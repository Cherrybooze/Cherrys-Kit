--73 strings untranslated as of 7/24/2011
zBLocale = {}
zBLocale.BagSortMatchStrings = {
	CurrentEquipment = "現在の装備",
	Bound = TEXT("TOOLTIP_SOULBOUND_ALREADY"),
	BindsWhenEquipped = TEXT("TOOLTIP_SOULBOUND_EQ"), 
	ItemShopItem = "ショッピングモールアイテム",
	NotDroppedOnPKDeath = "PKで倒されてもアイテムドロップしません。",
	StackedNumber = "数量: (%d+)",
	TimeTillExpiration = "使用可能制限時間: (%d+)",
	DailyQuest  = "(クエストアイテム)",
	Tier = "ミスティックレベル (%d+)",
	Durability = TEXT("SYS_WEAREQTYPE_1").." (%d+)/(%d+)",
	PowerModifier = TEXT("SYS_POWER_MODIFY").." %+?(-?%d+)%%",
	Level = "レベル (%d+)",
	PhysicalDefense = TEXT("SYS_ARMOR_DEF").." (%d+)",
	MagicalDefense = TEXT("SYS_ARMOR_MDEF").." (%d+)",
	PhysicalDamage = TEXT("SYS_WEAPON_DMG").." (%d+)",
	AttackSpeed = TEXT("SYS_WEAPON_ATKSPEED").." (%d+)",
	MagicalDamage = TEXT("SYS_WEAPON_MDMG").." (%d+)",
	Worth = "売買: (%d+)",
	Rune = "ルーン %((%d)/(%d)%)",
}
zBLocale.BagSortSortModeDisplayNames = {
    "コンパクト",
    "名前",
    "種別",
    "耐久度",
    "レベル",
    "価格",
    "物理ダメージ",
    "魔法ダメージ",
    "物理防御力",
    "魔法防御力",
    "属性",
	"ルーン", 
	"レア度",
}


zBLocale.BagSortConfigFrame= {
	BagSortUsageTitle =  "鞄ソート - ソート設定を選択", -- Needs review
}
	
--strings in the main zBag backpack frame
zBLocale.zBagStrings = {
	zBagInspectBankTooltip = "Inspect bank content",
	zBagConfigTooltip = "Configure zBag",
	zBagSortTooltip =  "アイテムソート",
	zBagSortTooltipAddline = "Info: 標準ではタブ毎にソートします",
	zBagSortFullTooltip = "完全ソート",
	zBagSortFullTooltipAddline = "Sorts your entire backpack.  Default sort moves empty space to the end.  Shift + left click to configure sorting method", 
	zBagQuickSellTooltip =  "アイテムの高速売却",
	zBagQuickSellTooltipAddLine = "When store interface is open, click this button to sell multiple bag items. Shift+left click on this icon to configure. Default setting is disabled. Drag an item from your bag onto this icon to configure quick sell options for that item or type of item.",
	zBagRent3Tooltip = "鞄タブ3のレンタル",
	zBagRent4Tooltip = "鞄タブ4のレンタル",
	zBagRent5Tooltip = "鞄タブ5のレンタル",
	zBagRent6Tooltip = "鞄タブ6のレンタル",
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
	BankSortTooltip = "アイテムソート",
	BankSortTooltipAddline = "Info: default tab based sorting",
	BankRentTab2Tooltip = "銀行タブ2のレンタル",
	BankRentTab3Tooltip = "銀行タブ3のレンタル",
	BankRentTab4Tooltip = "銀行タブ4のレンタル",
	BankRentTab5Tooltip = "銀行タブ5のレンタル",
	BankPREVIEW7Letters = "PREVIEW",
	BankPREVIEW5Letters = "PREVI",
	BankPREVIEW3Letters = "PRE",
	BankPREVIEW1Letter = "P",
}

--strings used in the zBag configuration frame
zBLocale.zBagConfigFrame= {
	zBagConfigTitleText =  "zBag 設定画面",
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
	BagItemsScale =  "鞄アイテム表示サイズ",
	AlwaysShowContent = "Always show content",
	AlwaysShowContentTooltipDetail = "Keeps your backpack content always visible.  Even if you try to close zBag.",
	ShowEquipmentSlots = "装備スロットの表示",
	ShowEquipmentSlotsTooltipDetail = "Show the items you have equipped at the end of your backpack items",
	ShowBackground = "Show background",
	ShowBackgroundBagTooltipDetail = "Show background image behind backpack contents.",
	ShowBackgroundBankTooltipDetail = "Display background image behind bank items",
	HighlightEvenTabs =  "タブ毎に強調表示する",
	HighlightEvenTabsBagTooltipDetail = "Places a yellow highlight on every even backpack tab",
	HighlightEvenTabsBankTooltipDetail = "Places a yellow highlight on every even bank tab",
	ShowItemShopButtons = "Show item shop buttons",
	ShowItemShopButtonsTooltipDetail = "Show buttons to extend rental for extra backpack and bank tabs",
	NumberOfItemsOnARow = "Number of items on a row",
	ShowPreviewHighlight = "Show preview highlight",
	ShowPreviewHighlightTooltipDetail = "Places a red background behind bank items if you do not have your bank open",
	OpenWithBackpack = "Open with backpack",
	OpenWithBackpackTooltipDetail = "鞄と銀行を一緒に表示する",
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
	QuickSellStartSlot = "高速売却開始スロット",
	QuickSellEndSlot = "高速売却終了スロット",
	IgnoreDontSellOptions = "Ignore Don't Sell Options",
	AlwaysNeverSellConfig = "Always/Never Sell Config",
	DurabilityHigherThan = "Durability Higher Than",
	RequiredLevelHigherThan = "Required Level Higher Than",
	WhiteRarity = "白装備",
	NormalRarity = "緑装備",
	GoodRarity = "青装備",
	RareRarity = "紫装備",
	EpicRarity = "橙装備",
	LegendaryRarity = "レジェンド装備",
	
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
