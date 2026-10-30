

-- ######################################################################################
-- #                                                    								#
-- #  Ultimate Mail Mod 2                     											#
-- #                                                    								#
-- #  Ultimate Mail Mod (continued)                     								#
-- #                                                    								#
-- #  Version: 6.4.2                                    								#
-- #                                                    								#
-- #  By Jagodragon                                     								#
-- #                                                    								#
-- #     Maxeem of Muinin                               								#
-- #     maxeem@silverlights-muinin.de                  								#
-- #                                                    								#
-- #  Thanks to Ultak                                   								#
-- #                                                    								#
-- #  Credits to:                                       								#
-- #    Shardea of Siochain (EN/EU)                     								#
-- #                                                    								#
-- #      																			    #
-- #  Bearbeitet:   			2021-11-18	Raihir        Lostcluster (Kadmos)          #
-- #                   																    #
-- #  Übersetzung FR.lua:  		2021-11-18	Claralouise   Lostcluster (Kadmos)          #
-- #                                                    								#
-- #                                                    								#
-- #	ItemDB.lua   			2021-11-07		\UltimateMailMod\Library				# 
-- #	DE.lua					2021-11-07		\UltimateMailMod\Locales				#	
-- #	EN.lua					2021-11-07		\UltimateMailMod\Locales				#	
-- #	FR.lua					2021-11-18		\UltimateMailMod\Locales				#	
-- #	MassenSendtItems.lua    2021-07-04		\UltimateMailMod\MassSendItems			#
-- #	MassenSendtItems.xml	2021-05-17		\UltimateMailMod\MassSendItems			#
-- #	Readme.txt				2020-01-19		\UltimateMailMod						#
-- #	Characters.lua			2019-03-15		\UltimateMailMod\Recipient				#
-- #	                                                								#
-- ######################################################################################

-- C:\Program Files (x86)\GameforgeLive\Games\DEU_deu\Runes Of Magic\interface\addons\UltimateMailMod\Recipient\
 
UMM_VERSION = {
  Major     = " Raihir ",		-- 7
  Minor     = 0,
  Revision  = 2,
  Build     = 20211118,	-- 2787
  ummRev    = '023-ck9';	-- Cherry's Kit 2026-10-30
}

-- ##### Local Variables #####

local ModEnabled  = false;

-- ##### Memory Cleanup #####

local SETTING_GarbageCollectTime  = 900; -- seconds
local GarbageCollectionTimeout    = SETTING_GarbageCollectTime;

local function CheckGarbageCollection()
  if (GetPlayerCombatState()) then
    GarbageCollectionTimeout = 1;
  else
    collectgarbage();
    GarbageCollectionTimeout = SETTING_GarbageCollectTime;
  end
end


-- ##### New Mail Icon Handling #####

function UMMNewMailButton_OnLoad(this)
  
  this.flashLevel = 0;
  
  this.CheckStatus = function(self, silent)
    local number = UMMSettings:NewMail();
    if (number) then
      if (number > 0) then
        getglobal(self:GetName().."Flash"):Show();
        self:Show();
        if (not silent) then
          self.flashLevel = 1;
          WarningFrame:AddMessage(UMM_NOTIFY_NEWMAILARRIVED, 0.48, 0.69, 0.86);
          if (UMMSettings:Get("AudioWarning") == true) then
            -- Play the sound warning if settings allow it
            PlaySoundByPath(UMMPath.."Sound/NewMail.wav")
          end
        end
      else
        self:Hide();
      end
    else
      self:Hide();
    end
  end;
  
  this.Enter = function(self)
    local number = UMMSettings:NewMail();
    if (number ~= nil) then
      if (number > 0) then
        GameTooltip:ClearLines();
        GameTooltip:ClearAllAnchors();
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 0);
        GameTooltip:AddLine("|cff"..UMMColor.Header..UMM_NOTIFY_TOOLTIP_TITLE.."|r");
        if (number == 1) then
          GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_NOTIFY_TOOLTIP_NEWMAIL.."|r");
        else
          GameTooltip:AddLine("|cff"..UMMColor.Bright..string.format(UMM_NOTIFY_TOOLTIP_NEWMAILS, number).."|r");
        end
        GameTooltip:AddLine("|cff"..UMMColor.Dark..UMM_NOTIFY_TOOLTIP_MOVETIP.."|r");
        GameTooltip:Show();
      end
    end
  end;
  
  this.Leave = function(self)
    GameTooltip:Hide();
  end;
  
  this.Update = function(self, this, elapsedTime)
    if (self.flashLevel > 0) then
      self.flashLevel = self.flashLevel - elapsedTime;
      if (self.flashLevel >= 0 and self.flashLevel <= 1) then
        getglobal(self:GetName().."Flash"):SetAlpha(self.flashLevel);
      end
      if (self.flashLevel <= 0) then
        self.flashLevel = 0;
      end
    end
  end;
  
