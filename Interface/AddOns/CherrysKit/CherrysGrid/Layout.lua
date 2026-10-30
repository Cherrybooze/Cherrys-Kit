-- Cherry's Grid: placing the members in the layout frame (CGrid_Layout), the background and
-- border behind them, the "Grid" tab used to move them, and hiding the game's party frames.

local G = CherrysGrid
local L = {}
G.Layout = L

local function uiScale()
  local s = GetUIScale and tonumber(GetUIScale()) or 1
  if not s or s <= 0 then
    s = 1
  end
  return s
end

local CORNER = {
  TOPLEFT = { 0, 0 }, TOPRIGHT = { 1, 0 }, BOTTOMLEFT = { 0, 1 }, BOTTOMRIGHT = { 1, 1 },
}

L.width, L.height = 0, 0

-- Member positions (top left of each, inside the layout frame) and the frame's size.
function L.Compute()
  local P = G.P
  local w, h = G.Frames.Size()
  local s = tonumber(P.scale) or 1
  local pad = math.floor((tonumber(P.padding) or 5) * s + 0.5)
  local sp = math.floor((tonumber(P.spacing) or 1) * s + 0.5)
  local gsp = math.floor((tonumber(P.groupSpacing) or 6) * s + 0.5)
  local spots = {}
  local maxW, maxH = 0, 0
  local offset = 0 -- along the direction groups are stacked
  for _, grp in ipairs(G.Roster.groups) do
    local longest = 0
    for i, e in ipairs(grp.units) do
      local x, y
      if P.horizontal then
        x, y = pad + (i - 1) * (w + sp), pad + offset
      else
        x, y = pad + offset, pad + (i - 1) * (h + sp)
      end
      spots[#spots + 1] = { entry = e, x = x, y = y }
      if x + w > maxW then
        maxW = x + w
      end
      if y + h > maxH then
        maxH = y + h
      end
      longest = i
    end
    if longest > 0 then
      offset = offset + (P.horizontal and h or w) + gsp
    end
  end
  local W, H = maxW + pad, maxH + pad
  if #spots == 0 then
    W, H = 0, 0
  end
  -- grow from the chosen corner: mirror the positions
  local c = CORNER[P.anchor] or CORNER.TOPLEFT
  for _, spot in ipairs(spots) do
    if c[1] == 1 then
      spot.x = W - spot.x - w
    end
    if c[2] == 1 then
      spot.y = H - spot.y - h
    end
  end
  return spots, W, H
end

-- Puts the layout frame where the saved corner is (P.x / P.y are that corner in screen pixels).
function L.Position(W, H)
  local P = G.P
  local frame = CGrid_Layout
  if not frame then
    return
  end
  local us = uiScale()
  local c = CORNER[P.anchor] or CORNER.TOPLEFT
  local x = (tonumber(P.x) or 300) / us - c[1] * W
  local y = (tonumber(P.y) or 300) / us - c[2] * H
  G.Try(frame, "ClearAllAnchors")
  G.Try(frame, "SetAnchor", "TOPLEFT", "TOPLEFT", "UIParent", x, y)
end

function L.SavePosition()
  local P = G.P
  local frame = CGrid_Layout
  if not frame then
    return
  end
  local x, y
  if type(frame.GetPos) == "function" then
    x, y = frame:GetPos()
  end
  if not x and type(frame.GetLeft) == "function" then
    x, y = frame:GetLeft(), frame:GetTop()
  end
  if not x then
    return
  end
  local us = uiScale()
  local c = CORNER[P.anchor] or CORNER.TOPLEFT
  P.x = x + c[1] * L.width * us
  P.y = y + c[2] * L.height * us
  L.Position(L.width, L.height)
end

local function rgb(t, def)
  t = t or def
  return t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 1
end

-- Re-places everything: call after the roster or any size setting changed.
function L.Apply(rosterUpdated)
  local frame = CGrid_Layout
  if not frame or not G.ready then
    return
  end
  local P = G.P
  if not rosterUpdated then G.UpdateRoster() end
  local spots, W, H = L.Compute()
  L.width, L.height = W, H

  local used = {}
  for _, spot in ipairs(spots) do
    local slot = spot.entry.slot
    local o = G.Frames.Obj(slot)
    if o then
      used[slot] = true
      G.Frames.Style(slot, spot.entry)
      G.Try(o.frame, "ClearAllAnchors")
      G.Try(o.frame, "SetAnchor", "TOPLEFT", "TOPLEFT", "CGrid_Layout", spot.x, spot.y)
      o.frame:Show()
    end
  end
  G.Frames.slotOf = {}
  for slot = 1, G.MAX_UNITS do
    if not used[slot] then
      G.Frames.unitOf[slot] = nil
      local o = G.Frames.Obj(slot)
      if o then
        o.frame:Hide()
      end
    else
      G.Frames.slotOf[G.Frames.unitOf[slot]] = slot
    end
  end

  -- background and border behind the members
  G.Try(frame, "SetWidth", math.max(1, W))
  G.Try(frame, "SetHeight", math.max(1, H))
  local bg = CGrid_LayoutBg
  if bg then
    G.Try(bg, "SetTexture", G.MEDIA .. "white.tga")
    local r, g, b, a = rgb(P.bgColor, { 0.06, 0.06, 0.06, 0.7 })
    G.Try(bg, "SetColor", r, g, b)
    G.Try(bg, "SetAlpha", a)
    G.Try(bg, "ClearAllAnchors")
    G.Try(bg, "SetAnchor", "TOPLEFT", "TOPLEFT", "CGrid_Layout", 0, 0)
    G.Try(bg, "SetWidth", math.max(1, W))
    G.Try(bg, "SetHeight", math.max(1, H))
  end
  local edges = { { "T", 0, 0, W, 1 }, { "B", 0, H - 1, W, 1 }, { "L", 0, 0, 1, H }, { "R", W - 1, 0, 1, H } }
  for _, e in ipairs(edges) do
    local t = _G["CGrid_LayoutBorder" .. e[1]]
    if t then
      G.Try(t, "SetTexture", G.MEDIA .. "white.tga")
      local r, g, b, a = rgb(P.borderColor, { 0.45, 0.45, 0.45, 1 })
      G.Try(t, "SetColor", r, g, b)
      G.Try(t, "SetAlpha", a)
      G.Try(t, "ClearAllAnchors")
      G.Try(t, "SetAnchor", "TOPLEFT", "TOPLEFT", "CGrid_Layout", e[2], e[3])
      G.Try(t, "SetWidth", math.max(1, e[4]))
      G.Try(t, "SetHeight", math.max(1, e[5]))
      if P.showBorder and W > 0 then
        t:Show()
      else
        t:Hide()
      end
    end
  end

  L.Position(W, H)
  if #spots > 0 and G.IsOn() then
    frame:Show()
  else
    frame:Hide()
  end
  L.UpdateTab()
  L.KeepPartyHidden()
end

function L.UpdateTab()
  local tab = CGrid_Tab
  if not tab then
    return
  end
  local P = G.P
  local label = CGrid_TabText
  if label then
    label:SetText("Grid  (drag)")
  end
  G.Try(CGrid_TabBg, "SetTexture", G.MEDIA .. "white.tga")
  G.Try(CGrid_TabBg, "SetColor", 0.06, 0.06, 0.06)
  G.Try(CGrid_TabBg, "SetAlpha", 0.8)
  G.Try(tab, "SetWidth", 80)
  if P.locked or P.hideTab or (L.width or 0) <= 0 then
    tab:Hide()
  else
    tab:Show()
  end
end

---------------------------------------------------------------------------
-- Tab (from CherrysGrid.xml): left drag moves, right click opens the options.
---------------------------------------------------------------------------

function L.TabDown(key)
  if key == "RBUTTON" then
    G.Options.Toggle()
    return
  end
  if not G.P.locked and CGrid_Layout then
    L.moving = true
    G.Try(CGrid_Layout, "StartMoving")
  end
end

function L.TabUp()
  if L.moving and CGrid_Layout then
    L.moving = false
    G.Try(CGrid_Layout, "StopMovingOrSizing")
    L.SavePosition()
  end
end

function L.TabEnter(frame)
  if GameTooltip then
    GameTooltip:SetOwner(frame, "ANCHOR_TOP", 0, 0)
    GameTooltip:SetText("Cherry's Grid", 1, 1, 1)
    if not G.P.locked then
      GameTooltip:AddLine("Left drag: move the frames", 0.6, 0.8, 1)
    end
    GameTooltip:AddLine("Right click: options (/grid)", 0.6, 0.8, 1)
    GameTooltip:Show()
  end
end

---------------------------------------------------------------------------
-- The game's own party and player frames
---------------------------------------------------------------------------

L.hidParty = false
L.hidPlayer = false

function L.KeepPartyHidden()
  local P = G.P
  if not G.IsOn() then
    return
  end
  local kind = G.groupType
  local hide = (P.hidePartyFrames == "always" and kind ~= "solo") or (P.hidePartyFrames == "raid" and kind == "raid")
  for i = 1, 5 do
    local f = _G["UnitFrame_party" .. i]
    if f then
      if hide then
        if f:IsVisible() then
          f:Hide()
        end
      elseif L.hidParty and G.U.Exists("party" .. i) and not f:IsVisible() then
        f:Show()
      end
    end
  end
  L.hidParty = hide
  local pf = PlayerFrame
  if pf then
    if P.hidePlayerFrame then
      if pf:IsVisible() then
        pf:Hide()
      end
      L.hidPlayer = true
    elseif L.hidPlayer then
      pf:Show()
      L.hidPlayer = false
    end
  end
end
