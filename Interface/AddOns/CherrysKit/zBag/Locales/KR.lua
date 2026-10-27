zBLocale = {}
zBLocale.BagSortMatchStrings = {
	CurrentEquipment = "현재 장비",
	Bound = TEXT("TOOLTIP_SOULBOUND_ALREADY"), 
	BindsWhenEquipped = TEXT("TOOLTIP_SOULBOUND_EQ"),
	ItemShopItem = "아이템 몰 아이템",
	NotDroppedOnPKDeath = "PK로 드랍되지 않음",
	StackedNumber = "갯수 : (%d+)",
	TimeTillExpiration = "잔여 시간 : (%d+)",
	DailyQuest  = "(일일 퀘스트)",
	Tier = "티어 : (%d+)",
	Durability = "내구도 (%d+)/(%d+)",
	PowerModifier = TEXT("SYS_POWER_MODIFY") .. "  %+?(-?%d+)%%", 
	Level = "레벨 (%d+)",
	PhysicalDefense = "물리 방어 (%d+)",
	MagicalDefense = "마법 방어 (%d+)",
	PhysicalDamage = "물리 대미지 (%d+)",
	AttackSpeed = "공격 속도 (%d+)",
	MagicalDamage = "마법 대미지 (%d+)",
	Worth = "가격 : (%d+)",
	Rune = "룬 %((%d)/(%d)%)",
}
zBLocale.BagSortSortModeDisplayNames = {
	"가방 전체 정렬",
	"이름",
    "형식",
    "내구도",
    "레벨",
    "가격",
    "물리 대미지",
    "마법 대미지",
    "물리 방어",
    "마법 방어",
    "특성",
	"룬",
	"희귀도",	
}


zBLocale.BagSortConfigFrame= {
	BagSortUsageTitle = "BagSort - Select sort mode",
}
	
--strings in the main zBag backpack frame
zBLocale.zBagStrings = {
	zBagInspectBankTooltip = "Inspect bank content",
	zBagConfigTooltip = "Configure zBag",
	zBagSortTooltip = "Sort items",
	zBagSortTooltipAddline = "Info: default tab based sorting",
	zBagSortFullTooltip = "Full sort",
	zBagSortFullTooltipAddline = "Sorts your entire backpack.  Default sort moves empty space to the end.  Shift + left click to configure sorting method", 
	zBagQuickSellTooltip = "Quick-sells inventory items",
	zBagQuickSellTooltipAddLine = "When store interface is open, click this button to sell multiple bag items. Shift+left click on this icon to configure. Default setting is disabled. Drag an item from your bag onto this icon to configure quick sell options for that item or type of item.",
	zBagRent3Tooltip = "Rent Bag tab 3",
	zBagRent4Tooltip = "Rent Bag tab 4",
	zBagRent5Tooltip = "Rent Bag tab 5",
	zBagRent6Tooltip = "Rent Bag tab 6",
	zBagConfigzBText2Letters = "zB",
	zBagSortFullSFText4Letters = "Full",
	zBagQuickSellQSText2Letters = "QS",
		
	zBagSellLotsShiftKeyDown = "zBag_SellLots Shift Key Down",
	zBagQuickSellDisabled = "Quick sell disabled in configuration (set to 0).  Shift+Left Click on the quick sell icon to configure.",
	zBagInvalidQuickSellEndSlot = "Invalid quick sell end slot number.  To enable quick sell, please set a number between 1 and 180 in the quick sell configuration interface (shift+left click on the quick sell icon to configure).",
	zBagLoaded = "loaded",
	zBagAltKeyDownDeveloperConfigOpened = "alt key down:developer config opened",
}

--strings in the main zBag bank frame
zBLocale.zBankStrings = {
	BankSortTooltip = "Sort items",
	BankSortTooltipAddline = "Info: default tab based sorting",
	BankRentTab2Tooltip = "Rent Bank tab 2",
	BankRentTab3Tooltip = "Rent Bank tab 3",
	BankRentTab4Tooltip = "Rent Bank tab 4",
	BankRentTab5Tooltip = "Rent Bank tab 5",
	BankPREVIEW7Letters = "PREVIEW",
	BankPREVIEW5Letters = "PREVI",
	BankPREVIEW3Letters = "PRE",
	BankPREVIEW1Letter = "P",
}

