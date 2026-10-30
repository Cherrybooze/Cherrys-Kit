--[[
pbInfo - Includes/inc.Core.lua
	v0.60
	by p.b. a.k.a. novayuna
	released under the Creative Commons License By-Nc-Sa: http://creativecommons.org/licenses/by-nc-sa/3.0/
]]
-- Cherry's Kit: Reload UI runs this file again in the SAME Lua state. Keep the game's own functions
-- that pbInfo wrapped last time (pbInfo.Original), so a wrapper never wraps its own old copy.
local previous = pbInfo;
pbInfo = {
	Config = {Scripts = {}},
	Hooked = {},
	Locale = {},
	CharData = {Scripts = {}},
	MobDB = {Mobs = {}},
	PlayerDB = {Players = {}},
	Scripts = {},
	Settings = {},
	BloodBars = {Scripts = {}},
	CastingBar = {},
	CharacterFrame = {},
	Chat = {Scripts = {}},
	ChatFrame = {Scripts = {}},
	ChatLog = {Data = {Whispers = {}}, DB = {}, Scripts = {}},
	Tooltip = {Border = {}, Scripts = {}},
	QuestTracker = {Scripts = {}}
};
pbInfo.ours = (previous and previous.ours) or setmetatable({}, {__mode = "k"});
pbInfo.real = (previous and previous.real) or {};
-- The game's own function for key: current, unless current is one of our old wrappers.
function pbInfo.Original(key, current)
	if (current ~= nil and pbInfo.ours[current]) then
		return pbInfo.real[key];
	end;
	pbInfo.real[key] = current;
	return current;
end;
function pbInfo.MarkOurs(fn)
	pbInfo.ours[fn] = true;
	return fn;
end;
-- Cherry's Kit on/off switch (/ck): off = load nothing, every XML script returns at once.
pbInfo.Off = (CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("pbInfo")) or nil;
pbInfoCharData = pbInfoCharData or {};
pbInfo.Account = GetAccountName();
pbInfo.Realm = string.gsub(GetCurrentRealm(), "|c%w%w%w%w%w%w%w%w(.-)|r", "%1");
pbInfo.RealmName = pbInfo.Realm:match("%)%s(.-)$") or pbInfo.Realm;
pbInfo.Directory = (CherrysKit_Paths and CherrysKit_Paths.pbInfo) or "Interface/AddOns/pbInfo/";
pbInfo.Version = "v0.60-ck4";
pbInfo.MessageColor = {0.5, 0.7, 0.1};
pbInfo.MatDBitemCount = {};
pbInfo.ThousandsSeparatorFormats = {".", ","};
pbInfo.TimeStampFormats = {"%I:%M %p", "%I:%M:%S %p", "%H:%M", "%H:%M:%S"};
pbInfo.Languages = {"Default", "Dutch", "Hungarian", "Italian", "Lithuanian", "Korean", "Polish", "Portuguese", "Romanian", "Russian", "Spanish", "Swedish"};
pbInfo.Language = GetLanguage():upper();
if ((pbInfo.Language ~= "DE")
	and (pbInfo.Language ~= "FR")
	and (pbInfo.Language ~= "JP")
	and (pbInfo.Language ~= "TW")
	) then pbInfo.Language = "ENEU" end;
pbInfo.PlayerInfo = {};
pbInfo.Classes = {
	[GetSystemString("SYS_CLASSNAME_WARRIOR")] 		= {["color"] = "FF0000", ["index"] = 1},
	[GetSystemString("SYS_CLASSNAME_RANGER")]		= {["color"] = "A5D603", ["index"] = 2},
	[GetSystemString("SYS_CLASSNAME_THIEF")] 		= {["color"] = "00D6C5", ["index"] = 3},
	[GetSystemString("SYS_CLASSNAME_MAGE")] 		= {["color"] = "FFC000", ["index"] = 4},
	[GetSystemString("SYS_CLASSNAME_AUGUR")] 		= {["color"] = "288CEC", ["index"] = 5},
	[GetSystemString("SYS_CLASSNAME_KNIGHT")] 		= {["color"] = "FFFF48", ["index"] = 6},
	[GetSystemString("SYS_CLASSNAME_WARDEN")]		= {["color"] = "C14AC1", ["index"] = 7},
	[GetSystemString("SYS_CLASSNAME_RUNEDANCER")]	= {["color"] = "C14AC1", ["index"] = 7},
	[GetSystemString("SYS_CLASSNAME_DRUID")] 		= {["color"] = "71D171", ["index"] = 8},
	[GetSystemString("SYS_CLASSNAME_PSYRON")] 		= {["color"] = "0000CD", ["index"] = 9},  -- Champion
	[GetSystemString("SYS_CLASSNAME_HARPSYN")] 		= {["color"] = "800080", ["index"] = 10},  -- Warlock
	[GetSystemString("SYS_CLASSNAME_GM")] 			= {["color"] = "FFFFFF", ["index"] = -1}
};
pbInfo.ChatFrame.FilterStrings = {CHAT_ZONE_GET, CHAT_PARTY_GET, CHAT_GUILD_GET, CHAT_RAID_GET, CHAT_YELL_GET};

if (pbInfo.Off) then
	-- switched off in the Cherry's Kit hub: nothing else loads
elseif (type(loadfile(pbInfo.Directory .. "Libs/lib.pbTools.lua")) == "function") then
	dofile(pbInfo.Directory .. "Libs/lib.pbTools.lua");
	pbLoadFile(pbInfo.Directory .. "Libs/lib.TableTools.lua");
	pbLoadFile(pbInfo.Directory .. "Libs/lib.ConvertColors.lua");
	pbLoadFile(pbInfo.Directory .. "Locales/lang." .. pbInfo.Language .. ".lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.Configuration.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.BloodBars.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.Chat.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.ChatFrame.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.ChatLog.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.MobDB.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.PlayerDB.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.QuestTracker.lua");
	pbLoadFile(pbInfo.Directory .. "Includes/inc.Tooltip.lua");
	pbInfo.MobDB.Mobs = {};
	pbInfo.MatDB = TableTools.loadTable(pbInfo.Directory .. "Locales/db.mats.lua");
else
	DEFAULT_CHAT_FRAME:AddMessage("[|cffFFFFFFpbInfo|r] |cFFFF0000Error while loading the plugin! Please check the folder structure!", unpack(pbInfo.MessageColor));
end;
