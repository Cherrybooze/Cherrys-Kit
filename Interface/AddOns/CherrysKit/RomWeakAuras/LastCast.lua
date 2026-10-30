-- LastCast.lua: the "Last cast" trigger. Remembers the last spells a unit (normally your target)
-- cast, and shows the newest with the time since it started. Forgotten when a new fight starts.
--
-- Two sources, so instant spells count too:
--   * UnitCastingTime(unit) -> name, total, elapsed, checked ten times a second (cast bars)
--   * COMBATMETER_DAMAGE with _source == the unit's name and a skill other than "ATTACK"
-- Works on its own; Cherry's KittyCombo can read RWA.LastCast.Get("target") (and RWA reads
-- Kitty.lastTargetCast when KittyCombo saw a cast first).

local RWA = RWA
local Triggers = RWA.Triggers

local LC = {}
RWA.LastCast = LC
LC.triggerLabel = "Last cast"
LC.UNITS = { "target", "targettarget", "player" }
LC.UNIT_LABELS = { target = "Target", targettarget = "Target's target", player = "Me" }
LC.SHOW = { "seen", "always" }
LC.SHOW_LABELS = { seen = "Once it casts", always = "Always" }
LC.KEEP = 10 -- casts remembered per unit
LC.STUTTER = 0.1 -- a cast bar shorter than this is not counted yet (same as KittyCombo)

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c = pcall(fn, ...)
  if ok then
    return a, b, c
  end
end

-- Who a unit is: GUID when the client has it, else the name.
local function who(unit)
  local guid = call(UnitGUID, unit)
  if guid and guid ~= "" and guid ~= 0 then
    return tostring(guid)
  end
  local name = call(UnitName, unit)
  return name and ("n:" .. name) or nil
end

local function inCombat()
  local state = call(GetPlayerCombatState)
  return state ~= nil and state ~= false and state ~= 0
end

---------------------------------------------------------------------------
-- Memory: casts[unitKey] = { { name, t, castTime }, ... } newest last
---------------------------------------------------------------------------

local casts = {}
LC.casts = casts
local bars = {} -- [unit] = { key, name, start } the cast bar seen last frame

