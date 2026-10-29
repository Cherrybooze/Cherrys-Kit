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
Wn.widthCacheCount = 0

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
  Wn.widthCache, Wn.widthCacheCount, Wn.gap = {}, 0, nil
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
  -- Complete chat prefixes are usually unique. Keep measurement memory bounded.
  if Wn.widthCacheCount >= 4096 then Wn.widthCache, Wn.widthCacheCount = {}, 0 end
  Wn.widthCache[text] = w
  Wn.widthCacheCount = Wn.widthCacheCount + 1
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

local function tokenize(list, msg, link, full, pics, classColour)
  local i, n = 1, string.len(msg)
  while i <= n do
    local ps, pe, num = string.find(msg, "^\1(%d+)\2", i)
    local c = string.match(msg, "^|c%x%x%x%x%x%x%x%x", i)
    local itemLink = not link and C.ReadLink(msg, i)
    if ps then
      local pic = pics and pics[tonumber(num)]
      if pic then
        local gap = Wn.PicGap()
        list[#list + 1] = { kind = "word", raw = gap.text, vis = gap.text, w = gap.w, pic = pic, copy = pic.copy,
          link = link, full = full }
      end
      i = pe + 1
    elseif itemLink then
      local playerColour = C.PlayerClassColour(itemLink.target)
      list[#list + 1] = { kind = "link_start", target = itemLink.target, text = itemLink.text, classColour = playerColour }
      tokenize(list, itemLink.text, itemLink.target, itemLink.full, pics, playerColour)
      list[#list + 1] = { kind = "link_end" }
      i = itemLink.last + 1
    elseif c then
      if not classColour then list[#list + 1] = { kind = "colour", raw = c } end
      i = i + 10
    elseif string.sub(msg, i, i + 1) == "|r" then
      if not classColour then list[#list + 1] = { kind = "reset", raw = "|r" } end
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
-- Split only words too wide for a whole row, retaining UTF-8 character boundaries and
-- the complete original link on every fragment. Localized names need not contain spaces.
local function fittingTokens(tokens, maxW)
  local result = {}
  for _, token in ipairs(tokens) do
    if token.kind == "word" and not token.pic and token.raw == token.vis
      and Wn.TextWidth((string.gsub(token.vis, "%s+$", ""))) > maxW then
      local part, i = "", 1
      local function add()
        if part ~= "" then
          result[#result + 1] = { kind = "word", raw = part, vis = part, link = token.link, full = token.full }
        end
      end
      while i <= #token.vis do
        local byte = string.byte(token.vis, i)
        local len = byte >= 240 and 4 or byte >= 224 and 3 or byte >= 192 and 2 or 1
        local ch = string.sub(token.vis, i, i + len - 1)
        if part ~= "" and Wn.TextWidth(part .. ch) > maxW then add(); part = "" end
        part, i = part .. ch, i + len
      end
      add()
    else
      result[#result + 1] = token
    end
  end
  return result
end

-- AAH's ItemLink generator documents the 12 hexadecimal fields: the third field
-- contains the instance rarity modifier in the upper bits of its second byte.
-- Only use that known format and native APIs; unknown links keep their supplied colour.
local qualityColours = {}
local function itemColour(target)
 if qualityColours[target] ~= nil then return qualityColours[target] or nil end
 local fields = {}
 local payload = string.match(target or "", "^item:(.+)$")
 if payload then for field in string.gmatch(payload, "%S+") do fields[#fields + 1] = field end end
 local colour
 if #fields == 12 and GetQualityByGUID and GetItemQualityColor then
  local valid = true
  for _, field in ipairs(fields) do if not string.match(field, "^%x+$") then valid = false end end
  local id, flags = tonumber(fields[1], 16), tonumber(fields[3], 16)
  if valid and id and flags then
   local ok, quality = pcall(GetQualityByGUID, id)
   if ok and type(quality) == "number" then
    local modifier = math.floor((math.floor(flags / 256) % 256) / 32)
    local success, r, g, b = pcall(GetItemQualityColor, quality + modifier)
    if success and type(r) == "number" and type(g) == "number" and type(b) == "number" and r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
     colour = string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
    end
   end
  end
 end
 qualityColours[target] = colour or false
 return colour
end

function Wn.WrapMessage(msg, maxW, pics, baseColour)
  maxW = math.max(1, tonumber(maxW) or 1)
  local tokens, links = Wn.Tokens(msg, pics)
  local list = fittingTokens(tokens, maxW)
  local rows, parts, plain, spans, rowPics, width, colour = {}, {}, {}, {}, {}, 0, baseColour
  local colourStack, linkStack = {}, {}
  if colour then parts[1] = colour end
  local function finish()
    if colour then parts[#parts + 1] = "|r" end
    rows[#rows + 1] = { text = table.concat(parts), plain = table.concat(plain), spans = spans, pics = rowPics }
    parts, plain, spans, rowPics, width = {}, {}, {}, {}, 0
    if colour then parts[1] = colour end
  end
  for _, t in ipairs(list) do
    if t.kind == "link_start" then
      linkStack[#linkStack + 1] = { colour = colour, depth = #colourStack }
      if t.classColour or (not string.find(t.text, "|c%x%x%x%x%x%x%x%x") and (not colour or colour == baseColour)) then
        local native = t.classColour or itemColour(t.target)
        if native then
          colourStack[#colourStack + 1] = colour or false
          colour = native
          parts[#parts + 1] = native
        end
      end
    elseif t.kind == "link_end" then
      local scope = table.remove(linkStack)
      if scope and (colour ~= scope.colour or #colourStack > scope.depth) then
        while #colourStack > scope.depth do table.remove(colourStack) end
        parts[#parts + 1] = "|r"
        colour = scope.colour
        if colour then parts[#parts + 1] = colour end
      end
    elseif t.kind == "colour" then
      colourStack[#colourStack + 1] = colour or false
      colour = t.raw
      parts[#parts + 1] = t.raw
    elseif t.kind == "reset" then
      colour = table.remove(colourStack) or baseColour
      parts[#parts + 1] = "|r"
      if colour then parts[#parts + 1] = colour end
    else
      local prefix = table.concat(parts)
      -- Measure the same complete visible prefix that the FontString draws. Summed word
      -- widths miss kerning across colour/link boundaries and move the clickable area.
      local fit = Wn.TextWidth(C.Plain(prefix .. (string.gsub(t.raw, "%s+$", ""))))
      if width > 0 and fit > maxW then finish(); prefix = table.concat(parts) end
      local nextWidth = Wn.TextWidth(C.Plain(prefix .. t.raw))
      if t.pic then rowPics[#rowPics + 1] = { x = width, pic = t.pic, prefix = prefix } end
      plain[#plain + 1] = t.copy or t.vis
      if t.link then
        local last = spans[#spans]
        if last and last.full == t.full and last.x1 == width then
          last.x1 = nextWidth
        else
          spans[#spans + 1] = { x0 = width, x1 = nextWidth, link = t.link, full = t.full }
        end
      end
      parts[#parts + 1] = t.raw
      width = nextWidth
    end
  end
  if #parts > 0 or #rows == 0 then finish() end
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
  local colour = C.logColor[i] and C.logColor[i][k] or false
  local function component(v)
    return math.floor(math.max(0, math.min(1, tonumber(v) or 1)) * 255 + 0.5)
  end
  local baseColour = colour and string.format("|cff%02x%02x%02x", component(colour[1]), component(colour[2]), component(colour[3])) or "|cffffffff"
  local wrapped, links = Wn.WrapMessage(shown, maxW, pics, baseColour)
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
      -- The channel colour is markup in the row; white avoids tinting item colours.
      try(fs, "SetColor", 1, 1, 1)
      fs:SetText(rows[idx].text)
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
  local x, y = cursorUI(i)
  if not x or not y then return nil end
  local first, last, count = Wn.Range(i)
  local slot = math.floor(y / Wn.LINE_H) + 1
  local index = last - (count - slot)
  -- RowAtCursor deliberately clamps during dragging. Link clicks must instead stay on
  -- the actual rendered row, excluding empty slots and padding above/below the text.
  if slot < 1 or slot > count or index < first or index > last then return nil end
  local row = Wn.Rows(i)[index]
  for _, span in ipairs(row and row.spans or {}) do
    if x >= span.x0 and x < span.x1 then return span end
  end
end

-- Hands a link click to the game's chat, as if it had been clicked there.
-- RoM does not document ChatFrame_OnHyperlinkClick, so the game's own calls are watched (see
-- Wn.WatchLinkClicks): once a real click in the game's chat has been seen, the same argument
-- layout is used. Until then pass the complete encoded hyperlink, including its item data and
-- localized label, as (frame, full hyperlink, key), with matching event globals.
local function linkValue(kind, chat, span, key)
  if kind == "frame" then return chat end
  if kind == "link" then return span.link end
  if kind == "full" then return span.full end
  if kind == "key" then return key end
  if kind == "label" or kind == "plainLabel" then
    local link = C.ReadLink(span.full or "")
    local text = link and link.text or ""
    return kind == "plainLabel" and C.Plain(text) or text
  end
end

function Wn.LinkArgs(chat, span, key)
  local sig = C.DB().linkSig
  if type(sig) == "table" and sig.n then
    local args = {}
    for p = 1, sig.n do args[p] = linkValue(sig[p], chat, span, key) end
    return args, sig.n
  end
  return { chat, span.full, key }, 3
end

local function itemTooltip(span)
  -- These native SetHyperLink methods are also used by the bundled auction/tooltip addons.
  -- Only an encoded item target qualifies: ordinary brackets never become guessed item IDs.
  if not string.match(span.link or "", "^item:") or not C.ReadLink(span.full or "") then return false end
  for _, name in ipairs({ "GameTooltipHyperLink", "GameTooltip" }) do
    local tooltip = _G[name]
    local ok, shown = try(tooltip, "SetHyperLink", span.full)
    if ok and shown ~= false then try(tooltip, "Show"); return true end
  end
  return false
end

function Wn.ClickLink(i, span, key)
  local fn = Wn.origLinkClick or ChatFrame_OnHyperlinkClick
  local ok, result = false, "native hyperlink click handler is unavailable"
  if type(fn) == "function" then
    local chat = C.Chat(i)
    local args, n = Wn.LinkArgs(chat, span, key)
    local oldThis, a1, a2, a3 = this, arg1, arg2, arg3
    local sig = C.DB().linkSig
    local globals = type(sig) == "table" and sig.globals
    if globals then
      this = linkValue(globals.this, chat, span, key)
      arg1, arg2, arg3 = linkValue(globals.arg1, chat, span, key), linkValue(globals.arg2, chat, span, key), linkValue(globals.arg3, chat, span, key)
    else
      -- Default event globals carry the same complete encoded hyperlink and key.
      this, arg1, arg2, arg3 = chat, span.full, key, nil
    end
    Wn.callingLink = true
    ok, result = pcall(fn, unpack(args, 1, n))
    Wn.callingLink = false
    this, arg1, arg2, arg3 = oldThis, a1, a2, a3
  end
  if ok and result ~= false then return true end
  Wn.lastLinkError = tostring(result)
  if itemTooltip(span) then return true end
  if not Wn.linkErrorShown then
    Wn.linkErrorShown = true
    C.Print("item link click failed (" .. Wn.lastLinkError .. "). Type /cchat linktest to learn the native click; /cchat linkprobe captures the raw message.")
  end
  return false
end

-- Classify actual native arguments, including event globals and a separate localized label.
-- The label is matched only to encoded link text witnessed in that same native call.
local function argKind(v, sample)
  if type(v) == "table" or type(v) == "userdata" then
    for i = 1, Wn.WINDOWS do if v == C.Chat(i) then return "frame" end end
    if has(v, "GetName") then return "frame" end
  elseif type(v) == "string" then
    if v == "LBUTTON" or v == "RBUTTON" or v == "MBUTTON"
      or v == "LeftButton" or v == "RightButton" or v == "MiddleButton" then return "key" end
    if string.find(v, "|H", 1, true) then return "full" end
    if sample and v == sample.text then return "label" end
    if sample and v == C.Plain(sample.text) then return "plainLabel" end
    if string.match(v, "^[%a_][%w_]*:") then return "link" end
  end
  return "nil"
end

local function nativeSample(...)
  for p = 1, select("#", ...) do
    local value = select(p, ...)
    if type(value) == "string" then
      local start = string.find(value, "|H", 1, true)
      local link = start and C.ReadLink(value, start)
      if link then return link end
    end
  end
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
        local sample = nativeSample(...) or nativeSample(arg1, arg2, arg3)
        for p = 1, n do
          local v = select(p, ...)
          sig[p] = argKind(v, sample)
          sig.seen[p] = type(v) == "string" and string.sub(v, 1, 40) or type(v)
        end
        sig.globals = { this = argKind(this, sample), arg1 = argKind(arg1, sample),
          arg2 = argKind(arg2, sample), arg3 = argKind(arg3, sample) }
        sig.thisIsFrame = sig.globals.this == "frame"
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

-- Screenshots hide link metadata. Capture a bounded local report from the original log,
-- before decoration, instead of guessing an item ID from its translated label.
function Wn.LinkProbe(i)
  i = i or C.CurrentIndex()
  local probe = { window = i, version = C.version, entries = {}, signature = C.DB().linkSig,
    clickError = Wn.lastLinkError }
  local output = { "Cherry's Chat link report (chat " .. i .. ", " .. C.version .. ")" }
  local function quoted(value)
    if type(value) == "string" then return string.format("%q", value) end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    return type(value)
  end
  local function native(link)
    if type(ParseHyperlink) ~= "function" then return "ParseHyperlink unavailable" end
    local ok, kind, data, label = pcall(ParseHyperlink, link)
    return "ParseHyperlink: " .. tostring(ok) .. " / " .. quoted(kind) .. " / " .. quoted(data) .. " / " .. quoted(label)
  end
  local source = C.log[i] or {}
  for k = #source, 1, -1 do
    local msg = source[k]
    if string.find(msg, "|H", 1, true) or string.find(msg, "[", 1, true) then
      local entry = { raw = msg, links = {}, native = native(msg), colour = C.logColor[i] and C.logColor[i][k] }
      probe.entries[#probe.entries + 1] = entry
      output[#output + 1] = "\nRaw " .. #probe.entries .. ": " .. quoted(msg)
      output[#output + 1] = entry.native
      local p = 1
      while p <= #msg do
        local link = C.ReadLink(msg, p)
        if link then
          entry.links[#entry.links + 1] = link
          output[#output + 1] = "Target: " .. quoted(link.target)
          output[#output + 1] = "Full: " .. quoted(link.full)
          output[#output + 1] = native(link.full)
          p = link.last + 1
        else
          p = p + (string.sub(msg, p, p + 1) == "||" and 2 or 1)
        end
      end
      local _, links = Wn.Tokens(msg)
      entry.recognized = #links
      output[#output + 1] = "Recognized targets: " .. #links
      if #probe.entries == 5 then break end
    end
  end
  if #probe.entries == 0 then output[#output + 1] = "No recent tagged/bracketed messages in this tab. Run again after the affected message." end
  local sig = probe.signature
  output[#output + 1] = "\nNative click signature: " .. (sig and tostring(sig.n) or "not learned")
  if sig then
    for p = 1, sig.n or 0 do output[#output + 1] = "argument " .. p .. ": " .. tostring(sig[p]) end
    for _, name in ipairs({ "this", "arg1", "arg2", "arg3" }) do
      output[#output + 1] = name .. ": " .. tostring(sig.globals and sig.globals[name] or "legacy/default")
    end
  end
  if probe.clickError then output[#output + 1] = "Last native click error: " .. probe.clickError end
  C.DB().linkProbe = probe
  local report = table.concat(output, "\n")
  Wn.ShowCopy(i, report)
  return report
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

-- Modified player clicks insert the name into an open chat box, or inquire when closed.
-- Shift-clicking an item still inserts the complete encoded link into chat.
function Wn.LinkLeftClick(i, span, key)
  local name = nameOf(span.link)
  local ctrl = type(IsCtrlKeyDown) == "function" and IsCtrlKeyDown()
  if name and (ctrl or shiftDown()) then
    local box = Wn.ChatBox()
    local visible, isOpen = try(box, "IsVisible")
    if visible and isOpen and isOpen ~= 0 then
      Wn.InsertIntoChat(name, false)
    else
      local ok, result = false, nil
      if type(AskPlayerInfo) == "function" then ok, result = pcall(AskPlayerInfo, name) end
      if not ok or result == false then C.Print("could not request player information for " .. name) end
    end
  elseif shiftDown() then
    Wn.InsertIntoChat(span.full, true)
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
  local fallback
  local function candidate(box)
    if not (has(box, "GetText") or has(box, "InsertText")) then return nil end
    fallback = fallback or box
    local ok, visible = try(box, "IsVisible")
    if ok and visible and visible ~= 0 then return box end
  end
  for _, n in ipairs({ "ChatFrameEditBox", "ChatFrame1EditBox", "DEFAULT_CHAT_FRAME_EDITBOX", "DEFAULT_CHAT_EDITBOX" }) do
    local box = candidate(_G[n])
    if box then return box end
  end
  local f = DEFAULT_CHAT_FRAME
  return candidate(f and f.editBox) or fallback
end

-- Puts text at the cursor of the chat typing box, opening it if needed. Item links go through the
-- game's own ChatEdit_AddItemLink first.
function Wn.InsertIntoChat(text, isItem)
  if isItem and type(ChatEdit_AddItemLink) == "function" then
    local ok, inserted = pcall(ChatEdit_AddItemLink, text)
    if ok and inserted ~= false then return true end
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
  if not try(box, "InsertText", text) and not try(box, "Insert", text) then
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
  Wn.SelectCopy()
end

-- Clicking the text, hint or border selects the saved payload again. Do this on mouse-up:
-- the edit box's own mouse-down otherwise replaces the selection with a caret.
function Wn.SelectCopy()
  local bar = CherrysChat_WinCopyBar
  if not Wn.copyText or not bar or not bar:IsVisible() then
    return
  end
  Wn.CopyGuard()
  try(CherrysChat_WinCopy, "SetFocus")
  try(CherrysChat_WinCopy, "HighlightText")
end

-- Static XML callback: the client does not always provide a usable 'this'.
function Wn.HighlightCopy()
  if Wn.copyText then
    Wn.CopyGuard()
    try(CherrysChat_WinCopy, "HighlightText")
  end
end

function Wn.HideCopy()
  Wn.copyText, Wn.copyFor = nil, nil
  if CherrysChat_WinCopyBar and CherrysChat_WinCopyBar:IsVisible() then
    try(CherrysChat_WinCopy, "ClearFocus")
    CherrysChat_WinCopyBar:Hide()
  end
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

-- Keep the payload until explicitly closed, even while another input owns focus. The XML
-- focus-lost handler restores text without taking focus back; a later click reselects it all.
-- Read-only: whatever is typed or pasted into the copy box is put back.
function Wn.CopyGuard()
  if Wn.restoringCopy then
    return
  end
  if Wn.copyText and CherrysChat_WinCopy:GetText() ~= Wn.copyText then
    -- Native edit boxes may normalize line endings or truncate input. Their
    -- OnTextChanged callback must not recursively try to restore forever.
    Wn.restoringCopy = true
    try(CherrysChat_WinCopy, "SetText", Wn.copyText)
    Wn.restoringCopy = nil
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
