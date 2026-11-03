-- Cherry's Kit: the Inbox page of the modern mail window, and the window's side of the inbox
-- automation in Library/MailManager.lua (M.View, the same calls the classic window answers).
--
-- The list never reads a mail on its own: the game cuts an unread mail's time in the inbox to 3 days
-- the moment its text or items are read (GetInboxText, GetInboxItem). Rows and the reader show what
-- the mail's header tells (sender, subject, gold, diamonds, C.O.D., first item's icon, days left);
-- item tooltips come from GameTooltip:SetInboxItem, which reads nothing. "Read this mail" in the
-- reader is the only thing that reads an unread mail.

local M = UMMModern;
local C = M.C;
local MM = UMMMailManager;
local I = { frame = UMMModernInbox };
M.pages.inbox = I;

M.Default("UMM_M_IN_ALL", "All");
M.Default("UMM_M_IN_GOLD", "Gold");
M.Default("UMM_M_IN_ITEMS", "Items");
M.Default("UMM_M_IN_GEMS", "Diamonds");
M.Default("UMM_M_IN_UNREAD", "Unread");
M.Default("UMM_M_IN_CHIP_TIP", "Shows only these mails. The number counts them.");
M.Default("UMM_M_IN_FROM", "From: %s");
M.Default("UMM_M_IN_FROM_ANY", "anyone");
M.Default("UMM_M_IN_FROM_OWN", "mine");
M.Default("UMM_M_IN_FROM_FRIEND", "friends");
M.Default("UMM_M_IN_FROM_GUILD", "guild");
M.Default("UMM_M_IN_FROM_OTHER", "others");
M.Default("UMM_M_IN_FROM_TIP", "Click to switch: mail from anyone, your characters, friends, your guild, everyone else.");
M.Default("UMM_M_IN_SEARCH", "Search sender or subject");
M.Default("UMM_M_IN_CHECKALL", "Tick all");
M.Default("UMM_M_IN_UNCHECK", "Untick %d");
M.Default("UMM_M_IN_CHECK_TIP", "Ticks every mail the list shows. Ctrl-click a mail (or its box) to tick it, Shift-click to tick everything up to it.");
M.Default("UMM_M_IN_TAKEALL", "Take all %d");
M.Default("UMM_M_IN_TAKE", "Take %d");
M.Default("UMM_M_IN_TAKE_TIP", "Takes gold, diamonds and items from the ticked mails, or from every mail the list shows when none is ticked. C.O.D. mails are left out, and so is gold that would take this character past 999,999,999.");
M.Default("UMM_M_IN_RETURN", "Return %d");
M.Default("UMM_M_IN_RETURN_TIP", "Sends the ticked mails back to their senders, with everything still attached.");
M.Default("UMM_M_IN_DELETE", "Delete %d");
M.Default("UMM_M_IN_DELETE_TIP", "Deletes the ticked mails that are empty. With none ticked: every mail the list shows that is empty and already read.");
M.Default("UMM_M_IN_CLEAN", "Delete emptied");
M.Default("UMM_M_IN_CLEAN_TIP", "When on, Take deletes the mails it emptied once it is done (the same setting as the classic window's).");
M.Default("UMM_M_IN_MAILS", "%d mails");
M.Default("UMM_M_IN_UNREADN", "%d unread");
M.Default("UMM_M_IN_GOLDN", "%s gold");
M.Default("UMM_M_IN_GEMSN", "%s diamonds");
M.Default("UMM_M_IN_CODN", "%d C.O.D.");
M.Default("UMM_M_IN_NONE", "No mail matches.");
M.Default("UMM_M_IN_SKIPCAP", "%d gold mails stay in the inbox: taking them would take this character past 999,999,999 gold.");
M.Default("UMM_M_IN_SKIPCOD", "%d C.O.D. mails stay in the inbox: open one and pay to take it.");
M.Default("UMM_M_IN_NOTHING", "Nothing to do for these mails.");
M.Default("UMM_M_IN_DONE", "Done.");
M.Default("UMM_M_RD_FROM", "From");
M.Default("UMM_M_RD_PICK", "Click a mail to see it here.");
M.Default("UMM_M_RD_LEFT", "%s left");
M.Default("UMM_M_RD_READ", "read");
M.Default("UMM_M_RD_NOTREAD", "not read yet");
M.Default("UMM_M_RD_RETURNED", "sent back to you");
M.Default("UMM_M_RD_SYSTEM", "from the game");
M.Default("UMM_M_RD_UNREADNOTE", "Not read yet. The text shows once you read it.");
M.Default("UMM_M_RD_SHOW", "Read this mail");
M.Default("UMM_M_RD_SHOW_TIP", "Shows the text and every item. Reading a mail cuts the time it stays in the inbox to 3 days (the game's rule), so the list never reads mails on its own.");
M.Default("UMM_M_RD_ATTACHED", "Attached");
M.Default("UMM_M_RD_ITEMS1", "1 item");
M.Default("UMM_M_RD_ITEMS", "%d items");
M.Default("UMM_M_RD_MORE", "+%d more");
M.Default("UMM_M_RD_NOTHING", "Nothing attached.");
M.Default("UMM_M_RD_COD", "C.O.D.: pay %s gold for it");
M.Default("UMM_M_RD_PAY", "Pay C.O.D.");
M.Default("UMM_M_RD_PAY_TIP", "Tick to pay the C.O.D. price when you take this mail.");
M.Default("UMM_M_RD_TAKE", "Take");
M.Default("UMM_M_RD_TAKE_TIP", "Takes everything attached to this mail.");
M.Default("UMM_M_RD_REPLY", "Reply");
M.Default("UMM_M_RD_RETURN", "Return");
M.Default("UMM_M_RD_DELETE", "Delete");
M.Default("UMM_M_RD_CAP", "Taking %s gold would take this character past 999,999,999.");
M.Default("UMM_M_RD_CODGOLD", "Not enough gold on this character for the C.O.D. price.");
M.Default("UMM_M_RD_NOARRIVE", "Nothing arrived from that mail (bags full, or the gold limit).");

