-- Cherry's chat: draws the game's chat windows itself, so lines can be painted with the mouse and
-- copied, and emoji show as symbols.
--
-- Nothing to set up. Every game chat window (General, Combat, Party, Guild ... and any window you
-- add or undock) gets an overlay at exactly its place and size. The game keeps its tabs, typing
-- box, background, moving and resizing; it just no longer draws the text, the overlay does:
--   * left click works like the game's chat (item links, names), passed on to the game
--   * left drag paints lines blue; right-click opens a menu: Copy to clipboard, Whisper <sender>
--   * mouse wheel scrolls
-- If anything in here fails, Cherry's Chat hands the text back to the game's chat.
-- Positions use what /cchat lab measured in game: GetCursorPos and GetLeft/GetTop are screen
-- pixels (+y down), sizes are UI units, and screen = UI * GetUIScale().

local C = CherrysChat
local Wn = {}
C.Win = Wn

Wn.WINDOWS = 10 -- one overlay per game chat frame
Wn.MAX_LINES = 40 -- lines per overlay
Wn.PAD = 4
-- The game keeps two buttons (search, scroll to bottom) on the left edge of its chat, on top of
-- our text (in game, 2026-10-26), so lines start right of them.
Wn.PAD_LEFT = 28
Wn.LINE_H = 17 -- the XML font is 14
Wn.PIC = 15 -- emoji picture size
Wn.MAX_PICS = 60 -- pictures per window (XML CherrysChat_W<i>Pic<k>)
Wn.FOLLOW_EVERY = 0.2

local try, has = C.Try, C.Has

local function cfg()
  local d = C.DB()
  if type(d.win) ~= "table" then
    d.win = {}
  end
  local w = d.win
  -- 0.5.0 was on, 0.6.0 off (the game's older lines showed under ours). 0.7.0 pushes those lines
  -- out of the game's frames, so it is on again: the user wants this chat, with no setup.
  if (w.defaults or 0) < 4 then
    w.defaults, w.on = 4, true
  end
  return w
end
Wn.Config = cfg

local function scale()
  local s = GetUIScale and GetUIScale()
  return (type(s) == "number" and s > 0) and s or 1
end

local function overlay(i)
  return _G["CherrysChat_W" .. i]
end
local function line(i, k)
  return _G["CherrysChat_W" .. i .. "Line" .. k]
end
local function hi(i, k)
  return _G["CherrysChat_W" .. i .. "Hi" .. k]
end

-- state[i] = { offset, w, h, selA, selB }
Wn.state = {}
local function st(i)
  Wn.state[i] = Wn.state[i] or { offset = 0 }
  return Wn.state[i]
end

---------------------------------------------------------------------------
-- Safety: an error turns the overlays off and gives the text back to the game's chat.
---------------------------------------------------------------------------

Wn.broken = false

local function guarded(fn, ...)
  if Wn.broken then
    return
  end
  local ok, err = pcall(fn, ...)
  if not ok then
    Wn.broken = true
    Wn.lastError = tostring(err)
    C.DB().winError = Wn.lastError
    pcall(Wn.HideAll)
    C.Print("the chat overlay hit an error and is off until Reload UI; the game's chat shows text again. Error: " .. Wn.lastError)
  end
end

-- True while Cherry's Chat draws window i (then the game's own AddMessage is skipped).
function Wn.Owns(i)
  if Wn.broken or not C.active or not cfg().on then
    return false
  end
  local o = overlay(i)
  return o ~= nil
end

---------------------------------------------------------------------------
-- Wrapping: chat lines become rows that fit the window width.
---------------------------------------------------------------------------

Wn.widthCache = {}

local function utf8Len(s)
  local _, n = string.gsub(s, "[^\128-\191]", "")
  return n
end

-- RoM FontStrings have no GetStringWidth (/cchat measuretest, 2026-10-27), so widths were guessed
-- at 8.7 per letter: lines wrapped early and emoji pictures landed a word too far right. A FontString
-- with no size (CherrysChat_WinMeasure2) does take its text's width: GetWidth, in UI units, trailing
-- spaces included. /cchat measure <n> multiplies measured widths (default 1).
function Wn.MeasureScale()
  local n = tonumber(cfg().measureScale)
  if n and n > 0 then
    return n
  end
  return 1
end

function Wn.SetMeasureScale(n)
  cfg().measureScale = n
  Wn.widthCache, Wn.gap = {}, nil
  for i = 1, Wn.WINDOWS do
    Wn.rows[i] = nil
    if Wn.Owns(i) then
      Wn.Draw(i)
    end
  end
end

