-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end
--------------------------------------------------------------------------------
-- Constants
Kitty.VERSION = "0.973";

--------------------------------------------------------------------------------
-- Print the target's buffs and debuffs
Kitty.showBuff = function(target)
	if(UnitName(target) == nil) then
		target = "player";
	end

	-- Read buffs
	local buffManager = Kitty.BuffManager();
	buffManager:update(target);
	Kitty.sendMessage(tostring(buffManager), "DEFAULT", 1, 1, 1);
	buffManager = nil;
end;
Kitty.showBuff = Kitty.protectFunction(Kitty.showBuff);	-- Run protected (errors go to chat)
Kitty.ShowBuff = Kitty.showBuff;	-- Alias
Kitty.showbuff = Kitty.showBuff;	-- Alias

--------------------------------------------------------------------------------
-- Check party members' buffs
Kitty.checkBuff = function()
	local outList = {};

	table.insert(outList, Kitty.T("message", "StartBuffCheckMessage"));
	for index, unit in Kitty.PartyManager.iterator() do
		outList = Kitty.concatTable(outList, Kitty.checkTarget(unit));
	end
	table.insert(outList, Kitty.T("message", "EndBuffCheckMessage"));

	-- Output
	local messageType = "DEFAULT";
	if(Kitty.PartyManager.count() > 1 and IsShiftKeyDown()) then
		messageType = "PARTY";
	end

	Kitty.sendMessage(outList, messageType);
end;
Kitty.checkBuff = Kitty.protectFunction(Kitty.checkBuff);	-- Run protected (errors go to chat)
Kitty.CheckBuff = Kitty.checkBuff;	-- Alias
Kitty.checkbuff = Kitty.checkBuff;	-- Alias
Kitty.formatBuffMessgage = function(buffManager, buffName, threshold)	-- true: buff present, false: buff missing, nil: buff about to expire
	if(threshold <= 0.0) then
		-- Zero or negative: always show the remaining time
		threshold = Kitty.MAX_VALUE;
	end

	local message = nil;
	local isBuff, duration = buffManager:hasEffect(buffName);
	if(isBuff) then
		if(duration < threshold) then
			isBuff = nil;
			message = Kitty.T("message", "BuffDurationStateMessage",
						Kitty.colorCyan(buffManager:getName()),
						Kitty.colorYellow(buffName),
						Kitty.colorYellow(Kitty.comma(duration)));
		else
			message = Kitty.T("message", "BuffExistStateMessage",
						Kitty.colorCyan(buffManager:getName()),
						Kitty.colorYellow(buffName));
		end
	else
		message = Kitty.T("message", "BuffNonExistStateMessage",
					Kitty.colorCyan(buffManager:getName()),
					Kitty.colorRed(buffName));
	end
	return isBuff, message;
end;
Kitty.checkBuffList = {
	[Kitty.T("skill", "Soul Bond")] = 0.0,
	[Kitty.T("skill", "Awakening of the Wild D")] = 0.0,
	[Kitty.T("item", "ProtectMeleeItem")] = 0.0,
	[Kitty.T("item", "ProtectMagicItem2")] = 0.0,
	[Kitty.T("item", "ProtectMagicItem1")] = 0.0,
	[Kitty.T("skill", "Holy Shield")] = 0.0,
	[Kitty.T("skill", "Holy Light Strike")] = 0.0,
	[Kitty.T("effect", "SignAttack")] = 0.0,
	[Kitty.T("effect", "SignMagicAttack")] = 0.0,
};
Kitty.checkTarget = function(target)
	if(UnitName(target) == nil) then
		return;
	end

	local outList = {};

	-- Read buffs
	local buffManager = Kitty.BuffManager();
	buffManager:update(target);

	-- HP
	if(UnitHealth(target) < 40000) then
		table.insert(outList, Kitty.T("message", "HPState",
								Kitty.colorCyan(tostring(UnitName(target))),
								Kitty.colorRed(Kitty.comma(UnitHealth(target))))
		);
	end

	-- Priest buffs
	if(not Kitty.ClassManager.isCaster(target)) then
		-- Amplified Attack
		local isAttackBoost, attackBoostMessage = buffManager:formatBuffMessgage(Kitty.T("skill", "Amplified Attack"), 180.0);
		if(isAttackBoost == nil or isAttackBoost == false) then
			-- Show the remaining time, or that the buff is missing
			table.insert(outList, tostring(attackBoostMessage));
		end
	end
	-- Grace of Life
	local isBenefitLife, benefitLifeMessage = buffManager:formatBuffMessgage(Kitty.T("skill", "Grace of Life"), 180.0);
	if(isBenefitLife == nil) then
		-- Show the remaining time
		table.insert(outList, tostring(benefitLifeMessage));
	end
	-- Enhanced Grace of Life
	local isBenefitLifeBoost, benefitLifeBoostMessage = buffManager:formatBuffMessgage(Kitty.T("skill", "Enhanced Grace of Life"), 180.0);
	if(isBenefitLifeBoost == nil) then
		-- Show the remaining time
		table.insert(outList, tostring(benefitLifeBoostMessage));
	end
	if(isBenefitLife == false and isBenefitLifeBoost == false) then
		-- Show that the buff is missing
		table.insert(outList, tostring(benefitLifeMessage));
	end

	-- Knight/Priest buffs
	local resultList = Kitty.PartyManager.searchClass("K/P");
	if(next(resultList) ~= nil) then
		-- Holy Protection
		local isHolyLightProtect, holyLightProtectMessage = buffManager:formatBuffMessgage(Kitty.T("skill", "Holy Protection"), 180.0);
		if(isHolyLightProtect == nil or isHolyLightProtect == false) then
			-- Show the remaining time, or that the buff is missing
			table.insert(outList, tostring(holyLightProtectMessage));
		end
	end

	-- Shadow Summoner buffs
	local resultList = Kitty.PartyManager.searchClass("Ss/");
	if(next(resultList) ~= nil) then
		-- Class buff spell
		local isClassUpSpell, ClassUpSpellMessage = buffManager:formatBuffMessgage(Kitty.T("skill", "Sublimation Weave Curse"), 180.0);
		if(isClassUpSpell == nil or isClassUpSpell == false) then
			-- Show the remaining time, or that the buff is missing
			table.insert(outList, tostring(ClassUpSpellMessage));
		end
	end

	-- Print the unit's buffs
	for buffName, threshold in pairs(Kitty.checkBuffList) do
		local isBuff, message = buffManager:formatBuffMessgage(buffName, threshold);

		if(threshold > 0.0) then
			if(isBuff == nil or isBuff == false) then
				-- Show the remaining time, or that the buff is missing
				table.insert(outList, tostring(message));
			end
		else
			if(isBuff == nil) then
				-- Show the remaining time
				table.insert(outList, tostring(message));
			end
		end
	end

	buffManager = nil;
	return outList;
