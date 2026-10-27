-- KittyTracker.lua: the "Kitty" trigger and the "Kitty tracker" display. Shows which skill a
-- Cherry's KittyCombo kitty would fire on the next press (icon 1), plus a guess at the two after
-- it (icons 2 and 3: the same kitty checked as if the earlier picks were on cooldown).
-- Needs Kitty.Predict from Cherry's KittyCombo 1.4.0+; without it the trigger never shows.

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local KT = {}
RWA.KittyTracker = KT
KT.triggerLabel = "Kitty tracker"
KT.MAX = 3 -- icons in the Kitty tracker display
KT.PICKS = 6 -- picks asked for: the tracker's 3 plus up to 3 extra icon displays

local function playerName()
  local ok, name = pcall(UnitName, "player")
  return ok and name or nil
end
KT.PlayerName = playerName

local function predictor()
  local k = rawget(_G, "Kitty")
  return type(k) == "table" and type(k.Predict) == "table" and k.Predict or nil
end
KT.Available = function()
  return predictor() ~= nil
end

---------------------------------------------------------------------------
-- Trigger: { type = "kitty", kitty = "<kitty name>" ("" = by class, like /run Kitty.attack()),
--            character = "<name>", anyCharacter = true|nil }
---------------------------------------------------------------------------

-- Saved name differs from the character playing: the tracker stays hidden.
function KT.NameMatches(trigger)
  if trigger.anyCharacter then
    return true
  end
  local want = trigger.character
  if want == nil or want == "" then
    return true
  end
  return string.lower(want) == string.lower(playerName() or "")
end

Triggers.evaluators.kitty = function(trigger)
  local state = { show = false, progressType = "static", value = 1, total = 1, name = trigger.kitty or "" }
  if not KT.NameMatches(trigger) then
    state.reason = "character"
    return state
  end
  local P = predictor()
  if not P then
    state.reason = "nokittycombo"
    return state
  end
  local picks, reason = P.next(trigger.kitty or "", KT.PICKS)
  state.reason = reason
  local icons, names = {}, {}
  for i, pick in ipairs(picks or {}) do
    if pick.type == "break" or pick.type == "debug" then
      break
    end
    icons[i] = pick.icon or W.TexturePath("exclamation-mark")
    names[i] = pick.name
  end
  state.kittyIcons, state.kittyNames = icons, names
  state.show = #icons > 0
  state.icon = icons[1]
  state.name = names[1] or state.name
  state.stacks = #icons
  return state
end

---------------------------------------------------------------------------
-- Display: up to three icons in a row. "timeline": the next press biggest, then smaller ones;
-- "same": all the size of the first; "single": only the next press. Bottom edges line up.
---------------------------------------------------------------------------

KT.LAYOUTS = { "timeline", "same", "single" }
KT.LAYOUT_LABELS = { timeline = "Timeline 1 2 3", same = "Same size", single = "Only next" }
KT.SCALES = {
  timeline = { 1, 0.7, 0.5 },
  same = { 1, 1, 1 },
  single = { 1 },
}
KT.SPACING = 4

-- Sizes and x offsets of each icon, and the whole width, for a layout and first-icon size.
function KT.Geometry(layout, w, h, spacing)
  local scales = KT.SCALES[layout] or KT.SCALES.timeline
  spacing = spacing or KT.SPACING
  local slots, x = {}, 0
  for i, s in ipairs(scales) do
    local sw, sh = math.floor(w * s + 0.5), math.floor(h * s + 0.5)
    slots[i] = { x = x, w = sw, h = sh }
    x = x + sw + spacing
  end
  return slots, x - spacing, h
end

RWA.REGION_DEFAULTS.kittytracker = { width = 48, height = 48, text = "", text2 = "", kittyLayout = "timeline" }

local Tracker = setmetatable({}, { __index = Regions.types.icon })
Tracker.__index = Tracker

