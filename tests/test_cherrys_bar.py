"""Cherry's Bar: bars, displays, position controls, settings, throttling and hub links in a fake client."""

import hashlib
import json
from pathlib import Path
import re
import struct
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface/AddOns/CherrysKit"
SOURCE = KIT / "CherrysBar"
FILES = ("Core.lua", "Bars.lua", "Displays.lua", "DisplayList.lua", "Menu.lua", "Options.lua", "Probe.lua", "Perf.lua")
NS = "{http://www.runewaker.com/}"
SKINS = ("Ironstone", "Blacksteel", "Froststeel", "Darkwood", "Verdant", "Arcane", "Slate")

CLIENT = r'''
messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, text) messages[#messages + 1] = text end }
calls = { bag = 0, ping = 0, opened = {}, volume = {} }
now, inCombat, zone = 100, false, "Varanas"
uiScale = 1
cursor = { 300, 12 }
volume = 80
state = { used = 10, total = 60, gold = 1234567, fps = 60, ping = 40, xp = 500, xpMax = 1000 }
os = nil  -- the game's Lua has no os library
function GetTime() return now end
function GetTickCount() return math.floor(now * 1000) end
function GetUIScale() return uiScale end
function GetCursorPos() return cursor[1], cursor[2] end
function GetScreenWidth() return 1024 end
function UnitName() return "Cherry" end
function UnitClass() return "Warrior", "Mage" end
function UnitLevel() return 80, 70 end
function UnitHealth() return 1 end
function UnitExists() return true end
function GetPlayerCombatState() return inCombat end
function TEXT(key) return key end
function GetPlayerExp() return state.xp end
function GetPlayerMaxExp() return state.xpMax end
function GetTpExp() return 42 end
function GetTotalTpExp() return 1000 end
function GetPlayerExpDebt() return 0, 0 end
function GetBagCount() calls.bag = calls.bag + 1; return state.used, state.total end
function GetGoodsItemInfo() calls.goods = (calls.goods or 0) + 1; return "icon", "name", 0 end
function GetBagItemCount() calls.currency = (calls.currency or 0) + 1; return 3 end
function GetCountInBankByName() return 2 end
function GetPlayerMoney(kind) return kind == "copper" and state.gold or 5 end
function GetFramerate() calls.ping = calls.ping + 1; return state.fps end
function GetPing() return state.ping end
function GetZoneName() return zone end
function GetPlayerWorldMapPos() return 0.123, 0.456 end
function GetFriendCount() return 2 end
function GetFriendInfo(_, i) return "Friend" .. i, 1, i == 1 end
function GetNumGuildMembers() return 0 end
function GetGuildRosterInfo() end
function GetGuildInfo() return "Guild" end
function GetInventoryItemDurable() return 90, 100, "Arrows" end
function GetInventoryItemCount() return 100 end
function GetCountInBagByName() return 5 end
function GetPlayerCurrentSkillValue() return 3.5 end
function Daily_count() return 3, 10 end
function GetNumQuestBookButton_QuestBook() return 0 end
function GetQuestInfo() end
function GetPlayerPointInfo() return 7 end
function GetPlayerGoodEvil() return 0 end
function TimeLet_GetLetTime() return 1 end
function OpenMail() calls.opened[#calls.opened + 1] = "mail" end
function OpenBank() calls.opened[#calls.opened + 1] = "bank" end
function ToggleUIFrame(frame) calls.opened[#calls.opened + 1] = frame:GetName() end
function ToggleCharacter(name) calls.opened[#calls.opened + 1] = name end
function ToggleSocialFrame() end
function ToggleGameMenu() end
function InviteByName() end
function ChatFrame_SendTell() end
function StaticPopup_Show() end
function MasterVolumeSlider_GetValue() return volume end
function MasterVolumeSlider_SetValue(v) volume = v end
-- The client's slider runs 0 to 100 in whole numbers.
SYS_AudioSettings_MasterVolumeSlider = { SetValue = function(self, v) self.value = math.floor(v + 0.5) end }

local Widget = {}
Widget.__index = Widget
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:IsVisible() return self.shown end
function Widget:SetText(t) self.text = t; self.setTexts = (self.setTexts or 0) + 1 end
function Widget:GetText() return self.text end
function Widget:GetName() return self.name end
function Widget:ClearAllAnchors() self.anchors = {} end
function Widget:SetAnchor(p, rp, rel, x, y)
  self.anchors = self.anchors or {}
  self.anchors[#self.anchors + 1] = { p, rp, rel, x, y }
end
function Widget:GetAnchor()
  local a = self.anchors and self.anchors[1]
  if a then return a[1], a[2], a[3], a[4], a[5] end
end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
-- A font string with no size takes the width of its text.
function Widget:GetWidth()
  if self.text then return #string.gsub(string.gsub(self.text, "|c%x%x%x%x%x%x%x%x", ""), "|r", "") * 6 end
  return self.w or 1600
end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetTexture(t) self.texture = t end
function Widget:SetChecked(v) self.checked = v end
function Widget:GetFont() return "fonts/game.ttf", 12 end
function Widget:SetFont(path, size) self.fontSize = size end
function Widget:GetPos() return self.posX or 100, self.posY or 0 end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function Widget:UnregisterEvent(e) self.events = self.events or {}; self.events[e] = nil end
function MakeWidget(name, shown)
  _G[name] = setmetatable({ name = name, shown = shown }, Widget)
  return _G[name]
end
function GameFrame(name, x, y, point)
  local f = MakeWidget(name, true)
  f:SetAnchor(point or "TOPLEFT", point or "TOPLEFT", "UIParent", x, y)
  return f
end
GameFrame("PlayerFrame", 0, 0)
GameFrame("TargetFrame", -64, 2, "TOP")
GameFrame("PlayerBuffButton1", -200, 10, "TOPRIGHT")
GameFrame("UnitFrame_party1", 2, 118)
GameFrame("MinimapFrame", -12, 32, "TOPRIGHT")
GameFrame("MinimapFrameBorder", 0, -1, "TOPRIGHT")
MakeWidget("WorldFrame", true)
MakeWidget("UIParent", true)
UIParent:SetAnchor("TOPLEFT", "TOPLEFT", "WorldFrame", 0, 0)
UIParent:SetAnchor("BOTTOMRIGHT", "BOTTOMRIGHT", "WorldFrame", 0, 0)
function UIParent:GetHeight()
  local a = self.anchors and self.anchors[2]
  return 1000 + (a and a[5] or 0)
end
GameFrame("MainMenuFrame", 0, 0, "BOTTOM")
GameFrame("MainActionBarFrame", -96, -16, "BOTTOMRIGHT")
GameFrame("ChatFrame1", 0, -36, "BOTTOMLEFT")
GameFrame("PlayerFramePartyBoardButton", 308, 30)
GameFrame("PetBookFrameButton", 138, 98)
GameFrame("HouseFrame", 0, 0)
GameFrame("ExperienceFrame", 0, 0, "BOTTOMLEFT")
MakeWidget("EquipDameFrame", true)
MakeWidget("BagFrame", false)
MakeWidget("WorldMapFrame", false)
MakeWidget("UI_QuestBook", false)
GameTooltip = MakeWidget("GameTooltip", false)
function GameTooltip:SetOwner() end
function GameTooltip:AddLine(t) self.lines = self.lines or {}; self.lines[#self.lines + 1] = t end
function GameTooltip:AddDoubleLine(a, b) self.lines = self.lines or {}; self.lines[#self.lines + 1] = a .. "=" .. tostring(b) end
function frameOf(key) return _G['CBar_D' .. CherrysBar.Displays.byKey[key].slot] end
function chipOf(key) return _G['CBar_Chip' .. CherrysBar.Displays.byKey[key].slot] end
function row(bar, side)
  local out = {}
  for i, def in ipairs(CherrysBar.Displays.Row(bar, side)) do out[i] = def.key end
  return table.concat(out, ",")
end
function cfg(key) return CherrysBar.Displays.Config(CherrysBar.Displays.byKey[key]) end
'''


def xml_names():
    tree = ET.parse(SOURCE / "CherrysBar.xml")
    return [el.get("name") for el in tree.iter() if el.get("name") and "$" not in el.get("name")
            and el.get("virtual") != "true"]


class BarTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        make = self.lua.globals().MakeWidget
        for name in xml_names():
            make(name, False)
        self.load_addon()

    def load_addon(self):
        for name in FILES:
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8"))
        self.lua.execute("CherrysBar.OnLoad(CBar_Events); CherrysBar.OnEvent('VARIABLES_LOADED'); CherrysBar.OnUpdate(0)")

    def ev(self, code):
        return self.lua.eval(code)

    def run_lua(self, code):
        self.lua.execute(code)

    def tick(self, seconds=0.3):
        self.run_lua(f"now = now + {seconds}; CherrysBar.OnUpdate({seconds})")

    def text_of(self, key):
        return self.ev(f"CherrysBar.Displays.byKey.{key}.shownText")

    def anchor_y(self, frame):
        return self.ev(f"select(5, {frame}:GetAnchor())")

    def menu_rows(self):
        return {self.ev(f"CBar_MenuRow{i}Text.text"): i for i in range(1, 25) if self.ev(f"CBar_MenuRow{i}.shown")}

    # Bars

    def test_default_is_top_bar_only_with_its_displays(self):
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.assertFalse(self.ev("CBar_BarBottom.shown"))
        for key in ("Menu", "Exp", "Bag", "Money", "Mail", "Perf", "Clock"):
            self.assertTrue(self.ev(f"frameOf('{key}').shown"), key)
        for key in ("Wallet", "Zone", "Friends", "Guild", "Ammo", "Repair", "Dps", "Daily", "Class", "Craft", "Volume"):
            self.assertFalse(self.ev(f"frameOf('{key}').shown"), key)

    def test_bars_draw_cherrys_art_in_tiles_on_their_own_edge(self):
        self.run_lua("CherrysBar.Command('both')")
        self.assertEqual(self.ev("CBar_BarTop.anchors[1][1]"), "TOPLEFT")
        self.assertEqual(self.ev("CBar_BarBottom.anchors[1][1]"), "BOTTOMLEFT")
        for i in range(1, 17):
            self.assertIn("Skins/Ironstone/top", self.ev(f"CBar_BarTopT{i}.texture"))
            self.assertIn("Skins/Ironstone/bottom", self.ev(f"CBar_BarBottomT{i}.texture"))
        self.assertEqual(self.ev("CBar_BarTop.h"), 24)
        self.assertEqual(self.ev("CBar_BarTopT1.h"), 24)
        self.assertEqual(self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Bag.slot .. 'Icon'].w"), 16)

    def test_what_sits_on_a_bar_clears_the_rail(self):
        self.run_lua("CherrysBar.Command('both'); local D = CherrysBar.Displays; D.SetBar(D.byKey.Zone, 'bottom')")
        self.assertEqual(self.ev("frameOf('Bag').anchors[1][5]"), -2)
        self.assertEqual(self.ev("frameOf('Zone').anchors[1][5]"), 2)

    def test_bar_height_moves_everything_with_it(self):
        self.run_lua("CherrysBar.S().bars.top.makeRoom = true; CherrysBar.S().barHeight = 34; CherrysBar.Refresh()")
        self.assertEqual(self.ev("CBar_BarTop.h"), 34)
        self.assertEqual(self.ev("frameOf('Bag').h"), 34)
        self.assertEqual(self.anchor_y("PlayerFrame"), 34)

    def test_commands_choose_bars(self):
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertFalse(self.ev("CBar_BarTop.shown"))
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.run_lua("CherrysBar.Command('top')")
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.assertFalse(self.ev("CBar_BarBottom.shown"))

    # Position controls

    def test_displays_are_set_per_bar_and_flow_without_overlap(self):
        self.run_lua("""
            CherrysBar.Command('both')
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Zone, 'bottom')
            D.SetBar(D.byKey.Friends, 'bottom')
            function right_edge(key) local f = frameOf(key); return f.anchors[1][4] + f.w end
            function left_edge(key) return frameOf(key).anchors[1][4] end
        """)
        self.assertEqual(self.ev("frameOf('Zone').anchors[1][3]"), "CBar_BarBottom")
        self.assertEqual(self.ev("frameOf('Bag').anchors[1][3]"), "CBar_BarTop")
        self.assertGreaterEqual(self.ev("left_edge('Friends')"), self.ev("right_edge('Zone')"))
        self.assertGreaterEqual(self.ev("left_edge('Bag')"), self.ev("right_edge('Exp')"))
        self.assertEqual(self.ev("frameOf('Clock').anchors[1][1]"), "RIGHT")

    def test_stepping_reaches_every_place_and_crosses_the_gap(self):
        step = "CherrysBar.Displays.Step(CherrysBar.Displays.byKey.Money, {})"
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")
        self.run_lua(step.format(-1))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Money,Bag")
        self.run_lua(step.format(1))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")
        self.run_lua(step.format(1))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag")
        self.assertEqual(self.ev("row('top', 'right')"), "Money,Mail,Perf,Clock")
        self.run_lua(step.format(-1))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")
        for _ in range(3):
            self.run_lua(step.format(-1))
        self.assertEqual(self.ev("row('top', 'left')"), "Money,Menu,Exp,Bag")
        self.run_lua(step.format(-1))  # already at the far left
        self.assertEqual(self.ev("row('top', 'left')"), "Money,Menu,Exp,Bag")

    def test_order_survives_rebuild(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Step(D.byKey.Bag, -1)
            D.Rebuild()
        """)
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Bag,Exp,Money")

    def test_a_display_sent_to_a_bar_that_is_off_brings_the_bar(self):
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Bag, 'bottom')")
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.assertTrue(self.ev("frameOf('Bag').shown"))
        self.assertEqual(self.ev("row('bottom', 'left')"), "Bag")

    def test_locked_displays_do_not_drag(self):
        self.run_lua("local D = CherrysBar.Displays; D.MouseDown(D.byKey.Bag.slot, 'LBUTTON')")
        self.assertFalse(self.ev("frameOf('Bag').moving"))

    def test_unlocking_shows_handles_and_grips_and_makes_room_for_them(self):
        self.assertFalse(self.ev("CBar_PinTop.shown"))
        self.assertFalse(self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Bag.slot .. 'Grip'].shown"))
        right_before = self.ev("frameOf('Clock').anchors[1][4]")
        self.run_lua("CherrysBar.Command('unlock')")
        self.assertTrue(self.ev("CBar_PinTop.shown"))
        self.assertTrue(self.ev("CBar_LockTop.shown"))
        self.assertTrue(self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Bag.slot .. 'Grip'].shown"))
        self.assertLess(self.ev("frameOf('Clock').anchors[1][4]"), right_before)
        self.run_lua("CherrysBar.Bars.SetLocked(true)")
        self.assertFalse(self.ev("CBar_LockTop.shown"))

    def test_dragging_a_display_along_a_bar_and_to_the_other_side(self):
        self.run_lua("""
            CherrysBar.Command('unlock')
            local D = CherrysBar.Displays
            -- on screen: Menu at 10, Exp at 80, Bag at 160, Money at 240; the screen is 1600 wide
            for key, x in pairs({ Menu = 10, Exp = 80, Bag = 160, Money = 240, Mail = 1300, Perf = 1400, Clock = 1500 }) do
              frameOf(key).posX, frameOf(key).posY = x, 0
            end
            slot = D.byKey.Money.slot
            D.MouseDown(slot, 'LBUTTON')
        """)
        self.assertTrue(self.ev("frameOf('Money').moving"))
        self.run_lua("frameOf('Money').posX = 40; CherrysBar.Displays.MouseUp(slot, 'LBUTTON')")
        self.assertFalse(self.ev("frameOf('Money').moving"))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Money,Exp,Bag")
        self.run_lua("""
            local D = CherrysBar.Displays
            for key, x in pairs({ Menu = 10, Money = 80, Exp = 160, Bag = 240 }) do frameOf(key).posX = x end
            D.MouseDown(D.byKey.Bag.slot, 'LBUTTON')
            frameOf('Bag').posX = 1450
            D.MouseUp(D.byKey.Bag.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Money,Exp")
        self.assertEqual(self.ev("row('top', 'right')"), "Mail,Perf,Bag,Clock")

    def test_dragging_to_the_other_bar(self):
        self.run_lua("""
            CherrysBar.Command('both')
            CherrysBar.Command('unlock')
            CBar_BarTop.posX, CBar_BarTop.posY = 0, 0
            CBar_BarBottom.posX, CBar_BarBottom.posY = 0, 1000
            local D = CherrysBar.Displays
            frameOf('Bag').posX, frameOf('Bag').posY = 160, 0
            D.MouseDown(D.byKey.Bag.slot, 'LBUTTON')
            frameOf('Bag').posY = 990
            D.MouseUp(D.byKey.Bag.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("cfg('Bag').bar"), "bottom")
        self.assertEqual(self.ev("frameOf('Bag').anchors[1][3]"), "CBar_BarBottom")

    def test_a_press_without_moving_is_still_a_click(self):
        self.run_lua("""
            CherrysBar.Command('unlock')
            local D = CherrysBar.Displays
            frameOf('Bag').posX = 160
            D.MouseDown(D.byKey.Bag.slot, 'LBUTTON')
            frameOf('Bag').posX = 161
            D.MouseUp(D.byKey.Bag.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("calls.opened[1]"), "BagFrame")
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")

    # Options window

    def test_options_buttons_move_the_picked_display(self):
        self.run_lua("""
            CherrysBar.Options.Toggle()
            CherrysBar.Options.ChipUp(CherrysBar.Displays.byKey.Bag.slot, 'LBUTTON')
            CherrysBar.Options.Move('left')
        """)
        self.assertEqual(self.ev("CBar_OptionsPicked.text"), "Bags")
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Bag,Exp,Money")
        self.run_lua("CherrysBar.Options.Move('right')")
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")
        self.run_lua("CherrysBar.Options.Move('bottom')")
        self.assertEqual(self.ev("cfg('Bag').bar"), "bottom")
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.run_lua("CherrysBar.Options.Move('top')")
        self.assertEqual(self.ev("cfg('Bag').bar"), "top")
        self.run_lua("CherrysBar.Options.Move('off')")
        self.assertEqual(self.ev("cfg('Bag').bar"), "off")
        self.assertFalse(self.ev("frameOf('Bag').shown"))

    def test_chips_map_the_bars(self):
        self.run_lua("CherrysBar.Options.Toggle()")
        menu_y, none_y = self.ev("chipOf('Menu').anchors[1][5]"), self.ev("chipOf('Zone').anchors[1][5]")
        self.assertLess(menu_y, none_y)
        self.assertLess(self.ev("chipOf('Menu').anchors[1][4]"), self.ev("chipOf('Exp').anchors[1][4]"))
        self.assertLess(self.ev("chipOf('Money').anchors[1][4]"), self.ev("chipOf('Mail').anchors[1][4]"))
        self.assertEqual(self.ev("chipOf('Bag').w"), 64)
        self.assertEqual(self.ev("_G['CBar_Chip' .. CherrysBar.Displays.byKey.Bag.slot .. 'Text'].text"), "Bag")
        self.assertEqual(self.ev("_G['CBar_Chip' .. CherrysBar.Displays.byKey.Menu.slot .. 'Mark'].shown"), True)

    def test_a_crowded_row_shrinks_chips_to_their_icons(self):
        self.run_lua("""
            CherrysBar.Options.Toggle()
            local D = CherrysBar.Displays
            for _, def in ipairs(D.list) do D.SetBar(def, 'top') end
            CherrysBar.Options.Refresh()
        """)
        self.assertLess(self.ev("chipOf('Bag').w"), 50)
        self.assertFalse(self.ev("_G['CBar_Chip' .. CherrysBar.Displays.byKey.Bag.slot .. 'Text'].shown"))
        lefts = sorted(self.ev(f"chipOf('{k}').anchors[1][4]") for k in self.ev("CherrysBar.Displays.byKey").keys() if k != "Mode")
        self.assertLess(lefts[-1] + 45, 90 + 776 + 8)
        self.assertEqual(len(set(lefts)), 18)

    def test_dragging_a_chip_between_rows(self):
        self.run_lua("""
            CherrysBar.Options.Toggle()
            local O = CherrysBar.Options
            CBar_Options.posX, CBar_Options.posY = 0, 0
            for key, x in pairs({ Menu = 94, Exp = 160, Bag = 226, Money = 292, Mail = 650, Perf = 716, Clock = 782 }) do
              chipOf(key).posX, chipOf(key).posY = x, 151
            end
            local zone = CherrysBar.Displays.byKey.Zone.slot
            chipOf('Zone').posX, chipOf('Zone').posY = 94, 219
            O.ChipDown(zone, 'LBUTTON')
        """)
        self.assertTrue(self.ev("chipOf('Zone').moving"))
        self.run_lua("""
            chipOf('Zone').posX, chipOf('Zone').posY = 170, 151
            CherrysBar.Options.ChipUp(CherrysBar.Displays.byKey.Zone.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Zone,Bag,Money")
        self.assertTrue(self.ev("frameOf('Zone').shown"))
        self.assertEqual(self.ev("CBar_OptionsPicked.text"), "Location")
        self.run_lua("""
            local zone = CherrysBar.Displays.byKey.Zone.slot
            chipOf('Zone').posX, chipOf('Zone').posY = 226, 151
            CherrysBar.Options.ChipDown(zone, 'LBUTTON')
            chipOf('Zone').posY = 220
            CherrysBar.Options.ChipUp(zone, 'LBUTTON')
        """)
        self.assertEqual(self.ev("cfg('Zone').bar"), "off")
        self.assertFalse(self.ev("frameOf('Zone').shown"))

    def test_bar_rows_and_general_rows(self):
        self.run_lua("CherrysBar.Options.Toggle(); CherrysBar.Options.BarClick('bottom', 'show')")
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.run_lua("CherrysBar.Options.BarClick('top', 'skin')")
        self.assertEqual(self.ev("CherrysBar.S().bars.top.skin"), "Blacksteel")
        self.assertEqual(self.ev("CBar_OptBarTopSkin.text"), "Blacksteel")
        self.assertIn("Blacksteel/top", self.ev("CBar_LayoutTop.texture"))
        self.run_lua("CherrysBar.Options.BarClick('top', 'minus')")
        self.assertAlmostEqual(self.ev("CBar_BarTop.alpha"), 0.9)
        self.assertEqual(self.ev("CBar_OptBarTopValue.text"), "90%")
        self.assertEqual(self.ev("CBar_OptRow1Label.text"), "Bar height")
        for i in range(1, 7):
            kind = self.ev(f"CherrysBar.Options.LIST[{i}].kind")
            for part in {"check": ["check", "check"], "num": ["plus", "minus"]}[kind]:
                self.run_lua(f"CherrysBar.Options.RowClick({i}, '{part}')")

    def test_picked_display_settings_and_format(self):
        self.run_lua("""
            CherrysBar.Options.Toggle()
            CherrysBar.Options.ChipUp(CherrysBar.Displays.byKey.Bag.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("CBar_OptionsFormat.text"), "[USED]/[TOTAL]")
        self.assertIn("[FREE]", self.ev("CBar_OptionsTokens.text"))
        self.run_lua("CBar_OptionsFormat:SetText('[TOTAL]'); CherrysBar.Options.ApplyFormat()")
        self.assertIn("60", self.text_of("Bag"))
        self.run_lua("CherrysBar.Options.ResetFormat()")
        self.assertEqual(self.ev("CBar_OptionsFormat.text"), "[USED]/[TOTAL]")
        self.run_lua("CherrysBar.Options.PickedFlip('icon')")
        self.assertFalse(self.ev("cfg('Bag').icon"))
        self.run_lua("CherrysBar.Options.ChipUp(CherrysBar.Displays.byKey.Menu.slot, 'LBUTTON')")
        self.assertFalse(self.ev("CBar_OptionsFormat.shown"))

    def test_lock_button_says_what_it_will_do(self):
        self.run_lua("CherrysBar.Options.Toggle()")
        self.assertEqual(self.ev("CBar_OptionsLock.text"), "Unlock to drag on the bars")
        self.run_lua("CherrysBar.Options.ToggleLock()")
        self.assertEqual(self.ev("CBar_OptionsLock.text"), "Lock the displays")

    # Menus

    def test_right_click_on_a_display_changes_it(self):
        self.run_lua("local D = CherrysBar.Displays; D.MouseUp(D.byKey.Bag.slot, 'RBUTTON')")
        self.assertTrue(self.ev("CBar_Menu.shown"))
        rows = self.menu_rows()
        self.assertIn("CheckboxOn", self.ev(f"CBar_MenuRow{rows['Show icon']}Icon.texture"))
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Show icon']}, 'LBUTTON')")
        self.assertFalse(self.ev("cfg('Bag').icon"))
        self.assertIn("CheckboxOff", self.ev(f"CBar_MenuRow{rows['Show icon']}Icon.texture"))
        self.assertTrue(self.ev("CBar_Menu.shown"))
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Move left']}, 'LBUTTON')")
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Bag,Exp,Money")
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Move to the bottom bar']}, 'LBUTTON')")
        self.assertEqual(self.ev("cfg('Bag').bar"), "bottom")
        self.assertIn("Move to the top bar", self.menu_rows())

    def test_right_click_on_a_bar_lists_every_display(self):
        self.run_lua("CherrysBar.Bars.BarClick('top', 'RBUTTON')")
        self.assertTrue(self.ev("CBar_Menu.shown"))
        self.assertEqual(self.ev("CBar_Menu.anchors[1][3]"), "UIParent")
        self.assertEqual(self.ev("CBar_Menu.anchors[1][4]"), 300)
        rows = self.menu_rows()
        self.assertIn("Location", rows)
        self.assertIn("CheckboxOff", self.ev(f"CBar_MenuRow{rows['Location']}Icon.texture"))
        self.assertIn("CheckboxOn", self.ev(f"CBar_MenuRow{rows['Bags']}Icon.texture"))
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Location']}, 'LBUTTON')")
        self.assertEqual(self.ev("cfg('Zone').bar"), "top")
        self.assertTrue(self.ev("frameOf('Zone').shown"))
        self.assertIn("CheckboxOn", self.ev(f"CBar_MenuRow{rows['Location']}Icon.texture"))
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Location']}, 'LBUTTON')")
        self.assertEqual(self.ev("cfg('Zone').bar"), "off")

    def test_left_click_on_a_bar_does_nothing(self):
        self.run_lua("CherrysBar.Bars.BarClick('top', 'LBUTTON')")
        self.assertFalse(self.ev("CBar_Menu.shown"))

    def test_menu_closes_after_the_mouse_leaves_and_scrolls(self):
        self.run_lua("""
            local list = {}
            for i = 1, 40 do list[i] = { text = 'row' .. i, click = function() clicked = i end } end
            CherrysBar.Menu.Open(list, nil, nil)
            CherrysBar.Menu.Wheel(-1)
        """)
        self.assertEqual(self.ev("CBar_MenuRow1Text.text"), "row2")
        self.run_lua("CherrysBar.Menu.RowClick(1, 'LBUTTON')")
        self.assertEqual(self.ev("clicked"), 2)
        self.run_lua("CherrysBar.Menu.Open({ { text = 'a' } }, nil, nil); CherrysBar.Menu.RowLeave(1)")
        self.assertTrue(self.ev("CBar_Menu.shown"))
        self.tick(1)
        self.assertFalse(self.ev("CBar_Menu.shown"))

    # Auto-hide

    def test_auto_hide_tucks_away_and_comes_back(self):
        self.run_lua("CherrysBar.Bars.SetAutoHide('top', true)")
        self.assertTrue(self.ev("CBar_EdgeTop.shown"))
        self.assertTrue(self.ev("CBar_BarTop.shown"))  # under the mouse just now
        self.tick(1.5)
        self.assertFalse(self.ev("CBar_BarTop.shown"))
        self.assertFalse(self.ev("frameOf('Bag').shown"))
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)  # takes no room
        self.run_lua("CherrysBar.Bars.Reveal('top')")
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.assertTrue(self.ev("frameOf('Bag').shown"))
        self.tick(3)
        self.assertTrue(self.ev("CBar_BarTop.shown"))  # stays until the mouse has been and gone
        self.run_lua("CherrysBar.Bars.Hover('top', true); CherrysBar.Bars.Hover('top', false)")
        self.tick(0.5)
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.tick(1)
        self.assertFalse(self.ev("CBar_BarTop.shown"))

    def test_moving_from_bar_to_display_keeps_it_out(self):
        self.run_lua("CherrysBar.Bars.SetAutoHide('top', true); CherrysBar.Bars.Hover('top', false)")
        self.tick(0.5)
        self.run_lua("local D = CherrysBar.Displays; D.Enter(D.byKey.Bag.slot, frameOf('Bag'))")
        self.tick(3)
        self.assertTrue(self.ev("CBar_BarTop.shown"))

    def test_an_open_menu_holds_an_auto_hide_bar(self):
        self.run_lua("""
            CherrysBar.Bars.SetAutoHide('top', true)
            CherrysBar.Bars.BarClick('top', 'RBUTTON')
            CherrysBar.Bars.Hover('top', false)
        """)
        self.tick(3)
        self.assertTrue(self.ev("CBar_BarTop.shown"))

    def test_pin_handle_toggles_auto_hide_and_its_picture(self):
        self.run_lua("CherrysBar.Command('unlock')")
        self.assertIn("Icons/PinIn", self.ev("CBar_PinTopIcon.texture"))
        self.run_lua("CherrysBar.Bars.PinClick('top')")
        self.assertTrue(self.ev("CherrysBar.S().bars.top.autoHide"))
        self.assertIn("PinOut", self.ev("CBar_PinTopIcon.texture"))
        self.run_lua("CherrysBar.Bars.PinClick('top')")
        self.assertFalse(self.ev("CBar_EdgeTop.shown"))
        self.assertTrue(self.ev("CBar_BarTop.shown"))

    # Drawing and throttling

    def test_format_tokens_label_and_colour(self):
        self.assertIn("10", self.text_of("Bag"))
        self.assertNotIn("Bag", self.text_of("Bag"))
        self.run_lua("""
            local D = CherrysBar.Displays
            local c = D.Config(D.byKey.Bag)
            c.fmt, c.label, c.color = '[USED] of [TOTAL] ([FREE] free, [LOAD]%) [NOPE]', true, false
            D.Rebuild()
        """)
        self.assertEqual(self.text_of("Bag"), "Bag 10 of 60 (50 free, 17%) [NOPE]")

    def test_no_error_escapes_the_update_loop_from_a_display_timer(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.byKey.Perf.tick = function() error('broken timer') end
            for i = 1, 40 do now = now + 0.3; CherrysBar.OnUpdate(0.3) end
        """)
        self.assertIn("broken timer", self.ev("CherrysBar.Displays.byKey.Perf.err"))

    def test_clock_shows_time_online_without_a_real_clock(self):
        self.assertEqual(self.text_of("Clock"), "00:00")
        self.assertIsNone(self.ev("CherrysBar.Displays.byKey.Clock.err"))
        self.tick(61)
        self.tick(1)
        self.assertEqual(self.text_of("Clock"), "00:01")

    def test_clock_tooltip_says_where_the_time_comes_from(self):
        self.run_lua("local D = CherrysBar.Displays; D.Enter(D.byKey.Clock.slot, frameOf('Clock'))")
        lines = " ".join(str(v) for v in self.ev("GameTooltip.lines").values())
        self.assertIn("Daily Rewards Chrome extension", lines)
        self.assertIn("daily reward", lines)

    def test_clock_uses_cherrys_clock_once_it_knows_the_time(self):
        self.run_lua("""
            CherrysClock = { Time = function() return 21, 7, 30 end, Date = function() return 2026, 10, 30 end }
            local D = CherrysBar.Displays
            D.Config(D.byKey.Clock).fmt = '[TIME24] [TIME12] [DATE]'
            D.Rebuild()
        """)
        self.assertEqual(self.text_of("Clock"), "21:07 09:07 PM 30-10-2026")

    def test_clock_waits_when_cherrys_clock_does_not_know_yet(self):
        self.run_lua("""
            CherrysClock = { Time = function() return nil end }
            CherrysBar.Displays.Rebuild()
        """)
        self.assertEqual(self.text_of("Clock"), "00:00")

    def test_perf_records_frames_memory_and_addon_cost_then_restores(self):
        self.run_lua("""
            CherrysGrid = { OnUpdate = function(e) now = now + 0.002; return 'kept' end }
            original = CherrysGrid.OnUpdate
            CherrysBar.Command('perf 2')
            result = CherrysGrid.OnUpdate(0.016)
            for i = 1, 30 do CherrysBar.OnUpdate(0.016); CherrysGrid.OnUpdate(0.016) end
            CherrysBar.OnUpdate(0.3)
            for i = 1, 100 do CherrysBar.OnUpdate(0.016); CherrysGrid.OnUpdate(0.016) end
        """)
        self.assertEqual(self.ev("result"), "kept")
        self.assertFalse(self.ev("CherrysBar.Perf.IsRunning()"))
        self.assertTrue(self.ev("CherrysGrid.OnUpdate == original"))
        self.assertIsNone(self.ev("CherrysBar.perfFrame"))
        self.assertEqual(self.ev("CherrysBar.S().perf.longestMs"), 300)
        self.assertEqual(self.ev("CherrysBar.S().perf.over250"), 1)
        self.assertEqual(self.ev("CherrysBar.S().perf.hitches[1].ms"), 300)
        self.assertEqual(self.ev("CherrysBar.S().perf.addons[1].name"), "CherrysGrid.OnUpdate")
        self.assertGreater(self.ev("CherrysBar.S().perf.addons[1].totalMs"), 50)
        self.assertTrue(any("longest" in str(m).lower() for m in self.ev("messages").values()))

    def test_perf_stop_and_double_start(self):
        self.run_lua("CherrysBar.Command('perf stop')")
        self.assertIn("not recording", self.ev("messages[#messages]"))
        self.run_lua("CherrysBar.Command('perf'); CherrysBar.Command('perf')")
        self.assertIn("already", self.ev("messages[#messages]"))
        self.run_lua("CherrysBar.Command('perf stop')")
        self.assertFalse(self.ev("CherrysBar.Perf.IsRunning()"))

    def test_every_display_uses_cherrys_icons(self):
        for key in self.ev("CherrysBar.Displays.byKey").keys():
            self.assertIn("CherrysBar/Media/Icons/", self.ev(f"CherrysBar.Displays.byKey.{key}.icon"), key)

    def test_events_only_mark_and_a_burst_redraws_once(self):
        before = self.ev("calls.bag")
        for _ in range(50):
            self.run_lua("CherrysBar.OnEvent('PLAYER_BAG_CHANGED')")
        self.assertEqual(self.ev("calls.bag"), before)
        self.tick()
        self.assertEqual(self.ev("calls.bag"), before + 1)

    def test_goods_are_scanned_only_when_the_format_asks(self):
        self.run_lua("calls.goods = 0; CherrysBar.OnEvent('PLAYER_BAG_CHANGED')")
        self.tick()
        self.assertEqual(self.ev("calls.goods"), 0)
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Bag).fmt = '[SUSED]'
            D.Rebuild()
        """)
        self.assertEqual(self.ev("calls.goods"), 60)

    def test_item_currencies_are_read_only_when_asked(self):
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Wallet, 'top'); CherrysBar.OnEvent('PLAYER_MONEY')")
        self.tick()
        self.assertIsNone(self.ev("calls.currency"))
        self.run_lua("local D = CherrysBar.Displays; D.Enter(D.byKey.Wallet.slot, frameOf('Wallet'))")
        self.assertEqual(self.ev("calls.currency"), 6)

    def test_hidden_displays_register_no_events_and_are_not_read(self):
        self.assertTrue(self.ev("CBar_Events.events.PLAYER_BAG_CHANGED"))
        self.run_lua("""
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Bag, 'off')
            calls.bag = 0
            CherrysBar.OnEvent('PLAYER_BAG_CHANGED')
        """)
        self.assertIsNone(self.ev("CBar_Events.events.PLAYER_BAG_CHANGED"))
        self.tick()
        self.assertEqual(self.ev("calls.bag"), 0)

    def test_events_follow_the_tokens_used(self):
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Dps, 'top')")
        self.assertIsNone(self.ev("CBar_Events.events.UNIT_HEALTH"))
        self.assertTrue(self.ev("CBar_Events.events.COMBATMETER_DAMAGE"))
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Dps).fmt = '[KILLS]'
            D.Rebuild()
        """)
        self.assertTrue(self.ev("CBar_Events.events.UNIT_HEALTH"))
        self.assertIsNone(self.ev("CBar_Events.events.COMBATMETER_DAMAGE"))

    def test_damage_counts_only_this_character_and_resets(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Dps, 'top')
            _source, _damage = 'Someone', 1000
            CherrysBar.OnEvent('COMBATMETER_DAMAGE')
            _source, _damage = 'Cherry', 500
            CherrysBar.OnEvent('COMBATMETER_DAMAGE')
        """)
        self.tick()
        self.assertEqual(self.text_of("Dps"), "500")
        self.tick(7)
        self.assertEqual(self.text_of("Dps"), "0")

    def test_idle_frames_make_no_garbage_and_no_text_writes(self):
        self.run_lua("""
            collectgarbage('collect')
            collectgarbage('stop')
            local before = collectgarbage('count')
            local text = _G['CBar_D' .. CherrysBar.Displays.byKey.Perf.slot .. 'Text']
            local start = text.setTexts
            for i = 1, 10000 do
              now = now + 0.016
              CherrysBar.OnUpdate(0.016)
            end
            grew = collectgarbage('count') - before
            collectgarbage('restart')
            writes = text.setTexts - start
        """)
        self.assertEqual(self.ev("writes"), 0)
        # 160 seconds: the clock redraws at most a few times, everything else stays silent.
        self.assertLess(self.ev("grew"), 32)

    def test_ticks_are_rarer_in_combat(self):
        self.run_lua("""
            ticks = 0
            local real = CherrysBar.Displays.Tick
            CherrysBar.Displays.Tick = function(dt) ticks = ticks + 1; real(dt) end
            for i = 1, 60 do CherrysBar.OnUpdate(0.1) end
            out_of_combat = ticks
            inCombat = true
            CherrysBar.OnUpdate(0.3)
            ticks = 0
            for i = 1, 60 do CherrysBar.OnUpdate(0.1) end
        """)
        self.assertGreaterEqual(self.ev("out_of_combat"), 15)
        self.assertLessEqual(self.ev("ticks"), 6)

    def test_perf_redraws_only_when_a_number_changes(self):
        self.run_lua("base = _G['CBar_D' .. CherrysBar.Displays.byKey.Perf.slot .. 'Text'].setTexts")
        for _ in range(10):
            self.tick(1)
        self.assertEqual(self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Perf.slot .. 'Text'].setTexts"), self.ev("base"))
        self.run_lua("state.fps = 30")
        for _ in range(3):
            self.tick(1)
        self.assertIn("30", self.text_of("Perf"))

    def test_a_failing_game_call_is_reported_not_raised(self):
        self.run_lua("function GetBagCount() error('gone') end; CherrysBar.OnEvent('PLAYER_BAG_CHANGED')")
        self.tick()
        self.assertIn("gone", self.ev("CherrysBar.Displays.byKey.Bag.err"))
        self.run_lua("CherrysBar.Probe.Run()")
        self.assertTrue(any("gone" in str(m) for m in self.ev("messages").values()))

    # Game frames

    def test_make_room_moves_top_frames_and_restores_them(self):
        self.run_lua("CherrysBar.S().bars.top.makeRoom = true; CherrysBar.Refresh()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.assertEqual(self.anchor_y("TargetFrame"), 26)
        self.assertEqual(self.anchor_y("MinimapFrame"), 56)
        self.assertEqual(self.anchor_y("MinimapFrameBorder"), 23)
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)
        self.assertEqual(self.anchor_y("MinimapFrame"), 32)
        self.run_lua("CherrysBar.Command('top')")
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_make_room_is_not_applied_twice(self):
        self.run_lua("CherrysBar.S().bars.top.makeRoom = true; CherrysBar.Refresh()")
        self.run_lua("CherrysBar.Bars.MakeRoom(); CherrysBar.Bars.MakeRoom()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.run_lua("CherrysBar.OnEvent('LOADING_END')")
        self.tick(4)
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_make_room_leaves_a_frame_the_player_dragged_away(self):
        self.run_lua("""
            CherrysBar.S().bars.top.makeRoom = true
            PlayerFrame:ClearAllAnchors()
            PlayerFrame:SetAnchor('TOPLEFT', 'TOPLEFT', 'UIParent', 300, 400)
            CherrysBar.Bars.MakeRoom()
        """)
        self.assertEqual(self.anchor_y("PlayerFrame"), 400)

    def test_top_bar_leaves_the_game_frames_alone_by_default(self):
        for frame in ("PlayerFrame", "MinimapFrame", "MinimapFrameBorder", "TargetFrame", "HouseFrame"):
            start = {"PlayerFrame": 0, "MinimapFrame": 32, "MinimapFrameBorder": -1, "TargetFrame": 2, "HouseFrame": 0}[frame]
            self.assertEqual(self.anchor_y(frame), start, frame)
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)

    def ui_lift(self):
        return self.ev("UIParent.anchors[2][5]")

    def test_bottom_bar_lifts_the_whole_interface_and_sits_below_it(self):
        self.assertEqual(self.ui_lift(), 0)
        self.run_lua("CherrysBar.Command('both')")
        self.assertEqual(self.ui_lift(), -24)
        self.assertEqual(self.ev("UIParent.anchors[1][3]"), "WorldFrame")
        self.assertEqual(self.ev("CBar_BarBottom.anchors[1][3]"), "WorldFrame")
        self.assertEqual(self.ev("CBar_BarTop.anchors[1][3]"), "UIParent")
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)  # lifted with its parent, not moved itself
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)
        self.run_lua("CherrysBar.Command('top')")
        self.assertEqual(self.ui_lift(), 0)

    def test_lift_follows_the_bar_height_and_its_settings(self):
        self.run_lua("CherrysBar.Command('both'); CherrysBar.S().barHeight = 30; CherrysBar.Refresh()")
        self.assertEqual(self.ui_lift(), -30)
        self.run_lua("CherrysBar.Options.BarClick('bottom', 'room')")
        self.assertEqual(self.ui_lift(), 0)
        self.run_lua("CherrysBar.Options.BarClick('bottom', 'room')")
        self.assertEqual(self.ui_lift(), -30)
        self.run_lua("CherrysBar.Bars.SetAutoHide('bottom', true)")
        self.assertEqual(self.ui_lift(), 0)

    def test_lift_survives_the_game_resetting_it_while_loading(self):
        self.run_lua("""
            CherrysBar.Command('both')
            UIParent:ClearAllAnchors()
            UIParent:SetAnchor('TOPLEFT', 'TOPLEFT', 'WorldFrame', 0, 0)
            UIParent:SetAnchor('BOTTOMRIGHT', 'BOTTOMRIGHT', 'WorldFrame', 0, 0)
            CherrysBar.OnEvent('LOADING_END')
        """)
        self.tick(4)
        self.assertEqual(self.ui_lift(), -24)

    def test_a_client_that_ignores_the_lift_gets_frames_moved_instead(self):
        self.run_lua("""
            function UIParent:GetHeight() return 1000 end
            CherrysBar.Command('both')
        """)
        self.assertEqual(self.ui_lift(), -24)
        self.tick(2)
        self.assertEqual(self.ui_lift(), 0)
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        self.assertEqual(self.anchor_y("MainActionBarFrame"), -40)
        self.assertEqual(self.anchor_y("ChatFrame1"), -60)
        self.assertEqual(self.ev("ExperienceFrame.anchors[1][4]"), 100)
        self.assertEqual(self.ev("ExperienceFrame.anchors[2][4]"), -106)
        self.assertEqual(self.anchor_y("ExperienceFrame"), -24)
        self.run_lua("CherrysBar.Command('top')")
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)
        self.assertEqual(self.anchor_y("MainActionBarFrame"), -16)
        self.assertEqual(self.anchor_y("ChatFrame1"), -36)
        self.assertEqual(self.anchor_y("ExperienceFrame"), 0)
        self.assertEqual(self.ev("ExperienceFrame.anchors[2][4]"), -106)

    def test_a_client_without_those_calls_gets_frames_moved_too(self):
        self.run_lua("WorldFrame = nil; CherrysBar.Command('both')")
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        self.assertEqual(self.ev("CBar_BarBottom.anchors[1][3]"), "UIParent")

    def test_make_room_is_a_choice_per_bar_and_takes_the_portrait_cluster_along(self):
        self.run_lua("CherrysBar.Options.Toggle(); CherrysBar.Options.BarClick('top', 'room')")
        for frame, y in (("PlayerFrame", 24), ("PlayerFramePartyBoardButton", 54), ("PetBookFrameButton", 122), ("HouseFrame", 24)):
            self.assertEqual(self.anchor_y(frame), y, frame)
        self.run_lua("CherrysBar.Options.BarClick('top', 'room')")
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)
        self.assertEqual(self.anchor_y("HouseFrame"), 0)

    def test_old_shared_setting_is_dropped(self):
        self.run_lua("CherrysBar.S().makeRoom = true")
        self.load_addon()
        self.assertIsNone(self.ev("CherrysBar.S().makeRoom"))
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)

    def test_left_displays_start_past_the_portrait_and_housing(self):
        self.assertEqual(self.ev("frameOf('Menu').anchors[1][4]"), 410)
        self.assertGreater(self.ev("frameOf('Exp').anchors[1][4]"), 410)

    def test_right_displays_stop_short_of_the_buffs_and_minimap(self):
        self.assertEqual(self.ev("frameOf('Clock').anchors[1][4]"), -500)
        self.assertLess(self.ev("frameOf('Perf').anchors[1][4]"), -500)

    def test_clear_gaps_are_set_per_bar(self):
        self.run_lua("""
            CherrysBar.Options.Toggle()
            CherrysBar.Command('both')
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Zone, 'bottom')
        """)
        self.assertEqual(self.ev("frameOf('Zone').anchors[1][4]"), 10)
        self.assertEqual(self.ev("CBar_OptBarTopLeftValue.text"), "400")
        self.run_lua("CherrysBar.Options.BarClick('top', 'leftMinus')")
        self.assertEqual(self.ev("frameOf('Menu').anchors[1][4]"), 390)
        self.assertEqual(self.ev("CBar_OptBarTopLeftValue.text"), "380")
        self.run_lua("CherrysBar.Options.BarClick('top', 'rightPlus')")
        self.assertEqual(self.ev("frameOf('Clock').anchors[1][4]"), -520)
        self.assertEqual(self.ev("CBar_OptBarTopRightValue.text"), "510")
        self.run_lua("CherrysBar.Options.BarClick('bottom', 'leftPlus')")
        self.assertEqual(self.ev("frameOf('Zone').anchors[1][4]"), 30)
        self.run_lua("for i = 1, 40 do CherrysBar.Options.BarClick('bottom', 'leftMinus') end")
        self.assertEqual(self.ev("CherrysBar.S().bars.bottom.leftGap"), 0)

    def test_handles_sit_inside_the_clear_stretch(self):
        self.run_lua("CherrysBar.Command('unlock')")
        self.assertEqual(self.ev("CBar_LockTop.anchors[1][4]"), -494)
        self.assertEqual(self.ev("CBar_PinTop.anchors[1][4]"), -514)
        self.assertEqual(self.ev("frameOf('Clock').anchors[1][4]"), -544)

    def test_hiding_game_frames_only_shows_what_it_hid(self):
        self.run_lua("MainMenuFrame:Hide(); CherrysBar.Refresh()")
        self.assertFalse(self.ev("MainMenuFrame.shown"))
        self.run_lua("CherrysBar.S().hideMenuBar = true; CherrysBar.Refresh(); MainMenuFrame:Show(); CherrysBar.Refresh()")
        self.assertFalse(self.ev("MainMenuFrame.shown"))
        self.run_lua("CherrysBar.S().hideMenuBar = false; CherrysBar.Refresh()")
        self.assertTrue(self.ev("MainMenuFrame.shown"))

    def test_reload_does_not_move_frames_twice(self):
        # Frames that kept their place through Reload UI...
        self.run_lua("CherrysBar.S().bars.top.makeRoom = true; CherrysBar.Refresh()")
        self.load_addon()
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.assertEqual(self.anchor_y("MinimapFrame"), 56)
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertEqual(self.ui_lift(), -24)
        self.load_addon()
        self.assertEqual(self.ui_lift(), -24)
        # ...and frames the reload rebuilt at the game's own positions.
        self.run_lua("""
            UIParent:ClearAllAnchors()
            UIParent:SetAnchor('TOPLEFT', 'TOPLEFT', 'WorldFrame', 0, 0)
            UIParent:SetAnchor('BOTTOMRIGHT', 'BOTTOMRIGHT', 'WorldFrame', 0, 0)
            CherrysBar.S().bars.top.show = true
            PlayerFrame:ClearAllAnchors()
            PlayerFrame:SetAnchor('TOPLEFT', 'TOPLEFT', 'UIParent', 0, 0)
        """)
        self.load_addon()
        self.assertEqual(self.ui_lift(), -24)
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        # Turned off for good: the next session puts UIParent back if it kept the lift.
        self.run_lua("""
            CherrysBar.S().bars.bottom.show = false
        """)
        self.load_addon()
        self.assertEqual(self.ui_lift(), 0)

    # Displays

    def test_left_click_does_the_display_job(self):
        self.run_lua("CherrysBar.Displays.MouseUp(CherrysBar.Displays.byKey.Bag.slot, 'LBUTTON')")
        self.assertEqual(self.ev("calls.opened[1]"), "BagFrame")

    def test_a_click_on_a_missing_game_call_gives_a_message(self):
        self.run_lua("OpenMail = nil; CherrysBar.Displays.MouseUp(CherrysBar.Displays.byKey.Mail.slot, 'LBUTTON')")
        self.assertIn("could not", self.ev("messages[#messages]"))

    def test_mail_counts_system_messages(self):
        self.run_lua("CherrysBar.OnEvent('CHAT_MSG_SYSTEM', 'SYS_NEW_MAIL'); CherrysBar.OnEvent('CHAT_MSG_SYSTEM', 'hello')")
        self.tick()
        self.assertIn("1", self.text_of("Mail"))
        self.run_lua("CherrysBar.OnEvent('MAIL_SHOW')")
        self.tick()
        self.assertIn("0", self.text_of("Mail"))

    def test_session_figures_per_hour_and_time_to_level(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Exp).fmt = '[XPS] [XPH] [TTL]'
            D.Config(D.byKey.Money).fmt = '[GAINED] [SPENT] [NET] [GPH]'
            D.Config(D.byKey.Money).color = false
            D.Rebuild()
            now = now + 3600
            state.xp = 600
            state.gold = state.gold + 2000
            CherrysBar.OnEvent('PLAYER_EXP_CHANGED')
            CherrysBar.OnEvent('PLAYER_MONEY')
        """)
        self.tick()
        self.assertEqual(self.text_of("Exp"), "100 99 04:02")
        self.run_lua("state.gold = state.gold - 500; CherrysBar.OnEvent('PLAYER_MONEY')")
        self.tick()
        self.assertEqual(self.text_of("Money"), "2,000 500 1,500 1,999")

    def test_reset_session_row_clears_the_figures(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Money).fmt = '[GAINED]'
            D.Config(D.byKey.Money).color = false
            D.Rebuild()
            state.gold = state.gold + 2000
            CherrysBar.OnEvent('PLAYER_MONEY')
        """)
        self.tick()
        self.assertEqual(self.text_of("Money"), "2,000")
        self.run_lua("local D = CherrysBar.Displays; D.MouseUp(D.byKey.Money.slot, 'RBUTTON')")
        rows = self.menu_rows()
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Reset session figures']}, 'LBUTTON')")
        self.assertEqual(self.text_of("Money"), "0")

    def test_location_reads_coordinates_only_when_asked(self):
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Zone, 'top')")
        self.assertEqual(self.text_of("Zone"), "Varanas")
        self.assertIsNone(self.ev("CherrysBar.Displays.byKey.Zone.v.X"))
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Zone).fmt = '[ZONE] [X],[Y]'
            D.Rebuild()
        """)
        self.assertEqual(self.text_of("Zone"), "Varanas 12.3,45.6")
        self.run_lua("zone = 'Howling'")
        self.tick(4)
        self.assertIn("Howling", self.text_of("Zone"))

    def test_volume_mutes_restores_scrolls_and_changes_its_speaker(self):
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Volume, 'top')")
        self.assertEqual(self.text_of("Volume"), "80%")
        volume_icon = "_G['CBar_D' .. CherrysBar.Displays.byKey.Volume.slot .. 'Icon']"
        self.assertEqual(self.ev(volume_icon + ".w"), 32)  # the pack's speakers are 2:1
        self.assertEqual(self.ev(volume_icon + ".h"), 16)
        icon = "_G['CBar_D' .. CherrysBar.Displays.byKey.Volume.slot .. 'Icon'].texture"
        self.assertIn("VolumeHigh", self.ev(icon))
        slot = self.ev("CherrysBar.Displays.byKey.Volume.slot")
        self.run_lua(f"CherrysBar.Displays.MouseUp({slot}, 'LBUTTON')")
        self.assertEqual(self.ev("volume"), 0)
        self.assertIn("VolumeMute", self.ev(icon))
        self.assertEqual(self.text_of("Volume"), "0%")
        self.run_lua(f"CherrysBar.Displays.MouseUp({slot}, 'LBUTTON')")
        self.assertEqual(self.ev("volume"), 80)
        self.assertEqual(self.ev("SYS_AudioSettings_MasterVolumeSlider.value"), 80)
        self.run_lua(f"for i = 1, 4 do CherrysBar.Displays.Wheel({slot}, -1) end")
        self.assertEqual(self.ev("volume"), 60)
        self.assertIn("VolumeMedium", self.ev(icon))
        self.assertEqual(self.text_of("Volume"), "60%")
        self.run_lua(f"for i = 1, 20 do CherrysBar.Displays.Wheel({slot}, 1) end")
        self.assertEqual(self.ev("volume"), 100)

    def with_kitty(self):
        self.run_lua("""
            Kitty = { L = function(_, d) return d end, Modes = { boss = true } }
            kittyMode, kittyHost, kittyFlyout = 'boss', nil, nil
            Kitty.ModeUI = {
              current = function() return kittyMode, { kittyMode } end,
              iconPath = function(name) return 'Kitty/gfx/modes/' .. name .. '.tga' end,
              setTextHost = function(host) kittyHost = host end,
              toggleFlyout = function(anchor) kittyFlyout = anchor end,
            }
            CherrysBar.Refresh()
        """)

    def test_mode_display_appears_with_kitty_and_takes_over_its_plate(self):
        self.assertFalse(self.ev("frameOf('Mode').shown"))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")
        self.with_kitty()
        self.assertTrue(self.ev("frameOf('Mode').shown"))
        self.assertEqual(self.ev("row('top', 'left')"), "Mode,Menu,Exp,Bag,Money")
        self.assertEqual(self.ev("frameOf('Mode').anchors[1][4]"), 410)
        self.assertEqual(self.ev("type(kittyHost)"), "function")
        self.assertIn("boss", self.text_of("Mode"))
        self.assertIn("Mode", self.text_of("Mode"))
        self.assertIn("modes/boss", self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Mode.slot .. 'Icon'].texture"))

    def test_mode_display_follows_the_mode_without_polling(self):
        self.with_kitty()
        self.tick(5)
        self.assertIn("boss", self.text_of("Mode"))
        self.run_lua("kittyMode = 'aoe'")
        self.tick(5)
        self.assertIn("boss", self.text_of("Mode"))  # nothing has told it yet
        self.run_lua("kittyHost()")
        self.tick()
        self.assertIn("aoe", self.text_of("Mode"))
        self.assertIn("modes/aoe", self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Mode.slot .. 'Icon'].texture"))

    def test_clicking_the_mode_display_opens_kittys_picker_at_it(self):
        self.with_kitty()
        self.run_lua("local D = CherrysBar.Displays; D.MouseUp(D.byKey.Mode.slot, 'LBUTTON')")
        self.assertEqual(self.ev("kittyFlyout == frameOf('Mode')"), True)

    def test_kittys_plate_comes_back_when_the_display_is_not_on_a_bar(self):
        self.with_kitty()
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Mode, 'off')")
        self.assertIsNone(self.ev("kittyHost"))
        self.run_lua("local D = CherrysBar.Displays; D.SetBar(D.byKey.Mode, 'top')")
        self.assertEqual(self.ev("type(kittyHost)"), "function")
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertIsNone(self.ev("kittyHost"))

    def test_mode_display_stays_away_when_kitty_is_turned_off(self):
        self.with_kitty()
        self.run_lua("Kitty.isTurnedOff = function() return true end; CherrysBar.Refresh()")
        self.assertFalse(self.ev("frameOf('Mode').shown"))
        self.assertEqual(self.ev("row('top', 'left')"), "Menu,Exp,Bag,Money")

    def test_bar_menu_lists_mode_only_with_kitty(self):
        self.run_lua("CherrysBar.Bars.BarClick('top', 'RBUTTON')")
        self.assertNotIn("Kitty mode", self.menu_rows())
        self.with_kitty()
        self.run_lua("CherrysBar.Bars.BarClick('top', 'RBUTTON')")
        self.assertIn("Kitty mode", self.menu_rows())

    def test_volume_scrolls_up_from_muted(self):
        self.run_lua("""
            volume = 0
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Volume, 'top')
            D.Wheel(D.byKey.Volume.slot, 1)
        """)
        self.assertEqual(self.ev("volume"), 5)
        self.assertEqual(self.text_of("Volume"), "5%")
        self.assertIn("VolumeLow", self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Volume.slot .. 'Icon'].texture"))
        self.run_lua("""
            volume = 0
            local D = CherrysBar.Displays
            D.MouseUp(D.byKey.Volume.slot, 'LBUTTON')
        """)
        self.assertEqual(self.ev("volume"), 50)

    def test_every_display_reads_and_tips_without_error(self):
        self.with_kitty()
        for key in self.ev("CherrysBar.Displays.byKey").keys():
            self.run_lua(f"""
                local D = CherrysBar.Displays
                local def = D.byKey.{key}
                D.SetBar(def, 'top')
                D.Enter(def.slot, frameOf('{key}'))
            """)
            self.assertFalse(self.ev(f"CherrysBar.Displays.byKey.{key}.err"), key)

    def test_tooltip_is_built_on_hover_and_quiet_in_combat(self):
        slot = self.ev("CherrysBar.Displays.byKey.Money.slot")
        self.run_lua(f"CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertTrue(any("Gold" in str(v) for v in self.ev("GameTooltip.lines").values()))
        self.run_lua(f"GameTooltip.lines = nil; inCombat = true; CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertIsNone(self.ev("GameTooltip.lines"))
        self.run_lua(f"CherrysBar.S().tipsInCombat = true; CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertIsNotNone(self.ev("GameTooltip.lines"))

    # Settings and the hub

    def test_settings_survive_reload_in_the_same_lua_state(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            CherrysBar.S().bars.bottom.show = true
            D.SetBar(D.byKey.Zone, 'bottom')
        """)
        self.load_addon()
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.assertEqual(self.ev("cfg('Zone').bar"), "bottom")

    def test_settings_of_the_first_build_are_replaced_but_counts_kept(self):
        self.run_lua("""
            CherrysBar_DB = { bars = { top = { show = true, skin = 'Tribal', alpha = 1 }, bottom = { show = false, skin = 'Black', alpha = 1 } },
                              displays = { Dps = { fmt = '[DURA]', bar = 'top' } }, playedMins = 77, kills = { Cherry = 3 } }
        """)
        self.load_addon()
        self.assertEqual(self.ev("CherrysBar.S().bars.top.skin"), "Ironstone")
        self.assertEqual(self.ev("cfg('Dps').bar"), "off")
        self.assertEqual(self.ev("CherrysBar.S().playedMins"), 77)
        self.assertEqual(self.ev("CherrysBar.S().kills.Cherry"), 3)

    def test_skin_names_of_the_first_art_carry_over_and_the_layout_stays(self):
        self.run_lua("""
            CherrysBar.S().bars.top.skin = 'Walnut'
            CherrysBar.S().bars.bottom.skin = 'Moss'
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Zone, 'top')
        """)
        self.load_addon()
        self.assertEqual(self.ev("CherrysBar.S().bars.top.skin"), "Darkwood")
        self.assertEqual(self.ev("CherrysBar.S().bars.bottom.skin"), "Verdant")
        self.assertEqual(self.ev("cfg('Zone').bar"), "top")
        self.assertIn("Skins/Darkwood/top", self.ev("CBar_BarTopT1.texture"))

    def test_reset_everything(self):
        self.run_lua("""
            CherrysBar.Command('both')
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Zone, 'bottom')
            CherrysBar.Command('reset')
        """)
        self.assertFalse(self.ev("CBar_BarBottom.shown"))
        self.assertEqual(self.ev("cfg('Zone').bar"), "off")
        self.assertFalse(self.ev("frameOf('Zone').shown"))
        self.assertEqual(self.ev("CherrysBar.S().locked"), True)

    def test_hub_off_stays_idle(self):
        self.run_lua("""
            CherrysBar_DB = nil
            CherrysKit = { IsEnabled = function() return false end }
            CBar_BarTop:Hide()
        """)
        self.load_addon()
        self.assertFalse(self.ev("CherrysBar.ready"))
        self.assertTrue(self.ev("CherrysBar.off"))
        self.assertFalse(self.ev("CBar_BarTop.shown"))
        self.assertEqual(self.ev("PlayerFrame.anchors[1][5]"), 0)

    def test_slash_command_and_probe(self):
        self.run_lua("SlashCmdList['CHERRYSBAR'](nil, 'probe')")
        text = " ".join(str(v) for v in self.ev("messages").values())
        self.assertIn("missing functions: none", text.replace("|cffff7fa8Cherry's Bar:|r ", ""))
        self.assertIn("displays shown", text)
        self.assertIn("master volume reads 80", text)


