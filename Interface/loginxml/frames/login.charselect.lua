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
me.NUMBER_WIDTH = 24 -- the character's number, from 1
me.ARROW_WIDTH = 20 -- Edit character order's up and down arrows

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

-- The columns, left to right: the number, class icon, three lines of text, gold (with Global Bank's data),
-- then the two arrows while Edit character order is on. Classic only adds the number and arrows while editing.
function me.characterColumns()
  local col, align, cells
  if modern() then
    -- the coin sits beside the gold's first line
    col, align = {me.NUMBER_WIDTH, 46, me.NAME_WIDTH}, {0, 0, 2}
    cells = {{left = 0, right = 0, size = 14}, nil, {left = 6, right = 4}}
    if me.goldColumn then
      col[4], align[4], cells[4] = me.GOLD_WIDTH, 1, {left = 2, right = 22, tex = {'TOPRIGHT', -4, 3}}
    end
  elseif me.editing() then
    col, align, cells = {22, 45, 155}, {0, 0, 2}, {{left = 0, right = 0}}
    if me.goldColumn then
      col[4], align[4] = 118, 1
    end
  else
    return me.goldColumn and {45, 155, 118} or {45, 155}, {0, 2, 1}, nil
  end
  if me.editing() then
    local n = #col
    col[n + 1], col[n + 2], align[n + 1], align[n + 2] = me.ARROW_WIDTH, me.ARROW_WIDTH, 0, 0
  end
  return col, align, cells
end

-- The arrows' column numbers while editing (after the number, icon, text and gold)
function me.arrowColumns()
  local before = me.goldColumn and 4 or 3
  return before + 1, before + 2
end

function me.listWidth()
  local width = 0
  for _, w in ipairs((me.characterColumns())) do
    width = width + w
  end
  return width
end

function me.layoutCharacterList()
  local fn = {callback = me.charactersCallback, onClick = me.charactersOnClick}
  local col, align, cells = me.characterColumns()
  local data = {col = col, align = align, cells = cells, fn = fn, noHead = true}
  if modern() then
    data.numRow, data.rowHeight = me.characterRows(), 46
  else
    data.numRow, data.rowHeight = 8, 45
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
    local width = me.listWidth()
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
-- ! ========================= order ==============================
-- ! ==============================================================
-- Each character's number, from 1: the order saved for this server with Edit character order (by name; it
-- can hold the server's other accounts' characters too), then any character it doesn't have, in the game's
-- own order. Next, Prev and /lnc <number> go by these numbers (CampNext_Login.lua, LOGCHAR_ORDER).

function me.editing()
  return login.config.character_order_edit and true or false
end

local function serverKey()
  return tostring(GetServerName and GetServerName() or '')
end

function me.savedOrder()
  local all = login.config.character_order
  local list = type(all) == 'table' and all[serverKey()]
  return type(list) == 'table' and list or nil
end

-- The game's character indexes, in number order
function me.order()
  local count = GetNumCharacters()
  local result, used = {}, {}
  local saved = me.savedOrder()
  if saved then
    local byName = {}
    for i = 1, count do
      local name = GetCharacterInfo(i)
      if name then
        byName[name] = i
      end
    end
    for _, name in ipairs(saved) do
      local i = byName[name]
      if i and not used[i] then
        used[i] = true
        table.insert(result, i)
      end
    end
  end
  for i = 1, count do
    if not used[i] then
      table.insert(result, i)
    end
  end
  return result
end

-- This account's names in their new order, in the places they had in the server's list; another
-- account's names keep theirs, and names the list didn't have go at the end
local function merge(saved, names)
  local mine, seen, result = {}, {}, {}
  for _, name in ipairs(names) do
    mine[name] = true
  end
  for _, name in ipairs(saved or {}) do
    if not seen[name] then
      seen[name] = true
      if mine[name] then
        table.insert(result, false) -- filled in below
      else
        table.insert(result, name)
      end
    end
  end
  for _, name in ipairs(names) do
    if not seen[name] then
      table.insert(result, false)
    end
  end
  local j = 0
  for i = 1, #result do
    if result[i] == false then
      j = j + 1
      result[i] = names[j]
    end
  end
  return result
end

function me.saveOrder(order)
  local names = {}
  for _, index in ipairs(order) do
    local name = GetCharacterInfo(index)
    if name then
      table.insert(names, name)
    end
  end
  local all = {}
  if type(login.config.character_order) == 'table' then
    for server, list in pairs(login.config.character_order) do
      all[server] = list
    end
  end
  all[serverKey()] = merge(all[serverKey()], names)
  login.settings.set('character_order', all)
end

