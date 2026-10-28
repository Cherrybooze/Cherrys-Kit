-- ZShop: the daily loyalty reward button (action button size, like KittyCombo's mode button).
-- Left click opens the shop on the daily reward page. Right-drag (or Shift+left-drag) moves it
-- unless locked. Options in the ZShop window (/zshop): show the button, lock it.
--
-- "Claimed" is a shortcut: the game can't see the Collect click, so the reward counts as claimed
-- on a level 100 character once the button (or /zshop daily) opened the page since the last reset,
-- 00:00 German time (Europe/Berlin). /zshop unmark clears it for this character.
--
-- Saved: ZShop_Char (this character) = { claimed = <os.time()>, x, y, show, lock };
-- ZShop_Settings (shared file) holds x, y, show, lock too, as the default for new characters,
-- because many players keep the shared save file read-only.

local me = ZShop
me.Button = me.Button or {}
local B = me.Button

if SaveVariables then
  SaveVariables("ZShop_Settings")
end
if SaveVariablesPerCharacter then
  SaveVariablesPerCharacter("ZShop_Char")
end

B.ICON = me.BASE_PATH .. "gfx/daily.tga"
B.ICON_DONE = me.BASE_PATH .. "gfx/daily_done.tga"
B.ICON_LOCKED = me.BASE_PATH .. "gfx/daily_locked.tga"
B.DEFAULTS = { show = true, lock = false }

---------------------------------------------------------------------------
-- German day (Europe/Berlin): UTC+1, UTC+2 from the last Sunday of March 01:00 UTC to the last
-- Sunday of October 01:00 UTC. Only os.time() is needed; dates are worked out here.
---------------------------------------------------------------------------

-- days since 1970-01-01 -> year, month, day
local function civil(days)
  local z = days + 719468
  local era = math.floor(z / 146097)
  local doe = z - era * 146097
  local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
  local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
  local mp = math.floor((5 * doy + 2) / 153)
  local d = doy - math.floor((153 * mp + 2) / 5) + 1
  local m = mp < 10 and mp + 3 or mp - 9
  local y = yoe + era * 400
  if m <= 2 then
    y = y + 1
  end
  return y, m, d
end

-- year, month, day -> days since 1970-01-01
local function daysFrom(y, m, d)
  if m <= 2 then
    y = y - 1
  end
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local mp = m > 2 and m - 3 or m + 9
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + math.floor((153 * mp + 2) / 5) + d - 1
  return era * 146097 + doe - 719468
end

-- last Sunday of March/October (both 31 days) at 01:00 UTC
local function lastSunday(y, m)
  local days = daysFrom(y, m, 31)
  return (days - (days + 4) % 7) * 86400 + 3600 -- 1970-01-01 was a Thursday
end

function B.BerlinOffset(utc)
  local y = civil(math.floor(utc / 86400))
  if utc >= lastSunday(y, 3) and utc < lastSunday(y, 10) then
    return 7200
  end
  return 3600
end

-- Some clients do not expose os.time. The Global Bank helper writes UTC seconds
-- every 30 seconds; trust it only after observing a new heartbeat in this session.
local beatPath = "Interface/GlobalBankHelper/GlobalBankHelperBeat.lua"
local lastBeat, anchorBeat, anchorTick, lastRead, lastTick
local function helperNow()
  if type(GetTime) ~= "function" or type(dofile) ~= "function" then
    return nil
  end
  local ok, tick = pcall(GetTime)
  tick = ok and tonumber(tick) or nil
  if not tick then return nil end
  if lastTick and tick < lastTick then
    lastBeat, anchorBeat, anchorTick, lastRead = nil, nil, nil, nil
  end
  lastTick = tick
  if not lastRead or tick - lastRead >= 5 then
    lastRead = tick
    GlobalBank_HelperBeat = nil
    local readOK = pcall(dofile, beatPath)
    local beat = readOK and tonumber(GlobalBank_HelperBeat) or nil
    GlobalBank_HelperBeat = nil
    if beat and beat >= 946684800 then
      if lastBeat and beat ~= lastBeat then
        anchorBeat, anchorTick = beat, tick
      end
      lastBeat = beat
    end
  end
  if anchorTick and tick - anchorTick <= 75 then
    return anchorBeat + math.max(0, tick - anchorTick)
  end
  return nil
end

function B.Now()
  if os and type(os.time) == "function" then
    local ok, now = pcall(os.time)
    if ok and type(now) == "number" then
      B.clockSource = "client"
      return now
    end
  end
  local now = helperNow()
  B.clockSource = now and "Global Bank helper" or "unavailable"
  return now
end

-- Epoch seconds of the last and the next 00:00 in Germany
function B.ResetTimes(utc)
  local offset = B.BerlinOffset(utc)
  local midnight = math.floor((utc + offset) / 86400) * 86400 - offset
  local nextOne = midnight + 86400
  return midnight, nextOne - (B.BerlinOffset(nextOne) - offset) -- day of a clock change: 23 or 25 hours
end

---------------------------------------------------------------------------
-- Saved state
---------------------------------------------------------------------------

local function char()
  if type(ZShop_Char) ~= "table" then
    ZShop_Char = {}
  end
  return ZShop_Char
end

local function shared()
  if type(ZShop_Settings) ~= "table" then
    ZShop_Settings = {}
  end
  return ZShop_Settings
end

function B.Get(key)
  local v = char()[key]
  if v == nil then
    v = shared()[key]
  end
  if v == nil then
    v = B.DEFAULTS[key]
  end
  return v
end

function B.Set(key, value)
  char()[key] = value
  shared()[key] = value
end

-- "claimed", "open" or "level" (not level 100 yet)
function B.State()
  local ok = me.CanDaily()
  if not ok then
    return "level"
  end
  local now, stamp = B.Now(), tonumber(char().claimed)
  if now and stamp and stamp >= (B.ResetTimes(now)) and stamp <= now then
    return "claimed"
  end
  return "open"
end

function B.MarkClaimed()
  local now = B.Now()
  if now and me.CanDaily() then
    char().claimed = now
  end
  B.Refresh()
end

function B.Unmark()
  char().claimed = nil
  me.Print("daily reward mark removed for this character.")
  B.Refresh()
end

---------------------------------------------------------------------------
-- The button (ZShopDailyButton in ZShop.xml)
---------------------------------------------------------------------------

-- Coordinates saved by older versions were absolute UI offsets. New positions
-- are fractions of the usable screen area, so they follow window/scale changes.
local function finite(value)
  value = tonumber(value)
  if value and value == value and value > -math.huge and value < math.huge then return value end
end

local function uiScale()
  local scale = type(GetUIScale) == "function" and finite(GetUIScale()) or nil
  return scale and scale > 0 and scale or 1
end

local function screenSize()
  local scale = uiScale()
  local w = type(GetScreenWidth) == "function" and finite(GetScreenWidth()) or nil
  local h = type(GetScreenHeight) == "function" and finite(GetScreenHeight()) or nil
  if w and h and w > 0 and h > 0 then return w / scale, h / scale, scale end
  local parent = _G["UIParent"]
  if parent and parent.GetWidth and parent.GetHeight then
    w, h = finite(parent:GetWidth()), finite(parent:GetHeight())
    if w and h and w > 0 and h > 0 then return w, h, scale end
  end
  return nil, nil, scale
end

local function travel(button, w, h)
  if not w or not h then return nil, nil end
  local bw = button.GetWidth and finite(button:GetWidth()) or 36
  local bh = button.GetHeight and finite(button:GetHeight()) or 36
  return math.max(0, w - (bw or 36)), math.max(0, h - (bh or 36))
end

local function clamp(n, maxValue)
  return math.max(0, math.min(n, maxValue))
end

local function positionSource()
  local c, s = char(), shared()
  if type(c.position) == "table" or (finite(c.x) and finite(c.y)) then return c end
  return s
end

local function relativePosition(source)
  local pos = source.position
  if type(pos) ~= "table" then return nil end
  local x, y = finite(pos.x), finite(pos.y)
  if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then return x, y end
end

-- Only migrate legacy positions that are visible: if the old resolution is
-- unknown, clamping is safer than guessing the position at the old size.
function B.InitializePosition()
  local button = _G["ZShopDailyButton"]
  if not button then return end
  local source = positionSource()
  if relativePosition(source) then return end
  local x, y = finite(source.x), finite(source.y)
  local w, h = screenSize()
  local maxX, maxY = travel(button, w, h)
  if x and y and maxX and maxY and maxX > 0 and maxY > 0 and
      x >= 0 and x <= maxX and y >= 0 and y <= maxY then
    source.position = { x = x / maxX, y = y / maxY }
  end
end

function B.Place()
  local button = _G["ZShopDailyButton"]
  if not button then return end
  local w, h, scale = screenSize()
  B.positionWidth, B.positionHeight, B.positionScale = w, h, scale
  local maxX, maxY = travel(button, w, h)
  local source = positionSource()
  local rx, ry = relativePosition(source)
  local x, y = finite(source.x), finite(source.y)
  if rx and maxX and maxY then
    x, y = rx * maxX, ry * maxY
  elseif x and y and maxX and maxY then
    x, y = clamp(x, maxX), clamp(y, maxY)
  end
  button:ClearAllAnchors()
  if x and y then
    button:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x, y)
  elseif _G["MinimapViewFrame"] then
    button:SetAnchor("RIGHT", "LEFT", "MinimapViewFrame", -8, -4)
  elseif maxX and maxY then
    button:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", clamp(w - 230 - (w - maxX), maxX), clamp(204, maxY))
  else
    button:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", -230, 204)
  end
