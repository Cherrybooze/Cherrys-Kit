-- Cherry's Kit: the Compose page of the modern mail window. One name in To, one mail in mind, and
-- whatever does not fit one mail goes out as more mails to the same name: each item in its own mail
-- (drop items on +), text longer than a mail holds in numbered parts. The box beside C.O.D. is the
-- gold for the name in To (with the text when there are no items), or the C.O.D. price of each item
-- mail while C.O.D. is ticked; the two preset buttons beside it fill it in. Extra gold mails on the
-- right go to any names, one row each (up to 999,999,999 a row). All gold is taken from the inbox's
-- gold mails when this character does not carry enough (Modern/Plan.lua works out the order). Send
-- shows the whole list first whenever it is more than one plain mail; Modern/Queue.lua sends it.

local M = UMMModern;
local C = M.C;
local P = M.Plan;
local K = M.Picker;
local MM = UMMMailManager;
local Page = { frame = UMMModernCompose };
M.pages.compose = Page;

M.Default("UMM_M_CO_TO", "To");
M.Default("UMM_M_CO_TO_HINT", "Name");
M.Default("UMM_M_CO_PICK_TIP", "Names: recently mailed, your characters, friends, guild.");
M.Default("UMM_M_CO_LAST", "Use last");
M.Default("UMM_M_CO_LAST_TIP", "Puts the last name you mailed on this server in To. Shared by your characters there.");
M.Default("UMM_M_CO_SUBJECT", "Subject");
M.Default("UMM_M_CO_SUBJECT_HINT", "Item mails use the item's name when this is empty");
M.Default("UMM_M_CO_BODY_HINT", "Text. Longer than one mail holds? It goes out in numbered parts.");
M.Default("UMM_M_CO_COUNT", "%s / 2,000");
M.Default("UMM_M_CO_COUNT_PARTS", "%s letters: %d mails, numbered in the subject");
M.Default("UMM_M_CO_ITEMS", "Items");
M.Default("UMM_M_CO_SLOT_TIP", "Click to take it out of this mail.");
M.Default("UMM_M_CO_ADD", "Add an item");
M.Default("UMM_M_CO_ADD_TIP", "Drop an item from your bags here (or click here while holding one). It goes in its own mail to the same name, with the same subject.");
M.Default("UMM_M_CO_BOUND", "%s is bound and can't be mailed.");
M.Default("UMM_M_CO_TWICE", "%s is in this mail already.");
M.Default("UMM_M_CO_FULL", "10 items at most here. For more, use Mass send.");
M.Default("UMM_M_CO_GONE", "%s is no longer in that bag slot, so it was taken out of the mail.");
M.Default("UMM_M_CO_BAGERR", "The game did not say which bag slot that item came from. Move a few items in your bag and try again.");
M.Default("UMM_M_CO_COD", "C.O.D.");
M.Default("UMM_M_CO_COD_TIP", "Ticked: the box beside it is the C.O.D. price, the gold each item mail asks before the receiver can take its item. Unticked (always the start): the box is gold for the name in To. Switching empties the box.");
M.Default("UMM_M_CO_COD_HINT", "C.O.D. price, each item mail");
M.Default("UMM_M_CO_GOLD", "Gold");
M.Default("UMM_M_CO_GOLD_HINT", "gold to send");
M.Default("UMM_M_CO_GOLD_TIP", "Gold for the name in To, up to 999,999,999. With text and no items it goes in the same mail. Gold for more names: Extra gold mails on the right.");
M.Default("UMM_M_CO_PRESET", "Gold preset %d");
M.Default("UMM_M_CO_PRESET_TIP", "Puts %s gold in the gold box (C.O.D. goes off). Change both amounts in the settings (cog).");
M.Default("UMM_M_CO_COD_ITEM", "C.O.D. needs an item.");
M.Default("UMM_M_CO_COD_AMOUNT", "Enter the C.O.D. price.");
M.Default("UMM_M_CO_RESET", "Reset");
M.Default("UMM_M_CO_RESET_TIP", "Empties subject, text, items, gold and the extra gold mails; To stays. Once more empties To too.");
M.Default("UMM_M_CO_SEND", "Send");
M.Default("UMM_M_CO_SENDN", "Send %d mails");
M.Default("UMM_M_CO_EMPTY", "Write a mail, drop items on +, or enter gold.");
M.Default("UMM_M_CO_PLAN_MAIN1", "1 mail to %s");
M.Default("UMM_M_CO_PLAN_MAIN", "%d mails to %s");
M.Default("UMM_M_CO_PLAN_ITEMS", "%d with an item");
M.Default("UMM_M_CO_PLAN_PARTS", "text in %d parts");
M.Default("UMM_M_CO_PLAN_GOLDPART", "%s gold");
M.Default("UMM_M_CO_PLAN_GOLD", "%d gold mails, %s gold");
M.Default("UMM_M_CO_PLAN_GOLD1", "1 gold mail, %s gold");
M.Default("UMM_M_CO_PLAN_TAKES", "First takes the gold of %d inbox mails, one at a time.");
M.Default("UMM_M_CO_PLAN_COD", "C.O.D. %s on each item mail.");
M.Default("UMM_M_CO_YOU", "that is you");
M.Default("UMM_M_CO_WHO_OWN", "your character");
M.Default("UMM_M_CO_WHO_FRIEND", "friend");
M.Default("UMM_M_CO_WHO_GUILD", "guild");
M.Default("UMM_M_GO_TITLE", "Extra gold mails");
M.Default("UMM_M_GO_HAND", "On this character");
M.Default("UMM_M_GO_INBOX", "In the inbox");
M.Default("UMM_M_GO_INBOXN", "%s in %d mails");
M.Default("UMM_M_GO_NONE", "no gold mails");
M.Default("UMM_M_GO_FILL", "Use inbox gold");
M.Default("UMM_M_GO_FILL_TIP", "One row per gold mail in the inbox (up to 8), each with that mail's gold. Put a name in each row, or leave it empty for the name in To. Send takes the gold out of those mails and sends it on, one mail at a time, so this character never carries more than 999,999,999.");
M.Default("UMM_M_GO_CLEAR", "Clear");
M.Default("UMM_M_GO_ADD", "Add gold mail");
M.Default("UMM_M_GO_ADD_TIP", "One more gold mail: a name (empty: the name in To) and up to 999,999,999 gold, the most one mail holds. Gold for the name in To alone goes in the box beside C.O.D.");
M.Default("UMM_M_GO_TO", "To");
M.Default("UMM_M_GO_AMOUNT", "Gold");
M.Default("UMM_M_GO_SAME", "same as To");
M.Default("UMM_M_GO_SAMEAS", "= %s");
M.Default("UMM_M_GO_REMOVE", "Remove this row");
M.Default("UMM_M_GO_TOTAL", "Total %s gold in %d mails");
M.Default("UMM_M_GO_TOTAL1", "Total %s gold in 1 mail");
M.Default("UMM_M_GO_SHORT", "Row %d is %s short");
M.Default("UMM_M_GO_MORE", "%d more gold mails in the inbox: 8 rows at most, send again for the rest.");
M.Default("UMM_M_RV_TITLE", "Check before sending");
M.Default("UMM_M_RV_SUMMARY", "%d mails, in this order. Stop (bottom right) ends after the mail on its way.");
M.Default("UMM_M_RV_SUMMARY_TAKES", "%d mails and %d gold takes from the inbox, in this order. Stop (bottom right) ends after the mail on its way.");
M.Default("UMM_M_RV_BACK", "Back");
M.Default("UMM_M_RV_TAKE", "Take %s gold from %s's mail");
M.Default("UMM_M_RV_GOLD", "%s gold to %s");
M.Default("UMM_M_RV_ITEM", "%s to %s");
M.Default("UMM_M_RV_TEXT", "Text part %d/%d to %s");
M.Default("UMM_M_RV_MAIL", "\"%s\" to %s");
M.Default("UMM_M_RV_NOTE", "  + the text");
M.Default("UMM_M_RV_PART", "  + text %d/%d");
M.Default("UMM_M_RV_CODN", "  C.O.D. %s");

