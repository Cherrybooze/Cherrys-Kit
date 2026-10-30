-- local _,y = loadfile("interface/loginxml/frames/login.charselect.lua") lprint(y) 
local me = { --
  charlist = {}, --
  channels = {}, --
  classes = {}, --
  selected = nil, --
  channel = 1, -- overwritten by config
  _locks = {},
}

function me.onLoad(this)
  me.initchannels()
  me.initCharacterList()
end
function me.registerEvents(this)
  this:RegisterEvent('UPDATE_CHARACTER_SELECT_LIST');
  this:RegisterEvent('UPDATE_CHARACTER_PARALLEZONE');
  this:RegisterEvent('UPDATE_SELECTED_CHARACTER');
end
function me.onEvent(event)
  return pcall(me[event], arg1, arg2, arg3, arg4)
end
function me.onUpdate(frame, elapsed)
  if frame.rotate then
    local val = frame.rotate == 'left' and -1 or 1
    SetCharacterSelectFacing(GetCharacterSelectFacing() - val * elapsed * 60);
  end
  if frame.cursor then
    local x = GetCursorPos();
    local diff = (x - frame.cursor) * 0.6;
    SetCharacterSelectFacing(GetCharacterSelectFacing() - diff);
    frame.cursor = x
  end
  if me._locks.loginTime and me._locks.loginChar then
    me._locks.loginTime = me._locks.loginTime - elapsed
    if me._locks.loginTime <= 0 then
      me._locks.loginTime = nil
      if me.selected and me._locks.loginChar == GetCharacterInfo(me.selected) then
        me.login()
      end
      me._locks.loginChar = nil
    end
  end
end
function me.onShow()
  OpenCharacterSelect()
end

function me.UPDATE_SELECTED_CHARACTER(arg1)
  me.selected = arg1 --GetSelectedItem()
  LoginCharSelectFrame_chars:update()
  me.updateDeleteButton()
end
function me.UPDATE_CHARACTER_PARALLEZONE()
  local tex = 'interface/buttons/uiindex%s-normal'
  local colors = {'green', 'yellow', 'red'}
  me.channels = {}
  for i = 1, GetNumParalleZones() do
    local name, load = GetParalleZonesInfo(i)
    local _tex = string.format(tex, colors[load])
    table.insert(me.channels, {{tex = _tex}, name, {tex = _tex}})
  end
  LoginCharSelectFrame_channels:update();
end
function me.UPDATE_CHARACTER_SELECT_LIST()
  me.updateDeleteButton()
  me.updateCharacterList()
  me.autoLogin()
end

-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.show()
  LoginCharSelectFrame:Show()
  if me.selected then
    SelectCharacter(me.selected)
  end
end
function me.hide()
  LoginCharSelectFrame:Hide()
end
function me.login()
  if not me.selected then
    return
  end
  local name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel = GetCharacterInfo(me.selected);
  if destroyTime then
    login.dialog.show('RECOVER_DELETE_CHARACTER', nil, {repl = name})
  else
    EnterWorld(me.channel)
  end
end
function me.delete()
  if not me.selected then
    return
  end
  local name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel = GetCharacterInfo(me.selected);
  if destroyTime then
    login.dialog.show('RECOVER_DELETE_CHARACTER', nil, {repl = name})
  else
    login.dialog.show('DELETE_CHARACTER')
  end
end

function me.autoLogin()
  local char = login.getAutoChar()
  local charNum = GetNumCharacters()
  if _G.LOGCHAR_FLAG == 1 or (login.campnext and login.campnext.armed == 1) then
    return -- a queued /lnc switch picks the character
  end
  if charNum == 0 then
    return
  elseif charNum == 1 then
    if not me._locks.onLogin and login.config.character_login_single then
      me._locks.onLogin = true
      if not (IsCtrlKeyDown() and login.config.character_nologin_ctrl) then
        me._locks.loginChar = GetCharacterInfo(1);
        me._locks.loginTime = 0.5
        return
      end
    end
  end
  if char == nil and login.config.character_login_first and not me._locks.onLogin then
    me._locks.onLogin = true
    if not (IsCtrlKeyDown() and login.config.character_nologin_ctrl) then
      for _, data in ipairs(me.charlist) do
        if not data.destroy then
          me._locks.loginChar = data.name
          me._locks.loginTime = 0.5
          SelectCharacter(data.index)
          break
        end
      end
    end
    return
  end
  local autoLogin = true
  if type(char) == 'table' then
    char = (char[GetServerName()] or {})[1]
    char = string.match(char or '', '^([a-zA-Z0-9]+)')
    autoLogin = false
  elseif type(char) ~= 'string' then
    return
  end
  for i = 1, charNum do
    local name = GetCharacterInfo(i) or ""
    if name:lower() == char:lower() then
      SelectCharacter(i)
      if autoLogin then
        me._locks.loginChar = name
        me._locks.loginTime = 0.5
      end
      break
    end
  end
end
-- ! ==============================================================
-- ! ========================== init ==============================
-- ! ==============================================================
function me.initCharacterList()
  for id = 0, GetNumClasses() do
    local name, token = GetClassInfoByID(id)
    if name ~= '' then
      me.classes[name] = token
    end
  end
  local data = {
    col = {45, 155}, --
    fn = { --
      callback = me.charactersCallback, --
      onClick = me.charactersOnClick, --
    }, --
    numRow = 8, --
    rowHeight = 45, --
    noHead = true, --
    align = {0, 2}, --
  }
  LoginCharSelectFrame_chars:init(data)
  LoginCharSelectFrame_chars_list:SetBackdropTileAlpha(.5)
