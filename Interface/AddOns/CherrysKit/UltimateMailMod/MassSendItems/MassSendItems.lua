-- 2021-05-17, Cherry's Kit rework 2026-10-26 (send queue, ctrl+click toggle, bound items in red)

-- #######################
-- ##                   ##
-- ##  Mass Send Items  ##
-- ##                   ##
-- #######################

-- #### Mass Send Status Frame #####

function UMMMassSendItemsStatusItemTemplate_OnLoad(this)
  
  this.SetData = function(self, recipient, mailObject, modeEdit)
    getglobal(self:GetName().."Recipient"):SetText("|cff"..UMMFriends:GetColor(recipient)..recipient.."|r");
    local subject = mailObject.Name.." ("..mailObject.Count..")";
    getglobal(self:GetName().."Subject"):SetText("|cff"..UMMColor.White..subject.."|r");
    local button = getglobal(self:GetName().."Button");
    SetItemButtonTexture(button, mailObject.Icon);
    SetItemButtonCount(button, 0);
    getglobal(self:GetName().."Status"):Hide();
    if (modeEdit) then
      getglobal(self:GetName().."COD"):Show();
      if (mailObject.CODAmount > 0) then
        getglobal(self:GetName().."COD"):SetText(mailObject.CODAmount);
      else
        getglobal(self:GetName().."COD"):SetText("");
      end
    else
      getglobal(self:GetName().."COD"):Hide();
    end
  end;
  
  this.SetStatus = function(self, status)
    getglobal(self:GetName().."COD"):Hide();
    getglobal(self:GetName().."Status"):Show();
    if (string.lower(status) == "sending") then
      getglobal(self:GetName().."Status"):SetText("|cff"..UMMColor.Green..UMM_MSI_STATUS_SENDING.."|r");
    elseif (string.lower(status) == "queued") then
      getglobal(self:GetName().."Status"):SetText("|cff"..UMMColor.Yellow..UMM_MSI_STATUS_QUEUED.."|r");
    end
  end;
  
end

