-- Cherry's KittyCombo: class icons (gfx/class/*.tga), shared with rom weakauras.
--------------------------------------------------------------------------------
-- Create the namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Files are gfx/class/<main>_<sub>.tga, or gfx/class/<class>.tga for one class,
-- named with the build letters K W R S M P Wd D Mc(Champion) Ss(Warlock).
Kitty.ClassIcons = {};
Kitty.ClassIcons.FOLDER = "gfx/class/";
Kitty.ClassIcons.EXTENSION = ".tga";
-- English class names, for callers that pass names instead of letters
Kitty.ClassIcons.englishNames = {
	["knight"] = "K", ["warrior"] = "W", ["rogue"] = "R", ["scout"] = "S", ["mage"] = "M",
	["priest"] = "P", ["warden"] = "Wd", ["druid"] = "D", ["champion"] = "Mc", ["warlock"] = "Ss",
};
-- Localised name -> letter, learned from UnitClass/UnitClassToken
Kitty.ClassIcons.learnedNames = {};
Kitty.ClassIcons.LEARN_UNITS = {"player", "target", "party1", "party2", "party3", "party4"};

local function isLetter(value)
	for _, letter in pairs(Kitty.BuildManager.classList) do
		if(letter == value) then
			return true;
		end
	end
	return false;
end

-- Remember what this client calls each class (UnitClass can be localised)
Kitty.ClassIcons.learn = function()
	if(type(UnitClass) ~= "function" or type(UnitClassToken) ~= "function") then
		return;
	end
	for _, unit in ipairs(Kitty.ClassIcons.LEARN_UNITS) do
		local mainName, subName = UnitClass(unit);
		local mainToken, subToken = UnitClassToken(unit);
		if(type(mainName) == "string" and Kitty.BuildManager.classList[mainToken]) then
			Kitty.ClassIcons.learnedNames[mainName] = Kitty.BuildManager.classList[mainToken];
		end
		if(type(subName) == "string" and Kitty.BuildManager.classList[subToken]) then
			Kitty.ClassIcons.learnedNames[subName] = Kitty.BuildManager.classList[subToken];
		end
	end
end;

-- Build letter for a letter, a token ("THIEF"), an English or a localised name; "" if unknown
Kitty.ClassIcons.toLetter = function(value)
	if(type(value) ~= "string" or value == "") then
		return "";
	end
	if(isLetter(value)) then
		return value;
	end
	local letter = Kitty.BuildManager.classList[string.upper(value)]
		or Kitty.ClassIcons.englishNames[string.lower(value)]
		or Kitty.ClassIcons.learnedNames[value];
	if(not letter) then
		Kitty.ClassIcons.learn();
		letter = Kitty.ClassIcons.learnedNames[value];
	end
	return letter or "";
end;

-- File name (without folder) for a main/sub letter pair, or nil
Kitty.ClassIcons.fileName = function(main, sub)
	if(main == "" and sub == "") then
		return nil;
	end
	if(main == "" or sub == "" or main == sub) then
		-- One class ("R", "/R" or "RR")
		return (main ~= "" and main or sub);
	end
	return main .. "_" .. sub;
end;

-- Texture path for a kitty build string ("RS", "R/S", "/S", "R"); nil for "any", "proc", ""
Kitty.ClassIcons.forBuild = function(build)
	if(type(build) ~= "string" or build == "") then
		return nil;
	end
	local main, sub = Kitty.BuildManager.splitClass(build);
	if(not main) then
		return nil;
	end
	local name = Kitty.ClassIcons.fileName(main, sub);
	return name and (Kitty.BASE_PATH .. Kitty.ClassIcons.FOLDER .. name .. Kitty.ClassIcons.EXTENSION);
end;

-- Kitty.ClassIcon(main, sub): texture path for a class pair, or nil.
-- Takes what UnitClass or UnitClassToken return, build letters, or English names.
-- Kitty.ClassIcon("player") uses that unit's classes.
Kitty.ClassIcon = function(main, sub)
	if(sub == nil and type(main) == "string" and type(UnitClassToken) == "function"
		and type(UnitName) == "function" and UnitName(main) ~= nil) then
		main, sub = UnitClassToken(main);
	end
	local mainLetter = Kitty.ClassIcons.toLetter(main);
	local subLetter = Kitty.ClassIcons.toLetter(sub);
	local name = Kitty.ClassIcons.fileName(mainLetter, subLetter);
	return name and (Kitty.BASE_PATH .. Kitty.ClassIcons.FOLDER .. name .. Kitty.ClassIcons.EXTENSION);
end;
