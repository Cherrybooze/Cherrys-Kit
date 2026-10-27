-- Engine.lua: loads auras, runs triggers, applies conditions and animations, shows and hides regions.
-- This is the RoM counterpart of the state machine in WeakAuras.lua, Conditions.lua and Animations.lua.

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local loaded = {} -- [id] = { data, region, env, states, active, anim, testUntil }
RWA.loaded = loaded

local dirty = true
local nextPoll = 0
local unlocked = false -- /rwa unlock: every aura shown and draggable
local editMode = false -- on while the /rwa window is open: also loads disabled auras and loops fake data
local editStart = 0
local LOOP = 10 -- seconds per fake cycle in edit and test mode

local function moving()
  return unlocked or editMode
end

function RWA.MarkDirty()
  dirty = true
end

---------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------

function RWA.UnloadAura(id)
  local a = loaded[id]
  if a then
    W.EnableMouse(a.region.frame, false)
    a.region:Release()
    loaded[id] = nil
  end
end

function RWA.LoadAura(id)
  RWA.UnloadAura(id)
  local data = RWA.GetAura(id)
  if not data or (not data.enabled and not editMode) then
    return
  end
  for i = 1, #data.triggers do
    Triggers.Reset(data.triggers[i])
  end
  local a = { data = data, env = { id = id }, states = {}, active = false }
  a.region = Regions.Acquire(data)
  loaded[id] = a
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
    local want = string.lower(load.class)
    if string.lower(main or "") ~= want and string.lower(sub or "") ~= want then
      return false
    end
  end
  if load.level and UnitLevel and (UnitLevel("player") or 0) < load.level then
    return false
  end
  return true
end

---------------------------------------------------------------------------
-- Conditions: { trigger = 1, var = "remaining", op = "<", value = 3, set = { color = {..}, alpha = 0.5 } }
---------------------------------------------------------------------------

local function conditionValue(state, var, now)
  if not state then
    return nil
  end
  if var == "remaining" then
    if state.progressType == "timed" and state.expirationTime then
      return state.expirationTime - now
    end
    return nil
  elseif var == "show" then
    return state.show and 1 or 0
  end
  return state[var]
end

local function applyConditions(a, now)
  local data = a.data
  local color, alpha = data.color, data.alpha or 1
  for _, cond in ipairs(data.conditions or {}) do
    local state = a.states[cond.trigger or 1]
    if Triggers.Compare(conditionValue(state, cond.var, now), cond.op, cond.value) and cond.set then
      color = cond.set.color or color
      alpha = cond.set.alpha or alpha
    end
  end
  if color ~= a.region.color then
    a.region:SetColor(color)
  end
  return alpha
end

---------------------------------------------------------------------------
-- Animations, after the WeakAuras presets: start and finish fade or slide, main pulse, flash or bounce.
-- Only alpha and position are animated, since RoM has no AnimationGroups or texture rotation.
---------------------------------------------------------------------------

local START_TIME, FINISH_TIME = 0.25, 0.25

local function animate(a, now, baseAlpha)
  local anim = a.data.animation or {}
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
    if not editMode then
      RWA.PlaySound(a.data.sound)
    end
  else
    a.anim = { kind = "finish", t0 = now }
  end
end

-- Fake data that loops every LOOP seconds: the timer runs down, stacks count 1 to 5 and
-- health-style values drain with it, so bars, text and conditions can be seen working.
local function fakeState(a, now)
  local t0 = (a.testUntil and a.testUntil > now) and (a.testUntil - LOOP) or editStart
  local elapsed = math.max(0, now - t0)
  local cycle = math.floor(elapsed / LOOP)
  local remaining = LOOP - (elapsed - cycle * LOOP)
  local pct = math.floor(remaining / LOOP * 100 + 0.5)
  return {
    show = true,
    name = a.data.id,
    stacks = cycle % 5 + 1,
    progressType = "timed",
    duration = LOOP,
    expirationTime = now + remaining,
    value = pct,
    total = 100,
    percent = pct,
    cycle = cycle,
    startTime = now - (elapsed - cycle * LOOP), -- %e counts up through each loop
  }
