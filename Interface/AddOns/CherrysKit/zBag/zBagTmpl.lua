-- author adisadicul
ZBAG_BANKINSPECT=0;

function yecho(str)
DEFAULT_CHAT_FRAME:AddMessage(str, 0.3, 0.8, 0.8);
end


function zBag_LetTime(tabindex, isbank)
local isLet,letTime = GetBagPageLetTime(tabindex);
if (isbank==true) then
	isLet=true;
	letTime = TimeLet_GetLetTime("BankBag"..tabindex);
end
if (not isLet) then
	return "Not rented";
else
	if (letTime >= 0) then
		local d = math.floor( letTime / 60 / 24 );
		local h = math.floor( ( letTime - ( d * 60 * 24 ) ) / 60 );
		local m = letTime - ( d * 60 * 24 ) - ( h * 60 );
		return string.format(BANK_LETTIME_MSG , d , h , m);
	else
		return BANK_LET_OVER_TIME;
	end
end
end

--yecho("zBagItem_Update");
function zBagItem_Update(this)
		local index,file,name,itemCount,locked,invalid = GetBagItemInfo(this:GetID());
		this.index = index;
		SetItemButtonTexture(this,file);
		SetItemButtonCount(this,itemCount);
		SetItemButtonLuminance(this,locked);
end

--yecho("zBagItem_OnEvent");
function zBagItem_OnEvent(this, event)
	if (event=="BAG_ITEM_UPDATE") then
		if (this:IsVisible() and this.index==arg1) then
			zBagItem_Update(this);
		end
	elseif (event=="BAG_UPDATE_COOLDOWN") then
		if (this:IsVisible()) then
			local duration,remaining = GetBagItemCooldown(this.index);
			CooldownFrame_SetTime(getglobal(this:GetName().."Cooldown"),duration,remaining);
		end
	end
end

--yecho("zBagItem_OnClick");
function zBagItem_OnClick(this, button, ignoreShift)
	if ( GarbageFrame:IsVisible() ) then
		InsertGarbageItem(this.index);
		return;
	end
    if ( MailFrame:IsVisible() ) and ( IsAltKeyDown() ) then
        PickupBagItem(this.index);
        ClickSendMailItemButton();
        if SendMailNameEditBox:GetText() and SendMailNameEditBox:GetText() ~= "" then
            SendMailFrame_SendMail();
        end    
        return;
    end 
	
	if (button=="LBUTTON") then
  --yecho("lbutton");
		if(IsShiftKeyDown() and not ignoreShift) then
  --yecho("isshift");
			local itemLink=GetBagItemLink(this.index);
			if(ChatEdit_AddItemLink(itemLink))then
				return;
			end
  --yecho("after chat add");
			local index,file,name,itemCount,locked=GetBagItemInfo(this:GetID());
			--itemCount=itemCount or 0;
			if(locked or itemCount<= 1 )then
				return;
			end
  --yecho("after locked");
			local slot, sourceIndex, sourceLink = this:GetID(), index, GetBagItemLink(index);
			if (not sourceLink) then return; end
			this.AskNumberFrameCallBack = function(button,Number)
				local currentIndex, _, _, currentCount, currentLocked = GetBagItemInfo(slot);
				Number = tonumber(Number);
				-- Updates may change another stack without cancelling this dialog.
				-- A remapped/replaced source must never split a different item.
				if (not this:IsVisible() or this:GetID() ~= slot or this.index ~= sourceIndex
					or currentIndex ~= sourceIndex or GetBagItemLink(sourceIndex) ~= sourceLink
					or currentLocked or not Number or Number ~= Number or Number < 1
					or Number == math.huge or Number ~= math.floor(Number)
					or not currentCount or currentCount <= 1 or Number > currentCount) then return; end
				SplitBagItem(sourceIndex,Number);
			end
  --yecho("before open number frame "..this:GetName());
			OpenAskNumberFrame(1,itemCount,this,"BOTTOMRIGHT","TOPRIGHT" );
			return;
		elseif( IsCtrlKeyDown() ) then
			local itemLink=GetBagItemLink(this.index);
			ItemPreviewFrame_SetItemLink(ItemPreviewFrame,itemLink);
			return;
		end
		PickupBagItem(this.index);
	elseif (button=="RBUTTON") then
		--yecho("rbutton");

		if( IsAltKeyDown() ) then
            if (zBag_VAR["allowaltrightclickdelete"] == 0) then
				yecho("Alt+Right click quick delete disabled in setup");
			else
				PickupBagItem(this.index);
				DeleteCursorItem();
				return;
			end
        end
		if TradeFrame:IsVisible() then
			for x = 1, 8 do
				if not GetTradePlayerItemInfo(x) then
					PickupBagItem(this.index);
					ClickTradeItem(x)
					return
				end
			end
		else
			UseBagItem(this.index);
		end		
	end
	AskNumberFrame:Hide();
end

--yecho("zBagItem_Resize");
function zBagItem_Resize(this,w,h)
this:SetSize(w,h);
getglobal(this:GetName().."Cooldown"):SetSize(w,h);
getglobal(this:GetName().."Icon"):SetSize(w*0.98,h*0.98);
getglobal(this:GetName().."Normal"):SetSize(w*2,h*2);
getglobal(this:GetName().."Pushed"):SetSize(w*2,h*2);
getglobal(this:GetName().."TabColor"):SetSize(w*2.2,h*2.2);
end

