-- Cherry's Kit: the modern mail window's toolkit and frame (title bar, tabs, status line).
-- Read by Modern/Loader.lua the first time a mailbox opens the window. Skins follow rom weakauras
-- (WeakAuras' textures and colours); the icons come from rom weakauras and Cherry's Bar, copied into
-- Textures/Modern so Ultimate Mail Mod works on its own (tools/build_umm_modern_assets.py).
--
-- Frames come from Modern.xml; their handlers call UMMModern_On, which runs frame.ummOn[event]. All
-- buttons share one handler table and read what to do from fields on the button (ummClick and so
-- on), so nothing is created while the window is used. Textures and labels are made here, once.

local M = UMMModern;

local function default(name, text)
  if (_G[name] == nil) then _G[name] = text; end
end
M.Default = default;

default("UMM_M_TAB_INBOX", "Inbox");
default("UMM_M_TAB_COMPOSE", "Compose");
default("UMM_M_TAB_MASS", "Mass send");
default("UMM_M_TAB_ACTIVITY", "Activity");
default("UMM_M_ONHAND", "Gold on this character");
default("UMM_M_SETTINGS", "Settings (/umm)");
default("UMM_M_SETTINGS_TIP", "Pacing, sounds, gold presets, and the switch back to the classic mail window.");
default("UMM_M_CLOSE", "Close the mailbox");
default("UMM_M_STOP", "Stop");
default("UMM_M_STOP_TIP", "Stops after the mail that is on its way. What was not sent stays as it is.");
default("UMM_M_READY", "Ready.");
default("UMM_M_DRAG_TIP", "Drag to move the window.");
default("UMM_MODERN_FAILED", "the modern mail window could not load (%s). The classic window opens instead; /umm ui classic keeps it.");

M.W, M.H = 760, 500;
-- The window is laid out at M.W x M.H and drawn at this times the scale setting (/umm scale, 1 by
-- default): 1.2 made the first in-game build easier to read.
M.BASE_SCALE = 1.2;
M.CAP = 999999999;
local MEDIA = UMMPath.."Textures/Modern/";
local FONT = UMMPath.."Fonts/FiraSans-Medium.ttf";
M.MEDIA, M.FONT = MEDIA, FONT;

-- ### Colours (rom weakauras' skin) ###

local STYLES = {
  choice   = { edge = {0.12, 0.43, 0.53}, fill = {0.035, 0.085, 0.12}, text = {0.90, 0.95, 1.00} },
  action   = { edge = {0.70, 0.51, 0.14}, fill = {0.06, 0.06, 0.05},   text = {1.00, 0.86, 0.55} },
  save     = { edge = {0.95, 0.73, 0.20}, fill = {0.55, 0.37, 0.12},   text = {1.00, 0.97, 0.88} },
  positive = { edge = {0.12, 0.65, 0.32}, fill = {0.03, 0.11, 0.08},   text = {0.30, 1.00, 0.55} },
  danger   = { edge = {0.72, 0.27, 0.25}, fill = {0.10, 0.04, 0.05},   text = {1.00, 0.42, 0.42} },
  quiet    = { edge = {0.22, 0.31, 0.40}, fill = {0.035, 0.085, 0.12}, text = {0.72, 0.80, 0.86} },
  row      = { edge = {0.07, 0.15, 0.19}, fill = {0.025, 0.055, 0.075}, text = {0.86, 0.92, 0.96} },
};
M.STYLES = STYLES;
local HOVER_EDGE, HOVER_FILL = {0, 0.85, 0.88}, {0.06, 0.17, 0.22};
local PRESS_FILL = {0.015, 0.045, 0.07};
local SELECT_EDGE, SELECT_FILL = {0, 0.85, 0.88}, {0.04, 0.22, 0.28};

M.C = {
  bg      = {0.016, 0.04, 0.055},
  bar     = {0.03, 0.075, 0.10},
  panel   = {0.025, 0.06, 0.08},
  line    = {0.12, 0.43, 0.53},
  dim     = {0.50, 0.60, 0.66},
  text    = {0.88, 0.94, 0.98},
  head    = {0.55, 0.86, 0.95},
  gold    = {1.00, 0.83, 0.37},
  gem     = {0.56, 0.89, 1.00},
  good    = {0.30, 1.00, 0.55},
  warn    = {1.00, 0.80, 0.30},
  bad     = {1.00, 0.40, 0.40},
  own     = {1.00, 0.60, 0.46},
  friend  = {0.45, 0.82, 1.00},
  guild   = {0.45, 0.95, 0.55},
  other   = {0.96, 0.90, 0.70},
};
local C = M.C;

-- ### Making textures and labels (once, while building) ###

local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 };
local made = 0;

local function newName(kind)
  made = made + 1;
  return "UMMModern"..kind..made;
end

local function setColor(obj, rgb, alpha)
  if (obj.SetColor) then obj:SetColor(rgb[1], rgb[2], rgb[3]); else obj:SetVertexColor(rgb[1], rgb[2], rgb[3]); end
  if (alpha) then obj:SetAlpha(alpha); end
end
M.SetColor = setColor;

function M.Size(obj, w, h)
  if (w) then obj:SetWidth(w); end
  if (h) then obj:SetHeight(h); end
end

