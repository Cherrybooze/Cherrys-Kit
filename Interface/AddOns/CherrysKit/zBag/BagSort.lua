local Sol = LibStub("Sol")

local VERSION = "v1.05b"
local MAX_TIME = 30
local NUM_SORTS = 5
local DEFAULT_BAGREFRESH_TIPS

local locale = string.sub(GetLanguage(), 1, 2)
local func, err = loadfile(zBagKit.path.."Locales/"..locale..".lua")
if err then
	dofile(zBagKit.path.."Locales/EN.lua")
else
	func()
end

BagSort = {}

BagSort.DefaultSettings = {
    SortMode = {1}
}

BagSort.SortModeDisplayNames = zBLocale.BagSortSortModeDisplayNames;

BagSort.SortModes = {
    "Default",
    "name",
    "type",
    "totalDur",
    "level",
    "worth",
    "patk",
    "matk",
    "pdef",
    "mdef",
    "attributes",
	"runesTotal",
	"itemQuality",
}

local hookedZBag = false

function BagSort.OnLoad(frame)
    frame:RegisterEvent("VARIABLES_LOADED")
end

function BagSort.OnEvent(frame, _event, _arg1)
	if ( _event == "VARIABLES_LOADED" ) then
		BagSort.RegisterWithAddonManager()
        Sol.config.CheckSettings("BagSort", BagSort.DefaultSettings)
        BagSortConfigFrameTitle:SetText(zBLocale.BagSortConfigFrame.BagSortUsageTitle);
        for i = 1, NUM_SORTS do
            Sol.config.SetupDropdown(
                _G["BagSortConfigFrameSortType" .. i], 
                BagSort.SortModeDisplayNames, 
                BagSort_Settings.SortMode[i], 
                100, BagSort.DropdownSelected
            )
        end
        
        BagSort.Enable()
    end
end

function BagSort.RegisterWithAddonManager()
    if AddonManager then
        local addon = {
            name = "BagSort", 
            description = "Adds sort options to bag", 
            category = "Inventory",
            version = VERSION,
            author = "Alleris",
            enableScript = BagSort.Enable,
            disableScript = BagSort.Disable,
            icon = "Interface/BagFrame/BagRefresh-Normal",
            onClickScript = function() 
                if not BagFrame:IsVisible() then
                    BagFrame:Show()
                    BagSortConfigFrame:Show()
                else
                    ToggleUIFrame(BagSortConfigFrame)
                end
            end,
        }
        
        if AddonManager.RegisterAddonTable then
            AddonManager.RegisterAddonTable(addon)
        else
            AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category, 
                addon.configFrame, addon.slashCommands, addon.miniButton, addon.onClickScript)
        end
    else
        Sol.io.Print("BagSort loaded")
    end
end

function BagSort.Enable()
    -- Cherry's Kit: Reload UI keeps the old text, so only add the line once
    local extra = "\n\nHold shift and click to show sort options"
    if string.find(BAGREFRESH_TIPS or "", extra, 1, true) then
        BAGREFRESH_TIPS = string.gsub(BAGREFRESH_TIPS, "\n\nHold shift and click to show sort options", "")
    end
    DEFAULT_BAGREFRESH_TIPS = BAGREFRESH_TIPS
    BAGREFRESH_TIPS = BAGREFRESH_TIPS .. extra
    if zBag_SortFull and type(zBag_SortFull) == "function" then
        Sol.hooks.Hook("BagSort", "zBag_SortFull", BagSort.RefreshBag)
        BagSortConfigFrame:ClearAllAnchors()
        BagSortConfigFrame:SetAnchor("TOPRIGHT", "TOPLEFT", zBagBackground, 0, 0)
        hookedZBag = true
    else
        Sol.hooks.Hook("BagSort", "RefreshBag", BagSort.RefreshBag)
        hookedZBag = false
    end
end

function BagSort.Disable()
    BAGREFRESH_TIPS = DEFAULT_BAGREFRESH_TIPS
    Sol.hooks.UnHook("BagSort", "zBag_SortFull")
    Sol.hooks.UnHook("BagSort", "RefreshBag")
end

function BagSort.OnShow(frame)
    local foundDefault = false
    for i = 1, NUM_SORTS do
        if BagSort_Settings.SortMode[i] then
            local dd = _G["BagSortConfigFrameSortType" .. i]
            UIDropDownMenu_SetSelectedID(dd, BagSort_Settings.SortMode[i])
            
            local value = BagSort.SortModeDisplayNames[BagSort_Settings.SortMode[i]]
            if not foundDefault then
                BagSort.DropdownSelected(dd, BagSort_Settings.SortMode[i], value)
            end
            if value == BagSort.SortModeDisplayNames[1] then
                foundDefault = true
            end
        end
    end
end

