-- Cherry's Bar: drawing displays, placing them on the bars and dragging them. A display is one slot
-- in CherrysBar.xml: an icon and a line of text. Its text comes from a format such as "[USED]/[TOTAL]".

local G = CherrysBar
local D = {}
G.Displays = D

D.list = {}         -- every display, in slot order (filled by DisplayList.lua)
D.byKey = {}
D.PADDING = 10      -- between two displays
D.TEXT_GAP = 4
D.GRIP = 14         -- room for the drag handle while unlocked
D.DRAG_PIXELS = 4   -- a press that moves less than this is a click
D.SHRINK_SLACK = 4  -- a text this much narrower does not move its neighbours (digits vary in width)

local active = {}   -- the displays currently on a shown bar: all a tick ever looks at
D.active = active
local eventMap = {} -- event -> displays that care; rebuilt when settings change
local registered = {}
local layoutDirty = false
local dragging      -- { def, x, y } while a display follows the mouse

function D.Add(def)
  def.slot = #D.list + 1
  def.v = {}
  D.list[def.slot] = def
  D.byKey[def.key] = def
end

function D.Config(def)
  return G.S().displays[def.key]
end

-- A display's defaults: which bar, which side and in what order.
function D.ApplyDefaults()
  local all = G.S().displays
  for _, def in ipairs(D.list) do
    local cfg = all[def.key]
    if type(cfg) ~= "table" then
      cfg = {}
      all[def.key] = cfg
    end
    if cfg.bar == nil then cfg.bar = def.bar or "off" end
    if cfg.side == nil then cfg.side = def.side or "left" end
    if cfg.order == nil then cfg.order = def.order or (100 + def.slot) end
    if cfg.icon == nil then cfg.icon = def.icon ~= nil end
    if cfg.label == nil then cfg.label = def.showLabel and true or false end
    if cfg.color == nil then cfg.color = true end
    if cfg.fmt == nil then cfg.fmt = def.fmt or "" end
  end
end

local function widget(def, part)
  return _G["CBar_D" .. def.slot .. part]
end

-- A display that needs another addon does not exist without it.
function D.IsAvailable(def)
  return (not def.available or def.available()) and true or false
end

local function onBar(def, cfg)
  return D.IsAvailable(def) and cfg.bar ~= "off" and G.Bars.IsShown(cfg.bar)
end

local function unlocked()
  return not G.S().locked
end

local function iconSize()
  return math.min(G.Bars.Height() - 8, 22)
end

-- Volume's speakers are drawn on a 2:1 canvas, and every other icon is square.
local function iconWidth(def)
  return def.iconWide and iconSize() * 2 or iconSize()
end

-- A display reads only what its format asks for: { "EVENT", "TOKEN", ... } registers EVENT only
-- when the format holds one of those tokens; no tokens listed means always.
local function wantsEvent(entry, fmt)
  if #entry == 1 then
    return true
  end
  for i = 2, #entry do
    if string.find(fmt, "[" .. entry[i] .. "]", 1, true) then
      return true
    end
  end
  return false
end