-- Places obj by its top left corner at x, y (down is +y) inside rel (a frame or its name).
function M.Place(obj, rel, x, y, w, h, point, relPoint)
  obj:ClearAllAnchors();
  obj:SetAnchor(point or "TOPLEFT", relPoint or point or "TOPLEFT", type(rel) == "string" and rel or rel:GetName(), x or 0, y or 0);
  M.Size(obj, w, h);
end

function M.Texture(parent, layer, file, rgb, alpha)
  local t = CreateUIComponent("Texture", newName("T"), parent:GetName());
  parent:SetLayers(LAYERS[layer] or 3, t);
  t:SetTexture(MEDIA..(file or "white")..".tga");
  if (rgb) then setColor(t, rgb, alpha); end
  return t;
end

-- A texture from anywhere (item icons): path as the game gives it.
function M.Icon(parent, layer, size)
  local t = CreateUIComponent("Texture", newName("I"), parent:GetName());
  parent:SetLayers(LAYERS[layer] or 3, t);
  M.Size(t, size, size);
  return t;
end

local function justify(fs, how)
  if (fs.SetJustifyHType) then fs:SetJustifyHType(how); elseif (fs.SetJustifyH) then fs:SetJustifyH(how); end
end
M.Justify = justify;

function M.Font(fs, size)
  fs:SetFont(FONT, size or 12, "NORMAL", "NORMAL");
end

-- A label: size 0 width leaves it unsized (its text decides the width).
function M.Label(parent, size, rgb, how, layer)
  local fs = CreateUIComponent("FontString", newName("F"), parent:GetName());
  parent:SetLayers(LAYERS[layer or "OVERLAY"], fs);
  M.Font(fs, size);
  setColor(fs, rgb or C.text);
  justify(fs, how or "LEFT");
  return fs;
end

-- Text with a colour, for labels that change colour with their text.
function M.SetText(fs, text, rgb)
  fs:SetText(text or "");
  if (rgb) then setColor(fs, rgb); end
end

-- A flat panel: fill and four 1 px edges in parent's background layers, placed at x, y.
function M.Panel(parent, x, y, w, h, fill, edge, alpha)
  local p = { fill = M.Texture(parent, "BACKGROUND", "white", fill or C.panel, alpha or 1) };
  M.Place(p.fill, parent, x, y, w, h);
  if (edge ~= false) then
    local rgb = edge or STYLES.quiet.edge;
    p.top = M.Texture(parent, "BORDER", "white", rgb); M.Place(p.top, parent, x, y, w, 1);
    p.bottom = M.Texture(parent, "BORDER", "white", rgb); M.Place(p.bottom, parent, x, y + h - 1, w, 1);
    p.left = M.Texture(parent, "BORDER", "white", rgb); M.Place(p.left, parent, x, y, 1, h);
    p.right = M.Texture(parent, "BORDER", "white", rgb); M.Place(p.right, parent, x + w - 1, y, 1, h);
  end
  return p;
end

-- A thin line (separator or accent).
function M.Line(parent, x, y, w, h, rgb, alpha)
  local t = M.Texture(parent, "BORDER", "white", rgb or C.line, alpha or 0.6);
  M.Place(t, parent, x, y, w, h);
  return t;
end

-- ### Formatting ###

function M.Gold(n)
  return UMMFormatNumber(n or 0);
end

