-- Cherry's Kit: a small hub for Cherry's addons. /ck opens a window that can open each addon's
-- settings, turn an addon on or off, and reload the UI.
--
-- RoM has no API to enable or disable an addon, so "off" is a flag the addons read at load:
--   if CherrysKit and not CherrysKit.IsEnabled("KittyCombo") then ... stay idle ... end
-- A change takes effect after Reload UI.

CherrysKit = CherrysKit or {}
local Kit = CherrysKit

Kit.version = "0.4.25"
Kit.MAX_ROWS = 18

if SaveVariables then
  SaveVariables("CherrysKit_DB")
end

local function db()
  if type(CherrysKit_DB) ~= "table" then
    CherrysKit_DB = {}
  end
  if type(CherrysKit_DB.disabled) ~= "table" then
    CherrysKit_DB.disabled = {}
  end
  return CherrysKit_DB
end

local function print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7fa8Cherry's Kit|r: " .. tostring(msg))
  end
end
Kit.Print = print

local function runSlash(key, msg)
  local fn = SlashCmdList and SlashCmdList[key]
  if type(fn) ~= "function" then
    return false, "slash handler " .. tostring(key) .. " is not available"
  end
  -- The hub's open handler supplies the addon/action context if this call fails.
  fn(nil, msg or "")
  return true
end

-- Addons in the kit. Each one can also call CherrysKit.Register itself to replace its entry.
Kit.addons = {
  {
    folder = "KittyCombo",
    title = "Cherry's KittyCombo",
    installed = function()
      return Kitty ~= nil
    end,
    open = function()
      return runSlash("KittyCombo", "show")
    end,
  },
  {
    folder = "RomWeakAuras",
    title = "rom weakauras",
    installed = function()
      return RWA ~= nil
    end,
    open = function()
      if RWA and RWA.ToggleOptions then
        RWA.ToggleOptions()
        return true
      end
      return runSlash("RomWeakAuras", "")
    end,
  },
  {
    -- ZShop registers itself too; this keeps its row even if that call never ran.
    folder = "ZShop",
    title = "ZShop",
    installed = function()
      return type(ZShop) == "table"
    end,
    open = function()
      if type(ZShop) == "table" and ZShop.Toggle then
        ZShop.Toggle()
        return true
      end
      return runSlash("ZSHOP", "")
    end,
  },
}

function Kit.Register(entry)
  for i, existing in ipairs(Kit.addons) do
    if existing.folder == entry.folder then
      Kit.addons[i] = entry
      Kit.Refresh()
      return
    end
  end
  table.insert(Kit.addons, entry)
  Kit.Refresh()
end

---------------------------------------------------------------------------
-- Original addons. A kit addon whose original, or an older separate copy of it, also sits in its own
-- folder in Interface\AddOns would load twice, so that one takes precedence: the kit's version stays
-- off (Kit.IsEnabled is false) and the hub says so for each one, in chat and in its window.
-- RoM cannot list addons, but loadfile can tell that a file is there without running it, whichever
-- loads first, so this is known before any kit addon loads. KitOrigins.lua, written from
-- release-packages.json, says what to look for. A folder under another name still shows by a global
-- that copy defines, its fingerprint:
--   before: the global already existed when the kit started loading that addon
--   after:  the global changed after the kit loaded that addon (another copy loaded later)
-- A name starting with "-" is one the kit's version never defines: it exists only with the other copy.
-- Nothing is said about a kit addon that isn't installed: its original is simply what's running.
--
-- The manifest can't skip files, so the kit's copy still loads. When it's known to be giving way, whatever
-- it adds is taken back as soon as it has loaded: its globals and commands go, and its frames are hidden
-- with their event and update scripts cleared. So the original runs as it would without the kit, whichever
-- of the two the game loads first.
---------------------------------------------------------------------------
Kit.ORIGINS = CherrysKit_Origins or {}
Kit.oldCopies = {} -- folder -> how it was found
Kit.kitFound = {} -- folder -> is the kit's own copy installed
Kit.warnedOld = nil -- warn again after Reload UI
-- folder -> { value, version } right after the kit loaded it. Reload UI re-runs every file in the
-- same Lua state, so this survives it: a global that is still the kit's own from before the
-- reload is not another copy.
Kit.ours = Kit.ours or {}

