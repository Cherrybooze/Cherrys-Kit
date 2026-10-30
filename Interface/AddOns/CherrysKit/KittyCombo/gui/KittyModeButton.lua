-- Cherry's KittyCombo: modes and the mode button
--------------------------------------------------------------------------------
-- Modes are names (aoe, single, request...) that "Mode is on" conditions check.
-- Kitty.Modes[name] = true while a mode is on. The mode button (near the
-- minimap, Kitty options: "Show mode button") picks one mode: clicking a mode
-- turns the others off. /kc toggle <name> still flips one mode by itself.
-- Saved: setting.mode = {names = {...}, current = "aoe", x = , y = }
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end
Kitty.Modes = Kitty.Modes or {};
Kitty.ModeUI = Kitty.ModeUI or {};
local M = Kitty.ModeUI;
M.pickHandler, M.pickerChoices, M.flyoutAnchor, M.page = nil, nil, nil, 0;
M.textHost = nil;	-- Reload UI re-runs this file: whoever carries the readout says so again

M.MAX = 15;	-- flyout buttons for modes (plus one for "no mode")
M.PER_ROW = 4;
M.SIZE = 30;	-- flyout button size; the mode button itself is 36 (an action button)
M.GAP = 4;
M.ADD_NEW = "Add new mode...";
-- Pictures in gfx/modes, by mode name (other names get the blank picture and their first letters)
M.ICONS = {aoe = "aoe", single = "single", burst = "burst", tank = "tank", heal = "heal",
	interrupt = "interrupt", pvp = "pvp", dps = "dps", farm = "farm", boss = "boss", request = "request"};
M.ALIASES = {multi = "aoe", cleave = "aoe", st = "single", cd = "burst", cds = "burst", cooldowns = "burst",
	def = "tank", defensive = "tank", defence = "tank", defense = "tank", healing = "heal", support = "heal",
	kick = "interrupt", silence = "interrupt", grind = "farm", raid = "boss"};

local function trim(text)
	return (string.gsub(tostring(text or ""), "^%s*(.-)%s*$", "%1"));
end
M.clean = function(name)
	return string.lower(trim(name));
end

M.setting = function()
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	if(setting == nil) then
		return {names = {}};
	end
	if(type(setting.mode) ~= "table") then
		setting.mode = {};
	end
	if(type(setting.mode.names) ~= "table") then
		setting.mode.names = {};
	end
	return setting.mode;
end

M.iconName = function(name)
	name = M.clean(name);
	if(name == "") then
		return "none";
	end
	return M.ICONS[name] or M.ICONS[M.ALIASES[name] or ""] or "blank";
end
M.iconPath = function(name)
	return Kitty.BASE_PATH .. "gfx/modes/" .. M.iconName(name) .. ".tga";
end
-- Letters drawn on the blank picture
M.letters = function(name)
	if(M.iconName(name) ~= "blank") then
		return "";
	end
	return string.upper(string.sub(M.clean(name), 1, 1)) .. string.sub(M.clean(name), 2, 3);
end

-- Every "Mode is on" name in a list of kitties
local function collect(found, kitties)
	if(type(kitties) ~= "table") then
		return;
	end
	for _, kitty in ipairs(kitties) do
		for _, command in ipairs(type(kitty) == "table" and kitty or {}) do
			if(type(command) == "table" and command.commandType == "changemode" and type(command.commandName) == "string") then
				local name = M.clean(command.commandName);
				if(name ~= "") then found[name] = true; end
			end
			for _, condition in ipairs(type(command) == "table" and command or {}) do
				if(type(condition) == "table" and condition.conditionType == "modeOn") then
					if(condition.name ~= nil) then
						found[M.clean(condition.name)] = true;	-- a row in the condition editor
					end
					for _, entry in ipairs(condition) do
						if(type(entry) == "table") then
							found[M.clean(entry.name)] = true;
						end
					end
				end
			end
		end
	end
