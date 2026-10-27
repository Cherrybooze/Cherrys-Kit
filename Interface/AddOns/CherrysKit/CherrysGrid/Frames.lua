-- Cherry's Grid: drawing one member (frames CGrid_Unit1..48 from CherrysGrid.xml).
-- Positions are offsets from the member's top left corner, x right and y down (RoM's SetAnchor).

local G = CherrysGrid
local F = {}
G.Frames = F

F.objs = {}      -- slot -> table of the frame and its parts
F.unitOf = {}    -- slot -> unit shown
F.slotOf = {}    -- unit -> slot
F.flash = {}     -- unit -> { kind = "damage" | "heal", alpha = }
F.lastHealth = {} -- unit -> health last seen (flash)
F.hover = nil    -- slot under the mouse

F.TEXTURES = {
  gradient = "bar_gradient",
  flat = "white",
  glass = "bar_glass",
  smooth = false, -- the game's own bar texture
}

local PARTS = { "Bg", "BarBg", "Bar", "Mana", "Skill", "Flash", "Hover", "BorderT", "BorderB", "BorderL", "BorderR",
  "CornerTL", "CornerTR", "CornerBL", "CornerBR", "Icon", "IconStack", "IconTime", "Text", "Text2", "Text3",
  "Debuff1", "Debuff2", "Debuff3", "Debuff4", "Debuff1Time", "Debuff2Time", "Debuff3Time", "Debuff4Time",
  "Spot1", "Spot2", "Spot3" }

function F.Obj(slot)
  local o = F.objs[slot]
  if o then
    return o
  end
  local name = "CGrid_Unit" .. slot
  local frame = _G[name]
  if not frame then
    return nil
  end
  o = { frame = frame, name = name, slot = slot }
  for _, p in ipairs(PARTS) do
    o[p] = _G[name .. p]
  end
  F.objs[slot] = o
  return o
end

local function media(file)
  return G.MEDIA .. file .. ".tga"
end

local function place(obj, frameName, x, y, w, h)
  if not obj then
    return
  end
  G.Try(obj, "ClearAllAnchors")
  G.Try(obj, "SetAnchor", "TOPLEFT", "TOPLEFT", frameName, x, y)
  if w then
    G.Try(obj, "SetWidth", math.max(0.01, w))
  end
  if h then
    G.Try(obj, "SetHeight", math.max(0.01, h))
  end
end

local function anchor(obj, point, rel, relTo, x, y)
  if not obj then
    return
  end
  G.Try(obj, "ClearAllAnchors")
  G.Try(obj, "SetAnchor", point, rel, relTo, x or 0, y or 0)
end

local function color(obj, col, alpha)
  if not obj or not col then
    return
  end
  G.Try(obj, "SetColor", col[1] or 1, col[2] or 1, col[3] or 1)
  if alpha then
    G.Try(obj, "SetAlpha", alpha)
  end
end

local function show(obj, on)
  if not obj then
    return
  end
  if on then
    obj:Show()
  else
    obj:Hide()
  end
end

function F.Size()
  local P = G.P
  local s = tonumber(P.scale) or 1
  return math.floor((tonumber(P.width) or 56) * s + 0.5), math.floor((tonumber(P.height) or 36) * s + 0.5), s
end

local function showsMana(unit, entry)
  local P = G.P
  if (tonumber(P.manaSize) or 0) <= 0 or (entry and entry.pet) then
    return false
  end
  if P.manaWho == "me" then
    return G.U.IsUnit(unit, "player")
  elseif P.manaWho == "healers" then
    local main, sub = G.U.Class(unit)
    return main == "AUGUR" or main == "DRUID" or sub == "AUGUR" or sub == "DRUID"
  end
  return true
end

