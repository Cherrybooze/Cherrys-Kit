zBagQuickSellConfigVariablesLoaded = 0;
ZBAG_MAXBAG = 180;

QSItemFilterX     = 450;
QSItemFilterY     = 300;

QSItemFilterAtStore	  = { "",zBLocale.zBagQuickSellConfigFrame.AlwaysSell,zBLocale.zBagQuickSellConfigFrame.NeverSell,""};
QSItemFilterEntryType = { "",zBLocale.zBagQuickSellConfigFrame.Item,zBLocale.zBagQuickSellConfigFrame.ItemType,"",""};

if (zBagQSItemFilter == nil) then
	zBagQSItemFilter      = {};
end

QSData =
	{
	Loaded          = false,
	Name            = zBLocale.zBagQuickSellConfigFrame.QuickSellItemFilter,
	Version         = "v1.0",
	Language        = nil,
	MissingLang     = nil,
	Resizing        = false,
	ListSelect      = nil,
	BootyCloseTimer = nil,
	StringSwitch    = false,
	Fade            = {},
	GarbageTimer    = false,
	GarbageArray    = {},
	RollFrameTimers = {},
	RollresultHack  = nil,
	};

QSDefaults =
	{
	AM              = true,	-- Enabled in AddonManager?
	Enabled         = true,	-- QS enabled?
	Roll            = 3,
	LootMaster      = false,
	AutoLoot        = 3,
	AutoPass        = 1,
	AutoGreed       = 1,
	AutoLootBoss    = false,

	ItemFilterX     = 450,
	ItemFilterY     = 300,
	ItemFilter      = {},

	LootQuest       = true,
	LootMove        = false,
	LootClose       = false,

	RollQuest       = true,
	RollTooltip     = true,
	RollDelay       = 2,
	RollFrameX      = 0,
	RollFrameY      = -60,
	RollFrameD      = -64,

	DropQuest       = true,
	DropItems       = 5,
	DropAmmo        = 20,
	DropTime        = 10,
	DropAuto        = false,
	DropBugFix      = false,

	ChatOutput      = false,
	RollNewStyle    = true,
	RollResults     = {{true,true,true},{true,true,true},{true,true,true},{true,true,true},{true,true,true},{true,true,true},},
	ChatFrames      = {true,true,true,true,true,true,true,true,true,true},
	ChatColor       = {r=1,g=1,b=0.5},
	};
	

