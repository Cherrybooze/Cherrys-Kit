-- author adisadicul
ZBAG_MAXBBAG=300;
zBag_VAR = {};

function zBagB_Resize(this)
	--yecho("zbank resize");
	local item;
	local bagtab = 1;
	local showtab = 1;
	local visibletab=1;
	local crx=1; local cry=1; local cr=1;
	local startrowitem=zBagBItem1; local lastitem=zBagItem1;
	local additionalTopOffset = 0;
	local additionalBottomOffset = 15;
	local zBagBSliderValue = zBagBRowSlider:GetValue();
	if (zBagBSliderValue == 0) then
		zBagBSliderValue = zBag_VAR["bankrowitems"];
	end
	if (zBagBSliderValue == nil) then
		zBagBSliderValue = 10;
	end
		
	if ((zBag_VAR["showitemshop"] == 1) and (zBagBSliderValue < 4)) then
		additionalTopOffset = 14+24*2*zBag_VAR["bankscale"];
	elseif ((ZBAG_BANKINSPECT==0) or (zBag_VAR["showitemshop"] == 1)) then
		additionalTopOffset = 14+24*zBag_VAR["bankscale"];
	else 
		additionalTopOffset = 14;
	end

	local zBagBBackgroundCloseButtonSize = 24*zBag_VAR["bankscale"];
	if (zBagBBackgroundCloseButtonSize > 20) then
		zBagBBackgroundCloseButtonSize = 20;
	end

	zBagBBackgroundCloseButton:SetSize(zBagBBackgroundCloseButtonSize,zBagBBackgroundCloseButtonSize);
	zBagBBackgroundCloseButton:ClearAllAnchors();
	zBagBBackgroundCloseButton:SetAnchor("TOPRIGHT","TOPRIGHT",zBagBBackground,-5,5);	

	zBagBSort:SetSize(24*zBag_VAR["bankscale"],24*zBag_VAR["bankscale"]);
	zBagBSort:ClearAllAnchors();
	zBagBSort:SetAnchor("TOPLEFT","TOPLEFT",zBagBBackground,12,24);	

	zBagBRent2:SetSize(24*zBag_VAR["bankscale"],24*zBag_VAR["bankscale"]);
	zBagBRent2:ClearAllAnchors();
	
	if (ZBAG_BANKINSPECT==1) then
		zBagBRent2:SetAnchor("TOPLEFT","TOPLEFT",zBagBBackground,12,24);	
	else
		zBagBRent2:SetAnchor("TOPLEFT","TOPRIGHT",zBagBSort,2,0);
	end

	zBagBRent3:SetSize(24*zBag_VAR["bankscale"],24*zBag_VAR["bankscale"]);
	zBagBRent3:ClearAllAnchors();
	zBagBRent3:SetAnchor("TOPLEFT","TOPRIGHT",zBagBRent2,2,0);	
	
	zBagBRent4:SetSize(24*zBag_VAR["bankscale"],24*zBag_VAR["bankscale"]);
	zBagBRent4:ClearAllAnchors();
	
	if (zBagBSliderValue < 4) then
		zBagBRent4:SetAnchor("TOPLEFT","BOTTOMLEFT",zBagBSort,0,2);
	else
		zBagBRent4:SetAnchor("TOPLEFT","TOPRIGHT",zBagBRent3,2,0);	
	end
	
	zBagBRent5:SetSize(24*zBag_VAR["bankscale"],24*zBag_VAR["bankscale"]);
	zBagBRent5:ClearAllAnchors();
	zBagBRent5:SetAnchor("TOPLEFT","TOPRIGHT",zBagBRent4,2,0);
							
	if (zBag_VAR["bankrowitems"] and zBag_VAR["bankscale"] and zBag_VAR["bankhighlighteven"] and zBag_VAR["bankshowback"]) then
		for i = 1, ZBAG_MAXBBAG do
				if ( (i-1)% 40 == 0 ) then
					bagtab = (i-1)/40+1;
					showtab=0;
					if (bagtab<=6 and zBagKit.ShowBankTab(bagtab)) then showtab=1; end -- Cherry's Kit: also the Auto tick
					if (showtab==1) then
						visibletab=visibletab+1;
					end
				end
				if (zBag_VAR["bank6"]==1 and i > 200) then
					showtab=1;
				end
			item = getglobal("zBagBItem"..i);
			item.index=i;
			item:ClearAllAnchors();
			if (showtab==1) then
				if (crx-1 == zBag_VAR["bankrowitems"]) then --new line when enough items on row
					crx=1; cry=cry+1;
				end
				zBagItem_Resize(item,32*zBag_VAR["bankscale"],32*zBag_VAR["bankscale"]);
				item:SetAnchor("TOPLEFT","TOPLEFT",zBagBBackground,(crx-1)*35*zBag_VAR["bankscale"]+14,(cry-1)*35*zBag_VAR["bankscale"]+15+additionalTopOffset);
				local itemhighlight=getglobal(item:GetName().."TabColor");
				if (ZBAG_BANKINSPECT==0) then
					if (zBag_VAR["bankhighlighteven"]==1 and visibletab%2==1) then
						--itemhighlight:SetColor(0.7,0.7,0,0.5);
						itemhighlight:Show();
					else
						itemhighlight:Hide();
					end
				else
					if (zBag_VAR["bankhighlightinspecting"]==1 and zBag_VAR["bankhighlighteven"]==1) then
						if (visibletab%2==1) then

							itemhighlight:SetColor(1,0.7,0,0.5);
						else

							itemhighlight:SetColor(0.7,0,0,0.5);
						end
						itemhighlight:Show();
					elseif (zBag_VAR["bankhighlightinspecting"]==1 and zBag_VAR["bankhighlighteven"]==0) then

							itemhighlight:SetColor(0.7,0,0,0.5);
							itemhighlight:Show();
					elseif (zBag_VAR["bankhighlightinspecting"]==0 and zBag_VAR["bankhighlighteven"]==1) then

						if (visibletab%2==1) then

							itemhighlight:SetColor(0.7,0.7,0,0.5);
							itemhighlight:Show();
						else

							itemhighlight:Hide();
						end
					else

							itemhighlight:Hide();
					end
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

		--if (crx-1 == zBag_VAR["bankrowitems"]) then --new line when enough items on row
		--	crx=1; cry=cry+1;
		--end

		local bagbk = getglobal("zBagBBackground");
		if (zBag_VAR["bankshowback"]==1) then
			bagbk:Show();
			bagbk:SetSize(zBag_VAR["bankrowitems"]*35*zBag_VAR["bankscale"]+25,cry*35*zBag_VAR["bankscale"]+27+additionalTopOffset+additionalBottomOffset);
			if (zBagBBackground:GetWidth() < 80) then
				zBagBInspect:SetText(zBLocale.zBankStrings.BankPREVIEW1Letter);
			elseif (zBagBBackground:GetWidth() < 100) then
				zBagBInspect:SetText(zBLocale.zBankStrings.BankPREVIEW3Letters);
			elseif (zBagBBackground:GetWidth() < 110) then
				zBagBInspect:SetText(zBLocale.zBankStrings.BankPREVIEW5Letters);
			else
				zBagBInspect:SetText(zBLocale.zBankStrings.BankPREVIEW7Letters);
			end
		else
			bagbk:Hide();
		end
		cry=cry+1;
		local sx,sy = (zBag_VAR["bankrowitems"]+1)*35*zBag_VAR["bankscale"], (cry)*35*zBag_VAR["bankscale"];
		--yecho("zBBx,zBBy:" .. zBagBBackground:GetWidth() .. "," .. zBagBBackground:GetHeight() .. " sx,sy:" .. sx .. "," .. sy);
		local bankhl = getglobal("zBagBHLBank");
		if (ZBAG_BANKINSPECT==0) then
			bankhl:SetSize(sx*2,sy*2);
			bankhl:ClearAllAnchors();
			bankhl:SetAnchor("CENTER","TOPLEFT",zBagBItem1,(sx-35*zBag_VAR["bankscale"])/2,(sy-35*zBag_VAR["bankscale"])/2);
			--bankhl:SetAnchor("BOTTOMRIGHT","TOPLEFT",zBagBBackgroundCloseButton,0,0);
			bankhl:Show();
		else
			bankhl:Hide();
		end
	end -- if
