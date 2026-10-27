-- Cherry's KittyCombo, based on KittyCombo (C) 2012-2013 Miranda
-- Built-in command lists ("kitties") offered on first use. Players' own kitties
-- live in the saved variables (KittyCombo_Setting), not here.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

-- Command lists
Kitty.ComboManager.commandList = {
{
	["info"]={["name"]="Default_R", ["class"]="R", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hide"), ["icon"]="interface/icons/skill_thi3-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Vanish"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Evasion"), ["icon"]="interface/icons/skill_thi72-1", ["enable"]=true,
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Escape"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_002.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blind Spot"), ["icon"]="interface/icons/skill_thi3-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetIsPC", ["value"]=true},
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Shadowstab"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Low Blow"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wound Attack"), ["icon"]="interface/icons/skill_thi6-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
},

{
	["info"]={["name"]="Default_RS", ["class"]="RS", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hide"), ["icon"]="interface/icons/skill_thi3-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Vanish"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Evasion"), ["icon"]="interface/icons/skill_thi72-1", ["enable"]=true,
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Escape"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_002.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blind Spot"), ["icon"]="interface/icons/skill_thi3-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetIsPC", ["value"]=true},
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Shadowstab"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Low Blow"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wound Attack"), ["icon"]="interface/icons/skill_thi6-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wrist Attack"), ["icon"]="interface/icons/skill_ran18-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shooting"), ["icon"]="interface/icons/skill_ran1-2", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_RW", ["class"]="RW", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hide"), ["icon"]="interface/icons/skill_thi3-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Vanish"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Evasion"), ["icon"]="interface/icons/skill_thi72-1", ["enable"]=true,
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Escape"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_002.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blind Spot"), ["icon"]="interface/icons/skill_thi3-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Decay"), ["icon"]="interface/icons/skill_thi_new45-6.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Poison"), ["threshold"]=0.6}},
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Decay"), ["threshold"]=0.6}},
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Poisonous Infection"), ["icon"]="interface/icons/skill_thi_new35-4", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Death's Touch"), ["icon"]="interface/icons/skill_thi_new45-3", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=70, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Shadowstab"), ["threshold"]=0.6}},
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Low Blow"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wound Attack"), ["icon"]="interface/icons/skill_thi6-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_RK", ["class"]="RK", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hide"), ["icon"]="interface/icons/skill_thi3-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Vanish"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Sanction Attack"), ["icon"]="interface/icons/skill_kni6-1", ["enable"]=true,
		{["conditionType"]="targetIsPC", ["value"]=true},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Evasion"), ["icon"]="interface/icons/skill_thi72-1", ["enable"]=true,
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Escape"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_002.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Punishment"), ["icon"]="interface/icons/skill_kni1-2", ["enable"]=false,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "HolyStrikeLv3"), ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blind Spot"), ["icon"]="interface/icons/skill_thi3-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetIsPC", ["value"]=true},
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Shadowstab"), ["threshold"]=0.6}},
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Low Blow"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wound Attack"), ["icon"]="interface/icons/skill_thi6-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "DisarmamentLv4"), ["threshold"]=4.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Holy Strike"), ["icon"]="interface/icons/skill_kni5-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_RM", ["class"]="RM", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Instant Shadow"), ["icon"]="interface/Icons/elf_skill/skill_thi_mag40.dds", ["enable"]=true,
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Instant Shadow")},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hide"), ["icon"]="interface/icons/skill_thi3-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Vanish"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Evasion"), ["icon"]="interface/icons/skill_thi72-1", ["enable"]=true,
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Escape"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_002.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Double Throw"), ["icon"]="interface/icons/skill_thi21-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Throw"), ["icon"]="interface/icons/skill_thi1-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Day of Rain"), ["icon"]="interface/Icons/elf_skill/skill_thi_mag30.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blind Spot"), ["icon"]="interface/icons/skill_thi3-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetIsPC", ["value"]=true},
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Shadowstab"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Low Blow"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wound Attack"), ["icon"]="interface/icons/skill_thi6-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Low Blow"), ["icon"]="interface/icons/skill_thi12-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=60, ["max"]=nil},
	},
},

