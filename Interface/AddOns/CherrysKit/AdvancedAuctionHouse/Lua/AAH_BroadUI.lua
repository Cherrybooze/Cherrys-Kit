-- The two tabs retain independent scans. Broad quotes are display models only;
-- a fresh native normal search is required before any auction can be paid for.
local UI = { views = {} }
AAH.BroadUI = UI
local B = AAH.Browse
local nativeFields = { "itemid", "link", "name", "count", "rarity", "texture", "level",
    "leftTime", "seller", "isBuyer", "moneyMode", "bidPrice", "buyoutPrice" }

local function call(object, method, ...)
    if object and type(object[method]) == "function" then return object[method](object, ...) end
end
local function connected()
    return not AAH.Main or AAH.Main.sessionOpen ~= false
end
local function clone(source)
    local value = {}; for key, item in pairs(source or {}) do value[key] = item end; return value
end
local function emptyScan(broad)
    return { broad=broad, active=false, stage="done", items={}, byId={}, seen={}, queue={},
        queries=0, finished=0, capped=0, unresolved={} }
end
local function viewName(view)
    return (view == "broad" or view == 5) and "broad" or "normal"
end
local function findRecord(rowId)
    if type(rowId) == "table" then
        if rowId.cacheEntry or rowId.link then return rowId end
        rowId = rowId.auctionid
    end
    if rowId == nil then rowId = B.selected_auctionid end
    local record = B.Scan and B.Scan.byId and B.Scan.byId[rowId]
    if not record and B.Results and B.Results.list and B.List_FindAuctionIndex then
        local _, item=B.List_FindAuctionIndex(rowId);record=item
    end
    return record
end
local function updateModel(entry, model)
    model = model or {}
    for _, field in ipairs(nativeFields) do
        if not (field == "level" and model.parsed) then model[field] = entry.data and entry.data[field] end
    end
    model.auctionid, model.cacheEntry, model.readonly = entry.key, entry, true
    model.levelcolor = model.levelcolor or NORMAL_FONT_COLOR_CODE or "|cffffffff"
    model.searchQuery = entry.origin
    model._nativeGeneration = nil
    return model
