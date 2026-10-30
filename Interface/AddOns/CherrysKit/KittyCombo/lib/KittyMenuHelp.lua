-- Cherry's KittyCombo: plain-words help shown when hovering a dropdown entry.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.MenuHelp = {};
Kitty.MenuHelp.NO_LIMIT = "Leave min or max empty for no limit.";

-- Condition types (the first dropdown of a condition row)
Kitty.MenuHelp.conditions = {
	["weakaura"] = "Use an aura from [/rwa]: pick the [aura], then what to check",
	["player"] = "About [me]: buffs, HP, mana, class...",
	["target"] = "About [my target]: buffs, HP, boss, player...",
	["skill / gear"] = "A [skill], an [action bar slot] or my [weapons]",
	["state"] = "The situation: [in combat], [targeted], [Shift], [mode]...",
	["other"] = "Everything else",
	["playerEffect"] = "When I have [buff] with [seconds] or more left",
	["playerNonEffect"] = "When I don't have [buff] (or it has less than [seconds] left)",
	["targetEffect"] = "When [my target] has [debuff] with [seconds] or more left",
	["targetNonEffect"] = "When [my target] doesn't have [debuff]: keeps a debuff up",
	["targetEffectCounter"] = "When [number] players put the same [effect] on [my target] (not stacks)",
	["playerHealth"] = "When my HP is between [min]% and [max]%. [max 40] = only when low",
	["targetHealth"] = "When [my target]'s HP is between [min]% and [max]%. [max 20] = finishers",
	["playerMana"] = "When my mana is between [min]% and [max]%",
	["playerTension"] = "When my tension is between [min] and [max]",
	["playerFocus"] = "When my focus ([Scout] SP) is between [min] and [max]",
	["playerEnergy"] = "When my energy ([Rogue] SP) is between [min] and [max]",
	["playerSoulPoint"] = "When my soul points ([0] to [6]) are between [min] and [max]",
	["playerName"] = "When my character is named [name]: for kitties shared between characters",
	["targetName"] = "When [my target] is named [name]: a boss with its own rotation",
	["playerIsFearless"] = "When I am [immune] to damage (Holy Shield, potions...)",
	["targetIsFearless"] = "When [my target] is [immune]. Use [no] to not waste skills on it",
	["playerClass"] = "When my [class combo] matches",
	["targetClass"] = "When [my target]'s [class combo] matches (PvP)",
	["targetIsPC"] = "When [my target] is a [player], not a monster",
	["targetIsCaster"] = "When [my target] is a [caster] (Mage, Priest, Druid, Warlock...)",
	["targetIsBoss"] = "When [my target] is a [boss] or elite",
	["wardenPetExists"] = "When my [Warden pet] is out",
	["targetIsDead"] = "When [my target] is [dead]",
	["isCombat"] = "When I am [in combat]",
	["isCG"] = "When I am in a [guild castle] war",
	["isTargeted"] = "When an enemy targets [me]",
	["canCast"] = "When [skill] is [ready] (or [on cooldown]): lets a command wait for another skill",
	["canUse"] = "When action bar [slot] is [ready] (or [on cooldown])",
	["castRecently"] = "When Kitty tried [skill] in the last [seconds] (or didn't): no double debuffs",
	["targetCasting"] = "When [my target] is casting [skill] (empty = built-in interrupt list; grow it with [/kc interrupt last])",
	["targetDebuffStacks"] = "When [debuff] on [my target] has [number] stacks or more",
	["modeOn"] = "When mode [aoe] is on (or off): switch with the [mode button] or [/kc mode aoe]",
	["isTwoHanded"] = "When I hold a [two-handed] weapon ([no] = one-handed)",
	["isShield"] = "When I wear a [shield]",
	["inRange"] = "When [my target] is in range of [skill] (skill must be on an action bar)",
	["isRequest"] = "Old request switch: now the [request] mode",
	["isShiftPressed"] = "When [Shift] is held while pressing the Kitty macro ([no] = not held)",
	["func"] = "For addon authors: runs [Lua code]. Leave it alone",
};

-- weakaura: what to check about the aura
Kitty.MenuHelp.weakauraFields = {
	["true"] = "Passes while the aura is showing.",
	["false"] = "Passes while the aura is NOT showing.",
	["remaining"] = "Seconds left on the aura's timer. Example: max 3 = refresh when under 3 s.",
	["stacks"] = "How many stacks the aura has. Example: min 3 = only at 3 or more.",
	["percent"] = "The aura's value as a percent of its maximum (0 to 100), e.g. health %.",
	["value"] = "The aura's current number, e.g. current HP, mana or energy.",
	["total"] = "The aura's maximum, e.g. max HP or the full length of its timer.",
	["duration"] = "Full length of the buff/debuff in seconds, not the time left.",
};
Kitty.MenuHelp.weakauraNumberFields = {remaining=true, stacks=true, percent=true, value=true, total=true, duration=true};

