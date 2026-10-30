local History = {
    PriceHistoryQueue={},

	TooltipHeight = 0,
	TooltipWidth = 0,
	Processing = true,

    ItemMaxDisplay = 10,
    AutoPriceHistoryTrigger=false,

    BrowseItemLink = nil,
    BrowseHistoryTrigger = false,
    PriceHistoryProcessed = true,
}
AAH.History = History

AAH_SavedHistoryTable = {}


local function DontSaveHistory()
    return (AAH_SavedSettings.HistoryMaxSaved <= 10)
end

function History.Init()

    local build = (AAH_SavedHistoryTable._TABLEBUILD or 0)

    -- for people switching from release to alpha
    if build > 500 and build < 20121119130745 then
        History.MinimizeHistory()
		build = AAH.Manifest.Build
	end

    local build = (AAH_SavedHistoryTable._TABLEBUILD or 0)
	if build < 20121120211541 then
		build = AAH.Manifest.Build
	end

    AAH_SavedHistoryTable._TABLEBUILD = build
	SaveVariables("AAH_SavedHistoryTable")

    History.SetMaxEntries(AAH_SavedSettings.HistoryMaxSaved)
end

function History.SetMaxEntries(max)
	if max < AAH.Settings.HistoryMin then max = AAH.Settings.HistoryMin end
    if max > AAH.Settings.HistoryMax then max = AAH.Settings.HistoryMax end

	AAH_SavedSettings.HistoryMaxSaved = max

    History.UpdateHistoryEntries()
end

function History.Reset()
    AAH_SavedHistoryTable = {}
end

function History.RemoveItem(itemid)
    if AAH_SavedHistoryTable[itemid] then
		AAH_SavedHistoryTable[itemid] = nil
        return true
    end
end

function History.RequestHistoryPopup(auctionid,itemid)
    History.Processing = false
    History.curItem = itemid
    if auctionid then
        AuctionBrowseHistoryRequest(auctionid)
    else
        AuctionItemHistoryRequest()
    end
end

function History.UpdateSellItemHistory(itemid)
    History.AutoPriceHistoryTrigger = true
    History.curItem = itemid
    AuctionItemHistoryRequest()
end

function AAH.Events.AUCTION_HISTORY_SHOW()
    if History.AutoPriceHistoryTrigger == true then
		History.AutoPriceHistoryTrigger = false
		History.Queue_AddHistory(History.curItem)
		AAH.Sell.AutoFillPriceFields()
		return
	elseif History.BrowseHistoryTrigger == true then
		History.BrowseHistoryTrigger = false
		History.Queue_AddHistory(History.curBrowseItem)
		History.PriceHistoryProcessed = true
		return
	else
		History.Queue_AddHistory(History.curItem)
		History.List_Show()
	end
end

function AAH.Events.AUCTION_HISTORY_HIDE()
	History.PriceHistoryProcessed = true
	if not History.Processing then
		SendSystemMsg(AAHLocale.Messages.HISTORY_NO_DATA, true)
	end
end

----------------------------------
function History.ClearQueue()
	History.BrowseHistoryTrigger = false
	History.PriceHistoryProcessed = true
	History.Processing = true
	History.AutoPriceHistoryTrigger = false
    History.PriceHistoryQueue={}
    History.QueueSeen={}
end

function History.Queue_Insertitem(auctionid,name,link,itemid)
    if auctionid and name then
        History.QueueSeen = History.QueueSeen or {}
        if itemid ~= nil and History.QueueSeen[itemid] then
            return
        end
        if itemid ~= nil then
            History.QueueSeen[itemid] = true
        end

        local queueItem = {}
        queueItem.name = name
        queueItem.auctionid = auctionid
        queueItem.link = link
        queueItem.itemid = itemid
        table.insert(History.PriceHistoryQueue, queueItem)
    end
end

