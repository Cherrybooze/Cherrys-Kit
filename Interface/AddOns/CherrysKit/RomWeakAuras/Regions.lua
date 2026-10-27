-- Regions.lua: what an aura draws. Ports the behaviour of WeakAuras' Icon, Aura Bar, Text and Texture
-- regions onto plain RoM textures and font strings (no cooldown spiral, masks or rotation needed).

local RWA = RWA
local W = RWA.W

local Regions = {}
RWA.Regions = Regions

local pools = {} -- [regionType] = { region, ... } frames cannot be deleted in RoM, so they are reused

local Base = {}
Base.__index = Base

---------------------------------------------------------------------------
-- Text placeholders, same letters as WeakAuras: %n name, %p progress, %t total, %s stacks,
-- plus %v value and %pct percent for resource triggers.
---------------------------------------------------------------------------

local function remaining(state, now)
  if state.progressType == "timed" and state.expirationTime then
    return math.max(0, state.expirationTime - now)
  end
end

local function placeholder(token, state, now)
  if token == "n" then
    return state.name or ""
  elseif token == "p" then
    local left = remaining(state, now)
    if left then
      return RWA.FormatTime(left)
    end
    return state.value and tostring(state.value) or ""
  elseif token == "t" then
    if state.progressType == "timed" then
      return RWA.FormatTime(state.duration)
    end
    return state.total and tostring(state.total) or ""
  elseif token == "s" then
    return (state.stacks and state.stacks > 1) and tostring(state.stacks) or ""
  elseif token == "v" then
    return state.value and tostring(state.value) or ""
  elseif token == "pct" then
    return state.percent and string.format("%d", math.floor(state.percent + 0.5)) or ""
  elseif token == "u" then
    return state.unit or ""
  elseif token == "e" then
    -- elapsed: time since state.startTime (in combat for the combat check), counting up
    if not state.startTime then
      return ""
    end
    local t = math.floor(math.max(0, now - state.startTime))
    return t < 60 and (t .. "s") or string.format("%d:%02d", math.floor(t / 60), t % 60)
  end
end

function Regions.FormatText(template, state, now)
  if not template or template == "" then
    return ""
  end
  return (string.gsub(template, "%%(%a+)", function(word)
    local value = placeholder(word, state, now)
    if value then
      return value
    end
    -- "%ps" is "%p" followed by the letter s.
    local first = string.sub(word, 1, 1)
    value = placeholder(first, state, now)
    if value then
      return value .. string.sub(word, 2)
    end
    return "%" .. word
  end))
end

function Regions.Progress(state, now)
  if not state then
    return 0
  end
  if state.progressType == "timed" then
    if not state.duration or state.duration <= 0 then
      return 1
    end
    return math.max(0, math.min(1, (state.expirationTime - now) / state.duration))
  end
  if state.total and state.total > 0 then
    return math.max(0, math.min(1, (state.value or 0) / state.total))
  end
  return 1
end

---------------------------------------------------------------------------
-- Shared region behaviour
---------------------------------------------------------------------------

function Base:Place(dx, dy)
  local d = self.data
  W.Place(self.frame, d.point or "CENTER", "UIParent", d.point or "CENTER", (d.x or 0) + (dx or 0), (d.y or 0) + (dy or 0))
end

function Base:Layout(data)
  self.data = data
  self.color = data.color
  W.SetSize(self.frame, data.width, data.height)
  self:Place()
  self:LayoutParts(data)
  self:LayoutElements(data)
end

function Base:SetState(state)
  self.state = state
end

function Base:SetAlpha(a)
  self.alpha = a
  RWA.Try(self.frame, "SetAlpha", a)
end

function Base:SetColor(c)
  self.color = c or self.data.color
  self:ApplyColor()
end

function Base:Show()
  if not self.shown then
    self.shown = true
    RWA.Try(self.frame, "Show")
  end
end

function Base:Hide()
  if self.shown ~= false then
    self.shown = false
    RWA.Try(self.frame, "Hide")
  end
end

function Base:Release()
  self:Hide()
  self.state = nil
  table.insert(pools[self.regionType], self)
end

local function colorOf(c)
  c = c or {}
  return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
end
Regions.ColorOf = colorOf