local SLOTS, GOLD_ROWS = 10, 8;
-- The item row sits below the name list (it opens under To and ends at 272), so all of the row,
-- C.O.D., the gold box and its presets stay in reach while the list is open.
local SLOT, SLOT_GAP, SLOT_X, SLOT_Y = 38, 42, 54, 282;
local COD_Y = SLOT_Y + SLOT + 8;
local MONEY_X, MONEY_W = 100, 130;
local PRESET_X, PRESET_W, PRESET_GAP = 238, 104, 4;
local ROWS_Y, ROW_STEP = 128, 28;
local REVIEW_LINES = 14;

local items = {};        -- { index, link, name, count, icon }: one mail each
local rowCount = 0;      -- gold rows shown
local codOn = false;     -- the box beside C.O.D. is its price (else gold for To); off at every start
local sending = nil;     -- this page's run: { parts, sentParts }
local reviewPlan, reviewOffset = nil, 0;
local ui = {};
local slots, goldRow, goldTo, goldAmount, goldRemove, presets = {}, {}, {}, {}, {}, {};
local lastPlan = nil;
local autoSubject = nil;  -- the subject as this page filled it in (nil: empty or typed by the player)
local firstKind = nil;    -- "item" or "gold": which came first, for that subject
local subjectEmptied = false;  -- the player emptied the subject: it fills in again once they leave it
local itemNote = nil;     -- the status line's last word on an item that could not go in

local function trim(text)
  return string.match(text or "", "^%s*(.-)%s*$") or "";
end

-- The text of the mail. Text pasted from Windows brings a carriage return with every line break;
-- the client keeps them in the box, so they are left out here and never reach the mail.
local function bodyText()
  local body = UMMModernComposeBody:GetText() or "";
  if (string.find(body, "\r", 1, true)) then body = string.gsub(body, "\r", ""); end
  return body;
end

local function readForm()
  local subject = UMMModernComposeSubject:GetText() or "";
  local form = {
    to = trim(UMMModernComposeTo:GetText()),
    subject = subject,
    body = bodyText(),
    items = items,
    cod = 0,
    gold = {},
  };
  if (autoSubject and subject == autoSubject) then
    -- filled in from the first item or gold: item and gold mails still say what each one holds
    form.subject, form.autoSubject = "", subject;
  end
  local money = M.GoldOf(UMMModernComposeMoney);
  if (codOn) then
    form.cod = money or 0;
  elseif (money) then
    -- gold for the name in To: the first gold of the Send, ahead of the extra gold mails (row 0)
    table.insert(form.gold, { to = "", amount = money, row = 0 });
  end
  for i = 1, rowCount do
    local amount = M.GoldOf(goldAmount[i]);
    if (amount) then table.insert(form.gold, { to = trim(goldTo[i]:GetText()), amount = amount, row = i }); end
  end
  return form;
end

local function inboxPool()
  return P.Pool(MM.Mails, MM.MailCount);
end

local function compute(form)
  local plan = P.Compose(form, { hand = M.OnHand(), pool = inboxPool(), player = UnitName("player") });
  if (codOn) then
    if (table.getn(items) == 0) then
      table.insert(plan.errors, 1, UMM_M_CO_COD_ITEM);
    elseif (form.cod == 0) then
      table.insert(plan.errors, 1, UMM_M_CO_COD_AMOUNT);
    end
  end
  return plan;
end

local function isEmpty(form)
  return form.subject == "" and form.body == "" and table.getn(items) == 0 and table.getn(form.gold) == 0;
end

-- ### Drawing ###

local function drawCounter()
  local body = bodyText();
  local len = string.len(body);
  if (len <= P.BODY_LIMIT) then
    M.SetText(ui.counter, string.format(UMM_M_CO_COUNT, M.Gold(len)), C.dim);
  else
    M.SetText(ui.counter, string.format(UMM_M_CO_COUNT_PARTS, M.Gold(len), table.getn(P.SplitBody(body))), C.head);
  end
end

local function drawWho()
  local name = trim(UMMModernComposeTo:GetText());
  if (name == "") then
    ui.who:SetText("");
    return;
  end
  local player = UnitName("player");
  if (player and string.lower(name) == string.lower(player)) then
    M.SetText(ui.who, UMM_M_CO_YOU, C.bad);
    return;
  end
  local rgb, kind = M.WhoColor(name);
  local text = (kind == "Character" and UMM_M_CO_WHO_OWN) or (kind == "Friend" and UMM_M_CO_WHO_FRIEND)
    or (kind == "Guildie" and UMM_M_CO_WHO_GUILD) or "";
  M.SetText(ui.who, text, rgb);
end

local function drawRowHints()
  local to = trim(UMMModernComposeTo:GetText());
  local hint = to ~= "" and string.format(UMM_M_GO_SAMEAS, to) or UMM_M_GO_SAME;
  for i = 1, GOLD_ROWS do M.Hint(goldTo[i], hint); end
