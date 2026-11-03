-- The RoM client's layout and mouse rules, for tests that need real geometry. Ported from the client
-- source (cherrybooze/oneforall, SourceCodeVS2019/Client/Ispania_English/ui/core and ui/xml):
--
--   uilayout.cpp  SetAnchorSize, ResetSize, ResetAnchors, SetPos, SetSize, SetAnchor, ClearAllAnchors
--   uiframe.cpp   InsertChild, AdjustFrameLevel, GetFrameAtPoint, ContainsPoint, HandleMouse
--   ui.cpp        LoadXmlLayout (size, then anchors, a TOPLEFT anchor to the parent when none),
--                 LoadXmlFrame (strata, level, enableMouse), Update (hit test, capture, mouse up)
--
-- What it adds to the UMM fixture widgets (tests/umm_fixtures.lua), for the frames under one root:
--   * a frame from XML has an anchor size: its <Size>, or 0 x 0 without one. Whenever something it is
--     anchored to moves or is re-anchored, a 0 x 0 frame takes its parent's size again (ResetSize),
--     undoing SetWidth/SetHeight. CreateUIComponent objects have -1 x -1 and keep their size.
--   * a frame's children are kept in the client's order: by strata, then frame level, then the order
--     they were made in; a mouse down lifts the frame, and every parent up the chain, above its
--     siblings of the same strata and level (CUi::SetCapture -> AdjustFrameLevel).
--   * RomLayout.Click(x, y) finds the frame the client would give the click to and runs its scripts.
-- Positions are screen units (UI units times scale), from the top left, like GetPos.

RomLayout = { sizeChanges = 0 }
local E = RomLayout

local POINT = { TOPLEFT = 1, TOP = 2, TOPRIGHT = 3, LEFT = 4, CENTER = 5, RIGHT = 6,
  BOTTOMLEFT = 7, BOTTOM = 8, BOTTOMRIGHT = 9 }
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, TOOLTIP = 6 }
local LAYERS = { Texture = true, FontString = true }

local Widget = getmetatable(UIParent)
local plain = {}
for _, name in ipairs({ "SetAnchor", "ClearAllAnchors", "SetWidth", "SetHeight", "SetSize", "GetPos" }) do
  plain[name] = Widget[name]
end

local function parentOf(w) return w.parent and _G[w.parent] or nil end
local function isFrame(w) return not LAYERS[w.kind] end

-- ### Children order (CUiFrame::InsertChild, AdjustFrameLevel) ###

local function insertChild(parent, w)
  local list = parent.rl.children
  for i, c in ipairs(list) do
    local cs, ws = c.rl, w.rl
    if cs.strata >= ws.strata then
      if cs.strata > ws.strata or cs.topLevel or cs.level > ws.level then
        table.insert(list, i, w)
        return
      end
    end
  end
  table.insert(list, w)
end

local function eraseChild(parent, w)
  local list = parent.rl.children
  for i, c in ipairs(list) do
    if c == w then table.remove(list, i); return end
  end
end

local function adjustFrameLevel(w)
  local parent = parentOf(w)
  if parent and parent.rl then
    eraseChild(parent, w)
    insertChild(parent, w)
    adjustFrameLevel(parent)
  end
end
E.AdjustFrameLevel = adjustFrameLevel

-- ### Size and position (CUiLayout) ###

local resetAnchors

local function relativesOf(w)
  local out = {}
  for i, r in ipairs(w.rl.relatives) do out[i] = r end
  return out
end

local function setPos(w, x, y)
  local s = w.rl
  if s.x ~= x or s.y ~= y then
    s.x, s.y = x, y
    for _, r in ipairs(relativesOf(w)) do
      E.ResetSize(r)
      resetAnchors(r)
    end
  end
end

-- CUiLayout::SetSize / CUiFrame::SetSize: a new size moves what hangs from the object
local function setSize(w, width, height, reAnchor)
  if w.width ~= width or w.height ~= height then
    w.width, w.height = width, height
    E.sizeChanges = E.sizeChanges + 1
    if reAnchor then resetAnchors(w) end
  end
end