-- yes / no for yes-no conditions
Kitty.MenuHelp.boolean = {
	["true"] = "Passes when this is so.",
	["false"] = "Passes when this is NOT so.",
};

-- The two-way choice of canCast, canUse and the 1.6.0 conditions
Kitty.MenuHelp.readyBoolean = {
	["true"] = "Passes when available and cooldown remaining is at or below the threshold.",
	["false"] = "Passes when the skill or slot exists and its cooldown exceeds the threshold.",
};
Kitty.MenuHelp.choiceHelp = {
	castRecently = {["true"] = "Passes if the attempt was within the seconds.", ["false"] = "Passes if no attempt was made within the seconds."},
	modeOn = {["true"] = "Passes while the mode is on.", ["false"] = "Passes while the mode is off."},
	targetCasting = {["true"] = "Passes while the target casts it.", ["false"] = "Passes while the target does NOT cast it."},
};

-- How a buff is named in buff conditions
Kitty.MenuHelp.effectTypes = {
	["name"] = "Type the buff's name exactly as the game shows it.",
	["id"] = "Type the buff's ID number. Use this when two buffs share a name.",
	["original"] = "Pick from the buffs KittyCombo already knows (the next dropdown).",
};

-- Command types (kitty editor rows)
Kitty.MenuHelp.commandTypes = {
	["skill"] = "Casts a skill from your skill book. Drag the skill onto the row's icon.",
	["suitskill"] = "Casts a suit (set) skill.",
	["action"] = "Uses whatever is in an action bar slot: items, potions, mounts...",
	["extra"] = "Uses a button on the extra action bar (special skills that pop up).",
	["macro"] = "Runs one of your macros (only macros that do not cast skills or use items).",
	["emote"] = "Does an emote.",
	["proc"] = "Runs another kitty here: its first ready command fires. Lets you reuse a rotation.",
	["changemode"] = "Changes Kitty's active mode. Pick its mode icon; an editable Mode is off condition is added automatically. The switch uses this press; the next press continues under the new mode.",
	["other"] = "break and debug.",
	["break"] = "Stops here: nothing below this row fires while its conditions pass.",
	["debug"] = "Prints a message instead of casting. For testing a kitty.",
};

-- Which enemies a kitty is for
Kitty.MenuHelp.targets = {
	["all"] = "Used for any target.",
	["boss"] = "Used only when the target is a boss or elite monster.",
	["pc"] = "Used only when the target is another player (PvP).",
	["caster"] = "Used only when the target is a player spell caster.",
	["none"] = "Used when you have no target or target yourself (buffing, prep).",
};

Kitty.MenuHelp.dpsTypes = {
	["None"] = "No damage report.",
	["Normal"] = "After each fight, show your total damage and DPS in chat.",
	["Detail"] = "After each fight, also list damage per skill, hits and crits.",
};

Kitty.MenuHelp.instanceLevels = {
	["None"] = "Leave the instance difficulty alone.",
	["Easy"] = "Set the instance difficulty to Easy when you lead a party.",
	["Normal"] = "Set the instance difficulty to Normal when you lead a party.",
	["Hard"] = "Set the instance difficulty to Hard when you lead a party.",
};

Kitty.MenuHelp.buffGroups = {
	["buff1"] = "Buffs KittyCombo knows, part 1.", ["buff2"] = "Buffs KittyCombo knows, part 2.", ["buff3"] = "Buffs KittyCombo knows, part 3.",
	["debuff1"] = "Debuffs KittyCombo knows, part 1.", ["debuff2"] = "Debuffs KittyCombo knows, part 2.", ["debuff3"] = "Debuffs KittyCombo knows, part 3.",
};
Kitty.MenuHelp.actionGroups = {
	["action1"] = "Action bar slots 1 to 20.", ["action2"] = "Action bar slots 21 to 40.",
	["action3"] = "Action bar slots 41 to 60.", ["action4"] = "Action bar slots 61 to 80.",
};

