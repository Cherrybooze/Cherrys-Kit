-- Cherry's Kit: the Mass send page of the modern window. All six bag pages at once; click items to
-- mark them (Ctrl-click: every stack of that item), drag a box over them, click a category box under
-- the bags, or type part of a name and press Enter. Every marked item goes in its own mail to To.
--
-- The bag grid is one mouse frame: the slot under the cursor is worked out from the cursor, so the
-- 180 slots are only textures, made the first time the page opens.

local M = UMMModern;
local C = M.C;
local P = M.Plan;
local K = M.Picker;
local BM = UMMBagManager;
local Page = { frame = UMMModernMass };
M.pages.mass = Page;

M.Default("UMM_M_MS_SEARCH", "Mark by name, then Enter");
M.Default("UMM_M_MS_SEARCH_TIP", "Items whose name has these letters stay bright; Enter marks all of them. In the bags: click marks an item, Ctrl-click every stack of it, and a box dragged over items marks what is inside (Ctrl or Shift keeps what is marked already).");
M.Default("UMM_M_MS_MARKED", "Marked");
M.Default("UMM_M_MS_UNMARK_TIP", "Click to unmark all of these.");
M.Default("UMM_M_MS_CAT_TIP", "Click to mark every item of this kind in your bags.");
M.Default("UMM_M_MS_CAT_TO", "Fills an empty To with %s (Recipient/Characters.lua).");
M.Default("UMM_M_MS_ALLCATS", "All categories");
M.Default("UMM_M_MS_ALLCATS_TIP", "Click to mark every item of all the kinds here.");
M.Default("UMM_M_MS_ALL", "All");
M.Default("UMM_M_MS_NONE", "Nothing marked. Click items, drag a box, or click a category under the bags.");
M.Default("UMM_M_MS_SUMMARY", "%d marked: %d mails to %s");
M.Default("UMM_M_MS_SUMMARY_NOTO", "%d marked: enter a name in To.");
M.Default("UMM_M_MS_BOUND", "  (%d bound, left out)");
M.Default("UMM_M_MS_CLEAR", "Unmark all");
M.Default("UMM_M_MS_COD", "C.O.D.");
M.Default("UMM_M_MS_COD_TIP", "Each mail asks this much gold from the receiver before they can take the item.");
M.Default("UMM_M_MS_COD_HINT", "price, each mail");
M.Default("UMM_M_MS_SAFE", "Send safely %d");
M.Default("UMM_M_MS_FAST", "Send fast");
M.Default("UMM_M_MS_TOSET", "This category goes to %s (Recipient/Characters.lua).");

local CELL, STEP = 28, 30;
local BAG_W, BAG_H, BAG_GAP = 6 * STEP - 2, 5 * STEP - 2, 10;
-- Drawn like the game's bags: each bag on a rounded panel, each slot a rounded box. The pictures
-- (Textures/Modern/bagpanel and slot, from tools/build_umm_modern_assets.py) are made for these
-- sizes; their edge takes the tint and their inside a darker share of it.
local PANEL_PAD = 3;
local PANEL_TINT, SLOT_TINT = {0.08, 0.16, 0.20}, {0.20, 0.30, 0.38};
local GRID_X, GRID_Y = 8, 36;
local GRID_W, GRID_H = BAG_W * 3 + BAG_GAP * 2, BAG_H * 2 + BAG_GAP;
local LIST_ROWS, LIST_ROW = 14, 22;
local SIDE_X, SIDE_W = 572, 180;
local BOTTOM_Y = 398;

