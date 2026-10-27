-- Cherry's Chat: encrypted chat. Every channel (Guild, Party, Whisper ...) can have its own key.
-- Messages you send in a channel with a key go out as scrambled letters; players with the same key
-- see them as text again, everyone else sees gibberish. A channel without a key is left alone both
-- ways: nothing is encrypted and nothing is opened there.
--
-- This hides chat from people without the key. It is not strong security: the cipher is RC4-style
-- (additive), keys are kept in plain text in CherrysChat_DB (SavedVariables), and anyone with the key
-- reads everything sent with it.
--
-- Short lines: the text is packed with a fixed letter-frequency code first (common letters take 3-5
-- bits), and every sent letter carries 6 bits, so an encrypted line is about as long as the text
-- itself, often shorter. Wire format: "~k" + 2 salt letters + 2 check letters + the packed text.
-- The 64 letters have no vowels, so the game's word filter does not turn random letters into ***.
-- A wrong key or a damaged line fails the check and is left as it is.

local C = CherrysChat
local Cr = {}
C.Crypt = Cr

Cr.MARK = "~k"
Cr.ALPHABET = "bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ0123456789-_=+*#@$&!?." -- 64, no vowels
Cr.MAX_LEN = 240 -- letters per chat message we send (the game cuts long lines)
Cr.MAX_PARTS = 3 -- a longer message is refused rather than flooding the channel
-- Channels in the settings, in order. CHANNEL<n> is a numbered custom channel.
Cr.CHANNELS = { "GUILD", "PARTY", "RAID", "WHISPER", "SAY", "YELL", "ZONE", "CHANNEL1", "CHANNEL2", "CHANNEL3",
  "CHANNEL4", "CHANNEL5" }
Cr.NAMES = { GUILD = "Guild", PARTY = "Party", RAID = "Raid", WHISPER = "Whisper", SAY = "Say", YELL = "Yell",
  ZONE = "Zone" }

local decode = {}
for k = 1, 64 do
  decode[string.sub(Cr.ALPHABET, k, k)] = k - 1
end
-- The alphabet as a Lua pattern class.
Cr.CLASS = "[" .. string.gsub(Cr.ALPHABET, "%p", "%%%0") .. "]"

function Cr.Config()
  local d = C.DB()
  if type(d.crypt) ~= "table" then
    d.crypt = { on = true, keys = {} }
  end
  if type(d.crypt.keys) ~= "table" then
    d.crypt.keys = {}
  end
  return d.crypt
end

function Cr.Name(channel)
  return Cr.NAMES[channel] or string.gsub(channel, "^CHANNEL(%d+)$", "Channel %1")
end

---------------------------------------------------------------------------
-- Cipher
---------------------------------------------------------------------------

-- Keystream from key .. salt (RC4 key schedule, first 256 bytes dropped).
local function stream(key, salt)
  local S, k = {}, key .. "\0" .. salt
  local klen = string.len(k)
  for i = 0, 255 do
    S[i] = i
  end
  local j = 0
  for i = 0, 255 do
    j = (j + S[i] + string.byte(k, i % klen + 1)) % 256
    S[i], S[j] = S[j], S[i]
  end
  local i = 0
  j = 0
  local function nextByte()
    i = (i + 1) % 256
    j = (j + S[i]) % 256
    S[i], S[j] = S[j], S[i]
    return S[(S[i] + S[j]) % 256]
  end
  for _ = 1, 256 do
    nextByte()
  end
  return nextByte
end

-- 12-bit check of the text.
local function check(text)
  local a, b = 7, 13
  for p = 1, string.len(text) do
    a = (a + string.byte(text, p)) % 251
    b = (b + a) % 251
  end
  return (a * 251 + b) % 4096
end