local ROWS, ROW_H = 14, 22;
local LIST_X, LIST_Y, LIST_W = 8, 62, 436;
local BAR_X, BAR_W, BAR_H = 446, 8, ROWS * ROW_H;
local READER_ITEMS = 5;
local TAKE_TIMEOUT = 6;

local KINDS = { "all", "gold", "items", "gems", "unread" };
local KIND_TEXT = { all = "UMM_M_IN_ALL", gold = "UMM_M_IN_GOLD", items = "UMM_M_IN_ITEMS", gems = "UMM_M_IN_GEMS", unread = "UMM_M_IN_UNREAD" };
local CHIP_W = { 56, 60, 62, 84, 70 };
local FROMS = { "any", "Character", "Friend", "Guildie", "Other" };
local FROM_TEXT = { any = "UMM_M_IN_FROM_ANY", Character = "UMM_M_IN_FROM_OWN", Friend = "UMM_M_IN_FROM_FRIEND",
                    Guildie = "UMM_M_IN_FROM_GUILD", Other = "UMM_M_IN_FROM_OTHER" };

local kind, from, search = "all", "any", "";
local shown, shownCount, inShown = {}, 0, {};
local counts = {};
local offset = 0;
local checked = {};      -- mail index -> true (ticked)
local current = nil;     -- mail index in the reader
local anchorPos = nil;   -- list position of the last click, for Shift-click
local seenMails, seenCount = nil, 0;
local locked = false;    -- inbox automation running (Take, Return, Delete of many)
local autoText = false;  -- the status line shows the automation's text
local taking = nil;      -- the reader's Take: { index, time }
local payCOD = false;
local bodyKey = nil;
local rows, reader = {}, {};
local bar, thumb, thumbH = nil, nil, 0;
local summary, emptyList, chips;

local function attached(mail)
  return mail.AttachedMoney + mail.AttachedItems + mail.AttachedDiamonds;
end

-- What identifies a mail across a reload of the inbox (the game renumbers mails when one goes).
local function sig(mail)
  return (mail.Author or "").."\1"..(mail.Subject or "").."\1"..mail.AttachedMoney.."\1"..mail.AttachedDiamonds
    .."\1"..mail.AttachedItems.."\1"..mail.CODAmount;
end

local function whoOf(mail)
  local who = mail.ummWho;
  if (not who) then
    local _, kindName = M.WhoColor(mail.Author);
    who = kindName or "Other";
    mail.ummWho = who;
  end
  return who;
end

local function lowerOf(mail)
  local text = mail.ummLower;
  if (not text) then
    text = string.lower((mail.Author or "").."\n"..(mail.Subject or ""));
    mail.ummLower = text;
  end
  return text;
end

local function kindMatch(mail, k)
  if (k == "gold") then return mail.AttachedMoney > 0; end
  if (k == "items") then return mail.AttachedItems > 0; end
  if (k == "gems") then return mail.AttachedDiamonds > 0; end
  if (k == "unread") then return not mail.WasRead; end
  return true;
end

-- The game rebuilt the mail list: keep the ticks and the reader on the same mails.
local function remap()
  local mails = MM.Mails;
  if (mails == seenMails) then return; end
  local old, oldCount = seenMails, seenCount;
  seenMails, seenCount = mails, MM.MailCount;
  local want = nil;
  if (old) then
    for index in pairs(checked) do
      local mail = old[index];
      if (mail) then
        want = want or {};
        local s = sig(mail);
        want[s] = (want[s] or 0) + 1;
      end
    end
  end
  local before = current;
  local curSig = before and old and old[before] and sig(old[before]);
  checked = {};
  current = nil;
  if (want or curSig) then
    for i = 1, MM.MailCount do
      local mail = mails[i];
      if (mail) then
        local s = sig(mail);
        if (want and (want[s] or 0) > 0) then
          checked[i] = true;
          want[s] = want[s] - 1;
        end
        if (curSig == s and (current == nil or i == before)) then current = i; end
      end
    end
  end
  -- the reader's mail changed in place (emptied by Take): same count, same place
  if (before and not current and old and MM.MailCount == oldCount and mails[before]) then current = before; end
end

local function filter()
  for i = shownCount, 1, -1 do shown[i] = nil; end
  for index in pairs(inShown) do inShown[index] = nil; end
  shownCount = 0;
  for _, k in ipairs(KINDS) do counts[k] = 0; end
  for i = 1, MM.MailCount do
    local mail = MM.Mails[i];
    if (mail and (from == "any" or whoOf(mail) == from)
        and (search == "" or string.find(lowerOf(mail), search, 1, true))) then
      for _, k in ipairs(KINDS) do
        if (kindMatch(mail, k)) then counts[k] = counts[k] + 1; end
      end
      if (kindMatch(mail, kind)) then
        shownCount = shownCount + 1;
        shown[shownCount] = i;
        inShown[i] = true;
      end
    end
  end
  offset = math.max(0, math.min(offset, shownCount - ROWS));
end

local function anyChecked()
  return next(checked) ~= nil;
end