end

-- ##### Master Frame Handling ######

local function KitDisabled()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("UltimateMailMod");
end

-- Is a mass send or a single mail in progress?
local function Sending()
  if (UMMMailComposer:Busy()) then
    return true;
  end
  local status = getglobal("UMMFrameTab3Status");
  return status ~= nil and status.IsSending ~= nil and status:IsSending();
end
UMMIsSending = Sending;

-- With the mailbox closed and nothing sending or waiting, the master frame has nothing to do
-- each frame: it then runs twice a second with the frame times added up. Any event wakes it.
local IDLE_TIME = 0.5;
local idleElapsed = 0;
local idle = false;

local function IsIdle()
  return not MailFrame:IsVisible() and not UMMFrame:IsVisible() and not Sending()
    and UMMGlobalTimeout <= 0 and UMMGlobalFailTimeout <= 0 and UMMGlobalInboxLoadTimeout <= 0;
end

function UMMMasterFrame_OnEvent(event, arg1, arg2, arg3, arg4)
  idle = false;
  if (event == "VARIABLES_LOADED") then
    if (KitDisabled()) then
      -- turned off in the Cherry's Kit hub: leave the game's own mail window alone
      ModEnabled = false;
      return;
    end
    ModEnabled = true;
    UMMBagManager:Invalidate();
    UMMSettings:Init();
    if (AddonManager or CherrysKit) then
      -- Skip displaying the prompt for those running AddonManager or Cherry's Kit
    else
      UMMPrompt(UMM_TITLE.." v"..UMM_VERSION.Major.."."..UMM_VERSION.Minor.."."..UMM_VERSION.Revision.." ("..UMM_VERSION.Build..")."..UMM_VERSION.ummRev..""..UMM_LOADED);
    end
    return;
  end
  if (ModEnabled ~= true) then
    return;
  end
  if (event == "LOADING_END") then
    UMMSettings:CheckCharacter();
    UMMNewMailButton:CheckStatus();
  elseif (event == "MAIL_SHOW") then
    UMMSettings:CheckCharacter();
    ShowUIPanel(UMMFrame);
  elseif (event == "MAIL_INBOX_UPDATE") then
    -- Reload the inbox
    UMMMailManager:InboxRefresh();
    UMMGlobalInboxLoadTimeout = 0;
    if (UMMMailManager:InboxShown()) then
      UMMFrameTab1TOC:RefreshTOC();
      UMMFrameTab1TOC:ShowInboxStatus();
    end
  elseif (event == "MAIL_SEND_INFO_UPDATE") then
    UMMTraceAdd(event, UMMMailComposer:State());
    UMMMailComposer:SendInfoUpdated();
  elseif (event == "MAIL_SEND_SUCCESS") then
    UMMTraceAdd(event, UMMMailComposer:State());
    UMMMailComposer:SendCompleted("ok");
  elseif (event == "MAIL_FAILED") then
    UMMTraceAdd(event, tostring(arg1).." "..tostring(UMMMailComposer:State()));
    UMMMailComposer:SendCompleted("failed");
  elseif (event == "PLAYER_BAG_CHANGED") then
    -- Only mark the bag list stale; it is reloaded when read or once the bags settle
    UMMBagManager:Invalidate();
    UMMBagChangedTime = 0;
    -- Inform the MailManager to unlock an item
    UMMMailManager:UnLock("Item");
    -- If inbox automation is running, go on with it
    UMMMailManager:AttachmentSucceeded();
  elseif (event == "PLAYER_MONEY") then
    -- Inform the MailManager to unlock for money
    UMMMailManager:UnLock("Money");
  elseif (event == "CHAT_MSG_SYSTEM") then
    if (arg1 ~= nil and TEXT("SYS_NEW_MAIL") == arg1) then
      -- Pop the "New Mail" icon
      UMMSettings:NewMail(1);
      UMMNewMailButton:CheckStatus();
    elseif (Sending()) then
      UMMTraceAdd("system", arg1);
    end
  elseif (event == "WARNING_MESSAGE") then
    if (Sending()) then
      UMMTraceAdd("warning", arg1);
    end
    if (TEXT("SYS_GAMEMSGEVENT_750") == arg1 or TEXT("ASK_BACKPACK_FULL") == arg1) then
      -- Safety check on empty bags before stopping (release 5.0.3.2575)
      if (UMMBagManager:HasEmptySlot()) then
        return;
      end
      UMMPrompt("|r|cff"..UMMColor.Red..BAG_OVERFLOW);
      UMMMailManager:StopAutomation();
      UMMSetGlobalFailTimeout("UMMMailManager");
      UMMGlobalFailTimeout = 0.75;
    end
  end
