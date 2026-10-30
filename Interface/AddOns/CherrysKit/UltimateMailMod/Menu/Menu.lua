
-- ###################################
-- ##                               ##
-- ##  Main Ultimate Mail Mod Menu  ##
-- ##                               ##
-- ###################################

local hideMailFrame = true;
-- Preserve Tab3's public mass-send names; History is third in visual order.
local TAB_ORDER = {1, 2, 4, 3};

local function positive(fn, ...)
  if (type(fn) ~= "function") then return; end
  local ok, value = pcall(fn, ...);
  if (ok and type(value) == "number" and value > 0 and value < math.huge) then return value; end
end

-- Grow only the mass-send page for its sidebar. Fit the whole window when
-- necessary and keep its screen position inside the viewport at every scale.
function UMMMenuLayout(id)
  local frame = UMMFrame;
  id = id or frame.ummTab or 1;
  frame.ummTab = id;
  local width = id == 3 and 985 or 805;
  local uiScale = positive(GetUIScale) or 1;
  local screenW, screenH = positive(GetScreenWidth), positive(GetScreenHeight);
  if (not screenW) then local w = positive(UIParent.GetWidth, UIParent);screenW = w and w * uiScale; end
  if (not screenH) then local h = positive(UIParent.GetHeight, UIParent);screenH = h and h * uiScale; end
  -- Compare the numbers themselves: this check also runs while the window is open.
  if (width == frame.ummLayoutWidth and uiScale == frame.ummLayoutUIScale
      and screenW == frame.ummLayoutScreenW and screenH == frame.ummLayoutScreenH) then return; end
  frame.ummLayoutWidth, frame.ummLayoutUIScale = width, uiScale;
  frame.ummLayoutScreenW, frame.ummLayoutScreenH = screenW, screenH;
  frame.ummBaseScale = frame.ummBaseScale or positive(frame.GetScale, frame) or 1;
  local ok, x, y;
  if (type(frame.GetPos) == "function") then ok, x, y = pcall(frame.GetPos, frame); end
  frame:SetWidth(width);
  UMMFrameBody:SetWidth(width - 20);
  UMMFrameTab3:SetWidth(960);
  for _, name in ipairs({"UMMFrameStatus", "UMMFrameModVersion"}) do
    local label = getglobal(name);
    if (label) then label:SetWidth(width - 5); end
  end
  local scale = frame.ummBaseScale;
  if (screenW) then scale = math.min(scale, math.max(1, screenW - 8) / width / uiScale); end
  if (screenH) then scale = math.min(scale, math.max(1, screenH - 8) / frame:GetHeight() / uiScale); end
  scale = math.max(.1, scale);
  frame:SetScale(scale);
  if (ok and type(x) == "number" and type(y) == "number") then
    if (screenW) then x = math.max(0, math.min(x, math.max(0, screenW - width * uiScale * scale))); end
    if (screenH) then y = math.max(0, math.min(y, math.max(0, screenH - frame:GetHeight() * uiScale * scale))); end
    frame:ClearAllAnchors();
    frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x / uiScale / scale, y / uiScale / scale);
  end
end

local function SetupTabs(this)
  local i, tab, tabBody, title;
  
  local previous;
  for _, i in ipairs(TAB_ORDER) do
    tab = getglobal(this:GetName().."Tab"..i.."Button");
    tabBody = getglobal(this:GetName().."Tab"..i);
    title = i == 4 and UMM_MENU_HISTORY or getglobal("UMM_MENU_TAB"..i);
    tab:ClearAllAnchors();
    if (i == 1) then
	-- Test Ticket 9 -- release 5.0.1.2553
	  title = (getglobal("UMM_MENU_TAB1").." ("..GetInboxNumItems()..")");	-- release 5.0.1.2553
	-- End of Test ---
      tab:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 10, 30);
    else
      tab:SetAnchor("TOPLEFT", "TOPRIGHT", previous, 0, 0);
    end
    tab:SetText(title);
    PanelTemplates_TabResize(tab, 9.5/GetUIScale())
    tab:Show();
    tabBody:ClearAllAnchors();
    tabBody:SetAnchor("TOPLEFT", "TOPLEFT", "UMMFrameBody", 5, 5);
    previous = tab:GetName();
  end