-- Mails a bulk action works on, in inbox order (the automation goes in that order too): the
-- ticked ones, or the shown ones when none is ticked. Tags them for the automation when tag is set.
-- Returns how many, and how many gold and C.O.D. mails Take leaves out.
local function pick(action, tag)
  local ticked = anyChecked();
  if (action == "return" and not ticked) then return 0, 0, 0; end
  if (tag) then MM:UnTagAll(); end
  local hand = M.OnHand();
  local n, capped, cod = 0, 0, 0;
  for i = 1, MM.MailCount do
    local mail = MM.Mails[i];
    if (mail and ((ticked and checked[i]) or (not ticked and inShown[i]))) then
      local ok = false;
      if (action == "take") then
        if (mail.CODAmount > 0) then
          cod = cod + 1;
        elseif (attached(mail) > 0) then
          if (mail.AttachedMoney > 0 and hand + mail.AttachedMoney > M.CAP) then
            capped = capped + 1;
          else
            ok = true;
            hand = hand + mail.AttachedMoney;
          end
        end
      elseif (action == "return") then
        ok = attached(mail) + mail.CODAmount > 0 and mail.CanReply and not mail.WasReturned;
      elseif (action == "delete") then
        ok = attached(mail) + mail.CODAmount == 0 and (ticked or mail.WasRead);
      end
      if (ok) then
        n = n + 1;
        if (tag) then MM:Tag(i); end
      end
    end
  end
  return n, capped, cod;
end

local function setMedia(tex, file)
  tex:SetTexture(M.MEDIA..file..".tga");
end

-- ### Drawing ###

local function drawRow(i)
  local row = rows[i];
  local index = shown[offset + i];
  local mail = index and MM.Mails[index];
  row.ummIndex = index;
  if (not mail) then
    row:Hide();
    return;
  end
  local auto = MM:IsAutomating();
  local on = (auto and mail.Tagged) or (not auto and checked[index]);
  M.ButtonIcon(row.ummCheck, on and "CheckboxOn" or "CheckboxOff");
  row.ummIcon:SetTexture(mail.Icon);
  row.ummCount:SetText(mail.AttachedItems > 1 and tostring(mail.AttachedItems) or "");
  M.SetText(row.ummFrom, mail.Author, (M.WhoColor(mail.Author)));
  M.SetText(row.ummSubject, mail.Subject, (mail.CODAmount > 0 and C.warn) or (mail.WasRead and C.dim) or C.text);
  if (mail.AttachedMoney > 0) then
    M.SetText(row.ummMoney, M.Gold(mail.AttachedMoney), C.gold);
    setMedia(row.ummCoin, "Gold");
    row.ummCoin:Show();
  elseif (mail.AttachedDiamonds > 0) then
    M.SetText(row.ummMoney, M.Gold(mail.AttachedDiamonds), C.gem);
    setMedia(row.ummCoin, "gem");
    row.ummCoin:Show();
  elseif (mail.CODAmount > 0) then
    M.SetText(row.ummMoney, M.Gold(mail.CODAmount), C.warn);
    setMedia(row.ummCoin, "cod");
    row.ummCoin:Show();
  else
    row.ummMoney:SetText("");
    row.ummCoin:Hide();
  end
  local days, dayColor = M.Days(mail.DaysLeft);
  M.SetText(row.ummDays, days, dayColor);
  M.Select(row, index == current);
  row:Show();
end

local function drawBar()
  if (shownCount <= ROWS) then
    bar:Hide();
    return;
  end
  bar:Show();
  thumbH = math.max(18, math.floor(BAR_H * ROWS / shownCount));
  local y = math.floor((BAR_H - thumbH) * offset / (shownCount - ROWS) + 0.5);
  M.Place(thumb, bar, 0, y, BAR_W, thumbH);
  thumb.ummFill:SetHeight(thumbH);
end

local function chipText(k)
  return getglobal(KIND_TEXT[k]).."  "..(counts[k] or 0);
end

local function drawList()
  for i = 1, ROWS do drawRow(i); end
  drawBar();
  local text = "";
  if (MM.MailCount == 0) then
    text = (M.status and M.status:GetText() == UMM_INBOX_LOADING) and UMM_INBOX_LOADING or UMM_INBOX_EMPTY;
  elseif (shownCount == 0) then
    text = UMM_M_IN_NONE;
  end
  emptyList:SetText(text);
  for i, k in ipairs(KINDS) do
    local chip = chips[i];
    M.ButtonText(chip, chipText(k));
    M.Select(chip, k == kind);
  end
  M.ButtonText(UMMModernInboxFrom, string.format(UMM_M_IN_FROM, getglobal(FROM_TEXT[from])));
  M.Select(UMMModernInboxFrom, from ~= "any");
end

local function drawSummary()
  local unread, cod = 0, 0;
  for i = 1, MM.MailCount do
    local mail = MM.Mails[i];
    if (mail and not mail.WasRead) then unread = unread + 1; end
    if (mail and mail.CODAmount > 0) then cod = cod + 1; end
  end
  local text = string.format(UMM_M_IN_MAILS, MM.MailCount);
  if (unread > 0) then text = text.."  ·  "..string.format(UMM_M_IN_UNREADN, unread); end
  if (MM.InboxTotalMoney > 0) then text = text.."  ·  "..string.format(UMM_M_IN_GOLDN, M.Gold(MM.InboxTotalMoney)); end
  if (MM.InboxTotalDiamonds > 0) then text = text.."  ·  "..string.format(UMM_M_IN_GEMSN, M.Gold(MM.InboxTotalDiamonds)); end
  if (cod > 0) then text = text.."  ·  "..string.format(UMM_M_IN_CODN, cod); end
  summary:SetText(MM.MailCount > 0 and text or "");
  M.TabText("inbox", UMM_M_TAB_INBOX..(MM.MailCount > 0 and ("  "..MM.MailCount) or ""));
