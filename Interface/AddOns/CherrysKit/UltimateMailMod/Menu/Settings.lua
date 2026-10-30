-- Cherry's Kit: Ultimate Mail Mod settings window. /umm opens it (also the hub's Settings
-- button). Every option here is also a /umm command; both write UMMConfig.Settings.

-- number rows: setting, label, step, low, high, format
local ROWS = {
  { "FastDelay",  "Send fast: seconds between mails",  0.1, 0.1, 10,  "%.1f" },
  { "SendDelay",  "Send safely: seconds between",      0.1, 0.2, 10,  "%.1f" },
  { "BatchSize",  "Safely: pause after ... mails", 5, 0,  200, "%d" },
  { "BatchPause", "Safely: pause length (s)",           1,   0,   120, "%d" },
  { "MaxRetries", "Safely: tries again",      1,   0,   10,  "%d" },
};

-- check boxes: label, read, write
local CHECKS = {
  { "Wait for item in send slot",
    function() return UMMSettings:Get("NoSlotCheck") ~= true end,
    function(on) UMMSettings:Set("NoSlotCheck", not on) end },
  { "Sound on new mail",
    function() return UMMSettings:Get("AudioWarning") == true end,
    function(on)
      UMMSettings:Set("AudioWarning", on and true or false);
      local box = getglobal("UMMFrameSettingAudioAlert");
      if (box) then box:SetChecked(on and 1 or nil); end
    end },
  { "Mail events in chat",
    function() return UMMTrace.live == true end,
    function(on) UMMTrace.live = on and true or false end },
  { UMM_SETTINGS_MAILSHORTCUTS,
    function() return UMMSettings:ShortcutsEnabled() end,
    function(on) UMMSettings:Set("MailShortcuts", on) end },
};

local goldDirty, refreshingGold = false, false;

local BUTTONS = {
  Check = "Run check", Trace = "Show trace", Defaults = "Defaults", Reset = "Forget own chars",
};

local function Get(i)
  return UMMSendSetting(ROWS[i][1]);
end

function UMMSettingsUI_OnLoad(this)
  -- UICommonFrameTemplate has no fill of its own: give it the game's panel background
  if (UIPanelBackdropFrame_SetTexture) then
    UIPanelBackdropFrame_SetTexture(this, "Interface/Common/PanelCommonFrame", 256, 256);
  end
  getglobal(this:GetName().."Title"):SetText("|cff"..UMMColor.Medium..UMM_TITLE.."|r");
  for i, row in ipairs(ROWS) do
    getglobal(this:GetName().."Row"..i.."Label"):SetText(row[2]);
  end
  for i, check in ipairs(CHECKS) do
    getglobal(this:GetName().."Check"..i.."Name"):SetText(check[1]);
  end
  for name, text in pairs(BUTTONS) do
    getglobal(this:GetName()..name):SetText(text);
  end
  for i = 1, 2 do
    getglobal(this:GetName().."Preset"..i.."Label"):SetText(string.format(UMM_SETTINGS_GOLDPRESET, i));
  end
  getglobal(this:GetName().."SavePresets"):SetText(UMM_SETTINGS_SAVEPRESETS);
end

function UMMSettingsUI_Refresh(resetGold)
  if (not UMMConfig) then
    return;
  end
  for i, row in ipairs(ROWS) do
    getglobal("UMMSettingsFrameRow"..i.."Value"):SetText(string.format(row[6], Get(i)));
  end
  for i, check in ipairs(CHECKS) do
    getglobal("UMMSettingsFrameCheck"..i):SetChecked(check[2]() and 1 or nil);
  end
  if (resetGold or not goldDirty) then
    refreshingGold = true;
    for i = 1, 2 do getglobal("UMMSettingsFramePreset"..i):SetText(string.format("%.0f", UMMSettings:GoldPreset(i))); end
    refreshingGold, goldDirty = false, false;
    getglobal("UMMSettingsFramePresetStatus"):SetText(UMM_SETTINGS_PRESETHELP);
  end
end

function UMMSettingsUI_PresetEdited()
  if (not refreshingGold) then
    goldDirty = true;
    local status = getglobal("UMMSettingsFramePresetStatus");
    if (status) then status:SetText(UMM_SETTINGS_PRESETHELP); end
  end
end

function UMMSettingsUI_SavePresets()
  local first, second = getglobal("UMMSettingsFramePreset1"):GetText(), getglobal("UMMSettingsFramePreset2"):GetText();
  if (not UMMSettings:SetGoldPresets(first, second)) then
    getglobal("UMMSettingsFramePresetStatus"):SetText("|cffff6060"..UMM_SETTINGS_PRESETERROR.."|r");
    return false;
  end
  UMMSettingsUI_Refresh(true);
  getglobal("UMMSettingsFramePresetStatus"):SetText(UMM_SETTINGS_PRESETSAVED);
  return true;
end

function UMMSettingsUI_ShortcutTip(this)
  if (not GameTooltip) then return; end
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
  GameTooltip:SetText(UMM_SETTINGS_MAILSHORTCUTS);
  GameTooltip:AddLine(UMM_SETTINGS_TIP_MAILSHORTCUTS, 1, 1, 1);
  GameTooltip:AddLine(UMM_SETTINGS_PRESETHELP, 1, 1, 1);
  GameTooltip:Show();
end

function UMMSettingsUI_Step(i, direction)
  local row = ROWS[i];
  local value = Get(i) + direction * row[3];
  value = math.floor(value / row[3] + 0.5) * row[3];   -- no 0.30000000004
  value = math.max(row[4], math.min(row[5], value));
  UMMSettings:Set(row[1], value);
  UMMSettingsUI_Refresh();
end

function UMMSettingsUI_Check(i, checked)
  CHECKS[i][3](checked and true or false);
  UMMSettingsUI_Refresh();
end

function UMMSettingsUI_Button(action)
  if (action == "check") then
    SlashCmdList["UMM"](nil, "x");
  elseif (action == "trace") then
    UMMTraceDump(30);
  elseif (action == "defaults") then
    for _, row in ipairs(ROWS) do
      UMMSettings:Set(row[1], UMM_SEND_DEFAULTS[row[1]]);
    end
    UMMSettings:Set("NoSlotCheck", false);
    UMMSettings:Set("MailShortcuts", true);
    UMMSettings:SetGoldPresets(UMM_GOLD_PRESET_DEFAULTS[1], UMM_GOLD_PRESET_DEFAULTS[2]);
    UMMPrompt("send settings back to defaults");
    UMMSettingsUI_Refresh(true);
  elseif (action == "resetchars") then
    SlashCmdList["UMM"](nil, "reset");
  end
end

function UMMSettingsUI_Toggle()
  if (UMMSettingsFrame:IsVisible()) then
    UMMSettingsFrame:Hide();
  else
    UMMSettingsFrame:Show();
  end
end