class PackageTest(unittest.TestCase):
    def fresh(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(CLIENT)
        make = lua.globals().MakeWidget
        for name in xml_names():
            make(name, False)
        for name in FILES:
            lua.execute((SOURCE / name).read_text(encoding="utf-8"))
        return lua

    def test_xml_handlers_call_functions_that_exist(self):
        lua = self.fresh()
        text = (SOURCE / "CherrysBar.xml").read_text(encoding="utf-8")
        calls = set(re.findall(r"CherrysBar\.[A-Za-z.]+(?=\()", text))
        self.assertTrue(calls)
        for call in calls:
            self.assertEqual(lua.eval(f"type({call})"), "function", call)

    def test_xml_parses_and_slots_match_the_list(self):
        tree = ET.parse(SOURCE / "CherrysBar.xml")
        names = {el.get("name") for el in tree.iter(NS + "Frame")}
        lua = self.fresh()
        count = lua.eval("#CherrysBar.Displays.list")
        self.assertEqual(count, 19)
        for i in range(1, count + 1):
            self.assertIn(f"CBar_D{i}", names)
            self.assertIn(f"CBar_Chip{i}", names)
        self.assertNotIn(f"CBar_D{count + 1}", names)

    def test_generators_match_the_committed_layout(self):
        # Options.lua and the XML generator must agree on where the layout rows are.
        options = (SOURCE / "Options.lua").read_text(encoding="utf-8")
        gen = (ROOT / "tools/gen_cherrysbar_xml.py").read_text(encoding="utf-8")
        for y in re.findall(r'"(?:Top|Bottom|None)": (\d+)', gen):
            self.assertIn(f"y = {y} }}", options)
        self.assertIn("ROW_X, ROW_W, ROW_H = 90, 776, 30", gen)
        self.assertIn("O.ROW_X, O.ROW_W, O.ROW_H = 90, 776, 30", options)

    def test_bars_are_drawn_under_the_game(self):
        root = ET.parse(SOURCE / "CherrysBar.xml").getroot()
        tops = {el.get("name"): el for el in root}
        for name, el in tops.items():
            if re.match(r"CBar_(Bar|Edge|Pin|Lock)(Top|Bottom)$|CBar_D\d+$", name):
                self.assertEqual(el.get("frameStrata"), "BACKGROUND", name)
        # The game's own top-of-screen frames are LOW, and its menus and windows higher still.
        self.assertEqual(tops["CBar_Menu"].get("frameStrata"), "DIALOG")
        self.assertEqual(tops["CBar_Options"].get("frameStrata"), "DIALOG")

    def test_toc_lists_lua_and_every_file_exists(self):
        toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8-sig")
        self.assertIn("CherrysBar_DB", toc)
        for name in FILES + ("CherrysBar.xml",):
            self.assertIn("CherrysBar/" + name, toc)
            self.assertTrue((SOURCE / name).is_file())
        self.assertIn("KitLoad/CherrysBar.lua", toc)

    def tga_size(self, path):
        data = path.read_bytes()
        width, height, depth = struct.unpack("<HHB", data[12:17])
        self.assertIn(len(data) - (18 + width * height * 4), (0, 26), path)  # 26: the optional TGA footer
        self.assertEqual(depth, 32, path)
        return width, height

    def test_every_skin_is_a_tile_with_top_and_bottom_art(self):
        found = {p.name for p in (SOURCE / "Media/Skins").iterdir()}
        self.assertEqual(found, set(SKINS))
        for skin in SKINS:
            for name in ("top", "bottom"):
                self.assertEqual(self.tga_size(SOURCE / "Media/Skins" / skin / f"{name}.tga"), (256, 32))
        lua = self.fresh()
        self.assertEqual(tuple(lua.eval("CherrysBar.Bars.SKINS").values()), SKINS)

    def test_every_icon_named_in_the_code_exists_and_none_is_spare(self):
        used = set()
        for name in FILES:
            used |= set(re.findall(r'Icon\("([A-Za-z]+)"\)', (SOURCE / name).read_text(encoding="utf-8")))
        used |= set(re.findall(r'Icons\\([A-Za-z]+)"', (SOURCE / "CherrysBar.xml").read_text(encoding="utf-8")))
        dynamic = {"VolumeMute", "VolumeLow", "VolumeMedium", "VolumeHigh", "CheckboxOn", "CheckboxOff",
                   "PinIn", "PinOut", "Unlock", "Lock"}
        files = {p.stem for p in (SOURCE / "Media/Icons").glob("*.tga")}
        self.assertEqual(used | dynamic, files)
        for path in (SOURCE / "Media/Icons").glob("*.tga"):
            self.assertEqual(self.tga_size(path), (64, 32) if path.stem.startswith("Volume") else (32, 32))

    def test_art_is_the_pack_unchanged(self):
        manifest = json.loads((ROOT / "design/cherrys-bar/asset-manifest.json").read_text(encoding="utf-8"))
        hashes = {f["sha256"] for asset in manifest["assets"] for f in asset["files"]}
        for path in (SOURCE / "Media").rglob("*.tga"):
            if path.parent.name != "Slate":
                self.assertIn(hashlib.sha256(path.read_bytes()).hexdigest(), hashes, path)

    def test_credits_and_licence_stay_with_the_addon(self):
        notice = (SOURCE / "LICENSE-CherrysBar.txt").read_text(encoding="utf-8")
        for needed in ("by-nc-sa/3.0", "nigr(A)ngelus", "matif", "Bussdee", "aveng3r", "Havorn", "Slayblaze",
                       "ArcticXWolf", "Caelin", "Mavoc", "Titan Panel Development Team"):
            self.assertIn(needed, notice)
        self.assertIn("CC BY-NC-SA 3.0", (SOURCE / "README.md").read_text(encoding="utf-8"))
        self.assertEqual((SOURCE / "LICENSE.txt").read_bytes(), (ROOT / "LICENSE.txt").read_bytes())

    def test_nothing_from_titan_panel_is_packaged(self):
        for path in SOURCE.rglob("*"):
            self.assertNotIn("titan", path.name.lower(), path)
        for path in SOURCE.glob("*.lua"):
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("TitanPanel", text, path)
            self.assertNotIn("LibStub", text, path)

    def test_no_xbar_art_is_left(self):
        for path in SOURCE.rglob("*"):
            self.assertNotIn(path.name.lower(), ("bar_bgndm.tga", "baru_bgndm.tga", "sysbtn_normal.tga", "logo.tga"), path)
        for skin in ("Black", "Gloss", "Blockz", "AdPanel", "Tribal", "Stone", "Steel", "Frost", "Walnut", "Moss", "Amethyst"):
            self.assertFalse((SOURCE / "Media/Skins" / skin).exists(), skin)

    def test_hub_knows_the_addon(self):
        hub = (KIT / "CherrysKit.lua").read_text(encoding="utf-8")
        self.assertIn('CherrysBar = "-XBARVERSION"', hub)
        self.assertIn('Kit.OLD_FOLDERS = { CherrysBar = "XBar" }', hub)
        self.assertIn('"CherrysBar", "ControlHub"', hub)
        self.assertIn('CherrysBar = "Interface/AddOns/CherrysKit/CherrysBar/"', (KIT / "KitPaths.lua").read_text(encoding="utf-8"))
        self.assertIn('CherrysBar = "/cbar"', (KIT / "Commands.lua").read_text(encoding="utf-8"))

    def test_old_xbar_folder_turns_it_off_and_the_hub_names_that_folder(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("""
            messages = {}
            DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) messages[#messages + 1] = msg end }
            function SaveVariables() end
        """)
        lua.execute((KIT / "CherrysKit.lua").read_text(encoding="utf-8"))
        self.assertTrue(lua.eval("CherrysKit.IsEnabled('CherrysBar')"))
        lua.execute("XBARVERSION = 1.71; CherrysKit.WarnOldCopies()")
        self.assertFalse(lua.eval("CherrysKit.IsEnabled('CherrysBar')"))
        text = " ".join(str(v) for v in lua.eval("messages").values())
        self.assertIn("AddOns\\XBar.", text)


if __name__ == "__main__":
    unittest.main()
