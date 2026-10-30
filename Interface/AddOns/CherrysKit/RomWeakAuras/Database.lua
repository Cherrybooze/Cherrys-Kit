-- Database.lua: saved settings, aura definitions and their defaults.
-- An aura is a plain table modelled on WeakAuras' format (triggers, conditions, region, load).

local RWA = RWA

RWA.DB_VERSION = 1
RWA.MIN_AURA_SCALE, RWA.MAX_AURA_SCALE = 0.1, 4

function RWA.ValidAuraScale(value)
  return type(value)=="number" and value==value and value>=RWA.MIN_AURA_SCALE and value<=RWA.MAX_AURA_SCALE
end

function RWA.AuraScale(data)
  local value=tonumber(data and data.scale) or 1
  if value~=value or value<=0 or value==math.huge then return 1 end
  return math.max(RWA.MIN_AURA_SCALE,math.min(RWA.MAX_AURA_SCALE,value))
end

local function positiveRead(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok and type(value)=="number" and value==value and value>0 and value<math.huge then return value end
end

function RWA.ValidScreenDimension(value)
  return type(value)=="number" and value==value and value>=1 and value<=10000000
end

function RWA.ViewportSize()
  local scale=positiveRead(GetUIScale) or 1
  local width,height=positiveRead(GetScreenWidth),positiveRead(GetScreenHeight)
  if width and height then width,height=width/scale,height/scale
  else
    width=positiveRead(UIParent and UIParent.GetWidth,UIParent)
    height=positiveRead(UIParent and UIParent.GetHeight,UIParent)
  end
  if RWA.ValidScreenDimension(width) and RWA.ValidScreenDimension(height) then return width,height end
end

function RWA.ValidScreenReference(data)
  return RWA.ValidScreenDimension(data.screenReferenceWidth) and RWA.ValidScreenDimension(data.screenReferenceHeight)
end

function RWA.SetAutoScaleScreen(data,on)
  if not on then data.autoScaleScreen=false; return true end
  if data.autoScaleScreen==true and RWA.ValidScreenReference(data) then return true end
  local width,height=RWA.ViewportSize()
  if not width then return false end
  data.screenReferenceWidth,data.screenReferenceHeight=width,height
  data.autoScaleScreen=true
  return true
end

-- Authored coordinates/scale stay at their reference viewport. Only derived
-- render values change on resize; uniform size scaling avoids stretching art.
function RWA.AuraTransform(data,width,height)
  local x,y=tonumber(data.x) or 0,tonumber(data.y) or 0
  local scale,rx,ry=RWA.AuraScale(data),1,1
  if data.autoScaleScreen==true and RWA.ValidScreenReference(data) then
    if not RWA.ValidScreenDimension(width) or not RWA.ValidScreenDimension(height) then width,height=RWA.ViewportSize() end
    if width and height then rx,ry=width/data.screenReferenceWidth,height/data.screenReferenceHeight end
  end
  return x*rx,y*ry,scale*math.min(rx,ry),rx,ry
end

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
  clickThrough = true,
  scale = 1,
  autoScaleScreen = false,
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

-- Factory placement from the approved saved layout. Only factories and an
-- explicit Reset position use this map; loading never reapplies saved positions.
RWA.DEFAULT_AURA_POSITIONS = {
  ["Player health"]={44,291}, ["Target health"]={-390,-215},
  ["Target's cast"]={0,-250}, ["My cast"]={34,254},
  ["In combat"]={153,-363}, ["Target's last cast"]={291,-363},
  ["Hits per second"]={338,-201}, ["Threat meter"]={-343,-202},
  ["KittyCombo mode"]={48,314}, ["Example: debuff on target"]={-106,-349},
  ["Kitty Hook"]={205,-263}, ["Class icon"]={-421,428,"TOPRIGHT"},
  ["Example: buff on me"]={341,-91}, ["Example: missing buff reminder"]={-98,-208},
  ["Resource: Upper bar"]={-360,-60}, ["Resource: Lower bar"]={-360,-32},
  ["Resource: PSI"]={-310,-125}, ["High durability repair"]={0,-265},
}
function RWA.ApplyDefaultPosition(data,factoryId)
  local position=data and RWA.DEFAULT_AURA_POSITIONS[factoryId or data.id]
  if position then data.point,data.x,data.y=position[3] or "CENTER",position[1],position[2] end
  return data
end

function RWA.ResetAuraPosition(data,factoryId)
  -- Custom auras return to the centre. Keep size, screen reference, rules and
  -- all relative output offsets intact; auto scaling still follows its reference.
  data.point,data.x,data.y="CENTER",0,0
  return RWA.ApplyDefaultPosition(data,factoryId)
end

-- Descriptions for the example auras, also added to examples saved by older versions.
local EXAMPLE_DESC = {
  ["High durability repair"] = "Warns when an equipped item with maximum durability of at least 101 drops below 101",
  ["Player health"] = "Your health as a bar with your class icon; red under 30%",
  ["Target health"] = "Your target's health: percentage above the bar, HP inside it (a monster's HP is learned like pbInfo, ? until known). Hides when you have no target",
  ["Class icon"] = "Your class combo; changes when you switch class",
  ["KittyCombo mode"] = "The KittyCombo mode that is on (mode button), as text and picture; in combat only",
  ["In combat"] = "Pulsing text and how long you have been fighting",
  ["Example: buff on me"] = "Choose a buff; show its icon when it is missing on you",
  ["Example: debuff on target"] = "Edit: type a debuff you put on enemies",
  ["Example: missing buff reminder"] = "Shows when a buff is missing",
}
-- Example descriptions older versions saved word for word; they get the current text.
local OLD_EXAMPLE_DESC = {
  ["Your target's health as HP and percentage; ~ marks learned estimates, ? unknown HP. Hides when you have no target"] = "Target health",
}

-- A mode belongs to KittyCombo's own state; it is not a game buff.
local KITTY_MODE_CODE = [[
local ui = Kitty and Kitty.ModeUI
if not ui or not ui.current then return false end
local mode = ui.current()
return true, { name = "Mode: " .. (mode or "none"), icon = ui.iconPath and ui.iconPath(mode or "") }]]

local EXAMPLES = {
  {
    id="High durability repair",enabled=true,schemaVersion=3,load={},
    primarySourceId="s1",nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
    sources={{id="s1",type="status",check="durability",unit="player",minimumMax=101}},
    rules={{id="r1",name="High durability below 101",enabled=true,
      when={mode="all",checks={{id="c1",sourceId="s1",field="value",op="<",value=101}}},
      actions={{id="a1",type="show",sourceId="s1",output={id="o1",regionType="text",width=420,height=34,
        text="Repair: %n (%v / %t)",fontSize=18,color={1,.8,.2,1},animation={start="none",main="none",finish="none"}}}}}},
  },
  {
    id = "Player health", enabled=true, schemaVersion=3, point="CENTER", x=0, y=220, load={},
    primarySourceId="s1",nextSourceId=3,nextRuleId=3,nextCheckId=4,nextActionId=4,nextOutputId=3,
    sources={{id="s1",type="status",check="health",unit="player"},{id="s2",type="status",check="class",unit="player"}},
    rules={
      {id="r1",name="My health",enabled=true,when={mode="all",checks={{id="c1",sourceId="s1",field="active"}}},
        actions={
          {id="a1",type="show",sourceId="s1",output={id="o1",regionType="aurabar",width=220,height=22,text="%n",text2="%v / %t",showIcon=false,color={.2,.7,.3,1},animation={start="none",main="none",finish="none"}}},
          {id="a2",type="show",sourceId="s2",output={id="o2",regionType="icon",parentOutputId="o1",offsetX=-124,offsetY=0,width=24,height=24,text="",text2="",animation={start="none",main="none",finish="none"}}}
        }},
      {id="r2",name="Low health",enabled=true,when={mode="all",checks={
        {id="c2",field="rule",ruleId="r1",value=true},{id="c3",sourceId="s1",field="percent",op="<",value=30}}},
        actions={{id="a3",type="color",targetId="o1",value={.9,.15,.15,1}}}}
    },
  },
  {
    id="Target health",enabled=true,schemaVersion=3,load={},
    primarySourceId="s1",nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
    sources={{id="s1",type="status",check="health",unit="target"}},
    rules={{id="r1",name="Target health",enabled=true,
      when={mode="all",checks={{id="c1",sourceId="s1",field="unitAvailable"}}},
      actions={{id="a1",type="show",sourceId="s1",output={id="o1",regionType="aurabar",width=240,height=22,
        text="%n",text2="%v / %t",showIcon=false,color={.2,.7,.3,1},animation={start="none",main="none",finish="none"}}}}}},
  },
  {
    id = "In combat",
    regionType = "text",
    x = 0,
    y = -160,
    text = "IN COMBAT",
    fontSize = 22,
    color = { 1, 0.3, 0.3, 1 },
    schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
    sources = { { id = "s1", type = "status", check = "combat" } },
    rules = { { id = "r1", name = "Show in combat", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } } },
    elements = { { type = "text", side = "BOTTOM", text = "%e", size = 16 } },
    animation = { start = "fade", main = "pulse", finish = "fade" },
  },
  {
    id="Example: buff on me",enabled=false,schemaVersion=3,load={},
    primarySourceId="s1",nextSourceId=2,nextRuleId=2,nextCheckId=2,nextActionId=2,nextOutputId=2,
    sources={{id="s1",type="aura",unit="player",filter="HELPFUL",ids={},names={}}},
    rules={{id="r1",name="Buff missing on me",enabled=true,
      when={mode="all",checks={{id="c1",sourceId="s1",field="missing"}}},
      actions={{id="a1",type="show",sourceId="s1",output={id="o1",regionType="icon",width=48,height=48,
        text="",text2="",animation={start="none",main="none",finish="none"}}}}}},
  },
  {
    id = "Example: debuff on target",
    enabled = false,
    regionType = "aurabar",
    x = 0,
    y = 260,
    schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
    sources = { { id = "s1", type = "aura", unit = "target", filter = "HARMFUL", names = { "Put a debuff name here" } } },
    rules = { { id = "r1", name = "Show when present", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "present" } } }, set = { visible = true } } },
  },
  {
    id = "Example: missing buff reminder",
    enabled = false,
    regionType = "icon",
    x = 60,
    y = 150,
    text = "MISSING",
    schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
    sources = { { id = "s1", type = "aura", unit = "player", filter = "HELPFUL", names = { "Put a buff name here" } } },
    rules = { { id = "r1", name = "Show when missing", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "missing" } } }, set = { visible = true } } },
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
    schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
    sources = { { id = "s1", type = "status", check = "class", unit = "player" } },
    rules = { { id = "r1", name = "Show class", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } } },
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
    schemaVersion = 2, defaultVisible = false, primarySourceId = "s1",
    sources = { { id = "s1", type = "custom", code = KITTY_MODE_CODE } },
    rules = { { id = "r1", name = "Show Kitty mode", when = { mode = "all", checks = {
      { id = "c1", sourceId = "s1", field = "active" } } }, set = { visible = true } } },
    elements = { { type = "icon", side = "LEFT" } },
    animation = { start = "fade", main = "none", finish = "fade" },
  },
}

