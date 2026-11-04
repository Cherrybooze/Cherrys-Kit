-- The login screen's two looks. Classic is the game's own textures, as it always was. Modern follows
-- rom weakauras' options window: flat dark panels with a thin border, cyan for what is selected or
-- under the mouse, gold for the main action, and Cherry's Bar's icons (media/, drawn by
-- tools/build_login_skin.py). Buttons, check boxes, lists, edit boxes and panels add themselves here as
-- they load. apply() restyles all of them and lets each screen lay itself out again (its onSkin), so the
-- "Modern look" setting switches at once. Anything that fails here leaves that one control as it was.
local MEDIA = 'interface/loginxml/media/'
local WHITE = {1, 1, 1}

local C = {
  fill = {.035, .085, .12},
  quiet = {.22, .31, .40},
  choice = {.12, .43, .53},
  selected = {0, .85, .88},
  text = {.9, .95, 1},
  dim = {.55, .65, .72},
  faint = {.38, .46, .53},
  gold = {1, .83, .37},
  cyan = {.33, .86, .95},
  green = {.29, .96, .71},
  red = {1, .37, .43},
  black = {0, 0, 0},
  white = WHITE,
  muted = {.5, .5, .5},
  classicGold = {1, .78, 0},
  classicGrey = {.5, .5, .5},
}

local me = {
  MEDIA = MEDIA,
  color = C,
  -- The same colours for |cff codes in text
  hex = {text = 'e6f2ff', dim = '8ca6b8', faint = '61758a', gold = 'ffd35e', cyan = '55dcf2', green = '4af5b4', red = 'ff5f6d'},
  modern = nil, -- the look in use, decided when the first control loads
  buttons = {}, checks = {}, lists = {}, edits = {}, panels = {}, icons = {}, sliders = {},
  -- Buttons that stand out: a screen's main action in gold, deleting in red
  KINDS = {
    LoginCharSelectFrame_enter = 'primary',
    LoginServerFrame_enter = 'primary',
    LoginCharCreateFrame_right_create = 'primary',
    LoginDialog_confirm = 'primary',
    LoginCharSelectFrame_delete = 'danger',
  },
  -- Screens that lay themselves out again on a switch, in this order
  SCREENS = {'settings', 'server', 'charselect', 'account', 'charcreate', 'dialog'},
}

-- The game's backdrops, as the XML gives them, and the flat one: one stretched white texel in a colour
local BACKDROPS = {
  tooltip = {edgeFile = 'Interface\\Tooltips\\Tooltip-border', bgFile = 'Interface\\Tooltips\\Tooltip-Background',
    BackgroundInsets = {left = 4, right = 4, top = 4, bottom = 4}, EdgeSize = 16, TileSize = 16},
  list = {edgeFile = 'Interface\\Tooltips\\Tooltip-border', bgFile = 'Interface\\SocialFrame\\SocialFrame_Contextborder_bg',
    EdgeSize = 10, TileSize = 5},
  dim = {edgeFile = 'Interface\\Tooltips\\Tooltip-border', bgFile = 'Interface\\SocialFrame\\SocialFrame_Contextborder_bg',
    EdgeSize = 0, TileSize = 10},
  flat = {edgeFile = MEDIA .. 'white', bgFile = MEDIA .. 'white', EdgeSize = 0, TileSize = 16},
}

-- ! ==============================================================
-- ! ========================= helpers ============================
-- ! ==============================================================
local function paint(texture, file, l, r, t, b, mode, color, alpha)
  if not texture then
    return
  end
  texture:SetFile(file)
  texture:SetTexCoord(l or 0, r or 1, t or 0, b or 1)
  texture:SetAlphaMode(mode or 'BLEND')
  color = color or WHITE
  texture:SetColor(color[1], color[2], color[3])
  texture:SetAlpha(alpha or 1)
end
me.paint = paint

local function tint(fontString, color)
  if fontString then
    fontString:SetColor(color[1], color[2], color[3])
  end
end
me.tint = tint

local function shown(object, on)
  if object then
    if on then
      object:Show()
    else
      object:Hide()
    end
  end
