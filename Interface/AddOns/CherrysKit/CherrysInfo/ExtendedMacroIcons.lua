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

EMI.version = "3.1.1"
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
  return (CherrysKit_Paths and (CherrysKit_Paths.CherrysInfo or CherrysKit_Paths.ExtendedMacroIcons)) or "Interface/AddOns/CherrysKit/CherrysInfo/"
end

function EMI.IsOffInKit()
  return CherrysKit ~= nil and CherrysKit.IsEnabled ~= nil and not CherrysKit.IsEnabled("CherrysInfo")
end

-- Its tick in /cinfo. The hooks and the macro window only change at load, so this applies after Reload UI.
if SaveVariables then
  SaveVariables("CherrysEMI_DB")
end

function EMI.IsSwitchedOff()
  return type(CherrysEMI_DB) == "table" and CherrysEMI_DB.off == true
end

function EMI.SetEnabled(on)
  if type(CherrysEMI_DB) ~= "table" then
    CherrysEMI_DB = {}
  end
  CherrysEMI_DB.off = (not on) or nil
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
  EMI.DrawImportTarget()
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
  CEMI_MacroImportFrame:Hide()
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
-- Import window: macros from Global Bank's library, searched by name and group
---------------------------------------------------------------------------

-- Global Bank's helper or page writes this file, so it can change while the game runs. It's read when the window
-- opens and let go when it closes, so a big library costs nothing the rest of the time.
EMI.IMPORT_FILE = "Interface/GlobalBankHelper/GlobalBankMacros.lua"
EMI.IMPORT_ROWS = 8

local import = { macros = {}, groups = {}, shown = {}, group = 0, search = "", offset = 0, selected = nil, loaded = false }

local function importLower(text)
  return string.lower(tostring(text or ""))
end

-- A macro's own text, shown as it's written instead of as the colours and links it may hold.
local function shownText(text)
  return (string.gsub(text, "|", "||"))
end

local function macroLabel(macro)
  if macro.name ~= "" then
    return macro.name
  end
  return string.sub((string.gsub(macro.text, "%s+", " ")), 1, 40)
end

function EMI.LoadLibrary()
  CherrysEMI_MacroLibrary = nil
  local ok = pcall(dofile, EMI.IMPORT_FILE)
  local library = CherrysEMI_MacroLibrary
  CherrysEMI_MacroLibrary = nil
  import.macros, import.groups, import.selected = {}, {}, nil
  import.loaded = ok and type(library) == "table" and type(library.macros) == "table"
  if not import.loaded then
    return false
  end
  local used = {}
  for _, entry in ipairs(library.macros) do
    if type(entry) == "table" and (entry.n or entry.t) then
      local macro = { name = tostring(entry.n or ""), icon = tonumber(entry.i) or 1, text = tostring(entry.t or ""), inGroup = {}, groupText = "" }
      if type(entry.g) == "table" then
        for _, group in ipairs(entry.g) do
          macro.inGroup[group] = true
          used[group] = true
        end
        macro.groupText = table.concat(entry.g, ", ")
      end
      macro.findName = importLower(macro.name .. "\n" .. macro.groupText)
      macro.findText = importLower(macro.text)
      table.insert(import.macros, macro)
    end
  end
  -- Only groups that hold something, in the order the page keeps them
  for _, group in ipairs(type(library.groups) == "table" and library.groups or {}) do
    if used[group] then
      table.insert(import.groups, group)
      used[group] = nil
    end
  end
  for group in pairs(used) do
    table.insert(import.groups, group)
  end
  if import.group > #import.groups then
    import.group = 0
  end
  return true
end

-- Every word of the search has to be found. Macros it finds by name or group come first, then those it finds in their text.
function EMI.FilterImport()
  local words = {}
  for word in string.gmatch(importLower(import.search), "%S+") do
    table.insert(words, word)
  end
  local group = import.groups[import.group]
  local byName, byText = {}, {}
  for _, macro in ipairs(import.macros) do
    if not group or macro.inGroup[group] then
      local inName, inEither = true, true
      for _, word in ipairs(words) do
        local name = string.find(macro.findName, word, 1, true)
        inName = inName and name ~= nil
        inEither = inEither and (name ~= nil or string.find(macro.findText, word, 1, true) ~= nil)
      end
      if inName then
        table.insert(byName, macro)
      elseif inEither then
        table.insert(byText, macro)
      end
    end
  end
  for _, macro in ipairs(byText) do
    table.insert(byName, macro)
  end
  import.shown = byName
  import.offset = 0
  local stillThere = false
  for _, macro in ipairs(byName) do
    stillThere = stillThere or macro == import.selected
  end
  if not stillThere then
    import.selected = byName[1]
  end
