local Browse = {
	DisplayedItems = 7,
	MAX_ROWS = 16, -- list rows in the XML (Cherry's Kit: more rows for a taller window)
	StatsWidth = 0,
	SortMode = 0,
	CustomSortItem1 = "level",
	CustomSortItem2 = "tier",
	CurrentCustomHeaderID = 0,
	Cache = {},
	Results = {},
	LastSearch = {},
	LastCached = 0,
	MaxPageItems = 50,
	CurrentCachePage = 1,
	CurrentFilterPage = 0,
	CurrentFilterItem = 0,
	MaxPages = 0,
	BuyoutEvent = false,
	FilteringActive = false,
    selected_auctionid=nil,
	SelectedCategory = {},
    CategoryButtonNums = 0,
    CategoryScrollValue = 0,
	RarityInfo = {
		TEXT("C_ALL"),
		TEXT("ITEM_QUALITY1_DESC"),
		TEXT("ITEM_QUALITY2_DESC"),
		TEXT("ITEM_QUALITY3_DESC"),
		TEXT("ITEM_QUALITY4_DESC"),
		TEXT("ITEM_QUALITY5_DESC"),
		TEXT("UNUSUAL_LV6"),
		TEXT("UNUSUAL_LV7"),
		TEXT("ACCOUNT_SHOP"),
		TEXT("UNUSUAL_LV9"),
		TEXT("UNUSUAL_LV10"),
	},
	RuneInfo = {
		"0+",
		"1+",
		"2+",
		"3+",
		"4+",
	},
}
AAH.Browse = Browse

local FILTER_DELAY = 2
local ABORT_DELAY = 6
local SEARCH_DELAY_START = 6
local SEARCH_DELAY_RETRY = 1
local SEARCH_DELAY_NEXTPAGE = 6 -- 6.0.2 waited this long before every next page

-- Cherry's Kit: page pacing. The server answers "Currently busy. Please try again later." when it
-- is asked too often; AuctionBrowseNextPage then returns false. Kit 0.11.7 started at 2.5 s and
-- retried every second, which spammed that message. Now:
--  * auto starts at the 6.0.2 pace (6 s) and only creeps down to 4 s while no page is refused;
--  * a refusal (or a "busy" message) raises the pace by 1.5 s, up to 10, and the next try waits the
--    whole pause, not one second; the lowest pace for the session goes up with it;
--  * the next page is never asked for while a price history request is still out, and price
--    history is not asked for while a page is on its way (one request at a time).
-- A fixed pause in the settings (or /aah pagedelay) replaces auto.
local PAGE_DELAY_START = 6
local PAGE_DELAY_MIN = 4
local PAGE_DELAY_MAX = 10
local HISTORY_TIMEOUT = 3 -- a price history answer that does not come stops blocking pages after this
Browse.Pace = { delay = PAGE_DELAY_START, floor = PAGE_DELAY_MIN, pages = 0, refusals = 0, busy = 0, time = 0, sorts = 0, clock = 0 }

-- How long to wait before asking for the next page.
function Browse.PageDelay()
	local fixed = AAH_SavedSettings and tonumber(AAH_SavedSettings.PageDelay)
	if fixed and fixed > 0 then -- 0 = auto
		return fixed
	end
	return Browse.Pace.delay
end

-- The server said no (AuctionBrowseNextPage returned false, or it printed "busy").
function Browse.PaceBackOff()
	local pace = Browse.Pace
	if pace.lastBackOff and pace.clock - pace.lastBackOff < 1 then
		return -- the refusal and its message are one event
	end
	pace.lastBackOff = pace.clock
	pace.refusedThisPage = true
	pace.floor = math.min(PAGE_DELAY_MAX, math.max(pace.floor, pace.delay + 1))
	pace.delay = math.min(PAGE_DELAY_MAX, pace.delay + 1.5)
end

local function paceRefused()
	Browse.Pace.refusals = Browse.Pace.refusals + 1
	Browse.PaceBackOff()
end

local function pacePageDone()
	local pace = Browse.Pace
	pace.pages = pace.pages + 1
	if not pace.refusedThisPage then
		pace.delay = math.max(pace.floor, pace.delay - 0.25)
	end
	pace.refusedThisPage = nil
end

-- A price history request is out and not answered yet (AAH_History.lua).
function Browse.HistoryRequestOut()
	local h = AAH.History
	return h.PriceHistoryProcessed == false and h.RequestedAt ~= nil and (Browse.Pace.clock - h.RequestedAt) < HISTORY_TIMEOUT
end

-- "Currently busy" from the game: count it, back off, and show it once per 5 seconds at most.
local BUSY_TEXT = "busy"
local function isBusy(text)
	return type(text) == "string" and string.find(string.lower(text), BUSY_TEXT, 1, true) ~= nil
end
function Browse.OnGameMessage(text)
	if not isBusy(text) then
		return true
	end
	local pace = Browse.Pace
	pace.busy = pace.busy + 1
	Browse.PaceBackOff()
	local scan=Browse.Scan
	if scan and scan.active and scan.stage=="header" then
		scan.retryAt=pace.clock+Browse.PageDelay();scan.waitReason="Server busy; retrying"
		Browse.InfoLabelUpdate()
	end
	if pace.lastBusyShown and pace.clock - pace.lastBusyShown < 5 then
		return false -- swallow the repeat
	end
	pace.lastBusyShown = pace.clock
	return true
end
for _, fname in ipairs({ "SendWarningMsg", "SendSystemMsg" }) do
	AAH.Hook("Browse." .. fname, _G, fname, function(orig, text, ...)
		if AAH.Browse.OnGameMessage(text) then
			return orig(text, ...)
		end
	end)
end

-- While a list is filtered and sorted, re-sort and redraw at most this often (6.0.2 sorted the
-- whole list on every frame that added an item).
local SORT_INTERVAL = 0.5
local SortClock = 0

local SearchRequested
local SearchBroadRequested
local FilterChanged
local AwaitingData
local CachingActive

local SearchDelay = ABORT_DELAY
local FilterDelay = FILTER_DELAY
local TimeRemaining = SEARCH_DELAY_START

-- One serial scan, using the normal native search/paging API. A capped query
-- is narrowed by native categories, then disjoint level ranges. No rarity,
-- price or stat partitions: those predicates are not reliable server bounds.
local SCAN_CAP = 1000
local SCAN_TIMEOUT = 30
local function copyQuery(query)
	local copy={}; for k,v in pairs(query) do if k~="readyAt" then copy[k]=v end end; return copy
end
local function queryKey(q)
	return table.concat({q.cat1 or 0,q.cat2 or 0,q.cat3 or 0,q.minlvl or 0,q.maxlvl or 0},":")
end
function Browse.SplitSearch(query)
	local depth=query.cat3 and 3 or query.cat2 and 2 or query.cat1 and 1 or 0
	if depth<3 and GetAuctionBrowseFilterList then
		local names
		if depth==0 then names={GetAuctionBrowseFilterList()}
		elseif depth==1 then names={GetAuctionBrowseFilterList(query.cat1)}
		else names={GetAuctionBrowseFilterList(query.cat1,query.cat2)} end
		local children={}
		for i,name in ipairs(names) do
			if type(name)=="string" and name~="" then
				local child=copyQuery(query); child["cat"..(depth+1)]=i
				children[#children+1]=child
			end
		end
		if #children>0 then return children end
	end
	local low=math.max(0,tonumber(query.minlvl) or 0)
	local high=math.max(0,tonumber(query.maxlvl) or 0)
	-- Zero means no bound in the native API. Keep the lower zero range intact
	-- when it can no longer be split without turning 0..0 back into "all".
	if high>0 and (high<=low or low==0 and high<=1) then return nil end
	local middle=high>0 and math.floor((low+high)/2) or math.max(50,low+49)
	local left,right=copyQuery(query),copyQuery(query)
	left.minlvl,left.maxlvl=low,middle
	right.minlvl,right.maxlvl=middle+1,high
	return {left,right}
end
local function searchCaption(active)
	AAH_BrowseSearchButton:SetText(active and "Stop" or TEXT("C_SEARCH"))
	AAH_BrowseSearchButton:Enable()
	if AAH_BrowseBroadSearchButton then
		if active then AAH_BrowseBroadSearchButton:Disable() else AAH_BrowseBroadSearchButton:Enable() end
	end
end
local function finishScan(reason)
	local scan=Browse.Scan; if not scan then return end
	scan.active,scan.stage,scan.reason=false,"done",reason
	CachingActive,AwaitingData=nil,nil
	if AAH.BroadUI and scan.broad then AAH.BroadUI.Finish(scan,not reason and scan.capped==0 and #scan.queue==0) end
	searchCaption(false)
	Browse.InfoLabelUpdate()
end
function Browse.CancelSearch(reason)
	SearchRequested,FilterChanged=false,false
	if Browse.Scan and Browse.Scan.active then
		-- No native query token/cancel API exists. Drain a stopped in-flight
		-- reply before a replacement search can claim its browse-update event.
		if CachingActive and AwaitingData then Browse.SearchNotBefore=Browse.Pace.clock+ABORT_DELAY end
		finishScan(reason or "Stopped; partial results")
	end
end
function Browse.PauseSession()
	local scan=Browse.Scan
	if CachingActive and AwaitingData and (not AAH.Main or AAH.Main.sessionOpen~=false) then
		Browse.SearchNotBefore=Browse.Pace.clock+ABORT_DELAY
	end
	if scan and scan.active and scan.stage~="paused" then
		if scan.query and (scan.stage=="header" or scan.stage=="pages") then
			table.insert(scan.queue,1,copyQuery(scan.query))
		end
		scan.stage="paused"
	end
	CachingActive,AwaitingData=nil,nil
end
function Browse.ResumeSession()
	local scan=Browse.Scan
	if scan and scan.active and scan.stage=="paused" then
		scan.stage,scan.nextAt="wait",math.max(Browse.Pace.clock+Browse.PageDelay(),Browse.SearchNotBefore or 0)
		searchCaption(true)
	end
	Browse.InfoLabelUpdate()
end
local function sendQuery(scan)
	local q=scan.query
	scan.sentAt,scan.retryAt=Browse.Pace.clock,nil
	scan.attempts=scan.attempts+1
	Browse.NativeGeneration=(Browse.NativeGeneration or 0)+1
	if not scan.broad and scan.attempts>1 then
		scan.items,scan.byId,scan.seen={},{},{};Browse.CurrentScanItem=1;Browse.List_Update()
	end
	local accepted=AuctionBrowseSearchItem(q.name,q.minlvl,q.maxlvl,q.rarity,1,q.rune,q.usable,q.cat1,q.cat2,q.cat3)
	if accepted==false then Browse.PaceBackOff();scan.retryAt=Browse.Pace.clock+Browse.PageDelay() end
end
local function beginQuery(scan)
	local q,soon
	for i,candidate in ipairs(scan.queue) do
		if not candidate.readyAt or candidate.readyAt<=Browse.Pace.clock then q=table.remove(scan.queue,i);break end
		soon=math.min(soon or candidate.readyAt,candidate.readyAt)
	end
	if not q and soon then scan.nextAt=soon;return end
	if not q then finishScan(); return end
	scan.query,scan.children,scan.count,scan.waitPageAt=q,nil,nil,nil
	scan.stage,scan.attempts="header",0
	scan.queries=scan.queries+1
	Browse.PrepareCachedSearch(); Browse.MaxPages,Browse.LastCached=0,0
	CachingActive,AwaitingData=true,true
	TimeRemaining=SEARCH_DELAY_START
	sendQuery(scan)
	Browse.InfoLabelUpdate()
end
local function queryDone()
	local scan=Browse.Scan
	if not scan or not scan.active or scan.stage=="wait" or scan.stage=="done" then return end
	if queryKey(scan.query)==scan.initialKey then scan.initialComplete=true end
	if scan.children then
		scan.expanded=true
		local key=queryKey(scan.query)
		if scan.unresolved[key] then scan.unresolved[key]=nil;scan.capped=scan.capped-1 end
		for _,q in ipairs(scan.children) do scan.queue[#scan.queue+1]=q end
	elseif scan.broad and scan.count==SCAN_CAP then
		local key=queryKey(scan.query)
		if not scan.unresolved[key] then scan.unresolved[key]=true;scan.capped=scan.capped+1 end
		-- Some identical-item groups have no further native partition. Poll
		-- them again at a modest pace; never label that coverage complete.
		scan.query.readyAt=Browse.Pace.clock+60
		scan.queue[#scan.queue+1]=scan.query
	else
		local key=queryKey(scan.query)
		if scan.unresolved[key] then scan.unresolved[key]=nil;scan.capped=scan.capped-1 end
	end
	scan.finished=scan.finished+1
	CachingActive,AwaitingData=nil,nil
	if #scan.queue==0 then finishScan(); return end
	scan.stage,scan.nextAt="wait",Browse.Pace.clock+Browse.PageDelay()
	scan.waitReason=nil
	Browse.InfoLabelUpdate()
end
local function retryQuery(scan,reason)
	Browse.PaceBackOff()
	scan.waitReason=reason
	scan.waitPageAt=nil
	scan.retryAt=Browse.Pace.clock+Browse.PageDelay()
	scan.stage="header"
	CachingActive,AwaitingData=true,true
	Browse.InfoLabelUpdate()
end
local function scanUpdate()
	local scan=Browse.Scan; if not scan or not scan.active then return end
	if scan.stage=="wait" and Browse.Pace.clock>=scan.nextAt and not Browse.HistoryRequestOut() then beginQuery(scan)
	elseif scan.stage=="header" then
		if scan.retryAt and Browse.Pace.clock>=scan.retryAt and not Browse.HistoryRequestOut() then
			sendQuery(scan)
		elseif not scan.retryAt and Browse.Pace.clock-scan.sentAt>=SCAN_TIMEOUT then
			retryQuery(scan,"Server response delayed; retrying")
		end
	elseif scan.stage=="pages" and scan.waitPageAt and Browse.Pace.clock-scan.waitPageAt>=SCAN_TIMEOUT then
		-- A server may report more pages than it actually supplies. Narrow a
		-- stalled query too, rather than relying only on the reported cap.
		local children=scan.broad and Browse.SplitSearch(scan.query)
		if children then scan.children=children;queryDone()
		else
			retryQuery(scan,"Page response delayed; retrying")
			Browse.PrepareCachedSearch();Browse.MaxPages=0
		end
	end
end
local function rememberListing(listing)
	local scan=Browse.Scan
	if not scan or not listing.auctionid then return listing end
	listing._nativeGeneration=Browse.NativeGeneration
	listing.searchQuery=scan.query
	if listing.itemid==200000 or listing.itemid==200003 then
		listing.count=tonumber(string.match(string.gsub(listing.name or "","%"..COMMA,""),"%d*") or "1") or 1
	end
	if scan.broad and AAH.BroadUI then return AAH.BroadUI.Remember(scan,listing) end
	local id=listing.auctionid
	if scan.seen[id] then return scan.byId[id] or {} end
	scan.seen[id],scan.byId[id]=true,listing
	scan.items[#scan.items+1]=listing
	return listing
end

local HeaderList = {
    -- Menu text, colum header text, internal value, category
    --General
    {C_LEVEL, C_LEVEL, "level", "GENERAL"},
    {AAHLocale.Messages.GENERAL_TIER_HEADER, AAHLocale.Messages.GENERAL_TIER_HEADER, "tier", "GENERAL"},
    {AAHLocale.Messages.GENERAL_PLUS_HEADER, AAHLocale.Messages.GENERAL_PLUS_HEADER, "plus", "GENERAL"},
    {AAHLocale.Messages.GENERAL_WORTH_HEADER, AAHLocale.Messages.GENERAL_WORTH_HEADER, "worth", "GENERAL"},
    {TEXT("SYS_ITEM_DURABLE"),    AAHLocale.Messages.GENERAL_DURA_HEADER, "dura", "GENERAL"},
    {TEXT("SYS_WEAPON_MDMG"),     AAHLocale.Messages.GENERAL_MDAM_HEADER, "mdam", "GENERAL"},
    {TEXT("SYS_WEAPON_DMG"),      AAHLocale.Messages.GENERAL_PDAM_HEADER, "pdam", "GENERAL"},
    {TEXT("SYS_WEAPON_ATKSPEED"), AAHLocale.Messages.GENERAL_SPEED_HEADER, "speed", "GENERAL"},
    {AAHLocale.Messages.GENERAL_DPS_HEADER, AAHLocale.Messages.GENERAL_DPS_HEADER, "dps", "GENERAL"},
    --Stats
    {TEXT("SYS_WEAREQTYPE_3"), AAHLocale.Messages.GENERAL_STAM_HEADER, "sta", "STATS"},
    {TEXT("SYS_WEAREQTYPE_2"), AAHLocale.Messages.GENERAL_STR_HEADER,  "str", "STATS"},
    {TEXT("SYS_WEAREQTYPE_6"), AAHLocale.Messages.GENERAL_DEX_HEADER,  "dex", "STATS"},
    {TEXT("SYS_WEAREQTYPE_5"), AAHLocale.Messages.GENERAL_WIS_HEADER,  "wis", "STATS"},
    {TEXT("SYS_WEAREQTYPE_4"), AAHLocale.Messages.GENERAL_INTEL_HEADER,"int", "STATS"},
    {TEXT("SYS_WEAREQTYPE_8"), AAHLocale.Messages.GENERAL_HP_HEADER,   "hp",  "STATS"},
    {TEXT("SYS_WEAREQTYPE_9"), AAHLocale.Messages.GENERAL_MP_HEADER,   "mp",  "STATS"},
    {TEXT("SYS_WEAREQTYPE_12"),AAHLocale.Messages.GENERAL_PATT_HEADER, "patt","STATS"},
    {TEXT("SYS_WEAREQTYPE_15"),AAHLocale.Messages.GENERAL_MATT_HEADER, "matt","STATS"},
    {TEXT("SYS_ARMOR_DEF"),    AAHLocale.Messages.GENERAL_PDEF_HEADER, "pdef","STATS"},
    {TEXT("SYS_ARMOR_MDEF"),   AAHLocale.Messages.GENERAL_MDEF_HEADER, "mdef","STATS"},
    --Attributes
    {TEXT("SYS_WEAREQTYPE_18"), AAHLocale.Messages.GENERAL_PCRIT_HEADER, "pcrit","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_20"), AAHLocale.Messages.GENERAL_MCRIT_HEADER, "mcrit","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_16"), AAHLocale.Messages.GENERAL_PACC_HEADER,  "pacc", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_195"),AAHLocale.Messages.GENERAL_MACC_HEADER,  "macc", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_17"), AAHLocale.Messages.GENERAL_PDOD_HEADER,  "pdod", "ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_22"), AAHLocale.Messages.GENERAL_PARRY_HEADER, "parry","ATTRIBUTES"},
    {TEXT("SYS_WEAREQTYPE_150"),AAHLocale.Messages.GENERAL_HEAL_HEADER,  "heal", "ATTRIBUTES"},
    --Other
}
local HeaderFrames = {
	"AAH_BrowseHeaderName",
	"AAH_BrowseHeaderCustom1",
	"AAH_BrowseHeaderCustom2",
	"AAH_BrowseHeaderLeftTime",
	"AAH_BrowseHeaderSeller",
	"AAH_BrowseHeaderPPU",
	"AAH_BrowseHeaderPrice",
	"AAH_BrowseHeaderStats",
	"AAH_BrowseHeaderDura",
}

local function ToNum(str)
	local n = tonumber(string.match(str, "[%d%.]+"))
	if not n then
		n = tonumber(string.match(str, "%d+%.%d+"))
	end
	return n or 0
end

local function Trim(str)
	return string.match(str, "^%s*(.-)%s*$")
end

Browse.KeyFinderTable = { -- resolve strings in tooltips to their types
	[Trim(TEXT("PET_LEVEL"))] = "level",
	[string.gsub(TEXT("SYS_TOOLTIP_RUNE_LEVEL"), " %%.", "")] = "tier", -- fix the " %d" pattern placement in this loca string
	[Trim(TEXT("SYS_ITEM_COST"))] = "worth",
	[Trim(TEXT("SYS_WEAPON_DMG"))] = "pdam",
	[Trim(TEXT("SYS_WEAPON_MDMG"))] = "mdam",
	[Trim(TEXT("SYS_ARMOR_DEF"))] = "pdef",
	[Trim(TEXT("SYS_ARMOR_MDEF"))] = "mdef",
	[Trim(TEXT("SYS_WEAREQTYPE_3"))] = "sta",
	[Trim(TEXT("SYS_WEAREQTYPE_2"))] = "str",
	[Trim(TEXT("SYS_WEAREQTYPE_6"))] = "dex",
	[Trim(TEXT("SYS_WEAREQTYPE_5"))] = "wis",
	[Trim(TEXT("SYS_WEAREQTYPE_4"))] = "int",
	[Trim(TEXT("SYS_WEAREQTYPE_13"))] = "pdef",
	[Trim(TEXT("SYS_WEAREQTYPE_14"))] = "mdef",
	[Trim(TEXT("SYS_WEAREQTYPE_12"))] = "patt",
	[Trim(TEXT("SYS_WEAREQTYPE_15"))] = "matt",
	[Trim(TEXT("SYS_WEAREQTYPE_8"))] = "hp",
	[Trim(TEXT("SYS_WEAREQTYPE_9"))] = "mp",
	[Trim(TEXT("SYS_WEAREQTYPE_18"))] = "pcrit",
	[Trim(TEXT("SYS_WEAREQTYPE_20"))] = "mcrit",
	[Trim(TEXT("SYS_WEAREQTYPE_16"))] = "pacc",
	[Trim(TEXT("SYS_WEAREQTYPE_195"))] = "macc",
	[Trim(TEXT("SYS_WEAREQTYPE_17"))] = "pdod",
	[Trim(TEXT("SYS_WEAREQTYPE_150"))] = "heal",
	[Trim(TEXT("SYS_WEAREQTYPE_22"))] = "parry",
	[Trim(TEXT("SYS_WEAREQTYPE_25"))] = "pdam",
	[Trim(TEXT("SYS_WEAREQTYPE_191"))] = "mdam",
	[Trim(TEXT("SYS_WEAPON_ATKSPEED"))] = "speed",
	[Trim(TEXT("SYS_ITEM_DURABLE"))] = "dura",
}

-- num = extra rows, value = extra height, extra = extra width (see AAH_Layout.lua).
-- Cherry's Kit: the search and filter panels are HEADER_EXTRA taller than in 6.0.2 (room for the
-- two rarity dropdowns), so the list and categories start that much lower and are that much shorter.
Browse.HEADER_EXTRA = 20
Browse.SEARCH_EXTRA_MAX = 40 -- extra width for the search panel (wider rarity dropdowns)

function Browse.Resize(num, value, extra)
	extra = extra or 0
	local hx = Browse.HEADER_EXTRA
	value = value - hx
	num = math.floor(value / AAH.Layout.ROW)
	Browse.Results.list = Browse.Results.list or {}
	AAH_BrowseList:SetSize(666 + extra, 340 + value)
	AAH_BrowseInfoLabel:SetWidth(350+extra)
	if AAH_BrowseScanBar then AAH_BrowseScanBar:SetWidth(350+extra) end
	AAH_BrowseCategory:SetSize(142, 340 + value)
	for _, f in ipairs({ AAH_BrowseList, AAH_BrowseCategory }) do
		f:ClearAllAnchors()
	end
	AAH_BrowseCategory:SetAnchor("TOPLEFT", "TOPLEFT", "AAH_BrowseFrame", 18, 102 + hx)
	AAH_BrowseList:SetAnchor("TOPLEFT", "TOPLEFT", "AAH_BrowseFrame", 156, 102 + hx)
	local searchExtra = math.max(0, math.min(extra, Browse.SEARCH_EXTRA_MAX))
	AAH_BrowseSearch:SetSize(450 + searchExtra, 77 + hx)
	AAH_BrowseFilter:SetHeight(77 + hx)
	Browse.SearchExtra = searchExtra
	AAH.Layout.Try(AAH_BrowseSavedSearch, "SetHeight", 481 + value + hx)
	Browse.DisplayedItems = math.max(1, math.min(7 + num, Browse.MAX_ROWS))
	Browse.TreeItems=Browse.DisplayedItems
	for i = Browse.DisplayedItems + 1, Browse.MAX_ROWS do
		getglobal("AAH_BrowseListItem"..i):Hide()
	end
	for i = (Browse.TreeItems * 2) + 1, Browse.MAX_ROWS * 2 do
		getglobal("AAH_BrowseCategoryButton"..i):Hide()
	end
	for i = (Browse.DisplayedItems * 2) + 7, Browse.MAX_ROWS * 2 + 6 do
		getglobal("AAH_BrowseSavedSearchButton"..i):Hide()
	end

	Browse.LayoutColumns(extra)
	UIDropDownMenu_SetWidth(AAH_BrowseRarityDropDown, 80 + searchExtra)
	UIDropDownMenu_SetWidth(AAH_BrowseRarityMinDropDown, 80 + searchExtra)
	if AAH.Filters.Layout then
		AAH.Filters.Layout(extra - searchExtra)
	end

	Browse.List_UpdateScrollBar()
	Browse.List_UpdateItems()
	Browse.CategoryScrollBar_Update()
	AAH.SavedSearch.ScrollBar_Update()
end

-- Splits extra width between the Stats column and Item Name.
function Browse.ColumnWidths(extra)
	if not (AAH_SavedSettings and AAH_SavedSettings.StatsColumn) or extra < 70 + Browse.DURA_W + 6 then
		return 0, extra - Browse.DURA_W - 6
	end
	-- the Durability column takes its width first, then the Stats column gets the extra width
	-- (up to 330, room for "1: 2: 3:" a line), Item Name the rest
	extra = extra - Browse.DURA_W - 6
	local stats = math.min(extra, 330)
	return stats, extra - stats
end

local function placeHeader(name, x)
	local h = _G[name]
	h:ClearAllAnchors()
	h:SetAnchor("TOP", "TOPLEFT", "AAH_BrowseList", x, 6)
end

-- Columns: Item Name, the two custom columns (Level and Tier by default), Dura (maximum
-- durability), Stats, then time left, seller and prices. Everything after Stats moves right by the
-- Dura and Stats widths.
Browse.DURA_W = 40
local AFTER_CUSTOM2 = {
	-- cell, its point, offset from the right of Custom2 (or Stats)
	{ "LeftTime", "BOTTOMLEFT", 6 },
	{ "Seller", "TOPLEFT", 6 },
	{ "PPUBuy", "TOPLEFT", 102 },
}

-- Maximum durability for the Dura column; over 101 (the stats carry the power modifier bonus) in green.
function Browse.DuraText(listing)
	local d = tonumber(listing and listing.dura) or 0
	if d <= 0 then
		return ""
	end
	if d > AAH.Stats.DURA_LIMIT then
		return "|cff40ff40" .. d .. "|r"
	end
	return tostring(d)
end

function Browse.DuraHeader_OnEnter(this)
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText("Maximum durability", 1, 1, 1)
	GameTooltip:AddLine("Green: over 101, the item's stats get the power modifier bonus. The Stats column shows them without it.", 0, 0.75, 0.95)
	GameTooltip:Show()
end

function Browse.LayoutColumns(extra)
	local statsW, nameExtra = Browse.ColumnWidths(extra)
	Browse.StatsWidth = statsW
	for i = 1, Browse.MAX_ROWS do
		local n = "AAH_BrowseListItem"..i
		_G[n]:SetWidth(636 + extra)
		_G[n]:SetHeight(40)
		_G[n.."Stats"]:SetHeight(36)
		_G[n.."Name"]:SetWidth(145 + nameExtra)
		local before = n.."Dura"
		if statsW > 0 then
			_G[n.."Stats"]:SetWidth(statsW)
			for line = 1, AAH.Stats.NAME_LINES do
				_G[n.."StatsText"..line]:SetWidth(statsW)
			end
			_G[n.."Stats"]:ClearAllAnchors()
			_G[n.."Stats"]:SetAnchor("LEFT", "RIGHT", n.."Dura", 6, 0)
			_G[n.."Stats"]:Show()
			before = n.."Stats"
		else
			_G[n.."Stats"]:Hide()
		end
		for _, c in ipairs(AFTER_CUSTOM2) do
			local cell = _G[n..c[1]]
			cell:ClearAllAnchors()
			cell:SetAnchor(c[2], "RIGHT", before, c[3], 0)
		end
	end
	local duraShift = Browse.DURA_W + 6
	local shift = nameExtra + duraShift + ((statsW > 0) and (statsW + 6) or 0)
	placeHeader("AAH_BrowseHeaderName", 112 + nameExtra / 2)
	placeHeader("AAH_BrowseHeaderCustom1", 238 + nameExtra)
	placeHeader("AAH_BrowseHeaderCustom2", 308 + nameExtra)
	placeHeader("AAH_BrowseHeaderDura", 343 + nameExtra + Browse.DURA_W / 2)
	if statsW > 0 then
		placeHeader("AAH_BrowseHeaderStats", 343 + nameExtra + duraShift + statsW / 2)
		AAH_BrowseHeaderStats:Show()
	else
		AAH_BrowseHeaderStats:Hide()
	end
	placeHeader("AAH_BrowseHeaderLeftTime", 367 + shift)
	placeHeader("AAH_BrowseHeaderSeller", 422 + shift)
	placeHeader("AAH_BrowseHeaderPPU", 484 + shift)
	placeHeader("AAH_BrowseHeaderPrice", 591 + extra)
end

function Browse.List_UpdateScrollBar()
	local maxValue = #(Browse.Results.list or {}) - Browse.DisplayedItems
	if maxValue > 0 then
		AAH_BrowseListScrollBar:SetMinMaxValues(0, maxValue)
		AAH_BrowseListScrollBar:Show()
	else
		AAH_BrowseListScrollBar:SetMinMaxValues(0, 0)
		AAH_BrowseListScrollBar:Hide()
	end
end

function Browse.Frame_OnLoad(this)
	AAH_BrowseHeaderPPU:SetText(AAHLocale.Messages.GENERAL_PRICE_PER_UNIT_HEADER)
	AAH_BrowseHeaderCustom2:SetText(AAHLocale.Messages.GENERAL_TIER_HEADER)
	AAH_BrowseHeaderStats:SetText("Stats: " .. ((AAH_SavedSettings and AAH_SavedSettings.StatsDisplay == "names") and "Names" or "Values"))

	for _, Header in pairs(HeaderFrames) do
		_G[Header]:SetWidth(_G[Header]:GetTextWidth() + 12)
	end

	AAH_BrowseHeaderCustom1:SetTextColor(0.6,0.8,1)
	AAH_BrowseHeaderCustom2:SetTextColor(0.6,0.8,1)
	UIDropDownMenu_Initialize(AAH_BrowseHeaderCustom1Menu, Browse.HeaderCustomMenu, "MENU")
	UIDropDownMenu_Initialize(AAH_BrowseHeaderCustom2Menu, Browse.HeaderCustomMenu, "MENU")

	AAH_BrowseUsableButtonLabel:SetText(AAHLocale.Messages.BROWSE_USABLE)
	AAH_BrowseResetButton:SetText(AAHLocale.Messages.BROWSE_CLEAR_BUTTON)
	AAH_BrowseFilterPPUButtonLabel:SetText(AAHLocale.Messages.BROWSE_PPU)
	AAH_BrowseFilterMinPriceEditBoxLabel:SetText(AAHLocale.Messages.BROWSE_MIN)
	AAH_BrowseFilterMaxPriceButtonLabel:SetText(AAHLocale.Messages.BROWSE_MAX)
	AAH_BrowseFilter1EditBoxLabel:SetText(AAHLocale.Messages.BROWSE_FILTER)
	AAH_BrowseSearchLabel:SetText(AAHLocale.Messages.BROWSE_SEARCH_PARAMETERS)

    UIDropDownMenu_SetWidth(AAH_BrowseRuneDropDown, 60)
    UIDropDownMenu_Initialize(AAH_BrowseRuneDropDown, Browse.RuneDropDown_Show)
    UIDropDownMenu_SetWidth(AAH_BrowseRarityDropDown, 80)
    UIDropDownMenu_Initialize(AAH_BrowseRarityDropDown, Browse.RarityDropDown_Show)
    UIDropDownMenu_SetWidth(AAH_BrowseRarityMinDropDown, 80)
    UIDropDownMenu_Initialize(AAH_BrowseRarityMinDropDown, Browse.RarityMinDropDown_Show)
    Browse.RarityUpdateText()

	AAH.Filters.InitDropDowns()

	Browse.PrepareCachedSearch()
end

function Browse.Frame_OnUpdate(this, elapsedTime)

	if SearchRequested then
		SearchDelay = SearchDelay - elapsedTime
        if SearchDelay <= 0 then
            SearchRequested = false
            Browse.ExecuteSearch(SearchBroadRequested)
        end
	end

	Browse.Pace.clock = Browse.Pace.clock + (elapsedTime or 0)
	if AAH.BroadUI and (not Browse.helperCheckAt or Browse.Pace.clock>=Browse.helperCheckAt) then
		Browse.helperCheckAt=Browse.Pace.clock+1;AAH.BroadUI.UpdateHelperState()
		local scan=Browse.Scan
		if scan and scan.broad and scan.active and AAH.BroadCache then
			if AAH.BroadCache.State()~="running" then
				Browse.PauseSession();scan.pausedForHelper=true;scan.waitReason="Global Bank helper unavailable; broad scan paused."
			elseif scan.pausedForHelper and (not AAH.Main or AAH.Main.sessionOpen~=false) then
				scan.pausedForHelper,scan.waitReason=nil,nil;Browse.ResumeSession()
			end
		end
		if AAH.BroadCache and (not Browse.cachePollAt or Browse.Pace.clock>=Browse.cachePollAt) then
			Browse.cachePollAt=Browse.Pace.clock+30;AAH.BroadCache.ReadHelper();AAH.BroadUI.Refresh()
		end
	end
	local connected=not AAH.Main or AAH.Main.sessionOpen~=false
	if connected then scanUpdate() end
	-- one request at a time: no price history while a page is on its way (Cherry's Kit)
	if connected and AAH.History.Processing and not (CachingActive and AwaitingData) then
		AAH.History.Queue_Process()
	end

	if Browse.FilteringActive then
        Browse.DoFilteringStep(elapsedTime)
	end

	if FilterChanged then
		FilterDelay = FilterDelay - elapsedTime
        if FilterDelay <=0 then
            FilterChanged = false
            Browse.List_Update()
        end
	end

	if CachingActive and not (Browse.Scan and Browse.Scan.stage=="header") then
		TimeRemaining = TimeRemaining - elapsedTime
		Browse.Pace.time = Browse.Pace.time + (elapsedTime or 0)

        if TimeRemaining <= 0 then
            if Browse.CurrentCachePage <= Browse.MaxPages then
                if Browse.CurrentCachePage == 1 then
                    Browse.CachePage(true)
                elseif AwaitingData then
                    Browse.CachePage(false)
                elseif Browse.HistoryRequestOut() then
                    TimeRemaining = 0.5 -- wait for the price history answer first
                elseif AuctionBrowseNextPage(Browse.CurrentCachePage) then
                    Browse.CachePage(false)
                else
                    paceRefused()
                    if Browse.Scan then Browse.Scan.waitPageAt=Browse.Scan.waitPageAt or Browse.Pace.clock end
                    TimeRemaining = Browse.PageDelay()
                end
            else
                CachingActive = nil
                queryDone()
            end
        end
	end
end

local function receiveSearchHeader()
	if Browse.CurrentCachePage == 1 and Browse.Cache.PAGEREADY[1] == false and CachingActive then
		if Browse.Scan and Browse.Scan.stage=="header" and Browse.Scan.retryAt then return true end
		Browse.MaxPages = GetAuctionBrowseMaxPages()
		Browse.EnsureCachePages(Browse.MaxPages)
		local scan=Browse.Scan
		if scan and scan.active and (scan.stage=="header" or scan.stage=="pages") then
			scan.stage,scan.count,scan.retryAt,scan.waitReason="pages",GetAuctionBrowseMaxItems(),nil,nil
			scan.children=scan.broad and scan.count==SCAN_CAP and Browse.SplitSearch(scan.query) or nil
		end
		if GetAuctionBrowseMaxItems() == 0 then
			CachingActive = nil
			AAH_BrowseProgressLabel:SetText(AAHLocale.Messages.BROWSE_NO_RESULTS)
			queryDone()
		else
			TimeRemaining = 0
		end
		return true
	end
end
function AAH.Events.AUCTION_BROWSE_UPDATE(this)
	if Browse.BuyoutEvent == true then
		Browse.BuyoutEvent = false
		Browse.Event_OnBuyout()
	end
	if receiveSearchHeader() then return end
	if CachingActive and AwaitingData then
		-- Cherry's Kit: the page we are waiting for has arrived; read it now, not on the next retry
		TimeRemaining = 0
	end
end

function Browse.Event_OnBuyout()
    local idx, info = Browse.List_GetSelected()
    assert(idx)
    local auctionid = info.auctionid
    table.remove(Browse.Results.list, idx)
    Browse.Cache_ClearAuction(auctionid)

    if idx>#Browse.Results.list then idx=idx-1 end
    Browse.List_SetSelected(Browse.Results.list[idx] and Browse.Results.list[idx].auctionid)

    Browse.List_UpdateItems()
end

function AAH.Events.AUCTION_SEARCH_RESULT()
	receiveSearchHeader()
	TimeRemaining = 0
	AAH_BrowseSearchButton:Enable()
end

function AAH.Events.AUCTION_BORWSE_PRICE_UPDATE(this)
    Browse.AUCTION_BORWSE_PRICE_UPDATE(arg1,arg2,arg3)
end

function Browse.AUCTION_BORWSE_PRICE_UPDATE(auctionid,bidprice,buyer)
    local cache = Browse.Cache_FindAuction(auctionid)
    if cache then
        cache.bidPrice = bidprice
        cache.isBuyer = buyer
        Browse.Cache_CalculatePPU(cache)
    end
    Browse.List_UpdateItems()
end

-- Cherry's Kit: an item that was already read (listing.parsed, a filter change on the same
-- results) costs a fifth of a new one, so re-filtering goes about five times faster.
local PARSED_COST = 0.2

local function nextFilterItem()
    Browse.CurrentFilterItem = Browse.CurrentFilterItem + 1
    if Browse.CurrentFilterItem > Browse.MaxPageItems then
        Browse.CurrentFilterItem = 1
        Browse.CurrentFilterPage = Browse.CurrentFilterPage + 1
    end
end

function Browse.DoFilteringStep(elapsedTime)

    local old_count = #Browse.Results.list
    local old_sel_index = Browse.List_GetSelected()

    AAH.Filters.Prepare() -- read the filter fields once per frame, not once per item
    local budget = AAH_SavedSettings.FilterSpeed
    while budget > 0 do
        if Browse.Scan then
            local listing=Browse.Scan.items[Browse.CurrentScanItem or 1]
            if not listing then Browse.FilteringActive=false;Browse.ResultsDirty=true;break end
            budget=budget-(listing.parsed and PARSED_COST or 1)
            Browse.AddListingToList(listing)
            Browse.CurrentScanItem=(Browse.CurrentScanItem or 1)+1
        else
        while (not(Browse.Cache.PAGEREADY and Browse.Cache.PAGEREADY[Browse.CurrentFilterPage] == true and
	        Browse.Cache.CACHEDDATA[Browse.CurrentFilterPage][Browse.CurrentFilterItem] and
	        Browse.Cache.CACHEDDATA[Browse.CurrentFilterPage][Browse.CurrentFilterItem].auctionid
	        or (Browse.CurrentFilterPage > Browse.MaxPages)))
        do
            -- stop at the first page that is not loaded yet; List_Update_AddPage resumes there
            if CachingActive and Browse.Cache.PAGEREADY and Browse.Cache.PAGEREADY[Browse.CurrentFilterPage] == false then
                budget = 0
                break
            end
            nextFilterItem()
        end
        if budget <= 0 then
            break
        end
        if Browse.CurrentFilterPage > Browse.MaxPages then
            Browse.FilteringActive = false
            break
        else
            local listing = Browse.Cache.CACHEDDATA[Browse.CurrentFilterPage][Browse.CurrentFilterItem]
            budget = budget - (listing.parsed and PARSED_COST or 1)
            Browse.AddItemToList(Browse.CurrentFilterPage, Browse.CurrentFilterItem)
            nextFilterItem()
        end
        end
    end
    AAH.Filters.Done()

    Browse.InfoLabelUpdate()

    if old_count ~= #Browse.Results.list then
        Browse.ResultsDirty = true
    end
    SortClock = SortClock + (elapsedTime or 0)
    if Browse.ResultsDirty and (not Browse.Results.sortIndex or SortClock >= SORT_INTERVAL or not Browse.FilteringActive) then
        Browse.ResultsDirty = nil
        SortClock = 0

        if Browse.Results.sortIndex then
            Browse.List_Sort(Browse.Results.sortIndex)
            Browse.Pace.sorts = Browse.Pace.sorts + 1
        end

        local maxValue = #(Browse.Results.list) - Browse.DisplayedItems
        if maxValue > 0 or (Browse.Results.pageNum > 1 and maxValue == 0) then
            AAH_BrowseListScrollBar:SetMinMaxValues(0, maxValue)
            AAH_BrowseListScrollBar:Show()
        else
            AAH_BrowseListScrollBar:SetMinMaxValues(0, 0)
            AAH_BrowseListScrollBar:Hide()
        end

        local new_sel_index = Browse.List_GetSelected()
        if old_sel_index and new_sel_index then
            local first_index = AAH_BrowseListScrollBar:GetValue()

            if old_sel_index>=first_index and old_sel_index < first_index + Browse.DisplayedItems then
                AAH_BrowseListScrollBar:SetValue(first_index+new_sel_index-old_sel_index)
            end
        end

        Browse.List_UpdateItems()
    end
end

function Browse.Frame_StopUpdates()
    Browse.CancelSearch("Stopped; partial results")
    CachingActive = nil
	FilterChanged = false
	SearchRequested = false
	Browse.FilteringActive = false

	Browse.PrepareCachedSearch()
end

function Browse.Header_OnClick(this, key)
	local id = this:GetID()
 if id == 8 and key == "LBUTTON" then
  AAH_SavedSettings.StatsDisplay = AAH_SavedSettings.StatsDisplay == "names" and "values" or "names"
  this:SetText("Stats: " .. (AAH_SavedSettings.StatsDisplay == "names" and "Names" or "Values"))
  if AAH.Layout then AAH.Layout.Apply(AAH.Layout.Size()) else Browse.List_UpdateItems() end
  return
 elseif id == 8 and key == "RBUTTON" then
  key = "LBUTTON"
 end
	if key == "LBUTTON" then
		Browse.ClearSortIcons()
		if Browse.Results.sortIndex == id or Browse.Results.sortIndex == -id then
			Browse.SortMode = (Browse.SortMode + 1) % 4
		else
			Browse.SortMode = 0
		end
		if id == 7 or id == 6 then
            AAH.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], Browse.SortMode)
		else
			if Browse.Results.sortIndex == id then
				id = -id
                AAH.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 1)
			else
                AAH.Tools.SetSortIcon(_G[this:GetName().."SortIcon"], 0)
			end
		end
		Browse.List_Sort(id)
	elseif key == "RBUTTON" then
		if id == 2 then
			Browse.CurrentCustomHeaderID = 1
			ToggleDropDownMenu(AAH_BrowseHeaderCustom1Menu)
		elseif id == 3 then
			Browse.CurrentCustomHeaderID = 2
			ToggleDropDownMenu(AAH_BrowseHeaderCustom2Menu)
		end
	end
