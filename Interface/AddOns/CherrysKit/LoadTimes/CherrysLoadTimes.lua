-- Cherry's Addon LoadTimes: how long each addon takes while the loading screen is up.
--
-- It lives in Cherry's Kit (CherrysKit/LoadTimes/) and is the kit's first file. build_kit.py adds a
-- Mark("<Folder>") before each kit addon, so the kit is split per addon exactly. Addon folders that
-- load after the kit (folder names after "CherrysKit") are timed together, and until VARIABLES_LOADED
-- it watches new global variables: the longest waits between two new globals are the slow spots, and
-- the global set after a wait usually carries the addon's name. (A client that names its files would
-- also give a per-folder list; the RoM client names every file "?", so it does not.)
-- Type /ckload after the loading screen; "/ckload probe" checks what this client allows.

-- RoM keeps Lua globals through Reload UI, so after a reload every addon's globals already exist:
-- the watcher then sees only the few new ones.
local reloaded = CherrysLoadTimes ~= nil
CherrysLoadTimes = { version = "1.2.1", standalone = true, reloaded = reloaded }
CherrysKit_Load = CherrysLoadTimes
local L = CherrysLoadTimes
L.marks = {}     -- kit addons: { name, t, kb }, in load order
L.events = {}    -- event -> { first = t, last = t } (login only)
L.folders = {}   -- every AddOns folder seen: { name, t, kb, globals }, in load order
L.unknown = 0    -- new globals whose file could not be told

local clock
if type(os) == "table" and type(os.clock) == "function" then
  clock, L.clock = os.clock, "os.clock"
elseif type(GetTickCount) == "function" then
  clock, L.clock = function() return GetTickCount() / 1000 end, "GetTickCount"
elseif type(GetTime) == "function" then
  clock, L.clock = GetTime, "GetTime"
else
  L.clock = "none"
end

function L.Now()
  if clock then
    local ok, t = pcall(clock)
    if ok and type(t) == "number" then
      return t
    end
  end
  return 0
end

local function memory()
  if type(collectgarbage) == "function" then
    local ok, kb = pcall(collectgarbage, "count")
    if ok and type(kb) == "number" then
      return kb
    end
  end
  return nil
end

L.start = L.Now()
L.startKb = memory()

---------------------------------------------------------------------------
-- Which file is running: debug.getinfo when the client has it, otherwise the position an error
-- message gets ("Interface/AddOns/Folder/file.lua:12:").
---------------------------------------------------------------------------
local getinfo = type(debug) == "table" and type(debug.getinfo) == "function" and debug.getinfo or nil
L.method = getinfo and "debug.getinfo" or "error position"

-- Source of the code that assigned the global: 1 is pcall, 2 this function, 3 __newindex, 4 the assigner.
local function sourceOf()
  if getinfo then
    local ok, info = pcall(getinfo, 4, "S")
    if ok and type(info) == "table" and info.source then
      return info.source
    end
  end
  local _, msg = pcall(error, "", 4)
  return msg
end

function L.FolderOf(source)
  if type(source) ~= "string" then
    return nil
  end
  local folder = string.match(source, "[Aa][Dd][Dd][Oo][Nn][Ss][/\\]([^/\\:\"]+)[/\\]")
  return folder
end

local current -- folder entry being loaded
local function seen(folder)
  if current and string.lower(current.name) == string.lower(folder) then
    current.globals = current.globals + 1
    return
  end
  current = { name = folder, t = L.Now(), kb = memory(), globals = 1 }
  table.insert(L.folders, current)
end

---------------------------------------------------------------------------
-- Watch new globals until VARIABLES_LOADED
---------------------------------------------------------------------------
local watcher
local previous = getmetatable(_G)
local previousNewindex = type(previous) == "table" and previous.__newindex or nil