--yecho("zBagItem_OnLoad");
function zBagItem_OnLoad(this)
	this:RegisterEvent("BAG_ITEM_UPDATE");
	this:RegisterEvent("BAG_UPDATE_COOLDOWN");
	this:RegisterForClicks("LeftButton", "RightButton");
	this.display=true;
end

-- EqItem functions --

function zEqItem_Update(this)
	local id = this:GetID();
	local textureName=GetInventoryItemTexture("player", id);
	if (textureName) then
		SetItemButtonTexture(this,textureName);
	else
		SetItemButtonTexture(this,this.backgroundTextureName);
	end
	local disabledTexture=getglobal(this:GetName().."Disabled");
	if (disabledTexture) then
		if ( GetInventoryItemInvalid("player", id) ) then
			disabledTexture:Show();
		else
			disabledTexture:Hide();
		end
	end
	
	local itemquality = GetInventoryItemQuality("player", id);
	local qualityTexture = getglobal(this:GetName().."TabColor");
	local r, g, b;
	if (itemquality>0) then
		qualityTexture:Show();
		r, g, b = GetItemQualityColor(itemquality);
		--yecho ("iq" .. itemquality .. " r:" .. r .. " g:" .. g .. " b:" .. b);
		if (itemquality == 2) then
			qualityTexture:SetAlpha( 1 );
		end 
		qualityTexture:SetColor(r, g, b);
	else
		qualityTexture:Hide();
	end
	
	SetItemButtonCount(this, GetInventoryItemCount("player",id));
	local duration,remaining = GetEquipItemCooldown(this:GetID());
	local cooldown = getglobal(this:GetName().."Cooldown");
	if (cooldown) then
		CooldownFrame_SetTime(cooldown, duration, remaining);
	end
	if (GameTooltip:IsVisible() and GameTooltip:IsOwned(this)) then
		GameTooltip:SetInventoryItem("player",id);
	end
end

function zEqItem_OnShow(this)
	zEqItem_Update(this);
end

function zEqItem_OnEvent(this,event,arg1,arg2)
	if (event=="PLAYER_INVENTORY_CHANGED") then
		if (arg1==this:GetID()) then
			zEqItem_Update(this);
		end
	elseif (event=="EQUIPMENT_UPDATE_COOLDOWN") then
		if (this:IsVisible()) then
			local duration,remaining = GetEquipItemCooldown(this:GetID());
			local cooldown = getglobal(this:GetName().."Cooldown");
			if (cooldown) then
				CooldownFrame_SetTime(cooldown, duration, remaining);
			end
		end
	end
end

function zEqItem_OnClick(this,key,isShiftDown)
	if (key=="LBUTTON") then
		PickupEquipmentItem(this:GetID());
	elseif (key=="RBUTTON") then
		UseEquipmentItem(this:GetID());
	end
end

function zEqItem_OnLoad(this)
	this:RegisterForClicks("LeftButton", "RightButton");
	this:RegisterEvent("EQUIPMENT_UPDATE_COOLDOWN");
	this:RegisterEvent("PLAYER_INVENTORY_CHANGED");
	this.display=true;
	local slotName = ZBAG_SLOTS[this:GetID()];
	local slotId;
	slotId, this.backgroundTextureName = GetInventorySlotInfo(slotName);
	this:SetID(slotId);
	getglobal(this:GetName().."Icon"):SetTexture(this.backgroundTextureName);
end

-- BankItem functions --

function zBankItem_OnLoad(this)
this:RegisterForClicks("LeftButton", "RightButton");
--this:RegisterEvent("BANK_UPDATE");
this.display=true;
this.tex="";
this.count=0;
this.lum=false;
this.enbl=true;
this.disbl=false;
end

function zBankItem_Update(this)
		if (this:IsVisible()) then
		local file,name,itemCount,locked = GetBankItemInfo(this:GetID());
		if (file~=this.tex) then SetItemButtonTexture(this,file); this.tex=file end
		if (itemCount~=this.count) then SetItemButtonCount(this,itemCount); this.count=itemCount end
		if (locked~=this.enbl) then SetItemButtonLuminance(this,locked); this.enbl=locked end
		end
end

function zBankItem_OnShow(this)
	zBankItem_Update(this);
end

function zBankItem_OnClick(this,key,isShiftDown)
	--yecho("in zBankItem_OnClick");
	if (key=="LBUTTON") then
		if( IsShiftKeyDown() ) then
			local itemLink=GetBankItemLink(this.index);
			ChatEdit_AddItemLink(itemLink);
			return;
		elseif(IsCtrlKeyDown()) then
			local itemLink=GetBankItemLink(this.index);
			ItemPreviewFrame_SetItemLink(ItemPreviewFrame,itemLink);
			return;
		end
		PickupBankItem(this.index);
	elseif (key=="RBUTTON") then
		if (ZBAG_BANKINSPECT==0) then
			DrawBankItem(this.index);
		end
	end
end

function zBankItem_OnEvent(this,event,arg1,arg2)
	if (event=="PLAYER_INVENTORY_CHANGED") then
		if (arg1==this:GetID()) then
			zBankItem_Update(this);
		end
	end
end
