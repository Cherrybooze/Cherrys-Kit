--[[ Filter Creation Help --
	Filter function will have 2 tables for parameters.
	First table is param and it is a table of what was entered into the filterbox.
		example filter: $bob/hello/13//46///en
		param = {
			[1] = "bob",
			[2] = "hello",
			[3] = "13",
			[4] = "",
			[5] = "46",
			[6] = "",
			[7] = "",
			[8] = "en",
		}
		only param[1] is needed, all others are optional for the filter
	Second Table is a table of info for that auction entry
		listing.name = string,				--name of the item
		listing.itemid = number,			--itemID number
		listing.count = number,				--stack size
		listing.rarity = number,			--rarity level (0=white, 1=green, etc.)
		listing.level = number,				--item level as listed in the level column
		listing.levelcolor = string,		--color hex code for the level, yellow if using game value, green if overriden with different value
		listing.leftTime = number,			--time left in minutes, not exact number, seems to round up by the tens slot (1234 will be 1240)
		listing.bidPrice = number,			--the estimated price to bid on the item
		listing.bidppu = number,			--bidPrice / count
		listing.buyoutPrice = number,		--the price to buyout the auction
		listing.buyppu = number,			--buyoutPrice / count
		listing.seller = string,			--name of the seller
		listing.isBuyer = boolean,			--true if you are the current highest bidder
		listing.texture = string,			--location of the item's icon texture file
		listing.auctionid = number,			--ID number used to buy the auction
		listing.tier = number				--Tier
		listing.plus = number				--Plus
		listing.dura = number				--Max Durability
		listing.worth = number				--Vendor Value
		listing.mdam = number				--Magical Damage
		listing.pdam = number				--Physical Damage
		listing.speed = number				--Attack Speed
		listing.dps = number				--DPS
		listing.sta = number				--Stamina
		listing.str = number				--Strength
		listing.dex = number				--Dexterity
		listing.wis = number				--Wisdom
		listing.int = number				--Intelligence
		listing.hp = number					--Maximum HP
		listing.mp = number					--Maximum MP
		listing.patt = number				--Physical Attack
		listing.matt = number				--Magical Attack
		listing.pdef = number				--Physical Defense
		listing.mdef = number				--Magical Defense
		listing.pcrit = number				--Physical Crit Rate
		listing.mcrit = number				--Magical Crit Rate
		listing.pacc = number				--Physical Accuracy
		listing.macc = number				--Magical Accuracy
		listing.pdod = number				--Physical Dodge Rate
		listing.parry = number				--Parry Rate
		listing.heal = number				--Healing Bonus
	Your function will look something like ...
		function FilterForBob(param, listing)
			--test for true
			return true
			--else
			return false
		end
	To register your filter use 1 of the 2 following methods in your VARIABLES_LOADED event
		AAH.Filters.Register({coms = <comma seperated string of commands>, func = <your function name without the (param, listing)>, desc = <your filter description string; optional>, })
	OR
		local filter = {
			coms = <comma seperated string of commands>,
			func = <your function name without the (param, listing)>,
			desc = <your filter description string; optional>,
		}
		AAH.Filters.Register(filter)
	Examples
		if AdvancedAuctionHouse then
			AAH.Filters.Register({coms = "$bob,$bobby,$robert", func = FilterForBob, desc = "This is a test filter"})
		end
	OR
		if AdvancedAuctionHouse then
			local filter = {
				coms = "$bob,$bobby,$robert",
				func = FilterForBob,
				desc = "Just another test",
			}
			AAH.Filters.Register(filter)
		end
]]

local Filters = {
	Registered = {},
	List = {}
}
AAH.Filters = Filters


