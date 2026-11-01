-- Cherry's Grid: buffs and debuffs of each member, read from the client and kept for a moment.
-- UnitBuff / UnitDebuff(unit, i) give name, icon, stacks and id; Unit*LeftTime(unit, i) the seconds left
-- (nil for buffs without an end).

local G = CherrysGrid
local A = {}
G.Auras = A

A.cache = {}       -- unit -> { time =, buffs = {...}, debuffs = {...} }
A.MAX = 40
A.RESCAN = 2       -- seconds a scan is trusted without a UNIT_BUFF_CHANGED event

local function now()
  return (GetTime and GetTime()) or 0
end

function A.Forget(unit)
  if unit then
    A.cache[unit] = nil
    local name = UnitName and UnitName(unit)
    local u = name and G.Roster.byName[name]
    if u then
      A.cache[u] = nil
    end
  else
    A.cache = {}
  end
end

---------------------------------------------------------------------------
-- Lists typed by the player: names or ids, split by ";" or new lines. Kept parsed per text.
---------------------------------------------------------------------------

local parsed = {}

function A.ParseList(text)
  text = tostring(text or "")
  local p = parsed[text]
  if p then
    return p
  end
  p = { order = {}, set = {} }
  for item in string.gmatch(text, "[^;\n\r]+") do
    item = string.gsub(item, "^%s+", "")
    item = string.gsub(item, "%s+$", "")
    if item ~= "" then
      local key = tonumber(item) or string.lower(item)
      if p.set[key] == nil then
        p.order[#p.order + 1] = key
        p.set[key] = #p.order
      end
    end
  end
  parsed[text] = p
  return p
end

-- Position of an aura in a list (1 = first), or nil.
function A.InList(list, aura)
  if aura.id and list.set[aura.id] then
    return list.set[aura.id]
  end
  return list.set[aura.lname]
end

---------------------------------------------------------------------------
-- Scanning
---------------------------------------------------------------------------

-- Fills `out` (the member's own list, kept between scans) and reuses its aura tables, so a buff
-- change on one member in a fight makes no new tables. Returns the list.
local function scan(unit, getter, timeGetter, out)
  local count = 0
  if type(getter) ~= "function" then
    for i = #out, 1, -1 do
      out[i] = nil
    end
    return out
  end
  local t = now()
  for i = 1, A.MAX do
    local ok, name, icon, stacks, id = pcall(getter, unit, i)
    if not ok or not name or name == "" then
      break
    end
    local left = nil
    if type(timeGetter) == "function" then
      local ok2, l = pcall(timeGetter, unit, i)
      if ok2 then
        left = tonumber(l)
      end
    end
    count = count + 1
    local a = out[count]
    if not a then
      a = {}
      out[count] = a
    end
    a.name = name
    a.lname = string.lower(name)
    a.icon = icon
    a.stacks = tonumber(stacks) or 0
    a.id = tonumber(id)
    a.expires = (left and left > 0) and (t + left) or nil
    a.index = i
    a.rank = nil
  end
  for i = #out, count + 1, -1 do
    out[i] = nil
  end
  return out
end

-- Test members get a few made-up auras so the indicators can be seen.
local function testAuras(n)
  local t = now()
  local TEST_ICON = G.MEDIA .. "test_buff.tga"
  local buffs, debuffs = {}, {}
  if n % 2 == 0 then
    buffs[#buffs + 1] = { name = "Regenerate", lname = "regenerate", icon = TEST_ICON, stacks = 0, expires = t + 4 + n % 15 }
  end
  if n % 5 == 0 then
    buffs[#buffs + 1] = { name = "Wave Armor", lname = "wave armor", icon = TEST_ICON, stacks = 0, expires = t + 40 }
  end
  if n % 4 == 1 then
    debuffs[#debuffs + 1] = { name = "Poison", lname = "poison", icon = G.MEDIA .. "test_debuff.tga", stacks = 2,
      expires = t + 3 + n % 9 }
  end
  if n % 6 == 1 then
    debuffs[#debuffs + 1] = { name = "Burn", lname = "burn", icon = G.MEDIA .. "test_debuff2.tga", stacks = 0, expires = t + 12 }
  end
  for _, list in ipairs({ buffs, debuffs }) do
    for i, a in ipairs(list) do
      a.index = i
    end
  end
  return buffs, debuffs
end

-- Each member keeps one scan table (and its lists) for good; A.Forget only drops it from A.cache,
-- so the next A.Get scans again into the same tables.
local scans = {}
local scanCount = 0

function A.Get(unit)
  local c = A.cache[unit]
  local t = now()
  if c and t - c.time < A.RESCAN then
    return c
  end
  local n = G.U.TestIndex(unit)
  if n then
    c = { time = t }
    c.buffs, c.debuffs = testAuras(n)
  else
    c = scans[unit]
    if not c then
      c = { buffs = {}, debuffs = {} }
      scans[unit] = c
    end
    c.time = t
    scan(unit, UnitBuff, UnitBuffLeftTime, c.buffs)
    scan(unit, UnitDebuff, UnitDebuffLeftTime, c.debuffs)
  end
  scanCount = scanCount + 1
  c.scan = scanCount
  A.cache[unit] = c
  return c
end

function A.TimeLeft(aura)
  if not aura.expires then
    return nil
  end
  local left = aura.expires - now()
  if left < 0 then
    left = 0
  end
  return left
end

-- First aura of `list` in `auras` (buffs or debuffs), in the list's order.
function A.FindFromList(auras, list)
  local best, bestPos
  for _, a in ipairs(auras) do
    local pos = A.InList(list, a)
    if pos and (not bestPos or pos < bestPos) then
      best, bestPos = a, pos
    end
  end
  return best
end

-- Every aura of `auras` named in `list`.
function A.AllFromList(auras, list)
  local out = {}
  for _, a in ipairs(auras) do
    if A.InList(list, a) then
      out[#out + 1] = a
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Debuffs chosen by the options, most important first
---------------------------------------------------------------------------

local function byRank(x, y)
  return x.rank < y.rank
end

-- One drawing asks for the same member's debuffs up to three times (the debuff statuses and the
-- debuff row): the list is the member's own, worked out again only when the scan, the time or a
-- debuff option changed.
local shown = {}

function A.ShownDebuffs(unit)
  local P = G.P
  local c = A.Get(unit)
  local t = now()
  local m = shown[unit]
  if not m then
    m = { list = {} }
    shown[unit] = m
  end
  if m.scan == c.scan and m.c == c and m.t == t and m.P == P and m.mode == P.debuffMode
    and m.listText == P.debuffList and m.hideText == P.debuffHide and m.alertText == P.debuffAlert
    and m.maxTime == P.debuffMaxTime and m.noPermanent == P.debuffNoPermanent then
    return m.list
  end
  m.scan, m.c, m.t, m.P, m.mode = c.scan, c, t, P, P.debuffMode
  m.listText, m.hideText, m.alertText = P.debuffList, P.debuffHide, P.debuffAlert
  m.maxTime, m.noPermanent = P.debuffMaxTime, P.debuffNoPermanent
  local list = A.ParseList(P.debuffList)
  local hide = A.ParseList(P.debuffHide)
  local alert = A.ParseList(P.debuffAlert)
  local maxTime = tonumber(P.debuffMaxTime) or 0
  local out = m.list
  for i = #out, 1, -1 do
    out[i] = nil
  end
  for _, a in ipairs(c.debuffs) do
    local pos = A.InList(list, a)
    local ok = not A.InList(hide, a)
    if ok and P.debuffMode == "listed" and not pos and not A.InList(alert, a) then
      ok = false
    elseif ok and P.debuffMode == "unlisted" and pos then
      ok = false
    end
    local left = A.TimeLeft(a)
    if ok and P.debuffNoPermanent and not left then
      ok = false
    end
    if ok and maxTime > 0 and left and left > maxTime then
      ok = false
    end
    if ok then
      local alertPos = A.InList(alert, a)
      -- important ones first, then the priority list, then the game's order
      a.rank = (alertPos and alertPos or 1000) * 10000 + (pos or 1000) * 100 + a.index
      out[#out + 1] = a
    end
  end
  table.sort(out, byRank)
  return out
end

-- Buffs selected by the enabled tracked-buff lists and present-buff watches.
local BUFF_LISTS = { { "hots", "hotList" }, { "shields", "shieldList" }, { "salves", "salveList" } }
local shownBuffs = {} -- unit -> { lists =, out = }, refilled on each call

function A.ShownBuffs(unit)
  local P = G.P
  local m = shownBuffs[unit]
  if not m then
    m = { lists = {}, out = {} }
    shownBuffs[unit] = m
  end
  local lists = m.lists
  for i = #lists, 1, -1 do
    lists[i] = nil
  end
  for _, pair in ipairs(BUFF_LISTS) do
    local status = P.statuses and P.statuses[pair[1]]
    if status and status.on then lists[#lists + 1] = A.ParseList(P[pair[2]]) end
  end
  for _, watch in ipairs(P.watches or {}) do
    if watch.on and watch.kind ~= "debuff" and not watch.missing and watch.name and watch.name ~= "" then
      lists[#lists + 1] = A.ParseList(watch.name)
    end
  end
  local out = m.out
  for i = #out, 1, -1 do
    out[i] = nil
  end
  for _, aura in ipairs(A.Get(unit).buffs) do
    for _, list in ipairs(lists) do
      if A.InList(list, aura) then
        out[#out + 1] = aura
        break
      end
    end
  end
  return out
end

-- Short text for a time: 1d, 3h, 12m, 9 (seconds)
function A.FormatTime(left)
  if not left then
    return ""
  end
  if left >= 86400 then
    return math.ceil(left / 86400) .. "d"
  elseif left >= 3600 then
    return math.ceil(left / 3600) .. "h"
  elseif left >= 60 then
    return math.ceil(left / 60) .. "m"
  end
  return tostring(math.ceil(left))
end