function BagSort.DropdownSelected(dropdown, id, value)
    if value == BagSort.SortModeDisplayNames[1] then
        for i = dropdown:GetID() + 1, NUM_SORTS do 
            _G["BagSortConfigFrameSortType" .. i]:Hide()
        end
    elseif dropdown:GetID() < NUM_SORTS then
        _G["BagSortConfigFrameSortType" .. dropdown:GetID() + 1]:Show()
    end
end

-- Save config settings
function BagSort.Save()
    BagSort_Settings.SortMode = {}
    local defaultFound = false
    for i = 1, NUM_SORTS do
        local dd = _G["BagSortConfigFrameSortType" .. i]
        if not defaultFound then
            BagSort_Settings.SortMode[i] = UIDropDownMenu_GetSelectedID(dd)
            if BagSort_Settings.SortMode[i] == 1 then
                defaultFound = true
            end
        else
            UIDropDownMenu_SetSelectedID(dd, 1)
            BagSort_Settings.SortMode[i] = 1
        end
    end
    BagSort.RefreshBag(PanelTemplates_GetSelectedTab(BagFrame))
    BagSortConfigFrame:Hide()
end

function BagSort.RefreshBag()
	--yecho("RefreshBag called");
	if IsShiftKeyDown() then
        --yecho("RefreshBag shift called");
		ToggleUIFrame(BagSortConfigFrame);
        
    elseif BagSort_Settings.SortMode[1] == 1 then
        --yecho("RefreshBag default called");
		-- Default only
        if hookedZBag then
            Sol.hooks.GetOriginalFn("BagSort", "zBag_SortFull")()
        else
            Sol.hooks.GetOriginalFn("BagSort", "RefreshBag")()
        end
        
    else
        --yecho("RefreshBag else called");
		if (not zBag_VAR["displayDebugMessages"]) then 
			zBag_VAR["displayDebugMessages"]=0;
		end
		debugEcho("Debug on, hold down alt+ctrl+shift and click on the zB config icon to enter the debug interface");
		local sortedData = BagSort.GetAllBagData()
        BagSort.RearrangeItems(sortedData)
    end
end

function BagSort.GetAllBagData()
    --yecho("GetAllBagData called");
	-- if no tab specified, must be a zbag sort
    --yecho("BAG_MAX_ITEMS:" .. BAG_MAX_ITEMS);
	local maxItems = Sol.util.TernaryOp(hookedZBag, ZBAG_MAXBAG, BAG_MAX_ITEMS)
    --yecho("maxItems:" .. maxItems);
	local offset = (hookedZBag and 0)
	--yecho("offset:" .. offset);
    -- Gather data from tooltips
    local bagData = {}
    for i = 1, maxItems do
        local index = offset + i;
         --yecho("past offset index:" .. index);
		 --Sol.io.Print("RightBefore bagData[i] = Sol.data.items.GetBagItemData(1)");
		 --here is what I need to fix
		bagData[i] = BagSort.GetBagItemData(index)
		
		--yecho("past sol:" .. index);
        --bagData[i].currentLoc = i;
		if bagData[i] then bagData[i].currentLoc = i end
		
		if bagData[i] and ( not bagData[i].name or bagData[i].name == "" ) then
			bagData[i] = nil;
		else
			--yecho("Next line prints out the data for each bag item");
			--Sol.io.PrintTable(bagData[i]);
       end
   end
	--yecho("postBagData");
	Sol.table.Compact(bagData)
    
    -- Sort the data
    table.sort(bagData, BagSort.CompareFn)
    
    -- Determine where to move based on the sorted data indeces
	local buttontable = {}
	for i=1,6 do
		local a,b = GetBagPageLetTime(i)
		if not (a and b == -1) then
			for j=1,30 do
				table.insert(buttontable,(i-1)*30+j)
			end
		end
	end

    for i = 1, maxItems do
        local item = bagData[i] 
		if item and buttontable[offset + i] then
			item.moveToIndex = GetBagItemInfo(buttontable[offset + i])
        end
    end
    
    return bagData
end


function BagSort.GetBagItemData(index, tooltip)
    --yecho("BagSort.GetBagItemData");
	local bagIndex, icon, name, itemCount, locked, itemQuality = GetBagItemInfo(index);
    if not icon or not zBag_CheckBagButtonLet(index) then 
        return nil;
    end
	--yecho("BagSort.GetBagItemData2");
    if not tooltip then
        tooltip = GameTooltip;
    end
    Sol.tooltip.ClearAllText(tooltip)
    tooltip:SetBagItem(bagIndex)
    tooltip:Hide()
    --yecho("BagSort.GetBagItemData3");
    local lines = Sol.tooltip.ReadTooltip(tooltip);
	--yecho("BagSort.GetBagItemData3a");
    local data = BagSort.ParseItemDataFromLines(lines);
    --yecho("BagSort.GetBagItemData4");
	data.icon = icon
    data.name = name
    data.itemCount = itemCount
    data.locked = locked
    data.invalid = invalid
    data.link = GetBagItemLink(bagIndex)
    data.bagIndex = bagIndex
	data.itemQuality = itemQuality
	if (zBag_VAR["displayDebugMessages"] == 1) then
		if (data.name ~= "") then
			Sol.io.PrintTable(data);
		end
	end			
    --yecho("Returning from BagSort.GetBagItemData");
    return data
