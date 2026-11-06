-- Cherry's Kit: the bag and bank search also finds items by their stat names ("stamina" finds every
-- item with a stamina line). Numbers are not part of it: the stat names come from tooltip lines with
-- a signed number in them (Stamina +12, +5% Dexterity), with the numbers taken out.
--
-- Searching only looks at a cache (item link -> stat names), so it reads no tooltip and makes no
-- garbage once the items are known. An item that isn't in the cache yet only sets a flag; while you
-- search, K.StatsTick (from zBagKit.OnUpdate, 20 times a second) waits until the text has been still
-- for a moment, reads a few tooltips per tick with the hidden zBagKitTipReader (zBagKit.xml) and then
-- refreshes the search once. Nothing runs while the search boxes are empty.

local K = zBagKit

K.STATS_READS_PER_TICK = 6     -- tooltips read per 0.05 s tick
K.STATS_SLOTS_PER_TICK = 60    -- slots looked at per tick
K.STATS_SETTLE = 0.3           -- seconds the search text must stay the same before reading starts
K.STATS_CACHE_MAX = 800        -- items kept; the cache starts over past this
K.STATS_TIP_LINES = 40
K.BAG_STAT_SLOTS = 180
K.BANK_STAT_SLOTS = 300

-- Reload UI runs this file again in the same Lua state: start with an empty cache and no pending work.
K.statCache = {}
K.statColors = {}      -- item link -> each stat line's tooltip colour (rrggbb), one per line like the names
K.statCount = 0
K.statsMissing = false
K.statsText = nil      -- last search text a search used
K.statsWaitText = nil  -- text the settle timer belongs to
K.statsSettle = 0
K.statsCursor = 0      -- 1..180 bag, 181..480 bank
K.statsRead = 0        -- tooltips read in this sweep
K.statsReadTotal = 0

local tipLeft, tipRight -- the reader's FontStrings, looked up once
local parts = {}        -- reused while building one cache entry
local colorParts = {}

-- A tooltip line's colour as "rrggbb", or "" when the client can't tell. A |cAARRGGBB code at the start of
-- the text is the line's colour (as in Global Bank's tooltip reader), else the FontString's own.
local function lineColor(fs, text)
  if type(text) == "string" then
    local coded = string.match(text, "^|c%x%x(%x%x%x%x%x%x)")
    if coded then
      return string.lower(coded)
    end
  end
  if not fs or not fs.GetColor then
    return ""
  end
  local ok, r, g, b = pcall(fs.GetColor, fs)
  if not ok or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
    return ""
  end
  return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function tipLines()
  if tipLeft then
    return tipLeft ~= false
  end
  if not zBagKitTipReader then
    return false
  end
  tipLeft, tipRight = {}, {}
  for i = 1, K.STATS_TIP_LINES do
    tipLeft[i] = _G["zBagKitTipReaderTextLeft" .. i]
    tipRight[i] = _G["zBagKitTipReaderTextRight" .. i]
  end
  return true
end

-- Stat name from one tooltip line, or nil when the line has no signed number.
function K.StatName(text)
  if type(text) ~= "string" or text == "" then
    return nil
  end
  text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
  text = string.gsub(text, "|r", "")
  if not string.find(text, "[%+%-]%s*%d") then
    return nil
  end
  text = string.gsub(text, "[%+%-]?%s*%d+[%.,]?%d*%s*%%?", " ")
  text = string.gsub(text, "[%(%)%[%]:]", " ")
  text = string.gsub(text, "%s+", " ")
  text = string.gsub(text, "^ ", "")
  text = string.gsub(text, " $", "")
  if text == "" then
    return nil
  end
  return string.lower(text)
end

-- Every stat name on the tooltip the reader shows now, one per line ("" when it has none), and each
-- name's line colour in the same order.
function K.StatNamesFromTip()
  local n = 0
  -- line 1 is the item's name (which may end in a refine level like +6)
  for i = 2, K.STATS_TIP_LINES do
    local left, right = tipLeft[i], tipRight[i]
    local l = left and left:GetText()
    local r = right and right:GetText()
    if (l == nil or l == "") and (r == nil or r == "") then
      if not left then break end
    else
      local name = K.StatName(l)
      if name then n = n + 1; parts[n] = name; colorParts[n] = lineColor(left, l) end
      name = K.StatName(r)
      if name then n = n + 1; parts[n] = name; colorParts[n] = lineColor(right, r) end
    end
  end
  local names = n > 0 and table.concat(parts, "\n", 1, n) or ""
  local colors = n > 0 and table.concat(colorParts, "\n", 1, n) or ""
  for i = n, 1, -1 do
    parts[i] = nil
    colorParts[i] = nil
  end
  return names, colors
end

local function clearTip()
  for i = 1, K.STATS_TIP_LINES do
    if tipLeft[i] then tipLeft[i]:SetText("") end
    if tipRight[i] then tipRight[i]:SetText("") end
  end
end

