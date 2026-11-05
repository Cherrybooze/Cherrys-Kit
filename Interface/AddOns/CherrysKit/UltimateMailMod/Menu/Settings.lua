-- Cherry's Kit: Ultimate Mail Mod settings window. /umm opens it (also the hub's Settings
-- button). Every option here is also a /umm command; both write UMMConfig.Settings.

local function default(name, text)
  if (_G[name] == nil) then _G[name] = text; end
end

default("UMM_SET_HEAD_SPEED", "Sending speed");
default("UMM_SET_HEAD_GOLD", "Gold presets");
default("UMM_SET_HEAD_WINDOW", "Mail window");
default("UMM_SET_HEAD_OPTIONS", "Options");
default("UMM_SET_HEAD_TOOLS", "Tools");
default("UMM_SET_FAST", "Send fast: wait between mails");
default("UMM_SET_SAFE", "Send safely: wait between mails");
default("UMM_SET_BATCH", "Send safely: pause after");
default("UMM_SET_PAUSE", "Send safely: pause for");
default("UMM_SET_RETRIES", "Send safely: tries again");
default("UMM_SET_SECONDS", "%s s");
default("UMM_SET_MAILS", "%s mails");
default("UMM_SET_NEVER", "never");
default("UMM_SET_TIMES", "%sx");
default("UMM_SET_DEFAULT_WAS", "Default: %s. Now: %s.");
default("UMM_SET_TIP_FAST", "Seconds between two mails when you click Send fast. Lower is quicker, but past about 60 quick mails the server may drop the connection. Also /umm fastdelay.");
default("UMM_SET_TIP_SAFE", "Seconds between two mails when you click Send safely (the green Send button). Higher is gentler on the connection. Also /umm delay.");
default("UMM_SET_TIP_BATCH", "Send safely takes a break after this many mails. 0 = no breaks. Also /umm batch.");
default("UMM_SET_TIP_PAUSE", "How long Send safely's break lasts, in seconds. Also /umm batch.");
default("UMM_SET_TIP_RETRIES", "How often Send safely tries a mail again when the game refuses it, before it gives up on that mail and stops. Also /umm retries.");
default("UMM_SET_SPEEDDEFAULTS", "Default speeds");
default("UMM_SET_TIP_SPEEDDEFAULTS", "Puts the five sending speed values back to their defaults. Nothing else changes.");
default("UMM_SET_SPEEDS_RESET", "sending speeds back to defaults");
default("UMM_SET_SLOTCHECK", "Wait for item in send slot");
default("UMM_SET_TIP_SLOTCHECK", "On (the default): a mail goes out only once the game shows its item in the send slot, so no mail leaves empty or with the wrong item. Also /umm slotcheck on|off.");
default("UMM_SET_SOUND", "Sound on new mail");
default("UMM_SET_TIP_SOUND", "Plays a sound when new mail arrives. Also /umm sound.");
default("UMM_SET_EVENTS", "Mail events in chat");
default("UMM_SET_TIP_EVENTS", "Writes every step of sending into chat as it happens (for finding problems). Off after a Reload UI. Also /umm trace on|off.");
default("UMM_SET_TIP_SAVEPRESETS", "Saves both gold presets. Enter in a box saves too.");
default("UMM_SET_CHECK", "Run check");
default("UMM_SET_TIP_CHECK", "Prints what UMM sees right now (mailbox, send slot, cursor, pacing) into chat. Also /umm x.");
default("UMM_SET_TRACE", "Show trace");
default("UMM_SET_TIP_TRACE", "Prints the last 30 mail events into chat, to share when something went wrong. Also /umm trace.");
default("UMM_SET_DEFAULTS", "All defaults");
default("UMM_SET_TIP_DEFAULTS", "Puts every setting in this window back to its default: speeds, window size, the boxes on the right and the gold presets.");
default("UMM_SET_RESET", "Forget own chars");
default("UMM_SET_TIP_RESET", "Forgets the list of your characters on this server (asks first). It fills again as you log in, and from the login screen's list.");