-- Fixed prefix code (Huffman) over bytes 0-255 plus END (256), from rough chat letter frequencies.
-- Built once at load; the same on every client.
local function buildCode()
  local weight = {}
  for v = 0, 256 do
    weight[v] = v >= 128 and 0.02 or 0.03
  end
  local common = { [" "] = 180, e = 100, t = 75, a = 65, o = 62, i = 57, n = 57, s = 53, h = 49, r = 49, d = 34,
    l = 33, u = 23, c = 22, m = 20, w = 19, f = 18, g = 16, y = 16, p = 15, b = 12, v = 8, k = 6, x = 1.5,
    j = 1, q = 1, z = 1, ["."] = 6, [","] = 5, ["?"] = 4, ["!"] = 3, ["'"] = 4, [":"] = 2, [")"] = 1.5, ["("] = 1,
    ["-"] = 1.5, ['"'] = 1 }
  for ch, w in pairs(common) do
    weight[string.byte(ch)] = w
    local up = string.upper(ch)
    if up ~= ch then
      weight[string.byte(up)] = w * 0.08 + 0.5
    end
  end
  for d = 0, 9 do
    weight[48 + d] = 3
  end
  weight[256] = 3
  -- Huffman: repeatedly join the two lightest nodes (ties: lower id first).
  local nodes = {}
  for v = 0, 256 do
    nodes[#nodes + 1] = { w = weight[v], id = v, sym = v }
  end
  local nextId = 257
  while #nodes > 1 do
    table.sort(nodes, function(x, y)
      if x.w ~= y.w then
        return x.w < y.w
      end
      return x.id < y.id
    end)
    local x, y = table.remove(nodes, 1), table.remove(nodes, 1)
    nodes[#nodes + 1] = { w = x.w + y.w, id = nextId, [0] = x, [1] = y }
    nextId = nextId + 1
  end
  local codes = {}
  local function walk(node, prefix)
    if node.sym then
      codes[node.sym] = prefix
    else
      walk(node[0], prefix .. "0")
      walk(node[1], prefix .. "1")
    end
  end
  walk(nodes[1], "")
  return codes, nodes[1]
end
Cr.codes, Cr.tree = buildCode()

local function pushBits(bits, value, count)
  for p = count - 1, 0, -1 do
    local q = 2 ^ p
    local bit = math.floor(value / q)
    value = value - bit * q
    bits[#bits + 1] = bit
  end
end

local function salt()
  local a, b = math.random(1, 64), math.random(1, 64)
  return string.sub(Cr.ALPHABET, a, a) .. string.sub(Cr.ALPHABET, b, b)
end

function Cr.Encrypt(text, key, saltText)
  saltText = saltText or salt()
  local bits = {}
  pushBits(bits, check(text), 12)
  for p = 1, string.len(text) do
    local code = Cr.codes[string.byte(text, p)]
    for c = 1, string.len(code) do
      bits[#bits + 1] = string.byte(code, c) - 48
    end
  end
  local stop = Cr.codes[256]
  for c = 1, string.len(stop) do
    bits[#bits + 1] = string.byte(stop, c) - 48
  end
  while #bits % 6 ~= 0 do
    bits[#bits + 1] = 0
  end
  local nextByte = stream(key, saltText)
  local out = {}
  for p = 1, #bits, 6 do
    local v = 0
    for q = p, p + 5 do
      v = v * 2 + bits[q]
    end
    v = (v + nextByte()) % 64
    out[#out + 1] = string.sub(Cr.ALPHABET, v + 1, v + 1)
  end
  return Cr.MARK .. saltText .. table.concat(out)
end

-- body: what follows the mark (salt + letters). Returns the text, or nil for a wrong key.
function Cr.DecryptBody(body, key)
  local saltText, data = string.sub(body, 1, 2), string.sub(body, 3)
  if string.len(data) < 3 then
    return nil
  end
  local nextByte = stream(key, saltText)
  local bits = {}
  for p = 1, string.len(data) do
    local v = decode[string.sub(data, p, p)]
    if not v then
      return nil
    end
    pushBits(bits, (v - nextByte()) % 64, 6)
  end
  local sum = 0
  for p = 1, 12 do
    sum = sum * 2 + bits[p]
  end
  local chars, node, p = {}, Cr.tree, 13
  while true do
    if p > #bits then
      return nil -- no END: not ours
    end
    node = node[bits[p]]
    p = p + 1
    if node.sym then
      if node.sym == 256 then
        break
      end
      chars[#chars + 1] = string.char(node.sym)
      node = Cr.tree
    end
  end
  if #bits - p + 1 >= 6 then
    return nil -- more than padding left over
  end
  local text = table.concat(chars)
  if check(text) ~= sum then
    return nil
  end
  return text
end

---------------------------------------------------------------------------
-- Incoming: an encrypted line is opened with the key of the channel it came in on. Cr.current is
-- set while the game's chat event runs (CherrysChat.lua wraps ChatFrame_OnEvent). If the client
-- prints without that event, the channel is unknown and every key is tried.
---------------------------------------------------------------------------

-- CHAT_MSG_GUILD -> GUILD, CHAT_MSG_PARTY_LEADER -> PARTY, CHAT_MSG_WHISPER_INFORM -> WHISPER,
-- CHAT_MSG_CHANNEL -> CHANNEL<arg8> (CHANNEL when the number is unknown).
function Cr.ChannelFromEvent(ev)
  if type(ev) ~= "string" then
    return nil
  end
  local kind = string.match(ev, "^CHAT_MSG_(.+)$")
  if not kind then
    return nil
  end
  kind = string.gsub(kind, "_LEADER$", "")
  kind = string.gsub(kind, "_INFORM$", "")
  kind = string.gsub(kind, "_WARNING$", "")
  if kind == "CHANNEL" then
    local n = tonumber(arg8)
    return n and ("CHANNEL" .. n) or "CHANNEL"
  end
  return kind
end

-- Keys to try for a line from channel (nil = unknown: all).
function Cr.KeysFor(channel)
  local keys, cfg = {}, Cr.Config()
  for ch, key in pairs(cfg.keys) do
    if type(key) == "string" and key ~= "" then
      if channel == nil or ch == channel or (channel == "CHANNEL" and string.find(ch, "^CHANNEL%d")) then
        keys[#keys + 1] = key
      end
    end
  end
  return keys
end

local function lockMark()
  local e = C.byCode and C.byCode.lock
  return (e and e.text or "|cff80ff80[locked]|r") .. " "
end

function Cr.Incoming(msg)
  if type(msg) ~= "string" or not string.find(msg, Cr.MARK, 1, true) then
    return msg
  end
  local cfg = Cr.Config()
  if not cfg.on then
    return msg
  end
  local keys = Cr.KeysFor(Cr.current)
  if #keys == 0 then
    return msg
  end
  return (string.gsub(msg, Cr.MARK .. "(" .. Cr.CLASS .. "+)", function(body)
    for _, key in ipairs(keys) do
      local text = Cr.DecryptBody(body, key)
      if text then
        -- Shown as plain words: colour codes and links from the sender are not drawn.
        return lockMark() .. (string.gsub(text, "|", "||"))
      end
    end
  end))
end

---------------------------------------------------------------------------
-- Outgoing
---------------------------------------------------------------------------

-- Which channel a SendChatMessage call goes to: its type, plus the number for custom channels.
function Cr.ChannelOf(kind, ...)
  kind = string.upper(tostring(kind or "SAY"))
  if kind == "CHANNEL" then
    for p = 1, select("#", ...) do
      local v = tonumber((select(p, ...)))
      if v then
        return "CHANNEL" .. v
      end
    end
  end
  return kind
end

function Cr.KeyFor(channel)
  local cfg = Cr.Config()
  local key = cfg.on and cfg.keys[channel]
  return (type(key) == "string" and key ~= "") and key or nil
end

-- Splits text at spaces into parts whose encrypted line fits MAX_LEN letters (almost never needed:
-- an encrypted line is about as long as the text).
function Cr.Split(text, key)
  if string.len(Cr.Encrypt(text, key, "bb")) <= Cr.MAX_LEN then
    return { text }
  end
  local half = math.floor(string.len(text) / 2)
  local cut = string.find(text, " ", half, true) or half
  local a = string.sub(text, 1, cut)
  local b = string.gsub(string.sub(text, cut + 1), "^ ", "")
  if a == "" or b == "" then
    a, b = string.sub(text, 1, half), string.sub(text, half + 1)
  end
  local parts = Cr.Split(a, key)
  for _, part in ipairs(Cr.Split(b, key)) do
    parts[#parts + 1] = part
  end
  return parts
end

-- Sends msg encrypted when its channel has a key. Returns true when it handled the send.
function Cr.Outgoing(send, msg, kind, ...)
  if type(msg) ~= "string" or msg == "" then
    return false
  end
  local channel = Cr.ChannelOf(kind, ...)
  C.DB().lastChatType = channel -- for /cchat probe: how this client names its channels
  local key = Cr.KeyFor(channel)
  if not key then
    return false
  end
  local parts = Cr.Split(msg, key)
  if #parts > Cr.MAX_PARTS then
    C.Print("|cffff6060not sent|r: too long to encrypt (" .. string.len(msg) .. " letters).")
    return true
  end
  for _, part in ipairs(parts) do
    send(Cr.Encrypt(part, key), kind, ...)
  end
  return true
end

---------------------------------------------------------------------------
-- Settings: pick a channel, type its key, Enter saves. An empty key turns the channel off.
---------------------------------------------------------------------------

Cr.selected = Cr.selected or 1

function Cr.Selected()
  return Cr.CHANNELS[Cr.selected] or Cr.CHANNELS[1]
end

function Cr.Step(delta)
  Cr.selected = (Cr.selected - 1 + delta) % #Cr.CHANNELS + 1
  Cr.ShowKey()
end

function Cr.ShowKey()
  if CherrysChat_KeyBox then
    CherrysChat_KeyBox:SetText(Cr.Config().keys[Cr.Selected()] or "")
  end
  C.Refresh()
end

function Cr.SetKey(channel, key)
  key = key and string.gsub(key, "^%s+", "") or ""
  key = string.gsub(key, "%s+$", "")
  Cr.Config().keys[channel] = key ~= "" and key or nil
  C.Print(key ~= "" and ("|cff60ff60" .. Cr.Name(channel) .. " is encrypted.|r Players need the same key to read it.")
    or (Cr.Name(channel) .. " is no longer encrypted."))
  C.Refresh()
end

function Cr.SaveKeyBox()
  if CherrysChat_KeyBox then
    Cr.SetKey(Cr.Selected(), CherrysChat_KeyBox:GetText())
    pcall(CherrysChat_KeyBox.ClearFocus, CherrysChat_KeyBox)
  end
end

function Cr.Label(ch)
  return Cr.Name(ch) .. (Cr.Config().keys[ch] and "  |cff60ff60(on)|r" or "  |cffa0a0a0(off)|r")
end

-- Channel dropdown: every channel, green "on" where it has a key.
function Cr.Menu()
  for k, ch in ipairs(Cr.CHANNELS) do
    local index = k
    UIDropDownMenu_AddButton({
      text = Cr.Label(ch),
      checked = k == Cr.selected,
      func = function()
        Cr.selected = index
        CloseDropDownMenus()
        Cr.ShowKey()
      end,
    }, 1)
  end
end

function Cr.ClearKey()
  Cr.SetKey(Cr.Selected(), "")
  Cr.ShowKey()
end

-- Settings window lines.
function Cr.RefreshUI()
  local ch = Cr.Selected()
  C.SetDropDown(CherrysChat_KeyDropDown, Cr.Label(ch))
  if CherrysChat_KeyHint then
    local list = Cr.Encrypted()
    CherrysChat_KeyHint:SetText(#list > 0 and ("Encrypted: " .. table.concat(list, ", ") .. ". Same key = readable.")
      or "Type a key for a channel and press Enter. Empty key = normal chat.")
  end
end

function Cr.Encrypted()
  local list = {}
  for _, ch in ipairs(Cr.CHANNELS) do
    if Cr.Config().keys[ch] then
      list[#list + 1] = Cr.Name(ch)
    end
  end
  return list
end

-- /cchat key <channel> <key>, /cchat key <channel> (clears), /cchat encrypt (on/off)
function Cr.Slash(rest)
  local name, key = string.match(rest or "", "^(%S+)%s*(.*)$")
  if not name then
    local list = Cr.Encrypted()
    C.Print("encrypted: " .. (#list > 0 and table.concat(list, ", ") or "nothing")
      .. ". /cchat key <channel> <key> sets one, /cchat key <channel> clears it.")
    return
  end
  local channel = string.upper(name)
  for _, ch in ipairs(Cr.CHANNELS) do
    if string.upper(Cr.Name(ch)) == channel or ch == channel then
      Cr.SetKey(ch, key)
      return
    end
  end
  C.Print("unknown channel " .. name .. ". Channels: guild, party, raid, whisper, say, yell, zone, channel1-5.")
end
