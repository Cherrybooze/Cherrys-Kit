-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end
--------------------------------------------------------------------------------
-- Constants
Kitty.MAX_VALUE = 100000000.0;

--------------------------------------------------------------------------------
-- General functions

-- Debug functions
Kitty.isDebugFlag = false;
-- Is debug mode on?
Kitty.isDebug = function(isDebugFlag)
	if(isDebugFlag ~= nil) then
		Kitty.isDebugFlag = isDebugFlag;
	end
	return Kitty.isDebugFlag;
end;
-- Print (debug)
Kitty.debugPrint = function(...)
	if(Kitty.isDebug()) then
		Kitty.print(...);
	end
end;

-- Protected mode
local function callProtected(context, func, ...)
	-- Run protected (errors go to chat)
	local resultList = {pcall(func, ...)};
	if(resultList[1]) then
		return unpack(resultList, 2);
	else
		-- Native UI calls can fail with nil; Lua also permits other error objects.
		-- Do not let the error reporter hide that failure with a second exception.
		local message = resultList[2];
		if(message == nil or message == "") then
			message = "Client call failed without an error message.";
		else
			message = tostring(message);
		end
		if(context ~= nil) then
			message = tostring(context) .. ": " .. message;
		end
		Kitty.sendMessage(message, "DEFAULT", 1, 0, 0);
		return nil;
	end
end;
Kitty.protectFunction = function(func, context)
	return function(...)
		return callProtected(context, func, ...);
	end
end;
Kitty.pcall = function(func, ...)
	return callProtected(nil, func, ...);
end;
-- Hide the instance in a closure
Kitty.bind = function(instance, func)
	return function(...)
		return func(instance, ...);
	end
end;
-- Print
Kitty.print = function(...)
	if(select("#", ...) == 0) then
		Kitty.sendMessage("<none>");
	else
		local str = "";
		for index = 1, select("#", ...) do
			if(str ~= "") then
				str = str .. " / ";
			end

			local arg = select(index, ...);
			str = str .. Kitty.dump(arg);
		end
		Kitty.sendMessage(str);
	end
end;
Kitty.print = Kitty.protectFunction(Kitty.print);	-- Run protected (errors go to chat)
-- Output
Kitty.sendMessage = function(message, messageType, r, g, b, indent)
	if(indent == nil) then
		indent = 0;
	end

	if(type(message) == "table") then
		for _, str in ipairs(message) do
			Kitty.sendMessage(str, messageType, r, g, b, indent+1);	-- Recursive call
		end
	else
		-- Add indentation
		local blank = "";
		for index=1, indent-1 do
			blank = blank .. "    ";
		end
		message = blank .. tostring(message);

		if(messageType == nil or string.upper(messageType) == "DEFAULT") then
			if(DEFAULT_CHAT_FRAME ~= nil and DEFAULT_CHAT_FRAME.AddMessage ~= nil) then
				if(r == nil or g == nil or b == nil) then
					DEFAULT_CHAT_FRAME:AddMessage(message);
				else
					DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b);
				end
			else
				print(message);
			end
		else
			if(Kitty.eventQueue ~= nill) then
				local executeTime = Kitty.eventQueue:getEndExecuteTime();
				local estimatedTime = 0;
				if(executeTime == nil) then
					estimatedTime = 0;
				else
					estimatedTime = (executeTime - Kitty.getTime())*1000 + 500;	-- Every 500 ms
				end

				if(SendChatMessage ~= nil) then
					Kitty.eventQueue:addFunction(estimatedTime, SendChatMessage, message, messageType);
				else
					Kitty.eventQueue:addFunction(estimatedTime, print, message);
				end
			else
				if(SendChatMessage ~= nil) then
					SendChatMessage(message, messageType);
				else
					print(message);
				end
			end
		end
	end
end;
-- Dump
Kitty.dump = function(data, nest)
	-- Limit recursion depth
	if(nest == nil) then
		nest = 0;
	else
		nest = nest + 1;
	end
	-- Check nesting depth
	if(nest ~= nil and nest > 1000) then
		error("Error: Stack overflow. Data:[" .. tostring(data) .. "], Index:[" .. tostring(nest) .. "]");
	end

	local line = "";
	if(type(data) == "string") then
		if(data == "") then
			line = "<blank>";
		else
			line = tostring(data);
		end
	elseif(type(data) == "table") then
		-- Array
		local meta = getmetatable(data);
		if(meta ~= nil and meta.__tostring ~= nil) then
			line = tostring(data);
		elseif(next(data) == nil) then
			line = "<empty>";
		else
			for key, value in pairs(data) do
				if(line ~= "") then
					line = line .. ", ";
				end

				if(type(key) == "string" and key:sub(1, 2) == "__") then
					-- Values that look like metatable info are circular, so details are not printed.
					line = line .. "[" .. key .. "]:[" .. type(value) .. "]"
				else
					line = line .. "[" .. Kitty.dump(key, nest) .. "]:[" .. Kitty.dump(value, nest) .. "]";	-- Recursive call
				end
			end
		end
	else
		-- nil, number, boolean, function
		line = tostring(data);
	end

	return line;
end;

--------------------------------------------------------------------------------
-- Debug functions
-- Raise an error
Kitty.error = function(errorMessage)
	Kitty.printStackTrace(Kitty.getStackTrace(3));
	error(errorMessage, 2);
end;
-- Get stack trace info
Kitty.getStackTrace = function(level)
	if(debug == nil) then
		error("Error: getStackTrace function does not support for debug mode.");
	end

	local debugInfoList = {};

	if(level == nil) then
		level = 2;	-- 0: debug.getinfo(), 1: Kitty.getStackTrace()
	end
	while(true) do
		local debugInfo = debug.getinfo(level);
		if(debugInfo ~= nil) then
			table.insert(debugInfoList, debugInfo);
			level = level + 1;
		else
			return debugInfoList;
		end
	end