-- number rows: setting, label, step, low, high, format, tooltip
local ROWS = {
  { "FastDelay",  UMM_SET_FAST,    0.1, 0.1, 10,  "%.1f", UMM_SET_TIP_FAST,    UMM_SET_SECONDS },
  { "SendDelay",  UMM_SET_SAFE,    0.1, 0.2, 10,  "%.1f", UMM_SET_TIP_SAFE,    UMM_SET_SECONDS },
  { "BatchSize",  UMM_SET_BATCH,   5,   0,   200, "%d",   UMM_SET_TIP_BATCH,   UMM_SET_MAILS },
  { "BatchPause", UMM_SET_PAUSE,   1,   0,   120, "%d",   UMM_SET_TIP_PAUSE,   UMM_SET_SECONDS },
  { "MaxRetries", UMM_SET_RETRIES, 1,   0,   10,  "%d",   UMM_SET_TIP_RETRIES, UMM_SET_TIMES },
  { "WindowScale", UMM_SETTINGS_SCALE, 0.05, UMM_WINDOW_SCALE_LOW, UMM_WINDOW_SCALE_HIGH, "%.2f", UMM_SETTINGS_TIP_SCALE },
};
local SCALE_ROW = 6;
local SPEED_ROWS = 5;   -- rows 1-5: the "Default speeds" button

-- check boxes: label, read, write, tooltip
local CHECKS = {
  { UMM_SET_SLOTCHECK,
    function() return UMMSettings:Get("NoSlotCheck") ~= true end,
    function(on) UMMSettings:Set("NoSlotCheck", not on) end, UMM_SET_TIP_SLOTCHECK },
  { UMM_SET_SOUND,
    function() return UMMSettings:Get("AudioWarning") == true end,
    function(on)
      UMMSettings:Set("AudioWarning", on and true or false);
      local box = getglobal("UMMFrameSettingAudioAlert");
      if (box) then box:SetChecked(on and 1 or nil); end
    end, UMM_SET_TIP_SOUND },
  { UMM_SET_EVENTS,
    function() return UMMTrace.live == true end,
    function(on) UMMTrace.live = on and true or false end, UMM_SET_TIP_EVENTS },
  { UMM_SETTINGS_MAILSHORTCUTS,
    function() return UMMSettings:ShortcutsEnabled() end,
    function(on) UMMSettings:Set("MailShortcuts", on) end, UMM_SETTINGS_TIP_MAILSHORTCUTS },
  { UMM_SETTINGS_CLASSICUI,
    function() return UMMUIStyle() == "classic" end,
    function(on)
      UMMSetUIStyle(on and "classic" or "modern");
      UMMPrompt(string.format(UMM_UI_NOW, on and UMM_UI_CLASSIC or UMM_UI_MODERN));
    end, UMM_SETTINGS_TIP_CLASSICUI },
  { UMM_SETTINGS_AUTOLIST,
    function() return UMMAutoNameList() end,
    function(on) UMMSettings:Set("AutoNameList", on and true or false) end, UMM_SETTINGS_TIP_AUTOLIST },
};

-- section headers: frame part, text
local HEADS = {
  Speed = UMM_SET_HEAD_SPEED, Gold = UMM_SET_HEAD_GOLD, Window = UMM_SET_HEAD_WINDOW,
  Options = UMM_SET_HEAD_OPTIONS, Tools = UMM_SET_HEAD_TOOLS,
};

local goldDirty, refreshingGold = false, false;
local shownGold = {};   -- preset box name -> its text as last grouped

local BUTTONS = {
  Check = UMM_SET_CHECK, Trace = UMM_SET_TRACE, Defaults = UMM_SET_DEFAULTS, Reset = UMM_SET_RESET,
  ConfirmYes = "Yes", ConfirmNo = "No", SpeedDefaults = UMM_SET_SPEEDDEFAULTS,
};
-- button tooltips: frame part, title, text
local BUTTON_TIPS = {
  Check = { UMM_SET_CHECK, UMM_SET_TIP_CHECK }, Trace = { UMM_SET_TRACE, UMM_SET_TIP_TRACE },
  Defaults = { UMM_SET_DEFAULTS, UMM_SET_TIP_DEFAULTS }, Reset = { UMM_SET_RESET, UMM_SET_TIP_RESET },
  SpeedDefaults = { UMM_SET_SPEEDDEFAULTS, UMM_SET_TIP_SPEEDDEFAULTS },
  SavePresets = { UMM_SETTINGS_SAVEPRESETS, UMM_SET_TIP_SAVEPRESETS },
};
-- "Forget own chars" asks first: the question and Yes/No take the place of these buttons.
-- No sits where the clicked button was, so a double click cannot confirm.
local CONFIRM_HIDES = { "Check", "Trace", "Defaults", "Reset" };
local CONFIRM_SHOWS = { "ConfirmText", "ConfirmYes", "ConfirmNo" };

