-- Cherry's Kit: the Activity page of the modern window. Every mail the window sent this session (and
-- every gold take from the inbox), newest first, with totals, and the last 20 names mailed (shared
-- across characters) to start a mail with one click. Kept in memory only: nothing is saved.

local M = UMMModern;
local C = M.C;
local P = M.Plan;
local A = { frame = UMMModernActivity };
M.pages.activity = A;

M.Default("UMM_M_AC_TOTALS", "This session: %d sent");
M.Default("UMM_M_AC_FAILED", "%d failed");
M.Default("UMM_M_AC_SKIPPED", "%d skipped");
M.Default("UMM_M_AC_GOLD", "%s gold sent");
M.Default("UMM_M_AC_TAKES", "%d gold mails taken");
M.Default("UMM_M_AC_LOG", "What went out (newest first)");
M.Default("UMM_M_AC_EMPTY", "Nothing sent from this window yet.");
M.Default("UMM_M_AC_CLEAR", "Clear");
M.Default("UMM_M_AC_CLEAR_TIP", "Empties this list and the totals. Your recent names stay.");
M.Default("UMM_M_AC_NAMES", "Recent names");
M.Default("UMM_M_AC_NAMES_HELP", "Click a name to write to them. The number: mails this session.");
M.Default("UMM_M_AC_NONAMES", "No mail sent yet.");
M.Default("UMM_M_AC_TOOK", "Took %s gold from %s's mail");
M.Default("UMM_M_AC_NOTTAKEN", "Gold from %s's mail did not arrive (%s)");
M.Default("UMM_M_AC_SENT", "%s  to  %s");
M.Default("UMM_M_AC_GOLDTO", "%s gold");
M.Default("UMM_M_AC_FAIL", "  failed: %s");
M.Default("UMM_M_AC_SKIP", "  skipped: %s");

local LINES = 18;
local LINE_H = 20;
local NAMES = 20;
local MAX = 300;

local entries = {};
local offset = 0;
local totals = { sent = 0, failed = 0, skipped = 0, gold = 0, takes = 0 };
local perName = {};
local ui = {};
local clock = 0;

local function now()
  return (GetTime and GetTime()) or UMMClock or 0;
end

local function reasonText(reason)
  if (type(reason) == "string" and type(_G[reason]) == "string") then return _G[reason]; end
  if (reason == 1) then return UMM_M_REASON_SELF; end
  if (reason == 2) then return UMM_M_REASON_SUBJECT; end
  if (reason == 3) then return UMM_M_REASON_BOUND; end
  return tostring(reason or "?");
end

local function what(step)
  local src = step.src or {};
  if (step.item) then return P.ItemSubject(step.item), C.text; end
  if (src.kind == "gold" or ((step.money or 0) > 0)) then return string.format(UMM_M_AC_GOLDTO, M.Gold(step.money)), C.gold; end
  return "\""..(step.subject or "").."\"", C.text;
end

-- Called by Modern/Queue.lua for every step that ended.
function M.Log(step, status, reason)
  local text, rgb;
  if (step.kind == "take") then
    if (status == "ok") then
      totals.takes = totals.takes + 1;
      text, rgb = string.format(UMM_M_AC_TOOK, M.Gold(step.money), step.sender or "?"), C.dim;
    else
      text, rgb = string.format(UMM_M_AC_NOTTAKEN, step.sender or "?", reasonText(reason)), C.bad;
    end
  else
    local thing, color = what(step);
    text = string.format(UMM_M_AC_SENT, thing, step.to or "?");
    rgb = color;
    if (status == "ok") then
      totals.sent = totals.sent + 1;
      totals.gold = totals.gold + (step.money or 0);
      local key = step.to or "?";
      perName[key] = (perName[key] or 0) + 1;
    elseif (status == "skipped") then
      totals.skipped = totals.skipped + 1;
      text, rgb = text..string.format(UMM_M_AC_SKIP, reasonText(reason)), C.warn;
    else
      totals.failed = totals.failed + 1;
      text, rgb = text..string.format(UMM_M_AC_FAIL, reasonText(reason)), C.bad;
    end
  end
  table.insert(entries, { t = now(), text = text, rgb = rgb });
  if (table.getn(entries) > MAX) then table.remove(entries, 1); end
  if (A.frame:IsVisible()) then A.Draw(); end
end

local function ago(t)
  local s = math.max(0, math.floor(now() - t));
  if (s < 60) then return s.."s"; end
  if (s < 3600) then return math.floor(s / 60).."m"; end
  return math.floor(s / 3600).."h";
end