-- Reads one item into the cache. bank: false for bag inventory index `index`, true for bank slot.
local function readItem(link, index, bank)
  local tip = zBagKitTipReader
  local compare1 = GameTooltip1 and GameTooltip1:IsVisible()
  local compare2 = GameTooltip2 and GameTooltip2:IsVisible()
  clearTip()
  local ok
  if bank then
    ok = pcall(tip.SetBankItem, tip, index)
  else
    ok = pcall(tip.SetBagItem, tip, index)
  end
  tip:Hide()
  -- the game can open its comparison tooltips beside any item tooltip
  if GameTooltip1 and not compare1 then GameTooltip1:Hide() end
  if GameTooltip2 and not compare2 then GameTooltip2:Hide() end
  local names, colors = "", ""
  if ok then
    local fine, text, lineColors = pcall(K.StatNamesFromTip)
    names = fine and text or ""
    colors = fine and lineColors or ""
  end
  if K.statCount >= K.STATS_CACHE_MAX then
    K.statCache = {}
    K.statColors = {}
    K.statCount = 0
  end
  K.statCache[link] = names
  K.statColors[link] = colors
  K.statCount = K.statCount + 1
  K.statsRead = K.statsRead + 1
  K.statsReadTotal = K.statsReadTotal + 1
end

-- true when the item behind `link` has a stat whose name contains `text` (already lower case).
-- An item not read yet counts as no match for now and asks the tick to read it.
function K.StatsMatch(link, text)
  if link == nil or link == "" or text == nil or text == "" then
    return false
  end
  if text == "#clean" then
    return K.StoneState(link) == 1
  elseif text == "#dirty" then
    return K.StoneState(link) == 2
  end
  K.statsText = text
  local names = K.statCache[link]
  if names == nil then
    K.statsMissing = true
    return false
  end
  return names ~= "" and string.find(names, text, 1, true) ~= nil
end

