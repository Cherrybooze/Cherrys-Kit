-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Buffs and debuffs on a unit, and the known effect list.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Buff/debuff reader
Kitty.BuffManager = {};
Kitty.BuffManager.effectNameList = {
	-- Buff
	--Skills
	[Kitty.T("skill",  "Amplified Attack")] =			{["id"]=500940, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Angel's Blessing")] =		{["id"]=502026, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Assassins Rage")] =				{["id"]=500960, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Awakening of the Wild D")] =	{["id"]=505157, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Blossoming Life")] =			{["id"]=503795, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Combat Master")] =				{["id"]=501921, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Courageous Guard")] =			{["id"]=502898, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Decay")] =						{["id"]=503263, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Death's Touch")] =			{["id"]=506222, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Enchanted Throw")] =			{["id"]=501279, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Energy Thief")] =				{["id"]=501924, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Enhanced Armor")] =				{["id"]=500141, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Enhanced Grace of Life")] =		{["id"]=502033, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Escape")] =						{["id"]=506454, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Essence of Magic")] =			{["id"]=501962, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Grace of Life")] =				{["id"]=500517, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Hide")] =						{["id"]=500675, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Holy Aura")] =				{["id"]=502902, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("skill",  "Holy Light Protection")] =		{["id"]=501940, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Holy Protection")] =			{["id"]=500673, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Holy Seal")] =				{["id"]=502077, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Holy Shield")] =				{["id"]=500943, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Ignore Pain")] =				{["id"]=501805, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Instant Shadow")] =				{["id"]=502597, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "King's Fearlessness")] =		{["id"]=506466, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Lucky Chance")] =			{["id"]=506665, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Lightning Burn Weapon")] =		{["id"]=500162, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Magic Tricks")] =				{["id"]={508539, 508534}, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Poison")] =						{["id"]=500715, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Premeditation")] =				{["id"]=500961, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Recover")] =					{["id"]=503797, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Regenerate")] =					{["id"]=500469, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Soul Bond")] =					{["id"]=500535, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Sprint")] =						{["id"]=500729, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Sublimation Weave Curse")] =	{["id"]=621736, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Undefeatable King")] =			{["id"]=506449, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Vanish")] =						{["id"]=500745, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Wave Armor")] =					{["id"]=500478, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Willpower Blade")] =			{["id"]=501571, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("skill",  "Yawaka's Blessing")] =			{["id"]=507485, ["isBuff"]=true, ["name"]=""},
    [Kitty.T("skill",  "Holy Light Strike")] =			{["id"]=502902, ["isBuff"]=true, ["name"]=""},
	--Effects																			
	[Kitty.T("effect", "ArcanePotion")] =				{["id"]=506133, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "ChainDrive")] =					{["id"]={621252,621253,622185}, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "FocusBuilding")] =				{["id"]=621444, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "Forceeff")] =					{["id"]=503827, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "Forgeeff")] =					{["id"]={621167,621251,621302,622184}, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "Hiddeneff")] =					{["id"]=505193, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "HiddenPeril")] =				{["id"]=504588, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "HighVoltage")] =				{["id"]={622952,622953,622954}, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "KillingIntent")] =				{["id"]=509320, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "MobEffect1")] =					{["id"]=509642, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "MobEffect2")] =					{["id"]={504995, 504996}, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "MobEffect3")] =					{["id"]=504238, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "PKState")] =					{["id"]=500668, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SacesFury")] =					{["id"]=621331, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "SacesImpulse")] =				{["id"]=621407, ["isBuff"]=true, ["name"]=""},													
	[Kitty.T("effect", "ShieldForm")] =					{["id"]=621218, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "SignAttack")] =					{["id"]=500999, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignDefence")] =				{["id"]=501000, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignExperience")] =				{["id"]=501001, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignMagicAttack")] =			{["id"]=501002, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignMagicDefence")] =			{["id"]=501003, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignRecovery")] =				{["id"]=500998, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "SignSkill")] =					{["id"]=501004, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "ThunderBoostLv1")] =			{["id"]=622952, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "ThunderBoostLv2")] =			{["id"]=622953, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "ThunderBoostLv3")] =			{["id"]=622954, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("effect", "WarpCharge")] =					{["id"]=501575, ["isBuff"]=true, ["name"]=""},												
	[Kitty.T("effect", "WillpowerConstructs")] =		{["id"]=501572, ["isBuff"]=true, ["name"]=""},															
	--Names																	
	[Kitty.T("name",   "MatchlessMob")] =				{["id"]={509642, 504995, 504996, 504238}, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("name",   "MatchlessPC")] =				{["id"]={505932, 505925}, ["isBuff"]=true, ["name"]=""},
	--Items
	[Kitty.T("item",   "ProtectMagicItem1")] =			{["id"]=501182, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("item",   "ProtectMagicItem2")] =			{["id"]=501190, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("item",   "ProtectMeleeItem")] =			{["id"]=501178, ["isBuff"]=true, ["name"]=""},
	[Kitty.T("item",   "ProtectMeleeItem2")] =			{["id"]=501189, ["isBuff"]=true, ["name"]=""},


	-- Debuff																
	--Skills																	
	[Kitty.T("skill", "Blind Spot")] =					{["id"]=620297, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Blind Stab")] =					{["id"]=500691, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Bone Chill")] =					{["id"]=501548, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Briar Entwinement")] =			{["id"]=503808, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Deadly Nightmare")] =			{["id"]=504057, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Death's Touch")] =				{["id"]=501815, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Electric Bolt")] =				{["id"]=501550, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Enter Nightmare")] =				{["id"]=508900, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Freeze")] =						{["id"]=501961, ["isBuff"]=false, ["name"]=""},
    [Kitty.T("skill", "Holy Light's Fury")] =			{["id"]=502074, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Lightning")] =					{["id"]={501535, 503837}, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Low Blow")] =					{["id"]={500704, 620314}, ["isBuff"]=false,["name"]="" },
	[Kitty.T("skill", "Low Roar")] =					{["id"]=508775, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Movement Restriction")] =		{["id"]=504241, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Open Flank")] =					{["id"]=501503, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Poisonous Infection")] =			{["id"]=502894, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Probing Attack")] =				{["id"]=501502, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Shadow Prison")] =				{["id"]={500735, 503861}, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Shadowstab")] =					{["id"]={500654, 620313, 621172}, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Slash")] =						{["id"]=500081, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("skill", "Sneak Attack")] =				{["id"]=500726, ["isBuff"]=false, ["name"]=""},
	--Effects																
	[Kitty.T("effect", "AuthoritativeDeterrence")] =	{["id"]=502112, ["isBuff"]=false, ["name"]=""},															
	[Kitty.T("effect", "BeastSigil")] =					{["id"]=620690, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "BleedRogue")] =					{["id"]={500654, 620313, 621172, 620297, 500726}, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "BleedWarrior")] =				{["id"]=500081, ["isBuff"]=false, ["name"]=""},												
	[Kitty.T("effect", "Disarmament")] =				{["id"]={500157,500158,500159,500165}, ["isBuff"]=false, ["name"]=""},												
	[Kitty.T("effect", "DisarmamentLv1")] =				{["id"]=500157, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "DisarmamentLv2")] =				{["id"]=500158, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "DisarmamentLv3")] =				{["id"]=500159, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "DisarmamentLv4")] =				{["id"]=500165, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "DivinePunishment")] =			{["id"]=502052, ["isBuff"]=false, ["name"]=""},													
	[Kitty.T("effect", "Electrocutioneff")] =			{["id"]=621396, ["isBuff"]=false, ["name"]=""},													
	[Kitty.T("effect", "ElementalExtraction")] =		{["id"]=623436, ["isBuff"]=false, ["name"]=""},														
	[Kitty.T("effect", "GrievousWoundLowBlow")] =		{["id"]={500704, 620314}, ["isBuff"]=false, ["name"]=""},														
	[Kitty.T("effect", "HolySeal")] =					{["id"]={500140,500146,500168,500169}, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "HolySealLv1")] =				{["id"]=500140, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolySealLv2")] =				{["id"]=500146, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolySealLv3")] =				{["id"]=500168, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolySealLv4")] =				{["id"]=500169, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolyStrikeLv1")] =			{["id"]=500137, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolyStrikeLv2")] =			{["id"]=500138, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "HolyStrikeLv3")] =			{["id"]=500139, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "IceFogRank1")] =				{["id"]=500485, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "IceFogRank2")] =				{["id"]=500486, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "IceFogRank3")] =				{["id"]=500487, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "SappingArrow")] =				{["id"]={501897,504285}, ["isBuff"]=false, ["name"]=""},												
	[Kitty.T("effect", "SilenceM")] =					{["id"]=500529, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "SilentSeal")] =					{["id"]=621445, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "SoulBrand")] =					{["id"]=621446, ["isBuff"]=false, ["name"]=""},											
	[Kitty.T("effect", "VampireArrows")] =				{["id"]=501690, ["isBuff"]=false, ["name"]=""},												
	[Kitty.T("effect", "Vulnerableeff")] =				{["id"]=501502, ["isBuff"]=false, ["name"]=""},												
    [Kitty.T("effect", "WaveArmorDebuff")] =			{["id"]=500479, ["isBuff"]=false, ["name"]=""},
	[Kitty.T("effect", "WeakenedWarlock")] =			{["id"]=501577, ["isBuff"]=false, ["name"]=""},													
	[Kitty.T("effect", "WeakenedWarrior")] =			{["id"]=501503, ["isBuff"]=false, ["name"]=""},													
	--Names																
	[Kitty.T("name", "Stun")] =							{["id"]={500735, 503861, 501535, 503837, 504241}, ["isBuff"]=false, ["name"]=""},


};