{
	["info"]={["name"]="Default_S", ["class"]="S", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Combo Shot"), ["icon"]="interface/icons/skill_ran3-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Piercing Arrow"), ["icon"]="interface/icons/skill_ran21-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Reflected Shot"), ["icon"]="interface/icons/skill_ran27-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_SK", ["class"]="SK", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Combo Shot"), ["icon"]="interface/icons/skill_ran3-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Piercing Arrow"), ["icon"]="interface/icons/skill_ran21-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Reflected Shot"), ["icon"]="interface/icons/skill_ran27-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_W", ["class"]="W", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Invincible Champion
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraUndefeatableKing"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Survival Instinct W"), ["icon"]="interface/icons/skill_war36-1", ["enable"]=true,
		{["conditionType"]="playerHealth", ["min"]=nil, ["max"]=49},
	},
	{
		-- W (one-handed)
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "WSingleHand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="isTwoHanded", ["value"]=false},
	},
	{
		-- W (two-handed)
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "WTwoHand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="isTwoHanded", ["value"]=true},
	},
},

{
	["info"]={["name"]="Default_WK", ["class"]="WK", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Ignore Pain"), ["icon"]="interface/icons/skill_war_new50-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Invincible Champion
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraUndefeatableKing"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Survival Instinct W"), ["icon"]="interface/icons/skill_war36-1", ["enable"]=true,
		{["conditionType"]="playerHealth", ["min"]=nil, ["max"]=49},
	},
	{
		-- WK (one-handed)
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "WKSingleHand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="isTwoHanded", ["value"]=false},
	},
	{
		-- WK (two-handed)
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "WKTwoHand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="isTwoHanded", ["value"]=true},
	},
},

{
	["info"]={["name"]="Default_WR", ["class"]="WR", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Invincible Champion
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraUndefeatableKing"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Survival Instinct W"), ["icon"]="interface/icons/skill_war36-1", ["enable"]=true,
		{["conditionType"]="playerHealth", ["min"]=nil, ["max"]=49},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blood Dance"), ["icon"]="interface/icons/skill_war_new20-2", ["enable"]=true,
	},
	{
		-- Lightning Speed
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Thunder"), ["icon"]="interface/icons/skill_war15-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
		{["conditionType"]="isTwoHanded", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Splitting Chop"), ["icon"]="interface/icons/skill_war_new40-2.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Probing Attack"), ["icon"]="interface/icons/skill_war3-2", ["enable"]=true,
		{["conditionType"]="canCast", {["name"]=Kitty.T("skill", "Splitting Chop"), ["threshold"]=0.6}},
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Open Flank"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Keen Attack"), ["icon"]="interface/icons/skill_war_new35-2", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Open Flank"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=60, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_WS", ["class"]="WS", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Invincible Champion
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraUndefeatableKing"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Survival Instinct W"), ["icon"]="interface/icons/skill_war36-1", ["enable"]=true,
		{["conditionType"]="playerHealth", ["min"]=nil, ["max"]=49},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Open Flank")},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Aim for the Wound"), ["icon"]="interface/icons/skill_war_new15-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
		{["conditionType"]="playerFocus", ["min"]=50, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Sword Breath"), ["icon"]="interface/icons/skill_war_new35-1", ["enable"]=true,
		{["conditionType"]="playerFocus", ["min"]=50, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shot"), ["icon"]="interface/icons/skill_ran1-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_WM", ["class"]="WM", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Invincible Champion
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraUndefeatableKing"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Defensive Formation"), ["icon"]="interface/icons/skill_war24-2", ["enable"]=false,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Survival Instinct W"), ["icon"]="interface/icons/skill_war36-1", ["enable"]=true,
		{["conditionType"]="playerHealth", ["min"]=nil, ["max"]=49},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning Burn Weapon"), ["icon"]="interface/Icons/elf_skill/skill_war_mag60.dds", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lightning Burn Weapon"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electrical Rage"), ["icon"]="interface/icons/skill_war_new15-3", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "ThunderBoostLv3"), ["threshold"]=1.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning's Touch"), ["icon"]="interface/icons/skill_war_new20-4", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_KW", ["class"]="KW", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Threaten"), ["icon"]="interface/icons/skill_kni16-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "HolySealLv3"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=75, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "DisarmamentLv4"), ["threshold"]=4.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Holy Strike"), ["icon"]="interface/icons/skill_kni5-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_KR", ["class"]="KR", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Threaten"), ["icon"]="interface/icons/skill_kni16-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "HolySealLv3"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "DisarmamentLv4"), ["threshold"]=4.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadowstab"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Holy Strike"), ["icon"]="interface/icons/skill_kni5-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_KS", ["class"]="KS", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Threaten"), ["icon"]="interface/icons/skill_kni16-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "HolySealLv3"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Hatred Strike"), ["icon"]="interface/icons/skill_kni12-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Whirlwind Shield"), ["icon"]="interface/icons/skill_kni20-1.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Holy Strike"), ["icon"]="interface/icons/skill_kni5-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_KP", ["class"]="KP", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Threaten"), ["icon"]="interface/icons/skill_kni16-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "HolySealLv3"), ["threshold"]=0.6}},
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Holy Strike"), ["icon"]="interface/icons/skill_kni5-1.dds", ["enable"]=true,
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0, ["value"]=false}},
	},
},