-- Gold the character carries (the game's GetPlayerMoney("copper")).
function M.OnHand()
  local value = GetPlayerMoney and GetPlayerMoney("copper");
  return tonumber(value) or 0;
end

-- Name colour by who it is: own character, friend, guild member, anyone else.
function M.WhoColor(name)
  local kind = UMMFriends:GetFriendType(name or "");
  if (kind == "Character") then return C.own, kind; end
  if (kind == "Friend") then return C.friend, kind; end
  if (kind == "Guildie") then return C.guild, kind; end
  return C.other, kind;
end

-- "3d", "20h": the time a mail has left, and its colour.
function M.Days(days)
  days = tonumber(days) or 0;
  if (days < 1) then
    return string.format("%dh", math.max(1, math.floor(days * 24))), C.bad;
  end
  local whole = math.floor(days) + 1;
  if (whole <= 1) then return "1d", C.bad; end
  if (whole <= 3) then return whole.."d", C.warn; end
  return whole.."d", C.dim;
end

-- ### Buttons: one handler table for all of them ###

local function mask(w, h)
  if (h > 48) then return "white"; end
  local mw = (w <= 40 and 32) or (w <= 80 and 64) or (w <= 160 and 128) or 256;
  return "round-"..mw.."-32";
end

function M.Paint(b)
  local s = b.umm;
  if (not s) then return; end
  local style = STYLES[s.style] or STYLES.choice;
  local edge, fill = style.edge, style.fill;
  if (s.selected) then
    edge, fill = SELECT_EDGE, SELECT_FILL;
  end
  if (s.hover and s.enabled and s.style ~= "row") then edge = HOVER_EDGE; end
  if (s.hover and s.enabled and not s.selected and s.style ~= "save") then fill = HOVER_FILL; end
  if (s.pressed and s.enabled) then fill = PRESS_FILL; end
  local alpha = s.enabled and 1 or 0.45;
  if (s.style == "row" and not s.selected and not s.hover) then
    setColor(s.edge, edge, s.rowAlpha or 0.0);
  else
    setColor(s.edge, edge, alpha);
  end
  setColor(s.fill, fill, s.style == "row" and (s.selected and 0.95 or (s.hover and 0.85 or 0.0)) or alpha);
  if (s.label) then setColor(s.label, s.textColor or style.text, alpha); end
  if (s.icon) then s.icon:SetAlpha(alpha); end
end

local function tooltip(b)
  local tip = b.ummTip;
  if (type(tip) == "function") then tip = tip(b); end
  if (not tip or not GameTooltip) then return; end
  GameTooltip:SetOwner(b, "ANCHOR_BOTTOMRIGHT", 0, 0);
  GameTooltip:SetText(tip[1]);
  for i = 2, table.getn(tip) do GameTooltip:AddLine(tip[i], 1, 1, 1); end
  GameTooltip:Show();
  M.tipOwner = b;
end
M.Tooltip = tooltip;

function M.HideTip(b)
  if (M.tipOwner == b or b == nil) then
    M.tipOwner = nil;
    if (GameTooltip) then GameTooltip:Hide(); end
  end
end

M.BUTTON = {
  enter = function(b)
    if (b.umm) then b.umm.hover = true; M.Paint(b); end
    if (b.ummEnter) then b.ummEnter(b); elseif (b.ummTip) then tooltip(b); end
  end,
  leave = function(b)
    if (b.umm) then b.umm.hover = false; b.umm.pressed = false; M.Paint(b); end
    if (b.ummLeave) then b.ummLeave(b); end
    M.HideTip(b);
  end,
  down = function(b, key)
    if (b.umm) then b.umm.pressed = true; M.Paint(b); end
    if (b.ummDown) then b.ummDown(b, key); end
  end,
  up = function(b, key)
    if (b.umm) then b.umm.pressed = false; M.Paint(b); end
    if (b.ummUp) then b.ummUp(b, key); end
  end,
  click = function(b, key)
    if (b.umm and not b.umm.enabled) then return; end
    if (b.ummClick) then b.ummClick(b, key); end
  end,
  wheel = function(b, delta)
    if (b.ummWheel) then b.ummWheel(b, tonumber(delta) or 0); end
  end,
  drop = function(b)
    if (b.ummDrop) then b.ummDrop(b); end
  end,
};

-- Skins a button from Modern.xml and places it. opts: style, text, icon, iconSize, justify, tip,
-- click, size (label), selected.
function M.Button(b, parent, x, y, w, h, opts)
  opts = opts or {};
  M.Place(b, parent, x, y, w, h);
  local s = b.umm;
  if (not s) then
    s = { enabled = true };
    b.umm = s;
    s.edge = M.Texture(b, "BACKGROUND", mask(w, h));
    s.fill = M.Texture(b, "BORDER", mask(w, h));
    M.Place(s.edge, b, 0, 0, w, h);
    M.Place(s.fill, b, 1, 1, w - 2, h - 2);
  end
  s.style = opts.style or "choice";
  s.selected = opts.selected and true or false;
  local left = 6;
  if (opts.icon) then
    local size = opts.iconSize or math.min(18, h - 6);
    s.icon = s.icon or M.Texture(b, "ARTWORK", opts.icon);
    s.icon:SetTexture(MEDIA..opts.icon..".tga");
    local ix = (opts.text and opts.text ~= "") and 6 or math.floor((w - size) / 2);
    M.Place(s.icon, b, ix, math.floor((h - size) / 2), size, size);
    left = ix + size + 5;
  end
  if (opts.text) then
    s.label = s.label or M.Label(b, opts.size or 12, nil, opts.justify or (opts.icon and "LEFT" or "CENTER"));
    local how = opts.justify or (opts.icon and "LEFT" or "CENTER");
    justify(s.label, how);
    if (how == "CENTER" and not opts.icon) then
      M.Place(s.label, b, 2, 0, w - 4, h);
    else
      M.Place(s.label, b, left, 0, w - left - 4, h);
    end
    s.label:SetText(opts.text);
  end
  b.ummOn = M.BUTTON;
  b.ummClick = opts.click or b.ummClick;
  b.ummTip = opts.tip or b.ummTip;
  b:Show();
  M.Paint(b);
  return b;
end

function M.ButtonText(b, text, rgb)
  local s = b.umm;
  if (s and s.label) then
    s.label:SetText(text or "");
    s.textColor = rgb;
    M.Paint(b);
  end
end

function M.ButtonIcon(b, icon)
  local s = b.umm;
  if (s and s.icon) then s.icon:SetTexture(MEDIA..icon..".tga"); end
end

function M.Enable(b, on)
  on = on and true or false;
  local s = b.umm;
  if (s and s.enabled == on) then return; end
  if (on) then b:Enable(); else b:Disable(); end
  if (s) then s.enabled = on; s.pressed = false; M.Paint(b); end
end

function M.Select(b, on)
  local s = b.umm;
  on = on and true or false;
  if (s and s.selected ~= on) then s.selected = on; M.Paint(b); end
end

-- A frame that only takes the mouse (lists, the title bar): handlers by field, like buttons.
function M.Hit(f, parent, x, y, w, h)
  if (parent) then M.Place(f, parent, x, y, w, h); end
  f.ummOn = M.BUTTON;
  f:Show();
  return f;
end

-- ### Edit boxes ###

local pendingGold = {};

local function regroupGold()
  for box in pairs(pendingGold) do
    pendingGold[box] = nil;
    local text = box:GetText() or "";
    if (text ~= box.ummShown) then
      local grouped, caret = UMMSettingsUI_RegroupGold(box.ummShown or "", text);
      box.ummShown = grouped;
      if (grouped ~= text) then
        box.ummQuiet = true;
        box:SetText(grouped);
        box.ummQuiet = false;
        box:HighlightText(caret, caret);   -- caret without a selection
      end
    end
    if (box.ummAfter) then box.ummAfter(box); end
  end
end

-- ### Ctrl+Backspace ###
-- The client has none of its own. With Ctrl held, Windows turns Backspace into a DEL character:
-- a text box types it where the caret is (after deleting a selection), a number box drops it.
-- OnKeyDown says the keys were pressed; the work waits a frame, as the client places the caret
-- only after the text handler. The caret counts UTF-16 units, Lua strings count UTF-8 bytes.

local DEL = "\127";
local pendingBack = {};

-- bytes of the character starting with byte b, and the UTF-16 units it takes
local function charSize(b)
  if (b >= 240) then return 4, 2; end
  if (b >= 224) then return 3, 1; end
  if (b >= 192) then return 2, 1; end
  return 1, 1;
end

-- Bytes in text before caret position `units`.
function M.TextBytes(text, units)
  local pos, n, len = 1, 0, string.len(text);
  while (pos <= len and n < units) do
    local size, u = charSize(string.byte(text, pos));
    pos = pos + size;
    n = n + u;
  end
  return math.min(pos - 1, len);
end

-- Caret position (UTF-16 units) after the first `bytes` bytes of text.
function M.TextUnits(text, bytes)
  local pos, n, stop = 1, 0, math.min(bytes, string.len(text));
  while (pos <= stop) do
    local size, u = charSize(string.byte(text, pos));
    pos = pos + size;
    n = n + u;
  end
  return n;
end

-- What Ctrl+Backspace leaves of text with the caret after `caret` bytes: "name" empties the box,
-- "gold" takes the digits back to the comma before them (the comma too), "text" a line break
-- alone or the word before the caret and the spaces after it. Returns the text and the caret.
function M.CtrlBack(kind, text, caret)
  text = text or "";
  local len = string.len(text);
  if (not caret or caret > len) then caret = len; end
  if (kind == "name") then return "", 0; end
  if (caret <= 0) then return text, 0; end
  local head, tail = string.sub(text, 1, caret), string.sub(text, caret + 1);
  if (kind == "gold") then
    head = string.gsub(head, "%D+$", "");
    head = string.gsub(head, "%d+$", "");
    local digits = string.gsub(head, "%D", "");
    local keep = string.len(digits);
    digits = digits..(string.gsub(tail, "%D", ""));
    local _, zeros = string.find(digits, "^0*");
    digits = string.sub(digits, zeros + 1);
    keep = math.max(keep - zeros, 0);
    local grouped, at = UMMGroupDigits(digits), 0;
    while (keep > 0 and at < string.len(grouped)) do
      at = at + 1;
      if (string.sub(grouped, at, at) ~= ",") then keep = keep - 1; end
    end
    return grouped, at;
  end
  if (string.sub(head, -1) == "\n") then
    head = string.sub(head, 1, -2);
  else
    head = string.gsub(head, "[ \t]+$", "");
    head = string.gsub(head, "[^%s]+$", "");
  end
  return head..tail, string.len(head);
end

local function setBack(e, text, caret)
  e.ummQuiet = true;
  e:SetText(text);
  e.ummQuiet = false;
  if (e.ummGold) then e.ummShown = text; end
  local units = M.TextUnits(text, caret);
  e:HighlightText(units, units);
  e.ummCaret, e.ummAll = units, nil;
  M.Hint(e);
  if (e.ummGold) then
    if (e.ummAfter) then e.ummAfter(e); end
  elseif (e.ummText) then
    e.ummText(e);
  end
end

local function backLater()
  for e in pairs(pendingBack) do
    local state = e.ummBack;
    local text = e:GetText() or "";
    local at = string.find(text, DEL, 1, true);
    if (at) then
      pendingBack[e], e.ummBack = nil, nil;
      local clean, n = string.gsub(text, DEL, "");
      local caret = at - 1;
      if (state == "selection") then n = n - 1; end   -- that press took the selection out
      for i = 1, n do clean, caret = M.CtrlBack(e.ummKind, clean, caret); end
      setBack(e, clean, caret);
    elseif (state == "key" and e.ummWait > 1) then
      -- a text box's DEL may come a frame late: wait for it rather than take the word twice
      e.ummWait = e.ummWait - 1;
      M.Later(backLater);
    else
      pendingBack[e], e.ummBack = nil, nil;
      if (state == "key" and not e.ummMulti) then
        -- nothing typed: a number box, or a full one
        if (e.ummAll) then
          setBack(e, "", 0);
        else
          local caret = e.ummCaret and M.TextBytes(text, e.ummCaret) or string.len(text);
          setBack(e, M.CtrlBack(e.ummKind, text, caret));
        end
      end
    end
  end
end

-- Selects the whole text; Ctrl+Backspace then empties the box, even a number box.
function M.SelectAll(e)
  e:HighlightText();
  e.ummAll = true;
end

-- ### Ctrl+A and Ctrl+V ###
-- The client's own text box does Ctrl+C, Ctrl+X, Ctrl+V and Shift+Insert (uieditbox.cpp: the keys
-- arrive as characters 3, 24 and 22), so those are left alone. It has no Ctrl+A: that one selects the
-- whole text here, which Ctrl+C and Ctrl+X then take. A one-line box pastes up to the first line
-- break or tab of the clipboard text, so a clipboard that starts with one pastes nothing, and a
-- locked or empty clipboard pastes nothing in any box. The paste is checked a few frames after the
-- key and says so in the status line when the box did not change.