end

local function drawButtons()
  local busy = locked or taking ~= nil or M.Busy();
  local ticked = anyChecked();
  local takeN = pick("take");
  M.ButtonText(UMMModernInboxTake, string.format(ticked and UMM_M_IN_TAKE or UMM_M_IN_TAKEALL, takeN));
  M.Enable(UMMModernInboxTake, takeN > 0 and not busy);
  local returnN = pick("return");
  M.ButtonText(UMMModernInboxReturn, string.format(UMM_M_IN_RETURN, returnN));
  M.Enable(UMMModernInboxReturn, returnN > 0 and not busy);
  local deleteN = pick("delete");
  M.ButtonText(UMMModernInboxDelete, string.format(UMM_M_IN_DELETE, deleteN));
  M.Enable(UMMModernInboxDelete, deleteN > 0 and not busy);
  local n = 0;
  for _ in pairs(checked) do n = n + 1; end
  M.ButtonText(UMMModernInboxSelect, n > 0 and string.format(UMM_M_IN_UNCHECK, n) or UMM_M_IN_CHECKALL);
  M.Enable(UMMModernInboxSelect, not locked and (n > 0 or shownCount > 0));
  M.ButtonIcon(UMMModernInboxClean, UMMSettings:Get("CheckTakeDeleteEmpty") ~= false and "CheckboxOn" or "CheckboxOff");
end

-- ### The reader ###

local function hideReaderDetail()
  for _, key in ipairs({ "fromLabel", "sender", "subject", "info", "unread", "attachedLabel", "more", "money", "coin" }) do
    reader[key]:Hide();
  end
  UMMModernReaderBody:Hide();
  UMMModernReaderShow:Hide();
  UMMModernReaderCOD:Hide();
  for k = 1, READER_ITEMS do getglobal("UMMModernReaderItem"..k):Hide(); end
  for _, name in ipairs({ "Take", "Reply", "Return", "Delete" }) do getglobal("UMMModernReader"..name):Hide(); end
end

local function showReaderDetail()
  for _, key in ipairs({ "fromLabel", "sender", "subject", "info", "attachedLabel" }) do reader[key]:Show(); end
  for _, name in ipairs({ "Take", "Reply", "Return", "Delete" }) do getglobal("UMMModernReader"..name):Show(); end
end

local function setItem(k, texture, count, pos)
  local b = getglobal("UMMModernReaderItem"..k);
  b.ummPos = pos;
  b.ummIcon:SetTexture(texture or "");
  b.ummCount:SetText((count and count > 1) and tostring(count) or "");
  b:Show();
end

local function drawReader()
  local mail = current and MM.Mails[current];
  if (not mail) then
    hideReaderDetail();
    reader.empty:SetText(UMM_M_RD_PICK);
    bodyKey = nil;
    return;
  end
  reader.empty:SetText("");
  showReaderDetail();
  M.SetText(reader.sender, mail.Author, (M.WhoColor(mail.Author)));
  reader.subject:SetText(mail.Subject or "");
  local days = M.Days(mail.DaysLeft);
  local info = string.format(UMM_M_RD_LEFT, days).."  ·  "..(mail.WasRead and UMM_M_RD_READ or UMM_M_RD_NOTREAD);
  if (mail.WasReturned) then info = info.."  ·  "..UMM_M_RD_RETURNED; end
  if (not mail.CanReply) then info = info.."  ·  "..UMM_M_RD_SYSTEM; end
  reader.info:SetText(info);

  for k = 1, READER_ITEMS do getglobal("UMMModernReaderItem"..k):Hide(); end
  reader.more:SetText("");
  reader.more:Show();
  if (mail.WasRead) then
    UMMModernReaderShow:Hide();
    reader.unread:Hide();
    UMMModernReaderBody:Show();
    local key = current.."\1"..sig(mail);
    if (key ~= bodyKey) then
      bodyKey = key;
      M.SetEditText(UMMModernReaderBody, GetInboxText(current) or "");
    end
    -- the mail is read already: its items can be listed (reading again changes nothing)
    local n = 0;
    if (mail.AttachedItems > 0 or mail.CODAmount > 0) then
      for pos = 1, 10 do
        local name, texture, count = GetInboxItem(current, pos);
        if (name and texture) then
          n = n + 1;
          if (n <= READER_ITEMS) then setItem(n, texture, count, pos); end
        end
      end
    end
    if (n > READER_ITEMS) then reader.more:SetText(string.format(UMM_M_RD_MORE, n - READER_ITEMS)); end
  else
    bodyKey = nil;
    UMMModernReaderBody:Hide();
    M.SetEditText(UMMModernReaderBody, "");
    reader.unread:SetText(UMM_M_RD_UNREADNOTE);
    reader.unread:Show();
    UMMModernReaderShow:Show();
    if (mail.AttachedItems > 0) then
      -- the header has the first item's icon; the rest shows once the mail is read
      setItem(1, mail.Icon, nil, nil);
      reader.more:SetText(mail.AttachedItems == 1 and UMM_M_RD_ITEMS1 or string.format(UMM_M_RD_ITEMS, mail.AttachedItems));
    end
  end

  reader.coin:Show();
  reader.money:Show();
  if (mail.AttachedMoney > 0) then
    setMedia(reader.coin, "Gold");
    M.SetText(reader.money, M.Gold(mail.AttachedMoney), C.gold);
  elseif (mail.AttachedDiamonds > 0) then
    setMedia(reader.coin, "gem");
    M.SetText(reader.money, string.format(UMM_M_IN_GEMSN, M.Gold(mail.AttachedDiamonds)), C.gem);
  elseif (mail.CODAmount > 0) then
    setMedia(reader.coin, "cod");
    M.SetText(reader.money, string.format(UMM_M_RD_COD, M.Gold(mail.CODAmount)), C.warn);
  elseif (mail.AttachedItems == 0) then
    reader.coin:Hide();
    M.SetText(reader.money, UMM_M_RD_NOTHING, C.dim);
  else
    reader.coin:Hide();
    reader.money:Hide();
  end
  if (mail.CODAmount > 0) then
    UMMModernReaderCOD:Show();
    M.ButtonIcon(UMMModernReaderCOD, payCOD and "CheckboxOn" or "CheckboxOff");
  else
    UMMModernReaderCOD:Hide();
  end

  local busy = locked or taking ~= nil or M.Busy();
  local hasStuff = attached(mail) > 0 or (mail.CODAmount > 0 and mail.AttachedItems > 0);
  M.Enable(UMMModernReaderTake, hasStuff and not busy and (mail.CODAmount == 0 or payCOD));
  M.Enable(UMMModernReaderReply, mail.CanReply and not busy);
  M.Enable(UMMModernReaderReturn, attached(mail) + mail.CODAmount > 0 and mail.CanReply and not mail.WasReturned and not busy);
  M.Enable(UMMModernReaderDelete, attached(mail) + mail.CODAmount == 0 and not busy);
  for k = 1, READER_ITEMS do
    M.Enable(getglobal("UMMModernReaderItem"..k), not busy);
  end
