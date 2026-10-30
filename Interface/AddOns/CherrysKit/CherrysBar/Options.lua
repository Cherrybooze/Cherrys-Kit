-- Cherry's Bar: the /cbar options window. On the left, one row per setting of the bars; on the
-- right, one row per display: which bar, which side, its place in the row and what it shows.
-- Below them, the text of the display being edited.

local G = CherrysBar
local O = {}
G.Options = O

O.GENERAL_ROWS = 12
O.DISPLAY_ROWS = 14

local function pct(v)
  return math.floor((tonumber(v) or 0) * 100 + 0.5) .. "%"
end

local function skinChoices()
  local list = {}
  for _, skin in ipairs(G.Bars.SKINS) do
    list[#list + 1] = { key = skin.key, label = skin.key }
  end
  return list
end

-- bar = "top" or "bottom": the setting lives in that bar's own table.
O.LIST = {
  { key = "show", bar = "top", kind = "check", label = "Show the top bar" },
  { key = "skin", bar = "top", kind = "choice", label = "Top bar style" },
  { key = "alpha", bar = "top", kind = "num", label = "Top bar opacity", min = 0.1, max = 1, step = 0.1, fmt = pct },
  { key = "show", bar = "bottom", kind = "check", label = "Show the bottom bar" },
  { key = "skin", bar = "bottom", kind = "choice", label = "Bottom bar style" },
  { key = "alpha", bar = "bottom", kind = "num", label = "Bottom bar opacity", min = 0.1, max = 1, step = 0.1, fmt = pct },
  { key = "textSize", kind = "num", label = "Text size", min = 9, max = 16, step = 1 },
  { key = "makeRoom", kind = "check", label = "Move game frames clear",
    tip = "Moves the player, target, party, buff and minimap frames down, and the action bar up, so the bars do not cover them. A frame you dragged far from the edge stays where it is." },
  { key = "tipsInCombat", kind = "check", label = "Tooltips in combat" },
  { key = "hideMenuBar", kind = "check", label = "Hide the game's menu bar",
    tip = "The Menu display on the bar opens the same windows." },
  { key = "hideXpBar", kind = "check", label = "Hide the game's XP bar" },
  { key = "hideDura", kind = "check", label = "Hide damaged-gear figure" },
}

local editing = "Menu"

local function settingTable(def)
  return def.bar and G.S().bars[def.bar] or G.S()
end

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

local function choiceLabel(list, value)
  for _, c in ipairs(list) do
    if c.key == value then
      return c.label
    end
  end
  return tostring(value)
end

local BAR_LABELS = { top = "Top", bottom = "Bottom", off = "Off" }
local NEXT_BAR = { top = "bottom", bottom = "off", off = "top" }

function O.Refresh()
  if not CBar_Options or not G.ready then
    return
  end
  CBar_OptionsTitle:SetText("Cherry's Bar " .. G.version)
  for i = 1, O.GENERAL_ROWS do
    local def = O.LIST[i]
    local row = part(i, "")
    if def and row then
      local v = settingTable(def)[def.key]
      part(i, "Label"):SetText(def.label)
      shown(part(i, "Check"), def.kind == "check")
      shown(part(i, "Minus"), def.kind == "num")
      shown(part(i, "Plus"), def.kind == "num")
      shown(part(i, "Value"), def.kind == "num")
      shown(part(i, "Choice"), def.kind == "choice")
      if def.kind == "check" then
        part(i, "Check"):SetChecked(v and 1 or nil)
      elseif def.kind == "num" then
        part(i, "Value"):SetText(def.fmt and def.fmt(v) or tostring(v))
      else
        part(i, "Choice"):SetText(choiceLabel(skinChoices(), v))
      end
      row:Show()
    elseif row then
      row:Hide()
    end
  end
  for i = 1, O.DISPLAY_ROWS do
    local def = G.Displays.list[i]
    local n = "CBar_OptD" .. i
    local row = _G[n]
    if def and row then
      local cfg = G.Displays.Config(def)
      _G[n .. "Name"]:SetText(def.title or def.label or def.key)
      _G[n .. "Bar"]:SetText(BAR_LABELS[cfg.bar] or cfg.bar)
      _G[n .. "Side"]:SetText(cfg.side == "right" and "Right" or "Left")
      _G[n .. "Icon"]:SetChecked(cfg.icon and 1 or nil)
      _G[n .. "Label"]:SetChecked(cfg.label and 1 or nil)
      _G[n .. "Color"]:SetChecked(cfg.color and 1 or nil)
      shown(_G[n .. "Mark"], def.key == editing)
      row:Show()
    elseif row then
      row:Hide()
    end
  end
  O.ShowEditing()
end

function O.ShowEditing()
  local def = G.Displays.byKey[editing]
  if not def then
    return
  end
  local name = def.title or def.label or def.key
  if def.tokens then
    CBar_OptionsEditing:SetText("Text of " .. name .. ":")
    CBar_OptionsTokens:SetText(def.tokens)
    CBar_OptionsFormat:SetText(G.Displays.Config(def).fmt)
    CBar_OptionsFormat:Show()
    CBar_OptionsApply:Show()
    CBar_OptionsFormatReset:Show()
  else
    CBar_OptionsEditing:SetText(name .. " has no text of its own.")
    CBar_OptionsTokens:SetText("")
    CBar_OptionsFormat:Hide()
    CBar_OptionsApply:Hide()
    CBar_OptionsFormatReset:Hide()
  end
end

function O.Toggle()
  if not CBar_Options then
    return
  end
  if CBar_Options:IsVisible() then
    CBar_Options:Hide()
  else
    O.Refresh()
    CBar_Options:Show()
  end
end

function O.RowClick(i, kind)
  local def = O.LIST[i]
  if not def then
    return
  end
  local t = settingTable(def)
  if kind == "check" then
    t[def.key] = not t[def.key]
  elseif kind == "minus" or kind == "plus" then
    local v = (tonumber(t[def.key]) or def.min) + (kind == "plus" and def.step or -def.step)
    v = math.floor(v / def.step + 0.5) * def.step
    t[def.key] = math.max(def.min, math.min(def.max, v))
  else
    local list = skinChoices()
    local at = 0
    for n, c in ipairs(list) do
      if c.key == t[def.key] then
        at = n
      end
    end
    t[def.key] = (list[at + 1] or list[1]).key
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

function O.DisplayClick(i, what)
  local def = G.Displays.list[i]
  if not def then
    return
  end
  local cfg = G.Displays.Config(def)
  if what == "bar" then
    G.Displays.SetBar(def, NEXT_BAR[cfg.bar] or "top")
  elseif what == "pick" then
    editing = def.key
  elseif what == "side" then
    cfg.side = cfg.side == "right" and "left" or "right"
    cfg.order = 1000 + def.slot
    G.Displays.Rebuild()
  elseif what == "earlier" then
    G.Displays.Move(def, -1)
  elseif what == "later" then
    G.Displays.Move(def, 1)
  elseif what == "icon" or what == "label" or what == "color" then
    cfg[what] = not cfg[what]
    G.Displays.Rebuild()
  end
  O.Refresh()
end

function O.ApplyFormat()
  local def = G.Displays.byKey[editing]
  if def and CBar_OptionsFormat then
    G.Displays.Config(def).fmt = CBar_OptionsFormat:GetText() or ""
    G.Displays.Rebuild()
  end
end

function O.ResetFormat()
  local def = G.Displays.byKey[editing]
  if def then
    G.Displays.Config(def).fmt = def.fmt or ""
    G.Displays.Rebuild()
    O.ShowEditing()
  end
end

function O.ResetAll()
  G.ResetAll()
  O.Refresh()
  G.Print("every setting is back to its default.")
end