-- /cchat measuretest: raw numbers from the game's text measuring, for Cherry to read off a screenshot.
function Wn.MeasureTest()
  local function num(v)
    return type(v) == "number" and string.format("%.1f", v) or tostring(v)
  end
  local function call(obj, method)
    if not has(obj, method) then
      return "-"
    end
    local ok, v = pcall(obj[method], obj)
    return ok and num(v) or "err"
  end
  local m, m2 = CherrysChat_WinMeasure, CherrysChat_WinMeasure2
  local out = { "scale " .. num(scale()) .. " factor " .. num(Wn.MeasureScale()) }
  for _, text in ipairs({ "x", "lol", "lol there", "test lol ", "[Say] [Sampleplayer]: test " }) do
    local parts = { "[" .. text .. "]" }
    if m then
      m:SetText(text)
      parts[#parts + 1] = "A " .. call(m, "GetStringWidth") .. "/" .. call(m, "GetStringWidth") .. " w" .. call(m, "GetWidth")
    end
    if m2 then
      m2:SetText(text)
      m2:Show()
      local l, r = call(m2, "GetLeft"), call(m2, "GetRight")
      parts[#parts + 1] = "B " .. call(m2, "GetStringWidth") .. " w" .. call(m2, "GetWidth") .. " L" .. l .. " R" .. r
    end
    out[#out + 1] = table.concat(parts, " ")
  end
  if m2 then
    m2:SetText("")
  end
  C.DB().measureTest = out
  for _, line in ipairs(out) do
    C.Print(line)
  end
end

function Wn.TextWidth(text)
  local cached = Wn.widthCache[text]
  if cached then
    return cached
  end
  local w
  local m2 = CherrysChat_WinMeasure2
  if m2 and has(m2, "GetWidth") then
    m2:SetText(text)
    local ok, v = pcall(m2.GetWidth, m2)
    m2:SetText("")
    if ok and type(v) == "number" and v > 0 and v < 4000 then
      w = v * Wn.MeasureScale()
    elseif text == "" then
      w = 0
    end
  end
  local m = CherrysChat_WinMeasure
  if not w and m and has(m, "GetStringWidth") then
    m:SetText(text)
    local ok, v = pcall(m.GetStringWidth, m)
    if ok and type(v) == "number" and (v > 0 or text == "") then
      w = v * Wn.MeasureScale()
    end
  end
  -- Without a measure, guess: an average letter is about half the font size wide.
  w = w or utf8Len(text) * 14 * 0.62
  Wn.widthCache[text] = w
  return w
end

-- Splits one chat line into pieces: colour codes, resets, and words with their trailing spaces.
-- Words inside a link (|Htarget|htext|h) carry the link, so a click on them can be handed to the
-- game; the link codes themselves are not drawn.
-- Spaces as wide as an emoji picture, the gap the picture is drawn over.
function Wn.PicGap()
  if not Wn.gap then
    -- Measured between letters: a lone or trailing space may measure 0.
    local space = Wn.TextWidth("a a") - Wn.TextWidth("aa")
    if not (type(space) == "number" and space > 0) then
      space = 4
    end
    local n = math.ceil(Wn.PIC / space)
    Wn.gap = { text = string.rep(" ", n), w = n * space }
  end
  return Wn.gap
end

local function tokenize(list, msg, link, full, pics)
  local i, n = 1, string.len(msg)
  while i <= n do
    local ps, pe, num = string.find(msg, "^\1(%d+)\2", i)
    local c = string.match(msg, "^|c%x%x%x%x%x%x%x%x", i)
    local ls, le, target, text = string.find(msg, "^|H(.-)|h(.-)|h", i)
    if ps then
      local pic = pics and pics[tonumber(num)]
      if pic then
        local gap = Wn.PicGap()
        list[#list + 1] = { kind = "word", raw = gap.text, vis = gap.text, w = gap.w, pic = pic, copy = pic.copy,
          link = link, full = full }
      end
      i = pe + 1
    elseif ls and not link then
      tokenize(list, text, target, string.sub(msg, ls, le), pics)
      i = le + 1
    elseif c then
      list[#list + 1] = { kind = "colour", raw = c }
      i = i + 10
    elseif string.sub(msg, i, i + 1) == "|r" then
      list[#list + 1] = { kind = "reset", raw = "|r" }
      i = i + 2
    elseif string.sub(msg, i, i + 1) == "||" then
      list[#list + 1] = { kind = "word", raw = "||", vis = "|", link = link, full = full }
      i = i + 2
    elseif string.match(msg, "^|T.-|t", i) then
      i = i + string.len(string.match(msg, "^|T.-|t", i))
    else
      local word = string.match(msg, "^[^|%s\1]*%s*", i)
      if word == "" then
        word = string.sub(msg, i, i) -- a lone "|"
      end
      list[#list + 1] = { kind = "word", raw = word, vis = word, link = link, full = full }
      i = i + string.len(word)
    end
  end
end

function Wn.Tokens(msg, pics)
  local list = {}
  tokenize(list, msg, nil, nil, pics)
  local links, seen = {}, {}
  for _, t in ipairs(list) do
    if t.link and not seen[t.full] then
      seen[t.full] = true
      links[#links + 1] = t.link
    end
  end
  return list, links
end

-- Returns rows { text, plain, spans = { { x0, x1, link, full } }, pics = { { x, pic } } } and the
-- message's link targets. plain is the text to copy (emoji as they were written).
function Wn.WrapMessage(msg, maxW, pics)
  local list, links = Wn.Tokens(msg, pics)
  local rows, parts, plain, spans, rowPics, width, colour = {}, {}, {}, {}, {}, 0, nil
  local function finish()
    if colour then
      parts[#parts + 1] = "|r"
    end
    rows[#rows + 1] = { text = table.concat(parts), plain = table.concat(plain), spans = spans, pics = rowPics }
    parts, plain, spans, rowPics, width = {}, {}, {}, {}, 0
    if colour then
      parts[1] = colour
    end
  end
  for _, t in ipairs(list) do
    if t.kind == "colour" then
      colour = t.raw
      parts[#parts + 1] = t.raw
    elseif t.kind == "reset" then
      colour = nil
      parts[#parts + 1] = "|r"
    else
      local w = t.w or Wn.TextWidth(t.vis)
      if width > 0 and width + (t.w or Wn.TextWidth((string.gsub(t.vis, "%s+$", "")))) > maxW then
        finish()
      end
      if t.pic then
        rowPics[#rowPics + 1] = { x = width, pic = t.pic, prefix = table.concat(parts) }
      end
      plain[#plain + 1] = t.copy or t.vis
      if t.link then
        local last = spans[#spans]
        if last and last.full == t.full then
          last.x1 = width + w
        else
          spans[#spans + 1] = { x0 = width, x1 = width + w, link = t.link, full = t.full }
        end
      end
      parts[#parts + 1] = t.raw
      width = width + w
    end
  end
  if #parts > 0 or #rows == 0 then
    finish()
  end
  return rows, links
end

function Wn.TextArea(i)
  local s = st(i)
  return (s.w or 430) - Wn.PAD_LEFT - Wn.PAD, (s.h or 180) - Wn.PAD * 2
end

-- rows[i] = { { text, m = log index, links, colour }, ... }, built when first needed.
Wn.rows = {}

local function wrapInto(rows, i, k, maxW)
  local msg = C.log[i][k]
  local shown = msg
  local pics = {}
  local ok, decorated = pcall(C.Decorate, msg, pics)
  if ok then
    shown = decorated
  else
    pics = nil
  end
  local wrapped, links = Wn.WrapMessage(shown, maxW, pics)
  local colour = C.logColor[i] and C.logColor[i][k] or false
  for _, r in ipairs(wrapped) do
    rows[#rows + 1] = { text = r.text, plain = r.plain, spans = r.spans, pics = r.pics, m = k, links = links,
      colour = colour }
  end
  return #wrapped
end

function Wn.Rows(i)
  local rows = Wn.rows[i]
  if not rows then
    rows = {}
    local maxW = Wn.TextArea(i)
    for k = 1, #(C.log[i] or {}) do
      wrapInto(rows, i, k, maxW)
    end
    Wn.rows[i] = rows
  end
  return rows
end

function Wn.Rewrap(i)
  Wn.rows[i] = nil
  st(i).selA, st(i).selB = nil, nil
  Wn.Draw(i)
end

-- Called by Cherry's Chat after every logged line (removed = old lines dropped from the log).
local function onLogged(i, removed)
  local rows = Wn.rows[i]
  if not rows then
    Wn.Draw(i)
    return
  end
  local s = st(i)
  if removed > 0 then
    local cut = 0
    while rows[cut + 1] and rows[cut + 1].m <= removed do
      cut = cut + 1
    end
    for _ = 1, cut do
      table.remove(rows, 1)
    end
    for _, r in ipairs(rows) do
      r.m = r.m - removed
    end
    s.selA, s.selB = nil, nil
  end
  local added = wrapInto(rows, i, #C.log[i], (Wn.TextArea(i)))
  if s.offset > 0 then
    s.offset = s.offset + added -- reading older lines: keep them in place
  end
  Wn.Draw(i)
end

function Wn.OnLogged(i, removed)
  if Wn.Owns(i) then
    guarded(onLogged, i, removed)
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

function Wn.VisibleCount(i)
  local _, h = Wn.TextArea(i)
  return math.max(1, math.min(Wn.MAX_LINES, math.floor(h / Wn.LINE_H)))
end

-- First and last row index on screen, and how many slots there are.
function Wn.Range(i)
  local rows = Wn.Rows(i)
  local count = Wn.VisibleCount(i)
  local s = st(i)
  s.offset = math.max(0, math.min(s.offset, #rows - count))
  local last = #rows - s.offset
  return math.max(1, last - count + 1), last, count
end

local function inSelection(s, idx)
  local a, b = s.selA, s.selB
  if not a then
    return false
  end
  if a > b then
    a, b = b, a
  end
  return idx >= a and idx <= b
end

-- Where a picture goes: the width of the line's text before its gap, measured whole (kerning and
-- trailing spaces included). Falls back to the sum of the word widths.
function Wn.PicX(fs, p)
  if p.prefix == "" then
    return 0
  end
  if CherrysChat_WinMeasure2 and has(CherrysChat_WinMeasure2, "GetWidth") then
    return Wn.TextWidth(p.prefix)
  end
  if has(fs, "GetStringWidth") then
    fs:SetText("x")
    local ok1, wx = pcall(fs.GetStringWidth, fs)
    fs:SetText(p.prefix .. "x")
    local ok2, w = pcall(fs.GetStringWidth, fs)
    if ok1 and ok2 and type(w) == "number" and type(wx) == "number" and w > wx and wx > 0 then
      return (w - wx) * Wn.MeasureScale()
    end
  end
  return p.x
end

function Wn.Draw(i)
  local o = overlay(i)
  if not (o and o:IsVisible()) then
    return
  end
  local s = st(i)
  local rows = Wn.Rows(i)
  local first, last, count = Wn.Range(i)
  local w = Wn.TextArea(i)
  local used = 0
  for slot = 1, Wn.MAX_LINES do
    local fs, tex = line(i, slot), hi(i, slot)
    local idx = last - (count - slot)
    if slot <= count and idx >= first and idx >= 1 and rows[idx] then
      local y = Wn.PAD + (slot - 1) * Wn.LINE_H
      try(fs, "ClearAllAnchors")
      try(fs, "SetAnchor", "TOPLEFT", "TOPLEFT", o, Wn.PAD_LEFT, y)
      try(fs, "SetSize", w, Wn.LINE_H)
      fs:SetText(rows[idx].text)
      local c = rows[idx].colour
      try(fs, "SetColor", c and c[1] or 1, c and c[2] or 1, c and c[3] or 1)
      fs:Show()
      for _, p in ipairs(rows[idx].pics or {}) do
        local pt = _G["CherrysChat_W" .. i .. "Pic" .. (used + 1)]
        if pt then
          used = used + 1
          local x = Wn.PicX(fs, p)
          try(pt, "SetTexture", C.BasePath() .. "Media/Emoji/" .. p.pic.entry.file .. ".tga")
          try(pt, "ClearAllAnchors")
          try(pt, "SetAnchor", "TOPLEFT", "TOPLEFT", o, Wn.PAD_LEFT + x, y + math.floor((Wn.LINE_H - Wn.PIC) / 2))
          try(pt, "SetSize", Wn.PIC, Wn.PIC)
          pt:Show()
        end
      end
      if rows[idx].pics and rows[idx].pics[1] then
        fs:SetText(rows[idx].text) -- PicX measured with the line itself
      end
      if inSelection(s, idx) then
        try(tex, "ClearAllAnchors")
        try(tex, "SetAnchor", "TOPLEFT", "TOPLEFT", o, Wn.PAD_LEFT - 2, y)
        try(tex, "SetSize", w + 4, Wn.LINE_H)
        tex:Show()
      else
        tex:Hide()
      end
    else
      fs:SetText("")
      fs:Hide()
      tex:Hide()
    end
  end
  for k = used + 1, Wn.MAX_PICS do
    local pt = _G["CherrysChat_W" .. i .. "Pic" .. k]
    if pt and pt:IsVisible() then
      pt:Hide()
    end
  end
  try(_G["CherrysChat_W" .. i .. "More"], "SetText", s.offset > 0 and ("|cffffd100v " .. s.offset .. "|r") or "")
end

function Wn.Scroll(i, delta)
  guarded(function()
    local s = st(i)
    s.offset = math.max(0, s.offset + ((tonumber(delta) or 0) > 0 and 3 or -3))
    Wn.Draw(i)
  end)
end

---------------------------------------------------------------------------
-- Following the game's chat windows: shown, place and size, every 0.2 s.
---------------------------------------------------------------------------

local function follow()
  for i = 1, Wn.WINDOWS do
    local o, chat = overlay(i), C.Chat(i)
    if o and chat then
      local visible = Wn.Owns(i) and has(chat, "IsVisible") and chat:IsVisible()
        and has(chat, "GetWidth") and has(chat, "GetHeight")
      if visible then
        local w, h = chat:GetWidth(), chat:GetHeight()
        local s = st(i)
        if not o:IsVisible() then
          try(o, "ClearAllAnchors")
          try(o, "SetAnchor", "TOPLEFT", "TOPLEFT", chat, 0, 0)
          o:Show()
          s.drawn = false
          if not o:IsVisible() then
            error("overlay " .. i .. " does not show")
          end
        end
        if type(w) == "number" and type(h) == "number" and (w ~= s.w or h ~= s.h) then
          local widthChanged = w ~= s.w
          s.w, s.h = w, h
          try(o, "SetSize", w, h)
          if widthChanged then
            Wn.rows[i] = nil
          end
          s.drawn = false
        end
        if not s.drawn then
          s.drawn = true
          Wn.Draw(i)
        end
      elseif o:IsVisible() then
        o:Hide()
        if Wn.copyFor == i then
          Wn.HideCopy()
        end
      end
    end
  end
end

Wn.followWait = 0

function Wn.Update(elapsed)
  if Wn.broken or not C.active then
    return
  end
  if Wn.painting then
    guarded(Wn.PaintUpdate, elapsed)
  end
  if Wn.copyLeft then
    Wn.copyLeft = Wn.copyLeft - (elapsed or 0)
    if Wn.copyLeft <= 0 then
      Wn.copyLeft = nil
      Wn.CopyDone()
    end
  end
  Wn.followWait = Wn.followWait - (elapsed or 0)
  if Wn.followWait <= 0 then
    Wn.followWait = Wn.FOLLOW_EVERY
    guarded(follow)
  end
end

---------------------------------------------------------------------------
-- Mouse: like the game's chat, plus selecting and a right-click menu.
--   left click            the game's own link handling (items, names ...)
--   left drag             paints lines blue (selection)
--   right click           menu: Copy to clipboard, Whisper <sender>
---------------------------------------------------------------------------

Wn.DRAG_PIXELS = 4

local function cursorUI(i)
  local o = overlay(i)
  if not (GetCursorPos and has(o, "GetTop") and has(o, "GetLeft")) then
    return nil
  end
  local cx, cy = GetCursorPos()
  local left, top = o:GetLeft(), o:GetTop()
  if type(cx) ~= "number" or type(left) ~= "number" or type(top) ~= "number" then
    return nil
  end
  return (cx - left) / scale() - Wn.PAD_LEFT, (cy - top) / scale() - Wn.PAD
end

-- Which row of window i the mouse is over (clamped to the rows on screen), and -1/1 when it is
-- above/below them.
function Wn.RowAtCursor(i)
  local _, y = cursorUI(i)
  if not y then
    return nil
  end
  local first, last, count = Wn.Range(i)
  local slot = math.floor(y / Wn.LINE_H) + 1
  local edge = (slot < 1 and -1) or (slot > count and 1) or 0
  slot = math.max(1, math.min(count, slot))
  return math.max(first, math.min(last, last - (count - slot))), edge
end

-- The link under the mouse, if any.
function Wn.LinkAtCursor(i)
  local x = cursorUI(i)
  local idx = Wn.RowAtCursor(i)
  local r = idx and Wn.Rows(i)[idx]
  if not (r and x) then
    return nil
  end
  for _, span in ipairs(r.spans or {}) do
    if x >= span.x0 - 2 and x <= span.x1 + 2 then
      return span
    end
  end
end

-- Hands a link click to the game's chat, as if it had been clicked there.
-- RoM does not document ChatFrame_OnHyperlinkClick, so the game's own calls are watched (see
-- Wn.WatchLinkClicks): once a real click in the game's chat has been seen, the same argument
-- layout is used. Until then the guess is (frame, link, key), with this/arg1/arg2/arg3 set too.
function Wn.LinkArgs(chat, span, key)
  local sig = C.DB().linkSig
  if type(sig) == "table" and sig.n then
    local args = {}
    for p = 1, sig.n do
      local kind = sig[p]
      args[p] = (kind == "frame" and chat) or (kind == "link" and span.link) or (kind == "full" and span.full)
        or (kind == "key" and key) or nil
    end
    return args, sig.n
  end
  return { chat, span.link, key }, 3
end

function Wn.ClickLink(i, span, key)
  local fn = Wn.origLinkClick or ChatFrame_OnHyperlinkClick
  if type(fn) ~= "function" then
    return false
  end
  local chat = C.Chat(i)
  local args, n = Wn.LinkArgs(chat, span, key)
  local oldThis, a1, a2, a3 = this, arg1, arg2, arg3
  this, arg1, arg2, arg3 = chat, span.link, span.full, key
  Wn.callingLink = true
  local ok, err = pcall(fn, unpack(args, 1, n))
  Wn.callingLink = false
  this, arg1, arg2, arg3 = oldThis, a1, a2, a3
  if not ok and not Wn.linkErrorShown then
    Wn.linkErrorShown = true
    C.Print("item link click failed (" .. tostring(err) .. "). Type /cchat linktest once to teach me how your game does it.")
  end
  return ok
end

-- Describes one argument of a real call, so the same layout can be rebuilt for our clicks.
local function argKind(v, link)
  if type(v) == "table" then
    return "frame"
  elseif type(v) == "string" then
    if v == "LBUTTON" or v == "RBUTTON" or v == "MBUTTON" then
      return "key"
    elseif string.find(v, "|H", 1, true) then
      return "full"
    elseif string.find(v, ":", 1, true) or v == link then
      return "link"
    end
  end
  return "nil"
end

-- Wraps the game's ChatFrame_OnHyperlinkClick: every real click in the game's chat is passed on
-- unchanged, and its argument layout is remembered (CherrysChat_DB.linkSig).
function Wn.WatchLinkClicks()
  if Wn.origLinkClick or type(ChatFrame_OnHyperlinkClick) ~= "function" then
    return
  end
  local orig = C.Real("ChatFrame_OnHyperlinkClick", ChatFrame_OnHyperlinkClick)
  if type(orig) ~= "function" then
    return
  end
  Wn.origLinkClick = orig
  ChatFrame_OnHyperlinkClick = C.MarkOurs(function(...)
    if not Wn.callingLink then
      pcall(function(...)
        local n = select("#", ...)
        local sig = { n = n, seen = {} }
        for p = 1, n do
          local v = select(p, ...)
          sig[p] = argKind(v)
          sig.seen[p] = type(v) == "string" and string.sub(v, 1, 40) or type(v)
        end
        sig.thisIsFrame = type(this) == "table"
        sig.arg1 = type(arg1) == "string" and string.sub(arg1, 1, 40) or type(arg1)
        local learned = C.DB().linkSig
        C.DB().linkSig = sig
        if Wn.learning then
          Wn.learning = false
          C.Print("learned how your game opens links: " .. table.concat(sig.seen, ", ") .. ". Cherry's chat is back on.")
          Wn.Toggle(true)
        elseif not learned then
          C.Print("learned how your game opens links.")
        end
      end, ...)
    end
    return orig(...)
  end)
end

-- /cchat linktest: the game draws its chat for a moment; clicking any item link or name there
-- teaches Cherry's Chat the game's own call. Then Cherry's chat comes back by itself.
function Wn.LinkTest()
  Wn.WatchLinkClicks()
  if not Wn.origLinkClick then
    C.Print("this client has no ChatFrame_OnHyperlinkClick; links cannot be passed on.")
    return
  end
  Wn.learning = true
  Wn.Toggle(false)
  C.Print("link test: the normal chat is back for a moment. Link an item into chat (Shift+click it in your bag and press Enter), then click that link in the chat.")
end

local function clearOthers(i)
  for k in pairs(Wn.state) do
    if k ~= i and Wn.state[k].selA then
      Wn.state[k].selA, Wn.state[k].selB = nil, nil
      Wn.Draw(k)
    end
  end
end

local function mouseDown(i, key)
  Wn.HideMenu()
  if key == "RBUTTON" then
    Wn.OpenMenu(i)
    return
  end
  local idx = Wn.RowAtCursor(i)
  local cx, cy = GetCursorPos()
  Wn.press = { i = i, idx = idx, x = cx, y = cy, moved = false }
  Wn.painting, Wn.edgeWait = i, 0
end

function Wn.MouseDown(i, key)
  guarded(mouseDown, i, key)
end

function Wn.PaintUpdate(elapsed)
  local i = Wn.painting
  local p = Wn.press
  local s = st(i)
  if not p.moved then
    local cx, cy = GetCursorPos()
    if math.abs(cx - p.x) + math.abs(cy - p.y) < Wn.DRAG_PIXELS then
      return
    end
    -- It is a drag: start painting from the row the button went down on.
    p.moved = true
    clearOthers(i)
    if not (p.idx and Wn.Rows(i)[p.idx]) then
      Wn.painting = false
      return
    end
    s.selA, s.selB = p.idx, p.idx
  end
  local idx, edge = Wn.RowAtCursor(i)
  if not idx then
    return
  end
  -- Past the top or bottom: scroll a row every 0.08 s and keep painting.
  if edge ~= 0 then
    Wn.edgeWait = (Wn.edgeWait or 0) - (elapsed or 0)
    if Wn.edgeWait <= 0 then
      Wn.edgeWait = 0.08
      s.offset = math.max(0, s.offset - edge)
      idx = Wn.RowAtCursor(i)
    end
  end
  s.selB = idx
  Wn.Draw(i)
end

function Wn.MouseUp(i, key)
  guarded(function()
    local p = Wn.press
    Wn.press = nil
    if Wn.painting ~= i or not p then
      return
    end
    Wn.painting = false
    if p.moved then
      return -- painted lines stay blue until a click elsewhere; right-click them to copy
    end
    -- A plain click: clear the paint and do what the game's chat does.
    local s = st(i)
    if s.selA then
      s.selA, s.selB = nil, nil
      Wn.Draw(i)
    end
    clearOthers(i)
    local span = Wn.LinkAtCursor(i)
    if span then
      Wn.LinkLeftClick(i, span, key or "LBUTTON")
    end
  end)
end

local function shiftDown()
  return type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false
end

local function nameOf(link)
  return link and string.match(link, "^player:([^:]+)")
end

-- Like the game's chat: a name whispers, Shift puts the name or item link into the chat box, and
-- any other link (an item) goes to the game, which shows its tooltip.
function Wn.LinkLeftClick(i, span, key)
  local name = nameOf(span.link)
  if shiftDown() then
    Wn.InsertIntoChat(name or span.full, not name)
  elseif name then
    Wn.Whisper(name)
  else
    Wn.ClickLink(i, span, key)
  end
end

function Wn.Whisper(name)
  if not (type(ChatFrame_SendTell) == "function" and pcall(ChatFrame_SendTell, name)) then
    C.Print("whisper " .. name .. ": type /w " .. name)
  end
end

-- The game's chat typing box: RoM names it ChatFrameEditBox like WoW (unverified), so the
-- known names are tried.
function Wn.ChatBox()
  for _, n in ipairs({ "ChatFrameEditBox", "ChatFrame1EditBox", "DEFAULT_CHAT_FRAME_EDITBOX" }) do
    local box = _G[n]
    if type(box) == "table" then
      return box
    end
  end
  local f = DEFAULT_CHAT_FRAME
  return f and type(f.editBox) == "table" and f.editBox or nil
end

-- Puts text at the cursor of the chat typing box, opening it if needed. Item links go through the
-- game's own ChatEdit_AddItemLink first.
function Wn.InsertIntoChat(text, isItem)
  if isItem and type(ChatEdit_AddItemLink) == "function" and pcall(ChatEdit_AddItemLink, text) then
    return true
  end
  local box = Wn.ChatBox()
  if not box then
    C.Print("could not find the chat box to put " .. C.Plain(text) .. " into")
    return false
  end
  if not (has(box, "IsVisible") and box:IsVisible()) then
    if not (type(ChatEdit_OpenEditBox) == "function" and pcall(ChatEdit_OpenEditBox)) then
      try(box, "Show")
    end
  end
  try(box, "SetFocus")
  if not try(box, "Insert", text) then
    box:SetText((box:GetText() or "") .. text)
  end
  return true
end

-- Plain text of the painted rows. Rows of one chat line are joined back without a line break.
function Wn.SelectedText(i)
  local s = st(i)
  local a, b = s.selA, s.selB
  if not a then
    return ""
  end
  if a > b then
    a, b = b, a
  end
  local rows = Wn.Rows(i)
  local out, lastM = {}, nil
  for idx = a, b do
    local r = rows[idx]
    if r then
      if lastM and r.m ~= lastM then
        out[#out + 1] = "\n"
      end
      out[#out + 1] = r.plain or C.Plain(r.text)
      lastM = r.m
    end
  end
  return table.concat(out)
end

---------------------------------------------------------------------------
-- Right-click menu
---------------------------------------------------------------------------

local function senderOf(r)
  for _, target in ipairs(r and r.links or {}) do
    local name = nameOf(target)
    if name then
      return name
    end
  end
end

-- Menu entries, in order; the ones that need a player name are left out when there is none.
Wn.MENU = { "copy", "copyname", "whisper", "friend", "ignore", "cancel" }
Wn.MENU_BUTTON_H = 26

function Wn.OpenMenu(i)
  local s = st(i)
  local idx = Wn.RowAtCursor(i)
  local rows = Wn.Rows(i)
  if not (idx and rows[idx]) then
    return
  end
  -- Right-click outside the blue lines selects just the line under the mouse.
  if not inSelection(s, idx) then
    clearOthers(i)
    s.selA, s.selB = idx, idx
    Wn.Draw(i)
  end
  local n = math.abs(s.selB - s.selA) + 1
  -- The name under the mouse, else the line's sender.
  local span = Wn.LinkAtCursor(i)
  local name = (span and nameOf(span.link)) or senderOf(rows[idx])
  Wn.menu = { i = i, name = name }
  local labels = {
    copy = n > 1 and ("Copy " .. n .. " lines to clipboard") or "Copy line to clipboard",
    copyname = name and ("Copy name " .. name),
    whisper = name and ("Whisper " .. name),
    friend = name and "Add friend",
    ignore = name and "Ignore",
    cancel = "Cancel",
  }
  local shown = 0
  for _, what in ipairs(Wn.MENU) do
    local b = _G["CherrysChat_Menu_" .. what]
    if labels[what] then
      b:SetText(labels[what])
      try(b, "ClearAllAnchors")
      try(b, "SetAnchor", "TOPLEFT", "TOPLEFT", CherrysChat_Menu, 6, 6 + shown * Wn.MENU_BUTTON_H)
      b:Show()
      shown = shown + 1
    else
      b:Hide()
    end
  end
  local cx, cy = GetCursorPos()
  local menu = CherrysChat_Menu
  try(menu, "SetSize", 212, 12 + shown * Wn.MENU_BUTTON_H)
  try(menu, "ClearAllAnchors")
  try(menu, "SetAnchor", "TOPLEFT", "TOPLEFT", UIParent, cx / scale() + 4, cy / scale() + 4)
  menu:Show()
end

function Wn.HideMenu()
  if CherrysChat_Menu and CherrysChat_Menu:IsVisible() then
    CherrysChat_Menu:Hide()
  end
end

-- RoM's friend list calls (AddFriend(list, name), list "Friend" or "BadFriend" for ignore) are not
-- documented; a failure is reported in chat.
function Wn.AddToList(list, name, label)
  if type(AddFriend) == "function" and pcall(AddFriend, list, name) then
    C.Print(name .. " " .. label)
  else
    C.Print("could not " .. (list == "Friend" and "add " .. name .. " as a friend" or "ignore " .. name)
      .. "; use the game's Social window")
  end
end

function Wn.MenuClick(what)
  guarded(function()
    local m = Wn.menu
    Wn.HideMenu()
    if not m then
      return
    end
    local i = m.i
    if what == "copy" then
      Wn.CopyToClipboard(Wn.SelectedText(i), i)
      local s = st(i)
      s.selA, s.selB = nil, nil
      Wn.Draw(i)
    elseif what == "copyname" and m.name then
      Wn.CopyToClipboard(m.name, i)
    elseif what == "whisper" and m.name then
      Wn.Whisper(m.name)
    elseif what == "friend" and m.name then
      Wn.AddToList("Friend", m.name, "added to your friends")
    elseif what == "ignore" and m.name then
      Wn.AddToList("BadFriend", m.name, "is ignored")
    end
  end)
end

-- RoM's own Chat_CopyToClipboard puts text on the Windows clipboard. If it is missing or fails,
-- the text goes into a small box instead, selected, for Ctrl+C.
-- The game's clipboard call silently copies nothing when the text is long: 1 and 8 lines worked, 36
-- did not (in game, 2026-10-27). The real limit is unknown; /cchat cliptest measures it and
-- /cchat clipmax N saves it. Longer text goes into the copy box for Ctrl+C.
Wn.CLIP_MAX = 1000

function Wn.ClipMax()
  local n = tonumber(C.DB().clipMax)
  return (n and n > 0) and n or Wn.CLIP_MAX
end

function Wn.CopyToClipboard(text, i)
  if text == "" then
    return
  end
  if string.len(text) > Wn.ClipMax() then
    -- Too long for the game's clipboard: the text waits, selected, in the box above the chat.
    Wn.ShowCopy(i or 1, text)
    C.Print(C.PRESS_CTRL_C .. " (" .. string.len(text) .. " letters; the game copies up to " .. Wn.ClipMax() .. " by itself)")
    return
  end
  if type(Chat_CopyToClipboard) == "function" and pcall(Chat_CopyToClipboard, text) then
    C.Print(C.COPIED)
    return
  end
  Wn.ShowCopy(i or 1, text)
  C.Print(C.PRESS_CTRL_C)
end

function Wn.ShowCopy(i, text)
  Wn.copyText, Wn.copyFor = text, i
  local bar = CherrysChat_WinCopyBar
  try(bar, "ClearAllAnchors")
  try(bar, "SetAnchor", "BOTTOMLEFT", "TOPLEFT", overlay(i), 0, -2)
  CherrysChat_WinCopy:SetText(text)
  try(CherrysChat_WinCopyHint, "SetText", C.PRESS_CTRL_C .. "  Esc closes")
  bar:Show()
  Wn.copyLeft = 20 -- the bar closes itself after 20 s
  try(CherrysChat_WinCopy, "SetFocus")
  try(CherrysChat_WinCopy, "HighlightText")
end

function Wn.HideCopy()
  if CherrysChat_WinCopyBar and CherrysChat_WinCopyBar:IsVisible() then
    try(CherrysChat_WinCopy, "ClearFocus")
    CherrysChat_WinCopyBar:Hide()
  end
  Wn.copyLeft = nil
end

function Wn.CopyDone()
  Wn.HideCopy()
end

-- /cchat cliptest: puts a long numbered text on the clipboard. Pasted anywhere, the last number
-- shows how many letters the game's clipboard keeps.
function Wn.ClipTest()
  if type(Chat_CopyToClipboard) ~= "function" then
    C.Print("this game has no clipboard call; copying always uses the box.")
    return
  end
  local parts = {}
  for n = 100, 8000, 100 do
    local mark = "<" .. n .. ">"
    parts[#parts + 1] = string.rep(".", 100 - string.len(mark)) .. mark
  end
  pcall(Chat_CopyToClipboard, table.concat(parts))
  C.Print("clipboard test copied. Paste it anywhere: the last <number> is how many letters the game copies. Then type /cchat clipmax <that number> (now " .. Wn.ClipMax() .. ").")
end

-- Read-only: whatever is typed or pasted into the copy box is put back.
function Wn.CopyGuard()
  if Wn.copyText and CherrysChat_WinCopy:GetText() ~= Wn.copyText then
    CherrysChat_WinCopy:SetText(Wn.copyText)
    try(CherrysChat_WinCopy, "HighlightText")
  end
end

---------------------------------------------------------------------------
-- On and off
---------------------------------------------------------------------------

function Wn.HideAll()
  for i = 1, Wn.WINDOWS do
    local o = overlay(i)
    if o then
      o:Hide()
    end
  end
  Wn.HideCopy()
  Wn.HideMenu()
end

function Wn.Apply()
  if not CherrysChat_W1 then
    return
  end
  Wn.WatchLinkClicks()
  if not Wn.textured then
    Wn.textured = true
    for i = 1, Wn.WINDOWS do
      for k = 1, Wn.MAX_LINES do
        try(hi(i, k), "SetTexture", C.BasePath() .. "Media/White.tga")
        try(hi(i, k), "SetColor", 0.25, 0.45, 1)
        try(hi(i, k), "SetAlpha", 0.45)
      end
    end
  end
  Wn.state, Wn.rows = {}, {}
  if Wn.Owns(1) then
    Wn.flushed = nil -- lines the game drew while Cherry's chat was off go out of sight too
    Wn.FlushGameText()
    Wn.followWait = 0
  else
    Wn.HideAll()
  end
end

-- Lines the game drew before Cherry's Chat took over stay in its own frames and showed under ours
-- (in game, 2026-10-26; the chat frames have no working Clear). Push them out of sight with blank
-- lines through the game's own AddMessage.
Wn.FLUSH_LINES = 60

function Wn.FlushGameText()
  for i = 1, Wn.WINDOWS do
    local chat = C.Chat(i)
    local orig = chat and C.originals[chat]
    if orig and not (Wn.flushed and Wn.flushed[i]) then
      Wn.flushed = Wn.flushed or {}
      Wn.flushed[i] = true
      try(chat, "Clear")
      for _ = 1, Wn.FLUSH_LINES do
        pcall(orig, chat, " ")
      end
    end
  end
end

-- Emergency switch (settings button and /cchat window): off gives the game's chat back.
function Wn.Toggle(on)
  local w = cfg()
  if on == nil then
    on = not w.on
  end
  w.on = on
  Wn.Apply()
  C.Print(on and "chat drawn by Cherry's Chat: drag over lines, then right-click to copy them."
    or "the game draws the chat again (new lines only). /cchat window switches back.")
end

C.OnLogged = Wn.OnLogged