end

local function draw()
  if (not I.frame:IsVisible()) then return; end
  drawList();
  drawButtons();
  drawReader();
end

-- Reads the game's list again (after a mail was read, returned or deleted here).
local function reload()
  MM:InboxRefresh();
  I.Refresh();
end

function I.Refresh()
  remap();
  filter();
  drawSummary();
  draw();
end

local function setOffset(value)
  value = math.max(0, math.min(value, shownCount - ROWS));
  if (value == offset) then return; end
  offset = value;
  for i = 1, ROWS do drawRow(i); end
  drawBar();
end

local function wheel(_, delta)
  setOffset(offset - (delta > 0 and 3 or -3));
end

-- The mail at list position pos goes in the reader (after the one there was returned or deleted).
local function showAt(pos)
  current = shown[pos] or shown[pos - 1];
  payCOD = false;
  if (current) then
    if (pos <= offset) then setOffset(pos - 1); elseif (pos > offset + ROWS) then setOffset(pos - ROWS); end
  end
  draw();
end

local function positionOf(index)
  for pos = 1, shownCount do
    if (shown[pos] == index) then return pos; end
  end
end

-- ### Actions ###

local function blocked()
  if (locked or taking or M.Busy()) then
    UMMPrompt(UMM_ERROR_STILLSENDING);
    return true;
  end
  return false;
end

local function run(action)
  if (blocked()) then return; end
  local n, capped, cod = pick(action, true);
  if (n == 0) then
    MM:UnTagAll();
    M.Status(UMM_M_IN_NOTHING, C.warn);
    draw();
    return;
  end
  if (capped > 0) then UMMPrompt("|r|cff"..UMMColor.Yellow..string.format(UMM_M_IN_SKIPCAP, capped)); end
  if (cod > 0) then UMMPrompt("|r|cff"..UMMColor.Yellow..string.format(UMM_M_IN_SKIPCOD, cod)); end
  checked = {};
  anchorPos = nil;
  MM:StartAutomation(action);
  draw();
end

local function checkAll()
  if (locked) then return; end
  if (anyChecked()) then
    checked = {};
  else
    for pos = 1, shownCount do checked[shown[pos]] = true; end
  end
  anchorPos = nil;
  draw();
end

local function rowClick(row)
  local index = row.ummIndex;
  if (not index or locked) then return; end
  local pos = offset + row.ummRow;
  if (M.Held(IsShiftKeyDown) and anchorPos) then
    for p = math.min(anchorPos, pos), math.max(anchorPos, pos) do
      local i = shown[p];
      if (i) then checked[i] = true; end
    end
  elseif (M.Held(IsCtrlKeyDown)) then
    checked[index] = (not checked[index]) or nil;
    anchorPos = pos;
  else
    if (current ~= index) then payCOD = false; end
    current = index;
    anchorPos = pos;
  end
  draw();
end

local function checkClick(b)
  local row = b.ummRowFrame;
  local index = row.ummIndex;
  if (not index or locked) then return; end
  local pos = offset + row.ummRow;
  if (M.Held(IsShiftKeyDown) and anchorPos) then
    for p = math.min(anchorPos, pos), math.max(anchorPos, pos) do
      local i = shown[p];
      if (i) then checked[i] = true; end
    end
  else
    checked[index] = (not checked[index]) or nil;
  end
  anchorPos = pos;
  draw();
end

local function rowEnter(row)
  local index = row.ummIndex;
  local mail = index and MM.Mails[index];
  if (mail and mail.AttachedItems > 0 and GameTooltip and GameTooltip.SetInboxItem) then
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT", 0, 0);
    GameTooltip:SetInboxItem(index);   -- reads nothing: the mail stays unread
    GameTooltip:Show();
    M.tipOwner = row;
  end
