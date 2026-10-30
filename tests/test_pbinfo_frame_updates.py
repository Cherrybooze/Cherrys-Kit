"""pbInfo's timers refresh a few times a second instead of on every frame."""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


PBINFO = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/pbInfo"
NS = {"ui": "http://www.runewaker.com/"}


def scripts(xml_name, frame_name):
    root = ET.parse(PBINFO / "Xml" / xml_name).getroot()
    frame = root.find(f".//ui:Frame[@name='{frame_name}']", NS)
    return {child.tag.split("}")[-1]: child.text for child in frame.find("ui:Scripts", NS)}


class PbInfoFrameUpdateTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          now = 10
          function GetTime() return now end
          local Widget = {}
          Widget.__index = Widget
          function Widget:IsVisible() return self.shown end
          function Widget:Show() self.shown = true end
          function Widget:Hide() self.shown = false end
          function Widget:SetAlpha(alpha) self.alpha = alpha end
          function Widget:GetText() return self.text end
          function Widget:SetText(text) self.text = text; self.sets = (self.sets or 0) + 1 end
          function Widget:RegisterEvent(name) self.events = self.events or {}; self.events[#self.events + 1] = name end
          function widget(name, shown) _G[name] = setmetatable({shown = shown}, Widget); return _G[name] end
          widget("GameTooltip", false)
          widget("GameTooltipTextLeft1", true)
          widget("CastingBarFrame", false)
          widget("CastingBarText", true)
          widget("pbInfoCastingBarText", true)
          widget("pbInfoCastingBarTime", true)
          widget("pbInfoCastingBar_MovingFrame", false)
          widget("pbInfoCastingBarHider", true)
          widget("pbInfoCastingBar_Display", false)
          DEFAULT_CHAT_FRAME = {AddMessage = function() end}
          SlashCmdList = {}
          rebuilds = 0
          pbInfo = {CastingBar = {}, Tooltip = {Scripts = {OnUpdate = function()
            rebuilds = rebuilds + 1
            if GameTooltipTextLeft1.text == "Mob" then GameTooltipTextLeft1.text = "Mob - Elite" end
          end}}, Version = "test"}
          pbInfoSettings = {ENABLE = true, CASTINGBARHIDEDEFAULT = true, CASTINGBARSHOWCASTTIME = true}
        ''')
        self.lua.execute((PBINFO / "pbInfoKit.lua").read_text(encoding="utf-8-sig"))

    def handler(self, xml_name, frame_name, script, args):
        self.lua.globals().handlerSource = scripts(xml_name, frame_name)[script]
        return self.lua.eval(f'assert(loadstring("local {args} = ...\\n" .. handlerSource))')

    def test_tooltip_rebuilds_ten_times_a_second_and_at_once_for_a_new_tooltip(self):
        tick = self.handler("pbInfo.xml", "pbInfoTooltipTimer", "OnUpdate", "this, elapsedTime")
        self.lua.globals().tick = tick
        self.lua.execute('''
          local function frames(count) for i = 1, count do tick(pbInfoTooltipTimer, 0.016) end end
          frames(10)
          assert(rebuilds == 0, "hidden tooltip was rebuilt")
          GameTooltip.shown = true; GameTooltipTextLeft1.text = "Mob"
          frames(1)
          assert(rebuilds == 1, "a tooltip that opens is set up at once")
          frames(5)
          assert(rebuilds == 1, "pbInfo's own first line change must not cause another rebuild")
          frames(2)
          assert(rebuilds == 2, "live numbers refresh after 0.1 s, got " .. rebuilds)
          GameTooltipTextLeft1.text = "Item"
          frames(1)
          assert(rebuilds == 3, "a tooltip whose first line changed is set up at once")
          GameTooltip.shown = false; frames(1); GameTooltip.shown = true; frames(1)
          assert(rebuilds == 4, "a tooltip that opens again is set up at once")
          rebuilds = 0
          frames(625)
          assert(rebuilds >= 80 and rebuilds <= 100, "10 seconds of frames gave " .. rebuilds .. " rebuilds")
        ''')

    def test_tooltip_timer_without_the_kit_glue_still_works(self):
        tick = self.handler("pbInfo.xml", "pbInfoTooltipTimer", "OnUpdate", "this, elapsedTime")
        self.lua.execute("pbInfo.Kit = nil; GameTooltip.shown = true")
        tick(None, 0.016)
        self.assertEqual(self.lua.globals().rebuilds, 1)

    def test_cast_bar_hides_on_cast_events_and_is_checked_four_times_a_second(self):
        onload = self.handler("CastingBar.xml", "pbInfoCastingBarHider", "OnLoad", "this")
        onload(self.lua.globals().pbInfoCastingBarHider)
        self.assertEqual(
            list(self.lua.globals().pbInfoCastingBarHider.events.values()),
            ["CASTING_START", "CASTING_STOP", "CASTING_FAILED", "CASTING_DELAYED"],
        )
        onevent = self.handler("CastingBar.xml", "pbInfoCastingBarHider", "OnEvent", "this, event")
        tick = self.handler("CastingBar.xml", "pbInfoCastingBarHider", "OnUpdate", "this, elapsedTime")
        self.lua.globals().onevent, self.lua.globals().tick = onevent, tick
        self.lua.execute('''
          local keep = pbInfo.CastingBar.KeepHidden
          checks = 0
          pbInfo.CastingBar.KeepHidden = function() checks = checks + 1; keep() end
          CastingBarFrame.shown = true
          onevent(pbInfoCastingBarHider, "CASTING_START")
          assert(CastingBarFrame.shown == false and CastingBarFrame.alpha == 0, "cast start hides the bar at once")
          tick(pbInfoCastingBarHider, 0.016)
          CastingBarFrame.shown = true
          for i = 1, 14 do tick(pbInfoCastingBarHider, 0.016) end
          assert(CastingBarFrame.shown == true, "the safety check waits a quarter second")
          for i = 1, 2 do tick(pbInfoCastingBarHider, 0.016) end
          assert(CastingBarFrame.shown == false, "the safety check hides it again")
          checks = 0
          for i = 1, 625 do tick(pbInfoCastingBarHider, 0.016) end
          assert(checks >= 39 and checks <= 41, "10 seconds of frames gave " .. checks .. " checks")
          pbInfoSettings.CASTINGBARHIDEDEFAULT = false
          for i = 1, 16 do tick(pbInfoCastingBarHider, 0.016) end
          assert(CastingBarFrame.alpha == 1, "turning the setting off gives the bar its alpha back")
        ''')

    def test_cast_time_text_only_changes_when_the_tenth_shown_changes(self):
        onevent = self.handler("CastingBar.xml", "pbInfoCastingBar_Display", "OnEvent", "this, event, arg1, arg2")
        update = self.handler("CastingBar.xml", "pbInfoCastingBar_Display", "OnUpdate", "this, elapsedTime")
        self.lua.globals().onevent, self.lua.globals().update = onevent, update
        self.lua.execute('''
          shown = {}
          local set = pbInfoCastingBarTime.SetText
          pbInfoCastingBarTime.SetText = function(self, text) shown[#shown + 1] = text; set(self, text) end
          onevent(pbInfoCastingBar_Display, "CASTING_START", "Fireball", 2.5)
          assert(pbInfoCastingBar_Display.shown and pbInfoCastingBarText.text == "Fireball")
          for i = 1, 200 do
            now = now + 1 / 60
            update(pbInfoCastingBar_Display, 1 / 60)
          end
          assert(#shown <= 26, #shown .. " texts for a 2.5 s cast")
          assert(shown[#shown] == "0.0 sec", tostring(shown[#shown]))
          for i = 2, #shown do assert(shown[i] ~= shown[i - 1], "same text set twice: " .. shown[i]) end
          local before = #shown
          onevent(pbInfoCastingBar_Display, "CASTING_START", "Heal", 1)
          now = now + 1 / 60
          update(pbInfoCastingBar_Display, 1 / 60)
          assert(#shown == before + 1 and shown[#shown] == "1.0 sec", "a new cast shows its time at once")
        ''')

    def test_char_data_timer_stops_when_os_dates_are_missing(self):
        onload = self.handler("pbInfo.xml", "pbInfoCharDataTimer", "OnLoad", "this")
        self.lua.execute('widget("pbInfoCharDataTimer", true); os = {}')
        onload(None)
        self.assertFalse(self.lua.globals().pbInfoCharDataTimer.shown)


class PlayerSearchTests(unittest.TestCase):
    def test_hovering_an_unknown_player_searches_at_most_once_a_second(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
          now = 10
          function GetTime() return now end
          function pbIsEmpty(value) return value == nil or value == "" end
          searches = 0
          function SearchGroupPeople() searches = searches + 1 end
          pbInfo = {Tooltip = {Scripts = {}}, Hooked = {}, Classes = {Mage = {index = 4}},
            PlayerDB = {Players = {Realm = {}}}, RealmName = "Realm",
            Original = function(_, fn) return fn end, MarkOurs = function(fn) return fn end}
        ''')
        lua.execute((PBINFO / "Includes/inc.Tooltip.lua").read_text(encoding="utf-8-sig"))
        lua.execute('''
          for i = 0, 11 do
            now = 10 + i * 0.25
            pbInfo.Tooltip.getPlayerInfo("Stranger", "Mage", 50, "", 0)
          end
          assert(searches == 3, "3 seconds of refreshes searched " .. searches .. " times")
          pbInfo.PlayerDB.Players.Realm.Friend = {_time = now}
          searches = 0
          now = now + 5
          assert(pbInfo.Tooltip.getPlayerInfo("Friend", "Mage", 50, "", 0)._time ~= nil)
          assert(searches == 0, "a known player is not searched")
        ''')


if __name__ == "__main__":
    unittest.main()
