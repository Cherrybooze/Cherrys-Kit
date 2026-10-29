-- Cherry's Grid: what a mouse button does on a member. Each button + modifier has two actions,
-- run in order: a 1st action (target, assist, member menu, follow) and a 2nd action that runs a
-- Cherry's KittyCombo kitty, a macro (kitty macros first) or a skill from the spellbook on the
-- member. A delay in ms can sit between them (0 = both at once).
--
-- Bindings are saved per class pair (main/sub, because kitties are made per class) in
-- CherrysGrid_DB.bindings["AUGUR/DRUID"], with "*" for all classes. Keys look like
-- "LBUTTON", "shift-RBUTTON", "ctrl-alt-MBUTTON", "WHEELUP". A binding:
--   { type = "target", delay = 0, act = "kitty", kitty = "ds_01" }
--   act "macro": macro = macro name, slot = macro slot;  act "spell": spell = skill name
-- Bindings from 1.0.0 ({ type = "kitty", kitty = }) still work: no 1st action, kitty 2nd.

local G = CherrysGrid
local C = {}
G.Clicks = C

C.BUTTONS = {
  { key = "LBUTTON", title = "Left button" },
  { key = "RBUTTON", title = "Right button" },
  { key = "MBUTTON", title = "Middle button" },
  { key = "WHEELUP", title = "Wheel up" },
  { key = "WHEELDOWN", title = "Wheel down" },
}
C.MODS = { "", "shift", "ctrl", "alt", "shift-ctrl", "shift-alt", "ctrl-alt", "shift-ctrl-alt" }
C.MOD_TITLES = { [""] = "No key", shift = "Shift", ctrl = "Ctrl", alt = "Alt", ["shift-ctrl"] = "Shift+Ctrl",
  ["shift-alt"] = "Shift+Alt", ["ctrl-alt"] = "Ctrl+Alt", ["shift-ctrl-alt"] = "Shift+Ctrl+Alt" }

-- 1st actions
C.ACTIONS = {
  { key = "none", title = "Nothing" },
  { key = "target", title = "Target" },
  { key = "assist", title = "Assist (target their target)" },
  { key = "menu", title = "Member menu" },
  { key = "follow", title = "Follow" },
}
-- 2nd actions
C.ACTS = {
  { key = "none", title = "Nothing" },
  { key = "kitty", title = "Use kitty" },
  { key = "macro", title = "Use macro" },
  { key = "spell", title = "Cast spell" },
}
C.MAX_DELAY = 5000

C.DEFAULTS = {
  LBUTTON = { type = "target" },
  RBUTTON = { type = "menu" },
}

C.FOCUS_SLOT = 12 -- prefer an empty high focus slot for temporary target storage

local function chat(text)
  G.Print(text)
end

function C.Key(button, mod)
  if not mod or mod == "" then
    return button
  end
  return mod .. "-" .. button
end