end

local function readerTake()
  local index = current;
  local mail = index and MM.Mails[index];
  if (not mail or blocked()) then return; end
  if (mail.AttachedMoney > 0 and M.OnHand() + mail.AttachedMoney > M.CAP) then
    M.Status(string.format(UMM_M_RD_CAP, M.Gold(mail.AttachedMoney)), C.bad);
    return;
  end
  if (mail.CODAmount > 0) then
    if (not payCOD) then
      M.Status(UMM_VIEWER_ATTACHMENT_NOT_ACCEPTED, C.warn);
      return;
    end
    if (M.OnHand() < mail.CODAmount) then
      M.Status(UMM_M_RD_CODGOLD, C.bad);
      return;
    end
  end
  if (MM:GetAttachments(index, mail.CODAmount > 0 and payCOD, "UMMModernReader")) then
    taking = { index = index, time = 0 };
    payCOD = false;
    draw();
  end
end

-- MailManager:UnLock calls this once what was taken has arrived.
function UMMModernReader.RefreshViewer(self)
  local was = taking;
  taking = nil;
  MM:InboxRefresh();
  remap();
  if (was and MM.Mails[was.index] and MM.MailCount == seenCount) then current = was.index; end
  I.Refresh();
end

local function readerShow()
  local index = current;
  if (not index or not MM.Mails[index]) then return; end
  GetInboxText(index);   -- reads the mail: the game marks it read
  reload();
end

local function readerReturn()
  local index = current;
  if (not index or blocked()) then return; end
  local pos = positionOf(index) or 1;
  if (MM:ReturnMail(index)) then
    current = nil;
    reload();
    showAt(pos);
  end
end

local function readerDelete()
  local index = current;
  if (not index or blocked()) then return; end
  local pos = positionOf(index) or 1;
  if (MM:DeleteMail(index)) then
    current = nil;
    I.Refresh();
    showAt(pos);
  end
end

function I.Reply(index, mail)
  if (not mail) then return; end
  local subject = mail.Subject or "";
  if (not string.find(string.lower(subject), "^re:")) then subject = "Re: "..subject; end
  M.ShowPage("compose");
  if (M.pages.compose.Reply) then M.pages.compose.Reply(mail.Author, subject); end
end

-- ### Building ###

local function buildRows()
  local list = UMMModernInboxList;
  M.Hit(list, I.frame, LIST_X, LIST_Y, LIST_W, BAR_H);
  list.ummWheel = wheel;
  for i = 1, ROWS do
    local row = getglobal("UMMModernInboxRow"..i);
    rows[i] = row;
    row.ummRow = i;
    M.Button(row, list, 0, (i - 1) * ROW_H, LIST_W, ROW_H - 1, { style = "row", click = rowClick });
    row.umm.rowAlpha = 0.25;
    row.ummWheel = wheel;
    row.ummEnter = rowEnter;
    local check = getglobal("UMMModernInboxRow"..i.."Check");
    M.Button(check, row, 2, 2, 18, 17, { icon = "CheckboxOff", iconSize = 14, style = "row", click = checkClick });
    check.ummRowFrame = row;
    check.ummWheel = wheel;
    row.ummCheck = check;
    row.ummIcon = M.Icon(row, "ARTWORK", 18);
    M.Place(row.ummIcon, row, 24, 2, 18, 18);
    row.ummCount = M.Label(row, 10, C.text, "RIGHT");
    M.Place(row.ummCount, row, 24, 9, 20, 12);
    row.ummFrom = M.Label(row, 12, C.text, "LEFT");
    M.Place(row.ummFrom, row, 48, 0, 98, ROW_H - 1);
    row.ummSubject = M.Label(row, 12, C.text, "LEFT");
    M.Place(row.ummSubject, row, 150, 0, 156, ROW_H - 1);
    row.ummMoney = M.Label(row, 12, C.gold, "RIGHT");
    M.Place(row.ummMoney, row, 306, 0, 90, ROW_H - 1);
    row.ummCoin = M.Texture(row, "ARTWORK", "Gold");
    M.Place(row.ummCoin, row, 398, 4, 13, 13);
    row.ummDays = M.Label(row, 11, C.dim, "RIGHT");
    M.Place(row.ummDays, row, 410, 0, 24, ROW_H - 1);
    row:Hide();
  end
  emptyList = M.Label(I.frame, 13, C.dim, "CENTER");
  M.Place(emptyList, I.frame, LIST_X, LIST_Y + 120, LIST_W, 24);

  bar = UMMModernInboxBar;
  M.Hit(bar, I.frame, BAR_X, LIST_Y, BAR_W, BAR_H);
  M.Place(M.Texture(bar, "BACKGROUND", "white", C.panel, 1), bar, 0, 0, BAR_W, BAR_H);
  bar.ummWheel = wheel;
  bar.ummDown = function(f)
    local _, y = M.LocalCursor(f);
    if (not y) then return; end
    local top = (BAR_H - thumbH) * offset / math.max(1, shownCount - ROWS);
    setOffset(offset + (y < top and -ROWS or ROWS));
  end;
  thumb = UMMModernInboxThumb;
  M.Hit(thumb, bar, 0, 0, BAR_W, 20);
  thumb.ummOn = M.BUTTON;
  thumb.ummFill = M.Texture(thumb, "ARTWORK", "white", M.STYLES.choice.edge, 0.9);
  M.Place(thumb.ummFill, thumb, 1, 0, BAR_W - 2, 20);
  thumb.ummWheel = wheel;
  thumb.ummDown = function()
    local _, startY = M.LocalCursor(bar);
    if (not startY) then return; end
    local startOffset = offset;
    M.StartDrag(function()
      local _, y = M.LocalCursor(bar);
      local range = BAR_H - thumbH;
      if (not y or range <= 0) then return; end
      setOffset(startOffset + math.floor((y - startY) / range * (shownCount - ROWS) + 0.5));
    end, nil);
  end;
  thumb.ummUp = function() if (M.Dragging()) then M.StopDrag(); end end;
  bar:Hide();