end

function B.SavePlace(button)
  local x, y = button:GetPos()
  local w, h, scale = screenSize()
  x, y = finite(x), finite(y)
  if not x or not y then return end
  x, y = x / scale, y / scale
  local maxX, maxY = travel(button, w, h)
  B.Set("x", x)
  B.Set("y", y)
  if maxX and maxY and maxX > 0 and maxY > 0 then
    B.Set("position", { x = clamp(x, maxX) / maxX, y = clamp(y, maxY) / maxY })
  else
    B.Set("position", nil)
  end
  B.Place()
end

function B.Refresh()
  local button = _G["ZShopDailyButton"]
  if not button then
    return
  end
  if not B.Get("show") or not me.IsOn() then
    button:Hide()
    return
  end
  local state = B.State()
  local icon = _G["ZShopDailyButtonIcon"]
  if icon then
    icon:SetTexture(state == "claimed" and B.ICON_DONE or state == "level" and B.ICON_LOCKED or B.ICON)
  end
  if button.GetHighlightTexture and button:GetHighlightTexture() then
    pcall(button:GetHighlightTexture().SetTexture, button:GetHighlightTexture(), me.BASE_PATH .. "gfx/daily_hl.tga")
  end
  button:Show()
  me.UpdateWindow()
end

function B.OnLoad(button)
  B.Place()
  if button and button.RegisterForClicks then
    pcall(button.RegisterForClicks, button, "LeftButton", "RightButton")
  end