function zBagQuickSellConfig_Load()
			--yecho("in qscl");
			if (tonumber(zBag_VAR["quicksellstartslotnumber"])>0) then
				zBagQuickSellConfigFramequicksellstartslotnumber:SetText(zBag_VAR["quicksellstartslotnumber"]);
			else
				zBagQuickSellConfigFramequicksellstartslotnumber:SetText(0);
			end		
			local qsesn = tonumber(zBag_VAR["quicksellendslotnumber"]);
			if (tonumber(zBag_VAR["quicksellendslotnumber"])>0) then
				zBagQuickSellConfigFramequicksellendslotnumber:SetText(zBag_VAR["quicksellendslotnumber"]);
			else
				zBagQuickSellConfigFramequicksellendslotnumber:SetText(0);
			end		
			if (zBag_VAR["quickSellIgnoreOptions"]==1) then
				zBagQuickSellConfigFramequickSellIgnoreOptions:SetChecked(true);
			else
				zBagQuickSellConfigFramequickSellIgnoreOptions:SetChecked(false);
			end
			if (tonumber(zBag_VAR["dontQuickSellDurability"])>0) then
				zBagQuickSellConfigFramedontQuickSellDurability:SetText(zBag_VAR["dontQuickSellDurability"]);
			else
				zBagQuickSellConfigFramedontQuickSellDurability:SetText(0);
			end		
			if (tonumber(zBag_VAR["dontQuickSellLevel"])>0) then
				zBagQuickSellConfigFramedontQuickSellLevel:SetText(zBag_VAR["dontQuickSellLevel"]);
			else
				zBagQuickSellConfigFramedontQuickSellLevel:SetText(0);
			end		
			
			if (zBag_VAR["dontQuickSellRarity0"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity0:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity0:SetChecked(false);
			end			
			if (zBag_VAR["dontQuickSellRarity1"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity1:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity1:SetChecked(false);
			end		
			if (zBag_VAR["dontQuickSellRarity2"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity2:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity2:SetChecked(false);
			end					
			if (zBag_VAR["dontQuickSellRarity3"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity3:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity3:SetChecked(false);
			end		
			if (zBag_VAR["dontQuickSellRarity4"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity4:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity4:SetChecked(false);
			end		
			if (zBag_VAR["dontQuickSellRarity5"]==1) then
				zBagQuickSellConfigFramedontQuickSellRarity5:SetChecked(true);
			else
				zBagQuickSellConfigFramedontQuickSellRarity5:SetChecked(false);
			end		
			
			QSItemFilterFrame:ClearAllAnchors();
			QSItemFilterFrame:SetAnchor("TOPLEFT","CENTER",UIParent,-QSItemFilterX/2,-QSItemFilterY/2);
			QSItemFilterFrame:SetSize(QSItemFilterX,QSItemFilterY);

			
			QSItemFilterFrame_Header                      :SetText(zBLocale.zBagQuickSellConfigFrame.zBagQuickSellItemFilterFrameTitle);
			QSItemFilterFrame_Itemname_Title              :SetText(zBLocale.zBagQuickSellConfigFrame.ItemOrCategoryName);
			QSItemFilterFrame_Looting_Title               :SetText(zBLocale.zBagQuickSellConfigFrame.AtStore);
			QSItemFilterFrame_Rolling_Title               :SetText(zBLocale.zBagQuickSellConfigFrame.EntryType);			
			
			UIDropDownMenu_Initialize   (QSItemFilterFrame_Looting, QSItemFilter_LootmenuItems);
			UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Looting, 1);
			UIDropDownMenu_Initialize   (QSItemFilterFrame_Rolling, QSItemFilter_RollmenuItems);
			UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Rolling, 1);
			zBagQuickSellConfigVariablesLoaded = 1;
		
			SaveVariablesPerCharacter("zBagQSItemFilter");
			--SaveVariables("zBagQSItemFilter");
			
			zBagQuickSellConfigTitleText:SetText(zBLocale.zBagQuickSellConfigFrame.zBagQuickSellConfigTitleText);
			zBagQuickSellConfigFrameTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.Options);
			zBagQuickSellConfigFrameTxt2:SetText(zBLocale.zBagQuickSellConfigFrame.DontSellIf);
			zBagQuickSellConfigFramequicksellstartslotnumberTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.QuickSellStartSlot);
			zBagQuickSellConfigFramequicksellendslotnumberTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.QuickSellEndSlot);
			zBagQuickSellConfigFramequickSellIgnoreOptionsTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.IgnoreDontSellOptions);
			AlwaysNeverSellConfigButton:SetText(zBLocale.zBagQuickSellConfigFrame.AlwaysNeverSellConfig);
			
			zBagQuickSellConfigFramedontQuickSellDurabilityTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.DurabilityHigherThan);
			zBagQuickSellConfigFramedontQuickSellLevelTxt1:SetText(zBLocale.zBagQuickSellConfigFrame.RequiredLevelHigherThan);
			zBagQuickSellConfigFramedontQuickSellRarity0Txt1:SetText("|cfffdfdfd" .. zBLocale.zBagQuickSellConfigFrame.WhiteRarity .. "|r");
			zBagQuickSellConfigFramedontQuickSellRarity1Txt1:SetText("|cff00fd00" .. zBLocale.zBagQuickSellConfigFrame.NormalRarity .. "|r");
			zBagQuickSellConfigFramedontQuickSellRarity2Txt1:SetText("|cff0072bb" .. zBLocale.zBagQuickSellConfigFrame.GoodRarity .. "|r");
			zBagQuickSellConfigFramedontQuickSellRarity3Txt1:SetText("|cffc705f7" .. zBLocale.zBagQuickSellConfigFrame.RareRarity .. "|r");
			zBagQuickSellConfigFramedontQuickSellRarity4Txt1:SetText("|cfff58d56" .. zBLocale.zBagQuickSellConfigFrame.EpicRarity .. "|r");
			zBagQuickSellConfigFramedontQuickSellRarity5Txt1:SetText("|cffa27d50" .. zBLocale.zBagQuickSellConfigFrame.LegendaryRarity .. "|r");
end

function zBagQuickSellConfig_Save()
			if (zBagQuickSellConfigVariablesLoaded == 1) then
				--yecho("in qscs");
				if ((zBagQuickSellConfigFramequicksellstartslotnumber:GetText() ~= "") and (tonumber(zBagQuickSellConfigFramequicksellstartslotnumber:GetText()) >0)) then
					zBag_VAR["quicksellstartslotnumber"] = zBagQuickSellConfigFramequicksellstartslotnumber:GetText();
				else
					zBag_VAR["quicksellstartslotnumber"] = 0;
				end
				if ((zBagQuickSellConfigFramequicksellendslotnumber:GetText() ~= "") and (tonumber(zBagQuickSellConfigFramequicksellendslotnumber:GetText()) >0)) then
					zBag_VAR["quicksellendslotnumber"] = zBagQuickSellConfigFramequicksellendslotnumber:GetText();
				else
					zBag_VAR["quicksellendslotnumber"] = 0;
				end			
				if (zBagQuickSellConfigFramequickSellIgnoreOptions:IsChecked()) then 
					zBag_VAR["quickSellIgnoreOptions"]=1; 
				else 
					zBag_VAR["quickSellIgnoreOptions"]=0; 
				end
				if ((zBagQuickSellConfigFramedontQuickSellDurability:GetText() ~= "") and (tonumber(zBagQuickSellConfigFramedontQuickSellDurability:GetText()) >0)) then
					zBag_VAR["dontQuickSellDurability"] = zBagQuickSellConfigFramedontQuickSellDurability:GetText();
				else
					zBag_VAR["dontQuickSellDurability"] = 0;
				end
				if ((zBagQuickSellConfigFramedontQuickSellLevel:GetText() ~= "") and (tonumber(zBagQuickSellConfigFramedontQuickSellLevel:GetText()) >0)) then
					zBag_VAR["dontQuickSellLevel"] = zBagQuickSellConfigFramedontQuickSellLevel:GetText();
				else
					zBag_VAR["dontQuickSellLevel"] = 0;
				end		
				
				if (zBagQuickSellConfigFramedontQuickSellRarity0:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity0"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity0"]=0; 
				end
				if (zBagQuickSellConfigFramedontQuickSellRarity1:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity1"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity1"]=0; 
				end
				if (zBagQuickSellConfigFramedontQuickSellRarity2:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity2"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity2"]=0; 
				end
				if (zBagQuickSellConfigFramedontQuickSellRarity3:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity3"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity3"]=0; 
				end
				if (zBagQuickSellConfigFramedontQuickSellRarity4:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity4"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity4"]=0; 
				end
				if (zBagQuickSellConfigFramedontQuickSellRarity5:IsChecked()) then 
					zBag_VAR["dontQuickSellRarity5"]=1; 
				else 
					zBag_VAR["dontQuickSellRarity5"]=0; 
				end
				SaveVariablesPerCharacter("zBag_VAR");
				SaveVariables("zBag_VAR");
			end
end

function zBagQuickSellConfig_showBagSlotNumbers()
	for i=1,ZBAG_MAXBAG do	
		textSlotNumber = getglobal("zBagItem"..i.."TextSlotNumber");
		textSlotNumber:SetText("");
		textSlotNumber:SetFontSize(16*ZBAG_SCALE);
		textSlotNumber:SetText(i);
	end
end

function zBagQuickSellConfig_hideBagSlotNumbers()
	for i=1,ZBAG_MAXBAG do	
		textSlotNumber = getglobal("zBagItem"..i.."TextSlotNumber");
		textSlotNumber:SetFontSize(16*ZBAG_SCALE);
		textSlotNumber:SetText("");
	end
end

----------------------------------------------------------------------------------------------------
-------------------- QS Item Filter -------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function QSGet_SearchResults(name,type,mode)
	local SearchResults = {};

	-- check characterspecific rules first
	for i=1,table.maxn(zBagQSItemFilter) do
		if (zBagQSItemFilter[i]["Char"] == UnitName("player")) then
			if ("$"..type == zBagQSItemFilter[i]["Name"]
			or  string.match(name, "^"..string.gsub(string.gsub(zBagQSItemFilter[i]["Name"], "(%W)", "%%%1"),"%%%*",".*").."$") ~= nil) then
				table.insert(SearchResults,{zBagQSItemFilter[i]["Name"],zBagQSItemFilter[i][mode]});
			end;
		end;
	end;

	-- if no results in characterspecific, search for global rules
 	if (table.maxn(SearchResults)==0) then
		for i=1,table.maxn(zBagQSItemFilter) do
			if (zBagQSItemFilter[i]["Char"] == nil) then
				if ("$"..type == zBagQSItemFilter[i]["Name"]
				or  string.match(name, "^"..string.gsub(string.gsub(zBagQSItemFilter[i]["Name"], "(%W)", "%%%1"),"%%%*",".*").."$") ~= nil) then
					table.insert(SearchResults,{zBagQSItemFilter[i]["Name"],zBagQSItemFilter[i][mode]});
				end;
			end;
		end;
	end;

 	if (table.maxn(SearchResults)>0) then
		table.sort(SearchResults,QSSort_SearchResults);
	end;

	return SearchResults;
end;

function QSSort_SearchResults(a,b) -- Sort the Searchresults of the zBagQSItemFilter, to find the most precise match
	if     (string.find(a[1],"^%$") == nil) then return true;
	elseif (string.len(string.gsub(a[1],"\*","")) > string.len(string.gsub(b[1],"\*",""))) then return true; end;
	return false;
end;

function QSDropTab_Display(Object)
	local parent=Object:GetParent():GetName();
	local x=string.gsub(Object:GetName(),"^.*_","");
	local storeFilter = tonumber(string.sub(x,1,1));
	local entryType = tonumber(string.sub(x,2));

	local RollTextures =
		{
		[1]=zBagKit.path.."Textures/item",
		[2]=zBagKit.path.."Textures/itemtype",
		[3]=zBagKit.path.."Textures/roll-need",
		[4]=zBagKit.path.."Textures/roll-manual",
		}
	local LootTextures =
		{
		[1]=zBagKit.path.."Textures/alwayssell",
		[2]=zBagKit.path.."Textures/neversell",
		[3]=zBagKit.path.."Textures/loot-drop",
		}

	if (entryType==0) then
		getglobal(parent.."_RollIcon"):Hide();
		getglobal(parent.."_RollText"):Hide();
	else
		getglobal(parent.."_RollIcon"):Show();
		getglobal(parent.."_RollText"):Show();
		getglobal(parent.."_RollIcon"):SetFile(RollTextures[entryType]);
		getglobal(parent.."_RollText"):SetText(tostring(QSItemFilterEntryType[entryType+1]));
	end;
	if (storeFilter==0) then
		getglobal(parent.."_LootIcon"):Hide();
		getglobal(parent.."_LootText"):Hide();
	else
		getglobal(parent.."_LootIcon"):Show();
		getglobal(parent.."_LootText"):Show();
		getglobal(parent.."_LootIcon"):SetFile(LootTextures[storeFilter]);
		getglobal(parent.."_LootText"):SetText(tostring(QSItemFilterAtStore[storeFilter+1]));
	end;
	if (entryType==0 and storeFilter==0) then
		getglobal(parent.."_LootMarker"):Hide();
		getglobal(parent.."_RollMarker"):Hide();
		getglobal(parent.."_Remove"):Show();
		getglobal(parent.."_Remove"):SetText("Remove Entry");
	else
		getglobal(parent.."_Remove"):Hide();
		getglobal(parent.."_LootMarker"):Show();
		getglobal(parent.."_LootMarker"):ClearAllAnchors();
		getglobal(parent.."_LootMarker"):SetAnchor("LEFT","LEFT",getglobal(parent.."_"..storeFilter.."0"),-1,0);
		getglobal(parent.."_RollMarker"):Show();
		getglobal(parent.."_RollMarker"):ClearAllAnchors();
		getglobal(parent.."_RollMarker"):SetAnchor("TOP","TOP",getglobal(parent.."_0"..entryType..""),0,-1);
	end;

end;

function QSDropTab_Check()
	local x,y = QSDropTab:GetPos();
	local a,b = QSDropTab:GetRealSize();
	local u,v = GetCursorPos();

	local inside=false;
	if (u>x and u<(x+a) and v>y and v<(y+b)) then inside=true; end;

	if (inside==true) then QSData.DropTabCheck=true; end;
	if (inside==false and QSData.DropTabCheck==true) then QSDropTab:Hide(); end;
end;

function QSDropTab_OnShow(this)
	this.newCheck = false;
	this.id = nil;
	if (this:GetName() ~= "QS_ChatlinkDropTab") then
		-- Find Window position, where complete frame is visible
		--for n=1,table.maxn(this.Locations) do
			this:ClearAllAnchors();
			this:SetAnchor("BOTTOMRIGHT","BOTTOMRIGHT",zBagQuickSell,-5,-5);
			
			
			--this:SetAnchor(unpack(this.Locations[n]));
			--if (this:GetTop()>0 and this:GetBottom()<GetScreenHeight() and this:GetLeft()>0 and this:GetRight()<GetScreenWidth()) then
			--	break;
			--end;
		--end;
		local dragged_from = CursorItemType()
		if dragged_from~="bag" then
			this:Hide()
			return
		end
		local id = GetCursorItemInfo();
		local _, name, _ = GetGoodsItemInfo(id);
		this.itemname = name;
		this.id = id;
	end;

	getglobal(this:GetName().."_Itemname"):SetText(this.itemname);

	getglobal(this:GetName().."_LootIcon"):Hide();
	getglobal(this:GetName().."_LootText"):Hide();
	getglobal(this:GetName().."_RollIcon"):Hide();
	getglobal(this:GetName().."_RollText"):Hide();
	getglobal(this:GetName().."_LootMarker"):Hide();
	getglobal(this:GetName().."_RollMarker"):Hide();
end;

function QSDropTab_OnUpdate(this)
	local x,y = this:GetPos();
	local a,b = this:GetRealSize();
	local u,v = GetCursorPos();

	local inside=false;
	if (x<u and u<x+a and y<v and v<y+b) then inside=true; end;

	if (inside==true                         ) then this.newCheck=true; end;
	if (inside==false and this.newCheck==true) then this:Hide(); end;
end;

function QSItemFilter_Repaint()
	local a,b = QSItemFilterFrame_Filterlist:GetSize();
	local maxvalues = math.floor((b-12)/20);

	local maxvalue = QSItemFilter_GetDisplayIndex(table.maxn(zBagQSItemFilter))-maxvalues+1;

	if (maxvalue < 1) then maxvalue = 1; end;

	QSItemFilterFrame_ScrollBar:SetMinMaxValues(1,maxvalue);

	local value = QSItemFilterFrame_ScrollBar:GetValue();

	for i=1,30 do
		local index = QSItemFilter_GetRealIndex(value-1+i);

		if (index <= table.maxn(zBagQSItemFilter) and i <= maxvalues) then
			getglobal("QSItemFilterFrame_Filterlist_Item"..i):Show();
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Name"):SetText(tostring(                              zBagQSItemFilter[index].Name ));
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Loot"):SetText(tostring(QSItemFilterAtStore[zBagQSItemFilter[index].StoreAction]));
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Roll"):SetText(tostring(QSItemFilterEntryType[zBagQSItemFilter[index].EntryType]));

			if (zBagQSItemFilter[index].Char == nil) then
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Name"):SetColor(1,1,1);
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Loot"):SetColor(1,1,1);
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Roll"):SetColor(1,1,1);
			else
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Name"):SetColor(0.5,0.5,0.5);
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Loot"):SetColor(0.5,0.5,0.5);
				getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Roll"):SetColor(0.5,0.5,0.5);
			end;
		else
			getglobal("QSItemFilterFrame_Filterlist_Item"..i):Hide();
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Name"):SetText("");
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Loot"):SetText("");
			getglobal("QSItemFilterFrame_Filterlist_Item"..i.."_Roll"):SetText("");
		end;
	end;

	QSItemFilter_SetValues();
end;

function QSItemFilter_GetRealIndex(x)
	local n=0;
	for i=1,table.maxn(zBagQSItemFilter) do
		if (zBagQSItemFilter[i].Char==nil
		or  zBagQSItemFilter[i].Char==UnitName("player")) then n=n+1; end;
		if (n==x) then return i; end;
	end;
	return x;
end;

function QSItemFilter_GetDisplayIndex(x)
	local n=0;
	for i=1,x do
		if (zBagQSItemFilter[i].Char~=nil
		and zBagQSItemFilter[i].Char~=UnitName("player")) then n=n+1; end;
	end;
	return (x-n);
end;

function QSItemFilter_RowClicked(id)
	QSData.ListSelect = QSItemFilter_GetRealIndex(QSItemFilterFrame_ScrollBar:GetValue()+id-1);
	QSItemFilter_SetValues();
end;

function QSItemFilter_SearchName()
	QSData.ListSelect = nil;
	for i=1,table.maxn(zBagQSItemFilter) do
		if (zBagQSItemFilter[i]["Name"] == QSItemFilterFrame_Itemname:GetText()) then
			QSData.ListSelect = i;
			break;
		end;
	end;
end;

function QSItemFilter_CheckEntries(itemname)
	local found1=false;
	local found2=false;
	for i=1,table.maxn(zBagQSItemFilter) do
		if (zBagQSItemFilter[i]["Name"] == itemname) then
			    if (zBagQSItemFilter[i].Char==nil               ) then found1=i;
			elseif (zBagQSItemFilter[i].Char==UnitName("player")) then found2=i;
			end;
		end;
	end;
	return found1,found2;
end;

function QSItemFilter_SetValues()
	if (QSData.ListSelect == nil) then
		QSItemFilterFrame_Itemname_Text :SetColor(1,1,1);
		QSItemFilterFrame_Filterlist_Highlight:Hide();
	else
		QSItemFilterFrame_Itemname_Text :SetColor(1,0.82,0);
		QSItemFilterFrame_Itemname:SetText(zBagQSItemFilter[QSData.ListSelect]["Name"]);

		UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Looting, zBagQSItemFilter[QSData.ListSelect]["StoreAction"]);
		UIDropDownMenu_SetText      (QSItemFilterFrame_Looting, tostring(QSItemFilterAtStore[zBagQSItemFilter[QSData.ListSelect]["StoreAction"]]));

		UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Rolling, zBagQSItemFilter[QSData.ListSelect]["EntryType"]);
		UIDropDownMenu_SetText      (QSItemFilterFrame_Rolling, tostring(QSItemFilterEntryType[zBagQSItemFilter[QSData.ListSelect]["EntryType"]]));

		local a,b       = QSItemFilterFrame_Filterlist:GetSize();
		local maxvalues = math.floor((b-12)/20);
		local offset    = QSItemFilter_GetDisplayIndex(QSData.ListSelect)-QSItemFilterFrame_ScrollBar:GetValue();

		if (offset>=0 and offset<maxvalues) then
			QSItemFilterFrame_Filterlist_Highlight:ClearAllAnchors();
			QSItemFilterFrame_Filterlist_Highlight:SetAnchor("TOPLEFT", "TOPLEFT", QSItemFilterFrame_Filterlist, 5, 11+offset*20);
			QSItemFilterFrame_Filterlist_Highlight:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", QSItemFilterFrame_Filterlist, -5, 30+offset*20);
			QSItemFilterFrame_Filterlist_Highlight:Show();
		else
			QSItemFilterFrame_Filterlist_Highlight:Hide();
		end;
	end;

	if (string.len(QSItemFilterFrame_Itemname:GetText())==0 or (UIDropDownMenu_GetSelectedID(QSItemFilterFrame_Looting) == 1 and UIDropDownMenu_GetSelectedID(QSItemFilterFrame_Rolling) == 1)) then
		QSItemFilterFrame_ItemAdd:Disable();
	else
		QSItemFilterFrame_ItemAdd:Enable();
	end;

	if (QSData.ListSelect == nil) then
		QSItemFilterFrame_ItemRemove:Disable();
	else
		QSItemFilterFrame_ItemRemove:Enable();
	end;
end;

function QSItemFilter_AddItem(key,itemname,storeactionmode,entrytypemode)
	local found1,found2 = QSItemFilter_CheckEntries(itemname);
	local settings="";
	if (storeactionmode>1) then settings=settings.."\""..tostring(QSItemFilterAtStore[storeactionmode]).."\""; end;
	if (entrytypemode>1) then settings=settings.."\""..tostring(QSItemFilterEntryType[entrytypemode]).."\""; end;
	settings=string.gsub(settings,"\"\""," - ");

	if (key=="LBUTTON") then
		if (type(found1)=="number") then table.remove(zBagQSItemFilter,found1); end;
		QSAddChatMessage(string.gsub(string.gsub(tostring(zBLocale.QSStrings.Added1),"<ITEM>",itemname),"<SETTINGS>",settings));
		table.insert(zBagQSItemFilter,
			{
			Name = itemname,
			StoreAction = storeactionmode,
			EntryType = entrytypemode,
			});
	elseif (key=="RBUTTON") then
		if (type(found2)=="number") then table.remove(zBagQSItemFilter,found2); end;
		QSAddChatMessage(string.gsub(string.gsub(tostring(zBLocale.QSStrings.Added2),"<ITEM>",itemname),"<SETTINGS>",settings));
		table.insert(zBagQSItemFilter,
			{
			Name = itemname,
			StoreAction = storeactionmode,
			EntryType = entrytypemode,
			Char = UnitName("player"),
			});
	end;
	table.sort(zBagQSItemFilter,QSItemFilter_ListSort);

	found1,found2 = QSItemFilter_CheckEntries(itemname);

	    if (key=="LBUTTON") then QSData.ListSelect = found1;
	elseif (key=="RBUTTON") then QSData.ListSelect = found2;
	end;

	QSItemFilter_Repaint();
end;

function QSItemFilter_RemoveItem()
	if (QSData.ListSelect ~= nil) then
		table.remove(zBagQSItemFilter,QSData.ListSelect);
		QSData.ListSelect = nil;
		QSItemFilter_Repaint();
	end;
end;

function QSItemFilter_ListSort(a,b)
	if (string.lower(string.gsub(a.Name,"[\* ]","")) == string.lower(string.gsub(b.Name,"[\* ]",""))) then
		if (a.Char == nil and b.Char ~= nil) then return true;
		else return false; end;
	elseif (string.lower(string.gsub(a.Name,"[\* ]","")) <  string.lower(string.gsub(b.Name,"[\* ]",""))) then return true;
	else return false;
	end;
end;

function QSItemFilter_EnterName(name)
	QSItemFilterFrame:Show();
	QSItemFilterFrame_Itemname:SetText(name);
	QSItemFilter_SearchName();
	QSItemFilter_SetValues();
end;

function QSItemFilter_LootmenuItems()
	local menuitem;

	menuitem = {};
	menuitem.text = tostring(QSItemFilterAtStore[1]);
	menuitem.func = function() QSItemFilter_LootmenuChange(1); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterAtStore[2]);
	menuitem.func = function() QSItemFilter_LootmenuChange(2); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterAtStore[3]);
	menuitem.func = function() QSItemFilter_LootmenuChange(3); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterAtStore[4]);
	menuitem.func = function() QSItemFilter_LootmenuChange(4); end;
	UIDropDownMenu_AddButton(menuitem,1);
