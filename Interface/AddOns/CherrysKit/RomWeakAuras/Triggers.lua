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
local knownAuras = {}

local function rememberAura(aura)
  if not aura.icon then
    return
  end
  local info = { name = aura.name, icon = aura.icon, id = aura.id }
  knownAuras["name:" .. string.lower(aura.name)] = info
  if aura.id then
    local key = tostring(aura.id)
    knownAuras[key] = info
    if type(RWA_DB) == "table" then
      RWA_DB.buffInfo = RWA_DB.buffInfo or {}
      local store = RWA_DB.buffInfo
      if store[key] == nil then
        -- Keep the remembered-buff cache bounded. Cleared entries are rebuilt
        -- the next time the buff is seen.
        local count = 0
        for _ in pairs(store) do count = count + 1 end
        if count >= 4000 then
          local drop = {}
          for name in pairs(store) do
            drop[#drop + 1] = name
            if #drop >= 1000 then break end
          end
          for _, name in ipairs(drop) do store[name] = nil end
        end
      end
      store[key] = info
    end
  end
end

function T.InvalidateAuras()
  cache = {}
end

local function scan(unit, filter, observedNow)
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
  local now = observedNow or RWA.Now()
  local who = unitKey(unit)
  scanSerial = scanSerial + 1
  for i = 1, 100 do
    local name, icon, stacks, id = getAura(unit, i)
    if not name or name == "" then
      break
    end
    local left = getLeft and getLeft(unit, i)
    local aura = { name = name, icon = icon, stacks = tonumber(stacks) or 0, id = id, index = i, unit = unit }
    rememberAura(aura)
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

-- Editor shortcuts keep the existing aura schema, including shared/imported codes.
function T.GetOptionType(trigger)
  local kind = trigger.type or "aura"
  if kind == "aura" and trigger.filter ~= "HARMFUL" and trigger.showOn == "missing"
    and not (trigger.stacksOp and trigger.stacks) then
    return "buffmissing"
  end
  return kind
end

function T.SetOptionType(trigger, kind)
  local previous = T.GetOptionType(trigger)
  trigger.type = kind == "buffmissing" and "aura" or kind
  if kind == "buffmissing" then
    trigger.filter, trigger.showOn = "HELPFUL", "missing"
    trigger.stacksOp, trigger.stacks = nil, nil
  elseif kind == "aura" and previous == "buffmissing" then
    trigger.showOn = "active"
  end
end

-- An absent buff still needs a name and picture. Prefer the actual buff observed
-- by ID, then the skill book when its localized name matches that buff.
function T.AuraInfo(trigger)
  local id = trigger.ids and trigger.ids[1]
  local key = id and tostring(id)
  local info = key and (knownAuras[key] or (RWA_DB and RWA_DB.buffInfo and RWA_DB.buffInfo[key]))
  if info then
    return info
  end
  local name = trigger.names and trigger.names[1]
  if id and TEXT then
    local ok, value = pcall(TEXT, "Sys" .. tostring(id) .. "_name")
    if ok and type(value) == "string" and value ~= "" and not string.find(value, "^Sys%d") then
      name = value
    end
  end
  info = name and knownAuras["name:" .. string.lower(name)]
  if info and (not id or tostring(info.id) == key) then
    return info
  end
  if name and T.FindSkill and GetSkillDetail then
    local page, slot = T.FindSkill(name)
    if page then
      local ok, _, icon = pcall(GetSkillDetail, page, slot)
      if ok and type(icon) == "string" and icon ~= "" then
        return { name = name, icon = icon, id = id }
      end
    end
  end
  return { name = name or (id and ("#" .. tostring(id))) or "?", id = id }
end

evaluators.aura = function(trigger, now)
  now = now or RWA.Now()
  local unit = trigger.unit or "player"
  local filter = trigger.filter == "HARMFUL" and "HARMFUL" or "HELPFUL"
  local r = rt(trigger)
  r.names = r.names or lowerSet(trigger.names)
  r.ids = r.ids or lowerSet(trigger.ids)
  local found, count = nil, 0
  for _, aura in ipairs(scan(unit, filter, now)) do
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
    local info = T.AuraInfo(trigger)
    state.name, state.icon, state.auraId = info.name, info.icon, info.id
    state.stacks = 0
    state.progressType = "static"
    state.value, state.total = 0, 1
  end
  if showOn == "missing" then
    state.show = (found == nil) and (unit == "player" or unitExists(unit))
  elseif showOn == "missingOrExpiring" then
    local low = found and found.expirationTime and compare(
      math.max(0, found.expirationTime - now), trigger.remainingOp or "<", trigger.remaining or 3)
    state.show = (found == nil or low == true) and (unit == "player" or unitExists(unit))
  elseif showOn == "always" then
    state.show = unit == "player" or unitExists(unit)
  else
    state.show = found ~= nil
  end
  if showOn == "active" and state.show and trigger.remainingOp and trigger.remaining ~= nil then
    state.show = found.expirationTime ~= nil and compare(
      math.max(0, found.expirationTime - now), trigger.remainingOp, trigger.remaining)
  end
  return state
end

-- Unfiltered observations for version 2 rules. Buff presence is read before
-- any legacy showOn, remaining or stacks filters are applied.
function T.Observe(source, now, env)
  local kind = source.type or "aura"
  if kind ~= "aura" then
    if not evaluators[kind] then return nil end
    local state = T.Evaluate(source, now, env)
    if type(state) ~= "table" then return nil end
    -- Typed resources are already normalized, shared observations. Keep their
    -- availability (including active zero) and immutable cache intact.
    if kind=="resource" then return state end
    state.available = state.available ~= false
    state.unitAvailable = unitExists(source.unit or "player") and true or false
    state.active = state.show == true
    state.present = state.active
    state.timed = state.progressType == "timed" and tonumber(state.expirationTime) ~= nil
    if state.timed then state.remaining = math.max(0, state.expirationTime - now) end
    return state
  end
  local unit = source.unit or "player"
  local available = unitExists(unit) and true or false
  local state = { available = available, unitAvailable = available, present = false, timed = false, unit = unit }
  if not available then return state end
  local r = rt(source)
  r.names, r.ids = r.names or lowerSet(source.names), r.ids or lowerSet(source.ids)
  local found
  for _, aura in ipairs(scan(unit, source.filter == "HARMFUL" and "HARMFUL" or "HELPFUL", now)) do
    if r.names[string.lower(aura.name)] or (aura.id and r.ids[tostring(aura.id)]) then
      found = aura
      break
    end
  end
  if found then
    state.present, state.active, state.show = true, true, true
    state.name, state.icon, state.stacks, state.buffId, state.auraId = found.name, found.icon, found.stacks, found.id, found.id
    if found.expirationTime then
      state.timed, state.progressType = true, "timed"
      state.duration, state.expirationTime = found.duration, found.expirationTime
      state.remaining = math.max(0, found.expirationTime - now)
    else
      state.progressType, state.value, state.total = "static", 1, 1
    end
  else
    local info = T.AuraInfo(source)
    state.name, state.icon, state.buffId, state.auraId = info.name, info.icon, info.id, info.id
    state.show, state.active, state.stacks = false, false, 0
    state.progressType, state.value, state.total = "static", 0, 1
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
  local cached = skillCache[key]
  if cached then
    if cached[1] then return cached[1], cached[2] end
    if RWA.Now() < cached.retryAt then return end
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
  -- A missing skill may become available after a class or skill change.
  -- Avoid scanning the whole skill book on every aura update in the meantime.
  skillCache[key] = { retryAt = RWA.Now() + 5 }
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

-- The client can expose NPC health as a percentage. pbInfo learns a maximum
-- at full health; scaling its recorded maximum is an estimate, not exact HP.
local targetHealthKey,targetHealthMax
local function targetHealthText(state)
  local isPlayer=call(rawget(_G,"UnitIsPlayer"),"target")
  if isPlayer==nil or isPlayer==true or (type(isPlayer)=="number" and isPlayer~=0) then return end
  if state.total~=100 or state.value<0 or state.value>100 then return end
  local guid=call(rawget(_G,"UnitGUID"),"target")
  if guid~=targetHealthKey then targetHealthKey,targetHealthMax=guid,nil end
  local changed=tonumber(call(rawget(_G,"UnitChangeHealth"),"target"))
  if state.value==100 and changed and changed>0 and guid then targetHealthMax=changed end
  local max=targetHealthMax
  local mobdb=type(pbInfo)=="table" and pbInfo.MobDB
  if type(mobdb)=="table" then
    if type(mobdb.Update)=="function" then pcall(mobdb.Update,"target") end
    local name=call(rawget(_G,"UnitName"),"target")
    local level=call(rawget(_G,"UnitLevel"),"target")
    local class=call(rawget(_G,"UnitClass"),"target")
    local byName=type(mobdb.Mobs)=="table" and mobdb.Mobs[name]
    local byLevel=type(byName)=="table" and byName[level]
    local byClass=type(byLevel)=="table" and byLevel[class]
    local known=type(byClass)=="table" and tonumber(byClass.healthpoints)
    if known and known>0 then max=known end
  end
  if not max and state.value==100 and changed and changed>0 then max=changed end
  state.healthText=max and ("~"..math.ceil(max*state.value/100).." / "..max) or (tostring(state.value).."%")
end
local status = {}
-- Read equipped durability at most once per second, shared by all durability
-- sources. Compare the raw values, not percentages or localized tooltip text.
local durabilitySlots={0,1,2,3,4,5,6,7,8,9,11,12,13,14,16,17,21,15,10}
local durabilityItems,durabilityAt={},nil
local function equippedDurability(now)
  now=tonumber(now) or RWA.Now()
  if durabilityAt and now>=durabilityAt and now-durabilityAt<1 then return durabilityItems end
  durabilityAt,durabilityItems=now,{}
  local get=rawget(_G,"GetInventoryItemDurable")
  if type(get)~="function" then return durabilityItems end
  for _,slot in ipairs(durabilitySlots) do
    local ok,current,maximum,name=pcall(get,"player",slot)
    current,maximum=tonumber(current),tonumber(maximum)
    if ok and type(name)=="string" and name~="" and current and maximum and maximum>0 and current>=0 then
      durabilityItems[#durabilityItems+1]={value=current,total=maximum,name=name,slot=slot}
    end
  end
  return durabilityItems
end
status.durability = function(trigger,now)
  local minimum=tonumber(trigger.minimumMax) or 101
  local lowest
  for _,item in ipairs(equippedDurability(now)) do
    if item.total>=minimum and (not lowest or item.value<lowest.value) then lowest=item end
  end
  if not lowest then return {show=false,available=false,unit="player",progressType="static"} end
  return {show=true,available=true,unit="player",progressType="static",name=lowest.name,
    value=lowest.value,total=lowest.total,percent=lowest.value/lowest.total*100,slot=lowest.slot}
end
status.health = function(trigger)
  local state=resource(trigger, UnitHealth, UnitMaxHealth)
  if state.show and state.unit=="target" then targetHealthText(state) end
  return state
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
    return { show = false, available = false }
  end
  local main, sub = call(UnitClass, unit)
  main, sub = main or "", sub or ""
  local name = (sub ~= "" and sub ~= main) and (main .. " / " .. sub) or main
  local mainToken,subToken=call(UnitClassToken,unit)
  local normalize=RWA.ClassToken or function(value) return value end
  return {
    show = main ~= "",
    available = main ~= "",
    class1 = normalize(mainToken or main), class2 = normalize(subToken or sub),
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
  local state = { unit = unit, show = false, casting = 0 }
  if not unitExists(unit) then
    return state
  end
  local name, total, done = call(UnitCastingTime, unit)
  if name and total and total > 0 then
    state.show, state.casting = true, 1
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
    state.available = false
    return state
  end
  local total, remaining = call(GetSkillCooldown, page, slot)
  remaining = tonumber(remaining)
  if not remaining then state.available = false; return state end
  local _, icon = call(GetSkillDetail, page, slot)
  state.icon = type(icon) == "string" and icon or nil
  local onCooldown = remaining > 0.05
  state.skillAvailable, state.cooldown, state.ready, state.remaining = true, onCooldown, not onCooldown, remaining
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

local function auraCount(trigger,now,filter)
  local unit=trigger.unit or "player"
  local available=unitExists(unit) and true or false
  -- The same unit/filter cache is shared with named-buff checks in this poll.
  -- Count aura entries, not stacks. An absent target is unavailable, not zero.
  return {show=available,available=available,unit=unit,progressType="static",
    value=available and #scan(unit,filter,now) or nil,total=100,
    name=filter=="HELPFUL" and "Buff count" or "Debuff count"}
end
status.buffcount=function(trigger,now) return auraCount(trigger,now,"HELPFUL") end
status.debuffcount=function(trigger,now) return auraCount(trigger,now,"HARMFUL") end

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
RWA.On("UNIT_CLASS_CHANGED", function(_, unit)
  if unit == nil or unit == "player" then
    skillCache = {}
  end
end)
RWA.On("EXCHANGECLASS_SUCCESS", function()
  skillCache = {}
end)
