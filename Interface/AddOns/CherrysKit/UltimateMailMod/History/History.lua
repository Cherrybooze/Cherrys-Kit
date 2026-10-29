-- Account-wide, bounded recipient history. Selecting a row only fills Compose.
function UMMHistory_OnLoad(this)
  getglobal(this:GetName().."Title"):SetText(UMM_HISTORY_TITLE);
  getglobal(this:GetName().."Help"):SetText(UMM_HISTORY_HELP);
  getglobal(this:GetName().."Empty"):SetText(UMM_HISTORY_EMPTY);
end

local function fillHistory(frame, compact)
  if (not frame) then return; end
  local history = UMMSettings:History();
  for i = 1, UMM_RECIPIENT_HISTORY_MAX do
    local row = getglobal(frame:GetName().."Entry"..i);
    local label = getglobal(row:GetName().."Name");
    row.priv_Recipient = history[i];
    label:SetText(history[i] and (compact and history[i] or string.format("%2d.  %s", i, history[i])) or "");
    if (history[i]) then row:Show(); else row:Hide(); end
    if (compact) then
      if (frame.priv_Blocked or UMMMailShortcutsBusy()) then row:Disable(); else row:Enable(); end
    end
  end
  local empty = getglobal(frame:GetName().."Empty");
  if (#history == 0) then empty:SetText(UMM_HISTORY_EMPTY);empty:Show();
  else empty:SetText("");empty:Hide(); end
  local count = getglobal(frame:GetName().."Count");
  if (count) then count:SetText(string.format(UMM_HISTORY_COUNT, #history)); end
end

function UMMHistory_Refresh()
  fillHistory(getglobal("UMMFrameTab4"), false);
  fillHistory(getglobal("UMMFrameTab3Recent"), true);
end

function UMMHistory_Select(index)
  local frame = getglobal("UMMFrameTab4");
  if (not frame or not frame:IsVisible()) then return; end
  local name = UMMSettings:History()[index];
  if (not name) then return; end
  if (UMMMailShortcutsBusy()) then UMMPrompt(UMM_ERROR_STILLSENDING);return; end
  UMMMenuSelectTab(2);
  UMMFrameTab2Composer:SetRecipient(name);
  getglobal(UMMFrameTab2Composer:GetName().."HeaderSubject"):SetFocus();
end

function UMMHistory_Enter(this, massSend)
  if (not this.priv_Recipient or not GameTooltip) then return; end
  GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, 0);
  GameTooltip:SetText(this.priv_Recipient);
  GameTooltip:AddLine(massSend and UMM_MSI_RECENT_HELP or UMM_HISTORY_HELP, 1, 1, 1);
  GameTooltip:Show();
end
