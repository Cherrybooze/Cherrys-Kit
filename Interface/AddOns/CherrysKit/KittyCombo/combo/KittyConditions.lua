-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Condition types. Each condition X comes with XHelp (tooltip text), XDescribe
-- (one-line summary) and XType (which editor controls it uses); the editor and
-- the import code find conditions by this naming.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Instance methods

--------------------------------------------------------------------------------
-- Condition: Player Effect
Kitty.ComboManager.playerEffect = function(self, condition)
	local result = true;
	for index, value in ipairs(condition) do
		if(value.effectType == "name") then
			-- Name
			result = result and self.playerBuffManager:hasEffectByName(value.name, value.threshold);
		elseif(value.effectType == "id") then
			-- ID
			result = result and self.playerBuffManager:hasEffectById(value.name, value.threshold);
		elseif(value.effectType == "original") then
			-- Original
			result = result and self.playerBuffManager:hasEffect(value.name, value.threshold);
		else
			error("Invalid EffectType. EffectType:[" .. tostring(value.effectType) .. "]");
		end
	end
	return result;
end;
Kitty.ComboManager.playerEffectHelp = function(self, condition)
	local resultList = {};
	for index, value in ipairs(condition) do
		local str = "";
		if(index ~= 1) then
			str = str .. "and" .. " ";
		end

		if(value.threshold and value.threshold > 0.0) then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		elseif value.threshold == nil or value.threshold == 0 then
			str = str .. Kitty.colorCyan(value.name);
		elseif value.threshold and value.threshold < 0.0 then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration1", math.abs(value.threshold)));
		end
		table.insert(resultList, str);
	end

	if(#resultList > 1) then
		table.insert(resultList, 1, Kitty.T("message", "PlayerEffect1"));
	elseif(#resultList == 1) then
		resultList[1] = Kitty.T("message", "PlayerEffect2", resultList[1]);
	end

	return resultList;
end;
Kitty.ComboManager.playerEffectDescribe = function(self, condition)
	return {
		Kitty.T("message", "playerEffectDescription1"),
		Kitty.T("message", "playerEffectDescription2"),
		Kitty.T("message", "playerEffectDescription3"),
	};
end;
Kitty.ComboManager.playerEffectType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;
--------------------------------------------------------------------------------
-- Condition: Player Non Effect
Kitty.ComboManager.playerNonEffect = function(self, condition)
	local result = true;
	for index, value in ipairs(condition) do
		if(value.effectType == "name") then
			-- Name
			result = result and (not self.playerBuffManager:hasEffectByName(value.name, value.threshold));
		elseif(value.effectType == "id") then
			-- ID
			result = result and (not self.playerBuffManager:hasEffectById(value.name, value.threshold));
		elseif(value.effectType == "original") then
			-- Original
			result = result and (not self.playerBuffManager:hasEffect(value.name, value.threshold));
		else
			error("Invalid EffectType. EffectType:[" .. tostring(value.effectType) .. "]");
		end
	end
	return result;
end;
Kitty.ComboManager.playerNonEffectHelp = function(self, condition)
	local resultList = {};
	for index, value in ipairs(condition) do
		local str = "";
		if(index ~= 1) then
			str = str .. "and ";
		end

		if(value.threshold and value.threshold > 0.0) then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		else
			str = str .. Kitty.colorCyan(value.name);
		end
		table.insert(resultList, str);
	end

	if(#resultList > 1) then
		table.insert(resultList, 1, Kitty.T("message", "PlayerEffect3"));
	elseif(#resultList == 1) then
		resultList[1] = Kitty.T("message", "PlayerEffect4", resultList[1]);
	end

	return resultList;
end;
Kitty.ComboManager.playerNonEffectDescribe = function(self, condition)
	return {
		Kitty.T("message", "playerNonEffectDescription1"),
		Kitty.T("message", "playerNonEffectDescription2"),
		Kitty.T("message", "playerNonEffectDescription3"),
	};
end;
Kitty.ComboManager.playerNonEffectType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;
--------------------------------------------------------------------------------
-- Condition: Target Effect Counter
Kitty.ComboManager.targetEffectCounter = function(self, condition) 
	local result = false;
	local counter = 0;
	for index, value in ipairs(condition) do
		-- Stops at the first empty debuff slot (0.973 asked all 100 slots
		-- every time)
		for i=1,100,1 do
			local a,b,c,d,e = UnitDebuff("target",i);
			if(a == nil) then
				break;
			end
			local match = false;
			if(value.effectType == "name") then
				match = (a == value.name);
			elseif(value.effectType == "id") then
				match = (tonumber(d) == tonumber(value.name));
			end
			if(match and (tonumber(UnitDebuffLeftTime("target", i)) or 0) >= 0.6) then
				counter = counter + 1;
			end
		end
		if(counter >= value.threshold)
		then
			result = true;
		end
	end
	return result;
end;
Kitty.ComboManager.targetEffectCounterHelp = function(self, condition)
	local resultList = {};
	for index, value in ipairs(condition) do
		local str = "";
		if(index ~= 1) then
			str = str .. "and ";
		end

		if(value.threshold and value.threshold > 0.0) then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "StackDuration1", value.threshold));
		else
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "StackDuration2"));
			---str = str .. Kitty.colorCyan(value.name);
		end
		table.insert(resultList, str);
	end

	if(#resultList > 1) then
		table.insert(resultList, 1, Kitty.T("message", "TargetEffect1"));
	elseif(#resultList == 1) then
		resultList[1] = Kitty.T("message", "TargetEffect2", resultList[1]);
	end

	return resultList;
end;
Kitty.ComboManager.targetEffectCounterDescribe = function(self, condition)
	return {
		Kitty.T("message", "targetEffectCounterDescription1"),
		Kitty.T("message", "targetEffectCounterDescription2"),
		Kitty.T("message", "targetEffectCounterDescription3"),
	};
end;
Kitty.ComboManager.targetEffectCounterType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;
--------------------------------------------------------------------------------

-- Condition: Target Effect
Kitty.ComboManager.targetEffect = function(self, condition)
	local result = true;
	for index, value in ipairs(condition) do
		if(value.effectType == "name") then
			-- Name
			result = result and self.targetBuffManager:hasEffectByName(value.name, value.threshold);
		elseif(value.effectType == "id") then
			-- ID
			result = result and self.targetBuffManager:hasEffectById(value.name, value.threshold);
		elseif(value.effectType == "original") then
			-- Original
			result = result and self.targetBuffManager:hasEffect(value.name, value.threshold);
		else
			error("Invalid EffectType. EffectType:[" .. tostring(value.effectType) .. "]");
		end
	end
	return result;
end;
Kitty.ComboManager.targetEffectHelp = function(self, condition)
	local resultList = {};
	for index, value in ipairs(condition) do
		local str = "";
		if(index ~= 1) then
			str = str .. "and ";
		end

		if(value.threshold and value.threshold > 0.0) then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		elseif value.threshold == nil or value.threshold == 0 then
			str = str .. Kitty.colorCyan(value.name);
		elseif value.threshold and value.threshold < 0.0 then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration1", math.abs(value.threshold)));
		end
		table.insert(resultList, str);
	end

	if(#resultList > 1) then
		table.insert(resultList, 1, Kitty.T("message", "TargetEffect1"));
	elseif(#resultList == 1) then
		resultList[1] = Kitty.T("message", "TargetEffect2", resultList[1]);
	end

	return resultList;
end;
Kitty.ComboManager.targetEffectDescribe = function(self, condition)
	return {
		Kitty.T("message", "targetEffectDescription1"),
		Kitty.T("message", "targetEffectDescription2"),
		Kitty.T("message", "targetEffectDescription3"),
	};
end;
Kitty.ComboManager.targetEffectType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;

--------------------------------------------------------------------------------
-- Condition: Target Non Effect
Kitty.ComboManager.targetNonEffect = function(self, condition)
	local result = true;
	for index, value in ipairs(condition) do
		if(value.effectType == "name") then
			-- Name
			result = result and (not self.targetBuffManager:hasEffectByName(value.name, value.threshold));
		elseif(value.effectType == "id") then
			-- ID
			result = result and (not self.targetBuffManager:hasEffectById(value.name, value.threshold));
		elseif(value.effectType == "original") then
			-- Original
			result = result and (not self.targetBuffManager:hasEffect(value.name, value.threshold));
		else
			error("Invalid EffectType. EffectType:[" .. tostring(value.effectType) .. "]");
		end
	end
	return result;
end;
Kitty.ComboManager.targetNonEffectHelp = function(self, condition)
	local resultList = {};
	for index, value in ipairs(condition) do
		local str = "";
		if(index ~= 1) then
			str = str .. "and ";
		end

		if(value.threshold and value.threshold > 0.0) then
			str = str .. Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		else
			str = str .. Kitty.colorCyan(value.name);
		end
		table.insert(resultList, str);
	end

	if(#resultList > 1) then
		table.insert(resultList, 1, Kitty.T("message", "TargetEffect3"));
	elseif(#resultList == 1) then
		resultList[1] = Kitty.T("message", "TargetEffect4", resultList[1]);
	end

	return resultList;
end;
Kitty.ComboManager.targetNonEffectDescribe = function(self, condition)
	return {
		Kitty.T("message", "targetNonEffectDescription1"),
		Kitty.T("message", "targetNonEffectDescription2"),
		Kitty.T("message", "targetNonEffectDescription3"),
	};
end;
Kitty.ComboManager.targetNonEffectType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;

-- Condition: Player Health
Kitty.ComboManager.playerHealth = function(self, min, max)
	return Kitty.ClassManager.hasHealthByRate("player", min, max);
end;
Kitty.ComboManager.playerHealthHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "HP1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "HP2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "HP3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerHealthDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerHealthDescription1"),
		Kitty.T("message", "playerHealthDescription2"),
		Kitty.T("message", "playerHealthDescription3"),
	};
end;
Kitty.ComboManager.playerHealthType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerHealthMinMax = function( self )
	return 0, 100
end
-- Condition: Target Health
Kitty.ComboManager.targetHealth = function(self, min, max)
	return Kitty.ClassManager.hasHealthByRate("target", min, max);
end;
Kitty.ComboManager.targetHealthHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "HP1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "HP2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "HP3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.targetHealthDescribe = function(self, min, max)
	return {
		Kitty.T("message", "targetHealthDescription1"),
		Kitty.T("message", "targetHealthDescription2"),
		Kitty.T("message", "targetHealthDescription3"),
	};
end;
Kitty.ComboManager.targetHealthType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.targetHealthMinMax = function( self )
	return 0, 100
end
-- Condition: Player Mana
Kitty.ComboManager.playerMana = function(self, min, max)
	return Kitty.ClassManager.hasManaByRate("player", min, max);
end;
Kitty.ComboManager.playerManaHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "MP1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "MP2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "MP3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerManaDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerManaDescription1"),
		Kitty.T("message", "playerManaDescription2"),
		Kitty.T("message", "playerManaDescription3"),
	};
end;
Kitty.ComboManager.playerManaType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerManaMinMax = function( self )
	return 0, 100
end
-- Condition: Player Tension
Kitty.ComboManager.playerTension = function(self, min, max)
	return Kitty.ClassManager.hasTension("player", min, max);
end;
Kitty.ComboManager.playerTensionHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "Tension1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "Tension2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "Tension3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerTensionDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerTensionDescription1"),
		Kitty.T("message", "playerTensionDescription2"),
		Kitty.T("message", "playerTensionDescription3"),
	};