end

local SortFunc = {
	["70"] = "SortBidLess",
	["71"] = "SortBidMore",
	["72"] = "SortBuyoutLess",
	["73"] = "SortBuyoutMore",
	["60"] = "SortBidPPULess",
	["61"] = "SortBidPPUMore",
	["62"] = "SortBuyoutPPULess",
	["63"] = "SortBuyoutPPUMore",
}

function Browse.ClearSortIcons()
	for _, name in ipairs({"Name", "Custom1", "Custom2", "LeftTime", "Seller", "PPU", "Price", "Stats", "Dura"}) do
		_G["AAH_BrowseHeader"..name.."SortIcon"]:SetFile("")
	end
end

function Browse.List_Sort(index)
	Browse.Results.sortIndex = index
	local i = math.abs(index)
	if i == 7 or i == 6 then
		table.sort(Browse.Results.list, AAH.Tools[SortFunc[i..Browse.SortMode]])
	else
		if i == 1 then
			AAH.Tools.CurrentSortItem = "name"
		elseif i == 2 then
			AAH.Tools.CurrentSortItem = Browse.CustomSortItem1
		elseif i == 3 then
			AAH.Tools.CurrentSortItem = Browse.CustomSortItem2
		elseif i == 4 then
			if Browse.Scan and Browse.Scan.broad and AAH.BroadCache then
				for _,record in ipairs(Browse.Results.list) do record._seenAge=AAH.BroadCache.Age(record.cacheEntry) or math.huge end
				AAH.Tools.CurrentSortItem = "_seenAge"
			else AAH.Tools.CurrentSortItem = "leftTime" end
		elseif i == 5 then
			AAH.Tools.CurrentSortItem = "seller"
		elseif i == 8 then
			AAH.Tools.CurrentSortItem = "statsum"
		elseif i == 9 then
			AAH.Tools.CurrentSortItem = "dura"
		end
		if Browse.Results.sortIndex > 0 then
			table.sort(Browse.Results.list, AAH.Tools.SortLess)
		else
			table.sort(Browse.Results.list, AAH.Tools.SortMore)
		end
	end
	Browse.List_UpdateItems()