-- ### Categories ###
-- The 35 kinds UMMMassMarkCategory marks (Library/ItemDB.lua's GetTypeByID, in that order), then
-- all of them as box 36. Each box shows the game's own icon of a typical item of its kind
-- (GetObjImage), so Library/ItemDB.lua (550 KB) is still read only when a box is clicked. A client
-- without GetObjImage gets a picture from Interface/icons instead. Kinds whose items look alike
-- (T6 gear, recipes, pet eggs, Cenedril) also carry a short tag; pet egg tags take their element's
-- colour.
local CATS = 36;
local CAT_SIZE, CAT_STEP = 22, 24;
local CAT_Y = GRID_Y + GRID_H + 6;
local ELEMENT = {
  dark = {0.74, 0.58, 1.00}, earth = {0.86, 0.66, 0.36}, fire = {1.00, 0.48, 0.32}, light = {1.00, 0.92, 0.45},
  water = {0.42, 0.76, 1.00}, rune = {0.45, 0.95, 0.90}, wind = {0.56, 1.00, 0.56},
};
local CATEGORY = {
  { item = 520021, icon = "runes_stone01_01" },                     -- 1 runes (Power I)
  { item = 200854, icon = "rune_crystal_001" },                     -- 2 production runes (Purify Rune)
  { item = 202882, icon = "fusion_stone001" },                      -- 3 fusion stones
  { item = 202849, icon = "mana stone10" },                         -- 4 mana stones (tier 10)
  { item = 202939, icon = "item_mat_001" },                         -- 5 general materials (Life Crystal)
  { item = 200473, icon = "item_mat_002" },                         -- 6 raw materials (Apple)
  { item = 200084, icon = "item_food_010_001" },                    -- 7 foods and desserts (Roasted Meat)
  { item = 200154, icon = "item_potion_000_001" },                  -- 8 potions (Basic Healing Potion)
  { item = 224451, icon = "bag01", tag = "Bag" },                   -- 9 T6 bag stat items
  { item = 212635, tag = "Cln" },                                   -- 10 clean T6 items
  { item = 214843, tag = "!" },                                     -- 11 T6 items to check before sending
  { item = 210438, tag = "Abl" },                                   -- 12 T6 items with an ability
  { item = 550676, tag = "Alc" },                                   -- 13 alchemy recipes
  { item = 550432, tag = "Ck" },                                    -- 14 cooking recipes
  { item = 550483, tag = "Tl" },                                    -- 15 tailoring recipes
  { item = 550257, tag = "Cp" },                                    -- 16 carpentry recipes
  { item = 550579, tag = "Ar" },                                    -- 17 armorcrafting recipes
  { item = 550346, tag = "Bs" },                                    -- 18 blacksmithing recipes
  { item = 550952, tag = "+" },                                     -- 19 other recipes
  { item = 200234, icon = "item_ore_001" },                         -- 20 ores (Iron Ore)
  { item = 200293, icon = "item_lum_001" },                         -- 21 wood (Ash Wood)
  { item = 200333, icon = "item_her_001" },                         -- 22 herbs (Bitterleaf)
  { item = 770004, icon = "item_moncard" },                         -- 23 monster cards
  { item = 202916, icon = "guildwar_001" },                         -- 24 guild contributions (Guild Rune)
  { item = 204481, icon = "shop_goods/egg_01", tag = "Dk", color = ELEMENT.dark },    -- 25 pet eggs
  { item = 204476, icon = "shop_goods/egg_01", tag = "Ea", color = ELEMENT.earth },   -- 26
  { item = 204478, icon = "shop_goods/egg_01", tag = "Fi", color = ELEMENT.fire },    -- 27
  { item = 204480, icon = "shop_goods/egg_01", tag = "Li", color = ELEMENT.light },   -- 28
  { item = 204477, icon = "shop_goods/egg_01", tag = "Wa", color = ELEMENT.water },   -- 29
  { item = 204509, icon = "shop_goods/egg_01", tag = "Ru", color = ELEMENT.rune },    -- 30
  { item = 204479, icon = "shop_goods/egg_01", tag = "Wi", color = ELEMENT.wind },    -- 31
  { item = 209873, tag = "Dyn" },                                   -- 32 Cenedril: dynamic
  { item = 209875, tag = "Mys" },                                   -- 33 mystical
  { item = 209874, tag = "Std" },                                   -- 34 steadfast
  { item = 200016, icon = "quest_bag01" },                          -- 35 daily quest materials
};
local catButtons = {};

local built = false;
local cells = {};
local groups = {};
local markedOffset = 0;
local search = "";
local codOn = false;
local dirty = false;
local running = false;
local hoverIndex, hoverTime = nil, 0;
local selBox = nil;
local ui = {};
local sendCount, boundCount = 0, 0;
local TIP_SAFE = { UMM_MSI_BUTTON_SENDSAFE, UMM_MSI_TIP_SENDSAFE };

local function trim(text)
  return string.match(text or "", "^%s*(.-)%s*$") or "";
end

-- Top left corner of bag slot i (1 to 180) in the grid: 6 bag pages, 3 across and 2 down, each
-- 6 slots wide and 5 high, like the classic window.
local function cellPos(i)
  local bag = math.floor((i - 1) / 30);
  local slot = (i - 1) - bag * 30;
  return (bag % 3) * (BAG_W + BAG_GAP) + (slot % 6) * STEP, math.floor(bag / 3) * (BAG_H + BAG_GAP) + math.floor(slot / 6) * STEP;
end

-- The bag slot at x, y in the grid, or nil between slots.
local function cellAt(x, y)
  if (not x or not y or x < 0 or y < 0 or x >= GRID_W or y >= GRID_H) then return nil; end
  local bx, by = math.floor(x / (BAG_W + BAG_GAP)), math.floor(y / (BAG_H + BAG_GAP));
  local lx, ly = x - bx * (BAG_W + BAG_GAP), y - by * (BAG_H + BAG_GAP);
  if (lx >= BAG_W or ly >= BAG_H) then return nil; end
  local sx, sy = math.floor(lx / STEP), math.floor(ly / STEP);
  if (lx - sx * STEP >= CELL or ly - sy * STEP >= CELL) then return nil; end
  return (by * 3 + bx) * 30 + sy * 6 + sx + 1;
end
Page.CellAt, Page.CellPos = cellAt, cellPos;

local function itemAt(i)
  local item = BM.ItemList[i];
  if (item and not item.Empty and item.Link) then return item; end
  return nil;
end

local function quality(item)
  if (item.ummQLink ~= item.Link) then
    item.ummQLink = item.Link;
    local r, g, b = UMMLinkColor(item.Link);
    if (r and not (r == 255 and g == 255 and b == 255)) then
      item.ummQ = { r / 255, g / 255, b / 255 };
    else
      item.ummQ = false;
    end
  end
  return item.ummQ;
end

local function matches(item)
  if (search == "") then return true; end
  if (item.ummLowerOf ~= item.Name) then
    item.ummLowerOf = item.Name;
    item.ummLower = string.lower(item.Name or "");
  end
  return string.find(item.ummLower, search, 1, true) ~= nil;
end

-- ### The grid ###

local function drawCell(i)
  local cell = cells[i];
  local item = itemAt(i);
  if (not item) then
    cell.icon:Hide();
    cell.quality:Hide();
    cell.mark:Hide();
    cell.count:SetText("");
    return;
  end
  cell.icon:SetTexture(item.Icon or "");
  cell.icon:SetAlpha(matches(item) and 1 or 0.25);
  cell.icon:Show();
  cell.count:SetText((item.Count or 1) > 1 and tostring(item.Count) or "");
  local q = quality(item);
  if (q) then
    M.SetColor(cell.quality, q, 0.9);
    cell.quality:Show();
  else
    cell.quality:Hide();
  end
  if (item.Marked == true) then
    M.SetColor(cell.mark, BM:IsBound(item) and C.bad or C.gold, 0.42);
    cell.mark:Show();
  else
    cell.mark:Hide();
  end
end

local function drawGrid()
  if (not built) then return; end
  BM:Ensure();
  for i = 1, 180 do drawCell(i); end
  dirty = false;
end

local function buildGrid()
  if (built) then return; end
  built = true;
  local g = UMMModernMassGrid;
  for bag = 0, 5 do
    local x, y = cellPos(bag * 30 + 1);
    M.Place(M.Texture(g, "BACKGROUND", "bagpanel", PANEL_TINT, 1), g, x - PANEL_PAD, y - PANEL_PAD,
      BAG_W + 2 * PANEL_PAD, BAG_H + 2 * PANEL_PAD);
  end
  for i = 1, 180 do
    local x, y = cellPos(i);
    local cell = {};
    cell.back = M.Texture(g, "BORDER", "slot", SLOT_TINT, 1);
    M.Place(cell.back, g, x, y, CELL, CELL);
    -- the icon stays inside the box's edge and round corners
    cell.icon = M.Icon(g, "ARTWORK", CELL - 4);
    M.Place(cell.icon, g, x + 2, y + 2, CELL - 4, CELL - 4);
    cell.quality = M.Texture(g, "ARTWORK", "white", C.line, 0.9);
    M.Place(cell.quality, g, x + 3, y + CELL - 4, CELL - 6, 2);
    cell.mark = M.Texture(g, "OVERLAY", "round-32-32", C.gold, 0.42);
    M.Place(cell.mark, g, x, y, CELL, CELL);
    cell.count = M.Label(g, 10, C.text, "RIGHT");
    M.Place(cell.count, g, x, y + CELL - 14, CELL - 3, 12);
    cells[i] = cell;
  end
  selBox = M.Texture(g, "OVERLAY", "white", M.STYLES.choice.edge, 0.3);
  M.Place(selBox, g, 0, 0, 1, 1);
  selBox:Hide();
end

-- ### Marked items, the summary and the buttons ###

local function buildGroups()
  for i = table.getn(groups), 1, -1 do groups[i] = nil; end
  local byName = {};
  local send, bound = 0, 0;
  BM:Ensure();
  for i = 1, 180 do
    local item = BM.ItemList[i];
    if (item and item.Marked == true and not item.Empty) then
      local isBound = BM:IsBound(item);
      if (isBound) then bound = bound + 1; else send = send + 1; end
      local key = item.Name or "?";
      local group = byName[key];
      if (not group) then
        group = { name = key, icon = item.Icon, stacks = 0, total = 0, bound = 0 };
        byName[key] = group;
        table.insert(groups, group);
      end
      group.stacks = group.stacks + 1;
      group.total = group.total + (item.Count or 1);
      if (isBound) then group.bound = group.bound + 1; end
    end
  end
  table.sort(groups, function(a, b) return a.name < b.name; end);
  sendCount, boundCount = send, bound;
end

local function drawMarked()
  local total = table.getn(groups);
  markedOffset = math.max(0, math.min(markedOffset, total - LIST_ROWS));
  for i = 1, LIST_ROWS do
    local row = getglobal("UMMModernMassMarkedRow"..i);
    local group = groups[markedOffset + i];
    row.ummGroup = group;
    if (group) then
      row.ummIcon:SetTexture(group.icon or "");
      M.SetText(row.ummName, group.name, group.bound > 0 and C.bad or C.text);
      row.ummCount:SetText((group.stacks > 1 and ("×"..group.stacks.."  ") or "")..group.total);
      row:Show();
    else
      row:Hide();
    end
  end
  ui.markedHead:SetText(UMM_M_MS_MARKED..(sendCount + boundCount > 0 and ("  "..(sendCount + boundCount)) or ""));
end

local function sendOK()
  local to = trim(UMMModernMassTo:GetText());
  local player = UnitName("player");
  return sendCount > 0 and to ~= "" and not (player and string.lower(to) == string.lower(player))
    and not running and not M.Busy() and (not codOn or M.GoldOf(UMMModernMassCODAmount) ~= nil);
end

local function drawControls()
  local to = trim(UMMModernMassTo:GetText());
  local text;
  if (sendCount + boundCount == 0) then
    text = UMM_M_MS_NONE;
  elseif (to == "") then
    text = string.format(UMM_M_MS_SUMMARY_NOTO, sendCount + boundCount);
  else
    text = string.format(UMM_M_MS_SUMMARY, sendCount + boundCount, sendCount, to);
  end
  if (boundCount > 0) then text = text..string.format(UMM_M_MS_BOUND, boundCount); end
  M.SetText(ui.summary, text, sendCount > 0 and C.text or C.dim);
  local ok = sendOK();
  -- Send safely and Send fast side by side, whatever the number of mails (7.0.1-ck17)
  M.ButtonText(UMMModernMassSend, string.format(UMM_M_MS_SAFE, sendCount));
  UMMModernMassSend.ummTip = TIP_SAFE;
  UMMModernMassFast:Show();
  M.Enable(UMMModernMassFast, ok);
  M.Enable(UMMModernMassSend, ok);
  M.Enable(UMMModernMassClear, sendCount + boundCount > 0 and not running);
  for i = 1, table.getn(catButtons) do M.Enable(catButtons[i], not running); end
end

-- C.O.D. is off until ticked, and its price box shows only while it is on; ticking either way
-- empties the price.
local function setCOD(on)
  codOn = on and true or false;
  M.ButtonIcon(UMMModernMassCOD, codOn and "CheckboxOn" or "CheckboxOff");
  M.SetEditText(UMMModernMassCODAmount, "");
  if (codOn) then
    UMMModernMassCODAmount:Show();
  else
    UMMModernMassCODAmount:ClearFocus();
    UMMModernMassCODAmount:Hide();
  end
end

-- Use last follows the "Mail shortcuts" setting, like the classic window.
local function drawShortcuts()
  if (UMMSettings:ShortcutsEnabled()) then UMMModernMassLast:Show(); else UMMModernMassLast:Hide(); end
end

local function marksChanged()
  buildGroups();
  drawMarked();
  drawControls();
end

local function drawWho()
  local name = trim(UMMModernMassTo:GetText());
  local player = UnitName("player");
  if (name == "") then
    ui.who:SetText("");
  elseif (player and string.lower(name) == string.lower(player)) then
    M.SetText(ui.who, UMM_M_CO_YOU, C.bad);
  else
    local rgb, kind = M.WhoColor(name);
    M.SetText(ui.who, (kind == "Character" and UMM_M_CO_WHO_OWN) or (kind == "Friend" and UMM_M_CO_WHO_FRIEND)
      or (kind == "Guildie" and UMM_M_CO_WHO_GUILD) or "", rgb);
  end
end

-- ### Marking ###

local function warnBound(item)
  if (item and item.Marked == true and BM:IsBound(item)) then
    UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND);
  end
