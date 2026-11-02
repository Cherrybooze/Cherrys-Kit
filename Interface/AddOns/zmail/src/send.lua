local parent = zmail
local me = {
    events = {},
    settings = {},
}

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.send", fn)
    end
    ZMailFrameBodySendComposerFooterMoneyLabel:SetColor(1,0.82,0)
    ZMailFrameBodySendComposerFooterMoneyTotalLabel:SetColor(1,0.82,0)
    ZMailFrameBodySendComposerFooterMoneyFormattedLabel:SetColor(1,0.82,0)
    ZMailFrameBodySendComposerFooterMoneyTotalFormattedLabel:SetColor(1,0.82,0)
    ZMailFrameBodySendToolsTotalMoneyLabel:SetColor(1,0.82,0)
    local Money = "ZMailFrameBodySendComposerFooterMoney"
    _G[Money.."Label"]:SetText(parent.GetLocaString("each"))
    _G[Money.."FormattedLabel"]:SetText(parent.GetLocaString("each"))
    _G[Money.."TotalLabel"]:SetText(parent.GetLocaString("total"))
    _G[Money.."TotalFormattedLabel"]:SetText(parent.GetLocaString("total"))

    local tools = "ZMailFrameBodySendTools"
    _G[tools.."OptionsCheckAutoSelectRecipientsLabel"]:SetText(parent.GetLocaString("autoSelectRecipients"))
    _G[tools.."OptionsCheckOnlyWhenEmptyLabel"]:SetText(parent.GetLocaString("onlyWhenEmpty"))
    _G[tools.."MoneySplitCheckIgnoreSelfLabel"]:SetText(parent.GetLocaString("ignoreSelf"))
    _G[tools.."MoneySplitWithholdMoneyLabel"]:SetText(parent.GetLocaString("withholdMoney"))
    _G[tools.."MoneySplitWithholdMoneyFormattedLabel"]:SetText(parent.GetLocaString("withholdMoney"))
    _G[tools.."MoneySplitGenerateText"]:SetText(parent.GetLocaString("generateText"))
    
end

function me.events.MAIL_SEND_INFO_UPDATE()
    if not ZMailFrameBodySend:IsVisible() then return end
    me.UpdateAttachment()
end
function me.events.PLAYER_MONEY()
    if not ZMailFrameBodySend:IsVisible() then return end
    me.check()
end

function me.OnShow()
    me.UpdateAttachment(false)
    me.SetStatus(10, true)
    me.check()
    if parent.getSendConfig().autoSelectRecipients then
        local frame = ZMailFrameBodySendComposerHeaderRecipient
        if not parent.getSendConfig().onlyWhenEmpty or frame:GetText() == "" then
            frame:SetFocus()
        end
    end
    me.settings.init()
end

function me.SetStatus(t, err, ...)
    if err == true then
        err = me.lastError
    else
        me.lastError = {t, err, ...}
    end
    if not ZMailFrameBodySend:IsVisible() then return end
    parent.SetStatus(unpack(me.lastError or {10}))
end
function me.check()
    if parent.isAutoSend() then
        ZMailFrameBodySendComposerSend:Disable()
        return
    end
    local data, errmsg, color = me.ReadUI()
    local rec = #data.recipients > 1 and #data.recipients or 1
    me.FooterCheckRecipients(data.recipients)
    if #data.recipients > 1 then
        if data.money then
            me.UpdateEachandAll()
        end
    end
    me.UpdateTotalMoney()

    local _, _, count = GetSendMailItem(1)
    if count and count > 32000 then
        errmsg = parent.GetLocaString("toomanyitems")
    end
    if errmsg then
        ZMailFrameBodySendComposerSend:Disable()
        me.SetStatus(1, errmsg, unpack(color))
        return false
    else
        me.SetStatus(1, nil)
    end

    ZMailFrameBodySendComposerSend:Enable()
    return true
end