-- A file that can't be compiled is still there; only "cannot open" means it isn't.
local function fileThere(path)
  if type(loadfile) ~= "function" then
    return false
  end
  local ok, fn, message = pcall(loadfile, path)
  if not ok then
    return false
  end
  return fn ~= nil or (type(message) == "string" and string.find(string.lower(message), "cannot open", 1, true) == nil)
end

local function kitThere(folder)
  local origin = Kit.ORIGINS[folder]
  if not origin then
    return false
  end
  if type(loadfile) ~= "function" then
    return true
  end
  if Kit.kitFound[folder] == nil then
    Kit.kitFound[folder] = fileThere("Interface/AddOns/CherrysKit/" .. origin.kit_file)
  end
  return Kit.kitFound[folder]
end

for folder, origin in pairs(Kit.ORIGINS) do
  if kitThere(folder) then
    for _, file in ipairs(origin.files) do
      if fileThere("Interface/AddOns/" .. origin.folder .. "/" .. file) then
        Kit.oldCopies[folder] = "file"
      end
    end
  end
end

local function versionField(v)
  if type(v) == "table" then
    return rawget(v, "version") or rawget(v, "VERSION") or rawget(v, "ADDON_VERSION")
  end
  return nil
end

local function fingerprintOf(folder)
  local origin = Kit.ORIGINS[folder]
  return origin and origin.fingerprint
end

local loadingFolder
local keptGlobals, keptTables
-- Tables every addon adds to, as well as the globals themselves
local SHARED_TABLES = { "SlashCmdList", "StaticPopupDialogs", "UIPanelWindows" }

local function copyOf(source)
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
end

-- A frame stays in the client, but with nothing left to run. Plain data has no such calls.
local function silence(value)
  if type(value) ~= "table" then
    return
  end
  local ok, clear = pcall(function() return value.SetScripts end)
  if ok and type(clear) == "function" then
    pcall(clear, value, "OnEvent", "")
    pcall(clear, value, "OnUpdate", "")
    pcall(value.Hide, value)
  end
end

local function putBack(target, kept, whenChanged)
  for key, value in pairs(target) do
    if kept[key] == nil then
      if whenChanged then
        whenChanged(value)
      end
      rawset(target, key, nil)
    end
  end
  for key, value in pairs(kept) do
    local now = rawget(target, key)
    if now ~= value then
      if whenChanged then
        whenChanged(now)
      end
      rawset(target, key, value)
    end
  end
end

local function startAddon(folder)
  local name = fingerprintOf(folder)
  local ours = Kit.ours[folder]
  if kitThere(folder) and name and string.sub(name, 1, 1) ~= "-" and rawget(_G, name) ~= nil
    and not (ours and rawget(_G, name) == ours.value) then
    Kit.oldCopies[folder] = "before"
  end
  if Kit.oldCopies[folder] then
    keptGlobals = copyOf(_G)
    keptTables = {}
    for _, shared in ipairs(SHARED_TABLES) do
      local target = rawget(_G, shared)
      if type(target) == "table" then
        keptTables[shared] = copyOf(target)
      end
    end
  end
end
local function finishAddon(folder)
  if keptGlobals then
    for shared, kept in pairs(keptTables) do
      local target = rawget(_G, shared)
      if type(target) == "table" then
        putBack(target, kept)
      end
    end
    putBack(_G, keptGlobals, silence)
    keptGlobals, keptTables = nil, nil
  end
  local name = fingerprintOf(folder)
  if name and string.sub(name, 1, 1) ~= "-" then
    Kit.ours[folder] = { value = rawget(_G, name), version = versionField(rawget(_G, name)) }
  end
end

-- build_kit.py puts CherrysKit_Load.Mark("<Folder>") before each addon's files (LoadTimes/CherrysLoadTimes.lua):
-- the mark of one addon is also the end of the one before.
function Kit.OnLoadMark(name)
  if loadingFolder then
    finishAddon(loadingFolder)
  end
  loadingFolder = Kit.ORIGINS[name] and name or nil
  if loadingFolder then
    startAddon(loadingFolder)
  end
end
-- (LoadTimes defines Mark again on every load, so the hook is checked by identity, not a flag.)
if type(CherrysKit_Load) == "table" and type(CherrysKit_Load.Mark) == "function"
  and CherrysKit_Load.Mark ~= Kit.markHook then
  local mark = CherrysKit_Load.Mark
  Kit.markHook = function(name, ...)
    mark(name, ...)
    pcall(Kit.OnLoadMark, name)
  end
  CherrysKit_Load.Mark = Kit.markHook