end;

--------------------------------------------------------------------------------
-- Repair
Kitty.repair = function()
	if(not Kitty.findItem(Kitty.T("item", "RepairHammer"))) then
		Kitty.sendMessage(Kitty.T("message", "RepairMessage1"));
		return false;
	end

	for _, index in ipairs({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 21, 15, 10}) do
		local durable, max, name = GetInventoryItemDurable("player", index);
		if(name ~= nil) then
			if(index == 15 or index == 10) then
				-- Weapon
				if((max>100 and durable<max and durable<103) or (durable <= 40 and durable<max)) then
					UseItemByName(Kitty.T("item", "RepairHammer"));
					PickupEquipmentItem(index);
					Kitty.sendMessage(name .. "[" .. durable .. "]->[" .. max .. "]");
					return true;
				end
			else
				-- Armor
				if((max>100 and durable<=100) or (durable <= 40 and durable<max)) then
					UseItemByName(Kitty.T("item", "RepairHammer"));
					PickupEquipmentItem(index);
					Kitty.sendMessage(name .. "[" .. durable .. "]->[" .. max .. "]");
					return true;
				end
			end
		end
	end

	Kitty.sendMessage(Kitty.T("message", "RepairMessage2"));
	return true;
end;
Kitty.repair = Kitty.protectFunction(Kitty.repair);	-- Run protected (errors go to chat)
Kitty.Repair = Kitty.repair;	-- Alias