end

local function toggleMark(i)
  local item = itemAt(i);
  if (not item) then return; end
  item.Marked = not (item.Marked == true);
  warnBound(item);
  drawCell(i);
end

-- every stack of the clicked item; on a marked item, unmarks them all
local function toggleGroup(i)
  local clicked = itemAt(i);
  if (not clicked or not clicked.Name) then return; end
  local state = not (clicked.Marked == true);
  local anyBound = false;
  for j = 1, 180 do
    local item = itemAt(j);
    if (item and item.Name == clicked.Name) then
      item.Marked = state;
      if (state and BM:IsBound(item)) then anyBound = true; end
      drawCell(j);
    end
  end
  if (anyBound) then UMMPrompt("|r|cff"..UMMColor.Red..UMM_ERROR_CANTSENDBOUND); end
end

local function unmarkName(name)
  for j = 1, 180 do
    local item = itemAt(j);
    if (item and item.Name == name and item.Marked) then
      item.Marked = false;
      drawCell(j);
    end
  end
  marksChanged();
end

local function clearMarks()
  if (running) then return; end
  BM:ClearMarks();
  drawGrid();
  marksChanged();
end

local function markSearch()
  if (running or search == "") then return; end
  BM:Ensure();
  for i = 1, 180 do
    local item = itemAt(i);
    if (item and matches(item)) then item.Marked = true; end
  end
  drawGrid();
  marksChanged();
