-- Cherry's Quests: the NPCs named in a quest's texts, and putting one in the game's NPC
-- tracking list.
--
-- Client calls (Chronicles of Arcadia API list; also used by pbInfo):
--   NpcTrack_SearchNpcByDBID(id) => count     NpcTrack_SearchNpc(name, caseInsensitive) => count
--   NpcTrack_GetNpc(i) => id, name, mapId, x, y (x and y 0..1 on that map)
--   NpcTrack_SetTarget(slot, id, r, g, b)     NpcTrackFrame_QuickTrackByNpcID(id) (the game's UI)
-- The quest texts are read after ViewQuest_QuestBook(index), like pbInfo does.

local Q = CherrysQuests
local N = {}
Q.Npcs = N

N.cache = {} -- [quest name] = list of NPCs (cleared when the quest book changes)

function N.Forget()
  N.cache = {}
end

local function trim(s)
  s = string.gsub(s or "", "^%s+", "")
  return (string.gsub(s, "%s+$", ""))
end

local function plain(s)
  s = string.gsub(s or "", "|c%x%x%x%x%x%x%x%x", "")
  s = string.gsub(s, "|r", "")
  s = string.gsub(s, "|H.-|h", "")
  s = string.gsub(s, "|h", "")
  s = string.gsub(s, "^%[", "")
  s = string.gsub(s, "%]$", "")
  return trim(s)
end
N.Plain = plain

-- NPC data for a database id, or nil when the tracker does not know it.
function N.Lookup(id)
  id = tonumber(id)
  if not id or id <= 0 then
    return nil
  end
  local ok, count = Q.Call("NpcTrack_SearchNpcByDBID", id)
  if not ok or (tonumber(count) or 0) < 1 then
    return nil
  end
  local okNpc, gid, name, map, x, y = Q.Call("NpcTrack_GetNpc", 1)
  if not okNpc or type(name) ~= "string" or name == "" then
    return nil
  end
  return { id = id, gid = tonumber(gid) or id, name = name, map = map, x = tonumber(x), y = tonumber(y) }
end

-- The NPC with exactly this name (any letter case), or nil.
function N.Search(name)
  name = plain(name)
  if name == "" or string.len(name) < 3 then
    return nil
  end
  local ok, count = Q.Call("NpcTrack_SearchNpc", name, true)
  count = ok and tonumber(count) or 0
  local want = string.lower(name)
  for i = 1, math.min(count, 25) do
    local okNpc, gid, found, map, x, y = Q.Call("NpcTrack_GetNpc", i)
    if okNpc and type(found) == "string" and string.lower(plain(found)) == want then
      return { id = tonumber(gid), gid = tonumber(gid), name = found, map = map, x = tonumber(x), y = tonumber(y) }
    end
  end
  return nil
end

-- Finds NPC mentions in one text, in reading order: links (|Hnpc:id|h[Name]|h), bare ids in
-- brackets ([110563] or [110563|Name]) and, failing those, names in brackets or colour codes
-- that the NPC search knows by that exact name.
function N.Mentions(text)
  local found = {}
  if type(text) ~= "string" or text == "" then
    return found
  end
  local function add(pos, kind, value)
    found[#found + 1] = { pos = pos, kind = kind, value = value }
  end
  local init = 1
  while true do
    local s, e, id = string.find(text, "|Hnpc:(%d+)[^|]*|h", init)
    if not s then
      break
    end
    add(s, "id", tonumber(id))
    init = e + 1
  end
  init = 1
  while true do
    local s, e, id = string.find(text, "%[(%d%d%d%d%d+)[%]|]", init)
    if not s then
      break
    end
    add(s, "id", tonumber(id))
    init = e + 1
  end
  -- names only where no link already covers the text
  local bare = string.gsub(text, "|Hnpc:.-|h.-|h", function(m)
    return string.rep(" ", string.len(m))
  end)
  init = 1
  while true do
    local s, e, name = string.find(bare, "%[([^%]%[|]+)%]", init)
    if not s then
      break
    end
    if not string.find(name, "^%d+$") then
      add(s, "name", name)
    end
    init = e + 1
  end
  init = 1
  while true do
    local s, e, name = string.find(bare, "|c%x%x%x%x%x%x%x%x(.-)|r", init)
    if not s then
      break
    end
    add(s, "name", name)
    init = e + 1
  end
  table.sort(found, function(a, b)
    return a.pos < b.pos
  end)
  return found
end

-- The texts of one quest, summary first. Selecting the quest in the quest book is how the
-- client exposes them (QuestDetail_* calls read the selected quest).
function N.Texts(quest)
  local texts = {}
  local function add(label, ok, value)
    if ok and type(value) == "string" and value ~= "" then
      texts[#texts + 1] = { label = label, text = value }
    end
  end
  for _, obj in ipairs(quest.objectives or {}) do
    add("objective", true, obj.text)
  end
  local viewed = Q.Call("ViewQuest_QuestBook", quest.id)
  N.viewed = viewed
  add("summary", Q.Call("GetQuestDetail_QuestDetailShort"))
  add("detail", Q.Call("GetQuestDetail_QuestDetail"))
  add("description", Q.Call("GetQuestDesc_QuestDetail", 1))
  local okTurnIn, turnIn = Q.Call("QuestDetail_GetRequestQuestNPC")
  local okGiver, giver = Q.Call("QuestDetail_GetQuestNPC")
  return texts, okTurnIn and tonumber(turnIn) or nil, okGiver and tonumber(giver) or nil
end

-- Every NPC Ctrl+click cycles through for this quest, without repeats.
function N.Candidates(quest, fresh)
  if not fresh and N.cache[quest.name] then
    return N.cache[quest.name]
  end
  local list, seen, tried = {}, {}, {}
  local function push(npc, source)
    if npc and npc.id and not seen[npc.id] then
      seen[npc.id] = true
      npc.source = source
      list[#list + 1] = npc
    end
  end
  local texts, turnIn = N.Texts(quest)
  local searches = 0
  for _, t in ipairs(texts) do
    for _, m in ipairs(N.Mentions(t.text)) do
      if m.kind == "id" then
        push(N.Lookup(m.value), t.label)
      else
        local key = string.lower(plain(m.value))
        if not tried[key] and searches < 12 then
          tried[key] = true
          searches = searches + 1
          push(N.Search(m.value), t.label)
        end
      end
    end
  end
  if Q.S().turnIn and turnIn then
    push(N.Lookup(turnIn), "turn-in")
  end
  N.cache[quest.name] = list
  return list
end

function N.ZoneText(npc)
  local ok, zone = Q.Call("GetZoneLocalName", npc.map)
  local where = (ok and type(zone) == "string" and zone ~= "") and zone or nil
  if npc.x and npc.y then
    local xy = string.format("%.1f, %.1f", npc.x * 100, npc.y * 100)
    where = where and (where .. " " .. xy) or xy
  end
  return where
end

-- Puts one NPC in the tracking list. Slot 0 lets the game's own quick track choose.
function N.Track(npc)
  local slot = tonumber(Q.S().slot) or 0
  local ok, how = false, nil
  if slot == 0 and type(NpcTrackFrame_QuickTrackByNpcID) == "function" then
    ok = pcall(NpcTrackFrame_QuickTrackByNpcID, npc.gid or npc.id)
    how = "quick track"
  end
  if not ok and type(NpcTrack_SetTarget) == "function" then
    -- the search fills the tracker's result list that SetTarget points into
    Q.Call("NpcTrack_SearchNpcByDBID", npc.id)
    ok = pcall(NpcTrack_SetTarget, slot > 0 and slot or 1, npc.id, 255, 127, 168)
    how = "slot " .. (slot > 0 and slot or 1)
    Q.Call("NpcTrackFrame_UpdateTarget")
    Q.Call("NpcTrackFrame_UpdateNpcList")
  end
  N.lastTrack = { name = npc.name, id = npc.id, ok = ok, how = how }
  return ok, how
end

local function findIndex(list, pick)
  if not pick then
    return 0
  end
  for i, npc in ipairs(list) do
    if npc.id == pick.id then
      return i
    end
  end
  return 0
end

-- Ctrl+click: the next (dir 1) or previous (dir -1) NPC; dir 0 tracks the remembered one again.
function N.Cycle(quest, dir)
  local list = N.Candidates(quest)
  if #list == 0 then
    -- the quest book may not have been ready: look once more before giving up
    list = N.Candidates(quest, true)
  end
  if #list == 0 then
    Q.Print("no named NPC found in \"" .. quest.name .. "\" (/cq text shows what the quest says).")
    return false
  end
  local picks = Q.Picks()
  local i = findIndex(list, picks[quest.name])
  if dir == 0 then
    i = (i > 0) and i or 1
  else
    i = i + dir
    if i > #list then
      i = 1
    elseif i < 1 then
      i = #list
    end
  end
  local npc = list[i]
  picks[quest.name] = { id = npc.id, name = npc.name }
  local ok, how = N.Track(npc)
  local where = N.ZoneText(npc)
  if ok then
    Q.Print("tracking " .. npc.name .. " (" .. i .. "/" .. #list .. ")" .. (where and (", " .. where) or ""))
  else
    Q.Print("picked " .. npc.name .. " (" .. i .. "/" .. #list .. ") but the game did not take it into the tracking list (" .. tostring(how) .. ").")
  end
  return ok
end

function N.Picked(quest)
  local pick = Q.Picks()[quest.name]
  return pick and pick.name or nil
end

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------

function N.ListAll()
  local list = Q.ReadTracked()
  if #list == 0 then
    Q.Print("no tracked quests.")
    return
  end
  for n, quest in ipairs(list) do
    local npcs = N.Candidates(quest, true)
    local names = {}
    for _, npc in ipairs(npcs) do
      names[#names + 1] = npc.name .. " [" .. tostring(npc.id) .. ", " .. tostring(npc.source) .. "]"
    end
    Q.Print(n .. ". " .. quest.name .. ": " .. (#names > 0 and table.concat(names, "; ") or "none found"))
  end
end

function N.TrackByName(name)
  name = trim(name)
  if name == "" then
    Q.Print("type a name: /cq track <NPC name>")
    return
  end
  local npc = N.Search(name)
  if not npc then
    local ok, count = Q.Call("NpcTrack_SearchNpc", name, true)
    Q.Print("no NPC named exactly \"" .. name .. "\" (" .. (ok and tostring(count) or "no search") .. " partial matches).")
    if ok and (tonumber(count) or 0) > 0 then
      local okNpc, gid, found = Q.Call("NpcTrack_GetNpc", 1)
      if okNpc and found then
        npc = { id = tonumber(gid), gid = tonumber(gid), name = found }
      end
    end
    if not npc then
      return
    end
  end
  local ok, how = N.Track(npc)
  Q.Print((ok and "tracking " or "could not track ") .. npc.name .. " [" .. tostring(npc.id) .. "] by " .. tostring(how) .. ".")
end

local function escape(s)
  return (string.gsub(s, "|", "||"))
end

function N.DumpText(n)
  local quest = Q.ReadTracked()[n]
  if not quest then
    Q.Print("no tracked quest " .. tostring(n) .. ".")
    return
  end
  local texts, turnIn, giver = N.Texts(quest)
  Q.Print(quest.name .. " (book index " .. tostring(quest.id) .. ", viewed " .. tostring(N.viewed)
    .. ", turn-in NPC " .. tostring(turnIn) .. ", giver " .. tostring(giver) .. "):")
  for _, t in ipairs(texts) do
    local text = t.text
    if string.len(text) > 400 then
      text = string.sub(text, 1, 400) .. "..."
    end
    Q.Print(t.label .. ": " .. escape(text))
  end
end
