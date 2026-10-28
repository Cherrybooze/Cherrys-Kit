-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Extra action bar, macros and emotes.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Extra action manager
Kitty.ExtraActionManager = {};
-- Static functions
Kitty.ExtraActionManager.canUseByIndex = function(index, threshold)
	if(threshold == nil) then
		threshold = 0.0;
	end

	local extraActionName = Kitty.ExtraActionManager.getExtraActionName(KittyComboGameTooltip, index);
	if(extraActionName ~= nil and extraActionName ~= "") then
		local _, remaining = GetExtraActionCooldown(index);

		if(remaining <= threshold) then
			return true, remaining;
		else
			return false, remaining;
		end
	end

	return false, 0;
end;
Kitty.ExtraActionManager.useByIndex = function(index)
	UseExtraAction(index);
end;
-- Read the name from the extra action bar
Kitty.ExtraActionManager.getExtraActionName = function(gameTooltip, index)
	if(gameTooltip) then
		Kitty.clearGameTooltip(gameTooltip);
		gameTooltip:SetExtraActionItem(index);
		gameTooltip:Hide();
		local name = _G[gameTooltip:GetName() .. "TextLeft1"]:GetText();
        if(name == nil or name == "") then return nil; end
		return tostring(name);
	else
		return nil;
	end
end;
-- Instance methods
Kitty.ExtraActionManager.getExtraActionList = function(self)
	local list = {};
	for extraActionName, value in pairs(self.extraActionTable) do
		table.insert(list, extraActionName);
	end
	return list;
end;
Kitty.ExtraActionManager.canUse = function(self, extraActionName, threshold)
	if(threshold == nil) then
		threshold = 0.0;
	end

	if(self.extraActionTable[extraActionName] ~= nil) then
		local remaining = self.extraActionTable[extraActionName].remaining;
		if(remaining <= threshold) then
			return true, remaining;
		else
			return false, remaining;
		end
	end

	return false, 0;
end;
Kitty.ExtraActionManager.use = function(self, extraActionName)
	if(self.extraActionTable[extraActionName] ~= nil) then
		local index = self.extraActionTable[extraActionName].index;
		UseExtraAction(index);
	end
end;
-- String form
Kitty.ExtraActionManager.toString = function(self)
	local str = "";
	for name, value in pairs(self.extraActionTable) do
		if(str == nil) then
			str = str .. ", ";
		end
		str = str .. name .. ":[Index=" .. tostring(value.index) .. "][Duration=" .. tostring(value.duration) .. "][Remaining=" .. tostring(value.remaining) .. "]";
	end
	return str;
