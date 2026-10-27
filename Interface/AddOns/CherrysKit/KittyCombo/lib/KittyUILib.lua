-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Mouse wheel over a list row or any control in it scrolls the list one row
Kitty.scrollList = function(scrollBar, delta)
	if(not scrollBar or not delta) then
		return;
	end
	if(delta > 0) then
		scrollBar:SetValue(scrollBar:GetValue() - 1);
	elseif(delta < 0) then
		scrollBar:SetValue(scrollBar:GetValue() + 1);
	end
end;

--------------------------------------------------------------------------------
-- Window position
-- All KittyCombo windows share one spot. GetPos gives screen pixels, anchors
-- take UI units, so savePosition stores pixels / UI scale and loadPosition uses
-- that as is. (0.973 multiplied by the scale again here, so with a UI scale
-- other than 100% each window opened somewhere else.)
-- A window made bigger or smaller with its corner grip counts its anchor
-- offset in its own size, so the offset is divided by that size
-- (Kitty.SCALED_OFFSETS; /kc probe "window position at 120%" checks it).
Kitty.SCALED_OFFSETS = true;
Kitty.loadPosition = function(this)
	local x = Kitty.SettingManager.setting.window.framePositionX;
	local y = Kitty.SettingManager.setting.window.framePositionY;
	local scaled = Kitty.SCALED_OFFSETS and Kitty.SettingManager.setting.window.scaledOffsets ~= false;
	local scale = (Kitty.Skin and scaled) and Kitty.Skin.getScale(this) or 1;
	this:ClearAllAnchors();
	this:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x / scale, y / scale);
end;
Kitty.savePosition = function(this)
	local scale = GetUIScale();
	local x, y = this:GetPos();
	Kitty.SettingManager.setting.window.framePositionX = x / scale;
	Kitty.SettingManager.setting.window.framePositionY = y / scale;
end;

--------------------------------------------------------------------------------
-- Clipboard. RoM's Chat_CopyToClipboard silently copies nothing when the text
-- is long (Cherry's Chat found that; /cchat cliptest measures the limit and
-- /cchat clipmax saves it, which is used here too).
Kitty.CLIP_MAX = 1000;
Kitty.clipboardMax = function()
	local own = Kitty.SettingManager and Kitty.SettingManager.setting and tonumber(Kitty.SettingManager.setting.clipMax);
	if(own and own > 0) then
		return own;
	end
	if(type(CherrysChat) == "table" and type(CherrysChat.DB) == "function") then
		local ok, db = pcall(CherrysChat.DB);
		local max = ok and type(db) == "table" and tonumber(db.clipMax);
		if(max and max > 0) then
			return max;
		end
	end
	return Kitty.CLIP_MAX;
end;
-- Numbered test text: every 10 characters end with their position, so a
-- paste shows how much arrived ("000000990," = 990 characters)
Kitty.clipTestText = function(length)
	local parts = {};
	for position = 10, length, 10 do
		table.insert(parts, string.format("%09d,", position));
	end
	return table.concat(parts);
end;
-- /kc cliptest [length]: clipboard and Ctrl+C test. /kc clipmax <n>: save the limit
Kitty.clipTest = function(length)
	length = math.max(10, math.min(20000, tonumber(length) or 3000));
	local text = Kitty.clipTestText(length);
	local copied = type(Chat_CopyToClipboard) == "function" and pcall(Chat_CopyToClipboard, text);
	Kitty.sendMessage(Kitty.L("ClipTest1", "Clipboard test: <<1>> characters <<2>>. Paste into Discord or Notepad: the last number is how many arrived.",
		tostring(string.len(text)), copied and "sent to the clipboard" or "NOT sent (no clipboard call)"));
	local box = KittyCommandConfigFrame_ExportEditBox;
	if(box and KittyCommandConfigFrame and KittyCommandConfigFrame:IsVisible()) then
		box:SetText(text);
		Kitty.CommandConfigFrame.selectExportText();
		Kitty.sendMessage(Kitty.L("ClipTest2", "The same text is selected in the Export box: press Ctrl+C and paste again to test Ctrl+C."));
	else
		Kitty.sendMessage(Kitty.L("ClipTest3", "To test Ctrl+C too, open a kitty in the editor and type the command again."));
	end
	Kitty.sendMessage(Kitty.L("ClipTest4", "Then save what the clipboard takes: /kc clipmax <number> (now <<1>>).", tostring(Kitty.clipboardMax())));