function me.reset(saveRecipients)
    parent.stopAutoSend()
    if saveRecipients and me.data then
        me.SetUI({recipients = me.data.recipients})
    else
        me.SetUI()
    end
    me.data = nil
    local _, _, count = GetSendMailItem(1)
    if count > 0 then
        parent.CursorPlaceBack()
        ClickSendMailItemButton(1)
        parent.CursorPlaceBack()
    end
end
function me.sendMail(success)
    local data = me.data
    if not data then return false end
    if success then
        me.data.recipientIndex = me.data.recipientIndex + 1
        me.SetStatus(2, string.format(parent.GetLocaString("currentrecipient"), me.data.recipients[me.data.recipientIndex] or "" ))
    elseif success == false then
        parent.stopAutoSend()
        me.SetStatus(2, parent.GetLastError() or parent.GetLocaString("unknownerror"), 1, 0, 0)
        return false
    end
    if #data.recipients < me.data.recipientIndex then
        me.SetStatus(2, nil)
        me.reset(true)
        return false
    end
    if data.recipients[me.data.recipientIndex]:lower() == (UnitName("player") or ""):lower() then
        return me.sendMail(true)
    end
    if data.isCod then
        SetSendMailCOD(data.money, 0)
    else
        SetSendMailMoney(data.money, 0)
    end
    SendMail(data.recipients[me.data.recipientIndex], data.subject, data.content)
    return true
end
function me.setReply(data)
    parent.SelectTab(2)
    local subject = data.subject
    if not subject:find(MAIL_REPLY_PREFIX) then
        subject = string.format("%s %s", MAIL_REPLY_PREFIX or "", subject or "")
    end
    return me.SetUI({
        recipients = {data.sender},
        subject = subject
    })