end

function UMMMasterFrame_OnLoad(this)
  this:RegisterEvent("VARIABLES_LOADED");
  this:RegisterEvent("LOADING_END");
  this:RegisterEvent("MAIL_SHOW");
  this:RegisterEvent("MAIL_INBOX_UPDATE");
  this:RegisterEvent("MAIL_SEND_INFO_UPDATE");
  this:RegisterEvent("MAIL_SEND_SUCCESS");
  this:RegisterEvent("MAIL_FAILED");
  this:RegisterEvent("CLOSE_INBOX_ITEM");
  this:RegisterEvent("PLAYER_BAG_CHANGED");
  this:RegisterEvent("CHAT_MSG_SYSTEM");
  this:RegisterEvent("CHAT_MSG_SYSTEM_GET");
  this:RegisterEvent("WARNING_MESSAGE");
  this:RegisterEvent("PLAYER_MONEY");
  UMMFrame_OnLoad(UMMFrame);
end

local TimeSinceLastUpdate = 0;
UMMBagChangedTime = 0;
local BAG_SETTLE_TIME = 0.15;  -- redraw the bag view this long after the last bag change
-- Opening the window and changing tabs lay it out at once; while it stays open,
-- screen size and UI scale changes are picked up within this many seconds.
local LAYOUT_CHECK_TIME = 0.5;
local layoutCheckWait = 0;

function UMMMasterFrame_OnUpdate(this, elapsedTime)
  if (ModEnabled ~= true) then
    return;
  end
  idleElapsed = idleElapsed + elapsedTime;
  if (idle and idleElapsed < IDLE_TIME) then
    return;
  end
  elapsedTime, idleElapsed = idleElapsed, 0;
  UMMClock = UMMClock + elapsedTime;
  if (UMMFrame:IsVisible()) then
    layoutCheckWait = layoutCheckWait - elapsedTime;
    if (layoutCheckWait <= 0) then
      layoutCheckWait = LAYOUT_CHECK_TIME;
      UMMMenuLayout();
    end
  end
  if (UMMFrame:IsVisible() and not MailFrame:IsVisible()) then
    HideUIPanel(UMMFrame);
    UMMComposeConfirm:Clear();
  end
  -- mail sending state machines
  UMMMailComposer:Tick(elapsedTime);
  UMMFrameTab3Status:Tick(elapsedTime);
  -- redraw the mass send bag view once the bags stop changing
  if (UMMBagManager:IsDirty() and UMMFrameTab3Bags:IsShownBags()) then
    UMMBagChangedTime = UMMBagChangedTime + elapsedTime;
    if (UMMBagChangedTime >= BAG_SETTLE_TIME and UMMFrame:IsVisible()) then
      UMMFrameTab3Bags:PopulateBags();
    end
  end
  TimeSinceLastUpdate = TimeSinceLastUpdate + elapsedTime;
  if (TimeSinceLastUpdate >= 1) then
    TimeSinceLastUpdate = 0;
    GarbageCollectionTimeout = GarbageCollectionTimeout - 1;
    if (GarbageCollectionTimeout <= 0) then
      if (Sending()) then
        GarbageCollectionTimeout = 30;  -- no full collection in the middle of sending
      else
        CheckGarbageCollection();
      end
    end
  end
  if (UMMGlobalTimeoutCallFunction ~= nil) then
    if (UMMGlobalTimeout > 0) then
      UMMGlobalTimeout = UMMGlobalTimeout - elapsedTime;
      if (UMMGlobalTimeout <= 0) then
        UMMGlobalTimeout = 0;
        UMMGlobalFailTimeout = 0;
        getglobal(UMMGlobalTimeoutCallFunction):TimeOut();
      end
    end
  end
  if (UMMGlobalFailTimeoutCallFunction ~= nil) then
    if (UMMGlobalFailTimeout > 0) then
      UMMGlobalFailTimeout = UMMGlobalFailTimeout - elapsedTime;
      if (UMMGlobalFailTimeout <= 0) then
        UMMGlobalFailTimeout = 0;
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_AUTOMATIONFAILED);
        getglobal(UMMGlobalFailTimeoutCallFunction):TimeOutFailed();
      end
    end
  end
  if (UMMGlobalInboxLoadTimeout > 0) then
    UMMGlobalInboxLoadTimeout = UMMGlobalInboxLoadTimeout - elapsedTime;
    if (UMMGlobalInboxLoadTimeout <= 0) then
      UMMGlobalInboxLoadTimeout = 0;
      UMMMasterFrame_OnEvent("MAIL_INBOX_UPDATE");
    end
  end
  idle = IsIdle();
