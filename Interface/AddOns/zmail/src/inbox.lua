local parent = zmail
local me = {
    NewMail = false,
    data = {},
    events = {},
    settings = {},
    ui = {},
    softDelete = {},
}
------------------- radio shit ------------------
function me.settings.selectRadio(key)
    local options = { 'all', 'item', 'gold' }
    if type(key) == "number" then
        key = options[key]
    else
        local k = nil
        for _, v in pairs(options) do
            if key == v then
                k = v
                break
            end
        end
        key = k
    end
    key = key or "all"
    parent.getInboxConfig().selectRadio = key
    local tools = "ZMailFrameBodyInboxToolsMassTagTake"
    for _, name in pairs({"All", "Item", "Gold"}) do
        if name:lower() == key then
            _G[tools..name]:SetChecked(true)
            _G[tools..name.."Label"]:SetColor(1,1,1)
        else
            _G[tools..name.."Label"]:SetColor(.8,.8,.8)
        end
    end
end

function me.settings.OnRadioClick(this)
    local gid = this:GetGroupId()
    local id = this:GetID()
    if gid == 1 then
        me.settings.selectRadio(id)
    end
end

------------------- checkboxes ------------------
local checkvars = {
    "takeanddelete",
    "autoStop",
    "enableTakeCOD",
    "autoRefresh",
    "continueAfterReload"
}
function me.settings.takeanddelete(val)
    local conf = parent.getInboxConfig()
    conf.takeanddelete = val ~= false -- defaults to true
    ZMailFrameBodyInboxToolsMassTakeCheckTakeDeleteEmpty:SetChecked(conf.takeanddelete)
end
function me.settings.autoStop(val)
    local conf = parent.getInboxConfig()
    conf.autoStop = val ~= false -- defaults to true
    ZMailFrameBodyInboxToolsMassTakeCheckTakeAndTryAgain:SetChecked(conf.autoStop)
end
function me.settings.enableTakeCOD(val)
    local conf = parent.getInboxConfig()
    conf.enableTakeCOD = val == true -- defaults to false
    ZMailFrameBodyInboxToolsMassTakeCheckAutoTakeCOD:SetChecked(conf.enableTakeCOD)

    local edit = "ZMailFrameBodyInboxToolsMassTake"
    if val then
        _G[edit]:SetHeight(154)
        _G[edit.."AutoCODMax"]:Hide()
        _G[edit.."AutoCODMaxFormatted"]:Show()
    else
        _G[edit]:SetHeight(132)
        _G[edit.."AutoCODMax"]:Hide()
        _G[edit.."AutoCODMaxFormatted"]:Hide()
    end
end
function me.settings.autoRefresh(val)
    local conf = parent.getInboxConfig()
    conf.autoRefresh = val == true -- defaults to false
    ZMailFrameBodyInboxToolsRefreshCheckAutoRefresh:SetChecked(conf.autoRefresh)
end
function me.settings.continueAfterReload(val)
    local conf = parent.getInboxConfig()
    conf.continueAfterReload = val == true -- defaults to false
    ZMailFrameBodyInboxToolsRefreshCheckContinueAfterReload:SetChecked(conf.continueAfterReload)
end
function me.settings.OnCheckClick(this)
    local id = this:GetID()
    assert(checkvars[id] and me.settings[checkvars[id]])
    me.settings[checkvars[id]](this:IsChecked())
end

function me.settings.OnCheckEnter(this)
    local id = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
    GameTooltip:SetText(parent.GetLocaString("InboxCheckTT"..id))
end

------------------- textfields ------------------
local editvars = {
    "minfreeslot",
    "autoTakeCODMax",
}
function me.settings.minfreeslot(val, eb)
    val = tonumber(val)
    if type(val) ~= "number" or val < 0 then val = 0 end
    local conf = parent.getInboxConfig()
    conf.minfreeslot = val -- defaults to 0
    if not eb then
        ZMailFrameBodyInboxToolsMassTakeMinFreeSlots:SetText(conf.minfreeslot)
    end
end