for _,example in ipairs(EXAMPLES) do RWA.ApplyDefaultPosition(example) end

-- The gallery reads immutable factory examples, never a player's edited copies.
RWA.BuiltinExamples = EXAMPLES
RWA.BuiltinExampleDescriptions = EXAMPLE_DESC

function RWA.ApplyAuraDefaults(data)
  if data.autoScaleScreen==nil then data.autoScaleScreen=false end
  if data.autoScaleScreen==true and not RWA.ValidScreenReference(data) then RWA.SetAutoScaleScreen(data,true) end
  -- A version 3 aura is a group of action-owned outputs. Apply appearance
  -- defaults only to the individual output definitions passed by the renderer.
  if data.schemaVersion == 3 and type(data.rules) == "table" then
    if data.enabled == nil then data.enabled = true end
    if data.clickThrough == nil then data.clickThrough = true end
    if data.scale == nil then data.scale = 1 end
    if data.point == nil then data.point = "CENTER" end
    if data.x == nil then data.x = 0 end
    if data.y == nil then data.y = 0 end
    if type(data.load) ~= "table" then data.load = {} end
    return data
  end
  local region = RWA.REGION_DEFAULTS[data.regionType or "icon"] or {}
  RWA.MergeDefaults(data, region)
  if data.schemaVersion == 2 or data.schemaVersion == 3 then
    for key, value in pairs(RWA.AURA_DEFAULTS) do
      if key ~= "triggers" and key ~= "conditions" and data[key] == nil then
        data[key] = RWA.CopyTable(value)
      end
    end
  else
    RWA.MergeDefaults(data, RWA.AURA_DEFAULTS)
  end
  return data
