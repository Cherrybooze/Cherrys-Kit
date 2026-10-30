-- Cherry's KittyCombo: share a command list ("kitty") as a text code.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Code format: "CKC1!" .. base64(data) .. "!" .. checksum
-- data is a small tagged format, parsed without loadstring so a pasted code
-- can never run Lua:
--   T / F                 boolean
--   n<number>;            number
--   s<length>:<bytes>     string
--   k<index>;             string key from KEY_ALIASES (keeps codes short)
--   { key value ... }     table
Kitty.Share = {};
Kitty.Share.PREFIX = "CKC1";
Kitty.Share.MAX_DEPTH = 16;
Kitty.Share.KEY_ALIASES = {
	"info", "name", "class", "target", "commandType", "commandName", "icon", "enable",
	"conditionType", "effectType", "threshold", "thresholdS", "value", "min", "max", "field",
};
Kitty.Share.KEY_INDEX = {};
for index, key in ipairs(Kitty.Share.KEY_ALIASES) do
	Kitty.Share.KEY_INDEX[key] = index;
end

--------------------------------------------------------------------------------
-- Serialize
Kitty.Share.serializeValue = function(value, out, depth, isKey)
	local valueType = type(value);
	if(valueType == "boolean") then
		table.insert(out, value and "T" or "F");
	elseif(valueType == "number") then
		table.insert(out, "n" .. string.format("%.14g", value) .. ";");
	elseif(valueType == "string") then
		if(isKey and Kitty.Share.KEY_INDEX[value]) then
			table.insert(out, "k" .. Kitty.Share.KEY_INDEX[value] .. ";");
		else
			table.insert(out, "s" .. string.len(value) .. ":" .. value);
		end
	elseif(valueType == "table") then
		if(depth > Kitty.Share.MAX_DEPTH) then
			error("Command list is nested too deeply to export.");
		end
		table.insert(out, "{");
		-- Array part first, in order, so the command order is kept exactly
		local count = #value;
		for index = 1, count do
			Kitty.Share.serializeValue(index, out, depth + 1, true);
			Kitty.Share.serializeValue(value[index], out, depth + 1, false);
		end
		for key, item in pairs(value) do
			local keyType = type(key);
			local isArrayKey = (keyType == "number" and key >= 1 and key <= count and math.floor(key) == key);
			local itemType = type(item);
			if(not isArrayKey and (keyType == "string" or keyType == "number")
			and (itemType == "string" or itemType == "number" or itemType == "boolean" or itemType == "table")) then
				Kitty.Share.serializeValue(key, out, depth + 1, true);
				Kitty.Share.serializeValue(item, out, depth + 1, false);
			end
		end
		table.insert(out, "}");
	else
		-- functions and other types are not exportable; skipped by the caller
		error("Cannot export a value of type " .. valueType .. ".");
	end
end;
Kitty.Share.serialize = function(value)
	local out = {};
	Kitty.Share.serializeValue(value, out, 0, false);
	return table.concat(out);
end;

--------------------------------------------------------------------------------
-- Parse
Kitty.Share.parseValue = function(data, pos, depth)
	local tag = string.sub(data, pos, pos);
	if(tag == "T") then
		return true, pos + 1;
	elseif(tag == "F") then
		return false, pos + 1;
	elseif(tag == "n") then
		local stop = string.find(data, ";", pos + 1, true);
		if(stop == nil) then
			error("bad number");
		end
		local number = tonumber(string.sub(data, pos + 1, stop - 1));
		if(number == nil) then
			error("bad number");
		end
		return number, stop + 1;
	elseif(tag == "k") then
		local stop = string.find(data, ";", pos + 1, true);
		if(stop == nil) then
			error("bad key");
		end
		local key = Kitty.Share.KEY_ALIASES[tonumber(string.sub(data, pos + 1, stop - 1)) or 0];
		if(key == nil) then
			error("bad key");
		end
		return key, stop + 1;
	elseif(tag == "s") then
		local colon = string.find(data, ":", pos + 1, true);
		if(colon == nil) then
			error("bad string");
		end
		local length = tonumber(string.sub(data, pos + 1, colon - 1));
		if(length == nil or length < 0 or colon + length > string.len(data)) then
			error("bad string");
		end
		return string.sub(data, colon + 1, colon + length), colon + length + 1;
	elseif(tag == "{") then
		if(depth > Kitty.Share.MAX_DEPTH) then
			error("too deep");
		end
		local result = {};
		pos = pos + 1;
		while(true) do
			if(pos > string.len(data)) then
				error("unterminated table");
			end
			if(string.sub(data, pos, pos) == "}") then
				return result, pos + 1;
			end
			local key, value;
			key, pos = Kitty.Share.parseValue(data, pos, depth + 1);
			if(type(key) ~= "string" and type(key) ~= "number") then
				error("bad table key");
			end
			value, pos = Kitty.Share.parseValue(data, pos, depth + 1);
			result[key] = value;
		end
	end
	error("bad data at " .. tostring(pos));
