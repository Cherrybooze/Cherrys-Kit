-- author adisadicul
ZBAG_ROW_ITEMS = 10;
ZBAG_SCALE = 0.99;
ZBAG_MAXBAG = 180;
ZBAG_MAXEQ = 21;
ZBAG_SHOWEQ = 1;
ZBAG_VERSION = "5.07";
ZBAG_SORTSTARTED=0;
ZBAG_SLOTS = {
"Ring0Slot",
"Ring1Slot",
"Earring0Slot",
"Earring1Slot",
"NecklaceSlot",
"Talisman0Slot",
"Talisman1Slot",
"Talisman2Slot",
"HeadSlot",
"ChestSlot",
"WaistSlot",
"LegsSlot",
"ShoulderSlot",
"HandsSlot",
"FeetSlot",
"BackSlot",
"AdornmentSlot",
"MainHandSlot",
"SecondaryHandSlot",
"RangedSlot",
"AmmoSlot", --21
};
-- zBag_VAR = {};

--yecho("zBag_GetCmd");
function zBag_GetCmd(msg)
    if msg then
        local a,b=string.find(msg, "(%s+)");
        if a then
            return string.sub(msg, 1, a-1), string.sub(msg, b+1);
        else	
            return msg;
        end
    end
end

function zBag_SetItemShop()
	if (zBag_VAR["showitemshop"]==0) then
	-- hide item shop related stuff
		zBagRent3:Hide();
		zBagRent4:Hide();
		zBagRent5:Hide();
		zBagRent6:Hide();
		--zBagShop:Hide();
	else
		zBagRent3:Show();
		zBagRent4:Show();
		zBagRent5:Show();
		zBagRent6:Show();
		--zBagShop:Show();
	end
end

function zBag_Resize(this)
local item;
local bagtab = 1;
local showtab = 1;
local visibletab=1;
local crx=1; local cry=1; local cr=1;
local startrowitem=zBagItem1; local lastitem=zBagItem1;
local additionalTopOffset = 0;
local additionalBottomOffset = 0;

-- yecho("scale:" .. ZBAG_SCALE);