-- Places the parts of one member for the current profile. Called by the layout.
function F.Style(slot, entry)
  local o = F.Obj(slot)
  if not o then
    return
  end
  local P = G.P
  local w, h, s = F.Size()
  local name = o.name
  G.Try(o.frame, "SetWidth", w)
  G.Try(o.frame, "SetHeight", h)

  local b = math.max(0, math.floor((tonumber(P.frameBorder) or 1) * s + 0.5))
  local ix, iy, iw, ih = b, b, w - 2 * b, h - 2 * b
  o.inner = { ix, iy, iw, ih }

  -- mana strip along the bottom
  local m = math.floor((tonumber(P.manaSize) or 0) * s + 0.5)
  local mana = entry and showsMana(entry.unit, entry)
  local skill = mana and P.skillBar
  local strip = 0
  if mana then
    strip = m + 1
    if skill then
      strip = strip + m
    end
  end
  o.mana = mana and { ix, iy + ih - m, iw, m } or nil
  o.skill = skill and { ix, iy + ih - 2 * m - 1, iw, m } or nil
  o.health = { ix, iy, iw, ih - strip }

  local tex = F.TEXTURES[P.texture]
  local barFile = (tex == false) and "Interface/Common/Bar/Smooth" or media(tex or "bar_gradient")
  if tex == "bar_gradient" and P.orientation == "HORIZONTAL" then
    barFile = media("bar_gradient_h")
  end
  for _, part in ipairs({ "Bg", "BarBg", "Flash", "Hover", "BorderT", "BorderB", "BorderL", "BorderR",
    "CornerTL", "CornerTR", "CornerBL", "CornerBR" }) do
    G.Try(o[part], "SetTexture", media("white"))
  end
  G.Try(o.Bar, "SetTexture", barFile)
  G.Try(o.Mana, "SetTexture", barFile)
  G.Try(o.Skill, "SetTexture", barFile)
  G.Try(o.BarBg, "SetTexture", barFile)

  place(o.Bg, name, 0, 0, w, h)
  color(o.Bg, { 0, 0, 0 }, 1)
  local hx, hy, hw, hh = o.health[1], o.health[2], o.health[3], o.health[4]
  place(o.BarBg, name, hx, hy, hw, hh)
  place(o.Flash, name, hx, hy, hw, hh)
  place(o.Hover, name, hx, hy, hw, hh)
  color(o.Hover, { 1, 1, 1 }, 0.18)
  show(o.Hover, F.hover == slot)
  if o.mana then
    place(o.Mana, name, o.mana[1], o.mana[2], o.mana[3], o.mana[4])
  end
  show(o.Mana, o.mana ~= nil)
  if o.skill then
    place(o.Skill, name, o.skill[1], o.skill[2], o.skill[3], o.skill[4])
  end
  show(o.Skill, o.skill ~= nil)

  -- border indicator: on the member's outer edge
  local bs = math.max(1, math.floor((tonumber(P.borderSize) or 2) * s + 0.5))
  place(o.BorderT, name, 0, 0, w, bs)
  place(o.BorderB, name, 0, h - bs, w, bs)
  place(o.BorderL, name, 0, 0, bs, h)
  place(o.BorderR, name, w - bs, 0, bs, h)

  local cs = math.max(2, math.floor((tonumber(P.cornerSize) or 7) * s + 0.5))
  place(o.CornerTL, name, ix, iy, cs, cs)
  place(o.CornerTR, name, ix + iw - cs, iy, cs, cs)
  place(o.CornerBL, name, ix, hy + hh - cs, cs, cs)
  place(o.CornerBR, name, ix + iw - cs, hy + hh - cs, cs, cs)

  local is = math.max(4, math.floor((tonumber(P.iconSize) or 16) * s + 0.5))
  place(o.Icon, name, math.floor((w - is) / 2), math.floor(hy + (hh - is) / 2), is, is)
  anchor(o.IconStack, "BOTTOMRIGHT", "BOTTOMRIGHT", name .. "Icon", 0, 0)
  anchor(o.IconTime, "CENTER", "CENTER", name .. "Icon", 0, 0)
  G.Try(o.IconStack, "SetScale", 0.8 * s)
  G.Try(o.IconTime, "SetScale", 0.9 * s)

  local n = math.max(0, math.min(4, tonumber(P.debuffRow) or 0))
  local ds = math.max(4, math.floor((tonumber(P.debuffRowSize) or 11) * s + 0.5))
  for i = 1, 4 do
    local d = o["Debuff" .. i]
    if i <= n then
      local dy = P.debuffRowTop and (hy + 1) or (hy + hh - ds - 1)
      place(d, name, ix + 1 + (i - 1) * (ds + 1), dy, ds, ds)
      anchor(o["Debuff" .. i .. "Time"], "CENTER", "CENTER", name .. "Debuff" .. i, 0, 0)
      G.Try(o["Debuff" .. i .. "Time"], "SetScale", 0.7 * s)
    else
      show(d, false)
      show(o["Debuff" .. i .. "Time"], false)
    end
  end

  local ts = (tonumber(P.textSize) or 1) * s
  for i, t in ipairs({ "Text", "Text2", "Text3" }) do
    G.Try(o[t], "SetScale", ts)
    anchor(o[t], "CENTER", "CENTER", name .. "Spot" .. i, 0, 0)
    G.Try(o["Spot" .. i], "SetAlpha", 0)
  end
  o.textScale = ts
  F.unitOf[slot] = entry and entry.unit or nil
  if entry then
    F.slotOf[entry.unit] = slot
  end