Filters.COUNT = 6 -- filter slots (Cherry's Kit; 6.0.2 had 3)

function Filters.Empty() return true end

function Filters.Register(entry)
	if type(entry) == "table" and type(entry.func) == "function" and type(entry.coms) == "string" then
		table.insert(Filters.List, { coms = entry.coms, desc = entry.desc or "---", func = entry.func })
		if entry.coms ~= "-" then
			entry.coms = entry.coms..","
			for com in string.gmatch(entry.coms, "\$(.-),") do
				Filters.Registered[com] = entry.func
				--AAHDebug("$"..com.." initialized")
	        end
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Invalid Filter setup")
    end
end
-- 3rd Party interaction (old)
AAH.FiltersRegister = Filters.Register

function Filters.Zero(param, listing)--Search for items with a 0 Stats
	return Filters.Count(param, listing, 0)
end
Filters.Register({coms = AAHLocale.Commands.ZERO, func = Filters.Zero, desc = AAHLocale.Messages.COMMAND_ZERO_DESCRIPTION})

function Filters.One(param, listing)--Search for items with a 1 Stat
	return Filters.Count(param, listing, 1)
end
Filters.Register({coms = AAHLocale.Commands.ONE, func = Filters.One, desc = AAHLocale.Messages.COMMAND_ONE_DESCRIPTION})

function Filters.Two(param, listing)--Search for items with a 2 Stats
	return Filters.Count(param, listing, 2)
end
Filters.Register({coms = AAHLocale.Commands.TWO, func = Filters.Two, desc = AAHLocale.Messages.COMMAND_TWO_DESCRIPTION})

function Filters.Three(param, listing)--Search for items with a 3 Stats
	return Filters.Count(param, listing, 3)
end
Filters.Register({coms = AAHLocale.Commands.THREE, func = Filters.Three, desc = AAHLocale.Messages.COMMAND_THREE_DESCRIPTION})

function Filters.Four(param, listing)--Search for items with a 4 Stats
	return Filters.Count(param, listing, 4)
end
Filters.Register({coms = AAHLocale.Commands.FOUR, func = Filters.Four, desc = AAHLocale.Messages.COMMAND_FOUR_DESCRIPTION})

function Filters.Five(param, listing)--Search for items with a 5 Stats
	return Filters.Count(param, listing, 5)
end
Filters.Register({coms = AAHLocale.Commands.FIVE, func = Filters.Five, desc = AAHLocale.Messages.COMMAND_FIVE_DESCRIPTION})

function Filters.Six(param, listing)--Search for items with a 6 Stats
	return Filters.Count(param, listing, 6)
end
Filters.Register({coms = AAHLocale.Commands.SIX, func = Filters.Six, desc = AAHLocale.Messages.COMMAND_SIX_DESCRIPTION})

Filters.Register({coms = "-", func = Filters.Empty})

function Filters.Green(param, listing, color)
	if color then
		return "green"
	else
		return Filters.Color(param, listing, "green")
	end
end
Filters.Register({coms = AAHLocale.Commands.GREEN, func = Filters.Green, desc = AAHLocale.Messages.COMMAND_GREEN_DESCRIPTION})

function Filters.Yellow(param, listing, color)
	if color then
		return "yellow"
	else
		return Filters.Color(param, listing, "yellow")
	end
end
Filters.Register({coms = AAHLocale.Commands.YELLOW, func = Filters.Yellow, desc = AAHLocale.Messages.COMMAND_YELLOW_DESCRIPTION})

function Filters.Orange(param, listing, color)
	if color then
		return "orange"
	else
		return Filters.Color(param, listing, "orange")
	end
end
Filters.Register({coms = AAHLocale.Commands.ORANGE, func = Filters.Orange, desc = AAHLocale.Messages.COMMAND_ORANGE_DESCRIPTION})

Filters.Register({coms = "-", func = Filters.Empty})

function Filters.Color(param, listing, color)--Search for green, yellow, or orange stats
	local left, right, found
	for i = 3, 40 do
		if getglobal("AAH_TooltipTextLeft"..i):IsVisible() and getglobal("AAH_TooltipTextRight"..i):IsVisible() then
			left = getglobal("AAH_TooltipTextLeft"..i):GetText()
			right = getglobal("AAH_TooltipTextRight"..i):GetText()
			if left and left ~= "" and right and right ~= "" then
				found = AAH.Tools.FindColorType(getglobal("AAH_TooltipTextLeft"..i):GetColor())
				if found == color then
					return true
				elseif AAH.Tools.FindColorType(r, g, b) == "rune" then
					return false
				end
			end
		end
	end
	return false
end

function Filters.Count(param, listing, count)-- Search for # of colored stats
	local statCount = 0
	local colorinverse = false
	local color = nil
	if param[2] then
		if string.sub(param[2],1,1) == "!" then
			param[2] = string.sub(param[2],2)
			colorinverse = true
		end
		if string.sub(param[2],1,1) == "$" then
			param[2] = string.sub(param[2],2)
		end
		if Filters.Registered[param[2]] then
			color = Filters.Registered[param[2]](param, listing, true)
			if color ~= "green" and color ~= "yellow" and color ~= "orange" then
				color = nil
			end
		end
	end
	local left, right, found
	for i = 3, 40 do
		if getglobal("AAH_TooltipTextLeft"..i):IsVisible() and getglobal("AAH_TooltipTextRight"..i):IsVisible() then
			left = getglobal("AAH_TooltipTextLeft"..i):GetText()
			right = getglobal("AAH_TooltipTextRight"..i):GetText()
			if left and left ~= "" and right and right ~= "" and not string.match(left, TEXT("SYS_TOOLTIP_RUNE_LEVEL")) then
				found = AAH.Tools.FindColorType(getglobal("AAH_TooltipTextLeft"..i):GetColor())
				if found == "rune" then
					break
				elseif found ~= "green" and found ~= "yellow" and found ~= "orange" then
					--ignore
				elseif color then
					if colorinverse then
						if found ~= color then
							statCount = statCount + 1
						elseif found == color then
							statCount = -1
							break
						end
					else
						if found == color then
							statCount = statCount + 1
						elseif found ~= color then
							statCount = -1
							break
						end
					end
				else
					statCount = statCount + 1
				end
			end
		end
	end
	if count == statCount then
		return true
	end
	return false
end

function Filters.Tier(param, listing)--Search for items with a minimum tier
	local value = 1
	if param[2] then
		value = tonumber(string.match(param[2], "%d+")) or 1
	end
	if listing.tier >= value then
		return true
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.TIER, func = Filters.Tier, desc = AAHLocale.Messages.COMMAND_TIER_DESCRIPTION})

