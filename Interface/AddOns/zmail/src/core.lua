local me = {
    path = "interface/addons/zmail",
    events = {},
    frames = {},
    template = {},
    config = nil
}

local default = { --don't edit here... look at data/config.lua
    ShowMinimapButton = false,
    inbox = {
        -- ui settings
        takeanddelete = true,       -- delete mail after taking items
        autoStop = true,            -- stop when bag is full
        enableTakeCOD = false,      -- enable take of cod items without confirmation check
        autoTakeCODMax = 6,         -- max price for enableTakeCOD
        minfreeslot = 5,            -- min number of free slots in bag
        autoRefresh = true,         -- refresh inbox on new mail
        continueAfterReload = false, -- continue taking after reload
        selectRadio = "all",        --"all", "item", "gold"
    },
    send = {
        autoSelectRecipients = false, --Setzt beim öffnen von ZMail automatisch den Focus in das jeweilige Empfänger-Feld
        onlyWhenEmpty = true, --Tut dies nur, wenn das Empfänger-Feld zuvor leer war
        ignoreIfSelf = true, --Gruppenverkaufsoption: wenn man selbst im Empfänger-Feld steht, erscheint kein Fehler, sondern Gold was anteilig an einen selbst verschickt werden würde, wird stattdessen nicht versand
        withholdMoney = 0, --Gruppenverkaufsoption: Summe an Gold, die bei mehreren Empfängern nicht verschickt werden soll (z.B.: Gesamtsumme 500kk, withholdMoney = 10000000 -> 490kk werden auf die Empfänger aufgeteilt)
    },
    charlist = {
        offlineColor = false,
        NoOfflineGuildmemberAfter = 30,
    },
    debug = {
        level = 2,
    },
    msi = {
        autoReset = false,
    },
}

function me.FormatNumber(number)
	local _, _, minus, int = tostring(number):find('([-]?)(%d+)')
	if not minus then
		return number
	end
	int = int:reverse():gsub("(%d%d%d)", "%1.")
	return minus .. int:reverse():gsub("^%.", "")
end

if not UseItemByID then
    function UseItemByID(id)
        UseItemByName(GetObjName(id))
    end
end

function me.getConfig()
    me.config = me.config or default or {}
    return me.config
end
function me.getDebugConfig()
    local conf = me.getConfig()
    conf.debug = conf.debug or {}
    return conf.debug
end
function me.getInboxConfig()
    local conf = me.getConfig()
    conf.inbox = conf.inbox or {}
    return conf.inbox
end
function me.getCharlistConfig()
    local conf = me.getConfig()
    conf.charlist = conf.charlist or {}
    return conf.charlist
end
function me.getSendConfig()
    local conf = me.getConfig()
    conf.send = conf.send or {}
    return conf.send
end
function me.getAutoSendConfig()
    local conf = me.getConfig()
    conf.autosend = conf.autosend or {}
    return conf.autosend
end

function me.getMSIConfig()
    local conf = me.getConfig()
    conf.msi = conf.msi or {}
    return conf.msi
end

-- Utility:
local schedule = {}
function me.ScheduleKeep(key, ...)
    if schedule[key] then
        return
    end
    me.Schedule(key, ...)
end
function me.Schedule(key, time, fn, ...)
    if not time or not fn then
        schedule[key] = nil
    else
        local _time = GetTime()
        schedule[key] = {_time + time, fn, {...}}
    end
end
function me.OnUpdate(this, elapsed)
    local time = GetTime()
    local remove = {}
    for key, data in pairs(schedule) do
        if data[1] <= time then
            local success, msg = pcall(data[2], unpack(data[3]))
            if not success then
                pcall(me.debug.warn, string.format("OnUpdate (%s) - %s", key, msg))
            end
            if schedule[key][1] == data[1] then
                table.insert(remove, key)
            end
        end
    end
    for _, key in pairs(remove) do
        schedule[key] = nil
    end