{
	["info"]={["name"]="Default_MP", ["class"]="MP", ["target"]="none"},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Discharge"), ["icon"]="interface/icons/skill_mag24-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Purgatory Fire"), ["icon"]="interface/icons/skill_mag72-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_MP_All", ["class"]="MP", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rising Tide"), ["icon"]="interface/icons/skill_aug1-1", ["enable"]=true,
	},
	{
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraMagicTricks"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_006.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electric Bolt"), ["icon"]="interface/icons/skill_mag_new50-5", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Electric Bolt"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Meteor Shower"), ["icon"]="interface/icons/skill_mag54-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_MP_PC", ["class"]="MP", ["target"]="pc"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Silence")},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Lightning")},
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rising Tide"), ["icon"]="interface/icons/skill_aug1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Phoenix"), ["icon"]="interface/icons/skill_mag21-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraMagicTricks"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_006.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electric Bolt"), ["icon"]="interface/icons/skill_mag_new50-5", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Electric Bolt"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Meteor Shower"), ["icon"]="interface/icons/skill_mag54-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_MK", ["class"]="MK", ["target"]="none"},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Discharge"), ["icon"]="interface/icons/skill_mag24-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Purgatory Fire"), ["icon"]="interface/icons/skill_mag72-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_MK_All", ["class"]="MK", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Light Charge"), ["icon"]="interface/icons/skill_mag_new35-4", ["enable"]=true,
	},
	{
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraMagicTricks"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_006.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electric Bolt"), ["icon"]="interface/icons/skill_mag_new50-5", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Electric Bolt"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Meteor Shower"), ["icon"]="interface/icons/skill_mag54-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_MK_PC", ["class"]="MK", ["target"]="pc"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Lightning")},
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Light Charge"), ["icon"]="interface/icons/skill_mag_new35-4", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Phoenix"), ["icon"]="interface/icons/skill_mag21-2", ["enable"]=true,
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "ExtraMagicTricks"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_006.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electric Bolt"), ["icon"]="interface/icons/skill_mag_new50-5", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Electric Bolt"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Meteor Shower"), ["icon"]="interface/icons/skill_mag54-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_P", ["class"]="P", ["target"]="none"},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Wave Armor"), ["icon"]="interface/icons/skill_aug3-2", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Wave Armor"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Regenerate"), ["icon"]="interface/icons/skill_aug3-1", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Regenerate"), ["threshold"]=1.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Urgent Heal"), ["icon"]="interface/icons/skill_aug42-3", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_PM_All", ["class"]="PM", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Icewind Blade"), ["icon"]="interface/icons/skill_aug_new45-7.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Death"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_z20_001", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Scars"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_003.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Bone Chill"), ["icon"]="interface/icons/skill_aug12-4", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Bone Chill"), ["threshold"]=1.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Chain of Light"), ["icon"]="interface/icons/skill_aug12-3.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_PM_PC", ["class"]="PM", ["target"]="pc"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="inRange", ["value"]=Kitty.T("skill", "Lightning")},
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Icewind Blade"), ["icon"]="interface/icons/skill_aug_new45-7.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Death"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_z20_001", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Scars"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_003.dds", ["enable"]=true,
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Bone Chill"), ["icon"]="interface/icons/skill_aug12-4", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Bone Chill"), ["threshold"]=1.0}},
	},
},

