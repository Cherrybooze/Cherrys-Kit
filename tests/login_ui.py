"""A stand-in for the game's UI engine, enough to load the whole login screen (Interface/loginxml) the
way the client does: the files in loginxml.toc order, XML templates expanded ("inherits"), "$parent"
in names, scripts run with this/event/arg1... as globals, and OnLoad fired once a top-level frame's
whole tree exists, children first. Widgets are Lua tables with the client's methods (the ones the
login screen calls); their state stays inside the stand-in, so tests can compare what is shown.

It is not the game: textures aren't loaded, text is measured roughly, and calls to methods it doesn't
know are counted in UI.unknown and do nothing. A method the client doesn't have for that kind of object
(its uilua*.cpp tables) is nil, as in the game, and looking it up is counted in UI.missing. The game's own settings window and colour picker
(game_settings/, logincolorpickerframe) are left out."""
import copy
import os
import re
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Interface", "loginxml")
SKIPPED = ("game_settings/", "frames/logincolorpickerframe")
FRAME_TAGS = {"Frame", "Button", "CheckButton", "RadioButton", "EditBox", "Slider", "GameTooltip", "Model", "StatusBar"}
SINGLE = {"Size", "Anchors", "Backdrop", "TexCoords", "PushedTextOffset", "TextInsets", "NormalTexture", "PushedTexture",
          "DisabledTexture", "HighlightTexture", "CheckedTexture", "DisabledCheckedTexture", "NormalText", "HighlightText",
          "DisabledText", "ThumbTexture", "FontString", "FontHeight", "Color", "Shadow"}
PARTS = {"NormalTexture": "normal", "PushedTexture": "pushed", "DisabledTexture": "disabled", "HighlightTexture": "highlight",
         "CheckedTexture": "checked", "DisabledCheckedTexture": "disabledChecked", "ThumbTexture": "thumb",
         "NormalText": "normalText", "HighlightText": "highlightText", "DisabledText": "disabledText", "FontString": "font"}

# What the game's string file gives the login screen, in English
STRINGS = {
    "LOGIN_ACCOUNT_EXIT": "Exit Game", "LOGIN_ACCOUNT_SYS": "Settings", "LOGIN_BACK": "Back", "LOGIN_OKAY": "Confirm",
    "LOGIN_CANCEL": "Cancel", "REALM_LAST_RECORD": "Record server", "CHARACTER_SELECT_DELETE": "Delete",
    "CHARACTER_SELECT_RECOVER_DELETE": "Recover", "CHARACTER_SELECT_REALM": "Server", "CHARACTER_ENTER_WORLD": "Enter World",
    "CHARACTER_SELECT_CREATE": "Create", "LOGIN_ACCOUNT_NAME": "Account", "LOGIN_ACCOUNT_PASSWORD": "Password",
    "LOGIN_ACCOUNT_LOGIN": "Log in", "LOGIN_PLAYER_NAME": "Name", "CHARACTER_CREATE_NAME_TIP": "A name",
    "LOGIN_HUMAN": "Human", "LOGIN_ELF": "Elf", "LOGIN_DWARF": "Dwarf", "LOGIN_MALE": "Male", "LOGIN_FEMALE": "Female",
}

