-- Cherry's KittyCombo: one-click macro for a kitty ("/run Kitty.attack([[name]])").
--------------------------------------------------------------------------------
-- Create the namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.Macro = {};
-- Default macro window has 49 slots; the client constant wins when present
Kitty.Macro.DEFAULT_SLOTS = 49;
-- Longest macro name we write (bytes); longer kitty names are shortened
Kitty.Macro.MAX_NAME_BYTES = 16;

Kitty.Macro.getSlotCount = function()
	if(type(MAX_NUM_MACROS) == "number" and MAX_NUM_MACROS > 0) then
		return MAX_NUM_MACROS;
	end
	return Kitty.Macro.DEFAULT_SLOTS;
end;

-- Macro text that fires this kitty. The long-bracket level is chosen so any
-- kitty name is quoted safely.
Kitty.Macro.getBody = function(kittyName)
	local level = "";
	while(string.find(kittyName, "]" .. level .. "]", 1, true)) do
		level = level .. "=";
	end
	return "/run Kitty.attack([" .. level .. "[" .. kittyName .. "]" .. level .. "])";
end;

-- Kitty name cut to MAX_NAME_BYTES without splitting a UTF-8 character
Kitty.Macro.getName = function(kittyName)
	local limit = Kitty.Macro.MAX_NAME_BYTES;
	if(string.len(kittyName) <= limit) then
		return kittyName;
	end
	local stop = limit;
	-- step back over UTF-8 continuation bytes (0x80-0xBF)
	while(stop > 0) do
		local byte = string.byte(kittyName, stop + 1);
		if(byte == nil or byte < 128 or byte >= 192) then
			break;
		end
		stop = stop - 1;
	end
	return string.sub(kittyName, 1, stop);
end;

-- Does this macro text fire the given kitty?
Kitty.Macro.isKittyBody = function(body, kittyName)
	if(type(body) ~= "string") then
		return false;
	end
	if(body == Kitty.Macro.getBody(kittyName)) then
		return true;
	end
    -- Only recognize a literal Kitty.attack call at the start of a /run or
    -- /script line. Arguments must all be simple quoted strings; never execute it.
    for line in string.gmatch(body .. "\n", "([^\n]*)\n") do
        local code = string.match(line, "^%s*/[Rr][Uu][Nn]%s+(.+)$")
            or string.match(line, "^%s*/[Ss][Cc][Rr][Ii][Pp][Tt]%s+(.+)$");
        local args = code and string.match(code, "^[Kk][Ii][Tt][Tt][Yy]%.attack%s*%(([^()]*)%)");
        if(args) then
            local pos, found, valid = 1, false, true;
            while(pos <= #args) do
                local _, space = string.find(args, "^%s*", pos); pos = (space or pos - 1) + 1;
                local quote = string.sub(args, pos, pos);
                local value, last;
                if(quote == "'" or quote == '\"') then
                    last = string.find(args, quote, pos + 1, true);
                    if(last) then value = string.sub(args, pos + 1, last - 1); end
                    if(value and string.find(value, "\\", 1, true)) then value = nil; end
                elseif(quote == "[") then
                    local equals = string.match(string.sub(args, pos), "^%[(=*)%[");
                    if(equals) then
                        local start = pos + #equals + 2;
                        local close = "]" .. equals .. "]";
                        local ending = string.find(args, close, start, true);
                        if(ending) then value, last = string.sub(args, start, ending - 1), ending + #close - 1; end
                    end
                end
                if(not value) then valid = false; break; end
                if(value == kittyName) then found = true; end
                pos = last + 1;
                local _, trailing = string.find(args, "^%s*", pos); pos = (trailing or pos - 1) + 1;
                if(pos <= #args) then
                    if(string.sub(args, pos, pos) ~= ",") then valid = false; break; end
                    pos = pos + 1;
                    if(not string.find(string.sub(args, pos), "%S")) then valid = false; break; end
                end
            end
            if(valid and found) then return true; end
        end
    end
    return false;
end;

-- Returns slot, macroName of the first macro that fires this kitty, or nil.
Kitty.Macro.find = function(kittyName)
	if(type(kittyName) ~= "string" or kittyName == "") then
		return nil;
	end
	for slot = 1, Kitty.Macro.getSlotCount() do
		if(HasMacro(slot)) then
			local _, name, body = GetMacroInfo(slot);
			if(Kitty.Macro.isKittyBody(body, kittyName)) then
				return slot, name;
			end
		end
	end
	return nil;
end;

Kitty.Macro.findFreeSlot = function()
	for slot = 1, Kitty.Macro.getSlotCount() do
		if(not HasMacro(slot)) then
			return slot;
		end
	end
	return nil;
end;

Kitty.Macro.randomIcon = function()
	local count = tonumber(GetNumMacroIcons()) or 0;
	if(count < 1) then
		return 1;
	end
	return math.random(1, count);
end;

-- Returns slot, macroName, created on success; nil, errorMessage on failure.
-- An existing macro for the kitty is reused, never duplicated.
Kitty.Macro.create = function(kittyName)
	if(type(kittyName) ~= "string" or kittyName == "") then
		return nil, Kitty.L("MacroNoName", "Give the kitty a name first.");
	end
	local slot, name = Kitty.Macro.find(kittyName);
	if(slot ~= nil) then
		return slot, name, false;
	end
	slot = Kitty.Macro.findFreeSlot();
	if(slot == nil) then
		return nil, Kitty.L("MacroFull", "All macro slots are in use. Delete a macro and try again.");
	end
	name = Kitty.Macro.getName(kittyName);
	EditMacro(slot, name, Kitty.Macro.randomIcon(), Kitty.Macro.getBody(kittyName));
	-- Refresh the game's macro window if it is open
	if(type(MacroFrame_Update) == "function") then
		pcall(MacroFrame_Update);
	end
	if(not HasMacro(slot)) then
		return nil, Kitty.L("MacroFailed", "The game did not accept the macro.");
	end
	return slot, name, true;
end;
