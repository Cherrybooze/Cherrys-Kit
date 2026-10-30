-- Cherry's Kit: files live in Interface/AddOns/CherrysKit/AdvancedAuctionHouse/ inside the kit,
-- or Interface/AddOns/AdvancedAuctionHouse/ when installed on its own.
local ROOT = (CherrysKit_Paths and CherrysKit_Paths.AdvancedAuctionHouse) or "Interface/AddOns/AdvancedAuctionHouse/"

local function LoadLocales()
    local locale = string.sub(GetLanguage(), 1, 2)
    local func, err = loadfile(ROOT.."Locales/"..locale..".lua")
    if err then
        dofile(ROOT.."Locales/EN.lua")
    else
        func()
    end

    -- this stuff is only important for development stage when locales other than german are not filled with content
    if not AAHLocale.Messages then
	    dofile(ROOT.."Locales/DE.lua")
    end
    if not AAHLocale.Messages then
	    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Advanced AuctionHouse faced a critical error:\n|rTHERE WERE PROBLEMS LOADING THE LOCALIZATION! ABORTING...")
	    return
    end
end
LoadLocales()


local VERSION = "v6.2.5"
local DEFAULT_SETTINGS = { -- NB: all settings without default value will be deleted!
	HistoryMaxSaved = 10,
	PriceHistoryAutoshow = false,
	Resize = 0,
	SellDurationSelected = 4,
	AutoFillBidSelected = 1,
	AutoFillBuyoutSelected = 1,
	SellAutoFillPercentBidValue = 100,
	FormulaBid = "",
	SellAutoFillPercentBuyoutValue = 100,
	FormulaBuyout = "",
	UseMatWhiteValue = false,
	FilterSpeed = 6,
    AvgSuggest=false,
    BidAlertLimit=100000,
    -- Cherry's Kit 6.1.x
    Width = 1150,          -- window size, dragged with the corner grip (AAH.Layout)
    Height = 509,
    LayoutVersion = 2,     -- AAH.Layout.Init migrations (2 = kit 0.11.8 layout)
    StatsDisplay = "values", -- names or normalized values in the Stats column
    StatsColumn = true,    -- compact Stats column in Browse
    PageDelay = 0,         -- seconds between result pages; 0 = learn the pace (AAH.Browse.PageDelay)
}

AdvancedAuctionHouse = true
local previousBroadCache=type(AAH)=="table" and AAH.BroadCache or nil
AAH = {
	BroadCache = previousBroadCache, -- unacknowledged character outbox survives Reload UI
	Manifest = {
		Name = "Advanced AuctionHouse",
		Author = "Mavoc, TellTod, Noguai, Graves, Cherry",
		Source = "http://rom.curseforge.com/addons/advancedauctionhouse/",
		Root = string.gsub(ROOT, "/$", ""),
		Licence = "GNU General Public License version 3 (GPLv3)",
		Build = 20261029010000,
		Version = VERSION,
	},
	-- Cherry's Kit: each data file is read the first time it is used (the auction window), not
	-- during the loading screen; Recipes.lua alone is 100 KB.
	Data = setmetatable({}, { __index = function(data, key)
		local file = ({ MatWhiteValue = "MatWhiteValue", PetEggs = "PetEggs", Recipes = "Recipes",
			StatValues = "StatsToAttributes" })[key]
		if file then
			local value = dofile(ROOT.."Data/"..file..".lua")
			rawset(data, key, value)
			return value
		end
	end }),
	Settings = {
		HistoryMin = 10,
		HistoryMax = 500,
		FilterSpeedMin = 1,
		FilterSpeedMax = 50,
		MinWarningPriceMin = 0,
		MinWarningPriceMax = 25000000,
	},
	Events = {},
	Updated = false;
}
AAHFunc = AAH -- required for 3rd Party Addons (example: DailyNotes, yaCit)

