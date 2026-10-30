-- Options.lua: the /rwa window, laid out like Cherry's KittyCombo: a list of auras (preview, name,
-- description, what it tracks) and, behind each Edit button, an editor for that one aura in sections.
-- It replaces the WeakAurasOptions addon (AceGUI) with plain RoM buttons and edit boxes:
-- XML-backed buttons open lists of choices; right click can step back one value.

local RWA = RWA
local W = RWA.W
local Regions = RWA.Regions
local Triggers = RWA.Triggers
local Editor = RWA.Editor

local WIN_W, WIN_H = 1060, 748
local ROWS = 11
local ROW_H = 44
local LIST_TOP = 112 -- first list row, under the column titles
local ui

local CHECK_LABELS = {
  health = "Health", mana = "Mana", skill = "Rage/energy/focus", combat = "In combat",
  target = "Has target", cast = "Casting", cooldown = "Skill cooldown", class = "Class",
  buffcount = "Buff count", debuffcount = "Debuff count",
}

local function indexOf(list, value)
  for i, v in ipairs(list) do
    if v == value then
      return i
    end
  end
  return 0
end

local function selected()
  return ui and ui.selected and Editor.Get(ui.selected)
end

local function at(obj, x, y)
  W.SetPoint(obj, "TOPLEFT", ui.win, "TOPLEFT", x, y)
end

local function label(text, x, y, w)
  local fs = W.FontString(ui.win, "OVERLAY", 12)
  W.SetJustify(fs, "LEFT")
  W.SetSize(fs, w or 96, 20)
  at(fs, x, y)
  W.SetText(fs, text)
  return fs
end

-- Look shared with Cherry's KittyCombo: dark navy panels with thin golden borders, gold headings.
local THEME = {
  bg = { 0.06, 0.09, 0.14, 0.96 },
  title = { 0.04, 0.06, 0.10, 1 },
  bar = { 0.10, 0.15, 0.23, 1 },
  panel = { 0.035, 0.055, 0.09, 1 },
  gold = { 0.85, 0.66, 0.28, 1 },
  darkGold = { 0.45, 0.34, 0.14, 1 },
  dimGold = { 0.55, 0.43, 0.20, 0.7 },
  divider = { 0.16, 0.20, 0.28, 1 },
}
RWA.THEME = THEME
local GOLD_TEXT = "|cffffc840"

