-- Database.lua: saved settings, aura definitions and their defaults.
-- An aura is a plain table modelled on WeakAuras' format (triggers, conditions, region, load).

local RWA = RWA

RWA.DB_VERSION = 1

RWA.SETTING_DEFAULTS = {
  texExt = ".tga",
  uiScale = 1, -- options window size (0.6-1.6), the Size button or /rwa size
  soundVolume = 0, -- 0 = follow the game; 25-100 = set the sound channel to this while an aura sound plays
  soundChannel = "interface", -- the slider that carries addon sounds (interface, confirmed in game); or "effects"/"both"
  soundExt = ".wav", -- every sound ships as .wav, .mp3 and .ogg; /rwa soundext picks one
  yUp = false,
  pollRate = 0.1,
  debug = false,
  font = nil, -- nil = the bundled Fira Sans
}

-- Values every aura gets, then per region type extras.
RWA.AURA_DEFAULTS = {
  enabled = true,
  regionType = "icon",
  point = "CENTER",
  x = 0,
  y = 0,
  width = 48,
  height = 48,
  alpha = 1,
  fontSize = 14,
  color = { 1, 1, 1, 1 },
  bgColor = { 0, 0, 0, 0.5 },
  texture = "Square_FullWhite",
  text = "%p",
  triggers = { mode = "all" },
  conditions = {},
  animation = { start = "fade", main = "none", finish = "fade" },
  load = {},
}

RWA.REGION_DEFAULTS = {
  icon = { width = 48, height = 48, text = "%p", text2 = "%s" },
  aurabar = { width = 220, height = 22, text = "%n", text2 = "%p", showIcon = true, color = { 0.2, 0.7, 0.3, 1 } },
  text = { width = 200, height = 24, text = "%n", fontSize = 18 },
  texture = { width = 64, height = 64, texture = "Circle_White", color = { 1, 0.8, 0.2, 0.8 } },
}

-- Descriptions for the example auras, also added to examples saved by older versions.
local EXAMPLE_DESC = {
  ["Player health"] = "Your health as a bar with your class icon; red under 30%",
  ["Class icon"] = "Your class combo; changes when you switch class",
  ["KittyCombo mode"] = "The KittyCombo mode that is on (mode button), as text and picture; in combat only",
  ["In combat"] = "Pulsing text and how long you have been fighting",
  ["Example: my buff"] = "Edit: type your buff's name or ID",
  ["Example: debuff on target"] = "Edit: type a debuff you put on enemies",
  ["Example: missing buff reminder"] = "Shows when a buff is missing",
}

-- A mode belongs to KittyCombo's own state; it is not a game buff.
local KITTY_MODE_CODE = [[
local ui = Kitty and Kitty.ModeUI
if not ui or not ui.current then return false end
local mode = ui.current()
return true, { name = "Mode: " .. (mode or "none"), icon = ui.iconPath and ui.iconPath(mode or "") }]]

local EXAMPLES = {
  {
    id = "Player health",
    regionType = "aurabar",
    x = 0,
    y = 220,
    text = "%n",
    text2 = "%v / %t",
    showIcon = false,
    triggers = {
      mode = "all",
      { type = "status", check = "health", unit = "player" },
      { type = "status", check = "class", unit = "player" },
    },
    elements = {
      { type = "icon", from = 2, side = "LEFT" },
    },
    conditions = {
      { trigger = 1, var = "percent", op = "<", value = 30, set = { color = { 0.9, 0.15, 0.15, 1 } } },
    },
    animation = { start = "none", main = "none", finish = "none" },
  },
  {
    id = "In combat",
    regionType = "text",
    x = 0,
    y = -160,
    text = "IN COMBAT",
    fontSize = 22,
    color = { 1, 0.3, 0.3, 1 },
    triggers = {
      mode = "all",
      { type = "status", check = "combat" },
    },
    elements = {
      { type = "text", from = 0, side = "BOTTOM", text = "%e", size = 16 },
    },
    animation = { start = "fade", main = "pulse", finish = "fade" },
  },
  {
    id = "Example: my buff",
    enabled = false,
    regionType = "icon",
    x = -60,
    y = 150,
    triggers = {
      mode = "all",
      { type = "aura", unit = "player", filter = "HELPFUL", names = { "Put a buff name here" }, showOn = "active" },
    },
    conditions = {
      { trigger = 1, var = "remaining", op = "<", value = 5, set = { color = { 1, 0.4, 0.4, 1 } } },
    },
  },
  {
    id = "Example: debuff on target",
    enabled = false,
    regionType = "aurabar",
    x = 0,
    y = 260,
    triggers = {
      mode = "all",
      { type = "aura", unit = "target", filter = "HARMFUL", names = { "Put a debuff name here" }, showOn = "active" },
    },
  },
  {
    id = "Example: missing buff reminder",
    enabled = false,
    regionType = "icon",
    x = 60,
    y = 150,
    text = "MISSING",
    triggers = {
      mode = "all",
      { type = "aura", unit = "player", filter = "HELPFUL", names = { "Put a buff name here" }, showOn = "missing" },
    },
    animation = { start = "fade", main = "flash", finish = "fade" },
  },
  {
    id = "Class icon",
    enabled = false, -- starts off; the health bar shows the class icon too
    regionType = "icon",
    point = "TOPRIGHT",
    x = -53,
    y = 354,
    width = 40,
    height = 40,
    text = "",
    text2 = "",
    triggers = {
      mode = "all",
      { type = "status", check = "class", unit = "player" },
    },
    animation = { start = "none", main = "none", finish = "none" },
  },
  {
    -- 0.9.12: reads KittyCombo 1.7.0's mode button (Kitty.ModeUI); never shows without it.
    id = "KittyCombo mode",
    enabled = false, -- starts off; turn it on in the list
    regionType = "text",
    x = 0,
    y = -200,
    text = "%n",
    fontSize = 18,
    color = { 1, 0.85, 0.4, 1 },
    load = { combat = true },
    triggers = {
      mode = "all",
      {
        type = "custom",
        code = KITTY_MODE_CODE,
      },
    },
    elements = {
      -- Follow the main mode state. A positive source would make trigger 1 belong
      -- exclusively to this extra icon, leaving the main text without a trigger.
      { type = "icon", from = 0, side = "LEFT" },
    },
    animation = { start = "fade", main = "none", finish = "fade" },
  },
}

