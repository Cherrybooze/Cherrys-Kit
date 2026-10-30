local me = {}
function LoginEditBox_OnLoad(frame)
    frame.SetPlaceholder = me.SetPlaceholder
end

me.SetPlaceholder = function(frame, text)
    local ph = _G[frame:GetName().."_placeholder"]
    ph:SetText(text)
end