end

-- A frame's backdrop. Modern: flat colour, no edge (the border is four 1 px textures, see border()).
local function backdrop(frame, kind, alpha, color)
  frame:SetBackdrop(BACKDROPS[kind])
  color = color or WHITE
  frame:SetBackdropTileColor(color[1], color[2], color[3])
  -- A list's own SetBackdropTileAlpha only takes what the screens set for Classic (see me.list)
  local setAlpha = frame._SetBackdropTileAlpha or frame.SetBackdropTileAlpha
  setAlpha(frame, alpha or 1)
end

-- The 1 px border declared in XML as <name>_bt, _bb, _bl and _br (hidden until Modern shows it)
local SIDES = {'_bt', '_bb', '_bl', '_br'}
local function border(frame, color, alpha)
  local name = frame:GetName()
  for _, side in ipairs(SIDES) do
    local line = _G[name .. side]
    if line then
      if color then
        paint(line, MEDIA .. 'white', 0, 1, 0, 1, 'BLEND', color, alpha)
        line:Show()
      else
        line:Hide()
      end
    end
  end
end
me.border = border

local function skipped(object)
  -- The game's own settings window and colour picker keep their look, buttons included
  local name = object:GetName() or ''
  return string.find(name, '^LoginSettingsFrame') or string.find(name, '^LoginColorPicker')
end

-- ! ==============================================================
-- ! ========================== styles ============================
-- ! ==============================================================
local CLASSIC_BUTTON = {'Interface\\Login\\Common\\PanelButton-Normal', 'Interface\\Login\\Common\\PanelButton-Depress',
  'Interface\\Login\\Common\\PanelButton-Disable'}

local function styleButton(button, modern)
  local kind = button.skinKind
  if modern then
    paint(button:GetNormalTexture(), MEDIA .. (kind == 'primary' and 'button_primary' or kind == 'danger' and 'button_danger' or 'button'))
    paint(button:GetPushedTexture(), MEDIA .. 'button_pushed')
    paint(button:GetDisabledTexture(), MEDIA .. 'button_disabled')
    paint(button:GetHighlightTexture(), MEDIA .. (kind == 'danger' and 'button_hover_danger' or 'button_hover'))
    tint(button:GetNormalText(), kind == 'danger' and C.red or kind == 'primary' and WHITE or C.text)
    tint(button:GetHighlightText(), WHITE)
    tint(button:GetDisabledText(), C.faint)
  else
    paint(button:GetNormalTexture(), CLASSIC_BUTTON[1], 0, .96875, 0, .5625)
    paint(button:GetPushedTexture(), CLASSIC_BUTTON[2], 0, .96875, 0, .5625)
    paint(button:GetDisabledTexture(), CLASSIC_BUTTON[3], 0, .96875, 0, .5625)
    paint(button:GetHighlightTexture(), 'Interface\\Buttons\\PanelButton-Highlight', 0, .671875, 0, .6875, 'ADD')
    tint(button:GetNormalText(), C.classicGold)
    tint(button:GetHighlightText(), WHITE)
    tint(button:GetDisabledText(), C.classicGrey)
  end
end

local function styleCheck(box, modern)
  if modern then
    paint(box:GetNormalTexture(), MEDIA .. 'check_off')
    paint(box:GetPushedTexture(), MEDIA .. 'check_off')
    paint(box:GetHighlightTexture(), MEDIA .. 'check_hl', 0, 1, 0, 1, 'ADD')
    paint(box:GetCheckedTexture(), MEDIA .. 'check_on')
    paint(box:GetDisabledCheckTexture(), MEDIA .. 'check_on', 0, 1, 0, 1, 'BLEND', WHITE, .45)
    tint(box:GetNormalText(), C.text)
    tint(box:GetDisabledText(), C.faint)
  else
    paint(box:GetNormalTexture(), 'Interface\\Buttons\\CheckBox-Normal')
    paint(box:GetPushedTexture(), 'Interface\\Buttons\\CheckBox-Depress')
    paint(box:GetHighlightTexture(), 'Interface\\Buttons\\CheckBox-Highlight', 0, 1, 0, 1, 'ADD')
    paint(box:GetCheckedTexture(), 'Interface\\Buttons\\CheckBox-Checked')
    paint(box:GetDisabledCheckTexture(), 'Interface\\Buttons\\CheckBox-Checked-Disabled')
    tint(box:GetNormalText(), C.classicGold)
    tint(box:GetDisabledText(), C.classicGrey)
  end
  if box.skinSize then
    if modern then
      box:SetSize(box.skinSize, box.skinSize)
    else
      box:SetSize(box.classicWidth, box.classicHeight)
    end
  end
