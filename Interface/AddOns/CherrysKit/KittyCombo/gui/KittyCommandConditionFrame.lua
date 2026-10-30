-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.CommandConditionFrame = {};

-- Command list before editing
Kitty.CommandConditionFrame.commandList = nil;
-- Index of the command being edited
Kitty.CommandConditionFrame.targetCommandIndex = nil;
-- Command being edited
Kitty.CommandConditionFrame.targetConditionList = nil;
-- Callback to show the parent window
Kitty.CommandConditionFrame.callbackFunc = nil;

-- Widget/data map
Kitty.CommandConditionFrame.relativeList = {
	-- Static texts
	["KittyCommandConditionFrame_VersionLabel"] = Kitty.getTitle(),
	["KittyCommandConditionFrame_TitleLabel"] = Kitty.T("message", "ConditionTitle"),
	["KittyCommandConditionFrame_CommandListLabel"] = Kitty.T("message", "CommandListNameLabel") .. ":",
	["KittyCommandConditionFrame_BuildLabel"] = Kitty.T("message", "BuildLabel") .. ":",
	["KittyCommandConditionFrame_TargetLabel"] = Kitty.T("message", "CommandListTargetLabel") .. ":",
	["KittyCommandConditionFrame_CommandLabel"] = Kitty.T("message", "CommandLabel") .. ":",

	-- Dynamic values
	["KittyCommandConditionFrame_CommandListNameLabel"]	= "name",
	["KittyCommandConditionFrame_BuildNameLabel"] = "class",
	["KittyCommandConditionFrame_TargetNameLabel"] = "target",
	["KittyCommandConditionFrame_CommandNameLabel"] = "",
	["KittyCommandConditionFrame_HintLabel"] = Kitty.L("ConditionHint", "Use this command when [all rows] below are true.  [+] adds a row, [-] removes it"),

	["KittyCommandConditionFrame_CloseButton"] = Kitty.T("message", "CloseButton"),
	["KittyCommandConditionFrame_CancelButton"] = Kitty.T("message", "CancelButton"),
};