end

local function setImportBar(max, value)
  local bar = CEMI_MacroImportScroll
  if max <= 0 then
    bar:Hide()
    return
  end
  if bar.SetMaxValue then
    bar:SetMaxValue(max)
  elseif bar.SetMinMaxValues then
    bar:SetMinMaxValues(0, max)
  end
  bar:SetValue(value)
  bar:Show()
end

local drawingImport = false
function EMI.DrawImport()
  drawingImport = true
  local max = math.max(0, #import.shown - EMI.IMPORT_ROWS)
  import.offset = math.max(0, math.min(import.offset, max))
  setImportBar(max, import.offset)
  drawingImport = false
  for i = 1, EMI.IMPORT_ROWS do
    local row = child("CEMI_MacroImportRow" .. i)
    local macro = import.shown[import.offset + i]
    row.macro = macro
    if macro then
      child("CEMI_MacroImportRow" .. i .. "Icon"):SetTexture(GetMacroIconInfo(macro.icon))
      child("CEMI_MacroImportRow" .. i .. "Name"):SetText(shownText(macroLabel(macro)))
      child("CEMI_MacroImportRow" .. i .. "Groups"):SetText(macro.groupText)
      local back = child("CEMI_MacroImportRow" .. i .. "Back")
      if macro == import.selected then
        back:Show()
      else
        back:Hide()
      end
      row:Show()
    else
      row:Hide()
    end
  end
  CEMI_MacroImportGroupButtonDropdownText:SetText(import.groups[import.group] or "All groups")
  local selected = import.selected
  CEMI_MacroImportFramePreview:SetText(selected and shownText(selected.text) or "")
  if not import.loaded then
    CEMI_MacroImportFrameStatus:SetText("No macros yet: open Global Bank's page in Chrome, or start its helper.")
  else
    CEMI_MacroImportFrameStatus:SetText(#import.shown .. " of " .. #import.macros .. " macros")
  end
  EMI.DrawImportTarget()
end

-- The Import button says where the macro goes: the slot chosen on the left.
function EMI.DrawImportTarget()
  if not CEMI_MacroImportFrame:IsVisible() then
    return
  end
  local slot = EMI.SelectedMacro()
  CEMI_MacroImportFrameTarget:SetText((HasMacro(slot) and "Replaces macro " or "Goes in macro ") .. slot)
  if import.selected then
    CEMI_MacroImportDoButton:Enable()
  else
    CEMI_MacroImportDoButton:Disable()
  end
end

function EMI.RefreshImport()
  EMI.LoadLibrary()
  EMI.FilterImport()
  EMI.DrawImport()
end

function EMI.Import_OnLoad()
  CEMI_MacroImportFrameTitleText:SetText("Import from Global Bank")
  local gfx = EMI.BasePath() .. "gfx/"
  CEMI_MacroImportGroupButtonLeftArrow:SetTexture(gfx .. "arrowleft.png")
  CEMI_MacroImportGroupButtonRightArrow:SetTexture(gfx .. "arrowright.png")
end

function EMI.Import_OnShow()
  CEMI_MacroPopupFrame:Hide()
  EMI.RefreshImport()
end

function EMI.Import_OnHide()
  import.macros, import.shown, import.selected = {}, {}, nil
end

function EMI.ToggleImport()
  if CEMI_MacroImportFrame:IsVisible() then
    CEMI_MacroImportFrame:Hide()
  else
    CEMI_MacroImportFrame:Show()
  end
end

function EMI.ImportSearch_OnChanged(text)
  import.search = tostring(text or "")
  EMI.FilterImport()
  EMI.DrawImport()
end

function EMI.StepImportGroup(step)
  local count = #import.groups + 1
  import.group = (import.group + step) % count
  EMI.FilterImport()
  EMI.DrawImport()
end

function EMI.ImportGroupLabel_OnClick(key)
  EMI.StepImportGroup(key == "RBUTTON" and -1 or 1)
end

function EMI.ImportScroll_OnValueChanged(this, value)
  UIPanelScrollBar_OnValueChanged(this, value)
  if drawingImport then
    return
  end
  import.offset = math.floor((tonumber(value) or 0) + 0.5)
  EMI.DrawImport()
end

function EMI.ImportWheel(delta)
  import.offset = import.offset + ((tonumber(delta) or 0) > 0 and -3 or 3)
  EMI.DrawImport()
end

function EMI.ImportRow_OnClick(this)
  import.selected = this.macro
  EMI.DrawImport()
end

function EMI.ImportRow_OnEnter(this)
  local macro = this.macro
  if macro then
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetText(macro.name ~= "" and macro.name or "Macro")
    if macro.groupText ~= "" then
      GameTooltip:AddLine(macro.groupText, 1, 0.82, 0)
    end
    GameTooltip:AddLine(shownText(macro.text), 1, 1, 1)
    GameTooltip:Show()
  end
end

function EMI.ImportInto(slot, macro)
  EditMacro(slot, macro.name, macro.icon, macro.text)
  EMI.UpdateMacros()
  CEMI_MacroImportFrameStatus:SetText("Imported " .. shownText(macroLabel(macro)) .. " into macro " .. slot)
end

StaticPopupDialogs["CEMI_MACRO_IMPORT_CONFIRM"] = {
  text = "Replace this macro?",
  button1 = TEXT and TEXT("OKAY") or "OK",
  button2 = TEXT and TEXT("CANCEL") or "Cancel",
  OnAccept = function()
    if import.selected then
      EMI.ImportInto(EMI.SelectedMacro(), import.selected)
    end
  end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

function EMI.ImportSelected()
  local macro = import.selected
  if not macro then
    return
  end
  local slot = EMI.SelectedMacro()
  if HasMacro(slot) then
    StaticPopupDialogs["CEMI_MACRO_IMPORT_CONFIRM"].text = "Replace macro " .. slot .. " with " .. shownText(macroLabel(macro)) .. "?"
    StaticPopup_Show("CEMI_MACRO_IMPORT_CONFIRM")
  else
    EMI.ImportInto(slot, macro)
  end
end

---------------------------------------------------------------------------
-- Start up, chat command, Cherry's Kit
---------------------------------------------------------------------------

function EMI.Start()
  if EMI.started then
    return
  end
  EMI.started = true
  if EMI.IsOffInKit() or EMI.IsSwitchedOff() then
    EMI.RestoreHooks()
    return
  end
  -- The old 2.15 folder still installed: it swaps the same functions and the macro window, so
  -- running both would fight. Let the old one run and say how to fix it.
  if EMI.OldVersionLoaded() then
    print("the old ExtendedMacroIcons 2.15 is still installed, so this version stays off. Run !setup_cherryskit.bat or move "
      .. "Interface\\AddOns\\ExtendedMacroIcons out of AddOns, then Reload UI.")
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
  add("old 2.15 folder loaded: " .. (EMI.OldVersionLoaded() and "YES (move Interface\\AddOns\\ExtendedMacroIcons out of AddOns)" or "no"))
  local stock = EMI.StockCount()
  add("stock icons " .. stock .. (stock >= 10000 and " (TOO MANY: extra icon numbers could clash)" or " (ok)"))
  add("stock icon 1 = " .. tostring(EMI.original.GetMacroIconInfo and EMI.original.GetMacroIconInfo(1) or GetMacroIconInfo(1)))
  add("Global Bank macro library: " .. (EMI.LoadLibrary() and (#import.macros .. " macros, " .. #import.groups .. " groups in use") or "no file yet"))
  import.macros, import.selected = {}, nil
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
    print("turned off. Tick it in /cinfo chat, or turn Cherry's Info on in /ck, then Reload UI.")
    return
  end
  if string.find(msg, "^%s*import") then
    if not CEMI_MacroFrame:IsVisible() then
      ShowUIPanel(CEMI_MacroFrame)
    end
    CEMI_MacroImportFrame:Show()
    return
  end
  EMI.Toggle()
end

SlashCmdList = SlashCmdList or {}
SLASH_ExtendedMacroIcons1 = "/emi"
SlashCmdList["ExtendedMacroIcons"] = function(editBox, msg)
  EMI.Slash(type(editBox) == "string" and editBox or msg)
end