end
-- Modes every player has from the start (the ones with pictures)
M.BUILT_IN = {"aoe", "single", "burst", "dps", "tank", "heal", "interrupt", "pvp", "farm", "boss", "request"};
-- All modes: built in, added by players, used in any kitty, or switched on with /kc toggle
M.names = function()
	local found = {};
	local hidden = M.setting().hidden or {};
	for _, name in ipairs(M.BUILT_IN) do
		if(not hidden[name]) then
			found[name] = true;
		end
	end
	for _, name in ipairs(M.setting().names) do
		found[M.clean(name)] = true;
	end
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	collect(found, setting and setting.command);
    -- Modes in an unsaved rotation remain available in the draft editor.
    local staged = Kitty.CommandListFrame and Kitty.CommandListFrame.allCommandList;
    if(type(staged) == "table") then collect(found, staged); end
    local draft = Kitty.CommandConfigFrame and Kitty.CommandConfigFrame.targetCommandList;
    if(type(draft) == "table") then collect(found, {draft}); end
	-- rows open in the condition editor
	local editing = Kitty.CommandConditionFrame and Kitty.CommandConditionFrame.targetConditionList;
	if(type(editing) == "table") then
		collect(found, {{editing}});
	end
	for name in pairs(Kitty.Modes) do
		found[name] = true;
	end
	found[""] = nil;
	local list = {};
	for name in pairs(found) do
		table.insert(list, name);
	end
	table.sort(list);
	return list;
end
M.add = function(name)
	name = M.clean(name);
	if(name == "" or name == M.clean(M.ADD_NEW)) then
		return false;
	end
	for _, known in ipairs(M.setting().names) do
		if(M.clean(known) == name) then
			return false;
		end
	end
	table.insert(M.setting().names, name);
	if(M.setting().hidden) then
		M.setting().hidden[name] = nil;
	end
	return true;
end
M.remove = function(name)
	name = M.clean(name);
	local names = M.setting().names;
	for index = #names, 1, -1 do
		if(M.clean(names[index]) == name) then
			table.remove(names, index);
		end
	end
	Kitty.Modes[name] = nil;
	-- a built-in mode stays out of the list until added again
	M.setting().hidden = M.setting().hidden or {};
	M.setting().hidden[name] = true;
	if(M.setting().current == name) then
		M.setting().current = nil;
	end
	M.refresh();
end

-- The mode that is on (the picked one first), or nil; second value: all that are on
M.current = function()
	local on = {};
	for name, state in pairs(Kitty.Modes) do
		if(state) then
			table.insert(on, name);
		end
	end
	table.sort(on);
	local picked = M.setting().current;
	if(picked and Kitty.Modes[picked]) then
		return picked, on;
	end
	return on[1], on;
end
-- Turn one mode on and every other off (nil or "" = no mode)
M.set = function(name, quiet)
	name = M.clean(name);
	for mode in pairs(Kitty.Modes) do
		Kitty.Modes[mode] = false;
	end
	if(name ~= "") then
		Kitty.Modes[name] = true;
		M.add(name);
		M.setting().current = name;
	else
		M.setting().current = nil;
	end
	if(Kitty.Predict) then Kitty.Predict.cache = {}; end
	if(not quiet) then
		Kitty.sendMessage(Kitty.L("ModeNow", "Kitty mode: <<1>>", name ~= "" and ("|cff40ff40" .. name .. "|r") or Kitty.L("ModeNone", "none")));
	end
	M.refresh();
end

M.validModeName = function(name)
	return type(name) == "string" and M.clean(name) ~= "" and M.clean(name) ~= M.clean(M.ADD_NEW);
end

-- After a kitty switches the mode, its other "Change kitty mode" rows wait this
-- long, so two rows that undo each other cannot flip the mode on every press.
-- Prediction marks its own simulated switch on its private manager (modeHeld).
M.SWITCH_HOLD = 1;
M.switchHeld = function(manager)
	if(type(manager) == "table" and rawget(manager, "modeHeld")) then return true; end
	local at = M.switchedAt;
	if(at == nil or not Kitty.getTime) then return false; end
	local now = Kitty.getTime();
	return now >= at and now - at < M.SWITCH_HOLD;
end
-- False when the mode is already the only one on: that switch would only use up a press.
-- Prediction passes its manager, whose modeState replaces the live modes.
M.wouldChange = function(name, manager)
	local modes = (type(manager) == "table" and rawget(manager, "modeState")) or Kitty.Modes;
	name = M.clean(name);
	for mode, state in pairs(modes) do
		if(state and mode ~= name) then return true; end
	end
	return modes[name] ~= true;
