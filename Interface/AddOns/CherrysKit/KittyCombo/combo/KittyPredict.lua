-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Kitty.Predict: which command a kitty would fire next, without casting anything.
-- Used by rom weakauras' "Kitty tracker" display (/rwa).
--   Kitty.Predict.listKitties(onlyMyClass) -> { {name=, class=, target=, mine=}, ... }
--   Kitty.Predict.next(kittyName, count) -> { {type=, name=, icon=, proc=}, ... }, reason
-- Entry 1 is what the next press would fire. Entries 2 and 3 are a guess: the same kitty
-- checked again as if the commands before them were on cooldown. Buffs, resources and
-- conditions are read as they are now, so the guess can be wrong after the cast changes them.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.Predict = {};
-- Seconds of cooldown still counted as ready, so the global cooldown after each press
-- does not blank the display. Execution uses SkillManager.EXECUTION_TOLERANCE.
Kitty.Predict.LOOKAHEAD = 1.1;
-- Results are reused for this long; every check reads skill cooldowns from the client.
Kitty.Predict.THROTTLE = 0.2;
Kitty.Predict.cache = {};

-- Kitties to choose from, sorted by name. Proc lists are left out (they are part of other kitties).
-- onlyMyClass: just the kitties whose class fits the current character.
Kitty.Predict.listKitties = function(onlyMyClass)
	local result = {};
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	if(setting == nil or setting.command == nil) then
		return result;
	end
	local className = nil;
	if(Kitty.BuildManager and Kitty.BuildManager.getClass) then
		local _, _, mainClass, subClass = Kitty.BuildManager.getClass("player");
		if(mainClass ~= nil and mainClass ~= "") then
			className = mainClass .. (subClass or "");
		end
	end
	for _, commandList in pairs(setting.command) do
		local info = commandList.info;
		if(info ~= nil and info.name ~= nil and info.class ~= "proc") then
			local mine = false;
			if(className ~= nil and info.class ~= nil) then
				local ok, match = pcall(Kitty.BuildManager.match, className, info.class);
				mine = ok and match and true or false;
			end
			if(mine or not onlyMyClass) then
				table.insert(result, {["name"]=info.name, ["class"]=info.class, ["target"]=info.target, ["mine"]=mine});
			end
		end
	end
	table.sort(result, function(a, b) return tostring(a.name) < tostring(b.name) end);
	return result;
end;

-- The kitty by name. An empty name picks the kitty for the current class and target,
-- the same as a plain /run Kitty.attack().
Kitty.Predict.findKitty = function(kittyName)
	if(kittyName == nil or kittyName == "") then
		local _, _, mainClass, subClass = Kitty.BuildManager.getClass("player");
		return (Kitty.ComboManager.selectCommandList(mainClass, subClass));
	end
	return Kitty.ComboManager.selectCommandListByName({kittyName})[1];
end;

-- A shallow copy of a command list without the masked commands. The saved tables are never
-- changed (BuffManager caches by table identity). Icons saved on the commands are collected.
local function maskKey(commandType, commandName)
	return tostring(commandType) .. "\001" .. tostring(commandName);
end
local function filtered(commandList, masked, icons)
	local copy = {["info"]=commandList.info};
	for _, command in ipairs(commandList) do
		local key = maskKey(command.commandType, command.commandName);
		if(icons[key] == nil and type(command.icon) == "string" and command.icon ~= "") then
			icons[key] = command.icon;
		end
		if(not masked[key]) then
			table.insert(copy, command);
		end
	end
	return copy;
end

-- The picture for a picked command: the skill book icon, an action slot's icon,
-- or the icon saved with the command in the kitty editor.
local function iconFor(comboManager, commandType, commandName, icons)
	if(commandType == "skill" or commandType == "suitskill") then
		local detail = comboManager.skillManager.skillTable[commandName];
		if(detail ~= nil and type(detail.texture) == "string" and detail.texture ~= "") then
			return detail.texture;
		end
	elseif(commandType == "action" and GetActionInfo) then
		local ok, texture = pcall(GetActionInfo, tonumber(commandName));
		if(ok and type(texture) == "string" and texture ~= "") then
			return texture;
		end
	elseif(commandType == "changemode" and Kitty.ModeUI) then
		return Kitty.ModeUI.iconPath(commandName);
	end
	return icons[maskKey(commandType, commandName)];