local Main = {
	Active = true,
	FoundUpdate = false,
	CurrentTab = 1,
	FrameEvents = {
		"AUCTION_AUCTION_INFO_UPDATE",
		"AUCTION_AUCTION_MONEY_UPDATE",
		"AUCTION_BUY_UPDATE",
		"AUCTION_SELL_UPDATE",
		"AUCTION_BROWSE_UPDATE",
		"AUCTION_SEARCH_RESULT",
		"AUCTION_HISTORY_SHOW",
		"AUCTION_HISTORY_HIDE",
		"AUCTION_OPEN",
		"AUCTION_CLOSE",
		"AUCTION_BORWSE_PRICE_UPDATE",
	},
}
AAH.Main = Main

-- Cherry's Kit: Reload UI re-runs every addon file in the same Lua state, and AAH is a new table
-- each time, so a plain "local orig = X; X = wrapper" wraps the last session's wrapper again and
-- the hooks pile up. AAH.Hook keeps one wrapper per hook in AAH_KitHooks, which survives the
-- reload: the wrapper is installed only when the current function is not already ours, and a
-- reload just swaps in the new code (impl). impl(orig, ...) gets the function it replaced.
-- If another addon wrapped on top of ours and we install again, the call can come back into our
-- wrapper; that inner call goes straight to the function we first replaced, so impl runs once.
AAH_KitHooks = type(rawget(_G, "AAH_KitHooks")) == "table" and rawget(_G, "AAH_KitHooks") or {}

local function hookDone(h, ok, ...)
	h.busy = nil
	if not ok then
		error((...), 0)
	end
	return ...
end

function AAH.Hook(id, owner, key, impl)
	local kind = type(owner)
	if (kind ~= "table" and kind ~= "userdata") or type(owner[key]) ~= "function" then
		return false
	end
	local h = AAH_KitHooks[id]
	if not h then
		h = {}
		AAH_KitHooks[id] = h
	end
	h.impl = impl
	if not h.wrapper then
		h.wrapper = function(...)
			if h.busy then
				return h.base(...)
			end
			h.busy = true
			return hookDone(h, pcall(h.impl, h.orig, ...))
		end
	end
	if owner[key] ~= h.wrapper then
		h.orig = owner[key]
		h.base = h.base or h.orig
		owner[key] = h.wrapper
	end
	return true
end

function Main.OnLoad(this)
	for _, event in pairs(Main.FrameEvents) do
		AuctionFrame:UnregisterEvent(event)
		AAH_AuctionFrame:RegisterEvent(event)
	end
	AAH_AuctionFrame:RegisterEvent("VARIABLES_LOADED")
	AAH_AuctionFrame:RegisterEvent("SAVE_VARIABLES")
end

function Main.Toggle(mode, quiet)
	if mode == nil then
		mode = not Main.Active
	end
	Main.Active = mode

	if Main.Active then
		for _, event in pairs(Main.FrameEvents) do
			AuctionFrame:UnregisterEvent(event)
			AAH_AuctionFrame:RegisterEvent(event)
		end
	else
		for _, event in pairs(Main.FrameEvents) do
			AuctionFrame:RegisterEvent(event)
			AAH_AuctionFrame:UnregisterEvent(event)
		end
		AUCTION_HEADER_SORT_ITEM = "name"
	end

    if quiet then return end
    DEFAULT_CHAT_FRAME:AddMessage("AdvancedAuctionHouse toggled. State is now: "..(Main.Active and "|cff00ff00ON" or "|cffff0000OFF").."|r")
end


function AAH.Events.AUCTION_AUCTION_MONEY_UPDATE(this)
end


function AAH.Events.AUCTION_CLOSE(this)
	Main.sessionOpen=false
	-- A native session timeout is not a request to discard the auction browser.
	-- Keep its cache/filter UI visible; explicit X/Escape still hides normally.
	if this:IsVisible() then
		if AAH.Browse.PauseSession then AAH.Browse.PauseSession() end
		AAH.Browse.List_UpdateItems()
		AAH.Browse.InfoLabelUpdate()
	end