end

function Browse.HeaderCustomMenu()
	local info = {}
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		info.text = AAHLocale.Messages.BROWSE_HEADER_CUSTOM_TITLE
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAHLocale.Messages.GENERAL_GENERAL
		info.value = "GENERAL"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAHLocale.Messages.GENERAL_STATS
		info.value = "STATS"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
		info = {}
		info.text = AAHLocale.Messages.GENERAL_ATTRIBUTES
		info.value = "ATTRIBUTES"
		info.notCheckable = true
		info.hasArrow = true
		UIDropDownMenu_AddButton(info, 1)
--		info = {}
--		info.text = AAHLocale.Messages.GENERAL_OTHER
--		info.value = "OTHER"
--		info.notCheckable = true
--		info.hasArrow = true
--		UIDropDownMenu_AddButton(info, 1)
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		for i = 1, #(HeaderList) do
			if HeaderList[i][4] == UIDROPDOWNMENU_MENU_VALUE then
				info = {}
				info.text = HeaderList[i][1]
				info.arg1 = HeaderList[i][2]
				info.value = HeaderList[i][3]
				info.arg2 = Browse.CurrentCustomHeaderID
				info.notCheckable = true
				info.func = function(button)
					Browse["CustomSortItem"..button.arg2] = button.value
					local header = getglobal("AAH_BrowseHeaderCustom"..button.arg2)
					header:SetText(button.arg1)
					header:SetWidth(header:GetTextWidth() + 12)
					if Browse.Results.sortIndex == button.arg2 + 1 or Browse.Results.sortIndex == -(button.arg2 + 1) then
						Browse.ClearSortIcons()
					end
					CloseDropDownMenus()
					Browse.List_UpdateItems()
				end
				UIDropDownMenu_AddButton(info, 2)
			end
		end
	end
