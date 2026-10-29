-- Ordered checks and action-owned outputs for rom weakauras.
-- Source and rule IDs are persistent; array positions are only display order.
local RWA = RWA
local Rules = { MAX_RULES = 10 }
RWA.Rules = Rules

local function nextId(data, items, prefix, counterKey)
  local used = {}
  for _, item in ipairs(items or {}) do
    if type(item) == "table" and type(item.id) == "string" then used[item.id] = true end
  end
  local n = math.max(1, tonumber(data[counterKey]) or 1)
  while used[prefix .. n] do n = n + 1 end
  data[counterKey] = n + 1
  return prefix .. n
end

function Rules.FindSource(data, id)
  for _, source in ipairs(data.sources or {}) do
    if source.id == id then return source end
  end
end

function Rules.FindRule(data, id)
  for _, rule in ipairs(data.rules or {}) do
    if rule.id == id then return rule end
  end
end

function Rules.AddSource(data, definition)
  data.sources = data.sources or {}
  local source = RWA.CopyTable(definition or { type = "aura", unit = "player", filter = "HELPFUL", names = {}, ids = {} })
  source.id = nextId(data, data.sources, "s", "nextSourceId")
  table.insert(data.sources, source)
  return source.id
end

function Rules.Add(data, template)
  data.rules = data.rules or {}
  if #data.rules >= Rules.MAX_RULES then return nil, "An aura can have up to ten behaviors, including conditional branches." end
  local rule = template and RWA.CopyTable(template) or { enabled = true, name = "", when = { mode = "all", checks = {} } }
  if not template then
    if data.schemaVersion == 3 then rule.actions = {} else rule.set = {} end
  end
  rule.id = nextId(data, data.rules, "r", "nextRuleId")
  table.insert(data.rules, rule)
  return rule
end

-- Checks also have stable IDs, for pending input and recycled controls. Older
-- RWA3 drafts without IDs get them when first edited, not during evaluation.
function Rules.EnsureCheckIds(data)
  local reserved, seen = {}, {}
  for _, rule in ipairs(data.rules or {}) do
    for _, check in ipairs(type(rule.when) == "table" and rule.when.checks or {}) do
      if type(check) == "table" and type(check.id) == "string" then reserved[check.id] = true end
    end
  end
  for _, rule in ipairs(data.rules or {}) do
    for _, check in ipairs(type(rule.when) == "table" and rule.when.checks or {}) do
      if type(check) == "table" then
        if type(check.id) ~= "string" or seen[check.id] then
          local n = math.max(1, tonumber(data.nextCheckId) or 1)
          while reserved["c" .. n] do n = n + 1 end
          check.id, data.nextCheckId = "c" .. n, n + 1
          reserved[check.id] = true
        end
        seen[check.id] = true
      end
    end
  end
end

function Rules.AddCheck(data, rule, template)
  if type(rule) ~= "table" then return nil end
  rule.when = type(rule.when) == "table" and rule.when or { mode = "all", checks = {} }
  rule.when.checks = type(rule.when.checks) == "table" and rule.when.checks or {}
  local check = RWA.CopyTable(template or { sourceId = data.primarySourceId, field = "present" })
  check.id = nil
  table.insert(rule.when.checks, check)
  Rules.EnsureCheckIds(data)
  return check
end

function Rules.FindCheck(rule, checkId)
  for _, check in ipairs(type(rule) == "table" and type(rule.when) == "table" and rule.when.checks or {}) do
    if check.id == checkId then return check end
  end
end

