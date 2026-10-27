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

UMMBagManager = {

  ItemList = {};
  BySlot = {};
  priv_Dirty = true;

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
    self:Ensure();
    return self.BySlot[slotIndex];
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
        if (entry.Index ~= idx or entry.Link ~= itemLink) then
          -- a different item now: forget its mark and bound state
          entry.Marked = false;
          entry.Bound = nil;
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
  end;

};
