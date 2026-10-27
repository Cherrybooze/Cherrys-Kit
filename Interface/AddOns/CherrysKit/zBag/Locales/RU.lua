zBLocale = {}
zBLocale.BagSortMatchStrings = {
	CurrentEquipment = "Текущее снаряжение",
	Bound = "Привязанный",
	BindsWhenEquipped = "Предмет из магазина", 
	ItemShopItem = "Предмет из магазина",
	NotDroppedOnPKDeath = "Не теряется при смерти персонажа",
	StackedNumber = "Кол-во: (%d+)",
	TimeTillExpiration = "Время до окончания: (%d+)",
	DailyQuest  = "(Ежедневное задание)",
	Tier = "Уровень (%d+)",
	Durability = "Прочность (%d+)/(%d+)",
	PowerModifier = "Преобразователь силы %+?(-?%d+)%%",
	Level = "Требует Ур. (%d+)",
	PhysicalDefense = "Physical Defense (%d+)",
	MagicalDefense = "Магическая защита (%d+)",
	PhysicalDamage = "Физический урон (%d+)",
	AttackSpeed = "Привязывается при экипировке",
	MagicalDamage = "Магический урон (%d+)",
	Worth = "Стоимость: (%d+)",
	Rune = "Руна %((%d)/(%d)%)",
}

zBLocale.BagSortSortModeDisplayNames = {
    "Упаковать",
    "Название",
    "Тип",
    "Прочность",
    "Уровень",
    "Цена",
    "Физ. урон",
    "Маг. урон",
    "Физ. защита",
    "Маг. защита",
    "Атрибуты",
	"Руны", 
	"Редкость",
}

zBLocale.BagSortConfigFrame= {
	BagSortUsageTitle = "Сортировка - выберите режим",
}
	
--strings in the main zBag backpack frame
zBLocale.zBagStrings = {
	zBagInspectBankTooltip = "Осмотреть содержимое банка",
	zBagConfigTooltip = "Настроить zBag",
	zBagSortTooltip = "Сортировка предметов",
	zBagSortTooltipAddline = "Обычная сортировка карманов рюкзака",
	zBagSortFullTooltip = "Полная сортировка",
	zBagSortFullTooltipAddline = "Сортирует весь рюкзак. По умолчанию собирает пустые ячейки в конце. Нажмите Shift + ЛКМ, чтобы настроить режим сортировки.", 
	zBagQuickSellTooltip = "Быстрая продажа предметов из рюкзака",
	zBagQuickSellTooltipAddLine = "Когда открыт магазин, нажмите эту кнопку, чтобы продать содержимое рюкзака. Shift + ЛКМ для настройки. По умолчанию выключено. Перетащите предмет на эту кнопку, чтобы настроить автопродажу этого предмета или предметов такого типа.",
	zBagRent3Tooltip = "Арендовать карман 3",
	zBagRent4Tooltip = "Арендовать карман 4",
	zBagRent5Tooltip = "Арендовать карман 5",
	zBagRent6Tooltip = "Арендовать карман 6",
	zBagConfigzBText2Letters = "zB",
	zBagSortFullSFText4Letters = "Срт",
	zBagQuickSellQSText2Letters = "БП",
	
	zBagSellLotsShiftKeyDown = "zBag_SellLots нажата клавиша Shift",
	zBagQuickSellDisabled = "Быстрая продажа отключена в настройках (выставлена в 0). Shift + ЛКМ на кнопке для настройки.",
	zBagInvalidQuickSellEndSlot = "Неверный номер последней ячейки. Чтобы включить быструю продажу, задайте число от 1 до 180 в настройках быстрой продажи (Shift + ЛКМ на кнопке быстрой продажи).",
	zBagLoaded = "загружен",
	zBagAltKeyDownDeveloperConfigOpened = "нажата Alt: открыты настройки разработчика",
}

--strings in the main zBag bank frame
zBLocale.zBankStrings = {
	BankSortTooltip = "Сортировать",
	BankSortTooltipAddline = "Обычная сортировка банка",
	BankRentTab2Tooltip = "Арендовать ячейку банка 2",
	BankRentTab3Tooltip = "Арендовать ячейку банка 3",
	BankRentTab4Tooltip = "Арендовать ячейку банка 4",
	BankRentTab5Tooltip = "Арендовать ячейку банка 5",
	BankPREVIEW7Letters = "ПРОСМОТР",
	BankPREVIEW5Letters = "ПРОСМ",
	BankPREVIEW3Letters = "ПРО",
	BankPREVIEW1Letter = "П",
}

