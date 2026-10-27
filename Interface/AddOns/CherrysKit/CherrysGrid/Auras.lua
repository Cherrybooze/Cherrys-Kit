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

local function scan(unit, getter, timeGetter)
  local out = {}
  if type(getter) ~= "function" then
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
    out[#out + 1] = {
      name = name,
      lname = string.lower(name),
      icon = icon,
      stacks = tonumber(stacks) or 0,
      id = tonumber(id),
      expires = (left and left > 0) and (t + left) or nil,
      index = i,
    }
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

function A.Get(unit)
  local c = A.cache[unit]
  local t = now()
  if c and t - c.time < A.RESCAN then
    return c
  end
  c = { time = t }
  local n = G.U.TestIndex(unit)
  if n then
    c.buffs, c.debuffs = testAuras(n)
  else
    c.buffs = scan(unit, UnitBuff, UnitBuffLeftTime)
    c.debuffs = scan(unit, UnitDebuff, UnitDebuffLeftTime)
  end
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

function A.ShownDebuffs(unit)
  local P = G.P
  local c = A.Get(unit)
  local list = A.ParseList(P.debuffList)
  local hide = A.ParseList(P.debuffHide)
  local alert = A.ParseList(P.debuffAlert)
  local maxTime = tonumber(P.debuffMaxTime) or 0
  local out = {}
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
  table.sort(out, function(x, y)
    return x.rank < y.rank
  end)
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
