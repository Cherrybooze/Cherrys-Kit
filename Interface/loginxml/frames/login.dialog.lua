local me = {}
-- local _,y = loadfile("interface/loginxml/frames/login.dialog.lua") lprint(y) 
LoginDialogTypes = {}

-- login.dialog.show("PASSWORD_FAILED")
LoginDialogTypes.PASSWORD_FAILED = {
  text = TEXT('LOGIN_PASSWORD_FAILED'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    LinkActivateWeb();
    QuitGame();
  end,
}

-- login.dialog.show("CREATE_CHARACTER")
LoginDialogTypes.CREATE_CHARACTER = {
  text = TEXT('CHARACTER_CREATING'), --
}

-- login.dialog.show("RESERVE_CHARACTER")
LoginDialogTypes.RESERVE_CHARACTER = {
  text = TEXT('RESERVE_CHARACTER'), --
  confirmText = TEXT('LOGIN_OKAY'),
}

-- login.dialog.show("CREATE_CHARACTER_SUCCESS")
LoginDialogTypes.CREATE_CHARACTER_SUCCESS = {
  text = TEXT('CREATE_CHARACTER_SUCCESS'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    SetLoginScreen('charselect');
  end,
}

-- login.dialog.show("CANCEL")
LoginDialogTypes.CANCEL = {
  cancelText = TEXT('LOGIN_CANCEL'), --
  onCancel = function() --
    login.setLoginData()
  end,
}

-- login.dialog.show("OKAY")
LoginDialogTypes.OKAY = {
  cancelText = TEXT('LOGIN_OKAY'), --
}

-- login.dialog.show("OKAY_AND_QUIT")
LoginDialogTypes.OKAY_AND_QUIT = {
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    QuitGame();
  end,
}

-- login.dialog.show("WAITING_QUEUE")
LoginDialogTypes.WAITING_QUEUE = {
  cancelText = TEXT('LOGIN_CANCEL'), --
  onCancel = function()
    SetSelectedRealmState(false);
    CancelWaitingQueue();
    login.setLoginData()
  end,
}

-- login.dialog.show("DELETE_CHARACTER")
LoginDialogTypes.DELETE_CHARACTER = {
  text = TEXT('DELETE_CHARACTER'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function(edit)
    DeleteCharacter(login.charselect.selected, edit);
  end, --
  hasEdit = 1, --
  passwordMode = 1,
}

-- login.dialog.show("DELETE_CHARACTER_FAILED")
LoginDialogTypes.DELETE_CHARACTER_FAILED = {
  text = TEXT('DELETE_CHARACTER_FAILED'), --
  confirmText = TEXT('LOGIN_OKAY'),
}

-- login.dialog.show("RECOVER_DELETE_CHARACTER")
LoginDialogTypes.RECOVER_DELETE_CHARACTER = {
  text = TEXT('RECOVER_DELETE_CHARACTER'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function()
    RecoverDeleteCharacter(login.charselect.selected);
  end,
}

-- login.dialog.show("SELECT_CHARACTER_ZONENOTEXIST")
LoginDialogTypes.SELECT_CHARACTER_ZONENOTEXIST = {
  text = TEXT('SELECT_CHARACTER_ZONENOTEXIST'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function()
    EnterWorld(login.charselect.selected);
  end,
}

-- login.dialog.show("OPEN_ACTIVATE_WEB")
LoginDialogTypes.OPEN_ACTIVATE_WEB = {
  text = TEXT('LINK_ACTIVATE_WEB'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function()
    LinkActivateWeb();
  end,
}

-- login.dialog.show("VALID_TIME_ERROR")
LoginDialogTypes.VALID_TIME_ERROR = {
  text = TEXT('VALID_TIME_ERROR'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function() --
    OpenActivateExecute();
    QuitGame();
  end,
}

-- login.dialog.show("RESET_PASSWORD")
LoginDialogTypes.RESET_PASSWORD = {
  text = TEXT('RESET_PASSWORD'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function() --
    OpenResetPasswordURL();
    QuitGame();
  end,
}

-- login.dialog.show("ADJUST_DISPLAY")
LoginDialogTypes.ADJUST_DISPLAY = {
  text = TEXT('PLZ_ADJUST_DISPLAY'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function()
    PlaySoundByPath('sound\\interface\\ui_generic_open.mp3');
    LoginSettingsFrame:Show();
  end,
}

-- login.dialog.show("SERVER_FULL")
LoginDialogTypes.SERVER_FULL = {
  text = TEXT('LOGIN_SERVER_LIST_FULL'), --
  confirmText = TEXT('LOGIN_OKAY'),
}

-- login.dialog.show("SERVER_ILLEGAL_AGE")
LoginDialogTypes.SERVER_ILLEGAL_AGE = {
  text = TEXT('LOGIN_ILLEGAL_AGE'), --
  confirmText = TEXT('LOGIN_OKAY'),
}

-- login.dialog.show("CONFIRM_PASSWORD")
LoginDialogTypes.CONFIRM_PASSWORD = {
  text = TEXT('LOGIN_CONFIRM_PASSWORD'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function(edit)
    ConfirmPassword(edit);
  end, --
  onCancel = function() --
    login.GOTO('server', 'account')
  end, passwordMode = 1, --
  hasEdit = 1, --
  locked = 1,
}

-- login.dialog.show("CONFIRM_PASSWORD_FAILED")
LoginDialogTypes.CONFIRM_PASSWORD_FAILED = {
  text = TEXT('PASSWORD_INPUT_FAILED'), --
  replFN = GetPasswordErrorCount, --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    me.show('CONFIRM_PASSWORD');
  end,
}

-- login.dialog.show("LOGIN_PASSWORD_THIRD")
LoginDialogTypes.LOGIN_PASSWORD_THIRD = {
  text = TEXT('LOGIN_LOCK_CHARACTER'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    QuitGame();
  end, --
  locked = 1,
}

-- login.dialog.show("LOGIN_LOCK_CHARACTER")
LoginDialogTypes.LOGIN_LOCK_CHARACTER = {
  text = TEXT('LOGIN_LOCK_CHARACTER'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  replFN = function()
    return math.floor((3600 - arg1) / 60) + 1
  end, onConfirm = function()
    QuitGame();
  end, --
  locked = 1,
}

-- login.dialog.show("CONFIRM_PASSWORD2")
LoginDialogTypes.CONFIRM_PASSWORD2 = {
  text = TEXT('LOGIN_CONFIRM_PASSWORD'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  onConfirm = function(edit)
    ConfirmPassword2(edit);
  end, --
  onCancel = function() --
    login.GOTO('server', 'account')
  end, passwordMode = 1, --
  hasEdit = 1, --
  locked = 1, --
}

-- login.dialog.show("CONFIRM_PASSWORD_FAILED2")
LoginDialogTypes.CONFIRM_PASSWORD_FAILED2 = {
  text = TEXT('PASSWORD_INPUT_FAILED'), --
  replFN = GetPasswordErrorCount, --
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    me.show('CONFIRM_PASSWORD2');
  end,
}

-- login.dialog.show("CONFIRM_CAPTCHA_FAILED")
LoginDialogTypes.CONFIRM_CAPTCHA_FAILED = {
  text = TEXT('PASSWORD_INPUT_FAILED'), --
  replFN = GetPasswordErrorCount, --
  confirmText = TEXT('LOGIN_OKAY'), --
}
-- login.dialog.show("CONFIRM_CAPTCHA_TIME_EXPIRED")
LoginDialogTypes.CONFIRM_CAPTCHA_TIME_EXPIRED = {
  text = TEXT('CAPTCHA_EXPIRED'), --
  confirmText = TEXT('LOGIN_OKAY'), --
}
-- login.dialog.show("CONFIRM_ENTER_WORLD")
LoginDialogTypes.CONFIRM_ENTER_WORLD = {
  confirmText = TEXT('LOGIN_OKAY'), --
  onConfirm = function()
    EnterWorld(CHARACTERSELECT_REGION_SELECTED); --
  end,
}

-- login.dialog.show("PASSWORD_SHOW")
LoginDialogTypes.PASSWORD_SHOW = {
  text = TEXT('LOGIN_CONFIRM_PASSWORD'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  cancelText = TEXT('LOGIN_CANCEL'), --
  placeholder1 = TEXT('PASSWORD'), --
  placeholder2 = TEXT('PASSWORD_CONFIRM'), --
  onShow = function()
    local pw, def = login.getSecPassword()
    me.edit(def, def)
  end, --
  onConfirm = function(edit1, edit2)
    local result = SetSecondPassword(edit1, edit2);
    local text = nil
    if result == -1 then
      text = TEXT('PASSWORD_ERROR_WRONGFUL')
    elseif result == -2 then
      text = TEXT('PASSWORD_ERROR_SHORT')
    elseif result == -3 then
      text = TEXT('PASSWORD_ERROR_UNEQUAL')
    elseif result == -4 then
      text = TEXT('PASSWORD_ERROR_WRONGFUL_1')
    else
      return
    end
    local function onCancel()
      me.show('PASSWORD_SHOW')
    end
    me.show('OKAY', nil, {text = text, onCancel = onCancel})
  end, --
  onCancel = function() --
    login.GOTO('server', 'account')
  end, --
  passwordMode = 1, --
  hasEdit = 2, --
  locked = 1,
}

-- login.dialog.show("LOGINRENAME_SHOW")
LoginDialogTypes.LOGINRENAME_SHOW = {
  text = TEXT('LOGIN_RENAME_TEXT'), --
  confirmText = TEXT('LOGIN_OKAY'), --
  confirmDisabled = false, cancelText = TEXT('LOGIN_CANCEL'), --
  placeholder1 = TEXT('LOGIN_PLAYER_NAME'), --
  onConfirm = function(edit1)
    local result = SetCharacterName(edit1);
    local text = nil
    result = 0
    if result == -1 then
      text = TEXT('CHARACTER_CREATE_NAME_TO_SHORT')
    elseif result == -2 then
      text = TEXT('CHARACTER_CREATE_NAME_TO_LONG')
    elseif result == -3 or result == -4 then
      text = TEXT('CHARACTER_CREATE_NAME_WRONGFUL')
    elseif result == -10 then
      text = TEXT('CHARACTER_NOT_EXIST')
    elseif result == -11 then
      text = TEXT('CHARACTER_RENAME_ERROR')
    else
      me.show('LOGINRENAME_SHOW', nil, {confirmDisabled = true})
      return
    end
    local function onCancel()
      me.show('LOGINRENAME_SHOW')
    end
    me.show('OKAY', nil, {text = text, onCancel = onCancel})
  end, --
  hasEdit = 1, --
  locked = 1,
}

function me.onAction(frame, confirm)
  if (confirm and frame.data.confirmText) or (not confirm and frame.data.cancelText) or fn then
    LoginDialogFrame:Hide()
  end

  local fn = frame.data[confirm and 'onConfirm' or 'onCancel']
  if fn then
    pcall(fn, LoginDialog_edit1:GetText(), LoginDialog_edit2:GetText())
  end
  LoginDialog_edit1:SetText('')
  LoginDialog_edit2:SetText('')
end
function me.registerEvents(this)
  -- this:RegisterEvent('LOADING_START');
  -- this:RegisterEvent('LOADING_END');
  -- this:RegisterEvent('LOADING_PROGRESS_POSITION');

  this:RegisterEvent('OPEN_LOGIN_DIALOG');
  this:RegisterEvent('UPDATE_LOGIN_DIALOG');
  this:RegisterEvent('CLOSE_LOGIN_DIALOG');

  this:RegisterEvent('PASSWORD_SHOW');
  this:RegisterEvent('PASSWORD_HIDE');

  this:RegisterEvent('LOGINRENAME_SHOW');
  this:RegisterEvent('LOGINRENAME_SUCCESS');
  this:RegisterEvent('LOGINRENAME_FAILED');

  this:RegisterEvent('CONFIRM_CAPTCHA');
  this:RegisterEvent('CONFIRM_CAPTCHA_OK');
  this:RegisterEvent('CONFIRM_CAPTCHA_FAILED');
  this:RegisterEvent('CONFIRM_CAPTCHA_TIME_EXPIRED');

  this:RegisterEvent('ADJUST_DISPLAY');
  this:RegisterEvent('LINK_ACTIVATE_WEB');
  this:RegisterEvent('VALID_TIME_ERROR');

  this:RegisterEvent('LOGIN_LOCK_CHARACTER');
  this:RegisterEvent('LOGIN_PASSWORD_FAILED');
  this:RegisterEvent('CONFIRM_PASSWORD');
  this:RegisterEvent('CONFIRM_PASSWORD_FAILED');
  this:RegisterEvent('PASSWORD_THIRD_FAILED');
  this:RegisterEvent('RESET_PASSWORD');
  this:RegisterEvent('CONFIRM_PASSWORD2');
  this:RegisterEvent('CONFIRM_PASSWORD_FAILED2');
end
function me.onEvent(event)
  if LoginDialogTypes[event] then
    me.show(event)
    return true
  end
  return pcall(me[event], arg1, arg2, arg3, arg4)
end
function me.OPEN_LOGIN_DIALOG(which, text, data)
  me.show(which, nil, {text=text, repl=data})
end
function me.CLOSE_LOGIN_DIALOG()
  if LoginDialogFrame:IsVisible() and not LoginDialogFrame.locked then
    LoginDialogFrame:Hide()
  end
end
function me.PASSWORD_HIDE()
  me.hide('PASSWORD_SHOW')
end
function me.LOGINRENAME_SUCCESS()
  me.hide('LOGINRENAME_SHOW')
end
function me.LOGINRENAME_FAILED()
  if me.hide('LOGINRENAME_SHOW') then
    me.show('LOGINRENAME_SHOW')
  end
end
function me.UPDATE_LOGIN_DIALOG(arg1, arg2)
  if not arg1 or string.len(arg1) == 0 then
    return
  end
  LoginDialog_text:SetText(arg1)
  local buttonText = arg2
  if not arg2 and LoginDialogFrame.data then
    buttonText = LoginDialogFrame.data.confirmText
  end
  if buttonText then
    LoginDialog_confirm:SetText(buttonText)
  end
  me.adjustHeight()
end

-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.isVisible(which)
  return LoginDialogFrame:IsVisible() and LoginDialogFrame.current == which
end
function me.edit(e1, e2)
  LoginDialog_edit1:SetText(e1 and tostring(e1) or LoginDialog_edit1:GetText())
  LoginDialog_edit2:SetText(e2 and tostring(e2) or LoginDialog_edit2:GetText())
end
function me.hide(which, force)
  if LoginDialogFrame:IsVisible() and (LoginDialogFrame.current == which or force) then
    LoginDialogFrame:Hide()
    return true
  end
  return false
end
function me.show(which, data, overwrite)
  if not data then
    data = LoginDialogTypes[which]
  end
  local frame = LoginDialogFrame
  if not frame:IsVisible() then
    frame:Show()
  else
    if frame.locked then
      return
    end
    LoginDialog_edit1:SetText('')
    LoginDialog_edit2:SetText('')
  end
  if data == nil then
    return
  end
  if overwrite then
    local _data = data
    data = {}
    for a, b in pairs(_data) do
      data[a] = b
    end
    for a, b in pairs(overwrite) do
      data[a] = b
    end
  end
  frame.locked = data.locked
  frame.current = which
  frame.data = data

  local btn1 = LoginDialog_confirm
  local btn2 = LoginDialog_cancel
  local edit1 = LoginDialog_edit1
  local edit2 = LoginDialog_edit2
  local text = LoginDialog_text
  local _text = data.text
  if _text then
    if data.repl or data.replFN then
      _text = string.format(_text, data.replFN and data.replFN() or data.repl)
    end
    text:SetText(_text)
    text:Show()
  else
    text:Hide()
  end
  if data.confirmDisabled then
    btn1:Disable()
  else
    btn1:Enable()
  end
  if data.confirmText and data.cancelText then
    btn1:SetText(tostring(data.confirmText))
    btn1:ClearAllAnchors()
    btn1:SetAnchor('BOTTOMRIGHT', 'BOTTOM', LoginDialog, 0, -10)
    btn1:Show()

    btn2:SetText(tostring(data.cancelText))
    btn2:ClearAllAnchors()
    btn2:SetAnchor('LEFT', 'RIGHT', btn1, 0, 0)
    btn2:Show()
  elseif data.confirmText or data.cancelText then
    local vis = data.confirmText and btn1 or btn2
    local hid = data.confirmText and btn2 or btn1
    vis:ClearAllAnchors()
    vis:SetAnchor('BOTTOM', 'BOTTOM', LoginDialog, 0, -10)
    vis:SetText(data.confirmText or data.cancelText)
    vis:Show()
    hid:Hide()
  else
    btn1:Hide()
    btn2:Hide()
  end
  if data.hasEdit or data.edit1 then
    edit1:SetPasswordMode(data.passwordMode)
    edit1:SetText(data.edit1 or '')
    edit1:SetPlaceholder(data.placeholder1 or '')
    edit1:Show()
    if data.hasEdit == 1 then
      edit2:Hide()
    else
      edit2:SetPasswordMode(data.passwordMode)
      edit2:SetText(data.edit2 or '')
      edit2:SetPlaceholder(data.placeholder2 or '')
      edit2:Show()
    end
    local offset = edit2:IsVisible() and edit2:GetWidth() / 2 + 1 or 0
    edit1:ClearAllAnchors()
    if btn1:IsVisible() or btn2:IsVisible() then
      edit1:SetAnchor('BOTTOM', 'BOTTOM', LoginDialog, -offset, -45)
    else
      edit1:SetAnchor('BOTTOM', 'BOTTOM', LoginDialog, -offset, -10)
    end
  else
    edit1:Hide()
    edit2:Hide()
  end
  me.adjustHeight()
  if data.onShow then
    data.onShow()
  end
end
function me.adjustHeight()
  local btn1 = LoginDialog_confirm
  local btn2 = LoginDialog_cancel
  local text = LoginDialog_text
  local edit1 = LoginDialog_edit1
  local bHeight = 0
  if btn1:IsVisible() or btn2:IsVisible() then
    bHeight = btn1:GetHeight() + 20
  end
  local tHeight = text:IsVisible() and text:GetHeight() + 25 or 0
  local eHeight = edit1:IsVisible() and edit1:GetHeight() + 10 or 0
  LoginDialog:SetHeight(bHeight + tHeight + eHeight)
end

login.dialog = me;