local function Get(i)
  return UMMSendSetting(ROWS[i][1]);
end

-- A row's value as shown: "0.6 s", "20 mails", "3x"; a pause after 0 mails is "never".
local function Shown(i, value)
  local row = ROWS[i];
  local text = string.format(row[6], value);
  if (row[1] == "BatchSize" and value == 0) then return UMM_SET_NEVER; end
  if (row[8]) then text = string.format(row[8], text); end
  return text;
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
  for name, text in pairs(HEADS) do
    getglobal(this:GetName().."Head"..name):SetText(text);
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
    local value = Get(i);
    local label = getglobal("UMMSettingsFrameRow"..i.."Value");
    label:SetText(Shown(i, value));
    -- a changed value stands out from the defaults
    if (label.SetColor) then
      if (math.abs(value - UMM_SEND_DEFAULTS[row[1]]) < 0.001) then
        label:SetColor(1, 0.82, 0);
      else
        label:SetColor(0.45, 1, 0.55);
      end
    end
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

local function tip(this, title, text)
  if (not GameTooltip) then return; end
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
  GameTooltip:SetText(title);
  GameTooltip:AddLine(text, 1, 1, 1);
  GameTooltip:Show();
end

function UMMSettingsUI_StyleTip(this)
  tip(this, UMM_SETTINGS_CLASSICUI, UMM_SETTINGS_TIP_CLASSICUI);
end

function UMMSettingsUI_ListTip(this)
  tip(this, UMM_SETTINGS_AUTOLIST, UMM_SETTINGS_TIP_AUTOLIST);
end

-- A number row's tooltip: what it does, its default and its value now.
function UMMSettingsUI_RowTip(this)
  local i = this:GetID();
  local row = ROWS[i];
  if (not row or not GameTooltip) then return; end
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
  GameTooltip:SetText(row[2]);
  GameTooltip:AddLine(row[7], 1, 1, 1);
  GameTooltip:AddLine(string.format(UMM_SET_DEFAULT_WAS, Shown(i, UMM_SEND_DEFAULTS[row[1]]), Shown(i, Get(i))), 0.6, 0.8, 1);
  GameTooltip:Show();
end

-- Every part of the window points here on mouse over: rows, check boxes and buttons.
function UMMSettingsUI_Tip(this)
  local name = this:GetName() or "";
  local part = string.gsub(name, "^UMMSettingsFrame", "");
  local hover = getglobal(name.."Hover");
  if (hover) then hover:Show(); end
  if (string.find(part, "^Row%d+$")) then
    UMMSettingsUI_RowTip(this);
  elseif (string.find(part, "^Check%d+$")) then
    local check = CHECKS[this:GetID()];
    if (check) then tip(this, check[1], check[4]); end
  elseif (BUTTON_TIPS[part]) then
    tip(this, BUTTON_TIPS[part][1], BUTTON_TIPS[part][2]);
  end
end

function UMMSettingsUI_Leave(this)
  local hover = getglobal((this:GetName() or "").."Hover");
  if (hover) then hover:Hide(); end
  if (GameTooltip) then GameTooltip:Hide(); end
end

function UMMSettingsUI_Step(i, direction)
  local row = ROWS[i];
  local value = Get(i) + direction * row[3];
  value = math.floor(value / row[3] + 0.5) * row[3];   -- no 0.30000000004
  value = math.max(row[4], math.min(row[5], value));
  UMMSettings:Set(row[1], value);
  UMMSettingsUI_Refresh();
  if (i == SCALE_ROW) then UMMApplyWindowScale(); end
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
  elseif (action == "speeds") then
    for i = 1, SPEED_ROWS do
      UMMSettings:Set(ROWS[i][1], UMM_SEND_DEFAULTS[ROWS[i][1]]);
    end
    UMMPrompt(UMM_SET_SPEEDS_RESET);
    UMMSettingsUI_Refresh();
  elseif (action == "defaults") then
    for _, row in ipairs(ROWS) do
      UMMSettings:Set(row[1], UMM_SEND_DEFAULTS[row[1]]);
    end
    UMMSettings:Set("NoSlotCheck", false);
    UMMSettings:Set("MailShortcuts", true);
    UMMSettings:Set("AutoNameList", true);
    UMMApplyWindowScale();
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
