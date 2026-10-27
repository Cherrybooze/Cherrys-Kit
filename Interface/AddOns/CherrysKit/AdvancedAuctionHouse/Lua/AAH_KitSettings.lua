-- Cherry's Kit: the settings window. /aah (or Settings for Advanced AuctionHouse in /ck) opens it
-- anywhere, without an auctioneer. The Settings tab inside the auction window still works; both
-- change the same AAH_SavedSettings, and each shows the other's changes.
-- The frames are in Xml/AAH_KitSettings.xml (written by tools/gen_settings_xml.py).

local KS = {}
AAH.KitSettings = KS

local M = AAHLocale.Messages

-- name = frame AAH_KitSettings<name> and the AAH_SavedSettings key.
-- tab = the matching control on the auction window's Settings tab, kept in step.
KS.CONTROLS = {
	{ name = "StatsColumn", kind = "check", default = true,
		label = "Stats column in Browse",
		tip = "Each stat line of an item, short (Str20 Patt120). Needs a window wider than 916." },
	{ name = "FilterSpeed", kind = "slider", default = 6, min = 1, max = 50, step = 1, tab = "AAH_SettingsFilterSpeed",
		label = M.SETTINGS_FILTER_SPEED, tipHeader = M.SETTINGS_FILTER_SPEED_HEADER, tip = M.SETTINGS_FILTER_SPEED_TEXT },
	-- stored in seconds; the slider counts half seconds, 0 = learn the pace
	{ name = "PageDelay", kind = "slider", default = 0, min = 0, max = 20, step = 1,
		label = "Pause between result pages",
		tip = "Auto starts at 6 seconds (the 6.0.2 pace), goes down to 4 while the server keeps up and backs off when it says \"Currently busy\". A fixed pause under 4 seconds may bring that message back." },
	{ name = "UseMatWhiteValue", kind = "check", default = false, tab = "AAH_SettingsUseWhiteValue",
		label = M.SETTINGS_PRICE_PER_UNIT_PER_WHITE, tipHeader = M.SETTINGS_PRICE_PER_UNIT_PER_WHITE_HEADER, tip = M.SETTINGS_PRICE_PER_UNIT_PER_WHITE_TEXT },
	{ name = "AvgSuggest", kind = "check", default = false, tab = "AAH_SettingsAvgDefaultLastPrice",
		label = M.SETTINGS_AVG_DEFAULT_LAST_PRICE, tipHeader = M.SETTINGS_AVG_DEFAULT_LAST_PRICE_HEADER, tip = M.SETTINGS_AVG_DEFAULT_LAST_PRICE_TEXT },
	{ name = "BidAlertLimit", kind = "slider", default = 100000, min = AAH.Settings.MinWarningPriceMin,
		max = AAH.Settings.MinWarningPriceMax, step = 10000, wheel = 1000, tab = "AAH_SettingsMinWarningPrice",
		label = M.SETTINGS_MIN_WARNING_PRICE, tipHeader = M.SETTINGS_MIN_WARNING_PRICE_HEADER, tip = M.SETTINGS_MIN_WARNING_PRICE_TEXT },
	{ name = "PriceHistoryAutoshow", kind = "check", default = false, tab = "AAH_SettingsAlwaysShowPriceHistory",
		label = M.SETTINGS_PRICE_HISTORY_TOOLTIP, tipHeader = M.SETTINGS_PRICE_HISTORY_TOOLTIP_HEADER, tip = M.SETTINGS_PRICE_HISTORY_TOOLTIP_TEXT },
	{ name = "HistoryMaxSaved", kind = "slider", default = 10, min = AAH.Settings.HistoryMin, max = AAH.Settings.HistoryMax,
		step = 1, tab = "AAH_SettingsMaxHistory",
		label = M.SETTINGS_MAX_SAVED_HISTORY, tipHeader = M.SETTINGS_MAX_SAVED_HISTORY_HEADER, tip = M.SETTINGS_MAX_SAVED_HISTORY_TEXT },
}
KS.BY_NAME = {}
for _, c in ipairs(KS.CONTROLS) do
	KS.BY_NAME[c.name] = c
end

local function frame(c)
	return _G["AAH_KitSettings" .. c.name]
end

local function spec(this)
	return KS.BY_NAME[string.gsub(this:GetName(), "^AAH_KitSettings", "")]
end

-- slider position <-> saved value
local function toSaved(c, v)
	if c.name == "PageDelay" then
		return (v > 0) and math.max(2, v * 0.5) or 0
	end
	return v