end;
Kitty.setClipMax = function(value)
	value = tonumber(value);
	Kitty.SettingManager.setting.clipMax = (value and value > 0) and math.floor(value) or nil;
	Kitty.sendMessage(Kitty.L("ClipMaxSaved", "Get code copies codes up to <<1>> characters; longer ones stay selected for Ctrl+C.", tostring(Kitty.clipboardMax())));
end;
-- true when the text went to the clipboard
Kitty.copyToClipboard = function(text)
	text = tostring(text or "");
	if(text == "" or string.len(text) > Kitty.clipboardMax() or type(Chat_CopyToClipboard) ~= "function") then
		return false;
	end
	return pcall(Chat_CopyToClipboard, text) and true or false;
end;

--------------------------------------------------------------------------------
-- Tooltip
Kitty.showGameTooltip = function(this, messageList)
	if(type(messageList) ~= "table") then
		messageList = {messageList};
	end

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 4, 0);
	for index, message in ipairs(messageList) do
		if(index == 1) then
			-- First line
			GameTooltip:SetText(Kitty.teal(tostring(message)));
		else
			GameTooltip:AddLine(Kitty.teal(tostring(message)));
		end
	end
	GameTooltip:Show();
end;
Kitty.hideGameTooltip = function(this)
	GameTooltip:Hide();
end;

--------------------------------------------------------------------------------
-- Custom check function
-- Widget type
Kitty.EDITBOX = "EditBox";
Kitty.CHECKBUTTON = "CheckButton";
Kitty.DROPDOWNMENU = "DropDownMenu";
Kitty.LABEL = "Label";
Kitty.BUTTON = "Button";
-- Widget type check
Kitty.getComponentType = function(componentName)
	local componentType = nil;
	if(string.endsWith(componentName, Kitty.EDITBOX)) then
		componentType = Kitty.EDITBOX;
	elseif(string.endsWith(componentName, Kitty.CHECKBUTTON)) then
		componentType = Kitty.CHECKBUTTON;
	elseif(string.endsWith(componentName, Kitty.DROPDOWNMENU)) then
		componentType = Kitty.DROPDOWNMENU;
	elseif(string.endsWith(componentName, Kitty.LABEL)) then
		componentType = Kitty.LABEL;
	elseif(string.endsWith(componentName, Kitty.BUTTON)) then
		componentType = Kitty.BUTTON;
	else
		error("Error: Invalid component. ComponentName:[" .. componentName .. "]");
	end

	return componentType;
end;

--------------------------------------------------------------------------------
-- DDX
-- Show settings in the window
Kitty.settingToComponent = function(settingData, relativeList)
	-- Loop over the settings-to-widget map
	for componentName, data in pairs(relativeList) do
		local component = _G[componentName];
		assert(component, "Error: Component is nil. ComponentName:[" .. componentName .. "]");

		-- If the setting is missing, show data as is
		local value = data;
		if(settingData ~= nil and settingData[data] ~= nil) then
			value = settingData[data];
		end

		local componentType = Kitty.getComponentType(componentName);
		if(componentType == Kitty.EDITBOX) then
			-- Edit box
			component:SetText(value);
		elseif(componentType == Kitty.CHECKBUTTON) then
			-- Check button
			component:SetChecked(value);
		elseif(componentType == Kitty.DROPDOWNMENU) then
			-- Dropdown
			UIDropDownMenu_SetText(component, value);
		elseif(componentType == Kitty.LABEL) then
			-- Label ([examples] in teal)
			component:SetText(Kitty.teal(value));
		elseif(componentType == Kitty.BUTTON) then
			-- Button
			component:SetText(value);
		else
			error("Error: Invalid componentType. ComponentType:[" .. componentType .. "]");
		end
	end