RUNTIME = r"""
local S = {}
UI = {objects = {}, errors = {}, caught = {}, unknown = {}, width = 1280, height = 800, mouse = nil, calls = {}}

-- The login screen wraps most of its work in pcall, so a mistake there would vanish: keep what it caught.
-- Calling a missing handler (login.onEvent tries me[event] for every event) is how it's meant to work.
local rawPcall = pcall
local function pack(...) return {n = select('#', ...), ...} end
function pcall(fn, ...)
  local r = pack(rawPcall(fn, ...))
  if not r[1] and tostring(r[2]) ~= 'attempt to call a nil value' then
    table.insert(UI.caught, tostring(r[2]))
  end
  return unpack(r, 1, r.n)
end
-- Each kind's Lua methods in the client (ui/core/lua/uilua*.cpp in the client source), with what it inherits.
-- A method a kind doesn't have is nil there, as in the game: calling it is an error, so a test sees it.
local CLIENT = {
  layout = {
    'ClearAllAnchors', 'GetAlpha', 'GetAnchor', 'GetAnchorOffset', 'GetBottom', 'GetCenter', 'GetColor',
    'GetHeight', 'GetLeft', 'GetName', 'GetParent', 'GetPos', 'GetRealScale', 'GetRealSize', 'GetRight',
    'GetScale', 'GetSize', 'GetTop', 'GetWidth', 'Hide', 'IsVisible', 'Moving', 'SetAlpha', 'SetAnchor',
    'SetColor', 'SetHeight', 'SetPos', 'SetScale', 'SetSize', 'SetWidth', 'Show',
  },
  frame = {
    'Disable', 'Enable', 'GetID', 'IsEnable', 'Locked', 'RegisterEvent', 'RegisterForClicks', 'RegisterForDrag',
    'ResetFrameOrder', 'SetBackdrop', 'SetBackdropEdgeAlpha', 'SetBackdropEdgeColor', 'SetBackdropTileAlpha',
    'SetBackdropTileColor', 'SetFrameLevel', 'SetFrameStrata', 'SetID', 'SetKeyboardEnable', 'SetLayers',
    'SetMouseEnable', 'SetParent', 'SetScripts', 'StartMoving', 'StartSizing', 'StopMovingOrSizing', 'Unlocked',
    'UnregisterEvent',
  },
  button = {
    'GetDisabledText', 'GetDisabledTexture', 'GetHighlightText', 'GetHighlightTexture', 'GetNormalText',
    'GetNormalTexture', 'GetPushedTexture', 'GetText', 'GetTextHeight', 'GetTextWidth', 'IsButtonPushed',
    'LockHighlight', 'LockPushed', 'SetDisabledTexture', 'SetHighlightTexture', 'SetNormalTexture',
    'SetPushedTexture', 'SetText', 'SetTextAnchor', 'SetTextColor', 'UnlockHighlight', 'UnlockPushed',
  },
  checkbutton = {
    'GetCheckedTexture', 'GetDisabledCheckTexture', 'IsChecked', 'SetChecked',
  },
  radiobutton = {
    'GetGroupId',
  },
  editbox = {
    'AddHistoryLine', 'ClearFocus', 'GetCaretColor', 'GetMultiFirstLine', 'GetMultiMaxLines', 'GetMultiRangeLines',
    'GetNumber', 'GetText', 'HighlightText', 'InsertChar', 'InsertText', 'SetCaretColor', 'SetFocus',
    'SetKeyboardInputEnable', 'SetMultiFirstLine', 'SetNumber', 'SetPasswordMode', 'SetPlaceCaret', 'SetRTL',
    'SetText', 'SetTextColor', 'SetTextInset',
  },
  fontstring = {
    'GetDisplayWidth', 'GetPaintLines', 'GetText', 'HideLastDot', 'IsDrawDot', 'SetFont', 'SetFontSize',
    'SetJustifyHType', 'SetRTL', 'SetText',
  },
  texture = {
    'GetAnimationProgress', 'PlayAnimation', 'Reload', 'SetAlphaMode', 'SetAnimation', 'SetCooldown', 'SetFile',
    'SetLuminance', 'SetMaskFile', 'SetRotate', 'SetTexCoord', 'SetTexture',
  },
  slider = {
    'GetMaxValue', 'GetMinMaxValues', 'GetMinValue', 'GetValue', 'GetValueStepMode', 'SetMaxValue',
    'SetMinMaxValues', 'SetMinValue', 'SetValue', 'SetValueStepMode',
  },
  statusbar = {
    'GetBarColor', 'GetMaxValue', 'GetMinValue', 'GetValue', 'SetBarColor', 'SetMaxValue', 'SetMinValue',
    'SetValue',
  },
  tooltip = {
    'AddDoubleLine', 'AddLine', 'AddSeparator', 'ClearLines', 'IsOwned', 'SetATFTitleItem', 'SetATFTitleTipItem',
    'SetATFUseItem', 'SetAbility', 'SetAccountBagItem', 'SetActionItem', 'SetAssignItem', 'SetAuctionBidItem',
    'SetAuctionBrowseItem', 'SetAuctionItem', 'SetAuctionSellItem', 'SetBagItem', 'SetBankItem', 'SetBootyItem',
    'SetBulletinBoardItem', 'SetCraftItem', 'SetCraftItemRuneHole', 'SetCraftQueueRequestItem',
    'SetCraftRequestItem', 'SetEquipmentItem', 'SetExtraActionItem', 'SetFusionStone', 'SetGameBarItem',
    'SetHistoryItem', 'SetHouseItem', 'SetHyperLink', 'SetImplementActionItem', 'SetInboxItem', 'SetInventoryItem',
    'SetItemDB', 'SetItemMall', 'SetLootItem', 'SetMagicBaseDB', 'SetMagicCollectDB', 'SetMerchantItem',
    'SetOwner', 'SetPartnerItem', 'SetPetActionItem', 'SetPetEquipmentItem', 'SetPetFeedFoodItem',
    'SetPetFeedFoodItemTmp', 'SetPetProductItem', 'SetPetSkillItem', 'SetPetTalentSkillItem', 'SetQuestItem',
    'SetRTL', 'SetRecipeStoreItem', 'SetRuneExChangeItem', 'SetSendMailItem', 'SetShoppingCartItem',
    'SetSkillItem', 'SetSkillItem_LevelUp', 'SetStoreItem', 'SetSuitSkillEquipmentItem', 'SetSuitSkillListItem',
    'SetSuitSkillPlateItem', 'SetSuitSkillSkillItem', 'SetText', 'SetTitle', 'SetTradePlayerItem',
    'SetTradeTargetItem', 'SetUnitBuff', 'SetUnitDebuff',
  },
  model = {
    'Build', 'CanDyeFXColors', 'GetMaterialCount', 'InserLinkFrame', 'IsPaperdoll', 'PlayMotion', 'ReleaseModel',
    'SetAlignmentFrames', 'SetCameraPosition', 'SetComponent', 'SetComponentColors', 'SetDefaultTexture',
    'SetDummyFemale', 'SetDummyMale', 'SetDyeFXColors', 'SetGuildHouseBuilding', 'SetHanger', 'SetItemLink',
    'SetMaskFile', 'SetModel', 'SetModelOffset', 'SetPet', 'SetPlayerModel', 'SetServant', 'SetServantHire',
    'SetTargetBone', 'SetTargetRotate', 'SetUnit', 'TakeOffAll', 'TakeOffWeapon',
  },
  scrollframe = {
    'GetHorizontalScroll', 'GetScrollRange', 'GetVerticalScroll', 'SetHorizontalScroll', 'SetScrollRange',
    'SetVerticalScroll', 'UpdateScrollChildRect',
  },
  listbox = {
    'Clear', 'GetCurrentItem', 'GetItemHeight', 'GetItemSize', 'GetTopItem', 'InsertItem', 'IsItemChecked',
    'RemoveItem', 'SetItemChecked', 'SetItemHeight', 'SetTopItem',
  },
  messageframe = {
    'AddMessage', 'ClearText', 'EnableHyperlink', 'GetFontString', 'GetLines', 'GetPageLines', 'GetPosition',
    'ResetTime', 'ScrollBottom', 'ScrollDown', 'ScrollTop', 'ScrollUp', 'SetFontSize', 'SetLineBytes',
    'SetPosition',
  },
}
local INHERITS = {frame = 'layout', button = 'frame', checkbutton = 'button', radiobutton = 'checkbutton',
  editbox = 'frame', fontstring = 'layout', texture = 'layout', slider = 'frame', statusbar = 'frame', tooltip = 'frame',
  model = 'frame', scrollframe = 'frame', listbox = 'frame', messageframe = 'frame'}
local KIND = {Frame = 'frame', Button = 'button', CheckButton = 'checkbutton', RadioButton = 'radiobutton',
  EditBox = 'editbox', FontString = 'fontstring', Texture = 'texture', Slider = 'slider', StatusBar = 'statusbar',
  GameTooltip = 'tooltip', Model = 'model', ScrollFrame = 'scrollframe', ListBox = 'listbox', MessageFrame = 'messageframe'}
local HAS = {}
for kind in pairs(CLIENT) do
  local set, k = {}, kind
  while k do
    for _, name in ipairs(CLIENT[k]) do set[name] = true end
    k = INHERITS[k]
  end
  HAS[kind] = set
end
UI.has = HAS
UI.missing = {} -- 'kind.Method' looked up on an object of a kind that doesn't have it

local M = {}
local mt = {__index = function(o, k)
  if type(k) ~= 'string' or not string.find(k, '^[A-Z]') then
    return nil
  end
  local s = S[o]
  local has = s and HAS[KIND[s.kind] or 'frame']
  if has and not has[k] then
    local key = s.kind .. '.' .. k
    UI.missing[key] = (UI.missing[key] or 0) + 1
    return nil
  end
  local m = M[k]
  if m ~= nil then return m end
  UI.unknown[k] = (UI.unknown[k] or 0) + 1
  return function() end
end}
UI.methods = M

function UI.create(kind, name, parent, layer)
  local o = setmetatable({}, mt)
  S[o] = {kind = kind, name = name, parent = parent, layer = layer, shown = true, anchors = {}, scripts = {},
    events = {}, alpha = 1, color = {1, 1, 1}, level = 0, parts = {}, children = {}, items = {}, id = 0,
    text = '', enabled = true, checked = false, min = 0, max = 0, value = 0, step = 'FLOAT',
    tileColor = {1, 1, 1}, tileAlpha = 1, edgeColor = {1, 1, 1}, edgeAlpha = 1, coords = {0, 1, 0, 1}, mode = 'BLEND'}
  if parent then
    local list = layer and S[parent].items or S[parent].children
    table.insert(list, o)
  end
  if name then
    _G[name] = o
  end
  table.insert(UI.objects, o)
  return o
end
function UI.state(o) return S[o] end
function UI.set(o, key, value) S[o][key] = value end
function UI.setPart(o, part, child) S[o].parts[part] = child end
function UI.addAnchor(o, point, relativePoint, relativeTo, x, y)
  table.insert(S[o].anchors, {point = point, relativePoint = relativePoint, relativeTo = relativeTo, x = x or 0, y = y or 0})
end
function UI.setScript(o, handler, body, chunk)
  local fn, err = loadstring(body, chunk)
  if not fn then
    table.insert(UI.errors, chunk .. ': ' .. tostring(err))
    return
  end
  S[o].scripts[handler] = fn
end

-- Runs a script the way the client does: this, event, arg1.. and the handler's own names as globals
local NAMES = {'event', 'arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'key', 'delta', 'elapsedTime'}
function UI.fire(o, handler, vars)
  local fn = S[o].scripts[handler]
  if not fn then return false end
  local saved = {this = this}
  for _, n in ipairs(NAMES) do saved[n] = _G[n] end
  this = o
  for _, n in ipairs(NAMES) do _G[n] = vars and vars[n] end
  local ok, err = rawPcall(fn)
  if not ok then
    table.insert(UI.errors, tostring(S[o].name) .. ' ' .. handler .. ': ' .. tostring(err))
  end
  this = saved.this
  for _, n in ipairs(NAMES) do _G[n] = saved[n] end
  return true
end
function UI.event(name, a1, a2, a3, a4)
  for _, o in ipairs(UI.objects) do
    if S[o].events[name] then
      UI.fire(o, 'OnEvent', {event = name, arg1 = a1, arg2 = a2, arg3 = a3, arg4 = a4})
    end
  end
end
-- One frame of time: OnUpdate for every shown frame that has one
function UI.update(elapsed)
  for _, o in ipairs(UI.objects) do
    if S[o].scripts.OnUpdate and UI.visible(o) then
      UI.fire(o, 'OnUpdate', {elapsedTime = elapsed, arg1 = elapsed})
    end
  end
end
function UI.click(o, key, double)
  local s = S[o]
  if s.kind == 'CheckButton' then
    s.checked = not s.checked
  end
  UI.fire(o, double and 'OnDoubleClick' or 'OnClick', {key = key or 'LeftButton'})
end

-- ! ======================== layout =========================
local POINTS = {TOPLEFT = {0, 0}, TOP = {.5, 0}, TOPRIGHT = {1, 0}, LEFT = {0, .5}, CENTER = {.5, .5},
  RIGHT = {1, .5}, BOTTOMLEFT = {0, 1}, BOTTOM = {.5, 1}, BOTTOMRIGHT = {1, 1}}
UI.POINTS = POINTS

-- Rough text size; tools can replace it with a real font's
function UI.measure(text, size)
  local plain = string.gsub(string.gsub(text or '', '|c%x%x%x%x%x%x%x%x', ''), '|r', '')
  local widest, lines = 0, 0
  for line in string.gmatch(plain .. '\n', '([^\n]*)\n') do
    lines = lines + 1
    widest = math.max(widest, string.len(line))
  end
  return widest * size * .55, lines * size -- the client's lines are one font height apart
end

local function textSize(s)
  return UI.measure(s.text, s.fontSize or 12)
end

function UI.relative(s, a)
  local rel = a.relativeTo
  if type(rel) == 'string' then rel = _G[rel] end
  return rel or s.parent
end

function UI.rect(o, depth)
  depth = (depth or 0) + 1
  if depth > 60 then error('anchor loop at ' .. tostring(S[o].name)) end
  local s = S[o]
  local pl, pt, pr, pb = 0, 0, UI.width, UI.height
  if s.parent then pl, pt, pr, pb = UI.rect(s.parent, depth) end
  local w, h = s.w, s.h
  if s.kind == 'FontString' and (not w or w == 0 or not h or h == 0) then
    local tw, th = textSize(s)
    if not w or w == 0 then w = tw end
    if not h or h == 0 then h = th end
  end
  if #s.anchors == 0 then
    if w and h and w > 0 and h > 0 and s.kind ~= 'Texture' then
      return pl, pt, pl + w, pt + h
    elseif s.kind == 'Texture' and w and h and w > 0 and h > 0 and s.layer then
      return pl, pt, pl + w, pt + h
    end
    return pl, pt, pr, pb
  end
  local L, R, CX, T, B, CY
  for _, a in ipairs(s.anchors) do
    local rel = UI.relative(s, a)
    local rl, rt, rr, rb = 0, 0, UI.width, UI.height
    if rel then rl, rt, rr, rb = UI.rect(rel, depth) end
    local rp = POINTS[a.relativePoint or a.point] or POINTS.CENTER
    local x = rl + (rr - rl) * rp[1] + (a.x or 0)
    local y = rt + (rb - rt) * rp[2] + (a.y or 0)
    local p = POINTS[a.point] or POINTS.CENTER
    if p[1] == 0 then L = x elseif p[1] == 1 then R = x else CX = x end
    if p[2] == 0 then T = y elseif p[2] == 1 then B = y else CY = y end
  end
  w, h = w or 0, h or 0
  local l, r, t, b
  if L and R then l, r = L, R elseif L then l, r = L, L + w elseif R then l, r = R - w, R
  elseif CX then l, r = CX - w / 2, CX + w / 2 else l, r = pl, pl + w end
  if T and B then t, b = T, B elseif T then t, b = T, T + h elseif B then t, b = B - h, B
  elseif CY then t, b = CY - h / 2, CY + h / 2 else t, b = pt, pt + h end
  return l, t, r, b
end

function UI.visible(o)
  local s = S[o]
  while s do
    if not s.shown then return false end
    s = s.parent and S[s.parent]
  end
  return true
end

-- As CUiFrame::SetVisible/OnShow: OnShow only once every parent is shown, and then the shown children
-- get theirs first (last first); OnHide right away and only for the frame itself
local function fireShow(o)
  local s = S[o]
  for i = #s.children, 1, -1 do
    local child = s.children[i]
    if S[child].shown then fireShow(child) end
  end
  UI.fire(o, 'OnShow')
end
local function setShown(o, on)
  local s = S[o]
  if s.shown == on then return end
  s.shown = on
  if s.kind == 'Texture' or s.kind == 'FontString' then return end
  if not on then
    UI.fire(o, 'OnHide')
    return
  end
  local p = s.parent
  while p do
    if not S[p].shown then return end
    p = S[p].parent
  end
  fireShow(o)
end

-- ! ======================== methods ========================
local function isButton(s) return s.kind == 'Button' or s.kind == 'CheckButton' or s.kind == 'RadioButton' end

function M.GetName(o) return S[o].name end
function M.GetParent(o) return S[o].parent end
function M.Show(o) setShown(o, true) end
function M.Hide(o) setShown(o, false) end
-- The client's IsVisible() is the object's own flag; IsVisible(true) also asks every parent (frames only)
function M.IsVisible(o, checkParent)
  local s = S[o]
  if checkParent and s.kind ~= 'Texture' and s.kind ~= 'FontString' then return UI.visible(o) end
  return s.shown
end
function M.IsShown(o) return S[o].shown end
function M.SetID(o, id) S[o].id = id end
function M.GetID(o) return S[o].id end
function M.SetSize(o, w, h) S[o].w, S[o].h = w, h end
function M.SetWidth(o, w) S[o].w = w end
function M.SetHeight(o, h) S[o].h = h end
function M.GetWidth(o) local l, t, r, b = UI.rect(o) return r - l end
function M.GetHeight(o) local l, t, r, b = UI.rect(o) return b - t end
function M.GetSize(o) local l, t, r, b = UI.rect(o) return r - l, b - t end
M.GetRealSize = M.GetSize
function M.GetPos(o) local l, t = UI.rect(o) return l, t end
function M.GetLeft(o) local l = UI.rect(o) return l end
function M.GetTop(o) local _, t = UI.rect(o) return t end
function M.ClearAllAnchors(o) S[o].anchors = {} end
function M.SetAnchor(o, point, relativePoint, relativeTo, x, y)
  UI.addAnchor(o, point, relativePoint, relativeTo, x, y)
end
function M.SetAlpha(o, a) S[o].alpha = a end
function M.GetAlpha(o) return S[o].alpha end
function M.SetColor(o, r, g, b) S[o].color = {r, g, b} end
function M.GetColor(o) local c = S[o].color return c[1], c[2], c[3] end
function M.SetScale() end
function M.RegisterEvent(o, e) S[o].events[e] = true end
function M.UnregisterEvent(o, e) S[o].events[e] = nil end
function M.RegisterForClicks() end
function M.SetFrameLevel(o, l) S[o].level = l end
function M.GetFrameLevel(o) return S[o].level end
function M.EnableMouse() end
function M.StartMoving() end
function M.StopMovingOrSizing() end
function M.SetScript() end -- the client ignores Lua-attached handlers
function M.SetBackdrop(o, spec)
  local insets = spec.BackgroundInsets or {}
  S[o].backdrop = {edgeFile = spec.edgeFile or 'Interface\\Tooltips\\Tooltip-Background',
    bgFile = spec.bgFile or 'Interface\\Tooltips\\Tooltip-Border', EdgeSize = spec.EdgeSize or 16,
    TileSize = spec.TileSize or 16, insets = {insets.left or 0, insets.right or 0, insets.top or 0, insets.bottom or 0}}
end
function M.SetBackdropTileColor(o, r, g, b) S[o].tileColor = {r, g, b} end -- the client keeps the alpha
function M.SetBackdropTileAlpha(o, a) if type(a) == 'number' then S[o].tileAlpha = math.min(math.max(a, 0), 1) end end
function M.SetBackdropEdgeColor(o, r, g, b) S[o].edgeColor = {r, g, b} end
function M.SetBackdropEdgeAlpha(o, a) if type(a) == 'number' then S[o].edgeAlpha = a end end

function M.SetText(o, text)
  local s = S[o]
  text = text == nil and '' or tostring(text)
  if isButton(s) then
    for _, part in ipairs({'normalText', 'highlightText', 'disabledText'}) do
      if s.parts[part] then S[s.parts[part]].text = text end
    end
    s.text = text
  elseif s.kind == 'GameTooltip' then
    M.ClearLines(o)
    M.AddLine(o, text)
    setShown(o, true)
  else
    local old = s.text
    s.text = text
    if s.kind == 'EditBox' and old ~= text then UI.fire(o, 'OnTextChanged') end
  end
end
function M.GetText(o)
  local s = S[o]
  if isButton(s) and s.parts.normalText then return S[s.parts.normalText].text end
  return s.text
end
function M.GetTextWidth(o)
  local s = S[o]
  local fs = s.parts.normalText and S[s.parts.normalText]
  if not fs then return 0 end
  return (UI.measure(fs.text, fs.fontSize or 12))
end
function M.GetTextHeight(o)
  local s = S[o]
  local fs = s.parts.normalText and S[s.parts.normalText]
  if not fs then return 0 end
  local _, h = UI.measure(fs.text, fs.fontSize or 12)
  return h
end
function M.GetDisplayWidth(o) return (textSize(S[o])) end
function M.GetNormalText(o) return S[o].parts.normalText end
function M.GetHighlightText(o) return S[o].parts.highlightText end
function M.GetDisabledText(o) return S[o].parts.disabledText end
function M.GetNormalTexture(o) return S[o].parts.normal end
function M.GetPushedTexture(o) return S[o].parts.pushed end
function M.GetDisabledTexture(o) return S[o].parts.disabled end
function M.GetHighlightTexture(o) return S[o].parts.highlight end
function M.GetCheckedTexture(o) return S[o].parts.checked end
function M.GetDisabledCheckTexture(o) return S[o].parts.disabledChecked end
function M.SetTextColor(o, r, g, b)
  local s = S[o]
  if s.kind == 'EditBox' then s.color = {r, g, b} return end
  for _, part in ipairs({'normalText', 'highlightText', 'disabledText'}) do
    if s.parts[part] then S[s.parts[part]].color = {r, g, b} end
  end
end
function M.Enable(o) S[o].enabled = true end
function M.Disable(o) S[o].enabled = false end
function M.IsEnabled(o) return S[o].enabled end
function M.LockHighlight(o) S[o].lockHighlight = true end
function M.UnlockHighlight(o) S[o].lockHighlight = nil end
function M.SetChecked(o, on) S[o].checked = on and true or false end
function M.IsChecked(o) return S[o].checked end
M.GetChecked = M.IsChecked

function M.SetFocus(o) UI.focus = o end
function M.ClearFocus(o) if UI.focus == o then UI.focus = nil end end
function M.HighlightText() end
function M.AddHistoryLine() end
function M.SetPasswordMode(o, on) S[o].password = on end

function M.SetMinMaxValues(o, min, max)
  local s = S[o]
  s.min, s.max = min, max
  if s.value < min or s.value > max then M.SetValue(o, math.min(math.max(s.value, min), max)) end
end
function M.GetMinMaxValues(o) return S[o].min, S[o].max end
function M.GetMinValue(o) return S[o].min end
function M.GetMaxValue(o) return S[o].max end
function M.SetValue(o, v)
  local s = S[o]
  v = math.min(math.max(tonumber(v) or 0, s.min), s.max)
  if s.step == 'INT' then v = math.floor(v + .5) end
  if v ~= s.value then
    s.value = v
    UI.fire(o, 'OnValueChanged')
  end
end
function M.GetValue(o) return S[o].value end
function M.SetValueStepMode(o, mode) S[o].step = mode end
function M.GetValueStepMode(o) return S[o].step end

function M.ClearLines(o)
  local s = S[o]
  s.lines = 0
  for i = 1, 10 do
    local left = _G[s.name .. 'TextLeft' .. i]
    if left then left:Hide() end
  end
end
function M.AddLine(o, text)
  local s = S[o]
  s.lines = (s.lines or 0) + 1
  local left = _G[s.name .. 'TextLeft' .. s.lines]
  if left then left:SetText(text) left:Show() end
end
function M.AddSeparator(o) end
function M.SetOwner() end

function M.SetFile(o, file) S[o].file = file end
M.SetTexture = M.SetFile
function M.SetTexCoord(o, l, r, t, b) S[o].coords = {l or 0, r or 1, t or 0, b or 1} end
function M.SetAlphaMode(o, mode)
  if mode == 'BLEND' or mode == 'ADD' or mode == 'DISABLE' or mode == 'LUMINANCE' then S[o].mode = mode end
end
function M.SetFontSize(o, size) S[o].fontSize = size end
function M.SetFont(o, file, size) S[o].font = file S[o].fontSize = size or S[o].fontSize return true end
function M.SetJustifyHType(o, j) S[o].justifyH = j end
"""

