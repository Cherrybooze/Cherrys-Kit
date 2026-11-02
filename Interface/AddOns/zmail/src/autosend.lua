local parent = zmail
local me = {
    data = {
        fullrecipients = {},
        lastRecipient = nil,
    },
    events = {},
    entries = {},
    timeout = 0,
    active = false,
    loaded = false,
    settings = {},
    ui = {},
}

local checkvars = {
    "disabled",
    "blacklist",
}
function me.settings.disabled(val)
    local conf = parent.getAutoSendConfig()
    conf.disabled = val and true or false
    ZMailFrameBodyAutoSendSettingsDisabled:SetChecked(conf.disabled)
end
function me.settings.blacklist(val)
    local conf = parent.getAutoSendConfig()
    if type(val) == "table" then
        val = conf.blacklist[UnitName("player")]
    end
    conf.blacklist[UnitName("player")] = val and true or nil
    ZMailFrameBodyAutoSendSettingsBlacklisted:SetChecked(val)
end

function me.settings.OnCheckClick(this)
    local id = this:GetID()
    assert(checkvars[id] and me.settings[checkvars[id]])
    me.settings[checkvars[id]](this:IsChecked())
end

function me.settings.OnCheckEnter(this)
    local id = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
    GameTooltip:SetText(parent.GetLocaString("AutoSendCheckTT"..id))
end

function me.settings.init()
    local conf = parent.getAutoSendConfig()
    for _, key in pairs(checkvars) do
        me.settings[key](conf[key])
    end
end

function me.events.MAIL_BAG_ITEM_UPDATE(_, type, real, bag)
    if me.active then
        me.select(real)
    end
end

function me.events.MAIL_ON_SHOW()
    if not me.loaded then
        me.loadFiles()
    end
    local config = parent.getAutoSendConfig()
    if config.disabled then
        parent.debug.debug("autosend is disabled")
        return
    end
    if (config.blacklist or {})[UnitName("player")] then
        parent.debug.debug("Current player is blacklisted -> no autosend")
        return
    end
    me.start()
end

function me.events.MAIL_ON_HIDE()
    me.stop()
end

function me.SetStatus(t, err, ...)
    if err == true then
        err = me.lastError
    else
        me.lastError = {t, err, ...}
    end
    parent.SetStatus(unpack(me.lastError or {10}))
end


function me.start()
    if parent.isAutoSend() then
        return false
    end
    me.SetStatus(10, nil)
    parent.setAutoSend("as")
    me.sendMail(true)
    me.active = true
end
function me.stop()
    me.SetStatus(2, nil)
    me.active = false
    if parent.isAutoSend() == "as" then
        parent.stopAutoSend()
    end
end

function me.Register(ident, recipients, items)
    return me.Register2(ident, {recipients=recipients, items=items})
end
function me.Register2(ident, entry)
    local selftarget = false
    for _, name in pairs(entry.recipients) do
        if name:gsub(" ",""):lower() == UnitName("player"):lower() then
            parent.debug.debug(string.format("filter(%s) not added: only filters with other characters permitted", tostring(ident)))
            selftarget = true
        end
    end
    local data = {
        ident = ident,
        selftarget = selftarget,
        name = entry.name or ident,
        recipients = entry.recipients,
        disabled = entry.disabled,
        itemfns = {},
        itemids = {},
    }
    for _, item in pairs(entry.items) do
        if type(item) == "string" then
            local fn = parent.itemfn.functions[item]
            if not fn then
                parent.debug.warn(string.format("Unknown function %s", key))
                return false
            end
            table.insert(data.itemfns, {fn.fn, {}})
        elseif type(item) == "function" then
            table.insert(data.itemfns, {item, {}})
        elseif type(item) == "number" then
            data.itemids[item] = {}
        elseif type(item) == "table" then
            if item.id then
                data.itemids[item.id] = item
            elseif item.key then
                local fn = parent.itemfn.functions[item.key]
                if not fn then
                    parent.debug.warn(string.format("Unknown function %s", item.key))
                    return false
                end
                table.insert(data.itemfns, {fn.fn, item})
            elseif item.fn then
                table.insert(data.itemfns, {item.fn, item})
            end
        end
    end
    table.insert(me.entries, data)
    return true
end

function me.events.ITEMFN_UPDATE()
    me.loadFiles()
end

function me.loadFiles()
    if UnitName("player") == nil or not parent.itemfn.loaded then
        return
    end
    me.loaded = true
    parent.SendEvent("REGISTER_AUTOSEND_ENTRIES", me.Register, parent.itemfn.GetFunction, parent.itemfn.GetHelper)
    local data = parent.loadFile("autosend.lua", nil, nil, parent.itemfn.GetFunction, parent.itemfn.GetHelper)
    for index, entry in pairs(data) do
        if not entry.ignore then
            me.Register2(index, entry)
        end
    end
    me.ListUpdate()
end

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.autoSend", fn)
    end
    me.ui.init()
end

function me.ui.init()
    -- list
    for i=1,19 do
        local frame = _G["ZMailFrameBodyAutoSendList"..i]
        frame:ClearAllAnchors()
        frame:SetID(i)
        frame:SetAnchor("TOPLEFT", "TOPLEFT", "ZMailFrameBodyAutoSendList", 5, 10+(i-1)*25)
        frame:SetBackdropTileAlpha( i % 2 == 0 and 0.1 or 0.2)
    end
    local settings = "ZMailFrameBodyAutoSendSettings"
    _G[settings.."DisabledLabel"]:SetText("> Disabled")
    _G[settings.."BlacklistedLabel"]:SetText(">Blacklisted")
