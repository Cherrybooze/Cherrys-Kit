-- Cherry's Grid: Mouse 4 outside Grid. A check box on the Clicks page, off until it's ticked: until then
-- nothing here touches the game. Grid's own frames use Mouse 4 as one of their click buttons (Clicks.lua)
-- with or without this.
--
-- The client reads four mouse buttons. The fourth reaches Lua as the key "XBUTTON", in the OnMouseDown
-- of the frame under the cursor, so Mouse 4 works over windows and buttons. Over the 3D world the press
-- lands on a frame Lua has no handle on, and Mouse 5 is never read at all (map that one to a key in the
-- mouse's own software). Real key bindings only react to the keyboard, so "MOUSE4" is shown and saved
-- in the game's Key Bindings window by wrapping its calls, and this runs what it's bound to.
--
-- A frame's script is the function the client keeps in the frame's table under SCRIPT, so one that's
-- already there can be wrapped. A frame without one needs SetScripts once: that tells the client to
-- run it.

local G = CherrysGrid
local M = {}
G.Mouse = M

M.KEYS = { "MOUSE4", "CTRL+MOUSE4", "SHIFT+MOUSE4", "ALT+MOUSE4" }
M.KEY_TITLES = { "Mouse 4", "Ctrl + Mouse 4", "Shift + Mouse 4", "Alt + Mouse 4" }
M.hooked = {}

local CLIENT_KEY = "XBUTTON"
local SCRIPT = "__uiLuaOnMouseDown__"
local ACTIONS = CherrysGrid_MouseActions or {}
-- Grid's own frames answer Mouse 4 through their click bindings
local OWN_FRAMES = "^CGrid_Unit%d+$"

-- Reload UI re-runs the addon in the same Lua state, and the wrapped calls with it, so these outlive G.
CherrysGrid_MouseCalls = CherrysGrid_MouseCalls or { native = {}, wrappers = {} }
local CALLS = CherrysGrid_MouseCalls

local IS_KEY = {}
for _, key in ipairs(M.KEYS) do
  IS_KEY[key] = true
end

-- Across the account, as the game's own key bindings are: { on = true, binds = { key = a binding's name, or a slash command } }
local function settings()
  local d = G.DB()
  if type(d.mouse4) ~= "table" then
    d.mouse4 = {}
  end
  if type(d.mouse4.binds) ~= "table" then
    d.mouse4.binds = {}
  end
  return d.mouse4
end

local function binds()
  return settings().binds
end

function M.IsOn()
  return G.IsOn() and type(CherrysGrid_DB) == "table" and type(CherrysGrid_DB.mouse4) == "table"
    and CherrysGrid_DB.mouse4.on == true
end

local function isCommand(action)
  return string.sub(action, 1, 1) == "/"
end

---------------------------------------------------------------------------
-- Running what Mouse 4 is bound to
---------------------------------------------------------------------------

local function runBinding(action)
  local entry = ACTIONS[action]
  if not entry then
    G.Print(tostring(action) .. " is not a key binding Grid knows how to run.")
    return
  end
  entry.run = entry.run or assert(loadstring(entry.code))
  -- A press and a release in one go: a frame can hide while the button is held, and then its release never comes.
  keystate = "down"
  entry.run()
  if entry.hold then
    keystate = "up"
    entry.run()
  end
end

function M.Run(action)
  if not action then
    return
  end
  local ok, why
  if isCommand(action) then
    ok, why = pcall(ExecuteMacroLine, action)
  else
    ok, why = pcall(runBinding, action)
  end
  if not ok then
    G.Print("Mouse 4 could not run " .. tostring(action) .. ": " .. tostring(why))
  end
end

local function heldKey()
  if IsCtrlKeyDown and IsCtrlKeyDown() then
    return "CTRL+MOUSE4"
  elseif IsShiftKeyDown and IsShiftKeyDown() then
    return "SHIFT+MOUSE4"
  elseif IsAltKeyDown and IsAltKeyDown() then
    return "ALT+MOUSE4"
  end
  return "MOUSE4"
end

local function frameName(frame)
  local ok, name = pcall(function() return frame:GetName() end)
  return ok and name or "a window"
end

function M.Press(frame)
  -- Unticked this session: a frame keeps its wrapper until Reload UI, and this does nothing
  if not M.IsOn() then
    return
  end
  M.seenOver = frameName(frame)
  local window = rawget(_G, "KeyDefineFrame")
  local button = window and window.nowButton
  if button and window:IsVisible() then
    -- The Key Bindings window is waiting for a key: this is one, as in its OnKeyUp
    window.nowButton = nil
    KeyDefineFrame_ChangeKey(button, heldKey())
  else
    M.Run(binds()[heldKey()])
  end
  if G.Options then
    G.Options.Draw()
  end
end

---------------------------------------------------------------------------
-- Catching it on frames
---------------------------------------------------------------------------

local function press(frame)
  local ok, why = pcall(M.Press, frame)
  if not ok then
    G.Print("Mouse 4: " .. tostring(why))
  end