end
function me.initchannels()
  me.channel = login.config.channel or me.channel
  local data = {
    col = {20, 160, 20}, --
    fn = { --
      callback = me.channelsCallback, --
      onClick = me.channelsOnClick, --
    }, --
    numRow = 4, --
    noHead = true, --
  }
  LoginCharSelectFrame_channels:init(data)
  LoginCharSelectFrame_channels_list:SetBackdropTileAlpha(.5)
end

-- ! ==============================================================
-- ! ========================= update =============================
-- ! ==============================================================

function me.updateDeleteButton()
  if me.selected and GetNumCharacters() > 0 then
    local name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel = GetCharacterInfo(me.selected);
    LoginCharSelectFrame_delete:SetText(destroyTime and TEXT('CHARACTER_SELECT_RECOVER_DELETE') or TEXT('CHARACTER_SELECT_DELETE'))
    LoginCharSelectFrame_delete:Enable()
  else
    LoginCharSelectFrame_delete:Disable()
  end
end
local function sortCharacterList(a, b)
  if (a.peak ~= b.peak) then
    return a.peak > b.peak;
  end
  if a.lv ~= b.lv then
    return a.lv > b.lv
  end
  if a.seclv ~= b.seclv then
    return a.seclv > b.seclv
  end
  return a.name < b.name
end
function me.updateCharacterList()
  local imgpath = {
    'interface/widgeticons/classicon_%s.tga', --
    'interface/widgeticons/classicon_%s_%s.tga', --
  }
  me.charlist = {}
  for i = 1, GetNumCharacters() do
    local name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel = GetCharacterInfo(i);
    local mtag = me.classes[tostring(mc)]
    local stag = me.classes[tostring(sc)]
    local icon = string.format(imgpath[stag and 2 or 1], mtag, stag)
    table.insert(me.charlist, {
      index = i, name = name, lv = lv, seclv = seclv, mc = mc, sc = sc, zone = zone, destroy = destroyTime, peak = peakLevel, icon = icon,
    })
  end
  if login.config.character_sort then
    table.sort(me.charlist, sortCharacterList)
  end
  LoginCharSelectFrame_chars:update()
end
-- ! ==============================================================
-- ! ========================== list ==============================
-- ! ==============================================================

function me.channelsCallback()
  return me.channels, {}, me.channel
end
function me.channelsOnClick(frame, double, index)
  me.channel = index
  LoginCharSelectFrame_channels:update()
end
function me.charactersCallback(frame)
  local res = {}
  local selected = nil
  for index, data in pairs(me.charlist) do
    if data.index == me.selected then
      selected = index
    end
    local color = data.destroy and {.5, .5, .5} or nil

    local firstLine = data.name
    if data.peak > 0 then
      firstLine = string.format('%s (%d)', firstLine, data.peak)
    end
    local secondLine = string.format('%s %d', data.mc, data.lv)
    if data.seclv > 0 then
      secondLine = string.format('%s/%d %s', secondLine, data.seclv, data.sc)
    end
    local thirdLine = data.zone
    if data.destroy then
      local sec = data.destroy % 60
      local min = math.floor(data.destroy / 60) % 60
      local hour = math.floor(data.destroy / 60 / 60) % 60
      thirdLine = string.format('%02d:%02d:%02d', hour, min, sec)
    end
    local lines = {firstLine, secondLine, thirdLine}
    for index, text in ipairs(lines) do
      if text:len()>23 then
        lines[index] = text:sub(1, 21).."..."
      end
    end
    local text = string.format('%s\n%s\n%s', unpack(lines))
    table.insert(res, {{tex = data.icon}, {text = text, color = color}})
  end
  if #res < GetMaxCharacterCreate() then
    table.insert(res, {{tex = {file = 'interface/buttons/minimapplusbutton_normal', size = {20, 20}}}, TEXT('CHARACTER_SELECT_CREATE')});
  end
  return res, nil, selected
end

function me.charactersOnClick(frame, double, index)
  if login.campnext then
    login.campnext.cancel() -- picking by hand stops a queued /lnc switch
  end
  if index > #me.charlist then
    if double then
      return
    end
    login.GOTO('charcreate')
    return
  end
  me.selected = me.charlist[index].index
  SelectCharacter(me.selected)
  frame:update()
  if double or login.config.character_single_click then
    me.login()
  end
end

-- Up/Down walk the list as shown; Enter (OnEnterPressed) logs in
function me.move(delta)
  local count = #me.charlist
  if count == 0 then
    return
  end
  if login.campnext then
    login.campnext.cancel()
  end
  local pos = 0
  for i, data in ipairs(me.charlist) do
    if data.index == me.selected then
      pos = i
    end
  end
  pos = math.max(1, math.min(count, pos + delta))
  me.selected = me.charlist[pos].index
  SelectCharacter(me.selected)
  LoginCharSelectFrame_chars:scrollTo(pos)
  LoginCharSelectFrame_chars:update()
end
function me.onKeyDown(key)
  if key == 'UP' then
    me.move(-1)
  elseif key == 'DOWN' then
    me.move(1)
  end
end
login.charselect = me;
