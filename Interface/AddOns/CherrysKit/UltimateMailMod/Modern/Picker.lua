-- Cherry's Kit: the name list under a To field of the modern window. It opens when a To field gets
-- the cursor and narrows down while you type: recently mailed names first, then your characters,
-- friends and guild. Click a name (or press Enter for the first one) to use it.

local M = UMMModern;
local K = {};
M.Picker = K;

M.Default("UMM_M_PICK_ALL", "All");
M.Default("UMM_M_PICK_RECENT", "Recent");
M.Default("UMM_M_PICK_MINE", "Mine");
M.Default("UMM_M_PICK_FRIENDS", "Friends");
M.Default("UMM_M_PICK_GUILD", "Guild");
M.Default("UMM_M_PICK_NONE", "No name matches. Type the whole name.");
M.Default("UMM_M_PICK_TIP", "Names: recently mailed, your characters, friends, guild. Enter takes the first one.");

local ROWS, ROW_H, WIDTH = 10, 20, 236;
local CHIPS = {
  { key = "all", text = "UMM_M_PICK_ALL" },
  { key = "recent", text = "UMM_M_PICK_RECENT" },
  { key = "own", text = "UMM_M_PICK_MINE" },
  { key = "friend", text = "UMM_M_PICK_FRIENDS" },
  { key = "guild", text = "UMM_M_PICK_GUILD" },
};
local KIND_TEXT = { recent = "UMM_M_PICK_RECENT", own = "UMM_M_PICK_MINE", friend = "UMM_M_PICK_FRIENDS", guild = "UMM_M_PICK_GUILD" };

local entries = {};   -- { name, kind } in the order shown under "All"
local shown = {};     -- entries matching the filter
local source = "all";
local offset = 0;
local target, picked = nil, nil;
local frame, empty;

local function kindColor(kind)
  if (kind == "own") then return M.C.own; end
  if (kind == "friend") then return M.C.friend; end
  if (kind == "guild") then return M.C.guild; end
  return M.C.other;
end

-- Everyone you could mail, once per name: recent, own, friends, guild.
function K.Collect()
  entries = {};
  local seen = {};
  local function add(name, kind)
    if (type(name) ~= "string" or name == "") then return; end
    local key = string.lower(name);
    if (seen[key]) then return; end
    seen[key] = true;
    table.insert(entries, { name = name, kind = kind, lower = key });
  end
  for _, name in ipairs(UMMSettings:History()) do add(name, "recent"); end
  local own, friends, guild = {}, {}, {};
  for name, info in pairs(UMMFriends.List or {}) do
    if (info.Own) then table.insert(own, name);
    elseif (info.Friend) then table.insert(friends, name);
    elseif (info.Guild) then table.insert(guild, name); end
  end
  -- your characters in the order of UMM_OwnCharacters (Recipient/Characters.lua), then by name
  local order = {};
  for i, name in ipairs(UMM_OwnCharacters or {}) do order[name] = i; end
  table.sort(own, function(a, b)
    local oa, ob = order[a] or 1000, order[b] or 1000;
    if (oa ~= ob) then return oa < ob; end
    return a < b;
  end);
  table.sort(friends);
  table.sort(guild);
  for _, name in ipairs(own) do add(name, "own"); end
  for _, name in ipairs(friends) do add(name, "friend"); end
  for _, name in ipairs(guild) do add(name, "guild"); end
end

local function kindOf(entry)
  -- a recent name keeps the colour of who it is
  if (entry.kind ~= "recent") then return entry.kind; end
  local info = UMMFriends.List and UMMFriends.List[entry.name];
  if (info and info.Own) then return "own"; end
  if (info and info.Friend) then return "friend"; end
  if (info and info.Guild) then return "guild"; end
  return "recent";
end

local function matches(entry, text)
  if (source ~= "all") then
    if (source == "recent" and entry.kind ~= "recent") then return false; end
    if (source ~= "recent" and kindOf(entry) ~= source) then return false; end
  end
  return text == "" or string.find(entry.lower, text, 1, true) ~= nil;
end

function K.Filter()
  local text = target and string.lower(target:GetText() or "") or "";
  -- names starting with what was typed first, then names containing it
  local n = 0;
  for i = table.getn(shown), 1, -1 do shown[i] = nil; end
  for _, entry in ipairs(entries) do
    if (matches(entry, text) and (text == "" or string.sub(entry.lower, 1, string.len(text)) == text)) then
      n = n + 1; shown[n] = entry;
    end
  end
  if (text ~= "") then
    for _, entry in ipairs(entries) do
      if (matches(entry, text) and string.sub(entry.lower, 1, string.len(text)) ~= text) then
        n = n + 1; shown[n] = entry;
      end
    end
  end
  offset = 0;
  K.Draw();