end

local function markCategory(id)
  if (running) then return; end
  local to = UMMMassMarkCategory(id);
  if (to and trim(UMMModernMassTo:GetText()) == "") then
    UMMModernMassTo:SetText(to);
    M.Status(string.format(UMM_M_MS_TOSET, to), C.dim);
  end
  drawGrid();
  marksChanged();
end

-- Mouse down on the grid: a click (mouse up close by) marks one slot, a drag draws a box.
local function gridDown(g, key)
  if (running or (key and key ~= "LBUTTON" and key ~= "LeftButton")) then return; end
  local x, y = M.LocalCursor(g);
  if (not x) then return; end
  BM:Ensure();
  local ctrl = M.Held(IsCtrlKeyDown);
  local additive = ctrl or M.Held(IsShiftKeyDown);
  local saved = {};
  for i = 1, 180 do
    local item = BM.ItemList[i];
    saved[i] = item ~= nil and item.Marked == true;
  end
  local start = cellAt(x, y);
  local active = false;
  M.HideTip(g);
  M.StartDrag(function()
    local cx, cy = M.LocalCursor(g);
    if (not cx) then return; end
    if (not active) then
      if ((cx - x) * (cx - x) + (cy - y) * (cy - y) < 16) then return; end
      active = true;
    end
    local l, t = math.max(0, math.min(x, cx)), math.max(0, math.min(y, cy));
    local r, b = math.min(GRID_W, math.max(x, cx)), math.min(GRID_H, math.max(y, cy));
    M.Place(selBox, g, l, t, math.max(1, r - l), math.max(1, b - t));
    selBox:Show();
    for i = 1, 180 do
      local item = itemAt(i);
      if (item) then
        local px, py = cellPos(i);
        local want = (px < r and px + CELL > l and py < b and py + CELL > t) or (additive and saved[i]) or false;
        if ((item.Marked == true) ~= want) then
          item.Marked = want;
          drawCell(i);
        end
      end
    end
  end, function(cancelled)
    selBox:Hide();
    if (not cancelled and not active and start) then
      if (ctrl) then toggleGroup(start); else toggleMark(start); end
    end
    marksChanged();
  end);
