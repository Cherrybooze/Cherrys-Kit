-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Damage totals, DPS report and combat start/end.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Damage tracker
Kitty.DamageManager = {};
-- Instance methods
-- Combat started
Kitty.DamageManager.onStartCombat = function(self)
	if(self.showDPSType == "Detail" or self.showDPSType == "Normal") then
		Kitty.sendMessage(Kitty.T("message", "StartCombatMessage"), "DEFAULT", 1, 1, 1);
	end
end;
-- Combat ended
Kitty.DamageManager.onEndCombat = function(self, term)
	if(self.showDPSType == "Detail" or self.showDPSType == "Normal") then
		Kitty.sendMessage(
			Kitty.T("message", "EndCombatMessage", Kitty.colorYellow(string.format("%.2f", term))),
		"DEFAULT", 1, 1, 1);
	end

	if(term <= 1.0) then
		-- Avoid dividing by a tiny time
		term = 1.0;
	end

	-- Output
	local allDamage = 0;
	-- Total damage
	for _, list in pairs(self.damageTable) do
		allDamage = allDamage + list.totalDamage;
	end

	if(self.showDPSType == "Detail") then
		-- Detailed DPS report
		Kitty.sendMessage(Kitty.T("message", "DPSHeader"), "DEFAULT", 1, 1, 1);

		for key, list in pairs(self.damageTable) do
			local totalAverage = 0.0;
			if(list.totalCount ~= 0) then
				totalAverage = list.totalDamage / list.totalCount;
			end
			local normalAverage = 0.0;
			if(list.normalCount ~= 0) then
				normalAverage = list.normalDamage / list.normalCount;
			end
			local criticalAverage = 0.0;
			if(list.criticalCount ~= 0) then
				criticalAverage = list.criticalDamage / list.criticalCount;
			end
			local criticalDamageRate = 0.0;
			if(normalAverage ~= 0) then
				criticalDamageRate = criticalAverage / normalAverage;
			end

			Kitty.sendMessage(
				Kitty.T("message", "DPSDetail1",
					Kitty.colorYellow(key .. "(" .. string.format("%.2f", list.totalDamage/allDamage * 100.0) .. ")" .. "%"),
					Kitty.colorYellow(Kitty.comma(totalAverage) .. "(" .. Kitty.comma(normalAverage) .. ":" .. Kitty.comma(criticalAverage) .. ")"),
					Kitty.colorYellow(tostring(list.totalCount) .. "(" .. tostring(list.normalCount) .. ":" .. tostring(list.criticalCount) .. ")"),
					Kitty.colorYellow(string.format("%.2f", list.criticalCount/list.totalCount * 100.0)),
					Kitty.colorYellow(string.format("%.2f", criticalDamageRate))
				),
			"DEFAULT", 1, 1, 1);
		end
	end

	if(self.showDPSType == "Detail" or self.showDPSType == "Normal") then
		-- DPS report
		Kitty.sendMessage(
			Kitty.T("message", "DPSDetail2",
				Kitty.colorYellow(Kitty.comma(allDamage/term)),
				Kitty.colorYellow(Kitty.comma(allDamage))
			),
		"DEFAULT", 1, 1, 1);
	end

	-- Clear
--	self.damageTable = {};
	for key, _ in pairs(self.damageTable) do
		self.damageTable[key] = nil;
	end
end;
-- Damage event
Kitty.DamageManager.onDamage = function(self, sourceName, targetName, damage, skillName, damageType)
	local playerName = UnitName("player");
	local isMine = (playerName == sourceName);
	local isOnMe = (playerName == targetName);
	if(not isMine and not isOnMe) then
		-- Party members' and pets' hits: nothing to total or show
		return;
	end

	-- Accumulate (only needed for the DPS report)
	if(isMine and self.showDPSType ~= "None") then
		local normalCount = 0;
		local normalDamage = 0;
		if(damageType == "NORMAL") then
			normalCount = 1;
			normalDamage = damage;
		end
		local criticalCount = 0;
		local criticalDamage = 0;
		if(damageType == "CRITIAL" or damageType == "CRITICAL") then	-- The client spells it both ways
			damageType = "CRITICAL";
			criticalCount = 1;
			criticalDamage = damage;
		end

		if(self.damageTable[skillName] == nil) then
			-- Add
			-- Skill, hits, total damage, normal hits, critical hits
			self.damageTable[skillName] = {["skill"]=skillName};
		end
		-- Update
		self.damageTable[skillName].totalDamage = (self.damageTable[skillName].totalDamage or 0) + damage;
		self.damageTable[skillName].normalDamage = (self.damageTable[skillName].normalDamage or 0) + normalDamage;
		self.damageTable[skillName].criticalDamage = (self.damageTable[skillName].criticalDamage or 0) + criticalDamage;
		self.damageTable[skillName].totalCount = (self.damageTable[skillName].totalCount or 0) + 1;
		self.damageTable[skillName].normalCount = (self.damageTable[skillName].normalCount or 0) + normalCount;
		self.damageTable[skillName].criticalCount = (self.damageTable[skillName].criticalCount or 0) + criticalCount;
	end

	local currentTime = Kitty.getTime();
	local strDamage = nil;

	-- Show damage done
	if(isMine
	and self.showDamageDoneThreshold > 0	-- 0 = off
	and damage >= self.showDamageDoneThreshold
	and skillName ~= "ATTACK") then

		-- Time since the last one
		local diffTime = currentTime - self.lastAttackTime;
		self.lastAttackTime = currentTime;

		-- Color
		if(skillName == Kitty.T("skill", "Wound Attack")) then
			skillName = Kitty.colorCyan(skillName);
		else
			skillName = "[" .. skillName .. "]";
		end
		-- Color
		if(damageType == "CRITICAL") then
			-- Critical
			strDamage = Kitty.color(Kitty.comma(damage), 0, 128, 255);
			damageType = Kitty.color("(" .. damageType .. ")", 0, 128, 255);
		elseif(damageType ~= "NORMAL" and damageType ~= "DOUBLE") then
			-- Miss
			strDamage = Kitty.color(Kitty.comma(damage), 128, 128, 128);
			damageType = Kitty.color("(" .. damageType .. ")", 128, 128, 128);
		else
			-- Normal
			strDamage = Kitty.comma(damage);
			damageType = "(" .. damageType .. ")";
		end

		Kitty.sendMessage(
			Kitty.T("message", "DPSDetail3",
				Kitty.color(string.format("%.2f", diffTime), 0, 128, 255),
				"[" .. sourceName .. "]",
				"[" .. targetName .. "]",
				strDamage,
				skillName,
				damageType
			)
		);
	end

	-- Damage taken
	if(isOnMe
	and self.showDamageTakenThreshold > 0	-- 0 = off
	and damage >= self.showDamageTakenThreshold) then

		-- Time since the last one
		local diffTime = currentTime - self.lastDamageTime;
		self.lastDamageTime = currentTime;

		-- Color
		if(damageType == "DODGE") then
			-- Miss
			strDamage = Kitty.color(Kitty.comma(damage), 128, 128, 128);
			damageType = Kitty.color("(" .. damageType .. ")", 128, 128, 128);
		else
			-- Normal
			strDamage = Kitty.color(Kitty.comma(damage), 255, 0, 0);
			damageType = Kitty.color("(" .. damageType .. ")", 255, 0, 0);
		end

		Kitty.sendMessage(
			Kitty.T("message", "DPSDetail3",
				Kitty.color(string.format("%.2f", diffTime), 0, 128, 255),
				"[" .. sourceName .. "]",
				"[" .. targetName .. "]",
				strDamage,
				"[" .. skillName .. "]",
				damageType
			)
		);
	end
