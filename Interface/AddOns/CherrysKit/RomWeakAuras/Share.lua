-- Share.lua: auras as text codes, the same scheme as Cherry's KittyCombo (lib/KittyShare.lua).
-- Code: "RWA2!" .. base85(LZW(packed data)) .. "!" .. 4 hex checksum. Values equal to the defaults are left
-- out (they come back on import), and LZW compression makes codes about half as long.
-- Old "RWA1!" .. base64(data) .. "!" .. 8 hex codes are still accepted. The data is a tagged format parsed without
-- loadstring, so pasting a code can never run Lua (custom triggers come in as text and only run
-- like any other custom trigger once the aura is loaded).
--   T / F               boolean
--   n<number>;          number
--   s<length>:<bytes>   string
--   k<index>;           string key from KEY_ALIASES (keeps codes short)
--   { key value ... }   table

local RWA = RWA
local Share = {}
RWA.Share = Share

Share.PREFIX = "RWA3"
Share.ACTION_PREFIX = "RWA4"
Share.COMPACT_PREFIX = "RWA2"
Share.OLD_PREFIX = "RWA1"
Share.MAX_DEPTH = 16
Share.KEY_ALIASES = {
  "auras", "id", "enabled", "regionType", "triggers", "type", "unit", "filter", "names", "ids",
  "showOn", "check", "op", "value", "percent", "code", "mode", "x", "y", "width", "height",
  "fontSize", "font", "text", "text2", "color", "alpha", "texture", "blend", "animation", "start",
  "main", "finish", "sound", "conditions", "trigger", "var", "set", "load", "combat", "class",
  "level", "showIcon", "skill", "desc", "icon", "previewIcon",
}
local KEY_INDEX = {}
for i, key in ipairs(Share.KEY_ALIASES) do
  KEY_INDEX[key] = i
end

---------------------------------------------------------------------------
-- Serialize and parse
---------------------------------------------------------------------------

