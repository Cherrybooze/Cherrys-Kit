-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Action bar slots.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Action bar (shortcut) manager
Kitty.SlotManager = {};
-- Static functions
Kitty.SlotManager.getPureName = function(skillName)
	skillName = skillName:gsub( " %+%d+", "" ) -- PLUSSED SKILL FIX UP
	-- Strip modifiers such as +10
	local str = skillName;
	if(str ~= nil) then
		local position = str:reverseFind("+");
		if(position) then
			str = string.sub(str, 0, position-1);
		end
	end
	return str;
end;
-- Read the name from the action bar
Kitty.SlotManager.getActionName = function(gameTooltip, index)
	if(gameTooltip) then
		Kitty.clearGameTooltip(gameTooltip);
		gameTooltip:SetActionItem(index);
		gameTooltip:Hide();
		local name = _G[gameTooltip:GetName() .. "TextLeft1"]:GetText();
		if(name) then
			name = Kitty.SlotManager.getPureName(name);
		end
		return tostring(name);
	else
		return "";
	end
end;
Kitty.SlotManager.getList = function(startIndex, endIndex)
	if(startIndex == nil) then
		startIndex = 1;
	end
	if(endIndex == nil) then
		endIndex = 80;
	end

	local list = {};
	for index = startIndex, endIndex do
		local path, _, _, _, _, _ = GetActionInfo(index);
		if(path ~= nil) then
			local name = Kitty.SlotManager.getActionName(KittyComboGameTooltip, index);
			if(name) then
				table.insert(list, name);
			end
		end
	end

	return list;
end;
-- Instance methods
-- Get index
Kitty.SlotManager.getIndex = function(self, name)
	return self.slotTable[name];
end;
-- Unusable check (cooldown only)
Kitty.SlotManager.canUse = function(self, name, threshold)
	if(threshold == nil) then
		threshold = 0.0;
	end

	local index = self.slotTable[name];
	if(index ~= nil) then
		local _, remaining = GetActionCooldown(index);
		if(remaining <= threshold) then
			-- Debug
			Kitty.debugPrint(tostring(name));

			return true, remaining;
		else
			return false, remaining;
		end
	end

	return false, 0;
end;
Kitty.SlotManager.use = function(self, name)
	local index = self.slotTable[name];
	if(index ~= nil) then
		UseAction(index);
	end
end;

-- Unusable check (range)
Kitty.SlotManager.inRange = function(self, name)
	local index = self.slotTable[name];
	if(index ~= nil) then
		return GetActionUsable(index);
	else
		-- Not on the action bar
		return nil;
	end
end;
-- Refresh slot info
Kitty.SlotManager.onUpdate = function(self, index)
	-- Clear
	for name, slotIndex in pairs(self.slotTable) do
		if(slotIndex == index) then
			self.slotTable[name] = nil;
			-- Debug
--			Kitty.debugPrint("Delete Index:[" .. tostring(index) .. "], Name:[" .. tostring(name) .. "]");
		end
	end
	-- Update
	local path, _, _, _, _, _ = GetActionInfo(index);
	if(path ~= nil) then
		local name = Kitty.SlotManager.getActionName(KittyComboGameTooltip, index);
		if(name) then
			self.slotTable[name] = index;
			-- Debug
--			Kitty.debugPrint("Add Index:[" .. tostring(index) .. "], Name:[" .. tostring(name) .. "]");
		end
	end
end;
-- String form
Kitty.SlotManager.toString = function(self, tabIndex)
	local str = "";
	if(tabIndex == nil or tabIndex == 0) then
		for name, index in pairs(self.slotTable) do
			if(str ~= "") then
				str = str .. ", ";
			end
			str = str .. string.format("[%s](%s)", name, index);
		end
	else
		local outCount = 0;
		local outIndex = 1;
		for name, index in pairs(self.slotTable) do
			if(outCount < 20) then
				if((tabIndex-1) * 20 <= outIndex and outIndex <= (tabIndex-1) * 20 + 20) then
					if(str ~= "") then
						str = str .. ", ";
					end
					str = str .. string.format("[%s](%s)", name, index);
					outCount = outCount + 1;
				end
				outIndex = outIndex + 1;
			else
				break;
			end
		end
	end

	return str;
end;
-- Constructor
Kitty.SlotManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.slotTable = {};

	-- Constructor
	-- Read shortcut info (shortcuts are valid only after LOADING_END)
	for index = 1, 80 do
		local path, _, _, _, _, _ = GetActionInfo(index);
		if(path ~= nil) then
			local name = Kitty.SlotManager.getActionName(KittyComboGameTooltip, index);
			if(name) then
				obj.slotTable[name] = index;
				-- Debug
				Kitty.debugPrint("Index:[" .. tostring(index) .. "], Name:[" .. tostring(name) .. "]");
			end
		end
	end

	return setmetatable(obj, {__index=Kitty.SlotManager, __tostring=Kitty.SlotManager.toString});
end;
setmetatable(Kitty.SlotManager, {__call=Kitty.SlotManager.constructor});	-- Calling the class makes an instance