end

local function buildTools()
  local f = I.frame;
  chips = {};
  local x = LIST_X;
  for i, k in ipairs(KINDS) do
    local chip = getglobal("UMMModernInboxFilter"..i);
    chips[i] = chip;
    M.Button(chip, f, x, 6, CHIP_W[i], 22, { text = getglobal(KIND_TEXT[k]), size = 12, style = "quiet",
      tip = { getglobal(KIND_TEXT[k]), UMM_M_IN_CHIP_TIP },
      click = function() kind = k; offset = 0; I.Refresh(); end });
    x = x + CHIP_W[i] + 4;
  end
  M.Button(UMMModernInboxFrom, f, x, 6, LIST_X + LIST_W + BAR_W + 2 - x, 22, { text = "", size = 12, style = "quiet",
    tip = { UMM_M_IN_FROM_TIP }, click = function()
      for i, value in ipairs(FROMS) do
        if (value == from) then from = FROMS[(i % table.getn(FROMS)) + 1]; break; end
      end
      offset = 0;
      I.Refresh();
    end });
  M.Edit(UMMModernInboxSearch, f, LIST_X + 6, 34, 324, 22, { hint = UMM_M_IN_SEARCH, text = function(e)
    search = string.lower(e:GetText() or "");
    offset = 0;
    I.Refresh();
  end });
  UMMModernInboxSearch.ummEsc = function(e) e:SetText(""); end;
  M.Button(UMMModernInboxSelect, f, 344, 34, 110, 22, { text = UMM_M_IN_CHECKALL, size = 12, style = "quiet",
    tip = { UMM_M_IN_CHECKALL, UMM_M_IN_CHECK_TIP }, click = checkAll });

  summary = M.Label(f, 11, C.dim, "LEFT");
  M.Place(summary, f, LIST_X + 2, LIST_Y + BAR_H + 3, LIST_W, 18);

  -- Take, then the Delete emptied toggle beside it: a click that misses Take must not return
  -- mail, so Return sits at the far end
  local y = LIST_Y + BAR_H + 24;
  M.Button(UMMModernInboxTake, f, LIST_X, y, 104, 24, { text = UMM_M_RD_TAKE, icon = "Bag", iconSize = 14, size = 12,
    style = "action", tip = { UMM_M_RD_TAKE, UMM_M_IN_TAKE_TIP }, click = function() run("take"); end });
  M.Button(UMMModernInboxClean, f, LIST_X + 108, y, 134, 24, { text = UMM_M_IN_CLEAN, icon = "CheckboxOn", iconSize = 14,
    size = 12, style = "quiet", tip = { UMM_M_IN_CLEAN, UMM_M_IN_CLEAN_TIP }, click = function()
      UMMSettings:Set("CheckTakeDeleteEmpty", UMMSettings:Get("CheckTakeDeleteEmpty") == false);
      drawButtons();
    end });
  M.Button(UMMModernInboxDelete, f, LIST_X + 246, y, 98, 24, { text = UMM_M_RD_DELETE, icon = "Trash", iconSize = 14,
    size = 12, style = "danger", tip = { UMM_M_RD_DELETE, UMM_M_IN_DELETE_TIP }, click = function() run("delete"); end });
  M.Button(UMMModernInboxReturn, f, LIST_X + 348, y, 98, 24, { text = UMM_M_RD_RETURN, icon = "Reload", iconSize = 14,
    size = 12, style = "quiet", tip = { UMM_M_RD_RETURN, UMM_M_IN_RETURN_TIP }, click = function() run("return"); end });
end

