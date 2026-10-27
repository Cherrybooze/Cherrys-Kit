-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Party helpers.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Party tracker
Kitty.PartyManager = {};
-- Constants
Kitty.PartyManager.RAID = "raid";
Kitty.PartyManager.PARTY = "party";
Kitty.PartyManager.SOLO = "solo";
Kitty.PartyManager.OFF = "off";
Kitty.PartyManager.AUTO = "auto";
Kitty.PartyManager.ONCE = "once";
Kitty.PartyManager.raidTable = {}
for i = 1, 36 do
	table.insert(Kitty.PartyManager.raidTable, "raid"..i)
end
Kitty.PartyManager.partyTable = {"player"}
for i = 1, 5 do
	table.insert(Kitty.PartyManager.partyTable, "party"..i)
end
Kitty.PartyManager.soloTable = {"player"};
-- Static functions
-- Iterator over party members
--------------------------------------------------------------------------------
Kitty.PartyManager.iterator = function()
	local _, _, memberList = Kitty.PartyManager.getPartyState();

	-- Iterator
	local iterator = function(_, index)
		for _, unit in pairs(memberList) do
			local name = UnitName(unit);
			if(name ~= nil) then
				index = index + 1;
				coroutine.yield(index, unit, name);
			end
		end
	end;

	-- iterator function, state, start index
	return coroutine.wrap(iterator), nil, 0;
end;
-- Party size
Kitty.PartyManager.count = function()
	local members = GetNumRaidMembers();
	if(members > 0) then
		return members;
	end
	members = GetNumPartyMembers();
	if(members > 0) then
		return members;
	end
	return 1;
end;
-- Solo, party or raid
Kitty.PartyManager.getPartyState = function()
	local numberOfPeople = 0;

	-- Raid
	numberOfPeople = GetNumRaidMembers();
	if(numberOfPeople > 0) then
		-- Raid
		return Kitty.PartyManager.RAID, numberOfPeople, Kitty.PartyManager.raidTable;
	end
	--Party
	numberOfPeople = GetNumPartyMembers();
	if(numberOfPeople > 0) then	-- True for raids too
		-- Party
		return Kitty.PartyManager.PARTY, numberOfPeople, Kitty.PartyManager.partyTable;
	end
	-- Solo
	return Kitty.PartyManager.SOLO, 1, Kitty.PartyManager.soloTable;
end;
-- List of member names
Kitty.PartyManager.getMemberList = function()
	local memberList = {};
	for index, unit, name in Kitty.PartyManager.iterator() do
		table.insert(memberList, name);
	end
	return memberList
end;
-- Find a member's unit id by name
Kitty.PartyManager.searchTarget = function(targetName)
	for index, unit, name in Kitty.PartyManager.iterator() do
		if(targetName == name) then
			return unit;
		end
	end
	return nil;
end;
-- Find members of a class
Kitty.PartyManager.searchClass = function(className)	-- "RS", "*K", ...
	local resultList = {};
	for index, unit, _ in Kitty.PartyManager.iterator() do
		if(Kitty.BuildManager.matchWithTarget(unit, className)) then
			table.insert(resultList, unit);
		end
	end
	return resultList;
end;
-- Make raid assistant
Kitty.PartyManager.giveAssistant = function(unit)
	if(UnitExists(unit) and (not UnitIsUnit("player", unit))) then
		if(UnitIsRaidAssistant(unit) ~= true) then
			SwithRaidAssistant(UnitRaidIndex(unit), true);
			return true;
		end
	end
	return false;
end;
-- Detect members joining/leaving
Kitty.PartyManager.detectUpdatedMember = function(oldList, newList)
	local updatedList = {};
	-- updatedList[index] = {name, ("add"|"remove"|"update"), oldTarget, newTarget};

	-- Compare member lists
	for newName, newTarget in pairs(newList) do
		local oldTarget = oldList[newName];
		if(oldTarget == nil) then
			-- Joined
			table.insert(updatedList, {newName, "add", "none", newTarget});
		else
			if(oldTarget ~= newTarget) then
				-- Moved
			table.insert(updatedList, {newName, "update", oldTarget, newTarget});
			else
				-- No change
			end
		end
	end

	for oldName, oldTarget in pairs(oldList) do
		local newTarget = newList[oldName];
		if(newTarget == nil) then
			-- Left
			table.insert(updatedList, {oldName, "remove", oldTarget, "none"});
		end
	end

	return updatedList;
end;
-- Instance methods
-- Refresh the party
Kitty.PartyManager.update = function(self)
	-- Keep the old member list
	local oldNameTable = self.nameTable;
	local newNameTalbe = {};

	self.nameTable = {};
	-- Refresh the member list
	for index, unit in Kitty.PartyManager.iterator() do
		local name = UnitName(unit);
		if(name ~= nil) then
			newNameTalbe[name] = unit;
		end
	end
	self.nameTable = newNameTalbe;

	-- Detect members joining/leaving
	local updatedList = Kitty.PartyManager.detectUpdatedMember(oldNameTable, newNameTalbe);
	for _, updatedInfo in ipairs(updatedList) do

		if(self.autoRaidType ~= Kitty.PartyManager.OFF) then
			if(Kitty.PartyManager.count() == 6) then
				-- Switch to raid
				SwitchToRaid();
--------------------------------------------------------------------------------
Kitty.sendMessage("--- SwitchToRaid.", "DEFAULT", 1, 0, 0);
--------------------------------------------------------------------------------
			end

			if(self.autoRaidType == Kitty.PartyManager.ONCE) then
				self.autoRaidType = Kitty.PartyManager.OFF;
			end
		end

		for name, func in pairs(self.listnerTable) do
			-- Notify listeners
			func(unpack(updatedInfo));
		end
	end
end;
-- AutoRaid
Kitty.PartyManager.setAutoRaid = function(self, isAutoRaid)
	if(type(isAutoRaid) == "boolean") then
		if(isAutoRaid) then
			self.autoRaidType = Kitty.PartyManager.AUTO;
		else
			self.autoRaidType = Kitty.PartyManager.OFF;
		end
	else
		self.autoRaidType = isAutoRaid;
	end
end;
-- Add a listener
Kitty.PartyManager.addListner = function(self, name, func)
	self.listnerTable[name] = func;
end;
-- Remove a listener
Kitty.PartyManager.removeListner = function(self, name)
	self.listnerTable[name] = nil;
end;
-- String form
Kitty.PartyManager.toString = function(self)
	local str = "";
	for name, target in pairs(self.nameTable) do
		str = str .. "Name:[" .. name .. "], Target:[" .. target .. "]\n";
	end

	return str;
end;
-- Constructor
Kitty.PartyManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.nameTable = {};
	obj.listnerTable = {};
	obj.autoRaidType = Kitty.PartyManager.OFF;

	return setmetatable(obj, {__index=Kitty.PartyManager, __tostring=Kitty.PartyManager.toString});
end;
setmetatable(Kitty.PartyManager, {__call=Kitty.PartyManager.constructor});	-- Calling the class makes an instance
