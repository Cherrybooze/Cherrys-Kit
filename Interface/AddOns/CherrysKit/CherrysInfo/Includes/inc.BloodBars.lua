--[[
pbInfo - Includes/inc.ThreatMeter.lua
	v0.55-fix
	by p.b. a.k.a. novayuna
	released under the Creative Commons License By-Nc-Sa: http://creativecommons.org/licenses/by-nc-sa/3.0/
	
	- This file is outdated and will not work! -
]]
pbInfo.BloodBars.Timer = 0;
-- Cherry's Kit: the 20 bars' frame names, made once instead of 100 new strings on every pass.
local BAR_NAMES = {};
for frameID = 1, 20 do
	local name = "OBloodBar" .. frameID;
	BAR_NAMES[frameID] = { name, name .. "Title", name .. "Bar", name .. "BarValue", name .. "BarLevel" };
end;
function pbInfo.BloodBars.Scripts.OnUpdate()
	local currentTime = GetTime();
	if (currentTime < (pbInfo.BloodBars.Timer + pbInfoSettings["BloodBarsDelay"])) then
		return false;
	elseif (pbInfoSettings["MODIFYBLOODBARS"] or pbInfoSettings["BLOODBARSCOLORFADE"]) then
		pbInfo.BloodBars.Timer = currentTime;
		for i = 0, 19, 1 do
			local frameID = 20 - i;
			local names 		= BAR_NAMES[frameID];
			local frame 		= _G[names[1]];

			if (frame and frame:IsVisible()) then
				local titleFrame 	= _G[names[2]];		-- GetText()		- text above bar (name)
				local barFrame 		= _G[names[3]];			-- GetValue() 	- bar filling (current hp ratio)
				local valueFrame 	= _G[names[4]]; 	-- GetText() 	- text inside bar (current hp ratio)
				local levelFrame 	= _G[names[5]];
				local name 			= titleFrame and titleFrame:GetText();
				local healthRatio 	= barFrame and barFrame:GetValue() or 0;
				local mL 			= levelFrame and tonumber(levelFrame:GetText());
				--local unitGUID 			= frame:GetID() - (512 * 512);
				if (pbInfoSettings["MODIFYBLOODBARS"]
					and type(pbInfo.MobDB.Mobs[name]) == "table"
					and type(pbInfo.MobDB.Mobs[name][mL]) == "table"
					and type(pbInfo.MobDB.Mobs[name][mL]["healthpoints"]) == "number"
					and pbInfo.MobDB.Mobs[name][mL]["healthpoints"] > 0
				) then
					local healthMax = pbInfo.MobDB.Mobs[name][mL]["healthpoints"];
					local health = math.ceil(healthMax * healthRatio / 100);
					if (valueFrame) then valueFrame:SetText(health .. " / " .. healthMax); end;
				end;
				if (pbInfoSettings["BLOODBARSCOLORFADE"] and barFrame) then
					barFrame:SetBarColor(HSBtoRGB(math.ceil((healthRatio / 100) * 127.5), 100, 100));
				end;
			end;
		end;
	end;
end;

function pbInfo.BloodBars.Scripts.OnLoad()
	if (pbInfoSettings["MODIFYBLOODBARS"] == false or pbInfoSettings["ENABLE"] == false) then
		pbInfoBloodBarsTimer:Hide();
	else
		pbInfoBloodBarsTimer:Show();
	end;
end; 