end

local function drawSlots()
  local n = table.getn(items);
  for k = 1, SLOTS do
    local b = slots[k];
    local item = items[k];
    if (item) then
      b.ummIcon:SetTexture(item.icon or "");
      b.ummCount:SetText((item.count or 1) > 1 and tostring(item.count) or "");
      M.Enable(b, not sending);
      b:Show();
    else
      b:Hide();
    end
  end
  if (n < SLOTS) then
    M.Place(UMMModernComposeAdd, Page.frame, SLOT_X + n * SLOT_GAP, SLOT_Y, SLOT, SLOT);
    M.Enable(UMMModernComposeAdd, not sending);
    UMMModernComposeAdd:Show();
  else
    UMMModernComposeAdd:Hide();
  end
end

local function drawRows()
  for i = 1, GOLD_ROWS do
    if (i <= rowCount) then
      goldRow[i]:Show();
      M.Enable(goldRemove[i], not sending);
    else
      goldRow[i]:Hide();
    end
  end
  if (rowCount < GOLD_ROWS) then
    M.Place(UMMModernGoldAdd, UMMModernGold, 8, ROWS_Y + rowCount * ROW_STEP, 120, 22);
    M.Enable(UMMModernGoldAdd, not sending);
    UMMModernGoldAdd:Show();
  else
    UMMModernGoldAdd:Hide();
  end
  ui.rowHead:SetText(rowCount > 0 and UMM_M_GO_TO or "");
  ui.rowHeadGold:SetText(rowCount > 0 and UMM_M_GO_AMOUNT or "");
end

local function drawGoldHead()
  ui.hand:SetText(M.Gold(M.OnHand()));
  local pool = inboxPool();
  local total, groups, amounts = 0, {}, {};
  for _, mail in ipairs(pool) do
    total = total + mail.money;
    if (not groups[mail.money]) then table.insert(amounts, mail.money); end
    groups[mail.money] = (groups[mail.money] or 0) + 1;
  end
  local n = table.getn(pool);
  ui.inbox:SetText(n > 0 and string.format(UMM_M_GO_INBOXN, M.Gold(total), n) or UMM_M_GO_NONE);
  table.sort(amounts, function(a, b) return a > b; end);
  local parts = {};
  for i = 1, math.min(3, table.getn(amounts)) do
    table.insert(parts, M.Gold(amounts[i]).." ×"..groups[amounts[i]]);
  end
  if (table.getn(amounts) > 3) then table.insert(parts, "..."); end
  ui.breakdown:SetText(table.concat(parts, "   "));
  M.Enable(UMMModernGoldFill, n > 0 and not sending);
end

local function drawPlan(plan, form)
  lastPlan = plan;
  local errors = plan.errors;
  -- the mails to the name in To (with the gold of the box beside C.O.D.), and the extra gold mails
  local toMails, toGold, extraMails, extraGold = 0, 0, 0, 0;
  for _, step in ipairs(plan.steps) do
    if (step.kind == "mail") then
      local src = step.src or {};
      if (src.kind == "gold" and src.row ~= 0) then
        extraMails, extraGold = extraMails + 1, extraGold + (step.money or 0);
      else
        toMails = toMails + 1;
        if (src.kind == "gold") then toGold = toGold + (step.money or 0); end
      end
    end
  end
  local main, note, mainColor = "", "", C.text;
  if (isEmpty(form)) then
    main, mainColor = UMM_M_CO_EMPTY, C.dim;
  elseif (table.getn(errors) > 0) then
    main, mainColor = errors[1], C.bad;
    note = errors[2] or "";
  else
    local pieces = {};
    if (toMails > 0) then
      local text = toMails == 1 and string.format(UMM_M_CO_PLAN_MAIN1, form.to) or string.format(UMM_M_CO_PLAN_MAIN, toMails, form.to);
      local detail = {};
      if (toMails > 1 and plan.itemMails > 0) then table.insert(detail, string.format(UMM_M_CO_PLAN_ITEMS, plan.itemMails)); end
      if (plan.textParts > 1) then table.insert(detail, string.format(UMM_M_CO_PLAN_PARTS, plan.textParts)); end
      if (toGold > 0) then table.insert(detail, string.format(UMM_M_CO_PLAN_GOLDPART, M.Gold(toGold))); end
      if (table.getn(detail) > 0) then text = text.." ("..table.concat(detail, ", ")..")"; end
      table.insert(pieces, text);
    end
    if (extraMails == 1) then
      table.insert(pieces, string.format(UMM_M_CO_PLAN_GOLD1, M.Gold(extraGold)));
    elseif (extraMails > 1) then
      table.insert(pieces, string.format(UMM_M_CO_PLAN_GOLD, extraMails, M.Gold(extraGold)));
    end
    main = table.concat(pieces, "  +  ");
    local notes = {};
    if (plan.takes > 0) then table.insert(notes, string.format(UMM_M_CO_PLAN_TAKES, plan.takes)); end
    if (form.cod > 0 and plan.itemMails > 0) then table.insert(notes, string.format(UMM_M_CO_PLAN_COD, M.Gold(form.cod))); end
    note = table.concat(notes, "  ");
  end
  M.SetText(ui.plan, main, mainColor);
  M.SetText(ui.note, note, table.getn(errors) > 0 and C.warn or C.dim);

  -- the extra gold mails' total (gold the box beside C.O.D. lacks is the plan line's to say)
  local short = nil;
  for row, missing in pairs(plan.shortRows or {}) do
    if (row ~= 0 and (not short or row < short)) then short = row; end
  end
  if (short) then
    M.SetText(ui.total, string.format(UMM_M_GO_SHORT, short, M.Gold(plan.shortRows[short])), C.bad);
  elseif (extraMails == 1) then
    M.SetText(ui.total, string.format(UMM_M_GO_TOTAL1, M.Gold(extraGold)), C.gold);
  elseif (extraMails > 1) then
    M.SetText(ui.total, string.format(UMM_M_GO_TOTAL, M.Gold(extraGold), extraMails), C.gold);
  else
    ui.total:SetText("");
  end

  local ok = table.getn(errors) == 0 and plan.mails > 0;
  M.ButtonText(UMMModernComposeSend, plan.mails > 1 and string.format(UMM_M_CO_SENDN, plan.mails) or UMM_M_CO_SEND);
  M.Enable(UMMModernComposeSend, ok and not sending and not M.Busy());
  M.Enable(UMMModernComposeReset, not sending);
  for i = 1, 2 do M.Enable(presets[i], not sending); end