end

function Browse.BidButton_OnClick(this)
	local money = AAH.MoneyFrame.GetMoney(AAH_BrowseBidMoneyInput)

    local idx, entry = Browse.List_GetSelected()
	if idx then
        AAH.Pay.PayAuction(entry, money, false, AAH.Pay.AuctionType.Browse)
	end
end

function Browse.HistoryButton_OnClick(this)
    local idx, entry = Browse.List_GetSelected()
    if idx then
        AAH.History.RequestHistoryPopup(entry.auctionid,entry.itemid)
    end
end

function Browse.BuyoutButton_OnClick(this)
    local idx, entry = Browse.List_GetSelected()
	if idx then
		AAH.Pay.PayAuction(entry, 0, true, AAH.Pay.AuctionType.Browse)
	end
end

function Browse.CategoryScrollBar_Update()
	local maxValue = GetAuctionBrowseFilterMaxItems(Browse.SelectedCategory[1], Browse.SelectedCategory[2]) - ((Browse.TreeItems or Browse.DisplayedItems) * 2)
	if maxValue > 0 then
		AAH_BrowseCategoryScrollBar:Show()
		AAH_BrowseCategoryScrollBar:SetMinMaxValues(0, maxValue)
	else
		AAH_BrowseCategoryScrollBar:Hide()
		AAH_BrowseCategoryScrollBar:SetMinMaxValues(0, 0)
	end
	Browse.Category_UpdateList()