function LC.Record(key, name, t, castTime)
  if not key or type(name) ~= "string" or name == "" then
    return
  end
  local list = casts[key]
  if not list then
    list = {}
    casts[key] = list
  end
  local last = list[#list]
  -- the same cast seen twice (cast bar, then its damage): keep the first
  if last and last.name == name and t - last.t < (last.castTime or 0) + 0.5 then
    return
  end
  list[#list + 1] = { name = name, t = t, castTime = castTime }
  if #list > LC.KEEP then
    table.remove(list, 1)
  end
  if RWA.MarkDirty then
    RWA.MarkDirty()
  end
end

-- Forgets casts older than `since` (all when nil).
function LC.Reset(since)
  for k, list in pairs(casts) do
    for i = #list, 1, -1 do
      if not since or list[i].t < since then
        table.remove(list, i)
      end
    end
    if #list == 0 then
      casts[k] = nil
    end
  end
  if not since then
    for k in pairs(bars) do
      bars[k] = nil
    end
  end
end

-- Newest cast of a unit, optionally only names in `set` (lowercased): name, seconds since, cast time.
function LC.Get(unit, set)
  local list = casts[who(unit or "target") or ""]
  if not list then
    return nil
  end
  for i = #list, 1, -1 do
    local c = list[i]
    if not set or set[string.lower(c.name)] then
      return c.name, RWA.Now() - c.t, c.castTime, c.t
    end
  end
end

local function checkBar(unit, now)
  local name, total, elapsed = call(UnitCastingTime, unit)
  local key = who(unit)
  local bar = bars[unit]
  if type(name) ~= "string" or name == "" or not key then
    bars[unit] = nil
    return
  end
  elapsed = tonumber(elapsed) or 0
  local start = now - elapsed
  -- a new cast: other unit, other spell, or the bar restarted
  if not bar or bar.key ~= key or bar.name ~= name or start > bar.start + 0.2 then
    bar = { key = key, name = name, start = start, counted = false }
    bars[unit] = bar
  end
  if not bar.counted and elapsed > LC.STUTTER then
    bar.counted = true
    LC.Record(key, name, start, tonumber(total))
  end
end

-- KittyCombo noticed a target cast (its own poll): count it too.
local kittySeen
local function checkKitty(now)
  local k = rawget(_G, "Kitty")
  local name = type(k) == "table" and k.lastTargetCast or nil
  if name and name ~= kittySeen then
    kittySeen = name
    LC.Record(who("target"), name, now)
  end
end

local wasInCombat = false
-- Ten looks a second are enough: the game's own elapsed time dates each cast.
local CHECK_EVERY, nextCheck = 0.1, 0
RWA.SetUpdater("lastcast", function(now)
  if now < nextCheck then return end
  nextCheck = now + CHECK_EVERY
  local fighting = inCombat()
  if fighting and not wasInCombat then
    LC.Reset(now - 2) -- a new fight: forget the last one's casts (keep the one that pulled)
  end
  wasInCombat = fighting
  for _, unit in ipairs(LC.UNITS) do
    checkBar(unit, now)
  end
  checkKitty(now)
end)

-- Instant spells show up only as damage. Match the attacker by name against the watched units.
RWA.On("COMBATMETER_DAMAGE", function()
  local src, skill = rawget(_G, "_source"), rawget(_G, "_skill")
  if type(src) ~= "string" or type(skill) ~= "string" or skill == "" or skill == "ATTACK" then
    return
  end
  local now = RWA.Now()
  for _, unit in ipairs(LC.UNITS) do
    if unit ~= "player" and call(UnitName, unit) == src then
      LC.Record(who(unit), skill, now)
    end
  end
end)

---------------------------------------------------------------------------
-- Trigger: { type = "lastcast", unit = "target", showOn = "seen"|"always", names = "Fireball, Heal" }
-- State: name = the spell, startTime = when it started (%e counts up), value = seconds since,
-- casting = true while its cast bar is still up.
---------------------------------------------------------------------------

local sets = setmetatable({}, { __mode = "k" })

Triggers.evaluators.lastcast = function(trigger, now, env, into)
  local unit = trigger.unit or "target"
  local set = sets[trigger]
  if set == nil then
    set = RWA.Recent and RWA.Recent.SkillSet and RWA.Recent.SkillSet(trigger.names) or false
    sets[trigger] = set
  end
  local name, ago, castTime, t = LC.Get(unit, set or nil)
  local state = Triggers.Fresh(into)
  state.unit, state.progressType, state.value, state.total = unit, "static", 0, 1
  if name then
    state.name = name
    state.startTime = t
    state.value = math.floor(ago * 10 + 0.5) / 10
    state.castTime = castTime
    local bar = bars[unit]
    state.casting = (bar ~= nil and bar.name == name) and 1 or 0 -- a number, so conditions can test it
    state.show = true
  else
    state.name = ""
    state.show = (trigger.showOn or "seen") == "always"
  end
  return state
end

---------------------------------------------------------------------------
-- Default aura "Target's last cast": added once, also to saved auras.
---------------------------------------------------------------------------

LC.EXAMPLE_ID = "Target's last cast"
LC.EXAMPLE = {
  id = LC.EXAMPLE_ID,
  desc = "The last spell your target cast and how long ago; forgotten each new fight",
  regionType = "text",
  x = 0,
  y = -290,
  text = "%n",
  fontSize = 18,
  color = { 1, 0.6, 0.25, 1 },
  schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
  sources = { { id = "s1", type = "lastcast", unit = "target", showOn = "seen" } },
  rules = {
    { id = "r1", name = "Show last cast", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } },
    { id = "r2", name = "Currently casting", when = { mode = "all", checks = {
      { id = "c2", sourceId = "s1", field = "casting", op = "==", value = 1 } } },
      set = { color = { 1, 0.25, 0.25, 1 } } },
  },
  elements = { { type = "text", side = "BOTTOM", text = "%e ago", size = 13 } },
  animation = { start = "fade", main = "none", finish = "fade" },
}
RWA.ApplyDefaultPosition(LC.EXAMPLE)

function LC.AddExample()
  local s = RWA_DB and RWA_DB.settings
  if not s or s.lastCastAdded then
    return
  end
  s.lastCastAdded = true
  if RWA_DB.auras[LC.EXAMPLE_ID] then
    return
  end
  local copy = RWA.CopyTable(LC.EXAMPLE)
  RWA.ApplyAuraDefaults(copy)
  RWA_DB.auras[copy.id] = copy
  table.insert(RWA_DB.order, copy.id)
end

-- Runs before Engine.lua's RWA_READY handler (this file loads first), so the aura loads with the rest.
RWA.On("RWA_READY", function()
  LC.AddExample()
end)

---------------------------------------------------------------------------
-- Editor rows (same env as KittyTracker.lua / Recent.lua; wrap everything in env.group)
--   Row 1: Unit  [Target v] [Once it casts v]
--   Row 2: Only  [cast names field, empty = any]
---------------------------------------------------------------------------

function LC.Describe(t)
  local unit = LC.UNIT_LABELS[t.unit or "target"] or t.unit or "target"
  local text = "last cast of " .. string.lower(unit)
  if t.names and t.names ~= "" then
    text = text .. ": " .. t.names
  end
  return text
end

function LC.BuildOptions(env)
  local r1, r2 = env.rows[1], env.rows[2]
  local WX, g = env.WX, env.group
  local function t()
    local trigger = env.trigger1()
    if trigger.type == "lastcast" and trigger.unit == nil then
      trigger.unit, trigger.showOn = "target", "seen"
    end
    return trigger
  end
  if not LC.describeWrapped and RWA.DescribeTarget then
    LC.describeWrapped = true
    local base = RWA.DescribeTarget
    RWA.DescribeTarget = function(data)
      local first = data.triggers and data.triggers[1]
      if first and first.type == "lastcast" then
        return LC.Describe(first)
      end
      return base(data)
    end
  end

  g(env.L("Unit", r1))
  g(env.cycle(WX, r1, 122, LC.UNITS, function(v)
    return LC.UNIT_LABELS[v] or v
  end, function()
    return t().unit or "target"
  end, function(v)
    t().unit = v
  end, "Whose casts"))
  g(env.cycle(WX + 128, r1, 122, LC.SHOW, function(v)
    return LC.SHOW_LABELS[v] or v
  end, function()
    return t().showOn or "seen"
  end, function(v)
    t().showOn = v
  end, "Show"))

  g(env.L("Only casts", r2))
  g(env.field(WX, r2, 250, function()
    return t().names or ""
  end, function(text)
    local trigger = t()
    if trigger.type ~= "lastcast" then
      return
    end
    text = RWA.Trim(text or "")
    trigger.names = text ~= "" and text or nil
    sets[trigger] = nil
  end))
end

---------------------------------------------------------------------------
-- /rwa lastcast: what was seen on your target (checks UnitCastingTime and the damage names in game).
---------------------------------------------------------------------------

function LC.Probe()
  local key = who("target")
  if not key then
    RWA.Print("[lastcast] no target")
    return
  end
  local name, total, elapsed = call(UnitCastingTime, "target")
  RWA.Print("[lastcast] target " .. tostring(call(UnitName, "target")) .. ", casting now: "
    .. tostring(name) .. " (" .. tostring(total) .. " s, " .. tostring(elapsed) .. " done)")
  local list = casts[key]
  if not list or #list == 0 then
    RWA.Print("[lastcast] nothing seen yet this fight")
    return
  end
  for i = #list, math.max(1, #list - 4), -1 do
    local c = list[i]
    RWA.Print(string.format("[lastcast] %s, %.1f s ago", c.name, RWA.Now() - c.t))
  end
end

local baseSlash = RWA.SlashCommand
RWA.SlashCommand = function(msg)
  local cmd = string.match(msg or "", "^(%S*)")
  if string.lower(cmd or "") == "lastcast" then
    LC.Probe()
    return
  end
  return baseSlash(msg)
end