--strings used in the zBag configuration frame
zBLocale.zBagConfigFrame= {
	zBagConfigTitleText = "Настройка zBag",
	zBagConfigFrameTxt1 = "Показать карманы рюкзака?",
	zBagConfigFrameTxt2 = "Показать ячейки банка:",
	ZeroPointFive = "0.5",
	One = "1",
	OnePointFive = "1.5",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Twenty = "20",
	BagItemsScale = "Масштаб предметов рюкзака",
	AlwaysShowContent = "Всегда показывать содержимое",
	AlwaysShowContentTooltipDetail = "Всегда показывать содержимое рюкзака, даже при закрытом zBag.",
	ShowEquipmentSlots = "Показывать слоты снаряжения",
	ShowEquipmentSlotsTooltipDetail = "Показывать надетые предметы внизу рюкзака.",
	ShowBackground = "Показывать фон",
	ShowBackgroundBagTooltipDetail = "Показывать фоновое изображение за содержимым рюкзака.",
	ShowBackgroundBankTooltipDetail = "Показывать фоновое изображение за содержимым банка",
	HighlightEvenTabs = "Подсвечивать чётные карманы",
	HighlightEvenTabsBagTooltipDetail = "Подсвечивает жёлтым содержимое каждого второго кармана.",
	HighlightEvenTabsBankTooltipDetail = "Подсвечивает жёлтым содержимое каждой второй банковской ячейки.",
	ShowItemShopButtons = "Показывать кнопки аренды.",
	ShowItemShopButtonsTooltipDetail = "Показывать кнопки аренды карманов рюкзака и ячеек банка",
	NumberOfItemsOnARow = "Число ячеек в ряду",
	ShowPreviewHighlight = "Подсвечивать просмотр",
	ShowPreviewHighlightTooltipDetail = "Подсвечивать красным предметы в банке, когда банк недоступен",
	OpenWithBackpack = "Открывать с рюкзаком",
	OpenWithBackpackTooltipDetail = "Показывать просмотр банка при открытии рюкзака",
	UseBagSearchAddon = "Use BagSearch Addon",
	UseBagSearchAddonTooltipDetail = "BagSearch adds a text box to the bottom of your zBag window. Type to find items in your bag that match the characters you enter",
	HighlightItemQuality = "Подсвечивать редкость предметов",
	HighlightItemQualityTooltipDetail = "Подсвечивает предметы в рюкзаке по их редкости (зелёные, синие, фиолетовые, рыжие и т. д.)",
	AllowAltRightClickDelete = "Удалять по Alt + ПКМ",
	AllowAltRightClickDeleteTooltipDetail = "Быстрое удаление любого предмета из рюкзака по Alt + ПКМ",
	BankItemsScale = "Масштаб предметов в банке",
	ItemShopBankItems = "Предмет из магазина",
}

--strings used for the quick sell feature
zBLocale.zBagQuickSellConfigFrame = {
	zBagQuickSellConfigTitleText = "Настройка быстрой продажи zBag",
	Options = "Настройки:",
	DontSellIf = "Не продавать если:",
	QuickSellStartSlot = "Первая ячейка продажи",
	QuickSellEndSlot = "Последняя ячейка продажи",
	IgnoreDontSellOptions = "Игнорировать запрет продажи",
	AlwaysNeverSellConfig = "Продавать всегда/никогда",
	DurabilityHigherThan = "Прочность выше",
	RequiredLevelHigherThan = "Треб. уровень выше",
	WhiteRarity = "Обычные",
	NormalRarity = "Нормальные",
	GoodRarity = "Хорошие",
	RareRarity = "Редкие",
	EpicRarity = "Эпические",
	LegendaryRarity = "Легендарные",
	
	zBagQuickSellItemFilterFrameTitle = "Фильтр предметов быстрой продажи zBag",
	ItemOrCategoryName = "Название предмета/категории",
	AtStore = "В магазине",
	EntryType = "Действие",
	AlwaysSell = "Всегда продавать",
	NeverSell = "Не продавать",
	Item = "Предмет",
	ItemType="Тип предмета",	
	QuickSellItemFilter = "Фильтр предметов быстрой продажи",
	CannotDetermineItemType = "Невозможно определить тип предмета, добавление не удалось.",
	
	TotalSale = "Выручка:",
	UnableToSell = "Невозможно продать - не открыт магазин",
}

-- Quick Sell Strings Written to the chat frame
zBLocale.QSStrings = {
	DropTab1	= "В фильтр",
	DropTab2	= "Перетащите предмет на этот символ и поместите в один из квадратов открывшегося окна, чтобы добавить его в фильтр предметов. ЛКМ добавляет в общий список, ПКМ в личный список персонажа.",
	Added1		= "\"<ITEM>\" добавлен с настройкой <SETTINGS>.",
	Added2		= "\"<ITEM>\" добавлен персонажу с настройкой <SETTINGS>.",
	Removed1	= "\"<ITEM>\" удалён",
	Removed2	= "\"<ITEM>\" удалён из списка персонажа",
	NotFound1	= "\"<ITEM>\" не найден в списке.",
	NotFound2	= "\"<ITEM>\" не найден в списке персонажа.",
}