-- Class letters used in build names such as "RS" (Rogue main, Scout secondary)
Kitty.MenuHelp.classNames = {
	["K"] = "Knight", ["W"] = "Warrior", ["R"] = "Rogue", ["S"] = "Scout", ["M"] = "Mage", ["P"] = "Priest",
	["Wd"] = "Warden", ["D"] = "Druid", ["Mc"] = "Champion", ["Ss"] = "Warlock",
};
Kitty.MenuHelp.describeBuild = function(text)
	if(type(text) ~= "string" or text == "") then
		return nil;
	end
	if(text == "any") then
		return "Any class. Used when no kitty matches your classes more closely.";
	end
	local subOnly = false;
	if(string.sub(text, 1, 1) == "/") then
		subOnly = true;
		text = string.sub(text, 2);
	end
	local names = {};
	local pos = 1;
	while(pos <= string.len(text)) do
		local two = string.sub(text, pos, pos + 1);
		local one = string.sub(text, pos, pos);
		if(Kitty.MenuHelp.classNames[two]) then
			table.insert(names, Kitty.MenuHelp.classNames[two]);
			pos = pos + 2;
		elseif(Kitty.MenuHelp.classNames[one]) then
			table.insert(names, Kitty.MenuHelp.classNames[one]);
			pos = pos + 1;
		else
			return nil;
		end
	end
	if(#names == 1 and subOnly) then
		return "Any main class with " .. names[1] .. " as secondary class.";
	elseif(#names == 1) then
		return names[1] .. " main class, any secondary class.";
	elseif(#names == 2) then
		return names[1] .. " main class, " .. names[2] .. " secondary class.";
	end
	return nil;
end;

local function lookup(list)
	return function(text)
		return list[text];
	end;
end

local function weakauraField(text)
	local help = Kitty.MenuHelp.weakauraFields[text];
	if(help and Kitty.MenuHelp.weakauraNumberFields[text]) then
		help = help .. " " .. Kitty.MenuHelp.NO_LIMIT;
	end
	return help;
end

local function auraName(text)
	if(type(RWA) ~= "table" or type(RWA.IsAuraActive) ~= "function") then
		return nil;
	end
	if(string.find(text, "^%d+%-%d+$")) then
		return "Auras " .. text .. " in your /rwa list.";
	end
	local ok, active = pcall(RWA.IsAuraActive, text);
	if(not ok) then
		return nil;
	end
	return "Your /rwa aura. Showing right now: " .. (active and "yes" or "no") .. ".";
end

local function procName(text)
	return "Runs your kitty \"" .. tostring(text) .. "\" at this spot: its first ready command fires.";
end

-- Dropdown frame name pattern -> help for its entries (first match wins)
Kitty.MenuHelp.byFrame = {
	{"^KittyCommandConditionFrame_Button%d+DropDownMenu$", lookup(Kitty.MenuHelp.conditions)},
	{"WeakAuraFieldDropDownMenu$", weakauraField},
	{"WeakAuraDropDownMenu$", auraName},
	{"EffectTypeDropDownMenu$", lookup(Kitty.MenuHelp.effectTypes)},
	{"^KittyCommandConditionFrame_Button%d+ConditionDropDownMenu$", lookup(Kitty.MenuHelp.buffGroups)},
	{"BooleanDropDownMenu$", "boolean"},
	{"ActionDropDownMenu$", lookup(Kitty.MenuHelp.actionGroups)},
	{"BuildDropDownMenu$", Kitty.MenuHelp.describeBuild},
	{"^KittyCommandConfigFrame_Button%d+DropDownMenu$", lookup(Kitty.MenuHelp.commandTypes)},
	{"^KittyCommandConfigFrame_Button%d+CommandDropDownMenu$", procName},
	{"TargetDropDownMenu$", lookup(Kitty.MenuHelp.targets)},
	{"ShowDPSTypeDropDownMenu$", lookup(Kitty.MenuHelp.dpsTypes)},
	{"InstanceLevelDropDownMenu$", lookup(Kitty.MenuHelp.instanceLevels)},
};

-- true/false reads "ready / on cooldown" when the row is canCast or canUse
Kitty.MenuHelp.describeBoolean = function(frameName, text)
	local rowName = string.gsub(frameName, "BooleanDropDownMenu$", "");
	local conditionType = Kitty.CommandConditionFrame and Kitty.CommandConditionFrame.rowConditionType(rowName);
	local value = text;
	if(Kitty.CommandConditionFrame and Kitty.CommandConditionFrame.choiceValue) then
		value = tostring(Kitty.CommandConditionFrame.choiceValue(text));
	end
	if(conditionType == "canCast" or conditionType == "canUse") then
		return Kitty.MenuHelp.readyBoolean[value];
	end
	if(Kitty.MenuHelp.choiceHelp[conditionType]) then
		return Kitty.MenuHelp.choiceHelp[conditionType][value];
	end
	return Kitty.MenuHelp.boolean[value];
end;

-- Help text for one entry of the named dropdown, or nil
Kitty.MenuHelp.describe = function(frameName, text)
	if(type(frameName) ~= "string" or type(text) ~= "string") then
		return nil;
	end
	for _, rule in ipairs(Kitty.MenuHelp.byFrame) do
		if(string.find(frameName, rule[1])) then
			if(rule[2] == "boolean") then
				return Kitty.MenuHelp.describeBoolean(frameName, text);
			end
			return rule[2](text);
		end
	end
	return nil;
end;