end

local function plainScript(this, key)
  if key == CLIENT_KEY then
    press(this)
  end
end

local function setterOf(frame)
  return frame.SetScripts
end

local function hookFrame(frame)
  if M.hooked[frame] then
    return
  end
  local old = frame[SCRIPT]
  if type(old) == "function" then
    frame[SCRIPT] = function(this, key)
      if key == CLIENT_KEY then
        press(this)
      end
      return old(this, key)
    end
  else
    if not pcall(frame.SetScripts, frame, "OnMouseDown", "") then
      return
    end
    frame[SCRIPT] = plainScript
  end
  M.hooked[frame] = true
end

-- Every frame with a name. SetScripts adds to _G for a moment, so they're listed before any is touched.
local function hookAll()
  local frames = {}
  for name, value in pairs(_G) do
    if type(value) == "table" and not (type(name) == "string" and string.find(name, OWN_FRAMES)) then
      local ok, set = pcall(setterOf, value)
      if ok and type(set) == "function" then
        frames[#frames + 1] = value
      end
    end
  end
  for _, frame in ipairs(frames) do
    hookFrame(frame)
  end
end

---------------------------------------------------------------------------
-- The game's Key Bindings window. It calls these through their globals.
---------------------------------------------------------------------------

local function isBlank(key)
  return not key or key == "" or key == KDF_UNDEFINE
end

local function withMouseKeys(name, key1, key2)
  for _, key in ipairs(M.KEYS) do
    if binds()[key] == name then
      if isBlank(key1) then
        key1 = key
      elseif isBlank(key2) then
        key2 = key
      end
    end
  end
  return key1, key2
end

local WRAPS = {}

WRAPS.GetBindings = function(native)
  return function(i)
    local header, name, key1, key2 = native(i)
    key1, key2 = withMouseKeys(name, key1, key2)
    return header, name, key1, key2
  end
end

WRAPS.GetBindingKey = function(native)
  return function(name)
    return withMouseKeys(name, native(name))
  end
end

WRAPS.SetBindingKey = function(native)
  return function(name, key1, key2)
    local saved = binds()
    for key, action in pairs(saved) do
      if action == name then
        saved[key] = nil
      end
    end
    -- The client can't hold a key it has no code for, so those slots stay empty there
    if IS_KEY[key1] then
      saved[key1] = name
      key1 = KDF_UNDEFINE or ""
    end
    if IS_KEY[key2] then
      saved[key2] = name
      key2 = KDF_UNDEFINE or ""
    end
    return native(name, key1, key2)
  end
end

WRAPS.DefaultBindingKey = function(native)
  return function()
    local saved = binds()
    for key, action in pairs(saved) do
      if not isCommand(action) then
        saved[key] = nil
      end
    end
    return native()
  end
end

local function wrapGameCalls()
  for name, make in pairs(WRAPS) do
    local current = rawget(_G, name)
    if type(current) == "function" then
      if current ~= CALLS.wrappers[name] then
        CALLS.native[name] = current
      end
      CALLS.wrappers[name] = make(CALLS.native[name])
      _G[name] = CALLS.wrappers[name]
    end
  end
end

local function restoreGameCalls()
  for name in pairs(WRAPS) do
    if CALLS.wrappers[name] and rawget(_G, name) == CALLS.wrappers[name] then
      _G[name] = CALLS.native[name]
    end
  end
end
-- What the last session wrapped goes back: whether it's on is only known once the saved settings are in
restoreGameCalls()

---------------------------------------------------------------------------
-- From Core (once started, and after each loading screen) and the Clicks page
---------------------------------------------------------------------------

function M.Apply()
  if M.IsOn() then
    wrapGameCalls()
    hookAll()
  end
end

function M.SetOn(on)
  settings().on = on and true or nil
  if on then
    M.Apply()
  else
    restoreGameCalls()
    G.Print("Mouse 4 is no longer a game keybind. Reload UI to take it off the windows too.")
  end
end

-- What a row of the Clicks page shows
function M.Describe(key)
  local action = binds()[key]
  if not action then
    return ""
  end
  if isCommand(action) or not TEXT then
    return action
  end
  return TEXT("BINDING_NAME_" .. action)
end

function M.SetCommand(key, text)
  text = string.gsub(text or "", "^%s*(.-)%s*$", "%1")
  if text == "" then
    binds()[key] = nil
  elseif isCommand(text) then
    binds()[key] = text
  elseif text ~= M.Describe(key) then
    G.Print("type a slash command starting with /, or bind a game action in Key Bindings.")
  end
end

function M.Status()
  if M.seenOver then
    return "|cff60ff60Mouse 4 last seen over " .. tostring(M.seenOver) .. ".|r"
  end
  return "Press Mouse 4 over this window to check the game sees it."
end

function M.OpenKeyBindings()
  if rawget(_G, "KeyDefineFrame") and ShowUIPanel then
    ShowUIPanel(KeyDefineFrame)
  end
end
