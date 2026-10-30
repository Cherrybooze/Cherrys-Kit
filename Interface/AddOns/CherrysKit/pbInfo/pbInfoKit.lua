-- Cherry's Kit glue for pbInfo: hub entry, /pbinfo command, probe, kit on/off switch.
--
-- /pbinfo          settings window (also Settings in the Cherry's Kit hub; /pbic still works)
-- /pbinfo probe    what pbInfo sees in this client (paste the chat lines back to Cherry)
-- /mobinfo         your target's health and class in chat (pbInfo's own command)
--
-- Left out of the kit version, because the kit already does it:
--   threat meter + aggro warning  -> rom weakauras "Threat meter" aura (/rwa threat)
--   target health bar numbers/%   -> PortraitHP (/php)

pbInfo.Kit = {}
local Kit = pbInfo.Kit
local FOLDER = "pbInfo"

local function say(text)
	DEFAULT_CHAT_FRAME:AddMessage("[|cffFFFFFFpbInfo|r] " .. tostring(text), 0.5, 0.7, 0.1);
end
Kit.Say = say

-- Switched off in the hub: nothing else loaded, hide the frames the XML shows by itself.
if (pbInfo.Off) then
	for _, name in ipairs({"pbInfoQuestTracker", "pbInfoCastingBar", "pbInfoTooltipTimer", "pbInfoBloodBarsTimer", "pbInfoCharDataTimer"}) do
		local f = _G[name];
		if (f and f.Hide) then
			pcall(f.Hide, f);
		end;
	end;
end;

-- "Hide default castbar" (CastingBar settings, on by default): the game shows its cast bar on
-- every cast, so pbInfoCastingBarHider (Xml/CastingBar.xml) hides it again on each cast event,
-- and checks 4 times a second in case something else shows it. Not while "Move CastingBar" is
-- showing it, and not while pbInfo is disabled. Turning it off gives the bar its alpha back.
function pbInfo.CastingBar.KeepHidden()
	local bar = CastingBarFrame;
	if (not bar or type(pbInfoSettings) ~= "table") then
		return;
	end;
	local hide = pbInfoSettings["CASTINGBARHIDEDEFAULT"] and pbInfoSettings["ENABLE"]
		and not (pbInfoCastingBar_MovingFrame and pbInfoCastingBar_MovingFrame:IsVisible());
	if (hide) then
		Kit.castBarHidden = true;
		if (bar:IsVisible()) then
			bar:SetAlpha(0);
			bar:Hide();
		end;
	elseif (Kit.castBarHidden) then
		Kit.castBarHidden = nil;
		bar:SetAlpha(1);
	end;
end

local HIDER_EVERY = 0.25;
local hiderWait = 0;
function pbInfo.CastingBar.KeepHiddenTick(elapsedTime)
	hiderWait = hiderWait - (elapsedTime or 0);
	if (hiderWait > 0) then
		return;
	end;
	hiderWait = HIDER_EVERY;
	pbInfo.CastingBar.KeepHidden();
end

-- pbInfoTooltipTimer (Xml/pbInfo.xml): pbInfo rebuilds the whole tooltip each time (dozens of new
-- strings and tables), and it used to do that on every frame while any tooltip was showing, so
-- hovering a monster in combat made garbage 30 to 60 times a second. Now: at once when a tooltip
-- opens or its first line changes, then 10 times a second for the live numbers. A new mouseover
-- unit is still handled at once by the UPDATE_MOUSEOVER_UNIT event in pbInfo_MainFrame.
local TOOLTIP_EVERY = 0.1;
local tooltipWait, tooltipOpen, tooltipTitle = 0, false, nil;
function Kit.TooltipTick(elapsedTime)
	if (not GameTooltip:IsVisible()) then
		tooltipOpen, tooltipTitle = false, nil;
		return;
	end;
	tooltipWait = tooltipWait - (elapsedTime or 0);
	-- Reading the same text back makes no new string, so this check costs no memory.
	local line = GameTooltipTextLeft1;
	local title = line and line:GetText();
	if (tooltipOpen and tooltipWait > 0 and title == tooltipTitle) then
		return;
	end;
	tooltipOpen, tooltipWait, tooltipTitle = true, TOOLTIP_EVERY, title;
	pbInfo.Tooltip.Scripts.OnUpdate();
	tooltipTitle = line and line:GetText();
