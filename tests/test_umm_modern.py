"""Ultimate Mail Mod's modern mail window against a simulated mailbox.

The real UMM Lua (master frame, mail manager, composer, bag manager), the real Modern.xml frames and
the modern window's own Lua run. Only the game's side is simulated: the inbox and the server's
answers, bags, cursor, send slot, gold, and the frame clock.
"""
import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

import test_umm_mail_shortcuts as support

UMM = support.UMM
ROOT = support.ROOT
CAP = 999_999_999
MODERN_FILES = ["Core.lua", "Plan.lua", "Queue.lua", "Picker.lua", "Inbox.lua", "Compose.lua", "Mass.lua",
                "Activity.lua"]

GAME = r'''
-- ### The game's side: clock, gold, bags, cursor, send slot, inbox and the server's answers ###
ummNow, ummMoney, ummMaxMoney = 0, 0, 0
ummInbox, ummReads, ummTakes, ummDeletes, ummReturns, ummTips, ummDofiles = {}, {}, {}, {}, {}, {}, {}
ummSent, ummDelivered, ummShownPanels = {}, {}, {}
ummServer = {}
ummCursor, ummSlot = nil, nil
ummAttachMoney, ummAttachCOD = 0, 0
ummFailSends = 0
ummReply, ummTakeLag, ummMoneyLag = 0.05, 0.05, 0
ummBagSlots, ummCategories = {}, {}
cursorX, cursorY, ctrl, shift = 0, 0, false, false

local function later(delay, fn) table.insert(ummServer, { at = ummNow + delay, fn = fn }) end
local function event(name, ...) UMMMasterFrame_OnEvent(name, ...) end
local function setMoney(value)
  ummMoney = value
  if value > ummMaxMoney then ummMaxMoney = value end
end
function ummSetMoney(value) ummMoney, ummMaxMoney = value, value end

function GetTime() return ummNow end
function GetPlayerMoney() return ummMoney end
function GetCursorPos() return cursorX, cursorY end
function IsCtrlKeyDown() return ctrl end
function IsShiftKeyDown() return shift end
-- the classic window's own OnShow needs its inbox frames, which these tests do not build
function ShowUIPanel(frame) table.insert(ummShownPanels, frame:GetName()); frame.visible = true end
function HideUIPanel(frame) if frame then frame:Hide() end end

-- bags: slot 1-180, inventory index = slot + 1000; two stacks of one item share its id
local ids, nextId = {}, 0x10000
function ummItem(slot, name, count)
  if not ids[name] then nextId = nextId + 1; ids[name] = nextId end
  local item = { name = name, count = count or 1, icon = "Icons/"..name,
    link = "|cffffffff|Hitem:"..string.format("%x", ids[name]).."|h["..name.."]|h|r" }
  ummBagSlots[slot] = item
  return item
end
function GetBagItemInfo(slot)
  local item = ummBagSlots[slot]
  if item then return slot + 1000, item.icon, item.name, item.count end
  return slot + 1000, nil, nil, 0
end
-- the arcane transmutor: body slots 51-60 (ummBox[51..60]), read with GetGoodsItemInfo, outside the bag list
ummBox = {}
function ummBoxItem(slot, name, count)
  local item = ummItem(0, name, count)
  ummBagSlots[0], ummBox[slot] = nil, item
  return item
end
function ummBody(index)
  if index and index >= 51 and index <= 60 then return ummBox[index] end
  return index and ummBagSlots[index - 1000]
end
local function takeBody(index)
  if index >= 51 and index <= 60 then ummBox[index] = nil else ummBagSlots[index - 1000] = nil end
end
function GetGoodsItemInfo(index)
  local item = ummBox[index]
  if item then return item.icon, item.name, item.count, false end
  return "", "", 0, false
end
function GetBagItemLink(index) local item = ummBody(index); return item and item.link end

-- cursor and the game's send slot
function CursorHasItem() return ummCursor ~= nil end
function GetCursorItemInfo() return ummCursor end
function PickupBagItem(index)
  if ummCursor then ummCursor = nil            -- put back where it came from
  elseif ummBody(index) then ummCursor = index end
end
function ItemClipboard_Clear() ummCursor = nil end
function ClickSendMailItemButton()
  if ummCursor then ummSlot, ummCursor = ummCursor, nil
  elseif ummSlot then ummCursor, ummSlot = ummSlot, nil end
  later(ummReply, function() event("MAIL_SEND_INFO_UPDATE") end)
end
function GetSendMailItem()
  local item = ummSlot and ummBody(ummSlot)
  if item then return item.name, item.icon, item.count end
end
function SetSendMailMoney(gold) ummAttachMoney = gold end
function SetSendMailCOD(gold) ummAttachCOD = gold end
function SendMail(to, subject, body)
  local item = ummSlot and ummBody(ummSlot)
  local mail = { recipient = to, subject = subject, body = body, money = ummAttachMoney or 0,
    cod = ummAttachCOD or 0, slot = ummSlot, item = item and item.name }
  ummAttachMoney, ummAttachCOD = 0, 0
  table.insert(ummSent, mail)
  later(ummReply, function()
    if ummFailSends > 0 then
      ummFailSends = ummFailSends - 1
      event("MAIL_FAILED")
      return
    end
    if mail.slot then takeBody(mail.slot); ummSlot = nil end
    table.insert(ummDelivered, mail)
    event("MAIL_SEND_SUCCESS")
    if mail.slot then event("PLAYER_BAG_CHANGED") end
    if mail.money > 0 then
      -- the gold leaving is its own message from the server, and can come late
      later(ummMoneyLag, function() setMoney(ummMoney - mail.money); event("PLAYER_MONEY") end)
    end
  end)
end

-- the inbox: { sender, subject, body, money, mode, cod, items = {{ name, icon, count }}, read, returned, system, days }
function ummMail(sender, money, fields)
  local m = fields or {}
  m.sender, m.money = sender, money or 0
  m.subject = m.subject or ("Mail "..(#ummInbox + 1))
  m.days = m.days or 29.5
  table.insert(ummInbox, m)
  return m
end
function GetInboxNumItems() return #ummInbox end
function GetInboxHeaderInfo(i)
  local m = ummInbox[i]
  if not m then return nil end
  local items = m.items and #m.items or 0
  local icon = (m.items and m.items[1] and m.items[1].icon) or ""
  return icon, m.sender, m.subject, m.cod ~= nil, m.mode or "copper", m.cod or m.money, m.days, 1, items,
    m.read == true, m.returned == true, m.system ~= true
end
-- reading a mail marks it read and cuts its time to 3 days (the game's rule)
local function readMail(i)
  local m = ummInbox[i]
  if not m then return nil end
  table.insert(ummReads, m.subject)
  if not m.read then
    m.read = true
    if m.days > 4319 / 1440 then m.days = 4319 / 1440 end
  end
  return m
end
function GetInboxText(i) local m = readMail(i); if m then return m.body or "", "", true, false end end
function GetInboxItem(i, pos)
  local m = readMail(i)
  local item = m and m.items and m.items[pos or 1]
  if item then return item.name, item.icon, item.count or 1 end
end
function InboxItemCanDelete(i)
  local m = ummInbox[i]
  return m ~= nil and (m.money or 0) == 0 and m.cod == nil and not (m.items and #m.items > 0)
end
function DeleteInboxItem(i) local m = table.remove(ummInbox, i); table.insert(ummDeletes, m and m.subject or "?") end
function ReturnInboxItem(i) local m = table.remove(ummInbox, i); table.insert(ummReturns, m and m.subject or "?") end
function TakeInboxItem(i)
  local m = ummInbox[i]
  table.insert(ummTakes, m and m.subject or "?")
  if not m then return end
  later(ummTakeLag, function()
    local money, items = m.money or 0, m.items or {}
    if m.cod and ummMoney < m.cod then return end
    if money > 0 and ummMoney + money > 999999999 then return end   -- nothing arrives, and nothing says so
    local free = {}
    for slot = 1, 60 do
      if #free >= #items then break end
      if not ummBagSlots[slot] then table.insert(free, slot) end
    end
    if #free < #items then return end
    local paid = m.cod
    if paid then setMoney(ummMoney - paid); m.cod = nil end
    for k, item in ipairs(items) do ummItem(free[k], item.name, item.count) end
    m.items, m.money = nil, 0
    if #items > 0 then event("PLAYER_BAG_CHANGED") end
    if money > 0 then setMoney(ummMoney + money) end
    if money > 0 or paid then event("PLAYER_MONEY") end
    event("MAIL_INBOX_UPDATE")
  end)
end

-- ### Frames the game makes and the frame clock ###
local W = getmetatable(UIParent)
function W:SetLayers(level, obj) obj.layer = level end
function W:SetTexture(path) self.texture = path end
function W:SetFont(path, size) self.font, self.fontSize = path, size end
function W:SetJustifyHType(how) self.justify = how end
function W:SetVertexColor(r, g, b) self.color = { r, g, b } end
local focused = nil
function W:SetFocus()
  if focused == self then return end
  if focused then focused:ClearFocus() end
  focused, self.focus = self, true
  UMMFixtureDispatch(self.name, "OnEditFocusGained")
end
function W:ClearFocus()
  self.focus = false
  if focused ~= self then return end
  focused = nil
  UMMFixtureDispatch(self.name, "OnEditFocusLost")
end
function ummFocused() return focused and focused.name end

-- ### Typing, as the client's EditBox does it (ui/core/uieditbox.cpp) ###
-- The caret counts UTF-16 units (a 4-byte UTF-8 character takes 2); only one-line boxes have
-- OnCursorChanged (Modern.xml), with the caret as arg1.
local function chars(text)
  local out = {}
  for ch in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = ch end
  return out
end
local function unitsOf(ch) return #ch == 4 and 2 or 1 end
local function textUnits(text)
  local n = 0
  for _, ch in ipairs(chars(text)) do n = n + unitsOf(ch) end
  return n
end
local function byteAt(text, caret)
  local n, b = 0, 0
  for _, ch in ipairs(chars(text)) do
    if n >= caret then break end
    n, b = n + unitsOf(ch), b + #ch
  end
  return b
end
local function placeCaret(box, caret)
  if caret < 0 or caret > textUnits(box.text) then return end
  box.caret = caret
  arg1, arg2 = caret, 0
  UMMFixtureDispatch(box.name, "OnCursorChanged")
end
function W:HighlightText(first, last)
  first, last = first or 0, last or -1
  if first >= 0 and first <= textUnits(self.text) then self.selStart = first end
  if last == -1 then last = textUnits(self.text) end
  placeCaret(self, last)
end
local function deleteSelection(box)
  local caret, sel = box.caret or 0, box.selStart or 0
  if caret == sel then return false end
  local a, b = math.min(caret, sel), math.max(caret, sel)
  box.text = string.sub(box.text, 1, byteAt(box.text, a))..string.sub(box.text, byteAt(box.text, b) + 1)
  UMMFixtureDispatch(box.name, "OnTextChanged")
  placeCaret(box, a)
  box.selStart = box.caret
  return true
end
-- WM_CHAR (CUiEditBox::OnChar): Backspace, or a character typed at the caret
function ummChar(name, ch)
  local box = _G[name]
  if ch == "\8" then
    if not deleteSelection(box) and (box.caret or 0) > 0 then
      local at = byteAt(box.text, box.caret - 1)
      local gone = string.sub(box.text, at + 1, byteAt(box.text, box.caret))
      box.text = string.sub(box.text, 1, at)..string.sub(box.text, at + #gone + 1)
      UMMFixtureDispatch(name, "OnTextChanged")
      placeCaret(box, box.caret - unitsOf(gone))
      box.selStart = box.caret
    end
    return
  end
  if ch < " " and not (ch == "\n" and box.multiLine) then return end
  if box.numeric and not string.find(ch, "^%d$") then return end
  deleteSelection(box)
  if textUnits(box.text) + unitsOf(ch) > (box.letters or 255) then return end
  local caret = box.caret or 0
  local b = byteAt(box.text, caret)
  box.text = string.sub(box.text, 1, b)..ch..string.sub(box.text, b + 1)
  UMMFixtureDispatch(name, "OnTextChanged")
  placeCaret(box, caret + unitsOf(ch))
  box.selStart = box.caret
end
-- a key pressed in a box: WM_KEYDOWN (OnKeyDown gets the key's name), then the WM_CHAR made of it
function ummKey(name, keyName, ch)
  key = keyName
  UMMFixtureDispatch(name, "OnKeyDown")
  if ch then ummChar(name, ch) end
end
function ummTypeKeys(name, text)
  for _, ch in ipairs(chars(text)) do ummKey(name, ch == "\n" and "ENTER" or "A", ch) end
end
-- Ctrl+Backspace: Windows makes a DEL (0x7F) of it
function ummCtrlBack(name)
  ctrl = true
  ummKey(name, "BACKSPACE", "\127")
  ctrl = false
end
function ummCaret(name) return _G[name].caret or 0, _G[name].selStart or 0 end
function CreateUIComponent(kind, name, parent) return UMMFixtureWidget(kind, name, parent) end
GameTooltip.SetInboxItem = function(self, index, pos) table.insert(ummTips, { index = index, pos = pos }) end

local realDofile = dofile
ummBreak = nil
function dofile(path)
  table.insert(ummDofiles, path)
  if ummBreak and string.find(path, ummBreak, 1, true) then error("broken on purpose") end
  return realDofile(path)
end

local updaters = { "UMMModernLater", "UMMModernMover", "UMMModernMassHover" }
function ummStep(dt)
  dt = dt or 0.05
  ummNow = ummNow + dt
  local i = 1
  while i <= #ummServer do
    local job = ummServer[i]
    if job.at <= ummNow + 1e-9 then table.remove(ummServer, i); job.fn() else i = i + 1 end
  end
  elapsedTime = dt
  UMMMasterFrame_OnUpdate(nil, dt)
  for _, name in ipairs(updaters) do
    local f = _G[name]
    if f and f:IsVisible() then UMMFixtureDispatch(name, "OnUpdate") end
  end
end
function ummRun(seconds)
  for i = 1, math.floor(seconds / 0.05 + 0.5) do ummStep(0.05) end
end
function ummRunUntil(cond, limit)
  local t = 0
  while not cond() do
    if t > limit then return false end
    ummStep(0.05)
    t = t + 0.05
  end
  return true
end

-- visible label texts under a frame, for checking what the window says
function ummTexts(root)
  local out = {}
  for _, w in pairs(ummWidgets) do
    if w.kind == "FontString" and w.text ~= "" and w:IsVisible() then
      local p = w
      while p do
        if p.name == root then table.insert(out, w.text); break end
        p = p.parent and _G[p.parent] or nil
      end
    end
  end
  table.sort(out)
  return out
end
function ummWidgetCount() local n = 0; for _ in pairs(ummWidgets) do n = n + 1 end; return n end

-- the rest of the UMM window that these tests do not build
UMMNewMailButton = { CheckStatus = function() end }
UIPanelBackdropFrame_SetTexture = function() end
UMMNormalBar = { Hide = function() end, Show = function() end, SetStatus = function() end, Init = function() end }
UMMTooltip = { SetHyperLink = function() end, Hide = function() end }
-- Library/ItemDB.lua (550 KB) is read the first time anything is asked of UMMItemDB: what was asked
ummItemDBReads = {}
local itemDB = { GetTypeByID = function(_, id) return "Type"..id end,
  IsItem = function(_, kind, link) return ummCategories[kind] ~= nil and ummCategories[kind][link] == true end }
UMMItemDB = setmetatable({}, { __index = function(_, key) table.insert(ummItemDBReads, key); return itemDB[key] end })
UMMFixtureWidget("Frame", "MailFrame", "UIParent").visible = false
UMMFixtureWidget("Frame", "UMMFrameTab1Tools", "UMMFrameTab1")
local toc = UMMFixtureWidget("Frame", "UMMFrameTab1TOC", "UMMFrameTab1")
for _, name in ipairs({ "HideTOC", "RefreshTOC", "ShowInboxStatus", "Lock", "UnLock" }) do toc[name] = function() end end
'''


