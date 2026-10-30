
local me = {}
me.update = function(frame)
    local min, max = frame:GetMinMaxValues()
    local down = _G[frame:GetName().."ScrollDownButton"]
	local up = _G[frame:GetName().."ScrollUpButton"]
	if frame:GetValue() == min then
       up:Disable()
    else
        up:Enable()
	end
	if frame:GetValue() == max then
        down:Disable()
    else
        down:Enable()
	end
end

_G["LOGIN_SCROLLBAR_TEMPLATE"] = me