end
local eventHandler = {}
function me.RegisterEventHandler(event, key, fn, wait, args)
    if type(fn)~="function" then
        if eventHandler[event] then
            eventHandler[event][key] = nil
        end
        return
    end
    ZMailFrame:RegisterEvent(event)
    if not eventHandler[event] then 
        eventHandler[event] = {}
    end
    eventHandler[event][key] = {fn, wait, args}
end
function me.SendEvent(event, ...)
    if not eventHandler[event] then return end
    for key, data in pairs(eventHandler[event]) do
        local fn, wait, customArgs = unpack(data)
        local args = {fn, event, ...}
        if customArgs then
            for index, v in pairs(customArgs) do
                table.insert(args, 2+index, v)
            end
        end
        if wait then
            me.ScheduleKeep("OnEvent"..event..key, wait, unpack(args))
        else
            local success, msg = pcall(unpack(args))
            if not success then
                me.debug.warn(string.format("SendEvent (%s:%s) - %s", tostring(key), tostring(event), tostring(msg)))
            end
        end
    end
end
function me.OnEvent(this, event, ...)
    me.SendEvent(event, ...)
end

function me.OnLoad(this)
    local events = {
        "MAIL_SHOW",
        "MAIL_INBOX_UPDATE",
        "MAIL_CLOSED",
        "MAIL_SEND_INFO_UPDATE",
        "MAIL_SEND_SUCCESS",
        "MAIL_FAILED",
        "CLOSE_INBOX_ITEM",
    }
    for _, event in pairs(events) do
        MailFrame:UnregisterEvent(event)
    end
    MailFrame:Hide()
    for event, fn in pairs(me.events) do
        me.RegisterEventHandler(event, "zmail", fn)
    end
    PanelTemplates_SetNumTabs(this, 4)
    ZMailFrameTab1:SetText(me.GetLocaString("tab1"))
    ZMailFrameTab2:SetText(me.GetLocaString("tab2"))
    ZMailFrameTab3:SetText(me.GetLocaString("tab3"))
    ZMailFrameTab4:SetText(me.GetLocaString("tab4"))
    PanelTemplates_TabResize(ZMailFrameTab1, 30);
    PanelTemplates_TabResize(ZMailFrameTab2, 30);
    PanelTemplates_TabResize(ZMailFrameTab3, 30);
    PanelTemplates_TabResize(ZMailFrameTab4, 30);

    --------------------
    local composer = "ZMailFrameBodySendComposer"
    _G[composer.."Reset"]:SetText(KDF_CLEAR)
    _G[composer.."Send"]:SetText(MAIL_MAILSENT)
    _G[composer.."HeaderRecipientButton"]:SetText(MAIL_ADDRESSEE_COLON)
    _G[composer.."HeaderSubjectLabel"]:SetText(MAIL_SUBJECT_COLON)

    _G[composer.."FooterAttachmentLabel"]:SetText(MAIL_SENTITEM_COLON)
    _G[composer.."FooterOptionMoneyLabel"]:SetText(MONEY_GOLD)
    _G[composer.."FooterOptionCODLabel"]:SetText(MAIL_COD)
    ZMailFrameStop:SetText(me.GetLocaString("stop"))
    me.send.reset()

    for _, data in pairs(me) do
        if type(data)== "table" and type(data.OnLoad) == "function" then
            pcall(data.OnLoad)            
        end
    end
end
function me.MinimapButton_CheckConfig()
    local MMB = ZMailFrame_MinimapButton
    if me.getConfig().ShowMinimapButton then
        MMB:Show()
    else
        MMB:Hide()
    end
end
function me.OnShow(this)
    ZMailFrame_MinimapButtonFlash:Hide()
    me.stopAutoSend()
    me.SelectTab(1)
    me.SendEvent("MAIL_ON_SHOW")
