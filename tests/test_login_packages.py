"""LogNextChar as a package: what the ZIPs hold, and what Install login screen.bat does."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
SHELL = shutil.which("powershell")  # Windows PowerShell: this file is only for Windows
spec = importlib.util.spec_from_file_location("build_release", ROOT / "tools/build_release.py")
build_release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build_release)


class PackagesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.output = Path(cls.temp.name)
        cls.packages = {p["package"]: p for p in build_release.write_login_packages(cls.output)}

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def names(self, package):
        return ZipFile(self.output / self.packages[package]["filename"]).namelist()

    def test_each_is_one_folder_for_interface_addons(self):
        self.assertEqual(list(self.packages), ["LogNextChar"])
        self.assertEqual({name.split("/")[0] for name in self.names("LogNextChar")}, {"CherrysKit"})
        self.assertIn("CherrysKit/LogNextChar/LogNextChar.lua", self.names("LogNextChar"))

    def test_the_hubs_manifest_is_what_loads_them(self):
        # The client loads every .toc it finds under Interface/AddOns, at any depth, so these have none: placed
        # anywhere but under CherrysKit they don't load at all.
        self.assertEqual([name for name in self.names("LogNextChar") if name.lower().endswith(".toc")], [])
        self.assertIn("CherrysKit/LogNextChar/LoginScreen/loginxml.toc.txt", self.names("LogNextChar"))

    def test_no_personal_files(self):
        for name in self.names("LogNextChar"):
            if name.startswith("CherrysKit/LogNextChar/LoginScreen/") and "/data/" not in name:
                self.assertNotIn(name.rsplit("/", 1)[-1], build_release.LOGIN_PERSONAL)

    def test_guide_links_work_inside_the_zip(self):
        with ZipFile(self.output / self.packages["LogNextChar"]["filename"]) as archive:
            guide = archive.read("CherrysKit/LogNextChar/README.md").decode("utf-8")
            self.assertIn("(LoginScreen/docs/Rom-Autologin-Readme.md)", guide)
            self.assertIn("CherrysKit/LogNextChar/LoginScreen/docs/Rom-Autologin-Readme.md", archive.namelist())

    def test_requirements_are_recorded(self):
        self.assertTrue(self.packages["LogNextChar"]["requires_hub"])
        self.assertNotIn("requires_addon", self.packages["LogNextChar"])

    def test_both_licences_travel_with_it(self):
        names = self.names("LogNextChar")
        self.assertIn("CherrysKit/LogNextChar/LICENSE.txt", names)
        self.assertIn("CherrysKit/LogNextChar/LICENSE-Loginxml.txt", names)
        with ZipFile(self.output / self.packages["LogNextChar"]["filename"]) as archive:
            self.assertIn(b"Pyrrhus", archive.read("CherrysKit/LogNextChar/LICENSE-Loginxml.txt"))


@unittest.skipUnless(SHELL, "Windows PowerShell required")
class InstallScreenTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.zips = tempfile.TemporaryDirectory()
        output = Path(cls.zips.name)
        packages = {p["package"]: p for p in build_release.write_login_packages(output)}
        cls.package = output / packages["LogNextChar"]["filename"]

    @classmethod
    def tearDownClass(cls):
        cls.zips.cleanup()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Path(self.temp.name) / "Game"
        addons = self.game / "Interface/AddOns"
        addons.mkdir(parents=True)
        with ZipFile(self.package) as archive:
            archive.extractall(addons)
        self.screen = self.game / "Interface/loginxml"
        self.documents = Path(self.temp.name) / "Documents"
        self.documents.mkdir()

    def install(self):
        script = self.game / "Interface/AddOns/CherrysKit/LogNextChar/setup/Install.ps1"
        result = subprocess.run([SHELL, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", str(script),
                                 "-Documents", str(self.documents)], capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_puts_the_login_screen_where_the_game_reads_it(self):
        self.install()
        self.assertTrue((self.screen / "loginxml.toc").is_file())
        self.assertFalse((self.screen / "loginxml.toc.txt").exists())
        self.assertTrue((self.screen / "frames/login.lua").is_file())

    def test_writes_where_the_game_saves_settings(self):
        self.install()
        text = (self.screen / "savedpath.lua").read_text()
        self.assertIn("Runes of Magic/SaveVariables.lua", text.replace("\\", "/"))

    def test_keeps_a_players_own_files(self):
        self.install()
        own = {"accounts.lua": "mine 1", "password.lua": "mine 2", "config.lua": "mine 3",
               "data/accounts.lua": "mine 4", "data/password.lua": "mine 5", "data/config.lua": "mine 6"}
        for name, text in own.items():
            (self.screen / name).write_text(text)
        (self.screen / "frames/login.lua").write_text("old")
        self.install()
        for name, text in own.items():
            self.assertEqual((self.screen / name).read_text(), text, name)
        self.assertNotEqual((self.screen / "frames/login.lua").read_text(), "old")

    def test_moves_only_the_old_addon_folder_and_deletes_nothing(self):
        old = self.game / "Interface/AddOns/CherrysLoginxml"
        old.mkdir()
        (old / "CherrysLoginxml.toc").write_text("## Title: Cherry's Loginxml helper\n")
        (old / "keep.txt").write_text("still here")
        other = self.game / "Interface/AddOns/SomeAddon"
        other.mkdir()
        (other / "SomeAddon.toc").write_text("## Title: SomeAddon\n")
        self.install()
        self.assertFalse(old.exists())
        self.assertEqual((self.offloaded() / "CherrysLoginxml/keep.txt").read_text(), "still here")
        self.assertTrue(other.exists())

    def test_moves_the_old_hook_folder(self):
        hook = self.game / "Interface/AddOns/CherrysKit/CherrysLoginxmlHook"
        hook.mkdir()
        (hook / "CherrysLoginxmlHook.lua").write_text("-- old")
        self.install()
        self.assertFalse(hook.exists())
        self.assertTrue((self.offloaded() / "CherrysLoginxmlHook/CherrysLoginxmlHook.lua").is_file())
        self.assertTrue((self.game / "Interface/AddOns/CherrysKit/LogNextChar/LogNextChar.lua").is_file())

    def test_moves_an_old_top_level_copy_of_itself(self):
        # It would keep the kit's copy off: the hub gives way to it.
        old = self.game / "Interface/AddOns/LogNextChar"
        old.mkdir()
        (old / "LogNextChar.toc").write_text("## Title: LogNextChar\n")
        (old / "LogNextChar.lua").write_text("-- old")
        self.install()
        self.assertFalse(old.exists())
        self.assertTrue((self.offloaded() / "LogNextChar/LogNextChar.toc").is_file())

    def test_a_second_move_does_not_overwrite_the_first(self):
        for text in ("first", "second"):
            old = self.game / "Interface/AddOns/LogNextChar"
            old.mkdir()
            (old / "LogNextChar.toc").write_text("## Title: LogNextChar\n" + text)
            self.install()
        self.assertIn("first", (self.offloaded() / "LogNextChar/LogNextChar.toc").read_text())
        self.assertIn("second", (self.offloaded() / "LogNextChar-2/LogNextChar.toc").read_text())

    def test_leaves_a_folder_that_only_shares_the_old_name(self):
        old = self.game / "Interface/AddOns/CherrysLoginxml"
        old.mkdir()
        (old / "CherrysLoginxml.toc").write_text("## Title: Something else\n")
        self.install()
        self.assertTrue(old.exists())

    def offloaded(self):
        return self.game / "Interface/offloaded_addons"

    def test_a_first_install_has_nothing_to_offload(self):
        self.install()
        self.assertFalse(self.offloaded().exists())

    def test_copies_an_existing_loginxml_first_and_keeps_all_of_it_there(self):
        self.screen.mkdir(parents=True)
        (self.screen / "accounts.lua").write_text("mine")
        (self.screen / "other_addons_file.lua").write_text("theirs")
        self.install()
        copy = self.offloaded() / "loginxml"
        self.assertEqual((copy / "accounts.lua").read_text(), "mine")
        self.assertEqual((copy / "other_addons_file.lua").read_text(), "theirs")
        self.assertFalse((copy / "frames/login.lua").exists())
        self.assertEqual((self.screen / "accounts.lua").read_text(), "mine")
        self.assertEqual((self.screen / "other_addons_file.lua").read_text(), "theirs")
        self.assertTrue((self.screen / "frames/login.lua").is_file())

    def test_up_to_date_it_changes_nothing_and_copies_nothing(self):
        self.install()
        files = [path for path in self.screen.rglob("*") if path.is_file()]
        for path in files:
            os.utime(path, (1000000000, 1000000000))
        self.install()
        self.assertFalse(self.offloaded().exists())
        self.assertEqual({path.stat().st_mtime for path in files}, {1000000000})

    def test_only_the_files_that_differ_change(self):
        self.install()
        (self.screen / "frames/login.lua").write_text("old")
        same = self.screen / "frames/login.xml"
        os.utime(same, (1000000000, 1000000000))
        self.install()
        self.assertNotEqual((self.screen / "frames/login.lua").read_text(), "old")
        self.assertEqual(same.stat().st_mtime, 1000000000)
        self.assertEqual((self.offloaded() / "loginxml/frames/login.lua").read_text(), "old")

    def test_never_overwrites_an_earlier_copy(self):
        self.screen.mkdir(parents=True)
        (self.screen / "first.lua").write_text("1")
        self.install()
        (self.screen / "frames/login.lua").write_text("old")
        self.install()
        self.assertTrue((self.offloaded() / "loginxml/first.lua").is_file())
        self.assertFalse((self.offloaded() / "loginxml/frames").exists())
        self.assertEqual((self.offloaded() / "loginxml-2/frames/login.lua").read_text(), "old")

    def test_refuses_to_run_outside_addons(self):
        moved = Path(self.temp.name) / "Elsewhere/LogNextChar"
        moved.parent.mkdir()
        shutil.move(str(self.game / "Interface/AddOns/CherrysKit/LogNextChar"), str(moved))
        result = subprocess.run([SHELL, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File",
                                 str(moved / "setup/Install.ps1"), "-Documents", str(self.documents)],
                                capture_output=True, text=True, timeout=60)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((Path(self.temp.name) / "loginxml").exists())


if __name__ == "__main__":
    unittest.main()
