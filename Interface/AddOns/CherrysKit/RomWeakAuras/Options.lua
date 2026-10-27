-- Options.lua: the /rwa window, laid out like Cherry's KittyCombo: a list of auras (preview, name,
-- description, what it tracks) and, behind each Edit button, an editor for that one aura in sections.
-- It replaces the WeakAurasOptions addon (AceGUI) with plain RoM buttons and edit boxes:
-- cycle buttons stand in for dropdowns (left click = next, right click = previous).

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers

local WIN_W, WIN_H = 800, 580
local ROWS = 12
local ROW_H = 32
local LIST_TOP = 72 -- first list row, under the column titles
local PREVIEW_H = 70 -- live preview box at the top of the Look section
local EDIT_TOP = 76 -- first editor section, under the Back button
local COL1, COL2 = 16, 408 -- editor columns
local SECTION_W = 372
local LX, WX = COL1, COL1 + 100 -- label and widget x of the editor column being built

local ui

local UNITS = { "player", "target", "party1", "party2", "party3", "party4", "party5", "pet" }
local TRIGGER_TYPES = { "aura", "status", "custom" }
local TRIGGER_LABELS = { aura = "Buff / debuff", status = "Status", custom = "Custom Lua" }
local CHECKS = { "health", "mana", "skill", "combat", "target", "cast", "cooldown", "class" }
local CHECK_LABELS = {
  health = "Health",
  mana = "Mana",
  skill = "Rage/energy/focus",
  combat = "In combat",
  target = "Has target",
  cast = "Casting",
  cooldown = "Skill cooldown",
  class = "Class",
}
local OPS = { "none", "<", "<=", ">", ">=", "==" }
local COND_VARS = { "none", "remaining", "stacks", "percent", "value" }
local COLORS = {
  { "White", { 1, 1, 1, 1 } },
  { "Red", { 0.9, 0.15, 0.15, 1 } },
  { "Green", { 0.2, 0.7, 0.3, 1 } },
  { "Blue", { 0.25, 0.5, 1, 1 } },
  { "Yellow", { 1, 0.85, 0.2, 1 } },
  { "Orange", { 1, 0.5, 0.1, 1 } },
  { "Purple", { 0.65, 0.35, 0.9, 1 } },
  { "Cyan", { 0.3, 0.85, 0.9, 1 } },
}
local START_ANIMS = { "none", "fade", "slide" }
local MAIN_ANIMS = { "none", "pulse", "flash", "bounce" }
local MEDIA = RWA.MEDIA or { textureCategories = {}, textures = {}, sounds = {}, fonts = {} }
local SOUNDS = { "none" }
for _, f in ipairs(MEDIA.sounds) do
  SOUNDS[#SOUNDS + 1] = f
end
local FONTS = { "default" }
for _, f in ipairs(MEDIA.fonts) do
  FONTS[#FONTS + 1] = f
end
local PICK_COLS, PICK_ROWS, PICK_CELL = 10, 5, 70

local function indexOf(list, value)
  for i, v in ipairs(list) do
    if v == value then
      return i
    end
  end
  return 0
end

local function colorName(c)
  for _, entry in ipairs(COLORS) do
    local v = entry[2]
    if c and math.abs((c[1] or 0) - v[1]) < 0.01 and math.abs((c[2] or 0) - v[2]) < 0.01 and math.abs((c[3] or 0) - v[3]) < 0.01 then
      return entry[1]
    end
  end
  return "Custom"
end

local function selected()
  return ui and ui.selected and RWA.GetAura(ui.selected)
end

local function newTrigger()
  return { type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active" }
end

-- The extra display being edited (ui.elemIndex > 0), or nil for the main display.
local function selElement()
  local data = selected()
  local i = ui and ui.elemIndex or 0
  return i > 0 and data and data.elements and data.elements[i] or nil
end

-- The triggers of the selected display: an extra display with its own trigger has just that one,
-- the main display (and extra displays that follow it) has every trigger no extra display owns.
local function displayTriggers(data)
  local e = selElement()
  local from = e and tonumber(e.from) or 0
  if from > 0 and data.triggers[from] then
    return { from }, true
  end
  local owned = RWA.OwnedTriggers(data)
  local list = {}
  for i = 1, #data.triggers do
    if not owned[i] then
      list[#list + 1] = i
    end
  end
  return list, false
end

-- Removes trigger i and renumbers what points at triggers after it.
local function removeTrigger(data, i)
  table.remove(data.triggers, i)
  for _, e in ipairs(data.elements or {}) do
    local from = tonumber(e.from) or 0
    if from == i then
      e.from = 0
    elseif from > i then
      e.from = from - 1
    end
  end
  for _, c in ipairs(data.conditions or {}) do
    if c.trigger == i then
      c.trigger = 1
    elseif (c.trigger or 1) > i then
      c.trigger = c.trigger - 1
    end
  end
end

-- The trigger being edited: the one picked in the Trigger section's dropdown (ui.trigIndex),
-- among the selected display's triggers.
local function trigger1()
  local data = selected()
  if not data then
    return nil
  end
  if not data.triggers[1] then
    data.triggers[1] = newTrigger()
  end
  local list = displayTriggers(data)
  if #list == 0 then
    -- every trigger belongs to an extra display: give the main display one again
    table.insert(data.triggers, newTrigger())
    list = { #data.triggers }
  end
  local i = list[1]
  for _, j in ipairs(list) do
    if j == ui.trigIndex then
      i = j
    end
  end
  ui.trigIndex = i
  return data.triggers[i]
end

local function cond1(create)
  local data = selected()
  if not data then
    return nil
  end
  if not data.conditions[1] and create then
    data.conditions[1] = { trigger = 1, var = "remaining", op = "<", value = 3, set = { color = { 0.9, 0.15, 0.15, 1 } } }
  end
  return data.conditions[1]
end

---------------------------------------------------------------------------
-- Control helpers. Each control is a table { objs = {...}, refresh = fn }.
---------------------------------------------------------------------------

local controls = {}

local function at(obj, x, y)
  W.SetPoint(obj, "TOPLEFT", ui.win, "TOPLEFT", x, y)
  if ui.building then
    -- Editor objects are sorted by column, so a dropdown can use the other column's space.
    table.insert(ui.colObjs[x >= COL2 - 10 and 2 or 1], obj)
  end
end

local function label(text, x, y, w)
  local fs = W.FontString(ui.win, "OVERLAY", 12)
  W.SetJustify(fs, "LEFT")
  W.SetSize(fs, w or 96, 20)
  at(fs, x, y)
  W.SetText(fs, text)
  return fs
end

-- Look shared with Cherry's KittyCombo: dark navy panels with thin golden borders, gold headings.
local THEME = {
  bg = { 0.06, 0.09, 0.14, 0.96 },
  title = { 0.04, 0.06, 0.10, 1 },
  bar = { 0.10, 0.15, 0.23, 1 },
  panel = { 0.035, 0.055, 0.09, 1 },
  gold = { 0.85, 0.66, 0.28, 1 },
  darkGold = { 0.45, 0.34, 0.14, 1 },
  dimGold = { 0.55, 0.43, 0.20, 0.7 },
  divider = { 0.16, 0.20, 0.28, 1 },
}
RWA.THEME = THEME
local GOLD_TEXT = "|cffffc840"

-- A thin border of four lines around x, y, w, h (window coordinates). Returns the lines.
local function goldBox(x, y, w, h, color, thick)
  color = color or THEME.gold
  thick = thick or 1
  local lines = {}
  local function line(lx, ly, lw, lh)
    local t = W.Texture(ui.win, "ARTWORK", "Square_FullWhite")
    W.SetSize(t, lw, lh)
    W.SetPoint(t, "TOPLEFT", ui.win, "TOPLEFT", lx, ly)
    W.SetColor(t, color[1], color[2], color[3], color[4] or 1)
    lines[#lines + 1] = t
  end
  line(x, y, w, thick)
  line(x, y + h - thick, w, thick)
  line(x, y, thick, h)
  line(x + w - thick, y, thick, h)
  return lines
end

local function setShown(objs, on)
  for _, o in ipairs(objs) do
    W.SetShown(o, on)
  end
end

-- Mouseover help for the editor's boxes and dropdowns, keyed by row label and position
-- ("Text#2" = the second control on the "Text" row): a title, then how-to lines.
local TIPS = {
  ["Name#1"] = { "Name", "Type a name for this aura, then press Save.", "Each aura needs its own name; it is also the name in share codes." },
  ["Description#1"] = { "Description", "A few words on what this aura is for.", "Shown in the list next to the name. Press Save to keep it." },
  ["Display#1"] = { "Main display", "Click: select it (green when there are several); the rows", "below and the Trigger section edit the selected display.", "Right click: change its type (Icon, Bar, Text, Texture...).", "+ adds more displays: a timer, an icon..." },
  ["Side#1"] = { "Side", "Where this display sits next to the main one:", "left, right, above, below, or in the middle on top of it." },
  ["Size / text#1"] = { "Size", "Icon: width and height in pixels. Text: font size.", "Empty = the height of the main display. Press Save." },
  ["Size / text#2"] = { "Text", "What a text display says. Codes:", "%n name   %p time left or value   %t duration or maximum", "%s stacks   %v value   %pct percent   %e time since it started", "Example: %e shows how long you have been in combat. Press Save." },
  ["Type#1"] = { "Trigger type", "Buff / debuff: a buff or debuff by name or ID.", "Status: health, mana, combat, target, casting, cooldown, class.", "Custom Lua: your own code." },
  ["Type#2"] = { "Unit", "Whose buffs or status to check: you, your target, party members or pet." },
  ["Looks for#1"] = { "Buff or debuff", "Look for a helpful buff or a harmful debuff." },
  ["Looks for#2"] = { "When to show", "Show if active: while it is on.", "Show if missing: a reminder while it is NOT on.", "Always show: always, with its time when on." },
  ["Name or ID#1"] = { "Buff / debuff names", "One or more names or IDs, separated by commas.", "Example: Holy Seal, 500123. TooltipIds (/ti) shows IDs on tooltips.", "Leave empty to match any. Press Save." },
  ["Check#1"] = { "Check", "What to watch: health, mana, rage/energy/focus, combat,", "having a target, casting, a skill cooldown, or the class." },
  ["Show when#1"] = { "Compare", "always = show all the time; or show only when the value is", "<, <=, >, >= or == the number next to it." },
  ["Show when#2"] = { "Number", "The number to compare with, e.g. 30. Press Save." },
  ["Show when#3"] = { "Value or percent", "Compare the plain value (e.g. 2500 health) or the percent (e.g. 30%)." },
  ["Skill name or ID#1"] = { "Skill", "The skill's name or ID, as in your skill book. Press Save." },
  ["Skill name or ID#2"] = { "When to show", "Always, only when ready, or only while on cooldown." },
  ["Lua code#1"] = { "Custom Lua", "The body of a function that returns true to show.", "Example: return UnitHealth(\"target\") < 1000", "It may also return a table: return true, { name = \"Execute!\" }. Press Save." },
  ["When#1"] = { "Condition", "Change the colour when this value crosses a number:", "time left (remaining), stacks, percent or value. none = off." },
  ["When#2"] = { "Compare", "How to compare it with the number: <, <=, >, >= or ==." },
  ["When#3"] = { "Number", "E.g. 30 with percent < 30 turns the bar red under 30%. Press Save." },
  ["When#4"] = { "Colour", "The colour to use while the condition is true." },
  ["Combat / class#1"] = { "Combat", "Load the aura any time, only in combat or only out of combat." },
  ["Combat / class#2"] = { "Class", "Only for this class, e.g. Mage (main or secondary). Empty = any. Press Save." },
  ["Text#1"] = { "Main text", "The main line of text. Codes:", "%n name   %p time left or value   %t duration or maximum", "%s stacks   %v value   %pct percent   %e time since it started", "Bars show it on the left, icons in the middle. Press Save." },
  ["Text#2"] = { "Second text", "A second line: on the right of a bar, the corner of an icon.", "Example: %v / %t shows 7395 / 7395 health. Press Save." },
  ["Size  W / H / font#1"] = { "Width", "Width in pixels, e.g. 220 for a bar, 48 for an icon. Press Save." },
  ["Size  W / H / font#2"] = { "Height", "Height in pixels, e.g. 22 for a bar. Press Save." },
  ["Size  W / H / font#3"] = { "Font size", "Size of the text, e.g. 14. Press Save." },
  ["Size  W / H / font#4"] = { "Font", "The text's font; default is Fira Sans." },
  ["Position X / Y#1"] = { "X", "Left (-) or right (+) of the anchor, in pixels.", "Easier: drag the aura on screen while this window is open." },
  ["Position X / Y#2"] = { "Y", "Up (-) or down (+) from the anchor, in pixels.", "The arrows move it 5 pixels; dragging works too." },
  ["Colour#1"] = { "Colour", "The main colour of the bar, texture or text." },
  ["Icon#1"] = { "Icon", "A game icon path to always show, e.g. interface/icons/skill_mag1.", "Empty = the buff's or skill's own icon. Press Save." },
  ["Animation#1"] = { "Start animation", "How it appears and disappears: fade or slide." },
  ["Animation#2"] = { "Loop animation", "While shown: pulse, flash or bounce." },
  ["Sound on show#1"] = { "Sound", "Plays when the aura appears (not while this window is open).", "Play previews it. Sounds need interface sounds on." },
  ["All auras volume#1"] = { "All auras volume", "Game = follow the game's volume. 25-100% = play aura sounds", "at that level even when game sounds are turned down." },
  ["All auras volume#2"] = { "Channel", "The game volume that carries addon sounds: interface (tested)." },
}

-- Gives the next control on the current row its tooltip from TIPS.
local function addTip(obj)
  if not ui or not ui.building or not ui.lastLabel then
    return
  end
  ui.tipCount = ui.tipCount or {}
  local key = ui.lastLabel
  ui.tipCount[key] = (ui.tipCount[key] or 0) + 1
  local tip = TIPS[key .. "#" .. ui.tipCount[key]]
  if tip and obj then
    W.Tooltip(obj, unpack(tip))
  end
end

-- An edit box bound to a field: get() fills it, set(text) stores it when Save is pressed.
local function field(x, y, w, get, set)
  local box, bg = W.EditBox(ui.win, w, 20)
  at(box, x, y)
  addTip(box)
  local c = {
    objs = { box, bg },
    refresh = function()
      local v = get()
      W.SetText(box, v == nil and "" or tostring(v))
    end,
    save = function()
      set(W.GetText(box))
    end,
  }
  table.insert(controls, c)
  return c
end

---------------------------------------------------------------------------
-- Dropdown lists. RoM has no dropdown widget we can script, so a list of choices opens in the
-- other editor column (which hides meanwhile), 24 per page, and stays open until a choice is
-- picked, the same button is clicked again, Close is pressed or anything else is clicked.
---------------------------------------------------------------------------

-- Short explanations shown next to choices in dropdowns, for players new to WeakAuras.
-- Keys are "<row label>/<value>", or just the value.
local DESCRIBE = {
  ["Display menu/type"] = "switch what this display draws",
  ["Display menu/remove"] = "delete this display (asks first)",
  class = "always on: the class combo and its icon",
  ["Display to edit/add"] = "another icon or text on this aura",
  ["Element type/icon"] = "a small icon",
  ["Element type/text"] = "a line of text (%n, %p, %s...)",
  ["From/0"] = "whatever the aura is showing",
  ["Side/LEFT"] = "left of the aura",
  ["Side/RIGHT"] = "right of the aura",
  ["Side/TOP"] = "above the aura",
  ["Side/BOTTOM"] = "below the aura",
  ["Side/CENTER"] = "on top of the aura, in the middle",
  ["Trigger to edit/add"] = "a new buff trigger; set it up below",
  ["Combine/all"] = "show only when every trigger is true",
  ["Combine/any"] = "show when at least one trigger is true",
  ["Delete/yes"] = "remove it from this aura",
  ["Delete/no"] = "keep it",
  ["All auras volume/0"] = "follow the game's own volume",
  ["All auras volume/100"] = "full, even if game sounds are turned down",
  ["Channel/both"] = "set interface and effects (safe default)",
  ["Channel/interface"] = "only interface sounds (/rwa channeltest)",
  ["Channel/effects"] = "only sound effects (/rwa channeltest)",
  icon = "square icon with a timer, like a buff",
  aurabar = "bar that runs down, with name and time",
  kittytracker = "next KittyCombo skills, 1-3 icons",
  kitty = "a saved KittyCombo rotation (KittyTracker)",
  recent = "hits, damage or any event in the past 0.5-10 seconds",
  lastcast = "the last spell a unit cast and how long ago",
  text = "just text, e.g. a big warning",
  texture = "a picture or shape, e.g. a glowing ring",
  aura = "a buff or debuff is on (or missing)",
  status = "health, mana, combat, casting, cooldown",
  custom = "your own Lua code",
  player = "you",
  target = "your current target",
  pet = "your pet",
  HELPFUL = "a buff",
  HARMFUL = "a debuff",
  active = "while it is on",
  missing = "while it is NOT on (reminder)",
  always = "always, with its time when on",
  ready = "when the skill is ready",
  health = "health",
  mana = "mana",
  skill = "rage, energy or focus",
  combat = "while you are fighting",
  ["Check/target"] = "while you have a target",
  cast = "while casting, with cast time",
  ["Check/cooldown"] = "a skill's cooldown",
  fade = "fades in and out",
  slide = "slides in from below",
  pulse = "grows and shrinks",
  flash = "blinks",
  bounce = "hops up and down",
  remaining = "seconds left",
  stacks = "number of stacks",
  percent = "percent (health, bar)",
  value = "the number itself",
  any = "always",
  ["in"] = "only in combat",
  out = "only out of combat",
}

-- Small pictures next to choices: what each display type looks like, and colour swatches.
local function dropPreview(c, v)
  if c.title == "Display" then
    if v == "icon" then
      return W.TexturePath("exclamation-mark"), { 1, 1, 1 }
    elseif v == "aurabar" then
      return W.TexturePath("Statusbar_Clean"), { 0.2, 0.7, 0.3 }
    elseif v == "texture" then
      return W.TexturePath("ring_glow3"), { 1, 0.8, 0.2 }
    elseif v == "kittytracker" then
      return W.TexturePath("arrows_target"), { 1, 0.6, 0.9 }
    end
    return nil
  end
  local name = string.gsub(tostring(v), "^%-> ", "")
  for _, e in ipairs(COLORS) do
    if e[1] == name then
      return W.TexturePath("Square_FullWhite"), e[2]
    end
  end
end

local function describe(c, v)
  return DESCRIBE[(c.title or "") .. "/" .. tostring(v)] or DESCRIBE[tostring(v)]
end

local DROP_COLS, DROP_ROWS = 2, 12
local DROP_PER = DROP_COLS * DROP_ROWS
local refreshDrop, openDrop, kittyAsk

local function dropValues(c)
  return type(c.values) == "function" and c.values() or c.values
end

local function hideDrop()
  local d = ui and ui.drop
  if d then
    d.open = false
    d.owner = nil
    setShown(d.objs, false)
  end
end

local function closeDrop()
  local d = ui and ui.drop
  if d and d.open then
    d.open = false
    d.owner = nil
    setShown(d.objs, false)
    RWA.RefreshEditor()
  end
end

local function buildDrop()
  local win = ui.win
  local d = { objs = {}, items = {}, mine = {}, page = 0 }
  ui.drop = d
  local function add(obj, dx, dy)
    table.insert(d.objs, { obj = obj, dx = dx, dy = dy })
    return obj
  end
  d.title = add(label("", 0, 0, 260), 0, EDIT_TOP + 2)
  local close = add(W.Button(win, "Close", 70, 22, function()
    closeDrop()
  end), 290, EDIT_TOP)
  d.mine[close] = true
  for i = 1, DROP_PER do
    local item = {}
    local col = math.floor((i - 1) / DROP_ROWS)
    local row = (i - 1) % DROP_ROWS
    item.btn = add(W.Button(win, "", 178, 24, function()
      local c = d.owner
      local list = c and dropValues(c)
      if list and item.index and item.index <= #list then
        c.set(list[item.index])
        d.open = false
        d.owner = nil
        setShown(d.objs, false)
        RWA.RefreshAuraFromEditor()
        -- a menu entry can lead on to another list (Change type, Remove's confirmation)
        local nextDrop = ui.nextDrop
        ui.nextDrop = nil
        if nextDrop then
          openDrop(nextDrop)
        end
      end
    end), col * 184, EDIT_TOP + 28 + row * 28)
    d.mine[item.btn] = true
    if i <= DROP_ROWS then
      -- "-" removes this entry (lists whose owner has onRemove, like triggers)
      item.del = add(W.Button(win, "-", 24, 24, function()
        local c = d.owner
        local list = c and dropValues(c)
        if c and c.onRemove and list and item.index and list[item.index] ~= nil then
          c.onRemove(list[item.index])
        end
      end), 338, EDIT_TOP + 28 + row * 28)
      d.mine[item.del] = true
    end
    item.tex = W.Texture(item.btn, "OVERLAY")
    W.SetSize(item.tex, 18, 18)
    W.SetPoint(item.tex, "LEFT", item.btn, "LEFT", 6, 0)
    d.items[i] = item
  end
  local pagesY = EDIT_TOP + 28 + DROP_ROWS * 28 + 4
  local prev = add(W.Button(win, "<", 30, 22, function()
    d.page = d.page - 1
    refreshDrop()
  end), 0, pagesY)
  d.pageText = add(label("", 0, 0, 60), 36, pagesY + 2)
  local nextBtn = add(W.Button(win, ">", 30, 22, function()
    d.page = d.page + 1
    refreshDrop()
  end), 100, pagesY)
  d.mine[prev], d.mine[nextBtn] = true, true
  d.paging = { prev, d.pageText, nextBtn }
  -- Unpack the {obj, dx, dy} records into a plain list for setShown, keeping the offsets.
  d.layout = d.objs
  d.objs = {}
  for _, rec in ipairs(d.layout) do
    table.insert(d.objs, rec.obj)
  end
  setShown(d.objs, false)
end

refreshDrop = function()
  local d = ui.drop
  local c = d.owner
  local list = dropValues(c)
  local maxPage = math.max(0, math.floor((#list - 1) / DROP_PER))
  d.page = math.max(0, math.min(d.page, maxPage))
  local current = c.get()
  -- With explanations, one wide column (12 per page); otherwise two columns of 12.
  local removable = c.onRemove ~= nil
  local wide = removable
  for _, v in ipairs(list) do
    wide = wide or describe(c, v) ~= nil
  end
  local per = wide and DROP_ROWS or DROP_PER
  maxPage = math.max(0, math.floor((#list - 1) / per))
  d.page = math.max(0, math.min(d.page, maxPage))
  for i, item in ipairs(d.items) do
    local index = d.page * per + i
    item.index = index
    W.SetSize(item.btn, removable and 334 or wide and 362 or 178, 24)
    local canDel = false
    if i <= per and index <= #list then
      local v = list[index]
      canDel = removable and (not c.canRemove or c.canRemove(v))
      -- the current value is green
      local text = tostring(c.labelOf(v))
      if v == current then
        text = "|cff40ff40" .. string.gsub(text, "|r", "|r|cff40ff40") .. "|r"
      end
      local about = describe(c, v)
      if about then
        text = text .. "  |cffd0d0d0- " .. about .. "|r"
      end
      local path, color = dropPreview(c, v)
      if path then
        RWA.Try(item.tex, "SetTexture", path)
        W.SetColor(item.tex, color[1], color[2], color[3], 1)
      end
      W.SetText(item.btn, text)
      setShown({ item.btn }, true)
      setShown({ item.tex }, path ~= nil)
    else
      setShown({ item.btn, item.tex }, false)
    end
    if item.del then
      setShown({ item.del }, canDel)
    end
  end
  W.SetText(d.pageText, (d.page + 1) .. " / " .. (maxPage + 1))
  setShown(d.paging, maxPage > 0)
end

openDrop = function(c)
  if not ui.drop then
    buildDrop()
  end
  local d = ui.drop
  if d.open and d.owner == c then
    closeDrop()
    return
  end
  if c.onOpen then
    c.onOpen()
  end
  d.owner = c
  d.open = true
  d.side = c.col == 1 and 2 or 1
  local bx = d.side == 1 and COL1 or COL2
  for _, rec in ipairs(d.layout) do
    W.SetPoint(rec.obj, "TOPLEFT", ui.win, "TOPLEFT", bx + rec.dx, rec.dy)
  end
  local list = dropValues(c)
  local per = DROP_PER
  for _, v in ipairs(list) do
    if describe(c, v) then
      per = DROP_ROWS
    end
  end
  if c.onRemove then
    per = DROP_ROWS
  end
  d.page = math.floor(math.max(0, indexOf(list, c.get()) - 1) / per)
  W.SetText(d.title, c.prompt or ("Choose " .. (c.title or "") .. ":"))
  setShown(ui.colObjs[d.side], false)
  setShown(d.objs, true)
  refreshDrop()
end

-- Any other button closes an open dropdown first.
function RWA.CloseDropdown()
  closeDrop()
end

W.BeforeClick = function(b)
  local d = ui and ui.drop
  if d and d.open and not d.mine[b] and not (d.owner and d.owner.objs[1] == b) then
    closeDrop()
  end
end

-- A dropdown button: shows labelOf(get()) and opens the list of values() to choose from.
-- Right click still steps back one value, as a shortcut.
local function cycle(x, y, w, values, labelOf, get, set, title)
  local c = { objs = {}, values = values, labelOf = labelOf, get = get, set = set, title = title or ui.lastLabel }
  c.col = x >= COL2 - 10 and 2 or 1
  local b = W.Button(ui.win, "", w, 22, function(_, key)
    if key == "RBUTTON" or key == "RightButton" then
      local list = dropValues(c)
      local i = indexOf(list, get())
      set(list[(i - 2) % #list + 1])
      RWA.RefreshAuraFromEditor()
      local nextDrop = ui.nextDrop
      ui.nextDrop = nil
      if nextDrop then
        openDrop(nextDrop)
      end
      return
    end
    openDrop(c)
  end)
  at(b, x, y)
  addTip(b)
  c.objs[1] = b
  c.refresh = function()
    W.SetText(b, tostring(labelOf(get())) .. " v")
  end
  table.insert(controls, c)
  return c
end

local function ident(v)
  return tostring(v)
end

---------------------------------------------------------------------------
-- Aura list
---------------------------------------------------------------------------

local function shorten(text, max)
  text = tostring(text or "")
  if string.len(text) > max then
    return string.sub(text, 1, max - 2) .. ".."
  end
  return text
end

-- Splits text into up to two lines of max characters at spaces; the second line ends in ".."
-- when the rest does not fit. Returns line1, line2 (or nil), cut.
local DESC_CHARS = 31
local function wrapTwo(text, max)
  text = RWA.Trim(tostring(text or ""))
  if string.len(text) <= max then
    return text, nil, false
  end
  local cutAt = max
  for i = max + 1, math.floor(max / 2), -1 do
    if string.sub(text, i, i) == " " then
      cutAt = i - 1
      break
    end
  end
  local first = string.sub(text, 1, cutAt)
  local rest = RWA.Trim(string.sub(text, cutAt + 1))
  if string.len(rest) <= max then
    return first, rest, false
  end
  return first, string.sub(rest, 1, max - 2) .. "..", true
end
RWA.WrapTwo = wrapTwo

-- What an aura tracks, in a few words, for the list's "Tracks" column.
function RWA.DescribeTarget(data)
  local triggers = data.triggers or {}
  local t = triggers[1]
  if not t then
    return "nothing yet"
  end
  local text
  if t.type == "status" then
    if t.check == "cooldown" then
      text = "cooldown of " .. ((t.skill and t.skill ~= "") and t.skill or "?")
    else
      text = (t.unit or "player") .. " " .. string.lower(CHECK_LABELS[t.check or "health"] or tostring(t.check))
      if t.op and t.value then
        text = text .. " " .. t.op .. " " .. t.value .. (t.percent and "%" or "")
      end
    end
  elseif t.type == "custom" then
    text = "custom Lua"
  else
    local what = {}
    for _, n in ipairs(t.names or {}) do
      what[#what + 1] = n
    end
    for _, n in ipairs(t.ids or {}) do
      what[#what + 1] = "#" .. n
    end
    text = (t.filter == "HARMFUL" and "debuff" or "buff") .. " on " .. (t.unit or "player") .. ": "
      .. (#what > 0 and table.concat(what, ", ") or "any")
    if t.showOn == "missing" then
      text = "missing " .. text
    end
  end
  if #triggers > 1 then
    text = text .. " (+" .. (#triggers - 1) .. ")"
  end
  return text
end

-- Small picture of the aura for the list: its icon, texture or bar in its colour, or "Aa" for text.
-- A Class trigger's icon, so a turned-off class aura still shows the right picture in the list.
local function classPreview(data)
  local t = data.triggers and data.triggers[1]
  if t and t.type == "status" and t.check == "class" and UnitClass and RWA.ClassIcon then
    return RWA.ClassIcon(UnitClass(t.unit or "player"))
  end
end

local function setPreview(row, data)
  local c = data.color or { 1, 1, 1, 1 }
  if data.regionType == "text" then
    setShown({ row.tex }, false)
    W.SetText(row.textPreview, "Aa")
    W.SetColor(row.textPreview, c[1], c[2], c[3])
    setShown({ row.textPreview }, true)
    return
  end
  setShown({ row.textPreview }, false)
  local path, h = nil, 26
  if data.regionType == "icon" or data.regionType == "kittytracker" then
    local a = RWA.loaded[data.id]
    path = (data.icon and data.icon ~= "") and data.icon or data.previewIcon
      or (a and a.region.lastIcon) or classPreview(data) or W.TexturePath("exclamation-mark")
    W.SetColor(row.tex, 1, 1, 1, 1)
  else
    path = W.TexturePath(data.texture or "Statusbar_Clean")
    W.SetColor(row.tex, c[1], c[2], c[3], 1)
    if data.regionType == "aurabar" then
      h = 10
    end
  end
  W.SetSize(row.tex, 26, h)
  RWA.Try(row.tex, "SetTexture", path)
  setShown({ row.tex }, true)
end

local function refreshList()
  if ui.pageName ~= "list" then
    return
  end
  local order = RWA_DB.order
  -- ui.top: how many auras are scrolled past (mouse wheel 1 row, < > a whole page).
  local maxTop = math.max(0, #order - ROWS)
  ui.top = math.max(0, math.min(ui.top or 0, maxTop))
  for i = 1, ROWS do
    local row = ui.rows[i]
    local id = order[ui.top + i]
    row.id = id
    local parts = { row.name, row.desc, row.desc2, row.descHover, row.target, row.export, row.edit, row.toggle, row.up, row.down }
    if id then
      local data = RWA_DB.auras[id]
      -- The selected aura (for Copy, Delete, Test and Export) shows in green.
      local name = shorten(id, 22)
      W.SetText(row.name, (id == ui.selected) and ("|cff80ff80" .. name .. "|r") or name)
      local l1, l2, cut = wrapTwo(data.desc, DESC_CHARS)
      row.descCut = cut
      if not data.desc then
        l1 = "|cff808080(no description: add one in Edit)|r"
      end
      W.SetText(row.desc, l1)
      W.SetText(row.desc2, l2 or "")
      at(row.desc, 226, row.descY + (l2 and -3 or 3))
      W.SetText(row.target, shorten(RWA.DescribeTarget(data), 22))
      W.SetText(row.toggle, data.enabled and "|cff40ff40On|r" or "|cffff5050Off|r")
      setShown(parts, true)
      setPreview(row, data)
    else
      setShown(parts, false)
      setShown({ row.tex, row.textPreview }, false)
    end
  end
  if #order > ROWS then
    W.SetText(ui.pageText, (ui.top + 1) .. "-" .. (ui.top + ROWS) .. " of " .. #order)
  else
    W.SetText(ui.pageText, #order .. (#order == 1 and " aura" or " auras"))
  end
  -- Scrollbar: the thumb shows which part of the list is visible.
  if ui.scrollThumb then
    local trackH = ROWS * ROW_H - 4
    local thumbH = math.max(16, math.floor(trackH * math.min(1, ROWS / math.max(1, #order))))
    local y = maxTop > 0 and math.floor((trackH - thumbH) * ui.top / maxTop) or 0
    W.SetSize(ui.scrollThumb, 6, thumbH)
    at(ui.scrollThumb, ui.scrollX, LIST_TOP + 2 + y)
    setShown({ ui.scrollTrack, ui.scrollThumb }, #order > ROWS)
  end
end

-- Scroll the list by n rows (mouse wheel: up = -1).
function RWA.ScrollList(n)
  if not ui or ui.pageName ~= "list" then
    return
  end
  ui.top = (ui.top or 0) + n
  refreshList()
end

-- Called from the window's XML (and its buttons) on the mouse wheel: delta > 0 is up.
function RWA_ListWheel(delta)
  RWA.ScrollList((tonumber(delta) or 0) > 0 and -1 or 1)
end

function RWA.ListTop()
  return ui and ui.top or 0
end

-- Keep the aura at position pos (1-based) in view.
local function scrollTo(pos)
  if pos <= 0 then
    return
  end
  ui.top = ui.top or 0
  if pos <= ui.top then
    ui.top = pos - 1
  elseif pos > ui.top + ROWS then
    ui.top = pos - ROWS
  end
end

local function closePicker()
  if ui.picker and ui.picker.open then
    ui.picker.open = false
    setShown(ui.picker.objs, false)
  end
end

local function selectAura(id)
  closePicker()
  ui.selected = id
  local pos = id and indexOf(RWA_DB.order, id) or 0
  scrollTo(pos)
  refreshList()
  RWA.RefreshEditor()
  if ui.exportAura and id then
    ui.exportAura(id, false)
  end
end

RWA.SelectAura = function(id)
  selectAura(id)
end

-- The window shows either the list or the editor of one aura.
function RWA.ShowList()
  if not ui then
    return
  end
  hideDrop()
  closePicker()
  ui.pageName = "list"
  local pos = ui.selected and indexOf(RWA_DB.order, ui.selected) or 0
  scrollTo(pos)
  setShown(ui.editorObjs, false)
  setShown(ui.listObjs, true)
  refreshList()
  if ui.exportAura and ui.selected and RWA_DB.auras[ui.selected] then
    ui.exportAura(ui.selected, false)
  end
end

-- A clicked rom weakauras chat link: open the list with the code in the Import box.
function RWA.OfferImport(code)
  if not RWA.IsOptionsOpen() then
    RWA.ToggleOptions()
  end
  RWA.ShowList()
  if ui and ui.importBox then
    W.SetText(ui.importBox, code)
  end
  RWA.Print("aura code from a chat link is in the Import box: press Import to add it")
end

function RWA.ShowEditor(id)
  if not ui or not (id and RWA_DB.auras[id]) then
    return
  end
  hideDrop()
  closePicker()
  if ui.selected ~= id then
    ui.trigIndex = 1
    ui.elemIndex = 0
  end
  ui.selected = id
  ui.pageName = "edit"
  setShown(ui.listObjs, false)
  RWA.RefreshEditor()
end

---------------------------------------------------------------------------
-- Editor
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Live preview in the editor: a copy of the aura's region inside the window, fed every frame
-- with the on-screen aura's state, colour and alpha (looping test data while the window is open).
---------------------------------------------------------------------------

local previews = {} -- [regionType] = region drawn on its own child frame of the window

local function previewPlace(self)
  W.SetPoint(self.frame, "CENTER", ui.win, "TOPLEFT", ui.previewX or 0, ui.previewY or 0)
end

local function hidePreview()
  for _, region in pairs(previews) do
    region:Hide()
  end
  if ui then
    ui.previewShown = nil
  end
end

function RWA.UpdatePreview(now)
  if not ui or not ui.previewBox then
    return
  end
  local data = selected()
  local a = data and RWA.loaded[data.id]
  local covered = (ui.drop and ui.drop.open and ui.drop.side == 2) or (ui.picker and ui.picker.open)
  if ui.pageName ~= "edit" or not a or not RWA.IsOptionsOpen() or covered then
    hidePreview()
    return
  end
  local t = Regions.types[data.regionType] and data.regionType or "icon"
  local region = previews[t]
  if not region then
    region = setmetatable({ regionType = t }, Regions.types[t])
    region.frame = W.Frame("RWA_Preview_" .. t, ui.win)
    region.Place = previewPlace
    region:Build()
    previews[t] = region
    ui.previewDirty = true
  end
  if ui.previewShown ~= region or ui.previewDirty then
    hidePreview()
    ui.previewDirty = false
    region:Layout(data)
    ui.previewShown = region
  end
  region:SetState(a.region.state or {})
  region:SetColor(a.region.color)
  region:SetAlpha(a.region.alpha or 1)
  region:Update(now)
  region:UpdateElements(now, a.states)
  region:Show()
end

function RWA.RefreshEditor()
  if not ui or ui.pageName ~= "edit" then
    return
  end
  if ui.picker and ui.picker.open then
    if selected() then
      refreshPicker()
      return
    end
    ui.picker.open = false
    setShown(ui.picker.objs, false)
  end
  local data = selected()
  if not data then
    RWA.ShowList()
    return
  end
  setShown(ui.editorObjs, true)
  W.SetText(ui.editTitle, "Editing: " .. data.id .. "   |cffaaaaaa" .. shorten(RWA.DescribeTarget(data), 50) .. "|r")
  local d = ui.drop
  if d and d.open then
    setShown(ui.colObjs[d.side], false)
    setShown(d.objs, true)
    refreshDrop()
  end
  for _, c in ipairs(controls) do
    c.refresh()
  end
  local t = trigger1()
  local kind = t.type or "aura"
  setShown(ui.groups.aura, kind == "aura")
  setShown(ui.groups.status, kind == "status")
  setShown(ui.groups.custom, kind == "custom")
  setShown(ui.groups.kitty, kind == "kitty")
  setShown(ui.groups.recent, kind == "recent")
  setShown(ui.groups.lastcast, kind == "lastcast")
  setShown(ui.groups.threat, kind == "threat")
  local isCooldown = kind == "status" and t.check == "cooldown"
  local isResource = kind == "status" and (t.check == "health" or t.check == "mana" or t.check == "skill")
  setShown(ui.groups.cooldown, isCooldown)
  setShown(ui.groups.compare, isResource)
  setShown(ui.groups.texture, data.regionType == "texture" or data.regionType == "aurabar")
  local list, own = displayTriggers(data)
  if ui.trigPick then
    -- the dropdown says whose triggers it lists
    local e = selElement()
    local main = Regions.labels[data.regionType] or data.regionType
    local name = e and (e.type == "text" and "Text" or "Icon") or main
    ui.trigPick.prompt = (e and not own) and ("The " .. name .. " uses the " .. main .. "'s triggers:")
      or ("Triggers of the " .. name .. " display:")
  end
  setShown(ui.trigX, own or #list > 1)
  setShown(ui.trigCombine, not own and #list > 1)
  if ui.refreshDisplays then
    ui.refreshDisplays()
  end
end

-- Called after any cycle button: rebuild the aura so the change shows at once.
function RWA.RefreshAuraFromEditor()
  local data = selected()
  if data then
    for _, t in ipairs(data.triggers) do
      Triggers.Reset(t)
    end
    RWA.LoadAura(data.id)
  end
  if ui then
    ui.previewDirty = true
  end
  refreshList()
  RWA.RefreshEditor()
end

local function saveEditor()
  local data = selected()
  if not data then
    return
  end
  local oldId = data.id
  local newName
  for _, c in ipairs(controls) do
    if c.save then
      c.save()
    end
    if c.isName then
      newName = c.pending
    end
  end
  if newName and newName ~= oldId then
    ui.selected = RWA.RenameAura(oldId, newName)
  end
  RWA.RefreshAuraFromEditor()
  RWA.Print("saved", ui.selected)
end

local function num(text, fallback)
  return tonumber(text) or fallback
end

local function buildEditor()
  local win = ui.win
  ui.building = true
  ui.colObjs = { {}, {} }
  local cols = { { x = COL1, y = EDIT_TOP }, { x = COL2, y = EDIT_TOP } }
  local cur
  local closeSection
  local function column(i)
    if closeSection then
      closeSection()
    end
    cur = cols[i]
    LX, WX = cur.x, cur.x + 100
  end
  local function nextRow()
    local r = cur.y
    cur.y = cur.y + 28
    return r
  end
  local before = {}
  for _, c in ipairs(controls) do
    before[c] = true
  end
  local labels = {}
  -- A section title on a coloured bar, as in KittyCombo's setup window.
  -- A section: a coloured title bar with a short hint, over a tinted panel holding its rows,
  -- so each group of settings reads as one box (like KittyCombo's setup window).
  closeSection = function()
    local s = cur and cur.open
    if not s then
      return
    end
    cur.open = nil
    local h = math.max(4, cur.y - s.top - 2)
    local panel = W.Texture(win, "BORDER", "Square_FullWhite")
    W.SetSize(panel, SECTION_W, h)
    at(panel, s.x - 6, s.top)
    W.SetColor(panel, THEME.panel[1], THEME.panel[2], THEME.panel[3], THEME.panel[4])
    table.insert(labels, panel)
    -- one golden frame around the title bar and its panel
    for _, t in ipairs(goldBox(s.x - 6, s.barTop, SECTION_W, s.top - s.barTop + h)) do
      table.insert(labels, t)
    end
  end
  local function section(title, color, hint)
    closeSection()
    ui.lastLabel = nil
    color = color or { 0.16, 0.32, 0.45 }
    local r = cur.y + 2
    cur.y = cur.y + 28
    local bar = W.Texture(win, "BORDER", "Square_FullWhite")
    W.SetSize(bar, SECTION_W, 22)
    at(bar, LX - 6, r)
    W.SetColor(bar, THEME.bar[1], THEME.bar[2], THEME.bar[3], THEME.bar[4])
    -- the section's own colour stays as a small strip, so sections are still told apart at a glance
    local accent = W.Texture(win, "ARTWORK", "Square_FullWhite")
    W.SetSize(accent, 4, 22)
    at(accent, LX - 6, r)
    W.SetColor(accent, color[1], color[2], color[3], 1)
    local underline = W.Texture(win, "ARTWORK", "Square_FullWhite")
    W.SetSize(underline, SECTION_W, 1)
    at(underline, LX - 6, r + 21)
    W.SetColor(underline, THEME.dimGold[1], THEME.dimGold[2], THEME.dimGold[3], THEME.dimGold[4])
    table.insert(labels, accent)
    table.insert(labels, underline)
    local fs = W.FontString(win, "OVERLAY", 13, "THICK")
    W.SetJustify(fs, "LEFT")
    W.SetSize(fs, 170, 22)
    at(fs, LX + 2, r)
    W.SetText(fs, GOLD_TEXT .. title .. "|r")
    local hfs = W.FontString(win, "OVERLAY", 11)
    W.SetJustify(hfs, "RIGHT")
    W.SetSize(hfs, SECTION_W - 182, 22)
    at(hfs, LX + 170, r)
    W.SetText(hfs, hint and ("|cffe8e8e8" .. hint .. "|r") or "")
    table.insert(labels, bar)
    table.insert(labels, fs)
    table.insert(labels, hfs)
    cur.open = { top = r + 22, barTop = r, x = LX, color = color }
    return hfs
  end
  local function L(text, row, x)
    ui.lastLabel = text
    local fs = label(text, x or LX, row + 2)
    table.insert(labels, fs)
    return fs
  end
  ui.groups = { aura = {}, status = {}, custom = {}, kitty = {}, recent = {}, lastcast = {}, threat = {}, cooldown = {}, compare = {}, texture = {} }
  local function group(name, ...)
    for i = 1, select("#", ...) do
      local item = select(i, ...)
      if item.objs then
        for _, o in ipairs(item.objs) do
          table.insert(ui.groups[name], o)
        end
      else
        table.insert(ui.groups[name], item)
      end
    end
  end

  column(1)
  section("General", { 0.20, 0.42, 0.62 }, "name and look")
  local r = nextRow()
  L("Name", r)
  local nameField
  nameField = field(WX, r, 250, function()
    return selected().id
  end, function(text)
    nameField.pending = RWA.Trim(text)
  end)
  nameField.isName = true

  r = nextRow()
  L("Description", r)
  field(WX, r, 250, function()
    return selected().desc or ""
  end, function(text)
    local desc = RWA.Trim(text)
    selected().desc = desc ~= "" and desc or nil
  end)

  r = nextRow()
  L("Display", r)
  local DISP_W = 100
  -- What "Change type" opens for the main display (the Display list, with previews).
  local mainType = { objs = {}, col = 1, title = "Display", values = Regions.order }
  mainType.labelOf = function(v)
    return Regions.labels[v] or v
  end
  mainType.get = function()
    return selected().regionType
  end
  mainType.set = function(v)
    local data = selected()
    data.regionType = v
    local defaults = RWA.REGION_DEFAULTS[v]
    data.width, data.height = defaults.width, defaults.height
    data.text, data.text2 = defaults.text, defaults.text2
    data.showIcon = defaults.showIcon
  end
  -- Displays: the main one and up to 3 more, all buttons of the same size. Click selects one
  -- (green: the rows below and the Trigger section edit it); right click opens its menu,
  -- Change type or Remove. + adds one.
  local MAX_EXTRA = 3
  local function saveTypedNow()
    for _, c in ipairs(controls) do
      if c.save and not c.isName then
        c.save()
      end
    end
  end
  local function elements()
    return selected().elements or {}
  end
  local function element()
    local i = ui.elemIndex or 0
    return i > 0 and elements()[i] or nil
  end
  local function elementLabel(i)
    local e = elements()[i]
    return (e and e.type == "text") and "Text" or "Icon"
  end
  local function selectDisplay(i)
    if (ui.elemIndex or 0) ~= i then
      saveTypedNow()
      ui.elemIndex = i
    end
  end
  -- "Change type" for an extra display
  local elemType = { objs = {}, col = 1, title = "Display type", values = { "icon", "text" } }
  elemType.labelOf = function(v)
    return v == "text" and "Text" or "Icon"
  end
  elemType.get = function()
    local e = element()
    return e and e.type or "icon"
  end
  elemType.set = function(v)
    local e = element()
    if e then
      e.type = v
    end
  end
  local SIDE_LABELS = { LEFT = "Left", RIGHT = "Right", TOP = "Above", BOTTOM = "Below", CENTER = "Middle" }
  local delConfirm = { objs = {}, col = 1, title = "Delete", values = { "yes", "no" } }
  delConfirm.labelOf = function(v)
    return v == "yes" and "Yes, delete it" or "No"
  end
  delConfirm.get = function()
    return nil
  end
  delConfirm.set = function(v)
    local data = selected()
    local i = delConfirm.index or 0
    local e = data.elements and data.elements[i]
    if v == "yes" and e then
      saveTypedNow()
      local from = tonumber(e.from) or 0
      table.remove(data.elements, i)
      -- its own trigger goes with it
      if from > 0 and data.triggers[from] then
        removeTrigger(data, from)
      end
      if #data.elements == 0 then
        data.elements = nil
      end
      ui.elemIndex = 0
    end
  end
  -- Layout: [Main][+] [Extra 1] on the Display row, [Extra 2] [Extra 3] under it; every display
  -- button is DISP_W wide.
  local function isRight(key)
    return key == "RBUTTON" or key == "RightButton"
  end
  -- Right click menu of display i (0 = the main display, which cannot be removed)
  local dispMenu = { objs = {}, col = 1, title = "Display menu" }
  dispMenu.values = function()
    return (dispMenu.index or 0) > 0 and { "type", "remove" } or { "type" }
  end
  dispMenu.labelOf = function(v)
    return v == "remove" and "Remove" or "Change type"
  end
  dispMenu.get = function()
    return nil
  end
  dispMenu.set = function(v)
    local i = dispMenu.index or 0
    if v == "remove" then
      delConfirm.index = i
      delConfirm.prompt = 'Delete display "' .. elementLabel(i) .. '"?'
      ui.nextDrop = delConfirm
    else
      ui.nextDrop = i > 0 and elemType or mainType
    end
  end
  local function openMenu(i, name)
    dispMenu.index = i
    dispMenu.prompt = name .. " display:"
    openDrop(dispMenu)
  end
  local mainBtn = W.Button(win, "", DISP_W, 22, function(_, key)
    selectDisplay(0)
    if isRight(key) then
      RWA.RefreshEditor()
      openMenu(0, mainType.labelOf(selected().regionType))
      return
    end
    closeDrop()
    RWA.RefreshEditor()
  end)
  at(mainBtn, WX, r)
  addTip(mainBtn)
  mainType.objs[1], dispMenu.objs[1], elemType.objs[1] = mainBtn, mainBtn, mainBtn
  table.insert(controls, { objs = { mainBtn }, refresh = function()
    local text = mainType.labelOf(selected().regionType)
    -- green while it is the display being edited (when there are several)
    if (ui.elemIndex or 0) == 0 and selected().elements then
      text = "|cff40ff40" .. text .. "|r"
    end
    W.SetText(mainBtn, text)
  end })
  local addDisp = W.Button(win, "+", 22, 22, function()
    local data = selected()
    if #elements() >= MAX_EXTRA then
      RWA.Print("an aura can have up to " .. (MAX_EXTRA + 1) .. " displays")
      return
    end
    saveTypedNow()
    closeDrop()
    data.elements = data.elements or {}
    table.insert(data.elements, { type = "text", from = 0, side = "BOTTOM", text = "%n" })
    ui.elemIndex = #data.elements
    RWA.RefreshAuraFromEditor()
  end)
  at(addDisp, WX + DISP_W + 4, r)
  W.Tooltip(addDisp, "Add a display", "Adds another piece to this aura, shown next to it:",
    "a text (like a combat timer) or an icon.", "Up to " .. (MAX_EXTRA + 1) .. " displays per aura.")
  table.insert(controls, { objs = { addDisp }, refresh = function() end })
  local dispRow1 = r
  r = nextRow()
  local noExtra = label("", WX, r + 2, 250)
  table.insert(labels, noExtra)
  local dispButtons = {}
  for i = 1, MAX_EXTRA do
    local slot = i + 1 -- slot 1 is the main display
    local x = WX + ((slot - 1) % 2) * (DISP_W + 34)
    local y = slot <= 2 and dispRow1 or r
    local b = W.Button(win, "", DISP_W, 22, function(_, key)
      selectDisplay(i)
      if isRight(key) then
        RWA.RefreshEditor()
        openMenu(i, elementLabel(i))
        return
      end
      closeDrop()
      RWA.RefreshEditor()
    end)
    at(b, x, y)
    W.Tooltip(b, "Extra display", "Click: select it. The rows below and the Trigger section",
      "then edit this display, and it turns green.", "Right click: change its type or remove it.")
    dispButtons[i] = b
    table.insert(controls, { objs = { b }, refresh = function() end })
  end

  -- Rows for the selected extra display
  local elemRows = {}
  local function elRow(...)
    for i = 1, select("#", ...) do
      local item = select(i, ...)
      for _, o in ipairs(item.objs or { item }) do
        table.insert(elemRows, o)
      end
    end
  end
  r = nextRow()
  elRow(L("Side", r))
  elRow(cycle(WX, r, 80, Regions.ELEMENT_SIDES, function(v)
    return SIDE_LABELS[v] or v
  end, function()
    local e = element()
    return e and e.side or "LEFT"
  end, function(v)
    local e = element()
    if e then
      e.side = v
    end
  end, "Side"))
  r = nextRow()
  elRow(L("Size / text", r))
  elRow(field(WX, r, 50, function()
    local e = element()
    return e and e.size or ""
  end, function(text)
    local e = element()
    if e then
      e.size = tonumber(text)
    end
  end))
  elRow(field(WX + 58, r, 192, function()
    local e = element()
    return e and e.type == "text" and (e.text or "%n") or ""
  end, function(text)
    local e = element()
    if e and e.type == "text" then
      e.text = text ~= "" and text or nil
    end
  end))

  ui.refreshDisplays = function()
    local list = elements()
    if (ui.elemIndex or 0) > #list then
      ui.elemIndex = 0
    end
    for i, b in ipairs(dispButtons) do
      if list[i] then
        local text = elementLabel(i)
        W.SetText(b, ui.elemIndex == i and ("|cff40ff40" .. text .. "|r") or text)
      end
      setShown({ b }, list[i] ~= nil)
    end
    local hint = ""
    if #list == 0 then
      hint = "+ adds a display (a timer, an icon...); right click: type"
    elseif #list == 1 then
      hint = "click: edit it   right click: type / remove"
    end
    W.SetText(noExtra, hint ~= "" and ("|cff909090" .. hint .. "|r") or "")
    setShown(elemRows, element() ~= nil)
  end

  -- KittyTracker.lua (optional) adds the "kitty" trigger type.
  local KT = RWA.KittyTracker
  if KT and KT.BuildOptions and not TRIGGER_LABELS.kitty then
    table.insert(TRIGGER_TYPES, "kitty")
    TRIGGER_LABELS.kitty = KT.triggerLabel or "Kitty"
  end
  -- Recent.lua (optional) adds the "recent" (past second) trigger type.
  local RC = RWA.Recent
  if RC and RC.BuildOptions and not TRIGGER_LABELS.recent then
    table.insert(TRIGGER_TYPES, "recent")
    TRIGGER_LABELS.recent = RC.triggerLabel or "Past second"
  end
  -- LastCast.lua (optional) adds the "lastcast" trigger type.
  local LCT = RWA.LastCast
  if LCT and LCT.BuildOptions and not TRIGGER_LABELS.lastcast then
    table.insert(TRIGGER_TYPES, "lastcast")
    TRIGGER_LABELS.lastcast = LCT.triggerLabel or "Last cast"
  end
  -- Threat.lua (optional) adds the "threat" (target's hate list) trigger type.
  local THT = RWA.Threat
  if THT and THT.BuildOptions and not TRIGGER_LABELS.threat then
    table.insert(TRIGGER_TYPES, "threat")
    TRIGGER_LABELS.threat = THT.triggerLabel or "Threat"
  end
  section("Trigger", { 0.78, 0.45, 0.10 })
  -- On the section bar: which trigger is being edited (last entry adds one), X deletes it after
  -- a confirmation, and whether all or any of the triggers must be true.
  local barY = cur.y - 26
  local function saveTyped()
    -- Typed fields belong to the trigger shown now: keep them before showing another one.
    for _, c in ipairs(controls) do
      if c.save and not c.isName then
        c.save()
      end
    end
  end
  local function triggerLabel(i)
    local data = selected()
    local t = data and data.triggers[i]
    if not t then
      return "+ Add a trigger"
    end
    return i .. ": " .. shorten(RWA.DescribeTarget({ triggers = { t } }), 24)
  end
  local confirm = { objs = {}, col = 1, title = "Delete", values = { "yes", "no" } }
  confirm.labelOf = function(v)
    return v == "yes" and "Yes, delete it" or "No"
  end
  confirm.get = function()
    return nil
  end
  confirm.set = function(v)
    local data = selected()
    local i = confirm.index or ui.trigIndex
    local list, own = displayTriggers(data)
    -- the main display keeps at least one trigger; an extra display can drop its own
    if v == "yes" and data.triggers[i] and (own or #list > 1) then
      saveTyped()
      removeTrigger(data, i)
      ui.trigIndex = math.min(ui.trigIndex, #data.triggers)
    end
  end
  local function askDelete(i)
    confirm.index = i
    confirm.prompt = 'Delete trigger "' .. shorten(triggerLabel(i), 30) .. '"?'
    openDrop(confirm)
  end
  local pick = cycle(LX + 64, barY, 190, function()
    local list = {}
    local mine, own = displayTriggers(selected())
    for _, i in ipairs(mine) do
      list[#list + 1] = i
    end
    -- an extra display has at most one trigger of its own
    if not own then
      list[#list + 1] = "add"
    end
    return list
  end, function(v)
    return v == "add" and "+ Add a trigger" or triggerLabel(v)
  end, function()
    trigger1()
    return ui.trigIndex
  end, function(v)
    saveTyped()
    local data = selected()
    if v == "add" then
      table.insert(data.triggers, newTrigger())
      ui.trigIndex = #data.triggers
      -- an extra display that used the main display's triggers gets this one as its own
      local e = selElement()
      if e then
        e.from = #data.triggers
      end
    else
      ui.trigIndex = v
    end
  end, "Trigger to edit")
  -- "-" next to each trigger in the list removes it (after asking)
  pick.canRemove = function(v)
    if v == "add" then
      return false
    end
    local list, own = displayTriggers(selected())
    return own or #list > 1
  end
  pick.onRemove = askDelete
  ui.trigPick = pick
  local delBtn = W.Button(win, "X", 22, 22, function()
    askDelete(ui.trigIndex)
  end)
  W.Tooltip(delBtn, "Delete trigger", "Deletes the trigger shown below, after asking.")
  confirm.objs[1] = delBtn
  at(delBtn, LX + 258, barY)
  table.insert(controls, { objs = { delBtn }, refresh = function() end })
  local combine = cycle(LX + 284, barY, 76, { "all", "any" }, function(v)
    return v == "any" and "Any of" or "All of"
  end, function()
    return selected().triggers.mode or "all"
  end, function(v)
    selected().triggers.mode = (v == "any") and "any" or nil
  end, "Combine")
  W.Tooltip(combine.objs[1], "All of / Any of", "All of: the aura shows when every trigger is true.",
    "Any of: it shows when at least one is. Triggers of an extra display", "with its own trigger do not count here.")
  ui.trigX, ui.trigCombine = { delBtn }, { combine.objs[1] }
  r = nextRow()
  kittyAsk = { objs = {}, col = 1, title = "Kitty display", values = { "yes", "no" },
    prompt = "Set display as Kitty tracker?" }
  kittyAsk.labelOf = function(v)
    return v == "yes" and "Yes, show the Kitty tracker" or "No, keep this display"
  end
  kittyAsk.get = function()
    return nil
  end
  kittyAsk.set = function(v)
    if v == "yes" and RWA.KittyTracker and RWA.KittyTracker.MakeTracker then
      RWA.KittyTracker.MakeTracker(selected())
    end
  end
  L("Type", r)
  cycle(WX, r, 120, TRIGGER_TYPES, function(v)
    return TRIGGER_LABELS[v] or v
  end, function()
    return trigger1().type or "aura"
  end, function(v)
    local t = trigger1()
    local old = t.type or "aura"
    t.type = v
    -- switching the main display's trigger to Kitty asks once whether the display should follow
    local KTr = RWA.KittyTracker
    if KTr and KTr.ShouldAskDisplay and not selElement() and KTr.ShouldAskDisplay(selected(), old, v) then
      ui.nextDrop = kittyAsk
    end
    if v == "status" then
      t.check = t.check or "health"
    elseif v == "custom" then
      t.code = t.code or "return UnitHealth(\"player\") < UnitMaxHealth(\"player\") * 0.5"
    end
  end)
  cycle(WX + 128, r, 110, UNITS, ident, function()
    return trigger1().unit or "player"
  end, function(v)
    trigger1().unit = v
  end)

  -- Buff / debuff trigger rows
  r = nextRow()
  group("aura", L("Looks for", r))
  group("aura", cycle(WX, r, 120, { "HELPFUL", "HARMFUL" }, function(v)
    return v == "HARMFUL" and "Debuff" or "Buff"
  end, function()
    return trigger1().filter or "HELPFUL"
  end, function(v)
    trigger1().filter = v
  end))
  group("aura", cycle(WX + 128, r, 110, { "active", "missing", "always" }, function(v)
    return v == "missing" and "Show if missing" or v == "always" and "Always show" or "Show if active"
  end, function()
    return trigger1().showOn or "active"
  end, function(v)
    trigger1().showOn = v
  end))
  local rowNames = nextRow()
  group("aura", L("Name or ID", rowNames))
  group("aura", field(WX, rowNames, 250, function()
    local t = trigger1()
    local parts = {}
    for _, n in ipairs(t.names or {}) do
      parts[#parts + 1] = n
    end
    for _, n in ipairs(t.ids or {}) do
      parts[#parts + 1] = tostring(n)
    end
    return table.concat(parts, ", ")
  end, function(text)
    local t = trigger1()
    if t.type ~= "aura" then
      return
    end
    t.names, t.ids = {}, {}
    for _, part in ipairs(RWA.Split(text, ",")) do
      if tonumber(part) then
        table.insert(t.ids, tonumber(part))
      else
        table.insert(t.names, part)
      end
    end
  end))

  -- Status trigger rows (share the same two rows as the aura trigger)
  group("status", L("Check", r))
  group("status", cycle(WX, r, 120, CHECKS, function(v)
    return CHECK_LABELS[v] or v
  end, function()
    return trigger1().check or "health"
  end, function(v)
    trigger1().check = v
  end))
  group("compare", L("Show when", rowNames))
  group("compare", cycle(WX, rowNames, 50, OPS, function(v)
    return v == "none" and "always" or v
  end, function()
    return trigger1().op or "none"
  end, function(v)
    trigger1().op = (v ~= "none") and v or nil
  end))
  group("compare", field(WX + 58, rowNames, 60, function()
    return trigger1().value
  end, function(text)
    local t = trigger1()
    if t.type == "status" then
      t.value = tonumber(text)
    end
  end))
  group("compare", cycle(WX + 126, rowNames, 70, { false, true }, function(v)
    return v and "percent" or "value"
  end, function()
    return trigger1().percent and true or false
  end, function(v)
    trigger1().percent = v
  end))
  group("cooldown", L("Skill name or ID", rowNames))
  group("cooldown", field(WX, rowNames, 150, function()
    return trigger1().skill or ""
  end, function(text)
    local t = trigger1()
    if t.type == "status" and t.check == "cooldown" then
      t.skill = RWA.Trim(text)
    end
  end))
  group("cooldown", cycle(WX + 158, rowNames, 92, { "always", "ready", "cooldown" }, function(v)
    return v == "ready" and "When ready" or v == "cooldown" and "On cooldown" or "Always"
  end, function()
    return trigger1().showOn or "always"
  end, function(v)
    trigger1().showOn = v
  end))

  -- Custom trigger row
  group("custom", L("Lua code", r))
  group("custom", field(WX, r, 250, function()
    return trigger1().code or ""
  end, function(text)
    local t = trigger1()
    if t.type == "custom" then
      t.code = text
    end
  end))
  group("custom", L("returns show [, {name=..}]", rowNames, WX))

  -- Kitty trigger rows: built by KittyTracker.lua on the same two rows (env documented there)
  if KT and KT.BuildOptions then
    KT.BuildOptions({
      rows = { r, rowNames },
      LX = LX,
      WX = WX,
      L = L,
      cycle = cycle,
      field = field,
      group = function(...)
        return group("kitty", ...)
      end,
      trigger1 = trigger1,
      selected = selected,
    })
  end
  -- Past second rows: built by Recent.lua on the same two rows
  if RC and RC.BuildOptions then
    RC.BuildOptions({
      rows = { r, rowNames },
      LX = LX,
      WX = WX,
      L = L,
      cycle = cycle,
      field = field,
      group = function(...)
        return group("recent", ...)
      end,
      trigger1 = trigger1,
      selected = selected,
    })
  end
  -- Last cast rows: built by LastCast.lua on the same two rows
  if LCT and LCT.BuildOptions then
    LCT.BuildOptions({
      rows = { r, rowNames },
      LX = LX,
      WX = WX,
      L = L,
      cycle = cycle,
      field = field,
      group = function(...)
        return group("lastcast", ...)
      end,
      trigger1 = trigger1,
      selected = selected,
    })
  end
  -- Threat rows: built by Threat.lua on the same two rows
  if THT and THT.BuildOptions then
    THT.BuildOptions({
      rows = { r, rowNames },
      LX = LX,
      WX = WX,
      L = L,
      cycle = cycle,
      field = field,
      group = function(...)
        return group("threat", ...)
      end,
      trigger1 = trigger1,
      selected = selected,
    })
  end

  column(2)
  section("Look", { 0.62, 0.25, 0.52 }, "colour, picture, animation")
  -- Live preview: the aura as it looks right now, redrawn every frame (RWA.UpdatePreview).
  local pv = W.Texture(win, "BORDER", "Square_FullWhite")
  W.SetSize(pv, SECTION_W - 12, PREVIEW_H)
  at(pv, LX, cur.y)
  W.SetColor(pv, 0, 0, 0, 0.55)
  table.insert(labels, pv)
  ui.previewBox = pv
  ui.previewX, ui.previewY = LX + (SECTION_W - 12) / 2, cur.y + PREVIEW_H / 2
  cur.y = cur.y + PREVIEW_H + 6
  r = nextRow()
  L("Colour", r)
  cycle(WX, r, 120, function()
    local names = {}
    for _, e in ipairs(COLORS) do
      names[#names + 1] = e[1]
    end
    return names
  end, ident, function()
    return colorName(selected().color)
  end, function(v)
    for _, e in ipairs(COLORS) do
      if e[1] == v then
        selected().color = RWA.CopyTable(e[2])
      end
    end
  end)
  local texBtn = W.Button(win, "", 122, 22, function()
    RWA.OpenTexturePicker()
  end)
  at(texBtn, WX + 128, r)
  group("texture", { objs = { texBtn } })
  table.insert(controls, {
    objs = { texBtn },
    refresh = function()
      local tex = selected().texture or ""
      tex = string.gsub(string.gsub(tex, "^PowerAuras/Aura", "Power Aura "), "_", " ")
      W.SetText(texBtn, "Tex: " .. shorten(tex, 13))
    end,
  })

  r = nextRow()
  L("Icon", r)
  field(WX, r, 250, function()
    return selected().icon or ""
  end, function(text)
    local icon = RWA.Trim(text)
    selected().icon = icon ~= "" and icon or nil
  end)

  r = nextRow()
  L("Animation", r)
  cycle(WX, r, 80, START_ANIMS, function(v)
    return "in: " .. v
  end, function()
    return selected().animation.start or "none"
  end, function(v)
    selected().animation.start = v
    selected().animation.finish = v
  end)
  cycle(WX + 88, r, 100, MAIN_ANIMS, function(v)
    return "loop: " .. v
  end, function()
    return selected().animation.main or "none"
  end, function(v)
    selected().animation.main = v
  end)


  section("Text and size", { 0.15, 0.55, 0.50 }, "%n name  %p time  %s stacks")
  r = nextRow()
  L("Text", r)
  field(WX, r, 150, function()
    return selected().text
  end, function(text)
    selected().text = text
  end)
  field(WX + 158, r, 92, function()
    return selected().text2 or ""
  end, function(text)
    selected().text2 = text
  end)

  r = nextRow()
  L("Size  W / H / font", r)
  field(WX, r, 50, function()
    return selected().width
  end, function(text)
    selected().width = num(text, selected().width)
  end)
  field(WX + 58, r, 50, function()
    return selected().height
  end, function(text)
    selected().height = num(text, selected().height)
  end)
  field(WX + 116, r, 40, function()
    return selected().fontSize
  end, function(text)
    selected().fontSize = num(text, selected().fontSize)
  end)
  cycle(WX + 164, r, 86, FONTS, function(v)
    return (string.gsub(tostring(v), "%.ttf$", ""))
  end, function()
    return selected().font or "default"
  end, function(v)
    selected().font = (v ~= "default") and v or nil
  end)

  section("Position", { 0.35, 0.35, 0.60 }, "or drag it on screen")
  r = nextRow()
  L("Position X / Y", r)
  local xField = field(WX, r, 50, function()
    return selected().x
  end, function(text)
    selected().x = num(text, selected().x)
  end)
  local yField = field(WX + 58, r, 50, function()
    return selected().y
  end, function(text)
    selected().y = num(text, selected().y)
  end)
  local function nudge(dx, dy)
    return function()
      local data = selected()
      if not data then
        return
      end
      data.x, data.y = (data.x or 0) + dx, (data.y or 0) + dy
      local a = RWA.loaded[data.id]
      if a then
        a.region:Place(0, a.dy or 0)
      end
      xField.refresh()
      yField.refresh()
    end
  end
  local nudges = {
    W.Button(win, "<", 24, 22, nudge(-5, 0)),
    W.Button(win, "^", 24, 22, nudge(0, -5)),
    W.Button(win, "v", 24, 22, nudge(0, 5)),
    W.Button(win, ">", 24, 22, nudge(5, 0)),
  }
  for i, b in ipairs(nudges) do
    at(b, WX + 116 + (i - 1) * 28, r)
  end

  section("Sound", { 0.62, 0.55, 0.12 }, "needs interface sounds on")
  r = nextRow()
  L("Sound on show", r)
  cycle(WX, r, 160, SOUNDS, ident, function()
    return selected().sound or "none"
  end, function(v)
    selected().sound = (v ~= "none") and v or nil
  end)
  local playBtn = W.Button(win, "Play", 50, 22, function()
    local sound = selected() and selected().sound
    if sound then
      RWA.PlaySound(sound)
      RWA.Print("playing", RWA.SoundPath(sound))
    end
  end)
  at(playBtn, WX + 168, r)
  table.insert(controls, { objs = { playBtn }, refresh = function() end })
  r = nextRow()
  L("All auras volume", r)
  cycle(WX, r, 90, RWA.SOUND_VOLUMES, function(v)
    return v == 0 and "Game" or (v .. "%")
  end, function()
    return RWA_DB.settings.soundVolume or 0
  end, function(v)
    RWA.SetSoundVolume(v)
  end)
  cycle(WX + 98, r, 152, RWA.SOUND_CHANNELS, function(v)
    return v == "interface" and "Interface ch." or v == "effects" and "Effects ch." or "Both channels"
  end, function()
    return RWA_DB.settings.soundChannel or "both"
  end, function(v)
    RWA.SetSoundChannel(v)
  end, "Channel")
  -- Aura sounds play on the game's interface channel: warn (and offer a fix) when it is off.
  r = nextRow()
  L("Game sound", r)
  local soundNote = label("", WX, r + 2, 250)
  table.insert(labels, soundNote)
  local unmuteBtn = W.Button(win, "Unmute", 70, 22, function()
    RWA.UnmuteInterface()
    RWA.RefreshEditor()
  end)
  at(unmuteBtn, WX + 180, r)
  table.insert(controls, {
    objs = { unmuteBtn },
    refresh = function()
      local vol = RWA.InterfaceVolume()
      local loud = (tonumber(RWA_DB.settings.soundVolume) or 0) > 0
      if vol and vol <= 0 and not loud then
        W.SetText(soundNote, "|cffff6060Interface sounds are off|r")
        setShown({ unmuteBtn }, true)
      else
        W.SetText(soundNote, vol and ("|cff40ff40Interface sounds on|r" .. (loud and "" or (" (" .. math.floor(vol * 100 + 0.5) .. "%)"))) or "Sound cues play on interface sounds")
        setShown({ unmuteBtn }, false)
      end
    end,
  })

  column(1)
  section("Condition", { 0.50, 0.20, 0.22 }, "change colour when...")
  r = nextRow()
  L("When", r)
  cycle(WX, r, 80, COND_VARS, ident, function()
    local c = cond1(false)
    return c and c.var or "none"
  end, function(v)
    local data = selected()
    if v == "none" then
      data.conditions = {}
    else
      cond1(true).var = v
    end
  end)
  cycle(WX + 88, r, 40, { "<", "<=", ">", ">=", "==" }, ident, function()
    local c = cond1(false)
    return c and c.op or "<"
  end, function(v)
    cond1(true).op = v
  end)
  field(WX + 136, r, 40, function()
    local c = cond1(false)
    return c and c.value or ""
  end, function(text)
    local c = cond1(false)
    if c then
      c.value = tonumber(text) or c.value
    end
  end)
  cycle(WX + 184, r, 66, function()
    local names = {}
    for _, e in ipairs(COLORS) do
      names[#names + 1] = e[1]
    end
    return names
  end, function(v)
    return "-> " .. v
  end, function()
    local c = cond1(false)
    return c and c.set and colorName(c.set.color) or "Red"
  end, function(v)
    local c = cond1(true)
    for _, e in ipairs(COLORS) do
      if e[1] == v then
        c.set = { color = RWA.CopyTable(e[2]) }
      end
    end
  end)

  section("Load", { 0.28, 0.45, 0.22 }, "only show when...")
  r = nextRow()
  L("Combat / class", r)
  cycle(WX, r, 120, { "any", "in", "out" }, function(v)
    return v == "in" and "Only in combat" or v == "out" and "Out of combat" or "Any time"
  end, function()
    local c = selected().load.combat
    return c == true and "in" or c == false and "out" or "any"
  end, function(v)
    if v == "in" then
      selected().load.combat = true
    elseif v == "out" then
      selected().load.combat = false
    else
      selected().load.combat = nil
    end
  end)
  field(WX + 128, r, 122, function()
    return selected().load.class or ""
  end, function(text)
    local class = RWA.Trim(text)
    selected().load.class = class ~= "" and class or nil
  end)

  closeSection()
  column(2)
  closeSection()
  -- Save and Revert under the right column; Back (top left) is part of the editor header.
  local r2 = math.max(cols[1].y, cols[2].y) + 8
  local saveBtn = W.Button(win, "Save", 90, 24, saveEditor)
  at(saveBtn, COL2 + 100, r2)
  local revertBtn = W.Button(win, "Revert", 90, 24, function()
    RWA.RefreshEditor()
  end)
  at(revertBtn, COL2 + 198, r2)
  local saveHint = label("Typed fields are kept when you press Save. Buttons change the aura at once.", COL1, r2 + 4, 380)
  table.insert(labels, saveHint)
  local back = W.Button(win, "< Back to list", 120, 24, function()
    RWA.ShowList()
  end)
  at(back, COL1, 42)
  ui.editTitle = label("", COL1 + 132, 44, 500)
  table.insert(labels, ui.editTitle)

  ui.building = false
  -- Everything built above belongs to the editor page.
  ui.editorObjs = { saveBtn, revertBtn, back }
  for _, fs in ipairs(labels) do
    table.insert(ui.editorObjs, fs)
  end
  for _, b in ipairs(nudges) do
    table.insert(ui.editorObjs, b)
  end
  for _, c in ipairs(controls) do
    if not before[c] then
      for _, o in ipairs(c.objs) do
        table.insert(ui.editorObjs, o)
      end
    end
  end
end


---------------------------------------------------------------------------
-- Texture picker: a grid of previews over the editor, like the WeakAuras texture picker.
---------------------------------------------------------------------------

local function categoryOf(tex)
  for _, cat in ipairs(MEDIA.textureCategories) do
    for _, name in ipairs(MEDIA.textures[cat] or {}) do
      if name == tex then
        return cat
      end
    end
  end
  return MEDIA.textureCategories[1]
end

local function refreshPicker()
  local p = ui.picker
  local list = MEDIA.textures[p.category] or {}
  local per = PICK_COLS * PICK_ROWS
  local maxPage = math.max(0, math.floor((#list - 1) / per))
  p.page = math.max(0, math.min(p.page, maxPage))
  local current = selected() and selected().texture
  for i, cell in ipairs(p.cells) do
    local name = list[p.page * per + i]
    cell.name = name
    if name then
      W.SetTexture(cell.tex, name)
      W.SetText(cell.btn, name == current and "*" or "")
    end
    setShown({ cell.btn, cell.tex }, name ~= nil)
  end
  W.SetText(p.catBtn, p.category .. " (" .. #list .. ")")
  W.SetText(p.pageText, (p.page + 1) .. " / " .. (maxPage + 1))
  W.SetText(p.current, "Current: " .. tostring(current or "none"))
end

local function buildPicker()
  local win = ui.win
  local p = { page = 0, category = MEDIA.textureCategories[1] or "Shapes", cells = {}, objs = {} }
  ui.picker = p
  local function add(obj)
    table.insert(p.objs, obj)
    return obj
  end
  p.catBtn = add(W.Button(win, "", 130, 22, function(_, key)
    local cats = MEDIA.textureCategories
    local i = indexOf(cats, p.category)
    local back = key == "RBUTTON" or key == "RightButton"
    p.category = cats[back and (i - 2) % #cats + 1 or i % #cats + 1]
    p.page = 0
    refreshPicker()
  end))
  at(p.catBtn, COL1, 44)
  local prev = add(W.Button(win, "<", 28, 22, function()
    p.page = p.page - 1
    refreshPicker()
  end))
  at(prev, COL1 + 136, 44)
  p.pageText = add(label("", COL1 + 168, 46, 56))
  W.SetJustify(p.pageText, "CENTER")
  local nextBtn = add(W.Button(win, ">", 28, 22, function()
    p.page = p.page + 1
    refreshPicker()
  end))
  at(nextBtn, COL1 + 228, 44)
  local cancel = add(W.Button(win, "Close", 70, 22, function()
    RWA.CloseTexturePicker()
  end))
  at(cancel, COL1 + 280, 44)
  for row = 1, PICK_ROWS do
    for col = 1, PICK_COLS do
      local cell = {}
      local x = COL1 + 4 + (col - 1) * PICK_CELL
      local y = 76 + (row - 1) * PICK_CELL
      cell.btn = add(W.Button(win, "", PICK_CELL - 4, PICK_CELL - 4, function()
        local data = selected()
        if data and cell.name then
          data.texture = cell.name
          RWA.CloseTexturePicker()
          RWA.RefreshAuraFromEditor()
        end
      end))
      at(cell.btn, x, y)
      -- The preview is drawn on the button itself so it sits above the button background.
      cell.tex = add(W.Texture(cell.btn, "OVERLAY"))
      W.SetSize(cell.tex, PICK_CELL - 14, PICK_CELL - 14)
      W.SetPoint(cell.tex, "CENTER", cell.btn, "CENTER", 0, 0)
      table.insert(p.cells, cell)
    end
  end
  p.current = add(label("", COL1, 76 + PICK_ROWS * PICK_CELL + 4, 350))
  add(label("Click a picture to use it. * marks the one in use.", COL1, 76 + PICK_ROWS * PICK_CELL + 26, 350))
  setShown(p.objs, false)
end

function RWA.OpenTexturePicker()
  if not ui or not selected() then
    return
  end
  if not ui.picker then
    buildPicker()
  end
  hideDrop()
  local p = ui.picker
  p.open = true
  p.category = categoryOf(selected().texture)
  local list = MEDIA.textures[p.category] or {}
  p.page = math.floor(math.max(0, indexOf(list, selected().texture) - 1) / (PICK_COLS * PICK_ROWS))
  setShown(ui.editorObjs, false)
  setShown(p.objs, true)
  refreshPicker()
end

function RWA.CloseTexturePicker()
  if ui and ui.picker and ui.picker.open then
    ui.picker.open = false
    setShown(ui.picker.objs, false)
    RWA.RefreshEditor()
  end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

-- Corner grip: drag right for bigger, left for smaller, 10% per 25 cursor pixels (sideways
-- only, as in KittyCombo: the client's cursor y may count either way).
local GRIP_PIXELS = 25

function RWA.GripScale(start, dx)
  local steps = dx / GRIP_PIXELS
  steps = steps >= 0 and math.floor(steps) or -math.floor(-steps)
  return math.max(0.6, math.min(1.6, start + steps * 0.1))
end

local function cursorX()
  if type(GetCursorPos) ~= "function" then
    return nil
  end
  local ok, x = pcall(GetCursorPos)
  return ok and tonumber(x) or nil
end

function RWA.GripStart()
  local x = cursorX()
  if x then
    RWA.gripDrag = { x = x, scale = tonumber(RWA_DB.settings.uiScale) or 1 }
  end
end

function RWA.GripUpdate()
  local drag, x = RWA.gripDrag, cursorX()
  if not drag or not x then
    return
  end
  local scale = RWA.GripScale(drag.scale, x - drag.x)
  if math.abs(scale - (tonumber(RWA_DB.settings.uiScale) or 1)) > 0.001 then
    RWA.SetWindowScale(scale)
  end
end

function RWA.GripStop()
  RWA.gripDrag = nil
end

function RWA.GripHover(on)
  local tex, grip = _G["RWA_OptGripTexture"], _G["RWA_OptGrip"]
  if tex then
    RWA.Try(tex, "SetTexture", W.TexturePath(on and "Grip_Highlight" or "Grip"))
  end
  if not GameTooltip then
    return
  end
  if on and grip then
    GameTooltip:SetOwner(grip, "ANCHOR_BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Window size")
    GameTooltip:AddLine("Drag this corner right for bigger, left for smaller.", 1, 1, 1)
    GameTooltip:AddLine("Now " .. math.floor((tonumber(RWA_DB.settings.uiScale) or 1) * 100 + 0.5) .. "%", 1, 1, 1)
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

-- The options window's scale (0.6 to 1.6), kept in the settings.
function RWA.SetWindowScale(scale)
  scale = math.max(0.6, math.min(1.6, tonumber(scale) or 1))
  scale = math.floor(scale * 10 + 0.5) / 10
  RWA_DB.settings.uiScale = scale
  local win = ui and ui.win or _G["RWA_OptionsWindow"]
  if win then
    RWA.Try(win, "SetScale", scale)
  end
  return scale
end

local function build()
  ui = { top = 0, rows = {} }
  -- The window and its button pool are declared in OptionsWidgets.xml.
  local win = _G["RWA_OptionsWindow"]
  if not win then
    win = W.Frame("RWA_OptionsWindow", "UIParent")
    W.SetPoint(win, "CENTER", "UIParent", "CENTER", 0, 0)
  end
  ui.win = win
  W.SetSize(win, WIN_W, WIN_H)
  RWA.Try(win, "SetScale", tonumber(RWA_DB.settings.uiScale) or 1)
  -- HIGH, not DIALOG: the game tooltip must draw above this window.
  RWA.Try(win, "SetFrameStrata", "HIGH")

  local bg = W.Texture(win, "BACKGROUND", "Square_FullWhite")
  W.SetSize(bg, WIN_W - 8, WIN_H - 8)
  W.SetPoint(bg, "TOPLEFT", win, "TOPLEFT", 4, 4)
  W.SetColor(bg, THEME.bg[1], THEME.bg[2], THEME.bg[3], THEME.bg[4])
  local titleBg = W.Texture(win, "BORDER", "Square_FullWhite")
  W.SetSize(titleBg, WIN_W - 8, 30)
  W.SetPoint(titleBg, "TOPLEFT", win, "TOPLEFT", 4, 4)
  W.SetColor(titleBg, THEME.title[1], THEME.title[2], THEME.title[3], THEME.title[4])
  -- golden frame around the window and under the title
  goldBox(2, 2, WIN_W - 4, WIN_H - 4, THEME.gold, 2)
  goldBox(7, 7, WIN_W - 14, WIN_H - 14, THEME.darkGold, 1)
  local titleLine = W.Texture(win, "ARTWORK", "Square_FullWhite")
  W.SetSize(titleLine, WIN_W - 8, 1)
  W.SetPoint(titleLine, "TOPLEFT", win, "TOPLEFT", 4, 34)
  W.SetColor(titleLine, THEME.gold[1], THEME.gold[2], THEME.gold[3], 1)
  local logo = W.Texture(win, "ARTWORK", "logo_64_nobg")
  W.SetSize(logo, 24, 24)
  W.SetPoint(logo, "TOPLEFT", win, "TOPLEFT", 6, 4)
  local title = W.FontString(win, "OVERLAY", 15)
  W.SetJustify(title, "LEFT")
  W.SetSize(title, 400, 24)
  W.SetPoint(title, "TOPLEFT", win, "TOPLEFT", 36, 4)
  W.SetText(title, GOLD_TEXT .. RWA.title .. "|r  |cffaaaaaav" .. RWA.version .. "|r")

  local close = W.Button(win, "X", 26, 24, function()
    RWA.Try(win, "Hide")
    RWA.SetEditMode(false)
  end)
  W.SetPoint(close, "TOPRIGHT", win, "TOPRIGHT", -4, 4)
  -- Window size: - and + next to the close button (one 10% step), and the corner grip
  -- (RWA_OptGrip in OptionsWidgets.xml) for small UI scales or high resolutions. Saved in the settings.
  local function sizeTip()
    return "Window size", "Smaller (-) or bigger (+), or drag the bottom right corner.",
      "Now " .. math.floor((tonumber(RWA_DB.settings.uiScale) or 1) * 100 + 0.5) .. "%. Also /rwa size 60-160."
  end
  local bigger = W.Button(win, "+", 24, 24, function()
    RWA.SetWindowScale((tonumber(RWA_DB.settings.uiScale) or 1) + 0.1)
  end)
  W.SetPoint(bigger, "TOPRIGHT", win, "TOPRIGHT", -32, 4)
  W.Tooltip(bigger, sizeTip)
  local smaller = W.Button(win, "-", 24, 24, function()
    RWA.SetWindowScale((tonumber(RWA_DB.settings.uiScale) or 1) - 0.1)
  end)
  W.SetPoint(smaller, "TOPRIGHT", win, "TOPRIGHT", -58, 4)
  W.Tooltip(smaller, sizeTip)
  RWA.sizeButtons = { up = bigger, down = smaller }
  local gripTex = _G["RWA_OptGripTexture"]
  if gripTex then
    RWA.Try(gripTex, "SetTexture", W.TexturePath("Grip"))
  end

  -- The window moves with StartMoving from its XML scripts.
  if _G["RWA_OptionsWindow"] then
    W.UseXmlScripts(win, "RWA_OptionsWindow")
  end

  -- Aura list, as in KittyCombo's list: preview, name, description, what it tracks, Edit, On/Off, order.
  ui.listObjs = {}
  local function L2(obj)
    table.insert(ui.listObjs, obj)
    return obj
  end
  local function head(text, x, w)
    local fs = L2(label("|cffccd6eb" .. text .. "|r", x, 46, w))
    return fs
  end
  -- the list sits in a gold-framed panel, with a faint line between rows
  local listPanel = L2(W.Texture(win, "BORDER", "Square_FullWhite"))
  W.SetSize(listPanel, WIN_W - 16, LIST_TOP - 42 + ROWS * ROW_H + 2)
  at(listPanel, 8, 42)
  W.SetColor(listPanel, THEME.panel[1], THEME.panel[2], THEME.panel[3], THEME.panel[4])
  for _, t in ipairs(goldBox(8, 42, WIN_W - 16, LIST_TOP - 42 + ROWS * ROW_H + 2)) do
    L2(t)
  end
  local listLine = L2(W.Texture(win, "ARTWORK", "Square_FullWhite"))
  W.SetSize(listLine, WIN_W - 18, 1)
  at(listLine, 9, LIST_TOP - 4)
  W.SetColor(listLine, THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.8)
  for i = 1, ROWS - 1 do
    local sep = L2(W.Texture(win, "BORDER", "Square_FullWhite"))
    W.SetSize(sep, WIN_W - 18, 1)
    at(sep, 9, LIST_TOP + i * ROW_H - 3)
    W.SetColor(sep, THEME.divider[1], THEME.divider[2], THEME.divider[3], THEME.divider[4])
  end
  head("Name", 48, 170)
  head("Description", 226, 190)
  head("Tracks", 424, 196)
  for i = 1, ROWS do
    local row = {}
    local y = LIST_TOP + (i - 1) * ROW_H
    row.tex = L2(W.Texture(win, "ARTWORK"))
    W.SetSize(row.tex, 26, 26)
    at(row.tex, 14, y)
    row.textPreview = L2(W.FontString(win, "OVERLAY", 14, "THICK"))
    W.SetSize(row.textPreview, 30, 26)
    at(row.textPreview, 12, y)
    row.name = L2(W.Button(win, "", 170, 24, function()
      if row.id then
        RWA.ShowEditor(row.id)
      end
    end))
    at(row.name, 48, y + 1)
    -- the description takes up to 2 lines; hovering shows all of it when it does not fit
    row.desc = L2(label("", 226, y - 3, 190))
    row.desc2 = L2(label("", 226, y + 10, 190))
    row.descY = y
    row.descHover = L2(W.HoverFrame(win))
    W.SetSize(row.descHover, 190, 28)
    at(row.descHover, 226, y)
    W.Tooltip(row.descHover, function()
      local data = row.id and RWA_DB.auras[row.id]
      if data and data.desc and row.descCut then
        return data.id, data.desc
      end
    end)
    row.target = L2(label("", 424, y + 3, 134))
    row.export = L2(W.Button(win, "Export", 58, 24, function()
      if row.id then
        selectAura(row.id)
        ui.exportAura(row.id, true)
      end
    end))
    at(row.export, 562, y + 1)
    row.edit = L2(W.Button(win, "Edit", 50, 24, function()
      if row.id then
        RWA.ShowEditor(row.id)
      end
    end))
    at(row.edit, 624, y + 1)
    row.toggle = L2(W.Button(win, "", 44, 24, function()
      local data = row.id and RWA_DB.auras[row.id]
      if data then
        data.enabled = not data.enabled
        -- LoadAura unloads a turned-off aura, except in edit mode where it stays visible, dimmed.
        RWA.LoadAura(row.id)
        refreshList()
      end
    end))
    at(row.toggle, 678, y + 1)
    local function move(delta)
      return function()
        local pos = row.id and indexOf(RWA_DB.order, row.id) or 0
        local to = pos + delta
        if pos > 0 and to >= 1 and to <= #RWA_DB.order then
          RWA_DB.order[pos], RWA_DB.order[to] = RWA_DB.order[to], RWA_DB.order[pos]
          selectAura(row.id)
        end
      end
    end
    row.up = L2(W.Button(win, "^", 24, 24, move(-1)))
    at(row.up, 726, y + 1)
    row.down = L2(W.Button(win, "v", 24, 24, move(1)))
    at(row.down, 752, y + 1)
    ui.rows[i] = row
  end
  local listBottom = LIST_TOP + ROWS * ROW_H + 6
  local prev = L2(W.Button(win, "<", 30, 24, function()
    RWA.ScrollList(-ROWS)
  end))
  at(prev, 14, listBottom)
  ui.pageText = L2(W.FontString(win, "OVERLAY", 12))
  W.SetSize(ui.pageText, 60, 24)
  -- scrollbar track and thumb, right of the order buttons
  ui.scrollX = 782
  ui.scrollTrack = L2(W.Texture(win, "ARTWORK", "Square_FullWhite"))
  W.SetSize(ui.scrollTrack, 6, ROWS * ROW_H - 4)
  at(ui.scrollTrack, ui.scrollX, LIST_TOP + 2)
  W.SetColor(ui.scrollTrack, THEME.divider[1], THEME.divider[2], THEME.divider[3], 1)
  ui.scrollThumb = L2(W.Texture(win, "OVERLAY", "Square_FullWhite"))
  W.SetColor(ui.scrollThumb, THEME.gold[1], THEME.gold[2], THEME.gold[3], 1)
  at(ui.pageText, 48, listBottom)
  local nextBtn = L2(W.Button(win, ">", 30, 24, function()
    RWA.ScrollList(ROWS)
  end))
  at(nextBtn, 112, listBottom)

  local function action(text, x, y2, fn, w)
    local b = L2(W.Button(win, text, w or 74, 24, fn))
    at(b, x, y2)
    return b
  end
  local ax = 170
  action("New", ax, listBottom, function()
    RWA.ShowEditor(RWA.NewAura("icon"))
  end)
  action("Copy", ax + 80, listBottom, function()
    if ui.selected then
      selectAura(RWA.DuplicateAura(ui.selected))
    end
  end)
  local deleteArmed = 0
  local deleteBtn
  deleteBtn = action("Delete", ax + 160, listBottom, function()
    if not ui.selected then
      return
    end
    if RWA.Now() - deleteArmed > 3 then
      deleteArmed = RWA.Now()
      W.SetText(deleteBtn, "Sure?")
      RWA.After(3, function()
        W.SetText(deleteBtn, "Delete")
      end)
      return
    end
    deleteArmed = 0
    W.SetText(deleteBtn, "Delete")
    RWA.DeleteAura(ui.selected)
    selectAura(nil)
  end)
  action("Test", ax + 240, listBottom, function()
    if ui.selected then
      RWA.TestAuras(ui.selected)
    else
      RWA.TestAuras()
    end
  end)
  action("Test all", ax + 320, listBottom, function()
    RWA.TestAuras()
  end)
  -- Move mode: while the window is open every aura shows looping test data and can be dragged.
  ui.moveOn = true
  ui.moveBtn = action("Move: On", ax + 400, listBottom, function()
    ui.moveOn = not ui.moveOn
    RWA.SetEditMode(ui.moveOn)
    W.SetText(ui.moveBtn, ui.moveOn and "Move: On" or "Move: Off")
  end, 90)
  ui.loudBtn = action("", ax + 496, listBottom, function()
    RWA.SetLoudSounds((tonumber(RWA_DB.settings.soundVolume) or 0) == 0)
  end, 110)
  RWA.OnLoudChanged((tonumber(RWA_DB.settings.soundVolume) or 0) > 0)

  buildEditor()

  -- Share codes, the same format as Cherry's KittyCombo: Import on the upper line, the selected
  -- aura's code (or all auras) on the lower one. Export buttons copy the code to the clipboard.
  local sy = listBottom + 32
  local importBox, importBoxBg = W.EditBox(win, 560, 20)
  L2(importBox)
  if importBoxBg then
    L2(importBoxBg)
  end
  at(importBox, 16, sy + 2)
  ui.importBox = importBox
  action("Import", 584, sy, function()
    local ids, err = RWA.Share.Import(W.GetText(importBox))
    if not ids then
      RWA.Print(err)
      return
    end
    W.SetText(importBox, "")
    RWA.Print("imported", #ids, "aura(s):", table.concat(ids, ", "))
    selectAura(ids[1])
  end, 96)
  local exportBox, exportBoxBg = W.EditBox(win, 560, 20)
  L2(exportBox)
  if exportBoxBg then
    L2(exportBoxBg)
  end
  at(exportBox, 16, sy + 30)
  ui.exportBox = exportBox
  local function sizeText(code)
    local n = string.len(code)
    if n > 255 then
      return "|cffff6060" .. n .. " characters. In-game chat only supports 255 characters. Share this on Discord or elsewhere.|r"
    end
    return n .. " characters: fits in one chat line."
  end
  local infoToken = 0
  -- ids: a list of aura ids, or nil for all. copy: also put it on the clipboard.
  local function exportCode(ids, copy)
    local code, count = RWA.Share.Export(ids)
    if not code then
      RWA.Print(count)
      return
    end
    ui.lastExport = { code = code, name = ids and ids[1] or ("all " .. count .. " auras") }
    W.SetText(exportBox, code)
    local info = sizeText(code)
    W.SetText(ui.exportInfo, info)
    if copy then
      local copied = type(Chat_CopyToClipboard) == "function" and pcall(Chat_CopyToClipboard, code)
      RWA.Try(exportBox, "SetFocus")
      RWA.Try(exportBox, "HighlightText")
      infoToken = infoToken + 1
      local mine = infoToken
      W.SetText(ui.exportInfo, copied and "|cff40ff40Copied export hash to clipboard.|r " .. info
        or "|cffffd040Press Ctrl+C to copy the selected code.|r " .. info)
      RWA.After(3, function()
        if infoToken == mine then
          W.SetText(ui.exportInfo, info)
        end
      end)
    end
  end
  ui.exportAura = function(id, copy)
    exportCode({ id }, copy)
  end
  action("Export all", 584, sy + 28, function()
    exportCode(nil, true)
  end, 96)
  ui.linkBtn = action("Chat link", 684, sy + 28, function()
    local last = ui.lastExport
    if not last then
      RWA.Print("export an aura first, then Chat link puts a clickable link to it in your chat line")
      return
    end
    RWA.Share.PostLink(last.code, last.name)
  end, 96)
  ui.exportInfo = L2(label("Import adds auras, never replaces. Export copies the code; Chat link puts a clickable link in your chat line.", 16, sy + 56, 760))

  RWA.ShowList()
end

-- Clicking or dragging an aura on screen selects it: in the list it is marked, in the editor
-- the editor switches to it.
function RWA.OnAuraMoved(id)
  if not ui or not RWA.IsOptionsOpen() then
    return
  end
  if ui.pageName == "edit" then
    if ui.selected ~= id then
      RWA.ShowEditor(id)
    else
      RWA.RefreshEditor()
    end
  else
    selectAura(id)
  end
end

function RWA.IsOptionsOpen()
  return ui ~= nil and ui.win.IsVisible ~= nil and ui.win:IsVisible() and true or false
end

function RWA.OnLoudChanged(on)
  if ui and ui.loudBtn then
    local pct = tonumber(RWA_DB.settings.soundVolume) or 0
    W.SetText(ui.loudBtn, pct > 0 and ("Vol: |cff40ff40" .. pct .. "%|r") or "Vol: game")
  end
end

function RWA.OnEditModeChanged(on)
  if ui and ui.moveBtn then
    W.SetText(ui.moveBtn, on and "Move: On" or "Move: Off")
  end
end

function RWA.ToggleOptions()
  if not ui then
    build()
    RWA.Try(ui.win, "Show")
    RWA.SetEditMode(ui.moveOn)
    return
  end
  if RWA.IsOptionsOpen() then
    RWA.Try(ui.win, "Hide")
    RWA.SetEditMode(false)
  else
    refreshList()
    RWA.RefreshEditor()
    RWA.Try(ui.win, "Show")
    RWA.SetEditMode(ui.moveOn)
  end
end
