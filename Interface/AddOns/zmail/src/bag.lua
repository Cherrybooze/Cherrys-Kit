local parent = zmail
local me = {
    events = {}
}

local items = {}
local toReal = {}
local toBag = {}

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.bag", fn)
    end
end

function me.events.BAG_ITEM_UPDATE()
    me.UpdateBag(arg1)
end
function me.events.VARIABLES_LOADED()
    me.UpdateBag()
end

function me.HasItem(index)
    if index == nil then
        return nil 
    end
    return items[index] ~= nil
end
function me.GetItem(index)
    if index == nil then
        return nil 
    end
    local rarity = 0
    local texture, name, count, enabled = GetGoodsItemInfo(index)
    if toBag[index] then
        local _, _, _, _,_, quality = GetBagItemInfo(toBag[index])
        rarity = quality
    end
    return index, texture, name, count, enabled, rarity
end
function me.GetBagItem(index)
    return me.GetItem(toReal[index])
end
function me.GetData(index)
    if not index then return end
    return items[index]
end
function me.GetBagData(index)
    return me.GetData(toReal[index])
end
function me.checkBagIndex(index)
    if not index then
        for i=1, 180 do
            if not me.checkBagIndex(GetBagItemInfo(i)) then
                return false
            end
        end
        return true
    end
    if index > 60 then
        return index == GetBagItemInfo(toBag[index] or -1)
    end
    return true
end
function me.fixupBagIndex()
    local old = toReal
    toReal = nil
    toBag = nil
    toReal = {}
    toBag = {}
    for i = 1,180 do
        local real = GetBagItemInfo(i)
        toReal[i] = real
        toBag[real] = i
    end
    parent.SendEvent("MAIL_BAG_INDEX_UPDATE", toReal, old)
end
function me.IsDisabled(real)
    if real > 60 then
        local bag = math.ceil(toBag[real] / 30 )
        local isLet, letTime = GetBagPageLetTime(bag)
        return isLet and letTime == -1
    end
    return false
end
function me.GetBagIndex(real)
    if not real then return nil end
    return toBag[real]
end
function me.UpdateBag(index)
    if not me.checkBagIndex(index) then
        me.fixupBagIndex()
    end
    local first = 1
    local last = 240
    if index then
        first = index
        last = index
    end
    for i=first, last do
        local old = items[i]
        local _, _, count, val  = GetGoodsItemInfo(i)
        if old and count == 0 and old[2] ~= 0 then
            items[i] = nil
            parent.SendEvent("MAIL_BAG_ITEM_UPDATE", 0, i)
        elseif count > 0 then
            local link = GetBagItemLink(i, false)
            if link == nil then
                if items[i] and not items[i].nolink then
                    items[i].nolink = true
                    parent.SendEvent("MAIL_BAG_ITEM_UPDATE", 1, i)
                end
            else
                local _, data = ParseHyperlink(link)
                local id, mode, misc, data = data:match("^(%x+) (%x+) (%x+) (.+) %x+$")
                id = tonumber(id, 16)
                mode = tonumber(mode, 16)
                local nmisc = string.format("%x", tonumber(misc, 16) % 0x800000 ) --workaround for a weird bug
                if old == nil or id ~= old.id or mode ~= old.mode or nmisc~=old.nmisc or data ~= old.data or count ~= old.count then
                    items[i] = {id=id, nmisc=nmisc, misc=misc, mode=mode, count=count, data=data, db=parent.itemlib.read(link), nolink = false}
                    parent.SendEvent("MAIL_BAG_ITEM_UPDATE", 2, i)
                elseif old and old.nolink then
                    items[i].nolink = false
                    parent.SendEvent("MAIL_BAG_ITEM_UPDATE", 1, i)
                end
            end
        end
    end
end

parent.bag = me
