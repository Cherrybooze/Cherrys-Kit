-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Builds (main/sub class) and class helpers.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Builds (main/sub class)
Kitty.BuildManager = {};
Kitty.BuildManager.combineList = nil;
Kitty.BuildManager.groupedList = nil;
Kitty.BuildManager.classList = {
	["KNIGHT"] = "K",	-- Knight
	["WARRIOR"] = "W",	-- Warrior
	["THIEF"] = "R",	-- Rogue
	["RANGER"] = "S",	-- Scout
	["MAGE"] = "M",		-- Mage
	["AUGUR"] = "P",	-- Priest
	["WARDEN"] = "Wd",	-- Warden
	["DRUID"] = "D",	-- Druid
	["PSYRON"] = "Mc",	-- Champion
	["HARPSYN"] = "Ss",	-- Warlock
};
-- ["RS"] = {"R", "S"}
-- ["WdD"] = {"Wd", "D"}
-- ["K"] = {"K", ""}
-- ["/K"] = {"", "K"}
-- Build the tables
Kitty.BuildManager.createCombineList = function(inList)
	local outList = {};
	if(inList) then
		-- Build the table
		for _, mainClass in pairs(inList) do
			-- Mixed
			for _, subClass in pairs(inList) do
				if(mainClass ~= subClass) then
					outList[mainClass .. subClass] = {mainClass, subClass};
				end
			end

			-- Main
			outList[mainClass] = {mainClass, ""};
			-- Sub
			outList["/" .. mainClass] = {"", mainClass};
		end
	end
	return outList;
end;
Kitty.BuildManager.createGroupedList = function(classList, combineList)
	local outList = {};
	if(classList) then
		-- Group
		for _, initial in pairs(classList) do
			outList[initial] = {};
		end
	end

	if(combineList) then
		for key, value in pairs(combineList) do
			local main = value[1];
			local sub = value[2];

			if(main ~= "") then
				table.insert(outList[main], main .. sub);
			else
				table.insert(outList[sub], main .. "/" .. sub);
			end
		end

		-- Sort
		for key, value in pairs(outList) do
			table.sort(value);
		end
	end
	return outList;
end;
Kitty.BuildManager.getGroupedList = function()
	if(not Kitty.BuildManager.groupedList) then
		if(not Kitty.BuildManager.combineList) then
			-- Build the list
			Kitty.BuildManager.combineList = Kitty.BuildManager.createCombineList(Kitty.BuildManager.classList);
		end
		-- Build the list
		Kitty.BuildManager.groupedList = Kitty.BuildManager.createGroupedList(Kitty.BuildManager.classList, Kitty.BuildManager.combineList);
	end
	return Kitty.BuildManager.groupedList;
end;
-- Get the class
Kitty.BuildManager.getClass = function(target)
	if(UnitName(target) ~= nil) then
		local mainClass, subClass = UnitClass(target);
		local mainToken, subToken = UnitClassToken(target);

		return
			tostring(mainClass), tostring(subClass),
			Kitty.BuildManager.classList[mainToken] or "", Kitty.BuildManager.classList[subToken] or "";
	else
		return "";
	end
end;
-- Split a class string
Kitty.BuildManager.splitClass = function(combineClass)
	-- "RWd", "R/Wd", "/Wd", "*Wd", "_Wd", " Wd"
	-- Use "/" as the separator
	combineClass = string.gsub(combineClass, "[*_ ]", "/");
	-- Remove separators except a leading one
	combineClass = string.gsub(combineClass, "^(%w+)/(%w-)", "%1%2");

	if(not Kitty.BuildManager.combineList) then
		-- Build the list
		Kitty.BuildManager.combineList = Kitty.BuildManager.createCombineList(Kitty.BuildManager.classList);
	end
	local resultArray = Kitty.BuildManager.combineList[combineClass];
	if(resultArray ~= nil) then
		return unpack(resultArray);
	else
		return nil;
	end
