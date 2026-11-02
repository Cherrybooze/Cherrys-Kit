local NEXT, Register, Get, GetHelper, RegisterHelper = ...

local function isClean(item)
	return #item.db:getStats() == 0
end
local exception = {
    --[123456] = true,
    --[123456] = true,
}
local function GetTierExceptionFn(tier, type)
    return function(index, item)
        local id = item.id
        if id < 210000 or id > 240000 then
            return false
        end
        if exception[id] then
            return false
        end
        if item.count > 1 then
            return false
        end
        local rarity = GetQualityByGUID(id)
        if rarity >= 3 then return false end; -- ignore purple
        if item.db:isPimped() then return false end
        if item.db:getFusionRarity() ~= tier then return false end
        if type == "clean" then
			return isClean(item)
		elseif type == "crap" then
			return not isClean(item)
		end
        return true
    end
end
local function GetTierFn(tier, type)
    return function(index, item)
        local id = item.id
        if id < 210000 or id > 240000 then
            return false
        end
        if item.count > 1 then
            return false
        end
        local rarity = GetQualityByGUID(id)
        if rarity >= 3 then return false end; -- ignore purple
        if item.db:isPimped() then return false end
        if item.db:getFusionRarity() ~= tier then return false end
        if type == "clean" then
			return isClean(item)
		elseif type == "crap" then
			return not isClean(item)
		end
        return true
    end
end
local function GetTierStoneFn(tier, type)
    return function(index, item)
        local id = item.id
        if id ~= tier + 202840 - 1 then
            return false
        end
        if type == "clean" then
			return isClean(item)
		elseif type == "crap" then
			return not isClean(item)
		end
        return true
    end
end
local function GetStatsFn(StatList)
    return function(index, item)
        local id = item.id
        if id < 210000 or id > 240000 then
            return false
        end
        if item.count > 1 then
            return false
        end
        if GetQualityByGUID(id) >= 3 then return false end; -- ignore purple
        if pimped(index, item) then return false end
        if #item.db:getStats() ~= 1 then return false end

        for k, v in pairs(item.db:getStats()) do
            if StatList[v.ID] then return true end
        end
    end
end
RegisterHelper("getTierFn", GetTierFn)
RegisterHelper("GetTierExceptionFn", GetTierExceptionFn)
RegisterHelper("GetTierStoneFn", GetTierStoneFn)
RegisterHelper("getStatsFn", GetStatsFn)