M.Default("UMM_M_PASTE_NONE", "Ctrl+V pasted nothing: the clipboard holds no text, or its text starts with a line break.");

local PASTE_FRAMES = 3;
local pendingPaste = {};

local function pasteLater()
  local waiting = false;
  for e, left in pairs(pendingPaste) do
    local seen = e.ummPasted;
    if ((e:GetText() or "") ~= seen) then
      pendingPaste[e], e.ummPasted = nil, nil;
    elseif (left > 1) then
      pendingPaste[e] = left - 1;
      waiting = true;
    else
      pendingPaste[e], e.ummPasted = nil, nil;
      if (M.focus == e) then M.Status(UMM_M_PASTE_NONE, C.warn); end
    end
  end
  if (waiting) then M.Later(pasteLater); end
end

local function watchPaste(e)
  e.ummPasted = e:GetText() or "";
  pendingPaste[e] = PASTE_FRAMES;
  M.Later(pasteLater);
end

M.EDIT = {
  text = function(e)
    if (e.ummQuiet) then return; end
    if (string.find(e:GetText() or "", DEL, 1, true)) then
      if (not e.ummBack) then e.ummBack, e.ummWait = "key", 1; end
      pendingBack[e] = true;
      M.Later(backLater);
      return;
    end
    -- Ctrl+Backspace over a selection: the client takes the selection out, then types the DEL
    if (e.ummBack == "key") then e.ummBack = "selection"; end
    M.Hint(e);
    if (e.ummGold) then
      -- the client moves the caret after this handler: the commas go back in next frame
      pendingGold[e] = true;
      M.Later(regroupGold);
      return;
    end
    if (e.ummText) then e.ummText(e); end
  end,
  enterkey = function(e)
    if (e.ummEnterKey) then e.ummEnterKey(e); else e:ClearFocus(); end
  end,
  esc = function(e)
    if (e.ummEsc) then e.ummEsc(e); end
    e:ClearFocus();
  end,
  tab = function(e)
    local nextBox = e.ummNext;
    if (type(nextBox) == "function") then nextBox = nextBox(e); end
    e:ClearFocus();
    if (nextBox) then nextBox:SetFocus(); end
  end,
  focus = function(e)
    M.focus = e;
    if (M.OnFocus) then M.OnFocus(e); end
    if (e.ummFocus) then e.ummFocus(e); end
  end,
  unfocus = function(e)
    if (M.focus == e) then M.focus = nil; end
    if (e.ummUnfocus) then e.ummUnfocus(e); end
  end,
  enter = function(e)
    if (e.ummTip) then tooltip(e); end
  end,
  leave = function(e)
    M.HideTip(e);
  end,
  keydown = function(e, key)
    if ((key ~= "BACKSPACE" and key ~= "A" and key ~= "V") or not M.Held(IsCtrlKeyDown)) then return; end
    if (key == "A") then M.SelectAll(e); return; end
    if (key == "V") then watchPaste(e); return; end
    e.ummBack = "key";
    e.ummWait = e.ummGold and 1 or 3;
    pendingBack[e] = true;
    M.Later(backLater);
  end,
  cursor = function(e, caret)
    -- one-line boxes only (Modern.xml): the caret, in UTF-16 units
    e.ummCaret = tonumber(caret);
    e.ummAll = nil;
  end,
};

