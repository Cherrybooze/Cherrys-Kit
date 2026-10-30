-- Broad-search quotes. Only an ASCII per-character helper outbox is saved by the client.
AAH = AAH or {}
local previousGeneration = type(AAH.BroadCache) == "table" and AAH.BroadCache.SessionGeneration or 0
local previousPending = type(AAH.BroadCache) == "table" and AAH.BroadCache.RuntimePending or nil
AAH.BroadCache = { SessionGeneration = (tonumber(previousGeneration) or 0) + 1 }
local Cache = AAH.BroadCache
local MAX_AGE = 2 * 24 * 60 * 60
local BEAT_PATH = "Interface/GlobalBankHelper/GlobalBankHelperBeat.lua"
local CACHE_PATH = "Interface/GlobalBankHelper/AAHBroadCache.lua"
local BEAT_LATE, POLL_INTERVAL = 75, 10
local nativeFields = { "itemid", "link", "name", "count", "rarity", "texture", "level",
    "leftTime", "seller", "isBuyer", "moneyMode", "bidPrice", "buyoutPrice" }
-- Parsed tooltip details are optional; old caches remain readable.
local detailFields = { "details", "dura", "tier", "plus", "statNames", "statsum",
    "raw_str", "raw_dex", "raw_sta", "raw_int", "raw_wis", "raw_patt", "raw_matt",
    "raw_pdam", "raw_mdam", "raw_pdef", "raw_mdef", "raw_hp", "raw_mp", "raw_pcrit",
    "raw_mcrit", "raw_pacc", "raw_macc", "raw_pdod", "raw_parry", "raw_heal" }
local scopeFields = { "name", "minlvl", "maxlvl", "rarity", "rune", "usable", "cat1", "cat2", "cat3" }
local initialized, data, session
local lastPoll, candidateBeat, trustedBeat, trustedAt, helperProtocol
local pendingRuns, dirty, transferId, sequence, charName, serverName = {}, false, nil, 0, "", ""
local submittedRunCount, pendingKeys = 0, {}