end

function Browse.Category_UpdateList()
	Browse.CategoryButtonNums = 0
	Browse.CategoryScrollValue = AAH_BrowseCategoryScrollBar:GetValue()
	Browse.Category_SetItemInfo(1, GetAuctionBrowseFilterList())
	for i = Browse.CategoryButtonNums + 1, (Browse.TreeItems or Browse.DisplayedItems) * 2 do
		_G["AAH_BrowseCategoryButton"..i]:Hide()
	end
end

function Browse.Category_SetItemInfo(layer, ...)
	for i = 1, arg.n do
		if Browse.CategoryButtonNums >= (Browse.TreeItems or Browse.DisplayedItems) * 2 then
			return
		end
		if Browse.CategoryScrollValue > 0 then
			Browse.CategoryScrollValue = Browse.CategoryScrollValue - 1
		else
			local count = Browse.CategoryButtonNums + 1
            local bname = "AAH_BrowseCategoryButton"..count
			local button = _G[bname]
			local normalText = _G[bname.."NormalText"]
			local highlightText = _G[bname.."HighlightText"]
			local lineTexture = _G[bname.."Line"]
			local backgoundTexture = _G[bname.."Backgound"]

			local width = 116
			button.layer = layer
			button.index = i
			if layer == 1 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(1.0)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, 0)
				normalText:SetWidth(width - 20)
				normalText:SetColor(1, 1, 0)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 10, 0)
				highlightText:SetWidth(width - 20)
				highlightText:SetColor(1, 1, 0)
			elseif layer == 2 then
				backgoundTexture:Show()
				backgoundTexture:SetAlpha(0.5)
				lineTexture:Hide()
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, 0)
				normalText:SetWidth(width - 25)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 15, 0)
				highlightText:SetWidth(width - 25)
				highlightText:SetColor(1, 1, 1)
			else
				backgoundTexture:Hide()
				lineTexture:Show()
				if i == arg.n then
					lineTexture:SetTexCoord(0, 1, 0.5, 0.8125)
				else
					lineTexture:SetTexCoord(0, 1, 0, 0.3125)
				end
				normalText:ClearAllAnchors()
				normalText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, 0)
				normalText:SetWidth(width - 30)
				normalText:SetColor(1, 1, 1)
				highlightText:ClearAllAnchors()
				highlightText:SetAnchor("LEFT", "LEFT", button:GetName(), 20, 0)
				highlightText:SetWidth(width - 30)
				highlightText:SetColor(1, 1, 1)
			end
			button:SetText(arg[i])
			if Browse.SelectedCategory[layer] == i then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
			button:Show()
			Browse.CategoryButtonNums = count
		end
		if layer == 1 then
			if Browse.SelectedCategory[1] == i then
				Browse.Category_SetItemInfo(layer + 1, GetAuctionBrowseFilterList(i))
			end
		elseif layer == 2 then
			if Browse.SelectedCategory[2] == i then
				Browse.Category_SetItemInfo(layer + 1, GetAuctionBrowseFilterList(Browse.SelectedCategory[1], i))
			end
		end
	end
end

function Browse.CategoryButton_OnClick(this, key)
	for index, value in pairs(Browse.SelectedCategory) do
		if index > this.layer then
			Browse.SelectedCategory[index] = nil
		end
	end
	if Browse.SelectedCategory[this.layer] == this.index then
		Browse.SelectedCategory[this.layer] = nil
	else
		Browse.SelectedCategory[this.layer] = this.index
	end
	Browse.CategoryScrollBar_Update()
end

function Browse.RuneDropDown_Show()
	for i = 1, 5 do
		info= {}
		info.text = Browse.RuneInfo[i]
		info.func = function(button)
			AAH.Tools.SetDropDown(AAH_BrowseRuneDropDown, button:GetID(), button:GetText())
		end
		UIDropDownMenu_AddButton(info)
	end
end

-- Cherry's Kit: rarity is two dropdowns under the Rarity header, "max" and "min". The names follow
-- what players call them (the game's own names in brackets): Uncommon (Normal, green), Rare (Good,
-- blue), Epic (Rare, purple), Legendary (Epic, orange), Mythic (Legendary and the Level 6-10
-- rarities), Item Shop last. Each keeps the colour of the game rarity it stands for.
-- RarityMin / RarityMax are positions in Browse.RARITIES (nil = any). When both pick the same
-- single game rarity the server searches for it; otherwise the server searches all rarities and
-- AAH.Filters.CheckFilter drops the others. Game rarity q is entry q + 1 of RarityInfo (the
-- server's value) and the colour GetItemQualityColor(q) gives item names.
Browse.RARITIES = {
	{ name = "Uncommon", q = { 1 } },
	{ name = "Rare", q = { 2 } },
	{ name = "Epic", q = { 3 } },
	{ name = "Legendary", q = { 4 } },
	{ name = "Mythic", q = { 5, 6, 7, 9, 10 } },
	{ name = "Item Shop", q = { 8 } },
}
local RANK_OF = { [0] = 0 }
for rank, r in ipairs(Browse.RARITIES) do
	for _, q in ipairs(r.q) do
		RANK_OF[q] = rank
	end
end

-- The position of game rarity q in Browse.RARITIES (0 = common/white; unknown higher ones = Mythic).
function Browse.RarityRank(q)
	q = tonumber(q) or 0
	return RANK_OF[q] or ((q > 10) and 5 or 0)
end

local function rarityColor(rank)
	return GetItemQualityColor(Browse.RARITIES[rank].q[1])
end

local function colored(rank)
	local r, g, b = rarityColor(rank)
	return string.format("|cff%02x%02x%02x%s|r", math.floor((r or 1) * 255), math.floor((g or 1) * 255),
		math.floor((b or 1) * 255), Browse.RARITIES[rank].name)
end

local function rarityDropDown(which)
	return (which == "min") and AAH_BrowseRarityMinDropDown or AAH_BrowseRarityDropDown
end

-- Shows "max Epic" / "min Any" on the two dropdowns.
function Browse.RarityUpdateText()
	for _, which in ipairs({ "max", "min" }) do
		local rank = (which == "min") and Browse.RarityMin or Browse.RarityMax
		AAH.Tools.SetDropDown(rarityDropDown(which), (rank or 0) + 1,
			"|cff999999" .. which .. "|r " .. (rank and colored(rank) or "Any"), {1, 1, 1})
	end
end

-- The rarity value for AuctionBrowseSearchItem: one game rarity, or 1 (all).
function Browse.ServerRarity()
	local lo, hi = Browse.RarityMin, Browse.RarityMax
	if lo and lo == hi and #Browse.RARITIES[lo].q == 1 then
		return Browse.RARITIES[lo].q[1] + 1
	end
	return 1
end

-- lo / hi are positions in Browse.RARITIES or nil.
function Browse.SetRarityRange(lo, hi)
	Browse.RarityMin, Browse.RarityMax = lo, hi
	Browse.RarityUpdateText()
	Browse.FilterChange()
end

-- Turns a saved search's rarity into a range (6.0.2 saved one game rarity, 1 = all).
function Browse.RarityFromSaved(data)
	if data.RarityLo or data.RarityHi then
		return data.RarityLo, data.RarityHi
	end
	local id = tonumber(data.Rarity) or 1
	if id > 1 then
		local rank = Browse.RarityRank(id - 1)
		if rank > 0 then
			return rank, rank
		end
	end
	return nil, nil
end

local function rarityMenu(which)
	local current = (which == "min") and Browse.RarityMin or Browse.RarityMax
	local info = { text = "Any", checked = (current == nil) }
	info.func = function()
		if which == "min" then
			Browse.SetRarityRange(nil, Browse.RarityMax)
		else
			Browse.SetRarityRange(Browse.RarityMin, nil)
		end
		CloseDropDownMenus()
	end
	UIDropDownMenu_AddButton(info)
	for rank, r in ipairs(Browse.RARITIES) do
		info = { text = r.name, checked = (current == rank) }
		info.textR, info.textG, info.textB = rarityColor(rank)
		info.func = function()
			local lo, hi = Browse.RarityMin, Browse.RarityMax
			if which == "min" then
				lo = rank
				if hi and hi < rank then hi = rank end
			else
				hi = rank
				if lo and lo > rank then lo = rank end
			end
			Browse.SetRarityRange(lo, hi)
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info)
	end