end

-- Icon buttons with a Modern icon of their own; classic = {normal, pushed, highlight}
local function styleIcon(button, modern)
  local spec = button.skinIcon
  if modern then
    paint(button:GetNormalTexture(), MEDIA .. spec.file)
    paint(button:GetPushedTexture(), MEDIA .. spec.file, 0, 1, 0, 1, 'BLEND', C.dim)
    paint(button:GetHighlightTexture(), MEDIA .. 'check_hl', 0, 1, 0, 1, 'ADD')
  else
    paint(button:GetNormalTexture(), spec.classic[1])
    paint(button:GetPushedTexture(), spec.classic[2])
    paint(button:GetHighlightTexture(), spec.classic[3], 0, 1, 0, 1, 'ADD')
  end
end

local function styleEdit(edit, modern)
  local name = edit:GetName()
  local file = modern and MEDIA .. 'edit' or 'Interface\\Common\\PanelEditBoxBorder'
  paint(_G[name .. 'Left'], file, 0, .25, 0, .625)
  paint(_G[name .. 'Right'], file, .75, 1, 0, .625)
  paint(_G[name .. 'Middle'], file, .25, .75, 0, .625)
  tint(_G[name .. '_placeholder'], modern and C.faint or WHITE)
end

local function stylePanel(frame, modern)
  local spec = frame.skinPanel
  if modern then
    if spec.kind == 'dim' then
      backdrop(frame, 'flat', .55, C.black)
      border(frame, nil)
    else
      backdrop(frame, 'flat', spec.kind == 'tooltip' and .96 or .9, C.fill)
      border(frame, spec.kind == 'tooltip' and C.choice or C.quiet)
    end
  else
    backdrop(frame, spec.kind, spec.alpha)
    border(frame, nil)
  end
end

local function styleScroll(slider, modern)
  local name = slider:GetName()
  local up, down = _G[name .. 'ScrollUpButton'], _G[name .. 'ScrollDownButton']
  local top, middle, bottom = _G[name .. 'Top'], _G[name .. 'Middle'], _G[name .. 'Bottom']
  local thumb = _G[name .. 'Thumb']
  if modern then
    -- A thin line and a slim handle; the arrows go (wheel and dragging still scroll)
    shown(up, false)
    shown(down, false)
    shown(top, false)
    shown(bottom, false)
    paint(middle, MEDIA .. 'scroll_track', 0, 1, 0, 1, 'BLEND', C.quiet, .8)
    paint(thumb, MEDIA .. 'scroll_thumb', 0, 1, 0, 1, 'BLEND', C.cyan, .85)
  else
    shown(up, true)
    shown(down, true)
    shown(top, true)
    shown(bottom, true)
    local file = 'Interface\\Common\\PanelScrollBar-Broder'
    paint(top, file, 0, 1, 0, .25)
    paint(middle, file, 0, 1, .25, .75)
    paint(bottom, file, 0, 1, .75, 1)
    paint(thumb, 'Interface\\Buttons\\ScrollBar-Knob', 0, 1, 0, .65625)
  end
end

-- Sliders (character creation, the account pages): a thin line, a round knob, small chevrons
local CLASSIC_ARROWS = {Left = 'Interface\\Login\\CharacterCreate\\SliderLeft-',
  Right = 'Interface\\Login\\CharacterCreate\\SliderRight-'}

