"""Exercise the shipped bank XML timer with real elapsed time under Lua 5.1."""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


SOURCE = Path(__file__).resolve().parents[1] / "Interface/AddOns/CherrysKit/zBag"
NS = {"ui": "http://www.runewaker.com/"}


class BankRefreshTests(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute((SOURCE / "zBagB.lua").read_text(encoding="utf-8-sig"))
        lua.execute("refreshes=0; zBagB_Update=function() refreshes=refreshes+1 end")
        script = ET.parse(SOURCE / "zBagB.xml").find(".//ui:OnUpdate", NS).text
        return lua, lua.eval("function(this, elapsedTime) " + script + " end")

    def test_refresh_frequency_is_about_five_hz_at_different_frame_rates(self):
        for fps in (15, 30, 60, 144):
            with self.subTest(fps=fps):
                lua, update = self.runtime()
                for _ in range(fps * 10):
                    update(lua.table(), 1 / fps)
                self.assertAlmostEqual(lua.globals().refreshes, 50, delta=1)

    def test_variable_frames_keep_time_and_a_stall_does_not_cause_a_refresh_burst(self):
        lua, update = self.runtime()
        for _ in range(50):
            for elapsed in (0.01, 0.02, 0.07, 0.1):
                update(lua.table(), elapsed)
        self.assertAlmostEqual(lua.globals().refreshes, 50, delta=1)
        before = lua.globals().refreshes
        update(lua.table(), 10)
        self.assertEqual(lua.globals().refreshes, before + 1)
        update(lua.table(), 0)
        update(lua.table(), None)
        self.assertEqual(lua.globals().refreshes, before + 1)


if __name__ == "__main__":
    unittest.main()
