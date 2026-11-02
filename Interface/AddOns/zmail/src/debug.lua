local me = {}
local parent = zmail

local level = {
    { "error",  1,  0,  0}, -- 1
    {  "warn",  1, .8,  0}, -- 2
    {  "info",  1,  1,  1}, -- 3
    { "debug", .3,  .3, 1}, -- 4 
}

function me.message(level, msg, type, r,g,b)
    if (parent.getDebugConfig().level or -1) < (level or 0) then
        return
    end
    ChatFrame1:AddMessage(string.format("|cffffff00ZMail:|r %s - %s", tostring(type), tostring(msg)), r or 1,g or 1,b or 1)
end

for index, data in pairs(level) do
    me[data[1]] = function(msg) me.message(index, msg, unpack(data)) end
end

parent.debug = me
