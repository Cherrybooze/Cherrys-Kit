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
-- [unit][filter] = list of the unit's auras. Every poll and UNIT_BUFF_CHANGED make the
-- lists stale; the next scan refills the same list and aura tables instead of new ones.
local cache, cacheRead, invalidation = {}, {}, 0
local durations = {} -- ["unitKey|filter|id|name"] = { duration, expires, seen }
local scanSerial = 0
local knownAuras = {}
local knownCount = 0
local savedStore, savedCount

-- Count a loaded saved table only once, then account for inserts and remove a
-- batch at the cap. No full-cache recount or sorted eviction on each new buff.
local function trimInfo(store, count, keep)
  for key in pairs(store) do
    if count <= keep then break end
    store[key], count = nil, count - 1
  end
  return count
end

local function buffStore()
  if type(RWA_DB) ~= "table" then return nil end
  if type(RWA_DB.buffInfo) ~= "table" then RWA_DB.buffInfo = {} end
  local store = RWA_DB.buffInfo
  if store ~= savedStore then
    savedStore, savedCount = store, 0
    for _ in pairs(store) do savedCount = savedCount + 1 end
    if savedCount > 4000 then savedCount = trimInfo(store, savedCount, 3000) end
  end
  return store
end

local function rememberAura(aura)
  if not aura.icon then
    return
  end
  local nameKey = "name:" .. string.lower(aura.name)
  local known = knownAuras[nameKey]
  if known and known.name == aura.name and known.icon == aura.icon and known.id == aura.id then
    -- seen before exactly like this: keep the remembered entry, make no new one
    local key = aura.id and tostring(aura.id)
    local store = key and buffStore()
    if not key or knownAuras[key] == known and (not store or store[key] == known) then return end
  end
  local info = { name = aura.name, icon = aura.icon, id = aura.id }
  -- Leave room for both the name and ID indices of the latest observation.
  if knownCount > 7998 then knownCount = trimInfo(knownAuras, knownCount, 6000) end
  if knownAuras[nameKey] == nil then knownCount = knownCount + 1 end
  knownAuras[nameKey] = info
  if aura.id then
    local key = tostring(aura.id)
    if knownAuras[key] == nil then knownCount = knownCount + 1 end
    knownAuras[key] = info
    local store = buffStore()
    if store then
      if store[key] == nil then
        if savedCount >= 4000 then savedCount = trimInfo(store, savedCount, 3000) end
        savedCount = savedCount + 1
      end
      store[key] = info
    end
  end
end

function T.InvalidateAuras()
  invalidation = invalidation + 1
end

local function scan(unit, filter, observedNow)
  local lists, reads = cache[unit], cacheRead[unit]
  if not lists then
    lists, reads = {}, {}
    cache[unit], cacheRead[unit] = lists, reads
  end
  local list = lists[filter]
  if list and reads[filter] == invalidation then
    return list
  end
  if not list then
    list = {}
    lists[filter] = list
  end
  reads[filter] = invalidation
  local count = 0
  local helpful = filter ~= "HARMFUL"
  local getAura = helpful and UnitBuff or UnitDebuff
  local getLeft = helpful and UnitBuffLeftTime or UnitDebuffLeftTime
  if not getAura or not unitExists(unit) then
    for i = #list, 1, -1 do list[i] = nil end
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
    count = count + 1
    local aura = list[count]
    if not aura then
      aura = {}
      list[count] = aura
    end
    aura.name, aura.icon, aura.stacks, aura.id, aura.index, aura.unit = name, icon, tonumber(stacks) or 0, id, i, unit
    aura.duration, aura.expirationTime = nil, nil
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
  end
  for i = #list, count + 1, -1 do list[i] = nil end
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

-- The engine polls every aura ten times a second. It hands each source its previous
-- observation back (into) to be emptied and refilled, so a running aura makes no new
-- table per poll. Every other caller passes nothing and gets a new table.
local function fresh(into)
  if into then
    for key in pairs(into) do into[key] = nil end
    return into
  end
  return {}
end
T.Fresh = fresh

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
-- The name and icon of an aura not seen this session, from its ID, name or the skill book.
local function lookUpAura(trigger, id, key)
  local info
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