end;
Kitty.ComboManager.playerTensionType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerTensionMinMax = function( self )
	return 0, 100
end
-- Condition: Player Focus
Kitty.ComboManager.playerFocus = function(self, min, max)
	return Kitty.ClassManager.hasFocus("player", min, max);
end;
Kitty.ComboManager.playerFocusHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "Focus1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "Focus2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "Focus3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerFocusDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerFocusDescription1"),
		Kitty.T("message", "playerFocusDescription2"),
		Kitty.T("message", "playerFocusDescription3"),
	};
end;
Kitty.ComboManager.playerFocusType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerFocusMinMax = function( self )
	return 0, 200
end
-- Condition: Player Engergy
Kitty.ComboManager.playerEnergy = function(self, min, max)
	return Kitty.ClassManager.hasEnergy("player", min, max);
end;
Kitty.ComboManager.playerEnergyHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "Energy1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "Energy2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "Energy3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerEnergyDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerEnergyDescription1"),
		Kitty.T("message", "playerEnergyDescription2"),
		Kitty.T("message", "playerEnergyDescription3"),
	};
end;
Kitty.ComboManager.playerEnergyType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerEnergyMinMax = function( self )
	return 0, 100
end
-- Condition: Player PSI
Kitty.ComboManager.playerSoulPoint = function(self, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 6;
	end

	local point, _ = Kitty.ClassManager.getSoulPoint();
	if(min <= point and point <= max) then
		return true, point;
	else
		return false, point;
	end
end;
Kitty.ComboManager.playerSoulPointHelp = function(self, min, max)
	if(min == nil) then
		return Kitty.T("message", "SoulPoint1", Kitty.colorCyan(max));
	end
	if(max == nil) then
		return Kitty.T("message", "SoulPoint2", Kitty.colorCyan(min));
	end
	return Kitty.T("message", "SoulPoint3", Kitty.colorCyan(min), Kitty.colorCyan(max));
end;
Kitty.ComboManager.playerSoulPointDescribe = function(self, min, max)
	return {
		Kitty.T("message", "playerSoulPointDescription1"),
		Kitty.T("message", "playerSoulPointDescription2"),
		Kitty.T("message", "playerSoulPointDescription3"),
	};
end;
Kitty.ComboManager.playerSoulPointType = function(self, min, max)
	return Kitty.ComboManager.TYPE_NUMBER;
end;
Kitty.ComboManager.playerSoulPointMinMax = function( self )
	return 0, 6
end
-- Condition: Player Name
Kitty.ComboManager.playerName = function(self, value)
	local playerName = UnitName("player");
	if(playerName == nil) then
		return false;
	end

	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);
	for name, bool in pairs(outData) do
		if(playerName == name) then
			if(bool) then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end;
Kitty.ComboManager.playerNameHelp = function(self, value)
	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local str = "";
	for name, bool in pairs(outData) do
		if(str ~= "") then
			str = str .. ", ";
		end

		if(bool) then
			str = str .. Kitty.colorCyan(name);
		else
			str = str .. Kitty.colorCyan(name) .. Kitty.T("message", "Exception");
		end
	end
	return Kitty.T("message", "PlayerName", str);
end;
Kitty.ComboManager.playerNameDescribe = function(self, value)
	return {
		Kitty.T("message", "playerNameDescription1"),
		Kitty.T("message", "playerNameDescription2"),
		Kitty.T("message", "playerNameDescription3"),
	};
