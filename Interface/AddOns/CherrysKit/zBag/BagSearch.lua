DEFAULT_CHAT_FRAME:AddMessage("BagSearch 1.21 LOADED")

function FindBagItemByName( itemName )
	if type(itemName) ~= "string" then
	  return nil
	end

	local occupiedSlots, availableSlots, totalSlots = GetBagCount()

	local itemList = {}

	for i=1,totalSlots do
	  local inventoryIndex, icon, name, itemCount, locked, quality = GetBagItemInfo (i)
	  if string.find(string.lower(name),string.lower(itemName),1,true) then
		table.insert(itemList,i)
	  end
	end
	return itemList
end

function FindGoodsItemByName( itemName )
	if type(itemName) ~= "string" then
	  return nil
	end

	local itemList = {}

	for i=1,50 do
	  local icon, name, itemCount, locked = GetGoodsItemInfo( i );
	  if string.find(string.lower(name),string.lower(itemName),1,true) then
		table.insert(itemList,i)
	  end
	end
	return itemList
end

function ItemInBag( itemSlot )
	return math.ceil(itemSlot/30)
end

function ItemInBankBag( itemSlot )
	return math.ceil(itemSlot/40)
end

function FindBankItemByName( itemName )
	if type(itemName) ~= "string" then
	  return nil
	end

	local itemList = {}

	for i=1,200 do
	  local texture, name, count, locked = GetBankItemInfo(i)
	  if name and string.find(string.lower(name),string.lower(itemName),1,true) then
		table.insert(itemList,i)
	  end
	end
	return itemList
end

function UsedBags ( itemList )
	local BagUsed = {false,false,false,false,false,false}
	for i,k in pairs(itemList) do
		BagUsed[ItemInBag(k)] = true
	end
	return BagUsed
end

function UsedBankBags ( itemList )
	local BagUsed = {false,false,false,false,false,false}
	for i,k in pairs(itemList) do
		BagUsed[ItemInBankBag(k)] = true
	end
	return BagUsed
end

function SetButtonAlpha( storeType, itemSlot, alphaVal)
	local itemButton = getglobal( storeType .. "ItemButton" .. itemSlot )
	itemButton:SetAlpha(alphaVal)
end	

function SetStorageTabColor( storeType, bag,rColor,gColor,bColor)
	local buttonBaseName = storeType .. "FrameTab"
	local enabledLeft = getglobal(buttonBaseName .. bag .. "Left")
	local enabledRight = getglobal(buttonBaseName .. bag .. "Right")
	local enabledMiddle = getglobal(buttonBaseName .. bag .. "Middle")
	local disabledLeft = getglobal(buttonBaseName .. bag .. "LeftDisabled")
	local disabledRight = getglobal(buttonBaseName .. bag .. "RightDisabled")
	local disabledMiddle = getglobal(buttonBaseName .. bag .. "MiddleDisabled")
	local tabFrames={enabledLeft,enabledRight,enabledMiddle,disabledLeft,disabledRight,disabledMiddle}
	for n=1,6 do
		tabFrames[n]:SetColor(rColor,gColor,bColor)
	end
end

function BagSearch(itemName)
	local itemList = FindBagItemByName(itemName)
	local usedBagsList = UsedBags(itemList)
	local currentBag = PanelTemplates_GetSelectedTab(BagFrame)
	local currentBagSlot = nil
	local itemButton = nil
	for n=1,180 do
		SetButtonAlpha("Bag",n,0.2)
	end
	for k,i in pairs(itemList) do
		if BagItemFrame3:IsVisible() then
			SetButtonAlpha("Bag",i,1)
		else
			if ItemInBag(i) == currentBag then
				currentBagSlot = i % 30
				if currentBagSlot == 0 then currentBagSlot = 30 end
				SetButtonAlpha("Bag",currentBagSlot,1)
			end
		end
	end
	for n=1,6 do
		if usedBagsList[n] then
			SetStorageTabColor("Bag",n,1,0.5,0)
		end
	end	
end

