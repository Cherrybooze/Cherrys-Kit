-- Cherry's Chat: copyable chat, emoji pictures, and free chat font and window sizes.
--
-- How it works:
--   * Every chat window's AddMessage is wrapped. The original text goes into a log (for the copy
--     window) and emoji in the text are swapped for small pictures (Media/Emoji) before the
--     client draws the line.
--   * Font size and window size are set on the chat frames directly and saved per window, so they
--     are put back after every login or Reload UI.
-- Many chat details of the RoM client are not documented. Where a call is a guess it is wrapped in
-- pcall, and /cchat probe reports what this client really has.

CherrysChat = CherrysChat or {}
local C = CherrysChat

-- RoM's Reload UI runs the addon files again in the SAME Lua state: CherrysChat and the functions
-- we wrapped last time are still there. So every load starts over (flags below), and a function
-- that is our own old wrapper is never taken as the game's original (C.Real).
C.started, C.active, C.eventWrapped, C.sendWrapped, C.gripOn, C.drag = nil, nil, nil, nil, nil, nil
C.dropDownsReady = nil
C.ours = C.ours or setmetatable({}, { __mode = "k" }) -- our wrappers, from any load
C.real = C.real or {} -- key -> the game's own function

-- The game's own function for key, given what is installed now.
function C.Real(key, current)
  if current ~= nil and C.ours[current] then
    return C.real[key]
  end
  C.real[key] = current
  return current
end

function C.MarkOurs(wrapper)
  C.ours[wrapper] = true
  return wrapper
end

C.version = "0.10.6"
C.MAX_WINDOWS = 10
C.MIN_FONT, C.MAX_FONT = 6, 40
C.MIN_W, C.MIN_H = 120, 60
C.FONT_STEP, C.SIZE_STEP = 1, 20

if SaveVariables then
  SaveVariables("CherrysChat_DB")
end

C.DEFAULTS = {
  -- In game (2026-10-26) RoM chat printed |T...|t picture codes as raw text, so pictures are out;
  -- symbols uses what the chat font can draw (Symbols.lua).
  emoji = "symbols", -- symbols | text | pictures | off
  emojiStyle = 1, -- which picture code the client understands, see C.PictureCode
  emojiSize = 0, -- 0 = same height as the text
  smileys = false, -- also turn :) :( <3 ... into pictures
  sendShortcodes = false, -- :heart: in a message you send becomes the emoji itself
  copyButton = true, -- the C button on the chat: select mode for copying
  allWindows = true, -- font and size changes go to every chat window
  logLines = 500,
  copyLines = 200,
  windows = {}, -- [index] = { font = n, w = n, h = n }
}

local function db()
  if type(CherrysChat_DB) ~= "table" then
    CherrysChat_DB = {}
  end
  local d = CherrysChat_DB
  for k, v in pairs(C.DEFAULTS) do
    if d[k] == nil then
      d[k] = type(v) == "table" and {} or v
    end
  end
  if (d.copyDefaults or 0) < 2 then
    -- 0.5.0 turned the C button off for the chat overlay, which did not work in game.
    d.copyDefaults, d.copyButton = 2, true
  end
  if (d.emojiDefaults or 0) < 2 then
    -- Settings from 0.1/0.2 say "pictures" or "text"; the client shows pictures as raw codes.
    d.emojiDefaults, d.textDefault = 2, nil
    if d.emoji == "pictures" or d.emoji == "text" then
      d.emoji = "symbols"
    end
  end
  return d
end
C.DB = db

local function print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring((select(i, ...)))
  end
  local frame = DEFAULT_CHAT_FRAME
  if frame then
    local text = "|cffff7fa8Cherry's Chat|r: " .. table.concat(parts, " ")
    -- While Cherry's chat draws this window, our lines go there too: the game's own frame is
    -- hidden under it, and a line drawn there showed through ours (in game, 2026-10-27).
    for i = 1, C.MAX_WINDOWS do
      if C.Chat(i) == frame and C.Win and C.Win.Owns(i) then
        frame:AddMessage(text)
        return
      end
    end
    -- Otherwise straight to the original AddMessage so our own lines stay out of the copy log.
    local add = C.originals and C.originals[frame] or frame.AddMessage
    local ok, shown = pcall(C.Decorate, text)
    add(frame, ok and shown or text)
  end
end
C.Print = print

local function try(obj, method, ...)
  if obj == nil then
    return false
  end
  local ok, fn = pcall(function()
    return obj[method]
  end)
  if not ok or type(fn) ~= "function" then
    return false
  end
  return pcall(fn, obj, ...)
end
C.Try = try

local function has(obj, method)
  local ok, fn = pcall(function()
    return obj[method]
  end)
  return ok and type(fn) == "function"
end

C.Has = has

-- RoM links encode an opaque target followed by a separately localized label.
-- ItemLink.lua in the bundled auction addon emits |Hitem:<hex fields>|h<label>|h.
-- Scan delimiters, never item names; doubled pipes are literal text, not control tags.
local function controlEnd(msg, tag, first, rejectLink)
  local i = first
  while i <= #msg do
    local p = string.find(msg, "|", i, true)
    if not p then return nil end
    local token = string.sub(msg, p, p + 1)
    if token == "||" then
      i = p + 2
    elseif token == tag then
      return p
    elseif rejectLink and token == "|H" then
      return nil -- an incomplete link must not swallow the next complete one
    else
      i = p + 2
    end
  end
end

function C.ReadLink(msg, first)
  first = first or 1
  if type(msg) ~= "string" or string.sub(msg, first, first + 1) ~= "|H" then return nil end
  local middle = controlEnd(msg, "|h", first + 2, true)
  if not middle then return nil end
  local last = controlEnd(msg, "|h", middle + 2, true)
  if not last then return nil end
  local target = string.sub(msg, first + 2, middle - 1)
  if not string.match(target, "^[%a_][%w_]*:") or string.find(target, "[\r\n]") then return nil end
  return { target = target, text = string.sub(msg, middle + 2, last - 1),
    full = string.sub(msg, first, last + 1), first = first, last = last + 1 }
end

function C.Chat(i)
  return _G["ChatFrame" .. i]
end

function C.WindowName(i)
  if GetChatWindowInfo then
    local ok, name = pcall(GetChatWindowInfo, i)
    if ok and type(name) == "string" and name ~= "" then
      return name
    end
  end
  return "Chat " .. i
end