end;
Kitty.ComboManager.playerNameType = function(self, value)
	return Kitty.ComboManager.TYPE_STRING;
end;

-- Condition: Target Name
Kitty.ComboManager.targetName = function(self, value)
	local targetName = UnitName("target");
	if(targetName == nil) then
		return false;
	end

	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);
	for name, bool in pairs(outData) do
		if(targetName == name) then
			if(bool) then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end;
Kitty.ComboManager.targetNameHelp = function(self, value)
	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local str = "";
	for name, bool in pairs(outData) do
		if(str ~= "") then
			str = str .. ", ";
		end

		if(bool) then
			str = str .. Kitty.colorCyan(name);
		else
			str = str .. Kitty.colorCyan(name) .. Kitty.T("message", "Exception");
		end
	end
	return Kitty.T("message", "TargetName", str);
end;
Kitty.ComboManager.targetNameDescribe = function(self, value)
	return {
		Kitty.T("message", "targetNameDescription1"),
		Kitty.T("message", "targetNameDescription2"),
		Kitty.T("message", "targetNameDescription3"),
	};
end;
Kitty.ComboManager.targetNameType = function(self, value)
	return Kitty.ComboManager.TYPE_STRING;
end;

-- Condition: Player Is Fearless
Kitty.ComboManager.playerIsFearless = function(self, value)
	if(self.playerBuffManager:isFearless(Kitty.ClassManager.isCaster("target"))) then
		return value;
	else
		return not value;
	end
end;
Kitty.ComboManager.playerIsFearlessHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "PlayerState1", Kitty.T("message", "MatchlessState"));
	else
		return Kitty.T("message", "PlayerState2", Kitty.T("message", "MatchlessState"));
	end
end;
Kitty.ComboManager.playerIsFearlessDescribe = function(self, value)
	return {
		Kitty.T("message", "playerIsFearlessDescription1"),
		Kitty.T("message", "playerIsFearlessDescription2"),
		Kitty.T("message", "playerIsFearlessDescription3"),
	};
end;
Kitty.ComboManager.playerIsFearlessType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Target Is Fearless
Kitty.ComboManager.targetIsFearless = function(self, value)
	if(self.targetBuffManager:isFearless(Kitty.ClassManager.isCaster("player"))) then
		return value;
	else
		return not value;
	end
end;
Kitty.ComboManager.targetIsFearlessHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TargetState1", Kitty.T("message", "MatchlessState"));
	else
		return Kitty.T("message", "TargetState2", Kitty.T("message", "MatchlessState"));
	end
end;
Kitty.ComboManager.targetIsFearlessDescribe = function(self, value)
	return {
		Kitty.T("message", "targetIsFearlessDescription1"),
		Kitty.T("message", "targetIsFearlessDescription2"),
		Kitty.T("message", "targetIsFearlessDescription3"),
	};
end;
Kitty.ComboManager.targetIsFearlessType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Player Class
Kitty.ComboManager.playerClass = function(self, value)
	if(value == nil) then
		return false;
	end

	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local isExist = false;
	local orResult = false;
	local andResult = true;
	for combineClass, isTarget in pairs(outData) do
		if(isTarget) then
			-- any of
			orResult = orResult or Kitty.BuildManager.matchWithTarget("player", combineClass);
			isExist = true;
		else
			-- none of
			andResult = andResult and (not Kitty.BuildManager.matchWithTarget("player", combineClass));
		end
	end

	return ((orResult or (not isExist)) and andResult);
end;
Kitty.ComboManager.playerClassHelp = function(self, value)
	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local strTrue = "";
	local strFalse = "";
	for combineClass, isTarget in pairs(outData) do
		if(isTarget) then
			if(strTrue ~= "") then
				strTrue = strTrue .. ", ";
			end
			strTrue = strTrue .. Kitty.colorCyan(combineClass);
		else
			if(strFalse ~= "") then
				strFalse = strFalse .. ", ";
			end
			strFalse = strFalse .. Kitty.colorCyan(combineClass);
		end
	end

	-- Build the message
	if(strTrue ~= "") then
		strTrue = Kitty.T("message", "PlayerState1", strTrue);
	end
	if(strFalse ~= "") then
		strFalse = Kitty.T("message", "PlayerState2", strFalse);
	end
	-- Join the messages
	if(strTrue ~= "" and strFalse ~= "") then
		return strTrue .. " " .. strFalse;
	else
		return strTrue .. strFalse;
	end
end;
Kitty.ComboManager.playerClassDescribe = function(self, value)
	return {
		Kitty.T("message", "playerClassDescription1"),
		Kitty.T("message", "playerClassDescription2"),
		Kitty.T("message", "playerClassDescription3"),
	};
end;
Kitty.ComboManager.playerClassType = function(self, value)
	return Kitty.ComboManager.TYPE_BUILD;
end;

-- Condition: Target Class
Kitty.ComboManager.targetClass = function(self, value)
	if(value == nil) then
		return false;
	end
	if(not Kitty.ClassManager.isPC("target")) then
		return false;
	end

	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local isExist = false;
	local orResult = false;
	local andResult = true;
	for combineClass, isTarget in pairs(outData) do
		if(isTarget) then
			-- any of
			orResult = orResult or Kitty.BuildManager.matchWithTarget("target", combineClass);
			isExist = true;
		else
			-- none of
			andResult = andResult and (not Kitty.BuildManager.matchWithTarget("target", combineClass));
		end
	end

	return ((orResult or (not isExist)) and andResult);
end;
Kitty.ComboManager.targetClassHelp = function(self, value)
	-- Normalize the arguments
	local outData = Kitty.BuffManager.format(value, true);

	local strTrue = "";
	local strFalse = "";
	for combineClass, isTarget in pairs(outData) do
		if(isTarget) then
			if(strTrue ~= "") then
				strTrue = strTrue .. ", ";
			end
			strTrue = strTrue .. Kitty.colorCyan(combineClass);
		else
			if(strFalse ~= "") then
				strFalse = strFalse .. ", ";
			end
			strFalse = strFalse .. Kitty.colorCyan(combineClass);
		end
	end

	-- Build the message
	if(strTrue ~= "") then
		strTrue = Kitty.T("message", "TargetState1", strTrue);
	end
	if(strFalse ~= "") then
		strFalse = Kitty.T("message", "TargetState2", strFalse);
	end
	-- Join the messages
	if(strTrue ~= "" and strFalse ~= "") then
		return strTrue .. " " .. strFalse;
	else
		return strTrue .. strFalse;
	end
end;
Kitty.ComboManager.targetClassDescribe = function(self, value)
	return {
		Kitty.T("message", "targetClassDescription1"),
		Kitty.T("message", "targetClassDescription2"),
		Kitty.T("message", "targetClassDescription3"),
	};
end;
Kitty.ComboManager.targetClassType = function(self, value)
	return Kitty.ComboManager.TYPE_BUILD;
end;

-- Condition: Target Is PC
Kitty.ComboManager.targetIsPC = function(self, value)
	if(value== nil) then
		value = true;
	end
	if(value) then
		return Kitty.ClassManager.isPC("target");
	else
		return (not Kitty.ClassManager.isPC("target"));
	end
end;
Kitty.ComboManager.targetIsPCHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TargetState1", Kitty.colorCyan("PC"));
	else
		return Kitty.T("message", "TargetState2", Kitty.colorCyan("PC"));
	end
