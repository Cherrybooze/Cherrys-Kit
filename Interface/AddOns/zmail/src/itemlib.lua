local parent = zmail
local me = {fn = {}}


local cache = {}
local lv_string = string.format("^%s.+%s (%%d+)", TEXT("TOOLTIP_LIMIT_TEXT"), TEXT("SYS_LEVEL"))
local cost_string = string.format("^%s (.+) %s$", TEXT("SYS_ITEM_COST"), TEXT("SYS_GOLD"))
local function parseTooltip(id)
    local c = cache[id]
    if c then return c end
    GameTooltip:SetHyperLink(string.format("|Hitem:%x|h|h", id))
    GameTooltip:Hide()
    local data = {}
    for i=1,10 do
        if not data.lv then
            data.lv = tonumber(_G["GameTooltipTextLeft"..i]:GetText():match(lv_string) or "")
        end
        if not data.cost then
            data.cost = tonumber(_G["GameTooltipTextLeft"..i]:GetText():match(cost_string) or "")
        end
    end
    cache[id] = data
    return data
end

local fn = me.fn
function fn.__index(table, key)
  return fn[key]
end

function fn.hasData(self)
  return self.data.data ~= nil
end
function fn.isPetEgg(self)
  local id = self:getID()
  return id >= 204476 and id <= 204509
end
function fn.getLevel(self)
    return parseTooltip(self:getID()).lv or 0
end
function fn.getCost(self)
    return parseTooltip(self:getID()).cost
end

function fn.getFusionRarity(self)
    local add = {0,2,5,9,12,15,20,24,28,35}
    local lv = self:getLevel()
    local rarity = GetQualityByGUID(self:getID())
    add = add[rarity+1] or 0
    return math.floor((lv - 1 + add*3/2)/20) + 1
end

function fn.isPimped(self)
    if #self:getStats() == 6 then return true end
    if #self:getRunes() > 1 then return true end
    if self:getPlus() > 1 then return true end
    if self:getDeltaTier() > 0 then return true end
    return false
end
-- ! ///////////////////////////////////
-- ! //////////// all items ////////////
-- ! ///////////////////////////////////
function fn.getMode(self)
  if self.data.modestruct then
    return self.data.modestruct
  end
  local mode = tonumber(self.data.mode, 16)
  local flags = {}
  while mode > 0 do
    local low = mode % 2
    local mode = (mode - low) / 2
    table.insert(flags, low == 1)
  end
  local trade = table.remove(flags, 1)
  local soulbound = table.remove(flags, 1)
  local unk1 = table.remove(flags, 1)
  local itemlock = table.remove(flags, 1)
  local protect = table.remove(flags, 1)
  local unk2 = table.remove(flags, 1)
  local unk3 = table.remove(flags, 1)
  local unk4 = table.remove(flags, 1)
  local pkprotect = table.remove(flags, 1)
  local unk5 = table.remove(flags, 1)
  local setskill = table.remove(flags, 1)
  local tmp = {
    trade = trade, --
    soulbound = soulbound, --
    itemlock = itemlock, --
    protect = protect, --
    pkprotect = pkprotect, --
    setskill = setskill, --
  }
  self.data.modestruct = tmp
  return tmp
end

-- ! ///////////////////////////////////
-- ! ////////// weapon/armor ///////////
-- ! ///////////////////////////////////
function fn.getBaseData(self)
  if self.data.basedata then
    return self.data.basedata
  end

  local misc = string.format('%08s', self.data.data[1]) -- orgQuality, quality, power_rare, level_rune
  local dura = tonumber(self.data.data[9], 16) / 100 --  dura
  local _, plus_slots, tier_rarity, maxdura = misc:match('(%x%x)(%x%x)(%x%x)(%x%x)')
  plus_slots = tonumber(plus_slots, 16)
  tier_rarity = tonumber(tier_rarity, 16)
  maxdura = tonumber(maxdura, 16)
  local plus = plus_slots % 0x20
  local empty_rune = (plus_slots - plus) / 0x20

  local tier = tier_rarity % 0x20
  local rarity = (tier_rarity - tier) / 0x20
  tier = tier - 10
  -- tier > 10: green tooltip
  -- tier < 10 red tooltip
  -- tier == 10 white tooltip

  local data = {
    plus = plus,--
    empty_rune = empty_rune,--
    tier = tier,--
    rarity = rarity,--
    maxdura = maxdura,--
    dura = dura--
  }
  self.data.basedata = data
  return data  