function me.settings.autoTakeCODMax(val, eb)
    val = tonumber(val)
    if type(val) ~= "number" or val < 0 then val = 0 end
    local conf = parent.getInboxConfig()
    conf.autoTakeCODMax = val -- defaults to 0
    if not eb then
        ZMailFrameBodyInboxToolsMassTakeAutoCODMax:SetText(conf.autoTakeCODMax)
        ZMailFrameBodyInboxToolsMassTakeAutoCODMaxFormatted:SetText(parent.FormatNumber(conf.autoTakeCODMax))
    end
end

function me.settings.NumberOnTextChanged(this)
    local id = this:GetID()
    assert(editvars[id] and me.settings[editvars[id]])
    me.settings[editvars[id]](this:GetText(), true)
end
function me.settings.NumberOnEnter(this)
    local id = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
    GameTooltip:SetText(parent.GetLocaString("InboxNumberTT"..id))
end

function me.settings.init()
    local conf = parent.getInboxConfig()
    for _, key in pairs(checkvars) do
        me.settings[key](conf[key])
    end
    for _, key in pairs(editvars) do
        me.settings[key](conf[key])
    end
    me.settings.selectRadio(conf.selectRadio)
end

------------------------ ui ----------------------------
function me.ui.setInfoLabel(text)
    ZMailFrameBodyInboxMailsInfoLabel:SetText(text)
end
function me.ui.setStatus(t, err, ...)
    if err == true then
        err = me.lastError
    else
        me.lastError = {t, err, ...}
    end
    if not ZMailFrameBodyInbox:IsVisible() then return end
    parent.SetStatus(unpack(me.lastError or {10}))
end

function me.ui.init()
    -- inbox
    for i=1,19 do
        local frame = _G["ZMailFrameBodyInboxMails"..i]
        frame:ClearAllAnchors()
        frame:SetID(i)
        frame:SetAnchor("TOPLEFT", "TOPLEFT", "ZMailFrameBodyInboxMails", 5, 10+(i-1)*25)
        if parent.getInboxConfig().hideBackground then
            frame:SetBackdropTileAlpha(0.1)
        else
            frame:SetBackdropTileAlpha( i % 2 == 0 and 0.1 or 0.2)
        end
    end
    local viewer = "ZMailFrameBodyInboxViewer"
    _G[viewer.."HeaderAuthorLabel"]:SetText(MAIL_SENDER_COLON)
    _G[viewer.."HeaderSubjectLabel"]:SetText(MAIL_SUBJECT_COLON)

    _G[viewer.."Reply"]:SetText(MAIL_REPLY)
    _G[viewer.."Return"]:SetText(MAIL_RETURN)
    _G[viewer.."Delete"]:SetText(C_DEL)
    _G[viewer.."Close"]:SetText(C_CLOSE)

    _G[viewer.."FooterAcceptCODCheckLabel"]:SetText(parent.GetLocaString("takecod"))

    local tools = "ZMailFrameBodyInboxTools"
    _G[tools.."MassTakeButtonTake"]:SetText(parent.GetLocaString("getitem"))
    _G[tools.."MassTakeButtonReturn"]:SetText(MAIL_RETURN)
    _G[tools.."MassTakeButtonDelete"]:SetText(C_DEL)

    _G[tools.."TotalMoneyLabel"]:SetText(parent.GetLocaString("gold"))
    _G[tools.."TotalMoneyLabel"]:SetColor(1,0.82,0)

    _G[tools.."MassTakeCheckTakeDeleteEmptyLabel"]:SetText(parent.GetLocaString("takendelete"))
    _G[tools.."MassTakeCheckTakeAndTryAgainLabel"]:SetText(parent.GetLocaString("takeandretry"))
    _G[tools.."MassTakeCheckAutoTakeCODLabel"]:SetText(parent.GetLocaString("autotakecod"))
    _G[tools.."MassTakeAutoCODMaxLabel"]:SetText(parent.GetLocaString("autocodmax"))
    _G[tools.."MassTakeAutoCODMaxFormattedLabel"]:SetText(parent.GetLocaString("autocodmax"))
    _G[tools.."MassTakeMinFreeSlotsLabel"]:SetText(parent.GetLocaString("minfreeslots"))

    _G[tools.."MassTagLabel"]:SetText(parent.GetLocaString("multiplemail"))
    _G[tools.."MassTagTakeAllLabel"]:SetText(parent.GetLocaString("all"))
    _G[tools.."MassTagTakeItemLabel"]:SetText(TEXT("CRAFT_TYPELIST_36"))
    _G[tools.."MassTagTakeGoldLabel"]:SetText(BILLBOARD_001)
    _G[tools.."MassTagButtonTagReset"]:SetText(OBJ_RESET)
    _G[tools.."MassTagButtonTagReset"]:SetTextColor(0,1,0)
    _G[tools.."MassTagButtonTagChars"]:SetText(parent.GetLocaString("list_private"))
    _G[tools.."MassTagButtonTagFriends"]:SetText(parent.GetLocaString("list_friend"))
    _G[tools.."MassTagButtonTagGuildies"]:SetText(parent.GetLocaString("list_guild"))
    _G[tools.."MassTagButtonTagOther"]:SetText(parent.GetLocaString("other"))
    _G[tools.."MassTagButtonTagEmpty"]:SetText(parent.GetLocaString("empty"))
    _G[tools.."MassTagButtonTagAuction"]:SetText(AUCTION)
   
    _G[tools.."RefreshCheckAutoRefreshLabel"]:SetText(parent.GetLocaString("autorefresh"))
    _G[tools.."RefreshCheckContinueAfterReloadLabel"]:SetText(parent.GetLocaString("continueafterreload")) 

    _G[tools.."RefreshButtonRefresh"]:SetText(parent.GetLocaString("refresh"))
