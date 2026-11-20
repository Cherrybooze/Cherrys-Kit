-- Cherry's Info: "Show all client buffs and debuffs". Hides the game's player buff icons and draws
-- every buff and debuff the client holds for the player, from a pool of icons declared in
-- AllBuffs.xml (RoM ignores scripts set from Lua).
--
-- What the client offers (client source, Interface/WorldFrames/UnitFrame.cpp, BuffFrame.cpp and
-- sprite/rolesprite.cpp): the player's effects are one list with no size limit on the client.
--   UnitBuff / UnitDebuff(unit, i)  -> name, icon, stacks, id: the i-th SHOWN helpful / harmful effect
--   UnitBuffLeftTime / UnitDebuffLeftTime(unit, i) -> seconds left, nil without a shown timer
--   UnitBuffInfo(unit, i)           -> name, icon, stacks, id of the i-th entry of the whole list,
--                                      hidden effects included (1-based)
--   GetPlayerBuffLeftTime(i)        -> whole seconds left of entry i of the whole list (0-based)
--   CancelPlayerBuff(i)             -> cancels the i-th shown helpful effect
-- The limit is the game's buff frame, which has a fixed set of icons. Hidden effects are ones the
-- game data marks as not shown; they are drawn only with "Include hidden effects".
--
-- Cost: the icons are read again only after UNIT_BUFF_CHANGED for the player (gathered for a short
-- moment) and every few seconds as a fallback. Timers are redrawn twice a second from the end time
-- kept at the read, and their texts come from a cache, so the running display makes no strings or
-- tables after the first minutes. Turned off, the display frame is hidden and gets no OnUpdate.

local Q = CherrysQuests
local B = {}
Q.AllBuffs = B

B.POOL = 96            -- icons declared in AllBuffs.xml (CInfoBuff1..96)
B.MAX_RAW = 120        -- the whole list is read up to this many entries
B.READ_DELAY = 0.1     -- read this long after the last buff event
B.FALLBACK = 3         -- read at least this often while shown
B.TIMER_EVERY = 0.5    -- timer texts
B.HIDE_EVERY = 0.5     -- keep the game's icons hidden
B.GAP = 4
B.TIME_H = 12          -- room under each icon for its timer

B.SIZES = {
  { key = "small", label = "Small, 16 a row", size = 24, perRow = 16 },
  { key = "medium", label = "Medium, 12 a row", size = 30, perRow = 12 },
  { key = "large", label = "Large, 10 a row", size = 36, perRow = 10 },
}

-- The game's own buff frame and icons, hidden while this display is on.
B.STOCK_FRAMES = { "PlayerBuffFrame" }
B.STOCK_BUTTONS = { "PlayerBuffButton", "PlayerDebuffButton" }
B.STOCK_SCAN = 64

local KIND_BUFF, KIND_DEBUFF, KIND_HIDDEN = 1, 2, 3
B.KIND_BUFF, B.KIND_DEBUFF, B.KIND_HIDDEN = KIND_BUFF, KIND_DEBUFF, KIND_HIDDEN

-- One entry per icon, made once and reused by every read.
B.entries = {}
B.count = 0
B.counts = { 0, 0, 0 }
B.stock = nil          -- the game's frames found, filled once
B.dirty = true
B.wait, B.since, B.timerWait, B.hideWait = 0, 0, 0, 0
B.style = 0
B.drawnStyle = -1

local function now()
  return (GetTime and GetTime()) or 0
end

local function uiScale()
  local s = GetUIScale and tonumber(GetUIScale()) or 1
  if not s or s <= 0 then
    s = 1
  end
  return s
end

local function S()
  return Q.S()
end

function B.IsOn()
  return Q.IsOn() and S().allBuffs == true
end

function B.SizeDef()
  local key = S().allBuffsSize
  for _, d in ipairs(B.SIZES) do
    if d.key == key then
      return d
    end
  end
  return B.SIZES[2]
end