-- A thin border of four lines around x, y, w, h (window coordinates). Returns the lines.
local function goldBox(x, y, w, h, color, thick)
  color = color or THEME.gold
  thick = thick or 1
  local lines = {}
  local function line(lx, ly, lw, lh)
    local t = W.Texture(ui.win, "ARTWORK", "Square_FullWhite")
    W.SetSize(t, lw, lh)
    W.SetPoint(t, "TOPLEFT", ui.win, "TOPLEFT", lx, ly)
    W.SetColor(t, color[1], color[2], color[3], color[4] or 1)
    lines[#lines + 1] = t
  end
  line(x, y, w, thick)
  line(x, y + h - thick, w, thick)
  line(x, y, thick, h)
  line(x + w - thick, y, thick, h)
  return lines
end

local function setShown(objs, on)
  for _, o in ipairs(objs) do
    W.SetShown(o, on)
  end
end

-- Keep the old public entry point wired to the current editor menu.
function RWA.CloseDropdown()
  if RWA.UnifiedEditor then RWA.UnifiedEditor.CloseMenu() end
end

W.BeforeClick = function(b)
  if ui and ui.pageName == "edit" then RWA.UnifiedEditor.BeforeClick(b) end
  if RWA.IconPicker and RWA.IconPicker.open then RWA.IconPicker.Close(true) end
end

local function shorten(text, max)
  text = tostring(text or "")
  if string.len(text) > max then
    return string.sub(text, 1, max - 2) .. ".."
  end
  return text
end

-- Splits text into up to two lines of max characters at spaces; the second line ends in ".."
-- when the rest does not fit. Returns line1, line2 (or nil), cut.
local DESC_CHARS = 43
local function wrapTwo(text, max)
  text = RWA.Trim(tostring(text or ""))
  if string.len(text) <= max then
    return text, nil, false
  end
  local cutAt = max
  for i = max + 1, math.floor(max / 2), -1 do
    if string.sub(text, i, i) == " " then
      cutAt = i - 1
      break
    end
  end
  local first = string.sub(text, 1, cutAt)
  local rest = RWA.Trim(string.sub(text, cutAt + 1))
  if string.len(rest) <= max then
    return first, rest, false
  end
  return first, string.sub(rest, 1, max - 2) .. "..", true
end
RWA.WrapTwo = wrapTwo

-- What an aura tracks, in a few words, for the list's "Tracks" column.
function RWA.DescribeTarget(data)
  local triggers = (data.schemaVersion == 2 or data.schemaVersion == 3) and (data.sources or {}) or (data.triggers or {})
  local t = (data.schemaVersion == 2 or data.schemaVersion == 3) and RWA.Rules.FindSource(data, data.primarySourceId) or triggers[1]
  if not t then
    return "nothing yet"
  end
  local text
  if t.type == "status" then
    if t.check == "cooldown" then
      text = "cooldown of " .. ((t.skill and t.skill ~= "") and t.skill or "?")
    else
      text = (t.unit or "player") .. " " .. string.lower(CHECK_LABELS[t.check or "health"] or tostring(t.check))
      if t.op and t.value then
        text = text .. " " .. t.op .. " " .. t.value .. (t.percent and "%" or "")
      end
    end
  elseif t.type == "custom" then
    text = "custom Lua"
  else
    local what = {}
    if type(t.names)=="table" then
      for _, n in ipairs(t.names) do what[#what + 1] = n end
    elseif type(t.names)=="string" and t.names~="" then what[#what + 1]=t.names end
    for _, n in ipairs(t.ids or {}) do
      what[#what + 1] = "#" .. n
    end
    text = (t.filter == "HARMFUL" and "debuff" or "buff") .. " on " .. (t.unit or "player") .. ": "
      .. (#what > 0 and table.concat(what, ", ") or "no name/ID set")
    if t.showOn == "missing" then
      text = "missing " .. text
    end
  end
  if #triggers > 1 then
    text = text .. " (+" .. (#triggers - 1) .. ")"
  end
  return text
end

-- Small picture of the aura for the list: its icon, texture or bar in its colour, or "Aa" for text.
-- A Class trigger's icon, so a turned-off class aura still shows the right picture in the list.
local function classPreview(data)
  local t = (data.schemaVersion == 2 or data.schemaVersion == 3) and RWA.Rules.FindSource(data,data.primarySourceId) or (data.triggers and data.triggers[1])
  if t and t.type == "status" and t.check == "class" and UnitClass and RWA.ClassIcon then
    return RWA.ClassIcon(UnitClass(t.unit or "player"))
  end
end

local function setPreview(row, data)
  local visual = data
  if data.schemaVersion == 3 then
    local first, artwork
    for _, rule in ipairs(data.rules or {}) do
      for _, action in ipairs(rule.actions or {}) do
        local output = action.type == "show" and action.output
        if type(output) == "table" and output.regionType then
          first = first or output
          if ((output.regionType == "icon" or output.regionType == "kittytracker") and output.icon and output.icon ~= "")
            or (output.regionType == "texture" and output.texture and output.texture ~= "") then
            artwork = output; break
          end
        end
      end
      if artwork then break end
    end
    visual = artwork or first or data
  end
  local c = visual.color or { 1, 1, 1, 1 }
  W.SetShown(row.extraTex, false)
  if visual.regionType == "text" then
    setShown({ row.tex }, false)
    local sample = type(visual.text) == "string" and visual.text or ""
    W.SetText(row.textPreview, sample ~= "" and #sample <= 8 and not string.find(sample, "%%") and sample or "Aa")
    W.SetColor(row.textPreview, c[1] or 1, c[2] or 1, c[3] or 1)
    setShown({ row.textPreview }, true)
    return
  end
  setShown({ row.textPreview }, false)
  local path, width, height, white = nil, 32, 32, false
  if visual.regionType == "icon" or visual.regionType == "kittytracker" then
    local a = RWA.loaded[data.id]
    path = (visual.icon and visual.icon ~= "") and visual.icon or data.previewIcon
      or (a and a.region and a.region.lastIcon) or classPreview(data) or "exclamation-mark"
  elseif visual.regionType == "soulpoints" and visual.psiStyle ~= "bar" then
    local diamond = RWA.MEDIA and RWA.MEDIA.resources and RWA.MEDIA.resources.diamond
    path, white = diamond and diamond.path or "Resources/soul-diamond", true
  elseif visual.regionType == "texture" and visual.texture and visual.texture ~= "" then
    path = visual.texture
    local w, h = tonumber(visual.width) or 32, tonumber(visual.height) or 32
    if w > 0 and h > 0 then
      local scale = math.min(32 / w, 32 / h)
      width, height = math.max(1, w * scale), math.max(1, h * scale)
    end
  else
    path = visual.texture or "Statusbar_Clean"
    if visual.regionType == "aurabar" or visual.regionType == "soulpoints" then height = 12 end
  end
  W.SetColor(row.tex, white and 1 or c[1] or 1, white and 1 or c[2] or 1, white and 1 or c[3] or 1, 1)
  local showMax = visual.resource and visual.showMax ~= false and visual.regionType == "aurabar"
  if showMax then width = 21 end
  W.SetSize(row.tex, width, height)
  at(row.tex, showMax and 14 or 14 + (32 - width) / 2, row.previewY + (32 - height) / 2)
  W.SetTexture(row.tex, path)
  setShown({ row.tex }, true)
  if showMax then
    local label = RWA.MEDIA and RWA.MEDIA.resources and RWA.MEDIA.resources.maxLabel
    W.SetTexture(row.extraTex, label and label.path or "Resources/max-label")
    W.SetColor(row.extraTex, 1, 1, 1, 1)
    W.SetSize(row.extraTex, 14, 9)
    at(row.extraTex, 35, row.previewY + 11)
    W.SetShown(row.extraTex, true)
  end
end
-- Search saved definitions without changing their saved ordering.
local function visibleIds()
  local q = string.lower(RWA.Trim(ui and ui.search or ""))
  local ids = {}
  for _, id in ipairs(RWA_DB.order or {}) do
    local data = RWA_DB.auras[id]
    if data then
      local fields = { id, data.desc or "" }
      local sources = (data.schemaVersion == 2 or data.schemaVersion == 3) and data.sources or data.triggers
      for _, source in ipairs(sources or {}) do
        if type(source.names)=="table" then
          for _, value in ipairs(source.names) do fields[#fields + 1] = tostring(value) end
        elseif type(source.names)=="string" then fields[#fields+1]=source.names end
        for _, value in ipairs(source.ids or {}) do fields[#fields + 1] = tostring(value) end
        fields[#fields + 1] = tostring(source.skill or "")
        fields[#fields + 1] = tostring(source.skills or "")
      end
      local matched = q == ""
      for _, value in ipairs(fields) do
        if string.find(string.lower(value), q, 1, true) then matched = true; break end
      end
      if matched then ids[#ids + 1] = id end
    end
  end
  return ids
end

local function selectedIsVisible()
  return ui.selected and indexOf(visibleIds(), ui.selected) > 0
end

local function refreshList()
  if ui.pageName ~= "list" then
    return
  end
  local order = visibleIds()
  W.SetText(ui.emptySearch, #order == 0 and ((ui.search or "") ~= "" and "No auras match this search." or "No auras yet.") or "")
  -- ui.top: how many auras are scrolled past (mouse wheel 1 row, < > a whole page).
  local maxTop = math.max(0, #order - ROWS)
  ui.top = math.max(0, math.min(ui.top or 0, maxTop))
  for i = 1, ROWS do
    local row = ui.rows[i]
    local id = order[ui.top + i]
    row.id = id
    local parts = { row.name, row.desc, row.desc2, row.descHover, row.target, row.branchText, row.export, row.edit, row.toggle, row.up, row.down }
    if id then
      local data = RWA_DB.auras[id]
      -- The selected aura (for Copy, Delete, Test and Export) shows in green.
      local name = shorten(id, 32)
      W.SetText(row.name, (id == ui.selected) and ("|cff80ff80" .. name .. "|r") or name)
      local overview,branches,branchInfo,details=RWA.Rules.ListOverview(data)
      local l1, l2, cut = wrapTwo(overview, DESC_CHARS)
      row.descCut = cut
      W.SetText(row.desc, l1)
      W.SetText(row.desc2, l2 or "")
      at(row.desc, 308, row.descY + (l2 and 0 or 9))
      W.SetText(row.target, details[1] and shorten(details[1].title,28) or "One behavior")
      W.SetText(row.branchText,details[1] and shorten(details[1].condition,28) or "")
      if #branches>1 then W.SetText(row.target,shorten(details[1].title,20).." +"..(#branches-1)) end
      W.SetShown(row.branchRail,#branches>0); W.SetShown(row.branchArm,#branches>0)
      W.SetText(row.toggle, data.enabled and "|cff40ff40On|r" or "|cffff5050Off|r")
      setShown(parts, true)
      local canReorder = RWA.Trim(ui.search or "") == ""
      RWA.Try(row.up, canReorder and "Enable" or "Disable")
      RWA.Try(row.down, canReorder and "Enable" or "Disable")
      setPreview(row, data)
    else
      setShown(parts, false)
      setShown({row.branchRail,row.branchArm},false)
      setShown({ row.tex, row.extraTex, row.textPreview }, false)
    end
  end
  if #order > ROWS then
    W.SetText(ui.pageText, (ui.top + 1) .. "-" .. (ui.top + ROWS) .. " of " .. #order)
  else
    W.SetText(ui.pageText, #order .. (#order == 1 and " aura" or " auras"))
  end
  -- Scrollbar: the thumb shows which part of the list is visible.
  if ui.scrollThumb then
    local trackH = ROWS * ROW_H - 4
    local thumbH = math.max(16, math.floor(trackH * math.min(1, ROWS / math.max(1, #order))))
    local y = maxTop > 0 and math.floor((trackH - thumbH) * ui.top / maxTop) or 0
    W.SetSize(ui.scrollThumb, 6, thumbH)
    at(ui.scrollThumb, ui.scrollX, LIST_TOP + 2 + y)
    setShown({ ui.scrollTrack, ui.scrollThumb }, #order > ROWS)
  end
end

-- Scroll the list by n rows (mouse wheel: up = -1).
function RWA.ScrollList(n)
  if not ui or ui.pageName ~= "list" then
    return
  end
  ui.top = (ui.top or 0) + n
  refreshList()
end

-- Called from the window's XML (and its buttons) on the mouse wheel: delta > 0 is up.
function RWA_ListWheel(delta)
  if RWA.IconPicker and RWA.IconPicker.open then
    RWA.IconPicker.Scroll(delta)
    return
  end
  local step = (tonumber(delta) or 0) > 0 and -1 or 1
  if ui and ui.pageName == "edit" then RWA.UnifiedEditor.Wheel(step,this); return end
  RWA.ScrollList(step)
end

function RWA.ListTop()
  return ui and ui.top or 0
end

-- Keep the aura at position pos (1-based) in view.
local function scrollTo(pos)
  if pos <= 0 then
    return
  end
  ui.top = ui.top or 0
  if pos <= ui.top then
    ui.top = pos - 1
  elseif pos > ui.top + ROWS then
    ui.top = pos - ROWS
  end
end

local function closePicker()
  if RWA.IconPicker then RWA.IconPicker.Close(true) end
end

local function selectAura(id)
  closePicker()
  ui.selected = id
  local pos = id and indexOf(visibleIds(), id) or 0
  scrollTo(pos)
  refreshList()
  RWA.RefreshEditor()
  if ui.exportAura and id then
    ui.exportAura(id, false)
  end
end

RWA.SelectAura = function(id)
  selectAura(id)
end

-- The window shows either the list or the editor of one aura.
function RWA.ShowList()
  if not ui then
    return
  end
  closePicker()
  if RWA.Templates then RWA.Templates.Close() end
  if RWA.UnifiedEditor then RWA.UnifiedEditor.Close() end
  if ui.selected and Editor.new[ui.selected] then Editor.Discard(ui.selected); ui.selected=nil end
  ui.pageName = "list"
  -- Keep the exact search and scroll position when returning from an aura.
  setShown(ui.editorObjs, false)
  setShown(ui.listObjs, true)
  refreshList()
  if RWA.ApplyOptionsSize then RWA.ApplyOptionsSize() end
  if ui.exportAura and ui.selected and RWA_DB.auras[ui.selected] then
    ui.exportAura(ui.selected, false)
  end
end

function RWA.ShowTemplates()
  if not ui then return end
  RWA.ShowList()
  ui.pageName="templates"
  setShown(ui.listObjs,false)
  RWA.Templates.Open(RWA.ShowList,function(templateId)
    local id,entry=RWA.Templates.Create(templateId)
    if not id then return end
    RWA.ShowEditor(id)
    RWA.UnifiedEditor.dirty[id]=true
    if entry.configure then RWA.UnifiedEditor.FocusFirstCheck() end
    RWA.UnifiedEditor.Refresh()
  end)
  RWA.ApplyOptionsSize()
end

-- A clicked rom weakauras chat link: open the list with the code in the Import box.
function RWA.OfferImport(code)
  if not RWA.IsOptionsOpen() then
    RWA.ToggleOptions()
  end
  RWA.ShowList()
  if ui and ui.importBox then
    W.SetText(ui.importBox, code)
  end
  RWA.Print("aura code from a chat link is in the Import box: press Import to add it")
end

function RWA.ShowEditor(id)
  if not ui or not (id and (RWA_DB.auras[id] or Editor.new[id])) then
    return
  end
  closePicker()
  if ui.selected ~= id then
    ui.trigIndex = 1
    ui.elemIndex = 0
    ui.conditionPage = 0
  end
  if RWA.UnifiedEditor then RWA.UnifiedEditor.Close() end
  if RWA.Templates then RWA.Templates.Close() end
  ui.selected, ui.pageName = id, "edit"
  Editor.PrepareForEditing(id)
  if Editor.cleanup[id] then RWA.UnifiedEditor.dirty[id]=true end
  setShown(ui.listObjs, false)
  setShown(ui.editorObjs, false)
  local context = {
    get = selected,
    getName = function() return Editor.names[ui.selected] or ui.selected end,
    setName = function(value) Editor.names[ui.selected] = value end,
    back = RWA.ShowList,
    save = function()
      ui.selected = Editor.Commit(ui.selected)
      if ui.selected then RWA.Print("saved", ui.selected) end
      return ui.selected
    end,
    revert = function() Editor.Revert(ui.selected); RWA.LoadAura(ui.selected) end,
    replaceDraft = function(value) Editor.drafts[ui.selected] = value end,
    inputChanged = function()
      ui.previewDirty = true
      RWA.MarkDirty()
    end,
    finishInputs = function()
      -- Placement uses the draft even when dragging has been locked.
      if RWA.IsEditMode() or RWA.IsOptionsPreview and RWA.IsOptionsPreview() then
        local draft = selected()
        if draft then RWA.LoadAura(draft.id) end
      end
    end,
    changed = function()
      local draft = selected()
      if draft then
        for _, source in ipairs(draft.sources or draft.triggers or {}) do Triggers.Reset(source) end
        RWA.LoadAura(draft.id)
      end
      ui.previewDirty = true
    end,
  }
  if not RWA.UnifiedEditor.Open(id, context) then RWA.ShowList(); return end
  if RWA.IsOptionsPreview and RWA.IsOptionsPreview() then RWA.LoadAura(id) end
  if RWA.ApplyOptionsSize then RWA.ApplyOptionsSize() end
end

---------------------------------------------------------------------------
-- Editor
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Live preview in the editor: a copy of the aura's region inside the window, fed every frame
-- with the on-screen aura's state, colour and alpha (looping test data while the window is open).
---------------------------------------------------------------------------

function RWA.UpdatePreview(now)
  if ui and ui.pageName == "templates" and RWA.IsOptionsOpen() then RWA.Templates.Update(now) end
  if ui and ui.pageName == "edit" and RWA.IsOptionsOpen() then
    RWA.UnifiedEditor.UpdatePreview(now)
  end
end

function RWA.RefreshEditor()
  if ui and ui.pageName == "edit" then RWA.UnifiedEditor.Refresh() end
end

-- Called after any cycle button: rebuild the aura so the change shows at once.
function RWA.RefreshAuraFromEditor()
  local data = selected()
  if data then
    for _, t in ipairs(data.sources or data.triggers or {}) do
      Triggers.Reset(t)
    end
    RWA.LoadAura(data.id)
  end
  if ui then
    ui.previewDirty = true
  end
  refreshList()
  RWA.RefreshEditor()
end

-- Window
---------------------------------------------------------------------------

-- Corner grip: drag right for bigger, left for smaller, 10% per 25 cursor pixels (sideways
-- only, as in KittyCombo: the client's cursor y may count either way).
local GRIP_PIXELS = 25

function RWA.GripScale(start, dx)
  local steps = dx / GRIP_PIXELS
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

function RWA.GripStart()
  local x = cursorX()
  if x then
    RWA.gripDrag = { x = x, scale = tonumber(RWA_DB.settings.uiScale) or 1 }
  end
end

function RWA.GripUpdate()
  local drag, x = RWA.gripDrag, cursorX()
  if not drag or not x then
    return
  end
  local scale = RWA.GripScale(drag.scale, x - drag.x)
  if math.abs(scale - (tonumber(RWA_DB.settings.uiScale) or 1)) > 0.001 then
    RWA.SetWindowScale(scale)
  end
end

function RWA.GripStop()
  RWA.gripDrag = nil
end

function RWA.GripHover(on)
  local tex, grip = _G["RWA_OptGripTexture"], _G["RWA_OptGrip"]
  if tex then
    RWA.Try(tex, "SetTexture", W.TexturePath(on and "Grip_Highlight" or "Grip"))
  end
  if not GameTooltip then
    return
  end
  if on and grip then
    GameTooltip:SetOwner(grip, "ANCHOR_BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Window size")
    GameTooltip:AddLine("Drag this corner right for bigger, left for smaller.", 1, 1, 1)
    GameTooltip:AddLine("Now " .. math.floor((tonumber(RWA_DB.settings.uiScale) or 1) * 100 + 0.5) .. "%", 1, 1, 1)
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

-- Keep the user's preferred scale while fitting this page inside the available UI.
-- Missing height/width APIs simply leave the preference unchanged.
function RWA.ApplyOptionsSize()
  if not ui then return end
  local height = WIN_H
  if ui.resizeWindow then ui.resizeWindow(height) end
  local effective = tonumber(RWA_DB.settings.uiScale) or 1
  local okH, availableH = RWA.Try(UIParent, "GetHeight")
  local okW, availableW = RWA.Try(UIParent, "GetWidth")
  if okH and type(availableH) == "number" and availableH > 200 then
    effective = math.min(effective, (availableH - 32) / height)
  end
  if okW and type(availableW) == "number" and availableW > 200 then
    effective = math.min(effective, (availableW - 32) / WIN_W)
  end
  effective = math.max(0.25, effective)
  ui.effectiveScale = effective
  RWA.Try(ui.win, "SetScale", effective)
end

function RWA.SetWindowScale(scale)
  scale = math.max(0.6, math.min(1.6, tonumber(scale) or 1))
  scale = math.floor(scale * 10 + 0.5) / 10
  RWA_DB.settings.uiScale = scale
  RWA.ApplyOptionsSize()
  return scale
end
function RWA.GetWindowScale() return ui and ui.effectiveScale or 1 end

local function build()
  ui = { top = 0, rows = {}, editorObjs = {} }
  -- The window and its button pool are declared in OptionsWidgets.xml.
  local win = _G["RWA_OptionsWindow"]
  if not win then
    win = W.Frame("RWA_OptionsWindow", "UIParent")
    W.SetPoint(win, "CENTER", "UIParent", "CENTER", 0, 0)
  end
  ui.win = win
  W.SetSize(win, WIN_W, WIN_H)
  RWA.Try(win, "SetScale", tonumber(RWA_DB.settings.uiScale) or 1)
  -- HIGH, not DIALOG: the game tooltip must draw above this window.
  RWA.Try(win, "SetFrameStrata", "HIGH")

  local bg = W.Texture(win, "BACKGROUND", "Square_FullWhite")
  W.SetSize(bg, WIN_W - 8, WIN_H - 8)
  W.SetPoint(bg, "TOPLEFT", win, "TOPLEFT", 4, 4)
  W.SetColor(bg, THEME.bg[1], THEME.bg[2], THEME.bg[3], THEME.bg[4])
  local titleBg = W.Texture(win, "BORDER", "Square_FullWhite")
  W.SetSize(titleBg, WIN_W - 8, 30)
  W.SetPoint(titleBg, "TOPLEFT", win, "TOPLEFT", 4, 4)
  W.SetColor(titleBg, THEME.title[1], THEME.title[2], THEME.title[3], THEME.title[4])
  -- golden frame around the window and under the title
  local outer = goldBox(2, 2, WIN_W - 4, WIN_H - 4, THEME.gold, 2)
  local inner = goldBox(7, 7, WIN_W - 14, WIN_H - 14, THEME.darkGold, 1)
  ui.resizeWindow = function(height)
    W.SetSize(win, WIN_W, height)
    W.SetSize(bg, WIN_W - 8, height - 8)
    local function resizeBorder(lines, inset, thick)
      local width, h = WIN_W - inset * 2, height - inset * 2
      W.SetPoint(lines[2], "TOPLEFT", win, "TOPLEFT", inset, inset + h - thick)
      W.SetSize(lines[2], width, thick)
      W.SetSize(lines[3], thick, h)
      W.SetSize(lines[4], thick, h)
    end
    resizeBorder(outer, 2, 2)
    resizeBorder(inner, 7, 1)
  end
  local titleLine = W.Texture(win, "ARTWORK", "Square_FullWhite")
  W.SetSize(titleLine, WIN_W - 8, 1)
  W.SetPoint(titleLine, "TOPLEFT", win, "TOPLEFT", 4, 34)
  W.SetColor(titleLine, THEME.gold[1], THEME.gold[2], THEME.gold[3], 1)
  local logo = W.Texture(win, "ARTWORK", "logo_64_nobg")
  W.SetSize(logo, 24, 24)
  W.SetPoint(logo, "TOPLEFT", win, "TOPLEFT", 6, 4)
  local title = W.FontString(win, "OVERLAY", 15)
  W.SetJustify(title, "LEFT")
  W.SetSize(title, 400, 24)
  W.SetPoint(title, "TOPLEFT", win, "TOPLEFT", 36, 4)
  W.SetText(title, GOLD_TEXT .. RWA.title .. "|r  |cffaaaaaav" .. RWA.version .. "|r")

  local close = W.Button(win, "X", 26, 24, function()
    RWA.CloseOptions()
  end)
  W.SetPoint(close, "TOPRIGHT", win, "TOPRIGHT", -4, 4)
  -- Window size: - and + next to the close button (one 10% step), and the corner grip
  -- (RWA_OptGrip in OptionsWidgets.xml) for small UI scales or high resolutions. Saved in the settings.
  local function sizeTip()
    return "Window size", "Smaller (-) or bigger (+), or drag the bottom right corner.",
      "Now " .. math.floor((tonumber(RWA_DB.settings.uiScale) or 1) * 100 + 0.5) .. "%. Also /rwa size 60-160."
  end
  local bigger = W.Button(win, "+", 24, 24, function()
    RWA.SetWindowScale((tonumber(RWA_DB.settings.uiScale) or 1) + 0.1)
  end)
  W.SetPoint(bigger, "TOPRIGHT", win, "TOPRIGHT", -32, 4)
  W.Tooltip(bigger, sizeTip)
  local smaller = W.Button(win, "-", 24, 24, function()
    RWA.SetWindowScale((tonumber(RWA_DB.settings.uiScale) or 1) - 0.1)
  end)
  W.SetPoint(smaller, "TOPRIGHT", win, "TOPRIGHT", -58, 4)
  W.Tooltip(smaller, sizeTip)
  RWA.sizeButtons = { up = bigger, down = smaller }
  local gripTex = _G["RWA_OptGripTexture"]
  if gripTex then
    RWA.Try(gripTex, "SetTexture", W.TexturePath("Grip"))
  end

  -- The window moves with StartMoving from its XML scripts.
  if _G["RWA_OptionsWindow"] then
    W.UseXmlScripts(win, "RWA_OptionsWindow")
  end

  -- Aura list, as in KittyCombo's list: preview, name, description, what it tracks, Edit, On/Off, order.
  ui.listObjs = {}
  local function L2(obj)
    table.insert(ui.listObjs, obj)
    return obj
  end
  local function head(text, x, w)
    local fs = L2(label("|cffccd6eb" .. text .. "|r", x, 82, w))
    return fs
  end
  -- the list sits in a gold-framed panel, with a faint line between rows
  local listPanel = L2(W.Texture(win, "BORDER", "Square_FullWhite"))
  W.SetSize(listPanel, WIN_W - 16, LIST_TOP - 42 + ROWS * ROW_H + 2)
  at(listPanel, 8, 42)
  W.SetColor(listPanel, THEME.panel[1], THEME.panel[2], THEME.panel[3], THEME.panel[4])
  for _, t in ipairs(goldBox(8, 42, WIN_W - 16, LIST_TOP - 42 + ROWS * ROW_H + 2)) do
    L2(t)
  end
  local listLine = L2(W.Texture(win, "ARTWORK", "Square_FullWhite"))
  W.SetSize(listLine, WIN_W - 18, 1)
  at(listLine, 9, LIST_TOP - 4)
  W.SetColor(listLine, THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.8)
  for i = 1, ROWS - 1 do
    local sep = L2(W.Texture(win, "BORDER", "Square_FullWhite"))
    W.SetSize(sep, WIN_W - 18, 1)
    at(sep, 9, LIST_TOP + i * ROW_H - 3)
    W.SetColor(sep, THEME.divider[1], THEME.divider[2], THEME.divider[3], THEME.divider[4])
  end
  L2(label("Search", 16, 48, 58))
  local searchBox, searchBg = W.EditBox(win, 650, 28)
  L2(searchBox)
  if searchBg then L2(searchBg) end
  at(searchBox, 90, 48)
  W.SetScript(searchBox, "OnTextChanged", function()
    ui.search = W.GetText(searchBox)
    ui.top = 0
    refreshList()
  end)
  local clearSearch = L2(W.Button(win, "Clear search", 130, 28, function()
    W.SetText(searchBox, "")
    ui.search, ui.top = "", 0
    refreshList()
  end))
  at(clearSearch, 752, 48)
  ui.emptySearch = L2(label("", 240, LIST_TOP + 20, 360))
  head("Name", 56, 238)
  head("What it does", 308, 276)
  head("Branches", 598, 188)
  for i = 1, ROWS do
    local row = {}
    local y = LIST_TOP + (i - 1) * ROW_H
    row.previewY = y + 4
    row.tex = L2(W.Texture(win, "ARTWORK"))
    row.extraTex = L2(W.Texture(win, "OVERLAY"))
    W.SetSize(row.tex, 26, 26)
    at(row.tex, 14, y + 4)
    row.textPreview = L2(W.FontString(win, "OVERLAY", 14, "THICK"))
    W.SetSize(row.textPreview, 36, 32)
    at(row.textPreview, 12, y + 4)
    row.name = L2(W.Button(win, "", 238, 30, function()
      if row.id then
        RWA.ShowEditor(row.id)
      end
    end))
    at(row.name, 56, y + 5)
    W.Skin(row.name,"quiet"); W.SetFont(W.skins[row.name].label,14)
    W.Tooltip(row.name, function()
      local d = row.id and RWA_DB.auras[row.id]
      if not d then return end
      local loadedAura = RWA.loaded and RWA.loaded[row.id]
      local lines = RWA.Rules.TooltipLines(d, loadedAura and loadedAura.ruleResult, loadedAura and loadedAura.states)
      return d.id, unpack(lines)
    end)
    -- the description takes up to 2 lines; hovering shows all of it when it does not fit
    row.desc = L2(label("", 308, y, 276))
    row.desc2 = L2(label("", 308, y + 18, 276))
    row.descY = y
    W.SetFont(row.desc,13); W.SetFont(row.desc2,13)
    row.descHover = L2(W.HoverFrame(win))
    W.SetSize(row.descHover, 276, 40)
    at(row.descHover, 308, y)
    W.Tooltip(row.descHover, function()
      local data = row.id and RWA_DB.auras[row.id]
      if data then
        local loaded=RWA.loaded and RWA.loaded[data.id]
        return data.id,unpack(RWA.Rules.TooltipLines(data,loaded and loaded.ruleResult,loaded and loaded.states))
      end
    end)
    row.target = L2(label("", 604, y, 182))
    row.branchText=L2(label("",604,y+18,182)); W.SetFont(row.branchText,11)
    row.branchRail=L2(W.Texture(win,"ARTWORK","Square_FullWhite")); W.SetSize(row.branchRail,1,26); at(row.branchRail,596,y+4)
    row.branchArm=L2(W.Texture(win,"ARTWORK","Square_FullWhite")); W.SetSize(row.branchArm,6,1); at(row.branchArm,596,y+27)
    W.SetColor(row.branchRail,.2,.65,.67); W.SetColor(row.branchArm,.2,.65,.67)
    row.export = L2(W.Button(win, "Export", 68, 30, function()
      if row.id then
        selectAura(row.id)
        ui.exportAura(row.id, true)
      end
    end))
    at(row.export, 794, y + 5)
    row.edit = L2(W.Button(win, "Edit", 52, 30, function()
      if row.id then
        RWA.ShowEditor(row.id)
      end
    end))
    at(row.edit, 868, y + 5)
    row.toggle = L2(W.Button(win, "", 48, 30, function()
      local data = row.id and RWA_DB.auras[row.id]
      if data then
        data.enabled = not data.enabled
        local draft = Editor.drafts[row.id]
        if draft then draft.enabled = data.enabled end
        -- LoadAura unloads a turned-off aura, except in edit mode where it stays visible, dimmed.
        RWA.LoadAura(row.id)
        refreshList()
      end
    end))
    at(row.toggle, 926, y + 5)
    local function move(delta)
      return function()
        if RWA.Trim(ui.search or "") ~= "" then RWA.Print("Clear search to reorder."); return end
        local pos = row.id and indexOf(RWA_DB.order, row.id) or 0
        local to = pos + delta
        if pos > 0 and to >= 1 and to <= #RWA_DB.order then
          RWA_DB.order[pos], RWA_DB.order[to] = RWA_DB.order[to], RWA_DB.order[pos]
          selectAura(row.id)
        end
      end
    end
    row.up = L2(W.Button(win, "^", 26, 30, move(-1)))
    at(row.up, 980, y + 5)
    row.down = L2(W.Button(win, "v", 26, 30, move(1)))
    at(row.down, 1012, y + 5)
    local function reorderTip()
      if RWA.Trim(ui.search or "") ~= "" then return "Clear search to reorder" end
      return "Reorder aura"
    end
    W.Tooltip(row.up, reorderTip)
    W.Tooltip(row.down, reorderTip)
    ui.rows[i] = row
  end
  local listBottom = LIST_TOP + ROWS * ROW_H + 6
  local prev = L2(W.Button(win, "<", 30, 24, function()
    RWA.ScrollList(-ROWS)
  end))
  at(prev, 14, listBottom)
  ui.pageText = L2(W.FontString(win, "OVERLAY", 12))
  W.SetSize(ui.pageText, 60, 24)
  -- scrollbar track and thumb, right of the order buttons
  ui.scrollX = WIN_W - 14
  ui.scrollTrack = L2(W.Texture(win, "ARTWORK", "Square_FullWhite"))
  W.SetSize(ui.scrollTrack, 6, ROWS * ROW_H - 4)
  at(ui.scrollTrack, ui.scrollX, LIST_TOP + 2)
  W.SetColor(ui.scrollTrack, THEME.divider[1], THEME.divider[2], THEME.divider[3], 1)
  ui.scrollThumb = L2(W.Texture(win, "OVERLAY", "Square_FullWhite"))
  W.SetColor(ui.scrollThumb, THEME.gold[1], THEME.gold[2], THEME.gold[3], 1)
  at(ui.pageText, 48, listBottom)
  local nextBtn = L2(W.Button(win, ">", 30, 24, function()
    RWA.ScrollList(ROWS)
  end))
  at(nextBtn, 112, listBottom)

  local function action(text, x, y2, fn, w)
    local b = L2(W.Button(win, text, w or 86, 30, fn))
    at(b, x, y2)
    return b
  end
  local ax = 190
  action("New", ax, listBottom, function()
    RWA.ShowTemplates()
  end)
  action("Copy", ax + 96, listBottom, function()
    if selectedIsVisible() then
      selectAura(RWA.DuplicateAura(ui.selected))
    end
  end)
  local deleteArmed = 0
  local deleteBtn
  deleteBtn = action("Delete", ax + 192, listBottom, function()
    if not selectedIsVisible() then
      RWA.Print("Select a visible aura first.")
      return
    end
    if RWA.Now() - deleteArmed > 3 then
      deleteArmed = RWA.Now()
      W.SetText(deleteBtn, "Sure?")
      RWA.After(3, function()
        W.SetText(deleteBtn, "Delete")
      end)
      return
    end
    deleteArmed = 0
    W.SetText(deleteBtn, "Delete")
    RWA.DeleteAura(ui.selected)
    selectAura(nil)
  end)
  action("Test", ax + 288, listBottom, function()
    if selectedIsVisible() then
      RWA.TestAuras(ui.selected)
    elseif ui.selected then
      RWA.Print("Select a visible aura first.")
    else
      RWA.TestAuras()
    end
  end)
  action("Test all", ax + 384, listBottom, function()
    RWA.TestAuras()
  end)
  -- Move mode: while the window is open every aura shows looping test data and can be dragged.
  ui.moveOn = true
  ui.moveBtn = action("Lock positions", ax + 480, listBottom, function()
    ui.moveOn = not ui.moveOn
    RWA.SetEditMode(ui.moveOn)
    W.SetText(ui.moveBtn, ui.moveOn and "Lock positions" or "Unlock positions")
  end, 110)
  ui.loudBtn = action("", ax + 600, listBottom, function()
    RWA.SetLoudSounds((tonumber(RWA_DB.settings.soundVolume) or 0) == 0)
  end, 150)
  RWA.OnLoudChanged((tonumber(RWA_DB.settings.soundVolume) or 0) > 0)

  -- Share codes, the same format as Cherry's KittyCombo: Import on the upper line, the selected
  -- aura's code (or all auras) on the lower one. Export buttons copy the code to the clipboard.
  local sy = listBottom + 38
  local importBox, importBoxBg = W.EditBox(win, 772, 28)
  L2(importBox)
  if importBoxBg then
    L2(importBoxBg)
  end
  at(importBox, 16, sy + 2)
  ui.importBox = importBox
  action("Import", 800, sy, function()
    local ids, err = RWA.Share.Import(W.GetText(importBox))
    if not ids then
      RWA.Print(err)
      return
    end
    W.SetText(importBox, "")
    RWA.Print("imported", #ids, "aura(s):", table.concat(ids, ", "))
    selectAura(ids[1])
  end, 112)
  local exportBox, exportBoxBg = W.EditBox(win, 772, 28)
  L2(exportBox)
  if exportBoxBg then
    L2(exportBoxBg)
  end
  at(exportBox, 16, sy + 34)
  ui.exportBox = exportBox
  local function sizeText(code)
    local n = string.len(code)
    if n > 255 then
      return "|cffff6060" .. n .. " characters. In-game chat only supports 255 characters. Share this on Discord or elsewhere.|r"
    end
    return n .. " characters: fits in one chat line."
  end
  local infoToken = 0
  -- ids: a list of aura ids, or nil for all. copy: also put it on the clipboard.
  local function exportCode(ids, copy)
    local code, count = RWA.Share.Export(ids)
    if not code then
      RWA.Print(count)
      return
    end
    ui.lastExport = { code = code, name = ids and ids[1] or ("all " .. count .. " auras") }
    W.SetText(exportBox, code)
    local info = sizeText(code)
    W.SetText(ui.exportInfo, info)
    if copy then
      local copied = type(Chat_CopyToClipboard) == "function" and pcall(Chat_CopyToClipboard, code)
      RWA.Try(exportBox, "SetFocus")
      RWA.Try(exportBox, "HighlightText")
      infoToken = infoToken + 1
      local mine = infoToken
      W.SetText(ui.exportInfo, copied and "|cff40ff40Copied export hash to clipboard.|r " .. info
        or "|cffffd040Press Ctrl+C to copy the selected code.|r " .. info)
      RWA.After(3, function()
        if infoToken == mine then
          W.SetText(ui.exportInfo, info)
        end
      end)
    end
  end
  ui.exportAura = function(id, copy)
    exportCode({ id }, copy)
  end
  action("Export all", 800, sy + 34, function()
    exportCode(nil, true)
  end, 112)
  ui.linkBtn = action("Chat link", 922, sy + 34, function()
    local last = ui.lastExport
    if not last then
      RWA.Print("export an aura first, then Chat link puts a clickable link to it in your chat line")
      return
    end
    RWA.Share.PostLink(last.code, last.name)
  end, 112)
  ui.exportInfo = L2(label("Import adds auras, never replaces. Export copies the code; Chat link puts a clickable link in your chat line.", 16, sy + 68, 1028))

  RWA.ShowList()
end

-- Clicking or dragging an aura on screen selects it: in the list it is marked, in the editor
-- the editor switches to it.
function RWA.OnAuraMoved(id,kind,modified)
  if not ui or not RWA.IsOptionsOpen() then
    return
  end
  if RWA.UnifiedEditor and modified~=false then RWA.UnifiedEditor.PlacementChanged(id,kind) end
  if ui.pageName == "edit" then
    if ui.selected ~= id then
      RWA.ShowEditor(id)
    else
      RWA.UnifiedEditor.previewDirty=true
      RWA.RefreshEditor()
    end
  else
    selectAura(id)
  end
end

function RWA.IsOptionsOpen()
  return ui ~= nil and ui.win.IsVisible ~= nil and ui.win:IsVisible() and true or false
end

function RWA.OnLoudChanged(on)
  if ui and ui.loudBtn then
    local pct = tonumber(RWA_DB.settings.soundVolume) or 0
    W.SetText(ui.loudBtn, pct > 0 and ("Vol: |cff40ff40" .. pct .. "%|r") or "Vol: game")
  end
end

function RWA.OnEditModeChanged(on)
  if ui and ui.moveBtn then
    ui.moveOn=on
    W.SetText(ui.moveBtn, on and "Lock positions" or "Unlock positions")
  end
end

function RWA.OptionsWindowHidden()
  if RWA.HotbarPicker and RWA.HotbarPicker.open then RWA.HotbarPicker.Close() end
  if RWA.UnifiedEditor and RWA.UnifiedEditor.open then
    RWA.UnifiedEditor.Flush(); RWA.UnifiedEditor.CloseMenu()
    if RWA.UnifiedEditor.cancelThumbDrag then RWA.UnifiedEditor.cancelThumbDrag() end
  end
  if RWA.IconPicker and RWA.IconPicker.open then RWA.IconPicker.Close(true) end
  if RWA.SetOptionsPreview then RWA.SetOptionsPreview(false) else RWA.SetEditMode(false) end
end

function RWA.CloseOptions()
  if ui then RWA.Try(ui.win,"Hide") end
  RWA.OptionsWindowHidden()
end

function RWA.ToggleOptions()
  if not ui then
    build()
    RWA.Try(ui.win, "Show")
    RWA.SetOptionsPreview(true)
    return
  end
  if RWA.IsOptionsOpen() then
    RWA.CloseOptions()
  else
    refreshList()
    RWA.RefreshEditor()
    RWA.Try(ui.win, "Show")
    RWA.SetOptionsPreview(true)
    if ui.pageName=="templates" then RWA.ShowTemplates()
    elseif ui.pageName=="edit" and ui.selected then RWA.LoadAura(ui.selected) end
  end
end