class ModernWindowFixture:
    def setUp(self):
        self.h = support.MailShortcutsTests()
        self.h.recipient_lists = True
        self.h.setUp()
        self.lua, self.g = self.h.lua, self.h.g
        self.lua.execute(GAME)
        self.h.load("Library/BagManager.lua")
        self.h.load("Library/MailManager.lua")
        self.h.load("MassSendItems/MassSendItems.lua")
        self.h.load_xml("MassSendItems/MassSendItems.xml")
        self.h.instantiate(ET.fromstring(
            '<Frame xmlns="http://www.runewaker.com/" name="UMMFrameTab3" parent="UMMFrameBody" '
            'inherits="UMMMassSendItemsTemplate" hidden="true"/>'), "UMMFrameBody")
        self.g.UMMPath = str(UMM) + "/"
        self.h.load("Modern/Loader.lua")
        self.h.load_xml("Modern/Modern.xml")
        # the window's frames follow the client's layout and mouse rules (tests/rom_layout.lua)
        self.lua.execute(Path(__file__).with_name("rom_layout.lua").read_text(encoding="utf-8"), name="rom_layout.lua")
        self.lua.execute('RomLayout.Adopt("UMMModernFrame"); local create = CreateUIComponent; '
                         'function CreateUIComponent(kind, name, parent) '
                         'local w = create(kind, name, parent); RomLayout.Created(w); return w end')
        self.g.UMMFrame.visible = False
        self.lua.execute('UMMConfig.Characters = { "Alt1", "Alt2", "Alt3" }; UMMMasterFrame_OnEvent("VARIABLES_LOADED")')

    # ### driving the game ###

    def step(self, seconds=0.05):
        self.g.ummRun(seconds)

    def until(self, condition, limit=120):
        done = self.lua.eval(f"ummRunUntil(function() return {condition} end, {limit})")
        self.assertTrue(done, f"still waiting for: {condition}")

    def open(self):
        self.lua.execute('MailFrame:Show(); UMMMasterFrame_OnEvent("MAIL_SHOW"); UMMMasterFrame_OnEvent("MAIL_INBOX_UPDATE")')
        self.step(0.1)

    def close(self):
        self.lua.execute("MailFrame:Hide()")
        self.step(0.1)

    def click(self, name, key="LBUTTON"):
        self.g.key = key
        self.h.script(name, "OnClick")
        self.step()

    def event(self, name, event):
        self.h.script(name, event)

    def type(self, name, text):
        box = self.g[name]
        box.SetFocus(box)
        box.SetText(box, text)
        self.step()

    def page(self, number):
        self.click(f"UMMModernTab{number}")

    # ### reading the window ###

    def shown(self, name):
        frame = self.g[name]
        return bool(frame.IsVisible(frame))

    def label(self, button):
        return self.g[button].umm.label.text

    def texts(self, root):
        return list(self.g.ummTexts(root).values())

    def status(self):
        return self.g.UMMModern.status.text

    def lua_list(self, name):
        return list(self.lua.eval(name).values())

    def delivered(self, *fields):
        return [tuple(mail[f] for f in fields) for mail in self.lua_list("ummDelivered")]

    def chat(self):
        return self.lua_list("ummMessages")

    def load_errors(self):
        return [text for text in self.chat() if "Ultimate Mail Mod:" in text]

    def inbox(self):
        return [mail.subject for mail in self.lua_list("ummInbox")]


class OpeningTests(ModernWindowFixture, unittest.TestCase):
    def test_mailbox_opens_the_modern_window_and_reads_its_lua_only_once(self):
        self.assertIsNone(self.g.UMMModern)
        self.assertEqual(self.lua_list("ummDofiles"), [])
        self.open()
        self.assertTrue(self.shown("UMMModernFrame"))
        self.assertTrue(self.shown("UMMModernInbox"))
        self.assertFalse(self.shown("UMMFrame"))
        self.assertTrue(self.lua.eval("UMMMailView == UMMModern.View"))
        self.assertEqual([Path(p).name for p in self.lua_list("ummDofiles")], MODERN_FILES)
        self.assertEqual(self.load_errors(), [])
        self.assertEqual(self.g.UMMModern_Status(), "open")
        widgets = self.g.ummWidgetCount()

        self.close()
        self.assertFalse(self.shown("UMMModernFrame"))
        self.assertEqual(self.g.UMMModern_Status(), "loaded")
        self.open()
        self.assertEqual(len(self.lua_list("ummDofiles")), len(MODERN_FILES))
        self.assertEqual(self.g.ummWidgetCount(), widgets, "opening again makes nothing new")
        self.assertEqual(self.load_errors(), [])

    def test_the_bag_grid_is_made_the_first_time_mass_send_opens(self):
        self.open()
        before = self.g.ummWidgetCount()
        self.page(3)
        made = self.g.ummWidgetCount() - before
        self.assertEqual(made, 180 * 5 + 1 + 6,
                         "5 textures and labels per bag slot, the selection box and a rounded panel per bag")
        self.page(1)
        self.page(3)
        self.assertEqual(self.g.ummWidgetCount() - before, made)

    def test_classic_choice_opens_the_classic_window_without_reading_the_modern_lua(self):
        self.g.SlashCmdList["UMM"](None, "ui classic")
        self.assertEqual(self.g.UMMUIStyle(), "classic")
        self.open()
        self.assertEqual(self.lua_list("ummShownPanels"), ["UMMFrame"])
        self.assertFalse(self.shown("UMMModernFrame"))
        self.assertEqual(self.lua_list("ummDofiles"), [])
        self.assertIsNone(self.g.UMMMailView)

        # the settings window's check box switches back
        self.g.UMMSettingsUI_Refresh()
        self.assertTrue(self.g.UMMSettingsFrameCheck5.checked)
        self.h.click("UMMSettingsFrameCheck5")
        self.assertEqual(self.g.UMMUIStyle(), "modern")
        self.assertIn("Mail window: modern. It shows the next time you open a mailbox.", self.chat()[-1])

    def test_a_window_that_fails_to_load_falls_back_to_classic_and_says_so_once(self):
        self.g.ummBreak = "Mass.lua"
        self.open()
        self.assertEqual(self.lua_list("ummShownPanels"), ["UMMFrame"])
        self.assertFalse(self.shown("UMMModernFrame"))
        self.assertIsNone(self.g.UMMModern)
        self.assertIsNone(self.g.UMMMailView)
        errors = self.load_errors()
        self.assertEqual(len(errors), 1)
        self.assertIn("could not load (Mass.lua:", errors[0])
        self.assertTrue(self.g.UMMModern_Status().startswith("failed (Mass.lua"))

        self.g.UMMFrame.visible = False
        self.open()
        self.assertEqual(self.lua_list("ummShownPanels"), ["UMMFrame", "UMMFrame"])
        self.assertEqual(len(self.load_errors()), 1, "said once, not at every mailbox")
        self.assertEqual(len(self.lua_list("ummDofiles")), MODERN_FILES.index("Mass.lua") + 1, "not read again")

    def test_reload_ui_builds_the_window_again_on_the_new_frames(self):
        self.open()
        self.close()
        # Reload UI runs every addon file again in the same Lua state, and the game makes new frames
        self.h.load("Modern/Loader.lua")
        self.assertIsNone(self.g.UMMModern)
        self.assertIsNone(self.g.UMMQueue)
        self.h.load_xml("Modern/Modern.xml")
        self.assertIsNone(self.g.UMMModernInboxTake.umm)
        self.open()
        self.assertTrue(self.shown("UMMModernFrame"))
        self.assertEqual(len(self.lua_list("ummDofiles")), 2 * len(MODERN_FILES))
        self.assertIsNotNone(self.g.UMMModernInboxTake.umm)
        self.assertEqual(self.load_errors(), [])

    def test_a_name_clicked_in_chat_goes_to_compose_or_to_mass_send(self):
        self.open()
        self.assertTrue(self.g.UMMUseClickedName("Pal"))
        self.assertTrue(self.shown("UMMModernCompose"))
        self.assertEqual(self.g.UMMModernComposeTo.text, "Pal")
        self.page(3)
        self.assertTrue(self.g.UMMUseClickedName("Buddy"))
        self.assertTrue(self.shown("UMMModernMass"))
        self.assertEqual(self.g.UMMModernMassTo.text, "Buddy")
        self.assertEqual(self.g.UMMModernComposeTo.text, "Pal")