end

-- ##### Slash command handling #####

local function SetNumber(name, value, low, high)
  local n = tonumber(value);
  if (n == nil or n < low or n > high) then
    return false;
  end
  UMMSettings:Set(name, n);
  return true;
end

local function PrintPacing()
  UMMPrompt(string.format("Send fast: %.1f s between mails. Send safely: %.1f s between mails, %.0f s pause every %d mails, %d retries",
    UMMSendSetting("FastDelay"), UMMSendSetting("SendDelay"), UMMSendSetting("BatchPause"), UMMSendSetting("BatchSize"), UMMSendSetting("MaxRetries")));
end

local function ShowHelp()
  UMMPrompt(UMM_SLASH_HELP1);
  UMMPrompt("/umm : settings window   /umm help : this list");
  UMMPrompt(UMM_SLASH_HELP2);
  UMMPrompt(UMM_SLASH_HELP3);
  UMMPrompt("/umm fastdelay <seconds> : Send fast, wait between two mails (0.1 - 10)");
  UMMPrompt("/umm delay <seconds> : Send safely, wait between two mails (0.2 - 10)");
  UMMPrompt("/umm batch <mails> <seconds> : pause after that many mails (0 = never)");
  UMMPrompt("/umm retries <n> : tries again this often before stopping (0 - 10)");
  UMMPrompt("/umm stop : stop a mass send after the current mail");
  UMMPrompt("/umm trace [on|off|clear|all] : the last mail events, for finding problems");
  UMMPrompt("/umm x : check (probe) - mail slot, cursor and send state");
  UMMPrompt("/umm slotcheck on|off : wait for the item to show in the send slot (default on)");
  UMMPrompt("/umm shortcuts on|off : Use last and gold preset buttons (default on)");
  UMMPrompt("/umm gold <amount1> <amount2> : set both shared gold presets");
  PrintPacing();
end
UMMShowHelp = ShowHelp;

-- /umm x: everything the send code relies on, read straight from the game
local function Probe()
  local a, b, c, d = nil, nil, nil, nil;
  if (GetSendMailItem) then
    a, b, c, d = GetSendMailItem();
  end
  UMMPrompt("probe ("..(UMM_VERSION.ummRev or "")..")");
  UMMPrint("GetSendMailItem() = "..tostring(a)..", "..tostring(b)..", "..tostring(c)..", "..tostring(d));
  UMMPrint("send slot has item: "..tostring(UMMSendSlotHasItem()).."   cursor has item: "..tostring(UMMCursorHasItem()));
  UMMPrint("CursorHasItem "..tostring(CursorHasItem ~= nil)..", ItemClipboard_Clear "..tostring(ItemClipboard_Clear ~= nil)..", GetSendMailItem "..tostring(GetSendMailItem ~= nil));
  UMMPrint("composer state: "..tostring(UMMMailComposer:State()).."   quiet for "..string.format("%.1f", UMMMailComposer:QuietTime()).." s   sending: "..tostring(Sending()));
  local send, bound = UMMBagManager:CountMarked();
  UMMPrint("marked: "..send.." to send, "..bound.." bound   mail window open: "..tostring(MailFrame and MailFrame:IsVisible()));
  UMMPrint("kit: "..tostring(CherrysKit ~= nil).."   enabled: "..tostring(ModEnabled).."   path: "..tostring(UMMPath));
  PrintPacing();
  UMMPrint("Tip: put an item in the game's send slot, then /umm x again: 'send slot has item' should say true.");
end