end

-- The first item or gold amount put in names the mail while the subject is empty or still the one
-- filled in here; a subject you type stays.
local function subjectFromForm()
  local item = items[1];
  local gold = (not codOn) and M.GoldOf(UMMModernComposeMoney) or nil;
  for i = 1, rowCount do
    if (gold) then break; end
    gold = M.GoldOf(goldAmount[i]);
  end
  if (not item and not gold) then
    firstKind = nil;
    return "";
  end
  if (firstKind == "item" and not item) or (firstKind == "gold" and not gold) or not firstKind then
    firstKind = item and "item" or "gold";
  end
  if (firstKind == "item") then return P.ItemSubject(item); end
  return (UMM_COMPOSER_AUTOSUBJECT or "Money: ")..M.Gold(gold);
end

local function fillSubject()
  local box = UMMModernComposeSubject;
  local current = box:GetText() or "";
  if (current ~= "" and current ~= autoSubject) or (current == "" and subjectEmptied) then
    autoSubject = nil;
    return;
  end
  local text = string.sub(subjectFromForm(), 1, P.SUBJECT_LIMIT);
  if (text ~= current) then M.SetEditText(box, text); end
  autoSubject = (text ~= "") and text or nil;
end

local function updatePlan()
  if (not Page.frame:IsVisible()) then return; end
  fillSubject();
  local form = readForm();
  drawPlan(compute(form), form);
end

local function changed()
  M.Later(updatePlan);
end

local function toChanged()
  drawWho();
  drawRowHints();
  changed();
end

-- ### Items ###

local function itemOf(slot)
  local entry = UMMBagManager:GetItem(slot);
  if (not entry or entry.Empty) then return nil; end
  return entry;
end

local function itemStatus(text, rgb)
  itemNote = text;
  M.Status(text, rgb);
end

-- The item on the cursor goes in slot k (k past the last one adds a mail).
local function addFromCursor(k)
  if (sending or not UMMCursorHasItem()) then return; end
  local slot = tonumber(GetCursorItemInfo and GetCursorItemInfo());
  if (not slot) then return; end
  if (slot == 0) then
    itemStatus(UMM_M_CO_BAGERR, C.bad);
    return;
  end
  local entry = itemOf(slot);
  if (not entry) then return; end
  PickupBagItem(slot);   -- the item goes back into its bag slot; the mail only remembers the slot
  for _, item in ipairs(items) do
    if (item.index == slot) then
      itemStatus(string.format(UMM_M_CO_TWICE, entry.Name or "?"), C.warn);
      return;
    end
  end
  if (UMMBagManager:IsBound(entry)) then
    itemStatus(string.format(UMM_M_CO_BOUND, entry.Name or "?"), C.bad);
    return;
  end
  local item = { index = slot, link = entry.Link, name = entry.Name, count = entry.Count or 1, icon = entry.Icon };
  if (items[k]) then
    items[k] = item;
  elseif (table.getn(items) >= SLOTS) then
    itemStatus(UMM_M_CO_FULL, C.warn);
    return;
  else
    table.insert(items, item);
  end
  -- an item went in: a line about one that could not is old news
  if (itemNote and M.status:GetText() == itemNote) then M.Status(""); end
  itemNote = nil;
  drawSlots();
  changed();
end

local function removeItem(k)
  if (sending or not items[k]) then return; end
  table.remove(items, k);
  M.HideTip();
  drawSlots();
  changed();
end

-- The game drops a carried item with a drag (OnReceiveDrag) or with a click (mouse up, maybe then
-- a click). Whichever comes first adds it, and puts it back in its bag slot, so it is added once.
local function dropTarget(b)
  b.ummDrop = function(btn) addFromCursor(btn.ummSlot or (table.getn(items) + 1)); end;
  b.ummDown = function(btn) btn.ummCarry = UMMCursorHasItem(); end;
  b.ummUp = function(btn, key)
    if ((key == nil or key == "LBUTTON" or key == "LeftButton") and UMMCursorHasItem()) then
      addFromCursor(btn.ummSlot or (table.getn(items) + 1));
    end
  end;
end

-- Items that left their bag slot are taken out of the mail (and counts follow stack changes).
local function checkItems()
  if (sending or M.Busy() or table.getn(items) == 0) then return; end
  local gone = false;
  for k = table.getn(items), 1, -1 do
    local item = items[k];
    local link = GetBagItemLink(item.index);
    if ((not link or not UMMSameItem(link, nil, item.link, item.name)) and UMMIsTransmutorSlot(item.index)) then
      -- taken back out of the arcane transmutor: the mail follows it to its bag slot
      local used = {};
      for _, other in ipairs(items) do used[other.index] = true; end
      local entry = UMMBagManager:FindInBag(item.link, item.name, used);
      if (entry) then
        item.index = entry.Index;
        link = entry.Link;
      end
    end
    if (not link or not UMMSameItem(link, nil, item.link, item.name)) then
      table.remove(items, k);
      itemStatus(string.format(UMM_M_CO_GONE, item.name or "?"), C.warn);
      gone = true;
    else
      local entry = UMMBagManager.BySlot[item.index];
      if (entry and not entry.Empty and entry.Count) then item.count = entry.Count; end
    end
  end
  if (gone or Page.frame:IsVisible()) then
    drawSlots();
    changed();
  end
end

-- ### The gold box beside C.O.D. ###

-- C.O.D. ticked or not. The amount in the box meant the other thing, so it goes.
local function setCOD(on)
  codOn = on and true or false;
  M.ButtonIcon(UMMModernComposeCOD, codOn and "CheckboxOn" or "CheckboxOff");
  M.Hint(UMMModernComposeMoney, codOn and UMM_M_CO_COD_HINT or UMM_M_CO_GOLD_HINT);
  M.SetEditText(UMMModernComposeMoney, "");
end

-- A preset button: its gold in the box, as gold to send (never as a C.O.D. price).
local function usePreset(i)
  if (sending) then return; end
  local amount = UMMSettings:GoldPreset(i);
  if (not amount) then return; end
  if (codOn) then setCOD(false); end
  M.SetGold(UMMModernComposeMoney, amount);
  changed();
end