function UMMMassSendItemsStatusTemplate_OnLoad(this)
  
  -- Cherry's Kit: the send queue. Each mail goes through UMMMailComposer (which waits for the
  -- game to confirm every step); between mails the queue waits SendDelay seconds AND until the
  -- game has been quiet for a moment, pauses after every BatchSize mails, retries a failed mail
  -- with a growing wait, and stops cleanly (items given back, the rest still marked) when a
  -- mail keeps failing or Stop is pressed.
  
  this.priv_SendTable   = nil;
  this.priv_Offset      = 0;
  this.priv_Recipient   = nil;
  this.priv_CODMode     = nil;
  this.priv_AutoRunning = nil;
  this.priv_SendCount   = 0;   -- index of the mail being sent / next to send
  this.priv_SentOk      = 0;
  this.priv_SendTotal   = 0;
  this.priv_MyName      = nil;
  this.priv_Wait        = 0;
  this.priv_Tries       = 0;
  this.priv_StopAsked   = nil;

  this.AutoDisableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Disable();
    end
  end;
  
  this.AutoEnableTabs = function(self)
    for i = 1, 3 do
      getglobal("UMMFrameTab"..i.."Button"):Enable();
    end
  end;

  this.Clear = function(self)
    self.priv_SendTable   = nil;
    self.priv_Offset      = 0;
    self.priv_Recipient   = nil;
    self.priv_CODMode     = nil;
    self.priv_AutoRunning = nil;
    self.priv_SendCount   = 0;
    self.priv_SentOk      = 0;
    self.priv_SendTotal   = 0;
    self.priv_MyName      = nil;
    self.priv_Wait        = 0;
    self.priv_Tries       = 0;
    self.priv_StopAsked   = nil;
  end;
  
  this.IsSending = function(self)
    return self.priv_AutoRunning;
  end;
  
  this.Refresh = function(self)
    local list = self.priv_SendTable or {};
    local total = table.getn(list);
    for idx = 1, 18 do
      local index = idx + self.priv_Offset;
      local mail = getglobal(self:GetName().."Mail"..idx);
      if (index <= total) then
        mail:SetData(self.priv_Recipient, list[index], self.priv_CODMode);
        if (not self.priv_CODMode) then
          if (idx == 1) then
            mail:SetStatus("Sending");
          else
            mail:SetStatus("Queued");
          end
        end
        mail:Show();
      else
        mail:Hide();
      end
    end
    local scroll = getglobal(self:GetName().."Scroll");
    if (self.priv_CODMode and total > 18) then
      scroll:SetMaxValue(total - 18);
      scroll:SetValue(self.priv_Offset);
      scroll:Show();
    else
      scroll:Hide();
    end
  end;
  
  this.ScrollChanged = function(self, this)
    self.priv_Offset = this:GetValue();
    self:Refresh();
  end;
  
  this.DefineCOD = function(self, id, value)
    local index = id + self.priv_Offset;
    local cash = tonumber(value) or 0;
    cash = math.floor(cash);
    if (cash < 0) then
      cash = 0;
    end
    if (self.priv_SendTable and index >= 1 and index <= table.getn(self.priv_SendTable)) then
      self.priv_SendTable[index].CODAmount = cash;
    end
  end;
  
  this.SetStatusText = function(self, text)
    UMMNormalBar:SetStatus(text);
  end;
  
  -- Start the mail at priv_SendCount
  this.AutoSend = function(self)
    local mail = self.priv_SendTable[self.priv_SendCount];
    self:SetStatusText(string.format(UMM_MSI_SEND_STATUS, self.priv_SendCount, self.priv_SendTotal));
    self.priv_Offset = self.priv_SendCount - 1;
    self:Refresh();
    -- the item must still be where it was when the list was made
    if (GetBagItemLink(mail.Index) ~= mail.Link) then
      UMMPrompt("|r|cff"..UMMColor.Red..string.format(UMM_MSI_SKIPPED, mail.Name or "?"));
      UMMTraceAdd("skip", mail.Name);
      self:NextMail(0);
      return;
    end
    UMMMailComposer:Clear();
    UMMMailComposer:SetComposer(self.priv_MyName);
    UMMMailComposer:Recipient(self.priv_Recipient);
    UMMMailComposer:Subject(mail.Name.." ("..mail.Count..")");
    local body = string.format(UMM_MSI_SEND_MAILBODY, self.priv_Recipient, UnitName("player"), "UMM v"..UMM_VERSION.Major.."."..UMM_VERSION.Minor.."."..UMM_VERSION.Revision.." ("..UMM_VERSION.Build..")");
    UMMMailComposer:Body(body);
    UMMMailComposer:DefinedCODAmount(mail.CODAmount);
    UMMMailComposer:AttachedItemIndex(mail.Index);
    UMMTraceAdd("mail", self.priv_SendCount.."/"..self.priv_SendTotal.." "..tostring(mail.Name).." slot "..tostring(mail.Index).." try "..(self.priv_Tries + 1));
    local result = UMMMailComposer:Send();
    if (result == 4) then
      -- previous mail still busy: try again shortly
      self.priv_Wait = 0.5;
    elseif (result ~= 0) then
      -- bound, self or no subject: skip this one
      UMMTraceAdd("skip", "code "..result);
      self:NextMail(0);
    end
  end;
  
  -- Move on to the next mail after a wait
  this.NextMail = function(self, wait)
    self.priv_SendCount = self.priv_SendCount + 1;
    self.priv_Tries = 0;
    self.priv_Wait = wait;
    if (self.priv_SendCount > self.priv_SendTotal or self.priv_StopAsked) then
      self:Finish();
    end
  end;
  
  -- Called every frame by the master frame
  this.Tick = function(self, elapsedTime)
    if (not self.priv_AutoRunning) then
      return;
    end
    if (UMMMailComposer:Busy()) then
      return;
    end
    if (self.priv_Wait > 0) then
      self.priv_Wait = self.priv_Wait - elapsedTime;
      return;
    end
    -- let late updates from the previous mail die down before attaching the next item
    if (not self.priv_Fast and UMMMailComposer:QuietTime() < 0.3) then
      return;
    end
    self:AutoSend();
  end;
  
  this.StartSending = function(self)
    self:AutoDisableTabs();
    self.priv_CODMode = nil;
    self.priv_SendCount = 1;
    self.priv_SentOk = 0;
    self.priv_Tries = 0;
    self.priv_StopAsked = nil;
    self.priv_Wait = 0;
    self.priv_SendTotal = table.getn(self.priv_SendTable);
    self.priv_MyName = self:GetName();
    getglobal(self:GetName().."Send"):Hide();
    getglobal(self:GetName().."Cancel"):SetText(UMM_MSI_BUTTON_STOP);
    getglobal(self:GetName().."Cancel"):Show();
    UMMNormalBar:Hide();
    UMMTraceAdd("start", self.priv_SendTotal.." mails to "..tostring(self.priv_Recipient)..(self.priv_Fast and " (fast)" or " (safe)"));
    if (self.priv_SendTotal == 0) then
      self:Finish();
      return;
    end
    self.priv_AutoRunning = true;
  end;
  
  this.SendCompleted = function(self, status, reason)
    if (not self.priv_AutoRunning) then
      return;
    end
    local mail = self.priv_SendTable[self.priv_SendCount];
    if (status == "ok") then
      self.priv_SentOk = self.priv_SentOk + 1;
      local item = UMMBagManager.BySlot[mail.Index];
      if (item) then
        item.Marked = false;
      end
      local wait = UMMSendSetting("SendDelay");
      local batch = UMMSendSetting("BatchSize");
      if (self.priv_Fast) then
        -- Send fast: its own gap (0.2 s by default, the old pace), no pauses
        wait = UMMSendSetting("FastDelay");
        batch = 0;
      end
      if (batch > 0 and self.priv_SentOk % batch == 0 and self.priv_SendCount < self.priv_SendTotal) then
        wait = math.max(wait, UMMSendSetting("BatchPause"));
        self:SetStatusText(string.format(UMM_MSI_PAUSE, self.priv_SentOk, self.priv_SendTotal));
      end
      self:NextMail(wait);
    else
      self.priv_Tries = self.priv_Tries + 1;
      if (self.priv_StopAsked) then
        self:Finish();
      elseif (self.priv_Fast or self.priv_Tries > UMMSendSetting("MaxRetries")) then
        UMMPrompt("|r|cff"..UMMColor.Red..string.format(UMM_MSI_GAVEUP, mail.Name or "?", self.priv_Tries, tostring(reason)));
        self:Finish();
      else
        -- 2, 4, 8 ... seconds: a busy server gets time to catch up
        local wait = 2 * math.pow(2, self.priv_Tries - 1);
        self:SetStatusText(string.format(UMM_MSI_RETRY, self.priv_SendCount, self.priv_SendTotal, tostring(reason), wait));
        self.priv_Wait = wait;
      end
    end
  end;
  
  -- Stop button while sending: the mail already handed to the server finishes first
  this.Stop = function(self)
    if (not self.priv_AutoRunning) then
      return;
    end
    self.priv_StopAsked = true;
    self:SetStatusText(UMM_MSI_STOPPING);
    if (UMMMailComposer:Busy()) then
      -- still attaching: given back and finished through SendCompleted; already sent: wait for it
      UMMMailComposer:Abort();
    else
      self:Finish();
    end
  end;
  
  this.Finish = function(self)
    if (not self.priv_AutoRunning and self.priv_SendTable == nil) then
      return;
    end
    local sent, total = self.priv_SentOk, self.priv_SendTotal;
    UMMTraceAdd("end", sent.." of "..total);
    if (sent == total) then
      UMMPrompt(string.format(UMM_MSI_DONE, sent, total));
    else
      UMMPrompt("|r|cff"..UMMColor.Yellow..string.format(UMM_MSI_STOPPED, sent, total));
    end
    UMMNormalBar:SetStatus("");
    UMMNormalBar:Show();
    self:Clear();
    self:Hide();
  end;
  
  this.CancelButton = function(self)
    if (self.priv_AutoRunning) then
      self:Stop();
    else
      self:CancelCOD();
    end
  end;
  
  -- Composer gave up waiting (old global timer hook, kept for safety)
  this.TimeOut = function(self)
  end;
  
  this.TimeOutFailed = function(self)
    if (self.priv_AutoRunning) then
      self:Finish();
    end
  end;
  
  this.BuildSendList = function(self)
    self.priv_SendTable = {};
    UMMBagManager:Ensure();
    local list = UMMBagManager.ItemList;
    for i = 1, table.getn(list) do
      local item = list[i];
      if (item.Marked == true and not item.Empty and not UMMBagManager:IsBound(item)) then
        table.insert(self.priv_SendTable, {
          Index = item.Index,
          Icon = item.Icon,
          Count = item.Count,
          Name = item.Name,
          Link = item.Link,
          CODAmount = 0,
        });
      end
    end
    self.priv_Offset = 0;
  end;
  
  this.Send = function(self, mode)
    self.priv_CODMode = nil;
    self.priv_Fast = (mode == "fast");
    self:BuildSendList();
    getglobal(this:GetName().."Status"):SetText("|cff"..UMMColor.White..UMM_MSI_STATUS.."|r");
    self.priv_Recipient = getglobal(this:GetParent():GetName().."RecipientRecipient"):GetText();
    getglobal(this:GetName().."Cancel"):Hide();
    getglobal(this:GetName().."Send"):Hide();
    self:Show();
    self:Refresh();
    self:StartSending();
  end;
  
  this.ShowCODEditor = function(self)
    self.priv_CODMode = true;
    self.priv_Fast = nil;   -- C.O.D. mails always go out the safe way
    self:BuildSendList();
    getglobal(this:GetName().."Status"):SetText("|cff"..UMMColor.White..UMM_MSI_COD.."|r");
    self.priv_Recipient = getglobal(this:GetParent():GetName().."RecipientRecipient"):GetText();
    getglobal(this:GetName().."Cancel"):SetText(UMM_MSI_BUTTON_CANCEL);
    getglobal(this:GetName().."Cancel"):Show();
    getglobal(this:GetName().."Send"):Show();
    self:Show();
    self:Refresh();
  end;
  
  this.CancelCOD = function(self)
    self.priv_SendTable = nil;
    self.priv_Offset = 0;
    self.priv_Recipient = nil;
    self.priv_CODMode = nil;
    self:Hide();
  end;
  
  for i = 1, 18 do
    local button = getglobal(this:GetName().."Mail"..i);
    button:ClearAllAnchors();
    button:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 5, ((i * 25) - 25) + 20);
  end
  getglobal(this:GetName().."Recipient"):SetText("|cff"..UMMColor.White..UMM_MSI_ADDRESSEE.."|r");
  getglobal(this:GetName().."Subject"):SetText("|cff"..UMMColor.White..UMM_MSI_SUBJECT.."|r");
  getglobal(this:GetName().."Status"):SetText("");
  getglobal(this:GetName().."Send"):SetText(UMM_MSI_BUTTON_SEND);
  getglobal(this:GetName().."Cancel"):SetText(UMM_MSI_BUTTON_CANCEL);
  
