-- Cherry's KittyCombo: window look (dark navy panels, golden borders) shared
-- with rom weakauras (RWA.THEME), and the corner grip that resizes a window.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.Skin = {};
-- Windows skinned in this load. Reload UI builds the windows again and runs
-- this file again, so this starts empty with them.
Kitty.Skin.done = {};
-- Texture names must stay unique for the whole session (Kitty survives a reload)
Kitty.SkinSerial = Kitty.SkinSerial or 0;

-- Colours (text; panels and lines are baked into gfx/ui/*.tga)
Kitty.Skin.TITLE = {1, 0.78, 0.25};
Kitty.Skin.HEADER = {0.80, 0.84, 0.92};
Kitty.Skin.MUTED = {0.62, 0.66, 0.74};
Kitty.Skin.BUTTON_TEXT = {1, 0.82, 0.35};
Kitty.Skin.PRIMARY_TEXT = {1, 0.93, 0.72};

-- Window size, same range and step as rom weakauras and the kit hub
Kitty.Skin.MIN_SCALE = 0.6;
Kitty.Skin.MAX_SCALE = 1.6;
Kitty.Skin.STEP = 0.1;
-- Cursor pixels per 10% while dragging the grip
Kitty.Skin.PIXELS_PER_STEP = 25;

local LAYERS = {BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5};

-- Call obj:method(...) only when the client has it; true when it ran
local function try(obj, method, ...)
	if(obj ~= nil and type(obj[method]) == "function") then
		return pcall(obj[method], obj, ...);
	end
	return false;
end
Kitty.Skin.try = try;

-- A global widget without creating one (the tests make widgets on lookup)
local function find(name)
	if(type(rawget) == "function") then
		return rawget(_G, name);
	end
	return _G[name];
end
Kitty.Skin.find = find;

Kitty.Skin.path = function(name)
	return Kitty.BASE_PATH .. "gfx/ui/" .. name .. ".tga";
end;

local function nameOf(obj)
	if(type(obj) == "string") then
		return obj;
	end
	return obj and obj.GetName and obj:GetName();
end

-- A texture drawn on parent's layer, as rom weakauras makes them
Kitty.Skin.texture = function(parent, layer, file)
	if(type(CreateUIComponent) ~= "function") then
		return nil;
	end
	Kitty.SkinSerial = Kitty.SkinSerial + 1;
	local ok, texture = pcall(CreateUIComponent, "Texture", "KittySkin" .. Kitty.SkinSerial, nameOf(parent));
	if(not ok or texture == nil) then
		return nil;
	end
	try(parent, "SetLayers", LAYERS[layer] or 3, texture);
	if(file ~= nil) then
		try(texture, "SetTexture", Kitty.Skin.path(file));
	end
	return texture;
end;
Kitty.Skin.place = function(obj, point, relativeTo, relativePoint, x, y)
	try(obj, "ClearAllAnchors");
	try(obj, "SetAnchor", point, relativePoint or point, nameOf(relativeTo), x or 0, y or 0);
end;
Kitty.Skin.fill = function(obj, relativeTo, inset)
	inset = inset or 0;
	try(obj, "ClearAllAnchors");
	try(obj, "SetAnchor", "TOPLEFT", "TOPLEFT", nameOf(relativeTo), inset, inset);
	try(obj, "SetAnchor", "BOTTOMRIGHT", "BOTTOMRIGHT", nameOf(relativeTo), -inset, -inset);
end;
-- A frame of four lines, inset pixels inside parent
Kitty.Skin.box = function(parent, file, inset, thick, layer)
	local name = nameOf(parent);
	local lines = {};
	local sides = {
		{"TOPLEFT", inset, inset, "TOPRIGHT", -inset, inset + thick},
		{"BOTTOMLEFT", inset, -inset - thick, "BOTTOMRIGHT", -inset, -inset},
		{"TOPLEFT", inset, inset, "BOTTOMLEFT", inset + thick, -inset},
		{"TOPRIGHT", -inset - thick, inset, "BOTTOMRIGHT", -inset, -inset},
	};
	for _, side in ipairs(sides) do
		local line = Kitty.Skin.texture(parent, layer or "BORDER", file);
		if(line ~= nil) then
			try(line, "ClearAllAnchors");
			try(line, "SetAnchor", side[1], side[1], name, side[2], side[3]);
			try(line, "SetAnchor", side[4], side[4], name, side[5], side[6]);
			table.insert(lines, line);
		end
	end
	return lines;
end;

Kitty.Skin.color = function(obj, color)
	if(not try(obj, "SetColor", color[1], color[2], color[3])) then
		try(obj, "SetTextColor", color[1], color[2], color[3]);
	end
end;

--------------------------------------------------------------------------------
-- Buttons: the game's button templates keep their behaviour, only the
-- pictures change. Normal, pushed, disabled and highlight are swapped when
-- the client has the getters (zBag uses GetNormalTexture and friends).
local function setPicture(texture, file)
	if(texture ~= nil and try(texture, "SetTexture", Kitty.Skin.path(file))) then
		try(texture, "SetTexCoord", 0, 1, 0, 1);
		return true;
	end
	return false;
end
-- How the last button was skinned, for /kc probe
Kitty.Skin.buttonReport = nil;
Kitty.Skin.button = function(button, primary)
	if(button == nil) then
		return false;
	end
	local name = nameOf(button) or "";
	local normal = primary and "btn_primary" or "btn";
	local pushed = primary and "btn_primary_pushed" or "btn_pushed";
	local got = {};
	local function swap(getter, file)
		local ok, texture = try(button, getter);
		if(ok and texture ~= nil and setPicture(texture, file)) then
			table.insert(got, getter);
		end
	end
	swap("GetNormalTexture", normal);
	swap("GetPushedTexture", pushed);
	swap("GetDisabledTexture", "btn_disabled");
	swap("GetHighlightTexture", "btn_hl");
	-- Templates drawn in three pieces
	for _, piece in ipairs({"Left", "Middle", "Right"}) do
		local texture = find(name .. piece);
		if(texture ~= nil and texture ~= button) then
			try(texture, "Hide");
		end
	end
	-- Gold label
	local color = primary and Kitty.Skin.PRIMARY_TEXT or Kitty.Skin.BUTTON_TEXT;
	local label = find(name .. "Text");
	if(label == nil) then
		local ok, fontString = try(button, "GetFontString");
		label = ok and fontString or nil;
	end
	if(label ~= nil) then
		Kitty.Skin.color(label, color);
	else
		try(button, "SetNormalTextColor", color[1], color[2], color[3]);
	end
	Kitty.Skin.buttonReport = (#got > 0) and table.concat(got, ", ") or "no texture getters";
	return #got > 0;
end;
-- Small square row buttons: up, down, plus, minus
Kitty.Skin.square = function(button, kind)
	if(button == nil) then
		return false;
	end
	local ok, normal = try(button, "GetNormalTexture");
	local done = ok and setPicture(normal, "sq_" .. kind);
	local okPushed, pushed = try(button, "GetPushedTexture");
	if(okPushed) then
		setPicture(pushed, "sq_" .. kind);
	end
	local okHl, highlight = try(button, "GetHighlightTexture");
	if(okHl) then
		setPicture(highlight, "sq_hl");
	end
	return done and true or false;
end;
-- List row: blue hover instead of the auction house glow, a line underneath
Kitty.Skin.row = function(row)
	local ok, highlight = try(row, "GetHighlightTexture");
	if(ok) then
		setPicture(highlight, "hover");
	end
	local line = Kitty.Skin.texture(row, "BACKGROUND", "divider");
	if(line ~= nil) then
		try(line, "ClearAllAnchors");
		try(line, "SetAnchor", "BOTTOMLEFT", "BOTTOMLEFT", nameOf(row), 4, 0);
		try(line, "SetAnchor", "BOTTOMRIGHT", "BOTTOMRIGHT", nameOf(row), -4, 0);
		try(line, "SetHeight", 1);
	end
	for _, kind in ipairs({"Up", "Down", "Plus", "Minus"}) do
		Kitty.Skin.square(find(nameOf(row) .. kind .. "Button"), string.lower(kind));
	end
	-- Condition rows: the plain sentence underneath
	local summary = find(nameOf(row) .. "Summary");
	if(summary ~= nil) then
		Kitty.Skin.color(summary, Kitty.Skin.MUTED);
	end
end;
-- Inner panel (lists): darker fill, thin line around it
Kitty.Skin.panel = function(frame)
	if(frame == nil) then
		return;
	end
	local background = find(nameOf(frame) .. "_SkinBg");
	if(background ~= nil) then
		try(background, "SetTexture", Kitty.Skin.path("inner"));
	end
	Kitty.Skin.box(frame, "divider", 0, 1, "BORDER");
end;

--------------------------------------------------------------------------------
-- Window: background, double golden border, the kitty, gold title.
-- spec (Kitty.Skin.SPECS) = {appAt={x, y}, appColor, titleAt={x, y},
--     headers/muted={label names}, buttons/primary={button names},
--     panels={inner frames}, rows={prefix, count}, rowButtons={suffixes}}
Kitty.Skin.SPECS = {};
Kitty.Skin.window = function(frame, spec)
	local name = nameOf(frame);
	if(name == nil or Kitty.Skin.done[name]) then
		return false;
	end
	Kitty.Skin.done[name] = true;
	spec = spec or Kitty.Skin.SPECS[name] or {};

	local background = find(name .. "_SkinBg");
	if(background ~= nil) then
		try(background, "SetTexture", Kitty.Skin.path("panel"));
	end
	Kitty.Skin.box(frame, "gold", 0, 2, "BORDER");
	Kitty.Skin.box(frame, "golddark", 5, 1, "BORDER");

	-- The kitty peeks over the top left corner
	local mascot = Kitty.Skin.texture(frame, "OVERLAY", "mascot");
	if(mascot ~= nil) then
		try(mascot, "SetSize", 60, 60);
		Kitty.Skin.place(mascot, "TOPLEFT", frame, "TOPLEFT", -14, -14);
	end
	-- Two lines next to it: the addon name (small) and this window's title (gold)
	local appAt = spec.appAt or {60, 9};
	local app = find(name .. "_VersionLabel");
	if(app ~= nil) then
		Kitty.Skin.place(app, "TOPLEFT", frame, "TOPLEFT", appAt[1], appAt[2]);
		Kitty.Skin.color(app, spec.appColor or Kitty.Skin.MUTED);
	end
	local titleAt = spec.titleAt or {60, 25};
	local title = find(name .. "_TitleLabel");
	if(title ~= nil) then
		if(spec.titleAt == nil) then
			try(title, "SetSize", 400, 20);
		end
		Kitty.Skin.place(title, "TOPLEFT", frame, "TOPLEFT", titleAt[1], titleAt[2]);
		Kitty.Skin.color(title, Kitty.Skin.TITLE);
	end
	for _, labelName in ipairs(spec.headers or {}) do
		Kitty.Skin.color(find(labelName), Kitty.Skin.HEADER);
	end
	for _, labelName in ipairs(spec.muted or {}) do
		Kitty.Skin.color(find(labelName), Kitty.Skin.MUTED);
	end
	for _, buttonName in ipairs(spec.buttons or {}) do
		Kitty.Skin.button(find(buttonName), false);
	end
	for _, buttonName in ipairs(spec.primary or {}) do
		Kitty.Skin.button(find(buttonName), true);
	end
	for _, panelName in ipairs(spec.panels or {}) do
		Kitty.Skin.panel(find(panelName));
	end
	if(spec.rows ~= nil) then
		for index = 1, spec.rows[2] do
			local row = find(spec.rows[1] .. index);
			if(row ~= nil) then
				Kitty.Skin.row(row);
				for _, suffix in ipairs(spec.rowButtons or {}) do
					Kitty.Skin.button(find(spec.rows[1] .. index .. suffix), false);
				end
			end
		end
	end
	local grip = find(name .. "_Grip");
	if(grip ~= nil) then
		Kitty.Skin.gripLoad(grip);
	end
	return true;
end;

--------------------------------------------------------------------------------
-- Window size (per window, saved in setting.window.scale)
local function scaleTable()
	local window = Kitty.SettingManager and Kitty.SettingManager.setting and Kitty.SettingManager.setting.window;
	if(window == nil) then
		return nil;
	end
	if(type(window.scale) ~= "table") then
		window.scale = {};
	end
	return window.scale;
end
Kitty.Skin.clamp = function(scale)
	scale = tonumber(scale) or 1;
	scale = math.max(Kitty.Skin.MIN_SCALE, math.min(Kitty.Skin.MAX_SCALE, scale));
	return math.floor(scale / Kitty.Skin.STEP + 0.5) / math.floor(1 / Kitty.Skin.STEP + 0.5);
end;
Kitty.Skin.getScale = function(frame)
	local saved = scaleTable();
	return Kitty.Skin.clamp(saved and saved[nameOf(frame)] or 1);
end;
Kitty.Skin.setScale = function(frame, scale)
	scale = Kitty.Skin.clamp(scale);
	local saved = scaleTable();
	if(saved ~= nil) then
		-- 100% is the default, so it is not stored
		saved[nameOf(frame)] = (math.abs(scale - 1) > 0.001) and scale or nil;
	end
	try(frame, "SetScale", scale);
	return scale;
end;

-- Every window's OnShow: skin once, size, then the shared position
Kitty.Skin.onShow = function(frame)
	pcall(Kitty.Skin.window, frame);
	try(frame, "SetScale", Kitty.Skin.getScale(frame));
	Kitty.loadPosition(frame);
end;

--------------------------------------------------------------------------------
-- Corner grip (gui/KittySkin.xml): drag right for bigger, left for smaller,
-- in 10% steps.
Kitty.Skin.drag = nil;
Kitty.Skin.gripLoad = function(grip)
	local texture = find(nameOf(grip) .. "Texture");
	if(texture ~= nil) then
		try(texture, "SetTexture", Kitty.Skin.path("grip"));
	end
end;
Kitty.Skin.gripHighlight = function(grip, on)
	local texture = find(nameOf(grip) .. "Texture");
	if(texture ~= nil) then
		try(texture, "SetTexture", Kitty.Skin.path(on and "grip_hl" or "grip"));
	end
end;
Kitty.Skin.gripTooltip = function(grip)
	local frame = grip:GetParent();
	Kitty.showGameTooltip(grip, {
		Kitty.L("SizeTitle", "Window size"),
		Kitty.L("SizeHelp", "Drag this corner right for bigger, left for smaller."),
		Kitty.L("SizeNow", "Now <<1>>%", tostring(math.floor(Kitty.Skin.getScale(frame) * 100 + 0.5))),
	});
end;
Kitty.Skin.gripStart = function(grip)
	local x, y = 0, 0;
	if(type(GetCursorPos) == "function") then
		x, y = GetCursorPos();
	end
	local frame = grip:GetParent();
	Kitty.Skin.drag = {grip = grip, frame = frame, x = tonumber(x) or 0, y = tonumber(y) or 0, scale = Kitty.Skin.getScale(frame)};
end;
-- The scale a drag of dx cursor pixels gives (sideways only: the client's
-- cursor y may count up or down)
Kitty.Skin.dragScale = function(startScale, dx)
	local steps = dx / Kitty.Skin.PIXELS_PER_STEP;
	steps = (steps >= 0) and math.floor(steps) or -math.floor(-steps);
	return Kitty.Skin.clamp(startScale + steps * Kitty.Skin.STEP);
end;
Kitty.Skin.gripUpdate = function(grip)
	local drag = Kitty.Skin.drag;
	if(drag == nil or drag.grip ~= grip or type(GetCursorPos) ~= "function") then
		return;
	end
	local x, y = GetCursorPos();
	local scale = Kitty.Skin.dragScale(drag.scale, (tonumber(x) or 0) - drag.x);
	if(math.abs(scale - Kitty.Skin.getScale(drag.frame)) > 0.001) then
		Kitty.Skin.setScale(drag.frame, scale);
		Kitty.loadPosition(drag.frame);
		Kitty.Skin.gripTooltip(grip);
	end
end;
Kitty.Skin.gripStop = function(grip)
	Kitty.Skin.drag = nil;
end;

--------------------------------------------------------------------------------
-- What each window has
Kitty.Skin.SPECS = {
	KittyBasicConfigFrame = {
		headers = {"KittyBasicConfigFrame_Separator1Label", "KittyBasicConfigFrame_Separator2Label"},
		buttons = {"KittyBasicConfigFrame_ChangelogButton", "KittyBasicConfigFrame_CancelButton"},
		primary = {"KittyBasicConfigFrame_CommandListButton", "KittyBasicConfigFrame_CloseButton"},
	},
	KittyChangelogFrame = {
		buttons = {"KittyChangelogFrame_PrevButton", "KittyChangelogFrame_NextButton"},
		primary = {"KittyChangelogFrame_CloseButton"},
		muted = {"KittyChangelogFrame_PageLabel"},
	},
	KittyCommandListFrame = {
		appAt = {58, 16},
		appColor = {0.95, 0.96, 1},
		titleAt = {22, 60},
		headers = {"KittyCommandListFrame_CommandListNameLabel", "KittyCommandListFrame_CommandListClassLabel",
			"KittyCommandListFrame_CommandListTargetLabel", "KittyCommandListFrame_ActionsLabel"},
		muted = {"KittyCommandListFrame_FooterLabel"},
		buttons = {"KittyCommandListFrame_ImportButton", "KittyCommandListFrame_CancelButton"},
		primary = {"KittyCommandListFrame_CreateButton", "KittyCommandListFrame_CloseButton"},
		panels = {"KittyCommandListFrame_List"},
		rows = {"KittyCommandListFrame_Button", 10},
		rowButtons = {"EditButton"},
	},
	KittyCommandConfigFrame = {
		headers = {"KittyCommandConfigFrame_PriorityTopLabel", "KittyCommandConfigFrame_PriorityBottomLabel"},
		muted = {"KittyCommandConfigFrame_FooterLabel"},
		buttons = {"KittyCommandConfigFrame_ExportButton", "KittyCommandConfigFrame_ImportButton",
			"KittyCommandConfigFrame_MacroButton", "KittyCommandConfigFrame_CancelButton"},
		primary = {"KittyCommandConfigFrame_CloseButton"},
		panels = {"KittyCommandConfigFrame_List"},
		rows = {"KittyCommandConfigFrame_Button", 10},
		rowButtons = {"ConditionButton"},
	},
	KittyCommandConditionFrame = {
		headers = {"KittyCommandConditionFrame_HintLabel"},
		muted = {"KittyCommandConditionFrame_FooterLabel"},
		buttons = {"KittyCommandConditionFrame_CancelButton"},
		primary = {"KittyCommandConditionFrame_CloseButton"},
		panels = {"KittyCommandConditionFrame_List"},
		rows = {"KittyCommandConditionFrame_Button", 10},
	},
};