-- Use last and the two presets follow the "Mail shortcuts" setting, like the classic window.
local function drawShortcuts()
  local on = UMMSettings:ShortcutsEnabled();
  for i = 1, 2 do
    local b = presets[i];
    if (on) then
      M.ButtonText(b, M.Gold(UMMSettings:GoldPreset(i)), C.gold);
      b:Show();
    else
      b:Hide();
    end
  end
  if (on) then UMMModernComposeLast:Show(); else UMMModernComposeLast:Hide(); end
end

-- ### Gold rows ###

local function setRow(i, to, amountText)
  M.SetEditText(goldTo[i], to or "");
  M.SetEditText(goldAmount[i], amountText or "");
end

local function addRow()
  if (sending or rowCount >= GOLD_ROWS) then return; end
  rowCount = rowCount + 1;
  setRow(rowCount, "", "");
  drawRows();
  drawRowHints();
  goldTo[rowCount]:SetFocus();
  changed();
end

local function removeRow(i)
  if (sending or i > rowCount) then return; end
  for j = i, rowCount - 1 do
    setRow(j, goldTo[j + 1]:GetText(), goldAmount[j + 1]:GetText());
  end
  setRow(rowCount, "", "");
  rowCount = rowCount - 1;
  drawRows();
  drawRowHints();
  changed();
end

local function clearRows()
  for i = 1, GOLD_ROWS do setRow(i, "", ""); end
  rowCount = 0;
  drawRows();
  drawRowHints();
  changed();
end

-- Rows whose gold all went out are dropped (after a run that stopped part way).
local function compactRows()
  local keep = {};
  for i = 1, rowCount do
    if (M.GoldOf(goldAmount[i])) then table.insert(keep, { goldTo[i]:GetText(), goldAmount[i]:GetText() }); end
  end
  for i = 1, GOLD_ROWS do
    local row = keep[i];
    setRow(i, row and row[1] or "", row and row[2] or "");
  end
  rowCount = table.getn(keep);
end

-- One row per inbox gold mail, biggest first, each with that mail's gold; names already typed stay.
local function fillFromInbox()
  if (sending) then return; end
  local pool = inboxPool();
  table.sort(pool, function(a, b) return a.money > b.money; end);
  local n = math.min(table.getn(pool), GOLD_ROWS);
  for i = 1, n do
    local to = i <= rowCount and goldTo[i]:GetText() or "";
    setRow(i, to, M.Gold(pool[i].money));
  end
  for i = n + 1, GOLD_ROWS do setRow(i, "", ""); end
  rowCount = n;
  drawRows();
  drawRowHints();
  if (table.getn(pool) > GOLD_ROWS) then
    M.Status(string.format(UMM_M_GO_MORE, table.getn(pool) - GOLD_ROWS), C.warn);
  end
  changed();
end

-- ### Review and sending ###

local function stepText(step, plan)
  if (step.kind == "take") then
    return string.format(UMM_M_RV_TAKE, M.Gold(step.money), step.sender or "?"), C.dim;
  end
  local src = step.src or {};
  if (src.kind == "gold") then
    local text = string.format(UMM_M_RV_GOLD, M.Gold(step.money), step.to);
    if (src.text) then text = text..UMM_M_RV_NOTE; end
    return text, C.gold;
  end
  if (src.kind == "item") then
    local text = string.format(UMM_M_RV_ITEM, P.ItemSubject(step.item), step.to);
    if ((step.cod or 0) > 0) then text = text..string.format(UMM_M_RV_CODN, M.Gold(step.cod)); end
    if (src.text and plan.textParts > 1) then
      text = text..string.format(UMM_M_RV_PART, src.n, plan.textParts);
    elseif (src.text and (step.body or "") ~= "") then
      text = text..UMM_M_RV_NOTE;
    end
    return text, C.text;
  end
  if (plan.textParts > 1) then
    return string.format(UMM_M_RV_TEXT, src.n or 1, plan.textParts, step.to), C.text;
  end
  return string.format(UMM_M_RV_MAIL, step.subject or "", step.to), C.text;
end

local function drawReview()
  local plan = reviewPlan;
  if (not plan) then return; end
  local total = table.getn(plan.steps);
  reviewOffset = math.max(0, math.min(reviewOffset, total - REVIEW_LINES));
  for i = 1, REVIEW_LINES do
    local step = plan.steps[reviewOffset + i];
    local line = ui.reviewLines[i];
    if (step) then
      local text, rgb = stepText(step, plan);
      M.SetText(line, (reviewOffset + i)..".  "..text, rgb);
    else
      line:SetText("");
    end
  end
  if (plan.takes > 0) then
    ui.reviewSummary:SetText(string.format(UMM_M_RV_SUMMARY_TAKES, plan.mails, plan.takes));
  else
    ui.reviewSummary:SetText(string.format(UMM_M_RV_SUMMARY, plan.mails));
  end
  M.ButtonText(UMMModernReviewGo, plan.mails > 1 and string.format(UMM_M_CO_SENDN, plan.mails) or UMM_M_CO_SEND);
end

local function closeReview()
  reviewPlan = nil;
  UMMModernReview:Hide();
end

local function openReview(plan)
  if (M.focus) then M.focus:ClearFocus(); end
  K.Close();
  reviewPlan, reviewOffset = plan, 0;
  UMMModernReview:Show();
  drawReview();
end

local function startSend(plan, form)
  if (M.Busy()) then
    UMMPrompt(UMM_ERROR_STILLSENDING);
    return;
  end
  sending = { parts = P.SplitBody(form.body), sentParts = {} };
  if (not UMMQueue:Run(plan.steps, { owner = Page })) then
    sending = nil;
    UMMPrompt(UMM_ERROR_STILLSENDING);
    return;
  end
  closeReview();
  drawSlots();
  drawRows();
  drawGoldHead();
  drawPlan(plan, form);
end

local function refreshCounts()
  for _, item in ipairs(items) do
    local entry = itemOf(item.index);
    if (entry and UMMSameItem(entry.Link, entry.Name, item.link, item.name)) then item.count = entry.Count or item.count; end
  end
end

local function send()
  if (sending or M.Busy()) then
    UMMPrompt(UMM_ERROR_STILLSENDING);
    return;
  end
  K.Close();
  refreshCounts();
  local form = readForm();
  local plan = compute(form);
  drawPlan(plan, form);
  if (table.getn(plan.errors) > 0 or plan.mails == 0) then
    M.Status(plan.errors[1] or UMM_M_CO_EMPTY, C.bad);
    return;
  end
  if (plan.mails > 1 or plan.goldMails > 0 or plan.takes > 0) then
    openReview(plan);
  else
    startSend(plan, form);
  end
