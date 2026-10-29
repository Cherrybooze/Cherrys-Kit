"""Grid spells/macros preserve targets using documented RoM unit identities."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysGrid"


class GridClickTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          old={name="Enemy",guid=11}; member={name="Member",guid=22}
          player={name="Me",guid=33}; current=old
          units={player=player,party1=member}; focus={}; calls={}; messages={}; casts=0
          function Resolve(unit)
            if unit=="target" then return current end
            local n=tonumber(string.match(unit or "","^focus(%d+)$"))
            if n then return focus[n] end
            return units[unit]
          end
          function UnitName(unit) local u=Resolve(unit); return u and u.name end
          function UnitGUID(unit) local u=Resolve(unit); return u and u.guid end
          function UnitIsUnit(a,b) return Resolve(a)~=nil and Resolve(a)==Resolve(b) end
          function UnitClassToken() return "AUGUR","DRUID" end
          function TargetUnit(unit)
            calls[#calls+1]=unit or ""
            if failTarget==unit then return false end
            current=Resolve(unit)
          end
          function FocusUnit(slot,unit)
            if focusFailure then error("focus failed") end
            if focusNoop then return end
            focus[slot]=Resolve(unit)
          end
          function CastSpellByName(name)
            casts=casts+1; castTarget=current
            if castError then error("cast failed") end
            if loseOld then old.guid=44; focus={}; units.party2=nil end
          end
          function GetMacroInfo() return "icon","Heal","/cast Heal\\n/run local fixture=true" end
          function ExecuteMacroLine(line) CastSpellByName(line) end
        ''')
        for name in ("Core.lua", "Roster.lua", "Clicks.lua"):
            self.lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        self.lua.execute("CherrysGrid.Print=function(text) messages[#messages+1]=text end")
        self.clicks = self.lua.globals().CherrysGrid.Clicks

    def run_action(self, kind):
        if kind == "spell":
            return self.clicks.RunSpell("party1", "Heal", False)
        return self.clicks.RunMacro("party1", self.lua.table_from({"slot": 1, "macro": "Heal"}), False)

    def test_spells_and_ordinary_macros_restore_a_verified_focus_stash(self):
        for kind in ("spell", "macro"):
            with self.subTest(kind=kind):
                self.assertTrue(self.run_action(kind))
                self.assertTrue(self.lua.eval("current==old and castTarget==member"))
                self.assertTrue(self.lua.eval("next(focus)==nil"))

    def test_without_focus_api_a_stable_party_unit_can_restore_the_old_target(self):
        self.lua.execute("FocusUnit=nil; units.party2=old")
        for kind in ("spell", "macro"):
            with self.subTest(kind=kind):
                self.assertTrue(self.run_action(kind))
                self.assertTrue(self.lua.eval("current==old and castTarget==member"))

    def test_without_a_safe_restore_path_the_original_target_is_left_intact(self):
        self.lua.execute("FocusUnit=nil")
        for kind in ("spell", "macro"):
            with self.subTest(kind=kind):
                self.assertFalse(self.run_action(kind))
                self.assertTrue(self.lua.eval("current==old"))
                self.assertEqual(self.lua.globals().casts, 0)
                self.assertEqual(len(self.lua.globals().calls), 0)
        self.assertGreater(len(self.lua.globals().messages), 0)

    def test_failed_or_silent_focus_stashing_does_not_change_the_target_or_cast(self):
        for failure in ("focusFailure", "focusNoop"):
            with self.subTest(failure=failure):
                self.lua.globals()[failure] = True
                self.assertFalse(self.run_action("spell"))
                self.assertTrue(self.lua.eval("current==old"))
                self.assertEqual(self.lua.globals().casts, 0)
                self.lua.globals()[failure] = False

    def test_existing_focus_slots_are_preserved(self):
        self.lua.execute("focus[12]=player")
        self.assertTrue(self.run_action("spell"))
        self.assertTrue(self.lua.eval("current==old and focus[12]==player"))

    def test_action_errors_still_restore_the_target(self):
        self.lua.globals().castError = True
        self.assertFalse(self.run_action("spell"))
        self.assertTrue(self.lua.eval("current==old"))
        self.assertTrue(self.lua.eval("next(focus)==nil"))

    def test_failed_or_disappeared_restoration_is_reported_without_clearing_the_member(self):
        for failure in ("refused", "disappeared"):
            with self.subTest(failure=failure):
                self.setUp()
                if failure == "refused":
                    self.lua.execute('failTarget="focus12"')
                else:
                    self.lua.globals().loseOld = True
                self.assertFalse(self.run_action("spell"))
                self.assertTrue(self.lua.eval("current==member"))
                self.assertGreater(len(self.lua.globals().messages), 0)

    def test_no_old_target_same_member_and_keep_target_still_work(self):
        self.lua.execute("FocusUnit=nil; current=nil")
        self.assertTrue(self.run_action("spell"))
        self.assertIsNone(self.lua.globals().current)
        self.lua.execute("current=member")
        self.assertTrue(self.run_action("spell"))
        self.assertTrue(self.lua.eval("current==member"))
        self.lua.execute("current=old")
        self.assertTrue(self.clicks.RunSpell("party1", "Heal", True))
        self.assertTrue(self.lua.eval("current==member"))

    def test_target_switch_failure_skips_the_action_and_preserves_the_old_target(self):
        self.lua.execute('failTarget="party1"')
        self.assertFalse(self.run_action("spell"))
        self.assertEqual(self.lua.globals().casts, 0)
        self.assertTrue(self.lua.eval("current==old"))


class GridRosterTests(unittest.TestCase):
    def test_poll_layout_and_startup_scan_the_roster_once(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        for name in ("Core.lua", "Roster.lua", "Layout.lua"):
            lua.execute((SOURCE / name).read_text(encoding="utf-8-sig"))
        lua.execute('''
          local G=CherrysGrid
          UnitName=function(unit) if unit=="player" then return "Me" end end
          local scans=0; local update=G.Roster.Update
          G.Roster.Update=function(...) scans=scans+1; return update(...) end
          CGrid_Layout={Show=function() end,Hide=function() end}
          G.Frames={unitOf={},Size=function() return 100,50 end,Obj=function() end,
            UpdateAll=function() end,Animate=function() end}
          G.FillStatusDefaults=function() end
          G.STATUS_DEFAULTS={}
          G.varsLoaded=true
          G.TryStart()
          assert(scans==1,"startup rescanned the roster: "..scans)
          scans=0
          G.Roster.signature="force change"
          G.rosterElapsed=2
          G.OnUpdate(0.11)
          assert(scans==1,"poll/layout rescanned the roster: "..scans)
          scans=0
          G.P.width=80
          G.Refresh(true)
          assert(scans==1,"explicit layout refresh did not scan exactly once")
        ''')


if __name__ == "__main__":
    unittest.main()