end

function UMMMassSendItemsStatusTemplate_OnShow(this)
  getglobal(this:GetParent():GetName().."Action"):Hide();
  getglobal(this:GetParent():GetName().."Recipient"):Hide();
  getglobal(this:GetParent():GetName().."Bags"):Hide();
  getglobal(this:GetParent():GetName().."Mark"):Hide();
end

function UMMMassSendItemsStatusTemplate_OnHide(this)
  -- marks of mails that went out are already cleared; what was not sent stays marked
  getglobal(this:GetParent():GetName().."Action"):Show();
  getglobal(this:GetParent():GetName().."Recipient"):Show();
  getglobal(this:GetParent():GetName().."Bags"):Show();
  getglobal(this:GetParent():GetName().."Mark"):Show();
  getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
  getglobal(this:GetParent():GetName().."RecipientRecipient"):SetFocus();
  this:AutoEnableTabs();
end


-- ##### Bags #####

-- Item quality colour from a link: R, G, B (0-255) or nil
local function LinkColor(link)
  if (not link) then
    return nil;
  end
  local _, _, hex = string.find(link, "|c%x%x(%x%x%x%x%x%x)");
  if (not hex) then
    return nil;
  end
  return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16);
end
UMMLinkColor = LinkColor;

function UMMMassSendItemsBagsTemplate_OnLoad(this)
  
  this.priv_Shown = nil;
  this.priv_Buttons = {};
  
  -- slot buttons are looked up once, not by name on every redraw
  this.GetButton = function(self, index)
    local button = self.priv_Buttons[index];
    if (button == nil) then
      local bagIndex = math.floor((index - 1) / 30) + 1;
      local slotIndex = index - (bagIndex - 1) * 30;
      local name = self:GetName().."Bag"..bagIndex.."Slot"..slotIndex;
      button = getglobal(name);
      button.ummInvalid = getglobal(name.."Invalid");
      button.ummQuality = getglobal(name.."QualityBorder");
      button.ummMark = getglobal(name.."MarkBorder");
      self.priv_Buttons[index] = button;
    end
    return button;
  end;
  
  this.GetItem = function(self, bagIndex, slotIndex)
    UMMBagManager:Ensure();
    return UMMBagManager.ItemList[(bagIndex - 1) * 30 + slotIndex];
  end;
  
  this.GetBagLink = function(self, bagIndex, slotIndex)
    local item = self:GetItem(bagIndex, slotIndex);
    if (item and item.Empty == false) then
      return item.Link;
    end
    return nil;
  end;
  
  -- Draws the mark of one slot: yellow border when marked, red when marked but bound
  this.DrawMark = function(self, index, item)
    local button = self:GetButton(index);
    if (item.Marked == true and not item.Empty) then
      if (UMMBagManager:IsBound(item)) then
        button.ummMark:Hide();
        button.ummInvalid:Show();
      else
        button.ummInvalid:Hide();
        button.ummMark:SetColor(1, 1, 0.2);
        button.ummMark:Show();
      end
    else
      button.ummMark:Hide();
      button.ummInvalid:Hide();
    end
  end;
  
  -- Plain click: mark / unmark one slot
  this.ToggleMark = function(self, bagIndex, slotIndex)
    local index = (bagIndex - 1) * 30 + slotIndex;
    local item = self:GetItem(bagIndex, slotIndex);
    if (item and item.Empty == false) then
      item.Marked = not (item.Marked == true);
      if (item.Marked and UMMBagManager:IsBound(item)) then
        UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
        WarningFrame:AddMessage(UMM_ERROR_CANTSENDBOUND);
      end
      self:DrawMark(index, item);
    end
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;
  
  -- Ctrl+click: mark every stack of the same item; on an item that is already marked,
  -- unmark them all instead
  this.ToggleGroup = function(self, bagIndex, slotIndex)
    local clicked = self:GetItem(bagIndex, slotIndex);
    if (not clicked or clicked.Empty or not clicked.Name) then
      return;
    end
    local newState = not (clicked.Marked == true);
    local list = UMMBagManager.ItemList;
    local anyBound = nil;
    for i = 1, table.getn(list) do
      local item = list[i];
      if (not item.Empty and item.Name == clicked.Name) then
        item.Marked = newState;
        if (newState and UMMBagManager:IsBound(item)) then
          anyBound = true;
        end
        self:DrawMark(i, item);
      end
    end
    if (anyBound) then
      UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
      WarningFrame:AddMessage(UMM_ERROR_CANTSENDBOUND);
    end
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;
  
  this.PopulateBags = function(self)
    if (self.priv_Shown and UMMFrame:IsVisible()) then
      UMMBagManager:Ensure();
      local list = UMMBagManager.ItemList;
      for index = 1, 180 do
        local button = self:GetButton(index);
        local item = list[index];
        button.ummQuality:Hide();
        if (item == nil or item.Empty == true or item.Link == nil) then
          button.ummMark:Hide();
          button.ummInvalid:Hide();
          SetItemButtonTexture(button, nil);
          SetItemButtonCount(button, 0);
          button:Disable();
        else
          local R, G, B = LinkColor(item.Link);
          if (R and not (R == 255 and G == 255 and B == 255)) then
            button.ummQuality:SetColor(R / 255, G / 255, B / 255);
            button.ummQuality:SetAlpha(0.65);
            button.ummQuality:Show();
          end
          SetItemButtonTexture(button, item.Icon);
          SetItemButtonCount(button, item.Count);
          self:DrawMark(index, item);
          button:Enable();
        end
      end
    end
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;
  
  this.ShowBags = function(self)
    self.priv_Shown = true;
    self:PopulateBags();
  end;
  
  this.HideBags = function(self)
    self.priv_Shown = nil;
  end;
  
  this.IsShownBags = function(self)
    return self.priv_Shown;
  end;
  
  local sizeX, sizeY;
  local x, y, b;
  
  sizeX = 255;
  sizeY = 215;
  b = 0;
  for y = 1, 2 do
    for x = 1, 3 do
      b = b + 1;
      local bag = getglobal(this:GetName().."Bag"..b);
      bag:ClearAllAnchors();
      bag:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), ((x * sizeX) - sizeX) + 5, ((y * sizeY) - sizeY) + 5);
      bag:Show();
    end
  end