end

-- Texts move: one line sits in the middle, two lines split top / middle, the third goes low.
-- The texts are anchored with no offset to invisible spots (Spot1..3), so their scale never
-- changes where they sit; only the spots are moved.
local function placeTexts(o, has2, has3)
  local name = o.name
  local hy, hh = o.health[2], o.health[4]
  local w = o.inner[3]
  local mid = math.floor(hy + hh / 2)
  local line = math.floor(10 * (o.textScale or 1) + 0.5)
  local y1, y2
  if has2 then
    y1, y2 = mid - math.floor(line * 0.65), mid + math.floor(line * 0.55)
  else
    y1, y2 = (has3 and (mid - math.floor(line * 0.3)) or mid), mid
  end
  place(o.Spot1, name, o.inner[1], y1, w, 1)
  place(o.Spot2, name, o.inner[1], y2, w, 1)
  -- the third line shares the bottom edge with the debuff row: then it takes the right half
  local P = G.P
  local row = (tonumber(P.debuffRow) or 0) > 0 and not P.debuffRowTop
  local x3, w3 = o.inner[1], w
  if row then
    x3, w3 = o.inner[1] + math.floor(w / 2), w - math.floor(w / 2)
  end
  place(o.Spot3, name, x3, hy + hh - math.floor(line * 0.6) - 1, w3, 1)
end

local function setText(fs, result)
  if not fs then
    return false
  end
  if result and result.text and result.text ~= "" then
    fs:SetText(result.text)
    color(fs, result.color)
    fs:Show()
    return true
  end
  fs:Hide()
  return false
end

local function setColorBox(obj, result)
  if result then
    color(obj, result.color, 1)
    obj:Show()
  else
    obj:Hide()
  end
end

