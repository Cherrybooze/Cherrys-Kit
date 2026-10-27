--35 strings untranslated as of 7/24/2011 http://rom.curseforge.com/addons/zbag/localization/plPL/
zBLocale = {}
zBLocale.BagSortMatchStrings = {
	CurrentEquipment = "Aktualny Ekwipunek",
	Bound = "Przypisany",
	BindsWhenEquipped = "Przedmiot zostaje przypisany po użyciu", 
	ItemShopItem = ""Przedmiot ze Sklepu z Przedmiotami",
	NotDroppedOnPKDeath = "Nie traci się w razie śmierci PK",
	StackedNumber = "Liczba przedmiotów w grupie: (%d+)",
	TimeTillExpiration = "Czas do wygaśnięcia: (%d+)",
	DailyQuest  = "(Misja Dzienna)",
	Tier = "Stopień (%d+)",
	Durability = "Trwałość (%d+)/(%d+)",
	PowerModifier = "Modyfikator Mocy %+?(-?%d+)%%",
	Level = "Poziom (%d+)",
	PhysicalDefense = ""Obrona Fizyczna (%d+)",
	MagicalDefense = "Obrona Magiczna (%d+)",
	PhysicalDamage = "Obrażenia Fizyczne (%d+)",
	AttackSpeed = "Prędkość ataku (%d+)",
	MagicalDamage = "Obrażenia Magiczne (%d+)",
	Worth = "Wartość: (%d+)",
	Rune = "Runa %((%d)/(%d)%)",
}
zBLocale.BagSortSortModeDisplayNames = {
    "Kompaktowy",
    "Nazwa",
    "Typ",
    "Trwałość",
    "Poziom",
    "Wartość",
    "Obrażenia Fizyczne",
    "Obrażenia Magiczne",
    "Obrona Fizyczna",
    "Obrona Magiczna",
    "Atrybuty",
	"Runy", 
	"Rzadkość",
}


zBLocale.BagSortConfigFrame= {
	BagSortUsageTitle = "BagSort - Wybierz metode sortowania",
}
	
--strings in the main zBag backpack frame
zBLocale.zBagStrings = {
	zBagInspectBankTooltip = "Przejrzyj zawartosc banku",
	zBagConfigTooltip = "Konfiguracja zBag",
	zBagSortTooltip = "Posortuj przedmioty",
	zBagSortTooltipAddline = "Informacja: domyślne sortowanie zakladek",
	zBagSortFullTooltip = ""Pełne sortowanie",
	zBagSortFullTooltipAddline = "Sortuje cały plecak. Domyślne sortowanie przesuwa wolne miejsca na koniec. Nacisnij Shift + lewy przycisk myszy aby skonfigurowac sortowanie", 
	zBagQuickSellTooltip = "Szybka sprzedaz przedmioty plecaka",
	zBagQuickSellTooltipAddLine = "Kiedy interfejs sklepu jest otwarty, nacisnij ten przycisk aby sprzedać wiele przedmiotow. Nacisnij Shift + Lewy przycisk myszy aby otworzyc konfiguracje. Domyslne ustawienia sa zablokowane. Przeciagnij przedmiot z plecaka na ta ikone aby skonfigurowac szybka sprzedaz dla tego przedmiotu albo typu przedmiotu.",
	zBagRent3Tooltip = "Wykup Plecak - zakładka 3",
	zBagRent4Tooltip = "Wykup Plecak - zakładka 4",
	zBagRent5Tooltip = "Wykup Plecak - zakładka 5",
	zBagRent6Tooltip = "Wykup Plecak - zakładka 6",
	zBagConfigzBText2Letters = "zB",
	zBagSortFullSFText4Letters = "Pełny",
	zBagQuickSellQSText2Letters = "SS",
		
	zBagSellLotsShiftKeyDown = "zBag_SellLots Shift wcisniety",
	zBagQuickSellDisabled = "Szybka sprzedaz zablokowana w konfiguracja (ustawione na 0). Nacisnij Shift + Lewy przycisk myszy na ikonie szybkiej sprzedazy aby otowrzyc konfiguracje",
	zBagInvalidQuickSellEndSlot = "Niewlasciwy koncowy numer szybkiej sprzedazy. Aby wlaczyc szybka sprzedaz ustaw liczbe pomiedzy 1 a 180 w interfejsie konfiguracji szybkiej sprzedazy. (Nacisnij Shift + Lewy przycisk myszy na ikonie szybkiej sprzedazy aby otowrzyc konfiguracje)",
	zBagLoaded = "załadowany",
	zBagAltKeyDownDeveloperConfigOpened = "lewy alt wcisniety: konfiguracja autora otwarta",
}

--strings in the main zBag bank frame
zBLocale.zBankStrings = {
	BankSortTooltip = "Sortuj itemy",
	BankSortTooltipAddline = "Informacja: domyślne sortowanie zakładek",
	BankRentTab2Tooltip = "Wykup Bank - zakładka 2",
	BankRentTab3Tooltip = "Wykup Bank - zakładka 3",
	BankRentTab4Tooltip = "Wykup Bank - zakładka 4",
	BankRentTab5Tooltip = "Wykup Bank - zakładka 5",
	BankPREVIEW7Letters = "PODGLĄD",
	BankPREVIEW5Letters = "PODG",
	BankPREVIEW3Letters = "POD",
	BankPREVIEW1Letter = "P",
}