end

function UMMMassSendItemsBagsTemplate_OnShow(this)
  this:ShowBags();
end

function UMMMassSendItemsBagsTemplate_OnHide(this)
  this:HideBags();
end

-- ##### Bag #####

function UMMMassSendItemsBagTemplate_OnLoad(this)
  local x, y, i;
  
  i = 0;
  for y = 1, 5 do
    for x = 1, 6 do
      i = i + 1;
      local btn = getglobal(this:GetName().."Slot"..i);
      btn:ClearAllAnchors();
      btn:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), ((x * 40) - 40) + 10, ((y * 40) - 40) + 10);
      btn:Show();
    end
  end
end

-- ##### Bag Slot Buttons ####

function UMMMassSendItemsSlotTemplate_OnEnter(this)
  local slotIndex = this:GetID();
  local bagIndex = this:GetParent():GetID();
  local itemLink = this:GetParent():GetParent():GetBagLink(bagIndex, slotIndex);
  if (itemLink) then
    GameTooltip:ClearLines();
    GameTooltip:ClearAllAnchors();
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, 0);
    GameTooltip:SetHyperLink(itemLink);
    GameTooltip:Show();
  end
end

-- Click marks one slot; Ctrl+click marks (or unmarks) every stack of that item
function UMMMassSendItemsSlotTemplate_OnClick(this)
  local slotIndex = this:GetID();
  local bagIndex = this:GetParent():GetID();
  local bags = this:GetParent():GetParent();
  if (IsCtrlKeyDown()) then
    bags:ToggleGroup(bagIndex, slotIndex);
  else
    bags:ToggleMark(bagIndex, slotIndex);
  end