for i = 1, ZBAG_MAXBAG do
	if (i==1) then
		local zBagSliderValue = zBagRowSlider:GetValue();
		if (zBagSliderValue == 0) then
			zBagSliderValue = zBag_VAR["rowitems"];
		end
		if (zBagSliderValue == nil) then
			zBagSliderValue = 10;
		end
			--yecho("zBSV: " .. zBagSliderValue);
		
		if ((zBagSliderValue == 2) and (zBag_VAR["showitemshop"] == 1))  then 
			---five rows at the top
			additionalTopOffset=118*ZBAG_SCALE;
		
		elseif ((zBagSliderValue < 4) and (zBag_VAR["showitemshop"] == 1)) then 
			-- four rows at the top
			additionalTopOffset=94*ZBAG_SCALE;
			if (showitemshop == 0) then
				additionaltopOffset = additionalTopOffset-24*ZBAG_SCALE;
			end
		elseif ( ((zBagSliderValue < 7) and (zBag_VAR["showitemshop"] == 1)) or (zBagSliderValue < 4)) then
			-- three rows at the top
			additionalTopOffset=70*ZBAG_SCALE;
			if (showitemshop == 0) then
				additionaltopOffset = additionalTopOffset-24*ZBAG_SCALE;
			end
		elseif ( ((zBagSliderValue < 10) and (zBag_VAR["showitemshop"] == 1)) or (zBagSliderValue < 6)) then
			-- two rows at the top
			additionalTopOffset=46*ZBAG_SCALE;
			if (showitemshop == 0) then
				additionaltopOffset = additionalTopOffset-24*ZBAG_SCALE;
			end
		else
			-- one rows at the top
			additionalTopOffset=22*ZBAG_SCALE;
		end
		
		zBagBackgroundCloseButton:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagBackgroundCloseButton:ClearAllAnchors();
		zBagBackgroundCloseButton:SetAnchor("TOPRIGHT","TOPRIGHT",zBagBackground,-5,5);	
		
		zBagInspectBank:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagInspectBank:GetNormalTexture():SetSize(34*ZBAG_SCALE,34*ZBAG_SCALE);
		zBagInspectBank:GetPushedTexture():SetSize(34*ZBAG_SCALE,34*ZBAG_SCALE);
		zBagInspectBank:GetHighlightTexture():SetSize(34*ZBAG_SCALE,34*ZBAG_SCALE);
		zBagInspectBank:ClearAllAnchors();
		zBagInspectBank:SetAnchor("TOPRIGHT","TOPLEFT",zBagBackgroundCloseButton,0,0);	
		
		zBagConfig:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagConfig:GetNormalTexture():SetSize(46*ZBAG_SCALE,46*ZBAG_SCALE);
		zBagConfig:GetPushedTexture():SetSize(46*ZBAG_SCALE,46*ZBAG_SCALE);
		zBagConfig:GetHighlightTexture():SetSize(46*ZBAG_SCALE,46*ZBAG_SCALE);
		--must change text before SetFontSize takes effect
		zBagConfigzBText:SetText("z");
		zBagConfigzBText:SetText(zBLocale.zBagStrings.zBagConfigzBText2Letters);
		zBagConfigzBText:SetFontSize(14*ZBAG_SCALE);
		zBagConfig:ClearAllAnchors();
		zBagConfig:SetAnchor("TOPRIGHT","TOPLEFT",zBagInspectBank,0,0);	
		
		
		zBagShop:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagShop:ClearAllAnchors();
		if (zBagSliderValue < 4) then
			zBagShop:SetAnchor("TOPLEFT","TOPLEFT",zBagBackground,15,5+24*ZBAG_SCALE);
		else
			zBagShop:SetAnchor("TOPLEFT","TOPLEFT",zBagBackground,15,5);	
		end
		
		
		zBagPartner:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagPartner:ClearAllAnchors();
		zBagPartner:SetAnchor("TOPLEFT","TOPRIGHT",zBagShop,1,0);	
		
		zBagTransmutor:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagTransmutor:ClearAllAnchors();
		if (zBagSliderValue == 2) then
			zBagTransmutor:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagShop,0,2);	
		else
			zBagTransmutor:SetAnchor("TOPLEFT","TOPRIGHT",zBagPartner,1,0);	
		end
		
		zBagGarbage:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagGarbage:ClearAllAnchors();
		if (zBagSliderValue == 4) then
			zBagGarbage:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagShop,0,2);	
		else 
			zBagGarbage:SetAnchor("TOPLEFT","TOPRIGHT",zBagTransmutor,1,0);	
		end
		
		
		
		zBagSort:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagSort:ClearAllAnchors();
		if (zBagSliderValue < 7 and zBagSliderValue ~= 4) then
			zBagSort:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagShop,0,2);	
		else
			zBagSort:SetAnchor("TOPLEFT","TOPRIGHT",zBagGarbage,1,0);	
		end
		
		zBagSortFull:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagSortFull:ClearAllAnchors();
		
		zBagSortFullSFText:SetText("F");
		zBagSortFullSFText:SetText(zBLocale.zBagStrings.zBagSortFullSFText4Letters);
		zBagSortFullSFText:SetFontSize(14*ZBAG_SCALE);
		
		zBagSortFull:SetAnchor("TOPLEFT","TOPRIGHT",zBagSort,1,0);			

		zBagQuickSell:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagQuickSell:ClearAllAnchors();
		
		zBagQuickSellQSText:SetText("Q");
		zBagQuickSellQSText:SetText(zBLocale.zBagStrings.zBagQuickSellQSText2Letters);
		zBagQuickSellQSText:SetFontSize(14*ZBAG_SCALE);
		
		zBagQuickSell:SetAnchor("TOPLEFT","TOPRIGHT",zBagSortFull,1,0);			
		
		zBagRent3:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagRent3:ClearAllAnchors();
		if (zBagSliderValue == 4) then
			zBagRent3:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagGarbage,0,1);	
		elseif (zBagSliderValue < 7) then
			zBagRent3:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagSort,0,1);	
		elseif (zBagSliderValue < 10) then
			zBagRent3:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagShop,0,1);	
		else  
			zBagRent3:SetAnchor("TOPLEFT","TOPRIGHT",zBagQuickSell,1,0);	
		end
		
		zBagRent4:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagRent4:ClearAllAnchors();
		zBagRent4:SetAnchor("TOPLEFT","TOPRIGHT",zBagRent3,1,0);	
		
		zBagRent5:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagRent5:ClearAllAnchors();
		
		--to do
		-- test scenarios 1) all slider values 2) rent buttons enabled/disabled 3) different zoom factors
		
		if (zBagSliderValue == 2) then
			zBagRent5:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagRent3,0,2);	
		else 
			zBagRent5:SetAnchor("TOPLEFT","TOPRIGHT",zBagRent4,1,0);	
		end
		zBagRent6:SetSize(24*ZBAG_SCALE,24*ZBAG_SCALE);
		zBagRent6:ClearAllAnchors();
		zBagRent6:SetAnchor("TOPLEFT","TOPRIGHT",zBagRent5,1,0);	
		
		
		
		if (zBagBackground:GetWidth() < 220) then
			additionalBottomOffset = 42;
			
			zBagBackgroundFrameAccountMoney:ClearAllAnchors();
			zBagBackgroundFrameAccountMoney:SetAnchor("BOTTOMRIGHT","BOTTOMRIGHT",zBagBackground,-16,-40);
			
			zBagBackgroundFrameCostBackMoney:ClearAllAnchors();
			zBagBackgroundFrameCostBackMoney:SetAnchor("TOPRIGHT","BOTTOMRIGHT",zBagBackgroundFrameAccountMoney,0,0);					
							
			zBagBackgroundFrameMoney:ClearAllAnchors();
			zBagBackgroundFrameMoney:SetAnchor("TOPRIGHT","BOTTOMRIGHT",zBagBackgroundFrameCostBackMoney,0,0);	
		else 
			additionalBottomOffset = 10;
			
			zBagBackgroundFrameAccountMoney:ClearAllAnchors();
			zBagBackgroundFrameAccountMoney:SetAnchor("BOTTOMRIGHT","BOTTOMRIGHT",zBagBackground,-160,-8);
			
			zBagBackgroundFrameCostBackMoney:ClearAllAnchors();
			zBagBackgroundFrameCostBackMoney:SetAnchor("BOTTOMRIGHT","BOTTOMRIGHT",zBagBackground,-100,-8);					
							
			zBagBackgroundFrameMoney:ClearAllAnchors();
			zBagBackgroundFrameMoney:SetAnchor("BOTTOMRIGHT","BOTTOMRIGHT",zBagBackground,-16,-8);	
		end
							
		--check if BagSearch addon should be used
		if (not zBagKit.IsOneBag()) then
			zBagKit.PlaceSearchBoxes();
		elseif ((zBag_VAR["usebagsearch"] == 1) and zBagKit.IsOn())then
			--yecho("Use Bag Search Enabled");
			BagSearchInstalled = 1;
			BagSearchEditBox:Show();
			BankSearchEditBox:Show();
			BagSearchEditBox:ClearAllAnchors();
			BagSearchEditBox:SetAnchor("BOTTOMLEFT","BOTTOMLEFT",zBagBackground,-5,-5);	
			BagSearchEditBox:SetFrameStrata( "LOW" );
			BankSearchEditBox:ClearAllAnchors();
			BankSearchEditBox:SetAnchor("BOTTOMLEFT","BOTTOMLEFT",zBagBBackground,-5,-5);	
			BankSearchEditBox:SetFrameStrata( "LOW" );
		else
			--yecho("Use Bag Search Disabled");
			BagSearchInstalled = 0;
			BagSearchEditBox:Hide();
			BankSearchEditBox:Hide();
		end
		
		
	end

	if ( (i-1)% 30 == 0 ) then
