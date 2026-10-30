-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Combo engine: a kitty is a list of commands; the first enabled command
-- whose skill is ready and whose conditions all pass is the one that fires.
Kitty.ComboManager = {};
Kitty.ComboManager.TYPE_EFFECT = "EFFECT";
Kitty.ComboManager.TYPE_ACTION = "ACTION";
Kitty.ComboManager.TYPE_BUILD = "BUILD";
Kitty.ComboManager.TYPE_STRING_NUMBER_LIST = "STRING_NUMBER_LIST";
Kitty.ComboManager.TYPE_STRING = "STRING";
Kitty.ComboManager.TYPE_NUMBER = "NUMBER";
Kitty.ComboManager.TYPE_BOOLEAN = "BOOLEAN";
Kitty.ComboManager.TYPE_OTHER = "OTHER";
Kitty.ComboManager.TYPE_WEAKAURA = "WEAKAURA";

--------------------------------------------------------------------------------
-- Static functions
-- Replace %s %t %b %d (and upper-case colored versions) in a message
Kitty.ComboManager.formatMessage = function(message)
	local replaceList = {
		["s"] = tostring(UnitName("player")),					-- Player name
		["t"] = tostring(UnitName("target")),					-- Target name
		["b"] = tostring(Kitty.lastBuffName),					-- Buff name
		["d"] = string.format("%.2f", Kitty.lastDuration),		-- Buff time left

		["S"] = Kitty.colorCyan(tostring(UnitName("player"))),				-- Player name
		["T"] = Kitty.colorCyan(tostring(UnitName("target"))),				-- Target name
		["B"] = Kitty.colorCyan(tostring(Kitty.lastBuffName)),				-- Buff name
		["D"] = Kitty.colorCyan(string.format("%.2f", Kitty.lastDuration)),	-- Buff time left
	};

	return string.gsub(message, "%%(%w)", replaceList);
end;
-- Collect every condition: a function X with XHelp, XDescribe and XType
Kitty.ComboManager.createFunctionList = function()
	local resultList = {};
	local suffix = "Describe";

	for funcName, func in pairs(Kitty.ComboManager) do
		if(type(funcName) == "string" and type(func) == "function") then
			if(string.endsWith(funcName, suffix)) then
				local originalFuncName = string.sub(funcName, 1, -string.len(suffix)-1);
				-- The condition function itself
				if(originalFuncName ~= "func" and originalFuncName ~= "show" and originalFuncName ~= "commandList" and originalFuncName ~= "command") then
					local helpFuncName = funcName .. "Help";
					local describeFuncName = originalFuncName .. "Describe";
					local typeFuncName = originalFuncName .. "Type";

					resultList[originalFuncName] = {};
					resultList[originalFuncName][originalFuncName] = Kitty.ComboManager[originalFuncName];
					resultList[originalFuncName][helpFuncName] = Kitty.ComboManager[helpFuncName];
					resultList[originalFuncName][describeFuncName] = Kitty.ComboManager[describeFuncName];
					resultList[originalFuncName][typeFuncName] = Kitty.ComboManager[typeFuncName];
				end
			end
		end
	end

	return resultList;
end;

-- The format type of a condition never changes, so it is looked up once per type
Kitty.ComboManager.formatTypeCache = {};
Kitty.ComboManager.getFormatType = function(conditionType)
	assert(conditionType, "ConditionType is nil.");
	local formatType = Kitty.ComboManager.formatTypeCache[conditionType];
	if(formatType == nil) then
		formatType = Kitty.ComboManager[conditionType .. "Type"](nil, nil);
		Kitty.ComboManager.formatTypeCache[conditionType] = formatType;
	end
	return formatType;
end;

-- Arguments the condition function takes
Kitty.ComboManager.getArgument = function(condition)
	local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
	if(formatType == Kitty.ComboManager.TYPE_EFFECT) then
		return condition;
	elseif(formatType == Kitty.ComboManager.TYPE_ACTION) then
		return condition.value;
	elseif(formatType == Kitty.ComboManager.TYPE_BUILD) then
		return condition.value;
	elseif(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST) then
		return condition;
	elseif(formatType == Kitty.ComboManager.TYPE_STRING) then
		return condition.value;
	elseif(formatType == Kitty.ComboManager.TYPE_NUMBER) then
		return condition.min, condition.max;
	elseif(formatType == Kitty.ComboManager.TYPE_BOOLEAN) then
		return condition.value;
	elseif(formatType == Kitty.ComboManager.TYPE_WEAKAURA) then
		return condition;
	else
		return condition;
	end
end;

-- Target state: none, caster, pc, boss, all
Kitty.ComboManager.getTargetState = function()
	if(UnitName("target") == nil or UnitIsUnit("target", "player")) then
		return "none";
	else
		if(UnitIsPlayer("target")) then
			if(Kitty.ClassManager.isCaster("target")) then
				return "caster", "pc", "all";
			else
				return "pc", "all";
			end
		else
			if(UnitSex("target") >= 3) then
				return "boss", "all";
			else
				return "all";
			end
		end
	end
