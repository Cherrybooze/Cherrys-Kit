-- Cherry's Bar: the /cbar options window. At the top each bar's own settings. In the middle a map of
-- both bars and the displays not shown: drag a display between the rows, or pick one and use the
-- buttons. Below that the picked display's own settings, then the general ones.

local G = CherrysBar
local O = {}
G.Options = O

O.GENERAL_ROWS = 8
-- The layout rows, as tools/gen_cherrysbar_xml.py places them.
O.ROW_X, O.ROW_W, O.ROW_H = 90, 776, 30
O.ROWS = { { key = "top", y = 148 }, { key = "bottom", y = 182 }, { key = "off", y = 216 } }
O.CHIP_H, O.CHIP_MAX, O.CHIP_MIN_TEXT = 24, 66, 50
O.DRAG_PIXELS = 4

local function pct(v)
  return math.floor((tonumber(v) or 0) * 100 + 0.5) .. "%"
end

O.LIST = {
  { key = "barHeight", kind = "num", label = "Bar height", min = 20, max = 36, step = 2 },
  { key = "textSize", kind = "num", label = "Text size", min = 9, max = 16, step = 1 },
  { key = "makeRoom", kind = "check", label = "Move the game's frames clear of the bars",
    tip = "Moves the player, target, party, buff and minimap frames down, and the action bar up, so the bars do not cover them. A frame you dragged far from the edge stays where it is." },
  { key = "tipsInCombat", kind = "check", label = "Tooltips in combat" },
  { key = "hideMenuBar", kind = "check", label = "Hide the game's menu bar",
    tip = "The Menu display on the bar opens the same windows." },
  { key = "hideXpBar", kind = "check", label = "Hide the game's XP bar" },
  { key = "hideDura", kind = "check", label = "Hide the game's damaged-gear figure" },
}

local picked = "Menu"
local chipDrag

local function part(i, name)
  return _G["CBar_OptRow" .. i .. name]
end

local function shown(w, on)
  if w then
    if on then
      w:Show()
    else
      w:Hide()
    end
  end
end

local function pickedDef()
  return G.Displays.byKey[picked]
end

local function displayName(def)
  return def.title or def.label or def.key
end

---------------------------------------------------------------------------
-- Drawing the window
---------------------------------------------------------------------------

local function refreshBar(name)
  local n = "CBar_OptBar" .. (name == "bottom" and "Bottom" or "Top")
  local cfg = G.S().bars[name]
  _G[n .. "Show"]:SetChecked(cfg.show and 1 or nil)
  _G[n .. "Skin"]:SetText(cfg.skin)
  _G[n .. "Value"]:SetText(pct(cfg.alpha))
  _G[n .. "Auto"]:SetChecked(cfg.autoHide and 1 or nil)
  local art = _G["CBar_Layout" .. (name == "bottom" and "Bottom" or "Top")]
  G.Try(art, "SetTexture", G.Bars.SkinFile(name))
end

local function placeChip(def, x, y, width)
  local n = "CBar_Chip" .. def.slot
  local chip = _G[n]
  if not chip then
    return
  end
  chip:ClearAllAnchors()
  chip:SetAnchor("TOPLEFT", "TOPLEFT", "CBar_Options", x, y)
  G.Try(chip, "SetWidth", width)
  local icon = _G[n .. "Icon"]
  local iconW = def.iconWide and 32 or 18
  G.Try(icon, "SetTexture", def.iconNow or def.icon)
  G.Try(icon, "SetWidth", iconW)
  G.Try(icon, "SetHeight", def.iconWide and 16 or 18)
  local text = _G[n .. "Text"]
  text:ClearAllAnchors()
  text:SetAnchor("LEFT", "LEFT", n, iconW + 5, 0)
  if width >= O.CHIP_MIN_TEXT then
    text:SetText(def.short or def.label or def.key)
    text:Show()
  else
    text:Hide()
  end
  shown(_G[n .. "Mark"], def.key == picked)
  chip:Show()
end