function RWA.ApplyAuraDefaults(data)
  local region = RWA.REGION_DEFAULTS[data.regionType or "icon"] or {}
  RWA.MergeDefaults(data, region)
  RWA.MergeDefaults(data, RWA.AURA_DEFAULTS)
  return data
end

function RWA.InitDB()
  if type(RWA_DB) ~= "table" then
    RWA_DB = {}
  end
  RWA_DB.settings = RWA_DB.settings or {}
  RWA.MergeDefaults(RWA_DB.settings, RWA.SETTING_DEFAULTS)
  if not RWA_DB.settings.channelChecked then
    -- 0.9.2: /rwa channeltest showed addon sounds use the interface channel
    RWA_DB.settings.channelChecked = true
    if RWA_DB.settings.soundChannel == "both" then
      RWA_DB.settings.soundChannel = "interface"
    end
  end
  if RWA_DB.settings.soundLoud ~= nil then
    -- 0.4.x "Loud" switch: on meant full volume
    if RWA_DB.settings.soundLoud then
      RWA_DB.settings.soundVolume = 100
    end
    RWA_DB.settings.soundLoud = nil
  end
  if type(RWA_DB.auras) ~= "table" then
    RWA_DB.auras = {}
    RWA_DB.order = {}
    for _, example in ipairs(EXAMPLES) do
      local copy = RWA.CopyTable(example)
      RWA_DB.auras[copy.id] = copy
      table.insert(RWA_DB.order, copy.id)
    end
  end
  RWA_DB.order = RWA_DB.order or {}
  -- Keep order and auras consistent if the file was edited by hand.
  local seen = {}
  for i = #RWA_DB.order, 1, -1 do
    local id = RWA_DB.order[i]
    if not RWA_DB.auras[id] or seen[id] then
      table.remove(RWA_DB.order, i)
    end
    seen[id] = true
  end
  for id, data in pairs(RWA_DB.auras) do
    data.id = id
    if not seen[id] then
      table.insert(RWA_DB.order, id)
    end
    RWA.ApplyAuraDefaults(data)
    if data.desc == nil and EXAMPLE_DESC[id] then
      data.desc = EXAMPLE_DESC[id]
    end
  end
  RWA.AddClassIconExamples()
  RWA.AddCombatTimerExample()
  RWA.AddKittyModeExample()
  RWA.FixKittyModeExample()
  RWA_DB.version = RWA.DB_VERSION
end

-- 0.9.0: the combat timer under "In combat", added once to saved auras too.
function RWA.AddCombatTimerExample()
  local s = RWA_DB.settings
  if s.combatTimerAdded then
    return
  end
  s.combatTimerAdded = true
  local ic = RWA_DB.auras["In combat"]
  if ic and not ic.elements and ic.triggers[1] and ic.triggers[1].check == "combat" then
    ic.elements = { { type = "text", from = 0, side = "BOTTOM", text = "%e", size = 16 } }
    if ic.desc == "Text that pulses while you fight" then
      ic.desc = EXAMPLE_DESC["In combat"]
    end
  end
end

-- 0.9.12: the KittyCombo mode aura (off), added once to saved auras too.
function RWA.AddKittyModeExample()
  local s = RWA_DB.settings
  if s.kittyModeAdded then
    return
  end
  s.kittyModeAdded = true
  if RWA_DB.auras["KittyCombo mode"] then
    return
  end
  for _, example in ipairs(EXAMPLES) do
    if example.id == "KittyCombo mode" then
      local copy = RWA.CopyTable(example)
      RWA.ApplyAuraDefaults(copy)
      copy.desc = EXAMPLE_DESC[copy.id]
      RWA_DB.auras[copy.id] = copy
      table.insert(RWA_DB.order, copy.id)
    end
  end
end