end;
-- Constructor
Kitty.ExtraActionManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.extraActionTable = {};

	local index = 1;
	while(true) do
		local extraActionName = Kitty.ExtraActionManager.getExtraActionName(KittyComboGameTooltip, index);
		if(extraActionName ~= nil and extraActionName ~= "") then
			obj.extraActionTable[extraActionName] = {};
			obj.extraActionTable[extraActionName].index = index;
			obj.extraActionTable[extraActionName].duration, obj.extraActionTable[extraActionName].remaining = GetExtraActionCooldown(index);
		else
			break;
		end

		index = index + 1;
	end

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.ExtraActionManager, __tostring=Kitty.ExtraActionManager.toString});
end;
setmetatable(Kitty.ExtraActionManager, {__call=Kitty.ExtraActionManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Macro manager
Kitty.MacroManager = {};
-- Instance methods
Kitty.MacroManager.getIndex = function(self, name)
	if(self.macroTable[name] ~= nil) then
		return self.macroTable[name].index;
	end
	return nil;
end;
Kitty.MacroManager.getIcon = function(self, name)
	if(self.macroTable[name] ~= nil) then
		local iconIndex = self.macroTable[name].iconIndex;
		if(iconIndex ~= nil) then
			return GetMacroIconInfo(iconIndex);
		end
	end
	return nil;
end;
Kitty.MacroManager.canExecute = function(self, name)
	if(self.macroTable[name] ~= nil) then
		return true;
	else
		return false;
	end
end;
-- Runs a macro (macros that use skills or items cannot be run)
Kitty.MacroManager.execute = function(self, name)
	-- Parse the macro
	local macroList, totalEstimatedPeriod = self:parseMacro(name);
	if(macroList == nil) then
		return nil;
	end

	-- Macro runner
	local eventQueue = self.eventQueue;
	local executeMacro = function(self, macroList)
		if(type(macroList) == "table") then

			while(true) do
				local macro = table.remove(macroList, 1);
				if(macro ~= nil) then
					if(type(macro) == "string") then
						-- Normal macro line
						ExecuteMacroLine(macro);
						Kitty.debugPrint("Execute:" .. tostring(macro));
					elseif(type(macro) == "number") then
						-- Wait
						eventQueue:addFunction(macro*1000, self, self, macroList);
						Kitty.debugPrint("Wait:" .. tostring(macro));
						break;
					else
						error("Error: Invalid type. Macro:[" .. tostring(macro) .. "]");
					end
				else
					break;
				end
			end

		else
			error("Error: macroList is not table. MacroList:[" .. tostring(macroList) .. "]");
		end
	end;

	-- Run the macro (asynchronously)
	eventQueue:addFunction(0, executeMacro, executeMacro, macroList);

	return totalEstimatedPeriod;
end;
-- Macro parser (split into line commands)
Kitty.MacroManager.parseMacro = function(self, name)
	local macroList = {};	-- Numbers are wait times, strings are macro line commands
	local totalEstimatedPeriod = 0.0;

	-- Parse the macro (split into line commands)
	if(self.macroTable[name] ~= nil and self.macroTable[name].index ~= nil) then
		local _, _, body = GetMacroInfo(self.macroTable[name].index);
		if(type(body) == "string") then
			-- Split on newlines
			local list = string.split(body, "\n");
			for index, str in ipairs(list) do
				if(str ~= nil and str ~= "") then
					str = string.trim(str);
					if(string.startsWith(str, "/[Ww][Aa][Ii][Tt]") == true) then
						-- /wait (does not work in the client, so the addon handles it)
						local period = self:getWaitTime(str);
						if(period ~= nil) then
							totalEstimatedPeriod = totalEstimatedPeriod + period;
							table.insert(macroList, period);
						end
					else
						-- Normal macro line
						table.insert(macroList, str);
					end
				end
			end

			-- Drop a trailing wait
			for index = #macroList, 1, -1 do
				if(type(macroList[index]) ~= "string") then
					-- Remove
					table.remove(macroList);
				else
					break;
				end
			end

			return macroList, totalEstimatedPeriod;
		end
	end
	return nil;
end;
-- Get the /wait time [sec] from a string
Kitty.MacroManager.getWaitTime = function(self, macro)	-- e.g. [/wait 1.0]
	local list = string.split(macro, " ");
	local period = nil;
	for index, str in ipairs(list) do
		-- The first number is the wait time
		period = tonumber(str);
		if(period ~= nil) then
			return period;
		end
	end
	return nil;
end;
-- String form
Kitty.MacroManager.toString = function(self)
	local str = "";
	for name, value in pairs(self.macroTable) do
		if(str == nil) then
			str = str .. ", ";
		end
		str = str .. name .. ":[Index=" .. tostring(value.index) .. "][IconIndex=" .. tostring(value.iconIndex) .. "]";
	end
	return str;
end;
-- Constructor
Kitty.MacroManager.constructor = function(self, eventQueue)
	-- Fields
	local obj = {};
	obj.eventQueue = eventQueue;
	obj.macroTable = {};

	for index = 1, MAX_NUM_MACROS do
		local iconIndex, name, body=GetMacroInfo(index);
		if(iconIndex ~= nil) then
			-- If several macros share a name, use the first
			if(obj.macroTable[name] == nil) then
				obj.macroTable[name] = {};
				obj.macroTable[name].index = index;
				obj.macroTable[name].iconIndex = iconIndex;
			end
		end
	end

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.MacroManager, __tostring=Kitty.MacroManager.toString});
end;
setmetatable(Kitty.MacroManager, {__call=Kitty.MacroManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Emote manager
Kitty.EmotionManager = {};
-- Instance methods
Kitty.EmotionManager.canEmote = function(self, emotionName)
	if(g_EmoteCmdTable[emotionName] ~= nil) then
		return true;
	else
		return false;
	end
end;
Kitty.EmotionManager.doEmote = function(self, emotionName)
	local index = g_EmoteCmdTable[emotionName];
	if(index ~= nil) then
		DoEmote(index);
	end
end;
Kitty.EmotionManager.getIndex = function(self, emotionName)
	return g_EmoteCmdTable[emotionName];
end;
-- String form
Kitty.EmotionManager.toString = function(self)
	local list = {};
	for name, index in pairs(g_EmoteCmdTable) do
		if(list[index] == nil) then
			-- New
			list[index] = {name};
		else
			-- Add
			table.insert(list[index], name)
		end
	end

	for index=1, #list do
		table.sort(list[index]);
	end

	local str = "";
	for index, nameList in ipairs(list) do
		if(tonumber(index) ~= nil) then
			local line = "";
			for nameIndex, name in ipairs(nameList) do
				if(line ~= nil) then
					line = line .. ", ";
				end

				line = line .. "[" .. string.format("%02d", tonumber(index)) .. "]:[" .. name .. "]";
			end
			str = str .. line .. "\n";
		end
	end

	return str;
end;
-- Constructor
Kitty.EmotionManager.constructor = function(self)
	-- Fields
	local obj = {};

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.EmotionManager, __tostring=Kitty.EmotionManager.toString});
end;
setmetatable(Kitty.EmotionManager, {__call=Kitty.EmotionManager.constructor});	-- Calling the class makes an instance