end;
-- Save the window's values to the settings
Kitty.componentToSetting = function(settingData, relativeList)
	-- Loop over the settings-to-widget map
	for componentName, data in pairs(relativeList) do
		local component = _G[componentName];
		assert(component, "Error: Component is nil. ComponentName:[" .. componentName .. "]");

		local componentType = Kitty.getComponentType(componentName);
		if(componentType == Kitty.EDITBOX) then
			-- Edit box
			settingData[data] = component:GetText();
		elseif(componentType == Kitty.CHECKBUTTON) then
			-- Check button
			settingData[data] = component:IsChecked();
		elseif(componentType == Kitty.DROPDOWNMENU) then
			-- Dropdown
			settingData[data] = UIDropDownMenu_GetText(component);
		elseif(componentType == Kitty.LABEL) then
			-- Label
		elseif(componentType == Kitty.BUTTON) then
			-- Button
		else
			error("Error: Invalid componentType. ComponentType:[" .. componentType .. "]");
		end
	end
end;

--------------------------------------------------------------------------------
-- List manager
Kitty.ListManager = {};
-- Instance methods
-- Update
Kitty.ListManager.update = function(self, index, element)
	Kitty.debugPrint("Update:[" .. tostring(index) .. "]");
	self[index] = element;
end;
-- Insert
Kitty.ListManager.insert = function(self, index, element)
	Kitty.debugPrint("Insert:[" .. tostring(index) .. "]");
	table.insert(self, index+1, element);
end;
-- Copy
Kitty.ListManager.copy = function(self, index)
	Kitty.debugPrint("Copy:[" .. tostring(index) .. "]");
	-- DeepCopy
	local element = Kitty.copyTable(self[index]);
	table.insert(self, index+1, element);
end;
-- Left
Kitty.ListManager.remove = function(self, index)
	Kitty.debugPrint("Remove:[" .. tostring(index) .. "]");
	table.remove(self, index);
end;
-- Swap elements
Kitty.ListManager.swap = function(self, fromIndex, toIndex)
	Kitty.debugPrint("Swap:[" .. tostring(fromIndex) .. ", " .. tostring(toIndex) .. "]");
	if(self[fromIndex] ~= nil and self[toIndex] ~= nil) then
		self[fromIndex], self[toIndex] = self[toIndex], self[fromIndex];
		return true;
	else
		return false;
	end
end;
-- String form
Kitty.ListManager.toString = function(self)
	local str = "";
	for key, value in pairs(self) do
		if(str ~= "") then
			str = str .. ",\n";
		end
		str = str .. "[" .. tostring(key) .. "]:[" .. Kitty.dump(value) .. "]"
	end

	return str;
end;
-- Constructor
Kitty.ListManager.constructor = function(self, list)
	-- Methods and tostring
	return setmetatable(list, {__index=Kitty.ListManager, __tostring=Kitty.ListManager.toString});