class InboxTests(ModernWindowFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
          ummMail("Alt1", 5000000, { subject = "Gold for you" })
          ummMail("Pal", 0, { subject = "Stuff", body = "Here you go",
            items = { { name = "Herb", icon = "Icons/Herb", count = 5 }, { name = "Ore", icon = "Icons/Ore", count = 2 } } })
          ummMail("Stranger", 0, { subject = "Hello", body = "Hi there", read = true })
        ''')

    def row(self, i):
        row = self.g[f"UMMModernInboxRow{i}"]
        if not row.IsVisible(row):
            return None
        return row.ummFrom.text, row.ummSubject.text, row.ummMoney.text, row.ummCount.text

    def test_the_list_shows_headers_and_reads_no_mail(self):
        self.open()
        self.assertEqual(self.row(1), ("Alt1", "Gold for you", "5,000,000", ""))
        self.assertEqual(self.row(2), ("Pal", "Stuff", "", "2"))
        self.assertEqual(self.row(3), ("Stranger", "Hello", "", ""))
        self.assertIsNone(self.row(4))
        self.assertIn("3 mails  ·  2 unread  ·  5,000,000 gold", self.texts("UMMModernInbox"))
        self.assertEqual([self.label(f"UMMModernInboxFilter{i}") for i in range(1, 5)],
                         ["All  3", "Gold  1", "Items  1", "Unread  2"])
        self.assertIsNone(self.g.UMMModernInboxFilter5, "diamonds can't be sent by mail: no filter for them")
        self.assertEqual(self.label("UMMModernTab1"), "Inbox  3")
        self.assertEqual(self.status(), "Ready.")

        # an item's tooltip comes from the header: still nothing read
        self.event("UMMModernInboxRow2", "OnEnter")
        self.assertEqual([(tip.index, tip.pos) for tip in self.lua_list("ummTips")], [(2, None)])
        self.assertEqual(self.lua_list("ummReads"), [])

    def test_the_reader_reads_a_mail_only_when_asked(self):
        self.open()
        self.click("UMMModernInboxRow2")
        self.assertTrue(self.shown("UMMModernReaderShow"))
        self.assertFalse(self.shown("UMMModernReaderBody"))
        reader = self.texts("UMMModernReader")
        self.assertIn("Not read yet. The text shows once you read it.", reader)
        self.assertIn("2 items", reader)
        self.assertEqual(self.g.UMMModernReaderItem1.ummIcon.texture, "Icons/Herb")
        self.assertEqual(self.lua_list("ummReads"), [])
        self.assertEqual(self.g.ummInbox[2].days, 29.5)

        self.click("UMMModernReaderShow")
        self.assertIn("Stuff", self.lua_list("ummReads"))
        self.assertLessEqual(self.g.ummInbox[2].days, 3)
        self.assertFalse(self.shown("UMMModernReaderShow"))
        self.assertTrue(self.shown("UMMModernReaderBody"))
        self.assertEqual(self.g.UMMModernReaderBody.text, "Here you go")
        self.assertTrue(self.shown("UMMModernReaderItem2"))
        self.assertEqual(self.g.UMMModernReaderItem2.ummCount.text, "2")
        self.assertEqual(self.g.UMMModernInboxRow2.ummDays.text, "3d")
        self.assertEqual(self.label("UMMModernInboxFilter4"), "Unread  1")

    def test_search_and_who_from_narrow_the_list(self):
        self.open()
        self.type("UMMModernInboxSearch", "pal")
        self.assertEqual(self.row(1)[0], "Pal")
        self.assertIsNone(self.row(2))
        self.type("UMMModernInboxSearch", "")
        self.assertEqual(self.label("UMMModernInboxFrom"), "From: anyone")
        self.click("UMMModernInboxFrom")
        self.assertEqual(self.label("UMMModernInboxFrom"), "From: mine")
        self.assertEqual(self.row(1)[0], "Alt1")
        self.assertIsNone(self.row(2))
        self.click("UMMModernInboxFrom")
        self.assertEqual(self.label("UMMModernInboxFrom"), "From: friends")
        self.assertEqual(self.row(1)[0], "Pal")
        self.assertIsNone(self.row(2))

    def test_reader_take_brings_the_gold_and_keeps_the_emptied_mail_in_view(self):
        self.open()
        self.click("UMMModernInboxRow1")
        self.click("UMMModernReaderTake")
        self.step(0.3)
        self.assertEqual(self.g.ummMoney, 5_000_000)
        self.assertEqual(self.g.UMMModern.gold.text, "5,000,000")
        self.assertIn("Gold for you", self.texts("UMMModernReader"))
        self.assertIn("Nothing attached.", self.texts("UMMModernReader"))
        self.assertTrue(self.g.UMMModernReaderDelete.umm.enabled)
        self.click("UMMModernReaderDelete")
        self.assertEqual(self.inbox(), ["Stuff", "Hello"])
        self.assertIn("Stuff", self.texts("UMMModernReader"), "the next mail moves into the reader")

    def test_reader_take_refuses_gold_past_the_carry_limit(self):
        self.g.ummSetMoney(CAP - 1_000_000)
        self.open()
        self.click("UMMModernInboxRow1")
        self.click("UMMModernReaderTake")
        self.step(0.3)
        self.assertEqual(self.lua_list("ummTakes"), [])
        self.assertEqual(self.status(), "Taking 5,000,000 gold would take this character past 999,999,999.")

    def test_ticked_mails_go_back_and_empty_read_ones_go_away(self):
        self.lua.execute('ummMail("Old", 0, { subject = "Empty", read = true }); ummMail("New", 0, { subject = "Unread empty" })')
        self.open()
        self.assertEqual(self.label("UMMModernInboxDelete"), "Delete 2")
        self.assertEqual(self.label("UMMModernInboxReturn"), "Return 0")
        self.assertFalse(self.g.UMMModernInboxReturn.umm.enabled)
        self.click("UMMModernInboxDelete")
        self.until("not UMMMailManager:IsAutomating()")
        self.assertEqual(self.lua_list("ummDeletes"), ["Hello", "Empty"])
        self.assertEqual(self.status(), "Done.")

        self.click("UMMModernInboxRow2Check")
        self.assertEqual(self.label("UMMModernInboxSelect"), "Untick 1")
        self.assertEqual(self.label("UMMModernInboxReturn"), "Return 1")
        self.click("UMMModernInboxReturn")
        self.until("not UMMMailManager:IsAutomating()")
        self.assertEqual(self.lua_list("ummReturns"), ["Stuff"])
        self.assertEqual(self.inbox(), ["Gold for you", "Unread empty"])

    def test_take_all_leaves_cod_mails_and_gold_past_the_carry_limit(self):
        self.lua.execute('''
          ummInbox = {}
          ummSetMoney(900000000)
          ummMail("Alt1", 50000000, { subject = "A" })
          ummMail("Alt2", 80000000, { subject = "B" })
          ummMail("Pal", 0, { subject = "C", cod = 1000, items = { { name = "Sword", icon = "Icons/Sword" } } })
          ummMail("Pal", 0, { subject = "D", items = { { name = "Herb", icon = "Icons/Herb", count = 3 } } })
          ummMail("Alt3", 30000000, { subject = "E" })
        ''')
        self.open()
        self.assertEqual(self.label("UMMModernInboxTake"), "Take all 3")
        self.click("UMMModernInboxTake")
        self.assertTrue(self.shown("UMMModernStop"))
        self.until("not UMMMailManager:IsAutomating()")
        self.assertEqual(self.lua_list("ummTakes"), ["A", "D", "E"])
        self.assertEqual(self.g.ummMoney, 980_000_000)
        self.assertLessEqual(self.g.ummMaxMoney, CAP)
        self.assertEqual(self.inbox(), ["B", "C"], "the emptied mails were deleted")
        chat = " ".join(self.chat())
        self.assertIn("1 gold mails stay in the inbox: taking them would take this character past 999,999,999 gold.", chat)
        self.assertIn("1 C.O.D. mails stay in the inbox", chat)
        self.assertEqual(self.status(), "Done.")
        self.assertFalse(self.shown("UMMModernStop"))
        self.assertEqual(self.label("UMMModernInboxTake"), "Take all 0")


class FullBagTakeTests(ModernWindowFixture, unittest.TestCase):
    """With the bags full the game takes no mail with items (not even its gold): Take all goes on
    with the gold mails behind it."""

    def setUp(self):
        super().setUp()
        self.lua.execute('''
          for slot = 1, 60 do ummItem(slot, "Stone", 1) end
          ummInbox = {}
          ummMail("Pal", 1000, { subject = "Item first", items = { { name = "Herb", icon = "Icons/Herb" } } })
          ummMail("Alt1", 5000, { subject = "Gold A" })
          ummMail("Alt2", 7000, { subject = "Gold B" })
          -- the client: refuses a mail with items at once when the bags have no room, and says so
          local take = TakeInboxItem
          function TakeInboxItem(i)
            local m = ummInbox[i]
            local used = 0
            for slot = 1, 60 do if ummBagSlots[slot] then used = used + 1 end end
            if m and m.items and #m.items > 60 - used then
              table.insert(ummTakes, "refused "..m.subject)
              UMMMasterFrame_OnEvent("WARNING_MESSAGE", "SYS_GAMEMSGEVENT_750")
              return
            end
            return take(i)
          end
        ''')
        self.money = self.g.ummMoney

    def take_all(self):
        self.open()
        self.click("UMMModernInboxTake")
        self.until("not UMMMailManager:IsAutomating()")

    def check_result(self, takes):
        self.assertEqual(self.lua_list("ummTakes"), takes)
        self.assertEqual(self.g.ummMoney - self.money, 12000)
        self.assertEqual(self.inbox(), ["Item first"])
        self.assertIn("1 mails with items stay in the inbox: the bags have no room for them",
                      " ".join(self.chat()))

    def test_mails_with_items_are_left_when_the_bags_are_counted_full(self):
        self.lua.execute('''
          function GetBagCount()
            local used = 0
            for slot = 1, 60 do if ummBagSlots[slot] then used = used + 1 end end
            return used, 60
          end
        ''')
        self.take_all()
        self.check_result(["Gold A", "Gold B"])

    def test_the_backpack_full_warning_skips_that_mail_and_goes_on(self):
        self.lua.execute("GetBagCount = nil")   # nothing counted ahead: the game's warning decides
        self.take_all()
        self.check_result(["refused Item first", "Gold A", "Gold B"])


class InboxReloadTests(ModernWindowFixture, unittest.TestCase):
    """The game loads the inbox list only when a mailbox opens; the Inbox tab opens it again."""

    def setUp(self):
        super().setUp()
        self.lua.execute('''
          ummMailCalls = {}
          function CloseMail() table.insert(ummMailCalls, "close") end
          function OpenMail() table.insert(ummMailCalls, "open") end
          UMMInboxHookOpenMail()
          ummMail("Alt1", 5000000, { subject = "Gold for you" })
        ''')

    def calls(self):
        return self.lua_list("ummMailCalls")

    def new_mail(self):
        self.lua.execute('ummMail("Pal", 0, { subject = "Late one" }); '
                         'UMMMasterFrame_OnEvent("CHAT_MSG_SYSTEM", "SYS_NEW_MAIL")')
        self.step()

    def test_a_mailbox_opened_from_anywhere_loads_the_list_again_on_the_inbox_tab(self):
        self.lua.execute("OpenMail()")   # the item shop's portable mailbox
        self.open()
        self.assertTrue(self.g.UMMInboxRemote())
        self.assertEqual(self.calls(), ["open"])
        self.new_mail()
        self.assertEqual(self.status(), "New mail came in. Click Inbox to load it.")
        self.step(2.5)
        self.page(1)
        self.assertEqual(self.calls(), ["open", "close", "open"])
        self.assertEqual(self.status(), "Loading inbox - please wait ...")
        self.assertTrue(self.shown("UMMModernFrame"), "the window stays open while the list comes in again")
        self.open()   # the game answers with MAIL_SHOW and the new list
        self.assertTrue(self.g.UMMInboxRemote(), "opened again from anywhere")
        self.assertIn("Late one", self.texts("UMMModernInbox"))
        self.assertEqual(self.status(), "Ready.")
        # not twice in a row within two seconds
        self.page(1)
        self.assertEqual(self.calls(), ["open", "close", "open"])

    def test_at_a_mailbox_in_the_world_the_tab_says_how_to_see_new_mail(self):
        self.open()
        self.assertFalse(self.g.UMMInboxRemote())
        self.new_mail()
        walk = "New mail came while the mailbox was open. Close the mailbox and click it again to see it."
        self.assertEqual(self.status(), walk)
        self.step(2.5)
        self.page(2)
        self.page(1)
        self.assertEqual(self.calls(), [], "CloseMail would end a mailbox in the world")
        self.assertEqual(self.status(), walk)

    def test_nothing_is_reopened_while_mail_goes_out(self):
        self.lua.execute("OpenMail()")
        self.open()
        self.step(2.5)
        self.lua.execute("UMMQueue.Busy = function() return true end")
        self.assertEqual(self.g.UMMInboxReload(), "busy")
        self.assertEqual(self.calls(), ["open"])

    def test_after_reload_ui_an_unanswered_open_mail_does_not_make_a_mailbox_in_the_world_remote(self):
        # an hour in, OpenMail() gets no mailbox (no portable mailbox time left)
        self.lua.execute("UMMClock = 3600; OpenMail()")
        # Reload UI runs the files again in the same Lua state: UMMClock starts again at 0
        self.h.load("Compose/Compose.lua")
        self.h.load("UltimateMailMod.lua")
        self.lua.execute('UMMMasterFrame_OnEvent("VARIABLES_LOADED")')
        self.step(30)
        self.open()   # a mailbox in the world
        self.assertFalse(self.g.UMMInboxRemote())
        self.new_mail()
        self.step(2.5)
        self.page(2)
        self.page(1)
        self.assertEqual(self.calls(), ["open"], "CloseMail would end a mailbox in the world")


class SettingsWindowTests(ModernWindowFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.g.UMMSettingsFrame.Show(self.g.UMMSettingsFrame)

    def value(self, row):
        return self.g[f"UMMSettingsFrameRow{row}Value"].text

    def tip(self, name):
        self.g.GameTooltip.text = None
        self.h.script(name, "OnEnter")
        return self.g.GameTooltip.text, list(self.g.GameTooltip.lines.values()) if self.g.GameTooltip.lines else []

    def test_sections_units_and_default_speeds(self):
        heads = [self.g[f"UMMSettingsFrameHead{n}"].text for n in ("Speed", "Gold", "Window", "Options", "Tools")]
        self.assertEqual(heads, ["Sending speed", "Gold presets", "Mail window", "Options", "Tools"])
        self.assertEqual([self.value(i) for i in range(1, 7)], ["0.2 s", "0.6 s", "20 mails", "5 s", "3x", "1.00"])
        for row in (1, 2, 3, 5):
            self.h.script(f"UMMSettingsFrameRow{row}Plus")
        self.h.script("UMMSettingsFrameRow6Plus")
        for _ in range(5):
            self.h.script("UMMSettingsFrameRow4Minus")
        self.assertEqual([self.value(i) for i in range(1, 7)], ["0.3 s", "0.7 s", "25 mails", "0 s", "4x", "1.05"])
        self.h.script("UMMSettingsFrameSpeedDefaults")
        self.assertEqual([self.value(i) for i in range(1, 7)], ["0.2 s", "0.6 s", "20 mails", "5 s", "3x", "1.05"],
                         "Default speeds leaves the window scale alone")
        for _ in range(4):
            self.h.script("UMMSettingsFrameRow3Minus")
        self.assertEqual(self.value(3), "never")

    def test_every_row_box_and_button_has_a_tooltip(self):
        names = [f"UMMSettingsFrameRow{i}" for i in range(1, 7)] + [f"UMMSettingsFrameCheck{i}" for i in range(1, 7)]
        names += ["UMMSettingsFrame" + n for n in ("SpeedDefaults", "SavePresets", "Check", "Trace", "Defaults", "Reset")]
        for name in names:
            title, lines = self.tip(name)
            self.assertTrue(title and lines and len(lines[0]) > 20, name)
        title, lines = self.tip("UMMSettingsFrameRow2")
        self.assertEqual(title, "Send safely: wait between mails")
        self.assertEqual(lines[1], "Default: 0.6 s. Now: 0.6 s.")
        # the - and + buttons show their row's tooltip
        self.assertEqual(self.tip("UMMSettingsFrameRow2Plus")[0], "Send safely: wait between mails")


class ComposeTests(ModernWindowFixture, unittest.TestCase):
    def review_lines(self):
        return self.texts("UMMModernReviewList")

    def test_seven_inbox_gold_caps_go_to_seven_characters_without_passing_the_limit(self):
        self.lua.execute('ummSetMoney(50000000); for i = 1, 7 do ummMail("Bank", 999999999, { subject = "Cap "..i }) end')
        self.open()
        self.page(2)
        gold = self.texts("UMMModernGold")
        self.assertIn("50,000,000", gold)
        self.assertIn("6,999,999,993 in 7 mails", gold)
        self.assertIn("999,999,999 ×7", gold)

        self.click("UMMModernGoldFill")
        for i in range(1, 8):
            self.assertEqual(self.g[f"UMMModernGoldRow{i}Amount"].text, "999,999,999")
            self.type(f"UMMModernGoldRow{i}To", f"Alt{i}")
        self.assertFalse(self.shown("UMMModernGoldRow8"))
        self.assertEqual(self.label("UMMModernComposeSend"), "Send 8 mails")
        compose = self.texts("UMMModernCompose")
        self.assertIn("8 gold mails, 6,999,999,993 gold", compose)
        self.assertIn("First takes the gold of 7 inbox mails, one at a time.", compose)
        self.assertIn("Total 6,999,999,993 gold in 8 mails", compose)

        self.click("UMMModernComposeSend")
        self.assertTrue(self.shown("UMMModernReview"))
        lines = self.review_lines()
        self.assertIn("1.  50,000,000 gold to Alt7", lines)
        self.assertIn("2.  Take 999,999,999 gold from Bank's mail", lines)
        self.assertIn("3.  999,999,999 gold to Alt1", lines)
        self.assertEqual(self.label("UMMModernReviewGo"), "Send 8 mails")
        self.assertEqual(self.lua_list("ummSent"), [], "nothing goes before Send in the list")

        self.click("UMMModernReviewGo")
        self.assertFalse(self.shown("UMMModernReview"))
        self.until("not UMMQueue:Busy()", 120)
        self.assertEqual(self.delivered("recipient", "money"),
                         [("Alt7", 50_000_000)] + [(f"Alt{i}", CAP) for i in range(1, 7)] + [("Alt7", 949_999_999)])
        self.assertEqual(len(self.lua_list("ummTakes")), 7)
        self.assertEqual(self.g.ummMoney, 50_000_000)
        self.assertLessEqual(self.g.ummMaxMoney, CAP)
        self.assertEqual(self.inbox(), [], "the emptied gold mails were deleted")
        self.assertEqual(self.status(), "Done: 8 of 8 mails sent.")
        self.assertFalse(self.shown("UMMModernGoldRow1"), "the rows went out, so they are gone")

        self.page(4)
        self.assertIn("This session: 8 sent  ·  6,999,999,993 gold sent  ·  7 gold mails taken",
                      self.texts("UMMModernActivity"))

    def test_gold_rows_group_digits_and_say_which_row_is_short(self):
        self.g.ummSetMoney(1_000_000)
        self.open()
        self.page(2)
        self.click("UMMModernGoldAdd")
        self.assertEqual(self.g.ummFocused(), "UMMModernGoldRow1To")
        self.type("UMMModernGoldRow1To", "Alt1")
        self.type("UMMModernGoldRow1Amount", "2500000")
        self.step()
        self.assertEqual(self.g.UMMModernGoldRow1Amount.text, "2,500,000")
        compose = self.texts("UMMModernCompose")
        self.assertIn("Row 1 is 1,500,000 short", compose)
        self.assertIn("Not enough gold: 1,500,000 short, counting this character and the inbox.", compose)
        self.assertFalse(self.g.UMMModernComposeSend.umm.enabled)

        self.type("UMMModernGoldRow1Amount", "400000")
        self.step()
        self.assertEqual(self.g.UMMModernGoldRow1Amount.text, "400,000")
        self.assertTrue(self.g.UMMModernComposeSend.umm.enabled)
        self.click("UMMModernComposeSend")
        self.assertTrue(self.shown("UMMModernReview"), "gold always shows the list first")
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "subject", "money"), [("Alt1", "Money: 400,000", 400_000)])

    def ticked(self, name):
        return self.g[name].umm.icon.texture.endswith("CheckboxOn.tga")

    def test_gold_typed_beside_cod_goes_to_the_to_name(self):
        """In game, gold typed in the box beside C.O.D. was taken as a C.O.D. price and ticked C.O.D.
        by itself, so "Done: 1 of 1 mails sent" went without the gold. That box is the gold for To."""
        self.g.ummSetMoney(600_000_000)
        self.open()
        self.page(2)
        self.g.ummTypeKeys("UMMModernComposeTo", "Alt1")
        self.h.script("UMMModernComposeTo", "OnEnterPressed")
        self.step()
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeMoney", "a name chosen: the gold comes next")
        self.g.ummTypeKeys("UMMModernComposeMoney", "500000000")
        self.step(0.1)   # the commas, then the plan
        money = self.g.UMMModernComposeMoney
        self.assertEqual(money.text, "500,000,000")
        self.assertFalse(self.ticked("UMMModernComposeCOD"), "typing gold never ticks C.O.D.")
        self.assertEqual(self.g.UMMModernComposeSubject.text, "Money: 500,000,000")
        self.assertIn("1 mail to Alt1 (500,000,000 gold)", self.texts("UMMModernCompose"))
        self.assertIn("no gold mails", self.texts("UMMModernGold"), "the right side is for extra gold mails only")
        self.assertEqual(self.label("UMMModernComposeSend"), "Send")

        self.click("UMMModernComposeSend")
        self.assertTrue(self.shown("UMMModernReview"), "gold always shows the list first")
        self.assertEqual(self.review_lines(), ["1.  500,000,000 gold to Alt1"])
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "subject", "money", "cod"),
                         [("Alt1", "Money: 500,000,000", 500_000_000, 0)])
        self.assertEqual(self.status(), "Done: 1 of 1 mails sent.")
        self.assertEqual(money.text, "", "sent: the gold box empties")
        self.assertEqual(self.g.ummMoney, 100_000_000)

    def test_gold_in_the_box_rides_with_the_text_and_extra_rows_add_their_own_mails(self):
        self.g.ummSetMoney(10_000_000)
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        self.type("UMMModernComposeSubject", "Rent")
        self.type("UMMModernComposeBody", "For the house")
        self.type("UMMModernComposeMoney", "2000000")
        self.click("UMMModernGoldAdd")
        self.type("UMMModernGoldRow1To", "Alt2")
        self.type("UMMModernGoldRow1Amount", "300000")
        self.step()
        compose = self.texts("UMMModernCompose")
        self.assertIn("1 mail to Alt1 (2,000,000 gold)  +  1 gold mail, 300,000 gold", compose)
        self.assertIn("Total 300,000 gold in 1 mail", compose, "the panel counts its own rows")
        self.click("UMMModernComposeSend")
        self.assertEqual(self.review_lines(), ["1.  2,000,000 gold to Alt1  + the text", "2.  300,000 gold to Alt2"])
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        # the text and its subject go with the gold for To; an extra gold mail is named by its gold
        self.assertEqual(self.delivered("recipient", "subject", "body", "money"),
                         [("Alt1", "Rent", "For the house", 2_000_000), ("Alt2", "Money: 300,000", "", 300_000)])

    def test_cod_starts_off_never_ticks_itself_and_switching_empties_the_box(self):
        self.lua.execute('ummItem(1, "Herb", 5)')
        self.open()
        self.page(2)
        money = self.g.UMMModernComposeMoney
        self.assertFalse(self.ticked("UMMModernComposeCOD"))
        self.assertEqual(money.ummHint.text, "gold to send")
        self.type("UMMModernComposeTo", "Alt1")
        self.g.ummCursor = 1001
        self.click("UMMModernComposeAdd")
        self.type("UMMModernComposeMoney", "1000")
        self.click("UMMModernComposeCOD")
        self.assertTrue(self.ticked("UMMModernComposeCOD"))
        self.assertEqual(money.text, "", "the gold to send is not a price: switching empties the box")
        self.assertEqual(money.ummHint.text, "C.O.D. price, each item mail")
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeMoney")
        self.type("UMMModernComposeMoney", "2500")
        self.step()
        self.assertIn("C.O.D. 2,500 on each item mail.", self.texts("UMMModernCompose"))
        self.click("UMMModernComposeCOD")
        self.assertFalse(self.ticked("UMMModernComposeCOD"))
        self.assertEqual(money.text, "")
        self.type("UMMModernComposeMoney", "700")
        self.step()
        self.assertFalse(self.ticked("UMMModernComposeCOD"), "and it stays off while gold is typed")
        self.assertEqual(money.text, "700")

        self.click("UMMModernComposeCOD")
        self.type("UMMModernComposeMoney", "2500")
        self.step()
        self.click("UMMModernComposeSend")
        if self.shown("UMMModernReview"):
            self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "item", "money", "cod"), [("Alt1", "Herb", 0, 2500)])

        # closing the mailbox turns it off again
        self.click("UMMModernComposeCOD")
        self.assertTrue(self.ticked("UMMModernComposeCOD"))
        self.close()
        self.open()
        self.page(2)
        self.assertFalse(self.ticked("UMMModernComposeCOD"))
        self.assertEqual(money.ummHint.text, "gold to send")

    def test_the_gold_presets_fill_the_gold_box_and_follow_the_shortcuts_setting(self):
        self.open()
        self.page(2)
        money = self.g.UMMModernComposeMoney
        self.assertEqual(self.label("UMMModernComposePreset1"), "100,000")
        self.assertEqual(self.label("UMMModernComposePreset2"), "1,000,000")
        self.click("UMMModernComposeCOD")
        self.click("UMMModernComposePreset2")
        self.assertFalse(self.ticked("UMMModernComposeCOD"), "a preset is gold to send: C.O.D. goes off")
        self.assertEqual(money.text, "1,000,000")
        self.assertEqual(self.g.UMMModernComposeSubject.text, "Money: 1,000,000")
        self.lua.execute('SlashCmdList.UMM(nil, "gold 250000 2000000")')
        self.assertEqual(self.label("UMMModernComposePreset1"), "250,000", "a changed preset shows at once")
        self.click("UMMModernComposePreset1")
        self.assertEqual(money.text, "250,000")
        self.lua.execute('SlashCmdList.UMM(nil, "shortcuts off")')
        for name in ("UMMModernComposePreset1", "UMMModernComposePreset2", "UMMModernComposeLast"):
            self.assertFalse(self.shown(name), f"{name} follows Mail shortcuts")
        self.page(3)
        self.assertFalse(self.shown("UMMModernMassLast"))
        self.lua.execute('SlashCmdList.UMM(nil, "shortcuts on")')
        self.assertTrue(self.shown("UMMModernMassLast"))
        self.page(2)
        self.assertTrue(self.shown("UMMModernComposePreset1"))

    def test_items_and_long_text_go_as_numbered_mails_to_one_name(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummItem(2, "Ore", 1)')
        text = " ".join(f"line{i:04d}" for i in range(500))
        self.open()
        self.page(2)
        self.g.ummCursor = 1001
        self.click("UMMModernComposeAdd")
        self.assertIsNone(self.g.ummCursor, "the item goes back into its bag slot")
        self.g.ummCursor = 1002
        self.event("UMMModernComposeAdd", "OnReceiveDrag")
        self.step()
        self.assertTrue(self.shown("UMMModernComposeSlot2"))
        self.assertEqual(self.g.UMMModernComposeSlot1.ummCount.text, "5")

        self.type("UMMModernComposeTo", "Alt1")
        self.type("UMMModernComposeSubject", "Hello")
        self.type("UMMModernComposeBody", text)
        compose = self.texts("UMMModernCompose")
        self.assertIn("4,499 letters: 3 mails, numbered in the subject", compose)
        self.assertIn("3 mails to Alt1 (2 with an item, text in 3 parts)", compose)
        self.assertIn("your character", compose)

        self.click("UMMModernComposeSend")
        lines = self.review_lines()
        self.assertEqual(lines, ["1.  Herb (5) to Alt1  + text 1/3", "2.  Ore to Alt1  + text 2/3",
                                 "3.  Text part 3/3 to Alt1"])
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        sent = self.delivered("recipient", "subject", "item")
        self.assertEqual(sent, [("Alt1", "Hello (1/3)", "Herb"), ("Alt1", "Hello (2/3)", "Ore"), ("Alt1", "Hello (3/3)", None)])
        bodies = [body for (body,) in self.delivered("body")]
        self.assertTrue(all(len(body.encode()) <= 2000 for body in bodies))
        self.assertEqual(" ".join(bodies), text)
        self.assertEqual(self.g.UMMModernComposeTo.text, "Alt1", "To stays for the next mail")
        self.assertEqual(self.g.UMMModernComposeBody.text, "")
        self.assertFalse(self.shown("UMMModernComposeSlot1"))
        self.assertEqual(self.g.UMMSettings.LastRecipient(self.g.UMMSettings), "Alt1")

    def test_a_click_that_drops_an_item_adds_it_once_and_a_plain_click_takes_it_out(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummItem(2, "Ore", 1)')
        self.open()
        self.page(2)

        def press(name):
            self.g.key = "LBUTTON"
            for event in ("OnMouseDown", "OnMouseUp", "OnClick"):
                self.event(name, event)
            self.step()

        self.g.ummCursor = 1001
        press("UMMModernComposeAdd")
        self.assertTrue(self.shown("UMMModernComposeSlot1"))
        self.assertFalse(self.shown("UMMModernComposeSlot2"))
        self.assertIsNone(self.g.ummCursor)
        self.g.ummCursor = 1002
        press("UMMModernComposeSlot1")   # a carried item clicked onto an item takes its place
        self.assertEqual(self.g.UMMModernComposeSlot1.ummIcon.texture, "Icons/Ore")
        self.assertFalse(self.shown("UMMModernComposeSlot2"))
        self.assertIsNone(self.g.ummCursor)
        press("UMMModernComposeSlot1")
        self.assertFalse(self.shown("UMMModernComposeSlot1"))
        self.assertIn("Write a mail, drop items on +, or enter gold.", self.texts("UMMModernCompose"))

    def test_an_item_in_the_arcane_transmutor_can_be_dropped_in_and_sent(self):
        # the transmutor keeps its items in body slots 51-60, outside the 180 bag slots
        self.lua.execute('ummItem(1, "Herb", 5); ummBoxItem(53, "Mana Stone", 1)')
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        self.g.ummCursor = 53
        self.click("UMMModernComposeAdd")
        self.assertTrue(self.shown("UMMModernComposeSlot1"))
        self.assertEqual(self.g.UMMModernComposeSlot1.ummIcon.texture, "Icons/Mana Stone")
        self.assertIsNone(self.g.ummCursor, "the item went back into the transmutor")
        self.assertEqual(self.g.UMMModernComposeSubject.text, "Mana Stone")
        self.click("UMMModernComposeSend")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "slot", "item"), [("Alt1", 53, "Mana Stone")])
        self.assertIsNone(self.lua.eval("ummBox[53]"))

    def test_a_transmutor_item_taken_back_to_the_bag_is_sent_from_its_bag_slot(self):
        self.lua.execute('ummBoxItem(51, "Mana Stone", 1)')
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        self.g.ummCursor = 51
        self.click("UMMModernComposeAdd")
        self.assertTrue(self.shown("UMMModernComposeSlot1"))
        # out of the transmutor into bag slot 7
        self.lua.execute('ummBagSlots[7], ummBox[51] = ummBox[51], nil; UMMMasterFrame_OnEvent("PLAYER_BAG_CHANGED")')
        self.step(0.2)
        self.assertTrue(self.shown("UMMModernComposeSlot1"), "the mail followed the item")
        self.click("UMMModernComposeSend")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("slot", "item"), [(1007, "Mana Stone")])

    def test_a_planned_transmutor_item_moved_to_the_bag_before_its_turn_still_goes(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummBoxItem(52, "Mana Stone", 1)')
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        for slot in (1001, 52):
            self.g.ummCursor = slot
            self.click("UMMModernComposeAdd")
        self.click("UMMModernComposeSend")
        self.click("UMMModernReviewGo")
        self.until("#ummDelivered == 1")
        self.lua.execute('ummBagSlots[9], ummBox[52] = ummBox[52], nil')
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("slot", "item"), [(1001, "Herb"), (1009, "Mana Stone")])

    def test_the_subject_takes_the_first_item_or_gold_until_one_is_typed(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummItem(2, "Ore", 1); ummSetMoney(1000000)')
        self.open()
        self.page(2)
        subject = self.g.UMMModernComposeSubject
        self.type("UMMModernComposeTo", "Alt1")
        self.h.script("UMMModernComposeTo", "OnEnterPressed")
        self.step()
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeMoney", "a name chosen: the gold comes next")
        # an item first: its name
        self.g.ummCursor = 1001
        self.click("UMMModernComposeAdd")
        self.step()
        self.assertEqual(subject.text, "Herb (5)")
        self.type("UMMModernComposeMoney", "400000")
        self.step()
        self.assertEqual(subject.text, "Herb (5)", "the item came first")
        # the item taken out: the gold names the mail now, and keeps doing so when an item comes back
        self.click("UMMModernComposeSlot1")
        self.step()
        self.assertEqual(subject.text, "Money: 400,000")
        self.g.ummCursor = 1002
        self.click("UMMModernComposeAdd")
        self.step()
        self.assertEqual(subject.text, "Money: 400,000")
        # clicking in selects it, so typing replaces it; a typed subject stays
        self.g.UMMModernComposeBody.SetFocus(self.g.UMMModernComposeBody)
        subject.SetFocus(subject)
        self.assertEqual((subject.selStart, subject.caret), (0, len("Money: 400,000")))
        self.type("UMMModernComposeSubject", "For the bank")
        self.type("UMMModernComposeMoney", "50000")
        self.step()
        self.assertEqual(subject.text, "For the bank")
        # emptied while typing, it stays empty until the cursor leaves it
        self.type("UMMModernComposeSubject", "")
        self.step()
        self.assertEqual(subject.text, "")
        self.g.UMMModernComposeBody.SetFocus(self.g.UMMModernComposeBody)
        self.step()
        self.assertEqual(subject.text, "Money: 50,000")
        self.click("UMMModernComposeReset")
        self.step()
        self.assertEqual(subject.text, "")

    def test_a_filled_in_subject_leaves_each_item_its_own_name_and_numbers_text_only_mails(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummItem(2, "Ore", 1)')
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        for slot in (1001, 1002):
            self.g.ummCursor = slot
            self.click("UMMModernComposeAdd")
        self.step()
        self.assertEqual(self.g.UMMModernComposeSubject.text, "Herb (5)")
        self.type("UMMModernComposeBody", " ".join(f"line{i:04d}" for i in range(500)))
        self.step()
        self.click("UMMModernComposeSend")
        self.assertEqual(self.review_lines(), ["1.  Herb (5) to Alt1  + text 1/3", "2.  Ore to Alt1  + text 2/3",
                                               "3.  Text part 3/3 to Alt1"])
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("subject", "item"),
                         [("Herb (5)", "Herb"), ("Ore", "Ore"), ("Herb (5) (3/3)", None)])

    def test_a_good_item_clears_the_line_about_one_that_could_not_go(self):
        self.lua.execute('ummItem(1, "Bound Ring", 1); ummItem(2, "Herb", 5); '
                         'UMMMailComposer.ItemIsBound = function(_, index) return index == 1001 end')
        self.open()
        self.page(2)
        self.g.ummCursor = 1001
        self.click("UMMModernComposeAdd")
        self.assertEqual(self.status(), "Bound Ring is bound and can't be mailed.")
        self.assertFalse(self.shown("UMMModernComposeSlot1"))
        self.g.ummCursor = 1002
        self.click("UMMModernComposeAdd")
        self.assertTrue(self.shown("UMMModernComposeSlot1"))
        self.assertEqual(self.status(), "")
        # a line that is about something else stays
        self.g.UMMModern.Status("Done: 3 of 3 mails sent.")
        self.g.ummCursor = 1001
        self.click("UMMModernComposeAdd")
        self.g.UMMModern.Status("Done: 3 of 3 mails sent.")
        self.lua.execute('ummItem(3, "Ore", 1)')
        self.g.ummCursor = 1003
        self.click("UMMModernComposeAdd")
        self.assertEqual(self.status(), "Done: 3 of 3 mails sent.")

    def test_the_name_list_can_wait_for_its_button(self):
        self.g.UMMSettingsFrame.Show(self.g.UMMSettingsFrame)
        self.assertTrue(self.g.UMMSettingsFrameCheck6.checked)
        self.assertEqual(self.g.UMMSettingsFrameCheck6Name.text, "Open name list by itself")
        self.h.click("UMMSettingsFrameCheck6")
        self.assertFalse(self.g.UMMAutoNameList())
        self.open()
        self.page(2)
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeTo")
        self.assertFalse(self.shown("UMMModernPicker"))
        self.type("UMMModernComposeTo", "Pa")
        self.assertFalse(self.shown("UMMModernPicker"))
        self.click("UMMModernComposePick")
        self.assertTrue(self.shown("UMMModernPicker"))
        self.click("UMMModernComposePick")
        self.assertFalse(self.shown("UMMModernPicker"))
        self.page(3)
        self.g.UMMModernMassTo.SetFocus(self.g.UMMModernMassTo)
        self.step()
        self.assertFalse(self.shown("UMMModernPicker"))
        self.close()

        self.lua.execute('SlashCmdList.UMM(nil, "namelist on")')
        self.assertTrue(self.g.UMMAutoNameList())
        self.assertTrue(self.g.UMMSettingsFrameCheck6.checked)
        self.open()
        self.page(2)
        self.g.UMMModernComposeBody.SetFocus(self.g.UMMModernComposeBody)
        self.g.UMMModernComposeTo.SetFocus(self.g.UMMModernComposeTo)
        self.step()
        self.assertTrue(self.shown("UMMModernPicker"))
        self.lua.execute('SlashCmdList.UMM(nil, "namelist off")')
        self.assertFalse(self.g.UMMSettingsFrameCheck6.checked)

    def test_one_plain_mail_goes_without_the_list(self):
        self.open()
        self.page(2)
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeTo", "an empty To gets the cursor")
        self.assertTrue(self.shown("UMMModernPicker"))
        self.type("UMMModernComposeTo", "Pa")
        self.assertEqual(self.g.UMMModernPickerRow1.ummName.text, "Pal")
        self.h.script("UMMModernComposeTo", "OnEnterPressed")
        self.step()
        self.assertEqual(self.g.UMMModernComposeTo.text, "Pal")
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeMoney", "a name chosen: the gold comes next")
        self.type("UMMModernComposeSubject", "Hi")
        self.type("UMMModernComposeBody", "See you tonight")
        self.assertEqual(self.label("UMMModernComposeSend"), "Send")
        self.click("UMMModernComposeSend")
        self.assertFalse(self.shown("UMMModernReview"))
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "subject", "body"), [("Pal", "Hi", "See you tonight")])

    def test_sending_to_this_character_is_stopped_before_it_starts(self):
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "SenderOne")
        self.type("UMMModernComposeSubject", "Me")
        self.assertIn("that is you", self.texts("UMMModernCompose"))
        self.assertIn("You can't send mail to yourself (SenderOne).", self.texts("UMMModernCompose"))
        self.assertFalse(self.g.UMMModernComposeSend.umm.enabled)

    def test_closing_the_mailbox_mid_run_gives_the_item_back_and_keeps_what_was_not_sent(self):
        self.lua.execute('ummItem(1, "Herb", 5); ummItem(2, "Ore", 1); ummItem(3, "Gem", 1)')
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        for slot in (1001, 1002, 1003):
            self.g.ummCursor = slot
            self.click("UMMModernComposeAdd")
        self.click("UMMModernComposeSend")
        self.click("UMMModernReviewGo")
        self.until("#ummDelivered == 1")
        self.until("ummSlot ~= nil")   # the second item sits in the game's send slot
        self.close()
        self.assertFalse(self.g.UMMQueue.Busy(self.g.UMMQueue))
        self.assertIsNone(self.g.ummSlot)
        self.assertIsNone(self.g.ummCursor)
        self.step(1)
        self.assertEqual(len(self.lua_list("ummDelivered")), 1)
        self.open()
        self.page(2)
        self.assertTrue(self.shown("UMMModernComposeSlot2"))
        self.assertFalse(self.shown("UMMModernComposeSlot3"))
        self.assertEqual(self.g.UMMModernComposeTo.text, "Alt1")

    def test_takes_wait_for_gold_the_game_reports_late(self):
        # the gold of a sent mail leaves this character a second after the server said "sent"
        self.lua.execute('ummMoneyLag = 1.0; ummSetMoney(50000000); for i = 1, 3 do ummMail("Bank", 999999999, { subject = "Cap "..i }) end')
        self.open()
        self.page(2)
        self.click("UMMModernGoldFill")
        for i in range(1, 4):
            self.type(f"UMMModernGoldRow{i}To", f"Alt{i}")
        self.click("UMMModernComposeSend")
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()", 120)
        self.step(2)
        self.assertEqual(self.status(), "Done: 4 of 4 mails sent.")
        self.assertEqual(self.g.ummMoney, 50_000_000)
        self.assertLessEqual(self.g.ummMaxMoney, CAP)

    def test_a_take_counts_from_gold_that_left_while_it_was_on_its_way(self):
        # the gold of the mail before the take leaves after the take started, before its gold came
        self.lua.execute('ummMoneyLag = 0.8; ummTakeLag = 0.5; ummSetMoney(100000000); ummMail("Bank", 500000000, { subject = "Big" })')
        self.open()
        self.page(2)
        self.click("UMMModernGoldAdd")
        self.type("UMMModernGoldRow1To", "Alt1")
        self.type("UMMModernGoldRow1Amount", "100000000")
        self.click("UMMModernGoldAdd")
        self.type("UMMModernGoldRow2To", "Alt2")
        self.type("UMMModernGoldRow2Amount", "500000000")
        self.step()
        self.click("UMMModernComposeSend")
        self.assertIn("2.  Take 500,000,000 gold from Bank's mail", self.review_lines())
        self.click("UMMModernReviewGo")
        self.until("not UMMQueue:Busy()", 60)
        self.assertEqual(self.status(), "Done: 2 of 2 mails sent.")
        self.assertEqual(self.delivered("recipient", "money"), [("Alt1", 100_000_000), ("Alt2", 500_000_000)])


class MassSendTests(ModernWindowFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
          ummItem(1, "Herb", 5); ummItem(2, "Herb", 3); ummItem(3, "Ore", 1); ummItem(4, "Gem", 1)
          ummItem(7, "Herb", 2); ummItem(8, "Ring", 1)
        ''')
        self.open()
        self.page(3)
        self.grid = self.g.UMMModernMassGrid

    def point(self, slot, dx=14, dy=14):
        """Where a cell is on the screen: the window is drawn at its scale (UMMModern.Scale)."""
        x, y = self.g.UMMModern.pages.mass.CellPos(slot)
        left, top = self.grid.GetPos(self.grid)
        scale = self.grid.GetRealScale(self.grid)
        return left + (x + dx) * scale, top + (y + dy) * scale

    def press(self, slot, *, ctrl=False, to=None, dx=14, dy=14):
        self.g.ctrl = ctrl
        self.g.cursorX, self.g.cursorY = self.point(slot, dx, dy)
        self.g.key = "LBUTTON"
        self.event("UMMModernMassGrid", "OnMouseDown")
        self.step()
        if to is not None:
            self.g.cursorX, self.g.cursorY = self.point(*to)
            self.step()
        self.event("UMMModernMassGrid", "OnMouseUp")
        self.g.ctrl = False
        self.step()

    def marked(self):
        return {i for i, item in self.g.UMMBagManager.ItemList.items() if item.Marked}

    def test_click_ctrl_click_and_send_one_mail_per_item(self):
        self.press(3)
        self.assertEqual(self.marked(), {3})
        self.press(1, ctrl=True)
        self.assertEqual(self.marked(), {1, 2, 3, 7})
        self.assertEqual(self.g.UMMModernMassMarkedRow1.ummName.text, "Herb")
        self.assertEqual(self.g.UMMModernMassMarkedRow1.ummCount.text, "×3  10")
        self.assertIn("4 marked: enter a name in To.", self.texts("UMMModernMass"))
        self.type("UMMModernMassTo", "Alt1")
        self.assertIn("4 marked: 4 mails to Alt1", self.texts("UMMModernMass"))
        # Send safely and Send fast are both up, whatever the number of mails
        self.assertEqual(self.label("UMMModernMassSend"), "Send safely 4")
        self.assertTrue(self.shown("UMMModernMassFast"))

        self.click("UMMModernMassSend")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "subject", "item"),
                         [("Alt1", "Herb (5)", "Herb"), ("Alt1", "Herb (3)", "Herb"), ("Alt1", "Ore", "Ore"),
                          ("Alt1", "Herb (2)", "Herb")])
        self.step(0.5)
        self.assertEqual(self.marked(), set())
        self.assertEqual(self.status(), "Done: 4 of 4 mails sent.")
        self.assertIn("Nothing marked. Click items, drag a box, or click a category under the bags.", self.texts("UMMModernMass"))

    def test_a_box_marks_what_it_covers_and_a_click_on_marked_unmarks(self):
        self.press(1, dx=4, dy=4, to=(8, 4, 4))
        self.assertEqual(self.marked(), {1, 2, 7, 8})
        self.assertFalse(self.g.UMMModern.Dragging())
        self.press(2)
        self.assertEqual(self.marked(), {1, 7, 8})
        self.click("UMMModernMassMarkedRow1")   # the Herb group: unmarks every Herb
        self.assertEqual(self.marked(), {8})

    def test_a_category_marks_its_items_and_search_with_enter_marks_by_name(self):
        self.lua.execute('ummCategories.Type5 = { [ummBagSlots[4].link] = true }')
        self.click("UMMModernMassCat5")
        self.assertEqual(self.marked(), {4})
        self.type("UMMModernMassSearch", "her")
        self.assertEqual(self.g.UMMModernMassMarkedRow1.ummName.text, "Gem")
        self.h.script("UMMModernMassSearch", "OnEnterPressed")
        self.step()
        self.assertEqual(self.marked(), {1, 2, 4, 7})

    def box(self, i):
        return self.g[f"UMMModernMassCat{i}"]

    def test_category_boxes_sit_in_two_rows_of_18_under_the_bag_columns(self):
        gx, gy = self.grid.GetPos(self.grid)
        _, grid_h = self.grid.GetRealSize(self.grid)
        send_top = self.g.UMMModernMassSend.GetPos(self.g.UMMModernMassSend)[1]
        rows = set()
        for i in range(1, 37):
            box = self.box(i)
            self.assertTrue(self.shown(f"UMMModernMassCat{i}"))
            x, y = box.GetPos(box)
            w, h = box.GetRealSize(box)
            col = (i - 1) % 18
            slot = (3 + col // 6) * 30 + 24 + col % 6 + 1      # the bottom slot of the bag column above
            self.assertAlmostEqual(x + w / 2, self.point(slot)[0], places=4, msg=f"box {i}")
            self.assertGreater(y, gy + grid_h)
            self.assertLessEqual(y + h, send_top)
            rows.add(round(y, 3))
        self.assertEqual(len(rows), 2)
        # the summary moved to the side column, under the marked list and beside the Send button
        self.assertIn("Nothing marked. Click items, drag a box, or click a category under the bags.",
                      self.texts("UMMModernMass"))
        sx, sy = self.lua.eval('''(function()
          for _, w in pairs(ummWidgets) do
            if w.kind == "FontString" and w.text == UMM_M_MS_NONE then return { w:GetPos() } end
          end
        end)()''').values()
        last = self.g.UMMModernMassMarkedRow14
        lx, ly = last.GetPos(last)
        _, lh = last.GetRealSize(last)
        self.assertGreaterEqual(sx, lx)
        self.assertGreaterEqual(sy, ly + lh)

    def test_boxes_show_pictures_and_tags_and_the_item_list_is_read_only_on_a_click(self):
        icon = lambda i: self.box(i).umm.icon.texture
        # this client has no GetObjImage: pictures from Interface/icons
        self.assertEqual(icon(1), "Interface/icons/runes_stone01_01")
        self.assertEqual(icon(10), "Interface/icons/icon-default")
        self.assertIsNone(self.box(1).ummTag)
        self.assertEqual(self.box(27).ummTag.text, "Fi")
        self.assertEqual(self.box(13).ummTag.text, "Alc")
        self.assertNotEqual(tuple(self.box(27).ummTag.color.values()), tuple(self.box(29).ummTag.color.values()))
        self.assertEqual(self.label("UMMModernMassCat36"), "All")
        self.assertIsNone(self.box(36).umm.icon)
        tip = lambda i: list(self.box(i).ummTip(self.box(i)).values())
        self.assertEqual(tip(3), ["Fusion Stones", "Click to mark every item of this kind in your bags."])
        self.assertEqual(tip(36), ["All categories", "Click to mark every item of all the kinds here."])
        self.g.UMM_MSI_RECIPE_SEND_TO14 = "Cook"
        self.assertEqual(tip(14)[2], "Fills an empty To with Cook (Recipient/Characters.lua).")
        # opening the page read nothing from the 550 KB item list; a click does
        self.assertEqual(self.lua_list("ummItemDBReads"), [])
        self.lua.execute('ummCategories.Type27 = { [ummBagSlots[8].link] = true }')
        self.click("UMMModernMassCat27")
        self.assertEqual(self.marked(), {8})
        self.assertIn("GetTypeByID", self.lua_list("ummItemDBReads"))

    def test_all_marks_every_kind_and_the_boxes_rest_while_a_send_runs(self):
        self.lua.execute('ummCategories.Type3 = { [ummBagSlots[4].link] = true }; '
                         'ummCategories.Type20 = { [ummBagSlots[3].link] = true }')
        self.click("UMMModernMassCat36")
        self.assertEqual(self.marked(), {3, 4})
        self.type("UMMModernMassTo", "Alt1")
        self.click("UMMModernMassSend")
        self.assertTrue(self.lua.eval("UMMQueue:Busy()"))
        self.assertFalse(self.box(1).umm.enabled)
        self.assertFalse(self.box(36).umm.enabled)
        self.until("not UMMQueue:Busy()")
        self.step(0.5)
        self.assertTrue(self.box(1).umm.enabled)
        self.assertTrue(self.box(36).umm.enabled)


    def test_cod_is_off_until_ticked_and_its_price_box_shows_only_then(self):
        def ticked():
            return self.g.UMMModernMassCOD.umm.icon.texture.endswith("CheckboxOn.tga")

        price = "UMMModernMassCODAmount"
        self.assertFalse(ticked())
        self.assertFalse(self.shown(price))
        self.press(3)
        self.type("UMMModernMassTo", "Alt1")
        self.click("UMMModernMassCOD")
        self.assertTrue(ticked())
        self.assertTrue(self.shown(price))
        self.assertEqual(self.g.ummFocused(), price)
        self.assertFalse(self.g.UMMModernMassSend.umm.enabled, "no price yet")
        self.type(price, "5000")
        self.step()
        self.assertEqual(self.g[price].text, "5,000")
        self.assertTrue(self.g.UMMModernMassSend.umm.enabled)
        self.click("UMMModernMassCOD")
        self.assertFalse(ticked())
        self.assertFalse(self.shown(price))
        self.assertEqual(self.g[price].text, "", "unticked: the price goes")
        self.assertTrue(self.g.UMMModernMassSend.umm.enabled)

        self.click("UMMModernMassCOD")
        self.type(price, "5000")
        self.click("UMMModernMassSend")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("item", "cod"), [("Ore", 5000)])
        self.close()
        self.open()
        self.page(3)
        self.assertFalse(ticked(), "closing the mailbox turns C.O.D. off")
        self.assertFalse(self.shown(price))

    def test_forty_or_more_offers_safe_and_fast(self):
        self.lua.execute('for slot = 10, 54 do ummItem(slot, "Arrow", 99) end; UMMMasterFrame_OnEvent("PLAYER_BAG_CHANGED")')
        self.step(0.3)
        self.assertEqual(self.g.UMMModernMassGrid and self.g.UMMBagManager.ItemList[54].Name, "Arrow")
        self.press(10, ctrl=True)
        self.type("UMMModernMassTo", "Alt2")
        self.assertEqual(self.label("UMMModernMassSend"), "Send safely 45")
        self.assertTrue(self.shown("UMMModernMassFast"))
        self.assertTrue(self.g.UMMModernMassFast.umm.enabled)


