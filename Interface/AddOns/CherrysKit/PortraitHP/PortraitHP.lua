-- PortraitHP Nonante@Nuada
-- Shows your target's health in percent on its portrait, green to red.
-- Cherry's Kit version: the event frame is declared in PortraitHP.xml (RoM ignores scripts set
-- from Lua), on/off is saved, Reload UI safe, kit on/off switch, hub row, /php probe.
local me = {
	name	= "PortraitHP",
	version	= "v2019.07.14-ck2",
	author		= "Nonante@Nuada",
	enable = true,
	initialized = false,
};

-- color for messages
local color = {
	green ="|cff00ff00",
	red = "|cffff0000",
	grey = "|cffA0A0A0",
	yellow = "|cffF0FF00",
	blue = "|cff0AADFF",
	pattern="|c%X%X%X%X%",
}

local function say(text)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(".:" .. color.yellow .. me.name .. "|r:. " .. tostring(text));
	end
end
me.Say = say

-- Cherry's Kit: true when the /ck hub has this addon switched off (applies after Reload UI).
function me.IsOffInKit()
	return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled(me.name)
end

if SaveVariables then
	SaveVariables("PortraitHP_DB")
end

local function db()
	if type(PortraitHP_DB) ~= "table" then
		PortraitHP_DB = {}
	end
	return PortraitHP_DB
end

-- Called by PortraitHP_Frame's OnLoad (PortraitHP.xml).
function me.OnFrameLoad(this)
	me.frame = this
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("LOADING_END");
	this:RegisterEvent("UNIT_TARGET_CHANGED");
	this:RegisterEvent("UNIT_HEALTH");
end

function me.OnLoad()
	me.initialized = false
	me.frame = me.frame or _G["PortraitHP_Frame"]
	local offInKit = me.IsOffInKit()
	me.enable = not offInKit and db().enable ~= false
	if offInKit then
		if me.frame then me.frame:Hide() end
		me.lastError = nil
		return true
	end
	if not me.frame then
		return false, "PortraitHP_Frame is missing; reinstall PortraitHP and Reload UI"
	end

	-- XML owns the font, anchor, layer and backdrop. Native SetAnchor expects a frame NAME,
	-- not the TargetFrame object formerly passed here; some clients report that failure as nil.
	-- Rebind on Reload UI too, when the XML frame's OnLoad may not run again.
	me.frame.Text = _G["PortraitHP_Text"] or me.frame.Text
	if not me.frame.Text then
		me.initialized = false
		me.frame:Hide()
		return false, "PortraitHP_Text is missing; reinstall PortraitHP and Reload UI"
	end
	me.initialized = true

	me.phase = "initial display"
	if me.enable then
		me.OnHealthChange("target")
		me.phase = "frame visibility"
		me.frame:Show();
	else
		me.frame:Hide();
	end
	me.phase = "AddonManager registration"
	me.CheckAddonManager()
	me.lastError = nil
	return true
end

-- AddonManager compatibility
function me.CheckAddonManager()
	local addon = {
		name = me.name,
		author = me.author,
		version = me.version,
		description = "Target health in percent on its portrait",
		icon = "Interface/Icons/boss_skill/skill_boss_skill_249",
		category = "Interface",
		slashCommands =	"/php",
		onClickScript =	SlashCmdList["PORTRAITHP"],
	};

	if(AddonManager and not me.managerRegistered) then
		if( AddonManager.RegisterAddonTable) then
			AddonManager.RegisterAddonTable(addon);
			me.managerRegistered = true
		end
	end
end

local function reportError(context, err)
	local detail = err == nil and "the client supplied no error detail (nil)" or tostring(err)
	me.lastError = context .. ": " .. detail
	if me.lastError ~= me.lastReportedError then
		me.lastReportedError = me.lastError
		say(me.lastError .. ". Run /php probe and include this message in your report.")
	end
end

local function handleEvent(this,event,arg1,arg2)
	me.frame = this or me.frame
	if event == "VARIABLES_LOADED" then
		me.variablesLoaded = true
	end
	if (event == "VARIABLES_LOADED" or event == "LOADING_END") and me.variablesLoaded then
		me.phase = "XML binding"
		local ready, reason = me.OnLoad()
		-- A later LOADING_END can finish initialization if the text was not ready yet.
		if not ready and event == "LOADING_END" then
			reportError("initialization", reason)
		end
	end

	if me.initialized and me.enable then
		if event == "UNIT_TARGET_CHANGED" then
			-- Calculate health immediatly
			me.OnHealthChange("target")
		elseif event == "UNIT_HEALTH" and arg1 == "target" then
			-- Update health
			me.OnHealthChange(arg1)
		end
	end
end