-- Draws one member.
function F.Draw(slot)
  local o = F.Obj(slot)
  local unit = F.unitOf[slot]
  if not o or not unit or not o.health then
    return
  end
  local P = G.P
  local entry = G.Roster.byUnit[unit]
  local ind = G.Statuses.Evaluate(unit, entry)

  -- health bar
  local f = G.Statuses.HealthFraction(unit)
  if f > 1 then
    f = 1
  elseif f < 0 then
    f = 0
  end
  if G.U.IsDead(unit) or not G.U.IsOnline(unit) then
    f = 0
  end
  local barCol = (ind.barColor and ind.barColor.color) or { 0.5, 0.5, 0.5 }
  local dark = tonumber(P.bgDarkness) or 0.25
  local hx, hy, hw, hh = o.health[1], o.health[2], o.health[3], o.health[4]
  local fillCol, bgCol = barCol, { barCol[1] * dark, barCol[2] * dark, barCol[3] * dark }
  if P.invert then
    fillCol, bgCol = { 0.08, 0.08, 0.08 }, barCol
  end
  color(o.BarBg, bgCol, 1)
  if f <= 0 then
    o.Bar:Hide()
  else
    if P.orientation == "HORIZONTAL" then
      place(o.Bar, o.name, hx, hy, hw * f, hh)
      G.Try(o.Bar, "SetTexCoord", 0, f, 0, 1)
    else
      local fh = hh * f
      place(o.Bar, o.name, hx, hy + hh - fh, hw, fh)
      G.Try(o.Bar, "SetTexCoord", 0, 1, 1 - f, 1)
    end
    color(o.Bar, fillCol, P.invert and 0.85 or 1)
    o.Bar:Show()
  end

  -- mana / skill strips
  local function strip(obj, rect, cur, max, kind)
    if not rect then
      return
    end
    local mf = (max and max > 0) and (cur / max) or 0
    if mf <= 0 then
      obj:Hide()
      return
    end
    if mf > 1 then
      mf = 1
    end
    place(obj, o.name, rect[1], rect[2], rect[3] * mf, rect[4])
    color(obj, G.Statuses.MANA_COLORS[kind] or G.Statuses.MANA_COLORS[1], 1)
    obj:Show()
  end
  if o.mana then
    strip(o.Mana, o.mana, G.U.Mana(unit))
  end
  if o.skill then
    local cur, max, kind = G.U.Skill(unit)
    if max > 0 then
      strip(o.Skill, o.skill, cur, max, kind)
    else
      o.Skill:Hide()
    end
  end

  -- border and corners
  local border = ind.border
  for _, e in ipairs({ "BorderT", "BorderB", "BorderL", "BorderR" }) do
    setColorBox(o[e], border)
  end
  setColorBox(o.CornerTL, ind.cornerTL)
  setColorBox(o.CornerTR, ind.cornerTR)
  setColorBox(o.CornerBL, ind.cornerBL)
  setColorBox(o.CornerBR, ind.cornerBR)

  -- centre icon
  local icon = ind.icon
  if icon and icon.icon then
    G.Try(o.Icon, "SetTexture", icon.icon)
    local cc = icon.coords
    if cc then
      G.Try(o.Icon, "SetTexCoord", cc[1], cc[2], cc[3], cc[4])
    else
      G.Try(o.Icon, "SetTexCoord", 0, 1, 0, 1)
    end
    G.Try(o.Icon, "SetColor", 1, 1, 1)
    o.Icon:Show()
    if P.iconStacks and icon.stacks and icon.stacks > 1 then
      o.IconStack:SetText(tostring(icon.stacks))
      o.IconStack:Show()
    else
      o.IconStack:Hide()
    end
    if P.iconTime and icon.left then
      o.IconTime:SetText(G.Auras.FormatTime(icon.left))
      o.IconTime:Show()
    else
      o.IconTime:Hide()
    end
  elseif icon then
    -- a colour-only status on the icon: a plain square
    G.Try(o.Icon, "SetTexture", media("white"))
    G.Try(o.Icon, "SetTexCoord", 0, 1, 0, 1)
    color(o.Icon, icon.color, 1)
    o.Icon:Show()
    o.IconStack:Hide()
    o.IconTime:Hide()
  else
    o.Icon:Hide()
    o.IconStack:Hide()
    o.IconTime:Hide()
  end

  -- debuff row: the debuffs after the one in the centre icon
  local n = math.max(0, math.min(4, tonumber(P.debuffRow) or 0))
  if n > 0 then
    local list = G.Auras.ShownDebuffs(unit)
    local skip = (icon and icon.aura) and 1 or 0
    for i = 1, n do
      local a = list[i + skip]
      local d, dt = o["Debuff" .. i], o["Debuff" .. i .. "Time"]
      if a and a.icon then
        G.Try(d, "SetTexture", a.icon)
        d:Show()
        local left = G.Auras.TimeLeft(a)
        if P.iconTime and left and left < 60 then
          dt:SetText(G.Auras.FormatTime(left))
          dt:Show()
        else
          dt:Hide()
        end
      else
        d:Hide()
        dt:Hide()
      end
    end
  end

  -- texts
  setText(o.Text, ind.text)
  local has2 = setText(o.Text2, ind.text2)
  local has3 = setText(o.Text3, ind.text3)
  placeTexts(o, has2, has3)

  -- flash overlay
  local fl = ind.flash
  if fl and fl.alpha and fl.alpha > 0 then
    color(o.Flash, fl.color, fl.alpha)
    o.Flash:Show()
  else
    o.Flash:Hide()
  end

  -- fading
  local alpha = 1
  if ind.alpha and ind.alpha.alpha then
    alpha = tonumber(ind.alpha.alpha) or 1
  end
  G.Try(o.frame, "SetAlpha", alpha)