class MassCategoryIconTests(ModernWindowFixture, unittest.TestCase):
    def test_boxes_use_the_game_icon_of_their_item_and_fall_back_when_it_has_none(self):
        self.lua.execute('''
          ummObjImages = {}
          function GetObjImage(id)
            table.insert(ummObjImages, id)
            if id == 520021 then return "interface/icons/rune_power_01" end
            if id == 202882 then error("no such object") end
            return ""
          end''')
        self.open()
        self.click("UMMModernTab3")
        icon = lambda i: self.g[f"UMMModernMassCat{i}"].umm.icon.texture
        self.assertEqual(icon(1), "interface/icons/rune_power_01")
        self.assertEqual(icon(3), "Interface/icons/fusion_stone001")     # GetObjImage failed
        self.assertEqual(icon(4), "Interface/icons/mana stone10")        # GetObjImage had no picture
        self.assertEqual(len(self.lua.eval("ummObjImages")), 35)

class CtrlBackspaceTests(ModernWindowFixture, unittest.TestCase):
    """Ctrl+Backspace, which the client lacks: gold goes back to the last comma, a name goes whole,
    text a word at a time. For it the client types a DEL (0x7F) in a text box and nothing in a
    number box, and places the caret only after the text handler (tests: ummCtrlBack, ummChar)."""

    def setUp(self):
        super().setUp()
        self.open()
        self.page(2)

    def back(self, name):
        self.g.ummCtrlBack(name)
        self.step(0.2)
        text = self.g[name].text
        self.assertNotIn("\x7f", text)
        return text

    def caret(self, name):
        return tuple(self.g.ummCaret(name))

    def focus(self, name):
        box = self.g[name]
        box.SetFocus(box)

    def test_gold_goes_back_a_comma_group_at_a_time(self):
        self.g.ummSetMoney(600_000_000)
        self.g.ummTypeKeys("UMMModernComposeTo", "Alt1")
        name = "UMMModernComposeMoney"
        self.focus(name)
        self.g.ummTypeKeys(name, "500000000")
        self.step()
        self.assertEqual(self.g[name].text, "500,000,000")
        self.assertEqual(self.back(name), "500,000")
        self.assertEqual(self.caret(name), (7, 7))
        self.assertIn("1 mail to Alt1 (500,000 gold)", self.texts("UMMModernCompose"), "the plan follows")
        self.assertEqual(self.g.UMMModernComposeSubject.text, "Money: 500,000")
        self.assertEqual(self.back(name), "500")
        self.assertEqual(self.back(name), "")
        self.assertEqual(self.back(name), "", "nothing left: nothing happens")
        self.assertEqual(self.g[name].ummHint.text, "gold to send")
        # typing goes on where the caret is
        self.g.ummTypeKeys(name, "12345")
        self.step()
        self.assertEqual(self.g[name].text, "12,345")
        # plain Backspace is still one digit
        self.g.ummKey(name, "BACKSPACE", "\b")
        self.step()
        self.assertEqual(self.g[name].text, "1,234")

    def test_gold_with_the_caret_inside_takes_the_digits_back_to_the_comma_before_it(self):
        name = "UMMModernComposeMoney"
        self.focus(name)
        self.g.ummTypeKeys(name, "1234567")
        self.step()
        box = self.g[name]
        box.HighlightText(box, 7, 7)                   # 1,234,5|67
        self.assertEqual(self.back(name), "123,467")
        self.assertEqual(self.caret(name), (5, 5))     # 123,4|67
        box.HighlightText(box, 4, 4)                   # 123,|467: the comma and the group before it
        self.assertEqual(self.back(name), "467")
        self.assertEqual(self.caret(name), (0, 0))
        self.g.ummTypeKeys(name, "1000")
        self.step()
        self.assertEqual(box.text, "1,000,467")
        box.HighlightText(box, 1, 1)                   # 1|,000,467: no zeros left in front
        self.assertEqual(self.back(name), "467")

    def test_gold_selected_on_the_way_in_empties_at_once(self):
        name = "UMMModernComposeMoney"
        self.type(name, "2500000")
        self.step()
        self.focus("UMMModernComposeSubject")
        self.focus(name)                               # selected on the way in
        self.assertEqual(self.caret(name), (9, 0))
        self.assertEqual(self.back(name), "")
        # an extra gold row and Mass send's C.O.D. price work the same way
        self.click("UMMModernGoldAdd")
        row = "UMMModernGoldRow1Amount"
        self.focus(row)
        self.g.ummTypeKeys(row, "75000")
        self.step()
        self.assertEqual(self.back(row), "75")
        self.page(3)
        self.click("UMMModernMassCOD")
        self.g.ummTypeKeys("UMMModernMassCODAmount", "1500")
        self.step()
        self.assertEqual(self.back("UMMModernMassCODAmount"), "1")

    def test_a_name_goes_whole_wherever_the_caret_is(self):
        name = "UMMModernComposeTo"
        self.assertEqual(self.g.ummFocused(), name)
        self.g.ummTypeKeys(name, "Alt1")
        self.assertEqual(self.g.UMMModernPickerRow1.ummName.text, "Alt1")
        box = self.g[name]
        box.HighlightText(box, 2, 2)
        self.assertEqual(self.back(name), "")
        self.assertEqual(box.ummHint.text, "Name")
        self.assertTrue(self.shown("UMMModernPicker"), "the list shows every name again")
        self.click("UMMModernGoldAdd")
        self.g.ummTypeKeys("UMMModernGoldRow1To", "Alt2")
        self.assertEqual(self.back("UMMModernGoldRow1To"), "")
        self.page(3)
        self.focus("UMMModernMassTo")
        self.g.ummTypeKeys("UMMModernMassTo", "Pal")
        self.assertEqual(self.back("UMMModernMassTo"), "")

    def test_text_goes_a_word_at_a_time(self):
        name = "UMMModernComposeSubject"
        self.focus(name)
        self.g.ummTypeKeys(name, "Grüße an alle  ")
        self.assertEqual(self.back(name), "Grüße an ")
        self.assertEqual(self.caret(name), (9, 9), "the caret counts letters, not bytes")
        self.assertEqual(self.back(name), "Grüße ")
        self.assertEqual(self.back(name), "")
        self.g.ummTypeKeys(name, "one two three")
        box = self.g[name]
        box.HighlightText(box, 7, 7)                   # one two| three
        self.assertEqual(self.back(name), "one  three")
        self.assertEqual(self.caret(name), (4, 4))
        box.HighlightText(box, 0, 3)                   # a selection goes, and only the selection
        self.assertEqual(self.back(name), "  three")
        self.assertEqual(self.caret(name), (0, 0))

    def test_the_text_box_goes_back_a_line_break_or_a_word(self):
        name = "UMMModernComposeBody"
        self.focus(name)
        self.g.ummTypeKeys(name, "first line\nsecond")
        self.assertEqual(self.back(name), "first line\n")
        self.assertEqual(self.back(name), "first line")
        self.assertEqual(self.back(name), "first ")
        self.assertIn("6 / 2,000", self.texts("UMMModernCompose"), "the counter follows")

    def test_a_late_del_or_a_full_box_still_takes_one_word(self):
        name = "UMMModernComposeSubject"
        self.focus(name)
        self.g.ummTypeKeys(name, "one two")
        # the DEL a frame after the key: one word, not two
        self.g.ctrl = True
        self.g.ummKey(name, "BACKSPACE")
        self.g.ctrl = False
        self.step()
        self.g.ummChar(name, "\x7f")
        self.step(0.2)
        self.assertEqual(self.g[name].text, "one ")
        # a full box has no room for the DEL: the caret it was given says where
        self.lua.execute(f"{name}.letters = 7")
        self.g.ummTypeKeys(name, "two")
        self.assertEqual(self.g[name].text, "one two")
        self.assertEqual(self.back(name), "one ")

    def test_the_rules(self):
        back = self.g.UMMModern.CtrlBack
        self.assertEqual(tuple(back("gold", "999,999,999", 11)), ("999,999", 7))
        self.assertEqual(tuple(back("gold", "999,999,999", 0)), ("999,999,999", 0))
        self.assertEqual(tuple(back("gold", "5", 1)), ("", 0))
        self.assertEqual(tuple(back("name", "Somebody", 3)), ("", 0))
        self.assertEqual(tuple(back("text", "a  b\t", 6)), ("a  ", 3))
        self.assertEqual(tuple(back("text", "x\n\n", 3)), ("x\n", 2))
        self.assertEqual(tuple(back("text", "line\n  ", 7)), ("line\n", 5))
        units, nbytes = self.g.UMMModern.TextUnits, self.g.UMMModern.TextBytes
        self.assertEqual(units("añ😀b", 7), 4, "ñ is one unit, the emoji two")
        self.assertEqual(units("añ😀b", 8), 5)
        self.assertEqual(nbytes("añ😀b", 4), 7)
        self.assertEqual(nbytes("añ😀b", 99), 8)