--strings used in the zBag configuration frame
zBLocale.zBagConfigFrame= {
	zBagConfigTitleText = "Konfiguracja zBag",
	zBagConfigFrameTxt1 = "Pokaż Zakładkę Plecaka:",
	zBagConfigFrameTxt2 = "Pokaż Zakładkę Banku:",
	ZeroPointFive = "0.5",
	One = "1",
	OnePointFive = "1.5",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Twenty = "20",
	BagItemsScale = "Skalowanie przedmiotow w plecaku",
	AlwaysShowContent = "Zawsze pokazuj zawartosc",
	AlwaysShowContentTooltipDetail = "Trzyma zawartosc plecaka zawsze widoczna. Nawet gdy sprobujesz zamknac zBag",
	ShowEquipmentSlots = "Pokaz ekwipunek",
	ShowEquipmentSlotsTooltipDetail = "Pokaz zalozone przedmioty po przedmiotach z plecaka",
	ShowBackground = "Pokaz tlo",
	ShowBackgroundBagTooltipDetail = "Pokaz obrazek tla za zawartoscia plecaka",
	ShowBackgroundBankTooltipDetail = "Pokaz obrazek tla za zawartoscia banku",
	HighlightEvenTabs = "Podswietl zakladki",
	HighlightEvenTabsBagTooltipDetail = "Umieszcza zółte podświetlenie na każdą osobną zakładkę plecaka",
	HighlightEvenTabsBankTooltipDetail = "Umieszcza zółte podświetlenie na każdą osobną zakładkę banku",
	ShowItemShopButtons = "Pokaż przyciski sklepu z przedmiotami",
	ShowItemShopButtonsTooltipDetail = ""Pokaż przyciski umożliwiające przedłużenie wynajmu dodatkowych zakładek plecaka i banku",
	NumberOfItemsOnARow = "Liczba przedmiotów w rzędzie",
	ShowPreviewHighlight = "Pokaż podświetlenie podglądu",
	ShowPreviewHighlightTooltipDetail = "Umieszcza czerwone tło za itemami z banku jeżeli okno banku nie jest otwarte",
	OpenWithBackpack = "Otwórz razem z plecakiem.",
	OpenWithBackpackTooltipDetail = "Pokaż podgląd okna banku podczas otwierania plecaka",
	UseBagSearchAddon = "Use BagSearch Addon",
	UseBagSearchAddonTooltipDetail = "BagSearch adds a text box to the bottom of your zBag window. Type to find items in your bag that match the characters you enter",
	HighlightItemQuality = ""Podświetl jakość itemu",
	HighlightItemQualityTooltipDetail = "Umieszcza podświetlenie za itemami w plecaku bazując na jakości itemu (zielony,niebieski,fioletowy,pomarańczowy, itd.)",
	AllowAltRightClickDelete = "Włącza usuwanie poprzez alt + rclick",
	AllowAltRightClickDeleteTooltipDetail = "Włącza opcje szybkiego usuwania itemu z plecaka poprzez alt + rclick",
	BankItemsScale = "Skalowanie itemów banku",
	ItemShopBankItems = "Item Shop Bank Items",	
}

--strings used for the quick sell feature
zBLocale.zBagQuickSellConfigFrame = {
	zBagQuickSellConfigTitleText = "Konfiguracja Szybkiej Sprzedaży zBag",
	Options = "Opcje:",
	DontSellIf = "Nie sprzedawaj jeżeli:",
	QuickSellStartSlot = "Początkowy numer slotu Szybkiej Sprzedaży",
	QuickSellEndSlot = "Końcowy numer slotu Szybkiej Sprzedaży",
	IgnoreDontSellOptions = "Ignoruj Nie sprzedawaj jeżeli:",
	AlwaysNeverSellConfig = "Opcje sprzedawania Zawsze/Nigdy",
	DurabilityHigherThan = "Trwalosc wieksza niz",
	RequiredLevelHigherThan = "Wymagany poziom wiekszy niz",
	WhiteRarity = "Biala rzadkosc",
	NormalRarity = "Zielona rzadkosc",
	GoodRarity = "Niebieska rzadkosc",
	RareRarity = "Fioletowa rzadkosc",
	EpicRarity = "Pomaranczowa rzadkosc",
	LegendaryRarity = "Brazowa rzadkosc",
	
	zBagQuickSellItemFilterFrameTitle = "zBag - Filtr szybkiej sprzedazy przedmiotow",
	ItemOrCategoryName = "Nazwa Itemu/Kategorii",
	AtStore = "W Sklepie",
	EntryType = "Typ wpisu",
	AlwaysSell = "Zawsze Sprzedawaj",
	NeverSell = "Nigdy nie sprzedawaj",
	Item = "Przedmiot",
	ItemType = "Typ Przedmiotu",	
	QuickSellItemFilter = "Filtr Szybkiej Sprzedaży",
	CannotDetermineItemType = "Nie można zidentyfikować typu itemu, dodawanie nie powiodło się",
	
	TotalSale = "Całkowita sprzedaż",
	UnableToSell = "Nie mogę sprzedać - okno sklepu nie jest widoczne",	
}

-- Quick Sell Strings Written to the chat frame
zBLocale.QSStrings = {
	DropTab1	= "DropTab",
	DropTab2	= "Przeciągnij przedmiot z plecaka na ten symbol i upuść na jeden z kwadratów w środku wyskakującego okna aby dodać ten item do filtra. Lewy przycisk myszy dodaje do ogólnego filtra, Prawy przycisk myszy dodaje do filtra aktualnej postaci",
	Added1		= "\"<ITEM>\" został dodany z następującymi ustawieniami <SETTINGS>.",
	Added2		= "\"<ITEM>\" został dodany do filtra danej postaci z następującymi ustawieniami <SETTINGS>.",
	Removed1	= "\"<ITEM>\" został usunięty.",
	Removed2	= "\"<ITEM>\" został usunięty z filtra danej postaci.",
	NotFound1	= "\"<ITEM>\"  nie został znaleziony w filtrze.",
	NotFound2	= "\"<ITEM>\" e został znaleziony w filtrze danej postaci.",
}