local function setText(fs, text)
  if fs.lastText ~= text then
    fs.lastText = text
    W.SetText(fs.obj, text)
  end
end

local function makeText(frame, size, justify)
  local fs = { obj = W.FontString(frame, "OVERLAY", size, "NORMAL") }
  W.SetJustify(fs.obj, justify or "CENTER")
  return fs
end

local function setTexSize(tex, w, h)
  if w < 0.5 or h < 0.5 then
    RWA.Try(tex, "Hide")
  else
    RWA.Try(tex, "Show")
    W.SetSize(tex, w, h)
  end
end

---------------------------------------------------------------------------
-- Extra elements (WeakAuras sub-elements): more icons or texts on one aura, each fed by the
-- shown state or by one trigger, placed on a side of the main region.
-- data.elements = { { type = "icon"|"text", from = 0 (shown) or trigger index,
--                     side = "LEFT"|"RIGHT"|"TOP"|"BOTTOM"|"CENTER", size, text, x, y }, ... }
---------------------------------------------------------------------------

local SIDES = {
  LEFT = { "RIGHT", "LEFT", -2, 0 },
  RIGHT = { "LEFT", "RIGHT", 2, 0 },
  TOP = { "BOTTOM", "TOP", 0, -2 },
  BOTTOM = { "TOP", "BOTTOM", 0, 2 },
  CENTER = { "CENTER", "CENTER", 0, 0 },
}
Regions.ELEMENT_SIDES = { "LEFT", "RIGHT", "TOP", "BOTTOM", "CENTER" }

function Base:LayoutElements(data)
  self.elems = self.elems or {}
  local list = data.elements or {}
  for i, e in ipairs(list) do
    local el = self.elems[i]
    if not el then
      el = { tex = W.Texture(self.frame, "OVERLAY"), fs = makeText(self.frame, 12, "CENTER") }
      self.elems[i] = el
    end
    local side = SIDES[e.side or "LEFT"] or SIDES.LEFT
    local size = tonumber(e.size) or data.height or 32
    local x, y = side[3] + (tonumber(e.x) or 0), side[4] + (tonumber(e.y) or 0)
    el.kind = e.type == "text" and "text" or "icon"
    if el.kind == "icon" then
      W.SetSize(el.tex, size, size)
      W.SetPoint(el.tex, side[1], self.frame, side[2], x, y)
      RWA.Try(el.tex, "Show")
      W.SetText(el.fs.obj, "")
      RWA.Try(el.fs.obj, "Hide")
    else
      W.SetFont(el.fs.obj, size, "OUTLINE", data.font)
      W.SetSize(el.fs.obj, 200, size + 4)
      W.SetJustify(el.fs.obj, side[1] == "RIGHT" and "RIGHT" or side[1] == "LEFT" and "LEFT" or "CENTER")
      W.SetPoint(el.fs.obj, side[1], self.frame, side[2], x, y)
      RWA.Try(el.fs.obj, "Show")
      RWA.Try(el.tex, "Hide")
    end
    el.lastIcon, el.fs.lastText = nil, nil
  end
  for i = #list + 1, #self.elems do
    local el = self.elems[i]
    el.kind = nil
    RWA.Try(el.tex, "Hide")
    W.SetText(el.fs.obj, "")
    RWA.Try(el.fs.obj, "Hide")
  end
end

-- states: every trigger's state (a.states); elements with from = 0 use the shown state.
function Base:UpdateElements(now, states)
  local list = self.data and self.data.elements
  if not list or not self.elems then
    return
  end
  for i, e in ipairs(list) do
    local el = self.elems[i]
    local from = tonumber(e.from) or 0
    local state = (from > 0 and states and states[from]) or self.state or {}
    if el and el.kind == "icon" then
      local icon = state.icon or (self.state and self.state.icon)
      if Regions.ElementIcon then -- KittyTracker.lua: extra icons show the next kitty picks
        local kitty = Regions.ElementIcon(self, i, state)
        if kitty ~= nil then
          icon = kitty or nil
        end
      end
      if icon ~= el.lastIcon then
        el.lastIcon = icon
        if icon then
          RWA.Try(el.tex, "SetTexture", icon)
        end
      end
      setTexSize(el.tex, icon and (tonumber(e.size) or self.data.height or 32) or 0, icon and (tonumber(e.size) or self.data.height or 32) or 0)
    elseif el and el.kind == "text" then
      setText(el.fs, Regions.FormatText(e.text or "%n", state, now))
    end
  end
