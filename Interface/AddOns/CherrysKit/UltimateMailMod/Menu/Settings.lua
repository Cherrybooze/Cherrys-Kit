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
};

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
end

function UMMSettingsUI_Refresh()
  if (not UMMConfig) then
    return;
  end
  for i, row in ipairs(ROWS) do
    getglobal("UMMSettingsFrameRow"..i.."Value"):SetText(string.format(row[6], Get(i)));
  end
  for i, check in ipairs(CHECKS) do
    getglobal("UMMSettingsFrameCheck"..i):SetChecked(check[2]() and 1 or nil);
  end
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
    UMMPrompt("send settings back to defaults");
    UMMSettingsUI_Refresh();
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