end

-- true when the original, or another separate copy, takes precedence over this kit addon
function Kit.OriginTakesPrecedence(folder)
  if not kitThere(folder) then
    return false
  end
  if Kit.oldCopies[folder] then
    return true
  end
  local name = fingerprintOf(folder)
  if not name then
    return false
  end
  if string.sub(name, 1, 1) == "-" then
    return rawget(_G, string.sub(name, 2)) ~= nil
  end
  local ours = Kit.ours[folder]
  if ours and loadingFolder ~= folder then
    local now = rawget(_G, name)
    return now ~= ours.value or versionField(now) ~= ours.version
  end
  return false
end

-- For chat: "the original zBag 5.07 in Interface\AddOns\zBag"
local function originWords(origin)
  local where = "Interface\\AddOns\\" .. origin.folder
  if origin.kind == "older" then
    return "your separate copy in " .. where
  end
  return "the original " .. origin.name .. " in " .. where
end

-- What an addon in the kit checks at load. Addons not in the kit are always on. A kit addon whose
-- original or separate copy is installed too stays off.
function Kit.IsEnabled(folder)
  return not db().disabled[folder] and not Kit.OriginTakesPrecedence(folder)
end

local pendingReload = false

function Kit.SetEnabled(folder, on)
  db().disabled[folder] = (not on) or nil
  pendingReload = true
  Kit.Refresh()
end

local function versionOf(entry)
  if entry.version then
    return entry.version
  end
  if entry.folder == "RomWeakAuras" and RWA then
    return RWA.version
  end
  if entry.folder == "KittyCombo" and Kitty and Kitty.version then
    return tostring(Kitty.version)
  end
  return nil
end

local function setText(obj, text)
  if obj and obj.SetText then
    obj:SetText(text)
  end
end

local function setShown(obj, on)
  if obj then
    if on then
      obj:Show()
    else
      obj:Hide()
    end
  end
end

-- Only addons that are actually loaded get a row, so the window lists what this install has.
local function installed(entry)
  if entry.installed == nil then
    return true
  end
  local ok, result = pcall(entry.installed)
  return ok and result and true or false
end

Kit.visible = {}

function Kit.Refresh()
  if not CherrysKit_Frame then
    return
  end
  Kit.visible = {}
  local listed = {}
  for _, entry in ipairs(Kit.addons) do
    if installed(entry) then
      table.insert(Kit.visible, entry)
      listed[entry.folder] = true
    end
  end
  -- One that stays off may never have registered itself, and still gets its row to say why.
  for folder, origin in pairs(Kit.ORIGINS) do
    if not listed[folder] and Kit.OriginTakesPrecedence(folder) then
      table.insert(Kit.visible, { folder = folder, title = origin.title })
    end
  end
  for i = 1, Kit.MAX_ROWS do
    local entry = Kit.visible[i]
    local name = _G["CherrysKit_Row" .. i .. "Name"]
    local open = _G["CherrysKit_Row" .. i .. "Open"]
    local toggle = _G["CherrysKit_Row" .. i .. "Toggle"]
    if entry then
      local old = Kit.OriginTakesPrecedence(entry.folder)
      local enabled = Kit.IsEnabled(entry.folder)
      local version = versionOf(entry)
      local label = entry.title .. (version and ("  " .. version) or "")
      if old then
        label = entry.title .. "  |cffff6060off|r"
      elseif not enabled then
        label = label .. "  |cffff6060(off)|r"
      end
      setText(name, label)
      setText(_G["CherrysKit_Row" .. i .. "Cmd"], old and ("|cffff6060AddOns\\" .. Kit.ORIGINS[entry.folder].folder .. " takes precedence|r")
        or ("|cffaaaaaa" .. Kit.CommandText(entry.folder) .. "|r"))
      setText(open, "Settings")
      setText(toggle, enabled and "Turn off" or "Turn on")
      setShown(open, enabled)
      setShown(toggle, not old)
    else
      setText(name, "")
      setText(_G["CherrysKit_Row" .. i .. "Cmd"], "")
      setShown(open, false)
      setShown(toggle, false)
    end
  end
  setText(CherrysKit_FrameHint, pendingReload and "|cffffd100Reload UI to apply your changes.|r" or "Turning an addon on or off applies after Reload UI.")
  setText(CherrysKit_FrameTitle, "Cherry's Kit  " .. Kit.version .. "   |cffaaaaaa" .. Kit.CommandText("ControlHub") .. "|r")