-- backpack
			bagtab = (i-1)/30+1;
			showtab=0;
			if (zBagKit.ShowBagTab(bagtab)) then showtab=1; end -- Cherry's Kit: also the Auto tick
			if (showtab==1) then
				visibletab=visibletab+1;
			end
		end
  --yecho("i:" .. i .. " cr:" .. cr .. " bagtab:" .. bagtab .. " showtab:" .. showtab);
	
	item = getglobal("zBagItem"..i);
	item.index=i;
	item:ClearAllAnchors();
	if (showtab==1) then
		if (crx-1 == ZBAG_ROW_ITEMS) then --new line when enough items on row
			crx=1; cry=cry+1;
		end
		zBagItem_Resize(item,32*ZBAG_SCALE,32*ZBAG_SCALE);
		local itemhighlight=getglobal(item:GetName().."TabColor2");
		itemhighlight:SetSize(32*ZBAG_SCALE*2.2,32*ZBAG_SCALE*2.2);
		item:SetAnchor("TOPLEFT","TOPLEFT",zBagBackground,(crx-1)*35*ZBAG_SCALE+14,(cry-1)*35*ZBAG_SCALE+15+additionalTopOffset);
		
		if (zBag_VAR["highlighteven"]==1 and visibletab%2==1) then
			itemhighlight:SetColor(0.7,0.7,0,0.5);
			
			itemhighlight:Show();
		else
			itemhighlight:Hide();
		end
		item.display=true;
		item:Show();
		lastitem=item;
		crx=crx+1;
		
		
		
	else
		item.display=false;
		item:SetAnchor("TOPLEFT","TOPLEFT","UIParent",10,10);
		item:Hide();
	end
end

-- Cherry's Kit: always start the equipment on the row after the bags (a full last row used to
-- leave an empty row before the equipment).
crx=1;

for i = 1, ZBAG_MAXEQ do
	item = getglobal("zEqItem"..i);
	item:ClearAllAnchors();
	if (ZBAG_SHOWEQ == 1) then
		if (crx-1 == ZBAG_ROW_ITEMS) then --new line when enough items on row
			crx=1; cry=cry+1;
		end
		zBagItem_Resize(item,32*ZBAG_SCALE,32*ZBAG_SCALE);
		item:SetAnchor("TOPLEFT","TOPLEFT",zBagBackground,(crx-1)*35*ZBAG_SCALE+14,(cry)*35*ZBAG_SCALE+20+additionalTopOffset);
		item.display=true;
		lastitem=item;
		crx=crx+1;
		item:Show();
	else
		item.display=false;
		item:SetAnchor("TOPLEFT","TOPLEFT","UIParent",10,10);
		item:Hide();
	end
end

local bagbk = getglobal("zBagBackground");
local padd=10;
if (ZBAG_SHOWEQ==0) then
	padd=0;
end
if (ZBAG_SHOWEQ == 1) then
	cry=cry+1;
end

if (zBag_VAR["showback"]==1) then
	bagbk:Show();
	bagbk:SetAlpha(1);
	bagbk:SetSize(ZBAG_ROW_ITEMS*35*ZBAG_SCALE+25,cry*35*ZBAG_SCALE+27+padd+additionalTopOffset+additionalBottomOffset);
else
	bagbk:SetSize(ZBAG_ROW_ITEMS*35*ZBAG_SCALE+25,cry*35*ZBAG_SCALE+27+padd+additionalTopOffset+additionalBottomOffset);
	bagbk:Show();
	bagbk:SetAlpha(0);
end

end

