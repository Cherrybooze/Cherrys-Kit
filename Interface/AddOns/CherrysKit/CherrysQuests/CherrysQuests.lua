-- Cherry's Quests: a prettier quest tracker for Runes of Magic with font, size and look options.
-- Ctrl+click a quest to cycle through the named NPCs in its summary and put the one you pick in
-- the game's NPC tracking list (the same list the world map's NPC search in the Backspace menu
-- fills). The pick is remembered per character and quest.
-- Written for Cherry's Kit.
--
-- Files: CherrysQuests (settings, events, reading quests, commands), Npcs (finding and tracking
-- NPCs), Tracker (drawing and clicks), Options (/cq window), Probe (/cq probe).

CherrysQuests = {}
local Q = CherrysQuests

Q.version = "1.0.0"
Q.MAX_ROWS = 30 -- quest rows declared in CherrysQuests.xml

if SaveVariables then
  SaveVariables("CherrysQuests_DB")
end

-- Wrappers this addon put on game functions. Reload UI re-runs this file in the same Lua state,
-- so the set lives in a global and a wrapper is never wrapped again.
CherrysQuests_Hooks = CherrysQuests_Hooks or { ours = {}, orig = {} }

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7fa8Cherry's Quests:|r " .. tostring(text))
  end
end
Q.Print = chat

-- The hub's on/off switch applies after Reload UI, so it is read once when this file loads.
Q.off = (CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("CherrysQuests")) and true or false

function Q.IsOn()
  return not Q.off
end

-- Calls obj:method(...) only when the client has that method. Returns true when it ran.
function Q.Try(obj, method, ...)
  if obj and type(obj[method]) == "function" then
    return (pcall(obj[method], obj, ...))
  end
  return false
end

-- Calls a global game function if it exists; returns ok followed by its results.
function Q.Call(name, ...)
  local fn = _G[name]
  if type(fn) ~= "function" then
    return false
  end
  return pcall(fn, ...)
end

function Q.Copy(t)
  if type(t) ~= "table" then
    return t
  end
  local c = {}
  for k, v in pairs(t) do
    c[k] = Q.Copy(v)
  end
  return c
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

Q.DEFAULTS = {
  shown = true,
  replace = true,       -- hide the game's tracker and pbInfo's while this one is shown
  locked = false,
  scale = 1,
  width = 240,
  font = "game",        -- "game" or a font file of rom weakauras (Media/Fonts)
  outline = "NORMAL",   -- NORMAL | OUTLINE | THICK
  titleSize = 13,
  textSize = 11,
  bgAlpha = 0.5,
  sort = "level",       -- track | level | leveldown | name
  bars = true,          -- thin progress bar under each quest
  fade = true,          -- progress numbers fade from red to green
  npcLine = true,       -- show the NPC picked with Ctrl+click under the quest
  hideDone = false,     -- hide finished objectives
  dailies = true,       -- daily quests get their own colour
  tooltip = true,
  clickBook = false,    -- a plain click opens the quest book (otherwise it folds the quest)
  turnIn = true,        -- the turn-in NPC joins the Ctrl+click list
  slot = 0,             -- 0: the game's quick track; 1 or more: that tracking list slot
  x = nil,
  y = nil,
  folded = {},          -- [quest name] = true
  allFolded = false,
}

Q.FONTS = {
  { key = "game", label = "Game font" },
  { key = "FiraSans-Medium.ttf", label = "Fira Sans" },
  { key = "FiraSans-Heavy.ttf", label = "Fira Sans Heavy" },
  { key = "FiraSansCondensed-Medium.ttf", label = "Fira Sans Condensed" },
  { key = "FiraSansCondensed-Heavy.ttf", label = "Fira Condensed Heavy" },
  { key = "PTSansNarrow-Regular.ttf", label = "PT Sans Narrow" },
  { key = "PTSansNarrow-Bold.ttf", label = "PT Sans Narrow Bold" },
  { key = "FiraMono-Medium.ttf", label = "Fira Mono" },
}

-- The fonts ship with rom weakauras, so they are offered only when it is installed.
function Q.FontPath(key)
  if not key or key == "game" or type(RWA) ~= "table" then
    return nil
  end
  local base = (CherrysKit_Paths and CherrysKit_Paths.RomWeakAuras) or "Interface/AddOns/RomWeakAuras/"
  return base .. "Media/Fonts/" .. key
end

function Q.FontChoices()
  if type(RWA) ~= "table" then
    return { Q.FONTS[1] }
  end
  return Q.FONTS
end

