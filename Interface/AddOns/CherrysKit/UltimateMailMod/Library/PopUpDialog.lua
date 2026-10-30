
function UMMPopUpDialogTemplate_OnLoad(this)
  
  this.priv_Actions = {};
  this.priv_Lines   = {};
  this.priv_Money   = 0;
  
  this.internal_FormatNumber = function(self, n)
    return UMMFormatNumber(n);   -- Cherry's Kit: same 1,234,567 grouping as the backpack
  end;
  
  this.Clear = function(self)
    self.priv_Actions = {};
    self.priv_Lines = {};
    self.priv_Money = 0;
    self:Hide();
  end;
  
  this.AddLine = function(self, text)
    table.insert(self.priv_Lines, text);
  end;
  
  this.SetMoney = function(self, amount)
    self.priv_Money = amount;
  end;
  
  this.AddButton = function(self, caption, func)
    local button = {};
    button.Caption = caption;
    button.execFunc = func;
    table.insert(self.priv_Actions, button);
  end;
  
  this.ButtonClick = function(self, id)
    if (self.priv_Actions[id]) then
      local fnc = self.priv_Actions[id].execFunc;
      if (fnc) then
        fnc();
      end
    end
    self:Hide();
  end;
  
  this.Pop = function(self)
    local yellow = "ffe600";
    local white = "ffffff";
    
    self:ClearAllAnchors();
    self:SetAnchor("TOP", "TOP", "UIParent", 0, 150);
    
    for l = 1, 10 do
      getglobal(self:GetName().."Label"..l):Hide();
      getglobal(self:GetName().."Label"..l):SetText("");
    end
    local y = 15;
    local h = 30;
    for l = 1, table.getn(self.priv_Lines) do
      local label = getglobal(self:GetName().."Label"..l);
      label:ClearAllAnchors();
      label:SetAnchor("TOPLEFT", "TOPLEFT", self:GetName(), 15, y);
      label:SetText("|cff"..white..self.priv_Lines[l].."|r");
      label:Show();
      y = y + 15;
      h = h + 15;
    end
    if (self.priv_Money > 0) then
      y = y + 5;
      h = h + 5;
      local goldLabel = getglobal(self:GetName().."Amount");
      goldLabel:SetText("|cff"..yellow..self:internal_FormatNumber(self.priv_Money).."|r");
      local w = goldLabel:GetWidth() + 20;
      goldLabel:ClearAllAnchors();
      goldLabel:SetAnchor("TOPLEFT", "TOPLEFT", self:GetName(), ((self:GetWidth() - w) / 2), y);
      goldLabel:Show();
      getglobal(self:GetName().."GoldCoin"):Show();
      y = y + 16;
      h = h + 16;
    else
      getglobal(self:GetName().."Amount"):Hide();
      getglobal(self:GetName().."GoldCoin"):Hide();
    end
    if (table.getn(self.priv_Actions) > 0) then
      y = y + 5;
      h = h + 5;
      local w = (self:GetWidth() - (table.getn(self.priv_Actions) * 75)) / (table.getn(self.priv_Actions) + 1);
      for index = 1, table.getn(self.priv_Actions) do
        local button = getglobal(self:GetName().."Button"..index);
        button:ClearAllAnchors();
        button:SetAnchor("TOPLEFT", "TOPLEFT", self:GetName(), 10 + (w * index) + ((index * 75) - 75), y);
        button:SetText(self.priv_Actions[index].Caption);
        button:Show();
      end
      h = h + 25;
    end
    
    self:SetHeight(h);
    self:Show();
  end;
  
end
