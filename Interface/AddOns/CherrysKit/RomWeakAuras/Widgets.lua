-- Widgets.lua: a thin layer over CreateUIComponent so the rest of the addon reads like WoW code.
-- RoM differences handled here:
--   * CreateUIComponent(type, name, parent, template) always makes a named global, and frames cannot be deleted.
--   * Positions use SetAnchor(point, relativePoint, relativeTo, x, y) instead of SetPoint.
--   * Script handlers are Lua source strings (SetScripts), so they call back into RWA_Script by frame name.
--   * Textures and font strings are drawn by adding them to a parent layer with SetLayers.

local RWA = RWA
local W = {}
RWA.W = W

local counter = 0
local handlers = {} -- [frameName][scriptName] = function(frame, ...)
local names = {} -- [object] = name
local kinds = {} -- [object] = component type
local texts = {} -- [font string] = its text, so a hidden one can be restored
local xmlScripted = {} -- [object] = true when its scripts are declared in XML

function W.UniqueName(prefix)
  counter = counter + 1
  return "RWA_" .. (prefix or "Obj") .. counter
end

function W.NameOf(obj)
  if obj == nil then
    return "UIParent"
  end
  if type(obj) == "string" then
    return obj
  end
  return names[obj] or (obj.GetName and obj:GetName()) or "UIParent"
end

-- Every script string calls this global with the frame name baked in, so it works even
-- when the client does not set `this`.
function RWA_Script(name, script, ...)
  local h = handlers[name]
  local fn = h and h[script]
  if not fn then
    return
  end
  local ok, err = pcall(fn, _G[name], ...)
  if not ok then
    RWA.Error(name .. " " .. script .. ": " .. tostring(err))
  end
end

-- Global variable names the client sets for each script type.
local SCRIPT_ARGS = {
  OnUpdate = "elapsed",
  OnEvent = "event, arg1, arg2, arg3, arg4, arg5, arg6",
  OnClick = "key",
  OnMouseDown = "key",
  OnMouseUp = "key",
  OnMouseWheel = "delta",
}

-- Frames declared in XML (Frames.xml, OptionsWidgets.xml) already call RWA_Script from their
-- scripts. In game, SetScripts from Lua had no effect, so only those frames get working handlers.
function W.UseXmlScripts(obj, name)
  name = name or W.NameOf(obj)
  names[obj] = name
  xmlScripted[obj] = true
  return obj
end

function W.SetScript(obj, script, fn)
  local name = W.NameOf(obj)
  handlers[name] = handlers[name] or {}
  local first = handlers[name][script] == nil
  handlers[name][script] = fn
  if not first or xmlScripted[obj] then
    return
  end
  local args = SCRIPT_ARGS[script]
  local code = "RWA_Script(\"" .. name .. "\", \"" .. script .. "\"" .. (args and (", " .. args) or "") .. ")"
  if type(obj.SetScripts) == "function" then
    obj:SetScripts(script, code)
  elseif type(obj.SetScript) == "function" then
    obj:SetScript(script, function(_, ...)
      RWA_Script(name, script, ...)
    end)
  end
end

local function create(kind, name, parent, template)
  name = name or W.UniqueName(kind)
  local parentName = W.NameOf(parent)
  local ok, obj
  if template then
    ok, obj = pcall(CreateUIComponent, kind, name, parentName, template)
    if not ok or obj == nil then
      RWA.Debug("template " .. template .. " failed for " .. kind)
      obj = nil
    end
  end
  if obj == nil then
    obj = CreateUIComponent(kind, name, parentName)
  end
  names[obj] = name
  kinds[obj] = kind
  return obj, name
end

function W.Frame(name, parent)
  local f = create("Frame", name, parent)
  return f
end

function W.SetPoint(obj, point, relTo, relPoint, x, y)
  RWA.Try(obj, "ClearAllAnchors")
  if type(obj.SetAnchor) == "function" then
    obj:SetAnchor(point, relPoint or point, W.NameOf(relTo), x or 0, y or 0)
  elseif type(obj.SetPoint) == "function" then
    if obj.ClearAllPoints then
      obj:ClearAllPoints()
    end
    obj:SetPoint(point, relTo or UIParent, relPoint or point, x or 0, -(y or 0))
  end