end;
setmetatable(Kitty.ListManager, {__call=Kitty.ListManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Drag-and-drop manager
Kitty.DragAndDropManager = {};
-- Static functions
Kitty.DragAndDropManager.getClassName = function()
	return "DragAndDropManager";
end;
Kitty.DragAndDropManager.SKILL = "skill";
Kitty.DragAndDropManager.ACTION = "action";
Kitty.DragAndDropManager.BAG = "bag";
Kitty.DragAndDropManager.EQUIP = "equip";
Kitty.DragAndDropManager.BANK = "bank";
Kitty.DragAndDropManager.EMOTE = "emote";
Kitty.DragAndDropManager.MACRO = "macro";
Kitty.DragAndDropManager.SUIT_SKILL = "SuitSkill";
Kitty.DragAndDropManager.SUIT_SKILL_PLATE = "SkillPlate";
Kitty.DragAndDropManager.hookedFunctionList = {
	["DragSkillButton"] = Kitty.DragAndDropManager.SKILL,
	["PickupAction"] = Kitty.DragAndDropManager.ACTION,
	["PickupBagItem"] = Kitty.DragAndDropManager.BAG,
	["PickupEquipmentItem"] = Kitty.DragAndDropManager.EQUIP,
	["PickupBankItem"] = Kitty.DragAndDropManager.BANK,
	["DragEmoteItem"] = Kitty.DragAndDropManager.EMOTE,
	["PickupMacroItem"] = Kitty.DragAndDropManager.MACRO,
	["DragSuitSkill_job"] = Kitty.DragAndDropManager.SUIT_SKILL,
	["SkillPlateDragStart"] = Kitty.DragAndDropManager.SUIT_SKILL_PLATE,
};
-- Instance methods
Kitty.DragAndDropManager.createHookFunction = function(self, funcName)
	local func = function(index1, index2)
		local cursorType = Kitty.DragAndDropManager.hookedFunctionList[funcName];
		assert(cursorType, "Error: CursorType is nil. FuncName:[" .. funcName .. "]");
		Kitty.debugPrint(cursorType, index1, index2);

		self.cursorType = cursorType;
		self.index1 = index1;
		self.index2 = index2;
	end;
	return func;
end;
-- While the kitty editor is open, note what was picked up (reload safe, and
-- the game functions stay functions for other addons; see Kitty.Hooks)
Kitty.DragAndDropManager.startHook = function(self)
	for functionName, _ in pairs(Kitty.DragAndDropManager.hookedFunctionList) do
		local record = self:createHookFunction(functionName);
		Kitty.Hooks.set(functionName, function(original, ...)
			pcall(record, ...);
			return original(...);
		end);
	end
end;
Kitty.DragAndDropManager.endHook = function(self)
	for functionName, _ in pairs(Kitty.DragAndDropManager.hookedFunctionList) do
		Kitty.Hooks.clear(functionName);
	end
end;
Kitty.DragAndDropManager.getInfo = function(self)
	return self.cursorType, self.index1, self.index2;
end;
Kitty.DragAndDropManager.clear = function(self)
	self.cursorType = "";
	self.index1 = 0;
	self.index2 = 0;
end;
-- String form
Kitty.DragAndDropManager.toString = function(self)
	return "CursorType:[" .. tostring(self.cursorType) .. "], Index1:[" .. tostring(self.index1) .. "], Index2:[" .. tostring(self.index2) .. "]";
end;
-- Constructor
Kitty.DragAndDropManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.cursorType = "";
	obj.index1 = 0;
	obj.index2 = 0;

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.DragAndDropManager, __tostring=Kitty.DragAndDropManager.toString});
end;
setmetatable(Kitty.DragAndDropManager, {__call=Kitty.DragAndDropManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- DropDown
Kitty.DropDown = {};
-- Static functions
Kitty.DropDown.SettingtoString = function(setting)
	local check = "[ ]";
	if(setting.checked) then
		check = "[O]";
	end
	local arrow = "[  ]";
	if(setting.hasArrow) then
		arrow = "[->]";
	end
	local title = "[     ]";
	if(setting.isTitle) then
		title = "[Title]";
	end
	local checkable = "[            ]";
	if(setting.notCheckable) then
		checkable = "[notCheckable]";
	end

	return check .. arrow .. title .. checkable .. " [" .. tostring(setting.value) .. "]/[" .. tostring(setting.text) .. "]";
end;
Kitty.DropDown.findIndex = function(list, target)
	for index, item in ipairs(list or {}) do
		if(type(item) == "string") then		-- Elements are strings
			if(item == target) then
				return index;
			end
		elseif(type(item) == "table") then	-- Elements are settings
			if(item.value == target) then
				return index;
			end
		else
			error("item was unexpected type. Type:[" .. type(item) .. "]");
		end

		if(item == target) then
			return index;
		end
	end
	return nil;
end;
-- Instance methods
Kitty.DropDown.getSelectedValue = function(self)
	return self.value;
end;
Kitty.DropDown.getSelectedText = function(self)
	return UIDropDownMenu_GetText(self.dropDownObj);
end;
-- Example 1 (elements are values)
--	local level1 = {"A", "B"};
--	local level2 = {{"A1", "A2"}, {"B1", "B2"}};
-- Example 2 (elements are settings)
--	local level1 = {
--		{value="A", text="aa"},
--		{value="B", text="bb"}
--	};
--	local level2 = {
--		{{value="A1", text="aa11"}, {value="A2", text="aa22"}, {value="A3", text="aa33"}},
--		{{value="B1", text="bb11"}, {value="B2", text="bb22"}, {value="B3", text="bb33"}}
--	};
Kitty.DropDown.setListData = function(self, onClickFunction, level1, level2)	-- {"A", "B"}, {{"A1", "A2"}, {"B1", "B2"}}
	-- Called when an entry is picked
	local func = function(button)
		Kitty.debugPrint("DropDownButton Name:[" .. tostring(button:GetName()) .. "], "
			.. "ID:[" .. tostring(button:GetID()) .. "], Value:[" .. tostring(button.value) .. "], Text:[" .. tostring(button:GetText()) .. "]");

		local previousValue = self.selectedValue;
		local previosuText = UIDropDownMenu_GetText(self.dropDownObj);
		-- Show the picked value
		self.selectedValue = button.value;
		UIDropDownMenu_SetText(self.dropDownObj, button:GetText());

		if(onClickFunction) then
			onClickFunction(self.dropDownObj, button,
							button.value, button:GetText(),	-- After picking
							previousValue, previosuText);	-- Before picking
		end

		if(UIDROPDOWNMENU_MENU_LEVEL == 2) then
			-- Hide the level-1 list
			CloseDropDownMenus(1);
		end
	end;

	-- Called on init
	local initializeFunction = function()
		Kitty.debugPrint("DropDown Level:[" .. tostring(UIDROPDOWNMENU_MENU_LEVEL) .. "], Value:[" .. tostring(UIDROPDOWNMENU_MENU_VALUE) .. "]");

		local level1Data = nil;
		if(type(level1)=="function") then
			level1Data = level1();	-- Call the function
		else
			level1Data = level1;
		end

		if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
			-- Level-1 menu
			for index, item in ipairs(level1Data or {}) do
				-- Element type check
				local setting = nil;
				if(type(item) == "string") then	-- Elements are strings
					setting = {};
					setting.text = item;	-- For display
					setting.value = item;	-- For internal use
				elseif(type(item) == "table") then	-- Elements are settings
					setting = Kitty.copyTable(item);
				else
					-- Error.
					error("item was unexpected type. Type:[" .. type(item) .. "]");
				end

				if(not self.isDescriptionMode) then
					local level2Data = nil;
					if(type(level2)=="function") then
						level2Data = level2(index, item);	-- Call the function
					elseif(type(level2)=="table") then
						level2Data = level2[index];
					else
						level2Data = level2;
					end

					if(not level2Data) then
						-- Level 1 only
						if(setting.checked == nil) then
							-- Set checked state
							local isCheck = false;
							if(setting.text == UIDropDownMenu_GetText(self.dropDownObj)) then
								isCheck = true;
							end
							setting.checked = isCheck;
						end
						setting.hasArrow = false;
						setting.func = func;
					else
						-- Level 1 + level 2
						setting.checked = false;
						setting.hasArrow = true;
						setting.isTitle = true;
						setting.notCheckable = true;
						setting.func = nil;
					end
				else
					-- Mode with descriptions
					-- Level 1 + level 2
					if(setting.checked == nil) then
						-- Set checked state
						local isCheck = false;
						if(setting.text == UIDropDownMenu_GetText(self.dropDownObj)) then
							isCheck = true;
						end
						setting.checked = isCheck;
					end
					setting.hasArrow = true;
					setting.func = func;
				end

				-- Add entries
				self:applyHelp(setting);
				self:applyIcon(setting);
				UIDropDownMenu_AddButton(setting, UIDROPDOWNMENU_MENU_LEVEL);
			end
		elseif(UIDROPDOWNMENU_MENU_LEVEL == 2) then
			-- Level-2 menu
			local itemIndex = Kitty.DropDown.findIndex(level1Data, UIDROPDOWNMENU_MENU_VALUE);
			local level2Data = nil;
			if(type(level2)=="function") then
				level2Data = level2(itemIndex, UIDROPDOWNMENU_MENU_VALUE);	-- Call the function
			elseif(type(level2)=="table") then
				level2Data = level2[itemIndex];
			else
				level2Data = level2;
			end

			for index, item in ipairs(level2Data or {}) do
				-- Element type check
				local setting = nil;
				if(type(item) == "string") then		-- Elements are strings
					setting = {};
					setting.text = item;	-- For display
					setting.value = item;	-- For internal use
				elseif(type(item) == "table") then	-- Elements are settings
					setting = Kitty.copyTable(item);
				else
					-- Error.
					error("item was unexpected type. Type:[" .. type(item) .. "]");
				end

				if(not self.isDescriptionMode) then
					if(setting.checked == nil) then
						-- Set checked state
						local isCheck = false;
						if(setting.text == UIDropDownMenu_GetText(self.dropDownObj)) then
							isCheck = true;
						end
						setting.checked = isCheck;
					end
					setting.hasArrow = false;
					setting.func = func;
				else
					-- Mode with descriptions
					setting.checked = false;
					setting.hasArrow = false;
					setting.isTitle = true;
					setting.notCheckable = true;
					setting.func = nil;
				end

				-- Add entries
				self:applyHelp(setting);
				self:applyIcon(setting);
				UIDropDownMenu_AddButton(setting, UIDROPDOWNMENU_MENU_LEVEL);
			end
		end
	end;

	if(self.width) then
		UIDropDownMenu_SetWidth(self.dropDownObj, self.width);
	end
	UIDropDownMenu_Initialize(self.dropDownObj, initializeFunction);
end;
-- Hover text for an entry (Cherry's KittyCombo): the game's dropdown shows
-- tooltipTitle/tooltipText when the mouse is over an entry.
Kitty.DropDown.applyHelp = function(self, setting)
	if(setting.tooltipText ~= nil or Kitty.MenuHelp == nil) then
		return;
	end
	local text = setting.text or setting.value;
	-- Entries shown under a friendly name keep their code name in value
	local help = (type(setting.value) == "string") and Kitty.MenuHelp.describe(self.name, setting.value) or nil;
	if(help == nil) then
		help = Kitty.MenuHelp.describe(self.name, tostring(text));
	end
	if(help ~= nil) then
		setting.tooltipTitle = tostring(text);
		setting.tooltipText = Kitty.teal(help);
	end
end;
-- Class icon on class menu entries ("D", "SD", "/S") of build dropdowns.
-- RoM's menu buttons have no icon texture (/kc probe), so the picture goes in
-- setting.kittyIcon and Kitty.DropDown.showMenuIcon draws it on the button.
Kitty.DropDown.applyIcon = function(self, setting)
	if(setting.kittyIcon ~= nil or Kitty.ClassIcons == nil or self.name == nil
		or not string.find(self.name, "BuildDropDownMenu$")) then
		return;
	end
	setting.kittyIcon = Kitty.ClassIcons.forBuild(tostring(setting.value or setting.text));
end;
-- Our icon textures on the game's menu buttons, by button name. Kept over a
-- Reload UI; a button object that changed gets a new texture.
Kitty.MenuIcons = Kitty.MenuIcons or {};
Kitty.DropDown.ICON_SIZE = 18;
-- The button UIDropDownMenu_AddButton just filled
Kitty.DropDown.lastButton = function(info, level)
	level = level or 1;
	local list = _G["DropDownList" .. level];
	local count = list and tonumber(rawget(list, "numButtons"));
	if(count ~= nil) then
		return _G["DropDownList" .. level .. "Button" .. count];
	end
	-- No count on the list: the last shown button with this text
	local found = nil;
	for index = 1, 32 do
		local button = rawget(_G, "DropDownList" .. level .. "Button" .. index);
		if(button == nil) then
			break;
		end
		local shown = (button.IsVisible == nil) or button:IsVisible();
		if(shown and button.GetText and button:GetText() == info.text) then
			found = button;
		end
	end
	return found;
end;
Kitty.DropDown.showMenuIcon = function(info, level)
	local button = Kitty.DropDown.lastButton(info or {}, level);
	if(button == nil or button.GetName == nil) then
		return;
	end
	local name = button:GetName();
	local entry = Kitty.MenuIcons[name];
	if(info ~= nil and info.kittyIcon ~= nil) then
		if(entry == nil or entry.button ~= button) then
			local texture = Kitty.Skin and Kitty.Skin.texture(button, "OVERLAY", nil);
			if(texture == nil) then
				return;
			end
			Kitty.Skin.try(texture, "SetSize", Kitty.DropDown.ICON_SIZE, Kitty.DropDown.ICON_SIZE);
			Kitty.Skin.place(texture, "RIGHT", button, "RIGHT", -2, 0);
			entry = {button = button, texture = texture};
			Kitty.MenuIcons[name] = entry;
		end
		entry.texture:SetTexture(info.kittyIcon);
		entry.texture:Show();
	elseif(entry ~= nil and entry.button == button) then
		entry.texture:Hide();
	end
end;
-- Every menu (also the game's) passes here, so an icon never stays on a
-- button that another menu reuses
Kitty.DropDown.addButton = function(original, info, level, ...)
	local result = original(info, level, ...);
	pcall(Kitty.DropDown.showMenuIcon, info, level);
	return result;
end;
if(type(UIDropDownMenu_AddButton) == "function" and Kitty.Hooks) then
	Kitty.Hooks.set("UIDropDownMenu_AddButton", Kitty.DropDown.addButton);
end
-- String form
Kitty.DropDown.toString = function(self)
	return "Kitty.DropDown";
end;
-- Constructor
Kitty.DropDown.constructor = function(self, dropDownObj, width, isDescriptionMode)
	-- Fields
	local obj = {};
	obj.dropDownObj = dropDownObj;
	obj.width = width;
	obj.isDescriptionMode = isDescriptionMode or false;
	obj.selectedValue = "";
	obj.name = dropDownObj and dropDownObj.GetName and dropDownObj:GetName() or nil;
	if(obj.name ~= nil) then
		Kitty.DropDown.ownMenus[obj.name] = true;
	end

	-- Methods and tostring
	return setmetatable(obj, {__index=Kitty.DropDown, __tostring=Kitty.DropDown.toString});
end;
setmetatable(Kitty.DropDown, {__call=Kitty.DropDown.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Keep KittyCombo's menus open (Cherry's KittyCombo)
-- The game hides an open dropdown a moment after the mouse leaves it: leaving
-- starts a countdown (UIDropDownMenu_StartCounting, UIDROPDOWNMENU_SHOW_TIME).
-- While one of KittyCombo's menus is open the countdown is stretched to
-- KEEP_OPEN_SECONDS, so the menu stays until you pick an entry or click one of
-- the KittyCombo windows (or that long passes). Other addons' menus are unchanged.
Kitty.DropDown.ownMenus = {};
Kitty.DropDown.KEEP_OPEN_SECONDS = 30;
Kitty.DropDown.isOwnMenuOpen = function()
	local menu = UIDROPDOWNMENU_OPEN_MENU;
	if(type(menu) == "table" and menu.GetName) then
		menu = menu:GetName();
	end
	return type(menu) == "string" and Kitty.DropDown.ownMenus[menu] == true;
end;
-- Reload safe (see Kitty.Hooks): the wrapper is installed once per game session.
Kitty.DropDown.keepOpen = function(original, frame, ...)
	if(not Kitty.DropDown.isOwnMenuOpen()) then
		return original(frame, ...);
	end
	local saved = UIDROPDOWNMENU_SHOW_TIME;
	UIDROPDOWNMENU_SHOW_TIME = Kitty.DropDown.KEEP_OPEN_SECONDS;
	local ok, err = pcall(original, frame, ...);
	UIDROPDOWNMENU_SHOW_TIME = saved;
	-- Also stretch a countdown already stored on the list (or its parent list)
	local list = frame;
	while(type(list) == "table") do
		if(type(list.showTimer) == "number" and list.showTimer < Kitty.DropDown.KEEP_OPEN_SECONDS) then
			list.showTimer = Kitty.DropDown.KEEP_OPEN_SECONDS;
		end
		list = rawget(list, "parent");
	end
	if(not ok) then
		error(err);
	end
end;
if(type(UIDropDownMenu_StartCounting) == "function" and Kitty.Hooks) then
	Kitty.Hooks.set("UIDropDownMenu_StartCounting", Kitty.DropDown.keepOpen);
	Kitty.DropDown.originalStartCounting = Kitty.Hooks.originals["UIDropDownMenu_StartCounting"];
end