function T.AuraInfo(trigger)
  local id = trigger.ids and trigger.ids[1]
  local key = id and tostring(id)
  local store = buffStore()
  local info = key and (knownAuras[key] or (store and store[key]))
  if info then
    return info
  end
  -- Not seen yet: the slower lookups below run once a second per trigger, not every poll.
  local r = rt(trigger)
  local now = RWA.Now()
  if r.auraInfo and now >= r.auraInfoAt and now - r.auraInfoAt < 1 then
    return r.auraInfo
  end
  r.auraInfo, r.auraInfoAt = lookUpAura(trigger, id, key), now
  return r.auraInfo
end

evaluators.aura = function(trigger, now, env, into)
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
  local state = fresh(into)
  state.unit, state.matchCount = unit, count
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
-- any legacy showOn, remaining or stacks filters are applied. recycle: the engine's
-- own poll, which may refill this source's previous observation (see fresh).
function T.Observe(source, now, env, recycle)
  local kind = source.type or "aura"
  local into
  if recycle and kind ~= "resource" then
    local r = rt(source)
    into = r.observed
    if not into then into = {}; r.observed = into end
  end
  if kind ~= "aura" then
    if not evaluators[kind] then return nil end
    local state = T.Evaluate(source, now, env, into)
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
  local state = fresh(into)
  state.available, state.unitAvailable, state.present, state.timed, state.unit = available, available, false, false, unit
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

local function resourceNumber(value)
  value=tonumber(value)
  if value and value==value and value>=0 and value<math.huge then return value end
end

local function resource(trigger, getValue, getMax, into)
  local unit = trigger.unit or "player"
  local state = fresh(into)
  state.unit, state.progressType = unit, "static"
  if not unitExists(unit) then
    state.show = false
    return state
  end
  local value,total=resourceNumber(call(getValue,unit)),resourceNumber(call(getMax,unit))
  state.valueKnown,state.totalKnown=value~=nil,total~=nil and total>0
  state.value,state.total=value or 0,total or 0
  state.name = call(UnitName, unit) or unit
  state.percent = state.total > 0 and (state.value / state.total * 100) or 0
  state.show = true
  if trigger.op and trigger.value then
    local current = trigger.percent and state.percent or state.value
    state.show = compare(current, trigger.op, trigger.value)
  end
  return state
end

-- Monsters and NPCs nobody owns expose only a whole percentage (their maximum reads
-- 100); players and owned pets expose HP. The HP number follows pbInfo: UnitChangeHealth
-- is the last HP change, and for a monster first seen at full health that change is its
-- whole HP (from 0 to full). So only full-health observations teach a maximum, and a
-- smaller one (a heal back to full) never lowers it. Maxima are kept for the session by
-- name, level and class like pbInfo's MobDB, which is read too when pbInfo is on.
local learnedMax,learnedCount={},0
local LEARNED_LIMIT=300
-- What the target is (player, pet, level, class) only changes with the target,
-- so it is read once per target instead of on every poll. UnitGUID plus the name
-- identify the target; a target change or one second clears the facts, so a
-- reused identity cannot keep stale ones. Without a GUID they are read each time.
local targetFacts={}
RWA.On("PLAYER_TARGET_CHANGED",function() targetFacts.at=nil end)
-- true or false, or nil when the game cannot tell. For anything but a player the game
-- answers nil, which therefore means "not a player" once the call itself worked.
local function unitIsPlayer(unit)
  local fn=rawget(_G,"UnitIsPlayer")
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,unit)
  if not ok then return nil end
  return value~=nil and value~=false and value~=0
end
local function readTargetFacts(name,now)
  local guid=call(rawget(_G,"UnitGUID"),"target")
  if type(guid)~="string" and type(guid)~="number" or guid==""
    or type(guid)=="number" and (not resourceNumber(guid) or guid==0) then guid=nil end
  local f=targetFacts
  now=tonumber(now) or RWA.Now()
  if guid and f.at and f.guid==guid and f.name==name and now>=f.at and now-f.at<1 then return f end
  f.guid,f.name,f.at,f.key=guid,name,guid and now or nil,nil
  f.isPlayer=unitIsPlayer("target")
  f.master=call(rawget(_G,"UnitMaster"),"target")
  f.level=call(rawget(_G,"UnitLevel"),"target")
  f.class=call(rawget(_G,"UnitClass"),"target")
  return f