end

-- Positions in this addon use screen-style offsets: +x right, +y down (the RoM convention).
-- If a client turns out to be y-up, the yUp setting flips it in one place.
function W.Place(obj, point, relTo, relPoint, x, y)
  local s = RWA_DB and RWA_DB.settings
  if s and s.yUp then
    y = -(y or 0)
  end
  W.SetPoint(obj, point, relTo, relPoint, x, y)
end

function W.SetSize(obj, w, h)
  if not RWA.Try(obj, "SetSize", w, h) then
    RWA.Try(obj, "SetWidth", w)
    RWA.Try(obj, "SetHeight", h)
  end
end

function W.SetColor(obj, r, g, b, a)
  if not RWA.Try(obj, "SetColor", r, g, b) then
    RWA.Try(obj, "SetVertexColor", r, g, b)
  end
  if a then
    RWA.Try(obj, "SetAlpha", a)
  end
end

local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }

local function addToLayer(parent, layer, obj)
  local level = LAYERS[layer or "ARTWORK"] or 3
  RWA.Try(parent, "SetLayers", level, obj)
end

function W.Texture(parent, layer, file)
  local t = create("Texture", nil, parent)
  addToLayer(parent, layer, t)
  if file then
    W.SetTexture(t, file)
  end
  return t
end

function W.TexturePath(file)
  if file == nil or file == "" then
    return nil
  end
  local lower = string.lower(file)
  if string.find(lower, "^interface[/\\]") or string.find(lower, "^fonts[/\\]") or string.find(lower, "%.%a%a%a$") then
    return file -- a full game path or a file with its own extension
  end
  local ext = (RWA_DB and RWA_DB.settings and RWA_DB.settings.texExt) or ".tga"
  return RWA.media .. "Textures/" .. file .. ext
end

function W.SetTexture(t, file)
  RWA.Try(t, "SetTexture", W.TexturePath(file))
end

function W.FontString(parent, layer, size, outline)
  local fs = create("FontString", nil, parent)
  addToLayer(parent, layer or "OVERLAY", fs)
  W.SetFont(fs, size or 12, outline)
  return fs
end

-- font is a file in Media/Fonts (for example "PTSansNarrow-Bold.ttf") or a full path; nil uses the default.
function W.SetFont(fs, size, outline, font)
  local s = RWA_DB and RWA_DB.settings
  if font and font ~= "" and not string.find(font, "[/\\]") then
    font = RWA.media .. "Fonts/" .. font
  end
  font = (font ~= "" and font) or (s and s.font) or (RWA.media .. "Fonts/FiraSans-Medium.ttf")
  RWA.Try(fs, "SetFont", font, size, "NORMAL", outline or "NORMAL")
end

function W.SetJustify(fs, h)
  if not RWA.Try(fs, "SetJustifyHType", h) then
    RWA.Try(fs, "SetJustifyH", h)
  end
end

-- Buttons and edit boxes come from a pool declared in OptionsWidgets.xml, because RoM only applies
-- UIPanelButtonTemplate / UIPanelEditBoxTemplate from XML. Outside the pool they are created bare.
local claimed = {}
local function claim(prefix, kind, parent, template)
  claimed[prefix] = (claimed[prefix] or 0) + 1
  local name = prefix .. claimed[prefix]
  local obj = _G[name]
  if obj then
    W.UseXmlScripts(obj, name)
    kinds[obj] = kind
    RWA.Try(obj, "Show")
    return obj, true
  end
  RWA.Debug("widget pool empty: " .. name)
  return create(kind, nil, parent, template), false
end

-- An invisible mouse area from the RWA_OptHover pool, for a tooltip over plain text.
function W.HoverFrame(parent)
  return claim("RWA_OptHover", "Frame", parent)
end

-- Aura display frames come from the RWA_Region pool in Frames.xml, so they can be dragged.
function W.RegionFrame()
  local f = claim("RWA_Region", "Frame", "UIParent")
  return f
end