end
-- A switch fired by a kitty row (the mode button and /kc mode use M.set)
M.kittySwitch = function(name)
	if(not M.validModeName(name)) then return false; end
	M.set(name, true);
	M.switchedAt = Kitty.getTime and Kitty.getTime() or nil;
	return true;
end
-- Enabled "Change kitty mode" rows with no condition except their own "Mode is off"
local function guardOnly(command)
	for _, condition in ipairs(command) do
		if(type(condition) ~= "table" or condition.conditionType ~= "modeOn") then return false; end
		for _, entry in ipairs(condition) do
			if(type(entry) ~= "table" or entry.modeActionGuard ~= true) then return false; end
		end
	end
	return true;
end
-- Mode names of those rows when two or more different modes would take turns
M.loopingModes = function(list)
	local names, seen = {}, {};
	for _, command in ipairs(type(list) == "table" and list or {}) do
		if(type(command) == "table" and command.enable ~= false and command.commandType == "changemode"
			and M.validModeName(command.commandName) and guardOnly(command)) then
			local name = M.clean(command.commandName);
			if(not seen[name]) then seen[name] = true; table.insert(names, name); end
		end
	end
	return #names > 1 and names or nil;
end

-- The marker lives on the ordinary modeOn entry, so split/merge and share
-- formats retain it. Boolean edits remain meaningful when the action is retargeted.
M.configureCommand = function(command, name)
	if(type(command) ~= "table" or not M.validModeName(name)) then return false; end
	name = M.clean(name);
	local owned;
	for _, condition in ipairs(command) do
		if(type(condition) == "table" and condition.conditionType == "modeOn") then
			for _, entry in ipairs(condition) do
				if(type(entry) == "table" and entry.modeActionGuard == true) then entry.name = name; owned = true; end
			end
		end
	end
	if(not owned) then
		table.insert(command, {conditionType="modeOn", {name=name,value=false,threshold=0,modeActionGuard=true}});
	end
	command.commandType, command.commandName, command.icon = "changemode", name, M.iconPath(name);
	return true;
end