function Tracker:Build()
  local f = self.frame
  self.slots = {}
  for i = 1, KT.MAX do
    self.slots[i] = {
      border = W.Texture(f, "BACKGROUND", "Square_FullWhite"),
      icon = W.Texture(f, "ARTWORK"),
    }
  end
  self.text = { obj = W.FontString(f, "OVERLAY", 14, "NORMAL") }
  W.SetJustify(self.text.obj, "CENTER")
end

function Tracker:LayoutParts(d)
  local geo, totalW, totalH = KT.Geometry(d.kittyLayout, d.width, d.height, d.kittySpacing)
  self.geo = geo
  W.SetSize(self.frame, totalW, totalH)
  self:Place()
  for i, slot in ipairs(self.slots) do
    local g = geo[i]
    if g then
      W.SetSize(slot.border, g.w, g.h)
      W.SetPoint(slot.border, "BOTTOMLEFT", self.frame, "BOTTOMLEFT", g.x, 0)
      W.SetColor(slot.border, 0, 0, 0, 1)
      W.SetSize(slot.icon, g.w - 2, g.h - 2)
      W.SetPoint(slot.icon, "BOTTOMLEFT", self.frame, "BOTTOMLEFT", g.x + 1, -1)
      RWA.Try(slot.icon, "SetTexCoord", 0.07, 0.93, 0.07, 0.93)
    end
    slot.lastIcon, slot.shown = nil, nil
  end
  W.SetFont(self.text.obj, d.fontSize or 14, "NORMAL", d.font)
  W.SetSize(self.text.obj, math.max(totalW, d.width), (d.fontSize or 14) + 6)
  W.SetPoint(self.text.obj, "TOPLEFT", self.frame, "BOTTOMLEFT", 0, 2)
  self.text.lastText = nil
  self:ApplyColor()
end

function Tracker:ApplyColor()
  local r, g, b = Regions.ColorOf(self.color)
  for _, slot in ipairs(self.slots) do
    W.SetColor(slot.icon, r, g, b)
  end
end

local function showSlot(slot, on)
  if slot.shown ~= on then
    slot.shown = on
    W.SetShown(slot.border, on)
    W.SetShown(slot.icon, on)
  end
end

function Tracker:Update(now)
  local d, state = self.data, self.state or {}
  local icons = state.kittyIcons
  if icons and icons[1] then
    d.previewIcon = icons[1] -- remembered for the preview in the /rwa list
  end
  for i, slot in ipairs(self.slots) do
    local path
    if self.geo[i] then
      if icons then
        path = icons[i]
      else
        -- Test mode / moving: no real picks, show the layout with placeholders.
        path = d.previewIcon or W.TexturePath("exclamation-mark")
      end
    end
    if path then
      if path ~= slot.lastIcon then
        slot.lastIcon = path
        RWA.Try(slot.icon, "SetTexture", path)
      end
      showSlot(slot, true)
    else
      showSlot(slot, false)
    end
  end
  local text = Regions.FormatText(d.text, state, now)
  if self.text.lastText ~= text then
    self.text.lastText = text
    W.SetText(self.text.obj, text)
  end
end

Regions.types.kittytracker = Tracker
Regions.labels.kittytracker = "Kitty tracker"
table.insert(Regions.order, "kittytracker")

---------------------------------------------------------------------------
-- Extra icon displays (the "+" next to Display) on a kitty aura continue the line: with an Icon
-- (or bar/text) main display showing pick 1, the first extra icon shows pick 2, the next pick 3;
-- after a Kitty tracker main display they start after its icons. Extra icons fed by their own
-- kitty trigger count from 1. e.kittyPick (1-6) sets a fixed pick instead.
-- Regions.lua calls this for each extra icon: nil = not a kitty state (normal icon),
-- false = no pick for this slot (hide it), otherwise the icon path.
---------------------------------------------------------------------------

