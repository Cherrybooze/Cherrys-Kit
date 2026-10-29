-- Extended Macro Icons: the game's macro window, with thousands more icons to choose from.
-- Original addon by Amurilon (2.15, 2018). Cleaned up for Cherry's Kit by Cherry.
--
-- How it works: a macro stores its icon as a number, and the game only knows its own icons
-- (1 to GetNumMacroIcons()). Extra icons get numbers no stock icon uses: a category code from
-- Categories.lua followed by the icon's place in that category's list (10000 and 12 make 1000012).
-- GetMacroIconInfo and GetActionInfo are wrapped so those numbers become pictures again, in this
-- window, on the action bars and in any other addon that asks.

CherrysEMI = CherrysEMI or {}
local EMI = CherrysEMI

EMI.version = "3.0.4"
EMI.MAX_MACROS = 56
EMI.MACRO_COLUMNS = 7
EMI.ICON_COLUMNS = 9
EMI.ICON_ROWS = 5
EMI.ICONS_SHOWN = EMI.ICON_COLUMNS * EMI.ICON_ROWS
EMI.CUSTOM_CODE = 90000
EMI.DEFAULT_ICON_PATH = "interface/icons/icon-default"

EMI.categories = EMI.categories or {}
EMI.byCode = EMI.byCode or {}
-- The game's own functions we wrap, kept in a global that survives the addon's files being run
-- again (Reload UI), so a wrapper is never wrapped twice and never loses the function it calls.
CherrysEMI_Hooks = CherrysEMI_Hooks or {}
EMI.original = setmetatable({}, { __index = function(_, name)
  local hook = CherrysEMI_Hooks[name]
  return hook and hook.original
end })
EMI.active = false
EMI.started = false

-- The icon picker: which category it shows and which icon is ticked (not saved until Save).
local picker = { category = 1, icon = nil }

local function print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7fa8Extended Macro Icons|r: " .. tostring(msg))
  end
end
EMI.Print = print

function EMI.BasePath()
  return (CherrysKit_Paths and CherrysKit_Paths.ExtendedMacroIcons) or "Interface/AddOns/ExtendedMacroIcons/"
end

function EMI.IsOffInKit()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("ExtendedMacroIcons")
end

---------------------------------------------------------------------------
-- Icon lists and icon numbers
---------------------------------------------------------------------------

-- A category's list file is read the first time something asks for category.paths (the icon
-- picker, or a macro using one of its icons), not at login: the lists are 500 KB together.
local lazyPaths = {
  __index = function(category, key)
    if key ~= "paths" then
      return nil
    end
    local fn, err = loadfile(EMI.BasePath() .. "icons/" .. category.file)
    local ok, list = false, err
    if fn then
      ok, list = pcall(fn)
    end
    if not (ok and type(list) == "table") then
      print("could not load icons/" .. category.file .. ": " .. tostring(list))
      list = {}
    end
    rawset(category, "paths", list)
    return list
  end,
}

function EMI.LoadIcons()
  EMI.categories = { { name = "Default Icons" } }
  EMI.byCode = {}
  for _, line in ipairs(EMI.CATEGORIES or {}) do
    local code, name, file = line[1], line[2], line[3]
    local category = setmetatable({ name = name, code = code, file = file, custom = tonumber(code) >= EMI.CUSTOM_CODE }, lazyPaths)
    table.insert(EMI.categories, category)
    EMI.byCode[code] = category
  end
end

-- Number of the game's own icons. Never wrapped, so other addons always get the real count.
function EMI.StockCount()
  return tonumber(GetNumMacroIcons and GetNumMacroIcons()) or 0
end

function EMI.Count(cat)
  local category = EMI.categories[cat]
  if not category or not category.code then
    return EMI.StockCount()
  end
  return #category.paths
end

function EMI.IconNumber(cat, index)
  local category = EMI.categories[cat]
  if not category or not category.code then
    return index
  end
  return tonumber(category.code .. index)
end

