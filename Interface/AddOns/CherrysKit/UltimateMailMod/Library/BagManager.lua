-- ###################
-- ##               ##
-- ##  Bag Manager  ##
-- ##               ##
-- ###################
--
-- Cherry's Kit: the item list is no longer rebuilt from scratch on every PLAYER_BAG_CHANGED
-- (the game fires it at least once per mail sent, so a 60 mail run rebuilt all 180 slots over
-- and over). A change only marks the list dirty; it is reloaded when something reads it, or by
-- the master frame once the bags settle. Entries are reused, marks survive while the same item
-- stays in its slot, and bound checks are cached per slot.

-- The same item, judged by what stays put: the item id from the link (the rest of a RoM link can
-- change while the item sits in its slot, or be missing right after the item arrives) and the name.
function UMMItemId(link)
  return type(link) == "string" and string.match(link, "item:(%x+)") or nil;
end

function UMMSameItem(link, name, otherLink, otherName)
  local id, otherId = UMMItemId(link), UMMItemId(otherLink);
  if (id and otherId) then
    return id == otherId;
  end
  local linkName = type(link) == "string" and string.match(link, "%[(.-)%]") or name;
  local otherLinkName = type(otherLink) == "string" and string.match(otherLink, "%[(.-)%]") or otherName;
  return linkName ~= nil and linkName == otherLinkName;
end

-- Body slots of the arcane transmutor (magic box): 51-60, after the 50 item shop slots.
UMM_TRANSMUTOR_FIRST = 51;
UMM_TRANSMUTOR_LAST = 60;

function UMMIsTransmutorSlot(slot)
  return type(slot) == "number" and slot >= UMM_TRANSMUTOR_FIRST and slot <= UMM_TRANSMUTOR_LAST;
end

UMMBagManager = {

  ItemList = {};
  BySlot = {};
  priv_Dirty = true;
  Revision = 0;

  Invalidate = function(self)
    self.priv_Dirty = true;
  end;

  IsDirty = function(self)
    return self.priv_Dirty;
  end;

  Ensure = function(self)
    if (self.priv_Dirty or table.getn(self.ItemList) < 180) then
      self:Load();
    end
  end;

  GetItem = function(self, slotIndex)
    if (UMMIsTransmutorSlot(slotIndex)) then
      return self:TransmutorItem(slotIndex);
    end
    self:Ensure();
    return self.BySlot[slotIndex];
  end;

  -- An item in the arcane transmutor. The game keeps those in body slots 51-60, outside the
  -- 180 bag slots, so the bag list never has them; the mail server sends from any body slot.
  -- Read live (only a drop or a send asks), one entry per slot so the bound check is cached.
  Transmutor = {};

  TransmutorItem = function(self, slotIndex)
    local texture, name, itemCount = nil, nil, 0;
    if (GetGoodsItemInfo) then
      texture, name, itemCount = GetGoodsItemInfo(slotIndex);
    end
    local link = (texture ~= nil and texture ~= "") and GetBagItemLink(slotIndex) or nil;
    if (not link) then
      self.Transmutor[slotIndex] = nil;
      return nil;
    end
    local entry = self.Transmutor[slotIndex];
    if (entry == nil or not UMMSameItem(entry.Link, entry.Name, link, name)) then
      entry = { Index = slotIndex, Empty = false, Marked = false, Transmutor = true };
      self.Transmutor[slotIndex] = entry;
    end
    entry.Icon = texture;
    entry.Name = name;
    entry.Count = itemCount or 1;
    entry.Link = link;
    return entry;
  end;

  -- The bag slot now holding this item (an item taken back out of the transmutor), or nil.
  FindInBag = function(self, link, name, skip)
    self:Ensure();
    for i = 1, table.getn(self.ItemList) do
      local entry = self.ItemList[i];
      if (not entry.Empty and not (skip and skip[entry.Index]) and UMMSameItem(entry.Link, entry.Name, link, name)) then
        return entry;
      end
    end
    return nil;
  end;

  MarkItem = function(self, slotIndex)
    local item = self:GetItem(slotIndex);
    if (item) then
      item.Marked = true;
    end
  end;

  UnMarkItem = function(self, slotIndex)
    local item = self:GetItem(slotIndex);
    if (item) then
      item.Marked = false;
    end
  end;

  ClearMarks = function(self)
    for i = 1, table.getn(self.ItemList) do
      self.ItemList[i].Marked = false;
    end
  end;

  -- True when the item can not be mailed. Read from the tooltip once per item, then cached.
  IsBound = function(self, item)
    if (item == nil or item.Empty) then
      return false;
    end
    if (item.Bound == nil) then
      item.Bound = UMMMailComposer:ItemIsBound(item.Index) and true or false;
    end
    return item.Bound;
  end;

  -- Marked items: how many can be sent, how many are bound
  CountMarked = function(self)
    self:Ensure();
    local send, bound = 0, 0;
    for i = 1, table.getn(self.ItemList) do
      local item = self.ItemList[i];
      if (item.Marked == true and not item.Empty) then
        if (self:IsBound(item)) then
          bound = bound + 1;
        else
          send = send + 1;
        end
      end
    end
    return send, bound;
  end;

  HasEmptySlot = function(self)
    self:Ensure();
    for i = 1, table.getn(self.ItemList) do
      if (self.ItemList[i].Empty == true) then
        return true;
      end
    end
    return false;
  end;

  Clear = function(self)
    self.ItemList = {};
    self.BySlot = {};
    self.priv_Dirty = true;
    self.Revision = self.Revision + 1;
  end;

  Load = function(self)
    local list = self.ItemList;
    local bySlot = {};
    for itemIndex = 1, 180 do
      local entry = list[itemIndex];
      if (entry == nil) then
        entry = { Index = 0, Empty = true, Count = 0, Marked = false };
        list[itemIndex] = entry;
      end
      local idx, texture, name, itemCount = GetBagItemInfo(itemIndex);
      if (texture ~= nil and texture ~= "" and idx) then
        local itemLink = GetBagItemLink(idx);
        if (entry.Empty or entry.Index ~= idx or not UMMSameItem(entry.Link, entry.Name, itemLink, name)) then
          -- a different item now: forget its mark and bound state
          entry.Marked = false;
          entry.Bound = nil;
        elseif (entry.Link == nil and itemLink ~= nil) then
          entry.Bound = nil;  -- read before the game had the link: check again
        end
        entry.Index = idx;
        entry.Icon = texture;
        entry.Count = itemCount;
        entry.Link = itemLink;
        entry.Name = name;
        entry.Empty = false;
        bySlot[idx] = entry;
      else
        entry.Index = 0;
        entry.Empty = true;
        entry.Icon = nil;
        entry.Count = 0;
        entry.Link = nil;
        entry.Name = nil;
        entry.Marked = false;
        entry.Bound = false;
      end
    end
    self.BySlot = bySlot;
    self.priv_Dirty = false;
    self.Revision = self.Revision + 1;
  end;

};