end;
Kitty.DamageManager.setShowDamageDoneThreshold = function(self, threshold)
	threshold = tonumber(threshold);
	if(threshold ~= nil) then
		self.showDamageDoneThreshold = threshold;
	else
		self.showDamageDoneThreshold = 0;
	end
end;
Kitty.DamageManager.setShowDamageTakenThreshold = function(self, threshold)	-- 0 = off
	threshold = tonumber(threshold);
	if(threshold ~= nil) then
		self.showDamageTakenThreshold = threshold;
	else
		self.showDamageTakenThreshold = 0;
	end
end;
Kitty.DamageManager.setShowDPSType = function(self, showDPSType)	-- "None", "Normal", "Detail"
	self.showDPSType = showDPSType;
end;
-- Constructor
Kitty.DamageManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.damageTable = {};
	obj.lastAttackTime = 0.0;
	obj.lastDamageTime = 0.0;
	-- Display settings
	obj.showDamageDoneThreshold = 10000;
	obj.showDamageTakenThreshold = 1000;
	obj.showDPSType = "Normal";

	return setmetatable(obj, {__index=Kitty.DamageManager});
end;
setmetatable(Kitty.DamageManager, {__call=Kitty.DamageManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Combat tracker
Kitty.CombatManager = {};
-- Instance methods
-- Detect combat start
Kitty.CombatManager.onChatMessageCombat = function(self, combatMessage)
	if(self.combatStartKeyword == nil) then
		self.combatStartKeyword = Kitty.T("keyword", "CombatStartMessage");
	end
	if(string.find(combatMessage, self.combatStartKeyword)) then
		if(not self.isCombatFlag) then
			-- Combat starts
			self.isCombatFlag = true;
			self.firstCombatTime = Kitty.getTime();
			self.damageManager:onStartCombat();
		end
		self.lastCombatTime = Kitty.getTime();
	end
end;
-- Detect combat end
Kitty.CombatManager.onUpdate = function(self, currentTime)
	if(self.isCombatFlag) then
		if(currentTime - self.lastCombatTime > 5.0) then
			-- Combat ends
			self.isCombatFlag = false;
			self.damageManager:onEndCombat(self.lastCombatTime - self.firstCombatTime);
		end
	end
end;
-- Damage during combat
Kitty.CombatManager.onCombatmeterDamage = function(self, sourceName, targetName, damage, skillName, damageType)
	self.damageManager:onDamage(sourceName, targetName, damage, skillName, damageType);
end;
-- In combat? (differs from GetPlayerCombatState())
Kitty.CombatManager.isCombat = function(self)
	return self.isCombatFlag;
end;
Kitty.CombatManager.setShowDamageDoneThreshold = function(self, threshold)
	self.damageManager:setShowDamageDoneThreshold(threshold);
end;
Kitty.CombatManager.setShowDamageTakenThreshold = function(self, threshold)	-- 0 = off
	self.damageManager:setShowDamageTakenThreshold(threshold);
end;
Kitty.CombatManager.setShowDPSType = function(self, showDPSType)	-- "None", "Normal", "Detail"
	self.damageManager:setShowDPSType(showDPSType);
end;
-- Constructor
Kitty.CombatManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.damageManager = Kitty.DamageManager();
	obj.isCombatFlag = false;
	obj.firstCombatTime = 0.0;
	obj.lastCombatTime = 0.0;

	return setmetatable(obj, {__index=Kitty.CombatManager});
end;
setmetatable(Kitty.CombatManager, {__call=Kitty.CombatManager.constructor});	-- Calling the class makes an instance