end;

function QSItemFilter_LootmenuChange(set)
	if (QSData.ListSelect ~= nil) then zBagQSItemFilter[QSData.ListSelect]["StoreAction"] = set; end;
	UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Looting, set);
	QSItemFilter_Repaint();
end;

function QSItemFilter_RollmenuItems()
	local menuitem;

	menuitem = {};
	menuitem.text = tostring(QSItemFilterEntryType[1]);
	menuitem.func = function() QSItemFilter_RollmenuChange(1); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterEntryType[2]);
	menuitem.func = function() QSItemFilter_RollmenuChange(2); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterEntryType[3]);
	menuitem.func = function() QSItemFilter_RollmenuChange(3); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterEntryType[4]);
	menuitem.func = function() QSItemFilter_RollmenuChange(4); end;
	UIDropDownMenu_AddButton(menuitem,1);

	menuitem = {};
	menuitem.text = tostring(QSItemFilterEntryType[5]);
	menuitem.func = function() QSItemFilter_RollmenuChange(5); end;
	UIDropDownMenu_AddButton(menuitem,1);
end;

function QSItemFilter_RollmenuChange(set)
	if (QSData.ListSelect ~= nil) then zBagQSItemFilter[QSData.ListSelect]["EntryType"] = set; end;
	UIDropDownMenu_SetSelectedID(QSItemFilterFrame_Rolling, set);
	QSItemFilter_Repaint();
