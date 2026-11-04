-- Cherry's Kit: what a Send in the modern window will do, worked out before anything is sent, so
-- the window can show it first. No frames here: plain tables in, plain tables out.
--
-- A step is { kind = "mail", to, subject, body, item, money, cod, src } or
--            { kind = "take", sender, money, subject } (gold taken from an inbox mail).

local M = UMMModern;
local P = {};
M.Plan = P;

M.Default("UMM_M_ERR_TO", "Enter a name in To.");
M.Default("UMM_M_ERR_SELF", "You can't send mail to yourself (%s).");
M.Default("UMM_M_ERR_SUBJECT", "Enter a subject.");
M.Default("UMM_M_ERR_NOTHING", "Nothing to send yet: write a mail, add an item, or enter gold.");
M.Default("UMM_M_ERR_SHORT", "Not enough gold: %s short, counting this character and the inbox.");

P.CAP = 999999999;      -- the most gold a character can carry, and the most one mail can hold
P.BODY_LIMIT = 2000;    -- the game's mail text holds 2048 bytes; each part stops a little short
P.SUBJECT_LIMIT = 255;

local function isSpace(b) return b == 32 or b == 9; end

-- Splits text into parts of at most limit bytes, at a line break or a space when there is one in
-- the last quarter of a part, never inside a character (UTF-8). "" is one empty part.
function P.SplitBody(text, limit)
  limit = limit or P.BODY_LIMIT;
  text = text or "";
  local parts = {};
  local len = string.len(text);
  if (len <= limit) then
    parts[1] = text;
    return parts;
  end
  local start = 1;
  while (start <= len) do
    local stop = start + limit - 1;
    if (stop >= len) then
      table.insert(parts, string.sub(text, start));
      break;
    end
    local low = start + math.floor(limit * 3 / 4);
    local cut = nil;
    for i = stop, low, -1 do
      if (string.byte(text, i + 1) == 10) then cut = i; break; end
    end
    if (not cut) then
      for i = stop, low, -1 do
        if (isSpace(string.byte(text, i + 1))) then cut = i; break; end
      end
    end
    if (not cut) then
      cut = stop;
      local b = string.byte(text, cut + 1) or 0;
      while (cut > start and b >= 128 and b < 192) do
        cut = cut - 1;
        b = string.byte(text, cut + 1) or 0;
      end
    end
    table.insert(parts, string.sub(text, start, cut));
    start = cut + 1;
    local b = string.byte(text, start);
    if (b == 10 or isSpace(b)) then start = start + 1; end
  end
  return parts;
end

-- subject with " (k/n)" when a mail is one of several, cut to fit the game's subject field.
function P.Numbered(subject, k, n)
  if (n <= 1) then return string.sub(subject, 1, P.SUBJECT_LIMIT); end
  local suffix = " ("..k.."/"..n..")";
  return string.sub(subject, 1, P.SUBJECT_LIMIT - string.len(suffix))..suffix;
end

function P.ItemSubject(item)
  local name = item.name or "?";
  if ((item.count or 1) > 1) then return name.." ("..item.count..")"; end
  return name;
end

-- Gold for rows of { to, amount, row } from gold on hand and inbox gold mails (pool: { sender,
-- money, subject }). A character carries at most cap, so an inbox mail can be taken only while
-- hand + mail <= cap: gold on hand is sent first when it is in the way. Prefers the smallest mail
-- that covers what a row still needs, else the biggest that fits.
-- Returns steps and short (row -> gold missing).
function P.Gold(rows, hand, pool, cap)
  cap = cap or P.CAP;
  hand = hand or 0;
  pool = pool or {};
  local steps, short, need, used = {}, {}, {}, {};
  for i, row in ipairs(rows) do need[i] = row.amount or 0; end

  local function take(j)
    used[j] = true;
    hand = hand + pool[j].money;
    table.insert(steps, { kind = "take", sender = pool[j].sender, money = pool[j].money, subject = pool[j].subject });
  end
  local function send(i, amount)
    need[i] = need[i] - amount;
    hand = hand - amount;
    table.insert(steps, { kind = "mail", to = rows[i].to, money = amount, src = { kind = "gold", row = rows[i].row or i } });
  end
  local function pick(target)
    local fit, best;
    for j, mail in ipairs(pool) do
      if (not used[j] and hand + mail.money <= cap) then
        if (hand + mail.money >= target) then
          if (not fit or mail.money < pool[fit].money) then fit = j; end
        elseif (not best or mail.money > pool[best].money) then
          best = j;
        end
      end
    end
    return fit or best;
  end

  for i = 1, table.getn(rows) do
    while (need[i] > 0) do
      if (hand >= need[i]) then
        send(i, need[i]);
      else
        local j = pick(need[i]);
        if (j) then
          take(j);
        elseif (hand > 0) then
          -- what is on hand blocks every inbox mail: send it toward the last row still in need
          local last = i;
          for k = table.getn(rows), i, -1 do
            if (need[k] > 0) then last = k; break; end
          end
          send(last, math.min(hand, need[last]));
        else
          short[rows[i].row or i] = need[i];
          break;
        end
      end
    end
  end
  return steps, short, hand;
end