function Filters.Plus(param, listing)--Search for items with a minimum plus
	local value = 1
	if param[2] then
		value = tonumber(string.match(param[2], "%d+")) or 1
	end
	if listing.plus >= value then
		return true
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.PLUS, func = Filters.Plus, desc = AAHLocale.Messages.COMMAND_PLUS_DESCRIPTION})

function Filters.Dura(param, listing)--Search for items with durability >= 101 (high dura)
	local value = 101
	if param[2] then
		value = tonumber(string.match(param[2], "%d+")) or 101
	end
	if listing.dura >= value then
		return true
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.DURA, func = Filters.Dura, desc = AAHLocale.Messages.COMMAND_DURA_DESCRIPTION})

Filters.Register({coms = "-", func = Filters.Empty})

function Filters.EggLevel(param, listing)--Search for Pet Eggs with a minimum Level
	if AAH.Data.PetEggs[listing.itemid] then
		local value = 1
		if param[2] then
			value = tonumber(string.match(param[2], "%d+")) or 1
		end
		if listing.level >= value then
			return true
		end
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.EGGLEVEL, func = Filters.EggLevel, desc = AAHLocale.Messages.COMMAND_EGGLEVEL_DESCRIPTION})

function Filters.EggAptitude(param, listing)--Search for Pet Eggs with a minimum Aptitude
	local left
	local value = 1
	if param[2] then
		value = tonumber(string.match(param[2], "%d+")) or 1
	end
	if AAH.Data.PetEggs[listing.itemid] then
		for i = 3, 40 do
			left = getglobal("AAH_TooltipTextLeft"..i):GetText()
			if left ~= nil and getglobal("AAH_TooltipTextLeft"..i):IsVisible() then
				if string.find(left, TEXT("PET_TOOLTIP_TALENT").."%d+") then
					if tonumber(string.match(left, "%d+")) >= value then
						return true
					end
				end
			end
		end
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.EGGAPTITUDE, func = Filters.EggAptitude, desc = AAHLocale.Messages.COMMAND_EGGAPTITUDE_DESCRIPTION})

Filters.Register({coms = "-", func = Filters.Empty})

function Filters.Vendor(param, listing)--Search for items that can be vendored for a profit
	if listing.isBuyer or listing.worth == 0 then
		return false
	end
	local minprofit = 1
	if param[2] then
		minprofit = tonumber(string.match(param[2], "%d+")) or 1
	end
	local maxtime = 4320
	if param[3] then
		maxtime = tonumber(string.match(param[3], "%d+")) or 4320
	end
	if listing.worth > listing.buyppu and listing.buyppu > 0 then
		return true
	elseif listing.worth - listing.bidppu >= minprofit and listing.leftTime <= maxtime then
		return true
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.VENDOR, func = Filters.Vendor, desc = AAHLocale.Messages.COMMAND_VENDOR_DESCRIPTION})

function Filters.Bargain(param, listing)--Search for items that can be reauctioned for a profit
    if listing.isBuyer then return false end

    local avgcost = AAH.History.GetAveragePrice(listing.itemid)
	if not avgcost then return false end

	local percent = .7
	if param[2] then
		percent = 1 - (tonumber(string.match(param[2], "%d+")) / 100) or .7
	end
	local maxtime = 4320
	if param[3] then
		maxtime = tonumber(string.match(param[3], "%d+")) or 4320
	end
	if avgcost * percent >= listing.bidppu and maxtime >= listing.leftTime then
		return true
	elseif avgcost * percent >= listing.buyppu and listing.buyppu > 0 then
		return true
	end
	return false
