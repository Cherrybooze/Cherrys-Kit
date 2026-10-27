-- Triggers.lua: turns game state into trigger states, the same role as WeakAuras' BuffTrigger2 and
-- GenericTrigger, rewritten for the RoM API.
--
-- A trigger state is a table:
--   show, name, icon, stacks, unit,
--   progressType = "timed" (duration + expirationTime) or "static" (value + total)

local RWA = RWA
local T = {}
RWA.Triggers = T

local function unitExists(unit)
  if unit == "player" then
    return true
  end
  if UnitExists then
    local ok, exists = pcall(UnitExists, unit)
    return ok and exists and exists ~= 0
  end
  return false
end

local function unitKey(unit)
  local key
  if UnitGUID then
    local ok, guid = pcall(UnitGUID, unit)
    key = ok and guid
  end
  if not key and UnitName then
    local ok, name = pcall(UnitName, unit)
    key = ok and name
  end
  return unit .. ":" .. tostring(key)
end

---------------------------------------------------------------------------
-- Buff and debuff scanning
---------------------------------------------------------------------------

-- UnitBuff/UnitDebuff(unit, i) -> name, icon, stacks, buffId
-- UnitBuffLeftTime/UnitDebuffLeftTime(unit, i) -> seconds left, or nil when the effect has no timer.
-- The LeftTime index matches UnitBuff, not UnitBuffInfo (which also lists hidden buffs).
local cache = {} -- ["unit|filter"] = list, cleared every poll and on UNIT_BUFF_CHANGED
local durations = {} -- ["unitKey|filter|id|name"] = { duration, expires, seen }
local scanSerial = 0

function T.InvalidateAuras()
  cache = {}
end

