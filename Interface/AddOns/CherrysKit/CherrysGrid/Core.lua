-- Cherry's Grid: compact party and raid frames for Runes of Magic, in the look of WoW's Grid,
-- with clicks that run Cherry's KittyCombo kitties on the member you click.
-- Written for Cherry's Kit. Ideas from Grid (WoW, by Maia, Pastamancer and Phanx) and
-- GridCliqueIt (RoM, by Skaryon, Jacobian and odie2); no code of either is used.
--
-- Files: Core (settings, events, commands), Roster (who is shown where), Auras (buffs and
-- debuffs), Statuses (what can be shown), Frames (drawing one member), Layout (placing the
-- members), Clicks (mouse buttons), Mouse (Mouse 4 outside Grid), Tooltip, Menu (drop-down lists),
-- Options (/grid window), Probe.

CherrysGrid = {}
local G = CherrysGrid

G.version = "1.1.5"
G.BASE_PATH = (CherrysKit_Paths and CherrysKit_Paths.CherrysGrid) or "Interface/AddOns/CherrysGrid/"
G.MEDIA = G.BASE_PATH .. "Media/"
G.MAX_UNITS = 48 -- 36 members + 12 pets; the frames are declared in CherrysGrid.xml

if SaveVariables then
  SaveVariables("CherrysGrid_DB")
end

local function chat(text, r, g, b)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fd0ffCherry's Grid:|r " .. tostring(text), r or 1, g or 1, b or 1)
  end
end
G.Print = chat

function G.IsOn()
  return not (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("CherrysGrid"))
end

-- Calls obj:method(...) only when the client has that method. Returns true when it ran.
function G.Try(obj, method, ...)
  if obj and type(obj[method]) == "function" then
    local ok = pcall(obj[method], obj, ...)
    return ok
  end
  return false
end

function G.Copy(t)
  if type(t) ~= "table" then
    return t
  end
  local c = {}
  for k, v in pairs(t) do
    c[k] = G.Copy(v)
  end
  return c
end

-- Fills in what `t` is missing from `defaults` (recursively); keeps what the player changed.
function G.Merge(t, defaults)
  for k, v in pairs(defaults) do
    if t[k] == nil then
      t[k] = G.Copy(v)
    elseif type(v) == "table" and type(t[k]) == "table" and not v[1] then
      G.Merge(t[k], v)
    end
  end
  return t
end

---------------------------------------------------------------------------
-- Defaults (one profile). Statuses and indicators are described in Statuses.lua.
---------------------------------------------------------------------------