-- Static functions
-- Argument conversion (to skill name/ID and threshold pairs)
-- "Dirty Tricks" -> {["Dirty Tricks"] = threshold}
-- 501961 → {[501961] = threshold}
-- Converts forms like {"Blow", 501961, [500704]=0.6, ["Dirty Tricks"]=0.6}
-- ↓↓↓
-- into {["Blow"]=threshold, [501961]=threshold, [500704]=0.6, ["Dirty Tricks"]=0.6}

Kitty.BuffManager.format = function(inData, default)
	local out = {};

	if(inData == nil) then
		return out;
	end

	-- Default value (threshold)
	if(default == nil) then
		default = 0.0;
	end

	if(type(inData) == "number") then	-- 500704
		-- id
		out[inData] = default;
	elseif(type(inData) == "string") then	-- "Dirty Tricks"
		-- Effect
		out[inData] = default;
	elseif(type(inData) == "table") then	-- {[1]="Stab", ["Dirty Tricks"]=0.6, [2]=500704, [500704]=0.0}
		for key, value in pairs(inData) do
			if(type(key) == "number") then
				if(key < 100000) then		-- [1] = "Stab"
					out[value] = default;
				else	-- [500704] = 0.0
					out[key] = value;
				end
			elseif(type(key) == "string") then	-- ["Dirty Tricks"]=0.6
				out[key] = value;
			end
		end
	end

	return out;