end
Filters.Register({coms = AAHLocale.Commands.BARGAIN, func = Filters.Bargain, desc = AAHLocale.Messages.COMMAND_BARGAIN_DESCRIPTION})

Filters.Register({coms = "-", func = Filters.Empty})

-- Cherry's Kit: Prepare reads the filter fields once per filtering step (6.0.2 read them, and
-- loaded the item tooltip again, for every item). The tooltip is only loaded when a filter
-- reads it: keywords, the colour and count filters, egg aptitude and filters from other addons.
-- Tier, plus, dura, egg level, vendor, bargain and the stat filters use values read before.
local NO_TOOLTIP = {}

local function needsTooltip(phrase)
	if phrase == "" or phrase == "!" then
		return false
	end
	if string.sub(phrase, 1, 1) == "!" then
		phrase = string.sub(phrase, 2)
	end
	if string.sub(phrase, 1, 1) ~= "$" then
		return true -- a keyword searches the tooltip text
	end
	local com = string.lower(string.match(phrase, "^%$([^/]*)") or "")
	local func = Filters.Registered[com]
	return not (func and NO_TOOLTIP[func])
end

local function matches(phrase, listing)
	if phrase == "" then
		return true
	elseif string.sub(phrase, 1, 1) == "!" then
		if string.len(phrase) > 1 then
			return not Filters.SearchInTooltip(string.sub(phrase, 2), listing)
		end
		return true
	end
	return Filters.SearchInTooltip(phrase, listing)
end

function Filters.Prepare()
	if not NO_TOOLTIP[Filters.Tier] then
		for _, f in ipairs({ Filters.Tier, Filters.Plus, Filters.Dura, Filters.EggLevel, Filters.Vendor,
			Filters.Bargain, Filters.StatMin, Filters.StatMax }) do
			NO_TOOLTIP[f] = true
		end
	end
	local st = {
		phrase = {},
		ors = {},
		minprice = AAH_BrowseFilterMinPriceEditBox:GetNumber(),
		maxprice = AAH_BrowseFilterMaxPriceEditBox:GetNumber(),
		ppu = AAH_BrowseFilterPPUButton:IsChecked(),
		bid = AAH_BrowseFilterBidButton:IsChecked(),
		rarityMin = AAH.Browse.RarityMin,
		rarityMax = AAH.Browse.RarityMax,
	}
	for n = 1, Filters.COUNT do
		st.phrase[n] = Filters.GetPhrase(n)
		st.ors[n] = n > 1 and Filters.IsOr(n)
		st.tooltip = st.tooltip or needsTooltip(st.phrase[n])
	end
	Filters.state = st
	return st
end

-- End of a filtering step: forget the fields and which item AAH_Tooltip holds.
function Filters.Done()
	Filters.state = nil
	Filters.TooltipFor = nil
end

function Filters.CheckFilter(listing)
	local st = Filters.state
	if not st then -- called outside a filtering step: read the fields just for this item
		st = Filters.Prepare()
		Filters.state = nil
	end
	-- Cherry's Kit: rarity range (the Rarity "min" and "max" dropdowns)
	local rank = AAH.Browse.RarityRank(listing.rarity)
	if (st.rarityMin and rank < st.rarityMin) or (st.rarityMax and rank > st.rarityMax) then
		return false
	end
	if st.tooltip and Filters.TooltipFor ~= listing.link then
		AAH_Tooltip:SetHyperLink(listing.link)
		AAH_Tooltip:Hide()
		GameTooltip1:Hide()
		GameTooltip2:Hide()
		Filters.TooltipFor = Filters.state and listing.link or nil
	end
	Filters.Checks = (Filters.Checks or 0) + 1
	-- left to right, as 6.0.2 did with three: "or" ticked on filter n means (filters before) or n,
	-- otherwise (filters before) and n. Empty filters are skipped.
	local filtertrue
	for n = 1, Filters.COUNT do
		if st.phrase[n] ~= "" then
			local ok = matches(st.phrase[n], listing)
			if filtertrue == nil then
				filtertrue = ok
			elseif st.ors[n] then
				filtertrue = filtertrue or ok
			else
				filtertrue = filtertrue and ok
			end
		end
	end
	if filtertrue == nil then
		filtertrue = true
	end
	if not filtertrue then
		return false
	end
	local filterminprice, filtermaxprice = st.minprice, st.maxprice
	local filterppu, filterbid = st.ppu, st.bid
	if filterminprice and filterminprice > 0 then
		if filterppu and filterbid and listing.bidppu < filterminprice then
			return false
		elseif filterppu and not filterbid and listing.buyppu < filterminprice then
			return false
		elseif not filterppu and filterbid and listing.bidPrice < filterminprice then
			return false
		elseif not filterppu and not filterbid and listing.buyoutPrice < filterminprice then
			return false
		end
	end
	if filtermaxprice and filtermaxprice > 0 then
		if filterppu and filterbid and listing.bidppu > filtermaxprice and listing.bidppu > 0 then
			return false
		elseif filterppu and not filterbid and listing.buyppu > filtermaxprice and listing.buyppu > 0 then
			return false
		elseif not filterppu and filterbid and listing.bidPrice > filtermaxprice and listing.bidPrice > 0 then
			return false
		elseif not filterppu and not filterbid and listing.buyoutPrice > filtermaxprice and listing.buyoutPrice > 0 then
			return false
		end
	end
	return true