end;
Kitty.ComboManager.targetIsPCDescribe = function(self, value)
	return {
		Kitty.T("message", "targetIsPCDescription1"),
		Kitty.T("message", "targetIsPCDescription2"),
		Kitty.T("message", "targetIsPCDescription3"),
	};
end;
Kitty.ComboManager.targetIsPCType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Target Is Caster
Kitty.ComboManager.targetIsCaster = function(self, value)
	if(value== nil) then
		value = true;
	end
	if(value) then
		return Kitty.ClassManager.isCaster("target");
	else
		return (not Kitty.ClassManager.isCaster("target"));
	end
end;
Kitty.ComboManager.targetIsCasterHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TargetState1", Kitty.colorCyan(Kitty.T("message", "SpellCaster")));
	else
		return Kitty.T("message", "TargetState2", Kitty.colorCyan(Kitty.T("message", "SpellCaster")));
	end
end;
Kitty.ComboManager.targetIsCasterDescribe = function(self, value)
	return {
		Kitty.T("message", "targetIsCasterDescription1"),
		Kitty.T("message", "targetIsCasterDescription2"),
		Kitty.T("message", "targetIsCasterDescription3"),
	};
end;
Kitty.ComboManager.targetIsCasterType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Target Is Boss
Kitty.ComboManager.targetIsBoss = function(self, value)
	if(value== nil) then
		value = true;
	end

	if(UnitSex("target") >= 3) then
		return value;
	else
		return (not value);
	end
end;
Kitty.ComboManager.targetIsBossHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TargetState1", Kitty.colorCyan(Kitty.T("message", "KingBoss")));
	else
		return Kitty.T("message", "TargetState2", Kitty.colorCyan(Kitty.T("message", "KingBoss")));
	end
end;
Kitty.ComboManager.targetIsBossDescribe = function(self, value)
	return {
		Kitty.T("message", "targetIsBossDescription1"),
		Kitty.T("message", "targetIsBossDescription2"),
		Kitty.T("message", "targetIsBossDescription3"),
	};
end;
Kitty.ComboManager.targetIsBossType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Warden Player Pet
Kitty.ComboManager.wardenPetExists = function(self, value)
	if(value== nil) then
		value = true;
	end

	local PetExists = UnitExists("playerpet")
	if PetExists then
		return value;
	else
		return (not value);
	end
end;
Kitty.ComboManager.wardenPetExistsHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "wardenPetExistsState1", Kitty.colorCyan(Kitty.T("message", "WardenPet")));
	else
		return Kitty.T("message", "wardenPetExistsState2", Kitty.colorCyan(Kitty.T("message", "WardenPet")));
	end
end;
Kitty.ComboManager.wardenPetExistsDescribe = function(self, value)
	return {
		Kitty.T("message", "wardenPetExistsDescription1"),
		Kitty.T("message", "wardenPetExistsDescription2"),
		Kitty.T("message", "wardenPetExistsDescription3"),
	};
end;
Kitty.ComboManager.wardenPetExistsType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;


-- Condition: Target Is Dead
Kitty.ComboManager.targetIsDead = function(self, value)
	if(value== nil) then
		value = true;
	end

	if(UnitIsDeadOrGhost("target") == true) then
		return value;
	else
		return (not value);
	end
end;
Kitty.ComboManager.targetIsDeadHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TargetState1", Kitty.colorCyan(Kitty.T("message", "DeadState")));
	else
		return Kitty.T("message", "TargetState2", Kitty.colorCyan(Kitty.T("message", "DeadState")));
	end
end;
Kitty.ComboManager.targetIsDeadDescribe = function(self, value)
	return {
		Kitty.T("message", "targetIsDeadDescription1"),
		Kitty.T("message", "targetIsDeadDescription2"),
		Kitty.T("message", "targetIsDeadDescription3"),
	};
end;
Kitty.ComboManager.targetIsDeadType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Is Combat
Kitty.ComboManager.isCombat = function(self, value)
	if(value == nil) then
		value = true;
	end
	if(value) then
		return GetPlayerCombatState();
	else
		return (not GetPlayerCombatState());
	end
end;
Kitty.ComboManager.isCombatHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "OnCombat");
	else
		return Kitty.T("message", "OffCombat");
	end
end;
Kitty.ComboManager.isCombatDescribe = function(self, value)
	return {
		Kitty.T("message", "isCombatDescription1"),
		Kitty.T("message", "isCombatDescription2"),
		Kitty.T("message", "isCombatDescription3"),
	};
end;
Kitty.ComboManager.isCombatType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Is CG
Kitty.ComboManager.isCG = function(self, value)
	if(value == nil) then
		value = true;
	end
	if(value) then
		return IsBattleGroundZone();
	else
		return (not IsBattleGroundZone());
	end
end;
Kitty.ComboManager.isCGHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "OnCG");
	else
		return Kitty.T("message", "OffCG");
	end
end;
Kitty.ComboManager.isCGDescribe = function(self, value)
	return {
		Kitty.T("message", "isCGDescription1"),
		Kitty.T("message", "isCGDescription2"),
		Kitty.T("message", "isCGDescription3"),
	};
end;
Kitty.ComboManager.isCGType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Is Targeted
Kitty.ComboManager.isTargeted = function(self, value)
	if(value== nil) then
		value = true;
	end
	if(value) then
		return UnitIsUnit("player", "targettarget");
	else
		return (not UnitIsUnit("player", "targettarget"));
	end
end;
Kitty.ComboManager.isTargetedHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "Targeted");
	else
		return Kitty.T("message", "Untargeted");
	end
end;
Kitty.ComboManager.isTargetedDescribe = function(self, value)
	return {
		Kitty.T("message", "isTargetedDescription1"),
		Kitty.T("message", "isTargetedDescription2"),
		Kitty.T("message", "isTargetedDescription3"),
	};
end;
Kitty.ComboManager.isTargetedType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Can Cast
-- Each entry: value = true (default) needs the skill ready, false needs it on cooldown
Kitty.ComboManager.canCast = function(self, condition)
	for index, value in ipairs(condition) do
		local ready = self.skillManager:canCast(value.name) and true or false;
		if(ready ~= (value.value ~= false)) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.canCastHelp = function(self, condition)
	-- Entries set to false read "can NOT" (canCast true/false choice)
	local ready, notReady = "", "";
	for index, value in ipairs(condition) do
		local item;
		if(value.threshold > 0.0) then
			item = Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		else
			item = Kitty.colorCyan(value.name);
		end
		if(value.value == false) then
			notReady = (notReady ~= "" and (notReady .. ", ") or "") .. item;
		else
			ready = (ready ~= "" and (ready .. ", ") or "") .. item;
		end
	end
	local lines = {};
	if(ready ~= "" or notReady == "") then
		table.insert(lines, Kitty.T("message", "CanCast", ready));
	end
	if(notReady ~= "") then
		table.insert(lines, Kitty.L("CanNotCast", "When <<1>> is on cooldown", notReady));
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.canCastDescribe = function(self, condition)
	return {
		Kitty.T("message", "canCastDescription1"),
		Kitty.T("message", "canCastDescription2"),
		Kitty.T("message", "canCastDescription3"),
	};
end;
Kitty.ComboManager.canCastType = function(self, condition)
	return Kitty.ComboManager.TYPE_STRING_NUMBER_LIST;
end;