-- The whole Send of the compose page. form: { to, subject, autoSubject, body, items, cod, gold }
-- (autoSubject: the subject the page filled in from the first item or gold; only mails with text
-- and nothing else take it, item and gold mails keep their own); items are
-- { index, link, name, count, icon }; gold rows { to, amount, row } (to "" = form.to).
-- ctx: { hand, pool, player }. Returns { steps, errors, mails, takes, goldMails, goldTotal,
-- itemMails, textParts, short, recipients }.
function P.Compose(form, ctx)
  ctx = ctx or {};
  local plan = { steps = {}, errors = {}, mails = 0, takes = 0, goldMails = 0, goldTotal = 0,
                 itemMails = 0, textParts = 0, short = 0, recipients = {}, shortRows = {} };
  local to = form.to or "";
  local subject = form.subject or "";
  local autoSubject = form.autoSubject or "";
  local body = form.body or "";
  local items = form.items or {};
  local hasText = subject ~= "" or body ~= "";
  local parts = P.SplitBody(body);
  local main = math.max(table.getn(items), hasText and table.getn(parts) or 0);

  local rows = {};
  for _, row in ipairs(form.gold or {}) do
    if ((row.amount or 0) > 0) then
      table.insert(rows, { to = (row.to ~= nil and row.to ~= "") and row.to or to, amount = row.amount, row = row.row });
    end
  end
  local goldSteps, short = P.Gold(rows, ctx.hand or 0, ctx.pool, P.CAP);
  plan.shortRows = short;
  for _, missing in pairs(short) do plan.short = plan.short + missing; end

  -- a short note with gold and nothing else rides in the first gold mail to the same name
  local note = nil;
  if (table.getn(items) == 0 and hasText and table.getn(parts) == 1) then
    for _, step in ipairs(goldSteps) do
      if (step.kind == "mail" and step.to == to) then note = step; break; end
    end
    if (note) then main = 0; end
  end

  local errors = plan.errors;
  if (main == 0 and table.getn(rows) == 0) then
    table.insert(errors, UMM_M_ERR_NOTHING);
    return plan;
  end
  if ((main > 0 or note) and to == "") then table.insert(errors, UMM_M_ERR_TO); end
  if (subject == "" and autoSubject == "" and main > table.getn(items)) then table.insert(errors, UMM_M_ERR_SUBJECT); end
  if (plan.short > 0) then table.insert(errors, string.format(UMM_M_ERR_SHORT, M.Gold(plan.short))); end

  for k = 1, main do
    local item = items[k];
    local mail = { kind = "mail", to = to, money = 0, cod = 0, body = (hasText and parts[k]) or "" };
    if (subject ~= "") then
      mail.subject = P.Numbered(subject, k, main);
    elseif (item) then
      mail.subject = P.ItemSubject(item);
    elseif (autoSubject ~= "") then
      mail.subject = P.Numbered(autoSubject, k, main);
    else
      mail.subject = "";
    end
    if (item) then
      mail.item = item;
      mail.cod = form.cod or 0;
      mail.src = { kind = "item", n = k, text = hasText and parts[k] ~= nil };
      plan.itemMails = plan.itemMails + 1;
    else
      mail.src = { kind = "text", n = k };
    end
    if (hasText and parts[k]) then plan.textParts = plan.textParts + 1; end
    table.insert(plan.steps, mail);
  end
  for _, step in ipairs(goldSteps) do
    if (step.kind == "mail") then
      step.subject = (UMM_COMPOSER_AUTOSUBJECT or "Money: ")..M.Gold(step.money);
      step.body = "";
      step.cod = 0;
      if (step == note) then
        if (subject ~= "") then step.subject = string.sub(subject, 1, P.SUBJECT_LIMIT); end
        step.body = body;
        step.src.text = true;
        plan.textParts = 1;
      end
      plan.goldMails = plan.goldMails + 1;
      plan.goldTotal = plan.goldTotal + step.money;
    else
      plan.takes = plan.takes + 1;
    end
    table.insert(plan.steps, step);
  end

  local player = ctx.player;
  local warned = {};
  for _, step in ipairs(plan.steps) do
    if (step.kind == "mail") then
      plan.mails = plan.mails + 1;
      if (step.to == "") then
        if (not warned[""]) then
          warned[""] = true;
          if (to ~= "" or not (main > 0 or note)) then table.insert(errors, UMM_M_ERR_TO); end
        end
      else
        plan.recipients[step.to] = (plan.recipients[step.to] or 0) + 1;
        if (player and string.lower(step.to) == string.lower(player) and not warned[step.to]) then
          warned[step.to] = true;
          table.insert(errors, string.format(UMM_M_ERR_SELF, step.to));
        end
      end
    end
  end
  return plan;
end

-- The inbox's gold mails that a Send can take from: gold only (no items, not C.O.D., not
-- diamonds), as { sender, money, subject, index }.
function P.Pool(mails, count)
  local pool = {};
  for i = 1, count or 0 do
    local mail = mails[i];
    if (mail and mail.CODAmount == 0 and mail.AttachedItems == 0 and mail.AttachedMoney > 0
        and string.lower(mail.MoneyMode or "copper") == "copper") then
      table.insert(pool, { sender = mail.Author, money = mail.AttachedMoney, subject = mail.Subject, index = i });
    end
  end
  return pool;
end