function KT.PickNumber(region, index)
  local data = region.data or {}
  local list = data.elements or {}
  local e = list[index]
  if not e then
    return nil
  end
  if tonumber(e.kittyPick) then
    return tonumber(e.kittyPick)
  end
  local from = tonumber(e.from) or 0
  local n = 0
  if from == 0 then
    if data.regionType == "kittytracker" then
      n = #(KT.SCALES[data.kittyLayout] or KT.SCALES.timeline)
    else
      n = 1
    end
  end
  for i = 1, index do
    local other = list[i]
    if other.type ~= "text" and (tonumber(other.from) or 0) == from and not tonumber(other.kittyPick) then
      n = n + 1
    end
  end
  return n
end

function Regions.ElementIcon(region, index, state)
  local icons = state and state.kittyIcons
  if not icons then
    return nil
  end
  local pick = KT.PickNumber(region, index)
  return pick and icons[pick] or false
end

---------------------------------------------------------------------------
-- Editor rows (called by Options.lua inside the Trigger section, see docs/KITTYTRACKER_HOOKS.md)
--   Row 1: Kitty [kitty v] [Name: on/off v]
--   Row 2: Character [name field] [layout v]
---------------------------------------------------------------------------

local AUTO = ""

-- Kitties for this character's class first, then the rest (marked with their class).
function KT.KittyChoices()
  local P = predictor()
  local list = { AUTO }
  KT.kittyClass = {}
  if not P then
    return list
  end
  local mine, others = {}, {}
  for _, k in ipairs(P.listKitties(false)) do
    table.insert(k.mine and mine or others, k.name)
    if not k.mine then
      KT.kittyClass[k.name] = k.class
    end
  end
  for _, n in ipairs(mine) do
    list[#list + 1] = n
  end
  for _, n in ipairs(others) do
    list[#list + 1] = n
  end
  return list
end

function KT.KittyLabel(v)
  if v == nil or v == AUTO then
    return "Auto (by class)"
  end
  local class = KT.kittyClass and KT.kittyClass[v]
  if class then
    return v .. " |cff999999(" .. tostring(class) .. ")|r"
  end
  return v
end

-- What the list's "Tracks" column says for a kitty trigger.
function KT.Describe(t)
  local text = "kitty " .. ((t.kitty and t.kitty ~= "") and t.kitty or "auto")
  if not t.anyCharacter and t.character and t.character ~= "" then
    text = text .. " on " .. t.character
  end
  return text
end

-- Turn an aura's main display into a Kitty tracker (layout: timeline, same or single).
function KT.MakeTracker(data, layout)
  if data.regionType ~= "kittytracker" then
    data.regionType = "kittytracker"
    local defaults = RWA.REGION_DEFAULTS.kittytracker
    data.width, data.height = defaults.width, defaults.height
    data.text, data.text2 = defaults.text, defaults.text2
  end
  data.kittyLayout = layout or data.kittyLayout or "timeline"
end

-- Ask "Set display as Kitty tracker?" right after a trigger becomes a kitty trigger,
-- unless the main display already is one.
function KT.ShouldAskDisplay(data, oldType, newType)
  return newType == "kitty" and oldType ~= "kitty" and data ~= nil and data.regionType ~= "kittytracker"
end

function KT.BuildOptions(env)
  local r1, r2 = env.rows[1], env.rows[2]
  local WX, g = env.WX, env.group
  local function t()
    return env.trigger1()
  end
  -- Defaults the first time a trigger becomes a kitty trigger.
  local function ensure(trigger)
    if trigger.type == "kitty" and trigger.kitty == nil then
      trigger.kitty = AUTO
      trigger.character = trigger.character or playerName()
    end
    return trigger
  end
  -- Show what a kitty trigger tracks in the /rwa list (Options.lua is loaded by now).
  if not KT.describeWrapped and RWA.DescribeTarget then
    KT.describeWrapped = true
    local base = RWA.DescribeTarget
    RWA.DescribeTarget = function(data)
      local first = data.triggers and data.triggers[1]
      if first and first.type == "kitty" then
        return KT.Describe(first)
      end
      return base(data)
    end
  end

  g(env.L("Kitty", r1))
  g(env.cycle(WX, r1, 150, KT.KittyChoices, KT.KittyLabel, function()
    return ensure(t()).kitty or AUTO
  end, function(v)
    local trigger = ensure(t())
    trigger.kitty = v
  end, "Kitty"))
  g(env.cycle(WX + 156, r1, 94, { false, true }, function(v)
    return v and "Name: off" or "Name: on"
  end, function()
    return ensure(t()).anyCharacter and true or false
  end, function(v)
    ensure(t()).anyCharacter = v or nil
  end, "Only this character"))

  g(env.L("Character", r2))
  g(env.field(WX, r2, 120, function()
    local trigger = ensure(t())
    return trigger.character or playerName() or ""
  end, function(text)
    local trigger = t()
    if trigger.type == "kitty" then
      text = RWA.Trim(text or "")
      trigger.character = text ~= "" and text or nil
    end
  end))
  g(env.cycle(WX + 128, r2, 122, KT.LAYOUTS, function(v)
    return KT.LAYOUT_LABELS[v] or "Show as..."
  end, function()
    local data = env.selected()
    if data and data.regionType == "kittytracker" then
      return data.kittyLayout or "timeline"
    end
  end, function(v)
    KT.MakeTracker(env.selected(), v)
  end, "Layout"))
end

---------------------------------------------------------------------------
-- /rwa kitty [kitty name]: in-game check of the KittyCombo link. Prints what the tracker would
-- show right now. Casts nothing.
---------------------------------------------------------------------------

function KT.Probe(kittyName)
  local function line(status, text)
    RWA.Print("[kitty " .. status .. "] " .. text)
  end
  local k = rawget(_G, "Kitty")
  if type(k) ~= "table" then
    line("FAIL", "Cherry's KittyCombo is not loaded")
    return
  end
  line("OK", "KittyCombo " .. tostring(k.ADDON_VERSION or k.version or "?"))
  local P = predictor()
  if not P then
    line("FAIL", "this KittyCombo has no Kitty.Predict (needs 1.4.0 or newer)")
    return
  end
  line("OK", "character: " .. tostring(playerName()))
  local ok, all = pcall(P.listKitties, false)
  if not ok then
    line("FAIL", "listKitties: " .. tostring(all))
    return
  end
  local mine = 0
  for _, kitty in ipairs(all) do
    if kitty.mine then
      mine = mine + 1
    end
  end
  line(#all > 0 and "OK" or "LOOK", #all .. " kitties, " .. mine .. " for this class")
  local name = (kittyName and kittyName ~= "") and kittyName or ""
  local picks, reason = P.next(name, KT.PICKS)
  line("LOOK", "kitty " .. (name ~= "" and name or "auto (by class)") .. ", reason: " .. tostring(reason or "-"))
  if #(picks or {}) == 0 then
    line("LOOK", "nothing would fire now (try with a target, out of cooldowns)")
  end
  for i, pick in ipairs(picks or {}) do
    line(i == 1 and "LOOK" or "GUESS", i .. ": " .. tostring(pick.type) .. " " .. tostring(pick.name)
      .. (pick.proc and (" (proc " .. tostring(pick.proc) .. ")") or "") .. ", icon " .. tostring(pick.icon))
  end
  line("LOOK", "press your kitty key now: does it cast pick 1?")
end

local baseSlash = RWA.SlashCommand
RWA.SlashCommand = function(msg)
  local cmd, rest = string.match(msg or "", "^(%S*)%s*(.-)$")
  if string.lower(cmd or "") == "kitty" then
    KT.Probe(rest)
    return
  end
  return baseSlash(msg)
end