end;
Kitty.formatStackTrace = function(debugInfo)
	-- Function name
	local message = debugInfo.name;
	if(message ~= nil) then
		message = message .. "[" .. debugInfo.what .. "]";
	else
		message = debugInfo.what;
	end

	-- File name
	local fileName = nil;
	if(debugInfo.currentline >= 0) then
		message = message .. "(" .. debugInfo.short_src .. ":" .. debugInfo.currentline .. ")";
	end

	return message;
end;
Kitty.printStackTrace = function(debugInfoList)
	for index, debugInfo in ipairs(debugInfoList) do
		Kitty.sendMessage([[	at ]] .. Kitty.formatStackTrace(debugInfo));
	end
end;

-- Trace function
Kitty.isExcepted = function(debugInfo, exceptedFunctionList)
	for index, functionName in pairs(exceptedFunctionList) do
		if(functionName == debugInfo.what or functionName == debugInfo.name) then
			return true;
		end
	end
	return false;
end;
Kitty.trace = function(mask, exceptedFunctionList)
	if(debug == nil) then
		error("Error: trace function does not support for debug mode.");
	end

	-- Set initial values
	-- Mask
	if(mask == nil) then
		mask = "";
	end
	local orginalMask = mask;
	if(string.find(mask, "c") == nil) then
		mask = mask .. "c";
	end
	if(string.find(mask, "r") == nil) then
		mask = mask .. "r";
	end
	-- Excluded functions
	if(exceptedFunctionList == nil) then
		exceptedFunctionList = {"C"};
	end

	local level = 0;
	-- Compute the starting depth
	local count = 0;
	local level = 0;	-- 0: debug.getinfo(), 1: Kitty.trace()
	while(true) do
		local debugInfo = debug.getinfo(count);
		if(debugInfo ~= nil) then
			count = count + 1;
			-- Is this function excluded?
			if(not Kitty.isExcepted(debugInfo, exceptedFunctionList)) then
				level = level + 1;
			end
		else
			break;
		end
	end
	level = level - 1;	-- Convert to depth from the top

	-- event call, return, tail return, line, count
	local hook = function(event, line)	-- c:"call", r:"return", l:"line"

		local message = nil;
		-- Info about the caller of the running function
		local parentInfo = debug.getinfo(3);
		-- Info about the running function
		local currentInfo = debug.getinfo(2);

		-- Is this function excluded?
		if(Kitty.isExcepted(currentInfo, exceptedFunctionList)) then
			return;
		end

		-- Update depth
		if(event == "call") then
			level = level + 1;
		end

		local message = "";
		-- Event kind
		if(event == "call") then
			-- Function call
			if(string.find(orginalMask, "c") ~= nil) then
				message = string.format("%02d", level) .. " " .. string.rep("  ", level) .. ">>> ";

				-- Function name
				if(currentInfo.name ~= nil) then
					message = message .. currentInfo.name .. "[" .. currentInfo.what .. "]";
				else
					message = message .. currentInfo.what;
				end

				-- File name
				if(parentInfo ~= nil and parentInfo.currentline >= 0) then
					message = message .. "(" .. parentInfo.short_src .. ":" .. parentInfo.currentline .. ")";
				end

				-- Arguments
				if(currentInfo.nparams ~= nil) then
					local str = "";
					for index = 1, currentInfo.nparams do
						if(str ~= "") then
							str = str .. ", ";
						end

						local argName, argValue = debug.getlocal(2, index);
						str = str .. string.format("[%s]=[%s]", tostring(argName), tostring(argValue));
					end
					if(str ~= "") then
						message = message .. " Arg: " .. str;
					end
				else
					-- Some interpreters leave currentInfo.nparams undefined
					local str = "";
					local index = 1;
					while(true) do
						local argName, argValue = debug.getlocal(2, index);
						if(argName == nil or argName == "(*temporary)") then
							break;
						end

						if(str ~= "") then
							str = str .. ", ";
						end

						str = str .. string.format("[%s]=[%s]", tostring(argName), tostring(argValue));
						index = index + 1;
					end
					if(str ~= "") then
						message = message .. " Arg: " .. str;
					end
				end
			end
		elseif(event == "return") then
			-- Function return
			if(string.find(orginalMask, "r") ~= nil) then
				message = string.format("%02d", level) .. " " .. string.rep("  ", level) .. "<<< ";

				-- Function name
				if(currentInfo.name ~= nil) then
					message = message .. currentInfo.name .. "[" .. currentInfo.what .. "]";
				else
					message = message .. currentInfo.what;
				end

				-- File name
				if(parentInfo ~= nil and parentInfo.currentline >= 0) then
					message = message .. "(" .. parentInfo.short_src .. ":" .. parentInfo.currentline .. ")";
				end
			end
		elseif(event == "line") then
			-- Line hook
			if(string.find(orginalMask, "l") ~= nil) then
				message = string.format("%02d", level+1) .. " " .. string.rep("  ", level+1) .. "--- ";

				-- Function name
				if(currentInfo.name ~= nil) then
					message = message .. currentInfo.name .. "[" .. currentInfo.what .. "]";
				else
					message = message .. currentInfo.what;
				end

				-- File name
				if(currentInfo.currentline >= 0) then
					message = message .. "(" .. currentInfo.short_src .. ":" .. line .. ")";
				end
			end
		elseif(event == "tail call") then
			message = string.format("%02d", level+1) .. " " .. string.rep("  ", level+1) .. "### ";

			-- Function name
			if(currentInfo.name ~= nil) then
				message = message .. currentInfo.name .. "[" .. currentInfo.what .. "]";
			else
				message = message .. currentInfo.what;
			end

			-- File name
			if(parentInfo ~= nil and parentInfo.currentline >= 0) then
				message = message .. "(" .. parentInfo.short_src .. ":" .. parentInfo.currentline .. ")";
			end
		elseif(event == "tail return") then
			message = string.format("%02d", level+1) .. " " .. string.rep("  ", level+1) .. "%%% ";

			-- Function name
			if(currentInfo.name ~= nil) then
				message = message .. currentInfo.name .. "[" .. currentInfo.what .. "]";
			else
				message = message .. currentInfo.what;
			end

			-- File name
			if(parentInfo ~= nil and parentInfo.currentline >= 0) then
				message = message .. "(" .. parentInfo.short_src .. ":" .. parentInfo.currentline .. ")";
			end
		else
			-- Error
			message = "Error:[" .. event .. "]";
		end

		-- Update depth
		if(event == "return") then
			if(level > 0) then
				level = level - 1;
			end
		end

		-- Print debug info
		if(message ~= "") then
			Kitty.sendMessage(message);
		end
	end;

	-- Hook
	debug.sethook(hook, mask);
