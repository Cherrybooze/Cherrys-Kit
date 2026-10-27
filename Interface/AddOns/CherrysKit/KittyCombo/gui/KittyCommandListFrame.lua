-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.CommandListFrame = {};
-- Command lists being edited
Kitty.CommandListFrame.allCommandList = nil;

-- Widget/data map
Kitty.CommandListFrame.relativeList = {
	-- Static texts
	["KittyCommandListFrame_VersionLabel"] = Kitty.getTitle(),
	["KittyCommandListFrame_TitleLabel"] = Kitty.T("message", "AllCommandListTitle"),

	["KittyCommandListFrame_CommandListNameLabel"] = Kitty.T("message", "CommandListNameLabel"),
	["KittyCommandListFrame_CommandListClassLabel"] = Kitty.T("message", "CommandListClassLabel"),
	["KittyCommandListFrame_CommandListTargetLabel"] = Kitty.T("message", "CommandListTargetLabel"),
	["KittyCommandListFrame_ActionsLabel"] = Kitty.L("ActionsLabel", "Actions"),

	["KittyCommandListFrame_CreateButton"] = Kitty.T("message", "CreateButton"),
	["KittyCommandListFrame_ImportButton"] = Kitty.L("ImportButton", "Import"),
	["KittyCommandListFrame_CloseButton"] = Kitty.T("message", "SaveAndCloseButton"),
	["KittyCommandListFrame_CancelButton"] = Kitty.T("message", "CancelButton"),
};

--------------------------------------------------------------------------------
-- Show window
Kitty.CommandListFrame.open = function()
	Kitty.CommandListFrame.allCommandList = Kitty.ListManager(Kitty.copyTable(Kitty.SettingManager.setting.command));

	Kitty.settingToComponent(nil, Kitty.CommandListFrame.relativeList);

	-- Show rows
	Kitty.CommandListFrame.onRedraw(this, 1, 10);

	KittyCommandListFrame:Show();
end;
Kitty.CommandListFrame.update = function(allCommandList)
	Kitty.CommandListFrame.allCommandList = allCommandList;

	-- Show rows
	Kitty.CommandListFrame.onRedraw(this, 1, 10);

	KittyCommandListFrame:Show();
end;

Kitty.CommandListFrame.save = function()
	Kitty.SettingManager.setting.command = nil;	-- GC
	Kitty.SettingManager.setting.command = Kitty.CommandListFrame.allCommandList;
end;
Kitty.CommandListFrame.close = function()
	Kitty.CommandListFrame.allCommandList = nil;

	KittyCommandListFrame:Hide();
end;

-- On click
Kitty.CommandListFrame.onClick = function(this, isNew)
	KittyCommandListFrame:Hide();

	if(isNew == true) then
		Kitty.CommandConfigFrame.open(Kitty.CommandListFrame.allCommandList, 0, Kitty.CommandListFrame.update);
	else
		local index = KittyCommandListFrame_ScrollBar:GetValue() + this:GetParent():GetID() - 1;
		-- Command list to view and edit
		Kitty.CommandConfigFrame.open(Kitty.CommandListFrame.allCommandList, index, Kitty.CommandListFrame.update);
	end
end;

-- Import: open the editor on a new kitty with the Import box ready for a code
Kitty.CommandListFrame.onImport = function(this)
	Kitty.CommandListFrame.onClick(this, true);
	if(KittyCommandConfigFrame_ImportEditBox) then
		KittyCommandConfigFrame_ImportEditBox:SetFocus();
	end
	Kitty.sendMessage(Kitty.L("ImportNewHint", "Paste the code into the Import box (Ctrl+V), press Import, then Save."));
end;

-- "Command lists  10" over the list and "10 command lists" under it
Kitty.CommandListFrame.showCount = function()
	local count = Kitty.CommandListFrame.allCommandList and #Kitty.CommandListFrame.allCommandList or 0;
	if(KittyCommandListFrame_TitleLabel) then
		KittyCommandListFrame_TitleLabel:SetText(Kitty.T("message", "AllCommandListTitle") .. "   |cff9ea8ba" .. count .. "|r");
	end
	if(KittyCommandListFrame_FooterLabel) then
		local text = (count == 1) and Kitty.L("CommandListCountOne", "1 command list")
			or Kitty.L("CommandListCount", "<<1>> command lists", tostring(count));
		KittyCommandListFrame_FooterLabel:SetText(text);
	end
end;
-- Class icon left of the Target Class text (hidden for "any", "proc" and unknown builds)
Kitty.CommandListFrame.setClassIcon = function(texture, build)
	if(not texture) then
		return;
	end
	local path = Kitty.ClassIcons.forBuild(build);
	if(path) then
		texture:SetTexture(path);
		texture:Show();
	else
		texture:Hide();
	end
