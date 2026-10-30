-- Cherry's KittyCombo: /kc probe checks, in the real client, the things the
-- offline tests could only guess. Results go to chat and are saved in
-- KittyCombo_Setting.probe (SavedVariables) so they can be read back later.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.Probe = {};

Kitty.Probe.GLOBALS = {
	"HasMacro", "GetMacroInfo", "EditMacro", "GetNumMacroIcons", "GetMacroIconInfo", "PickupMacroItem",
	"UnitCastingTime", "UIDropDownMenu_StartCounting", "UIDropDownMenu_AddButton", "ToggleDropDownMenu",
	"CloseDropDownMenus", "GetSkillDetail", "GetSkillCooldown", "UnitBuff", "GetActionInfo",
};

-- One result line: ok = true (pass), false (fail) or nil (look at it yourself)
Kitty.Probe.add = function(result, ok, name, detail)
	table.insert(result.lines, {ok = ok, name = name, detail = tostring(detail or "")});
end;

Kitty.Probe.run = function()
	local result = {version = Kitty.version, lines = {}};
	local add = Kitty.Probe.add;

	-- Client functions this version relies on
	local missing = {};
	for _, name in ipairs(Kitty.Probe.GLOBALS) do
		if(type(_G[name]) ~= "function" and type(_G[name]) ~= "table") then
			table.insert(missing, name);
		end
	end
	add(result, #missing == 0, "client functions", #missing == 0 and "all present" or ("missing: " .. table.concat(missing, ", ")));
	add(result, true, "install folder", Kitty.BASE_PATH);

	-- Macro API (read only: nothing is created)
	local slots = Kitty.Macro and Kitty.Macro.getSlotCount() or 0;
	local used, sample = 0, nil;
	local ok, err = pcall(function()
		for slot = 1, slots do
			if(HasMacro(slot)) then
				used = used + 1;
				if(sample == nil) then
					local icon, name, body = GetMacroInfo(slot);
					sample = "slot " .. slot .. ": icon=" .. tostring(icon) .. " name=" .. tostring(name) .. " body=" .. string.sub(tostring(body), 1, 30);
				end
			end
		end
	end);
	add(result, ok, "macro slots", ok and (slots .. " slots (MAX_NUM_MACROS=" .. tostring(MAX_NUM_MACROS) .. "), " .. used .. " used, " .. tostring(GetNumMacroIcons and GetNumMacroIcons()) .. " icons") or err);
	if(sample) then
		add(result, type(sample) == "string", "macro read", sample);
	end

	-- Export box: how many characters it really holds
	if(KittyCommandConfigFrame_ExportEditBox) then
		local box = KittyCommandConfigFrame_ExportEditBox;
		local before = box:GetText();
		box:SetText(string.rep("x", 5000));
		local held = string.len(box:GetText() or "");
		box:SetText(before or "");
		add(result, held >= 1000, "export box length", "holds " .. held .. " of 5000 characters");
	end

	-- Chat input: how long a message can be (the 255 limit used for the warning)
	local chatBox = _G["ChatFrameEditBox"] or _G["ChatFrame1EditBox"];
	if(chatBox and chatBox.SetText and chatBox.GetText) then
		local before = chatBox:GetText();
		chatBox:SetText(string.rep("x", 600));
		local held = string.len(chatBox:GetText() or "");
		chatBox:SetText(before or "");
		add(result, held <= Kitty.Share.CHAT_LIMIT, "chat message limit", "chat box holds " .. held .. " characters (warning uses " .. Kitty.Share.CHAT_LIMIT .. ")");
	else
		add(result, nil, "chat message limit", "chat input box not found by name");
	end

	-- Share codes: compression loads and a code survives the round trip
	local deflate = Kitty.Share.getDeflate();
	add(result, deflate ~= nil, "LibDeflate", deflate and "loaded" or "not loaded: codes fall back to CKC1");
	local list = Kitty.SettingManager.setting.command and Kitty.SettingManager.setting.command[1];
	if(list) then
		local start = os and os.clock and os.clock() or 0;
		local code = Kitty.Share.exportCommandList(list);
		local back = Kitty.Share.importCommandList(code);
		local ms = os and os.clock and math.floor((os.clock() - start) * 1000) or -1;
		add(result, back ~= nil and #back == #list, "share code round trip", string.sub(code, 1, 5) .. " " .. string.len(code) .. " characters, " .. ms .. " ms");
	end

	-- Dropdowns: hover help and staying open. Opens a KittyCombo menu for a moment.
	add(result, Kitty.DropDown.originalStartCounting ~= nil, "keep-open hook", "show time " .. tostring(UIDROPDOWNMENU_SHOW_TIME));
	local menu = KittyCommandConfigFrame_TargetDropDownMenu;
	if(menu and ToggleDropDownMenu) then
		local okMenu, menuErr = pcall(function()
			CloseDropDownMenus();
			-- RoM: ToggleDropDownMenu(dropDownFrame, level, ...); WoW puts level first
			if(not pcall(ToggleDropDownMenu, menu, 1)) then
				ToggleDropDownMenu(1, nil, menu);
			end
			local list1 = _G["DropDownList1"];
			local button = _G["DropDownList1Button1"];
			local shown = list1 and list1.IsVisible and list1:IsVisible();
			add(result, shown and true or nil, "menu opens", "list visible: " .. tostring(shown) .. ", open menu: " .. tostring(type(UIDROPDOWNMENU_OPEN_MENU) == "table" and UIDROPDOWNMENU_OPEN_MENU.GetName and UIDROPDOWNMENU_OPEN_MENU:GetName() or UIDROPDOWNMENU_OPEN_MENU));
			-- Class icons in class menus: drawn by KittyCombo on the menu buttons
			local buildMenu = KittyCommandConfigFrame_BuildDropDownMenu;
			if(buildMenu) then
				CloseDropDownMenus();
				if(not pcall(ToggleDropDownMenu, buildMenu, 1)) then
					ToggleDropDownMenu(1, nil, buildMenu);
				end
				local shownIcons = 0;
				for _, entry in pairs(Kitty.MenuIcons) do
					if(entry.texture and entry.texture.IsVisible and entry.texture:IsVisible()) then
						shownIcons = shownIcons + 1;
					end
				end
				local count = list1 and rawget(list1, "numButtons");
				add(result, shownIcons > 0 and true or nil, "menu button icons", shownIcons .. " class icons on the class menu (numButtons "
					.. tostring(count) .. "). Look: icons at the right of the class letters?");
				CloseDropDownMenus();
			end
			if(button) then
				add(result, button.tooltipTitle ~= nil or button.tooltipText ~= nil, "hover help reaches menu buttons",
					"tooltipTitle=" .. tostring(button.tooltipTitle) .. ", tooltipText=" .. string.sub(tostring(button.tooltipText), 1, 40));
			end
			if(list1) then
				UIDropDownMenu_StartCounting(list1);
				add(result, (tonumber(list1.showTimer) or 0) >= Kitty.DropDown.KEEP_OPEN_SECONDS, "menu countdown stretched", "showTimer=" .. tostring(list1.showTimer));
			end
			CloseDropDownMenus();
		end);
		if(not okMenu) then
			add(result, false, "menu test", menuErr);
		end
	end

	-- Window position: a window opened at the saved spot should report it back
	if(KittyChangelogFrame and KittyChangelogFrame.GetPos and GetUIScale) then
		local okPos, posErr = pcall(function()
			local window = Kitty.SettingManager.setting.window;
			local savedX, savedY = window.framePositionX, window.framePositionY;
			Kitty.loadPosition(KittyChangelogFrame);
			local px, py = KittyChangelogFrame:GetPos();
			local scale = GetUIScale();
			local backX, backY = (tonumber(px) or 0) / scale, (tonumber(py) or 0) / scale;
			local same = math.abs(backX - savedX) < 3 and math.abs(backY - savedY) < 3;
			add(result, same, "window position", string.format("saved %d,%d; opens at %d,%d; UI scale %.2f", savedX, savedY, backX, backY, scale));
		end);
		if(not okPos) then
			add(result, nil, "window position", posErr);
		end
	end

	-- Get code puts the code on the clipboard
	add(result, type(Chat_CopyToClipboard) == "function", "clipboard", "Chat_CopyToClipboard " .. (type(Chat_CopyToClipboard) == "function" and ("present, codes up to " .. Kitty.clipboardMax() .. " characters are copied") or "missing: codes stay selected in the box"));

	-- Window size: a window at 120% must still open at the saved spot. If the
	-- client does not scale anchor offsets, remember that (window.scaledOffsets).
	if(KittyChangelogFrame and KittyChangelogFrame.GetPos and GetUIScale and Kitty.Skin) then
		local okSize, sizeErr = pcall(function()
			local window = Kitty.SettingManager.setting.window;
			local savedX, savedY = window.framePositionX, window.framePositionY;
			local before = Kitty.Skin.getScale(KittyChangelogFrame);
			local hasScale = type(KittyChangelogFrame.SetScale) == "function";
			window.scaledOffsets = nil;
			Kitty.Skin.setScale(KittyChangelogFrame, 1.2);
			Kitty.loadPosition(KittyChangelogFrame);
			local px, py = KittyChangelogFrame:GetPos();
			local scale = GetUIScale();
			local backX, backY = (tonumber(px) or 0) / scale, (tonumber(py) or 0) / scale;
			local same = math.abs(backX - savedX) < 3 and math.abs(backY - savedY) < 3;
			local note = "";
			if(not same and math.abs(backX - savedX / 1.2) < 3 and math.abs(backY - savedY / 1.2) < 3) then
				-- Offsets are not scaled here: use them as they are from now on
				window.scaledOffsets = false;
				note = " -> switched to unscaled offsets, run /kc probe again";
			end
			Kitty.Skin.setScale(KittyChangelogFrame, before);
			Kitty.loadPosition(KittyChangelogFrame);
			add(result, hasScale and same, "window position at 120%", string.format("SetScale %s; saved %d,%d; opens at %d,%d%s",
				hasScale and "yes" or "MISSING", savedX, savedY, backX, backY, note));
		end);
		if(not okSize) then
			add(result, nil, "window position at 120%", sizeErr);
		end
	end

	-- Window look: textures can be made at run time and buttons take new pictures
	if(Kitty.Skin) then
		local okSkin, skinErr = pcall(function()
			Kitty.Skin.done.KittyChangelogFrame = nil;
			local made = Kitty.Skin.window(KittyChangelogFrame);
			add(result, type(CreateUIComponent) == "function" and made, "window skin",
				"CreateUIComponent " .. tostring(type(CreateUIComponent) == "function") .. "; buttons: " .. tostring(Kitty.Skin.buttonReport));
		end);
		if(not okSkin) then
			add(result, false, "window skin", skinErr);
		end
	end

	-- Mode button: shown for a moment with its picture, flyout filled
	if(Kitty.ModeUI and KittyModeButton) then
		local okMode, modeErr = pcall(function()
			local basic = Kitty.SettingManager.setting.basic;
			local was = basic.showModeButton;
			basic.showModeButton = true;
			Kitty.ModeUI.refresh();
			Kitty.ModeUI.fillFlyout();
			local icon = KittyModeButtonIcon and KittyModeButtonIcon.GetTexture and KittyModeButtonIcon:GetTexture();
			local moving = type(KittyModeButton.StartMoving) == "function";
			local count = #(Kitty.ModeUI.shownList or {});
			basic.showModeButton = was;
			Kitty.ModeUI.refresh();
			add(result, moving and count > 0, "mode button", string.format("StartMoving %s; %d modes in the flyout; picture %s; MinimapViewFrame %s",
				tostring(moving), count, tostring(icon), tostring(MinimapViewFrame ~= nil)));
		end);
		if(not okMode) then
			add(result, false, "mode button", modeErr);
		end
	else
		add(result, false, "mode button", "KittyModeButton not loaded (gui/KittyModeButton.xml in the toc?)");
	end

	-- Mouse keys the mode button got (right-click it before /kc probe)
	if(Kitty.ModeUI) then
		add(result, Kitty.ModeUI.lastKey == "RBUTTON" or Kitty.ModeUI.lastKey == "RightButton" or nil, "mode button right-click",
			"last mouse key on it: " .. tostring(Kitty.ModeUI.lastKey) .. " (right-click the mode button, then run /kc probe again); RegisterForClicks " .. tostring(KittyModeButton and KittyModeButton.RegisterForClicks ~= nil));
	end

	-- Mode icons: they open from the readout and the kitty editor while the mode
	-- button is hidden (its default), so they must not depend on that button
	if(Kitty.ModeUI and KittyModeFlyout) then
		local basic = Kitty.SettingManager.setting.basic;
		local was = basic.showModeButton;
		local okText, textErr = pcall(function()
			basic.showModeButton = false;
			Kitty.ModeUI.refresh();
			Kitty.ModeUI.closeFlyout();
			Kitty.ModeUI.openPicker(KittyModeText, nil, Kitty.ModeUI.current() or "", true);
			local shown = KittyModeFlyout:IsVisible() and true or false;
			add(result, shown, "mode icons", "open with the mode button hidden: " .. tostring(shown));
		end);
		Kitty.ModeUI.closeFlyout();
		basic.showModeButton = was;
		Kitty.ModeUI.refresh();
		if(not okText) then
			add(result, false, "mode icons", textErr);
		end
	end

	-- Things only your eyes can check
	add(result, nil, "symbols", "do these show as symbols, not boxes?  \226\150\178 \226\150\188 \226\156\148 \226\128\147");
	return result;
end;

Kitty.Probe.report = function()
	local result = Kitty.Probe.run();
	Kitty.sendMessage("--- " .. Kitty.getTitle() .. " probe ---");
	local passed, failed, look = 0, 0, 0;
	for _, line in ipairs(result.lines) do
		local mark;
		if(line.ok == true) then
			mark = Kitty.color("OK", 0, 255, 0);
			passed = passed + 1;
		elseif(line.ok == false) then
			mark = Kitty.color("FAIL", 255, 64, 64);
			failed = failed + 1;
		else
			mark = Kitty.color("LOOK", 255, 200, 0);
			look = look + 1;
		end
		Kitty.sendMessage(mark .. " " .. line.name .. ": " .. line.detail);
	end
	Kitty.sendMessage(passed .. " ok, " .. failed .. " failed, " .. look .. " to check by eye. Saved in KittyCombo_Setting.probe (written on logout or /reloadui).");
	if(Kitty.SettingManager.setting) then
		Kitty.SettingManager.setting.probe = result;
	end
	return result;
end;
