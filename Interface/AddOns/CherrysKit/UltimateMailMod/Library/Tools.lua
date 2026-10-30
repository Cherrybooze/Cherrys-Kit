
-- ###########################
-- ##                       ##
-- ##  Miscellaneous Tools  ##
-- ##                       ##
-- ###########################

-- ### Locale Loader ###

-- Cherry's Kit: the addon lives in Interface/AddOns/CherrysKit/UltimateMailMod/ inside the kit.
UMMPath = (CherrysKit_Paths and CherrysKit_Paths.UltimateMailMod) or "Interface/Addons/UltimateMailMod/";
local LOCALE_PATH = UMMPath.."Locales/";
local Sol = LibStub("Sol");

local function LoadLUAFile(fileName)
  local func, err = loadfile(fileName);
  if err then
    return false, err;
  else
    dofile(fileName);
    return true;
  end
end

local locale = string.sub(GetLanguage():upper(), 1, 2);			-- release 4.0.8.2506
-- old function: GetLocation() loads the settings of the RoM Client instead of the selected RoM language
-- English first, so a missing string in a translation falls back to English
LoadLUAFile(LOCALE_PATH.."EN.lua");
if (locale ~= "EN") then
  LoadLUAFile(LOCALE_PATH..locale..".lua");
end

-- ### Miscellaneous Public Functions ###

function UMMPrompt(strMessage)
  local prefix = "|cff"..UMMColor.Header.."[|r|cff"..UMMColor.Medium..UMM_PROMPT.."|r|cff"..UMMColor.Header.."] |r";
  local msgColor = "|cff"..UMMColor.Bright;
  DEFAULT_CHAT_FRAME:AddMessage(prefix..msgColor..strMessage.."|r");
end

function UMMPrint(strMessage)
  local msgColor = "|cff"..UMMColor.Bright;
  DEFAULT_CHAT_FRAME:AddMessage(msgColor..strMessage.."|r");
end

-- Cherry's Kit: gold uses the game's grouping, as in the backpack: 1,234,567.
function UMMGroupDigits(digits)
  local head = string.len(digits) % 3;
  if (head == 0) then head = 3; end
  local result = string.sub(digits, 1, head);
  for i = head + 1, string.len(digits), 3 do
    result = result..","..string.sub(digits, i, i + 2);
  end
  return result;
end

function UMMFormatNumber(n)
  n = math.floor(tonumber(n) or 0);
  if (n < 0) then return "-"..UMMGroupDigits(string.format("%.0f", -n)); end
  return UMMGroupDigits(string.format("%.0f", n));
end

-- Global timing

UMMGlobalTimeout = 0;
UMMGlobalFailTimeout = 0;
UMMGlobalTimeoutCallFunction = nil;
UMMGlobalFailTimeoutCallFunction = nil;
UMMGlobalInboxLoadTimeout = 0;

-- 200ms seem to be stable for medium level hardware usage
UMM_GLOBAL_AUTOMATION_WAITTIME    = 0.2;					-- release 5.0.1.2553
-- 10 seconds to wait for automation fail is suitable
UMM_GLOBAL_AUTOMATION_WAITTIMEOUT = 10;
--125ms delete delay seems to be stable for medium level hardware usage
UMM_AUTOMATION_DELETE_WAITTIME    = 0.125;					-- release 5.0.1.2553

function UMMSetGlobalFailTimeout(callFunction)
  UMMGlobalFailTimeoutCallFunction = callFunction;
  UMMGlobalFailTimeout = UMM_GLOBAL_AUTOMATION_WAITTIMEOUT;
end

function UMMSetGlobalTimeout(callFunction, deleteTimer)
  UMMGlobalTimeoutCallFunction = callFunction;
  if (deleteTimer) then
    UMMGlobalTimeout = UMM_AUTOMATION_DELETE_WAITTIME;
  else
    UMMGlobalTimeout = UMM_GLOBAL_AUTOMATION_WAITTIME;
  end
  UMMSetGlobalFailTimeout(callFunction);
end

-- **************************************************************
-- Test to implement the GetType Function
-- **************************************************************
function UMMGetItemType(index, item)
  Sol.tooltip.ClearAllText(GameTooltip);
  GameTooltip:SetBagItem(GetBagItemInfo(index));
  -- GameTooltip:Hide();
  local lines = Sol.tooltip.ReadTooltip(GameTooltip);
  local result = UMMSearchInTooltip(item);
  return result;
end

function UMMSearchInTooltip(searchString)
  searchString = string.gsub(searchString, "-", "%%-");
  local lowerString = string.lower(searchString);
  local result;
  for i = 2, 40 do
    --Search for text in left sides
    result = getglobal("GameTooltipTextLeft"..i):GetText();
    if result ~= nil and getglobal("GameTooltipTextLeft"..i):IsVisible() then
      if string.find(string.lower(result), string.lower(searchString)) then
        return result;
      end
    end
    --Search for text in right sides
    result = getglobal("GameTooltipTextRight"..i):GetText();
    if result ~= nil and getglobal("GameTooltipTextRight"..i):IsVisible() then
      if string.find(string.lower(result), string.lower(searchString)) then
        return result;
      end
    end
  end
  result = "Item";
  return result;
end
