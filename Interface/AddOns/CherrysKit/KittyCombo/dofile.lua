-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

-- Display name. The folder, slash commands and saved variables keep the
-- original "KittyCombo" names so existing settings carry over.
Kitty.ADDON_NAME = "Cherry's KittyCombo";
Kitty.ADDON_VERSION = "1.7.13";
Kitty.version = Kitty.ADDON_VERSION;	-- read by the Cherry's Kit hub (/ck)
-- Where this addon's files are: its own folder when installed alone, or a
-- subfolder of CherrysKit (the kit's KitPaths.lua sets CherrysKit_Paths).
Kitty.BASE_PATH = (type(CherrysKit_Paths) == "table" and CherrysKit_Paths.KittyCombo) or "interface/addons/KittyCombo/";
if(string.sub(Kitty.BASE_PATH, -1) ~= "/" and string.sub(Kitty.BASE_PATH, -1) ~= "\\") then
	Kitty.BASE_PATH = Kitty.BASE_PATH .. "/";
end
-- Cherry's Kit can turn this addon off (applies after a UI reload).
-- Checked when used, since the kit may load after this folder.
Kitty.isTurnedOff = function()
	return (type(CherrysKit) == "table" and type(CherrysKit.IsEnabled) == "function"
		and not CherrysKit.IsEnabled("KittyCombo"));
end;
-- Inside Cherry's Kit the kit's own minimap button replaces KittyMinimap
Kitty.inKit = function()
	return type(CherrysKit_Paths) == "table";
end;
Kitty.showMinimap = function()
	if(not KittyMinimap) then
		return;
	end
	if(Kitty.inKit()) then
		KittyMinimap:Hide();
	else
		KittyMinimap:Show();
	end
end;
Kitty.turnedOffMessage = function()
	DEFAULT_CHAT_FRAME:AddMessage(Kitty.ADDON_NAME .. " is turned off in Cherry's Kit. Type /ck to turn it on.", 1, 0.5, 0);
end;
Kitty.getTitle = function()
	return Kitty.ADDON_NAME .. " " .. Kitty.ADDON_VERSION;
end;

--------------------------------------------------------------------------------
-- Load a language file
Kitty.loadLanguageFile = function(locale)
	function toName(num) -- shortening TEXT() (only accepts ID between 100000-999999)
		if tonumber(num) == nil then
			return
		end
		result = TEXT("Sys"..num.."_name")
		return result
	end
	return pcall(dofile, Kitty.BASE_PATH .. "locales/lang_" .. tostring(locale) .. ".lua");
end;
-- Look up a localized string
Kitty.T = function(category, key, ...)
	local message = "";
	if(Kitty.locale) then
		-- Look up
		message = Kitty.getData(Kitty.locale, category, key);
		message = Kitty.format(message, ...);
	else
		message = key;
	end

	return message;
end;
-- Text with an English fallback, for strings Cherry's KittyCombo added
-- that the older locale files do not have yet.
Kitty.L = function(key, fallback, ...)
	local message = nil;
	if(Kitty.locale and Kitty.getData) then
		message = Kitty.getData(Kitty.locale, "message", key);
	end
	if(type(message) ~= "string") then
		message = fallback;
	end
	if(Kitty.format) then
		return Kitty.format(message, ...);
	end
	return tostring(message);
end;
Kitty.text = function(categoryList, replaceList)	-- Kitty.text({"category1", "category2", ...}, {replace_data1, replace_data2, ...});
	if(categoryList) then
		if(Kitty.locale) then
			-- Language data loaded
			local message = "";
			if(type(categoryList) == "table") then
				message = Kitty.getData(Kitty.locale, unpack(categoryList));
			else
				message = Kitty.getData(Kitty.locale, categoryList);
			end

			if(type(message) == "string") then
				-- Replace
				if(replaceList) then
					if(type(replaceList) == "table") then
						message = Kitty.format(message, unpack(replaceList));
					else
						message = Kitty.format(message, replaceList);
					end
				end
			else
				message = "NONE";
			end
			return message;
		else
			-- No language data
			local resultText = "";
			if(type(categoryList) == "table") then
				for index, value in ipairs(categoryList) do
					if(index ~= 1) then
						resultText = resultText .. ".";
					end
					resultText = resultText .. value;
				end
			else
				resultText = categoryList;
			end
			return resultText;
		end
	else
		return "NONE";
	end
end;

--------------------------------------------------------------------------------
-- Files to load, in order
Kitty.loadFileList = {
	Kitty.BASE_PATH .. "lib/KittyLib.lua",
	Kitty.BASE_PATH .. "lib/KittyClassLib.lua",
	Kitty.BASE_PATH .. "lib/managers/BuildManager.lua",
	Kitty.BASE_PATH .. "lib/managers/CombatManager.lua",
	Kitty.BASE_PATH .. "lib/managers/PartyManager.lua",
	Kitty.BASE_PATH .. "lib/managers/BuffManager.lua",
	Kitty.BASE_PATH .. "lib/managers/SlotManager.lua",
	Kitty.BASE_PATH .. "lib/managers/SkillManager.lua",
	Kitty.BASE_PATH .. "lib/managers/ActionManagers.lua",
	Kitty.BASE_PATH .. "lib/KittyUILib.lua",
	Kitty.BASE_PATH .. "lib/KittySkin.lua",
	Kitty.BASE_PATH .. "lib/KittyMenuHelp.lua",
	Kitty.BASE_PATH .. "lib/KittyShare.lua",
	Kitty.BASE_PATH .. "data/ShareDictionary.lua",	-- codebook for CKC3 share codes (never change)
	Kitty.BASE_PATH .. "lib/KittyMacro.lua",
	Kitty.BASE_PATH .. "lib/KittyClassIcon.lua",
	Kitty.BASE_PATH .. "lib/KittyChangelog.lua",
	Kitty.BASE_PATH .. "lib/KittyProbe.lua",
	Kitty.BASE_PATH .. "KittyCombo.lua",
	Kitty.BASE_PATH .. "combo/KittyConditions.lua",
	Kitty.BASE_PATH .. "combo/KittyComboEngine.lua",
	Kitty.BASE_PATH .. "combo/KittyPredict.lua",	-- read-only "what fires next" for rom weakauras
	Kitty.BASE_PATH .. "data/InterruptList.lua",	-- casts to interrupt
	Kitty.BASE_PATH .. "data/DefaultKitties.lua",	-- before KittySetting.lua, whose defaults use it
	Kitty.BASE_PATH .. "KittySetting.lua",
	Kitty.BASE_PATH .. "Kitty.lua",
	Kitty.BASE_PATH .. "gui/KittyControl.lua",
	Kitty.BASE_PATH .. "gui/KittyBasicConfigFrame.lua",
	Kitty.BASE_PATH .. "gui/KittyCommandListFrame.lua",
	Kitty.BASE_PATH .. "gui/KittyCommandConfigFrame.lua",
	Kitty.BASE_PATH .. "gui/KittyCommandConditionFrame.lua",
	Kitty.BASE_PATH .. "gui/KittyEventCodeButton.lua",
	Kitty.BASE_PATH .. "gui/KittyModeButton.lua",	-- modes: mode button, request mode
};
Kitty.dofile = function(index)
	-- index: nil = load all, number = one entry of loadFileList, string = a path
	if(index == nil) then
		for _, file in ipairs(Kitty.loadFileList) do
			local result, errorMessage = pcall(dofile, file);
			if(result == false) then
				DEFAULT_CHAT_FRAME:AddMessage("Error:" .. errorMessage, 1, 0, 0);
				break;
			end
		end
	else
		if(type(index) == "number") then
			local result, errorMessage = pcall(dofile, Kitty.loadFileList[index]);
			if(result == false) then
				DEFAULT_CHAT_FRAME:AddMessage("Error:" .. errorMessage, 1, 0, 0);
			end
		elseif(type(index) == "string") then
			local result, errorMessage = pcall(dofile, index);
			if(result == false) then
				DEFAULT_CHAT_FRAME:AddMessage("Error:" .. errorMessage, 1, 0, 0);
			end
		end
	end
end;

--------------------------------------------------------------------------------
-- Run at load
(function()
	-- Load the language
	local result, locale = Kitty.loadLanguageFile(GetLanguage():upper());
	if(result) then
		Kitty.locale = locale;
	else
		result, locale = Kitty.loadLanguageFile("ENEU");	-- Default
		if(result) then
			Kitty.locale = locale;
		else
			DEFAULT_CHAT_FRAME:AddMessage("Error:" .. locale, 1, 0, 0);
		end
	end

	-- Load the files
	Kitty.dofile();
end)();
