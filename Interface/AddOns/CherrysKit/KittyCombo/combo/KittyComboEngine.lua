-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- ComboManager:check(): walks a kitty top to bottom and returns the first command
-- that can fire. Also the constructor, which reads skills and buffs lazily.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.ComboManager.debugSkillList = {};
Kitty.ComboManager.check = function(self, targetList, path)
    path = path or {};
    if(path[targetList]) then
        local now = Kitty.getTime and Kitty.getTime() or 0;
        if(not Kitty.ComboManager.cycleWarning or now - Kitty.ComboManager.cycleWarning >= 5) then
            Kitty.ComboManager.cycleWarning = now;
            Kitty.sendMessage("KittyCombo: cyclic proc skipped: " .. tostring(targetList.info and targetList.info.name or "unknown"), "DEFAULT", 1, 0, 0);
        end
        return nil;
    end
    path[targetList] = true;
    local function walk()
	-- Skill check
	-- Each command, in priority order
	for _, command in ipairs(targetList) do
		-- Enabled commands
		if(command.enable ~= false) then	-- nil counts as enabled
			local result = false;

			if(command.commandType == "skill") then
				-- Can the skill be cast?
				result = self.skillManager:canCast(command.commandName);
				-- Debug.
				if(Kitty.ComboManager.debugSkillList[command.commandName] == true) then
					Kitty.print("canCast Result:[" .. tostring(result) .. "], Command:[" .. tostring(command.commandName) .. "]");
				end
			elseif(command.commandType == "suitskill") then
				-- Can the skill be cast?
				result = self.skillManager:canCast(command.commandName);
				-- Debug.
				if(Kitty.ComboManager.debugSkillList[command.commandName] == true) then
					Kitty.print("canCast Result:[" .. tostring(result) .. "], Command:[" .. tostring(command.commandName) .. "]");
				end
			elseif(command.commandType == "action") then
				-- Can the action slot be used?
				result = self.slotManager:canUse(command.commandName);
				-- Debug.
				if(Kitty.ComboManager.debugSkillList[command.commandName] == true) then
					Kitty.print("canUse Result:[" .. tostring(result) .. "], Command:[" .. tostring(command.commandName) .. "]");
				end
			elseif(command.commandType == "extra") then
				-- Can the extra action be used?
				local extraActionIndex = tonumber(command.commandName);
				if(extraActionIndex == nil) then
					-- By skill name
					local extraActionManager = Kitty.ExtraActionManager();
					result = extraActionManager:canUse(command.commandName);
				else
					-- By index
					result = Kitty.ExtraActionManager.canUseByIndex(extraActionIndex);
				end
			elseif(command.commandType == "macro") then
				-- Macro
				result = self.macroManager:canExecute(command.commandName);
				if(result) then
					-- Cooldown check
					result = self.cooldownManager:canCast(command.commandName);
				end
			elseif(command.commandType == "emote") then
				-- Emote
				local emotionManager = Kitty.EmotionManager();
				result = emotionManager:canEmote(command.commandName);
				if(result) then
					-- Cooldown check
					result = self.cooldownManager:canCast(command.commandName);
				end
			elseif(command.commandType == "proc") then
				-- Proc (another command list)
				local commandLists = self:findProc(command.commandName);
				if(#commandLists > 0) then
					-- Check the command's conditions
					result = self:checkCondition(command);
					if(result) then
						local commandType, commandName = self:check(commandLists[1], path);	-- Recursive call
						if(commandType ~= nil) then
							if(Kitty.isDebugFlag) then
								Kitty.debugPrint("Check result. CommandType:[" .. commandType .. "], CommandName:[" .. commandName .. "], ProcName:[" .. command.commandName .. "]");
							end
							return commandType, commandName, command.commandName;
						else
							-- Nothing in the proc is ready
							result = false;
						end
					end
				else
					error("Invalid Proc. ProcName:[" .. tostring(command.commandName) .. "]");
				end
			elseif(command.commandType == "break") then
				-- Stop here (break)
				result = true;
			elseif(command.commandType == "debug") then
				-- Debug message
				result = true;
			else
--				error("Invalid CommandType:[" .. tostring(command.commandType) .. "]");
			end

			if(result) then
				-- Check the command's conditions
				result = self:checkCondition(command);
			end

			if(result) then
				if(Kitty.isDebugFlag) then
					Kitty.debugPrint("Check result. CommandType:[" .. command.commandType .. "], CommandName:[" .. command.commandName .. "]");
				end
				return command.commandType, command.commandName, nil;
			end
		end
	end

	-- Debug.
	if(Kitty.isDebugFlag) then
		Kitty.debugPrint("SelectedCommand:[nil], CommandName:[" .. tostring(targetList.info and targetList.info.name) .. "]");
	end
	return nil;
    end
    local commandType, commandName, procName = walk();
    path[targetList] = nil;
    return commandType, commandName, procName;
end;
-- Command lists used by "proc" commands, looked up once per key press
Kitty.ComboManager.findProc = function(self, name)
	local found = self.procCache[name];
	if(found == nil) then
		found = Kitty.ComboManager.selectCommandListByName({name});
		self.procCache[name] = found;
	end
	return found;
end;
-- Check a command's conditions
Kitty.ComboManager.checkCondition = function(self, command)
	local result = true;

	-- Each condition
	for _, condition in ipairs(command) do
		-- Run the condition
		local func = self[condition.conditionType];
		assert(func, "Error: Function:[" .. tostring(condition.conditionType) .. "] is nothing.");
		local ok, value = pcall(func, self, Kitty.ComboManager.getArgument(condition));
		if(ok) then
			result = value;
		else
			Kitty.sendMessage(value, "DEFAULT", 1, 0, 0);
			result = nil;
		end

		-- Debug.
		if(Kitty.ComboManager.debugSkillList[command.commandName] == true) then
			Kitty.print("checkCondition Result:[" .. tostring(result) .. "], Command:[" .. tostring(command.commandName) .. "], ConditionType:[" .. tostring(condition.conditionType) .. "]", Kitty.ComboManager.getArgument(condition));
		end

		if(result ~= true) then
			break;
		end
	end
	return result;
end;

Kitty.ComboManager.cast = function(self, commandType, command)
	if(commandType == "skill") or (commandType == "suitskill") then
		-- Cast a skill
		self.skillManager:cast(command);

	elseif(commandType == "action") then
		-- Use an action slot
		self.slotManager:use(command);
	elseif(commandType == "extra") then
		-- Can the extra action be used?
		local extraActionIndex = tonumber(command);
		if(extraActionIndex == nil) then
			local extraActionManager = Kitty.ExtraActionManager();
			-- By skill name
			extraActionManager:use(command);
		else
			-- By index
			Kitty.ExtraActionManager.useByIndex(extraActionIndex);
		end
	elseif(commandType == "macro") then
		-- Macro
		local totalEstimatedPeriod = self.macroManager:execute(command);
		if(totalEstimatedPeriod == nil) then
			Kitty.sendMessage(Kitty.format("This macro cannot be executed. MacroName:[<<1>>]", tostring(command)), "DEFAULT", 1, 0, 0);
		else
			-- Start our own cooldown
			self.cooldownManager:onCast(command, totalEstimatedPeriod + 0.5);
		end
	elseif(commandType == "emote") then
		-- Emote
		local emotionManager = Kitty.EmotionManager();
		emotionManager:doEmote(command);
		-- Start our own cooldown
		self.cooldownManager:onCast(command, 0.5);
	elseif(commandType == "proc") then
		-- Proc (another command list)
		-- A proc is never cast directly
		error("Error. Invalid argument. CommandType:[" .. tostring(commandType) .. "], Proc:[" .. tostring(command) .. "]");
	elseif(commandType == "break") then
		-- Stop here (break)
		if(command ~= nil and command ~= "") then
			SendSystemMsg(Kitty.ComboManager.formatMessage(command));
		end
	elseif(commandType == "debug") then
		-- Debug message
		if(command ~= nil and command ~= "") then
			SendSystemMsg(Kitty.ComboManager.formatMessage(command));
		end
	end
end;

-- Constructor
Kitty.ComboManager.constructor = function(self, slotManager, cooldownManager, macroManager)
	-- Fields
	local obj = {};
	-- Action bar slots
	obj.slotManager = slotManager;
	-- Cooldown tracker
	obj.cooldownManager = cooldownManager;
	-- Buff readers
	-- targetBuffManager / playerBuffManager are read on first use (see lazyMembers),
	-- so a key press that never checks a buff does not scan any.
	-- Skill reader
	-- Only the skills the command list asks about are read from the client.
	obj.skillManager = Kitty.SkillManager(cooldownManager);
	obj.skillManager:updateLazy();
	-- Macro runner
	obj.macroManager = macroManager;
	-- proc name -> command list
	obj.procCache = {};

	return setmetatable(obj, {__index=Kitty.ComboManager.lazyIndex});
end;
Kitty.ComboManager.lazyMembers = {
	["targetBuffManager"] = function()
		local buffManager = Kitty.BuffManager();
		buffManager:update("target");
		return buffManager;
	end,
	["playerBuffManager"] = function()
		local buffManager = Kitty.BuffManager();
		buffManager:update("player");
		return buffManager;
	end,
};
Kitty.ComboManager.lazyIndex = function(obj, key)
	local builder = Kitty.ComboManager.lazyMembers[key];
	if(builder ~= nil) then
		local value = builder();
		rawset(obj, key, value);
		return value;
	end
	return Kitty.ComboManager[key];
end;
setmetatable(Kitty.ComboManager, {__call=Kitty.ComboManager.constructor});	-- Calling the class makes an instance