-- Category number and place in it for an icon number; nil, nil for a stock or unknown icon.
function EMI.Decode(icon)
  icon = tonumber(icon)
  if not icon or icon <= EMI.StockCount() then
    return nil, nil
  end
  local text = string.format("%d", icon)
  local category = EMI.byCode[string.sub(text, 1, 5)]
  local index = tonumber(string.sub(text, 6))
  if not category or not index or not category.paths[index] then
    return nil, nil
  end
  for cat, c in ipairs(EMI.categories) do
    if c == category then
      return cat, index
    end
  end
  return nil, nil
end

function EMI.IsExtended(icon)
  icon = tonumber(icon)
  return icon ~= nil and icon > EMI.StockCount()
end

-- Picture for an extended icon number. Unknown numbers get the first stock icon, as before.
function EMI.ExtendedTexture(icon)
  local cat, index = EMI.Decode(icon)
  if not cat then
    local stock = EMI.original.GetMacroIconInfo
    return stock and stock(1) or nil
  end
  local category = EMI.categories[cat]
  local path = category.paths[index]
  if not category.custom then
    return "Interface/" .. path
  end
  if string.find(string.lower(path), "^interface[/\\]") then
    return path
  end
  return EMI.BasePath() .. path
end

-- Icon number of the macro called name, if it uses an extended icon.
-- The name-to-icon map is rebuilt when the macro list changes, not on every lookup.
local macroIconCache = nil
function EMI.MacroIconByName(name)
  if macroIconCache == nil then
    macroIconCache = {}
    for i = 1, EMI.MAX_MACROS do
      local icon, macroName = GetMacroInfo(i)
      if macroName and macroName ~= "" and EMI.IsExtended(icon) then
        macroIconCache[macroName] = icon
      end
    end
  end
  return macroIconCache[name]
end

-- A macro with an extended icon comes back from the game with the default icon; swap in ours.
local function fixActionIcon(path, name, ...)
  if name and name ~= "" and type(path) == "string"
      and string.lower(string.gsub(path, "\\", "/")) == EMI.DEFAULT_ICON_PATH then
    local icon = EMI.MacroIconByName(name)
    if icon then
      path = EMI.ExtendedTexture(icon)
    end
  end
  return path, name, ...
end

-- Replaces the global function name with make(original). Does nothing when the function is
-- missing, and keeps the existing wrapper when it is already ours (files run again on Reload UI).
local function hook(name, make)
  local current = _G[name]
  local entry = CherrysEMI_Hooks[name]
  if type(current) ~= "function" or (entry and entry.wrapper == current) then
    return
  end
  entry = { original = current }
  entry.wrapper = make(current)
  CherrysEMI_Hooks[name] = entry
  _G[name] = entry.wrapper
end

function EMI.InstallHooks()
  hook("GetMacroIconInfo", function(original)
    return function(icon, ...)
      if EMI.IsExtended(icon) then
        return EMI.ExtendedTexture(icon)
      end
      return original(icon, ...)
    end
  end)
  hook("GetActionInfo", function(original)
    return function(...)
      return fixActionIcon(original(...))
    end
  end)
end

function EMI.HooksOn()
  local entry = CherrysEMI_Hooks.GetMacroIconInfo
  return entry ~= nil and GetMacroIconInfo == entry.wrapper
end

-- Gives the game its own functions (and macro window) back. Used when the kit keeps this
-- addon off: Reload UI re-runs this file in the same Lua state, so last session's wrappers
-- would otherwise stay installed.
function EMI.RestoreHooks()
  for name, entry in pairs(CherrysEMI_Hooks) do
    if entry.original and _G[name] == entry.wrapper then
      _G[name] = entry.original
    end
  end
  CherrysEMI_Hooks = {}
  macroIconCache = nil
  if MacroFrame == CEMI_MacroFrame and EMI.originalMacroFrame then
    MacroFrame = EMI.originalMacroFrame
    EMI.originalMacroFrame = nil
  end
end

---------------------------------------------------------------------------
-- Macro window
---------------------------------------------------------------------------

local function child(name)
  return getglobal(name)
end

