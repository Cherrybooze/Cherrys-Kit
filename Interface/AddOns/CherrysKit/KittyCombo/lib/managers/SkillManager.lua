-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Skill book lookups, cooldowns, and the lazy skill index.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
-- Skill reader
Kitty.SkillManager = {};
Kitty.SkillManager.manaList = {
	[Kitty.T("skill", "Holy Strike")] =					200,	-- K
	[Kitty.T("skill", "Disarmament")] =					200,	-- K
};
Kitty.SkillManager.tensionList = {
	[Kitty.T("skill", "Slash")] =						25,	-- W
	[Kitty.T("skill", "Whirlwind")] =					50,	-- W
	[Kitty.T("skill", "Berserk")] =						25,	-- W
	[Kitty.T("skill", "Defensive Formation")] =			25,	-- W
	[Kitty.T("skill", "Probing Attack")] =				10,	-- W
	[Kitty.T("skill", "Open Flank")] =					20,	-- W
	[Kitty.T("skill", "Tactical Attack")] =				15,	-- W
	[Kitty.T("skill", "Thunder")] =						15,	-- W
	[Kitty.T("skill", "Full Moon Cleave")] =			50,	-- W
	[Kitty.T("skill", "Shout")] =						30,	-- W
	[Kitty.T("skill", "Terror")] =						30,	-- W
	[Kitty.T("skill", "Blasting Cyclone")] =			35,	-- W
	[Kitty.T("skill", "Punishment W")] =				25,
	[Kitty.T("skill", "Sword of Imprisonment")] =		20,
	[Kitty.T("skill", "Brash Ferocity Strike")] =		25,
	[Kitty.T("skill", "Electrical Rage")] =				15,	-- WM
	[Kitty.T("skill", "Interrupting Strike")] =			30,	-- WP
	[Kitty.T("skill", "Opportunity")] =					15,	-- WP
	[Kitty.T("skill", "The Final Battle")] =			25,	-- WS
	[Kitty.T("skill", "Splitting Chop")] =				15,	-- WR
	[Kitty.T("skill", "Quick Reflexes")] =				20,	-- KW
	[Kitty.T("skill", "Fearless")] =					10,	-- KW
	[Kitty.T("skill", "Master of Parry")] =				30,	-- KW
	[Kitty.T("skill", "Authoritative Deterrence")] =	10,	-- KW
	[Kitty.T("skill", "Magical Talent")] =				20,	-- MW
	[Kitty.T("skill", "Magical Enlightenment")] =		35,	-- MW
	[Kitty.T("skill", "Elemental Explosion")] =			35,	-- MW
	[Kitty.T("skill", "Rage Mana")] =					35,	-- MW
	[Kitty.T("skill", "Ascending Dragon Strike")] =		30,	-- PW
	[Kitty.T("skill", "Vindictive Strike")] =			10,	-- PW
	[Kitty.T("skill", "Condensed Rage")] =				25,	-- PW
	[Kitty.T("skill", "Battle Instinct")] =				30,	-- SW
	[Kitty.T("skill", "Mental Focus")] =				30,	-- SW
	[Kitty.T("skill", "Death's Touch")] =				15,	-- RW
	[Kitty.T("skill", "Poisonous Infection")] =			20,	-- RW
	[Kitty.T("skill", "Double Chop")] =					25,	-- WdW
	[Kitty.T("skill", "Beast Chop")] =					20,	-- WdW
	[Kitty.T("skill", "Natural Attack")] =				15,	-- DW
	[Kitty.T("skill", "Cross of Thorns Attack")] =		30,	-- DW
	[Kitty.T("skill", "Healing Wind")] =				15,	-- DW
	[Kitty.T("skill", "Electrocution")] =				20,	-- Mc
	[Kitty.T("skill", "Heavy Bash")] =					20,	-- Mc
	[Kitty.T("skill", "Energy Influx Strike")] =		25,	-- Mc
	[Kitty.T("skill", "Shock Strike")] =				25,	-- Mc
	[Kitty.T("skill", "Fearless Blow")] =				15,	-- Mc
	[Kitty.T("skill", "Rune Energy Influx")] =			10,	-- Mc
	[Kitty.T("skill", "Vacuum Wave")] =					40,	-- Mc
	[Kitty.T("skill", "Imprisonment Pulse")] =			30,	-- Mc
	[Kitty.T("skill", "Arc Strike")] =					5,	-- McW
	[Kitty.T("skill", "Superior Suppression")] =		20,	-- McW
	[Kitty.T("skill", "Deadland Protection")] =			10,	-- McW
	[Kitty.T("skill", "Divine Vengeance")] =			15,	-- McP
	[Kitty.T("skill", "Rune Energy Consecration")] =	10,	-- McP
	[Kitty.T("skill", "Suppression Offensive")] =		10,	-- McM
	[Kitty.T("skill", "Dark Energy Strike")] =			20,	-- McSs
	[Kitty.T("skill", "Indomitable Spirit")] =			20,	-- McSs
	[Kitty.T("skill", "Rune Siphon")] =					10,	-- McSs
	[Kitty.T("skill", "Confusion Mechanism")] =			20,	-- RMc
	[Kitty.T("skill", "Foot Mechanism")] =				20,	-- RMc
	[Kitty.T("skill", "Silent Rune Bomb")] =			20,	-- RMc
	[Kitty.T("skill", "Pulse Rune Bomb")] =				25,	-- RMc
	[Kitty.T("skill", "Electrocution Mechanism")] =		35,	-- RMc
	[Kitty.T("skill", "Heart Rune Energy")] =			20,	-- PMc
	[Kitty.T("skill", "Diamond Light Activation")] =	30,	-- PMc
	[Kitty.T("skill", "Rune Footstep")] =				20,	-- PMc
	[Kitty.T("skill", "Brain Shock")] =					30,	-- MMc
	[Kitty.T("skill", "Electrolysis Power")] =			20,	-- MMc
	[Kitty.T("skill", "Ion Storm")] =					30,	-- MMc
	[Kitty.T("skill", "Saces's Fury")] =				10,	-- SsMc
};
Kitty.SkillManager.energyList = {
	[Kitty.T("skill", "Shadowstab")] =					20,	-- R
	[Kitty.T("skill", "Blind Stab")] =					20,	-- R
	[Kitty.T("skill", "Shadow Step")] =					20,	-- R
	[Kitty.T("skill", "Low Blow")] =					30,	-- R
	[Kitty.T("skill", "Wound Attack")] =				35,	-- R
	[Kitty.T("skill", "Blind Spot")] =					25,	-- R
	[Kitty.T("skill", "Premeditation")] =				20,	-- R
	[Kitty.T("skill", "Sneak Attack")] =				30,	-- R
	[Kitty.T("skill", "Shadow Prison")] =				50,	-- R
	[Kitty.T("skill", "Phantom Stab")] =				35,
	[Kitty.T("skill", "Escape")] =						30,
	[Kitty.T("skill", "Night Attack")] =				25,
	[Kitty.T("skill", "Unknown Choice")] =				25,
	[Kitty.T("skill", "Yawaka's Blessing")] =			30,
	[Kitty.T("skill", "Lion Claw Mark")] =				20,
	[Kitty.T("skill", "Sneak Shot")] =					25,
	[Kitty.T("skill", "Kanches' Rend")] =				35,
	[Kitty.T("skill", "Decay")] =						30,	-- RW
	[Kitty.T("skill", "Vengeance Sting")] =				25,	-- RM
	[Kitty.T("skill", "Create Opportunity")] =			45,	-- RM
	[Kitty.T("skill", "Disabling Blade")] =				50,	-- RM
	[Kitty.T("skill", "Quickness Aura")] =				60,	-- RP
	[Kitty.T("skill", "Kick")] =						30,	-- RP
	[Kitty.T("skill", "Energy Absorb")] =				20,	-- RS
	[Kitty.T("skill", "Killin' Time")] =				45,	-- RD
	[Kitty.T("skill", "Frenzied Attack")] =				50,	-- WR
	[Kitty.T("skill", "Keen Attack")] =					20,	-- WR
	[Kitty.T("skill", "Crazy Blades")] =				20,	-- KR
	[Kitty.T("skill", "Cursed Fangs")] =				30,	-- MR
	[Kitty.T("skill", "Demoralize")] =					30,	-- MR
	[Kitty.T("skill", "Snake Curse")] =					30,	-- PR
	[Kitty.T("skill", "Infectious Wound")] =			30,	-- PR
	[Kitty.T("skill", "Lure of the Snake Woman")] =		40,	-- PR
	[Kitty.T("skill", "Blinding Powder")] =				30,	-- SR
	[Kitty.T("skill", "Sapping Arrows")] =				30,	-- SR
	[Kitty.T("skill", "Achilles' Heel Strike")] =		30,	-- WdR
	[Kitty.T("skill", "Gravel Attack")] =				30,	-- WdR
	[Kitty.T("skill", "Poisonous Widow Embrace")] =		30,	-- DR
	[Kitty.T("skill", "Speed Catalysis")] =				15,	-- DR
	[Kitty.T("skill", "Corrosive Poison")] =			30,	-- DR
	[Kitty.T("skill", "Necrotic Wound")] =				30,	-- DR
	[Kitty.T("skill", "Shadow Pulse")] =				20,	-- McR
	[Kitty.T("skill", "Waiting Game")] =				20,	-- McR
	[Kitty.T("skill", "Shadow Explosion")] =			10,	-- McR
	[Kitty.T("skill", "Soul Poisoned Fang")] =			25,	-- SsR
};
Kitty.SkillManager.focusList = {
	[Kitty.T("skill", "Vampire Arrows")] =				20,	-- S
	[Kitty.T("skill", "Joint Blow")] =					15,	-- S
	[Kitty.T("skill", "Throat Attack")] =				15,	-- S
	[Kitty.T("skill", "Wrist Attack")] =				35,	-- S
	[Kitty.T("skill", "Wind Arrows")] =					15,	-- S
	[Kitty.T("skill", "Frost Arrow")] =					20,	-- S
	[Kitty.T("skill", "Mana Drain Shot")] =				35,	-- S
	[Kitty.T("skill", "Lasso")] =						35,	-- S
	[Kitty.T("skill", "Neck Strike")] =					30,	-- S
	[Kitty.T("skill", "Shatterstar Storm")] =			20,
	[Kitty.T("skill", "Target Lock")] =					30,	-- SW
	[Kitty.T("skill", "Aggro Transfer")] =				35,	-- SM
	[Kitty.T("skill", "Aggro Lead")] =					35,	-- SP
	[Kitty.T("skill", "Weak Spot")] =					30,	-- SR
	[Kitty.T("skill", "Poisonous Bite")] =				20,	-- SR
	[Kitty.T("skill", "Skull Breaker")] =				30,	-- WS
	[Kitty.T("skill", "Stun Shot")] =					30,	-- WS
	[Kitty.T("skill", "Aim for the Wound")] =			30,	-- WS
	[Kitty.T("skill", "Sword Breath")] =				25,	-- WS
	[Kitty.T("skill", "Arrow of Vengeance")] =			20,	-- KS
	[Kitty.T("skill", "Sacred Protection")] =			60,	-- KS
	[Kitty.T("skill", "Disregard Danger")] =			20,	-- KS
	[Kitty.T("skill", "Thunderclap")] =					20,	-- MS
	[Kitty.T("skill", "Magic Crossflow")] =				30,	-- MS
	[Kitty.T("skill", "Combat Master")] =				30,	-- RS
	[Kitty.T("skill", "Substitute")] =					30,	-- RS
	[Kitty.T("skill", "Anti-Magic Arrow")] =			30,	-- WdS
	[Kitty.T("skill", "Morale Boost Wd")] =				35,	-- WdS
	[Kitty.T("skill", "Healing Arrows")] =				20,	-- DS
	[Kitty.T("skill", "Psychic Arrows")] =				20,	-- Ss
	[Kitty.T("skill", "Weakening Weave Curse")] =		20,	-- Ss
	[Kitty.T("skill", "Warp Charge")] =					30,	-- Ss
	[Kitty.T("skill", "Soul Pain")] =					15,	-- Ss
	[Kitty.T("skill", "Surge of Malice")] =				20,	-- Ss
	[Kitty.T("skill", "Saces's Scorn")] =				30,	-- Ss
	[Kitty.T("skill", "Perplexed")] =					25,	-- Ss
	[Kitty.T("skill", "Perception Extraction")] =		15,	-- Ss
	[Kitty.T("skill", "Shield of Solid Mind")] =		35,	-- Ss
	[Kitty.T("skill", "Sublimation Weave Curse")] =		50,	-- Ss
	[Kitty.T("skill", "Beast's Roar")] =				30,	-- Ss
	[Kitty.T("skill", "Defense Net")] =					35,	-- Ss
	[Kitty.T("skill", "Soul Trauma")] =					25,	-- Ss
	[Kitty.T("skill", "Puzzlement")] =					20,	-- Ss
	[Kitty.T("skill", "Calm Paradox")] =				25,	-- Ss
	[Kitty.T("skill", "Surge of Awareness")] =			25,	-- Ss
	[Kitty.T("skill", "Spreading Pain")] =				15,	-- SsP
	[Kitty.T("skill", "Mind Rune")] =					15,	-- SsMc
	[Kitty.T("skill", "Rage Blow")] =					20,	-- WSs
	[Kitty.T("skill", "Divine Battle Spirit")] =		20,	-- WSs
	[Kitty.T("skill", "Psychic Battle Cry")] =			20,	-- WSs
	[Kitty.T("skill", "Spirit-Cracking Blow")] =		30,	-- WSs
	[Kitty.T("skill", "Soul Stab")] =					30,	-- RSs
	[Kitty.T("skill", "Ghostly Strike")] =				30,	-- RSs
	[Kitty.T("skill", "Touch of Revival")] =			30,	-- PSs
	[Kitty.T("skill", "Prayer of Tribulation")] =		30,	-- PSs
	[Kitty.T("skill", "Spirit Jump")] =					20,	-- PSs
	[Kitty.T("skill", "Spatial Jump")] =				20,	-- PSs
	[Kitty.T("skill", "Breath Erase")] =				10,	-- PSs
	[Kitty.T("skill", "Soul Stepping")] =				30,	-- PSs
	[Kitty.T("skill", "Fire Lightning Burst")] =		25,	-- PSs
	[Kitty.T("skill", "Endless Pulse")] =				20,	-- McSs
	[Kitty.T("skill", "Rune Siphon")] =					20,	-- McSs
	[Kitty.T("skill", "Heart Collection Rune")] =		35,	-- McSs
};
Kitty.SkillManager.soulPointList = {
	[Kitty.T("skill", "Willpower Blade")] =				6,
	[Kitty.T("skill", "Willpower Construct")] =			6,
	[Kitty.T("skill", "Locked Heart")] =				3,
	[Kitty.T("skill", "Severed Consciousness")] =		2,
	[Kitty.T("skill", "Mind Barrier")] =				5,
	[Kitty.T("skill", "Ruthless Judgment")] =			2,
	[Kitty.T("skill", "Knowledge Acquisition")] =		4,
	[Kitty.T("skill", "Otherworldly Whisper")] =		3,
	[Kitty.T("skill", "Life Weave")] =					6,
	[Kitty.T("skill", "Heart Fence")] =					2,	-- SsW
	[Kitty.T("skill", "Consistent Heart Strike")] =		2,	-- SsW
	[Kitty.T("skill", "Liquidation Suffering")] =		2,	-- SsR
	[Kitty.T("skill", "End of Thought")] =				3,	-- SsR
	[Kitty.T("skill", "Crime and Punishment")] =		2,	-- SsR
	[Kitty.T("skill", "Soul Enlightenment")] =			2,	-- SsP
	[Kitty.T("skill", "Touch of Faith")] =				2,	-- SsP
	[Kitty.T("skill", "Saces's Cracking Spell")] =		2,	-- SsM
	[Kitty.T("skill", "Soul Brand Sting")] =			1,	-- SsM
	[Kitty.T("skill", "Imagination Release")] =			1,	-- SsMc
	[Kitty.T("skill", "Saces's Impulse")] =				2,	-- SsMc
};
-- Static functions
-- Usable suit skill check
Kitty.SkillManager.isAvailableSuitSkill = function(skillName)
	for index = 0, (SkillPlateUpdate(-1) - 1) do
		if(SkillPlateUpdate(index) == skillName) then
			return true;
		end
	end
	return false;
