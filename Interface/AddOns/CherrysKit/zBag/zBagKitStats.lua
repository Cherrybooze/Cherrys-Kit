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

-- Every stat name on the tooltip the reader shows now, one per line ("" when it has none).
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
      if name then n = n + 1; parts[n] = name end
      name = K.StatName(r)
      if name then n = n + 1; parts[n] = name end
    end
  end
  local names = n > 0 and table.concat(parts, "\n", 1, n) or ""
  for i = n, 1, -1 do
    parts[i] = nil
  end
  return names
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
  local names = ""
  if ok then
    local fine, text = pcall(K.StatNamesFromTip)
    names = fine and text or ""
  end
  if K.statCount >= K.STATS_CACHE_MAX then
    K.statCache = {}
    K.statCount = 0
  end
  K.statCache[link] = names
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
-- per link: 0 = not a stone, 1 = clean, 2 = has stats.
---------------------------------------------------------------------------

K.stoneCache = {}
K.stoneCount = 0

local function isStone(id)
  return id and ((id >= 202840 and id <= 202859) or (id >= 202880 and id <= 202885))
end

function K.StoneState(link)
  local state = K.stoneCache[link]
  if state then
    return state
  end
  state = 0
  local hex = type(link) == "string" and string.match(link, "|Hitem:([%x ]+)|h")
  local id = hex and tonumber(string.match(hex, "^%x+") or "", 16)
  if isStone(id) then
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