-- Condition: Can Use
-- Each entry: value = true (default) needs the slot ready, false needs it on cooldown
Kitty.ComboManager.canUse = function(self, condition)
	for index, value in ipairs(condition) do
		local ready = self.slotManager:canUse(value.name) and true or false;
		if(ready ~= (value.value ~= false)) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.canUseHelp = function(self, condition)
	-- Entries set to false read "can NOT" (canUse true/false choice)
	local ready, notReady = "", "";
	for index, value in ipairs(condition) do
		local item;
		if(value.threshold > 0.0) then
			item = Kitty.colorCyan(value.name .. Kitty.T("message", "OverDuration", value.threshold));
		else
			item = Kitty.colorCyan(value.name);
		end
		if(value.value == false) then
			notReady = (notReady ~= "" and (notReady .. ", ") or "") .. item;
		else
			ready = (ready ~= "" and (ready .. ", ") or "") .. item;
		end
	end
	local lines = {};
	if(ready ~= "" or notReady == "") then
		table.insert(lines, Kitty.T("message", "UsableMessage", ready));
	end
	if(notReady ~= "") then
		table.insert(lines, Kitty.L("NotUsableMessage", "When slot <<1>> is on cooldown", notReady));
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.canUseDescribe = function(self, condition)
	return {
		Kitty.T("message", "canUseDescription1"),
		Kitty.T("message", "canUseDescription2"),
		Kitty.T("message", "canUseDescription3"),
	};
end;
Kitty.ComboManager.canUseType = function(self, condition)
	return Kitty.ComboManager.TYPE_STRING_NUMBER_LIST;
end;

-- Condition: Is Two Handed
Kitty.ComboManager.isTwoHanded = function(self, value)
	if(value == nil) then
		value = true;
	end

	local isTwoHandedWeapon = nil
	if(Kitty.ClassManager.getWeaponType("player") == Kitty.ClassManager.TWO_HANDED) then
		isTwoHandedWeapon = true;
	else
		isTwoHandedWeapon = false;
	end

	if(value) then
		return isTwoHandedWeapon;
	else
		return not isTwoHandedWeapon;
	end
end;
Kitty.ComboManager.isTwoHandedHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "TwoHanded");
	else
		return Kitty.T("message", "SingleHanded");
	end
end;
Kitty.ComboManager.isTwoHandedDescribe = function(self, value)
	return {
		Kitty.T("message", "isTwoHandedDescription1"),
		Kitty.T("message", "isTwoHandedDescription2"),
		Kitty.T("message", "isTwoHandedDescription3"),
	};
end;
Kitty.ComboManager.isTwoHandedType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Is Shield
Kitty.ComboManager.isShield = function(self, value)
	if(value == nil) then
		value = true;
	end

	local isShield = nil
	if(Kitty.ClassManager.getWeaponType("player") == Kitty.ClassManager.SHIELD) then
		isShield = true;
	else
		isShield = false;
	end

	if(value) then
		return isShield;
	else
		return not isShield;
	end
end;
Kitty.ComboManager.isShieldHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "HasShield");
	else
		return Kitty.T("message", "HasNotShield");
	end
end;
Kitty.ComboManager.isShieldDescribe = function(self, value)
	return {
		Kitty.T("message", "isShieldDescription1"),
		Kitty.T("message", "isShieldDescription2"),
		Kitty.T("message", "isShieldDescription3"),
	};
end;
Kitty.ComboManager.isShieldType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Is in Range
Kitty.ComboManager.inRange = function(self, skill)
	local result = self.slotManager:inRange(skill);
	if(result ~= nil) then
		return self.slotManager:inRange(skill);
	else
		-- Not on the action bar
		SendWarningMsg(Kitty.format("Shortcut for inRange is not registered. SkillName:[<<1>>]", tostring(skill)));
		return false;
	end
end;
Kitty.ComboManager.inRangeHelp = function(self, skill)
	return Kitty.T("message", "InRange", Kitty.colorCyan(skill));
end;
Kitty.ComboManager.inRangeDescribe = function(self, skill)
	return {
		Kitty.T("message", "inRangeDescription1"),
		Kitty.T("message", "inRangeDescription2"),
		Kitty.T("message", "inRangeDescription3"),
	};
end;
Kitty.ComboManager.inRangeType = function(self, skill)
	return Kitty.ComboManager.TYPE_ACTION;
end;

-- Condition: Is Requested. 1.7.0: request mode is the mode called "request"
-- (mode button or /kc mode request); saved isRequest rows become "Mode is on:
-- request" when the settings load, this only reads codes from older versions.
Kitty.ComboManager.isRequest = function(self, value)
	if(value == nil) then
		value = true;
	end
	local on = (Kitty.Modes and Kitty.Modes.request == true);
	if(value) then
		return on;
	else
		return not on;
	end
end;
Kitty.ComboManager.isRequestHelp = function(self, value)
	if(value) then
		return Kitty.T("message", "IsRequestOn");
	else
		return Kitty.T("message", "IsRequestOff");
	end
end;
Kitty.ComboManager.isRequestDescribe = function(self, value)
	return {
		Kitty.T("message", "isRequestDescription1"),
		Kitty.T("message", "isRequestDescription2"),
		Kitty.T("message", "isRequestDescription3"),
	};
end;
Kitty.ComboManager.isRequestType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

-- Condition: Shift is held (while pressing the Kitty macro)
Kitty.ComboManager.isShiftPressed = function(self, value)
	local held = (type(IsShiftKeyDown) == "function" and IsShiftKeyDown()) and true or false;
	if(value == false) then
		return not held;
	end
	return held;
end;
Kitty.ComboManager.isShiftPressedHelp = function(self, value)
	if(value == false) then
		return Kitty.L("ShiftNotHeldHelp", "When [Shift] is not held");
	end
	return Kitty.L("ShiftHeldHelp", "When [Shift] is held");
end;
Kitty.ComboManager.isShiftPressedDescribe = function(self, value)
	return {
		Kitty.L("isShiftPressedDescription1", "yes: when I hold [Shift] while pressing the Kitty macro"),
		Kitty.L("isShiftPressedDescription2", "no: when [Shift] is not held"),
		Kitty.L("isShiftPressedDescription3", "Use it for a second set of skills on the same key"),
	};
end;
Kitty.ComboManager.isShiftPressedType = function(self, value)
	return Kitty.ComboManager.TYPE_BOOLEAN;
end;

--------------------------------------------------------------------------------
-- rom weakauras (RomWeakAuras) aura state
-- condition = {conditionType="weakaura", name=<aura name>, field=<field>, min=<number|nil>, max=<number|nil>}
-- field "true": the aura is showing, "false": it is not showing,
-- any other field: RWA.GetAuraValue(name, field) must be between min and max (a blank bound is open).
-- Condition: WeakAura
Kitty.ComboManager.WEAKAURA_FIELDS = {"true", "false", "remaining", "stacks", "percent", "value", "total", "duration"};
-- The condition type menu: a dropdown level shows at most 32 entries and there
-- are more condition types than that, so they are grouped. Types not listed
-- here land in "other".
-- Conditions added in Cherry's KittyCombo 1.6.0: interrupt list, debuff
-- stacks, recast timers and mode switches.

-- Words in a name box split at commas: "Fireball, Heal" -> {"Fireball", "Heal"}
Kitty.ComboManager.splitNames = function(text)
	local list = {};
	for part in string.gmatch(tostring(text or ""), "[^,]+") do
		part = string.gsub(part, "^%s+", "");
		part = string.gsub(part, "%s+$", "");
		if(part ~= "") then
			table.insert(list, part);
		end
	end
	return list;
