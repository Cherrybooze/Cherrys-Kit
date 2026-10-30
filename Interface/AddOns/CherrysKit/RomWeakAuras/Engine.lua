-- Engine.lua: loads auras, runs triggers, applies conditions and animations, shows and hides regions.
-- Rules own their outputs; one shared loop updates observations and animations.

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers
local Rules = RWA.Rules

local actionEdges = {} -- stable aura/rule/action identities, retained across reloads
local spareEdges = {} -- per aura, the emptied table the next poll's edges are written into
local compiledActions = {}
function RWA.ResetRuleSoundHistory(id)
  actionEdges[id], spareEdges[id], compiledActions[id] = nil, nil, nil
end
function RWA.MoveRuleSoundHistory(oldId, newId)
  actionEdges[newId], actionEdges[oldId] = actionEdges[oldId], nil
  spareEdges[oldId] = nil
  compiledActions[newId], compiledActions[oldId] = compiledActions[oldId], nil
end
local loaded = {} -- [id] = { data, region, env, states, active, anim, testUntil }
RWA.loaded = loaded
local releasePlacement,updatePlacementGrip

local dirty = true
local nextPoll = 0
local unlocked = false -- /rwa unlock: every aura shown and draggable
local editMode = false -- on while the /rwa window is open: also loads disabled auras and loops fake data
local optionsPreview = false -- window placement visibility is independent of the drag lock
local editStart = 0
local LOOP = 10 -- seconds per fake cycle in edit and test mode

local function moving()
  return unlocked or editMode
end

local function previewing(a, now)
  return optionsPreview or moving() or (a.testUntil and a.testUntil > now) or false
end

function RWA.MarkDirty()
  dirty = true
end

---------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------

local function resetConditionVisuals(region)
  if region.conditionScale then
    RWA.Try(region.frame, "SetScale", region.conditionBaseScale or 1)
    region.conditionScale = nil
  end
  if region.conditionOverlay then
    RWA.Try(region.conditionOverlay, "Hide")
    W.SetTexture(region.conditionOverlay, nil)
    region.conditionOverlayPath = nil
    region.conditionOverlayShown = false
  end
end

local function clearFrameHandlers(frame)
  if W.activeTooltipOwner == frame then
    W.activeTooltipOwner = nil
    RWA.Try(GameTooltip, "Hide")
  end
  for _, event in ipairs({"OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp"}) do
    W.SetScript(frame, event, nil)
  end
  W.EnableMouse(frame, false)
end
local function clearRegionHandlers(region)
  clearFrameHandlers(region.frame)
end

local function attachRegionHover(a, region)
  if not optionsPreview and not moving() and a.data.clickThrough ~= false then
    clearRegionHandlers(region)
    return
  end
  W.Tooltip(region.frame, function()
    if loaded[a.data.id] ~= a then return end
    if not optionsPreview and not moving() and a.data.clickThrough ~= false then return end
    local lines = Rules.TooltipLines(a.data, a.ruleResult, a.states)
    return a.data.id, unpack(lines)
  end)
  W.EnableMouse(region.frame, true)
end

function RWA.UnloadAura(id)
  local a = loaded[id]
  if a then
    releasePlacement(a)
    for _, output in ipairs(a.outputs) do
      clearRegionHandlers(output.region)
      resetConditionVisuals(output.region)
      output.region:Release()
    end
    loaded[id] = nil
  end
end

