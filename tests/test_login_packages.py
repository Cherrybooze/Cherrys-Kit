"""Cherry's Loginxml and LogNextChar as packages: what the ZIPs hold, and what Install login screen.bat does."""
import importlib.util
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
        self.assertEqual({name.split("/")[0] for name in self.names("CherrysLoginxml")}, {"CherrysKit"})
        self.assertEqual({name.split("/")[0] for name in self.names("LogNextChar")}, {"LogNextChar"})

    def test_game_would_load_only_the_addons_own_toc(self):
        # The client loads every .toc it finds under Interface/AddOns, at any depth
        tocs = [name for name in self.names("CherrysLoginxml") if name.lower().endswith(".toc")]
        self.assertEqual(tocs, ["CherrysKit/CherrysLoginxmlHook/CherrysLoginxmlHook.toc"])
        self.assertIn("CherrysKit/CherrysLoginxmlHook/LoginScreen/loginxml.toc.txt", self.names("CherrysLoginxml"))

    def test_no_personal_files(self):
        for name in self.names("CherrysLoginxml"):
            if name.startswith("CherrysKit/CherrysLoginxmlHook/LoginScreen/") and "/data/" not in name:
                self.assertNotIn(name.rsplit("/", 1)[-1], build_release.LOGIN_PERSONAL)

    def test_guide_links_work_inside_the_zip(self):
        with ZipFile(self.output / self.packages["CherrysLoginxml"]["filename"]) as archive:
            guide = archive.read("CherrysKit/CherrysLoginxmlHook/README.md").decode("utf-8")
            self.assertIn("(LoginScreen/docs/Rom-Autologin-Readme.md)", guide)
            self.assertIn("CherrysKit/CherrysLoginxmlHook/LoginScreen/docs/Rom-Autologin-Readme.md", archive.namelist())

    def test_requirements_are_recorded(self):
        self.assertTrue(self.packages["CherrysLoginxml"]["requires_hub"])
        self.assertEqual(self.packages["LogNextChar"]["requires_addon"], "CherrysLoginxml")


@unittest.skipUnless(SHELL, "Windows PowerShell required")
class InstallScreenTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.zips = tempfile.TemporaryDirectory()
        output = Path(cls.zips.name)
        packages = {p["package"]: p for p in build_release.write_login_packages(output)}
        cls.package = output / packages["CherrysLoginxml"]["filename"]

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
        script = self.game / "Interface/AddOns/CherrysKit/CherrysLoginxmlHook/setup/Install.ps1"
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

    def test_removes_only_the_old_addon_folder(self):
        old = self.game / "Interface/AddOns/CherrysLoginxml"
        old.mkdir()
        (old / "CherrysLoginxml.toc").write_text("## Title: Cherry's Loginxml helper\n")
        other = self.game / "Interface/AddOns/LogNextChar"
        other.mkdir()
        (other / "LogNextChar.toc").write_text("## Title: LogNextChar\n")
        self.install()
        self.assertFalse(old.exists())
        self.assertTrue(other.exists())

    def test_leaves_a_folder_that_only_shares_the_old_name(self):
        old = self.game / "Interface/AddOns/CherrysLoginxml"
        old.mkdir()
        (old / "CherrysLoginxml.toc").write_text("## Title: Something else\n")
        self.install()
        self.assertTrue(old.exists())

    def test_refuses_to_run_outside_addons(self):
        moved = Path(self.temp.name) / "Elsewhere/CherrysLoginxmlHook"
        moved.parent.mkdir()
        shutil.move(str(self.game / "Interface/AddOns/CherrysKit/CherrysLoginxmlHook"), str(moved))
        result = subprocess.run([SHELL, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File",
                                 str(moved / "setup/Install.ps1"), "-Documents", str(self.documents)],
                                capture_output=True, text=True, timeout=60)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((Path(self.temp.name) / "loginxml").exists())


if __name__ == "__main__":
    unittest.main()