end

function Browse.RarityDropDown_Show()
	rarityMenu("max")
end

function Browse.RarityMinDropDown_Show()
	rarityMenu("min")
end

function Browse.ResetButton_OnClick()
	AAH_BrowseNameEditBox:SetText("")
	AAH_BrowseMinLvlEditBox:SetText("")
	AAH_BrowseMaxLvlEditBox:SetText("")
	Browse.RarityMin, Browse.RarityMax = nil, nil
	Browse.RarityUpdateText()
	AAH.Tools.SetDropDown(AAH_BrowseRuneDropDown, 1, Browse.RuneInfo[1])
	AAH_BrowseUsableButton:SetChecked(false)
	Browse.SelectedCategory = {}
	Browse.CategoryScrollBar_Update()
	AAH.Filters.ResetKinds()
	AAH_BrowseFilterPPUButton:SetChecked(false)
	AAH_BrowseFilterBidButton:SetChecked(false)
	AAH_BrowseFilterMinPriceEditBox:SetText("")
	AAH_BrowseFilterMaxPriceEditBox:SetText("")
end

function Browse.SearchButton_OnClick(broad)
    if Browse.Scan and Browse.Scan.active then Browse.CancelSearch();return end
	if AAH.Main and AAH.Main.sessionOpen==false then Browse.InfoLabelUpdate();return end

	Browse.PrepareCachedSearch()
	Browse.List_Update()

	if not CachingActive then
		Browse.ExecuteSearch(broad==true)
	else
		AAH_BrowseSearchButton:Disable()
		CachingActive = nil
		SearchRequested = true
		SearchBroadRequested = broad==true
		SearchDelay = ABORT_DELAY
		AAH_BrowseProgressLabel:SetText(AAHLocale.Messages.BROWSE_CANCELLING)
		AAH_BrowseInfoLabel:SetText("")
	end
end

function Browse.ExecuteSearch(broad)
	local name = AAH_BrowseNameEditBox:GetText()
	local minlvl = AAH_BrowseMinLvlEditBox:GetNumber()
	local maxlvl = AAH_BrowseMaxLvlEditBox:GetNumber()
	local rarity = Browse.ServerRarity()
	local rune = UIDropDownMenu_GetSelectedID(AAH_BrowseRuneDropDown)
	local usable = AAH_BrowseUsableButton:IsChecked()
    local cat1=Browse.SelectedCategory[1]
    local cat2=Browse.SelectedCategory[2]
    local cat3=Browse.SelectedCategory[3]

	Browse.DoSearch(name, minlvl, maxlvl, rarity, rune, usable, cat1,cat2,cat3,broad)
end

function Browse.DoSearch(name, minlvl, maxlvl, rarity, rune, usable, cat1, cat2, cat3,broad)
	if AAH.Main and AAH.Main.sessionOpen==false then Browse.InfoLabelUpdate();return end
	if broad and AAH.BroadUI and not AAH.BroadUI.UpdateHelperState() then
		AAH_BrowseProgressLabel:SetText(AAH.BroadUI.HelperMessage());AAH.BroadUI.UpdateHelperState();return
	end
	if AAH.BroadUI then
		if AAH.Main and AAH.Main.ClickTab then AAH.Main.ClickTab(broad and 5 or 1,true)
		else AAH.BroadUI.Switch(broad and "broad" or "normal",true) end
	end
	Browse.CancelSearch()

	name = string.gsub(name, "'", "%%") -- see: http://forum.runesofmagic.com/showthread.php?t=490924&p=4405930#post4405930

	if Browse.LastSearch.name ~= name or
		Browse.LastSearch.minlvl ~= minlvl or
		Browse.LastSearch.maxlvl ~= maxlvl or
		Browse.LastSearch.rarity ~= rarity or
		Browse.LastSearch.rarityMin ~= Browse.RarityMin or
		Browse.LastSearch.rarityMax ~= Browse.RarityMax or
		Browse.LastSearch.rune ~= rune or
		Browse.LastSearch.usable ~= usable or
		Browse.LastSearch.cat1 ~= cat1 or
		Browse.LastSearch.cat2 ~= cat2 or
		Browse.LastSearch.cat3 ~= cat3
	then
		Browse.Results.sortIndex = nil
		Browse.SortMode = 0
		Browse.ClearSortIcons()
	end
	Browse.LastSearch = {
		name = name,
		minlvl = minlvl,
		maxlvl = maxlvl,
		rarity = rarity,
		rarityMin = Browse.RarityMin,
		rarityMax = Browse.RarityMax,
		rune = rune,
		usable = usable,
		cat1 = cat1,
		cat2 = cat2,
		cat3 = cat3,
	}
	Browse.Scan={active=true,broad=broad==true,stage="wait",items={},byId={},seen={},queue={copyQuery(Browse.LastSearch)},
		queries=0,finished=0,capped=0,unresolved={},initialKey=queryKey(Browse.LastSearch),
		nextAt=math.max(Browse.Pace.clock,Browse.SearchNotBefore or 0)}
	Browse.CurrentScanItem=1
	if AAH.BroadUI then AAH.BroadUI.Attach(Browse.Scan,Browse.LastSearch) end

	AAH_BrowseProgressLabel:SetText(AAHLocale.Messages.BROWSE_SEARCHING)
	AAH_BrowseInfoLabel:SetText("")
    if (cat1 == 13 and cat2 == 1) then
        AAH_BrowseHeaderPPU:SetText(AAHLocale.Messages.GENERAL_UNITS_PER_PRICE_HEADER)
    else
        AAH_BrowseHeaderPPU:SetText(AAHLocale.Messages.GENERAL_PRICE_PER_UNIT_HEADER)
    end

	if Browse.HistoryRequestOut() then
		Browse.Scan.nextAt=math.max(Browse.Scan.nextAt,AAH.History.RequestedAt+HISTORY_TIMEOUT)
	end
	AAH.History.ClearQueue()

	Browse.Results.pageNum = 1
	Browse.PrepareCachedSearch()
	Browse.List_Update()

	Browse.Pace.pages, Browse.Pace.refusals, Browse.Pace.busy, Browse.Pace.time, Browse.Pace.sorts = 0, 0, 0, 0, 0
	searchCaption(true)
	CachingActive,AwaitingData=nil,nil
	scanUpdate()
end

function Browse.PrepareCachedSearch()
	Browse.Cache.PAGEREADY = {}
	Browse.Cache.CACHEDDATA = {}
	Browse.EnsureCachePages(20)
	Browse.CurrentCachePage = 1
end

-- Cherry's Kit: the 6.0.2 cache had exactly 20 pages (1000 items, the server's usual cap).
-- It now grows to whatever page count the server reports, so a bigger result never breaks it.
function Browse.EnsureCachePages(pages)
	pages = tonumber(pages) or 0
	for i = 1, pages do
		if Browse.Cache.PAGEREADY[i] == nil then
			Browse.Cache.PAGEREADY[i] = false
			Browse.Cache.CACHEDDATA[i] = {}
		end
	end
end

function Browse.Filter_TooltipDisplay(this, num)
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", 0, -50)
	GameTooltip:SetText(AAHLocale.Messages.BROWSE_FILTER_TOOLTIP_HEADER .. num, 1, 1, 1)
	for _, filter in ipairs(AAH.Filters.List) do
		if filter.coms == "-" then
			GameTooltip:AddSeparator()
		else
			GameTooltip:AddDoubleLine(filter.coms, filter.desc, 1, 0.82, 0, 0, 0.75, 0.95)
		end
	end

	GameTooltip:AddLine(AAHLocale.Messages.BROWSE_FILTER_TOOLTIP_TEXT1, 0, 0.75, 0.95) --Do not edit before generation. This would wrap lines to early.
	GameTooltip:Show()
end

function Browse.FilterChange()
	FilterChanged = true
	FilterDelay = FILTER_DELAY
end

function Browse.CachePage(firstPage)

	local link, itemid, itemname
	local j, max
	-- check if all items are loaded
	if (Browse.CurrentCachePage < Browse.MaxPages) then -- not on last page
		j = Browse.MaxPageItems
	else -- last page
		max=GetAuctionBrowseMaxItems()
		j = max - (Browse.MaxPages-1)*Browse.MaxPageItems
	end

	local auctionid, name, count, rarity, texture, level, leftTime, seller, isBuyer, moneyMode, bidPrice, buyoutPrice = GetAuctionBrowseItemInfo(Browse.CurrentCachePage, j)
	if not auctionid then -- not loaded
		if Browse.Scan then Browse.Scan.waitPageAt=Browse.Scan.waitPageAt or Browse.Pace.clock end
		if Browse.CurrentCachePage <= Browse.MaxPages then
			TimeRemaining = SEARCH_DELAY_RETRY
			AwaitingData = true
		else -- end of result
			CachingActive = nil -- stop loading
			AwaitingData = nil
		end
		return
	end

	AwaitingData = nil
	if Browse.Scan then Browse.Scan.waitPageAt=nil end
	for i = 1, Browse.MaxPageItems do
		auctionid, name, count, rarity, texture, level, leftTime, seller, isBuyer, moneyMode, bidPrice, buyoutPrice = GetAuctionBrowseItemInfo(Browse.CurrentCachePage, i)
		if auctionid then
			link = GetAuctionBrowseItemLink(auctionid)
			itemid, itemname = AAH.Tools.ParseLink(link)
		end

		local listing = {
			auctionid = auctionid,
			itemid = itemid,
			link = link,
			name = name,
			count = count,
			rarity = rarity,
			texture = texture,
			level = level,
			levelcolor = NORMAL_FONT_COLOR_CODE,
			leftTime = leftTime,
			seller = seller,
			isBuyer = isBuyer,
			moneyMode = moneyMode,
			bidPrice = bidPrice,
			buyoutPrice = buyoutPrice,
		}
		Browse.Cache.CACHEDDATA[Browse.CurrentCachePage][i] = rememberListing(listing)
        if auctionid and not (Browse.Scan and Browse.Scan.broad) then AAH.History.Queue_Insertitem(auctionid, name, link, itemid) end
	end

	Browse.Cache.PAGEREADY[Browse.CurrentCachePage] = true
	Browse.LastCached = Browse.CurrentCachePage
	Browse.InfoLabelUpdate()
	Browse.CurrentCachePage = Browse.CurrentCachePage + 1
	if Browse.Scan then
		Browse.FilteringActive=(Browse.CurrentScanItem or 1)<=#Browse.Scan.items
	elseif firstPage then
		Browse.List_Update()
	else
		Browse.List_Update_AddPage(Browse.LastCached)
	end
	pacePageDone()
	TimeRemaining = Browse.PageDelay()
	local scan=Browse.Scan
	if scan and scan.active and (scan.children and scan.initialComplete or Browse.CurrentCachePage>Browse.MaxPages) then queryDone() end
