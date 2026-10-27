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
	if(not quiet) then
		Kitty.sendMessage(Kitty.L("ModeNow", "Kitty mode: <<1>>", name ~= "" and ("|cff40ff40" .. name .. "|r") or Kitty.L("ModeNone", "none")));
	end
	M.refresh();
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
	KittyModeButton = {"x", "y", -8, 40, -230, 160},
	KittyModeText = {"tx", "ty", -8, 84, -230, 204},	-- under the mode button
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
		M.closeFlyout();
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
		if(#list > M.MAX) then
			break;
		end
		table.insert(list, name);
	end
	return list;
end
M.fillFlyout = function()
	local flyout = find("KittyModeFlyout");
	local button = find("KittyModeButton");
	if(flyout == nil or button == nil) then
		return;
	end
	local list = M.flyoutList();
	M.shownList = list;
	local current = M.current() or "";
	for index = 1, M.MAX + 1 do
		local choice = find("KittyModeFlyout_Button" .. index);
		if(choice) then
			if(list[index] ~= nil) then
				local column = math.mod and math.mod(index - 1, M.PER_ROW) or ((index - 1) % M.PER_ROW);
				local row = math.floor((index - 1) / M.PER_ROW);
				choice:ClearAllAnchors();
				choice:SetAnchor("TOPLEFT", "TOPLEFT", flyout, 6 + column * (M.SIZE + M.GAP), 6 + row * (M.SIZE + M.GAP));
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
	local columns = math.min(#list, M.PER_ROW);
	local rows = math.ceil(#list / M.PER_ROW);
	flyout:SetSize(12 + columns * M.SIZE + (columns - 1) * M.GAP, 12 + rows * M.SIZE + (rows - 1) * M.GAP);
	try(find("KittyModeFlyout_SkinBg"), "SetTexture", Kitty.Skin.path("inner"));
	if(not flyout.kittyBox and Kitty.Skin.box) then
		flyout.kittyBox = true;
		Kitty.Skin.box(flyout, "gold", 0, 1, "BORDER");
	end
	-- open downwards, or upwards when the button is in the lower half of the screen
	flyout:ClearAllAnchors();
	local _, y = button:GetPos();
	local height = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768;
	local scale = (type(GetUIScale) == "function" and GetUIScale()) or 1;
	if(y and y / scale > height / 2) then
		flyout:SetAnchor("BOTTOMRIGHT", "TOPRIGHT", button, 0, -4);
	else
		flyout:SetAnchor("TOPRIGHT", "BOTTOMRIGHT", button, 0, 4);
	end
end
M.toggleFlyout = function()
	local flyout = find("KittyModeFlyout");
	if(flyout == nil) then
		return;
	end
	if(flyout:IsVisible()) then
		flyout:Hide();
	else
		M.fillFlyout();
		flyout:Show();
	end
end
M.closeFlyout = function()
	local flyout = find("KittyModeFlyout");
	if(flyout) then
		flyout:Hide();
	end
end
M.pick = function(index)
	local name = M.shownList and M.shownList[index];
	if(name == nil) then
		return;
	end
	M.set(name);
	M.closeFlyout();
end
M.onChoiceEnter = function(choice)
	local name = M.shownList and M.shownList[choice:GetID()];
	if(name == nil) then
		return;
	end
	local current = M.current() or "";
	local title = (name == "") and Kitty.L("ModeNoneButton", "No mode (all off)") or name;
	if(name == current) then
		title = title .. Kitty.L("ModeCurrent", "  |cff40ff40(now)|r");
	end
	Kitty.showGameTooltip(choice, {title, Kitty.L("ModeChoiceClick", "|cff9ea8baClick to switch to this mode|r")});
end

--------------------------------------------------------------------------------
-- Current mode readout ("Show current mode" in Kitty options): "Mode: [aoe]";
-- a click opens a menu of every mode
M.textLabel = function()
	return Kitty.L("ModeReadout", "Mode: <<1>>", Kitty.colorCyan(M.current() or Kitty.L("ModeNone", "none")));
end
M.refreshText = function()
	local readout = find("KittyModeText");
	if(readout == nil) then
		return;
	end
	if(not M.isTextShown()) then
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
	local menu = find("KittyModeTextMenu");
	if(menu == nil or type(ToggleDropDownMenu) ~= "function") then
		return;
	end
	local function toggle()
		-- RoM: ToggleDropDownMenu(frame, level); WoW puts level first
		if(not pcall(ToggleDropDownMenu, menu, 1)) then
			pcall(ToggleDropDownMenu, 1, nil, menu);
		end
	end
	local list = find("DropDownList1");
	toggle();
	if(list and list.IsVisible and not list:IsVisible() and not menu:IsVisible() and not M.menuWasOpen) then
		-- the menu may need its frame shown: show it invisible, without its arrow
		try(menu, "SetAlpha", 0);
		try(find(menu:GetName() .. "Button"), "Hide");
		menu:Show();
		M.menuShownFrame = true;
		toggle();
	end
	M.menuWasOpen = list and list.IsVisible and list:IsVisible() or nil;
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