class LayoutTests(ModernWindowFixture, unittest.TestCase):
    """The window under the client's own layout and mouse rules (tests/rom_layout.lua).

    In game, frames declared without a size kept snapping back to their parent's size, and a clicked
    frame is lifted above its siblings: after one click a tab the size of the screen took every click,
    and the edit boxes' borders showed as bars across the bottom of the screen.
    """
    PAGES = ["inbox", "compose", "mass", "activity"]

    def frames(self):
        return self.lua.eval('''(function()
          local out = {}
          for name, w in pairs(ummWidgets) do
            if w.rl and w.kind ~= "Texture" and w.kind ~= "FontString" and string.find(name, "^UMMModern") then
              out[name] = w
            end
          end
          return out end)()''')

    def window_rect(self):
        f = self.g.UMMModernFrame
        x, y = f.GetPos(f)
        w, h = f.GetRealSize(f)
        return x, y, x + w, y + h

    def scale(self):
        f = self.g.UMMModernFrame
        return f.GetRealScale(f)

    def center(self, name):
        return self.g.RomLayout.Center(self.g[name])

    def click_at(self, x, y):
        name = self.g.RomLayout.Click(x, y)
        self.step()
        return name

    def click_on(self, name):
        x, y = self.center(name)
        return self.click_at(x, y)

    def drag_title(self, dx, dy):
        left, top, _, _ = self.window_rect()
        x, y = left + 660 * self.scale(), top + 18 * self.scale()   # the title bar, past the gold
        self.assertEqual(self.g.RomLayout.Down(x, y), "UMMModernTitle")
        self.step()
        self.g.cursorX, self.g.cursorY = x + dx, y + dy
        self.step()
        self.g.RomLayout.Up(x + dx, y + dy)
        self.step()

    def assert_sizes_hold(self):
        """Every frame is the size Lua last gave it, and nothing visible reaches past the window."""
        left, top, right, bottom = self.window_rect()
        for name, w in self.frames().items():
            if w.rl.luaW is not None:
                self.assertEqual((w.width, w.height), (w.rl.luaW, w.rl.luaH), f"{name} lost its size")
            else:
                self.assertLessEqual(w.width * w.height, 1, f"{name} took a size nobody gave it")
            if w.IsVisible(w) and name != "UMMModernFrame":
                x, y = w.GetPos(w)
                rw, rh = w.GetRealSize(w)
                self.assertTrue(left <= x + 1e-6 and y + 1e-6 >= top and x + rw <= right + 1e-6 and y + rh <= bottom + 1e-6,
                                f"{name} reaches past the window: {(x, y, rw, rh)}")

    def test_frames_keep_their_sizes_when_the_window_moves_and_the_screen_lays_out_again(self):
        self.open()
        self.assert_sizes_hold()
        self.drag_title(-120, 40)
        self.assert_sizes_hold()
        for page in self.PAGES:
            self.g.UMMModern.ShowPage(page)
            self.step()
            self.g.RomLayout.Relayout()      # what Cherry's Bar's lift or a resolution change does
            self.assert_sizes_hold()

    def test_tabs_take_every_click_whatever_was_clicked_before(self):
        self.open()
        for order in ([2, 3, 4, 1], [1, 4, 2, 3, 1]):
            for i in order:
                self.assertEqual(self.click_on(f"UMMModernTab{i}"), f"UMMModernTab{i}")
                self.assertEqual(self.g.UMMModern.page, self.PAGES[i - 1])
        # the title bar's drag area lies under the tabs; a click on it must not lift it over them
        self.drag_title(0, 0)
        self.drag_title(30, 10)
        for i in (3, 1, 2):
            self.assertEqual(self.click_on(f"UMMModernTab{i}"), f"UMMModernTab{i}")
            self.assertEqual(self.g.UMMModern.page, self.PAGES[i - 1])
        # clicks inside a page lift that page's frames, never above the tabs
        self.assertEqual(self.click_on("UMMModernComposeTo"), "UMMModernComposeTo")
        self.assertEqual(self.click_on("UMMModernGoldAdd"), "UMMModernGoldAdd")
        self.assertEqual(self.click_on("UMMModernTab1"), "UMMModernTab1")
        self.assertEqual(self.click_on("UMMModernInboxFilter2"), "UMMModernInboxFilter2")
        self.assertEqual(self.click_on("UMMModernInboxSearch"), "UMMModernInboxSearch")
        self.assertEqual(self.click_on("UMMModernTab4"), "UMMModernTab4")
        self.assertEqual(self.g.UMMModern.page, "activity")
        self.assertEqual(self.click_on("UMMModernGear"), "UMMModernGear")
        self.assertEqual(self.click_on("UMMModernClose"), "UMMModernClose")
        self.assertFalse(self.shown("UMMModernFrame"))

    def test_nothing_outside_the_window_takes_the_mouse(self):
        self.open()
        for i in (2, 3, 4, 1):
            self.click_on(f"UMMModernTab{i}")
        self.drag_title(-50, 20)
        self.g.RomLayout.Relayout()
        left, top, right, bottom = self.window_rect()
        outside = [(x, bottom + 4) for x in range(int(left), int(right), 37)]
        outside += [(right + 4, y) for y in range(int(top), int(bottom), 31)]
        outside += [(right + 300, bottom + 200), (1900, 1060), (left - 4, top + 50), (left + 100, top - 4)]
        for x, y in outside:
            hit = self.g.RomLayout.FrameAt(x, y)
            self.assertTrue(hit is None or hit.name == "UIParent", f"{hit and hit.name} takes the mouse at {(x, y)}")

    def test_no_two_frames_that_take_the_mouse_overlap_on_any_page(self):
        """The client lifts a clicked frame over its siblings of the same strata and level, so two
        overlapping ones would swap places after a click. Only the title bar's drag area lies under
        other frames, at a lower frame level."""
        self.open()
        for page in self.PAGES:
            self.g.UMMModern.ShowPage(page)
            self.step()
            overlaps = self.lua.eval('''(function()
              local out = {}
              local function rect(w)
                local x, y = w:GetPos(); local rw, rh = w:GetRealSize()
                return x + 1e-6, y + 1e-6, x + rw - 1e-6, y + rh - 1e-6
              end
              local function walk(f)
                local live = {}
                for _, c in ipairs(f.rl.children) do
                  if c.visible then
                    if c.mouse and c.width * c.height > 1 then table.insert(live, c) end
                    walk(c)
                  end
                end
                for i = 1, #live do
                  for j = i + 1, #live do
                    local a, b = live[i], live[j]
                    if a.rl.strata == b.rl.strata and a.rl.level == b.rl.level then
                      local ax, ay, ar, ab = rect(a)
                      local bx, by, br, bb = rect(b)
                      if ax < br and bx < ar and ay < bb and by < ab then
                        table.insert(out, a.name .. " / " .. b.name)
                      end
                    end
                  end
                end
              end
              walk(UMMModernFrame)
              return out end)()''')
            self.assertEqual(list(overlaps.values()), [], page)

    def scale_command(self, value):
        self.lua.execute(f'SlashCmdList.UMM(nil, "scale {value}")')
        self.step()

    def test_scale_one_draws_the_layout_at_one_point_two_and_the_setting_resizes_it_at_once(self):
        self.open()
        self.assertAlmostEqual(self.scale(), 1.2)
        left, top, right, bottom = self.window_rect()
        self.assertAlmostEqual(right - left, 912)
        self.assertAlmostEqual(bottom - top, 600)
        self.assertEqual((left, top), (504, 90), "centred, near the top of a 1920 x 1080 screen")
        self.drag_title(-100, 30)
        self.assertEqual(self.window_rect()[:2], (404, 120))

        # the settings window's scale row, one step up: bigger at once, same top left corner
        self.g.UMMSettingsFrame.Show(self.g.UMMSettingsFrame)
        self.assertEqual(self.g.UMMSettingsFrameRow6Label.text, "Mail window scale")
        self.assertEqual(self.g.UMMSettingsFrameRow6Value.text, "1.00")
        self.h.script("UMMSettingsFrameRow6Plus")
        self.step()
        self.assertEqual(self.g.UMMSettingsFrameRow6Value.text, "1.05")
        self.assertAlmostEqual(self.scale(), 1.26)
        left, top, right, bottom = self.window_rect()
        self.assertAlmostEqual(left, 404)
        self.assertAlmostEqual(top, 120)
        self.assertAlmostEqual(right - left, 957.6)
        self.assert_sizes_hold()

        # /umm scale, with a decimal comma too; out of range changes nothing
        self.scale_command("1,5")
        self.assertAlmostEqual(self.scale(), 1.8)
        self.assertEqual(self.g.UMMSettingsFrameRow6Value.text, "1.50")
        self.assertTrue(any("mail window scale: 1.50 (/umm scale 0.7 - 1.5)" in line for line in self.chat()))
        self.scale_command("2")
        self.assertAlmostEqual(self.scale(), 1.8)
        self.assertTrue(any("/umm scale <0.7 - 1.5>" in line for line in self.chat()))
        self.assertAlmostEqual(self.window_rect()[0], 404)

        # grown past the right edge of the screen, it moves back in whole
        self.scale_command("1")
        self.drag_title(700, 0)
        self.assertAlmostEqual(self.window_rect()[2], 1920, msg="dragged as far right as it goes")
        self.scale_command("1.5")
        left, _, right, _ = self.window_rect()
        self.assertAlmostEqual(right, 1920)
        self.assertAlmostEqual(left, 1920 - 760 * 1.8)

        # shut and opened again smaller: where it was dragged to, at the scale of the setting
        self.close()
        self.scale_command("0.7")
        self.open()
        self.assertAlmostEqual(self.scale(), 0.84)
        left, top, _, _ = self.window_rect()
        self.assertAlmostEqual(left, 1008)
        self.assertAlmostEqual(top, 120)
        self.assert_sizes_hold()

    def test_the_smallest_and_the_biggest_scale_keep_the_layout_and_every_click(self):
        for setting in ("0.7", "1.5"):
            with self.subTest(setting=setting):
                self.scale_command(setting)
                self.open()
                self.assertAlmostEqual(self.scale(), 1.2 * float(setting))
                self.assert_sizes_hold()
                for i in (2, 3, 4, 1):
                    self.assertEqual(self.click_on(f"UMMModernTab{i}"), f"UMMModernTab{i}")
                    self.assert_sizes_hold()
                self.drag_title(-40, 25)
                self.g.RomLayout.Relayout()
                self.assert_sizes_hold()
                left, top, right, bottom = self.window_rect()
                for x, y in [(right + 3, top + 40), (left + 40, bottom + 3), (left - 3, top + 40)]:
                    hit = self.g.RomLayout.FrameAt(x, y)
                    self.assertTrue(hit is None or hit.name == "UIParent", f"{hit and hit.name} at {(x, y)}")
                self.close()

    def test_the_title_bar_starts_with_the_inbox_tab_and_the_gold_follows_the_tabs(self):
        self.open()
        left, top, _, _ = self.window_rect()
        s = self.scale()

        def x_in_window(widget):
            x, _ = widget.GetPos(widget)
            return round((x - left) / s, 6)

        self.assertEqual([x_in_window(self.g[f"UMMModernTab{i}"]) for i in range(1, 5)], [8, 126, 244, 362])
        self.assertTrue(self.label("UMMModernTab1").startswith("Inbox"))
        self.assertNotIn("Mail", self.texts("UMMModernFrame"), "no window title")
        last = self.g.UMMModernTab4
        self.assertGreater(x_in_window(self.g.UMMModern.gold), x_in_window(last) + last.width)
        self.assertEqual(self.click_on("UMMModernTab1"), "UMMModernTab1")

    def box(self, name):
        """A frame's place and size in window units."""
        left, top, _, _ = self.window_rect()
        s = self.scale()
        w = self.g[name]
        x, y = w.GetPos(w)
        width, height = w.GetRealSize(w)
        return round((x - left) / s, 6), round((y - top) / s, 6), round(width / s, 6), round(height / s, 6)

    def test_tick_all_joins_the_filters_take_all_takes_its_place_and_the_bottom_row_moves_left(self):
        self.lua.execute('ummMail("Bank", 1000)')
        self.open()
        row = [self.box(f"UMMModernInboxFilter{i}") for i in range(1, 5)]
        row += [self.box("UMMModernInboxSelect"), self.box("UMMModernInboxFrom")]
        self.assertEqual(len({b[1] for b in row}), 1, "All, Gold, Items, Unread, Tick all, From: one row")
        for a, b in zip(row, row[1:]):
            self.assertEqual(b[0] - (a[0] + a[2]), 4, "left to right, 4 apart")
        search, take, who = self.box("UMMModernInboxSearch"), self.box("UMMModernInboxTake"), row[-1]
        self.assertEqual(take[1], search[1], "Take all is where Tick all was, beside the search")
        self.assertEqual(take[0] - (search[0] + search[2]), 4)
        self.assertEqual((take[0], take[2]), (who[0], who[2]), "right under From, as wide")
        bottom = [self.box(n) for n in ("UMMModernInboxClean", "UMMModernInboxDelete", "UMMModernInboxReturn")]
        self.assertEqual(bottom[0][0], search[0], "Delete emptied starts the bottom row now")
        for a, b in zip(bottom, bottom[1:]):
            self.assertEqual(b[0] - (a[0] + a[2]), 4, "Delete emptied, Delete, then Return last")
        self.assertEqual(bottom[-1][0] + bottom[-1][2], search[0] + search[2])
        for name in ("UMMModernInboxSelect", "UMMModernInboxFrom", "UMMModernInboxTake", "UMMModernInboxClean",
                     "UMMModernInboxDelete", "UMMModernInboxReturn"):
            self.assertEqual(self.g.RomLayout.FrameAt(*self.center(name)).name, name)
        # a click just past Delete emptied lands on nothing
        clean = self.g.UMMModernInboxClean
        x, y = clean.GetPos(clean)
        w, h = clean.GetRealSize(clean)
        self.assertNotIn(self.click_at(x + w + 2 * self.scale(), y + h / 2),
                         ("UMMModernInboxDelete", "UMMModernInboxReturn"))
        self.assertEqual(self.inbox(), ["Mail 1"], "nothing went")

    def test_the_open_name_list_leaves_the_items_gold_box_and_presets_free(self):
        self.lua.execute('ummItem(1, "Herb", 5)')
        self.open()
        self.page(2)
        self.assertTrue(self.shown("UMMModernPicker"))
        picker = self.g.UMMModernPicker
        px, py = picker.GetPos(picker)
        pw, ph = picker.GetRealSize(picker)
        free = ["UMMModernComposeAdd", "UMMModernComposeCOD", "UMMModernComposeMoney", "UMMModernComposePreset1",
                "UMMModernComposePreset2", "UMMModernComposeSend"]
        for name in free:
            w = self.g[name]
            _, y = w.GetPos(w)
            self.assertGreaterEqual(y, py + ph, f"{name} is under the name list")
        money, cod = self.box("UMMModernComposeMoney"), self.box("UMMModernComposeCOD")
        presets = [self.box(f"UMMModernComposePreset{i}") for i in (1, 2)]
        self.assertEqual({money[1], presets[0][1], presets[1][1]}, {money[1]}, "the presets sit beside the gold")
        self.assertLess(cod[0], money[0])
        self.assertLess(money[0] + money[2], presets[0][0])
        self.g.ummCursor = 1001
        self.assertEqual(self.click_on("UMMModernComposeAdd"), "UMMModernComposeAdd")
        self.assertTrue(self.shown("UMMModernComposeSlot1"))
        slot = self.g.UMMModernComposeSlot1
        self.assertGreaterEqual(slot.GetPos(slot)[1], py + ph)
        self.assertEqual(self.click_on("UMMModernComposePreset1"), "UMMModernComposePreset1")
        self.assertEqual(self.g.UMMModernComposeMoney.text, "100,000")
        self.assertEqual(self.click_on("UMMModernComposeCOD"), "UMMModernComposeCOD")
        self.assertEqual(self.g.ummFocused(), "UMMModernComposeMoney")

    def test_the_review_list_takes_its_clicks(self):
        self.g.ummSetMoney(1_000_000)
        self.open()
        self.page(2)
        self.type("UMMModernComposeTo", "Alt1")
        self.type("UMMModernComposeMoney", "1000")
        self.step()
        self.click("UMMModernComposeSend")
        self.assertTrue(self.shown("UMMModernReview"))
        self.assertEqual(self.click_on("UMMModernReviewBack"), "UMMModernReviewBack")
        self.assertFalse(self.shown("UMMModernReview"))
        self.assertEqual(self.lua_list("ummSent"), [])
        self.click("UMMModernComposeSend")
        self.assertEqual(self.click_on("UMMModernReviewGo"), "UMMModernReviewGo")
        self.until("not UMMQueue:Busy()")
        self.assertEqual(self.delivered("recipient", "money"), [("Alt1", 1000)])

    def test_mass_send_bags_are_rounded_like_the_game_bags(self):
        self.open()
        self.page(3)
        textures = self.lua.eval('''(function()
          local out = {}
          for _, w in pairs(ummWidgets) do
            if w.kind == "Texture" and w.parent == "UMMModernMassGrid" and w.texture then
              local file = string.match(w.texture, "([^/\\\\]+)%.tga$") or w.texture
              out[file] = (out[file] or 0) + 1
            end
          end
          return out end)()''')
        counts = dict(textures.items())
        self.assertEqual(counts.get("bagpanel"), 6, "one rounded panel per bag")
        self.assertEqual(counts.get("slot"), 180, "a rounded slot under every cell")
        self.assertEqual(counts.get("round-32-32"), 180, "and a rounded mark over it")
        for name in ("bagpanel", "slot", "round-32-32"):
            self.assertTrue((UMM / "Textures" / "Modern" / f"{name}.tga").is_file())