end;
-- Command lists for a build, by target type
Kitty.ComboManager.pickupCommandList = function(allCommandList, mainClass, subClass)
	local result = {};
	local className = nil;
	if(mainClass == "" and subClass == "") then
		className = "any";
	elseif(mainClass == "") then
		className = "/" .. subClass;
	else
		className = mainClass .. subClass;
	end

	for index, commandList in ipairs(allCommandList) do
		if(commandList ~= nil and commandList.info ~= nil) then
			if(commandList.info.class == className) then	-- Exact class match
				if(result[commandList.info.target] == nil) then
					-- The first one wins
					result[commandList.info.target] = commandList;
				else
					-- Duplicate
--					Kitty.sendMessage(Kitty.format("Command list is duplicated. Class:[<<1>>], Target:[<<2>>]", tostring(mainClass) .. tostring(subClass), tostring(commandList.info.target)), "DEFAULT", 1, 0, 0);
				end
			end
		end
	end

	return result;
end;

Kitty.ComboManager.selectCommandList = function(mainClass, subClass)
	local targetStateList = {Kitty.ComboManager.getTargetState()};

	-- Lists for main + sub class
	local targetCommandListMap = Kitty.ComboManager.pickupCommandList(Kitty.SettingManager.setting.command, mainClass, subClass);
	for _, targetState in ipairs(targetStateList) do
		if(targetCommandListMap[targetState] ~= nil) then
			return targetCommandListMap[targetState], targetState;
		end
	end

	-- Lists for the main class only
	local targetCommandListMap = Kitty.ComboManager.pickupCommandList(Kitty.SettingManager.setting.command, mainClass, "");
	for _, targetState in ipairs(targetStateList) do
		if(targetCommandListMap[targetState] ~= nil) then
			return targetCommandListMap[targetState], targetState;
		end
	end

	-- Lists for the sub class only
	local targetCommandListMap = Kitty.ComboManager.pickupCommandList(Kitty.SettingManager.setting.command, "", subClass);
	for _, targetState in ipairs(targetStateList) do
		if(targetCommandListMap[targetState] ~= nil) then
			return targetCommandListMap[targetState], targetState;
		end
	end

	-- Lists for any class
	local targetCommandListMap = Kitty.ComboManager.pickupCommandList(Kitty.SettingManager.setting.command, "", "");
	for _, targetState in ipairs(targetStateList) do
		if(targetCommandListMap[targetState] ~= nil) then
			return targetCommandListMap[targetState], targetState;
		end
	end

	-- Not supported
	return nil;
end;
Kitty.ComboManager.selectCommandListByName = function(commandListNames)
    local resultList, seen = {}, {};
    -- Requested names define priority. Existing duplicate names retain saved-list order.
    for _, name in ipairs(commandListNames) do
        if(not seen[name]) then
            seen[name] = true;
            for _, commandList in ipairs(Kitty.SettingManager.setting.command) do
                if(commandList.info and commandList.info.name == name) then table.insert(resultList, commandList); end
            end
        end
    end
    return resultList;
end;

Kitty.ComboManager.getSupportedClass = function(allCommandList)
	local map = {};
	-- Remove duplicates
	for index, commandList in ipairs(allCommandList) do
		if(commandList.info ~= nil and commandList.info.class ~= nil) then
			if(commandList.info.class ~= "proc") then
				map[commandList.info.class] = true;
			end
		end
	end

	-- To an array
	local array = {};
	for key, _ in pairs(map) do
		table.insert(array, key);
	end

	table.sort(array);
	return array;
end;
Kitty.ComboManager.isSupportedClass = function(allCommandList, className)
	for index, commandList in ipairs(allCommandList) do
		if(commandList.info ~= nil and commandList.info.class ~= nil) then
			if(Kitty.BuildManager.match(className, commandList.info.class)) then
				return true;
			end
		end
	end
	return false;
end;

