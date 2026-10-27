"""Editor/model regressions through production Lua and shipped XML handlers."""

import re
import unittest

import test_rwa as support


class EditorRegressionTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        # Require the shipped XML callbacks, as in the native client.
        self.lua.execute("getmetatable(UIParent).SetScripts = function() end")

    def add(self, *, triggers=None, auxiliary=None, elements=None, conditions=None, **changes):
        triggers = triggers or [self.custom(True, "Main"), self.custom(False, "Extra")]
        table = {"mode": "all", **{i: value for i, value in enumerate(triggers, 1)}}
        if auxiliary:
            table["auxiliary"] = auxiliary
        data = {"id": "Review", "regionType": "text", "enabled": True,
                "animation": {"start": "none", "main": "none", "finish": "none"},
                "triggers": table, "conditions": conditions or [], **changes}
        if elements is not None:
            data["elements"] = elements
        self.lua.globals().RWA.AddAura(self.h.table(data))
        self.h.tick()
        return self.lua.globals().RWA.GetAura("Review")

    @staticmethod
    def custom(show, name):
        return {"type": "custom", "code": 'return ' + str(show).lower()
                + ', {name="' + name + '", icon="Interface/Icons/' + name + '"}'}

    def options(self):
        self.h.options("Review")
        return self.lua.globals().RWA.Editor.Get("Review")

    @staticmethod
    def clean(text):
        return re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", text)

    def choose(self, label):
        choices = [w for w in self.h.widgets("Button") if (self.clean(w.text) == label
                   or self.clean(w.text).startswith(label + "  -")) and w.width >= 150]
        self.assertEqual(len(choices), 1, label)
        self.h.script(choices[0].name, "OnClick", key="LBUTTON")

    def selectors(self):
        return sorted([w for w in self.h.widgets("Button") if w.width == 134 and w.anchor
                       and w.anchor[1] == "TOPLEFT" and w.anchor[4] in (16, 192)],
                      key=lambda w: (w.anchor[5], w.anchor[4]))

    def remove_display(self, index):
        selector = self.selectors()[index]
        buttons = [w for w in self.h.widgets("Button") if w.anchor
                   and w.anchor[4] == selector.anchor[4] + 138 and w.anchor[5] == selector.anchor[5]]
        self.assertEqual(len(buttons), 1)
        self.h.script(buttons[0].name, "OnClick", key="LBUTTON")
        self.h.tick()

    def select_trigger(self, index):
        header = [w for w in self.h.widgets("Button") if w.width == 190 and w.anchor and w.anchor[4] == 80]
        self.assertEqual(len(header), 1)
        self.h.script(header[0].name, "OnClick", key="LBUTTON")
        choices = [w for w in self.h.widgets("Button") if w.width == 334
                   and self.clean(w.text).startswith(str(index) + ":")]
        self.assertEqual(len(choices), 1)
        label = self.clean(choices[0].text)
        self.h.script(choices[0].name, "OnClick", key="LBUTTON")
        return label

    def role(self, label):
        current = [w for w in self.h.widgets("Button") if self.clean(w.text)
                   in ("Conditions only v", "Controls showing v")]
        self.assertEqual(len(current), 1)
        self.h.script(current[0].name, "OnClick", key="LBUTTON")
        self.choose(label)
        self.h.tick()

    def delete_selected_trigger(self):
        # Dispatch even a hidden stale delete button to exercise the commit-time guard.
        buttons = [w for w in self.lua.globals().fixtureWidgets.values()
                   if w.kind == "Button" and w.text == "X" and w.anchor and w.anchor[4] == 274]
        self.assertEqual(len(buttons), 1)
        self.h.script(buttons[0].name, "OnClick", key="LBUTTON")
        self.choose("Yes, delete it")
        self.h.tick()

    def save_close(self):
        self.h.click("Save")
        self.lua.globals().RWA.ToggleOptions()
        self.h.tick()

    def owned_case(self):
        self.add(elements=[{"type": "text", "from": 2}],
                 conditions=[{"trigger": 2, "var": "show", "op": "==", "value": 1,
                              "set": {"color": [0, 0, 1, 1]}}])
        draft = self.options()
        self.assertTrue(self.lua.eval("RWA.loaded.Review.realActive"))
        self.remove_display(1)
        return draft

    def test_last_owned_display_removal_keeps_gate_trigger_and_condition_sources(self):
        draft = self.owned_case()
        self.assertTrue(draft.triggers.auxiliary["2"])
        self.assertEqual(len(draft.triggers), 2)
        self.assertEqual(draft.conditions[1].trigger, 2)
        self.assertTrue(self.lua.eval("RWA.loaded.Review.realActive"))
        self.assertEqual(len(self.lua.globals().RWA.GetAura("Review").elements), 1)
        self.save_close()
        self.assertTrue(self.lua.globals().RWA.IsAuraActive("Review"))
        saved = self.lua.globals().RWA.GetAura("Review")
        self.assertTrue(saved.triggers.auxiliary["2"])
        self.assertEqual(saved.conditions[1].trigger, 2)

    def test_conditions_only_picker_and_role_reattach_restore_gate_intentionally(self):
        draft = self.owned_case()
        self.assertIn("conditions only", self.select_trigger(2))
        self.role("Controls showing")
        self.assertIsNone(draft.triggers.auxiliary)
        self.assertFalse(self.lua.eval("RWA.loaded.Review.realActive"))
        self.assertEqual(draft.conditions[1].trigger, 2)
        self.save_close()
        self.assertFalse(self.lua.globals().RWA.IsAuraActive("Review"))

    def test_last_main_cannot_be_made_auxiliary_or_deleted_because_auxiliary_remains(self):
        self.add(auxiliary={"2": True})
        draft = self.options()
        self.role("Conditions only")
        self.assertIsNone(draft.triggers.auxiliary["1"])
        self.assertTrue(draft.triggers.auxiliary["2"])
        self.assertTrue(any("at least one trigger" in message for message in self.lua.globals().fixtureMessages.values()))
        self.delete_selected_trigger()
        self.assertEqual(len(draft.triggers), 2)
        self.assertIn("Main", draft.triggers[1].code)
        self.assertTrue(self.lua.eval("RWA.loaded.Review.realActive"))

    def test_removing_a_trigger_renumbers_auxiliary_extra_sources_and_conditions(self):
        self.add(triggers=[self.custom(True, "One"), self.custom(True, "Two"),
                           self.custom(False, "Three"), self.custom(False, "Four")],
                 elements=[{"type": "text", "from": 3}, {"type": "text", "from": 4}],
                 conditions=[{"trigger": 3}, {"trigger": 4}])
        draft = self.options()
        self.remove_display(1)
        self.assertTrue(draft.triggers.auxiliary["3"])
        self.select_trigger(2)
        self.delete_selected_trigger()
        self.assertEqual(len(draft.triggers), 3)
        self.assertTrue(draft.triggers.auxiliary["2"])
        self.assertIsNone(draft.triggers.auxiliary["3"])
        self.assertEqual(draft.elements[1]["from"], 3)
        self.assertEqual((draft.conditions[1].trigger, draft.conditions[2].trigger), (2, 3))
        self.assertIn("Three", draft.triggers[2].code)
        self.assertTrue(self.lua.eval("RWA.loaded.Review.realActive"))
        self.save_close()
        self.assertTrue(self.lua.globals().RWA.IsAuraActive("Review"))

    def test_legacy_fallback_shares_real_source_without_overriding_explicit_auxiliary(self):
        self.add(triggers=[self.custom(True, "One"), self.custom(True, "Two")],
                 elements=[{"type": "text", "from": 1}, {"type": "icon", "from": 2}])
        self.assertIsNone(self.lua.eval("RWA.OwnedTriggers(RWA.GetAura('Review'))[1]"))
        self.lua.execute("RWA.GetAura('Review').triggers.auxiliary = {['1'] = true}")
        self.assertTrue(self.lua.eval("RWA.OwnedTriggers(RWA.GetAura('Review'))[1]"))
        self.assertIsNone(self.lua.eval("RWA.OwnedTriggers(RWA.GetAura('Review'))[2]"))
        self.lua.execute("RWA.GetAura('Review').triggers.auxiliary['2'] = true; RWA.LoadAura('Review')")
        self.h.tick()
        self.assertFalse(self.lua.globals().RWA.IsAuraActive("Review"))
        draft = self.options()
        self.assertEqual(len(draft.triggers), 2)  # no invented blank buff

    def test_list_off_syncs_existing_draft_and_save_preserves_off(self):
        self.add(triggers=[self.custom(True, "Main")])
        draft = self.options()
        draft.desc = "Keep my unsaved description"
        self.lua.globals().RWA.ShowList()
        self.h.click("|cff40ff40On|r")
        self.h.tick()
        self.assertFalse(self.lua.globals().RWA.GetAura("Review").enabled)
        self.assertFalse(draft.enabled)
        self.assertFalse(self.lua.eval("RWA.loaded.Review.realActive"))
        self.lua.globals().RWA.ShowEditor("Review")
        self.save_close()
        saved = self.lua.globals().RWA.GetAura("Review")
        self.assertFalse(saved.enabled)
        self.assertEqual(saved.desc, "Keep my unsaved description")

    def test_list_on_syncs_existing_disabled_draft(self):
        self.add(triggers=[self.custom(True, "Main")], enabled=False)
        draft = self.options()
        self.lua.globals().RWA.ShowList()
        self.h.click("|cffff5050Off|r")
        self.h.tick()
        self.assertTrue(draft.enabled)
        self.assertTrue(self.lua.eval("RWA.loaded.Review.realActive"))
        self.lua.globals().RWA.ShowEditor("Review")
        self.save_close()
        self.assertTrue(self.lua.globals().RWA.GetAura("Review").enabled)

    def test_primary_promotion_preserves_resolved_extra_style_without_deleted_main_overrides(self):
        self.add(triggers=[self.custom(True, "Main")], color=[1, 0, 0, 1], borderStyle="thick",
                 animation={"start": "none", "main": "flash", "finish": "none"},
                 elements=[{"type": "icon", "from": 0}], point="TOPRIGHT", x=-50, y=100,
                 load={"level": 1})
        draft = self.options()
        self.remove_display(0)
        self.assertEqual(draft.regionType, "icon")
        self.assertEqual((draft.color[1], draft.color[2], draft.color[3]), (1, 1, 1))
        self.assertEqual(draft.borderStyle, "none")
        self.assertEqual(draft.animation.main, "none")
        self.assertEqual((draft.id, draft.point, draft.x, draft.y), ("Review", "TOPRIGHT", -50, 100))
        self.assertEqual(draft.load.level, 1)
        self.assertEqual(self.lua.eval("RWA.loaded.Review.region.icon.color[2]"), 1)
        self.assertEqual(self.lua.eval("RWA.loaded.Review.region.borderCount"), 0)
        self.assertEqual(self.lua.globals().RWA.GetAura("Review").color[2], 0)

    def test_edge_width_fields_use_real_style_defaults(self):
        self.add(triggers=[self.custom(True, "Main")], regionType="icon", borderStyle="thick")
        draft = self.options()
        for style, width in (("thin", 1), ("thick", 3), ("corners", 2), ("double", 1)):
            with self.subTest(style=style):
                draft.borderStyle, draft.borderSize = style, None
                self.lua.globals().RWA.RefreshAuraFromEditor()
                self.h.tick()
                edge = self.h.widgets("FontString", text="Edge")[0]
                field = self.h.field_at(edge.anchor[4] + 208, edge.anchor[5] - 2)
                self.assertEqual(field.text, str(width))
                self.assertEqual(self.lua.eval("RWA.loaded.Review.region.borderParts[1].height"), width)

    def test_share_roundtrip_keeps_multiple_sparse_auxiliary_sources_after_renumber(self):
        self.add(triggers=[self.custom(True, "One"), self.custom(False, "Two"),
                           self.custom(True, "Three"), self.custom(False, "Four")],
                 auxiliary={"2": True, "4": True}, conditions=[{"trigger": 4, "var": "show", "value": 1}])
        self.h.load("Share.lua")
        self.lua.execute("firstCode = RWA.Share.Export({'Review'}); imported = assert(RWA.Share.Import(firstCode))")
        copy = self.lua.globals().RWA.GetAura(self.lua.globals().imported[1])
        self.assertTrue(copy.triggers.auxiliary["2"])
        self.assertTrue(copy.triggers.auxiliary["4"])
        draft = self.options()
        self.select_trigger(2)
        self.delete_selected_trigger()
        self.assertEqual(len(draft.triggers), 3)
        self.assertTrue(draft.triggers.auxiliary["3"])
        self.assertIsNone(draft.triggers.auxiliary["2"])
        self.assertEqual(draft.conditions[1].trigger, 3)
        self.h.click("Save")
        self.lua.execute("secondCode = RWA.Share.Export({'Review'}); importedAgain = assert(RWA.Share.Import(secondCode))")
        copy = self.lua.globals().RWA.GetAura(self.lua.globals().importedAgain[1])
        self.assertTrue(copy.triggers.auxiliary["3"])
        self.assertEqual(copy.conditions[1].trigger, 3)

    def test_numeric_legacy_auxiliary_keys_are_read_and_normalized_when_deleted(self):
        self.add(triggers=[self.custom(True, "One"), self.custom(False, "Two"), self.custom(False, "Three")],
                 auxiliary={2: True, 3: True})
        self.assertTrue(self.lua.globals().RWA.IsAuraActive("Review"))
        draft = self.options()
        self.select_trigger(2)
        self.delete_selected_trigger()
        self.assertTrue(draft.triggers.auxiliary["2"])
        self.assertIsNone(draft.triggers.auxiliary[2])

    def test_role_control_stays_inside_native_pools_and_fitted_window(self):
        self.add(triggers=[self.custom(True, "Main")])
        self.options()
        buttons = [w for w in self.lua.globals().fixtureWidgets.values()
                   if w.name.startswith("RWA_OptBtn") and w.anchor]
        edits = [w for w in self.lua.globals().fixtureWidgets.values()
                 if w.name.startswith("RWA_OptEdit") and w.anchor]
        self.assertLessEqual(len(buttons), 320)
        self.assertLessEqual(len(edits), 48)
        self.assertEqual(self.lua.globals().RWA_OptionsWindow.width, 800)
        self.assertLessEqual(self.lua.globals().RWA_OptionsWindow.height, 822)
        self.assertTrue(all("OnClick" in self.h.xml[w.name] for w in buttons))
        self.assertTrue(all("OnTextChanged" in self.h.xml[w.name] for w in edits))


if __name__ == "__main__":
    unittest.main()
