-- ClassIcons.lua: the class-combo icon for a primary/secondary class (used by the Class trigger).
-- The icons ship with Cherry's KittyCombo 1.5.0+ (Kitty.ClassIcon, gfx/class); without it there is no icon.

local RWA = RWA

-- Kitty's icon helper expects tokens, so normalize numeric and localized API
-- values. Client IDs 9/10 are Warlock/Champion; pbInfo's display indices differ.
local CLASS_IDS = { "WARRIOR", "RANGER", "THIEF", "MAGE", "AUGUR", "KNIGHT",
  "WARDEN", "DRUID", "HARPSYN", "PSYRON" }
local tokens = { RUNEDANCER = "WARDEN" } -- old client name for Warden
for _, token in ipairs(CLASS_IDS) do
  tokens[token] = token
end
local names = {WARRIOR="Warrior",RANGER="Scout",THIEF="Rogue",MAGE="Mage",AUGUR="Priest",KNIGHT="Knight",
  WARDEN="Warden",DRUID="Druid",HARPSYN="Warlock",PSYRON="Champion",any="Any"}
local localized = {}
for token, name in pairs(names) do localized[string.lower(name)] = token end

local function classToken(value)
  if type(value) == "number" then
    return CLASS_IDS[value] or value
  end
  if type(value) ~= "string" or value == "" then
    return value
  end
  local id = tonumber(value)
  if id and CLASS_IDS[id] then
    return CLASS_IDS[id]
  end
  local key = string.lower(value)
  local token = tokens[string.upper(value)] or localized[key]
  if token then
    return token
  end
  -- Unlike learning from nearby units, system strings also cover raid members
  -- and clients where UnitClassToken is unavailable. Failed lookups can retry.
  for name, canonical in pairs(tokens) do
    local key = "SYS_CLASSNAME_" .. name
    local ok, text
    if type(GetSystemString) == "function" then
      ok, text = pcall(GetSystemString, key)
    end
    if (not ok or type(text) ~= "string" or text == key or text == "") and type(TEXT) == "function" then
      ok, text = pcall(TEXT, key)
    end
    if ok and type(text) == "string" and text ~= "" and text ~= key then
      localized[string.lower(text)] = canonical
    end
  end
  return localized[key] or value
end

RWA.ClassToken=classToken
RWA.ClassNames=names
RWA.ClassChoices={{label="Any",value="any"}}
for _,token in ipairs(CLASS_IDS) do RWA.ClassChoices[#RWA.ClassChoices+1]={label=RWA.ClassNames[token],value=token} end

function RWA.ClassIcon(main, sub)
  if Kitty and type(Kitty.ClassIcon) == "function" then
    local ok, path = pcall(Kitty.ClassIcon, classToken(main), classToken(sub))
    if ok and type(path) == "string" and path ~= "" then
      return path
    end
  end
  return nil
end