end

function AAH.Events.AUCTION_OPEN(this)
	local retained=Main.sessionOpen==false and this:IsVisible()
	Main.sessionOpen=true
	if retained then
		if AAH.Browse.ResumeSession then AAH.Browse.ResumeSession() end
		AAH.Browse.List_UpdateItems()
	else ShowUIPanel(this) end
	PlaySoundByPath("Sound\\Interface\\shop_open.mp3")
end

function AAH.Events.VARIABLES_LOADED(this)
	-- Turned off in the Cherry's Kit hub: give the auction house back to the game's own window.
	if AAH.Kit and not AAH.Kit.Enabled() then
		Main.Toggle(false, true)
		AAH.Disabled = true
		return
	end
	dofile(ROOT.."Lua/AAH_Hooks.lua")
    dofile(ROOT.."Lua/AAH_BroadCache.lua")
    AAH.BroadCache.Init()
    dofile(ROOT.."Lua/AAH_BroadUI.lua")
    Main.InitSaveVariables()
    AAH.History.Init()
    Main.InitGUI(this)

    -- 3rd party stuff
	if AddonManager and AddonManager.RegisterAddonTable then
		local addon = {
			name = AAH.Manifest.Name,
			version = AAH.Manifest.Version,
			author = AAH.Manifest.Author,
			description = AAHLocale.Messages.ADDON_MANAGER_DESCRIPTION,
			icon = ROOT.."Textures/AAHIcon",
			category = "Economy",
			miniButton = AAHMiniButton,
			onClickScript = function() Main.Toggle() end,
		}
        AddonManager.RegisterAddonTable(addon)
    else
    	DEFAULT_CHAT_FRAME:AddMessage(string.gsub(string.gsub(AAHLocale.Messages.AUCTION_LOADED_MESSAGE, "<AUTHOR>", AAH.Manifest.Author), "<VERSION>", AAH.Manifest.Version),0,255,255)
	end

	if Luna then
		Luna.RegisterAddon("AdvancedAuctionHouse", AAH.Tools.LunaReceive)
--@non-alpha@
		Luna.QueueMessage("AdvancedAuctionHouse", "Build: "..AAH.Manifest.Build)
--@end-non-alpha@
	end
end

function Main.InitSaveVariables()
    AAH_SavedSearch = AAH_SavedSearch or {}
	SaveVariables("AAH_SavedSearch")

    AAH_LastSellPrice = AAH_LastSellPrice or {}
	if not AAH_LastSellPrice._TABLEBUILD or AAH_LastSellPrice._TABLEBUILD < 89 then
		AAH_LastSellPrice._TABLEBUILD = AAH.Manifest.Build
	end
	SaveVariables("AAH_LastSellPrice")

    AAH_SavedSettings = AAH_SavedSettings or {}
    -- Cherry's Kit: a height saved before LayoutVersion existed needs AAH.Layout.Init's migration
    if AAH_SavedSettings.Height and not AAH_SavedSettings.LayoutVersion then
        AAH_SavedSettings.LayoutVersion = 1
    end
    for i, v in pairs(DEFAULT_SETTINGS) do
        if AAH_SavedSettings[i] == nil then
            AAH_SavedSettings[i] = v
        end
    end
    for i, v in pairs(AAH_SavedSettings) do
        if DEFAULT_SETTINGS[i] == nil then
            AAH_SavedSettings[i] = nil
        end
    end
	SaveVariables("AAH_SavedSettings")
end