-- A row shows its displays as they stand on the bar: the left side from the left, the right side
-- from the right. Chips shrink to their icon when a row is crowded.
local function refreshRow(rowDef)
  local y = rowDef.y + 3
  if rowDef.key == "off" then
    local row = G.Displays.Row("off")
    local width = math.min(O.CHIP_MAX, math.floor((O.ROW_W - 8) / math.max(1, #row)))
    for i, def in ipairs(row) do
      placeChip(def, O.ROW_X + 4 + (i - 1) * width, y, width - 2)
    end
    return
  end
  local left, right = G.Displays.Row(rowDef.key, "left"), G.Displays.Row(rowDef.key, "right")
  local count = #left + #right
  local width = math.min(O.CHIP_MAX, math.floor((O.ROW_W - 8) / math.max(1, count)))
  for i, def in ipairs(left) do
    placeChip(def, O.ROW_X + 4 + (i - 1) * width, y, width - 2)
  end
  for i, def in ipairs(right) do
    placeChip(def, O.ROW_X + O.ROW_W - 4 - (#right - i + 1) * width, y, width - 2)
  end
end

local function refreshPicked()
  local def = pickedDef()
  if not def then
    return
  end
  local cfg = G.Displays.Config(def)
  CBar_OptionsPicked:SetText(displayName(def))
  CBar_OptionsIcon:SetChecked(cfg.icon and 1 or nil)
  CBar_OptionsLabel:SetChecked(cfg.label and 1 or nil)
  CBar_OptionsColor:SetChecked(cfg.color and 1 or nil)
  if def.tokens then
    CBar_OptionsTokens:SetText(def.tokens)
    CBar_OptionsFormat:SetText(cfg.fmt)
    CBar_OptionsFormat:Show()
    CBar_OptionsApply:Show()
    CBar_OptionsFormatReset:Show()
    CBar_OptionsTextLabel:Show()
  else
    CBar_OptionsTokens:SetText("This display has no text of its own.")
    CBar_OptionsFormat:Hide()
    CBar_OptionsApply:Hide()
    CBar_OptionsFormatReset:Hide()
    CBar_OptionsTextLabel:Hide()
  end
end

function O.Refresh()
  if not CBar_Options or not G.ready then
    return
  end
  local S = G.S()
  CBar_OptionsTitle:SetText("Cherry's Bar " .. G.version)
  refreshBar("top")
  refreshBar("bottom")
  CBar_OptionsLock:SetText(S.locked and "Unlock to drag on the bars" or "Lock the displays")
  for _, rowDef in ipairs(O.ROWS) do
    refreshRow(rowDef)
  end
  refreshPicked()
  for i = 1, O.GENERAL_ROWS do
    local def = O.LIST[i]
    local row = part(i, "")
    if def and row then
      local v = S[def.key]
      part(i, "Label"):SetText(def.label)
      shown(part(i, "Check"), def.kind == "check")
      shown(part(i, "Minus"), def.kind == "num")
      shown(part(i, "Plus"), def.kind == "num")
      shown(part(i, "Value"), def.kind == "num")
      if def.kind == "check" then
        part(i, "Check"):SetChecked(v and 1 or nil)
      else
        part(i, "Value"):SetText(tostring(v))
      end
      row:Show()
    elseif row then
      row:Hide()
    end
  end
end

function O.Toggle()
  if not CBar_Options then
    return
  end
  if CBar_Options:IsVisible() then
    CBar_Options:Hide()
  else
    CBar_Options:Show()
    O.Refresh()
  end
end

---------------------------------------------------------------------------
-- Bars
---------------------------------------------------------------------------

function O.BarClick(name, what)
  local cfg = G.S().bars[name]
  if what == "show" then
    cfg.show = not cfg.show
  elseif what == "auto" then
    G.Bars.SetAutoHide(name, not cfg.autoHide)
    return
  elseif what == "skin" then
    local skins, at = G.Bars.SKINS, 0
    for i, key in ipairs(skins) do
      if key == cfg.skin then
        at = i
      end
    end
    cfg.skin = skins[at + 1] or skins[1]
  else
    local v = (tonumber(cfg.alpha) or 1) + (what == "plus" and 0.1 or -0.1)
    cfg.alpha = math.floor(math.max(0.1, math.min(1, v)) * 10 + 0.5) / 10
  end
  G.Refresh()
  O.Refresh()
end

function O.ToggleLock()
  G.Bars.SetLocked(not G.S().locked)
end

---------------------------------------------------------------------------
-- Moving displays: buttons and dragging chips
---------------------------------------------------------------------------

function O.Move(what)
  local def = pickedDef()
  if not def then
    return
  end
  if what == "left" then
    G.Displays.Step(def, -1)
  elseif what == "right" then
    G.Displays.Step(def, 1)
  else
    G.Displays.SetBar(def, what)
  end
  O.Refresh()
end

function O.ChipEnter(slot, frame)
  local def = G.Displays.list[slot]
  if def and GameTooltip and not chipDrag then
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM", 0, 0)
    GameTooltip:SetText(displayName(def), 1, 1, 1)
    GameTooltip:AddLine("Click to pick it. Drag it to another place or row.", 0.9, 0.9, 0.9)
    G.Try(GameTooltip, "Show")
  end
end

function O.ChipDown(slot, key)
  local chip = _G["CBar_Chip" .. slot]
  if key ~= "LBUTTON" or not chip then
    return
  end
  local x, y = G.FramePos(chip)
  if x and G.Try(chip, "StartMoving") then
    chipDrag = { slot = slot, x = x, y = y }
    if GameTooltip then
      GameTooltip:Hide()
    end
  end
end

-- Dropped: the row it is nearest, the side of that row, and between the chips either side of it.
function O.ChipDrop(def, x, y)
  local scale = G.UIScale()
  local ox, oy = G.FramePos(CBar_Options)
  if not ox then
    return
  end
  -- Back to window units, the chip's centre.
  local cx = (x - ox) / scale + O.CHIP_MAX / 2
  local cy = (y - oy) / scale + O.CHIP_H / 2
  local target, best = "off", nil
  for _, rowDef in ipairs(O.ROWS) do
    local distance = math.abs(cy - (rowDef.y + O.ROW_H / 2))
    if not best or distance < best then
      target, best = rowDef.key, distance
    end
  end
  if target == "off" then
    G.Displays.SetBar(def, "off")
    return
  end
  local side = cx < O.ROW_X + O.ROW_W / 2 and "left" or "right"
  local index = 0
  for _, other in ipairs(G.Displays.Row(target, side)) do
    if other ~= def then
      local chipX = G.FramePos(_G["CBar_Chip" .. other.slot])
      if chipX and (chipX - ox) / scale + O.CHIP_MAX / 2 < cx then
        index = index + 1
      end
    end
  end
  G.Displays.Place(def, target, side, index)
end

function O.ChipUp(slot, key)
  local def = G.Displays.list[slot]
  if not def then
    return
  end
  if chipDrag and chipDrag.slot == slot then
    local from = chipDrag
    chipDrag = nil
    local chip = _G["CBar_Chip" .. slot]
    G.Try(chip, "StopMovingOrSizing")
    local x, y = G.FramePos(chip)
    if x and math.abs(x - from.x) + math.abs(y - from.y) >= O.DRAG_PIXELS then
      O.ChipDrop(def, x, y)
    end
  end
  picked = def.key
  O.Refresh()
end

---------------------------------------------------------------------------
-- The picked display
---------------------------------------------------------------------------

function O.PickedFlip(what)
  local def = pickedDef()
  if def then
    local cfg = G.Displays.Config(def)
    cfg[what] = not cfg[what]
    G.Displays.Rebuild()
    O.Refresh()
  end
end

function O.ApplyFormat()
  local def = pickedDef()
  if def and CBar_OptionsFormat then
    G.Displays.Config(def).fmt = CBar_OptionsFormat:GetText() or ""
    G.Displays.Rebuild()
  end
end

function O.ResetFormat()
  local def = pickedDef()
  if def then
    G.Displays.Config(def).fmt = def.fmt or ""
    G.Displays.Rebuild()
    refreshPicked()
  end
end

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------

function O.RowClick(i, kind)
  local def = O.LIST[i]
  if not def then
    return
  end
  local S = G.S()
  if kind == "check" then
    S[def.key] = not S[def.key]
  else
    local v = (tonumber(S[def.key]) or def.min) + (kind == "plus" and def.step or -def.step)
    S[def.key] = math.max(def.min, math.min(def.max, v))
  end
  G.Refresh()
  O.Refresh()
end

function O.RowEnter(i, frame)
  local def = O.LIST[i]
  if not def or not def.tip or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", 0, 0)
  GameTooltip:SetText(def.label, 1, 1, 1)
  GameTooltip:AddLine(def.tip, 0.9, 0.9, 0.9)
  G.Try(GameTooltip, "Show")
end

function O.ResetAll()
  G.ResetAll()
  O.Refresh()
  G.Print("every setting is back to its default.")
end