end

function fn.getPlus(self)
  return self:getBaseData().plus
end
function fn.getDeltaTier(self)
  return self:getBaseData().tier
end

function fn.getStats(self)
  if self.data.stats then
    return self.data.stats
  end
  local stats = {}
  for i = 2, 4 do
    local str = string.format('%08s', self.data.data[i]) -- stat
    local ids = {str:match('(%x%x%x%x)(%x%x%x%x)')}
    for _, id in pairs(ids) do
      local num = tonumber(id, 16)
      if num > 0 then
        table.insert(stats, num < 40000 and num + 500000 or num + 0x70000)
      end
    end
  end
  self.data.stats = stats
  return stats
end

function fn.getRunes(self)
  if self.data.runes then
    return self.data.runes
  end
  local runes = {}
  for i = 5, 8 do
    local id = tonumber(self.data.data[i], 16)
    if id > 0 then
      table.insert(runes, id)
    end
  end
  self.data.runes = runes
  return runes
end

-- ! ///////////////////////////////////
-- ! //////////// Pet eggs /////////////
-- ! ///////////////////////////////////

function fn.getPetValues(self)
  if self.data.pet then
    return self.data.pet
  end
  if not self:isPetEgg() then
    return nil
 end
  local time1 = self.data.data[1]
  local time2 = self.data.data[2]
  local petID = tonumber(self.data.data[3], 16) -- petID
  local TP = tonumber(self.data.data[4], 16) -- TP
  local ability3 = string.format('%08s', self.data.data[5]) -- train Lv Prop Typ
  local ability4 = string.format('%08s', self.data.data[6]) -- Strength Talent
  local ability5 = string.format('%08s', self.data.data[7]) -- Int Sta
  local ability6 = string.format('%08s', self.data.data[8]) -- Agi Mnd

  local _train, _lv, _prop, _typ = ability3:match('(%x%x)(%x%x)(%x%x)(%x%x)')
  local _str, _talent = ability4:match('(%x%x%x%x)(%x%x%x%x)')
  local _int, _sta = ability5:match('(%x%x%x%x)(%x%x%x%x)')
  local _agi, _mnd = ability6:match('(%x%x%x%x)(%x%x%x%x)')

  local res = {
    id = petID, --
    tp = TP, --
    -- train = tonumber(_train, 16), always 0
    lv = tonumber(_lv, 16), --
    prop = tonumber(_prop, 16), -- unknown
    typ = tonumber(_typ, 16), --
    talent = tonumber(_talent, 16), -- Begabung
    str = tonumber(_str, 16), --
    int = tonumber(_int, 16), --
    sta = tonumber(_sta, 16), --
    agi = tonumber(_agi, 16), --
    mnd = tonumber(_mnd, 16),
  }
  self.data.pet = res
  return res
end

function fn.getID(self)
  return self.data.id
end

function me.read(link)
  local id, other = string.match(link or '', '|Hitem:(%x+)(.-)|h')
  id = tonumber(id, 16)
  assert(id, 'Error: Couldn\'t read item link')

  local data = {other:match('^ (%x+) (%x+) (%x+) (%x+) (%x+) (%x+) (%x+) (%x+) (%x+) (%x+) (%x+)$')}
  local mode = table.remove(data, 1)
  local ret = {data = {id = id}}
  setmetatable(ret, fn)
  if mode then
    ret.data.mode = mode
    ret.data.data = data
  end
  return ret
end

parent.itemlib = me