end

function Browse.List_Update()
	Browse.Results.nextPage = nil
    Browse.Results.maxNums = Browse.Scan and #Browse.Scan.items or GetAuctionBrowseMaxItems()
    Browse.Results.list = {}
    Browse.FilteringActive = false
    Browse.ResultsDirty = nil
    SortClock = 0
    if Browse.Results.maxNums > 0 then
        Browse.CurrentScanItem=1
        Browse.CurrentFilterPage = 1
        Browse.CurrentFilterItem = 1
        Browse.FilteringActive = true
        AAH_BrowseProgressLabel:SetText("")
        if Browse.Results.sortIndex then
            Browse.List_Sort(Browse.Results.sortIndex)
        end
    end
    Browse.List_UpdateItems()
end

function Browse.List_Update_AddPage(addPage)
	Browse.Results.nextPage = nil
    if Browse.FilteringActive == false then
        Browse.CurrentFilterPage = addPage
        Browse.CurrentFilterItem = 1
        Browse.FilteringActive = true
    end
    Browse.InfoLabelUpdate()
end

function Browse.Cache_FindAuction(auctionid)
    if Browse.Scan then return Browse.Scan.byId[auctionid] end
    for j = 1, Browse.MaxPages do
		for i = 1, Browse.MaxPageItems do
			local item = Browse.Cache.CACHEDDATA[j] and Browse.Cache.CACHEDDATA[j][i]
			if item and item.auctionid == auctionid then
				return item
			end
		end
	end
end

function Browse.Cache_ClearAuction(auctionid)
    if Browse.Scan then
        local item=Browse.Scan.byId[auctionid]
        if item then item.auctionid=nil;Browse.Scan.byId[auctionid]=nil;return true end
        return false
    end
    for j = 1, Browse.MaxPages do
        for i = 1, Browse.MaxPageItems do
			local item = Browse.Cache.CACHEDDATA[j] and Browse.Cache.CACHEDDATA[j][i]
	        if item and item.auctionid == auctionid then
                Browse.Cache.CACHEDDATA[j][i] = {}
                return true
            end
        end
    end
end

function Browse.Cache_CalculatePPU(item)
    local white = AAH.Tools.GetWhiteValue(item.itemid)
    if item.buyoutPrice > 0 then
        if item.itemid == 200000 then
            item.buyppu = item.count / item.buyoutPrice
        else
            item.buyppu = (item.buyoutPrice / item.count) / white
        end
    else
        item.buyppu = -1
    end
    if item.itemid == 200000 then
        item.bidppu = item.count / item.bidPrice
    else
        item.bidppu = (item.bidPrice / item.count) / white
    end
end

local function ResetAttributes(listing)
	listing.tier = 0		--Tier
	listing.plus = 0		--Plus
	listing.dura = 0		--Max Durability
	listing.worth = 0		--Vendor Value
	listing.mdam = 0		--Magical Damage
	listing.pdam = 0		--Physical Damage
	listing.speed = 0		--Attack Speed
	listing.dps = 0			--DPS
	listing.sta = 0			--Stamina
	listing.str = 0			--Strength
	listing.dex = 0			--Dexterity
	listing.wis = 0			--Wisdom
	listing.int = 0			--Intelligence
	listing.hp = 0			--Maximum HP
	listing.mp = 0			--Maximum MP
	listing.patt = 0		--Physical Attack
	listing.matt = 0		--Magical Attack
	listing.pdef = 0		--Physical Defense
	listing.mdef = 0		--Magical Defense
	listing.pcrit = 0		--Physical Crit Rate
	listing.mcrit = 0		--Magical Crit Rate
	listing.pacc = 0		--Physical Accuracy
	listing.macc = 0		--Magical Accuracy
	listing.pdod = 0		--Physical Dodge Rate
	listing.parry = 0		--Parry Rate
	listing.heal = 0		--Healing Bonus
	listing.slots = {}		--Cherry's Kit: the item's added (named) stats by slot, for the Stats column
	listing.slotsDone = nil
	listing.slotsBonus = nil
	listing.powerMod = nil
end
local function ParseLine(listing, line)
	line = string.gsub(line, "|c%x%x%x%x%x%x%x%x", "")
	line = string.gsub(line, "|r", "")
	local prefix, value, suffix = string.match(line, "^%s*(.-)%s*([%d%.]+)%s*(.-)%s*$")

	local key1 = Browse.KeyFinderTable[prefix]
	local key2 = Browse.KeyFinderTable[suffix]
	if key1 then
		if key1 == "worth" then --additional code for price
			value = string.gsub(value, "%"..COMMA, "") --added "%" to comma because in german this is a point instead of comma!
			listing["worth"] =  ToNum(value)
		elseif key1 == "level" then --additional code for pet eggs
			if AAH.Data.PetEggs[listing.itemid] then
				listing.levelcolor = GREEN_FONT_COLOR_CODE
				listing["level"] = ToNum(value)
			end
		elseif key1 == "dura" then --use suffix on dura to get max dura
			listing[key1] = (listing[key1] or 0) + ToNum(string.gsub(suffix, "/", ""))
		else
			listing[key1] = (listing[key1] or 0) + ToNum(value)
			return key1, ToNum(value), prefix
		end
	elseif key2 then
		listing[key2] = (listing[key2] or 0) + ToNum(value)
		return key2, ToNum(value), suffix
	end
end

local function ParseToolTip(listing)
    Browse.KeyFinderTable[listing.name.." +"] = "plus"
    ResetAttributes(listing)
    AAH_Tooltip:SetHyperLink(listing.link)
    AAH_Tooltip:Hide()
    GameTooltip1:Hide()
    GameTooltip2:Hide()
    local left, leftVis, right, rightVis

    for i = 1, 40 do
        leftVis = getglobal("AAH_TooltipTextLeft"..i):IsVisible()
        rightVis = getglobal("AAH_TooltipTextRight"..i):IsVisible()
        if not leftVis and not rightVis then
            break
        end

        local leftCtrl = getglobal("AAH_TooltipTextLeft"..i)
        local rightCtrl = getglobal("AAH_TooltipTextRight"..i)
        left = leftCtrl:GetText()
        local lkey, lvalue, lname
        if left and left ~= "" and leftVis then
	        lkey, lvalue, lname = ParseLine(listing, left)
        end
        right = rightCtrl:GetText()
        if right and right ~= "" and rightVis then
	        ParseLine(listing, right)
        else
            right = nil
        end
        AAH.Stats.ReadSlotLine(listing, (leftVis and left) or nil, right, lkey, lvalue, AAH.Stats.NativeColor(leftCtrl, left), AAH.Stats.NativeColor(rightCtrl, right))
    end
    AAH.Stats.Capture(listing) -- the item's own stats, before the derived values below
    if listing.mdam > 0 then
        listing.heal = listing.heal + (listing.mdam * 0.5)
    end
    if listing.speed > 0 and listing.pdam > 0 then
        listing.dps = listing.pdam / listing.speed
    end
end

function Browse.AddItemToList(pageNumber, itemIndex)
	if Browse.Cache.PAGEREADY and Browse.Cache.PAGEREADY[pageNumber] == true then
		Browse.AddListingToList(Browse.Cache.CACHEDDATA[pageNumber][itemIndex])
	end
end
function Browse.AddListingToList(listing)
		if not listing.auctionid then return end

        if listing.itemid == 200000 or listing.itemid == 200003 then -- Get Count from "itemname" for gold and diamonds
            listing.count = tonumber(string.match(string.gsub(listing.name, "%"..COMMA, ""), "%d*") or "1") or 1
        end

        Browse.Cache_CalculatePPU(listing)
        -- Cherry's Kit: read the tooltip and add the class conversions once per listing. 6.0.2 did
        -- both again for every item on every filter change.
        if not listing.parsed then
            ParseToolTip(listing)
            listing.parsed = true
            AAH.Filters.TooltipFor = listing.link -- AAH_Tooltip shows this item now

            if AAH.Data.Recipes[listing.itemid] then
                listing.levelcolor = GREEN_FONT_COLOR_CODE
                listing.level = AAH.Data.Recipes[listing.itemid]
            end

            local class = UnitClass("player")
            if AAH.Data.StatValues[class] then
                for stat, t in pairs(AAH.Data.StatValues[class]) do
                    for attribute, value in pairs(t) do
                        listing[attribute] = listing[attribute] + (listing[stat] * value)
                    end
                end
            elseif not Browse.WarnedClass then
                -- 6.0.2 printed this once per item; a class it does not know just skips the conversion
                Browse.WarnedClass = true
                DEFAULT_CHAT_FRAME:AddMessage("Advanced AuctionHouse: no stat conversion for class "..tostring(class).."; Str/Int etc. are not added to attack in the custom columns.")
            end
        end

        if AAH.Filters.CheckFilter(listing) then
            table.insert(Browse.Results.list, listing)
        end
end

local function scanBar(scan,percent,label)
	local bar=AAH_BrowseScanBar; if not bar then return end
	if not scan or not scan.broad or not scan.active and (scan.queries or 0)==0 then bar:Hide();return end
	if not Browse.scanBarReady then
		local path=AAH.Manifest.Root.."/Textures/scan_bar.tga"
		AAH_BrowseScanBarBackground:SetTexture(path);AAH_BrowseScanBarBackground:SetColor(.035,.07,.09)
		AAH_BrowseScanBarFill:SetTexture(path);AAH_BrowseScanBarFill:SetColor(.08,.55,.7)
		Browse.scanBarReady=true
	end
	bar:Show()
	scan.percent=percent
	AAH_BrowseScanBarFill:SetWidth(math.max(1,bar:GetWidth()*percent/100))
	AAH_BrowseScanBarText:SetText(percent.."% - "..label)
