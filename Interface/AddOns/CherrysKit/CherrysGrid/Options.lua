-- Cherry's Grid: the options window (/grid). RoM can't give scripts to frames made in Lua, so
-- the window is a fixed set of rows from CherrysGrid.xml (CGrid_OptRow1..N); each page is a list
-- of row descriptions and the rows show only the widgets their type needs:
--   header  title line              check   check box + label
--   number  label  [-] value [+]    choice  label + button that opens a list
--   color   choice with colours     text    label + edit box (Enter saves)
--   button  a button                info    a line of text

local G = CherrysGrid
local O = {}
G.Options = O

O.ROWS = 20
O.page = "layout"
O.scroll = 0
O.rows = {}       -- current page's row descriptions
O.statusKey = "deficit"
O.watchIndex = 1
O.clickScope = "class"
O.clickButton = "LBUTTON"
O.clickMod = ""
O.bookTab = 2
O.newProfile = ""

O.PAGES = {
  { key = "layout", title = "Layout" },
  { key = "frame", title = "Frame" },
  { key = "statuses", title = "Statuses" },
  { key = "debuffs", title = "Debuffs" },
  { key = "buffs", title = "Buffs" },
  { key = "clicks", title = "Clicks" },
  { key = "general", title = "Tooltip & more" },
  { key = "profiles", title = "Profiles" },
  { key = "about", title = "About" },
}

O.COLORS = {
  { "White", { 1, 1, 1 } }, { "Light grey", { 0.75, 0.75, 0.75 } }, { "Grey", { 0.5, 0.5, 0.5 } }, { "Dark grey", { 0.25, 0.25, 0.25 } },
  { "Black", { 0.05, 0.05, 0.05 } }, { "Red", { 1, 0, 0 } }, { "Dark red", { 0.6, 0.05, 0.05 } }, { "Orange", { 1, 0.5, 0 } },
  { "Gold", { 1, 0.82, 0 } }, { "Yellow", { 1, 0.95, 0.2 } }, { "Lime", { 0.55, 1, 0.1 } }, { "Green", { 0, 1, 0 } },
  { "Dark green", { 0.05, 0.5, 0.1 } }, { "Teal", { 0, 0.8, 0.7 } }, { "Cyan", { 0, 1, 1 } }, { "Light blue", { 0.5, 0.75, 1 } },
  { "Blue", { 0.25, 0.5, 1 } }, { "Dark blue", { 0.1, 0.15, 0.6 } }, { "Purple", { 0.75, 0.2, 1 } }, { "Pink", { 1, 0.45, 0.8 } },
  { "Magenta", { 1, 0, 1 } }, { "Brown", { 0.55, 0.35, 0.15 } },
}

local function hex(c)
  return string.format("%02x%02x%02x", math.floor((c[1] or 1) * 255), math.floor((c[2] or 1) * 255), math.floor((c[3] or 1) * 255))
end

local function colorName(c)
  if type(c) ~= "table" then
    return "?"
  end
  for _, e in ipairs(O.COLORS) do
    local v = e[2]
    if math.abs(v[1] - c[1]) < 0.02 and math.abs(v[2] - c[2]) < 0.02 and math.abs(v[3] - c[3]) < 0.02 then
      return e[1]
    end
  end
  return "Custom"
end

local function P()
  return G.P
end

local function choiceText(list, value)
  for _, e in ipairs(list) do
    if e[1] == value then
      return e[2]
    end
  end
  return tostring(value)
end

