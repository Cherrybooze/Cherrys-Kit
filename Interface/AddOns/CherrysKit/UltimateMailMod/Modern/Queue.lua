-- Cherry's Kit: the modern window's send queue. Runs the steps of Modern/Plan.lua (and Mass send's
-- mails) one at a time: each mail goes through UMMMailComposer, which waits for the game to confirm
-- every part of it, with the same pacing, batch pauses and retries as the classic Mass Send
-- (/umm delay, /umm batch, /umm retries). Gold from inbox mails is taken just before the mail that
-- needs it, checked against the 999,999,999 a character can carry, and the step only counts once
-- the gold has arrived.
--
-- Driven by the master frame: Tick every frame, SendCompleted from the composer (it is named as the
-- composer's return frame), MoneyChanged on PLAYER_MONEY.

local M = UMMModern;

M.Default("UMM_M_Q_SENDING", "Sending %d of %d to %s ...");
M.Default("UMM_M_Q_TAKING", "Taking %s gold from %s's mail ...");
M.Default("UMM_M_Q_DONE", "Done: %d of %d mails sent.");
M.Default("UMM_M_Q_STOPPED", "Stopped: %d of %d mails sent. What was not sent is still there.");
M.Default("UMM_M_Q_NOGOLD", "Stopped: this character no longer has the gold for the next mail.");
M.Default("UMM_M_Q_TAKEFAILED", "Stopped: %s gold did not arrive from %s's mail (gold limit, or the mail changed).");
M.Default("UMM_M_Q_NOTFOUND", "Stopped: %s's mail with %s gold is no longer in the inbox.");
M.Default("UMM_M_Q_CAP", "Stopped: taking %s gold would go past the 999,999,999 a character can carry.");
M.Default("UMM_M_Q_SKIPPED", "Skipped %s: %s.");
M.Default("UMM_M_REASON_MOVED", "it is no longer in that bag slot");
M.Default("UMM_M_REASON_SELF", "that is this character");
M.Default("UMM_M_REASON_SUBJECT", "no subject");
M.Default("UMM_M_REASON_BOUND", "the item is bound");

local TAKE_TIMEOUT = 8;   -- seconds for taken gold to arrive
local CAP_WAIT = 3;       -- seconds the gold of the mail before a take gets to leave this character
local REASONS = { [1] = "UMM_M_REASON_SELF", [2] = "UMM_M_REASON_SUBJECT", [3] = "UMM_M_REASON_BOUND" };

UMMQueue = {
  steps = nil, pos = 0, total = 0, mails = 0, sent = 0, failed = 0, skipped = 0, taken = 0,
  tries = 0, wait = 0, capWait = 0, fast = false, running = false, stopAsked = false, taking = nil,
  owner = nil, emptied = nil,
};
local Q = UMMQueue;

function Q:Busy()
  return self.running == true;
end

-- Starts a run. opts: fast (Send fast pacing), owner (a page with QueueStep and QueueDone).
function Q:Run(steps, opts)
  if (self.running or UMMMailComposer:Busy() or UMMMailManager:IsAutomating()) then return false; end
  opts = opts or {};
  self.steps, self.pos, self.total = steps, 1, table.getn(steps);
  self.mails, self.sent, self.failed, self.skipped, self.taken = 0, 0, 0, 0, 0;
  for _, step in ipairs(steps) do
    step.status = nil;
    if (step.kind == "mail") then self.mails = self.mails + 1; end
  end
  self.tries, self.wait, self.capWait, self.stopAsked, self.taking = 0, 0, 0, false, nil;
  self.fast = opts.fast and true or false;
  self.owner = opts.owner;
  self.emptied = {};
  self.running = true;
  UMMTraceAdd("start", self.total.." steps"..(self.fast and " (fast)" or " (safe)"));
  M.RefreshStop();
  if (self.total == 0) then self:Finish(); end
  return true;
end

local function reasonText(reason)
  local key = REASONS[reason] or reason;
  return (type(key) == "string" and _G[key]) or tostring(reason or "");
end

function Q:Show()
  local step = self.steps and self.steps[self.pos];
  if (not step) then return; end
  if (step.kind == "take") then
    M.Status(string.format(UMM_M_Q_TAKING, M.Gold(step.money), step.sender or "?"), M.C.gold);
  else
    M.Status(string.format(UMM_M_Q_SENDING, self.sent + self.failed + self.skipped + 1, self.mails, step.to or "?"), M.C.text);
  end
  M.Progress(self.pos - 1, self.total);
end

-- One step ended: remember it, tell the page and the activity list.
function Q:Record(step, status, reason)
  step.status, step.reason = status, reason;
  if (step.kind == "take") then
    if (status == "ok") then self.taken = self.taken + 1; end
  elseif (status == "ok") then self.sent = self.sent + 1;
  elseif (status == "skipped") then self.skipped = self.skipped + 1;
  else self.failed = self.failed + 1; end
  if (M.Log) then M.Log(step, status, reason); end
  if (self.owner and self.owner.QueueStep) then self.owner.QueueStep(step, status); end
end

function Q:Advance(wait)
  self.pos = self.pos + 1;
  self.tries = 0;
  self.capWait = 0;
  self.wait = wait or 0;
  if (self.pos > self.total) then
    self:Finish();
  else
    self:Show();
  end
end

-- Inbox gold mail of a take step, read fresh from the game: same sender and amount, gold only.
local function findGoldMail(step)
  local count = GetInboxNumItems() or 0;
  local found = nil;
  for i = 1, count do
    local _, sender, subject, cod, mode, money, _, _, items = GetInboxHeaderInfo(i);
    if (sender == step.sender and money == step.money and not cod and (items or 0) == 0
        and string.lower(mode or "copper") == "copper") then
      if (subject == step.subject) then return i; end
      found = found or i;
    end
  end
  return found;
end

function Q:StartTake(step, elapsed)
  local index = findGoldMail(step);
  if (not index) then
    self:Record(step, "failed", "missing");
    self:Finish(string.format(UMM_M_Q_NOTFOUND, step.sender or "?", M.Gold(step.money)));
    return;
  end
  local hand = M.OnHand();
  if (hand + step.money > M.CAP) then
    -- the game can report the gold of the mail sent just before a moment late: give it time
    self.capWait = self.capWait + (elapsed or 0);
    if (self.capWait < CAP_WAIT) then return; end
    self:Record(step, "failed", "cap");
    self:Finish(string.format(UMM_M_Q_CAP, M.Gold(step.money)));
    return;
  end
  self.taking = { index = index, before = hand, money = step.money, time = 0 };
  UMMTraceAdd("take", tostring(step.sender).." "..step.money.." mail "..index);
  self:Show();
  TakeInboxItem(index);
end

-- Has the gold of the take arrived? Gold that left after the take started (a mail sent just before,
-- reported late) is not the take's doing, so the count starts again from what is left.
local function arrived(t)
  local hand = M.OnHand();
  if (hand < t.before) then t.before = hand; end
  return hand >= t.before + t.money;
end

function Q:TakeDone(ok)
  self.taking = nil;
  local step = self.steps[self.pos];
  if (ok) then
    self:Record(step, "ok");
    table.insert(self.emptied, step);
    self:Advance(0.3);
  else
    self:Record(step, "failed", "take");
    self:Finish(string.format(UMM_M_Q_TAKEFAILED, M.Gold(step.money), step.sender or "?"));
  end
end

function Q:MoneyChanged()
  local t = self.taking;
  if (t and arrived(t)) then self:TakeDone(true); end
end

function Q:StartMail(step)
  local item = step.item;
  if (item and not UMMSameItem(GetBagItemLink(item.index), nil, item.link, item.name)) then
    self:Record(step, "skipped", "UMM_M_REASON_MOVED");
    UMMPrompt("|r|cff"..UMMColor.Yellow..string.format(UMM_M_Q_SKIPPED, item.name or "?", UMM_M_REASON_MOVED));
    self:Advance(0);
    return;
  end
  if ((step.money or 0) > 0 and M.OnHand() < step.money) then
    self:Record(step, "failed", "gold");
    self:Finish(UMM_M_Q_NOGOLD);
    return;
  end
  local composer = UMMMailComposer;
  composer:Clear();
  composer:SetComposer("UMMQueue");
  composer:Recipient(step.to);
  composer:Subject(step.subject or "");
  composer:Body(step.body or "");
  if ((step.money or 0) > 0) then composer:AttachedMoney(step.money); end
  if ((step.cod or 0) > 0 and item) then composer:DefinedCODAmount(step.cod); end
  if (item) then composer:AttachedItemIndex(item.index); end
  UMMTraceAdd("mail", self.pos.."/"..self.total.." to "..tostring(step.to)..(item and (" "..tostring(item.name)) or "")
    ..((step.money or 0) > 0 and (" "..step.money.."g") or "").." try "..(self.tries + 1));
  self:Show();
  local result = composer:Send();
  if (result == 4) then
    self.wait = 0.5;   -- the previous mail is still finishing
  elseif (result ~= 0) then
    self:Record(step, "skipped", result);
    UMMPrompt("|r|cff"..UMMColor.Yellow..string.format(UMM_M_Q_SKIPPED, item and item.name or (step.subject or "?"), reasonText(result)));
    self:Advance(0);
  end
end

function Q:Tick(elapsed)
  if (not self.running) then return; end
  local t = self.taking;
  if (t) then
    t.time = t.time + elapsed;
    if (arrived(t)) then
      self:TakeDone(true);
    elseif (t.time > TAKE_TIMEOUT) then
      self:TakeDone(false);
    end
    return;
  end
  if (UMMMailComposer:Busy()) then return; end
  if (self.stopAsked) then self:Finish(); return; end
  if (self.wait > 0) then
    self.wait = self.wait - elapsed;
    return;
  end
  -- late updates from the previous mail die down before the next item is attached
  if (not self.fast and UMMMailComposer:QuietTime() < 0.3) then return; end
  local step = self.steps[self.pos];
  if (not step) then self:Finish(); return; end
  if (step.kind == "take") then self:StartTake(step, elapsed); else self:StartMail(step); end
end

-- The composer finished the current mail (it calls getglobal("UMMQueue"):SendCompleted).
function Q:SendCompleted(status, reason)
  if (not self.running) then return; end
  local step = self.steps[self.pos];
  if (not step or step.kind ~= "mail") then return; end
  if (status == "ok") then
    if (step.item) then
      local item = UMMBagManager.BySlot[step.item.index];
      if (item) then item.Marked = false; end
    end
    self:Record(step, "ok");
    local wait = UMMSendSetting("SendDelay");
    local batch = UMMSendSetting("BatchSize");
    if (self.fast) then
      wait, batch = UMMSendSetting("FastDelay"), 0;
    end
    if (batch > 0 and self.sent % batch == 0 and self.pos < self.total) then
      wait = math.max(wait, UMMSendSetting("BatchPause"));
      self:Advance(wait);
      M.Status(string.format(UMM_MSI_PAUSE, self.sent, self.mails), M.C.warn);
      return;
    end
    self:Advance(wait);
    return;
  end
  self.tries = self.tries + 1;
  if (self.stopAsked) then
    self:Finish();
  elseif (self.fast or self.tries > UMMSendSetting("MaxRetries")) then
    self:Record(step, "failed", reason);
    local what = (step.item and step.item.name) or step.subject or "?";
    self:Finish(string.format(UMM_MSI_GAVEUP, what, self.tries, tostring(reason)));
  else
    -- 2, 4, 8 ... seconds: a busy server gets time to catch up
    local wait = 2 * math.pow(2, self.tries - 1);
    self.wait = wait;
    M.Status(string.format(UMM_MSI_RETRY, self.pos, self.total, tostring(reason), wait), M.C.warn);
  end
end

-- Stop after the mail on its way. reason "mailbox closed": stop now, giving the item back.
function Q:Stop(reason)
  if (not self.running) then return; end
  self.stopAsked = true;
  M.Status(UMM_MSI_STOPPING, M.C.warn);
  if (reason == "mailbox closed") then
    if (UMMMailComposer:Busy()) then UMMMailComposer:Finish("failed", reason); end
    self:Finish();
  elseif (self.taking) then
    return;   -- the gold is on its way; Tick stops once it is here
  elseif (UMMMailComposer:Busy()) then
    UMMMailComposer:Abort();   -- still attaching: given back, and SendCompleted stops the run
  else
    self:Finish();
  end
end

-- Gold mails emptied by this run go, like the inbox's "delete emptied mails" setting says.
local function deleteEmptied(list)
  if (not list or table.getn(list) == 0 or UMMSettings:Get("CheckTakeDeleteEmpty") == false) then return; end
  local deleted = false;
  for _, step in ipairs(list) do
    local count = GetInboxNumItems() or 0;
    for i = count, 1, -1 do
      local _, sender, subject, cod, _, money, _, _, items = GetInboxHeaderInfo(i);
      if (sender == step.sender and subject == step.subject and not cod and (money or 0) == 0 and (items or 0) == 0
          and (not InboxItemCanDelete or InboxItemCanDelete(i))) then
        DeleteInboxItem(i);
        deleted = true;
        break;
      end
    end
  end
  if (deleted) then
    UMMMailManager:InboxRefresh();
    if (M.InboxUpdated) then M.InboxUpdated(); end
  end
end

function Q:Finish(message)
  if (not self.running) then return; end
  self.running = false;
  self.taking = nil;
  local steps, emptied = self.steps, self.emptied;
  self.emptied = nil;
  deleteEmptied(emptied);
  UMMTraceAdd("end", self.sent.." of "..self.mails.." mails, "..self.taken.." taken");
  local done = self.sent == self.mails and not message;
  local text = message or string.format(done and UMM_M_Q_DONE or UMM_M_Q_STOPPED, self.sent, self.mails);
  UMMPrompt((done and "" or "|r|cff"..UMMColor.Yellow)..text);
  UMMBagManager:Invalidate();
  M.Progress(0, 0);
  M.Status(text, done and M.C.good or M.C.warn);
  M.RefreshStop();
  local owner = self.owner;
  self.owner = nil;
  if (owner and owner.QueueDone) then owner.QueueDone(steps, done); end
end
