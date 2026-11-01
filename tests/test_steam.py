"""Steam: the daily button's route past Steam's browser, Steam's characters as one account, and the setup's two installs."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface/AddOns/CherrysKit"
SETUP = KIT / "Setup/Setup-CherrysKit.ps1"
SHELL = shutil.which("powershell") or shutil.which("pwsh")
NODE = shutil.which("node")
os.environ["CHERRYSKIT_FIND_INSTALLS"] = "none"  # never the real game folders of the PC running these


class ClientKindTests(unittest.TestCase):
    def kit(self, setup):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(setup)
        source = (KIT / "CherrysKit.lua").read_text(encoding="utf-8-sig")
        # Only the function under test: the rest of the hub needs a whole client.
        start = source.index("function Kit.IsSteam()")
        end = source.index("local function runSlash")
        lua.execute("CherrysKit = {}; local Kit = CherrysKit\n" + source[start:end])
        return lua.globals().CherrysKit

    def test_the_setups_mark_says_steam(self):
        kit = self.kit('loadfile = function(path) if path == "Interface/CherrysKitClient.lua" then return function() return "steam" end end end')
        self.assertTrue(kit.IsSteam())

    def test_a_steam_login_says_steam_without_the_mark(self):
        self.assertTrue(self.kit('GetAccountName = function() return "SteamLogin" end').IsSteam())

    def test_anything_else_is_not_steam(self):
        for account in ("TNTLogin", "someone"):
            self.assertFalse(self.kit(f'GetAccountName = function() return "{account}" end').IsSteam())
        self.assertFalse(self.kit("").IsSteam())


class SteamShopTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('''
          messages, opened, topup, pressed = {}, {}, {}, 0
          steam = true
          CherrysKit = { IsSteam = function() return steam end }
          DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) messages[#messages + 1] = text end }
          UnitLevel = function() return 100 end
          OnClick_MinimapStoreButton = function() pressed = pressed + 1 end
          GC_OpenWebRadio = function(link) opened[#opened + 1] = link end
          OpenTopupPage = function(link) topup[#topup + 1] = link end
        ''')
        for name in ("ZShop.lua", "ZShopButton.lua"):
            self.lua.execute((KIT / "ZShop" / name).read_text(encoding="utf-8-sig"))
        self.lua.execute('''
          ZShop_Char = {}
          ZShop_Settings = {}
          ZShop.Button.Now = function() return 1700000000 end
          ZShop.Button.Refresh = function() end
        ''')
        self.shop = self.lua.globals().ZShop
        self.g = self.lua.globals()

    def test_the_daily_button_goes_to_the_normal_browser_with_placeholders_only(self):
        self.shop.Open("daily")
        self.assertEqual(self.g.opened[1], "https://eu-shop-runesofmagic.gameforge.com/dailies/display/5"
                         "?sas=[$SESSIONID]&c=[$LANGUAGE]&shopType=ingame&pid=[$ROLEDBID]&sid=[$WORLDID]")
        self.assertEqual(self.g.pressed, 0)
        self.assertIsNotNone(self.g.ZShop_Char.claimed)
        self.assertIsNone(self.shop.pending)
        self.assertIsNone(self.shop.waitTimer)

    def test_a_refusing_browser_leaves_the_day_unmarked(self):
        self.lua.execute("GC_OpenWebRadio = function() return false end")
        self.shop.Open("daily")
        self.assertIsNone(self.g.ZShop_Char.claimed)

    def test_other_shop_opens_stay_stock_and_never_touch_the_normal_browser(self):
        self.shop.Open("home")
        self.assertEqual(self.g.pressed, 1)
        self.shop.Open("depot")
        self.assertIn("/depotitems?sas=[$SESSIONID]", self.g.topup[1])
        self.assertEqual(len(list(self.g.opened)), 0)
        self.assertIsNone(self.g.ZShop_Char.claimed)
        self.assertIsNone(self.shop.waitTimer)

    def test_below_level_100_nothing_opens(self):
        self.lua.execute("UnitLevel = function() return 50 end")
        self.shop.Open("daily")
        self.assertEqual(len(list(self.g.opened)), 0)

    def test_the_shop_address_comes_from_config_then_a_past_link_then_the_language(self):
        self.lua.execute('GetLanguage = function() return "ENUS" end')
        self.assertEqual(self.shop.ShopHost(), "https://us-shop-runesofmagic.gameforge.com")
        self.lua.execute('steam = false')
        self.shop.OnShopLink("https://eu-shop-runesofmagic.gameforge.com?sas=1&c=ENEU&shopType=ingame&pid=2&sid=3")
        self.assertEqual(self.g.ZShop_Settings.shopHost, "https://eu-shop-runesofmagic.gameforge.com")
        self.assertEqual(self.shop.ShopHost(), "https://eu-shop-runesofmagic.gameforge.com")
        self.shop.config.shop_host = "https://xx-shop-runesofmagic.gameforge.com"
        self.assertEqual(self.shop.ShopHost(), "https://xx-shop-runesofmagic.gameforge.com")

    def test_only_the_address_of_a_link_is_kept(self):
        self.lua.execute('steam = false')
        self.shop.OnShopLink("https://eu-shop-runesofmagic.gameforge.com?sas=12345&c=ENEU&shopType=ingame&pid=678&sid=9")
        saved = dict(self.g.ZShop_Settings)
        self.assertNotIn("12345", json.dumps(saved))

    def test_gameforge_keeps_its_old_route(self):
        self.lua.execute('steam = false')
        self.shop.Open("daily")
        self.assertEqual(self.g.pressed, 1)
        self.assertEqual(len(list(self.g.opened)), 0)
        self.assertIsNotNone(self.shop.pending)


class SteamAccountTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('SaveVariablesPerCharacter = function() end')
        source = (KIT / "GlobalBank/GlobalBank.lua").read_text(encoding="utf-8-sig")
        self.lua.execute(source)
        self.gb = self.lua.globals().GlobalBank

    def add(self, key, *records):
        text = "`".join(("GB1~" + key + "~Mage~80~100~60~200~0~t",) + records)
        self.gb.chars[key] = self.gb.Parse(text)

    def test_the_mark_survives_a_save_and_a_read(self):
        self.add("Alt", "S~Aynara", "L~steam")
        self.assertTrue(self.gb.chars["Alt"].steam)
        self.assertIn("L~steam", self.gb.Serialize(self.gb.chars["Alt"]))
        self.add("Other", "S~Aynara")
        self.assertIsNone(self.gb.chars["Other"].steam)
        self.assertNotIn("L~steam", self.gb.Serialize(self.gb.chars["Other"]))

    def test_steams_characters_are_one_account_on_each_server(self):
        self.add("One", "S~Aynara", "L~steam")
        self.add("Two", "S~Aynara", "L~steam")
        self.add("Three", "S~Other", "L~steam")
        self.add("Gf", "S~Aynara", "R~Gf;GfAlt")
        accounts = self.gb.Accounts()
        self.assertEqual(accounts["One"].id, accounts["Two"].id)
        self.assertEqual(accounts["One"].label, "Steam account")
        self.assertNotEqual(accounts["One"].id, accounts["Three"].id)
        self.assertEqual(accounts["Gf"].label, "Gf's account")

    def test_a_name_only_steams_login_screen_listed_joins_the_steam_account(self):
        self.add("One", "S~Aynara", "L~steam", "R~One;NotSavedSince")
        self.add("NotSavedSince", "S~Aynara")
        self.assertEqual(self.gb.Accounts()["NotSavedSince"].label, "Steam account")


@unittest.skipUnless(NODE, "Node required")
class SteamPageTests(unittest.TestCase):
    def run_js(self, body):
        extension = KIT / "GlobalBank/Helper/ChromeExtension"
        script = f"""
          const fs = require('fs'), vm = require('vm');
          const context = {{console, Intl, setTimeout, clearTimeout}};
          context.globalThis = context; context.self = context;
          vm.createContext(context);
          vm.runInContext(fs.readFileSync({json.dumps(str(extension / 'accounts.js'))}, 'utf8') + ';globalThis.GBAccounts = GBAccounts;', context);
          const accountGroups = context.GBAccounts.accountGroups;
          {body}
        """
        result = subprocess.run([NODE, "-e", script], capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_steam_groups_per_server_and_leaves_others_alone(self):
        out = self.run_js("""
          const known = accountGroups([{name:'One',server:'Aynara',steam:true},{name:'Two',server:'Aynara',steam:true},
            {name:'Far',server:'Other',steam:true},{name:'Gf',server:'Aynara',roster:['Gf','Alt']}]);
          console.log(JSON.stringify({same: known.of('One') === known.of('Two'), steam: known.of('One').steam,
            far: known.of('Far') === known.of('One'), farSteam: known.of('Far').steam, gf: !!known.of('Gf').steam}));
        """)
        self.assertEqual(out, {"same": True, "steam": True, "far": False, "farSteam": True, "gf": False})


@unittest.skipUnless(SHELL, "PowerShell required")
class TwoInstallTests(unittest.TestCase):
    def game(self, root, relative, *addons):
        game = Path(root) / relative
        folder = game / "Interface/AddOns"
        folder.mkdir(parents=True)
        (game / "Client.exe").write_text("fixture", encoding="utf-8")
        for name in addons:
            (folder / name).mkdir()
            (folder / name / "marker.toc").write_text("fixture\n", encoding="utf-8")
        return game

    def add_kit(self, game, version="9.9.9"):
        kit = game / "Interface/AddOns/CherrysKit"
        (kit / "Setup").mkdir(parents=True)
        shutil.copy2(SETUP, kit / "Setup" / SETUP.name)
        shutil.copy2(KIT / "KitOrigins.lua", kit / "KitOrigins.lua")
        (kit / "CherrysKit.toc").write_text(f"## Version: {version}\n", encoding="utf-8")
        (kit / "README.md").write_text("Version **1.0**\n", encoding="utf-8")
        (kit / "zBag").mkdir()
        (kit / "zBag/zBagKit.lua").write_text("-- fixture\n", encoding="utf-8")
        return kit

    def run_from(self, game, also):
        return subprocess.run(
            [SHELL, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
             str(game / "Interface/AddOns/CherrysKit/Setup" / SETUP.name), "-NonInteractive", "-AlsoInstall", str(also)],
            capture_output=True, text=True, errors="replace", timeout=300)

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = temp.name
        self.gameforge = self.game(self.root, "RunesOfMagic")
        self.steam = self.game(self.root, "SteamLibrary/steamapps/common/Runes of Magic", "zBag", "KeepMe")

    def is_junction_to(self, link, target):
        result = subprocess.run([SHELL, "-NoLogo", "-NoProfile", "-Command",
                                 f"(Get-Item -LiteralPath '{link}' -Force).Target"],
                                capture_output=True, text=True, timeout=60)
        return str(target).lower() in result.stdout.lower()

    def check_steam_is_set_up(self):
        interface = self.steam / "Interface"
        self.assertTrue((interface / "AddOns/CherrysKit/CherrysKit.toc").is_file())
        self.assertEqual((interface / "CherrysKitClient.lua").read_text(encoding="utf-8").strip(), 'return "steam"')
        self.assertTrue(self.is_junction_to(interface / "GlobalBankHelper", self.gameforge / "Interface/GlobalBankHelper"))
        self.assertTrue((self.gameforge / "Interface/GlobalBankHelper").is_dir())
        self.assertFalse((interface / "AddOns/zBag").exists())
        self.assertTrue((interface / "offloaded_addons/zBag").is_dir())
        self.assertTrue((interface / "AddOns/KeepMe").is_dir())
        self.assertFalse((self.gameforge / "Interface/CherrysKitClient.lua").exists())

    def test_from_gameforge_it_sets_up_steam_too(self):
        self.add_kit(self.gameforge)
        result = self.run_from(self.gameforge, self.steam)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.check_steam_is_set_up()

    def test_from_steam_it_sets_up_gameforge_too(self):
        self.add_kit(self.steam)
        result = self.run_from(self.steam, self.gameforge)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.check_steam_is_set_up()
        self.assertTrue((self.gameforge / "Interface/AddOns/CherrysKit/CherrysKit.toc").is_file())

    def test_a_second_run_changes_nothing(self):
        self.add_kit(self.gameforge)
        self.run_from(self.gameforge, self.steam)
        result = self.run_from(self.gameforge, self.steam)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("up to date", result.stdout)
        self.assertNotIn("previous", " ".join(p.name for p in (self.steam / "Interface/offloaded_addons").iterdir()))

    def test_an_older_kit_there_is_updated_and_what_players_edit_stays(self):
        self.add_kit(self.gameforge)
        old = self.add_kit(self.steam, "1.0.0")
        (old / "Commands.lua").write_text("-- mine\n", encoding="utf-8")
        result = self.run_from(self.gameforge, self.steam)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("9.9.9", (old / "CherrysKit.toc").read_text(encoding="utf-8"))
        self.assertEqual((old / "Commands.lua").read_text(encoding="utf-8"), "-- mine\n")

    def test_steams_own_data_folder_moves_aside_instead_of_being_lost(self):
        self.add_kit(self.gameforge)
        data = self.steam / "Interface/GlobalBankHelper"
        data.mkdir()
        (data / "GlobalBank.json").write_text("{}", encoding="utf-8")
        result = self.run_from(self.gameforge, self.steam)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        kept = [p for p in (self.steam / "Interface/offloaded_addons").iterdir() if p.name.startswith("GlobalBankHelper")]
        self.assertEqual(len(kept), 1)
        self.assertTrue((kept[0] / "GlobalBank.json").is_file())

    def test_without_being_named_no_other_install_is_touched(self):
        self.add_kit(self.gameforge)
        result = subprocess.run(
            [SHELL, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
             str(self.gameforge / "Interface/AddOns/CherrysKit/Setup" / SETUP.name), "-NonInteractive"],
            capture_output=True, text=True, errors="replace", timeout=300)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.steam / "Interface/AddOns/CherrysKit").exists())


if __name__ == "__main__":
    unittest.main()
