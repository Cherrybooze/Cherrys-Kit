
-- #########################
-- ##                     ##
-- ##  New Mail Composer  ##
-- ##                     ##
-- #########################
--
-- Cherry's Kit rewrite of the send sequence. The old one moved to "send" on ANY
-- MAIL_SEND_INFO_UPDATE, so a late update left over from the previous mail could fire SendMail
-- before the next item was attached. The item then stayed in the send slot or on the cursor,
-- every following attach swapped items around, MAIL_FAILED was treated like success, and the
-- 10 second fail timer only forgot its state without giving the item back. After enough mails
-- in a row the mail system was stuck until relog.
--
-- Now every mail is one state machine, driven by UMMMailComposer:Tick from the master frame:
--   attaching  item picked up and dropped on the send slot; wait until the game confirms it
--              (send info update seen AFTER the attach, cursor empty, slot holds an item)
--   sending    SendMail called; wait for MAIL_SEND_SUCCESS or MAIL_FAILED (with a time limit)
-- Any failure takes the item back out of the send slot / off the cursor and reports "failed".

local ATTACH_TIMEOUT = 6;   -- seconds to wait for the attachment to show up
local SEND_TIMEOUT   = 15;  -- seconds to wait for the server to answer SendMail

local composers = {}; -- fixed XML-created compose/reply forms, keyed by name

function UMMMailShortcutsBusy()
  return (UMMMailComposer and UMMMailComposer:Busy()) or (type(UMMIsSending) == "function" and UMMIsSending());
end

function UMMRefreshMailShortcuts()
  for _, composer in pairs(composers) do composer:RefreshShortcuts(); end
  if (type(UMMHistory_Refresh) == "function") then UMMHistory_Refresh(); end
end

function UMMComposeShortcutTooltip(button, kind, index)
  if (not GameTooltip) then return; end
  GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 0, 0);
  if (kind == "last") then
    GameTooltip:SetText(UMM_COMPOSER_USELAST);
    GameTooltip:AddLine(UMM_COMPOSER_TIP_USELAST, 1, 1, 1);
    GameTooltip:AddLine(UMMSettings:LastRecipient() or UMM_HISTORY_EMPTY, 1, 0.8, 0);
  else
    local amount = UMMSettings:GoldPreset(index);
    GameTooltip:SetText(string.format(UMM_SETTINGS_GOLDPRESET, index));
    GameTooltip:AddLine(string.format(UMM_COMPOSER_TIP_GOLDPRESET, UMMFormatNumber(amount)), 1, 1, 1);
  end
  GameTooltip:Show();
end

UMMClock = 0;               -- seconds, advanced by the master frame

-- Does the send slot hold an item? nil when the client gives no answer we understand.
function UMMSendSlotHasItem()
  if (not GetSendMailItem) then
    return nil;
  end
  local a, b, c = GetSendMailItem();
  local function filled(v)
    return v ~= nil and v ~= "" and v ~= 0 and v ~= false;
  end
  return (filled(a) or filled(b)) and true or false;
end

function UMMCursorHasItem()
  if (CursorHasItem) then
    return CursorHasItem() and true or false;
  end
  return GetCursorItemInfo and GetCursorItemInfo() ~= nil;
end

