local NEXT, Register, Get, GetHelper, RegisterHelper = ...

local GetTierFn = GetHelper("getTierFn")
local GetTierStoneFn = GetHelper("GetTierStoneFn")
local GetStatsFn = GetHelper("getStatsFn")

local function crap(index, item)
    local id = item.id
    if id < 210000 or id > 240000 then
        return false
    end
    -- all t1-t5 items and projectiles
    if item.db:getCost(id) == 0 then 
        return false 
    end
    if item.count > 1 then
        return true
    end
    return item.db:getFusionRarity() < 6
end

Register("crap", crap, "Crap items")
for i = 1, 20 do
    Register("T"..i, GetTierFn(i, false), string.format("T%d", i))
    Register("T"..i.."Clean", GetTierFn(i, "clean"), string.format("T%d Clean", i))
    Register("T"..i.."Crap", GetTierFn(i, "crap"), string.format("T%d Crap", i))

    Register("T"..i.."Stone", GetTierStoneFn(i, false), string.format("T%d Stone", i))
    Register("T"..i.."StoneClean", GetTierStoneFn(i, "clean"), string.format("T%d Stone Clean", i))
    Register("T"..i.."StoneCrap", GetTierStoneFn(i, "crap"), string.format("T%d Stone Crap", i))
end

local BagStats = {
   [510820] = {}, -- Geschwindigkeit
   [510920] = {}, -- Observanz
   [511100] = {}, -- Schimmer
   [511200] = {}, -- Berglöwe
   [511300] = {}, -- Fuchs
   [511440] = {}, -- Expansion
   [511580] = {}, -- Hammer
   [511900] = {}, -- Verschlinger
   [510840] = {'pdd'}, -- Reißzahn
   [511000] = {}, -- Illusion
   [511120] = {'tank'}, -- Abschottung
   [511220] = {'pdd'}, -- Barbar
   [511340] = {}, -- Weiser
   [511460] = {}, -- Trübung
   [511600] = {}, -- Grausamkeit
   [511940] = {}, -- Grimoire
   [510860] = {}, -- Reflex
   [511020] = {'mdd'}, -- Leuchten
   [511140] = {}, -- Überlegenheit
   [511240] = {}, -- Verteidiger
   [511360] = {'heal'}, -- Mönch
   [511500] = {}, -- Gelehrter
   [511620] = {}, -- Moral
   [512010] = {}, -- Blitz
   [510880] = {}, -- Gewandtheit
   [511040] = {}, -- Genie
   [511160] = {'tank'}, -- Unterdrückung
   [511260] = {}, -- Paladin
   [511400] = {}, -- Härte
   [511520] = {}, -- Gebirgsmassiv
   [511640] = {}, -- Wut
   [512030] = {}, -- Flink
   [510900] = {}, -- Genauigkeit
   [511060] = {}, -- Seele
   [511180] = {'tank'}, -- Autorität
   [511280] = {'tank', 'pdd'}, -- Wildheit
   [511420] = {'mdd'}, -- Ältester
   [511540] = {}, -- Donner
   [511740] = {}, -- Lumen
   [512050] = {}, -- Rage
}

local function GetUseful(lvl, mygroups)
    if type(mygroups) == "string" then
        mygroups = {mygroups}
    end
    if type(mygroups) =="table" then
        local res = {}
        for _, key in pairs(mygroups) do
            res[key] = true
        end
        mygroups = res
    end
    local list = {}
    local cnt = 0
    for id, groups in pairs(BagStats) do
        if mygroups == true then
            if #groups > 0 then
                list[id + lvl - 1] = true
                cnt = cnt + 1
            end
        else
            for _, group in pairs(groups) do
                if mygroups[group] then
                    list[id + lvl - 1] = true
                    cnt = cnt + 1
                end
            end
        end
    end
    assert(cnt > 0, "No Useful Stat found (Empty Table)")
    return GetStatsFn(list)
end

Register("UsefulBagStat", GetUseful(17, true), "UsefulBagStat")

local statlist = {}
for i=514667, 514824 do
    table.insert(statlist, i)
end
Register("NoM", GetStatsFn(statlist), "NoM")