local function scan(unit, filter)
  local cacheKey = unit .. "|" .. filter
  local list = cache[cacheKey]
  if list then
    return list
  end
  list = {}
  cache[cacheKey] = list
  if not unitExists(unit) then
    return list
  end
  local helpful = filter ~= "HARMFUL"
  local getAura = helpful and UnitBuff or UnitDebuff
  local getLeft = helpful and UnitBuffLeftTime or UnitDebuffLeftTime
  if not getAura then
    return list
  end
  local now = RWA.Now()
  local who = unitKey(unit)
  scanSerial = scanSerial + 1
  for i = 1, 100 do
    local name, icon, stacks, id = getAura(unit, i)
    if not name or name == "" then
      break
    end
    local left = getLeft and getLeft(unit, i)
    local aura = { name = name, icon = icon, stacks = tonumber(stacks) or 0, id = id, index = i, unit = unit }
    if left and left > 0 then
      local key = who .. "|" .. filter .. "|" .. tostring(id) .. "|" .. name
      local rec = durations[key]
      -- First sighting, or the timer went up (refreshed): the time left now is the full duration.
      if not rec or left > (rec.expires - now) + 0.5 then
        rec = { duration = left, expires = now + left }
        durations[key] = rec
      else
        rec.expires = now + left
        if left > rec.duration then
          rec.duration = left
        end
      end
      rec.seen = scanSerial
      aura.duration = rec.duration
      aura.expirationTime = rec.expires
    end
    list[#list + 1] = aura
  end
  return list
end

-- Forget durations of auras that faded long ago, so a re-applied buff starts a fresh bar.
local function pruneDurations(now)
  for key, rec in pairs(durations) do
    if rec.expires < now - 2 then
      durations[key] = nil
    end
  end
end

local function lowerSet(list)
  local set = {}
  for _, v in ipairs(list or {}) do
    set[string.lower(tostring(v))] = true
  end
  return set
end

local function compare(a, op, b)
  if a == nil or b == nil then
    return false
  end
  a, b = tonumber(a), tonumber(b)
  if not a or not b then
    return false
  end
  if op == "<" then
    return a < b
  elseif op == "<=" then
    return a <= b
  elseif op == ">" then
    return a > b
  elseif op == ">=" then
    return a >= b
  elseif op == "==" or op == "=" then
    return a == b
  elseif op == "~=" or op == "!=" then
    return a ~= b
  end
  return false
end
T.Compare = compare

local evaluators = {}
-- Other files (KittyTracker.lua) add trigger types here: T.evaluators[type] = function(trigger, now, auraEnv) return state end
T.evaluators = evaluators

-- Runtime caches live outside the aura tables so they never reach the saved variables file.
local runtime = setmetatable({}, { __mode = "k" })
local function rt(trigger)
  local r = runtime[trigger]
  if not r then
    r = {}
    runtime[trigger] = r
  end
  return r
end

evaluators.aura = function(trigger)
  local unit = trigger.unit or "player"
  local filter = trigger.filter == "HARMFUL" and "HARMFUL" or "HELPFUL"
  local r = rt(trigger)
  r.names = r.names or lowerSet(trigger.names)
  r.ids = r.ids or lowerSet(trigger.ids)
  local found, count = nil, 0
  for _, aura in ipairs(scan(unit, filter)) do
    if r.names[string.lower(aura.name)] or (aura.id and r.ids[tostring(aura.id)]) then
      count = count + 1
      if not found then
        found = aura
      end
    end
  end
  if found and trigger.stacksOp and trigger.stacks and not compare(found.stacks, trigger.stacksOp, trigger.stacks) then
    found = nil
  end
  local showOn = trigger.showOn or "active"
  local state = { unit = unit, matchCount = count }
  if found then
    state.name = found.name
    state.icon = found.icon
    state.stacks = found.stacks
    state.auraId = found.id
    if found.duration then
      state.progressType = "timed"
      state.duration = found.duration
      state.expirationTime = found.expirationTime
    else
      state.progressType = "static"
      state.value, state.total = 1, 1
    end
  else
    state.name = trigger.names and trigger.names[1] or "?"
    state.progressType = "static"
    state.value, state.total = 0, 1
  end
  if showOn == "missing" then
    state.show = (found == nil) and (unit == "player" or unitExists(unit))
  elseif showOn == "always" then
    state.show = unit == "player" or unitExists(unit)
  else
    state.show = found ~= nil
  end
  return state
end

---------------------------------------------------------------------------
-- Status triggers: health, mana, secondary resource, combat, target, cast, cooldown
---------------------------------------------------------------------------

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then
    return a, b, c, d
  end
end

local skillCache = {}
-- A skill by its name or its ID (the number TooltipIds shows). An ID becomes the name with
-- TEXT("Sys<id>_name"), since GetSkillDetail returns names only.
function T.FindSkill(name)
  local id = tonumber(name)
  if id and TEXT then
    local ok, text = pcall(TEXT, "Sys" .. id .. "_name")
    if ok and type(text) == "string" and text ~= "" and not string.find(text, "^Sys%d") then
      name = text
    end
  end
  local key = string.lower(name or "")
  if skillCache[key] then
    return skillCache[key][1], skillCache[key][2]
  end
  if not GetSkillDetail then
    return
  end
  for page = 1, 5 do
    local num = call(GetNumSkill, page) or 60
    for slot = 1, num do
      local skillName = call(GetSkillDetail, page, slot)
      if skillName == nil then
        break
      end
      if string.lower(skillName) == key then
        skillCache[key] = { page, slot }
        return page, slot
      end
    end
  end
end

local function resource(trigger, getValue, getMax)
  local unit = trigger.unit or "player"
  local state = { unit = unit, progressType = "static" }
  if not unitExists(unit) then
    state.show = false
    return state
  end
  state.value = tonumber(call(getValue, unit)) or 0
  state.total = tonumber(call(getMax, unit)) or 0
  state.name = call(UnitName, unit) or unit
  state.percent = state.total > 0 and (state.value / state.total * 100) or 0
  state.show = true
  if trigger.op and trigger.value then
    local current = trigger.percent and state.percent or state.value
    state.show = compare(current, trigger.op, trigger.value)
  end
  return state
end

local status = {}
status.health = function(trigger)
  return resource(trigger, UnitHealth, UnitMaxHealth)
end
status.mana = function(trigger)
  return resource(trigger, UnitMana, UnitMaxMana)
end
-- RoM's second resource bar (rage, energy, focus) is "skill" in the API.
status.skill = function(trigger)
  return resource(trigger, UnitSkill, UnitMaxSkill)
end
-- When the current fight started, for %e (time in combat); nil out of combat.
local combatSince
status.combat = function(trigger, now)
  local inCombat = call(GetPlayerCombatState)
  inCombat = inCombat ~= nil and inCombat ~= false and inCombat ~= 0
  if inCombat then
    combatSince = combatSince or now
  else
    combatSince = nil
  end
  local show = inCombat
  if trigger.invert then
    show = not show
  end
  return {
    show = show,
    name = show and "In combat" or "Out of combat",
    progressType = "static",
    value = 1,
    total = 1,
    startTime = combatSince,
  }
end
-- Class: always shows, with the unit's primary/secondary class as name and its class-combo
-- icon (RWA.ClassIcon, see ClassIcons.lua). Polled, so it follows a class change at once.
status.class = function(trigger)
  local unit = trigger.unit or "player"
  if not unitExists(unit) then
    return { show = false }
  end
  local main, sub = call(UnitClass, unit)
  main, sub = main or "", sub or ""
  local name = (sub ~= "" and sub ~= main) and (main .. " / " .. sub) or main
  return {
    show = main ~= "",
    unit = unit,
    name = name,
    icon = RWA.ClassIcon and RWA.ClassIcon(main, sub) or nil,
    progressType = "static",
    value = 1,
    total = 1,
  }
end
status.target = function(trigger)
  local unit = trigger.unit or "target"
  local exists = unitExists(unit)
  local state = { unit = unit, progressType = "static", value = 1, total = 1 }
  state.name = exists and call(UnitName, unit) or ""
  state.show = exists
  if exists and trigger.enemy ~= nil then
    local hostile = call(UnitCanAttack, "player", unit)
    state.show = (hostile and true or false) == trigger.enemy
  end
  return state
end
-- UnitCastingTime(unit) -> spell name, total cast time, time already cast.
status.cast = function(trigger, now)
  local unit = trigger.unit or "player"
  local state = { unit = unit, show = false }
  if not unitExists(unit) then
    return state
  end
  local name, total, done = call(UnitCastingTime, unit)
  if name and total and total > 0 then
    state.show = true
    state.name = name
    state.progressType = "timed"
    state.duration = total
    state.expirationTime = now + math.max(0, total - (done or 0))
  end
  return state
end
-- GetSkillCooldown(page, slot) -> total cooldown, seconds remaining.
status.cooldown = function(trigger, now)
  local state = { name = trigger.skill or "?", show = false }
  local page, slot = T.FindSkill(trigger.skill)
  if not page then
    return state
  end
  local total, remaining = call(GetSkillCooldown, page, slot)
  remaining = tonumber(remaining) or 0
  local _, icon = call(GetSkillDetail, page, slot)
  state.icon = type(icon) == "string" and icon or nil
  local onCooldown = remaining > 0.05
  if onCooldown then
    state.progressType = "timed"
    state.duration = tonumber(total) and total > 0 and total or remaining
    state.expirationTime = now + remaining
  else
    state.progressType = "static"
    state.value, state.total = 1, 1
  end
  local showOn = trigger.showOn or "always"
  if showOn == "ready" then
    state.show = not onCooldown
  elseif showOn == "cooldown" then
    state.show = onCooldown
  else
    state.show = true
  end
  return state
end

evaluators.status = function(trigger, now)
  local fn = status[trigger.check or "health"]
  if not fn then
    return { show = false }
  end
  return fn(trigger, now)
end

---------------------------------------------------------------------------
-- Custom Lua triggers
---------------------------------------------------------------------------

-- Functions custom code may not call, in the spirit of WeakAuras' AuraEnvironment blocklist.
local BLOCKED = {
  "SaveVariables",
  "SaveVariablesPerCharacter",
  "SendChatMessage",
  "DeleteCharacter",
  "RWA_DB",
}

local function makeEnv(auraEnv)
  local env = { aura_env = auraEnv }
  for _, name in ipairs(BLOCKED) do
    env[name] = false
  end
  return setmetatable(env, { __index = _G })
end

-- Custom code is the body of a function; it returns show, and optionally a table of state fields:
--   return UnitHealth("target") < 1000, { name = "Execute!" }
function T.CompileCustom(code, auraEnv)
  if not loadstring then
    return nil, "this client has no loadstring"
  end
  local chunk, err = loadstring("return function(aura_env)\n" .. (code or "return false") .. "\nend", "rwa custom")
  if not chunk then
    return nil, err
  end
  if setfenv then
    setfenv(chunk, makeEnv(auraEnv))
  end
  local ok, fn = pcall(chunk)
  if not ok then
    return nil, fn
  end
  return fn
end

evaluators.custom = function(trigger, now, auraEnv)
  local r = rt(trigger)
  if r.fn == nil then
    local fn, err = T.CompileCustom(trigger.code, auraEnv)
    r.fn = fn or false
    if err then
      RWA.Error("custom trigger: " .. tostring(err))
    end
  end
  if not r.fn then
    return { show = false }
  end
  local ok, show, extra = pcall(r.fn, auraEnv)
  if not ok then
    RWA.Error("custom trigger: " .. tostring(show))
    return { show = false }
  end
  local state = { show = show and true or false, progressType = "static", value = 1, total = 1 }
  if type(extra) == "table" then
    for k, v in pairs(extra) do
      state[k] = v
    end
  end
  return state
end

function T.Evaluate(trigger, now, auraEnv)
  local fn = evaluators[trigger.type or "aura"]
  if not fn then
    return { show = false }
  end
  return fn(trigger, now, auraEnv)
end

-- Drop compiled code and lookup sets after the editor changes a trigger.
function T.Reset(trigger)
  runtime[trigger] = nil
end

function T.Tick(now)
  T.InvalidateAuras()
  pruneDurations(now)
end

RWA.On("UNIT_BUFF_CHANGED", function()
  T.InvalidateAuras()
  RWA.MarkDirty()
end)
RWA.On("LEARN_NEW_SKILL", function()
  skillCache = {}
end)