end

function me.ui.updateRefreshButton()
    local perma, item = parent.Open(true)
    local frame = ZMailFrameBodyInboxToolsRefreshButtonRefresh
    if perma or item then
        if perma then
            frame:SetTextColor(1,1,1)
        else
            frame:SetTextColor(1,1,0)
        end
        frame:Enable()
    else
        frame:SetTextColor(.7,.7,.7)
        frame:Disable()
    end
end

local newMailText = TEXT("SYS_NEW_MAIL")
function me.events.CHAT_MSG_SYSTEM(event, arg1)
    if arg1 == newMailText then
        if ZMailFrame:IsVisible() then
            me.initialItemCount = 30 --bugfix für crash beim öffnen
        else
            me.NewMail = true
            ZMailFrame_MinimapButtonFlash:Show()
            parent.MinimapButton_SetFlashColor()
            if parent.getInboxConfig().sendSystemMsg then
                SendWarningMsg("|cff93ccea"..newMailText)
            end
        end
    end
end
function me.events.MAIL_SHOW()
    me.softDelete = {}
    me.initialItemCount = 0
    me.waitForData = true
    local car = parent.getInboxConfig().continueAfterReload or false
    if type(car) == "function" then car = car() or false end
    me.LoadList(not car)
    me.ui.setInfoLabel(parent.GetLocaString("loading"))
    parent.Schedule("MAILBODYINFO", 1, function() me.LoadList() end)
end

function me.events.MAIL_INBOX_UPDATE()
    me.initialItemCount = math.max(me.initialItemCount, GetInboxNumItems())
    me.LoadList()
    me.ui.setInfoLabel("")
    parent.Schedule("MAILBODYINFO")
    me.UpdateInbox()
    me.takeAuto()
    if not me.continueAfterReload then
        local take = parent.getInboxConfig().continueAfterReload
        if type(take) == "function" then take = take() end 
        if take then
            me.Reset()
            me.select("all", true)
            me.take()
        end
    end
    me.AutoRefresh()
end

function me.events.MAIL_CHARLIST_UPDATE()
    me.ListUpdate()
end

function me.events.MAIL_LOAD_FILES()
    me.ui.init()
end

function me.AutoRefresh()
    if me.initialItemCount ~= 30 then return end
    if parent.isAutoSend() then return end
    local autoRefresh = parent.getInboxConfig().autoRefresh
    if type(autoRefresh) == "function" then autoRefresh = autoRefresh() end
    if autoRefresh and #me.data == 0 and parent.Open(true, false) then
        parent.Open(false, false)
    end
end

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.inbox", fn)
    end
    me.settings.init()
end