end

local function hoverUpdate(f, elapsed)
  hoverTime = hoverTime + (elapsed or 0);
  if (hoverTime < 0.1) then return; end
  hoverTime = 0;
  if (M.Dragging()) then return; end
  local g = UMMModernMassGrid;
  local x, y = M.LocalCursor(g);
  local i = cellAt(x, y);
  if (i == hoverIndex) then return; end
  hoverIndex = i;
  local item = i and itemAt(i);
  if (item and GameTooltip) then
    GameTooltip:SetOwner(g, "ANCHOR_RIGHT", 0, 0);
    if (GameTooltip.SetHyperLink) then GameTooltip:SetHyperLink(item.Link); else GameTooltip:SetText(item.Name or "?"); end
    GameTooltip:Show();
    M.tipOwner = g;
  else
    M.HideTip(g);
  end
end

-- ### Sending ###

local function send(mode)
  if (running or M.Busy()) then
    UMMPrompt(UMM_ERROR_STILLSENDING);
    return;
  end
  if (not sendOK()) then return; end
  local to = trim(UMMModernMassTo:GetText());
  local cod = codOn and (M.GoldOf(UMMModernMassCODAmount) or 0) or 0;
  -- the bags read fresh: what is sent is what is there now
  BM:Load();
  local steps = {};
  for i = 1, 180 do
    local entry = BM.ItemList[i];
    if (entry and entry.Marked == true and not entry.Empty and not BM:IsBound(entry)) then
      local item = { index = entry.Index, link = entry.Link, name = entry.Name, count = entry.Count or 1, icon = entry.Icon };
      table.insert(steps, { kind = "mail", to = to, subject = P.ItemSubject(item), body = "", item = item,
        money = 0, cod = cod, src = { kind = "mass" } });
    end
  end
  if (table.getn(steps) == 0) then return; end
  K.Close();
  if (M.focus) then M.focus:ClearFocus(); end
  running = true;
  if (not UMMQueue:Run(steps, { fast = mode == "fast", owner = Page })) then
    running = false;
    UMMPrompt(UMM_ERROR_STILLSENDING);
  end
  drawControls();