end

-- A ComboManager whose skill checks look LOOKAHEAD seconds ahead and whose procs see the masked lists.
local function predictor(masked, icons)
	local comboManager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
	local modeState = {};
	for name, state in pairs(Kitty.Modes or {}) do modeState[name] = state; end
	rawset(comboManager, "modeState", modeState);
    local liveCooldowns = comboManager.cooldownManager;
    rawset(comboManager, "cooldownManager", setmetatable({
        canCast = function(_, name, threshold)
            return liveCooldowns:canCast(name, threshold, true);
        end,
    }, {__index=liveCooldowns}));
	local realSkills = comboManager.skillManager;
	rawset(comboManager, "skillManager", setmetatable({
		["canCast"] = function(self, skillName, threshold)
			return Kitty.SkillManager.canCast(self, skillName, math.max(threshold or 0.6, Kitty.Predict.LOOKAHEAD), true);
		end,
	}, {__index=realSkills}));
	local procs, lists = {}, {};
	local function filteredOnce(commandList)
		if(lists[commandList] == nil) then lists[commandList] = filtered(commandList, masked, icons); end
		return lists[commandList];
	end
	rawset(comboManager, "filteredList", function(_, commandList) return filteredOnce(commandList); end);
	rawset(comboManager, "findProc", function(self, name)
		local found = procs[name];
		if(found == nil) then
			found = {};
			for i, commandList in ipairs(Kitty.ComboManager.selectCommandListByName({name})) do
				found[i] = filteredOnce(commandList);
			end
			procs[name] = found;
		end
		return found;
	end);
	rawset(comboManager, "resetProcs", function()
		procs, lists = {}, {};
	end);
	return comboManager;
end

Kitty.Predict.compute = function(kittyName, count)
	local commandList = Kitty.Predict.findKitty(kittyName);
	if(commandList == nil) then
		return {}, "nokitty";
	end
	local masked, icons = {}, {};
	local comboManager = predictor(masked, icons);
	local result = {};
	for round = 1, (count or 1) do
		comboManager.resetProcs();
		local commandType, commandName, procName = comboManager:check(comboManager:filteredList(commandList));
		if(commandType == nil) then
			break;
		end
		table.insert(result, {
			["type"]=commandType,
			["name"]=commandName,
			["proc"]=procName,
			["icon"]=iconFor(comboManager, commandType, commandName, icons),
		});
		-- A "break" row stops the kitty: nothing after it would fire either.
		if(commandType == "break" or commandType == "debug") then
			break;
		end
		if(commandType == "changemode") then
			for name in pairs(comboManager.modeState) do comboManager.modeState[name] = false; end
			comboManager.modeState[Kitty.ModeUI.clean(commandName)] = true;
		end
		masked[maskKey(commandType, commandName)] = true;
	end
	return result;
end;

-- Throttled, including while the player is casting.
Kitty.Predict.next = function(kittyName, count)
	if(Kitty.isTurnedOff and Kitty.isTurnedOff()) then
		return {}, "off";
	end
	count = count or 1;
	local key = tostring(kittyName or "") .. "\001" .. count;
	local now = Kitty.getTime and Kitty.getTime() or GetTime();
	local entry = Kitty.Predict.cache[key];
	if(entry ~= nil) then
		local fresh = (now - entry.time) < Kitty.Predict.THROTTLE;
		if(fresh) then
			return entry.result, entry.reason;
		end
	end
	local ok, result, reason = pcall(Kitty.Predict.compute, kittyName, count);
	if(not ok) then
		result, reason = {}, "error: " .. tostring(result);
	end
	Kitty.Predict.cache[key] = {["time"]=now, ["result"]=result, ["reason"]=reason};
	return result, reason;
end;