function L.Watch()
  if watcher or (previous ~= nil and type(previous) ~= "table") then
    return
  end
  watcher = {}
  if previous then
    for k, v in pairs(previous) do
      watcher[k] = v
    end
  end
  watcher.__newindex = function(t, k, v)
    -- RoM names every file "?", so after 200 misses stop asking (it costs a pcall per global).
    local folder
    if #L.folders > 0 or L.unknown < 200 then
      local source = sourceOf()
      L.sampleSource = L.sampleSource or source
      folder = L.FolderOf(source)
    end
    if folder then
      seen(folder)
    else
      L.unknown = L.unknown + 1
    end
    L.NoteGlobal(k)
    if type(previousNewindex) == "function" then
      previousNewindex(t, k, v)
    elseif type(previousNewindex) == "table" then
      previousNewindex[k] = v
    else
      rawset(t, k, v)
    end
  end
  local ok = pcall(setmetatable, _G, watcher)
  L.watching, L.watched = ok, ok
  if not ok then
    watcher = nil
  end
end

function L.Unwatch()
  if watcher and getmetatable(_G) == watcher then
    pcall(setmetatable, _G, previous)
  end
  L.watching = false
end

-- Without file names, the slow spots still show: a long wait between two new globals is a big
-- file being read or many frames being made. The global set after the wait names the culprit
-- (addons prefix their globals and frames with their own name).
L.GAP = 0.02 -- seconds; shorter waits are not kept
L.gaps = {}  -- { t0, t1, before, after }
L.globals = 0
local lastT, lastName = L.start, "(start)"
function L.NoteGlobal(name)
  local now = L.Now()
  L.globals = L.globals + 1
  if now - lastT >= L.GAP then
    table.insert(L.gaps, { t0 = lastT, t1 = now, before = lastName, after = tostring(name) })
  end
  lastT, lastName = now, tostring(name)
end

-- The kit's marks (one before each kit addon).
function L.Mark(name)
  table.insert(L.marks, { name = name, t = L.Now(), kb = memory() })
end

-- which = "first" (this addon's frame, before every addon) or "last" (the kit's frame after its
-- addons). Only the first time each event fires counts: that is the login.
function L.Event(which, event)
  local e = L.events[event] or {}
  L.events[event] = e
  if e[which] == nil then
    e[which] = L.Now()
    if event == "VARIABLES_LOADED" and which == "first" then
      L.filesDone = e[which]
      L.filesDoneKb = memory()
      L.Unwatch()
      L.RegisterWithHub()
    end
  end
end

-- First frame drawn after the login LOADING_END: the loading screen is gone.
function L.Update(frame)
  local e = L.events.LOADING_END
  if e and e.first and not L.ready then
    L.ready = L.Now()
    -- Both probe frames stop here; the one that did not run first would keep its OnUpdate.
    for _, name in ipairs({ "CherrysLoadTimes_Frame", "CherrysKit_LoadLast" }) do
      local probe = _G[name]
      if probe and probe.Hide then
        probe:Hide()
      end
    end
  end
end

---------------------------------------------------------------------------
-- Report
---------------------------------------------------------------------------
local function ms(seconds)
  return string.format("%d ms", math.floor(seconds * 1000 + 0.5))
end

local function kb(a, b)
  if a and b then
    return string.format("   %+d KB", math.floor(b - a + 0.5))
  end
  return ""
end

local function row(name, seconds, a, b)
  return string.format("  %-22s %s", name, ms(seconds)) .. kb(a, b)
end