function me.OnShow()
    me.ListUpdate()
    me.ui.updateRefreshButton()
    me.AutoRefresh()
    me.settings.init()
    me.ui.setStatus(10)
    me.NewMail = false
end

function me.checkSelect( typ, index, noCOD )
    local data = me.data[index]
    local max = noCOD and 0 or (parent.getInboxConfig().enableTakeCOD and (parent.getInboxConfig().autoTakeCODMax or 0)) or 0
    if data.money > max and data.cod then
        return false
    end
    local hasItem = data.items > 0
    local hasGold = data.money > 0
    if typ == "empty" then
        return not (hasItem or hasGold)
    end
    if parent.getInboxConfig().selectRadio == 'item' and not hasItem then
        return false
    end
    if parent.getInboxConfig().selectRadio == 'gold' and not hasGold then
        return false
    end
    if typ == "all" then
        return true
    end
    if typ == 'auction' then
        if data.canReturn then return false end
        if data.canReply then return false end
        if data.subject == TEXT("SYS_AC_SENDBACK_ITEM") and data.sender == data.sender ~= UnitName("player") then
            return true
        end 
        if data.subject == TEXT("SYS_AC_BUY") and data.sender == TEXT("CHAT_MSG_SYSTEM") then
            return true
        end
        if data.sender ~= UnitName("player") then 
            return false 
        end
        return data.subject == string.format("%s %s", TEXT("SYS_SEND_BACK"), TEXT("SYS_AC_SENDBACK_ITEM"))
    end
    if UnitName('player') == data.sender then
        return typ == 'private'
    end
    local data = parent.charlist.Get(data.sender) or {}
    if typ == "other" then
        if data.guild then return false end
        if data.private then return false end
        if data.friend then return false end
        return true
    end
    return data[typ] ~= nil
end
function me.select(type, noCOD)
    for index, data in pairs(me.data) do
        data.selected = me.checkSelect(type, index, noCOD)
    end
    me.ListUpdate()
end
function me.getQueueSize()
    local queued = 20
    for i=1, 20 do
        if not (GetItemQueueInfo(i) or nil) then
            queued = i - 1
            break
        end
    end
    return queued, 20- queued
end
function me.getBagSpace()
    local current, max = GetBagCount()
    local keepfree = parent.getInboxConfig().minfreeslot or 0
    if type(keepfree) == "function" then keepfree = keepfree() or 0 end
    return  max - current - keepfree
end
function me.start()
    if me.continueAfterReload then
        return false
    end
    me.continueAfterReload = {
        delete = parent.getInboxConfig().takeanddelete,
    }
    parent.UpdateStopButton()
    me.ListUpdate()
    me.takeAuto()
end
function me.stop()
    me.continueAfterReload = false
    parent.UpdateStopButton()
    me.ListUpdate()
end
function me.takeAuto()
    for k, _ in pairs(me.softDelete) do
        me.Delete(k)
    end
    me.softDelete = {}
    if not me.continueAfterReload then
        return false
    end
    local space = me.getBagSpace()
    local queued, freequeued = me.getQueueSize()
    local cnt = 0
    for index, data in pairs(me.data) do
        if data.selected then
            if data.money > 0 or data.items > 0 then
                if not data.cod and data.money > 0 and GetPlayerMoney("copper") + data.money > 999999999 then
                    me.ui.setStatus(2, string.format(parent.GetLocaString("cannottakemoney"), MoneyNormalization(data.money)))
                elseif space - queued > 0 and freequeued > 1 then
                    local count = 0
                    if data.money == 0 then
                        count = select(3, GetInboxItem(index, 1))
                    end
                    if count and count <= 32000 then
                        TakeInboxItem(index) --hier tritt der bug auf -> wird einmal ausgeführt
                        return true
                    end
                else
                    cnt = cnt + 1
                end
            elseif me.continueAfterReload.delete then
                me.Delete(index)
                me.takeAuto()
                return true
            end
        end
    end
    if cnt == 0 then
        me.stop()
    elseif space - queued == 0 then
        if not parent.getInboxConfig().autoStop then
            parent.Schedule("AUTOTAKE", 1, me.takeAuto)
        else
            me.stop()
        end
    else
        parent.Schedule("AUTOTAKE", .25, me.takeAuto)
    end
    return false
