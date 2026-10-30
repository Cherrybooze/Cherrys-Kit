-- local _,y = loadfile("interface/loginxml/frames/login.charselect.lua") lprint(y) 
local me = {
    raceSexList = {}, --
    classList = {}, --
    parts = {
        'Head', 'Breasts', 'Stature', 'Chest', 'Figure', 'Arm', 'Forearm',
        'Hand', 'Leg', 'Calf', 'Foot'
    }, --
    _locks = {}
}

function me.onLoad()
    me.initRaceSexList()
    me.initClassList()
end
function me.registerEvents(this)
    this:RegisterEvent('CHARACTER_CREATE_SUCCESS');
    this:RegisterEvent('CHARACTER_CREATE_FAILED');
end
function me.onEvent(event) return pcall(me[event], arg1, arg2, arg3, arg4) end
function me.onUpdate(frame, elapsed)
    if frame.rotate then
        local val = frame.rotate == 'left' and -1 or 1
        SetCharacterCreateFacing(GetCharacterCreateFacing() - val * elapsed * 60);
    end
    if frame.cursor then
        local x = GetCursorPos();
        local diff = (x - frame.cursor) * 0.6;
        SetCharacterCreateFacing(GetCharacterCreateFacing() - diff);
        frame.cursor = x
    end
end
function me.onShow()
    OpenCharacterCreateModel()
    me.updateModel()
    me.initHairColor()
    me.initBoneScale()
    me.initModelSlider()
    LoginCharCreateFrame_right_race:update()
    LoginCharCreateFrame_right_class:update()
    me.zoom(true)
end

function me.CHARACTER_CREATE_SUCCESS()
    login.GOTO('charselect')
    me.CHARACTER_CREATE_FAILED()
end
function me.CHARACTER_CREATE_FAILED() login.dialog.hide('CREATE_CHARACTER') end
-- ! ==============================================================
-- ! ========================== util ==============================
-- ! ==============================================================
function me.show() LoginCharCreateFrame:Show() end
function me.hide() LoginCharCreateFrame:Hide() end
function me.create()
    local name = LoginCharCreateFrame_right_name:GetText()
    if string.len(name) < 1 then
        login.dialog.show('OKAY', nil,
                          {text = TEXT('CHARACTER_CREATE_NAME_ERR')});
        return;
    end
    CreateCharacter(name)
    login.dialog.show('CREATE_CHARACTER');
end

function me.zoom(reset)
    local frame = LoginCharCreateFrame_left_zoom
    if reset then frame.zoom = true end
    frame:SetText(frame.zoom and CHARACTERCREATE_ZOOM_IN or
                      CHARACTERCREATE_ZOOM_OUT)
    CharacterCreate_SetLookAtFace(not frame.zoom)
    frame.zoom = not frame.zoom
end

-- ! ==============================================================
-- ! ========================== init ==============================
-- ! ==============================================================
function me.initRaceSexList()
    local raceList = {
        TEXT('LOGIN_HUMAN'), TEXT('LOGIN_ELF'), TEXT('LOGIN_DWARF')
    }
    local sexList = {TEXT('LOGIN_MALE'), TEXT('LOGIN_FEMALE')}
    for index, name in ipairs(raceList) do
        for _index, _name in ipairs(sexList) do
            if index < 3 or (index == 3 and _index == 1) then
                table.insert(me.raceSexList, {
                    string.format('%s - %s', name, _name),
                    race = index,
                    sex = _index
                })
            end
        end
    end

    local data = {
        col = {180}, --
        fn = {
            callback = me.raceCallback, --
            onClick = me.raceOnClick
        }, --
        numRow = 5, --
        rowHeight = 20, --
        noHead = true, --
        align = {0, 2} --
    }
    LoginCharCreateFrame_right_race:init(data)
    LoginCharCreateFrame_right_race_list:SetBackdropTileAlpha(.2)
