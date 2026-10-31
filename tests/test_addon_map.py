"""The map in release-packages.json has to match what the addons really do."""
import json
import re
import unittest
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
ADDONS = ROOT / "Interface/AddOns"
KIT = ADDONS / "CherrysKit"
DATA = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
PACKAGES = {package["folder"]: package for package in DATA["addons"] + DATA["standalone_packages"]}
# Names that only exist with that addon. A name another addon reaches for means a link.
OWN_NAMES = {
    "KittyCombo": ["Kitty"],
    "RomWeakAuras": ["RWA", "RWA_Script"],
    "CherrysChat": ["CherrysChat"],
    "zBag": ["zBagKit", "zBagItem_OnClick", "zBagBackgroundCloseButton", "zBagB_OnUpdate"],
    "GlobalBank": ["GlobalBank"],
    "ExtendedMacroIcons": ["CherrysEMI"],
    "TooltipIds": ["TooltipIds"],
    "UltimateMailMod": ["UMMFrame", "UMMMailManager", "UMMConfig"],
    "AdvancedAuctionHouse": ["AAH"],
    "ZShop": ["ZShop"],
    "pbInfo": ["pbInfo", "pbInfoQuestTracker"],
    "PortraitHP": ["PortraitHP"],
    "CherrysGrid": ["CherrysGrid"],
    "CherrysQuests": ["CherrysQuests"],
    "CherrysBar": ["CherrysBar"],
    "LogNextChar": ["LogNextChar"],
    "CherrysLoginxml": ["CherrysLoginxml"],
}
# Only reads other addons' names, to time them. Its own description says so.
LABELS_ONLY = {"Perf.lua"}


def source_folder(package):
    if package in ("CherrysLoginxml", "LogNextChar"):
        return ADDONS / PACKAGES[package].get("install_folder", package)
    return KIT / package


def code_of(path):
    text = path.read_text(encoding="latin-1")
    if path.suffix.lower() == ".xml":
        return re.sub(r"<!--.*?-->", "", text, flags=re.S)
    text = re.sub(r"--\[\[.*?\]\]", "", text, flags=re.S)
    return re.sub(r"--[^\n]*", "", text)


class AddonMapTest(unittest.TestCase):
    maxDiff = None

    def test_every_link_in_the_code_is_in_the_map(self):
        undeclared = []
        for package in PACKAGES:
            declared = {item["package"] for item in PACKAGES[package].get("works_with", [])}
            for path in source_folder(package).rglob("*"):
                if path.suffix.lower() not in (".lua", ".xml") or path.name in LABELS_ONLY or "docs" in path.parts:
                    continue
                code = code_of(path)
                for other, names in OWN_NAMES.items():
                    if other == package or other in declared:
                        continue
                    for name in names:
                        if re.search(rf"(?<![\w.\"]){re.escape(name)}\b", code):
                            undeclared.append(f"{package} reaches for {name} ({other}) in {path.name}")
        self.assertEqual(sorted(set(undeclared)), [])

    def test_links_are_listed_on_both_sides(self):
        missing = []
        for package, data in PACKAGES.items():
            for item in data.get("works_with", []):
                if package not in {other["package"] for other in PACKAGES[item["package"]].get("works_with", [])}:
                    missing.append(f"{item['package']} doesn't list {package}")
        self.assertEqual(missing, [])

    def test_only_the_hub_is_ever_required(self):
        for package, data in PACKAGES.items():
            self.assertEqual(data.get("requires", []), [], package)

    def test_every_addon_says_where_it_came_from(self):
        for package, data in PACKAGES.items():
            origin = data["origin"]
            self.assertIn(origin["kind"], ("original", "older"), package)
            self.assertTrue(origin["folder"] and origin["files"], package)
            if origin["kind"] == "original":
                self.assertTrue(origin["name"] and origin["by"], package)

    def test_the_file_the_hub_looks_for_is_real(self):
        for package, data in PACKAGES.items():
            top, _, rest = data["kit_file"].partition("/")
            self.assertTrue((source_folder(package) / rest).is_file(), data["kit_file"])
            self.assertEqual(top, data.get("install_folder", package))

    def test_nothing_under_addons_has_its_own_manifest_except_the_hub(self):
        tocs = [path.relative_to(ADDONS).as_posix() for path in ADDONS.rglob("*.toc")]
        self.assertEqual(tocs, ["CherrysKit/CherrysKit.toc"])

    def test_the_hub_manifest_loads_the_separate_packages(self):
        toc = (KIT / "CherrysKit.toc").read_text(encoding="utf-8-sig")
        for line in ("CherrysLoginxmlHook/CherrysLoginxmlHook.lua", "CherrysLoginxmlHook/CherrysLoginxmlHook.xml", "LogNextChar/LogNextChar.lua", "LogNextChar/LogNextChar.xml", "KitOrigins.lua"):
            self.assertIn("\n" + line, toc.replace("\r\n", "\n"))
        self.assertLess(toc.index("KitOrigins.lua"), toc.index("\nCherrysKit.lua"))

    def test_descriptions_carry_the_map(self):
        pages = ROOT / "docs/curseforge"
        for package, data in PACKAGES.items():
            for path in (pages / data["description_file"], source_folder(package) / "README.md"):
                text = path.read_text(encoding="utf-8")
                head = text[:text.index("**On its own:**") + 400] if "**On its own:**" in text else ""
                self.assertIn("**Where it goes:**", text, path)
                self.assertIn("**On its own:**", text, path)
                self.assertIn(f"AddOns\\{data['origin']['folder']}", text, path)
                self.assertIn("takes precedence", text, path)
                for item in data.get("works_with", []):
                    self.assertIn(item["for"], text, f"{path}: {item['package']}")

    def test_the_reason_for_one_folder_is_written_down(self):
        for path in (ROOT / "docs/ADDON_MAP.md", KIT / "README.md", ROOT / "docs/curseforge/01-cherrys-kit.md"):
            text = path.read_text(encoding="utf-8")
            self.assertIn("Compatibility with addons managed separately can't be guaranteed", text, path)

    def test_the_row_count_fits_every_addon(self):
        hub = (KIT / "CherrysKit.lua").read_text(encoding="utf-8")
        rows = int(re.search(r"Kit\.MAX_ROWS = (\d+)", hub).group(1))
        self.assertGreaterEqual(rows, len(PACKAGES))
        xml = (KIT / "CherrysKit.xml").read_text(encoding="utf-8")
        for row in range(1, rows + 1):
            for part in ("Name", "Cmd", "Open", "Toggle"):
                self.assertIn(f'name="CherrysKit_Row{row}{part}"', xml)


if __name__ == "__main__":
    unittest.main()