function History.Queue_Process()
    if #(History.PriceHistoryQueue) > 0 then
		if History.PriceHistoryProcessed then
			local queueItem = table.remove(History.PriceHistoryQueue)
			if queueItem and queueItem.auctionid ~= nil and queueItem.link ~= nil then
				History.PriceHistoryProcessed = false
				History.BrowseHistoryTrigger = true
                History.curBrowseItem = queueItem.itemid
                History.RequestedAt = AAH.Browse.Pace and AAH.Browse.Pace.clock -- Cherry's Kit: paging waits for the answer
				AuctionBrowseHistoryRequest(queueItem.auctionid)
			end
		end
	end
end

local function recalcSummary(itemid)
    local history = AAH_SavedHistoryTable[itemid]

    local totalcost = 0
    local totalcount = 0
    history.avg = 0
    history.median = 0
    history.min=0
    history.max=0
    if #history.history<=0 then
        return
    end

    local ppu = history.history[1].price / (history.history[1].count or 1)
    history.min = ppu
    history.max = ppu

    local all_ppu = {}
    for _,dat in ipairs(history.history) do
        local ppu = dat.price / (dat.count or 1)
        if history.min > ppu then
            history.min = ppu
        end
        if history.max < ppu then
            history.max = ppu
        end
        table.insert(all_ppu, ppu)
        totalcost = totalcost + dat.price
        totalcount = totalcount + (dat.count or 1)
    end

    table.sort(all_ppu)
    local mid = #(all_ppu) / 2 + 0.5
    history.median = (all_ppu[math.floor(mid)] + all_ppu[math.ceil(mid)]) / 2
    history.avg = totalcost / totalcount

    if itemid==200000 then
        history.avg = 1/history.avg
        history.min = 1/history.min
        history.max = 1/history.max
        history.median = 1/history.median
    end
end

local function getAuctionHistoryInfo(itemid, index)
    local e={}
    local month,day,hour,minute
    e.name, e.count, e.rarity, e.icon, e.seller, e.buyer, _, e.price, month,day,hour,minute = GetAuctionHistoryItemInfo(index)

    if itemid==200000 or itemid==200003 then
        e.count = tonumber(string.match(string.gsub(e.name, "%"..COMMA, ""), "%d*") or "1") or 1
        e.name = TEXT("Sys"..itemid.."_name")
    end

    local hash = ""
    hash = hash.. month
    hash = hash.. day
    hash = hash.. hour
    hash = hash.. minute
    hash = hash.. e.count
    hash = hash.. e.seller
    hash = hash.. e.buyer
    hash = hash.. e.price

    e.date = string.format("%02d/%02d %02d:%02d", month,day,hour,minute)
    e.ppu = e.price / e.count
    if itemid==200000 then e.ppu = 1/e.ppu end

    return e, hash
end

local function getAuctionHistoryFromHistory(itemid, index)

    local base = AAH_SavedHistoryTable[itemid]

    local e={}

    for k,v in pairs(base.history[index]) do e[k]=v end
    e.count = e.count or 1
    e.rarity = e.rarity or base.rarity
    e.icon = e.icon or base.icon

    e.ppu = e.price / e.count
    if itemid==200000 then e.ppu = 1/e.ppu end

    return e
end