end

function UMMMassSendItemsSlotTemplate_OnLeave(this)
  if (GameTooltip:IsVisible()) then
    GameTooltip:Hide();
  end
end

-- ##### Action Frame #####

function UMMMassSendItemsActionTemplate_OnLoad(this)
  
  this.CheckStatus = function(self)
    local recipient = getglobal(self:GetParent():GetName().."RecipientRecipient"):GetText() or "";
    recipient = string.gsub(recipient, " ", "");
    
    local mailCount, boundCount = UMMBagManager:CountMarked();
    local label = getglobal(self:GetName().."Label");
    local canSend = mailCount > 0 and recipient ~= "";
    
    if (mailCount > 0) then
      local text = "|cff"..UMMColor.White..string.format(UMM_MSI_MAILSTOSEND, mailCount).."|r";
      if (boundCount > 0) then
        text = text.."|cff"..UMMColor.Red..string.format(UMM_MSI_BOUNDSKIPPED, boundCount).."|r";
      end
      label:SetText(text);
    elseif (boundCount > 0) then
      label:SetText("|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND.."|r");
    else
      label:SetText("");
    end
    for _, name in ipairs({ "Send", "SendFast", "COD" }) do
      if (canSend) then
        getglobal(self:GetName()..name):Enable();
      else
        getglobal(self:GetName()..name):Disable();
      end
    end
    -- under SPLIT_AT mails one plain "Send" (fast); from SPLIT_AT on, "Send fast" + "Send safely"
    local split = mailCount >= UMM_MSI_SPLIT_AT;
    if (split ~= self.priv_Split) then
      self.priv_Split = split;
      local send = getglobal(self:GetName().."Send");
      local fast = getglobal(self:GetName().."SendFast");
      local cod = getglobal(self:GetName().."COD");
      cod:ClearAllAnchors();
      if (split) then
        send:SetText(UMM_MSI_BUTTON_SENDSAFE);
        fast:Show();
        cod:SetAnchor("RIGHT", "LEFT", fast:GetName(), -8, 0);
      else
        send:SetText(UMM_MSI_BUTTON_SEND);
        fast:Hide();
        cod:SetAnchor("RIGHT", "LEFT", send:GetName(), -8, 0);
      end
    end
  end;
  
  -- what the main button does: "safe" when split into two buttons, else "fast"
  this.MainSendMode = function(self)
    return self.priv_Split and "safe" or "fast";
  end;
  
  -- mode "safe" (paced queue) or "fast" (as fast as the old Send button)
  this.Send = function(self, mode)
    getglobal(self:GetParent():GetName().."Status"):Send(mode);
  end;
  
  this.COD = function(self)
    getglobal(self:GetParent():GetName().."Status"):ShowCODEditor();
  end;
  
  getglobal(this:GetName().."Send"):SetText(UMM_MSI_BUTTON_SEND);
  getglobal(this:GetName().."SendFast"):SetText(UMM_MSI_BUTTON_SENDFAST);
  getglobal(this:GetName().."SendFast"):Hide();
  this.priv_Split = false;
  getglobal(this:GetName().."COD"):SetText(UMM_MSI_BUTTON_COD);
  
end

function UMMMassSendItemsAction_Tooltip(button, mode)
  GameTooltip:ClearLines();
  GameTooltip:ClearAllAnchors();
  GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT", 0, 0);
  if (mode == "fast" and button:GetName() ~= nil and string.find(button:GetName(), "SendFast$") == nil) then
    -- the single "Send" button (few mails): no warning needed
    GameTooltip:AddLine("|cff"..UMMColor.Medium..UMM_MSI_BUTTON_SEND.."|r");
    GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_MSI_TIP_SEND.."|r");
  elseif (mode == "fast") then
    GameTooltip:AddLine("|cff"..UMMColor.Medium..UMM_MSI_BUTTON_SENDFAST.."|r");
    GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_MSI_TIP_SENDFAST.."|r");
  else
    GameTooltip:AddLine("|cff"..UMMColor.Medium..UMM_MSI_BUTTON_SENDSAFE.."|r");
    GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_MSI_TIP_SENDSAFE.."|r");
  end
  GameTooltip:Show();