end;
Kitty.Share.parse = function(data)
	local value, pos = Kitty.Share.parseValue(data, 1, 0);
	if(pos ~= string.len(data) + 1) then
		error("extra data");
	end
	return value;
end;

--------------------------------------------------------------------------------
-- Base64 (Lua 5.1 has no bit operations, so this uses arithmetic)
Kitty.Share.B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
Kitty.Share.B64_INDEX = {};
for index = 1, 64 do
	Kitty.Share.B64_INDEX[string.sub(Kitty.Share.B64, index, index)] = index - 1;
end
Kitty.Share.base64Encode = function(data)
	local out = {};
	local chars = Kitty.Share.B64;
	local length = string.len(data);
	for index = 1, length, 3 do
		local a, b, c = string.byte(data, index, index + 2);
		local n = a * 65536 + (b or 0) * 256 + (c or 0);
		local c1 = math.floor(n / 262144) % 64;
		local c2 = math.floor(n / 4096) % 64;
		local c3 = math.floor(n / 64) % 64;
		local c4 = n % 64;
		table.insert(out, string.sub(chars, c1 + 1, c1 + 1) .. string.sub(chars, c2 + 1, c2 + 1)
			.. (b and string.sub(chars, c3 + 1, c3 + 1) or "=")
			.. (c and string.sub(chars, c4 + 1, c4 + 1) or "="));
	end
	return table.concat(out);
end;
Kitty.Share.base64Decode = function(text)
	text = string.gsub(text, "[^%w%+/=]", "");
	if(string.len(text) % 4 ~= 0) then
		return nil;
	end
	local out = {};
	local index = Kitty.Share.B64_INDEX;
	for pos = 1, string.len(text), 4 do
		local s1, s2, s3, s4 = string.sub(text, pos, pos), string.sub(text, pos + 1, pos + 1), string.sub(text, pos + 2, pos + 2), string.sub(text, pos + 3, pos + 3);
		local v1, v2 = index[s1], index[s2];
		if(v1 == nil or v2 == nil) then
			return nil;
		end
		local v3 = index[s3] or 0;
		local v4 = index[s4] or 0;
		local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4;
		table.insert(out, string.char(math.floor(n / 65536) % 256));
		if(s3 ~= "=") then
			table.insert(out, string.char(math.floor(n / 256) % 256));
		end
		if(s4 ~= "=") then
			table.insert(out, string.char(n % 256));
		end
	end
	return table.concat(out);
end;

-- Adler-32 style checksum as 8 hex digits
Kitty.Share.checksum = function(data)
	local a, b = 1, 0;
	for index = 1, string.len(data) do
		a = (a + string.byte(data, index)) % 65521;
		b = (b + a) % 65521;
	end
	return string.format("%04x%04x", b, a);
end;

--------------------------------------------------------------------------------
-- Command lists
-- Copy without runtime-only values (functions, etc.)
Kitty.Share.clean = function(value, depth)
	depth = depth or 0;
	if(type(value) ~= "table") then
		local valueType = type(value);
		if(valueType == "string" or valueType == "number" or valueType == "boolean") then
			return value;
		end
		return nil;
	end
	if(depth > Kitty.Share.MAX_DEPTH) then
		return nil;
	end
	local result = {};
	for key, item in pairs(value) do
		if(type(key) == "string" or type(key) == "number") then
			local cleaned = Kitty.Share.clean(item, depth + 1);
			if(cleaned ~= nil) then
				result[key] = cleaned;
			end
		end
	end
	return result;
end;

-- Version 1 codes (1.0 to 1.2), still accepted by the import box
Kitty.Share.exportCommandListV1 = function(commandList)
	local data = Kitty.Share.serialize(Kitty.Share.clean(commandList));
	return Kitty.Share.PREFIX .. "!" .. Kitty.Share.base64Encode(data) .. "!" .. Kitty.Share.checksum(data);
end;

