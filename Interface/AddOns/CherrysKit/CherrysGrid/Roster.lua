-- Cherry's Grid: who is in the group and in which order they are shown.
-- Also the unit functions the rest of the addon uses (G.U), so "/grid test" can show made-up members.

local G = CherrysGrid
local R = {}
G.Roster = R

R.units = {}      -- ordered list of { unit =, group =, pet = }
R.groups = {}     -- ordered list of { title =, units = { entry, ... } }
R.byUnit = {}     -- unit -> entry
R.byName = {}     -- character name -> unit
R.signature = ""
R.test = false

---------------------------------------------------------------------------
-- Unit functions (real client, or test members while /grid test is on)
---------------------------------------------------------------------------

local U = {}
G.U = U

local TEST_CLASSES = { "WARRIOR", "KNIGHT", "AUGUR", "DRUID", "MAGE", "RANGER", "THIEF", "WARDEN", "PSYRON", "HARPSYN" }
local TEST_NAMES = { "Aeris", "Brom", "Cyra", "Dain", "Elowen", "Faro", "Gwyn", "Hale", "Isolde", "Jory", "Kael", "Lyra",
  "Mira", "Nox", "Orin", "Pell", "Quin", "Rhea", "Sable", "Tarn", "Ula", "Vex", "Wren", "Xan", "Yara", "Zed",
  "Ash", "Bree", "Cole", "Dusk", "Ember", "Fen", "Gale", "Holt", "Ivy", "Jet" }

local function testIndex(unit)
  local n = string.match(tostring(unit or ""), "^cgtest(%d+)$")
  return n and tonumber(n)
end
U.TestIndex = testIndex

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then
    return a, b, c, d
  end
  return nil
end

function U.Name(unit)
  local t = testIndex(unit)
  if t then
    return TEST_NAMES[t] or ("Test" .. t)
  end
  local n = call(UnitName, unit)
  if n == "" then
    return nil
  end
  return n
end

function U.Exists(unit)
  if testIndex(unit) then
    return true
  end
  return U.Name(unit) ~= nil
end