end

function UMMMassSendItemsActionTemplate_OnShow(this)
  this:CheckStatus();
end

function UMMMassSendItemsActionTemplate_OnHide(this)
  
end


-- ##### Recipient Frame #####

function UMMMassSendItemsRecipientTemplate_OnLoad(this)
  
  this.HideBody = function(self)
    getglobal(self:GetParent():GetName().."Action"):Hide();
    getglobal(self:GetParent():GetName().."Bags"):Hide();
    getglobal(self:GetParent():GetName().."Mark"):Hide();
    getglobal(self:GetParent():GetName().."People"):Show();
  end;
  
  this.ShowBody = function(self)
    getglobal(self:GetParent():GetName().."Action"):Show();
    getglobal(self:GetParent():GetName().."Bags"):Show();
    getglobal(self:GetParent():GetName().."Mark"):Show();
    getglobal(self:GetParent():GetName().."People"):Hide();
  end;
  
  this.SelectDone = function(self)
    self:ShowBody();
  end;
  
  this.FindRecipient = function(self)
    if (getglobal(self:GetParent():GetName().."Bags"):IsVisible()) then
      self:HideBody();
    else
      self:ShowBody();
    end
  end;
  
  this.CheckSendStatus = function(self)
    getglobal(self:GetParent():GetName().."Action"):CheckStatus();
  end;
  
  this.Reset = function(self)
    UMMBagManager:ClearMarks();
    getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
    getglobal(this:GetName().."Recipient"):SetText("");
    getglobal(this:GetName().."Recipient"):SetFocus();
  end;
  
  getglobal(this:GetName().."Find"):SetText(UMM_MSI_BUTTON_ADDRESSEE);
  getglobal(this:GetName().."Reset"):SetText(UMM_MSI_BUTTON_RESET);
  