{
	["info"]={["name"]="Default_PK_All", ["class"]="PK", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rising Tide"), ["icon"]="interface/icons/skill_aug1-1", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Chain of Light"), ["icon"]="interface/icons/skill_aug12-3.dds", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Death"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_z20_001", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Scars"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_003.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Bone Chill"), ["icon"]="interface/icons/skill_aug12-4", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Bone Chill"), ["threshold"]=1.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rising Tide"), ["icon"]="interface/icons/skill_aug1-1", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_PK_PC", ["class"]="PK", ["target"]="pc"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shield of Atonement"), ["icon"]="interface/icons/skill_kni6-1", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Bone Chill"), ["icon"]="interface/icons/skill_aug12-4", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Bone Chill"), ["threshold"]=2.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Ice Fog Rank 1"), ["icon"]="interface/icons/skill_aug6-1", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Death"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_z20_001", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Frost Scars"), ["icon"]="interface/Icons/skill_panel_icons/sp_aug_003.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Chain of Light"), ["icon"]="interface/icons/skill_aug12-3.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_Wd", ["class"]="Wd", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Untamable"), ["icon"]="", ["enable"]=true,
	},
	{
		-- Cross Slash
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Cross Chop"), ["icon"]="", ["enable"]=true,
	},
	{
		-- Charged Slash
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Charged Chop"), ["icon"]="interface/icons/elf_skill/skill_ward1-1.dds", ["enable"]=true,
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
	{
		-- Power of the Wood Spirit
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Power of the Wood Spirit"), ["icon"]="interface/icons/elf_skill/skill_ward8-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_WdS", ["class"]="WdS", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Untamable"), ["icon"]="", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
	},
	{
		-- Cross Slash
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Cross Chop"), ["icon"]="", ["enable"]=true,
	},
	{
		-- Charged Slash
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Charged Chop"), ["icon"]="interface/icons/elf_skill/skill_ward1-1.dds", ["enable"]=true,
		{["conditionType"]="modeOn", {["name"]="request", ["threshold"]=0}},
	},
},

{
	["info"]={["name"]="Default_WdW", ["class"]="WdW", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		-- Cross Slash
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Cross Chop"), ["icon"]="", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Frantic Briar"), ["icon"]="interface/icons/elf_skill/skill_ward26-1.dds", ["enable"]=true,
	},
	{
		-- Power of the Wood Spirit
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Power of the Wood Spirit"), ["icon"]="interface/icons/elf_skill/skill_ward8-1.dds", ["enable"]=true,
	},
},

{
	["info"]={["name"]="Default_D", ["class"]="D", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Briar Entwinement"), ["icon"]="interface/icons/elf_skill/skill_dru2-1.dds", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Briar Entwinement"), ["threshold"]=1}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Earth Arrow"), ["icon"]="interface/icons/elf_skill/skill_dru1-2.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Blossoming Life"), ["icon"]="interface/icons/elf_skill/skill_dru10-1.dds", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=70},
		{["conditionType"]="playerNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Blossoming Life"), ["threshold"]=1.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Recover"), ["icon"]="interface/icons/elf_skill/skill_dru1-1.dds", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=50},
	},
},

