"""Addon LoadTimes is a troubleshooting tool: LoadTimes/Switch.txt decides whether it loads at all."""
from pathlib import Path
import shutil
import tempfile
import unittest

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface/AddOns/CherrysKit"
GAME_DIR = "Interface/AddOns/CherrysKit/"


class LoadTimesSwitchTests(unittest.TestCase):
    def setUp(self):
        # The game reads files relative to its install folder; map that onto a copy of the kit.
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(KIT / "LoadTimes", self.tmp / "LoadTimes")
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.g = self.lua.globals()
        self.lua.execute("""
          chat = {}
          DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) chat[#chat + 1] = text end }
          SlashCmdList = {}
          reads = {}
        """)
        real_loadfile = self.g.loadfile
        real_dofile = self.g.dofile
        base = str(self.tmp) + "/"

        def game_path(path):
            path = str(path)
            assert path.startswith(GAME_DIR), path
            return base + path[len(GAME_DIR):]

        def loadfile(path):
            self.g.reads[len(self.g.reads) + 1] = path
            return real_loadfile(game_path(path))

        def dofile(path):
            self.g.reads[len(self.g.reads) + 1] = path
            return real_dofile(game_path(path))

        # Lua functions like the client's (a Python callable would be userdata to type()).
        self.g.gameLoadfile, self.g.gameDofile = loadfile, dofile
        self.lua.execute("""
          loadfile = function(path) return gameLoadfile(path) end
          dofile = function(path) return gameDofile(path) end
        """)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def load(self):
        """The first two lines of the kit's manifest, as a login or Reload UI runs them."""
        for name in ("KitLoad/start.lua", "LoadTimes/Load.lua"):
            self.lua.execute((KIT / name).read_text(encoding="utf-8"), name)

    def switch(self, value):
        path = self.tmp / "LoadTimes/Switch.txt"
        text = path.read_text(encoding="utf-8")
        path.write_text(text.replace("LoadTimes = false", f"LoadTimes = {value}"), encoding="utf-8")

    def reads(self):
        return list(self.g.reads.values())

    def test_manifest_loads_only_the_stub_and_the_switch_first(self):
        toc = [line.strip() for line in (KIT / "CherrysKit.toc").read_text(encoding="utf-8").splitlines()
               if line.strip() and not line.startswith("#")]
        self.assertEqual(toc[:3], ["KitLoad/start.lua", "LoadTimes/Load.lua", "LoadTimes/CherrysLoadTimes.xml"])
        self.assertNotIn("LoadTimes/CherrysLoadTimes.lua", toc)
        self.assertIn("LoadTimes = false", (KIT / "LoadTimes/Switch.txt").read_text(encoding="utf-8"))

    def test_switched_off_reads_only_the_switch_and_keeps_the_hub_marks_working(self):
        self.load()
        self.assertEqual(self.reads(), [GAME_DIR + "LoadTimes/Switch.txt"])
        self.assertIsNone(self.g.CherrysLoadTimes)
        self.assertIsNone(self.lua.eval("getmetatable(_G)"))
        self.assertIsNone(self.lua.eval("LoadTimes"))  # the switch file runs in its own table
        self.lua.execute("""
          CherrysKit_Load.Mark("hub"); CherrysKit_Load.Event("first", "VARIABLES_LOADED")
          frame = { shown = true, Hide = function(self) self.shown = false end }
          CherrysKit_Load.Update(frame)
          assert(frame.shown == false, "the probe frames stop on their first update")
          SlashCmdList.CherrysKitLoad(nil, "")
        """)
        self.assertEqual(self.g.SLASH_CherrysKitLoad1, "/ckload")
        self.assertIn("Switch.txt", self.g.chat[1])
        self.assertIn("change false to true", self.g.chat[1])

    def test_switched_on_loads_the_timer_which_lets_go_of_globals_after_loading(self):
        self.switch("true")
        self.load()
        self.assertEqual(self.reads(), [GAME_DIR + "LoadTimes/Switch.txt", GAME_DIR + "LoadTimes/CherrysLoadTimes.lua"])
        self.assertEqual(self.g.CherrysLoadTimes.version, "1.3.0")
        self.assertTrue(self.lua.eval("CherrysKit_Load == CherrysLoadTimes"))
        self.assertIsNotNone(self.lua.eval("getmetatable(_G)"))
        self.lua.execute('CherrysKit_Load.Mark("hub"); someAddonGlobal = 1; CherrysKit_Load.Event("first", "VARIABLES_LOADED")')
        self.assertIsNone(self.lua.eval("getmetatable(_G)"))
        self.assertEqual(len(self.g.CherrysLoadTimes.marks), 1)

    def test_reload_after_switching_off_takes_the_watcher_back_off(self):
        self.switch("true")
        self.load()
        self.assertIsNotNone(self.lua.eval("getmetatable(_G)"))
        (self.tmp / "LoadTimes/Switch.txt").write_bytes((KIT / "LoadTimes/Switch.txt").read_bytes())
        self.load()  # Reload UI in the same Lua state, before VARIABLES_LOADED took it off
        self.assertIsNone(self.lua.eval("getmetatable(_G)"))
        self.assertIsNone(self.g.CherrysLoadTimes)
        self.assertIsNone(self.g.CherrysKit_Load.version)

    def test_a_missing_or_broken_switch_counts_as_off(self):
        (self.tmp / "LoadTimes/Switch.txt").unlink()
        self.load()
        self.assertIsNone(self.g.CherrysLoadTimes)
        (self.tmp / "LoadTimes/Switch.txt").write_text("LoadTimes = = true", encoding="utf-8")
        self.load()
        self.assertIsNone(self.g.CherrysLoadTimes)
        (self.tmp / "LoadTimes/Switch.txt").write_text('LoadTimes = "yes"', encoding="utf-8")
        self.load()
        self.assertIsNone(self.g.CherrysLoadTimes)


if __name__ == "__main__":
    unittest.main(verbosity=2)