end;
Kitty.traceGlobals = function()
	local global = {};
	local set = function(t, name, value)
		local debugInfo = debug.getinfo(2, "Sl");

		-- "(xxxx.lua:999) [arg]:[old]->[new]"
		local message = debugInfo.short_src;
		if(debugInfo.currentline >= 0) then
			message = message .. ":" .. debugInfo.currentline;
		end
		message = "(" .. message .. ") ";
		message = message .. "[" .. name .. "]:[" .. Kitty.dump(global[name]) .. "]->[" .. Kitty.dump(value) .. "]";
		Kitty.sendMessage(message);

		global[name] = value;
	end;

	setmetatable(_G, {__index=global, __newindex=set});
end;

--------------------------------------------------------------------------------
-- Table functions
-- Table copy (deep)
Kitty.copyTable = function(list)
	local result = nil;

	local dataType = type(list);
	if(dataType == "nil"
	or dataType == "number"
	or dataType == "string"
	or dataType == "boolean"
	or dataType == "function") then
		result = list;
	elseif(dataType == "table") then
		result = {};
		for key, value in pairs(list) do
			result[Kitty.copyTable(key)] = Kitty.copyTable(value);	-- Recursive call
		end
	else
		-- thread, userdata
		error("Could not copy. DataType:[" .. dataType .. "]");
	end

	return result;
end;
-- Join table elements
Kitty.concatTable = function(list1, list2)
	local resultList = {};
	for key, value in pairs(list1) do
		if(type(key)=="number") then
			table.insert(resultList, value);
		else
			resultList[key] = value;
		end
	end
	for key, value in pairs(list2) do
		if(type(key)=="number") then
			table.insert(resultList, value);
		else
			resultList[key] = value;
		end
	end
	return resultList;
end;
-- Get data from an associative table by the given keys
Kitty.getData = function(mapData, ...)	-- Kitty.getData(Kitty.locale, "category1", "category2", ...);
	local resultData = nil;
	if(select("#", ...) > 0) then
		resultData = mapData;
		for index=1, select("#", ...) do
			local temp = resultData[select(index, ...)];
			if(temp) then
				resultData = temp;
				if(type(temp) ~= "table") then
					break;
				end
			else
				resultData = nil;
				break;
			end
		end
	end
	return resultData;
end;

-- Get time
Kitty.getTime = function()
	if(GetTime ~= nil) then
		return GetTime();
	elseif(os ~= nil and os.time ~= nil) then
		return os.time();
	else
		error("Error: Does not exist clock.");
	end
end;

-- Load / stringify Lua code
Kitty.stringToData = function(str)
	local func = loadstring("return " .. tostring(str) .. ";");
	if(func ~= nil) then
		return func();
	else
		return nil;
	end
end;

Kitty.dataToString = function(data, indent)
	if(not indent) then
		indent = 0;
	else
		-- Check nesting depth
		if(indent > 1000) then
			error("Error: Stack overflow. Data:[" .. tostring(data) .. "], Indent:[" .. tostring(indent) .. "]");
		end
	end

	local out = "";
	if(type(data) == "thread") then
		out = "thread";
	elseif(type(data) == "userdata") then
		out = "userdata";
	elseif(type(data) == "table") then
		-- Array
		local line = "";
		for key, value in pairs(data) do
			if(line ~= "") then
				line = line .. ",\n";
			end

			indent = indent + 1;
			line = line .. Kitty.blank(indent);
			if(string.startsWith(tostring(key), "__")) then
				-- Meta info
				line = line .. "[" .. Kitty.formatData(key) .. "]=" .. Kitty.formatData(value);
			else
				-- Plain data
				line = line .. "[" .. Kitty.formatData(key) .. "]=" .. Kitty.dataToString(value, indent);	-- Recursive call
			end
			indent = indent - 1;
		end

		if(line ~= "") then
			out = out .. "{" .. "\n";
			out = out .. line .. "\n";
			out = out .. Kitty.blank(indent) .. "}";
		else
			out = out .. "{}";
		end
	else
		-- string, number, boolean
		out = Kitty.formatData(data);
	end

	return out;
end;
Kitty.blank = function(indent, blank)
	if(not blank) then
		blank = "    ";
	end

	local result = "";
	for index=1, indent do
		result = result .. blank;
	end
	return result;
end;
Kitty.formatData = function(data)
	local result = nil;

	if(type(data) == "nil") then
		result = tostring(data);
	elseif(type(data) == "number") then
		result = tostring(data);
	elseif(type(data) == "string") then
		result = [["]] .. data .. [["]];
	elseif(type(data) == "boolean") then
		result = tostring(data);
	elseif(type(data) == "table") then
		result = "{talbe}";
	elseif(type(data) == "function") then
		result = "function()";
	else
		result = tostring(data);
	end

	return result;