M.clearCommandGuard = function(command)
	for i = #command, 1, -1 do
		local condition = command[i];
		if(type(condition) == "table" and condition.conditionType == "modeOn") then
			local removed;
			for j = #condition, 1, -1 do
				if(type(condition[j]) == "table" and condition[j].modeActionGuard == true) then table.remove(condition,j); removed = true; end
			end
			if(removed and #condition == 0) then table.remove(command,i); end
		end
	end
end
-- After logging in: the mode picked last time is on again
M.restore = function()
	local picked = M.setting().current;
	if(picked and picked ~= "") then
		Kitty.Modes[picked] = true;
	end
	M.refresh();
end

-- Old "request mode" (Shift+Kitty macro) is now the mode called request:
-- isRequest conditions become "Mode is on: request".
M.REQUEST = "request";
M.migrateCondition = function(condition)
	if(type(condition) ~= "table" or condition.conditionType ~= "isRequest") then
		return false;
	end
	local entry = {name = M.REQUEST, threshold = 0};
	if(condition.value == false) then
		entry.value = false;
	end
	condition.conditionType = "modeOn";
	condition.value = nil;
	condition[1] = entry;
	return true;
end
M.migrate = function(kitties)
	local count = 0;
	for _, kitty in ipairs(type(kitties) == "table" and kitties or {}) do
		for _, command in ipairs(type(kitty) == "table" and kitty or {}) do
			for _, condition in ipairs(type(command) == "table" and command or {}) do
				if(M.migrateCondition(condition)) then
					count = count + 1;
				end
			end
		end
	end
	return count;
end

-- After the saved variables are read
M.afterLoad = function()
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	if(setting and type(setting.command) == "table") then
		M.migrate(setting.command);
	end
	M.closeFlyout();
	M.place();
	M.restore();
end

--------------------------------------------------------------------------------
-- The mode button
local function find(name)
	return Kitty.Skin and Kitty.Skin.find(name) or nil;
end
local function try(obj, method, ...)
	return Kitty.Skin.try(obj, method, ...);
end
local function basic()
	local setting = Kitty.SettingManager and Kitty.SettingManager.setting;
	return (setting and setting.basic) or {};
end
-- check boxes save true/false (or 1/nil)
local function on(value)
	return value ~= nil and value ~= false and value ~= 0;
end
M.isShown = function()
	return on(basic().showModeButton) and not (Kitty.isTurnedOff and Kitty.isTurnedOff());
end
M.isTextShown = function()
	return on(basic().showModeText) and not (Kitty.isTurnedOff and Kitty.isTurnedOff());
end
M.isLocked = function()
	return on(basic().lockModeButton);
end

-- A button's picture and letters
M.paint = function(button, name)
	if(button == nil) then
		return;
	end
	local id = button:GetName();
	try(find(id .. "Icon"), "SetTexture", M.iconPath(name));
	local text = find(id .. "Letters");
	if(text) then
		text:SetText(M.letters(name));
	end
	try(find(id .. "Glow"), "SetTexture", Kitty.Skin.path("sq_hl"));
	if(button.GetHighlightTexture) then
		try(button:GetHighlightTexture(), "SetTexture", Kitty.Skin.path("sq_hl"));
	end
end

-- Saved places: x/y for the mode button, tx/ty for the current mode readout
local PLACES = {
	-- Leave the default housing/furniture controls clear. Explicit saved
	-- positions still take precedence; the readout keeps its existing gap.
	KittyModeButton = {"x", "y", -8, 72, -230, 192},
	KittyModeText = {"tx", "ty", -8, 116, -230, 236},	-- under the mode button
};
M.place = function()
	local mode = M.setting();
	for name, spec in pairs(PLACES) do
		local button = find(name);
		if(button) then
			button:ClearAllAnchors();
			local x, y = tonumber(mode[spec[1]]), tonumber(mode[spec[2]]);
			if(x and y) then
				button:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", x, y);
			elseif(find("MinimapViewFrame")) then
				-- left of the minimap, a little below its middle
				button:SetAnchor("RIGHT", "LEFT", "MinimapViewFrame", spec[3], spec[4]);
			else
				button:SetAnchor("TOPRIGHT", "TOPRIGHT", "UIParent", spec[5], spec[6]);
			end
		end
	end
end
M.savePlace = function(button)
	local spec = PLACES[button:GetName()] or PLACES.KittyModeButton;
	local x, y = button:GetPos();
	local scale = (type(GetUIScale) == "function" and GetUIScale()) or 1;
	M.setting()[spec[1]] = x / scale;
	M.setting()[spec[2]] = y / scale;
end

M.refresh = function()
	M.refreshText();
	local button = find("KittyModeButton");
	if(button == nil) then
		return;
	end
	if(not M.isShown()) then
		button:Hide();
		if(not M.pickHandler or (Kitty.isTurnedOff and Kitty.isTurnedOff())) then M.closeFlyout(); end
		return;
	end
	M.paint(button, M.current() or "");
	button:Show();
	local flyout = find("KittyModeFlyout");
	if(flyout and flyout:IsVisible()) then
		M.fillFlyout();
	end
end

-- Left click: open the modes. Right-drag (or Shift+left-drag) moves it unless locked.
M.onLoad = function(button)
	-- XML provides the initial anchors. Place both widgets in afterLoad, once
	-- VARIABLES_LOADED has supplied their saved positions and both frames exist.
	if(button and button.RegisterForClicks) then
		pcall(button.RegisterForClicks, button, "LeftButton", "RightButton");
	end
end
M.isDragKey = function(key)
	return key == "RBUTTON" or key == "RightButton" or (type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false);
end
M.onMouseDown = function(button, key)
	M.lastKey = key;	-- shown by /kc probe
	button.kittyDownX, button.kittyDownY = button:GetPos();
	button.kittyDragKey = M.isDragKey(key);
	if(button.kittyDragKey and not M.isLocked()) then
		button:StartMoving();
		button.kittyMoving = true;
	end
end
M.onMouseUp = function(button, key)
	local moved = false;
	local dragKey = button.kittyDragKey;
	button.kittyDragKey = nil;
	if(button.kittyMoving) then
		button:StopMovingOrSizing();
		button.kittyMoving = nil;
		local x, y = button:GetPos();
		moved = math.abs(x - (button.kittyDownX or x)) > 2 or math.abs(y - (button.kittyDownY or y)) > 2;
		if(moved) then
			M.savePlace(button);
			M.closeFlyout();
		end
	end
	if(not moved and not dragKey) then
		if(button:GetName() == "KittyModeText") then
			M.openMenu();
		else
			M.toggleFlyout();
		end
	end
end
M.onEnter = function(button)
	local current, on = M.current();
	local lines = {Kitty.L("ModeButtonTitle", "Kitty mode: <<1>>", current or Kitty.L("ModeNone", "none"))};
	if(on and #on > 1) then
		table.insert(lines, Kitty.L("ModesOn", "On: <<1>>", table.concat(on, ", ")));
	end
	table.insert(lines, Kitty.L("ModeButtonClick", "|cff9ea8baClick: pick a mode|r"));
	if(not M.isLocked()) then
		table.insert(lines, Kitty.L("ModeButtonDrag", "|cff9ea8baRight-drag (or Shift+drag): move. Lock it in Kitty options|r"));
	end
	Kitty.showGameTooltip(button, lines);
end

--------------------------------------------------------------------------------
-- The modes that open under the button
M.flyoutList = function()
	local list = {""};	-- "" = no mode
	for _, name in ipairs(M.names()) do
		table.insert(list, name);
	end
	return list;
end

local function numericCall(fn, ...)
	if(type(fn) ~= "function") then return nil; end
	local ok, value = pcall(fn, ...);
	if(ok and type(value) == "number" and value == value and value > 0 and value < math.huge) then return value; end
end

-- GetPos is in screen pixels; popup anchors and dimensions are UI units.
-- Keep the saved button/readout positions independent of popup placement.
local function fitFlyout(flyout, anchor, count, footer)
	local scale = numericCall(GetUIScale) or 1;
	local width = numericCall(GetScreenWidth);
	local height = numericCall(GetScreenHeight);
	width = width and width / scale or numericCall(UIParent and UIParent.GetWidth, UIParent) or 1024;
	height = height and height / scale or numericCall(UIParent and UIParent.GetHeight, UIParent) or 768;
	local ok, x, y = try(anchor, "GetPos");
	x, y = ok and tonumber(x) or 0, ok and tonumber(y) or 0;
	x, y = (x or 0) / scale, (y or 0) / scale;
	local aw = numericCall(anchor and anchor.GetWidth, anchor) or 36;
	local ah = numericCall(anchor and anchor.GetHeight, anchor) or 36;
	local real, rw, rh = try(anchor, "GetRealSize");
	if(real and tonumber(rw) and tonumber(rh)) then aw, ah = rw / scale, rh / scale; end
	local available = math.max(y - 8, height - y - ah - 8);
	local preferred = math.min(M.PER_ROW, count);
	if(x <= M.SIZE + M.GAP and footer == 0 and 12 + count * (M.SIZE + M.GAP) - M.GAP <= available) then
		preferred = 1; -- left-edge selectors read top-down when a full column fits
	end
	local columns, best = preferred, nil;
	for candidate = 1, count do
		local w = 12 + candidate * (M.SIZE + M.GAP) - M.GAP;
		local h = 12 + math.ceil(count / candidate) * (M.SIZE + M.GAP) - M.GAP + footer;
		if(w <= width - 8 and h <= height - 8 and (footer == 0 or w >= 100)) then
			local score = math.abs(candidate - preferred) + (h > available and 100 or 0);
			if(best == nil or score < best) then columns, best = candidate, score; end
		end
	end
	local rows = math.ceil(count / columns);
	local w = 12 + columns * (M.SIZE + M.GAP) - M.GAP;
	local h = 12 + rows * (M.SIZE + M.GAP) - M.GAP + footer;
	local fit = math.max(0.01, math.min(1, math.max(1, width - 8) / w, math.max(1, height - 8) / h));
	try(flyout, "SetScale", fit);
	flyout:SetSize(w, h);
	local px = x + aw - w * fit;
	if(px < 4) then px = x; end
	px = math.max(0, math.min(width - w * fit, math.max(4, px)));
	local py = y + ah + 4;
	if(py + h * fit > height - 4) then py = y - h * fit - 4; end
	py = math.max(0, math.min(height - h * fit, math.max(4, py)));
	flyout:ClearAllAnchors();
	flyout:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", px / fit, py / fit);
	try(flyout, "SetFrameStrata", "DIALOG");
	return columns, w, h;
end

M.fillFlyout = function()
	local flyout = find("KittyModeFlyout");
	local button = M.flyoutAnchor or find("KittyModeButton");
	if(flyout == nil or button == nil) then
		return;
	end
	local all = M.pickerChoices or M.flyoutList();
	local capacity = M.MAX + 1;
	M.pageCount = math.max(1, math.ceil(#all / capacity));
	M.page = math.max(0, math.min(M.page or 0, M.pageCount - 1));
	local list = {};
	for i = 1, capacity do
		local name = all[M.page * capacity + i];
		if(name ~= nil) then list[#list + 1] = name; end
	end
	M.shownList = list;
	local footer = M.pageCount > 1 and 26 or 0;
	local columns, width, height = fitFlyout(flyout, button, math.max(1, #list), footer);
	local current = M.pickHandler and M.pickerCurrent or M.current() or "";
	for index = 1, M.MAX + 1 do
		local choice = find("KittyModeFlyout_Button" .. index);
		if(choice) then
			if(list[index] ~= nil) then
				local column = (index - 1) % columns;
				local row = math.floor((index - 1) / columns);
				choice:ClearAllAnchors();
				choice:SetAnchor("TOPLEFT", "TOPLEFT", flyout:GetName(), 6 + column * (M.SIZE + M.GAP), 6 + row * (M.SIZE + M.GAP));
				M.paint(choice, list[index]);
				local glow = find(choice:GetName() .. "Glow");
				if(glow) then
					if(list[index] == current) then glow:Show(); else glow:Hide(); end
				end
				choice:Show();
			else
				choice:Hide();
			end
		end
	end
	for _, spec in ipairs({{"Prev",6,"<"},{"Next",width - 36,">"},{"Page",width / 2 - 20,tostring(M.page + 1) .. "/" .. M.pageCount}}) do
		local control = find("KittyModeFlyout_" .. spec[1]);
		if(control) then
			if(footer > 0) then
				control:ClearAllAnchors();
				control:SetAnchor("TOPLEFT", "TOPLEFT", flyout:GetName(), spec[2], height - footer);
				try(control, "SetText", spec[3]); control:Show();
			else control:Hide(); end
		end
	end
	try(find("KittyModeFlyout_SkinBg"), "SetTexture", Kitty.Skin.path("inner"));
	if(not flyout.kittyBox and Kitty.Skin.box) then
		flyout.kittyBox = true;
		Kitty.Skin.box(flyout, "gold", 0, 1, "BORDER");
	end
end

-- The editor reuses the same icon picker with a selection callback. Picking an
-- action's mode must not switch the player's live mode while editing a draft.
M.openPicker = function(anchor, onPick, current, includeNone)
	local flyout = find("KittyModeFlyout");
	if(flyout == nil) then return false; end
	M.flyoutAnchor, M.pickHandler, M.pickerCurrent, M.page = anchor or find("KittyModeButton"), onPick, current or "", 0;
	M.pickerChoices = nil;
	if(onPick) then
		M.pickerChoices = includeNone == false and {} or {""};
		for _, name in ipairs(M.names()) do table.insert(M.pickerChoices, name); end
		if(#M.pickerChoices == 0) then M.closeFlyout(); return false; end
	end
	M.fillFlyout(); flyout:Show(); return true;
end
M.toggleFlyout = function(anchor)
	local flyout = find("KittyModeFlyout");
	anchor = anchor or find("KittyModeButton");
	if(flyout and flyout:IsVisible() and M.flyoutAnchor == anchor and not M.pickHandler) then
		M.closeFlyout();
	else M.openPicker(anchor, nil, M.current() or "", true); end
end
M.changePage = function(delta)
	M.page = math.max(0, math.min((M.page or 0) + delta, (M.pageCount or 1) - 1));
	M.fillFlyout();
end
M.closeFlyout = function()
	local flyout = find("KittyModeFlyout");
	if(flyout) then
		flyout:Hide();
	end
	M.pickHandler, M.pickerChoices, M.flyoutAnchor, M.pickerCurrent, M.page = nil, nil, nil, nil, 0;
	M.shownList = nil;
end
M.pick = function(index)
	local flyout = find("KittyModeFlyout");
	if(not flyout or not flyout:IsVisible()) then return; end
	local name = M.shownList and M.shownList[index];
	if(name == nil) then
		return;
	end
	local choose = M.pickHandler;
	M.closeFlyout();
	if(choose) then choose(name); else M.set(name); end
end
M.onChoiceEnter = function(choice)
	local name = M.shownList and M.shownList[choice:GetID()];
	if(name == nil) then
		return;
	end
	local current = M.pickHandler and M.pickerCurrent or M.current() or "";
	local title = (name == "") and Kitty.L("ModeNoneButton", "No mode (all off)") or name;
	if(name == current) then
		title = title .. (M.pickHandler and Kitty.L("ModeSelected", "  |cff40ff40(selected)|r") or Kitty.L("ModeCurrent", "  |cff40ff40(now)|r"));
	end
	-- In the kitty editor a click only picks the action's mode
	local hint = M.pickHandler and Kitty.L("ModeChoicePick", "|cff9ea8baClick to use this mode for the action|r")
		or Kitty.L("ModeChoiceClick", "|cff9ea8baClick to switch to this mode|r");
	Kitty.showGameTooltip(choice, {title, hint});
end

--------------------------------------------------------------------------------
-- Current mode readout ("Show current mode" in Kitty options): "Mode: [aoe]";
-- a click opens a menu of every mode
M.textLabel = function()
	return Kitty.L("ModeReadout", "Mode: <<1>>", Kitty.colorCyan(M.current() or Kitty.L("ModeNone", "none")));
end
-- Cherry's Bar shows the mode on a bar when it is installed. While it does, it is told when the mode
-- may have changed and Kitty's own plate stays hidden; passing nil gives the plate back.
M.setTextHost = function(host)
	M.textHost = host;
	M.refreshText();
end
M.refreshText = function()
	if(M.textHost) then
		pcall(M.textHost);
	end
	local readout = find("KittyModeText");
	if(readout == nil) then
		return;
	end
	if(M.textHost or not M.isTextShown()) then
		readout:Hide();
		return;
	end
	try(find("KittyModeText_SkinBg"), "SetTexture", Kitty.Skin.path("inner"));
	if(not readout.kittyBox and Kitty.Skin.box) then
		readout.kittyBox = true;
		Kitty.Skin.box(readout, "gold", 0, 1, "BORDER");
	end
	if(readout.GetHighlightTexture) then
		try(readout:GetHighlightTexture(), "SetTexture", Kitty.Skin.path("hover"));
	end
	local text = find("KittyModeTextText");
	if(text) then
		text:SetText(M.textLabel());
		Kitty.Skin.color(text, {1, 0.85, 0.4});
	end
	readout:Show();
end
-- Menu entries: no mode, then every mode
M.menuChoices = function()
	local list = {Kitty.L("ModeNoneButton", "No mode (all off)")};
	for _, name in ipairs(M.names()) do
		if(#list >= 30) then
			break;	-- menus hold at most 32 entries
		end
		table.insert(list, name);
	end
	return list;
end
M.onMenuPick = function(text)
	if(text == Kitty.L("ModeNoneButton", "No mode (all off)")) then
		M.set("");
	else
		M.set(text);
	end
end
M.openMenu = function()
	M.toggleFlyout(find("KittyModeText"));
end
M.onTextEnter = function(readout)
	local lines = {M.textLabel(), Kitty.L("ModeTextClick", "|cff9ea8baClick: pick a mode|r")};
	if(not M.isLocked()) then
		table.insert(lines, Kitty.L("ModeButtonDrag", "|cff9ea8baRight-drag (or Shift+drag): move. Lock it in Kitty options|r"));
	end
	Kitty.showGameTooltip(readout, lines);
end

--------------------------------------------------------------------------------
-- /kc mode [name | none | remove name | list]
M.command = function(text)
	text = trim(text);
	local word, rest = string.match(text, "^(%S+)%s*(.*)$");
	word = string.lower(word or "");
	if(word == "" or word == "list") then
		local current = M.current();
		Kitty.sendMessage(Kitty.L("ModeListAll", "Kitty modes: <<1>> (now: <<2>>). /kc mode <name> switches, /kc mode none turns all off.",
			table.concat(M.names(), ", "), current or Kitty.L("ModeNone", "none")));
	elseif(word == "none" or word == "off") then
		M.set("");
	elseif(word == "remove" or word == "del") then
		M.remove(rest);
		Kitty.sendMessage(Kitty.L("ModeRemoved", "Removed mode <<1>> from the list (kitties that use it keep it).", M.clean(rest)));
	elseif(word == "add") then
		M.add(rest);
		M.refresh();
	else
		M.set(text);
	end
end