end


function Filters.SearchInTooltip(searchString, listing)
	local lowerString = AAH.Tools.StringLower(string.gsub(searchString, "-", "%%-"))
	local text
	if string.sub(lowerString, 1, 1) == "$" then
		lowerString = lowerString.."/"
		local strlen = string.len(lowerString)
		local param = {}
		local loc1, loc2 = 2, 0
		repeat
			loc2 = string.find(lowerString, "/", loc1)
			table.insert(param, string.sub(lowerString, loc1, loc2 - 1))
			loc1 = loc2 + 1
		until loc1 > strlen
		if Filters.Registered[param[1]] then
			return Filters.Registered[param[1]](param, listing)
		end
	else
		for i = 1, 40 do
			--Search for text in left sides
			text = getglobal("AAH_TooltipTextLeft"..i):GetText()
			if text ~= nil and getglobal("AAH_TooltipTextLeft"..i):IsVisible() then
				if string.find(AAH.Tools.StringLower(text), lowerString) then
					return true
				end
			end
			--Search for text in right sides
			text = getglobal("AAH_TooltipTextRight"..i):GetText()
			if text ~= nil and getglobal("AAH_TooltipTextRight"..i):IsVisible() then
				if string.find(AAH.Tools.StringLower(text), lowerString) then
					return true
				end
			end
		end
	end
	return false
end

AAH.FiltersSearchInTooltip=Filters.SearchInTooltip -- 3rd party interaction (yacit)

---------------------------------------------------------------------------
-- Cherry's Kit: stat filters ($str/30 = Strength at least 30, $maxstr/425 = Strength at most 425,
-- and so on). They read the item's added stats without the durability bonus (AAH_Stats.lua), not
-- the class conversions. "At most" only keeps items that have the stat.
---------------------------------------------------------------------------

Filters.StatComs = {} -- com -> listing key, in AAH.Stats.ORDER order
Filters.StatKinds = {}

function Filters.StatMin(param, listing)
	local key = Filters.StatComs[param[1]]
	local raw = listing.raw or listing
	local value = tonumber(param[2] and string.match(param[2], "[%d%.]+")) or 1
	return key ~= nil and (tonumber(raw[key]) or 0) >= value
end

Filters.StatMaxKinds = {}

function Filters.StatMax(param, listing)
	local key = Filters.StatComs[param[1]]
	local raw = listing.raw or listing
	local value = tonumber(param[2] and string.match(param[2], "[%d%.]+")) or 0
	local have = key and tonumber(raw[key]) or 0
	return key ~= nil and have > 0 and have <= value
end

for _, st in ipairs(AAH.Stats.ORDER) do
	local com = string.lower(st[2])
	if not Filters.Registered[com] then
		Filters.Registered[com] = Filters.StatMin
		Filters.StatComs[com] = st[1]
		table.insert(Filters.StatKinds, { com = com, label = st[2] .. " at least", name = st[3],
			hint = st[3] .. " at least this much, for example 30", value = true })
	end
	local maxCom = "max" .. com
	if not Filters.Registered[maxCom] then
		Filters.Registered[maxCom] = Filters.StatMax
		Filters.StatComs[maxCom] = st[1]
		table.insert(Filters.StatMaxKinds, { com = maxCom, label = st[2] .. " at most", name = st[3],
			hint = st[3] .. " at most this much (items with some), for example 425", value = true })
	end
end

---------------------------------------------------------------------------
-- Cherry's Kit: filter dropdowns. Each of the three filters is a dropdown (what to filter by)
-- and a value box. "Keyword" works like the old text box: tooltip text, ! in front to invert,
-- or a typed $command. The other choices build the same $command/value text the old boxes took.
---------------------------------------------------------------------------

