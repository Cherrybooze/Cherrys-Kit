-- Threat.lua: the "Threat" trigger and the "Threat meter" display. Reads your target's hate list
-- (who the mob wants to hit, and how much) and shows the top entries as compact rows: name, a bar
-- and the threat value. The idea and the hate list calls come from pbInfo's threat meter
-- (pbInfo by p.b. a.k.a. novayuna, later odie2; CC BY-NC-SA 3.0).
--
-- Client calls (same as pbInfo):
--   TargetHateListRequest()        asks the server for the target's list (answer arrives later)
--   GetTargetHateList(i) -> name, threat   entry i of the last answer, nil after the last one

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local TH = {}
RWA.Threat = TH
TH.triggerLabel = "Threat"
TH.MAX_ROWS = 10 -- rows the display can draw
TH.POLL = 0.5 -- seconds between hate list requests (pbInfo used 1.0)
TH.SHOW = { "combat", "target", "always" }
TH.SHOW_LABELS = { combat = "In combat", target = "With a target", always = "Always" }
TH.VALUES = { "threat", "top", "total" }
TH.VALUE_LABELS = { threat = "Threat number", top = "% of the top", total = "% of all" }
TH.COUNTS = { 3, 5, 8, 10 }
TH.GOLD = { 1, 0.82, 0.2, 1 }

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c = pcall(fn, ...)
  if ok then
    return a, b, c
  end
end

local function inCombat()
  local state = call(rawget(_G, "GetPlayerCombatState"))
  return state ~= nil and state ~= false and state ~= 0
end

local function hostileTarget()
  if not call(rawget(_G, "UnitExists"), "target") then
    return false
  end
  return call(rawget(_G, "UnitCanAttack"), "player", "target") and true or false
end

function TH.Available()
  return type(rawget(_G, "GetTargetHateList")) == "function"
end

---------------------------------------------------------------------------
-- Hate list: polled only while an aura asks for it (TH.wanted), sorted biggest first.
-- TH.list = { { name, threat, ratio (of the top), share (of all), me }, ... }
---------------------------------------------------------------------------

TH.list = {}
TH.total, TH.top = 0, 0
TH.wanted = nil
local lastPoll = -100

-- 12345 -> "12.3k", 1234567 -> "1.23M"
function TH.Short(n)
  n = tonumber(n) or 0
  if n >= 1e9 then
    return string.format("%.2fG", n / 1e9)
  elseif n >= 1e6 then
    return string.format("%.2fM", n / 1e6)
  elseif n >= 1e4 then
    return string.format("%.1fk", n / 1e3)
  end
  return tostring(math.floor(n + 0.5))
end

local function byThreat(a, b)
  return a.threat > b.threat
end

