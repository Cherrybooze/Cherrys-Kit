
LOGINDROPDOWN_BUTTON_HEIGHT = 16;
LOGINDROPDOWN_BORDER_SIZE = 12;

LOGINDROPDOWN_MAXBUTTONS = 20;
LOGINDROPDOWN_OPEN_MENU = nil;

COLORDROPDOWN_BUTTON_HEIGHT = 16;
COLORDROPDOWN_BUTTON_SPACING = 6;
COLORDROPDOWN_BORDER_SIZE = 24;

COLORDROPDOWN_LINE_MAXBUTTONS = 8;
COLORDROPDOWN_MAXBUTTONS = 40;

COLORDROPDOWN_OPEN_MENU = nil;

function CloseAllDropDownList()
	ColorDropDownList:Hide();
	LoginDropDownList:Hide();
end

function ColorDropDownList_Initialize(frame, initialize)
	local frameName = frame:GetName();
	
	if ( COLORDROPDOWN_OPEN_MENU ~= frameName ) then
		COLORDROPDOWN_OPEN_MENU = frameName;
	end
	
	if ( initialize ) then
		frame.initialize = initialize;
	end
	
	frame.numButtons = 0;
	for i = 1, COLORDROPDOWN_MAXBUTTONS do
		getglobal("ColorDropDownListButton"..i):Hide();
	end
	
	if (frame.initialize) then
		frame.initialize();
	end
end

function ColorDropDownList_SetSelectedID(frame, id)
	frame.selectedID = id;
	ColorDropDownList_Refresh(frame);
end

function ColorDropDownList_GetSelectedID(frame)
	return frame.selectedID;
end

function ColorDropDownList_SetColor(frame, r, g, b)
	getglobal(frame:GetName().."Texture"):SetColor(r, g, b);
end

function ColorDropDownList_Refresh(frame)
	local button, checked, buttonChecked;
	
	for i = 1, COLORDROPDOWN_MAXBUTTONS do
		button = getglobal("ColorDropDownListButton"..i);
		buttonChecked = getglobal("ColorDropDownListButton"..i.."Checked");
		checked = nil;
		if ( ColorDropDownList_GetSelectedID(frame) == button:GetID() ) then
			checked = 1;
		end
		
		if ( checked ) then
			ColorDropDownList_SetColor(frame, button.red, button.green, button.blue);
			buttonChecked:Show();
			--button:LockHighlight();
		else
			buttonChecked:Hide();
			--button:UnlockHighlight();
		end
	end
end

--[[
================================================================
info.red [1-255]
info.green [1-255]
info.blue [1-255]
info.value [ANYTHING]
info.func [function()]
]]
function ColorDropDownList_AddButton(info)	
	local button, buttonTexture, width, height, numLines;
	
	if ( not COLORDROPDOWN_OPEN_MENU ) then
		return;
	end	
	
	local dropDownMenu = getglobal(COLORDROPDOWN_OPEN_MENU);
	local index = dropDownMenu.numButtons + 1;
	if ( index > COLORDROPDOWN_MAXBUTTONS ) then
		return;
	end
	
	dropDownMenu.numButtons = index;
	local button = getglobal("ColorDropDownListButton"..index);
	local buttonTexture = getglobal("ColorDropDownListButton"..index.."Texture");
	buttonTexture:SetColor(info.red, info.green, info.blue);
	button.red = info.red;
	button.green = info.green;
	button.blue = info.blue;
	button.value = info.value;
	button.func = info.func;
	
	button:ClearAllAnchors();
	if ( index == 1 ) then
		button:SetAnchor("TOPLEFT", "TOPLEFT", "$parent", COLORDROPDOWN_BORDER_SIZE/2, COLORDROPDOWN_BORDER_SIZE/2);
	elseif ( index <= COLORDROPDOWN_LINE_MAXBUTTONS ) then
		button:SetAnchor("TOPLEFT", "TOPRIGHT", "ColorDropDownListButton"..(index-1), COLORDROPDOWN_BUTTON_SPACING, 0);
	else
		button:SetAnchor("TOPLEFT", "BOTTOMLEFT", "ColorDropDownListButton"..(index-COLORDROPDOWN_LINE_MAXBUTTONS), 0, COLORDROPDOWN_BUTTON_SPACING);
	end
	
	if ( ColorDropDownList_GetSelectedID(dropDownMenu) == index ) then
		getglobal("ColorDropDownListButton"..index.."Checked"):Show();
	else
		getglobal("ColorDropDownListButton"..index.."Checked"):Hide();
	end
	
	button:Show();
	
	numLines = math.floor((index-1) / COLORDROPDOWN_LINE_MAXBUTTONS) + 1;
	height = numLines * COLORDROPDOWN_BUTTON_HEIGHT + (numLines-1) * COLORDROPDOWN_BUTTON_SPACING + COLORDROPDOWN_BORDER_SIZE;
	width = index * COLORDROPDOWN_BUTTON_HEIGHT + (index-1) * COLORDROPDOWN_BUTTON_SPACING + COLORDROPDOWN_BORDER_SIZE;
	
	if ( index <= COLORDROPDOWN_LINE_MAXBUTTONS ) then
		ColorDropDownList:SetWidth(width);
	end
	ColorDropDownList:SetHeight(height);