end;
-- Argument conversion (skill names to IDs)
-- Converts forms like {"Blow"=0.0, [501961]=0.0, [500704]=0.6, ["Dirty Tricks"]=0.6}
-- into {[500081]=0.0, [501961]=0.0, [500704]=0.6, ["500704"]=0.6, ["620314"]=0.6}
Kitty.BuffManager.translate = function(inData)
	local out = {};

	if(inData == nil) then
		return out;
	end

	-- Table structure conversion
	for key, value in pairs(inData) do
		if(type(key) == "number") then
			-- id
			out[key] = value;
		elseif(type(key) == "string") then	-- ["Dirty Tricks"]=0.6
			if(Kitty.BuffManager.effectNameList[key] ~= nil) then
				if(type(Kitty.BuffManager.effectNameList[key].id) == "number") then	-- ["Dirty Tricks"] = {["id"]=500704}
					out[Kitty.BuffManager.effectNameList[key].id] = value;
				elseif(type(Kitty.BuffManager.effectNameList[key].id) == "table") then	-- ["Dirty Tricks"] = {["id"]={500704, 620314}}
					for _, id in pairs(Kitty.BuffManager.effectNameList[key].id) do
						out[id] = value;
					end
				end
			else
				-- Error
				error("Error: [" .. tostring(key) .. "] is nothing.");
			end
		else
			-- Error
			error("Error: [" .. tostring(key) .. "] is nothing.");
		end
	end

	return out;