end
local function loadBroad(scan)
    local previous, items, byId = scan.byId or {}, {}, {}
    local entries = AAH.BroadCache and AAH.BroadCache.List() or {}
    for _, entry in ipairs(entries) do
        local model = updateModel(entry, previous[entry.key])
        items[#items+1], byId[entry.key] = model, model
    end
    scan.items, scan.byId = items, byId
end
local function resetList(keepSelection)
    local selected=B.selected_auctionid
    if B.PrepareCachedSearch then B.PrepareCachedSearch() end
    B.MaxPages, B.LastCached, B.CurrentScanItem = 0, 0, 1
    B.selected_auctionid = keepSelection and selected or nil
    if B.Results then B.Results.pageNum = 1 end
    if B.List_Update then B.List_Update() end
    UI.UpdateSelection(B.selected_auctionid)
end

function UI.Switch(view, keepInputs)
    view = viewName(view)
    local outgoing = viewName(B.DataView)
    if view == outgoing and UI.views[view] then UI.UpdateHelperState();return end
    if B.PauseSession then B.PauseSession() end
    UI.views[outgoing] = UI.views[outgoing] or {}
    UI.views[outgoing].scan, UI.views[outgoing].scope = B.Scan or emptyScan(outgoing == "broad"), B.LastSearch
    local incoming = UI.views[view]
    if not incoming then
        incoming = {scan=emptyScan(view == "broad"), scope={}}
        UI.views[view] = incoming
    end
    B.DataView, B.Scan, B.LastSearch = view, incoming.scan, incoming.scope
    if view == "broad" then loadBroad(B.Scan) end
    if not keepInputs then UI.ApplyFields(incoming.scope) end
    resetList()
    if connected() and B.Scan.active and B.Scan.stage == "paused" and B.ResumeSession then B.ResumeSession() end
    call(AAH_BrowseSearchButton, "SetText", B.Scan.active and "Stop" or TEXT("C_SEARCH"))
    UI.UpdateHelperState()
end

function UI.Attach(scan, scope)
    local view = scan.broad and "broad" or "normal"
    B.DataView = view
    UI.views[view] = {scan=scan, scope=scope or B.LastSearch}
    if scan.broad then
        scan.broadRun = AAH.BroadCache.Begin(scope or B.LastSearch)
        loadBroad(scan)
    else
        scan.items, scan.byId = {}, {}
    end
    return scan
end

function UI.Remember(scan, listing)
    if not scan or not scan.broad then return listing end
    listing.searchQuery = scan.query
    local entry, key = AAH.BroadCache.Observe(scan.broadRun, listing)
    if not entry then return {} end
    key = key or entry.key
    local model = scan.byId[key]
    if not model then
        model = updateModel(entry)
        scan.items[#scan.items+1], scan.byId[key] = model, model
    else updateModel(entry, model) end
    return model
end

function UI.Finish(scan, complete)
    if not scan or not scan.broad then return end
    AAH.BroadCache.Finish(scan.broadRun, complete == true)
    AAH.BroadCache.Flush()
    loadBroad(scan)
    if B.Scan == scan then resetList(true) end
end

function UI.Refresh()
    local view=UI.views.broad
    if not view or not view.scan or view.scan.active then return end
    local scan=view.scan
    local entries=AAH.BroadCache.List()
    local changed=#entries~=#scan.items
    for _,entry in ipairs(entries) do if not scan.byId[entry.key] then changed=true;break end end
    if changed then
        loadBroad(scan)
        if B.Scan==scan then B.List_Update() end
    else
        for _,entry in ipairs(entries) do updateModel(entry,scan.byId[entry.key]) end
        if B.Scan==scan then B.List_UpdateItems() end
    end
end

function UI.UpdateSelection(rowId)
    local record = findRecord(rowId)
    local readonly = B.DataView == "broad" or B.Scan and B.Scan.broad or record and
        (record.readonly or record.cacheEntry or record._nativeGeneration ~= B.NativeGeneration)
    local handled = not record or readonly or not connected()
    if handled then
        call(AAH_BrowseBidButton,"Hide"); call(AAH_BrowseBidButton,"Disable")
        call(AAH_BrowseBuyoutButton,"Hide"); call(AAH_BrowseBuyoutButton,"Disable")
        call(AAH_BrowseHistoryButton,"Disable")
        call(AAH_BrowseBidMoneyInput,"Hide")
        -- The normal tab has no target action until one of its records goes stale.
        call(AAH_BrowseTargetSearchButton, readonly and "Show" or "Hide")
        call(AAH_BrowseTargetSearchButton, (record and connected()) and "Enable" or "Disable")
        return true
    end
    call(AAH_BrowseBidButton,"Show"); call(AAH_BrowseBuyoutButton,"Show")
    call(AAH_BrowseBidMoneyInput,"Show")
    call(AAH_BrowseTargetSearchButton,"Hide")
    return false
end

function UI.TargetSearch(rowId)
    local record = findRecord(rowId)
    if not connected() or not record or not record.name then return false end
    local scope = clone(record.cacheEntry and record.cacheEntry.origin or record.searchQuery or B.LastSearch)
    scope.name = (record.itemid==200000 or record.itemid==200003) and (scope.name or "") or record.name
    UI.ApplyFields(scope)
    B.DoSearch(scope.name, scope.minlvl or 0, scope.maxlvl or 0, scope.rarity or 1,
        scope.rune or 1, scope.usable == true or scope.usable == 1, scope.cat1, scope.cat2, scope.cat3, false)
    return true
end

function UI.AgeText(record)
    local entry = record and record.cacheEntry
    local minutes = entry and AAH.BroadCache.Age(entry)
    return type(minutes) == "number" and (math.max(0, math.floor(minutes)) .. "m ago") or "prior scan"
end

function UI.ShowItemTooltip(widget)
    local row = widget and call(widget,"GetParent")
    local record = findRecord(row and row.auctionid)
    if not record or not record.link then return false end
    call(GameTooltip,"SetOwner",widget,"ANCHOR_RIGHT")
    call(GameTooltip,"SetHyperLink",record.link)
    call(GameTooltip,"Show")
    return true
end

function UI.ApplyFields(scope)
    scope = scope or {}
    call(AAH_BrowseNameEditBox,"SetText",scope.name or "")
    call(AAH_BrowseMinLvlEditBox,"SetText",scope.minlvl and scope.minlvl ~= 0 and tostring(scope.minlvl) or "")
    call(AAH_BrowseMaxLvlEditBox,"SetText",scope.maxlvl and scope.maxlvl ~= 0 and tostring(scope.maxlvl) or "")
    call(AAH_BrowseUsableButton,"SetChecked",scope.usable == true or scope.usable == 1)
    B.SelectedCategory = {scope.cat1,scope.cat2,scope.cat3}
    B.RarityMin, B.RarityMax = scope.rarityMin, scope.rarityMax
    if B.RarityMin == nil and B.RarityMax == nil and (tonumber(scope.rarity) or 1) > 1 and B.RarityRank then
        local rank = B.RarityRank(scope.rarity - 1)
        B.RarityMin, B.RarityMax = rank, rank
    end
    if AAH_BrowseRarityDropDown and B.RarityUpdateText then B.RarityUpdateText() end
    if AAH_BrowseRuneDropDown and AAH.Tools and AAH.Tools.SetDropDown then
        local rune = scope.rune or 1
        AAH.Tools.SetDropDown(AAH_BrowseRuneDropDown,rune,B.RuneInfo and B.RuneInfo[rune] or tostring(rune))
    end
    if AAH_BrowseCategory and B.CategoryScrollBar_Update then B.CategoryScrollBar_Update() end
end

function UI.HelperMessage()
    local state = AAH.BroadCache and AAH.BroadCache.State() or "missing"
    if state == "running" then return "Broad search keeps read-only quotes. Target search item to refresh before buying." end
    local help = GlobalBank and GlobalBank.HelperHelp and GlobalBank.HelperHelp()
        or 'Run "Start Global Bank helper.bat" in Interface/AddOns/CherrysKit/GlobalBank/Helper and keep its window open.'
    local reason = state == "outdated" and "Update and restart the Global Bank helper (v1.4.3 or newer). "
        or state == "stopped" and "Global Bank helper stopped or waiting for a fresh heartbeat. "
        or "Global Bank helper is missing or not running. "
    return reason .. help
end

function UI.UpdateHelperState()
    local running = AAH.BroadCache and AAH.BroadCache.State() == "running"
    local enabled = running and connected() and not (B.Scan and B.Scan.active)
    call(AAH_BrowseBroadSearchButton,enabled and "Enable" or "Disable")
    call(AAH_BroadHelperOverlay, running and "Hide" or "Show")
    return running
end