end

function Page.QueueStep(step, status)
  if (status == "ok") then dirty = true; end
end

function Page.QueueDone()
  running = false;
  dirty = true;
  drawGrid();
  marksChanged();
end

-- ### Building ###

local function markedWheel(_, delta)
  markedOffset = markedOffset + (delta > 0 and -2 or 2);
  drawMarked();
end

local function buildTop()
  local f = Page.frame;
  local toLabel = M.Label(f, 12, C.dim, "LEFT");
  M.Place(toLabel, f, 8, 6, 30, 22);
  toLabel:SetText(UMM_M_CO_TO);
  M.Edit(UMMModernMassTo, f, 40, 6, 194, 22, { hint = UMM_M_CO_TO_HINT, name = true, text = function(box)
    if (K.IsOpenFor(box)) then K.Filter(); end
    drawWho();
    drawControls();
  end });
  UMMModernMassTo.ummFocus = function(box)
    if (UMMAutoNameList()) then K.Open(box, function() drawWho(); drawControls(); end); end
  end;
  UMMModernMassTo.ummEnterKey = function(box)
    local first = K.IsOpenFor(box) and K.First();
    if (first) then K.Use(first); else K.Close(); box:ClearFocus(); end
  end;
  UMMModernMassTo.ummEsc = function() K.Close(); end;
  M.Button(UMMModernMassPick, f, 238, 6, 24, 22, { icon = "Characters", iconSize = 16, style = "quiet",
    tip = { UMM_M_CO_PICK_TIP }, click = function()
      K.Toggle(UMMModernMassTo, function() drawWho(); drawControls(); end);
    end });
  M.Button(UMMModernMassLast, f, 266, 6, 74, 22, { text = UMM_M_CO_LAST, size = 12, style = "quiet",
    tip = { UMM_M_CO_LAST, UMM_M_CO_LAST_TIP }, click = function()
      local last = UMMSettings:LastRecipient();
      if (last) then
        K.Close();
        UMMModernMassTo:SetText(last);
      end
    end });
  ui.who = M.Label(f, 11, C.dim, "LEFT");
  M.Place(ui.who, f, 346, 6, 216, 22);

  M.Edit(UMMModernMassSearch, f, SIDE_X + 4, 6, SIDE_W - 8, 22, { hint = UMM_M_MS_SEARCH, tip = { UMM_M_MS_SEARCH, UMM_M_MS_SEARCH_TIP },
    text = function(box)
      search = string.lower(trim(box:GetText()));
      drawGrid();
    end });
  UMMModernMassSearch.ummEnterKey = function(box) markSearch(); box:ClearFocus(); end;
  UMMModernMassSearch.ummEsc = function(box) box:SetText(""); end;