-- Places an edit box from Modern.xml. A hint shows in grey while it is empty.
function M.Edit(e, parent, x, y, w, h, opts)
  opts = opts or {};
  M.Place(e, parent, x, y, w, h);
  e.ummOn = M.EDIT;
  e.ummText = opts.text;
  e.ummTip = opts.tip;
  e.ummNext = opts.nextBox;
  -- what Ctrl+Backspace takes (M.CtrlBack); a multi-line box gives no caret to go by (Modern.xml)
  e.ummKind = opts.gold and "gold" or opts.name and "name" or "text";
  e.ummMulti = (opts.panel or opts.multi) and true or nil;
  if (opts.gold) then
    e.ummGold = true;
    e.ummShown = "";
    e.ummAfter = opts.text;
    e.ummText = nil;
  end
  if (opts.panel) then
    -- a multi-line box draws nothing of its own (Modern.xml): a flat background to type on
    local p = e.ummPanel;
    if (not p) then
      e.ummPanel = M.Panel(e, 0, 0, w, h, C.panel, STYLES.quiet.edge, 1);
    else
      M.Place(p.fill, e, 0, 0, w, h);
      M.Place(p.top, e, 0, 0, w, 1); M.Place(p.bottom, e, 0, h - 1, w, 1);
      M.Place(p.left, e, 0, 0, 1, h); M.Place(p.right, e, w - 1, 0, 1, h);
    end
  end
  if (opts.hint) then
    -- on the box itself: the box's own background would cover a label of the page
    e.ummHint = e.ummHint or M.Label(e, 12, C.dim, "LEFT", "OVERLAY");
    M.Place(e.ummHint, e, 8, 0, w - 16, h);
    e.ummHintText = opts.hint;
    e.ummHint:SetText(opts.hint);
  end
  e:Show();
  return e;
