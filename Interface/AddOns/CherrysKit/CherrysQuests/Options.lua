-- Cherry's Quests: the /cq options window. One page of rows declared in CherrysQuests.xml:
-- a tick box, a value with - and + buttons, or a button that steps through choices.

local Q = CherrysQuests
local O = {}
Q.Options = O

O.ROWS = 20

local function pct(v)
  return math.floor((tonumber(v) or 0) * 100 + 0.5) .. "%"
end

local function choiceLabel(choices, value)
  for _, c in ipairs(choices) do
    if c.key == value then
      return c.label
    end
  end
  return choices[1] and choices[1].label or tostring(value)
end

O.SORTS = {
  { key = "level", label = "Level, low first" },
  { key = "leveldown", label = "Level, high first" },
  { key = "name", label = "Name" },
  { key = "track", label = "Order tracked" },
}

O.OUTLINES = {
  { key = "NORMAL", label = "None" },
  { key = "OUTLINE", label = "Outline" },
  { key = "THICK", label = "Thick outline" },
}

-- style = true: changing it sets the fonts again.
O.LIST = {
  { key = "shown", kind = "check", label = "Show the tracker" },
  { key = "replace", kind = "check", label = "Replace the game's tracker",
    tip = "Hides the game's quest tracker (and pbInfo's) while this one is shown. Unticked, they come back after Reload UI." },
  { key = "locked", kind = "check", label = "Lock position", tip = "Unlocked, drag the title bar to move the tracker." },
  { key = "scale", kind = "num", label = "Scale", min = 0.6, max = 2, step = 0.05, fmt = pct, style = true },
  { key = "width", kind = "num", label = "Width", min = 160, max = 420, step = 10 },
  { key = "font", kind = "choice", label = "Font", choices = Q.FontChoices, style = true,
    tip = "The extra fonts come with rom weakauras. Going back to the game font may need Reload UI." },
  { key = "outline", kind = "choice", label = "Font outline", choices = O.OUTLINES, style = true },
  { key = "titleSize", kind = "num", label = "Quest name size", min = 8, max = 22, step = 1, style = true },
  { key = "textSize", kind = "num", label = "Objective size", min = 8, max = 20, step = 1, style = true },
  { key = "bgAlpha", kind = "num", label = "Background", min = 0, max = 1, step = 0.1, fmt = pct },
  { key = "sort", kind = "choice", label = "Sort quests by", choices = O.SORTS },
  { key = "bars", kind = "check", label = "Progress bar under each quest" },
  { key = "fade", kind = "check", label = "Counts fade from red to green" },
  { key = "hideDone", kind = "check", label = "Hide finished objectives" },
  { key = "dailies", kind = "check", label = "Colour daily quests blue" },
  { key = "npcLine", kind = "check", label = "Show the picked NPC under a quest" },
  { key = "turnIn", kind = "check", label = "Ctrl+click list includes the turn-in NPC" },
  { key = "slot", kind = "num", label = "Tracking list slot", min = 0, max = 10, step = 1,
    fmt = function(v)
      return (tonumber(v) or 0) == 0 and "Game" or tostring(v)
    end,
    tip = "Game: the game's own quick track picks the place in the NPC tracking list. A number: Ctrl+click always replaces that slot." },
  { key = "clickBook", kind = "check", label = "Click opens the quest book",
    tip = "Unticked, a click folds the quest and a right click opens the quest book." },
  { key = "tooltip", kind = "check", label = "Tooltip on quests" },
}

local function choicesOf(def)
  if type(def.choices) == "function" then
    return def.choices()
  end
  return def.choices
end

local function widget(i, part)
  return _G["CQ_OptRow" .. i .. part]
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

function O.Refresh()
  if not CQ_Options then
    return
  end
  local S = Q.S()
  if CQ_OptionsTitle then
    CQ_OptionsTitle:SetText("Cherry's Quests " .. Q.version)
  end
  for i = 1, O.ROWS do
    local def = O.LIST[i]
    local row = widget(i, "")
    if def and row then
      widget(i, "Label"):SetText(def.label)
      local v = S[def.key]
      shown(widget(i, "Check"), def.kind == "check")
      shown(widget(i, "Minus"), def.kind == "num")
      shown(widget(i, "Plus"), def.kind == "num")
      shown(widget(i, "Value"), def.kind == "num")
      shown(widget(i, "Choice"), def.kind == "choice")
      if def.kind == "check" then
        widget(i, "Check"):SetChecked(v and 1 or nil)
      elseif def.kind == "num" then
        widget(i, "Value"):SetText(def.fmt and def.fmt(v) or tostring(v))
      elseif def.kind == "choice" then
        widget(i, "Choice"):SetText(choiceLabel(choicesOf(def), v))
      end
      row:Show()
    elseif row then
      row:Hide()
    end
  end
  if CQ_OptionsHint then
    CQ_OptionsHint:SetText("Ctrl+click a quest: next NPC to track. Ctrl+right-click: previous. Alt+click: track it again.")
  end
end

function O.Toggle()
  if not CQ_Options then
    return
  end
  if CQ_Options:IsVisible() then
    CQ_Options:Hide()
  else
    O.Refresh()
    CQ_Options:Show()
  end
end

function O.Set(def, value)
  local S = Q.S()
  S[def.key] = value
  if def.style then
    Q.Tracker.StyleChanged()
  else
    Q.Tracker.Refresh(true)
  end
  if def.key == "turnIn" then
    Q.Npcs.Forget()
  end
end

function O.Click(i, part)
  local def = O.LIST[i]
  if not def then
    return
  end
  local S = Q.S()
  if part == "check" then
    O.Set(def, not S[def.key])
  elseif part == "minus" or part == "plus" then
    local v = tonumber(S[def.key]) or def.min
    v = v + (part == "plus" and def.step or -def.step)
    v = math.max(def.min, math.min(def.max, v))
    v = math.floor(v / def.step + 0.5) * def.step
    O.Set(def, v)
  elseif part == "choice" then
    local list = choicesOf(def)
    local at = 0
    for n, c in ipairs(list) do
      if c.key == S[def.key] then
        at = n
      end
    end
    local nextChoice = list[at + 1] or list[1]
    O.Set(def, nextChoice.key)
  end
  O.Refresh()
end

function O.Enter(i, frame)
  local def = O.LIST[i]
  if not def or not def.tip or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  GameTooltip:SetText(def.label, 1, 1, 1)
  GameTooltip:AddLine(def.tip, 0.9, 0.9, 0.9)
  GameTooltip:Show()
end

function O.ResetPosition()
  local S = Q.S()
  S.x, S.y = nil, nil
  Q.Tracker.Position()
  Q.Print("tracker moved back to the top right.")
end

function O.Forget()
  local db = Q.DB()
  local who = Q.charName or "?"
  if type(db.chars[who]) == "table" then
    db.chars[who].picks = {}
  end
  Q.Npcs.Forget()
  Q.Tracker.Refresh(true)
  Q.Print("forgot this character's NPC picks.")
end