end
function me.OnHide(this)
    me.SendEvent("MAIL_ON_HIDE")
    CloseMail()
    me.stopAutoSend()
    if UMMFrame then
        MailFrame:Hide()
        UMMFrame:Hide()
    end
    me.inbox.initialItemCount = 0 --bugfix für crash beim öffnen
end

local function loadFile(path, basepath)
    basepath = me.path or basepath
    local cp = me.configpaths or {}
    local files = {}
    for _, p in pairs(cp.path or {}) do
        if p and p:gsub(" ", ""):gsub("/", ""):gsub("\\","") ~= "" then
            table.insert(files, string.format("%s/%s/%s", basepath, p, path))
        end
    end
    table.insert(files, string.format("%s/data/%s", basepath, path))
    local index = me.nextFile
    for i=index, #files do
        me.nextFile = i
        local p = files[i]
        local fn, err = loadfile(p)
        if fn then
            return fn, err, p
        elseif not err:match("cannot open") then
            me.debug.error(err)
        end
    end
    return nil, me.GetLocaString("nomorefiles")
end

function me.loadFile(path, basePath, f,  ...)
    local args = {...}
    me.nextFile = f or 1
    local fn, err, p = loadFile(path, basePath, f )
    if fn then
        me.debug.debug(string.format("loaded %s", p))
    end
    if not fn then
        me.debug.warn(string.format("%s - %s", err, path))
        return false
    end
    local loadnext = function()
        me.nextFile = me.nextFile + 1
        return me.loadFile(path, basePath, me.nextFile, unpack(args))
    end
    local res = { pcall(fn, loadnext, unpack(args)) }
    local ok = table.remove(res, 1)
    if not ok then
        local msg = table.remove(res, 1)
        me.debug.error(string.format("%s - %s", msg, path))
        return false
    end
    return unpack(res)
end
function me.LoadFiles(config)
    local res, err = loadfile(string.format("%s/index.lua", me.path))
    if not res then
        res, err = loadfile(string.format("%s/develop/index.lua", me.path))
    end
    if res then
        local res, data = pcall(res)
        if res then
            me.configpaths = data
        else
            me.debug.error(data)
        end
    end
    if config then
        me.config = me.loadFile("config.lua") or me.config
    end
    me.SendEvent("MAIL_LOAD_FILES")
end

function me.MoneyFrameTemplateOnLoad(frame)
    frame.SetAmount = function(self, amount, negativ)
        _G[self:GetName().."Amount"]:SetText(negativ and me.FormatNumber(amount) or MoneyNormalization(amount));
        self:Show();
    end;
end
function me.RegisterFrame(frame)
    me.frames[frame:GetID()] = frame
end
local statusColors = {
    error = {1,0,0},
    warn = {1,0.5,0},
}
function me.SetStatus(priority, text, r, g, b)
    local frame = ZMailFrameStatus
    if text then
        if type(r) == 'string' then
            r,g,b = unpack(statusColors[r] or {})
        end
        frame.priority = priority
        frame:Show()
        frame:SetText(text)
        frame:SetColor(r or 1, g or 1, b or 1)
    elseif (frame.priority or 0) <= (priority or 0) then
        frame:Hide()
    end
end
function me.SelectTab(index)
    PanelTemplates_SetTab(ZMailFrame, index)
    ZMailFrameRecipients:Hide()
    for i, frame in pairs(me.frames) do
        if i ~= index and frame:IsVisible() then
            frame:Hide()
        end
    end
    for i, frame in pairs(me.frames) do
        if i == index and not frame:IsVisible() then
            frame:Show()
        end
    end
end
function me.events.WARNING_MESSAGE(event, msg)
    me.lastMsg = msg
end
function me.events.MAIL_LOAD_FILES()
    me.MinimapButton_CheckConfig()
end
function me.GetLastError()
    return me.lastMsg
