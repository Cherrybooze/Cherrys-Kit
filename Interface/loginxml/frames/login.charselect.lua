-- local _,y = loadfile("interface/loginxml/frames/login.charselect.lua") lprint(y) 
local me = { --
  charlist = {}, --
  channels = {}, -- rows for the channel list, in the look in use
  zones = {}, -- the channels: name and load (1 low .. 3 full)
  classes = {}, --
  selected = nil, --
  channel = 1, -- overwritten by config
  _locks = {},
}

-- The Modern look (template/skin.lua) is on
local function modern()
  return LoginLook and LoginLook.modern
end

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
  me.zones = {}
  for i = 1, GetNumParalleZones() do
    local name, load = GetParalleZonesInfo(i)
    table.insert(me.zones, {name = name, load = load})
  end
  me.buildChannels()
  if modern() and LoginCharSelectFrame_channels.numRow ~= me.channelRows() then
    me.layoutChannels()
  else
    LoginCharSelectFrame_channels:update();
  end
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
  -- Room for gold only for players with Global Bank's data
  me.goldColumn = login.globalbank and login.globalbank.read()
  me.layoutCharacterList()
end
function me.initchannels()
  me.channel = login.config.channel or me.channel
  me.layoutChannels()
end

-- Modern column widths: "Champion 100 / Warlock 100" and "2026-11-02 23:08" each fit on one line
me.NAME_WIDTH = 172
me.GOLD_WIDTH = 130

-- Modern: as many rows as there are characters and the Create row, up to 8; Classic always shows 8
function me.characterRows()
  local count = #me.charlist
  if count < GetMaxCharacterCreate() then
    count = count + 1
  end
  return math.max(1, math.min(8, count))
