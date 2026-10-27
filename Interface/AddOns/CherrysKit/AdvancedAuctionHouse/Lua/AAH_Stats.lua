-- Cherry's Kit: the compact Stats column in Browse.
--
-- The column shows only an item's added stats: the named stat slots (orange/yellow lines such as
-- "+471.6 Dexterity   Triumph of the Minotaurs" followed by "+1178.4 Physical Attack"), the ones that
-- come off when the item is sharded. The item's own (innate, green) stats are left out. There are
-- at most 6 slots; each is shown as "1:Dex472+Patt1178", three slots a line when the column is
-- wide enough ("1: 2: 3:" over "4: 5: 6:"), otherwise two a line. Hover a cell for the slot names,
-- full stat names and totals, hover the Stats header for the legend. Sorting and the $str/30 filters
-- use the added stats' totals (listing.raw).

local Stats = {}
AAH.Stats = Stats

local GOLD, ORANGE, BLUE, GREEN, PURPLE = "ffd200", "ff9a40", "80c8ff", "80ff80", "d0a8ff"

-- key in the listing, short tag, full name, tag colour. The order is the order in the cell.
Stats.ORDER = {
	{ "str",   "Str",   "Strength",               GOLD },
	{ "dex",   "Dex",   "Dexterity",              GOLD },
	{ "sta",   "Sta",   "Stamina",                GOLD },
	{ "int",   "Int",   "Intelligence",           GOLD },
	{ "wis",   "Wis",   "Wisdom",                 GOLD },
	{ "patt",  "Patt",  "Physical Attack",        ORANGE },
	{ "matt",  "Matt",  "Magical Attack",         ORANGE },
	{ "pdam",  "Dmg",   "Weapon Damage",          ORANGE },
	{ "mdam",  "Mdmg",  "Magical Damage",         ORANGE },
	{ "pdef",  "Pdef",  "Physical Defense",       BLUE },
	{ "mdef",  "Mdef",  "Magical Defense",        BLUE },
	{ "hp",    "HP",    "Maximum HP",             GREEN },
	{ "mp",    "MP",    "Maximum MP",             GREEN },
	{ "pcrit", "Pcrit", "Physical Critical Rate", PURPLE },
	{ "mcrit", "Mcrit", "Magical Critical Rate",  PURPLE },
	{ "pacc",  "Acc",   "Physical Accuracy",      PURPLE },
	{ "macc",  "Macc",  "Magical Accuracy",       PURPLE },
	{ "pdod",  "Dodge", "Physical Dodge Rate",    PURPLE },
	{ "parry", "Parry", "Parry Rate",             PURPLE },
	{ "heal",  "Heal",  "Healing Bonus",          PURPLE },
}
Stats.ATTRIBUTES = { "str", "dex", "sta", "int", "wis" }
Stats.BY_KEY = {}
for _, s in ipairs(Stats.ORDER) do
	Stats.BY_KEY[s[1]] = s
end

Stats.MAX_SLOTS = 6

local function plain(text)
	if not text then
		return nil
	end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = string.gsub(text, "|r", "")
	return text
end