end;

function QSItemFilter_ReceiveDrag(this)
	if ( CursorItemType() == "bag" ) then
		local id = GetCursorItemInfo();
		local icon, name, count = GetGoodsItemInfo(id);
		QSItemFilter_EnterName(name);
		QSItemFilterFrame_Itemname:ClearFocus();
		PickupBagItem(id);
	end
end;

function QSDropTab_Receive(key,this)
	if ( this:GetParent().itemname~=nil ) then
		local x=string.gsub(this:GetName(),"^.*_","");
		local storeFilter = tonumber(string.sub(x,1,1))+1;
		local entryType = tonumber(string.sub(x,2))+1;

		if (storeFilter==1 and entryType==1) then
			local found1,found2 = QSItemFilter_CheckEntries(this:GetParent().itemname);

			if (key=="LBUTTON") then
				if (found1~=false) then
					table.remove(zBagQSItemFilter,found1);
					if (found1 == QSData.ListSelect) then
						QSData.ListSelect = nil;
					end;
					QSAddChatMessage(string.gsub(tostring(zBLocale.QSStrings.Removed1),"<ITEM>",this:GetParent().itemname));
				else
					QSAddChatMessage(string.gsub(tostring(zBLocale.QSStrings.NotFound1),"<ITEM>",this:GetParent().itemname));
				end;
			elseif (key=="RBUTTON") then
				if (found2~=false) then
					table.remove(zBagQSItemFilter,found2);
					if (found2 == QSData.ListSelect) then
						QSData.ListSelect = nil;
					end;
					QSAddChatMessage(string.gsub(tostring(zBLocale.QSStrings.Removed2),"<ITEM>",this:GetParent().itemname));
				else
					QSAddChatMessage(string.gsub(tostring(zBLocale.QSStrings.NotFound2),"<ITEM>",this:GetParent().itemname));
				end;
			end;

			QSItemFilter_Repaint();
		else
			if entryType==3 then --request is to add an itemType to the registery, figure out itemType
				for i = 1, 180 do
					local bagIndex, icon, name, itemCount, locked, itemQuality = GetBagItemInfo(i);
					if (name == this:GetParent().itemname) then
						--yecho("match:" .. name);
						thisItemData = BagSort.GetBagItemData(i);
						--yecho("matchType:"..thisItemData.type);
						break;
					end
				end	
				if (thisItemData and thisItemData.type) then
					QSItemFilter_AddItem(key,thisItemData.type,storeFilter,entryType);
				else
					yecho(zBLocale.zBagQuickSellConfigFrame.CannotDetermineItemType);
				end
			else
				QSItemFilter_AddItem(key,this:GetParent().itemname,storeFilter,entryType);
			end
		end;

		this:GetParent():Hide();

		if (this:GetParent().id ~= nil) then
			PickupBagItem(this:GetParent().id);
		end;
	end
