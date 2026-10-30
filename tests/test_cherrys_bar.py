"""Cherry's Bar: bars, displays, settings, throttling and hub links in a fake client."""

from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface/AddOns/CherrysKit"
SOURCE = KIT / "CherrysBar"
FILES = ("Core.lua", "Bars.lua", "Displays.lua", "DisplayList.lua", "Menu.lua", "Options.lua", "Probe.lua")
NS = "{http://www.runewaker.com/}"

CLIENT = r'''
messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, text) messages[#messages + 1] = text end }
calls = { bag = 0, ping = 0, opened = {} }
now, inCombat, zone = 100, false, "Varanas"
state = { used = 10, total = 60, gold = 1234567, fps = 60, ping = 40, xp = 500, xpMax = 1000 }
function GetTime() return now end
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
function GetPlayerMoney(kind) return kind == "copper" and state.gold or 5 end
function GetFramerate() calls.ping = calls.ping + 1; return state.fps end
function GetPing() return state.ping end
function GetZoneName() return zone end
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
  return self.w or 0
end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetTexture(t) self.texture = t end
function Widget:SetChecked(v) self.checked = v end
function Widget:GetFont() return "fonts/game.ttf", 12 end
function Widget:SetFont(path, size) self.fontSize = size end
function Widget:GetPos() return self.posX or 100, 0 end
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
GameFrame("MainMenuFrame", 0, 0, "BOTTOM")
GameFrame("ExperienceFrame", 0, 0, "BOTTOMLEFT")
MakeWidget("EquipDameFrame", true)
MakeWidget("BagFrame", false)
MakeWidget("WorldMapFrame", false)
GameTooltip = MakeWidget("GameTooltip", false)
function GameTooltip:SetOwner() end
function GameTooltip:AddLine(t) self.lines = self.lines or {}; self.lines[#self.lines + 1] = t end
function GameTooltip:AddDoubleLine(a, b) self.lines = self.lines or {}; self.lines[#self.lines + 1] = a .. "=" .. tostring(b) end
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

    def test_default_is_top_bar_only_with_its_displays(self):
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.assertFalse(self.ev("CBar_BarBottom.shown"))
        shown = [d for d in ("Menu", "Exp", "Bag", "Money", "Mail", "Perf", "Clock")
                 if self.ev(f"_G['CBar_D' .. CherrysBar.Displays.byKey.{d}.slot].shown")]
        self.assertEqual(len(shown), 7)
        for hidden in ("Zone", "Friends", "Guild", "Ammo", "Class", "Craft", "Dps"):
            self.assertFalse(self.ev(f"_G['CBar_D' .. CherrysBar.Displays.byKey.{hidden}.slot].shown"), hidden)

    def test_bars_anchor_to_their_screen_edge(self):
        self.run_lua("CherrysBar.Command('both')")
        self.assertEqual(self.ev("CBar_BarTop.anchors[1][1]"), "TOPLEFT")
        self.assertEqual(self.ev("CBar_BarBottom.anchors[1][1]"), "BOTTOMLEFT")
        self.assertIn("barU_bgndM", self.ev("CBar_BarBottomM.texture"))
        self.assertIn("/bar_bgndM", self.ev("CBar_BarTopM.texture"))

    def test_commands_choose_bars(self):
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertFalse(self.ev("CBar_BarTop.shown"))
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.run_lua("CherrysBar.Command('top')")
        self.assertTrue(self.ev("CBar_BarTop.shown"))
        self.assertFalse(self.ev("CBar_BarBottom.shown"))

    def test_displays_are_set_per_bar_and_flow_without_overlap(self):
        self.run_lua("""
            CherrysBar.Command('both')
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Zone, 'bottom')
            D.SetBar(D.byKey.Friends, 'bottom')
            function right_edge(key)
              local def = D.byKey[key]
              local frame = _G['CBar_D' .. def.slot]
              return frame.anchors[1][4] + frame.w
            end
            function left_edge(key) return _G['CBar_D' .. D.byKey[key].slot].anchors[1][4] end
            function rel(key) return _G['CBar_D' .. D.byKey[key].slot].anchors[1][3] end
        """)
        self.assertEqual(self.ev("rel('Zone')"), "CBar_BarBottom")
        self.assertEqual(self.ev("rel('Bag')"), "CBar_BarTop")
        self.assertGreaterEqual(self.ev("left_edge('Friends')"), self.ev("right_edge('Zone')"))
        self.assertGreaterEqual(self.ev("left_edge('Bag')"), self.ev("right_edge('Exp')"))
        self.assertEqual(self.ev("_G['CBar_D' .. CherrysBar.Displays.byKey.Clock.slot].anchors[1][1]"), "RIGHT")

    def test_moving_swaps_neighbours_and_survives_rebuild(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Move(D.byKey.Bag, -1)
            D.Rebuild()
            order = {}
            for i, def in ipairs(D.Row('top', 'left')) do order[i] = def.key end
        """)
        self.assertEqual([self.ev(f"order[{i}]") for i in (1, 2, 3, 4)], ["Menu", "Bag", "Exp", "Money"])

    def test_format_tokens_label_and_colour(self):
        self.assertIn("Bag", self.text_of("Bag"))
        self.assertIn("10", self.text_of("Bag"))
        self.run_lua("""
            local D = CherrysBar.Displays
            local cfg = D.Config(D.byKey.Bag)
            cfg.fmt, cfg.label, cfg.color = '[USED] of [TOTAL] ([LOAD]%) [NOPE]', false, false
            D.Rebuild()
        """)
        self.assertEqual(self.text_of("Bag"), "10 of 60 (17%) [NOPE]")

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
        self.run_lua("""
            local D = CherrysBar.Displays
            D.SetBar(D.byKey.Dps, 'top')
        """)
        self.assertIsNone(self.ev("CBar_Events.events.UNIT_HEALTH"))
        self.assertTrue(self.ev("CBar_Events.events.COMBATMETER_DAMAGE"))
        self.run_lua("""
            local D = CherrysBar.Displays
            D.Config(D.byKey.Dps).fmt = '[KILLS]'
            D.Rebuild()
        """)
        self.assertTrue(self.ev("CBar_Events.events.UNIT_HEALTH"))
        self.assertIsNone(self.ev("CBar_Events.events.COMBATMETER_DAMAGE"))

    def test_idle_frames_make_no_garbage_and_no_text_writes(self):
        self.run_lua("""
            collectgarbage('collect')
            collectgarbage('stop')
            local before = collectgarbage('count')
            writes = 0
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
        self.assertTrue(any("gone" in str(m) for m in self.lua.table_from(self.ev("messages")).values()))

    def test_make_room_moves_top_frames_and_restores_them(self):
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.assertEqual(self.anchor_y("TargetFrame"), 26)
        self.assertEqual(self.anchor_y("MinimapFrame"), 56)
        self.assertEqual(self.anchor_y("MinimapFrameBorder"), 23)
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)
        self.assertEqual(self.anchor_y("MinimapFrame"), 32)
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        self.assertEqual(self.anchor_y("ExperienceFrame"), -24)
        self.run_lua("CherrysBar.Command('top')")
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_make_room_is_not_applied_twice(self):
        self.run_lua("CherrysBar.Bars.MakeRoom(); CherrysBar.Bars.MakeRoom()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.run_lua("CherrysBar.OnEvent('LOADING_END')")
        self.tick(4)
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_make_room_follows_a_taller_skin(self):
        self.run_lua("CherrysBar.S().bars.top.skin = 'Black'; CherrysBar.Refresh()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 32)
        self.run_lua("CherrysBar.S().bars.top.skin = 'Slate'; CherrysBar.Refresh()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_make_room_leaves_a_frame_the_player_dragged_away(self):
        self.run_lua("""
            PlayerFrame:ClearAllAnchors()
            PlayerFrame:SetAnchor('TOPLEFT', 'TOPLEFT', 'UIParent', 300, 400)
            CherrysBar.Bars.MakeRoom()
        """)
        self.assertEqual(self.anchor_y("PlayerFrame"), 400)

    def test_make_room_off_touches_nothing(self):
        self.run_lua("CherrysBar.S().makeRoom = false; CherrysBar.Refresh()")
        self.assertEqual(self.anchor_y("PlayerFrame"), 0)
        self.assertEqual(self.anchor_y("MainMenuFrame"), 0)

    def test_hiding_game_frames_only_shows_what_it_hid(self):
        self.run_lua("MainMenuFrame:Hide(); CherrysBar.Refresh()")
        self.assertFalse(self.ev("MainMenuFrame.shown"))
        self.run_lua("CherrysBar.S().hideMenuBar = true; CherrysBar.Refresh(); MainMenuFrame:Show(); CherrysBar.Refresh()")
        self.assertFalse(self.ev("MainMenuFrame.shown"))
        self.run_lua("CherrysBar.S().hideMenuBar = false; CherrysBar.Refresh()")
        self.assertTrue(self.ev("MainMenuFrame.shown"))

    def test_right_click_menu_changes_a_display(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            slot = D.byKey.Bag.slot
            D.Click(slot, 'RBUTTON')
        """)
        self.assertTrue(self.ev("CBar_Menu.shown"))
        rows = {}
        for i in range(1, 25):
            if self.ev(f"CBar_MenuRow{i}.shown"):
                rows[self.ev(f"CBar_MenuRow{i}Text.text")] = i
        self.assertIn("[x] Show icon", rows)
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['[x] Show icon']}, 'LBUTTON')")
        self.assertFalse(self.ev("CherrysBar.Displays.Config(CherrysBar.Displays.byKey.Bag).icon"))
        self.assertTrue(self.ev("CBar_Menu.shown"))
        rows = {self.ev(f"CBar_MenuRow{i}Text.text"): i for i in range(1, 25) if self.ev(f"CBar_MenuRow{i}.shown")}
        self.run_lua(f"CherrysBar.Menu.RowClick({rows['Move to the bottom bar']}, 'LBUTTON')")
        self.assertEqual(self.ev("CherrysBar.Displays.Config(CherrysBar.Displays.byKey.Bag).bar"), "bottom")

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

    def test_left_click_does_the_display_job(self):
        self.run_lua("CherrysBar.Displays.Click(CherrysBar.Displays.byKey.Bag.slot, 'LBUTTON')")
        self.assertEqual(self.ev("calls.opened[1]"), "BagFrame")

    def test_a_click_on_a_missing_game_call_gives_a_message(self):
        self.run_lua("OpenMail = nil; CherrysBar.Displays.Click(CherrysBar.Displays.byKey.Mail.slot, 'LBUTTON')")
        self.assertIn("could not", self.ev("messages[#messages]"))

    def test_mail_counts_system_messages(self):
        self.run_lua("CherrysBar.OnEvent('CHAT_MSG_SYSTEM', 'SYS_NEW_MAIL'); CherrysBar.OnEvent('CHAT_MSG_SYSTEM', 'hello')")
        self.tick()
        self.assertIn("1", self.text_of("Mail"))
        self.run_lua("CherrysBar.OnEvent('MAIL_SHOW')")
        self.tick()
        self.assertIn("0", self.text_of("Mail"))

    def test_options_rows_and_format_editor(self):
        self.run_lua("CherrysBar.Options.Toggle()")
        self.assertTrue(self.ev("CBar_Options.shown"))
        self.assertEqual(self.ev("CBar_OptRow1Label.text"), "Show the top bar")
        self.run_lua("CherrysBar.Options.RowClick(4, 'check')")
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.run_lua("CherrysBar.Options.RowClick(2, 'choice')")
        self.assertEqual(self.ev("CherrysBar.S().bars.top.skin"), "Black")
        self.assertEqual(self.ev("CBar_BarTop.h"), 32)
        slot = self.ev("CherrysBar.Displays.byKey.Bag.slot")
        self.run_lua(f"CherrysBar.Options.DisplayClick({slot}, 'pick')")
        self.assertEqual(self.ev("CBar_OptionsFormat.text"), "[USED]/[TOTAL]")
        self.run_lua("CBar_OptionsFormat:SetText('[TOTAL]'); CherrysBar.Options.ApplyFormat()")
        self.assertIn("60", self.text_of("Bag"))
        self.run_lua("CherrysBar.Options.ResetFormat()")
        self.assertEqual(self.ev("CBar_OptionsFormat.text"), "[USED]/[TOTAL]")
        self.run_lua(f"CherrysBar.Options.DisplayClick({slot}, 'bar')")
        self.assertEqual(self.ev("CherrysBar.Displays.Config(CherrysBar.Displays.byKey.Bag).bar"), "bottom")

    def test_every_option_row_click_works(self):
        for i in range(1, 13):
            kind = self.ev(f"CherrysBar.Options.LIST[{i}].kind")
            for part in {"check": ["check"], "num": ["minus", "plus"], "choice": ["choice"]}[kind]:
                self.run_lua(f"CherrysBar.Options.RowClick({i}, '{part}')")

    def test_settings_survive_reload_in_the_same_lua_state(self):
        self.run_lua("""
            local D = CherrysBar.Displays
            CherrysBar.S().bars.bottom.show = true
            D.SetBar(D.byKey.Zone, 'bottom')
        """)
        self.load_addon()
        self.assertTrue(self.ev("CBar_BarBottom.shown"))
        self.assertEqual(self.ev("CherrysBar.Displays.Config(CherrysBar.Displays.byKey.Zone).bar"), "bottom")

    def test_reload_does_not_move_frames_twice(self):
        # Frames that kept their place through Reload UI...
        self.load_addon()
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)
        self.assertEqual(self.anchor_y("MinimapFrame"), 56)
        self.run_lua("CherrysBar.Command('bottom')")
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        self.load_addon()
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        # ...and frames the reload rebuilt at the game's own positions.
        self.run_lua("""
            MainMenuFrame:ClearAllAnchors()
            MainMenuFrame:SetAnchor('BOTTOM', 'BOTTOM', 'UIParent', 0, 0)
            CherrysBar.S().bars.top.show = true
            PlayerFrame:ClearAllAnchors()
            PlayerFrame:SetAnchor('TOPLEFT', 'TOPLEFT', 'UIParent', 0, 0)
        """)
        self.load_addon()
        self.assertEqual(self.anchor_y("MainMenuFrame"), -24)
        self.assertEqual(self.anchor_y("PlayerFrame"), 24)

    def test_text_size_changes_only_after_the_player_asks(self):
        self.assertIsNone(self.ev("CBar_D2Text.fontSize"))
        self.run_lua("CherrysBar.S().textSize = 14; CherrysBar.Refresh()")
        self.assertEqual(self.ev("CBar_D2Text.fontSize"), 14)

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
        self.assertEqual(self.ev("PlayerFrame.anchors[1][5]"), 24)  # from the first load, not moved again

    def test_slash_command_and_probe(self):
        self.run_lua("SlashCmdList['CHERRYSBAR'](nil, 'probe')")
        text = " ".join(str(v) for v in self.ev("messages").values())
        self.assertIn("missing functions", text)
        self.assertIn("displays shown", text)

    def test_tooltip_is_built_on_hover_and_quiet_in_combat(self):
        slot = self.ev("CherrysBar.Displays.byKey.Money.slot")
        self.run_lua(f"CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertTrue(any("Gold" in str(v) for v in self.ev("GameTooltip.lines").values()))
        self.run_lua(f"GameTooltip.lines = nil; inCombat = true; CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertIsNone(self.ev("GameTooltip.lines"))
        self.run_lua(f"CherrysBar.S().tipsInCombat = true; CherrysBar.Displays.Enter({slot}, _G['CBar_D{slot}'])")
        self.assertIsNotNone(self.ev("GameTooltip.lines"))

    def test_every_display_reads_and_tips_without_error(self):
        for key in self.ev("CherrysBar.Displays.byKey").keys():
            self.run_lua(f"""
                local D = CherrysBar.Displays
                local def = D.byKey.{key}
                D.SetBar(def, 'top')
                D.Enter(def.slot, _G['CBar_D' .. def.slot])
                assert(not def.err, def.err)
            """)
            self.assertFalse(self.ev(f"CherrysBar.Displays.byKey.{key}.err"), key)


class PackageTest(unittest.TestCase):
    def test_xml_handlers_call_functions_that_exist(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(CLIENT)
        make = lua.globals().MakeWidget
        for name in xml_names():
            make(name, False)
        for name in FILES:
            lua.execute((SOURCE / name).read_text(encoding="utf-8"))
        text = (SOURCE / "CherrysBar.xml").read_text(encoding="utf-8")
        calls = set(re.findall(r"CherrysBar\.[A-Za-z.]+(?=\()", text))
        self.assertTrue(calls)
        for call in calls:
            self.assertEqual(lua.eval(f"type({call})"), "function", call)

    def test_xml_parses_and_slots_match_the_list(self):
        tree = ET.parse(SOURCE / "CherrysBar.xml")
        names = {el.get("name") for el in tree.iter(NS + "Frame")}
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(CLIENT)
        for name in FILES:
            lua.execute((SOURCE / name).read_text(encoding="utf-8"))
        count = lua.eval("#CherrysBar.Displays.list")
        for i in range(1, count + 1):
            self.assertIn(f"CBar_D{i}", names)
            self.assertIn(f"CBar_OptD{i}", names)
        self.assertNotIn(f"CBar_D{count + 1}", names)

    def test_toc_lists_lua_and_every_file_exists(self):
        toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8-sig")
        self.assertIn("CherrysBar_DB", toc)
        for name in FILES + ("CherrysBar.xml",):
            self.assertIn("CherrysBar/" + name, toc)
        self.assertIn("KitLoad/CherrysBar.lua", toc)

    def test_every_skin_has_top_and_bottom_art(self):
        for skin in ("Slate", "Black", "Gloss", "Blockz", "AdPanel", "Tribal"):
            for name in ("bar_bgndL", "bar_bgndM", "bar_bgndR", "barU_bgndL", "barU_bgndM", "barU_bgndR"):
                self.assertTrue((SOURCE / "Media/Skins" / skin / (name + ".tga")).is_file(), (skin, name))
        self.assertTrue((SOURCE / "Media/Icons/SysBtn_Normal.tga").is_file())

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