end
function me.OnMailSend(success)
    if not success then
        me.SetStatus(2, me.lastMsg or me.GetLocaString("unknownerror"), 1,0,0)
    end
    local which = me.autoSend or me.lastSend
    if which == "msi" then
        me.massSendItems.bag.sendMail(success)
    elseif which == "mail" then
        me.send.sendMail(success)
    elseif which == "as" then
        me.autosend.sendMail(success)
    end
    me.lastMsg = nil
end
function me.UpdateStopButton()
    if me.autoSend or me.inbox.continueAfterReload then
        ZMailFrameStop:Enable()
    else
        ZMailFrameStop:Disable()
    end
end
function me.Stop()
    me.stopAutoSend()
    me.inbox.stop()
    me.UpdateStopButton()
end
function me.setAutoSend(value) 
    local last = me.autoSend
    me.autoSend = value
   -- if (last or me.autoSend) == "msi" then
        me.massSendItems.check()
   -- elseif (last or me.autoSend) == 'mail' then
        me.send.check()
    --end
    me.UpdateStopButton()
end
function me.stopAutoSend()
    me.setAutoSend(false)
    me.SendEvent("MAIL_STOP_AUTOSEND")
end
function me.isAutoSend() 
    return me.autoSend
end


function me.events.VARIABLES_LOADED()
    CloseMail()
    me.LoadFiles(true)
end

function me.events.MAIL_SEND_SUCCESS()
    me.OnMailSend(true)
end
function me.events.MAIL_FAILED()
    me.OnMailSend(false)
end

local lastOpen = GetTime()
function me.Open(dry, useItem)
    if not dry then
        if lastOpen > GetTime() then 
            return
        end
        lastOpen = GetTime() + .5
    end
    if TimeLet_GetLetTime("MailLet") >= 0 then
        if dry then return true end
        CloseMail()
        OpenMail()
        return
    elseif GetBagItemCount(208789) > 0 then
        if dry then return true end
        CloseMail()
        UseItemByID(208789)
        return
    elseif GetBagItemCount(208790) > 0 then
        if dry then return true end
        CloseMail()
        UseItemByID(208790)
        return
    elseif GetBagItemCount(208791) > 0 then
        if dry then return true end
        CloseMail()
        UseItemByID(208791)
        return
    elseif GetBagItemCount(208792) > 0 then
        if dry then return true end
        CloseMail()
        UseItemByID(208792)
        return
    end
    if dry and useItem then
        return GetBagItemCount(201136) > 0
    elseif dry then
        return false, GetBagItemCount(201136) > 0
    end
    if useItem then
        CloseMail()
        UseItemByID(201136)
        return
    end
    StaticPopup_Show("TIMEFLAG_FAIL1")
end

function me.events.MAIL_SHOW()
    me.stopAutoSend()
    ZMailFrame:Show()
end
function me.events.MAIL_CLOSED()
    me.stopAutoSend()
    ZMailFrame:Hide()
end

function me.CursorPlaceBack()
    if not CursorHasItem() then return true end
    local fn = {
        bag = PickupBagItem,
        bank = PickupBankItem,
        equip = PickupEquipmentItem,
        action = PickupAction,
        trade = false,
        macro = false,
        emote = false,
        skill = false,
        shop = false,
        merchant = false,
        house = false,
        teleport = false,
        guildbank = false,
        guildfurniture = false,
        SuitSkill = false,
        SkillPlate = false,
        SuitSkillequip = false,
        CoolClothBag = false,
        CoolSuit = false,
        HappyPartner = false,
    }
    local typ = CursorItemType()
    local info = GetCursorItemInfo()
    if fn[typ] then
        fn[typ](info)
        return true
    end
    if fn[typ] == false then
        ItemClipboard_Clear()
        return true
    end
    ItemClipboard_Clear()
    SendWarningMsg("Unknown type: ".. tostring(typ))
    return false
end