end

local function exampleCopy(id)
  for _,example in ipairs(EXAMPLES) do
    if example.id==id then
      local copy=RWA.CopyTable(example)
      copy.desc=EXAMPLE_DESC[id]
      return RWA.ApplyAuraDefaults(copy)
    end
  end
end

local function onlyKeys(value,allowed)
  for key in pairs(value) do if not allowed[key] then return false end end
  return true
end

-- Adopt only the known plain reminder. Richer edited auras keep their name and
-- full logic; the new empty example is installed beside them instead.
local function remakeTargetArea(original)
  if type(original)~="table" or not RWA.Rules then return nil end
  local backup={}
  for key,value in pairs(original) do
    if key~="previousDefinition" then backup[key]=RWA.CopyTable(value) end
  end
  local ok,data=pcall(RWA.Rules.Normalize,RWA.CopyTable(backup))
  if not ok or type(data)~="table" or type(data.sources)~="table" or type(data.rules)~="table" then return nil end
  local sources={}
  for _,source in ipairs(data.sources) do
    if type(source)~="table" or type(source.id)~="string" or source.type~="aura" or source.unit~="player" or source.filter~="HELPFUL"
      or type(source.ids)~="table" or #source.ids~=1 or tonumber(source.ids[1])~=500934
      or source.names~=nil and (type(source.names)~="table" or next(source.names)~=nil)
      -- Converted legacy filters are inert source metadata: any actual filter
      -- became a rule check, and non-Missing checks below reject adoption.
      or not onlyKeys(source,{id=true,type=true,unit=true,filter=true,ids=true,names=true,
        showOn=true,remainingOp=true,remaining=true,stacksOp=true,stacks=true}) then return nil end
    sources[source.id]=true
  end
  if not next(sources) then return nil end
  local missingRules,output={},nil
  for _,rule in ipairs(data.rules) do
    local when=type(rule)=="table" and rule.when
    if type(rule)~="table" or type(rule.id)~="string" or rule.enabled==false or type(when)~="table" or when.mode~="all"
      or type(when.checks)~="table" or #when.checks==0 or type(rule.actions)~="table" then return nil end
    for _,check in ipairs(when.checks) do
      if type(check)~="table" then return nil end
      if check.field=="missing" and sources[check.sourceId] then
        if not onlyKeys(check,{id=true,field=true,sourceId=true}) then return nil end
      elseif check.field=="rule" and check.value==true and missingRules[check.ruleId] then
        if not onlyKeys(check,{id=true,field=true,ruleId=true,value=true}) then return nil end
      else return nil end
    end
    missingRules[rule.id]=true
    for _,action in ipairs(rule.actions) do
      if type(action)~="table" or action.type~="show" or output
        or action.sourceId~=nil and not sources[action.sourceId]
        or type(action.output)~="table" or action.output.regionType~="icon"
        or action.output.parentOutputId~=nil
        or action.output.elements~=nil and (type(action.output.elements)~="table" or next(action.output.elements)~=nil)
        or action.sourceChoices~=nil and type(action.sourceChoices)~="table" then return nil end
      for _,choice in ipairs(action.sourceChoices or {}) do
        if type(choice)~="table" or not sources[choice.sourceId] or not missingRules[choice.ruleId] then return nil end
      end
      output=action.output
    end
  end
  if not output then return nil end
  local copy=exampleCopy("Example: buff on me")
  for _,key in ipairs({"enabled","point","x","y","load"}) do
    if original[key]~=nil then copy[key]=RWA.CopyTable(original[key]) end
  end
  copy.sources[1].ids={500934}
  copy.rules[1].actions[1].output=RWA.CopyTable(output)
  copy.rules[1].actions[1].output.id="o1"
  copy.previousDefinition=backup
  return copy
