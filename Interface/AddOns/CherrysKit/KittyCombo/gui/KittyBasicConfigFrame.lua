-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.BasicConfigFrame = {};
-- Widget/data map
Kitty.BasicConfigFrame.relativeList = {
	-- Static texts
	["KittyBasicConfigFrame_VersionLabel"] = Kitty.getTitle(),
	["KittyBasicConfigFrame_TitleLabel"] = Kitty.T("message", "BasicSettingTitle"),
	["KittyBasicConfigFrame_Separator1Label"] = Kitty.T("message", "Separator1Label"),
	["KittyBasicConfigFrame_Separator2Label"] = Kitty.T("message", "Separator2Label"),
	["KittyBasicConfigFrame_ShowDamageTakenThresholdLabel"] = Kitty.T("message", "ShowDamageTakenThresholdLabel"),
	["KittyBasicConfigFrame_ShowDamageDoneThresholdLabel"] = Kitty.T("message", "ShowDamageDoneThresholdLabel"),
	["KittyBasicConfigFrame_ShowDPSTypeLabel"] = Kitty.T("message", "ShowDPSTypeLabel"),
	["KittyBasicConfigFrame_SkipPetTargetLabel"] = Kitty.T("message", "SkipPetTargetLabel"),
	["KittyBasicConfigFrame_UseAutoshotLabel"] = Kitty.T("message", "AutoshotToggle"),
	["KittyBasicConfigFrame_SkipTargetLabel"] = Kitty.T("message", "SkipTargetLabel"),

	["KittyBasicConfigFrame_AutoInvitePartyLabel"] = Kitty.T("message", "AutoInvitePartyLabel"),
	["KittyBasicConfigFrame_AutoAcceptPartyLabel"] = Kitty.T("message", "AutoAcceptPartyLabel"),
	["KittyBasicConfigFrame_GivePartyLeaderLabel"] = Kitty.T("message", "GivePartyLeaderLabel", Kitty.T("keyword", "PromoteToPartyLeader1")),
	["KittyBasicConfigFrame_AutoAssistantLabel"] = Kitty.T("message", "AutoAssistantLabel"),
	["KittyBasicConfigFrame_InstanceLevelLabel"] = Kitty.T("message", "InstanceLevelLabel"),
	["KittyBasicConfigFrame_LootThresholdLabel"] = Kitty.T("message", "LootThresholdLabel"),
	["KittyBasicConfigFrame_ShowInstanceLevelLabel"] = Kitty.T("message", "ShowInstanceLevelLabel"),
	["KittyBasicConfigFrame_ShowModeButtonLabel"] = Kitty.L("ShowModeButtonLabel", "Show [mode button] near the minimap"),
	["KittyBasicConfigFrame_ShowModeTextLabel"] = Kitty.L("ShowModeTextLabel", "Show [current mode] (click it to switch)"),
	["KittyBasicConfigFrame_LockModeButtonLabel"] = Kitty.L("LockModeButtonLabel", "Lock [mode button] and [current mode] in place"),

	["KittyBasicConfigFrame_CommandListButton"] = Kitty.T("message", "CommandListButton"),
	["KittyBasicConfigFrame_ChangelogButton"] = "Changelog",
	["KittyBasicConfigFrame_CloseButton"] = Kitty.T("message", "SaveAndCloseButton"),
	["KittyBasicConfigFrame_CancelButton"] = Kitty.T("message", "CancelButton"),

	-- Dynamic values
	["KittyBasicConfigFrame_ShowDamageTakenThresholdEditBox"] = "showDamageTakenThreshold",
	["KittyBasicConfigFrame_ShowDamageDoneThresholdEditBox"] = "showDamageDoneThreshold",
	["KittyBasicConfigFrame_ShowDPSTypeDropDownMenu"] = "showDPSType",
	["KittyBasicConfigFrame_SkipPetTargetCheckButton"] = "skipPetTarget",
	["KittyBasicConfigFrame_UseAutoshotCheckButton"] = "useAutoshot",
	["KittyBasicConfigFrame_SkipTargetCheckButton"] = "skipTarget",

	["KittyBasicConfigFrame_AutoInvitePartyCheckButton"] = "autoInviteParty",
	["KittyBasicConfigFrame_AutoInvitePartyKeyword1EditBox"] = "keyword1",
	["KittyBasicConfigFrame_AutoInvitePartyKeyword2EditBox"] = "keyword2",
	["KittyBasicConfigFrame_AutoInvitePartyKeyword3EditBox"] = "keyword3",
	["KittyBasicConfigFrame_AutoAcceptPartyCheckButton"] = "autoAcceptParty",
	["KittyBasicConfigFrame_GivePartyLeaderCheckButton"] = "givePartyLeader",
	["KittyBasicConfigFrame_AutoAssistantCheckButton"] = "autoAssistant",
	["KittyBasicConfigFrame_InstanceLevelDropDownMenu"] = "instanceLevel",
	["KittyBasicConfigFrame_LootThresholdCheckButton"] = "lootThreshold",
	["KittyBasicConfigFrame_ShowInstanceLevelCheckButton"] = "showInstanceLevel",
	["KittyBasicConfigFrame_ShowModeButtonCheckButton"] = "showModeButton",
	["KittyBasicConfigFrame_ShowModeTextCheckButton"] = "showModeText",
	["KittyBasicConfigFrame_LockModeButtonCheckButton"] = "lockModeButton",
};