class PlanTests(ModernWindowFixture, unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.assertTrue(self.g.UMMModern_Load())
        self.P = self.g.UMMModern.Plan

    def parts(self, text, limit=None):
        return list(self.P.SplitBody(text, limit).values())

    def test_long_text_splits_at_spaces_and_lines_and_never_inside_a_letter(self):
        text = " ".join(f"line{i:04d}" for i in range(500))
        parts = self.parts(text)
        self.assertEqual(len(parts), 3)
        self.assertTrue(all(len(part) <= 2000 for part in parts))
        self.assertEqual(" ".join(parts), text)

        lines = "\n".join("x" * 99 for _ in range(30))   # 2999 bytes in lines of 100
        parts = self.parts(lines)
        self.assertEqual("\n".join(parts), lines)
        self.assertTrue(all(not part.startswith("\n") and len(part) <= 2000 for part in parts))

        accents = "é" * 1500   # 3000 bytes, no space anywhere
        raw = self.P.SplitBody(accents)
        pieces = [raw[i] for i in range(1, len(raw) + 1)]
        self.assertTrue(all(len(piece.encode("utf-8")) <= 2000 for piece in pieces))
        self.assertEqual("".join(pieces), accents)
        self.assertEqual(self.parts(""), [""])

    def test_gold_rows_use_gold_on_hand_first_when_it_blocks_every_inbox_mail(self):
        steps, short, hand = self.lua.eval('''
          (function()
            local rows, pool = {}, {}
            for i = 1, 3 do rows[i] = { to = "Alt"..i, amount = 999999999 } end
            for i = 1, 3 do pool[i] = { sender = "Bank", money = 999999999, subject = "Cap "..i } end
            return UMMModern.Plan.Gold(rows, 50000000, pool)
          end)()''')
        kinds = [(s.kind, s.to or s.subject, s.money) for s in steps.values()]
        self.assertEqual(kinds, [("mail", "Alt3", 50_000_000), ("take", "Cap 1", CAP), ("mail", "Alt1", CAP),
                                 ("take", "Cap 2", CAP), ("mail", "Alt2", CAP), ("take", "Cap 3", CAP),
                                 ("mail", "Alt3", 949_999_999)])
        self.assertEqual(dict(short.items()), {})
        self.assertEqual(hand, 50_000_000)

    def test_a_row_that_can_not_be_paid_is_named(self):
        plan = self.lua.eval('''UMMModern.Plan.Compose({ to = "", gold = {
            { to = "Alt1", amount = 600000000, row = 1 }, { to = "Alt2", amount = 600000000, row = 2 } } },
          { hand = 100000000, pool = { { sender = "Bank", money = 500000000, subject = "Big" } }, player = "SenderOne" })''')
        self.assertEqual(dict(plan.shortRows.items()), {2: 600_000_000})
        self.assertEqual(list(plan.errors.values()),
                         ["Not enough gold: 600,000,000 short, counting this character and the inbox."])

    def test_a_short_note_rides_in_the_gold_mail_and_missing_parts_are_named(self):
        plan = self.lua.eval('''UMMModern.Plan.Compose({ to = "Alt1", subject = "Rent", body = "for May",
          gold = { { to = "", amount = 1000, row = 1 } } }, { hand = 5000, player = "SenderOne" })''')
        steps = list(plan.steps.values())
        self.assertEqual([(s.to, s.subject, s.body, s.money) for s in steps], [("Alt1", "Rent", "for May", 1000)])
        self.assertEqual(plan.mails, 1)

        def errors(form):
            return list(self.lua.eval(f'UMMModern.Plan.Compose({form}, {{ hand = 0, player = "SenderOne" }})').errors.values())
        self.assertEqual(errors('{ to = "Alt1", subject = "", body = "text" }'), ["Enter a subject."])
        self.assertEqual(errors('{ to = "", subject = "Hi", body = "" }'), ["Enter a name in To."])
        self.assertEqual(errors('{ to = "senderone", subject = "Hi" }'), ["You can't send mail to yourself (senderone)."])
        self.assertEqual(errors('{ to = "Alt1" }'), ["Nothing to send yet: write a mail, add an item, or enter gold."])


class ModernXmlTests(unittest.TestCase):
    def test_modern_xml_is_what_the_generator_writes(self):
        spec = importlib.util.spec_from_file_location("gen_umm_modern_xml", ROOT / "tools/gen_umm_modern_xml.py")
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        self.assertEqual((UMM / "Modern/Modern.xml").read_text(encoding="utf-8"), generator.build())

    def test_modern_xml_holds_bare_frames_whose_handlers_all_go_through_the_loader(self):
        root = ET.parse(UMM / "Modern/Modern.xml").getroot()
        handlers = 0
        parents = {child: parent for parent in root.iter() for child in parent}
        for element in root.iter():
            tag = element.tag.split("}")[-1]
            # no art and no positions: Modern/Core.lua draws and places everything
            self.assertNotIn(tag, {"Layers", "Layer", "Texture", "Anchors", "Backdrop"})
            if tag == "FontString":   # only the text font of the multi-line template
                self.assertEqual(parents[element].get("name"), "UMMModernBodyTemplate")
            if tag.startswith("On"):
                handlers += 1
                self.assertTrue(element.text.startswith("UMMModern_On("), element.text)
        self.assertGreater(handlers, 30)

    def test_every_frame_has_a_size_so_the_client_never_ties_it_to_its_parent(self):
        # Without a <Size> the client gives a frame anchor size 0 x 0, "as big as my parent", and
        # puts it back to its parent's size whenever what it hangs from moves (CUiLayout::ResetSize).
        root = ET.parse(UMM / "Modern/Modern.xml").getroot()
        templates = {e.get("name"): e for e in root if e.get("virtual") == "true"}

        def sized(element):
            size = element.find("ui:Size/ui:AbsDimension", support.NS)
            if size is not None:
                return float(size.get("x")) > 0 and float(size.get("y")) > 0
            base = templates.get(element.get("inherits"))   # the game's own templates do not count
            return base is not None and sized(base)

        frames = [e for e in root.iter() if e.tag.split("}")[-1] in ("Frame", "Button", "EditBox")]
        self.assertGreater(len(frames), 150)
        for element in frames:
            self.assertTrue(sized(element), element.get("name"))

    def test_the_title_bar_buttons_sit_above_its_drag_area(self):
        root = ET.parse(UMM / "Modern/Modern.xml").getroot()
        level = {e.get("name"): int(e.get("frameLevel", 0)) for e in root.iter() if e.get("name")}
        for name in ("UMMModernTab1", "UMMModernTab2", "UMMModernTab3", "UMMModernTab4", "UMMModernGear",
                     "UMMModernClose", "UMMModernStop"):
            self.assertGreater(level[name], level["UMMModernTitle"], name)
        # and every edit box takes the mouse itself: an XML frame does only when told to
        for template in ("UMMModernEditTemplate", "UMMModernGoldTemplate", "UMMModernBodyTemplate"):
            element = next(e for e in root if e.get("name") == template)
            self.assertEqual(element.get("enableMouse"), "true", template)

    def test_the_toc_loads_only_the_loader_and_the_frames(self):
        toc = (ROOT / "Interface/AddOns/CherrysKit/CherrysKit.toc").read_text(encoding="utf-8")
        modern = [line.strip() for line in toc.splitlines() if "UltimateMailMod/Modern/" in line]
        self.assertEqual(modern, ["UltimateMailMod/Modern/Loader.lua", "UltimateMailMod/Modern/Modern.xml"])
        loader = (UMM / "Modern/Loader.lua").read_text(encoding="utf-8")
        for name in MODERN_FILES:
            self.assertIn(f'"{name[:-4]}"', loader)
            self.assertTrue((UMM / "Modern" / name).exists())


if __name__ == "__main__":
    unittest.main()