end

function RWA.InstallStarterFlowDefaults()
  local settings=RWA_DB.settings
  if (tonumber(settings.starterFlowDefaultsVersion) or 0)>=1 then return end
  local buffId="Example: buff on me"
  if not RWA_DB.auras[buffId] then
    local remade=remakeTargetArea(RWA_DB.auras["Target Area"])
    if remade then
      RWA_DB.auras["Target Area"],RWA_DB.auras[buffId]=nil,remade
      for i,id in ipairs(RWA_DB.order) do if id=="Target Area" then RWA_DB.order[i]=buffId end end
    end
  end
  for _,id in ipairs({"Target health",buffId}) do
    if not RWA_DB.auras[id] then
      RWA_DB.auras[id]=exampleCopy(id)
      RWA_DB.order[#RWA_DB.order+1]=id
    end
  end
  settings.starterFlowDefaultsVersion=1
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
    if (data.desc == nil or OLD_EXAMPLE_DESC[data.desc] == id) and EXAMPLE_DESC[id] then
      data.desc = EXAMPLE_DESC[id]
    end
  end
  RWA.AddClassIconExamples()
  RWA.AddCombatTimerExample()
  RWA.AddKittyModeExample()
  RWA.FixKittyModeExample()
  RWA.InstallStarterFlowDefaults()
  -- Install once for existing profiles; later deletion is a player's choice.
  if not RWA_DB.settings.durabilityReminderAdded then
    local id="High durability repair"
    if not RWA_DB.auras[id] then
      RWA_DB.auras[id]=exampleCopy(id)
      RWA_DB.order[#RWA_DB.order+1]=id
    end
    RWA_DB.settings.durabilityReminderAdded=true
  end
  if RWA.Resources and RWA.Resources.InstallDefaults then RWA.Resources.InstallDefaults() end
  -- These same guarded installers run on RWA_READY. Calling them here also
  -- gives /rwa reset confirm the complete factory set without firing gameplay events.
  if RWA.Recent and RWA.Recent.AddExample then RWA.Recent.AddExample() end
  if RWA.LastCast and RWA.LastCast.AddExample then RWA.LastCast.AddExample() end
  if RWA.Threat and RWA.Threat.AddExample then RWA.Threat.AddExample() end
  if RWA.CastBars and RWA.CastBars.AddExamples then RWA.CastBars.AddExamples() end
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
  if ic and not ic.elements and ic.triggers and ic.triggers[1] and ic.triggers[1].check == "combat" then
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
  if hp and hp.triggers and #hp.triggers == 1 and hp.triggers[1].check == "health" and not hp.elements then
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
  local normalized, err = RWA.Rules.Normalize(data)
  if not normalized then return nil, err end
  data = normalized
  data.id = RWA.UniqueAuraId(data.id)
  RWA.ApplyAuraDefaults(data)
  RWA_DB.auras[data.id] = data
  table.insert(RWA_DB.order, data.id)
  RWA.LoadAura(data.id)
  return data.id
end

function RWA.NewAura(regionType)
  local data = { id = "New aura", enabled = true, regionType = regionType or "icon" }
  RWA.Rules.InitializeActions(data)
  RWA.Rules.AddAction(data, data.rules[1], {type="show", output={regionType=regionType or "icon"}})
  data.regionType = nil
  return RWA.AddAura(data)
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
  if RWA.ResetRuleSoundHistory then RWA.ResetRuleSoundHistory(id) end
  if RWA.Editor and RWA.Editor.Forget then RWA.Editor.Forget(id) end
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
  if RWA.MoveRuleSoundHistory then RWA.MoveRuleSoundHistory(oldId, newId) end
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