end
function me.initClassList()
    local data = {
        col = {30, 150}, --
        fn = {
            callback = me.classCallback, --
            onClick = me.classOnClick --
        }, --
        numRow = 6, --
        noHead = true, --
        rowHeight = 30, --
        align = {0, 2} --
    }
    LoginCharCreateFrame_right_class:init(data)
    LoginCharCreateFrame_right_class_list:SetBackdropTileAlpha(.5)
end

function me.initHairColor()
    local r, g, b = GetCharacterHairColor()
    me._locks.modelUpdate = true
    _G['LoginCharCreateFrame_left_hair_r']:SetText(math.ceil(r * 255))
    _G['LoginCharCreateFrame_left_hair_g']:SetText(math.ceil(g * 255))
    _G['LoginCharCreateFrame_left_hair_b']:SetText(math.ceil(b * 255))
    LoginCharCreateFrame_left_hair_colorTexture:SetColor(r, g, b)
    me._locks.modelUpdate = false
end
function me.initModelSlider()
    me._locks.modelUpdate = true
    local max =
        GetCharacterCreateNumHairs(GetCharacterRace(), GetCharacterSex())
    local current = GetCharacterHair()
    LoginCharCreateFrame_left_hair:SetMinMaxValues(1, max)
    LoginCharCreateFrame_left_hair:SetValue(current)

    local max =
        GetCharacterCreateNumFaces(GetCharacterRace(), GetCharacterSex())
    local current = GetCharacterFace()
    LoginCharCreateFrame_left_face:SetMinMaxValues(1, max)
    LoginCharCreateFrame_left_face:SetValue(current)

    local max = GetCharacterCreateNumSkinColors()
    local current = GetCharacterSkinIndex()
    LoginCharCreateFrame_left_skin:SetMinMaxValues(1, max)
    LoginCharCreateFrame_left_skin:SetValue(current)
    me._locks.modelUpdate = false
end
function me.initBoneScale()
    me._locks.modelUpdate = true
    for _, part in pairs(me.parts) do
        local min, max, default = GetCharacterCreateFigureInfo(part)
        local frame = _G['LoginCharCreateFrame_left_' .. part]
        frame:SetMinMaxValues(min, max)
        frame:SetValue(default)
    end
    me._locks.modelUpdate = false
end

-- ! ==============================================================
-- ! ========================= update =============================
-- ! ==============================================================
function me.updateClassList()
    local classes = {GetCharacterCreateClassInfo()}
    me.classList = {}
    local imgpath = 'interface/widgeticons/classicon_%s.tga';
    for i = 1, #classes, 2 do
        local name, token = GetClassInfoByID(classes[i])
        local icon = string.format(imgpath, token)
        table.insert(me.classList,
                     {{tex = icon}, {text = name}, id = classes[i]})
    end
    LoginCharCreateFrame_right_class:update()
end
function me.updateModel(val)
    if me._locks.modelUpdate then return end
    local is_empty = val == nil
    val = val or {}
    local race = val.race or GetCharacterRace()
    local sex = val.sex or GetCharacterSex()
    local class = val.class or GetCharacterVocation()
    local face = val.face or GetCharacterFace()
    local hair = val.hair or GetCharacterHair()
    local skin = val.skin or GetCharacterSkinIndex()
    local hair_r, hair_g, hair_b = unpack(
                                       val.hair_color or
                                           {GetCharacterHairColor()})

    UpdateCharacterCreateModel(race, sex, class, face, hair, skin, hair_r,
                               hair_g, hair_b)
    if is_empty or val.race then me.updateClassList() end
end
function me.updateHairColor()
    local r =
        (tonumber(_G['LoginCharCreateFrame_left_hair_r']:GetText()) or 0) / 255
    local g =
        (tonumber(_G['LoginCharCreateFrame_left_hair_g']:GetText()) or 0) / 255
    local b =
        (tonumber(_G['LoginCharCreateFrame_left_hair_b']:GetText()) or 0) / 255

    LoginCharCreateFrame_left_hair_colorTexture:SetColor(r, g, b)
    if not me._locks.colorpicker then
        LoginColorTextureFrame_SetColor(r, g, b)
    end
    me.updateModel({hair_color = {r, g, b}})