-- CUiLayout::ResetSize (CUiFontString's does nothing)
function E.ResetSize(w)
  local s = w.rl
  if w.kind == "FontString" then return end
  local parent = parentOf(w)
  if s.aw == 0 and s.ah == 0 and parent then
    setSize(w, parent.width, parent.height, false)
  end
end

local function anchorPointPos(rel, point, ox, oy)
  local scale = rel:GetRealScale()
  local s = rel.rl
  return ((point - 1) % 3) * (rel.width * scale / 2) + s.x + ox * scale,
    math.floor((point - 1) / 3) * (rel.height * scale / 2) + s.y + oy * scale
end

local function pair(p1, p2, v1, v2) return (p1 == v1 and p2 == v2) or (p1 == v2 and p2 == v1) end

resetAnchors = function(w)
  local s = w.rl
  local parent = parentOf(w)
  local x, y
  if not parent or not parent.rl then
    x, y = 0, 0
  elseif #s.anchors == 0 then
    x, y = parent.rl.x, parent.rl.y
  else
    local a1 = s.anchors[1]
    local rel1 = a1.rel or parent
    local scale = w:GetRealScale()
    if #s.anchors > 1 then
      local a2 = s.anchors[2]
      local x1, y1 = anchorPointPos(rel1, a1.relPoint, a1.x, a1.y)
      local x2, y2 = anchorPointPos(a2.rel or parent, a2.relPoint, a2.x, a2.y)
      local width, height = w.width, w.height
      local p1, p2 = a1.point, a2.point
      if pair(p1, p2, POINT.LEFT, POINT.RIGHT) or pair(p1, p2, POINT.TOPLEFT, POINT.TOPRIGHT)
          or pair(p1, p2, POINT.BOTTOMLEFT, POINT.BOTTOMRIGHT) then
        width = scale > 0 and math.abs(x1 - x2) / scale or 0
      elseif pair(p1, p2, POINT.TOP, POINT.BOTTOM) or pair(p1, p2, POINT.TOPLEFT, POINT.BOTTOMLEFT)
          or pair(p1, p2, POINT.TOPRIGHT, POINT.BOTTOMRIGHT) then
        height = scale > 0 and math.abs(y1 - y2) / scale or 0
      elseif pair(p1, p2, POINT.TOPLEFT, POINT.BOTTOMRIGHT) then
        width = scale > 0 and math.abs(x1 - x2) / scale or 0
        height = scale > 0 and math.abs(y1 - y2) / scale or 0
      end
      setSize(w, width, height, false)
    end
    local rs = rel1.rl
    local relScale = rel1:GetRealScale()
    local relW, relH = rel1.width * relScale, rel1.height * relScale
    x = ((a1.relPoint - 1) % 3) * (relW / 2) - ((a1.point - 1) % 3) * (w.width * scale / 2)
    y = math.floor((a1.relPoint - 1) / 3) * (relH / 2) - math.floor((a1.point - 1) / 3) * (w.height * scale / 2)
    x, y = x + a1.x * scale + rs.x, y + a1.y * scale + rs.y
  end
  setPos(w, x, y)
  for _, r in ipairs(relativesOf(w)) do
    E.ResetSize(r)
    resetAnchors(r)
  end
end
E.ResetAnchors = resetAnchors

local function entangle(rel, w)
  for _, r in ipairs(rel.rl.relatives) do
    if r == w then return end
  end
  table.insert(rel.rl.relatives, w)
end

local function dissolve(rel, w)
  local list = rel.rl.relatives
  for i, r in ipairs(list) do
    if r == w then table.remove(list, i); return end
  end
end

local function clearAnchors(w)
  for _, a in ipairs(w.rl.anchors) do
    if a.rel and a.rel.rl then dissolve(a.rel, w) end
  end
  w.rl.anchors = {}
end

local function setAnchor(w, point, relPoint, rel, x, y)
  local parent = parentOf(w)
  if rel == nil or rel == w then rel = parent end
  local a = { point = POINT[point or ""] or POINT.TOPLEFT, rel = rel, x = x or 0, y = y or 0 }
  a.relPoint = POINT[relPoint or ""] or a.point
  if rel and rel.rl then entangle(rel, w) end
  table.insert(w.rl.anchors, a)
  resetAnchors(w)
end

-- CUiLayout::SetAnchorSize
local function setAnchorSize(w, aw, ah)
  local s = w.rl
  if s.aw ~= aw or s.ah ~= ah then
    s.aw, s.ah = aw, ah
    local parent = parentOf(w)
    if aw == 0 and ah == 0 and parent then
      setSize(w, parent.width, parent.height, true)
    else
      setSize(w, aw, ah, true)
    end
  end
end

-- ### Taking widgets in ###

local function newState(w)
  w.rl = { anchors = {}, relatives = {}, children = {}, x = 0, y = 0, aw = -1, ah = -1,
    strata = STRATA.MEDIUM, level = 0 }
end

-- A widget from XML, as CUi::LoadXmlFrames makes it: inserted into its parent at construction, then
-- its size (the XML's or 0 x 0), its anchors (a TOPLEFT one to the parent when the XML has none),
-- then strata and level.
local function adoptXml(w)
  newState(w)
  local parent = parentOf(w)
  if isFrame(w) and parent and parent.rl then insertChild(parent, w) end
  local width, height = w.width, w.height
  w.width, w.height = 0, 0
  if w.xmlSized then setAnchorSize(w, width, height) else setAnchorSize(w, 0, 0) end
  local a = w.anchor
  w.anchor = nil
  if a then
    setAnchor(w, a[1], a[2], _G[a[3]], a[4], a[5])
  else
    setAnchor(w, "TOPLEFT", "TOPLEFT", parent, 0, 0)
  end
  local strata = STRATA[w.xmlStrata or "MEDIUM"] or STRATA.MEDIUM
  if strata ~= w.rl.strata then w.rl.strata = strata; adjustFrameLevel(w) end
  local level = tonumber(w.xmlLevel) or 0
  if level ~= w.rl.level then w.rl.level = level; adjustFrameLevel(w) end
end

-- Takes in root and every widget under it, in the order they were made (each widget's seq).
function E.Adopt(rootName)
  if not UIParent.rl then
    newState(UIParent)
    UIParent.rl.aw, UIParent.rl.ah = UIParent.width, UIParent.height
  end
  local under = {}
  for _, w in pairs(ummWidgets) do
    local p = w
    while p do
      if p.name == rootName then table.insert(under, w); break end
      p = parentOf(p)
    end
  end
  table.sort(under, function(a, b) return (a.seq or 0) < (b.seq or 0) end)
  for _, w in ipairs(under) do adoptXml(w) end
  E.root = _G[rootName]
end

-- CreateUIComponent: anchor size -1 x -1, placed by its creator.
function E.Created(w)
  local parent = parentOf(w)
  if not (parent and parent.rl) then return end
  newState(w)
  if isFrame(w) then insertChild(parent, w) end
end

-- ### The Lua API, for adopted widgets (others keep the fixture's) ###

function Widget:SetAnchor(point, relPoint, rel, x, y)
  if not self.rl then return plain.SetAnchor(self, point, relPoint, rel, x, y) end
  if type(rel) == "string" then rel = _G[rel] end
  setAnchor(self, point, relPoint, rel, x, y)
end

function Widget:ClearAllAnchors()
  if not self.rl then return plain.ClearAllAnchors(self) end
  clearAnchors(self)
end

-- Each also notes the size Lua asked for (rl.luaW, rl.luaH): a ResetSize later shows as a difference.
function Widget:SetWidth(v)
  if not self.rl then return plain.SetWidth(self, v) end
  setSize(self, v, self.height, true)
  self.rl.luaW, self.rl.luaH = v, self.height
end

function Widget:SetHeight(v)
  if not self.rl then return plain.SetHeight(self, v) end
  setSize(self, self.width, v, true)
  self.rl.luaW, self.rl.luaH = self.width, v
end

function Widget:SetSize(w, h)
  if not self.rl then return plain.SetSize(self, w, h) end
  setSize(self, w, h, true)
  self.rl.luaW, self.rl.luaH = w, h
end

function Widget:GetPos()
  if not self.rl then return plain.GetPos(self) end
  return self.rl.x, self.rl.y
end

function Widget:SetFrameLevel(level)
  if self.rl and self.rl.level ~= level then self.rl.level = level; adjustFrameLevel(self) end
end

-- ### The mouse ###

-- CUiFrame::ContainsPoint (no hit insets here)
function E.Contains(w, x, y)
  local s, scale = w.rl, w:GetRealScale()
  return x >= s.x and y >= s.y and x <= s.x + w.width * scale and y <= s.y + w.height * scale
end

-- CUiFrame::GetFrameAtPoint: children last in order first, then the frame itself if it takes the mouse
function E.FrameAt(x, y, from)
  local function at(w)
    if not w.visible then return nil end
    local list = w.rl.children
    for i = #list, 1, -1 do
      local hit = at(list[i])
      if hit then return hit end
    end
    if w.mouse and E.Contains(w, x, y) then return w end
    return nil
  end
  return at(from or UIParent)
end

-- A button going down, as CUi::Update and CUiFrame::HandleMouse run it: hit test, capture (which
-- lifts the frame and its parents above their siblings), OnMouseDown. Moves the GetCursorPos double's
-- cursor there first. Returns the frame's name, or nil when nothing takes the mouse there.
function E.Down(x, y, button)
  cursorX, cursorY = x, y
  E.captured = nil
  local w = E.FrameAt(x, y)
  if not w or w == UIParent then return nil end
  if w.enabled == false then return w.name end   -- HandleMouse: a disabled frame does nothing
  E.captured = w
  adjustFrameLevel(w)
  key = button or "LBUTTON"
  UMMFixtureDispatch(w.name, "OnMouseDown")
  return w.name
end

-- The button coming up at x, y: the captured frame gets OnClick if the cursor is still on it, then
-- OnMouseUp.
function E.Up(x, y, button)
  cursorX, cursorY = x, y
  local w = E.captured
  E.captured = nil
  if not w then return nil end
  key = button or "LBUTTON"
  if E.Contains(w, x, y) then UMMFixtureDispatch(w.name, "OnClick") end
  UMMFixtureDispatch(w.name, "OnMouseUp")
  return w.name
end

function E.Click(x, y, button)
  local name = E.Down(x, y, button)
  E.Up(x, y, button)
  return name
end

-- The middle of a frame, in screen units.
function E.Center(w)
  local s, scale = w.rl, w:GetRealScale()
  return s.x + w.width * scale / 2, s.y + w.height * scale / 2
end

-- Something moves UIParent (a resolution change, Cherry's Bar lifting the interface): everything
-- anchored to it is re-anchored, as CUiLayout::ResetAnchors does for its relatives.
function E.Relayout()
  resetAnchors(UIParent)
end