-- Edit character order: one number up (-1) or down (1)
function me.moveCharacter(index, delta)
  local order = me.order()
  local from
  for pos, i in ipairs(order) do
    if i == index then
      from = pos
    end
  end
  local to = from and from + delta
  if not to or to < 1 or to > #order then
    return
  end
  order[from], order[to] = order[to], order[from]
  me.saveOrder(order)
  me.updateCharacterList()
  LoginCharSelectFrame_chars:scrollTo(to)
  LoginCharSelectFrame_chars:update()
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
  for pos, i in ipairs(me.order()) do
    local name, sex, lv, mc, seclv, sc, zone, destroyTime, peakLevel = GetCharacterInfo(i);
    local mtag = me.classes[tostring(mc)]
    local stag = me.classes[tostring(sc)]
    local icon = string.format(imgpath[stag and 2 or 1], mtag, stag)
    table.insert(me.charlist, {
      index = i, pos = pos, name = name, lv = lv, seclv = seclv, mc = mc, sc = sc, zone = zone, destroy = destroyTime, peak = peakLevel, icon = icon,
    })
  end
  -- while editing the order, the list shows it
  if login.config.character_sort and not me.editing() then
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
  local row = {{text = tostring(data.pos or ''), color = skin.color.cyan}, {tex = {file = data.icon, size = {34, 34}}},
    {text = text}}
  if me.goldColumn then
    local known = login.globalbank.character(data.name)
    if known then
      local gold, charges, saved = login.globalbank.parts(known)
      -- always three lines, so the coin stays beside the first
      row[4] = {
        text = string.format('|cff%s%s|r%s\n|cff%s%s|r\n|cff%s%s|r', hex.gold, gold, known.unsure and ' ?' or '',
          hex.dim, charges and 'Charges ' .. charges or ' ', hex.faint, saved),
        tex = {file = skin.MEDIA .. 'coin', size = {15, 15}},
      }
    else
      row[4] = ''
    end
  end
  return row
end

-- Edit character order's arrows, dimmed where the character can't go further
local ARROWS = {
  modern = {up = 'arrow_up', down = 'arrow_down'},
  classic = {up = 'interface/buttons/scrollbar-upbutton-normal', down = 'interface/buttons/scrollbar-downbutton-normal'},
}
local function arrow(skin, which, can)
  if skin then
    return {tex = {file = skin.MEDIA .. ARROWS.modern[which], size = {14, 14}, color = can and skin.color.dim or skin.color.faint}}
  end
  return {tex = {file = ARROWS.classic[which], size = {18, 18}, color = can and {1, 1, 1} or {.4, .4, .4}}}
end

function me.charactersCallback(frame)
  local res = {}
  local selected = nil
  local skin = modern() and LoginLook
  local editing = me.editing()
  local up, down = me.arrowColumns()
  for index, data in pairs(me.charlist) do
    if data.index == me.selected then
      selected = index
    end
    local row
    if skin then
      row = me.modernRow(data, skin)
    else
      row = me.classicRow(data)
      if editing then
        table.insert(row, 1, tostring(data.pos or ''))
      end
    end
    if editing then
      row[up] = arrow(skin, 'up', index > 1)
      row[down] = arrow(skin, 'down', index < #me.charlist)
    end
    table.insert(res, row)
  end
  if #res < GetMaxCharacterCreate() then
    local row
    if skin then
      row = {'', {tex = {file = skin.MEDIA .. 'plus', size = {20, 20}}},
        {text = TEXT('CHARACTER_SELECT_CREATE'), color = skin.color.dim}}
    else
      row = {{tex = {file = 'interface/buttons/minimapplusbutton_normal', size = {20, 20}}}, TEXT('CHARACTER_SELECT_CREATE')}
      if editing then
        table.insert(row, 1, '')
      end
    end
    if me.goldColumn then
      row[#row + 1] = ''
    end
    if editing then
      row[up], row[down] = '', ''
    end
    table.insert(res, row)
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

function me.charactersOnClick(frame, double, index, key, col)
  if login.campnext then
    login.campnext.cancel() -- picking by hand stops a queued /lnc switch
  end
  if me.editing() and index <= #me.charlist then
    local up, down = me.arrowColumns()
    if col == up or col == down then
      me.moveCharacter(me.charlist[index].index, col == up and -1 or 1)
      return
    end
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
  local delta = (key == 'UP' and -1) or (key == 'DOWN' and 1) or nil
  if not delta then
    return
  end
  -- Shift moves the selected character's number while Edit character order is on
  if me.editing() and me.selected and IsShiftKeyDown() then
    me.moveCharacter(me.selected, delta)
  else
    me.move(delta)
  end
end
login.charselect = me;
