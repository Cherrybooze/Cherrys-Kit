local parent = zmail
local me = {
    data = {},
    events = {},
    cod = {},
    mark = {
        buttons = 20,
        entries = {},
        page = 1,
        maxpage = 1,
    },
    bag = {},
    selected = {},
    tempSelect = {}
}

function me.events.MAIL_BAG_ITEM_UPDATE(_, type, real, bag)
    if me.selected[real] and not me.selected[real].sending and type ~= 1 then
        me.selected[real] = false
        me.updateCount()
    end
    me.bag.BagUpdate(real)
    
    if not ZMailFrameBodyMassSendItems:IsVisible() then return end
    if me.selected[real] then
        me.check()
    end
end
function me.events.MAIL_BAG_INDEX_UPDATE(_, current, old)
    for i=1, 180 do
        me.bag.BagUpdate(GetBagItemInfo(i))
    end
    me.cod.Update(true)
end
function me.events.ITEMFN_UPDATE()
    me.mark.Load()
end

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.massSendItems", fn)
    end
    local top = "ZMailFrameBodyMassSendItems"
    _G[top.."TopRecipientButton"]:SetText(MAIL_ADDRESSEE_COLON)
    _G[top.."TopReset"]:SetText(OBJ_RESET)
    _G[top.."ExtraCODReset"]:SetText(OBJ_RESET)
    _G[top.."TopSend"]:SetText(MAIL_MAILSENT)
    _G[top.."TopCOD"]:SetText(parent.GetLocaString("CODButton"))
    _G[top.."ExtraCODMultiAssign"]:SetText(parent.GetLocaString("Assign"))
end

function me.OnShow(this)
    if parent.getMSIConfig().autoReset then
        me.reset(true)
    end
    if this then
        for k, v in pairs(me.tempSelect) do
            me.mark.Mark(k, unpack(v))
        end
    end
    for i=1, 240 do 
        me.bag.BagUpdate(i)
    end
    me.check()
    me.updateCount()
    me.SetStatus(10, true)
    if parent.getSendConfig().autoSelectRecipients then
        local frame = ZMailFrameBodyMassSendItemsTopRecipient
        if not parent.getSendConfig().onlyWhenEmpty or frame:GetText() == "" then
            frame:SetFocus()
        end
    end
end

function me.SetStatus(t, err, ...)
    if err == true then
        err = me.lastError
    else
        me.lastError = {t, err, ...}
    end
    if not ZMailFrameBodyMassSendItems:IsVisible() then return end
    parent.SetStatus(unpack(me.lastError or {10}))
end

function me.reset(noShow)
    me.selected = nil
    me.selected = {}
    me.lastItem = nil
    parent.stopAutoSend()
    ZMailFrameBodyMassSendItemsTopRecipient:SetText("")
    if not noShow then
        me.OnShow()
    end
end
function me.selectID(id, select, where)
    select = select or nil
    if where == "all" or where == "bag" then
        for i=1,180 do
            local other = parent.bag.GetBagData(i)
            if other and other.id == id then
                local index = GetBagItemInfo(i)
                me.bag.select(index, select, false, false)
            end
        end
    end
    if where == "all" or where == "is" then
        for i=1,50 do
            local other = parent.bag.GetData(i)
            if other and other.id == id then
                me.bag.select(i, select, false, false)
            end
        end
    end
    if where == "all" or where == "tm" then
        for i=51, 60 do
            local other = parent.bag.GetData(i)
            if other and other.id == id then
                me.bag.select(i, select, false, false)
            end
        end
    end
    me.check()
    me.updateCount()
end

function me.ReadUI()
    local recipient = ZMailFrameBodyMassSendItemsTopRecipient:GetText()
    local recipients, err, hasPlayer = parent.getRecipients(recipient, true)
    local errType = 'error'
    if err then
        if err == "" then
            err = MAIL_INPUT_ADDRESSEE_NAME
        else
            err = string.format(parent.GetLocaString("invalidrecipient"), err) 
        end
    elseif hasPlayer then
        if #recipients == 1 then
            err = parent.GetLocaString("ignoredandnomore")
        end
    end
    for _, v in pairs(me.selected or {}) do
        if v and v.cod > 0 and #recipients ~= 1 then
            err = parent.GetLocaString("codonerecipient")
            errType = 'error'
            break
        end
    end
    local data = {
        recipients = recipients
    }
    if not err then
        return data
    end
    return data, err, errType