local function serializeValue(value, out, depth, isKey)
  local t = type(value)
  if t == "boolean" then
    out[#out + 1] = value and "T" or "F"
  elseif t == "number" then
    out[#out + 1] = "n" .. string.format("%.14g", value) .. ";"
  elseif t == "string" then
    if isKey and KEY_INDEX[value] then
      out[#out + 1] = "k" .. KEY_INDEX[value] .. ";"
    else
      out[#out + 1] = "s" .. string.len(value) .. ":" .. value
    end
  elseif t == "table" then
    if depth > Share.MAX_DEPTH then
      error("aura is nested too deeply to export")
    end
    out[#out + 1] = "{"
    local count = #value
    for i = 1, count do
      serializeValue(i, out, depth + 1, true)
      serializeValue(value[i], out, depth + 1, false)
    end
    for k, v in pairs(value) do
      local kt, vt = type(k), type(v)
      local isArrayKey = kt == "number" and k >= 1 and k <= count and math.floor(k) == k
      if not isArrayKey and (kt == "string" or kt == "number")
        and (vt == "string" or vt == "number" or vt == "boolean" or vt == "table") then
        serializeValue(k, out, depth + 1, true)
        serializeValue(v, out, depth + 1, false)
      end
    end
    out[#out + 1] = "}"
  else
    error("cannot export a value of type " .. t)
  end
end

function Share.Serialize(value)
  local out = {}
  serializeValue(value, out, 0, false)
  return table.concat(out)
end

local function parseValue(data, pos, depth)
  local tag = string.sub(data, pos, pos)
  if tag == "T" then
    return true, pos + 1
  elseif tag == "F" then
    return false, pos + 1
  elseif tag == "n" or tag == "k" then
    local stop = string.find(data, ";", pos + 1, true)
    local n = stop and tonumber(string.sub(data, pos + 1, stop - 1))
    if not n then
      error("bad number")
    end
    if tag == "k" then
      local key = Share.KEY_ALIASES[n]
      if not key then
        error("bad key")
      end
      return key, stop + 1
    end
    return n, stop + 1
  elseif tag == "s" then
    local colon = string.find(data, ":", pos + 1, true)
    local len = colon and tonumber(string.sub(data, pos + 1, colon - 1))
    if not len or len < 0 or colon + len > string.len(data) then
      error("bad string")
    end
    return string.sub(data, colon + 1, colon + len), colon + len + 1
  elseif tag == "{" then
    if depth > Share.MAX_DEPTH then
      error("too deep")
    end
    local result = {}
    pos = pos + 1
    while true do
      if pos > string.len(data) then
        error("unterminated table")
      end
      if string.sub(data, pos, pos) == "}" then
        return result, pos + 1
      end
      local key, value
      key, pos = parseValue(data, pos, depth + 1)
      if type(key) ~= "string" and type(key) ~= "number" then
        error("bad table key")
      end
      value, pos = parseValue(data, pos, depth + 1)
      result[key] = value
    end
  end
  error("bad data at " .. tostring(pos))
end

function Share.Parse(data)
  local value, pos = parseValue(data, 1, 0)
  if pos ~= string.len(data) + 1 then
    error("extra data")
  end
  return value
end

---------------------------------------------------------------------------
-- Base64 (Lua 5.1 has no bit operations) and checksum, as in KittyShare
---------------------------------------------------------------------------

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_INDEX = {}
for i = 1, 64 do
  B64_INDEX[string.sub(B64, i, i)] = i - 1
end

function Share.Base64Encode(data)
  local out = {}
  for i = 1, string.len(data), 3 do
    local a, b, c = string.byte(data, i, i + 2)
    local n = a * 65536 + (b or 0) * 256 + (c or 0)
    local c1, c2 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64
    local c3, c4 = math.floor(n / 64) % 64, n % 64
    out[#out + 1] = string.sub(B64, c1 + 1, c1 + 1) .. string.sub(B64, c2 + 1, c2 + 1)
      .. (b and string.sub(B64, c3 + 1, c3 + 1) or "=")
      .. (c and string.sub(B64, c4 + 1, c4 + 1) or "=")
  end
  return table.concat(out)
end

function Share.Base64Decode(text)
  text = string.gsub(text, "[^%w%+/=]", "")
  if string.len(text) % 4 ~= 0 then
    return nil
  end
  local out = {}
  for pos = 1, string.len(text), 4 do
    local s3, s4 = string.sub(text, pos + 2, pos + 2), string.sub(text, pos + 3, pos + 3)
    local v1, v2 = B64_INDEX[string.sub(text, pos, pos)], B64_INDEX[string.sub(text, pos + 1, pos + 1)]
    if v1 == nil or v2 == nil then
      return nil
    end
    local n = v1 * 262144 + v2 * 4096 + (B64_INDEX[s3] or 0) * 64 + (B64_INDEX[s4] or 0)
    out[#out + 1] = string.char(math.floor(n / 65536) % 256)
    if s3 ~= "=" then
      out[#out + 1] = string.char(math.floor(n / 256) % 256)
    end
    if s4 ~= "=" then
      out[#out + 1] = string.char(n % 256)
    end
  end
  return table.concat(out)
end

function Share.Checksum(data)
  local a, b = 1, 0
  for i = 1, string.len(data) do
    a = (a + string.byte(data, i)) % 65521
    b = (b + a) % 65521
  end
  return string.format("%04x%04x", b, a)
end

---------------------------------------------------------------------------
-- Compact format for RWA2 (shared with Cherry's KittyCombo CKC2):
--   T / F                    boolean
--   byte 224-255             whole number 0-31
--   n<number>;               any other number
--   byte 128-223             a string from WORDS (keys and common values), 1 byte each
--   s<length>:<bytes>        any other string
--   { values [= key value ...] }   a table: its array part in order, then "=" and the other keys
---------------------------------------------------------------------------

Share.WORDS = {
  -- keys
  "auras", "id", "enabled", "regionType", "triggers", "type", "unit", "filter", "names", "ids",
  "showOn", "check", "op", "value", "percent", "code", "mode", "x", "y", "width", "height",
  "fontSize", "font", "text", "text2", "color", "alpha", "texture", "blend", "animation", "start",
  "main", "finish", "sound", "conditions", "trigger", "var", "set", "load", "combat", "class",
  "level", "showIcon", "skill", "desc", "icon", "enemy", "bgColor", "point",
  -- common values
  "player", "target", "party1", "party2", "pet", "HELPFUL", "HARMFUL", "aura", "status", "custom",
  "active", "missing", "always", "ready", "cooldown", "all", "any", "remaining", "stacks", "health",
  "mana", "aurabar", "fade", "slide", "none", "pulse", "flash", "bounce", "<", "<=", ">", ">=", "==",
  "%n", "%p", "%s", "%t", "%v", "%pct", "Square_FullWhite", "Circle_White", "cast", "ADD",
  -- 0.8.0 (appended so older codes keep their bytes)
  "elements", "from", "side", "LEFT",
}
local WORD_INDEX = {}
for i, w in ipairs(Share.WORDS) do
  WORD_INDEX[w] = i
end
assert(#Share.WORDS <= 96, "Share.WORDS holds at most 96 words")

local function pack(value, out, depth)
  local t = type(value)
  if t == "boolean" then
    out[#out + 1] = value and "T" or "F"
  elseif t == "number" then
    if value >= 0 and value <= 31 and math.floor(value) == value then
      out[#out + 1] = string.char(224 + value)
    else
      out[#out + 1] = "n" .. string.format("%.14g", value) .. ";"
    end
  elseif t == "string" then
    if WORD_INDEX[value] then
      out[#out + 1] = string.char(127 + WORD_INDEX[value])
    else
      out[#out + 1] = "s" .. string.len(value) .. ":" .. value
    end
  elseif t == "table" then
    if depth > Share.MAX_DEPTH then
      error("aura is nested too deeply to export")
    end
    out[#out + 1] = "{"
    local count = #value
    for i = 1, count do
      pack(value[i], out, depth + 1)
    end
    local first = true
    for k, v in pairs(value) do
      local kt, vt = type(k), type(v)
      local isArrayKey = kt == "number" and k >= 1 and k <= count and math.floor(k) == k
      if not isArrayKey and (kt == "string" or kt == "number")
        and (vt == "string" or vt == "number" or vt == "boolean" or vt == "table") then
        if first then
          out[#out + 1] = "="
          first = false
        end
        pack(k, out, depth + 1)
        pack(v, out, depth + 1)
      end
    end
    out[#out + 1] = "}"
  else
    error("cannot export a value of type " .. t)
  end
end

function Share.Pack(value)
  local out = {}
  pack(value, out, 0)
  return table.concat(out)
end

local function unpackValue(data, pos, depth)
  local b = string.byte(data, pos)
  if not b then
    error("unexpected end")
  end
  if b >= 224 then
    return b - 224, pos + 1
  elseif b >= 128 then
    local w = Share.WORDS[b - 127]
    if not w then
      error("bad word")
    end
    return w, pos + 1
  end
  local tag = string.char(b)
  if tag == "T" then
    return true, pos + 1
  elseif tag == "F" then
    return false, pos + 1
  elseif tag == "n" then
    local stop = string.find(data, ";", pos + 1, true)
    local n = stop and tonumber(string.sub(data, pos + 1, stop - 1))
    if not n then
      error("bad number")
    end
    return n, stop + 1
  elseif tag == "s" then
    local colon = string.find(data, ":", pos + 1, true)
    local len = colon and tonumber(string.sub(data, pos + 1, colon - 1))
    if not len or len < 0 or colon + len > string.len(data) then
      error("bad string")
    end
    return string.sub(data, colon + 1, colon + len), colon + len + 1
  elseif tag == "{" then
    if depth > Share.MAX_DEPTH then
      error("too deep")
    end
    local result, n, hash = {}, 0, false
    pos = pos + 1
    while true do
      local c = string.sub(data, pos, pos)
      if c == "" then
        error("unterminated table")
      elseif c == "}" then
        return result, pos + 1
      elseif c == "=" and not hash then
        hash = true
        pos = pos + 1
      elseif hash then
        local key, value
        key, pos = unpackValue(data, pos, depth + 1)
        if type(key) ~= "string" and type(key) ~= "number" then
          error("bad table key")
        end
        value, pos = unpackValue(data, pos, depth + 1)
        result[key] = value
      else
        n = n + 1
        result[n], pos = unpackValue(data, pos, depth + 1)
      end
    end
  end
  error("bad data at " .. tostring(pos))
end

function Share.Unpack(data)
  local value, pos = unpackValue(data, 1, 0)
  if pos ~= string.len(data) + 1 then
    error("extra data")
  end
  return value
end

-- Base 85 for RWA2 bodies: 4 bytes become 5 characters (base 64 needs 5.33). The alphabet leaves
-- out characters chat treats specially or the code uses: | % \ " ' ` ! and space.
Share.B85 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#$&()*+,-./:;<=>?@[]^_{"
local B85_INDEX = {}
for i = 1, 85 do
  B85_INDEX[string.byte(Share.B85, i)] = i - 1
end
assert(string.len(Share.B85) == 85)

function Share.Base85Encode(data)
  local out = {}
  local len = string.len(data)
  for i = 1, len, 4 do
    local n, count = 0, math.min(4, len - i + 1)
    for j = 0, 3 do
      n = n * 256 + (string.byte(data, i + j) or 0)
    end
    local chars = {}
    for j = 5, 1, -1 do
      local d = n % 85
      chars[j] = string.sub(Share.B85, d + 1, d + 1)
      n = (n - d) / 85
    end
    out[#out + 1] = table.concat(chars, "", 1, count + 1)
  end
  return table.concat(out)
end

function Share.Base85Decode(text)
  local out = {}
  local len = string.len(text)
  for i = 1, len, 5 do
    local count = math.min(5, len - i + 1)
    if count < 2 then
      return nil
    end
    local n = 0
    for j = 0, 4 do
      local d = (j < count) and B85_INDEX[string.byte(text, i + j)] or 84
      if d == nil then
        return nil
      end
      n = n * 85 + d
    end
    local bytes = {}
    for j = 4, 1, -1 do
      local b = n % 256
      bytes[j] = string.char(b)
      n = (n - b) / 256
    end
    out[#out + 1] = table.concat(bytes, "", 1, count - 1)
  end
  return table.concat(out)
end

-- Short checksum for RWA2 codes: 4 hex digits.
function Share.ShortChecksum(data)
  return string.sub(Share.Checksum(data), 1, 4)
end

---------------------------------------------------------------------------
-- LZW compression with growing code width (9 bits and up), packed into bytes with arithmetic
-- (Lua 5.1 has no bit operations). The k-th code is written with just enough bits for 256 + k.
---------------------------------------------------------------------------

local function codeWidth(k)
  local width, limit = 9, 512
  while 256 + k >= limit do
    width, limit = width + 1, limit * 2
  end
  return width
end

function Share.Compress(data)
  local dict, nextCode = {}, 256
  for i = 0, 255 do
    dict[string.char(i)] = i
  end
  local out, acc, nbits, k = {}, 0, 0, 0
  local function emit(code)
    local width = codeWidth(k)
    k = k + 1
    acc = acc + code * 2 ^ nbits
    nbits = nbits + width
    while nbits >= 8 do
      local byte = acc % 256
      out[#out + 1] = string.char(byte)
      acc = (acc - byte) / 256
      nbits = nbits - 8
    end
  end
  local w = ""
  for i = 1, string.len(data) do
    local c = string.sub(data, i, i)
    local wc = w .. c
    if dict[wc] then
      w = wc
    else
      emit(dict[w])
      dict[wc] = nextCode
      nextCode = nextCode + 1
      w = c
    end
  end
  if w ~= "" then
    emit(dict[w])
  end
  if nbits > 0 then
    out[#out + 1] = string.char(acc % 256)
  end
  return table.concat(out)
end

function Share.Decompress(packed)
  local dict = {}
  for i = 0, 255 do
    dict[i] = string.char(i)
  end
  local nextCode = 256
  local out, acc, nbits, pos, k = {}, 0, 0, 1, 0
  local len = string.len(packed)
  local prev
  while true do
    local width = codeWidth(k)
    while nbits < width and pos <= len do
      acc = acc + string.byte(packed, pos) * 2 ^ nbits
      pos = pos + 1
      nbits = nbits + 8
    end
    if nbits < width then
      break
    end
    local p = 2 ^ width
    local code = acc % p
    acc = (acc - code) / p
    nbits = nbits - width
    k = k + 1
    local entry = dict[code]
    if entry == nil then
      if code == nextCode and prev then
        entry = prev .. string.sub(prev, 1, 1)
      else
        error("bad compressed data")
      end
    end
    out[#out + 1] = entry
    if prev then
      dict[nextCode] = prev .. string.sub(entry, 1, 1)
      nextCode = nextCode + 1
    end
    prev = entry
  end
  return table.concat(out)
end

---------------------------------------------------------------------------
-- Auras
---------------------------------------------------------------------------

local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not same(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

-- Leaves out what the defaults would fill back in on import (RWA.ApplyAuraDefaults).
local function strip(value, default)
  if type(value) ~= "table" or type(default) ~= "table" or #value > 0 or #default > 0 then
    return value
  end
  local out = {}
  for k, v in pairs(value) do
    local d = default[k]
    if d == nil or not same(v, d) then
      out[k] = strip(v, d)
    end
  end
  return out
end

local function compactAura(data)
  local exported = {}
  for key,value in pairs(data) do
    -- Exclude recovery data before copying: share codes must not contain it,
    -- and building one should not allocate a second copy of the backup.
    if key ~= "previewIcon" and key ~= "previousDefinition" then exported[key]=value end
  end
  local copy = RWA.CopyTable(exported)
  if copy.schemaVersion == 2 or copy.schemaVersion == 3 then return copy end
  local defaults = RWA.CopyTable(RWA.REGION_DEFAULTS[copy.regionType or "icon"] or {})
  RWA.MergeDefaults(defaults, RWA.AURA_DEFAULTS)
  defaults.regionType, defaults.id = nil, nil -- always kept
  local out = strip(copy, defaults)
  -- An emptied table whose default is a table is restored on import, so it can go.
  for k, v in pairs(out) do
    if type(v) == "table" and next(v) == nil and type(defaults[k]) == "table" then
      out[k] = nil
    end
  end
  return out
end

-- Code for the given aura ids (all auras when ids is nil), in list order.
function Share.Export(ids)
  local list = {}
  for _, id in ipairs(ids or RWA_DB.order) do
    local data = RWA_DB.auras[id]
    if data then
      list[#list + 1] = compactAura(data)
    end
  end
  if #list == 0 then
    return nil, "there is no aura to export"
  end
  local prefix, version = Share.PREFIX, 3
  for _, aura in ipairs(list) do
    if aura.schemaVersion == 3 then prefix, version = Share.ACTION_PREFIX, 4; break end
  end
  local data = Share.Pack({ formatVersion = version, auras = list })
  return prefix .. "!" .. Share.Base85Encode(Share.Compress(data)) .. "!" .. Share.ShortChecksum(data), #list
end

-- Adds the auras in a code. Returns the list of new ids, or nil and a message.
-- Names that already exist get a number added, so nothing is overwritten.
function Share.Import(code)
  code = string.gsub(tostring(code or ""), "%s", "")
  if code == "" then
    return nil, "paste a code into the Import box first"
  end
  local prefix, body, check = string.match(code, "^(%w+)!([^!]+)!(%x+)$")
  if prefix ~= Share.ACTION_PREFIX and prefix ~= Share.PREFIX and prefix ~= Share.COMPACT_PREFIX and prefix ~= Share.OLD_PREFIX then
    return nil, "that is not a rom weakauras code (it should start with RWA1!, RWA2!, RWA3! or RWA4!)"
  end
  local compact = prefix == Share.ACTION_PREFIX or prefix == Share.PREFIX or prefix == Share.COMPACT_PREFIX
  local data = compact and Share.Base85Decode(body) or Share.Base64Decode(body)
  if data and compact then
    local ok, plain = pcall(Share.Decompress, data)
    data = ok and plain or nil
  end
  local sum = data and (compact and Share.ShortChecksum(data) or Share.Checksum(data))
  if not data or sum ~= string.lower(check) then
    return nil, "the code is damaged or was cut off; copy the whole code and try again"
  end
  local ok, value = pcall(compact and Share.Unpack or Share.Parse, data)
  if not ok or type(value) ~= "table" or type(value.auras) ~= "table" then
    return nil, "the code could not be read"
  end
  if (prefix == Share.PREFIX and value.formatVersion ~= 3) or (prefix == Share.ACTION_PREFIX and value.formatVersion ~= 4) then
    return nil, "this code requires a newer version of rom weakauras"
  end
  -- Validate the complete envelope before adding any aura, so a bad later entry
  -- cannot leave a partially imported set behind.
  for _, aura in ipairs(value.auras) do
    if type(aura) ~= "table" then return nil, "the code contains an invalid aura" end
    if aura.schemaVersion ~= nil and aura.schemaVersion ~= 1 and aura.schemaVersion ~= 2 and aura.schemaVersion ~= 3 then
      return nil, "this aura requires a newer version of rom weakauras"
    end
    if aura.schemaVersion == 2 or aura.schemaVersion == 3 then
      if (prefix ~= Share.PREFIX and prefix ~= Share.ACTION_PREFIX) or (aura.schemaVersion == 3 and prefix ~= Share.ACTION_PREFIX) or type(aura.sources) ~= "table" or type(aura.rules) ~= "table"
        or (aura.schemaVersion == 2 and type(aura.primarySourceId) ~= "string")
        or (aura.schemaVersion == 3 and aura.primarySourceId ~= nil and type(aura.primarySourceId) ~= "string") then
        return nil, "the code contains an invalid rule definition"
      end
      local sources, rules, actions, outputs = {}, {}, {}, {}
      for _, source in ipairs(aura.sources) do
        if type(source) ~= "table" or type(source.id) ~= "string" or sources[source.id] then
          return nil, "the code contains invalid source IDs"
        end
        if (source.type or "aura") == "aura" then
          if (source.names ~= nil and type(source.names) ~= "table") or (source.ids ~= nil and type(source.ids) ~= "table") then
            return nil, "the code contains an invalid buff source"
          end
          for _, name in ipairs(source.names or {}) do if type(name) ~= "string" then return nil, "the code contains an invalid buff name" end end
          for _, id in ipairs(source.ids or {}) do if type(id) ~= "number" and type(id) ~= "string" then return nil, "the code contains an invalid buff ID" end end
        end
        sources[source.id] = true
      end
      for _, rule in ipairs(aura.rules) do
        if type(rule) ~= "table" or type(rule.id) ~= "string" or rules[rule.id]
          or type(rule.when) ~= "table" or type(rule.when.checks) ~= "table"
          or (aura.schemaVersion == 2 and type(rule.set) ~= "table")
          or (aura.schemaVersion == 3 and type(rule.actions) ~= "table") then
          return nil, "the code contains invalid rules"
        end
        if rule.when.mode ~= "all" and rule.when.mode ~= "any" then return nil, "the code contains an invalid rule mode" end
        for _, check in ipairs(rule.when.checks) do
          if type(check) ~= "table" or (check.sourceId ~= nil and type(check.sourceId) ~= "string") then
            return nil, "the code contains an invalid rule check"
          end
        end
        if aura.schemaVersion == 3 then
          for _, action in ipairs(rule.actions) do
            if type(action) ~= "table" or type(action.id) ~= "string" or actions[action.id] then
              return nil, "the code contains invalid action IDs"
            end
            actions[action.id] = true
            if action.output ~= nil then
              if type(action.output) ~= "table" or type(action.output.id) ~= "string" or outputs[action.output.id] then
                return nil, "the code contains invalid output IDs"
              end
              outputs[action.output.id] = true
            end
          end
        end
        rules[rule.id] = true
      end
    elseif type(aura.triggers) ~= "table" then
      return nil, "the code contains an invalid legacy aura"
    end
  end
  -- Conversion is also performed for the whole envelope before any write.
  local converted = {}
  for _, aura in ipairs(value.auras) do
    local normalized, err = RWA.Rules.Normalize(aura)
    if not normalized then return nil, "could not convert aura: " .. tostring(err or "unsupported definition") end
    converted[#converted + 1] = normalized
  end
  local ids = {}
  for _, aura in ipairs(converted) do
    aura.id = RWA.Trim(type(aura.id) == "string" and aura.id or "Imported")
    if aura.id == "" then aura.id = "Imported" end
    ids[#ids + 1] = RWA.AddAura(aura)
  end
  if #ids == 0 then return nil, "the code has no auras in it" end
  return ids
end

---------------------------------------------------------------------------
-- Chat links (experimental): |Hrwa:<code>|h[RWA: name]|h. Clicking one with rom weakauras
-- installed puts the code in the Import box. Whether the server passes a link type it does not
-- know is not confirmed; /rwa linktest shows one locally to check that it draws and clicks.
---------------------------------------------------------------------------

local LINK_TYPE = "rwa"

-- The link carries the code without its "RWA2!" prefix (the link type says what it is); the
-- visible "[RWA: name]" is cut to fit the 255 characters of a chat line, down to "[RWA]".
function Share.MakeLink(code, name)
  local body = code -- retain the format prefix so old and new links stay distinguishable
  local head = "|H" .. LINK_TYPE .. ":" .. body .. "|h[RWA"
  local tail = "]|h"
  local room = 255 - string.len(head) - string.len(tail)
  if room < 0 then
    return nil, string.len(code)
  end
  name = tostring(name or "")
  local label = ""
  if room >= 6 and name ~= "" then
    label = ": " .. name
    if string.len(label) > room then
      label = string.sub(label, 1, room - 2) .. ".."
    end
  end
  return head .. label .. tail
end

function Share.PostLink(code, name)
  local link, n = Share.MakeLink(code, name)
  if not link then
    RWA.Print("this code is " .. n .. " characters, too long for a chat link (about 230 fit). Share it on Discord or elsewhere.")
    return false
  end
  if type(ChatEdit_AddItemLink) == "function" and pcall(ChatEdit_AddItemLink, link) then
    RWA.Print("link added to your chat line: press Enter to send it")
    return true
  end
  RWA.Print("this client cannot add links to the chat line; copy the code instead")
  return false
end

-- Finds an rwa link code in any of the arguments a hyperlink click handler gets.
function Share.LinkCode(...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if type(v) == "string" then
      local code = string.match(v, "^" .. LINK_TYPE .. ":([^|]+)") or string.match(v, "|H" .. LINK_TYPE .. ":([^|]+)")
      if code then
        return code
      end
    end
  end
end

-- Reload UI re-runs this file in the same Lua state, so the wrapper and the game's original live
-- in RWA (which survives) and the wrapper is installed once: wrapping again would wrap our own
-- wrapper and chain them.
function Share.OnHyperlinkClick(...)
  local code = Share.LinkCode(...)
  if code then
    if not string.find(code, "^RWA%d!") then
      code = Share.COMPACT_PREFIX .. "!" .. code
    end
    RWA.OfferImport(code)
    return
  end
  local original = RWA.linkOriginal
  if original then
    return original(...)
  end
end

function Share.HookLinks()
  if type(ChatFrame_OnHyperlinkClick) ~= "function" then
    return
  end
  if not RWA.linkWrapper then
    RWA.linkWrapper = function(...)
      return RWA.Share.OnHyperlinkClick(...)
    end
  end
  if ChatFrame_OnHyperlinkClick ~= RWA.linkWrapper then
    RWA.linkOriginal = ChatFrame_OnHyperlinkClick
    ChatFrame_OnHyperlinkClick = RWA.linkWrapper
  end
  Share.linksHooked = true
end

function Share.LinkTest()
  local code = Share.Export({ RWA_DB.order[1] })
  local link = code and Share.MakeLink(code, RWA_DB.order[1])
  if link and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("rom weakauras link test (click it): " .. link)
    RWA.Print("hook on hyperlink clicks: " .. (Share.linksHooked and "yes" or "no (ChatFrame_OnHyperlinkClick missing)"))
  end
end

RWA.On("RWA_READY", function()
  Share.HookLinks()
end)
