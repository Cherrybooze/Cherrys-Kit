local me = {
    servers = {},--
    selected = nil--
}

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
  local data = {
    col = {30, 130, 30}, --
    fn = {
      callback = me.serverListCallback, --
      onClick = me.serverListOnClick, --
    }, --
    numRow = 10, --
    rowHeight = 30, --
    noHead = true,
  }
  LoginServerFrame_list:init(data)
  LoginServerFrame_list_list:SetBackdropTileAlpha(.5)
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
      isPvP = isPvP, --
      characters = characters, --
      isMaintain = isMaintain, --
      isLogin = isLogin, --
      load = load,
    })
  end
  table.sort(me.servers, sortServerList)
  me.selected = GetCurrentServerList()
  LoginServerFrame_list:update()
end

-- ! ==============================================================
-- ! ========================== list ==============================
-- ! ==============================================================

function me.serverListCallback(frame)
  local res = {}
  local selected = nil
  for index, data in pairs(me.servers) do
    if data.name == me.selected then
      selected = index
    end
    local charcount = data.characters
    local flag = 'Interface\\Flags\\' .. data.location
    local color = data.isMaintain and {.5, .5, .5} or nil
    table.insert(res, {{tex = flag}, {text = data.name, color = color}, tostring(charcount)})
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
