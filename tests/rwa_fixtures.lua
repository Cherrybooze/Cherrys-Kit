-- Small RoM UI/game double. Missing widget methods stay missing; XML scripts
-- and every production Widgets/Events/Triggers/Regions/Options function run as-is.
fixtureWidgets, fixtureXmlScripts, fixtureMessages, fixtureErrors = {}, {}, {}, {}
fixtureNow, fixtureBuffs, fixtureUnits = 100, {}, { player = true, target = true }

local Widget = {}
Widget.__index = Widget

function FixtureDispatch(name, script)
  local obj = fixtureWidgets[name]
  local code = (fixtureXmlScripts[name] and fixtureXmlScripts[name][script])
    or (obj and obj.scripts[script])
  if not code then return end
  local previous = this
  this = obj
  local fn = assert(loadstring(code, name .. "." .. script))
  fn()
  this = previous
end

function FixtureWidget(kind, name, parent, template)
  local obj = setmetatable({ kind = kind, name = name, parent = parent,
    visible = true, text = "", width = 48, height = 48, scripts = {}, events = {} }, Widget)
  fixtureWidgets[name], _G[name] = obj, obj
  if kind == "CheckButton" then
    function obj:SetChecked(value) self.checked = value and true or false end
    function obj:IsChecked() return self.checked == true end
  end
  if template and fixtureXmlScripts[template] then fixtureXmlScripts[name] = fixtureXmlScripts[template] end
  return obj
end
function Widget:GetName() return self.name end
function Widget:GetParent() return _G[self.parent] end
function Widget:SetSize(w, h) self.width, self.height = w, h end
function Widget:SetWidth(w) self.width = w end
function Widget:SetHeight(h) self.height = h end
function Widget:GetWidth() return self.width end
function Widget:GetHeight() return self.height end
function Widget:ClearAllAnchors() self.anchor = nil end
function Widget:SetAnchor(point, relativePoint, relativeTo, x, y)
  assert(type(relativeTo) == "string", "native anchors require a widget name")
  self.anchor = { point, relativePoint, relativeTo, x, y }
  self.x, self.y = x, y
end
function Widget:GetPos() return self.x or 0, self.y or 0 end
function Widget:GetRealSize() return self.width * (self.scale or 1), self.height * (self.scale or 1) end
function Widget:SetText(text)
  local changed = self.text ~= text
  self.text = text
  if changed then FixtureDispatch(self.name, "OnTextChanged") end
end
function Widget:GetText() return self.text end
function Widget:SetTexture(path) self.texture = path end
function Widget:GetTexture() return self.texture end
function Widget:SetTexCoord(...) self.texCoord = {...} end
function Widget:SetFont(...) self.font = {...} end
function Widget:SetJustifyHType(value) self.justify = value end
function Widget:SetColor(...) self.color = {...} end
function Widget:SetAlpha(value) self.alpha = value end
function Widget:SetScale(value) self.scale = value end
function Widget:SetFrameStrata(value) self.strata = value end
function Widget:SetFrameLevel(value) self.frameLevel=value end
function Widget:GetFrameLevel()
  if self.frameLevel~=nil then return self.frameLevel end
  local parent=self.parent and _G[self.parent]
  return parent and parent~=self and parent:GetFrameLevel()+((self.kind=="Texture" or self.kind=="FontString") and 0 or 1) or 0
end
function Widget:SetLayers(level,obj) self.layers={level,obj}; obj.layer=level end
function Widget:SetScripts(script, code) self.scripts[script] = code end
function Widget:EnableMouse(value) self.mouse = value end
function Widget:RegisterForClicks(...) self.clicks = {...} end
function Widget:RegisterEvent(event) self.events[event] = true end
function Widget:ClearFocus() self.focus = false end
function Widget:SetFocus() self.focus = true end
function Widget:HighlightText() self.highlighted = true end
function Widget:Show() self.visible = true end
function Widget:Hide()
  local changed = self.visible
  self.visible = false
  if changed then FixtureDispatch(self.name, "OnHide") end
end
function Widget:IsVisible()
  if not self.visible then return false end
  local parent = self.parent and _G[self.parent]
  return not parent or parent == self or parent:IsVisible()
end

CreateUIComponent = FixtureWidget
FixtureWidget("Frame", "UIParent"):SetSize(1920, 1080)
DEFAULT_CHAT_FRAME = {AddMessage = function(_, text) table.insert(fixtureMessages, text) end}
function GetTime() return fixtureNow end
function UnitExists(unit) return fixtureUnits[unit] end
function UnitName(unit) return fixtureUnits[unit] and ("Fixture " .. unit) end
function UnitGUID(unit) return fixtureUnits[unit] and ("fixture:" .. unit) end
function UnitBuff(unit, i)
  local buff = fixtureBuffs[unit] and fixtureBuffs[unit][i]
  if buff then return buff.name, buff.icon, buff.stacks or 1, buff.id end
end
function UnitBuffLeftTime(unit, i)
  local buff = fixtureBuffs[unit] and fixtureBuffs[unit][i]
  return buff and buff.left
end
UnitDebuff, UnitDebuffLeftTime = UnitBuff, UnitBuffLeftTime
function UnitHealth() return 75 end
function UnitMaxHealth() return 100 end
function GetNumSkill() return 0 end
function GetNumMacroIcons() return 78 end
function GetMacroIconInfo(i) return "Icons/Fixture" .. i end
function TEXT(key)
  if key == "Sys500934_name" then return "Fixture buff" end
  return key
end
