
-- ##  Global Configuration  ##

UMMConfig = nil;

-- These belong to the account-wide UMMConfig, not a character's save file.
UMM_GOLD_PRESET_MAX = 999999999;
UMM_GOLD_PRESET_DEFAULTS = {100000, 1000000};
UMM_RECIPIENT_HISTORY_MAX = 20;

function UMMGoldAmount(value)
  if (type(value) == "string") then
    value = string.gsub(value, ",", "");   -- typed or shown as 1,234,567
    if (not string.match(value, "^%s*%d+%s*$")) then return nil; end
  end
  local amount = tonumber(value);
  if (amount and amount == amount and amount >= 1 and amount <= UMM_GOLD_PRESET_MAX and amount == math.floor(amount)) then
    return amount;
  end
end

local function RecipientName(value)
  if (type(value) ~= "string") then return nil; end
  value = string.match(value, "^%s*(.-)%s*$");
  if (value ~= "" and #value <= 255 and not string.find(value, "[%c|]")) then return value; end
end

local function RecipientHistory(history, latest)
  local result, seen = {}, {};
  local function add(value)
    local name = RecipientName(value);
    local key = name and string.lower(name);
    if (name and not seen[key]) then
      seen[key] = true;
      result[#result + 1] = name;
    end
  end
  add(latest);
  if (type(history) == "table") then
    for _, name in ipairs(history) do
      if (#result >= UMM_RECIPIENT_HISTORY_MAX) then break; end
      add(name);
    end
  end
  return result;
end

-- The server this character plays on, for the names you mailed: a character name exists on its own
-- server only. The login screen leaves it in LOGCHAR_SERVER for a client that can't say in game
-- (as Global Bank reads it). "?" while neither knows.
-- A server name without its colour codes and the spaces around it.
local function CleanServerName(name)
  name = string.gsub(string.gsub(name, "|c%x%x%x%x%x%x%x%x", ""), "|r", "");
  return string.match(name, "^%s*(.-)%s*$") or "";
end

function UMMServerKey()
  local name = nil;
  if (type(GetServerName) == "function") then
    local ok, value = pcall(GetServerName);
    if (ok) then name = value; end
  end
  if (type(name) ~= "string" or name == "") then name = LOGCHAR_SERVER; end
  if (type(name) ~= "string") then return "?"; end
  name = CleanServerName(name);
  if (name == "") then return "?"; end
  return name;
end

-- Names as a set of lower-case keys.
local function NameSet(list, into)
  into = into or {};
  if (type(list) == "table") then
    for _, name in ipairs(list) do
      if (type(name) == "string") then into[string.lower(name)] = true; end
    end
  end
  return into;
end

-- Adds name to the sorted list unless it is there; true when added.
local function AddSorted(list, name)
  for _, have in ipairs(list) do
    if (have == name) then return false; end
  end
  table.insert(list, name);
  table.sort(list);
  return true;
end

local function RefreshShortcuts()
  if (type(UMMRefreshMailShortcuts) == "function") then UMMRefreshMailShortcuts(); end
end

UMMSettings = {
  
  Save = function(self)
    SaveVariables("UMMConfig");
  end;
  
  Set = function(self, entry, value)
    if (type(UMMConfig) ~= "table" or type(UMMConfig.Settings) ~= "table") then
      self:Init();
    end
    UMMConfig.Settings[entry] = value;
    self:Save();
    if (entry == "MailShortcuts" or entry == "GoldPreset1" or entry == "GoldPreset2") then RefreshShortcuts(); end
  end;
  
  Get = function(self, entry)
    if (type(UMMConfig) == "table" and type(UMMConfig.Settings) == "table") then
      return UMMConfig.Settings[entry]; -- explicit false is a saved choice
    end
  end;
  
  Init = function(self)
    if (type(UMMConfig) ~= "table") then
      UMMConfig = {};
    end
    if (type(UMMConfig.Settings) ~= "table") then
      UMMConfig.Settings = {};
      self:Set("AudioWarning", true);
      self:Set("DeleteDelay", 1.0);
      self:Set("CheckTooltipDisplay", false);
      self:Set("CheckTakeDeleteEmpty", true);
    end
    if (type(UMMConfig.Settings.MailShortcuts) ~= "boolean") then UMMConfig.Settings.MailShortcuts = true; end
    for i = 1, 2 do
      local key = "GoldPreset"..i;
      UMMConfig.Settings[key] = UMMGoldAmount(UMMConfig.Settings[key]) or UMM_GOLD_PRESET_DEFAULTS[i];
    end
    -- names you mailed, one list per server (RecentByServer[server] = names, newest first)
    local byServer = {};
    if (type(UMMConfig.RecentByServer) == "table") then
      for server, names in pairs(UMMConfig.RecentByServer) do
        if (type(server) == "string" and server ~= "") then
          names = RecipientHistory(names);
          if (#names > 0) then byServer[server] = names; end
        end
      end
    end
    UMMConfig.RecentByServer = byServer;
    -- the one list of every server from before 7.0.1-ck14: the first server that asks takes it over
    if (UMMConfig.RecipientHistory ~= nil) then
      local old = RecipientHistory(UMMConfig.RecipientHistory);
      UMMConfig.RecipientHistory = (#old > 0) and old or nil;
    end
    if (UMMConfig.NewMail == nil) then
      UMMConfig.NewMail = {};
    end
    if (UMMConfig.Characters == nil) then
      UMMConfig.Characters = {};
    end
    -- your characters per server (7.0.1-ck17): Characters above is every server's, kept as it was
    if (type(UMMConfig.CharactersByServer) ~= "table") then UMMConfig.CharactersByServer = {}; end
    if (type(UMMConfig.RosterByServer) ~= "table") then UMMConfig.RosterByServer = {}; end
    self:Save();
    RefreshShortcuts();
  end;

  ShortcutsEnabled = function(self)
    return self:Get("MailShortcuts") ~= false;
  end;

  GoldPreset = function(self, index)
    if (index ~= 1 and index ~= 2) then return nil; end
    return UMMGoldAmount(self:Get("GoldPreset"..index)) or UMM_GOLD_PRESET_DEFAULTS[index];
  end;

  SetGoldPresets = function(self, first, second)
    first, second = UMMGoldAmount(first), UMMGoldAmount(second);
    if (not first or not second) then return false; end
    if (type(UMMConfig) ~= "table" or type(UMMConfig.Settings) ~= "table") then self:Init(); end
    UMMConfig.Settings.GoldPreset1, UMMConfig.Settings.GoldPreset2 = first, second;
    self:Save();
    RefreshShortcuts();
    return true;
  end;

  -- The names mailed from this server, newest first (at most 20), without the names of your
  -- characters on other servers (see SavedHistory and OwnElsewhere).
  History = function(self)
    local names = self:SavedHistory();
    local elsewhere = self:OwnElsewhere();
    if (not elsewhere) then return names; end
    local kept = nil;
    for i, name in ipairs(names) do
      if (elsewhere[string.lower(name)]) then
        if (not kept) then
          kept = {};
          for j = 1, i - 1 do kept[j] = names[j]; end
        end
      elseif (kept) then
        kept[#kept + 1] = name;
      end
    end
    return kept or names;
  end;

  -- Your characters on this server: the login screen's list (LOGCHAR_ROSTER, loginxml) once this
  -- server's was seen, plus every character played here with UMM. Until then the account-wide
  -- Characters list (every server's names) fills in, less the names known to be yours on another
  -- server only.
  OwnCharacters = function(self)
    if (type(UMMConfig) ~= "table") then return {}; end
    local legacy = type(UMMConfig.Characters) == "table" and UMMConfig.Characters or {};
    local server = UMMServerKey();
    if (server == "?") then return legacy; end
    local byServer, rosters = UMMConfig.CharactersByServer, UMMConfig.RosterByServer;
    local names = type(byServer) == "table" and byServer[server] or nil;
    if (type(names) ~= "table") then names = {}; end
    if (type(rosters) == "table" and rosters[server]) then return names; end
    local result, seen = {}, NameSet(names);
    for _, name in ipairs(names) do result[#result + 1] = name; end
    local elsewhere = self:OwnElsewhere(true) or {};
    for _, name in ipairs(legacy) do
      local key = type(name) == "string" and string.lower(name);
      if (key and not seen[key] and not elsewhere[key]) then
        seen[key] = true;
        result[#result + 1] = name;
      end
    end
    table.sort(result);
    return result;
  end;

  -- Lower-case names of your characters on other servers that are not yours here, or nil while
  -- this server's full list is unknown (no login screen list seen yet): a Recent name that is one
  -- of them was mailed from another server (the one list of every server before 7.0.1-ck14).
  -- anyList: also while this server's list is not complete (for OwnCharacters' fill-in).
  OwnElsewhere = function(self, anyList)
    if (type(UMMConfig) ~= "table") then return nil; end
    local server = UMMServerKey();
    local rosters, byServer = UMMConfig.RosterByServer, UMMConfig.CharactersByServer;
    if (server == "?" or type(byServer) ~= "table") then return nil; end
    if (not anyList and (type(rosters) ~= "table" or not rosters[server])) then return nil; end
    local here = NameSet(byServer[server]);
    local result, any = {}, false;
    for other, names in pairs(byServer) do
      if (other ~= server and type(names) == "table") then
        for _, name in ipairs(names) do
          local key = type(name) == "string" and string.lower(name);
          if (key and not here[key]) then result[key] = true; any = true; end
        end
      end
    end
    return any and result or nil;
  end;

  -- The names mailed from this server as saved, newest first.
  SavedHistory = function(self)
    if (type(UMMConfig) ~= "table") then return {}; end
    local server = UMMServerKey();
    local byServer = UMMConfig.RecentByServer;
    local names = type(byServer) == "table" and byServer[server] or nil;
    if (type(names) == "table") then return names; end
    if (type(UMMConfig.RecipientHistory) == "table") then
      if (server == "?") then return UMMConfig.RecipientHistory; end
      -- the list kept for every server before: it stays with the first server known
      if (type(byServer) ~= "table") then byServer = {}; UMMConfig.RecentByServer = byServer; end
      byServer[server] = RecipientHistory(UMMConfig.RecipientHistory);
      UMMConfig.RecipientHistory = nil;
      self:Save();
      return byServer[server];
    end
    return {};
  end;

  LastRecipient = function(self)
    return self:History()[1];
  end;

  RememberRecipient = function(self, recipient)
    recipient = RecipientName(recipient);
    if (not recipient) then return; end
    if (type(UMMConfig) ~= "table") then self:Init(); end
    local history = self:History();
    if (history[1] == recipient) then return; end
    if (type(UMMConfig.RecentByServer) ~= "table") then UMMConfig.RecentByServer = {}; end
    UMMConfig.RecentByServer[UMMServerKey()] = RecipientHistory(history, recipient);
    self:Save();
    RefreshShortcuts();
  end;

  CheckCharacter = function(self)
    if (UMMConfig == nil) then
      self:Init();
    end
    local name = UnitName("player");
    if (name ~= nil and name ~= "") then
      local found = nil;
      for index = 1, table.getn(UMMConfig.Characters) do
        if (UMMConfig.Characters[index] == name) then
          found = true;
          break;
        end
      end
      if (not found) then
        table.insert(UMMConfig.Characters, name);
        table.sort(UMMConfig.Characters);
      end
      self:RecordServerCharacters(name);
    end
    self:Save();
  end;

  -- This server's characters: the one playing, and the login screen's list of this account on
  -- this server when loginxml left it (LOGCHAR_ROSTER with LOGCHAR_SERVER). The roster replaces the
  -- server's list, so deleted or moved characters drop out.
  RecordServerCharacters = function(self, name)
    local server = UMMServerKey();
    if (server == "?") then return; end
    if (type(UMMConfig.CharactersByServer) ~= "table") then UMMConfig.CharactersByServer = {}; end
    if (type(UMMConfig.RosterByServer) ~= "table") then UMMConfig.RosterByServer = {}; end
    local list = UMMConfig.CharactersByServer[server];
    if (type(list) ~= "table") then list = {}; end
    local roster, rosterServer = rawget(_G, "LOGCHAR_ROSTER"), rawget(_G, "LOGCHAR_SERVER");
    if (type(roster) == "table" and type(rosterServer) == "string"
        and CleanServerName(rosterServer) == server) then
      local fromRoster = {};
      for _, who in pairs(roster) do
        who = RecipientName(who);
        if (who) then AddSorted(fromRoster, who); end
      end
      if (#fromRoster > 0) then
        list = fromRoster;
        UMMConfig.RosterByServer[server] = true;
      end
    end
    if (name) then AddSorted(list, name); end
    UMMConfig.CharactersByServer[server] = list;
  end;

  -- "Forget own chars": this server's list starts again from the character playing.
  ForgetCharacters = function(self)
    if (type(UMMConfig) ~= "table") then self:Init(); end
    UMMConfig.Characters = {};
    local server = UMMServerKey();
    if (type(UMMConfig.CharactersByServer) == "table") then UMMConfig.CharactersByServer[server] = nil; end
    if (type(UMMConfig.RosterByServer) == "table") then UMMConfig.RosterByServer[server] = nil; end
    self:CheckCharacter();
  end;
  
  NewMail = function(self, number)
    if (number == nil) then
      local name = UnitName("player");
      if (name ~= nil and name ~= "") then
        return UMMConfig.NewMail[name];
      else
        return 0;
      end
    else
      if (UMMConfig == nil) then
        self:Init();
      end
      local name = UnitName("player");
      if (name ~= nil and name ~= "") then
        UMMConfig.NewMail[name] = number;
      end
      self:Save();
    end
  end;
  
  NoNewMail = function(self)
    if (UMMConfig == nil) then
      self:Init();
    end
    local name = UnitName("player");
    if (name ~= nil and name ~= "") then
      UMMConfig.NewMail[name] = 0;
    end
    self:Save();
  end;
  
};
