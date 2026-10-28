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
  local ok, obj, usedTemplate
  if template then
    ok, obj = pcall(CreateUIComponent, kind, name, parentName, template)
    if not ok or obj == nil then
      RWA.Debug("template " .. template .. " failed for " .. kind)
      obj = nil
    else usedTemplate = true end
  end
  if obj == nil then
    obj = CreateUIComponent(kind, name, parentName)
  end
  names[obj] = name
  kinds[obj] = kind
  return obj, name, usedTemplate
end

function W.ChildRegionFrame(parent)
  local frame,name,scripted=create("Frame",nil,parent,"RWA_ChildRegionTemplate")
  if scripted then W.UseXmlScripts(frame,name) end
  return frame
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
  local skin=W.skins and W.skins[obj]
  if skin and skin.panel then
    skin.anchor={point,relTo,relPoint or point,x or 0,y or 0}
    W.LayoutPanel(skin)
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
  if W.LayoutSkin then W.LayoutSkin(obj,w,h) end
end

function W.SetColor(obj, r, g, b, a)
  if not RWA.Try(obj, "SetColor", r, g, b) then
    RWA.Try(obj, "SetVertexColor", r, g, b)
  end
  if a then
    RWA.Try(obj, "SetAlpha", a)
  end
  local peers=W.borderPeers and W.borderPeers[obj]
  if peers then for _,edge in ipairs(peers) do W.SetColor(edge,r,g,b,a) end end
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
-- Small native skins. Shared textures, no per-control update handlers.
W.skins={}
W.borderPeers={}
local skinColors={choice={0.12,0.43,0.53},action={0.70,0.51,0.14},selected={0,0.85,0.88},
  quiet={0.22,0.31,0.40},phrase={0.10,0.24,0.29},clear={0.08,0.19,0.23},
  save={0.95,0.73,0.20},positive={0.12,0.65,0.32},danger={0.72,0.27,0.25}}
function W.LayoutPanel(s)
  local w,h=s.width or 1,s.height or 1
  local a=s.anchor; if not a then return end
  local x=a[4]-(string.find(a[1],"LEFT",1,true) and 0 or string.find(a[1],"RIGHT",1,true) and w or w/2)
  local y=a[5]-(string.find(a[1],"TOP",1,true) and 0 or string.find(a[1],"BOTTOM",1,true) and h or h/2)
  local rects={{x,y,w,1},{x,y+h-1,w,1},{x,y,1,h},{x+w-1,y,1,h}}
  for i,r in ipairs(rects) do
    W.SetPoint(s.edges[i],"TOPLEFT",a[2],a[3],r[1],r[2]); W.SetSize(s.edges[i],r[3],r[4])
  end
end
function W.LayoutSkin(obj,w,h)
  local s=W.skins[obj]; if not s then return end
  s.width,s.height=w,h
  if s.panel then W.LayoutPanel(s); return end
  local mask="Square_FullWhite"
  if not s.square then
    local mw=w<=40 and 32 or w<=80 and 64 or w<=160 and 128 or w<=320 and 256 or w<=640 and 512 or 1024
    local mh=h<=48 and 32 or 96
    if mh==96 then mw=w<=320 and 256 or 512 end
    mask="UI/round-"..mw.."-"..mh
  end
  if s.mask~=mask then W.SetTexture(s.edge,mask); W.SetTexture(s.fill,mask); s.mask=mask end
  W.SetSize(s.edge,w,h); W.SetSize(s.fill,math.max(1,w-2),math.max(1,h-2))
  W.SetSize(s.label,math.max(1,w-(s.iconName and 30 or 10)),h-2)
  W.SetPoint(s.label,"LEFT",obj,"LEFT",s.iconName and 27 or 5,0)
end
function W.Skin(obj,style,icon,square)
  local s=W.skins[obj]
  if not s then
    s={edge=W.Texture(obj,"BACKGROUND","Square_FullWhite"),fill=W.Texture(obj,"BORDER","Square_FullWhite"),
      label=W.FontString(obj,"OVERLAY",12)}
    W.skins[obj]=s
    W.SetPoint(s.edge,"TOPLEFT",obj,"TOPLEFT",0,0); W.SetPoint(s.fill,"TOPLEFT",obj,"TOPLEFT",1,1)
    W.SetJustify(s.label,"CENTER")
  end
  s.style,s.iconName=style or "choice",icon
  s.square=square or s.square
  if icon and not s.icon then s.icon=W.Texture(obj,"ARTWORK"); W.SetSize(s.icon,18,18); W.SetPoint(s.icon,"LEFT",obj,"LEFT",6,0) end
  if s.icon then W.SetShown(s.icon,icon~=nil); if icon then W.SetTexture(s.icon,icon) end end
  W.SetColor(s.edge,unpack(skinColors[s.style] or skinColors.choice))
  W.SetColor(s.fill,s.style=="save" and 0.55 or 0.035,s.style=="save" and 0.37 or 0.085,0.12,1)
  if s.style=="danger" then W.SetColor(s.label,1,.28,.32,1)
  elseif s.style=="positive" then W.SetColor(s.label,.3,1,.55,1)
  else W.SetColor(s.label,s.style=="clear" and .45 or .9,s.style=="clear" and .6 or .95,s.style=="clear" and .65 or 1,1) end
  local _,width=RWA.Try(obj,"GetWidth"); local _,height=RWA.Try(obj,"GetHeight")
  W.LayoutSkin(obj,tonumber(width) or 80,tonumber(height) or 24)
  -- Bare native buttons have no built-in FontString: GetText may be empty
  -- even after SetText. The skin owns its label; never read it back from the button.
  RWA.Try(s.label,"SetText",texts[obj] or "")
  return s