end

local function reviewGo()
  -- worked out again: gold on hand or in the inbox may have changed while the list was open
  local form = readForm();
  local plan = compute(form);
  if (table.getn(plan.errors) > 0 or plan.mails == 0) then
    closeReview();
    drawPlan(plan, form);
    M.Status(plan.errors[1] or UMM_M_CO_EMPTY, C.bad);
    return;
  end
  startSend(plan, form);
end

local function clearForm(keepTo)
  if (not keepTo) then M.SetEditText(UMMModernComposeTo, ""); end
  M.SetEditText(UMMModernComposeSubject, "");
  autoSubject, firstKind, subjectEmptied = nil, nil, false;
  M.SetEditText(UMMModernComposeBody, "");
  items = {};
  setCOD(false);
  for i = 1, GOLD_ROWS do setRow(i, "", ""); end
  rowCount = 0;
  drawSlots();
  drawRows();
  drawCounter();
  drawWho();
  drawRowHints();
  changed();
end

local function reset()
  if (sending) then return; end
  local form = readForm();
  clearForm(not isEmpty(form) or codOn);
end

-- Queue: one step ended. What went out leaves the form at once.
function Page.QueueStep(step, status)
  if (not sending or status ~= "ok" or step.kind ~= "mail") then return; end
  local src = step.src or {};
  if (src.kind == "item") then
    for k, item in ipairs(items) do
      if (item == step.item) then table.remove(items, k); break; end
    end
    if (src.text) then sending.sentParts[src.n] = true; end
    drawSlots();
  elseif (src.kind == "text") then
    sending.sentParts[src.n] = true;
  elseif (src.kind == "gold") then
    local box = (src.row == 0) and UMMModernComposeMoney or goldAmount[src.row];
    if (box) then
      local left = (M.GoldOf(box) or 0) - (step.money or 0);
      M.SetGold(box, left > 0 and left or nil);
    end
    if (src.text) then sending.sentParts[1] = true; end
  end
end

-- Queue: the run ended. All sent: the form empties, To stays. Stopped: what is left stays.
function Page.QueueDone(steps, done)
  local run = sending;
  sending = nil;
  if (not run) then return; end
  if (done) then
    clearForm(true);
  else
    if (next(run.sentParts)) then
      local left = {};
      for k, part in ipairs(run.parts) do
        if (not run.sentParts[k]) then table.insert(left, part); end
      end
      M.SetEditText(UMMModernComposeBody, table.concat(left, "\n"));
    end
    compactRows();
    drawSlots();
    drawRows();
    drawRowHints();
    drawCounter();
  end
  drawGoldHead();
  changed();
end

-- ### Names ###

local function nameBox(e, onDone)
  e.ummFocus = function(box)
    -- a name already in the box is selected on the way in: typing replaces it, Ctrl+C takes it
    if ((box:GetText() or "") ~= "") then M.SelectAll(box); end
    if (UMMAutoNameList()) then K.Open(box, function(b) changed(); onDone(b); end); end
  end;
  e.ummEnterKey = function(box)
    local first = K.IsOpenFor(box) and K.First();
    if (first) then
      K.Use(first);
    else
      K.Close();
      onDone(box);
    end
  end;
  e.ummEsc = function() K.Close(); end;
end

function Page.Reply(to, subject)
  M.SetEditText(UMMModernComposeTo, to or "");
  M.SetEditText(UMMModernComposeSubject, subject or "");
  toChanged();
  UMMModernComposeBody:SetFocus();
end

-- A name clicked in chat: into the gold row being typed in, else To.
function Page.UseName(name)
  local box = M.focus;
  if (box and box.ummGoldTo and box:IsVisible()) then
    box:SetText(name);
  else
    UMMModernComposeTo:SetText(name);
  end
  K.Close();
  toChanged();
  return true;
end

-- ### Building ###