end

local function buildSide()
  local f = Page.frame;
  ui.markedHead = M.Label(f, 11, C.dim, "LEFT");
  M.Place(ui.markedHead, f, SIDE_X + 2, 34, SIDE_W, 14);
  local marked = UMMModernMassMarked;
  M.Hit(marked, f, SIDE_X, 50, SIDE_W, LIST_ROWS * LIST_ROW);
  marked.ummWheel = markedWheel;
  for i = 1, LIST_ROWS do
    local row = getglobal("UMMModernMassMarkedRow"..i);
    M.Button(row, marked, 0, (i - 1) * LIST_ROW, SIDE_W, LIST_ROW - 1, { style = "row",
      tip = { UMM_M_MS_MARKED, UMM_M_MS_UNMARK_TIP },
      click = function(b) if (b.ummGroup and not running) then unmarkName(b.ummGroup.name); end end });
    row.umm.rowAlpha = 0.25;
    row.ummWheel = marked.ummWheel;
    row.ummIcon = M.Icon(row, "ARTWORK", 16);
    M.Place(row.ummIcon, row, 3, 3, 16, 16);
    row.ummName = M.Label(row, 11, C.text, "LEFT");
    M.Place(row.ummName, row, 24, 0, 100, LIST_ROW - 1);
    row.ummCount = M.Label(row, 11, C.dim, "RIGHT");
    M.Place(row.ummCount, row, 120, 0, SIDE_W - 124, LIST_ROW - 1);
    row:Hide();
  end
  -- what Send would do, beside the Send button: up to three lines
  ui.summary = M.Label(f, 12, C.text, "LEFT");
  M.Place(ui.summary, f, SIDE_X + 2, 50 + LIST_ROWS * LIST_ROW + 6, SIDE_W - 4, 54);
end

-- Name and help for category box b; the name set for that kind in Recipient/Characters.lua too.
local function catTip(b)
  local id = b.ummCat;
  local tip;
  if (id == CATS) then
    tip = { UMM_M_MS_ALLCATS, UMM_M_MS_ALLCATS_TIP };
  else
    tip = { getglobal("UMM_MSI_MARK_TOOLTIP"..id) or tostring(id), UMM_M_MS_CAT_TIP };
  end
  local to = getglobal("UMM_MSI_RECIPE_SEND_TO"..id);
  if (to and to ~= "") then table.insert(tip, string.format(UMM_M_MS_CAT_TO, to)); end
  return tip;
end

-- The picture of category c: the game's icon of its item, else one from Interface/icons.
local function catIcon(c)
  local path;
  if (type(GetObjImage) == "function") then
    local ok, found = pcall(GetObjImage, c.item);
    if (ok and type(found) == "string" and found ~= "") then path = found; end
  end
  return path or ("Interface/icons/"..(c.icon or "icon-default"));
end

