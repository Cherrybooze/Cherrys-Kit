-- Global Bank (Cherry's Kit): what every character carries in its bag and bank, and its gold.
-- Cherry's code, GPL v2; see LICENSE.txt in the kit folder.
--
-- Where the data lives (nothing is ever stored in the addon folder):
--   GlobalBank_Char   this character's own snapshot, one compact string, saved by the game in
--                     Documents\Runes of Magic\<Name>\SaveVariables.lua (SaveVariablesPerCharacter).
--                     The shared account file is not used at all, so it can stay read-only.
--   GlobalBank_Notes  notes this character wrote (and the window size), until the helper's database
--                     has them; the helper shares them with every character (see "Notes" below).
--   Helper\          "Start Global Bank helper.bat" in this addon's Helper folder. While its window
--                     is open it creates Interface\GlobalBankHelper (outside the kit, so the kit stays
--                     safe to share) and, a few seconds after any character logs out, collects every
--                     character's GlobalBank_Char into
--                     Interface\GlobalBankHelper\GlobalBankDatabase.lua, which the addon reads when
--                     the window opens and on Refresh (not during the loading screen).
--
-- Snapshot string: header and records joined by "`", fields by "~":
--   GB1~name~class~level~gold~bagSlots~bankSlots~bankSeen(0/1)~time
--   B~slot~count~id~name~icon   (bag)     K~slot~count~id~name~icon   (bank)   then ~1 if the item is bound
--   gear then adds ~durability~maxDurability~plus~tierAdded~freeRuneSlots~stats~runes~colour~link (stats and runes joined by ;, link as the numbers of the item's link)
--   mana and fusion stones with stats instead add ~bound~ST~stats~link
--   M~key~amount~name   a currency other than gold, left out at zero
--   S~server   the server this character was last saved on

GlobalBank = GlobalBank or {}
local GB = GlobalBank

GB.version = "1.4.15"
GB.DATABASE = "Interface/GlobalBankHelper/GlobalBankDatabase.lua"
GB.BEAT = "Interface/GlobalBankHelper/GlobalBankHelperBeat.lua" -- rewritten every 30 s while the helper runs
GB.BEAT_LATE = 75 -- seconds without a new beat before the helper counts as stopped
GB.HELPER_DIR = string.gsub(((CherrysKit_Paths and CherrysKit_Paths.GlobalBank) or "Interface/AddOns/GlobalBank/") .. "Helper", "/", "\\")
GB.BAG_SLOTS = 180
GB.BANK_SLOTS = 300 -- 1-200 bank pages, 201-300 the item shop tab
GB.QUIET = 3        -- seconds without bag changes before this character's bags are read again
GB.MAX_WAIT = 15    -- ...but no longer than this while things keep changing (looting, crafting)

-- Per character only: the shared account file (often kept read-only) is never touched.
if SaveVariablesPerCharacter then
  SaveVariablesPerCharacter("GlobalBank_Char")
  SaveVariablesPerCharacter("GlobalBank_Probe")
  SaveVariablesPerCharacter("GlobalBank_Removed")
  SaveVariablesPerCharacter("GlobalBank_Notes")
end

-- Per-session state: GlobalBank survives Reload UI, so it is reset here.
GB.started = false
GB.dirty = nil
GB.lastBeat, GB.lastBeatAt, GB.helperState = nil, nil, nil
GB.drag, GB.noteName = nil, nil
GB.chars = {}       -- name -> character (see GB.Parse)
GB.order = {}       -- names, sorted for the list
GB.events = {}      -- event -> times seen (for /gb probe)
GB.db = { loaded = false, count = 0 }

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Global Bank|r: " .. text)
  end
end
GB.Print = chat

function GB.IsOn()
  return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("GlobalBank"))
end

---------------------------------------------------------------------------
-- Snapshot string
---------------------------------------------------------------------------

-- Names and icon paths lose the few characters the format and the save file need for themselves.
local function clean(text)
  text = tostring(text or "")
  text = string.gsub(text, "\\", "/")
  text = string.gsub(text, "[%c\"~`|]", "")
  return text
end
GB.Clean = clean

-- Item id from a RoM item link ("|Hitem:7a120 ..."), as a decimal string; the name when there is no link.
function GB.ItemId(link, name)
  if type(link) == "string" then
    local hex = string.match(link, "|Hitem:(%x+)")
    if hex and tonumber(hex, 16) then
      return tostring(tonumber(hex, 16))
    end
  end
  return "n:" .. clean(name)
end

function GB.Serialize(c)
  local parts = { table.concat({ "GB1", clean(c.name), clean(c.cls), tostring(c.lvl or 0), tostring(c.money or 0),
    tostring(c.bagMax or 0), tostring(c.bankMax or 0), c.bank and "1" or "0", clean(c.when) }, "~") }
  local function add(tag, list)
    for _, it in ipairs(list or {}) do
      local record = table.concat({ tag, it.slot, it.count, it.id, clean(it.name), clean(it.icon) }, "~")
      local gear = it.gear
      if gear then
        record = table.concat({ record, it.bound and "1" or "", gear.dura, gear.maxDura, gear.plus, gear.tier, gear.freeSlots,
          clean(table.concat(gear.stats, ";")), clean(table.concat(gear.runes, ";")), clean(gear.color), clean(gear.link) }, "~")
      elseif it.stone then
        record = table.concat({ record, it.bound and "1" or "", "ST", clean(table.concat(it.stone.stats, ";")), clean(it.stone.link) }, "~")
      elseif it.bound then
        record = record .. "~1"
      end
      parts[#parts + 1] = record
    end
  end
  for _, class in ipairs(c.classes or {}) do
    parts[#parts + 1] = table.concat({ "C", clean(class.name), tostring(class.level or 0) }, "~")
  end
  if c.server and c.server ~= "" then
    parts[#parts + 1] = "S~" .. clean(c.server)
  end
  for _, money in ipairs(c.currencies or {}) do
    parts[#parts + 1] = table.concat({ "M", clean(money.key), tostring(money.amount), clean(money.name) }, "~")
  end
  add("B", c.bag)
  add("K", c.bank)
  return table.concat(parts, "`")
end

local function split(text, sep)
  local list, start = {}, 1
  while true do
    local i = string.find(text, sep, start, true)
    if not i then
      list[#list + 1] = string.sub(text, start)
      return list
    end
    list[#list + 1] = string.sub(text, start, i - 1)
    start = i + 1
  end
end

-- The gear fields of an item record, split into a table; nil for anything else.
function GB.ParseGear(f)
  if not tonumber(f[8]) then
    return nil
  end
  local function names(text)
    local list = {}
    if text and text ~= "" then
      list = split(text, ";")
    end
    return list
  end
  return { dura = tonumber(f[8]) or 0, maxDura = tonumber(f[9]) or 0, plus = tonumber(f[10]) or 0, tier = tonumber(f[11]) or 0,
    freeSlots = tonumber(f[12]) or 0, stats = names(f[13]), runes = names(f[14]), color = f[15] or "", link = f[16] or "" }
end

function GB.ParseStone(f)
  if f[8] ~= "ST" then
    return nil
  end
  return { stats = f[9] and f[9] ~= "" and split(f[9], ";") or {}, link = f[10] or "" }
end

-- Returns the character table, or nil for anything that is not a GB1 string.
function GB.Parse(text)
  if type(text) ~= "string" or string.sub(text, 1, 4) ~= "GB1~" then
    return nil
  end
  local records = split(text, "`")
  local h = split(records[1], "~")
  if not h[2] or h[2] == "" then
    return nil
  end
  local c = { name = h[2], cls = h[3] or "", lvl = tonumber(h[4]) or 0, money = tonumber(h[5]) or 0,
    bagMax = tonumber(h[6]) or 0, bankMax = tonumber(h[7]) or 0, when = h[9] or "", bag = {}, classes = {}, currencies = {} }
  if h[8] == "1" then
    c.bank = {}
  end
  for i = 2, #records do
    local f = split(records[i], "~")
    if f[1] == "C" and f[2] and f[2] ~= "" and tonumber(f[3]) then
      c.classes[#c.classes + 1] = { name = f[2], level = tonumber(f[3]) }
    end
    if f[1] == "S" and f[2] and f[2] ~= "" then
      c.server = f[2]
    end
    if f[1] == "M" and f[2] and f[2] ~= "" and tonumber(f[3]) then
      c.currencies[#c.currencies + 1] = { key = f[2], amount = tonumber(f[3]), name = f[4] or "" }
    end
    local list = (f[1] == "B" and c.bag) or (f[1] == "K" and c.bank) or nil
    if list and f[4] then
      list[#list + 1] = { slot = tonumber(f[2]) or 0, count = tonumber(f[3]) or 1, id = f[4], bound = f[7] == "1" or nil, gear = GB.ParseGear(f), stone = GB.ParseStone(f), name = f[5] or "", icon = f[6] or "" }
    end
  end
  return c
end

local function filled(c)
  return #c.bag + (c.bank and #c.bank or 0)
end
GB.Filled = filled

---------------------------------------------------------------------------
-- Reading this character (only called at the moments listed in GB.OnEvent, never every frame)
---------------------------------------------------------------------------

local function call(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end
  local result = { pcall(fn, ...) }
  if not result[1] then
    return nil
  end
  table.remove(result, 1)
  return unpack(result)
end

function GB.PlayerName()
  local name = call(UnitName, "player")
  if type(name) == "string" and name ~= "" then
    return name
  end
end

function GB.ReadMoney()
  local money = call(GetPlayerMoney, "copper")
  if type(money) ~= "number" then
    money = call(GetPlayerMoney)
  end
  return type(money) == "number" and money or 0
end

-- An item link's second number is the item's mode, and its lowest bit says it can be traded. A nil is
-- no link to go by.
function GB.IsBound(link)
  local mode = type(link) == "string" and string.match(link, "|Hitem:%x+ (%x+)")
  mode = mode and tonumber(mode, 16)
  if mode then
    return mode % 2 == 0
  end
end

-- What a weapon's, armour's or jewellery's link holds, after its ID and mode: a number packing maximum durability,
-- tier and rarity, and plus and free rune slots; three numbers holding two stats each (their IDs less 0x70000);
-- four rune IDs; then durability times 100. Names come from the game's own strings, in the player's language.
local function objectName(id)
  local key = "Sys" .. id .. "_name"
  local name = call(TEXT, key)
  return type(name) == "string" and name ~= key and name or nil
end

function GB.ReadGear(id, link)
  id = tonumber(id)
  if type(link) ~= "string" or not id or id < 210000 or id >= 240000 then
    return nil
  end
  local hex = string.match(link, "|Hitem:([%x ]+)|h")
  if not hex then
    return nil
  end
  local data = {}
  for value in string.gmatch(hex, "%x+") do
    data[#data + 1] = tonumber(value, 16)
  end
  if not data[11] then
    return nil
  end
  local packed = data[3]
  local tierByte = math.floor(packed / 256) % 256
  local plusByte = math.floor(packed / 65536) % 256
  local gear = { dura = math.floor(data[11] / 100), maxDura = packed % 256, plus = plusByte % 32, freeSlots = math.floor(plusByte / 32),
    tier = math.max(tierByte % 32 - 10, 0), stats = {}, runes = {}, color = string.match(link, "|h|c%x%x(%x%x%x%x%x%x)%[") or "", link = hex }
  for i = 4, 6 do
    for _, short in ipairs({ data[i] % 65536, math.floor(data[i] / 65536) }) do
      if short > 0 then
        gear.stats[#gear.stats + 1] = objectName(short + 458752) or ("Stat " .. (short + 458752))
      end
    end
  end
  for i = 7, 10 do
    if data[i] > 0 then
      gear.runes[#gear.runes + 1] = objectName(data[i]) or ("Rune " .. data[i])
    end
  end
  return gear
end

-- A mana or fusion stone's link, after its ID, mode and creation time: three numbers of two stats each, as
-- their IDs less 500000. Stones with no stats return nil and stack as usual.
function GB.ReadStone(id, link)
  id = tonumber(id)
  if type(link) ~= "string" or not id or not ((id >= 202840 and id <= 202859) or (id >= 202880 and id <= 202885)) then
    return nil
  end
  local hex = string.match(link, "|Hitem:([%x ]+)|h")
  if not hex then
    return nil
  end
  local data = {}
  for value in string.gmatch(hex, "%x+") do
    data[#data + 1] = tonumber(value, 16)
  end
  local stats = {}
  for i = 4, 6 do
    if data[i] then
      for _, short in ipairs({ data[i] % 65536, math.floor(data[i] / 65536) }) do
        if short > 0 then
          stats[#stats + 1] = objectName(short + 500000) or ("Stat " .. (short + 500000))
        end
      end
    end
  end
  if #stats == 0 then
    return nil
  end
  return { stats = stats, link = hex }
end

-- The rows of the game's own currency window: its group, its row, and the number of its name.
GB.CURRENCY_ROWS = {
  { 1, 1, 11 }, { 1, 2, 12 }, { 1, 3, 10 }, { 1, 4, 17 }, { 1, 5, 21 },
  { 2, 1, 9 }, { 2, 2, 13 }, { 2, 3, 15 }, { 2, 4, 16 },
  { 3, 1, 4 }, { 3, 2, 8 }, { 3, 3, 14 }, { 3, 4, 18 }, { 3, 5, 19 }, { 3, 6, 22 }, { 3, 7, 23 },
}
GB.SHOP_CURRENCIES = { "account", "bonus", "billdin" }

function GB.ReadCurrencies()
  local list = {}
  for _, row in ipairs(GB.CURRENCY_ROWS) do
    local amount = tonumber((call(GetPlayerPointInfo, row[1], row[2], "SYS_MONEY_TIPS_" .. row[3])))
    if amount and amount > 0 then
      list[#list + 1] = { key = tostring(row[3]), amount = amount, name = call(TEXT, "SYS_MONEY_TYPE_" .. row[3]) or "" }
    end
  end
  local charges = tonumber((call(GetMagicBoxEnergy)))
  if charges and charges > 0 then
    list[#list + 1] = { key = "transmutor", amount = charges, name = "" }
  end
  for _, key in ipairs(GB.SHOP_CURRENCIES) do
    local amount = tonumber((call(GetPlayerMoney, key)))
    if amount and amount > 0 then
      list[#list + 1] = { key = key, amount = amount, name = "" }
    end
  end
  return list
end

function GB.ReadBag()
  local list = {}
  for i = 1, GB.BAG_SLOTS do
    local index, icon, name, count = call(GetBagItemInfo, i)
    if type(name) == "string" and name ~= "" then
      local link = index and call(GetBagItemLink, index)
      list[#list + 1] = { slot = i, count = tonumber(count) or 1, id = GB.ItemId(link, name), bound = GB.IsBound(link), gear = GB.ReadGear(GB.ItemId(link, name), link), stone = GB.ReadStone(GB.ItemId(link, name), link), name = name, icon = icon }
    end
  end
  -- GetBagCount: used, available, total (180 with every page bought)
  local _, open = call(GetBagCount)
  return list, tonumber(open) or 0
end

function GB.ReadBank()
  local list = {}
  for i = 1, GB.BANK_SLOTS do
    local icon, name, count = call(GetBankItemInfo, i)
    if type(name) == "string" and name ~= "" then
      local link = call(GetBankItemLink, i)
      list[#list + 1] = { slot = i, count = tonumber(count) or 1, id = GB.ItemId(link, name), bound = GB.IsBound(link), gear = GB.ReadGear(GB.ItemId(link, name), link), stone = GB.ReadStone(GB.ItemId(link, name), link), name = name, icon = icon }
    end
  end
  local a, b = call(GetBankNumItems)
  return list, tonumber(b) or tonumber(a) or 0
end

local function now()
  if os and os.date then
    local ok, text = pcall(os.date, "%Y-%m-%d %H:%M")
    if ok then
      return text
    end
  end
  return ""
end

GB.bankOpen = false

-- authoritative: the bank window is open, so an empty bank really is empty. With the bank closed the
-- game may return nothing, so a closed read is only kept when it finds items.
function GB.Snapshot(withBank, authoritative)
  local name = GB.PlayerName()
  if not name then
    return
  end
  local c = GB.chars[name] or { name = name, bag = {} }
  c.name, c.live = name, true
  c.cls = call(UnitClass, "player") or c.cls or ""
  c.lvl = call(UnitLevel, "player") or c.lvl or 0
  local count = tonumber(call(GetPlayerNumClasses))
  if count and count > 0 then
    local classes = {}
    for i = 1, count do
      local class, _, level = call(GetPlayerClassInfo, i, true)
      if type(class) == "string" and class ~= "" and tonumber(level) and tonumber(level) > 0 then
        classes[#classes + 1] = { name = class, level = tonumber(level) }
      end
    end
    if #classes == count then c.classes = classes end
  end
  c.money = GB.ReadMoney()
  c.currencies = GB.ReadCurrencies()
  c.server = call(GetServerName) or c.server
  c.bag, c.bagMax = GB.ReadBag()
  if withBank then
    local bank, max = GB.ReadBank()
    if authoritative or #bank > 0 then
      c.bank, c.bankMax = bank, max
    end
  end
  c.when = now()
  c.saved = nil
  GB.chars[name] = c
  GlobalBank_Char = GB.Serialize(c)
  GB.dirty = nil
  GB.Changed()
  return c
end

---------------------------------------------------------------------------
-- Removed entries. GlobalBank_Removed (this character's save file) lists "name~stamp" records
-- joined by "`"; stamp is the removed snapshot's date. The helper reads every character's list and
-- leaves those snapshots out of the database. A character that logs in again saves a newer
-- snapshot, so it comes back by itself.
---------------------------------------------------------------------------

GB.removed = {}
GB.MAX_REMOVED = 300

function GB.LoadRemoved()
  GB.removed = {}
  if type(GlobalBank_Removed) ~= "string" then
    return
  end
  for _, rec in ipairs(split(GlobalBank_Removed, "`")) do
    local f = split(rec, "~")
    if f[1] and f[1] ~= "" then
      GB.removed[f[1]] = f[2] or ""
    end
  end
end

local function saveRemoved()
  local list = {}
  for name, stamp in pairs(GB.removed) do
    list[#list + 1] = clean(name) .. "~" .. clean(stamp)
  end
  table.sort(list)
  while #list > GB.MAX_REMOVED do
    table.remove(list, 1)
  end
  GlobalBank_Removed = table.concat(list, "`")
end

-- True when c is a snapshot this character removed (and not a newer one).
function GB.IsRemoved(c)
  local stamp = GB.removed[c.name]
  return stamp ~= nil and (c.saved or "") <= stamp
end

function GB.Remove(name)
  local c = GB.chars[name]
  if not c then
    return false
  end
  if c.live or name == GB.PlayerName() then
    chat("you're playing " .. name .. " right now, so it can't be removed.")
    return false
  end
  GB.removed[name] = c.saved or ""
  saveRemoved()
  GB.chars[name] = nil
  if GB.selected == name then
    GB.selected = nil
  end
  GB.Changed()
  chat("removed " .. name .. ". It comes back by itself if " .. name .. " logs in again.")
  return true
end

---------------------------------------------------------------------------
-- Notes. GlobalBank_Notes (this character's save file) lists "name~version~text" records joined by
-- "`": the notes this character wrote. The helper keeps the highest version of each name from every
-- character and writes them to the database as GlobalBank_Import.notes, so a note written on one
-- character shows on all of them. Writing a note takes the highest version seen plus one; once the
-- database has caught up, the record leaves this character's save file again.
-- The window size is kept the same way, under the name "*size" (no character name has a "*").
---------------------------------------------------------------------------

GB.NOTE_MAX = 80
GB.SIZE_KEY = "*size"
GB.myNotes = {}     -- name -> { v = version, t = text }, written on this character
GB.dbNotes = {}     -- name -> { v, t }, from the helper's database

local function parseNotes(text)
  local list = {}
  if type(text) ~= "string" then
    return list
  end
  for _, rec in ipairs(split(text, "`")) do
    local f = split(rec, "~")
    local v = tonumber(f[2])
    if f[1] and f[1] ~= "" and v then
      list[f[1]] = { v = v, t = f[3] or "" }
    end
  end
  return list
end
GB.ParseNotes = parseNotes

local function saveNotes()
  local list = {}
  for name, n in pairs(GB.myNotes) do
    list[#list + 1] = clean(name) .. "~" .. n.v .. "~" .. clean(n.t)
  end
  table.sort(list)
  GlobalBank_Notes = #list > 0 and table.concat(list, "`") or nil
end

function GB.LoadNotes()
  GB.myNotes = parseNotes(GlobalBank_Notes)
end

-- The newest of this character's and the database's record for name.
function GB.NoteRecord(name)
  local mine, db = GB.myNotes[name], GB.dbNotes[name]
  if mine and (not db or mine.v >= db.v) then
    return mine
  end
  return db
end

function GB.Note(name)
  local n = name and GB.NoteRecord(name)
  return n and n.t or ""
end

function GB.TidyNote(text)
  text = clean(text)
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return string.sub(text, 1, GB.NOTE_MAX)
end

function GB.SetNote(name, text, quiet)
  if not name or name == "" then
    return
  end
  text = GB.TidyNote(text)
  if text == GB.Note(name) then
    return
  end
  local n = GB.NoteRecord(name)
  GB.myNotes[name] = { v = (n and n.v or 0) + 1, t = text }
  saveNotes()
  if not quiet then
    GB.Changed()
  end
end

-- Called with the database's notes string; drops this character's records the database has caught up with.
function GB.SetDatabaseNotes(text)
  GB.dbNotes = parseNotes(text)
  local changed = false
  for name, mine in pairs(GB.myNotes) do
    local db = GB.dbNotes[name]
    if db and (db.v > mine.v or (db.v == mine.v and db.t == mine.t)) then
      GB.myNotes[name] = nil
      changed = true
    end
  end
  if changed then
    saveNotes()
  end
end

---------------------------------------------------------------------------
-- The database the helper writes (other characters)
---------------------------------------------------------------------------

function GB.LoadDatabase()
  GlobalBank_Import = nil
  local ok, err = pcall(dofile, GB.DATABASE)
  GB.db = { loaded = ok and type(GlobalBank_Import) == "table", count = 0, error = (not ok) and tostring(err) or nil }
  local me = GB.PlayerName()
  if GB.db.loaded then
    GB.db.made = GlobalBank_Import.made
    GB.SetDatabaseNotes(GlobalBank_Import.notes)
    local seen = {}
    for _, entry in ipairs(GlobalBank_Import) do
      local c = GB.Parse(type(entry) == "table" and entry.s or entry)
      if c then
        GB.db.count = GB.db.count + 1
        c.saved = type(entry) == "table" and entry.saved or nil
        seen[c.name] = true
        local old = GB.chars[c.name]
        if c.name ~= me and not (old and old.live) and not GB.IsRemoved(c) then
          GB.chars[c.name] = c
        end
      end
    end
    -- Characters the helper no longer exports disappear right away, not at the next Reload UI.
    for name, old in pairs(GB.chars) do
      if name ~= me and not (old and old.live) and not seen[name] then
        GB.chars[name] = nil
      end
    end
  end
  GlobalBank_Import = nil -- the parsed copy is enough; free the raw strings
  GB.Changed()
  return GB.db.loaded
end

---------------------------------------------------------------------------
-- Search and sort
---------------------------------------------------------------------------

GB.search = ""
GB.sortBy = "gold"
GB.sortDesc = true

-- Number of items (stacks) of c whose name contains text (lower case); nil when nothing matches.
function GB.Matches(c, text)
  if text == "" then
    return 0
  end
  local n = 0
  local function scan(list)
    for _, it in ipairs(list or {}) do
      it.lower = it.lower or string.lower(it.name)
      if string.find(it.lower, text, 1, true) then
        n = n + 1
      end
    end
  end
  scan(c.bag)
  scan(c.bank)
  if n > 0 then
    return n
  end
  if string.find(string.lower(c.name), text, 1, true) then
    return 0
  end
  local note = GB.Note(c.name)
  if note ~= "" and string.find(string.lower(note), text, 1, true) then
    return 0
  end
  return nil
end

function GB.ItemMatches(it)
  if GB.search == "" then
    return true
  end
  it.lower = it.lower or string.lower(it.name)
  return string.find(it.lower, GB.search, 1, true) ~= nil
end

function GB.SetSearch(text)
  text = string.lower(tostring(text or ""))
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  GB.search = text
  GB.Changed()
end

function GB.SetSort(by)
  if GB.sortBy == by then
    GB.sortDesc = not GB.sortDesc
  else
    GB.sortBy = by
    GB.sortDesc = by ~= "name" and by ~= "note"
  end
  GB.Changed()
end

-- Rebuilds GB.order (names shown in the list) and GB.found (name -> matching stacks).
function GB.BuildList()
  local order, found = {}, {}
  for name, c in pairs(GB.chars) do
    local m = GB.Matches(c, GB.search)
    if m then
      order[#order + 1] = name
      found[name] = m
    end
  end
  local by, desc = GB.sortBy, GB.sortDesc
  local function key(name)
    local c = GB.chars[name]
    if by == "gold" then
      return c.money or 0
    elseif by == "level" then
      return c.lvl or 0
    elseif by == "items" then
      return filled(c)
    elseif by == "found" then
      return found[name] or 0
    elseif by == "note" then
      -- notes A to Z, characters without one last (either way round)
      local note = string.lower(GB.Note(name))
      if note == "" then
        return desc and "" or "\255"
      end
      return note
    end
    return 0
  end
  table.sort(order, function(a, b)
    if by ~= "name" then
      local ka, kb = key(a), key(b)
      if ka ~= kb then
        if desc then
          return ka > kb
        end
        return ka < kb
      end
    end
    if by == "name" and desc then
      return string.lower(a) > string.lower(b)
    end
    return string.lower(a) < string.lower(b)
  end)
  GB.order, GB.found = order, found
  return order
end

function GB.Totals()
  local n, gold = 0, 0
  for _, c in pairs(GB.chars) do
    n = n + 1
    gold = gold + (c.money or 0)
  end
  return n, gold
end

function GB.FormatGold(n)
  local text = tostring(math.floor(tonumber(n) or 0))
  local out = ""
  while string.len(text) > 3 do
    out = "," .. string.sub(text, -3) .. out
    text = string.sub(text, 1, -4)
  end
  return text .. out
end

-- The UI (GlobalBankUI.lua) replaces this.
function GB.Changed()
end

---------------------------------------------------------------------------
-- Events: the only moments anything is read from the game
---------------------------------------------------------------------------

GB.EVENTS = { "VARIABLES_LOADED", "LOADING_END", "BAG_ITEM_UPDATE", "PLAYER_BAG_CHANGED", "PLAYER_MONEY",
  "BANK_OPEN", "BANK_CLOSE", "BANK_UPDATE", "UNIT_LEVEL", "EXCHANGECLASS_SUCCESS" }

function GB.OnLoad(frame)
  GB.registered = {}
  for _, event in ipairs(GB.EVENTS) do
    if pcall(frame.RegisterEvent, frame, event) then
      GB.registered[#GB.registered + 1] = event
    end
  end
end

local timer = nil      -- seconds until the pending snapshot
local timerBank = false
local timerAuth = false

local waited = 0        -- seconds since the first change that is still waiting

-- quiet: a bag or gold change, which restarts the wait (so a burst of changes costs one read),
-- but never past GB.MAX_WAIT.
local function schedule(seconds, withBank, authoritative, quiet)
  if timer == nil then
    waited = 0
  end
  if quiet and waited < GB.MAX_WAIT then
    timer = math.max(timer or 0, seconds)
  elseif timer == nil or seconds < timer then
    timer = seconds
  end
  timerBank = timerBank or withBank
  timerAuth = timerAuth or authoritative
end

function GB.OnEvent(event)
  GB.events[event] = (GB.events[event] or 0) + 1
  if event == "VARIABLES_LOADED" then
    if not GB.IsOn() then
      GB.HideButtons()
      return
    end
    GB.started = true
    GB.LoadRemoved()
    GB.LoadNotes()
    if GB.ApplySavedSize then
      GB.ApplySavedSize()
    end
    -- Last session's snapshot keeps the bank until the bank is opened again.
    local mine = GB.Parse(GlobalBank_Char)
    if mine then
      GB.chars[mine.name] = mine
    end
    -- Other characters are read when the window first opens, not during the loading screen; only
    -- the helper's one-line beat file is read now, to tell later whether it is still running.
    GB.HelperState()
    schedule(5, true, false)
  elseif not GB.started then
    return
  elseif event == "LOADING_END" then
    schedule(3, true, false)
  elseif event == "UNIT_LEVEL" or event == "EXCHANGECLASS_SUCCESS" then
    -- Ignore other units. Refresh only when the player levels or changes class.
    if event ~= "UNIT_LEVEL" or arg1 == nil or arg1 == "player" then
      schedule(1, GB.bankOpen, GB.bankOpen)
    end
  elseif event == "BANK_OPEN" then
    GB.bankOpen = true
    schedule(1, true, true)
  elseif event == "BANK_UPDATE" then
    if GB.bankOpen then
      schedule(GB.QUIET, true, true, true)
    end
  elseif event == "BANK_CLOSE" then
    if GB.bankOpen and timerBank and timer then
      GB.Snapshot(true, timerAuth) -- before the game forgets the bank
      timer, timerBank, timerAuth = nil, false, false
    end
    GB.bankOpen = false
  elseif event == "PLAYER_MONEY" then
    GB.UpdateMoney() -- right away: gold often changes just before logging out (mail, trade)
  else -- bags changed
    GB.dirty = true
    schedule(GB.QUIET, GB.bankOpen, GB.bankOpen, true)
  end
end

-- Gold only: no bag reads, just this character's save string written again.
function GB.UpdateMoney()
  local c = GB.chars[GB.PlayerName() or ""]
  if not (c and c.live) then
    GB.Snapshot(GB.bankOpen, GB.bankOpen)
    return
  end
  local money = GB.ReadMoney()
  if money ~= c.money then
    c.money = money
    GlobalBank_Char = GB.Serialize(c)
    GB.Changed()
  end
end

-- Anything still waiting is saved before the game writes the save file (logout, quit, reload).
function GB.Flush()
  if timer ~= nil or GB.dirty then
    local withBank, auth = timerBank, timerAuth
    timer, timerBank, timerAuth = nil, false, false
    pcall(GB.Snapshot, withBank or GB.bankOpen, (auth or GB.bankOpen) and GB.bankOpen)
  else
    pcall(GB.Snapshot, GB.bankOpen, GB.bankOpen)
  end
end

-- Reload UI re-runs this file in the same Lua state, so the game's original functions and our
-- wrappers are kept in GlobalBank itself. A wrapper is only installed when the current function
-- isn't already ours, and it calls the current GlobalBank code, never last session's.
GB.originals = GB.originals or {}
GB.wrappers = GB.wrappers or {}
GB.hooked = {}

local function hookExit(name)
  local current = _G[name]
  if type(current) ~= "function" then
    return
  end
  if current ~= GB.wrappers[name] then
    GB.originals[name] = current
    GB.wrappers[name] = function(...)
      local gb = GlobalBank
      if gb and gb.started and gb.Flush then
        pcall(gb.Flush)
      end
      return gb.originals[name](...)
    end
    _G[name] = GB.wrappers[name]
  end
  GB.hooked[name] = true
end

for _, name in ipairs({ "Logout", "QuitGame", "ReloadUI" }) do
  hookExit(name)
end

function GB.OnUpdate(elapsed)
  if timer == nil then
    return
  end
  timer = timer - (elapsed or 0)
  waited = waited + (elapsed or 0)
  if timer > 0 then
    return
  end
  local withBank, auth = timerBank, timerAuth
  timer, timerBank, timerAuth = nil, false, false
  GB.Snapshot(withBank, auth and GB.bankOpen)
end

-- Refresh button and /gb refresh: this character now, and the helper's file again.
function GB.Refresh()
  GB.Snapshot(true, GB.bankOpen)
  GB.LoadDatabase()
  GB.helperState = GB.HelperState()
  if GB.helperState == "running" then
    chat(GB.db.count .. " other characters read" .. (GB.db.made and (" (updated " .. GB.db.made .. ")") or "") .. ".")
  else
    GB.WarnHelper(GB.helperState, true)
  end
  GB.Changed()
end

---------------------------------------------------------------------------
-- Is the helper set up and running? The helper rewrites GB.BEAT every 30 seconds with a new
-- number; the same number for longer than GB.BEAT_LATE means its window was closed.
---------------------------------------------------------------------------

function GB.ReadBeat()
  GlobalBank_HelperBeat = nil
  pcall(dofile, GB.BEAT)
  local beat = tonumber(GlobalBank_HelperBeat)
  GlobalBank_HelperBeat = nil
  return beat
end

local function clock()
  local ok, t = pcall(GetTime)
  return ok and tonumber(t) or 0
end

-- "missing" (never set up, or an old helper without the beat file), "stopped" or "running".
function GB.HelperState()
  local beat = GB.ReadBeat()
  if not beat then
    return "missing"
  end
  local now = clock()
  if beat ~= GB.lastBeat then
    GB.lastBeat, GB.lastBeatAt = beat, now
    return "running"
  end
  if now - (GB.lastBeatAt or now) > GB.BEAT_LATE then
    return "stopped"
  end
  return "running"
end

function GB.HelperHelp()
  return "Run \"Start Global Bank helper.bat\" in " .. GB.HELPER_DIR .. " and keep its window open."
end

GB.warnedState = nil

function GB.WarnHelper(state, always)
  state = state or GB.helperState or "missing"
  if GB.warnedState == state and not always then
    return
  end
  GB.warnedState = state
  if state == "missing" then
    chat("|cffff6060only this character can be shown until the helper is set up.|r " .. GB.HelperHelp()
      .. " Your characters' bags, banks and gold then save automatically to Interface\\GlobalBankHelper."
      .. " Don't share that folder: it shows what all your characters own.")
  elseif state == "stopped" then
    chat("|cffffa040the helper isn't running, so other characters may be out of date.|r " .. GB.HelperHelp())
  end
end

function GB.HideButtons()
  if GlobalBankBagButton then
    GlobalBankBagButton:Hide()
  end
  if GlobalBankZBagButton then
    GlobalBankZBagButton:Hide()
  end
end

---------------------------------------------------------------------------
-- /gb, /gb refresh, /gb probe
---------------------------------------------------------------------------

local function yes(v)
  return v and "yes" or "NO"
end

function GB.Probe()
  local lines = {}
  local function add(text)
    lines[#lines + 1] = text
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Global Bank probe|r " .. text)
    end
  end
  local me = GB.PlayerName()
  add("version " .. GB.version .. ", kit on " .. yes(GB.IsOn()) .. ", character " .. tostring(me)
    .. ", class " .. tostring(call(UnitClass, "player")) .. ", level " .. tostring(call(UnitLevel, "player")))
  local used, open, total = call(GetBagCount)
  add("gold: GetPlayerMoney(\"copper\") " .. tostring(call(GetPlayerMoney, "copper")) .. ", GetPlayerMoney() "
    .. tostring(call(GetPlayerMoney)) .. ", GetBagCount " .. tostring(used) .. "/" .. tostring(open) .. "/" .. tostring(total))
  local bag = GB.ReadBag()
  local first = bag[1]
  local link = first and call(GetBagItemLink, (call(GetBagItemInfo, first.slot)))
  add("bag: " .. #bag .. " filled slots; first " .. (first and (first.name .. " x" .. first.count .. ", id " .. first.id
    .. ", icon " .. tostring(first.icon) .. ", link " .. string.gsub(tostring(link), "|", "!")) or "none"))
  local bank, max = GB.ReadBank()
  add("bank now (window " .. (GB.bankOpen and "open" or "closed") .. "): " .. #bank .. " filled, GetBankNumItems "
    .. tostring(max) .. (bank[1] and (", first " .. bank[1].name .. " in slot " .. bank[1].slot) or ""))
  local c = me and GB.chars[me]
  add("saved snapshot: " .. string.len(tostring(GlobalBank_Char or "")) .. " characters, bank "
    .. (c and c.bank and (#c.bank .. " items") or "not seen yet") .. ", taken " .. tostring(c and c.when))
  add("helper: " .. GB.HelperState() .. ", beat " .. tostring(GB.lastBeat) .. ", folder " .. GB.HELPER_DIR)
  add("database " .. GB.DATABASE .. ": " .. (GB.db.loaded and (GB.db.count .. " characters, made " .. tostring(GB.db.made))
    or ("not loaded (" .. tostring(GB.db.error) .. ")")))
  local seen = {}
  for event, n in pairs(GB.events) do
    seen[#seen + 1] = event .. "=" .. n
  end
  table.sort(seen)
  local hooks = {}
  for name in pairs(GB.hooked) do
    hooks[#hooks + 1] = name
  end
  table.sort(hooks)
  add("events registered " .. table.concat(GB.registered or {}, " ") .. "; seen " .. table.concat(seen, " ")
    .. "; save before " .. (#hooks > 0 and table.concat(hooks, " ") or "nothing"))
  local function shown(f)
    if not f then
      return "missing"
    end
    local ok, v = pcall(function() return f:IsVisible() end)
    return ok and (v and "shown" or "hidden") or "?"
  end
  add("window: " .. shown(GlobalBankFrame) .. ", list rows " .. ((GlobalBankRow1 and GlobalBankRow19) and "yes" or "NO")
    .. ", item slots " .. ((GlobalBankItem1 and GlobalBankItem80) and "yes" or "NO") .. ", search box "
    .. yes(GlobalBankFrameSearch) .. ", scroll bars " .. yes(GlobalBankFrameListScroll and GlobalBankFrameGridScroll)
    .. ", last error " .. tostring(GB.lastError))
  local sizeErrors = {}
  for what, err in pairs(GB.sizeErrors or {}) do
    sizeErrors[#sizeErrors + 1] = what .. ": " .. err
  end
  add("size " .. tostring(GB.width) .. " x " .. tostring(GB.height) .. ", rows " .. tostring(GB.ROWS) .. "/" .. tostring(GB.GRID_ROWS)
    .. ", GetCursorPos " .. yes(GetCursorPos) .. ", GetUIScale " .. tostring(GetUIScale and GetUIScale())
    .. ", errors " .. (#sizeErrors > 0 and table.concat(sizeErrors, "; ") or "none"))
  local mine = 0
  for _ in pairs(GB.myNotes or {}) do
    mine = mine + 1
  end
  add("notes: " .. mine .. " waiting for the helper, " .. string.len(tostring(GlobalBank_Notes or "")) .. " characters saved")
  add("buttons: backpack " .. shown(GlobalBankBagButton) .. " (bag window " .. shown(BagFrame) .. "), zBag one bag "
    .. shown(GlobalBankZBagButton) .. " (zBag window " .. shown(zBag) .. "); os.date " .. yes(os and os.date)
    .. ", SetHyperLink " .. yes(GameTooltip and GameTooltip.SetHyperLink))
  GlobalBank_Probe = lines
  add("saved in your character's save file. Screenshot this, or send Documents\\Runes of Magic\\" .. tostring(me)
    .. "\\SaveVariables.lua after logout.")
end

SlashCmdList = SlashCmdList or {}
SLASH_GLOBALBANK1 = "/gb"
SLASH_GLOBALBANK2 = "/globalbank"
SlashCmdList["GLOBALBANK"] = function(editBox, msg)
  local text = string.lower(tostring((type(editBox) == "string" and editBox) or msg or ""))
  if string.find(text, "probe") then
    GB.Probe()
  elseif string.find(text, "refresh") then
    GB.Refresh()
  elseif string.find(text, "size") and GB.ResetSize then
    GB.ResetSize()
  elseif not GB.IsOn() then
    chat("turned off in the Cherry's Kit window (/ck).")
  else
    GB.Toggle()
  end
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "GlobalBank",
    title = "Global Bank",
    version = GB.version,
    installed = function()
      return true
    end,
    open = function()
      GB.Toggle()
      return true
    end,
  })
end