end
local function learnedMaximum(facts,value)
  local key=facts.key
  if not key then
    key=tostring(facts.name).."\t"..tostring(facts.level).."\t"..tostring(facts.class)
    facts.key=key
  end
  local max=learnedMax[key]
  local mobdb=type(pbInfo)=="table" and pbInfo.MobDB
  if type(mobdb)=="table" then
    local byName=type(mobdb.Mobs)=="table" and mobdb.Mobs[facts.name]
    local byLevel=type(byName)=="table" and byName[facts.level]
    local byClass=type(byLevel)=="table" and byLevel[facts.class]
    local known=type(byClass)=="table" and resourceNumber(byClass.healthpoints)
    if known and known>=1 then max=math.max(max or 0,math.floor(known)) end
  end
  if value==100 then
    local changed=resourceNumber(call(rawget(_G,"UnitChangeHealth"),"target"))
    if changed and changed>=1 then
      changed=math.floor(changed)
      local before=learnedMax[key]
      if not before then
        if learnedCount>=LEARNED_LIMIT then learnedMax,learnedCount={},0 end
        learnedCount=learnedCount+1
      end
      if not before or changed>before then learnedMax[key]=changed end
      max=math.max(max or 0,changed)
    end
  end
  return max
end
-- The texts are only rebuilt when a number changes, never on every poll.
local function groupDigits(n) -- 1234567 -> "1,234,567", as the game groups gold
  local digits=string.format("%.0f",n)
  local head=string.len(digits)%3
  if head==0 then head=3 end
  local text=string.sub(digits,1,head)
  for i=head+1,string.len(digits),3 do text=text..","..string.sub(digits,i,i+2) end
  return text
end
local percentTexts={}
local hpShown,hpText,maxShown,maxText,lineHp,lineMax,linePercent,lineText
-- The game rounds a monster's percentage down but never to 0 while it lives.
local function wholePercent(value,total)
  if value<=0 then return 0 end
  return math.max(1,math.min(100,math.floor(value*100/total)))
end
local function targetHealthText(state,now)
  if state.value==nil then targetFacts.at=nil;return end
  local percent="?%"
  if state.valueKnown and state.totalKnown then
    local whole=wholePercent(state.value,state.total)
    percent=percentTexts[whole]
    if not percent then percent=whole.."%";percentTexts[whole]=percent end
  end
  local facts=readTargetFacts(state.name,now)
  local isPlayer,master=facts.isPlayer,facts.master
  local current,max
  if isPlayer==true or type(master)=="string" and master~="" or state.totalKnown and state.total~=100 then
    current=state.valueKnown and state.value or nil
    max=state.totalKnown and state.total or nil
  elseif isPlayer==false and state.valueKnown and state.totalKnown and state.value<=100 then
    -- an unknown kind of unit must not turn an ambiguous 100 into HP
    max=learnedMaximum(facts,state.value)
    current=max and math.ceil(max*state.value/100)
  end
  if current and current~=hpShown then hpShown,hpText=current,groupDigits(current) end
  if max and max~=maxShown then maxShown,maxText=max,groupDigits(max) end
  local hp,top=current and hpText or "?",max and maxText or "?"
  if hp~=lineHp or top~=lineMax or percent~=linePercent then
    lineHp,lineMax,linePercent=hp,top,percent
    lineText=hp.." / "..top.." ("..percent..")"
  end
  state.healthNumber,state.healthPercent,state.healthText=hp,percent,lineText
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
status.durability = function(trigger,now,into)
  local minimum=tonumber(trigger.minimumMax) or 101
  local lowest
  for _,item in ipairs(equippedDurability(now)) do
    if item.total>=minimum and (not lowest or item.value<lowest.value) then lowest=item end
  end
  local state=fresh(into)
  state.unit,state.progressType="player","static"
  if not lowest then state.show,state.available=false,false;return state end
  state.show,state.available,state.name,state.slot=true,true,lowest.name,lowest.slot
  state.value,state.total,state.percent=lowest.value,lowest.total,lowest.value/lowest.total*100
  return state
end
status.health = function(trigger, now, into)
  local state=resource(trigger, UnitHealth, UnitMaxHealth, into)
  if state.unit=="target" then targetHealthText(state, now) end
  return state
end
status.mana = function(trigger, now, into)
  return resource(trigger, UnitMana, UnitMaxMana, into)
end
-- RoM's second resource bar (rage, energy, focus) is "skill" in the API.
status.skill = function(trigger, now, into)
  return resource(trigger, UnitSkill, UnitMaxSkill, into)