end;
-- Show the command list rows
Kitty.CommandListFrame.onRedraw = function(this, start, count)
	local position = KittyCommandListFrame_ScrollBar:GetValue();
	if(start == position) then
		-- Redraw
		Kitty.CommandListFrame.onShowList(KittyCommandListFrame_ScrollBar, start, count);
	else
		-- Update the scroll bar (it redraws afterwards)
		KittyCommandListFrame_ScrollBar:SetValue(start);
	end
end;
Kitty.CommandListFrame.onShowList = function(this, start, count)
	if(count ~= nil) then
		count = 10;
	end

	-- Work out the slider range
	local aboveRange = start - 1;	-- Rows that can scroll up
	if(aboveRange < 0) then
		aboveRange = 0;
	end
	local belowRange = 0;
	if(Kitty.CommandListFrame.allCommandList ~= nil) then
		belowRange = #Kitty.CommandListFrame.allCommandList - count - (start - 1);	-- Rows that can scroll down
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
		-- Row
		local detailButton = getglobal("KittyCommandListFrame_Button" .. tostring(position));
		assert(detailButton, "KittyCommandListFrame_Button" .. tostring(position) .. " is nil.");
		-- Row: command list name
		local buttonName = getglobal(detailButton:GetName() .. "Name");
		assert(buttonName, detailButton:GetName() .. "Name is nil.");
		-- Row: class
		local buttonClass = getglobal(detailButton:GetName() .. "Class");
		assert(buttonClass, detailButton:GetName() .. "Class is nil.");
		-- Row: class icon
		local buttonClassIcon = getglobal(detailButton:GetName() .. "ClassIcon");
		-- Row: target
		local buttonTarget = getglobal(detailButton:GetName() .. "Target");
		assert(buttonTarget, detailButton:GetName() .. "Target is nil.");
		-- Row: edit button
		local buttonEdit = getglobal(detailButton:GetName() .. "EditButton");
		assert(buttonEdit, detailButton:GetName() .. "EditButton is nil.");

		if(Kitty.CommandListFrame.allCommandList ~= nil) then
			local command = Kitty.CommandListFrame.allCommandList[index];
			if(command ~= nil) then
				local info = command.info;
				if(info ~= nil) then
					-- Command list name
					buttonName:SetText(tostring(info.name));
					if(Kitty.BuildManager.matchWithTarget("player", info.class)) then
						-- Class (matching)
						buttonClass:SetColor(0.0, 1.0, 1.0);
						buttonClass:SetText(tostring(info.class));
					else
						-- Class (not matching)
						buttonClass:SetColor(1.0, 1.0, 1.0);
						buttonClass:SetText(tostring(info.class));
					end
					Kitty.CommandListFrame.setClassIcon(buttonClassIcon, info.class);
					-- Target
					buttonTarget:SetText(tostring(info.target));
					-- Button name
					buttonEdit:SetText(Kitty.T("message", "EditButton"));
				else
					buttonName:SetText("None:[info]");
					Kitty.CommandListFrame.setClassIcon(buttonClassIcon, nil);
				end
				detailButton:Show();
			else
				buttonName:SetText("None:[command]");
				detailButton:Hide();
			end
		end

		position = position + 1;
	end

	-- Check for duplicate command list names
	local duplicatedCommandNameList = {};
	if(Kitty.CommandListFrame.allCommandList ~= nil) then
		for index, commandList in ipairs(Kitty.CommandListFrame.allCommandList) do
			if(commandList.info ~= nil) then
				if(duplicatedCommandNameList[commandList.info.name] == nil) then
					duplicatedCommandNameList[commandList.info.name] = 1;
				else
					duplicatedCommandNameList[commandList.info.name] = duplicatedCommandNameList[commandList.info.name] + 1;
				end
			end
		end
	end

	position = 1;
	for index=start, start+count-1 do
		-- Row
		local detailButton = getglobal("KittyCommandListFrame_Button" .. tostring(position));
		assert(detailButton, "KittyCommandListFrame_Button" .. tostring(position) .. " is nil.");
		-- Row: command list name
		local buttonName = getglobal(detailButton:GetName() .. "Name");
		assert(buttonName, detailButton:GetName() .. "Name is nil.");

		if(Kitty.CommandListFrame.allCommandList ~= nil) then
			local command = Kitty.CommandListFrame.allCommandList[index];
			if(command ~= nil) then
				local info = command.info;
				if(info ~= nil) then
					if(duplicatedCommandNameList[info.name] > 1) then
						buttonName:SetColor(1.0, 0.0, 0.0);
					else
						buttonName:SetColor(1.0, 1.0, 1.0);
					end
				end
			end
		end
		position = position + 1;
	end
	Kitty.CommandListFrame.showCount();
end;