end

--this function works, but the functions it calls do not
function zBagB_CompactItems() -- fill free slots
local startidx,endidx = 0,ZBAG_MAXBBAG;
while (startidx<endidx) do
	endidx=zBagB_FindLastItemPos(endidx,1);
	startidx=zBagB_FindNextGap(startidx,endidx);
	if (startidx<endidx) then
		zBagB_SwapItemsIdx(startidx,endidx);
	end
end--while
--yecho("gap:"..startidx.." last:"..endidx);
end

function zBagB_Sort()
--	zBag_CompactItems();
		RefreshBank(1);
		if (zBagKit.ShowBankTab(2)) then
			RefreshBank(2);
		end
		if (zBagKit.ShowBankTab(3)) then
			RefreshBank(3);
		end
		if (zBagKit.ShowBankTab(4)) then
			RefreshBank(4);
		end
		if (zBagKit.ShowBankTab(5)) then
			RefreshBank(5);
		end
		if (zBag_VAR["bank6"]==1) then
			RefreshBank(6);
		end		
end

--Broken.  GetBankItemInfo only returns 4 values  texture, name, count, locked
function zBagB_FindLastItemPos(endidx,min)
local found=false;
local cridx=endidx;
while (found==false and cridx>=min) do
	local index,file,name,itemCount,locked,invalid = GetBankItemInfo(getglobal("zBagBItem"..cridx):GetID());
	--yecho("name"..name.." itemCount:"..itemCount);
	if (locked or itemCount<1) then -- emptyslot (going down)
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