G.DEFAULTS = {
  -- Layout
  locked = false,
  hideTab = false,
  showSolo = true,
  showParty = true,
  showRaid = true,
  showPets = false,
  playerFirst = true,
  groupBy = "group",      -- group | class | role | none
  sortBy = "index",       -- index | name | class
  perLine = 6,            -- members in one column (row) when groupBy is "none"
  horizontal = false,     -- false: each group is a column; true: each group is a row
  anchor = "TOPLEFT",     -- the corner the layout grows from
  raidGroups = { true, true, true, true, true, true },
  spacing = 1,
  groupSpacing = 6,
  padding = 5,
  bgColor = { 0.06, 0.06, 0.06, 0.7 },
  borderColor = { 0.45, 0.45, 0.45, 1 },
  showBorder = true,
  x = 300,
  y = 300,
  hidePartyFrames = "raid", -- never | raid | always: the game's own party frames
  hidePlayerFrame = false,

  -- One member
  width = 100,
  height = 52,
  scale = 1,
  orientation = "VERTICAL", -- VERTICAL fills bottom to top (Grid), HORIZONTAL left to right
  texture = "gradient",     -- gradient | flat | glass | smooth
  invert = false,           -- dark bar on a class coloured background
  bgDarkness = 0.25,        -- background brightness compared with the bar colour
  frameBorder = 1,          -- black edge round each member
  borderSize = 2,           -- border indicator thickness
  cornerSize = 7,
  iconSize = 16,
  iconTime = false,         -- seconds left on the centre icon (Grid shows none)
  iconStacks = true,
  textSize = 1,
  textLength = 6,
  colorScheme = "rom",      -- rom | wow | white: class colours
  nameClassColor = false,   -- name text in class colour (else white)
  manaSize = 3,             -- 0 hides the mana bar
  manaWho = "healers",      -- all | healers | me
  skillBar = false,         -- rage / energy / focus as a second thin bar
  separatedLayout = true, -- name centre; health at top, separate aura rows
  buffRow = 3,             -- tracked buff icons at the upper right
  debuffRow = 4,            -- small debuff icons along the bottom edge (0 to 4)
  debuffRowSize = 11,
  debuffRowTop = false,
  rangeFade = false,
  rangeDistance = 250,
  hotTimers = false,        -- seconds left of tracked heals over time on the third text line

  -- Statuses: [key] = { on, color = {r,g,b}, prio, ind = { indicator = true }, ... }
  statuses = {},            -- filled from G.STATUS_DEFAULTS by Statuses.lua

  -- Debuffs
  debuffMode = "all",       -- all | listed | unlisted
  debuffList = "",          -- names or ids, one per line (or ";"), first = most important
  debuffHide = "",          -- never shown
  debuffAlert = "",         -- important ones: also the "Important debuff" status (border)
  debuffMaxTime = 0,        -- 0 = any; else only debuffs with this many seconds or fewer
  debuffNoPermanent = false,

  -- Auras GridCliqueIt marked (English names; edit for other client languages)
  hotList = "Regenerate;Recover;Blossoming Life;Camellia Flower;Spring Flower;Healing Arrows;Spring of Blessings;Curing Shot",
  shieldList = "Wave Armor;Enhanced Wave Armor;Mother Earth's Protection;Shield of Light",
  salveList = "Healing Salve;Curing Seed",

  -- Your own watches: { on, name, kind = buff|debuff, missing, color, ind }
  watches = {},

  -- Tooltip
  tooltip = "ooc",          -- always | ooc | alt | never
  tooltipAnchor = "frame",  -- frame | cursor
  tooltipAuras = true,

  -- Clicks
  keepTarget = false,       -- after a kitty click, leave the member targeted
  clickOnUp = false,        -- run on button release instead of press
}

---------------------------------------------------------------------------
-- Saved data
--   CherrysGrid_DB.profiles[name]          one profile (G.DEFAULTS)
--   CherrysGrid_DB.chars[charName]         { solo = profile, party = profile, raid = profile }
--   CherrysGrid_DB.bindings[classKey][btn] { type = "kitty", kitty = "Heal" }, classKey "*" = any class
---------------------------------------------------------------------------

local function db()
  if type(CherrysGrid_DB) ~= "table" then
    CherrysGrid_DB = {}
  end
  local d = CherrysGrid_DB
  d.profiles = d.profiles or {}
  d.chars = d.chars or {}
  d.bindings = d.bindings or {}
  if type(d.profiles.Default) ~= "table" then
    d.profiles.Default = {}
  end
  return d
end
G.DB = db

G.charName = nil
G.groupType = "solo"   -- solo | party | raid
G.profileName = "Default"
G.P = G.Copy(G.DEFAULTS)

function G.CharKey()
  return G.charName or "?"
end

function G.CharProfiles()
  local d = db()
  local key = G.CharKey()
  if type(d.chars[key]) ~= "table" then
    d.chars[key] = { solo = "Default", party = "Default", raid = "Default" }
  end
  return d.chars[key]
end