-- Called by ParseToolTip for every tooltip line, top to bottom. key/value are what ParseLine read
-- from the left text (nil when it is not a stat AAH knows). A stat line with a name on its right
-- starts a slot; stat lines without a right text that follow it belong to that slot; the first
-- other line after the slots (for example "Rune (0/4)") ends them.
function Stats.ReadSlotLine(listing, left, right, key, value)
	left, right = plain(left), plain(right)
	-- "Power Modifier +20%": the bonus the slot values carry (see Stats.Normalize)
	for _, text in ipairs({ left or "", right or "" }) do
		local pct = string.match(text, "[Mm]odifier%s*%+%s*([%d%.]+)%s*%%")
		if pct then
			listing.powerMod = tonumber(pct)
		end
	end
	local slots = listing.slots
	if not slots or listing.slotsDone then
		return
	end
	local sign, num, rest
	if left then
		sign, num, rest = string.match(left, "^%s*([%+%-])%s*([%d%.]+)%%?%s*(.-)%s*$")
	end
	local isStat = num ~= nil
	local stat
	if isStat then
		local v = tonumber(value) or tonumber(num) or 0
		if sign == "-" then
			v = -math.abs(v)
		end
		stat = { key = Stats.BY_KEY[key or ""] and key or nil, value = v, label = rest }
	end
	local named = right and string.find(right, "%S") and not string.find(right, "%d")
	if isStat and named then
		if #slots >= Stats.MAX_SLOTS then
			listing.slotsDone = true
			return
		end
		table.insert(slots, { name = right, stats = { stat } })
	elseif isStat and not right and #slots > 0 then
		table.insert(slots[#slots].stats, stat)
	elseif #slots > 0 and left and string.find(left, "%S") then
		listing.slotsDone = true
	end
end

Stats.CHAR_W = 5.6 -- rough width of one character of the cell font (height 11), in UI units
Stats.LINES = 3   -- a 40-high row holds three lines of the small font

-- Totals of the added stats (the slots) into listing.raw, for sorting and the stat filters.
-- Items with more than 101 maximum durability get +20% on their stats in the tooltip ("Power
-- Modifier +20%"). The column, sorting and filters always use the values without that bonus, so
-- the same stat compares the same on any item (471.6 at 102 durability shows as 393). The
-- percentage on the "Power Modifier" line is used when the tooltip has one (English client);
-- otherwise +20% when the maximum durability is over 101.
Stats.DURA_LIMIT = 101
Stats.DURA_BONUS = 1.2

-- Takes the durability bonus off the slot values (once per listing).
function Stats.Normalize(listing)
	if listing.slotsBonus then
		return
	end
	local bonus
	if listing.powerMod then
		bonus = 1 + listing.powerMod / 100
	elseif (tonumber(listing.dura) or 0) > Stats.DURA_LIMIT then
		bonus = Stats.DURA_BONUS
	end
	if not bonus or bonus <= 1 then
		return
	end
	listing.slotsBonus = bonus
	for _, slot in ipairs(listing.slots or {}) do
		for _, stat in ipairs(slot.stats) do
			stat.value = math.floor(stat.value / bonus * 10 + 0.5) / 10
		end
	end
end

function Stats.Capture(listing)
	Stats.Normalize(listing)
	local raw = {}
	for _, st in ipairs(Stats.ORDER) do
		raw[st[1]] = 0
	end
	for _, slot in ipairs(listing.slots or {}) do
		for _, stat in ipairs(slot.stats) do
			if stat.key then
				raw[stat.key] = raw[stat.key] + stat.value
			end
		end
	end
	listing.raw = raw
	local sum = 0
	for _, k in ipairs(Stats.ATTRIBUTES) do
		sum = sum + raw[k]
	end
	listing.statsum = sum
	return raw
end

-- Values of 100 and more without decimals (472, 1178), smaller ones with one (4.5).
-- short = true writes 1000 and more as 1.2k.
function Stats.Fmt(v, short)
	if short and math.abs(v) >= 1000 then
		return string.format("%.1fk", v / 1000)
	end
	if math.abs(v) >= 100 or v == math.floor(v) then
		return tostring(math.floor(v + 0.5))
	end
	return string.format("%.1f", v)
end

-- Short tag and colour of a stat in a slot.
function Stats.Tag(stat)
	local st = stat.key and Stats.BY_KEY[stat.key]
	if st then
		return st[2], st[4], st[3]
	end
	local label = stat.label or "?"
	return string.sub(string.gsub(label, "%s", ""), 1, 4), "cccccc", label
end

-- "1:Dex472+Patt1178": plain text (for measuring) and coloured text.
local function slotText(i, slot, short)
	local plainParts, colorParts = {}, {}
	for _, stat in ipairs(slot.stats) do
		local tag, color = Stats.Tag(stat)
		local v = Stats.Fmt(stat.value, short)
		table.insert(plainParts, tag .. v)
		table.insert(colorParts, "|cff" .. color .. tag .. "|r" .. v)
	end
	return i .. ":" .. table.concat(plainParts, "+"), "|cff999999" .. i .. ":|r" .. table.concat(colorParts, "+")
end

-- One entry per added stat with its total, in ORDER (for the tooltip).
function Stats.Totals(listing)
	local out = {}
	local raw = listing and listing.raw
	if not raw then
		return out
	end
	for _, st in ipairs(Stats.ORDER) do
		local v = raw[st[1]]
		if v and v ~= 0 then
			table.insert(out, { st[2], v, st[4], st[3], st[1] })
		end
	end
	return out
end

Stats.GAP = "  " -- between slots on a line

-- Cell text for a column `width` units wide: the slots, three a line if that fits in two lines,
-- else two a line (three lines); values shortened to 1.2k when even that is too wide.
function Stats.Text(listing, width)
	local slots = listing and listing.slots or {}
	if #slots == 0 then
		return ""
	end
	local perLine = math.max(6, math.floor((width or 120) / Stats.CHAR_W))
	for _, short in ipairs({ false, true }) do
		local texts = {}
		for i, slot in ipairs(slots) do
			local p, c = slotText(i, slot, short)
			texts[i] = { p, c }
		end
		for _, k in ipairs({ 3, 2 }) do
			if math.ceil(#texts / k) <= Stats.LINES then
				local fits, lines = true, {}
				for first = 1, #texts, k do
					local plainLine, colorLine = {}, {}
					for i = first, math.min(first + k - 1, #texts) do
						table.insert(plainLine, texts[i][1])
						table.insert(colorLine, texts[i][2])
					end
					if string.len(table.concat(plainLine, Stats.GAP)) > perLine then
						fits = false
						break
					end
					table.insert(lines, table.concat(colorLine, Stats.GAP))
				end
				if fits then
					return table.concat(lines, "\n")
				end
			end
		end
	end
	-- too narrow even so: two a line, the FontString cuts what does not fit
	local lines = {}
	for first = 1, #slots, 2 do
		local line = {}
		for i = first, math.min(first + 1, #slots) do
			local _, c = slotText(i, slots[i], true)
			table.insert(line, c)
		end
		table.insert(lines, table.concat(line, " "))
	end
	return table.concat(lines, "\n")
end

-- Hover on a cell: each slot with its name and the full stat names, then the totals.
function Stats.ShowTooltip(owner, listing)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(listing.name or "Stats", 1, 1, 1)
	local slots = listing.slots or {}
	if #slots == 0 then
		GameTooltip:AddLine("No added stats on this item.", 0.7, 0.7, 0.7)
	end
	for i, slot in ipairs(slots) do
		GameTooltip:AddLine(i .. "  " .. slot.name, 1, 0.6, 0.2)
		for _, stat in ipairs(slot.stats) do
			local tag, color, name = Stats.Tag(stat)
			GameTooltip:AddDoubleLine("   |cff" .. color .. tag .. "|r  " .. name, Stats.Fmt(stat.value), 1, 1, 1, 1, 1, 1)
		end
	end
	if listing.slotsBonus then
		GameTooltip:AddLine(string.format("Without the +%d%% power modifier (durability over 101)", math.floor((listing.slotsBonus - 1) * 100 + 0.5)), 0.6, 0.6, 0.6)
	end
	local totals = Stats.Totals(listing)
	if #totals > 0 then
		GameTooltip:AddLine("Added stats in total", 1, 0.82, 0)
		for _, t in ipairs(totals) do
			GameTooltip:AddDoubleLine("|cff" .. t[3] .. t[1] .. "|r  " .. t[4], Stats.Fmt(t[2]), 1, 1, 1, 0.8, 0.8, 0.8)
		end
	end
	GameTooltip:Show()
end

-- Hover on the header: the legend.
function Stats.ShowLegend(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText("Stats", 1, 1, 1)
	GameTooltip:AddLine("The item's added stats by slot (1-6), not its own stats. Click to sort by added Str+Dex+Sta+Int+Wis.", 0, 0.75, 0.95)
	for _, s in ipairs(Stats.ORDER) do
		GameTooltip:AddDoubleLine("|cff" .. s[4] .. s[2] .. "|r", s[3], 1, 1, 1, 0.8, 0.8, 0.8)
	end
	GameTooltip:Show()
end

function Stats.Row_OnEnter(this)
	local row = this:GetParent()
	local _, listing = AAH.Browse.List_FindAuctionIndex(row and row.auctionid)
	if listing then
		Stats.ShowTooltip(this, listing)
	end
end
