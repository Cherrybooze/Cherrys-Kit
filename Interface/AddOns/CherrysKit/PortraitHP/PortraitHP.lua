-- PortraitHP Nonante@Nuada
-- Shows your target's health in percent on its portrait, green to red.
-- Cherry's Kit version: the event frame is declared in PortraitHP.xml (RoM ignores scripts set
-- from Lua), on/off is saved, Reload UI safe, kit on/off switch, hub row, /php probe.
local me = {
	name	= "PortraitHP",
	version	= "v2019.07.14-ck1",
	author		= "Nonante@Nuada",
	enable = true,
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
	this:RegisterEvent("UNIT_TARGET_CHANGED");
	this:RegisterEvent("UNIT_HEALTH");
end

function me.OnLoad()
	if me.IsOffInKit() then
		me.enable = false
		if me.frame then me.frame:Hide() end
		return
	end
	if db().enable == false then
		me.enable = false
	end

	-- Create UI component (once: Reload UI keeps the old one, frames cannot be deleted)
	me.CreateFontString()
	me.CreateBackdrop()

	-- AddonManager
	me.CheckAddonManager()

	if me.enable then
		me.frame:Show();
		me.OnHealthChange("target")
	else
		me.frame:Hide();
	end
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

	if(AddonManager) then
		if( AddonManager.RegisterAddonTable) then
			AddonManager.RegisterAddonTable(addon);
		end
	end
end

function me.OnEvent(this,event,arg1,arg2)
	if event == "VARIABLES_LOADED" then
		me.OnLoad();
	end

	if me.enable then
		if event == "UNIT_TARGET_CHANGED" then
			-- Calculate health immediatly
			me.OnHealthChange("target")
		elseif event == "UNIT_HEALTH" and arg1 == "target" then
			-- Update health
			me.OnHealthChange(arg1)
		end
	end
end

-- Health in percent: the client gives the target's health in percent already for most units,
-- and the real numbers for some (then it is over 100).
function me.Percent(unit)
	local hp = UnitHealth(unit) or 0
	if hp > 100 then
		local max = UnitMaxHealth(unit) or 0
		if max <= 0 then
			return 100
		end
		hp = 100 * hp / max
	end
	return math.max(0, math.min(100, hp))
end

-- display health percentage
function me.OnHealthChange(arg1)
	local text = me.frame and me.frame.Text
	if not text then
		return
	end
	if UnitExists and not UnitExists(arg1) then
		text:SetText("");
		return
	end
	-- Only for the current target
	local hppercent = me.Percent(arg1)
	text:SetText(string.format("%d%%",hppercent));
	local red = 1 - (hppercent/100)
	local green = (hppercent/100)
	text:SetColor(red,green,0)
end

--- Create text component
function me.CreateFontString()
	me.frame.Text = _G["PortraitHP_Text"] or CreateUIComponent("FontString", "PortraitHP_Text", "PortraitHP_Frame");
	me.frame.Text:SetSize(64, 64);
	me.frame.Text:SetFont("Fonts/DFHEIMDU.TTF", 24, "NORMAL", "NORMAL");  -- file, size, weight, outline
	me.frame.Text:SetJustifyHType("CENTER");
	me.frame.Text:ClearAllAnchors();
	me.frame.Text:SetAnchor("CENTER", "CENTER", TargetFrame, 60, 0);
	me.frame.Text:SetText("");
	me.frame.Text:SetColor(0,1,0);
	me.frame:SetLayers(3, me.frame.Text); -- Attach to our base frame
end

function me.CreateBackdrop()
	local FrameBackdrop = {
		edgeFile = "Interface/Tooltips/Tooltip-border",
		bgFile = "Interface/Common/Portrait-Border",
		BackgroundInsets = { top = 0, left = 0, bottom = 0, right = 0 },
		EdgeSize = 0,
		TileSize = 1,
	};

	me.frame:SetBackdrop(FrameBackdrop);
	me.frame:SetBackdropTileAlpha(1)
end

function me.Toggle()
	me.enable = not me.enable
	db().enable = me.enable
	if me.enable then
		say(color.green .. "ON")
		if me.frame then me.frame:Show() end
		me.OnHealthChange("target")
	else
		say(color.red .. "OFF")
		if me.frame then me.frame:Hide() end
	end
end

local function has(name)
	return (_G[name] ~= nil) and "yes" or "NO"
end

-- /php probe: what the addon sees (paste the chat lines back to Cherry)
function me.Probe()
	say(me.version .. ", on " .. tostring(me.enable) .. ", kit off " .. tostring(me.IsOffInKit()))
	say("TargetFrame " .. has("TargetFrame") .. ", TargetPortrait " .. has("TargetPortrait") ..
		", PortraitHP_Frame " .. has("PortraitHP_Frame") .. ", text " .. tostring(me.frame and me.frame.Text ~= nil))
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
	me.Toggle()
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
			me.Toggle()
			return true
		end,
	})
end