--------------------------------------------------------------------------------
-- rom weakauras aura menu. A dropdown level holds at most 32 entries, so
-- more than 30 auras are split into groups of 30.
Kitty.CommandConditionFrame.WEAKAURA_GROUP_SIZE = 30;
Kitty.CommandConditionFrame.weakAuraMenuLevel1 = function()
	local names = Kitty.ComboManager.getWeakAuraNames();
	if(#names == 0) then
		return {Kitty.L("WeakAuraNone", "(no auras: open /rwa)")};
	end
	local size = Kitty.CommandConditionFrame.WEAKAURA_GROUP_SIZE;
	if(#names <= size) then
		return names;
	end
	local groups = {};
	for first = 1, #names, size do
		table.insert(groups, tostring(first) .. "-" .. tostring(math.min(first + size - 1, #names)));
	end
	return groups;
end;
Kitty.CommandConditionFrame.weakAuraMenuLevel2 = function(index, item)
	local names = Kitty.ComboManager.getWeakAuraNames();
	local size = Kitty.CommandConditionFrame.WEAKAURA_GROUP_SIZE;
	if(#names <= size or index == nil) then
		return nil;
	end
	local list = {};
	for i = (index - 1) * size + 1, math.min(index * size, #names) do
		table.insert(list, names[i]);
	end
	return list;
end;

--------------------------------------------------------------------------------
Kitty.CommandConditionFrame.toString = function(command)
	local str = "";

	str = str .. "CommandType:[" .. tostring(command.commandType) .. "], CommandName:[" .. tostring(command.commandName) .. "], Enable:[" .. tostring(command.enable) .. "]\n";
	for index, condition in ipairs(command) do
		if(condition.conditionType == nil) then
			str = "ConditionType:[" .. tostring(condition.conditionType) .. "]";
		else
			local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
			if(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST or formatType == Kitty.ComboManager.TYPE_EFFECT) then
				for index, effect in ipairs(condition) do
					str = str .. "CommandName:[" .. tostring(command.commandName) .. "],ConditionType:[" .. tostring(condition.conditionType) .. "], EffectType:[" .. tostring(condition.effectType) .. "], Name:[" .. tostring(condition.name) .. "], Threshold:[" .. tostring(condition.threshold) .. "]\n";
				end
			else
				str = str .. "ConditionType:[" .. tostring(condition.conditionType) .. "], Name:[" .. tostring(condition.name) .. "], Field:[" .. tostring(condition.field) .. "], Min:[" .. tostring(condition.min) .. "], Max:[" .. tostring(condition.max) .. "], Value:[" .. tostring(condition.value) .. "]\n";
			end
		end
	end
	return str;
end;

--[[
- Input
command = {
	["commandType"]="extra", ["commandName"]="name",
	{["conditionType"]="playerEffect",	{["name"]="1st"},
										{["name"]="2nd"}},
	{["conditionType"]="targetEffect"},
};
- Output
command = {
	["commandType"]="extra", ["commandName"]="name",
	{["conditionType"]="playerEffect", ["name"]="1st"},
	{["conditionType"]="playerEffect", ["name"]="2nd"}
	{["conditionType"]="targetEffect"},
};
--]]
-- Split
Kitty.CommandConditionFrame.separate = function(command)
	command = Kitty.copyTable(command);

	local resultArray = {};
	for key, condition in pairs(command) do
		if(type(key)=="number") then
			-- Entries with numeric keys
			if(type(condition)=="table") then
				-- Element is a table
				local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
				if(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST
				or formatType == Kitty.ComboManager.TYPE_EFFECT) then
					-- Needs splitting
					for itemKey, item in ipairs(condition) do
						if(type(itemKey)=="number") then
							if(type(item)=="table") then
								item.conditionType = condition.conditionType;
								table.insert(resultArray, item);
							else
								-- Negrect.
							end
						else
							if(key~="conditionType") then
								-- Negrect.
							end
						end
					end
				else
					-- No split needed
					table.insert(resultArray, condition);
				end
			else
				-- Element is not a table
				table.insert(resultArray, condition);
			end
		else
			-- Entries with non-numeric keys
			resultArray[key] = condition;
		end
	end
	return resultArray;
end;
-- Merge
Kitty.CommandConditionFrame.merge = function(command)
	command = Kitty.copyTable(command);

	local resultArray = {};
	local mergeList = {};
	for key, condition in pairs(command) do
		if(type(key)=="number") then
			-- Entries with numeric keys
			if(type(condition)=="table") then
				-- Element is a table
				local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
				if(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST
				or formatType == Kitty.ComboManager.TYPE_EFFECT) then
					-- Needs merging
					if(mergeList[condition.conditionType] == nil) then
						-- First time
						local newList = {};
						newList.conditionType = condition.conditionType;
						table.insert(newList, condition);

						mergeList[condition.conditionType] = newList;
						condition.conditionType = nil;
						table.insert(resultArray, newList);
					else
						-- After the first
						table.insert(mergeList[condition.conditionType], condition);
						condition.conditionType = nil;
					end
				else
					-- No merge needed
					table.insert(resultArray, condition);
				end
			else
				-- Element is not a table
				table.insert(resultArray, condition);
			end
		else
			-- Entries with non-numeric keys
			resultArray[key] = condition;
		end
	end
	return resultArray;
end;

--------------------------------------------------------------------------------
-- Some conditions take a two-way choice in front of the name, stored as
-- value = false for the second one ("on cooldown", "not cast", ...)
Kitty.CommandConditionFrame.CHOICES = {
	canCast = {"ready", "on cooldown"},
	canUse = {"ready", "on cooldown"},
	castRecently = {"cast", "not cast"},
	modeOn = {"on", "off"},
	targetCasting = {"casting", "not casting"},
};
-- Yes/no conditions read yes/no instead of true/false
Kitty.CommandConditionFrame.YES_NO = {"yes", "no"};
-- Conditions whose number box means nothing
Kitty.CommandConditionFrame.NO_THRESHOLD = {targetCasting = true, modeOn = true};
Kitty.CommandConditionFrame.hasReadyChoice = function(conditionType)
	return Kitty.CommandConditionFrame.CHOICES[conditionType] ~= nil;
end;
local function choiceWord(word)
	return Kitty.L("Choice_" .. string.gsub(word, " ", "_"), word);
end
-- The two words of the row's choice dropdown, {true word, false word}
Kitty.CommandConditionFrame.choiceLabels = function(conditionType)
	local pair = Kitty.CommandConditionFrame.CHOICES[conditionType] or Kitty.CommandConditionFrame.YES_NO;
	return {choiceWord(pair[1]), choiceWord(pair[2])};
end;
Kitty.CommandConditionFrame.choiceText = function(conditionType, value)
	local labels = Kitty.CommandConditionFrame.choiceLabels(conditionType);
	return (value == false) and labels[2] or labels[1];
end;
-- true or false from what the choice dropdown shows (true/false still work)
Kitty.CommandConditionFrame.choiceValue = function(text)
	if(text == "false") then
		return false;
	elseif(text == "true") then
		return true;
	end
	local pairs_ = {Kitty.CommandConditionFrame.YES_NO};
	for _, pair in pairs(Kitty.CommandConditionFrame.CHOICES) do
		table.insert(pairs_, pair);
	end
	for _, pair in ipairs(pairs_) do
		if(text == choiceWord(pair[2])) then
			return false;
		end
	end
	return true;
end;
-- The condition code name of a row, from its type dropdown
Kitty.CommandConditionFrame.rowConditionType = function(row)
	local name = (type(row) == "string") and row or (row and row:GetName());
	local menu = name and Kitty.Skin.find(name .. "DropDownMenu");
	local text = menu and UIDropDownMenu_GetText(menu);
	return Kitty.ComboManager.conditionFromLabel(text);
end;
-- One plain sentence under the row: what it checks right now
Kitty.CommandConditionFrame.summary = function(condition)
	if(condition == nil or condition.conditionType == nil or condition.conditionType == "") then
		return Kitty.teal(Kitty.L("ConditionPickHint", "Pick [what to check] in the menu on the left"));
	end
	local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
	local argument = condition;
	if(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST or formatType == Kitty.ComboManager.TYPE_EFFECT) then
		argument = {condition};
	end
	local help = Kitty.ComboManager[condition.conditionType .. "Help"];
	if(help == nil) then
		return "";
	end
	local ok, text;
	if(argument ~= condition) then
		ok, text = pcall(help, nil, argument);
	else
		ok, text = pcall(help, nil, Kitty.ComboManager.getArgument(condition));
	end
	if(not ok) then
		return "";
	end
	if(type(text) == "table") then
		text = table.concat(text, " ");
	end
	return Kitty.teal(tostring(text or ""));
end;
-- "Mode is on": the mode dropdown lists every mode, then Add new mode...,
-- which swaps it for the name box so a new name can be typed
Kitty.CommandConditionFrame.modeChoices = function()
	local list = {};
	for _, name in ipairs(Kitty.ModeUI.names()) do
		if(#list >= 30) then
			break;	-- menus hold at most 32 entries
		end
		table.insert(list, name);
	end
	table.insert(list, Kitty.L("ModeAddNew", Kitty.ModeUI.ADD_NEW));
	return list;
end;
Kitty.CommandConditionFrame.showModeName = function(row, name, typing)
	local menu = getglobal(row:GetName() .. "ModeDropDownMenu");
	local editBox = getglobal(row:GetName() .. "ConditionValueEditBox");
	row.kittyTypingMode = typing and true or nil;
	if(typing) then
		menu:Hide();
		Kitty.CommandConditionFrame.placeValueEditBox(row, true);
		editBox:SetText(name or "");
		editBox:Show();
		if(editBox.SetFocus) then
			editBox:SetFocus();
		end
	else
		editBox:Hide();
		UIDropDownMenu_SetText(menu, name or "");
		menu:Show();
	end
end;
Kitty.CommandConditionFrame.onModePicked = function(row, text)
	if(text == Kitty.L("ModeAddNew", Kitty.ModeUI.ADD_NEW)) then
		local menu = getglobal(row:GetName() .. "ModeDropDownMenu");
		UIDropDownMenu_SetText(menu, "");
		Kitty.CommandConditionFrame.showModeName(row, "", true);
	end
	Kitty.CommandConditionFrame.updateData(row);
end;
-- The name box sits after the effect-type dropdown, or after true/false
Kitty.CommandConditionFrame.placeValueEditBox = function(row, afterBoolean)
	local editBox = getglobal(row:GetName() .. "ConditionValueEditBox");
	local before = getglobal(row:GetName() .. (afterBoolean and "BooleanDropDownMenu" or "EffectTypeDropDownMenu"));
	if(editBox and before and editBox.ClearAllAnchors and editBox.SetAnchor) then
		editBox:ClearAllAnchors();
		editBox:SetAnchor("LEFT", "RIGHT", before, 5, 0);
	end
end;
-- Icon of the command being edited, next to its name in the header
Kitty.CommandConditionFrame.showCommandIcon = function(command)
	local texture = KittyCommandConditionFrame_CommandIcon;
	if(not texture) then
		return;
	end
	local icon = command and command.icon;
	if(type(icon) == "string" and icon ~= "") then
		texture:SetTexture(icon);
		texture:Show();
	else
		texture:Hide();
	end
end;

-- Show window
Kitty.CommandConditionFrame.open = function(commandList, index, callbackFunc)
	Kitty.CommandConditionFrame.callbackFunc = callbackFunc;

	Kitty.CommandConditionFrame.commandList = commandList;
	Kitty.CommandConditionFrame.targetCommandIndex = index;
	local conditionList = Kitty.CommandConditionFrame.commandList[Kitty.CommandConditionFrame.targetCommandIndex];
	Kitty.CommandConditionFrame.targetConditionList = Kitty.ListManager(Kitty.copyTable(Kitty.CommandConditionFrame.separate(conditionList)));

	if(#Kitty.CommandConditionFrame.targetConditionList == 0) then
		-- Create Empty
		table.insert(Kitty.CommandConditionFrame.targetConditionList, {["conditionType"]=""});
	end

	Kitty.CommandConditionFrame.relativeList["KittyCommandConditionFrame_CommandNameLabel"] = conditionList.commandName;
	Kitty.CommandConditionFrame.showCommandIcon(conditionList);
	Kitty.settingToComponent(commandList.info, Kitty.CommandConditionFrame.relativeList);

	-- Show rows
	Kitty.CommandConditionFrame.onRedraw(this, 1, 10);

	KittyCommandConditionFrame:Show();
end;

Kitty.CommandConditionFrame.save = function()
	-- Merge
	local mergedList = Kitty.CommandConditionFrame.merge(Kitty.CommandConditionFrame.targetConditionList);
	Kitty.CommandConditionFrame.commandList[Kitty.CommandConditionFrame.targetCommandIndex] = mergedList;

	Kitty.debugPrint("mergedList", mergedList);
end;
Kitty.CommandConditionFrame.close = function()
	Kitty.CommandConditionFrame.commandList = nil;
	Kitty.CommandConditionFrame.targetCommandIndex = nil;
	Kitty.CommandConditionFrame.targetConditionList = nil;
	Kitty.CommandConditionFrame.callbackFunc = nil;

	KittyCommandConditionFrame:Hide();
end;

-- Store the values shown in the list rows into the data
Kitty.CommandConditionFrame.allowUpdateData = true;
Kitty.CommandConditionFrame.updateData = function(this)
	if(Kitty.CommandConditionFrame.allowUpdateData) then
		Kitty.debugPrint("Kitty.CommandConditionFrame.updateData");
	else
		Kitty.debugPrint("Kitty.CommandConditionFrame.updateData Canceled.");
		return;
	end
	-- Dropdown (condition type)
	local dropDownMenu = getglobal(this:GetName() .. "DropDownMenu");
	assert(dropDownMenu, this:GetName() .. "DropDownMenu is nil");

	-- Dropdown (effect kind)
	local effectTypeDropDownMenu = getglobal(this:GetName() .. "EffectTypeDropDownMenu");
	assert(effectTypeDropDownMenu, this:GetName() .. "EffectTypeDropDownMenu is nil");
	-- Dropdown (buff kind)
	local conditionDropDownMenu = getglobal(this:GetName() .. "ConditionDropDownMenu");
	assert(conditionDropDownMenu, this:GetName() .. "ConditionDropDownMenu is nil");
	-- Edit box (value)
	local conditionEditBox = getglobal(this:GetName() .. "ConditionValueEditBox");
	assert(conditionEditBox, this:GetName() .. "ConditionValueEditBox is nil");
	-- Edit box (threshold)
	local thresholdEditBox = getglobal(this:GetName() .. "ConditionThresholdEditBox");
	assert(thresholdEditBox, this:GetName() .. "ConditionThresholdEditBox is nil");
	-- Edit box (min)
	local minEditBox = getglobal(this:GetName() .. "MinEditBox");
	assert(minEditBox, this:GetName() .. "MinEditBox is nil");
	-- Edit box (max)
	local maxEditBox = getglobal(this:GetName() .. "MaxEditBox");
	assert(maxEditBox, this:GetName() .. "MaxEditBox is nil");
	-- Dropdown (yes/no)
	local booleanDropDownMenu = getglobal(this:GetName() .. "BooleanDropDownMenu");
	assert(booleanDropDownMenu, this:GetName() .. "BooleanDropDownMenu is nil");
	-- Dropdown (shortcut)
	local actionDropDownMenu = getglobal(this:GetName() .. "ActionDropDownMenu");
	assert(actionDropDownMenu, this:GetName() .. "ActionDropDownMenu is nil");
	-- Dropdown (build)
	local buildDropDownMenu = getglobal(this:GetName() .. "BuildDropDownMenu");
	assert(buildDropDownMenu, this:GetName() .. "BuildDropDownMenu is nil");
	-- rom weakauras
	local weakAuraDropDownMenu = getglobal(this:GetName() .. "WeakAuraDropDownMenu");
	assert(weakAuraDropDownMenu, this:GetName() .. "WeakAuraDropDownMenu is nil");
	local weakAuraFieldDropDownMenu = getglobal(this:GetName() .. "WeakAuraFieldDropDownMenu");
	assert(weakAuraFieldDropDownMenu, this:GetName() .. "WeakAuraFieldDropDownMenu is nil");
	local weakAuraMinEditBox = getglobal(this:GetName() .. "WeakAuraMinEditBox");
	assert(weakAuraMinEditBox, this:GetName() .. "WeakAuraMinEditBox is nil");
	local weakAuraMaxEditBox = getglobal(this:GetName() .. "WeakAuraMaxEditBox");
	assert(weakAuraMaxEditBox, this:GetName() .. "WeakAuraMaxEditBox is nil");

	-- Dropdown (condition type)
	local condition = {};
	condition.conditionType = Kitty.ComboManager.conditionFromLabel(UIDropDownMenu_GetText(dropDownMenu));
	if(condition.conditionType ~= nil and condition.conditionType ~= "") then
		local formatType = Kitty.ComboManager.getFormatType(condition.conditionType);

		if(formatType == Kitty.ComboManager.TYPE_EFFECT) then
			-- Dropdown (effect kind)
			condition.effectType = UIDropDownMenu_GetText(effectTypeDropDownMenu);
			-- Edit box (value)
			if(condition.effectType == "original") then
				condition.name = UIDropDownMenu_GetText(conditionDropDownMenu);
			else
				condition.name = conditionEditBox:GetText();
			end
			-- Edit box (threshold)
			condition.threshold = tonumber(thresholdEditBox:GetText());
			condition.thresholdS = tostring(thresholdEditBox:GetText());
			if(condition.threshold == nil ) then
				condition.threshold = 0;
			end
			if string.lower(condition.thresholdS) == "s" then
				condition.threshold = "S";
			end
		elseif(formatType == Kitty.ComboManager.TYPE_ACTION) then
			condition.value = UIDropDownMenu_GetText(actionDropDownMenu);
		elseif(formatType == Kitty.ComboManager.TYPE_BUILD) then
			condition.value = UIDropDownMenu_GetText(buildDropDownMenu);
		elseif(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST) then
			-- Dropdown (ready / on cooldown) for canCast and canUse; only false is stored
			if(Kitty.CommandConditionFrame.hasReadyChoice(condition.conditionType)
				and Kitty.CommandConditionFrame.choiceValue(UIDropDownMenu_GetText(booleanDropDownMenu)) == false) then
				condition.value = false;
			end
			-- Edit box (value); "Mode is on" takes the mode dropdown unless a new name is typed
			condition.name = conditionEditBox:GetText();
			local modeMenu = getglobal(this:GetName() .. "ModeDropDownMenu");
			if(condition.conditionType == "modeOn" and modeMenu and not this.kittyTypingMode) then
				condition.name = UIDropDownMenu_GetText(modeMenu) or "";
				if(condition.name == Kitty.L("ModeAddNew", Kitty.ModeUI.ADD_NEW)) then
					condition.name = "";
				end
			end
			if(condition.conditionType == "modeOn") then
				condition.name = Kitty.ModeUI.clean(condition.name);
			end
			-- Edit box (threshold)
			condition.threshold = tonumber(thresholdEditBox:GetText());
			if(condition.threshold == nil) then
				condition.threshold = 0;
			end
		elseif(formatType == Kitty.ComboManager.TYPE_STRING) then
			-- Edit box (value)
			condition.value = conditionEditBox:GetText();
		elseif(formatType == Kitty.ComboManager.TYPE_NUMBER) then
			-- Edit box (min/max)
			condition.min = tonumber(minEditBox:GetText());
			condition.max = tonumber(maxEditBox:GetText());
		elseif(formatType == Kitty.ComboManager.TYPE_BOOLEAN) then
			-- Dropdown (yes/no)
			condition.value = Kitty.CommandConditionFrame.choiceValue(UIDropDownMenu_GetText(booleanDropDownMenu));
		elseif(formatType == Kitty.ComboManager.TYPE_WEAKAURA) then
			condition.name = UIDropDownMenu_GetText(weakAuraDropDownMenu);
			if(condition.name == Kitty.L("WeakAuraNone", "(no auras: open /rwa)")) then
				condition.name = "";
			end
			condition.field = UIDropDownMenu_GetText(weakAuraFieldDropDownMenu);
			if(condition.field == nil or condition.field == "") then
				condition.field = "true";
			end
			if(condition.field ~= "true" and condition.field ~= "false") then
				condition.min = tonumber(weakAuraMinEditBox:GetText());
				condition.max = tonumber(weakAuraMaxEditBox:GetText());
			end
		else
			error("Invalid DataType:[" .. tostring(formatType) .. "]");
		end
	end

	local index = KittyCommandConditionFrame_ScrollBar:GetValue() + this:GetID() - 1;
	local previous = Kitty.CommandConditionFrame.targetConditionList[index];
	if(previous and previous.modeActionGuard == true and condition.conditionType == "modeOn" and condition.name == previous.name) then
		condition.modeActionGuard = true;
	end
	Kitty.CommandConditionFrame.targetConditionList[index] = condition;
	local summaryLabel = Kitty.Skin.find(this:GetName() .. "Summary");
	if(summaryLabel ~= nil) then
		summaryLabel:SetText(Kitty.CommandConditionFrame.summary(condition));
	end
end;

-- Show the command list rows
Kitty.CommandConditionFrame.onRedraw = function(this, start, count)
	local position = KittyCommandConditionFrame_ScrollBar:GetValue();
	if(start == position) then
		-- Redraw
		Kitty.CommandConditionFrame.onShowList(KittyCommandConditionFrame_ScrollBar, start, count);
	else
		-- Update the scroll bar (it redraws afterwards)
		KittyCommandConditionFrame_ScrollBar:SetValue(start);
	end
end;
Kitty.CommandConditionFrame.onShowList = function(this, start, count)
	Kitty.CommandConditionFrame.allowUpdateData = false;
	Kitty.debugPrint("Kitty.CommandConditionFrame.onShowList");

	if(count ~= nil) then
		count = 10;
	end

	-- Work out the slider range
	local aboveRange = start - 1;	-- Rows that can scroll up
	if(aboveRange < 0) then
		aboveRange = 0;
	end
	local belowRange = 0;
	if(Kitty.CommandConditionFrame.targetConditionList ~= nil) then
		belowRange = #Kitty.CommandConditionFrame.targetConditionList - count - (start - 1);	-- Rows that can scroll down
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
		local detailButton = getglobal("KittyCommandConditionFrame_Button" .. tostring(position));
		assert(detailButton, "KittyCommandConditionFrame_Button" .. tostring(position) .. " is nil.");

		-- Update row
		if(Kitty.CommandConditionFrame.targetConditionList ~= nil) then
			local condition = Kitty.CommandConditionFrame.targetConditionList[index];
			if(condition ~= nil) then
				Kitty.CommandConditionFrame.showDetail(detailButton, condition);
				detailButton:Show();
			else
				detailButton:Hide();
			end
		end

		position = position + 1;
	end
	Kitty.CommandConditionFrame.showCount();

	Kitty.CommandConditionFrame.allowUpdateData = true;
end;
-- "2 conditions" under the list (empty rows do not count)
Kitty.CommandConditionFrame.showCount = function()
	local label = Kitty.Skin.find("KittyCommandConditionFrame_FooterLabel");
	if(label == nil) then
		return;
	end
	local count = 0;
	for _, condition in ipairs(Kitty.CommandConditionFrame.targetConditionList or {}) do
		if(condition.conditionType ~= nil and condition.conditionType ~= "") then
			count = count + 1;
		end
	end
	if(count == 0) then
		label:SetText(Kitty.teal(Kitty.L("ConditionCountNone", "No conditions: used whenever [ready]")));
	elseif(count == 1) then
		label:SetText(Kitty.L("ConditionCountOne", "1 condition"));
	else
		label:SetText(Kitty.teal(Kitty.L("ConditionCount", "<<1>> conditions, [all] must be true", tostring(count))));
	end
end;

-- Show the data in the list rows
Kitty.CommandConditionFrame.showDetail = function(this, condition)
	-- Dropdown (condition type)
	local dropDownMenu = getglobal(this:GetName() .. "DropDownMenu");
	assert(dropDownMenu, this:GetName() .. "DropDownMenu is nil");

	-- Dropdown (effect kind)
	local effectTypeDropDownMenu = getglobal(this:GetName() .. "EffectTypeDropDownMenu");
	assert(effectTypeDropDownMenu, this:GetName() .. "EffectTypeDropDownMenu is nil");
	-- Dropdown (buff kind)
	local conditionDropDownMenu = getglobal(this:GetName() .. "ConditionDropDownMenu");
	assert(conditionDropDownMenu, this:GetName() .. "ConditionDropDownMenu is nil");
	-- Edit box (value)
	local conditionEditBox = getglobal(this:GetName() .. "ConditionValueEditBox");
	assert(conditionEditBox, this:GetName() .. "ConditionValueEditBox is nil");
	-- Edit box (threshold)
	local thresholdEditBox = getglobal(this:GetName() .. "ConditionThresholdEditBox");
	assert(thresholdEditBox, this:GetName() .. "ConditionThresholdEditBox is nil");
	-- Edit box (min)
	local minEditBox = getglobal(this:GetName() .. "MinEditBox");
	assert(minEditBox, this:GetName() .. "MinEditBox is nil");
	-- Edit box (max)
	local maxEditBox = getglobal(this:GetName() .. "MaxEditBox");
	assert(maxEditBox, this:GetName() .. "MaxEditBox is nil");
	-- Dropdown (yes/no)
	local booleanDropDownMenu = getglobal(this:GetName() .. "BooleanDropDownMenu");
	assert(booleanDropDownMenu, this:GetName() .. "BooleanDropDownMenu is nil");
	-- Name box back in its usual spot (canCast/canUse move it after true/false)
	Kitty.CommandConditionFrame.placeValueEditBox(this, false);
	-- Dropdown (shortcut)
	local actionDropDownMenu = getglobal(this:GetName() .. "ActionDropDownMenu");
	assert(actionDropDownMenu, this:GetName() .. "ActionDropDownMenu is nil");
	-- Dropdown (build)
	local buildDropDownMenu = getglobal(this:GetName() .. "BuildDropDownMenu");
	assert(buildDropDownMenu, this:GetName() .. "BuildDropDownMenu is nil");
	-- rom weakauras
	local weakAuraDropDownMenu = getglobal(this:GetName() .. "WeakAuraDropDownMenu");
	assert(weakAuraDropDownMenu, this:GetName() .. "WeakAuraDropDownMenu is nil");
	local weakAuraFieldDropDownMenu = getglobal(this:GetName() .. "WeakAuraFieldDropDownMenu");
	assert(weakAuraFieldDropDownMenu, this:GetName() .. "WeakAuraFieldDropDownMenu is nil");
	local weakAuraMinEditBox = getglobal(this:GetName() .. "WeakAuraMinEditBox");
	assert(weakAuraMinEditBox, this:GetName() .. "WeakAuraMinEditBox is nil");
	local weakAuraMaxEditBox = getglobal(this:GetName() .. "WeakAuraMaxEditBox");
	assert(weakAuraMaxEditBox, this:GetName() .. "WeakAuraMaxEditBox is nil");

	UIDropDownMenu_SetText(dropDownMenu, Kitty.ComboManager.conditionLabel(condition.conditionType));
	-- Change the input controls to match the condition
	local formatType = nil
	if(condition.conditionType ~= nil and condition.conditionType ~= "") then
		formatType = Kitty.ComboManager.getFormatType(condition.conditionType);
	else
		formatType = Kitty.ComboManager.TYPE_BOOLEAN;
	end

	-- Initialize
	UIDropDownMenu_SetText(effectTypeDropDownMenu, "");
	conditionEditBox:SetText("");
	thresholdEditBox:SetText("");
	minEditBox:SetText("");
	maxEditBox:SetText("");
	UIDropDownMenu_SetText(booleanDropDownMenu, "");
	UIDropDownMenu_SetText(weakAuraDropDownMenu, "");
	UIDropDownMenu_SetText(weakAuraFieldDropDownMenu, "");
	weakAuraMinEditBox:SetText("");
	weakAuraMaxEditBox:SetText("");
	weakAuraDropDownMenu:Hide();
	weakAuraFieldDropDownMenu:Hide();
	weakAuraMinEditBox:Hide();
	weakAuraMaxEditBox:Hide();
	local modeMenu = getglobal(this:GetName() .. "ModeDropDownMenu");
	this.kittyTypingMode = nil;
	if(modeMenu) then
		UIDropDownMenu_SetText(modeMenu, "");
		modeMenu:Hide();
	end

	if(formatType == Kitty.ComboManager.TYPE_EFFECT) then
		if(condition.effectType == nil) then
			condition.effectType = "name";
		end
		UIDropDownMenu_SetText(effectTypeDropDownMenu, tostring(condition.effectType));

		-- Depends on how the buff is given
		if(condition.effectType == "original") then
			if(condition.name == nil) then
				condition.name = "";
			end
			UIDropDownMenu_SetText(conditionDropDownMenu, tostring(condition.name));

			if(condition.threshold == nil) then
				condition.threshold = 0.0;
			end
			thresholdEditBox:SetText(tostring(condition.threshold));

			effectTypeDropDownMenu:Show();
			conditionDropDownMenu:Show();
			conditionEditBox:Hide();
			thresholdEditBox:Show();
			minEditBox:Hide();
			maxEditBox:Hide();
			booleanDropDownMenu:Hide();
			actionDropDownMenu:Hide();
			buildDropDownMenu:Hide();
		else
			if(condition.name == nil) then
				condition.name = "";
			end
			conditionEditBox:SetText(tostring(condition.name));

			if(condition.threshold == nil) then
				condition.threshold = 0.0;
			end
			thresholdEditBox:SetText(tostring(condition.threshold));

			effectTypeDropDownMenu:Show();
			conditionDropDownMenu:Hide();
			conditionEditBox:Show();
			thresholdEditBox:Show();
			minEditBox:Hide();
			maxEditBox:Hide();
			booleanDropDownMenu:Hide();
			actionDropDownMenu:Hide();
			buildDropDownMenu:Hide();
		end
	elseif(formatType == Kitty.ComboManager.TYPE_ACTION) then
		if(condition.value == nil) then
			condition.value = "";
		end
		UIDropDownMenu_SetText(actionDropDownMenu, tostring(condition.value));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Hide();
		thresholdEditBox:Hide();
		minEditBox:Hide();
		maxEditBox:Hide();
		booleanDropDownMenu:Hide();
		actionDropDownMenu:Show();
		buildDropDownMenu:Hide();
	elseif(formatType == Kitty.ComboManager.TYPE_BUILD) then
		if(condition.value == nil) then
			condition.value = "";
		end
		UIDropDownMenu_SetText(buildDropDownMenu, tostring(condition.value));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Hide();
		thresholdEditBox:Hide();
		minEditBox:Hide();
		maxEditBox:Hide();
		booleanDropDownMenu:Hide();
		actionDropDownMenu:Hide();
		buildDropDownMenu:Show();
	elseif(formatType == Kitty.ComboManager.TYPE_STRING_NUMBER_LIST) then
		if(condition.name == nil) then
			condition.name = "";
		end
		conditionEditBox:SetText(tostring(condition.name));

		if(condition.threshold == nil) then
			condition.threshold = 0.0;
		end
		thresholdEditBox:SetText(tostring(condition.threshold));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Show();
		if(Kitty.CommandConditionFrame.NO_THRESHOLD[condition.conditionType]) then
			thresholdEditBox:Hide();
		else
			thresholdEditBox:Show();
		end
		minEditBox:Hide();
		maxEditBox:Hide();
		-- canCast / canUse: true (ready) or false (on cooldown) before the name
		Kitty.CommandConditionFrame.placeValueEditBox(this, Kitty.CommandConditionFrame.hasReadyChoice(condition.conditionType));
		if(Kitty.CommandConditionFrame.hasReadyChoice(condition.conditionType)) then
			UIDropDownMenu_SetText(booleanDropDownMenu, Kitty.CommandConditionFrame.choiceText(condition.conditionType, condition.value));
			booleanDropDownMenu:Show();
		else
			booleanDropDownMenu:Hide();
		end
		actionDropDownMenu:Hide();
		buildDropDownMenu:Hide();
		if(condition.conditionType == "modeOn" and modeMenu) then
			Kitty.CommandConditionFrame.showModeName(this, Kitty.ModeUI.clean(condition.name), false);
		end
	elseif(formatType == Kitty.ComboManager.TYPE_STRING) then
		if(condition.value == nil) then
			condition.value = "";
		end
		conditionEditBox:SetText(tostring(condition.value));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Show();
		thresholdEditBox:Hide();
		minEditBox:Hide();
		maxEditBox:Hide();
		booleanDropDownMenu:Hide();
		actionDropDownMenu:Hide();
		buildDropDownMenu:Hide();
	elseif(formatType == Kitty.ComboManager.TYPE_NUMBER) then
		if(condition.min == nil) then
			condition.min = 0;
			minEditBox:SetText(tostring(condition.min));
		end
		minEditBox:SetText(tostring(condition.min));

		if(condition.max == nil) then
			condition.max = 100;
		end
		maxEditBox:SetText(tostring(condition.max));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Hide();
		thresholdEditBox:Hide();
		minEditBox:Show();
		maxEditBox:Show();
		booleanDropDownMenu:Hide();
		actionDropDownMenu:Hide();
		buildDropDownMenu:Hide();
	elseif(formatType == Kitty.ComboManager.TYPE_BOOLEAN) then
		if(condition.value == nil) then
			condition.value = true;
		end
		UIDropDownMenu_SetText(booleanDropDownMenu, Kitty.CommandConditionFrame.choiceText(condition.conditionType, condition.value));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Hide();
		thresholdEditBox:Hide();
		minEditBox:Hide();
		maxEditBox:Hide();
		booleanDropDownMenu:Show();
		actionDropDownMenu:Hide();
		buildDropDownMenu:Hide();
	elseif(formatType == Kitty.ComboManager.TYPE_WEAKAURA) then
		if(condition.name == nil) then
			condition.name = "";
		end
		if(condition.field == nil or condition.field == "") then
			condition.field = "true";
		end
		UIDropDownMenu_SetText(weakAuraDropDownMenu, tostring(condition.name));
		UIDropDownMenu_SetText(weakAuraFieldDropDownMenu, tostring(condition.field));

		effectTypeDropDownMenu:Hide();
		conditionDropDownMenu:Hide();
		conditionEditBox:Hide();
		thresholdEditBox:Hide();
		minEditBox:Hide();
		maxEditBox:Hide();
		booleanDropDownMenu:Hide();
		actionDropDownMenu:Hide();
		buildDropDownMenu:Hide();
		weakAuraDropDownMenu:Show();
		weakAuraFieldDropDownMenu:Show();
		if(condition.field ~= "true" and condition.field ~= "false") then
			if(condition.min ~= nil) then
				weakAuraMinEditBox:SetText(tostring(condition.min));
			end
			if(condition.max ~= nil) then
				weakAuraMaxEditBox:SetText(tostring(condition.max));
			end
			weakAuraMinEditBox:Show();
			weakAuraMaxEditBox:Show();
		end
	else
		error("Invalid DataType:[" .. tostring(formatType) .. "]");
	end
	-- Plain sentence under the row
	local summaryLabel = Kitty.Skin.find(this:GetName() .. "Summary");
	if(summaryLabel ~= nil) then
		summaryLabel:SetText(Kitty.CommandConditionFrame.summary(condition));
	end
end;