{
	["info"]={["name"]="Default_McR", ["class"]="McR", ["target"]="all"},
	{
		-- Common commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "CommonCommand"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rune Energy Influx"), ["icon"]="interface/Icons/dwarf_skill/skill_psy18-2", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="name", ["name"]=Kitty.T("skill", "Shield Form"), ["threshold"]=0.0}},
		{["conditionType"]="targetIsBoss", ["value"]=true},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rune Growth"), ["icon"]="interface/Icons/dwarf_skill/skill_psy24-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Rune Pulse"), ["icon"]="interface/Icons/dwarf_skill/skill_psy10-1", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="name", ["name"]=Kitty.T("skill", "Chain Drive"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Pulse"), ["icon"]="interface/Icons/dwarf_skill/skill_psy_thi20-1.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fearless Blow"), ["icon"]="interface/Icons/dwarf_skill/skill_psy14-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Electrocution"), ["icon"]="interface/Icons/dwarf_skill/skill_psy1-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shock Strike"), ["icon"]="interface/Icons/dwarf_skill/skill_psy20-1", ["enable"]=true,
	},
	{
		-- Sinister
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vicious Attack"), ["icon"]="interface/icons/skill_thi1-1", ["enable"]=true,
		{["conditionType"]="playerEnergy", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Heavy Bash"), ["icon"]="interface/Icons/dwarf_skill/skill_psy1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Throw"), ["icon"]="interface/icons/skill_thi1-2", ["enable"]=true,
	},
},

-- RangeAttack
{
	["info"]={["name"]="RangeAttack", ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="proc", ["commandName"]="RangeAttack_S", ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerClass", ["value"]="/S"},
	},
	{
		["commandType"]="break", ["commandName"]="", ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerClass", ["value"]="/S"},
	},
	{
		["commandType"]="proc", ["commandName"]="RangeAttack_RM", ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerClass", ["value"]="RM"},
	},
	{
		["commandType"]="break", ["commandName"]="", ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerClass", ["value"]="RM"},
	},
	{
		["commandType"]="proc", ["commandName"]="RangeAttack_R", ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerClass", ["value"]="R/"},
	},
},

{
	["info"]={["name"]="RangeAttack_S", ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Vampire Arrows"), ["icon"]="interface/icons/skill_ran6-3.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shooting"), ["icon"]="interface/icons/skill_ran1-2", ["enable"]=true,
	},
},

{
	["info"]={["name"]="RangeAttack_R", ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Kanches' Rend"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_z21_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Phantom Stab"), ["icon"]="interface/Icons/skill_panel_icons/sp_thi_001.dds", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Shadow Step"), ["icon"]="interface/icons/skill_thi27-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Combo Throw"), ["icon"]="interface/icons/skill_thi21-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Throw"), ["icon"]="interface/icons/skill_thi1-2", ["enable"]=true,
	},
},

{
	["info"]={["name"]="RangeAttack_RM", ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Silence"), ["icon"]="interface/icons/skill_aug39-2", ["enable"]=true,
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Throw"), ["icon"]="interface/icons/skill_thi1-2", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Double Throw"), ["icon"]="interface/icons/skill_thi21-2", ["enable"]=true,
	},
	{
		-- Summon Thunder
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Lightning"), ["icon"]="interface/icons/skill_mag3-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect",	{["effectType"]="original", ["name"]=Kitty.T("skill", "Holy Light Protection"), ["threshold"]=0.6},
												{["effectType"]="original", ["name"]=Kitty.T("skill", "Ignore Pain"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Fireball"), ["icon"]="interface/icons/skill_mag1-1", ["enable"]=true,
	},
},

-- Common commands
{
	["info"]={["name"]=Kitty.T("name", "CommonCommand"), ["class"]="proc", ["target"]="all"},
	{
		-- Loot commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "LootCommand"), ["icon"]="", ["enable"]=true,
	},
	{
		-- Healing commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "RecoveryCommand"), ["icon"]="", ["enable"]=false,
		{["conditionType"]="isCG", ["value"]=false},
	},
	{
		-- Invincibility commands
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "MatchlessCommand"), ["icon"]="", ["enable"]=false,
		{["conditionType"]="isCG", ["value"]=true},
	},
	{
		-- Invincible?
		["commandType"]="proc", ["commandName"]=Kitty.T("name", "TargetMatchless"), ["icon"]="", ["enable"]=true,
	},
},

