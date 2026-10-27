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

function B.Now()
  return os and os.time and os.time() or nil
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

function B.Place()
  local button = _G["ZShopDailyButton"]
  if not button then
    return
  end
  button:ClearAllAnchors()
  local x, y = tonumber(B.Get("x")), tonumber(B.Get("y"))
  if x and y then
    button:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x, y)
  elseif _G["MinimapViewFrame"] then
    button:SetAnchor("RIGHT", "LEFT", "MinimapViewFrame", -8, -4) -- just above KittyCombo's mode button spot
  else
    button:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", -230, 204)
  end
end

function B.SavePlace(button)
  local x, y = button:GetPos()
  local scale = (type(GetUIScale) == "function" and GetUIScale()) or 1
  B.Set("x", x / scale)
  B.Set("y", y / scale)
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
    text = "|cff40ff40Claimed today on this character|r"
  else
    text = "|cffffd100Not claimed today|r"
  end
  if now then
    local _, nextReset = B.ResetTimes(now)
    text = text .. "\n|cff9ea8baResets in " .. hm(nextReset - now) .. " (00:00 German time)|r"
  else
    text = text .. "\n|cffff6060No clock in this client: the claimed mark can't be kept.|r"
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