-- The chat tab you are looking at.
function C.CurrentIndex()
  for _, global in ipairs({ "SELECTED_CHAT_FRAME", "SELECTED_DOCK_FRAME" }) do
    local f = _G[global]
    for i = 1, C.MAX_WINDOWS do
      if f ~= nil and C.Chat(i) == f then
        return i
      end
    end
  end
  for i = 1, C.MAX_WINDOWS do
    local f = C.Chat(i)
    if f and try(f, "IsVisible") and f:IsVisible() then
      return i
    end
  end
  return 1
end

---------------------------------------------------------------------------
-- Emoji
---------------------------------------------------------------------------

C.byText, C.byCode = {}, {}
for _, e in ipairs(CherrysChat_EmojiList or {}) do
  local entry = { code = e[1], text = e[2], file = e[3] }
  C.byText[e[2]] = entry
  C.byCode[e[1]] = entry
end

-- Other names people type for the same emoji.
C.ALIASES = {
  thumbs_up = "thumbsup", thumbs_down = "thumbsdown", lol = "joy", love = "heart", sad = "cry", happy = "smile",
  sword = "crossed_swords", swords = "crossed_swords", gold = "coin", money = "moneybag", poo = "poop",
  kitty = "cat", puppy = "dog", pumpkin = "jack_o_lantern", flame = "fire", wizard = "mage", party = "tada",
}
for alias, code in pairs(C.ALIASES) do
  if C.byCode[code] and not C.byCode[alias] then
    C.byCode[alias] = C.byCode[code]
  end
end

-- Classic smileys, used when "smileys" is on. Only matched between spaces.
C.SMILEYS = {
  [":)"] = "slight_smile", [":-)"] = "slight_smile", [":D"] = "smiley", [":-D"] = "smiley",
  [";)"] = "wink", [";-)"] = "wink", [":("] = "slight_frown", [":-("] = "slight_frown",
  [":P"] = "stuck_out_tongue", [":p"] = "stuck_out_tongue", [":O"] = "open_mouth", [":o"] = "open_mouth",
  ["<3"] = "heart", ["</3"] = "broken_heart", ["xD"] = "laughing", ["XD"] = "laughing",
  [":'("] = "cry", ["B)"] = "sunglasses", [":|"] = "neutral", ["^^"] = "blush",
}

function C.BasePath()
  return (CherrysKit_Paths and CherrysKit_Paths.CherrysChat) or "Interface/AddOns/CherrysChat/"
end

-- RoM does not document an inline picture code, so there are three guesses. /cchat probe shows
-- all three; the one that draws a picture is the one to pick (Settings, or /cchat style N).
C.STYLES = 3
function C.PictureCode(file, style, size)
  local path = C.BasePath() .. "Media/Emoji/" .. file
  size = size or 0
  if style == 2 then
    return "|T" .. path .. ".tga:" .. size .. "|t"
  elseif style == 3 then
    return "|T" .. path .. "|t"
  end
  return "|T" .. path .. ":" .. size .. ":" .. size .. "|t"
end