end;
Kitty.SkillManager.castTarget = function(skillName, unitId)
	if(skillName ~= nil) then
		if(UnitName("target") ~= nil) then
			FocusUnit(1, "target");	-- Save
			TargetUnit(unitId);
			CastSpellByName(skillName);
			TargetUnit("focus1");	-- Restore
			FocusUnit(1, "");
		else
			TargetUnit(unitId);
			CastSpellByName(skillName);
			TargetUnit();	-- Clear Target
		end
	end
end;
-- Instance methods
-- Read skills
Kitty.SkillManager.update = function(self)
	-- Main class skills, sub class skills
	for tabIndex = 1, 4 do
		local skillCount = GetNumSkill(tabIndex);
		if skillCount then
			for skillIndex = 1, skillCount do
				local skill, _, texture, _, rank, _, nextRank, isSkillable, isAvailable = GetSkillDetail(tabIndex, skillIndex);
				local cooldown, remaining = GetSkillCooldown(tabIndex, skillIndex);
				if(self.skillTable[skill] == nil) then
					-- Add
					-- Skill name, texture, level, TP cost, isSkillable, isAvailable, cooldown, remaining, tabIndex, skillIndex, isSuitSkill
					self.skillTable[skill] = {};
				end
				-- Update
				self.skillTable[skill].skill = skill;
				self.skillTable[skill].texture = texture;
				self.skillTable[skill].rank = rank;
				self.skillTable[skill].nextRank = nextRank;
				self.skillTable[skill].isSkillable = isSkillable;
				self.skillTable[skill].isAvailable = isAvailable;
				self.skillTable[skill].cooldown = cooldown;
				self.skillTable[skill].remaining = remaining;
				self.skillTable[skill].tabIndex = tabIndex;
				self.skillTable[skill].skillIndex = skillIndex;
				self.skillTable[skill].isSuitSkill = false;
			end
		end
	end

	-- Suit skill
	for classIndex, count in ipairs({SetSuitSkill_List()}) do
		for skillIndex = 0, count-1 do
			--GetSuitSkill_List( int Jobindex, int Skillindex ) => string Name, string Texture, int index
			local skill, texture, index = GetSuitSkill_List(classIndex, skillIndex);	-- 8 / 8 / 8 / 0 / 0 / 8 / 0 / 0 / 11
			--SkillPlateUpdate(int index) return: ( string Name, string Texture, float total cooldown, float current cooldown );
			local _, _, cooldown, remaining = SkillPlateUpdate(skillIndex)
			if(self.skillTable[skill] == nil) then
				-- Add
				self.skillTable[skill] = {};
			end
			-- Update
			self.skillTable[skill].skill = skill;
			self.skillTable[skill].texture = texture;
			self.skillTable[skill].tabIndex = classIndex;
			self.skillTable[skill].skillIndex = skillIndex;
			self.skillTable[skill].cooldown = cooldown;
			self.skillTable[skill].remaining = remaining;
			self.skillTable[skill].index = index;
			self.skillTable[skill].isAvailable = false;
			self.skillTable[skill].isSuitSkill = true;
		end
	end
	
	-- Refresh isAvailable
	for index = 0, (SkillPlateUpdate(-1) - 1) do
		local skillDetail = self.skillTable[SkillPlateUpdate(index)];
		if(skillDetail ~= nil) then
			skillDetail.isAvailable = true;
		end
	end