end

function me.check()
    local autosend = parent.isAutoSend()
    if autosend == 'msi' then
        return true
    elseif autosend then    
        ZMailFrameBodyMassSendItemsTopSend:Disable()
        return false
    elseif me.lastItem then
        local index = me.lastItem[1]
        me.lastItem[2].sending = nil
        if parent.bag.HasItem(index) then
            ClickSendMailItemButton(1)
            PickupBagItem(index)
            me.selected[index] = me.lastItem[2]
        else
            me.selected[index] = nil
        end
        me.bag.BagUpdate(index)
        me.lastItem = nil
    end
    
    ZMailFrameBodyMassSendItemsTopSend:Enable()
    local data, errmsg, errType = me.ReadUI()
    if errmsg then
        me.SetStatus(1, errmsg, errType)
        return errType ~= 'warn'
    end
    me.SetStatus(1)
    return true
end

function me.updateCount()
    local cnt = 0
    local err = 0
    for _, data in pairs(me.selected) do
        if data then
            cnt = cnt + 1
        else
            err = err + 1
        end
    end
    if cnt > 0 and err == 0 then
        ZMailFrameTab3:SetText(string.format(parent.GetLocaString("tab3count"), cnt))
    elseif cnt > 0 then
        ZMailFrameTab3:SetText(string.format(parent.GetLocaString("tab3counterror"), cnt, err))
    else
        ZMailFrameTab3:SetText(parent.GetLocaString("tab3"))
    end
    me.cod.Update(true)
end

function me.send()
    if parent.isAutoSend() then return false end
    local data, errmsg, errType = me.ReadUI()
    if errmsg then
        me.SetStatus(1, errmsg, errType)
        SendWarningMsg(errmsg)
    else
        me.SetStatus(2)
    end
    if errType == 'warn' or not errmsg then
        me.data = data
        me.data.recipientIndex = 0
        parent.setAutoSend("msi")
        me.bag.sendMail(true)
    end
end


function me.cod.MulitAssignOnClick()
    local val = tonumber(ZMailFrameBodyMassSendItemsExtraCODMoney:GetText()) or 0
    me.cod.multiAssign(val)
end

function me.cod.multiAssign(val)
    for index, data in pairs(me.selected) do
        me.cod.assign(index, val, true)
    end
    me.cod.Update()
    me.check()
end
function me.cod.assign(slot, value, nocheck)
    local data = me.selected[slot]
    if not data then return end
    data.cod = value
    me.bag.BagUpdate(slot)
    if nocheck then return end
    me.check()
end
local function codSort(a,b)
    if a > 60 then
        a = parent.bag.GetBagIndex(a) + 60
    end
    if b > 60 then
        b = parent.bag.GetBagIndex(b) + 60
    end
    return a < b
end
function me.cod.OnMouseWheel(delta)
    local f = ZMailFrameBodyMassSendItemsExtraCODListScroll
    f:SetValue(f:GetValue()- delta/120)