-- UTF-8 bytes remain intact inside Base64; the native SavedVariables string is ASCII only.
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64Encode(value)
    local out = {}
    for i = 1, #value, 3 do
        local a, b, c = string.byte(value, i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local x, y, z, w = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64, math.floor(n / 64) % 64, n % 64
        out[#out + 1] = string.sub(alphabet, x + 1, x + 1) .. string.sub(alphabet, y + 1, y + 1)
            .. (b and string.sub(alphabet, z + 1, z + 1) or "=") .. (c and string.sub(alphabet, w + 1, w + 1) or "=")
    end
    return table.concat(out)
end

local function base64Decode(value)
    if type(value) ~= "string" or #value % 4 ~= 0 or string.find(value, "[^%w%+/%=]") then error("invalid base64") end
    local out = {}
    for i = 1, #value, 4 do
        local chars, n = string.sub(value, i, i + 3), 0
        for j = 1, 4 do
            local c = string.sub(chars, j, j)
            local at = string.find(alphabet, c, 1, true)
            if not at and c ~= "=" then error("invalid base64") end
            if c == "=" and (j < 3 or i + 3 ~= #value) then error("invalid padding") end
            n = n * 64 + (at and at - 1 or 0)
        end
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if string.sub(chars, 3, 3) ~= "=" then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
        if string.sub(chars, 4, 4) ~= "=" then out[#out + 1] = string.char(n % 256) end
    end
    return table.concat(out)
end

local function jsonQuote(value)
    return '"' .. string.gsub(value, '[%z\1-\31\\"]', function(c)
        return string.format("\\u%04x", string.byte(c))
    end) .. '"'
end

local function jsonEncode(value, array)
    local kind = type(value)
    if kind == "string" then return jsonQuote(value) end
    if kind == "number" or kind == "boolean" then return tostring(value) end
    if kind ~= "table" then error("unsupported JSON value") end
    local out = {}
    if array or #value > 0 then
        for _, item in ipairs(value) do out[#out + 1] = jsonEncode(item) end
        return "[" .. table.concat(out, ",") .. "]"
    end
    for key, item in pairs(value) do
        out[#out + 1] = jsonQuote(key) .. ":" .. jsonEncode(item, key == "entries" or key == "runs" or key == "seenKeys")
    end
    table.sort(out)
    return "{" .. table.concat(out, ",") .. "}"
end

-- A data parser, never loadstring: pending outboxes must survive Reload UI without code execution.
local function jsonDecode(source)
    local pos, depth = 1, 0
    local function space() local _, last = string.find(source, "^%s*", pos); pos = (last or pos - 1) + 1 end
    local parse
    local function text()
        pos = pos + 1
        local out = {}
        while pos <= #source do
            local c = string.sub(source, pos, pos); pos = pos + 1
            if c == '"' then return table.concat(out) end
            if c == "\\" then
                c = string.sub(source, pos, pos); pos = pos + 1
                local escapes = { ['"']='"', ['\\']='\\', ['/']='/', b='\b', f='\f', n='\n', r='\r', t='\t' }
                if c == "u" then
                    local h = string.sub(source, pos, pos + 3)
                    if #h ~= 4 or string.find(h, "[^%x]") then error("invalid escape") end
                    local n = tonumber(h, 16); pos = pos + 4
                    if n < 128 then c = string.char(n)
                    elseif n < 2048 then c = string.char(192 + math.floor(n / 64), 128 + n % 64)
                    elseif n < 55296 or n > 57343 then c = string.char(224 + math.floor(n / 4096), 128 + math.floor(n / 64) % 64, 128 + n % 64)
                    else error("unsupported surrogate") end
                else c = escapes[c]; if not c then error("invalid escape") end end
            elseif string.byte(c) < 32 then error("invalid string") end
            out[#out + 1] = c
        end
        error("unterminated string")
    end
    parse = function()
        space(); depth = depth + 1; if depth > 30 then error("JSON nesting") end
        local c, result = string.sub(source, pos, pos)
        if c == '"' then result = text()
        elseif c == "{" or c == "[" then
            local object, closing = c == "{", c == "{" and "}" or "]"
            result = {}; pos = pos + 1; space()
            if string.sub(source, pos, pos) ~= closing then
                while true do
                    local key
                    if object then
                        if string.sub(source, pos, pos) ~= '"' then error("object key") end
                        key = text(); space(); if string.sub(source, pos, pos) ~= ":" then error("missing colon") end
                        pos = pos + 1
                    else key = #result + 1 end
                    result[key] = parse(); space()
                    local separator = string.sub(source, pos, pos)
                    if separator == closing then break end
                    if separator ~= "," then error("missing comma") end
                    pos = pos + 1; space()
                end
            end
            pos = pos + 1
        elseif string.sub(source, pos, pos + 3) == "true" then result = true; pos = pos + 4
        elseif string.sub(source, pos, pos + 4) == "false" then result = false; pos = pos + 5
        else
            local number = string.match(source, "^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
            result = tonumber(number)
            if not result or result ~= result or result == math.huge or result == -math.huge then error("invalid number") end
            pos = pos + #number
        end
        depth = depth - 1; return result
    end
    local value = parse(); space(); if pos <= #source then error("trailing JSON") end
    return value
end

local function scalar(value)
    local kind = type(value)
    if kind == "string" or kind == "boolean" then return value end
    if kind == "number" and value == value and value ~= math.huge and value ~= -math.huge then return value end
end

local function relativeNow()
    if type(GetTime) ~= "function" then return nil end
    local ok, value = pcall(GetTime)
    if ok and type(value) == "number" and scalar(value) and value >= 0 then return value end
end

local function readBeat()
    local value
    GlobalBank_AAHCacheProtocol = nil
    if GlobalBank and type(GlobalBank.ReadBeat) == "function" then
        local ok, result = pcall(GlobalBank.ReadBeat)
        if ok then value = result end
    elseif type(dofile) == "function" then
        local previous = GlobalBank_HelperBeat
        GlobalBank_HelperBeat = nil
        local ok = pcall(dofile, BEAT_PATH)
        if ok then value = GlobalBank_HelperBeat end
        GlobalBank_HelperBeat = previous
    end
    helperProtocol = GlobalBank_AAHCacheProtocol
    value = tonumber(value)
    if value and scalar(value) and value >= 946684800 then return value end
end

-- A lone beat may be yesterday's file. Only an advancing beat proves that the helper is alive.
-- Sampling is shared by the whole cache, never one timer or disk read per listing.
function Cache.RefreshClock()
    local now = relativeNow()
    if not now then return nil end
    if lastPoll and (now < lastPoll or now - lastPoll > BEAT_LATE) then
        lastPoll, candidateBeat, trustedBeat, trustedAt = nil, nil, nil, nil
    end
    if not lastPoll or now - lastPoll >= POLL_INTERVAL then
        lastPoll = now
        local beat = readBeat()
        if beat then
            if candidateBeat and beat > candidateBeat then trustedBeat, trustedAt = beat, now end
            if candidateBeat and beat < candidateBeat then trustedBeat, trustedAt = nil, nil end
            candidateBeat = beat
        else
            candidateBeat, trustedBeat, trustedAt = nil, nil, nil
        end
    end
    if trustedBeat and trustedAt and now >= trustedAt and now - trustedAt <= BEAT_LATE then
        return trustedBeat + now - trustedAt
    end
end

-- An initial beat cannot distinguish a running helper from a file left behind yesterday.
function Cache.State()
    if Cache.RefreshClock() then return helperProtocol == 1 and "running" or "outdated" end
    return candidateBeat and "stopped" or "missing"
end

local function trustedNow()
    local now = relativeNow()
    if now and trustedBeat and trustedAt and now >= trustedAt and now - trustedAt <= BEAT_LATE then
        return trustedBeat + now - trustedAt
    end
end

local function part(value)
    value = scalar(value)
    if value == nil then return "n:" end
    local text = tostring(value)
    return type(value) .. ":" .. string.len(text) .. ":" .. text
end

-- The full link distinguishes modifiers; length prefixes prevent delimiter collisions.
function Cache.Key(native)
    return table.concat({ part(native.link), part(native.seller), part(native.count),
        part(native.moneyMode), part(native.buyoutPrice) }, "|")
end

local function copyScope(source)
    local scope = {}
    for _, field in ipairs(scopeFields) do scope[field] = scalar(source and source[field]) end
    scope.name = scope.name or ""
    scope.minlvl, scope.maxlvl = scope.minlvl or 0, scope.maxlvl or 0
    scope.rarity, scope.rune = scope.rarity or 1, scope.rune or 1
    scope.usable = scope.usable == true or scope.usable == 1
    for _, field in ipairs({ "cat1", "cat2", "cat3" }) do
        if scope[field] == 0 then scope[field] = nil end
    end
    return scope
end

local function scopeKey(scope)
    local parts = {}
    for _, field in ipairs(scopeFields) do parts[#parts + 1] = part(scope[field]) end
    return table.concat(parts, "|")
end

local function isAll(scope)
    return scope.name == "" and scope.minlvl == 0 and scope.maxlvl == 0
        and scope.rarity == 1 and scope.rune == 1 and not scope.usable
        and not scope.cat1 and not scope.cat2 and not scope.cat3
end

local function pruneExpired()
    local now = trustedNow()
    if not now then return end
    for key, entry in pairs(data.entries) do
        if type(entry.lastSeenTrustedUTC) == "number" then
            -- The game's remaining time is in minutes and rounds up, so a live auction isn't removed early.
            local left = type(entry.data) == "table" and entry.data.leftTime
            if now - entry.lastSeenTrustedUTC >= MAX_AGE
                or (type(left) == "number" and now - entry.lastSeenTrustedUTC >= left * 60) then
                data.entries[key] = nil
            end
        end
    end
end

local function characterName()
    if type(UnitName) == "function" then
        local ok, name = pcall(UnitName, "player")
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return ""
end

local function realmName()
    if type(GetServerName) == "function" then
        local ok, name = pcall(GetServerName)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return "@character:" .. charName
end

local function cleanEntry(source)
    if type(source) ~= "table" or type(source.data) ~= "table" or type(source.data.link) ~= "string" then return nil end
    local entry = { data = {}, memberships = {}, origin = copyScope(type(source.origin) == "table" and source.origin or {}) }
    for _, field in ipairs(nativeFields) do entry.data[field] = scalar(source.data[field]) end
    for _, field in ipairs(detailFields) do entry.data[field] = scalar(source.data[field]) end
    entry.key = Cache.Key(entry.data)
    if type(source.lastSeenTrustedUTC) == "number" and scalar(source.lastSeenTrustedUTC) then
        entry.lastSeenTrustedUTC = source.lastSeenTrustedUTC
    end
    if type(source.memberships) == "table" then
        for key, present in pairs(source.memberships) do
            if type(key) == "string" and present == true then entry.memberships[key] = true end
        end
    end
    return entry
end

local function cleanRun(source)
    if type(source) ~= "table" or type(source.scope) ~= "table" or type(source.seenKeys) ~= "table" then return nil end
    if type(source.completedUTC) ~= "number" or not scalar(source.completedUTC) then return nil end
    local query = copyScope(source.scope)
    local run = { id = type(source.id) == "string" and source.id or "", key = scopeKey(query), scope = query,
        all = isAll(query), completedUTC = source.completedUTC, seenKeys = {} }
    for _, key in ipairs(source.seenKeys) do if type(key) == "string" then run.seenKeys[#run.seenKeys + 1] = key end end
    return run
end

local function mergeEntries(entries)
    local imported = {}
    if type(entries) ~= "table" then return imported end
    for _, source in ipairs(entries) do
        local entry = cleanEntry(source)
        if entry then
            imported[entry.key] = true
            local old = data.entries[entry.key]
            if not old then data.entries[entry.key] = entry
            elseif (entry.lastSeenTrustedUTC and (not old.lastSeenTrustedUTC or entry.lastSeenTrustedUTC > old.lastSeenTrustedUTC))
                or (old.lastSeenSession ~= session and not pendingKeys[entry.key]
                    and (entry.lastSeenTrustedUTC or 0) == (old.lastSeenTrustedUTC or 0)) then
                for _, field in ipairs(nativeFields) do old.data[field] = entry.data[field] end
                for _, field in ipairs(detailFields) do old.data[field] = entry.data[field] end
                old.origin, old.memberships, old.lastSeenTrustedUTC = entry.origin, entry.memberships, entry.lastSeenTrustedUTC
                old.lastSeenSession, old.lastSeenRelative = nil, nil
            end
        end
    end
    return imported
end

local function reconcile(run, seen, beforeUTC)
    for key, entry in pairs(data.entries) do
        if not seen[key] and (not beforeUTC or (entry.lastSeenTrustedUTC and entry.lastSeenTrustedUTC <= beforeUTC)) then
            if run.all then data.entries[key] = nil
            elseif entry.memberships[run.key] then
                entry.memberships[run.key] = nil
                if not next(entry.memberships) then data.entries[key] = nil end
            end
        end
    end
end

local function markDirty()
    dirty = true
    -- This table is deliberately unregistered: preserve an interrupted scan through Reload UI.
    Cache.RuntimePending = { entries = data.entries, runs = pendingRuns, charName = charName, serverName = serverName, dirty = true }
end

function Cache.Snapshot()
    Cache.Init()
    local entries = {}
    for _, entry in pairs(data.entries) do entries[#entries + 1] = cleanEntry(entry) end
    return entries
end

function Cache.ReadHelper()
    Cache.Init()
    -- Only the dedicated helper-generated data chunk is evaluated, with no globals or APIs.
    if type(loadfile) ~= "function" or type(setfenv) ~= "function" then return false end
    local ok, chunk = pcall(loadfile, CACHE_PATH)
    if not ok or type(chunk) ~= "function" then return false end
    local sandboxed = pcall(setfenv, chunk, {})
    if not sandboxed then return false end
    local read, export = pcall(chunk)
    if not read or type(export) ~= "table" or export.schemaVersion ~= 1 or type(export.realms) ~= "table" then return false end
    local realm = export.realms[serverName]
    if type(realm) ~= "table" or type(realm.entries) ~= "table" then return false end
    local acknowledged = transferId and type(realm.acknowledgements) == "table" and realm.acknowledgements[charName] == transferId
    if acknowledged then
        AAH_BroadOutbox = nil
        if not dirty then Cache.RuntimePending = nil end
        transferId, pendingKeys = nil, {}
        for _ = 1, submittedRunCount do table.remove(pendingRuns, 1) end
        submittedRunCount = 0
    end
    local imported = mergeEntries(realm.entries)
    for key, entry in pairs(data.entries) do
        if not imported[key] and entry.lastSeenSession ~= session and not pendingKeys[key] then data.entries[key] = nil end
    end
    -- An older helper export must not resurrect an offer that a pending complete scan removed.
    for _, run in ipairs(pendingRuns) do
        local seen = {}; for _, key in ipairs(run.seenKeys) do seen[key] = true end
        reconcile(run, seen, run.completedUTC)
    end
    pruneExpired()
    return true
end

function Cache.Flush()
    Cache.Init()
    if not dirty then return AAH_BroadOutbox end
    charName = characterName()
    if charName == "" then return nil end
    serverName = realmName()
    sequence = sequence + 1
    transferId = charName .. ":" .. tostring(trustedNow() or "unknown") .. ":" .. tostring(relativeNow() or 0)
        .. ":" .. tostring(session) .. ":" .. tostring(sequence)
    local snapshot = Cache.Snapshot()
    AAH_BroadOutbox = "AAHB1:" .. base64Encode(jsonEncode({ schemaVersion = 1, charName = charName, serverName = serverName,
        transferId = transferId, entries = snapshot, runs = pendingRuns }))
    pendingKeys = {}; for _, entry in ipairs(snapshot) do pendingKeys[entry.key] = true end
    submittedRunCount, dirty = #pendingRuns, false
    if Cache.RuntimePending then Cache.RuntimePending.dirty = false end
    return AAH_BroadOutbox
end

function Cache.Init()
    if initialized then return end
    initialized = true
    session = Cache.SessionGeneration
    data = { version = 1, entries = {} }
    charName = characterName()
    serverName = realmName()
    if type(SaveVariablesPerCharacter) == "function" then SaveVariablesPerCharacter("AAH_BroadOutbox") end
    if type(AAH_BroadOutbox) == "string" and string.sub(AAH_BroadOutbox, 1, 6) == "AAHB1:" then
        local ok, pending = pcall(function() return jsonDecode(base64Decode(string.sub(AAH_BroadOutbox, 7))) end)
        if ok and type(pending) == "table" and pending.schemaVersion == 1 and pending.charName == charName and pending.serverName == serverName
            and type(pending.transferId) == "string" then
            transferId = pending.transferId
            pendingKeys = mergeEntries(pending.entries)
            if type(pending.runs) == "table" then
                for _, source in ipairs(pending.runs) do local run = cleanRun(source); if run then pendingRuns[#pendingRuns + 1] = run end end
            end
            submittedRunCount = #pendingRuns
        end
    end
    Cache.RefreshClock()
    if type(previousPending) == "table" and previousPending.charName == charName
        and previousPending.serverName == serverName and type(previousPending.entries) == "table" then
        data.entries = previousPending.entries
        pendingRuns = type(previousPending.runs) == "table" and previousPending.runs or {}
        markDirty()
        Cache.Flush()
    end
    previousPending = nil
    Cache.ReadHelper()
    pruneExpired()
end

function Cache.Begin(scope)
    Cache.Init()
    Cache.RefreshClock()
    pruneExpired()
    local query = copyScope(scope)
    return { scope = query, key = scopeKey(query), all = isAll(query), seen = {} }
end

function Cache.Observe(run, native)
    Cache.Init()
    if type(run) ~= "table" or run.finished or type(native) ~= "table" or type(native.link) ~= "string" then return end
    Cache.RefreshClock()
    local key = Cache.Key(native)
    local entry = data.entries[key]
    local isNew = not entry
    if not entry then entry = { key = key, data = {}, memberships = {} }; data.entries[key] = entry end
    for _, field in ipairs(nativeFields) do entry.data[field] = scalar(native[field]) end
    entry.origin = copyScope(type(native.searchQuery) == "table" and native.searchQuery or run.scope)
    entry.memberships[run.key] = true
    entry.lastSeenSession, entry.lastSeenRelative = session, relativeNow()
    -- An offline refresh cannot preserve an older trusted timestamp as though it dates this sighting.
    entry.lastSeenTrustedUTC = trustedNow()
    run.seen[key] = true
    markDirty()
    return entry, key, isNew
end

-- Save only values AAH already parsed from this listing's tooltip; never scan extra items.
function Cache.RecordDetails(listing)
    if type(listing) ~= "table" or not listing.parsed or type(listing.cacheEntry) ~= "table" then return end
    local entry = listing.cacheEntry
    if not data or data.entries[entry.key] ~= entry then return end
    local values = { details = true, dura = listing.dura, tier = listing.tier, plus = listing.plus,
        statsum = listing.statsum }
    local names = {}
    for _, slot in ipairs(listing.slots or {}) do
        if type(slot.name) == "string" and slot.name ~= "" then names[#names + 1] = slot.name end
    end
    local statNames = table.concat(names, "; ")
    if #statNames <= 4096 then values.statNames = statNames end
    for key, value in pairs(listing.raw or {}) do
        if type(key) == "string" then values["raw_" .. key] = value end
    end
    local changed = false
    for _, field in ipairs(detailFields) do
        local value = scalar(values[field])
        if entry.data[field] ~= value then entry.data[field] = value; changed = true end
    end
    if changed then markDirty() end
end

function Cache.Finish(run, complete)
    Cache.Init()
    Cache.RefreshClock()
    if type(run) ~= "table" or run.finished then return end
    run.finished = true
    if complete == true then
        reconcile(run, run.seen)
        local utc = trustedNow()
        if utc then
            sequence = sequence + 1
            local completed = { id = charName .. ":run:" .. tostring(utc) .. ":" .. tostring(session) .. ":" .. tostring(sequence),
                key = run.key, scope = copyScope(run.scope), all = run.all, seenKeys = {}, completedUTC = utc }
            for key in pairs(run.seen) do completed.seenKeys[#completed.seenKeys + 1] = key end
            table.sort(completed.seenKeys)
            pendingRuns[#pendingRuns + 1] = completed
        end
        markDirty()
    end
    pruneExpired()
end

function Cache.List()
    Cache.Init()
    Cache.RefreshClock()
    pruneExpired()
    local list = {}
    for _, entry in pairs(data.entries) do list[#list + 1] = entry end
    return list
end

-- Minutes since the last observation; nil means a prior scan without a trusted wall clock.
function Cache.Age(entry)
    if type(entry) ~= "table" then return nil end
    local now = trustedNow()
    if now and type(entry.lastSeenTrustedUTC) == "number" and now >= entry.lastSeenTrustedUTC then
        return (now - entry.lastSeenTrustedUTC) / 60
    end
    local relative = relativeNow()
    if entry.lastSeenSession == session and relative and type(entry.lastSeenRelative) == "number"
        and relative >= entry.lastSeenRelative then return (relative - entry.lastSeenRelative) / 60 end
end