-- Fills in missing settings once per saved table; later calls just return it.
function Q.DB()
  if Q.checkedDB ~= nil and Q.checkedDB == CherrysQuests_DB then
    return Q.checkedDB
  end
  if type(CherrysQuests_DB) ~= "table" then
    CherrysQuests_DB = {}
  end
  local db = CherrysQuests_DB
  if type(db.settings) ~= "table" then
    db.settings = {}
  end
  for k, v in pairs(Q.DEFAULTS) do
    if db.settings[k] == nil then
      db.settings[k] = Q.Copy(v)
    end
  end
  if type(db.chars) ~= "table" then
    db.chars = {}
  end
  Q.checkedDB = db
  return db
end

function Q.S()
  return Q.DB().settings
end

-- What this character picked with Ctrl+click: [quest name] = { id = NPC id, name = NPC name }.
function Q.Picks()
  local db = Q.DB()
  local who = Q.charName or (UnitName and UnitName("player")) or "?"
  if type(db.chars[who]) ~= "table" then
    db.chars[who] = {}
  end
  local c = db.chars[who]
  if type(c.picks) ~= "table" then
    c.picks = {}
  end
  return c.picks
end

---------------------------------------------------------------------------
-- Reading quests
---------------------------------------------------------------------------

-- "(Complete)" as the clients write it after a finished objective or quest name.
Q.DONE_WORDS = { "Complete", "Fertig", "Termin\195\169e", "\208\151\208\176\208\178\208\181\209\128\209\136\208\184\209\130\209\140",
  "\229\174\140\228\186\134", "\233\129\148\230\136\144", "\236\153\132\235\163\140", "\229\174\140\230\136\144" }

local function stripDone(text)
  local done = false
  for _, word in ipairs(Q.DONE_WORDS) do
    local s, e = string.find(text, "%s*%(" .. word .. "%)", 1)
    if s then
      done = true
      text = string.sub(text, 1, s - 1) .. string.sub(text, e + 1)
    end
  end
  return text, done
end
Q.StripDone = stripDone

function Q.ParseObjective(line)
  local text, done = stripDone(line)
  local obj = { text = text, done = done }
  local s, _, have, need = string.find(text, "(%d+)%s*/%s*(%d+)%s*$")
  if s then
    obj.have, obj.need = tonumber(have), tonumber(need)
    local label = string.sub(text, 1, s - 1)
    label = string.gsub(label, "[%s:]+$", "")
    obj.label = label
    if obj.need and obj.need > 0 and obj.have >= obj.need then
      obj.done = true
    end
  else
    obj.label = text
  end
  return obj
end