end
function W.HoverSkin(obj,on)
  local s=W.skins[obj]; if not s then return end
  s.hover=on
  if s.style=="clear" then W.SetColor(s.label,on and .8 or .45,on and 1 or .6,on and 1 or .65,1) end
  W.SetColor(s.edge,unpack(on and s.style~="danger" and s.style~="positive" and skinColors.selected or skinColors[s.style] or skinColors.choice))
  if s.style~="save" then W.SetColor(s.fill,on and 0.06 or 0.035,on and 0.17 or 0.085,on and 0.22 or 0.12,1) end
end
function W.PressSkin(obj,on)
  local s=W.skins[obj]; if not s then return end
  if on then W.SetColor(s.fill,0.015,0.045,0.07,1)
  elseif s.style=="save" then W.SetColor(s.fill,0.55,0.37,0.12,1)
  else W.HoverSkin(obj,s.hover) end
end
function W.FlowButton(name,text,width,height,fn,style)
  local b=W.UseXmlScripts(_G[name],name)
  RWA.Try(b,"SetFrameLevel",4)
  W.SetSize(b,width,height); W.SetText(b,text); W.Skin(b,style)
  W.SetScript(b,"OnClick",fn)
  W.SetShown(b,true)
  return b
end
function W.Panel(parent,x,y,width,height,accent,layer)
  -- Decorations belong to the content parent's background layers. An opaque
  -- child frame can cover parent labels/edit boxes in the native client even
  -- when SetFrameLevel claims they have the same level.
  local fill=W.Texture(parent,layer or "BACKGROUND","Square_FullWhite")
  local edges={}
  for i=1,4 do edges[i]=W.Texture(parent,layer=="BORDER" and "ARTWORK" or "BORDER","Square_FullWhite") end
  W.skins[fill]={panel=true,edge=edges[1],edges=edges,fill=fill,style=accent or "quiet"}
  W.borderPeers[edges[1]]={edges[2],edges[3],edges[4]}
  W.SetColor(edges[1],unpack(skinColors[accent or "quiet"] or skinColors.quiet))
  W.SetColor(fill,.035,.085,.12,1)
  W.SetSize(fill,width,height); W.SetPoint(fill,"TOPLEFT",parent,"TOPLEFT",x,y)
  return fill
end

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
  W.SetText(b, text or "")
  W.Skin(b,"action")
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

-- Dedicated XML-backed pool for the unified editor. Rebinding these controls
-- does not allocate more named native widgets while auras or rules change.
function W.UnifiedButton(parent, text, w, h, onClick, menuChoice)
  local b = claim(menuChoice and "RWA_UniChoice" or "RWA_UniBtn", "Button", parent, "UIPanelButtonTemplate")
  RWA.Try(b,"SetFrameLevel",4)
  W.SetSize(b, w or 80, h or 22)
  W.SetText(b, text or "")
  if onClick then
    W.SetScript(b, "OnClick", function(...)
      if W.BeforeClick then W.BeforeClick(b) end
      return onClick(...)
    end)
  end
  W.Skin(b,"choice")
  return b
end

function W.UnifiedEditBox(parent, w, h)
  local box = claim("RWA_UniEdit", "EditBox", parent, "UIPanelEditBoxTemplate")
  W.SetSize(box, w or 120, h or 20)
  RWA.Try(box, "ClearFocus")
  W.SetScript(box, "OnEscapePressed", function(self) RWA.Try(self, "ClearFocus") end)
  W.SetScript(box, "OnEnterPressed", function(self) RWA.Try(self, "ClearFocus") end)
  return box
end

-- Show or hide anything. Hide does not blank font strings in RoM, so their text is cleared too.
function W.SetShown(obj, on)
  if obj == nil then
    return
  end
  RWA.Try(obj, on and "Show" or "Hide")
  if W.skins and W.skins[obj] then
    local skin=W.skins[obj]
    if skin.panel then for _,edge in ipairs(skin.edges) do RWA.Try(edge,on and "Show" or "Hide") end
    else RWA.Try(skin.label,"SetText",on and (texts[obj] or "") or "") end
  end
  if kinds[obj] == "FontString" then
    RWA.Try(obj, "SetText", on and (texts[obj] or "") or "")
  end
end

function W.GetText(obj)
  if W.skins and W.skins[obj] then return texts[obj] or "" end
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
  if W.skins and W.skins[obj] and W.skins[obj].label then RWA.Try(W.skins[obj].label,"SetText",text) end
end

function W.EnableMouse(obj, on)
  if not RWA.Try(obj, "EnableMouse", on) then
    RWA.Try(obj, "SetMouseEnable", on)
  end
end

-- Dragging without relying on StartMoving: follow GetCursorPos while the button is held.
-- getPos/setPos read and write the caller's stored offsets.
function W.MakeDraggable(obj, getPos, setPos, onDone, scaleFactor)
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
    if scaleFactor then scale=scale*(tonumber(scaleFactor()) or 1) end
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
  end, function() drag=nil end
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
    W.activeTooltipOwner = self
    RWA.Try(GameTooltip, "SetFrameStrata", "TOOLTIP")
    GameTooltip:SetText(text)
    for _, line in ipairs(lines) do
      GameTooltip:AddLine(line, 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  W.SetScript(obj, "OnLeave", function()
    if W.activeTooltipOwner == obj then
      W.activeTooltipOwner = nil
      if GameTooltip then GameTooltip:Hide() end
    end
  end)
end