end
function me.cod.Update(reset)
    local framename = "ZMailFrameBodyMassSendItemsExtraCOD"
    local scrollbar = _G[framename.."ListScroll"]
    if reset or not me.cod.data then
        local codData = {}
        for index, data in pairs(me.selected) do
            if data then
                table.insert(codData, index)
            end
        end
        table.sort(codData, codSort)
        me.cod.data = nil
        me.cod.data = codData
        scrollbar:SetMinMaxValues(1, math.max(1, #codData - 15 + 1))
    end
    local offset = scrollbar:GetValue() - 1

    for i=1,15 do
        local entry = _G[framename.."List"..i]
        entry:SetID(0)
        local index = me.cod.data[i+offset]
        if index then
            local data = me.selected[index]
            if not data then
                if not reset then
                    me.cod.Update(true)
                    return
                else
                    parent.debug.error("cod data invalid!")
                end
            end
            local real, tex, name, count, locked, quality = parent.bag.GetItem(index)
            local disabled = parent.bag.IsDisabled(real)
            local itembtn = _G[framename.."List"..i.."Icon"]
            SetItemButtonCount(itembtn, count)
            SetItemButtonTexture(itembtn, tex)
            local qualityTexture = _G[itembtn:GetName().."Quality"];
            if quality > 0 then
                qualityTexture:Show();
                qualityTexture:SetColor(GetItemQualityColor(quality));
            else
                qualityTexture:Hide();
            end
            _G[entry:GetName().."Item"]:SetText(name)
            entry:SetID(index)
            _G[entry:GetName().."Money"]:SetText(data and data.cod or 0)
            _G[entry:GetName().."Money"]:Hide()
            _G[entry:GetName().."MoneyFormatted"]:SetText(zmail.FormatNumber(data and data.cod or 0))
            _G[entry:GetName().."MoneyFormatted"]:Show()
            entry:Show()
        else
            entry:Hide()
        end
    end
end

function me.cod.ItemOnEnter(this)
    local index = this:GetParent():GetID()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", -5, 0);
    GameTooltip:SetBagItem(index);
end
function me.bag.OnLoad(this)
    local parentName = this:GetName()
    for i=1, 6 do
        local bagname = parentName.."Bag"..i
        local bag = _G[bagname]
        bag:ClearAllAnchors();
        if i == 1 then
            bag:SetAnchor("TOPLEFT", "TOPLEFT", parentName, 5, 5)
        elseif (i-1) % 3 == 0 then
            bag:SetAnchor("TOP", "BOTTOM", _G[parentName.."Bag"..(i-3)],0, 2)
        else
            bag:SetAnchor("LEFT", "RIGHT", _G[parentName.."Bag"..(i-1)], 2, 0)
        end
        bag:SetID(i)
        for j=1, 30 do
            local slot = _G[bagname.."Slot"..j]
            slot:ClearAllAnchors();
            if j == 1 then
                slot:SetAnchor("TOPLEFT", "TOPLEFT", bagname, 7, 7)
            elseif (j-1) % 6 == 0 then
                slot:SetAnchor("TOP", "BOTTOM", _G[bagname.."Slot"..(j-6)], 0, 4)
            else
                slot:SetAnchor("LEFT", "RIGHT", _G[bagname.."Slot"..(j-1)], 4, 0)
            end
            slot.index = j
        end
    end
    local cod = "ZMailFrameBodyMassSendItemsExtraCODList"
    for i=1, 15 do
        local entry = _G[cod..i]
        entry:ClearAllAnchors()
		entry:SetBackdropTileAlpha( i % 2==0 and 0.1 or 0.2)
        entry:SetAnchor("TOPLEFT", "TOPLEFT", cod, 15, (i-1)*24+10)
        entry:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", cod, -24, i*24+10)
    end
    
    local transmutor = "ZMailFrameBodyMassSendItemsExtraOtherTransmutor"
    local slots = {
        [2] = { "BOTTOMRIGHT", "LEFT", -3, -3},
        [3] = { "BOTTOMLEFT", "RIGHT", 3, -3},
        [4] = { "TOPRIGHT", "LEFT", -3, 3},
        [5] = { "TOPLEFT", "RIGHT", 3, 3}
    }
    for i = 2, 5 do
        for j=0,1 do
            local slot = _G[transmutor.."Slot"..(j*5) + i]
            local rel = _G[transmutor.."Slot"..(j*5)+1]
            slot:ClearAllAnchors()
            local a, ra, x,y = unpack(slots[i])
            slot:SetAnchor(a,ra,rel,x,y)
        end
    end
    for j=0, 1 do
        local slot = _G[transmutor.."Slot"..(j*5) + 1]
        local  rel = slot:GetParent()
        slot:ClearAllAnchors()
        slot:SetAnchor(j==1 and "LEFT" or "RIGHT", "CENTER", rel, j==1 and 50 or -50, 0)
    end

    local itemshop = "ZMailFrameBodyMassSendItemsExtraOtherItemshop"
    local slot = _G[itemshop.."Slot1"]
    slot:ClearAllAnchors()
    slot:SetAnchor("TOPLEFT", "TOPLEFT", slot:GetParent(), 15, 25)
    for i= 2, 50 do
        local slot = _G[itemshop.."Slot"..i]
        slot:ClearAllAnchors()
        if i % 7 == 1 and i ~= 50 then
            local prev = _G[itemshop.."Slot"..i-7]
            slot:SetAnchor("TOP", "BOTTOM", prev, 0, 2)
        else
            local prev = _G[itemshop.."Slot"..i-1]
            slot:SetAnchor("LEFT", "RIGHT", prev, 2, 0)
        end
    end
end
function me.bag.select(index, select, all, msg, check)
    local data = parent.bag.GetData(index)
    if parent.bag.IsDisabled(index) then
        me.selected[index] = nil
    elseif data and data.mode % 2 == 0 then
        if msg then
            SendWarningMsg(parent.GetLocaString("bound")) 
        end
        me.selected[index] = nil
    elseif data and data.count > 32000 then
        if msg then
            SendWarningMsg(parent.GetLocaString("toomanyitems")) 
        end
        me.selected[index] = nil
    elseif select and parent.bag.HasItem(index) then
        if not me.selected[index] then
            me.selected[index] = { cod = 0 }
        end
    else
        me.selected[index] = nil
    end
    if all and data then
        if all == true then
            if index > 60 then
                all = "bag"
            elseif index > 50 then
                all = "tm"
            else
                all = "is"
            end
        end
        me.selectID(data.id, me.selected[index], all)
    end
    me.bag.BagUpdate(index)
    if check then
        me.check()
        me.updateCount()
    end
end
function me.bag.SlotOnClick(this, key)
    if key == "RBUTTON" then return end
    me.bag.temporarySelect = nil
    local id = this:GetID()
    local all = IsCtrlKeyDown() 
    if IsAltKeyDown() then
        all = 'all'
    end
    me.bag.select(id, me.selected[id] == nil, all, true, true)
end
function me.bag.SlotOnMouseDown(this, key)
    if key == "RBUTTON" then return end
    me.bag.SelectTemporary(this)
end

local function isFrameInBox(frame, xstart, xend, ystart, yend)
    local fxstart, fystart = frame:GetPos()
    if fxstart > xend then return false end
    if fxstart < xstart then return false end
    if fystart > yend then return false end
    if fystart < ystart then return false end
    return true
end
function me.bag.SelectTemporary(frame)
    if frame == nil then
        local data = me.bag.temporarySelect
        me.bag.temporarySelect = nil
        return
    elseif me.bag.temporarySelect == nil then
        me.bag.temporarySelect = {}
        me.bag.temporarySelect.start = frame
    end

    local x1, y1 = me.bag.temporarySelect.start:GetPos()
    local x2, y2 = frame:GetPos()
    local xstart = math.min(x1, x2)
    local xend = math.max(x1, x2)
    local ystart = math.min(y1, y2)
    local yend = math.max(y1, y2)
    local data = {}
    if ZMailFrameBodyMassSendItemsBags:IsVisible() then
        for bag = 1, 6 do
            for slot=1, 30 do
                local frame = _G[string.format("ZMailFrameBodyMassSendItemsBagsBag%dSlot%d", bag, slot)]
                if isFrameInBox(frame, xstart, xend, ystart, yend) then
                    data[GetBagItemInfo((bag-1)*30 + slot)] = true
                end
            end
        end
    else
        local frame = nil
        for i=1 , 60 do
            if i <= 50 then -- itemshop
                frame = _G[string.format("ZMailFrameBodyMassSendItemsExtraOtherItemshopSlot%d", i)]
            else -- transmutor
                frame = _G[string.format("ZMailFrameBodyMassSendItemsExtraOtherTransmutorSlot%d", i-50)]
            end
            if isFrameInBox(frame, xstart, xend, ystart, yend) then
                data[i] = true
            end
        end
    end
    local ts = me.bag.temporarySelect
    for i=1, 240 do
        if ts[i] ~= data[i] then
            if ts[i] then
                ts[i] = nil
            else
                ts[i] = true
            end
            me.bag.BagUpdate(i)
        end
    end
end
function me.bag.SlotOnMouseUp(this, key)
    if key == "RBUTTON" then return end
    if not me.bag.temporarySelect then return end
    local tmp = me.bag.temporarySelect
    me.bag.temporarySelect = nil
    local ctrl = IsCtrlKeyDown()
    local shift = IsShiftKeyDown()
    if shift then
        for i=1,240 do
            if not tmp[i] then
                me.bag.select(i, false, false, false)
            end
        end
    end
    for i=1,240 do
        if tmp[i] then
            local all = IsCtrlKeyDown() 
            if IsAltKeyDown() then
                all = 'all'
            end
            me.bag.select(i, true, all, false)
        end
    end
    me.check()
    me.updateCount()
end
function me.bag.BagUpdate(index)
    if not ZMailFrameBodyMassSendItems:IsVisible() then return end
    local real, tex, name, count, locked, quality = parent.bag.GetItem(index)
    local frame = nil
    if real > 60 then
        local _index = parent.bag.GetBagIndex(real)
        local bag = math.ceil(_index / 30)
        local slot = (( _index - 1 ) % 30) + 1
        frame = _G[string.format("ZMailFrameBodyMassSendItemsBagsBag%dSlot%d", bag, slot)]
    else
        if real <= 50 then -- itemshop
            frame = _G[string.format("ZMailFrameBodyMassSendItemsExtraOtherItemshopSlot%d", real)]
        elseif real <= 60 then -- transmutor
            frame = _G[string.format("ZMailFrameBodyMassSendItemsExtraOtherTransmutorSlot%d", real-50)]
        end
    end
    if not frame then return end
    frame:SetID(real)
    local disabled = parent.bag.IsDisabled(real)
    SetItemButtonCount(frame, count)
    SetItemButtonTexture(frame, tex)
    SetItemButtonLuminance(frame, locked);
    local sel = me.selected[real]
    _G[frame:GetName().."MarkBorder"]:Show()
    if me.bag.temporarySelect and me.bag.temporarySelect[real] then
        if sel and sel.cod > 0 then
            _G[frame:GetName().."MarkBorder"]:SetColor(1,0.84,.4)
        else
            _G[frame:GetName().."MarkBorder"]:SetColor(.4,1,.4)
        end
    elseif sel and sel.sending then
        _G[frame:GetName().."MarkBorder"]:SetColor(.4,.4,1)
    elseif sel then
        if sel.cod > 0 then
            _G[frame:GetName().."MarkBorder"]:SetColor(1,0.84,0)
        else
            _G[frame:GetName().."MarkBorder"]:SetColor(0,1,0)
        end
    elseif sel == false then
        _G[frame:GetName().."MarkBorder"]:SetColor(1,0,0)
    else
        _G[frame:GetName().."MarkBorder"]:Hide()
    end
    local data = parent.bag.GetData(index)
    if disabled then
        _G[frame:GetName().."Invalid"]:Show()
        _G[frame:GetName().."Invalid"]:SetColor(0,0,0)
        _G[frame:GetName().."Invalid"]:SetAlpha(0.5)
    elseif data and (data.mode % 2 == 0 or data.count > 32000) then
        _G[frame:GetName().."Invalid"]:Show()
        _G[frame:GetName().."Invalid"]:SetColor(1,1,1)
        _G[frame:GetName().."Invalid"]:SetAlpha(0.5)
    else
        _G[frame:GetName().."Invalid"]:Hide()
    end
	local qualityTexture = _G[frame:GetName().."Quality"];
	if quality > 0 then
		qualityTexture:Show();
		qualityTexture:SetColor(GetItemQualityColor(quality));
	else
		qualityTexture:Hide();
	end
end
function me.bag.sendMail(success)
    if success  then
        if me.lastItem then
            me.selected[me.lastItem[1]] = nil
            me.bag.BagUpdate(me.lastItem[1])
        end
        me.lastItem = nil
        me.updateCount()
    elseif not success then
        if parent.lastMsg == TEXT("SYS_SENDMAIL_TARGET_MAILFULL") then
            table.remove(me.data.recipients, me.data.recipientIndex)
            me.data.recipientIndex = me.data.recipientIndex - 1
        else
            parent.stopAutoSend()
            return
        end
    end
    if success == false or me.data.recipientIndex == 0 then
        local player = (UnitName("player") or ""):lower()
        repeat
            me.data.recipientIndex = me.data.recipientIndex + 1
            local recipient = (me.data.recipients[me.data.recipientIndex] or "..."):lower()
        until recipient ~= player
        me.SetStatus(2, string.format(parent.GetLocaString("currentrecipient"), me.data.recipients[me.data.recipientIndex] or "" ))
    end
    if #me.data.recipients < me.data.recipientIndex then
        parent.stopAutoSend()
        me.SetStatus(2, parent.GetLocaString("nomorerecipients"), 1,0.5,0)
        return false
    end
    if CursorHasItem() then
        parent.stopAutoSend()
        me.SetStatus(2, parent.GetLocaString("cursoritem"), 1,0.5,0)
        SendWarningMsg(parent.GetLocaString("cursoritem"))
        return false
    end
    if not me.lastItem then
        local item = nil
        for index, data in pairs(me.selected) do
            if data then
                item = {index, data}
                break
            end
        end
        me.lastItem = item
        if not item then
            parent.stopAutoSend()
            me.SetStatus(2, parent.GetLocaString("allsent"), 0,1,0)
            return false
        end
        item[2].sending = true
        PickupBagItem(item[1])
        ClickSendMailItemButton(1)
    end
    if me.lastItem[2].cod > 0 then
        SetSendMailCOD(me.lastItem[2].cod, 0)
    end
    local _, _, name, count, _, _ = parent.bag.GetItem(me.lastItem[1])
    local data = parent.bag.GetData(me.lastItem[1])
    if data and data.id then
        name = ("[%d]"):format(data.id)
    end

    local subject = count > 1 and string.format(parent.GetLocaString("subject"),count, name) or name
    SendMail(me.data.recipients[me.data.recipientIndex], subject , parent.GetLocaString("zmailbrand"))
    return true
end
function me.bag.SlotOnEnter(this)
    local index = this:GetID()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", -5, 0);
    GameTooltip:SetBagItem(index);
    local data = me.selected[index]
    if data and data.cod > 0 then
        GameTooltip:AddLine(string.format(parent.GetLocaString("codTooltip"), MoneyNormalization(data.cod)))
    end
    if me.bag.temporarySelect then
        me.bag.SelectTemporary(this)
    end
end
-- Mark Buttons
function me.mark.ButtonsOnLoad(this)
    local parentName = this:GetName()
    _G[parentName.."Label"]:SetColor(1, 1, 1);
    for i = 1, 20 do
        local button = _G[parentName.."Button"..i];
        button:ClearAllAnchors();
        if i == 1 then
            button:SetAnchor("TOPLEFT", "TOPLEFT", parentName, 34, 0)
        elseif ((i-1) % 10) == 0 then
            button:SetAnchor("TOP", "BOTTOM", _G[parentName.."Button"..(i-10)],0, 0)
        else
            button:SetAnchor("LEFT", "RIGHT", _G[parentName.."Button"..(i-1)], 0, 0)
        end
    end
end
function me.mark.SetButton(key, index, text, recipients)
    -- all also includes itemshop bagpack and arcane transmutor
    if not parent.itemfn.functions[key] then
        parent.debug.warn(string.format("Unknown function %s", key))
        return false
    end
    if type(index)~="number" then return false end 
    me.mark.entries.max = math.max(me.mark.entries.max or 0, index)
    if me.mark.entries[index] then
        parent.debug.warn(string.format("Overwriting %s with %s on index %d", parent.itemfn.functions[index].key, key, index))
    end
    me.mark.entries[index] = {key=key, recipients=recipients, text=text}
    return true
end
function me.mark.UpdateButtons()
    local offset = (me.mark.page-1) * me.mark.buttons

    for i=1, me.mark.buttons do
        local btn = _G["ZMailFrameBodyMassSendItemsMarkButton"..i]
        local data = me.mark.entries[i+offset]
        if data then
            btn:SetText(tostring(data.text or data.key))
            btn:SetID(i+offset)
            btn:Show()
            if me.tempSelect[i+offset] then
                btn:SetTextColor(0,1,0)
            else
                btn:SetTextColor(1,.82,0)
            end
        else
            btn:Hide()
        end
    end
    if me.mark.maxpage == 1 then
        ZMailFrameBodyMassSendItemsMarkDown:Hide()
        ZMailFrameBodyMassSendItemsMarkUp:Hide()
        ZMailFrameBodyMassSendItemsMarkLabel:Hide()
        return
    end
    ZMailFrameBodyMassSendItemsMarkLabel:SetText(string.format("%d/%d", me.mark.page, me.mark.maxpage))
    ZMailFrameBodyMassSendItemsMarkLabel:Show()
    ZMailFrameBodyMassSendItemsMarkDown:Show()
    ZMailFrameBodyMassSendItemsMarkUp:Show()
    if me.mark.page == 1 then
        ZMailFrameBodyMassSendItemsMarkUp:Disable()
        ZMailFrameBodyMassSendItemsMarkDown:Enable()
    else
        ZMailFrameBodyMassSendItemsMarkUp:Enable()
        ZMailFrameBodyMassSendItemsMarkDown:Enable()
    end

    if me.mark.page == me.mark.maxpage then
        ZMailFrameBodyMassSendItemsMarkUp:Enable()
        ZMailFrameBodyMassSendItemsMarkDown:Disable()
    end
end

function me.mark.Load()
    me.mark.entries = {}
    me.mark.page = 1
    me.mark.maxpage = 1
    parent.SendEvent("REGISTER_MSI_BUTTON", me.mark.SetButton)
    local data = parent.loadFile("msi.lua")
    if not data then
        parent.debug.log("please rename msi/_button.lua to msi.lua")
        data = parent.loadFile("msi/_button.lua")
    end
    for index, entry in pairs(data) do
        me.mark.SetButton(entry.key, index, entry.text, entry.recipients, entry.all, true)
    end
    me.mark.maxpage = math.ceil(me.mark.entries.max / me.mark.buttons)
    me.mark.UpdateButtons()
end

function me.mark.MarkByType(fn, select, typ)
    local s,e = 0,0
    if typ == 'bag' or typ == nil then
        s,e = 61,240
    elseif typ == 'is' then
        s,e = 1, 50
    elseif typ == 'tm' then
        s,e = 51,60
    end
    for real = s, e do
        local data = parent.bag.GetData(real)
        if data and data.mode % 2 == 1 and not parent.bag.IsDisabled(real) and data.count <= 32000 then
            if fn(real, data, parent.bag) then
                me.bag.select(real, select, false, false)
            end
        end
    end
end
function me.mark.Mark(key, select, recipients, bagtypes)
    local fn = nil
    if type(key) == "number" then
        local data = me.mark.entries[key]
        if not data then
            parent.debug.debug(string.format("key not found: %s", key))
            return 
        end
        key = data.key
        if recipients == true then
            recipients = data.recipients
        end
    end
    if type(key)~="string" then return end 
    local fndata = parent.itemfn.functions[key]
    if not fndata then
        parent.debug.debug(string.format("key not found: %s", key))
        return 
    end
    if recipients and recipients ~= true then
        local recipients = type(recipients) == "function" and recipients() or recipients
        if type(recipients) ~= "table" then
            local r, e = me.getRecipients(tostring(recipients), true)
            assert(e == nil)
            recipients = r
        end
        local recipient = parent.getRecipientString(recipients)
        ZMailFrameBodyMassSendItemsTopRecipient:SetText(recipient)
    end
    for k, v in pairs(bagtypes or {bag=true}) do
        if v then
            me.mark.MarkByType(fndata.fn, select, k)
        end
    end
    me.check()
    me.updateCount()
end
function me.mark.OnClick(this, key)
    local sel = key ~= "RBUTTON"
    local setRecipients = not IsShiftKeyDown() and sel
    local types = {}
    local all = IsAltKeyDown()
    if all or ZMailFrameBodyMassSendItemsBags:IsVisible() then
        types.bag = true
    end
    if all or ZMailFrameBodyMassSendItemsExtra:IsVisible() then
        types.is = true
        types.tm = true
    end
    if IsCtrlKeyDown() then
        local id = this:GetID()
        if not me.tempSelect[id] then
            me.tempSelect[id] = {sel, setRecipients, types}
            this:SetTextColor(0,1,0)
        else
            me.tempSelect[id] = nil
            this:SetTextColor(1,.82,0)
        end
    else
        me.mark.Mark(this:GetID(), sel, setRecipients, types)
    end
end
function me.mark.OnEnter(this)
    local entry = me.mark.entries[this:GetID()]
    if not entry then return end

    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", -5, 0);
    GameTooltip:SetText(entry.note or entry.key)
    local recipients = entry.recipients
    if recipients then
        GameTooltip:AddLine(parent.GetLocaString("recipient"))
        recipients = type(recipients) == "function" and recipients() or recipients
        GameTooltip:AddLine(" > "..parent.getRecipientString(recipients))
    end
end
function me.mark.OnMouseWheel(this, delta)
    local page = me.mark.page + (delta>0 and -1 or 1)
    me.mark.page = math.max(1, math.min(page, me.mark.maxpage))
    me.mark.UpdateButtons()
end
function me.mark.UpDown_OnClick(this)
    local step = this:GetID()
    me.mark.page = math.max(1, math.min(me.mark.page + step, me.mark.maxpage))
    me.mark.UpdateButtons()
end
parent.massSendItems = me