UMMMailComposer = {
  
  priv_Recipient          = nil;
  priv_Subject            = nil;
  priv_Body               = nil;
  priv_DefinedCODAmount   = 0;
  priv_AttachedMoney      = 0;
  priv_AttachedItemIndex  = 0;
  priv_ComposerReturn     = nil;
  
  priv_AutoRunning        = nil;
  priv_State              = nil;   -- nil, "attaching", "sending"
  priv_StateTime          = 0;
  priv_InfoSeen           = nil;
  priv_LastInfoTime       = -100;
  priv_LastError          = nil;
  
  ItemIsBound = function(self, index)
    local itemLink = GetBagItemLink(index);
    if (not itemLink) then
      return nil;
    end
    UMMTooltip:SetHyperLink(itemLink);
    UMMTooltip:Hide();
    for i = 1, 40 do
      local lineLeft = getglobal("UMMTooltipTextLeft"..i);
      local lineRight = getglobal("UMMTooltipTextRight"..i);
      if (lineLeft == nil) then
        break;
      end
      local textLeft, textRight = "", "";
      if (lineLeft:IsVisible()) then
        textLeft = lineLeft:GetText() or "";
      end
      if (lineRight and lineRight:IsVisible()) then
        textRight = lineRight:GetText() or "";
      end
      if (string.find(textLeft.." "..textRight, UMM_TOOLTIP_BOUND)) then
        return true;
      end
    end
    return nil;
  end;
  
  Clear = function(self)
    self.priv_Recipient = nil;
    self.priv_Subject = nil;
    self.priv_Body = nil;
    self.priv_DefinedCODAmount = 0;
    self.priv_AttachedMoney = 0;
    self.priv_AttachedItemIndex = 0;
    self.priv_ComposerReturn = nil;
    self.priv_AutoRunning = nil;
    self.priv_State = nil;
    self.priv_InfoSeen = nil;
  end;
  
  SetComposer = function(self, frameName)
    self.priv_ComposerReturn = frameName;
  end;
  
  Recipient = function(self, value)
    if (value) then
      self.priv_Recipient = value;
    else
      return self.priv_Recipient;
    end
  end;
  
  Subject = function(self, value)
    if (value) then
      self.priv_Subject = value;
    else
      return self.priv_Subject;
    end
  end;
  
  Body = function(self, value)
    if (value) then
      self.priv_Body = value;
    else
      return self.priv_Body;
    end
  end;
  
  DefinedCODAmount = function(self, value)
    if (value) then
      self.priv_DefinedCODAmount = value;
    else
      return self.priv_DefinedCODAmount;
    end
  end;
  
  AttachedMoney = function(self, value)
    if (value) then
      self.priv_AttachedMoney = value;
    else
      return self.priv_AttachedMoney;
    end
  end;
  
  AttachedItemIndex = function(self, value)
    if (value) then
      self.priv_AttachedItemIndex = value;
    else
      return self.priv_AttachedItemIndex;
    end
  end;
  
  -- Busy while a mail is being attached or sent
  Busy = function(self)
    return self.priv_State ~= nil;
  end;
  
  State = function(self)
    return self.priv_State;
  end;
  
  -- Seconds since the last MAIL_SEND_INFO_UPDATE
  QuietTime = function(self)
    return UMMClock - self.priv_LastInfoTime;
  end;
  
  SetState = function(self, state)
    self.priv_State = state;
    self.priv_StateTime = 0;
    UMMTraceAdd("state", tostring(state));
  end;
  
  -- Give back whatever a failed mail left behind: the item in the send slot or on the cursor,
  -- and money or C.O.D. typed into the game's send form.
  Recover = function(self)
    local index = self.priv_AttachedItemIndex or 0;
    if (UMMCursorHasItem()) then
      if (index > 0) then
        PickupBagItem(index);
      end
      if (UMMCursorHasItem() and ItemClipboard_Clear) then
        ItemClipboard_Clear();
      end
    end
    if (index > 0 and UMMSendSlotHasItem() ~= false) then
      -- an empty cursor on the send slot takes the item back out
      ClickSendMailItemButton();
      if (UMMCursorHasItem()) then
        PickupBagItem(index);
      end
      if (UMMCursorHasItem() and ItemClipboard_Clear) then
        ItemClipboard_Clear();
      end
    end
    if (self.priv_AttachedMoney > 0 and SetSendMailMoney) then
      SetSendMailMoney(0, 0);
    end
    if (self.priv_DefinedCODAmount > 0 and SetSendMailCOD) then
      SetSendMailCOD(0, 0);
    end
    UMMTraceAdd("recover", "slot="..tostring(UMMSendSlotHasItem()).." cursor="..tostring(UMMCursorHasItem()));
    UMMBagManager:Invalidate();
  end;
  
  -- Ends the current mail and tells the frame that started it
  Finish = function(self, status, reason)
    self.priv_LastError = reason;
    if (status ~= "ok") then
      self:Recover();
    end
    UMMTraceAdd("finish", status..(reason and (" "..reason) or ""));
    local returnFrame = self.priv_ComposerReturn;
    local wasRunning = self.priv_AutoRunning;
    local recipient = status == "ok" and self.priv_State == "sending" and wasRunning and self.priv_Recipient;
    self:Clear();
    if (recipient) then UMMSettings:RememberRecipient(recipient); end
    if (wasRunning and returnFrame) then
      local frame = getglobal(returnFrame);
      if (frame and frame.SendCompleted) then
        frame:SendCompleted(status, reason);
      end
    end
  end;
  
  -- Abort the current mail (only possible before SendMail went out)
  Abort = function(self)
    if (self.priv_State == "attaching") then
      self:Finish("failed", "stopped");
      return true;
    end
    return self.priv_State == nil;
  end;
  
  DoSendMail = function(self)
    if (self.priv_AttachedMoney > 0) then
      SetSendMailMoney(self.priv_AttachedMoney, 0);
    elseif (self.priv_DefinedCODAmount > 0) then
      SetSendMailCOD(self.priv_DefinedCODAmount, 0);
    end
    self:SetState("sending");
    SendMail(self.priv_Recipient, self.priv_Subject, self.priv_Body);
  end;
  
  -- Method that sends the composed mail
  -- Return values :
  --   0 = Mail seems to be in order and an attempt to send the mail was made
  --   1 = Recipient is the same as the current character: can't send
  --   2 = Subject is empty: can't send
  --   3 = Attached item is bound: can't send
  --   4 = Still busy with the previous mail
  Send = function(self)
    if (self.priv_State ~= nil) then
      return 4;
    end
    if (self.priv_Recipient == UnitName("player")) then
      return 1;
    end
    if (self.priv_Subject == nil or self.priv_Subject == "" or self.priv_Subject == "nil") then
      return 2;
    end
    local index = self.priv_AttachedItemIndex;
    if (index > 0) then
      local item = UMMBagManager:GetItem(index);
      if (item and UMMBagManager:IsBound(item)) or (not item and self:ItemIsBound(index)) then
        return 3;
      end
    end
    self.priv_AutoRunning = true;
    self.priv_LastError = nil;
    if (index > 0) then
      if (UMMCursorHasItem() and ItemClipboard_Clear) then
        ItemClipboard_Clear();
      end
      self.priv_InfoSeen = nil;
      self:SetState("attaching");
      PickupBagItem(index);
      ClickSendMailItemButton();
    else
      self:DoSendMail();
    end
    return 0;
  end;
  
  Tick = function(self, elapsedTime)
    if (self.priv_State == nil) then
      return;
    end
    self.priv_StateTime = self.priv_StateTime + elapsedTime;
    if (self.priv_State == "attaching") then
      local slot = UMMSendSlotHasItem();
      local slotOk = (slot == true) or (slot == nil) or (UMMSettings:Get("NoSlotCheck") == true);
      if (self.priv_InfoSeen and slotOk and not UMMCursorHasItem()) then
        self:DoSendMail();
      elseif (self.priv_StateTime > ATTACH_TIMEOUT) then
        self:Finish("failed", "attach");
      end
    elseif (self.priv_State == "sending") then
      if (self.priv_StateTime > SEND_TIMEOUT) then
        self:Finish("failed", "timeout");
      end
    end
  end;
  
  SendInfoUpdated = function(self)
    self.priv_LastInfoTime = UMMClock;
    if (self.priv_State == "attaching") then
      self.priv_InfoSeen = true;
    end
  end;
  
  SendCompleted = function(self, status)
    if (self.priv_State == "sending") then
      self:Finish(status, status ~= "ok" and "server" or nil);
    elseif (self.priv_State == "attaching" and status ~= "ok") then
      -- the server refused the attachment before our SendMail went out
      self:Finish("failed", "server");
    end
  end;
  
  TimeOutFailed = function(self)
    if (self.priv_State) then
      self:Finish("failed", "timeout");
    end
  end;
  
};