function TH.Read()
  local list, total, top = {}, 0, 0
  local me = call(rawget(_G, "UnitName"), "player")
  local get = rawget(_G, "GetTargetHateList")
  for i = 1, 100 do
    local name, threat = call(get, i)
    threat = tonumber(threat)
    if not threat then
      break
    end
    name = tostring(name or "?")
    list[#list + 1] = { name = name, threat = threat, me = (name == me) }
    total = total + threat
    if threat > top then
      top = threat
    end
  end
  table.sort(list, byThreat)
  for _, e in ipairs(list) do
    e.ratio = top > 0 and e.threat / top or 0
    e.share = total > 0 and e.threat / total or 0
  end
  TH.list, TH.total, TH.top = list, total, top
  return list
end

function TH.Clear()
  TH.list, TH.total, TH.top = {}, 0, 0
end

function TH.Poll(now, force)
  if not force and now - lastPoll < TH.POLL then
    return
  end
  lastPoll = now
  if not hostileTarget() then
    if #TH.list > 0 then
      TH.Clear()
      RWA.MarkDirty()
    end
    return
  end
  call(rawget(_G, "TargetHateListRequest"))
  TH.Read()
  RWA.MarkDirty()
end

RWA.SetUpdater("threat", function(now)
  if TH.wanted and now - TH.wanted < 2 then
    TH.Poll(now)
  end
end)

-- A new target: drop the old list at once instead of showing it for up to TH.POLL seconds.
RWA.On("UNIT_TARGET_CHANGED", function()
  TH.Clear()
  lastPoll = -100
  RWA.MarkDirty()
end)

---------------------------------------------------------------------------
-- Trigger: { type = "threat", showOn = "combat"|"target"|"always", count = 5, valueAs = "threat"|"top"|"total" }
-- State: threatRows (the rows to draw), name = the target, value = your threat, total = the top
-- threat, percent = yours as % of the top, rank (0 = not on the list), aggro (1 = you are top).
---------------------------------------------------------------------------

function TH.ValueText(e, valueAs)
  if valueAs == "top" then
    return string.format("%d%%", math.floor(e.ratio * 100 + 0.5))
  elseif valueAs == "total" then
    return string.format("%d%%", math.floor(e.share * 100 + 0.5))
  end
  return TH.Short(e.threat)
end

Triggers.evaluators.threat = function(trigger, now, env, into)
  TH.wanted = now
  local count = math.min(TH.MAX_ROWS, tonumber(trigger.count) or 5)
  -- an engine poll refills last poll's state, rows and row tables (Triggers.Fresh)
  local rows = into and into.threatRows or {}
  local state = Triggers.Fresh(into)
  state.progressType, state.value, state.total, state.percent, state.rank, state.aggro = "static", 0, 1, 0, 0, 0
  state.name = call(rawget(_G, "UnitName"), "target") or ""
  local shown = 0
  for i, e in ipairs(TH.list) do
    if i <= count then
      local row = rows[i] or {}
      rows[i], shown = row, i
      row.name, row.ratio, row.me, row.text = e.name, e.ratio, e.me, TH.ValueText(e, trigger.valueAs)
    end
    if e.me then
      state.value = e.threat
      state.percent = e.ratio * 100
      state.rank = i
      state.aggro = (i == 1) and 1 or 0
    end
  end
  for i = #rows, shown + 1, -1 do rows[i] = nil end
  state.total = TH.top > 0 and TH.top or 1
  state.stacks = #TH.list
  state.threatRows = rows
  local showOn = trigger.showOn or "combat"
  if showOn == "always" then
    state.show = true
  elseif #rows == 0 then
    state.show = false
  elseif showOn == "target" then
    state.show = true
  else
    state.show = inCombat()
  end
  return state
end

---------------------------------------------------------------------------
-- Display "Threat meter": a dark panel with a thin gold edge, an optional title (data.text,
-- placeholders work: "Threat  %n" = Threat and the target's name) and up to data.threatRows rows.
-- Each row: the bar behind, the name on the left, the value on the right. data.width is the row
-- width, data.height the row height. Your own bar is gold; the one with aggro is red.
---------------------------------------------------------------------------

RWA.REGION_DEFAULTS.threatmeter = {
  width = 190,
  height = 15,
  text = "Threat  %n",
  text2 = "",
  fontSize = 11,
  threatRows = 5,
  color = { 1, 0.82, 0.2, 1 },
  bgColor = { 0.05, 0.04, 0.02, 0.72 },
  texture = "Statusbar_Clean",
}

TH.PAD, TH.GAP = 3, 1

local Meter = setmetatable({}, { __index = Regions.types.icon })
Meter.__index = Meter

function Meter:Build()
  local f = self.frame
  self.bg = W.Texture(f, "BACKGROUND", "Square_FullWhite")
  self.edges = {}
  for i = 1, 4 do
    self.edges[i] = W.Texture(f, "BORDER", "Square_FullWhite")
  end
  self.titleLine = W.Texture(f, "BORDER", "Square_FullWhite")
  self.title = { obj = W.FontString(f, "OVERLAY", 12, "NORMAL") }
  W.SetJustify(self.title.obj, "LEFT")
  self.rows = {}
  for i = 1, TH.MAX_ROWS do
    local row = {
      back = W.Texture(f, "BORDER", "Square_FullWhite"),
      bar = W.Texture(f, "ARTWORK"),
      name = W.FontString(f, "OVERLAY", 11, "OUTLINE"),
      value = W.FontString(f, "OVERLAY", 11, "OUTLINE"),
    }
    W.SetJustify(row.name, "LEFT")
    W.SetJustify(row.value, "RIGHT")
    self.rows[i] = row
  end
end

local function hide(obj)
  RWA.Try(obj, "Hide")
end

local function show(obj)
  RWA.Try(obj, "Show")
end

function Meter:LayoutParts(d)
  local n = math.max(1, math.min(TH.MAX_ROWS, tonumber(d.threatRows) or 5))
  local w, rh = d.width, math.max(8, d.height)
  local fs = d.fontSize or 11
  local hasTitle = d.text ~= nil and d.text ~= ""
  local titleH = hasTitle and (fs + 7) or 0
  local pad, gap = TH.PAD, TH.GAP
  local totalW = w + pad * 2
  local totalH = pad * 2 + titleH + n * rh + (n - 1) * gap
  self.n, self.rowW, self.rowH = n, w, rh
  W.SetSize(self.frame, totalW, totalH)
  self:Place()
  W.SetSize(self.bg, totalW, totalH)
  W.SetPoint(self.bg, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
  W.SetColor(self.bg, Regions.ColorOf(d.bgColor))
  -- 1 px gold edge: top, bottom, left, right
  local e = self.edges
  W.SetSize(e[1], totalW, 1)
  W.SetPoint(e[1], "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
  W.SetSize(e[2], totalW, 1)
  W.SetPoint(e[2], "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
  W.SetSize(e[3], 1, totalH)
  W.SetPoint(e[3], "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
  W.SetSize(e[4], 1, totalH)
  W.SetPoint(e[4], "TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
  if hasTitle then
    show(self.title.obj)
    show(self.titleLine)
    W.SetFont(self.title.obj, fs + 1, "OUTLINE", d.font)
    W.SetSize(self.title.obj, w, fs + 5)
    W.SetPoint(self.title.obj, "TOPLEFT", self.frame, "TOPLEFT", pad + 2, pad)
    W.SetSize(self.titleLine, w, 1)
    W.SetPoint(self.titleLine, "TOPLEFT", self.frame, "TOPLEFT", pad, pad + titleH - 3)
  else
    hide(self.title.obj)
    hide(self.titleLine)
  end
  self.title.lastText = nil
  for i, row in ipairs(self.rows) do
    local y = pad + titleH + (i - 1) * (rh + gap)
    row.y = y
    if i <= n then
      W.SetSize(row.back, w, rh)
      W.SetPoint(row.back, "TOPLEFT", self.frame, "TOPLEFT", pad, y)
      W.SetColor(row.back, 1, 1, 1, 0.06)
      W.SetTexture(row.bar, d.texture or "Statusbar_Clean")
      W.SetFont(row.name, fs, "OUTLINE", d.font)
      W.SetFont(row.value, fs, "OUTLINE", d.font)
      W.SetSize(row.name, w * 0.68 - 4, rh)
      W.SetSize(row.value, w * 0.32 - 4, rh)
      W.SetPoint(row.name, "TOPLEFT", self.frame, "TOPLEFT", pad + 4, y)
      W.SetPoint(row.value, "TOPRIGHT", self.frame, "TOPRIGHT", -pad - 4, y)
    end
    row.lastName, row.lastValue, row.lastW, row.lastKind, row.shown = nil, nil, nil, nil, nil
  end
  self:ApplyColor()
end

-- data.color tints the gold edge, the title and your own bar.
function Meter:ApplyColor()
  local r, g, b = Regions.ColorOf(self.color)
  for _, e in ipairs(self.edges) do
    W.SetColor(e, r, g, b, 0.85)
  end
  W.SetColor(self.titleLine, r, g, b, 0.35)
  W.SetColor(self.title.obj, r, g, b)
  for _, row in ipairs(self.rows) do
    row.lastKind = nil
  end
end

-- Bar colours: aggro red, yours gold (data.color), others a soft amber that darkens lower down.
function TH.BarColor(rowInfo, index, gold)
  if index == 1 and not rowInfo.placeholder then
    return 0.85, 0.22, 0.15
  end
  if rowInfo.me then
    return gold[1], gold[2], gold[3]
  end
  local k = 0.75 - math.min(0.35, (index - 2) * 0.08)
  return 0.78 * k + 0.1, 0.55 * k + 0.08, 0.25 * k
end

TH.PREVIEW = {
  { name = "Tank", ratio = 1, text = "48.2k" },
  { name = "You", ratio = 0.74, text = "35.7k", me = true },
  { name = "Healer", ratio = 0.52, text = "25.1k" },
  { name = "Mage", ratio = 0.31, text = "14.9k" },
  { name = "Scout", ratio = 0.12, text = "5806" },
}

local function setRowShown(row, on)
  if row.shown ~= on then
    row.shown = on
    W.SetShown(row.back, on)
    W.SetShown(row.bar, on)
    W.SetShown(row.name, on)
    W.SetShown(row.value, on)
  end
end

function Meter:Update(now)
  local d, state = self.data, self.state or {}
  local rows = state.threatRows
  if not rows then
    rows = TH.PREVIEW -- test mode, moving, or the editor preview
  end
  local title = Regions.FormatText(d.text, state.threatRows and state or { name = "Target" }, now)
  if self.title.lastText ~= title then
    self.title.lastText = title
    W.SetText(self.title.obj, title)
  end
  local gold = { Regions.ColorOf(self.color) }
  for i, row in ipairs(self.rows) do
    local info = i <= (self.n or 0) and rows[i] or nil
    if info then
      local bw = math.floor(self.rowW * math.max(0, math.min(1, info.ratio or 0)) + 0.5)
      if bw ~= row.lastW then
        row.lastW = bw
        if bw < 1 then
          hide(row.bar)
        else
          show(row.bar)
          W.SetSize(row.bar, bw, self.rowH)
          W.SetPoint(row.bar, "TOPLEFT", self.frame, "TOPLEFT", TH.PAD, row.y)
        end
      end
      local kind = (i == 1 and "aggro") or (info.me and "me") or ("other" .. i)
      if kind ~= row.lastKind then
        row.lastKind = kind
        local r, g, b = TH.BarColor(info, i, gold)
        W.SetColor(row.bar, r, g, b, 0.9)
        W.SetColor(row.name, 1, 1, 1)
        W.SetColor(row.value, 1, 0.95, 0.85)
      end
      if row.lastName ~= info.name then
        row.lastName = info.name
        W.SetText(row.name, info.name)
      end
      if row.lastValue ~= info.text then
        row.lastValue = info.text
        W.SetText(row.value, info.text)
      end
      setRowShown(row, true)
      if bw < 1 then
        hide(row.bar)
      end
    else
      setRowShown(row, false)
    end
  end
end

Regions.types.threatmeter = Meter
Regions.labels.threatmeter = "Threat meter"
table.insert(Regions.order, "threatmeter")

-- Turn an aura's main display into a Threat meter.
function TH.MakeMeter(data)
  if data.regionType ~= "threatmeter" then
    data.regionType = "threatmeter"
    local defaults = RWA.REGION_DEFAULTS.threatmeter
    data.width, data.height = defaults.width, defaults.height
    data.text, data.text2 = defaults.text, defaults.text2
    data.fontSize = defaults.fontSize
    data.texture = defaults.texture
    data.bgColor = RWA.CopyTable(defaults.bgColor)
    data.color = RWA.CopyTable(defaults.color)
  end
  data.threatRows = data.threatRows or 5
end

---------------------------------------------------------------------------
-- Default aura "Threat meter": added once (settings.threatAdded), also to saved auras.
---------------------------------------------------------------------------

TH.EXAMPLE_ID = "Threat meter"
TH.EXAMPLE = {
  id = TH.EXAMPLE_ID,
  desc = "Top 5 on your target's hate list: name, bar and threat; in combat only",
  regionType = "threatmeter",
  point = "CENTER",
  x = 330,
  y = 60,
  width = 190,
  height = 15,
  text = "Threat  %n",
  text2 = "",
  fontSize = 11,
  threatRows = 5,
  color = { 1, 0.82, 0.2, 1 },
  bgColor = { 0.05, 0.04, 0.02, 0.72 },
  texture = "Statusbar_Clean",
  schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
  sources = { { id = "s1", type = "threat", showOn = "combat", count = 5, valueAs = "threat" } },
  rules = { { id = "r1", name = "Show threat", when = { mode = "all", checks = {
    { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } } },
  animation = { start = "fade", main = "none", finish = "fade" },
}
RWA.ApplyDefaultPosition(TH.EXAMPLE)

function TH.AddExample()
  local s = RWA_DB and RWA_DB.settings
  if not s or s.threatAdded then
    return
  end
  s.threatAdded = true
  if RWA_DB.auras[TH.EXAMPLE_ID] then
    return
  end
  local copy = RWA.CopyTable(TH.EXAMPLE)
  RWA.ApplyAuraDefaults(copy)
  RWA_DB.auras[copy.id] = copy
  table.insert(RWA_DB.order, copy.id)
end

-- Runs before Engine.lua's RWA_READY handler (this file loads first), so the aura loads with the rest.
RWA.On("RWA_READY", function()
  TH.AddExample()
end)

---------------------------------------------------------------------------
-- Editor rows (same env as KittyTracker.lua / LastCast.lua; wrap everything in env.group)
--   Row 1: Show  [In combat v] [Threat number v]
--   Row 2: Rows  [5 rows v] [Show as threat meter v]
---------------------------------------------------------------------------

function TH.Describe(t)
  return "threat on target (" .. string.lower(TH.SHOW_LABELS[t.showOn or "combat"] or "") .. ")"
end

function TH.BuildOptions(env)
  local r1, r2 = env.rows[1], env.rows[2]
  local WX, g = env.WX, env.group
  local function t()
    local trigger = env.trigger1()
    if trigger.type == "threat" and trigger.showOn == nil then
      trigger.showOn, trigger.count, trigger.valueAs = "combat", 5, "threat"
    end
    return trigger
  end
  if not TH.describeWrapped and RWA.DescribeTarget then
    TH.describeWrapped = true
    local base = RWA.DescribeTarget
    RWA.DescribeTarget = function(data)
      local first = data.triggers and data.triggers[1]
      if first and first.type == "threat" then
        return TH.Describe(first)
      end
      return base(data)
    end
  end

  g(env.L("Show", r1))
  g(env.cycle(WX, r1, 122, TH.SHOW, function(v)
    return TH.SHOW_LABELS[v] or v
  end, function()
    return t().showOn or "combat"
  end, function(v)
    t().showOn = v
  end, "Show"))
  g(env.cycle(WX + 128, r1, 122, TH.VALUES, function(v)
    return TH.VALUE_LABELS[v] or v
  end, function()
    return t().valueAs or "threat"
  end, function(v)
    t().valueAs = v
  end, "Value"))

  g(env.L("Rows", r2))
  g(env.cycle(WX, r2, 122, TH.COUNTS, function(v)
    return v .. " rows"
  end, function()
    return tonumber(t().count) or 5
  end, function(v)
    t().count = v
    local data = env.selected()
    if data and data.regionType == "threatmeter" then
      data.threatRows = v
    end
  end, "Rows"))
  g(env.cycle(WX + 128, r2, 122, { "meter" }, function()
    local data = env.selected()
    return (data and data.regionType == "threatmeter") and "Threat meter" or "Show as meter"
  end, function()
    return "meter"
  end, function()
    TH.MakeMeter(env.selected())
    env.selected().threatRows = tonumber(t().count) or 5
  end, "Display"))
end

---------------------------------------------------------------------------
-- /rwa threat: in-game check of the hate list calls. Target a mob you are fighting first.
---------------------------------------------------------------------------

function TH.Probe()
  local function line(status, text)
    RWA.Print("[threat " .. status .. "] " .. text)
  end
  line(type(rawget(_G, "TargetHateListRequest")) == "function" and "OK" or "FAIL", "TargetHateListRequest "
    .. type(rawget(_G, "TargetHateListRequest")))
  line(TH.Available() and "OK" or "FAIL", "GetTargetHateList " .. type(rawget(_G, "GetTargetHateList")))
  line("LOOK", "target " .. tostring(call(rawget(_G, "UnitName"), "target")) .. ", hostile " .. tostring(hostileTarget())
    .. ", in combat " .. tostring(inCombat()))
  TH.Poll(RWA.Now(), true)
  line(#TH.list > 0 and "OK" or "LOOK", #TH.list .. " on the list (the first request after a target change can be empty: run it twice)")
  for i = 1, math.min(5, #TH.list) do
    local e = TH.list[i]
    line("LOOK", string.format("%d: %s %s (%d%% of top)%s", i, e.name, TH.Short(e.threat), math.floor(e.ratio * 100 + 0.5),
      e.me and " <- you" or ""))
  end
end

local baseSlash = RWA.SlashCommand
RWA.SlashCommand = function(msg)
  local cmd = string.match(msg or "", "^(%S*)")
  if string.lower(cmd or "") == "threat" then
    TH.Probe()
    return
  end
  return baseSlash(msg)
end