local function styleSlider(slider, modern)
  local name = slider:GetName()
  local file = modern and MEDIA .. 'slider_track' or 'Interface\\BagFrame\\BagFrame-Slider-Border'
  local color = modern and C.quiet or WHITE
  paint(_G[name .. 'Left'], file, 0, .25, 0, 1, 'BLEND', color)
  paint(_G[name .. 'Right'], file, .75, 1, 0, 1, 'BLEND', color)
  paint(_G[name .. 'Middle'], file, .25, .75, 0, 1, 'BLEND', color)
  if modern then
    paint(_G[name .. 'Thumb'], MEDIA .. 'slider_thumb', 0, 1, 0, 1, 'BLEND', C.cyan)
  else
    paint(_G[name .. 'Thumb'], 'Interface\\BagFrame\\BagFrame-Slider-knob')
  end
  for side, classic in pairs(CLASSIC_ARROWS) do
    local button = _G[name .. side .. 'Button']
    if button then
      if modern then
        local arrow = MEDIA .. 'arrow_' .. string.lower(side)
        paint(button:GetNormalTexture(), arrow, 0, 1, 0, 1, 'BLEND', C.dim)
        paint(button:GetPushedTexture(), arrow, 0, 1, 0, 1, 'BLEND', C.text)
        paint(button:GetDisabledTexture(), arrow, 0, 1, 0, 1, 'BLEND', C.faint, .5)
        paint(button:GetHighlightTexture(), arrow, 0, 1, 0, 1, 'ADD', C.cyan, .6)
      else
        paint(button:GetNormalTexture(), classic .. 'Normal')
        paint(button:GetPushedTexture(), classic .. 'Depress')
        paint(button:GetDisabledTexture(), classic .. 'Disable')
        paint(button:GetHighlightTexture(), classic .. 'Highlight', 0, 1, 0, 1, 'ADD')
      end
    end
  end
end

local function styleList(frame, modern)
  local name = frame:GetName()
  local inner = _G[name .. '_list']
  frame.modern = modern
  if modern then
    backdrop(inner, 'flat', .9, C.fill)
    border(inner, C.quiet)
  else
    backdrop(inner, 'list', inner.classicAlpha or 1)
    border(inner, nil)
  end
  -- The selected row: a cyan bar in Modern, the game's gold glow in Classic
  local hl = _G[name .. '_list_hl']
  if modern then
    paint(hl, MEDIA .. 'white', 0, 1, 0, 1, 'BLEND', C.choice, .5)
    paint(_G[name .. '_list_hlbar'], MEDIA .. 'white', 0, 1, 0, 1, 'BLEND', C.selected, 1)
  else
    paint(hl, 'Interface\\Login\\Common\\ServerlistButton-Highlight')
    shown(_G[name .. '_list_hlbar'], false)
  end
  for i = 0, LOGIN_LIST_TEMPLATE.row.max do
    local row = _G[name .. '_list_' .. i]
    if row then
      local sep = _G[row:GetName() .. '_sep']
      if modern then
        paint(sep, MEDIA .. 'white', 0, 1, 0, 1, 'BLEND', C.quiet, .55)
      else
        shown(sep, false)
      end
      if i == 0 then
        -- The head row: no column art in Modern, cyan titles
        for c = 1, LOGIN_LIST_TEMPLATE.col.max do
          local col = _G[row:GetName() .. '_' .. c]
          if col then
            local colName = col:GetName()
            shown(_G[colName .. 'Left'], not modern)
            shown(_G[colName .. 'Right'], not modern)
            shown(_G[colName .. 'Middle'], not modern)
            tint(col:GetNormalText(), modern and C.cyan or C.classicGold)
          end
        end
      else
        local rowHl = _G[row:GetName() .. '_hl']
        if modern then
          paint(rowHl, MEDIA .. 'white', 0, 1, 0, 1, 'BLEND', C.cyan, .08)
        else
          paint(rowHl, 'Interface\\AuctionFrame\\AuctionFrameItem-Highlight', 0, 1, 0, 1, 'ADD')
        end
      end
    end
  end
  styleScroll(_G[name .. '_scroll'], modern)
  if frame.updateCallback then
    frame:update()
  end
