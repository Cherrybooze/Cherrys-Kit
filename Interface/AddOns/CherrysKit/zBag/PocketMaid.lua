-- Default
local POCKETMAID_DISCLAIMER   = "PocketMaid Loaded. PocketMaid is not responsible for lost items by using those Hidden slots, please use your own discretion."
local POCKETMAID_HIDDENSLOT   = "Hidden slot: Use at your own risk"
local POCKETMAID_HIDDENSLOTDISABLED   = "Hidden slot: Disabled in RoM v4.0"

-- tw
if ( GetLanguage() == "TW" ) then
    POCKETMAID_DISCLAIMER	= "PocketMaid 已載入. 本插件及插件作者對使用額外欄位所造成的物品遺失不負任何責任, 請斟酌使用."
	POCKETMAID_HIDDENSLOT	= "額外欄位"
	POCKETMAID_HIDDENSLOTDISABLED   = "DISABLED: 額外欄位"
end


function PocketMaid_OnLoad(this)
	this:RegisterEvent("VARIABLES_LOADED");
end

function PocketMaid_OnEvent(this, event,arg,arg2,arg3,arg4)
	if event =="VARIABLES_LOADED" then
		--DEFAULT_CHAT_FRAME:AddMessage(POCKETMAID_DISCLAIMER) --Disclaimer
	end
end

--Rewrite
function HouseServantEquipItemButton_OnEnter( this )
	GameTooltip:SetOwner( this, "ANCHOR_TOPLEFT", -5, 0);
	local itemLink = nil;
	local ServantDBID = HouseServantFrame.ServantDBID;
	if( ServantDBID )then	
		itemLink = Houses_GetItemLink( ServantDBID , this:GetID() );
	end
	if( itemLink )then
		GameTooltip:SetHyperLink( itemLink );
	else
		local index = this:GetID() - 1
		if index == 29 or index > 39 then 	--additional slot describe
			GameTooltip:SetText( C_HOUSESERVANT_ITEM_TIPS );
			if index > 39 then
				GameTooltip:AddLine("-"..POCKETMAID_HIDDENSLOTDISABLED.."-",0.5,0.5,0.5) 
			else
				GameTooltip:AddLine("-"..POCKETMAID_HIDDENSLOT.."-",0.5,0.5,0.5) 
			end
		elseif( index < 30 )then
			local token = string.format( "SYS_EQWEARPOS_%02d", index );
			local tips = TEXT( token );
			GameTooltip:SetText( tips );
		else
			GameTooltip:SetText( C_HOUSESERVANT_ITEM_TIPS );
		end
		GameTooltip:Show();
	end
end


--Rewrite
function HouseServantFrame_Open_InfoMade( servantIndex )
	HouseServantFrameTitle:SetText( C_HOUSESERVANT_TITLE_VIEW );
	g_ServantHireIndex = nil;
	g_HouseServantFrame_Mode = DF_HS_Mode_Info;
	g_ServantIndex = servantIndex;
	for i = 1, HouseServantFrame_MAX_PAGES do
		local TabObj     = getglobal( "HouseServantTab" .. i );
		local ActiveObj  = getglobal( "HouseServantTab" .. i .. "Active" );
		local InctiveObj = getglobal( "HouseServantTab" .. i .. "Inctive" );
		local IconObj    = getglobal( "HouseServantTab" .. i .. "Icon" );
		if( i >= 1 and i <= Houses_GetServantCount() )then
			local DBID, name, sex = Houses_GetServantInfo( i )  --++
			TabObj.Page = HouseServantPageInfo;
			TabObj.tips = C_HOUSESERVANTINFO_PAGE1_TIPS.." ("..name..")"  --**
			TabObj:Show()
			--IconObj:SetFile( "interface\\HouseFrame\\HouseServant_Tab_state" );
			if( sex == 0 )then  --++
				IconObj:SetFile( "interface\\HouseFrame\\HouseServant_Tab_male" )  --++
			elseif( sex == 1 )then  --++
				IconObj:SetFile( "interface\\HouseFrame\\HouseServant_Tab_female" )  --++
			end  --++
		elseif( i >= 11 and i <= Houses_GetServantCount()+10 )then
			local DBID, name = Houses_GetServantInfo( i-10 )  --++
			TabObj.Page = HouseServantPageEquip;
			TabObj.tips = C_HOUSESERVANTINFO_PAGE2_TIPS.." ("..name..")"  --**
			TabObj:Show();
			IconObj:SetFile( "interface\\HouseFrame\\HouseServant_Tab_eq" );
		else
			TabObj.Page = nil;
			TabObj:Hide();
		end
	end
	HouseServantHireButton:Hide();
	HouseServantTabButton_OnClick( servantIndex );
	HouseServantPageInfo_Update();
	HouseServantFrame:Show();
end

--hook
orig_HouseServantTabButton_OnClick = orig_HouseServantTabButton_OnClick or HouseServantTabButton_OnClick
function HouseServantTabButton_OnClick( id )
	orig_HouseServantTabButton_OnClick( id )
	if( g_HouseServantFrame_Mode == DF_HS_Mode_Info )then
		for i=1, HouseServantFrame_MAX_PAGES do
			local TabObj     = getglobal( "HouseServantTab" .. i );
			local ActiveObj  = getglobal( "HouseServantTab" .. i .. "Active" );
			local InctiveObj = getglobal( "HouseServantTab" .. i .. "Inctive" );
			if( TabObj.Page )then
				if( i == id ) then
					TabObj.Page:Hide()
					if i>=1 and i <=Houses_GetServantCount() then
						g_ServantIndex = i
					elseif i >=11 and i <=Houses_GetServantCount()+10 then
						g_ServantIndex = i-10
					end
					ServantDBID = HouseServantFrame.ServantDBID
					HouseServantPageInfo_Update()
					TabObj.Page:Show()
				end
			end
		end
	end
end

