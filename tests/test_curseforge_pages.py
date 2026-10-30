"""Every CurseForge description says what it needs before anything else, and the plan lists every package."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("curseforge_pages", ROOT / "tools/curseforge_pages.py")
pages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pages)


class DescriptionsTest(unittest.TestCase):
    def setUp(self):
        self.packages = pages.packages()
        self.names = pages.titles(self.packages)

    def test_files_are_up_to_date(self):
        for path, text in pages.updated_files().items():
            self.assertEqual(path.read_text(encoding="utf-8"), text, f"{path.name}: run tools/curseforge_pages.py")

    def test_requirements_come_right_after_the_title(self):
        for package in self.packages:
            lines = (pages.PAGES / package["description_file"]).read_text(encoding="utf-8").splitlines()
            self.assertTrue(lines[0].startswith("# "), package["id"])
            self.assertEqual(lines[1], "", package["id"])
            self.assertTrue(lines[2].startswith("> **Requires:**"), package["id"])

    def test_every_addon_needs_the_hub_first(self):
        for package in self.packages:
            if package["kind"] == "hub":
                continue
            self.assertIn("Cherry's Kit", (pages.PAGES / package["description_file"]).read_text(encoding="utf-8").splitlines()[2])

    def test_lognextchar_needs_the_login_screen(self):
        line = (pages.PAGES / "19-lognextchar.md").read_text(encoding="utf-8").splitlines()[2]
        self.assertIn("Cherry's Kit and Cherry's Loginxml", line)

    def test_a_hub_version_is_named_when_an_addon_needs_one(self):
        for package in self.packages:
            if package.get("minimum_hub_version"):
                self.assertIn(f"hub {package['minimum_hub_version']} or later", pages.front_block(package, self.names))

    def test_combined_file_has_every_page_with_its_requirements(self):
        combined = (pages.PAGES / "descriptions.md").read_text(encoding="utf-8")
        for package in self.packages:
            marker = f"<!-- {package['description_file']} -->"
            self.assertIn(marker, combined)
            self.assertIn(pages.front_block(package, self.names), combined)

    def test_named_addons_exist(self):
        for package in self.packages:
            for item in package.get("works_with", []):
                self.assertIn(item["package"], self.names, package["id"])
            for other in package.get("requires", []):
                self.assertIn(other, self.names, package["id"])

    def test_plan_lists_every_package(self):
        readme = (pages.PAGES / "README.md").read_text(encoding="utf-8")
        for package in self.packages:
            self.assertIn(f"[{package['description_file']}]({package['description_file']})", readme)


if __name__ == "__main__":
    unittest.main()