end

function B.IsDragKey(key)
  return key == "RBUTTON" or key == "RightButton" or (type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false)
end

function B.OnMouseDown(button, key)
  B.lastKey = key -- shown by /zshop probe
  button.zsDownX, button.zsDownY = button:GetPos()
  button.zsDragKey = B.IsDragKey(key)
  if button.zsDragKey and not B.Get("lock") then
    button:StartMoving()
    button.zsMoving = true
  end
end

function B.OnMouseUp(button, key)
  local moved = false
  local dragKey = button.zsDragKey
  button.zsDragKey = nil
  if button.zsMoving then
    button:StopMovingOrSizing()
    button.zsMoving = nil
    local x, y = button:GetPos()
    moved = math.abs(x - (button.zsDownX or x)) > 2 or math.abs(y - (button.zsDownY or y)) > 2
    if moved then
      B.SavePlace(button)
    end
  end
  if not moved and not dragKey then
    me.Open("daily")
  end
end

local function hm(seconds)
  seconds = math.max(0, seconds)
  return math.floor(seconds / 3600) .. " h " .. math.floor(seconds % 3600 / 60) .. " min"
end

function B.StatusText()
  local state = B.State()
  local now = B.Now()
  local text
  if state == "level" then
    local _, level = me.CanDaily()
    text = "|cff9ea8baNeeds level " .. me.DAILY_LEVEL .. " (this character " .. tostring(level) .. ")|r"
  elseif state == "claimed" then
    text = "|cff40ff40Daily page opened today on this character|r"
  else
    text = "|cffffd100Daily page not marked as opened today|r"
  end
  if now then
    local _, nextReset = B.ResetTimes(now)
    text = text .. "\n|cff9ea8baResets in " .. hm(nextReset - now) .. " (00:00 German time)|r"
  else
    text = text .. "\n|cffff6060No clock yet: start the Global Bank helper and wait up to a minute.|r"
  end
  return text