end;

function QSItemFilter_Scroll(delta)
	    if (delta>0) then QSItemFilterFrame_ScrollBar:SetValue(QSItemFilterFrame_ScrollBar:GetValue()-1);
	elseif (delta<0) then QSItemFilterFrame_ScrollBar:SetValue(QSItemFilterFrame_ScrollBar:GetValue()+1); end;
end;


function QSAddChatMessage(message)
	if (message~="nil") then
		for n=1,10 do
			if (QSDefaults.ChatFrames[n]) then
				getglobal("ChatFrame"..n):AddMessage("|HQuicksell:0|h["..QSData.Name.."]|h: "..message,QSDefaults.ChatColor.r,QSDefaults.ChatColor.g,QSDefaults.ChatColor.b);
			end;
		end;
	end;
end;


function QSTooltip(Object)
	GameTooltip:SetOwner(Object,"ANCHOR_BOTTOM",0,0);

	if (zBLocale.QSStrings["Tooltip_"..Object:GetName()]~=nil) then
		GameTooltip:SetText("|cffFFFE80"..zBLocale.QSStrings["Tooltip_"..Object:GetName()][1].."|r");
		GameTooltip:AddLine(              zBLocale.QSStrings["Tooltip_"..Object:GetName()][2]      );

		if (table.maxn(zBLocale.QSStrings["Tooltip_"..Object:GetName()])>2) then
			if (IsShiftKeyDown()) then
				for n=3,table.maxn(zBLocale.QSStrings["Tooltip_"..Object:GetName()]) do
					if (type(zBLocale.QSStrings["Tooltip_"..Object:GetName()][n])=="table")
					then GameTooltip:AddDoubleLine(zBLocale.QSStrings["Tooltip_"..Object:GetName()][n][1],zBLocale.QSStrings["Tooltip_"..Object:GetName()][n][2]);
					else GameTooltip:AddLine(zBLocale.QSStrings["Tooltip_"..Object:GetName()][n]); end;
				end;
			else
				GameTooltip:AddLine(zBLocale.QSStrings["Tooltip_LongText"], 0, 0.75, 0.95);
			end;
		end;
	end;
end;