end
function me.take()
    if me.GetSelectedCount() == 0 then
        me.select("all")
    end
    me.start()
end
function me.returnSelected()
    for i=#me.data, 1, -1 do
        local data= me.data[i]
        if data.selected then
            me.Return(i, true)
        end
    end
    me.LoadList()
end
function me.deleteSelected()
    for i=#me.data, 1, -1 do
        local data= me.data[i]
        if data.selected then
            me.Delete(i, true)
        end
    end
    me.LoadList()
end
local function afterDeleteOrReturn(index, noList)
    if ZMailFrameBodyInboxViewer:GetID() == index then --ok
        me.SetDetail()
    end
    table.remove(me.data, index)
    if not noList then
        me.LoadList()
    end

end
function me.Delete(index, noList)
    local data = me.data[index] or {}
    if not data.canDelete then
        SendWarningMsg(parent.GetLocaString("cannotdelete"))
        return false
    end
    DeleteInboxItem(index)
    afterDeleteOrReturn(index, noList)
    return true
end
function me.Return(index, noList)
    local data = me.data[index] or {}
    if not data.canReturn then
        return false
    end
    ReturnInboxItem(index)
    afterDeleteOrReturn(index, noList)
    return true
end
function me.Reply(index, noList)
    local data = me.data[index] or {}
    if not data.canReturn then
        return false
    end
    return parent.send.setReply(data)
end
function me.Reset()
    for _, data in pairs(me.data) do
        data.selected = false
    end
    me.ListUpdate()
end
function me.LoadList(reset)
    local cnt = GetInboxNumItems()
    if cnt == 0 then
       me.ui.setInfoLabel(parent.GetLocaString("nomail"))
    end
    if reset or not me.data then
        me.data = nil;
        me.data = {}
    end
    if not reset and me.waitForData and cnt ~= 0 and cnt < #me.data then
        -- this should never happen
        me.data = nil;
        me.data = {}
    elseif cnt ~= #me.data and not me.waitForData then
        me.data = nil;
        me.data = {}
    end
    if cnt > 0 and me.waitForData then
        me.waitForData = false
    end
    
    local gold = 0
    local player = UnitName("player")
    for i=1, cnt do
        local packageIcon, sender, subject, COD, moneyMode, money, daysLeft, _, items, wasRead, wasReturned, canReply = GetInboxHeaderInfo(i);
        local entry = me.data[i] or {}
        entry.index = i
        entry.icon = packageIcon
        entry.sender = sender
        entry.subject = subject
        if entry.sender ~= player then
            entry.shortSubject = subject:gsub("^"..TEXT("SYS_SEND_BACK"), "Re:")
        else
            entry.shortSubject = subject:gsub("^"..TEXT("SYS_SEND_BACK").." ", "")
        end
        entry.cod = COD
        entry.gold = moneyMode == "copper"
        entry.money = money
        entry.daysLeft = daysLeft
        entry.items = items
        entry.read = wasRead
        entry.canReturn = not wasReturned and canReply
        entry.canReply = canReply
        entry.canDelete = InboxItemCanDelete(i) and money == 0 and items == 0
        me.data[i] = entry
        if entry.money > 0 and not entry.cod then
            gold = gold + entry.money
        end
    end
    ZMailFrameBodyInboxMailsScroll:SetMinMaxValues(1, math.max(cnt - 19 + 1, 1))
    if gold == 0 then
        ZMailFrameBodyInboxToolsTotalMoneyLabel:Hide()
        ZMailFrameBodyInboxToolsTotalMoney:Hide()
    else
        ZMailFrameBodyInboxToolsTotalMoneyLabel:Show()
        ZMailFrameBodyInboxToolsTotalMoney:Show()
        ZMailFrameBodyInboxToolsTotalMoney:SetAmount(gold)
    end
    me.ListUpdate(reset ~= nil)
end
function me.GetSelectedCount()
    local selected = 0
    for _, data in pairs(me.data) do
        if data.selected then
            selected = selected + 1
        end
    end
    return selected