SLASH_UMM1 = "/umm";
SlashCmdList["UMM"] = function(editBox, msg)
  msg = string.lower(msg or "");
  local cmd, rest = string.match(msg, "^%s*(%S*)%s*(.-)%s*$");
  local arg1, arg2 = string.match(rest or "", "^(%S*)%s*(%S*)");
  if (cmd == nil or cmd == "") then
    if (ModEnabled == true) then
      UMMSettingsUI_Toggle();
    else
      UMMPrompt("Ultimate Mail Mod is turned off in Cherry's Kit (/ck).");
    end
  elseif (cmd == "help") then
    ShowHelp();
  elseif (cmd == "sound") then
    if (UMMSettings:Get("AudioWarning") == true) then
      UMMSettings:Set("AudioWarning", false);
      UMMPrompt(UMM_SLASH_AUDIODISABLED);
    else
      UMMSettings:Set("AudioWarning", true);
      UMMPrompt(UMM_SLASH_AUDIOENABLED);
    end
  elseif (cmd == "reset") then
    UMMConfig.Characters = {};
    UMMSettings:CheckCharacter();
    UMMSettings:Save();
    UMMPrompt(UMM_SLASH_CHARSRESET);
  elseif (cmd == "delay") then
    if (not SetNumber("SendDelay", arg1, 0.2, 10)) then
      UMMPrompt("/umm delay <0.2 - 10>");
    end
    PrintPacing();
  elseif (cmd == "fastdelay") then
    if (not SetNumber("FastDelay", arg1, 0.1, 10)) then
      UMMPrompt("/umm fastdelay <0.1 - 10>");
    end
    PrintPacing();
  elseif (cmd == "batch") then
    if (not SetNumber("BatchSize", arg1, 0, 200) or (arg2 ~= "" and not SetNumber("BatchPause", arg2, 0, 120))) then
      UMMPrompt("/umm batch <mails 0 - 200> <seconds 0 - 120>");
    end
    PrintPacing();
  elseif (cmd == "retries") then
    if (not SetNumber("MaxRetries", arg1, 0, 10)) then
      UMMPrompt("/umm retries <0 - 10>");
    end
    PrintPacing();
  elseif (cmd == "stop") then
    if (UMMFrameTab3Status:IsSending()) then
      UMMFrameTab3Status:Stop();
    elseif (UMMMailComposer:Busy()) then
      UMMMailComposer:Abort();
    else
      UMMPrompt("nothing is being sent");
    end
  elseif (cmd == "trace") then
    if (arg1 == "on") then
      UMMTrace.live = true;
      UMMPrompt("trace: printing mail events live");
    elseif (arg1 == "off") then
      UMMTrace.live = false;
      UMMPrompt("trace: live printing off (still recorded)");
    elseif (arg1 == "clear") then
      UMMTraceClear();
      UMMPrompt("trace cleared");
    elseif (arg1 == "all") then
      UMMTraceDump(200);
    else
      UMMTraceDump(30);
    end
  elseif (cmd == "slotcheck") then
    UMMSettings:Set("NoSlotCheck", arg1 == "off");
    UMMPrompt("send slot check: "..((arg1 == "off") and "off" or "on"));
  elseif (cmd == "shortcuts") then
    if (arg1 == "on" or arg1 == "off") then UMMSettings:Set("MailShortcuts", arg1 == "on"); end
    UMMPrompt("mail shortcuts: "..(UMMSettings:ShortcutsEnabled() and "on" or "off").." (/umm shortcuts on|off)");
    if (type(UMMSettingsUI_Refresh) == "function") then UMMSettingsUI_Refresh(); end
  elseif (cmd == "gold") then
    if (arg1 ~= "" and not UMMSettings:SetGoldPresets(arg1, arg2)) then UMMPrompt(UMM_SETTINGS_PRESETERROR); end
    UMMPrompt("gold presets: "..UMMFormatNumber(UMMSettings:GoldPreset(1)).." / "..UMMFormatNumber(UMMSettings:GoldPreset(2)));
    if (type(UMMSettingsUI_Refresh) == "function") then UMMSettingsUI_Refresh(true); end
  elseif (cmd == "x" or cmd == "probe") then
    Probe();
  else
    ShowHelp();
  end
end

-- ##### Cherry's Kit hub entry #####

if (CherrysKit and CherrysKit.Register) then
  CherrysKit.Register({
    folder = "UltimateMailMod",
    title = "Ultimate Mail Mod",
    version = UMM_VERSION.ummRev,
    installed = function()
      return true;
    end,
    open = function()
      -- the mail window itself opens at a mailbox; this is its settings window
      UMMSettingsUI_Toggle();
      return true;
    end,
  });
end