--------------------------------------------------------------------------------
-- Help
Kitty.ComboManager.showHelp = function(allCommandList, className)
	local resultList = {};

	for index, commandList in ipairs(allCommandList) do
		if(commandList ~= nil and commandList.info ~= nil) then
			if(commandList.info.class == className) then	-- Exact class match

				if(commandList.info.target == "all") then
					table.insert(resultList, Kitty.T("message", "Skill02"));
				elseif(commandList.info.target == "pc") then
					table.insert(resultList, Kitty.T("message", "Skill03"));
				elseif(commandList.info.target == "caster") then
					table.insert(resultList, Kitty.T("message", "Skill04"));
				elseif(commandList.info.target == "boss") then
					table.insert(resultList, Kitty.T("message", "Skill06"));
				elseif(commandList.info.target == "none") then
					table.insert(resultList, Kitty.T("message", "Skill05"));
				else
					table.insert(resultList, Kitty.T("message", "UnsupportedTarget", tostring(commandList.info.target)));
					break;
				end

				resultList = Kitty.concatTable(resultList, Kitty.ComboManager.commandListHelp(commandList));
			end
		end
	end

	if(#resultList == 0) then
		table.insert(resultList, Kitty.T("message", "UnsupportedClass", className));
	end

	return resultList;
end;
Kitty.ComboManager.commandListHelp = function(targetList)
	local resultList = {};
	-- Each command, in priority order
	for index, command in ipairs(targetList) do
		local commandName = nil;
		if(command.commandName ~= nil and command.commandName ~= "") then
			commandName = command.commandName
		else
			commandName = "<none>";
		end

		-- Enabled commands
		if(command.enable ~= false) then	-- nil counts as enabled
			if(command.commandType ~= nil and command.commandType ~= "") then
				-- Number, skill name
				local message = Kitty.color(tostring(index), 255, 255, 255) .. "."
							.. Kitty.ComboManager.formatCommandType(command.commandType)
							.. Kitty.color(tostring(commandName), 255, 255, 0);
				table.insert(resultList, message);
				-- Conditions
				local strList = Kitty.ComboManager.commandHelp(command);
				table.insert(resultList, strList);	-- Nested list
			else
				table.insert(resultList, Kitty.color(tostring(index) .. ".", 255, 255, 255)
										.. Kitty.color(Kitty.ComboManager.formatCommandType(command.commandType)
										.. Kitty.T("message", "Invalid"), 255, 0, 0));
			end
		else
			local message = Kitty.color(tostring(index) .. ".", 255, 255, 255)
										.. Kitty.ComboManager.formatCommandType(command.commandType)
										.. tostring(commandName)
										.. Kitty.color(Kitty.T("message", "Disable"), 255, 0, 255);
			table.insert(resultList, message);
		end
	end

	return resultList;
end;
-- Colour actor labels without touching already-coloured skill or effect names.
local function colorConditionActors(text)
  local startTag = "|H|h|c[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]";
  local tokens = Kitty.Tokenizer(text, {startTag, "|r|h"});
  local parts, depth = {}, 0;
  while(true) do
    local isText, token = tokens:nextToken();
    if(isText == nil) then break; end
    if(isText and depth == 0) then
      local function actor(label)
        return Kitty.color(label, Kitty.PURPLE[1], Kitty.PURPLE[2], Kitty.PURPLE[3]);
      end
      token = string.gsub(token, "%[my target%]", actor);
      token = string.gsub(token, "%[me%]", actor);
    elseif(not isText) then
      if(string.match(token, startTag)) then depth = depth + 1; else depth = depth - 1; end
    end
    table.insert(parts, token);
  end
  return table.concat(parts);
end;
Kitty.ComboManager.commandHelp = function(command)
	local resultList = {};
	if(command ~= nil) then
		-- Conditions
		for index, condition in ipairs(command) do
			local func = Kitty.ComboManager[condition.conditionType .. "Help"];
			assert(func, "Error: Function:[" .. tostring(condition.conditionType .. "Help") .. "] is nothing.");
			local conditionMessage = func(nil, Kitty.ComboManager.getArgument(condition));	-- Instance method, but the instance is not used
			if(type(conditionMessage) == "string") then
				conditionMessage = {conditionMessage};
			end

			-- Actor names stay purple; colour the sentence white for teal values and targeting.
			for _, value in ipairs(conditionMessage) do
				value = colorConditionActors(value);
				if(Kitty.hasTeal(value) or condition.conditionType == "isTargeted") then
					table.insert(resultList, Kitty.color(value, 255, 255, 255));
				else
					table.insert(resultList, Kitty.color(value, Kitty.PURPLE[1], Kitty.PURPLE[2], Kitty.PURPLE[3]));
				end
			end
		end
	end
	return resultList;
end;
Kitty.ComboManager.formatCommandType = function(commandType)
	if(commandType == "skill") then
		return Kitty.colorGreen("K");
	elseif(commandType == "suitskill") then
		return Kitty.colorGreen("S");
	elseif(commandType == "action") then
		return Kitty.colorGreen("A");
	elseif(commandType == "extra") then
		return Kitty.colorGreen("X");
	elseif(commandType == "emote") then
		return Kitty.colorGreen("E");
	elseif(commandType == "macro") then
		return Kitty.colorGreen("M");
	elseif(commandType == "proc") then
		return Kitty.colorGreen("P");
	elseif(commandType == "changemode") then
		return Kitty.colorGreen("Mode");
	elseif(commandType == "break") then
		return Kitty.colorGreen("B");
	elseif(commandType == "debug") then
		return Kitty.colorGreen("D");
	else
		return Kitty.colorMagenta("?");
	end
end;


-- Files that add to Kitty.ComboManager (loaded right after this one, see dofile.lua):
--   combo/KittyConditions.lua   every condition type (X, XHelp, XDescribe, XType)
--   combo/KittyComboEngine.lua  check(): picks the command to fire, and the constructor
--   data/DefaultKitties.lua     the built-in command lists