end
function Browse.InfoLabelUpdate()
	if AAH.Main and AAH.Main.sessionOpen==false then
		local message="Auction connection closed; cached results retained. Talk to the auctioneer to resume."
		scanBar(Browse.Scan,Browse.Scan and Browse.Scan.percent or 0,message)
		AAH_BrowseProgressLabel:SetText(#(Browse.Results.list or {})==0 and message or "")
		AAH_BrowseInfoLabel:SetText(string.format("%d cached auctions | %d shown",
			Browse.Scan and #Browse.Scan.items or 0,#(Browse.Results.list or {})))
		return
	end
	local scan=Browse.Scan
	if scan then
		local progress=scan.waitReason or scan.capped>0 and (scan.capped.." capped group(s) still being checked; server has not exposed the full list")
			or scan.expanded and "Scanning smaller categories and level ranges..." or "Searching..."
		local current=scan.active and (scan.stage=="header" or scan.stage=="pages") and 1 or 0
		local known=scan.finished+#scan.queue+current+(current==1 and scan.children and #scan.children or 0)
		local part=scan.stage=="pages" and Browse.MaxPages>0 and math.min(1,Browse.LastCached/Browse.MaxPages) or 0
		local percent=known>0 and math.floor(100*(scan.finished+part)/known) or 0
		if scan.active then percent=math.min(99,percent) end
		if scan.broad and scan.active and not scan.initialComplete and scan.count then
			local fetched=math.min(scan.count,Browse.LastCached*Browse.MaxPageItems)
			progress=string.format("Initial batch %d/2: %d / %d auctions (%d%%)",fetched>=500 and 2 or 1,
				fetched,math.min(1000,scan.count),math.floor(100*fetched/math.max(1,scan.count)))
		elseif scan.active and scan.stage=="pages" then
			progress=progress..string.format(" Page %d/%d",Browse.LastCached,Browse.MaxPages)
		end
		local message=scan.active and progress or scan.reason or "Search finished"
		scanBar(scan,percent,message)
		AAH_BrowseProgressLabel:SetText(#(Browse.Results.list or {})==0 and message or "")
		AAH_BrowseInfoLabel:SetText(string.format("%d "..(scan.broad and "cached offers" or "unique auctions").." | %d shown | %d%% of known searches checked (%d/%d)%s",
			#scan.items,#(Browse.Results.list or {}),percent,scan.finished,known,
			scan.active and (" | "..#scan.queue.." queued | Stop to cancel") or ""))
		return
	end
	scanBar(nil,0,"")

    local pages = Browse.MaxPages
    if not pages or pages==0 then
        pages = 1
    end

	local filterPercentPerPage = 100 / pages
	local filterPercentPerItem = filterPercentPerPage / 50

    local status={}
    status.SCANPERCENT = math.ceil(100 / pages * Browse.LastCached)
    status.MAXITEMS = GetAuctionBrowseMaxItems()
    status.FILTEREDITEMS = #Browse.Results.list
    status.FILTERPERCENT = math.ceil((filterPercentPerPage * (Browse.CurrentFilterPage - 1)) + (filterPercentPerItem * Browse.CurrentFilterItem))

	if status.FILTERPERCENT > status.SCANPERCENT then
		status.FILTERPERCENT = status.SCANPERCENT
	end

	local labeltext = AAHLocale.Messages.BROWSE_INFO_LABEL
	labeltext = labeltext:gsub("<(%w+)>", status)
	AAH_BrowseInfoLabel:SetText(labeltext)
end

function Browse.List_UpdateItems()
    local snapshot=Browse.DataView=="broad" or Browse.Scan and Browse.Scan.broad
    AAH_BrowseHeaderLeftTime:SetText(snapshot and "Last seen" or TEXT("AUCTION_BALANCE_TIME"))
    AAH_BrowseHeaderPrice:SetText(snapshot and "Last price" or TEXT("AUCTION_PRICE"))
    AAH_BrowseHeaderStats:SetText("Stats: " .. ((AAH_SavedSettings and AAH_SavedSettings.StatsDisplay == "names") and "Names" or "Values"))
    AAH_BrowseHeaderStats:SetWidth(AAH_BrowseHeaderStats:GetTextWidth() + 12)
	local first_index = AAH_BrowseListScrollBar:GetValue()

	for i = 1, Browse.DisplayedItems do
		local button = getglobal("AAH_BrowseListItem"..i)
		local info = Browse.Results.list[first_index+i]
		if info then
			button.auctionid = info.auctionid
			local buttonName = button:GetName()

			getglobal(buttonName.."Name"):SetText(info.name)
			getglobal(buttonName.."Name"):SetColor( GetItemQualityColor(info.rarity) )

			local inversecoloring = false
            local count = info.count
            if info.itemid == 200000 then
				inversecoloring = true
			    count = 0
			elseif info.itemid == 200003 then
				count = 0
            end
            SetItemButtonCount(getglobal(buttonName.."Icon"), count)

			SetItemButtonTexture(getglobal(buttonName.."Icon"), info.texture)
			if Browse.StatsWidth > 0 then
				AAH.Stats.SetCell(buttonName.."Stats", info, Browse.StatsWidth, AAH_SavedSettings.StatsDisplay)
				getglobal(buttonName.."Dura"):SetText(Browse.DuraText(info))
			end
			for k = 1, 2 do
				if not info[Browse["CustomSortItem"..k]] or info[Browse["CustomSortItem"..k]] == 0 or info[Browse["CustomSortItem"..k]] == "" then
					getglobal(buttonName.."Custom"..k):SetText("")
				elseif Browse["CustomSortItem"..k] == "level" then
					getglobal(buttonName.."Custom"..k):SetText((info.levelcolor or NORMAL_FONT_COLOR_CODE or "|cffffffff")..info.level.."|r")
				else
					getglobal(buttonName.."Custom"..k):SetText(tonumber(string.format("%.2f", info[Browse["CustomSortItem"..k]])))
				end
			end
			getglobal(buttonName.."LeftTime"):SetText(AAH.BroadUI and info.cacheEntry and AAH.BroadUI.AgeText(info) or AAH.Tools.LocalTimeString(info.leftTime))
			getglobal(buttonName.."Seller"):SetText(info.seller)

			getglobal(buttonName.."PPUBid"):SetText("")
			getglobal(buttonName.."PPUBuy"):SetText("")
			white = AAH.Tools.GetWhiteValue(info.itemid)

			if info.count > 0 and info.bidPrice > 0 then
				getglobal(buttonName.."PPUBid"):SetText(AAH.Tools.FormatThousands(math.floor(info.bidppu)))
				if info.buyoutPrice > 0 then
					getglobal(buttonName.."PPUBuy"):SetText(AAH.Tools.FormatThousands(math.floor(info.buyppu)))
				end
			end
			getglobal(buttonName.."PPUBid"):SetColor(1,1,1)
			getglobal(buttonName.."PPUBuy"):SetColor(1,1,1)

            local avg = AAH.History.GetAveragePrice(info.itemid)
			if avg then
				AAH.Tools.GetAvgPriceColor(info.bidppu, avg, buttonName.."PPUBid", inversecoloring)
				AAH.Tools.GetAvgPriceColor(info.buyppu, avg, buttonName.."PPUBuy", inversecoloring)
			end

			MoneyFrame_Update(buttonName.."BidMoney", info.bidPrice, info.moneyMode or "copper")
			if info.isBuyer then
				getglobal(buttonName.."BidMoneyText"):SetText(TEXT("AUCTION_SELF_BID"))
			else
				getglobal(buttonName.."BidMoneyText"):SetText("")
			end
			if info.buyoutPrice > 0 then
				getglobal(buttonName.."BuyoutMoney"):Show()
				MoneyFrame_Update(buttonName.."BuyoutMoney", info.buyoutPrice, info.moneyMode or "copper")
			else
				getglobal(buttonName.."BuyoutMoney"):Hide()
			end
			button:Show()
		else
			button:Hide()
		end
	end

	Browse.List_SetSelected(Browse.selected_auctionid)
end

-- Click a row: select it. Alt+click: search for every auction of that item.
function Browse.ListItem_OnClick(row, key)
	Browse.List_SetSelected(row.auctionid)
	if IsAltKeyDown and IsAltKeyDown() then
		Browse.SearchSame(row.auctionid)
	end
end

function Browse.SearchSame(auctionid)
	if AAH.BroadUI then return AAH.BroadUI.TargetSearch(auctionid) end
	local _, info = Browse.List_FindAuctionIndex(auctionid)
	if not info or not info.name then
		return
	end
	local name = info.name
	if info.itemid == 200000 or info.itemid == 200003 then
		return -- gold and diamond auctions are named after their amount
	end
	AAH_BrowseNameEditBox:SetText(name)
	Browse.SearchButton_OnClick()
end

function Browse.List_ItemIcon_OnClick(this,key)
	local _,cached=Browse.List_FindAuctionIndex(this:GetParent().auctionid)
	local itemLink = cached and cached.link or GetAuctionBrowseItemLink(this:GetParent().auctionid)
    if IsAltKeyDown and IsAltKeyDown() and key == "LBUTTON" then
        Browse.SearchSame(this:GetParent().auctionid)
    elseif IsShiftKeyDown() and key == "LBUTTON" then
        AAH.Tools.ChatEdit_AddItemLink(itemLink,true)
    elseif IsCtrlKeyDown() and key == "LBUTTON" then
        ItemPreviewFrame_SetItemLink(ItemPreviewFrame, itemLink)
    end
end

function Browse.List_FindAuctionIndex(auctionid)
    for i,entry in ipairs(Browse.Results.list) do
        if entry.auctionid == auctionid then
            return i,entry
        end
    end
end

function Browse.List_GetSelected()
    local idx,entry = Browse.List_FindAuctionIndex(Browse.selected_auctionid)
    return idx,entry
end

function Browse.List_SetSelected(auctionid)
	AAH_BrowseBidButton:Disable()
	AAH_BrowseBuyoutButton:Disable()
	AAH_BrowseHistoryButton:Disable()

	for i = 1, Browse.DisplayedItems do
        local button = getglobal("AAH_BrowseListItem"..i)
    	button:UnlockHighlight()
	end

    Browse.selected_auctionid = auctionid
    local index = Browse.List_FindAuctionIndex(auctionid)
    if not index then
        -- A refilter builds the result array incrementally. Keep the stable
        -- selection while that array is temporarily empty, then clear it only
        -- if the finished result really no longer contains the item.
        if not Browse.FilteringActive then Browse.selected_auctionid = nil end
        if AAH.BroadUI then AAH.BroadUI.UpdateSelection(Browse.selected_auctionid) end
        return
    end

    local first_index = AAH_BrowseListScrollBar:GetValue()
    local but_idx = index-first_index
    local button = _G["AAH_BrowseListItem"..but_idx]
    if button and but_idx>=1 and but_idx<=Browse.DisplayedItems then button:LockHighlight() end
	-- Read-only quote actions must not bypass the selected-row highlight.
	if AAH.BroadUI and AAH.BroadUI.UpdateSelection(auctionid) then return end
	if AAH.Main and AAH.Main.sessionOpen==false then return end
    if not button or but_idx>Browse.DisplayedItems then return end

    local _,info = Browse.List_GetSelected()
    AAH.MoneyFrame.SetMode(AAH_BrowseBidMoneyInput, info.moneyMode)
    AAH.MoneyFrame.SetMoney(AAH_BrowseBidMoneyInput, AAH.Tools.CalcBidPrice(info.bidPrice))
    if not info.isBuyer then
        AAH_BrowseBidButton:Enable()
    end
    if info.buyoutPrice > 0 then
        AAH_BrowseBuyoutButton:Enable()
    end
    AAH_BrowseHistoryButton:Enable()
end