# The client side of the login screen: characters, servers, channels, and what was called
CLIENT = r"""
CLIENT = {
  version = '9.0.0.0000', account = 'cherry', server = 'Gaia', realmRecord = true,
  -- name, sex, level, main class, secondary level, secondary class, zone, delete timer, peak level
  characters = {
    {'Kittycombo', 0, 85, 'Champion', 70, 'Warden', 'Elven Island', nil, 0},
    {'Cherrybooze', 1, 102, 'Priest', 100, 'Druid', 'Obsidian Stronghold', nil, 7},
  },
  maxCharacters = 8,
  servers = { -- location, name, isPVP, characters, load, maintenance
    {'EU', 'Gaia', false, 2, 1, false}, {'DE', 'Aynara', false, 0, 1, false}, {'DE', 'Kadmos', false, 0, 2, false},
  },
  zones = {{'Gaia 1', 1}, {'Gaia 2', 1}, {'Gaia 3', 2}, {'Gaia 4', 3}},
  classes = {'Warrior', 'Scout', 'Rogue', 'Mage', 'Priest', 'Knight', 'Warden', 'Druid', 'Warlock', 'Champion'},
  files = {}, -- extra files for loadfile, by lower-case path
  entered = {},
}
function GetVersion() return CLIENT.version end
function GetAccountName() return CLIENT.account end
function GetServerName() return CLIENT.server end
function TEXT(key) return STRINGS[key] or key end
function GetNumClasses() return #CLIENT.classes end
function GetClassInfoByID(id)
  local name = CLIENT.classes[id]
  if not name then return '', '' end
  return name, string.upper(name)
end
function GetNumCharacters() return #CLIENT.characters end
function GetCharacterInfo(i) local c = CLIENT.characters[i] if c then return unpack(c, 1, 9) end end
function GetMaxCharacterCreate() return CLIENT.maxCharacters end
function SelectCharacter(i) UI.event('UPDATE_SELECTED_CHARACTER', i) end
function EnterWorld(channel) table.insert(CLIENT.entered, channel) end
function GetNumParalleZones() return #CLIENT.zones end
function GetParalleZonesInfo(i) local z = CLIENT.zones[i] return z[1], z[2] end
function GetNumServerList() return #CLIENT.servers end
function GetServerListInfo(i)
  local s = CLIENT.servers[i]
  return s[1], s[2], s[3], s[4], s[5], s[6], false, '', false, false, false, false
end
function GetCurrentServerList() return CLIENT.server end
function ChangeServerList(name) CLIENT.server = name end
function GetSelectedRealmState() return CLIENT.realmRecord end
function SetSelectedRealmState(on) CLIENT.realmRecord = on end
function IsHideLoginUI() return false end
function IsShiftKeyDown() return CLIENT.shift == true end
function IsAltKeyDown() return false end
function IsCtrlKeyDown() return false end
function GetCursorPos() return 0, 0 end
function GetCharacterSelectFacing() return 0 end
function SetCharacterSelectFacing() end
function GetTickCount() return 1000 end
function PlaySoundByPath() end
function OpenCharacterSelect() end
function CloseCharacterSelect() end
function SetCurrentScreen(name) CLIENT.screen = name end
function AcceptUserAgreement() end
function DisconnectFromServer() end
function CloseServerList() end
function DefaultServerLogin() end
function QuitGame() end
function GetCharacterHairColor() return 1, 1, 1 end
function GetCharacterRace() return 0 end
function GetCharacterSex() return 0 end
function GetCharacterVocation() return 1 end
function GetCharacterSkinIndex() return 1 end
function GetCharacterHair() return 1 end
function GetCharacterFace() return 1 end
function GetCharacterCreateFacing() return 0 end
function SetCharacterCreateFacing() end
function UpdateCharacterCreateModel() end
function UpdateCharacterCreateModelBoneScale() end
function OpenCharacterCreateModel() end
function GetCharacterCreateNumSkinColors() return 6 end
function GetCharacterCreateNumHairs() return 6 end
function GetCharacterCreateNumFaces() return 6 end
function GetCharacterCreateFigureInfo() return 0, 100, 50 end
function GetCharacterCreateClassInfo() return 1, true, 2, true, 3, true, 4, true, 5, true, 6, true end
function CreateCharacter() end
function CharacterCreate_SetLookAtFace() end
function CloseCharacterCreateModel() end
function LoginColorTextureFrame_SetColor() end -- logincolorpickerframe, left out
function loadfile(path)
  local key = string.lower(string.gsub(path, '\\', '/'))
  local extra = CLIENT.files[key]
  if extra then return extra end
  return CLIENT_LOADFILE(key)
end
"""