end

function UMMMassSendItemsRecipientTemplate_OnShow(this)
  getglobal(this:GetName().."Recipient"):SetFocus();
end

function UMMMassSendItemsRecipientTemplate_OnHide(this)
  getglobal(this:GetName().."Recipient"):ClearFocus();
end

-- ##### People Columns #####

function UMMMassSendItemsPeopleTemplate_OnShow(this)
  UMMFriends:Load();
  local recipientName = this:GetParent():GetName().."RecipientRecipient";
  local recipientFrame = this:GetParent():GetName().."Recipient";
  
  local listFrame = getglobal(this:GetName().."Own")
  listFrame:ClearAllAnchors();
  listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 0, 0);
  listFrame:SetTarget(recipientName);
  listFrame:SetSelectDone(recipientFrame);
  listFrame:SetupList("own");
  listFrame:Show();

  local listFrame = getglobal(this:GetName().."Friends")
  listFrame:ClearAllAnchors();
  listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 145, 0);
  listFrame:SetTarget(recipientName);
  listFrame:SetSelectDone(recipientFrame);
  listFrame:SetupList("friend");
  listFrame:Show();
  
  local listFrame = getglobal(this:GetName().."Guildies")
  if (IsInGuild()) then
    listFrame:ClearAllAnchors();
    listFrame:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 290, 0);
    listFrame:SetTarget(recipientName);
    listFrame:SetSelectDone(recipientFrame);
    listFrame:SetupList("guild");
    listFrame:Show();
  else
    listFrame:Hide();
  end
end

-- ##### Bottom Mark Button Bar #####

-- Marks every bag item of one category (from the ItemDB or, for recipes, by name and colour)
local RECIPE_COLORS = {
  WRecipes = { 255, 255, 255 },
  GRecipes = { 0, 255, 0 },
  BRecipes = { 0, 114, 188 },
  MRecipes = { 200, 5, 248 },
};

local function MatchesType(item, type, R, G, B)
  local rc = RECIPE_COLORS[type];
  if (rc and R == rc[1] and G == rc[2] and B == rc[3]) then
    -- recipes: right colour and the recipe name prefix
    return Sol.string.StartsWith(item.Name, UMM_RECIPES_NAME_PREFIX) and true or false;
  end
  return UMMItemDB:IsItem(type, item.Link) and true or false;
end

