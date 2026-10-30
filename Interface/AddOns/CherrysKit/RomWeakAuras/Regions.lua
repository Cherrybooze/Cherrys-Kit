-- Regions.lua: what an aura draws. Ports the behaviour of WeakAuras' Icon, Aura Bar, Text and Texture
-- regions onto plain RoM textures and font strings (no cooldown spiral, masks or rotation needed).

local RWA = RWA
local W = RWA.W

-- Reload UI keeps native widgets and RWA, while the module-local pools are rebuilt.
-- Draft-only extras must not reappear when their XML parent is reused by a saved aura.
-- Keep only a cleanup registry across loads, never active rendering state or old pools.
local function cleanOldChild(region)
  if type(region) ~= "table" then return end
  if type(region.Hide) == "function" then pcall(region.Hide, region) end
  pcall(RWA.Try, region.frame, "Hide")
  -- Also clear individual components if an older/custom Hide handler failed midway.
  for _, name in ipairs({ "text", "text2" }) do
    local fs = region[name]
    if type(fs) == "table" and fs.obj then
      pcall(RWA.Try, fs.obj, "SetText", "")
      pcall(RWA.Try, fs.obj, "Hide")
      fs.lastText = nil
    end
  end
  for _, name in ipairs({ "icon", "shade", "fill", "bg", "tex" }) do
    pcall(RWA.Try, region[name], "Hide")
  end
  for _, texture in ipairs(region.borderParts or {}) do pcall(RWA.Try, texture, "Hide") end
  region.state, region.elementActive, region.elementPhase = nil, nil, nil
end
if type(RWA.regionChildren) == "table" then
  for _, region in pairs(RWA.regionChildren) do pcall(cleanOldChild, region) end
end
local childRegistry = {}
RWA.regionChildren = childRegistry

local Regions = {}
RWA.Regions = Regions

local pools = {} -- [regionType] = { region, ... } frames cannot be deleted in RoM, so they are reused
local CORE_TYPES = { icon = true, aurabar = true, text = true, texture = true }
local SIDES = {
  LEFT = { "RIGHT", "LEFT", -2, 0 },
  RIGHT = { "LEFT", "RIGHT", 2, 0 },
  TOP = { "BOTTOM", "TOP", 0, -2 },
  BOTTOM = { "TOP", "BOTTOM", 0, 2 },
  CENTER = { "CENTER", "CENTER", 0, 0 },
}
Regions.ELEMENT_SIDES = { "LEFT", "RIGHT", "TOP", "BOTTOM", "CENTER" }
Regions.borderStyles = { "none", "thin", "thick", "double", "corners" }
Regions.borderLabels = { none = "None", thin = "Thin", thick = "Thick", double = "Double", corners = "Corners" }
local acquireElement

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
  -- Other files add their own codes here (Recent.lua: %rate, %fight, %ft, %avg);
  -- a code returns nil when the state has nothing for it.
  local code = Regions.CODES[token]
  if code then return code(state, now) end
end

Regions.CODES = {}