end

-- Hides the hint while the box has text (call from the box's text handler).
function M.Hint(e, text)
  if (not e.ummHint) then return; end
  if (text) then e.ummHintText = text; end
  local empty = (e:GetText() or "") == "";
  e.ummHint:SetText(empty and (e.ummHintText or "") or "");
end

function M.SetEditText(e, text)
  text = text or "";
  e.ummQuiet = true;
  e:SetText(text);
  e.ummQuiet = false;
  if (e.ummGold) then e.ummShown = text; end
  -- SetText puts the caret at the start; while typing there, it goes to the end
  e.ummCaret, e.ummAll = 0, nil;
  if (M.focus == e and text ~= "") then
    local units = M.TextUnits(text, string.len(text));
    e:HighlightText(units, units);
    e.ummCaret = units;
  end
  M.Hint(e);
end

-- A gold box's amount, or nil when empty or not a whole amount from 1 to 999,999,999.
function M.GoldOf(e)
  return UMMGoldAmount(e:GetText() or "");
end

function M.SetGold(e, amount)
  M.SetEditText(e, amount and amount > 0 and M.Gold(amount) or "");
end

-- ### Next frame and dragging ###

local later, laterSpare = {}, {};

function M.Later(fn)
  for i = 1, table.getn(later) do
    if (later[i] == fn) then return; end
  end
  table.insert(later, fn);
  UMMModernLater:Show();
end

local function runLater(f)
  f:Hide();
  local run = later;
  later, laterSpare = laterSpare, run;
  for i = 1, table.getn(run) do
    local fn = run[i];
    run[i] = nil;
    fn();
  end
end

local drag = nil;

-- update(elapsed) runs every frame until M.StopDrag; finish(cancelled) once at the end.
function M.StartDrag(update, finish)
  if (drag and drag.finish) then drag.finish(true); end
  drag = { update = update, finish = finish };
  UMMModernMover:Show();
end

function M.StopDrag(cancelled)
  local d = drag;
  drag = nil;
  UMMModernMover:Hide();
  if (d and d.finish) then d.finish(cancelled and true or false); end
end

function M.Dragging()
  return drag ~= nil;
end

-- Cursor in UI units (the game gives screen pixels).
function M.Cursor()
  if (not GetCursorPos) then return nil; end
  local x, y = GetCursorPos();
  local scale = (GetUIScale and GetUIScale()) or 1;
  if (not scale or scale <= 0) then scale = 1; end
  return x / scale, y / scale;
end

-- The cursor inside frame in the frame's own units (x from its left edge, y from its top), and the
-- frame's width and height. The game gives the cursor and frame positions in screen pixels; the
-- frame's real size against its width covers every UI scale on the way (like Mass Send's boxes).
function M.LocalCursor(frame)
  if (not GetCursorPos or not frame.GetPos or not frame.GetRealSize) then return nil; end
  local cx, cy = GetCursorPos();
  local fx, fy = frame:GetPos();
  local rw, rh = frame:GetRealSize();
  local w, h = frame:GetWidth(), frame:GetHeight();
  if (not cx or not cy or not fx or not fy or not rw or not rh or rw <= 0 or rh <= 0 or not w or not h or w <= 0 or h <= 0) then
    return nil;
  end
  return (cx - fx) * w / rw, (cy - fy) * h / rh, w, h;
end

-- A key or modifier held now (IsCtrlKeyDown and friends may be missing or return 1/nil).
function M.Held(fn)
  if (type(fn) ~= "function") then return false; end
  local value = fn();
  return value ~= nil and value ~= false and value ~= 0;
end

-- ### The window ###

M.pages = {};
M.order = { "inbox", "compose", "mass", "activity" };
local TAB_ICONS = { inbox = "inbox", compose = "compose", mass = "mass", activity = "activity" };
local TAB_TEXT = { inbox = "UMM_M_TAB_INBOX", compose = "UMM_M_TAB_COMPOSE", mass = "UMM_M_TAB_MASS", activity = "UMM_M_TAB_ACTIVITY" };
local TAB_X, TAB_W, TAB_STEP = 8, 114, 118;

local function savedPos()
  local pos = UMMSettings:Get("ModernPos");
  if (type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number") then return pos.x, pos.y; end
end

-- The window's scale: the setting times M.BASE_SCALE.
function M.Scale()
  return M.BASE_SCALE * ((UMMWindowScale and UMMWindowScale()) or 1);
end

-- Puts the window's top left corner at x, y of the screen (UI units; nil: where it was saved, else
-- centred near the top), at the scale of the setting, keeping the title bar on the screen. The
-- client multiplies a frame's anchor offset by the frame's own scale, so the offset is x / scale.
function M.PlaceWindow(x, y)
  local frame = UMMModernFrame;
  local scale = M.Scale();
  local uiW, uiH = UIParent:GetWidth() or 1024, UIParent:GetHeight() or 768;
  local w, h = M.W * scale, M.H * scale;
  if (not x) then x, y = savedPos(); end
  if (not x) then x, y = math.floor((uiW - w) / 2), math.min(90, math.floor((uiH - h) / 2)); end
  x = math.max(0, math.min(x, uiW - w));
  y = math.max(0, math.min(y, uiH - 40 * scale));
  M.x, M.y = x, y;
  if (frame:GetScale() ~= scale) then frame:SetScale(scale); end
  frame:ClearAllAnchors();
  frame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x / scale, y / scale);
