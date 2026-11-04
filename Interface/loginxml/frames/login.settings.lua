-- On/off settings from config.lua as toggles, to the right of the server list.
-- A click applies at once and is kept in CherrysLoginxml_Settings, which wins over
-- config.lua. The game writes that table to SaveVariables.lua when you log out or quit
-- (LogNextChar in Interface\AddOns\CherrysKit registers it). The game only loads that
-- file on entering the world, so the first login screen after a restart reads it itself.
-- Lua cannot find the Documents folder: "Install login screen.bat" leaves the path in
-- savedpath.lua.
local me = {
  -- group: the heading it sits under in the Modern look; default: its value when config.lua has none
  toggles = {
    {key = 'modern_ui', label = 'Modern look', group = 1, default = true},
    {key = 'character_login_single', label = 'Log in if only one character', group = 2},
    {key = 'character_login_first', label = 'Log in the first character', group = 2},
    {key = 'character_nologin_ctrl', label = 'Ctrl stops at character select', group = 2},
    {key = 'character_single_click', label = 'One click logs in a character', group = 2},
    {key = 'character_sort', label = 'Sort characters by level', group = 2},
    -- arrows on the character screen that change the numbers, which Next, Prev and /lnc <number> follow
    {key = 'character_order_edit', label = 'Edit character order', group = 2},
    {key = 'server_single_click', label = 'One click joins a server', group = 3},
    {key = 'server_list_retry', label = 'Retry the server list', on = 10, off = 0, group = 3},
    {key = 'account_single_click', label = 'One click logs in an account', group = 4},
    {key = 'account_force_show', label = 'Show empty account lists', group = 4},
    {key = 'account_use_slider', label = 'Account page slider', group = 4},
    {key = 'account_use_list', label = 'Account page list', group = 4},
    {key = 'show_account_info', label = 'Show the account name', group = 4},
    {key = 'debug', label = 'DEBUG button and log', group = 5},
  },
  groups = {'Look', 'Characters', 'Servers', 'Accounts', 'Other'},
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
  if value == nil and toggle.default ~= nil then
    value = toggle.default
  end
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
  elseif key == 'modern_ui' then
    if LoginLook then
      LoginLook.apply(login.config.modern_ui ~= false)
    end
  elseif key == 'character_order_edit' or key == 'character_sort' then
    if login.charselect and login.charselect.onSkin then
      pcall(login.charselect.updateCharacterList)
      pcall(login.charselect.onSkin)
    end
  end
end

function me.set(key, value)
  login.config[key] = value
  store()[key] = value
  live().values[key] = value
  me.applyLive(key)
  me.refresh()
end

-- Forgets every saved toggle and goes back to config.lua. The character order isn't a toggle: it stays.
function me.reset()
  local order = login.config.character_order
  CherrysLoginxml_Settings = {character_order = order}
  CherrysLoginxml_Live = {values = {character_order = order}, reset = true}
  local data = login.loadFile('config')
  if type(data) == 'table' then
    login.config = data
    data.character_order = order
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
  me.frame = frame
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
  me.layout()
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

-- Classic: one column of boxes as in login.settings.xml, right of the server list. Modern: smaller boxes
-- under group headings, the panel at the left edge of the screen (the server list is on the right).
local CLASSIC_ROW, ROW, HEAD, GAP, BOX, WIDTH = 24, 21, 17, 6, 18, 250 -- WIDTH: as in login.settings.xml

local function place(object, x, y)
  object:ClearAllAnchors()
  object:SetAnchor('TOPLEFT', 'TOPLEFT', me.frame, x, y)
end

local function label(box, x, y)
  local text = box:GetNormalText()
  text:ClearAllAnchors()
  text:SetAnchor('LEFT', 'RIGHT', box, x, y)
end

function me.layout()
  local frame = me.frame
  if not frame then
    return
  end
  local name = 'LoginServerFrame_options'
  local skin = LoginLook
  if skin and skin.modern then
    local y, group = 38, nil
    for i, toggle in ipairs(me.toggles) do
      if toggle.group ~= group then
        y = group and y + GAP or y
        group = toggle.group
        local head = _G[name .. '_group' .. group]
        place(head, 16, y)
        head:SetText(me.groups[group])
        skin.tint(head, skin.color.cyan)
        head:Show()
        y = y + HEAD
      end
      local box = _G['LoginServerFrame_options_' .. i]
      place(box, 14, y)
      box:SetSize(BOX, BOX)
      label(box, 7, 0)
      y = y + ROW
    end
    -- Global Bank's state (up to four lines) and the hint (up to three) above the button
    local status, hint = _G[name .. '_globalbank'], _G[name .. '_hint']
    status:SetSize(WIDTH - 32, 48)
    hint:SetSize(WIDTH - 32, 36)
    status:ClearAllAnchors()
    status:SetAnchor('BOTTOMLEFT', 'BOTTOMLEFT', frame, 16, -80)
    hint:ClearAllAnchors()
    hint:SetAnchor('BOTTOMLEFT', 'BOTTOMLEFT', frame, 16, -40)
    frame:SetHeight(y + 136)
    frame:ClearAllAnchors()
    -- at the left edge, level with the server list on the right
    frame:SetAnchor('LEFT', 'LEFT', LoginServerFrame, 10, -20)
    place(_G[name .. '_title'], 16, 13)
    skin.tint(_G[name .. '_title'], skin.color.text)
    skin.tint(_G[name .. '_hint'], skin.color.dim)
    skin.tint(_G[name .. '_globalbank'], skin.color.dim)
    me.placed = true
    return
  end
  if me.placed then
    for i = 1, #me.toggles do
      local box = _G['LoginServerFrame_options_' .. i]
      place(box, 12, 34 + CLASSIC_ROW * (i - 1))
      box:SetSize(24, 24)
      label(box, 0, -1)
    end
    for i = 1, #me.groups do
      _G[name .. '_group' .. i]:Hide()
    end
    local status, hint = _G[name .. '_globalbank'], _G[name .. '_hint']
    status:SetSize(226, 44)
    hint:SetSize(226, 34)
    status:ClearAllAnchors()
    status:SetAnchor('BOTTOMLEFT', 'BOTTOMLEFT', frame, 14, -76)
    hint:ClearAllAnchors()
    hint:SetAnchor('BOTTOMLEFT', 'BOTTOMLEFT', frame, 14, -40)
    frame:ClearAllAnchors()
    frame:SetAnchor('TOPLEFT', 'TOPRIGHT', LoginServerFrame_list, 90, 0)
    place(_G[name .. '_title'], 14, 10)
    if skin then
      skin.tint(_G[name .. '_title'], skin.color.white)
      skin.tint(_G[name .. '_hint'], skin.color.classicGold)
      skin.tint(_G[name .. '_globalbank'], skin.color.classicGold)
    end
    me.placed = nil
  end
  frame:SetHeight(#me.toggles * CLASSIC_ROW + 160)
end
me.onSkin = me.layout

function me.refresh()
  for i, toggle in ipairs(me.toggles) do
    local box = _G['LoginServerFrame_options_' .. i]
    if box then
      box:SetChecked(isOn(toggle))
    end
  end
end

me.max = 15 -- check buttons in login.settings.xml
login.settings = me;