function me.OnEvent(this,event,arg1,arg2)
	-- Native UI failures can be error(nil); preserve the event and operation that failed.
	-- This is diagnostic containment: initialization still uses the actual XML components.
	local ok, err = pcall(handleEvent, this, event, arg1, arg2)
	if not ok then
		if event == "VARIABLES_LOADED" or event == "LOADING_END" then
			me.initialized = false
		end
		reportError(tostring(event) .. " / " .. tostring(me.phase or "event dispatch"), err)
	end
end

-- Health in percent: the client gives the target's health in percent already for most units,
-- and the real numbers for some (then it is over 100).
function me.Percent(unit)
	local hp = tonumber(UnitHealth(unit)) or 0
	if hp ~= hp then return 0 end -- no displayable percentage for NaN
	if hp > 100 then
		local max = tonumber(UnitMaxHealth(unit)) or 0
		if max ~= max or max <= 0 then
			return 100
		end
		hp = 100 * hp / max
	end
	return math.max(0, math.min(100, hp))
end

-- display health percentage
function me.OnHealthChange(arg1)
	local text = me.frame and me.frame.Text
	if not me.initialized or not text then
		return
	end
	me.phase = "target health text"
	if UnitExists and not UnitExists(arg1) then
		text:SetText("");
		me.lastError = nil
		return
	end
	-- Only for the current target
	local hppercent = me.Percent(arg1)
	text:SetText(string.format("%d%%",hppercent));
	local red = 1 - (hppercent/100)
	local green = (hppercent/100)
	me.phase = "target health color"
	text:SetColor(red,green,0)
	me.lastError = nil
end

function me.Toggle()
	if me.IsOffInKit() then
		return false, "PortraitHP is turned off in Cherry's Kit; turn it on in /ck and Reload UI"
	end
	if not me.variablesLoaded then
		return false, "PortraitHP is still loading; try again after loading finishes"
	end
	if not me.initialized then
		local ready, reason = me.OnLoad()
		if not ready then return false, reason end
	end
	local enabled = not me.enable
	if enabled then
		me.OnHealthChange("target")
		me.phase = "frame visibility"
		if me.frame then me.frame:Show() end
	else
		me.phase = "frame visibility"
		if me.frame then me.frame:Hide() end
	end
	me.enable = enabled
	db().enable = enabled
	say(enabled and (color.green .. "ON") or (color.red .. "OFF"))
	return true
end

local function has(name)
	return (_G[name] ~= nil) and "yes" or "NO"
end

-- /php probe: what the addon sees (paste the chat lines back to Cherry)
function me.Probe()
	say(me.version .. ", on " .. tostring(me.enable) .. ", kit off " .. tostring(me.IsOffInKit()))
	say("TargetFrame " .. has("TargetFrame") .. ", TargetPortrait " .. has("TargetPortrait") ..
		", PortraitHP_Frame " .. has("PortraitHP_Frame") .. ", text " .. tostring(me.frame and me.frame.Text ~= nil))
	say("variables loaded " .. tostring(me.variablesLoaded == true) .. ", initialized " .. tostring(me.initialized)
		.. ", last error " .. tostring(me.lastError or "none"))
	local ok, shown = pcall(function() return me.frame and me.frame:IsVisible() end)
	say("frame visible " .. tostring(ok and shown))
	if UnitExists and UnitExists("target") then
		say("target " .. tostring(UnitName("target")) .. ": UnitHealth " .. tostring(UnitHealth("target")) ..
			", UnitMaxHealth " .. tostring(UnitMaxHealth("target")) .. " -> " .. string.format("%d%%", me.Percent("target")))
	else
		say("no target: pick one and run /php probe again")
	end
end

--=================================================
-- Slash command
--=================================================
SLASH_PORTRAITHP1 = "/php"
SLASH_PORTRAITHP2 = "/portraithp"
SlashCmdList["PORTRAITHP"] = function(editBox,msg)
	msg = string.lower(msg or "")
	if msg == "probe" then
		me.Probe()
		return
	end
	say(color.grey .. me.version .. "|r by " .. color.blue .. me.author .. "|r")
	local ok, result, reason = pcall(me.Toggle)
	if not ok then
		reportError("toggle / " .. tostring(me.phase or "display"), result)
	elseif result == false then
		say(reason)
	end
end

--=================================================
-- Global referencing
--=================================================
_G[me.name] = me;
-- Reload UI keeps the XML frame; pick it up in case its OnLoad does not run again.
me.frame = me.frame or _G["PortraitHP_Frame"]

if CherrysKit and CherrysKit.Register then
	CherrysKit.Register({
		folder = "PortraitHP",
		title = "PortraitHP",
		version = me.version,
		installed = function()
			return true
		end,
		open = function()
			return me.Toggle()
		end,
	})
end