function G.ProfileNames()
  local list = {}
  for name in pairs(db().profiles) do
    list[#list + 1] = name
  end
  table.sort(list)
  return list
end

-- Update untouched old layouts, but do not overwrite an edited profile's indicators.
local function prepareProfile(profile)
  if profile.separatedLayout ~= nil or next(profile) == nil then return end
  local old = {
    name = { text = true }, deficit = { text2 = true }, percent = { text2 = true },
    dead = { text2 = true, barColor = true, alpha = true },
    offline = { text2 = true, barColor = true, alpha = true },
    targetOfTarget = { cornerBL = true }, leader = { cornerTL = true },
    assistant = { cornerTL = true }, role = { cornerTR = true },
    raidIcon = { icon = true }, debuff = { icon = true },
    debuffAlert = { border = true, cornerBR = true }, hots = { cornerTR = true },
    hotTimers = { text3 = true }, shields = { cornerBR = true }, salves = { cornerBL = true },
  }
  local stock = (profile.width == nil or profile.width == 56) and (profile.height == nil or profile.height == 36)
  if (profile.debuffRow ~= nil and profile.debuffRow ~= 2)
    or (profile.debuffRowSize ~= nil and profile.debuffRowSize ~= 11)
    or profile.debuffRowTop == true or profile.hotTimers == false then stock = false end
  for key, cfg in pairs(profile.statuses or {}) do
    local def = G.STATUS_DEFAULTS[key]
    local oldOn = key == "hotTimers" and true or (def and def.on)
    if type(cfg) == "table" and def and cfg.on ~= nil and cfg.on ~= oldOn then stock = false end
  end
  local deficit = profile.statuses and profile.statuses.deficit
  if deficit and ((deficit.threshold ~= nil and deficit.threshold ~= 90)
    or (deficit.format ~= nil and deficit.format ~= "number")) then stock = false end
  for key, expected in pairs(old) do
    local cfg = profile.statuses and profile.statuses[key]
    if type(cfg) == "table" and type(cfg.ind) == "table" then
      for k, v in pairs(cfg.ind) do if v and not expected[k] then stock = false end end
      for k in pairs(expected) do if cfg.ind[k] ~= true then stock = false end end
    end
  end
  profile.separatedLayout = stock
  if stock then
    profile.width, profile.height, profile.debuffRow, profile.buffRow, profile.hotTimers = 100, 52, 4, 3, false
    for key in pairs(old) do
      local cfg = profile.statuses and profile.statuses[key]
      if type(cfg) == "table" then
        cfg.ind = G.Copy(G.STATUS_DEFAULTS[key].ind)
        if key == "deficit" and cfg.threshold == 90 then cfg.threshold = 100 end
        if key == "hotTimers" then cfg.on = false end
      end
    end
  else
    profile.buffRow = profile.buffRow or 0
    -- FillStatusDefaults merges defaults into existing maps; prevent new mappings being added
    -- to a user's customised indicator selections.
    for key, cfg in pairs(profile.statuses or {}) do
      local def = G.STATUS_DEFAULTS[key]
      if def and type(cfg.ind) == "table" then
        for ind in pairs(def.ind or {}) do if cfg.ind[ind] == nil then cfg.ind[ind] = false end end
      end
    end
  end
end

-- Makes G.P the profile chosen for this character and group type.
function G.LoadProfile()
  local d = db()
  local name = G.CharProfiles()[G.groupType] or "Default"
  if type(d.profiles[name]) ~= "table" then
    name = "Default"
  end
  G.profileName = name
  prepareProfile(d.profiles[name])
  G.P = G.Merge(d.profiles[name], G.DEFAULTS)
  if G.FillStatusDefaults then
    G.FillStatusDefaults(G.P)
  end
  -- 1.1.0: health percent shown as a number by default (profiles from 1.0.0 had it off)
  if (tonumber(G.P.revision) or 0) < 2 then
    local pc = G.P.statuses and G.P.statuses.percent
    if type(pc) == "table" then
      pc.on, pc.ind = true, { text2 = true }
    end
    G.P.revision = 2
  end
  return G.P
end

function G.NewProfile(name, copyFrom)
  name = string.gsub(tostring(name or ""), "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  if name == "" then
    return false
  end
  local d = db()
  if d.profiles[name] then
    return false
  end
  d.profiles[name] = G.Copy(d.profiles[copyFrom or G.profileName] or {})
  return true
end

function G.DeleteProfile(name)
  local d = db()
  if name == "Default" or not d.profiles[name] then
    return false
  end
  d.profiles[name] = nil
  for _, c in pairs(d.chars) do
    for k, v in pairs(c) do
      if v == name then
        c[k] = "Default"
      end
    end
  end
  return true
end

function G.ResetProfile()
  db().profiles[G.profileName] = {}
  G.LoadProfile()
end

function G.UseProfile(groupType, name)
  G.CharProfiles()[groupType] = name
  G.LoadProfile()
  G.Refresh(true)
end

---------------------------------------------------------------------------
-- Class key for click bindings: "AUGUR/DRUID" (main/sub); "*" holds the any-class bindings.
---------------------------------------------------------------------------

function G.ClassKey()
  local main, sub = nil, nil
  if UnitClassToken then
    main, sub = UnitClassToken("player")
  end
  if not main or main == "" then
    return "*"
  end
  return tostring(main) .. "/" .. tostring(sub or "")
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

G.ready = false
G.varsLoaded = false
G.elapsed = 0
G.slowElapsed = 0
G.rosterElapsed = 0
G.animElapsed = 0
G.dirty = {}       -- unit -> true: redraw on the next update
G.spareDirty = {}  -- the emptied list the next update's marks go into
G.allDirty = true
-- Damage and heal flashes fade 20 times a second; the frames redraw ten times a second.
G.ANIMATE_EVERY = 0.05

G.EVENTS = {
  "VARIABLES_LOADED", "LOADING_END", "PARTY_MEMBER_CHANGED", "PARTY_LEADER_CHANGED",
  "UNIT_HEALTH", "UNIT_MANA", "UNIT_SKILL", "UNIT_BUFF_CHANGED", "UNIT_CLASS_CHANGED",
  "UNIT_TARGET_CHANGED", "RAID_TARGET_CHANGED", "UNIT_PET_CHANGED", "EXCHANGECLASS_SUCCESS",
}

function G.OnLoad(frame)
  for _, e in ipairs(G.EVENTS) do
    G.Try(frame, "RegisterEvent", e)
  end
end

-- Marks a unit (and every frame showing the same character) for redrawing.
function G.MarkDirty(unit)
  if not unit or unit == "" then
    G.allDirty = true
    return
  end
  G.dirty[unit] = true
  if G.Roster and G.Roster.byUnit and not G.Roster.byUnit[unit] and UnitName then
    local name = UnitName(unit)
    if name and name ~= "" then
      local u = G.Roster.byName[name]
      if u then
        G.dirty[u] = true
      end
    end
  end
end

function G.OnEvent(event, arg1)
  if event == "VARIABLES_LOADED" then
    G.varsLoaded = true
    return
  end
  if not G.ready then
    return
  end
  if event == "UNIT_HEALTH" then
    if G.Frames then
      G.Frames.NoteHealth(arg1)
    end
    G.MarkDirty(arg1)
  elseif event == "UNIT_MANA" or event == "UNIT_SKILL" or event == "UNIT_CLASS_CHANGED" then
    G.MarkDirty(arg1)
  elseif event == "UNIT_BUFF_CHANGED" then
    if G.Auras then
      G.Auras.Forget(arg1)
    end
    G.MarkDirty(arg1)
  elseif event == "UNIT_TARGET_CHANGED" then
    G.allDirty = true
  elseif event == "RAID_TARGET_CHANGED" or event == "PARTY_LEADER_CHANGED" then
    G.allDirty = true
  elseif event == "PARTY_MEMBER_CHANGED" or event == "UNIT_PET_CHANGED" then
    G.rosterElapsed = 99
  elseif event == "EXCHANGECLASS_SUCCESS" then
    G.allDirty = true
    if G.Options and G.Options.Refresh then
      G.Options.Refresh()
    end
  elseif event == "LOADING_END" then
    G.rosterElapsed = 99
    if G.Mouse then
      G.Mouse.Apply()
    end
  end
end

-- Starts once the saved variables are in and the player's name is known (RoM fills names late).
function G.TryStart()
  if G.ready then
    return
  end
  local name = UnitName and UnitName("player")
  if not name or name == "" then
    return
  end
  if not G.varsLoaded and CherrysGrid_DB == nil then
    -- VARIABLES_LOADED can come before this file runs after Reload UI; give it a moment
    G.waitVars = (G.waitVars or 0) + 1
    if G.waitVars < 20 then
      return
    end
  end
  G.charName = name
  G.ready = true
  G.LoadProfile()
  G.Refresh(true)
  if G.Mouse then
    G.Mouse.Apply()
  end
end

function G.OnUpdate(elapsed)
  elapsed = tonumber(elapsed) or 0
  if not G.IsOn() then
    return
  end
  if not G.ready then
    G.TryStart()
    return
  end
  G.elapsed = G.elapsed + elapsed
  G.slowElapsed = G.slowElapsed + elapsed
  G.rosterElapsed = G.rosterElapsed + elapsed
  G.animElapsed = G.animElapsed + elapsed
  if G.Frames and G.animElapsed >= G.ANIMATE_EVERY then
    G.Frames.Animate(G.animElapsed)
    G.animElapsed = 0
  end
  if G.Clicks then
    G.Clicks.Tick(elapsed)
  end
  if G.Options and G.Options.deferred then
    local fn = G.Options.deferred
    G.Options.deferred = nil
    fn()
  end
  if G.elapsed < 0.1 then
    return
  end
  G.elapsed = 0
  if G.rosterElapsed > 1 then
    G.rosterElapsed = 0
    if G.UpdateRoster() then
      G.Refresh(true, true)
      return
    end
    G.Layout.KeepPartyHidden()
  end
  if G.slowElapsed > 0.5 then
    -- timers, range and target highlights change without events
    G.slowElapsed = 0
    G.allDirty = true
  end
  if G.allDirty then
    G.allDirty = false
    for unit in pairs(G.dirty) do G.dirty[unit] = nil end
    G.Frames.UpdateAll()
  elseif next(G.dirty) then
    -- two lists take turns, so marking units for the next update makes no new table
    local d = G.dirty
    G.dirty, G.spareDirty = G.spareDirty, d
    for unit in pairs(d) do
      G.Frames.UpdateUnit(unit)
    end
    for unit in pairs(d) do d[unit] = nil end
  end
end

-- Select the group profile before the one roster scan, so the scan uses its
-- filters and ordering even when joining/leaving a raid.
function G.UpdateRoster()
  local wanted = G.Roster.GroupType()
  local profileChanged = wanted ~= G.groupType
  if profileChanged then
    G.groupType = wanted
    G.LoadProfile()
  end
  return G.Roster.Update(wanted) or profileChanged
end

-- Redraws everything. rosterUpdated reuses the scan performed by OnUpdate.
function G.Refresh(layout, rosterUpdated)
  if not G.ready then return end
  if not rosterUpdated then layout = G.UpdateRoster() or layout end
  if layout then
    G.Layout.Apply(true)
  end
  G.Frames.UpdateAll()
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

function G.Help()
  chat("commands:")
  chat(" /grid  opens the options window")
  chat(" /grid lock | unlock  stops or allows moving the frames")
  chat(" /grid test  shows 36 test members (again to stop)")
  chat(" /grid reset  moves the frames back to the middle of the screen")
  chat(" /grid probe  checks what this game client offers")
end

function G.Command(msg)
  msg = string.lower(tostring(msg or ""))
  msg = string.gsub(msg, "^%s+", "")
  if msg == "probe" then
    G.Probe.Run()
  elseif msg == "help" then
    G.Help()
  elseif not G.IsOn() then
    chat("turned off in the Cherry's Kit window (/ck).")
  elseif not G.ready then
    chat("still loading, try again in a moment.")
  elseif msg == "lock" then
    G.P.locked = true
    G.Layout.Apply()
    chat("frames locked: the tab is hidden, /grid opens the options.")
  elseif msg == "unlock" then
    G.P.locked = false
    G.Layout.Apply()
    chat("frames unlocked: drag the tab to move them.")
  elseif msg == "test" then
    G.Roster.SetTest(not G.Roster.test)
    G.Refresh(true)
    chat(G.Roster.test and "test members on (/grid test again to stop)." or "test members off.")
  elseif msg == "reset" then
    G.P.x, G.P.y = 300, 300
    G.Layout.Apply()
  else
    G.Options.Toggle()
  end
end

SlashCmdList = SlashCmdList or {}
SLASH_CHERRYSGRID1 = "/grid"
SLASH_CHERRYSGRID2 = "/cgrid"
SlashCmdList["CHERRYSGRID"] = function(editBox, msg)
  G.Command((type(editBox) == "string" and editBox) or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "CherrysGrid",
    title = "Cherry's Grid",
    version = G.version,
    installed = function()
      return true
    end,
    open = function()
      G.Options.Toggle()
      return true
    end,
  })
end
