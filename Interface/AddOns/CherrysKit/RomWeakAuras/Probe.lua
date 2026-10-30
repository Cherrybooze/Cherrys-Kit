-- Probe.lua: /rwa probe reports which API calls this client really has, so guesses in Widgets.lua
-- can be confirmed. Results go to chat and to RWA_DB.probe in the saved variables file.

local RWA = RWA
local W = RWA.W

local GLOBALS = {
  "CreateUIComponent", "GetTime", "GetTickCount", "loadstring", "setfenv", "getfenv", "PlaySoundByPath",
  "SaveVariables", "SaveVariablesPerCharacter", "GetCursorPos", "GetUIScale", "GetScreenWidth", "GetScreenHeight",
  "UnitBuff", "UnitDebuff", "UnitBuffLeftTime", "UnitDebuffLeftTime", "UnitBuffInfo", "UnitGUID", "UnitName",
  "UnitExists", "UnitHealth", "UnitMaxHealth", "UnitMana", "UnitMaxMana", "UnitSkill", "UnitMaxSkill",
  "UnitClass", "UnitLevel", "UnitCanAttack", "UnitCastingTime", "GetPlayerCombatState", "GetSkillCooldown",
  "GetSkillDetail", "GetNumSkill", "SlashCmdList", "DEFAULT_CHAT_FRAME", "UIParent",
}

local WIDGET_METHODS = {
  Frame = { "SetAnchor", "ClearAllAnchors", "SetSize", "SetWidth", "SetHeight", "SetScripts", "SetScript",
    "RegisterEvent", "Show", "Hide", "IsVisible", "SetAlpha", "SetScale", "SetLayers", "SetFrameStrata",
    "SetFrameLevel", "EnableMouse", "SetMouseEnable", "StartMoving", "StopMovingOrSizing", "GetName",
    "GetLeft", "GetTop", "GetWidth", "SetBackdrop" },
  Texture = { "SetTexture", "SetTexCoord", "SetColor", "SetVertexColor", "SetAlpha", "SetAlphaMode",
    "SetSize", "SetAnchor", "Show", "Hide", "SetRotation", "SetMask" },
  FontString = { "SetFont", "SetText", "SetColor", "SetTextColor", "SetJustifyHType", "SetJustifyH", "SetSize",
    "SetAnchor", "Show", "Hide" },
  Button = { "SetText", "SetScripts", "RegisterForClicks", "Enable", "Disable" },
  EditBox = { "SetText", "GetText", "SetAutoFocus", "ClearFocus", "SetFocus", "SetMaxLetters" },
  StatusBar = { "SetMinMaxValues", "SetValue", "SetBarColor", "SetStatusBarColor", "SetStatusBarTexture" },
}

local function hasMethod(obj, method)
  local ok, value = pcall(function()
    return obj[method]
  end)
  return ok and type(value) == "function"
end

function RWA.Probe()
  local result = { version = RWA.version, missingGlobals = {}, widgets = {}, events = {} }
  for _, name in ipairs(GLOBALS) do
    if _G[name] == nil then
      table.insert(result.missingGlobals, name)
    end
  end
  for kind, methods in pairs(WIDGET_METHODS) do
    local ok, obj = pcall(CreateUIComponent, kind, "RWA_Probe" .. kind, "UIParent")
    local entry = { created = ok and obj ~= nil, missing = {}, present = {} }
    if entry.created then
      for _, m in ipairs(methods) do
        table.insert(hasMethod(obj, m) and entry.present or entry.missing, m)
      end
      RWA.Try(obj, "Hide")
    else
      entry.error = tostring(obj)
    end
    result.widgets[kind] = entry
  end
  -- Samples to check units and timers: the first player buff, and target info.
  if UnitBuff then
    local name, icon, stacks, id = UnitBuff("player", 1)
    result.firstPlayerBuff = { name = name, icon = icon, stacks = stacks, id = id,
      left = UnitBuffLeftTime and UnitBuffLeftTime("player", 1) }
  end
  if GetCursorPos then
    result.cursor = { GetCursorPos() }
  end
  result.combatState = GetPlayerCombatState and tostring(GetPlayerCombatState()) or "missing"
  result.events = RWA.seenEvents
  RWA_DB.probe = result

  RWA.Print("probe: missing globals:", #result.missingGlobals > 0 and table.concat(result.missingGlobals, ", ") or "none")
  for kind, entry in pairs(result.widgets) do
    if entry.created then
      RWA.Print("probe:", kind, "missing:", #entry.missing > 0 and table.concat(entry.missing, ", ") or "none")
    else
      RWA.Print("probe:", kind, "could not be created:", entry.error)
    end
  end
  if result.firstPlayerBuff and result.firstPlayerBuff.name then
    local b = result.firstPlayerBuff
    RWA.Print("probe: first buff", b.name, "id", tostring(b.id), "stacks", tostring(b.stacks), "left", tostring(b.left))
  end
  local share = RWA.Share
  if share then
    local deflate = share.GetDeflate()
    result.shareCodes = (deflate and share.GetCodebook()) and share.CODEBOOK_PREFIX
      or (deflate and "RWA4 (data/ShareCodebook.lua missing or changed)" or "RWA4 (lib/LibDeflate.lua missing)")
    RWA.Print("probe: share codes", result.shareCodes)
  end
  RWA.Print("probe: saved to RWA_DB.probe; /reloadui writes it to the SavedVariables file")
end

-- Remember which buff/target events actually fire, to learn their names and arguments.
RWA.seenEvents = {}
local WATCH = { "UNIT_BUFF_CHANGED", "PLAYER_BUFF_CHANGED", "PLAYER_TARGET_CHANGED", "UNIT_TARGET_CHANGED",
  "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT", "UNIT_HEALTH", "UNIT_MANA", "UNIT_CASTING_START" }
for _, event in ipairs(WATCH) do
  RWA.On(event, function(e, a1, a2)
    local seen = RWA.seenEvents[e] or { count = 0 }
    seen.count = seen.count + 1
    seen.lastArgs = tostring(a1) .. ", " .. tostring(a2)
    RWA.seenEvents[e] = seen
  end)
end
RWA.On("PLAYER_ENTER_COMBAT", function()
  RWA.MarkDirty()
end)
RWA.On("PLAYER_LEAVE_COMBAT", function()
  RWA.MarkDirty()
end)
RWA.On("PLAYER_TARGET_CHANGED", function()
  RWA.Triggers.InvalidateAuras()
  RWA.MarkDirty()
end)