end

function BagSort.ParseItemDataFromLines(lines)
    --yecho("BS.PIDFromLines1");
	local colorRegex = "|cff%x%x%x%x%x%x";
	local data = {}
    local index = 1
    local numLines = #(lines.left)
    data.attributes = {}
    
    if not lines.left[index] then
        return data
    end
    --yecho(lines.left[index].text);
    if lines.left[index].text == zBLocale.BagSortMatchStrings.CurrentEquipment then
        index = index + 1
    end
    --yecho("BS.PIDFromLines2 ItemQual");
    if not Sol._help.qualityColors then
        Sol._help.qualityColors = {}
        for i = 1, 5 do
            local hexColor = Sol.color.ColorValuesToHexColor(GetItemQualityColor(i))
            Sol._help.qualityColors[hexColor] = _G["ITEM_QUALITY" .. i .. "_DESC"]
        end
    end
        
    -- Item Name is the first thing in the tooltip
    data.name = lines.left[index].text
	debugEcho("1:ItemName:" .. data.name);
	for i = 1, numLines  do
		debugEcho(" L" .. i .. ":" .. lines.left[i].text);
		if lines.right[i] then
			debugEcho(" R" .. i .. ":" .. lines.right[i].text);
		end
	 end
    local color = (data.name:sub(1,2) == "|c") and data.name:sub(5, 10)
    if color then
        --yecho(data.name .. " color:" .. color);
		data.quality = Sol._help.qualityColors[color:upper()]
	else
		--yecho(data.name .. " no color defined");
    end
    index = index + 1
    if index > numLines then
        return data
    end
    --yecho("BS.PIDFromLines3 Bound");
	debugEcho(" 3:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.Bound);
    if lines.left[index].text:match(zBLocale.BagSortMatchStrings.Bound) ~= nil then
        --yecho(zBLocale.BagSortMatchStrings.Bound);
		data.isBound = true
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines4 BWE");
	debugEcho(" 4:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.BindsWhenEquipped);

    if lines.left[index].text:match(zBLocale.BagSortMatchStrings.BindsWhenEquipped) ~= nil then
        --yecho("Binds when equipped");
		data.isBindable = true
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines5 Item Shop Item");
	debugEcho(" 5:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.ItemShopItem);
    if lines.left[index].text:match(zBLocale.BagSortMatchStrings.ItemShopItem) ~= nil then
        --yecho("Item Shop Item");
		data.isItemShopItem = true
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines6 PK Death");
	debugEcho(" 6:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.NotDroppedOnPKDeath);	
    if lines.left[index].text:match(zBLocale.BagSortMatchStrings.NotDroppedOnPKDeath) ~= nil then
        --yecho("Not dropped on PK death");
		data.isNotDropOnPKDeath = true
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines7");
	debugEcho(" 7:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.StackedNumber);	
    data.stackCount = lines.left[index].text:match(zBLocale.BagSortMatchStrings.StackedNumber)
    if data.stackCount then
        --yecho("yep, stacked");
		index = index + 1
        if index > numLines then
            return data
        end
	else
		--yecho("nope" .. lines.left[index].text);
    end
	
    --yecho("BS.PIDFromLines8c");
	--yecho(lines.left[index].text);
	debugEcho(" 8c:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.TimeTillExpiration);	
    data.liveTime = lines.left[index].text:match(zBLocale.BagSortMatchStrings.TimeTillExpiration)
    if data.liveTime then
        debugEcho(" 8d: liveTime" .. data.liveTime);
		index = index + 1
        if index > numLines then
            return data
        end
    end	
	
    --yecho("BS.PIDFromLines10");
    local color = Sol.color.GetTextColor(lines.left[index].text, lines.left[index].color)
    if color == Sol.constants.FLAVOR_TEXT_COLOR then
        data.flavorText = lines.left[index].text
        if data.flavorText:match(zBLocale.BagSortMatchStrings.DailyQuest) then
            data.type = "Quest Item"
            data.isDaily = true        
        end
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines11");
	debugEcho(" 11:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.Tier);	
    -- Items with durability must have a tier
    data.tier = tonumber(lines.left[index].text:match(zBLocale.BagSortMatchStrings.Tier))
    if data.tier then
        if lines.right[index] then
            local currentDur, totalDur = lines.right[index].text:match(zBLocale.BagSortMatchStrings.Durability)
            data.currentDur = tonumber(currentDur)
            data.totalDur = tonumber(totalDur)
            if lines.right[index + 1] and not lines.left[index + 1] then
                data.powerModifier = tonumber(lines.right[index].text:gsub(colorRegex, ""):match(zBLocale.BagSortMatchStrings.PowerModifier));
                index = index + 1
            end
        end
        index = index + 1
        if index > numLines then
            return data
        end
    end
	
	if (string.len(lines.left[index].text) < 2) then
		index = index + 1;
	end
	
    --yecho("BS.PIDFromLines12");
	debugEcho(" 12:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.Level);
	data.level = tonumber(lines.left[index].text:match(zBLocale.BagSortMatchStrings.Level))
    if data.level then
        index = index + 1
        if index > numLines then
            return data
        end
    end
	--yecho("BS.PIDFromLines13");
	--yecho("+" .. lines.left[index].text);
    --data.worth = lines.left[index].text:match("Worth: (%d+.%d+) Gold")
	--yecho("WL: " .. lines.left[index].text);
    --if data.worth then
    --    index = index + 1
	    --yecho(data.name .. " " .. data.worth);
	--	if index > numLines then
	--		return data
	--	end
	--end
	

    --yecho("BS.PIDFromLines14");
    -- For most things, the type is next
    color = Sol.color.GetTextColor(lines.left[index].text, lines.left[index].color)
    if not data.type and 
        (not color or 
            color == Sol.constants.NORMAL_TEXT_COLOR or 
            color == Sol.constants.ERROR_TEXT_COLOR) then
        
        data.type = lines.left[index].text
        if color == Sol.constants.ERROR_TEXT_COLOR then
            data.unequipable = true
        end
        if lines.right[index] then
            data.position = lines.right[index].text
        end
        index = index + 1
        if index > numLines then
            return data
        end
    end
	--Sol.io.PrintTable(data);
    --yecho("BS.PIDFromLines15");
	debugEcho(" 15:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.PhysicalDefense);	
    -- Physical defense shows up on armor only    
	local lineText = lines.left[index].text:gsub(colorRegex, "");
	lineText = lineText:gsub(",", "");
	data.pdef = tonumber(lineText:match(zBLocale.BagSortMatchStrings.PhysicalDefense))

	
	if data.pdef then
		debugEcho(" 15a pdef works");
		if lines.right[index] then
			--yecho("BS.PIDFromLines15a");
			if (zBag_VAR["displayDebugMessages"] == 1) then
				debugEcho(" 15b:" .. lines.right[index].text .. ":" .. zBLocale.BagSortMatchStrings.MagicalDefense);
			end		
			local lineText = lines.right[index].text:gsub(colorRegex, "");
			lineText = lineText:gsub(",", "");
			data.mdef = tonumber(lineText:match(zBLocale.BagSortMatchStrings.MagicalDefense))
			if ((zBag_VAR["displayDebugMessages"] == 1) and data.mdef) then
				debugEcho(" 15b2 mdef works");
			end
        end
		--yecho("BS.PIDFromLines15c");
        index = index + 1
        if index > numLines then
            --yecho("BS.PIDFromLines15d");
			return data;
        end
		--yecho("BS.PIDFromLines15e");
    end
    --yecho("BS.PIDFromLines16");
	debugEcho(" 16:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.PhysicalDamage);
	local lineText = lines.left[index].text:gsub(colorRegex, "");
	lineText = lineText:gsub(",", "");
    data.patk = tonumber(lineText:match(zBLocale.BagSortMatchStrings.PhysicalDamage))
    if data.patk then
		debugEcho(" 16a patk works");
		if lines.right[index] then
            local lineText = lines.right[index].text:gsub(colorRegex, "");
			lineText = lineText:gsub(",", "");
			data.speed = tonumber(lineText:match(zBLocale.BagSortMatchStrings.AttackSpeed))
			if ((zBag_VAR["displayDebugMessages"] == 1) and data.speed) then
				debugEcho(" 16b speed works");
			end			
        end
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines17");
	debugEcho(" 17:" .. lines.left[index].text .. ":" .. zBLocale.BagSortMatchStrings.MagicalDamage);
    local lineText = lines.left[index].text:gsub(colorRegex, "");
	lineText = lineText:gsub(",", "");
	data.matk = tonumber(lineText:match(zBLocale.BagSortMatchStrings.MagicalDamage))
    if data.matk then
		debugEcho(" 17a matk works");
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines18");
    -- may have already gotten worth by now
	--local tempWorth = "Worth: 3,655";
	--yecho(tempWorth);
	--yecho("test1:" .. tempWorth:match("Worth: (%d+)"));
	--yecho("test2:" .. tempWorth:match("Worth: (%d+.%d+)"));
	
	--local tempWorth = "Worth: 655";
	--yecho(tempWorth);
	--yecho("test1b:" .. tempWorth:match("Worth: (%d+)"));
	--yecho("test2b:" .. tempWorth:match("Worth: (%d+.%d+)"));
	
	--yecho("test4:" .. tempWorth:match("Worth: (%d+?%d+)"));
	--yecho("test5:" .. tempWorth:match("Worth: (%d+','%d+)"));
	--yecho("test3:" .. tempWorth:match("Worth: (%d+%d+)"));
    if not data.worth then
		local lineText = lines.left[index].text:gsub(colorRegex, "");
		lineText = lineText:gsub("["..COMMA.."]", "");
		data.worth = tonumber(lineText:match(zBLocale.BagSortMatchStrings.Worth));
		
		if not data.worth then
			 --yecho("trying to find worth");
			 local allLinesText = "";
			 for i = 1, numLines  do
				--yecho("i:" .. i);
				allLinesText = allLinesText .. " " .. lines.left[i].text;
			 end
			 allLinesText = allLinesText:gsub(colorRegex, "");
			 allLinesText = allLinesText:gsub("["..COMMA.."]", "");
			 --yecho(allLinesText);
			 data.worth = tonumber(allLinesText:match(zBLocale.BagSortMatchStrings.Worth));
			--yecho("Worth not found");
		end 
		if data.worth then
            --yecho("Worth:" .. data.worth);
			index = index + 1
            if index > numLines then
                return data
            end
        end
    end
    --yecho("BS.PIDFromLines19");
	debugEcho(" 19 blue text");	
    -- Blue text is 'flavor' text; sometimes it appears on equipment, after the worth
    -- note that there's another part that checks for flavor text above
    color = Sol.color.GetTextColor(lines.left[index].text, lines.left[index].color)
    if not data.flavorText and color == Sol.constants.FLAVOR_TEXT_COLOR then
        data.flavorText = lines.left[index].text
        if data.flavorText:match(zBLocale.BagSortMatchStrings.DailyQuest) then
            data.type = "Quest Item"
            data.isDaily = true
        end
        index = index + 1
        if index > numLines then
            return data
        end
    end
    --yecho("BS.PIDFromLines20");
	debugEcho(" 20 attributes & runes");	
    for i = index, #lines.left do
        local line = lines.left[i]
        local color = Sol.color.GetTextColor(line.text, line.color)
        if color == Sol.constants.GREEN_STAT_TEXT_COLOR or color == YELLOW_STAT_TEXT_COLOR then
            table.insert(data.attributes, line.text)
            
        elseif color == Sol.constants.RUNE_TEXT_COLOR then
            local runesUsed, runesTotal = line.text:match(zBLocale.BagSortMatchStrings.Rune)
            if runesUsed then
                data.runesUsed = tonumber(runesUsed)
                data.runesTotal = tonumber(runesTotal)
            end
        end
    end
    table.sort(data.attributes)
    return data
end

-- If a should come before b in the list, returns true; else false
function BagSort.CompareFn(a, b)
    --yecho("CompareFn called");
	-- For each sort mode selected, in order, try one, then the next, ...
    for i = 1, #BagSort_Settings.SortMode do
        local sortType = BagSort.SortModes[BagSort_Settings.SortMode[i]]
        if sortType == "Default" then
            -- Default's always last
            return a.currentLoc < b.currentLoc
        elseif sortType == "attributes" then
            -- Attribs are a bit special because it's a table.
            -- The list is sorted once where the item data is built.
            for attrIndex = 1, #a.attributes do
                if not b.attributes[attrIndex] then
                    return false
                elseif a.attributes[attrIndex] < b.attributes[attrIndex] 
                    or a.attributes[attrIndex] > b.attributes[attrIndex] then
                    
                    return a.attributes[attrIndex] < b.attributes[attrIndex]
                end
            end
            if #b.attributes > #a.attributes then
                return true
            end
        else
            -- Everything else is just simple values
            if not a[sortType] and b[sortType] then
                return true
            elseif not b[sortType] and a[sortType] then
                return false
            elseif not a[sortType] and not b[sortType] then
                -- go to the next sort type
            elseif a[sortType] < b[sortType] or a[sortType] > b[sortType] then
                return a[sortType] < b[sortType]
            end
        end
    end
    
    -- If all sort orders are used, this acts like a Default
    return a.currentLoc < b.currentLoc
end


function BagSort.FindItemBzBagIndex(data, bagIndex)
    for i = 1, #data do
        if data[i].bagIndex == bagIndex then
            return data[i]
        end
    end
end

-- Check if the bag looks like BagSort.SortedData
function BagSort.AreAllItemsInPlace() 
    return #BagSort.SortedData == 0
end

function BagSort.DebugSortedData()    
    local indeces = {}
    for i = 1, 30 do 
        indeces[i] = GetBagItemInfo(i)
    end
    
    local moveFromSlot, moveToSlot
    for k,v in pairs(BagSort.SortedData) do 
        for i, index in ipairs(indeces) do 
            if index == v.bagIndex then 
                moveFromSlot = i
            elseif index == v.moveToIndex then
                moveToSlot = i
            end
        end
        Sol.io.Printf("%s [%2s] to %s [%2s] - %s (%s)", nil, 
            tostring(v.bagIndex), 
            tostring(moveFromSlot), 
            tostring(v.moveToIndex), 
            tostring(moveToSlot), 
            tostring(v.name), 
            tostring(v.worth)
        )
    end
end

function BagSort.RearrangeItems(sortedData)
    BagSort.SortedData = sortedData
    BagSort.SortStartTime = GetTime()
    
    --BagSort.DebugSortedData()
    BagSort.timer = Sol.timers.ScheduleTimer("BagSort", 0, BagSort.DoMove, 1)
    
    if hookedZBag then
        zBagSortFull:Disable()
    else
        BagRefreshButton:Disable()
    end
end

-- finds a bag slot (e.g., 1-30 for bag i) from a bag index (e.g., 60-90 for bag i)
function BagSort.GetBagItemSlot(index)
    for i = 1, 6 * BAG_MAX_ITEMS do
        if GetBagItemInfo(i) == index then
            return i
        end
    end
end

function BagSort.DoMove()
	-- zBgab_TestSortmsg : set true if want to spam sort msg
	-- zBgab_TestInnerSortmsg : set true if want ot spam presort msg
	-- zBgab_TestInnerSortloop : max time to presort for each DoMove
	-- zBgab_TestInnerSortLayer : 0~100, max Layer to presort
    if not BagSort.timer then return end
    
    local visited = {}
    
	-- Try to place cursor item back
	local function ClearCursor()
		if CursorHasItem() then
			if CursorItemType() == "bag" then
				PickupBagItem(GetCursorItemInfo())
			elseif CursorItemType() == "bank" then
				PickupBankItem(GetCursorItemInfo())
			elseif CursorItemType() == "action" then
				DeleteCursorItem()
			elseif CursorItemType() == "macro" then
				DeleteCursorItem()
			elseif CursorItemType() == "skill" then
				DeleteCursorItem()
			elseif CursorItemType() == "house" then --don't checke how to do yet.
			end
		end
	end
	ClearCursor()
	
	local movetable ={}
	local movetotable = {}
	local indextable = {}
	local toindextable = {}
	local emptytable = {}
	local function RebuildTable()
		for i = #BagSort.SortedData, 1, -1 do
			local item = BagSort.SortedData[i]
			if item.bagIndex == item.moveToIndex then
				table.remove(BagSort.SortedData, i)
			end
		end
		movetable ={}
		movetotable = {}
		indextable = {}
		toindextable = {}
		emptytable = {}
		for index, item in pairs(BagSort.SortedData) do
			movetable[item.bagIndex] = item.moveToIndex
			movetotable[item.moveToIndex] = item.bagIndex
			indextable[item.bagIndex] = index
			toindextable[item.moveToIndex] = index
		end
	end
	
	--inner move (just drop those same item's switch)
	zBgab_TestInnerSortloop = zBgab_TestInnerSortloop or 10
	if not zBgab_TestInnerSortLayer or type(zBgab_TestInnerSortLayer)~="number" then
		zBgab_TestInnerSortLayer = 2
	else
		zBgab_TestInnerSortLayer = math.floor(math.min(math.max(zBgab_TestInnerSortLayer,0),100)) -- mostly call 1-3 times. 
	end
	
	-- return true if they are the same thing (don't need real move)
	local function CheckSameItems(item1,item2)
		if item1.name == item2.name then
			if ( item1.itemCount > 1 or item2.itemCount > 1 ) then
				return true
			end
			if item1.link and item2.link then
				local _type1, _data1, _name1 = ParseHyperlink(item1.link)
				local _,_,nonehash1 =string.find(_data1, "(%x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+)")
				local _type2, _data2, _name2 = ParseHyperlink(item2.link)
				local _,_,nonehash2 =string.find(_data2, "(%x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+ %x+)")
				if nonehash1 == nonehash2 then
					return true
				end
			end
		end
	end
	
	--recursive
	local function CheckNextLayer(item,toitem,lvl)
		if indextable[toitem.moveToIndex] and BagSort.SortedData[indextable[toitem.moveToIndex]] and zBgab_TestInnerSortLayer >=lvl then
			local tonextitem = BagSort.SortedData[indextable[toitem.moveToIndex]]
			if CheckSameItems( item,tonextitem ) then
				if zBgab_TestInnerSortmsg and item.bagIndex ~= tonextitem.bagIndex then ChatFrame1:AddMessage("inner"..(lvl).." :"..item.bagIndex.."->"..tonextitem.bagIndex..item.name) end
				local bag = tonextitem.bagIndex
				tonextitem.bagIndex = item.bagIndex
				item.bagIndex = bag
				return 1
			else
				return CheckNextLayer(item,tonextitem,lvl+1)
			end
		end
	end
	
	--InnerSort
	if zBgab_TestInnerSortLayer >=1 then
		for i=1,zBgab_TestInnerSortloop do
			local z=nil
			RebuildTable()
			for index, item in pairs(BagSort.SortedData) do
				if  item.bagIndex ~= item.moveToIndex  then
					if CheckNextLayer(item,item,1) then	--recursive
						z = 1
						RebuildTable()
					end
				end
			end
			if not z then break end
		end
	end
	
	-- basic loop
	-- if zBgab_TestInnerSortLayer >=1 then
		-- for i=1,zBgab_TestInnerSortloop do
			-- local z=nil
			-- for index, item in pairs(BagSort.SortedData) do
				-- for i = #BagSort.SortedData, 1, -1 do
					-- local item = BagSort.SortedData[i]
					-- if item.bagIndex == item.moveToIndex then
						-- table.remove(BagSort.SortedData, i)
					-- end
				-- end
				-- movetable ={}
				-- movetotable = {}
				-- indextable = {}
				-- toindextable = {}
				-- emptytable = {}
				-- for index, item in pairs(BagSort.SortedData) do
					-- movetable[item.bagIndex] = item.moveToIndex
					-- movetotable[item.moveToIndex] = item.bagIndex
					-- indextable[item.bagIndex] = index
					-- toindextable[item.moveToIndex] = index
				-- end
				-- if  item.bagIndex ~= item.moveToIndex  then
					-- if indextable[item.moveToIndex] and BagSort.SortedData[indextable[item.moveToIndex]] then
						-- local toL1item = BagSort.SortedData[indextable[item.moveToIndex]]
						-- if item.name == toL1item.name and ( item.itemCount > 1 or toL1item.itemCount > 1 ) then
							-- if zBgab_TestInnerSortmsg and item.bagIndex ~= toL1item.bagIndex then ChatFrame1:AddMessage("inner1 :"..item.bagIndex.."->"..toL1item.bagIndex..item.name) end
							-- local bag = toL1item.bagIndex
							-- toL1item.bagIndex = item.bagIndex
							-- item.bagIndex = bag
							-- z=1
						-- else
							-- if indextable[toL1item.moveToIndex] and BagSort.SortedData[indextable[toL1item.moveToIndex]] and zBgab_TestInnerSortLayer >=2 then
								-- local toL2item = BagSort.SortedData[indextable[toL1item.moveToIndex]]
								-- if item.name == toL2item.name and ( item.itemCount > 1 or toL2item.itemCount > 1 ) then
									-- if zBgab_TestInnerSortmsg and item.bagIndex ~= toL2item.bagIndex then ChatFrame1:AddMessage("inner2 :"..item.bagIndex.."->"..toL2item.bagIndex..item.name) end
									-- local bag = toL2item.bagIndex
									-- toL2item.bagIndex = item.bagIndex
									-- item.bagIndex = bag
									-- z=1
								-- else
									-- if indextable[toL2item.moveToIndex] and BagSort.SortedData[indextable[toL2item.moveToIndex]] and zBgab_TestInnerSortLayer >=3 then
										-- local toL3item = BagSort.SortedData[indextable[toL2item.moveToIndex]]
										-- if item.name == toL3item.name and ( item.itemCount > 1 or toL3item.itemCount > 1 ) then
											-- if zBgab_TestInnerSortmsg and item.bagIndex ~= toL3item.bagIndex then ChatFrame1:AddMessage("inner3 :"..item.bagIndex.."->"..toL3item.bagIndex..item.name) end
											-- local bag = toL3item.bagIndex
											-- toL3item.bagIndex = item.bagIndex
											-- item.bagIndex = bag
											-- z=1
										-- else
											-- if indextable[toL3item.moveToIndex] and BagSort.SortedData[indextable[toL3item.moveToIndex]] and zBgab_TestInnerSortLayer >=4 then
												-- local toL4item = BagSort.SortedData[indextable[toL3item.moveToIndex]]
												-- if item.name == toL4item.name and ( item.itemCount > 1 or toL4item.itemCount > 1 ) then
													-- if zBgab_TestInnerSortmsg and item.bagIndex ~= toL4item.bagIndex then ChatFrame1:AddMessage("inner4 :"..item.bagIndex.."->"..toL4item.bagIndex..item.name) end
													-- local bag = toL4item.bagIndex
													-- toL4item.bagIndex = item.bagIndex
													-- item.bagIndex = bag
													-- z=1
												-- else
													-- if indextable[toL4item.moveToIndex] and BagSort.SortedData[indextable[toL4item.moveToIndex]] and zBgab_TestInnerSortLayer >=5 then
														-- local toL5item = BagSort.SortedData[indextable[toL4item.moveToIndex]]
														-- if item.name == toL5item.name and ( item.itemCount > 1 or toL5item.itemCount > 1 ) then
															-- if zBgab_TestInnerSortmsg and item.bagIndex ~= toL5item.bagIndex then ChatFrame1:AddMessage("inner5 :"..item.bagIndex.."->"..toL5item.bagIndex..item.name) end
															-- local bag = toL5item.bagIndex
															-- toL5item.bagIndex = item.bagIndex
															-- item.bagIndex = bag
															-- z=1
														-- else
														-- --next layer if needed
														-- end
													-- end
												-- end
											-- end
										-- end
									-- end
								-- end
							-- end
						-- end
					-- end
				-- end
			-- end
			-- if not z then i=zBgab_TestInnerSortloop+1 end
		-- end
	-- end

	RebuildTable()
	
	-- spam new table (after presort)
	if zBgab_TestSortmsg then
		for i = #BagSort.SortedData, 1, -1 do
			local item = BagSort.SortedData[i]
			if item and item.bagInex then
				local msg = ""
				if indextable[item.moveToIndex] and BagSort.SortedData[indextable[item.moveToIndex]] then
					local toitem = BagSort.SortedData[indextable[item.moveToIndex]]
					msg = "->"..toitem.name .. "x" .. toitem.itemCount
				else
					msg = "->empty"
				end
				ChatFrame1:AddMessage("0:"..item.bagInex.."->"..item.moveToIndex.."("..item.name.."x"..item.itemCount..msg..")")
			end
		end
	end

	--items that only need move once
	for i,v in pairs(movetable) do
		if v and not Sol.table.Contains(visited, i) and 
			not Sol.table.Contains(visited, v) then
			if not movetable[v] or movetable[v] == i then
				if not CursorHasItem() then
					PickupBagItem(i)
					if CursorHasItem() then
						PickupBagItem(v)
						if not CursorHasItem() then
							table.insert(visited, v)
							table.insert(visited, i)
							if zBgab_TestSortmsg then
								ChatFrame1:AddMessage("1:"..i .."->".. v .."("..BagSort.SortedData[indextable[i]].name.."x"..BagSort.SortedData[indextable[i]].itemCount..")")
							end
							BagSort.SortedData[indextable[i]].bagIndex = v
							if movetable[v] then BagSort.SortedData[indextable[v]].bagIndex = i end
						else
							ClearCursor()
						end
					end
				else
					ClearCursor()
				end
			end
		end
	end

	--move to empty
	local letstat = {1,1}
	for i=1,6 do
		local a,b = GetBagPageLetTime(i)
		if not (a and b == -1) then
			letstat[i] = 1
		end
	end
	for i=1,6 do --findempty
		if letstat[i] then
			for j=1,30 do
				local idx,icon = GetBagItemInfo((i-1)*30+j)
				if idx and not movetable[idx] and not movetotable[idx] and icon == "" then
					table.insert(emptytable,idx)
				end
			end
		end
	end
	for index, item in pairs(BagSort.SortedData) do --move
		if  not Sol.table.Contains(visited, item.bagIndex) and #emptytable > 0 then
			if not CursorHasItem() then
				PickupBagItem(item.bagIndex)
				if CursorHasItem() then
					PickupBagItem(emptytable[1])
					if not CursorHasItem() then
						table.insert(visited, item.bagIndex)
						if zBgab_TestSortmsg then
							ChatFrame1:AddMessage("2:"..item.bagIndex.."->"..emptytable[1].."("..item.name.."x"..item.itemCount..")")
						end
						item.bagIndex = emptytable[1]
						table.remove(emptytable, 1)
					else
						ClearCursor()
					end
				end
			else
				ClearCursor()
			end
		end
	end
	
	-- then origin sort, plus cursor check
	for index, item in pairs(BagSort.SortedData) do
		if  not Sol.table.Contains(visited, item.moveToIndex) and 
			not Sol.table.Contains(visited, item.bagIndex) then
			if not CursorHasItem() then            
				PickupBagItem(item.bagIndex)
				if CursorHasItem() then   
					PickupBagItem(item.moveToIndex)
					if not CursorHasItem() then
						local displacedItem = BagSort.FindItemBzBagIndex(BagSort.SortedData, item.moveToIndex)
						
						table.insert(visited, item.moveToIndex)
						table.insert(visited, item.bagIndex)
						
						if zBgab_TestSortmsg then
							ChatFrame1:AddMessage("3:"..item.bagIndex.."->"..item.moveToIndex.."("..item.name.."x"..item.itemCount..")")
						end
					  
						if displacedItem then
							displacedItem.bagIndex = item.bagIndex
						end
						item.bagIndex = item.moveToIndex
					else
						ClearCursor()
					end
				end
			else
				ClearCursor()
			end
		end
	end

	
    if BagSort.AreAllItemsInPlace() then
        Sol.io.Print("Sorting finished")
        Sol.timers.RemoveTimer("BagSort", BagSort.timer)
        BagSort.timer = nil
        if hookedZBag then
            zBagSortFull:Enable()
        else
            BagRefreshButton:Enable()
        end

    elseif GetTime() - BagSort.SortStartTime > MAX_TIME then
        -- Timeout. Took too long
        Sol.io.Print("Could not complete bag sort")
        Sol.timers.RemoveTimer("BagSort", BagSort.timer)
        BagSort.timer = nil
        if hookedZBag then
            zBagSortFull:Enable()
        else
            BagRefreshButton:Enable()
        end
    end
end

function BagSort_OnUpdate() 
    -- Used by Sol timers
end

