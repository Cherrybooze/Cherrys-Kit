-- Recent.lua: "past second" tracking. Remembers your hits, damage and hits taken for the last
-- few seconds (COMBATMETER_DAMAGE) and gives them to auras as the "Past second" trigger, text
-- codes and a small API for custom code. Merges the WhiteCount addon (hits per second) into
-- rom weakauras; the default "Hits per second" aura replaces its window.
--
-- COMBATMETER_DAMAGE sets globals, not args: _source, _target, _damage, _type, _skill
-- (the same names WhiteCount and KittyCombo read). An auto attack has _skill == "ATTACK".

local RWA = RWA
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local R = {}
RWA.Recent = R
R.triggerLabel = "Past second"
R.MAX_WINDOW = 10 -- seconds of events kept
R.WINDOWS = { 0.5, 1, 2, 3, 5, 10 }
R.MEASURES = { "hits", "white", "skills", "damage", "taken", "takendamage", "event" }
R.MEASURE_LABELS = {
  hits = "My hits",
  white = "My auto attacks",
  skills = "My skill hits",
  damage = "My damage",
  taken = "Hits on me",
  takendamage = "Damage on me",
  event = "Game event",
}
R.SHOW = { "combat", "active", "always" }
R.SHOW_LABELS = { combat = "In combat", active = "When above 0", always = "Always" }

-- Which measures sum damage instead of counting events.
local SUMS = { damage = "hits", takendamage = "taken" }
local ATTACK = "ATTACK"

local function now()
  return RWA.Now()
end

local playerName
local function me()
  if not playerName and UnitName then
    local ok, name = pcall(UnitName, "player")
    playerName = ok and name or nil
  end
  return playerName
end

local function inCombat()
  if not GetPlayerCombatState then
    return false
  end
  local ok, state = pcall(GetPlayerCombatState)
  return ok and state ~= nil and state ~= false and state ~= 0
end

---------------------------------------------------------------------------
-- Event log: one list per kind ("hits", "taken", "ev:<EVENT>", or a custom key), oldest first.
-- Each entry: { t = time, n = amount, skill = lowercased skill name, white = true for auto attacks }
---------------------------------------------------------------------------

local logs = {}
R.logs = logs

local function prune(list, t)
  local cut = t - R.MAX_WINDOW
  local drop = 0
  while list[drop + 1] and list[drop + 1].t < cut do
    drop = drop + 1
  end
  if drop > 0 then
    local n = #list
    for i = 1, n - drop do
      list[i] = list[i + drop]
    end
    for i = n - drop + 1, n do
      list[i] = nil
    end
  end
end

