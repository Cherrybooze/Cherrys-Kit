-- CherrysClock: real time for addons. The game's Lua has no clock of its own (no os library).
-- Global Bank's Daily Rewards extension has its local host write Windows' time, uptime counter and
-- time zone to a small file when Chrome starts, and whenever the extension talks to it.
-- GetTickCount() (the same uptime counter) carries that time forward, across characters and game
-- restarts, until Windows restarts. Nothing keeps running and the game server is not involved.
--   local hour, minute, second = CherrysClock.Time()      -- nil while unknown
--   local year, month, day = CherrysClock.Date()          -- nil while unknown
--   CherrysClock.UTC()                                    -- seconds since 1970, UTC
--   CherrysClock.Now()                                    -- the same, shifted to this PC's time zone
--
-- GetCurrentGameTime() is the game server's time on this PC's time zone as minutes, modulo 240.
-- It cannot give the time by itself, but it shows when the file is out of date: a whole number
-- of hours off means the time zone or daylight saving changed (corrected here); anything else
-- means Windows restarted without the file being written again.
CherrysClock = CherrysClock or {}
local me = CherrysClock

me.FILE = "Interface/GlobalBankHelper/CherrysClockStamp.lua"
me.WRAP = 4294967296 -- GetTickCount() wraps at 2^32 ms, and the game hands it over as a signed int
me.MAX_AGE = 40 * 86400 -- older than this is treated as out of date
me.TOLERANCE = 5 -- minutes the PC and server clocks may disagree by
me.CHECK_EVERY = 60
me.LOOK_EVERY = 10 -- seconds between looks at the file while the time is unknown

local function tick()
  if type(GetTickCount) ~= "function" then
    return nil
  end
  local ok, value = pcall(GetTickCount)
  return ok and tonumber(value) or nil
end

-- Reads the file without letting it touch anything else
local function readFile()
  if type(loadfile) ~= "function" then
    return nil
  end
  local fn = loadfile(me.FILE)
  if not fn then
    return nil
  end
  if type(setfenv) == "function" then
    setfenv(fn, {})
  end
  local ok, data = pcall(fn)
  if ok and type(data) == "table" and tonumber(data.utc) and tonumber(data.tick) then
    return { utc = tonumber(data.utc), tick = tonumber(data.tick), offset = tonumber(data.offset) or 0 }
  end
  return nil
end

-- Seconds since 1970, UTC, or nil while unknown
function me.UTC()
  local base = me.base
  local now = tick()
  if not base or not now then
    return nil
  end
  local age = (now - base.tick) % me.WRAP / 1000
  if age > me.MAX_AGE then
    return nil
  end
  return base.utc + age
end

-- The same, shifted to this PC's time zone: what Date() and Time() read
function me.Now()
  local utc = me.UTC()
  return utc and (utc + me.base.offset) or nil
end

-- Year, month, day on this PC, or nil while unknown (civil from days, Howard Hinnant)
function me.Date()
  local now = me.Now()
  if not now then
    return nil
  end
  local z = math.floor(now / 86400) + 719468
  local era = math.floor(z / 146097)
  local doe = z - era * 146097
  local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
  local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
  local mp = math.floor((5 * doy + 2) / 153)
  local day = doy - math.floor((153 * mp + 2) / 5) + 1
  local month = mp < 10 and mp + 3 or mp - 9
  local year = yoe + era * 400 + (month <= 2 and 1 or 0)
  return year, month, day
end

-- Hour, minute, second on this PC, or nil while unknown
function me.Time()
  local now = me.Now()
  if not now then
    return nil
  end
  local seconds = math.floor(now) % 86400
  return math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
end

-- Takes the file's time, unless it is the one already found out of date
function me.Look()
  local data = readFile()
  if data and data.utc ~= me.staleUtc then
    me.base = data
    me.lastGameTime = nil
  end
end

-- Compares with the game's minutes, once they are seen moving: they stand still in zones with
-- a fixed time of day, and read 0 until the first update
function me.Check()
  if type(GetCurrentGameTime) ~= "function" or not me.base then
    return
  end
  local ok, minutes = pcall(GetCurrentGameTime)
  minutes = ok and tonumber(minutes) or nil
  if not minutes then
    return
  end
  local moved = me.lastGameTime ~= nil and me.lastGameTime ~= minutes
  me.lastGameTime = minutes
  local now = me.Now()
  if not moved or not now then
    return
  end
  local off = (minutes - math.floor(now / 60) + 120) % 240 - 120 -- -120 .. 119
  local hours = math.floor(off / 60 + 0.5)
  if math.abs(off - hours * 60) > me.TOLERANCE then
    me.staleUtc = me.base.utc
    me.base = nil
  elseif hours ~= 0 then
    me.base.offset = me.base.offset + hours * 3600
  end
end

function me.OnEvent(event)
  if event == "VARIABLES_LOADED" then
    me.base = nil
    me.staleUtc = nil
    me.lastGameTime = nil
    me.checkWait = 0
    me.lookWait = 0
    me.Look()
    me.Check()
  end
end

function me.OnUpdate(elapsed)
  if not me.checkWait then
    return
  end
  elapsed = elapsed or 0
  if not me.UTC() then
    me.lookWait = me.lookWait + elapsed
    if me.lookWait >= me.LOOK_EVERY then
      me.lookWait = 0
      me.Look()
    end
  end
  me.checkWait = me.checkWait + elapsed
  if me.checkWait >= me.CHECK_EVERY then
    me.checkWait = 0
    me.Check()
  end
end