local function sameDefinition(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for key, value in pairs(a) do
    if not sameDefinition(value, b[key]) then return false end
  end
  for key in pairs(b) do
    if a[key] == nil then return false end
  end
  return true
end

-- Repair only the recognizable original mode example. Older editor refreshes could
-- append a blank buff trigger after the icon claimed its sole custom trigger.
-- Leave meaningful user triggers, custom code, conditions and source choices intact.
function RWA.FixKittyModeExample()
  local settings = RWA_DB.settings
  if settings.kittyModeSourceFixed then return end
  settings.kittyModeSourceFixed = true
  local data = RWA_DB.auras["KittyCombo mode"]
  if not data or data.regionType ~= "text" or type(data.triggers) ~= "table"
    or type(data.elements) ~= "table" or #data.elements ~= 1 then return end
  for key in pairs(data.elements) do
    if key ~= 1 then return end
  end
  local triggers, icon = data.triggers, data.elements[1]
  if type(icon) ~= "table" or icon.type ~= "icon" or tonumber(icon.from) ~= 1
    or (triggers.mode ~= nil and triggers.mode ~= "all") then return end
  local visualKeys = { type = true, from = true, side = true, size = true, text = true, x = true, y = true }
  for key in pairs(icon) do
    if not visualKeys[key] then return end
  end
  if not sameDefinition(triggers[1], { type = "custom", code = KITTY_MODE_CODE }) then return end
  for key in pairs(triggers) do
    if key ~= "mode" and key ~= 1 and key ~= 2 then return end
  end
  if triggers[2] ~= nil and not sameDefinition(triggers[2], {
    type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active",
  }) then return end
  for _, condition in ipairs(data.conditions or {}) do
    if condition.trigger ~= nil and tonumber(condition.trigger) ~= 1 then return end
  end
  icon.from = 0
  if triggers[2] ~= nil then table.remove(triggers, 2) end
end

-- 0.8.0: the class icon aura and the class icon on the health bar, added once to saved auras too.
function RWA.AddClassIconExamples()
  local s = RWA_DB.settings
  if s.classIconAdded then
    return
  end
  s.classIconAdded = true
  if not RWA_DB.auras["Class icon"] then
    for _, example in ipairs(EXAMPLES) do
      if example.id == "Class icon" then
        local copy = RWA.CopyTable(example)
        RWA.ApplyAuraDefaults(copy)
        copy.desc = EXAMPLE_DESC[copy.id]
        RWA_DB.auras[copy.id] = copy
        table.insert(RWA_DB.order, copy.id)
      end
    end
  end
  local hp = RWA_DB.auras["Player health"]
  if hp and #hp.triggers == 1 and hp.triggers[1].check == "health" and not hp.elements then
    table.insert(hp.triggers, { type = "status", check = "class", unit = "player" })
    hp.elements = { { type = "icon", from = 2, side = "LEFT" } }
    if hp.desc == "Your health as a bar; turns red under 30%" then
      hp.desc = EXAMPLE_DESC["Player health"]
    end
  end
end

function RWA.GetAura(id)
  return RWA_DB and RWA_DB.auras[id]
end

function RWA.UniqueAuraId(base)
  base = RWA.Trim(base)
  if base == "" then
    base = "New aura"
  end
  local id, n = base, 1
  while RWA_DB.auras[id] do
    n = n + 1
    id = base .. " " .. n
  end
  return id
end

function RWA.AddAura(data)
  data.id = RWA.UniqueAuraId(data.id)
  RWA.ApplyAuraDefaults(data)
  RWA_DB.auras[data.id] = data
  table.insert(RWA_DB.order, data.id)
  RWA.LoadAura(data.id)
  return data.id
end

function RWA.NewAura(regionType)
  return RWA.AddAura({
    id = "New aura",
    enabled = true,
    regionType = regionType or "icon",
    triggers = {
      mode = "all",
      { type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active" },
    },
  })
end

function RWA.DuplicateAura(id)
  local data = RWA.GetAura(id)
  if not data then
    return
  end
  local copy = RWA.CopyTable(data)
  copy.id = id
  copy.enabled = true
  copy.y = (copy.y or 0) + 30
  return RWA.AddAura(copy)
end

function RWA.DeleteAura(id)
  RWA.UnloadAura(id)
  RWA_DB.auras[id] = nil
  for i = #RWA_DB.order, 1, -1 do
    if RWA_DB.order[i] == id then
      table.remove(RWA_DB.order, i)
    end
  end
end

function RWA.RenameAura(oldId, newId)
  newId = RWA.Trim(newId)
  if newId == "" or newId == oldId then
    return oldId
  end
  if RWA_DB.auras[newId] then
    newId = RWA.UniqueAuraId(newId)
  end
  local data = RWA_DB.auras[oldId]
  RWA.UnloadAura(oldId)
  RWA_DB.auras[oldId] = nil
  data.id = newId
  RWA_DB.auras[newId] = data
  for i, id in ipairs(RWA_DB.order) do
    if id == oldId then
      RWA_DB.order[i] = newId
    end
  end
  RWA.LoadAura(newId)
  return newId
end