end
function me.OnShow()
    me.settings.init()
    me.ListUpdate()
end
function me.testItem(def, real, data)
    if data.count > 32000 then
        return false
    end
    if type(def.count) == "number" and data.count ~= def.count then
        return false
    elseif type(def.count) == "function" and not def.count(data.count, real, data) then
        return false
    end
    return true
end

function me.select(real)
    for _, entry in pairs(me.entries) do
        if not entry.disabled and not entry.selftarget then
            local data = parent.bag.GetData(real)
            if data and data.mode % 2 == 1 and not parent.bag.IsDisabled(real) then
                for _, fn in pairs(entry.itemfns) do
                    if fn[1](real, data, parent.bag) and me.testItem(fn[2], real, data) then
                        return entry.recipients
                    end
                end
                if entry.itemids[data.id] and me.testItem(entry.itemids[data.id], real, data) then
                    return entry.recipients
                end
            end
        end
    end
end

function me.selectNext(typ)
    local s, e = 0,0
    if typ == 'bag' or typ == nil then
        s,e = 61,240
    elseif typ == 'is' then
        s,e = 1, 50
    elseif typ == 'tm' then
        s,e = 51,60
    end
    for real = s, e do
        local recipients = me.select(real)
        if recipients then
            return real, recipients
        end
    end
end


function me.sendMail(success)
    if success  then
        me.data.lastItem = nil
    elseif me.data.lastRecipient then
        if parent.lastMsg == TEXT("SYS_SENDMAIL_TARGET_MAILFULL") then
            me.data.fullrecipients[me.data.lastRecipient] = GetTime() + 60
        elseif parent.lastMsg == TEXT("SYS_SENDMAIL_TARGET_ERROR") then
            me.data.fullrecipients[me.data.lastRecipient] = GetTime() + 3600
        else
            me.timeout = GetTime() + 60
            me.stop()
            return false
        end
    else
        me.stop()
        return false
    end

    if CursorHasItem() then
        me.stop()
        me.SetStatus(2, parent.GetLocaString("cursoritem"), 1,0.5,0)
        return false
    end

    me.data.lastRecipient = nil
    local real, recipients = me.selectNext()
    if not real then
        me.stop()
        return false
    end
    for _, recipient in pairs(recipients) do
        if (me.data.fullrecipients[recipient] or 0) < GetTime() then
            me.data.lastRecipient = recipient
            break
        end
    end
    if not me.data.lastRecipient then
        me.stop()
        return false
    end

    if not me.data.lastItem then
        me.data.lastItem = real
        PickupBagItem(real)
        ClickSendMailItemButton(1)
    end

    local _, _, name, count, _, _ = parent.bag.GetItem(real)
    local data = parent.bag.GetData(real)
    if data and data.id then
        name = ("[%d]"):format(data.id)
    end

    
    me.SetStatus(2, string.format("%d %s -> %s", count, GetReplaceSystemKeyword(name), me.data.lastRecipient))

    local subject = count > 1 and string.format(parent.GetLocaString("subject"), count, name) or name
    SendMail(me.data.lastRecipient, subject , parent.GetLocaString("zmailbrand"))
    return true
end

function me.ListOnMouseWheel(this, delta)
    ZMailFrameBodyAutoSendListScroll:SetValue(ZMailFrameBodyAutoSendListScroll:GetValue()- delta/120)
end
function me.ListOnClick(this)
    local id = this:GetID()
    local data = me.entries[id]
    if not data then 
        return 
    end
    data.disabled = not data.disabled
    me.ListUpdate()
end

function me.ListOnEnter(this, notooltip)
    local id = this:GetID()
    _G[this:GetName().."Highlight"]:Show()

    if notooltip then return end
    local data = me.entries[id]
    if not data then 
        return 
    end
    if data.name then
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", -5, 0);
        GameTooltip:SetText(data.name)
        for _, name in pairs(data.recipients) do
            local d = me.data.fullrecipients[name] or 0
            local t = GetTime()
            if d > t then
                GameTooltip:AddLine(string.format("%s: %0.2fs", name, d - t), 1,0,0)
            else
                GameTooltip:AddLine(name)
            end
        end
    end
end
function me.ListOnLeave(this)
    _G[this:GetName().."Highlight"]:Hide()
	GameTooltip:Hide();
end
function me.ListUpdate()
    ZMailFrameBodyAutoSendListScroll:SetMinMaxValues(1, #me.entries)
    for i=1, 19 do
        local name = "ZMailFrameBodyAutoSendList"..i
        local frame = _G[name]
        local index = i + ZMailFrameBodyAutoSendListScroll:GetValue() - 1
        local data = me.entries[index]
        if data then
            frame:Show()
            frame:SetID(index)
            _G[name.."Name"]:SetText(data.name)
            if data.selftarget then
                _G[name.."Name"]:SetColor(1,0,0)
            else
                _G[name.."Name"]:SetColor(1,1,1)
            end
            _G[name.."Enabled"]:SetChecked(not data.disabled)
        else
            frame:Hide()
        end
    end
end

parent.autosend = me
-- /run zmail.autosend.start()
-- /run zmail.autosend.selectAll()
