"""Pure display-editing regressions executed by the real Lua 5.1 runtime.

Requires Lupa; run with ``python tests/test_rwa_displays.py``.
No game widgets or runtime APIs are needed by DisplayEditor.lua.
"""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


MODEL = (
    Path(__file__).resolve().parents[1]
    / "Interface"
    / "AddOns"
    / "CherrysKit"
    / "RomWeakAuras"
    / "DisplayEditor.lua"
)


class DisplayEditorTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("RWA = {W = {}, On = function() end}")
        for name in ("Init.lua", "Database.lua", "Regions.lua", "Engine.lua", "DisplayEditor.lua"):
            self.lua.execute((MODEL.parent / name).read_text(encoding="utf-8-sig"), name=name)
        self.model = self.lua.globals().RWA.DisplayEditor
        self.same = self.lua.eval("function(a, b) return rawequal(a, b) end")
        self.is_table = self.lua.eval("function(value) return type(value) == 'table' end")

    def table(self, value):
        return self.lua.table_from(value, recursive=True)

    def snapshot(self, value):
        if self.is_table(value):
            return {key: self.snapshot(item) for key, item in value.items()}
        return value

    def aura(self, extras=None, **changes):
        value = {
            "id": "An aura",
            "regionType": "aurabar",
            "point": "TOPRIGHT",
            "x": -53,
            "y": 354,
            "width": 220,
            "height": 22,
            "text": "old primary text",
            "text2": "old primary second text",
            "font": "Chosen font",
            "fontSize": 14,
            "alpha": 0.7,
            "enabled": False,
            "color": [0.2, 0.7, 0.3, 1],
            "bgColor": [0, 0, 0, 0.5],
            "animation": {"start": "fade", "main": "pulse", "finish": "none"},
            "load": {"combat": True, "class": "WARRIOR"},
            "triggers": {
                "mode": "any",
                1: {"type": "status", "check": "health", "unit": "player"},
                2: {"type": "status", "check": "class", "unit": "player"},
                3: {"type": "aura", "names": ["A buff"], "showOn": "active"},
            },
            "conditions": [
                {"trigger": 1, "var": "percent", "op": "<", "value": 30,
                 "set": {"color": [0.9, 0.15, 0.15, 1]}},
                {"trigger": 3, "var": "stacks", "op": ">", "value": 2,
                 "set": {"alpha": 0.5}},
            ],
            "customSetting": {"preserve": "future settings too"},
        }
        if extras is not None:
            value["elements"] = extras
        value.update(changes)
        return self.table(value)

    def assert_keeps_shared_settings(self, data, originals, auxiliary=None):
        for name, (original, snapshot) in originals.items():
            with self.subTest(shared=name):
                self.assertTrue(self.same(data[name], original))
                actual = self.snapshot(data[name])
                if name == "triggers" and auxiliary is not None:
                    self.assertEqual(actual.pop("auxiliary"), auxiliary)
                self.assertEqual(actual, snapshot)

    def shared_settings(self, data, appearance=True):
        keys = ["id", "point", "x", "y", "enabled", "load", "triggers", "conditions", "customSetting"]
        if appearance:
            keys.extend(("font", "alpha", "color", "bgColor", "animation"))
        return {
            name: (data[name], self.snapshot(data[name]))
            for name in keys
        }

    def rendered_appearance(self, data):
        resolved = self.lua.globals().RWA.Regions.ElementData(data, data.elements[1])
        return {name: self.snapshot(resolved[name]) for name in (
            "regionType", "width", "height", "fontSize", "text", "text2", "font",
            "color", "bgColor", "alpha", "animation", "texture", "icon", "previewIcon",
            "showIcon", "borderStyle", "borderColor", "borderSize", "blend",
        )}

    def assert_keeps_rendered_appearance(self, data, expected):
        for name, value in expected.items():
            with self.subTest(appearance=name):
                self.assertEqual(self.snapshot(data[name]), value)

    def assert_rejected_without_changes(self, data, operation, *args):
        before = self.snapshot(data)
        ok, reason = operation(data, *args)
        self.assertFalse(ok)
        self.assertIsInstance(reason, str)
        self.assertTrue(reason)
        self.assertEqual(self.snapshot(data), before)
        return reason

    def test_count_includes_default_main_without_creating_elements(self):
        self.assertEqual(self.model.Count(None), 0)
        data = self.table({})
        self.assertEqual(self.model.Count(data), 1)
        self.assertIsNone(data.elements)
        data = self.aura([{"type": "icon"}, {"type": "text"}, {"type": "icon"}])
        self.assertEqual(self.model.Count(data), 4)

    def test_removing_middle_extra_preserves_triggers_and_element_references(self):
        data = self.aura([
            {"type": "text", "text": "%p", "from": 0, "side": "TOP", "size": 12},
            {"type": "icon", "from": 2, "side": "LEFT", "size": 32},
            {"type": "icon", "from": 3, "side": "RIGHT", "x": 10, "y": -4},
        ])
        shared = self.shared_settings(data)
        list_ref, first, last = data.elements, data.elements[1], data.elements[3]
        first_state, last_state = self.snapshot(first), self.snapshot(last)
        ok, reason = self.model.Remove(data, 2)
        self.assertTrue(ok)
        self.assertIn("conditions only", reason)
        self.assertEqual(self.model.Count(data), 3)
        self.assertTrue(self.same(data.elements, list_ref))
        self.assertTrue(self.same(data.elements[1], first))
        self.assertTrue(self.same(data.elements[2], last))
        self.assertEqual(self.snapshot(first), first_state)
        self.assertEqual(self.snapshot(last), last_state)
        self.assertEqual(data.elements[2]["from"], 3)  # No trigger renumbering.
        self.assertEqual(data.regionType, "aurabar")
        self.assert_keeps_shared_settings(data, shared, auxiliary={"2": True})

    def test_removing_last_extra_keeps_main_and_every_trigger(self):
        data = self.aura([{"type": "icon", "from": 2}])
        shared = self.shared_settings(data)
        ok, reason = self.model.Remove(data, 1)
        self.assertTrue(ok)
        self.assertIn("conditions only", reason)
        self.assertIsNone(data.elements)
        self.assertEqual(self.model.Count(data), 1)
        self.assertEqual(data.regionType, "aurabar")
        self.assert_keeps_shared_settings(data, shared, auxiliary={"2": True})

    def test_last_main_cannot_be_removed_with_nil_or_empty_elements(self):
        for extras in (None, []):
            with self.subTest(extras=extras):
                data = self.aura(extras)
                reason = self.assert_rejected_without_changes(data, self.model.Remove, 0)
                self.assertIn("at least one display", reason)

    def test_main_promotes_text_template_and_rendered_size(self):
        data = self.aura([
            {"type": "text", "text": "Timer %p", "size": 18, "from": 0,
             "side": "BOTTOM", "x": 500, "y": 400},
            {"type": "icon", "size": 44, "from": 3, "side": "LEFT", "x": 7, "y": 8},
        ])
        shared, appearance = self.shared_settings(data, appearance=False), self.rendered_appearance(data)
        list_ref, remaining = data.elements, data.elements[2]
        remaining_state = self.snapshot(remaining)
        self.assertEqual(self.model.Remove(data, 0), (True, None))
        self.assertEqual((data.regionType, data.text, data.text2), ("text", "Timer %p", ""))
        self.assertEqual((data.fontSize, data.width, data.height), (18, 200, 22))
        self.assertEqual(self.model.Count(data), 2)
        self.assertTrue(self.same(data.elements, list_ref))
        self.assertTrue(self.same(data.elements[1], remaining))
        self.assertEqual(self.snapshot(remaining), remaining_state)
        self.assert_keeps_shared_settings(data, shared)
        self.assert_keeps_rendered_appearance(data, appearance)

    def test_main_promotes_icon_without_deleted_text_or_static_icon_override(self):
        data = self.aura(
            [{"type": "icon", "size": "40", "from": 0, "side": "LEFT",
              "text": "new icon text"}],
            icon="old fixed icon", previewIcon="old cached icon",
        )
        shared, appearance = self.shared_settings(data, appearance=False), self.rendered_appearance(data)
        self.assertEqual(self.model.Remove(data, 0), (True, None))
        self.assertEqual((data.regionType, data.width, data.height), ("icon", 40, 40))
        self.assertEqual((data.text, data.text2), ("new icon text", ""))
        self.assertIsNone(data.icon)
        self.assertIsNone(data.previewIcon)
        self.assertIsNone(data.elements)
        self.assert_keeps_shared_settings(data, shared)
        self.assert_keeps_rendered_appearance(data, appearance)

    def test_promoting_owned_source_keeps_trigger_order_and_explains_source_change(self):
        data = self.aura([
            {"type": "icon", "from": 2},
            {"type": "text", "from": 2, "text": "%n", "size": 16},
        ])
        shared, appearance = self.shared_settings(data, appearance=False), self.rendered_appearance(data)
        remaining = data.elements[2]
        ok, reason = self.model.Remove(data, 0)
        self.assertTrue(ok)
        self.assertIn("main display's triggers", reason)
        self.assertEqual(data.elements[1]["from"], 2)
        self.assertTrue(self.same(data.elements[1], remaining))
        self.assertIsNone(data["from"])  # No invented primary-source schema.
        self.assert_keeps_shared_settings(data, shared)
        self.assert_keeps_rendered_appearance(data, appearance)

    def test_promotion_uses_existing_size_fallback_and_keeps_empty_text(self):
        for kind in ("icon", "text"):
            with self.subTest(kind=kind):
                data = self.aura([{"type": kind, "text": ""}])
                self.assertEqual(self.model.Remove(data, 0), (True, None))
                if kind == "icon":
                    self.assertEqual((data.width, data.height), (22, 22))
                else:
                    self.assertEqual((data.fontSize, data.width, data.height), (22, 200, 26))
                    self.assertEqual(data.text, "")
        data = self.table({"elements": [{"type": "text", "size": -20}]})
        self.model.Remove(data, 0)
        self.assertEqual((data.text, data.fontSize, data.width, data.height), ("%n", 32, 200, 36))

    def test_invalid_indices_or_unsupported_promotion_do_not_change_aura(self):
        data = self.aura([{"type": "unsupported", "from": 2}])
        for index in (None, -1, 0.5, 2, "1"):
            with self.subTest(index=index):
                self.assert_rejected_without_changes(data, self.model.Remove, index)
        self.assert_rejected_without_changes(data, self.model.Remove, 0)
        # An unsupported imported extra can still be removed safely.
        ok, reason = self.model.Remove(data, 1)
        self.assertTrue(ok)
        self.assertIn("conditions only", reason)
        self.assertTrue(data.triggers.auxiliary["2"])

    def test_add_icon_and_text_use_existing_schema_and_preserve_references(self):
        data = self.aura()
        shared = self.shared_settings(data)
        self.assertEqual(self.model.Add(data, "icon"), 1)
        first = data.elements[1]
        self.assertEqual(self.snapshot(first), {"type": "icon", "from": 0, "side": "LEFT", "width": 48, "height": 48})
        self.assertEqual(self.model.Add(data, "text"), 2)
        self.assertTrue(self.same(data.elements[1], first))
        self.assertEqual(self.snapshot(data.elements[2]), {
            "type": "text", "from": 0, "side": "BOTTOM", "text": "%n", "fontSize": 18,
            "width": 200, "height": 24,
        })
        self.assertEqual(self.model.Count(data), 3)
        self.assert_keeps_shared_settings(data, shared)

    def test_add_limit_allows_three_extras_and_rejects_unsupported_types(self):
        data = self.aura()
        for kind in (None, "kittytracker", "unknown"):
            with self.subTest(kind=kind):
                self.assert_rejected_without_changes(data, self.model.Add, kind)
        for index in range(1, 4):
            self.assertEqual(self.model.Add(data, "text"), index)
        self.assertEqual(self.model.Count(data), 4)
        reason = self.assert_rejected_without_changes(data, self.model.Add, "icon")
        self.assertIn("three extra", reason)

    def test_bar_and_graphic_add_and_primary_promotion_keep_appearance(self):
        for kind, expected in (("aurabar", (220, 22)), ("texture", (64, 64))):
            with self.subTest(kind=kind):
                data = self.aura()
                self.assertEqual(self.model.Add(data, kind), 1)
                extra = data.elements[1]
                extra.color = self.table([0.1, 0.2, 0.8, 1])
                extra.alpha = 0.4
                extra.borderStyle = "corners"
                triggers, conditions = data.triggers, data.conditions
                self.assertEqual(self.model.Remove(data, 0), (True, None))
                self.assertEqual(data.regionType, kind)
                self.assertEqual((data.width, data.height), expected)
                self.assertEqual(data.color[3], 0.8)
                self.assertEqual(data.alpha, 0.4)
                self.assertEqual(data.borderStyle, "corners")
                self.assertTrue(self.same(data.triggers, triggers))
                self.assertTrue(self.same(data.conditions, conditions))

    def test_legacy_bar_promotion_retains_rendered_size_and_icon_default(self):
        data = self.aura([{"type": "aurabar", "size": 30}])
        self.model.Remove(data, 0)
        self.assertEqual((data.regionType, data.width, data.height, data.fontSize), ("aurabar", 220, 30, 12))
        self.assertTrue(data.showIcon)

    def test_invalid_aura_or_display_list_returns_explanation(self):
        for data in (None, "not an aura", self.table({"elements": "not a list"})):
            with self.subTest(data=data):
                self.assert_rejected_without_changes(data, self.model.Add, "text")
                self.assert_rejected_without_changes(data, self.model.Remove, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