end

-- The scale setting changed: the window keeps its top left corner.
function M.ApplyScale()
  if (UMMModernFrame:IsVisible()) then
    M.PlaceWindow(M.x, M.y);
    M.HideTip();
  end
end

local function titleDown(f, key)
  if (key and key ~= "LBUTTON" and key ~= "LeftButton") then return; end
  local cx, cy = M.Cursor();
  if (not cx) then return; end
  local startX, startY, wx, wy = cx, cy, M.x or 0, M.y or 0;
  M.StartDrag(function()
    local x, y = M.Cursor();
    if (x) then M.PlaceWindow(wx + x - startX, wy + y - startY); end
  end, function(cancelled)
    if (not cancelled) then UMMSettings:Set("ModernPos", { x = M.x, y = M.y }); end
  end);
end

local function titleUp()
  if (M.Dragging()) then M.StopDrag(); end
end

function M.Status(text, rgb)
  M.status:SetText(text or "");
  setColor(M.status, rgb or C.dim);
end

-- done of total as a bar in the status line; total 0 hides it.
function M.Progress(done, total)
  local bar = M.progress;
  if (not total or total <= 0) then
    bar.back:Hide(); bar.fill:Hide();
    return;
  end
  bar.back:Show(); bar.fill:Show();
  local w = math.max(1, math.floor(bar.width * math.min(1, done / total)));
  bar.fill:SetWidth(w);
end

function M.Busy()
  return (UMMQueue and UMMQueue:Busy()) or UMMMailManager:IsAutomating() or UMMMailComposer:Busy();
end

-- Stop is shown while mail goes out or the inbox is being taken from.
function M.RefreshStop()
  local busy = (UMMQueue and UMMQueue:Busy()) or UMMMailManager:IsAutomating();
  if (busy) then UMMModernStop:Show(); else UMMModernStop:Hide(); end
end

function M.ShowPage(name)
  if (not M.pages[name]) then name = "inbox"; end
  if (M.Picker) then M.Picker.Close(); end
  -- typing must not go on into a box of a page that is no longer shown
  if (M.focus and M.page ~= name) then M.focus:ClearFocus(); end
  M.page = name;
  for i, key in ipairs(M.order) do
    local page = M.pages[key];
    M.Select(getglobal("UMMModernTab"..i), key == name);
    if (key ~= name and page.frame:IsVisible()) then
      page.frame:Hide();
      if (page.Hide) then page.Hide(); end
    end
  end
  local page = M.pages[name];
  page.frame:Show();
  if (page.Show) then page.Show(); end
end

function M.TabText(name, text)
  for i, key in ipairs(M.order) do
    if (key == name) then M.ButtonText(getglobal("UMMModernTab"..i), text); end
  end
end

function M.MoneyChanged()
  if (not M.gold) then return; end
  M.gold:SetText(M.Gold(M.OnHand()));
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.MoneyChanged) then page.MoneyChanged(); end
  end
end

local function buildFrame()
  local f = UMMModernFrame;
  M.Size(f, M.W, M.H);
  f.ummOn = { show = function() M.Shown(); end, hide = function() M.Hidden(); end };
  -- body, title bar, status line (opaque: name plates in the world must not show through)
  M.Panel(f, 0, 0, M.W, M.H, C.bg, STYLES.quiet.edge, 1);
  M.Panel(f, 1, 1, M.W - 2, 36, C.bar, false);
  M.Line(f, 1, 37, M.W - 2, 1, C.line, 0.8);
  M.Panel(f, 1, M.H - 27, M.W - 2, 26, C.bar, false);
  M.Line(f, 1, M.H - 28, M.W - 2, 1, C.line, 0.5);

  M.Hit(UMMModernTitle, f, 0, 0, M.W - 64, 37);
  UMMModernTitle.ummDown = titleDown;
  UMMModernTitle.ummUp = titleUp;
  UMMModernMover.ummOn = { update = function(mover, elapsed)
    if (drag) then drag.update(elapsed); else mover:Hide(); end
  end };
  UMMModernLater.ummOn = { update = runLater };

  -- the tabs from the left edge, then the gold on hand; the drag area is what the bar has left
  for i, key in ipairs(M.order) do
    M.Button(getglobal("UMMModernTab"..i), f, TAB_X + (i - 1) * TAB_STEP, 6, TAB_W, 26, {
      text = getglobal(TAB_TEXT[key]), icon = TAB_ICONS[key], iconSize = 16, size = 13,
      click = function() M.ShowPage(key); end,
    });
  end

  local goldX = TAB_X + table.getn(M.order) * TAB_STEP + 10;
  local coin = M.Texture(f, "ARTWORK", "Gold");
  M.Place(coin, f, goldX, 10, 18, 18);
  M.gold = M.Label(f, 13, C.gold, "LEFT");
  M.Place(M.gold, f, goldX + 22, 2, 120, 34);
  UMMModernTitle.ummTip = { UMM_M_ONHAND, UMM_M_DRAG_TIP };

  M.Button(UMMModernGear, f, M.W - 60, 8, 24, 22, { icon = "gear", iconSize = 16, style = "quiet",
    tip = { UMM_M_SETTINGS, UMM_M_SETTINGS_TIP }, click = function() UMMSettingsUI_Toggle(); end });
  M.Button(UMMModernClose, f, M.W - 32, 8, 24, 22, { icon = "Close", iconSize = 14, style = "danger",
    tip = { UMM_M_CLOSE }, click = function() UMMModernFrame:Hide(); end });

  M.status = M.Label(f, 12, C.dim, "LEFT");
  M.Place(M.status, f, 12, M.H - 26, 520, 24);
  M.progress = { width = 120 };
  M.progress.back = M.Texture(f, "ARTWORK", "white", C.panel, 1);
  M.Place(M.progress.back, f, 540, M.H - 17, 120, 6);
  M.progress.fill = M.Texture(f, "OVERLAY", "white", C.good, 0.9);
  M.Place(M.progress.fill, f, 540, M.H - 17, 1, 6);
  M.Progress(0, 0);
  M.Button(UMMModernStop, f, M.W - 86, M.H - 24, 76, 20, { text = UMM_M_STOP, style = "danger", icon = "Close",
    iconSize = 12, size = 12, tip = { UMM_M_STOP, UMM_M_STOP_TIP }, click = function() M.StopAll(); end });
  UMMModernStop:Hide();