end

local function toSlider(c, v)
	v = tonumber(v) or c.default
	if c.name == "PageDelay" then
		return math.floor(v * 2 + 0.5)
	end
	return v
end

local function valueText(c, v)
	if c.name == "PageDelay" then
		local s = toSaved(c, v)
		if s == 0 then
			return string.format("Auto (now %.1f s)", AAH.Browse.PageDelay())
		end
		return string.format("%.1f s", s)
	end
	return tostring(v)
end

function KS.OnLoad(this)
	AAH_KitSettingsTitle:SetText(AAH.Manifest.Name .. " " .. AAH.Manifest.Version .. " settings")
	for _, h in ipairs({ "Browse", "Prices", "History" }) do
		_G["AAH_KitSettingsHeader" .. h]:SetColor(1, 0.82, 0)
	end
	AAH_KitSettingsHint:SetText("Changes apply at once. Drag the window to move it.")
	for _, c in ipairs(KS.CONTROLS) do
		local f = frame(c)
		_G[f:GetName() .. "Label"]:SetText(c.label or c.name)
		if c.kind == "slider" then
			if c.step == 1 then
				f:SetValueStepMode("INT")
			end
			f:SetMinMaxValues(c.min, c.max)
			_G[f:GetName() .. "Min"]:SetText(c.name == "PageDelay" and "Auto" or tostring(c.min))
			_G[f:GetName() .. "Max"]:SetText(c.name == "PageDelay" and "10 s" or tostring(c.max))
		end
	end
end

-- Puts the saved values into the controls.
function KS.Refresh()
	local s = AAH_SavedSettings
	if not s then
		return
	end
	KS.refreshing = true
	for _, c in ipairs(KS.CONTROLS) do
		local f = frame(c)
		if c.kind == "check" then
			f:SetChecked(s[c.name] and true or false)
		else
			f:SetValue(toSlider(c, s[c.name]))
			_G[f:GetName() .. "Value"]:SetText(valueText(c, toSlider(c, s[c.name])))
		end
	end
	KS.refreshing = nil
end

-- A setting changed (here or on the auction window's Settings tab): apply it.
function KS.Set(name, value)
	local c = KS.BY_NAME[name]
	local s = AAH_SavedSettings
	if not (c and s) then
		return
	end
	if name == "HistoryMaxSaved" then
		AAH.History.SetMaxEntries(value)
	else
		s[name] = value
	end
	if name == "StatsColumn" then
		AAH.Layout.Apply(AAH.Layout.Size())
	end
	-- keep the auction window's Settings tab in step
	local tab = c.tab and _G[c.tab]
	if tab and not KS.refreshing then
		if c.kind == "check" then
			tab:SetChecked(value and true or false)
		elseif tab.GetValue and tab:GetValue() ~= value then
			tab:SetValue(value)
		end
	end
end

function KS.Check_OnClick(this)
	local c = spec(this)
	if c then
		KS.Set(c.name, this:IsChecked() and true or false)
	end
end

function KS.Slider_OnValueChanged(this)
	local c = spec(this)
	if not c then
		return
	end
	local v = this:GetValue()
	if c.step and c.step > 1 then
		v = math.floor(v / c.step + 0.5) * c.step
	end
	_G[this:GetName() .. "Value"]:SetText(valueText(c, v))
	if not KS.refreshing then
		KS.Set(c.name, toSaved(c, v))
	end
end

function KS.Slider_OnMouseWheel(this, delta)
	local c = spec(this)
	local step = (c and (c.wheel or c.step)) or 1
	this:SetValue(this:GetValue() + ((delta > 0) and step or -step))
end

function KS.OnEnter(this)
	local c = spec(this)
	if not c then
		return
	end
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText(c.tipHeader or c.label or c.name, 1, 1, 1)
	if c.tip then
		GameTooltip:AddLine(c.tip, 0, 0.75, 0.95)
	end
	GameTooltip:Show()
end

function KS.ResetSize()
	AAH.Layout.Reset()
	AAH.Kit.Say("window size " .. table.concat({ AAH.Layout.Size() }, " x "))
end

function KS.Defaults()
	for _, c in ipairs(KS.CONTROLS) do
		KS.Set(c.name, c.default)
	end
	KS.Refresh()
end

function KS.Toggle()
	if AAH_KitSettings:IsVisible() then
		AAH_KitSettings:Hide()
	else
		AAH_KitSettings:Show()
	end
end
