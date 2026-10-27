-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Reload UI keeps Kitty, so drop the managers from the last session: they are
-- created again on LOADING_END from the code loaded now.
Kitty.eventQueue = nil;
Kitty.macroManager = nil;
Kitty.slotManager = nil;
Kitty.cooldownManager = nil;
Kitty.combatManager = nil;
Kitty.partyManager = nil;

--------------------------------------------------------------------------------
Kitty.relativeList = {
	["Arcadia"] = true,
	["Axis"] = true,
	["ギルドさぼてん"] = true,
	["Ｆｏｒｔｕｎｅ"] = true,
	["エスケープ"] = true,
	["mayu♪"] = true,
};
-- Buffer for event messages
if(Kitty.areaEventList == nil) then
	Kitty.areaEventList = {};
end

-- Event
Kitty.eventFilter = {};
Kitty.onLoad = function(this)
	Kitty.sendMessage(Kitty.getTitle() .. [[ loaded. Commands: "/kc".]]);
	-- Check
	if((not Kitty.relativeList[GetGuildInfo()]) and (not Kitty.relativeList[UnitName("player")])) then
--		Kitty.sendMessage(Kitty.color("KittyCombo does not support this player. Please contact Miranda.", "DEFAULT", 1, 0, 0);
	end

	-- Register events
	-- Only events onEvent acts on. The original also registered ~35 events
	-- (UNIT_BUFF_CHANGED, CHAT_MSG_CHANNEL, ...) just to log them for the author,
	-- which cost a Lua call each time one fired.
	local events = {
		"VARIABLES_LOADED", "LOADING_END",
		"PARTY_MEMBER_CHANGED", "PARTY_INVITE_REQUEST", "EXCHANGECLASS_SUCCESS",
		"COMBATMETER_DAMAGE", "CHAT_MSG_COMBAT", "CASTING_START", "EXTRA_ACTIONBAR_SHOW",
		"WARNING_MESSAGE", "ACTIONBAR_SLOT_CHANGED", "MACROFRAME_UPDATE",
		"CHAT_MSG_GUILD", "CHAT_MSG_PARTY", "UPDATE_MOUSEOVER_UNIT", "PLAYER_SKILLED_CHANGED",
	};
	Kitty.registeredEvents = events;
	for _, event in ipairs(events) do
		this:RegisterEvent(event);
		Kitty.eventFilter[event] = false;
	end

	SaveVariables(Kitty.SettingManager.VARIABLE_NAME);	-- Without this line nothing is saved (and earlier saved data is lost)

-- Handlers called from events cannot run functions that act on the player
end;

--------------------------------------------------------------------------------
Kitty.targetPetList = {};
Kitty.lastOnUpdateTime = 0.0;
Kitty.onUpdate = function(this, elapsedTime)
	if(Kitty.turnedOff) then
		return;
	end
	local currentTime = Kitty.getTime();
	if((currentTime - Kitty.lastOnUpdateTime) > 0.2) then	-- Update every 0.2 sec
		-- Update
		if(Kitty.combatManager ~= nil) then
			Kitty.combatManager:onUpdate(currentTime);
		end

		if(IsBattleGroundZone()) then	-- CG
			if(Kitty.SettingManager.setting.basic.skipPetTarget) then
				-- Drop a pet target
				if(UnitMaster("target") ~= nil and UnitCanAttack("player", "target")) then	-- Pet owner
					if(UnitName("target") ~= Kitty.T("mob", "Chiron the Centaur")
					and UnitName("target") ~= Kitty.T("mob", "Spirit of the Oak")
					and UnitName("target") ~= Kitty.T("mob", "Oak Walker")) then
						if(Kitty.targetPetList[UnitGUID("target")] == nil) then
							-- Pet never targeted before
							Kitty.targetPetList[UnitGUID("target")] = true;
							TargetNearestEnemy(false);	-- Next Target
						else
							-- Pet targeted before
							Kitty.targetPetList = {};
							TargetUnit();				-- Clear Target
						end
					end
				else
					-- Reset if the target is not a pet
					for key, _ in pairs(Kitty.targetPetList) do
						Kitty.targetPetList[key] = nil;
					end
				end
			end
		end

		-- Run one queued job
		if(Kitty.eventQueue ~= nil) then
			Kitty.eventQueue:execute(currentTime);
		end

		Kitty.lastOnUpdateTime = currentTime;
	end
end;

--------------------------------------------------------------------------------
Kitty.onEvent = function(this, event, arg1, arg2, arg3, arg4)
	-- Turned off in Cherry's Kit: stop listening once all addons have loaded.
	-- The saved settings are left untouched, so turning it back on restores them.
	if(Kitty.turnedOff) then
		return;
	end
	if(event == "VARIABLES_LOADED" and Kitty.isTurnedOff()) then
		Kitty.turnedOff = true;
		for _, registered in ipairs(Kitty.registeredEvents or {}) do
			pcall(function() this:UnregisterEvent(registered); end);
		end
		pcall(function() KittyMinimap:Hide(); end);
		return;
	end
	-- Log only the chosen events
	if(Kitty.isAuthor()) then
		if(Kitty.eventFilter[event] ~= false) then
			Kitty.sendMessage(string.format("%.2f[Sec] [%s], Arg:[%s][%s][%s][%s]",
				Kitty.getTime(), tostring(event), tostring(arg1), tostring(arg2), tostring(arg3), tostring(arg4)));
		end
	end

	----------------------------------------------------------------------------
	-- Combat messages
	if(event == "CHAT_MSG_COMBAT") then	-- Fires before COMBATMETER_DAMAGE
		if(Kitty.combatManager ~= nil) then
			Kitty.combatManager:onChatMessageCombat(arg1);
		end
	end

	----------------------------------------------------------------------------
	-- Combat
	if(event == "COMBATMETER_DAMAGE") then
		if(UnitName("player") == _target) then
			if(_skill == Kitty.T("skill", "Discharge") or _skill == Kitty.T("skill", "Lightning")) then
				PlaySoundByPath("sound/character/creature/frail_youth/death.mp3");	-- (sound)
			else
				if(Kitty.isAuthor()) then
					if(_damage > 1000) then
						PlaySoundByPath("sound/character/creature/dog/dog_aggro.mp3");	-- (sound)
					end
				end
			end
		end

		-- Cast finished check
		if(UnitName("player") == _source) then
			if(Kitty.cooldownManager ~= nil) then
				Kitty.cooldownManager:onSucceed(_skill);
			end
		end

		-- Damage totals
		if(Kitty.combatManager ~= nil) then
			Kitty.combatManager:onCombatmeterDamage(_source, _target, _damage, _skill, _type);
		end
	end

	----------------------------------------------------------------------------
	if(event == "UPDATE_MOUSEOVER_UNIT") then
		-- Target under the mouse
		if(IsBattleGroundZone()) then	-- CG
			if(Kitty.SettingManager.setting.basic.skipPetTarget) then
				-- Target on mouse-over
				if(UnitName("target") == nil or UnitIsUnit("target", "player")) then
					if(UnitName("mouseover") ~= nil and UnitCanAttack("player", "mouseover") and UnitMaster("mouseover") == nil and (not UnitIsDeadOrGhost("mouseover"))) then
						TargetUnit("mouseover");
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "CASTING_START") then
		if(Kitty.cooldownManager ~= nil) then
			-- Cast finished check
			Kitty.cooldownManager:onCast(arg1);
		end
	end

	----------------------------------------------------------------------------
	if(event == "EXTRA_ACTIONBAR_SHOW") then
		if(Kitty.cooldownManager ~= nil) then
			-- Cast finished check for skills that raise an ExSkill icon
			local extraActionManager = Kitty.ExtraActionManager();
			local list = extraActionManager:getExtraActionList();
			for index, value in ipairs(list) do
				Kitty.cooldownManager:onCast(value);
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "PARTY_INVITE_REQUEST") then
		if(Kitty.SettingManager.setting.basic.autoAcceptParty) then
			-- Local functions
			local joinParty = function()
				-- Auto-join party
				local popup = StaticPopup_FindVisible("PARTY_INVITE");
				if(popup == nil) then
					popup = StaticPopup_FindVisible("HONOR_PARTY_INVITE");
				end
				if(popup == nil) then
					popup = StaticPopup_FindVisible("BATTLE_PARTY_INVITE");
				end
				if(popup ~= nil) then
					StaticPopup_OnClick(popup, 1);
				end
			end;

			if(Kitty.eventQueue ~= nil) then
				Kitty.eventQueue:addFunction(500, joinParty);
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "LEADER_CHANNEL_CONFIRM") then
		if(Kitty.isAuthor()) then
			local popup = StaticPopup_FindVisible("LEADER_CHANNEL_CONFIRM");
			if(popup ~= nil) then
				-- Cancel channel change
				StaticPopup_OnClick(popup, 2);
			end
		end
	end

	----------------------------------------------------------------------------
