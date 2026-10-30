-- Cherry's Bar: /cbar perf records how smooth the game is for a while, then prints it to chat and
-- keeps it in CherrysBar_DB.perf, saved at the next Reload UI or logout. It looks at each frame's
-- length, the Lua heap once a second, and the time spent in addons' per-frame functions. It costs
-- nothing until started: while it is off, only one nil check runs per frame.

local G = CherrysBar
local P = {}
G.Perf = P

P.DEFAULT_SECONDS = 60
P.HITCH = 0.05 -- a frame this long, in seconds, is listed
P.MAX_HITCHES = 20
P.SHOW_ENTRIES = 6

-- Addons' per-frame functions, as their XML calls them. XML looks each one up on every call, so
-- swapping the function here is enough. A name that is not loaded is skipped.
P.ENTRIES = {
  "CherrysBar.OnUpdate", "CherrysChat.OnUpdate", "CherrysGrid.OnUpdate", "CherrysQuests.OnUpdate",
  "ZShop.OnUpdate", "GlobalBank.OnUpdate", "zBagKit.OnUpdate", "zBagB_OnUpdate", "Kitty.onUpdate", "RWA_Script",
  "Lootomatic.Func.OnUpdate", "CherrysClock.OnUpdate", "CherrysClockProbe.OnUpdate",
}

local run -- the recording under way

local function now()
  if type(GetTickCount) == "function" then
    return GetTickCount()
  end
  return (GetTime and GetTime() or 0) * 1000
end

local function heap()
  return collectgarbage("count")
end

local function resolve(path)
  local parent, key = _G, path
  for part, rest in string.gmatch(path, "([^.]+)(%.?)") do
    key = part
    if rest == "." then
      parent = parent[part]
      if type(parent) ~= "table" then
        return nil
      end
    end
  end
  if type(parent[key]) == "function" then
    return parent, key
  end
  return nil
end

local function wrap(path)
  local parent, key = resolve(path)
  if not parent then
    return nil
  end
  local original = parent[key]
  local stat = { name = path, calls = 0, total = 0, max = 0, parent = parent, key = key, original = original }
  local function finish(start, ...)
    local spent = now() - start
    stat.calls = stat.calls + 1
    stat.total = stat.total + spent
    if spent > stat.max then
      stat.max = spent
    end
    return ...
  end
  stat.wrapper = function(...)
    return finish(now(), original(...))
  end
  parent[key] = stat.wrapper
  return stat
end

function P.IsRunning()
  return run ~= nil
end

function P.Start(seconds)
  if run then
    G.Print("already recording: /cbar perf stop ends it.")
    return
  end
  seconds = tonumber(seconds) or P.DEFAULT_SECONDS
  run = {
    seconds = seconds, time = 0, frames = 0, longest = 0, over33 = 0, over50 = 0, over100 = 0, over250 = 0,
    combat = 0, hitches = {}, stats = {}, nextHeap = 1, heapStart = heap(), heapGrown = 0, heapFreed = 0, heapDrops = 0,
  }
  run.heapLast = run.heapStart
  for _, path in ipairs(P.ENTRIES) do
    local stat = wrap(path)
    if stat then
      run.stats[#run.stats + 1] = stat
    end
  end
  G.perfFrame = P.Frame
  G.Print("recording for " .. seconds .. " seconds. Play as usual; the result comes to chat.")
end

function P.Frame(elapsed)
  local r = run
  elapsed = tonumber(elapsed) or 0
  r.time = r.time + elapsed
  r.frames = r.frames + 1
  if elapsed > r.longest then
    r.longest = elapsed
  end
  if elapsed >= 0.033 then
    r.over33 = r.over33 + 1
    if elapsed >= P.HITCH then
      r.over50 = r.over50 + 1
      if elapsed >= 0.1 then
        r.over100 = r.over100 + 1
        if elapsed >= 0.25 then
          r.over250 = r.over250 + 1
        end
      end
      if #r.hitches < P.MAX_HITCHES then
        r.hitches[#r.hitches + 1] = { at = math.floor(r.time * 10) / 10, ms = math.floor(elapsed * 1000), heap = math.floor(heap()) }
      end
    end
  end
  if r.time >= r.nextHeap then
    r.nextHeap = r.nextHeap + 1
    local kb = heap()
    if kb < r.heapLast then
      r.heapDrops = r.heapDrops + 1
      r.heapFreed = r.heapFreed + (r.heapLast - kb)
    else
      r.heapGrown = r.heapGrown + (kb - r.heapLast)
    end
    r.heapLast = kb
    if G.InCombat() then
      r.combat = r.combat + 1
    end
  end
  if r.time >= r.seconds then
    P.Stop()
  end
end

local function byTotal(a, b)
  return a.total > b.total
end

function P.Stop()
  local r = run
  if not r then
    G.Print("not recording. /cbar perf starts it.")
    return
  end
  run = nil
  G.perfFrame = nil
  for _, stat in ipairs(r.stats) do
    if stat.parent[stat.key] == stat.wrapper then
      stat.parent[stat.key] = stat.original
    end
  end
  table.sort(r.stats, byTotal)
  local seconds = math.max(r.time, 0.001)
  local result = {
    seconds = math.floor(seconds), frames = r.frames, fps = math.floor(r.frames / seconds),
    longestMs = math.floor(r.longest * 1000),
    over33 = r.over33, over50 = r.over50, over100 = r.over100, over250 = r.over250, combatSeconds = r.combat,
    heapStartKB = math.floor(r.heapStart), heapEndKB = math.floor(heap()),
    heapGrowthKBs = math.floor(r.heapGrown / seconds), heapDrops = r.heapDrops, heapFreedKB = math.floor(r.heapFreed),
    hitches = r.hitches, addons = {},
  }
  for _, stat in ipairs(r.stats) do
    result.addons[#result.addons + 1] = {
      name = stat.name, calls = stat.calls, totalMs = stat.total, maxMs = stat.max,
      perSecondMs = math.floor(stat.total / seconds * 10) / 10,
    }
  end
  G.S().perf = result
  G.Print(result.seconds .. "s, " .. result.fps .. " fps. Longest frame " .. result.longestMs .. " ms. Frames over 33 ms: "
    .. result.over33 .. ", 50 ms: " .. result.over50 .. ", 100 ms: " .. result.over100 .. ", 250 ms: " .. result.over250)
  G.Print("Lua memory " .. result.heapStartKB .. " to " .. result.heapEndKB .. " KB, growing " .. result.heapGrowthKBs
    .. " KB a second, freed " .. result.heapDrops .. " times (" .. result.heapFreedKB .. " KB)")
  for i = 1, math.min(P.SHOW_ENTRIES, #result.addons) do
    local a = result.addons[i]
    G.Print(a.name .. ": " .. a.perSecondMs .. " ms a second, slowest call " .. a.maxMs .. " ms")
  end
  for i = 1, math.min(5, #result.hitches) do
    local h = result.hitches[i]
    G.Print("long frame at " .. h.at .. "s: " .. h.ms .. " ms, Lua memory " .. h.heap .. " KB")
  end
  G.Print("Reload UI to save this for sharing.")
end
