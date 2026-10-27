-- CastBars.lua: cast bar auras. Adds an icon to the "Casting" status trigger (your own spells:
-- from your spellbook; anyone else's: a generic cast icon), an optional fill-up bar
-- (trigger.fillUp: the bar grows while the cast runs, like the game's cast bar), and two default
-- auras, "My cast" and "Target's cast" (icon, bar, spell name and time left).
-- pbInfo's "Hide default castbar" option (on by default) hides the game's own cast bar.

local RWA = RWA
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local CB = {}
RWA.CastBars = CB
CB.OTHER_ICON = "interrupt" -- Media/Textures/interrupt.tga, for spells not in your spellbook

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local ok, a, b, c = pcall(fn, ...)
  if ok then
    return a, b, c
  end
end

-- Icon of one of your own skills by name (nil when it is not in your spellbook).
local icons = {}
function CB.SkillIcon(name)
  if not name or name == "" then
    return nil
  end
  local cached = icons[name]
  if cached ~= nil then
    return cached or nil
  end
  local page, slot
  if Triggers.FindSkill then
    page, slot = Triggers.FindSkill(name)
  end
  local icon
  if page then
    local _, path = call(rawget(_G, "GetSkillDetail"), page, slot)
    icon = type(path) == "string" and path ~= "" and path or nil
  end
  icons[name] = icon or false
  return icon
end

-- The status evaluator is built by Triggers.lua; add the icon and fill-up flag to cast states.
-- Wrapped once per load (Reload UI builds a new Triggers table, so this wraps the new one).
local baseStatus = Triggers.evaluators.status
Triggers.evaluators.status = function(trigger, now, ...)
  local state = baseStatus(trigger, now, ...)
  if trigger.check == "cast" and state and state.show then
    local unit = trigger.unit or "player"
    state.icon = (unit == "player" and CB.SkillIcon(state.name)) or RWA.W.TexturePath(CB.OTHER_ICON)
    state.fillUp = trigger.fillUp and true or nil
  end
  return state
end

-- Fill-up bars: progress counts up instead of down for states that ask for it.
local baseProgress = Regions.Progress
Regions.Progress = function(state, now)
  local p = baseProgress(state, now)
  if state and state.fillUp and state.progressType == "timed" then
    return 1 - p
  end
  return p
end

---------------------------------------------------------------------------
-- Default auras, added once (settings.castBarsAdded), also to saved auras.
---------------------------------------------------------------------------

local function castBar(id, desc, unit, y, color)
  return {
    id = id,
    desc = desc,
    regionType = "aurabar",
    point = "CENTER",
    x = 0,
    y = y,
    width = 240,
    height = 22,
    fontSize = 13,
    text = "%n",
    text2 = "%p",
    showIcon = true,
    texture = "Statusbar_Clean",
    color = color,
    bgColor = { 0.05, 0.04, 0.02, 0.72 },
    triggers = {
      mode = "all",
      { type = "status", check = "cast", unit = unit, fillUp = true },
    },
    conditions = {},
    animation = { start = "fade", main = "none", finish = "fade" },
  }
end

CB.EXAMPLES = {
  castBar("My cast", "Your cast bar: spell icon, bar, name and time left (replaces the game's cast bar)",
    "player", 260, { 1, 0.82, 0.2, 1 }),
  castBar("Target's cast", "What your target is casting: icon, bar, name and time left",
    "target", -250, { 0.9, 0.3, 0.2, 1 }),
}

function CB.AddExamples()
  local s = RWA_DB and RWA_DB.settings
  if not s or s.castBarsAdded then
    return
  end
  s.castBarsAdded = true
  for _, example in ipairs(CB.EXAMPLES) do
    if not RWA_DB.auras[example.id] then
      local copy = RWA.CopyTable(example)
      RWA.ApplyAuraDefaults(copy)
      RWA_DB.auras[copy.id] = copy
      table.insert(RWA_DB.order, copy.id)
    end
  end
end

-- Runs before Engine.lua's RWA_READY handler (this file loads first), so the auras load with the rest.
RWA.On("RWA_READY", function()
  CB.AddExamples()
end)