end
function me.channelRows()
  return math.max(1, math.min(4, #me.zones))
end

function me.layoutCharacterList()
  local fn = {callback = me.charactersCallback, onClick = me.charactersOnClick}
  local data
  if modern() then
    data = {
      col = {46, me.NAME_WIDTH, me.goldColumn and me.GOLD_WIDTH or nil}, --
      fn = fn, numRow = me.characterRows(), rowHeight = 46, noHead = true, --
      align = {0, 2, 1}, --
      -- class icon, three lines of text, gold with the coin beside its first line
      cells = {nil, {left = 6, right = 4}, {left = 2, right = 22, tex = {'TOPRIGHT', -4, 3}}}, --
    }
  else
    data = {
      col = me.goldColumn and {45, 155, 118} or {45, 155}, --
      fn = fn, numRow = 8, rowHeight = 45, noHead = true, --
      align = {0, 2, 1}, --
    }
  end
  LoginCharSelectFrame_chars:init(data)
  LoginCharSelectFrame_chars_list:SetBackdropTileAlpha(.5)
  -- Modern leaves a little room between the two lists and above the Delete button
  local gap = modern() and 6 or 0
  LoginCharSelectFrame_channels:ClearAllAnchors()
  LoginCharSelectFrame_channels:SetAnchor('BOTTOM', 'TOP', LoginCharSelectFrame_chars, 0, -gap)
  LoginCharSelectFrame_delete:ClearAllAnchors()
  if modern() then
    -- centred on the list itself; the frame keeps room on the right for the scroll bar
    LoginCharSelectFrame_delete:SetAnchor('TOP', 'BOTTOM', LoginCharSelectFrame_chars_list, 0, gap)
  else
    LoginCharSelectFrame_delete:SetAnchor('TOP', 'BOTTOM', LoginCharSelectFrame_chars, 0, 0)
  end
  me.layoutChannels()
end

-- Modern: a dot in the channel's load colour and its name, as wide as the character list
function me.layoutChannels()
  local fn = {callback = me.channelsCallback, onClick = me.channelsOnClick}
  local data
  if modern() then
    local width = 46 + me.NAME_WIDTH + (me.goldColumn and me.GOLD_WIDTH or 0)
    data = {col = {26, width - 26}, fn = fn, numRow = me.channelRows(), rowHeight = 22, noHead = true, align = {0, 2},
      cells = {nil, {left = 2}}}
  else
    data = {col = {20, 160, 20}, fn = fn, numRow = 4, noHead = true}
  end
  LoginCharSelectFrame_channels:init(data)
  LoginCharSelectFrame_channels_list:SetBackdropTileAlpha(.5)
end

local LOAD = {'green', 'yellow', 'red'}
local LOAD_MODERN = {'green', 'gold', 'red'}
function me.buildChannels()
  me.channels = {}
  local skin = modern() and LoginLook
  for _, zone in ipairs(me.zones) do
    if skin then
      local dot = {file = skin.MEDIA .. 'dot', size = {8, 8}, color = skin.color[LOAD_MODERN[zone.load] or 'quiet']}
      table.insert(me.channels, {{tex = dot}, zone.name})
    else
      local tex = string.format('interface/buttons/uiindex%s-normal', LOAD[zone.load] or 'green')
      table.insert(me.channels, {{tex = tex}, zone.name, {tex = tex}})
    end
  end
end

-- The Modern look switched on or off: lay both lists out again
function me.onSkin()
  if not (LoginCharSelectFrame_chars and LoginCharSelectFrame_chars.updateCallback) then
    return
  end
  me.buildChannels()
  me.layoutCharacterList()
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
  if login.globalbank then
    login.globalbank.read()
  end
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
  if modern() and LoginCharSelectFrame_chars.numRow ~= me.characterRows() then
    me.layoutCharacterList()
  else
    LoginCharSelectFrame_chars:update()
  end
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
local function shorten(text, max)
  if text:len() > max then
    return text:sub(1, max - 2) .. '...'
  end
  return text
end

local function deleteTimer(seconds)
  local sec = seconds % 60
  local min = math.floor(seconds / 60) % 60
  local hour = math.floor(seconds / 60 / 60) % 60
  return string.format('%02d:%02d:%02d', hour, min, sec)
end

-- Modern row: name (peak level dimmed), classes and levels, zone or the delete timer in red;
-- gold in gold beside a coin, charges, when Global Bank saved it
function me.modernRow(data, skin)
  local hex = skin.hex
  local name = shorten(data.name, 20)
  if data.destroy then
    name = string.format('|cff%s%s|r', hex.faint, name)
  end
  if (tonumber(data.peak) or 0) > 0 then
    name = string.format('%s |cff%s(%d)|r', name, hex.dim, data.peak)
  end
  local classes = string.format('%s %d', data.mc, data.lv)
  if data.seclv > 0 then
    classes = string.format('%s / %s %d', classes, data.sc, data.seclv)
  end
  local last = data.destroy and string.format('|cff%s%s|r', hex.red, deleteTimer(data.destroy))
    or string.format('|cff%s%s|r', hex.faint, shorten(data.zone or '', 26))
  local text = string.format('%s\n|cff%s%s|r\n%s', name, hex.dim, shorten(classes, 26), last)
  local row = {{tex = {file = data.icon, size = {34, 34}}}, {text = text}}
  if me.goldColumn then
    local known = login.globalbank.character(data.name)
    if known then
      local gold, charges, saved = login.globalbank.parts(known)
      -- always three lines, so the coin stays beside the first
      row[3] = {
        text = string.format('|cff%s%s|r%s\n|cff%s%s|r\n|cff%s%s|r', hex.gold, gold, known.unsure and ' ?' or '',
          hex.dim, charges and 'Charges ' .. charges or ' ', hex.faint, saved),
        tex = {file = skin.MEDIA .. 'coin', size = {15, 15}},
      }
    else
      row[3] = ''
    end
  end
  return row
end

function me.charactersCallback(frame)
  local res = {}
  local selected = nil
  local skin = modern() and LoginLook
  for index, data in pairs(me.charlist) do
    if data.index == me.selected then
      selected = index
    end
    if skin then
      table.insert(res, me.modernRow(data, skin))
    else
      table.insert(res, me.classicRow(data))
    end
  end
  if #res < GetMaxCharacterCreate() then
    if skin then
      table.insert(res, {{tex = {file = skin.MEDIA .. 'plus', size = {20, 20}}},
        {text = TEXT('CHARACTER_SELECT_CREATE'), color = skin.color.dim}, me.goldColumn and '' or nil})
    else
      table.insert(res, {{tex = {file = 'interface/buttons/minimapplusbutton_normal', size = {20, 20}}}, TEXT('CHARACTER_SELECT_CREATE'), me.goldColumn and '' or nil});
    end
  end
  return res, nil, selected
end

function me.classicRow(data)
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
      thirdLine = deleteTimer(data.destroy)
    end
    local lines = {firstLine, secondLine, thirdLine}
    for index, text in ipairs(lines) do
      if text:len()>23 then
        lines[index] = text:sub(1, 21).."..."
      end
    end
    local text = string.format('%s\n%s\n%s', unpack(lines))
    local row = {{tex = data.icon}, {text = text, color = color}}
    if me.goldColumn then
      local known = login.globalbank.character(data.name)
      row[3] = known and {text = login.globalbank.describe(known), color = color} or ''
    end
    return row
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