--yecho("zBag_Update");
function zBag_Update()

	if (not zBag:IsVisible()) then
		return;
	end
	local item,index,texture,name,itemCount,locked;
	local count=0;
	local bagtab = 1;
	local IsRented, RentTime;
	local r, g, b;
	for i=1,ZBAG_MAXBAG do	
		if ( (i-1)% 30 == 0 ) then
			bagtab = (i-1)/30+1;
			IsRented, RentTime = GetBagPageLetTime(bagtab);
		end
		item = getglobal("zBagItem"..i);
		if (item.display==true) then
		item:SetID(i);
		
		--in interface\worldxml\bagframe.lua, line 157, they write
		--index, texture, name, itemCount, locked, quality = GetBagItemInfo(i + offset); 
		index,texture,name,itemCount,locked,itemquality = GetBagItemInfo(i);
		--copy from yBagTmpl.lua, line 130 and change it
		if (itemquality) then
			local qualityTexture = getglobal(item:GetName().."TabColor");
			--yecho("highlightitemquality:");
			if (itemquality>0 and zBag_VAR["highlightitemquality"]==1) then
				qualityTexture:Show();
				r, g, b = GetItemQualityColor(itemquality);
				--yecho (name .. " iq" .. itemquality .. " r:" .. r .. " g:" .. g .. " b:" .. b);
				if (itemquality >= 2) then
					qualityTexture:SetAlpha( 1 );
				else 
					qualityTexture:SetAlpha( 0.5 );
				end 
				qualityTexture:SetColor(r, g, b);
			else
				qualityTexture:Hide();
			end
		end
		
		--code for DailyNotes tie
		if ZBag_IsDailyItem(index) then
			local qualityTexture = getglobal(item:GetName().."TabColor")
			qualityTexture:Show()
			qualityTexture:SetAlpha(1)
			qualityTexture:SetColor(0.1, 1, 0.9)
		end

		
		if (IsRented and RentTime==-1) then
			item:Disable();
			getglobal(item:GetName().."Disabled"):Show();
		else
			item:Enable();
			getglobal(item:GetName().."Disabled"):Hide();
		end
		
		if (index<0) then
			item:Hide();
			
		else
			item.index = index;
			item:Show();
			if (string.len(name)>0) then
				count=count+1;
			end
			SetItemButtonTexture(item,texture);
			SetItemButtonCount(item,0);
			textWackyBag = getglobal("zBagItem"..i.."TextWackyBag");
			textItemCount = getglobal("zBagItem"..i.."TextItemCount");
			
			--yecho("dwbi:" .. zBag_VAR["displayWackyBagIndex"]);
			if (zBag_VAR["displayWackyBagIndex"] == 1) then
				textWackyBag:Show();
			else
				textWackyBag:Hide();
			end			
			
			textWackyBag:SetText("");
			textItemCount:SetText("");
			if (itemCount > 1) then
				textItemCount:SetText(itemCount);
			else
				textItemCount:SetText("");
			end
			if (string.len(name)>0) then
				textWackyBag:SetText(index);
			else
				textWackyBag:SetText("");
			end
			textWackyBag:SetFontSize(16*ZBAG_SCALE);
			textItemCount:SetFontSize(16*ZBAG_SCALE);
			
			SetItemButtonLuminance(item,locked);
			if (zBag_VAR["slotnumbers"] == 1) then
				zBagKit.Label(item, i, 13*ZBAG_SCALE);
			else
				zBagKit.Label(item, nil);
			end
			if (GameTooltip:IsVisible() and GameTooltip:IsOwned(item)) then
				GameTooltip:SetBagItem(item.index);
			end
			local duration,remaining = GetBagItemCooldown(item.index);
			CooldownFrame_SetTime(getglobal(item:GetName().."Cooldown"),duration,remaining);
		end
		else
			item:Hide();
		end
	end
	
	AskNumberFrame:Hide();

for i = 1, ZBAG_MAXEQ do
	item = getglobal("zEqItem"..i);
	zEqItem_Update(item);