function History.Queue_AddHistory(itemid)

	local maxnums = GetAuctionHistoryItemNums()

	local startplace = 1
    if AAH_SavedHistoryTable[itemid] then
        for i = maxnums, 1, -1 do
            local _, hash = getAuctionHistoryInfo(itemid, i)
            if hash == AAH_SavedHistoryTable[itemid].hash then
                startplace = i + 1
                break
            end
        end
    else
        AAH_SavedHistoryTable[itemid] = {}
        _,_,AAH_SavedHistoryTable[itemid].rarity,
            AAH_SavedHistoryTable[itemid].icon = GetAuctionHistoryItemInfo(1)
        AAH_SavedHistoryTable[itemid].avg = 0
        AAH_SavedHistoryTable[itemid].history = {}
    end

    AAH_SavedHistoryTable[itemid].history = AAH_SavedHistoryTable[itemid].history or {}
    local history = AAH_SavedHistoryTable[itemid].history
    for i = startplace, maxnums do

        local entry,hash = getAuctionHistoryInfo(itemid, i)

        -- clean up
        entry.name=nil
        entry.ppu=nil
        if entry.count==1 then entry.count = nil end
        if entry.rarity==AAH_SavedHistoryTable[itemid].rarity then entry.rarity = nil end
        if entry.icon==AAH_SavedHistoryTable[itemid].icon then entry.icon = nil end

        while #history >= AAH_SavedSettings.HistoryMaxSaved do
            table.remove(history, #history)
        end
        table.insert(history, 1, entry)
        AAH_SavedHistoryTable[itemid].hash = hash
    end

    recalcSummary(itemid)

    if DontSaveHistory() then
        AAH_SavedHistoryTable[itemid].hash = nil
        if #history<10 then
            AAH_SavedHistoryTable[itemid].history_count = #history
        else
            AAH_SavedHistoryTable[itemid].history_count = nil
        end
        AAH_SavedHistoryTable[itemid].history = nil
    end
end
----------------------------------
function History.MinimizeHistory()

    local base={["history"]=1,["hash"]=1,["max"]=1,["min"]=1,["median"]=1,["avg"]=1,["rarity"]=1,["icon"]=1}
    local sub={["count"]=1,["date"]=1,["price"]=1,["buyer"]=1,["seller"]=1,["rarity"]=1,["icon"]=1,["count"]=1}


    for id, h in pairs(AAH_SavedHistoryTable) do
        if id~="_TABLEBUILD" then
            h.hash = string.gsub(h.hash,"^"..h.name,"")
            h.totalcount=nil
            h.totalcost=nil
            h.name=nil

            local found=true
            while found do
                found=false
                for k,v in pairs(h) do
                    if type(k)=="number" then
                        h[k]=nil
                        found = true
                    end
                end
            end


            for _, ent in ipairs(h.history) do
                ent.name=nil
                ent.realname=nil
                ent.moneymode=nil
                ent.ppu=nil
                if ent.count==1 then ent.count = nil end

                if not h.rarity then h.rarity = ent.rarity end
                if not h.icon then h.icon = ent.icon end
                if ent.rarity==h.rarity then ent.rarity = nil end
                if ent.icon==h.icon then ent.icon = nil end

                for k,v in pairs(ent) do
                    if not sub[k] then
                        AAHDebug("OBSOLETE-SUB?: "..k)
                        sub[k]=1
                    end
                end
            end

            for k,v in pairs(h) do
                if not base[k] then
                    AAHDebug("OBSOLETE-BASE?: "..k)
                    base[k]=1
                end
            end
        end
    end
end

function History.UpdateHistoryEntries()

    if DontSaveHistory() then
        for id, h in pairs(AAH_SavedHistoryTable) do
            if id~="_TABLEBUILD" then
                h.hash = nil
                h.history_count = nil
                if h.history and #h.history<10 then
                    h.history_count = #h.history
                end
                h.history = nil
            end
        end
    else
        for id, h in pairs(AAH_SavedHistoryTable) do
            if id~="_TABLEBUILD" then
                while h.history and #h.history >= AAH_SavedSettings.HistoryMaxSaved do
                    table.remove(h.history, #h.history)
                end
            end
        end
    end

end

----------------------------------
function History.List_Show()

    local itemid = History.curItem
	local white = AAH.Tools.GetWhiteValue(itemid)

    if (itemid == 200000) then
        AAH_HistoryHeaderPPU:SetText(AAHLocale.Messages.GENERAL_UNITS_PER_PRICE_HEADER)
    else
        AAH_HistoryHeaderPPU:SetText(AAHLocale.Messages.GENERAL_PRICE_PER_UNIT_HEADER)
    end

    local base = AAH_SavedHistoryTable[itemid]

    local numhistory = base.history and #(base.history) or GetAuctionHistoryItemNums()
    if numhistory == 0 then
        SendSystemMsg("no history available") -- TODO: localize
        AAH_HistoryList:Hide()
        return
    end


    local summary = AAHLocale.Messages.HISTORY_SUMMARY_MINMAX
    summary = string.gsub(summary, "<MINIMUM>", "|cffffd200"..AAH.Tools.FormatNumber(base.min / white).."|r")
    summary = string.gsub(summary, "<MAXIMUM>", "|cffffd200"..AAH.Tools.FormatNumber(base.max / white).."|r")
    AAH_HistoryMinMaxLabel:SetText(summary)

    local summary = AAHLocale.Messages.HISTORY_SUMMARY_AVERAGE
    summary = string.gsub(summary, "<MEDIAN>", "|cffffd200"..AAH.Tools.FormatNumber(base.median / white).."|r")
    summary = string.gsub(summary, "<AVERAGE>", "|cffffd200"..AAH.Tools.FormatNumber(base.avg / white).."|r")
    AAH_HistoryAverageLabel:SetText(summary)

    local summary = AAHLocale.Messages.HISTORY_SUMMARY_NUMHISTORY
    summary = string.gsub(summary, "<NUMHISTORY>", numhistory)
    AAH_HistoryNumHistoryLabel:SetText(summary)

    local maxvalue = numhistory - History.ItemMaxDisplay
    if maxvalue > 0 then
        AAH_HistoryListScrollBar:SetMinMaxValues(0, maxvalue)
        AAH_HistoryListScrollBar:Show()
    else
        AAH_HistoryListScrollBar:SetMinMaxValues(0, 0)
        AAH_HistoryListScrollBar:Hide()
    end
    History.List_UpdateItems()
    AAH_HistoryList:Show()
end

function History.List_UpdateItems()

    local itemid = History.curItem
	local name,_,_,_,_,_,moneymode = GetAuctionHistoryItemInfo(1)
	local white = AAH.Tools.GetWhiteValue(itemid)

	local hidecount = false
	local inversecoloring = false

    if itemid==200000 or itemid==200003 then
        name =TEXT("Sys"..itemid.."_name")
        hidecount = true
	    inversecoloring = (itemid==200000)
    end

    local base = AAH_SavedHistoryTable[itemid]
    local numhistory = base.history and #(base.history) or GetAuctionHistoryItemNums()
    local first_line = AAH_HistoryListScrollBar:GetValue()

    for i = 1, History.ItemMaxDisplay do
        local index = first_line+i
        local frame_name = "AAH_HistoryListItem"..i
        if index <= numhistory then

            local e
            if index <= GetAuctionHistoryItemNums() then
                e = getAuctionHistoryInfo(itemid, 1+GetAuctionHistoryItemNums()-index)
            else
                e = getAuctionHistoryFromHistory(itemid, index)
            end

            local button = _G[frame_name.."Icon"]
            button.index = index
            SetItemButtonTexture(button, e.icon)

            local item_name = name or "???"
            if hidecount then
                item_name = string.format("%s %s",AAH.Tools.FormatNumber(e.count),name)
                SetItemButtonCount(button, 0)
            else
                SetItemButtonCount(button, e.count)
            end

            if index <= GetAuctionHistoryItemNums() then
                _G[button:GetName().."Red"]:Hide()
            else
                _G[button:GetName().."Red"]:Show()
            end

            local r, g, b = GetItemQualityColor(e.rarity)
            _G[frame_name.."Name"]:SetText(item_name)
            _G[frame_name.."Name"]:SetColor(r, g, b)
            _G[frame_name.."DateText"]:SetText(e.date)
            _G[frame_name.."SellerText"]:SetText(e.seller)
            _G[frame_name.."BuyerText"]:SetText(e.buyer)
            _G[frame_name.."PPU"]:SetText(AAH.Tools.FormatNumber(e.ppu / white))
            _G[frame_name.."PPU"]:SetColor(1,1,1)
            AAH.Tools.GetAvgPriceColor(e.ppu, base.avg, frame_name.."PPU", inversecoloring)
            MoneyFrame_Update(frame_name.."Price", e.price, moneymode)

            _G[frame_name]:Show()
        else
            _G[frame_name]:Hide()
        end
    end
end

function History.List_OnClose()
    History.BrowseItemLink = nil
    History.Processing = true
end


----------------------------------
function History.GetAveragePrice(itemid)
    return AAH_SavedHistoryTable[itemid] and AAH_SavedHistoryTable[itemid].avg
end

function History.GetPriceStatistic(itemid)
    local data = AAH_SavedHistoryTable[itemid]
    if not data then return end

    return data.avg, data.min, data.max, data.median
end

function AAH.ToolsShowPriceHistoryTooltip(tooltip, itemid)
	local tempString = ""
	local white = AAH.Tools.GetWhiteValue(itemid)
	AAH_PriceHistoryTooltip:SetText(AAHLocale.Messages.TOOLS_PRICE_HISTORY, 0, 0.75, 0.95)
	AAH_PriceHistoryTooltip:AddDoubleLine(AAHLocale.Messages.TOOLS_POWERED_BY, "", 0, 0.75, 0.95)

    local history = AAH_SavedHistoryTable[itemid]

	if history then
		local numhistory = history.history and #(history.history) or (history.history_count or 10)
		if numhistory > 0 then
			AAH_PriceHistoryTooltip:AddLine(" ")
			tempString = "|cffffd200"..AAH.Tools.FormatNumber(history.avg / white).."|r"
			AAH_PriceHistoryTooltip:AddDoubleLine(AAHLocale.Messages.GENERAL_AVERAGE_PRICE_PER_UNIT, tempString)
			tempString = "|cffffd200"..AAH.Tools.FormatNumber(history.median / white).."|r"
			AAH_PriceHistoryTooltip:AddDoubleLine(AAHLocale.Messages.GENERAL_MEDIAN_PRICE_PER_UNIT, tempString)
			tempString = string.gsub(AAHLocale.Messages.TOOLS_GOLD_BASED, "<SCANNED>", numhistory)
			AAH_PriceHistoryTooltip:AddDoubleLine(tempString)
		end
	else
		AAH_PriceHistoryTooltip:AddLine(" ")
		AAH_PriceHistoryTooltip:AddLine(AAHLocale.Messages.TOOLS_NO_HISTORY_DATA)
	end

	History.TooltipWidth = AAH_PriceHistoryTooltip:GetWidth()
	History.TooltipHeight = AAH_PriceHistoryTooltip:GetHeight()
	AAH_PriceHistoryTooltip:Show()
end

function AAH.ToolsPriceHistoryTooltip_OnUpdate(tooltip, elapsedTime)
	if ((not GameTooltip:IsVisible()) and HistoryForGameTooltip) or
        ((not GameTooltipHyperLink:IsVisible()) and HistoryForGameTooltipHyperLink) or
        ((not GameTooltip:IsVisible()) and (not GameTooltipHyperLink:IsVisible())) then
		tooltip:Hide()
	else
		if HistoryForGameTooltip then
			tooltip:ClearAllAnchors()
			tooltip:SetAnchor("TOPLEFT", "BOTTOMLEFT", GameTooltip, 0, 0)
		elseif HistoryForGameTooltipHyperLink then
			tooltip:ClearAllAnchors()
			tooltip:SetAnchor("TOPLEFT", "BOTTOMLEFT", GameTooltipHyperLink, 0, 0)
		end
		tooltip:SetWidth(History.TooltipWidth)
		tooltip:SetHeight(History.TooltipHeight)
	end
end
