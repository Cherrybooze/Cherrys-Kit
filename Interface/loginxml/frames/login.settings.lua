-- On/off settings from config.lua as toggles, to the right of the server list.
-- A click applies at once and is kept in CherrysLoginxml_Settings, which wins over
-- config.lua. The game writes that table to SaveVariables.lua when you log out or quit
-- (the CherrysLoginxml addon in Interface\AddOns registers it). The game only loads that
-- file on entering the world, so the first login screen after a restart reads it itself.
-- Lua cannot find the Documents folder: "Install login screen.bat" leaves the path in
-- savedpath.lua.
local me = {
  toggles = {
    {key = 'character_login_single', label = 'Log in if only one character'},
    {key = 'character_login_first', label = 'Log in the first character'},
    {key = 'character_nologin_ctrl', label = 'Ctrl stops at character select'},
    {key = 'character_single_click', label = 'One click logs in a character'},
    {key = 'character_sort', label = 'Sort characters by level'},
    {key = 'server_single_click', label = 'One click joins a server'},
    {key = 'server_list_retry', label = 'Retry the server list', on = 10, off = 0},
    {key = 'account_single_click', label = 'One click logs in an account'},
    {key = 'account_force_show', label = 'Show empty account lists'},
    {key = 'account_use_slider', label = 'Account page slider'},
    {key = 'account_use_list', label = 'Account page list'},
    {key = 'show_account_info', label = 'Show the account name'},
    {key = 'debug', label = 'DEBUG button and log'},
  },
  source = 'config.lua', -- where the settings came from, shown in the DEBUG log
}

local function store()
  if type(CherrysLoginxml_Settings) ~= 'table' then
    CherrysLoginxml_Settings = {}
  end
  return CherrysLoginxml_Settings
end

-- Changes made on the login screen this session. Loading saved variables in game
-- replaces CherrysLoginxml_Settings with the saved copy, so the in-game addon puts
-- these back over it.
local function live()
  if type(CherrysLoginxml_Live) ~= 'table' then
    CherrysLoginxml_Live = {values = {}}
  end
  return CherrysLoginxml_Live
end

-- Only this one table is taken from the file; the rest stays in the throwaway environment
local function readSaved()
  local path = login.loadFile('savedpath')
  me.hasSetup = type(path) == 'string'
  local fn = me.hasSetup and loadfile(path)
  if not fn then
    return nil
  end
  local env = {}
  setfenv(fn, env)
  local ok = pcall(fn)
  return ok and type(env.CherrysLoginxml_Settings) == 'table' and env.CherrysLoginxml_Settings or nil
end

-- Called by login.onLoad right after config.lua is read
function me.load()
  if SaveVariables then
    pcall(SaveVariables, 'CherrysLoginxml_Settings')
  end
  local ok, fromFile = pcall(readSaved)
  if type(CherrysLoginxml_Settings) ~= 'table' and ok then
    CherrysLoginxml_Settings = fromFile
  end
  local saved = CherrysLoginxml_Settings
  if type(saved) == 'table' and next(saved) then
    me.source = 'saved settings'
    for key, value in pairs(saved) do
      login.config[key] = value
    end
  end
  if lprint then
    lprint('settings from ' .. me.source)
  end
end

local function isOn(toggle)
  local value = login.config[toggle.key]
  if toggle.on then
    if value == nil then
      value = toggle.on
    end
    return (tonumber(value) or 0) > 0
  end
  return value and true or false
end

-- Redraws whatever a setting shows right away; the rest is read when it is used
function me.applyLive(key)
  if key == 'show_account_info' then
    if login.config.show_account_info then
      LoginAccount:Show()
    else
      LoginAccount:Hide()
    end
  elseif key == 'debug' then
    if login.config.debug then
      LoginFrame_debug:Show()
    else
      LoginFrame_debug:Hide()
      LoginDebugFrame:Hide()
    end
  elseif key == 'account_force_show' or key == 'account_use_slider' or key == 'account_use_list' then
    pcall(login.account.initPageSlider)
    pcall(login.account.initPageList)
    pcall(login.account.updateAccountList)
  end
end

function me.set(key, value)
  login.config[key] = value
  store()[key] = value
  live().values[key] = value
  me.applyLive(key)
  me.refresh()
end

-- Forgets every saved toggle and goes back to config.lua
function me.reset()
  CherrysLoginxml_Settings = {}
  CherrysLoginxml_Live = {values = {}, reset = true}
  local data = login.loadFile('config')
  if type(data) == 'table' then
    login.config = data
  end
  me.source = 'config.lua'
  for _, toggle in ipairs(me.toggles) do
    me.applyLive(toggle.key)
  end
  me.refresh()
end

-- ! ==============================================================
-- ! ========================== frame =============================
-- ! ==============================================================
function me.onLoad(frame)
  for i = 1, me.max do
    local box = _G['LoginServerFrame_options_' .. i]
    local toggle = me.toggles[i]
    if toggle then
      box:SetID(i)
      box:SetText(toggle.label)
      box:Show()
    else
      box:Hide()
    end
  end
  frame:SetHeight(#me.toggles * 24 + 116)
  local hint = _G['LoginServerFrame_options_hint']
  if hint then
    hint:SetText(me.hasSetup and 'Applies at once. Saved once you enter the game, then log out or quit.'
      or 'Applies at once. Run Install login screen.bat once to keep these after a restart.')
  end
  me.refresh()
end

function me.onClick(box)
  local toggle = me.toggles[box:GetID()]
  if not toggle then
    return
  end
  local on = box:IsChecked() and true or false
  if toggle.on then
    me.set(toggle.key, on and toggle.on or toggle.off)
  else
    me.set(toggle.key, on)
  end
end

function me.refresh()
  for i, toggle in ipairs(me.toggles) do
    local box = _G['LoginServerFrame_options_' .. i]
    if box then
      box:SetChecked(isOn(toggle))
    end
  end
end

me.max = 14 -- check buttons in login.settings.xml
login.settings = me;