end
-- the game bag no longer updates itself, so keep the search highlight current (Cherry's Kit)
if (BagSearchInstalled == 1 and AttemptBagSearch) then
	AttemptBagSearch("Bag");
end
end

--yecho("zBag_OnLoad");
function zBag_OnLoad(this)
	this:RegisterEvent("PLAYER_BAG_CHANGED");
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("VARIABLES_LOADED");
--	zBag_Resize(this);
-- unregister events for default bag: done in zBagKit.Freeze, and only for the one bag (Cherry's Kit)
end

--yecho("zBag_OnEvent");
function zBag_OnEvent(this,event,arg1,arg2)
	if (event=="PLAYER_BAG_CHANGED") then
		if (this:IsVisible()) then
			zBag_Update();
		end
	elseif (event=="VARIABLES_LOADED") then
		if(not zBag_VAR)then
			zBag_VAR={};
		end
		zBagKit.Freeze();
		if (not zBag_VAR["fx"] and not zBag_VAR["fy"]) then
			zBag_VAR["fx"] = 116;
			zBag_VAR["fy"] = 15;
		end
		if (not zBag_VAR["bx"] and not zBag_VAR["by"]) then
			zBag_VAR["bx"] = 1;
			zBag_VAR["by"] = 1;
		end
		if (zBag_VAR["bx"] and zBag_VAR["by"])then
			zBagBackground:ClearAllAnchors();
			local scale = GetUIScale();
			zBagBackground:SetAnchor("TOPLEFT","TOPLEFT","zBag",zBag_VAR["bx"]/scale,zBag_VAR["by"]/scale);
		end
		if (not zBag_VAR["bbx"] and not zBag_VAR["bby"]) then
			zBag_VAR["bbx"] = 1;
			zBag_VAR["bby"] = 1;
		end
		if (zBag_VAR["bbx"] and zBag_VAR["bby"])then
			zBagBBackground:ClearAllAnchors();
			local scale = GetUIScale();
			zBagBBackground:SetAnchor("TOPLEFT","TOPLEFT","zBagB",zBag_VAR["bbx"]/scale,zBag_VAR["bby"]/scale);
		end
		if (zBag_VAR["rowitems"]) then 
			ZBAG_ROW_ITEMS=zBag_VAR["rowitems"];
		end
		if (not zBag_VAR["bag3"]) then 
			zBag_VAR["bag3"]=1;
		end
		if (not zBag_VAR["bag4"]) then 
			zBag_VAR["bag4"]=0;
		end
		if (not zBag_VAR["bag5"]) then 
			zBag_VAR["bag5"]=0;
		end
		if (not zBag_VAR["bag6"]) then 
			zBag_VAR["bag6"]=0;
		end
		if (not zBag_VAR["bank2"]) then 
			zBag_VAR["bank2"]=1;
		end
		if (not zBag_VAR["bank3"]) then 
			zBag_VAR["bank3"]=0;
		end
		if (not zBag_VAR["bank4"]) then 
			zBag_VAR["bank4"]=0;
		end
		if (not zBag_VAR["bank5"]) then 
			zBag_VAR["bank5"]=0;
		end
		if (not zBag_VAR["bank6"]) then 
			zBag_VAR["bank6"]=1;
		end		
		if (not zBag_VAR["alwaysshow"]) then 
			zBag_VAR["alwaysshow"]=0;
		end
		if (not zBag_VAR["showeq"]) then 
			zBag_VAR["showeq"]=1;
		end
		if (not zBag_VAR["showback"]) then 
			zBag_VAR["showback"]=1;
		end
		if (not zBag_VAR["scale"]) then 
			zBag_VAR["scale"]=1;
		end
		if (not zBag_VAR["highlighteven"]) then 
			zBag_VAR["highlighteven"]=1;
		end
		if (not zBag_VAR["highlightitemquality"]) then 
			zBag_VAR["highlightitemquality"]=1;
		end
		if (zBag_VAR["scale"]) then 
			ZBAG_SCALE=zBag_VAR["scale"];
		end
		if (zBag_VAR["showeq"]) then 
			ZBAG_SHOWEQ=zBag_VAR["showeq"];
		end
		if (not zBag_VAR["bankreplace"]) then 
			zBag_VAR["bankreplace"]=1;
		end
		if (not zBag_VAR["showitemshop"]) then 
			zBag_VAR["showitemshop"]=1;
		end
		if (not zBag_VAR["quicksellstartslotnumber"]) then
			zBag_VAR["quicksellstartslotnumber"]=0;
		end
		if (not zBag_VAR["quicksellendslotnumber"]) then
			zBag_VAR["quicksellendslotnumber"]=180;
		end

		if (not zBag_VAR["quickSellIgnoreOptions"]) then
			zBag_VAR["quickSellIgnoreOptions"]=0;
		end		
		if (not zBag_VAR["dontQuickSellDurability"]) then
			zBag_VAR["dontQuickSellDurability"]=0;
		end
		if (not zBag_VAR["dontQuickSellLevel"]) then
			zBag_VAR["dontQuickSellLevel"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity0"]) then
			zBag_VAR["dontQuickSellRarity0"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity1"]) then
			zBag_VAR["dontQuickSellRarity1"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity2"]) then
			zBag_VAR["dontQuickSellRarity2"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity3"]) then
			zBag_VAR["dontQuickSellRarity3"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity4"]) then
			zBag_VAR["dontQuickSellRarity4"]=0;
		end
		if (not zBag_VAR["dontQuickSellRarity5"]) then
			zBag_VAR["dontQuickSellRarity5"]=0;
		end		
		if (not zBag_VAR["displayWackyBagIndex"]) then
			zBag_VAR["displayWackyBagIndex"]=0;
		end			
		if (not zBag_VAR["displayDebugMessages"]) then 
			zBag_VAR["displayDebugMessages"]=0;
		end		
		zBag_SetItemShop();
		--save both per character, and generically so alts will have a preset
		SaveVariablesPerCharacter("zBag_VAR");
		SaveVariables("zBag_VAR");
		zBag_Resize(this);
		if (this:IsVisible()) then
			zBag_Update();
		end
		getglobal("zBagVersionText"):SetText("v. "..ZBAG_VERSION);
		yecho("zBag v".. ZBAG_VERSION .. " " .. zBLocale.zBagStrings.zBagLoaded);

	end	
end

--yecho("zBag_OnShow");
function zBag_OnShow(this)
	if (this:IsVisible()) then
		if (BankFrame:IsVisible()) then ZBAG_BANKINSPECT=0 else ZBAG_BANKINSPECT=1 end
		zBag_Resize(this);
		zBag_Update();
	end
end

--yecho("zBag_OnHide");
function zBag_OnHide(this)
	HideUIPanel(AskNumberFrame);
	if (zBagKit.IsOneBag() and BankFrame:IsVisible()) then
		HideUIPanel(BankFrame);
	end
end

--yecho("zBag_Switch");
function zBag_Switch(a, msg)
--yecho("cmd ".. msg);
    if (type(a) == "string") then msg = a; end
    local cmd,subcmd = zBag_GetCmd(msg);
    if (cmd=="probe") then
        zBagKit.Probe(); -- Cherry's Kit: checks for the in-game test
    elseif (cmd=="all") then
        zBagKit.ToggleAllBags(); -- Cherry's Kit: All bags window, for macros
    elseif (cmd=="help")then
        yecho("zBag v. " .. ZBAG_VERSION .. " commands:");
        yecho("|cffFFFF00/zb help|r this one ;) and that's it");
        yecho("|cffFFFF00/zb all|r open or close the All bags window (works in macros)");
        yecho("|cffFFFF00/zb probe|r Cherry's Kit checks (open your bag, and the bank if you can, first)");
        yecho("Project page: |cffFFFF00http://rom.curseforge.com/projects/zbag/|r");
    end
end

-- sorting functions
function zBag_SwapItems(item1,item2)
if (item1 and item2) then
	local index1,file1,name1,itemCount1,locked1,invalid1 = GetBagItemInfo(item1:GetID());
	local index2,file2,name2,itemCount2,locked2,invalid2 = GetBagItemInfo(item2:GetID());
	if (locked1 or locked2) then -- don't swap locked slots
		return
	end
	if (itemCount1<1 and itemCount2<1) then -- two empty slots. nothing to swap
		return
	end
	if (itemCount1>=1) then --swap starting with an existing item
		PickupBagItem(index1);
		PickupBagItem(index2);
	else
		PickupBagItem(index2);
		PickupBagItem(index1);
	end
end
end

function zBag_SwapItemsIdx(index1,index2)
if (index1 and index2) then
	local item1,item2 = getglobal("zBagItem"..index1), getglobal("zBagItem"..index2);
	zBag_SwapItems(item1,item2);
end
end

function zBag_FindLastItemPos(endidx,min)
local found=false;
local cridx=endidx;
while (found==false and cridx>=min) do
	local index,file,name,itemCount,locked,invalid = GetBagItemInfo(getglobal("zBagItem"..cridx):GetID());
	 if (locked or itemCount<1) or not zBag_CheckBagButtonLet(getglobal("zBagItem"..cridx):GetID()) then  -- emptyslot (going down)
		cridx=cridx-1;
	else
		found=true;
	end
end --while
if (found==true) then
	return cridx;
else
	return 0;
end --if
end

function zBag_FindNextGap(startidx,max)
local found=false;
local cridx=startidx+1;
while (found==false and cridx<=max) do
    local index,file,name,itemCount,locked,invalid = GetBagItemInfo(getglobal("zBagItem"..cridx):GetID());
    if (itemCount>=1) or not zBag_CheckBagButtonLet(getglobal("zBagItem"..cridx):GetID()) then -- full slot (going next)
        cridx=cridx+1;
    else
        found=true;
    end
end --while
if (found==true) then
    return cridx;
else
    return 9999;
end --if
end

function zBag_CheckBagButtonLet(btn)
    if not btn or type(btn) ~= "number" or btn < 1 or btn > 180 then return end
    if btn >= 1 and btn <= 60 then return true end
    local page = math.floor((btn-1)/30) + 1
    local a,b = GetBagPageLetTime(page)
    if not (a and b == -1) then
        return true
    end
end

function zBag_CompactItems() -- fill free slots
local startidx,endidx = 0,ZBAG_MAXBAG;
while (startidx<endidx) do
	endidx=zBag_FindLastItemPos(endidx,1);
	startidx=zBag_FindNextGap(startidx,endidx);
	if (startidx<endidx) then
		zBag_SwapItemsIdx(startidx,endidx);
	end
end--while
--yecho("gap:"..startidx.." last:"..endidx);
end

function zBag_Compare(idx1,idx2) -- returns 0 if equal, 1 if item[idx1]>item[idx2], -1 if <
local it1,it2=getglobal("zBagItem"..idx1),getglobal("zBagItem"..idx2);
local index1,file1,name1,itemCount1,locked1,invalid1 = GetBagItemInfo(it1:GetID());
local index2,file2,name2,itemCount2,locked2,invalid2 = GetBagItemInfo(it2:GetID());
if (name1==name2) then
	return 0;
elseif (name1>name2) then
	return 1;
else
	return -1;
end
end

function zBag_FindLockedItem(count)
local lidx=0;
for i=1,count do
	local it1=getglobal("zBagItem"..i);
	local index1,file1,name1,itemCount1,locked1,invalid1 = GetBagItemInfo(it1:GetID());
	if (locked1) then
		lidx=i;
	end
end
return lidx;
end

function zBag_OrderItems() -- sort items (bubble sort)
local count=zBag_FindLastItemPos(ZBAG_MAXBAG,1);
-- local locked=zBag_FindLockedItem(count);
local ordered=false;
if (count>1) then -- start bubble sorting if we have more than 1 item
--	while (ordered==false) do
	ordered=true;
	--for i=1,count-1 do	
	--	local it1,it2=getglobal("zBagItem"..i),getglobal("zBagItem"..(i+1));
	--	local index1,file1,name1,itemCount1,locked1,invalid1 = GetBagItemInfo(it1:GetID());
	--	local index2,file2,name2,itemCount2,locked2,invalid2 = GetBagItemInfo(it2:GetID());
	--	if (name1>name2) then
	--		zBag_SwapItems(it1,it2);
	--		ordered=false;
	--	end
	--end
	--if (ordered==true) then
		ZBAG_SORTSTARTED=0;
		--yecho("zBag: finished!");
	--end
--	end -- while
end
end

function zBag_Sort()
--	zBag_CompactItems();
		RefreshBag(1);
		RefreshBag(2);
		if (zBagKit.ShowBagTab(3)) then
			RefreshBag(3);
		end
		if (zBagKit.ShowBagTab(4)) then
			RefreshBag(4);
		end
		if (zBagKit.ShowBagTab(5)) then
			RefreshBag(5);
		end
		if (zBagKit.ShowBagTab(6)) then
			RefreshBag(6);
		end
		zBag_Update();
end

function zBag_SortFull()
--HideUIPanel(zBag);
	--yecho("zBag: please wait to sort items!");
	zBag_CompactItems();
 	--zBag_OrderItems();
	ZBAG_SORTSTARTED=1;
--ShowUIPanel(zBag);
end

function zBag_SellLots()
	local moneyEarned = 0;
	local thisItemData;
	if IsShiftKeyDown() then
		yecho(zBLocale.zBagStrings.zBagSellLotsShiftKeyDown);
		ToggleUIFrame(zBagQuickSellConfigFrame);
	elseif StoreFrame:IsVisible() then	
		local startSellNumber = tonumber(zBag_VAR["quicksellstartslotnumber"]); 
		local endSellNumber = tonumber(zBag_VAR["quicksellendslotnumber"]); 
		local ignoreOptions = tonumber(zBag_VAR["quickSellIgnoreOptions"]);
		local dontSellDura = tonumber(zBag_VAR["dontQuickSellDurability"]);
		local dontSellLevel = tonumber(zBag_VAR["dontQuickSellLevel"]);
		local dontSellRarity0 = tonumber(zBag_VAR["dontQuickSellRarity0"]);
		local dontSellRarity1 = tonumber(zBag_VAR["dontQuickSellRarity1"]);
		local dontSellRarity2 = tonumber(zBag_VAR["dontQuickSellRarity2"]);
		local dontSellRarity3 = tonumber(zBag_VAR["dontQuickSellRarity3"]);
		local dontSellRarity4 = tonumber(zBag_VAR["dontQuickSellRarity4"]);
		local dontSellRarity5 = tonumber(zBag_VAR["dontQuickSellRarity5"]);
		if (startSellNumber == 0) then
			yecho(zBLocale.zBagStrings.zBagQuickSellDisabled);
		elseif (endSellNumber > ZBAG_MAXBAG) then
			yecho(zBLocale.zBagStrings.zBagInvalidQuickSellEndSlot);
		else
			local sellItem = 1;
			for i = startSellNumber, endSellNumber do
				sellItem = 1;
				local it1=getglobal("zBagItem"..i);
				local index1,file1,name1,itemCount1,locked1,invalid1 = GetBagItemInfo(it1:GetID());
				if (index1 > 0) then
					--BAGSORT TESTING CODE
					--data.: attributes,bagIndex,currentDur,flavorText,icon,invalid,isBindable,isBound,isDaily,isItemShopItem,isNotDropOnPKDeath,itemCount,level,link,liveTime,locked
					--data.: matk,mdef,name,numUses,patk,pdef,position,powerModifier,quality,runesTotal,runesUsed,speed,stackCount,tier,totalDur,type,unequipable,worth
					if (ignoreOptions == 1) then
						UseBagItem(index1);
					else
						thisItemData = BagSort.GetBagItemData(it1:GetID());

						
						if (thisItemData and (thisItemData.name ~= "")) then
							--NEW QS ITEM FILTER CODE
							alwaysSellThisItem = 0;
							neverSellThisItem = 0;
							for i=1,table.maxn(zBagQSItemFilter) do
								--StoreAction:1:"",2:"Always Sell",3:"Never Sell"
								--EntryType:1"",2"Item",3"Item Type"
								--yecho("StoreActionIs:" .. zBagQSItemFilter[i]["StoreAction"]);
								if ((zBagQSItemFilter[i]["StoreAction"]==3) and (zBagQSItemFilter[i]["EntryType"]==2)) then
									--yecho(zBagQSItemFilter[i]["Name"] .. "Never Sell Item Action");
									if (zBagQSItemFilter[i]["Name"] == thisItemData.name) then
										--yecho("match neverSellThisItem!");
										neverSellThisItem = 1;
										break; -- exit the for loop
									end
								elseif ((zBagQSItemFilter[i]["StoreAction"]==3) and (zBagQSItemFilter[i]["EntryType"]==3)) then
									--yecho(zBagQSItemFilter[i]["Name"] .. "Never Sell Item Type Action");
									if (zBagQSItemFilter[i]["Name"] == thisItemData.type) then
										--yecho("match neverSellThisItem 2nd!");
										neverSellThisItem = 1;
										break; -- exit the for loop
									end
								elseif ((zBagQSItemFilter[i]["StoreAction"]==2) and (zBagQSItemFilter[i]["EntryType"]==2)) then
									--yecho(zBagQSItemFilter[i]["Name"] .. "Always Sell Item Action");
									if (zBagQSItemFilter[i]["Name"] == thisItemData.name) then
										--yecho("match alwaysSellThisItem!");
										alwaysSellThisItem = 1;
										break; -- exit the for loop
									end
								elseif ((zBagQSItemFilter[i]["StoreAction"]==2) and (zBagQSItemFilter[i]["EntryType"]==3)) then
									--yecho(zBagQSItemFilter[i]["Name"] .. "Always Sell Item Type Action");	
									if (zBagQSItemFilter[i]["Name"] == thisItemData.type) then
										--yecho("match alwaysSellThisItem 2nd!");
										alwaysSellThisItem = 1;
										break; -- exit the for loop
									end									
								end
							end
						
							--dontSellDura = tonumber(zBag_VAR["dontQuickSellDurability"]);
							--local dontSellLevel = tonumber(zBag_VAR["dontQuickSellLevel"]);
							--local dontSellRarity0 = tonumber(zBag_VAR["dontQuickSellRarity0"]);
							if (dontSellDura > 0) then
								--yecho("dontSellDura gt 0");
								if (thisItemData.totalDur) then
									--yecho("thisItemData.totalDur");
									if (thisItemData.totalDur > dontSellDura) then
										--yecho("this.totalDur gt dontSellDura");
										sellItem = 0;
									end
								end
							end
							
							if (dontSellLevel > 0) then
								if (thisItemData.level) then
									if (thisItemData.level > dontSellLevel) then
										sellItem = 0;
									end
								end
							end							

							if (thisItemData.itemQuality) then
								--yecho(thisItemData.name .. thisItemData.itemQuality);
								if (dontSellRarity0 == 1) then
									if (thisItemData.itemQuality == 0) then
										sellItem = 0;
									end
								end

								if (dontSellRarity1 == 1) then
									if (thisItemData.itemQuality == 1) then
										--yecho(thisItemData.name .. thisItemData.itemQuality);
										sellItem = 0;
									end
								end

								if (dontSellRarity2 == 1) then
									if (thisItemData.itemQuality == 2) then
										
										sellItem = 0;
									end
								end

								if (dontSellRarity3 == 1) then
									if (thisItemData.itemQuality == 3) then
										sellItem = 0;
									end
								end

								if (dontSellRarity4 == 1) then
									if (thisItemData.itemQuality == 4) then
										sellItem = 0;
									end
								end

								if (dontSellRarity5 == 1) then
									if (thisItemData.itemQuality == 5) then
										sellItem = 0;
									end
								end								
							end
							
							if ((sellItem == 1) or alwaysSellThisItem ==1) then
								if (neverSellThisItem==1) then
									--don't sell this item
								else
									if (thisItemData.worth) then
										--yecho("thisworth:"..thisItemData.worth);
										if (thisItemData.itemCount) then
											moneyEarned = moneyEarned + (thisItemData.worth*thisItemData.itemCount);
										else
											moneyEarned = moneyEarned + thisItemData.worth;
										end
										UseBagItem(index1);
									end
								end
							end
						end
					end
				end
			end
			yecho(zBLocale.zBagQuickSellConfigFrame.TotalSale .. ": " .. moneyEarned);
		end
	else
		yecho(zBLocale.zBagQuickSellConfigFrame.UnableToSell);
	end
end

function debugEcho(debugString)
	if (zBag_VAR["displayDebugMessages"] == 1) then
		yecho(debugString);
	end
end

--overwrite BagSearch and SetButtonAlpha BagSearch addon functions to make BagSearch work with zBag
-- Cherry's Kit: only with the one bag. With individual bags, BagSearch's own functions (kept here)
-- work on the game's bag and bank windows.
local BagSearchOwn = { BagSearch = BagSearch, BankSearch = BankSearch, BankSearchResetFrames = BankSearchResetFrames };

function SetButtonAlpha( storeType, itemSlot, alphaVal)
	if (not zBagKit.IsOneBag()) then
		local itemButton = getglobal( storeType .. "ItemButton" .. (itemSlot or "") );
		if (itemButton ~= nil) then
			itemButton:SetAlpha(alphaVal);
		end
		return;
	end
	if (itemSlot ~= nil) then
		if (storeType == "Bag") then
			storeType = "zBag";
			itemTypeGroupName = "Item";
		elseif (storeType == "Bank") then
			storeType = "zBagB";
			itemTypeGroupName = "Item";
		else
			itemTypeGroupName = "ItemButton";
		end
		--yecho(storeType .. itemTypeGroupName .. itemSlot);
		local itemButton = getglobal( storeType .. itemTypeGroupName .. itemSlot );
		if (itemButton ~= nil) then
			itemButton:SetAlpha(alphaVal);
		end
	end
end	

function BagSearch(itemName)
	if (not zBagKit.IsOneBag()) then
		return BagSearchOwn.BagSearch(itemName);
	end
	local itemList = FindBagItemByName(itemName)
	for n=1,180 do
		SetButtonAlpha("Bag",n,0.2)
	end
	for k,i in pairs(itemList) do
		SetButtonAlpha("Bag",i,1)
	end
end

function BankSearch(itemName)
	if (not zBagKit.IsOneBag()) then
		return BagSearchOwn.BankSearch(itemName);
	end
	local itemList = zBagKit.FindBankItems(itemName, ZBAG_MAXBBAG)
	for n=1,ZBAG_MAXBBAG do
		SetButtonAlpha("Bank",n,0.2)
	end
	for k,i in pairs(itemList) do
		SetButtonAlpha("Bank",i,1)
	end
end

function BankSearchResetFrames()
	if (not zBagKit.IsOneBag()) then
		return BagSearchOwn.BankSearchResetFrames();
	end
	ResetBagItemAlpha("Bank",1,ZBAG_MAXBBAG)
	for n=1,5 do
		SetStorageTabColor("Bank",n,1,1,1)
	end
end
--end overwritten BagSearch functions

--for dailynotes addon tie
function ZBag_IsDailyItem(index)
	-- will be hooked by dailynotes
	return false ;
end

SLASH_ZBAG1 = "/zb";
SLASH_ZBAG2 = "/zBag";
SlashCmdList["ZBAG"] = zBag_Switch;