-- The category boxes: 2 rows of 18 under the bags, each centred under a column of bag slots.
local function buildCats()
  local f = Page.frame;
  local inset = math.floor((CELL - CAT_SIZE) / 2);
  for id = 1, CATS do
    local b = getglobal("UMMModernMassCat"..id);
    local col, row = (id - 1) % 18, math.floor((id - 1) / 18);
    local x = GRID_X + math.floor(col / 6) * (BAG_W + BAG_GAP) + (col % 6) * STEP + inset;
    local c = CATEGORY[id];
    M.Button(b, f, x, CAT_Y + row * CAT_STEP, CAT_SIZE, CAT_SIZE, { style = "quiet", tip = catTip,
      text = (id == CATS) and UMM_M_MS_ALL or nil, size = 10,
      click = function(button) markCategory(button.ummCat); end });
    b.ummCat = id;
    if (c) then
      local icon = M.Icon(b, "ARTWORK", CAT_SIZE - 4);
      M.Place(icon, b, 2, 2, CAT_SIZE - 4, CAT_SIZE - 4);
      icon:SetTexture(catIcon(c));
      b.umm.icon = icon;   -- dims with the button while a send runs
      if (c.tag) then
        M.Default("UMM_M_MS_TAG"..id, c.tag);
        local shade = M.Texture(b, "OVERLAY", "white", C.bg, 0.72);
        M.Place(shade, b, 2, CAT_SIZE - 11, CAT_SIZE - 4, 9);
        local tag = M.Label(b, 9, c.color or C.text, "CENTER", "OVERLAY");
        M.Place(tag, b, 1, CAT_SIZE - 12, CAT_SIZE - 2, 11);
        tag:SetText(getglobal("UMM_M_MS_TAG"..id));
        b.ummTag = tag;
      end
    end
    catButtons[id] = b;
  end
end

local function buildBottom()
  local f = Page.frame;
  local y = BOTTOM_Y;
  M.Button(UMMModernMassClear, f, 8, y, 110, 24, { text = UMM_M_MS_CLEAR, icon = "Broom", iconSize = 14, size = 12,
    style = "quiet", click = clearMarks });
  M.Button(UMMModernMassCOD, f, 124, y, 84, 24, { text = UMM_M_MS_COD, icon = "CheckboxOff", iconSize = 14, size = 12,
    style = "quiet", tip = { UMM_M_MS_COD, UMM_M_MS_COD_TIP }, click = function()
      if (running) then return; end
      setCOD(not codOn);
      if (codOn) then UMMModernMassCODAmount:SetFocus(); end
      drawControls();
    end });
  M.Edit(UMMModernMassCODAmount, f, 214, y + 1, 120, 22, { gold = true, hint = UMM_M_MS_COD_HINT, text = drawControls });
  UMMModernMassCODAmount:Hide();
  M.Button(UMMModernMassFast, f, 340, y, 104, 24, { text = UMM_M_MS_FAST, icon = "Run", iconSize = 14, size = 12,
    style = "action", tip = { UMM_MSI_BUTTON_SENDFAST, UMM_MSI_TIP_SENDFAST }, click = function() send("fast"); end });
  M.Button(UMMModernMassSend, f, 448, y, 114, 24, { text = "", icon = "Mail", iconSize = 16, size = 12,
    style = "save", click = function() send("safe"); end });
  UMMModernMassFast:Hide();
end

function Page.Build()
  local g = UMMModernMassGrid;
  M.Hit(g, Page.frame, GRID_X, GRID_Y, GRID_W, GRID_H);
  g.ummDown = gridDown;
  g.ummUp = function() if (M.Dragging()) then M.StopDrag(); end end;
  g.ummEnter = function() hoverIndex, hoverTime = nil, 1; UMMModernMassHover:Show(); end;
  g.ummLeave = function()
    UMMModernMassHover:Hide();
    hoverIndex = nil;
    M.HideTip(UMMModernMassGrid);
  end;
  UMMModernMassHover.ummOn = { update = hoverUpdate };
  buildTop();
  buildSide();
  buildCats();
  buildBottom();
end

-- ### Page hooks ###

function Page.Show()
  buildGrid();   -- the 180 slots are made the first time the page opens
  drawShortcuts();
  drawGrid();
  drawWho();
  marksChanged();
end

function Page.Hide()
  UMMModernMassHover:Hide();
end

function Page.BagsChanged()
  dirty = true;
end

function Page.Tick()
  -- bag changes come in bursts (one per mail sent): the grid is drawn again at most 4 times a second
  if (dirty and built and Page.frame:IsVisible() and not M.Dragging()) then
    drawGrid();
    marksChanged();
  end
end

function Page.UseName(name)
  UMMModernMassTo:SetText(name);
  K.Close();
  return true;
end

function Page.Closed()
  running = false;
  UMMModernMassHover:Hide();
  if (codOn) then setCOD(false); end
end

function Page.ShortcutsChanged()
  drawShortcuts();
end
