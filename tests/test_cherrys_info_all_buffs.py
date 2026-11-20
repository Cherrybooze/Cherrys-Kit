"""Cherry's Info "Show all client buffs and debuffs": reading, drawing, throttling and the game's icons, in a fake client."""

from pathlib import Path
import re
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysInfo"
FILES = ("CherrysQuests.lua", "Npcs.lua", "Tracker.lua", "Options.lua", "Probe.lua", "AllBuffs.lua")

CLIENT = r'''
clock = 100
function GetTime() return clock end
function GetUIScale() return 1 end
function UnitName() return "Cherry" end
function GetCurrentVocLV() return 40 end
function GetQuestTrack(i) if i == -1 then return 0 end end
function Daily_count() return 0, 10 end
shift = false
function IsShiftKeyDown() return shift end
function IsCtrlKeyDown() return false end
function IsAltKeyDown() return false end
messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, text) messages[#messages + 1] = text end }

-- The player's whole effect list, like CRoleSprite::m_buffInfo: good = helpful, show = drawn by the game.
effects = {}
for i = 1, 30 do effects[#effects + 1] = { name = "Buff" .. i, id = 500000 + i, good = true, show = true, time = 60 * i } end
for i = 1, 10 do effects[#effects + 1] = { name = "Debuff" .. i, id = 600000 + i, good = false, show = true, time = 5 + i } end
effects[#effects + 1] = { name = "Marker", id = 700001, good = true, show = false, time = 0 }
effects[#effects + 1] = { name = "Buff3", id = 500003, good = true, show = true, time = 0 } -- same id twice
calls = { buff = 0, info = 0, cancel = {} }

local function nth(good, i)
  local n = 0
  for raw, e in ipairs(effects) do
    if e.good == good and e.show then
      n = n + 1
      if n == i then return e, raw end
    end
  end
end
for _, e in ipairs(effects) do e.icon = "icon/" .. e.name end
local function ret(e) return e.name, e.icon, e.stacks or 0, e.id, nil end
function UnitBuff(unit, i) calls.buff = calls.buff + 1; local e = nth(true, i); if e then return ret(e) end end
function UnitDebuff(unit, i) local e = nth(false, i); if e then return ret(e) end end
function UnitBuffLeftTime(unit, i) local e = nth(true, i); if e and e.time > 0 then return e.time end end
function UnitDebuffLeftTime(unit, i) local e = nth(false, i); if e and e.time > 0 then return e.time end end
function UnitBuffInfo(unit, i) calls.info = calls.info + 1; local e = effects[i]; if e then return ret(e) end end
function GetPlayerBuffLeftTime(i) local e = effects[i + 1]; return e and math.floor(e.time) or 0 end
function CancelPlayerBuff(i) calls.cancel[#calls.cancel + 1] = i end

local Widget = {}
Widget.__index = Widget
function Widget:Show() self.shown = true end
function Widget:Hide() self.shown = false end
function Widget:IsVisible() return self.shown end
function Widget:SetText(t) self.text = t; self.sets = (self.sets or 0) + 1 end
function Widget:GetText() return self.text end
-- Kept tables are refilled, so the fake makes no garbage of its own while the display runs.
function Widget:ClearAllAnchors() self.cleared = true end
function Widget:SetAnchor(p, rp, rel, x, y)
  local a = self.anchor or {}
  a[1], a[2], a[3], a[4], a[5] = p, rp, rel, x, y
  self.anchor = a
end
function Widget:SetWidth(w) self.w = w end
function Widget:SetHeight(h) self.h = h end
function Widget:SetColor(r, g, b)
  local c = self.color or {}
  c[1], c[2], c[3] = r, g, b
  self.color = c
end
function Widget:SetAlpha(a) self.alpha = a end
function Widget:SetFile(f) self.file = f end
function Widget:SetChecked(v) self.checked = v end
function Widget:SetFont() end
function Widget:SetFontSize() end
function Widget:GetFont() return "f", 12 end
function Widget:GetHeight() return 0 end
function Widget:StartMoving() self.moving = true end
function Widget:StopMovingOrSizing() self.moving = false end
function Widget:GetPos() return 700, 40 end
function Widget:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function MakeWidget(name, hidden)
  _G[name] = setmetatable({ name = name, shown = not hidden }, Widget)
end
PlayerBuffFrame = setmetatable({ name = "PlayerBuffFrame", shown = true }, Widget)
for i = 1, 16 do _G["PlayerBuffButton" .. i] = setmetatable({ shown = true }, Widget) end
for i = 1, 8 do _G["PlayerDebuffButton" .. i] = setmetatable({ shown = true }, Widget) end
GameTooltip = setmetatable({ name = "GameTooltip", lines = {} }, Widget)
function GameTooltip:SetOwner() self.lines = {} end
function GameTooltip:ClearLines() self.lines = {} end
function GameTooltip:AddLine(t) self.lines[#self.lines + 1] = t end
function GameTooltip:SetUnitBuff(unit, i) self.buff = i end
function GameTooltip:SetUnitDebuff(unit, i) self.debuff = i end
'''


class AllBuffsTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(CLIENT)
        g = self.lua.globals()
        for xml_name in ("CherrysQuests.xml", "AllBuffs.xml"):
            xml = (SOURCE / xml_name).read_text(encoding="utf-8")
            for name, rest in re.findall(r'name="(CQ_[A-Za-z0-9_]+|CInfoBuffs?[0-9]*)"([^>]*)', xml):
                g.MakeWidget(name, 'hidden="true"' in rest)
        for i in range(1, 97):
            for part in ("Icon", "Border", "Count", "Time"):
                g.MakeWidget(f"CInfoBuff{i}{part}", False)
        for name in FILES:
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        self.lua.execute('CherrysQuests.OnLoad(CQ_Events); CherrysQuests.AllBuffs.OnLoad(CInfoBuffs)')
        self.lua.execute('CherrysQuests.OnEvent("VARIABLES_LOADED"); CherrysQuests.OnUpdate(0.01)')

    def eval(self, code):
        return self.lua.eval(code)

    def frames(self, seconds, step=1 / 60):
        # OnUpdate runs only while the display frame is shown, as in the game
        self.lua.execute(f"for i = 1, {int(seconds / step)} do clock = clock + {step}; "
                         f"if CInfoBuffs.shown then CherrysQuests.AllBuffs.OnUpdate({step}) end end")

    def turn_on(self, hidden=False):
        self.lua.execute(f"CherrysQuests.S().allBuffsHidden = {'true' if hidden else 'false'}")
        self.lua.execute('CherrysQuests.Options.Set({ key = "allBuffs", set = function(v) CherrysQuests.S().allBuffs = v; CherrysQuests.AllBuffs.Apply() end }, true)')
        self.frames(0.2)

    def test_off_by_default_and_the_game_icons_stay(self):
        self.assertFalse(self.eval("CherrysQuests.S().allBuffs"))
        self.assertFalse(self.eval("CInfoBuffs.shown"))
        self.assertTrue(self.eval("PlayerBuffFrame.shown"))
        self.assertEqual(self.eval("calls.buff"), 0)

    def test_on_shows_every_buff_and_debuff_and_hides_the_game_icons(self):
        self.turn_on()
        self.assertTrue(self.eval("CInfoBuffs.shown"))
        self.assertFalse(self.eval("PlayerBuffFrame.shown"))
        self.assertFalse(self.eval("PlayerBuffButton16.shown"))
        self.assertFalse(self.eval("PlayerDebuffButton1.shown"))
        b = "CherrysQuests.AllBuffs"
        self.assertEqual(self.eval(f"{b}.counts[1]"), 31)  # 30 + the second Buff3
        self.assertEqual(self.eval(f"{b}.counts[2]"), 10)
        self.assertEqual(self.eval(f"{b}.counts[3]"), 0)
        self.assertTrue(self.eval("CInfoBuff41.shown"))
        self.assertFalse(self.eval("CInfoBuff42.shown"))
        self.assertEqual(self.eval("CInfoBuff1Icon.file"), "icon/Buff1")
        self.assertEqual(self.eval("CInfoBuff1Time.text"), "1m")
        self.assertEqual(self.eval("CInfoBuff32Time.text"), "6")  # Debuff1: 6 s
        # medium: 12 a row; debuffs start their own row (31 buffs = rows 0-2, debuffs on row 3)
        self.assertEqual(self.eval("CInfoBuff13.anchor[5]"), 46)
        self.assertEqual(self.eval("CInfoBuff32.anchor[4]"), 0)
        self.assertEqual(self.eval("CInfoBuff32.anchor[5]"), 3 * 46)
        self.assertEqual(self.eval("CInfoBuff32Border.color[1]"), 0.85)

    def test_hidden_effects_only_when_asked(self):
        self.turn_on(hidden=True)
        self.assertEqual(self.eval("CherrysQuests.AllBuffs.counts[3]"), 1)
        self.assertEqual(self.eval("CherrysQuests.AllBuffs.entries[42].name"), "Marker")
        self.lua.execute("CherrysQuests.AllBuffs.Enter(42, CInfoBuff42)")
        self.assertIn("Hidden effect", self.eval("GameTooltip.lines[1]"))

    def test_timers_count_down_without_reading_again(self):
        self.turn_on()
        reads = self.eval("calls.buff")
        self.frames(2.0)
        self.assertEqual(self.eval("calls.buff"), reads)
        self.assertEqual(self.eval("CInfoBuff32Time.text"), "4")
        self.frames(1.5)  # fallback read after 3 s
        self.assertGreater(self.eval("calls.buff"), reads)

    def test_a_burst_of_events_is_one_read(self):
        self.turn_on()
        reads = self.eval("calls.buff")
        self.lua.execute('for i = 1, 20 do CherrysQuests.AllBuffs.OnEvent("UNIT_BUFF_CHANGED", "player") end')
        self.lua.execute('CherrysQuests.AllBuffs.OnEvent("UNIT_BUFF_CHANGED", "target")')
        self.frames(0.3)
        self.assertEqual(self.eval("calls.buff") - reads, 32)  # one pass over 31 buffs + the empty slot

    def test_no_garbage_while_running(self):
        self.turn_on()
        self.frames(5)
        self.lua.execute("""
          function run(n) for i = 1, n do clock = clock + 1 / 60; CherrysQuests.AllBuffs.OnUpdate(1 / 60) end end
          run(10)
          collectgarbage('collect'); collectgarbage('stop'); kb = collectgarbage('count')
          run(300) -- 5 s: timers redraw 10 times and one fallback read and draw
          grown = collectgarbage('count') - kb
          collectgarbage('restart')""")
        grown = self.eval("grown")
        self.assertLess(grown, 1.0)

    def test_right_click_cancels_a_buff_and_shift_drag_moves(self):
        self.turn_on()
        self.lua.execute('CherrysQuests.AllBuffs.Click(5, "RBUTTON")')
        self.assertEqual(self.eval("calls.cancel[1]"), 5)
        self.lua.execute('CherrysQuests.AllBuffs.Click(35, "RBUTTON")')  # a debuff
        self.assertEqual(len(self.lua.globals().calls.cancel), 1)
        self.lua.execute('shift = true; CherrysQuests.AllBuffs.MouseDown("LBUTTON"); CherrysQuests.AllBuffs.MouseUp("LBUTTON")')
        self.assertEqual(self.eval("CherrysQuests.S().allBuffsX"), 700)
        self.assertEqual(self.eval("CInfoBuffs.anchor[1]"), "TOPLEFT")
        self.lua.execute('CherrysQuests.AllBuffs.Click(5, "RBUTTON")')  # the release after a drag is not a click
        self.assertEqual(len(self.lua.globals().calls.cancel), 1)

    def test_turning_off_brings_the_game_frame_back(self):
        self.turn_on()
        self.lua.execute('CherrysQuests.S().allBuffs = false; CherrysQuests.AllBuffs.Apply()')
        self.assertFalse(self.eval("CInfoBuffs.shown"))
        self.assertTrue(self.eval("PlayerBuffFrame.shown"))

    def test_size_choice_and_probe(self):
        self.turn_on()
        self.lua.execute('CherrysQuests.S().allBuffsSize = "small"; CherrysQuests.AllBuffs.Restyle()')
        self.frames(0.2)
        self.assertEqual(self.eval("CInfoBuff1.w"), 24)
        self.assertEqual(self.eval("CInfoBuff17.anchor[5]"), 24 + 12 + 4)
        self.lua.execute('CherrysQuests.Command("buffs")')
        text = " ".join(str(m) for m in self.lua.globals().messages.values())
        self.assertIn("holds 42 effects on you: 31 buffs, 10 debuffs and 1 hidden", text)
        self.assertIn("PlayerBuffButton x16, PlayerDebuffButton x8", text)

    def test_options_row_on_the_target_tab(self):
        self.lua.execute('CherrysQuests.Options.OpenTab("target")')
        labels = [self.eval(f"CQ_OptRow{i}Label.text") for i in range(1, 21)]
        self.assertIn("Show all client buffs and debuffs", labels)
        row = labels.index("Buff icon size") + 1
        self.assertEqual(self.eval(f"CQ_OptRow{row}Choice.text"), "Medium, 12 a row")
        self.lua.execute(f'CherrysQuests.Options.Click({row}, "choice")')
        self.assertEqual(self.eval("CherrysQuests.S().allBuffsSize"), "large")
        on_row = labels.index("Show all client buffs and debuffs") + 1
        self.lua.execute(f'CherrysQuests.Options.Click({on_row}, "check")')
        self.assertTrue(self.eval("CInfoBuffs.shown"))


if __name__ == "__main__":
    unittest.main()
