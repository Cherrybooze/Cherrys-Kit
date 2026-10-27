-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Settings
Kitty.SettingManager = {};
Kitty.SettingManager.VARIABLE_NAME = "KittyCombo_Setting";	-- Must be a global name
Kitty.SettingManager.setting = {};	-- Values
Kitty.SettingManager.setting.window = {};
Kitty.SettingManager.setting.basic = {};
Kitty.SettingManager.setting.gradation = {};
Kitty.SettingManager.setting.command = {};

Kitty.SettingManager.onVariablesLoaded = function(version)
	local settingFromFile = _G[Kitty.SettingManager.VARIABLE_NAME];

	local settingToFile = {};
	if(settingFromFile == nil) then
		-- Nothing saved yet
		settingToFile = Kitty.SettingManager.defaultSetting;
	elseif(type(settingFromFile) == "table") then
		-- Saved data found
		-- Copy section by section so stray keys are dropped

		-- Window position
		if(settingFromFile.window == nil) then
			-- Defaults
			settingToFile.window = Kitty.SettingManager.defaultSetting.window;
		else
			settingToFile.window = settingFromFile.window;
		end

		-- Basic settings
		if(settingFromFile.basic == nil) then
			-- Defaults
			settingToFile.basic = Kitty.SettingManager.defaultSetting.basic;
		else
			settingToFile.basic = settingFromFile.basic;

			if(settingToFile.basic.showDamageDoneThreshold == nil) then
				settingToFile.basic.showDamageDone = nil;	-- Drop an old key
				settingToFile.basic.showDamageDoneThreshold = Kitty.SettingManager.defaultSetting.basic.showDamageDoneThreshold;
			end
		end

		-- Chat gradient colors
		if(settingFromFile.gradation == nil) then
			-- Defaults
			settingToFile.gradation = Kitty.SettingManager.defaultSetting.gradation;
		else
			settingToFile.gradation = settingFromFile.gradation;
		end

		-- Command lists
		if(settingFromFile.command == nil) then
			-- Defaults
			settingToFile.command = Kitty.copyTable(Kitty.SettingManager.defaultSetting.command);
		else
			settingToFile.command = settingFromFile.command;
		end
		-- Cherry's KittyCombo additions: own interrupt casts, modes, clipboard limit
		settingToFile.interrupt = settingFromFile.interrupt;
		settingToFile.mode = settingFromFile.mode;
		settingToFile.clipMax = settingFromFile.clipMax;
	else
		error("Error: Stored data is not table format. Data:[" .. tostring(settingFromFile) .. "]");
	end
	-- Remember the version
	settingToFile.version = version;

	_G[Kitty.SettingManager.VARIABLE_NAME] = settingToFile;
	Kitty.SettingManager.setting = _G[Kitty.SettingManager.VARIABLE_NAME];
end;

-- Default settings
Kitty.SettingManager.defaultSetting = {};
Kitty.SettingManager.defaultSetting.window = {
	-- Frame position
	["framePositionX"] = 100,
	["framePositionY"] = 100,
	-- Show the minimap button
	["showMinimap"] = true,
};
Kitty.SettingManager.defaultSetting.basic = {
	["skipTarget"] = true,
	["useAutoshot"] = true,
	-- Show damage taken at or above this (0 = off)
	["showDamageTakenThreshold"] = 0,	-- 0 = off
	-- Show damage done at or above this (0 = off)
	["showDamageDoneThreshold"] = 0,	-- 0 = off
	-- DPS report: "None", "Normal" or "Detail"
	["showDPSType"] = "None",
	-- Skip pet targets (battlegrounds only)
	["skipPetTarget"] = true,
	-- Auto invite on keyword
	["autoInviteParty"] = false,
	["keyword1"] = Kitty.T("keyword", "InviteParty1"),
	["keyword2"] = Kitty.T("keyword", "InviteParty2"),
	["keyword3"] = Kitty.T("keyword", "InviteParty3"),
	-- Auto accept party invites
	["autoAcceptParty"] = false,
	-- Give party lead on request
	["givePartyLeader"] = true,
	-- Auto raid assistant
	["autoAssistant"] = true,
	-- Instance difficulty: "None", "Easy", "Normal", "Hard"
	["instanceLevel"] = Kitty.T("message", "None"),
	-- Set loot threshold to white
	["lootThreshold"] = false,
	-- Show instance difficulty
	["showInstanceLevel"] = false,
	-- Mode button near the minimap, and whether it can be dragged
	["showModeButton"] = false,
	["showModeText"] = false,
	["lockModeButton"] = false,
};
Kitty.SettingManager.defaultSetting.gradation = {
	["startR"] = 0,
	["startG"] = 255,
	["startB"] = 255,
	["endR"] = 255,
	["endG"] = 255,
	["endB"] = 255,
	["messageType"] = "DEFAULT",
};
Kitty.SettingManager.defaultSetting.command = Kitty.ComboManager.commandList;
