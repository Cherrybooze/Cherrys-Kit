local parent = zmail
local me = {
    helper = {},
    functions = {},
    events = {},
    loaded = false,
}


function me.events.MAIL_LOAD_FILES()
    me.load()
    parent.SendEvent("ITEMFN_UPDATE")
end

function me.OnLoad()
    for event, fn in pairs(me.events) do
        parent.RegisterEventHandler(event, "zmail.itemfn", fn)
    end
end

function me.Register(key, fn, note)
    me.functions[key] = {
        key = key, 
        fn=fn,
        note=note
    }
end

function me.GetFunction(name)
    local data = me.functions[name]
    if not data then
        parent.debug.error(string.format("Function doesn't exist %s", name))
    end
    return data and data.fn
end

function me.GetHelper(name)
    local res = me.helper[name]
    if not res then
        parent.debug.error(string.format("Helper doesn't exist %s", name))
    end
    return res
end
function me.RegisterHelper(name, fn)
    if me.helper[name] then
        parent.debug.warn(string.format("Helper already exists: %s", name))
    end
    me.helper[name] = fn
end

local function loadDBFile(path)
    local data = parent.loadFile(path, nil, nil, me.Register, me.GetFunction, me.GetHelper, me.RegisterHelper)
    if not data then return end
    for key, entry in pairs(data) do
        me.Register(key, entry[1], entry[2])
    end
end

function me.load()
    me.loaded = true
    me.Register("all", function() return true end)
    local data = parent.loadFile("itemfn/_index.lua")
    for i, entry in pairs(data or {}) do
        if entry.use then
            loadDBFile(string.format("itemfn/%s.lua", entry.name))
        end
    end
end

function me.Print()
    for key, data in pairs(me.functions) do
        ChatFrame1:AddMessage(string.format("%s, %s", tostring(data.key), tostring(data.note)))
    end
end

parent.itemfn = me