-- pics: Cherry's chat draws emoji as pictures. The emoji becomes a mark "\1n\2" and pics[n] says
-- which picture and what text to copy; the window puts the picture over the gap.
local function render(entry, pics, original)
  if pics then
    pics[#pics + 1] = { entry = entry, copy = original or entry.text }
    return "\1" .. #pics .. "\2"
  end
  local d = db()
  if d.emoji == "symbols" then
    local sym = CherrysChat_Symbols and CherrysChat_Symbols[entry.code]
    if sym then
      return "|cff" .. sym[2] .. sym[1] .. "|r"
    end
  end
  if d.emoji == "text" or d.emoji == "symbols" then
    return "|cffffd100:" .. entry.code .. ":|r"
  end
  return C.PictureCode(entry.file, d.emojiStyle, d.emojiSize)
end

local VS16 = "\239\184\143" -- U+FE0F, asks for the colour form; carries nothing for us
local ZWJ = "\226\128\141" -- U+200D, glues emoji into one (family, profession ...)

local function charLen(b)
  if b >= 240 then
    return 4
  elseif b >= 224 then
    return 3
  elseif b >= 192 then
    return 2
  end
  return 1
end

local function isSkinTone(ch)
  -- U+1F3FB .. U+1F3FF
  return #ch == 4 and string.sub(ch, 1, 3) == "\240\159\143" and string.byte(ch, 4) >= 187
end

-- Swaps known emoji for symbols, text or (with pics, for Cherry's chat) picture marks. Skin tones
-- and joined sequences show their first emoji; an emoji we have no picture for is left as it is.
local function decorateText(msg, pics)
  local d = db()
  if d.emoji == "off" or type(msg) ~= "string" then
    return msg
  end
  local out = msg
  if string.find(msg, "[\226-\244]") then
    local parts, i, n, changed = {}, 1, string.len(msg), false
    while i <= n do
      local len = charLen(string.byte(msg, i))
      local ch = string.sub(msg, i, i + len - 1)
      local entry = C.byText[ch]
      local start = i
      i = i + len
      if entry then
        changed = true
        -- Swallow what belongs to this emoji: FE0F, a skin tone, and ZWJ + next emoji.
        while i <= n do
          local nlen = charLen(string.byte(msg, i))
          local nxt = string.sub(msg, i, i + nlen - 1)
          if nxt == VS16 or isSkinTone(nxt) then
            i = i + nlen
          elseif nxt == ZWJ and i + nlen <= n then
            i = i + nlen
            i = i + charLen(string.byte(msg, i))
          else
            break
          end
        end
        parts[#parts + 1] = render(entry, pics, string.sub(msg, start, i - 1))
      else
        parts[#parts + 1] = ch
      end
    end
    if changed then
      out = table.concat(parts)
    end
  end
  if d.smileys then
    out = string.gsub(" " .. out .. " ", "(%s)(%S+)(%f[%s])", function(pre, word)
      local code = C.SMILEYS[word]
      if code and C.byCode[code] then
        return pre .. render(C.byCode[code], pics, word)
      end
    end)
    out = string.sub(out, 2, -2)
  end
  if pics then
    -- Typed codes (:skull or :skull:) from anyone become pictures too.
    out = C.ReplaceShortcodes(out, function(entry, typed)
      return render(entry, pics, typed)
    end)
  end
  return out
end

function C.Decorate(msg, pics)
  if type(msg) ~= "string" or not string.find(msg, "|H", 1, true) then
    return decorateText(msg, pics)
  end
  -- Preserve both link metadata and the sender's exact label. Decoration outside links
  -- still works; shift-click and native tooltips receive the original complete link.
  local parts, first, i = {}, 1, 1
  while i <= #msg do
    local link = C.ReadLink(msg, i)
    if link then
      parts[#parts + 1] = decorateText(string.sub(msg, first, i - 1), pics)
      parts[#parts + 1] = link.full
      i, first = link.last + 1, link.last + 1
    elseif string.sub(msg, i, i + 1) == "||" then
      i = i + 2
    else
      i = i + 1
    end
  end
  parts[#parts + 1] = decorateText(string.sub(msg, first), pics)
  return table.concat(parts)
end

-- Finds :code and :code: (the closing colon is optional) for codes we know. The colon must start a
-- word, so 12:30 and item:1234 links stay as they are, and codes of one or two letters (:x, :ok)
-- need the closing colon so faces like :x stay faces. fn(entry, typed) returns the replacement.
function C.ReplaceShortcodes(msg, fn)
  if type(msg) ~= "string" or not string.find(msg, ":", 1, true) then
    return msg
  end
  local out, i, n = {}, 1, string.len(msg)
  while i <= n do
    local s, e, code = string.find(msg, ":([%w_]+)", i)
    if not s then
      break
    end
    local before = s > 1 and string.sub(msg, s - 1, s - 1) or ""
    local closed = string.sub(msg, e + 1, e + 1) == ":"
    local entry = C.byCode[string.lower(code)]
    if entry and not string.find(before, "[%w_]") and (closed or string.len(code) > 2) then
      local stop = closed and e + 1 or e
      out[#out + 1] = string.sub(msg, i, s - 1)
      out[#out + 1] = fn(entry, string.sub(msg, s, stop))
      i = stop + 1
    else
      out[#out + 1] = string.sub(msg, i, s)
      i = s + 1
    end
  end
  out[#out + 1] = string.sub(msg, i)
  return table.concat(out)
end

-- :heart or :heart: -> the emoji's own text, for messages you send.
function C.ExpandShortcodes(msg)
  return C.ReplaceShortcodes(msg, function(entry)
    return entry.text
  end)
end

---------------------------------------------------------------------------
-- Chat log and copy text
---------------------------------------------------------------------------

C.log = {}
C.originals = {}

C.logColor = {}

-- r, g, b: the line colour the client passed to AddMessage (Cherry's chat window draws it).
function C.Log(i, msg, r, g, b)
  local list, colours = C.log[i], C.logColor[i]
  if not list then
    list, colours = {}, {}
    C.log[i], C.logColor[i] = list, colours
  end
  list[#list + 1] = msg
  colours[#list] = (type(r) == "number") and { r, g or 1, b or 1 } or false
  local over = #list - db().logLines
  if over > 0 then
    for _ = 1, over do
      table.remove(list, 1)
      table.remove(colours, 1)
    end
  end
  if C.OnLogged then
    pcall(C.OnLogged, i, over > 0 and over or 0)
  end
end

-- Chat text without colours, links and pictures: what you would type.
function C.Plain(msg)
  local s = tostring(msg or "")
  local parts, i = {}, 1
  while i <= #s do
    local token = string.sub(s, i, i + 1)
    local link = token == "|H" and C.ReadLink(s, i)
    if token == "||" then
      parts[#parts + 1], i = "|", i + 2
    elseif link then
      parts[#parts + 1], i = C.Plain(link.text), link.last + 1
    elseif string.match(s, "^|c%x%x%x%x%x%x%x%x", i) then
      i = i + 10
    elseif token == "|r" then
      i = i + 2
    elseif token == "|T" and controlEnd(s, "|t", i + 2) then
      i = controlEnd(s, "|t", i + 2) + 2
    else
      local nextPipe = string.find(s, "|", i + 1, true) or (#s + 1)
      parts[#parts + 1], i = string.sub(s, i, nextPipe - 1), nextPipe
    end
  end
  return table.concat(parts)
end

function C.CopyText(i, lines)
  local list = C.log[i] or {}
  lines = lines or db().copyLines
  local first = math.max(1, #list - lines + 1)
  local out = {}
  for k = first, #list do
    out[#out + 1] = C.Plain(list[k])
  end
  return table.concat(out, "\n"), #out
end

---------------------------------------------------------------------------
-- Hooks
---------------------------------------------------------------------------

C.hookFailed = {}

local function wrapAddMessage(i)
  local f = C.Chat(i)
  if not f or C.originals[f] then
    return
  end
  local ok, orig = pcall(function()
    return f.AddMessage
  end)
  orig = ok and C.Real(f, orig)
  if type(orig) ~= "function" then
    return
  end
  local wrapper = function(self, msg, ...)
    if type(msg) == "string" then
      if C.Crypt then
        msg = C.Crypt.Incoming(msg)
      end
      C.Log(i, msg, ...)
      if C.Win and C.Win.Owns(i) then
        return -- Cherry's Chat draws this window
      end
      local good, shown = pcall(C.Decorate, msg)
      if good then
        msg = shown
      end
    end
    return orig(self, msg, ...)
  end
  C.MarkOurs(wrapper)
  local set = pcall(function()
    f.AddMessage = wrapper
  end)
  if set and f.AddMessage == wrapper then
    C.originals[f] = orig
  else
    C.hookFailed[i] = true
  end
end

-- Fallback when a chat frame cannot be wrapped: catch the text in the chat event handler instead.
local function wrapChatEvent()
  if C.eventWrapped or type(ChatFrame_OnEvent) ~= "function" then
    return
  end
  C.eventWrapped = true
  local orig = C.Real("ChatFrame_OnEvent", ChatFrame_OnEvent)
  ChatFrame_OnEvent = C.MarkOurs(function(...)
    -- Which channel the lines printed now belong to (encrypted chat opens only that channel's key).
    local was = C.Crypt and C.Crypt.current
    if C.Crypt then
      local ev = (select(1, ...))
      C.Crypt.current = C.Crypt.ChannelFromEvent(type(ev) == "string" and ev or event)
    end
    local results = { pcall(C.OnChatEvent, orig, ...) }
    if C.Crypt then
      C.Crypt.current = was
    end
    if not results[1] then
      error(results[2], 0)
    end
    return unpack(results, 2)
  end)
end

-- The game's chat event. Only for a frame whose AddMessage could not be wrapped is the text caught
-- here (logged, decrypted, emoji swapped) before the game prints it.
function C.OnChatEvent(orig, ...)
  local frame = this
  local index
  for i = 1, C.MAX_WINDOWS do
    if C.Chat(i) == frame then
      index = i
    end
  end
  if not index or not C.hookFailed[index] or type(arg1) ~= "string" then
    return orig(...)
  end
  local raw = arg1
  local text = C.Crypt and C.Crypt.Incoming(raw) or raw
  C.Log(index, text)
  local good, shown = pcall(C.Decorate, text)
  arg1 = good and shown or text
  local results = { pcall(orig, ...) }
  arg1 = raw
  if not results[1] then
    error(results[2], 0)
  end
  return unpack(results, 2)
end

local function wrapSend()
  if C.sendWrapped or type(SendChatMessage) ~= "function" then
    return
  end
  C.sendWrapped = true
  local orig = C.Real("SendChatMessage", SendChatMessage)
  SendChatMessage = C.MarkOurs(function(msg, ...)
    if db().sendShortcodes then
      msg = C.ExpandShortcodes(msg)
    end
    if C.Crypt and C.Crypt.Outgoing(orig, msg, ...) then
      return
    end
    return orig(msg, ...)
  end)
end

function C.InstallHooks()
  for i = 1, C.MAX_WINDOWS do
    wrapAddMessage(i)
  end
  wrapChatEvent() -- always: also tells encrypted chat which channel a line is from
  wrapSend()
end

---------------------------------------------------------------------------
-- Font and window size
---------------------------------------------------------------------------

function C.Window(i)
  local w = db().windows
  w[i] = w[i] or {}
  return w[i]
end

function C.GetFontSize(i)
  local saved = C.Window(i).font
  if saved then
    return saved
  end
  local f = C.Chat(i)
  if has(f, "GetFont") then
    local ok, _, size = pcall(f.GetFont, f)
    if ok and type(size) == "number" then
      return math.floor(size + 0.5)
    end
  end
  if GetChatWindowInfo then
    local ok, _, size = pcall(GetChatWindowInfo, i)
    if ok and type(size) == "number" and size > 0 then
      return size
    end
  end
  return 14
end

-- Tries the ways a RoM chat frame might take a font size; remembers the one that worked.
function C.SetFont(i, size)
  local f = C.Chat(i)
  if not f then
    return false
  end
  if has(f, "GetFont") and has(f, "SetFont") then
    local ok, file, _, flags = pcall(f.GetFont, f)
    if ok and file then
      if pcall(f.SetFont, f, file, size, flags) then
        C.fontWay = "SetFont"
        return true
      end
    end
  end
  for _, method in ipairs({ "SetFontSize", "SetFontHeight" }) do
    if try(f, method, size) then
      C.fontWay = method
      return true
    end
  end
  if type(FCF_SetChatWindowFontSize) == "function" and pcall(FCF_SetChatWindowFontSize, f, size) then
    C.fontWay = "FCF_SetChatWindowFontSize"
    return true
  end
  return false
end

function C.GetSize(i)
  local saved, f = C.Window(i), C.Chat(i)
  local w, h = saved.w, saved.h
  if not w and has(f, "GetWidth") then
    w = f:GetWidth()
  end
  if not h and has(f, "GetHeight") then
    h = f:GetHeight()
  end
  return math.floor((w or 400) + 0.5), math.floor((h or 180) + 0.5)
end

function C.SetFrameSize(i, w, h)
  local f = C.Chat(i)
  if not f then
    return false
  end
  if try(f, "SetSize", w, h) then
    return true
  end
  local a = try(f, "SetWidth", w)
  local b = try(f, "SetHeight", h)
  return a or b
end

local function targets(i)
  if not db().allWindows then
    return { i }
  end
  local list = {}
  for k = 1, C.MAX_WINDOWS do
    if C.Chat(k) then
      list[#list + 1] = k
    end
  end
  return list
end

function C.ChangeFont(i, size)
  size = math.max(C.MIN_FONT, math.min(C.MAX_FONT, math.floor(size + 0.5)))
  local ok = false
  for _, k in ipairs(targets(i)) do
    C.Window(k).font = size
    ok = C.SetFont(k, size) or ok
  end
  if not ok then
    print("this client did not take a font size. Please send the /cchat probe lines to Cherry.")
  end
  C.Refresh()
  return ok
end

function C.ChangeSize(i, w, h)
  w = math.max(C.MIN_W, math.floor(w + 0.5))
  h = math.max(C.MIN_H, math.floor(h + 0.5))
  for _, k in ipairs(targets(i)) do
    C.Window(k).w, C.Window(k).h = w, h
    C.SetFrameSize(k, w, h)
  end
  C.Refresh()
end

function C.ResetWindow(i)
  for _, k in ipairs(targets(i)) do
    db().windows[k] = nil
  end
  print("saved sizes cleared. Reload UI to get the client's own sizes back.")
  C.Refresh()
end

function C.ApplySaved()
  for i, w in pairs(db().windows) do
    if type(i) == "number" and C.Chat(i) then
      if w.font then
        C.SetFont(i, w.font)
      end
      if w.w and w.h then
        C.SetFrameSize(i, w.w, w.h)
      end
    end
  end
end

---------------------------------------------------------------------------
-- Drag to resize: a grip on the top right corner of the chat window you are looking at.
-- Follows GetCursorPos (screen style, +y down) while the mouse button is held.
---------------------------------------------------------------------------

C.gripOn = false

function C.PlaceGrip()
  local grip = CherrysChat_Grip
  if not grip then
    return
  end
  if not C.gripOn then
    grip:Hide()
    return
  end
  local i = C.CurrentIndex()
  C.gripIndex = i
  try(grip, "ClearAllAnchors")
  try(grip, "SetAnchor", "CENTER", "TOPRIGHT", C.Chat(i), 0, 0)
  grip:Show()
end

function C.ToggleGrip(on)
  if on == nil then
    on = not C.gripOn
  end
  C.gripOn = on
  C.PlaceGrip()
  if on then
    print("drag the pink corner on the chat window to resize it. Turn it off in Settings when done.")
  end
  C.Refresh()
end

function C.GripDown()
  if not GetCursorPos then
    return
  end
  local x, y = GetCursorPos()
  local w, h = C.GetSize(C.gripIndex or 1)
  C.drag = { x = x, y = y, w = w, h = h, scale = (GetUIScale and GetUIScale()) or 1 }
end

function C.GripUp()
  if C.drag then
    C.drag = nil
    local w, h = C.GetSize(C.gripIndex or 1)
    print("chat window size " .. w .. " x " .. h)
  end
end

function C.GripUpdate()
  local d = C.drag
  if not d then
    return
  end
  local x, y = GetCursorPos()
  local scale = (d.scale and d.scale > 0) and d.scale or 1
  -- Right makes it wider, up makes it taller.
  C.ChangeSize(C.gripIndex or 1, d.w + (x - d.x) / scale, d.h - (y - d.y) / scale)
end

---------------------------------------------------------------------------
-- Copy window
---------------------------------------------------------------------------

C.copyIndex = 1

function C.ShowCopy(i)
  if not CherrysChat_Copy then
    return
  end
  C.copyIndex = i or C.CurrentIndex()
  local text, count = C.CopyText(C.copyIndex)
  CherrysChat_CopyBox:SetText(text)
  CherrysChat_CopyTitle:SetText("Copy chat: " .. C.WindowName(C.copyIndex) .. "  |cffaaaaaa(" .. count .. " lines)|r")
  CherrysChat_Copy:Show()
  C.SelectAll()
end

function C.CopyStep(delta)
  local i = C.copyIndex
  for _ = 1, C.MAX_WINDOWS do
    i = i + delta
    if i < 1 then
      i = C.MAX_WINDOWS
    elseif i > C.MAX_WINDOWS then
      i = 1
    end
    if C.Chat(i) then
      break
    end
  end
  C.ShowCopy(i)
end

function C.SelectAll()
  try(CherrysChat_CopyBox, "SetFocus")
  try(CherrysChat_CopyBox, "HighlightText")
end

-- Copy messages, same wording and colours as KittyCombo.
C.COPIED = "|cff60ff60Copied to Windows clipboard!|r"
C.PRESS_CTRL_C = "|cffff6060Press Ctrl+C to copy!|r"

-- RoM has a Chat_CopyToClipboard; what it takes is not documented, so it is tried with the text.
function C.ToClipboard()
  local text = C.CopyText(C.copyIndex)
  if string.len(text) <= C.Win.ClipMax() and type(Chat_CopyToClipboard) == "function" and pcall(Chat_CopyToClipboard, text) then
    print(C.COPIED)
  else
    C.SelectAll()
    print(C.PRESS_CTRL_C)
  end
end

function C.PlaceCopyButton()
  local b = CherrysChat_CopyButton
  if not b then
    return
  end
  -- Not needed while Cherry's Chat draws the chat: the lines can be painted directly.
  if not (db().copyButton and C.active) or (C.Win and C.Win.Owns(1)) then
    b:Hide()
    return
  end
  try(b, "ClearAllAnchors")
  try(b, "SetAnchor", "TOPRIGHT", "TOPRIGHT", C.Chat(1) or UIParent, 0, -22)
  b:Show()
end

---------------------------------------------------------------------------
-- Select mode: a read-only text box laid exactly over the chat window, holding the lines you
-- see. Drag over lines to pick them, Ctrl+C to copy. The game's own chat is not a text field, so
-- this is the closest RoM allows. Esc, X, or the C button again goes back to the normal chat.
---------------------------------------------------------------------------

C.selOffset = 0

local function lineHeight(i)
  return C.GetFontSize(i) * 1.25
end

function C.SelectLines(i, offset)
  local list = C.log[i] or {}
  local _, h = C.GetSize(i)
  local fit = math.max(3, math.floor((h - 12) / lineHeight(i)))
  offset = math.max(0, math.min(offset or 0, math.max(0, #list - fit)))
  local last = #list - offset
  local out = {}
  for k = math.max(1, last - fit + 1), last do
    out[#out + 1] = C.Plain(list[k])
  end
  return table.concat(out, "\n"), offset
end

function C.IsSelecting()
  return CherrysChat_Select ~= nil and CherrysChat_Select:IsVisible()
end

function C.RefreshSelect()
  local i = C.selIndex or 1
  local text, offset = C.SelectLines(i, C.selOffset)
  C.selOffset, C.selText = offset, text
  CherrysChat_SelectBox:SetText(text)
  local more = offset > 0 and ("  |cffffd100" .. offset .. " newer lines below|r") or ""
  CherrysChat_SelectTitle:SetText("Select, then Ctrl+C" .. more)
end

function C.ShowSelect(i)
  if not CherrysChat_Select then
    return
  end
  i = i or C.CurrentIndex()
  local chat = C.Chat(i)
  if not chat then
    return
  end
  C.selIndex, C.selOffset = i, 0
  local w, h = C.GetSize(i)
  try(CherrysChat_Select, "ClearAllAnchors")
  try(CherrysChat_Select, "SetAnchor", "TOPLEFT", "TOPLEFT", chat, -4, -4)
  try(CherrysChat_Select, "SetSize", w + 8, h + 8)
  try(CherrysChat_SelectBox, "SetSize", w, h)
  if has(chat, "GetFont") then
    local ok, file, size = pcall(chat.GetFont, chat)
    if ok and file then
      try(CherrysChat_SelectBox, "SetFont", file, size)
    end
  end
  C.RefreshSelect()
  CherrysChat_Select:Show()
  try(CherrysChat_SelectBox, "SetFocus")
end

function C.HideSelect()
  if CherrysChat_Select then
    try(CherrysChat_SelectBox, "ClearFocus")
    CherrysChat_Select:Hide()
  end
end

function C.ToggleSelect(i)
  if C.IsSelecting() then
    C.HideSelect()
  else
    C.ShowSelect(i)
  end
end

-- delta > 0 = older lines (mouse wheel up).
function C.SelectScroll(delta)
  if not C.IsSelecting() then
    return
  end
  local step = (tonumber(delta) or 0) > 0 and 3 or -3
  C.selOffset = math.max(0, C.selOffset + step)
  C.RefreshSelect()
end

function C.SelectNewest()
  C.selOffset = 0
  C.RefreshSelect()
end

-- Keeps the box read-only: anything typed or pasted into it is put back.
function C.SelectGuard()
  local box = CherrysChat_SelectBox
  if box and C.selText and box:GetText() ~= C.selText then
    box:SetText(C.selText)
  end
end

---------------------------------------------------------------------------
-- Settings window
---------------------------------------------------------------------------

C.selected = 1

local function setText(obj, text)
  if obj and has(obj, "SetText") then
    obj:SetText(text)
  end
end

-- Pictures stay out of the cycle: RoM chat cannot draw them (in game, 2026-10-26).
local EMOJI_MODES = { "symbols", "text", "off" }
local EMOJI_LABELS = { symbols = "Symbols (^_^)", text = "Text (:smile:)", pictures = "Pictures", off = "Off" }

local function onOff(v)
  return v and "|cff60ff60on|r" or "|cffff6060off|r"
end

function C.Refresh()
  if not CherrysChat_Settings then
    return
  end
  local d, i = db(), C.selected
  local w, h = C.GetSize(i)
  setText(CherrysChat_SettingsTitle, "Cherry's Chat  " .. C.version)
  C.SetDropDown(CherrysChat_WindowDropDown, C.WindowName(i) .. "  (" .. i .. ")")
  setText(CherrysChat_FontLabel, "Font size: " .. C.GetFontSize(i))
  setText(CherrysChat_WidthLabel, "Width: " .. w)
  setText(CherrysChat_HeightLabel, "Height: " .. h)
  setText(CherrysChat_AllButton, "All windows: " .. onOff(d.allWindows))
  setText(CherrysChat_GripButton, "Drag to resize: " .. onOff(C.gripOn))
  setText(CherrysChat_EmojiButton, "Game chat emoji: " .. EMOJI_LABELS[d.emoji])
  setText(CherrysChat_SmileyButton, ":) <3 as emoji: " .. onOff(d.smileys))
  setText(CherrysChat_SendButton, ":heart: when sending: " .. onOff(d.sendShortcodes))
  setText(CherrysChat_CopyToggle, "Copy button on chat: " .. onOff(d.copyButton))
  if C.Crypt then
    C.Crypt.RefreshUI()
  end
  if C.Win then
    setText(CherrysChat_WinButton, "Experimental overlay: " .. onOff(C.Win.Config().on and not C.Win.broken))
  end
end

function C.Settings(action)
  local d, i = db(), C.selected
  if action == "prev" or action == "next" then
    local step = action == "prev" and -1 or 1
    for _ = 1, C.MAX_WINDOWS do
      i = i + step
      if i < 1 then
        i = C.MAX_WINDOWS
      elseif i > C.MAX_WINDOWS then
        i = 1
      end
      if C.Chat(i) then
        break
      end
    end
    C.selected = i
  elseif action == "font-" or action == "font+" then
    C.ChangeFont(i, C.GetFontSize(i) + (action == "font+" and C.FONT_STEP or -C.FONT_STEP))
  elseif action == "w-" or action == "w+" or action == "h-" or action == "h+" then
    local w, h = C.GetSize(i)
    local step = string.sub(action, 2) == "+" and C.SIZE_STEP or -C.SIZE_STEP
    if string.sub(action, 1, 1) == "w" then
      w = w + step
    else
      h = h + step
    end
    C.ChangeSize(i, w, h)
  elseif action == "all" then
    d.allWindows = not d.allWindows
  elseif action == "grip" then
    C.ToggleGrip()
  elseif action == "emoji" then
    local nextMode = EMOJI_MODES[1]
    for k, mode in ipairs(EMOJI_MODES) do
      if mode == d.emoji then
        nextMode = EMOJI_MODES[k % #EMOJI_MODES + 1]
      end
    end
    d.emoji = nextMode
  elseif action == "style" then
    d.emojiStyle = d.emojiStyle % C.STYLES + 1
    C.TestEmoji()
  elseif action == "esize-" or action == "esize+" then
    local size = d.emojiSize == 0 and C.GetFontSize(i) or d.emojiSize
    size = size + (action == "esize+" and 2 or -2)
    d.emojiSize = (size < C.MIN_FONT) and 0 or math.min(64, size)
  elseif action == "smileys" then
    d.smileys = not d.smileys
  elseif action == "send" then
    d.sendShortcodes = not d.sendShortcodes
  elseif action == "copybutton" then
    d.copyButton = not d.copyButton
    C.PlaceCopyButton()
  elseif action == "copy" then
    C.ShowCopy(i)
  elseif action == "window" then
    C.Win.Toggle()

  elseif action == "test" then
    C.TestEmoji()
  elseif action == "probe" then
    C.Probe()
  elseif action == "reset" then
    C.ResetWindow(i)
  end
  C.Refresh()
end

-- Shows text on a game dropdown (its <name>Text FontString).
function C.SetDropDown(frame, text)
  local ok, name = false, nil
  if frame and type(frame.GetName) == "function" then
    ok, name = pcall(frame.GetName, frame)
  end
  local fs = ok and type(name) == "string" and _G[name .. "Text"]
  if fs then
    fs:SetText(text)
  end
end

-- Window dropdown: every chat window the game has, by its tab name.
function C.WindowMenu()
  for i = 1, C.MAX_WINDOWS do
    if C.Chat(i) then
      local index = i
      UIDropDownMenu_AddButton({
        text = C.WindowName(i) .. "  (" .. i .. ")",
        checked = i == C.selected,
        func = function()
          C.selected = index
          CloseDropDownMenus()
          C.Refresh()
        end,
      }, 1)
    end
  end
end

function C.InitDropDowns()
  if C.dropDownsReady or type(UIDropDownMenu_Initialize) ~= "function" then
    return
  end
  C.dropDownsReady = true
  if CherrysChat_WindowDropDown then
    UIDropDownMenu_Initialize(CherrysChat_WindowDropDown, C.WindowMenu)
    pcall(UIDropDownMenu_SetWidth, CherrysChat_WindowDropDown, 170)
  end
  if CherrysChat_KeyDropDown and C.Crypt then
    UIDropDownMenu_Initialize(CherrysChat_KeyDropDown, C.Crypt.Menu)
    pcall(UIDropDownMenu_SetWidth, CherrysChat_KeyDropDown, 150)
  end
end

function C.ToggleSettings()
  if not CherrysChat_Settings then
    return
  end
  if CherrysChat_Settings:IsVisible() then
    CherrysChat_Settings:Hide()
  else
    C.selected = C.CurrentIndex()
    pcall(C.InitDropDowns)
    if C.Crypt then
      C.Crypt.ShowKey() -- also refreshes
    else
      C.Refresh()
    end
    CherrysChat_Settings:Show()
  end
end

---------------------------------------------------------------------------
-- Probe and test lines
---------------------------------------------------------------------------

-- RoM chat cannot draw pictures (in game, 2026-10-26), so the test shows emoji the way the chosen
-- Emoji setting does: a symbol, :code: text, or the raw character.
function C.TestEmoji()
  local parts = {}
  for _, code in ipairs({ "smile", "heart", "thumbsup", "fire", "skull", "cat", "carrot", "star" }) do
    local e = C.byCode[code]
    if e then
      parts[#parts + 1] = ":" .. code .. " " .. e.text
    end
  end
  print("emoji test: " .. table.concat(parts, "  "))
  print("Cherry's chat draws these as pictures; the game's chat shows them as " .. db().emoji
    .. ". /cchat emojis lists all " .. #(CherrysChat_EmojiList or {}) .. ".")
end

-- /cchat emojis: every emoji with its code, a few per line.
function C.ListEmoji()
  local line = {}
  for k, e in ipairs(CherrysChat_EmojiList or {}) do
    line[#line + 1] = e[2] .. " :" .. e[1]
    if #line == 6 or k == #CherrysChat_EmojiList then
      print(table.concat(line, "   "))
      line = {}
    end
  end
end

C.PROBE_METHODS = { "AddMessage", "GetFont", "SetFont", "SetFontSize", "SetFontHeight", "GetFontObject",
  "SetFontObject", "SetSize", "SetWidth", "SetHeight", "GetWidth", "GetHeight", "GetNumMessages",
  "GetMessageInfo", "GetNumLinesDisplayed", "SetMaxLines", "GetMaxLines", "SetMaxResize", "SetMinResize",
  "SetResizable", "StartSizing", "SetAnchor", "GetLeft", "GetTop" }

-- Numbered symbols, so a box (the font lacks it) can be named and swapped out.
function C.TestSymbols()
  local list = CherrysChat_SymbolTest or {}
  for start = 1, #list, 8 do
    local parts = {}
    for k = start, math.min(#list, start + 7) do
      parts[#parts + 1] = k .. "=" .. list[k]
    end
    print("symbols: " .. table.concat(parts, "  "))
  end
  local samples = {}
  local d = db()
  local mode = d.emoji
  d.emoji = "symbols"
  for _, code in ipairs({ "smile", "heart", "star", "thumbsup", "sunny", "cry" }) do
    samples[#samples + 1] = render(C.byCode[code])
  end
  d.emoji = mode
  print("as chat shows them: " .. table.concat(samples, " "))
end

-- /cchat lab: what a rewritten chat window would need. Results in chat and CherrysChat_DB.lab.
C.LAB_FONT_METHODS = { "SetFont", "GetFont", "GetStringWidth", "GetStringHeight", "GetWidth", "GetHeight",
  "GetText", "SetJustifyHType", "SetJustifyVType", "SetSpacing", "SetWordWrap", "SetNonSpaceWrap", "GetNumLines" }
C.LAB_EDIT_METHODS = { "SetFont", "HighlightText", "SetCursorPosition", "GetCursorPosition", "Insert",
  "SetMultiLine", "IsMultiLine", "SetTextColor", "SetColor", "EnableMouseWheel" }

function C.Lab()
  if not CherrysChat_Lab then
    return
  end
  local lab = { fontMethods = {}, editMissing = {} }
  for _, m in ipairs(C.LAB_FONT_METHODS) do
    lab.fontMethods[#lab.fontMethods + 1] = m .. (has(CherrysChat_Lab1, m) and "+" or "-")
  end
  for _, m in ipairs(C.LAB_EDIT_METHODS) do
    lab.fontMethods[#lab.fontMethods + 1] = "edit." .. m .. (has(CherrysChat_LabEdit, m) and "+" or "-")
  end
  -- 1: colour codes in a FontString. 2 and 3: a font file shipped by an addon.
  CherrysChat_Lab1:SetText("1 |cffff4040red|r |cff60ff60green|r normal  \226\153\165\226\152\133\226\152\186")
  local fira = ((CherrysKit_Paths and CherrysKit_Paths.RomWeakAuras) or "Interface/AddOns/RomWeakAuras/") .. "Media/Fonts/"
  CherrysChat_Lab2:SetText("2 Fira Sans font? The quick brown fox 123")
  CherrysChat_Lab3:SetText("3 Fira Mono font? The quick brown fox 123")
  lab.font2 = { pcall(CherrysChat_Lab2.SetFont, CherrysChat_Lab2, fira .. "FiraSans-Heavy.ttf", 18) }
  lab.font3 = { pcall(CherrysChat_Lab3.SetFont, CherrysChat_Lab3, fira .. "FiraMono-Medium.ttf", 16) }
  lab.font2[1], lab.font3[1] = tostring(lab.font2[1]), tostring(lab.font3[1])
  -- 4: how wide text is, for placing pictures and hit-testing the mouse.
  CherrysChat_Lab4:SetText("4 WWWWWWWWWW")
  local okW, width = pcall(function()
    return CherrysChat_Lab4:GetStringWidth()
  end)
  lab.stringWidth = okW and width or "missing"
  -- Colour codes inside a text box (would let a selectable chat keep its colours).
  CherrysChat_LabEdit:SetText("edit box: |cffff4040red|r |cff60ff60green|r normal\nsecond line")
  lab.clicks = {}
  CherrysChat_Lab:Show()
  db().lab = lab
  print("lab: " .. table.concat(lab.fontMethods, " "))
  print("lab: font2 " .. lab.font2[1] .. " font3 " .. lab.font3[1] .. "  width of 10 W at 16: " .. tostring(lab.stringWidth))
end

function C.LabClick(key)
  if not (CherrysChat_Lab and GetCursorPos) then
    return
  end
  local x, y = GetCursorPos()
  local f = CherrysChat_Lab
  local function num(m)
    local ok, v = pcall(function()
      return f[m](f)
    end)
    return ok and v and math.floor(v + 0.5) or "?"
  end
  local line = "click " .. x .. "," .. y .. "  window left " .. num("GetLeft") .. " top " .. num("GetTop") ..
    " w " .. num("GetWidth") .. " h " .. num("GetHeight") .. "  scale " .. tostring(GetUIScale and GetUIScale())
  local lab = db().lab
  if lab then
    lab.clicks[#lab.clicks + 1] = line
  end
  print(line)
end

function C.Probe()
  local f = C.Chat(1)
  local present, missing = {}, {}
  for _, m in ipairs(C.PROBE_METHODS) do
    table.insert(has(f, m) and present or missing, m)
  end
  local result = {
    version = C.version,
    frameType = type(f),
    present = present,
    missing = missing,
    hooked = {},
    fontWay = C.fontWay,
  }
  for i = 1, C.MAX_WINDOWS do
    if C.Chat(i) then
      result.hooked[#result.hooked + 1] = i .. "=" .. (C.originals[C.Chat(i)] and "yes" or (C.hookFailed[i] and "no" or "?"))
    end
  end
  if has(f, "GetFont") then
    result.font = { pcall(f.GetFont, f) }
  end
  if GetChatWindowInfo then
    result.windowInfo = { pcall(GetChatWindowInfo, 1) }
  end
  local globals = {}
  for _, g in ipairs({ "GetChatWindowInfo", "SetChatWindowSize", "FCF_SetChatWindowFontSize", "Chat_CopyToClipboard",
    "ChatFrame_OnEvent", "SendChatMessage", "SELECTED_CHAT_FRAME", "SELECTED_DOCK_FRAME", "GetCursorPos", "GetUIScale" }) do
    globals[#globals + 1] = g .. (_G[g] ~= nil and "+" or "-")
  end
  result.globals = globals
  db().probe = result

  print("probe 1/4: chat frame is a " .. type(f) .. ", wrapped: " .. table.concat(result.hooked, " "))
  print("probe 2/4: has " .. table.concat(present, ", "))
  print("probe 3/4: missing " .. table.concat(missing, ", "))
  print("probe 4/4: " .. table.concat(globals, " ") .. (result.font and ("  font " .. tostring(result.font[2]) .. " " .. tostring(result.font[3])) or ""))
  print("saved in CherrysChat_DB.probe too.")
end

---------------------------------------------------------------------------
-- Start up
---------------------------------------------------------------------------

function C.IsOffInKit()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("CherrysChat")
end

C.timers = {}

function C.After(seconds, fn)
  C.timers[#C.timers + 1] = { left = seconds, fn = fn }
end

function C.OnUpdate(elapsed)
  if C.drag then
    C.GripUpdate()
  end
  if C.Win then
    C.Win.Update(elapsed)
  end
  if #C.timers == 0 then
    return
  end
  local due = {}
  for k = #C.timers, 1, -1 do
    local t = C.timers[k]
    t.left = t.left - (elapsed or 0)
    if t.left <= 0 then
      table.remove(C.timers, k)
      due[#due + 1] = t.fn
    end
  end
  for _, fn in ipairs(due) do
    pcall(fn)
  end
end

function C.Start()
  if C.started then
    C.ApplySaved()
    return
  end
  C.started = true
  db()
  if C.IsOffInKit() then
    C.active = false
    return
  end
  C.active = true
  try(CherrysChat_GripTexture, "SetTexture", C.BasePath() .. "Media/Grip.tga")
  C.InstallHooks()
  C.ApplySaved()
  -- The client lays out its chat windows during loading too; put our sizes back after it.
  C.After(2, C.ApplySaved)
  C.After(8, C.ApplySaved)
  C.PlaceCopyButton()
  if C.Win then
    C.Win.Apply()
  end
end

function C.OnEvent(event)
  if event == "VARIABLES_LOADED" or event == "LOADING_END" then
    C.Start()
  end
end

function C.Slash(msg)
  local cmd, rest = string.match(tostring(msg or ""), "^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd)
  local rawRest = rest -- keys keep their capitals
  rest = string.lower(rest)
  if C.IsOffInKit() then
    print("turned off in Cherry's Kit. Type /ck to turn it on, then Reload UI.")
    return
  end
  local i = C.CurrentIndex()
  if cmd == "" or cmd == "settings" then
    C.ToggleSettings()
  elseif cmd == "copy" then
    C.ShowCopy(i)
  elseif cmd == "select" then
    C.ToggleSelect(i)
  elseif cmd == "font" and tonumber(rest) then
    C.ChangeFont(i, tonumber(rest))
  elseif cmd == "size" then
    local w, h = string.match(rest, "^(%d+)%D+(%d+)$")
    if w then
      C.ChangeSize(i, tonumber(w), tonumber(h))
    else
      print("/cchat size <width> <height>, for example /cchat size 600 300")
    end
  elseif cmd == "resize" then
    C.ToggleGrip()
  elseif cmd == "style" and tonumber(rest) then
    db().emojiStyle = math.max(1, math.min(C.STYLES, tonumber(rest)))
    C.TestEmoji()
  elseif cmd == "window" then
    C.Win.Toggle()

  elseif cmd == "measuretest" then
    C.Win.MeasureTest()
  elseif cmd == "measure" then
    local n = tonumber(rest)
    if n then
      C.Win.SetMeasureScale(n > 0 and n or nil)
    end
    print("text width factor " .. C.Win.MeasureScale() .. " (/cchat measure <number>, 0 = automatic). Test: lol "
      .. C.byCode.fire.text .. " there " .. C.byCode.heart.text)
  elseif cmd == "key" then
    C.Crypt.Slash(rawRest)
  elseif cmd == "cliptest" then
    C.Win.ClipTest()
  elseif cmd == "clipmax" and tonumber(rest) then
    db().clipMax = math.max(50, math.floor(tonumber(rest)))
    print("texts longer than " .. db().clipMax .. " letters are copied through the box (Ctrl+C).")
  elseif cmd == "linktest" then
    C.Win.LinkTest()
  elseif cmd == "linkprobe" then
    C.Win.LinkProbe(i)
  elseif cmd == "lab" then
    C.Lab()
  elseif cmd == "symbols" then
    C.TestSymbols()
  elseif cmd == "emoji" then
    C.TestEmoji()
  elseif cmd == "emojis" then
    C.ListEmoji()
  elseif cmd == "probe" then
    C.Probe()
  elseif cmd == "reset" then
    C.ResetWindow(i)
  else
    print("/cchat (settings), /cchat window, /cchat linktest, /cchat linkprobe, /cchat cliptest, /cchat clipmax <n>, /cchat select, /cchat symbols, /cchat copy, /cchat font <size>, /cchat size <w> <h>, /cchat resize, /cchat emoji, /cchat emojis, /cchat key <channel> <key>, /cchat measure <n>, /cchat probe, /cchat reset")
  end
end

SlashCmdList = SlashCmdList or {}
SLASH_CherrysChat1 = "/cchat"
SLASH_CherrysChat2 = "/cherryschat"
SlashCmdList["CherrysChat"] = function(editBox, msg)
  C.Slash(type(editBox) == "string" and editBox or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "CherrysChat",
    title = "Cherry's Chat",
    version = C.version,
    installed = function()
      return true
    end,
    open = function()
      C.ToggleSettings()
      return true
    end,
  })
end