end

local function openEntry(entry, source)
  local ok, result, reason
  if type(entry.open) == "function" then
    ok, result, reason = pcall(entry.open)
  else
    ok, result, reason = true, false, "no settings handler is registered"
  end
  if not ok or result == false then
    local detail
    if not ok then detail = result else detail = reason end
    if detail == nil then
      detail = not ok and "the client supplied no error detail (nil)" or "the settings handler was not ready"
    end
    Kit.lastOpenError = {
      folder = entry.folder,
      source = source,
      detail = tostring(detail),
    }
    print(tostring(entry.title or entry.folder) .. " [" .. tostring(entry.folder) .. ", " .. source
      .. "] could not be opened: " .. tostring(detail))
    return false
  end
  Kit.lastOpenError = nil
  return true
end

function Kit.OnRowClick(i, what)
  local entry = Kit.visible[i]
  if not entry then
    return false
  end
  if what == "open" then
    if not Kit.IsEnabled(entry.folder) then
      print(entry.title .. " is turned off. Turn it on here and Reload UI.")
      return false
    end
    return openEntry(entry, "hub row " .. tostring(i))
  elseif what == "toggle" then
    local on = not Kit.IsEnabled(entry.folder)
    Kit.SetEnabled(entry.folder, on)
    print(entry.title .. (on and " will be on" or " will be off") .. " after Reload UI.")
    return true
  end
  return false
end

function Kit.Toggle()
  if not CherrysKit_Frame then
    return
  end
  if CherrysKit_Frame:IsVisible() then
    CherrysKit_Frame:Hide()
  else
    Kit.Refresh()
    CherrysKit_Frame:Show()
  end
end

function Kit.Reload()
  if ReloadUI then
    ReloadUI()
  else
    print("this client has no ReloadUI; type /reloadui")
  end
end

-- Minimap buttons of kit addons that the kit's own button replaces.
Kit.ADDON_MINIMAP_BUTTONS = { "KittyMinimap" }

function Kit.HideAddonMinimapButtons()
  for _, name in ipairs(Kit.ADDON_MINIMAP_BUTTONS) do
    local button = _G[name]
    -- With its original in charge, this is the original's own button.
    if button and button.Hide and not Kit.OriginTakesPrecedence("KittyCombo") then
      pcall(button.Hide, button)
    end
  end
end

-- Window size: the Size button scales the hub (left click bigger, right click smaller),
-- for small UI scales or high resolutions. Saved in CherrysKit_DB.scale (0.6 to 1.6).
function Kit.SetScale(scale)
  scale = math.max(0.6, math.min(1.6, tonumber(scale) or 1))
  scale = math.floor(scale * 10 + 0.5) / 10
  db().scale = scale
  if CherrysKit_Frame and CherrysKit_Frame.SetScale then
    pcall(CherrysKit_Frame.SetScale, CherrysKit_Frame, scale)
  end
  return scale
end

-- - and + buttons: one 10% step
function Kit.SizeStep(dir)
  Kit.SetScale((tonumber(db().scale) or 1) + (dir < 0 and -0.1 or 0.1))
end

