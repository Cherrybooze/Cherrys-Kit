-- From [EventCodeButton v2012.05.18 by YossyE (Osel)],
-- Part of this code is borrowed from YossyE, with permission.
--------------------------------------------------------------------------------
-- Namespace
if(_G and not _G.Kitty) then
	_G.Kitty = {};
end

--------------------------------------------------------------------------------
Kitty.EventCodeButton = {};
Kitty.EventCodeButton.eventCode = nil;
Kitty.EventCodeButton.eventPassword = nil;

Kitty.EventCodeButton.startEventCode = function()
	local onOpenMail = function()
		local message = OpenMailBodyText:GetText();
		local eventCode = nil;
		local eventPassword = nil;

		if(message ~= nil) then
			-- Extract ID
			if(eventCode == nil) then
				-- Colon (half width)
				_, _, eventCode = string.find(message, "[Ii][Dd]%s-：%s-【(%w-)】");
			end
			if(eventCode == nil) then
				-- Colon (full width)
				_, _, eventCode = string.find(message, "[Ii][Dd]%s-:%s-【(%w-)】");
			end
			-- Extract password
			if(eventPassword == nil) then
				-- Colon (half width)
				_, _, eventPassword = string.find(message, "パスワード%s-：%s-【(%w-)】");
			end
			if(eventPassword == nil) then
				-- Colon (full width)
				_, _, eventPassword = string.find(message, "パスワード%s-:%s-【(%w-)】");
			end

			-- Should the button show?
			if(eventCode ~= nil and eventPassword ~= nil) then
				Kitty.EventCodeButton.eventCode = eventCode;
				Kitty.EventCodeButton.eventPassword = eventPassword;

				KittyEventCodeButton:Enable();
			else
				Kitty.EventCodeButton.eventCode = nil;
				Kitty.EventCodeButton.eventPassword = nil;

				KittyEventCodeButton:Disable();
			end

			-- Debug
			Kitty.debugPrint("ID:[" .. tostring(eventCode) .. "], Password:[" .. tostring(eventPassword) .. "]");
		end
	end;

	KittyEventCodeButton:Show();
	-- Hook
	Kitty.Hooks.set("OpenMail_Update", function(original, ...)
		local results = {original(...)};
		pcall(onOpenMail);
		return unpack(results);
	end);
end;
Kitty.EventCodeButton.endEventCode = function()
	KittyEventCodeButton:Hide();
	-- Remove hook
	Kitty.Hooks.clear("OpenMail_Update");
end;

--------------------------------------------------------------------------------
-- Load
Kitty.EventCodeButton.onLoad = function(this)
	this:RegisterEvent("LOADING_END");
end;
-- Event
Kitty.EventCodeButton.onEvent = function(this, event, arg1, arg2, arg3, arg4)
	if(event == "LOADING_END") then
		-- Must be checked at LOADING_END to detect conflicts
		if(EventCodeButton == nil) then
			Kitty.EventCodeButton.startEventCode();
		end
	end
end;

-- Speech bubble
Kitty.EventCodeButton.onEnter = function(this)
	GameTooltip:SetOwner(this, "ANCHOR_LEFT", 4, 0);

	if(Kitty.EventCodeButton.eventCode ~= nil and Kitty.EventCodeButton.eventPassword ~= nil) then
		GameTooltip:SetText(Kitty.T("message", "PickUpEventCode"), 1, 1, 1);
		GameTooltip:AddLine("   " .. Kitty.T("message", "EventCode") .. Kitty.colorGreen(Kitty.EventCodeButton.eventCode), 1, 1, 1);
		GameTooltip:AddLine("   " .. Kitty.T("message", "EventPassword") .. Kitty.colorGreen(Kitty.EventCodeButton.eventPassword), 1, 1, 1);
		GameTooltip:AddLine(Kitty.T("message", "ExchangeEventCodeMessage"), 0, 0.75, 0.95);
		GameTooltip:AddLine(Kitty.T("message", "TransmissionMessage"), 0, 0.75, 0.95);
		GameTooltip:AddLine(Kitty.T("message", "DiversionMessage", Kitty.colorCyan("YossyE")), 1, 1, 1);
	else
		GameTooltip:SetText(Kitty.T("message", "InvalidMailMessage"), 1, 1, 1);
	end

	GameTooltip:Show();
end;
Kitty.EventCodeButton.onLeave = function(this)
	GameTooltip:Hide();
end;

Kitty.EventCodeButton.onClick = function(this)
	if(Kitty.EventCodeButton.eventCode ~= nil and Kitty.EventCodeButton.eventPassword ~= nil) then
		if(not IsShiftKeyDown()) then
			-- Event code exchange
			ItemExchangeRequest(Kitty.EventCodeButton.eventCode, Kitty.EventCodeButton.eventPassword);
		else
			-- Send to the chat box
			SendMailSubjectEditBox:SetText(OpenMailSubject:GetText());
			SendMailBodyEditBox:SetText(OpenMailBodyText:GetText());
			MailFrameTab_OnClick(2);
			SendMailNameEditBox:SetFocus();
		end
	end
end;

Kitty.EventCodeButton.exchange = function(isExchange)
	if(isExchange) then
		-- Event code exchange
		ItemExchangeRequest(Kitty.EventCodeButton.eventCode, Kitty.EventCodeButton.eventPassword);
	else
		Kitty.sendMessage(Kitty.T("message", "EventCodeMessage", Kitty.colorGreen(Kitty.EventCodeButton.eventCode), Kitty.colorGreen(Kitty.EventCodeButton.eventPassword)));
	end
end;