end

function ColorDropDownList_OnUpdate(this, elapsedTime)
	if ( this.showTimer ) then
		this.showTimer = this.showTimer - elapsedTime;
		if ( this.showTimer < 0 ) then
			this:Hide();
			this.showTimer = nil;
		end
	end
end

function ColorDropDownListButton_OnClick(this)
	if ( not this.func ) then
		return;
	end
	this.func(this);
	this:GetParent():Hide();
end

function ToggleColorDropDownMenu(frame, anchorName, xOffset, yOffset)
	local point, relativePoint, relativeTo;
	if ( not frame ) then
		frame = COLORDROPDOWN_OPEN_MENU;
	end
	
	if ( ColorDropDownList:IsVisible() and COLORDROPDOWN_OPEN_MENU == frame:GetName() ) then
		ColorDropDownList:Hide();
	else
		CloseAllDropDownList();
	
		ColorDropDownList:ClearAllAnchors();
		ColorDropDownList:Hide();

		if ( not anchorName ) then
			if ( frame.point ) then
				point = frame.point;
			end
			if ( frame.relativePoint ) then
				point = frame.relativePoint;
			end
			if ( frame.xOffset ) then
				xOffset = frame.xOffset;
			end
			if ( frame.yOffset ) then
				yOffset = frame.yOffset;
			end
			if ( frame.relativeTo ) then
				relativeTo = frame.relativeTo;
			else
				relativeTo = frame:GetName();
			end
		elseif ( anchorName == "cursor" ) then
			relativeTo = "UIParent";
			local cursorX, cursorY = GetCursorPos();
			if ( not xOffset ) then
				xOffset = 0;
			end
			if ( not yOffset ) then
				yOffset = 0;
			end
			xOffset = cursorX + xOffset;
			yOffset = cursorY + yOffset;
		else
			relativeTo = anchorName;
		end
		if ( not point ) then
			point = "TOPLEFT";
		end
		if ( not relativePoint ) then
			relativePoint = "BOTTOMLEFT";
		end
		ColorDropDownList:SetAnchor(point, relativePoint, relativeTo, xOffset, yOffset);
		ColorDropDownList_Initialize(frame);
		if ( frame.numButtons == 0 ) then
			return;
		end
		ColorDropDownList:Show();
	end
end