---------------------------------------------------------------------------
-- Text caches: timers and stack counts are drawn from these, so a running display makes no strings.
---------------------------------------------------------------------------

local timeText = {}
local countText = {}

function B.TimeText(left)
  if not left then
    return ""
  end
  local s = math.ceil(left)
  if s < 0 then
    s = 0
  end
  local key, n, unit
  if s >= 3600 then
    n = math.ceil(s / 3600)
    key, unit = 200000 + n, "h"
  elseif s >= 60 then
    n = math.ceil(s / 60)
    key, unit = 100000 + n, "m"
  else
    key = s
  end
  local text = timeText[key]
  if not text then
    text = unit and (n .. unit) or tostring(s)
    timeText[key] = text
  end
  return text
end

function B.CountText(n)
  if not n or n <= 1 then
    return ""
  end
  local text = countText[n]
  if not text then
    text = tostring(n)
    countText[n] = text
  end
  return text
end

---------------------------------------------------------------------------
-- Reading the client
---------------------------------------------------------------------------

local seen = {}   -- id -> how many shown entries have it, cleared on each read

local function entry(n)
  local e = B.entries[n]
  if not e then
    e = {}
    B.entries[n] = e
  end
  return e
end

local function add(kind, index, name, icon, stacks, id, left, t)
  local n = B.count + 1
  if n > B.POOL then
    B.overflow = B.overflow + 1
    return
  end
  B.count = n
  local e = entry(n)
  e.kind = kind
  e.index = index
  e.name = name
  e.icon = icon
  e.stacks = tonumber(stacks) or 0
  e.id = tonumber(id)
  left = tonumber(left)
  e.expires = (left and left > 0) and (t + left) or nil
  B.counts[kind] = B.counts[kind] + 1
end

local function readShown(kind, getter, timeGetter, t)
  if type(getter) ~= "function" then
    return
  end
  for i = 1, B.POOL do
    local ok, name, icon, stacks, id = pcall(getter, "player", i)
    if not ok or not name or name == "" then
      return
    end
    local left
    if type(timeGetter) == "function" then
      local ok2, l = pcall(timeGetter, "player", i)
      if ok2 then
        left = l
      end
    end
    id = tonumber(id)
    if id then
      seen[id] = (seen[id] or 0) + 1
    end
    add(kind, i, name, icon, stacks, id, left, t)
  end
end

-- Entries of the whole list that no shown buff or debuff accounts for.
local function readHidden(t)
  if type(UnitBuffInfo) ~= "function" then
    return
  end
  for i = 1, B.MAX_RAW do
    local ok, name, icon, stacks, id = pcall(UnitBuffInfo, "player", i)
    if not ok or not name then
      return
    end
    B.raw = i
    id = tonumber(id)
    local n = id and seen[id]
    if n and n > 0 then
      seen[id] = n - 1
    elseif name ~= "" then
      local left
      if type(GetPlayerBuffLeftTime) == "function" then
        local ok2, l = pcall(GetPlayerBuffLeftTime, i - 1)
        if ok2 then
          left = l
        end
      end
      add(KIND_HIDDEN, i, name, icon, stacks, id, left, t)
    end
  end
end

function B.Read()
  for id in pairs(seen) do
    seen[id] = nil
  end
  B.count, B.overflow, B.raw = 0, 0, 0
  B.counts[1], B.counts[2], B.counts[3] = 0, 0, 0
  local t = now()
  readShown(KIND_BUFF, UnitBuff, UnitBuffLeftTime, t)
  readShown(KIND_DEBUFF, UnitDebuff, UnitDebuffLeftTime, t)
  if S().allBuffsHidden then
    readHidden(t)
  end
  B.readAt = t
end

---------------------------------------------------------------------------
-- The game's icons
---------------------------------------------------------------------------

