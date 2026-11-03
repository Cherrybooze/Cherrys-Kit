local me = {}
function LoginEditBox_OnLoad(frame)
    frame.SetPlaceholder = me.SetPlaceholder
    if LoginLook then
        LoginLook.edit(frame)
    end
end

me.SetPlaceholder = function(frame, text)
    local ph = _G[frame:GetName().."_placeholder"]
    ph:SetText(text)
end