--------------------------------------------------------------------------------
-- Version 2 codes (1.3): about a quarter the length of version 1.
--   "CKC2!" .. base85(deflate(data)) .. "!" .. check(4 hex)
-- Same layout and base 85 alphabet as rom weakauras' RWA2 codes.
-- data is the tagged format above with these additions:
--   0-9                   a one-digit whole number
--   v<index>;             a common string value from VALUE_ALIASES
--   { values | key value ... }   array items first, then named fields
-- Skill icons can be restored from the skill book; other icons are preserved.
-- enable=true is the default. The alias lists are append-only: changing an
-- entry would break codes already shared.
Kitty.Share.PREFIX2 = "CKC2";
-- In-game chat takes at most this many characters per message
Kitty.Share.CHAT_LIMIT = 255;
Kitty.Share.VALUE_ALIASES = {
	"skill", "suitskill", "action", "extra", "macro", "emote", "proc", "break", "debug",
	"original", "name", "id", "all", "boss", "pc", "caster", "none", "any",
	"true", "false", "remaining", "stacks", "percent", "value", "total", "duration",
	"playerEffect", "playerNonEffect", "targetEffectCounter", "targetEffect", "targetNonEffect",
	"playerHealth", "targetHealth", "playerMana", "playerTension", "playerFocus", "playerEnergy",
	"playerSoulPoint", "playerName", "targetName", "playerIsFearless", "targetIsFearless",
	"playerClass", "targetClass", "targetIsPC", "targetIsCaster", "targetIsBoss", "wardenPetExists",
	"targetIsDead", "isCombat", "isCG", "isTargeted", "canCast", "canUse", "isTwoHanded", "isShield",
	"inRange", "isRequest", "weakaura", "func",
};
Kitty.Share.VALUE_INDEX = {};
for index, value in ipairs(Kitty.Share.VALUE_ALIASES) do
	Kitty.Share.VALUE_INDEX[value] = index;
end
-- Base 85: 4 bytes become 5 characters. The alphabet leaves out characters
-- chat treats specially or the code uses: | % \ " ' ` ! and space.
Kitty.Share.B85 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#$&()*+,-./:;<=>?@[]^_{";
Kitty.Share.B85_INDEX = {};
for index = 1, 85 do
	Kitty.Share.B85_INDEX[string.byte(Kitty.Share.B85, index)] = index - 1;
end
Kitty.Share.base85Encode = function(data)
	local out = {};
	local length = string.len(data);
	for i = 1, length, 4 do
		local n, count = 0, math.min(4, length - i + 1);
		for j = 0, 3 do
			n = n * 256 + (string.byte(data, i + j) or 0);
		end
		local chars = {};
		for j = 5, 1, -1 do
			local d = n % 85;
			chars[j] = string.sub(Kitty.Share.B85, d + 1, d + 1);
			n = (n - d) / 85;
		end
		table.insert(out, table.concat(chars, "", 1, count + 1));
	end
	return table.concat(out);
end;
Kitty.Share.base85Decode = function(text)
	local out = {};
	local length = string.len(text);
	for i = 1, length, 5 do
		local count = math.min(5, length - i + 1);
		if(count < 2) then
			return nil;
		end
		local n = 0;
		for j = 0, 4 do
			local d = (j < count) and Kitty.Share.B85_INDEX[string.byte(text, i + j)] or 84;
			if(d == nil) then
				return nil;
			end
			n = n * 85 + d;
		end
		local bytes = {};
		for j = 4, 1, -1 do
			local b = n % 256;
			bytes[j] = string.char(b);
			n = (n - b) / 256;
		end
		table.insert(out, table.concat(bytes, "", 1, count - 1));
	end
	return table.concat(out);
end;

-- LibDeflate (zlib license) does the compression. With LibStub present it
-- registers there, so several addons share one copy.
Kitty.Share.getDeflate = function()
	if(Kitty.Share.deflate == nil) then
		if(type(LibStub) == "table" and LibStub.GetLibrary) then
			Kitty.Share.deflate = LibStub:GetLibrary("LibDeflate", true);
		end
		if(Kitty.Share.deflate == nil) then
			local ok, lib = pcall(dofile, (Kitty.BASE_PATH or "interface/addons/KittyCombo/") .. "lib/LibDeflate.lua");
			if(ok and type(lib) == "table") then
				Kitty.Share.deflate = lib;
			else
				Kitty.Share.deflate = false;
			end
		end
	end
	return Kitty.Share.deflate or nil;
end;

