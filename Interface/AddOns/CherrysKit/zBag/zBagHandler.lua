
function zBagHandler_OnEvent(this,event,arg1,arg2)
if event=="VARIABLES_LOADED" then
	if AddonManager then
            local addon = {
                name = "zBag", 
                description = "Customizable bag and bank frames", 
                icon = "Interface\\Icons\\chest_001.dds",
                category = "Inventory",
                configFrame = zBagConfigFrame, 
                slashCommands = "/zb",
                miniButton = zBagMiniButton,
                onClickScript = zBagonClickScript,
				version = ZBAG_VERSION,
                author = "jrmstuff",
            }
            if AddonManager.RegisterAddonTable then
                AddonManager.RegisterAddonTable(addon)
            else
                AddonManager.RegisterAddon(addon.name, addon.description, addon.icon, addon.category, 
                    addon.configFrame, addon.slashCommands, addon.miniButton, addon.onClickScript)
            end
	end	
end
end

-- onupd777ate handler
-- Cherry's Kit: sorting moves an item every frame; the bag and bank windows are checked
-- 20 times a second instead of every frame.
local zBagHandlerWait = 0;
function zBagHandler_OnUpdate(this, elapsed)
	if (ZBAG_SORTSTARTED==1) then
		zBag_OrderItems();
	end
	zBagHandlerWait = zBagHandlerWait - (tonumber(elapsed) or 0.05);
	if (zBagHandlerWait > 0) then return; end
	zBagHandlerWait = 0.05;
	-- The bag and bank layouts are independent.
	if (zBagKit.onebag == nil) then return; end
	if (not zBagKit.IsOneBag()) then
		if (zBag:IsVisible()) then zBag:Hide(); end
	else
	if (zBag:IsVisible() and not BagFrame:IsVisible()) then
		--yecho("here1");
		if(zBag_VAR["alwaysshow"]==0) then 
			HideUIPanel(zBag);
		end
		if (zBagKit.IsOneBank() and zBag_VAR["bankopenwithbag"]==1) then
	--		ZBAG_BANKINSPECT=1;
			HideUIPanel(zBagB);
		end
	elseif (not zBag:IsVisible() and BagFrame:IsVisible()) then
		--yecho("here2");
		ShowUIPanel(zBag);
		if (zBagKit.IsOneBank() and zBag_VAR["bankopenwithbag"]==1) then
	--		ZBAG_BANKINSPECT=1;
			ShowUIPanel(zBagB);
		end
	--	just move the old bag out of view
		zBagKit.RememberPos(BagFrame, "bagpos"); -- Cherry's Kit: to put it back for individual bags
		BagFrame:ClearAllAnchors();
		BagFrame:SetAnchor("TOPLEFT","TOPRIGHT","UIParent",50,50);
		BagItemFrame:Hide(); -- to not get update events on default bag when opened (a little fps boost)
	end
	zBagKit.KeepOffScreen(BagFrame, "bagpos", 50, 50); -- Cherry's Kit: moved back on screen by someone else

	end

	if (not zBagKit.IsOneBank()) then
		if (zBagB:IsVisible()) then zBagB:Hide(); end
		return;
	end
	if (zBagB:IsVisible() and not BankFrame:IsVisible() and ZBAG_BANKINSPECT==0) then
		--yecho("here3");
		HideUIPanel(zBagB);
		--HideUIPanel(zBagBBackground);
	elseif (not zBagB:IsVisible() and BankFrame:IsVisible()) then
		--yecho("here4");
		ShowUIPanel(zBagB);
		--ShowUIPanel(zBagBBackground);
	--	just move the old bank out of view
		zBagKit.RememberPos(BankFrame, "bankpos");
		BankFrame:ClearAllAnchors();
		BankFrame:SetAnchor("TOPLEFT","TOPRIGHT","UIParent",100,100);
	elseif (zBagB:IsVisible() and BankFrame:IsVisible() and ZBAG_BANKINSPECT==1) or
			(zBagB:IsVisible() and not BankFrame:IsVisible() and ZBAG_BANKINSPECT==0) then -- reopen zbank to enable controls
		--yecho("here5");
		ZBAG_BANKINSPECT=0;
		zBagB_Resize(zBagB);
		zBagB_Update();
		zBagB_OnShow();
	--	just move the old bank out of view
		zBagKit.RememberPos(BankFrame, "bankpos");
		BankFrame:ClearAllAnchors();
		BankFrame:SetAnchor("TOPLEFT","TOPRIGHT","UIParent",100,100);
	end
	zBagKit.KeepOffScreen(BankFrame, "bankpos", 100, 100); -- Cherry's Kit: moved back on screen by someone else
end

SLASH_ZBAG1 = "/zb";
SLASH_ZBAG2 = "/zBag";
SlashCmdList["ZBAG"] = zBag_Switch;