---------------------------------------------------------------------------
-- "#clean" and "#dirty" (the whole search text, any case): mana and fusion stones without stats, or
-- with stats. A stone's link holds, after its ID, mode and creation time, three numbers of two stat IDs
-- each (the same reading as Global Bank's GB.ReadStone), so no tooltip is needed. The answer is kept
-- per link: 0 = not a stone, 1 = clean, 2 = has stats, 3 = a weapon, armour or jewellery piece (ID 210000
-- to 239999, the same range Global Bank reads as gear; its link also holds its stats in fields 4-6).
---------------------------------------------------------------------------

K.stoneCache = {}
K.stoneCount = 0

local function isStone(id)
  return id and ((id >= 202840 and id <= 202859) or (id >= 202880 and id <= 202885))
end

local function isGear(id)
  return id and id >= 210000 and id < 240000
end

function K.StoneState(link)
  local state = K.stoneCache[link]
  if state then
    return state
  end
  state = 0
  local hex = type(link) == "string" and string.match(link, "|Hitem:([%x ]+)|h")
  local id = hex and tonumber(string.match(hex, "^%x+") or "", 16)
  if isGear(id) then
    state = 3
  elseif isStone(id) then
    state = 1
    local n = 0
    for value in string.gmatch(hex, "%x+") do
      n = n + 1
      if n >= 4 and n <= 6 then
        local v = tonumber(value, 16) or 0
        if v % 65536 > 0 or math.floor(v / 65536) > 0 then
          state = 2
          break
        end
      elseif n > 6 then
        break
      end
    end
  end
  if K.stoneCount >= K.STATS_CACHE_MAX then
    K.stoneCache = {}
    K.stoneCount = 0
  end
  K.stoneCache[link] = state
  K.stoneCount = K.stoneCount + 1
  return state
end

-- How many stats a stone's or gear's link carries (each link field 4-6 holds two 16-bit stat ids). One stat can
-- add several tooltip lines ("Furiousness of the Righteous": stamina and strength), so this counts
-- stats, not lines. Kept per link.
K.stoneStats = {}
K.stoneStatsCount = 0

function K.StoneStatCount(link)
  local count = K.stoneStats[link]
  if count then
    return count
  end
  count = 0
  local hex = type(link) == "string" and string.match(link, "|Hitem:([%x ]+)|h")
  if hex then
    local n = 0
    for value in string.gmatch(hex, "%x+") do
      n = n + 1
      if n >= 4 and n <= 6 then
        local v = tonumber(value, 16) or 0
        if v % 65536 > 0 then count = count + 1 end
        if math.floor(v / 65536) > 0 then count = count + 1 end
      elseif n > 6 then
        break
      end
    end
  end
  if K.stoneStatsCount >= K.STATS_CACHE_MAX then
    K.stoneStats = {}
    K.stoneStatsCount = 0
  end
  K.stoneStats[link] = count
  K.stoneStatsCount = K.stoneStatsCount + 1
  return count
end

function K.BagStatsMatch(index, text)
  if index == nil or index < 0 or not GetBagItemLink then
    return false
  end
  return K.StatsMatch(GetBagItemLink(index), text)
end

function K.BankStatsMatch(slot, text)
  if not GetBankItemLink then
    return false
  end
  return K.StatsMatch(GetBankItemLink(slot), text)
end

local function bankOpen()
  return (BankFrame and BankFrame:IsVisible()) or (zBagB and zBagB:IsVisible())
end

-- Shows the new matches in whichever search is open.
function K.RefreshStatSearch()
  if K.StatPrefixOn and K.StatPrefixOn() then
    K.StatPrefixRefresh()
    if zBag and zBag:IsVisible() and zBag_Update then pcall(zBag_Update) end
    if K.UpdateOverlaysNow then K.UpdateOverlaysNow() end
  end
  if AttemptBagSearch and BagSearchInstalled == 1 then
    pcall(AttemptBagSearch, "Bag")
    if bankOpen() then
      pcall(AttemptBagSearch, "Bank")
    end
  end
  if K.UpdateAll then K.UpdateAll() end
  if K.UpdateCherry then K.UpdateCherry() end
end

-- Called 20 times a second; does nothing unless a search found items it doesn't know yet.
function K.StatsTick(elapsed)
  if not K.statsMissing then
    return
  end
  if K.statsWaitText ~= K.statsText then
    K.statsWaitText = K.statsText
    K.statsSettle = K.STATS_SETTLE
    return
  end
  if K.statsSettle > 0 then
    K.statsSettle = K.statsSettle - (elapsed or 0.05)
    return
  end
  if not tipLines() then
    K.statsMissing = false
    return
  end
  local reads, looked = 0, 0
  local bank = bankOpen()
  local last = K.BAG_STAT_SLOTS + (bank and K.BANK_STAT_SLOTS or 0)
  local cache = K.statCache
  while K.statsCursor < last and reads < K.STATS_READS_PER_TICK and looked < K.STATS_SLOTS_PER_TICK do
    K.statsCursor = K.statsCursor + 1
    looked = looked + 1
    local c = K.statsCursor
    if c <= K.BAG_STAT_SLOTS then
      local index, _, name = GetBagItemInfo(c)
      if index and index >= 0 and name and name ~= "" then
        local link = GetBagItemLink(index)
        if link and link ~= "" and cache[link] == nil then
          readItem(link, index, false)
          reads = reads + 1
          cache = K.statCache
        end
      end
    else
      local slot = c - K.BAG_STAT_SLOTS
      local _, name = GetBankItemInfo(slot)
      if name and name ~= "" then
        local link = GetBankItemLink(slot)
        if link and link ~= "" and cache[link] == nil then
          readItem(link, slot, true)
          reads = reads + 1
          cache = K.statCache
        end
      end
    end
  end
  if K.statsCursor >= last then
    -- sweep done: show what it found, which also flags anything still missing for one more sweep
    K.statsCursor = 0
    K.statsMissing = false
    local found = K.statsRead
    K.statsRead = 0
    if found > 0 then
      K.RefreshStatSearch()
    else
      -- nothing new to read (an item the sweep can't reach): look again in 2 seconds at the earliest
      K.statsSettle = 2
    end
  end
end

---------------------------------------------------------------------------
-- BagSearch's finders, with stat names added (BagSearch.lua itself stays unchanged). They replace
-- the globals each time this file runs, so Reload UI doesn't stack them.
---------------------------------------------------------------------------

function FindBagItemByName(itemName)
  if type(itemName) ~= "string" then
    return nil
  end
  local text = string.lower(itemName)
  local _, _, totalSlots = GetBagCount()
  local itemList = {}
  for i = 1, totalSlots do
    local index, _, name = GetBagItemInfo(i)
    if name and name ~= "" and (string.find(string.lower(name), text, 1, true) or K.BagStatsMatch(index, text)) then
      table.insert(itemList, i)
    end
  end
  return itemList
end

function FindBankItemByName(itemName)
  if type(itemName) ~= "string" then
    return nil
  end
  local text = string.lower(itemName)
  local itemList = {}
  for i = 1, 200 do
    local _, name = GetBankItemInfo(i)
    if name and name ~= "" and (string.find(string.lower(name), text, 1, true) or K.BankStatsMatch(i, text)) then
      table.insert(itemList, i)
    end
  end
  return itemList
end

---------------------------------------------------------------------------
-- "Stats" tick beside the bag search (zBag_VAR["statprefix"] = 1): a mana stone or a piece of gear with one
-- stat shows its short name on the bag icon, one with more shows "2x" to "6x", in every layout. The name
-- takes the colour set for that stat (K.STAT_COLORS, changed in zBag's settings under Stat colours), and the
-- icon gets an outline in the colour of the stat's tooltip line (bright orange or bright yellow; green
-- stats get none). The names come from the same cache as the stat search; items not read yet are read by
-- K.StatsTick and drawn after.
-- Each icon only looks its item up again when the bags change (K.prefixGen) or it holds another
-- slot, so an open bag costs nothing between bag events.
---------------------------------------------------------------------------

K.SHORT_STATS = {
  ["strength"] = "str", ["stamina"] = "stam", ["dexterity"] = "dex", ["intelligence"] = "int",
  ["wisdom"] = "wis", ["all attributes"] = "all", ["all main attributes"] = "all",
  ["physical attack"] = "patt", ["magical attack"] = "matt", ["magic attack"] = "matt",
  ["physical defense"] = "def", ["defense"] = "def", ["magical defense"] = "mdef", ["magic defense"] = "mdef",
  ["maximum health"] = "hp", ["max health"] = "hp", ["max hp"] = "hp", ["health"] = "hp", ["hp"] = "hp",
  ["maximum mana"] = "mp", ["max mana"] = "mp", ["max mp"] = "mp", ["mana"] = "mp", ["mp"] = "mp",
  ["physical damage"] = "pdmg", ["magical damage"] = "mdmg", ["magic damage"] = "mdmg",
  ["physical critical rate"] = "pcrit", ["magical critical rate"] = "mcrit", ["critical rate"] = "crit",
  ["physical critical hit rate"] = "pcrit", ["magical critical hit rate"] = "mcrit", ["critical hit rate"] = "crit",
  ["accuracy"] = "acc", ["physical accuracy"] = "acc", ["magical accuracy"] = "macc",
  ["dodge rate"] = "dodge", ["parry rate"] = "parry", ["attack speed"] = "aspd", ["casting speed"] = "cast",
  ["block rate"] = "block", ["movement speed"] = "move", ["healing"] = "heal", ["heal"] = "heal", ["resistance"] = "res",
}

-- German client names, UTF-8 written as escapes (\195\164 is a with umlaut). StatName lower-cases
-- only ASCII letters, so umlauts stay as they are.
K.SHORT_STATS_DE = {
  ["st\195\164rke"] = "str", ["ausdauer"] = "stam", ["geschicklichkeit"] = "dex", ["intelligenz"] = "int",
  ["weisheit"] = "wis", ["alle attribute"] = "all", ["alle hauptattribute"] = "all",
  ["physischer angriff"] = "patt", ["physische angriffskraft"] = "patt", ["magischer angriff"] = "matt",
  ["magische angriffskraft"] = "matt", ["physische verteidigung"] = "def", ["verteidigung"] = "def",
  ["magische verteidigung"] = "mdef", ["maximale lp"] = "hp", ["max. lp"] = "hp", ["lp"] = "hp",
  ["lebenspunkte"] = "hp", ["maximale mp"] = "mp", ["max. mp"] = "mp", ["mp"] = "mp", ["mana"] = "mp",
  ["physischer schaden"] = "pdmg", ["magischer schaden"] = "mdmg", ["genauigkeit"] = "acc",
  ["physische genauigkeit"] = "acc", ["magische genauigkeit"] = "macc", ["ausweichrate"] = "dodge",
  ["parierrate"] = "parry", ["blockrate"] = "block", ["angriffsgeschwindigkeit"] = "aspd",
  ["zaubergeschwindigkeit"] = "cast", ["bewegungsgeschwindigkeit"] = "move", ["heilung"] = "heal",
  ["kritische trefferrate"] = "crit", ["physische kritische trefferrate"] = "pcrit",
  ["magische kritische trefferrate"] = "mcrit", ["widerstand"] = "res",
}
for name, short in pairs(K.SHORT_STATS_DE) do
  K.SHORT_STATS[name] = K.SHORT_STATS[name] or short
end

-- The colour of each main stat's label (zBag settings, Stat colours: a picker per stat). These are the
-- defaults; zBag_VAR["statcolors"][key] holds what was picked. Every stat not named here ("all attributes",
-- hit points, critical rate ...) uses the "other" colour.
K.STAT_COLORS = {
  str = "ff8c1a", dex = "33e633", wis = "b34dff", int = "ffe619", stam = "19d9c6",
  matt = "ffe619", patt = "ff8c1a", def = "33e633", mdef = "19d9c6", other = "ffffff",
}
-- The rows of the Stat colours window, in order (zBagKitStatColorsColor1-10).
K.STAT_COLOR_ORDER = { "str", "dex", "wis", "int", "stam", "matt", "patt", "def", "mdef", "other" }
K.STAT_COLOR_NAMES = {
  str = "Strength", dex = "Dexterity", wis = "Wisdom", int = "Intelligence", stam = "Stamina",
  matt = "Magical attack", patt = "Physical attack", def = "Defense", mdef = "Magical defense", other = "All other stats",
}

-- A single stat that adds several stat lines shows each line's name, one per line, in that stat's colour
-- and this order ("Sta" over "Str").
K.COMBINED_ORDER = { stam = 1, str = 2, dex = 3, int = 4, wis = 5, patt = 6, matt = 7, def = 8, mdef = 9 }
K.COMBINED_NAMES = { stam = "Sta", str = "Str", dex = "Dex", int = "Int", wis = "Wis" }
K.COUNT_TEXT = { "1x", "2x", "3x", "4x", "5x", "6x" }

-- The outline round the icon of a single-stat item, by the stat's tooltip colour: bright orange and bright
-- yellow, 3 pixels wide with a black pixel on each side (statring.tga and statring-back.tga). Green stats
-- get no outline.
K.OUTLINE_COLORS = { orange = "ff8a00", yellow = "ffee00" }

-- The colour a stat's label takes: the picked one, else the default; any stat not listed uses "other".
function K.StatColor(short)
  local key = K.STAT_COLORS[short] and short or "other"
  local picked = type(zBag_VAR) == "table" and zBag_VAR["statcolors"]
  local value = type(picked) == "table" and picked[key]
  if type(value) == "string" and string.find(value, "^%x%x%x%x%x%x$") then
    return value
  end
  return K.STAT_COLORS[key]
end

-- "rrggbb" -> red, green, blue as 0 to 1 (white when it isn't a colour).
function K.HexRgb(hex)
  if type(hex) ~= "string" or not string.find(hex, "^%x%x%x%x%x%x$") then
    return 1, 1, 1
  end
  return tonumber(string.sub(hex, 1, 2), 16) / 255, tonumber(string.sub(hex, 3, 4), 16) / 255,
    tonumber(string.sub(hex, 5, 6), 16) / 255
end

-- Which of the three stat colours a tooltip line has: "orange" (f0610d), "yellow" (ffff00), "green"
-- (00ff00), judged by the colour's parts so a slightly different shade still counts; nil for white, class
-- colours and anything else.
function K.LineKind(color)
  if type(color) ~= "string" or not string.find(color, "^%x%x%x%x%x%x$") then
    return nil
  end
  local r = tonumber(string.sub(color, 1, 2), 16)
  local g = tonumber(string.sub(color, 3, 4), 16)
  local b = tonumber(string.sub(color, 5, 6), 16)
  if b > 90 then
    return nil
  end
  if r >= 200 and g >= 200 then
    return "yellow"
  elseif r >= 200 and g >= 70 then
    return "orange"
  elseif g >= 200 and r <= 90 then
    return "green"
  end
  return nil
end

K.prefixCache = {}
K.prefixOutline = {}   -- item link -> outline colour (rrggbb) of its label, or false
K.prefixCount = 0
K.prefixGen = (K.prefixGen or 0) + 1

function K.StatPrefixOn()
  return K.IsOn() and type(zBag_VAR) == "table" and zBag_VAR["statprefix"] == 1
end

-- Drops a UTF-8 character cut in half at the end of a short name.
function K.CutUtf8(text)
  local last = string.byte(text, -1)
  if last and last >= 192 then
    return string.sub(text, 1, -2)
  end
  if last and last >= 128 then
    local lead = string.byte(text, -2)
    if lead and lead >= 224 then return string.sub(text, 1, -3) end
  end
  return text
end

-- "physical attack" -> "patt": a known name, else the first letters of the leading words and three
-- of the last ("magical defense" -> "mdef"), or a single word's first four.
function K.ShortStat(name)
  local known = K.SHORT_STATS[name]
  if known then
    return known
  end
  local initials, last = "", nil
  -- letters include UTF-8 bytes, so "st\195\164rke" stays one word
  for word in string.gmatch(name, "[%a\128-\255]+") do
    if last then
      initials = initials .. string.sub(last, 1, 1)
    end
    last = word
  end
  if not last then
    return K.CutUtf8(string.sub(name, 1, 4))
  end
  if initials == "" then
    return K.CutUtf8(string.sub(last, 1, 4))
  end
  return K.CutUtf8(string.sub(initials, 1, 2)) .. K.CutUtf8(string.sub(last, 1, 3))
end

local combined, combinedColor, colorList = {}, {}, {}
local function combinedBefore(a, b)
  local oa, ob = K.COMBINED_ORDER[a] or 99, K.COMBINED_ORDER[b] or 99
  if oa ~= ob then return oa < ob end
  return a < b
end

-- Rarer stat colours first when one label shows two colours ("2" orange, "x" yellow).
K.LINE_KIND_RANK = { orange = 1, yellow = 2, green = 3 }
local function colorBefore(a, b)
  local ra, rb = K.LINE_KIND_RANK[K.LineKind(a)] or 5, K.LINE_KIND_RANK[K.LineKind(b)] or 5
  if ra ~= rb then return ra < rb end
  return a < b
end

local function paint(color, text)
  if color and color ~= "" then
    return "|cff" .. color .. text .. "|r"
  end
  return text
end

-- The text for an item's stat names ("" when it has none) and the outline colour for its icon (nil for
-- none). stats: how many stats the link carries (K.StoneStatCount), or nil to count the names. colors: each
-- name's tooltip line colour ("rrggbb", one per line like the names), or nil. gear: a weapon, armour or
-- jewellery piece, whose tooltip also has lines that aren't stats; only the lines in a stat colour count then.
--   one stat: its short name in that stat's colour (K.StatColor), and the icon outlined in the colour of
--   its tooltip line (orange or yellow); a stat with several lines (Sta over Str) is still one stat
--   2 to 6 stats: only how many ("2x" ... "6x"), in the tooltip colours, no outline
function K.StatPrefixText(names, stats, colors, gear)
  -- one line per stat, without repeats, with the first colour seen for it
  local n, c = 0, 0
  local nextColor = colors and colors ~= "" and string.gmatch(colors .. "\n", "([^\n]*)\n")
  for name in string.gmatch(names, "[^\n]+") do
    local color = nextColor and nextColor() or ""
    if not (gear and color ~= "" and not K.LineKind(color)) then
      local short = K.ShortStat(name)
      local seen = false
      for i = 1, n do
        if combined[i] == short then seen = true; break end
      end
      if not seen then
        n = n + 1
        combined[n] = short
        combinedColor[short] = color
      end
      if color ~= "" then
        local known = false
        for i = 1, c do
          if colorList[i] == color then known = true; break end
        end
        if not known then c = c + 1; colorList[c] = color end
      end
    end
  end
  local text, outline
  if n == 0 then
    -- gear whose lines gave no stat: the link still knows how many it has
    text = (gear and stats and stats > 0) and (K.COUNT_TEXT[stats] or (stats .. "x")) or ""
  elseif (stats and stats > 1) or (not stats and n > 1) then
    -- 2 to 6 stats: only how many ("2x" ... "6x"), in the stats' colour, or the count in the rarest
    -- colour and the x in the next one when they differ
    local count = stats or n
    table.sort(colorList, colorBefore)
    if c >= 2 then
      text = paint(colorList[1], tostring(count)) .. paint(colorList[2], "x")
    else
      text = paint(colorList[1], K.COUNT_TEXT[count] or (count .. "x"))
    end
  else
    -- one stat: the outline takes the rarest colour among its lines
    table.sort(colorList, colorBefore)
    outline = K.OUTLINE_COLORS[K.LineKind(colorList[1])]
    if n == 1 then
      text = paint(K.StatColor(combined[1]), combined[1])
    else
      -- one stat with several lines: every line's name, stacked ("Sta" over "Str")
      table.sort(combined, combinedBefore)
      text = ""
      for i = 1, n do
        local short = combined[i]
        text = text .. (i > 1 and "\n" or "") .. paint(K.StatColor(short), K.COMBINED_NAMES[short] or short)
      end
    end
  end
  for i = n, 1, -1 do
    combinedColor[combined[i]] = nil
    combined[i] = nil
  end
  for i = c, 1, -1 do
    colorList[i] = nil
  end
  return text, outline
end

-- The label and outline colour for one item, kept per item link. gear: see K.StatPrefixText.
function K.ItemLabel(link, names, gear)
  local text = K.prefixCache[link]
  if text then
    return text, K.prefixOutline[link] or nil
  end
  local outline
  text, outline = K.StatPrefixText(names, K.StoneStatCount(link), K.statColors[link], gear)
  if K.prefixCount >= K.STATS_CACHE_MAX then
    K.prefixCache = {}
    K.prefixOutline = {}
    K.prefixCount = 0
  end
  K.prefixCache[link] = text
  K.prefixOutline[link] = outline or false
  K.prefixCount = K.prefixCount + 1
  return text, outline
end

-- Draws (or clears) the outline round an icon: the black ring under the coloured one, both sized like the
-- slot. The two textures are in the slot templates (zBagTmpl.xml, zBagKit.xml); outline: "rrggbb" or nil.
function K.DrawRing(owner, outline, width, height)
  local back, ring = owner.kitRingBack, owner.kitRing
  if back == nil then
    local name = owner:GetName()
    back = _G[name .. "KitRingBack"] or false
    ring = _G[name .. "KitRing"] or false
    owner.kitRingBack, owner.kitRing = back, ring
  end
  if not back or not ring then
    return
  end
  if outline then
    if back.SetSize then
      back:SetSize(width, height)
      ring:SetSize(width, height)
    end
    ring:SetColor(K.HexRgb(outline))
    back:Show()
    ring:Show()
  else
    back:Hide()
    ring:Hide()
  end
end

-- Draws (or clears) the short stat names and the outline on one icon. owner: zBag's item button or an
-- individual-bags overlay; index: the item's inventory index (nil or < 0 for none); size: font size.
-- bagSlot (1-180) instead of index: the index is looked up only when the icon needs it.
-- bankSlot (1-300) instead of both: a bank slot.
function K.StatPrefix(owner, index, size, bagSlot, bankSlot)
  if not owner then
    return
  end
  local text, outline = "", nil
  local key = bagSlot or index
  if bankSlot then key = -bankSlot end -- bank keys never meet bag keys
  if key and (bankSlot or bagSlot or index >= 0) and K.StatPrefixOn() then
    if owner.kitStatIndex == key and owner.kitStatGen == K.prefixGen then
      return
    end
    owner.kitStatIndex, owner.kitStatGen = key, K.prefixGen
    if bagSlot then
      index = GetBagItemInfo(bagSlot)
    end
    local link
    if bankSlot then
      link = GetBankItemLink and GetBankItemLink(bankSlot)
    else
      link = index and index >= 0 and GetBagItemLink and GetBagItemLink(index)
    end
    -- mana and fusion stones with stats, and gear with stats; a clean stone has nothing to show
    local state = link and link ~= "" and K.StoneState(link)
    if state == 2 or (state == 3 and K.StoneStatCount(link) > 0) then
      local names = K.statCache[link]
      if names == nil then
        K.statsMissing = true
        owner.kitStatGen = nil -- look again after the read
      elseif names ~= "" or state == 3 then
        text, outline = K.ItemLabel(link, names, state == 3)
      end
    end
  else
    owner.kitStatIndex, owner.kitStatGen = nil, nil
  end
  size = math.floor((size or K.SlotNumberFontSize()) + 0.5)
  local width, height = K.SlotSize(owner)
  if owner.kitStatText == text and owner.kitStatSize == size and owner.kitStatWidth == width
    and owner.kitStatOutline == outline then
    return
  end
  owner.kitStatText, owner.kitStatSize, owner.kitStatWidth, owner.kitStatOutline = text, size, width, outline
  K.DrawRing(owner, outline, width, height)
  local fs = owner.kitStatFS
  if fs == nil then
    fs = _G[owner:GetName() .. "KitStats"] or false
    owner.kitStatFS = fs
  end
  if not fs then
    return
  end
  if text == "" then
    fs:SetText("")
    fs:Hide()
    return
  end
  -- the text fills the slot inside the outline (5 pixels in on every side): the font shrinks until the
  -- longest line and every line fit
  if fs.SetSize then
    fs:SetSize(width - 10, height - 10)
  end
  size = K.FitLabelSize(text, size, width - 8, height - 8)
  -- the client takes a font change only after the text changed; a thick black outline keeps the
  -- label readable on any icon
  fs:SetText("z")
  fs:SetText(text)
  if not (fs.SetFont and pcall(fs.SetFont, fs, K.LABEL_FONT, size, "NORMAL", "THICK")) then
    fs:SetFontSize(size)
  end
  fs:Show()
end

K.LABEL_FONT = "Fonts/DFHEIMDU.TTF"
K.LABEL_CHAR_WIDTH = 0.62 -- average letter width per point of font size, outline included below
K.LABEL_MIN_SIZE = 6

-- The slot's size (36 x 36 when the client can't tell).
function K.SlotSize(owner)
  local w, h
  if owner.GetWidth then
    local ok, value = pcall(owner.GetWidth, owner)
    if ok and type(value) == "number" and value > 8 then w = value end
  end
  if owner.GetHeight then
    local ok, value = pcall(owner.GetHeight, owner)
    if ok and type(value) == "number" and value > 8 then h = value end
  end
  return math.floor(w or 36), math.floor(h or w or 36)
end

-- The largest font size (up to `size`) at which every line of the label fits a width x height slot.
function K.FitLabelSize(text, size, width, height)
  local plain = string.gsub(string.gsub(text, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
  local lines, longest = 0, 0
  for line in string.gmatch(plain, "[^\n]+") do
    lines = lines + 1
    -- a UTF-8 letter is one character, not two bytes
    local chars = string.len(string.gsub(line, "[\128-\191]", ""))
    if chars > longest then longest = chars end
  end
  if lines == 0 then
    return size
  end
  local fitWidth = (width - 4) / (longest * K.LABEL_CHAR_WIDTH)
  local fitHeight = (height - 2) / lines
  local fit = math.floor(math.min(size, fitWidth, fitHeight))
  if fit < K.LABEL_MIN_SIZE then fit = K.LABEL_MIN_SIZE end
  return fit
end

-- Bags changed, or the tick or the cache did: every icon looks its item up again.
function K.StatPrefixRefresh()
  K.prefixGen = K.prefixGen + 1
end

function K.SyncStatTicks()
  local on = type(zBag_VAR) == "table" and zBag_VAR["statprefix"] == 1
  if zBagKitStatTick then zBagKitStatTick:SetChecked(on) end
  if zBagKitStatTickCB then zBagKitStatTickCB:SetChecked(on) end
end

function K.ToggleStatPrefix(tick)
  if type(zBag_VAR) ~= "table" then zBag_VAR = {} end
  zBag_VAR["statprefix"] = (tick and tick:IsChecked()) and 1 or 0
  K.SaveSettings()
  K.SyncStatTicks()
  K.StatPrefixRefresh()
  K.RefreshStatPrefixes()
end

-- Redraws the bag icons of whichever layout is open.
function K.RefreshStatPrefixes()
  if zBag and zBag:IsVisible() and zBag_Update then pcall(zBag_Update) end
  if K.UpdateAll then K.UpdateAll() end
  if K.UpdateCherry then K.UpdateCherry() end
  if K.UpdateOverlaysNow then K.UpdateOverlaysNow() end
end

---------------------------------------------------------------------------
-- Stat colours (zBag settings, "Stat colours..."; zBagKitStatColors in zBagKit.xml): one swatch per main
-- stat opens the game's colour picker. Only what was changed is saved, in zBag_VAR["statcolors"].
---------------------------------------------------------------------------

-- Labels are cached per item, so a new colour starts them over and redraws the open bags.
local function colorsChanged()
  K.prefixCache = {}
  K.prefixOutline = {}
  K.prefixCount = 0
  K.SaveSettings()
  K.StatPrefixRefresh()
  K.RefreshStatPrefixes()
end

local function hexOf(r, g, b)
  local function part(v)
    return math.max(0, math.min(255, math.floor((tonumber(v) or 0) * 255 + 0.5)))
  end
  return string.format("%02x%02x%02x", part(r), part(g), part(b))
end

function K.SetStatColor(key, hex)
  if not K.STAT_COLORS[key] or type(hex) ~= "string" or not string.find(hex, "^%x%x%x%x%x%x$") then
    return false
  end
  if type(zBag_VAR) ~= "table" then zBag_VAR = {} end
  if type(zBag_VAR["statcolors"]) ~= "table" then zBag_VAR["statcolors"] = {} end
  hex = string.lower(hex)
  -- a colour equal to the default is not kept
  zBag_VAR["statcolors"][key] = hex ~= K.STAT_COLORS[key] and hex or nil
  colorsChanged()
  K.RefreshStatColorRows()
  return true
end

function K.ResetStatColors()
  if type(zBag_VAR) == "table" then
    zBag_VAR["statcolors"] = nil
  end
  colorsChanged()
  K.RefreshStatColorRows()
end

-- The swatches and names in the window show the colours in use; each name is written in its colour.
function K.RefreshStatColorRows()
  for i, key in ipairs(K.STAT_COLOR_ORDER) do
    local color = K.StatColor(key)
    local block = _G["zBagKitStatColorsColor" .. i .. "Block"]
    if block then
      block:SetColor(K.HexRgb(color))
    end
    local label = _G["zBagKitStatColorsLabel" .. i]
    if label then
      label:SetText("|cff" .. color .. K.STAT_COLOR_NAMES[key] .. "|r")
    end
  end
end

function K.ToggleStatColors()
  if not zBagKitStatColors then return end
  if zBagKitStatColors:IsVisible() then
    zBagKitStatColors:Hide()
  else
    zBagKitStatColors:Show()
  end
end

-- Opens the game's colour picker for row `id`; OK saves, a move of the picker shows live in the swatch,
-- Cancel puts the saved colour back.
function K.PickStatColor(id)
  local key = K.STAT_COLOR_ORDER[id]
  local swatch = _G["zBagKitStatColorsColor" .. id]
  if not key or not swatch then return end
  local block = _G["zBagKitStatColorsColor" .. id .. "Block"]
  local r, g, b = K.HexRgb(K.StatColor(key))
  local function okay()
    K.SetStatColor(key, hexOf(ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b))
  end
  local function update()
    if block then block:SetColor(ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b) end
  end
  local function cancel()
    K.RefreshStatColorRows()
  end
  if ColorPickerFrame then
    if ColorPickerFrame.SetFrameStrata then ColorPickerFrame:SetFrameStrata("DIALOG") end
    ColorPickerFrame.call = swatch
  end
  if OpenColorPickerFrameEx then
    OpenColorPickerFrameEx({
      parent = swatch, titleText = "zBag - " .. K.STAT_COLOR_NAMES[key], alphaMode = nil,
      r = r, g = g, b = b, a = 1, brightnessUp = 1, brightnessDown = 0.2,
      callbackFuncOkay = okay, callbackFuncUpdate = update, callbackFuncCancel = cancel,
    })
  elseif OpenColorPickerFrame then
    OpenColorPickerFrame(okay, false, "zBag - " .. K.STAT_COLOR_NAMES[key], r, g, b, 1, zBagKitStatColors)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("zBag: this client has no colour picker. Use /zb color " .. key .. " rrggbb")
  end
end

-- /zb colors opens the window; /zb color <stat> <rrggbb> sets one (stat: str dex wis int stam matt patt def mdef other).
function K.StatColorCommand(rest)
  local key, hex = string.match(rest or "", "^(%a+)%s+#?(%x+)%s*$")
  if key and K.STAT_COLORS[string.lower(key)] and hex and string.len(hex) == 6 then
    K.SetStatColor(string.lower(key), hex)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("zBag: /zb color <stat> <rrggbb>, for example /zb color str ff8800. Stats: str dex wis int stam matt patt def mdef other. /zb colors opens the colour window.")
  end
end