end

local function has(name)
	return (_G[name] ~= nil) and "yes" or "NO";
end

function Kit.Probe()
	say("probe " .. tostring(pbInfo.Version) .. ", files from " .. tostring(pbInfo.Directory));
	local kitPath = CherrysKit_Paths and CherrysKit_Paths.pbInfo;
	if (kitPath and kitPath ~= pbInfo.Directory) then
		say("|cffff4040The old Interface/AddOns/pbInfo folder is loaded too. Delete it and restart the game.|r");
	end;
	say("kit off: " .. tostring(pbInfo.Off == true) .. ", pbInfo enabled: " .. tostring(type(pbInfoSettings) == "table" and pbInfoSettings["ENABLE"]));
	say("locale " .. tostring(pbInfo.Language) .. ", loaded: " .. tostring(pbInfo.Locale and pbInfo.Locale["Config"] ~= nil));
	say("frames: config " .. has("pbInfoConfig") .. ", quest tracker " .. has("pbInfoQuestTracker") .. ", casting bar " .. has("pbInfoCastingBar"));
	say("game hooks: ChatFrame_OnEvent " .. has("ChatFrame_OnEvent") .. ", CRF_TalkFrame_AddMessage " .. has("CRF_TalkFrame_AddMessage") ..
		", OnClick_QuestTrackButton " .. has("OnClick_QuestTrackButton") .. ", OnEnter_MinimapTimeIcon " .. has("OnEnter_MinimapTimeIcon"));
	local wrapped = 0;
	for _, key in ipairs({"ChatFrame_OnEvent", "CRF_TalkFrame_AddMessage", "CRF_MsnWnd_OnHide", "CRF_MsnWnd_OnShow", "OnClick_QuestTrackButton", "OnEnter_MinimapTimeIcon"}) do
		if (pbInfo.ours[_G[key]]) then
			wrapped = wrapped + 1;
		end;
	end;
	say(wrapped .. " of 6 game functions wrapped by pbInfo" .. ((wrapped < 6 and not pbInfo.Off) and " (another addon wrapped some after it: fine)" or ""));
	say("hide default castbar: " .. tostring(type(pbInfoSettings) == "table" and pbInfoSettings["CASTINGBARHIDEDEFAULT"]) ..
		", CastingBarFrame " .. has("CastingBarFrame") .. ", hidden by pbInfo " .. tostring(Kit.castBarHidden == true));
	say("API: TargetHateListRequest " .. has("TargetHateListRequest") .. ", SearchGroupPeople " .. has("SearchGroupPeople") ..
		", ClickRepairAllButton " .. has("ClickRepairAllButton") .. ", os.date " .. tostring(os ~= nil and os.date ~= nil));
end

function Kit.Open()
	if (pbInfo.Off or not pbInfoConfig) then
		say("pbInfo is off in the Cherry's Kit hub (turn it on, then Reload UI).");
		return false;
	end;
	if (pbInfoConfig:IsVisible()) then
		pbInfoConfig:Hide();
	else
		pbInfoConfig:Show();
	end;
	return true;
end

SLASH_pbInfoKit1 = "/pbinfo";
SlashCmdList["pbInfoKit"] = function(editBox, msg)
	msg = string.lower(msg or "");
	if (msg == "probe") then
		Kit.Probe();
	elseif (msg == "help") then
		say("/pbinfo = settings | /pbinfo probe | /mobinfo [party|guild|name] = target info");
	else
		Kit.Open();
	end;
end;

if (CherrysKit and CherrysKit.Register) then
	CherrysKit.Register({
		folder = FOLDER,
		title = "pbInfo",
		version = pbInfo.Version,
		installed = function()
			return true;
		end,
		open = function()
			return Kit.Open();
		end,
	});
end;
