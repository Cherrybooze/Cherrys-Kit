-- Events.lua: one hidden frame drives every event, timer and per-frame update.

local RWA = RWA
local W = RWA.W

local listeners = {} -- [event] = { fn, ... }
local updaters = {} -- [key] = fn(now, elapsed)
local timers = {}

-- Declared in Frames.xml, whose OnEvent and OnUpdate call RWA_Script.
local core = _G["RWA_CoreFrame"]
if core then
  W.UseXmlScripts(core, "RWA_CoreFrame")
else
  core = W.Frame("RWA_CoreFrame", "UIParent")
  W.SetSize(core, 1, 1)
  W.SetPoint(core, "TOPLEFT", "UIParent", "TOPLEFT", 0, 0)
end
RWA.coreFrame = core

function RWA.On(event, fn)
  if not listeners[event] then
    listeners[event] = {}
    RWA.Try(core, "RegisterEvent", event)
  end
  table.insert(listeners[event], fn)
end

function RWA.Fire(event, ...)
  local list = listeners[event]
  if not list then
    return
  end
  for i = 1, #list do
    local ok, err = pcall(list[i], event, ...)
    if not ok then
      RWA.Error(event .. ": " .. tostring(err))
    end
  end
end

function RWA.SetUpdater(key, fn)
  updaters[key] = fn
end

function RWA.After(seconds, fn)
  table.insert(timers, { at = RWA.Now() + seconds, fn = fn })
end

W.SetScript(core, "OnEvent", function(_, event, ...)
  RWA.Fire(event, ...)
end)

local last = RWA.Now()
W.SetScript(core, "OnUpdate", function()
  local now = RWA.Now()
  local elapsed = now - last
  last = now
  if #timers > 0 then
    local due = {}
    for i = #timers, 1, -1 do
      if timers[i].at <= now then
        table.insert(due, table.remove(timers, i))
      end
    end
    for i = 1, #due do
      local ok, err = pcall(due[i].fn)
      if not ok then
        RWA.Error(err)
      end
    end
  end
  for key, fn in pairs(updaters) do
    local ok, err = pcall(fn, now, elapsed)
    if not ok then
      RWA.Error(tostring(key) .. ": " .. tostring(err))
    end
  end
end)

-- Saved variables arrive with VARIABLES_LOADED; some setups miss it, so LOADING_END is the backup.
local started = false
local function start()
  if started then
    return
  end
  started = true
  RWA.InitDB()
  RWA.Fire("RWA_READY")
end
RWA.On("VARIABLES_LOADED", start)
RWA.On("LOADING_END", start)
RWA.Start = start

-- /rwa slash command. RoM passes (editBox, msg); WoW passes (msg, editBox). Accept both.
SLASH_RomWeakAuras1 = "/rwa"
SlashCmdList = SlashCmdList or {}
SlashCmdList["RomWeakAuras"] = function(a, b)
  local msg = type(a) == "string" and a or b
  start()
  if RWA.IsOffInKit() then
    RWA.Print("turned off in Cherry's Kit. Type /ck to turn it on.")
    return
  end
  RWA.SlashCommand(RWA.Trim(msg))
end

function RWA.SlashCommand(msg)
  local cmd, rest = string.match(msg or "", "^(%S*)%s*(.-)$")
  cmd = string.lower(cmd or "")
  if cmd == "" or cmd == "show" or cmd == "options" then
    RWA.ToggleOptions()
  elseif cmd == "unlock" then
    RWA.SetUnlocked(true)
  elseif cmd == "lock" then
    RWA.SetUnlocked(false)
  elseif cmd == "test" then
    RWA.TestAuras(rest ~= "" and rest or nil)
  elseif cmd == "probe" then
    RWA.Probe()
  elseif cmd == "debug" then
    RWA_DB.settings.debug = not RWA_DB.settings.debug
    RWA.Print("debug", RWA_DB.settings.debug and "on" or "off")
  elseif cmd == "yup" then
    RWA_DB.settings.yUp = not RWA_DB.settings.yUp
    RWA.Print("y offsets now count", RWA_DB.settings.yUp and "upward" or "downward")
    RWA.ReloadAll()
  elseif cmd == "texext" then
    RWA_DB.settings.texExt = (rest == "none") and "" or rest
    RWA.Print("texture extension set to '" .. RWA_DB.settings.texExt .. "'")
    RWA.ReloadAll()
  elseif cmd == "soundext" then
    local ext = string.lower(rest or "")
    ext = (string.sub(ext, 1, 1) == "." or ext == "") and ext or ("." .. ext)
    if ext ~= ".wav" and ext ~= ".mp3" and ext ~= ".ogg" then
      RWA.Print("sounds use '" .. RWA_DB.settings.soundExt .. "'. Choose with /rwa soundext wav, mp3 or ogg")
      return
    end
    RWA_DB.settings.soundExt = ext
    RWA.Print("sounds now play as " .. ext)
    RWA.PlaySound("AirHorn")
  elseif cmd == "loud" then
    RWA.SetLoudSounds((tonumber(RWA_DB.settings.soundVolume) or 0) == 0)
  elseif cmd == "size" or cmd == "scale" then
    local n = tonumber(rest)
    if not n then
      RWA.Print("window size: " .. math.floor((tonumber(RWA_DB.settings.uiScale) or 1) * 100 + 0.5) .. "%. Set with /rwa size 60-160")
      return
    end
    if n > 3 then
      n = n / 100
    end
    RWA.Print("window size " .. math.floor(RWA.SetWindowScale(n) * 100 + 0.5) .. "%")
  elseif cmd == "volume" then
    if not tonumber(rest) then
      RWA.Print("aura volume: " .. RWA_DB.settings.soundVolume .. "% (0 = follow the game). Set with /rwa volume 0-100")
      return
    end
    RWA.SetSoundVolume(tonumber(rest))
  elseif cmd == "channel" then
    if rest ~= "interface" and rest ~= "effects" and rest ~= "both" then
      RWA.Print("aura volume sets the " .. RWA.SoundChannelLabel(RWA_DB.settings.soundChannel)
        .. ". Choose with /rwa channel interface, effects or both, or find out with /rwa channeltest")
      return
    end
    RWA.SetSoundChannel(rest)
  elseif cmd == "channeltest" then
    RWA.ChannelTest()
  elseif cmd == "linktest" then
    RWA.Share.LinkTest()
  elseif cmd == "soundtest" then
    -- Plays one sound in each format, a second and a half apart, so you can hear which ones work.
    local saved = RWA_DB.settings.soundExt
    for i, ext in ipairs({ ".wav", ".mp3", ".ogg" }) do
      RWA.After((i - 1) * 1.5, function()
        RWA_DB.settings.soundExt = ext
        RWA.Print("sound test " .. i .. ": " .. ext)
        RWA.PlaySound("AirHorn")
        RWA_DB.settings.soundExt = saved
      end)
    end
    RWA.After(4.5, function()
      RWA.Print("which numbers did you hear? Pick a working one with /rwa soundext wav, mp3 or ogg")
    end)
  elseif cmd == "reset" and rest == "confirm" then
    RWA_DB = nil
    RWA.InitDB()
    RWA.NormalizeSavedAuras()
    RWA.ReloadAll()
    RWA.Print("all auras reset to the examples")
  else
    RWA.Print("commands: /rwa (window), unlock, lock, test [name], probe, debug, yup, texext <.tga|.dds|none>, soundtest, soundext <wav|mp3|ogg>, volume <0-100>, channel <interface|effects|both>, channeltest, linktest, loud, kitty [name], hits [reset], lastcast, threat, size <60-160>, reset confirm")
  end
end
