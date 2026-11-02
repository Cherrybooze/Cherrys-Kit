local function GetBagPageFn(page)
    return function(realindex, _, bag)
        local bagindex = bag.GetBagIndex(realindex)
        return bagindex > (page-1)*30 and bagindex <= page * 30
    end
end
local function ItemID(id, stack)
    if stack then
        return { function(_, item) return item.id == id and stack == item.count end, string.format("%s (%s)", GetObjName(id), tostring(stack))}
    else
        return { function(_, item) return item.id == id end, GetObjName(id)}
    end
end

local function Cenedril(_, item)
    return item.id >= 209873 and item.id <= 209944 
end
local function CenedrilS(_, item)
    return item.id >= 209873 and item.id <= 209944 and item.id % 3 == 0
end
local function CenedrilM(_, item)
    return item.id >= 209873 and item.id <= 209944 and item.id % 3 == 1
end
local function CenedrilD(_, item)
    return item.id >= 209873 and item.id <= 209944 and item.id % 3 == 2
end
local function ProductionRunes(_, item)
    return item.id >= 200850 and item.id <= 200855 
end
local function ProductionRunesStack(_, item)
    return item.id >= 200850 and item.id <= 200855 and item.count == 100
end
local function Runes(_, item)
    return item.id > 520000 and item.id < 530000
end
local function ProduktionMaterial(_, item)
    return (item.id > 202100 and item.id < 202133) or 
        (item.id > 207408 and item.id < 208256) or 
        (item.id > 240409 and item.id < 240414) or 
        (item.id > 241462 and item.id < 241467) or 
        (item.id > 242062 and item.id < 242067) or 
        (item.id > 242313 and item.id < 242330)
end
local function GetTierRuneFn(tier)
    tier = tier % 20
    return function(realindex, item)
        return Runes(nil, item) and item.id % 20 == tier
    end
end
local function GetTierRuneStackFn(tier)
    tier = tier % 20
    return function(realindex, item)
        return Runes(nil, item) and item.id % 20 == tier and item.count == 99
    end
end
local function Manastone(_, item) -- itemtype = 35
    return item.id >= 202840 and item.id <= 202859
end
local function ManastoneTier(tier)
    return function(realindex, item)
        return Manastone(nil, item) and item.id - 202839 == tier
    end
end
local function MonsterCards(_, item)
    return item.id >= 770000 and item.id <= 779999
end
local function AllPetEggs(_, item)
    return item.id >= 204476 and item.id <= 204505
end
local function HolyPetEggs(_, item)
    return item.id >= 204500 and item.id <= 204505
end
local function NoElementEggs(_, item)
    return item.id >= 204506 and item.id <= 204509
end
local function LightEggs(_, item)
    return item.id % 6 == 0 and item.id >= 204476 and item.id <= 204505
end
local function DarkEggs(_, item)
    return item.id % 6 == 1 and item.id >= 204476 and item.id <= 204505
end
local function EarthEggs(_, item)
    return item.id % 6 == 2 and item.id >= 204476 and item.id <= 204505
end
local function WaterEggs(_, item)
    return item.id % 6 == 3 and item.id >= 204476 and item.id <= 204505
end
local function FireEggs(_, item)
    return item.id % 6 == 4 and item.id >= 204476 and item.id <= 204505
end
local function WindEggs(_, item)
    return item.id % 6 == 5 and item.id >= 204476 and item.id <= 204505
end
local function Recipe(_, item)
    return item.id >= 550000 and item.id <= 559999
end
local function EXPSphere(_, item)
    return (item.id >= 203276 and item.id <= 203279) or item.id == 206902 or (item.id >= 242546 and item.id <= 242548)
end
local function TPSphere(_, item)
    return (item.id >= 203064 and item.id <= 203067) or item.id == 203580 or item.id == 209984 or item.id == 209985 or (item.id >= 242549 and item.id <= 242554)
end
local function EXPTPSphere(_, item)
    return EXPSphere(_, item) or TPSphere(_, item)
end

local out = {
    Manastone = {Manastone, "Manastone T1-20"},
    ProductionRunes = {ProductionRunes, "Production Runes"},
    ProductionRunesStack = {ProductionRunesStack, "Production Runes Stack"},
    Runes = {Runes, "All Runes"},
    Cenedril = {Cenedril, "Cenedril Materials"},    
    CenedrilS = {CenedrilS, "Cenedril Wehrhaft"},
    CenedrilM = {CenedrilM, "Cenedril Mystisch"},
    CenedrilD = {CenedrilD, "Cenedril Dynamisch"},
    MonsterCards = {MonsterCards, "MonsterCards"},
    AllPetEggs = {AllPetEggs, "AllPetEggs"},
    HolyPetEggs = {HolyPetEggs, "HolyPetEggs"},
    NoElementEggs = {NoElementEggs, "NoElementEggs"},
    LightEggs = {LightEggs, "LightEggs"},
    DarkEggs = {DarkEggs, "DarkEggs"},
    EarthEggs = {EarthEggs, "EarthEggs"},
    WaterEggs = {WaterEggs, "WaterEggs"},
    FireEggs = {FireEggs, "FireEggs"},
    WindEggs = {WindEggs, "WindEggs"},
    ProduktionMaterial = {ProduktionMaterial, "ProduktionMaterial"},
    EXPTPSphere = {EXPTPSphere, "EXP and TP Sphere"},
    EXPSphere = {EXPSphere, "EXP Sphere"},
    TPSphere = {TPSphere, "TP Sphere"},
}

for index, name in ipairs({'Link', 'Frost', 'Activate','Disenchant','Purify','Blend'}) do
    out[name..'Rune'] = ItemID(200850 + index - 1)
    out[name..'RuneStack'] = ItemID(200850 + index - 1,100)
end

for i=1,10 do
    out["Runes"..i] = {GetTierRuneFn(i), "Runes Tier"..i}
end
for i=1,10 do
    out["Runes"..i.."Stack"] = {GetTierRuneStackFn(i), "Runes Tier"..i}
end
for i=1,6 do
    out["Bag"..i] = {GetBagPageFn(i), "Bagpage"..i}
end
for i=1,20 do
    out["ManastoneT"..i] = {ManastoneTier(i), "Manastone Tier"..i}
end

return out