function EMI.MacroFrame_OnLoad(this)
  UIPanelFrame_Initialize(this, nil, nil)
  CEMI_MacroFrameTitleText:SetText("Extended Macro Icons")
  for i = 1, EMI.MAX_MACROS do
    local button = child("CEMI_MacroButton" .. i)
    button:ClearAllAnchors()
    if i == 1 then
      button:SetAnchor("TOPLEFT", "TOPLEFT", this:GetName(), 32, 46)
    elseif i <= EMI.MACRO_COLUMNS then
      button:SetAnchor("LEFT", "RIGHT", "CEMI_MacroButton" .. (i - 1), 4, 0)
    else
      button:SetAnchor("TOPLEFT", "BOTTOMLEFT", "CEMI_MacroButton" .. (i - EMI.MACRO_COLUMNS), 0, 6)
    end
  end
  this.selectedMacro = 1
  this:RegisterEvent("MACROFRAME_UPDATE")
end

function EMI.SelectedMacro()
  return CEMI_MacroFrame.selectedMacro or 1
end

function EMI.UpdateMacros()
  macroIconCache = nil
  for i = 1, EMI.MAX_MACROS do
    local button = child("CEMI_MacroButton" .. i)
    local label = child("CEMI_MacroButton" .. i .. "Name")
    local picture = child("CEMI_MacroButton" .. i .. "Icon")
    button:SetID(i)
    if HasMacro(i) then
      local icon, name = GetMacroInfo(i)
      label:SetText(name or "")
      picture:SetTexture(GetMacroIconInfo(icon))
    else
      label:SetText("")
      picture:SetTexture("")
    end
    button:SetChecked(i == EMI.SelectedMacro())
  end
  if HasMacro(EMI.SelectedMacro()) then
    CEMI_MacroEditButton:SetText(TEXT("MACRO_MODIFY"))
    CEMI_MacroResetButton:Enable()
  else
    CEMI_MacroEditButton:SetText(TEXT("MACRO_CREATE"))
    CEMI_MacroResetButton:Disable()
  end
end

function EMI.MacroButton_OnClick(this)
  if CEMI_MacroPopupFrame:IsVisible() then
    return
  end
  if CursorItemType() == "macro" then
    PickupMacroItem(this:GetID())
    return
  end
  CEMI_MacroFrame.selectedMacro = this:GetID()
  EMI.UpdateMacros()
end

function EMI.MacroButton_OnEnter(this)
  local _, name = GetMacroInfo(this:GetID())
  if HasMacro(this:GetID()) and name and name ~= "" then
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 0, 0)
    GameTooltip:SetText(name)
    GameTooltip:Show()
  end
end