--strings used in the zBag configuration frame
zBLocale.zBagConfigFrame= {
	zBagConfigTitleText = "zBag Configuration",
	zBagConfigFrameTxt1 = "Show Backpack Tab:",
	zBagConfigFrameTxt2 = "Show Bank Tab:",
	ZeroPointFive = "0.5",
	One = "1",
	OnePointFive = "1.5",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Twenty = "20",
	BagItemsScale = "Bag items scale",
	AlwaysShowContent = "Always show content",
	AlwaysShowContentTooltipDetail = "Keeps your backpack content always visible.  Even if you try to close zBag.",
	ShowEquipmentSlots = "Show equipment slots",
	ShowEquipmentSlotsTooltipDetail = "Show the items you have equipped at the end of your backpack items",
	ShowBackground = "Show background",
	ShowBackgroundBagTooltipDetail = "Show background image behind backpack contents.",
	ShowBackgroundBankTooltipDetail = "Display background image behind bank items",
	HighlightEvenTabs = "Highlight even tabs",
	HighlightEvenTabsBagTooltipDetail = "Places a yellow highlight on every even backpack tab",
	HighlightEvenTabsBankTooltipDetail = "Places a yellow highlight on every even bank tab",
	ShowItemShopButtons = "Show item shop buttons",
	ShowItemShopButtonsTooltipDetail = "Show buttons to extend rental for extra backpack and bank tabs",
	NumberOfItemsOnARow = "Number of items on a row",
	ShowPreviewHighlight = "Show preview highlight",
	ShowPreviewHighlightTooltipDetail = "Places a red background behind bank items if you do not have your bank open",
	OpenWithBackpack = "Open with backpack",
	OpenWithBackpackTooltipDetail = "Show bank preview window when opening backpack",
	UseBagSearchAddon = "Use BagSearch Addon",
	UseBagSearchAddonTooltipDetail = "BagSearch adds a text box to the bottom of your zBag window. Type to find items in your bag that match the characters you enter",	
	HighlightItemQuality = "Highlight item quality",
	HighlightItemQualityTooltipDetail = "Places a highlight behind items in your backpack based on item quality (green, blue, purple, orange, etc.)",
	AllowAltRightClickDelete = "Allow alt + rclick delete",
	AllowAltRightClickDeleteTooltipDetail = "Allow pressing alt + right click to quickly delete an item from your backpack",
	BankItemsScale = "Bank items scale",
	ItemShopBankItems = "Item Shop Bank Items",	
}

--strings used for the quick sell feature
zBLocale.zBagQuickSellConfigFrame = {
	zBagQuickSellConfigTitleText = "zBag Quick Sell Configuration",
	Options = "Options:",
	DontSellIf = "Don't sell if:",
	QuickSellStartSlot = "Quick sell start slot",
	QuickSellEndSlot = "Quick sell end slot",
	IgnoreDontSellOptions = "Ignore Don't Sell Options",
	AlwaysNeverSellConfig = "Always/Never Sell Config",
	DurabilityHigherThan = "Durability Higher Than",
	RequiredLevelHigherThan = "Required Level Higher Than",
	WhiteRarity = "White Rarity",
	NormalRarity = "Normal Rarity",
	GoodRarity = "Good Rarity",
	RareRarity = "Rare Rarity",
	EpicRarity = "Epic Rarity",
	LegendaryRarity = "Legendary Rarity",
	
	zBagQuickSellItemFilterFrameTitle = "zBag - Quick Sell Item Filter",
	ItemOrCategoryName = "Item/Category Name",
	AtStore = "At Store",
	EntryType = "Entry Type",
	AlwaysSell = "Always Sell",
	NeverSell = "Never Sell",
	Item = "Item",
	ItemType="Item Type",	
	QuickSellItemFilter = "Quick Sell Item Filter",
	CannotDetermineItemType = "Cannot determine item type, add failed",
	
	TotalSale = "Total sale",
	UnableToSell = "Unable to sell - Store Frame not visible",	
}

-- Quick Sell Strings Written to the chat frame
zBLocale.QSStrings = {
	DropTab1	= "DropTab",
	DropTab2	= "Drag an Item from your bag onto this symbol and drop it in one of the squares inside the poping window, to add an entry of this item to the Itemfilter. Leftclick adds it to the common Itemfilter, Rightclick to the characterspecific.",
	Added1		= "\"<ITEM>\" has been added with settings <SETTINGS>.",
	Added2		= "\"<ITEM>\" has been characterspecific added with settings <SETTINGS>.",
	Removed1	= "\"<ITEM>\" has been removed.",
	Removed2	= "\"<ITEM>\" has been characterspecific removed.",
	NotFound1	= "\"<ITEM>\" wasn't found in the ItemFilter.",
	NotFound2	= "\"<ITEM>\" wasn't found in the characterspecific ItemFilter.",
}