end

-- ! ==============================================================
-- ! ======================== the switch ==========================
-- ! ==============================================================
-- Modern unless the player turned it off (login.config.modern_ui = false)
function me.wanted()
  return not (login and login.config and login.config.modern_ui == false)
end

local function setMode(modern)
  me.modern = modern
  if LOGIN_LIST_TEMPLATE then
    LOGIN_LIST_TEMPLATE.textColor = modern and C.text or WHITE
  end
end

function me.current()
  if me.modern == nil then
    setMode(me.wanted())
  end
  return me.modern
end

local function report(what, err)
  if lprint then
    pcall(lprint, 'skin: ' .. tostring(what) .. ': ' .. tostring(err))
  end
end

local function try(style, object, modern)
  local ok, err = pcall(style, object, modern)
  if not ok then
    report(object:GetName(), err)
  end
end

-- Restyles every control and lets the screens lay themselves out again
function me.apply(modern)
  modern = modern and true or false
  if me.modern == modern then
    return
  end
  setMode(modern)
  for _, object in ipairs(me.buttons) do
    try(styleButton, object, modern)
  end
  for _, object in ipairs(me.checks) do
    try(styleCheck, object, modern)
  end
  for _, object in ipairs(me.icons) do
    try(styleIcon, object, modern)
  end
  for _, object in ipairs(me.edits) do
    try(styleEdit, object, modern)
  end
  for _, object in ipairs(me.panels) do
    try(stylePanel, object, modern)
  end
  for _, object in ipairs(me.sliders) do
    try(styleSlider, object, modern)
  end
  for _, object in ipairs(me.lists) do
    try(styleList, object, modern)
  end
  if login then
    for _, key in ipairs(me.SCREENS) do
      local screen = login[key]
      if screen and screen.onSkin then
        local ok, err = pcall(screen.onSkin, modern)
        if not ok then
          report(key, err)
        end
      end
    end
  end
end

-- ! ==============================================================
-- ! ======================= registration =========================
-- ! ==============================================================
-- Each control calls one of these from its OnLoad and gets the look in use straight away.
function me.button(button)
  if skipped(button) then
    return
  end
  button.skinKind = me.KINDS[button:GetName() or ''] or button.skinKind
  table.insert(me.buttons, button)
  try(styleButton, button, me.current())
end

-- size: a Modern size for a box that is bigger in Classic
function me.check(box, size)
  if skipped(box) or box.skinned then
    return
  end
  box.skinned = true
  if size then
    box.skinSize = size
    box.classicWidth, box.classicHeight = box:GetWidth(), box:GetHeight()
  end
  table.insert(me.checks, box)
  try(styleCheck, box, me.current())
end

-- file: the Modern icon in media/; classic: {normal, pushed, highlight} as in its XML
function me.icon(button, file, classic)
  button.skinIcon = {file = file, classic = classic}
  table.insert(me.icons, button)
  try(styleIcon, button, me.current())
end

function me.edit(edit)
  if skipped(edit) then
    return
  end
  table.insert(me.edits, edit)
  try(styleEdit, edit, me.current())
end

-- kind: the Classic backdrop ('tooltip', 'list' or 'dim'), alpha: its Classic tile alpha
function me.panel(frame, kind, alpha)
  frame.skinPanel = {kind = kind, alpha = alpha or 1}
  table.insert(me.panels, frame)
  try(stylePanel, frame, me.current())
end

function me.slider(slider)
  table.insert(me.sliders, slider)
  try(styleSlider, slider, me.current())
end

function me.list(frame)
  local inner = _G[frame:GetName() .. '_list']
  -- The screens set their own Classic transparency; Modern keeps its own and remembers theirs
  inner._SetBackdropTileAlpha = inner.SetBackdropTileAlpha
  inner.SetBackdropTileAlpha = function(self, alpha)
    self.classicAlpha = alpha
    if not me.modern then
      self:_SetBackdropTileAlpha(alpha)
    end
  end
  table.insert(me.lists, frame)
  try(styleList, frame, me.current())
end

_G['LoginLook'] = me
