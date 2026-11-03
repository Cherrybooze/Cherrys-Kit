local me = {
    servers = {},--
    selected = nil--
}

-- The Modern look (template/skin.lua) is on
local function modern()
  return LoginLook and LoginLook.modern
end

function me.registerEvents(frame)
  frame:RegisterEvent('SERVER_LIST_UPDATE'); -- ?
  frame:RegisterEvent('OPEN_SERVER_LIST'); -- Serverliste anzeigen
end
function me.onLoad(this)
  me.initServerList()
end
function me.onEvent(event)
  return pcall(me[event], arg1, arg2, arg3, arg4)
end

-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.OPEN_SERVER_LIST()
  LoginAccount:SetText(GetAccountName())
  login.GOTO('server')

  local srv, auto = login.getAutoServer()
  if type(srv)=="string" then
    for i = 1, GetNumServerList() do
      local _, name =  GetServerListInfo(i)
      if string.lower(name or "")==srv:lower() then
        srv = name
      end
    end
  else
    srv = nil
  end
  me.selected = srv
  if auto then
    me.login()
  end
  LoginServerFrame_list:update()
end
function me.SERVER_LIST_UPDATE()
  me.updateServerList()
end
function me.show()
  LoginServerFrame:Show()
end
function me.hide()
  LoginServerFrame:Hide()
end

function me.login()
  ChangeServerList(me.selected)
end
-- ! ==============================================================
-- ! ========================== init ==============================
-- ! ==============================================================
function me.initServerList()
  local fn = {callback = me.serverListCallback, onClick = me.serverListOnClick}
  local data
  if modern() then
    -- flag, name, your characters there beside a helmet; as many rows as servers, up to 10
    data = {
      col = {36, 150, 58}, fn = fn, numRow = me.serverRows(), rowHeight = 28, noHead = true, align = {0, 2, 1}, --
      cells = {nil, {left = 4, right = 4}, {left = 2, right = 28, tex = {'RIGHT', -7, 0}}}, --
    }
  else
    data = {col = {30, 130, 30}, fn = fn, numRow = 10, rowHeight = 30, noHead = true}
  end
  LoginServerFrame_list:init(data)
  LoginServerFrame_list_list:SetBackdropTileAlpha(.5)
  me.placeButtons()
end

-- Modern: the server list at the right edge, the settings at the left (login.settings.lua).
-- Classic: in the middle, as login.server.xml has it.
function me.placeList()
  local list = LoginServerFrame_list
  list:ClearAllAnchors()
  if modern() then
    list:SetAnchor('RIGHT', 'RIGHT', LoginServerFrame, -10, -20)
  else
    list:SetAnchor('CENTER', 'CENTER', LoginServerFrame, 0, -20)
  end
end

-- Modern: Confirm and Cancel as wide as the list together, Record server a little below them.
-- Classic: as login.server.xml has them.
function me.placeButtons()
  me.placeList()
  local enter, cancel, record = LoginServerFrame_enter, LoginServerFrame_cancel, LoginServerFrame_settings
  local label = record:GetNormalText()
  enter:ClearAllAnchors()
  cancel:ClearAllAnchors()
  record:ClearAllAnchors()
  label:ClearAllAnchors()
  if modern() then
    local half = math.floor((LoginServerFrame_list_list:GetWidth() - 8) / 2)
    enter:SetSize(half, 24)
    cancel:SetSize(half, 24)
    enter:SetAnchor('TOPLEFT', 'BOTTOMLEFT', LoginServerFrame_list, 0, 6)
    cancel:SetAnchor('LEFT', 'RIGHT', enter, 8, 0)
    record:SetAnchor('TOPLEFT', 'BOTTOMLEFT', enter, 0, 8)
    label:SetAnchor('LEFT', 'RIGHT', record, 6, 0)
  else
    enter:SetSize(100, 20)
    cancel:SetSize(100, 20)
    enter:SetAnchor('TOPLEFT', 'BOTTOMLEFT', LoginServerFrame_list, 0, 5)
    cancel:SetAnchor('LEFT', 'RIGHT', enter, 10, 0)
    record:SetAnchor('TOPLEFT', 'BOTTOMLEFT', enter, 0, -5)
    label:SetAnchor('LEFT', 'RIGHT', record, 0, -1)
  end
end
function me.serverRows()
  return math.max(1, math.min(10, #me.servers))
end
function me.onSkin()
  if LoginServerFrame_list and LoginServerFrame_list.updateCallback then
    me.initServerList()
  end
end

-- ! ==============================================================
-- ! ========================= update =============================
-- ! ==============================================================
local function sortServerList(a, b)
  if (a.characters == b.characters) then
    return a.name < b.name
  else
    return a.characters > b.characters
  end
end
function me.updateServerList()
  me.servers = {}
  for i = 1, GetNumServerList() do
    local location, name, isPVP, characters, load, isMaintain, isLogin, flagText, isTop, isNew, limitNewAccount, illegalAge =
      GetServerListInfo(i);
    table.insert(me.servers, {
      name = name, --
      location = location, --
      isPvP = isPVP, --
      characters = characters, --
      isMaintain = isMaintain, --
      isLogin = isLogin, --
      load = load,
    })
  end
  table.sort(me.servers, sortServerList)
  me.selected = GetCurrentServerList()
  if modern() and LoginServerFrame_list.numRow ~= me.serverRows() then
    me.initServerList()
  else
    LoginServerFrame_list:update()
  end
end

-- ! ==============================================================
-- ! ========================== list ==============================
-- ! ==============================================================

function me.serverListCallback(frame)
  local res = {}
  local selected = nil
  local skin = modern() and LoginLook
  for index, data in pairs(me.servers) do
    if data.name == me.selected then
      selected = index
    end
    local charcount = data.characters
    local flag = 'Interface\\Flags\\' .. data.location
    local color = data.isMaintain and {.5, .5, .5} or nil
    if skin then
      local count = tonumber(charcount) or 0
      local c = skin.color
      table.insert(res, {
        -- a 3:2 flag fills the top two thirds of its square texture (measured on the game's screen)
        {tex = {file = flag, size = {24, 16}, coord = {0, 1, 0, .65625}}},
        {text = data.name, color = data.isMaintain and c.faint or nil},
        {text = tostring(count), color = count > 0 and c.text or c.faint,
          tex = {file = skin.MEDIA .. 'characters', size = {18, 18}, color = count > 0 and c.white or c.muted}},
      })
    else
      table.insert(res, {{tex = flag}, {text = data.name, color = color}, tostring(charcount)})
    end
  end
  return res, nil, selected
end

function me.serverListOnClick(frame, double, index, key, col_index, row, col)
  me.selected = me.servers[index].name
  frame:update()
  if double or login.config.server_single_click then
    me.login()
  end
end

-- Up/Down walk the list as shown; Enter (OnEnterPressed) joins
function me.move(delta)
  local count = #me.servers
  if count == 0 then
    return
  end
  local pos = 0
  for i, data in ipairs(me.servers) do
    if data.name == me.selected then
      pos = i
    end
  end
  pos = math.max(1, math.min(count, pos + delta))
  me.selected = me.servers[pos].name
  LoginServerFrame_list:scrollTo(pos)
  LoginServerFrame_list:update()
end
function me.onKeyDown(key)
  if key == 'UP' then
    me.move(-1)
  elseif key == 'DOWN' then
    me.move(1)
  end
end

login.server = me;