end;
--------------------------------------------------------------------------------
-- Lazy skill lookups (Cherry's KittyCombo)
-- update() reads every skill and its cooldown on each key press. updateLazy()
-- reads only the skills a command list asks about. Where each skill lives in
-- the skill book is cached and re-read on PLAYER_SKILLED_CHANGED, after a
-- class change, when a cached slot no longer holds the expected skill, and
-- every INDEX_TTL seconds as a fallback.
Kitty.SkillManager.INDEX_TTL = 60;
Kitty.SkillManager.index = nil;
Kitty.SkillManager.indexTime = 0;
Kitty.SkillManager.invalidateIndex = function()
	Kitty.SkillManager.index = nil;
end;
Kitty.SkillManager.buildIndex = function()
	local index = {};
	-- Main class skills, sub class skills
	for tabIndex = 1, 4 do
		local skillCount = GetNumSkill(tabIndex);
		if skillCount then
			for skillIndex = 1, skillCount do
				local skill = GetSkillDetail(tabIndex, skillIndex);
				if(skill ~= nil) then
					index[skill] = {["isSuitSkill"]=false, ["tabIndex"]=tabIndex, ["skillIndex"]=skillIndex};
				end
			end
		end
	end
	-- Suit skills (same order as update(): a suit skill wins over a book skill with the same name)
	for classIndex, count in ipairs({SetSuitSkill_List()}) do
		for skillIndex = 0, count-1 do
			local skill, texture, plateIndex = GetSuitSkill_List(classIndex, skillIndex);
			if(skill ~= nil) then
				index[skill] = {["isSuitSkill"]=true, ["tabIndex"]=classIndex, ["skillIndex"]=skillIndex, ["texture"]=texture, ["index"]=plateIndex};
			end
		end
	end
	Kitty.SkillManager.index = index;
	Kitty.SkillManager.indexTime = Kitty.getTime();
end;
-- Same fields update() stores for one skill, or nil when the player does not have it
Kitty.SkillManager.fetchSkill = function(skillName)
	if(Kitty.SkillManager.index == nil or (Kitty.getTime() - Kitty.SkillManager.indexTime) > Kitty.SkillManager.INDEX_TTL) then
		Kitty.SkillManager.buildIndex();
	end
	for attempt = 1, 2 do
		local location = Kitty.SkillManager.index[skillName];
		if(location == nil) then
			return nil;
		end
		if(location.isSuitSkill) then
			local detail = {};
			detail.skill = skillName;
			detail.texture = location.texture;
			detail.tabIndex = location.tabIndex;
			detail.skillIndex = location.skillIndex;
			local _, _, cooldown, remaining = SkillPlateUpdate(location.skillIndex);	-- as update() does
			detail.cooldown = cooldown;
			detail.remaining = remaining;
			detail.index = location.index;
			detail.isAvailable = Kitty.SkillManager.isAvailableSuitSkill(skillName);
			detail.isSuitSkill = true;
			return detail;
		end

		local skill, _, texture, _, rank, _, nextRank, isSkillable, isAvailable = GetSkillDetail(location.tabIndex, location.skillIndex);
		if(skill == skillName) then
			local cooldown, remaining = GetSkillCooldown(location.tabIndex, location.skillIndex);
			local detail = {};
			detail.skill = skill;
			detail.texture = texture;
			detail.rank = rank;
			detail.nextRank = nextRank;
			detail.isSkillable = isSkillable;
			detail.isAvailable = isAvailable or Kitty.SkillManager.isAvailableSuitSkill(skillName);
			detail.cooldown = cooldown;
			detail.remaining = remaining;
			detail.tabIndex = location.tabIndex;
			detail.skillIndex = location.skillIndex;
			detail.isSuitSkill = false;
			return detail;
		end
		-- The skill book changed since the index was built
		Kitty.SkillManager.buildIndex();
	end
	return nil;
end;
Kitty.SkillManager.updateLazy = function(self)
	self.skillTable = setmetatable({}, {__index = function(skillTable, skillName)
		if(type(skillName) ~= "string") then
			return nil;
		end
		local detail = Kitty.SkillManager.fetchSkill(skillName);
		if(detail ~= nil) then
			rawset(skillTable, skillName, detail);
		end
		return detail;
	end});
end;

-- Get cooldown
Kitty.SkillManager.canCast = function(self, skillName, threshold)
	if(threshold == nil) then
		threshold = 0.6;
	end

	if(not self:isAvailable(skillName)) then
		return false, 0.0;
	end

	-- Mana check
	if(Kitty.SkillManager.manaList[skillName] ~= nil) then
		if(Kitty.ClassManager.getMana("player") < Kitty.SkillManager.manaList[skillName]) then
			return false, 0.0;
		end
	end
	-- Tension check
	if(Kitty.SkillManager.tensionList[skillName] ~= nil) then
		if(Kitty.ClassManager.getTension("player") < Kitty.SkillManager.tensionList[skillName]) then
			return false, 0.0;
		end
	end
	-- Rogue SP check
	if(Kitty.SkillManager.energyList[skillName] ~= nil) then
		if(Kitty.ClassManager.getEnergy("player") < Kitty.SkillManager.energyList[skillName]) then
			return false, 0.0;
		end
	end
	-- Scout SP check
	if(Kitty.SkillManager.focusList[skillName] ~= nil) then
		if(Kitty.ClassManager.getFocus("player") < Kitty.SkillManager.focusList[skillName]) then
			return false, 0.0;
		end
	end
	-- Shadow summoner soul point check
	if(Kitty.SkillManager.soulPointList[skillName] ~= nil) then
		local point, _ = Kitty.ClassManager.getSoulPoint();
		if(point < Kitty.SkillManager.soulPointList[skillName]) then
			return false, 0.0;
		end
	end

	local result = false;
	local remaining = 0.0;
	local skillType = Kitty.CooldownManager.getSkillType(skillName);
	if(skillType ~= nil or self:isSuitSkill(skillName)) then
		-- Skills whose cooldown must be tracked by the addon
		assert(self.cooldownManager, "CooldownManager is nil.");

		if(skillType == "TrialSkill") then
			-- Special skills
			-- Check both CooldownManager and SkillManager cooldowns
			local ret1, remain1 = self.cooldownManager:canCast(skillName, threshold);
			if(not ret1) then
				result = ret1;
				remaining = remain1;
			else
				local ret2, remain2 = self:canCastNormalSkill(skillName, threshold);
				if(not ret2) then
					result = ret2;
					remaining = remain2;
				else
					result = true;
					remaining = 0.0;
				end
			end
		else
			-- SuitSkill, CastingSpell
			-- Check the CooldownManager cooldown
			result, remaining = self.cooldownManager:canCast(skillName, threshold);
		end
	else
		-- Normal skills
		result, remaining = self:canCastNormalSkill(skillName, threshold);
	end

	return result, remaining;
end;
-- Cast (skill or suit skill)
-- Action slot that held Autoshot last time, so a key press does not scan all 80 slots
Kitty.autoshotSlot = nil;
Kitty.autoshotMissing = false;
Kitty.Autoshot = function()
	local mainClass, subClass = UnitClassToken("player");
	if mainClass == "RANGER" then
		local slot = Kitty.autoshotSlot;
		if slot ~= nil then
			local a1,a2,a3,a4,a5,ASon = GetActionInfo(slot)
			if tostring(a1):find("skill_ran_new35%-7") and ASon ~= nil then
				if ASon == false then
					UseAction(slot)
				end
				return
			end
			Kitty.autoshotSlot = nil
		end
		for i = 1, (Kitty.autoshotMissing and 0 or 80) do
			local a1,a2,a3,a4,a5,ASon = GetActionInfo(i)
			if tostring(a1):find("skill_ran_new35%-7") then
				if ASon ~= nil then
					Kitty.autoshotSlot = i
					if ASon == false then
						UseAction(i)
					end
					return
				end
			end
		end
		-- Not on the action bar: remember that until the bar changes
		Kitty.autoshotMissing = true
		for i = 80, 1, -1 do 
			if GetActionInfo(i) == nil then
				SetAction(i, 492589)
				local a1,a2,a3,a4,a5,ASon = GetActionInfo(i)
				if ASon == false then
					UseAction(i)
				end
				SetAction(i, 0)
				break;
			end
		end
	end
end
Kitty.SkillManager.cast = function(self, skillName)
	if(skillName ~= nil) then
		CastSpellByName(skillName);
		-- For the "Cast in last X sec" condition
		if(Kitty.lastCast ~= nil) then
			Kitty.lastCast[skillName] = GetTime();
		end
	end
	Kitty.debugPrint(string.format("%.2f[Sec] %s", Kitty.getTime(), "SkillName:[" .. tostring(skillName) .. "]"));
end;
-- Can a normal skill be cast?
Kitty.SkillManager.canCastNormalSkill = function(self, skillName, threshold)
	if(threshold == nil) then
		threshold = 0.6;
	end

	local skillDetail = self.skillTable[skillName];
	if(skillDetail ~= nil) then
		if(skillDetail.isAvailable and skillDetail.remaining <= threshold) then
			return true, skillDetail.remaining;
		end
	end

	return false, 0.0;
end;
-- Suit skill check
Kitty.SkillManager.isSuitSkill = function(self, skillName)
	if(self.skillTable[skillName] ~= nil) then
		return self.skillTable[skillName].isSuitSkill;
	else
		return false;
	end
end;
-- Usable skill check
Kitty.SkillManager.isAvailable = function(self, skillName)
	if(self.skillTable[skillName] ~= nil) then
		return self.skillTable[skillName].isAvailable;
	else
		return false;
	end
end;
-- Get hyperlink
Kitty.SkillManager.getHyperLink = function(self, skillName)
	local skillInfo = self.skillTable[skillName];
	if(skillInfo ~= nil) then
		return GetSkillHyperLink(skillInfo.tabIndex, skillInfo.skillIndex);
	end

	return nil;
end;
-- Get skill index
Kitty.SkillManager.getIndex = function(self, skillName)
	local skillInfo = self.skillTable[skillName];
	if(skillInfo ~= nil) then
		return skillInfo.tabIndex, skillInfo.skillIndex, skillInfo.index;
	end

	return nil;
end;
-- Get suit skill name
Kitty.SkillManager.getSuitSkill = function(self, index)
	for skillName, skillInfo in pairs(self.skillTable) do
		if(skillInfo ~= nil) then
			if(skillInfo.index == index) then
				return skillInfo.skill, skillInfo.texture;
			end
		end
	end
	return nil;
end;
-- String form
Kitty.SkillManager.toString = function(self, tabIndex)
	local str = "";

	if(type(tabIndex) == "string") then
		-- Details
		if(self.skillTable[tabIndex] ~= nil) then
			for key, value in pairs(self.skillTable[tabIndex]) do
				if(str ~= "") then
					str = str .. ", ";
				end
				str = str .. tostring(key) .. ":[" .. tostring(value) .. "]";
			end
		else
			str = "None";
		end
	else
		-- nil: all, zero: suit skills, number: that tab
		for skillName, skillDetail in pairs(self.skillTable) do
			if(tabIndex == nil) then
				-- All
				if(str ~= "") then
					str = str .. ", ";
				end
				str = str .. "[" .. tostring(skillDetail.skill) .. "]";
			elseif(tabIndex == 0) then
				-- Suit skills only
				if(skillDetail.isSuitSkill) then
					if(str ~= "") then
						str = str .. ", ";
					end
					str = str .. "[" .. tostring(skillDetail.skill) .. "]";
				end
			else
				-- Only the given tab
				if(skillDetail.tabIndex == tabIndex) then
					if(str ~= "") then
						str = str .. ", ";
					end
					str = str .. "[" .. tostring(skillDetail.skill) .. "]";
				end
			end
		end
	end

	return str;
end;
-- Constructor
Kitty.SkillManager.constructor = function(self, cooldownManager)
	-- Fields
	local obj = {};
	obj.skillTable = {};
	obj.cooldownManager = cooldownManager;

	return setmetatable(obj, {__index=Kitty.SkillManager, __tostring=Kitty.SkillManager.toString});
end;
setmetatable(Kitty.SkillManager, {__call=Kitty.SkillManager.constructor});	-- Calling the class makes an instance

--------------------------------------------------------------------------------
-- Cooldown tracker
Kitty.CooldownManager = {};
Kitty.CooldownManager.cooldownTable = {
	[Kitty.T("skill", "Blind Spot")] =									{["skilltype"]="TrialSkill",   ["cooldown"]=5.0},
	[Kitty.T("skill", "Blind Stab")] =									{["skilltype"]="TrialSkill",   ["cooldown"]=5.0},
	[Kitty.T("skill", "Electric Bolt")] =								{["skilltype"]="CastingSpell", ["cooldown"]=2.0},
-- Common: General, Item Set Skills
	--Restore Rage Focus Energy
	[Kitty.T("skill", "Energy Restore")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=45.0},	--Lvl  51 Sleepwalker Accessory
	--Restore Life
	[Kitty.T("skill", "Spirit Herb Essence")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  51 Sleepwalker Accessory
	[Kitty.T("skill", "Essence of Herbs of Omnipotence")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  62 Fire Protection, Angerfang's Spirit, Guardian's Spirit, Yinha's Spirit, Fury of Death, Blessing of Death  
	[Kitty.T("skill", "Mysterious Herb Essence")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  72 Augmented Release, Imprisoning Barrier, Spirit Suppression, Runic Energy, Immolating Burn, Glacial Freeze   
	[Kitty.T("skill", "Mysterious Fruit Essence")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  77 Disaster of Chaos, Master of Will, Headfirst Engagement, Final Strike, Sealed Fate, Otherworld Craftsman 
	[Kitty.T("skill", "Rare Elf Stone Essence")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  82 Lyfonava's Set, Sagwyth's Set, Sayafiz's Set, Jolytta's Set, Farutor's Set, Maderoth's Set  
	[Kitty.T("skill", "Elven Herb Extraction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  87 Kerkolon's Set, Horban's Set, Jalorian Bioweapons Set, Yarlis' Set, Gorligen's Set, Sarsidan's Set 
	[Kitty.T("skill", "Miracle Flower Extraction")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  92 Lismomo's Set, Yarnatha's Set, Tatarwiak's Set, Kinya's Set, Manakaza's Set, Voidal Banka Set    
	[Kitty.T("skill", "Sage Herb Extraction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  97 Charkor's Set, Mogmogur's Set, Genozan's Set, Kellas' Set, Meshyah's Set, Asoken's Set     
	[Kitty.T("skill", "Hundred Grass Essence Extraction")] =			{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl 100 Golem Guardian's Set, Kadnis' Set, Darkfang Set, Nex of Enoch Set, Sunlight Set 
	--Restore Mana
	[Kitty.T("skill", "Elemental Spirit Stone")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  51 Sleepwalker Accessory
	[Kitty.T("skill", "Essence of Elemental Stone of Omnipotence")] =	{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  62 Fire Protection, Angerfang's Spirit, Guardian's Spirit, Yinha's Spirit, Fury of Death, Blessing of Death  
	[Kitty.T("skill", "Mysterious Magic Stone Essence")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  72 Augmented Release, Imprisoning Barrier, Spirit Suppression, Runic Energy, Immolating Burn, Glacial Freeze   
	[Kitty.T("skill", "Blessed Magic Stone Essence")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  77 Disaster of Chaos, Master of Will, Headfirst Engagement, Final Strike, Sealed Fate, Otherworld Craftsman 
	[Kitty.T("skill", "Blessed Herb Extraction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  82 Lyfonava's Set, Sagwyth's Set, Sayafiz's Set, Jolytta's Set, Farutor's Set, Maderoth's Set
	[Kitty.T("skill", "Mysterious Elf Stone Essence")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  87 Kerkolon's Set, Horban's Set, Jalorian Bioweapons Set, Yarlis' Set, Gorligen's Set, Sarsidan's Set
	[Kitty.T("skill", "Rare Sage Stone Essence")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  92 Lismomo's Set, Yarnatha's Set, Tatarwiak's Set, Kinya's Set, Manakaza's Set, Voidal Banka Set
	[Kitty.T("skill", "Mysterious Sage Stone Essence")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  97 Charkor's Set, Mogmogur's Set, Genozan's Set, Kellas' Set, Meshyah's Set, Asoken's Set 
	[Kitty.T("skill", "Divine Magic Stone Essence")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl 100 Golem Guardian's Set, Kadnis' Set, Darkfang Set, Nex of Enoch Set, Sunlight Set 

-- W Warrior Item Set
	[Kitty.T("skill", "Undefeatable King")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  55 Fury Battle Wear
	--P[Kitty.T("skill", "Weapon Guard")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55 Devil Slaughter Suit
	[Kitty.T("skill", "Tourniquet 55")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  55 Fearless Chainmail Set ?
	[Kitty.T("skill", "Punishment W")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  58 Dragon On The Loose ?
	[Kitty.T("skill", "Sword of Imprisonment")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Guardian Punishment
	[Kitty.T("skill", "Composure")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  65 Heart of Distortion
	[Kitty.T("skill", "Tourniquet 67")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  67 Deadly Danger ?
	[Kitty.T("skill", "Brash Ferocity Strike")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  70 Assault of the Quaking King
	[Kitty.T("skill", "Powerhouse Sword")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  75 S2 Punishment Rune Series
	--P[Kitty.T("skill", "Iron Light Magic Ring Protection")] =			{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Lyong's Set	
	[Kitty.T("skill", "Guardian of the Pass")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  85 Tekoli-Wussa's Set
	[Kitty.T("skill", "Recovery Area")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  90 Khalakli Set
	[Kitty.T("skill", "Attack Stance")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  95 Slogar's Set
	[Kitty.T("skill", "Crescent Moon Cleave")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=10.0},	--Lvl  98 Terror Spread Set
	--P[Kitty.T("skill", "War Blade")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  99 Fursthor Set
	[Kitty.T("skill", "Soul Warrior")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=10.0},	--Lvl 100 Fursthor Set
	--P[Kitty.T("skill", "Desire to Destroy")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 104 Final Form of Extermination
	
-- K Knight Item Set
	[Kitty.T("skill", "Lion King Battle Roar")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  55 Destruction Armor
	[Kitty.T("skill", "Full Moon Cleave")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=20.0},	--Lvl  55 Knight's Falcon Suit
	[Kitty.T("skill", "Flawless Scarlet Sword")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  55 Fearless Plate Set 
	--P[Kitty.T("skill", "Honorable Fighter")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  58 Furious Fighter 
	--P[Kitty.T("skill", "Tyrant")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Sacred Beast Will
	[Kitty.T("skill", "Arching Chop")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=20.0},	--Lvl  65 Heart of Taming
	[Kitty.T("skill", "Lanaik's Roar")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  67 Skeleton Protection
	--P[Kitty.T("skill", "Wicked Backfire")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  70 Protection of the Unrivaled Shield
	[Kitty.T("skill", "Myrmex Military Sickle")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  75 Carnage
	--P[Kitty.T("skill", "Protection of Twilight")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Tatha's Set
	[Kitty.T("skill", "Tsunami")] =										{["skilltype"]="SuitSkill",    ["cooldown"]=20.0},	--Lvl  85 Pikusate's Set (A4/R20)
	[Kitty.T("skill", "Howl from the Deep")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  90 Adur Set (A30/R120)
	--P[Kitty.T("skill", "World Domination")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  95 Omnisoul Sarcophagus Set	
	[Kitty.T("skill", "Holy Thunder Blade")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  98 Kreyen's Set (A2/R4)
	[Kitty.T("skill", "Traces of the Cross Sword")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=15.0},	--Lvl  99 Nasqtas Set (A15/R10)
	--P[Kitty.T("skill", "Heroic Spirit Guard")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 100 Steel of Tomb	
	--P[Kitty.T("skill", "Honorable Guard")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 104 Final Form of Vitality	
	
-- M Mage Item Set
	[Kitty.T("skill", "Lucky Chance")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=12.0},	--Lvl  55 Bloody Attire
	[Kitty.T("skill", "Lucky Chance Wind")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=12.0,},
	[Kitty.T("skill", "Lucky Chance Flame")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=12.0,},
	[Kitty.T("skill", "Recover Magic")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  55 Elemental Flame Set
	[Kitty.T("skill", "Stone Scale Blade")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55 Fearless Cloth Set
	[Kitty.T("skill", "Unharmed")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  58 Thoughts on Ruling
	[Kitty.T("skill", "Earth Collapse")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  60 Unbalanced Energy
	[Kitty.T("skill", "Magic Tricks")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  65 Heart of Illusion (A0/R0)
	[Kitty.T("skill", "Magic Tricks Wind")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0,},
	[Kitty.T("skill", "Magic Tricks Flame")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0,},
	--P[Kitty.T("skill", "Sage")] =										{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  67 Energy Expansion
	[Kitty.T("skill", "Sword of Divinity")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  70 Dexterity of a Thousand Feathers
	--P[Kitty.T("skill", "Shetamb's Think Tank")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  75 Signal Suspicion
	[Kitty.T("skill", "Earth Splitting Giant Phantom")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Hoson's Set (A30/R0)
	[Kitty.T("skill", "Voice of the Sea")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  85 Aggregate of Desperation Set (A0/R180)
	[Kitty.T("skill", "Dulcet Tones")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  90 Thallsus Set
	[Kitty.T("skill", "Runic Formation")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  95 Sanbresha's Set (A180/R60)
	[Kitty.T("skill", "The Sage")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  98 Marissha's Set (A300 activeSkill?/R0 passiveSkill?)
	--P[Kitty.T("skill", "Divine Elementalist")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  99 Nex of Korris Set	Archadia
	[Kitty.T("skill", "Shining Blade")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  99 Nex of Korris Set	Runes
	--P[Kitty.T("skill", "Rune Master")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 100 Soul of Tomb	
	--P[Kitty.T("skill", "Badge of Destruction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 104 Final Form of Magic	

-- P Priest Item Set
	[Kitty.T("skill", "Mana Rune Stone")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55 Ornaments of the Void
	[Kitty.T("skill", "Holy Candle Shield")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl  55 Holy Source Set
	[Kitty.T("skill", "Frost Scars")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  55 Noble Cloth Set
	[Kitty.T("skill", "Cleanse Suit")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},  --Lvl  58 Guard of the Ruler
	[Kitty.T("skill", "Altar of Shadoj")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  60 Heart of Prayer
	[Kitty.T("skill", "Mage's Repayment")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  65 Puppet Heart
	[Kitty.T("skill", "Frost Death")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  67 Loyal Protection
	[Kitty.T("skill", "Heroic Guard")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  70 Power of the Cursed Face  
	[Kitty.T("skill", "Energy Reaction")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  75 War Experience
	[Kitty.T("skill", "Elemental Repercussions")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Krynor's Set
	[Kitty.T("skill", "Shield of Disorder")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl  80 Krynor's Set
	[Kitty.T("skill", "Water Element of Rebirth")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  85 Yifirus' Set	
	[Kitty.T("skill", "Death of Cold")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  90 Kelopas Set (A2/R4)
	[Kitty.T("skill", "Blessing of Rebirth")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  95 Istye's Set (A15/R60)
	[Kitty.T("skill", "Slipstream of Healing")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=10.0},	--Lvl  98 Mazzren's Set (A30/R10)
	[Kitty.T("skill", "Supreme Priest")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl  99 Zeyj Set (Archadia active / Runes passive)
	[Kitty.T("skill", "Divine Shield")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl 100 Wisdom of Tomb
	--P[Kitty.T("skill", "Divine Urge")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 104 Final Form of Aid	
	
-- R Rogue Item Set
	[Kitty.T("skill", "Phantom Stab")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Giant Fist Battle Suit
	[Kitty.T("skill", "Escape")] =										{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  55 Atrocity Suit
	[Kitty.T("skill", "Night Attack")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55 Fearless Leather Set
	[Kitty.T("skill", "Unknown Choice")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  58 The Controller's Thoughts
	[Kitty.T("skill", "Yawaka's Blessing")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Illegal Invasion
	[Kitty.T("skill", "Lion Claw Mark")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  65 Heart of Clown
	[Kitty.T("skill", "Sneak Shot")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  67 Strength of a Coward
	[Kitty.T("skill", "Kanches' Rend")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  70 Seizure of the Night King
	[Kitty.T("skill", "Greedy Blood Maggot")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  75 Sorrowful Sonata
	[Kitty.T("skill", "Poison Pangs")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Sandos' Set
	[Kitty.T("skill", "Demon Wolf Claw")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  85 Tabokake's Set
	[Kitty.T("skill", "Bloodless")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  90 Mosfetto Set
	[Kitty.T("skill", "Soul Storm")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  95 Old Dan's Set	(A20/R60)
	[Kitty.T("skill", "Claw Scar")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=6.0},	--Lvl  98 Nex of Tasuq Set
	[Kitty.T("skill", "Target")] =										{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  99 Cibel Set (Archadia active / Runes passive)
	[Kitty.T("skill", "Golden Cicada Skin")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl 100 Energy of Tomb (A60/R120)
	[Kitty.T("skill", "Lightning Attack")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl 104 Final Form of Agility	
		
-- S Scout Item Set
	[Kitty.T("skill", "Archer's Glory")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  55 Hunting Dress of the Goddess
	[Kitty.T("skill", "Shatterstar Storm")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Shatterstar Storm
	--P[Kitty.T("skill", "Keen Will")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55  Hurricane Leather Set
	[Kitty.T("skill", "Arrow Shield")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  58 The Baron's Rage
	[Kitty.T("skill", "Create Tendrils")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Brave and Fierce
	--P[Kitty.T("skill", "Hunter's Advantage")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  65 Heart of Teasing
	--P[Kitty.T("skill", "Focus Enhancement")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  67 Dark Energy
	[Kitty.T("skill", "Shadow of a Thousand Feathers")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  70 Massacre of the Insane Warrior
	[Kitty.T("skill", "Strange Arrow")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  75 Until Death
	--P[Kitty.T("skill", "Spirit Beast's Leather")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Lasoyl's Set
	[Kitty.T("skill", "Hunter Stance")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  85 Yinajo's Set
	[Kitty.T("skill", "Hurricane Downpour")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  90 Katbalbus Set
	[Kitty.T("skill", "Arrow Defense")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  95 Shabdoo's Set
	--P[Kitty.T("skill", "Going It Alone")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  98 Swamp of Oblivion Set
	[Kitty.T("skill", "Shock Frost Arrow")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl  99 Cibel Set
	--P[Kitty.T("skill", "Soul Raider")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 100 Energy of Tomb
	[Kitty.T("skill", "Devil's Contract")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=30.0},	--Lvl 104 Final Form of Agility	
		
-- Wd Warden Item Set
	--P[Kitty.T("skill", "Pet Master")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0}, 	--Lvl  55 Fury Battle Wear
	[Kitty.T("skill", "Beast King Attack")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=20.0},	--Lvl  55 Giant Tree Summoning Set
	[Kitty.T("skill", "Tranquil Wave")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0}, 	--Lvl  55 Earth-Splitter Chainmail Set
	[Kitty.T("skill", "Dance of Confusion")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=120.0}, --Lvl  58 Dragon On The Loose
	[Kitty.T("skill", "Unbind")] =										{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  60 Guardian Punishment
	[Kitty.T("skill", "Animal Spirit Eclipse")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  65 Heart of Distortion
	[Kitty.T("skill", "Companion")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  67 Deadly Danger
	--P[Kitty.T("skill", "Binding Contract")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  70 Assault of the Quaking King
	[Kitty.T("skill", "Beast Punishment")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=20.0},	--Lvl  75 S2 Punishment Rune Series (A8/R20)
	[Kitty.T("skill", "Shadow of the Mist")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  80 Lyong's Set
	[Kitty.T("skill", "Chaos of Greed")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=120.0}, --Lvl  85 Tekoli-Wussa's Set
	[Kitty.T("skill", "Unbridled Will")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  90 Khalakli Set
	[Kitty.T("skill", "Assault of the Animal Spirit")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=4.0},	--Lvl  95 Slogar's Set
	[Kitty.T("skill", "Echo Effect")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  98 Terror Spread Set
	[Kitty.T("skill", "Berserk of Nature")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  99 Fursthor Set Archadia
	[Kitty.T("skill", "Nervous Tribulations")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=180.0},	--Lvl  99 Fursthor Set Runes
	--P[Kitty.T("skill", "Iron Focus")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 100 Spirit of Tomb
	[Kitty.T("skill", "Animal Spirit's Embrace")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl 104 Final Form of Extermination	

-- D Druid Item Set
	[Kitty.T("skill", "Blinding Seeds55")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Druid Item Set
	[Kitty.T("skill", "Countdown Seeds")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Primal Spirit Set
	[Kitty.T("skill", "Forest Bath")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Augury Cloth Set
	[Kitty.T("skill", "Lunar Halo")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  58 Guard of the Ruler
	[Kitty.T("skill", "Green Seed")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Heart of Prayer
	[Kitty.T("skill", "Soul Soothe")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  65 Puppet Heart
	[Kitty.T("skill", "Forest Worship")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  67 Loyal Protection
	[Kitty.T("skill", "Nature's Force Field")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  70 Power of the Cursed Face
	[Kitty.T("skill", "Half-assimilate")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=120.0},	--Lvl  75 War Experience
	[Kitty.T("skill", "Blinding Seeds80")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  80 Krynor's Set	
	[Kitty.T("skill", "Seed of Destruction")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  85 Yifirus' Set		
	[Kitty.T("skill", "Return of Light")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  90 Kelopas Set	
	[Kitty.T("skill", "Life Seed")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  95 Istye's Set		
	[Kitty.T("skill", "Seed of Resonance")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  98 Mazzren's Set	
	[Kitty.T("skill", "Heaven and Earth")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl  99 Zeyj Set A240/R120
	[Kitty.T("skill", "Lava Effect")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=45.0},	--Lvl 100 Wisdom of Tomb
	[Kitty.T("skill", "Nature's Cleanse")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=300.0},	--Lvl 104 Final Form of Aid	

-- Warlock Item Set
	[Kitty.T("skill", "Dark Soul Essence")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  55 Bloody Attire
	[Kitty.T("skill", "Void Shift")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  55 Elemental Flame Set
	[Kitty.T("skill", "Dark Halo")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=50.0},	--Lvl  55 Fearless Cloth Set
	[Kitty.T("skill", "Abyss Footsteps")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  58 Thoughts on Ruling
	[Kitty.T("skill", "Soul Absorb Barrier")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  60 Unbalanced Energy
	[Kitty.T("skill", "Terror of Broken Souls")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  65 Heart of Illusion
	[Kitty.T("skill", "Self-Distortion")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  67 Energy Expansion
	[Kitty.T("skill", "Siphonic Etching")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  70 Dexterity of a Thousand Feathers
	[Kitty.T("skill", "Psychic Power of the Ant Queen")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=50.0},	--Lvl  75 Signal Suspicion
	[Kitty.T("skill", "Chaos Guide")] =									{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  80 Hoson's Set	
	[Kitty.T("skill", "Shield of the Otherworld")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  85 Aggregate of Desperation Set	Archadia 90  offi 60	
	[Kitty.T("skill", "Path of Anguish")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  90 Thallsus Set	Archadia 70  offi 60	
	[Kitty.T("skill", "Dead Spirit Protection")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  95 Sanbresha's Set		
	[Kitty.T("skill", "Spatial Rift")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=90.0},	--Lvl  98 Marissha's Set	30->90
	[Kitty.T("skill", "Traces of the Void")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  99 Nex of Korris Set Archadia 90  offi 0 oder Sperrzeit 10sec
	[Kitty.T("skill", "Soul Crusher")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 100 Soul of Tomb (A30/R0) Runes 6sec for dottime ?
	[Kitty.T("skill", "Astaroth's Dark Magic")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl 104 Final Form of Magic	40 -> 0

-- Champion Item Set
	[Kitty.T("skill", "Ultimate Destruction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  55 Fury Battle Wear
	[Kitty.T("skill", "Disassembly Step")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=5.0},	--Lvl  55 Devil Slaughter Suit
	--P[Kitty.T("skill", "Runic Enhancement")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  55 Fearless Chainmail Set
	[Kitty.T("skill", "Clone Conversion")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  58 Dragon On The Loose
	[Kitty.T("skill", "Battle Defense Transfer")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  60 Guardian Punishment
	[Kitty.T("skill", "Rune Guardian")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=300.0},	--Lvl  65 Heart of Distortion
	[Kitty.T("skill", "Energy Supply")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  67 Deadly Danger
	--P[Kitty.T("skill", "Power Upgrade")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  70 Assault of the Quaking King
	[Kitty.T("skill", "Punisher's Disassembly")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=8.0},	--Lvl  75 S2 Punishment Rune Series
	[Kitty.T("skill", "Ferocious Disassembly")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=5.0},	--Lvl  80 Lyong's Set	
	[Kitty.T("skill", "Organic Deconstruction")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=60.0},	--Lvl  85 Tekoli-Wussa's Set		
	[Kitty.T("skill", "Attack Is the Best Defense")] =					{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  90 Khalakli Set
	[Kitty.T("skill", "Sacrificial Protection")] =						{["skilltype"]="SuitSkill",    ["cooldown"]=480.0},	--Lvl  95 Slogar's Set	A300/R480
	--P[Kitty.T("skill", "Unbreakable")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  98 Terror Spread Set	
	--P[Kitty.T("skill", "Increased Drive")] =							{["skilltype"]="SuitSkill",    ["cooldown"]=0.0},	--Lvl  99 Fursthor Set
	[Kitty.T("skill", "Runic Charge")] =								{["skilltype"]="SuitSkill",    ["cooldown"]=40.0},	--Lvl 100 Spirit of Tomb
	[Kitty.T("skill", "Secret Technique of the Ruins")] =				{["skilltype"]="SuitSkill",    ["cooldown"]=240.0},	--Lvl 104 Final Form of Extermination	
		
};

-- Static functions
-- Is this a tracked skill?
Kitty.CooldownManager.getSkillType = function(skillName)
	local detail = Kitty.CooldownManager.cooldownTable[skillName];
	if(detail ~= nil) then
		return detail.skilltype;
	else
		return nil;
	end
end;
-- Instance methods
-- Skill succeeded
Kitty.CooldownManager.onSucceed = function(self, skillName)
	local detail = Kitty.CooldownManager.cooldownTable[skillName];
	if(detail ~= nil) then
		if(self.skillTable[skillName] == nil or (self.skillTable[skillName].skilltype ~= "CastingSpell")) then
			self.skillTable[skillName] = {};
			self.skillTable[skillName].skilltype = detail.skilltype;
			self.skillTable[skillName].cooldown = detail.cooldown;
			self.skillTable[skillName].timestamp = Kitty.getTime();
			self.skillTable[skillName].state = "Succeed";
		end

		local original = Kitty.CooldownManager.cooldownTable[detail.skillName];
		if(original ~= nil) then
			-- Put the skill on cooldown
			self.skillTable[detail.skillName] = {};
			self.skillTable[detail.skillName].skilltype = original.skilltype;
			self.skillTable[detail.skillName].cooldown = original.cooldown;
			self.skillTable[detail.skillName].timestamp = Kitty.getTime();
			self.skillTable[detail.skillName].state = "Cast";
		end
	end
end;
-- Skill failed
Kitty.CooldownManager.onFail = function(self, skillName)
	local detail = Kitty.CooldownManager.cooldownTable[skillName];
	if(detail ~= nil) then
		self.skillTable[skillName] = {};
		self.skillTable[skillName].skilltype = detail.skilltype;
		self.skillTable[skillName].cooldown = detail.cooldown;
		self.skillTable[skillName].timestamp = Kitty.getTime();
		self.skillTable[skillName].state = "Fail";
	end
end;
-- Spell cast started
Kitty.CooldownManager.onCast = function(self, skillName, cooldown)
	local detail = Kitty.CooldownManager.cooldownTable[skillName];
	if(detail ~= nil) then
		self.skillTable[skillName] = {};
		self.skillTable[skillName].skilltype = detail.skilltype;
		self.skillTable[skillName].cooldown = detail.cooldown;
		self.skillTable[skillName].timestamp = Kitty.getTime();
		self.skillTable[skillName].state = "Cast";
	else
		-- Cooldown for any action
		self.skillTable[skillName] = {};
		self.skillTable[skillName].skilltype = "Custom";
		self.skillTable[skillName].cooldown = cooldown or 3.0;
		self.skillTable[skillName].timestamp = Kitty.getTime();
		self.skillTable[skillName].state = "Act";
	end
end;
-- Can the skill be used?
Kitty.CooldownManager.canCast = function(self, skillName, threshold)
	if(threshold == nil) then
		threshold = 0.3;
	end
	threshold = math.abs(threshold);
	local result = false;
	local remaining = 0.0;
	local skillDetail = self.skillTable[skillName];
	if(skillDetail ~= nil) then
		local remain = skillDetail.timestamp + skillDetail.cooldown - Kitty.getTime();
		if(remain > threshold) then
			result = false;
			remaining = remain;
		else
			-- Clear cast history
			self.skillTable[skillName] = nil;
			result = true;
			remaining = remain;
		end
	else
		result = true;
		remaining = 0.0;
	end

	return result, remaining;
end;
-- String form
Kitty.CooldownManager.toString = function(self)
	local str = "";
	for key, value in pairs(self.skillTable) do
		if(str ~= "") then
			str = str .. ", ";
		end

		str = str .. tostring(key) .. ":";
		for k, v in pairs(value) do
			if(type(v) == "number") then
				str = str .. string.format("[%s=%.2f]", tostring(k), v);
			else
				str = str .. string.format("[%s=%s]", tostring(k), tostring(v));
			end
		end
	end

	if(str == "") then
		str = "None";
	end
	return str;
end;
-- Constructor
Kitty.CooldownManager.constructor = function(self)
	-- Fields
	local obj = {};
	obj.skillTable = {};

	return setmetatable(obj, {__index=Kitty.CooldownManager, __tostring=Kitty.CooldownManager.toString});
end;
setmetatable(Kitty.CooldownManager, {__call=Kitty.CooldownManager.constructor});	-- Calling the class makes an instance