def local(tag):
    return tag.split("}")[-1]


class LoginUI:
    """The login screen in the stand-in. modern: the Modern look setting (None = config.lua's).
    before: Lua run before the files load (CLIENT.files, saved settings). skip: toc entries to leave out."""

    def __init__(self, width=1280, height=800, modern=None, before="", skip=()):
        self.skip = tuple(skip)
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(RUNTIME)
        self.ui = self.lua.globals().UI
        self.ui.width, self.ui.height = width, height
        self.lua.globals().STRINGS = self.lua.table_from(STRINGS)
        for key, value in STRINGS.items():
            self.lua.globals()[key] = value
        self.lua.globals().CLIENT_LOADFILE = self._loadfile
        self.lua.execute(CLIENT)
        if modern is not None:
            self.lua.execute(f"CherrysLoginxml_Settings = {{modern_ui = {str(bool(modern)).lower()}}}")
        if before:
            self.lua.execute(before)
        self.templates = {}
        self.fonts = {}
        self.load()

    # ! ===================== files =====================
    def _loadfile(self, key):
        prefix = "interface/loginxml/"
        if not key.startswith(prefix):
            return None
        path = os.path.join(ROOT, *key[len(prefix):].split("/"))
        if not os.path.isfile(path):
            return None
        with open(path, encoding="latin-1") as handle:
            source = handle.read()
        return self.lua.eval("function(source, name) return (loadstring(source, name)) end")(source, key)

    def toc(self):
        with open(os.path.join(ROOT, "loginxml.toc"), encoding="utf-8") as handle:
            entries = [line.strip() for line in handle if line.strip()]
        return [e for e in entries if not e.startswith("$root") and not e.startswith(SKIPPED) and e not in self.skip]

    def load(self):
        for entry in self.toc():
            path = os.path.join(ROOT, *entry.split("/"))
            if entry.endswith(".lua"):
                with open(path, encoding="latin-1") as handle:
                    source = handle.read()
                err = self.lua.eval("function(s, n) local f, e = loadstring(s, n) if not f then return e end "
                                    "local ok, e2 = pcall(f) if not ok then return e2 end end")(source, entry)
                if err:
                    self.ui.errors[len(self.ui.errors) + 1] = f"{entry}: {err}"
            elif entry.endswith(".xml"):
                self.load_xml(path, entry)

    # ! ===================== XML =====================
    def load_xml(self, path, entry):
        root = ET.parse(path).getroot()
        for node in root:
            if node.get("virtual", "").lower() == "true":
                self.templates[node.get("name")] = node
        for node in root:
            if node.get("virtual", "").lower() == "true" or local(node.tag) not in FRAME_TAGS:
                continue
            parent = node.get("parent")
            parent_obj = self.lua.globals()[parent] if parent else None
            created = []
            self.instantiate(node, parent_obj, parent or "", created, entry)
            # OnLoad once the whole tree exists: children before their parent, last first
            for obj in reversed(created):
                self.ui.fire(obj, "OnLoad")

    def resolve(self, node):
        name = node.get("inherits")
        if not name or name not in self.templates:
            return node
        template = self.resolve(self.templates[name])
        out = copy.deepcopy(template)
        attrs = dict(out.attrib)
        attrs.pop("virtual", None)
        attrs.update(node.attrib)
        attrs.pop("inherits", None)
        out.attrib.clear()
        out.attrib.update(attrs)
        for child in node:
            tag = local(child.tag)
            mine = [c for c in out if local(c.tag) == tag]
            if tag in SINGLE:
                for old in mine:
                    out.remove(old)
                out.append(copy.deepcopy(child))
            elif tag == "Scripts" and mine:
                handlers = {local(h.tag): h for h in mine[0]}
                for handler in child:
                    if local(handler.tag) in handlers:
                        mine[0].remove(handlers[local(handler.tag)])
                    mine[0].append(copy.deepcopy(handler))
            elif tag in ("Layers", "Frames") and mine:
                for item in child:
                    mine[0].append(copy.deepcopy(item))
            else:
                out.append(copy.deepcopy(child))
        return out

    def font(self, node):
        """size, colour and font file of a FontString after its templates"""
        size, color, file = 12, (1, 1, 1), None
        for item in node:
            tag = local(item.tag)
            if tag == "FontHeight":
                value = item.find("{*}AbsValue")
                size = float(value.get("val")) if value is not None else size
            elif tag == "Color":
                color = tuple(float(item.get(k, 1)) for k in ("r", "g", "b"))
        return size, color, node.get("font", file)

    def text(self, value):
        return STRINGS.get(value, value)

    def instantiate(self, node, parent_obj, parent_name, created, entry, layer=None, part=None):
        node = self.resolve(node)
        tag = local(node.tag)
        name = node.get("name")
        if name:
            name = name.replace("$parent", parent_name)
        kind = tag if tag in FRAME_TAGS or tag in ("Texture", "FontString") else tag
        if part:
            kind = "FontString" if part.endswith("Text") or part == "font" else "Texture"
        obj = self.ui.create(kind, name, parent_obj, layer or (part and "PART"))
        if part:
            self.ui.setPart(parent_obj, part, obj)
        own = name or parent_name
        if node.get("hidden", "").lower() == "true":
            self.ui.set(obj, "shown", False)
        if node.get("id"):
            self.ui.set(obj, "id", int(node.get("id")))
        if node.get("frameLevel"):
            self.ui.set(obj, "level", int(node.get("frameLevel")))
        if kind == "Texture":
            if node.get("file"):
                self.ui.set(obj, "file", node.get("file"))
            if node.get("alphaMode"):
                self.ui.set(obj, "mode", node.get("alphaMode"))
        if kind == "FontString":
            size, color, file = self.font(node)
            self.ui.set(obj, "fontSize", size)
            self.ui.set(obj, "color", self.lua.table(*color))
            self.ui.set(obj, "justifyH", node.get("justifyH", "CENTER"))
            self.ui.set(obj, "justifyV", node.get("justifyV", "MIDDLE"))
            if node.get("text") is not None:
                self.ui.set(obj, "text", self.text(node.get("text")))
        if kind == "EditBox" and node.get("password", "").lower() == "true":
            self.ui.set(obj, "password", True)
        if kind in FRAME_TAGS:
            created.append(obj)
        for child in node:
            tag = local(child.tag)
            if tag == "Size":
                dim = child.find("{*}AbsDimension")
                if dim is not None:
                    x, y = dim.get("x"), dim.get("y")
                    self.ui.set(obj, "w", float(x) if x is not None else None)
                    self.ui.set(obj, "h", float(y) if y is not None else None)
            elif tag == "Anchors":
                for anchor in child:
                    offset = anchor.find("{*}Offset/{*}AbsDimension")
                    x = float(offset.get("x", 0)) if offset is not None else 0
                    y = float(offset.get("y", 0)) if offset is not None else 0
                    rel = anchor.get("relativeTo")
                    if rel:
                        # in an anchor, "$parent" is the frame this one belongs to
                        rel = rel.replace("$parent", parent_name)
                    self.ui.addAnchor(obj, anchor.get("point"), anchor.get("relativePoint"), rel, x, y)
            elif tag == "TexCoords":
                self.ui.set(obj, "coords", self.lua.table(*(float(child.get(k, d)) for k, d in
                                                            (("left", 0), ("right", 1), ("top", 0), ("bottom", 1)))))
            elif tag == "Color" and kind == "Texture":
                self.ui.set(obj, "color", self.lua.table(*(float(child.get(k, 1)) for k in ("r", "g", "b"))))
            elif tag == "Backdrop":
                spec = {"edgeFile": child.get("edgeFile"), "bgFile": child.get("bgFile")}
                for key in ("EdgeSize", "TileSize"):
                    value = child.find(f"{{*}}{key}/{{*}}AbsValue")
                    if value is not None:
                        spec[key] = int(float(value.get("val")))
                inset = child.find("{*}BackgroundInsets/{*}AbsInset")
                if inset is not None:
                    spec["BackgroundInsets"] = self.lua.table_from({k: int(float(inset.get(k, 0)))
                                                                    for k in ("left", "right", "top", "bottom")})
                self.lua.globals().UI.methods.SetBackdrop(obj, self.lua.table_from(spec))
            elif tag == "Layers":
                for level in child:
                    for item in level:
                        self.instantiate(item, obj, own, created, entry, layer=level.get("level", "ARTWORK"))
            elif tag == "Frames":
                for item in child:
                    self.instantiate(item, obj, own, created, entry)
            elif tag == "Scripts":
                for handler in child:
                    self.ui.setScript(obj, local(handler.tag), handler.text or "",
                                      f"{entry}:{own}:{local(handler.tag)}")
            elif tag in PARTS:
                self.instantiate(child, obj, own, created, entry, part=PARTS[tag])
        if kind in ("Button", "CheckButton", "RadioButton") and node.get("text") is not None:
            self.lua.globals().UI.methods.SetText(obj, self.text(node.get("text")))
        return obj

    # ! ===================== helpers for tests and tools =====================
    def g(self, name):
        return self.lua.globals()[name]

    def state(self, obj):
        return self.ui.state(obj)

    def errors(self):
        return [self.ui.errors[i] for i in range(1, len(self.ui.errors) + 1)]

    def caught(self):
        """errors the login screen's own pcalls swallowed"""
        return [self.ui.caught[i] for i in range(1, len(self.ui.caught) + 1)]

    def unknown(self):
        return dict(self.ui.unknown.items())

    def missing(self):
        """'Kind.Method' looked up on objects whose kind has no such method in the client"""
        return dict(self.ui.missing.items())

    def event(self, name, *args):
        self.ui.event(name, *args)

    def update(self, elapsed=0.1):
        self.ui.update(elapsed)

    def click(self, name, key="LeftButton", double=False):
        self.ui.click(self.g(name), key, double)

    def rect(self, obj):
        return self.ui.rect(obj)

    def visible(self, obj):
        return self.ui.visible(obj)

    def character_screen(self):
        self.event("SET_LOGIN_SCREEN", "charselect")
        self.event("UPDATE_CHARACTER_PARALLEZONE")
        self.event("UPDATE_CHARACTER_SELECT_LIST")
        self.lua.execute("SelectCharacter(1)")

    def server_screen(self):
        self.event("SET_LOGIN_SCREEN", "login")
        self.event("OPEN_SERVER_LIST")
        self.event("SERVER_LIST_UPDATE")

    def snapshot(self):
        """What is drawn: every shown object's look and place, by name"""
        out = {}
        lua_state = self.ui.state
        for i in range(1, len(self.ui.objects) + 1):
            obj = self.ui.objects[i]
            s = lua_state(obj)
            name = s.name or f"#{i}"
            if not self.visible(obj):
                out[name] = "hidden"
                continue
            anchors = []
            for j in range(1, len(s.anchors) + 1):
                a = s.anchors[j]
                rel = self.ui.relative(s, a)
                rel_name = lua_state(rel).name if rel is not None else None
                anchors.append((a.point, a.relativePoint or a.point, rel_name, round(a.x, 3), round(a.y, 3)))
            look = {k: s[k] for k in ("file", "mode", "text", "fontSize", "justifyH", "w", "h", "checked")}
            for key in ("coords", "color", "tileColor"):
                look[key] = tuple(round(s[key][j], 4) for j in range(1, len(s[key]) + 1))
            look["alpha"] = round(s.alpha, 4)
            look["tileAlpha"] = round(s.tileAlpha, 4)
            if s.backdrop:
                b = s.backdrop
                look["backdrop"] = (b.edgeFile, b.bgFile, b.EdgeSize, b.TileSize, tuple(b.insets[j] for j in range(1, 5)))
            look["anchors"] = tuple(anchors)
            out[name] = look
        return out
