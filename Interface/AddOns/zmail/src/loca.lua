local loca = {}


local function init()
    loca = loadfile("interface/addons/zmail/locale/en.lua")()
    local lang = loadfile(string.format("interface/addons/zmail/locale/%s.lua", GetLanguage():sub(1,2)))()
    for key, value in pairs(lang) do
        loca[key] = value
    end
end
local res, err = pcall(init)
if not res then
    ChatFrame1:AddMessage("ZMail: loca: "..tostring(err))
end

local me = zmail

function me.GetLocaString(key)
    return (loca or {})[key] or key
end
function me.ReloadLang()
    init()
end