end
function me.SetUI(data)
    data = data or {}
    local recipients = data.recipients or {}
    ZMailFrameBodySendComposerHeaderRecipient:SetText(parent.getRecipientString(recipients))
    ZMailFrameBodySendComposerHeaderSubject:SetText(data.subject or "")
    ZMailFrameBodySendComposerBodyFrameInput:SetText(data.content or "")

    me.OptionOnClick(data.isCod and 2 or 1)
    if data.isCod then
        ZMailFrameBodySendComposerFooterCOD:SetText(data.money and data.money > 0 and data.money or "")
        ZMailFrameBodySendComposerFooterMoney:SetText("")
        ZMailFrameBodySendComposerFooterMoneyTotal:SetText("")
    else
        ZMailFrameBodySendComposerFooterCOD:SetText("")
        ZMailFrameBodySendComposerFooterMoney:SetText(data.money and data.money > 0 and data.money or "")
        ZMailFrameBodySendComposerFooterMoneyTotal:SetText(data.money and data.money > 0 and #data.recipients > 0 and data.money/#data.recipients or data.money and data.money > 0 and data.money or "")
    end
    me.check()
    return true
end

function me.SetSubject(force)
    local data = me.ReadUI()
    local name, _, count = GetSendMailItem(1)
    local text = nil
    if count > 0 then
        text = count > 1 and string.format(parent.GetLocaString("subject"), count, name) or name
    end
    if data.money > 0 then
        if data.isCod then
            text = string.format(parent.GetLocaString("codSubject"), MoneyNormalization(data.money), text)
        else
            if text == nil then
                text = string.format("%s %s", MoneyNormalization(data.money), MONEY_GOLD)
            else
                text = string.format("%s %s: %s", MoneyNormalization(data.money), MONEY_GOLD, text)
            end
        end
    end
    if text or force then
        ZMailFrameBodySendComposerHeaderSubject:SetText(text or "")
    end
end
function me.ReadUI()
    local recipient = ZMailFrameBodySendComposerHeaderRecipient:GetText()
    local subject = ZMailFrameBodySendComposerHeaderSubject:GetText()
    local content = ZMailFrameBodySendComposerBodyFrameInput:GetText()

    local ismoney = ZMailFrameBodySendComposerFooterOptionMoney:IsChecked()
    local money = tonumber(ZMailFrameBodySendComposerFooterMoney:GetText()) or 0
    local cod = tonumber(ZMailFrameBodySendComposerFooterCOD:GetText()) or 0

    local _, _, count = GetSendMailItem(1)
    local recipients, err, hasPlayer = parent.getRecipients(recipient, true)

    local playername = (UnitName("player") or ""):lower()
    if #recipients > 1 and not parent.getSendConfig().ignoreIfSelf then
        for k, v in pairs(recipients) do
            if v:lower() == playername then
                err = v
            end
        end
    end
    if #recipients == 1 and recipients[1]:lower() == playername then
        err = recipients[1]
    end

    local data = {
        recipients = recipients,
        subject = subject,
        content = content,
        isCod = not ismoney,
        money = ismoney and money or cod,
        hasItem = count > 0
    }
    local color = {1, 0, 0}
    if err then
        if err == "" then
            err = MAIL_INPUT_ADDRESSEE_NAME
        else
            err = string.format(parent.GetLocaString("invalidrecipient"), err)
        end
    elseif #recipients == 0 then
        err = MAIL_INPUT_ADDRESSEE_NAME
    elseif #recipients > 1 and count > 0 then
        err = parent.GetLocaString("nomultirecipient")
    elseif ismoney and #recipients * money > GetPlayerMoney("copper") then
        err = FST_TRADE_NO_MONEY
    elseif subject:len() == 0 then
        err = parent.GetLocaString("emptysubject")
    end
    return data, err, color or {}
end
function me.send()
    if parent.isAutoSend() then return end
    local data, err, color = me.ReadUI()

    if err then
        SendWarningMsg(err)
        me.SetStatus(2, err, unpack(color))
    else
        me.data = data
        me.data.recipientIndex = 0
        parent.setAutoSend("mail")
        me.sendMail(true)
    end
end

function me.FooterCheckRecipients(recipients)
    recipients = recipients or parent.getRecipients(ZMailFrameBodySendComposerHeaderRecipient:GetText())
    if #recipients > 1 then
        ZMailFrameBodySendComposerFooterMoneyFormattedLabel:Show()
        ZMailFrameBodySendComposerFooterMoneyLabel:Show()
        ZMailFrameBodySendComposerFooterMoneyTotalFormatted:Show()
    else
        ZMailFrameBodySendComposerFooterMoneyLabel:Hide()
        ZMailFrameBodySendComposerFooterMoneyFormattedLabel:Hide()
        ZMailFrameBodySendComposerFooterMoneyTotal:Hide()
        ZMailFrameBodySendComposerFooterMoneyTotalFormatted:Hide()
    end
end
function me.OptionCheckRecipients(recipients)
    recipients = recipients or parent.getRecipients(ZMailFrameBodySendComposerHeaderRecipient:GetText())
    if #recipients > 1 then
        ZMailFrameBodySendToolsMoneySplitWithholdMoney:Hide()
        ZMailFrameBodySendToolsMoneySplitWithholdMoneyFormatted:Show()
        ZMailFrameBodySendToolsMoneySplitGenerateText:Show()
        ZMailFrameBodySendToolsMoneySplit:SetHeight(106)
    else
        ZMailFrameBodySendToolsMoneySplitWithholdMoney:Hide()
        ZMailFrameBodySendToolsMoneySplitWithholdMoneyFormatted:Hide()
        ZMailFrameBodySendToolsMoneySplitGenerateText:Hide()
        ZMailFrameBodySendToolsMoneySplit:SetHeight(58)
    end
end
function me.OptionOnClick(id)
    ZMailFrameBodySendComposerFooterOptionMoney:SetChecked( id == 1)
    ZMailFrameBodySendComposerFooterOptionCOD:SetChecked(id == 2)
    if id == 1 then
        ZMailFrameBodySendComposerFooterMoneyFormatted:Show()
        ZMailFrameBodySendComposerFooterCOD:Hide()
        ZMailFrameBodySendComposerFooterCODFormatted:Hide()
        me.FooterCheckRecipients()
    else
        ZMailFrameBodySendComposerFooterMoney:Hide()
        ZMailFrameBodySendComposerFooterMoneyFormatted:Hide()
        ZMailFrameBodySendComposerFooterMoneyTotal:Hide()
        ZMailFrameBodySendComposerFooterMoneyTotalFormatted:Hide()
        ZMailFrameBodySendComposerFooterCODFormatted:Show()
    end
    me.UpdateTotalMoney()
end

function me.UpdateAttachment(force)
    local this = ZMailFrameBodySendComposerFooterAttachment
    local name, icon, count = GetSendMailItem(1)

    SetItemButtonTexture(this, icon or "");
    SetItemButtonCount(this, count or 0);

    if count > 0 then
        ZMailFrameBodySendComposerFooterOptionCOD:Enable()
    else
        me.OptionOnClick(1)
        ZMailFrameBodySendComposerFooterOptionCOD:Disable()
    end
    me.check()
    me.SetSubject(force)
end
function me.AttachmentButtonOnRecvDrag()
    ClickSendMailItemButton(1)
end

function me.AttachmentButtonOnClick(key)
    if key == "RBUTTON" then
        parent.CursorPlaceBack()
        ClickSendMailItemButton(1)
        parent.CursorPlaceBack()
    else
        ClickSendMailItemButton(1)
    end
end
local MoneyFrames = {
    ["ZMailFrameBodySendComposerFooterMoneyTotalFormatted"] = "ZMailFrameBodySendComposerFooterMoneyTotal",
    ["ZMailFrameBodySendComposerFooterMoneyFormatted"] = "ZMailFrameBodySendComposerFooterMoney",
}
function me.UpdateTotalMoney()
    local money = GetPlayerMoney("copper")
    local cod = ZMailFrameBodySendComposerFooterOptionCOD:IsChecked() 
    if cod then
        ZMailFrameBodySendToolsTotalMoney:SetAmount(money)
        ZMailFrameBodySendToolsTotalMoneyAmount:SetColor(1,0.82,0)
        return
    else
        local frame
        for k,v in pairs(MoneyFrames) do
            if _G[k]:IsVisible() or _G[v]:IsVisible() then
                frame = _G[v]
                break
            end        
        end
        if not frame then 
            ZMailFrameBodySendToolsTotalMoney:SetAmount(money)
            ZMailFrameBodySendToolsTotalMoneyAmount:SetColor(1,0.82,0)
            return 
        end
        local sub = frame:GetText()
        sub = sub ~= "" and sub or 0
        money = money - sub 
        if money < 0 then
            ZMailFrameBodySendToolsTotalMoney:SetAmount(money, true)
            ZMailFrameBodySendToolsTotalMoneyAmount:SetColor(1,0,0)
        else
            ZMailFrameBodySendToolsTotalMoney:SetAmount(money)
            ZMailFrameBodySendToolsTotalMoneyAmount:SetColor(1,0.82,0)
        end
    end
end

function me.UpdateEachandAll()
    local frame = me.MoneyFocus
    if not frame then return end
    local money = tonumber(frame:GetText()) or 0
    local recipients = parent.getRecipients(ZMailFrameBodySendComposerHeaderRecipient:GetText())
    recipients = #recipients > 1 and #recipients or 1
    local total = money
    
    local moneyformatted = _G[frame:GetName().."Formatted"]
    moneyformatted:SetText(parent.FormatNumber(frame:GetText()))

    local withholdMoney = parent.getSendConfig().withholdMoney
    if recipients == 1 then
        withholdMoney = 0;
    end

    if frame == ZMailFrameBodySendComposerFooterMoneyTotal then
        if money > 999999999 then
            money = 999999999
            frame:SetText(money)
            moneyformatted:SetText(parent.FormatNumber(money))
        end
        local each = math.floor((money - withholdMoney) / recipients)
        ZMailFrameBodySendComposerFooterMoney:SetText(each or 0)
        ZMailFrameBodySendComposerFooterMoneyFormatted:SetText(parent.FormatNumber(each or 0))
    else
        total = (money * recipients) + withholdMoney
        if total > 999999999 then 
            total = 999999999
            frame:SetText(math.floor(total/recipients))
            moneyformatted:SetText(parent.FormatNumber(math.floor(total/recipients)))
        end
        ZMailFrameBodySendComposerFooterMoneyTotal:SetText(total or 0)
        ZMailFrameBodySendComposerFooterMoneyTotalFormatted:SetText(parent.FormatNumber(total or 0))
    end
    me.SetSubject()
end

local checkvars = {
    "autoSelectRecipients",
    "onlyWhenEmpty",
    "ignoreIfSelf",
}
function me.settings.autoSelectRecipients(val)
    local conf = parent.getSendConfig()
    conf.autoSelectRecipients = val == true -- defaults to false 
    ZMailFrameBodySendToolsOptionsCheckAutoSelectRecipients:SetChecked(conf.autoSelectRecipients)

    local onlywhenempty = ZMailFrameBodySendToolsOptionsCheckOnlyWhenEmpty
    if val then
        onlywhenempty:GetParent():SetHeight(82)
        onlywhenempty:Show()
    else
        onlywhenempty:GetParent():SetHeight(58)
        onlywhenempty:Hide()
    end
end
function me.settings.onlyWhenEmpty(val)
    local conf = parent.getSendConfig()
    conf.onlyWhenEmpty = val == true -- defaults to false
    ZMailFrameBodySendToolsOptionsCheckOnlyWhenEmpty:SetChecked(conf.onlyWhenEmpty)
end
function me.settings.ignoreIfSelf(val)
    local conf = parent.getSendConfig()
    conf.ignoreIfSelf = val ~= false -- defaults to true
    ZMailFrameBodySendToolsMoneySplitCheckIgnoreSelf:SetChecked(conf.ignoreIfSelf)
    me.check()
end

function me.settings.OnCheckClick(this)
    local id = this:GetID()
    assert(checkvars[id] and me.settings[checkvars[id]])
    me.settings[checkvars[id]](this:IsChecked())
end

function me.settings.OnCheckEnter(this)
    local id = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
    GameTooltip:SetText(parent.GetLocaString("SendCheckTT"..id))
end

local editvars = {
    "withholdMoney",
}
function me.settings.withholdMoney(val, eb)
    local conf = parent.getSendConfig()
    val = tonumber(val)
    if type(val)~="number" then val = 0 end
    if val < 0 then val = 0 end
    conf.withholdMoney = val -- defaults to 0
    if not eb then
        ZMailFrameBodySendToolsMoneySplitWithholdMoney:SetText(conf.withholdMoney)
        ZMailFrameBodySendToolsMoneySplitWithholdMoneyFormatted:SetText(parent.FormatNumber(conf.withholdMoney))
    else
        me.UpdateEachandAll()
    end
end
function me.settings.NumberOnTextChanged(this)
    local id = this:GetID()
    assert(editvars[id] and me.settings[editvars[id]])
    me.settings[editvars[id]](this:GetText(), true)
end
function me.settings.NumberOnEnter(this)
    local id = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetText(parent.GetLocaString("SendNumberTT"..id))
end

function me.settings.init()
    local conf = parent.getSendConfig()
    for _, key in pairs(checkvars) do
        me.settings[key](conf[key])
    end
    for _, key in pairs(editvars) do
        me.settings[key](conf[key])
    end
end

function me.GenerateText_OnClick(this)
    local recipients = nil
    local data, errmsg, color = me.ReadUI()
    for k, v in pairs(data.recipients) do
        recipients = recipients and recipients..", "..v or v
    end
    local money = ZMailFrameBodySendComposerFooterMoneyTotal:GetText()

    ZMailFrameBodySendComposerBodyFrameInput:SetText(string.format(parent.GetLocaString("generateTemplate"), #data.recipients, recipients, parent.FormatNumber(money), parent.FormatNumber(parent.getSendConfig().withholdMoney), parent.FormatNumber(data.money)))
end

function me.GenerateText_OnEnter(this)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetText(parent.GetLocaString("generateTextTT"))
end

parent.send = me