function Main.InitGUI(this)
	PanelTemplates_SetNumTabs(this, 5)

	AAH_AuctionTitleText:SetText(string.gsub(string.gsub(AAHLocale.Messages.AUCTION_FRAME_TITLE, "<AUTHOR>", AAH.Manifest.Author), "<VERSION>", AAH.Manifest.Version))
	AAH_AuctionForumsButton:SetText(AAHLocale.Messages.AUCTION_FORUMS_BUTTON)

    AAH.Sell.OnInit()

	AAH.Layout.Init()
	AAH_SettingsUseWhiteValue:SetChecked(AAH_SavedSettings.UseMatWhiteValue)
	AAH_SettingsAvgDefaultLastPrice:SetChecked(AAH_SavedSettings.AvgSuggest)
	AAH_SettingsAlwaysShowPriceHistory:SetChecked(AAH_SavedSettings.PriceHistoryAutoshow)
	AAH_SettingsMaxHistory:SetValue(AAH_SavedSettings.HistoryMaxSaved)
	AAH_SettingsFilterSpeed:SetValue(AAH_SavedSettings.FilterSpeed)
	AAH_SettingsMinWarningPrice:SetValue(AAH_SavedSettings.BidAlertLimit)
end

function Main.OnShow(this)
	Main.ClickTab(1)
	AAH.Browse.RarityMin, AAH.Browse.RarityMax = nil, nil
	AAH.Browse.RarityUpdateText()
	AAH.Tools.SetDropDown(AAH_BrowseRuneDropDown, 1, AAH.Browse.RuneInfo[1])
	AAH.Browse.Results.pageNum = 1
	AAH.Browse.SelectedCategory = {}
	AAH.SavedSearch.Expand = {}
	AAH.MoneyFrame.ResetMoney(AAH_BrowseBidMoneyInput)
	AAH.Browse.CategoryScrollBar_Update()
	AAH.SavedSearch.ScrollBar_Update()
	AAH.Browse.List_Update()
	AAH.Bid.ReadList()
	AAH_BrowseSearchButton:Enable()
end

function Main.OnHide(this)
	Main.sessionOpen=false
	CloseDropDownMenus()
	AAH_HistoryList:Hide()
	AAH_BrowseInfoLabel:SetText("")
	AAH_BrowseProgressLabel:SetText("")
	AAH.SavedSearch.MinimizeButton_OnClick()

    AAH.Browse.Frame_StopUpdates()
	if AAH.BroadCache then AAH.BroadCache.Flush() end
	AAH.History.ClearQueue()

	SetSellMoneyType(0)

    AuctionClose()
end

function Main.ClickTab(tab,keepInputs)
	if Main.sessionOpen==false and (tab==2 or tab==3) then
		AAH.Browse.InfoLabelUpdate();return
	end
	PanelTemplates_SetTab(AAH_AuctionFrame, tab)
	AAH_BrowseFrame:Hide()
	AAH_BidFrame:Hide()
	AAH_SellFrame:Hide()
	AAH_SettingsFrame:Hide()
	if tab == 1 then
		AAH.Main.CurrentTab = "BROWSE"
		AAH_BrowseFrame:Show()
		if AAH.BroadUI then AAH.BroadUI.Switch("normal",keepInputs) end
	elseif tab == 5 then
		AAH.Main.CurrentTab = "BROAD"
		AAH_BrowseFrame:Show()
		if AAH.BroadUI then AAH.BroadUI.Switch("broad",keepInputs) end
	elseif tab == 2 then
		AAH.Main.CurrentTab = "BUY"
		AAH_BidFrame:Show()
	elseif tab == 3 then
		AAH.Main.CurrentTab = "SELL"
		AAH_SellFrame:Show()
	elseif tab == 4 then
		AAH.Main.CurrentTab = "SETTINGS"
		AAH_SettingsFrame:Show()
	end
end

function AAH.Events.SAVE_VARIABLES()
	if AAH.BroadCache then AAH.BroadCache.Flush() end
end

-- Old step resize (the arrow buttons): now one row (44) taller or shorter per click.
function Main.ResizeFrame(step)
	AAH.Layout.Step(step)
end