Filters.Kind = {}   -- [1..3] = the chosen kind (nil = Keyword)
Filters.MENU_MAX = 30 -- RoM dropdowns hold at most 32 entries; the rest go under "More"

Filters.KEYWORD = { label = "Keyword", hint = "Text in the item tooltip. ! in front = must NOT contain it. A $command works too.", value = true }

-- Short labels for the built-in filters, by function (their commands differ per language).
Filters.Labels = {
	[Filters.Zero]        = { label = "No stats" },
	[Filters.One]         = { label = "1 stat", hint = "Optional: green, yellow or orange (only stats of that colour), !green = none green", value = true },
	[Filters.Two]         = { label = "2 stats", hint = "Optional: green, yellow or orange", value = true },
	[Filters.Three]       = { label = "3 stats", hint = "Optional: green, yellow or orange", value = true },
	[Filters.Four]        = { label = "4 stats", hint = "Optional: green, yellow or orange", value = true },
	[Filters.Five]        = { label = "5 stats", hint = "Optional: green, yellow or orange", value = true },
	[Filters.Six]         = { label = "6 stats", hint = "Optional: green, yellow or orange", value = true },
	[Filters.Green]       = { label = "Green stats", color = { 0.3, 1, 0.3 } },
	[Filters.Yellow]      = { label = "Yellow stats", color = { 1, 1, 0.2 } },
	[Filters.Orange]      = { label = "Orange stats", color = { 1, 0.55, 0.1 } },
	[Filters.Tier]        = { label = "Tier at least", hint = "Lowest tier, for example 6", value = true },
	[Filters.Plus]        = { label = "Plus at least", hint = "Lowest plus, for example 6", value = true },
	[Filters.Dura]        = { label = "Durability at least", hint = "Lowest max durability (empty = 101)", value = true },
	[Filters.EggLevel]    = { label = "Pet egg level", hint = "Lowest pet egg level, for example 30", value = true },
	[Filters.EggAptitude] = { label = "Pet egg aptitude", hint = "Lowest pet egg aptitude, for example 80", value = true },
	[Filters.Vendor]      = { label = "Vendor for profit", hint = "Optional: min profit/max minutes left, for example 100/600", value = true },
	[Filters.Bargain]     = { label = "Below average price", hint = "Optional: % below average/max minutes left, for example 30/600", value = true },
}

-- The kinds from Filters.List (built-ins and filters other addons registered), built on use.
function Filters.Kinds()
	if Filters.kindsFor == #Filters.List and Filters.kinds then
		return Filters.kinds
	end
	local kinds = {}
	for _, entry in ipairs(Filters.List) do
		local com = entry.coms ~= "-" and string.match(entry.coms, "%$([^,]+)")
		if com then
			local known = Filters.Labels[entry.func]
			local kind = { com = string.lower(com), func = entry.func }
			if known then
				kind.label, kind.hint, kind.value, kind.color = known.label, known.hint, known.value, known.color
			else
				kind.label = "$" .. com
				kind.hint = entry.desc
				kind.value = true
			end
			kind.desc = entry.desc
			table.insert(kinds, kind)
		end
	end
	Filters.kinds, Filters.kindsFor = kinds, #Filters.List
	return kinds
end

-- Finds the kind for a typed command ($tier, $durability, $str ...).
function Filters.KindForCom(com)
	com = string.lower(com or "")
	for _, list in ipairs({ Filters.StatKinds, Filters.StatMaxKinds }) do
		for _, kind in ipairs(list) do
			if kind.com == com then
				return kind
			end
		end
	end
	local func = Filters.Registered[com]
	for _, kind in ipairs(Filters.Kinds()) do
		if kind.com == com or (func and kind.func == func and func ~= Filters.StatMin and func ~= Filters.StatMax) then
			return kind
		end
	end
end

local function dropDown(n)
	return _G["AAH_BrowseFilter" .. n .. "DropDown"]
end
local function valueBox(n)
	return _G["AAH_BrowseFilter" .. n .. "EditBox"]
end

-- The text CheckFilter tests for filter n: a keyword, or "$command/value".
function Filters.GetPhrase(n)
	local text = valueBox(n):GetText() or ""
	local kind = Filters.Kind[n]
	if not kind or kind == Filters.KEYWORD then
		return text
	end
	if kind.value and text ~= "" then
		return "$" .. kind.com .. "/" .. text
	end
	return "$" .. kind.com
end