end

function UMMMenuSelectTab(id)
  if (type(UMMCancelMassSelection) == "function") then UMMCancelMassSelection(); end
  local i, tab, tabBody;
  UMMMenuLayout(id);
  
  for _, i in ipairs(TAB_ORDER) do
    tab = getglobal("UMMFrameTab"..i.."Button");
    tabBody = getglobal("UMMFrameTab"..i);
    if (i == id) then
      UIPanelTab_SetActiveState(tab, true);
      tabBody:Show();
    else
      UIPanelTab_SetActiveState(tab, false);
      tabBody:Hide();
    end
  end
end

function UMMMenuTabTemplate_OnLoad(this)
  this:RegisterForClicks("LeftButton", "RightButton");
end

function UMMMenuTabTemplate_OnClick(this)
  UMMMenuSelectTab(this:GetID());
end

function UMMFrame_OnLoad(this)
  getglobal(this:GetName().."Title"):SetText("|cff"..UMMColor.Medium..UMM_TITLE.."|r");
  SetupTabs(this);
  UMMMenuLayout(1);
  
  this.CheckSetting = function(self, checkBox, entry)
    if (checkBox:IsChecked()) then
      UMMSettings:Set(entry, true);
    else
      UMMSettings:Set(entry, false);
    end
  end;
  
end

function UMMFrame_OnShow(this)
  UMMFriends:Load();
  UMMGlobalInboxLoadTimeout = 2.3;
  getglobal(this:GetName().."Tab1TOC"):HideTOC();
  getglobal(this:GetName().."Tab1Tools"):Hide();
  getglobal(this:GetName().."Tab1Tools"):SetOption(1);
  getglobal(this:GetName().."Tab1InfoLabel"):SetText("|cff"..UMMColor.Medium..UMM_INBOX_LOADING.."|r");
  UMMNormalBar:Init();
  UMMNormalBar:Show();
  if (hideMailFrame) then
    MailFrame:ClearAllAnchors();
    MailFrame:SetAnchor("TOPRIGHT", "TOPLEFT", "UIParent", 0, 110);
  end
  UMMBagManager:Load();
  UMMFriends:Load();
  UMMMenuSelectTab(1);
  if (UMMConfig.Settings.AudioWarning == true) then
    getglobal(this:GetName().."SettingAudioAlert"):SetChecked(1);
  else
    getglobal(this:GetName().."SettingAudioAlert"):SetChecked(nil);
  end
end

function UMMFrame_OnHide(this)
  if (type(UMMCancelMassSelection) == "function") then UMMCancelMassSelection(); end
  -- mailbox closed in the middle of a mail: stop and hand the item back instead of leaving it
  -- stuck in the send slot
  local status = getglobal(this:GetName().."Tab3Status");
  if (status.IsSending and status:IsSending()) then
    status:Stop();
  end
  if (UMMMailComposer:Busy()) then
    UMMMailComposer:Finish("failed", "mailbox closed");
  end
  HideUIPanel(MailFrame);
  UMMMailManager:StopAutomation();
  UMMMailManager:Clear();
  UMMFriends:Clear();
  if (hideMailFrame) then
    MailFrame:ClearAllAnchors();
    MailFrame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", 0, 110);
  end
  getglobal(this:GetName().."Tab1Tools"):Hide();
  getglobal(this:GetName().."Tab1TOC"):HideTOC();
  getglobal(this:GetName().."Tab2Composer"):ClearAllEditFocus();
  getglobal(this:GetName().."Tab3Status"):Clear();
end