local function choiceItems(list, current)
  local items = {}
  for _, e in ipairs(list) do
    items[#items + 1] = { text = e[2], value = e[1], checked = (e[1] == current) }
  end
  return items
end

-- Row builders --------------------------------------------------------------

local function header(text)
  return { type = "header", label = text }
end

local function info(text)
  return { type = "info", label = text }
end

-- A setting of the profile: check box
local function check(label, key, desc, layout)
  return {
    type = "check", label = label, desc = desc, layout = layout,
    get = function() return P()[key] and true or false end,
    set = function(v) P()[key] = v end,
  }
end

local function number(label, key, min, max, step, desc, layout, fmt)
  return {
    type = "number", label = label, desc = desc, layout = layout, min = min, max = max, step = step, fmt = fmt,
    get = function() return tonumber(P()[key]) or min end,
    set = function(v) P()[key] = v end,
  }
end

-- list = { { value, text }, ... }
local function choice(label, key, list, desc, layout)
  return {
    type = "choice", label = label, desc = desc, layout = layout,
    text = function() return choiceText(list, P()[key]) end,
    items = function() return choiceItems(list, P()[key]) end,
    set = function(v) P()[key] = v end,
  }
end

local function colorRow(label, getT, setT, desc)
  return {
    type = "color", label = label, desc = desc,
    getColor = getT,
    text = function() return colorName(getT()) end,
    items = function()
      local items, cur = {}, getT() or {}
      for _, e in ipairs(O.COLORS) do
        items[#items + 1] = { text = "|cff" .. hex(e[2]) .. e[1] .. "|r", value = e[2], checked = (colorName(cur) == e[1]) }
      end
      return items
    end,
    set = function(v) setT(G.Copy(v)) end,
  }
end

local function textRow(label, getS, setS, desc, layout)
  return { type = "text", label = label, desc = desc, layout = layout, get = getS, set = setS }
end

local function button(label, fn, desc)
  return { type = "button", label = label, desc = desc, fn = fn }
end

local ORIENT = { { "VERTICAL", "Bottom to top" }, { "HORIZONTAL", "Left to right" } }
local TEXTURES = { { "gradient", "Gradient" }, { "flat", "Flat" }, { "glass", "Glass" }, { "smooth", "Game bar" } }
local GROUP_BY = { { "group", "Raid group" }, { "class", "Class" }, { "role", "Raid role" }, { "none", "No groups" } }
local SORT_BY = { { "index", "Group order" }, { "name", "Name" }, { "class", "Class" } }
local ANCHORS = { { "TOPLEFT", "Top left" }, { "TOPRIGHT", "Top right" }, { "BOTTOMLEFT", "Bottom left" }, { "BOTTOMRIGHT", "Bottom right" } }
local SCHEMES = { { "rom", "Runes of Magic" }, { "wow", "WoW Grid" }, { "white", "All grey" } }
local MANA_WHO = { { "all", "Everybody" }, { "healers", "Augurs and druids" }, { "me", "Only me" } }
local DEBUFF_MODE = { { "all", "All debuffs" }, { "listed", "Only listed (and important)" }, { "unlisted", "All except listed" } }
local TOOLTIP = { { "always", "Always" }, { "ooc", "Out of combat" }, { "alt", "While Alt is held" }, { "never", "Never" } }
local TT_ANCHOR = { { "frame", "Next to the member" }, { "cursor", "At the mouse" } }
local HIDE_PARTY = { { "never", "Never" }, { "raid", "In a raid" }, { "always", "In party and raid" } }
local FORMATS = { { "number", "-1.2k" }, { "percent", "45%" }, { "both", "-1.2k 45%" }, { "current", "Health left (8.4k)" } }

local function pct(v)
  return math.floor(v * 100 + 0.5) .. "%"
end

-- Pages --------------------------------------------------------------------

local BUILD = {}

function BUILD.layout()
  local rows = {
    header("Frames"),
    check("Lock", "locked", "Locked: the frames can't be moved and the \"Grid (drag)\" tab is hidden. Open these options with /grid.", true),
    header("Show the frames"),
    check("When solo", "showSolo", "Show yourself when you are not in a group.", true),
    check("In a party", "showParty", nil, true),
    check("In a raid", "showRaid", nil, true),
    check("Pets", "showPets", "A group of pets after the members.", true),
    header("Raid groups shown (all 6)"),
  }
  for g = 1, 6 do
    rows[#rows + 1] = {
      type = "check", label = "Group " .. g, layout = true,
      get = function() return P().raidGroups[g] ~= false end,
      set = function(v) P().raidGroups[g] = v end,
    }
  end
  local more = {
    header("Order"),
    choice("Group by", "groupBy", GROUP_BY, "Raid group, class, raid role (tank / attacker) or one list.", true),
    choice("Sort inside a group", "sortBy", SORT_BY, nil, true),
    check("You first in a party", "playerFirst", nil, true),
    number("Members per line (no groups)", "perLine", 1, 36, 1, "With \"No groups\": members in one column (or row).", true),
    check("Groups as rows", "horizontal", "Off: each group is a column (Grid). On: each group is a row.", true),
    choice("Grow from", "anchor", ANCHORS, "The corner that stays put when the layout gets bigger.", true),
    header("Spacing and look"),
    number("Space between members", "spacing", 0, 20, 1, nil, true),
    number("Space between groups", "groupSpacing", 0, 40, 1, nil, true),
    number("Padding", "padding", 0, 30, 1, "Space between the members and the layout border.", true),
    colorRow("Background", function() return P().bgColor end, function(c) c[4] = P().bgColor[4] or 0.7; P().bgColor = c end),
    {
      type = "number", label = "Background opacity", min = 0, max = 1, step = 0.05, fmt = pct, layout = true,
      get = function() return P().bgColor[4] or 0.7 end, set = function(v) P().bgColor[4] = v end,
    },
    check("Layout border", "showBorder", nil, true),
    colorRow("Border colour", function() return P().borderColor end, function(c) c[4] = 1; P().borderColor = c end),
    button("Move to the middle of the screen", function() P().x, P().y = 300, 300 end),
  }
  for _, r in ipairs(more) do
    r.layout = true
    rows[#rows + 1] = r
  end
  return rows
end

function BUILD.frame()
  return {
    header("Size"),
    number("Width", "width", 16, 200, 1, nil, true),
    number("Height", "height", 12, 120, 1, nil, true),
    { type = "number", label = "Scale", min = 0.5, max = 2.5, step = 0.05, fmt = pct, layout = true,
      get = function() return tonumber(P().scale) or 1 end, set = function(v) P().scale = v end },
    header("Health bar"),
    choice("Fills", "orientation", ORIENT, nil, true),
    choice("Texture", "texture", TEXTURES, nil, true),
    check("Invert colours", "invert", "Dark bar on a class coloured background (Grid's \"invert bar colour\").", true),
    { type = "number", label = "Background brightness", min = 0, max = 1, step = 0.05, fmt = pct, layout = true,
      get = function() return tonumber(P().bgDarkness) or 0.25 end, set = function(v) P().bgDarkness = v end },
    choice("Class colours", "colorScheme", SCHEMES, nil, true),
    number("Black edge", "frameBorder", 0, 4, 1, "Black line round each member.", true),
    header("Mana bar"),
    number("Mana bar size", "manaSize", 0, 10, 1, "0 hides it.", true),
    choice("Mana bar for", "manaWho", MANA_WHO, nil, true),
    check("Rage / energy / focus bar too", "skillBar", nil, true),
    header("Indicators"),
    number("Border size", "borderSize", 1, 6, 1, nil, true),
    number("Corner size", "cornerSize", 2, 20, 1, nil, true),
    number("Centre icon size", "iconSize", 6, 40, 1, nil, true),
    check("Seconds on icons", "iconTime", nil, true),
    check("Stacks on the centre icon", "iconStacks", nil, true),
    check("Separate health, name and aura positions", "separatedLayout", "Keeps the name in the centre and health values along the top.", true),
    number("Tracked buff icons at top right", "buffRow", 0, 3, 1, "Shows enabled tracked buffs and present-buff watches.", true),
    number("Debuff icons along the edge", "debuffRow", 0, 4, 1, "Small icons for debuffs along the edge.", true),
    number("Their size", "debuffRowSize", 6, 24, 1, nil, true),
    check("Along the top edge", "debuffRowTop", "Off: along the bottom edge.", true),
    header("Text"),
    { type = "number", label = "Text size", min = 0.5, max = 2, step = 0.05, fmt = pct, layout = true,
      get = function() return tonumber(P().textSize) or 1 end, set = function(v) P().textSize = v end },
    number("Name length", "textLength", 1, 16, 1, "Letters of the name shown.", true),
    check("Names in class colour", "nameClassColor", nil, true),
    header("Range"),
    check("Fade members out of range", "rangeFade", "Needs UnitDistance in your client (/grid probe tells).", true),
    number("Range", "rangeDistance", 20, 1000, 10, "Farther than this fades the member (Out of range status).", true),
  }
end

local function indicatorRows(rows, cfg)
  rows[#rows + 1] = header("Shown on")
  for _, ind in ipairs(G.Statuses.INDICATORS) do
    rows[#rows + 1] = {
      type = "check", label = ind.title,
      get = function() return cfg().ind and cfg().ind[ind.key] and true or false end,
      set = function(v)
        cfg().ind = cfg().ind or {}
        cfg().ind[ind.key] = v and true or false -- false, not nil: defaults would put it back
      end,
    }
  end
end

function BUILD.statuses()
  local S = G.Statuses
  local def
  for _, s in ipairs(S.LIST) do
    if s.key == O.statusKey then
      def = s
    end
  end
  def = def or S.LIST[1]
  local function cfg()
    return P().statuses[def.key]
  end
  local rows = {
    {
      type = "choice", label = "Status",
      text = function() return def.title end,
      items = function()
        local items = {}
        for _, s in ipairs(S.LIST) do
          local on = P().statuses[s.key] and P().statuses[s.key].on
          items[#items + 1] = { text = (on and "" or "|cff888888") .. s.title .. (on and "" or " (off)|r"), value = s.key,
            checked = s.key == O.statusKey }
        end
        return items
      end,
      set = function(v) O.statusKey = v end,
      rebuild = true,
    },
    info(def.desc or ""),
    { type = "check", label = "On", get = function() return cfg().on and true or false end, set = function(v) cfg().on = v end },
    colorRow("Colour", function() return cfg().color end, function(c) cfg().color = c end),
  }
  if def.key == "role" then
    rows[#rows + 1] = colorRow("Main attacker colour", function() return cfg().color2 end, function(c) cfg().color2 = c end)
  end
  rows[#rows + 1] = { type = "number", label = "Priority", min = 0, max = 100, step = 1,
    desc = "When two statuses want the same indicator, the higher number wins.",
    get = function() return tonumber(cfg().prio) or 0 end, set = function(v) cfg().prio = v end }
  if def.threshold then
    local t = def.threshold
    rows[#rows + 1] = { type = "number", label = "Threshold", min = t[1], max = t[2], step = t[3],
      fmt = function(v) return v .. (t[4] or "") end,
      get = function() return tonumber(cfg().threshold) or t[1] end, set = function(v) cfg().threshold = v end }
  end
  if def.formats then
    rows[#rows + 1] = { type = "choice", label = "Shown as", text = function() return choiceText(FORMATS, cfg().format) end,
      items = function() return choiceItems(FORMATS, cfg().format) end, set = function(v) cfg().format = v end }
  end
  if def.alpha then
    rows[#rows + 1] = { type = "number", label = "Fade to", min = 0.05, max = 1, step = 0.05, fmt = pct,
      get = function() return tonumber(cfg().alpha) or 0.5 end, set = function(v) cfg().alpha = v end }
  end
  indicatorRows(rows, cfg)
  return rows
end

function BUILD.debuffs()
  local p = P()
  return {
    header("Which debuffs"),
    choice("Show", "debuffMode", DEBUFF_MODE, "Listed = the priority list below.", false),
    textRow("Priority list", function() return p.debuffList end, function(v) p.debuffList = v end,
      "Names or ids, separated by ; - the first one wins the centre icon."),
    textRow("Important", function() return p.debuffAlert end, function(v) p.debuffAlert = v end,
      "Always shown first, and turn on the Important debuff status (purple border)."),
    textRow("Never show", function() return p.debuffHide end, function(v) p.debuffHide = v end,
      "Debuffs to ignore everywhere, separated by ;"),
    number("Only if ending within (s)", "debuffMaxTime", 0, 600, 5, "0 = any length. Longer debuffs are left out.", false,
      function(v) return v == 0 and "any" or (v .. " s") end),
    check("Leave out debuffs with no end", "debuffNoPermanent"),
    header("Where"),
    info("Centre icon: the Debuff status (Statuses page)."),
    number("Debuff icons along the edge", "debuffRow", 0, 4, 1, "The next debuffs as small icons.", true),
    check("Along the top edge", "debuffRowTop", nil, true),
    check("Seconds on icons", "iconTime", nil, true),
    check("Show debuffs in the tooltip", "tooltipAuras"),
    info("RoM does not tell debuff types (magic, poison...), so lists replace Grid's dispel colours."),
  }
end

function BUILD.buffs()
  local p = P()
  local rows = {
    header("Lists (names or ids, separated by ;)"),
    textRow("Heals over time", function() return p.hotList end, function(v) p.hotList = v end,
      "Heal over time status (corner) and HoT timers (third text line)."),
    textRow("Shields", function() return p.shieldList end, function(v) p.shieldList = v end, "Shield status."),
    textRow("Salves / seeds", function() return p.salveList end, function(v) p.salveList = v end, "Salve status."),
    info("The names are English; on another client language type yours."),
    header("Your own watches"),
    {
      type = "choice", label = "Watch",
      text = function()
        local w = p.watches[O.watchIndex]
        return O.watchIndex .. ": " .. ((w.name ~= "" and w.name) or "(empty)")
      end,
      items = function()
        local items = {}
        for i, w in ipairs(p.watches) do
          items[#items + 1] = { text = i .. ": " .. ((w.name ~= "" and w.name) or "(empty)") .. (w.on and "" or " (off)"),
            value = i, checked = i == O.watchIndex }
        end
        return items
      end,
      set = function(v) O.watchIndex = v end,
      rebuild = true,
    },
  }
  local function cfg()
    return p.watches[O.watchIndex]
  end
  local more = {
    { type = "check", label = "On", get = function() return cfg().on and true or false end, set = function(v) cfg().on = v end },
    textRow("Buff or debuff", function() return cfg().name end, function(v) cfg().name = v end,
      "One name or id (or several separated by ;)."),
    { type = "choice", label = "It is a", text = function() return cfg().kind == "debuff" and "Debuff" or "Buff" end,
      items = function() return { { text = "Buff", value = "buff", checked = cfg().kind ~= "debuff" },
        { text = "Debuff", value = "debuff", checked = cfg().kind == "debuff" } } end,
      set = function(v) cfg().kind = v end },
    { type = "check", label = "Show when it is missing", desc = "For buffs everyone should have (shows \"!name\" on texts).",
      get = function() return cfg().missing and true or false end, set = function(v) cfg().missing = v end },
    colorRow("Colour", function() return cfg().color end, function(c) cfg().color = c end),
    { type = "number", label = "Priority", min = 0, max = 100, step = 1,
      get = function() return tonumber(cfg().prio) or 55 end, set = function(v) cfg().prio = v end },
  }
  for _, r in ipairs(more) do
    rows[#rows + 1] = r
  end
  indicatorRows(rows, cfg)
  return rows
end

local function kittyStatus()
  if not G.Clicks.HasKitty() then
    return "|cffff8080Cherry's KittyCombo is not loaded: kitties do nothing (macros and spells still work).|r"
  end
  local v = Kitty and (Kitty.VERSION or Kitty.version) or nil
  if type(Kitty.attackOn) == "function" then
    return "KittyCombo " .. tostring(v or "") .. " is ready (kitties run on the member, your target comes back)."
  end
  return "KittyCombo " .. tostring(v or "") .. ": older version, Grid swaps the target itself."
end

-- Changes the binding being edited: starts from what the key does now, in the new form.
local function editBinding(key, fn)
  local C = G.Clicks
  local t = C.Table(O.clickScope)
  local b = G.Copy(t[key] or C.Get(key) or {}) or {}
  local a1, act = C.Parts(b)
  b.type, b.act = a1, act
  fn(b)
  t[key] = b
end

-- Mouse 4 outside Grid. Across the account, not per profile, as the game's key bindings are.
local function mouseRows()
  local M = G.Mouse
  local rows = {
    header("Mouse 4 outside Grid"),
    {
      type = "check", label = "Use Mouse 4 as a game keybind", get = M.IsOn, set = M.SetOn, rebuild = true,
      desc = "Off: nothing changes outside Grid. On: Mouse 4 shows in the game's Key Bindings and works over windows and buttons.",
    },
  }
  if M.IsOn() then
    rows[#rows + 1] = info(M.Status)
    rows[#rows + 1] = button("Open the game's Key Bindings", M.OpenKeyBindings, "Click a slot, press Mouse 4, then Okay. Over Grid's own frames, Mouse 4 follows the bindings above.")
    for i, key in ipairs(M.KEYS) do
      rows[#rows + 1] = textRow(M.KEY_TITLES[i], function() return M.Describe(key) end, function(v) M.SetCommand(key, v) end,
        "A game action from Key Bindings, or type a slash command. Enter saves, empty clears.")
    end
    rows[#rows + 1] = info("Works with the cursor over a window or button, not the 3D world, as one press.")
  end
  rows[#rows + 1] = info("Mouse 5 never reaches the game: map it to a key in your mouse's software.")
  return rows
end

function BUILD.clicks()
  local C = G.Clicks
  local scopeList = { { "class", "This class (" .. G.ClassKey() .. ")" }, { "all", "All classes" } }
  local buttonList, modList, a1List, actList = {}, {}, {}, {}
  for _, b in ipairs(C.BUTTONS) do
    buttonList[#buttonList + 1] = { b.key, b.title }
  end
  for _, mod in ipairs(C.MODS) do
    modList[#modList + 1] = { mod, C.MOD_TITLES[mod] }
  end
  for _, a in ipairs(C.ACTIONS) do
    a1List[#a1List + 1] = { a.key, a.title }
  end
  for _, a in ipairs(C.ACTS) do
    actList[#actList + 1] = { a.key, a.title }
  end
  local key = C.Key(O.clickButton, O.clickMod)
  local function cur()
    return C.Get(key) or {}
  end
  local function own()
    return C.Table(O.clickScope)[key]
  end
  local function pick(label, list, getV, setV, desc, rebuild)
    return {
      type = "choice", label = label, desc = desc, rebuild = rebuild,
      text = function() return choiceText(list, getV()) end,
      items = function() return choiceItems(list, getV()) end,
      set = function(v) setV(v) end,
    }
  end
  local _, act = C.Parts(cur())
  local rows = {
    info(kittyStatus()),
    pick("Bindings for", scopeList, function() return O.clickScope end, function(v) O.clickScope = v end,
      "Kitties belong to a class, so bindings are kept per class pair; All classes fills the gaps.", true),
    pick("Mouse button", buttonList, function() return O.clickButton end, function(v) O.clickButton = v end, nil, true),
    pick("Key", modList, function() return O.clickMod end, function(v) O.clickMod = v end, nil, true),
    info(function()
      local b, from = C.Get(key)
      local where = own() and "" or ((from == "all") and "  |cff888888(from All classes)|r" or ((from == "default") and "  |cff888888(default)|r" or ""))
      return "|cffffd27f" .. C.MOD_TITLES[O.clickMod] .. " + " .. choiceText(buttonList, O.clickButton) .. ":|r  " .. C.Describe(b) .. where
    end),
    pick("1st action", a1List, function() return (C.Parts(cur())) end,
      function(v) editBinding(key, function(b) b.type = v end) end, "Runs first. Nothing = left out."),
    {
      type = "number", label = "Delay (ms)", min = 0, max = C.MAX_DELAY, step = 50,
      get = function() return tonumber(cur().delay) or 0 end,
      set = function(v) editBinding(key, function(b) b.delay = v end) end,
      desc = "Wait between the 1st and 2nd action. 0 = both at once. Shift+click changes it by 250.",
    },
    pick("2nd action", actList, function() local _, a = C.Parts(cur()) return a end,
      function(v) editBinding(key, function(b) b.act = v end) end, "Runs on the member you click.", true),
  }
  if act == "kitty" then
    rows[#rows + 1] = {
      type = "choice", label = "Kitty",
      text = function() return tostring(cur().kitty or "(choose)") end,
      items = function()
        local items = {}
        for _, k in ipairs(C.KittyNames()) do
          items[#items + 1] = { text = (k.mine and "|cffffd27f" or "") .. k.name .. (k.mine and "|r" or ""), value = k.name,
            checked = cur().kitty == k.name }
        end
        if #items == 0 then
          items[1] = { text = "No kitties found (type a name below)", isTitle = true, notCheckable = true }
        end
        return items
      end,
      set = function(v) editBinding(key, function(b) b.kitty = v end) end,
      desc = "Kitties of your class are listed first (gold).",
    }
    rows[#rows + 1] = textRow("Or type a kitty name", function() return cur().kitty or "" end, function(v)
      v = string.gsub(v or "", "^%s*(.-)%s*$", "%1")
      if v ~= "" then
        editBinding(key, function(b) b.kitty = v end)
      end
    end, "Enter saves it.")
  elseif act == "macro" then
    rows[#rows + 1] = {
      type = "choice", label = "Macro",
      text = function()
        local b = cur()
        return b.macro and tostring(b.macro) or "(choose)"
      end,
      items = function()
        local items = {}
        for _, m in ipairs(C.Macros()) do
          local text = m.kitty and ("|cffffd27f" .. m.name .. "|r  (kitty " .. m.kitty .. ")") or (m.name .. "  |cff888888(slot " .. m.slot .. ")|r")
          items[#items + 1] = { text = text, value = { slot = m.slot, name = m.name }, checked = cur().macro == m.name }
        end
        if #items == 0 then
          items[1] = { text = "No macros in the macro window", isTitle = true, notCheckable = true }
        end
        return items
      end,
      set = function(v) editBinding(key, function(b) b.macro, b.slot = v.name, v.slot end) end,
      desc = "Kitty macros (gold) run their kitty on the member; other macros run with the member targeted.",
    }
  elseif act == "spell" then
    local tabs = {}
    for _, t in ipairs(C.BOOK_TABS) do
      tabs[#tabs + 1] = { t[1], t[2] .. " (" .. #C.Spells(t[1]) .. ")" }
    end
    rows[#rows + 1] = pick("Spellbook tab", tabs, function() return O.bookTab end, function(v) O.bookTab = v end, nil, true)
    rows[#rows + 1] = {
      type = "choice", label = "Spell",
      text = function() return tostring(cur().spell or "(choose)") end,
      items = function()
        local items = {}
        for _, s in ipairs(C.Spells(O.bookTab)) do
          items[#items + 1] = { text = s.name, value = s.name, checked = cur().spell == s.name }
        end
        if #items == 0 then
          items[1] = { text = "No skills on this tab", isTitle = true, notCheckable = true }
        end
        return items
      end,
      set = function(v) editBinding(key, function(b) b.spell = v end) end,
      desc = "Cast on the member you click; your target comes back unless the 1st action is Target.",
    }
  end
  rows[#rows + 1] = button(O.clickScope == "class" and "Clear (use All classes)" or "Clear (use default)", function()
    C.Set(O.clickScope, key, nil)
  end, "Removes this key's binding from " .. (O.clickScope == "class" and "this class." or "All classes."))
  rows[#rows + 1] = header(choiceText(buttonList, O.clickButton) .. " with each key")
  for _, mod in ipairs(C.MODS) do
    local k = C.Key(O.clickButton, mod)
    rows[#rows + 1] = info(function()
      return C.MOD_TITLES[mod] .. ":  " .. C.Describe((C.Get(k)))
    end)
  end
  local more = {
    header("How clicks behave"),
    check("Keep the member targeted after a kitty", "keepTarget", "Off: your old target comes back after the 2nd action (unless the 1st action is Target)."),
    check("Act when the button is released", "clickOnUp", "Off: on press (faster)."),
  }
  for _, r in ipairs(more) do
    rows[#rows + 1] = r
  end
  for _, r in ipairs(mouseRows()) do
    rows[#rows + 1] = r
  end
  return rows
end

function BUILD.general()
  return {
    header("Tooltip"),
    choice("Show the tooltip", "tooltip", TOOLTIP),
    choice("Tooltip position", "tooltipAnchor", TT_ANCHOR),
    check("Buffs and debuffs in it", "tooltipAuras"),
    header("The game's own frames"),
    choice("Hide the party frames", "hidePartyFrames", HIDE_PARTY, "The game's party frames on the left of the screen.", true),
    check("Hide the player frame", "hidePlayerFrame", "Your own portrait frame.", true),
    info("A hidden party frame comes back when you change this (or after the next party change)."),
  }
end

function BUILD.profiles()
  local names = G.ProfileNames()
  local list = {}
  for _, n in ipairs(names) do
    list[#list + 1] = { n, n }
  end
  local rows = {
    info("Profile in use now: |cffffd27f" .. G.profileName .. "|r (" .. G.groupType .. ")"),
    header("Profile for this character"),
  }
  for _, kind in ipairs({ "solo", "party", "raid" }) do
    local title = (kind == "solo") and "When solo" or ((kind == "party") and "In a party" or "In a raid")
    rows[#rows + 1] = {
      type = "choice", label = title,
      text = function() return G.CharProfiles()[kind] or "Default" end,
      items = function() return choiceItems(list, G.CharProfiles()[kind] or "Default") end,
      set = function(v)
        G.CharProfiles()[kind] = v
        G.LoadProfile()
      end,
      layout = true, rebuild = true,
    }
  end
  local more = {
    header("New profile (a copy of the one in use)"),
    textRow("Name", function() return O.newProfile end, function(v) O.newProfile = v end),
    button("Create", function()
      if G.NewProfile(O.newProfile, G.profileName) then
        G.Print("profile \"" .. O.newProfile .. "\" made. Pick it above.")
        O.newProfile = ""
      else
        G.Print("type a new, unused name first.")
      end
    end),
    header("The profile in use"),
    button("Reset to defaults", function()
      G.ResetProfile()
      G.Print("profile \"" .. G.profileName .. "\" is back to the defaults.")
    end),
    button("Delete it", function()
      local name = G.profileName
      if G.DeleteProfile(name) then
        G.LoadProfile()
        G.Print("profile \"" .. name .. "\" deleted.")
      else
        G.Print("the Default profile stays.")
      end
    end),
    info("Party and raid can use different profiles, as GridCliqueIt's separate raid settings did."),
  }
  for _, r in ipairs(more) do
    r.layout = r.layout or (r.type == "button")
    rows[#rows + 1] = r
  end
  return rows
end

function BUILD.about()
  return {
    header("Cherry's Grid " .. G.version),
    info("Compact party and raid frames in the look of WoW's Grid, with kitty clicks."),
    info("Drag the \"Grid\" tab to move the frames, right-click it for this window."),
    info("Commands: /grid, /grid test, /grid lock, /grid unlock, /grid reset, /grid probe"),
    button("Test members on / off", function()
      G.Roster.SetTest(not G.Roster.test)
    end),
    button("Run the probe (chat)", function() G.Probe.Run() end),
    header("Credits"),
    info("Ideas from Grid (WoW) by Maia, Pastamancer and Phanx,"),
    info("and GridCliqueIt (RoM) by Skaryon, Jacobian and odie2."),
    info("Written new for Cherry's Kit; no code of either is used."),
  }
end

---------------------------------------------------------------------------
-- Drawing the rows
---------------------------------------------------------------------------

local function row(i)
  local name = "CGrid_OptRow" .. i
  return {
    frame = _G[name], label = _G[name .. "Label"], check = _G[name .. "Check"], minus = _G[name .. "Minus"],
    value = _G[name .. "Value"], plus = _G[name .. "Plus"], choice = _G[name .. "Choice"], edit = _G[name .. "Edit"],
    swatch = _G[name .. "Swatch"], name = name,
  }
end

local function hideAll(r)
  for _, k in ipairs({ "check", "minus", "value", "plus", "choice", "edit", "swatch" }) do
    if r[k] then
      r[k]:Hide()
    end
  end
end

local function fmtNumber(d, v)
  if d.fmt then
    return d.fmt(v)
  end
  if math.floor(v) == v then
    return tostring(v)
  end
  return string.format("%.2f", v)
end

local function labelAt(r, x, color)
  if not r.label then
    return
  end
  G.Try(r.label, "ClearAllAnchors")
  G.Try(r.label, "SetAnchor", "LEFT", "LEFT", r.name, x, 0)
  if color then
    G.Try(r.label, "SetColor", color[1], color[2], color[3])
  end
end

function O.Draw()
  if not CGrid_Options or not CGrid_Options:IsVisible() then
    return
  end
  local total = #O.rows
  local maxScroll = math.max(0, total - O.ROWS)
  if O.scroll > maxScroll then
    O.scroll = maxScroll
  end
  for i = 1, O.ROWS do
    local r = row(i)
    local d = O.rows[i + O.scroll]
    if r.frame then
      hideAll(r)
      if not d then
        r.frame:Hide()
      else
        r.frame:Show()
        local label = d.label
        if type(label) == "function" then
          local ok, text = pcall(label)
          label = ok and text or ""
        end
        r.label:SetText(label or "")
        if d.type == "header" then
          labelAt(r, 0, { 1, 0.82, 0 })
        elseif d.type == "info" then
          labelAt(r, 8, { 0.75, 0.8, 0.85 })
        elseif d.type == "check" then
          labelAt(r, 30, { 1, 1, 1 })
          r.check:SetChecked(d.get() and true or false)
          r.check:Show()
        elseif d.type == "number" then
          labelAt(r, 8, { 1, 1, 1 })
          r.value:SetText(fmtNumber(d, d.get()))
          r.minus:Show()
          r.value:Show()
          r.plus:Show()
        elseif d.type == "choice" or d.type == "color" then
          labelAt(r, 8, { 1, 1, 1 })
          r.choice:SetText(d.text() or "")
          r.choice:Show()
          if d.type == "color" and r.swatch then
            local c = d.getColor() or { 1, 1, 1 }
            G.Try(r.swatch, "SetTexture", G.MEDIA .. "white.tga")
            G.Try(r.swatch, "SetColor", c[1], c[2], c[3])
            r.swatch:Show()
          end
        elseif d.type == "text" then
          labelAt(r, 8, { 1, 1, 1 })
          r.edit:SetText(tostring(d.get() or ""))
          r.edit:Show()
        elseif d.type == "button" then
          r.label:SetText("")
          r.choice:SetText(d.label or "")
          r.choice:Show()
        end
      end
    end
  end
  for i, p in ipairs(O.PAGES) do
    local b = _G["CGrid_OptNav" .. i]
    if b then
      b:SetText((p.key == O.page) and ("> " .. p.title) or p.title)
    end
  end
  if CGrid_OptionsScroll then
    if maxScroll > 0 then
      CGrid_OptionsScroll:SetText(string.format("%d-%d of %d%s", O.scroll + 1, math.min(total, O.scroll + O.ROWS), total,
        (O.scroll + O.ROWS < total) and "  |cffffd27fmore below (v)|r" or ""))
    else
      CGrid_OptionsScroll:SetText("")
    end
  end
  if CGrid_OptionsTitle then
    CGrid_OptionsTitle:SetText("Cherry's Grid  |cff888888" .. G.profileName .. "|r")
  end
  if CGrid_OptTest then
    CGrid_OptTest:SetText(G.Roster.test and "Stop test" or "Test members")
  end
  if CGrid_OptLock then
    CGrid_OptLock:SetText(G.P.locked and "Unlock" or "Lock")
  end
end

function O.Build()
  local fn = BUILD[O.page] or BUILD.layout
  local ok, rows = pcall(fn)
  if not ok then
    G.Print("options page error: " .. tostring(rows))
    rows = {}
  end
  O.rows = rows
  O.Draw()
end

function O.Refresh()
  if CGrid_Options and CGrid_Options:IsVisible() then
    O.Build()
  end
end

local function changed(d)
  if d and d.layout then
    G.Refresh(true)
  else
    G.Auras.Forget()
    G.allDirty = true
  end
  if d and d.rebuild then
    O.Build()
  else
    O.Draw()
  end
end

---------------------------------------------------------------------------
-- From CherrysGrid.xml
---------------------------------------------------------------------------

function O.Toggle()
  if not CGrid_Options then
    return
  end
  if CGrid_Options:IsVisible() then
    CGrid_Options:Hide()
  else
    CGrid_Options:Show()
    O.Build()
  end
end

function O.Nav(i)
  local p = O.PAGES[i]
  if p then
    O.page = p.key
    O.scroll = 0
    O.Build()
  end
end

function O.Scroll(delta)
  delta = tonumber(delta) or 0
  if delta > 0 then
    O.scroll = math.max(0, O.scroll - 3)
  elseif delta < 0 then
    O.scroll = O.scroll + 3
  end
  O.Draw()
end

-- Opens a row's list; longer lists than a menu holds get "Next page" / "Previous page" entries.
O.PAGE = 28
function O.OpenList(frame, d, items, page)
  local shown = items
  local pages = math.max(1, math.ceil(#items / O.PAGE))
  if #items > G.Menu.MAX then
    shown = {}
    if page > 1 then
      shown[#shown + 1] = { text = "|cffffd27f<< Previous page|r", value = { cgPage = page - 1 }, notCheckable = true }
    end
    for j = (page - 1) * O.PAGE + 1, math.min(#items, page * O.PAGE) do
      shown[#shown + 1] = items[j]
    end
    if page < pages then
      shown[#shown + 1] = { text = "|cffffd27fNext page >> (" .. (page + 1) .. " of " .. pages .. ")|r", value = { cgPage = page + 1 }, notCheckable = true }
    end
  end
  G.Menu.Open(frame, shown, function(value)
    if type(value) == "table" and value.cgPage then
      -- the menu closes itself after this click: open the next page on the next frame
      O.deferred = function()
        O.OpenList(frame, d, items, value.cgPage)
      end
      return
    end
    d.set(value)
    changed(d)
  end)
end

function O.Click(i, what, frame)
  local d = O.rows[i + O.scroll]
  if not d then
    return
  end
  if what == "check" then
    d.set(not d.get())
    changed(d)
  elseif what == "minus" or what == "plus" then
    local step = d.step or 1
    if IsShiftKeyDown and IsShiftKeyDown() then
      step = step * 5
    end
    local v = d.get() + ((what == "plus") and step or -step)
    v = math.floor(v / (d.step or 1) + 0.5) * (d.step or 1)
    if v < d.min then
      v = d.min
    elseif v > d.max then
      v = d.max
    end
    d.set(v)
    changed(d)
  elseif what == "choice" then
    if d.type == "button" then
      d.fn()
      G.Refresh(true)
      O.Build()
      return
    end
    O.OpenList(frame, d, d.items(), 1)
  elseif what == "edit" then
    local edit = _G["CGrid_OptRow" .. i .. "Edit"]
    if edit then
      d.set(edit:GetText() or "")
      G.Try(edit, "ClearFocus")
      changed(d)
    end
  end
end

function O.Enter(i)
  local d = O.rows[i + O.scroll]
  if CGrid_OptionsHint then
    CGrid_OptionsHint:SetText((d and d.desc) or "")
  end
end

function O.TestButton()
  G.Roster.SetTest(not G.Roster.test)
  G.Refresh(true)
  O.Draw()
end

function O.LockButton()
  G.P.locked = not G.P.locked
  G.Layout.Apply()
  O.Build()
end