end

function F.UpdateUnit(unit)
  local slot = F.slotOf[unit]
  if slot and F.unitOf[slot] == unit then
    F.Draw(slot)
  end
end

function F.UpdateAll()
  for slot = 1, G.MAX_UNITS do
    if F.unitOf[slot] then
      F.Draw(slot)
    end
  end
end

-- Health went down: red flash; up by more than 1%: green flash (as GridCliqueIt did).
function F.NoteHealth(unit)
  if not unit then
    return
  end
  local gridUnit = unit
  if not G.Roster.byUnit[unit] then
    local name = UnitName and UnitName(unit)
    gridUnit = name and G.Roster.byName[name]
    if not gridUnit then
      return
    end
  end
  local cur, max = G.U.Health(gridUnit)
  local last = F.lastHealth[gridUnit]
  F.lastHealth[gridUnit] = cur
  if not last or max <= 0 or G.U.IsDead(gridUnit) then
    return
  end
  if cur < last then
    F.flash[gridUnit] = { kind = "damage", alpha = 0.55 }
  elseif cur - last > max / 100 then
    F.flash[gridUnit] = { kind = "heal", alpha = 0.55 }
  end
end

F.FLASH_TIME = 0.8

function F.Animate(elapsed)
  if not next(F.flash) then
    return
  end
  local step = 0.55 * elapsed / F.FLASH_TIME
  for unit, fl in pairs(F.flash) do
    fl.alpha = fl.alpha - step
    local slot = F.slotOf[unit]
    local o = slot and F.objs[slot]
    if fl.alpha <= 0 then
      F.flash[unit] = nil
      if o and o.Flash then
        o.Flash:Hide()
      end
    elseif o and o.Flash and o.Flash:IsVisible() then
      G.Try(o.Flash, "SetAlpha", fl.alpha)
    elseif o then
      G.MarkDirty(unit)
    end
  end
end

---------------------------------------------------------------------------
-- Mouse (from CherrysGrid.xml)
---------------------------------------------------------------------------

function F.OnEnter(frame)
  local slot = frame and tonumber(string.match(frame:GetName() or "", "(%d+)$"))
  if not slot then
    return
  end
  F.hover = slot
  local o = F.Obj(slot)
  if o and o.Hover then
    o.Hover:Show()
  end
  if G.Tooltip then
    G.Tooltip.Show(frame, F.unitOf[slot])
  end
end

function F.OnLeave(frame)
  local slot = frame and tonumber(string.match(frame:GetName() or "", "(%d+)$"))
  if F.hover == slot then
    F.hover = nil
  end
  local o = slot and F.Obj(slot)
  if o and o.Hover then
    o.Hover:Hide()
  end
  if G.Tooltip then
    G.Tooltip.Hide()
  end
end

function F.OnMouseDown(frame, key)
  local slot = frame and tonumber(string.match(frame:GetName() or "", "(%d+)$"))
  if slot and not G.P.clickOnUp then
    G.Clicks.Run(F.unitOf[slot], key, frame)
  end
end

function F.OnMouseUp(frame, key)
  local slot = frame and tonumber(string.match(frame:GetName() or "", "(%d+)$"))
  if slot and G.P.clickOnUp then
    G.Clicks.Run(F.unitOf[slot], key, frame)
  end
end