end

function K.Draw()
  local total = table.getn(shown);
  offset = math.max(0, math.min(offset, total - ROWS));
  for i = 1, ROWS do
    local row = getglobal("UMMModernPickerRow"..i);
    local entry = shown[offset + i];
    if (entry) then
      row.ummEntry = entry;
      M.SetText(row.ummName, entry.name, kindColor(kindOf(entry)));
      row.ummKind:SetText(getglobal(KIND_TEXT[entry.kind] or "UMM_M_PICK_RECENT"));
      row:Show();
    else
      row.ummEntry = nil;
      row:Hide();
    end
  end
  empty:SetText(total == 0 and UMM_M_PICK_NONE or "");
  for i, chip in ipairs(CHIPS) do
    M.Select(getglobal("UMMModernPickerChip"..i), chip.key == source);
  end
end

-- The name Enter takes in the To field: the one typed in full if the list has it, else the first
-- one the list offers, or nil.
function K.First()
  if (not frame:IsVisible()) then return nil; end
  local text = target and string.lower(target:GetText() or "") or "";
  for i = 1, table.getn(shown) do
    if (shown[i].lower == text) then return shown[i].name; end
  end
  local entry = shown[1];
  return entry and entry.name;
end

function K.IsOpenFor(box)
  return frame:IsVisible() and target == box;
end

-- Opens under box. onPick(box, name) runs after a name was put in the box.
function K.Open(box, onPick)
  target, picked = box, onPick;
  K.Collect();
  frame:ClearAllAnchors();
  frame:SetAnchor("TOPLEFT", "BOTTOMLEFT", box:GetName(), -4, 2);
  frame:Show();
  K.Filter();
end

function K.Close()
  if (frame and frame:IsVisible()) then frame:Hide(); end
  target, picked = nil, nil;
end

function K.Toggle(box, onPick)
  if (K.IsOpenFor(box)) then K.Close(); else K.Open(box, onPick); box:SetFocus(); end
end

function K.Use(name)
  local box, onPick = target, picked;
  K.Close();
  if (not box or not name) then return; end
  box:SetText(name);
  if (onPick) then onPick(box, name); end
end

function K.Build()
  frame = UMMModernPicker;
  local h = 34 + ROWS * ROW_H + 8;
  M.Size(frame, WIDTH, h);
  frame.ummOn = M.BUTTON;
  frame.ummWheel = function(_, delta)
    offset = offset - (delta > 0 and 3 or -3);
    K.Draw();
  end;
  M.Panel(frame, 0, 0, WIDTH, h, M.C.bar, M.STYLES.choice.edge, 0.98);
  local x = 6;
  local widths = { 34, 48, 40, 52, 44 };
  for i, chip in ipairs(CHIPS) do
    local b = getglobal("UMMModernPickerChip"..i);
    M.Button(b, frame, x, 6, widths[i], 20, { text = getglobal(chip.text), size = 11, style = "quiet",
      click = function() source = chip.key; K.Filter(); if (target) then target:SetFocus(); end end });
    b.ummWheel = frame.ummWheel;
    x = x + widths[i] + 3;
  end
  for i = 1, ROWS do
    local row = getglobal("UMMModernPickerRow"..i);
    M.Button(row, frame, 4, 32 + (i - 1) * ROW_H, WIDTH - 8, ROW_H - 1, { style = "row",
      click = function(b) if (b.ummEntry) then K.Use(b.ummEntry.name); end end });
    row.ummName = M.Label(row, 12, M.C.text, "LEFT");
    M.Place(row.ummName, row, 6, 0, 150, ROW_H - 1);
    row.ummKind = M.Label(row, 10, M.C.dim, "RIGHT");
    M.Place(row.ummKind, row, 150, 0, WIDTH - 8 - 156, ROW_H - 1);
    row.ummWheel = frame.ummWheel;
  end
  empty = M.Label(frame, 11, M.C.dim, "LEFT");
  M.Place(empty, frame, 10, 34, WIDTH - 20, 20);
  frame:Hide();
end

-- Another box got the cursor: the list belongs to its own box only.
local previousFocus = M.OnFocus;
function M.OnFocus(box)
  if (previousFocus) then previousFocus(box); end
  if (frame and frame:IsVisible() and box ~= target) then K.Close(); end
end
