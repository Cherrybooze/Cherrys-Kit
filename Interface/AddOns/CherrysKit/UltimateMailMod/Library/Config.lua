
-- ##  Global Configuration  ##

UMMConfig = nil;

-- These belong to the account-wide UMMConfig, not a character's save file.
UMM_GOLD_PRESET_MAX = 999999999;
UMM_GOLD_PRESET_DEFAULTS = {100000, 1000000};
UMM_RECIPIENT_HISTORY_MAX = 20;

function UMMGoldAmount(value)
  if (type(value) == "string" and not string.match(value, "^%s*%d+%s*$")) then return nil; end
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
    UMMConfig.RecipientHistory = RecipientHistory(UMMConfig.RecipientHistory);
    if (UMMConfig.NewMail == nil) then
      UMMConfig.NewMail = {};
    end
    if (UMMConfig.Characters == nil) then
      UMMConfig.Characters = {};
    end
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

  History = function(self)
    return type(UMMConfig) == "table" and type(UMMConfig.RecipientHistory) == "table" and UMMConfig.RecipientHistory or {};
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
    UMMConfig.RecipientHistory = RecipientHistory(history, recipient);
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
    end
    self:Save();
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
