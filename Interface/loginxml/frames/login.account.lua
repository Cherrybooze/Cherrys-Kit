local me = {
  columns = 3, --
  max = 10, --
  accountData = {}, --
  page = 1,
}

function me.onLoad(this)
  local data = login.loadFile('accounts')
  data = type(data) == 'table' and data or {}
  local col_settings = login.config.account_columns
  me.columns = type(col_settings) == 'number' and math.floor(col_settings) or 3
  data.accounts = data.accounts or {}
  for account, value in pairs(data.accounts) do
    if type(account) == 'string' then
      if type(value) == 'table' then
        local secpw = value[2]
        login.addSecPW(account, secpw)
        data.accounts[account] = value[1]
      end
    end
  end
  me.accountData = data

  local page_settings = login.config.account_page
  me.page = type(page_settings) == 'number' and math.floor(page_settings) or 1
  me.page = math.max(1, math.min(me.page, me.getAccountCount()))

  me.initAccountList()
  me.initPageList()
  me.initPageSlider()
end
function me.onEvent(event)
  return pcall(me[event], arg1, arg2, arg3, arg4)
end

-- ! ==============================================================
-- ! ========================== init ==============================
-- ! ==============================================================

function me.initAccountList()
  local name = 'LoginAccountFrame'
  local data = {
    col = {200}, --
    fn = {
      callback = me.accountCallback, --
      onClick = me.accountOnClick, --
      onEnter = me.accountOnEnter, --
      onLeave = me.accountOnLeave, --
    }, --
    numRow = math.min(math.floor(LoginAccountFrame:GetHeight() / 40) - 3, 20),
  }
  local col = me.columns
  local odd = col % 2 == 1

  for i = 1, me.max do
    local list = _G[name .. '_' .. i]
    if i > col * 2 then
      list:Hide()
    else
      local up = math.floor((i - 1) / col) == 0
      local offset_fac = ((i - 1) % col) - col / 2;
      offset_fac = offset_fac + 0.5

      _G[list:GetName() .. '_list']:SetBackdropTileAlpha(.5)
      list:SetID(i)
      list:init(data)

      list:ClearAllAnchors()
      list:SetAnchor(up and 'BOTTOM' or 'TOP', 'CENTER', LoginAccountFrame, list:GetWidth() * offset_fac, up and -20 or 20)
    end
  end
  me.updateAccountList()
end

function me.initPageSlider()
  local slider = LoginAccountFrame_pages_slider
  local max = me.getAccountCount()
  if not login.config.account_use_slider or max == 1 then
    slider:Hide()
    return
  end
  slider:SetValueStepMode('INT')
  slider:SetMinMaxValues(1, max)
  slider:SetValue(me.page)
  slider:Show()
end
function me.initPageList()
  local list = LoginAccountFrame_pages
  local max = me.getAccountCount()
  if not login.config.account_use_list or max == 1 then
    list:Hide()
    return
  end

  local lst = {}
  for i = 1, max do
    lst[i] = {i}
  end
  local data = {
    col = {60}, --
    noHead = true, --
    fn = {
      callback = function()
        return lst, {}, me.page
      end, onClick = me.pageOnClick, onEnter = me.pageOnEnter, --
      onLeave = me.pageOnLeave, --
    },
  }
  LoginAccountFrame_pages:init(data)
  LoginAccountFrame_pages_list:SetBackdropTileAlpha(0.2)
  LoginAccountFrame_pages:Show()
end
-- ! ==============================================================
-- ! ========================= update =============================
-- ! ==============================================================

function me.updateAccountList()
  local colPerPage = me.columns * 2
  for i = 1, colPerPage do
    local index = i + (me.page - 1) * (colPerPage)
    local list = _G['LoginAccountFrame_' .. i]
    if type(me.accountData[index]) == 'table' and #me.accountData[index] > 0 or login.config.account_force_show then
      list:Show()
      list:update()
    else
      list:Hide()
    end
  end
end

-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.show()
  if IsHideLoginUI() then
    LoginAccountFrame:Hide()
    me.retry.tries = 0
    me.retryReset()
    LoginAccountButton:Show()
  else
    LoginAccountButton:Hide()
    LoginAccountFrame:Show()
    LoginAccountFrame_account:SetFocus();
  end
end
function me.hide()
  LoginAccountFrame:Hide()
  LoginAccountButton:Hide()
end

-- Launcher logins (Steam, Gameforge client) show only the Retry button while the
-- server list loads. When it hangs on "obtaining server list", AcceptUserAgreement()
-- asks again. Config: server_list_retry = seconds before an automatic retry
-- (0 = by hand only), server_list_retry_max = automatic retries before stopping.
me.retry = {left = nil, tries = 0, shown = nil}

function me.retryReset()
  local wait = tonumber(login.config.server_list_retry) or 10
  me.retry.left = wait > 0 and wait or nil
end
function me.retryNow()
  me.retry.tries = me.retry.tries + 1
  me.retryReset()
  if lprint then
    lprint('server list retry ' .. me.retry.tries)
  end
  AcceptUserAgreement()