-- Adds an entry to a log. Custom code can count its own things: RWA.Recent.Add("mykey", 1)
function R.Add(kind, amount, skill, white)
  local t = now()
  local list = logs[kind]
  if not list then
    list = {}
    logs[kind] = list
  end
  prune(list, t)
  list[#list + 1] = { t = t, n = tonumber(amount) or 1, skill = skill and string.lower(skill) or nil, white = white }
  if RWA.MarkDirty then
    RWA.MarkDirty()
  end
end

local function skillSet(text)
  if not text or text == "" then
    return nil
  end
  local set, any = {}, false
  for part in string.gmatch(text, "[^,]+") do
    part = string.lower(RWA.Trim(part))
    if part ~= "" then
      set[part] = true
      any = true
    end
  end
  return any and set or nil
end
R.SkillSet = skillSet

-- Count (or, with sum = true, total amount) of entries in the last `window` seconds.
-- filter: nil, "white", "skills", or a set of lowercased skill names.
local function tally(kind, window, filter, sum)
  local list = logs[kind]
  if not list then
    return 0
  end
  local t = now()
  local from = t - (tonumber(window) or 1)
  local total = 0
  for i = #list, 1, -1 do
    local e = list[i]
    if e.t < from then
      break
    end
    local ok = true
    if filter == "white" then
      ok = e.white
    elseif filter == "skills" then
      ok = not e.white
    elseif type(filter) == "table" then
      ok = e.skill ~= nil and filter[e.skill] == true
    end
    if ok then
      total = total + (sum and e.n or 1)
    end
  end
  return total
end

-- Hits per second from the time between hits, so it has fractions (3.47/s) instead of
-- whole counts per window. With n hits in the window, span from first to last:
-- rate = (n - 1) / span. Once the next hit is late, the gap counts too, so the rate
-- falls off smoothly when you stop. Fewer than 2 hits (or 2 at the same moment): n / window.
local function smoothRate(kind, window, filter)
  local list = logs[kind]
  window = tonumber(window) or 1
  if not list then
    return 0
  end
  local t = now()
  local from = t - window
  local n, first, last = 0, nil, nil
  for i = #list, 1, -1 do
    local e = list[i]
    if e.t < from then
      break
    end
    local ok = true
    if filter == "white" then
      ok = e.white
    elseif filter == "skills" then
      ok = not e.white
    elseif type(filter) == "table" then
      ok = e.skill ~= nil and filter[e.skill] == true
    end
    if ok then
      n = n + 1
      last = last or e.t
      first = e.t
    end
  end
  local span = n >= 2 and (last - first) or 0
  if span < 0.05 then
    return n / window
  end
  local interval = span / (n - 1)
  local late = math.max(0, (t - last) - interval)
  return (n - 1) / (span + late)
end
R.SmoothRate = smoothRate

-- Turns a measure into (log kind, filter, sum).
local function source(measure, skills, eventName)
  measure = measure or "hits"
  if measure == "event" then
    return "ev:" .. string.upper(eventName or ""), nil, false
  end
  local kind = SUMS[measure] or measure
  local filter
  if measure == "white" then
    kind, filter = "hits", "white"
  elseif measure == "skills" then
    kind, filter = "hits", "skills"
  end
  if type(skills) == "string" then
    skills = skillSet(skills)
  end
  if skills and kind == "hits" then
    filter = skills
  end
  -- any other measure is a custom key added with RWA.Recent.Add, counted as is
  return kind, filter, SUMS[measure] ~= nil
end

-- Public API, also for custom triggers:
--   RWA.Recent.Count("hits", 1)            your hits in the past second
--   RWA.Recent.Count("white", 2)           auto attacks in the past 2 s
--   RWA.Recent.Count("damage", 1)          damage you did in the past second
--   RWA.Recent.Count("hits", 1, "Slash, Thunder")   only those skills
--   RWA.Recent.Count("mykey", 3)           things you added with RWA.Recent.Add("mykey")
--   RWA.Recent.Rate(measure, window)       per second
--   RWA.Recent.Fight(measure)              count, seconds, per second for the current (or last) fight
function R.Count(measure, window, skills)
  local kind, filter, sum = source(measure, skills)
  return tally(kind, window or 1, filter, sum)
end

-- Per second: damage measures = total / window; counts = from the time between hits (fractions).
function R.Rate(measure, window, skills)
  window = tonumber(window) or 1
  local kind, filter, sum = source(measure, skills)
  if sum then
    return tally(kind, window, filter, true) / window
  end
  return smoothRate(kind, window, filter)
end

---------------------------------------------------------------------------
-- Fight totals (what WhiteCount showed): counted from the first event after you enter combat
-- until combat ends; the last fight's numbers stay until the next one starts.
---------------------------------------------------------------------------

local fight = { totals = {}, first = {}, last = {}, start = nil, stop = nil }
R.fight = fight

local function fightAdd(key, n)
  fight.totals[key] = (fight.totals[key] or 0) + n
  fight.last[key] = now()
  fight.first[key] = fight.first[key] or fight.last[key]
end

local function fightBegin(t)
  if fight.start and not fight.stop then
    return
  end
  fight.totals, fight.first, fight.last = {}, {}, {}
  fight.start, fight.stop = t, nil
end

function R.ResetFight()
  fight.totals, fight.first, fight.last = {}, {}, {}
  fight.start, fight.stop = nil, nil
end

local FIGHT_KEYS = {
  hits = "hits", white = "white", skills = "skills", damage = "damage",
  taken = "taken", takendamage = "takendamage",
}

function R.Fight(measure)
  local key = FIGHT_KEYS[measure or "hits"] or "hits"
  local count = fight.totals[key] or 0
  if not fight.start then
    return 0, 0, 0
  end
  local seconds = (fight.stop or now()) - fight.start
  -- the first hit starts the clock, so n hits make n - 1 gaps (damage: all of it)
  local per = 0
  if SUMS[measure or "hits"] then
    per = count / math.max(1, seconds)
  elseif count > 1 then
    -- same as the window rate: gaps between hits, plus any lateness after the last one
    local span = fight.last[key] - fight.first[key]
    if span > 0.05 then
      local interval = span / (count - 1)
      local late = math.max(0, ((fight.stop or now()) - fight.last[key]) - interval)
      per = (count - 1) / (span + late)
    end
  end
  return count, seconds, per
end

---------------------------------------------------------------------------
-- Game events
---------------------------------------------------------------------------

local function global(name)
  return rawget(_G, name)
end

function R.OnDamage()
  local src, target = global("_source"), global("_target")
  local damage = tonumber(global("_damage")) or 0
  local skill = global("_skill")
  local name = me()
  if not name then
    return
  end
  local t = now()
  if src == name then
    local white = skill == ATTACK
    R.Add("hits", damage, skill, white)
    fightBegin(t)
    fightAdd("hits", 1)
    fightAdd(white and "white" or "skills", 1)
    fightAdd("damage", damage)
  end
  if target == name then
    R.Add("taken", damage, skill, skill == ATTACK)
    fightBegin(t)
    fightAdd("taken", 1)
    fightAdd("takendamage", damage)
  end
end

RWA.On("COMBATMETER_DAMAGE", function()
  R.OnDamage()
end)

-- "Game event" measure: counts any client event; the event is registered the first time an aura asks.
local watched = {}
function R.WatchEvent(eventName)
  eventName = string.upper(eventName or "")
  if eventName == "" or watched[eventName] then
    return
  end
  watched[eventName] = true
  RWA.On(eventName, function()
    R.Add("ev:" .. eventName, 1)
  end)
end

-- Ends the fight when combat ends (checked a few times a second).
local nextCheck = 0
RWA.SetUpdater("recent", function(t)
  if t < nextCheck then
    return
  end
  nextCheck = t + 0.25
  if fight.start and not fight.stop and not inCombat() then
    -- out of combat and nothing landed for a moment: the fight is over
    local last = 0
    for _, kind in ipairs({ "hits", "taken" }) do
      local list = logs[kind]
      if list and list[#list] then
        last = math.max(last, list[#list].t)
      end
    end
    if t - last > 1 then
      fight.stop = math.max(last, fight.start)
    end
  end
end)

---------------------------------------------------------------------------
-- Trigger: { type = "recent", measure = "hits"|..., window = 1, showOn = "combat"|"active"|"always",
--            skills = "Slash, Thunder" (hits measures), event = "EVENT_NAME" (event measure) }
-- State: value = count (or damage) in the window, total = the highest value this fight (for bars),
-- perSecond, fightCount, fightTime, fightRate.
---------------------------------------------------------------------------

local peaks = setmetatable({}, { __mode = "k" })

Triggers.evaluators.recent = function(trigger, now, env, into)
  local measure = trigger.measure or "hits"
  local window = tonumber(trigger.window) or 1
  if measure == "event" then
    R.WatchEvent(trigger.event)
  end
  local kind, filter, sum = source(measure, trigger.skills, trigger.event)
  local value = tally(kind, window, filter, sum)
  local peak = peaks[trigger]
  if not peak or (fight.start and peak.start ~= fight.start) then
    peak = { start = fight.start, value = 0 }
    peaks[trigger] = peak
  end
  if value > peak.value then
    peak.value = value
  end
  local count, seconds, per = R.Fight(measure)
  local state = Triggers.Fresh(into)
  state.name = R.MEASURE_LABELS[measure] or measure
  state.progressType, state.value, state.total = "static", value, math.max(1, peak.value)
  state.perSecond = sum and (value / window) or smoothRate(kind, window, filter)
  state.fightCount, state.fightTime, state.fightRate = count, seconds, per
  state.percent = value / state.total * 100
  local showOn = trigger.showOn or "combat"
  if showOn == "always" then
    state.show = true
  elseif showOn == "active" then
    state.show = value > 0
  else
    state.show = value > 0 or inCombat()
  end
  return state
end

---------------------------------------------------------------------------
-- Text codes for Past second triggers (any display text):
--   %v     count in the window (already in Regions.lua)
--   %rate  per second over the window, two decimals (counts: from the time between hits)
--   %fight count this fight      %ft  fight time (12.3s)      %avg  fight per second (2.35)
---------------------------------------------------------------------------

local function fmt1(x)
  return string.format("%.1f", x or 0)
end

-- Only Past second states (they carry fightCount) fill these codes.
local CODES = {
  rate = function(s)
    return s.fightCount and s.perSecond and string.format("%.2f", s.perSecond)
  end,
  fight = function(s)
    return s.fightCount and tostring(s.fightCount)
  end,
  ft = function(s)
    return s.fightCount and s.fightTime and (fmt1(s.fightTime) .. "s")
  end,
  avg = function(s)
    return s.fightCount and s.fightRate and string.format("%.2f", s.fightRate)
  end,
}
R.CODES = CODES

-- Regions.lua is re-run on Reload UI before this file, so its fresh code list gets them again.
-- (They used to be swapped in with string.gsub and a new function on every draw.)
for word, code in pairs(CODES) do
  Regions.CODES[word] = code
end

---------------------------------------------------------------------------
-- Default aura "Hits per second" (WhiteCount): added once, also to saved auras.
---------------------------------------------------------------------------

R.EXAMPLE_ID = "Hits per second"
R.EXAMPLE = {
  id = R.EXAMPLE_ID,
  desc = "Auto attacks per second (cap 4 per weapon), and this fight's average (from WhiteCount)",
  regionType = "text",
  x = 0,
  y = -230,
  text = "%rate hits/s",
  fontSize = 20,
  color = { 1, 0.85, 0.35, 1 },
  schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
  sources = { { id = "s1", type = "recent", measure = "white", window = 3, showOn = "combat" } },
  rules = {
    { id = "r1", name = "Show in combat", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } },
    -- Green near the cap of one weapon (4/s); for dual wield, change this to 7.6.
    { id = "r2", name = "Near cap", when = { mode = "all", checks = {
      { id = "c2", sourceId = "s1", field = "perSecond", op = ">=", value = 3.8 } } },
      set = { color = { 0.4, 1, 0.4, 1 } } },
  },
  elements = { { type = "text", side = "BOTTOM", text = "%fight hits in %ft = %avg/s", size = 13 } },
  animation = { start = "fade", main = "none", finish = "fade" },
}
RWA.ApplyDefaultPosition(R.EXAMPLE)

-- 0.9.11: the first version showed whole hits per 1 s window; switch saved copies that were
-- not edited to the auto attack rate with decimals.
function R.UpgradeExample()
  local s = RWA_DB and RWA_DB.settings
  if not s or s.hitsPerSecondV2 then
    return
  end
  s.hitsPerSecondV2 = true
  local a = RWA_DB.auras[R.EXAMPLE_ID]
  local t = a and a.triggers and a.triggers[1]
  if not (t and t.type == "recent" and a.text == "%v hits/s") then
    return
  end
  local new = R.EXAMPLE
  a.text = new.text
  a.desc = new.desc
  t.measure, t.window = new.sources[1].measure, new.sources[1].window
  local c = a.conditions and a.conditions[1]
  if c and c.var == "value" and c.op == ">=" and c.value == 3 then
    a.conditions[1] = { trigger = 1, var = "perSecond", op = ">=", value = 3.8, set = { color = { 0.4, 1, 0.4, 1 } } }
  end
  if Triggers.Reset then
    Triggers.Reset(t)
  end
end

function R.AddExample()
  local s = RWA_DB and RWA_DB.settings
  if not s or s.hitsPerSecondAdded then
    R.UpgradeExample()
    return
  end
  s.hitsPerSecondV2 = true
  s.hitsPerSecondAdded = true
  if RWA_DB.auras[R.EXAMPLE_ID] then
    return
  end
  local copy = RWA.CopyTable(R.EXAMPLE)
  RWA.ApplyAuraDefaults(copy)
  RWA_DB.auras[copy.id] = copy
  table.insert(RWA_DB.order, copy.id)
end

-- Runs before Engine.lua's RWA_READY handler (this file loads first), so the aura loads with the rest.
RWA.On("RWA_READY", function()
  R.AddExample()
end)

---------------------------------------------------------------------------
-- Editor rows (called by Options.lua inside the Trigger section, same env as KittyTracker.lua,
-- see docs/KITTYTRACKER_HOOKS.md; wrap everything in env.group)
--   Row 1: Count [measure v] [Past 1 s v]
--   Row 2: Show  [In combat v] [skills / event name field]
---------------------------------------------------------------------------

function R.WindowLabel(v)
  return "Past " .. (v == 0.5 and "0.5" or tostring(v)) .. " s"
end

-- What the list's "Tracks" column says.
function R.Describe(t)
  local what = R.MEASURE_LABELS[t.measure or "hits"] or "?"
  if t.measure == "event" then
    what = (t.event and t.event ~= "") and t.event or "game event"
  end
  return string.lower(what) .. " in " .. string.lower(R.WindowLabel(tonumber(t.window) or 1))
end

function R.BuildOptions(env)
  local r1, r2 = env.rows[1], env.rows[2]
  local WX, g = env.WX, env.group
  local function t()
    local trigger = env.trigger1()
    if trigger.type == "recent" and trigger.measure == nil then
      trigger.measure, trigger.window, trigger.showOn = "hits", 1, "combat"
    end
    return trigger
  end
  if not R.describeWrapped and RWA.DescribeTarget then
    R.describeWrapped = true
    local base = RWA.DescribeTarget
    RWA.DescribeTarget = function(data)
      local first = data.triggers and data.triggers[1]
      if first and first.type == "recent" then
        return R.Describe(first)
      end
      return base(data)
    end
  end

  g(env.L("Count", r1))
  g(env.cycle(WX, r1, 136, R.MEASURES, function(v)
    return R.MEASURE_LABELS[v] or v
  end, function()
    return t().measure or "hits"
  end, function(v)
    local trigger = t()
    trigger.measure = v
    Triggers.Reset(trigger)
  end, "What to count"))
  g(env.cycle(WX + 142, r1, 108, R.WINDOWS, R.WindowLabel, function()
    return tonumber(t().window) or 1
  end, function(v)
    t().window = v
  end, "Time window"))

  g(env.L("Show", r2))
  g(env.cycle(WX, r2, 108, R.SHOW, function(v)
    return R.SHOW_LABELS[v] or v
  end, function()
    return t().showOn or "combat"
  end, function(v)
    t().showOn = v
  end, "Show"))
  g(env.field(WX + 114, r2, 136, function()
    local trigger = t()
    if trigger.measure == "event" then
      return trigger.event or ""
    end
    return trigger.skills or ""
  end, function(text)
    local trigger = t()
    if trigger.type ~= "recent" then
      return
    end
    text = RWA.Trim(text or "")
    if trigger.measure == "event" then
      trigger.event = text ~= "" and string.upper(text) or nil
    else
      trigger.skills = text ~= "" and text or nil
    end
  end))
end

---------------------------------------------------------------------------
-- /rwa hits: what was counted (checks COMBATMETER_DAMAGE in game). /rwa hits reset: new fight.
---------------------------------------------------------------------------

function R.Probe(arg)
  if arg == "reset" then
    R.ResetFight()
    RWA.Print("hits per second: fight reset")
    return
  end
  local count, seconds, per = R.Fight("hits")
  RWA.Print(string.format("[hits] past 1 s: %d hits (%d auto attacks), %d damage; taken %d",
    R.Count("hits", 1), R.Count("white", 1), R.Count("damage", 1), R.Count("taken", 1)))
  RWA.Print(string.format("[hits] this fight: %d hits in %.1f s = %.2f/s, %d damage",
    count, seconds, per, (R.Fight("damage"))))
  local last = logs.hits and logs.hits[#logs.hits]
  if last then
    RWA.Print(string.format("[hits] last: skill %s, %d damage, %.1f s ago",
      tostring(last.skill), last.n, now() - last.t))
  else
    RWA.Print("[hits] nothing counted yet: hit something, then type /rwa hits again")
  end
end

local baseSlash = RWA.SlashCommand
RWA.SlashCommand = function(msg)
  local cmd, rest = string.match(msg or "", "^(%S*)%s*(.-)$")
  if string.lower(cmd or "") == "hits" then
    R.Probe(string.lower(rest or ""))
    return
  end
  return baseSlash(msg)
end
