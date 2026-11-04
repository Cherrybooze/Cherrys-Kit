"""Release versions agree: release-packages.json, addon READMEs and download links.

The release ZIP name and release-versions.json come from release-packages.json,
while the guided setup reads the installed addon's README "Version **x**" line.
If the two differ, the setup reports a mismatch for that addon forever.
"""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_LINE = re.compile(r"Version \*\*([^*]+)\*\*")


def readme_for(folder):
    for base in (ROOT / "Interface/AddOns/CherrysKit", ROOT / "Interface/AddOns"):
        path = base / folder / "README.md"
        if path.exists():
            return path
    return None


class PackageVersionTests(unittest.TestCase):
    def test_addon_and_standalone_versions_match_their_readmes(self):
        data = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
        checked = 0
        for key in ("addons", "standalone_packages"):
            for package in data[key]:
                folder, version = package["folder"], package["version"]
                with self.subTest(folder=folder):
                    readme = readme_for(folder)
                    self.assertIsNotNone(readme, folder + " has no README.md")
                    match = VERSION_LINE.search(readme.read_text(encoding="utf-8"))
                    self.assertIsNotNone(match, str(readme) + " has no Version line")
                    self.assertEqual(match.group(1), version,
                                     folder + ": release-packages.json and README.md disagree")
                    checked += 1
        self.assertGreater(checked, 10)

    def test_download_links_name_files_this_release_builds(self):
        data = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
        kit = data["kit_version"]
        manifest = ROOT / "extras/GlobalBankDailyRewards/GlobalBank/Helper/ChromeExtension/manifest.json"
        extension = json.loads(manifest.read_text(encoding="utf-8"))["version"]
        expected = {"CherrysKit-Full-" + kit + ".zip", "CherrysKit-Hub-" + kit + ".zip",
                    "CherrysKit-GlobalBankDailyRewards-" + extension + ".zip",
                    "release-versions.json", "release-manifest.json", "SHA256SUMS.txt"}
        expected |= {"CherrysKit-%s-%s.zip" % (a["folder"], a["version"]) for a in data["addons"]}
        expected |= {"%s-%s.zip" % (a["folder"], a["version"])
                     for a in data["standalone_packages"] + data["external_packages"]}
        link = re.compile(r"releases/download/v" + re.escape(kit) + r"/([^)\s\"'#?]+)")
        found = 0
        for path in (ROOT / "README.md", ROOT / "extras/GlobalBankDailyRewards/README.md"):
            for name in link.findall(path.read_text(encoding="utf-8")):
                found += 1
                with self.subTest(file=path.name, link=name):
                    self.assertIn(name, expected, "no such file in release v" + kit)
        self.assertGreater(found, 0)


if __name__ == "__main__":
    unittest.main()