local function actionItems(data, outputs)
  local items = {}
  for _, rule in ipairs(data.rules or {}) do
    for _, action in ipairs(rule.actions or {}) do
      local item = outputs and action.output or action
      if type(item) == "table" then items[#items + 1] = item end
    end
  end
  return items
end

function Rules.AddAction(data, rule, template)
  if type(rule) ~= "table" then return nil end
  rule.actions = rule.actions or {}
  local action = RWA.CopyTable(template or {})
  action.id = nextId(data, actionItems(data), "a", "nextActionId")
  if type(action.output) == "table" then
    action.output.id = nextId(data, actionItems(data, true), "o", "nextOutputId")
  end
  rule.actions[#rule.actions + 1] = action
  return action
end

function Rules.FindAction(rule, actionId)
  for _, action in ipairs(type(rule) == "table" and rule.actions or {}) do
    if action.id == actionId then return action end
  end
end

-- Changing a type clears dependent choices, but the action identity survives.
function Rules.ChangeActionType(data, action, kind)
  if type(action) ~= "table" then return false end
  if action.type == kind then return true end
  local id = action.id
  local oldOutput = type(action.output) == "table" and action.output.id
  local oldNumber = type(oldOutput) == "string" and tonumber(string.match(oldOutput, "^o(%d+)$"))
  if oldNumber then data.nextOutputId = math.max(tonumber(data.nextOutputId) or 1, oldNumber + 1) end
  for key in pairs(action) do action[key] = nil end
  action.id, action.type = id, kind
  if kind == "show" then
    action.output = { id = nextId(data, actionItems(data, true), "o", "nextOutputId") }
  end
  Rules.PruneSources(data)
  return true
end

function Rules.RemoveAction(data, rule, actionId)
  for index, action in ipairs(type(rule) == "table" and rule.actions or {}) do
    if action.id == actionId then
      local actionNumber = type(action.id) == "string" and tonumber(string.match(action.id, "^a(%d+)$"))
      local outputId = type(action.output) == "table" and action.output.id
      local outputNumber = type(outputId) == "string" and tonumber(string.match(outputId, "^o(%d+)$"))
      if actionNumber then data.nextActionId = math.max(tonumber(data.nextActionId) or 1, actionNumber + 1) end
      if outputNumber then data.nextOutputId = math.max(tonumber(data.nextOutputId) or 1, outputNumber + 1) end
      table.remove(rule.actions, index)
      Rules.PruneSources(data)
      return true
    end
  end
  return false
end

function Rules.SetAction(rule, key, value)
  if type(rule) ~= "table" then return false end
  rule.set = type(rule.set) == "table" and rule.set or {}
  rule.set[key] = value -- nil removes exactly this property; false is a real value.
  return true
end

local function referencesRule(rule, id)
  for _, check in ipairs(type(rule.when) == "table" and rule.when.checks or {}) do
    if check.field == "rule" and check.ruleId == id then return true end
  end
  return false
end

function Rules.Move(data, ruleId, direction)
  for i, rule in ipairs(data.rules or {}) do
    if rule.id == ruleId then
      local j = i + direction
      if (direction ~= -1 and direction ~= 1) or j < 1 or j > #data.rules then return false end
      local neighbor = data.rules[j]
      if (direction < 0 and referencesRule(rule, neighbor.id))
        or (direction > 0 and referencesRule(neighbor, rule.id)) then
        return false, "A rule must remain after the rule it references."
      end
      data.rules[i], data.rules[j] = neighbor, rule
      return true
    end
  end
  return false
end

function Rules.Remove(data, ruleId)
  for i, rule in ipairs(data.rules or {}) do
    if rule.id == ruleId then
      local number = type(rule.id) == "string" and tonumber(string.match(rule.id, "^r(%d+)$"))
      if number then data.nextRuleId = math.max(tonumber(data.nextRuleId) or 1, number + 1) end
      -- Keep identities retired even for imported definitions without counters.
      for _, check in ipairs(rule.when and rule.when.checks or {}) do
        local n = type(check.id) == "string" and tonumber(string.match(check.id, "^c(%d+)$"))
        if n then data.nextCheckId = math.max(tonumber(data.nextCheckId) or 1, n + 1) end
      end
      for _, action in ipairs(rule.actions or {}) do
        local n = type(action.id) == "string" and tonumber(string.match(action.id, "^a(%d+)$"))
        if n then data.nextActionId = math.max(tonumber(data.nextActionId) or 1, n + 1) end
        local outputId = type(action.output) == "table" and action.output.id
        n = type(outputId) == "string" and tonumber(string.match(outputId, "^o(%d+)$"))
        if n then data.nextOutputId = math.max(tonumber(data.nextOutputId) or 1, n + 1) end
      end
      table.remove(data.rules, i)
      Rules.PruneSources(data)
      return true
    end
  end
  return false
end

function Rules.Duplicate(data, ruleId)
  local rule = Rules.FindRule(data, ruleId)
  if not rule then return nil, "Rule no longer exists." end
  local copy, reason = Rules.Add(data, rule)
  if copy then
    for _, check in ipairs(copy.when and copy.when.checks or {}) do check.id = nil end
    Rules.EnsureCheckIds(data)
    if copy.actions then
      local actions, remap = copy.actions, {}
      copy.actions = {}
      for _, action in ipairs(actions) do
        local oldOutput = type(action.output) == "table" and action.output.id
        local duplicate = Rules.AddAction(data, copy, action)
        if oldOutput and duplicate.output then remap[oldOutput] = duplicate.output.id end
      end
      for _, action in ipairs(copy.actions) do
        if remap[action.targetId] then action.targetId = remap[action.targetId] end
        if type(action.output) == "table" and remap[action.output.parentOutputId] then
          action.output.parentOutputId = remap[action.output.parentOutputId]
        end
      end
    end
  end
  return copy, reason
end

local function actionSourceId(data, rule, action)
  local id = action.sourceId
  if id == nil then
    for _, check in ipairs(rule.when and rule.when.checks or {}) do
      if check.sourceId then id = check.sourceId; break end
    end
  end
  return id ~= false and (id or data.primarySourceId) or nil
end

-- Collect references once per load/edit, including converted sourceChoices and
-- nested display metadata. The recovery archive is data only. A compatibility
-- primary is not itself a reason to poll an otherwise unused source.
function Rules.UsedSources(data)
  local used, seen = {}, {}
  local function references(value)
    if type(value) ~= "table" or seen[value] then return end
    seen[value] = true
    for key, child in pairs(value) do
      if key == "sourceId" and type(child) == "string" then used[child] = true
      elseif key ~= "previousDefinition" then references(child) end
    end
  end
  for key, value in pairs(data) do
    if key ~= "previousDefinition" then references(value) end
  end
  if data.schemaVersion ~= 3 and data.primarySourceId then used[data.primarySourceId] = true end
  for _, rule in ipairs(data.rules or {}) do
    for _, action in ipairs(rule.actions or {}) do
      if action.type == "show" then
        local id = actionSourceId(data, rule, action)
        if id then used[id] = true end
      end
    end
  end
  return used
end

function Rules.PruneSource(data, id, used)
  -- Keep the primary definition/ID for GetAuraValue and legacy editors, even
  -- when normal polling no longer needs it. Observation is demand-driven.
  if not id or data.primarySourceId == id or (used or Rules.UsedSources(data))[id] then return end
  for i, source in ipairs(data.sources or {}) do
    if source.id == id then
      local number = type(id) == "string" and tonumber(string.match(id, "^s(%d+)$"))
      if number then data.nextSourceId = math.max(tonumber(data.nextSourceId) or 1, number + 1) end
      table.remove(data.sources, i)
      return
    end
  end
end

function Rules.PruneSources(data)
  local used = Rules.UsedSources(data)
  for i = #(data.sources or {}), 1, -1 do Rules.PruneSource(data, data.sources[i].id, used) end
end

-- Always make a new source when an editor changes a check's source. Other
-- checks and displays that refer to the old definition remain unchanged.
function Rules.RebindCheck(data, check, definition)
  if type(check) ~= "table" then return nil end
  local old = check.sourceId
  check.sourceId = Rules.AddSource(data, definition)
  Rules.PruneSource(data, old)
  return check.sourceId
end

-- Conversion is explicit and reversible. The archive is one data-only copy,
-- not an active second rule engine, and never nests older archives.
function Rules.StartFresh(data)
  if type(data) ~= "table" or data.schemaVersion == 2 then return false end
  if data.schemaVersion ~= 2 then
    local previous = RWA.CopyTable(data)
    previous.previousDefinition = nil
    data.previousDefinition = previous
  end
  data.schemaVersion, data.defaultVisible, data.rules, data.sources = 2, false, {}, {}
  data.nextSourceId, data.nextRuleId, data.nextCheckId = 1, 1, 1
  local triggerIds = {}
  for i, trigger in ipairs(data.triggers or {}) do
    triggerIds[i] = Rules.AddSource(data, trigger)
  end
  data.primarySourceId = triggerIds[1] or Rules.AddSource(data)
  for _, element in ipairs(data.elements or {}) do
    local from = tonumber(element.from) or 0
    element.sourceId = from > 0 and (triggerIds[from] or ("missing-legacy-"..from)) or nil
    element.from = nil
  end
  -- triggers and conditions are retained only inside previousDefinition.
  data.triggers, data.conditions = nil, nil
  return true
end

function Rules.RestorePrevious(data)
  if type(data) ~= "table" or type(data.previousDefinition) ~= "table" then return nil end
  local restored = RWA.CopyTable(data.previousDefinition)
  restored.id = data.id
  restored.previousDefinition = nil
  return restored
end

function Rules.Initialize(data)
  data.schemaVersion, data.defaultVisible, data.sources, data.rules = 2, false, {}, {}
  data.nextSourceId, data.nextRuleId, data.nextCheckId = 1, 1, 1
  data.primarySourceId = Rules.AddSource(data)
  local rule = Rules.Add(data)
  rule.name, rule.set = "Show when present", { visible = true }
  Rules.AddCheck(data, rule, { sourceId = data.primarySourceId, field = "present" })
  return data
end

-- A useful explicit starter: X is real and Y deliberately remains unconfigured.
function Rules.MakeExample(data)
  if type(data) ~= "table" or data.schemaVersion ~= 2 then return false end
  data.defaultVisible, data.color = false, { 1, 1, 1, 1 }
  local x = Rules.AddSource(data, { type = "aura", unit = "player", filter = "HELPFUL", ids = {500934}, names = {} })
  local y = Rules.AddSource(data, { type = "aura", unit = "player", filter = "HELPFUL", ids = {}, names = {} })
  data.primarySourceId, data.rules = x, {}
  local r = Rules.Add(data); r.name = "Missing buff"; r.set = { visible = true }
  Rules.AddCheck(data, r, { sourceId = x, field = "missing" })
  r = Rules.Add(data); r.name = "About to expire"; r.set = { visible = true, color = {0.9, 0.15, 0.15, 1}, grow = 1.25 }
  Rules.AddCheck(data, r, { sourceId = x, field = "present" })
  Rules.AddCheck(data, r, { sourceId = x, field = "remaining", op = "<", value = 3 })
  r = Rules.Add(data); r.name = "Another buff is active"; r.set = { visible = true, color = {0.9, 0.15, 0.15, 1}, grow = 1.25 }
  Rules.AddCheck(data, r, { sourceId = x, field = "present" })
  Rules.AddCheck(data, r, { sourceId = y, field = "present" })
  for i=#data.sources,1,-1 do Rules.PruneSource(data,data.sources[i].id) end
  return true
end

-- Scenario observations are detached from live source tables. They never call
-- the game APIs and never alter live sound-edge history.
function Rules.Scenario(data, live, mode, now)
  if mode == "live" then return live end
  local snapshot = RWA.CopyTable(live or {})
  local primary = Rules.FindSource(data, data.primarySourceId)
  if not primary or (primary.type or "aura") ~= "aura" or not ((primary.names and #primary.names>0) or (primary.ids and #primary.ids>0)) then return snapshot end
  -- Sample concrete buff facts, then derive every source observation from the
  -- same facts. Names and IDs can both refer to the same buff.
  local function unitOf(candidate) return candidate.unit or "player" end
  local function filterOf(candidate) return candidate.filter == "HARMFUL" and "HARMFUL" or "HELPFUL" end
  local function resolvedName(id)
    if type(TEXT) ~= "function" then return nil end
    local ok, name = pcall(TEXT, "Sys" .. tostring(id) .. "_name")
    if ok and type(name) == "string" and name ~= "" and not string.find(name, "^Sys%d+_name$") then return name end
  end
  local function matches(candidate, fact)
    if unitOf(candidate) ~= fact.unit or filterOf(candidate) ~= fact.filter then return false end
    for _, id in ipairs(candidate.ids or {}) do if fact.id and tostring(id) == tostring(fact.id) then return true end end
    for _, name in ipairs(candidate.names or {}) do
      if fact.name and string.lower(tostring(name)) == string.lower(fact.name) then return true end
    end
    return false
  end
  local function namedId(candidate, name)
    for _, other in ipairs(data.sources or {}) do
      if (other.type or "aura") == "aura" and unitOf(other) == unitOf(candidate) and filterOf(other) == filterOf(candidate) then
        for _, id in ipairs(other.ids or {}) do
          local known = resolvedName(id)
          if known and string.lower(known) == string.lower(name) then return id end
        end
      end
    end
  end
  local function factsFor(candidate)
    local result = {}
    for _, id in ipairs(candidate.ids or {}) do
      result[#result + 1] = { id=id, name=resolvedName(id), unit=unitOf(candidate), filter=filterOf(candidate) }
    end
    for _, name in ipairs(candidate.names or {}) do
      local textName = tostring(name)
      result[#result + 1] = { id=namedId(candidate, textName), name=textName, unit=unitOf(candidate), filter=filterOf(candidate) }
    end
    return result
  end
  local facts = {}
  if mode ~= "missing" then
    local candidates = factsFor(primary)
    if candidates[1] then facts[#facts + 1] = candidates[1] end
  end
  if mode == "secondary" then
    local chosen = false
    for _, candidate in ipairs(data.sources or {}) do
      if candidate.id ~= data.primarySourceId and (candidate.type or "aura") == "aura" then
        for _, fact in ipairs(factsFor(candidate)) do
          local first = facts[1]
          local same = first and fact.unit == first.unit and fact.filter == first.filter
            and ((fact.id and first.id and tostring(fact.id) == tostring(first.id))
              or (not fact.id and not first.id and fact.name and first.name and string.lower(fact.name) == string.lower(first.name)))
          if not same then facts[#facts + 1] = fact; chosen = true; break end
        end
        if chosen then break end
      end
    end
  end
  for _, candidate in ipairs(data.sources or {}) do
    if (candidate.type or "aura") == "aura" and ((candidate.names and #candidate.names > 0) or (candidate.ids and #candidate.ids > 0)) then
      local fact
      for _, item in ipairs(facts) do if matches(candidate, item) then fact = item; break end end
      local present = fact ~= nil
      local source = RWA.CopyTable(snapshot[candidate.id] or {})
      source.available, source.unit = true, unitOf(candidate)
      source.present, source.active, source.show, source.timed = present, present, present, present
      source.name = (fact and fact.name) or source.name or "Sample buff"
      source.buffId, source.auraId = fact and fact.id or nil, fact and fact.id or nil
      if present then
        local remaining = mode == "expiring" and 2.5 or 10
        source.progressType, source.duration = "timed", 10
        source.remaining, source.expirationTime, source.stacks = remaining, now + remaining, 1
      else
        source.progressType, source.value, source.total = "static", 0, 1
        source.remaining, source.expirationTime, source.duration, source.stacks = nil, nil, nil, 0
      end
      snapshot[candidate.id] = source
    end
  end
  return snapshot
end

local function complete(source,data)
  if type(source) ~= "table" then return false end
  local kind = source.type or "aura"
  if kind=="resource" then return RWA.Resources and RWA.Resources.IsKind(source.resource) or false end
  if kind == "aura" then
    if data and data.schemaVersion == 3 and (type(source.unit) ~= "string" or source.unit == ""
      or (source.filter ~= "HELPFUL" and source.filter ~= "HARMFUL")) then return false end
    return (type(source.names) == "table" and #source.names > 0) or (type(source.ids) == "table" and #source.ids > 0)
  end
  if kind == "custom" then return type(source.code)=="string" and RWA.Trim(source.code)~="" end
  if kind=="kitty" and source.hotbarSlot~=nil then
    local slot=tonumber(source.hotbarSlot)
    if not slot or slot~=math.floor(slot) or slot<1 or slot>80 then return false end
  end
  if kind == "status" and data and data.schemaVersion == 3 then
    if type(source.check) ~= "string" or source.check == "" then return false end
    if source.check ~= "combat" and source.check ~= "cooldown"
      and (type(source.unit) ~= "string" or source.unit == "") then return false end
  end
  if kind == "status" and source.check == "cooldown" then return type(source.skill)=="string" and RWA.Trim(source.skill)~="" end
  if data and data.schemaVersion == 3 then
    if kind == "recent" and (type(source.measure) ~= "string" or type(source.showOn) ~= "string") then return false end
    if kind == "lastcast" and (type(source.unit) ~= "string" or source.unit == "" or type(source.showOn) ~= "string") then return false end
    if kind == "threat" and type(source.showOn) ~= "string" then return false end
  end
  if kind == "recent" and source.measure == "event" then return type(source.event)=="string" and RWA.Trim(source.event)~="" end
  return true
end

-- Each source is read once per evaluation, at the same supplied time.
function Rules.Observe(data, now, env, used)
  local snapshot = {}
  used = used or Rules.UsedSources(data)
  for _, source in ipairs(data.sources or {}) do
    if type(source.id) == "string" and used[source.id] and complete(source,data) then
      local ok, state = pcall(RWA.Triggers.Observe, source, now, env)
      if ok and type(state) == "table" then snapshot[source.id] = state end
    end
  end
  return snapshot
end

local numericFields = { remaining = true, stacks = true, percent = true, value = true, duration = true, total = true, perSecond = true, casting = true, hotbarSlot = true }
local operators = { ["<"] = true, ["<="] = true, [">"] = true, [">="] = true, ["=="] = true, ["="] = true, ["~="] = true, ["!="] = true }
-- A configured source remains valid when its unit or observation is unavailable.
-- This keeps an unavailable alternative false without invalidating an ANY group.
local function validCheck(check, snapshot, data, prior)
  if type(check) ~= "table" then return false end
  if check.field == "always" then return true end
  if check.field == "rule" then
    return prior ~= nil and type(check.ruleId) == "string" and type(check.value) == "boolean"
      and prior.valid[check.ruleId] == true
  end
  local obs = snapshot[check.sourceId]
  if data then
    if type(check.sourceId) ~= "string" or not complete(Rules.FindSource(data, check.sourceId),data) then return false end
  elseif type(obs) ~= "table" then
    return false
  end
  if check.field=="class" then
    local names=RWA.ClassNames or {}
    return names[check.class1]~=nil and names[check.class2]~=nil
  end
  if check.field=="hotbarSlot" then
    local slot=tonumber(check.value)
    if not slot or slot~=math.floor(slot) or slot<1 or slot>80 then return false end
    if data then
      local source=Rules.FindSource(data,check.sourceId)
      if not source or source.type~="kitty" or source.hotbarSlot==nil then return false end
    end
  end
  if check.field == "present" or check.field == "missing" or check.field == "active" or check.field == "unitAvailable"
    or check.field == "ready" or check.field == "cooldown" or check.field == "skillAvailable" then
    if data or (type(obs) == "table" and obs.available == false) then return true end
    if check.field == "active" then return obs.active ~= nil end
    if check.field == "unitAvailable" then return obs.unitAvailable ~= nil end
    return obs.present ~= nil
  end
  if not (numericFields[check.field] and operators[check.op] and tonumber(check.value) ~= nil) then return false end
  if data or (type(obs) == "table" and obs.available == false) then return true end
  if check.field == "remaining" then return obs.present ~= nil and obs.timed ~= nil end
  return tonumber(obs[check.field]) ~= nil
end

local function match(check, snapshot, prior)
  if check.field == "always" then return true end
  if check.field == "rule" then return prior.matches[check.ruleId] == check.value end
  local obs = snapshot[check.sourceId]
  if type(obs) ~= "table" or obs.available == false then return false end
  if check.field=="class" then
    return obs.unitAvailable==true and obs.class1~=nil and obs.class1~=""
      and (check.class1=="any" or check.class1==obs.class1)
      and (check.class2=="any" or check.class2==obs.class2)
  end
  if check.field == "present" then return obs.available == true and obs.present == true end
  if check.field == "missing" then return obs.available == true and obs.present == false end
  if check.field == "active" then return obs.active == true end
  if check.field == "unitAvailable" then return obs.unitAvailable == true end
  if check.field == "ready" or check.field == "cooldown" or check.field == "skillAvailable" then
    return obs[check.field] == true
  end
  local value = obs[check.field]
  -- Timed non-buff providers can have a valid countdown while their own
  -- active gate is false (for example a cooldown shown only when ready).
  if check.field == "remaining" and not (obs.available and (obs.timed or obs.skillAvailable)) then return false end
  return RWA.Triggers.Compare(value, check.op, check.value)
end

local function matchRule(rule, snapshot, data, prior)
  if type(rule) ~= "table" or type(rule.when) ~= "table" then return false, false end
  local checks = rule.when.checks
  if type(checks) ~= "table" or #checks == 0 then return false, false end
  local mode = rule.when.mode
  if mode ~= "all" and mode ~= "any" then return false, false end
  for _, check in ipairs(checks) do
    if not validCheck(check, snapshot, data, prior) then return false, false end
  end
  if rule.enabled == false then return false, true end
  local any = false
  for _, check in ipairs(checks) do
    local ok = match(check, snapshot, prior)
    if mode == "all" and not ok then return false, true end
    if ok then any = true end
  end
  return any, true
end

function Rules.Match(rule, snapshot)
  local matched = matchRule(rule, snapshot)
  return matched
end

-- New action-model auras start incomplete; an unset selector is not Always,
-- false, zero or a silently chosen source.
function Rules.InitializeActions(data)
  data.schemaVersion, data.sources, data.rules = 3, {}, {}
  data.nextSourceId, data.nextRuleId, data.nextCheckId = 1, 1, 1
  data.nextActionId, data.nextOutputId = 1, 1
  data.primarySourceId, data.defaultVisible, data.triggers, data.conditions = nil, nil, nil, nil
  data.elements, data.sound = nil, nil
  local rule = Rules.Add(data)
  rule.set, rule.actions = nil, {}
  Rules.AddCheck(data, rule, {})
  return data
end

-- The requested example is intentionally two rules: health modifies the icon,
-- it never gates the missing-buff check that creates it.
function Rules.MakeFlowExample(data)
  Rules.InitializeActions(data)
  local buff = Rules.AddSource(data,{type="aura",unit="player",filter="HELPFUL",ids={500934},names={}})
  local health = Rules.AddSource(data,{type="status",unit="player",check="health"})
  data.primarySourceId = buff
  local first = data.rules[1]
  first.name = "Missing buff"
  first.when.checks[1].sourceId, first.when.checks[1].field = buff, "missing"
  local show = Rules.AddAction(data,first,{type="show",sourceId=buff,
    output={regionType="icon",width=48,height=48,color={1,1,1,1},text="MISSING",text2=""}})
  Rules.AddAction(data,first,{type="sound",clip="AirHorn",mode="once"})
  local second = Rules.Add(data)
  second.name, second.set, second.actions = "Low-health colour", nil, {}
  Rules.AddCheck(data,second,{field="rule",ruleId=first.id,value=true})
  Rules.AddCheck(data,second,{sourceId=health,field="percent",op="<",value=20})
  Rules.AddAction(data,second,{type="color",targetId=show.output.id,value={1,0,0,1}})
  return data
end

-- Convert the common one-show-rule layout into independently owned outputs.
-- Other legacy layouts remain in the recovery copy and are handled separately.
local function splitSimpleElements(data, visual, visibleRule, parentOutputId)
  if type(visual.elements) ~= "table" or #visual.elements == 0 then return true end
  if not RWA.Regions or not RWA.Regions.ElementData then
    return false,"This extra display arrangement needs conversion."
  end
  for _, element in ipairs(visual.elements) do
    local sourceId = element.sourceId or data.primarySourceId
    local source = Rules.FindSource(data, sourceId)
    if not source then return false,"This extra display has a source that needs conversion." end
    if source.type == "kitty" and not (RWA.KittyTracker and RWA.KittyTracker.PickNumber) then
      return false,"This Kitty display needs its provider to convert."
    end
  end
  local elements = visual.elements
  for index, element in ipairs(elements) do
    local sourceId = element.sourceId or data.primarySourceId
    local source = Rules.FindSource(data, sourceId)
    local child = RWA.Regions.ElementData(visual, element)
    if source.type=="kitty" and (child.regionType=="icon" or child.regionType=="aurabar")
      and not (element.icon and element.icon~="") then
      child.kittyPick=RWA.KittyTracker.PickNumber({data=visual},index)
    end
    child.sourceId,child.gateRuleId,child.from,child.side,child.type,child.x,child.y,child.followMain=nil,nil,nil,nil,nil,nil,nil,nil
    local pw, ph = tonumber(visual.width) or 48, tonumber(visual.height) or 48
    local cw, ch = tonumber(child.width) or 48, tonumber(child.height) or 48
    local side, point = element.side or "LEFT", data.point or "CENTER"
    local x, y = tonumber(element.x) or 0, tonumber(element.y) or 0
    if side == "LEFT" then x = x - (pw + cw) / 2 - 2
    elseif side == "RIGHT" then x = x + (pw + cw) / 2 + 2
    elseif side == "TOP" then y = y - (ph + ch) / 2 - 2
    elseif side == "BOTTOM" then y = y + (ph + ch) / 2 + 2 end
    if string.find(point,"LEFT",1,true) then x = x + (pw - cw) / 2
    elseif string.find(point,"RIGHT",1,true) then x = x - (pw - cw) / 2 end
    if string.find(point,"TOP",1,true) then y = y + (ph - ch) / 2
    elseif string.find(point,"BOTTOM",1,true) then y = y - (ph - ch) / 2 end
    if RWA_DB and RWA_DB.settings and RWA_DB.settings.yUp then y = -y end
    child.offsetX, child.offsetY = x, y
    -- A normal action-owned display can be anchored to another output. Native
    -- parenting carries the parent's scale, alpha, visibility and movement.
    child.parentOutputId = parentOutputId
    local rule = {id=nextId(data,data.rules,"r","nextRuleId"),name="Show "..(child.regionType or "display"),
      enabled=element.enabled ~= false and visibleRule ~= nil,when={mode="all",checks={
        element.followMain and {field="always"}
          or element.gateRuleId and {field="rule",ruleId=element.gateRuleId,value=true}
          or {field="active",sourceId=sourceId}}},actions={}}
    table.insert(data.rules,rule)
    Rules.AddAction(data,rule,{type="show",sourceId=sourceId,output=child})
  end
  visual.elements = nil
  return true
end

-- Older cooldown checks used the provider's hidden showOn setting. Make the
-- selected state explicit, retaining the old meaning of each saved check.
local function normalizeCooldownChecks(data)
  for _,rule in ipairs(data.rules or {}) do
    for _,check in ipairs(rule.when and rule.when.checks or {}) do
      local source=Rules.FindSource(data,check.sourceId)
      if check.field=="active" and source and source.type=="status" and source.check=="cooldown" then
        check.field=source.showOn=="ready" and "ready" or source.showOn=="cooldown" and "cooldown" or "skillAvailable"
      end
    end
  end
  return data
end

-- Data-only conversion for existing version 2 rules. The original is retained
-- locally for recovery; it is never evaluated and Share removes it on export.
function Rules.ConvertV2(original)
  if type(original) ~= "table" or original.schemaVersion ~= 2 then return nil end
  local data = RWA.CopyTable(original)
  local backup = RWA.CopyTable(original)
  backup.previousDefinition = nil
  data.previousDefinition = backup
  -- Repair the two recognizable broken saved examples while preserving their
  -- original definitions in the local recovery copy.
  if data.id == "In combat" then
    local source = Rules.FindSource(data, data.primarySourceId)
    if source and (source.type or "aura") == "aura" and source.check == "combat"
      and not (source.ids and #source.ids > 0) and not (source.names and #source.names > 0) then
      source.type = "status"
      for _, rule in ipairs(data.rules or {}) do
        for _, check in ipairs(rule.when and rule.when.checks or {}) do
          if check.sourceId == source.id and check.field == "present" then check.field = "active" end
        end
      end
    end
  elseif data.id == "KittyCombo mode" then
    local primary = Rules.FindSource(data, data.primarySourceId)
    if primary and primary.type == "custom" and type(primary.code) == "string" and string.find(primary.code, "Kitty.ModeUI", 1, true) then
      local unused = {}
      for _, rule in ipairs(data.rules or {}) do
        for _, check in ipairs(rule.when and rule.when.checks or {}) do
          local source = Rules.FindSource(data, check.sourceId)
          if source and (source.type or "aura") == "aura" and check.field == "present"
            and not (source.ids and #source.ids > 0) and not (source.names and #source.names > 0) then
            unused[source.id] = true
            check.sourceId, check.field = primary.id, "active"
          end
        end
      end
      for id in pairs(unused) do Rules.PruneSource(data, id) end
    end
  end
  for _, source in ipairs(data.sources or {}) do
    if (source.type or "aura") == "aura" then
      source.unit = source.unit or "player"
      source.filter = source.filter == "HARMFUL" and "HARMFUL" or "HELPFUL"
    elseif source.type == "status" then
      source.check = source.check or "health"
      if source.check ~= "combat" and source.check ~= "cooldown" then
        source.unit = source.unit or (source.check == "target" and "target" or "player")
      end
    elseif source.type == "recent" then source.measure,source.showOn=source.measure or "hits",source.showOn or "combat"
    elseif source.type == "lastcast" then source.unit,source.showOn=source.unit or "target",source.showOn or "seen"
    elseif source.type == "threat" then source.showOn=source.showOn or "combat"
    end
  end
  data.schemaVersion, data.nextActionId, data.nextOutputId = 3, 1, 1
  local excluded = {id=true,enabled=true,desc=true,schemaVersion=true,rules=true,sources=true,primarySourceId=true,
    nextRuleId=true,nextCheckId=true,nextSourceId=true,nextActionId=true,nextOutputId=true,previousDefinition=true,
    load=true,defaultVisible=true,x=true,y=true,point=true,sound=true,clickThrough=true,scale=true,
    autoScaleScreen=true,screenReferenceWidth=true,screenReferenceHeight=true}
  local visual = { regionType = data.regionType or "icon" }
  for key, value in pairs(data) do
    if not excluded[key] then visual[key] = RWA.CopyTable(value) end
  end
  -- Split before the owning action copies the primary visual. New output rules
  -- are appended only after conversion of the original rules below.
  local legacyElements = visual.elements
  local visibilityChanges={}
  for _,rule in ipairs(data.rules or {}) do
    if type(rule.set)=="table" and type(rule.set.visible)=="boolean" then
      visibilityChanges[#visibilityChanges+1]={ruleId=rule.id,visible=rule.set.visible}
    end
  end
  local targetId, defined
  local function show(rule)
    local a
    if not defined then
      a = Rules.AddAction(data, rule, {type="show", output=visual, sourceId=data.primarySourceId})
      targetId, defined = a.output.id, true
    else
      a = Rules.AddAction(data, rule, {type="show",targetId=targetId})
    end
  end
  if data.defaultVisible == true then
    local initial = {id=nextId(data,data.rules,"r","nextRuleId"),name="Initially visible",enabled=true,
      when={mode="all",checks={{field="always"}}},actions={}}
    table.insert(data.rules, 1, initial)
    show(initial)
  end
  -- Assign an output identity before resolving modifiers, even when their
  -- owner precedes the first matching show rule.
  if not targetId then
    targetId = nextId(data, actionItems(data, true), "o", "nextOutputId")
  end
  for _, rule in ipairs(data.rules or {}) do
    if rule.set then
      local set = rule.set
      rule.actions = {}
      if set.visible == true then
        if not defined then
          local a=Rules.AddAction(data,rule,{type="show",output=visual,sourceId=data.primarySourceId})
          a.output.id, defined = targetId, true
        else show(rule) end
      elseif set.visible == false then Rules.AddAction(data,rule,{type="hide",targetId=targetId}) end
      for _, key in ipairs({"color","alpha","grow","blink","overlayIcon"}) do
        if set[key] ~= nil then Rules.AddAction(data,rule,{type=key,targetId=targetId,value=set[key]}) end
      end
      if type(set.sound)=="string" and set.sound~="" then
        Rules.AddAction(data,rule,{type="sound",clip=set.sound,mode="once"})
      end
      rule.set = nil
    end
  end
  if not defined then
    local owner = {id=nextId(data,data.rules,"r","nextRuleId"),name="Display",enabled=false,
      when={mode="all",checks={{field="always"}}},actions={}}
    table.insert(data.rules,owner)
    local a=Rules.AddAction(data,owner,{type="show",output=visual,sourceId=data.primarySourceId})
    a.output.id=targetId
  end
  local visibleRule
  local needsVisibility = (type(data.sound)=="string" and data.sound~="" and data.sound~="none")
    or (type(legacyElements)=="table" and #legacyElements>0)
  if needsVisibility then
    local function gate(name,mode,checks)
      local r={id=nextId(data,data.rules,"r","nextRuleId"),name=name,enabled=true,when={mode=mode,checks={}},actions={}}
      data.rules[#data.rules+1]=r
      for _,check in ipairs(checks) do Rules.AddCheck(data,r,check) end
      return r.id
    end
    if data.defaultVisible==true then visibleRule=gate("Initially visible","all",{{field="always"}}) end
    for _,change in ipairs(visibilityChanges) do
      if change.visible then
        if visibleRule then
          visibleRule=gate("Visibility","any",{{field="rule",ruleId=change.ruleId,value=true},
            {field="rule",ruleId=visibleRule,value=true}})
        else visibleRule=change.ruleId end
      elseif visibleRule then
        visibleRule=gate("Visibility","all",{{field="rule",ruleId=visibleRule,value=true},
          {field="rule",ruleId=change.ruleId,value=false}})
      end
    end
    if visibleRule and type(data.sound)=="string" and data.sound~="" and data.sound~="none" then
      local r={id=nextId(data,data.rules,"r","nextRuleId"),name="Sound on show",enabled=true,
        when={mode="all",checks={}},actions={}}
      data.rules[#data.rules+1]=r
      Rules.AddCheck(data,r,{field="rule",ruleId=visibleRule,value=true})
      Rules.AddAction(data,r,{type="sound",clip=data.sound,mode="once"})
    end
  end
  local split,splitError=splitSimpleElements(data, visual, visibleRule, targetId)
  if not split then return nil,splitError end
  if legacyElements and not visual.elements then
    for _, rule in ipairs(data.rules) do
      for _, action in ipairs(rule.actions or {}) do
        if action.output and action.output.id == targetId then action.output.elements = nil end
      end
    end
  end
  -- Visual properties now belong to the show action. Keeping a second copy
  -- at aura level wastes memory and leaves two apparently editable models.
  for key in pairs(visual) do data[key] = nil end
  data.elements, data.sound, data.defaultVisible = nil, nil, nil
  Rules.EnsureCheckIds(data)
  return normalizeCooldownChecks(data)
end

-- Translate legacy definitions into action rules as data. Cases whose old
-- behavior cannot yet be represented are rejected instead of silently changed.
function Rules.ConvertLegacy(original)
  if type(original) ~= "table" or (original.schemaVersion ~= nil and original.schemaVersion ~= 1)
    or type(original.triggers) ~= "table" then return nil, "Not a legacy aura." end
  local data=RWA.CopyTable(original)
  local triggers=data.triggers
  if triggers.mode ~= nil and triggers.mode ~= "all" and triggers.mode ~= "any" then return nil,"Unsupported trigger mode." end
  local owned,elementSources={},{[1]=false}
  local auxiliary=type(triggers.auxiliary)=="table" and triggers.auxiliary or {}
  for _,element in ipairs(data.elements or {}) do
    local index=tonumber(element.from) or 0
    if index>0 then
      if not triggers[index] then return nil,"An extra display refers to a missing trigger." end
      owned[index]=true
    end
    elementSources[index>0 and index or 1]=true
  end
  local hasMain,fallback=false,nil
  for i=1,#triggers do
    if auxiliary[i]==true or auxiliary[tostring(i)]==true then owned[i]=true
    else fallback=fallback or i; if not owned[i] then hasMain=true end end
  end
  if not hasMain and fallback then owned[fallback]=nil end
  if #triggers==0 then return nil,"The aura has no source to convert." end
  data.schemaVersion,data.defaultVisible,data.sources,data.rules=2,false,{},{}
  data.nextSourceId,data.nextRuleId,data.nextCheckId=1,1,1
  local ids,checks,conditionGates,elementGates,sourceChoices={},{},{},{},{}
  local function convertedRule()
    local rule={id=nextId(data,data.rules,"r","nextRuleId"),enabled=true,name="",when={mode="all",checks={}},set={}}
    data.rules[#data.rules+1]=rule
    return rule
  end
  for index,trigger in ipairs(triggers) do
    if type(trigger)~="table" then return nil,"A source is invalid." end
    local source=RWA.CopyTable(trigger)
    -- Repair the identifiable stock combat example, leaving its source in the backup.
    if data.id=="In combat" and (source.type or "aura")=="aura" and source.check=="combat"
      and not (source.ids and #source.ids>0) and not (source.names and #source.names>0) then source.type="status" end
    local kind=source.type or "aura"
    if kind=="aura" and source.stacksOp and (not operators[source.stacksOp] or tonumber(source.stacks)==nil) then
      return nil,"This aura has an invalid legacy stacks filter."
    end
    local mode=source.showOn or "active"
    if kind=="aura" and (mode=="active" or mode=="missingOrExpiring") and source.remainingOp
      and (not operators[source.remainingOp] or (source.remaining~=nil and tonumber(source.remaining)==nil)) then
      return nil,"This aura has an invalid legacy time-left filter."
    end
    if kind=="aura" and mode~="active" and mode~="missing" and mode~="missingOrExpiring" and mode~="always" then
      return nil,"This aura has a legacy buff visibility setting that needs conversion."
    end
    ids[index]=Rules.AddSource(data,source)
    if kind=="aura" then source=Rules.FindSource(data,ids[index]); source.showOn=nil end
    local effective,missingGate,availability
    if kind=="aura" and source.stacksOp then
      local gate=convertedRule(); gate.name="Matching buff stacks"
      Rules.AddCheck(data,gate,{sourceId=ids[index],field="present"})
      Rules.AddCheck(data,gate,{sourceId=ids[index],field="stacks",op=source.stacksOp,value=source.stacks})
      effective=gate.id
      gate=convertedRule(); gate.name="Buff unit available"; gate.when.mode="any"
      Rules.AddCheck(data,gate,{sourceId=ids[index],field="present"})
      Rules.AddCheck(data,gate,{sourceId=ids[index],field="missing"})
      availability=gate.id
      gate=convertedRule(); gate.name="Matching buff missing"
      Rules.AddCheck(data,gate,{field="rule",ruleId=availability,value=true})
      Rules.AddCheck(data,gate,{field="rule",ruleId=effective,value=false})
      missingGate=gate.id
      -- Filtered-out buffs have the old static empty state: stacks/value 0,
      -- total 1, and no duration or provider-specific measurements.
      for _,condition in ipairs(data.conditions or {}) do
        if type(condition)=="table" and (tonumber(condition.trigger) or 1)==index
          and numericFields[condition.var] and condition.var~="remaining"
          and operators[condition.op] and tonumber(condition.value)~=nil then
          local matching=convertedRule(); matching.name="Filtered buff condition"
          Rules.AddCheck(data,matching,{field="rule",ruleId=effective,value=true})
          Rules.AddCheck(data,matching,{sourceId=ids[index],field=condition.var,op=condition.op,value=condition.value})
          local emptyValue = (condition.var=="stacks" or condition.var=="value") and 0
            or (condition.var=="total" and 1 or nil)
          if emptyValue ~= nil and RWA.Triggers.Compare(emptyValue,condition.op,condition.value) then
            local either=convertedRule(); either.name="Filtered buff condition or empty"; either.when.mode="any"
            Rules.AddCheck(data,either,{field="rule",ruleId=matching.id,value=true})
            Rules.AddCheck(data,either,{field="rule",ruleId=effective,value=false})
            conditionGates[condition]=either.id
          else
            conditionGates[condition]=matching.id
          end
        end
      end
    end
    local timeConditions={}
    if kind=="aura" then
      for _,condition in ipairs(data.conditions or {}) do
        if type(condition)=="table" and (tonumber(condition.trigger) or 1)==index and condition.var=="remaining"
          and operators[condition.op] and tonumber(condition.value)~=nil then
          local timerCheck={sourceId=ids[index],field="remaining",op=condition.op,value=condition.value}
          if effective then
            local timer=convertedRule(); timer.name="Matching buff time left"
            Rules.AddCheck(data,timer,{field="rule",ruleId=effective,value=true})
            Rules.AddCheck(data,timer,timerCheck)
            timerCheck={field="rule",ruleId=timer.id,value=true}
          end
          local gate=convertedRule(); gate.name="Time-left condition"; gate.when.mode="any"
          Rules.AddCheck(data,gate,{sourceId=ids[index],field="missing"})
          Rules.AddCheck(data,gate,timerCheck)
          conditionGates[condition]=gate.id
          timeConditions[#timeConditions+1]={field="rule",ruleId=gate.id,value=true}
        end
      end
    end
    do
      local check={sourceId=ids[index],field=kind=="aura" and (mode=="missing" and "missing" or "present") or "active"}
      if #timeConditions>0 then
        local gate=convertedRule(); gate.name="Time-left visibility"; gate.when.mode="any"
        for _,conditionCheck in ipairs(timeConditions) do Rules.AddCheck(data,gate,conditionCheck) end
        check={field="rule",ruleId=gate.id,value=true}
      elseif effective and mode=="missing" then check={field="rule",ruleId=missingGate,value=true}
      elseif effective and mode=="active" and not (source.remainingOp and source.remaining~=nil) then
        check={field="rule",ruleId=effective,value=true}
      elseif kind=="aura" and (mode=="always" or mode=="missingOrExpiring" or (mode=="active" and source.remainingOp and source.remaining~=nil)) then
        local timerCheck={sourceId=ids[index],field="remaining",op=source.remainingOp or "<",value=source.remaining or 3}
        if effective and mode=="missingOrExpiring" then
          local timer=convertedRule(); timer.name="Matching buff time left"
          Rules.AddCheck(data,timer,{field="rule",ruleId=effective,value=true}); Rules.AddCheck(data,timer,timerCheck)
          timerCheck={field="rule",ruleId=timer.id,value=true}
        end
        local gate=convertedRule(); gate.name="Buff availability"
        if mode=="always" then
          gate.when.mode="any"
          Rules.AddCheck(data,gate,{sourceId=ids[index],field="present"})
          Rules.AddCheck(data,gate,{sourceId=ids[index],field="missing"})
        elseif mode=="missingOrExpiring" then
          gate.when.mode="any"
          Rules.AddCheck(data,gate,missingGate and {field="rule",ruleId=missingGate,value=true} or {sourceId=ids[index],field="missing"})
          Rules.AddCheck(data,gate,timerCheck)
        else
          Rules.AddCheck(data,gate,effective and {field="rule",ruleId=effective,value=true} or {sourceId=ids[index],field="present"})
          Rules.AddCheck(data,gate,timerCheck)
        end
        check={field="rule",ruleId=gate.id,value=true}
      end
      -- A legacy "show" comparison reads the trigger before any condition
      -- forces it visible. Record that fact once, before applying overrides.
      local showBase
      for _,condition in ipairs(data.conditions or {}) do
        if type(condition)=="table" and (tonumber(condition.trigger) or 1)==index and condition.var=="show"
          and operators[condition.op] and tonumber(condition.value)~=nil then
          if not showBase then
            local gate=convertedRule(); gate.name="Original trigger visibility"; Rules.AddCheck(data,gate,check); showBase=gate.id
          end
          local yes=RWA.Triggers.Compare(1,condition.op,condition.value)
          local no=RWA.Triggers.Compare(0,condition.op,condition.value)
          local gate=convertedRule(); gate.name="Trigger visibility condition"
          if yes and no then Rules.AddCheck(data,gate,{field="always"})
          elseif yes or no then Rules.AddCheck(data,gate,{field="rule",ruleId=showBase,value=yes and true or false})
          else
            Rules.AddCheck(data,gate,{field="rule",ruleId=showBase,value=true})
            Rules.AddCheck(data,gate,{field="rule",ruleId=showBase,value=false})
          end
          conditionGates[condition]=gate.id
        end
      end
      local forced={}
      for _,condition in ipairs(data.conditions or {}) do
        if type(condition)=="table" and (tonumber(condition.trigger) or 1)==index
          and type(condition.set)=="table" and condition.set.show==true then
          if (not numericFields[condition.var] and condition.var~="show") or not operators[condition.op] or tonumber(condition.value)==nil then
            return nil,"A legacy show condition needs conversion."
          end
          local force=convertedRule(); force.name="Force trigger shown"
          if conditionGates[condition] then
            Rules.AddCheck(data,force,{field="rule",ruleId=conditionGates[condition],value=true})
          else
            Rules.AddCheck(data,force,{sourceId=ids[index],field=condition.var,op=condition.op,value=condition.value})
          end
          Rules.AddCheck(data,force,{sourceId=ids[index],field="unitAvailable"})
          forced[#forced+1]={field="rule",ruleId=force.id,value=true}
        end
      end
      if #forced>0 then
        local gate=convertedRule(); gate.name="Trigger visibility"; gate.when.mode="any"
        Rules.AddCheck(data,gate,check)
        for _,force in ipairs(forced) do Rules.AddCheck(data,gate,force) end
        check={field="rule",ruleId=gate.id,value=true}
      end
      if elementSources[index] or (not owned[index] and #triggers>1) then
        local gate=convertedRule(); gate.name="Display source active"
        Rules.AddCheck(data,gate,check)
        elementGates[index]=gate.id
        if not owned[index] then sourceChoices[#sourceChoices+1]={sourceId=ids[index],ruleId=gate.id} end
      end
      if not owned[index] then checks[#checks+1]=check end
    end
    if kind=="aura" then source.stacksOp,source.stacks,source.remainingOp,source.remaining=nil,nil,nil,nil end
  end
  data.primarySourceId=ids[1]
  if #checks==0 then return nil,"The aura has no primary trigger." end
  local show=convertedRule()
  show.name,show.when.mode,show.set="Show when active",triggers.mode or "all",{visible=true}
  for _,check in ipairs(checks) do Rules.AddCheck(data,show,check) end
  local hideRules,sounds={},{}
  for _,condition in ipairs(data.conditions or {}) do
    if type(condition)~="table" or not ids[tonumber(condition.trigger) or 1] or (not numericFields[condition.var] and condition.var~="show")
      or not operators[condition.op] or tonumber(condition.value)==nil or type(condition.set)~="table" then
      return nil,"A legacy condition needs conversion."
    end
    local set=condition.set
    local r=convertedRule()
    r.name,r.set="Condition",{}
    if conditionGates[condition] then
      Rules.AddCheck(data,r,{field="rule",ruleId=conditionGates[condition],value=true})
    else
      Rules.AddCheck(data,r,{sourceId=ids[tonumber(condition.trigger) or 1],field=condition.var,op=condition.op,value=condition.value})
    end
    for _,key in ipairs({"color","alpha","grow","blink","overlayIcon"}) do
      if set[key]~=nil then r.set[key]=key=="grow" and set[key]==true and 1.25 or RWA.CopyTable(set[key]) end
    end
    if set.hide==true then hideRules[#hideRules+1]=r end
    if type(set.sound)=="string" and set.sound~="" then sounds[#sounds+1]={rule=r.id,clip=set.sound} end
  end
  for _,r in ipairs(hideRules) do r.set.visible=false end
  -- Legacy condition sounds fired only while the final aura was visible. Keep
  -- that gate explicit so the new action's activation edge has the same scope.
  if type(data.sound)=="string" and data.sound~="" and data.sound~="none" then
    sounds[#sounds+1]={clip=data.sound}
  end
  data.sound=nil
  for _,sound in ipairs(sounds) do
    local rule=convertedRule(); rule.name=sound.rule and "Condition sound" or "Sound on show"; rule.set={sound=sound.clip}
    if sound.rule then Rules.AddCheck(data,rule,{field="rule",ruleId=sound.rule,value=true}) end
    Rules.AddCheck(data,rule,{field="rule",ruleId=show.id,value=true})
    for _,hide in ipairs(hideRules) do Rules.AddCheck(data,rule,{field="rule",ruleId=hide.id,value=false}) end
  end
  for _,element in ipairs(data.elements or {}) do
    local index=tonumber(element.from) or 0
    element.sourceId=index>0 and ids[index] or nil
    element.followMain=index==0
    element.gateRuleId=index>0 and elementGates[index] or nil
    -- Keep the old index until child Kitty prediction numbers are computed.
    -- The independently owned output drops it during the next conversion step.
  end
  data.triggers,data.conditions=nil,nil
  local converted,err=Rules.ConvertV2(data)
  if not converted then return nil,err end
  if #sourceChoices>0 then
    local parentId, children, mainAction = nil, {}, nil
    for _,rule in ipairs(converted.rules or {}) do
      for _,action in ipairs(rule.actions or {}) do
        if action.type=="show" and type(action.output)=="table" then
          if not parentId then parentId,mainAction=action.output.id,action
          elseif action.output.parentOutputId==parentId then children[#children+1]=action end
        end
      end
    end
    if mainAction then mainAction.sourceChoices=sourceChoices end
    for index,element in ipairs(original.elements or {}) do
      if (tonumber(element.from) or 0)==0 and children[index] then children[index].sourceChoices=sourceChoices end
    end
  end
  local backup=RWA.CopyTable(original); backup.previousDefinition=nil
  converted.previousDefinition=backup
  return converted
end

-- Decode old definitions before saving or importing. Conversion is data-only;
-- errors leave the original available for recovery and never start an engine.
function Rules.Normalize(data)
  if type(data)~="table" then return nil,"Invalid aura definition." end
  if data.schemaVersion==3 then return normalizeCooldownChecks(data) end
  if data.schemaVersion==2 then return Rules.ConvertV2(data) end
  if data.schemaVersion==nil or data.schemaVersion==1 then return Rules.ConvertLegacy(data) end
  return nil,"This aura requires a newer version."
end

-- Build the action-owned output index once when a definition is loaded or
-- edited. A show action owns its definition; modifiers refer to its stable ID.
function Rules.PrepareActions(data)
  local prepared = { outputs = {}, order = {}, usedSources = Rules.UsedSources(data) }
  for _, rule in ipairs(data.rules or {}) do
    for _, action in ipairs(rule.actions or {}) do
      local output = type(action) == "table" and action.type == "show" and action.output
      if type(output) == "table" and type(output.id) == "string" and type(output.regionType) == "string"
        and (not RWA.Regions or RWA.Regions.types[output.regionType]) and not prepared.outputs[output.id] then
        local binding=actionSourceId(data, rule, action)
        local boundSource=binding and Rules.FindSource(data,binding)
        local item = { definition = output, sourceId = binding, sourceChoices = action.sourceChoices,
          sourceValid = action.sourceId ~= false and (binding == nil or boundSource ~= nil),
          resource=output.resource or output.regionType=="soulpoints" and "psi" or boundSource and boundSource.type=="resource" and boundSource.resource }
        prepared.outputs[output.id] = item
        prepared.order[#prepared.order + 1] = output.id
      end
    end
  end
  -- Resolve parent references and order them before their children once per load.
  -- Broken or cyclic references stay incomplete instead of rendering at an
  -- unrelated position. Rule evaluation itself remains in authored order.
  local sorted, state = {}, {}
  local function visit(id)
    local item = prepared.outputs[id]
    if state[id] == 2 then return item.linkValid end
    if state[id] == 1 then return false end
    state[id] = 1
    local parent = item.definition.parentOutputId
    item.linkValid = parent == nil or (type(parent) == "string" and prepared.outputs[parent] ~= nil
      and parent ~= id and visit(parent)) or false
    state[id] = 2
    sorted[#sorted + 1] = id
    return item.linkValid
  end
  for _, id in ipairs(prepared.order) do visit(id) end
  prepared.order = sorted
  prepared.actionValid = {}
  for _, rule in ipairs(data.rules or {}) do
    for _, action in ipairs(rule.actions or {}) do
      if type(action) == "table" then prepared.actionValid[action] = Rules.ValidAction(action, prepared) end
    end
  end
  return prepared
end

function Rules.ValidAction(action, prepared)
  if type(action) ~= "table" or type(action.id) ~= "string" then return false end
  local kind = action.type
  if kind == "sound" then
    local interval = tonumber(action.interval)
    return type(action.clip) == "string" and RWA.Trim(action.clip) ~= ""
      and (action.mode == "once" or (action.mode == "loop" and interval and interval > 0 and interval < math.huge)) and true or false
  elseif kind == "code" then
    return type(action.code) == "string" and RWA.Trim(action.code) ~= ""
  end
  local id = kind == "show" and type(action.output) == "table" and action.output.id or action.targetId
  if not (prepared and prepared.outputs[id]) then return false end
  if kind == "show" then return action.sourceId ~= false and prepared.outputs[id].sourceValid and prepared.outputs[id].linkValid end
  if kind == "hide" then return true end
  if kind == "color" then
    if type(action.value) ~= "table" then return false end
    for i = 1, 3 do
      local value = tonumber(action.value[i])
      if not value or value ~= value or value < 0 or value > 1 then return false end
    end
    return true
  end
  if kind == "alpha" or kind == "grow" then
    local value = tonumber(action.value)
    return value ~= nil and value == value and value < math.huge and (kind == "grow" and value > 0 or kind == "alpha" and value >= 0 and value <= 1)
  end
  if kind == "blink" then return type(action.value) == "boolean" end
  if kind == "overlayIcon" then return type(action.value) == "string" and action.value ~= "" end
  return false
end

local function evaluateActions(data, snapshot, gates, prepared)
  prepared = prepared or Rules.PrepareActions(data)
  local result = { visible = false, matches = {}, valid = {}, actionValid = {}, outputs = {}, effects = {}, effectOrder = {} }
  for _, id in ipairs(prepared.order) do
    local item=prepared.outputs[id]; local def=item.definition
    local observation=snapshot[item.sourceId]
    local color=def.autoResourceColor and observation and RWA.Resources and RWA.Resources.COLORS[observation.resource] or def.color
    result.outputs[id] = { visible = false, color = color, alpha = tonumber(def.alpha) or 1, grow = 1 }
  end
  local allowed = data.enabled ~= false and gates ~= false
  for _, rule in ipairs(data.rules or {}) do
    local matched, valid = matchRule(rule, snapshot, data, result)
    matched = allowed and matched
    if type(rule) == "table" and type(rule.id) == "string" then
      result.matches[rule.id], result.valid[rule.id] = matched, valid
    end
    for _, action in ipairs(rule.actions or {}) do
      if type(action) == "table" then
        local key = type(rule.id) == "string" and type(action.id) == "string" and (rule.id .. "\031" .. action.id)
        local validAction = prepared.actionValid[action] == true
        if key then result.actionValid[key] = validAction end
        if matched and validAction then
          local kind = action.type
          local id = kind == "show" and type(action.output) == "table" and action.output.id or action.targetId
          local output = result.outputs[id]
          if output then
            if kind == "show" then
              local item=prepared.outputs[id]
              local def=item.definition
              output.visible = true
              local resource=item.resource
              if resource then
                local observation=Rules.OutputState(item,snapshot,result)
                output.visible=RWA.Resources and RWA.Resources.Matches(resource,observation) or false
              end
              -- An icon bound to a particular Kitty prediction has no content
              -- when that prediction does not exist. Bars retain their content.
              if def.kittyPick and def.regionType=="icon" and not (def.icon and def.icon~="") then
                local obs=snapshot[item.sourceId]
                local pick=tonumber(def.kittyPick)
                if pick and type(obs)=="table" and type(obs.kittyIcons)=="table" and not obs.kittyIcons[pick] then
                  output.visible=false
                end
              end
            elseif kind == "hide" then output.visible = false
            elseif kind == "color" and type(action.value) == "table" then output.color,output.colorOverride = action.value,true
            elseif kind == "alpha" and tonumber(action.value) then output.alpha = tonumber(action.value)
            elseif kind == "grow" and tonumber(action.value) then output.grow = tonumber(action.value)
            elseif kind == "blink" and type(action.value) == "boolean" then output.blink = action.value
            elseif kind == "overlayIcon" then output.overlayIcon = action.value end
          end
          if (kind == "sound" or kind == "code") and type(action.id) == "string" then
            local effectId = rule.id .. "\031" .. action.id
            result.effects[effectId] = action
            result.effectOrder[#result.effectOrder + 1] = effectId
          end
        end
      end
    end
  end
  for _, id in ipairs(prepared.order) do
    local output = result.outputs[id]
    local parentId = prepared.outputs[id].definition.parentOutputId
    if parentId then
      output.localVisible = output.visible
      local parent = result.outputs[parentId]
      output.visible = output.visible and parent ~= nil and parent.visible or false
    end
    if output.visible then result.visible = true end
  end
  return result
end

-- Migrated multi-trigger displays choose the first participating rule that
-- matched, using the already observed states and evaluated rule results.
function Rules.OutputState(item, snapshot, result)
  if type(item.sourceChoices)=="table" then
    for _,choice in ipairs(item.sourceChoices) do
      if type(choice)=="table" and type(choice.ruleId)=="string" and type(choice.sourceId)=="string"
        and result.matches[choice.ruleId] and snapshot[choice.sourceId] then return snapshot[choice.sourceId] end
    end
  end
  return snapshot[item.sourceId] or {}
end

-- This is pure resolution: it neither changes observations nor plays sounds.
function Rules.Evaluate(data, snapshot, gates, prepared)
  return evaluateActions(data, snapshot, gates, prepared)
end

-- One explanation source for the editor, list and rendered aura hover.
local function ruleLabel(data, id)
  for i, rule in ipairs(data.rules or {}) do
    if rule.id == id then return Rules.RuleTitle and Rules.RuleTitle(data,rule) or "Rule " .. i end
  end
  return "unresolved rule " .. tostring(id or "(choose)")
end

local function outputLabel(data, id)
  for i, rule in ipairs(data.rules or {}) do
    for _, action in ipairs(rule.actions or {}) do
      local output = action.type == "show" and action.output
      if type(output) == "table" and output.id == id then
        local labels = {icon="Icon", text="Text", aurabar="Bar", texture="Graphic", kittytracker="Kitty tracker", threatmeter="Threat meter"}
        return (labels[output.regionType] or "Display") .. " from " .. (Rules.RuleTitle and Rules.RuleTitle(data,rule) or "Rule "..i)
      end
    end
  end
  return "unresolved display " .. tostring(id or "(choose)")
end

function Rules.DescribeCheck(data, check, decorate)
  local edit=decorate or function(value) return tostring(value) end
  if type(check) ~= "table" then return edit("choose a check") end
  if check.field == "always" then return edit("always","condition") end
  if check.field == "rule" then
    return edit(ruleLabel(data,check.ruleId)).." is "..edit(check.value==true and "true" or check.value==false and "false" or "choose true or false","condition")
  end
  local source=Rules.FindSource(data,check.sourceId)
  if not source then return edit("choose a source") end
  local kind=source.type or "aura"
  local unit=source.unit or "player"
  local subject
  if kind=="aura" then
    local terms={}
    for _,id in ipairs(source.ids or {}) do terms[#terms+1]=tostring(id) end
    for _,name in ipairs(source.names or {}) do terms[#terms+1]=tostring(name) end
    subject=edit(source.filter=="HARMFUL" and "debuff" or "buff").." "..edit(#terms>0 and table.concat(terms,"/") or "(choose buff)").." on "..edit(unit)
  elseif kind=="status" then
    subject=source.check=="cooldown" and ("cooldown for "..edit(source.skill or "(choose skill)"))
      or (edit(unit).." "..edit(({buffcount="buff count",debuffcount="debuff count",mana="primary resource",skill="secondary resource"})[source.check] or source.check or "status"))
  elseif kind=="resource" then
    subject=edit("my "..string.lower(RWA.Resources and RWA.Resources.LABELS[source.resource] or "resource"))
  else subject=edit(({custom="custom condition",kitty="KittyCombo macro",recent="past second",lastcast="last cast",threat="threat"})[kind] or kind) end
  if check.field=="class" then
    local names=RWA.ClassNames or {}
    return edit(unit).." class is "..edit(names[check.class1] or "(choose primary)","condition").." / "..edit(names[check.class2] or "(choose secondary)","condition")
  end
  local states={present="present",missing="missing",active="active",ready="ready",cooldown="on cooldown",skillAvailable="available"}
  if states[check.field] then return subject.." is "..edit(states[check.field],"condition") end
  if check.field=="unitAvailable" then return edit(unit).." is "..edit("available","condition") end
  local fields={remaining="time left",stacks="stacks",percent="percent",value="value",duration="duration",total="total",perSecond="per second",casting="casting",hotbarSlot="hotbar slot"}
  local op=({["<"]="below",["<="]="at most",[">"]="above",[">="]="at least",["=="]="equals",["="]="equals",["~="]="not equal to",["!="]="not equal to"})[check.op] or "(choose comparison)"
  local value=check.value~=nil and tostring(check.value) or "(choose value)"
  return subject.." "..edit(fields[check.field] or "(choose check)").." "..edit(op,"condition").." "..edit(value..(check.field=="percent" and "%" or ""),"condition")
end

local function describeAction(data, action, decorate)
  local edit=decorate or function(value) return tostring(value) end
  if type(action) ~= "table" then return edit("choose an action") end
  local kind = action.type
  if kind == "sound" then
    local mode = action.mode == "once" and "once on activation" or action.mode == "loop" and ("every " .. tostring(action.interval or "?") .. " seconds") or "(choose once or loop)"
    return edit("play") .. " " .. edit(action.clip or "(choose sound)") .. " " .. edit(mode)
  elseif kind == "code" then return edit("run Lua").." once on activation" end
  local id = kind == "show" and type(action.output) == "table" and action.output.id or action.targetId
  local target = edit(outputLabel(data, id))
  if kind == "show" then
    local pick=type(action.output)=="table" and tonumber(action.output.kittyPick)
    local parent=type(action.output)=="table" and action.output.parentOutputId
    return edit("show").." " .. target .. (pick and (" (Kitty pick "..pick..")") or "")
      .. (parent and (" attached to "..edit(outputLabel(data,parent))) or "")
      .. (action.sourceChoices and " using the first matching source" or "")
  end
  if kind == "hide" then return edit("hide").." " .. target end
  if kind == "color" then
    local c = action.value
    local color = Rules.ColorName(c)
    color = color and string.lower(color) or "choose colour"
    return edit("colour").." " .. target .. " " .. edit(color)
  end
  if kind == "grow" then
    local value = tonumber(action.value)
    return edit("scale").." " .. target .. " to " .. edit(tostring(value and math.floor(value*100+0.5) or "?").."%")
  end
  if kind == "alpha" then return "change opacity of " .. target end
  if kind == "blink" then return "change blinking of " .. target end
  if kind == "overlayIcon" then return "change overlay of " .. target end
  return edit("choose an action")
end

function Rules.DescribeRule(data, rule)
  local conditions, actions = {}, {}
  for _, check in ipairs(type(rule.when) == "table" and rule.when.checks or {}) do conditions[#conditions+1] = Rules.DescribeCheck(data, check) end
  for _, action in ipairs(rule.actions or {}) do actions[#actions+1] = describeAction(data, action) end
  -- Until saved definitions are converted, describe their existing assignments.
  if rule.set then
    local set=rule.set
    if set.visible ~= nil then actions[#actions+1] = set.visible and "show display" or "hide display" end
    if set.color then actions[#actions+1] = "change colour" end
    if set.alpha ~= nil then actions[#actions+1] = "change opacity" end
    if set.grow ~= nil then actions[#actions+1] = "change size" end
    if set.blink ~= nil then actions[#actions+1] = "change blinking" end
    if set.overlayIcon ~= nil then actions[#actions+1] = "change overlay" end
    if set.sound then actions[#actions+1] = "play " .. tostring(set.sound) .. " once" end
  end
  if #conditions == 0 then conditions[1] = "choose a check" end
  if #actions == 0 then actions[1] = "choose an action" end
  return conditions, actions, rule.when and rule.when.mode == "any" and "OR" or "AND"
end

function Rules.RuleSentence(data, rule)
  local checks, actions, conjunction = Rules.DescribeRule(data, rule)
  return "WHEN " .. table.concat(checks, " " .. conjunction .. " ") .. " THEN " .. table.concat(actions, "; ")
end

local function bracket(value,status)
  local color=status==true and "|cff50e69a" or status==false and "|cffff6b76" or "|cff43d5d0"
  local clean=tostring(value):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  return color.."["..clean.."]|r"
end
function Rules.TooltipCheck(data,check,result,snapshot,rule)
  local status
  if result and snapshot and (not rule or rule.enabled~=false) and validCheck(check,snapshot,data,result) then
    if check.field=="always" or check.field=="rule" or snapshot[check.sourceId] then status=match(check,snapshot,result) end
  end
  return Rules.DescribeCheck(data,check,function(value,role)
    if role=="condition" then return bracket(value,status) end
    return bracket(value)
  end)
end
function Rules.TooltipLines(data, result, snapshot, onlyRule)
  local observed=result
  if not result and data.schemaVersion==3 then result=Rules.Evaluate(data,{},false,Rules.PrepareActions(data)) end
  local lines={}
  local used=Rules.SupportingUsage and Rules.SupportingUsage(data) or {}
  local branches=Rules.BranchInfo and Rules.BranchInfo(data)
  if data.enabled==false then lines[#lines+1]="Disabled" end
  local load=data.load or {}
  if load.combat~=nil then lines[#lines+1]="Load: "..bracket(load.combat and "in combat" or "out of combat") end
  if load.class and load.class~="" then lines[#lines+1]="Class: "..bracket(load.class) end
  if tonumber(load.level) then lines[#lines+1]="Minimum level: "..bracket(load.level) end
  local function condition(check,owner,seen)
    local helper=check.field=="rule" and check.value==true and Rules.FindRule(data,check.ruleId)
    if helper and helper.enabled~=false and #(helper.actions or {})==0 and not seen[helper.id] then
      seen[helper.id]=true
      local parts={}
      for _,c in ipairs(helper.when and helper.when.checks or {}) do parts[#parts+1]=condition(c,helper,seen) end
      seen[helper.id]=nil
      if #parts>0 then return (#parts>1 and "(" or "")..table.concat(parts,helper.when.mode=="any" and " OR " or " AND ")..(#parts>1 and ")" or "") end
    end
    return Rules.TooltipCheck(data,check,observed,snapshot,owner)
  end
  local function actionText(action,previousShow)
    if action.type=="show" then
      local source=Rules.FindSource(data,action.sourceId)
      local kind=action.output and action.output.regionType
      local label=kind=="icon" and source and source.type=="status" and source.check=="class" and "class icon"
        or ({icon="icon",text="text",aurabar="bar",texture="graphic",kittytracker="next three abilities",threatmeter="threat meter"})[kind] or "display"
      return (previousShow and "" or bracket("show").." ")..bracket(label)
    end
    return describeAction(data,action,bracket)
  end
  for _,rule in ipairs(data.rules or {}) do
    local helper=#(rule.actions or {})==0 and used[rule.id]
    if (not onlyRule or rule==onlyRule) and (onlyRule or not helper) then
      local status=rule.enabled==false and " (disabled)" or result and result.valid and result.valid[rule.id]==false and " (incomplete)" or ""
      lines[#lines+1]=(branches and branches.parent[rule.id] and "  -> " or "")..(Rules.RuleTitle and Rules.RuleTitle(data,rule) or rule.name or "Behavior")..status
      local checks={}
      for _,c in ipairs(rule.when and rule.when.checks or {}) do checks[#checks+1]=condition(c,rule,{}) end
      lines[#lines+1]="  WHEN "..(#checks>0 and table.concat(checks,rule.when.mode=="any" and " OR " or " AND ") or bracket("choose a condition"))
      local actions,previous={},false
      for _,action in ipairs(rule.actions or {}) do
        local key=action.id and rule.id.."\031"..action.id
        local incomplete=key and result and result.actionValid and result.actionValid[key]==false
        actions[#actions+1]=actionText(action,previous)..(incomplete and " (incomplete)" or "")
        previous=action.type=="show"
      end
      if #actions>0 then lines[#lines+1]="  THEN "..table.concat(actions," AND ")
      elseif helper then
        local users={};for id in pairs(used[rule.id]) do users[#users+1]=bracket(ruleLabel(data,id)) end
        table.sort(users);lines[#lines+1]="  Used by "..table.concat(users,", ")
      else lines[#lines+1]="  THEN "..bracket("choose an action") end
    end
  end
  return lines
end

-- A one-time editing cleanup for converted definitions. This is never called
-- by observation/evaluation. Compare complete definitions, not displayed labels.
local function sameDefinition(a,b,ignoreId)
  if type(a)~=type(b) then return false end
  if type(a)~="table" then return a==b end
  for k,v in pairs(a) do if not (ignoreId and k=="id") and not sameDefinition(v,b[k],false) then return false end end
  for k in pairs(b) do if not (ignoreId and k=="id") and a[k]==nil then return false end end
  return true
end
function Rules.SimplifyConverted(data)
  if type(data)~="table" or data.schemaVersion~=3 or type(data.previousDefinition)~="table" then return nil end
  if type(data.sources)~="table" or type(data.rules)~="table" then return nil end
  for _,s in ipairs(data.sources) do if type(s)~="table" or type(s.id)~="string" or s.type=="custom" then return nil end end
  for _,r in ipairs(data.rules) do
    if type(r)~="table" or type(r.id)~="string" or type(r.when)~="table" or type(r.when.checks)~="table" or type(r.actions)~="table" or (r.when.mode~="all" and r.when.mode~="any") then return nil end
    for _,c in ipairs(r.when.checks) do if type(c)~="table" then return nil end end
    for _,a in ipairs(r.actions) do
      if type(a)~="table" or a.type=="code" or a.sourceChoices~=nil and type(a.sourceChoices)~="table" or a.output~=nil and type(a.output)~="table" then return nil end
      for _,choice in ipairs(a.sourceChoices or {}) do
        if type(choice)~="table" or type(choice.ruleId)~="string" or type(choice.sourceId)~="string" then return nil end
      end
    end
  end
  -- For built-in auras, identify untouched conversion helpers from their
  -- recovery copy. A player may have edited a default, so its name alone is
  -- not evidence that a condition group is safe to remove.
  local originalHelpers={}
  local backup=data.previousDefinition
  local builtin=false
  for _,example in ipairs(RWA.BuiltinExamples or {}) do
    if example.id==data.id and backup.id==data.id then builtin=true; break end
  end
  if builtin then
    local convert=backup.schemaVersion==2 and Rules.ConvertV2 or Rules.ConvertLegacy
    local ok,original=pcall(convert,backup)
    if ok and type(original)=="table" then
      local originals={}
      for _,r in ipairs(original.rules or {}) do originals[r.id]=r end
      for _,r in ipairs(data.rules) do
        if r.name=="Display source active" and originals[r.id] and sameDefinition(r,originals[r.id],false) then
          originalHelpers[r.id]=true
        end
      end
    end
  end
  local report={sources=0,checks=0,rules=0,choices=0}; local remap,kept={},{}
  for _,s in ipairs(data.sources or {}) do
    local equivalent
    if s.type=="aura" then
      for _,other in ipairs(kept) do if sameDefinition(s,other,true) then equivalent=other; break end end
    end
    if equivalent then remap[s.id]=equivalent.id; report.sources=report.sources+1 else kept[#kept+1]=s end
  end
  if report.sources>0 then
    data.sources=kept; data.primarySourceId=remap[data.primarySourceId] or data.primarySourceId
    for _,r in ipairs(data.rules) do
      for _,c in ipairs(r.when and r.when.checks or {}) do c.sourceId=remap[c.sourceId] or c.sourceId end
      for _,a in ipairs(r.actions or {}) do
        a.sourceId=remap[a.sourceId] or a.sourceId
        for _,choice in ipairs(a.sourceChoices or {}) do choice.sourceId=remap[choice.sourceId] or choice.sourceId end
      end
    end
  end
  -- A choice list whose every branch AND fallback use the same observation
  -- cannot change an output's data. Keep source IDs and output IDs stable.
  local prepared=Rules.PrepareActions(data)
  for _,r in ipairs(data.rules) do
    local checks=r.when and r.when.checks or {}
    for i=#checks,2,-1 do
      for j=1,i-1 do
        if checks[i].field and sameDefinition(checks[i],checks[j],true) then table.remove(checks,i); report.checks=report.checks+1; break end
      end
    end
    for _,a in ipairs(r.actions or {}) do
      local item=a.output and prepared.outputs[a.output.id]
      if item and a.sourceChoices and #a.sourceChoices>0 then
        local equal=true
        for _,choice in ipairs(a.sourceChoices) do if choice.sourceId~=item.sourceId then equal=false; break end end
        if equal then a.sourceChoices=nil; report.choices=report.choices+1 end
      end
    end
  end
  local referenced={}
  for _,r in ipairs(data.rules) do
    for _,c in ipairs(r.when and r.when.checks or {}) do if c.ruleId then referenced[c.ruleId]=true end end
    for _,a in ipairs(r.actions or {}) do for _,choice in ipairs(a.sourceChoices or {}) do referenced[choice.ruleId]=true end end
  end
  for i=#data.rules,1,-1 do
    local r=data.rules[i]
    local duplicated=false
    if r.name=="Display source active" and r.enabled~=false and #(r.actions or {})==0 and r.when.mode=="all" and #r.when.checks==1 and not referenced[r.id] then
      for _,other in ipairs(data.rules) do
        if #(other.actions or {})>0 then
          for _,check in ipairs(other.when.checks) do if sameDefinition(r.when.checks[1],check,true) then duplicated=true; break end end
        end
      end
    end
    if duplicated or (originalHelpers[r.id] and not referenced[r.id]) then table.remove(data.rules,i); report.rules=report.rules+1 end
  end
  if report.sources+report.checks+report.rules+report.choices==0 then return nil end
  return report
end

local readableNames={}
local unitNames={player="me",target="my target",pet="my pet"}
local displayKinds={icon="icon",aurabar="bar",text="text",texture="graphic",kittytracker="skill tracker",threatmeter="threat meter",soulpoints="soul points"}
function Rules.ReadableSource(source)
  if not source then return "Choose a condition" end
  local kind=source.type or "aura"
  if kind=="resource" then return RWA.Resources and RWA.Resources.LABELS[source.resource] or "Choose a resource" end
  if kind=="aura" then
    local id=source.ids and source.ids[1]
    local known=id and RWA_DB and RWA_DB.buffInfo and RWA_DB.buffInfo[tostring(id)]
    local name=known and known.name or source.names and source.names[1]
    if not name and id then
      if readableNames[id]==nil then
        local ok,value
        if type(TEXT)=="function" then ok,value=pcall(TEXT,"Sys"..tostring(id).."_name") end
        readableNames[id]=ok and type(value)=="string" and value~="" and not string.find(value,"^Sys%d") and value or false
      end
      name=readableNames[id] or nil
    end
    local noun=source.filter=="HARMFUL" and "Debuff" or "Buff"
    local count=#(source.ids or {})+#(source.names or {})
    return (name or (id and noun.." "..id) or "Choose "..string.lower(noun))..(count>1 and " +"..(count-1) or "")
  end
  if kind=="status" then
    return ({health="Health",durability="Durability",mana="Primary resource",skill="Secondary resource",combat="Combat",target="Target",cast="Casting",class="Class",buffcount="Buff count",debuffcount="Debuff count"})[source.check]
      or (source.check=="cooldown" and (source.skill and source.skill~="" and source.skill or "Choose skill").." cooldown") or "Status"
  end
  return ({recent="Recent activity",lastcast="Last cast",threat="Threat",kitty="KittyCombo macro",custom="Custom condition"})[kind] or kind
end
function Rules.SupportingUsage(data)
  local used={}
  for i,r in ipairs(data.rules or {}) do
    local function link(id)
      if id then used[id]=used[id] or {}; used[id][r.id]=i end
    end
    for _,c in ipairs(r.when and r.when.checks or {}) do if c.field=="rule" then link(c.ruleId) end end
    for _,a in ipairs(r.actions or {}) do for _,choice in ipairs(a.sourceChoices or {}) do link(choice.ruleId) end end
  end
  return used
end
function Rules.IsGeneratedHelper(rule)
  return rule.name=="Display source active" and #(rule.actions or {})==0
end
-- A branch is an ordinary ordered rule guarded by its parent's result. The
-- presentation derives the tree from these real dependencies; there is no
-- second evaluator or separately maintained branch format.
function Rules.BranchInfo(data)
  local info={parent={},depth={},roots={},children={},scope={},output={}}; local prior,owners={},{}
  for _,r in ipairs(data.rules or {}) do
    local checks=r.when and r.when.checks or {}
    if r.when and (r.when.mode=="all" or #checks==1) then
      for _,c in ipairs(checks) do
        local parent=c.field=="rule" and c.value==true and prior[c.ruleId]
        if parent and not Rules.IsGeneratedHelper(parent) then info.parent[r.id]=parent.id; info.scope[r.id]="condition"; break end
      end
    end
    if not info.parent[r.id] and #(r.actions or {})>0 then
      local target,owner,onlyModifiers=nil,nil,true
      local modifiers={color=true,alpha=true,grow=true,blink=true,overlayIcon=true,hide=true}
      for _,action in ipairs(r.actions) do
        if not modifiers[action.type] or not action.targetId or not owners[action.targetId] then onlyModifiers=false; break end
        if target and target~=action.targetId then onlyModifiers=false; break end
        target,owner=action.targetId,owners[action.targetId]
      end
      if onlyModifiers and owner then
        info.parent[r.id],info.scope[r.id],info.output[r.id]=owner.id,"display",target
      end
    end
    local parent=info.parent[r.id]
    info.depth[r.id]=parent and (info.depth[parent] or 0)+1 or 0
    if parent then info.children[parent]=info.children[parent] or {}; table.insert(info.children[parent],r.id)
    elseif not Rules.IsGeneratedHelper(r) then info.roots[#info.roots+1]=r.id end
    prior[r.id]=r
    for _,action in ipairs(r.actions or {}) do
      if action.type=="show" and type(action.output)=="table" and action.output.id then owners[action.output.id]=r end
    end
  end
  return info
end
function Rules.AddBranch(data,parentId)
  local parent=Rules.FindRule(data,parentId)
  if not parent then return nil,"Choose a parent condition first." end
  local rule,err=Rules.Add(data)
  if not rule then return nil,err end
  rule.when.mode="all"
  Rules.AddCheck(data,rule,{field="rule",ruleId=parentId,value=true})
  return rule
end
function Rules.BranchDisplay(data,rule)
  local info=Rules.BranchInfo(data); local current=rule
  for _=1,#(data.rules or {}) do
    if not current then return nil end
    for _,a in ipairs(current.actions or {}) do
      if a.type=="show" and a.output and a.output.id then return a.output.id end
      if a.targetId then return a.targetId end
    end
    current=info.parent[current.id] and Rules.FindRule(data,info.parent[current.id])
  end
end
function Rules.ColorName(value)
  if type(value)~="table" or not tonumber(value[1]) or not tonumber(value[2]) or not tonumber(value[3]) then return nil end
  local r,g,b=value[1],value[2],value[3]
  if r>.65 and g<.4 and b<.4 then return "Red" end
  if g>.55 and r<.4 and b<.5 then return "Green" end
  if b>.65 and r<.4 and g<.65 then return "Blue" end
  if r>.85 and g>.85 and b>.85 then return "White" end
  if r>.7 and g>.65 and b<.35 then return "Yellow" end
  return string.format("#%02X%02X%02X",math.floor(math.max(0,math.min(1,r))*255+.5),math.floor(math.max(0,math.min(1,g))*255+.5),math.floor(math.max(0,math.min(1,b))*255+.5))
end
function Rules.ActionTitle(action)
  local kind=action and action.type
  if kind=="show" then return "Show "..(displayKinds[action.output and action.output.regionType] or "display") end
  return ({hide="Hide display",color="Change colour",grow="Change size",alpha="Change opacity",blink="Blink",overlayIcon="Overlay an icon",sound="Play sound",code="Run Lua"})[kind] or "Choose an action"
end
function Rules.ActionCaption(action)
  if action.type=="sound" then return "Play "..(action.clip or "sound")..(action.mode=="once" and " once" or action.mode=="loop" and " repeatedly" or "") end
  if action.type=="color" and type(action.value)=="table" and action.value[1]==1 and action.value[2]==0 and action.value[3]==0 then return "Make display red" end
  return Rules.ActionTitle(action)
end
function Rules.RuleStatus(rule,result,used)
  if rule.enabled==false then return "Disabled" end
  if result and result.valid[rule.id]==false then return "Needs setup" end
  for _,action in ipairs(rule.actions or {}) do
    local key=type(rule.id)=="string" and type(action.id)=="string" and rule.id.."\031"..action.id
    if result and (not key or result.actionValid[key]==false) then return "Needs setup" end
  end
  if #(rule.actions or {})==0 and not (used and used[rule.id]) then return "Add action" end
  return result and result.matches[rule.id] and "Matched" or "Waiting"
end
function Rules.RuleTitle(data,rule)
  local name=rule.name
  if name and name~="" and name~="Display source active" and name~="Show when active" and name~="Condition" and not string.match(name,"^Rule %d+$") then return name end
  if #(rule.actions or {})>0 then return Rules.ActionTitle(rule.actions[1])..(#rule.actions>1 and " + "..(#rule.actions-1).." action(s)" or "") end
  local check=rule.when and rule.when.checks and rule.when.checks[1]
  if check and check.sourceId then return Rules.ReadableSource(Rules.FindSource(data,check.sourceId)).." "..(check.field=="missing" and "missing" or check.field=="present" and "present" or "condition") end
  return "New behavior"
end
function Rules.ReferenceLabel(data,id)
  local rule=Rules.FindRule(data,id)
  return rule and Rules.RuleTitle(data,rule) or "Choose a condition group"
end
function Rules.ListOverview(data)
  local info=Rules.BranchInfo(data); local main,branches,details
  branches,details={},{}
  for _,r in ipairs(data.rules or {}) do
    if not Rules.IsGeneratedHelper(r) then
      if not main then main=r
      elseif #(r.actions or {})>0 or info.parent[r.id] then
        local condition
        for _,c in ipairs(r.when and r.when.checks or {}) do
          if c.field~="rule" or c.ruleId~=info.parent[r.id] then condition=Rules.HumanCheck(data,c); break end
        end
        branches[#branches+1]=(info.parent[r.id] and "-> " or "Also: ")..(condition or Rules.RuleTitle(data,r))
        local action=r.actions and r.actions[1]
        local title=action and Rules.ActionTitle(action) or "Conditional branch"
        if action and action.type=="color" and type(action.value)=="table" and action.value[1]==1 and action.value[2]==0 and action.value[3]==0 then title="Make display red" end
        details[#details+1]={title=title,condition=condition or Rules.RuleTitle(data,r),parent=info.parent[r.id]}
      end
    end
  end
  local first=main and main.actions and main.actions[1]
  local description=first and Rules.ActionCaption(first) or main and Rules.RuleTitle(data,main) or "Start a new behavior"
  if first and #main.actions>1 then description=description.." + "..(#main.actions-1).." action(s)" end
  local checks=main and main.when and main.when.checks or {}
  if #checks>0 then description=description.." - "..Rules.HumanCheck(data,checks[1]) end
  return description,branches,info,details
end
function Rules.HumanCheck(data,check)
  if not check then return "choose a condition" end
  if check.field=="rule" then
    local r=Rules.FindRule(data,check.ruleId)
    return (r and Rules.RuleTitle(data,r) or "Choose a rule")..(check.value==false and " does not match" or " matches")
  end
  if check.field=="always" then return "this aura is loaded" end
  local source=Rules.FindSource(data,check.sourceId)
  if not source then return "choose a condition" end
  if source.type=="resource" and check.field=="active" then
    return "my "..string.lower(RWA.Resources and RWA.Resources.LABELS[source.resource] or "resource").." is available"
  end
  if source.type=="status" and source.check=="combat" and check.field=="active" then return "you are in combat" end
  if source.type=="kitty" and check.field=="hotbarSlot" and (check.op=="==" or check.op=="=") then
    return "the KittyCombo macro is in hotbar slot "..tostring(check.value or "?")
  end
  local name=Rules.ReadableSource(source)
  local who=unitNames[source.unit] or source.unit or "choose a unit"
  if source.type=="status" and source.check~="cooldown" and source.check~="combat" then name=(source.unit=="player" and "my " or who.."'s ")..string.lower(name) end
  local state=({missing="is missing",present="is present",active="is active",ready="is ready",cooldown="is on cooldown",unitAvailable="is available",skillAvailable="is available"})[check.field]
  if check.field=="class" then
    local classes=RWA.ClassNames or {}
    state="is "..(classes[check.class1] or "choose primary").." / "..(classes[check.class2] or "choose secondary")
  elseif not state then
    local op=({["<"]="below",["<="]="at most",[">"]="above",[">="]="at least",["=="]="equal to",["="]="equal to",["~="]="not equal to"})[check.op] or "choose comparison"
    local measure=check.field=="remaining" and "time left " or check.field=="stacks" and "stacks " or check.field=="hotbarSlot" and "hotbar slot " or ""
    state=measure.."is "..op.." "..tostring(check.value or "?")..(check.field=="percent" and "%" or check.field=="remaining" and " s" or "")
  end
  return name.." "..state..((source.type or "aura")=="aura" and " on "..who or "")
end
function Rules.AuraSummary(data)
  local main,extras
  for _,r in ipairs(data.rules or {}) do
    if #(r.actions or {})>0 then if not main then main=r else extras=(extras or 0)+1 end end
  end
  if not main then return "Choose when something should happen, then add an action." end
  local checks=main.when and main.when.checks or {}
  local why=Rules.HumanCheck(data,checks[1])
  if #checks>1 then why=why..(main.when.mode=="any" and " OR " or " AND ")..(#checks-1).." more check(s)" end
  return Rules.ActionTitle(main.actions[1]).." when "..why.."."..(extras and (" "..extras.." additional behavior(s).") or #main.actions>1 and " Also "..string.lower(Rules.ActionTitle(main.actions[2])).."." or "")
end
function Rules.CheckResult(data,check,result,snapshot)
  if not result or not snapshot or not validCheck(check,snapshot,data,result) then return nil end
  if check.sourceId and not snapshot[check.sourceId] then return nil end
  return match(check,snapshot,result)
end
function Rules.PreviewExplanation(data,result,snapshot,prepared,gates)
  if data.enabled==false then return "Disabled","Turn on this aura to display it." end
  if gates==false then return "Not loaded","The aura's Load restrictions do not match." end
  local function kittyReason(rule)
    for _,check in ipairs(rule.when and rule.when.checks or {}) do
      local source=Rules.FindSource(data,check.sourceId)
      if source and source.type=="kitty" and (source.hotbarSlot~=nil or check.field=="hotbarSlot") then
        local observed=snapshot and snapshot[source.id]
        local reason=observed and observed.reason
        local labels=RWA.KittyTracker and RWA.KittyTracker.REASONS or {}
        local message=reason and labels[reason]
        local slot=tonumber(source.hotbarSlot)
        if not slot or slot<1 or slot>80 or slot~=math.floor(slot) then
          message="Choose a hotbar slot from 1 to 80."
        elseif observed and observed.available and observed.active~=true then
          message=message or "No skill is currently predicted for this macro."
        end
        if message then return "Hotbar slot "..tostring(source.hotbarSlot or "?")..": "..message end
      end
    end
  end
  local visibility,colour={},{}
  for _,r in ipairs(data.rules or {}) do
    if result.matches[r.id] then
      for _,a in ipairs(r.actions or {}) do
        if prepared.actionValid[a] then
          local id=a.type=="show" and a.output.id or a.targetId
          if a.type=="show" or a.type=="hide" then visibility[id]={rule=r,action=a}
          elseif a.type=="color" then colour[id]=r end
        end
      end
    end
  end
  local function reason(rule)
    local parts={}
    for _,c in ipairs(rule.when and rule.when.checks or {}) do
      if rule.when.mode~="any" or Rules.CheckResult(data,c,result,snapshot) then parts[#parts+1]=Rules.HumanCheck(data,c) end
    end
    return #parts>0 and table.concat(parts," and ") or "its conditions match"
  end
  local visibleId,visibleCount
  for _,id in ipairs(prepared.order) do if result.outputs[id].visible then visibleId=visibleId or id; visibleCount=(visibleCount or 0)+1 end end
  if visibleId then
    local active=visibility[visibleId]; local status="Visible"
    if #prepared.order>1 then status=visibleCount.." of "..#prepared.order.." displays visible" end
    local value=result.outputs[visibleId].color
    local colorName=type(value)=="table" and value[1]==1 and value[2]==0 and value[3]==0 and "Red"
    if colorName then status=status.." · "..colorName end
    local detail=active and reason(active.rule) or "The display's conditions match."
    if colour[visibleId] and (not active or colour[visibleId]~=active.rule) then detail=detail.."\nColour changes when "..reason(colour[visibleId]) end
    return status,detail
  end
  if #prepared.order==0 and #result.effectOrder>0 then return "Action matched","The preview is silent and does not run actions." end
  for _,r in ipairs(data.rules or {}) do if result.valid[r.id]==false then return "Needs setup",kittyReason(r) or Rules.RuleTitle(data,r)..": choose the remaining condition settings." end end
  for _,id in ipairs(prepared.order) do
    local active=visibility[id]
    if active and active.action.type=="hide" then return "Hidden","Hidden by "..Rules.RuleTitle(data,active.rule)..": "..reason(active.rule) end
  end
  for _,r in ipairs(data.rules or {}) do
    for _,a in ipairs(r.actions or {}) do if not prepared.actionValid[a] then return "Needs setup","Choose the remaining settings for "..string.lower(Rules.ActionTitle(a)).."." end end
    if #(r.actions or {})>0 then
      for _,c in ipairs(r.when and r.when.checks or {}) do
        if Rules.CheckResult(data,c,result,snapshot)==false then return "Hidden",kittyReason(r) or "Waiting until "..Rules.HumanCheck(data,c).."." end
      end
    end
  end
  return "Hidden","No display action currently matches."
end


-- Detached placement rendering, shared by world markers and the editor pane.
-- Only small observation/visual tables are reused here. Definitions, cached
-- live observations, rule results and action activation history stay untouched.
local EMPTY_PLACEMENT={}
local function placementIconPath(value) return type(value)=="string" and value~="" and value or nil end
function Rules.PlacementPreview(definition,source,observed,visual,now,cache)
  cache=cache or {}
  local state=cache.state or {}; cache.state=state
  local shown=cache.visual or {}; cache.visual=shown
  if observed~=state then
    for key in pairs(state) do state[key]=nil end
    for key,value in pairs(type(observed)=="table" and observed or EMPTY_PLACEMENT) do state[key]=value end
  end
  if visual~=shown then
    for key in pairs(shown) do shown[key]=nil end
    for key,value in pairs(type(visual)=="table" and visual or EMPTY_PLACEMENT) do shown[key]=value end
  end
  definition=definition or EMPTY_PLACEMENT
  now=tonumber(now) or 0
  local inactive=not observed or observed.available==false or observed.active==false
  local kind=source and (source.type or "aura")
  local resource=kind=="resource" and source.resource or definition.resource or definition.regionType=="soulpoints" and "psi"
  if resource then
    if not state._resourceUnavailablePreview and RWA.Resources and not RWA.Resources.Matches(resource,state) then
      RWA.Resources.Preview(resource,"partial",state)
      state._placementSample=true
    end
    -- Resource zero and Max eligibility are already normalized. Do not apply
    -- generic sample progress/stacks or substitute nonzero PSI content.
    state._placement=true
    shown.visible,shown.localVisible=state.available==true,state.available==true
    shown.color=shown.color or definition.color
    if definition.autoResourceColor and not shown.colorOverride and RWA.Resources then
      shown.color=RWA.Resources.COLORS[state.resource] or shown.color
    end
    shown.alpha=math.max(.5,tonumber(shown.alpha) or tonumber(definition.alpha) or 1)
    shown.grow=tonumber(shown.grow) or 1
    if shown.grow<=0 then shown.grow=1 end
    shown.blink=false
    return state,shown
  end
  state._placement=true
  state._elementNoIcon=nil
  state.available,state.unitAvailable,state.show,state.active=true,true,true,true
  state.unit=state.unit or source and source.unit or "player"
  if not state.name or state.name=="" then
    state.name=source and Rules.ReadableSource(source) or "Preview"
    state._placementSample=true
  end
  if not cache.fallbackIcon then cache.fallbackIcon=RWA.W.TexturePath("UI/image") end
  state.icon=placementIconPath(state.icon) or placementIconPath(definition.previewIcon) or cache.fallbackIcon
  if state.total==nil or tonumber(state.total)==nil or tonumber(state.total)<=0 then state.total=100 end
  if state.value==nil then state.value=75; state._placementSample=true end
  if state.percent==nil then state.percent=75 end
  if not cache.startTime then cache.startTime=now-12 end
  if not state.startTime then state.startTime=cache.startTime; state._placementSample=true end
  if not tonumber(state.stacks) or tonumber(state.stacks)<2 then state.stacks=3; state._placementSample=true end
  if kind=="aura" and (not observed or observed.present~=true) then
    state.progressType,state.duration,state.expirationTime="timed",10,now+8
    state.remaining,state.timed,state._placementSample=8,true,true
  elseif source and source.type=="status" and source.check=="combat" and inactive then
    state.progressType,state.value,state.startTime="static",12,cache.startTime
    state._placementSample=true
  elseif not state.progressType then state.progressType="static" end
  if state.progressType=="timed" then
    state.duration=tonumber(state.duration)
    if not state.duration or state.duration<=0 then state.duration=10 end
    state.expirationTime=tonumber(state.expirationTime)
    if not state.expirationTime or state.expirationTime<=now then state.expirationTime=now+8; state._placementSample=true end
    state.remaining=math.max(0,state.expirationTime-now)
  end
  if state.kittyIcons then
    local icons=cache.icons or {}; cache.icons=icons
    for i=1,6 do icons[i]=placementIconPath(state.kittyIcons[i]) or state.icon end
    state.kittyIcons=icons
  elseif kind=="kitty" then
    local icons=cache.icons or {}; cache.icons=icons
    for i=1,6 do icons[i]=state.icon end
    state.kittyIcons=icons
  end
  if definition.regionType=="threatmeter" and (type(state.threatRows)~="table" or #state.threatRows==0) then
    state.threatRows=RWA.Threat and RWA.Threat.PREVIEW
    state._placementSample=true
  end
  if definition.regionType=="aurabar" and RWA.Regions.Progress(state,now)<=0 then
    state._placementProgress=.65
    state._placementSample=true
  end
  if definition.regionType=="text" and RWA.Trim(RWA.Regions.FormatText(definition.text,state,now))=="" then
    state._placementText="Text preview"
    state._placementSample=true
  end
  shown.visible,shown.localVisible=true,true
  shown.color=shown.color or definition.color
  shown.alpha=math.max(.5,tonumber(shown.alpha) or tonumber(definition.alpha) or 1)
  shown.grow=tonumber(shown.grow) or 1
  if shown.grow<=0 then shown.grow=1 end
  shown.blink=false
  return state,shown
end