function GoodsSearch(itemName)
	local itemList = FindGoodsItemByName(itemName)
	for n=1,50 do
		SetButtonAlpha("Goods",n,0.2)
	end
	for k,i in pairs(itemList) do
		SetButtonAlpha("Goods",i,1)
	end	
end

function BankSearch(itemName)
	local itemList = FindBankItemByName(itemName)
	local usedBagsList = UsedBankBags(itemList)
	local currentBag = BankFrame.PageIndex
	local currentBagSlot = nil
	local itemButton = nil
	for n=1,40 do
		SetButtonAlpha("Bank",n,0.2)
	end
	for k,i in pairs(itemList) do
		if ItemInBankBag(i) == currentBag then
			currentBagSlot = i % 40
			if currentBagSlot == 0 then currentBagSlot = 40 end
			SetButtonAlpha("Bank",currentBagSlot,1)
		end
	end
	for n=1,5 do
		if usedBagsList[n] then
			SetStorageTabColor("Bank",n,1,0.5,0)
		end
	end	
end

function BagSearchResetFrames()
	ResetBagItemAlpha("Bag",1,180)
	for n=1,6 do
		SetStorageTabColor("Bag",n,1,1,1)
	end
end

function GoodsSearchResetFrames()
	ResetBagItemAlpha("Goods",1,50)
end

function BankSearchResetFrames()
	ResetBagItemAlpha("Bank",1,40)
	for n=1,5 do
		SetStorageTabColor("Bank",n,1,1,1)
	end
end

function ResetBagItemAlpha(storeType, startButton, endButton)
	for n=startButton,endButton do
	  SetButtonAlpha(storeType, n, 1)
	end
end

function AttemptBagSearch(storeType)
	local searchText = getglobal(storeType.."SearchEditBox"):GetText()
	getglobal(storeType .. "SearchResetFrames")()
	if searchText ~= "" and getglobal(storeType.."Frame"):IsVisible() then
		getglobal(storeType .. "Search")(searchText)
	end
end

function ModifyBagUpdate()
	OldBagFrame_Update = BagFrame_Update
	BagFrame_Update = function() OldBagFrame_Update(); AttemptBagSearch("Bag"); end
end

function RestoreBagUpdate()
	BagFrame_Update = OldBagFrame_Update
	OldBagFrame_Update = nil
end

function ModifyGoodsUpdate()
	OldGoodsFrame_Update = GoodsFrame_Update
	GoodsFrame_Update = function() OldGoodsFrame_Update(); AttemptBagSearch("Goods"); end
end

function RestoreGoodsUpdate()
	GoodsFrame_Update = OldGoodsFrame_Update
	OldGoodsFrame_Update = nil
end

function ModifyBankUpdate()
	OldBankFrame_Update = BankFrame_Update
	BankFrame_Update = function() OldBankFrame_Update(BankFrame); AttemptBagSearch("Bank"); end
end

function RestoreBankUpdate()
	BankFrame_Update = OldBankFrame_Update
	OldBankFrame_Update = nil
end

function BagCrossTextUpdate()
	local myText = BagSearchEditBox:GetText()
	if  BankSearchEditBox:GetText() ~= myText then
		BankSearchEditBox:SetText(myText)
	end
	if  GoodsSearchEditBox:GetText() ~= myText then
		GoodsSearchEditBox:SetText(myText)
	end
end

function BankCrossTextUpdate()
	local myText = BankSearchEditBox:GetText()
	if  BagSearchEditBox:GetText() ~= myText then
		BagSearchEditBox:SetText(myText)
	end
	if  GoodsSearchEditBox:GetText() ~= myText then
		GoodsSearchEditBox:SetText(myText)
	end
end

function GoodsCrossTextUpdate()
	local myText = BankSearchEditBox:GetText()
	if  BagSearchEditBox:GetText() ~= myText then
		BagSearchEditBox:SetText(myText)
	end
	if  BankSearchEditBox:GetText() ~= myText then
		BankSearchEditBox:SetText(myText)
	end
end