end

function B.OnEnter(button)
  if not GameTooltip then
    return
  end
  GameTooltip:SetOwner(button, "ANCHOR_LEFT")
  GameTooltip:SetText("Daily loyalty reward")
  for line in string.gmatch(B.StatusText(), "[^\n]+") do
    GameTooltip:AddLine(line)
  end
  GameTooltip:AddLine("|cff9ea8baClick: open the daily reward page, then press Collect|r")
  if not B.Get("lock") then
    GameTooltip:AddLine("|cff9ea8baRight-drag (or Shift+drag): move. Lock it in /zshop|r")
  end
  GameTooltip:Show()
end

function B.OnLeave()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

-- Check boxes in the ZShop window
function B.SetShown(value)
  B.Set("show", value and true or false)
  B.Refresh()
end

function B.SetLocked(value)
  B.Set("lock", value and true or false)
end

-- Every 30 seconds: the icon changes at the reset or when the character reaches level 100.
B.tick = 0
function B.OnUpdate(elapsed)
  B.positionTick = (B.positionTick or 0) + (tonumber(elapsed) or 0)
  if B.positionTick >= 1 then
    B.positionTick = 0
    local button = _G["ZShopDailyButton"]
    local w, h, scale = screenSize()
    if button and not button.zsMoving then
      if w ~= B.positionWidth or h ~= B.positionHeight or scale ~= B.positionScale then
        B.Place()
      end
      -- The minimap itself can be outside a newly resized window. Recover the
      -- default minimap-anchored button after the client resolves its anchor.
      local maxX, maxY = travel(button, w, h)
      if maxX and maxY and button.GetPos then
        local x, y = button:GetPos()
        x, y = finite(x), finite(y)
        if x and y then
          x, y = x / scale, y / scale
          if x < 0 or y < 0 or x > maxX or y > maxY then
            button:ClearAllAnchors()
            button:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", clamp(x, maxX), clamp(y, maxY))
          end
        end
      end
    end
  end
  -- Sample the helper clock even while the daily button is hidden or below level.
  B.clockTick = (B.clockTick or 0) + (tonumber(elapsed) or 0)
  if B.clockTick >= 5 then
    B.clockTick = 0
    B.Now()
  end
  B.tick = B.tick + (tonumber(elapsed) or 0)
  if B.tick >= 30 then
    B.tick = 0
    local state = B.State()
    if state ~= B.lastState then
      B.lastState = state
      B.Refresh()
    end
  end
end
