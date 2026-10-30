"""Lua 5.1 runtime with just enough of the RoM client stubbed to load the addon files."""
import os

from lupa.lua51 import LuaRuntime

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Interface")

LOGIN_FILES = [
    "loginxml/frames/login.lua",
    "loginxml/frames/login.account.lua",
    "loginxml/frames/login.server.lua",
    "loginxml/frames/login.charselect.lua",
    "loginxml/frames/login.settings.lua",
    "loginxml/frames/CampNext_Login.lua",
    "loginxml/frames/compat_stock.lua",
]

# Login screen client: three characters on the server, in slot order
LOGIN_STUBS = r"""
chars = { -- name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel
  {"Aa", 0, 10, "Warrior", 0, "", "Zone", nil, 0},
  {"Bb", 0, 90, "Mage", 0, "", "Zone", nil, 0},
  {"Cc", 0, 50, "Priest", 0, "", "Zone", nil, 0},
}
function GetNumCharacters() return #chars end
function GetCharacterInfo(i) local c = chars[i] if c then return unpack(c, 1, 9) end end
function GetMaxCharacterCreate() return 8 end
function SelectCharacter(i) login.charselect.UPDATE_SELECTED_CHARACTER(i) end
entered = {}
function EnterWorld(channel) table.insert(entered, login.charselect.selected) end
function GetServerName() return "Server" end
accepted = 0
function AcceptUserAgreement() accepted = accepted + 1 end
function IsHideLoginUI() return true end
function IsCtrlKeyDown() return false end
function TEXT(key) return key end
local function widget()
  return setmetatable({}, {__index = function() return function() end end})
end
LoginAccountFrame = widget()
local function shown()
  return {shown = true, Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end}
end
LoginAccount = shown()
LoginFrame_debug = shown()
LoginDebugFrame = shown()
for i = 1, 14 do
  _G["LoginServerFrame_options_" .. i] = {
    SetID = function(self, id) self.id = id end, GetID = function(self) return self.id end,
    SetText = function(self, text) self.text = text end,
    SetChecked = function(self, on) self.checked = on end, IsChecked = function(self) return self.checked end,
    Show = function() end, Hide = function(self) self.hidden = true end,
  }
end
LoginAccountButton = {SetText = function(self, text) self.text = text end, Show = function() end, Hide = function() end}
LoginDialogFrame = {visible = false, IsVisible = function(self) return self.visible end}
LoginCharSelectFrame_delete = widget()
scrolled = {}
LoginCharSelectFrame_chars = {scrollTo = function(_, pos) table.insert(scrolled, pos) end, update = function() end}
LoginServerFrame_list = {scrollTo = function(_, pos) table.insert(scrolled, pos) end, update = function() end}
"""

# In game client with the LogNextChar bar widgets
GAME_STUBS = r"""
chat = {}
DEFAULT_CHAT_FRAME = {AddMessage = function(_, msg) table.insert(chat, msg) end}
SlashCmdList = {}
function SaveVariables() end
logouts = 0
function CampOutStart() logouts = logouts + 1 end
shift = false
function IsShiftKeyDown() return shift end
tip = {}
GameTooltip = {
  SetOwner = function() tip = {} end,
  SetText = function(_, text) table.insert(tip, text) end,
  AddLine = function(_, text) table.insert(tip, text) end,
  Show = function() end, Hide = function() end,
}
function GetUIScale() return 1 end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
local function shown()
  return {shown = true, Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
    IsVisible = function(self) return self.shown end}
end
MinimapViewFrame = {GetPos = function() return 1000, 20 end, GetWidth = function() return 170 end, GetHeight = function() return 170 end}
LogNextCharFrame = shown()
LogNextCharFrame.shown = false
LogNextCharFrameLock = {SetText = function(self, text) self.text = text end}
LogNextCharFrameShow = {SetChecked = function(self, on) self.checked = on end}
LogNextCharBar = {x = 500, y = 300, shown = true,
  GetWidth = function() return 36 end, GetHeight = function() return 74 end,
  ClearAllAnchors = function() end,
  SetAnchor = function(self, point, relativePoint, relativeTo, x, y)
    self.anchor = {point, x, y, relativeTo, relativePoint}
  end,
  GetPos = function(self) return self.x, self.y end,
  StartMoving = function(self) self.moving = true end,
  StopMovingOrSizing = function(self) self.moving = false end,
  Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
  RegisterEvent = function() end,
}
local function button(name)
  local glow = {SetTexture = function(self, path) self.path = path end, SetAlpha = function(self, a) self.alpha = a end}
  _G[name] = {GetName = function() return name end, GetHighlightTexture = function() return glow end,
    SetAlpha = function(self, a) self.alpha = a end, glow = glow}
  _G[name .. "Icon"] = {SetTexture = function(self, path) self.path = path end}
  _G[name .. "Letters"] = {SetText = function(self, text) self.text = text end}
end
button("LogNextCharBarPrev")
button("LogNextCharBarNext")
"""


def run_file(lua, relative):
    with open(os.path.join(ROOT, relative), encoding="latin-1") as handle:
        lua.execute(handle.read())


def login_screen():
    lua = LuaRuntime()
    lua.execute(LOGIN_STUBS)
    for relative in LOGIN_FILES:
        run_file(lua, relative)
    lua.execute('login.charselect.classes = {Warrior = "WARRIOR", Mage = "MAGE", Priest = "AUGUR"}')
    return lua


def in_game(before=""):
    lua = LuaRuntime()
    lua.execute(GAME_STUBS)
    lua.execute(before)
    run_file(lua, "AddOns/LogNextChar/LogNextChar.lua")
    lua.execute("LogNextChar.OnLoad(LogNextCharBar)")
    return lua


def lua_list(table):
    return [table[i] for i in range(1, len(table) + 1)]