Kitty.BasicConfigFrame.TIPS = {
	ShowModeButton = {"Mode button", "A button near the minimap that shows the Kitty mode that is on.",
		"Click it to see every mode, click a mode to switch to it.", "Modes are used by \"Mode is on\" conditions."},
	ShowModeText = {"Current mode", "Shows [Mode: aoe] near the minimap.", "Click it: a menu of every mode, pick one to switch."},
	LockModeButton = {"Lock the mode button", "On: the button cannot be dragged.", "Off: drag it anywhere with the left mouse button."},
};

--------------------------------------------------------------------------------
-- Initial UI setup
Kitty.BasicConfigFrame.set = function(this)
	-- Text area state
	if(KittyBasicConfigFrame_AutoInvitePartyCheckButton:IsChecked()) then
		-- Enable
		KittyBasicConfigFrame_AutoInvitePartyKeyword1EditBox:Enable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword1EditBox:SetTextColor(1.0, 1.0, 1.0);
		KittyBasicConfigFrame_AutoInvitePartyKeyword2EditBox:Enable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword2EditBox:SetTextColor(1.0, 1.0, 1.0);
		KittyBasicConfigFrame_AutoInvitePartyKeyword3EditBox:Enable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword3EditBox:SetTextColor(1.0, 1.0, 1.0);
	else
		-- Disable
		KittyBasicConfigFrame_AutoInvitePartyKeyword1EditBox:Disable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword1EditBox:SetTextColor(0.5, 0.5, 0.5);
		KittyBasicConfigFrame_AutoInvitePartyKeyword2EditBox:Disable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword2EditBox:SetTextColor(0.5, 0.5, 0.5);
		KittyBasicConfigFrame_AutoInvitePartyKeyword3EditBox:Disable();
		KittyBasicConfigFrame_AutoInvitePartyKeyword3EditBox:SetTextColor(0.5, 0.5, 0.5);
	end
end;

--------------------------------------------------------------------------------
-- Show window
Kitty.BasicConfigFrame.onShow = function(this)
	Kitty.settingToComponent(Kitty.SettingManager.setting.basic, Kitty.BasicConfigFrame.relativeList);

	-- Text area state
	Kitty.BasicConfigFrame.set();
end;
-- Save settings
Kitty.BasicConfigFrame.onSave = function(this)
	Kitty.componentToSetting(Kitty.SettingManager.setting.basic, Kitty.BasicConfigFrame.relativeList);

	-- Notify settings changed
	Kitty.onVariablesChanged(Kitty.SettingManager.setting);
end;