end;
-- Kitty.BuildManager.match(actual class, pattern)
Kitty.BuildManager.match = function(className1, className2)	-- ("RK", "R")->ture, ("R", "RK")->false
	if(className1 == "proc" or className2 == "proc") then
		return false;
	end
	if(className1 == "any" or className2 == "any") then
		return true;
	end

	local main1, sub1 = Kitty.BuildManager.splitClass(className1);
	local main2, sub2 = Kitty.BuildManager.splitClass(className2);

	-- Compare main class
	if(main1 ~= "" and main2 ~= "") then
		if(main1 ~= main2) then
			return false;
		end
	end
	-- Compare sub class
	if(sub1 ~= "" and sub2 ~= "") then
		if(sub1 ~= sub2) then
			return false;
		end
	end
	if(sub1 == "" and sub2 ~= "") then
		return false;
	end

	-- Only one side given: false
	if(main1 == "" and sub2 == "") then
		return false;
	end
	if(sub1 == "" and main2 == "") then
		return false;
	end

	return true;
end;
-- Kitty.BuildManager.matchWithTarget(unit, pattern)
Kitty.BuildManager.matchWithTarget = function(unit, pattern)
	local _, _, mainClass, subClass = Kitty.BuildManager.getClass(unit);
	return Kitty.BuildManager.match(mainClass .. subClass, pattern);
end;
-- Instance methods
Kitty.BuildManager.getMain = function(self)
	return self.main;
end;
Kitty.BuildManager.getSub = function(self)
	return self.sub;
end;
-- String form
Kitty.BuildManager.toString = function(self)
	return self.main .. "/" .. self.sub;
