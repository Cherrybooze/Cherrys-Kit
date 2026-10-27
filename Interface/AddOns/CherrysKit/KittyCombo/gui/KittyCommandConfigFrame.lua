-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.CommandConfigFrame = {};
-- Command lists before editing
Kitty.CommandConfigFrame.allCommandList = nil;
-- Index of the command list being edited
Kitty.CommandConfigFrame.targetCommandListIndex = nil;
-- Command list being edited
Kitty.CommandConfigFrame.targetCommandList = nil;
-- Callback to show the parent window
Kitty.CommandConfigFrame.callbackFunc = nil;

Kitty.CommandConfigFrame.dragAndDropManager = nil;

-- Widget/data map
Kitty.CommandConfigFrame.relativeList = {
	-- Static texts
	["KittyCommandConfigFrame_VersionLabel"] = Kitty.getTitle(),
	["KittyCommandConfigFrame_TitleLabel"] = Kitty.T("message", "CommandListTitle"),
	["KittyCommandConfigFrame_CommandListNameLabel"] = Kitty.T("message", "CommandListNameLabel"),
	["KittyCommandConfigFrame_BuildLabel"] = Kitty.T("message", "BuildLabel"),
	["KittyCommandConfigFrame_TargetLabel"] = Kitty.T("message", "CommandListTargetLabel"),

	["KittyCommandConfigFrame_CloseButton"] = Kitty.T("message", "CloseButton"),
	["KittyCommandConfigFrame_CancelButton"] = Kitty.T("message", "CancelButton"),

	-- Priority direction and share codes (Cherry's KittyCombo)
	["KittyCommandConfigFrame_PriorityTopLabel"] = Kitty.L("PriorityTop", "\226\150\178 [Highest priority]: checked first. The first ready command fires"),
	["KittyCommandConfigFrame_PriorityBottomLabel"] = Kitty.L("PriorityBottom", "\226\150\188 [Lowest priority]: checked last"),
	["KittyCommandConfigFrame_ExportLabel"] = Kitty.L("ExportLabel", "Export"),
	["KittyCommandConfigFrame_ExportButton"] = Kitty.L("ExportButton", "Get code"),
	["KittyCommandConfigFrame_ImportLabel"] = Kitty.L("ImportLabel", "Import"),
	["KittyCommandConfigFrame_ImportButton"] = Kitty.L("ImportButton", "Import"),

	-- Dynamic values
	["KittyCommandConfigFrame_CommandListNameEditBox"] = "name",
	["KittyCommandConfigFrame_BuildDropDownMenu"] = "class",
	["KittyCommandConfigFrame_TargetDropDownMenu"] = "target",
};

-- Make a unique name
Kitty.CommandConfigFrame.createUniqueName = function(base, list)
	local index = 0;
	local name = nil;
	repeat
		index = index + 1;
		name = base .. string.format("%03d", index);
	until(list[name] == nil);

	return name;
end;

--------------------------------------------------------------------------------
-- Show window
Kitty.CommandConfigFrame.open = function(allCommandList, index, callbackFunc)
	Kitty.CommandConfigFrame.callbackFunc = callbackFunc;

	Kitty.CommandConfigFrame.allCommandList = allCommandList;
	Kitty.CommandConfigFrame.targetCommandListIndex = index;

	-- Opened from the command list window
	if(Kitty.CommandConfigFrame.targetCommandListIndex > 0) then
		-- DeepCopy
		Kitty.CommandConfigFrame.targetCommandList = Kitty.ListManager(Kitty.copyTable(Kitty.CommandConfigFrame.allCommandList[Kitty.CommandConfigFrame.targetCommandListIndex]));
	else
		-- Make a command list name
		commandListNameList = {};
		for index, commandList in pairs(allCommandList) do
			if(commandList.info ~= nil) then
				commandListNameList[commandList.info.name] = true;
			end
		end
		local _, _, main, sub = Kitty.BuildManager.getClass("player");
		local commandListName = Kitty.CommandConfigFrame.createUniqueName(main .. sub .. "_", commandListNameList);

		-- Create new
		local command = {["info"] = {["name"]=commandListName, ["class"]=main .. sub, ["target"]="all"}, {["commandType"]="", ["commandName"]="", ["icon"]="", ["enable"]=true}};
		Kitty.CommandConfigFrame.targetCommandList = Kitty.ListManager(command);
	end

	Kitty.settingToComponent(Kitty.CommandConfigFrame.targetCommandList.info, Kitty.CommandConfigFrame.relativeList);

	-- Show rows
	Kitty.CommandConfigFrame.onRedraw(this, 1, 10);

	KittyCommandConfigFrame_ImportEditBox:SetText("");
	Kitty.CommandConfigFrame.refreshExport(false);
	Kitty.CommandConfigFrame.refreshMacro();

	KittyCommandConfigFrame:Show();
end;

--------------------------------------------------------------------------------
-- Macro button: green check + macro name when this kitty has a macro,
-- yellow dash when it does not yet.
Kitty.CommandConfigFrame.getEditedName = function()
	return KittyCommandConfigFrame_CommandListNameEditBox:GetText() or "";
end;
Kitty.CommandConfigFrame.refreshMacro = function()
	local kittyName = Kitty.CommandConfigFrame.getEditedName();
	local slot, macroName = Kitty.Macro.find(kittyName);
	if(slot ~= nil) then
		KittyCommandConfigFrame_MacroStatusIcon:SetText("\226\156\148");
		KittyCommandConfigFrame_MacroStatusIcon:SetColor(0.2, 1.0, 0.2);
		KittyCommandConfigFrame_MacroStatusLabel:SetText(Kitty.L("MacroExists", "Macro: <<1>> (slot <<2>>)", tostring(macroName), slot));
		KittyCommandConfigFrame_MacroStatusLabel:SetColor(0.2, 1.0, 0.2);
		KittyCommandConfigFrame_MacroButton:SetText(Kitty.L("MacroPickUpButton", "Pick up macro"));
	else
		KittyCommandConfigFrame_MacroStatusIcon:SetText("\226\128\147");
		KittyCommandConfigFrame_MacroStatusIcon:SetColor(1.0, 0.85, 0.0);
		KittyCommandConfigFrame_MacroStatusLabel:SetText(Kitty.L("MacroMissing", "No macro yet: <<1>>", Kitty.Macro.getName(kittyName)));
		KittyCommandConfigFrame_MacroStatusLabel:SetColor(1.0, 0.85, 0.0);
		KittyCommandConfigFrame_MacroButton:SetText(Kitty.L("MacroCreateButton", "Create macro"));
	end
end;
-- Create the macro (or reuse the existing one) and put it on the cursor
Kitty.CommandConfigFrame.createMacro = function()
	local kittyName = Kitty.CommandConfigFrame.getEditedName();
	local slot, result, created = Kitty.Macro.create(kittyName);
	if(slot == nil) then
		Kitty.sendMessage(result, "DEFAULT", 1, 0, 0);
		return;
	end
	Kitty.CommandConfigFrame.refreshMacro();
	pcall(function() PickupMacroItem(slot); end);

	local message;
	if(created) then
		message = Kitty.L("MacroCreated", "Created macro <<1>> in slot <<2>>. It is on your cursor: click an action bar slot to place it.", Kitty.colorCyan(result), slot);
	else
		message = Kitty.L("MacroPickedUp", "Macro <<1>> (slot <<2>>) is on your cursor: click an action bar slot to place it.", Kitty.colorCyan(result), slot);
	end
	-- The macro calls the kitty by its saved name
	local index = Kitty.CommandConfigFrame.targetCommandListIndex or 0;
	local saved = Kitty.CommandConfigFrame.allCommandList and Kitty.CommandConfigFrame.allCommandList[index];
	if(index <= 0 or saved == nil or saved.info == nil or saved.info.name ~= kittyName) then
		message = message .. " " .. Kitty.L("MacroNeedsSave", "Press Save so the macro can find this kitty.");
	end
	Kitty.sendMessage(message);
end;

--------------------------------------------------------------------------------
-- Share codes
-- Put the current (unsaved) kitty's code in the Export box.
Kitty.CommandConfigFrame.refreshExport = function(selectText)
	local commandList = Kitty.CommandConfigFrame.targetCommandList;
	if(commandList == nil) then
		return;
	end
	local ok, code = pcall(Kitty.Share.exportCommandList, commandList);
	if(not ok) then
		Kitty.sendMessage(tostring(code), "DEFAULT", 1, 0, 0);
		code = "";
	end
	KittyCommandConfigFrame_ExportEditBox:SetText(code);
	Kitty.CommandConfigFrame.showExportLength(code);
	if(selectText) then
		-- The code also stays selected in the box, in case the clipboard did not take it
		Kitty.CommandConfigFrame.selectExportText();
		if(code ~= "" and Kitty.copyToClipboard(code)) then
			Kitty.sendMessage(Kitty.L("ExportCopied", "Copied to Windows clipboard! Ctrl+V to share or import."), "DEFAULT", 0.3, 1, 0.3);
		elseif(code ~= "") then
			-- Too long for the game's clipboard (or no clipboard): Ctrl+C from the box
			Kitty.sendMessage(Kitty.L("ExportPressCtrlC", "Press Ctrl+C to copy! (the code is selected in the Export box)"), "DEFAULT", 1, 0.25, 0.25);
		end
	end
end;
-- Character count under the Export box; orange warning when chat can't take it
Kitty.CommandConfigFrame.showExportLength = function(code)
	local length = string.len(code or "");
	local label = KittyCommandConfigFrame_ExportLengthLabel;
	if(length == 0) then
		label:SetText("");
	elseif(length <= Kitty.Share.CHAT_LIMIT) then
		label:SetText(Kitty.L("ExportFitsChat", "Code: <<1>> characters. Fits in one chat message.", length));
		label:SetColor(0.4, 1.0, 0.4);
	else
		label:SetText(Kitty.L("ExportTooLongForChat", "Code: <<1>> characters. In-game chat only supports <<2>>: share this kitty on Discord or elsewhere.", length, Kitty.Share.CHAT_LIMIT));
		label:SetColor(1.0, 0.6, 0.2);
	end
end;
Kitty.CommandConfigFrame.selectExportText = function()
	local editBox = KittyCommandConfigFrame_ExportEditBox;
	pcall(function() editBox:SetFocus(); end);
	if(editBox.HighlightText) then
		pcall(function() editBox:HighlightText(); end);
	end
end;
-- Replace the commands being edited with the code in the Import box.
Kitty.CommandConfigFrame.importCode = function()
	local code = KittyCommandConfigFrame_ImportEditBox:GetText();
	local commandList, result = Kitty.Share.importCommandList(code);
	if(commandList == nil) then
		Kitty.sendMessage(result, "DEFAULT", 1, 0, 0);
		return;
	end

	-- Avoid clashing with another kitty's name (the one being edited may keep its name)
	local names = {};
	for index, other in ipairs(Kitty.CommandConfigFrame.allCommandList or {}) do
		if(index ~= Kitty.CommandConfigFrame.targetCommandListIndex and other.info ~= nil) then
			names[other.info.name] = true;
		end
	end
	if(names[commandList.info.name]) then
		commandList.info.name = Kitty.CommandConfigFrame.createUniqueName(commandList.info.name .. "_", names);
	end

	Kitty.CommandConfigFrame.targetCommandList = Kitty.ListManager(commandList);
	Kitty.settingToComponent(Kitty.CommandConfigFrame.targetCommandList.info, Kitty.CommandConfigFrame.relativeList);
	Kitty.CommandConfigFrame.onRedraw(KittyCommandConfigFrame, 1, 10);
	KittyCommandConfigFrame_ImportEditBox:SetText("");
	Kitty.CommandConfigFrame.refreshExport(false);
	Kitty.CommandConfigFrame.refreshMacro();

	local message = Kitty.L("ImportDone", "Imported <<1>> (<<2>> commands). Press Save to keep it.", Kitty.colorCyan(commandList.info.name), #commandList);
	if(result and result > 0) then
		message = message .. " " .. Kitty.L("ImportDropped", "<<1>> conditions were skipped because this version does not know them.", result);
	end
	Kitty.sendMessage(message);
end;

Kitty.CommandConfigFrame.update = function(commandList)
	Kitty.CommandConfigFrame.targetCommandList = commandList;

	-- Show rows
	Kitty.CommandConfigFrame.onRedraw(this, 1, 10);

	KittyCommandConfigFrame:Show();
end;

Kitty.CommandConfigFrame.save = function()
	Kitty.componentToSetting(Kitty.CommandConfigFrame.targetCommandList.info, Kitty.CommandConfigFrame.relativeList);

	if(Kitty.CommandConfigFrame.targetCommandListIndex > 0) then
		-- Update
		Kitty.CommandConfigFrame.allCommandList[Kitty.CommandConfigFrame.targetCommandListIndex] = Kitty.CommandConfigFrame.targetCommandList;
	else
		-- Create new
		table.insert(Kitty.CommandConfigFrame.allCommandList, 1, Kitty.CommandConfigFrame.targetCommandList);
	end

	-- Notify settings changed
--	Kitty.onVariablesChanged(Kitty.SettingManager.setting);
end;
Kitty.CommandConfigFrame.close = function()
	Kitty.CommandConfigFrame.allCommandList = nil;
	Kitty.CommandConfigFrame.targetCommandListIndex = nil;
	Kitty.CommandConfigFrame.targetCommandList = nil;
	Kitty.CommandConfigFrame.callbackFunc = nil;

	KittyCommandConfigFrame:Hide();
end;

-- On click
Kitty.CommandConfigFrame.onClick = function(this)
	local index = KittyCommandConfigFrame_ScrollBar:GetValue() + this:GetParent():GetID() - 1;
	KittyCommandConfigFrame:Hide();
	Kitty.CommandConditionFrame.open(Kitty.CommandConfigFrame.targetCommandList, index, Kitty.CommandConfigFrame.update);
end;

Kitty.CommandConfigFrame.onShow = function(this)
	-- Start hooks
	if(Kitty.CommandConfigFrame.dragAndDropManager == nil) then
		Kitty.CommandConfigFrame.dragAndDropManager = Kitty.DragAndDropManager();
	end
	Kitty.CommandConfigFrame.dragAndDropManager:startHook();
end;
Kitty.CommandConfigFrame.onHide = function(this)
	-- End hooks
	if(Kitty.CommandConfigFrame.dragAndDropManager ~= nil) then
		Kitty.CommandConfigFrame.dragAndDropManager:endHook()
	end
end;

-- Drop
Kitty.CommandConfigFrame.onDrop = function(this)
	-- Get info about the dropped icon
	local cursorType, index1, index2 = Kitty.CommandConfigFrame.dragAndDropManager:getInfo();
	Kitty.CommandConfigFrame.dragAndDropManager:clear();

	if(cursorType ~= CursorItemType()) then
		-- Cursor type changed since the drag started
		return;
	end

	-- SkillManager
	local skillManager = Kitty.SkillManager(Kitty.cooldownManager);
	skillManager:update();

	-- Get the command
	local index = KittyCommandConfigFrame_ScrollBar:GetValue() + this:GetParent():GetID() - 1;
	local command = Kitty.CommandConfigFrame.targetCommandList[index];

	-- Handle each kind of drop
	if(cursorType == Kitty.DragAndDropManager.SKILL) then
		--------------------------------------------------------------------------------
		-- Skill
		ItemClipboard_Clear();	-- Clear the cursor

		local skillName, _, icon, skillType, rank, _, upgradeCost, isSkillable, isAvailable = GetSkillDetail(index1, index2);
		if(skillName ~= nil) then
			command.commandType = "skill";
			command.commandName = skillName;
			command.icon = icon;
		end
	elseif(cursorType == Kitty.DragAndDropManager.ACTION) then
		--------------------------------------------------------------------------------
		-- Action
		PickupAction(index1);	-- Clear the cursor

		-- Shortcut
		local icon, macroName, count, locked, wore, continued = GetActionInfo(index1);
		local name = Kitty.SlotManager.getActionName(KittyComboGameTooltip, index1);
		if(name ~= nil) then
			name = Kitty.SlotManager.getPureName(name);	-- Strip upgrade values such as +70

			-- Shortcut kind
			local actionType = Kitty.CommandConfigFrame.getActionType(name);
			if(actionType == Kitty.DragAndDropManager.SKILL) then
				-- Skill
				command.commandType = "skill";
				command.commandName = name;
				command.icon = icon;
			elseif(actionType == Kitty.DragAndDropManager.SUIT_SKILL) then
				-- SuitSkill
				command.commandType = "suitskill";
				command.commandName = name;
				command.icon = icon;
			elseif(actionType == Kitty.DragAndDropManager.EMOTE) then
				-- Emote
				command.commandType = "emote";
				command.commandName = name;
				command.icon = icon;
			elseif(actionType == Kitty.DragAndDropManager.MACRO) then
				-- Macro
				command.commandType = "macro";
				command.commandName = name;
				command.icon = icon;
			else	-- actionType == Kitty.DragAndDropManager.ACTION
				-- Action
				command.commandType = "action";
				command.commandName = name;
				command.icon = icon;
			end
		end
	elseif(cursorType == Kitty.DragAndDropManager.BAG) then
		--------------------------------------------------------------------------------
		-- Item
		PickupBagItem(index1);	-- Clear the cursor

		SendWarningMsg(Kitty.T("message", "CanNotUseItemMessage"));
		SendWarningMsg(Kitty.T("message", "CanUseFromShortcutMessage"));
	elseif(cursorType == Kitty.DragAndDropManager.EQUIP) then
		--------------------------------------------------------------------------------
		-- Equipment
		PickupEquipmentItem(index1);	-- Clear the cursor

		SendWarningMsg(Kitty.T("message", "CanNotSetEquipmentMessage"));
	elseif(cursorType == Kitty.DragAndDropManager.BANK) then
		--------------------------------------------------------------------------------
		-- Bank
		PickupBankItem(index1);	-- Clear the cursor

		SendWarningMsg(Kitty.T("message", "CanNotSetBankItemMessage"));
	elseif(cursorType == Kitty.DragAndDropManager.EMOTE) then
		--------------------------------------------------------------------------------
		-- Emote
		ItemClipboard_Clear();	-- Clear the cursor

		local index, name1, name2, icon = GetEmoteInfo(index1 - 1);
		if(index ~= nil) then
			-- Get the command
			command.commandType = "emote";
			command.commandName = name1;
			command.value = index;
			command.icon = icon;
		end
	elseif(cursorType == Kitty.DragAndDropManager.MACRO) then
		--------------------------------------------------------------------------------
		-- Macro
		ItemClipboard_Clear();	-- Clear the cursor

		local index, name, body = GetMacroInfo(index1);
		if(index ~= nil) then
			local icon = GetMacroIconInfo(index);
			command.commandType = "macro";
			command.commandName = name;
			command.icon = icon;
		end
	elseif(cursorType == Kitty.DragAndDropManager.SUIT_SKILL) then
		--------------------------------------------------------------------------------
		-- Suit skill (list)
		ItemClipboard_Clear();	-- Clear the cursor

		local name, icon = skillManager:getSuitSkill(index1);
		if(name ~= nil) then
			command.commandType = "suitskill";
			command.commandName = name;
			command.icon = icon;
		end
	elseif(cursorType == Kitty.DragAndDropManager.SUIT_SKILL_PLATE) then
		--------------------------------------------------------------------------------
		-- Suit skill (plate)
		ItemClipboard_Clear();	-- Clear the cursor

		local name, icon = SkillPlateUpdate(index1);
		if(name ~= nil) then
			command.commandType = "suitskill";
			command.commandName = name;
			command.icon = icon;
		end
	else
		-- Error
		Kitty.sendMessage("Error: Not support. CursorType:[" .. cursorType .. "]", "DEFAULT", 1, 0, 0);
	end

	-- Update row
	Kitty.CommandConfigFrame.onRedraw(KittyCommandConfigFrame, tonumber(KittyCommandConfigFrame_ScrollBar:GetValue()), 10);

	skillManager = nil;
end;

-- Store the values shown in the list rows into the data
Kitty.CommandConfigFrame.allowUpdateData = true;
Kitty.CommandConfigFrame.updateData = function(this)
	if(Kitty.CommandConfigFrame.allowUpdateData) then
		Kitty.debugPrint("Kitty.CommandConfigFrame.updateData");
	else
		Kitty.debugPrint("Kitty.CommandConfigFrame.updateData Canceled.");
		return;
	end

	local info = {};
	-- Update the header
	local commandListNameEditBox = getglobal("KittyCommandConfigFrame_CommandListNameEditBox");
	assert(commandListNameEditBox, "KittyCommandConfigFrame_CommandListNameEditBox is nil");
	info.name = commandListNameEditBox:GetText();

	local buildDropDownMenu = getglobal("KittyCommandConfigFrame_BuildDropDownMenu");
	assert(buildDropDownMenu, "KittyCommandConfigFrame_BuildDropDownMenu is nil");
	info.class = UIDropDownMenu_GetText(buildDropDownMenu);

	local targetDropDownMenu = getglobal("KittyCommandConfigFrame_TargetDropDownMenu");
	assert(targetDropDownMenu, "KittyCommandConfigFrame_TargetDropDownMenu is nil");
	info.target = UIDropDownMenu_GetText(targetDropDownMenu);

	Kitty.CommandConfigFrame.targetCommandList.info = info;

	if(this ~= nil) then
		-- Update the row in the list
		local index = KittyCommandConfigFrame_ScrollBar:GetValue() + this:GetID() - 1;
		local command = {};
		for index, condition in ipairs(Kitty.CommandConfigFrame.targetCommandList[index]) do
			command[index] = condition;
		end

		-- Enabled/disabled check box
		local checkButton = getglobal(this:GetName() .. "CheckButton");
		assert(checkButton, this:GetName() .. "CheckButton is nil");
		command.enable = checkButton:IsChecked();

		-- Dropdown (command type)
		local dropDownMenu = getglobal(this:GetName() .. "DropDownMenu");
		assert(dropDownMenu, this:GetName() .. "DropDownMenu is nil");
		command.commandType = UIDropDownMenu_GetText(dropDownMenu);

		if(command.commandType ~= "proc") then
			-- Edit box (command name)
			local commandNameEditBox = getglobal(this:GetName() .. "CommandNameEditBox");
			assert(commandNameEditBox, this:GetName() .. "CommandNameEditBox is nil");
			command.commandName = commandNameEditBox:GetText();
		else
			-- Dropdown (proc name)
			local commandDropDownMenu = getglobal(this:GetName() .. "CommandDropDownMenu");
			assert(dropDownMenu, this:GetName() .. "CommandDropDownMenu is nil");
			command.commandName = UIDropDownMenu_GetText(commandDropDownMenu);
		end

		-- Command icon
		if(command.commandType == "extra" or command.commandType == "proc" or command.commandType == "break" or command.commandType == "debug") then
			command.icon = nil;
		else
			command.icon = Kitty.CommandConfigFrame.targetCommandList[index].icon;
		end

		-- Condition button
--		local conditionButton = getglobal(this:GetName() .. "ConditionButton");
--		assert(conditionButton, this:GetName() .. "ConditionButton is nil");

		Kitty.CommandConfigFrame.targetCommandList[index] = command;
	end
end;

-- Show the command list rows
Kitty.CommandConfigFrame.onRedraw = function(this, start, count)
	local position = KittyCommandConfigFrame_ScrollBar:GetValue();
	if(start == position) then
		-- Redraw
		Kitty.CommandConfigFrame.onShowList(KittyCommandConfigFrame_ScrollBar, start, count);
	else
		-- Update the scroll bar (it redraws afterwards)
		KittyCommandConfigFrame_ScrollBar:SetValue(start);
	end
end;
Kitty.CommandConfigFrame.onShowList = function(this, start, count)
	Kitty.CommandConfigFrame.allowUpdateData = false;
	Kitty.debugPrint("Kitty.CommandConfigFrame.onShowList");

	if(count ~= nil) then
		count = 10;
	end

	-- Work out the slider range
	local aboveRange = start - 1;	-- Rows that can scroll up
	if(aboveRange < 0) then
		aboveRange = 0;
	end
	local belowRange = 0;
	if(Kitty.CommandConfigFrame.targetCommandList ~= nil) then
		belowRange = #Kitty.CommandConfigFrame.targetCommandList - count - (start - 1);	-- Rows that can scroll down
	end
	if(belowRange < 0) then
		belowRange = 0;
	end
	local range = aboveRange + belowRange + 1;

	if(range <= 0) then
		-- No slider needed
		this:SetMinMaxValues(1, 1);
	else
		this:SetMinMaxValues(1, range);
	end

	-- Debug
	local min, max = this:GetMinMaxValues();
	Kitty.debugPrint("Scroll Value:[" .. tostring(this:GetValue()) .. "], Range:[" .. min .. ", " .. max .. "], Above:[" .. aboveRange .. "], Below:[" .. belowRange .. "]");

	-- Show rows
	local position = 1;
	for index=start, start+count-1 do
		local detailButton = getglobal("KittyCommandConfigFrame_Button" .. tostring(position));
		assert(detailButton, "KittyCommandConfigFrame_Button" .. tostring(position) .. " is nil.");

		-- Update row
		if(Kitty.CommandConfigFrame.targetCommandList ~= nil) then
			local command = Kitty.CommandConfigFrame.targetCommandList[index];
			if(command ~= nil) then
				Kitty.CommandConfigFrame.showDetail(detailButton, command, index, #Kitty.CommandConfigFrame.targetCommandList);
				detailButton:Show();
			else
				detailButton:Hide();
			end
		end

		position = position + 1;
	end

	Kitty.CommandConfigFrame.allowUpdateData = true;
end;

-- Show the data in the list rows
Kitty.CommandConfigFrame.showDetail = function(this, command, index, total)
	-- Priority number: green at the top (checked first) fading to orange at the bottom
	local rankLabel = getglobal(this:GetName() .. "Rank");
	if(rankLabel ~= nil and index ~= nil) then
		local ratio = 0;
		if(total ~= nil and total > 1) then
			ratio = (index - 1) / (total - 1);
		end
		rankLabel:SetText(tostring(index));
		if(command.enable == false) then
			rankLabel:SetColor(0.5, 0.5, 0.5);
		else
			rankLabel:SetColor(0.2 + 0.8 * ratio, 1.0 - 0.5 * ratio, 0.2 * (1 - ratio));
		end
	end

	-- Enabled/disabled check box
	local checkButton = getglobal(this:GetName() .. "CheckButton");
	assert(checkButton, this:GetName() .. "CheckButton is nil");
	checkButton:SetChecked(command.enable);

	-- Command icon
	local iconButton = getglobal(this:GetName() .. "ActionButtonIcon");
	assert(iconButton, this:GetName() .. "ActionButtonIcon is nil");
	if(command.icon ~= nil) then
		iconButton:SetFile(command.icon);
	else
		iconButton:SetFile("");
	end

	-- Dropdown (command type)
	local dropDownMenu = getglobal(this:GetName() .. "DropDownMenu");
	assert(dropDownMenu, this:GetName() .. "DropDownMenu is nil");
	UIDropDownMenu_SetText(dropDownMenu, tostring(command.commandType));

	-- Edit box (command name)
	local editBox = getglobal(this:GetName() .. "CommandNameEditBox");
	assert(editBox, this:GetName() .. "CommandNameEditBox is nil");
	-- Dropdown (command name)
	local commandDropDownMenu = getglobal(this:GetName() .. "CommandDropDownMenu");
	assert(dropDownMenu, this:GetName() .. "CommandDropDownMenu is nil");
	if(command.commandType ~= "proc") then
		-- Show the edit box
		editBox:SetText(tostring(command.commandName));
		UIDropDownMenu_SetText(commandDropDownMenu, tostring(""));

		editBox:Show();
		commandDropDownMenu:Hide();
	else
		-- Show the dropdown
		editBox:SetText(tostring(""));
		UIDropDownMenu_SetText(commandDropDownMenu, tostring(command.commandName));

		editBox:Hide();
		commandDropDownMenu:Show();
	end

	-- Condition button
	local conditionButton = getglobal(this:GetName() .. "ConditionButton");
	assert(conditionButton, this:GetName() .. "ConditionButton is nil");
	-- Show the count after splitting
	conditionButton:SetText(Kitty.T("message", "Condition") .. "(" .. #Kitty.CommandConditionFrame.separate(command) .. ")");
end;

-- Work out from a name whether it is a skill, macro, etc.
Kitty.CommandConfigFrame.getActionType = function(actionName)
	local skillManager = Kitty.SkillManager(Kitty.cooldownManager);
	skillManager:update();

	local tabIndex, skillIndex, index = skillManager:getIndex(actionName);
	if(tabIndex ~= nil) then
		if(skillManager:isSuitSkill(actionName)) then
			-- SuitSkill
			return Kitty.DragAndDropManager.SUIT_SKILL, index;
		else
			-- Skill
			return Kitty.DragAndDropManager.SKILL, tabIndex, skillIndex;
		end
	end

	-- Emote
	local emotionManager = Kitty.EmotionManager();
	local emotionIndex = emotionManager:getIndex(actionName);
	if(emotionIndex ~= nil) then
		return Kitty.DragAndDropManager.EMOTE, emotionIndex;
	end

	-- Macro
	local macroIndex = Kitty.macroManager:getIndex(actionName);
	if(macroIndex ~= nil) then
		return Kitty.DragAndDropManager.MACRO, macroIndex;
	end

	-- Action
	local slotIndex = Kitty.slotManager:getIndex(actionName);
	if(slotIndex ~= nil) then
		return Kitty.DragAndDropManager.ACTION, slotIndex;
	end

	return nil;

	-- Not supported yet:
	-- Bag: Kitty.DragAndDropManager.BAG
	-- Equip: Kitty.DragAndDropManager.EQUIP
	-- Bank: Kitty.DragAndDropManager.BANK
end;
