"""Native player CASTING events cover transport/non-spell actions without leaking to target casts."""
import unittest

import test_rwa as support


class NativeCastTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.h.load("CastBars.lua")
        self.lua, self.rwa = self.h.lua, self.h.lua.globals().RWA
        self.lua.execute('''
          UnitCastingTime=function() return nil end
          function castState(unit)
            return RWA.Triggers.Evaluate({type="status",check="cast",unit=unit or "player",fillUp=true},fixtureNow,{})
          end
        ''')

    def state(self, unit="player"):
        return self.lua.globals().castState(unit)

    def test_transport_event_provides_name_progress_and_fallback_icon(self):
        self.rwa.Fire("CASTING_START", "Transport", 5)
        self.lua.globals().fixtureNow += 2
        state = self.state()
        self.assertTrue(state.show)
        self.assertEqual((state.name, state.duration, state.expirationTime, state.casting), ("Transport", 5, 105, 1))
        self.assertEqual(state.icon, self.rwa.W.TexturePath(self.rwa.CastBars.OTHER_ICON))
        self.assertAlmostEqual(self.rwa.Regions.Progress(state, 102), .4)

    def test_stop_failure_zone_and_death_clear_nonspell_actions(self):
        for event in ("CASTING_STOP", "CASTING_FAILED", "LOADING_END", "PLAYER_DEAD"):
            with self.subTest(event=event):
                self.rwa.Fire("CASTING_START", "Gathering", 5)
                self.assertTrue(self.state().show)
                self.rwa.Fire(event)
                self.assertFalse(self.state().show)

    def test_timeout_and_replacement_do_not_leave_stale_progress(self):
        self.rwa.Fire("CASTING_START", "Transport", 3)
        self.lua.globals().fixtureNow = 101
        self.rwa.Fire("CASTING_START", "Opening chest", 4)
        self.assertEqual(self.state().name, "Opening chest")
        self.lua.globals().fixtureNow = 105
        self.assertFalse(self.state().show)
        self.assertIsNone(self.rwa.CastBars.playerCast)

    def test_delay_extends_duration_and_finish_time(self):
        self.rwa.Fire("CASTING_START", "Transport", 5)
        self.rwa.Fire("CASTING_DELAYED", 2)
        state = self.state()
        self.assertEqual((state.duration, state.expirationTime), (7, 107))
        self.lua.globals().fixtureNow = 106
        self.assertTrue(self.state().show)
        self.lua.globals().fixtureNow = 107
        self.assertFalse(self.state().show)

    def test_polled_spell_timing_wins_and_player_events_do_not_fabricate_target_casts(self):
        self.rwa.Fire("CASTING_START", "Transport", 5)
        self.assertFalse(self.state("target").show)
        self.lua.execute('UnitCastingTime=function(unit) return "Spell",10,3 end')
        self.assertEqual((self.state().name, self.state().duration, self.state().expirationTime), ("Spell", 10, 107))
        self.assertEqual(self.state("target").name, "Spell")

    def test_bad_native_arguments_cannot_create_infinite_or_invalid_bars(self):
        for duration in (0, -1, float("inf"), float("nan"), "invalid"):
            with self.subTest(duration=duration):
                self.rwa.Fire("CASTING_START", "Transport", duration)
                self.assertFalse(self.state().show)
        self.rwa.Fire("CASTING_START", "", 5)
        self.assertFalse(self.state().show)

    def test_shipped_my_cast_aura_uses_the_native_fallback_without_editing_saved_sources(self):
        self.lua.execute('''
          RWA.CastBars.AddExamples();RWA.NormalizeSavedAuras();RWA.ReloadAll()
        ''')
        self.rwa.Fire("CASTING_START", "Transport", 5)
        self.h.tick()
        self.assertTrue(self.rwa.IsAuraActive("My cast"))
        self.assertEqual(self.rwa.loaded["My cast"].region.state.name, "Transport")
        self.rwa.Fire("CASTING_FAILED")
        self.h.tick()
        self.assertFalse(self.rwa.IsAuraActive("My cast"))


if __name__ == "__main__":
    unittest.main()
