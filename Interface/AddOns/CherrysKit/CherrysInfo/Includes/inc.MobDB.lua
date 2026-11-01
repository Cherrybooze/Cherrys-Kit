--[[
pbInfo - Includes/inc.MobDB.lua
	v0.56
	by p.b. a.k.a. novayuna
	released under the Creative Commons License By-Nc-Sa: http://creativecommons.org/licenses/by-nc-sa/3.0/
]]
function pbInfo.MobDB.Update(target, observation)
	-- The tooltip can supply its same-update unit facts. Other callers retain
	-- the original one-argument API and read their own current target.
	local exists, isPlayer, name, mL, mC, health;
	if (type(observation) == "table" and observation.unit == target) then
		exists, isPlayer = observation.exists, observation.isPlayer;
		name, mL, mC, health = observation.name, observation.level, observation.class, observation.health;
	else
		exists = UnitExists(target);
		if (not exists) then return; end;
		isPlayer = UnitIsPlayer(target);
		if (isPlayer) then return; end;
		name, mL, mC, health = UnitName(target), UnitLevel(target), UnitClass(target), UnitHealth(target);
	end;
	if (exists and not isPlayer and (mL or 0) > 0) then
		local healthMax = UnitChangeHealth(target);
		if (type(pbInfo.MobDB.Mobs[name]) ~= "table") then
			pbInfo.MobDB.Mobs[name] = {};
		end;
		if (type(pbInfo.MobDB.Mobs[name][mL]) ~= "table") then
			pbInfo.MobDB.Mobs[name][mL] = {};
		end;
		-- thanks to matif for the update (different mob clases within one level have different healthMax).
		if (type(pbInfo.MobDB.Mobs[name][mL][mC]) ~= "table") then
			pbInfo.MobDB.Mobs[name][mL][mC] = {};
		end;
		if (health == 100 and (pbInfo.MobDB.Mobs[name][mL][mC]["healthpoints"] or 0) < healthMax) then
			pbInfo.MobDB.Mobs[name][mL]["healthpoints"] = healthMax; -- backward compatibility for other addons
			pbInfo.MobDB.Mobs[name][mL][mC]["healthpoints"] = healthMax;
		end;
	end;
end;