-- Shows filter n as `kind` with value text (used by the menu, saved searches and Clear).
function Filters.SetKind(n, kind, text)
	kind = kind or Filters.KEYWORD
	Filters.Kind[n] = kind
	AAH.Tools.SetDropDown(dropDown(n), nil, kind.label, kind.color or ((kind == Filters.KEYWORD) and { 1, 1, 1 }) or { 1, 0.82, 0 })
	local box = valueBox(n)
	box:SetText(text or "")
	if kind.value then
		box:Show()
	else
		box:Hide()
	end
	Filters.UpdateClear(n)
	AAH.Browse.FilterChange()
end

-- The red X next to a filter shows while that filter does something.
function Filters.UpdateClear(n)
	local x = _G["AAH_BrowseFilter" .. n .. "Clear"]
	if not x then
		return
	end
	local kind = Filters.Kind[n] or Filters.KEYWORD
	if kind ~= Filters.KEYWORD or (valueBox(n):GetText() or "") ~= "" then
		x:Show()
	else
		x:Hide()
	end
end

function Filters.Clear(n)
	CloseDropDownMenus()
	valueBox(n):ClearFocus()
	Filters.SetKind(n, Filters.KEYWORD, "")
end

-- The reverse of GetPhrase, for saved searches made with the old text boxes too.
function Filters.SetPhrase(n, phrase)
	phrase = phrase or ""
	local com, rest = string.match(phrase, "^%$([^/]+)/?(.*)$")
	local kind = com and Filters.KindForCom(com)
	if kind then
		Filters.SetKind(n, kind, rest)
	else
		Filters.SetKind(n, Filters.KEYWORD, phrase)
	end
end

function Filters.ResetKinds()
	for n = 1, Filters.COUNT do
		Filters.SetKind(n, Filters.KEYWORD, "")
		if n > 1 then
			_G["AAH_BrowseFilter" .. n .. "OrButton"]:SetChecked(false)
		end
	end
end

function Filters.IsOr(n)
	local b = _G["AAH_BrowseFilter" .. n .. "OrButton"]
	return b and b:IsChecked() and true or false
end

function Filters.Menu(n)
	local level = UIDROPDOWNMENU_MENU_LEVEL or 1
	local info
	local function add(kind, lvl)
		info = {}
		info.text = kind.label
		info.notCheckable = true
		if kind.color then
			info.textR, info.textG, info.textB = kind.color[1], kind.color[2], kind.color[3]
		end
		info.func = function()
			Filters.SetKind(n, kind, "")
			CloseDropDownMenus()
			if kind.value then
				valueBox(n):SetFocus()
			end
		end
		UIDropDownMenu_AddButton(info, lvl)
	end
	local kinds = Filters.Kinds()
	if level == 1 then
		add(Filters.KEYWORD, 1)
		info = { text = "Stat at least", value = "STATS", hasArrow = true, notCheckable = true }
		UIDropDownMenu_AddButton(info, 1)
		info = { text = "Stat at most", value = "STATSMAX", hasArrow = true, notCheckable = true }
		UIDropDownMenu_AddButton(info, 1)
		for i, kind in ipairs(kinds) do
			if i > Filters.MENU_MAX - 4 then
				info = { text = "More", value = "MORE", hasArrow = true, notCheckable = true }
				UIDropDownMenu_AddButton(info, 1)
				break
			end
			add(kind, 1)
		end
	elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "STATS" then
		for _, kind in ipairs(Filters.StatKinds) do
			add(kind, 2)
		end
	elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "STATSMAX" then
		for _, kind in ipairs(Filters.StatMaxKinds) do
			add(kind, 2)
		end
	elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "MORE" then
		for i = Filters.MENU_MAX - 3, math.min(#kinds, Filters.MENU_MAX * 2) do
			add(kinds[i], 2)
		end
	end
end

function Filters.InitDropDowns()
	for n = 2, Filters.COUNT do
		_G["AAH_BrowseFilter" .. n .. "OrButtonLabel"]:SetText(AAHLocale.Messages.BROWSE_OR)
	end
	for n = 1, Filters.COUNT do
		AAH.Layout.Try(_G["AAH_BrowseFilter" .. n .. "ClearIcon"], "SetFile", AAH.Manifest.Root .. "/Textures/clear_x")
		local index = n
		UIDropDownMenu_Initialize(dropDown(n), function() Filters.Menu(index) end)
		UIDropDownMenu_SetWidth(dropDown(n), 60)
		Filters.SetKind(n, Filters.KEYWORD, valueBox(n):GetText())
	end
end

-- Six filters in two columns of three (1-3, 4-6), left of the price boxes. They share the panel's
-- width: wider window, longer dropdowns and value boxes (extra = extra window width for the panel).
Filters.RIGHT_BLOCK = 126 -- PPU / Bid / Min / Max on the right of the panel
function Filters.Layout(extra)
	local width = 295 + math.max(0, math.min(extra or 0, 260))
	local avail = math.floor((width - Filters.RIGHT_BLOCK) / 2) - 70 -- dropdown + value box of one column
	local dd = math.max(55, math.min(120, math.floor(avail * 0.55)))
	local boxW = math.max(26, avail - dd)
	for n = 1, Filters.COUNT do
		UIDropDownMenu_SetWidth(dropDown(n), dd)
		valueBox(n):SetWidth(boxW)
	end
	AAH_BrowseFilter:SetWidth(width)
	local labels = 49 + dd + 21 -- "or" box and dropdown left of a value box
	AAH_BrowseFilter1EditBox:ClearAllAnchors()
	AAH_BrowseFilter1EditBox:SetAnchor("TOPLEFT", "TOPLEFT", "AAH_BrowseFilter", labels, 6)
	AAH_BrowseFilter4EditBox:ClearAllAnchors()
	AAH_BrowseFilter4EditBox:SetAnchor("TOPLEFT", "TOPLEFT", "AAH_BrowseFilter", 2 * labels + boxW - 4, 6)
	Filters.ColumnEnd = 2 * labels + 2 * boxW - 4
end

function Filters.Value_OnTextChanged(n)
	Filters.UpdateClear(n)
	AAH.Browse.FilterChange()
end

function Filters.Value_OnEnter(this, n)
	local kind = Filters.Kind[n] or Filters.KEYWORD
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, -50)
	GameTooltip:SetText(kind.label, 1, 1, 1)
	if kind.hint then
		GameTooltip:AddLine(kind.hint, 0, 0.75, 0.95)
	end
	if kind == Filters.KEYWORD then
		GameTooltip:AddLine(AAHLocale.Messages.BROWSE_FILTER_TOOLTIP_TEXT1, 0, 0.75, 0.95)
	end
	GameTooltip:Show()
