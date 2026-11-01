"""Big frame pools share one XML template (smaller files, quicker to read at login). Expanded the way
the client reads them, every member still has all of its parts and its scripts."""
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

import xml_templates

KIT = pathlib.Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit"
NS = {"ui": "http://www.runewaker.com/"}


def names(root):
    return {node.get("name") for node in root.iter() if node.get("name")}


class XmlTemplateTests(unittest.TestCase):
    def test_every_grid_member_has_its_parts_and_mouse_scripts(self):
        root = xml_templates.parse(KIT / "CherrysGrid" / "CherrysGrid.xml")
        frames = (KIT / "CherrysGrid" / "Frames.lua").read_text(encoding="utf-8")
        parts = re.findall(r'"(\w+)"', frames[frames.index("local PARTS"):frames.index("function F.Obj")])
        self.assertIn("Debuff4Time", parts)
        found = names(root)
        for slot in range(1, 49):
            unit = f"CGrid_Unit{slot}"
            for part in parts:
                self.assertIn(unit + part, found)
            node = root.find(f".//*[@name='{unit}']", NS)
            self.assertEqual(node.get("enableMouse"), "true")
            scripts = {s.tag.split("}")[1] for s in node.find("ui:Scripts", NS)}
            self.assertEqual(scripts, {"OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnMouseWheel"})
        self.assertNotIn("CGrid_Unit49", found)

    def test_every_chat_window_has_its_lines_pictures_and_scroll_bar(self):
        root = xml_templates.parse(KIT / "CherrysChat" / "CherrysChat.xml")
        found = names(root)
        for i in range(1, 11):
            node = root.find(f".//*[@name='CherrysChat_W{i}']", NS)
            self.assertEqual(node.get("parent"), f"ChatFrame{i}")
            for part in ("Line1", "Line40", "Hi40", "Pic60", "More", "Bar", "BarUp", "BarDown", "BarThumb", "BarMiddle"):
                self.assertIn(f"CherrysChat_W{i}{part}", found)
            self.assertNotIn(f"CherrysChat_W{i}Line41", found)

    def test_every_bag_and_bank_button_has_a_slot_number(self):
        root = xml_templates.parse(KIT / "zBag" / "zBagKit.xml")
        found = names(root)
        for stem, parent, count in (("zBagKitBag", "BagItemButton", 180), ("zBagKitBank", "BankItemButton", 40)):
            for n in range(1, count + 1):
                node = root.find(f".//*[@name='{stem}{n}']", NS)
                self.assertEqual(node.get("parent"), f"{parent}{n}")
                self.assertIn(f"{stem}{n}KitSlot", found)
                self.assertIn(f"{stem}{n}KitSlotBack", found)

    def test_every_global_bank_row_and_slot_has_its_parts_and_scripts(self):
        root = xml_templates.parse(KIT / "GlobalBank" / "GlobalBank.xml")
        found = names(root)
        for stem, count, parts, wanted in (
            ("GlobalBankRow", 48, ("Head", "Back", "Name", "Level", "Gold", "Items", "Note", "Group"), {"OnLoad", "OnClick", "OnMouseWheel"}),
            ("GlobalBankItem", 300, ("Slot", "Icon", "Dim", "Glow", "Count"), {"OnEnter", "OnLeave", "OnMouseWheel"}),
        ):
            for n in range(1, count + 1):
                node = root.find(f".//*[@name='{stem}{n}']", NS)
                self.assertEqual(node.get("id"), str(n))
                for part in parts:
                    self.assertIn(f"{stem}{n}{part}", found)
                scripts = {s.tag.split("}")[1] for s in node.find("ui:Scripts", NS)}
                self.assertEqual(scripts, wanted)
            self.assertNotIn(f"{stem}{count + 1}", found)


class XmlFileTests(unittest.TestCase):
    def shipped(self):
        for folder in (KIT.parent, KIT.parents[1] / "loginxml"):
            yield from folder.rglob("*.xml")

    def test_every_xml_file_is_well_formed(self):
        # What the client's reader does with a stray & or < is unknown, so none ships.
        for path in self.shipped():
            with self.subTest(path=path.name):
                ET.parse(path)

    def test_a_template_comes_before_the_frames_that_use_it(self):
        # The client reads a file from the top.
        for path in self.shipped():
            seen = set()
            root = ET.parse(path).getroot()
            templates = {n.get("name") for n in root.iter() if n.get("virtual", "").lower() == "true"}
            for node in root.iter():
                inherits = node.get("inherits")
                if inherits in templates:
                    self.assertIn(inherits, seen, f"{path.name}: {node.get('name')}")
                if node.get("name") in templates:
                    seen.add(node.get("name"))


if __name__ == "__main__":
    unittest.main()