function W.Button(parent, text, w, h, onClick)
  local b = claim("RWA_OptBtn", "Button", parent, "UIPanelButtonTemplate")
  W.SetSize(b, w or 80, h or 22)
  RWA.Try(b, "SetText", text or "")
  if onClick then
    -- W.BeforeClick lets the window close an open dropdown when anything else is clicked.
    W.SetScript(b, "OnClick", function(...)
      if W.BeforeClick then
        W.BeforeClick(b)
      end
      return onClick(...)
    end)
  end
  return b
end

function W.EditBox(parent, w, h)
  local box, pooled = claim("RWA_OptEdit", "EditBox", parent, "UIPanelEditBoxTemplate")
  W.SetSize(box, w or 120, h or 20)
  RWA.Try(box, "ClearFocus")
  local bg
  if not pooled then
    -- No template: draw our own background so the box can be found.
    bg = W.Texture(parent, "BACKGROUND", "Square_FullWhite")
    W.SetColor(bg, 0, 0, 0, 0.5)
    W.SetSize(bg, (w or 120) + 4, (h or 20) + 2)
    W.SetPoint(bg, "CENTER", box, "CENTER", 0, 0)
  end
  W.SetScript(box, "OnEscapePressed", function(self)
    RWA.Try(self, "ClearFocus")
  end)
  W.SetScript(box, "OnEnterPressed", function(self)
    RWA.Try(self, "ClearFocus")
  end)
  return box, bg
end

-- Show or hide anything. Hide does not blank font strings in RoM, so their text is cleared too.
function W.SetShown(obj, on)
  if obj == nil then
    return
  end
  RWA.Try(obj, on and "Show" or "Hide")
  if kinds[obj] == "FontString" then
    RWA.Try(obj, "SetText", on and (texts[obj] or "") or "")
  end
end

function W.GetText(obj)
  if obj and obj.GetText then
    local ok, text = pcall(obj.GetText, obj)
    if ok then
      return text or ""
    end
  end
  return ""
end

function W.SetText(obj, text)
  text = text == nil and "" or tostring(text)
  texts[obj] = text
  RWA.Try(obj, "SetText", text)
end

function W.EnableMouse(obj, on)
  if not RWA.Try(obj, "EnableMouse", on) then
    RWA.Try(obj, "SetMouseEnable", on)
  end
end

-- Dragging without relying on StartMoving: follow GetCursorPos while the button is held.
-- getPos/setPos read and write the caller's stored offsets.
function W.MakeDraggable(obj, getPos, setPos, onDone)
  W.EnableMouse(obj, true)
  RWA.Try(obj, "RegisterForClicks", "LeftButton", "RightButton")
  local drag
  W.SetScript(obj, "OnMouseDown", function()
    if not GetCursorPos then
      return
    end
    local cx, cy = GetCursorPos()
    local x, y = getPos()
    local scale = (GetUIScale and GetUIScale()) or 1
    if scale == 0 then
      scale = 1
    end
    drag = { cx = cx, cy = cy, x = x, y = y, scale = scale }
  end)
  W.SetScript(obj, "OnMouseUp", function()
    if drag and onDone then
      onDone()
    end
    drag = nil
  end)
  return function()
    if not drag then
      return
    end
    local cx, cy = GetCursorPos()
    setPos(drag.x + (cx - drag.cx) / drag.scale, drag.y + (cy - drag.cy) / drag.scale)
  end
end

-- A mouseover tooltip on a pooled button or edit box (their XML declares OnEnter/OnLeave).
-- lines: a title, then lines of help.
function W.Tooltip(obj, title, ...)
  local lines = { ... }
  W.SetScript(obj, "OnEnter", function(self)
    if not GameTooltip then
      return
    end
    -- title can be a function returning the title and lines (no title = no tooltip now)
    local text = title
    if type(title) == "function" then
      local all = { title() }
      if not all[1] then
        return
      end
      text = table.remove(all, 1)
      lines = all
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 0)
    RWA.Try(GameTooltip, "SetFrameStrata", "TOOLTIP")
    GameTooltip:SetText(text)
    for _, line in ipairs(lines) do
      GameTooltip:AddLine(line, 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  W.SetScript(obj, "OnLeave", function()
    if GameTooltip then
      GameTooltip:Hide()
    end
  end)
end
