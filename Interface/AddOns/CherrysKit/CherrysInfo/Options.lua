-- Cherry's Info: the unified /cinfo and /cq options window with 4 tabs (Quests, Tooltips & IDs,
-- Target & World, Chat & Macros). Uses the 20 option rows declared in CherrysQuests.xml:
-- a tick box, a value with - and + buttons, a choice cycler, or an action button.

local Q = CherrysQuests
local O = {}
Q.Options = O

O.ROWS = 20
O.tab = "quests"

O.TAB_ORDER = {
  { key = "quests", label = "Quests" },
  { key = "tooltips", label = "Tooltips & IDs" },
  { key = "target", label = "Target & World" },
  { key = "chat", label = "Chat & Macros" },
}

local function pct(v)
  return math.floor((tonumber(v) or 0) * 100 + 0.5) .. "%"
end

local function secs(v)
  return string.format("%.2fs", tonumber(v) or 0)
end

local function choiceLabel(choices, value)
  for _, c in ipairs(choices) do
    if c.key == value then
      return c.label
    end
  end
  return choices[1] and choices[1].label or tostring(value)
end

local function pbS()
  if type(pbInfoSettings) ~= "table" then
    pbInfoSettings = (type(pbInfo) == "table" and type(pbInfo.DefaultSettings) == "table" and Q.Copy(pbInfo.DefaultSettings)) or {}
  end
  return pbInfoSettings
end

local function pbGet(key, default)
  local s = pbS()
  if s[key] == nil then
    return default
  end
  return s[key]
end

local function pbSet(key, value)
  local s = pbS()
  s[key] = value
  if key == "GameTooltipAlpha" and GameTooltip then
    Q.Try(GameTooltip, "SetBackdropTileAlpha", value)
    Q.Try(GameTooltip, "SetBackdropEdgeAlpha", value)
  elseif key == "CASTINGBARHIDEDEFAULT" and type(pbInfo) == "table" and pbInfo.CastingBar and pbInfo.CastingBar.KeepHidden then
    pcall(pbInfo.CastingBar.KeepHidden)
  elseif key == "CASTINGBARSHOWCASTTIME" and not value and CastingBarText then
    Q.Try(CastingBarText, "Show")
  elseif key == "PLAYERINFOSAVEDATA" then
    if value and SaveVariables then
      SaveVariables("pbInfoPlayers")
    elseif not value then
      pbInfoPlayers = nil
    end
  end
  -- What pbInfo's own Save button ends with: the blood bars, chat log and tooltip read their settings again.
  if type(pbInfo) == "table" and type(pbInfo.LoadScripts) == "function" then
    pcall(pbInfo.LoadScripts)
  end
end

local function pbOpt(key, kind, label, extra)
  local def = {
    key = key,
    kind = kind,
    label = label,
    get = function()
      return pbGet(key, extra and extra.default)
    end,
    set = function(v)
      pbSet(key, v)
    end,
  }
  if extra then
    for k, v in pairs(extra) do
      def[k] = v
    end
  end
  return def
end

local function tiSettings()
  if type(TooltipIds) == "table" and type(TooltipIds.GetSettings) == "function" then
    return TooltipIds.GetSettings()
  end
  if type(TooltipIds_Settings) ~= "table" then
    TooltipIds_Settings = { Options = {}, TextColor = { r = 0.33, g = 0.86, b = 0.60 } }
  end
  TooltipIds_Settings.Options = TooltipIds_Settings.Options or {}
  TooltipIds_Settings.TextColor = TooltipIds_Settings.TextColor or { r = 0.33, g = 0.86, b = 0.60 }
  return TooltipIds_Settings
end

local function tiOpt(index, label, alsoIndex)
  return {
    key = "ti_" .. index,
    kind = "check",
    label = label,
    get = function()
      local opts = tiSettings().Options
      return opts[index] ~= false
    end,
    set = function(v)
      local opts = tiSettings().Options
      opts[index] = v and true or false
      if alsoIndex then
        opts[alsoIndex] = v and true or false
      end
    end,
  }
end

O.ID_COLORS = {
  { key = "mint", label = "Mint green", r = 0.33, g = 0.86, b = 0.60 },
  { key = "gold", label = "Gold", r = 1.00, g = 0.85, b = 0.35 },
  { key = "sky", label = "Sky blue", r = 0.50, g = 0.82, b = 1.00 },
  { key = "pink", label = "Cherry pink", r = 1.00, g = 0.50, b = 0.66 },
  { key = "white", label = "White", r = 0.95, g = 0.95, b = 0.95 },
}