--	if(event == "SYSTEM_MESSAGE") then
			-- Warn when a system message contains a member's name
	--		if(string.find(arg1, Kitty.T("keyword", "FollowingMessage")) == nil) then
	--			for index, unit, name in Kitty.PartyManager.iterator() do
		--			if(string.find(arg1, name)) then
		--				if(Kitty.PartyManager.count() == 1) then
							-- Solo
						--	Kitty.sendMessage(Kitty.T("message", "CalledMessage", Kitty.colorRed(name)));
		--				else
							-- Party
		--					else
								--SendChatMessage(Kitty.T("message", "CalledMessage", Kitty.colorRed(name)), "PARTY");
			--				end
				--		end

				--		if(name == UnitName("player")) then
							-- Sound if it is me
					--	end
				--	end
			--	end
		--	end
		--end
	--end

	----------------------------------------------------------------------------
	if(event == "WARNING_MESSAGE") then
		if(Kitty.cooldownManager ~= nil) then
			if(arg1 == Kitty.T("keyword", "BehindTargetMessage")) then
				PlaySoundByPath("sound/character/creature/nightmare/nightmare_aggro.mp3");	-- (sound)
				-- Cast finished check
				Kitty.cooldownManager:onFail(Kitty.T("skill", "Blind Spot"));
			elseif(arg1 == Kitty.T("keyword", "FrontTargetMessage")) then
				PlaySoundByPath("sound/character/creature/nightmare/nightmare_aggro.mp3");	-- (sound)
				-- Cast finished check
				Kitty.cooldownManager:onFail(Kitty.T("skill", "Blind Stab"));
			end
		end

		if(not IsBattleGroundZone()) then	-- Not CG
			-- Record area events
			if(string.find(arg1, Kitty.T("keyword", "StartAreaEvent"))) then
				if(os and os.date) then
					-- Date and time
					local str = os.date("%Y/%m/%d %H:%M:%S");
					-- Zone name
					local zoneName = GetZoneLocalName(tonumber(GetZoneID())%1000);
					if(zoneName) then
						str = str .. " " .. zoneName .. "/" .. GetZoneName() .. "(" .. GetCurrentParallelID() .. "ch)";
					else
						str = str .. " " .. GetZoneName() .. "(" .. GetCurrentParallelID() .. "ch)";
					end

					table.insert(Kitty.areaEventList, str);

					if(#Kitty.areaEventList > 10) then	-- At most 10 entries
						table.remove(Kitty.areaEventList);
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "CHAT_MSG_SAY") then
		if(arg4 ~= UnitName("player")) then
			if(not string.find(arg1, tostring(Kitty.VERSION))) then
				if(string.find(arg1, Kitty.T("keyword", "VersionConfirm1")) or string.find(arg1, Kitty.T("keyword", "VersionConfirm2"))) then
					-- Version check message
					SendChatMessage(Kitty.T("message", "VersionMessage", tostring(Kitty.VERSION)), "SAY");
				end
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "CHAT_MSG_PARTY") then
		if(Kitty.SettingManager.setting.basic.givePartyLeader) then
			if(string.find(arg1, Kitty.T("keyword", "PromoteToPartyLeader1")) or string.find(arg1, Kitty.T("keyword", "PromoteToPartyLeader2"))) then
				if(IsPartyLeader() or IsRaidLeader()) then
					if(arg4 ~= UnitName("player")) then
						local target = Kitty.PartyManager.searchTarget(arg4);
						if(target ~= nil) then
							PromoteToPartyLeader(target);
							SendChatMessage(Kitty.T("message", "PromoteLeaderMessage", Kitty.colorCyan(arg4)), "PARTY");
						end
					else
						SendChatMessage(Kitty.T("message", "HappenNothingMessage"), "PARTY");
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------
	if(event == "CHAT_MSG_GUILD") then
		if(Kitty.SettingManager.setting.basic.autoInviteParty) then
			local keyword1 = Kitty.SettingManager.setting.basic.keyword1;
			local keyword2 = Kitty.SettingManager.setting.basic.keyword2;
			local keyword3 = Kitty.SettingManager.setting.basic.keyword3;

			-- Search
			local result = false;
			if(keyword1 ~= nil and keyword1 ~= "" and string.find(arg1, keyword1) ~= nil) then
				result = true;
			end
			if(keyword2 ~= nil and keyword2 ~= "" and string.find(arg1, keyword2) ~= nil) then
				result = true;
			end
			if(keyword3 ~= nil and keyword3 ~= "" and string.find(arg1, keyword3) ~= nil) then
				result = true;
			end

			if(result == true) then
				if(arg4 ~= UnitName("player")) then
					if(Kitty.eventQueue ~= nil) then
						if(Kitty.PartyManager.count() == 6) then
							-- Switch to raid
							Kitty.eventQueue:addFunction(500, SwitchToRaid);
						end
						-- Invite to party
						Kitty.eventQueue:addFunction(1000, InviteByName, arg4);
					end
				end
			end
		end
	end

	----------------------------------------------------------------------------
	-- Death
	if(event == "PLAYER_DEAD") then
		-- Hook functions
		if(Kitty.isAuthor()) then
			-- Local functions
			local sayThanks = function(...)
				if(not IsBattleGroundZone()) then	-- Not CG
					Kitty.sendMessage(Kitty.colorGradation(Kitty.T("message", "ThanksMessage"), 0, 255, 255, 0, 0, 255), "SAY");
				end
			end;
			Kitty.Hooks.set("AcceptResurrect", function(original, ...)
				pcall(sayThanks, ...);
				return original(...);
			end);
			Kitty.sendMessage(Kitty.T("message", "DeadMessage", Kitty.colorCyan(tostring(UnitName("player")))));
		end
	end

	----------------------------------------------------------------------------
	-- Revive
	if(event == "PLAYER_ALIVE") then
		-- Unhook functions
		if(Kitty.isAuthor()) then
			-- AcceptResurrect
			Kitty.Hooks.clear("AcceptResurrect");
		end
	end

	----------------------------------------------------------------------------
	if(event == "PARTY_MEMBER_CHANGED") then
		-- Update
		if(Kitty.partyManager ~= nil) then
			Kitty.partyManager:update();
		end
	end

	----------------------------------------------------------------------------
	if(event == "ACTIONBAR_SLOT_CHANGED") then
		-- Autoshot may have moved
		Kitty.autoshotSlot = nil;
		Kitty.autoshotMissing = false;
		-- Update
		if(Kitty.slotManager ~= nil) then
			Kitty.slotManager:onUpdate(arg1);
		end
	end

	----------------------------------------------------------------------------
	-- Skill learned or upgraded: re-read where skills sit in the book (as Diyce does)
	if(event == "PLAYER_SKILLED_CHANGED") then
		Kitty.SkillManager.invalidateIndex();
	end

	if(event == "EXCHANGECLASS_SUCCESS") then
		Kitty.SkillManager.invalidateIndex();
		Kitty.autoshotSlot = nil;
		Kitty.autoshotMissing = false;
		-- Rebuild slot info
		Kitty.slotManager = nil;
		Kitty.slotManager = Kitty.SlotManager();
	end

	----------------------------------------------------------------------------
	-- Macros changed
	if(event == "MACROFRAME_UPDATE") then
		Kitty.macroManager = nil;
		Kitty.macroManager = Kitty.MacroManager(Kitty.eventQueue);
		if(KittyCommandConfigFrame ~= nil and KittyCommandConfigFrame:IsVisible()) then
			Kitty.CommandConfigFrame.refreshMacro();
		end
	end

	----------------------------------------------------------------------------
	-- Script runtime error
	if(event == "SCRIPT_RUNTIME_ERROR") then
		-- nop
	end

	----------------------------------------------------------------------------
	if(event == "VARIABLES_LOADED") then
		-- Settings file loaded
		Kitty.SettingManager.onVariablesLoaded(Kitty.VERSION);
		-- Modes: old request mode conditions, the mode picked last time, the mode button
		if(Kitty.ModeUI and Kitty.ModeUI.afterLoad) then
			Kitty.ModeUI.afterLoad();
		end

		-- AddonManager support
		if(AddonManager ~= nil) then
			local addon = {
				name = Kitty.ADDON_NAME,
				description = Kitty.T("message", "AddonManagerDescription"),
				icon = "Interface/Icons/skill_thi12-2.dds",
				category = "Leveling",
				configFrame = KittyBasicConfigFrame,
				slashCommands = SLASH_KittyCombo2,
				miniButton = KittyAddonManagerMiniButton,
				version = Kitty.ADDON_VERSION,
				author = "Miranda, Cherry",
				disableScript = function()
					Kitty.debugPrint("onDisableScript");
					KittyMinimap:Hide();
					if(Kitty.SettingManager.setting.window ~= nil) then
						Kitty.SettingManager.setting.window.showMinimap = false;
					end
				end,
				enableScript = function()
					Kitty.debugPrint("onEnableScript");
					Kitty.showMinimap();
					if(Kitty.SettingManager.setting.window ~= nil) then
						Kitty.SettingManager.setting.window.showMinimap = true;
					end
				end,
			};
			if(AddonManager.RegisterAddonTable ~= nil) then
				AddonManager.RegisterAddonTable(addon);
			elseif(AddonManager.RegisterAddon ~= nil) then
				AddonManager.RegisterAddon(
					addon.name,
					addon.description,
					addon.icon,
					addon.category,
					addon.configFrame,
					addon.slashCommands,
					addon.miniButton,
					addon.onClickScript,
					addon.version,
					addon.author,
					addon.disableScript,
					addon.enableScript);
			end
		end

		-- Supporting XBar's popup menu(JiJicom, Thank you for your suggestion.)
		if XBARVERSION and XBARVERSION>=1.51 then
			local add = {
				popup = {{
					icon = "Interface/TargetFrame/TargetFrameIcon-THIEF",
					GetText = function() return Kitty.ADDON_NAME; end,
					GetTooltip = function() return "/kc\n\nAuthor: Miranda, Cherry"; end,
					OnClick = function(this, key) ToggleUIFrame(KittyBasicConfigFrame); end,
				}}
			};
			XAddon_Register(add);
		end

	end

	----------------------------------------------------------------------------
	if(event == "SAVE_VARIABLES") then
		-- Just before settings are saved
		-- nop
	end

	----------------------------------------------------------------------------
	-- Initialize
	if(event == "LOADING_END") then
		-- Event queue
		if(Kitty.eventQueue == nil) then
			Kitty.eventQueue = Kitty.EventQueue();

			-- Macro runner
			if(Kitty.macroManager == nil) then
				Kitty.macroManager = Kitty.MacroManager(Kitty.eventQueue);
			end
			-- Add macro shortcut icon kinds
			NUM_ICON_ROWS = 20;
		end

		-- Action bar (shortcut) manager
		if(Kitty.slotManager == nil) then
			Kitty.slotManager = Kitty.SlotManager();
		end

		-- Cooldown tracker
		if(Kitty.cooldownManager == nil) then
			Kitty.cooldownManager = Kitty.CooldownManager();
		end

		-- Combat tracker
		if(Kitty.combatManager == nil) then
			Kitty.combatManager = Kitty.CombatManager();
			-- Display settings
			Kitty.combatManager:setShowDamageDoneThreshold(Kitty.SettingManager.setting.basic.showDamageDoneThreshold);
			Kitty.combatManager:setShowDamageTakenThreshold(Kitty.SettingManager.setting.basic.showDamageTakenThreshold);
			Kitty.combatManager:setShowDPSType(Kitty.SettingManager.setting.basic.showDPSType);
		end

		-- Party tracker
		if(Kitty.partyManager == nil) then
			Kitty.partyManager = Kitty.PartyManager();
			Kitty.partyManager:update();

			if(Kitty.isDebug()) then
				-- Local functions
				local debugParty = function(name, operation, oldTarget, newTarget)
					DEFAULT_CHAT_FRAME:AddMessage("[" .. name .. "]:[" .. operation .. "], Target:[" .. oldTarget .. "]->[" .. newTarget .. "]", 1, 1, 1);
				end;
				-- Register events
				Kitty.partyManager:addListner("DebugParty", debugParty);
			end

			-- Register events
			Kitty.partyManager:addListner("SetPartyState", Kitty.setPartyState);
		else
			-- Update
			Kitty.partyManager:update();
		end

		-- Instance difficulty setting
		Kitty.setPartyState();

		-- Show instance difficulty
		if(Kitty.SettingManager.setting.basic.showInstanceLevel) then
			Kitty.eventQueue:addFunction(2000,
				function()
					local zoneName = GetZoneLocalName(tonumber(GetZoneID())%1000);
					if(zoneName) then
						Kitty.sendMessage(
							Kitty.T("message", "IDLevelMessage",
								Kitty.colorCyan(zoneName .. "/" .. GetZoneName()), Kitty.colorCyan(GetInstanceLevel())
							)
						);
					else
						Kitty.sendMessage(
							Kitty.T("message", "IDLevelMessage",
								Kitty.colorCyan(GetZoneName()), Kitty.colorCyan(GetInstanceLevel())
							)
						);
					end
				end
			);
		end

	end