-- Loot check
{
	["info"]={["name"]=Kitty.T("name", "LootCommand"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="break", ["commandName"]="", ["icon"]="", ["enable"]=true,
		{["conditionType"]="targetIsDead", ["value"]=true},
		{["conditionType"]="playerClass", ["value"]="K/"},
	},
	{
		["commandType"]="break", ["commandName"]="", ["icon"]="", ["enable"]=true,
		{["conditionType"]="targetIsDead", ["value"]=true},
		{["conditionType"]="playerClass", ["value"]="S/"},
	},
	{
		-- Attack
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Attack"), ["icon"]="interface/Icons/weapon/wp_act_blade", ["enable"]=true,
		{["conditionType"]="targetIsDead", ["value"]=true},
	},
},

-- Potions
{
	["info"]={["name"]=Kitty.T("name", "RecoveryCommand"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPPotionLv5"), ["icon"]="interface/icons/fete_water_05", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=20},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPPotionLv4"), ["icon"]="interface/icons/item_potion_040_008", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=30},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPPotionLv3"), ["icon"]="interface/icons/item_potion_070_006", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=40},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPPotionLv2"), ["icon"]="interface/icons/item_potion_040_001", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=50},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPPotionLv1"), ["icon"]="interface/icons/item_potion_030_001", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=60},
	},
	{
		-- Lv5 Philius' Mysterious Water
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPMPpotionLv5"), ["icon"]="interface/icons/fete_water_10", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=20},
	},
	{
		-- Lv4 Philius' Mysterious Water
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPMPpotionLv4"), ["icon"]="interface/icons/item_potion_040_009", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=30},
	},
	{
		-- Lv3 Philius' Mysterious Water
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPMPpotionLv3"), ["icon"]="interface/icons/item_potion_070_003", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=40},
	},
	{
		-- Lv2 Philius' Mysterious Water
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPMPpotionLv2"), ["icon"]="interface/icons/item_potion_040_003", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=50},
	},
	{
		-- Lv1 Philius' Mysterious Water
		["commandType"]="action", ["commandName"]=Kitty.T("item", "HPMPpotionLv1"), ["icon"]="interface/icons/item_potion_030_002", ["enable"]=true,
		{["conditionType"]="playerHealth", ["max"]=60},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "ProtectMeleeItem"), ["icon"]="interface/icons/item_sweets_060_004", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="targetIsBoss", ["value"]=true},
		{["conditionType"]="playerHealth", ["max"]=40},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
},

{
	["info"]={["name"]=Kitty.T("name", "MatchlessCommand"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "ProtectMeleeItem"), ["icon"]="interface/icons/item_sweets_060_004", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="targetIsCaster", ["value"]=false},
		{["conditionType"]="playerHealth", ["max"]=60},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		["commandType"]="action", ["commandName"]=Kitty.T("item", "ProtectMagicItem2"), ["icon"]="interface/icons/item_sweets_070_004", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerHealth", ["max"]=60},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
	{
		-- Forest Cake
		["commandType"]="action", ["commandName"]=Kitty.T("item", "ProtectMagicItem1"), ["icon"]="interface/icons/item_sweets_040_003", ["enable"]=true,
		{["conditionType"]="isTargeted", ["value"]=true},
		{["conditionType"]="targetIsCaster", ["value"]=true},
		{["conditionType"]="playerHealth", ["max"]=60},
		{["conditionType"]="playerIsFearless", ["value"]=false},
	},
},

-- Target invincible?
{
	["info"]={["name"]=Kitty.T("name", "TargetMatchless"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="break", ["commandName"]=Kitty.T("message", "MatchlessStateMessage"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="targetIsFearless", ["value"]=true},
	},
},

-- W ExSkill
{
	["info"]={["name"]=Kitty.T("name", "ExtraUndefeatableKing"), ["class"]="proc", ["target"]="all"},
	{
		-- Invincible Champion
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Undefeatable King"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_001.dds", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6}},
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Undefeatable King"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="extra", ["commandName"]=Kitty.T("skill", "King Fairness"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerEffect",	{["effectType"]="original", ["name"]=Kitty.T("name", "Stun"), ["threshold"]=0.6},
											{["effectType"]="original", ["name"]=Kitty.T("skill", "Undefeatable King"), ["threshold"]=0.6}},
	},
},