-- One tracked quest. id is the quest book index GetQuestTrack returns.
function Q.ReadQuest(id, order)
  local ok, name = Q.Call("GetQuestRequest", id, -2)
  if not ok or type(name) ~= "string" or name == "" then
    return nil
  end
  local _, level = Q.Call("GetQuestRequest", id, -3)
  local quest = { id = id, order = order, level = tonumber(level) or 0, objectives = {} }
  quest.name, quest.done = stripDone(name)
  local i = 1
  while i <= 20 do
    local okLine, line = Q.Call("GetQuestRequest", id, i)
    if not okLine or type(line) ~= "string" then
      break
    end
    quest.objectives[#quest.objectives + 1] = Q.ParseObjective(line)
    i = i + 1
  end
  local have, need, finished = 0, 0, 0
  for _, obj in ipairs(quest.objectives) do
    if obj.done then
      finished = finished + 1
    end
    if obj.need and obj.need > 0 then
      have = have + math.min(obj.have, obj.need)
      need = need + obj.need
    elseif obj.done then
      have, need = have + 1, need + 1
    else
      need = need + 1
    end
  end
  if #quest.objectives > 0 and finished == #quest.objectives then
    quest.done = true
  end
  quest.progress = (need > 0) and (have / need) or (quest.done and 1 or 0)
  local okInfo, _, _, _, _, _, daily = Q.Call("GetQuestInfo", id)
  quest.daily = okInfo and (daily == true or daily == 1) or false
  return quest
end

local function byName(a, b)
  return a.name < b.name
end

function Q.ReadTracked()
  local ok, count = Q.Call("GetQuestTrack", -1)
  count = ok and tonumber(count) or 0
  local list = {}
  for i = 1, math.min(count, 40) do
    local okId, id = Q.Call("GetQuestTrack", i)
    if okId and id then
      local quest = Q.ReadQuest(id, i)
      if quest then
        list[#list + 1] = quest
      end
    end
  end
  local sort = Q.S().sort
  if sort == "level" or sort == "leveldown" then
    local up = sort == "level"
    table.sort(list, function(a, b)
      if a.level == b.level then
        return byName(a, b)
      end
      if up then
        return a.level < b.level
      end
      return a.level > b.level
    end)
  elseif sort == "name" then
    table.sort(list, byName)
  end
  return list
end

-- A short text that changes whenever anything shown changes, so the tracker redraws only then.
function Q.Signature(list)
  local parts = {}
  for _, q in ipairs(list) do
    parts[#parts + 1] = q.name .. "#" .. q.level .. (q.done and "+" or "")
    for _, obj in ipairs(q.objectives) do
      parts[#parts + 1] = obj.text .. (obj.done and "+" or "")
    end
  end
  return table.concat(parts, "\n")
end

function Q.PlayerLevel()
  local ok, lvl = Q.Call("GetCurrentVocLV")
  lvl = ok and tonumber(lvl)
  if not lvl and UnitLevel then
    lvl = tonumber((UnitLevel("player")))
  end
  return lvl or 0
end

function Q.DailyText()
  local ok, done, perDay = Q.Call("Daily_count")
  done, perDay = tonumber(done), tonumber(perDay)
  if ok and done and perDay and perDay > 0 then
    return (perDay - done) .. "/" .. perDay
  end
  return nil
end

---------------------------------------------------------------------------
-- The other trackers
---------------------------------------------------------------------------

function Q.Replacing()
  local S = Q.S()
  return Q.IsOn() and Q.ready and S.shown and S.replace and not Q.buttonHidden
end

function Q.HideOthers()
  if not Q.Replacing() then
    return
  end
  if QuestTrackerFrame and QuestTrackerFrame.IsVisible and QuestTrackerFrame:IsVisible() then
    QuestTrackerFrame:Hide()
  end
  if pbInfoQuestTracker and pbInfoQuestTracker.IsVisible and pbInfoQuestTracker:IsVisible() then
    pbInfoQuestTracker:Hide()
  end
end

-- Wraps a global function once per Lua state. make(orig) returns the wrapper.
local function hookGlobal(key, make)
  local H = CherrysQuests_Hooks
  local current = _G[key]
  if type(current) ~= "function" or H.ours[current] then
    return
  end
  local wrapper = make(current)
  H.ours[wrapper] = true
  _G[key] = wrapper
end
Q.HookGlobal = hookGlobal

-- The wrappers look up CherrysQuests when they run: after Reload UI it is a new table.
function Q.QuestButton(orig, ...)
  if Q.IsOn() and Q.ready and Q.S().shown and Q.S().replace then
    Q.buttonHidden = not Q.buttonHidden
    Q.Tracker.Refresh(true)
    return
  end
  return orig(...)
end

function Q.InstallHooks()
  -- The quest button by the minimap shows or hides this tracker while it replaces the others.
  hookGlobal("OnClick_QuestTrackButton", function(orig)
    return function(...)
      return CherrysQuests.QuestButton(orig, ...)
    end
  end)
  -- pbInfo shows its own tracker on quest events; keep it hidden while this one replaces it.
  local qt = type(pbInfo) == "table" and pbInfo.QuestTracker
  if type(qt) == "table" and type(qt.UpdateTracker) == "function" and not CherrysQuests_Hooks.ours[qt.UpdateTracker] then
    local orig = qt.UpdateTracker
    local wrapper = function(...)
      if CherrysQuests.Replacing() then
        if pbInfoQuestTracker then
          pbInfoQuestTracker:Hide()
        end
        return false
      end
      return orig(...)
    end
    CherrysQuests_Hooks.ours[wrapper] = true
    qt.UpdateTracker = wrapper
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

Q.EVENTS = { "VARIABLES_LOADED", "LOADING_END", "RESET_QUESTTRACK", "RESET_QUESTBOOK", "ADDNEW_QUESTBOOK",
  "QUEST_COMPLETE", "PLAYER_LEVEL_UP" }

Q.elapsed, Q.pollElapsed = 0, 0

function Q.OnLoad(frame)
  for _, ev in ipairs(Q.EVENTS) do
    Q.Try(frame, "RegisterEvent", ev)
  end
end

function Q.OnEvent(event)
  if event == "VARIABLES_LOADED" then
    Q.varsLoaded = true
    return
  end
  if not Q.IsOn() or not Q.ready then
    return
  end
  if event == "RESET_QUESTBOOK" or event == "ADDNEW_QUESTBOOK" or event == "QUEST_COMPLETE" then
    Q.Npcs.Forget()
  end
  Q.HideOthers()
  Q.dirty = true
end

function Q.TryStart()
  local name = UnitName and UnitName("player")
  if not name or name == "" then
    return
  end
  if not Q.varsLoaded and CherrysQuests_DB == nil then
    -- VARIABLES_LOADED can come before this file runs after Reload UI; give it a moment
    Q.waitVars = (Q.waitVars or 0) + 1
    if Q.waitVars < 20 then
      return
    end
  end
  Q.charName = name
  Q.ready = true
  Q.InstallHooks()
  Q.Tracker.Setup()
  Q.dirty = true
end

-- Runs every frame but only adds a number until a timer is due: no strings or tables are made
-- here. Quests are read on quest events (a short delay gathers a burst into one redraw) and,
-- as a fallback for objective counts the client changes without an event, every 10 seconds.
Q.CHECK_EVERY = 0.5   -- keep the other trackers hidden
Q.EVENT_DELAY = 0.3   -- redraw this long after the last quest event
Q.POLL_EVERY = 10     -- fallback read without an event

function Q.OnUpdate(elapsed)
  if Q.off then
    return
  end
  if not Q.ready then
    Q.TryStart()
    return
  end
  elapsed = tonumber(elapsed) or 0
  Q.elapsed = Q.elapsed + elapsed
  if Q.elapsed < Q.CHECK_EVERY and not (Q.dirty and Q.elapsed >= Q.EVENT_DELAY) then
    return
  end
  Q.pollElapsed = Q.pollElapsed + Q.elapsed
  Q.elapsed = 0
  Q.HideOthers()
  if Q.dirty or Q.pollElapsed >= Q.POLL_EVERY then
    local force = Q.dirty
    Q.dirty = false
    Q.pollElapsed = 0
    Q.Tracker.Refresh(force)
  end
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

function Q.Help()
  chat("commands:")
  chat(" /cq  opens the options window")
  chat(" /cq show | hide  shows or hides the tracker")
  chat(" /cq lock | unlock  stops or allows dragging it by its title")
  chat(" /cq reset  puts the tracker back in its first place")
  chat(" /cq npcs  lists the NPCs Ctrl+click cycles through for each tracked quest")
  chat(" /cq track <name>  finds an NPC by name and tracks it (like the world map search)")
  chat(" /cq text [n]  prints the raw summary text of tracked quest n (for bug reports)")
  chat(" /cq forget  forgets every NPC you picked with Ctrl+click")
  chat(" /cq probe  checks what this game client offers")
end

function Q.Command(msg)
  msg = tostring(msg or "")
  msg = string.gsub(msg, "^%s+", "")
  msg = string.gsub(msg, "%s+$", "")
  local s, e = string.find(msg, "%s+")
  local word, rest = msg, ""
  if s then
    word, rest = string.sub(msg, 1, s - 1), string.sub(msg, e + 1)
  end
  word = string.lower(word)
  if word == "probe" then
    Q.Probe.Run()
  elseif word == "help" then
    Q.Help()
  elseif not Q.IsOn() then
    chat("turned off in the Cherry's Kit window (/ck).")
  elseif not Q.ready then
    chat("still loading, try again in a moment.")
  elseif word == "show" or word == "hide" then
    Q.S().shown = word == "show"
    Q.buttonHidden = false
    Q.Tracker.Refresh(true)
    if word == "hide" and Q.S().replace then
      chat("hidden. The game's tracker comes back after Reload UI if you also untick \"Replace the game's tracker\".")
    end
  elseif word == "lock" or word == "unlock" then
    Q.S().locked = word == "lock"
    chat(Q.S().locked and "locked." or "unlocked: drag the title to move the tracker.")
  elseif word == "reset" then
    Q.Options.ResetPosition()
  elseif word == "npcs" then
    Q.Npcs.ListAll()
  elseif word == "track" then
    Q.Npcs.TrackByName(rest)
  elseif word == "text" then
    Q.Npcs.DumpText(tonumber(rest) or 1)
  elseif word == "forget" then
    Q.Options.Forget()
  else
    Q.Options.Toggle()
  end
end

SlashCmdList = SlashCmdList or {}
SLASH_CHERRYSQUESTS1 = "/cq"
SLASH_CHERRYSQUESTS2 = "/cquests"
SlashCmdList["CHERRYSQUESTS"] = function(editBox, msg)
  Q.Command((type(editBox) == "string" and editBox) or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "CherrysQuests",
    title = "Cherry's Quests",
    version = Q.version,
    installed = function()
      return true
    end,
    open = function()
      Q.Options.Toggle()
      return true
    end,
  })
end