end

-- The content area of every page: below the title bar, above the status line.
M.TOP, M.BOTTOM = 44, M.H - 32;

function M.Build()
  buildFrame();
  for i, key in ipairs(M.order) do
    local page = M.pages[key];
    page.frame:ClearAllAnchors();
    page.frame:SetAnchor("TOPLEFT", "TOPLEFT", "UMMModernFrame", 0, M.TOP);
    M.Size(page.frame, M.W, M.BOTTOM - M.TOP);
    page.frame:Hide();
    page.Build();
  end
  if (M.Picker) then M.Picker.Build(); end
end

function M.Open()
  UMMMailView = M.View;
  M.PlaceWindow();
  UMMModernFrame:Show();
  return true;
end

function M.StopAll()
  if (UMMQueue and UMMQueue:Busy()) then
    UMMQueue:Stop();
  elseif (UMMMailManager:IsAutomating()) then
    UMMMailManager:StopAutomation(true);
    M.Status(UMM_M_READY);
  end
  M.RefreshStop();
end

-- The window opened (MAIL_SHOW): like the classic window, the game's own mail frame moves off
-- screen and stays open underneath, because closing it ends the mailbox.
function M.Shown()
  UMMFriends:Load();
  UMMBagManager:Load();
  UMMMailManager:ShowInbox();
  UMMGlobalInboxLoadTimeout = 2.3;
  MailFrame:ClearAllAnchors();
  MailFrame:SetAnchor("TOPRIGHT", "TOPLEFT", "UIParent", 0, 110);
  M.Status(UMM_INBOX_LOADING, C.dim);
  M.MoneyChanged();
  M.RefreshStop();
  M.ShowPage(M.page or "inbox");
end

function M.Hidden()
  if (M.Dragging()) then M.StopDrag(true); end
  if (M.Picker) then M.Picker.Close(); end
  M.HideTip();
  -- mailbox closed in the middle of a mail: stop and hand the item back
  if (UMMQueue and UMMQueue:Busy()) then UMMQueue:Stop("mailbox closed"); end
  if (UMMMailComposer:Busy()) then UMMMailComposer:Finish("failed", "mailbox closed"); end
  HideUIPanel(MailFrame);
  UMMMailManager:StopAutomation();
  UMMMailManager:Clear();
  UMMFriends:Clear();
  MailFrame:ClearAllAnchors();
  MailFrame:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", 0, 110);
  if (M.focus) then M.focus:ClearFocus(); end
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.Closed) then page.Closed(); end
  end
end

-- ### Called by UltimateMailMod.lua ###

function M.InboxUpdated()
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.InboxUpdated) then page.InboxUpdated(); end
  end
end

function M.BagsChanged()
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.BagsChanged) then page.BagsChanged(); end
  end
end

function M.HistoryChanged()
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.HistoryChanged) then page.HistoryChanged(); end
  end
end

-- The "Mail shortcuts" setting or a gold preset changed (UMMRefreshMailShortcuts).
function M.ShortcutsChanged()
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.ShortcutsChanged) then page.ShortcutsChanged(); end
  end
end

-- A name clicked in chat (Ctrl or Shift): Mass send's To on that page, else Compose's To.
function M.UseName(name)
  if (M.Busy()) then UMMPrompt(UMM_ERROR_STILLSENDING); return true; end
  if (M.page == "mass") then return M.pages.mass.UseName(name); end
  if (M.page ~= "compose") then M.ShowPage("compose"); end
  return M.pages.compose.UseName(name);
end

-- Every frame while the window is open (the master frame's update): pages get it 4 times a second.
local tickTime = 0;
function M.Tick(elapsed)
  tickTime = tickTime + elapsed;
  if (tickTime < 0.25) then return; end
  local dt = tickTime;
  tickTime = 0;
  for _, key in ipairs(M.order) do
    local page = M.pages[key];
    if (page.Tick) then page.Tick(dt); end
  end
end