local function drawTotals()
  local parts = { string.format(UMM_M_AC_TOTALS, totals.sent) };
  if (totals.failed > 0) then table.insert(parts, string.format(UMM_M_AC_FAILED, totals.failed)); end
  if (totals.skipped > 0) then table.insert(parts, string.format(UMM_M_AC_SKIPPED, totals.skipped)); end
  if (totals.gold > 0) then table.insert(parts, string.format(UMM_M_AC_GOLD, M.Gold(totals.gold))); end
  if (totals.takes > 0) then table.insert(parts, string.format(UMM_M_AC_TAKES, totals.takes)); end
  ui.totals:SetText(table.concat(parts, "  ·  "));
end

local function drawLog()
  local total = table.getn(entries);
  offset = math.max(0, math.min(offset, total - LINES));
  for i = 1, LINES do
    local entry = entries[total - offset - i + 1];
    local line = ui.lines[i];
    if (entry) then
      line.time:SetText(ago(entry.t));
      M.SetText(line.text, entry.text, entry.rgb);
    else
      line.time:SetText("");
      line.text:SetText("");
    end
  end
  ui.empty:SetText(total == 0 and UMM_M_AC_EMPTY or "");
end

local function drawNames()
  local history = UMMSettings:History();
  for i = 1, NAMES do
    local b = getglobal("UMMModernActivityName"..i);
    local name = history[i];
    b.ummName = name;
    if (name) then
      M.ButtonText(b, name, (M.WhoColor(name)));
      b.ummCount:SetText(perName[name] and tostring(perName[name]) or "");
      b:Show();
    else
      b:Hide();
    end
  end
  ui.noNames:SetText(history[1] and "" or UMM_M_AC_NONAMES);
end

function A.Draw()
  drawTotals();
  drawLog();
end

function A.Build()
  local f = A.frame;
  ui.totals = M.Label(f, 12, C.text, "LEFT");
  M.Place(ui.totals, f, 8, 4, 400, 22);
  M.Button(UMMModernActivityClear, f, 412, 4, 80, 22, { text = UMM_M_AC_CLEAR, icon = "Broom", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_AC_CLEAR, UMM_M_AC_CLEAR_TIP }, click = function()
      entries, offset, perName = {}, 0, {};
      totals = { sent = 0, failed = 0, skipped = 0, gold = 0, takes = 0 };
      A.Draw();
      drawNames();
    end });
  local head = M.Label(f, 11, C.dim, "LEFT");
  M.Place(head, f, 8, 28, 484, 16);
  head:SetText(UMM_M_AC_LOG);

  local log = UMMModernActivityLog;
  M.Hit(log, f, 8, 46, 484, LINES * LINE_H);
  M.Panel(log, 0, 0, 484, LINES * LINE_H, C.panel, M.STYLES.quiet.edge, 0.9);
  log.ummWheel = function(_, delta)
    offset = offset + (delta > 0 and -3 or 3);
    drawLog();
  end;
  ui.lines = {};
  for i = 1, LINES do
    local y = (i - 1) * LINE_H;
    local line = {};
    line.time = M.Label(log, 11, C.dim, "RIGHT");
    M.Place(line.time, log, 4, y, 34, LINE_H);
    line.text = M.Label(log, 12, C.text, "LEFT");
    M.Place(line.text, log, 46, y, 432, LINE_H);
    ui.lines[i] = line;
  end
  ui.empty = M.Label(log, 13, C.dim, "CENTER");
  M.Place(ui.empty, log, 0, 150, 484, 24);

  local x = 506;
  local title = M.Label(f, 13, C.head, "LEFT");
  M.Place(title, f, x, 4, 246, 22);
  title:SetText(UMM_M_AC_NAMES);
  local help = M.Label(f, 11, C.dim, "LEFT");
  M.Place(help, f, x, 26, 246, 16);
  help:SetText(UMM_M_AC_NAMES_HELP);
  for i = 1, NAMES do
    local col, row = math.floor((i - 1) / 10), (i - 1) % 10;
    local b = getglobal("UMMModernActivityName"..i);
    M.Button(b, f, x + col * 124, 46 + row * 26, 120, 22, { text = "", size = 12, style = "quiet", justify = "LEFT",
      click = function(btn)
        if (btn.ummName) then
          M.ShowPage("compose");
          M.pages.compose.UseName(btn.ummName);
        end
      end });
    M.Place(b.umm.label, b, 6, 0, 80, 22);
    b.ummCount = M.Label(b, 11, C.dim, "RIGHT");
    M.Place(b.ummCount, b, 86, 0, 28, 22);
    b:Hide();
  end
  ui.noNames = M.Label(f, 12, C.dim, "LEFT");
  M.Place(ui.noNames, f, x, 50, 246, 20);
end

function A.Show()
  clock = 0;
  A.Draw();
  drawNames();
end

function A.HistoryChanged()
  if (A.frame:IsVisible()) then drawNames(); end
end

-- the "2m" times move on once a second while the page is open
function A.Tick(dt)
  if (not A.frame:IsVisible() or table.getn(entries) == 0) then return; end
  clock = clock + dt;
  if (clock >= 1) then
    clock = 0;
    drawLog();
  end
end