local function MarkTypes(types)
  UMMBagManager:Ensure();
  local list = UMMBagManager.ItemList;
  for index = 1, table.getn(list) do
    local item = list[index];
    if (not item.Empty and item.Link ~= nil and item.Name ~= nil) then
      local R, G, B = UMMLinkColor(item.Link);
      for t = 1, table.getn(types) do
        if (MatchesType(item, types[t], R, G, B)) then
          item.Marked = true;
          break;
        end
      end
    end
  end
end

function UMMMassSendItemsMarkButtonsTemplate_OnLoad(this)

  this.ButtonClick = function(self, id)
    local sendTo = getglobal("UMM_MSI_RECIPE_SEND_TO"..id);
    if (sendTo ~= nil and sendTo ~= "") then
      getglobal(this:GetParent():GetName().."RecipientRecipient"):SetText(sendTo);
    end
    local types = {};
    if (id == 36) then
      -- "all": every category 1 to 35
      for typeId = 1, 35 do
        table.insert(types, UMMItemDB:GetTypeByID(typeId));
      end
    else
      table.insert(types, UMMItemDB:GetTypeByID(id));
    end
    MarkTypes(types);
    getglobal(this:GetParent():GetName().."Bags"):PopulateBags();
  end;
  
  this.ButtonEnter = function(self, this)
    local title = getglobal("UMM_MSI_MARK_TOOLTIP"..this:GetID());
    if (title) then
      GameTooltip:ClearLines();
      GameTooltip:ClearAllAnchors();
      GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 0);
      GameTooltip:AddLine("|cff"..UMMColor.Medium..title.."|r");
      GameTooltip:AddLine("|cff"..UMMColor.Bright..UMM_MSI_MARK_TOOLTIPCLICK.."|r");
      GameTooltip:Show();
    end
  end;
  
  this.ButtonLeave = function(self, id)
    GameTooltip:Hide();
  end;
  
--  getglobal(this:GetName().."Label"):SetText("|cff"..UMMColor.White..UMM_MSI_MARK_LABEL.."|r");		-- "Wähle:" entfernt xxxxxxxxxx
  local shiftX = 45;			-- 45		Zentrierung der 36 Button	xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  for index = 1, 48 do			--  1, 33 Anzahl angezeigten der Button	xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    local button = getglobal(this:GetName().."Button"..index);
    button:ClearAllAnchors();
    if (index < 13) then		-- release 4.0.11.2531
      button:SetAnchor("LEFT", "LEFT", this:GetName(), ((index * 65) - 121) + 5 + shiftX, -6);			-- ((index * 65) - 121) + 5 + shiftX, 0);
	else if (index < 25) then
      button:SetAnchor("LEFT", "LEFT", this:GetName(), (((index-12) * 65) - 121) + 5 + shiftX, 15);		-- (((index-11) * 65) - 65) + 5 + shiftX, 25=Abstand von oben);
	else if (index < 37) then
      button:SetAnchor("LEFT", "LEFT", this:GetName(), (((index-24) * 65) - 121) + 5 + shiftX, 36);		-- (((index-22) * 65) - 65) + 5=Position von rechts + shiftX, 50=Abstand von oben)

	else if (index < 49) then
      button:SetAnchor("LEFT", "LEFT", this:GetName(), (((index-36) * 65) - 121) + 5 + shiftX, 57);		-- (((index-22) * 65) - 65) + 5=Position von rechts + shiftX, 50=Abstand von oben)			xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

	end
	  
	end
	end
	end
    button:SetText(getglobal("UMM_MSI_MARKBUTTON"..index));
 end

end

-- ##### Main Mass Send Items Frame #####

function UMMMassSendItemsTemplate_OnShow(this)
  UMMFriends:Load();
  getglobal(this:GetName().."Action"):Show();
  getglobal(this:GetName().."Recipient"):Show();
  getglobal(this:GetName().."Bags"):Show();
  getglobal(this:GetName().."Mark"):Show();
  getglobal(this:GetName().."Status"):Hide();
  getglobal(this:GetName().."People"):Hide();
end

function UMMMassSendItemsTemplate_OnHide(this)
  getglobal(this:GetName().."Action"):Hide();
  getglobal(this:GetName().."RecipientRecipient"):SetText("");
  getglobal(this:GetName().."RecipientRecipient"):ClearFocus();
  getglobal(this:GetName().."Recipient"):Hide();
  getglobal(this:GetName().."Bags"):Hide();
  getglobal(this:GetName().."Mark"):Hide();
  getglobal(this:GetName().."Status"):Hide();
end