function U.Class(unit)
  local t = testIndex(unit)
  if t then
    return TEST_CLASSES[(t - 1) % #TEST_CLASSES + 1], TEST_CLASSES[(t + 2) % #TEST_CLASSES + 1]
  end
  return call(UnitClassToken, unit)
end

function U.ClassNames(unit)
  local t = testIndex(unit)
  if t then
    return U.Class(unit)
  end
  return call(UnitClass, unit)
end

function U.Level(unit)
  if testIndex(unit) then
    return 100, 100
  end
  return call(UnitLevel, unit)
end

function U.Health(unit)
  local t = testIndex(unit)
  if t then
    local max = 20000 + t * 1000
    local cur = math.floor(max * (((t * 37) % 100) / 100))
    if t % 7 == 0 then
      cur = 0
    elseif t % 3 == 0 then
      cur = max
    end
    return cur, max
  end
  local cur = call(UnitHealth, unit) or 0
  local max = call(UnitMaxHealth, unit) or 0
  return cur, max
end

function U.Mana(unit)
  local t = testIndex(unit)
  if t then
    return 60 + (t * 13) % 40, 100, (t % 4 == 1) and 2 or 1
  end
  return call(UnitMana, unit) or 0, call(UnitMaxMana, unit) or 0, call(UnitManaType, unit) or 1
end

function U.Skill(unit)
  if testIndex(unit) then
    return 0, 0, 2
  end
  return call(UnitSkill, unit) or 0, call(UnitMaxSkill, unit) or 0, call(UnitSkillType, unit) or 2
end

function U.IsDead(unit)
  local t = testIndex(unit)
  if t then
    return t % 7 == 0
  end
  if call(UnitIsDeadOrGhost, unit) then
    return true
  end
  local cur, max = U.Health(unit)
  return max > 0 and cur <= 0
end

-- Raid and party members have an online flag (GetRaidMember / GetPartyMember second value).
function U.IsOnline(unit)
  local t = testIndex(unit)
  if t then
    return t ~= 11
  end
  local raid = string.match(tostring(unit), "^raid(%d+)$")
  if raid then
    local name, online = call(GetRaidMember, tonumber(raid))
    if name and online == false then
      return false
    end
    return true
  end
  local party = string.match(tostring(unit), "^party(%d+)$")
  if party then
    local name, online = call(GetPartyMember, tonumber(party))
    if name and online == false then
      return false
    end
  end
  return true
end

function U.IsUnit(a, b)
  if testIndex(a) or testIndex(b) then
    return a == b
  end
  if call(UnitIsUnit, a, b) then
    return true
  end
  local na, nb = U.Name(a), U.Name(b)
  return na ~= nil and na == nb
end

function U.IsLeader(unit)
  if testIndex(unit) then
    return testIndex(unit) == 1
  end
  return call(UnitIsRaidLeader, unit) and true or false
end

function U.IsAssistant(unit)
  if testIndex(unit) then
    return testIndex(unit) == 2
  end
  return call(UnitIsRaidAssistant, unit) and true or false
end

function U.IsLooter(unit)
  if testIndex(unit) then
    return false
  end
  return call(UnitIsMasterLooter, unit) and true or false
end

-- "tank", "attacker" or nil (raid roles set by the leader)
function U.Role(unit)
  local t = testIndex(unit)
  if t then
    return (t == 1 or t == 7) and "tank" or ((t == 2) and "attacker" or nil)
  end
  if call(UnitIsRaidMainTank, unit) then
    return "tank"
  end
  if call(UnitIsRaidMainAttacker, unit) then
    return "attacker"
  end
  return nil
end

function U.RaidIcon(unit)
  local t = testIndex(unit)
  if t then
    return (t == 4) and 1 or nil
  end
  local n = call(GetRaidTargetIndex, unit)
  n = tonumber(n)
  if n and n >= 1 and n <= 8 then
    return n
  end
  return nil
end

function U.Distance(unit)
  if testIndex(unit) then
    return nil
  end
  local d = call(UnitDistance, unit)
  return tonumber(d)
end

function U.Casting(unit)
  if testIndex(unit) then
    return nil
  end
  return call(UnitCastingTime, unit)
end

---------------------------------------------------------------------------
-- Roster
---------------------------------------------------------------------------

function R.SetTest(on)
  R.test = on and true or false
  R.signature = ""
  R.Update()
end

local function numRaid()
  return tonumber(GetNumRaidMembers and GetNumRaidMembers() or 0) or 0
end

local function numParty()
  return tonumber(GetNumPartyMembers and GetNumPartyMembers() or 0) or 0
end

function R.GroupType()
  if R.test then
    return "raid"
  end
  if numRaid() > 0 then
    return "raid"
  end
  for i = 1, 5 do
    if U.Exists("party" .. i) then
      return "party"
    end
  end
  if numParty() > 1 then
    return "party"
  end
  return "solo"
end

local CLASS_ORDER = { WARRIOR = 1, KNIGHT = 2, PSYRON = 3, WARDEN = 4, THIEF = 5, RANGER = 6, MAGE = 7, HARPSYN = 8,
  BARD = 9, DRUID = 10, AUGUR = 11 }

local function classOf(unit)
  local main = U.Class(unit)
  return main or "?"
end

local function sortUnits(list, by)
  if by == "name" then
    table.sort(list, function(a, b)
      return tostring(U.Name(a.unit)) < tostring(U.Name(b.unit))
    end)
  elseif by == "class" then
    table.sort(list, function(a, b)
      local ca, cb = CLASS_ORDER[classOf(a.unit)] or 99, CLASS_ORDER[classOf(b.unit)] or 99
      if ca ~= cb then
        return ca < cb
      end
      return a.index < b.index
    end)
  else
    table.sort(list, function(a, b)
      return a.index < b.index
    end)
  end
end

-- The members as { unit, index, group } before they are split into shown groups.
local function members(P, kind)
  local list = {}
  if kind == "raid" then
    local count = R.test and 36 or 36
    for i = 1, count do
      local unit = R.test and ("cgtest" .. i) or ("raid" .. i)
      if U.Exists(unit) then
        list[#list + 1] = { unit = unit, index = i, group = math.floor((i - 1) / 6) + 1 }
      end
    end
  elseif kind == "party" or kind == "solo" then
    list[1] = { unit = "player", index = 0, group = 1 }
    if kind == "party" then
      for i = 1, 5 do
        local unit = "party" .. i
        if U.Exists(unit) then
          list[#list + 1] = { unit = unit, index = i, group = 1 }
        end
      end
    end
  end
  return list
end

local function pets(list)
  local out = {}
  for _, e in ipairs(list) do
    local pet
    if e.unit == "player" then
      pet = "pet"
    elseif not U.TestIndex(e.unit) then
      pet = e.unit .. "pet"
    end
    if pet and U.Exists(pet) then
      out[#out + 1] = { unit = pet, index = e.index, group = 0, pet = true }
    end
  end
  return out
end

local ROLE_TITLES = { tank = "Tanks", attacker = "Attackers" }

-- Rebuilds R.groups. Returns true when who is shown (or where) changed.
function R.Update()
  local P = G.P
  local kind = R.GroupType()
  R.units, R.groups, R.byUnit, R.byName = {}, {}, {}, {}
  local show = (kind == "solo" and P.showSolo) or (kind == "party" and P.showParty) or (kind == "raid" and P.showRaid)
  local list = show and members(P, kind) or {}

  if kind == "raid" then
    local kept = {}
    for _, e in ipairs(list) do
      if P.raidGroups[e.group] ~= false then
        kept[#kept + 1] = e
      end
    end
    list = kept
  end
  local petList = (show and P.showPets) and pets(list) or {}

  local groups = {}
  if kind ~= "raid" then
    if not P.playerFirst then
      sortUnits(list, P.sortBy)
    elseif P.sortBy ~= "index" then
      local first = table.remove(list, 1)
      sortUnits(list, P.sortBy)
      table.insert(list, 1, first)
    end
    if P.groupBy == "none" or P.groupBy == "group" then
      groups[1] = { title = "Party", units = list }
    else
      R.SplitBy(list, P.groupBy, groups)
    end
  elseif P.groupBy == "group" then
    for g = 1, 6 do
      local units = {}
      for _, e in ipairs(list) do
        if e.group == g then
          units[#units + 1] = e
        end
      end
      if #units > 0 then
        sortUnits(units, P.sortBy)
        groups[#groups + 1] = { title = "Group " .. g, units = units }
      end
    end
  elseif P.groupBy == "none" then
    sortUnits(list, P.sortBy)
    local per = math.max(1, math.floor(tonumber(P.perLine) or 6))
    for i = 1, #list, per do
      local units = {}
      for j = i, math.min(#list, i + per - 1) do
        units[#units + 1] = list[j]
      end
      groups[#groups + 1] = { title = "", units = units }
    end
  else
    sortUnits(list, P.sortBy)
    R.SplitBy(list, P.groupBy, groups)
  end
  if #petList > 0 then
    sortUnits(petList, P.sortBy)
    groups[#groups + 1] = { title = "Pets", units = petList, pets = true }
  end

  -- no more than the frames there are
  local count, sig = 0, { kind }
  for _, grp in ipairs(groups) do
    local kept = {}
    for _, e in ipairs(grp.units) do
      if count < G.MAX_UNITS then
        count = count + 1
        e.slot = count
        kept[#kept + 1] = e
        R.units[count] = e
        R.byUnit[e.unit] = e
        local name = U.Name(e.unit)
        if name then
          R.byName[name] = e.unit
        end
        sig[#sig + 1] = e.unit .. "=" .. tostring(name)
      end
    end
    grp.units = kept
    if #kept > 0 then
      R.groups[#R.groups + 1] = grp
      sig[#sig + 1] = "|"
    end
  end
  local s = table.concat(sig, ",")
  local changed = s ~= R.signature
  R.signature = s
  return changed
end

-- Groups by main class or raid role, in a fixed order.
function R.SplitBy(list, by, groups)
  local buckets, order = {}, {}
  for _, e in ipairs(list) do
    local key
    if by == "role" then
      key = U.Role(e.unit) or "other"
    else
      key = classOf(e.unit)
    end
    if not buckets[key] then
      buckets[key] = {}
      order[#order + 1] = key
    end
    table.insert(buckets[key], e)
  end
  table.sort(order, function(a, b)
    if by == "role" then
      local w = { tank = 1, attacker = 2, other = 3 }
      return (w[a] or 9) < (w[b] or 9)
    end
    return (CLASS_ORDER[a] or 99) < (CLASS_ORDER[b] or 99)
  end)
  for _, key in ipairs(order) do
    local title = (by == "role") and (ROLE_TITLES[key] or "Others") or key
    groups[#groups + 1] = { title = title, units = buckets[key] }
  end
end