end;

--------------------------------------------------------------------------------
-- Instance difficulty function
Kitty.setPartyState = function(name, operation, oldTarget, newTarget)
	if(Kitty.SettingManager.setting.basic.autoAssistant == true) then
		if(IsRaidLeader() and Kitty.PartyManager.getPartyState() == Kitty.PartyManager.RAID) then
			-- Make raid assistant
			for index, unit in Kitty.PartyManager.iterator() do
				local result = Kitty.PartyManager.giveAssistant(unit);
				if(result) then
					Kitty.sendMessage(Kitty.T("message", "AssistantMessage", Kitty.colorCyan(tostring(UnitName(unit)))));
				end
			end
		end
	end

	if(Kitty.eventQueue ~= nil) then
		-- Instance difficulty
		local instanceLevel = string.lower(Kitty.SettingManager.setting.basic.instanceLevel);
		if(instanceLevel ~= nil and instanceLevel ~= "none") then
			if(IsPartyLeader() or IsRaidLeader() or Kitty.PartyManager.getPartyState() == Kitty.PartyManager.SOLO) then
				if(instanceLevel ~= GetInstanceLevel()) then
					Kitty.eventQueue:addFunction(500, SetInstanceLevel, instanceLevel);
				end
			end
		end

		-- Dice setting
		if(Kitty.SettingManager.setting.basic.lootThreshold == true) then
			if(IsPartyLeader() or IsRaidLeader()) then
				if(GetLootThreshold() ~= 0) then
					Kitty.eventQueue:addFunction(1000, SetLootThreshold, 0);
				end
			end
		end
	end
end;
