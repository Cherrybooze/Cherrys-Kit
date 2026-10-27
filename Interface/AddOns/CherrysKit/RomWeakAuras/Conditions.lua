-- Condition rules and their actions. Saved rules remain ordinary tables, so old
-- color/alpha conditions and imported rules with several actions still work.
local RWA = RWA
local C = {}
RWA.Conditions = C

local ACTIONS = { "hide", "show", "sound", "grow", "blink", "overlayIcon", "color" }
local OPS = { ["<"] = true, ["<="] = true, [">"] = true, [">="] = true,
  ["="] = true, ["=="] = true, ["~="] = true, ["!="] = true }

function C.GetAction(cond)
  local set = type(cond) == "table" and type(cond.set) == "table" and cond.set or {}
  for _, action in ipairs(ACTIONS) do
    if set[action] ~= nil and set[action] ~= false then return action end
  end
  return "color"
end

function C.SetAction(cond, action)
  local previous = type(cond.set) == "table" and cond.set or {}
  local set = {}
  -- Keep extension fields from shared rules while replacing the selected action.
  for key, value in pairs(previous) do set[key] = value end
  for _, name in ipairs(ACTIONS) do set[name] = nil end
  set.alpha = nil -- legacy opacity is also replaced when choosing a new action
  if action == "hide" or action == "show" or action == "blink" then
    set[action] = true
  elseif action == "grow" then
    set.grow = tonumber(previous.grow) or 1.25
  elseif action == "sound" then
    set.sound = type(previous.sound) == "string" and previous.sound ~= "" and previous.sound or "AirHorn"
  elseif action == "overlayIcon" then
    set.overlayIcon = type(previous.overlayIcon) == "string" and previous.overlayIcon ~= ""
      and previous.overlayIcon or "exclamation-mark"
  else
    set.color = type(previous.color) == "table" and RWA.CopyTable(previous.color) or { 0.9, 0.15, 0.15, 1 }
  end
  cond.set = set
  return cond
end

function C.New(action)
  return C.SetAction({ trigger = 1, var = "remaining", op = "<", value = 3 }, action)
end

function C.UnitAvailable(trigger)
  local unit = trigger.unit or "player"
  if unit == "player" then return true end
  if type(UnitExists) ~= "function" then return false end
  local ok, exists = pcall(UnitExists, unit)
  return ok and exists ~= nil and exists ~= false and exists ~= 0
end

local function remainingRule(cond)
  return cond.var == "remaining" and OPS[cond.op] and tonumber(cond.value) ~= nil
end

function C.Match(cond, state, now)
  if type(cond) ~= "table" or not state then return false end
  local value
  if cond.var == "remaining" then
    if not remainingRule(cond) or state.conditionAvailable == false or state.conditionBlocked then
      return false
    end
    if state.conditionMissing then return true end
    if state.progressType == "timed" and state.expirationTime then
      value = math.max(0, state.expirationTime - now)
    end
  elseif cond.var == "show" then
    value = state.show and 1 or 0
  else
    value = state[cond.var]
  end
  return RWA.Triggers.Compare(value, cond.op, cond.value)
end

-- Time-left rules replace only their own buff trigger's visibility. Read the
-- actual buff even when showOn="missing" or a separate remaining filter hides it.
function C.EvaluateTrigger(trigger, index, conditions, now, env)
  local rules = {}
  if (trigger.type or "aura") == "aura" then
    for _, cond in ipairs(conditions or {}) do
      if type(cond) == "table" and (tonumber(cond.trigger) or 1) == index and remainingRule(cond) then
        rules[#rules + 1] = cond
      end
    end
  end
  if #rules == 0 then return RWA.Triggers.Evaluate(trigger, now, env) end
  local actual = {}
  for key, value in pairs(trigger) do actual[key] = value end
  actual.showOn, actual.remainingOp, actual.remaining = "always", nil, nil
  local state = RWA.Triggers.Evaluate(actual, now, env)
  state.conditionAvailable = state.show and C.UnitAvailable(trigger) or false
  state.conditionMissing = (state.matchCount or 0) == 0
  -- A present buff rejected by the trigger's stacks filter is not missing.
  state.conditionBlocked = not state.conditionMissing and state.progressType == "static" and state.value == 0
  state.show = false
  for _, cond in ipairs(rules) do
    if C.Match(cond, state, now) then state.show = true end
  end
  return state
end

function C.Effects(data, states, now)
  local effects = { color = data.color, alpha = tonumber(data.alpha) or 1,
    grow = 1, matches = {}, showTriggers = {} }
  for _, cond in ipairs(data.conditions or {}) do
    if type(cond) == "table" then
      local index = tonumber(cond.trigger) or 1
      local matched = C.Match(cond, states[index], now)
      effects.matches[cond] = matched
      local set = matched and type(cond.set) == "table" and cond.set
      if set then
        if type(set.color) == "table" then effects.color = set.color end
        if tonumber(set.alpha) then effects.alpha = tonumber(set.alpha) end
        if set.hide == true then effects.hide = true end
        if set.show == true and data.triggers[index] and C.UnitAvailable(data.triggers[index]) then
          effects.showTriggers[index] = true
        end
        local grow = set.grow == true and 1.25 or tonumber(set.grow)
        if grow and grow > 0 and grow < math.huge then effects.grow = grow end
        if set.blink == true then effects.blink = true end
        if type(set.overlayIcon) == "string" and set.overlayIcon ~= "" then
          effects.overlayIcon = set.overlayIcon
        end
      end
    end
  end
  return effects
end