end


---------------------------------------------------------------------------
-- Icon: icon texture, darkening overlay for elapsed time, centre text and stack text
---------------------------------------------------------------------------

local Icon = setmetatable({}, { __index = Base })
Icon.__index = Icon

function Icon:Build()
  local f = self.frame
  self.border = W.Texture(f, "BACKGROUND", "Square_FullWhite")
  self.icon = W.Texture(f, "ARTWORK")
  self.shade = W.Texture(f, "OVERLAY", "Square_FullWhite")
  self.text = makeText(f, 14, "CENTER")
  self.text2 = makeText(f, 12, "RIGHT")
end

function Icon:LayoutParts(d)
  local w, h = d.width, d.height
  W.SetSize(self.border, w, h)
  W.SetPoint(self.border, "CENTER", self.frame, "CENTER", 0, 0)
  W.SetColor(self.border, 0, 0, 0, 1)
  W.SetSize(self.icon, w - 2, h - 2)
  W.SetPoint(self.icon, "CENTER", self.frame, "CENTER", 0, 0)
  RWA.Try(self.icon, "SetTexCoord", 0.07, 0.93, 0.07, 0.93)
  W.SetPoint(self.shade, "TOP", self.frame, "TOP", 0, 1)
  W.SetColor(self.shade, 0, 0, 0, 0.6)
  for _, fs in ipairs({ self.text, self.text2 }) do
    W.SetFont(fs.obj, fs == self.text and d.fontSize or math.max(9, d.fontSize - 2), "NORMAL", d.font)
    W.SetSize(fs.obj, w, d.fontSize + 6)
    fs.lastText = nil
  end
  W.SetPoint(self.text.obj, "CENTER", self.frame, "CENTER", 0, 0)
  W.SetPoint(self.text2.obj, "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -2, -1)
  self.lastIcon = nil
  self:ApplyColor()
end

function Icon:ApplyColor()
  local r, g, b = colorOf(self.color)
  W.SetColor(self.icon, r, g, b)
end

function Icon:Update(now)
  local d, state = self.data, self.state or {}
  if state.icon and d.previewIcon ~= state.icon then
    d.previewIcon = state.icon -- remembered for the preview in the /rwa list
  end
  local iconPath = (d.icon and d.icon ~= "") and d.icon or state.icon or W.TexturePath("exclamation-mark")
  if iconPath ~= self.lastIcon then
    self.lastIcon = iconPath
    RWA.Try(self.icon, "SetTexture", iconPath)
  end
  local shade = 0
  if state.progressType == "timed" and state.duration and state.duration > 0 then
    shade = 1 - Regions.Progress(state, now)
  end
  setTexSize(self.shade, d.width - 2, (d.height - 2) * shade)
  setText(self.text, Regions.FormatText(d.text, state, now))
  setText(self.text2, Regions.FormatText(d.text2, state, now))
end

---------------------------------------------------------------------------
-- Aura bar: background, fill that shrinks with time (or tracks value), optional icon, two texts
---------------------------------------------------------------------------

local Bar = setmetatable({}, { __index = Base })
Bar.__index = Bar

function Bar:Build()
  local f = self.frame
  self.bg = W.Texture(f, "BACKGROUND", "Square_FullWhite")
  self.fill = W.Texture(f, "ARTWORK")
  self.icon = W.Texture(f, "ARTWORK")
  self.text = makeText(f, 12, "LEFT")
  self.text2 = makeText(f, 12, "RIGHT")
end

function Bar:LayoutParts(d)
  local w, h = d.width, d.height
  local iconW = d.showIcon and h or 0
  self.barX, self.barW = iconW, w - iconW
  W.SetSize(self.bg, w, h)
  W.SetPoint(self.bg, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
  W.SetColor(self.bg, colorOf(d.bgColor))
  W.SetTexture(self.fill, d.texture)
  W.SetPoint(self.fill, "TOPLEFT", self.frame, "TOPLEFT", iconW, 0)
  if d.showIcon then
    RWA.Try(self.icon, "Show")
    W.SetSize(self.icon, h, h)
    W.SetPoint(self.icon, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    RWA.Try(self.icon, "SetTexCoord", 0.07, 0.93, 0.07, 0.93)
  else
    RWA.Try(self.icon, "Hide")
  end
  W.SetFont(self.text.obj, d.fontSize, "NORMAL", d.font)
  W.SetFont(self.text2.obj, d.fontSize, "NORMAL", d.font)
  W.SetSize(self.text.obj, self.barW * 0.7 - 6, h)
  W.SetSize(self.text2.obj, self.barW * 0.3 - 4, h)
  W.SetPoint(self.text.obj, "LEFT", self.frame, "LEFT", iconW + 4, 0)
  W.SetPoint(self.text2.obj, "RIGHT", self.frame, "RIGHT", -4, 0)
  self.text.lastText, self.text2.lastText, self.lastIcon, self.lastFill = nil, nil, nil, nil
  self:ApplyColor()
end

function Bar:ApplyColor()
  W.SetColor(self.fill, colorOf(self.color))
end

function Bar:Update(now)
  local d, state = self.data, self.state or {}
  local width = math.floor(self.barW * Regions.Progress(state, now) + 0.5)
  if width ~= self.lastFill then
    self.lastFill = width
    setTexSize(self.fill, width, d.height)
  end
  if d.showIcon then
    if state.icon and d.previewIcon ~= state.icon then
      d.previewIcon = state.icon -- remembered for the preview in the /rwa list
    end
    local iconPath = (d.icon and d.icon ~= "") and d.icon or state.icon or W.TexturePath("exclamation-mark")
    if iconPath ~= self.lastIcon then
      self.lastIcon = iconPath
      RWA.Try(self.icon, "SetTexture", iconPath)
    end
  end
  setText(self.text, Regions.FormatText(d.text, state, now))
  setText(self.text2, Regions.FormatText(d.text2, state, now))
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------

local Text = setmetatable({}, { __index = Base })
Text.__index = Text

function Text:Build()
  self.text = makeText(self.frame, 18, "CENTER")
end

function Text:LayoutParts(d)
  W.SetFont(self.text.obj, d.fontSize, "THICK", d.font)
  W.SetSize(self.text.obj, d.width, d.height)
  W.SetPoint(self.text.obj, "CENTER", self.frame, "CENTER", 0, 0)
  self.text.lastText = nil
  self:ApplyColor()
end

function Text:ApplyColor()
  W.SetColor(self.text.obj, colorOf(self.color))
end

function Text:Update(now)
  setText(self.text, Regions.FormatText(self.data.text, self.state or {}, now))
end

---------------------------------------------------------------------------
-- Texture: any image from Media/Textures (or a full game path), tinted, optionally additive
---------------------------------------------------------------------------

local Tex = setmetatable({}, { __index = Base })
Tex.__index = Tex

function Tex:Build()
  self.tex = W.Texture(self.frame, "ARTWORK")
end

function Tex:LayoutParts(d)
  W.SetTexture(self.tex, d.texture)
  W.SetSize(self.tex, d.width, d.height)
  W.SetPoint(self.tex, "CENTER", self.frame, "CENTER", 0, 0)
  RWA.Try(self.tex, "SetAlphaMode", d.blend == "ADD" and "ADD" or "BLEND")
  self:ApplyColor()
end

function Tex:ApplyColor()
  local r, g, b, a = colorOf(self.color)
  W.SetColor(self.tex, r, g, b)
  RWA.Try(self.tex, "SetAlpha", a)
end

function Tex:Update()
end

---------------------------------------------------------------------------

Regions.types = { icon = Icon, aurabar = Bar, text = Text, texture = Tex }
Regions.labels = { icon = "Icon", aurabar = "Bar", text = "Text", texture = "Texture" }
Regions.order = { "icon", "aurabar", "text", "texture" }

function Regions.Acquire(data)
  local regionType = Regions.types[data.regionType] and data.regionType or "icon"
  pools[regionType] = pools[regionType] or {}
  local region = table.remove(pools[regionType])
  if not region then
    region = setmetatable({ regionType = regionType }, Regions.types[regionType])
    region.frame = W.RegionFrame()
    region:Build()
  end
  region:Layout(data)
  region:SetAlpha(data.alpha or 1)
  region:Hide()
  return region
end