-- M ExSkill
{
	["info"]={["name"]=Kitty.T("name", "ExtraMagicTricks"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Magic Tricks"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_006.dds", ["enable"]=true,
		{["conditionType"]="playerNonEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Magic Tricks"), ["threshold"]=0}},
	},
	{
		["commandType"]="extra", ["commandName"]=Kitty.T("skill", "Magic Tricks Wind"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Magic Tricks"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="extra", ["commandName"]=Kitty.T("skill", "Magic Tricks Flame"), ["icon"]="", ["enable"]=true,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Magic Tricks"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Lucky Chance"), ["icon"]="interface/icons/skill_panel_icons/sp_mag_002.dds", ["enable"]=false,
		{["conditionType"]="playerNonEffect",	{["name"]=Kitty.T("skill", "Lucky Chance"), ["effectType"]="original", ["threshold"]=0},
												{["name"]=Kitty.T("skill", "Magic Tricks"), ["effectType"]="original", ["threshold"]=0}},
	},
	{
		["commandType"]="extra", ["commandName"]=Kitty.T("skill", "Lucky Chance Flame"), ["icon"]="", ["enable"]=false,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lucky Chance"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="extra", ["commandName"]=Kitty.T("skill", "Lucky Chance Wind"), ["icon"]="", ["enable"]=false,
		{["conditionType"]="playerEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Lucky Chance"), ["threshold"]=0.6}},
	},
},

-- W (one-handed)
{
	["info"]={["name"]=Kitty.T("name", "WSingleHand"), ["class"]="proc", ["target"]="all"},
	{
		-- Lightning Speed
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Thunder"), ["icon"]="interface/icons/skill_war15-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Probing Attack"), ["icon"]="interface/icons/skill_war3-2", ["enable"]=true,
		{["conditionType"]="canCast", {["name"]=Kitty.T("skill", "Thunder"), ["threshold"]=0.6}},
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Open Flank"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
},

-- W (two-handed)
{
	["info"]={["name"]=Kitty.T("name", "WTwoHand"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=40, ["max"]=nil},
		{["conditionType"]="canCast", {["name"]=Kitty.T("skill", "Brash Ferocity Strike"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Tactical Attack"), ["icon"]="interface/icons/skill_war9-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Slash"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
},

-- WK (one-handed)
{
	["info"]={["name"]=Kitty.T("name", "WKSingleHand"), ["class"]="proc", ["target"]="all"},
	{
		-- Lightning Speed
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Thunder"), ["icon"]="interface/icons/skill_war15-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Probing Attack"), ["icon"]="interface/icons/skill_war3-2", ["enable"]=true,
		{["conditionType"]="canCast", {["name"]=Kitty.T("skill", "Thunder"), ["threshold"]=0.6}},
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Open Flank"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=40, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=70, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
	},
},

-- WK (two-handed)
{
	["info"]={["name"]=Kitty.T("name", "WKTwoHand"), ["class"]="proc", ["target"]="all"},
	{
		["commandType"]="suitskill", ["commandName"]=Kitty.T("skill", "Brash Ferocity Strike"), ["icon"]="interface/Icons/skill_panel_icons/sp_war_z21_001.dds", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Probing Attack"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Open Flank"), ["icon"]="interface/icons/skill_thi3-1.dds", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=40, ["max"]=nil},
		{["conditionType"]="canCast", {["name"]=Kitty.T("skill", "Brash Ferocity Strike"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Tactical Attack"), ["icon"]="interface/icons/skill_war9-1", ["enable"]=true,
		{["conditionType"]="targetEffect", {["effectType"]="original", ["name"]=Kitty.T("skill", "Slash"), ["threshold"]=0.6}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
		{["conditionType"]="playerTension", ["min"]=70, ["max"]=nil},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
		{["conditionType"]="targetNonEffect", {["effectType"]="original", ["name"]=Kitty.T("effect", "DisarmamentLv4"), ["threshold"]=4.0}},
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Slash"), ["icon"]="interface/icons/skill_war1-1", ["enable"]=true,
	},
	{
		["commandType"]="skill", ["commandName"]=Kitty.T("skill", "Disarmament"), ["icon"]="interface/icons/skill_kni12-1", ["enable"]=true,
	},
},
};
