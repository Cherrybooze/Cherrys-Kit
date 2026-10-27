-- (C) 2012-2013 Miranda
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Custom check function
Kitty.authorList = {
	["KittyHawk"] = true,
	["Miranda"] = true,
	["Virgo"] = true,
	["Kyle"] = true,
	["Legina"] = true,
	["AddOn"] = true,
	["RuntimeException"] = true,
};
Kitty.isAuthorFlag = nil;
-- Is this one of the original author's characters?
Kitty.isAuthor = function(name)
	if(name ~= nil) then
		-- Name given
		return (Kitty.authorList[name] ~= nil);
	end

	-- No name: use the player
	if(Kitty.isAuthorFlag == nil) then
		-- UnitName returns nil before LOADING_END.
		if(UnitName("player") ~= nil) then
			-- Calling UnitName while the game exits can crash it.
			if(Kitty.authorList[UnitName("player")] ~= nil) then
				Kitty.isAuthorFlag = true;
			else
				Kitty.isAuthorFlag = false;
			end
		else
			return true;
		end
	end

	return Kitty.isAuthorFlag;
end;

-- Clear a tooltip
Kitty.clearGameTooltip = function(gameTooltip)
	if(gameTooltip) then
		gameTooltip:ClearLines()
		for index = 1, 40 do
			local left = _G[gameTooltip:GetName() .. "TextLeft" .. index];
			local right = _G[gameTooltip:GetName() .. "TextRight" .. index];
			left:SetText("");
			right:SetText("");
		end
	end
end;

-- Opponent guild in a guild war
Kitty.getTargetGuildName = function(playerGuildName, playerServerName)
	if(playerGuildName == nil) then
		-- Player's guild
		playerGuildName = GetGuildInfo();
	end
	if(playerServerName == nil) then
		-- Player's server
		playerServerName = GetServerName();
	end

	local count = GuildHousesWar_GetRegisterCount();
	for index=1, count do
		local guild1, server1, _, guild2, server2 = GuildHousesWar_GetRegisterInfo(index);
		if(playerServerName == server1 and playerGuildName == guild1) then
			return guild2, server2;
		elseif(playerServerName == server2 and playerGuildName == guild2) then
			return guild1, server1;
		end
	end
	return nil;
end;

-- Print the revenge list
Kitty.showRevengeList = function()
	for index=1, GetFriendCount("HateFriend") do
		local name = GetFriendInfo("HateFriend", index);
		Kitty.sendMessage(name);
	end
end;
-- Clear the revenge list
Kitty.clearRevengeList = function(name)
	if(string.lower(name) == "all") then
		-- Remove all
		while(GetFriendCount("HateFriend") > 0) do
			DelFriend("HateFriend", GetFriendInfo("HateFriend", 1));
		end
	elseif(tonumber(name) ~= nil) then
		-- By number
		DelFriend("HateFriend", GetFriendInfo("HateFriend", tonumber(name)));
	else
		-- By name
		DelFriend("HateFriend", name);
	end
end;


-- The manager classes live in lib/managers/ (loaded right after this file):
--   BuildManager, CombatManager (+DamageManager), PartyManager, BuffManager,
--   SlotManager, SkillManager (+CooldownManager), ActionManagers (extra action, macro, emote)