Kitty.Share.serializeValue2 = function(value, out, depth, isKey)
	local valueType = type(value);
	if(valueType == "boolean") then
		table.insert(out, value and "T" or "F");
	elseif(valueType == "number") then
		if(value >= 0 and value <= 9 and math.floor(value) == value) then
			table.insert(out, tostring(value));
		else
			table.insert(out, "n" .. string.format("%.14g", value) .. ";");
		end
	elseif(valueType == "string") then
		if(isKey and Kitty.Share.KEY_INDEX[value]) then
			table.insert(out, "k" .. Kitty.Share.KEY_INDEX[value] .. ";");
		elseif(not isKey and Kitty.Share.VALUE_INDEX[value]) then
			table.insert(out, "v" .. Kitty.Share.VALUE_INDEX[value] .. ";");
		else
			table.insert(out, "s" .. string.len(value) .. ":" .. value);
		end
	elseif(valueType == "table") then
		if(depth > Kitty.Share.MAX_DEPTH) then
			error("Command list is nested too deeply to export.");
		end
		table.insert(out, "{");
		local count = #value;
		for index = 1, count do
			Kitty.Share.serializeValue2(value[index], out, depth + 1, false);
		end
		local first = true;
		for key, item in pairs(value) do
			local keyType = type(key);
			local isArrayKey = (keyType == "number" and key >= 1 and key <= count and math.floor(key) == key);
			local itemType = type(item);
			if(not isArrayKey and (keyType == "string" or keyType == "number")
			and (itemType == "string" or itemType == "number" or itemType == "boolean" or itemType == "table")) then
				if(first) then
					table.insert(out, "|");
					first = false;
				end
				Kitty.Share.serializeValue2(key, out, depth + 1, true);
				Kitty.Share.serializeValue2(item, out, depth + 1, false);
			end
		end
		table.insert(out, "}");
	else
		error("Cannot export a value of type " .. valueType .. ".");
	end
end;
Kitty.Share.serialize2 = function(value)
	local out = {};
	Kitty.Share.serializeValue2(value, out, 0, false);
	return table.concat(out);
end;
Kitty.Share.parseValue2 = function(data, pos, depth)
	local tag = string.sub(data, pos, pos);
	if(string.find(tag, "^%d$")) then
		return tonumber(tag), pos + 1;
	elseif(tag == "v") then
		local stop = string.find(data, ";", pos + 1, true);
		local value = stop and Kitty.Share.VALUE_ALIASES[tonumber(string.sub(data, pos + 1, stop - 1)) or 0];
		if(value == nil) then
			error("bad value");
		end
		return value, stop + 1;
	elseif(tag == "{") then
		if(depth > Kitty.Share.MAX_DEPTH) then
			error("too deep");
		end
		local result = {};
		local inArray = true;
		pos = pos + 1;
		while(true) do
			if(pos > string.len(data)) then
				error("unterminated table");
			end
			local char = string.sub(data, pos, pos);
			if(char == "}") then
				return result, pos + 1;
			elseif(char == "|" and inArray) then
				inArray = false;
				pos = pos + 1;
			elseif(inArray) then
				local value;
				value, pos = Kitty.Share.parseValue2(data, pos, depth + 1);
				table.insert(result, value);
			else
				local key, value;
				key, pos = Kitty.Share.parseValue2(data, pos, depth + 1);
				if(type(key) ~= "string" and type(key) ~= "number") then
					error("bad table key");
				end
				value, pos = Kitty.Share.parseValue2(data, pos, depth + 1);
				result[key] = value;
			end
		end
	end
	-- T, F, n, s, k are the same as version 1
	if(tag == "T" or tag == "F" or tag == "n" or tag == "s" or tag == "k") then
		return Kitty.Share.parseValue(data, pos, depth);
	end
	error("bad data at " .. tostring(pos));
end;
Kitty.Share.parse2 = function(data)
	local value, pos = Kitty.Share.parseValue2(data, 1, 0);
	if(pos ~= string.len(data) + 1) then
		error("extra data");
	end
	return value;
end;

-- Short checksum: the first 4 hex digits of checksum()
Kitty.Share.checksum2 = function(data)
	return string.sub(Kitty.Share.checksum(data), 1, 4);
end;

-- Skill icons can be restored locally; retain icons for other command types.
Kitty.Share.slim = function(commandList)
	local list = Kitty.Share.clean(commandList);
	for _, command in ipairs(list) do
		if(type(command) == "table") then
            -- Only skill icons are reconstructed from the player's skill book.
            if(command.commandType == "skill" or command.commandType == "suitskill") then command.icon = nil; end
			if(command.enable == true) then
				command.enable = nil;
			end
		end
	end
	return list;