function LoginDropDownList_Initialize(frame, initialize, displayMode)
	local frameName = frame:GetName();
	
	if ( LOGINDROPDOWN_OPEN_MENU ~= frameName ) then
		LOGINDROPDOWN_OPEN_MENU = frameName;
	end
	
	if ( initialize ) then
		frame.initialize = initialize;
	end

	-- Change appearance based on the displayMode
	if ( displayMode == "MENU" ) then
		getglobal(frame:GetName().."Left"):Hide();
		getglobal(frame:GetName().."Middle"):Hide();
		getglobal(frame:GetName().."Right"):Hide();
		getglobal(frame:GetName().."Button"):Hide();
		frame.displayMode = "MENU";
	else
		frame.numButtons = 0;
		LoginDropDownList.maxWidth = 0;
		for i = 1, LOGINDROPDOWN_MAXBUTTONS do
			getglobal("LoginDropDownListButton"..i):Hide();
		end
	
		if (frame.initialize) then
			frame.initialize();
		end
	end
end

function LoginDropDownList_SetSelectedID(frame, id)
	frame.selectedID = id;
	frame.selectedValue = nil;
	LoginDropDownList_Refresh(frame);
end

function LoginDropDownList_GetSelectedID(frame)
	return frame.selectedID;
end

function LoginDropDownList_SetSelectedValue(frame, value)
	frame.selectedValue = value;
	frame.selectedID = nil;
	LoginDropDownList_Refresh(frame);
end

function LoginDropDownList_GetSelectedValue(frame)
	return frame.selectedValue;
end

function LoginDropDownList_SetText(frame, text)
	getglobal(frame:GetName().."Text"):SetText(text);
end

function LoginDropDownList_SetWidth(frame, width)
	if ( not frame ) then
		return;
	end
	frame:SetWidth(width + 24);
	getglobal(frame:GetName().."Text"):SetWidth(width - 16);
	frame.noResize = 1;
end

function LoginDropDownList_Refresh(frame)
	local button, checked, checkImage;
	local frameName = frame:GetName();
	
	for i = 1, LOGINDROPDOWN_MAXBUTTONS do
		button = getglobal("LoginDropDownListButton"..i);
		checked = nil;

		if ( LoginDropDownList_GetSelectedID(frame) ) then
			if ( LoginDropDownList_GetSelectedID(frame) == button:GetID() ) then
				checked = 1;
			end
		elseif ( LoginDropDownList_GetSelectedValue(frame) ) then
			if ( LoginDropDownList_GetSelectedValue(frame) == button.value ) then
				checked = 1;
			end
		end
		
		-- If checked show check image
		checkImage = getglobal(button:GetName().."Check");
		
		if ( checked ) then
			LoginDropDownList_SetText(frame, button:GetText());
			checkImage:Show();
			--button:LockHighlight();
		else
			checkImage:Hide();
			--button:UnlockHighlight();
		end
	end
end