local function addName(recipients, name)
    local valid = name:match("^%s*([^%s]+)%s*$") ~= nil
    local recipient = name:match("^%s*(.-)%s*$")
    local error = nil
    if recipient ~= nil then
        table.insert(recipients, recipient)
    end
    if not valid then
        return recipient
    end
    if recipient:len() < 4 then -- no upper limit ...utf8 is annoying...
        return recipient
    end
    if recipient and recipient:lower() == (UnitName("player") or ""):lower() then
        return recipient, true
    end
    return nil
end
function me.getRecipients(text, ignorePlayer)
    local recipients = {}
    local error = nil
    local hasPlayer = false
    repeat
        local offset = text:find(",")
        local name = text
        if offset then
            name = text:sub(1, offset - 1)
            text = text:sub(offset + 1)
        end
        local err, player = addName(recipients, name)
        hasPlayer = hasPlayer or player
        if not ignorePlayer or not player then
            error = error or err
        end
    until offset == nil
    return recipients, error, hasPlayer
end
function me.getRecipientString(tbl)
    local res = ""
    for _, name in ipairs(tbl) do
        res = ("%s,%s"):format(res, name:gsub("%s", ""))
    end
    return res:sub(2):gsub(",", ", ")

end
function me.ShowRecipientSelection(callback, preselect)
    local function hide(frame)
        frame:Hide()
    end
    local function ok(frame, data)
        hide(frame)
        return callback(me.getRecipientString(data))
    end
    local frame = ZMailFrameRecipients
    frame:Init({onOK=ok, onCancel=hide}, true)
    for _, name in pairs(me.getRecipients(preselect or "")) do
        frame:Select(name)        
    end
end

function me.formatTime(sec)
    sec = math.floor(sec)
    local min = math.floor(sec / 60) % 60
    local h = math.floor(sec / 60 / 60) % 24
    local d = math.floor(sec / 60 / 60 / 24)
    if d >0 then
        return string.format("%dd %02d:%02d", d,h,min)
    end
    if h > 0 then
        return string.format("%d:%02d", h, min)
    end
    return string.format("!%d min!", min)
end

function me.MinimapButton_SetFlashColor()
    if me.Open(true) then
        ZMailFrame_MinimapButtonFlash:SetColor(0,1,0)
    elseif me.Open(true, true) then
        ZMailFrame_MinimapButtonFlash:SetColor(1,1,0)
    else
        ZMailFrame_MinimapButtonFlash:SetColor(1,0,0)
    end
end

function me.MinimapButton_OnEnter(this)
    GameTooltip:SetOwner(this, "ANCHOR_LEFT", 0, 0)
    GameTooltip:SetText("ZMail")

    local text = string.format("|cffff0000%s|r", LOGIN_LOAD_OFFLINE)
    me.MinimapButton_SetFlashColor()
    local perma, item = me.Open(true)
    if perma then
        text = string.format("|cff00ff00%s|r", me.GetLocaString("MM_available"))
    elseif item then
        text = string.format("|cffffff00%dx %s|r", GetBagItemCount(201136), GetObjName(201136))
    end
    GameTooltip:AddLine(string.format("%s: %s", TEXT("TIMEFLAG_HANDY_MAIL"), TEXT(text)))
    local time = TimeLet_GetLetTime("MailLet")
    if time >= 0 then
        GameTooltip:AddLine(string.format(TEXT("SYS_REMAINTIME").."%s", me.formatTime(time * 60)))
    end
    if me.inbox.NewMail then
        GameTooltip:AddLine(string.format("|cffffff00%s|r", TEXT("SYS_NEW_MAIL")))
    end
    GameTooltip:Show()
end

function me.MinimapButton_OnClick(this, key)
    if key == "RBUTTON" then
        ToggleUIFrame(TimeFlagFrame)
        return
    end
    if ZMailFrame:IsVisible() then
        ZMailFrame:Hide()
    else
        me.Open(false, IsCtrlKeyDown())
        me.inbox.NewMail = false
    end
end
_G["zmail"] = me