end;
-- Instance methods
-- Update
Kitty.BuffManager.update = function(self, target)
	if(UnitName(target) == nil) then
		return;
	end
	self.name = tostring(UnitName(target));
	self.unit = target;

	local index = 1;
	self.effectTable = {};
	self.effectNameTable = {};

	-- Buff
	index = 1;
	while(true) do
		local name, texture, count, id, params = UnitBuff(target, index);
		if(name ~= nil) then
			-- Buff/debuff kind, buff name, texture, stacks, ID, parameter, timestamp, duration
			local table = {};
			table.isBuff = true;
			table.name = name;
			table.texture = texture;
			table.count = count;
			table.id = id;
			table.params = params;
			table.timestamp = Kitty.getTime();
			local duration = UnitBuffLeftTime(target, index);
			if(duration ~= nil) then
				table.duration = duration;
			end

			-- ID -> buff info
			self.effectTable[id] = table;
			-- Buff name -> buff info
			if(self.effectNameTable[name] == nil) then
				self.effectNameTable[name] = table;
			else
				-- Pick the one with the longest duration
				if(self.effectNameTable[name].duration and table.duration) then
					if(self.effectNameTable[name].duration < table.duration) then
						self.effectNameTable[name] = table;
					end
				elseif(table.duration) then
					self.effectNameTable[name] = table;
				end
			end

			index = index + 1;
		else
			break;
		end
	end

	-- Debuff
	index = 1;
	while(true) do
		local name, texture, count, id, params = UnitDebuff(target, index);
		if(name ~= nil) then
			-- Buff/debuff kind, debuff name, texture, stacks, ID, parameter, timestamp, duration
			local table = {};
			table.isBuff = false;
			table.name = name;
			table.texture = texture;
			table.count = count;
			table.id = id;
			table.params = params;
			table.timestamp = Kitty.getTime();
			local duration = UnitDebuffLeftTime(target, index);
			if(duration ~= nil) then
				table.duration = duration;
			end

			-- ID -> buff info
			self.effectTable[id] = table;
			-- Buff name -> buff info
			if(self.effectNameTable[name] == nil) then
				self.effectNameTable[name] = table;
			else
				-- Pick the one with the longest duration
				if(self.effectNameTable[name].duration and table.duration) then
					if(self.effectNameTable[name].duration < table.duration) then
						self.effectNameTable[name] = table;
					end
				elseif(table.duration) then
					self.effectNameTable[name] = table;
				end
			end

			index = index + 1;
		else
			break;
		end
	end
end;

-- Buff/debuff check (by name)
Kitty.BuffManager.hasEffectByName = function(self, effectName, threshold)
	local result = false;
	local duration = 0.0;

	local detail = self.effectNameTable[effectName];
	if(detail ~= nil) then
		if(detail.duration ~= nil) then
			if(detail.duration > threshold) then
				result = true;
				duration = detail.duration;
			else
				result = false;
			end
		else
			result = true;
		end
	else
		result = false;
	end

	return result, duration;
end;
-- Buff/debuff check (by ID)
Kitty.BuffManager.hasEffectById = function(self, id, threshold)
	local result = false;
	local duration = 0.0;

	local detail = self.effectTable[tonumber(id)];
	if(detail ~= nil) then
		if(detail.duration ~= nil) then
			if(detail.duration > threshold) then
				result = true;
				duration = detail.duration;
			else
				result = false;
			end
		else
			result = true;
		end
	else
		result = false;
	end

	return result, duration;
end;
-- Buff/debuff check (by default list)
-- format() + translate() results, per buff list and threshold. Buff lists in
-- conditions are the same table on every key press (editing makes a new copy),
-- so they are keyed weakly by table and dropped when the list is.
Kitty.BuffManager.idCache = setmetatable({}, {__mode="k"});
Kitty.BuffManager.idCacheByValue = {};
Kitty.BuffManager.getIds = function(effectName, threshold)
	local cache;
	if(type(effectName) == "table") then
		cache = Kitty.BuffManager.idCache;
	elseif(effectName ~= nil) then
		cache = Kitty.BuffManager.idCacheByValue;
	else
		return Kitty.BuffManager.translate(Kitty.BuffManager.format(effectName, threshold));
	end
	local byThreshold = cache[effectName];
	if(byThreshold == nil) then
		byThreshold = {};
		cache[effectName] = byThreshold;
	end
	local key = threshold or "nil";
	local ids = byThreshold[key];
	if(ids == nil) then
		-- Convert to skill name/ID and threshold pairs, then skill names to IDs
		ids = Kitty.BuffManager.translate(Kitty.BuffManager.format(effectName, threshold));
		byThreshold[key] = ids;
	end
	return ids;
end;
Kitty.BuffManager.hasEffect = function(self, effectName, threshold)
	local outData = Kitty.BuffManager.getIds(effectName, threshold);

	local result = false;
	local duration = 0.0;
	for id, limit in pairs(outData) do
		local detail = self.effectTable[id];
		if(detail ~= nil) then
			if(detail.duration ~= nil) then
				if(detail.duration > limit) then
					result = result or true;
					duration = detail.duration;
				else
					result = result or false;
				end
			else
				result = result or true;
			end
		else
			result = result or false;
		end
	end

	return result, duration;