local function currentIdColorKey()
  local c = tiSettings().TextColor or {}
  local best, bestDist = "mint", 999
  for _, item in ipairs(O.ID_COLORS) do
    local dr = (tonumber(c.r) or 0.33) - item.r
    local dg = (tonumber(c.g) or 0.86) - item.g
    local db = (tonumber(c.b) or 0.60) - item.b
    local dist = dr * dr + dg * dg + db * db
    if dist < bestDist then
      best, bestDist = item.key, dist
    end
  end
  return best
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

O.TIMESTAMPS = {
  { key = "%H:%M:%S", label = "24h (%H:%M:%S)" },
  { key = "%H:%M", label = "24h short (%H:%M)" },
  { key = "%I:%M:%S %p", label = "12h (%I:%M:%S %p)" },
  { key = "%I:%M %p", label = "12h short (%I:%M %p)" },
}

O.SEPARATORS = {
  { key = ".", label = "Dot (1.000)" },
  { key = ",", label = "Comma (1,000)" },
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

O.TABS = {
  quests = O.LIST,
  tooltips = {
    pbOpt("ENABLE", "check", "Enable pbInfo tooltips & features", { default = true }),
    pbOpt("MODIFYTOOLTIP", "check", "Richer unit tooltips (level, HP, class)", { default = true }),
    pbOpt("HEALTHCOLORFADE", "check", "Health colour fade in tooltips", { default = true }),
    pbOpt("SHOWMANA", "check", "Show mana, rage, energy and focus", { default = true }),
    pbOpt("TOOLTIPSHOWRACE", "check", "Show unit race in tooltips", { default = true }),
    pbOpt("TOOLTIPSHOWPLAYERINFO", "check", "Show player guild and title info", { default = false }),
    pbOpt("SHOWMOUSEOVERTARGET", "check", "Show mouseover unit's target", { default = false }),
    pbOpt("ALLNPC", "check", "Detailed tooltips for all NPCs", { default = false }),
    pbOpt("SHOWMATERIALINFO", "check", "Gathering material counts (bag & bank)", { default = true }),
    pbOpt("STICKYTOOLTIP", "check", "Fixed (sticky) tooltip position", { default = false }),
    pbOpt("GameTooltipAlpha", "num", "Tooltip background opacity", { default = 1, min = 0.1, max = 1, step = 0.1, fmt = pct }),
    tiOpt(1, "Show Unit IDs in tooltips"),
    tiOpt(2, "Show Item IDs in tooltips"),
    tiOpt(3, "Show Skill IDs in tooltips"),
    tiOpt(4, "Show Buff & Debuff IDs"),
    tiOpt(5, "Show Title IDs"),
    tiOpt(6, "Show Item Shop (Mall) IDs"),
    tiOpt(7, "Show Store & Hyperlink IDs", 8),
    tiOpt(9, "Show Quest IDs in quest book"),
    {
      key = "ti_color",
      kind = "choice",
      label = "Tooltip ID text colour",
      choices = O.ID_COLORS,
      get = currentIdColorKey,
      set = function(v)
        for _, item in ipairs(O.ID_COLORS) do
          if item.key == v then
            tiSettings().TextColor = { r = item.r, g = item.g, b = item.b }
            return
          end
        end
      end,
    },
  },
  target = {
    {
      key = "portraithp",
      kind = "check",
      label = "Target health % on its portrait",
      tip = "Shows your target's health percentage on its portrait, coloured from green to red.",
      get = function()
        return type(PortraitHP) ~= "table" or PortraitHP.enable ~= false
      end,
      set = function(v)
        if type(PortraitHP) == "table" and type(PortraitHP.SetEnabled) == "function" then
          local ok, done, reason = pcall(PortraitHP.SetEnabled, v, true)
          if not ok or done == false then
            Q.Print("target health: " .. tostring(ok and reason or done))
          end
        end
      end,
    },
    pbOpt("CASTINGBARHIDEDEFAULT", "check", "Hide the game's cast bar", { default = true,
      tip = "Hides the game's own cast bar so rom weakauras' My cast aura can take its place." }),
    pbOpt("CASTINGBARSHOWCASTTIME", "check", "Show cast time on default cast bar", { default = false }),
    pbOpt("CASTINGBARMOVEONLOAD", "check", "Use saved custom cast bar position", { default = false }),
    {
      key = "move_castbar",
      kind = "action",
      label = "Custom cast bar position",
      buttonLabel = "Move cast bar",
      run = function()
        if pbInfoCastingBar_MovingFrame and pbInfoCastingBar_MovingFrame.Show then
          if CQ_Options then CQ_Options:Hide() end
          pbInfoCastingBar_MovingFrame:Show()
        end
      end,
    },
    {
      key = "move_tooltip",
      kind = "action",
      label = "Fixed tooltip box position",
      buttonLabel = "Move tooltip box",
      run = function()
        if pbInfoTooltipBorder and pbInfoTooltipBorder.Show then
          if CQ_Options then CQ_Options:Hide() end
          pbInfoTooltipBorder:Show()
        end
      end,
    },
    pbOpt("MODIFYBLOODBARS", "check", "HP numbers on overhead health bars", { default = true }),
    pbOpt("BLOODBARSCOLORFADE", "check", "Overhead health bar colour fade", { default = false }),
    pbOpt("BloodBarsDelay", "num", "Overhead health bar refresh delay", { default = 0.2, min = 0.05, max = 1.0, step = 0.05, fmt = secs }),
    pbOpt("AUTOREPAIRALL", "check", "Auto-repair when opening a store", { default = true }),
    pbOpt("SHOWCLOCKTOOLTIP", "check", "Clock tooltip on minimap daylight icon", { default = false }),
    pbOpt("PLAYERINFOSAVEDATA", "check", "Save learned player class & level cache", { default = false }),
    {
      key = "more_pbinfo",
      kind = "action",
      label = "Everything else pbInfo can do",
      buttonLabel = "Open pbInfo's window",
      tip = "The rest of pbInfo's settings: material counts per bag and bank, sticky tooltips everywhere, its older quest tracker and extra languages.",
      run = function()
        if pbInfoConfig and pbInfoConfig.Show then
          if CQ_Options then CQ_Options:Hide() end
          pbInfoConfig:Show()
          pbInfo.Config.TabClick()
          pbInfoConfig_PageTooltip:Show()
        end
      end,
    },
  },
  chat = {
    pbOpt("CHATFRAMEFILTERTITLES", "check", "Hide channel titles ([Zone], [Party])", { default = false }),
    pbOpt("CHATFRAMEHIDEXPTP", "check", "Hide XP and TP gain messages", { default = false }),
    pbOpt("CHATFRAMEHIDEXPTPDEBT", "check", "Hide XP and TP debt messages", { default = false }),
    pbOpt("CHATFRAMEHIDEPROGRESS", "check", "Hide crafting & gathering progress", { default = false }),
    pbOpt("CHATFRAMEHIDEPROGRESSGATHER", "check", "Hide gathering progress only", { default = false }),
    pbOpt("CHATFRAMESHOWPLAYERINFO", "check", "Show player class & level in chat", { default = true }),
    pbOpt("TIMESTAMP", "check", "Show timestamps in chat", { default = true }),
    pbOpt("TIMESTAMPNOTINCOMBATLOG", "check", "No timestamps in combat log", { default = true }),
    pbOpt("TimeStampFormat", "choice", "Timestamp format", { default = "%H:%M:%S", choices = O.TIMESTAMPS }),
    pbOpt("ThousandsSeparatorFormat", "choice", "Thousands separator", { default = ".", choices = O.SEPARATORS }),
    pbOpt("CHATLOG", "check", "Keep whisper & chat history log", { default = true }),
    pbOpt("ChatLogMaxLinesPerChat", "num", "Max history lines per chat", { default = 99, min = 10, max = 200, step = 10 }),
    {
      key = "emi_enabled",
      kind = "check",
      label = "Extended Macro Icons (10,500+ icons)",
      tip = "Replaces the macro icon picker with 58 categories of extra icons. Applies after Reload UI.",
      get = function()
        return type(CherrysEMI) ~= "table" or not CherrysEMI.IsSwitchedOff()
      end,
      set = function(v)
        if type(CherrysEMI) == "table" then
          CherrysEMI.SetEnabled(v)
          Q.Print("Extended Macro Icons " .. (v and "on" or "off") .. " after Reload UI.")
        end
      end,
    },
    {
      key = "emi_open",
      kind = "action",
      label = "Extended Macro Icons window",
      buttonLabel = "Open macros (/emi)",
      run = function()
        if type(CherrysEMI) == "table" and type(CherrysEMI.Slash) == "function" then
          CherrysEMI.Slash("")
        end
      end,
    },
  },
}

O.HINTS = {
  quests = "Ctrl+click a quest: next NPC to track. Ctrl+right-click: previous. Alt+click: track it again.",
  tooltips = "Tooltip and ID changes apply at once. Hover a monster at full HP once so its max HP is learned.",
  target = "Target portrait %, cast bar and world options apply at once.",
  chat = "Chat filters and timestamps apply at once. Extended Macro Icons (/emi) applies after Reload UI.",
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

function O.CurrentList()
  return O.TABS[O.tab] or O.LIST
end

local function getValue(def, S)
  if def.get then
    return def.get()
  end
  return S[def.key]
end

function O.Refresh()
  if not CQ_Options then
    return
  end
  local S = Q.S()
  local list = O.CurrentList()
  if CQ_OptionsTitle then
    CQ_OptionsTitle:SetText("Cherry's Info " .. Q.version)
  end
  for idx, tab in ipairs(O.TAB_ORDER) do
    local btn = _G["CQ_Tab" .. idx]
    if btn and btn.SetText then
      local active = (O.tab == tab.key)
      btn:SetText(active and ("|cffffd15a" .. tab.label .. "|r") or tab.label)
    end
  end
  local onQuests = (O.tab == "quests")
  shown(CQ_OptionsReset, onQuests)
  shown(CQ_OptionsForget, onQuests)
  for i = 1, O.ROWS do
    local def = list[i]
    local row = widget(i, "")
    if def and row then
      widget(i, "Label"):SetText(def.label)
      local v = getValue(def, S)
      shown(widget(i, "Check"), def.kind == "check")
      shown(widget(i, "Minus"), def.kind == "num")
      shown(widget(i, "Plus"), def.kind == "num")
      shown(widget(i, "Value"), def.kind == "num")
      shown(widget(i, "Choice"), def.kind == "choice" or def.kind == "action")
      if def.kind == "check" then
        widget(i, "Check"):SetChecked(v and 1 or nil)
      elseif def.kind == "num" then
        widget(i, "Value"):SetText(def.fmt and def.fmt(v) or tostring(v))
      elseif def.kind == "choice" then
        widget(i, "Choice"):SetText(choiceLabel(choicesOf(def), v))
      elseif def.kind == "action" then
        widget(i, "Choice"):SetText(def.buttonLabel or def.label)
      end
      row:Show()
    elseif row then
      row:Hide()
    end
  end
  if CQ_OptionsHint then
    CQ_OptionsHint:SetText(O.HINTS[O.tab] or O.HINTS.quests)
  end
end

function O.SelectTab(tab)
  if O.TABS[tab] then
    O.tab = tab
    O.Refresh()
  end
end

function O.OpenTab(tab)
  if O.TABS[tab] then
    O.tab = tab
  end
  if not CQ_Options then
    return
  end
  O.Refresh()
  CQ_Options:Show()
end

function O.Toggle(tab)
  if not CQ_Options then
    return
  end
  if CQ_Options:IsVisible() and (not tab or O.tab == tab) then
    CQ_Options:Hide()
  else
    if tab and O.TABS[tab] then
      O.tab = tab
    end
    O.Refresh()
    CQ_Options:Show()
  end
end

function O.Set(def, value)
  if def.set then
    def.set(value)
    return
  end
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
  local list = O.CurrentList()
  local def = list[i]
  if not def then
    return
  end
  local S = Q.S()
  local current = getValue(def, S)
  if part == "check" then
    O.Set(def, not current)
  elseif part == "minus" or part == "plus" then
    local v = tonumber(current) or def.min
    v = v + (part == "plus" and def.step or -def.step)
    v = math.max(def.min, math.min(def.max, v))
    v = math.floor(v / def.step + 0.5) * def.step
    O.Set(def, v)
  elseif part == "choice" then
    if def.kind == "action" and type(def.run) == "function" then
      def.run()
      return
    end
    local choices = choicesOf(def)
    local at = 0
    for n, c in ipairs(choices) do
      if c.key == current then
        at = n
      end
    end
    local nextChoice = choices[at + 1] or choices[1]
    O.Set(def, nextChoice.key)
  end
  O.Refresh()
end

function O.Enter(i, frame)
  local def = O.CurrentList()[i]
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