function C.CurrentMod()
  local parts = {}
  if IsShiftKeyDown and IsShiftKeyDown() then
    parts[#parts + 1] = "shift"
  end
  if IsCtrlKeyDown and IsCtrlKeyDown() then
    parts[#parts + 1] = "ctrl"
  end
  if IsAltKeyDown and IsAltKeyDown() then
    parts[#parts + 1] = "alt"
  end
  return table.concat(parts, "-")
end

-- The binding table for a scope: "class" (this class pair) or "all" ("*").
function C.Table(scope)
  local d = G.DB()
  local key = (scope == "all") and "*" or G.ClassKey()
  if type(d.bindings[key]) ~= "table" then
    d.bindings[key] = {}
  end
  return d.bindings[key]
end

-- What a key does: this class's binding, else the all-classes one, else the default.
function C.Get(key)
  local d = G.DB()
  local mine = d.bindings[G.ClassKey()]
  if type(mine) == "table" and mine[key] then
    return mine[key], "class"
  end
  local all = d.bindings["*"]
  if type(all) == "table" and all[key] then
    return all[key], "all"
  end
  return C.DEFAULTS[key], "default"
end

function C.Set(scope, key, binding)
  C.Table(scope)[key] = binding
end

-- The two actions of a binding: 1st action key, 2nd action key, delay in seconds.
function C.Parts(b)
  if not b then
    return "none", "none", 0
  end
  if b.type == "kitty" and not b.act then
    return "none", "kitty", 0
  end
  local delay = math.max(0, math.min(C.MAX_DELAY, tonumber(b.delay) or 0)) / 1000
  return b.type or "none", b.act or "none", delay
end

local function title(list, key)
  for _, a in ipairs(list) do
    if a.key == key then
      return a.title
    end
  end
  return tostring(key)
end

function C.DescribeAct(b)
  local _, act = C.Parts(b)
  if act == "kitty" then
    return "Kitty: " .. tostring(b.kitty or "?")
  elseif act == "macro" then
    return "Macro: " .. tostring(b.macro or ("slot " .. tostring(b.slot)))
  elseif act == "spell" then
    return "Spell: " .. tostring(b.spell or "?")
  end
  return nil
end

-- "Target | Kitty: ds_01", "Kitty: Heal", "Target | 200 ms | Spell: Heal". A 1st action of "Nothing" is left out.
function C.Describe(b)
  local a1, _, delay = C.Parts(b)
  local parts = {}
  if a1 ~= "none" then
    parts[#parts + 1] = title(C.ACTIONS, a1)
  end
  local second = C.DescribeAct(b)
  if second then
    if a1 ~= "none" and delay > 0 then
      parts[#parts + 1] = math.floor(delay * 1000 + 0.5) .. " ms"
    end
    parts[#parts + 1] = second
  end
  if #parts == 0 then
    return "Nothing"
  end
  return table.concat(parts, " | ")
end

---------------------------------------------------------------------------
-- Kitties (Cherry's KittyCombo)
---------------------------------------------------------------------------

function C.HasKitty()
  return type(Kitty) == "table" and type(Kitty.attack) == "function"
end

-- Kitty names for the menus: this class's kitties first. At most `max` names.
function C.KittyNames(max)
  local out, seen = {}, {}
  if not C.HasKitty() or not Kitty.Predict or type(Kitty.Predict.listKitties) ~= "function" then
    return out
  end
  local ok, all = pcall(Kitty.Predict.listKitties, false)
  if not ok or type(all) ~= "table" then
    return out
  end
  table.sort(all, function(a, b)
    if (a.mine and true or false) ~= (b.mine and true or false) then
      return a.mine and true or false
    end
    return tostring(a.name) < tostring(b.name)
  end)
  for _, k in ipairs(all) do
    if k.name and not seen[k.name] then
      seen[k.name] = true
      out[#out + 1] = { name = k.name, mine = k.mine, class = k.class }
      if max and #out >= max then
        break
      end
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Macros and spellbook
---------------------------------------------------------------------------

-- The kitty a macro runs ("/run Kitty.attack([[name]])", or with quotes), or nil.
function C.KittyOfMacro(body)
  body = tostring(body or "")
  local name = string.match(body, "[Kk]itty%.attack%s*%(%s*%[=*%[(.-)%]=*%]%s*%)")
    or string.match(body, '[Kk]itty%.attack%s*%(%s*"(.-)"%s*%)')
    or string.match(body, "[Kk]itty%.attack%s*%(%s*'(.-)'%s*%)")
  return name
end

local function macroSlots()
  if type(MAX_NUM_MACROS) == "number" and MAX_NUM_MACROS > 0 then
    return MAX_NUM_MACROS
  end
  return 49
end

-- Every macro in the macro window: { slot, name, body, kitty }. Kitty macros first.
function C.Macros()
  local out = {}
  if type(GetMacroInfo) ~= "function" then
    return out
  end
  for slot = 1, macroSlots() do
    local ok, _, name, body = pcall(GetMacroInfo, slot)
    if ok and ((name and name ~= "") or (body and body ~= "")) then
      out[#out + 1] = { slot = slot, name = (name and name ~= "") and name or ("Macro " .. slot), body = body or "",
        kitty = C.KittyOfMacro(body) }
    end
  end
  table.sort(out, function(a, b)
    if (a.kitty and true or false) ~= (b.kitty and true or false) then
      return a.kitty and true or false
    end
    return a.slot < b.slot
  end)
  return out
end

-- The macro of a binding: by slot when the name still matches, else by name (macros get moved).
function C.FindMacro(b)
  if type(GetMacroInfo) ~= "function" then
    return nil
  end
  if b.slot then
    local ok, _, name, body = pcall(GetMacroInfo, b.slot)
    if ok and (b.macro == nil or name == b.macro) and body then
      return body
    end
  end
  for _, m in ipairs(C.Macros()) do
    if m.name == b.macro then
      return m.body
    end
  end
  return nil
end

C.BOOK_TABS = { { 1, "General" }, { 2, "Main class" }, { 3, "Sub class" }, { 4, "Tab 4" } }

-- Skills of a spellbook tab: { name, tab, index }.
function C.Spells(tab)
  local out = {}
  if type(GetNumSkill) ~= "function" or type(GetSkillDetail) ~= "function" then
    return out
  end
  local ok, n = pcall(GetNumSkill, tab)
  n = ok and tonumber(n) or 0
  for i = 1, n do
    local ok2, name = pcall(GetSkillDetail, tab, i)
    if ok2 and name and name ~= "" then
      out[#out + 1] = { name = name, tab = tab, index = i }
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Running on a member
---------------------------------------------------------------------------

local function guid(unit)
  if type(UnitGUID) == "function" then
    local ok, value = pcall(UnitGUID, unit)
    if ok and value and value ~= 0 and value ~= "" then return value end
  end
end

local function sameUnit(a, b)
  local ga, gb = guid(a), guid(b)
  if ga and gb then return ga == gb end
  if type(UnitIsUnit) == "function" then
    local ok, value = pcall(UnitIsUnit, a, b)
    return ok and value ~= nil and value ~= false and value ~= 0
  end
  return false -- names alone cannot distinguish two NPCs with the same name
end

local function clientCall(fn, ...)
  if type(fn) ~= "function" then return false end
  local ok, value = pcall(fn, ...)
  return ok and value ~= false and value ~= 0 -- the documented calls return nil on success
end

-- TargetUnit accepts unit IDs, not names/GUIDs or an assumed last-target token.
-- Reuse a stable ID first, then verify a new stash before changing the target.
local function saveTarget()
  for _, unit in ipairs({ "player", "pet" }) do
    if sameUnit("target", unit) then return unit end
  end
  for _, group in ipairs({ { "party", 5 }, { "raid", 36 }, { "focus", 12 } }) do
    for i = 1, group[2] do
      local unit = group[1] .. i
      if sameUnit("target", unit) then return unit end
      if group[1] ~= "focus" and sameUnit("target", unit .. "pet") then return unit .. "pet" end
    end
  end
  if type(FocusUnit) == "function" then
    for slot = C.FOCUS_SLOT, 1, -1 do
      local unit = "focus" .. slot
      if not G.U.Exists(unit) then
        if clientCall(FocusUnit, slot, "target") and sameUnit("target", unit) then return unit, slot end
        pcall(FocusUnit, slot, "") -- this slot was empty before our attempt
        return nil
      end
    end
  end
end

-- Runs fn with the member targeted, then gives the old target back (unless keep).
function C.OnMember(unit, keep, fn)
  local hadTarget = G.U.Exists("target")
  local already = hadTarget and sameUnit("target", unit)
  local oldGuid, restore, slot = guid("target")
  if hadTarget and not already and not keep then
    restore, slot = saveTarget()
    if not restore then
      chat("click action skipped: this client could not preserve your current target.")
      return false
    end
  end
  local ok, err = pcall(function()
    if not already and (not clientCall(TargetUnit, unit) or not sameUnit("target", unit)) then
      error("could not target the clicked member", 0)
    end
    fn()
    if SpellIsTargeting and SpellIsTargeting() then
      if not clientCall(SpellTargetUnit, unit) then error("could not give the spell its target", 0) end
    end
  end)
  local restored = true
  if not already and not keep then
    if hadTarget then
      -- A vanished/reassigned unit ID must not be sent to TargetUnit: that can
      -- clear the current target. Check both availability and the result.
      restored = G.U.Exists(restore) and (not oldGuid or guid(restore) == oldGuid)
        and clientCall(TargetUnit, restore) and sameUnit("target", restore)
        and (not oldGuid or guid("target") == oldGuid)
    else
      restored = clientCall(TargetUnit, "") and not G.U.Exists("target")
    end
  end
  if slot then
    local cleared = clientCall(FocusUnit, slot, "") and not G.U.Exists("focus" .. slot)
    if not cleared then chat("could not clear the temporary focus slot " .. slot .. ".") end
  end
  if not restored then chat("could not restore your previous target after the click action.") end
  if not ok then
    chat("error: " .. tostring(err))
  end
  return ok and restored and true or false
end

-- Runs a kitty with the member as its target, then gives the old target back.
function C.RunKitty(unit, name, keep)
  if not C.HasKitty() then
    chat("Cherry's KittyCombo is not loaded, so kitty \"" .. tostring(name) .. "\" can't run.")
    return false
  end
  keep = keep or (G.P.keepTarget and true or false)
  if type(Kitty.attackOn) == "function" then
    local ok, fired = pcall(Kitty.attackOn, unit, name, keep)
    if not ok then
      chat("kitty error: " .. tostring(fired))
      return false
    end
    return fired
  end
  -- KittyCombo before 1.7.5: do the same here
  if SpellIsTargeting and SpellIsTargeting() then
    SpellTargetUnit(unit)
    return true
  end
  local basic = Kitty.SettingManager and Kitty.SettingManager.setting and Kitty.SettingManager.setting.basic
  local skip, auto
  if type(basic) == "table" then
    skip, auto = basic.skipTarget, basic.useAutoshot
    basic.skipTarget, basic.useAutoshot = false, false
  end
  local ok = C.OnMember(unit, keep, function()
    Kitty.attack(name)
  end)
  if type(basic) == "table" then
    basic.skipTarget, basic.useAutoshot = skip, auto
  end
  return ok
end

-- A macro on the member: a kitty macro runs its kitty (as above), other macros run line by line.
function C.RunMacro(unit, b, keep)
  local body = C.FindMacro(b)
  if not body then
    chat("macro \"" .. tostring(b.macro) .. "\" not found in the macro window.")
    return false
  end
  local kitty = C.KittyOfMacro(body)
  if kitty then
    return C.RunKitty(unit, kitty, keep)
  end
  if type(ExecuteMacroLine) ~= "function" then
    chat("this client can't run macros from addons.")
    return false
  end
  return C.OnMember(unit, keep or (G.P.keepTarget and true or false), function()
    for line in string.gmatch(body, "[^\r\n]+") do
      if not string.find(line, "^%s*$") then
        ExecuteMacroLine(line)
      end
    end
  end)
end

function C.RunSpell(unit, name, keep)
  if SpellIsTargeting and SpellIsTargeting() then
    SpellTargetUnit(unit)
    return true
  end
  if type(CastSpellByName) ~= "function" then
    return false
  end
  return C.OnMember(unit, keep or (G.P.keepTarget and true or false), function()
    CastSpellByName(name)
  end)
end

---------------------------------------------------------------------------
-- Member menu (the game's own player / party / target menus)
---------------------------------------------------------------------------

function C.Menu(unit, frame)
  if type(ToggleDropDownMenu) ~= "function" then
    return
  end
  local menu
  if G.U.IsUnit(unit, "player") then
    menu = PlayerFrameDropDown
  else
    local party = string.match(unit, "^party(%d+)$")
    if party then
      menu = _G["UnitFrame_party" .. party .. "DropDown"]
    end
    if not menu then
      TargetUnit(unit)
      menu = TargetFrameDropDown
    end
  end
  if menu then
    menu.unit = unit
    menu.name = G.U.Name(unit)
    if not pcall(ToggleDropDownMenu, menu, 1, nil, frame) then
      pcall(ToggleDropDownMenu, 1, nil, menu, frame)
    end
  end
end

---------------------------------------------------------------------------
-- A click on a member (Frames.OnMouseDown / OnMouseUp / OnMouseWheel)
---------------------------------------------------------------------------

C.queue = {} -- 2nd actions waiting for their delay: { at =, unit =, b =, keep = }
C.clock = 0

local function first(a1, unit, frame)
  if a1 == "target" then
    TargetUnit(unit)
  elseif a1 == "assist" then
    if AssistUnit then
      AssistUnit(unit)
    end
  elseif a1 == "menu" then
    C.Menu(unit, frame)
  elseif a1 == "follow" then
    if FollowUnit then
      FollowUnit(unit)
    end
  end
end

function C.Second(unit, b, keep)
  local _, act = C.Parts(b)
  if act == "kitty" then
    C.RunKitty(unit, b.kitty, keep)
  elseif act == "macro" then
    C.RunMacro(unit, b, keep)
  elseif act == "spell" then
    C.RunSpell(unit, b.spell, keep)
  end
  G.allDirty = true
end

function C.Run(unit, button, frame)
  if not unit or not button then
    return
  end
  C.seen = C.seen or {}
  C.seen[tostring(button)] = true -- for /grid probe: which button names this client sends
  local key = C.Key(button, C.CurrentMod())
  local b = C.Get(key)
  if G.U.TestIndex(unit) then
    chat("test member " .. tostring(G.U.Name(unit)) .. ": " .. C.Describe(b))
    return
  end
  local a1, act, delay = C.Parts(b)
  if a1 == "none" and act == "none" then
    return
  end
  -- a skill waiting for a target (ground or click-to-target) takes the member first
  if act == "none" and SpellIsTargeting and SpellIsTargeting() then
    SpellTargetUnit(unit)
    return
  end
  first(a1, unit, frame)
  -- after "Target" the member stays targeted; otherwise the 2nd action gives your target back
  local keep = (a1 == "target")
  if act ~= "none" then
    if delay > 0 and a1 ~= "none" then
      C.queue[#C.queue + 1] = { at = C.clock + delay, unit = unit, b = b, keep = keep }
    else
      C.Second(unit, b, keep)
    end
  end
  G.allDirty = true
end

-- From Core's OnUpdate: runs the 2nd actions whose delay is over.
function C.Tick(elapsed)
  C.clock = C.clock + (tonumber(elapsed) or 0)
  if #C.queue == 0 then
    return
  end
  local due, rest = {}, {}
  for _, q in ipairs(C.queue) do
    if q.at <= C.clock then
      due[#due + 1] = q
    else
      rest[#rest + 1] = q
    end
  end
  C.queue = rest
  for _, q in ipairs(due) do
    C.Second(q.unit, q.b, q.keep)
  end
end

function C.Wheel(frame, delta)
  local slot = frame and tonumber(string.match(frame:GetName() or "", "(%d+)$"))
  delta = tonumber(delta) or 0
  if slot and delta ~= 0 then
    C.Run(G.Frames.unitOf[slot], delta > 0 and "WHEELUP" or "WHEELDOWN", frame)
  end
end