-- Bottom right grip: drag right for bigger, left for smaller, 10% per 25 cursor pixels
-- (sideways only, as in KittyCombo: the client's cursor y may count either way).
Kit.PIXELS_PER_STEP = 25

function Kit.DragScale(start, dx)
  local steps = dx / Kit.PIXELS_PER_STEP
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

function Kit.GripStart()
  local x = cursorX()
  if x then
    Kit.drag = { x = x, scale = tonumber(db().scale) or 1 }
  end
end

function Kit.GripUpdate()
  local drag, x = Kit.drag, cursorX()
  if not drag or not x then
    return
  end
  local scale = Kit.DragScale(drag.scale, x - drag.x)
  if math.abs(scale - (tonumber(db().scale) or 1)) > 0.001 then
    Kit.SetScale(scale)
    if CherrysKit_Grip then
      Kit.SizeTooltip(CherrysKit_Grip)
    end
  end
end

function Kit.GripStop()
  Kit.drag = nil
end

function Kit.GripHover(grip, on)
  if CherrysKit_GripTexture and CherrysKit_GripTexture.SetTexture then
    pcall(CherrysKit_GripTexture.SetTexture, CherrysKit_GripTexture, "Interface/AddOns/CherrysKit/Media/" .. (on and "grip_hl" or "grip"))
  end
  if on then
    Kit.SizeTooltip(grip)
  elseif GameTooltip then
    GameTooltip:Hide()
  end
end

function Kit.SizeTooltip(owner)
  if not GameTooltip then
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT", 0, 0)
  GameTooltip:SetText("Window size")
  GameTooltip:AddLine("Drag this corner right for bigger, left for smaller, or use - and + at the top.", 1, 1, 1)
  GameTooltip:AddLine("Now " .. math.floor((tonumber(db().scale) or 1) * 100 + 0.5) .. "%", 1, 1, 1)
  GameTooltip:Show()
end

function Kit.MinimapTooltip(owner)
  if not GameTooltip then
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT", 0, 0)
  GameTooltip:SetText("Cherry's Kit")
  GameTooltip:AddLine("Click: every addon of the kit (/rwa, /ck)", 1, 1, 1)
  if UI_MINIMAPBUTTON_MOVE then
    GameTooltip:AddLine(UI_MINIMAPBUTTON_MOVE, 0, 0.75, 0.95)
  end
  GameTooltip:Show()
end

-- Once per session, one line for each: which kit addons are off, and what took precedence.
function Kit.WarnOrigins()
  if Kit.warnedOld then
    return
  end
  Kit.warnedOld = true
  local folders = {}
  for folder in pairs(Kit.ORIGINS) do
    if Kit.OriginTakesPrecedence(folder) then
      table.insert(folders, folder)
    end
  end
  table.sort(folders)
  for _, folder in ipairs(folders) do
    local origin = Kit.ORIGINS[folder]
    print(origin.title .. " from the kit is off: " .. originWords(origin) .. " takes precedence. "
      .. "To use the kit's version, delete that folder and Reload UI.")
  end
end

function Kit.OnEvent(event)
  if event == "VARIABLES_LOADED" or event == "LOADING_END" then
    Kit.SetScale(db().scale or 1)
    Kit.ApplyCommands()
    Kit.Refresh()
    -- KittyCombo shows its button on VARIABLES_LOADED after us, so LOADING_END hides it again.
    Kit.HideAddonMinimapButtons()
    if event == "LOADING_END" then
      Kit.WarnOrigins()
    end
  end
end

---------------------------------------------------------------------------
-- Chat commands from Commands.lua. A command another addon already owns is wrapped:
-- typed alone it opens the chosen window, with extra words it goes to its owner as before.
---------------------------------------------------------------------------

Kit.DEFAULT_COMMANDS = { KittyCombo = "/kc /kitty", RomWeakAuras = "/wa", CherrysChat = "/cchat", zBag = "/zb", ExtendedMacroIcons = "/emi", TooltipIds = "/ti", UltimateMailMod = "/umm", GlobalBank = "/gb", AdvancedAuctionHouse = "/aah", CherrysLoadTimes = "/ckload", ZShop = "/zshop", pbInfo = "/pbinfo", PortraitHP = "/php", CherrysGrid = "/grid", CherrysQuests = "/cq", CherrysBar = "/cbar", ControlHub = "/rwa /ck" }
Kit.WINDOWS = { "KittyCombo", "RomWeakAuras", "CherrysChat", "zBag", "ExtendedMacroIcons", "TooltipIds", "UltimateMailMod", "GlobalBank", "AdvancedAuctionHouse", "CherrysLoadTimes", "ZShop", "pbInfo", "PortraitHP", "CherrysGrid", "CherrysQuests", "CherrysBar", "ControlHub" }
Kit.WINDOW_TITLES = {
  KittyCombo = "Cherry's KittyCombo",
  RomWeakAuras = "rom weakauras",
  CherrysChat = "Cherry's Chat",
  zBag = "zBag",
  ExtendedMacroIcons = "Extended Macro Icons",
  TooltipIds = "TooltipIds",
  UltimateMailMod = "Ultimate Mail Mod",
  GlobalBank = "Global Bank",
  AdvancedAuctionHouse = "Advanced AuctionHouse",
  CherrysLoadTimes = "Cherry's Addon LoadTimes",
  ZShop = "ZShop",
  pbInfo = "pbInfo",
  PortraitHP = "PortraitHP",
  CherrysGrid = "Cherry's Grid",
  CherrysQuests = "Cherry's Quests",
  CherrysBar = "Cherry's Bar",
  ControlHub = "Control hub",
}

local function entryFor(folder)
  for _, entry in ipairs(Kit.addons) do
    if entry.folder == folder then
      return entry
    end
  end
end

function Kit.OpenWindow(window)
  if window == "ControlHub" then
    Kit.Toggle()
    return true
  end
  local entry = entryFor(window)
  if not entry or not installed(entry) then
    print((Kit.WINDOW_TITLES[window] or tostring(window)) .. " is not installed")
  elseif Kit.OriginTakesPrecedence(window) then
    print(entry.title .. " from the kit is off: " .. originWords(Kit.ORIGINS[window]) .. " takes precedence.")
  elseif not Kit.IsEnabled(window) then
    print(entry.title .. " is turned off. Turn it on here and Reload UI.")
    Kit.Toggle()
  else
    return openEntry(entry, "command")
  end
  return false
end

function Kit.CommandsFor(window)
  local config = type(CherrysKit_Commands) == "table" and CherrysKit_Commands or Kit.DEFAULT_COMMANDS
  local list = {}
  for cmd in string.gmatch(tostring(config[window] or Kit.DEFAULT_COMMANDS[window] or ""), "%S+") do
    if string.sub(cmd, 1, 1) ~= "/" then
      cmd = "/" .. cmd
    end
    list[#list + 1] = string.lower(cmd)
  end
  return list
end

-- Which SlashCmdList key already answers each command.
local function slashOwners()
  local owners = {}
  for key in pairs(SlashCmdList) do
    for n = 1, 20 do
      local cmd = _G["SLASH_" .. key .. n]
      if type(cmd) == "string" then
        owners[string.lower(cmd)] = owners[string.lower(cmd)] or key
      end
    end
  end
  return owners
end

local wrapped = {}
local applied = false

-- Reload UI re-runs the files in the same Lua state: take back what the last session set up
-- (its own commands and its wrappers around other addons' commands) before setting it up again.
local function undoLastSession()
  for key in pairs(SlashCmdList) do
    if string.find(key, "^CherrysKit_") then
      SlashCmdList[key] = nil
      for n = 1, 20 do
        _G["SLASH_" .. key .. n] = nil
      end
    end
  end
  for owner, w in pairs(Kit.slashWrappers or {}) do
    if SlashCmdList[owner] == w.wrapper then
      SlashCmdList[owner] = w.original
    end
  end
  Kit.slashWrappers = {}
end

function Kit.ApplyCommands()
  if applied then
    return
  end
  applied = true
  undoLastSession()
  local owners = slashOwners()
  for _, window in ipairs(Kit.WINDOWS) do
    local own = {}
    -- With its original in charge, the commands stay the original's.
    for _, cmd in ipairs(Kit.OriginTakesPrecedence(window) and {} or Kit.CommandsFor(window)) do
      local owner = owners[cmd]
      if owner and string.find(owner, "^CherrysKit") == nil then
        if not wrapped[owner] then
          local original = SlashCmdList[owner]
          wrapped[owner] = { original = original }
          SlashCmdList[owner] = function(editBox, msg)
            local text = type(editBox) == "string" and editBox or msg
            if (text == nil or string.find(text, "^%s*$")) and wrapped[owner].default then
              Kit.OpenWindow(wrapped[owner].default)
              return
            end
            return original(editBox, msg)
          end
          Kit.slashWrappers[owner] = { original = original, wrapper = SlashCmdList[owner] }
        end
        -- The client does not say which alias was typed, so the first window claiming an owner wins.
        wrapped[owner].default = wrapped[owner].default or window
      elseif not owner then
        own[#own + 1] = cmd
        owners[cmd] = "CherrysKit_" .. window
      end
    end
    if window == "ControlHub" then
      table.insert(own, "/cherryskit")
    end
    local key = "CherrysKit_" .. window
    for i, cmd in ipairs(own) do
      _G["SLASH_" .. key .. i] = cmd
    end
    if #own > 0 then
      SlashCmdList[key] = function()
        Kit.OpenWindow(window)
      end
    end
  end
end

-- tests: what a Reload UI does to the commands
function Kit.ReapplyCommandsForTest()
  applied = false
  wrapped = {}
  Kit.ApplyCommands()
end

function Kit.CommandText(window)
  local list = Kit.CommandsFor(window)
  return #list > 0 and table.concat(list, " ") or "no command"
end

SlashCmdList = SlashCmdList or {}