end;

Kitty.lastDuration = 0.0;
Kitty.lastBuffName = "";
-- Invincible?
Kitty.BuffManager.fearlessCasterList = {
	Kitty.T("item", "ProtectMagicItem2"),
	Kitty.T("item", "ProtectMagicItem1"),
	Kitty.T("skill", "Holy Shield"),
	Kitty.T("skill", "Holy Light Strike"),
	Kitty.T("name", "MatchlessPC"),
	Kitty.T("name", "MatchlessMob"),
};
Kitty.BuffManager.fearlessMeleeList = {
	Kitty.T("item", "ProtectMeleeItem"),
	Kitty.T("skill", "Holy Shield"),
	Kitty.T("skill", "Holy Light Strike"),
	Kitty.T("name", "MatchlessPC"),
	Kitty.T("name", "MatchlessMob"),
};
Kitty.BuffManager.isFearless = function(self, opponentIsPlayerCaster)
	local list = nil;
	if(opponentIsPlayerCaster) then
		-- Player is a caster
		list = Kitty.BuffManager.fearlessCasterList;
	else
		-- Player is a melee class
		list = Kitty.BuffManager.fearlessMeleeList;
	end

	for _, buffName in ipairs(list) do
		local isFearless, duration = self:hasEffect(buffName, 0.3);
		if(isFearless) then
			Kitty.lastDuration = duration;
			Kitty.lastBuffName = buffName;
			return isFearless, duration, buffName;
		end
	end

	return false, 0.0, "";
end;

-- Target character name
Kitty.BuffManager.getName = function(self)
	return tostring(self.name);
end;

-- Buff check message (true: has buff, false: no buff, nil: duration message)
Kitty.BuffManager.formatBuffMessgage = function(self, buffName, threshold)
	if(threshold <= 0.0) then
		-- Zero or negative: always show the remaining time
		threshold = Kitty.MAX_VALUE;
	end

	local message = nil;
	local isBuff, duration = self:hasEffect(buffName);
	if(isBuff) then
		if(duration < threshold) then
			isBuff = nil;
			message = Kitty.T("message", "BuffDurationStateMessage",
				Kitty.colorCyan(self:getName()),
				Kitty.colorYellow(buffName),
				Kitty.colorYellow(Kitty.comma(duration)));
		else
			message = Kitty.T("message", "BuffExistStateMessage",
				Kitty.colorCyan(self:getName()),
				Kitty.colorYellow(buffName));
		end
	else
		message = Kitty.T("message", "BuffNonExistStateMessage",
			Kitty.colorCyan(self:getName()),
			Kitty.colorRed(buffName));
	end
	return isBuff, message;
end;

-- String form
Kitty.BuffManager.toString = function(self)
	local str = "";
	-- Buff
	str = str .. "[" .. self:getName() .. "]:Buff\n";
	for id, detail in pairs(self.effectTable) do
		if(detail.isBuff) then
			if(detail.duration ~= nil) then
				local remain = tonumber(detail.duration) - (Kitty.getTime() - tonumber(detail.timestamp));
				str = str .. string.format("%s(%s) %.2f[Sec]\n", tostring(detail.name), tostring(detail.id), remain);
			else
				str = str .. string.format("%s(%s)\n", tostring(detail.name), tostring(detail.id));
			end
		end
	end
	-- Debuff
	str = str .. "[" .. self:getName() .. "]:Debuff\n";
	for id, detail in pairs(self.effectTable) do
		if(not detail.isBuff) then
			if(detail.duration ~= nil) then
				local remain = tonumber(detail.duration) - (Kitty.getTime() - tonumber(detail.timestamp));
				str = str .. string.format("%s(%s) %.2f[Sec]\n", tostring(detail.name), tostring(detail.id), remain);
			else
				str = str .. string.format("%s(%s)\n", tostring(detail.name), tostring(detail.id));
			end
		end
	end

	return str;
end;
-- Constructor
Kitty.BuffManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.name = "";
	-- Buff/debuff
	obj.effectNameTable = {};	-- key: buff/debuff name, value: buff/debuff info
	obj.effectTable = {};		-- key: id, value: buff/debuff info

	return setmetatable(obj, {__index=Kitty.BuffManager, __tostring=Kitty.BuffManager.toString});
end;
setmetatable(Kitty.BuffManager, {__call=Kitty.BuffManager.constructor});	-- Calling the class makes an instance
