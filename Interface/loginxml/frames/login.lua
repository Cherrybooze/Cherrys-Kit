local me = {
  name = "Cherry's Loginxml",
  version = "1.2.0",
  sub = {
    'account', --
    'server', --
    'charselect', --
    'charcreate', --
    'dialog', --
  }, --
  history = {}, --
  password = {}, --
  config = { --
    character_sort = true, --
    channel = 1, --
    debug = false, --
    server_single_click = false, --
    character_single_click = false, --
    character_login_single = true, --
    character_nologin_ctrl = true, --
    account_single_click = false, --
    account_force_show = true, --
    account_use_slider = false, --
    account_use_list = true, --
    account_page = 1, --
    account_columns = 5, --
    show_account_info = true, --
  }, --
  autologin = {}, --
}

function me.onLoad(this)
  local data = me.loadFile('config')
  me.config = type(data) == 'table' and data or me.config
  if me.settings then
    me.settings.load()
  end

  if me.config.show_account_info then
    LoginAccount:Show()
  else
    LoginAccount:Hide()
  end

  local data = me.loadFile('password')
  me.password = type(data) == 'table' and data or {}
  me.password._accounts = type(me.password._accounts) == 'table' and me.password._accounts or {}

  for _, key in pairs(me.sub) do
    if me[key] and me[key].registerEvents then
      pcall(me[key].registerEvents, this)
    end
  end
  this:RegisterEvent('SET_LOGIN_SCREEN');
  this:RegisterEvent('SHOW_LOGIN');
end

function me.onEvent(event)
  local res = false;
  for _, key in pairs(me.sub) do
    if me[key] and me[key].onEvent then
      local _res, ret = pcall(me[key].onEvent, event)
      res = _res and ret or res
    end
  end
  local res = pcall(me[event], arg1, arg2, arg3, arg4) or res
  if not res then
    pcall(ldebug, string.format('ERR: %s', event), arg1, arg2, arg3, arg4)
  else
    pcall(ldebug, event, arg1, arg2, arg3, arg4)
  end
end
function me.SHOW_LOGIN()
  LoginParent:Show();
end
function me.SET_LOGIN_SCREEN(arg1, arg2)
  if arg1 == 'login' then
    me.GOTO('account', nil, true)
    LoginAccount:SetText(GetAccountName())
    AcceptUserAgreement();
  elseif arg1 == 'charselect' then
    LoginAccount:SetText(GetAccountName())
    me.GOTO('charselect')
    me.pw_helper = {num = 1}
  end
  SetCurrentScreen(arg1);
end

function me.GOTO(which, next, SLS)
  -- which = "charcreate"
  if which == 'last' then
    if GetCurrentServerList()=="" then
      return me.GOTO("account")
    end
    return me.GOTO(me.history[2])
  end
  if login[1]==which then return end;
  table.insert(me.history, 1, which)
  if next then
    me.history[2] = next
  end
  me.history[3] = nil
  if which == 'account' and not SLS then
    DisconnectFromServer();
    CloseServerList();
  end
  for _, key in pairs(me.sub) do
    if key ~= 'dialog' and me[key] and me[key].hide then
      pcall(me[key].hide)
    end
  end
  if me[which] and me[which].show then
    pcall(me[which].show)
  end
end

-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.loadFile(name)
  local fn, msg = loadfile('interface/loginxml/' .. name .. '.lua')
  if fn then
    return fn()
  end
  local fn2, msg2 = loadfile('interface/loginxml/data/' .. name .. '.lua')
  if fn2 then
    return fn2()
  end
  if lprint then
    lprint(tostring(msg))
    lprint(tostring(msg2))
  end
end

-- ! ==============================================================
-- ! ======================== auto login ==========================
-- ! ==============================================================
function me.getAutoServer()
  local res = me.autologin.srv or me.autologin.srv_sel
  local isAuto = me.autologin.srv
  me.autologin.srv = nil
  me.autologin.srv_sel = nil
  return res, isAuto
end
function me.getAutoChar()
  me.getAutoServer() -- force reset
  local res = me.autologin.char or me.autologin.chars
  me.autologin.char = nil
  me.autologin.chars = nil
  return res
end
function me.setLoginData(srv, char, srv_sel, char_sel)
  me.autologin = {
    srv = srv, --
    char = char, --
    srv_sel = srv_sel, --
    chars = char_sel, --
  }
end

-- ! ==============================================================
-- ! ========================= sec pw =============================
-- ! ==============================================================
function me.EnterPW(force)
  if not me.pw_helper then
    return
  end
  if me.pw_helper.num >= 2 and not force then
    return
  end
  if not me.pw_helper.chars then
    return
  end
  if not (me.pw_helper.confirm or me.pw_helper.pw) then
    return
  end
  me.pw_helper.num = me.pw_helper.num + 1
  local pw, def = me.getSecPassword()
  if not (pw or def) then
    return
  end

  if me.pw_helper.confirm then
    login.dialog.hide('CONFIRM_PASSWORD')
    LoginDialogTypes.CONFIRM_PASSWORD.onConfirm(pw or def)
  end
  if me.pw_helper.pw and pw then
    login.dialog.hide('PASSWORD_SHOW')
    LoginDialogTypes.PASSWORD_SHOW.onConfirm(pw, pw)
  end
end
function me.PASSWORD_SHOW()
  me.pw_helper.pw = true
  me.EnterPW()
end
function me.UPDATE_CHARACTER_SELECT_LIST()
  me.pw_helper.chars = true
  me.EnterPW()
end
function me.CONFIRM_PASSWORD()
  me.pw_helper.confirm = true
  me.EnterPW()
end

function me.addSecPW(account, secpw)
  me.password._accounts[account] = secpw
end
function me.getSecPassword()
  local server = me.password[GetServerName()]
  if type(server) == 'table' then
    for i = 1, GetNumCharacters() do
      local name = GetCharacterInfo(i);
      if server[name] then
        return server[name]
      end
    end
  elseif type(server) == 'string' then
    return server
  end
  local account = GetAccountName()
  if type(me.password._accounts[account]) == 'string' then
    return me.password._accounts[account]
  end
  local default = me.password._default
  return nil, (type(default) == 'string' and default or nil)
end

_G['login'] = me;