--------------------------------------------------------------------------------
-- Re-create the party
Kitty.previousMemberList = {};
Kitty.remakeParty = function()
	if(Kitty.PartyManager.getPartyState() ~= Kitty.PartyManager.SOLO) then
		-- In a party or raid
		if(IsShiftKeyDown()) then
			-- Disband
			Kitty.previousMemberList = Kitty.disperseParty();
		else
			assert(Kitty.eventQueue, "Kitty.eventQueue is nil.");
			-- Re-form (disband, then invite)
			-- Disband
			Kitty.previousMemberList = Kitty.disperseParty();

			if(#Kitty.previousMemberList > 6) then
				-- More than 6 people will be invited, so switch to a raid
				assert(Kitty.partyManager, "Kitty.partyManager is nil.");
				Kitty.partyManager:setAutoRaid(Kitty.PartyManager.ONCE);
			end

			-- Invite
			Kitty.eventQueue:addFunction(1000, Kitty.createParty, Kitty.previousMemberList);
		end
	else
		-- Solo
		if(#Kitty.previousMemberList > 6) then
			-- More than 6 people will be invited, so switch to a raid
			assert(Kitty.partyManager, "Kitty.partyManager is nil.");
			Kitty.partyManager:setAutoRaid(Kitty.PartyManager.ONCE);
		end

		-- Invite
		Kitty.createParty(Kitty.previousMemberList);
	end
end;
Kitty.remakeParty = Kitty.protectFunction(Kitty.remakeParty);	-- Run protected (errors go to chat)
Kitty.RemakeParty = Kitty.remakeParty;	-- Alias
Kitty.remakeparty = Kitty.remakeParty;	-- Alias
-- Invite to party
Kitty.createParty = function(memberList)
	for _, name in pairs(memberList) do
		if(name ~= UnitName("player")) then
			InviteByName(name);
		end
	end
end;
-- Disband party
Kitty.disperseParty = function()
	local memberList = Kitty.PartyManager.getMemberList();
	for _, name in pairs(memberList) do
		if(name ~= UnitName("player")) then
			UninviteByName(name);
		end
	end
	return memberList;
end;

--------------------------------------------------------------------------------
-- Find an item in the bag
Kitty.findItem = function(name) -- Item name
	local returnIndex = nil;
	-- Find an item in the bag
	for index = 1, 180 do
		local inventoryIndex, icon, itemName, itemCount, locked, quality = GetBagItemInfo(index);
		if(itemName == name) then
			returnIndex = inventoryIndex;
			break;
		end;
	end
	return returnIndex;
end;

--------------------------------------------------------------------------------
-- Cast on a unit without changing the target
Kitty.cast = function(skillName, unitName)	-- Skill name, character name
	local unitId = Kitty.PartyManager.searchTarget(unitName);
	if(unitId == nil) then
		unitId = unitName;
	end

	Kitty.SkillManager.castTarget(skillName, unitId);	-- Skill name, unit id
end;
Kitty.Cast = Kitty.cast;	-- Alias

--------------------------------------------------------------------------------
-- Combo attack (the main /run Kitty.attack() macro)
Kitty.isRequest = false;
Kitty.attack = function(...)
	if(Kitty.turnedOff or Kitty.isTurnedOff()) then
		if(not Kitty.turnedOffWarned) then
			Kitty.turnedOffWarned = true;
			Kitty.turnedOffMessage();
		end
		return;
	end
	-- While casting, the kitty is still checked: some RoM skills can be used
	-- during another cast, and the usual cooldown check decides which. Only
	-- re-targeting and autoshot wait until the cast is over.
	local casting = (UnitCastingTime("player") ~= nil);
	if(not casting) then
		if Kitty.SettingManager.setting.basic.skipTarget then
			local targetHP = UnitHealth("target") or 0
			local condition = targetHP > 0 and UnitCanAttack("player", "target")
			if not condition then
				TargetNearestEnemy()
			end
		end
		if Kitty.SettingManager.setting.basic.useAutoshot then
			Kitty.Autoshot() -- triggers autoshot if main class is ranger
		end
	end
	local mainClassName, subClassName, mainClass, subClass = Kitty.BuildManager.getClass("player");

	-- 1.7.0: Shift no longer flips request mode (that is the "request" mode now);
	-- the kitty runs as usual and "Shift is held" conditions see the key.

	local args = {...};
	if(#args > 0) then
		-- Command lists named in the call
		local commandLists = Kitty.ComboManager.selectCommandListByName(args);
		if(#commandLists == 0) then
			local str = "";
			for index, value in ipairs(args) do
				if(str ~= "") then
					str = str .. ", ";
				end
				str = str .. "[" .. value .. "]";
			end
			Kitty.sendMessage("This command list does not exist." .. str);
			return;
		end

		-- ComboManager
		local comboManager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
		for index, commandList in ipairs(commandLists) do
			local commandType, commandName = comboManager:check(commandList);
			if(commandType ~= nil) then
				comboManager:cast(commandType, commandName);
				break;
			end
		end
		-- Release
		comboManager = nil;
	else
		-- No list named: pick one by class and target
		-- Choose the command list
		local commandList, targetState = Kitty.ComboManager.selectCommandList(mainClass, subClass);
		if(commandList == nil) then
			if(Kitty.ComboManager.getTargetState() ~= "none") then
				Kitty.sendMessage(Kitty.format("This command list does not exist. MainClass:[<<1>>], SubClass[<<2>>]", tostring(mainClassName), tostring(subClassName)));
				return;
			else
				-- Negrect
			end
		else
			-- ComboManager
			local comboManager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
			local commandType, commandName = comboManager:check(commandList);
			comboManager:cast(commandType, commandName);
			-- Release
			comboManager = nil;
		end
	end
end;
Kitty.attack = Kitty.protectFunction(Kitty.attack);	-- Run protected (errors go to chat)
Kitty.Attack = Kitty.attack;	-- Alias

-- Run a kitty on another unit (Cherry's Grid: click a raid frame to run "Heal
-- kitty" on that member). Kitty.attackOn(unitId, kittyName[, keepTarget])
-- returns true when a command fired. The unit is targeted for the run and the
-- old target comes back afterwards (kept in focus slot Kitty.ATTACK_ON_FOCUS),
-- unless keepTarget is true. No "pick next target" and no autoshot here.
Kitty.ATTACK_ON_FOCUS = 12;
Kitty.attackOn = function(unitId, kittyName, keepTarget)
	if(Kitty.turnedOff or Kitty.isTurnedOff() or unitId == nil or kittyName == nil or kittyName == "") then
		return false;
	end
	-- a skill waiting for a target (ground or click cast): give it this unit
	if(type(SpellIsTargeting) == "function" and SpellIsTargeting()) then
		if(type(SpellTargetUnit) == "function") then
			SpellTargetUnit(unitId);
		end
		return true;
	end
	local commandLists = Kitty.ComboManager.selectCommandListByName({kittyName});
	if(#commandLists == 0) then
		Kitty.sendMessage("This command list does not exist.[" .. tostring(kittyName) .. "]");
		return false;
	end
	local slot = Kitty.ATTACK_ON_FOCUS;
	local hadTarget = (UnitName("target") ~= nil);
	local sameUnit = hadTarget and type(UnitIsUnit) == "function" and UnitIsUnit("target", unitId);
	if(hadTarget and not sameUnit) then
		FocusUnit(slot, "target");	-- save
	end
	if(not sameUnit) then
		TargetUnit(unitId);
	end
	local ok, fired = pcall(function()
		local comboManager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
		for _, commandList in ipairs(commandLists) do
			local commandType, commandName = comboManager:check(commandList);
			if(commandType ~= nil) then
				comboManager:cast(commandType, commandName);
				return true;
			end
		end
		return false;
	end);
	if(not sameUnit and not keepTarget) then
		if(hadTarget) then
			TargetUnit("focus" .. slot);	-- restore
		else
			TargetUnit();	-- clear
		end
	end
	if(hadTarget and not sameUnit) then
		FocusUnit(slot, "");
	end
	if(not ok) then
		Kitty.sendMessage("Kitty.attackOn: " .. tostring(fired));
		return false;
	end
	return fired and true or false;
end;

--------------------------------------------------------------------------------
-- Ranged attack
Kitty.rangeAttack = function()
	-- Read skills
	local skillManager = Kitty.SkillManager(Kitty.cooldownManager);
	skillManager:update();

	-- Ranged attack
	local skillName = nil;
	local _, _, mainClass, subClass = Kitty.BuildManager.getClass("player");
	-- Scout skills
	if(tostring(subClass) == "S") then
		if(skillManager:canCast(Kitty.T("skill", "Vampire Arrows"))) then
			skillName = Kitty.T("skill", "Vampire Arrows");
		elseif(skillManager:canCast(Kitty.T("skill", "Shooting"))) then
			skillName = Kitty.T("skill", "Shooting");
		elseif(skillManager:canCast(Kitty.T("skill", "Shot"))) then
			skillName = Kitty.T("skill", "Shot");
		end
	-- Rogue skills
	elseif(tostring(mainClass) == "R") then
		if(not Kitty.isAuthor()) then
			if(skillManager:canCast(Kitty.T("skill", "Combo Throw"))) then
				skillName = Kitty.T("skill", "Combo Throw");
			elseif(skillManager:canCast(Kitty.T("skill", "Throw"))) then
				skillName = Kitty.T("skill", "Throw");
			end
		else
			if(skillManager:canCast(Kitty.T("skill", "Kanches' Rend"))) then
				skillName = Kitty.T("skill", "Kanches' Rend");
			elseif(skillManager:canCast(Kitty.T("skill", "Phantom Stab"))) then
				skillName = Kitty.T("skill", "Phantom Stab");
			elseif(skillManager:canCast(Kitty.T("skill", "Shadow Step"))) then
				skillName = Kitty.T("skill", "Shadow Step");
			elseif(skillManager:canCast(Kitty.T("skill", "Combo Throw"))) then
				skillName = Kitty.T("skill", "Combo Throw");
			elseif(skillManager:canCast(Kitty.T("skill", "Throw"))) then
				skillName = Kitty.T("skill", "Throw");
			end
		end
	else
		Kitty.sendMessage("Unsupported class. (use is possible, only when a subclass is Scout and main class is Rogue)");
	end

	skillManager:cast(skillName);
	skillManager = nil;
end;
Kitty.rangeAttack = Kitty.protectFunction(Kitty.rangeAttack);	-- Run protected (errors go to chat)
Kitty.RangeAttack = Kitty.rangeAttack;	-- Alias
Kitty.rangeattack = Kitty.rangeAttack;	-- Alias

--------------------------------------------------------------------------------
-- Start bulk buying
Kitty.startBigShop = function()
	-- Bulk buy (Shift version of ALTdeBB)
	local overrideFunc = function(orgFunc, ...)
		if(STOREFRAME_CURRENT_TAB == "SELL") then
			local this, key = ...;
			if(key == "RBUTTON" and IsShiftKeyDown()) then
				-- Read item info
				local index = this:GetParent().index;
				local icon, name, price, moneyType, count, stock, maxHeap, secondPrice, secondMoneyType = GetStoreSellItemInfo(index);

				if(price > 0 and moneyType == 0 and secondMoneyType == 0) then
					local heap = math.floor(GetPlayerMoney("copper") / price);
					if(heap > maxHeap) then
						heap = maxHeap;
					end

					if(heap > 0) then
						StoreBuyItem(index, heap);
						Kitty.sendMessage(Kitty.T("message", "BulkPurchase", Kitty.colorCyan(name)));
						return;
					end
				end
			end
		end

		return orgFunc(...);
	end;
	-- Hook (reload safe)
	Kitty.Hooks.set("StoreItemButton_OnClick", overrideFunc);
end;
-- Stop bulk buying
Kitty.endBigShop = function()
	Kitty.Hooks.clear("StoreItemButton_OnClick");
end;
Kitty.startBigShop();

--------------------------------------------------------------------------------
-- Functions
Kitty.onVariablesChanged = function(setting)
	if(Kitty.ModeUI and Kitty.ModeUI.refresh) then
		Kitty.ModeUI.refresh();	-- "Show mode button" may have changed
	end
	if(Kitty.combatManager ~= nil) then
		-- Display settings
		Kitty.combatManager:setShowDamageDoneThreshold(setting.basic.showDamageDoneThreshold);
		Kitty.combatManager:setShowDamageTakenThreshold(setting.basic.showDamageTakenThreshold);
		Kitty.combatManager:setShowDPSType(setting.basic.showDPSType);

		-- Update party state
		Kitty.setPartyState();
	end
end;

--------------------------------------------------------------------------------
Kitty.preCastList = {
	[Kitty.T("skill", "Combat Master")] =			{["threshold"]= 0.0},
	[Kitty.T("skill", "Yawaka's Blessing")] =		{["threshold"]=20.0},
	[Kitty.T("skill", "Essence of Magic")] =		{["threshold"]=20.0},
	[Kitty.T("skill", "Enhanced Armor")] =			{["threshold"]=20.0},
	[Kitty.T("skill", "Holy Seal")] =				{["threshold"]=20.0},
	[Kitty.T("skill", "Grace of Life")] =			{["threshold"]=20.0, ["isFunc"]=function(playerBuffManager, skillManager)
																			return not playerBuffManager:hasEffect(Kitty.T("skill", "Grace of Life"));
																		end},	-- P: Grace of Life
	[Kitty.T("skill", "Angel's Blessing")] =		{["threshold"]=20.0},
	[Kitty.T("skill", "Enhanced Grace of Life")] =	{["threshold"]=20.0},
};
-- Pre-buffs (self only)
Kitty.preCast = function(playerBuffManager, skillManager)
	for skillName, element in pairs(Kitty.preCastList) do
		if(skillManager:isAvailable(skillName)) then
			if(not playerBuffManager:hasEffect(skillName, element.threshold)) then
				if(element.isFunc ~= nil) then
					if(not element.isFunc(playerBuffManager, skillManager)) then
						break;
					end
				end

				-- No buff
				if(skillManager:canCast(skillName)) then
					if(UnitIsUnit("target", "player")) then
						skillManager:cast(skillName);
					else
						Kitty.SkillManager.castTarget(skillName, "player");
					end
					return true, skillName;
				end
			end
		end
	end
	return false, "";
end;

--------------------------------------------------------------------------------
-- Help (menu)
Kitty.helpHelp = function()
	-- Supported builds
	local str = "";
	local list = Kitty.ComboManager.getSupportedClass(Kitty.SettingManager.setting.command);
	for index = 1, #list do
		if(str ~= "") then
			str = str .. ", ";
		end
		str = str .. "[" .. list[index] .. "]";
	end

	-- [Help]
	local messageType = "DEFAULT";
	Kitty.sendMessage(Kitty.T("message", "HelpTitle"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help01") .. " " .. Kitty.color("/kc help", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help02") .. " " .. Kitty.color("/kc function", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help03") .. " " .. Kitty.color("/kc macro", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help04", "/kc") .. " " .. Kitty.color("/kc RS", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help05") .. " " .. Kitty.color("/kc show", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help06") .. " " .. Kitty.color("/kc grad", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help07") .. " " .. Kitty.color("/kcg [Message]", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help08") .. " " .. Kitty.color("/kc history", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.L("HelpProbe", "Check this version against your game client:") .. " " .. Kitty.color("/kc probe", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.L("HelpReadyWindow", "How early a key press may fire a skill (seconds):") .. " " .. Kitty.color("/kc window 0.2", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Help09"), messageType, 1, 1, 1);
	Kitty.sendMessage(str, messageType, 1, 1, 1);
end;

--------------------------------------------------------------------------------
-- Help (features)
Kitty.functionHelp = function()
	-- [Main features]
	local messageType = "DEFAULT";
	Kitty.sendMessage(Kitty.T("message", "FunctionTitle"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function01") .. " " .. Kitty.color("Kitty.attack(), Kitty.rangeAttack()", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function02") .. " " .. Kitty.color("Kitty.repair()", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function03") .. " " .. Kitty.color("Kitty.checkBuff()", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function04") .. " " .. Kitty.color("Kitty.remakeParty()", 255, 255, 255), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function05"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function06"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function07"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function08"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function09"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function10"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function11"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Function12"), messageType);
end;

--------------------------------------------------------------------------------
-- Help (macros)
Kitty.macroHelp = function()
	-- [Macros]
	local messageType = "DEFAULT";
	Kitty.sendMessage(Kitty.T("message", "MacroTitle"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Macro01"), messageType);
	Kitty.sendMessage("/run Kitty.attack();", messageType, 1, 1, 1);
--	Kitty.sendMessage(Kitty.T("message", "Macro02"), messageType);
--	Kitty.sendMessage("/run Kitty.rangeAttack();" .. " " .. Kitty.colorRed(Kitty.T("message", "Macro03")), messageType, 1, 1, 1);
--	Kitty.sendMessage(Kitty.T("message", "Macro04", [[/run Kitty.attack("RangeAttack")]]), messageType, 1, 1, 1);
	Kitty.sendMessage(Kitty.T("message", "Macro05"), messageType);
	Kitty.sendMessage("/run Kitty.repair();", messageType, 1, 1, 1);
	Kitty.sendMessage(Kitty.T("message", "Macro06"), messageType);
	Kitty.sendMessage("/run Kitty.checkBuff();", messageType, 1, 1, 1);
	Kitty.sendMessage(Kitty.T("message", "Function04"), messageType);
	Kitty.sendMessage("/run Kitty.remakeParty();", messageType, 1, 1, 1);
	Kitty.sendMessage(Kitty.T("message", "Macro07"), messageType);
end;

--------------------------------------------------------------------------------
-- Help (gradient text settings)
Kitty.colorList = {
	["R"] = {["r"]=255, ["g"]=  0, ["b"]=  0},
	["G"] = {["r"]=  0, ["g"]=255, ["b"]=  0},
	["B"] = {["r"]=  0, ["g"]=  0, ["b"]=255},
	["C"] = {["r"]=  0, ["g"]=255, ["b"]=255},
	["M"] = {["r"]=255, ["g"]=  0, ["b"]=255},
	["Y"] = {["r"]=255, ["g"]=255, ["b"]=  0},
	["W"] = {["r"]=255, ["g"]=255, ["b"]=255},
	["A"] = {["r"]=128, ["g"]=128, ["b"]=128},
	["K"] = {["r"]=  0, ["g"]=  0, ["b"]=  0},
};
Kitty.messgeTypeList = {
	["SAY"] = true,
	["ZONE"] = true,
	["YELL"] = true,
	["GUILD"] = true,
	["PARTY"] = true,
	["DEFAULT"] = true,
};
Kitty.gradationHelp = function(message)
	-- Read settings
	local color = nil;
	local messageType = nil;
	if(message ~= nil and message ~= "") then
		message = string.gsub(message, " +", " ");
		message = string.trim(message);

		local list = string.split(message, " ");
		for index = 1, #list do
			if(string.lower(list[index]) == "grad") then
				-- Colors
				if(list[index+1] ~= nil and list[index+1] ~= "") then
					color = list[index+1];
				end
				-- Chat channel to send to
				if(list[index+2] ~= nil and list[index+2] ~= "") then
					messageType = list[index+2];
				end

				break;
			end
		end
	end

	if(color == nil) then
		-- No arguments: show help
		local messageType = "DEFAULT";
		-- [Gradient settings]
		Kitty.sendMessage(Kitty.T("message", "GradationTitle"), messageType);
		Kitty.sendMessage(Kitty.T("message", "Gradation01"), messageType);
		Kitty.sendMessage("/kc grad [S][E] [messageType]", messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. "Ex) /kc grad BW SAY", messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. Kitty.T("message", "Gradation02"), messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. Kitty.T("message", "Gradation03"), messageType, 1, 1, 1);
		Kitty.sendMessage("  " ..
						"R:" .. Kitty.colorRed(Kitty.T("message", "ColorRed")) .. ", " ..
						"G:" .. Kitty.colorGreen(Kitty.T("message", "ColorGreen")) .. ", " ..
						"B:" .. Kitty.colorBlue(Kitty.T("message", "ColorBlue")) .. ", " ..
						"C:" .. Kitty.colorCyan(Kitty.T("message", "ColorCyan")) .. ", " ..
						"M:" .. Kitty.colorMagenta(Kitty.T("message", "ColorMagenta")) .. ", " ..
						"Y:" .. Kitty.colorYellow(Kitty.T("message", "ColorYellow")) .. ", " ..
						"W:" .. Kitty.colorWhite(Kitty.T("message", "ColorWhite")) .. ", " ..
						"A:" .. Kitty.colorGray(Kitty.T("message", "ColorGray")) .. ", " ..
						"K:" .. Kitty.colorBlack(Kitty.T("message", "ColorBlack")), messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. Kitty.T("message", "Gradation04"), messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. Kitty.T("message", "Gradation05"), messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. "SAY、ZONE、YELL、GUILD、PARTY、DEFAULT", messageType, 1, 1, 1);
		Kitty.sendMessage("  " .. Kitty.T("message", "Gradation06"), messageType, 1, 1, 1);
		Kitty.sendMessage(Kitty.T("message", "Gradation07"), messageType);
		Kitty.sendMessage("/kcg " .. Kitty.T("message", "Gradation08"), messageType, 1, 1, 1);
		Kitty.sendMessage(Kitty.T("message", "Gradation09"), messageType);
		Kitty.sendMessage("/kcg", messageType, 1, 1, 1);
	else
		-- Arguments given: save them
		-- Colors
		local strStart = string.upper(string.sub(color, 1, 1));
		local strEnd = string.upper(string.sub(color, 2, 2));

		local startColor = Kitty.colorList[strStart];
		local endColor = Kitty.colorList[strEnd];
		if(startColor ~= nil and endColor ~= nil) then
			Kitty.SettingManager.setting.gradation.startR = startColor.r
			Kitty.SettingManager.setting.gradation.startG = startColor.g
			Kitty.SettingManager.setting.gradation.startB = startColor.b
			Kitty.SettingManager.setting.gradation.endR = endColor.r
			Kitty.SettingManager.setting.gradation.endG = endColor.g
			Kitty.SettingManager.setting.gradation.endB = endColor.b

			-- Chat channel to send to
			if(messageType ~= nil and messageType ~= "") then
				if(Kitty.messgeTypeList[string.upper(messageType)] ~= nil) then
					Kitty.SettingManager.setting.gradation.messageType = string.upper(messageType);
				else
					-- Invalid chat channel
					Kitty.sendMessage(Kitty.T("message", "NotExistChannelMessage", tostring(messageType)));
					return;
				end
			end
		else
			-- Invalid color
			Kitty.sendMessage(Kitty.T("message", "NotExistColorMessage", tostring(color)), "DEFAULT", 1, 0, 0);
			return;
		end

		-- Show the result
		if(messageType ~= nil and messageType ~= "") then
			Kitty.sendMessage(Kitty.T("message", "SettingCompleteMessage", tostring(strStart) .. tostring(strEnd), tostring(string.upper(messageType))));
		else
			Kitty.sendMessage(Kitty.T("message", "SettingCompleteMessage", tostring(strStart) .. tostring(strEnd), tostring(Kitty.SettingManager.setting.gradation.messageType)));
		end
	end
end;

--------------------------------------------------------------------------------
-- Help (change history)
Kitty.historyHelp = function()
	-- [Recent changes]
	local messageType = "DEFAULT";
	Kitty.sendMessage("[Latest main modification.]", messageType);
	Kitty.sendMessage(Kitty.color("At version:" .. tostring(Kitty.VERSION), 255, 255, 255), messageType);
	Kitty.sendMessage("- Dalaqua, 10.09.2021", messageType);	
	Kitty.sendMessage("- #Setskills over lvl 70 old classes, Warlock and Champion added with duration time", messageType);
	Kitty.sendMessage("- #Setskills some work without a shortcut and cooldown is working without condition", messageType);	
	Kitty.sendMessage("- #but, if setskill is not working use shortcut and condition use.", messageType);
	Kitty.sendMessage("- #Autoshoot function for Scout added, check or uncheck on main page if needed ", messageType);	
	Kitty.sendMessage("- #For Warden, Condition Playerpet is summond or not added to be able to use skill that work only if pet is summond  ", messageType);
	Kitty.sendMessage("- #Reworked the Info / Help messages some Infos seemed to be not so good translated, from original Japan ", messageType);
	Kitty.sendMessage("- #glued the language translations (locals) together, not finished, some help needed ", messageType);
	Kitty.sendMessage("- #Reworked the Original Skill Conditions, erased the Japan, not working and renewed the IDs, not finished ", messageType);
	Kitty.sendMessage(Kitty.color("At version:0.972", 255, 255, 255), messageType);
	Kitty.sendMessage("...", messageType);		
	Kitty.sendMessage(Kitty.color("At version:0.971", 255, 255, 255), messageType);
	Kitty.sendMessage("- targethealth and targetdebuffcounter function added", messageType);	
	Kitty.sendMessage(Kitty.color("At version:0.9xx", 255, 255, 255), messageType);
	Kitty.sendMessage("- Fixed: Bug of initialize button.", messageType);
	Kitty.sendMessage(Kitty.color("At version:0.946", 255, 255, 255), messageType);
	Kitty.sendMessage("- Show messsage when Lv75ID 5th Boss calls party menber name.", messageType);
	Kitty.sendMessage("- Changed: auto-target function is available, when pet skip function is enabled.", messageType);
	Kitty.sendMessage("- Changed: 40 durability or less equipment might be repaired. Changed high durable weapon might be repaired always.", messageType);
	Kitty.sendMessage([[- The log of area event information was displayed by "/kc event."]], messageType);
	Kitty.sendMessage("- Chagend: Pet of centaur is not targetted by pet skip function.", messageType);
	Kitty.sendMessage([[- Fixed: the issue which ToolTip does not shown when using "Kitty.attack" macro.]], messageType);
	Kitty.sendMessage([[- Added: "canUse" which is triggering conditions whether player can use shortcut item.]], messageType);
	Kitty.sendMessage("- ###Need Help### with Knight/Warrior, Knight Skill -Bestrafung- Warrior Setskill -Bestrafung- they have the same name in german  ", messageType);
	Kitty.sendMessage("- ###Need Help### Kitty always tries to take the Warrior Setskill if you play Knight  ", messageType);

	Kitty.sendMessage(Kitty.color("At version:0.929", 255, 255, 255), messageType);
	Kitty.sendMessage("- Multi-language is supported.", messageType);
	Kitty.sendMessage("- The initial value of isRequest is changed into off.", messageType);
	Kitty.sendMessage("- Ss(Warlock): The defect which could not detect [Sublimation Weave Curse] buff is revised.", messageType);
	Kitty.sendMessage("- W(Warrior): The defect which could not execute [Undefeatable King] is revised.", messageType);
	Kitty.sendMessage("- Remove guild CG limitation. Player can attack all guild in CG.", messageType);
	Kitty.sendMessage("- Add: Command List of McR, WS", messageType);

end;

--------------------------------------------------------------------------------
-- Help (area event log)
Kitty.showAreaEventLog = function(list)
	if(list and #list > 0) then
		Kitty.sendMessage(Kitty.T("message", "AreaEvent01"));
		for index, value in ipairs(list) do
			Kitty.sendMessage(value);
		end
	else
		Kitty.sendMessage(Kitty.T("message", "AreaEventMessage"));
	end
end;

--------------------------------------------------------------------------------
-- Help (command lists for a build)
Kitty.commandHelp = function(className)
	-- [Skills]
	local messageType = "DEFAULT";
	Kitty.sendMessage(Kitty.T("message", "SkillTitle"), messageType);
	Kitty.sendMessage(Kitty.T("message", "Skill01", className), messageType);
	Kitty.sendMessage(Kitty.ComboManager.showHelp(Kitty.SettingManager.setting.command, className), messageType);
end;

--------------------------------------------------------------------------------
-- Run at load
(function()
	-- Help command
	local showHelp = function(editBox, message)
		Kitty.debugPrint(editBox, message);

		local messageType = "DEFAULT";
		Kitty.sendMessage("--- " .. Kitty.getTitle() .. " --------------------", messageType, 1, 1, 1);

		if(message == nil or message == "") then
			Kitty.helpHelp();
		else
			if(string.lower(message) == "probe") then
				-- In-game checks of what the offline tests could not verify
				Kitty.Probe.report();
			elseif(string.find(string.lower(message), "^cliptest")) then
				Kitty.clipTest(string.match(message, "^%S+%s+(%d+)"));
			elseif(string.find(string.lower(message), "^clipmax")) then
				Kitty.setClipMax(string.match(message, "^%S+%s+(%d+)"));
			elseif(string.find(string.lower(message), "^interrupt")) then
				-- Players' own interrupt list: /kc interrupt add <name>
				Kitty.interruptCommand(string.match(message, "^%S+%s*(.*)$"));
			elseif(string.find(string.lower(message), "^mode$") or string.find(string.lower(message), "^mode%s")) then
				-- Pick one mode (the others turn off): /kc mode aoe, /kc mode none
				Kitty.ModeUI.command(string.match(message, "^%S+%s*(.*)$"));
			elseif(string.find(string.lower(message), "^window")) then
				-- How early a key press may fire a skill: /kc window 0.6, /kc window default
				Kitty.SkillManager.readyWindowCommand(string.match(message, "^%S+%s*(.*)$"));
			elseif(string.find(string.lower(message), "^toggle")) then
				-- Mode switches for the "Mode is on" condition: /kc toggle aoe
				Kitty.toggleMode(string.match(message, "^%S+%s+(%S+)"));
			elseif(string.find(string.lower(message), "help")) then
				Kitty.helpHelp();
			elseif(string.find(string.lower(message), "function")) then
				Kitty.functionHelp();
			elseif(string.find(string.lower(message), "macro")) then
				Kitty.macroHelp();
			elseif(string.find(string.lower(message), "grad")) then
				Kitty.gradationHelp(message);
			elseif(string.find(string.lower(message), "history")) then
				Kitty.historyHelp();
			elseif(string.find(string.lower(message), "show")) then
				if(KittyBasicConfigFrame:IsVisible()) then
					KittyBasicConfigFrame:Hide();
				else
					KittyBasicConfigFrame:Show();
					if(Kitty.SettingManager.setting.window ~= nil and Kitty.SettingManager.setting.window.showMinimap ~= nil) then
						Kitty.SettingManager.setting.window.showMinimap = true;
						Kitty.showMinimap();
					end
				end
			elseif(string.find(string.lower(message), "event")) then
				Kitty.showAreaEventLog(Kitty.areaEventList);
			elseif(string.find(string.lower(message), "date")) then
				if(os and os.date) then
					Kitty.sendMessage(os.date("%Y/%m/%d %H:%M:%S"));
				end
			else
				-- Is this a supported build?
				if(Kitty.ComboManager.isSupportedClass(Kitty.SettingManager.setting.command, message)) then
					Kitty.commandHelp(message);
				else
					Kitty.sendMessage(Kitty.T("message", "NotExistSettingMessage", message), messageType, 1, 0, 0);
				end
			end
		end
	end;
	-- Slash commands
	SLASH_KittyCombo1 = "/KittyCombo";
	SLASH_KittyCombo2 = "/kc";
	SlashCmdList["KittyCombo"] = Kitty.protectFunction(function(editBox, message)
		if(Kitty.turnedOff or Kitty.isTurnedOff()) then
			Kitty.turnedOffMessage();
			return;
		end
		showHelp(editBox, message);
	end);

	-- Gradient text command
	local showGradation = function(editBox, message)
		Kitty.debugPrint(editBox, message);

		if(message == nil or message == "") then
			-- Show the current setting
			local str = Kitty.colorGradation(Kitty.T("message", "GradationSettingMessage", Kitty.SettingManager.setting.gradation.messageType),
											Kitty.SettingManager.setting.gradation.startR,
											Kitty.SettingManager.setting.gradation.startG,
											Kitty.SettingManager.setting.gradation.startB,
											Kitty.SettingManager.setting.gradation.endR,
											Kitty.SettingManager.setting.gradation.endG,
											Kitty.SettingManager.setting.gradation.endB);
			Kitty.sendMessage(str);
		else
			local str = Kitty.colorGradation(Kitty.ComboManager.formatMessage(tostring(message)),
											Kitty.SettingManager.setting.gradation.startR,
											Kitty.SettingManager.setting.gradation.startG,
											Kitty.SettingManager.setting.gradation.startB,
											Kitty.SettingManager.setting.gradation.endR,
											Kitty.SettingManager.setting.gradation.endG,
											Kitty.SettingManager.setting.gradation.endB);
			Kitty.sendMessage(str, Kitty.SettingManager.setting.gradation.messageType);
		end
	end;
	-- Slash commands
	SLASH_KittyComboGradation1 = "/KittyComboGradation";
	SLASH_KittyComboGradation2 = "/kcg";
	SlashCmdList["KittyComboGradation"] = Kitty.protectFunction(showGradation);
end)();

--------------------------------------------------------------------------------
Kitty.foreach = function(list, func)
	for key, value in pairs(list) do
		if(func(key, value) == false) then	-- nil keeps going
			break;
		end
	end
end;
Kitty.showKeyList = function(list)
	Kitty.foreach(list, function(key, value)
		Kitty.sendMessage("[" .. tostring(key) .. "]");
	end);
end;

--------------------------------------------------------------------------------
-- For Test
Kitty.test = function(target)
	Kitty.print(Kitty.getTitle());

	if(UnitName(target) == nil) then
		target = "player";
	end

	-- Buff/debuff reader
	Kitty.buff = Kitty.BuffManager();
	Kitty.buff:update(target);
	-- Read skills
	Kitty.skill = Kitty.SkillManager(Kitty.cooldownManager);
	Kitty.skill:update();

	-- Combat tracker
	-- Party tracker
	-- Action bar slots
	-- Cooldown tracker
	-- Extra action bar
--	Kitty.extra = Kitty.ExtraAction();

	-- Combo engine
	Kitty.combo = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
end;