end
function me.colorpickerCallback()
    local r = LoginColorPickerFrame.r
    local g = LoginColorPickerFrame.g
    local b = LoginColorPickerFrame.b
    me._locks.colorpicker = true
    LoginCharCreateFrame_left_hair_r:SetText(math.ceil(r * 255))
    LoginCharCreateFrame_left_hair_g:SetText(math.ceil(g * 255))
    LoginCharCreateFrame_left_hair_b:SetText(math.ceil(b * 255))
    me._locks.colorpicker = nil
end
function me.updateBoneScale()
    if me._locks.modelUpdate then return end
    local val = {}
    for index, part in ipairs(me.parts) do
        val[index] = _G['LoginCharCreateFrame_left_' .. part]:GetValue()
    end
    UpdateCharacterCreateModelBoneScale(unpack(val))
end

-- ! ==============================================================
-- ! ========================== list ==============================
-- ! ==============================================================
function me.classOnClick(frame, double, index)
    if double then return end
    local data = me.classList[index]
    me.updateModel({class = data.id})
    LoginCharCreateFrame_right_class:update()
end

function me.raceOnClick(frame, double, index)
    if double then return end
    local data = me.raceSexList[index]
    me.updateModel({race = data.race, sex = data.sex})
    LoginCharCreateFrame_right_race:update()
    me.initModelSlider()
end

function me.classCallback()
    local index = nil
    local _class = GetCharacterVocation()
    for i, data in pairs(me.classList) do
        if _class == data.id then index = i end
    end
    return me.classList, {}, index
end
function me.raceCallback()
    local index = nil
    local _race = GetCharacterRace()
    local _sex = GetCharacterSex()
    for i, data in pairs(me.raceSexList) do
        if _race == data.race and _sex == data.sex then index = i end
    end
    return me.raceSexList, {}, index
end

-- ! ==============================================================
-- ! ========================= helper =============================
-- ! ==============================================================
function me.generateName()
    local min = login.config.charname_min
    local max = login.config.charname_max
    if type(min) ~= "number" or min < 4 then min = 4 end
    if type(max) ~= "number" or max > 16 then max = 16 end
    local length = math.random(min, max)

    local cons_1 = {
        "b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s",
        "t", "v", "w", "z", "br", "bl", "cr", "cl", "ch", "chr", "dr", "dw",
        "fr", "fl", "gr", "gl", "gh", "gn", "kr", "kl", "pr", "pl", "ph", "phr",
        "qu", "sc", "scr", "sh", "shr", "sk", "sl", "sm", "sn", "sp", "spr",
        "spl", "squ", "st", "str", "sw", "th", "thr", "tr", "tw", "wr", "wh"
    }
    local cons_2 = {
        "b", "c", "d", "f", "g", "h", "k", "l", "m", "n", "p", "que", "r", "s",
        "t", "w", "rd", "nd", "ld", "ff", "rf", "lf", "ng", "rg", "gh", "sh",
        "ch", "rch", "th", "rth", "nth", "ph", "rk", "sk", "lk", "ll", "rl",
        "rn", "gn", "rp", "sp", "lp", "ss", "st", "rst", "ct", "nt", "lt"
    }
    local vows_1 = {
        "a", "e", "i", "o", "ai", "ea", "ei", "ee", "oo", "oa", "oi"
    }
    local vows_2 = {
        "a", "e", "i", "o", "u", "ae", "ai", "ea", "ei", "ee", "oo", "oa", "oi",
        "y"
    }

    local name

    local isVowel = math.random() > 0.5
    -- Start the name
    if isVowel then
        name = vows_1[math.random(#vows_1)]
    else
        name = cons_1[math.random(#cons_1)]
    end

    while (#name < length) do
        isVowel = not isVowel -- Toggle
        if isVowel then
            name = name .. vows_2[math.random(#vows_2)]
        else
            name = name .. cons_2[math.random(#cons_2)]
        end
    end

    if name:len()>16 then
        name = name:sub(1,16)
    end
    -- Capitalise
    name = name:sub(1, 1):upper() .. name:sub(2, -1):lower()

    return name
end

login.charcreate = me;

