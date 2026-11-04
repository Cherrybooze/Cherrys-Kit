"""Each package version in release-packages.json matches its addon README.

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


if __name__ == "__main__":
    unittest.main()