end;

-- Formatting functions
Kitty.comma = function(data)
	if(type(data) == "string" or type(data) == "number") then
		if(tonumber(data) ~= nil) then
			data = string.format("%d", tonumber(data));	-- Convert to integer
			local out = "";
			for index = -1, -#data, -3 do
				if(out ~= "") then
					-- Add thousands separators
					out = "," .. out;
				end
				out = string.sub(data, index - 2, index) .. out;
			end

			return out;
		end
	end
	return data;
end;

-- Format localized text
Kitty.format = function(text, ...)
	if(text ~= nil and text ~= "") then
		for index=1, select("#", ...) do
			text = text:gsub("<<" .. index .. ">>", (select(index, ...)));	-- Keep only the first return value of select
		end
	end
	return tostring(text);
end

--------------------------------------------------------------------------------
-- String extensions
Kitty.getUtf8Length = function(initialByte)
	-- Check the first byte
	if(0x00 <= initialByte and initialByte <= 0x7F) then
		return 1;
	elseif(0xC0 <= initialByte and initialByte <= 0xDF) then
		return 2;
	elseif(0xE0 <= initialByte and initialByte <= 0xEF) then
		return 3;
	elseif(0xF0 <= initialByte and initialByte <= 0xF7) then
		return 4;
	elseif(0xF8 <= initialByte and initialByte <= 0xFB) then
		return 5;
	elseif(0xFC <= initialByte and initialByte <= 0xFD) then
		return 6;
	else
		-- Remaining characters
		error("Invalid byte. str:[" .. tostring(str) .. "]");
	end
end;
-- Split a string into characters
string.toArray = function(self)
	local resultArray = {};

	local index = 1;
	while(index <= string.len(self or "")) do
		local length = Kitty.getUtf8Length(string.byte(self, index));
		table.insert(resultArray, string.sub(self, index, index + length - 1));

		index = index + length;
	end
	return resultArray;
end;
-- Search from the right
string.reverseFind = function(self, pattern, final, plain)
	if(final ~= nil) then
		-- Trim the end and narrow the search range
		self = string.sub(self, 1, final);
	end

	local result = {};
	local lastResult = nil;
	repeat
		lastResult = result;
		-- Search starts at 1, then at the end of the previous match + 1
		result = {string.find(self, pattern, (lastResult[2] or 0) + 1, plain)};
	until(result[1] == nil);

	return unpack(lastResult);
end;

-- Split a string
string.split = function(self, delimiter)
	assert(self, "Error: self is nil.");

	local result = {};
	local lastPosition = 1;
	for part, position in string.gmatch(self, "(.-)" .. delimiter .. "()") do
		-- Find and record each word + separator
		table.insert(result, part);
		lastPosition = position;
	end

	-- Record the last word
	table.insert(result, string.sub(self, lastPosition));
	return result
end;

string.startsWith = function(self, pattern, init, plain)
	if(init == nil) then
		init = 1;
	end

	if(plain == true) then
		-- Plain search
		if(pattern == string.sub(self, init, init + string.len(pattern) - 1)) then
			return true, pattern;
		else
			return false;
		end
	else
		-- Pattern search
		local s, e = string.find(self, pattern, init, plain);
		if(s == init) then
			-- Start
			return true, string.sub(self, s, e);
		else
			return false;
		end
	end
end;
string.endsWith = function(self, pattern, final, plain)
	if(final == nil) then
		final = string.len(self);
	elseif(final < 0) then
		-- Negative indexes are not used
		final = final + string.len(self) + 1;
	end

	if(plain == true) then
		-- Plain search
		if(pattern == string.sub(self, final - string.len(pattern) + 1, final)) then
			return true, pattern;
		else
			return false;
		end
	else
		-- Pattern search
		local s, e = string.reverseFind(self, pattern, final, plain);
		if(e == final) then
			-- End
			return true, string.sub(self, s, e);
		else
			return false;
		end
	end
end;

string.trim = function(self, pattern)	-- pattern is the characters to strip, joined together.
	return string.trimRight(string.trimLeft(self, pattern), pattern);
end;
string.trimLeft = function(self, pattern)
	assert(self, "Error: self is nil.");

	if(pattern == nil) then
		set = [[ 　	]];
	elseif(type(pattern) == "string") then
		set = pattern;
	elseif(type(pattern) == "table") then
		set = table.concat(pattern);
	else
		-- Error
		error("Error: This type is not supported. pattern:[" .. tostring(pattern) .. "](" .. type(pattern) .. ")");
	end
	-- Strip leading blanks
	return string.gsub(self, "^[" .. set .. "]+", "");
end;
string.trimRight = function(self, pattern)
	assert(self, "Error: self is nil.");

	if(pattern == nil) then
		set = [[ 　	]];
	elseif(type(pattern) == "string") then
		set = pattern;
	elseif(type(pattern) == "table") then
		set = table.concat(pattern);
	else
		-- Error
		error("Error: This type is not supported. pattern:[" .. tostring(pattern) .. "](" .. type(pattern) .. ")");
	end
	-- Strip trailing blanks
	return string.gsub(self, "[" .. set .. "]+$", "");
end;