--[[
================================================================
info.text [string]
info.value [ANYTHING]
info.checked = [nil, 1]  		--  Check the button
info.notCheckable = [nil, 1]  	--  
info.func [function()]
]]
function LoginDropDownList_AddButton(info)
	local button, height, width;
	
	if ( not LOGINDROPDOWN_OPEN_MENU ) then
		return;
	end	
	
	local dropDownMenu = getglobal(LOGINDROPDOWN_OPEN_MENU);
	local index = dropDownMenu.numButtons + 1;
	if ( index > LOGINDROPDOWN_MAXBUTTONS ) then
		return;
	end
	
	dropDownMenu.numButtons = index;
	local button = getglobal("LoginDropDownListButton"..index);
	local buttonName = button:GetName();
	local normalText = getglobal(button:GetName().."NormalText");
	
	if ( info.text ) then
		button:SetText(info.text);
		
		width = button:GetTextWidth() + 12 + 30;
		
		if ( info.notCheckable ) then
			width = width - 30;
		end
		
		if ( width > LoginDropDownList.maxWidth ) then
			LoginDropDownList.maxWidth = width;
		end
	else
		button:SetText("");
	end
	
	button:ClearAllAnchors();
	normalText:ClearAllAnchors();
	if ( info.notCheckable ) then
		--xPos = xPos + 3;
		normalText:SetAnchor("LEFT", "LEFT", button, 0, 0);
	else
		normalText:SetAnchor("LEFT", "LEFT", button, 27, 0);
	end
	
	local xPos = LOGINDROPDOWN_BORDER_SIZE;
	local yPos = (index - 1) * LOGINDROPDOWN_BUTTON_HEIGHT + LOGINDROPDOWN_BORDER_SIZE;
	button:ClearAllAnchors();
	button:SetAnchor("TOPLEFT", "TOPLEFT", LoginDropDownList, xPos, yPos);
	button.value = info.value;
	button.func = info.func;
	button:Show();
	
	-- See if button is selected by id or name
	if ( dropDownMenu ) then
		if ( LoginDropDownList_GetSelectedID(dropDownMenu) ) then
			if ( button:GetID() == LoginDropDownList_GetSelectedID(dropDownMenu) ) then
				info.checked = 1;
			end
		elseif ( LoginDropDownList_GetSelectedValue(dropDownMenu) ) then
			if ( button.value == LoginDropDownList_GetSelectedValue(dropDownMenu) ) then
				info.checked = 1;
			end
		end
	end
	
	-- Show the check if checked
	if ( info.checked ) then
		button:LockHighlight();
		getglobal(buttonName.."Check"):Show();
	else
		button:UnlockHighlight();
		getglobal(buttonName.."Check"):Hide();
	end
	
	LoginDropDownList:SetHeight(index * LOGINDROPDOWN_BUTTON_HEIGHT + LOGINDROPDOWN_BORDER_SIZE * 2);
end

function LoginDropDownList_OnUpdate(this, elapsedTime)
	if ( this.showTimer ) then
		this.showTimer = this.showTimer - elapsedTime;
		if ( this.showTimer < 0 ) then
			this:Hide();
			this.showTimer = nil;
		end
	end
end

function LoginDropDownListButton_OnClick(this)
	if ( not this.func ) then
		return;
	end
	this.func(this);
	this:GetParent():Hide();
end

function ToggleLoginDropDownMenu(frame, anchorName, xOffset, yOffset)
	local point, relativePoint, relativeTo;
	if ( not frame ) then
		frame = LOGINDROPDOWN_OPEN_MENU;
	end
	
	if ( LoginDropDownList:IsVisible() and LOGINDROPDOWN_OPEN_MENU == frame:GetName() ) then
		LoginDropDownList:Hide();
	else
		CloseAllDropDownList();
		
		LoginDropDownList:ClearAllAnchors();
		LoginDropDownList:Hide();

		if ( not anchorName ) then
			if ( frame.point ) then
				point = frame.point;
			end
			if ( frame.relativePoint ) then
				point = frame.relativePoint;
			end
			if ( frame.xOffset ) then
				xOffset = frame.xOffset;
			end
			if ( frame.yOffset ) then
				yOffset = frame.yOffset;
			end
			if ( frame.relativeTo ) then
				relativeTo = frame.relativeTo;
			else
				relativeTo = frame:GetName();
			end
		elseif ( anchorName == "cursor" ) then
			relativeTo = "UIParent";
			local cursorX, cursorY = GetCursorPos();
			if ( not xOffset ) then
				xOffset = 0;
			end
			if ( not yOffset ) then
				yOffset = 0;
			end
			xOffset = cursorX + xOffset;
			yOffset = cursorY + yOffset;
		else
			relativeTo = anchorName;
		end
		if ( not point ) then
			point = "TOPRIGHT";
		end
		if ( not relativePoint ) then
			relativePoint = "BOTTOMRIGHT";
		end
		LoginDropDownList:SetAnchor(point, relativePoint, relativeTo, xOffset, yOffset);
		LoginDropDownList_Initialize(frame);
		if ( frame.numButtons == 0 ) then
			return;
		end
		LoginDropDownList:Show();
	end
end