local function buildMail()
  local f = Page.frame;
  ui.toLabel = M.Label(f, 12, C.dim, "LEFT");
  M.Place(ui.toLabel, f, 8, 6, 30, 22);
  ui.toLabel:SetText(UMM_M_CO_TO);
  M.Edit(UMMModernComposeTo, f, 40, 6, 194, 22, { hint = UMM_M_CO_TO_HINT, name = true, text = function(box)
    if (K.IsOpenFor(box)) then K.Filter(); end
    toChanged();
  end, nextBox = UMMModernComposeSubject });
  -- a name chosen (from the list, Enter or Use last): next comes the gold, so the cursor goes there;
  -- Tab still goes on to Subject
  nameBox(UMMModernComposeTo, function() UMMModernComposeMoney:SetFocus(); end);
  M.Button(UMMModernComposePick, f, 238, 6, 24, 22, { icon = "Characters", iconSize = 16, style = "quiet",
    tip = { UMM_M_CO_PICK_TIP }, click = function()
      K.Toggle(UMMModernComposeTo, function() changed(); UMMModernComposeMoney:SetFocus(); end);
    end });
  M.Button(UMMModernComposeLast, f, 266, 6, 74, 22, { text = UMM_M_CO_LAST, size = 12, style = "quiet",
    tip = { UMM_M_CO_LAST, UMM_M_CO_LAST_TIP }, click = function()
      local last = UMMSettings:LastRecipient();
      if (last) then
        K.Close();
        UMMModernComposeTo:SetText(last);
        toChanged();
        UMMModernComposeMoney:SetFocus();
      end
    end });
  ui.who = M.Label(f, 11, C.dim, "LEFT");
  M.Place(ui.who, f, 346, 6, 124, 22);

  ui.subjectLabel = M.Label(f, 12, C.dim, "LEFT");
  M.Place(ui.subjectLabel, f, 8, 34, 50, 22);
  ui.subjectLabel:SetText(UMM_M_CO_SUBJECT);
  M.Edit(UMMModernComposeSubject, f, 62, 34, 408, 22, { hint = UMM_M_CO_SUBJECT_HINT, nextBox = UMMModernComposeBody,
    text = function(box)
      subjectEmptied = (box:GetText() or "") == "";
      changed();
    end });
  UMMModernComposeSubject.ummEnterKey = function() UMMModernComposeBody:SetFocus(); end;
  -- the subject filled in from an item or gold is selected on the way in, so typing replaces it
  UMMModernComposeSubject.ummFocus = function(box)
    if (autoSubject and (box:GetText() or "") == autoSubject) then M.SelectAll(box); end
  end;
  UMMModernComposeSubject.ummUnfocus = function(box)
    if (subjectEmptied) then subjectEmptied = false; changed(); end
  end;

  M.Edit(UMMModernComposeBody, f, 8, 62, 462, 150, { hint = UMM_M_CO_BODY_HINT, panel = true, text = function()
    drawCounter();
    changed();
  end });
  M.Place(UMMModernComposeBody.ummHint, UMMModernComposeBody, 8, 6, 446, 18);
  ui.counter = M.Label(f, 11, C.dim, "RIGHT");
  M.Place(ui.counter, f, 8, 214, 462, 16);

  ui.itemsLabel = M.Label(f, 12, C.dim, "LEFT");
  M.Place(ui.itemsLabel, f, 8, SLOT_Y, SLOT_X - 10, SLOT);
  ui.itemsLabel:SetText(UMM_M_CO_ITEMS);
  for k = 1, SLOTS do
    local b = getglobal("UMMModernComposeSlot"..k);
    slots[k] = b;
    M.Button(b, f, SLOT_X + (k - 1) * SLOT_GAP, SLOT_Y, SLOT, SLOT, { style = "choice", click = function(btn)
      if (UMMCursorHasItem()) then
        addFromCursor(btn.ummSlot);
      elseif (not btn.ummCarry) then
        removeItem(btn.ummSlot);   -- a plain click; not the click that just dropped an item here
      end
      btn.ummCarry = false;
    end });
    b.ummSlot = k;
    dropTarget(b);
    b.ummIcon = M.Icon(b, "ARTWORK", SLOT - 6);
    M.Place(b.ummIcon, b, 3, 3, SLOT - 6, SLOT - 6);
    b.ummCount = M.Label(b, 11, C.text, "RIGHT");
    M.Place(b.ummCount, b, 2, SLOT - 16, SLOT - 5, 14);
    b.ummEnter = function(btn)
      local item = items[btn.ummSlot];
      if (not item or not GameTooltip) then return; end
      GameTooltip:SetOwner(btn, "ANCHOR_RIGHT", 0, 0);
      if (item.link and GameTooltip.SetHyperLink) then
        GameTooltip:SetHyperLink(item.link);
      else
        GameTooltip:SetText(item.name or "?");
      end
      GameTooltip:AddLine(UMM_M_CO_SLOT_TIP, 0.7, 0.8, 1);
      GameTooltip:Show();
      M.tipOwner = btn;
    end;
    b:Hide();
  end
  M.Button(UMMModernComposeAdd, f, SLOT_X, SLOT_Y, SLOT, SLOT, { icon = "Plus", iconSize = 18, style = "quiet",
    tip = { UMM_M_CO_ADD, UMM_M_CO_ADD_TIP }, click = function(btn)
      addFromCursor(table.getn(items) + 1);
      btn.ummCarry = false;
    end });
  UMMModernComposeAdd.ummSlot = nil;   -- past the last item: a new mail
  dropTarget(UMMModernComposeAdd);

  -- C.O.D. only ever changes by a click on it: typing an amount never ticks it
  M.Button(UMMModernComposeCOD, f, 8, COD_Y, 84, 22, { text = UMM_M_CO_COD, icon = "CheckboxOff", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_CO_COD, UMM_M_CO_COD_TIP }, click = function()
      if (sending) then return; end
      setCOD(not codOn);
      UMMModernComposeMoney:SetFocus();
      changed();
    end });
  M.Edit(UMMModernComposeMoney, f, MONEY_X, COD_Y, MONEY_W, 22, { gold = true, hint = UMM_M_CO_GOLD_HINT, text = changed,
    tip = function()
      if (codOn) then return { UMM_M_CO_COD, UMM_M_CO_COD_TIP }; end
      return { UMM_M_CO_GOLD, UMM_M_CO_GOLD_TIP };
    end });
  -- getting the cursor selects the amount, so typing replaces it
  UMMModernComposeMoney.ummFocus = function(box)
    if ((box:GetText() or "") ~= "") then M.SelectAll(box); end
  end;
  for i = 1, 2 do
    local b = getglobal("UMMModernComposePreset"..i);
    presets[i] = b;
    M.Button(b, f, PRESET_X + (i - 1) * (PRESET_W + PRESET_GAP), COD_Y, PRESET_W, 22, {
      text = M.Gold(UMMSettings:GoldPreset(i)), icon = "Gold", iconSize = 14, size = 12, style = "quiet",
      tip = function()
        return { string.format(UMM_M_CO_PRESET, i), string.format(UMM_M_CO_PRESET_TIP, M.Gold(UMMSettings:GoldPreset(i))) };
      end, click = function() usePreset(i); end });
  end

  ui.plan = M.Label(f, 12, C.text, "LEFT");
  M.Place(ui.plan, f, 8, COD_Y + 28, 462, 18);
  ui.note = M.Label(f, 11, C.dim, "LEFT");
  M.Place(ui.note, f, 8, COD_Y + 46, 462, 16);

  M.Button(UMMModernComposeReset, f, 8, 394, 86, 24, { text = UMM_M_CO_RESET, icon = "Broom", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_CO_RESET, UMM_M_CO_RESET_TIP }, click = reset });
  M.Button(UMMModernComposeSend, f, 310, 394, 160, 24, { text = UMM_M_CO_SEND, icon = "Mail", iconSize = 16, size = 13,
    style = "save", click = send });
end

