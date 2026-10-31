-- In-game half of Cherry's Loginxml. The login screen cannot write files, so its settings toggles
-- (loginxml, login.settings.lua) are registered here and the game writes them to SaveVariables.lua
-- when you log out or quit. This also says so when the login screen itself is missing or out of date.
CherrysLoginxml = CherrysLoginxml or {}
local me = CherrysLoginxml

me.version = "1.2.2"
me.FOLDER = "CherrysLoginxml"

if SaveVariables then
  SaveVariables("CherrysLoginxml_Settings")
end

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Cherry's Loginxml:|r " .. text)
  end
end

local function isOff()
  return CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled(me.FOLDER)
end

-- Loading saved variables replaces CherrysLoginxml_Settings with the copy on disk, so
-- what was changed on the login screen this session goes back over it.
local function keepLoginChanges()
  local live = CherrysLoginxml_Live
  if type(live) ~= "table" then
    return
  end
  if live.reset or type(CherrysLoginxml_Settings) ~= "table" then
    CherrysLoginxml_Settings = {}
  end
  for key, value in pairs(live.values or {}) do
    CherrysLoginxml_Settings[key] = value
  end
end

-- A package can only fill Interface\AddOns, and the game reads its login screen from Interface\loginxml, so
-- Install login screen.bat copies it there. Login screen and addons share one Lua state, so this can see it.
function me.CheckLoginScreen()
  local screen = type(login) == "table" and login.version
  if screen == me.version or me.told then
    return
  end
  me.told = true
  local run = "close the game and double-click Interface\\AddOns\\CherrysKit\\CherrysLoginxmlHook\\Install login screen.bat."
  if screen then
    chat("the login screen is version " .. tostring(screen) .. " and this addon is " .. me.version .. ": " .. run)
  else
    chat("the login screen isn't in place yet: " .. run)
  end
end

function me.OnEvent(event)
  if event ~= "VARIABLES_LOADED" then
    return
  end
  if CherrysKit and CherrysKit.Register then
    CherrysKit.Register({
      folder = me.FOLDER,
      title = "Cherry's Loginxml",
      version = me.version,
      installed = function()
        return true
      end,
      open = function()
        chat("its settings are the toggle buttons on the server screen, when you log in.")
        return true
      end,
    })
  end
  if isOff() then
    return
  end
  keepLoginChanges()
  me.CheckLoginScreen()
end
