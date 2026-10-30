-- CampNext: picks the character to log in after a relog requested in game.
-- In game, LogNextChar (/lnc, /lpc or ChangeChar) sets
--   LOGCHAR_FLAG = 1
--   LOGCHAR_MODE = "next" | "prev" | "current" | "index"
--   LOGCHAR_TARGET = <character index>   (only for "index")
-- and logs out. This file picks that up on the character select screen.
local me = {
  armed = 0,
  mode = nil,          -- "next", "prev", "current" or "index"
  wanted = nil,        -- index asked for by "index" mode
  lastIndex = nil,
  targetIndex = nil,
  retryTimer = 0,
  retryInterval = 0.5,
  waited = 0,
  timeout = 15,        -- seconds before giving up and leaving the screen to the user
}

local function log(msg)
  if lprint then
    lprint("[CampNext] " .. tostring(msg))
  end
end

local function reset()
  me.armed = 0
  me.mode = nil
  me.wanted = nil
  me.lastIndex = nil
  me.targetIndex = nil
  me.retryTimer = 0
  me.waited = 0
end

local function getPrevIndex(i, count)
  if not i or not count or count < 1 then
    return nil
  end
  if count == 1 then
    return 1
  end
  if i <= 1 then
    return count
  end
  return i - 1
end

local function getNextIndex(i, count)
  if not i or not count or count < 1 then
    return nil
  end
  if count == 1 then
    return 1
  end
  if i >= count then
    return 1
  end
  return i + 1
end

-- arms CampNext; usable from the DEBUG command box too ("campnext next")
function me.activate(mode, target)
  reset()
  me.armed = 1
  me.mode = mode or "next"
  me.wanted = tonumber(target)
  log("Armed mode=" .. tostring(me.mode) .. (me.wanted and (" target=" .. me.wanted) or ""))
end

function me.cancel()
  if me.armed == 1 then
    log("Cancelled")
  end
  reset()
end

local function importFlag()
  if _G.LOGCHAR_FLAG == 1 then
    local mode, target = _G.LOGCHAR_MODE, _G.LOGCHAR_TARGET
    _G.LOGCHAR_FLAG = 0
    _G.LOGCHAR_MODE = nil
    _G.LOGCHAR_TARGET = nil
    me.activate(mode, target)
  end
end

local function computeTarget(count)
  if me.mode == "next" then
    return getNextIndex(me.lastIndex, count)
  elseif me.mode == "prev" then
    return getPrevIndex(me.lastIndex, count)
  elseif me.mode == "current" then
    return me.lastIndex
  elseif me.mode == "index" then
    if me.wanted and me.wanted >= 1 and me.wanted <= count then
      return me.wanted
    end
  end
  return nil
end

local _original_onUpdate = login.charselect.onUpdate

login.charselect.onUpdate = function(frame, elapsed)
  if _original_onUpdate then
    _original_onUpdate(frame, elapsed)
  end

  importFlag()

  if me.armed ~= 1 then
    return
  end

  me.waited = me.waited + (elapsed or 0)
  if me.waited > me.timeout then
    log("Gave up after " .. me.timeout .. "s, pick a character by hand")
    reset()
    return
  end

  me.retryTimer = me.retryTimer + (elapsed or 0)
  if me.retryTimer < me.retryInterval then
    return
  end
  me.retryTimer = 0

  local selected = login.charselect.selected
  local count = GetNumCharacters and GetNumCharacters() or 0

  if not selected or selected < 1 then
    log("Waiting for selected index...")
    return
  end

  if count < 1 then
    log("Waiting for character count...")
    return
  end

  if selected > count then
    log("Selected index out of range: " .. tostring(selected) .. " / " .. tostring(count))
    return
  end

  if not me.lastIndex then
    me.lastIndex = selected
    log("Detected last index: " .. tostring(me.lastIndex))
    return
  end

  if not me.targetIndex then
    me.targetIndex = computeTarget(count)

    if not me.targetIndex then
      log("No valid target for mode=" .. tostring(me.mode) .. ", cancelled")
      reset()
      return
    end

    log("Target index: " .. tostring(me.targetIndex))
  end

  if selected == me.targetIndex then
    local name = GetCharacterInfo(me.targetIndex)

    if name then
      log("Logging into " .. tostring(me.targetIndex) .. " (" .. tostring(name) .. ")")
      login.charselect._locks.loginChar = name
      login.charselect._locks.loginTime = 1.0
      reset()
    end

    return
  end

  log("Force " .. tostring(selected) .. " -> " .. tostring(me.targetIndex))
  login.charselect.selected = me.targetIndex
  SelectCharacter(me.targetIndex)
end

-- Leave the character names (slot order) behind for LogNextChar's tooltips in game
local _original_updateList = login.charselect.updateCharacterList
login.charselect.updateCharacterList = function(...)
  _original_updateList(...)
  local roster = {}
  for i = 1, GetNumCharacters() do
    roster[i] = (GetCharacterInfo(i))
  end
  _G.LOGCHAR_ROSTER = roster
end

login.campnext = me

log("CampNext ready")