end;

-- Condition: Target Is Casting
-- Each entry: name = casts separated by commas, empty = any cast on the
-- interrupt list (data/InterruptList.lua), "*" = any cast at all.
-- value = false means the target must NOT be casting it.
Kitty.ComboManager.targetCastName = function()
	if(type(UnitCastingTime) ~= "function") then
		return nil;
	end
	local name, total, elapsed = UnitCastingTime("target");
	-- A cast that just started may still be a stutter (Tirasmacros waits 0.1 s too)
	if(type(name) ~= "string" or name == "" or (tonumber(elapsed) or 0) <= 0.1) then
		return nil;
	end
	-- For /kc interrupt last
	Kitty.lastTargetCast = name;
	return name;
end;

-- The interrupt list players can change in game (/kc interrupt ...), kept in
-- KittyCombo_Setting.interrupt = {added = {[name]=true}, removed = {[name]=true}}
-- so new boss casts need no addon update.
Kitty.interruptSetting = function()
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	if(setting == nil) then
		return {added = {}, removed = {}};
	end
	if(type(setting.interrupt) ~= "table") then
		setting.interrupt = {};
	end
	setting.interrupt.added = setting.interrupt.added or {};
	setting.interrupt.removed = setting.interrupt.removed or {};
	return setting.interrupt;
end;
Kitty.isInterruptCast = function(name)
	if(name == nil) then
		return false;
	end
	local own = Kitty.interruptSetting();
	if(own.removed[name]) then
		return false;
	end
	return own.added[name] == true or (Kitty.INTERRUPT_LIST ~= nil and Kitty.INTERRUPT_LIST[name] == true);
end;
Kitty.addInterruptCast = function(name)
	local own = Kitty.interruptSetting();
	own.removed[name] = nil;
	if(not (Kitty.INTERRUPT_LIST and Kitty.INTERRUPT_LIST[name])) then
		own.added[name] = true;
	end
end;
Kitty.removeInterruptCast = function(name)
	local own = Kitty.interruptSetting();
	own.added[name] = nil;
	if(Kitty.INTERRUPT_LIST and Kitty.INTERRUPT_LIST[name]) then
		own.removed[name] = true;
	end
