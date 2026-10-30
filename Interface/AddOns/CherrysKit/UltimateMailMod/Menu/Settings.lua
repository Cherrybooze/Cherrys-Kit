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
local shownGold = {};   -- preset box name -> its text as last grouped

local BUTTONS = {
  Check = "Run check", Trace = "Show trace", Defaults = "Defaults", Reset = "Forget own chars",
  ConfirmYes = "Yes", ConfirmNo = "No",
};
-- "Forget own chars" asks first: the question and Yes/No take the place of these buttons.
-- No sits where the clicked button was, so a double click cannot confirm.
local CONFIRM_HIDES = { "Check", "Trace", "Defaults", "Reset" };
local CONFIRM_SHOWS = { "ConfirmText", "ConfirmYes", "ConfirmNo" };

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
  getglobal(this:GetName().."ConfirmText"):SetText("Confirm resetting own character list?");
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
    for i = 1, 2 do
      local box = getglobal("UMMSettingsFramePreset"..i);
      shownGold[box:GetName()] = UMMFormatNumber(UMMSettings:GoldPreset(i));
      box:SetText(shownGold[box:GetName()]);
    end
    refreshingGold, goldDirty = false, false;
    getglobal("UMMSettingsFramePresetStatus"):SetText(UMM_SETTINGS_PRESETHELP);
  end
end

function UMMSettingsUI_PresetEdited()
  if (not refreshingGold) then
    goldDirty = true;
    local status = getglobal("UMMSettingsFramePresetStatus");
    if (status) then status:SetText(UMM_SETTINGS_PRESETHELP); end
    -- The client moves the caret after this handler returns, so the commas are put
    -- back on the next frame by a helper frame that hides itself again.
    local later = getglobal("UMMSettingsFramePresetFormat");
    if (later) then later:Show(); end
  end
end

-- Groups an edited preset like the backpack's gold (1,234,567) and caps it at 9 digits
-- (999,999,999). Returns the new text and the caret position after the same digits.
function UMMSettingsUI_RegroupGold(before, text)
  -- the edit lies between the unchanged first p and last s characters
  local short, p, s = math.min(string.len(before), string.len(text)), 0, 0;
  while (p < short and string.byte(before, p + 1) == string.byte(text, p + 1)) do p = p + 1; end
  while (s < short - p and string.byte(before, -1 - s) == string.byte(text, -1 - s)) do s = s + 1; end
  local digits = string.gsub(text, "%D", "");
  local lead = string.len((string.gsub(string.sub(text, 1, string.len(text) - s), "%D", "")));
  if (string.len(text) < string.len(before) and lead > 0
      and string.len(digits) == string.len((string.gsub(before, "%D", "")))) then
    -- only a comma went (Backspace over it): take the digit in front of it too
    digits = string.sub(digits, 1, lead - 1)..string.sub(digits, lead + 1);
    lead = lead - 1;
  end
  if (string.len(digits) > 9) then digits, lead = "999999999", 9; end
  local result, caret = UMMGroupDigits(digits), 0;
  while (lead > 0 and caret < string.len(result)) do
    caret = caret + 1;
    if (string.sub(result, caret, caret) ~= ",") then lead = lead - 1; end
  end
  return result, caret;
end

function UMMSettingsUI_FormatPresets()
  for i = 1, 2 do
    local box = getglobal("UMMSettingsFramePreset"..i);
    local name, text = box:GetName(), box:GetText() or "";
    if (text ~= shownGold[name]) then
      local grouped, caret = UMMSettingsUI_RegroupGold(shownGold[name] or "", text);
      shownGold[name] = grouped;
      if (grouped ~= text) then
        refreshingGold = true;
        box:SetText(grouped);
        refreshingGold = false;
        box:HighlightText(caret, caret);   -- caret without a selection; SetPlaceCaret(0) jumps to the end
      end
    end
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

local function AskReset(asking)
  for _, name in ipairs(CONFIRM_HIDES) do
    local part = getglobal("UMMSettingsFrame"..name);
    if (asking) then part:Hide(); else part:Show(); end
  end
  for _, name in ipairs(CONFIRM_SHOWS) do
    local part = getglobal("UMMSettingsFrame"..name);
    if (asking) then part:Show(); else part:Hide(); end
  end
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
    AskReset(true);
  end
end

function UMMSettingsUI_ConfirmReset(yes)
  AskReset(false);
  if (yes) then SlashCmdList["UMM"](nil, "reset"); end
end

function UMMSettingsUI_Toggle()
  if (UMMSettingsFrame:IsVisible()) then
    UMMSettingsFrame:Hide();
  else
    UMMSettingsFrame:Show();
  end
end