end
function me.retryOnUpdate(button, elapsed)
  local r = me.retry
  local max = tonumber(login.config.server_list_retry_max) or 3
  local text = 'Retry'
  if r.left and r.tries < max and not LoginDialogFrame:IsVisible() then
    r.left = r.left - elapsed
    if r.left <= 0 then
      me.retryNow()
      return
    end
    text = string.format('Retry (%d)', math.ceil(r.left))
  end
  if r.shown ~= text then
    r.shown = text
    button:SetText(text)
  end
end
function me.login()
  login.setLoginData()
  local acc = LoginAccountFrame_account:GetText()
  local pw = LoginAccountFrame_password:GetText()

  if acc == '' or pw == '' then
    return false
  end
  login.charselect._locks.onLogin = nil
  DefaultServerLogin(acc, pw)
  return true
end

function me.setPage(i)
  me.page = i
  me.updateAccountList()
  if LoginAccountFrame_pages:IsVisible() then
    LoginAccountFrame_pages:update()
  end
  LoginAccountFrame_pages_slider:SetValue(i)
end

-- ! ==============================================================
-- ! ========================== list ==============================
-- ! ==============================================================
function me.pageOnClick(_, double, index)
  if not double then
    me.setPage(index)
  end
end
function me.pageOnEnter(frame, index, col_index, row, col)
  local tt = LoginTooltip
  tt:ClearAllAnchors()
  tt:SetAnchor('TOPRIGHT', 'TOPLEFT', row, 0, 0)
  local colPerPage = me.columns * 2
  local id = colPerPage * (index - 1) + 1
  string.format('Page %d: [%d-%d]', index, id, id + colPerPage)
  tt:SetText('Page: ' .. index)
  for i = id, id + colPerPage do
    local data = me.accountData[i]
    if type(data) == 'table' and data._title then
      tt:AddLine(string.format('=== %s ===', i))
      tt:AddLine(data._title)
    end
  end
end
function me.pageOnLeave()
  LoginTooltip:Hide()
end

function me.accountCallback(frame)
  local id = frame:GetID()
  local colPerPage = me.columns * 2
  id = id + colPerPage * (me.page - 1)
  local res = {}
  local data = me.accountData[id]
  if not data then
    return {}, {id}, nil
  end
  for _, entry in ipairs(data) do
    local txt = tostring(entry.acc)
    if entry.srv then
      if entry.char then
        txt = string.format('%s - %s - %s', entry.char, entry.srv, txt)
      else
        txt = string.format('%s - %s', entry.srv, txt)
      end
    end
    table.insert(res, {txt})
  end
  local title = data._title and string.format('%s (%s)', tostring(data._title), id) or id
  return res, {title}, nil
end
function me.accountOnClick(frame, double, index, key, col_index, row, col)
  local id = frame:GetID()
  local colPerPage = me.columns * 2
  id = id + colPerPage * (me.page - 1)
  local data = me.accountData[id][index]
  local account = data.acc
  local pw = me.accountData.accounts[account]
  pw = pw or me.accountData._defaultPassword

  LoginAccountFrame_account:SetText(account or '')
  LoginAccountFrame_password:SetText(pw or '')
  if double or login.config.account_single_click then
    if me.login() then
      login.setLoginData(data.srv, data.char, data.srv_sel, data.chars)
    end
  end
end
function me.accountOnEnter(frame, index, col_index, row, col)
  local tt = LoginTooltip
  tt:ClearAllAnchors()
  tt:SetAnchor('TOPLEFT', 'BOTTOMLEFT', row, 10, 0)

  local id = frame:GetID()
  local colPerPage = me.columns * 2
  id = id + colPerPage * (me.page - 1)

  local entry = me.accountData[id][index]

  tt:SetText(entry.char and 'Char' or entry.srv and 'Server' or 'Account')
  tt:AddLine('Account: ' .. entry.acc)
  if entry.srv then
    tt:AddLine('Server: ' .. entry.srv)
  end
  if entry.char then
    tt:AddLine('Char: ' .. entry.char)
  end
  if entry.note then
    tt:AddLine('Note: ' .. entry.note)
  end
  if entry.srv_sel then
    tt:AddSeparator()
    tt:AddLine('Select Server: ' .. entry.srv_sel)
  end
  if entry.chars then
    tt:AddSeparator()
    for srv, chars in pairs(entry.chars) do
      tt:AddLine(srv)
      for _, char in pairs(chars) do
        tt:AddLine('-> ' .. tostring(char))
      end
    end
  end
end
function me.accountOnLeave()
  LoginTooltip:Hide()
end

-- ! ==============================================================
-- ! ========================= helper =============================
-- ! ==============================================================
function me.getAccountCount()
  local max = 1
  for index, _ in pairs(me.accountData) do
    if type(index) == 'number' and index > max then
      max = index
    end
  end
  local colPerPage = me.columns * 2
  return math.ceil(max / colPerPage)
end

login.account = me;