end;
-- Constructor
Kitty.BuildManager.constructor = function(self, main, sub)
	-- Fields
	local obj = {};
	obj.main = "";
	obj.sub = "";

	if(sub) then
		-- No split needed
		if(main) then
			obj.main = main;
		end
		obj.sub = sub;
	else
		-- Split needed
		main, sub = Kitty.BuildManager.splitClass(main);
		if(main) then
			obj.main = main;
			obj.sub = sub;
		end
	end

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.BuildManager, __tostring=Kitty.BuildManager.toString});
end;
setmetatable(Kitty.BuildManager, {__call=Kitty.BuildManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Class helpers
Kitty.ClassManager = {};
Kitty.ClassManager.TWO_HANDED = "TwoHanded";
Kitty.ClassManager.SHIELD = "Shield";
Kitty.ClassManager.DOUBLE = "Double";
Kitty.ClassManager.UNKNOWN = "Unknown";
-- Unit type
Kitty.ClassManager.isPC = function(target)
	if(UnitName(target) ~= nil) then
		if(UnitIsPlayer(target)) then
			return true;
		end
	end
	return false;
end;
Kitty.ClassManager.isCaster = function(target)
	if(Kitty.ClassManager.isPC(target)) then
		local _, _, mainClass, subClass = Kitty.BuildManager.getClass(target);
		if(mainClass == "M" or mainClass == "P"
		or mainClass == "D" or mainClass == "Ss") then
			return true;
		end
	end
	return false;
end;

-- Health
Kitty.ClassManager.getHealth = function(target)
	if(UnitName(target) ~= nil) then
		-- UnitHealth/UnitMaxHealth return points for players and a percentage for NPCs.
		return UnitHealth(target), UnitMaxHealth(target), UnitHealth(target) / UnitMaxHealth(target) * 100;
	else
		return 0;
	end
end;
Kitty.ClassManager.hasHealth = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = Kitty.MAX_VALUE;
	end

	local value = Kitty.ClassManager.getHealth(target);
	if(min <= value and value <= max) then
		return true, value;
	else
		return false, value;
	end
end;
Kitty.ClassManager.hasHealthByRate = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 100;
	end

	local _, _, healthRate = Kitty.ClassManager.getHealth(target);
	if not healthRate then
		return
	end
	if(min <= healthRate and healthRate <= max) then
		return true, healthRate;
	else
		return false, healthRate;
	end
end;
-- Mana (knight, mage, priest, druid)
Kitty.ClassManager.getMana = function(target)
	if(UnitName(target) ~= nil) then
		if(UnitManaType(target) == 1) then
			-- Main class
			if(UnitMaxMana(target) > 0) then
				return UnitMana(target), UnitMaxMana(target), UnitMana(target) / UnitMaxMana(target) * 100;
			else
				return UnitMana(target), UnitMaxMana(target), 0;
			end
		elseif(UnitSkillType(target) == 1) then
			-- Sub class
			if(UnitMaxSkill(target) > 0) then
				return UnitSkill(target), UnitMaxSkill(target), UnitSkill(target) / UnitMaxSkill(target) * 100;
			else
				return UnitSkill(target), UnitMaxSkill(target), 0;
			end
		end
	end
	return 0;
end;
Kitty.ClassManager.hasMana = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = Kitty.MAX_VALUE;
	end

	local value = Kitty.ClassManager.getMana(target);
	if(min <= value and value <= max) then
		return true, value;
	else
		return false, value;
	end
end;
Kitty.ClassManager.hasManaByRate = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 100;
	end

	local _, _, manaRate = Kitty.ClassManager.getMana(target);
	if(min <= manaRate and manaRate <= max) then
		return true, manaRate;
	else
		return false, manaRate;
	end
end;
-- Rage (warrior, warden, champion)
Kitty.ClassManager.getTension = function(target)
	if(UnitName(target) ~= nil) then
		if(UnitManaType(target) == 2) then
			-- Main class
			return UnitMana(target);
		elseif(UnitSkillType(target) == 2) then
			-- Sub class
			return UnitSkill(target);
		end
	end
	return 0;
end;
Kitty.ClassManager.hasTension = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 100;
	end

	local value = Kitty.ClassManager.getTension(target);
	if(min <= value and value <= max) then
		return true, value;
	else
		return false, value;
	end
end;
-- Focus (scout, warlock)
Kitty.ClassManager.getFocus = function(target)
	if(UnitName(target) ~= nil) then
		if(UnitManaType(target) == 3) then
			-- Main class
			return UnitMana(target);
		elseif(UnitSkillType(target) == 3) then
			-- Sub class
			return UnitSkill(target);
		end
	end
	return 0;
end;
Kitty.ClassManager.hasFocus = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 100;
	end

	local value = Kitty.ClassManager.getFocus(target);
	if(min <= value and value <= max) then
		return true, value;
	else
		return false, value;
	end
end;
-- Energy (rogue)
Kitty.ClassManager.getEnergy = function(target)
	if(UnitName(target) ~= nil) then
		if(UnitManaType(target) == 4) then
			-- Main class
			return UnitMana(target);
		elseif(UnitSkillType(target) == 4) then
			-- Sub class
			return UnitSkill(target);
		end
	end
	return 0;
end;
Kitty.ClassManager.hasEnergy = function(target, min, max)
	if(min == nil) then
		min = 0;
	end
	if(max == nil) then
		max = 100;
	end

	local value = Kitty.ClassManager.getEnergy(target);
	if(min <= value and value <= max) then
		return true, value;
	else
		return false, value;
	end
end;
-- SoulPoint
Kitty.ClassManager.getSoulPoint = function()
	return GetSoulPoint();
end;

-- Weapon type
Kitty.ClassManager.getWeaponType = function(target)
	-- GetInventoryItemType: -1 empty, 0 shield, 1 weapon
	--local eqType = GetInventoryItemType(unit, invPos) 
	--return: -1 if slot is free; 0 if armor in slot; 1 if weapon in slot
	--invPos: [15] = "MainHandSlot" [16] = "SecondaryHandSlot

	local mainHand = GetInventoryItemType(target, 15);
	local secondaryHand = GetInventoryItemType(target, 16);
	if(mainHand == 1 and secondaryHand == -1) then
		-- Two-handed (one/two-handed is not told apart precisely)
		--Zweihandwaffen (habe ich nicht gemacht, weil es schwierig ist, 
		--Einhandwaffen und Zweihandwaffen zu beurteilen) 
		return Kitty.ClassManager.TWO_HANDED;
	elseif(mainHand == 1 and secondaryHand == 0) then
		-- Shield
		return Kitty.ClassManager.SHIELD;
	elseif(mainHand == 1 and secondaryHand == 1) then
		-- Dual wield
		return Kitty.ClassManager.DOUBLE;
	else
		-- Unknown
		return Kitty.ClassManager.UNKNOWN;
	end
end;
