-- What Global Bank knows, for the login screen: each character's gold and when it was saved, and
-- whether the helper is running. It only reads the helper's files, and nothing in them can touch the game.
local me = {
  DATABASE = 'interface/GlobalBankHelper/GlobalBankDatabase.lua',
  BEAT = 'interface/GlobalBankHelper/GlobalBankHelperBeat.lua', -- rewritten every 30 s while the helper runs
  STAMP = 'interface/GlobalBankHelper/CherrysClockStamp.lua', -- real time, when the Chrome extension is set up
  LATE = 75, -- seconds without a new beat before the helper counts as stopped
  CHECK_EVERY = 5,
  MAX_AGE = 40 * 86400,
  WRAP = 4294967296,
  characters = {},
  state = nil,
  wait = 0,
  watched = 0,
}

-- The globals a file sets, and what it returns. nil if it isn't there or can't run.
local function readFile(path)
  if type(loadfile) ~= 'function' then
    return nil
  end
  local fn = loadfile(path)
  if not fn then
    return nil
  end
  local env = {}
  setfenv(fn, env)
  local ok, result = pcall(fn)
  if not ok then
    return nil
  end
  return env, result
end

-- GB1~name~class~level~gold~bagSlots~bankSlots~bankSeen~time, then more records after a backtick,
-- with S~server among them. Names repeat between servers, so a character is found by both.
-- M~transmutor~amount is its Arcane Transmutor charges, left out at zero. A snapshot old enough to have
-- no server has no currencies either, so there no record means unknown, not zero.
function me.read()
  local env = readFile(me.DATABASE)
  local import = env and env.GlobalBank_Import
  me.characters = {}
  me.hasData = false
  if type(import) ~= 'table' then
    return false
  end
  for _, entry in ipairs(import) do
    local name, gold, when
    if type(entry) == 'table' then -- anything else in the file is skipped, never an error on the character screen
      name, gold, when = string.match(tostring(entry.s), '^GB1~([^~`]*)~[^~`]*~[^~`]*~([^~`]*)~[^~`]*~[^~`]*~[^~`]*~([^~`]*)')
    end
    if name and name ~= '' then
      local server = string.match(tostring(entry.s), '`S~([^`]*)')
      local key = string.lower(name)
      me.characters[key] = me.characters[key] or {servers = {}}
      local known = {gold = tonumber(gold) or 0, saved = when ~= '' and when or tostring(entry.saved or '')}
      known.charges = tonumber(string.match(tostring(entry.s), '`M~transmutor~(%d+)'))
      if not known.charges and server and server ~= '' then
        known.charges = 0
      end
      if server and server ~= '' then
        me.characters[key].servers[server] = known
      else
        known.unsure = true
        me.characters[key].unsure = known
      end
      me.hasData = true
    end
  end
  return me.hasData
end

-- One saved before servers were recorded could be either character, so it says so (a ? on the screen).
function me.character(name)
  local found = me.characters[string.lower(tostring(name))]
  if not found then
    return nil
  end
  local server = type(GetServerName) == 'function' and GetServerName() or nil
  return found.servers[server] or found.unsure
end

-- The character screen's column: gold, then charges when they're known, then when it was saved
function me.describe(known)
  local lines = {string.format('%s gold%s', me.formatGold(known.gold), known.unsure and ' ?' or '')}
  if known.charges then
    lines[#lines + 1] = string.format('Charges: %s', me.formatGold(known.charges))
  end
  lines[#lines + 1] = known.saved
  return table.concat(lines, '\n')
end

-- The same pieces for the Modern look, which lays them out itself: gold, charges (nil while unknown), saved
function me.parts(known)
  return me.formatGold(known.gold), known.charges and me.formatGold(known.charges) or nil, known.saved
end

function me.formatGold(amount)
  local text = string.format('%d', amount)
  while true do
    local changed
    text, changed = string.gsub(text, '^(%d+)(%d%d%d)', '%1,%2')
    if changed == 0 then
      return text
    end
  end
end

-- Now, in seconds since 1970, from the extension's stamp and Windows' uptime. nil while unknown.
local function realTime()
  if type(GetTickCount) ~= 'function' then
    return nil
  end
  local _, stamp = readFile(me.STAMP)
  local ok, tick = pcall(GetTickCount)
  if not ok or type(stamp) ~= 'table' or not tonumber(stamp.utc) or not tonumber(stamp.tick) or not tonumber(tick) then
    return nil
  end
  local elapsed = ((tonumber(tick) - tonumber(stamp.tick)) % me.WRAP) / 1000
  return elapsed <= me.MAX_AGE and tonumber(stamp.utc) + elapsed or nil
end

-- 'setup', 'running', 'stopped', or 'checking' until there's enough to go on: with no real time, only
-- a beat that changes proves the helper is alive.
function me.check(elapsed)
  local env = readFile(me.BEAT)
  local beat = env and tonumber(env.GlobalBank_HelperBeat)
  if not beat then
    return (me.hasData or readFile(me.DATABASE)) and 'stopped' or 'setup'
  end
  local now = realTime()
  if now then
    return now - beat <= me.LATE and 'running' or 'stopped'
  end
  if me.lastBeat and beat ~= me.lastBeat then
    me.lastBeat, me.watched = beat, 0
    return 'running'
  end
  if me.lastBeat then
    me.watched = me.watched + elapsed
  end
  me.lastBeat = beat
  if me.watched > me.LATE then
    return 'stopped'
  end
  return me.state == 'running' and 'running' or 'checking'
end

me.TEXT = {
  setup = '|cffffa040Global Bank isn\'t set up, so no gold shows on the character screen. Run Start Global Bank helper.bat in CherrysKit\\GlobalBank\\Helper.|r',
  stopped = '|cffffa040Global Bank helper isn\'t running, so gold on the character screen may be out of date.|r',
  running = '|cff60d060Global Bank helper is running.|r',
  checking = 'Checking the Global Bank helper...',
}

function me.show()
  local status = _G['LoginServerFrame_options_globalbank']
  if status and me.state then
    status:SetText(me.TEXT[me.state])
  end
end

function me.onUpdate(elapsed)
  me.wait = me.wait - elapsed
  if me.wait > 0 then
    return
  end
  local since = me.CHECK_EVERY - me.wait
  me.wait = me.CHECK_EVERY
  me.state = me.check(since)
  me.show()
end

login.globalbank = me