end;
-- /kc interrupt [add <name> | remove <name> | last | list]
Kitty.interruptCommand = function(text)
	text = tostring(text or "");
	local word, rest = string.match(text, "^%s*(%S*)%s*(.-)%s*$");
	word = string.lower(word or "");
	local function say(message)
		Kitty.sendMessage(message);
	end
	if(word == "add" and rest ~= "") then
		Kitty.addInterruptCast(rest);
		say(Kitty.L("InterruptAdded", "Added to the interrupt list: <<1>>", rest));
	elseif((word == "remove" or word == "del") and rest ~= "") then
		Kitty.removeInterruptCast(rest);
		say(Kitty.L("InterruptRemoved", "Removed from the interrupt list: <<1>>", rest));
	elseif(word == "last" or word == "target") then
		local name = Kitty.ComboManager.targetCastName();
		-- rom weakauras keeps watching casts even while no kitty runs
		if(name == nil and type(RWA) == "table" and type(RWA.LastCast) == "table" and type(RWA.LastCast.Get) == "function") then
			local ok, last = pcall(RWA.LastCast.Get, "target");
			if(ok and type(last) == "string" and last ~= "") then
				name = last;
			end
		end
		name = name or Kitty.lastTargetCast;
		if(name == nil) then
			say(Kitty.L("InterruptNoCast", "No cast seen on your target yet. Target the enemy while it casts, then try again."));
		else
			Kitty.addInterruptCast(name);
			say(Kitty.L("InterruptAdded", "Added to the interrupt list: <<1>>", name));
		end
	elseif(word == "list") then
		local own = Kitty.interruptSetting();
		local added, removed = {}, {};
		for name in pairs(own.added) do table.insert(added, name); end
		for name in pairs(own.removed) do table.insert(removed, name); end
		table.sort(added);
		table.sort(removed);
		local builtIn = 0;
		for _ in pairs(Kitty.INTERRUPT_LIST or {}) do builtIn = builtIn + 1; end
		say(Kitty.L("InterruptListInfo", "Interrupt list: <<1>> built in, yours added: <<2>>, yours removed: <<3>>",
			tostring(builtIn), (#added > 0) and table.concat(added, ", ") or "-", (#removed > 0) and table.concat(removed, ", ") or "-"));
	else
		say(Kitty.L("InterruptHelp1", "/kc interrupt last - add what your target is casting (or cast last)"));
		say(Kitty.L("InterruptHelp2", "/kc interrupt add <name> / remove <name> - change the list by name"));
		say(Kitty.L("InterruptHelp3", "/kc interrupt list - show your changes. Saved with your settings."));
	end
end;
Kitty.ComboManager.isCastMatch = function(spell, names)
	if(spell == nil) then
		return false;
	end
	local list = Kitty.ComboManager.splitNames(names);
	if(#list == 0) then
		return Kitty.isInterruptCast(spell);
	end
	for _, name in ipairs(list) do
		if(name == "*" or name == spell) then
			return true;
		end
	end
	return false;
end;
Kitty.ComboManager.targetCasting = function(self, condition)
	local spell = Kitty.ComboManager.targetCastName();
	for _, value in ipairs(condition) do
		if(Kitty.ComboManager.isCastMatch(spell, value.name) ~= (value.value ~= false)) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.targetCastingHelp = function(self, condition)
	local lines = {};
	for _, value in ipairs(condition) do
		local what;
		if(#Kitty.ComboManager.splitNames(value.name) == 0) then
			what = Kitty.L("CastFromList", "[a skill to interrupt]");
		elseif(value.name == "*") then
			what = Kitty.L("CastAny", "[anything]");
		else
			what = Kitty.colorCyan(value.name);
		end
		if(value.value == false) then
			table.insert(lines, Kitty.L("TargetNotCasting", "When [my target] is not casting <<1>>", what));
		else
			table.insert(lines, Kitty.L("TargetIsCasting", "When [my target] is casting <<1>>", what));
		end
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.targetCastingDescribe = function(self, condition)
	return {
		Kitty.L("targetCastingDescription1", "Use it to interrupt: true while the target casts one of the names."),
		Kitty.L("targetCastingDescription2", "Several names: separate them with commas. * = any cast."),
		Kitty.L("targetCastingDescription3", "Empty = the built-in [interrupt list]. Add casts: [/kc interrupt last]"),
	};
end;
Kitty.ComboManager.targetCastingType = function(self, condition)
	return Kitty.ComboManager.TYPE_STRING_NUMBER_LIST;
end;

-- Condition: Target Debuff Stacks
-- Each entry: a debuff (by name or id) with at least threshold stacks on the target
Kitty.ComboManager.targetDebuffStackCount = function(value)
	for i = 1, 100 do
		local name, icon, count, id = UnitDebuff("target", i);
		if(name == nil) then
			break;	-- no more debuffs
		end
		local match;
		if(value.effectType == "id") then
			match = (tonumber(id) == tonumber(value.name));
		else
			match = (name == value.name);
		end
		if(match) then
			return math.max(tonumber(count) or 1, 1);
		end
	end
	return 0;
end;
Kitty.ComboManager.targetDebuffStacks = function(self, condition)
	for _, value in ipairs(condition) do
		local need = math.max(tonumber(value.threshold) or 1, 1);
		if(Kitty.ComboManager.targetDebuffStackCount(value) < need) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.targetDebuffStacksHelp = function(self, condition)
	local lines = {};
	for _, value in ipairs(condition) do
		table.insert(lines, Kitty.L("DebuffStacksHelp", "When <<1>> on [my target] has [<<2>>] stacks or more",
			Kitty.colorCyan(tostring(value.name)), tostring(math.max(tonumber(value.threshold) or 1, 1))));
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.targetDebuffStacksDescribe = function(self, condition)
	return {
		Kitty.L("targetDebuffStacksDescription1", "A debuff that stacks on the target, by name or id."),
		Kitty.L("targetDebuffStacksDescription2", "The number box is how many stacks it needs at least."),
		Kitty.L("targetDebuffStacksDescription3", "(Target debuff count counts copies from different players.)"),
	};
end;
Kitty.ComboManager.targetDebuffStacksType = function(self, condition)
	return Kitty.ComboManager.TYPE_EFFECT;
end;

-- Condition: Cast In Last X Seconds
-- Each entry: name = skill, threshold = seconds. Counts casts KittyCombo made
-- (Kitty.lastCast, set by SkillManager.cast). value = false: NOT cast in that time,
-- so a damage over time skill is not cast twice while the first is on its way.
Kitty.lastCast = Kitty.lastCast or {};
Kitty.ComboManager.castWithin = function(name, seconds)
	local at = Kitty.lastCast[name];
	return (at ~= nil and (GetTime() - at) <= (tonumber(seconds) or 0));
end;
Kitty.ComboManager.castRecently = function(self, condition)
	for _, value in ipairs(condition) do
		if(Kitty.ComboManager.castWithin(value.name, value.threshold) ~= (value.value ~= false)) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.castRecentlyHelp = function(self, condition)
	local lines = {};
	for _, value in ipairs(condition) do
		local seconds = tostring(tonumber(value.threshold) or 0);
		if(value.value == false) then
			table.insert(lines, Kitty.L("NotCastRecently", "When I did not cast <<1>> in the last [<<2>>] s", Kitty.colorCyan(tostring(value.name)), seconds));
		else
			table.insert(lines, Kitty.L("CastRecentlyHelp", "When I cast <<1>> in the last [<<2>>] s", Kitty.colorCyan(tostring(value.name)), seconds));
		end
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.castRecentlyDescribe = function(self, condition)
	return {
		Kitty.L("castRecentlyDescription1", "Skill name, then seconds. Counts casts KittyCombo made."),
		Kitty.L("castRecentlyDescription2", "\"not cast\" stops a skill from being cast twice in a row,"),
		Kitty.L("castRecentlyDescription3", "for example a debuff that takes a moment to land."),
	};
end;
Kitty.ComboManager.castRecentlyType = function(self, condition)
	return Kitty.ComboManager.TYPE_STRING_NUMBER_LIST;
end;

-- Condition: Mode Is On
-- Modes are switched with /kc toggle <name> (or Kitty.toggleMode("aoe") in a
-- macro) and last until logout. Each entry: name = mode, value = false: mode off.
Kitty.Modes = Kitty.Modes or {};
Kitty.toggleMode = function(name, on)
	if(name == nil or name == "") then
		local list = {};
		for mode, state in pairs(Kitty.Modes) do
			table.insert(list, mode .. "=" .. (state and "on" or "off"));
		end
		table.sort(list);
		Kitty.sendMessage(Kitty.L("ModeList", "Modes: <<1>>. Switch one with /kc toggle aoe", (#list > 0) and table.concat(list, ", ") or "-"));
		return nil;
	end
	name = string.lower(name);
	if(on == nil) then
		on = not Kitty.Modes[name];
	end
	Kitty.Modes[name] = on and true or false;
	if(Kitty.ModeUI and Kitty.ModeUI.refresh) then
		Kitty.ModeUI.refresh();
	end
	Kitty.sendMessage(Kitty.L("ModeSwitched", "<<1>> mode: <<2>>", name, on and "|cff40ff40ON|r" or "|cffff6060OFF|r"));
	return Kitty.Modes[name];
end;
Kitty.ComboManager.modeOn = function(self, condition)
	for _, value in ipairs(condition) do
		local on = Kitty.Modes[string.lower(tostring(value.name or ""))] == true;
		if(on ~= (value.value ~= false)) then
			return false;
		end
	end
	return true;
end;
Kitty.ComboManager.modeOnHelp = function(self, condition)
	local lines = {};
	for _, value in ipairs(condition) do
		local name = Kitty.colorCyan(string.lower(tostring(value.name or "")));
		if(value.value == false) then
			table.insert(lines, Kitty.L("ModeOffHelp", "When mode <<1>> is off", name));
		else
			table.insert(lines, Kitty.L("ModeOnHelp", "When mode <<1>> is on", name));
		end
	end
	return table.concat(lines, " ");
end;
Kitty.ComboManager.modeOnDescribe = function(self, condition)
	return {
		Kitty.L("modeOnDescription1", "Pick a [mode], or [Add new mode...] and type a name"),
		Kitty.L("modeOnDescription2", "Switch with the [mode button] or [/kc mode aoe]"),
		Kitty.L("modeOnDescription3", "[/kc toggle aoe] flips one mode alone (macros too)"),
	};
end;
Kitty.ComboManager.modeOnType = function(self, condition)
	return Kitty.ComboManager.TYPE_STRING_NUMBER_LIST;
end;

-- Menu groups, in plain words for players new to the game
Kitty.ComboManager.CONDITION_GROUPS = {
	{"player", "^player", "About me"},
	{"target", "^target", "About my target"},
	{"skill / gear", {canCast=true, canUse=true, inRange=true, isShield=true, isTwoHanded=true, castRecently=true}, "Skills, items & gear"},
	{"state", {isCG=true, isCombat=true, isShiftPressed=true, isTargeted=true, wardenPetExists=true, modeOn=true}, "Combat & situation"},
};
-- Short names shown in the menu and on the row (the saved data keeps the
-- condition's code name, so kitties and share codes do not change)
Kitty.ComboManager.CONDITION_LABELS = {
	weakaura = "WeakAura state",
	playerEffect = "I have a buff",
	playerNonEffect = "I lack a buff",
	playerHealth = "My HP %",
	playerMana = "My mana %",
	playerTension = "My rage",
	playerFocus = "My focus",
	playerEnergy = "My energy",
	playerSoulPoint = "My soul points",
	playerName = "My name",
	playerIsFearless = "I am immune",
	playerClass = "My class",
	targetEffect = "Target has a buff",
	targetNonEffect = "Target lacks a buff",
	targetEffectCounter = "Target debuff count",
	targetDebuffStacks = "Target debuff stacks",
	targetHealth = "Target HP %",
	targetName = "Target name",
	targetIsFearless = "Target is immune",
	targetClass = "Target class",
	targetIsPC = "Target is a player",
	targetIsCaster = "Target is a caster",
	targetIsBoss = "Target is a boss",
	targetIsDead = "Target is dead",
	targetCasting = "Target is casting",
	wardenPetExists = "Warden pet is out",
	isCombat = "In combat",
	isCG = "In guild castle",
	isRequest = "Request mode (old)",
	isShiftPressed = "Shift is held",
	isTargeted = "An enemy targets me",
	canCast = "Skill is ready",
	canUse = "Item is ready",
	castRecently = "Cast in last X sec",
	inRange = "Skill in range",
	isTwoHanded = "Two-handed weapon",
	isShield = "Shield equipped",
	modeOn = "Mode is on",
	func = "Lua code (advanced)",
};
Kitty.ComboManager.conditionLabel = function(conditionType)
	if(conditionType == nil or conditionType == "") then
		return "";
	end
	local english = Kitty.ComboManager.CONDITION_LABELS[conditionType];
	if(english == nil) then
		return conditionType;
	end
	return Kitty.L("Condition_" .. conditionType, english);
end;
-- Back from what the menu shows to the code name (code names still work)
Kitty.ComboManager.conditionFromLabel = function(text)
	if(text == nil or text == "") then
		return text;
	end
	if(Kitty.ComboManager[text .. "Type"] ~= nil) then
		return text;
	end
	for conditionType, _ in pairs(Kitty.ComboManager.CONDITION_LABELS) do
		if(Kitty.ComboManager.conditionLabel(conditionType) == text) then
			return conditionType;
		end
	end
	return text;
end;
-- Still read, no longer offered: request mode is now a mode
Kitty.ComboManager.HIDDEN_CONDITIONS = {isRequest = true};
local function labelEntry(name)
	return {value = name, text = Kitty.ComboManager.conditionLabel(name)};
end
Kitty.ComboManager.getConditionMenu = function()
	local names = {};
	for name, _ in pairs(Kitty.ComboManager.createFunctionList()) do
		if(name ~= "weakaura" and not Kitty.ComboManager.HIDDEN_CONDITIONS[name]) then
			table.insert(names, name);
		end
	end
	local function byLabel(a, b)
		return Kitty.ComboManager.conditionLabel(a) < Kitty.ComboManager.conditionLabel(b);
	end
	table.sort(names, byLabel);
	local level1, level2, used = {labelEntry("weakaura")}, {false}, {};
	for _, group in ipairs(Kitty.ComboManager.CONDITION_GROUPS) do
		local list = {};
		for _, name in ipairs(names) do
			local rule = group[2];
			local match = (type(rule) == "string" and string.find(name, rule) ~= nil) or (type(rule) == "table" and rule[name]);
			if(match and not used[name]) then
				used[name] = true;
				table.insert(list, labelEntry(name));
			end
		end
		if(#list > 0) then
			table.insert(level1, {value = group[1], text = Kitty.L("ConditionGroup_" .. string.gsub(group[1], "[^%w]", ""), group[3])});
			table.insert(level2, list);
		end
	end
	local other = {};
	for _, name in ipairs(names) do
		if(not used[name]) then
			table.insert(other, labelEntry(name));
		end
	end
	if(#other > 0) then
		table.insert(level1, {value = "other", text = Kitty.L("ConditionGroup_other", "Other")});
		table.insert(level2, other);
	end
	return level1, level2;
end;
Kitty.ComboManager.isWeakAuraLoaded = function()
	return (type(RWA) == "table" and type(RWA.IsAuraActive) == "function");
end;
-- Aura names in /rwa order, or an empty list when rom weakauras is not loaded
Kitty.ComboManager.getWeakAuraNames = function()
	if(Kitty.ComboManager.isWeakAuraLoaded() and type(RWA.GetAuraIds) == "function") then
		local ok, list = pcall(RWA.GetAuraIds);
		if(ok and type(list) == "table") then
			return list;
		end
	end
	return {};
end;
Kitty.ComboManager.weakauraWarned = false;
Kitty.ComboManager.weakaura = function(self, condition)
	if(not Kitty.ComboManager.isWeakAuraLoaded()) then
		if(not Kitty.ComboManager.weakauraWarned) then
			Kitty.ComboManager.weakauraWarned = true;
			Kitty.sendMessage(Kitty.L("WeakAuraMissing", "Cherry's KittyCombo: a command uses a weakAura condition, but rom weakauras is not loaded. Those commands are skipped."), "DEFAULT", 1, 0.5, 0);
		end
		return false;
	end
	local name = condition.name;
	if(name == nil or name == "") then
		return false;
	end
	-- A deleted or renamed aura never matches, not even with "false"
	if(type(RWA_DB) == "table" and type(RWA_DB.auras) == "table" and RWA_DB.auras[name] == nil) then
		return false;
	end
	local field = condition.field or "true";
	if(field == "true") then
		return (RWA.IsAuraActive(name) == true);
	elseif(field == "false") then
		return (RWA.IsAuraActive(name) ~= true);
	end

	local value = nil;
	if(type(RWA.GetAuraValue) == "function") then
		value = RWA.GetAuraValue(name, field);
	end
	if(type(value) ~= "number") then
		return false;
	end
	if(condition.min ~= nil and value < condition.min) then
		return false;
	end
	if(condition.max ~= nil and value > condition.max) then
		return false;
	end
	return true;
end;
Kitty.ComboManager.weakauraHelp = function(self, condition)
	condition = condition or {};
	local name = Kitty.colorCyan(tostring(condition.name or "?"));
	local field = condition.field or "true";
	if(field == "true") then
		return Kitty.L("WeakAuraHelpTrue", "When aura <<1>> is showing", name);
	elseif(field == "false") then
		return Kitty.L("WeakAuraHelpFalse", "When aura <<1>> is not showing", name);
	end
	local fieldText = Kitty.colorCyan(field);
	if(condition.min == nil and condition.max == nil) then
		return Kitty.L("WeakAuraHelpAny", "When aura <<1>> has a <<2>>", name, fieldText);
	elseif(condition.min == nil) then
		return Kitty.L("WeakAuraHelpMax", "When aura <<1>> <<2>> is <<3>> or less", name, fieldText, Kitty.colorCyan(condition.max));
	elseif(condition.max == nil) then
		return Kitty.L("WeakAuraHelpMin", "When aura <<1>> <<2>> is <<3>> or more", name, fieldText, Kitty.colorCyan(condition.min));
	end
	return Kitty.L("WeakAuraHelpRange", "When aura <<1>> <<2>> is <<3>> to <<4>>", name, fieldText, Kitty.colorCyan(condition.min), Kitty.colorCyan(condition.max));
end;
Kitty.ComboManager.weakauraDescribe = function(self, condition)
	return {
		Kitty.L("weakAuraDescription1", "Uses an aura you made in rom weakauras (/rwa)."),
		Kitty.L("weakAuraDescription2", "true / false: the aura is / is not showing."),
		Kitty.L("weakAuraDescription3", "remaining, stacks, percent, value, total, duration: the number must be between min and max (leave one blank for no limit)."),
	};
end;
Kitty.ComboManager.weakauraType = function(self, condition)
	return Kitty.ComboManager.TYPE_WEAKAURA;
end;

--------------------------------------------------------------------------------
Kitty.ComboManager.func = function(self, func)
	if(func ~= nil) then
		return func(self.targetBuffManager, self.playerBuffManager, self.skillManager);
	end
end;
Kitty.ComboManager.funcHelp = function(self, func)
	return Kitty.T("message", "SpecialState");
end;
Kitty.ComboManager.funcDescribe = function(self, func)
	return {
		Kitty.T("message", "funcDescription1"),
		Kitty.T("message", "funcDescription2"),
		Kitty.T("message", "funcDescription3"),
	};
end;
Kitty.ComboManager.funcType = function(self, func)
	return Kitty.ComboManager.TYPE_OTHER;
end;