local function rebuildEvents()
  eventMap = {}
  for _, def in ipairs(active) do
    local fmt = D.Config(def).fmt
    for _, entry in ipairs(def.events or {}) do
      if wantsEvent(entry, fmt) then
        local list = eventMap[entry[1]]
        if not list then
          list = {}
          eventMap[entry[1]] = list
        end
        list[#list + 1] = def
      end
    end
  end
  local frame = G.frame
  if not frame then
    return
  end
  for event in pairs(eventMap) do
    if not registered[event] then
      G.Try(frame, "RegisterEvent", event)
      registered[event] = true
    end
  end
  for event in pairs(registered) do
    if not eventMap[event] then
      G.Try(frame, "UnregisterEvent", event)
      registered[event] = nil
    end
  end
end

-- Events arrive in bursts (bags, damage): they only mark a display, and the next tick redraws it once.
function D.OnEvent(event, arg1)
  local list = eventMap[event]
  if not list then
    return
  end
  for i = 1, #list do
    local def = list[i]
    if not def.onEvent or def.onEvent(def, event, arg1) ~= false then
      def.dirty = true
    end
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function strip(text)
  text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
  text = string.gsub(text, "|r", "")
  return text
end

-- What the display says now. Colour codes are written by the read function, and stripped here for
-- a display whose Colour tick is off.
function D.Text(def, cfg)
  local text = string.gsub(cfg.fmt, "%[(%u+%d*)%]", def.v)
  if not cfg.color then
    text = strip(text)
  end
  if cfg.label and def.label then
    local head = cfg.color and ("|cffffd100" .. def.label .. "|r") or def.label
    text = text == "" and head or (head .. " " .. text)
  end
  return text
end

-- A FontString with no size takes its text's width (found out by Cherry's Chat's /cchat measuretest).
local function measure(fs, text)
  if fs and type(fs.GetWidth) == "function" then
    local ok, w = pcall(fs.GetWidth, fs)
    if ok and type(w) == "number" and w > 0 and w < 4000 then
      return w
    end
  end
  local letters = string.gsub(strip(text), "[\128-\191]", "")
  return #letters * (tonumber(G.S().textSize) or 12) * 0.55
end

function D.Update(def)
  def.dirty = false
  local cfg = D.Config(def)
  if def.read then
    local ok, err = pcall(def.read, def.v, def, cfg)
    if not ok then
      def.err = tostring(err)
    else
      def.err = nil
    end
  end
  local text = D.Text(def, cfg)
  if text == def.shownText then
    return
  end
  def.shownText = text
  local fs = widget(def, "Text")
  if not fs then
    return
  end
  fs:SetText(text)
  local width = measure(fs, text)
  local old = def.textWidth or 0
  if width > old or old - width > D.SHRINK_SLACK then
    def.textWidth = width
    layoutDirty = true
  end
end

-- For a display whose picture follows its reading, such as Volume's speaker.
function D.SetIcon(def, file)
  if def.iconNow ~= file then
    def.iconNow = file
    if D.Config(def).icon then
      G.Try(widget(def, "Icon"), "SetTexture", file)
    end
  end
end

function D.Tick(dt)
  for i = 1, #active do
    local def = active[i]
    if def.every then
      def.timer = (def.timer or 0) + dt
      if def.timer >= def.every then
        def.timer = 0
        if def.tick then
          if def.tick(def) then
            def.dirty = true
          end
        else
          def.dirty = true
        end
      end
    end
    if def.dirty then
      D.Update(def)
    end
  end
  if layoutDirty then
    layoutDirty = false
    D.Layout()
  end
end

---------------------------------------------------------------------------
-- Placing: left-side displays flow from the left edge, right-side ones from the right edge.
---------------------------------------------------------------------------

local function displayWidth(def, cfg)
  local grip = unlocked() and D.GRIP or 0
  local iconPart = (cfg.icon and def.icon) and (iconWidth(def) + D.TEXT_GAP) or 0
  return grip + iconPart + (def.textWidth or 0) + 8
end

local function byOrder(a, b)
  local ca, cb = D.Config(a), D.Config(b)
  if ca.order ~= cb.order then
    return ca.order < cb.order
  end
  return a.slot < b.slot
end

-- The displays on one side of one bar, left to right. With no side: all of them on that bar.
function D.Row(bar, side)
  local row = {}
  for _, def in ipairs(D.list) do
    local cfg = D.Config(def)
    if cfg.bar == bar and (side == nil or cfg.side == side) and D.IsAvailable(def) then
      row[#row + 1] = def
    end
  end
  table.sort(row, byOrder)
  return row
end

local function place(def, cfg, barName, side, offset)
  local frame = widget(def, "")
  local width = displayWidth(def, cfg)
  frame:ClearAllAnchors()
  local relName = barName == "bottom" and "CBar_BarBottom" or "CBar_BarTop"
  local nudge = G.Bars.Nudge(barName)
  if side == "right" then
    frame:SetAnchor("RIGHT", "RIGHT", relName, -offset, nudge)
  else
    frame:SetAnchor("LEFT", "LEFT", relName, offset, nudge)
  end
  G.Try(frame, "SetWidth", width)
  G.Try(frame, "SetHeight", G.Bars.Height())
  return width
end

function D.Layout()
  for _, barName in ipairs(G.BAR_NAMES) do
    if G.Bars.IsShown(barName) then
      local offset = D.PADDING + G.Bars.Gap(barName, "left")
      for _, def in ipairs(D.Row(barName, "left")) do
        offset = offset + place(def, D.Config(def), barName, "left", offset) + D.PADDING
      end
      local right = D.PADDING + G.Bars.Gap(barName, "right") + (unlocked() and G.Bars.HANDLE_SPACE or 0)
      local row = D.Row(barName, "right")
      for i = #row, 1, -1 do
        local def = row[i]
        right = right + place(def, D.Config(def), barName, "right", right) + D.PADDING
      end
    end
  end
end

---------------------------------------------------------------------------
-- After a settings change
---------------------------------------------------------------------------

local function styleSlot(def, cfg)
  local icon, text, grip = widget(def, "Icon"), widget(def, "Text"), widget(def, "Grip")
  local left = 4
  if grip then
    if unlocked() then
      grip:Show()
      left = left + D.GRIP
    else
      grip:Hide()
    end
  end
  local size = iconSize()
  if icon then
    if cfg.icon and def.icon then
      G.Try(icon, "SetTexture", def.iconNow or def.icon)
      G.Try(icon, "SetWidth", iconWidth(def))
      G.Try(icon, "SetHeight", size)
      icon:ClearAllAnchors()
      icon:SetAnchor("LEFT", "LEFT", widget(def, ""), left, 0)
      icon:Show()
      left = left + iconWidth(def) + D.TEXT_GAP
    else
      icon:Hide()
    end
  end
  if text then
    local fontSize = tonumber(G.S().textSize) or 12
    -- The XML's size is 12: the font is left alone until the player has changed it.
    if fontSize ~= 12 or def.fontSet then
      local ok, path
      if type(text.GetFont) == "function" then
        ok, path = pcall(text.GetFont, text)
      end
      path = (ok and type(path) == "string") and path or "Fonts/DFHEIMDU.TTF"
      G.Try(text, "SetFont", path, fontSize, "NORMAL", "NORMAL")
      def.fontSet = true
    end
    text:ClearAllAnchors()
    text:SetAnchor("LEFT", "LEFT", widget(def, ""), left, 0)
  end
end

-- Re-reads every shown display and places them all: after a settings change only, never in a tick.
function D.Rebuild()
  for i = #active, 1, -1 do
    active[i] = nil
  end
  for _, def in ipairs(D.list) do
    local cfg = D.Config(def)
    local frame = widget(def, "")
    if frame then
      local shown = onBar(def, cfg)
      if def.placed then
        pcall(def.placed, def, shown)
      end
      if shown then
        active[#active + 1] = def
        def.timer = 0
        def.dirty = true
        def.shownText = nil
        def.textWidth = nil
        if def.setup then
          pcall(def.setup, def, cfg)
        end
        styleSlot(def, cfg)
        if G.Bars.IsVisible(cfg.bar) then
          frame:Show()
        else
          frame:Hide()
        end
      else
        frame:Hide()
      end
    end
  end
  rebuildEvents()
  for i = 1, #active do
    D.Update(active[i])
  end
  layoutDirty = false
  D.Layout()
end

-- An auto-hide bar came out or went away. Text is measured again on the way out: a hidden font
-- string may not have reported its width.
function D.BarShown(name, on)
  for i = 1, #active do
    local def = active[i]
    if D.Config(def).bar == name then
      local frame = widget(def, "")
      if on then
        frame:Show()
        def.shownText = nil
        def.dirty = true
      else
        frame:Hide()
      end
    end
  end
end

---------------------------------------------------------------------------
-- Moving a display
---------------------------------------------------------------------------

-- Puts a display on a bar and side, at `index` among the others there (0 is the far left).
function D.Place(def, bar, side, index)
  local cfg = D.Config(def)
  cfg.bar, cfg.side = bar, side
  if bar ~= "off" then
    local row = {}
    for _, other in ipairs(D.Row(bar, side)) do
      if other ~= def then
        row[#row + 1] = other
      end
    end
    table.insert(row, math.max(0, math.min(index, #row)) + 1, def)
    for i, other in ipairs(row) do
      D.Config(other).order = i * 10
    end
    -- A display sent to a bar that is off brings the bar with it.
    if not G.Bars.IsShown(bar) then
      G.S().bars[bar].show = true
      G.Refresh()
      return
    end
  end
  D.Rebuild()
end

-- Onto a bar, at the end of the side it was on.
function D.SetBar(def, bar)
  local cfg = D.Config(def)
  if bar == "off" then
    D.Place(def, "off", cfg.side, 0)
  else
    D.Place(def, bar, cfg.side, #D.Row(bar, cfg.side))
  end
end

-- One step along the bar, -1 towards the left or 1 towards the right. Stepping past the end of its
-- side crosses the gap to the other side, so the two buttons reach every place on the bar.
function D.Step(def, step)
  local cfg = D.Config(def)
  if cfg.bar == "off" then
    return
  end
  local row = D.Row(cfg.bar, cfg.side)
  local at = 1
  for i, other in ipairs(row) do
    if other == def then
      at = i
    end
  end
  local target = at + step
  if target >= 1 and target <= #row then
    D.Place(def, cfg.bar, cfg.side, target - 1)
  elseif step > 0 and cfg.side == "left" then
    D.Place(def, cfg.bar, "right", 0)
  elseif step < 0 and cfg.side == "right" then
    D.Place(def, cfg.bar, "left", #D.Row(cfg.bar, "left"))
  end
end

-- Dropped by the mouse: the nearest shown bar, the side of the screen it is on, and between the
-- displays either side of it. Positions are the pixels FramePos gives.
function D.Drop(def, x, y)
  local cfg = D.Config(def)
  local bar = cfg.bar
  local topOn, bottomOn = G.Bars.IsVisible("top"), G.Bars.IsVisible("bottom")
  if topOn and bottomOn then
    local _, topY = G.FramePos(CBar_BarTop)
    local _, bottomY = G.FramePos(CBar_BarBottom)
    if topY and bottomY then
      bar = math.abs(y - topY) <= math.abs(y - bottomY) and "top" or "bottom"
    end
  elseif topOn then
    bar = "top"
  elseif bottomOn then
    bar = "bottom"
  end
  local scale = G.UIScale()
  local center = x + displayWidth(def, cfg) * scale / 2
  local side = center < G.MiddleX() and "left" or "right"
  local index = 0
  for _, other in ipairs(D.Row(bar, side)) do
    if other ~= def then
      local ox = G.FramePos(widget(other, ""))
      if ox and ox + displayWidth(other, D.Config(other)) * scale / 2 < center then
        index = index + 1
      end
    end
  end
  D.Place(def, bar, side, index)
  G.Options.Refresh()
end

---------------------------------------------------------------------------
-- Mouse
---------------------------------------------------------------------------

function D.TooltipOwner(frame, def)
  local bottom = D.Config(def).bar == "bottom"
  local x = G.FramePos(frame) or 0
  local side = (x < G.MiddleX()) and "RIGHT" or "LEFT"
  GameTooltip:SetOwner(frame, "ANCHOR_" .. (bottom and "TOP" or "BOTTOM") .. side, 0, 0)
end

function D.Enter(slot, frame)
  local def = D.list[slot]
  if not def then
    return
  end
  G.Try(widget(def, "Hover"), "Show")
  G.Bars.Hover(D.Config(def).bar, true)
  if dragging or not GameTooltip or (G.InCombat() and not G.S().tipsInCombat) then
    return
  end
  D.TooltipOwner(frame, def)
  GameTooltip:SetText(def.title or def.label or def.key, 1, 1, 1)
  if def.read then
    def.hovering = true
    pcall(def.read, def.v, def, D.Config(def))
    def.hovering = false
  end
  if def.tip then
    local ok, err = pcall(def.tip, def.v, def)
    if not ok then
      def.err = tostring(err)
    end
  end
  if def.hint then
    GameTooltip:AddLine(def.hint, 0, 0.7, 0.9)
  end
  if unlocked() then
    GameTooltip:AddLine("Drag: move it along the bar", 0, 0.7, 0.9)
  end
  GameTooltip:AddLine("Right-click: options for this display", 0, 0.7, 0.9)
  G.Try(GameTooltip, "Show")
end

function D.Leave(slot)
  local def = D.list[slot]
  if def then
    G.Try(widget(def, "Hover"), "Hide")
    local bar = D.Config(def).bar
    if bar ~= "off" then
      G.Bars.Hover(bar, false)
    end
  end
  if GameTooltip then
    GameTooltip:Hide()
  end
end

-- The client moves the frame itself between StartMoving and StopMovingOrSizing, as XBar did, so a
-- drag adds no update loop.
function D.MouseDown(slot, key)
  local def = D.list[slot]
  if not def or key ~= "LBUTTON" or not unlocked() then
    return
  end
  local frame = widget(def, "")
  local x, y = G.FramePos(frame)
  if x and G.Try(frame, "StartMoving") then
    dragging = { def = def, x = x, y = y }
    if GameTooltip then
      GameTooltip:Hide()
    end
  end
end

function D.MouseUp(slot, key)
  local def = D.list[slot]
  if not def then
    return
  end
  if dragging and dragging.def == def then
    local from = dragging
    dragging = nil
    local frame = widget(def, "")
    G.Try(frame, "StopMovingOrSizing")
    local x, y = G.FramePos(frame)
    if x and math.abs(x - from.x) + math.abs(y - from.y) >= D.DRAG_PIXELS then
      D.Drop(def, x, y)
      return
    end
    D.Layout() -- back to its place: it was a click
  end
  if key == "RBUTTON" then
    if GameTooltip then
      GameTooltip:Hide()
    end
    G.Menu.OpenDisplay(def, widget(def, ""))
  elseif key == "LBUTTON" and def.click then
    local ok, err = pcall(def.click, def, widget(def, ""))
    if not ok then
      def.err = tostring(err)
      G.Print((def.title or def.key) .. " could not do that here: " .. def.err)
    end
  end
end

function D.Wheel(slot, delta)
  local def = D.list[slot]
  if def and def.wheel then
    local ok, err = pcall(def.wheel, def, delta)
    if not ok then
      def.err = tostring(err)
    end
    D.Update(def)
  end
end