function UMMComposeMailTemplate_OnLoad(this)
  
  this.AttachBagSlotIndex = 0;
  this.AttachItemLink     = nil;
  this.AttachItemIcon     = nil;
  this.AttachItemCount    = 0;
  this.AttachMoney        = 0;
  this.CODMoney           = 0;
  this.AutoSubject        = nil;
  this.ComposerDisabled   = false;
  composers[this:GetName()] = this;

  this.RefreshShortcuts = function(self)
    local enabled = UMMSettings:ShortcutsEnabled();
    local busy = self.ComposerDisabled or UMMMailShortcutsBusy();
    local last = getglobal(self:GetName().."HeaderUseLast");
    if (last) then
      last:SetText(UMM_COMPOSER_USELAST);
      if (enabled) then last:Show(); else last:Hide(); end
      if (not busy and UMMSettings:LastRecipient()) then last:Enable(); else last:Disable(); end
    end
    for i = 1, 2 do
      local preset = getglobal(self:GetName().."FooterGoldPreset"..i);
      if (preset) then
        preset:SetText(UMMFormatNumber(UMMSettings:GoldPreset(i)));
        if (enabled) then preset:Show(); else preset:Hide(); end
        if (busy) then preset:Disable(); else preset:Enable(); end
      end
    end
    getglobal(self:GetName().."Footer"):SetHeight(enabled and 112 or 85);
    self:SetHeight(enabled and 505 or 475);
  end;

  this.UseLastRecipient = function(self)
    if (not UMMSettings:ShortcutsEnabled() or self.ComposerDisabled or UMMMailShortcutsBusy()) then return; end
    local recipient = UMMSettings:LastRecipient();
    if (recipient) then self:SetRecipient(recipient); end
  end;

  this.UseGoldPreset = function(self, index)
    if (not UMMSettings:ShortcutsEnabled() or self.ComposerDisabled or UMMMailShortcutsBusy()) then return; end
    local amount = UMMSettings:GoldPreset(index);
    if (not amount) then return; end
    self:SetOption("money", true); -- never put a Send Gold preset into C.O.D.
    getglobal(self:GetName().."FooterMoney"):SetText(string.format("%.0f", amount));
    self:CheckSendStatus();
  end;
  
  this.CheckSendStatus = function(self)
    local recipient = getglobal(self:GetName().."HeaderAuthor"):GetText();
    local subject = getglobal(self:GetName().."HeaderSubject"):GetText();
    if (subject == nil or subject == "" and not self.AutoSubject) then
      if (getglobal(self:GetName().."FooterOptionMoney"):IsChecked()) then
        self.AutoSubject = true;
      end
    end
    if (self.AutoSubject) then
      if (getglobal(self:GetName().."FooterOptionMoney"):IsChecked()) then
        local money = getglobal(self:GetName().."FooterMoney"):GetText();
        if (money ~= nil and money ~= "") then
          local crap = string.format("%d", money + 1);
          crap = crap - 1;
          if (crap > 0) then
            subject = UMM_COMPOSER_AUTOSUBJECT..UMMFormatNumber(money);
            getglobal(self:GetName().."HeaderSubject"):SetText(subject);
          end
        else
          self.AutoSubject = nil;
          getglobal(self:GetName().."HeaderSubject"):SetText("");
        end
      end
    end
    if (recipient ~= nil and recipient ~= "" and subject ~= nil and subject ~= "") then
      getglobal(self:GetName().."Send"):Enable();
    else
      getglobal(self:GetName().."Send"):Disable();
    end
    if (self.AttachBagSlotIndex == 0) then
      getglobal(self:GetName().."FooterOptionCOD"):Disable();
    else
      getglobal(self:GetName().."FooterOptionCOD"):Enable();
    end
  end;
  
  this.SetRecipient = function(self, name)
    getglobal(self:GetName().."HeaderAuthor"):SetText(name);
    self:CheckSendStatus();
  end;
  
  this.SetSubject = function(self, subject)
    getglobal(self:GetName().."HeaderSubject"):SetText(subject);
    self:CheckSendStatus();
  end;
  
  this.SetBody = function(self, body)
    getglobal(self:GetName().."BodyFrameInput"):SetText(body);
    self:CheckSendStatus();
  end;
  
  this.SetReply = function(self, name, subject)
    getglobal(self:GetParent():GetName().."Own"):Hide();
    getglobal(self:GetParent():GetName().."Friends"):Hide();
    getglobal(self:GetParent():GetName().."Guildies"):Hide();
    self:SetRecipient(name);
    self:SetSubject(subject);
    getglobal(self:GetName().."BodyFrameInput"):SetFocus();
    getglobal(self:GetParent():GetName().."ViewerReply"):Disable();
    getglobal(self:GetParent():GetName().."ViewerReturn"):Disable();
    getglobal(self:GetParent():GetName().."ViewerDelete"):Disable();
    getglobal(self:GetParent():GetName().."ViewerClose"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAttachment1"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAttachment2"):Disable();
    getglobal(self:GetParent():GetName().."ViewerFooterAcceptCODCheck"):Disable();
  end;
  
  this.SetOption = function(self, type, dontFocus)
    if (string.lower(type) == "money") then
      getglobal(self:GetName().."FooterOptionMoney"):SetChecked(1);
      getglobal(self:GetName().."FooterMoney"):SetText("");
      getglobal(self:GetName().."FooterMoney"):Show();
      getglobal(self:GetName().."FooterOptionCOD"):SetChecked(nil);
      getglobal(self:GetName().."FooterCOD"):SetText("");
      getglobal(self:GetName().."FooterCOD"):Hide();
      if (not dontFocus) then
        getglobal(self:GetName().."FooterMoney"):SetFocus();
      end
    elseif (string.lower(type) == "cod") then
      getglobal(self:GetName().."FooterOptionMoney"):SetChecked(nil);
      getglobal(self:GetName().."FooterMoney"):SetText("");
      getglobal(self:GetName().."FooterMoney"):Hide();
      getglobal(self:GetName().."FooterOptionCOD"):SetChecked(1);
      getglobal(self:GetName().."FooterCOD"):SetText("");
      getglobal(self:GetName().."FooterCOD"):Show();
      if (not dontFocus) then
        getglobal(self:GetName().."FooterCOD"):SetFocus();
      end
    end
  end;
  
  this.ClearMail = function(self, full)
    if (full) then
      getglobal(self:GetName().."HeaderAuthor"):SetText("");
    end
    self.AttachBagSlotIndex = 0;
    self.AttachItemLink     = nil;
    self.AttachItemIcon     = nil;
    self.AttachItemCount    = 0;
    self.AttachMoney        = 0;
    self.CODMoney           = 0;
    self.AutoSubject        = nil;
    SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), nil);
    SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), nil);
    
    getglobal(self:GetName().."HeaderSubject"):SetText("");
    getglobal(self:GetName().."BodyFrameInput"):SetText("");
    self:SetOption("money", true);
    self:CheckSendStatus();
    if (full) then
      getglobal(self:GetName().."HeaderAuthor"):SetFocus();
    else
      getglobal(self:GetName().."HeaderSubject"):SetFocus();
    end
  
    getglobal(self:GetParent():GetName().."Own"):Show();
    getglobal(self:GetParent():GetName().."Friends"):Show();
    if (IsInGuild()) then
      getglobal(self:GetParent():GetName().."Guildies"):Show();
    else
      getglobal(self:GetParent():GetName().."Guildies"):Hide();
    end
    getglobal(self:GetParent():GetName().."Viewer"):Hide();
    if (not UMMMailComposer:Busy()) then
      UMMMailComposer:Clear();
    end
  end;
  
  this.ClearAllEditFocus = function(self)
    getglobal(self:GetName().."HeaderAuthor"):ClearFocus();
    getglobal(self:GetName().."HeaderSubject"):ClearFocus();
    getglobal(self:GetName().."BodyFrameInput"):ClearFocus();
    getglobal(self:GetName().."FooterMoney"):ClearFocus();
    getglobal(self:GetName().."FooterCOD"):ClearFocus();
  end;
  
  this.DisableComposer = function(self)
    self.ComposerDisabled = true;
    self:ClearAllEditFocus();
    getglobal(self:GetName().."HeaderAuthor"):Disable();
    getglobal(self:GetName().."HeaderSubject"):Disable();
    getglobal(self:GetName().."Reset"):Disable();
    getglobal(self:GetName().."Send"):Disable();
    getglobal(self:GetName().."BodyFrameInput"):Disable();
    getglobal(self:GetName().."FooterAttachment"):Disable();
    getglobal(self:GetName().."FooterOptionMoney"):Disable();
    getglobal(self:GetName().."FooterOptionCOD"):Disable();
    getglobal(self:GetName().."FooterMoney"):Disable();
    getglobal(self:GetName().."FooterCOD"):Disable();
    self:RefreshShortcuts();
  end;
  
  this.EnableComposer = function(self)
    self.ComposerDisabled = false;
    getglobal(self:GetName().."HeaderAuthor"):Enable();
    getglobal(self:GetName().."HeaderSubject"):Enable();
    getglobal(self:GetName().."Reset"):Enable();
    getglobal(self:GetName().."Send"):Enable();
    getglobal(self:GetName().."BodyFrameInput"):Enable();
    getglobal(self:GetName().."FooterAttachment"):Enable();
    getglobal(self:GetName().."FooterOptionMoney"):Enable();
    getglobal(self:GetName().."FooterOptionCOD"):Enable();
    getglobal(self:GetName().."FooterMoney"):Enable();
    getglobal(self:GetName().."FooterCOD"):Enable();
    self:RefreshShortcuts();
  end;
  
  this.Send = function(self)
    if (UMMMailComposer:Busy()) then
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_STILLSENDING);
      return;
    end
    local recipient = getglobal(self:GetName().."HeaderAuthor"):GetText();
    local subject = getglobal(self:GetName().."HeaderSubject"):GetText();
    local body = getglobal(self:GetName().."BodyFrameInput"):GetText();
    UMMMailComposer:Clear();
    UMMMailComposer:SetComposer(self:GetName());
    UMMMailComposer:Recipient(recipient);
    UMMMailComposer:Subject(subject);
    UMMMailComposer:Body(body);
    if (getglobal(self:GetName().."FooterOptionCOD"):IsChecked()) then
      local money = getglobal(self:GetName().."FooterCOD"):GetText();
      if (money ~= nil and money ~= "") then
        local cash = string.format("%d", money + 1);
        cash = cash - 1;
        if (cash > 0) then
          UMMMailComposer:DefinedCODAmount(cash);
        end
      end
    else
      local money = getglobal(self:GetName().."FooterMoney"):GetText();
      if (money ~= nil and money ~= "") then
        local cash = string.format("%d", money + 1);
        cash = cash - 1;
        if (cash > 0) then
          UMMMailComposer:AttachedMoney(cash);
        end
      end
    end
    if (self.AttachBagSlotIndex > 0) then
      UMMMailComposer:AttachedItemIndex(self.AttachBagSlotIndex);
    end
    local result = UMMMailComposer:Send();
    if (result == 0) then
      self:DisableComposer();
    elseif (result == 1) then
      -- Recipient
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDSELF);
      WarningFrame:AddMessage(UMM_ERROR_CANTSENDSELF);
      getglobal(self:GetName().."HeaderAuthor"):SetFocus();
    elseif (result == 2) then
      -- Subject
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_NOSUBJECT);
      WarningFrame:AddMessage(UMM_ERROR_NOSUBJECT);
      getglobal(self:GetName().."HeaderSubject"):SetFocus();
    elseif (result == 4) then
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_STILLSENDING);
    elseif (result == 3) then
      -- Bound
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
      WarningFrame:AddMessage(UMM_ERROR_CANTSENDBOUND);
      self:RemoveAttachment();
    end
  end;
  
  this.SendCompleted = function(self, status)
    self:EnableComposer();
    if (status == "ok") then
      self:ClearMail();
    end
  end;
  
  this.RemoveAttachment = function(self)
    self.AttachBagSlotIndex = 0;
    self.AttachItemLink     = nil;
    self.AttachItemIcon     = nil;
    self.AttachItemCount    = 0;
    SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), nil);
    SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), nil);
    self:SetOption("money", true);
    getglobal(self:GetName().."FooterOptionCOD"):Disable();
  end;
  
  this.AttachItem = function(self, slotIndex)
    local bagSlotIndex = 0;
    slotIndex = GetCursorItemInfo();							-- release 5.0.1.2550
    if (slotIndex ~= nil and slotIndex ~= "") then
      local bsi = string.format("%d", slotIndex + 1);
      bsi = bsi - 1;
      bagSlotIndex = bsi;
    else
      bagSlotIndex = -1;
    end
    if (bagSlotIndex == -1) then
      -- Do nothing
    elseif (bagSlotIndex == 0) then
      UMMPrompt("|r|cff"..UMMColor.Reg.."Internal Frogster bag error ! Please expand your backpack and move a few items.");
    else
      local item = UMMBagManager:GetItem(bagSlotIndex);
      if (item) then
        if (not item.Empty == true) then
          self:RemoveAttachment();
          self.AttachBagSlotIndex = bagSlotIndex;
          self.AttachItemLink = item.Link;
          self.AttachItemIcon = item.Icon;
          self.AttachItemCount = item.Count;
          SetItemButtonTexture(getglobal(self:GetName().."FooterAttachment"), self.AttachItemIcon);
          SetItemButtonCount(getglobal(self:GetName().."FooterAttachment"), self.AttachItemCount);
          PickupBagItem(bagSlotIndex);
          if (item.Count > 1) then
            self:SetSubject(item.Name.." ("..item.Count..")");
          else
            self:SetSubject(item.Name);
          end
          getglobal(self:GetName().."FooterOptionCOD"):Enable();
        end
      end
    end
  end;
  
  this.AttachEnter = function(self)
    if (self.AttachItemLink ~= nil) then
      GameTooltip:ClearAllAnchors();
      GameTooltip:SetAnchor("TOPLEFT", "BOTTOMRIGHT", self:GetName().."FooterAttachment", 2, 0);
      GameTooltip:Show();
      GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
      GameTooltip:SetHyperLink(self.AttachItemLink);
    end
  end;
  
  this.AttachLeave = function(self)
    GameTooltip:Hide();
  end;
  
  this.ViewerClosed = function(self)
    -- Place holder for return signal when the viewer is closed.
  end;
  
  getglobal(this:GetName().."HeaderAuthorLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_ADDRESSEE.."|r");
  getglobal(this:GetName().."HeaderSubjectLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SUBJECT.."|r");
  getglobal(this:GetName().."Reset"):SetText(UMM_COMPOSER_BUTTON_RESET);
  getglobal(this:GetName().."Send"):SetText(UMM_COMPOSER_BUTTON_SEND);
  getglobal(this:GetName().."FooterAttachmentLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_ATTACHMENT.."|r");
  getglobal(this:GetName().."FooterOptionMoneyLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SENDGOLD.."|r");
  getglobal(this:GetName().."FooterOptionCODLabel"):SetText("|cff"..UMMColor.White..UMM_COMPOSER_SENDCOD.."|r");
  this:RefreshShortcuts();
end

function UMMComposeMailTemplate_OnShow(this)
  this:ClearMail(true);
  this:CheckSendStatus();
  this:RefreshShortcuts();
  getglobal(this:GetName().."HeaderAuthor"):SetFocus();
end

function UMMComposeMailTemplate_OnHide(this)
  this:ClearMail();
  this:EnableComposer();
  this:ClearAllEditFocus();
end

function UMMComposeMailTemplateButton_OnClick(this, action)
  if (string.lower(action) == "reset") then
    this:GetParent():ClearMail();
  elseif (string.lower(action) == "send") then
    local moneyAttached = nil;
    local money = getglobal(this:GetParent():GetName().."FooterMoney"):GetText();
    if (money ~= nil and money ~= "") then
      local cash = string.format("%d", money + 1);
      cash = cash - 1;
      if (cash > 0) then
        moneyAttached = tonumber(cash);
      end
    end
    if (moneyAttached) then
      local recipient = getglobal(this:GetParent():GetName().."HeaderAuthor"):GetText();
      UMMComposeConfirm:Clear();
      UMMComposeConfirm:AddLine(UMM_COMPOSER_CONFIRM_TEXT1);
      UMMComposeConfirm:AddLine(string.format(UMM_COMPOSER_CONFIRM_TEXT2, recipient));
      UMMComposeConfirm:SetMoney(moneyAttached);
      UMMComposeConfirm:AddButton(UMM_COMPOSER_CONFIRM_YES, function()
        this:GetParent():Send();
      end);
      UMMComposeConfirm:AddButton(UMM_COMPOSER_CONFIRM_NO);
      UMMComposeConfirm:Pop();
    else
      this:GetParent():Send();
    end
  end
end

function UMMComposeTemplate_OnShow(this)
  UMMFriends:Load();
end

function UMMComposeTemplate_OnHide(this)
  getglobal(this:GetName().."Composer"):EnableComposer();
  getglobal(this:GetName().."Composer"):ClearAllEditFocus();
  UMMComposeConfirm:Clear();
end

-- ##### Names clicked in chat #####
-- With the mail window open, Ctrl+click or Shift+click on a player's name in chat puts it in To
-- (asked for 2026-10-30): Mass Send's recipient while that tab is open, else Compose's To, which
-- opens from the inbox or history tab. Other buttons, other links and a closed mail window are
-- left to the game, and so is a click while a gold confirm or a planned mass send names its
-- recipient, or while the inbox is busy taking mail (its tabs are locked then). Cherry's Chat
-- asks CherrysKit_NameTakers before its own Ctrl/Shift action; the game's chat and other name
-- links (auction sellers) reach Hyperlink_Assign or ChatFrame_OnHyperlinkClick, which
-- UMMHookNameClicks wraps when UMM starts, so nothing is wrapped while UMM is off in the hub.

local function tabLocked(id)
  local tab = getglobal("UMMFrameTab"..id.."Button");
  return tab ~= nil and tab.IsEnable ~= nil and not tab:IsEnable();
end

function UMMUseClickedName(name)
  if (type(name) ~= "string" or name == "" or not UMMFrame or not UMMFrame:IsVisible()) then return false; end
  if (UMMMailShortcutsBusy()) then UMMPrompt(UMM_ERROR_STILLSENDING);return true; end
  if (UMMComposeConfirm:IsVisible()) then return false; end
  if (UMMFrameTab3:IsVisible()) then
    if (getglobal("UMMFrameTab3Status"):IsVisible()) then return false; end
    UMMCancelMassSelection();
    local chooser = getglobal("UMMFrameTab3Recipient");
    if (not UMMFrameTab3Bags:IsVisible()) then chooser:ShowBody(); end
    local field = getglobal(chooser:GetName().."Recipient");
    field:SetText(name);
    field:SetFocus();
    getglobal("UMMFrameTab3Action"):CheckStatus();
    return true;
  end
  if (not UMMFrameTab2:IsVisible()) then
    if (tabLocked(2)) then return false; end
    UMMMenuSelectTab(2);
  end
  UMMFrameTab2Composer:SetRecipient(name);
  getglobal(UMMFrameTab2Composer:GetName().."HeaderSubject"):SetFocus();
  return true;
end

CherrysKit_NameTakers = CherrysKit_NameTakers or {};
CherrysKit_NameTakers.UltimateMailMod = function(name) return UMMUseClickedName(name); end;

local function playerIn(value)
  if (type(value) ~= "string") then return nil; end
  return string.match(value, "|Hplayer:([^|:]+)") or string.match(value, "^player:([^|:]+)");
end

local OTHER_BUTTONS = { RBUTTON = true, MBUTTON = true, RightButton = true, MiddleButton = true };

-- The player's name in a left click's link. The game passes the link and button as arguments;
-- a handler called without any falls back to arg1 and arg2, as XML event handlers get them.
local function clickedName(...)
  local name, otherButton, sawText = nil, false, false;
  for i = 1, select("#", ...) do
    local value = select(i, ...);
    if (type(value) == "string") then
      sawText = true;
      otherButton = otherButton or OTHER_BUTTONS[value] == true;
      name = name or playerIn(value);
    end
  end
  if (not sawText) then
    name = playerIn(arg1) or playerIn(arg2);
    otherButton = OTHER_BUTTONS[arg1] == true or OTHER_BUTTONS[arg2] == true;
  end
  if (otherButton) then return nil; end
  return name;
end

local function modifierDown()
  return (type(IsCtrlKeyDown) == "function" and IsCtrlKeyDown()) or (type(IsShiftKeyDown) == "function" and IsShiftKeyDown());
end

-- Reload UI runs this file again in the same Lua state, so a function already wrapped stays as is.
UMMNameClickWrappers = UMMNameClickWrappers or {};
local function wrapNameClicks(key)
  local original = _G[key];
  if (type(original) ~= "function" or UMMNameClickWrappers[original]) then return; end
  local wrapper = function(...)
    if (modifierDown() and UMMFrame and UMMFrame:IsVisible()) then
      local name = clickedName(...);
      if (name and UMMUseClickedName(name)) then return; end
    end
    return original(...);
  end;
  UMMNameClickWrappers[wrapper] = true;
  _G[key] = wrapper;
end

function UMMHookNameClicks()
  wrapNameClicks("Hyperlink_Assign");
  wrapNameClicks("ChatFrame_OnHyperlinkClick");
end