end;

-- Version 3: like version 2, but compressed against a codebook both players
-- have (data/ShareDictionary.lua: English skill names and the built-in kitties),
-- so known skills and rows cost a few characters. About 5 times shorter.
--   "CKC3!" .. base85(deflate(data, codebook)) .. "!" .. check(4 hex)
Kitty.Share.PREFIX3 = "CKC3";
Kitty.Share.getDict3 = function()
	if(Kitty.Share.dict3 ~= nil) then
		return Kitty.Share.dict3 or nil;
	end
	Kitty.Share.dict3 = false;
	local deflate = Kitty.Share.getDeflate();
	local text = Kitty.Share.DICT3;
	if(deflate == nil or type(text) ~= "string" or string.len(text) ~= Kitty.Share.DICT3_LENGTH) then
		return nil;
	end
	local ok, dict = pcall(deflate.CreateDictionary, deflate, text, string.len(text), Kitty.Share.DICT3_ADLER);
	if(ok and dict ~= nil) then
		Kitty.Share.dict3 = dict;
	end
	return Kitty.Share.dict3 or nil;
end;
Kitty.Share.exportCommandList = function(commandList)
	local deflate = Kitty.Share.getDeflate();
	if(deflate == nil) then
		return Kitty.Share.exportCommandListV1(commandList);
	end
	local data = Kitty.Share.serialize2(Kitty.Share.slim(commandList));
	local dict = Kitty.Share.getDict3();
	if(dict ~= nil) then
		return Kitty.Share.PREFIX3 .. "!" .. Kitty.Share.base85Encode(deflate:CompressDeflateWithDict(data, dict, {level = 9})) .. "!" .. Kitty.Share.checksum2(data);
	end
	return Kitty.Share.PREFIX2 .. "!" .. Kitty.Share.base85Encode(deflate:CompressDeflate(data, {level = 9})) .. "!" .. Kitty.Share.checksum2(data);
end;
-- The old version 2 code (no codebook), for tests and comparisons
Kitty.Share.exportCommandListV2 = function(commandList)
	local deflate = Kitty.Share.getDeflate();
	local data = Kitty.Share.serialize2(Kitty.Share.slim(commandList));
	return Kitty.Share.PREFIX2 .. "!" .. Kitty.Share.base85Encode(deflate:CompressDeflate(data, {level = 9})) .. "!" .. Kitty.Share.checksum2(data);
end;

-- Body and checksum of a version 2 code, or nil
Kitty.Share.readCode2 = function(text)
	local prefix, body, check = string.match(text, "^(%w+)!(.+)!(%x%x%x%x)$");
	if(prefix ~= Kitty.Share.PREFIX2 and prefix ~= Kitty.Share.PREFIX3) then
		return nil;
	end
	return body, string.lower(check);
end;

-- Fill in icons left out of version 2 codes, from the player's own skill book
Kitty.Share.restoreIcons = function(commandList)
	for _, command in ipairs(commandList) do
		if(type(command) == "table" and command.icon == nil) then
			command.icon = "";
			if((command.commandType == "skill" or command.commandType == "suitskill") and type(command.commandName) == "string" and command.commandName ~= "") then
				local ok, detail = pcall(Kitty.SkillManager.fetchSkill, command.commandName);
				if(ok and type(detail) == "table" and detail.texture) then
					command.icon = detail.texture;
				end
			end
		end
		if(type(command) == "table" and command.enable == nil) then
			command.enable = true;
		end
	end
	return commandList;
end;