local function buildGold()
  local g = UMMModernGold;
  local W, H = 270, 412;
  M.Place(g, Page.frame, 482, 6, W, H);
  g:Show();
  M.Panel(g, 0, 0, W, H, C.panel, M.STYLES.quiet.edge, 0.95);
  local coin = M.Texture(g, "ARTWORK", "Gold");
  M.Place(coin, g, 10, 9, 16, 16);
  local title = M.Label(g, 13, C.head, "LEFT");
  M.Place(title, g, 32, 6, 200, 22);
  title:SetText(UMM_M_GO_TITLE);
  local handLabel = M.Label(g, 11, C.dim, "LEFT");
  M.Place(handLabel, g, 10, 30, 120, 16);
  handLabel:SetText(UMM_M_GO_HAND);
  ui.hand = M.Label(g, 12, C.gold, "RIGHT");
  M.Place(ui.hand, g, 120, 30, W - 130, 16);
  local inboxLabel = M.Label(g, 11, C.dim, "LEFT");
  M.Place(inboxLabel, g, 10, 48, 120, 16);
  inboxLabel:SetText(UMM_M_GO_INBOX);
  ui.inbox = M.Label(g, 12, C.gold, "RIGHT");
  M.Place(ui.inbox, g, 100, 48, W - 110, 16);
  ui.breakdown = M.Label(g, 11, C.dim, "RIGHT");
  M.Place(ui.breakdown, g, 10, 66, W - 20, 16);

  M.Button(UMMModernGoldFill, g, 8, 88, 150, 22, { text = UMM_M_GO_FILL, icon = "caps", iconSize = 14, size = 12,
    style = "action", tip = { UMM_M_GO_FILL, UMM_M_GO_FILL_TIP }, click = fillFromInbox });
  M.Button(UMMModernGoldClear, g, 162, 88, 100, 22, { text = UMM_M_GO_CLEAR, icon = "Broom", iconSize = 14, size = 12,
    style = "quiet", click = function() if (not sending) then clearRows(); end end });

  ui.rowHead = M.Label(g, 11, C.dim, "LEFT");
  M.Place(ui.rowHead, g, 12, ROWS_Y - 16, 100, 14);
  ui.rowHeadGold = M.Label(g, 11, C.dim, "LEFT");
  M.Place(ui.rowHeadGold, g, 128, ROWS_Y - 16, 100, 14);
  for i = 1, GOLD_ROWS do
    local row = getglobal("UMMModernGoldRow"..i);
    goldRow[i] = row;
    M.Place(row, g, 0, ROWS_Y + (i - 1) * ROW_STEP, W, 24);
    local to = getglobal("UMMModernGoldRow"..i.."To");
    local amount = getglobal("UMMModernGoldRow"..i.."Amount");
    local remove = getglobal("UMMModernGoldRow"..i.."Remove");
    goldTo[i], goldAmount[i], goldRemove[i] = to, amount, remove;
    M.Edit(to, row, 10, 1, 108, 22, { hint = UMM_M_GO_SAME, name = true, text = function(box)
      if (K.IsOpenFor(box)) then K.Filter(); end
      changed();
    end, nextBox = amount });
    to.ummGoldTo = true;
    nameBox(to, function() amount:SetFocus(); end);
    M.Edit(amount, row, 124, 1, 116, 22, { gold = true, text = changed, nextBox = function()
      return goldTo[i + 1] and i + 1 <= rowCount and goldTo[i + 1] or nil;
    end });
    M.Button(remove, row, 244, 1, 20, 22, { icon = "Minus", iconSize = 12, style = "danger",
      tip = { UMM_M_GO_REMOVE }, click = function() removeRow(i); end });
    row:Hide();
  end
  M.Button(UMMModernGoldAdd, g, 8, ROWS_Y, 120, 22, { text = UMM_M_GO_ADD, icon = "Plus", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_GO_ADD, UMM_M_GO_ADD_TIP }, click = addRow });
  ui.total = M.Label(g, 12, C.gold, "LEFT");
  M.Place(ui.total, g, 10, H - 28, W - 20, 20);
end

local function buildReview()
  local r = UMMModernReview;
  local W, H = M.W, M.BOTTOM - M.TOP;
  M.Hit(r, Page.frame, 0, 0, W, H);
  M.Panel(r, 0, 0, W, H, C.bg, false, 0.8);
  local x, y, w, h = 110, 14, 540, 396;
  M.Panel(r, x, y, w, h, C.bar, M.STYLES.choice.edge, 0.98);
  local title = M.Label(r, 14, C.head, "LEFT");
  M.Place(title, r, x + 12, y + 8, w - 24, 22);
  title:SetText(UMM_M_RV_TITLE);
  ui.reviewSummary = M.Label(r, 11, C.dim, "LEFT");
  M.Place(ui.reviewSummary, r, x + 12, y + 30, w - 24, 16);
  local list = UMMModernReviewList;
  M.Hit(list, r, x + 10, y + 52, w - 20, REVIEW_LINES * 20);
  local function wheel(_, delta)
    reviewOffset = reviewOffset - (delta > 0 and 3 or -3);
    drawReview();
  end
  list.ummWheel = wheel;
  r.ummWheel = wheel;
  ui.reviewLines = {};
  for i = 1, REVIEW_LINES do
    local line = M.Label(list, 12, C.text, "LEFT");
    M.Place(line, list, 4, (i - 1) * 20, w - 28, 20);
    ui.reviewLines[i] = line;
  end
  M.Button(UMMModernReviewBack, r, x + 12, y + h - 34, 100, 24, { text = UMM_M_RV_BACK, size = 12, style = "quiet",
    click = closeReview });
  M.Button(UMMModernReviewGo, r, x + w - 172, y + h - 34, 160, 24, { text = UMM_M_CO_SEND, icon = "Mail", iconSize = 16,
    size = 13, style = "save", click = reviewGo });
  r:Hide();
end

function Page.Build()
  buildMail();
  buildGold();
  buildReview();
  drawSlots();
  drawRows();
end

-- ### Page hooks ###

function Page.Show()
  drawShortcuts();
  drawGoldHead();
  drawCounter();
  drawWho();
  drawRowHints();
  checkItems();
  drawSlots();
  drawRows();
  updatePlan();
  if (trim(UMMModernComposeTo:GetText()) == "" and not sending) then UMMModernComposeTo:SetFocus(); end
end

function Page.Hide()
  closeReview();
end

function Page.MoneyChanged()
  if (Page.frame:IsVisible()) then
    drawGoldHead();
    changed();
  end
end

function Page.InboxUpdated()
  if (Page.frame:IsVisible()) then
    drawGoldHead();
    changed();
  end
end

function Page.BagsChanged()
  if (table.getn(items) > 0) then M.Later(checkItems); end
end

function Page.HistoryChanged()
  if (Page.frame:IsVisible()) then drawWho(); end
end

function Page.Tick()
  -- Send's state follows the queue and the inbox automation of other pages
  if (lastPlan and Page.frame:IsVisible()) then
    local ok = table.getn(lastPlan.errors) == 0 and lastPlan.mails > 0 and not sending and not M.Busy();
    M.Enable(UMMModernComposeSend, ok);
  end
end

function Page.Closed()
  closeReview();
  sending = nil;
  -- C.O.D. is off whenever a mailbox opens: a price from last time does not wait in the box
  if (codOn) then setCOD(false); end
end

function Page.ShortcutsChanged()
  drawShortcuts();
end