--Broken.  GetBankItemInfo only returns 4 values  texture, name, count, locked
function zBagB_FindNextGap(startidx,max)
local found=false;
local cridx=startidx+1;
while (found==false and cridx<=max) do
	local index,file,name,itemCount,locked,invalid = GetBankItemInfo(getglobal("zBagBItem"..cridx):GetID());
	if (itemCount>=1) then -- full slot (going next)
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

--Broken.  GetBankItemInfo only returns 4 values  texture, name, count, locked
function zBagB_SwapItems(item1,item2)
if (item1 and item2) then
	--local texture, name, count, locked = GetBankItemInfo();
	--local inventoryIndex, icon, name, itemCount, locked, invalid = GetBagItemInfo ();
	
	local index1,file1,name1,itemCount1,locked1,invalid1 = GetBankItemInfo(item1:GetID());
	local index2,file2,name2,itemCount2,locked2,invalid2 = GetBankItemInfo(item2:GetID());
	if (locked1 or locked2) then -- don't swap locked slots
		return
	end
	if (itemCount1<1 and itemCount2<1) then -- two empty slots. nothing to swap
		return
	end
	if (itemCount1>=1) then --swap starting with an existing item
		PickupBankItem(index1);
		PickupBankItem(index2);
	else
		PickupBankItem(index2);
		PickupBankItem(index1);
	end
end
end

--Broken.  GetBankItemInfo only returns 4 values  texture, name, count, locked
function zBagB_SwapItemsIdx(index1,index2)
if (index1 and index2) then
	local item1,item2 = getglobal("zBagBItem"..index1), getglobal("zBagBItem"..index2);
	zBagB_SwapItems(item1,item2);
end
end

function zBagB_SetItemShop()
	if (zBag_VAR["showitemshop"]==0) then
	-- hide item shop related stuff
		zBagBRent2:Hide();
		zBagBRent3:Hide();
		zBagBRent4:Hide();
		zBagBRent5:Hide();
		
		--zBagShop:Hide();
	else
		zBagBRent2:Show();
		zBagBRent3:Show();
		zBagBRent4:Show();
		zBagBRent5:Show();
		--zBagShop:Show();
	end
end

function zBagB_Update()
	if (zBagB:IsVisible() and ZBAG_BANKINSPECT==0) then
		--yecho("zbankupdt");
		local item,texture,name,itemCount,locked;
		local bagtab = 1;
		local RentTime;
		item = getglobal("zBagBItem1");
		for i=1,ZBAG_MAXBBAG do	
			if ( (i-1)% 40 == 0 ) then
				bagtab = (i-1)/40+1;
				if (bagtab == 1) then
					RentTime = 1;
				else
					RentTime = TimeLet_GetLetTime("BankBag"..bagtab);
				end
			end
			item = getglobal("zBagBItem"..i);
			if (item.display==true) then
				item:SetID(i);
				texture,name,itemCount,locked = GetBankItemInfo(i);
			
				--and this.disbl==false
				if (RentTime and RentTime<0 ) then
					item:Disable(); item.disbl=true;
					getglobal(item:GetName().."Disabled"):Show();
				elseif (item.disbl==true) then
					item:Enable(); item.disbl=false;
					getglobal(item:GetName().."Disabled"):Hide();
				end
				if (not item:IsVisible()) then 
					item:Show();
				  --yecho("zbanki "..i.." show");
				end

				if (texture~=item.tex) then 
					SetItemButtonTexture(item,texture); 
					item.tex=texture;
				  --yecho("zbanki "..i.." tex");
				end
				if (itemCount~=item.count) then 
					SetItemButtonCount(item,itemCount); 
					item.count=itemCount;
				  --yecho("zbanki "..i.." count");
				end
				if (zBag_VAR["bankslotnumbers"] == 1) then
					zBagKit.Label(item, i, 13*(zBag_VAR["bankscale"] or 1));
				else
					zBagKit.Label(item, nil);
				end
				if (locked~=item.enbl) then 
					SetItemButtonLuminance(item,locked); 
					item.enbl=locked;
				  --yecho("zbanki "..i.." lock");

				end
				
				if (GameTooltip:IsVisible() and GameTooltip:IsOwned(item)) then
					GameTooltip:SetBankItem(item.index);
				end 
			else
				if (item:IsVisible()) then item:Hide() end
			end

		end

	end