end
-- When the current fight started, for %e (time in combat); nil out of combat.
local combatSince
status.combat = function(trigger, now, into)
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
  local state = fresh(into)
  state.show, state.name, state.startTime = show, show and "In combat" or "Out of combat", combatSince
  state.progressType, state.value, state.total = "static", 1, 1
  return state
end
-- Class: always shows, with the unit's primary/secondary class as name and its class-combo
-- icon (RWA.ClassIcon, see ClassIcons.lua). Polled, so it follows a class change at once.
local function sameToken(value) return value end
status.class = function(trigger, now, into)
  local unit = trigger.unit or "player"
  local state = fresh(into)
  if not unitExists(unit) then
    state.show, state.available = false, false
    return state
  end
  local main, sub = call(UnitClass, unit)
  main, sub = main or "", sub or ""
  local name = (sub ~= "" and sub ~= main) and (main .. " / " .. sub) or main
  local mainToken,subToken=call(UnitClassToken,unit)
  local normalize=RWA.ClassToken or sameToken
  state.show, state.available = main ~= "", main ~= ""
  state.class1, state.class2 = normalize(mainToken or main), normalize(subToken or sub)
  state.unit, state.name = unit, name
  state.icon = RWA.ClassIcon and RWA.ClassIcon(main, sub) or nil
  state.progressType, state.value, state.total = "static", 1, 1
  return state
end
status.target = function(trigger, now, into)
  local unit = trigger.unit or "target"
  local exists = unitExists(unit)
  local state = fresh(into)
  state.unit, state.progressType, state.value, state.total = unit, "static", 1, 1
  state.name = exists and call(UnitName, unit) or ""
  state.show = exists
  if exists and trigger.enemy ~= nil then
    local hostile = call(UnitCanAttack, "player", unit)
    state.show = (hostile and true or false) == trigger.enemy
  end
  return state
end
-- UnitCastingTime(unit) -> spell name, total cast time, time already cast.
status.cast = function(trigger, now, into)
  local unit = trigger.unit or "player"
  local state = fresh(into)
  state.unit, state.show, state.casting = unit, false, 0
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
status.cooldown = function(trigger, now, into)
  local state = fresh(into)
  state.name, state.show = trigger.skill or "?", false
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

local function auraCount(trigger,now,filter,into)
  local unit=trigger.unit or "player"
  local available=unitExists(unit) and true or false
  -- The same unit/filter cache is shared with named-buff checks in this poll.
  -- Count aura entries, not stacks. An absent target is unavailable, not zero.
  local state=fresh(into)
  state.show,state.available,state.unit,state.progressType=available,available,unit,"static"
  state.value,state.total=available and #scan(unit,filter,now) or nil,100
  state.name=filter=="HELPFUL" and "Buff count" or "Debuff count"
  return state
end
status.buffcount=function(trigger,now,into) return auraCount(trigger,now,"HELPFUL",into) end
status.debuffcount=function(trigger,now,into) return auraCount(trigger,now,"HARMFUL",into) end

evaluators.status = function(trigger, now, env, into)
  local fn = status[trigger.check or "health"]
  if not fn then
    local state = fresh(into)
    state.show = false
    return state
  end
  return fn(trigger, now, into)
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

evaluators.custom = function(trigger, now, auraEnv, into)
  local r = rt(trigger)
  if r.fn == nil then
    local fn, err = T.CompileCustom(trigger.code, auraEnv)
    r.fn = fn or false
    if err then
      RWA.Error("custom trigger: " .. tostring(err))
    end
  end
  local state = fresh(into)
  if not r.fn then
    state.show = false
    return state
  end
  local ok, show, extra = pcall(r.fn, auraEnv)
  if not ok then
    RWA.Error("custom trigger: " .. tostring(show))
    state.show = false
    return state
  end
  state.show, state.progressType, state.value, state.total = show and true or false, "static", 1, 1
  if type(extra) == "table" then
    for k, v in pairs(extra) do
      state[k] = v
    end
  end
  return state
end

function T.Evaluate(trigger, now, auraEnv, into)
  local fn = evaluators[trigger.type or "aura"]
  if not fn then
    local state = fresh(into)
    state.show = false
    return state
  end
  return fn(trigger, now, auraEnv, into)
end

-- Drop compiled code and lookup sets after the editor changes a trigger.
function T.Reset(trigger)
  runtime[trigger] = nil
end

function T.Tick(now)
  T.InvalidateAuras()
  buffStore() -- also bound an oversized pre-existing save with no new sightings
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
