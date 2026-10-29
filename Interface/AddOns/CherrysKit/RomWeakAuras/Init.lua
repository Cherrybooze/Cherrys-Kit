-- rom weakauras: a Runes of Magic rewrite of WeakAuras (GPLv2, see LICENSE).
-- Init.lua sets up the namespace, saved variables and small helpers used everywhere.

RWA = RWA or {}
local RWA = RWA

RWA.name = "RomWeakAuras"
RWA.title = "rom weakauras"
RWA.version = "0.9.24"
-- Inside Cherry's Kit the addon lives in Interface/AddOns/CherrysKit/RomWeakAuras/ (set by the kit's KitPaths.lua).
RWA.path = (CherrysKit_Paths and CherrysKit_Paths.RomWeakAuras) or "Interface/AddOns/RomWeakAuras/"
RWA.media = RWA.path .. "Media/"

-- Saved data lives in RWA_DB (account wide). RoM declares saved variables with a call, not a .toc line.
if SaveVariables then
  SaveVariables("RWA_DB")
end

local tostring, select, type, pairs = tostring, select, type, pairs

function RWA.Print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = tostring((select(i, ...)))
  end
  local msg = "|cff9be3ff" .. RWA.title .. "|r: " .. table.concat(parts, " ")
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  elseif SendSystemChat then
    SendSystemChat(msg)
  end
end

-- Errors from user code or a missing client method must never break the whole addon.
local lastErrors = {}
function RWA.Error(err)
  err = tostring(err)
  local now = RWA.Now()
  if lastErrors[err] and now - lastErrors[err] < 10 then
    return
  end
  lastErrors[err] = now
  RWA.Print("|cffff6060error|r " .. err)
end

function RWA.Now()
  if GetTime then
    return GetTime()
  end
  return os.clock()
end

-- Calls obj:method(...) only if the client has that method. Returns true when it ran.
-- The RoM widget API is only partly documented, so every widget call goes through here.
function RWA.Try(obj, method, ...)
  if obj == nil then
    return false
  end
  local fn = obj[method]
  if type(fn) ~= "function" then
    return false
  end
  local ok, err = pcall(fn, obj, ...)
  if not ok then
    RWA.Debug(method .. ": " .. tostring(err))
  end
  return ok, err
end

function RWA.Debug(msg)
  if RWA_DB and RWA_DB.settings and RWA_DB.settings.debug then
    RWA.Print("|cffaaaaaa" .. tostring(msg) .. "|r")
  end
end

function RWA.CopyTable(src)
  if type(src) ~= "table" then
    return src
  end
  local out = {}
  for k, v in pairs(src) do
    out[k] = RWA.CopyTable(v)
  end
  return out
end

-- Fills missing keys of dst from defaults, recursively. Existing values win.
function RWA.MergeDefaults(dst, defaults)
  for k, v in pairs(defaults) do
    if dst[k] == nil then
      dst[k] = RWA.CopyTable(v)
    elseif type(v) == "table" and type(dst[k]) == "table" then
      RWA.MergeDefaults(dst[k], v)
    end
  end
  return dst
end

function RWA.Trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function RWA.Split(s, sep)
  local out = {}
  for part in string.gmatch(tostring(s or ""), "[^" .. (sep or ",") .. "]+") do
    part = RWA.Trim(part)
    if part ~= "" then
      out[#out + 1] = part
    end
  end
  return out
end

function RWA.FormatTime(seconds)
  if not seconds or seconds <= 0 then
    return ""
  end
  if seconds < 3 then
    return string.format("%.1f", seconds)
  elseif seconds < 60 then
    return string.format("%d", math.floor(seconds + 0.5))
  elseif seconds < 3600 then
    return string.format("%dm", math.floor(seconds / 60 + 0.5))
  end
  return string.format("%dh", math.floor(seconds / 3600 + 0.5))
end