-- Returns commandList, droppedCount on success; nil, errorMessage on failure.
Kitty.Share.importCommandList = function(code)
	if(type(code) ~= "string") then
		return nil, Kitty.L("ImportEmpty", "Paste a code into the Import box first.");
	end
	code = string.gsub(code, "%s", "");
	-- Pasted back from a Discord .txt or Pastebin with words around it:
	-- keep from "CKC" to the 4-digit checksum
	local start = string.find(code, "CKC%d!");
	if(start ~= nil and start > 1) then
		code = string.sub(code, start);
	end
	if(start ~= nil and string.sub(code, 1, 5) == "CKC1!") then
		code = string.match(code, "^CKC1![%w%+/=]+!%x+") or code;
	elseif(start ~= nil and not string.find(code, "!%x%x%x%x$")) then
		local last = nil;
		for position in string.gmatch(code, "()!%x%x%x%x") do
			last = position;
		end
		if(last ~= nil) then
			code = string.sub(code, 1, last + 4);
		end
	end
	if(code == "") then
		return nil, Kitty.L("ImportEmpty", "Paste a code into the Import box first.");
	end
	local damaged = Kitty.L("ImportBadChecksum", "The code is damaged or was cut off. Copy the whole code and try again.");
	local ok, commandList;
	local version3 = (string.sub(code, 1, string.len(Kitty.Share.PREFIX3)) == Kitty.Share.PREFIX3);
	if(version3 or string.sub(code, 1, string.len(Kitty.Share.PREFIX2)) == Kitty.Share.PREFIX2) then
		-- Version 2, or 3 (with the codebook)
		local body, check = Kitty.Share.readCode2(code);
		if(body == nil) then
			return nil, damaged;
		end
		local deflate = Kitty.Share.getDeflate();
		if(deflate == nil) then
			return nil, Kitty.L("ImportNoDeflate", "lib/LibDeflate.lua is missing, so this code cannot be read.");
		end
		local dict = nil;
		if(version3) then
			dict = Kitty.Share.getDict3();
			if(dict == nil) then
				return nil, Kitty.L("ImportNoDict", "data/ShareDictionary.lua is missing or changed, so this CKC3 code cannot be read.");
			end
		end
		local compressed = Kitty.Share.base85Decode(body);
		local data = nil;
		if(compressed ~= nil) then
			local okInflate, inflated;
			if(version3) then
				okInflate, inflated = pcall(deflate.DecompressDeflateWithDict, deflate, compressed, dict);
			else
				okInflate, inflated = pcall(deflate.DecompressDeflate, deflate, compressed);
			end
			data = okInflate and inflated or nil;
		end
		if(type(data) ~= "string" or Kitty.Share.checksum2(data) ~= check) then
			return nil, damaged;
		end
		ok, commandList = pcall(Kitty.Share.parse2, data);
		if(ok and type(commandList) == "table") then
			Kitty.Share.restoreIcons(commandList);
		end
	else
		-- Version 1
		local prefix, body, check = string.match(code, "^(%w+)!([%w%+/=]+)!(%x+)$");
		if(prefix ~= Kitty.Share.PREFIX) then
			return nil, Kitty.L("ImportBadPrefix2", "That is not a Cherry's KittyCombo code (it should start with CKC3!, CKC2! or CKC1!).");
		end
		local data = Kitty.Share.base64Decode(body);
		if(data == nil or Kitty.Share.checksum(data) ~= string.lower(check)) then
			return nil, damaged;
		end
		ok, commandList = pcall(Kitty.Share.parse, data);
	end
	if(not ok or type(commandList) ~= "table" or type(commandList.info) ~= "table") then
		return nil, Kitty.L("ImportBadData", "The code could not be read.");
	end

	-- Keep only entries this version understands
	local result = {};
	result.info = {
		["name"] = tostring(commandList.info.name or "Imported"),
		["class"] = tostring(commandList.info.class or "any"),
		["target"] = tostring(commandList.info.target or "all"),
	};
	local dropped = 0;
	for index = 1, #commandList do
		local command = commandList[index];
		if(type(command) == "table") then
			local newCommand = {};
			for key, value in pairs(command) do
				if(type(key) == "string") then
					newCommand[key] = value;
				end
			end
			if(newCommand.commandType == "changemode" and Kitty.ModeUI and Kitty.ModeUI.validModeName(newCommand.commandName)) then
				newCommand.icon = Kitty.ModeUI.iconPath(newCommand.commandName);
			end
			for _, condition in ipairs(command) do
				local conditionType = (type(condition) == "table") and condition.conditionType or nil;
				if(type(conditionType) == "string" and type(Kitty.ComboManager[conditionType .. "Type"]) == "function") then
					table.insert(newCommand, condition);
				else
                    return nil, Kitty.L("ImportUnknownCondition", "Cannot import: unsupported condition <<1>>.", tostring(conditionType or "(missing)"));
				end
			end
			table.insert(result, newCommand);
		end
	end
	if(#result == 0) then
		table.insert(result, {["commandType"]="", ["commandName"]="", ["icon"]="", ["enable"]=true});
	end
	-- old request mode rows become "Mode is on: request"
	if(Kitty.ModeUI and Kitty.ModeUI.migrate) then
		Kitty.ModeUI.migrate({result});
	end
	return result, dropped;
end;
