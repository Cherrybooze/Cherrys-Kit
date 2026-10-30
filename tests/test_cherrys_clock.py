"""CherrysClock, the hub's real time for addons: read from the time file, carried by the tick count."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/CherrysClock.lua"


class RealTimeClockTest(unittest.TestCase):
    UTC = 1793352600  # 2026-10-30 09:30:00 UTC

    def clock(self, tick=1000, offset=7200, file=True, game=None):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(f"now_tick = {tick}; game_minutes = {game if game is not None else 'nil'}")
        lua.execute("function GetTickCount() return now_tick end")
        lua.execute("function GetCurrentGameTime() return game_minutes end")
        stamp = f"[[return {{utc = {self.UTC}, tick = 1000, offset = {offset}}}]]" if file else "nil"
        lua.execute(f"stamp = {stamp}")
        lua.execute("""
          function loadfile(path)
            if stamp and path == "Interface/GlobalBankHelper/CherrysClockStamp.lua" then
              return loadstring(stamp)
            end
            return nil, "cannot open"
          end
        """)
        lua.execute(SOURCE.read_text(encoding="utf-8"))
        lua.execute('CherrysClock.OnEvent("VARIABLES_LOADED")')
        return lua

    def values(self, lua, call):
        result = lua.eval(f"{{CherrysClock.{call}()}}")
        return tuple(result[i] for i in range(1, len(result) + 1))

    def test_utc_runs_from_the_tick_count(self):
        lua = self.clock()
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC)
        lua.execute("now_tick = 61000")
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC + 60)

    def test_local_date_and_time(self):
        lua = self.clock()
        self.assertEqual(lua.eval("CherrysClock.Now()"), self.UTC + 7200)
        self.assertEqual(self.values(lua, "Date"), (2026, 10, 30))
        self.assertEqual(self.values(lua, "Time"), (11, 30, 0))

    def test_date_rolls_over_with_the_time_zone(self):
        lua = self.clock(offset=-36000)  # 23:30 the day before
        self.assertEqual(self.values(lua, "Date"), (2026, 10, 29))
        self.assertEqual(self.values(lua, "Time"), (23, 30, 0))

    def test_leap_day(self):
        lua = self.clock()
        lua.execute("CherrysClock.base.utc = 1835395200; CherrysClock.base.offset = 0")  # 2028-02-29 00:00 UTC
        self.assertEqual(self.values(lua, "Date"), (2028, 2, 29))

    def test_tick_count_going_negative(self):
        lua = self.clock()
        lua.execute("CherrysClock.base.tick = 2147483000; now_tick = -2147483000")
        self.assertAlmostEqual(lua.eval("CherrysClock.UTC()"), self.UTC + 1.296, places=3)

    def test_unknown_without_the_file(self):
        lua = self.clock(file=False)
        for call in ("UTC", "Now", "Date", "Time"):
            self.assertIsNone(lua.eval(f"CherrysClock.{call}()"))

    def test_picks_up_the_file_while_playing(self):
        lua = self.clock(file=False)
        lua.execute(f"stamp = [[return {{utc = {self.UTC}, tick = 1000, offset = 0}}]]")
        lua.execute("CherrysClock.OnUpdate(11)")
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC)

    def test_too_old_counts_as_unknown(self):
        lua = self.clock()
        lua.execute("now_tick = 1000 + 41 * 86400 * 1000")
        self.assertIsNone(lua.eval("CherrysClock.UTC()"))

    def game_minutes(self, lua):
        return int(lua.eval("math.floor(CherrysClock.Now() / 60) % 240"))

    def move_game_clock(self, lua, minutes):
        lua.execute(f"game_minutes = {minutes}; CherrysClock.Check()")
        lua.execute(f"game_minutes = {minutes + 1}; CherrysClock.Check()")

    def test_agreeing_minutes_change_nothing(self):
        lua = self.clock()
        self.move_game_clock(lua, self.game_minutes(lua))
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC)
        self.assertEqual(lua.eval("CherrysClock.base.offset"), 7200)

    def test_whole_hour_difference_fixes_the_time_zone(self):
        lua = self.clock()
        self.move_game_clock(lua, self.game_minutes(lua) + 60)
        self.assertEqual(lua.eval("CherrysClock.base.offset"), 7200 + 3600)

    def test_any_other_difference_means_out_of_date(self):
        lua = self.clock()
        self.move_game_clock(lua, self.game_minutes(lua) + 25)
        self.assertIsNone(lua.eval("CherrysClock.UTC()"))

    def test_out_of_date_file_is_not_taken_again_until_rewritten(self):
        lua = self.clock()
        self.move_game_clock(lua, self.game_minutes(lua) + 25)
        lua.execute("CherrysClock.OnUpdate(11)")
        self.assertIsNone(lua.eval("CherrysClock.UTC()"))
        lua.execute(f"now_tick = 5000; stamp = [[return {{utc = {self.UTC + 99}, tick = 5000, offset = 0}}]]")
        lua.execute("CherrysClock.OnUpdate(11)")
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC + 99)

    def test_fixed_time_zones_prove_nothing(self):
        lua = self.clock(game=0)
        for _ in range(5):
            lua.execute("CherrysClock.OnUpdate(60)")
        self.assertEqual(lua.eval("CherrysClock.UTC()"), self.UTC)

    def test_file_cannot_reach_other_globals(self):
        lua = self.clock()
        lua.execute('stamp = "Touched = true; return {utc = 1, tick = 1}"')
        lua.execute("CherrysClock.Look()")
        self.assertIsNone(lua.eval("Touched"))


if __name__ == "__main__":
    unittest.main()