local function buildReader()
  local r = UMMModernReader;
  local W, H = 286, 412;
  M.Place(r, I.frame, 466, 6, W, H);
  r:Show();
  M.Panel(r, 0, 0, W, H, C.panel, M.STYLES.quiet.edge, 0.95);
  reader.empty = M.Label(r, 13, C.dim, "CENTER");
  M.Place(reader.empty, r, 10, 180, W - 20, 24);
  reader.fromLabel = M.Label(r, 11, C.dim, "LEFT");
  M.Place(reader.fromLabel, r, 10, 8, 40, 18);
  reader.fromLabel:SetText(UMM_M_RD_FROM);
  reader.sender = M.Label(r, 13, C.text, "LEFT");
  M.Place(reader.sender, r, 50, 8, W - 60, 18);
  reader.subject = M.Label(r, 13, C.head, "LEFT");
  M.Place(reader.subject, r, 10, 28, W - 20, 18);
  reader.info = M.Label(r, 11, C.dim, "LEFT");
  M.Place(reader.info, r, 10, 48, W - 20, 16);
  M.Edit(UMMModernReaderBody, r, 8, 70, W - 16, 176, {});
  reader.unread = M.Label(r, 12, C.dim, "CENTER");
  M.Place(reader.unread, r, 12, 104, W - 24, 30);
  M.Button(UMMModernReaderShow, r, math.floor((W - 150) / 2), 140, 150, 26, { text = UMM_M_RD_SHOW, icon = "letter",
    iconSize = 16, size = 12, style = "action", tip = { UMM_M_RD_SHOW, UMM_M_RD_SHOW_TIP }, click = readerShow });

  reader.attachedLabel = M.Label(r, 11, C.dim, "LEFT");
  M.Place(reader.attachedLabel, r, 10, 252, W - 20, 16);
  reader.attachedLabel:SetText(UMM_M_RD_ATTACHED);
  for k = 1, READER_ITEMS do
    local b = getglobal("UMMModernReaderItem"..k);
    M.Button(b, r, 10 + (k - 1) * 40, 270, 36, 36, { style = "quiet", click = function() readerTake(); end });
    b.ummIcon = M.Icon(b, "ARTWORK", 30);
    M.Place(b.ummIcon, b, 3, 3, 30, 30);
    b.ummCount = M.Label(b, 11, C.text, "RIGHT");
    M.Place(b.ummCount, b, 2, 20, 31, 14);
    b.ummEnter = function(btn)
      if (not current or not GameTooltip or not GameTooltip.SetInboxItem) then return; end
      GameTooltip:SetOwner(btn, "ANCHOR_RIGHT", 0, 0);
      GameTooltip:SetInboxItem(current, btn.ummPos);   -- reads nothing
      GameTooltip:Show();
      M.tipOwner = btn;
    end;
    b:Hide();
  end
  reader.more = M.Label(r, 12, C.dim, "LEFT");
  M.Place(reader.more, r, 10 + READER_ITEMS * 40, 270, W - 20 - READER_ITEMS * 40, 36);
  reader.coin = M.Texture(r, "ARTWORK", "Gold");
  M.Place(reader.coin, r, 10, 316, 16, 16);
  reader.money = M.Label(r, 13, C.gold, "LEFT");
  M.Place(reader.money, r, 32, 314, W - 42, 20);
  M.Button(UMMModernReaderCOD, r, 8, 340, 150, 22, { text = UMM_M_RD_PAY, icon = "CheckboxOff", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_RD_PAY, UMM_M_RD_PAY_TIP }, click = function() payCOD = not payCOD; drawReader(); end });

  local y = H - 30;
  M.Button(UMMModernReaderTake, r, 8, y, 64, 24, { text = UMM_M_RD_TAKE, size = 12, style = "action",
    tip = { UMM_M_RD_TAKE, UMM_M_RD_TAKE_TIP }, click = readerTake });
  M.Button(UMMModernReaderReply, r, 76, y, 64, 24, { text = UMM_M_RD_REPLY, size = 12, style = "choice",
    click = function() if (current) then MM:ReplyToMail(current); end end });
  M.Button(UMMModernReaderReturn, r, 144, y, 66, 24, { text = UMM_M_RD_RETURN, size = 12, style = "quiet",
    tip = { UMM_M_RD_RETURN, UMM_M_IN_RETURN_TIP }, click = readerReturn });
  M.Button(UMMModernReaderDelete, r, 214, y, 64, 24, { text = UMM_M_RD_DELETE, size = 12, style = "danger",
    click = readerDelete });
  hideReaderDetail();
end

function I.Build()
  buildTools();
  buildRows();
  buildReader();
end

-- ### Page hooks ###

function I.Show()
  I.Refresh();
end

function I.InboxUpdated()
  if (MM.Mails ~= seenMails) then I.Refresh(); end
end

function I.MoneyChanged()
  if (I.frame:IsVisible()) then drawButtons(); end
end

function I.Tick(dt)
  if (taking) then
    taking.time = taking.time + dt;
    if (taking.time > TAKE_TIMEOUT) then
      taking = nil;
      if (not MM:IsAutomating()) then MM:ClearAutomationLock(); end
      M.Status(UMM_M_RD_NOARRIVE, C.warn);
      reload();
    end
  end
end

function I.Closed()
  seenMails, seenCount = nil, 0;
  checked, current, anchorPos, taking, payCOD, bodyKey = {}, nil, nil, nil, false, nil;
  locked, autoText = false, false;
  offset = 0;
  M.SetEditText(UMMModernInboxSearch, "");
  search = "";
end

-- ### What the inbox automation shows (Library/MailManager.lua talks to the window through this) ###

M.View = {
  RefreshTOC = function(self) I.Refresh(); end,
  ShowInboxStatus = function(self)
    drawSummary();
    if (M.Busy() or MM:IsAutomating()) then return; end
    local text = M.status:GetText() or "";
    if (text == "" or text == UMM_INBOX_LOADING) then
      M.Status(MM.MailCount == 0 and UMM_INBOX_EMPTY or UMM_M_READY, C.dim);
      draw();
    end
  end,
  Lock = function(self)
    locked = true;
    draw();
  end,
  UnLock = function(self)
    locked = false;
    if (autoText) then
      autoText = false;
      M.Status(UMM_M_IN_DONE, C.good);
    end
    draw();
  end,
  SetStatus = function(self, text)
    if (text == nil or text == "") then
      autoText = false;
      M.Status("");
    else
      autoText = true;
      M.Status(text, C.text);
    end
  end,
  ShowBar = function(self) end,
  HideBar = function(self) end,
  DisableTabs = function(self) M.RefreshStop(); end,
  EnableTabs = function(self) M.RefreshStop(); end,
  -- the page tags the mails itself; whatever is tagged is taken whole
  TakeFilter = function(self) return 1; end,
  TakeDeleteEmpty = function(self) return UMMSettings:Get("CheckTakeDeleteEmpty") ~= false; end,
  Reply = function(self, mailIndex, mailObject) I.Reply(mailIndex, mailObject); end,
};
