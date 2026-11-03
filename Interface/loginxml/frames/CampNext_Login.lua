-- CampNext: picks the character to log in after a relog requested in game.
-- In game, LogNextChar (/lnc, /lpc or ChangeChar) sets
--   LOGCHAR_FLAG = 1
--   LOGCHAR_MODE = "next" | "prev" | "current" | "index" | "slot"
--   LOGCHAR_TARGET = the character's number on the character screen ("index", /lnc <number>)
--                    or its slot in the game's own order ("slot", ChangeChar)
--   LOGCHAR_FROM = <name of the character being left>
-- Next, Prev and numbers follow the order the character screen numbers the characters in, which is the
-- game's own unless it was changed there with Edit character order (login.charselect.order).
-- and logs out. This file picks that up on the character select screen.
-- The client fills the character list one character at a time and only then selects the one last played
-- (UPDATE_SELECTED_CHARACTER, then UPDATE_CHARACTER_SELECT_LIST). So nothing is picked before that list is
-- in, and the pick is held until the login starts: a late selection from the client can't undo it.
local me = {
  armed = 0,
  mode = nil,          -- "next", "prev", "current", "index" or "slot"
  wanted = nil,        -- number asked for by "index" mode, slot by "slot" mode
  lastIndex = nil,
  targetIndex = nil,
  retryTimer = 0,
  retryInterval = 0.5,
  waited = 0,
  timeout = 15,        -- seconds before giving up and leaving the screen to the user
  from = nil,          -- name of the character the switch started from
  listIn = false,      -- the client has sent the whole character list since arming
  listWait = 6,        -- seconds to wait for that list before going on with what is there
  entering = nil,      -- name of the character about to be logged in
  enterWait = 0,
  enterDelay = 1.0,    -- seconds on the target before logging in, so its model shows first
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
  me.from = nil
  me.listIn = false
  me.entering = nil
  me.enterWait = 0
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

-- arms CampNext; usable from the DEBUG command box too ("campnext next"), where the list is already in
function me.activate(mode, target, from, listIn)
  reset()
  me.armed = 1
  me.mode = mode or "next"
  me.wanted = tonumber(target)
  me.from = type(from) == "string" and from ~= "" and from or nil
  me.listIn = listIn ~= false
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
    local mode, target, from = _G.LOGCHAR_MODE, _G.LOGCHAR_TARGET, _G.LOGCHAR_FROM
    _G.LOGCHAR_FLAG = 0
    _G.LOGCHAR_MODE = nil
    _G.LOGCHAR_TARGET = nil
    _G.LOGCHAR_FROM = nil
    me.activate(mode, target, from, false)
  end
end

-- The game's indexes in number order: numbered(count)[n] is the character with number n
local function numbered(count)
  local ok, order = pcall(login.charselect.order)
  if ok and type(order) == "table" and #order == count then
    return order
  end
  order = {}
  for i = 1, count do
    order[i] = i
  end
  return order
end

local function computeTarget(count)
  if me.mode == "current" then
    return me.lastIndex
  elseif me.mode == "slot" then
    if me.wanted and me.wanted >= 1 and me.wanted <= count then
      return me.wanted
    end
    return nil
  end
  local order = numbered(count)
  if me.mode == "index" then
    return me.wanted and order[me.wanted] or nil
  end
  local pos
  for number, index in ipairs(order) do
    if index == me.lastIndex then
      pos = number
    end
  end
  if me.mode == "next" then
    pos = getNextIndex(pos, count)
  elseif me.mode == "prev" then
    pos = getPrevIndex(pos, count)
  else
    pos = nil
  end
  return pos and order[pos] or nil
end

-- Where the switch starts: the character it was asked from, found by name, else the one the client selected
local function startIndex(selected, count)
  if me.from then
    for i = 1, count do
      if GetCharacterInfo(i) == me.from then
        return i
      end
    end
  end
  return selected
end

-- On the target: wait a moment, putting the selection back if anything moved it, then log in
local function enter(selected, elapsed)
  if selected ~= me.targetIndex or GetCharacterInfo(me.targetIndex) ~= me.entering then
    if GetCharacterInfo(me.targetIndex) ~= me.entering then
      log("The character list changed, cancelled")
      reset()
      return
    end
    log("Selection moved to " .. tostring(selected) .. ", back to " .. tostring(me.targetIndex))
    login.charselect.selected = me.targetIndex
    SelectCharacter(me.targetIndex)
    me.enterWait = me.enterDelay
    return
  end
  me.enterWait = me.enterWait - (elapsed or 0)
  if me.enterWait > 0 then
    return
  end
  log("Logging into " .. tostring(me.targetIndex) .. " (" .. tostring(me.entering) .. ")")
  reset()
  login.charselect.login()
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

  if me.entering then
    enter(login.charselect.selected, elapsed)
    return
  end

  if not me.listIn then
    if me.waited < me.listWait then
      return
    end
    log("No character list after " .. me.listWait .. "s, going on with what is there")
    me.listIn = true
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
    me.lastIndex = startIndex(selected, count)
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
      me.entering = name
      me.enterWait = me.enterDelay
    end

    return
  end

  log("Force " .. tostring(selected) .. " -> " .. tostring(me.targetIndex))
  login.charselect.selected = me.targetIndex
  SelectCharacter(me.targetIndex)
end

-- The whole list is in once the client sends this, with the last played character already selected
local _original_listEvent = login.charselect.UPDATE_CHARACTER_SELECT_LIST
login.charselect.UPDATE_CHARACTER_SELECT_LIST = function(...)
  importFlag() -- before the stock auto login looks, so a queued switch keeps the screen
  _original_listEvent(...)
  if me.armed == 1 and not me.listIn then
    me.listIn = true
    me.waited = 0 -- a slow list (a queue on the server) doesn't eat into the time to switch
  end
end

-- Leave the character names behind for LogNextChar's buttons and tooltips in game: LOGCHAR_ROSTER in the
-- game's slot order, LOGCHAR_ORDER in number order
local _original_updateList = login.charselect.updateCharacterList
login.charselect.updateCharacterList = function(...)
  _original_updateList(...)
  -- Global Bank records it with each character: names repeat between servers
  if type(GetServerName) == "function" then
    LOGCHAR_SERVER = GetServerName()
  end
  local count = GetNumCharacters()
  local roster, order = {}, {}
  for i = 1, count do
    roster[i] = (GetCharacterInfo(i))
  end
  for number, index in ipairs(numbered(count)) do
    order[number] = roster[index]
  end
  _G.LOGCHAR_ROSTER = roster
  _G.LOGCHAR_ORDER = order
end

login.campnext = me

log("CampNext ready")