-- The kit's marks end with "end" (after its last addon); a mark's time runs to the next one.
local function kitLines(lines)
  local marks = L.marks
  if #marks < 2 then
    return
  end
  table.insert(lines, "Cherry's Kit, per addon:")
  for i = 1, #marks - 1 do
    local a, b = marks[i], marks[i + 1]
    if a.name ~= "(probe)" then
      table.insert(lines, row(a.name, b.t - a.t, a.kb, b.kb))
    end
  end
  table.insert(lines, "  all kit files          " .. ms(marks[#marks].t - marks[1].t))
end

function L.Lines()
  local lines = { "Addon load times (clock: " .. L.clock .. ")" }
  if L.reloaded then
    table.insert(lines, "(after Reload UI: slow spots after the kit only show after a fresh login)")
  end
  if L.clock == "none" then
    table.insert(lines, "no clock in this client, nothing measured")
    return lines
  end
  local done = L.filesDone or L.Now()
  if #L.folders > 0 then
    table.insert(lines, "Every addon folder, in load order (approximate):")
    for i, f in ipairs(L.folders) do
      local nextF = L.folders[i + 1]
      local stop = nextF and nextF.t or done
      local stopKb = nextF and nextF.kb or L.filesDoneKb
      table.insert(lines, row(f.name, stop - f.t, f.kb, stopKb))
    end
  end
  kitLines(lines)
  local marks = L.marks
  local kitStart, kitEnd = marks[1] and marks[1].t, marks[#marks] and marks[#marks].t
  if L.filesDone then
    local all = L.filesDone - L.start
    table.insert(lines, "  all addon files        " .. ms(all) .. kb(L.startKb, L.filesDoneKb))
    if kitStart and kitEnd and #marks > 1 then
      table.insert(lines, "  addons after the kit   " .. ms(math.max(0, all - (kitEnd - kitStart))))
    end
  end
  if #L.folders == 0 and #L.gaps > 0 then
    -- slowest waits after the kit, biggest first
    local outside = {}
    for _, g in ipairs(L.gaps) do
      if not (kitStart and kitEnd and g.t1 > kitStart and g.t0 < kitEnd) then
        table.insert(outside, g)
      end
    end
    table.sort(outside, function(a, b) return (a.t1 - a.t0) > (b.t1 - b.t0) end)
    if #outside > 0 then
      table.insert(lines, "Slowest spots after the kit (the name after the wait is usually the addon):")
      for i = 1, math.min(10, #outside) do
        local g = outside[i]
        table.insert(lines, string.format("  %s before %s   (after %s)", ms(g.t1 - g.t0), g.after, g.before))
      end
    end
  end
  for _, event in ipairs({ "VARIABLES_LOADED", "LOADING_END" }) do
    local e = L.events[event]
    if e and e.first and e.last then
      table.insert(lines, "  " .. event .. " handlers  " .. ms(math.max(0, e.last - e.first)))
    end
  end
  if L.ready then
    table.insert(lines, "  first addon file to end of loading screen  " .. ms(L.ready - L.start)
      .. " (includes the game's own loading)")
  end
  return lines
end

local function chat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  end
end

function L.Print()
  for _, line in ipairs(L.Lines()) do
    chat(line)
  end
end

-- /ckload probe: what this client allows, for Cherry to check.
function L.ProbeLines()
  local first = L.folders[1]
  return {
    "LoadTimes probe " .. L.version,
    "clock: " .. L.clock .. ", memory: " .. tostring(L.startKb ~= nil),
    "file detection: " .. L.method .. ", sample: " .. tostring(L.sampleSource),
    "watching globals worked: " .. tostring(L.watched == true and #L.folders > 0),
    "folders seen: " .. #L.folders .. ", globals with unknown file: " .. L.unknown
      .. ", new globals: " .. L.globals .. ", waits over 20 ms: " .. #L.gaps,
    "first folder seen: " .. (first and first.name or "none") .. ", kit marks: " .. #L.marks,
    "after Reload UI: " .. tostring(L.reloaded),
  }
end

function L.Probe()
  for _, line in ipairs(L.ProbeLines()) do
    chat("probe " .. line)
  end
end

function L.Slash(a, b)
  -- RoM passes (editBox, msg); WoW passes (msg, editBox).
  local msg = type(a) == "string" and a or (type(b) == "string" and b or "")
  if CherrysKit and CherrysKit.IsEnabled and not CherrysKit.IsEnabled("CherrysLoadTimes") then
    chat("Cherry's Addon LoadTimes is turned off in the Cherry's Kit window (/ck).")
    return
  end
  if string.lower(string.match(msg, "^%s*(%S*)") or "") == "probe" then
    L.Probe()
  else
    L.Print()
  end
end

SLASH_CherrysKitLoad1 = "/ckload"
SLASH_CherrysKitLoad2 = "/loadtimes"
SlashCmdList = SlashCmdList or {}
SlashCmdList["CherrysKitLoad"] = L.Slash

-- The hub loads after this folder, so the row is added once everything is loaded.
function L.RegisterWithHub()
  if CherrysKit and CherrysKit.Register and not L.registered then
    L.registered = true
    CherrysKit.Register({
      folder = "CherrysLoadTimes",
      title = "Cherry's Addon LoadTimes",
      version = L.version,
      installed = function()
        return true
      end,
      open = function()
        L.Print()
        return true
      end,
    })
  end
end

L.Watch()