--------------------------------------------------------------------------------
-- Reload-safe hooks on game functions (Cherry's KittyCombo).
-- RoM's Reload UI runs the addon files again in the same Lua state: Kitty and
-- game functions we wrapped survive. So each wrapper is installed once and only
-- looks up the current handler; a reload just swaps the handler. If another
-- addon wrapped on top of ours, the new wrapper and the old one both end up in
-- the chain, and the busy flag makes the inner one pass straight through.
Kitty.Hooks = Kitty.Hooks or {wrappers = {}, handlers = {}, originals = {}, busy = {}};
-- handler(original, ...) runs instead of the game function; nil passes through
Kitty.Hooks.set = function(name, handler)
	local hooks = Kitty.Hooks;
	hooks.handlers[name] = handler;
	local current = _G[name];
	if(current == nil or current == hooks.wrappers[name]) then
		return current ~= nil;
	end
	local original = current;
	local wrapper;
	wrapper = function(...)
		local h = Kitty.Hooks.handlers[name];
		if(h == nil or Kitty.Hooks.busy[name]) then
			return original(...);
		end
		Kitty.Hooks.busy[name] = true;
		local result = {pcall(h, original, ...)};
		Kitty.Hooks.busy[name] = nil;
		if(not result[1]) then
			error(result[2], 0);
		end
		return unpack(result, 2);
	end;
	if(hooks.originals[name] == nil) then
		hooks.originals[name] = original;
	end
	hooks.wrappers[name] = wrapper;
	_G[name] = wrapper;
	return true;
end;
-- Stop handling; the wrapper stays and just calls through
Kitty.Hooks.clear = function(name)
	Kitty.Hooks.handlers[name] = nil;
end;

--------------------------------------------------------------------------------
-- Hook manager
-- Note: a hooked Lua function is garbage collected, a C function is not.
-- So hooks on C functions must be removed explicitly.
Kitty.HookManager = {};
-- Static functions
-- Override
Kitty.HookManager.override = function(orgFunc, overrideFunc, instance)
	local hookManager = Kitty.HookManager(orgFunc, nil, nil, instance);
	hookManager.overrideFunc = overrideFunc;
	return hookManager;
end;
-- Instance methods
Kitty.HookManager.call = function(self, ...)
	if(self.overrideFunc ~= nil) then
		-- Override
		local result = nil;
		if(self.instance ~= nil) then
			result = {pcall(self.overrideFunc, self.instance, self.orgFunc, ...)};
		else
			result = {pcall(self.overrideFunc, self.orgFunc, ...)};
		end

		if(result[1]) then
			return unpack(result, 2);
		else
			-- Error
			Kitty.sendMessage(result[2]);
			return;
		end
	end

	-- Before call
	if(self.preFunc ~= nil) then
		local result = nil;
		if(self.instance ~= nil) then
			result = {pcall(self.preFunc, self.instance, ...)};
		else
			result = {pcall(self.preFunc, ...)};
		end
		if(not result[1]) then
			-- Error
			Kitty.sendMessage(result[2]);
		end
	end

	-- Original function
	local resultList = {pcall(self.orgFunc, ...)};
	if(not resultList[1]) then
		-- Error
		Kitty.sendMessage(resultList[2]);
	end

	-- After call
	if(self.postFunc ~= nil) then
		local result = nil;
		if(self.instance ~= nil) then
			result = {pcall(self.postFunc, self.instance, ...)};
		else
			result = {pcall(self.postFunc, ...)};
		end
		if(not result[1]) then
			-- Error
			Kitty.sendMessage(result[2]);
		end
	end

	return unpack(resultList, 2);
end;
Kitty.HookManager.getOriginalFunction = function(self)
	return self.orgFunc;
end;
Kitty.HookManager.isHooked = function(self)
	return true;
end;
-- String form
Kitty.HookManager.toString = function(self)
	return "orgFunc:[" .. tostring(self.orgFunc) .. "], preFunc:[" .. tostring(self.preFunc) .. "], postFunc:[" .. tostring(self.postFunc) .. "], overrideFunc:[" .. tostring(self.overrideFunc) .. "]";
end;
-- Constructor
Kitty.HookManager.constructor = function(self, orgFunc, preFunc, postFunc, instance)
	-- Fields
	local obj = {};
	-- Function to hook
	obj.orgFunc = orgFunc;
	-- Function called when the hook fires
	obj.preFunc = preFunc;
	obj.postFunc = postFunc;
	obj.instance = instance;
	obj.overrideFunc = nil;

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.HookManager, __tostring=Kitty.HookManager.toString, __call=Kitty.HookManager.call});
end;
setmetatable(Kitty.HookManager, {__call=Kitty.HookManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Tokenizer
Kitty.Tokenizer = {};
-- Static functions
Kitty.Tokenizer.startsWith = function(source, delimiterArray)
	for _, value in pairs(delimiterArray) do
		local result, word = source:startsWith(value);	-- Pattern
		if(result) then
			return word;
		end
	end
	return nil;
end;
-- Instance methods
-- Get the next token (returns a token or a separator)
Kitty.Tokenizer.nextToken = function(self)
	-- Token
	local position = 0;
	local result = nil;
	local word = nil;
	while(true) do
		local str = self.source:sub(self.offset + position);
		if(str == nil or str == "") then
			if(position > 0) then
				-- Token
				local token = self.source:sub(self.offset, self.offset + position -1);
				self.offset = self.offset + position;
				result = true;
				word = token;
				break;
			else
				-- Done parsing
				result = nil;
				word = nil;
				break;
			end
		end

		-- Is this an ignored character?
		if(self.exceptedWordArray ~= nil) then
			local exceptedWord = Kitty.Tokenizer.startsWith(str, self.exceptedWordArray);
			if(exceptedWord ~= nil) then
				position = position + exceptedWord:len();
			end
		end

		local delimiter = Kitty.Tokenizer.startsWith(str, self.delimiterArray);
		if(delimiter ~= nil) then
			if(position > 0) then
				-- Token
				local token = self.source:sub(self.offset, self.offset + position -1);
				self.offset = self.offset + position;
				result = true;
				word = token;
				break;
			else
				-- Separator
				self.offset = self.offset + delimiter:len();
				result = false;
				word = delimiter;
				break;
			end
		end

		position = position + 1;
	end

	return result, word;
end;
-- Set separators
Kitty.Tokenizer.setDelimiter = function(self, delimiterArray)
	self.delimiterArray = delimiterArray;
end;
Kitty.Tokenizer.setExceptedWord = function(self, exceptedWordArray)
	self.exceptedWordArray = exceptedWordArray;
end;
-- String form
Kitty.Tokenizer.toString = function(self)
	return self.source;
end;
-- Constructor
Kitty.Tokenizer.constructor = function(self, source, delimiterArray)
	-- Fields
	local obj = {};
	-- String to split into tokens
	obj.source = source;
	-- Separators (string)
	obj.delimiterArray = delimiterArray;
	-- Ignored characters (string)
	obj.exceptedWordArray = nil;
	-- Offset
	obj.offset = 1;

	return setmetatable(obj, {__index=Kitty.Tokenizer, __tostring=Kitty.Tokenizer.toString});
end;
setmetatable(Kitty.Tokenizer, {__call=Kitty.Tokenizer.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- LinkedList
Kitty.LinkedList = {};
-- Instance methods
-- Number of stored elements
Kitty.LinkedList.count = function(self)
	return self.numberOfCell;
end;
-- Append to the end
Kitty.LinkedList.pushBack = function(self, data)
	local cell = nil;
	if(self.numberOfCell == 0) then
		cell = Kitty.LinkedList.Cell(data, nil, nil);
		self.frontCell = cell;
		self.backCell = cell;
	else
		cell = Kitty.LinkedList.Cell(data, self.backCell, nil);
		self.backCell.nextCell = cell;
		self.backCell = cell;
	end
	self.numberOfCell = self.numberOfCell + 1;
end;
-- Insert at the front
Kitty.LinkedList.pushFront = function(self, data)
	local cell = nil;
	if(self.numberOfCell == 0) then
		cell = Kitty.LinkedList.Cell(data, nil, nil);
		self.frontCell = cell;
		self.backCell = cell;
	else
		cell = Kitty.LinkedList.Cell(data, nil, self.frontCell);
		self.frontCell.prevCell = cell;
		self.frontCell = cell;
	end
	self.numberOfCell = self.numberOfCell + 1;
end;
-- Pop from the end (removes it)
Kitty.LinkedList.popBack = function(self)
	local returnValue = nil;
	if(self.numberOfCell > 0) then
		local cell = self.backCell;
		if(self.numberOfCell == 1) then
			self.frontCell = nil;
			self.backCell = nil;
		else
			self.backCell.prevCell.nextCell = nil;
			self.backCell = self.backCell.prevCell;
		end
		self.numberOfCell = self.numberOfCell - 1;
		returnValue = cell.data;
	end

	return returnValue;
end;
-- Pop from the front (removes it)
Kitty.LinkedList.popFront = function(self)
	local returnValue = nil;
	if(self.numberOfCell > 0) then
		local cell = self.frontCell;
		if(self.numberOfCell == 1) then
			self.frontCell = nil;
			self.backCell = nil;
		else
			self.frontCell.nextCell.prevCell = nil;
			self.frontCell = self.frontCell.nextCell;
		end
		self.numberOfCell = self.numberOfCell - 1;
		returnValue = cell.data;
	end

	return returnValue;
end;
-- Peek at the end (does not remove)
Kitty.LinkedList.back = function(self)
	local returnValue = nil;
	if(self.numberOfCell > 0) then
		returnValue = self.backCell.data;
	end
	return returnValue;
end;
-- Peek at the front (does not remove)
Kitty.LinkedList.front = function(self)
	local returnValue = nil;
	if(self.numberOfCell > 0) then
		returnValue = self.frontCell.data;
	end
	return returnValue;
end;
-- Get element at index (does not remove; index starts at zero)
Kitty.LinkedList.getCell = function(self, index)
	local currentIndex = 0;
	local cell = self.frontCell;
	while(cell ~= nil) do
		if(currentIndex == index) then
			return cell.data;
		end
		cell = cell.nextCell;
		currentIndex = currentIndex + 1;
	end
	return nil;
end;
-- Insert at index (index starts at zero)
Kitty.LinkedList.insertCell = function(self, index, data)
	if(self.numberOfCell == index) then
		-- Append to the end
		self:pushBack(data);
		return true;
	end

	local currentIndex = 0;
	local cell = self.frontCell;
	while(cell ~= nil) do
		if(currentIndex == index) then
			-- Add
			local newCell = Kitty.LinkedList.Cell(data, cell.prevCell, cell);
			if(cell.prevCell == nil) then
				self.frontCell = newCell;
			else
				cell.prevCell.nextCell = newCell;
			end
			cell.prevCell = newCell;
			self.numberOfCell = self.numberOfCell + 1;
			return true;
		end
		cell = cell.nextCell;
		currentIndex = currentIndex + 1;
	end
	return false;
end;
-- Remove all elements
Kitty.LinkedList.clear = function(self)
	self.frontCell = nil;
	self.backCell = nil;
	self.numberOfCell = 0;
end;
-- Insert after the given element (for iterators)
Kitty.LinkedList.insertNext = function(self, cell, data)
	local newCell = Kitty.LinkedList.Cell(data, cell, cell.nextCell);
	if(cell.nextCell == nil) then
		self.backCell = newCell;
	else
		cell.nextCell.prevCell = newCell;
	end
	cell.nextCell = newCell;
	self.numberOfCell = self.numberOfCell + 1;
end;
-- Insert before the given element (for iterators)
Kitty.LinkedList.insertPrev = function(self, cell, data)
	local newCell = Kitty.LinkedList.Cell(data, cell.prevCell, cell);
	if(cell.prevCell == nil) then
		self.frontCell = newCell;
	else
		cell.prevCell.nextCell = newCell;
	end
	cell.prevCell = newCell;
	self.numberOfCell = self.numberOfCell + 1;
end;
-- Iterator over party members
Kitty.LinkedList.iterator = function(self)
	local currentCell = nil;

	-- Iterator
	local iterator = function(linkedList, index)
		if(index == 0) then
			-- First time
			currentCell = self.frontCell;
		else
			if(currentCell ~= nil) then
				-- Next element
				currentCell = currentCell.nextCell;
			else
				-- Error
				error("Error: Program error. Called again after iterator returned nil value.");
			end
		end

		index = index + 1;

		if(currentCell == nil) then
			-- Last
			return nil, nil, nil;
		else
			return index, currentCell.data, currentCell;
		end
	end;

	-- iterator function, state, start index
	return iterator, self, 0;
end;
Kitty.LinkedList.reverseIterator = function(self)
	local currentCell = nil;

	-- Iterator
	local iterator = function(linkedList, index)
		if(index == 0) then
			-- First time
			currentCell = self.backCell;
		else
			if(currentCell ~= nil) then
				-- Next element
				currentCell = currentCell.prevCell;
			else
				-- Error
				error("Error: Program error. Called again after iterator returned nil value.");
			end
		end

		index = index + 1;

		if(currentCell == nil) then
			-- Last
			return nil, nil, nil;
		else
			return index, currentCell.data, currentCell;
		end
	end;

	-- iterator function, state, start index
	return iterator, self, 0;
end;
-- String form
Kitty.LinkedList.toString = function(self)
	local str = "Count:[" .. self.numberOfCell .. "]";
	local cell = self.frontCell;
	while(cell ~= nil) do
		if(str ~= "") then
			str = str .. ", ";
		end

		str = str .. "[" .. tostring(cell) .. "]";
		cell = cell.nextCell;
	end
	return str;
end;
-- Constructor
Kitty.LinkedList.constructor = function(self)
	local obj = {};

	-- Element ordering
	-- front << prev << cell << next << back
	obj.frontCell = nil;
	obj.backCell = nil;
	obj.numberOfCell = 0;

	return setmetatable(obj, {__index=Kitty.LinkedList, __tostring=Kitty.LinkedList.toString});
end;
setmetatable(Kitty.LinkedList, {__call=Kitty.LinkedList.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- LinkedList element
Kitty.LinkedList.Cell = {};
-- String form
Kitty.LinkedList.Cell.toString = function(self)
	local strPrev = "None";
	if(self.prevCell ~= nil) then
		strPrev = tostring(self.prevCell.data);
	end
	local strNext = "None";
	if(self.nextCell ~= nil) then
		strNext = tostring(self.nextCell.data);
	end
	return string.format("Data:[%s], prevData:[%s], nextData:[%s]", Kitty.dump(self.data), strPrev, strNext);
end;
-- Constructor
Kitty.LinkedList.Cell.constructor = function(self, data, prevCell, nextCell)
	-- Fields
	local obj = {};
	obj.prevCell = prevCell;
	obj.nextCell = nextCell;
	obj.data = data;

	return setmetatable(obj, {__index=Kitty.LinkedList.Cell, __tostring=Kitty.LinkedList.Cell.toString});
end;
setmetatable(Kitty.LinkedList.Cell, {__call=Kitty.LinkedList.Cell.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Runs functions at a given time
Kitty.EventQueue = {};
-- Instance methods
Kitty.EventQueue.count = function(self)
	return self.queue:count();
end;
-- Schedule a function (delay [ms], function, arguments)
Kitty.EventQueue.addFunction = function(self, delayTime, func, ...)
	local newEventQueueElement = Kitty.EventQueue.Element((delayTime / 1000) + Kitty.getTime(), func, ...);

	-- Insert so the queue stays in run-time order
	for index, eventQueueElement, cell in self.queue:reverseIterator() do
		if(newEventQueueElement:getExpectedExecutetime() >= eventQueueElement:getExpectedExecutetime()) then
			-- Insert
			self.queue:insertNext(cell, newEventQueueElement);
			return;
		end
	end

	-- Insert (empty queue or earliest)
	self.queue:pushFront(newEventQueueElement);
end;
-- Run one function that is due (current time [sec])
Kitty.EventQueue.execute = function(self, currentTime)
	local eventQueueElement = self.queue:front();
	if(eventQueueElement ~= nil) then
		if(eventQueueElement:executable(currentTime)) then
			self.queue:popFront();
			-- Run
			return eventQueueElement:execute();
		end
	end

	return nil;
end;
-- Earliest scheduled time
Kitty.EventQueue.getStartExecuteTime = function(self)
	local element = self.queue:front();
	if(element ~= nil) then
		return element:getExpectedExecutetime();
	else
		return nil;
	end
end;
-- Latest scheduled time
Kitty.EventQueue.getEndExecuteTime = function(self)
	local element = self.queue:back();
	if(element ~= nil) then
		return element:getExpectedExecutetime();
	else
		return nil;
	end
end;
-- String form
Kitty.EventQueue.toString = function(self)
	local str = "";

	for index, eventQueueElement, _ in self.queue:iterator() do
		if(str ~= "") then
			str = str .. ", "
		end

		str = str .. "[" .. tostring(eventQueueElement) .. "]";
	end

	if(str == "") then
		str = "None";
	end
	return str;
end;
-- Constructor
Kitty.EventQueue.constructor = function(self)
	-- Fields
	local obj = {};
	obj.queue = Kitty.LinkedList();

	return setmetatable(obj, {__index=Kitty.EventQueue, __tostring=Kitty.EventQueue.toString});
end;
setmetatable(Kitty.EventQueue, {__call=Kitty.EventQueue.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- EventQueue element
Kitty.EventQueue.Element = {};
-- Instance methods
-- Time check
Kitty.EventQueue.Element.executable = function(self, currentTime)
	if(self.expectedExecutetime <= currentTime) then
		return true;
	else
		return false;
	end
end;
-- Run
Kitty.EventQueue.Element.execute = function(self)
	return self.func(unpack(self.argList));
end;
-- Scheduled run time
Kitty.EventQueue.Element.getExpectedExecutetime = function(self)
	return self.expectedExecutetime;
end;
-- String form
Kitty.EventQueue.Element.toString = function(self)
	return tostring(self.expectedExecutetime);
end;
-- Constructor
Kitty.EventQueue.Element.constructor = function(self, expectedExecutetime, func, ...)
	-- Fields
	local obj = {};
	obj.expectedExecutetime = expectedExecutetime;
	obj.func = func;
	obj.argList = {...};

	return setmetatable(obj, {__index=Kitty.EventQueue.Element, __tostring=Kitty.EventQueue.Element.toString});
end;
setmetatable(Kitty.EventQueue.Element, {__call=Kitty.EventQueue.Element.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Text color functions
Kitty.color = function(str, r, g, b)
	local header = "|H|h|cff" .. string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b);
	local footer = "|r|h";

	local START_TAG = "|H|h|c[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]";
	local END_TAG = "|r|h";
	local tokenizer = Kitty.Tokenizer(str, {START_TAG, END_TAG});
--	Kitty.debugPrint("[" .. tokenizer:toString() .. "]");

	local message = "";
	local index = 0;
	repeat
		local result, token = tokenizer:nextToken();
		if(result == true) then
			-- Token
--			Kitty.debugPrint("[" .. token .. "]");
			if(index == 0) then
				-- Only color text that has no color yet
				message = message .. header .. token .. footer;
			else
				message = message .. token;
			end
		elseif(result == false) then
			-- Separator
			if(token:match(START_TAG) ~= nil) then
				-- START_TAG
				index = index + 1;
--				Kitty.debugPrint((" "):rep(index) .. "Start:[" .. token .. "]");
				message = message .. token;
			else
				-- END_TAG
--				Kitty.debugPrint((" "):rep(index) .. "End:[" .. token .. "]");
				message = message .. token;
				index = index - 1;
			end
		end
	until(result == nil);

--	Kitty.debugPrint("[" .. message .. "]");
	return message;
end;
-- Fixed color + brackets
Kitty.colorRed = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 255, 0, 0);
end;
Kitty.colorGreen = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 0, 255, 0);
end;
Kitty.colorBlue = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 0, 0, 255);
end;
-- [examples] (names, numbers, the thing a text is about) show in teal
Kitty.TEAL = {64, 224, 208};
Kitty.colorCyan = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", Kitty.TEAL[1], Kitty.TEAL[2], Kitty.TEAL[3]);
end;
Kitty.colorTeal = Kitty.colorCyan;
-- Lines with no teal [name] (chat list of a kitty) are drawn in bright purple
Kitty.PURPLE = {200, 110, 255};
Kitty.hasTeal = function(text)
	return type(text) == "string" and string.find(string.lower(text), string.format("|cff%02x%02x%02x", Kitty.TEAL[1], Kitty.TEAL[2], Kitty.TEAL[3]), 1, true) ~= nil;
end;
-- Every [example] in a text in teal; ones already coloured stay as they are
Kitty.teal = function(text)
	if(type(text) ~= "string" or not string.find(text, "[", 1, true)) then
		return text;
	end
	local out, last = {}, 1;
	for start, inner, stop in string.gmatch(text, "()%[([^%[%]|]-)%]()") do
		local before = string.sub(text, math.max(1, start - 10), start - 1);
		if(inner ~= "" and not string.find(before, "^|c%x%x%x%x%x%x%x%x$")) then
			table.insert(out, string.sub(text, last, start - 1));
			table.insert(out, Kitty.colorCyan(inner));
			last = stop;
		end
	end
	table.insert(out, string.sub(text, last));
	return table.concat(out);
end;
Kitty.colorMagenta = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 255, 0, 255);
end;
Kitty.colorYellow = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 255, 255, 0);
end;
Kitty.colorWhite = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 255, 255, 255);
end;
Kitty.colorGray = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 128, 128, 128);
end;
Kitty.colorBlack = function(str)
	return Kitty.color("[" .. tostring(str) .. "]", 0, 0, 0);
end;
Kitty.colorGradation = function(str, startR, startG, startB, endR, endG, endB)
	if(startR == nil) then
		startR = 0;
	end
	if(startG == nil) then
		startG = 255;
	end
	if(startB == nil) then
		startB = 255;
	end
	if(endR == nil) then
		endR = 255;
	end
	if(endG == nil) then
		endG = 255;
	end
	if(endB == nil) then
		endB = 255;
	end

	local result = "";
	local array = str:toArray();
	while(#array > 24) do	-- Channel messages are limited to about 24 characters
		table.remove(array);
	end

	if(#array > 1) then
		-- Linear interpolation
		for index, charcter in ipairs(array) do
			local r = startR + (endR - startR) / (#array-1) * (index-1);
			local g = startG + (endG - startG) / (#array-1) * (index-1);
			local b = startB + (endB - startB) / (#array-1) * (index-1);
			result = result .. Kitty.color(charcter, r, g, b);
		end
	else
		-- For a single character, use the average
		local r = (startR + endR) / 2;
		local g = (startG + endG) / 2;
		local b = (startB + endB) / 2;
		result = Kitty.color(str, r, g, b);
	end

	return result;
end;