-- Visible texts are formatted many times a second, so each template is split once
-- into literal text and %tokens; formatting then needs no gsub or closure.
local compiledTemplates, compiledCount, formatParts = {}, 0, {}
local function compileTemplate(template)
  local parts, pos = {}, 1
  while true do
    local first, last, word = string.find(template, "%%(%a+)", pos)
    if not first then break end
    if first > pos then parts[#parts + 1] = string.sub(template, pos, first - 1) end
    -- "%ps" is "%p" followed by the letter s.
    parts[#parts + 1] = { word, string.sub(word, 1, 1), string.sub(word, 2) }
    pos = last + 1
  end
  if pos <= string.len(template) then parts[#parts + 1] = string.sub(template, pos) end
  return parts
end

function Regions.FormatText(template, state, now)
  if template=="%v / %t" and state.healthText then return state.healthText end
  if not template or template == "" then
    return ""
  end
  if type(template) ~= "string" then template = tostring(template) end
  local parts = compiledTemplates[template]
  if not parts then
    if compiledCount >= 200 then compiledTemplates, compiledCount = {}, 0 end
    parts = compileTemplate(template)
    compiledTemplates[template], compiledCount = parts, compiledCount + 1
  end
  local count = #parts
  if count == 1 and type(parts[1]) == "string" then return parts[1] end
  for i = 1, count do
    local part = parts[i]
    if type(part) == "string" then
      formatParts[i] = part
    else
      local value = placeholder(part[1], state, now)
      if not value then
        value = placeholder(part[2], state, now)
        value = value and (value .. part[3]) or ("%" .. part[1])
      end
      formatParts[i] = value
    end
  end
  return table.concat(formatParts, "", 1, count)
end

function Regions.Progress(state, now)
  if not state then
    return 0
  end
  if state._placement and state._placementProgress then return state._placementProgress end
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

-- RoM multiplies anchor offsets by the anchored widget's own real scale.
-- Divide by its local scale so scaling/growing does not move the chosen
-- position; children still inherit their parent's transform exactly once.
function Regions.PositionScale(region)
  local scale=tonumber(region.conditionScale or region.conditionBaseScale) or 1
  return scale>0 and scale or 1
end

function Base:Place(dx, dy)
  local d = self.data
  self.placeDX,self.placeDY=dx or 0,dy or 0
  local scale=Regions.PositionScale(self)
  if self.owner and d.parentOutputId then
    local childDy=dy or 0
    if RWA_DB and RWA_DB.settings and RWA_DB.settings.yUp then childDy=-childDy end
    W.Place(self.frame, d.point or "CENTER", self.owner.frame, d.point or "CENTER",
      ((tonumber(d.offsetX) or 0) + (dx or 0))/scale, ((tonumber(d.offsetY) or 0) + childDy)/scale)
    return
  end
  if self.owner then
    local side = SIDES[d.side or "LEFT"] or SIDES.LEFT
    W.SetPoint(self.frame, side[1], self.owner.frame, side[2],
      (side[3] + (tonumber(d.x) or 0) + (dx or 0))/scale, (side[4] + (tonumber(d.y) or 0) + (dy or 0))/scale)
    return
  end
  W.Place(self.frame, d.point or "CENTER", "UIParent", d.point or "CENTER", ((d.x or 0) + (dx or 0))/scale, ((d.y or 0) + (dy or 0))/scale)
end

function Base:Layout(data)
  self.data = data
  self.color = data.color
  if data._element then self.elementActive, self.elementPhase = nil, nil end
  W.SetSize(self.frame, data.width, data.height)
  self:Place()
  self.elementDy = nil
  self:LayoutParts(data)
  self:LayoutBorder(data)
  if not self.isElement then self:LayoutElements(data) end
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
    for _, name in ipairs({ "text", "text2" }) do
      local fs = self[name]
      if fs and fs.obj then W.SetShown(fs.obj, true) end
    end
  end
end

function Base:Hide()
  if W.activeTooltipOwner == self.frame then
    W.activeTooltipOwner = nil
    RWA.Try(GameTooltip, "Hide")
  end
  if self.shown ~= false then
    self.shown = false
    RWA.Try(self.frame, "Hide")
    for _, name in ipairs({ "text", "text2" }) do
      local fs = self[name]
      if fs and fs.obj then
        W.SetShown(fs.obj, false)
        fs.lastText = nil
      end
    end
  end
  for _, el in ipairs(self.elems or {}) do el.region:Hide() end
end

function Base:Release()
  if self.released then return end
  self:Hide()
  self.released = true
  for _, el in ipairs(self.elems or {}) do el.region:Release() end
  self.elems = nil
  self.state, self.elementActive, self.elementPhase = nil, nil, nil
  self.elementIndex, self.elementDy = nil, nil
  self.lastIcon, self.lastFill = nil, nil
  for _, name in ipairs({ "text", "text2" }) do
    local fs = self[name]
    if fs and fs.obj then
      W.SetText(fs.obj, "")
      W.SetShown(fs.obj, false)
      fs.lastText = nil
    end
  end
  if self.icon then W.SetTexture(self.icon, nil) end
  local pool
  if self.owner then
    self.owner.elementPools = self.owner.elementPools or {}
    self.owner.elementPools[self.regionType] = self.owner.elementPools[self.regionType] or {}
    pool = self.owner.elementPools[self.regionType]
  else
    pools[self.regionType] = pools[self.regionType] or {}
    pool = pools[self.regionType]
  end
  self.data = nil
  table.insert(pool, self)
end

local function colorOf(c)
  c = c or {}
  return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
end
Regions.ColorOf = colorOf

local function positive(value, fallback)
  local n = tonumber(value)
  return n and n > 0 and n < math.huge and n or fallback
end

local function borderMetrics(data, kind)
  local style = data.borderStyle
  if style == nil then style = kind == "icon" and not data._element and "thin" or "none" end
  if not Regions.borderLabels[style] then style = "none" end
  local thickness = positive(data.borderSize, style == "thick" and 3 or style == "corners" and 2 or 1)
  thickness = math.min(thickness, math.max(1, math.min(data.width, data.height) / 4))
  local inset = style == "none" and 0 or style == "double" and thickness * 3 or thickness
  inset = math.min(inset, math.max(0, math.min(data.width, data.height) / 2 - 0.5))
  return style, thickness, inset
end

-- Borders use actual rectangular textures; no unsupported native backdrop/glow APIs.
-- Segments are reused and surplus segments are hidden when a style changes.
function Base:LayoutBorder(data)
  local style, thickness, inset = borderMetrics(data, self.regionType)
  self.borderStyle, self.borderInset = style, inset
  self.borderParts = self.borderParts or {}
  local count = 0
  local function segment(x, y, width, height)
    if width <= 0 or height <= 0 then return end
    count = count + 1
    local tex = self.borderParts[count]
    if not tex then
      tex = W.Texture(self.frame, "OVERLAY", "Square_FullWhite")
      self.borderParts[count] = tex
    end
    W.SetSize(tex, width, height)
    W.SetPoint(tex, "TOPLEFT", self.frame, "TOPLEFT", x, y)
    W.SetColor(tex, colorOf(data.borderColor or { 0, 0, 0, 1 }))
    RWA.Try(tex, "Show")
  end
  local w, h = data.width, data.height
  local function ring(offset)
    local width, height = w - offset * 2, h - offset * 2
    if width <= 0 or height <= 0 then return end
    local t = math.min(thickness, width / 2, height / 2)
    segment(offset, offset, width, t)
    segment(offset, h - offset - t, width, t)
    segment(offset, offset + t, t, height - t * 2)
    segment(w - offset - t, offset + t, t, height - t * 2)
  end
  if style == "thin" or style == "thick" then
    ring(0)
  elseif style == "double" then
    ring(0)
    ring(thickness * 2)
  elseif style == "corners" then
    local t = math.min(thickness, w / 2, h / 2)
    local arm = math.min(math.min(w, h) / 2, math.max(t * 3, math.min(w, h) / 4))
    segment(0, 0, arm, t)
    segment(0, t, t, arm - t)
    segment(w - arm, 0, arm, t)
    segment(w - t, t, t, arm - t)
    segment(0, h - t, arm, t)
    segment(0, h - arm, t, arm - t)
    segment(w - arm, h - t, arm, t)
    segment(w - t, h - arm, t, arm - t)
  end
  for i = count + 1, #self.borderParts do RWA.Try(self.borderParts[i], "Hide") end
  self.borderCount = count
end

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
-- Extra displays use the same rendering classes as the main display on independent,
-- non-interactive child frames. Only mains use the draggable XML region-frame pool.
-- from = 0 follows the shown main state; a positive index uses that trigger's state.
---------------------------------------------------------------------------

-- A detached rendering model, also used by the editor's selected-display preview.
-- Keep old icon/text size semantics; new width/height/fontSize fields take priority.
function Regions.ElementData(parentData, element)
  parentData, element = parentData or {}, element or {}
  local d = RWA.CopyTable(element)
  local kind = CORE_TYPES[element.type] and element.type or "icon"
  d.regionType, d._element = kind, true
  d.elements, d.triggers, d.conditions, d.load = nil, nil, nil, nil
  local size = positive(element.size, positive(parentData.height, 32))
  if kind == "text" then
    d.fontSize = positive(element.fontSize, size)
    d.width, d.height = positive(element.width, 200), positive(element.height, d.fontSize + 4)
    d.text = element.text == nil and "%n" or element.text
  elseif kind == "aurabar" then
    d.width, d.height = positive(element.width, 220), positive(element.height, positive(element.size, 22))
    d.fontSize = positive(element.fontSize, 12)
    d.text = element.text == nil and "%n" or element.text
    d.text2 = element.text2 == nil and "%p" or element.text2
    d.showIcon = element.showIcon ~= false
  else
    local defaultSize = kind == "texture" and positive(element.size, 64) or size
    d.width, d.height = positive(element.width, defaultSize), positive(element.height, defaultSize)
    d.fontSize = positive(element.fontSize, 14)
    d.text = element.text or ""
  end
  d.text2 = d.text2 or ""
  d.font = element.font or parentData.font
  d.color = d.color or { 1, 1, 1, 1 }
  d.bgColor = d.bgColor or { 0, 0, 0, 0.5 }
  d.alpha = tonumber(d.alpha) or 1
  if d.alpha ~= d.alpha then d.alpha = 1 end
  d.alpha = math.max(0, math.min(1, d.alpha))
  d.texture = d.texture or (kind == "texture" and "Circle_White" or "Square_FullWhite")
  d.borderStyle = d.borderStyle or "none"
  d.animation = type(d.animation) == "table" and d.animation or {}
  RWA.MergeDefaults(d.animation, { start = "none", main = "none", finish = "none" })
  return d
end

-- Drawn many times a second, so no table is made here: a missing state is this shared
-- empty one (only read), and a Kitty icon element refills its own copy of the state.
local NO_STATE = {}
function Regions.ElementState(owner, index, states)
  local e = owner.data and owner.data.elements and owner.data.elements[index]
  if not e then return NO_STATE, false end
  local from = tonumber(e.from) or 0
  local state
  if e.sourceId then state = states and states[e.sourceId]
  elseif from > 0 then state = states and states[from] else state = owner.state end
  local active = type(state) == "table" and state.show ~= false
  if type(state) ~= "table" then state = NO_STATE end
  if (e.type == nil or e.type == "icon" or e.type == "aurabar") and not (e.icon and e.icon ~= "")
    and Regions.ElementIcon then
    local icon = Regions.ElementIcon(owner, index, state)
    if icon ~= nil then
      local copies = owner.elementStates
      if not copies then copies = {}; owner.elementStates = copies end
      local copy = copies[index]
      if copy then
        for key in pairs(copy) do copy[key] = nil end
      else
        copy = {}; copies[index] = copy
      end
      for key, value in pairs(state) do copy[key] = value end
      state = copy
      state.icon, state._elementNoIcon = icon or nil, icon == false
    end
  end
  return state, active
end

function Base:LayoutElements(data)
  self.elems = self.elems or {}
  local list = data.elements or {}
  for i, e in ipairs(list) do
    local el = self.elems[i]
    local resolved = Regions.ElementData(data, e)
    if el and el.kind ~= resolved.regionType then
      el.region:Release()
      el = nil
    end
    if not el then
      el = { kind = resolved.regionType, region = acquireElement(self, resolved, i) }
      self.elems[i] = el
    else
      el.region:Layout(resolved)
      el.region:SetAlpha(resolved.alpha)
      el.region:Hide()
    end
    el.region.state, el.region.elementActive, el.region.elementPhase = nil, nil, nil
    el.tex, el.fs = el.region.icon or el.region.tex, el.region.text
  end
  for i = #self.elems, #list + 1, -1 do
    self.elems[i].region:Release()
    self.elems[i] = nil
  end
end

local NO_ANIMATION = {}
local function animateElement(region, now, active, baseAlpha)
  local d, animation = region.data, region.data.animation or NO_ANIMATION
  if active ~= region.elementActive then
    local wasActive = region.elementActive
    region.elementActive = active
    region.elementPhase = (active or wasActive) and { kind = active and "start" or "finish", t0 = now } or nil
  end
  local phase, alpha, dy = region.elementPhase, baseAlpha or d.alpha or 1, 0
  if phase and (phase.kind == "start" or phase.kind == "finish") then
    local p = math.min(1, math.max(0, (now - phase.t0) / 0.25))
    local kind = phase.kind
    local preset = animation[kind] or "none"
    if preset == "none" or p >= 1 then
      region.elementPhase = active and { kind = "main", t0 = now } or nil
    elseif preset == "fade" then
      alpha = alpha * (kind == "start" and p or 1 - p)
    elseif preset == "slide" then
      alpha = alpha * (kind == "start" and p or 1 - p)
      dy = kind == "start" and 30 * (1 - p) or -30 * p
    end
  end
  phase = region.elementPhase
  if phase and phase.kind == "main" then
    local t = now - phase.t0
    if animation.main == "pulse" then
      alpha = alpha * (0.55 + 0.45 * math.cos(t * math.pi * 2))
    elseif animation.main == "flash" then
      alpha = alpha * (math.floor(t * 2) % 2 == 0 and 1 or 0.25)
    elseif animation.main == "bounce" then
      dy = -math.abs(math.sin(t * math.pi)) * 8
    end
  end
  if region.elementDy ~= dy then
    region.elementDy = dy
    region:Place(0, dy)
  end
  if region.alpha ~= alpha then region:SetAlpha(alpha) end
  if active or region.elementPhase then region:Show() else region:Hide() end
end
-- Selected-display previews may use this with their own Place implementation and
-- condition-adjusted alpha, without applying main-display color/alpha defaults.
Regions.AnimateElement = animateElement

function Base:UpdateElements(now, states)
  local list = self.data and self.data.elements
  if not list or not self.elems then
    return
  end
  for i, e in ipairs(list) do
    local el = self.elems[i]
    if el then
      local region = el.region
      local state, active = Regions.ElementState(self, i, states)
      if active or not region.elementActive and not region.elementPhase then region:SetState(state) end
      region:Update(now)
      active = active and region.contentShown ~= false and region.data.enabled ~= false
      animateElement(region, now, active)
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
  self.icon = W.Texture(f, "ARTWORK")
  self.shade = W.Texture(f, "OVERLAY", "Square_FullWhite")
  self.text = makeText(f, 14, "CENTER")
  self.text2 = makeText(f, 12, "RIGHT")
end

function Icon:LayoutParts(d)
  local w, h = d.width, d.height
  local _, _, inset = borderMetrics(d, self.regionType)
  self.contentW, self.contentH = math.max(0, w - inset * 2), math.max(0, h - inset * 2)
  W.SetSize(self.icon, self.contentW, self.contentH)
  W.SetPoint(self.icon, "CENTER", self.frame, "CENTER", 0, 0)
  RWA.Try(self.icon, "SetTexCoord", 0.07, 0.93, 0.07, 0.93)
  W.SetPoint(self.shade, "TOP", self.frame, "TOP", 0, inset)
  W.SetColor(self.shade, 0, 0, 0, 0.6)
  for _, fs in ipairs({ self.text, self.text2 }) do
    W.SetFont(fs.obj, fs == self.text and d.fontSize or math.max(9, d.fontSize - 2), "NORMAL", d.font)
    W.SetColor(fs.obj, colorOf(d.textColor))
    W.SetSize(fs.obj, w, d.fontSize + 6)
    fs.lastText = nil
  end
  W.SetPoint(self.text.obj, "CENTER", self.frame, "CENTER", 0, 0)
  W.SetPoint(self.text2.obj, "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -2, -1)
  self.lastIcon = nil
  self:ApplyColor()
end

function Icon:ApplyColor()
  W.SetColor(self.icon, colorOf(self.color))
end

function Icon:Update(now)
  local d, state = self.data, self.state or {}
  local extra = self.isElement or d._element
  if not extra and state.icon and d.previewIcon ~= state.icon then
    d.previewIcon = state.icon -- remembered for the preview in the /rwa list
  end
  local explicit = d.icon and d.icon ~= "" and W.TexturePath(d.icon) or nil
  local iconPath = explicit or state.icon
  if not explicit and tonumber(d.kittyPick) and type(state.kittyIcons)=="table" then
    iconPath = state.kittyIcons[tonumber(d.kittyPick)]
  end
  if not extra and not (tonumber(d.kittyPick) and state.kittyIcons) then
    iconPath = iconPath or d.previewIcon or W.TexturePath("exclamation-mark")
  end
  if state._elementNoIcon and not explicit then iconPath = nil end
  if iconPath ~= self.lastIcon then
    self.lastIcon = iconPath
    RWA.Try(self.icon, "SetTexture", iconPath)
  end
  self.contentShown = not extra or iconPath ~= nil
  setTexSize(self.icon, iconPath and self.contentW or 0, iconPath and self.contentH or 0)
  local shade = 0
  if state.progressType == "timed" and state.duration and state.duration > 0 then
    shade = 1 - Regions.Progress(state, now)
  end
  setTexSize(self.shade, iconPath and self.contentW or 0, iconPath and self.contentH * shade or 0)
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

-- Target health with the stock "%v / %t" text: the HP number sits at the bar's right
-- end and the percentage centred just above the bar (a third text, made when needed).
local function layoutBarText(region,data,health)
  local w,h=region.barW,data.height
  W.SetSize(region.text.obj,math.max(1,w*(health and .62 or .7)-6),h)
  W.SetSize(region.text2.obj,math.max(1,w*(health and .38 or .3)-4),h)
  W.SetPoint(region.text.obj,"LEFT",region.frame,"LEFT",region.barX+4,0)
  W.SetPoint(region.text2.obj,"RIGHT",region.frame,"RIGHT",-4,0)
  if health and not region.text3 then region.text3=makeText(region.frame,12,"CENTER") end
  local above=region.text3
  if above then
    above.lastText=nil
    if health then
      W.SetFont(above.obj,data.fontSize,"NORMAL",data.font)
      W.SetColor(above.obj,colorOf(data.textColor))
      W.SetSize(above.obj,math.max(1,w),(tonumber(data.fontSize) or 12)+4)
      W.SetPoint(above.obj,"BOTTOM",region.frame,"TOP",region.barX/2,-2)
      RWA.Try(above.obj,"Show")
    else
      W.SetText(above.obj,"")
      RWA.Try(above.obj,"Hide")
    end
  end
  region.healthTextLayout=health
end

function Bar:LayoutParts(d)
  local w, h = d.width, d.height
  local iconW = d.showIcon and math.min(w, h) or 0
  self.barX, self.barW = iconW, math.max(0, w - iconW)
  W.SetSize(self.bg, w, h)
  W.SetPoint(self.bg, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
  W.SetColor(self.bg, colorOf(d.bgColor))
  W.SetTexture(self.fill, d.texture)
  W.SetPoint(self.fill, "TOPLEFT", self.frame, "TOPLEFT", iconW, 0)
  if d.showIcon then
    RWA.Try(self.icon, "Show")
    W.SetSize(self.icon, iconW, h)
    W.SetPoint(self.icon, "TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    RWA.Try(self.icon, "SetTexCoord", 0.07, 0.93, 0.07, 0.93)
  else
    RWA.Try(self.icon, "Hide")
  end
  W.SetFont(self.text.obj, d.fontSize, "NORMAL", d.font)
  W.SetFont(self.text2.obj, d.fontSize, "NORMAL", d.font)
  W.SetJustify(self.text.obj,"LEFT"); W.SetJustify(self.text2.obj,"RIGHT")
  W.SetColor(self.text.obj, colorOf(d.textColor))
  W.SetColor(self.text2.obj, colorOf(d.textColor))
  layoutBarText(self,d,false)
  self.text.lastText, self.text2.lastText, self.lastIcon, self.lastFill = nil, nil, nil, nil
  if RWA.ResourceDisplays then
    if d.resource or self.regionType=="soulpoints" then RWA.ResourceDisplays.LayoutBar(self,d)
    else RWA.ResourceDisplays.ClearBar(self) end
  end
  self:ApplyColor()
end

function Bar:LayoutBorder(d)
  if d.resource or self.regionType=="soulpoints" then
    for _,edge in ipairs(self.borderParts or {}) do W.SetShown(edge,false) end
    self.borderCount=0
  else Base.LayoutBorder(self,d) end
end

function Bar:ApplyColor()
  W.SetColor(self.fill, colorOf(self.color))
end

function Bar:Update(now)
  local d, state = self.data, self.state or {}
  local resource=d.resource and RWA.ResourceDisplays
  if resource then
    if not resource.NeedsUpdate(self,state) then return end
    if not resource.BeginBarUpdate(self,state) then resource.Updated(self);return end
  end
  local width = math.floor(self.barW * Regions.Progress(state, now) + 0.5)
  if width ~= self.lastFill then
    self.lastFill = width
    if resource then resource.SetFill(self,width) else setTexSize(self.fill, width, d.height) end
  end
  if d.showIcon and not resource then
    local extra = self.isElement or d._element
    if not extra and state.icon and d.previewIcon ~= state.icon then
      d.previewIcon = state.icon -- remembered for the preview in the /rwa list
    end
    local explicit = d.icon and d.icon ~= "" and W.TexturePath(d.icon) or nil
    local iconPath = explicit or state.icon
    if not explicit and tonumber(d.kittyPick) and type(state.kittyIcons)=="table" then
      iconPath = state.kittyIcons[tonumber(d.kittyPick)]
    end
    if not extra and not (tonumber(d.kittyPick) and state.kittyIcons) then
      iconPath = iconPath or d.previewIcon or W.TexturePath("exclamation-mark")
    end
    if state._elementNoIcon and not explicit then iconPath = nil end
    if iconPath ~= self.lastIcon then
      self.lastIcon = iconPath
      RWA.Try(self.icon, "SetTexture", iconPath)
    end
    setTexSize(self.icon, iconPath and self.barX or 0, iconPath and d.height or 0)
  end
  if resource then resource.UpdateBarText(self,state,now);resource.Updated(self)
  else
    local health=state.healthText~=nil and d.text2=="%v / %t"
    if health~=self.healthTextLayout then layoutBarText(self,d,health) end
    setText(self.text, Regions.FormatText(d.text, state, now))
    if health then
      setText(self.text2, state.healthNumber)
      setText(self.text3, state.healthPercent)
    else
      setText(self.text2, Regions.FormatText(d.text2, state, now))
    end
  end
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
  local extra = self.isElement or d._element
  W.SetFont(self.text.obj, d.fontSize, extra and "OUTLINE" or "THICK", d.font)
  W.SetJustify(self.text.obj, d.justify or (extra and d.side == "LEFT" and "RIGHT"
    or extra and d.side == "RIGHT" and "LEFT" or "CENTER"))
  W.SetSize(self.text.obj, d.width, d.height)
  W.SetPoint(self.text.obj, "CENTER", self.frame, "CENTER", 0, 0)
  self.text.lastText = nil
  self:ApplyColor()
end

function Text:ApplyColor()
  W.SetColor(self.text.obj, colorOf(self.color))
end

function Text:Update(now)
  local state=self.state or {}
  setText(self.text, state._placement and state._placementText or Regions.FormatText(self.data.text, state, now))
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

-- A separate pool per owner avoids reparenting native widgets and never claims an
-- XML main-region frame for an extra display. Removed/type-changed children return here.
acquireElement = function(owner, data, index)
  owner.elementPools = owner.elementPools or {}
  local pool = owner.elementPools[data.regionType]
  local region = pool and table.remove(pool)
  if not region then
    region = setmetatable({ regionType = data.regionType, isElement = true, owner = owner }, Regions.types[data.regionType])
    region.frame = W.ChildRegionFrame(owner.frame)
    W.EnableMouse(region.frame, false)
    childRegistry[#childRegistry + 1] = region
    region:Build()
  end
  region.released, region.owner, region.elementIndex = false, owner, index
  region.contentShown = nil
  region:Layout(data)
  region:SetAlpha(data.alpha)
  region:Hide()
  return region
end

function Regions.AcquireChild(owner, data)
  return acquireElement(owner, data)
end

function Regions.Acquire(data)
  local regionType = Regions.types[data.regionType] and data.regionType or "icon"
  pools[regionType] = pools[regionType] or {}
  local region = table.remove(pools[regionType])
  if not region then
    region = setmetatable({ regionType = regionType }, Regions.types[regionType])
    region.frame = W.RegionFrame()
    region:Build()
  end
  region.released, region.contentShown = false, nil
  region:Layout(data)
  region:SetAlpha(data.alpha or 1)
  region:Hide()
  return region
end