end
function me.ListUpdate(reset)
    if #me.data == 0 or reset then
        ZMailFrameTab1:SetText(parent.GetLocaString("tab1"))
    else
        ZMailFrameTab1:SetText(string.format(parent.GetLocaString("tab1count"), #me.data))
    end
    if not ZMailFrameBodyInbox:IsVisible() then return end
    local detailPage = ZMailFrameBodyInboxViewer:GetID()
    for i=1, 19 do
        local name = "ZMailFrameBodyInboxMails"..i
        local frame = _G[name]
        local index = i + ZMailFrameBodyInboxMailsScroll:GetValue() - 1
        local data = me.data[index]
        if not reset and data then
            frame:Show()
            frame:SetID(index)
            if index == detailPage then
                if data.selected then
                    frame:SetBackdropTileColor(0,0,1)
                else
                    frame:SetBackdropTileColor(0,1,1)
                end
            elseif data.temporarySelected then
                if data.cod and data.money > (parent.getInboxConfig().autoTakeCODMax or 0) and parent.getInboxConfig().enableTakeCOD then
                    frame:SetBackdropTileColor(1,0.4,0.4)
                else
                    frame:SetBackdropTileColor(1,0.5,1)
                end
            elseif data.selected then
                if me.continueAfterReload then
                    frame:SetBackdropTileColor(1,0,0)
                else
                    frame:SetBackdropTileColor(1,0,1)
                end
            else
                if parent.getInboxConfig().hideBackground then
                    frame:SetBackdropTileColor(0,0,0)
                else
                    frame:SetBackdropTileColor(1,1,1)
                end
            end
            _G[name.."Subject"]:SetText(data.shortSubject)
            _G[name.."SubjectHigh"]:SetText(data.shortSubject)
            _G[name.."Author"]:SetText(data.sender)
            local charlist = parent.charlist.Get(data.sender) or {}
            if charlist.private then
                _G[name.."Author"]:SetColor(.86, .53, .42)
            elseif charlist.party then
                _G[name.."Author"]:SetColor(.94, .41, .8)
            elseif charlist.friend then
                _G[name.."Author"]:SetColor(.41,.8,.94)
            elseif charlist.guild then
                _G[name.."Author"]:SetColor(0,1,0)
            else
                _G[name.."Author"]:SetColor(1,1,1)
            end
            if data.money > 0 then
                _G[name.."Money"]:Show()
                _G[name.."Subject"]:Hide()
                _G[name.."SubjectHigh"]:Show()
                _G[name.."Money"]:SetAmount(data.money)
                if data.cod then
                    _G[name.."MoneyAmount"]:SetColor(1,0,0)
                else
                    _G[name.."MoneyAmount"]:SetColor(1,1,1)
                end
            else
                _G[name.."Money"]:Hide()
                _G[name.."Subject"]:Show()
                _G[name.."SubjectHigh"]:Hide()
            end
            local icon = _G[name.."Icon"]
            if data.icon and data.icon ~= "" then
                SetItemButtonTexture(icon, data.icon)
            elseif data.money > 0 and data then
                if data.read then
                    SetItemButtonTexture(icon, "interface/icons/coin_02")
                else
                    SetItemButtonTexture(icon, "interface/icons/coin_03")
                end
            else
                if data.read then
                    SetItemButtonTexture(icon, "interface/icons/quest_letter02")
                else
                    SetItemButtonTexture(icon, "interface/icons/quest_letter07")
                end
            end
            local dFrame = _G[name.."DaysLeft"]
            dFrame:SetText(parent.formatTime(data.daysLeft * 24 * 60 * 60));
            if data.daysLeft >= 3 then
                dFrame:SetColor(0,1,0)
            elseif data.daysLeft >= 2 then
                dFrame:SetColor(1,1,0)
            elseif data.daysLeft >= 1 then
                dFrame:SetColor(1,.5,0)
            else
                dFrame:SetColor(1,0,0)
            end
        else
            frame:Hide()
        end
    end
    if me.GetSelectedCount() == 0 then     
        ZMailFrameBodyInboxToolsMassTakeButtonReturn:Disable()
        ZMailFrameBodyInboxToolsMassTakeButtonDelete:Disable()
    else
        ZMailFrameBodyInboxToolsMassTakeButtonReturn:Enable()
        ZMailFrameBodyInboxToolsMassTakeButtonDelete:Enable()
    end
end
function me.ListOnMouseWheel(this, delta)
    ZMailFrameBodyInboxMailsScroll:SetValue(ZMailFrameBodyInboxMailsScroll:GetValue()- delta/120)
end
function me.ListOnEnter(this, notooltip)
    local id = this:GetID()
    _G[this:GetName().."Highlight"]:Show()

    if me.selectOnEnter then
        for i=math.min(id, me.selectOnEnter), math.max(id, me.selectOnEnter) do
            (me.data[i] or {}).temporarySelected = true
        end
        me.selectOnEnter = id
        me.ListUpdate()
    end
    if notooltip then return end
    local data = me.data[id]
    if not data then 
        return 
    end
    if data.shortSubject:len() > 31 then
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", -5, 0);
        GameTooltip:SetText(MAIL_SUBJECT_COLON)
        GameTooltip:AddLine(data.shortSubject)
    end
end
function me.ListOnLeave(this)
    _G[this:GetName().."Highlight"]:Hide()
	GameTooltip:Hide();
end
function me.ListAttachmentOnEnter(this)
    me.ListOnEnter(this:GetParent(), true)
    local id = this:GetParent():GetID()
    local data = me.data[id]
    if not data then 
        return 
    end
    if data.items > 0  then
        GameTooltip:SetInboxItem(id)
        GameTooltip:SetOwner(this:GetParent(), "ANCHOR_BOTTOMLEFT", -5, 0);
    end
end
function me.ListAttachmentOnLeave(this)
    _G[this:GetParent():GetName().."Highlight"]:Hide()
	GameTooltip:Hide()
end
function me.DetailAttachmentOnEnter(this)
    local mailIndex = this:GetParent():GetParent():GetID()
    local itemindex = this:GetParent():GetParent():GetID()
    local name = GetInboxItem(mailIndex, 1)
    if not name then return end
    GameTooltip:SetInboxItem(mailIndex, itemindex)
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT", -5, 0);
end
function me.DetailAttachmentOnClick(this)
    local id = this:GetParent():GetParent():GetID()
    local data = me.data[id]
    me.ui.setStatus(2, "")
    local _, _, count = GetInboxItem(id, 1)
    if data and data.items > 0 and count > 32000 then
        SendWarningMsg(parent.GetLocaString("toomanyitems"))
        return
    end
    if data.cod and data.money ~= 0 then
        if not ZMailFrameBodyInboxViewerFooterAcceptCODCheck:IsChecked() then
            SendWarningMsg(parent.GetLocaString("acceptcod"))
            return
        end
    end
    TakeInboxItem(id)
end
function me.DetailAttachmentOnLeave(this)
	GameTooltip:Hide();
end
function me.UpdateInbox()
    if not ZMailFrameBodyInboxViewer:IsVisible() then
        return
    end
    local id = ZMailFrameBodyInboxViewer:GetID()
    local data = me.data[id]
    if not data then
        me.SetDetail()
        return
    end
    local viewer = "ZMailFrameBodyInboxViewer"
    local txt = GetInboxText(id)
    me.LoadList()
    _G[viewer.."BodyInput"]:SetText(txt)
    UIMultiEditBox_UpdateRangeChanged(_G[viewer.."BodyInput"]);
    _G[viewer.."HeaderAuthor"]:SetText(data.sender)
    _G[viewer.."HeaderSubject"]:SetText(data.shortSubject)
    if data.canReturn then
        ZMailFrameBodyInboxViewerReturn:Enable()
    else
        ZMailFrameBodyInboxViewerReturn:Disable()
    end
    if data.canDelete then
        ZMailFrameBodyInboxViewerDelete:Enable()
    else
        ZMailFrameBodyInboxViewerDelete:Disable()
    end
    if data.items==0 and data.money == 0 then
        _G[viewer.."Footer"]:Hide()
    else
        _G[viewer.."Footer"]:Show()
    end

    if data.items==0 then
        _G[viewer.."FooterAttachment"]:Hide()
    else
        _G[viewer.."FooterAttachment"]:Show()
    end
    if data.money > 0 then
        _G[viewer.."FooterMoney"]:Show()
        _G[viewer.."FooterMoney"]:SetAmount(data.money)
    else
        _G[viewer.."FooterMoney"]:Hide()
    end
    if data.cod and data.money > 0 then
        _G[viewer.."FooterAcceptCODCheck"]:Show()
        _G[viewer.."FooterAcceptCODCheck"]:SetChecked(false)
        _G[viewer.."FooterAttachmentLabel"]:SetText(MAIL_COD..":")
        _G[viewer.."FooterMoneyAmount"]:SetColor(1,0,0)

        local money = _G[viewer.."FooterMoney"]
        money:ClearAllAnchors()
        money:SetAnchor("LEFT", "RIGHT", viewer.."FooterAttachment", 10, 10)
    else
        local money = _G[viewer.."FooterMoney"]
        money:ClearAllAnchors()
        money:SetAnchor("LEFT", "RIGHT", viewer.."FooterAttachment", 10, 0)

        _G[viewer.."FooterMoneyAmount"]:SetColor(1,1,1)
        _G[viewer.."FooterAcceptCODCheck"]:Hide()
        _G[viewer.."FooterAttachmentLabel"]:SetText(MAIL_SENTITEM_COLON)
    end

    local name, texture, count = GetInboxItem(id, 1)
    local icon = _G[viewer.."FooterAttachment"]
    icon:Enable()
    if name then
        SetItemButtonTexture(icon, texture or "interface/icons/coin_03")
        SetItemButtonCount(icon, count)
        if count > 32000 then
            icon:Disable()
        end
    else
        SetItemButtonTexture(icon, "")
        SetItemButtonCount(icon, 0)
    end
end
function me.SetDetail(id)
    ZMailFrameBodyInboxViewer:SetID(id or 0)
    if id == nil then
        me.ListUpdate()
        ZMailFrameBodyInboxTools:Show()
        return
    end
    ZMailFrameBodyInboxViewer:Show()
    me.UpdateInbox()
end
function me.ListOnClick(this, key)
    if me.selectOnEnter then
        for i, v in pairs(me.data) do
            v.temporarySelected = nil
        end
    end
    me.selectOnEnter = false
    local id = this:GetID()
    local data = me.data[id]
    if key == "RBUTTON" then
        if data.cod and data.money > (parent.getInboxConfig().autoTakeCODMax or 0) and parent.getInboxConfig().enableTakeCOD then
            return
        end
        data.selected = true
        if data.money > 0 or data.items > 0 then
            local _, _, count = GetInboxItem(id, 1)
            if data.items > 0 and count and count > 32000 then
                SendWarningMsg(parent.GetLocaString("toomanyitems"))
                return
            end
            TakeInboxItem(this:GetID())
            if IsCtrlKeyDown() then
                me.softDelete[this:GetID()] = true
            end
        elseif IsCtrlKeyDown() then
            me.Delete(this:GetID())
        end
    else
        if IsCtrlKeyDown() then
            data.selected = not data.selected
            me.ListUpdate()
        else
            me.SetDetail(this:GetID())
        end
    end
end
function me.ListOnMouseDown(this, key)
    me.ui.setStatus(2, "")
    local id = this:GetID()
    me.selectOnEnter = id
    me.data[id].temporarySelected = true
    me.ListUpdate()
end
function me.ListOnMouseUp(this, key)
    if not me.selectOnEnter then return end
    me.selectOnEnter = false
    local shift = IsShiftKeyDown()
    local alt = IsAltKeyDown()
    for i, v in pairs(me.data) do
        if v.temporarySelected then
            v.temporarySelected = false
            if not (v.cod and v.money >= (parent.getInboxConfig().autoTakeCODMax or 0) and parent.getInboxConfig().enableTakeCOD) or alt then
                v.selected = true
            end
        elseif not shift then
            v.selected = false
        end
    end
    me.ListUpdate()
    
    if key ~= "RBUTTON" then return end
    local ctrl = IsCtrlKeyDown()
    if not me.continueAfterReload then
        me.continueAfterReload = {
            delete = ctrl
        }
        me.takeAuto()
        parent.UpdateStopButton()
    end
end
parent.inbox = me