function B.FindStock()
  if B.stock then
    return B.stock
  end
  local list = {}
  for _, name in ipairs(B.STOCK_FRAMES) do
    if _G[name] then
      list[#list + 1] = _G[name]
    end
  end
  B.stockButtons = {}
  for _, prefix in ipairs(B.STOCK_BUTTONS) do
    local n = 0
    for i = 1, B.STOCK_SCAN do
      local f = _G[prefix .. i]
      if f then
        list[#list + 1] = f
        n = i
      end
    end
    B.stockButtons[prefix] = n
  end
  B.stock = list
  return list
end

function B.HideStock()
  local list = B.FindStock()
  for i = 1, #list do
    local f = list[i]
    if type(f.IsVisible) == "function" and f:IsVisible() then
      f:Hide()
      B.hidStock = true
    end
  end
end

function B.ShowStock()
  if not B.hidStock then
    return
  end
  B.hidStock = false
  for _, name in ipairs(B.STOCK_FRAMES) do
    Q.Try(_G[name], "Show")
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function part(i, suffix)
  return _G["CInfoBuff" .. i .. suffix]
end

-- Widgets of each pool icon, looked up once.
B.widgets = {}
local function widgets(i)
  local w = B.widgets[i]
  if not w then
    w = {
      button = _G["CInfoBuff" .. i],
      icon = part(i, "Icon"),
      border = part(i, "Border"),
      count = part(i, "Count"),
      time = part(i, "Time"),
    }
    B.widgets[i] = w
  end
  return w
end

local BORDER = {
  [KIND_BUFF] = { 0.10, 0.10, 0.10, 0.8 },
  [KIND_DEBUFF] = { 0.85, 0.12, 0.12, 1 },
  [KIND_HIDDEN] = { 0.45, 0.45, 0.55, 0.9 },
}

function B.Position()
  local f = CInfoBuffs
  if not f then
    return
  end
  local s = S()
  Q.Try(f, "ClearAllAnchors")
  if s.allBuffsX and s.allBuffsY then
    local us = uiScale()
    Q.Try(f, "SetAnchor", "TOPLEFT", "TOPLEFT", "UIParent", (tonumber(s.allBuffsX) or 0) / us, (tonumber(s.allBuffsY) or 0) / us)
  else
    Q.Try(f, "SetAnchor", "TOPRIGHT", "TOPRIGHT", "UIParent", -230, 12)
  end
end

-- Sizes every icon for the chosen size; only after a size change.
local function styleIcons(d)
  for i = 1, B.POOL do
    local w = widgets(i)
    if w.button then
      Q.Try(w.button, "SetWidth", d.size)
      Q.Try(w.button, "SetHeight", d.size)
      Q.Try(w.icon, "SetWidth", d.size - 2)
      Q.Try(w.icon, "SetHeight", d.size - 2)
      Q.Try(w.border, "SetWidth", d.size)
      Q.Try(w.border, "SetHeight", d.size)
    end
  end
end

-- Places the icons read last: buffs, then debuffs on a new row, then hidden effects on a new row.
-- Each row fills from the right, like the game's own icons.
function B.Draw()
  local f = CInfoBuffs
  if not f then
    return
  end
  local d = B.SizeDef()
  if B.drawnStyle ~= B.style then
    B.drawnStyle = B.style
    styleIcons(d)
  end
  local step = d.size + B.GAP
  local rowH = d.size + B.TIME_H + B.GAP
  local width = d.perRow * step
  local row, col, lastKind = 0, 0, nil
  local t = now()
  for i = 1, B.POOL do
    local w = widgets(i)
    local e = (i <= B.count) and B.entries[i] or nil
    if e and w.button then
      if lastKind and e.kind ~= lastKind and col > 0 then
        row, col = row + 1, 0
      elseif col >= d.perRow then
        row, col = row + 1, 0
      end
      lastKind = e.kind
      Q.Try(w.button, "ClearAllAnchors")
      Q.Try(w.button, "SetAnchor", "TOPRIGHT", "TOPRIGHT", "CInfoBuffs", -col * step, row * rowH)
      col = col + 1
      Q.Try(w.icon, "SetFile", e.icon)
      local c = BORDER[e.kind]
      Q.Try(w.border, "SetColor", c[1], c[2], c[3])
      Q.Try(w.border, "SetAlpha", c[4])
      Q.Try(w.icon, "SetAlpha", e.kind == KIND_HIDDEN and 0.75 or 1)
      Q.Try(w.count, "SetText", B.CountText(e.stacks))
      Q.Try(w.time, "SetText", B.TimeText(e.expires and (e.expires - t)))
      w.button:Show()
    elseif w.button then
      w.button:Hide()
    end
  end
  local rows = (B.count > 0) and (row + 1) or 1
  Q.Try(f, "SetWidth", width)
  Q.Try(f, "SetHeight", rows * rowH)
end

-- Timers only: no anchors, no files. A text is set only when it changes.
function B.DrawTimers()
  local t = now()
  for i = 1, B.count do
    local e = B.entries[i]
    if e.expires then
      local w = widgets(i)
      local text = B.TimeText(e.expires - t)
      if w.time and w.time.GetText and w.time:GetText() ~= text then
        w.time:SetText(text)
      end
    end
  end
end

---------------------------------------------------------------------------
-- Switching, events and the throttled update
---------------------------------------------------------------------------

function B.Apply()
  local f = CInfoBuffs
  if not f then
    return
  end
  if B.IsOn() and Q.ready then
    B.Position()
    B.HideStock()
    B.dirty = true
    B.wait = B.READ_DELAY
    f:Show()
  else
    f:Hide()
    B.ShowStock()
  end
end

function B.Restyle()
  B.style = B.style + 1
  B.dirty = true
  B.wait = B.READ_DELAY
end

function B.OnLoad(frame)
  Q.Try(frame, "RegisterEvent", "UNIT_BUFF_CHANGED")
  Q.Try(frame, "RegisterEvent", "LOADING_END")
end

function B.OnEvent(event, unit)
  if event == "LOADING_END" or unit == "player" then
    B.dirty = true
    B.wait = 0
  end
end

function B.OnUpdate(elapsed)
  elapsed = tonumber(elapsed) or 0
  B.wait = B.wait + elapsed
  B.since = B.since + elapsed
  B.timerWait = B.timerWait + elapsed
  B.hideWait = B.hideWait + elapsed
  if B.hideWait >= B.HIDE_EVERY then
    B.hideWait = 0
    B.HideStock()
  end
  if (B.dirty and B.wait >= B.READ_DELAY) or B.since >= B.FALLBACK then
    B.dirty, B.wait, B.since, B.timerWait = false, 0, 0, 0
    B.Read()
    B.Draw()
    return
  end
  if not B.dirty then
    B.wait = 0
  end
  if B.timerWait >= B.TIMER_EVERY then
    B.timerWait = 0
    B.DrawTimers()
  end
end

---------------------------------------------------------------------------
-- Mouse: tooltip, right-click cancels a buff, Shift+drag moves the display
---------------------------------------------------------------------------

function B.Enter(i, frame)
  local e = (i <= B.count) and B.entries[i]
  if not e or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
  if e.kind == KIND_BUFF and type(GameTooltip.SetUnitBuff) == "function" then
    GameTooltip:SetUnitBuff("player", e.index)
  elseif e.kind == KIND_DEBUFF and type(GameTooltip.SetUnitDebuff) == "function" then
    GameTooltip:SetUnitDebuff("player", e.index)
  else
    GameTooltip:ClearLines()
    GameTooltip:SetText(e.name or "?", 1, 1, 1)
    GameTooltip:AddLine("Hidden effect: the game's own icons leave it out.", 0.75, 0.75, 0.85)
    if e.id then
      GameTooltip:AddLine("ID " .. e.id, 0.6, 0.6, 0.6)
    end
  end
  if e.kind == KIND_BUFF then
    GameTooltip:AddLine("Right-click: cancel   Shift+drag: move", 0.6, 0.6, 0.6)
  else
    GameTooltip:AddLine("Shift+drag: move", 0.6, 0.6, 0.6)
  end
  GameTooltip:Show()
end

function B.Leave()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

function B.Click(i, key)
  local e = (i <= B.count) and B.entries[i]
  if not e or B.moved then
    B.moved = false
    return
  end
  if key == "RBUTTON" and e.kind == KIND_BUFF and type(CancelPlayerBuff) == "function" then
    pcall(CancelPlayerBuff, e.index)
    B.dirty = true
  end
end

function B.MouseDown(key)
  if key == "LBUTTON" and IsShiftKeyDown and IsShiftKeyDown() and CInfoBuffs then
    B.moving = true
    Q.Try(CInfoBuffs, "StartMoving")
  end
end

function B.MouseUp()
  if not B.moving or not CInfoBuffs then
    return
  end
  B.moving = false
  B.moved = true
  Q.Try(CInfoBuffs, "StopMovingOrSizing")
  local f = CInfoBuffs
  local x, y
  if type(f.GetPos) == "function" then
    x, y = f:GetPos()
  end
  if not x and type(f.GetLeft) == "function" then
    local us = uiScale()
    x, y = f:GetLeft(), f:GetTop()
    x, y = x and x * us, y and y * us
  end
  if x and y then
    S().allBuffsX, S().allBuffsY = x, y
  end
  B.Position()
end

function B.ResetPosition()
  S().allBuffsX, S().allBuffsY = nil, nil
  B.Position()
end

---------------------------------------------------------------------------
-- /cinfo buffs: what the client holds next to what the game's icons can show
---------------------------------------------------------------------------

local function countShown(getter)
  if type(getter) ~= "function" then
    return "missing"
  end
  local n = 0
  for i = 1, B.MAX_RAW do
    local ok, name = pcall(getter, "player", i)
    if not ok or not name or name == "" then
      break
    end
    n = i
  end
  return n
end

function B.Probe()
  local raw = countShown(UnitBuffInfo)
  local buffs = countShown(UnitBuff)
  local debuffs = countShown(UnitDebuff)
  local hidden = "?"
  if type(raw) == "number" and type(buffs) == "number" and type(debuffs) == "number" then
    hidden = raw - buffs - debuffs
  end
  Q.Print("buffs: the client holds " .. tostring(raw) .. " effects on you: " .. tostring(buffs) .. " buffs, "
    .. tostring(debuffs) .. " debuffs and " .. tostring(hidden) .. " hidden.")
  B.stock = nil
  B.FindStock()
  local parts = {}
  for _, prefix in ipairs(B.STOCK_BUTTONS) do
    parts[#parts + 1] = prefix .. " x" .. tostring(B.stockButtons[prefix] or 0)
  end
  Q.Print("buffs: the game's icons: " .. table.concat(parts, ", ") .. ", PlayerBuffFrame "
    .. tostring(PlayerBuffFrame ~= nil) .. ".")
  local fns = {}
  for _, fn in ipairs({ "UnitBuff", "UnitDebuff", "UnitBuffLeftTime", "UnitDebuffLeftTime", "UnitBuffInfo",
    "GetPlayerBuffLeftTime", "CancelPlayerBuff" }) do
    if type(_G[fn]) ~= "function" then
      fns[#fns + 1] = fn
    end
  end
  Q.Print("buffs: all-buffs display " .. (B.IsOn() and "on" or "off") .. ", hidden effects "
    .. (S().allBuffsHidden and "on" or "off") .. ", showing " .. tostring(B.count) .. " of " .. B.POOL
    .. " icons, missing functions: " .. (#fns > 0 and table.concat(fns, ", ") or "none") .. ".")
end

function B.Command(rest)
  rest = string.lower(tostring(rest or ""))
  if rest == "on" or rest == "off" then
    S().allBuffs = rest == "on"
    B.Apply()
    Q.Print("all buffs and debuffs " .. rest .. ".")
  elseif rest == "reset" then
    B.ResetPosition()
    Q.Print("buff display moved back to the top right.")
  else
    B.Probe()
  end
end
