"""Cherry's Quests: tracker drawing, Ctrl+click NPC cycling, throttling and options in a fake client."""

from pathlib import Path
import re
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysQuests"
FILES = ("CherrysQuests.lua", "Npcs.lua", "Tracker.lua", "Options.lua", "Probe.lua")

CLIENT = r'''
calls = { track = 0, request = 0, quick = {}, setTarget = {}, view = {} }
mods = { ctrl = false, alt = false, shift = false }
function IsCtrlKeyDown() return mods.ctrl end
function IsAltKeyDown() return mods.alt end
function IsShiftKeyDown() return mods.shift end
function UnitName(unit) return "Cherry" end
function GetCurrentVocLV() return 40 end
function GetUIScale() return 1 end
function Daily_count() return 3, 10 end
messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, text) messages[#messages + 1] = text end }

npcs = {
  [110001] = { name = "Elder Kalin", map = 2, x = 0.5, y = 0.25 },
  [110002] = { name = "Guard Loran", map = 2, x = 0.1, y = 0.2 },
  [110003] = { name = "Herbalist Mira", map = 3, x = 0.4, y = 0.6 },
  [110004] = { name = "Captain Rhys", map = 2, x = 0.7, y = 0.7 },
}
quests = {
  [5] = { name = "Wolves at the Gate", level = 41, lines = { "Wolf Pelt: 3/10", "Report to Guard Loran" },
          summary = "Speak with |Hnpc:110001|h[Elder Kalin]|h, then ask [110002] about the wolves. [Herbalist Mira] knows more.",
          turnIn = 110004 },
  [9] = { name = "Old Debts (Complete)", level = 38, lines = { "Collect the debt (Complete)" }, summary = "", turnIn = 110004,
          daily = true },
  [7] = { name = "No Names Here", level = 45, lines = { "Kill boars: 0/5" }, summary = "Just boars." },
}
tracked = { 5, 9, 7 }
function GetQuestTrack(i)
  calls.track = calls.track + 1
  if i == -1 then return #tracked end
  return tracked[i]
end
function GetQuestRequest(id, i)
  calls.request = calls.request + 1
  local q = quests[id]
  if not q then return nil end
  if i == -2 then return q.name end
  if i == -3 then return q.level end
  return q.lines[i]
end
function GetQuestInfo(id) local q = quests[id]; return id, 1, q and q.name, 2, q and q.level, q and q.daily or false end
viewed = nil
function ViewQuest_QuestBook(id) viewed = id; calls.view[#calls.view + 1] = id end
function GetQuestDetail_QuestDetailShort() return viewed and quests[viewed].summary or "" end
function GetQuestDetail_QuestDetail() return "" end
function GetQuestDesc_QuestDetail() return "" end
function QuestDetail_GetRequestQuestNPC() return viewed and quests[viewed].turnIn or 0 end
function QuestDetail_GetQuestNPC() return 0 end
function GetZoneLocalName(map) return "Zone" .. tostring(map) end
results = {}
function NpcTrack_SearchNpcByDBID(id)
  results = {}
  local n = npcs[id]
  if n then results[1] = { id, n.name, n.map, n.x, n.y } end
  return #results
end
function NpcTrack_SearchNpc(name, ci)
  results = {}
  for id, n in pairs(npcs) do
    if string.find(string.lower(n.name), string.lower(name), 1, true) then
      results[#results + 1] = { id, n.name, n.map, n.x, n.y }
    end
  end
  return #results
end
function NpcTrack_GetNpc(i) local r = results[i]; if r then return r[1], r[2], r[3], r[4], r[5] end end
function NpcTrack_GetMax() return 10 end
function NpcTrackFrame_QuickTrackByNpcID(id) calls.quick[#calls.quick + 1] = id end
function NpcTrack_SetTarget(slot, id, r, g, b) calls.setTarget[#calls.setTarget + 1] = { slot, id } end

local Widget = {}
Widget.__index = Widget
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:IsVisible() return self.shown end
function Widget:SetText(t) self.text = t end
function Widget:GetText() return self.text end
function Widget:GetName() return self.name end
function Widget:ClearAllAnchors() self.anchor = nil end
function Widget:SetAnchor(p, rp, rel, x, y) self.anchor = { p, rp, rel, x, y } end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
function Widget:GetHeight() return 0 end
function Widget:SetColor(r, g, b) self.color = { r, g, b } end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetFont(path, size, weight, outline) self.font = { path, size, outline } end
function Widget:SetFontSize(size) self.fontSize = size end
function Widget:GetFont() return "fonts/game.ttf", 12 end
function Widget:SetChecked(v) self.checked = v end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:GetPos() return 500, 300 end
function Widget:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function MakeWidget(name, hidden)
  _G[name] = setmetatable({ name = name, shown = not hidden }, Widget)
end
QuestTrackerFrame = setmetatable({ name = "QuestTrackerFrame", shown = true }, Widget)
pbInfoQuestTracker = setmetatable({ name = "pbInfoQuestTracker", shown = true }, Widget)
buttonClicks = 0
function OnClick_QuestTrackButton() buttonClicks = buttonClicks + 1 end
GameTooltip = setmetatable({ name = "GameTooltip", lines = {} }, Widget)
function GameTooltip:SetOwner() self.lines = {} end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:AddLine(t) self.lines[#self.lines + 1] = t end
'''


class CherrysQuestsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        xml = (SOURCE / "CherrysQuests.xml").read_text(encoding="utf-8")
        for name, hidden in re.findall(r'name="(CQ_[A-Za-z0-9_]+)"([^>]*)', xml):
            self.lua.globals().MakeWidget(name, 'hidden="true"' in hidden)
        self.load()
        self.start()

    def load(self):
        for name in FILES:
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        self.lua.execute("CherrysQuests.OnLoad(CQ_Events)")

    def start(self):
        self.lua.execute('CherrysQuests.OnEvent("VARIABLES_LOADED"); CherrysQuests.OnUpdate(0.01)')

    def frames(self, seconds, step=1 / 60):
        self.lua.execute(f"for i = 1, {int(seconds / step)} do CherrysQuests.OnUpdate({step}) end")

    def eval(self, code):
        return self.lua.eval(code)

    def test_tracker_draws_sorted_quests_and_hides_the_other_trackers(self):
        self.frames(0.6)
        self.assertTrue(self.eval("CQ_Tracker.shown"))
        titles = [self.eval(f"CQ_Row{i}Title.text") for i in (1, 2, 3)]
        self.assertIn("Old Debts", titles[0])          # level 38 first
        self.assertIn("Wolves at the Gate", titles[1])
        self.assertIn("No Names Here", titles[2])
        self.assertNotIn("(Complete)", titles[0])
        self.assertIn("Done", titles[0])
        self.assertIn("3/10", self.eval("CQ_Row2Text.text"))
        self.assertFalse(self.eval("CQ_Row4.shown"))
        self.assertIn("Daily 7/10", self.eval("CQ_HeadTitle.text"))
        self.assertFalse(self.eval("QuestTrackerFrame.shown"))
        self.assertFalse(self.eval("pbInfoQuestTracker.shown"))

    def test_rows_stack_without_overlap(self):
        self.frames(0.6)
        y1 = self.eval("CQ_Row1.anchor[5]")
        h1 = self.eval("CQ_Row1.h")
        y2 = self.eval("CQ_Row2.anchor[5]")
        self.assertGreaterEqual(y2, y1 + h1)
        self.assertGreater(self.eval("CQ_Tracker.h"), y2)

    def test_ctrl_click_cycles_named_npcs_in_text_order_then_turn_in(self):
        self.frames(0.6)
        self.lua.execute("mods.ctrl = true")
        seen = []
        for _ in range(5):
            self.lua.execute('CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
            seen.append(self.eval("calls.quick[#calls.quick]"))
        # link, bare id, name search, turn-in NPC, then back to the first
        self.assertEqual(seen, [110001, 110002, 110003, 110004, 110001])
        self.assertEqual(self.eval('CherrysQuests_DB.chars["Cherry"].picks["Wolves at the Gate"].id'), 110001)
        self.lua.execute('CherrysQuests.Tracker.RowClick(2, "RBUTTON")')
        self.assertEqual(self.eval("calls.quick[#calls.quick]"), 110004)
        self.lua.execute('mods.ctrl = false; mods.alt = true; CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertEqual(self.eval("calls.quick[#calls.quick]"), 110004)
        self.assertIn("Captain Rhys", self.eval("CQ_Row2Npc.text"))
        self.assertTrue(any("tracking Captain Rhys" in str(m) for m in self.lua.globals().messages.values()))

    def test_pick_survives_reload_and_the_next_ctrl_click_moves_on(self):
        self.frames(0.6)
        self.lua.execute('mods.ctrl = true; CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.load()
        self.start()
        self.frames(0.6)
        self.assertIn("Elder Kalin", self.eval("CQ_Row2Npc.text"))
        self.lua.execute('CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertEqual(self.eval("calls.quick[#calls.quick]"), 110002)

    def test_a_fixed_slot_uses_the_tracking_list_directly(self):
        self.frames(0.6)
        self.lua.execute('CherrysQuests.S().slot = 3; mods.ctrl = true; CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertEqual(list(self.eval("calls.setTarget[1]").values()), [3, 110001])
        self.assertEqual(len(self.lua.globals().calls.quick), 0)

    def test_without_quick_track_it_falls_back_to_slot_one(self):
        self.lua.execute("NpcTrackFrame_QuickTrackByNpcID = nil")
        self.frames(0.6)
        self.lua.execute('mods.ctrl = true; CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertEqual(list(self.eval("calls.setTarget[1]").values()), [1, 110001])

    def test_a_quest_without_names_says_so(self):
        self.frames(0.6)
        self.lua.execute('mods.ctrl = true; CherrysQuests.Tracker.RowClick(3, "LBUTTON")')
        self.assertTrue(any("no named NPC" in str(m) for m in self.lua.globals().messages.values()))

    def test_plain_click_folds_and_shift_does_not(self):
        self.frames(0.6)
        self.lua.execute('CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertEqual(self.eval("CQ_Row2Text.text"), "")
        self.assertIn("(+2)", self.eval("CQ_Row2Title.text"))
        self.lua.execute('CherrysQuests.Tracker.RowClick(2, "LBUTTON")')
        self.assertIn("3/10", self.eval("CQ_Row2Text.text"))

    def test_idle_frames_do_not_read_quests_or_allocate(self):
        self.frames(0.6)
        before = self.eval("calls.track")
        self.lua.execute('collectgarbage("stop"); kb = collectgarbage("count")')
        self.frames(5)
        grown = self.eval('collectgarbage("count") - kb')
        self.lua.execute('collectgarbage("restart")')
        self.assertEqual(self.eval("calls.track"), before)
        self.assertLess(grown, 2)
        self.frames(5.5)
        self.assertGreater(self.eval("calls.track"), before)  # the 10 second fallback read

    def test_quest_events_redraw_after_a_short_delay(self):
        self.frames(0.6)
        self.lua.execute('quests[5].lines[1] = "Wolf Pelt: 4/10"; CherrysQuests.OnEvent("RESET_QUESTTRACK")')
        self.assertIn("3/10", self.eval("CQ_Row2Text.text"))
        self.frames(0.6)
        self.assertIn("4/10", self.eval("CQ_Row2Text.text"))

    def test_reload_does_not_wrap_the_quest_button_twice(self):
        self.frames(0.6)
        self.lua.execute("firstButton = OnClick_QuestTrackButton")
        self.load()
        self.start()
        self.assertTrue(self.eval("OnClick_QuestTrackButton == firstButton"))
        self.lua.execute("OnClick_QuestTrackButton()")
        self.frames(0.6)
        self.assertFalse(self.eval("CQ_Tracker.shown"))
        self.assertEqual(self.eval("buttonClicks"), 0)
        self.lua.execute("CherrysQuests.S().replace = false; OnClick_QuestTrackButton()")
        self.assertEqual(self.eval("buttonClicks"), 1)

    def test_fonts_need_rom_weakauras_and_style_changes_reapply(self):
        self.frames(0.6)
        self.assertEqual(self.eval("#CherrysQuests.FontChoices()"), 1)
        self.lua.execute("RWA = {}")
        self.lua.execute('for i = 1, 20 do if CherrysQuests.Options.LIST[i].key == "font" then fontRow = i end end')
        self.lua.execute('CherrysQuests.Options.Click(fontRow, "choice")')
        self.assertEqual(self.eval("CherrysQuests.S().font"), "FiraSans-Medium.ttf")
        self.assertTrue(self.eval('string.find(CQ_Row1Title.font[1], "RomWeakAuras/Media/Fonts/FiraSans%-Medium.ttf") ~= nil'))
        self.lua.execute('for i = 1, 20 do if CherrysQuests.Options.LIST[i].key == "scale" then scaleRow = i end end')
        self.lua.execute('CherrysQuests.Options.Click(scaleRow, "plus")')
        self.assertAlmostEqual(self.eval("CherrysQuests.S().scale"), 1.05)
        self.assertEqual(self.eval("CQ_Row1Title.font[2]"), 14)

    def test_hub_off_switch_keeps_it_idle(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(CLIENT)
        lua.execute('CherrysKit = { IsEnabled = function(f) return f ~= "CherrysQuests" end }')
        for name in FILES:
            lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        lua.execute('MakeWidget("CQ_Tracker", true); CherrysQuests.OnEvent("VARIABLES_LOADED")')
        lua.execute("for i = 1, 100 do CherrysQuests.OnUpdate(0.1) end")
        self.assertFalse(lua.eval("CherrysQuests.ready"))
        self.assertEqual(lua.eval("calls.track"), 0)
        self.assertTrue(lua.eval("QuestTrackerFrame.shown"))

    def test_probe_options_tooltip_and_commands_run(self):
        self.frames(0.6)
        self.lua.execute('mods.ctrl = true; CherrysQuests.Tracker.RowClick(2, "LBUTTON"); mods.ctrl = false')
        self.lua.execute("CherrysQuests.Tracker.RowEnter(CQ_Row2, 2)")
        lines = list(self.eval("GameTooltip.lines").values())
        self.assertTrue(any("> 1. Elder Kalin" in str(l) for l in lines))
        for cmd in ("probe", "npcs", "text 2", "track Guard Loran", "lock", "unlock", "reset", "hide", "show", "forget", "help", ""):
            self.lua.globals().SlashCmdList["CHERRYSQUESTS"](None, cmd)
        self.assertTrue(self.eval("CQ_Options.shown"))
        self.assertEqual(self.eval("CQ_OptRow1Label.text"), "Show the tracker")
        self.assertEqual(self.eval("calls.quick[#calls.quick]"), 110002)
        messages = [str(m) for m in self.lua.globals().messages.values()]
        self.assertTrue(any("Herbalist Mira [110003, summary]" in m for m in messages))
        self.assertTrue(any("||Hnpc:110001" in m for m in messages))

    def test_objective_parsing(self):
        q = self.lua.globals().CherrysQuests
        o = q.ParseObjective("Wolf Pelt: 10/10")
        self.assertTrue(o.done)
        self.assertEqual(o.label, "Wolf Pelt")
        o = q.ParseObjective("Talk to the elder (Complete)")
        self.assertTrue(o.done)
        self.assertEqual(o.text, "Talk to the elder")
        o = q.ParseObjective("Ore 2/5")
        self.assertFalse(o.done)
        self.assertEqual((o.have, o.need, o.label), (2, 5, "Ore"))


if __name__ == "__main__":
    unittest.main()