end

function zBagB_OnLoad(this)
	this:RegisterEvent("BANK_OPEN");
	this:RegisterEvent("BANK_CLOSE");
	this:RegisterEvent("BANK_UPDTAE");
	this:RegisterEvent("VARIABLES_LOADED");
end

function zBagB_OnEvent(this,event,arg1,arg2)
--yecho(event);
	if (event=="BAG_ITEM_UPDATE" or event=="BANK_OPEN" or event=="BANK_UPDTAE") then
		if (this:IsVisible()) then
			zBagB_Update();
		end
	elseif (event=="VARIABLES_LOADED") then
		if(not zBag_VAR)then
			zBag_VAR={};
		end
		zBagKit.Freeze();
		if (zBag_VAR["bankx"] and zBag_VAR["banky"])then
			zBagBBackground:ClearAllAnchors();
			local scale = GetUIScale();
			zBagBBackground:SetAnchor("TOPLEFT","TOPLEFT","UIParent",zBag_VAR["bankx"]/scale,zBag_VAR["banky"]/scale);
		else
			zBag_VAR["bankx"]=50;
			zBag_VAR["banky"]=200;
		end
		if (not zBag_VAR["bankrowitems"]) then 
			zBag_VAR["bankrowitems"]=10;
		end
		if (not zBag_VAR["bankshowback"]) then 
			zBag_VAR["bankshowback"]=1;
		end
		if (not zBag_VAR["bankscale"]) then 
			zBag_VAR["bankscale"]=0.99;
		end
		if (not zBag_VAR["bankhighlighteven"]) then
			zBag_VAR["bankhighlighteven"]=1;
		end
		if (not zBag_VAR["bankhighlightinspecting"]) then
			zBag_VAR["bankhighlightinspecting"]=1;
		end
		if (not zBag_VAR["bankopenwithbag"]) then
			zBag_VAR["bankopenwithbag"]=0;
		end
		if (not zBag_VAR["allowaltrightclickdelete"]) then
			zBag_VAR["allowaltrightclickdelete"]=0;
		end
		if (not zBag_VAR["usebagsearch"]) then
			zBag_VAR["usebagsearch"]=1;
		end		

	
		if (not zBag_VAR["bank2"]) then 
			zBag_VAR["bank2"]=1;
		end
		if (not zBag_VAR["bank3"]) then 
			zBag_VAR["bank3"]=1;
		end
		if (not zBag_VAR["bank4"]) then 
			zBag_VAR["bank4"]=1;
		end
		if (not zBag_VAR["bank5"]) then 
			zBag_VAR["bank5"]=1;
		end
		--bank6 = the item shop bank
		if (not zBag_VAR["bank6"]) then 
			zBag_VAR["bank6"]=1;
		end		
		SaveVariablesPerCharacter("zBag_VAR");
		SaveVariables("zBag_VAR");
		zBagB_Resize(this);
		--yecho("zbank loaded");
		if (this:IsVisible()) then
			zBagB_Update();
		end
	end	
end

function zBagB_OnShow(this)
	--yecho("zBagB_OnShow called");
	if (this:IsVisible()) then
		if (BankFrame:IsVisible()) then 
			ZBAG_BANKINSPECT=0;
		else 
			ZBAG_BANKINSPECT=1; 
		end
		--yecho("in zBagB_OnShow");
		zBagB_Resize(this);
		zBagB_Update();
	end
end

function zBagB_OnUpdate(this)
zBagB_Update();
end

function zBagB_OnShow()
zBagBRent2:Hide();
zBagBRent3:Hide();
zBagBRent4:Hide();
zBagBRent5:Hide();
	if (zBag_VAR["showitemshop"]==1) then
		zBagBRent2:Show();
		zBagBRent3:Show();
		zBagBRent4:Show();
		zBagBRent5:Show();
	end		
	if (ZBAG_BANKINSPECT==1) then
		zBagBInspect:Show();
		zBagBSort:Hide();
	else
		zBagBInspect:Hide();
		zBagBSort:Show();
	end
		ShowUIPanel(zBagB);
end