end

function Filters.DropDown_OnEnter(this, n)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, -50)
	GameTooltip:SetText(AAHLocale.Messages.BROWSE_FILTER_TOOLTIP_HEADER .. n, 1, 1, 1)
	GameTooltip:AddLine("Pick what to filter by, then type the value in the box next to it.", 0, 0.75, 0.95)
	if n > 1 then
		GameTooltip:AddLine(AAHLocale.Messages.BROWSE_FILTER_OR_TOOLTIP_TEXT, 0.7, 0.7, 0.7)
	end
	GameTooltip:Show()
end
---------------------------------------------------------------------------
-- Cherry's Kit: keep AAH's dropdown menus open (same approach as Cherry's KittyCombo 1.5).
-- The game hides an open dropdown a moment after the mouse leaves it: leaving starts a countdown
-- (UIDropDownMenu_StartCounting, UIDROPDOWNMENU_SHOW_TIME). While one of AAH's menus is open the
-- countdown is stretched to KEEP_OPEN_SECONDS, so the menu stays until you pick an entry, click the
-- auction window (AAH_AuctionFrame OnMouseDown), close the window, or that long passes.
-- Other addons' menus are unchanged.
---------------------------------------------------------------------------

Filters.KEEP_OPEN_SECONDS = 60

function Filters.IsOwnMenuOpen()
	local menu = UIDROPDOWNMENU_OPEN_MENU
	if type(menu) == "table" and menu.GetName then
		menu = menu:GetName()
	end
	return type(menu) == "string" and string.find(menu, "^AAH_") ~= nil
end

AAH.Hook("Filters.StartCounting", _G, "UIDropDownMenu_StartCounting", function(orig, frame, ...)
	if not Filters.IsOwnMenuOpen() then
		return orig(frame, ...)
	end
	local saved = UIDROPDOWNMENU_SHOW_TIME
	UIDROPDOWNMENU_SHOW_TIME = Filters.KEEP_OPEN_SECONDS
	local ok, err = pcall(orig, frame, ...)
	UIDROPDOWNMENU_SHOW_TIME = saved
	-- also stretch a countdown already stored on the list (or its parent list)
	local list = frame
	while type(list) == "table" do
		if type(list.showTimer) == "number" and list.showTimer < Filters.KEEP_OPEN_SECONDS then
			list.showTimer = Filters.KEEP_OPEN_SECONDS
		end
		list = rawget(list, "parent")
	end
	if not ok then
		error(err)
	end
end)