function EMI.Toggle()
  if CEMI_MacroFrame:IsVisible() then
    HideUIPanel(CEMI_MacroFrame)
  else
    ShowUIPanel(CEMI_MacroFrame)
  end
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["CEMI_MACRO_RESET_CONFIRM"] = {
  text = TEXT and TEXT("MACRO_RESET_CONFIRM") or "Delete this macro?",
  button1 = TEXT and TEXT("OKAY") or "OK",
  button2 = TEXT and TEXT("CANCEL") or "Cancel",
  OnAccept = function()
    EditMacro(EMI.SelectedMacro())
    EMI.UpdateMacros()
  end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

---------------------------------------------------------------------------
-- Edit window (name, icon, text)
---------------------------------------------------------------------------

function EMI.EditPopup_OnLoad()
  CEMI_MacroPopupFrameTitleText:SetText(MACRO_CONTENT)
  -- The client's label says 255 letters; the edit box takes 767.
  local text = string.gsub(tostring(MACRO_CONTENT_LENGTH or ""), "%d+", "767", 1)
  CEMI_MacroPopupFrameContent:SetText(text)
end

function EMI.SetEditIcon(icon)
  CEMI_MacroPopupFrame.selectedIcon = icon
  CEMI_MacroPopupIconButtonIcon:SetTexture(GetMacroIconInfo(icon))
  if icon then
    CEMI_MacroPopupSaveButton:Enable()
  else
    CEMI_MacroPopupSaveButton:Disable()
  end
end

function EMI.EditPopup_OnShow()
  local icon, name, body = GetMacroInfo(EMI.SelectedMacro())
  EMI.SetEditIcon(icon or 1)
  CEMI_MacroPopupNameEdit:SetText(name or "")
  CEMI_MacroPopupBodyEdit:SetText(body or "")
end

function EMI.SaveMacro()
  EditMacro(EMI.SelectedMacro(), CEMI_MacroPopupNameEdit:GetText(), CEMI_MacroPopupFrame.selectedIcon,
    CEMI_MacroPopupBodyEdit:GetText())
  CEMI_MacroPopupFrame:Hide()
  EMI.UpdateMacros()
end

-- "Item" button: link of the item in the first backpack slot, at the cursor.
function EMI.InsertItemLink()
  local slot = GetBagItemInfo(1)
  local link = slot and GetBagItemLink(slot)
  if link and link ~= "" then
    CEMI_MacroPopupBodyEdit:InsertText(link)
  else
    print("put the item in the first backpack slot first")
  end
end

function EMI.InsertNameLink()
  local name = CEMI_MacroPopupNameFrameEdit:GetText()
  if name and name ~= "" then
    CEMI_MacroPopupBodyEdit:InsertText("|Hplayer:" .. name .. "|h[" .. name .. "]|h")
  end
  CEMI_MacroPopupNameFrame:Hide()
end

---------------------------------------------------------------------------
-- Icon picker
---------------------------------------------------------------------------

function EMI.Picker_OnLoad(this)
  for i = 1, EMI.ICONS_SHOWN do
    local button = child("CEMI_MacroPopupIconButton" .. i)
    button:ClearAllAnchors()
    if i == 1 then
      button:SetAnchor("TOPLEFT", "TOPLEFT", "CEMI_MacroPopupSelectIconFrame", 8, 12)
    elseif (i - 1) % EMI.ICON_COLUMNS == 0 then
      button:SetAnchor("TOPLEFT", "BOTTOMLEFT", "CEMI_MacroPopupIconButton" .. (i - EMI.ICON_COLUMNS), 0, 2)
    else
      button:SetAnchor("TOPLEFT", "TOPRIGHT", "CEMI_MacroPopupIconButton" .. (i - 1), 2, 0)
    end
  end
  local gfx = EMI.BasePath() .. "gfx/"
  CEMI_MacroPopupIconFrameBorder:SetTexture(gfx .. "macropopupiconframe-border")
  CEMI_CatFrameButtonLeftArrow:SetTexture(gfx .. "arrowleft.png")
  CEMI_CatFrameButtonRightArrow:SetTexture(gfx .. "arrowright.png")
end

local function maxRow(cat)
  local rows = math.ceil(EMI.Count(cat) / EMI.ICON_COLUMNS)
  return math.max(0, rows - EMI.ICON_ROWS)
end

-- Shows a category, scrolled so the icon at index is visible.
function EMI.ShowCategory(cat, index)
  local count = #EMI.categories
  if cat < 1 then
    cat = count
  elseif cat > count then
    cat = 1
  end
  picker.category = cat
  CEMI_CatFrameButtonDropdownText:SetText(EMI.categories[cat].name .. "  (" .. cat .. "/" .. count .. ")")
  local row = 0
  if index then
    row = math.floor((index - 1) / EMI.ICON_COLUMNS) - (EMI.ICON_ROWS - 1)
  end
  CEMI_MacroPopupIconScrollBar:SetMaxValue(maxRow(cat))
  CEMI_MacroPopupIconScrollBar:SetValue(math.max(0, math.min(row, maxRow(cat))))
  EMI.UpdatePicker()
end

function EMI.Picker_OnShow()
  picker.icon = CEMI_MacroPopupFrame.selectedIcon or 1
  local cat, index = EMI.Decode(picker.icon)
  if cat then
    EMI.ShowCategory(cat, index)
  else
    EMI.ShowCategory(1, tonumber(picker.icon))
  end
end

function EMI.UpdatePicker()
  local cat = picker.category
  local count = EMI.Count(cat)
  local first = math.floor(CEMI_MacroPopupIconScrollBar:GetValue() or 0) * EMI.ICON_COLUMNS
  for i = 1, EMI.ICONS_SHOWN do
    local button = child("CEMI_MacroPopupIconButton" .. i)
    local index = first + i
    if index <= count then
      local icon = EMI.IconNumber(cat, index)
      local path = GetMacroIconInfo(icon)
      child("CEMI_MacroPopupIconButton" .. i .. "Icon"):SetTexture(path)
      button.icon = icon
      button.path = path
      button:SetChecked(icon == picker.icon)
      button:Show()
    else
      button.icon = nil
      button:Hide()
    end
  end
end

function EMI.PickerScroll_OnValueChanged(this, value)
  UIPanelScrollBar_OnValueChanged(this, value)
  EMI.UpdatePicker()
end

function EMI.PickerIcon_OnClick(this)
  picker.icon = this.icon
  EMI.UpdatePicker()
end

-- Shift + hover shows the picture's file path.
function EMI.PickerIcon_OnEnter(this)
  if IsShiftKeyDown() and this.path then
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", 0, 0)
    GameTooltip:SetText(this.path)
    GameTooltip:Show()
  end
end

function EMI.PickerOkay()
  EMI.SetEditIcon(picker.icon)
  CEMI_MacroPopupIconFrame:Hide()
end

function EMI.StepCategory(step)
  EMI.ShowCategory(picker.category + step)
end

-- Category name: left click or wheel down = next, right click or wheel up = previous.
function EMI.CategoryLabel_OnClick(key)
  EMI.StepCategory(key == "RBUTTON" and -1 or 1)
end

function EMI.CategoryLabel_OnMouseWheel(delta)
  EMI.StepCategory((delta or 0) > 0 and -1 or 1)
end

---------------------------------------------------------------------------
-- Start up, chat command, Cherry's Kit
---------------------------------------------------------------------------

function EMI.Start()
  if EMI.started then
    return
  end
  EMI.started = true
  if EMI.IsOffInKit() then
    EMI.RestoreHooks()
    return
  end
  -- The old 2.15 folder still installed: it swaps the same functions and the macro window, so
  -- running both would fight. Let the old one run and say how to fix it.
  if EMI.OldVersionLoaded() then
    print("the old ExtendedMacroIcons 2.15 is still installed, so this version stays off. Delete the folder "
      .. "Interface\\AddOns\\ExtendedMacroIcons and Reload UI.")
    return
  end
  EMI.active = true
  EMI.LoadIcons()
  EMI.InstallHooks()
  -- The game's macro button and key open this window instead of the stock one.
  if MacroFrame ~= CEMI_MacroFrame then
    EMI.originalMacroFrame = MacroFrame
  end
  MacroFrame = CEMI_MacroFrame
  UIPanelWindows = UIPanelWindows or {}
  UIPanelWindows["CEMI_MacroFrame"] = { area = "left", layer = 0, setAnchor = 1 }
end

function EMI.OldVersionLoaded()
  return type(ExtendedMacroIcons) == "table" and type(ExtendedMacroIcons.func) == "table"
end

function EMI.OnEvent(event)
  if event == "VARIABLES_LOADED" then
    EMI.Start()
  end
end

-- /emi probe: prints what this client does with the things the addon assumes but nobody has
-- checked in game yet. Copy the lines (Cherry's Chat copy window) and send them to Cherry.
local function has(obj, method)
  return obj ~= nil and type(obj[method]) == "function" and "yes" or "NO"
end

function EMI.Probe()
  local lines = {}
  local function add(text)
    lines[#lines + 1] = text
    print("probe " .. text)
  end
  add("version " .. EMI.version .. ", active " .. tostring(EMI.active) .. ", folder " .. EMI.BasePath())
  add("old 2.15 folder loaded: " .. (EMI.OldVersionLoaded() and "YES (delete Interface\\AddOns\\ExtendedMacroIcons)" or "no"))
  local stock = EMI.StockCount()
  add("stock icons " .. stock .. (stock >= 10000 and " (TOO MANY: extra icon numbers could clash)" or " (ok)"))
  add("stock icon 1 = " .. tostring(EMI.original.GetMacroIconInfo and EMI.original.GetMacroIconInfo(1) or GetMacroIconInfo(1)))
  local loaded, icons, empty = 0, 0, {}
  for _, c in ipairs(EMI.categories) do
    if c.code then
      loaded = loaded + 1
      icons = icons + #c.paths
      if #c.paths == 0 then
        empty[#empty + 1] = c.name
      end
    end
  end
  add("categories loaded " .. loaded .. " of " .. #(EMI.CATEGORIES or {}) .. ", extra icons " .. icons
    .. (#empty > 0 and (", EMPTY: " .. table.concat(empty, ", ")) or ""))
  add("sample pictures: " .. tostring(GetMacroIconInfo(1000001)) .. " | " .. tostring(GetMacroIconInfo(900001)))
  add("hooks " .. (EMI.HooksOn() and "on" or "off") .. ", GetActionInfo hooked "
    .. tostring(CherrysEMI_Hooks.GetActionInfo ~= nil and GetActionInfo == CherrysEMI_Hooks.GetActionInfo.wrapper) .. ", macro window replaced "
    .. tostring(MacroFrame == CEMI_MacroFrame))
  -- Macros saved with an extra icon: proves the server keeps big icon numbers.
  local saved, extended = 0, {}
  for i = 1, EMI.MAX_MACROS do
    if HasMacro(i) then
      saved = saved + 1
      local icon, name = GetMacroInfo(i)
      if EMI.IsExtended(icon) then
        extended[#extended + 1] = tostring(name) .. "=" .. tostring(icon)
      end
    end
  end
  add("macros " .. saved .. ", with extra icons " .. #extended
    .. (#extended > 0 and (": " .. table.concat(extended, ", ", 1, math.min(#extended, 5))) or ""))
  -- What the action bar gets for macros: the raw path tells whether the default icon check matches.
  local raw = EMI.original.GetActionInfo or GetActionInfo
  local seen = 0
  for slot = 1, 80 do
    local ok, path, name = pcall(raw, slot)
    if ok and name and name ~= "" and type(path) == "string" and string.find(string.lower(path), "default") then
      add("action " .. slot .. " '" .. name .. "' raw " .. path .. " -> shown " .. tostring((GetActionInfo(slot))))
      seen = seen + 1
      if seen >= 3 then
        break
      end
    end
  end
  if seen == 0 then
    add("no action bar slot with a default icon (put a macro with an extra icon on the bar and probe again)")
  end
  add("Button:RegisterForClicks " .. has(CEMI_CatFrameButtonDropdown, "RegisterForClicks")
    .. ", EditBox:InsertText " .. has(CEMI_MacroPopupBodyEdit, "InsertText")
    .. ", Slider:SetValueStepMode " .. has(CEMI_MacroPopupIconScrollBar, "SetValueStepMode")
    .. ", CheckButton:SetChecked " .. has(CEMI_MacroButton1, "SetChecked"))
  local ok, slot = pcall(GetBagItemInfo, 1)
  add("GetBagItemInfo(1) = " .. tostring(ok and slot or ("error " .. tostring(slot))))
  add("arrow pictures: " .. EMI.BasePath() .. "gfx/arrowleft.png (look: are the < > arrows above the icons visible?)")
  return lines
end

function EMI.Slash(msg)
  msg = string.lower(tostring(msg or ""))
  if string.find(msg, "^%s*probe") then
    EMI.Probe()
    return
  end
  if not EMI.active then
    print("turned off in Cherry's Kit. Type /ck to turn it on, then Reload UI.")
    return
  end
  EMI.Toggle()
end

SlashCmdList = SlashCmdList or {}
SLASH_ExtendedMacroIcons1 = "/emi"
SlashCmdList["ExtendedMacroIcons"] = function(editBox, msg)
  EMI.Slash(type(editBox) == "string" and editBox or msg)
end

if CherrysKit and CherrysKit.Register then
  CherrysKit.Register({
    folder = "ExtendedMacroIcons",
    title = "Extended Macro Icons",
    version = EMI.version,
    installed = function()
      return true
    end,
    open = function()
      EMI.Slash("")
      return true
    end,
  })
end
