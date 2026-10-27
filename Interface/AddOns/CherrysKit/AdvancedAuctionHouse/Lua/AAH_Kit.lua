-- Cherry's Kit glue for Advanced AuctionHouse: on/off switch, chat commands, hub entry, probe.
--
-- /aah                 settings window (also Settings in the Cherry's Kit hub)
-- /aah help            short help
-- /aah pagedelay <s>   fixed pause between result pages (0 = auto)
-- /aah probe           what the addon sees in this client (paste the chat lines back to Cherry)
-- /aah size reset      default window size;  /aah size 1100 600  sets one
-- /aah stats on|off    the Stats column in Browse
-- The original commands still work: /aah clear <item>, clearall, usewhitevalue, pricehistory,
-- numhistory <n>, turn on|off, toggle.

local Kit = {}
AAH.Kit = Kit
local FOLDER = "AdvancedAuctionHouse"

function Kit.Enabled()
	return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled(FOLDER))
end

local function say(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd200AAH|r " .. tostring(text))
end
Kit.Say = say

function Kit.Help()
	say(AAH.Manifest.Name .. " " .. AAH.Manifest.Version .. " by " .. AAH.Manifest.Author)
	say("Open the auction house at an auctioneer. Drag the bottom-right corner to resize the window.")
	say("Stats column: hover its header for the abbreviations. Alt+click an item to search for all of them.")
	say("/aah = settings | /aah size reset | /aah size <width> <height> | /aah stats on|off | /aah pagedelay <seconds, 0 = auto> | /aah probe")
	say("/aah clear <item> | clearall | usewhitevalue | pricehistory | numhistory <n> | turn on|off")
end

local function has(name)
	return (_G[name] ~= nil) and "yes" or "NO"
end

local function size(frame)
	if not frame then
		return "missing"
	end
	local ok1, w = pcall(frame.GetWidth, frame)
	local ok2, h = pcall(frame.GetHeight, frame)
	return string.format("%s x %s", ok1 and tostring(math.floor((w or 0) + 0.5)) or "?", ok2 and tostring(math.floor((h or 0) + 0.5)) or "?")
end

function Kit.Probe()
	say("probe " .. AAH.Manifest.Version .. ", files from " .. tostring(AAH.Manifest.Root))
	local kitPath = CherrysKit_Paths and CherrysKit_Paths.AdvancedAuctionHouse
	if kitPath and string.gsub(kitPath, "/$", "") ~= AAH.Manifest.Root then
		say("|cffff4040The old Interface/AddOns/AdvancedAuctionHouse folder is loaded too. Delete it and restart the game.|r")
	end
	say("kit on: " .. tostring(Kit.Enabled()) .. ", AAH active: " .. tostring(AAH.Main.Active) .. ", disabled at load: " .. tostring(AAH.Disabled == true))
	say("API: GetCursorPos " .. has("GetCursorPos") .. ", GetUIScale " .. has("GetUIScale") .. " (" .. tostring(GetUIScale and GetUIScale()) ..
		"), IsAltKeyDown " .. has("IsAltKeyDown") .. ", UIDropDownMenu_SetWidth " .. has("UIDropDownMenu_SetWidth") ..
		", CloseDropDownMenus " .. has("CloseDropDownMenus"))
	local s = AAH_SavedSettings or {}
	say("saved size " .. tostring(s.Width) .. " x " .. tostring(s.Height) .. ", window " .. size(AAH_AuctionFrame) ..
		", list " .. size(AAH_BrowseList) .. ", rows " .. tostring(AAH.Browse.DisplayedItems) .. ", stats column " .. tostring(AAH.Browse.StatsWidth))
	local f = AAH_AuctionFrame
	local okL, left = pcall(f.GetLeft, f)
	local okT, top = pcall(f.GetTop, f)
	say("window left/top " .. tostring(okL and left) .. " / " .. tostring(okT and top))
	if AAH.Layout.pin then
		local p = AAH.Layout.pin
		say(string.format("last pin: before %s,%s after %s,%s scale %s%s", tostring(p.left), tostring(p.top), tostring(p.left2), tostring(p.top2),
			tostring(p.scale), p.fallback and " (used UI units)" or ""))
	end
	local errs = 0
	for name, err in pairs(AAH.Layout.errors) do
		errs = errs + 1
		say("|cffff4040layout error (" .. name .. "):|r " .. err)
	end
	if errs == 0 then
		say("layout errors: none")
	end
	-- filters
	local kinds = AAH.Filters.Kinds()
	local phrases = {}
	for n = 1, AAH.Filters.COUNT do
		table.insert(phrases, "[" .. AAH.Filters.GetPhrase(n) .. "]")
	end
	say("filters: " .. #kinds .. " kinds + " .. #AAH.Filters.StatKinds .. " stat kinds; now " .. table.concat(phrases, " "))
	-- stats of the results so far
	local list = AAH.Browse.Results and AAH.Browse.Results.list or {}
	local withStats = 0
	local example
	for _, listing in ipairs(list) do
		if #(listing.slots or {}) > 0 then
			withStats = withStats + 1
			example = example or listing
		end
	end
	local pace = AAH.Browse.Pace
	say(string.format("page pace: %.2f s between pages%s, last search %d pages in %.1f s, %d refused, %d busy, %d re-sorts, rarity range %s-%s",
		AAH.Browse.PageDelay(), (tonumber(AAH_SavedSettings and AAH_SavedSettings.PageDelay) or 0) > 0 and " (fixed)" or " (learned)",
		pace.pages, pace.time, pace.refusals, pace.busy, pace.sorts, tostring(AAH.Browse.RarityMin), tostring(AAH.Browse.RarityMax)))
	local okI, items = pcall(GetAuctionBrowseMaxItems)
	local okP, pages = pcall(GetAuctionBrowseMaxPages)
	say("last search, server says: " .. tostring(okI and items) .. " items in " .. tostring(okP and pages) ..
		" pages (" .. tostring(AAH.Browse.MaxPageItems) .. " per page; 1000 items = 20 pages is the server's usual cap)")
	say("results " .. #list .. ", with stats " .. withStats)
	if example then
		say("e.g. " .. tostring(example.name) .. ": " .. AAH.Stats.Text(example, 400))
	end
	say("class " .. tostring(UnitClass and UnitClass("player")) .. ", stat conversion known: " ..
		tostring(AAH.Data.StatValues[UnitClass and UnitClass("player") or ""] ~= nil))
end

function Kit.Slash(editBox, msg)
	msg = msg or ""
	local command, rest = string.match(msg, "^%s*(%S*)%s*(.-)%s*$")
	command = string.lower(command or "")
	if command == "" and AAH.KitSettings and not AAH.Disabled then
		AAH.KitSettings.Toggle()
	elseif command == "" or command == "help" then
		Kit.Help()
	elseif command == "probe" then
		Kit.Probe()
	elseif command == "size" then
		if rest == "reset" or rest == "" then
			AAH.Layout.Reset()
		else
			local w, h = string.match(rest, "(%d+)%D+(%d+)")
			AAH.Layout.Apply(tonumber(w), tonumber(h))
		end
		local w, h = AAH.Layout.Size()
		say("window size " .. w .. " x " .. h)
	elseif command == "pagedelay" then
		local v = tonumber(rest)
		if v then
			AAH_SavedSettings.PageDelay = (v > 0) and math.max(2, math.min(10, v)) or 0
		end
		say("pause between result pages: " .. ((AAH_SavedSettings.PageDelay > 0) and (AAH_SavedSettings.PageDelay .. " s") or
			string.format("auto (now %.1f s)", AAH.Browse.PageDelay())))
	elseif command == "stats" then
		AAH_SavedSettings.StatsColumn = (rest ~= "off")
		AAH.Layout.Apply(AAH.Layout.Size())
		say("Stats column " .. (AAH_SavedSettings.StatsColumn and "on (needs a window wider than 916)" or "off"))
	elseif AAH.SlashHandler then
		AAH.SlashHandler(editBox, msg)
	else
		say("Advanced AuctionHouse is turned off in Cherry's Kit (/ck).")
	end
end

-- Registered at load time so the Cherry's Kit hub sees /aah as taken and wraps it.
SLASH_AAH_SlashHandler1 = "/aah"
SLASH_AAH_SlashHandler2 = "/auctionhouse"
SlashCmdList["AAH_SlashHandler"] = Kit.Slash

if CherrysKit and CherrysKit.Register then
	CherrysKit.Register({
		folder = FOLDER,
		title = "Advanced AuctionHouse",
		version = AAH.Manifest.Version,
		installed = function()
			return true
		end,
		open = function()
			if AAH.Disabled then
				Kit.Help()
			else
				AAH_KitSettings:Show()
			end
			return true
		end,
	})
end