function RWA.LoadAura(id)
  RWA.UnloadAura(id)
  local data = ((optionsPreview or editMode) and RWA.GetEditingAura and RWA.GetEditingAura(id)) or RWA.GetAura(id)
  if not data or data.schemaVersion ~= 3 or (not data.enabled and not (optionsPreview or editMode)) then
    if data and (data.schemaVersion == 2 or data.schemaVersion == 3) then RWA.ResetRuleSoundHistory(id) end
    return
  end
  for _, source in ipairs(data.sources or {}) do
    Triggers.Reset(source)
  end
  local a = { data = data, env = { id = id }, states = {}, active = false }
  local cache = compiledActions[id]
  if cache then
    local used = {}
    for _, rule in ipairs(data.rules or {}) do
      for _, action in ipairs(rule.actions or {}) do
        if type(rule.id) == "string" and type(action.id) == "string" and action.type == "code" then
          used[rule.id .. "\031" .. action.id] = true
        end
      end
    end
    for key in pairs(cache) do if not used[key] then cache[key] = nil end end
  end
  a.prepared, a.outputs, a.outputsById = Rules.PrepareActions(data), {}, {}
  local viewportWidth,viewportHeight
  if data.autoScaleScreen==true then viewportWidth,viewportHeight=RWA.ViewportSize() end
  local positionX,positionY,auraScale=RWA.AuraTransform(data,viewportWidth,viewportHeight)
  a.viewportWidth,a.viewportHeight=viewportWidth,viewportHeight
  for _, outputId in ipairs(a.prepared.order) do
    local item = a.prepared.outputs[outputId]
    local definition = RWA.CopyTable(item.definition)
    definition.id, definition.schemaVersion = data.id, 3
    definition.point = data.point or "CENTER"
    definition.x = positionX + (tonumber(definition.offsetX) or 0) * auraScale
    definition.y = positionY + (tonumber(definition.offsetY) or 0) * auraScale
    RWA.ApplyAuraDefaults(definition)
    local output = { id = outputId, data = definition, sourceId = item.sourceId, active = false, placementCache = {} }
    local parent = item.linkValid and definition.parentOutputId and a.outputsById[definition.parentOutputId]
    output.parent = parent
    output.region = parent and Regions.AcquireChild(parent.region, definition) or Regions.Acquire(definition)
    resetConditionVisuals(output.region)
    -- Native children inherit their parent's scale. Independent outputs scale
    -- about the shared aura position; condition Grow multiplies this base.
    output.region.conditionBaseScale = parent and 1 or auraScale
    RWA.Try(output.region.frame, "SetScale", output.region.conditionBaseScale)
    output.region:Place()
    a.outputs[#a.outputs + 1] = output
    a.outputsById[outputId] = output
  end
  a.region = a.outputs[1] and a.outputs[1].region
  loaded[id] = a
  for _, output in ipairs(a.outputs) do attachRegionHover(a, output.region) end
  if moving() then
    RWA.MakeMovable(a)
  end
  dirty = true
end

function RWA.ReloadAll()
  for id in pairs(loaded) do
    RWA.UnloadAura(id)
  end
  for _, id in ipairs(RWA_DB.order) do
    RWA.LoadAura(id)
  end
end

---------------------------------------------------------------------------
-- Load conditions (WeakAuras "Load" tab): combat, class, minimum level
---------------------------------------------------------------------------

local function inCombat()
  if not GetPlayerCombatState then
    return false
  end
  local ok, state = pcall(GetPlayerCombatState)
  return ok and state ~= nil and state ~= false and state ~= 0
end

local function shouldLoad(load)
  if not load then
    return true
  end
  if load.combat ~= nil and load.combat ~= inCombat() then
    return false
  end
  if load.class and load.class ~= "" and UnitClass then
    local main, sub = UnitClass("player")
    local function normalize(value)
      local token = RWA.ClassToken and RWA.ClassToken(value) or value
      return type(token) == "string" and string.lower(token) or token
    end
    local want = normalize(load.class)
    if normalize(main or "") ~= want and normalize(sub or "") ~= want then
      if type(UnitClassToken) ~= "function" then return false end
      main, sub = UnitClassToken("player")
      if normalize(main or "") ~= want and normalize(sub or "") ~= want then return false end
    end
  end
  if load.level and UnitLevel and (UnitLevel("player") or 0) < load.level then
    return false
  end
  return true
end
RWA.PassesLoad = shouldLoad

---------------------------------------------------------------------------
-- Reversible condition visuals. Visibility and sounds use real trigger states,
-- while preview/test data may still animate the display.
---------------------------------------------------------------------------

-- The editor's separate preview region can reuse these visuals without sounds.
function RWA.ApplyConditionVisuals(region, effects, now)
  local data = region.data
  if not effects then
    -- not evaluated yet: the display's own look, in a table kept with the region
    effects = region.plainEffects
    if not effects then effects = {}; region.plainEffects = effects end
    effects.color, effects.alpha, effects.grow = data.color, data.alpha or 1, 1
  end
  if effects.color ~= region.color then region:SetColor(effects.color) end
  if not region.conditionBaseScale then
    local ok, scale = RWA.Try(region.frame, "GetScale")
    region.conditionBaseScale = ok and tonumber(scale) or 1
  end
  local scale = region.conditionBaseScale * effects.grow
  if scale ~= region.conditionScale then
    RWA.Try(region.frame, "SetScale", scale)
    region.conditionScale = scale
    region:Place(region.placeDX or 0,region.placeDY or 0)
  end
  local overlay = effects.overlayIcon
  if overlay then
    if not region.conditionOverlay then
      region.conditionOverlay = W.Texture(region.frame, "OVERLAY")
      W.SetPoint(region.conditionOverlay, "CENTER", region.frame, "CENTER", 0, 0)
    end
    local texture = region.conditionOverlay
    local size = math.max(1, math.min(data.width or 48, data.height or 48))
    if size ~= region.conditionOverlaySize then
      W.SetSize(texture, size, size)
      region.conditionOverlaySize = size
    end
    if overlay ~= region.conditionOverlayPath then
      W.SetTexture(texture, overlay)
      region.conditionOverlayPath = overlay
    end
    if not region.conditionOverlayShown then
      RWA.Try(texture, "Show")
      region.conditionOverlayShown = true
    end
  elseif region.conditionOverlayPath then
    RWA.Try(region.conditionOverlay, "Hide")
    W.SetTexture(region.conditionOverlay, nil)
    region.conditionOverlayPath = nil
    region.conditionOverlayShown = false
  end
  local alpha = effects.alpha
  if effects.blink then
    alpha = alpha * ((math.floor(now * 4) % 2 == 0) and 1 or 0.25)
  end
  return alpha
end

---------------------------------------------------------------------------
-- Animations, after the WeakAuras presets: start and finish fade or slide, main pulse, flash or bounce.
-- Only alpha and position are animated, since RoM has no AnimationGroups or texture rotation.
---------------------------------------------------------------------------

local START_TIME, FINISH_TIME = 0.25, 0.25

local NO_ANIMATION = {}
local function animate(a, now, baseAlpha)
  local anim = a.data.animation or NO_ANIMATION
  local alpha, dy = baseAlpha, 0
  local phase = a.anim
  if phase and phase.kind == "start" then
    local p = (now - phase.t0) / START_TIME
    if p >= 1 then
      a.anim = { kind = "main", t0 = now }
    elseif anim.start == "fade" then
      alpha = alpha * p
    elseif anim.start == "slide" then
      alpha = alpha * p
      dy = 30 * (1 - p)
    end
  elseif phase and phase.kind == "finish" then
    local p = (now - phase.t0) / FINISH_TIME
    if p >= 1 or anim.finish == "none" or anim.finish == nil then
      a.anim = nil
      a.region:Hide()
      return
    end
    alpha = alpha * (1 - p)
    if anim.finish == "slide" then
      dy = 30 * p
    end
  end
  if a.anim and a.anim.kind == "main" then
    local t = now - a.anim.t0
    if anim.main == "pulse" then
      alpha = alpha * (0.55 + 0.45 * math.cos(t * 2 * math.pi))
    elseif anim.main == "flash" then
      alpha = alpha * ((math.floor(t * 2) % 2 == 0) and 1 or 0.25)
    elseif anim.main == "bounce" then
      dy = -math.abs(math.sin(t * math.pi)) * 8
    end
  end
  if dy ~= (a.dy or 0) then
    a.dy = dy
    a.region:Place(0, dy)
  end
  if alpha ~= a.region.alpha then
    a.region:SetAlpha(alpha)
  end
end

---------------------------------------------------------------------------
-- Show / hide
---------------------------------------------------------------------------

-- Sounds are stored by name ("AirHorn"; older auras saved "AirHorn.ogg"). Each one ships as .wav, .mp3
-- and .ogg, and settings.soundExt picks the format, since the client may not play every format.
function RWA.SoundPath(file)
  if not file or file == "" or file == "none" then
    return nil
  end
  if string.find(file, "[/\\]") then
    return file
  end
  local ext = (RWA_DB and RWA_DB.settings.soundExt) or ".wav"
  return RWA.media .. "Sounds/" .. string.gsub(file, "%.%a+$", "") .. ext
end

-- Aura volume: RoM has no separate channel for addon sounds, so while one plays the game's master
-- volume goes to full and the channel that carries addon sounds (interface, effects or both,
-- settings.soundChannel) is set to settings.soundVolume percent, then everything is put back after
-- LOUD_TIME (long enough for the bundled sounds). Other game sounds on that channel follow the
-- same level for that moment, and it cannot help when sound is switched off entirely in the game.
local LOUD_TIME = 3
local MASTER = "MasterVolumeSlider"
local CHANNELS = { interface = "InterfaceSFXVolumeSlider", effects = "SoundFXVolumeSlider" }
local SLIDERS = { MASTER, CHANNELS.effects, CHANNELS.interface }
RWA.SOUND_CHANNELS = { "both", "interface", "effects" }
RWA.SOUND_VOLUMES = { 0, 25, 50, 75, 100 }
local loudSaved, loudUntil = nil, 0

local function sliderCall(name, op, ...)
  local fn = _G[name .. "_" .. op]
  if type(fn) ~= "function" then
    return nil
  end
  local ok, v = pcall(fn, ...)
  return ok and (v == nil and true or v) or nil
end

-- levels: slider name -> 0..1. The sliders may run 0-1 or 0-100: the larger scale is used when the
-- current value shows it.
local function setVolumes(levels, seconds)
  loudUntil = math.max(loudUntil, RWA.Now() + seconds)
  if not loudSaved then
    loudSaved = {}
    for _, name in ipairs(SLIDERS) do
      loudSaved[name] = tonumber(sliderCall(name, "GetValue"))
    end
    -- Kept in the saved data too, so a reload in the middle still gets the volume back.
    RWA_DB.settings.loudRestore = loudSaved
    local function restore()
      if RWA.Now() < loudUntil - 0.01 then
        RWA.After(loudUntil - RWA.Now(), restore)
        return
      end
      for name, v in pairs(loudSaved or {}) do
        sliderCall(name, "SetValue", v)
      end
      loudSaved = nil
      RWA_DB.settings.loudRestore = nil
    end
    RWA.After(seconds, restore)
  end
  for name, level in pairs(levels) do
    local old = loudSaved[name]
    if old then
      sliderCall(name, "SetValue", old > 1 and level * 100 or level)
    end
  end
end

local function auraVolumeLevels()
  local s = RWA_DB.settings
  local level = (tonumber(s.soundVolume) or 0) / 100
  local levels = { [MASTER] = 1 }
  if s.soundChannel == "interface" or s.soundChannel == "effects" then
    levels[CHANNELS[s.soundChannel]] = level
  else
    levels[CHANNELS.interface] = level
    levels[CHANNELS.effects] = level
  end
  return levels
end

function RWA.SetSoundVolume(pct)
  pct = math.max(0, math.min(100, tonumber(pct) or 0))
  RWA_DB.settings.soundVolume = pct
  if pct == 0 then
    RWA.Print("aura sounds follow the game's volume")
  else
    RWA.Print("aura sounds play at " .. pct .. "% (" .. RWA.SoundChannelLabel(RWA_DB.settings.soundChannel) .. ")")
  end
  if RWA.OnLoudChanged then
    RWA.OnLoudChanged(pct > 0)
  end
end

function RWA.SoundChannelLabel(ch)
  return ch == "interface" and "interface channel" or ch == "effects" and "sound effects channel"
    or "interface and effects channels"
end

function RWA.SetSoundChannel(ch)
  if ch ~= "interface" and ch ~= "effects" then
    ch = "both"
  end
  RWA_DB.settings.soundChannel = ch
  RWA.Print("aura volume sets the " .. RWA.SoundChannelLabel(ch))
end

-- The game's interface volume (0..1, or nil when the client does not say). Addon sounds play on
-- the interface channel, so at 0 (or master at 0) no aura sound is heard.
function RWA.InterfaceVolume()
  local function norm(name)
    local v = tonumber(sliderCall(name, "GetValue"))
    if v and v > 1 then
      v = v / 100
    end
    return v
  end
  local iface, master = norm(CHANNELS.interface), norm(MASTER)
  if not iface then
    return nil
  end
  return iface * (master or 1)
end

function RWA.UnmuteInterface()
  -- The sliders run 0-1 or 0-100; any slider above 1 shows the larger scale.
  local scale = 1
  for _, name in ipairs(SLIDERS) do
    local v = tonumber(sliderCall(name, "GetValue"))
    if v and v > 1 then
      scale = 100
    end
  end
  for _, name in ipairs({ MASTER, CHANNELS.interface }) do
    local v = tonumber(sliderCall(name, "GetValue"))
    if v and v <= 0 then
      sliderCall(name, "SetValue", 0.5 * scale)
    end
  end
  if RWA.OnLoudChanged then
    RWA.OnLoudChanged()
  end
  RWA.Print("interface sounds turned on (50%): change the level in the game's sound settings")
end

-- Old switch, kept for /rwa loud: on = 100%, off = follow the game.
function RWA.SetLoudSounds(on)
  RWA.SetSoundVolume(on and 100 or 0)
end

-- Plays the same sound twice: first with only the interface channel up, then only the effects
-- channel, so the player can hear which one carries addon sounds.
function RWA.ChannelTest()
  local steps = {
    { "interface", { [MASTER] = 1, [CHANNELS.interface] = 1, [CHANNELS.effects] = 0 } },
    { "effects", { [MASTER] = 1, [CHANNELS.interface] = 0, [CHANNELS.effects] = 1 } },
  }
  for i, step in ipairs(steps) do
    RWA.After((i - 1) * 2, function()
      setVolumes(step[2], 2.5)
      RWA.Print("channel test " .. i .. ": only " .. RWA.SoundChannelLabel(step[1]) .. " up")
      local path = RWA.SoundPath("AirHorn")
      if path and PlaySoundByPath then
        pcall(PlaySoundByPath, path)
      end
    end)
  end
  RWA.After(4.5, function()
    RWA.Print("heard only 1: /rwa channel interface. Only 2: /rwa channel effects. Both: /rwa channel both")
  end)
end

function RWA.PlaySound(file)
  local path = RWA.SoundPath(file)
  if not path then
    return false
  end
  if not PlaySoundByPath then
    RWA.Debug("no PlaySoundByPath in this client")
    return false
  end
  if RWA_DB and (tonumber(RWA_DB.settings.soundVolume) or 0) > 0 then
    setVolumes(auraVolumeLevels(), LOUD_TIME)
  end
  local ok, err = pcall(PlaySoundByPath, path)
  if not ok then
    RWA.Debug("PlaySoundByPath " .. path .. ": " .. tostring(err))
  end
  return ok
end

local function setActive(a, active, now)
  if active == a.active then
    return
  end
  a.active = active
  local anim = a.data.animation or {}
  if active then
    a.region:Show()
    a.anim = { kind = (anim.start and anim.start ~= "none") and "start" or "main", t0 = now }
  else
    a.anim = { kind = "finish", t0 = now }
  end
end

-- Preview uses the same animation presets and native parent relationship,
-- but never enters the gameplay action/sound evaluation path.
function RWA.AnimatePreviewOutput(output, visual, now, alpha)
  if output.parent then
    if output.parent.region.shown then
      Regions.AnimateElement(output.region, now,
        visual.localVisible and output.region.contentShown ~= false, alpha)
    end
  else
    setActive(output, visual.visible, now)
    if (output.active or output.anim) and output.region.shown then animate(output, now, alpha) end
  end
end

local function evaluateActionEffects(a, effects, now)
  local id = a.data.id
  local order = effects.effectOrder
  -- most auras have no sound or code: nothing to remember, no table to make
  if not order or not order[1] then
    if actionEdges[id] then spareEdges[id], actionEdges[id] = actionEdges[id], nil end
    return
  end
  local old = actionEdges[id] or {}
  -- two tables per aura take turns: last poll's edges and this poll's
  local nextEdges = spareEdges[id] or {}
  for key in pairs(nextEdges) do nextEdges[key] = nil end
  local cache = compiledActions[id] or {}
  compiledActions[id] = cache
  local muted = previewing(a, now)
  for _, key in ipairs(effects.effectOrder or {}) do
    local action = effects.effects[key]
    local previous = old[key]
    local state = previous or {}
    nextEdges[key] = state
    if action.type == "sound" then
      local clip = action.clip
      local interval = tonumber(action.interval)
      local loop = action.mode == "loop" and interval and interval > 0
      if (action.mode == "once" or loop) and type(clip) == "string" and clip ~= "" then
        if not previous or (loop and now >= (state.nextAt or now)) then
          if not muted then RWA.PlaySound(clip) end
          if loop then state.nextAt = now + interval end
        end
      end
    elseif action.type == "code" and not previous and not muted and type(action.code) == "string" and action.code ~= "" then
      local compiled = cache[key]
      if not compiled or compiled.source ~= action.code or compiled.env ~= a.env then
        local fn, err = Triggers.CompileCustom(action.code, a.env)
        compiled = { source = action.code, fn = fn, error = err, env = a.env }
        cache[key] = compiled
      end
      if not muted then
        if compiled.fn then
          local ok, err = pcall(compiled.fn, a.env)
          if not ok then RWA.Error(tostring(id) .. " action: " .. tostring(err)) end
        else
          RWA.Error(tostring(id) .. " action: " .. tostring(compiled.error))
        end
      end
    end
  end
  actionEdges[id], spareEdges[id] = nextEdges, old
end

-- Each loaded aura keeps its own snapshot and result tables (for the draft, the saved
-- aura while a draft differs, and the editor's sample), refilled on every poll.
local function buffer(a, key)
  local t = a[key]
  if not t then t = {}; a[key] = t end
  return t
end

local function evaluate(a, now)
  local data = a.data
  local snapshot = Rules.Observe(data, now, a.env, a.prepared.usedSources, buffer(a, "observedBuffer"))
  local effects = Rules.Evaluate(data, snapshot, shouldLoad(data.load), a.prepared, buffer(a, "resultBuffer"))
  local liveData = RWA.GetAura(data.id) or data
  if liveData.schemaVersion ~= 3 then liveData = data end
  local livePrepared = liveData == data and a.prepared or a.livePrepared
  if liveData ~= data and (not livePrepared or a.livePreparedData ~= liveData) then
    livePrepared = Rules.PrepareActions(liveData)
    a.livePrepared, a.livePreparedData = livePrepared, liveData
  end
  local liveSnapshot = liveData == data and snapshot
    or Rules.Observe(liveData, now, a.env, livePrepared.usedSources, buffer(a, "liveObservedBuffer"))
  local liveEffects = liveData == data and effects
    or Rules.Evaluate(liveData, liveSnapshot, shouldLoad(liveData.load), livePrepared, buffer(a, "liveResultBuffer"))
  a.realData, a.realStates, a.realActive = liveData, liveSnapshot, liveEffects.visible
  evaluateActionEffects(a, liveEffects, now)
  if not optionsPreview and previewing(a, now) and shouldLoad(data.load) then
    local phase = math.floor((now - editStart) % LOOP / (LOOP / 3))
    local mode = phase == 0 and "missing" or phase == 1 and "long" or "expiring"
    snapshot = Rules.Scenario(data, snapshot, mode, now)
    effects = Rules.Evaluate(data, snapshot, true, a.prepared, buffer(a, "sampleResultBuffer"))
    if moving() then
      for _, output in pairs(effects.outputs) do output.visible = true; output.localVisible = true; effects.visible = true end
    end
  end
  a.states, a.ruleResult = snapshot, effects
  for _, output in ipairs(a.outputs) do
    local visual = effects.outputs[output.id]
    local observed=Rules.OutputState(a.prepared.outputs[output.id], snapshot, effects)
    if optionsPreview then
      -- Keep matching/effect diagnostics real. Only the detached rendering
      -- state is filled with sample values and forced visible for positioning.
      observed,visual=Rules.PlacementPreview(output.data,Rules.FindSource(data,output.sourceId),observed,visual,now,output.placementCache)
    end
    output.conditionEffects = visual
    output.region:SetState(observed)
    if optionsPreview then
      output.active,output.anim,output.dy=true,nil,0
      output.region.elementPhase=nil
      if not output.placementPlaced then output.region:Place(0,0); output.placementPlaced=true end
      output.region:Show()
    elseif output.parent then
      output.active = visual and visual.localVisible or false
    else
      setActive(output, visual and visual.visible or false, now)
    end
  end
  a.active = optionsPreview and #a.outputs>0 or effects.visible
end

local function applyAuraTransform(a,width,height)
  local x,y,scale=RWA.AuraTransform(a.data,width,height)
  a.viewportWidth,a.viewportHeight=width,height
  for _,output in ipairs(a.outputs) do
    output.data.x=x+(tonumber(output.data.offsetX) or 0)*scale
    output.data.y=y+(tonumber(output.data.offsetY) or 0)*scale
    output.region.conditionBaseScale=output.parent and 1 or scale
    output.region:Place(output.region.placeDX or 0,output.region.placeDY or 0)
  end
end

local function placementUIScale()
  -- pcall(nil) fails cleanly when the client lacks GetUIScale; no closure per frame.
  local ok,value=pcall(GetUIScale)
  return ok and type(value)=="number" and value>0 and value<math.huge and value or 1
end

-- Bars, timers and fades are drawn 20 times a second, and a burst of game events (buffs
-- changing in a fight) re-evaluates auras at most that often. Only while you drag an aura
-- into place does it follow every frame.
local DRAW_EVERY = 0.05
local nextDraw, nextDirty = 0, 0
local function dragging()
  if not moving() then return false end
  for _, a in pairs(loaded) do
    if a.placementDrag then return true end
  end
  return false
end

local function frame(now)
  -- The window can close without our button (Escape, another addon), so edit mode follows it.
  if optionsPreview and RWA.IsOptionsOpen and not RWA.IsOptionsOpen() then
    RWA.SetOptionsPreview(false)
  elseif editMode and RWA.IsOptionsOpen and not RWA.IsOptionsOpen() then
    RWA.SetEditMode(false)
  end
  local poll = now >= nextPoll
  if poll then
    nextPoll = now + ((RWA_DB and RWA_DB.settings.pollRate) or 0.1)
    Triggers.Tick(now)
  end
  local reevaluate = poll or dirty and now >= nextDirty
  if reevaluate then dirty, nextDirty = false, now + DRAW_EVERY end
  if not (reevaluate or now >= nextDraw or dragging()) then return end
  nextDraw = now + DRAW_EVERY
  local viewportRead,viewportWidth,viewportHeight=false
  local gripScale
  if moving() then
    viewportWidth,viewportHeight=RWA.ViewportSize();viewportRead=true
    gripScale=placementUIScale()
  end
  for _, a in pairs(loaded) do
    -- The screen size rarely changes: check it on poll ticks, not every frame.
    if a.data.autoScaleScreen==true and (poll or viewportRead) then
      if not viewportRead then viewportWidth,viewportHeight=RWA.ViewportSize();viewportRead=true end
      if viewportWidth~=a.viewportWidth or viewportHeight~=a.viewportHeight then applyAuraTransform(a,viewportWidth,viewportHeight) end
    end
    if reevaluate then
      evaluate(a, now)
    end
    if a.dragUpdate then a.dragUpdate() end
    for _, output in ipairs(a.outputs) do
      local alpha = RWA.ApplyConditionVisuals(output.region, output.conditionEffects, now)
      -- The native child frame inherits its parent's disabled fade as well.
      if not a.data.enabled and not output.parent then alpha = alpha * 0.4 end
      if optionsPreview then
        -- Steady placement markers must remain visible between polls, including
        -- while the real aura is disabled, unloaded, hidden or fading out.
        output.region.elementPhase=nil
        output.region:Show()
        output.region:Update(now)
        output.region:SetAlpha(math.max(a.data.enabled==false and 0.4 or 0.5,alpha))
      elseif output.parent then
        if output.parent.region.shown then
          output.region:Update(now)
          Regions.AnimateElement(output.region, now,
            output.active and output.region.contentShown ~= false, alpha)
        end
      else
        if (output.active or output.anim) and output.region.shown then
          output.region:Update(now)
          output.region:UpdateElements(now, a.states)
          animate(output, now, alpha)
        end
        if not output.region.shown and alpha ~= output.region.alpha then
          output.region:SetAlpha(alpha)
        end
      end
    end
    if a.grip then updatePlacementGrip(a,viewportWidth,viewportHeight,gripScale) end
  end
  if RWA.UpdatePreview and RWA.IsOptionsOpen and RWA.IsOptionsOpen() then
    RWA.UpdatePreview(now)
  end
end

---------------------------------------------------------------------------
-- Test mode and moving auras
---------------------------------------------------------------------------

function RWA.TestAuras(id)
  local now = RWA.Now()
  local count = 0
  for auraId, a in pairs(loaded) do
    if not id or string.lower(auraId) == string.lower(id) then
      a.testUntil = now + LOOP
      count = count + 1
    end
  end
  dirty = true
  RWA.Print("showing", count, "aura(s) for 10 seconds")
end

-- Two 16-unit grips per movable aura from the RWA_PlaceGrip pool in Frames.xml: the move handle
-- on the top-left corner and the scale corner (the usual resize look) on the bottom-right one.
-- A frame made at runtime gets no mouse scripts in game, so only pooled frames can be dragged.
-- Reload UI re-runs this file and Widgets.lua counts its pool from 1 again: retire old grips.
local function hideGrip(grip)
  grip.owner,grip.shown,grip.x,grip.y,grip.relative=nil,nil,nil,nil,nil
  grip.scaleX,grip.scaleY,grip.scaleRelative,grip.scaleShown=nil,nil,nil,nil
  clearFrameHandlers(grip.frame);RWA.Try(grip.frame,"Hide")
  if grip.scaleFrame then
    clearFrameHandlers(grip.scaleFrame);RWA.Try(grip.scaleFrame,"Hide")
    RWA.Try(grip.scaleText,"Hide")
  end
end
for _,grip in ipairs(RWA.placementGrips or {}) do
  if grip.owner and grip.owner.cancelDrag then grip.owner.cancelDrag() end
  hideGrip(grip)
end
local placementGrips={}
RWA.placementGrips=placementGrips

releasePlacement=function(a)
  if a.cancelDrag then a.cancelDrag() end
  a.dragUpdate,a.cancelDrag=nil,nil
  local grip=a.grip
  if not grip then return end
  hideGrip(grip)
  a.grip=nil
end

local function gripFrame(file)
  local frame=W.PlacementGripFrame()
  if not frame then return end
  W.SetSize(frame,16,16)
  RWA.Try(frame,"SetFrameStrata","MEDIUM");RWA.Try(frame,"SetFrameLevel",10)
  local art=W.Texture(frame,"OVERLAY",file)
  W.SetSize(art,16,16);W.SetPoint(art,"CENTER",frame,"CENTER",0,0)
  return frame,art
end

local function acquirePlacementGrip(a)
  local grip
  for _,candidate in ipairs(placementGrips) do if not candidate.owner then grip=candidate;break end end
  if not grip then
    local frame,art=gripFrame("UI/move")
    if not frame then return end -- pool used up: the aura itself still drags
    grip={frame=frame,art=art}
    grip.scaleFrame,grip.scaleArt=gripFrame("Grip_Highlight")
    if not grip.scaleFrame then RWA.Try(frame,"Hide");return end
    placementGrips[#placementGrips+1]=grip
    grip.scaleText=W.FontString(grip.scaleFrame,"OVERLAY",12)
    W.SetSize(grip.scaleText,60,16);W.SetPoint(grip.scaleText,"LEFT",grip.scaleFrame,"RIGHT",2,0)
    RWA.Try(grip.scaleText,"Hide")
  end
  grip.owner,a.grip=a,grip
  W.EnableMouse(grip.frame,true)
  W.EnableMouse(grip.scaleFrame,true)
  local function name() return RWA.Editor.names[a.data.id] or a.data.id end
  local function where()
    return optionsPreview and "Position and size stay in the draft until Save aura." or "Placement is saved for this aura; /rwa lock finishes."
  end
  W.Tooltip(grip.frame,function()
    if loaded[a.data.id]~=a or not moving() then return end
    return name().." - move","Drag to move every output together.",
      "Drag the bottom-right corner to scale it.",where()
  end)
  W.Tooltip(grip.scaleFrame,function()
    if loaded[a.data.id]~=a or not moving() then return end
    return name().." - scale "..math.floor(RWA.AuraScale(a.data)*100+.5).."%",
      "Drag down or right to enlarge, up or left to shrink (10-400%).",
      "Exact scale: Position in the aura editor.",where()
  end)
  return grip
end

updatePlacementGrip=function(a,width,height,uiScale)
  local grip=a.grip
  if not grip or grip.owner~=a then return end
  local left,top,right,bottom
  for _,output in ipairs(a.outputs) do
    local frame=output.region.frame
    local ok,x,y
    if type(frame.GetPos)=="function" then ok,x,y=pcall(frame.GetPos,frame) end
    if ok and type(x)=="number" and type(y)=="number" and math.abs(x)<math.huge and math.abs(y)<math.huge then
      left,top=math.min(left or x,x),math.min(top or y,y)
      local sized,w,h
      if type(frame.GetRealSize)=="function" then sized,w,h=pcall(frame.GetRealSize,frame) end
      if sized and type(w)=="number" and type(h)=="number" and math.abs(w)<math.huge and math.abs(h)<math.huge then
        right,bottom=math.max(right or x+w,x+w),math.max(bottom or y+h,y+h)
      end
    end
  end
  local scale=uiScale or 1
  if left then
    -- GetPos reports physical screen pixels; the grip itself stays 16 UI units
    -- irrespective of aura size, Grow effects, native parent scale or UI scale.
    local x,y=left/scale-16,top/scale-16
    if width then x=math.max(0,math.min(math.max(0,width-16),x)) end
    if height then y=math.max(0,math.min(math.max(0,height-16),y)) end
    if x~=grip.x or y~=grip.y or grip.relative then
      W.SetPoint(grip.frame,"TOPLEFT","UIParent","TOPLEFT",x,y)
      grip.x,grip.y,grip.relative=x,y,nil
    end
  elseif grip.relative~=a.region.frame then
    W.SetPoint(grip.frame,"BOTTOMRIGHT",a.region.frame,"TOPLEFT",0,0)
    grip.relative=a.region.frame
  end
  if right then
    local x,y=right/scale,bottom/scale
    if width then x=math.max(0,math.min(math.max(0,width-16),x)) end
    if height then y=math.max(0,math.min(math.max(0,height-16),y)) end
    if x~=grip.scaleX or y~=grip.scaleY or grip.scaleRelative then
      W.SetPoint(grip.scaleFrame,"TOPLEFT","UIParent","TOPLEFT",x,y)
      grip.scaleX,grip.scaleY,grip.scaleRelative=x,y,nil
    end
  elseif grip.scaleRelative~=a.region.frame then
    W.SetPoint(grip.scaleFrame,"TOPLEFT",a.region.frame,"BOTTOMRIGHT",0,0)
    grip.scaleRelative=a.region.frame
  end
  if not grip.shown then RWA.Try(grip.frame,"Show");grip.shown=true end
  if not grip.scaleShown then RWA.Try(grip.scaleFrame,"Show");grip.scaleShown=true end
end

function RWA.CancelAuraPlacement()
  for _,a in pairs(loaded) do if a.cancelDrag then a.cancelDrag() end end
end

local function placementCursor()
  if type(GetCursorPos)~="function" then return end
  local ok,x,y=pcall(GetCursorPos)
  if ok and type(x)=="number" and type(y)=="number" and math.abs(x)<math.huge and math.abs(y)<math.huge then return x,y end
end
local function leftButton(key) return key==nil or key=="LBUTTON" or key=="LeftButton" end

function RWA.MakeMovable(a)
  if not a.region then return end
  local grip=a.grip or acquirePlacementGrip(a)
  local function valid() return moving() and loaded[a.data.id]==a end
  a.cancelDrag=function()
    a.placementDrag=nil
    if a.grip and a.grip.scaleText then RWA.Try(a.grip.scaleText,"Hide") end
  end
  a.dragUpdate=function()
    local drag=a.placementDrag
    if not drag then return end
    local width,height
    if a.data.autoScaleScreen==true then width,height=RWA.ViewportSize() end
    if not valid() or placementUIScale()~=drag.uiScale or width~=drag.width or height~=drag.height then a.cancelDrag();return end
    local cx,cy=placementCursor()
    if not cx then a.cancelDrag();return end
    local changed
    if drag.kind=="scale" then
      -- 1% per 2 UI pixels; the corner also counts down (bigger) and up (smaller)
      local moved=cx-drag.cx
      if drag.corner then moved=moved+(cy-drag.cy) end
      local scale=math.max(RWA.MIN_AURA_SCALE,math.min(RWA.MAX_AURA_SCALE,
        drag.scale+math.floor(moved/drag.uiScale/2+.5)/100))
      changed=scale~=RWA.AuraScale(a.data)
      a.data.scale=scale
      if changed and a.grip and a.grip.scaleText then
        W.SetText(a.grip.scaleText,math.floor(scale*100+.5).."%") -- only while you drag
      end
    else
      local _,_,_,rx,ry=RWA.AuraTransform(a.data,width,height)
      local x=(drag.x+math.floor((cx-drag.cx)/drag.uiScale+.5))/rx
      local y=(drag.y+math.floor((cy-drag.cy)/drag.uiScale+.5))/ry
      changed=x~=a.data.x or y~=a.data.y
      a.data.x,a.data.y=x,y
    end
    if changed then
      drag.changed=true
      applyAuraTransform(a,width,height)
      if optionsPreview and RWA.UnifiedEditor and RWA.UnifiedEditor.PlacementChanged then RWA.UnifiedEditor.PlacementChanged(a.data.id,drag.kind) end
    end
  end
  local function begin(key,resize,corner)
    if not leftButton(key) or not valid() then return end
    RWA.CancelAuraPlacement()
    local cx,cy=placementCursor();if not cx then return end
    local x,y=RWA.AuraTransform(a.data)
    local width,height
    if a.data.autoScaleScreen==true then width,height=RWA.ViewportSize() end
    a.placementDrag={cx=cx,cy=cy,x=x,y=y,scale=RWA.AuraScale(a.data),uiScale=placementUIScale(),
      kind=resize and "scale" or "position",corner=corner,width=width,height=height}
    if corner and grip then
      W.SetText(grip.scaleText,math.floor(RWA.AuraScale(a.data)*100+.5).."%")
      RWA.Try(grip.scaleText,"Show")
    end
  end
  local function finish(_,key)
    if not leftButton(key) then return end
    local drag=a.placementDrag
    if not drag then return end
    a.dragUpdate();a.placementDrag=nil
    if grip then RWA.Try(grip.scaleText,"Hide") end
    if valid() and RWA.OnAuraMoved then RWA.OnAuraMoved(a.data.id,drag.kind,drag.changed==true) end
  end
  local function shiftDrag(_,key) -- Shift-drag scales too, also when the grip pool is used up
    begin(key,type(IsShiftKeyDown)=="function" and IsShiftKeyDown() and true or false)
  end
  W.SetScript(a.region.frame,"OnMouseDown",shiftDrag)
  W.SetScript(a.region.frame,"OnMouseUp",finish)
  if not grip then return end
  W.SetScript(grip.frame,"OnMouseDown",shiftDrag)
  W.SetScript(grip.frame,"OnMouseUp",finish)
  W.SetScript(grip.scaleFrame,"OnMouseDown",function(_,key) begin(key,true,true) end)
  W.SetScript(grip.scaleFrame,"OnMouseUp",finish)
  local width,height=RWA.ViewportSize()
  updatePlacementGrip(a,width,height,placementUIScale())
end
local function applyMoving()
  for _, a in pairs(loaded) do
    if a.cancelDrag then a.cancelDrag() end
    for _, output in ipairs(a.outputs) do
      if not moving() then
        W.SetScript(output.region.frame, "OnMouseDown", nil)
        W.SetScript(output.region.frame, "OnMouseUp", nil)
      end
      attachRegionHover(a, output.region)
    end
    if moving() then
      if not a.dragUpdate then
        RWA.MakeMovable(a)
      end
    else
      releasePlacement(a)
    end
  end
  dirty = true
end

function RWA.SetUnlocked(on)
  unlocked = on and true or false
  applyMoving()
  RWA.Print(unlocked and "auras unlocked: drag them, then /rwa lock" or "auras locked")
end

function RWA.IsUnlocked()
  return unlocked
end

-- Edit mode: every aura, including turned-off ones (dimmed), shows looping test data and can be
-- dragged. The /rwa window turns it on when it opens and off when it closes.
function RWA.SetEditMode(on)
  on = on and true or false
  if on == editMode then
    return
  end
  editMode = on
  editStart = RWA.Now()
  if RWA_DB and not optionsPreview then
    RWA.ReloadAll()
  end
  applyMoving()
  if RWA.OnEditModeChanged then
    RWA.OnEditModeChanged(on)
  end
end

function RWA.IsEditMode()
  return editMode
end

-- Enter once per window opening. Locking positions changes editMode only;
-- placement visibility and muting remain until the window actually closes.
function RWA.SetOptionsPreview(on)
  on=on and true or false
  if on==optionsPreview and (on or not editMode) then return end
  optionsPreview=on
  editMode=on
  editStart=RWA.Now()
  if RWA_DB then RWA.ReloadAll() end
  applyMoving()
  if RWA.OnEditModeChanged then RWA.OnEditModeChanged(editMode) end
end
function RWA.IsOptionsPreview() return optionsPreview end

-- Cherry's Kit (/ck) can switch the addon off; it then stays idle until turned on and reloaded.
function RWA.IsOffInKit()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("RomWeakAuras")
end

function RWA.NormalizeSavedAuras()
  -- Provider examples are installed before this handler. Normalize once, before
  -- loading any runtime state; retain an unconvertible definition unchanged.
  for id, data in pairs(RWA_DB.auras) do
    local converted, err = Rules.Normalize(data)
    if converted then RWA_DB.auras[id] = RWA.ApplyAuraDefaults(converted)
    else RWA.Error(id .. ": could not convert aura: " .. tostring(err or "unsupported definition")) end
  end
end

RWA.On("RWA_READY", function()
  local pending = RWA_DB.settings.loudRestore
  if pending then
    for name, v in pairs(pending) do
      sliderCall(name, "SetValue", v)
    end
    RWA_DB.settings.loudRestore = nil
  end
  if RWA.IsOffInKit() then
    RWA.Print("turned off in Cherry's Kit. Type /ck to turn it on.")
    return
  end
  RWA.NormalizeSavedAuras()
  RWA.ReloadAll()
  RWA.SetUpdater("engine", frame)
  RWA.Print("v" .. RWA.version .. " loaded,", #RWA_DB.order, "auras. Type /rwa to open.")
end)

---------------------------------------------------------------------------
-- Public API for other addons (for example Cherry's KittyCombo). Safe to call before RWA_READY.
---------------------------------------------------------------------------

-- Ids of all auras, in list order.
function RWA.GetAuraIds()
  local ids = {}
  for i, id in ipairs((RWA_DB and RWA_DB.order) or {}) do
    ids[i] = id
  end
  return ids
end

-- True while the aura's triggers and load conditions are met (test and unlock mode do not count).
function RWA.IsAuraActive(id)
  local a = loaded[id]
  return a ~= nil and a.realActive == true
end

-- A number from the aura's first active trigger: "remaining", "stacks", "percent", "value",
-- "duration" or "total". Returns nil when the aura is not active or has no such value.
function RWA.GetAuraValue(id, var)
  local a = loaded[id]
  if not a or not RWA.IsAuraActive(id) then
    return nil
  end
  local state
  local data, states = a.realData or a.data, a.realStates or a.states
  if data.schemaVersion == 2 or data.schemaVersion == 3 then
    state = states[data.primarySourceId]
    if not state and type(data.primarySourceId) == "string" then
      -- Legacy callers explicitly requesting the primary still get its value;
      -- unreferenced compatibility sources need no background observation.
      local observed = Rules.Observe(data, RWA.Now(), a.env, { [data.primarySourceId] = true })
      state = observed[data.primarySourceId]
      states[data.primarySourceId] = state
    end
  else
    for i = 1, #(data.triggers or {}) do
      if states[i] and states[i].show then
        state = states[i]
        break
      end
    end
  end
  if not state then
    return nil
  end
  if var == "remaining" then
    if state.progressType == "timed" and state.expirationTime then
      return math.max(0, state.expirationTime - RWA.Now())
    end
    return nil
  end
  local v = state[var]
  return type(v) == "number" and v or nil
end