end

-- Triggers that feed only an extra display (element.from = i): they do not decide whether the
-- aura shows, and are not the main display's data.
function RWA.OwnedTriggers(data)
  local owned = {}
  for _, e in ipairs(data.elements or {}) do
    local from = tonumber(e.from) or 0
    if from > 0 and data.triggers[from] then
      owned[from] = true
    end
  end
  return owned
end

local function evaluate(a, now)
  local data = a.data
  local triggers = data.triggers
  local owned = RWA.OwnedTriggers(data)
  local anyShown, allShown, counted = false, true, 0
  local first
  for i = 1, #triggers do
    local ok, state = pcall(Triggers.Evaluate, triggers[i], now, a.env)
    if not ok then
      RWA.Error(data.id .. " trigger " .. i .. ": " .. tostring(state))
      state = { show = false }
    end
    a.states[i] = state
    if not owned[i] then
      counted = counted + 1
      if state.show then
        anyShown = true
        first = first or state
      else
        allShown = false
      end
    end
  end
  allShown = allShown and counted > 0
  local active
  if data.triggers.mode == "any" then
    active = anyShown
  else
    active = allShown
  end
  local display = first or a.states[1] or {}
  if active and not shouldLoad(data.load) then
    active = false
  end
  a.realActive = active and data.enabled and true or false
  if (a.testUntil and a.testUntil > now) or moving() then
    if not active or not data.enabled then
      display = fakeState(a, now)
      -- Replay the start animation each loop, as if the aura had just appeared.
      if a.lastCycle and display.cycle ~= a.lastCycle and a.active then
        local anim = data.animation or {}
        if anim.start and anim.start ~= "none" then
          a.anim = { kind = "start", t0 = now }
        end
      end
      a.lastCycle = display.cycle
    end
    active = true
  else
    a.lastCycle = nil
  end
  a.region:SetState(display)
  setActive(a, active, now)
end

local function frame(now)
  -- The window can close without our button (Escape, another addon), so edit mode follows it.
  if editMode and RWA.IsOptionsOpen and not RWA.IsOptionsOpen() then
    RWA.SetEditMode(false)
  end
  local poll = now >= nextPoll
  if poll then
    nextPoll = now + ((RWA_DB and RWA_DB.settings.pollRate) or 0.1)
    Triggers.Tick(now)
  end
  local reevaluate = poll or dirty
  dirty = false
  for _, a in pairs(loaded) do
    if reevaluate then
      evaluate(a, now)
    end
    if a.active or a.anim then
      if a.region.shown then
        local alpha = applyConditions(a, now)
        if not a.data.enabled then
          alpha = alpha * 0.4 -- turned off, shown only in edit mode
        end
        a.region:Update(now)
        a.region:UpdateElements(now, a.states)
        animate(a, now, alpha)
      end
    end
    if a.dragUpdate then
      a.dragUpdate()
    end
  end
  if RWA.UpdatePreview then
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

function RWA.MakeMovable(a)
  local region = a.region
  a.dragUpdate = W.MakeDraggable(region.frame, function()
    return region.data.x or 0, region.data.y or 0
  end, function(x, y)
    -- Stored offsets are screen style (+y down), the same as GetCursorPos.
    region.data.x = math.floor(x + 0.5)
    region.data.y = math.floor(y + 0.5)
    region:Place(0, a.dy or 0)
  end, function()
    if RWA.OnAuraMoved then
      RWA.OnAuraMoved(region.data.id)
    end
  end)
end

local function applyMoving()
  for _, a in pairs(loaded) do
    if moving() then
      if not a.dragUpdate then
        RWA.MakeMovable(a)
      end
    else
      a.dragUpdate = nil
      W.EnableMouse(a.region.frame, false)
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
  if RWA_DB then
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

-- Cherry's Kit (/ck) can switch the addon off; it then stays idle until turned on and reloaded.
function RWA.IsOffInKit()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("RomWeakAuras")
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
  for i = 1, #a.data.triggers do
    if a.states[i] and a.states[i].show then
      state = a.states[i]
      break
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
