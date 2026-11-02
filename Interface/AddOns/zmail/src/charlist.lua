local parent = zmail
local me = {
    events = {},
    privates = {},
}

function me.OnLoad()
    for event, fn in pairs(me.events) do
        local wait = nil
        if event=="MAIL_LOAD_CHARLIST" then
            wait = .5
        end
        parent.RegisterEventHandler(event, "zmail.charlist", fn, wait)
    end
end

function me.events.MAIL_LOAD_FILES()
    me.events.MAIL_LOAD_PRIVATE_CHARACTERS()
end
function me.events.MAIL_LOAD_CHARLIST(event, reset)
    me.LoadCharlist(reset)
end
function me.events.PARTY_MEMBER_CHANGED(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.ADD_FRIEND(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.RESET_FRIEND(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.DEL_FRIEND(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.ONLINE_FRIEND(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.UPDATE_GUILD_MEMBER(event)
    parent.SendEvent("MAIL_LOAD_CHARLIST")
end
function me.events.MAIL_LOAD_PRIVATE_CHARACTERS()
    local data = parent.loadFile("chars.lua")
    local temp = {}
    local server = GetServerName()
    if data[server] then
        for k, v in pairs(data[server]) do
            table.insert(temp, v)
        end
    end
    for k, v in pairs(data) do
        if type(v) ~= "table" then
            table.insert(temp, v)
        end
    end
    me.privates = nil
    me.privates = temp
    me.LoadCharlist()
end
function me.events.MAIL_CUSTOM_CHAR(event)
    for index, name in pairs(me.privates or {}) do
        if type(name) == "string" then
            me.Add(name, 1/(index + 1))
        elseif type(name) == "table" then
            me.Add(name[1], name[2])
        end
    end
    me.Add(UnitName("player"), 1)
end
function me.Get(name)
    return me.characterlist[name]
end
function me.Add(name, priority_type)
    name = type(name)=="string" and name:match("^%s*([^%s]+)%s*$") or nil
    if not name then return false end
    me.characterlist[name] = me.characterlist[name] or {}
    if type(priority_type) == "number" then
        me.characterlist[name].private = priority_type
    elseif type(priority_type) == "string" then
        me.characterlist[name][priority_type] = true
    elseif type(priority_type) == "table" then
        for key, value in pairs(priority_type) do
            me.characterlist[name][key] = value
        end
    end
    return true
end

local function parseTime(time)
    local d = time:match("(%d+)%s+d%s+")
    if d then
        return tonumber(d)
    end
    return 0
end
function me.LoadCharlist(reset)
    local saved = {}
    if not reset then
        for name, data in pairs(me.characterlist or {}) do
            if data.party then
                saved[name] = saved[name] or {}
                saved[name].party = data.party - 1
            end
        end
    end
    me.characterlist = nil
    me.characterlist = {}
    for name, data in pairs(saved) do
        me.characterlist[name] = data
    end
    parent.SendEvent("MAIL_CUSTOM_CHAR", me.Add)
    
    -- friends
    for i=1, GetFriendCount("Friend") do
        local name, _, online = GetFriendInfo("Friend", i)
        me.characterlist[name] = me.characterlist[name] or {}
        me.characterlist[name].online = online
        me.characterlist[name].friend = true
    end
    -- guild
    if IsInGuild() then
        local checkTime = parent.getCharlistConfig().NoOfflineGuildmemberAfter and parent.getCharlistConfig().NoOfflineGuildmemberAfter > 0 and parent.getCharlistConfig().NoOfflineGuildmemberAfter or false
        for i=1, GetNumGuildMembers() do
            local name, _, _, _, _, _, _, _, _, _, online, offlinetime = GetGuildRosterInfo(i)
            if not checkTime or parseTime(offlinetime) < checkTime then
                me.characterlist[name] = me.characterlist[name] or {}
                me.characterlist[name].online = online
                me.characterlist[name].guild = true
            end
        end
    end
    -- party
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        for i=1,36 do
            local name, online = GetRaidMember(i)
            if name and not UnitIsUnit("raid"..i, "player") then
                me.characterlist[name] = me.characterlist[name] or {}
                me.characterlist[name].online = online
                me.characterlist[name].party = 1
            end
        end
    end
    parent.SendEvent("MAIL_CHARLIST_UPDATE")
end

-------------------------------------
local frametypes = {
    'selected',
    'all',
    'private',
    'friend',
    'guild',
    'party',
}
local color = {
    selected ={0.94,1,1},
    all ={0.6,0.95,0.95},
    private={1,0.5,0.31},
    friend={1,0.73,0.06},
    guild={0.2,0.9,0},
    party={0.39,0.72,1},
}
local frames = {"Selected", "All", "Private", "Friend", "Guild", "Party"}
me.frame = {}

function me.frame.FrameUpdate(frame)
    local name = frame:GetName()
    for i,v in pairs(frames) do
        _G[name.."Lists"..v]:Update(true)
    end
end
function me.frame.FrameOnHide(this)
    local name = this:GetName()
    for i,v in pairs(frames) do
        _G[name.."Lists"..v]:Hide()
    end
end
function me.frame.FrameOnShow(this)
    local name = this:GetName()
    for i,v in pairs(frames) do
        _G[name.."Lists"..v]:Show()
    end
end
function me.frame.FrameSelect(frame, name, noUpdate)
    if name:len() < 4 then return false end
    if frame.selected[name] then return false end
    table.insert(frame.selected, name)
    frame.selected[name] = true
    if noUpdate then return true end
    frame:Update()
    return true
end
function me.frame.FrameDeselect(frame, name, noUpdate)
    if not frame.selected[name] then return false end
    for i,v in ipairs(frame.selected) do
        if v == name then
            table.remove(frame.selected, i)
        end
    end
    frame.selected[name] = nil
    if noUpdate then return true end
    frame:Update()
    return true
end
function me.frame.FrameReset(frame)
    frame.selected = nil
    frame.selected = {}
    local name = frame:GetName()
    for i,v in pairs(frames) do
        local list = _G[name.."Lists"..v]
        _G[list:GetName().."Search"]:SetText("")
    end
    frame:Update()
end
function me.frame.FrameGetSelected(frame)
    return frame.selected
end
function me.frame.FrameIsSelected(frame, name)
    return frame.selected[name]
end
function me.frame.FrameOnEntryClicked(frame, name, typ)
    name = name:gsub("%s", "")
    if not frame.selected[name] then
        frame:Select(name)
    else
        frame:Deselect(name)
    end
    return false
end
function me.frame.FrameOk(frame)
    frame:cbOnOk(frame:GetSelected())
end
function me.frame.FrameCancel(frame)
    frame:cbOnCancel()
end
function me.frame.FrameInitialize(frame, callback, show)
    frame.selected = nil
    frame.selected = {}
    frame.cbOnOk = callback.onOK
    frame.cbOnCancel = callback.onCancel

    local c = {
        onEntryClicked = function(...) return me.frame.FrameOnEntryClicked(frame, ...) end,
        isSelected = function(...) return frame:IsSelected(...) end,
        getSelected = function(...) return frame:GetSelected(...)  end,
    }
    local name = frame:GetName()
    for _,v in pairs(frames) do
        _G[name.."Lists"..v]:Init(c, show)
    end
    if show then
        frame:Show()
    end
    me.frame.FrameReset(frame)
end
function me.frame.FrameOnLoad(this)
    UIPanelBackdropFrame_SetTexture(this, "Interface/Common/PanelCommonBorder", 40, 40);
    this.Select = me.frame.FrameSelect
    this.Deselect = me.frame.FrameDeselect
    this.GetSelected = me.frame.FrameGetSelected
    this.IsSelected = me.frame.FrameIsSelected
    this.Reset = me.frame.FrameReset
    this.Init = me.frame.FrameInitialize
    this.Update = me.frame.FrameUpdate
    this.OK = me.frame.FrameOk
    this.Cancel = me.frame.FrameCancel
    local name = this:GetName()
    local lists = _G[name.."Lists"]
    local w = lists:GetWidth()
    local offsetwidth = 2
    local selectedoffset = 22
    w = w - offsetwidth*(#frames-1) - selectedoffset - 2
    local lw = math.floor(w/#frames) 
    for i,v in pairs(frames) do
        local list = _G[lists:GetName()..v]
        list:ClearAllAnchors()
        local offset = offsetwidth*(i-1) + 3
        if i > 1 then
            offset = offset + selectedoffset
        end
        list:SetAnchor("TOPLEFT", "TOPLEFT", list:GetParent(), lw*(i-1)+offset, 0)
        list:SetAnchor("BOTTOMRIGHT", "BOTTOMLEFT", list:GetParent(), lw*i+offset, 0)
        me.frame.ListOnLoad(list)
    end

    local Main = "ZMailFrameRecipients"
    _G[Main.."Reset"]:SetText(OBJ_RESET)
    _G[Main.."Add"]:SetText(CSTRING_ADD)
    _G[Main.."Cancel"]:SetText(C_CANCEL)
    _G[Main.."Ok"]:SetText(C_SURE)
    _G[Main.."ManualTitle"]:SetText(parent.GetLocaString("manual"))
end

function me.frame.ListInitialize(frame, callback, show)
    frame.callback = callback
    if not show then return end
    if frame:IsVisible() then
        frame:Update(true)
    else
        frame:Show()
    end
end
function me.frame.ListEntryOnClick(button)
    local btnid = button:GetID()
    local list = button:GetParent():GetParent()
    if list.callback.onEntryClicked(list.data[btnid]) then
        list:Update()
    end
    if #ZMailFrameRecipients.selected == 1 and not IsCtrlKeyDown() then
        me.frame.FrameOk(ZMailFrameRecipients)
    end
end
function me.frame.ListUpdateData(frame)
    frame.data = nil
    frame.data = {}
    local filter = _G[frame:GetName().."Search"]:GetText():gsub("%s", ""):lower()
    local typ = frame.type
    if typ == 'selected' then
        for _, v in ipairs(frame.callback.getSelected()) do
            if v:lower():match(filter) then
                table.insert(frame.data, v)
            end
        end
    else
        local function sortfn(a,b)
            local xa = me.characterlist[a] or {}
            local xb = me.characterlist[b] or {}
            local ta = xa[typ] or 0
            local tb = xb[typ] or 0
            if ta == tb or typ == 'all' then
                if not xa.online == not xb.online then
                    return a:lower() < b:lower()
                end
                return xa.online == true
            end
            return ta > tb
        end
        for name, data in pairs(me.characterlist) do
            if (typ=='all' or data[typ]) and name:lower():match(filter) then
                table.insert(frame.data, name)
            end
        end
        table.sort(frame.data, sortfn)
    end
    if not ZMailFrameBodySend:IsVisible() then
        local player = (UnitName("player") or ""):lower()
        for i, name in pairs(frame.data) do
            if name:lower() == player then
                table.remove(frame.data, i)
                break
            end
        end
    end
    local scrollbar = _G[frame:GetName().."ListScroll"]
    scrollbar:SetMinMaxValues(1, math.max(1, #frame.data - frame.entrycount + 1))
    frame:Update()
end
function me.frame.ListOnEvent(event, frame)
    frame:Update(true)
end
function me.frame.ListUpdate(frame, force)
    if not frame:IsVisible() then return end
    if force then
        me.frame.ListUpdateData(frame)
    end
    local list = frame:GetName().."List"
    local offset = math.max(0, _G[list.."Scroll"]:GetValue() - 1)
    local onlineColor = color[frame.type] or {1,1,1}
    local offlineColor = {.6,.6,.6}
    local conf = parent.getCharlistConfig().offlineColor
    if conf and type(conf) == "number" and conf <= 1 and conf >= 0 then 
        for i,v in pairs(onlineColor) do
            offlineColor[i] = v * conf
        end
    end
    for i=1, frame.entrycount do
        local entry = _G[list..i]
        local name = frame.data[i + offset]
        if not name then
            entry:Hide()
        else
            entry:SetID(i + offset)
            local data = me.characterlist[name] or {}
            entry:SetText(name, unpack(data.online and onlineColor or offlineColor))
            if frame.callback.isSelected(name) and frame.type ~= 'selected' then
                _G[entry:GetName().."Selected"]:Show()
            else
                _G[entry:GetName().."Selected"]:Hide()            
            end
            entry:Show()
        end
    end
end
function me.frame.ListSetEntryText(frame, text, r,g,b)
    local x = _G[frame:GetName().."Name"]
    x:SetText(text)
    x:SetColor(r or 1,g or 1,b or 1)
end
function me.frame.ListOnLoad(frame)
    frame.Update = me.frame.ListUpdate
    frame.Init = me.frame.ListInitialize
    
    local id = frame:GetID()
    local list = _G[frame:GetName().."List"]
    parent.RegisterEventHandler("MAIL_CHARLIST_UPDATE", frame:GetName(), me.frame.ListOnEvent, 1, {frame})
    frame.type = frametypes[id]

    _G[frame:GetName().."SearchTitle"]:SetText(parent.GetLocaString('list_'..frame.type))
    _G[frame:GetName().."SearchTitle"]:SetColor(unpack(color[frame.type] or {1,1,1}))

    UIPanelBackdropFrame_SetTexture(list, "Interface/Common/PanelCommonBorder", 40, 40)
    local height = list:GetHeight() - 5 
    for i=1,23 do 
        local entry = _G[list:GetName()..i]
        entry:Hide()
        if i*20+5 <= height then
            frame.entrycount = i
        end
        entry:ClearAllAnchors()
        entry:SetAnchor("TOPLEFT", "TOPLEFT", list, 5, (i-1)*20+8)
        entry:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", list, -10, i*20+8)
    end
end

parent.charlist = me
