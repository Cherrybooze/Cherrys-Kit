"""Selected-display/condition UI regressions through shipped native XML handlers."""

import re
import unittest
import xml.etree.ElementTree as ET

import test_rwa as support


class DisplayUITests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.lua.execute("getmetatable(UIParent).SetScripts = function() end")

    def options(self, extras=None, **changes):
        if extras is not None:
            changes["elements"] = extras
        self.saved = self.h.add_aura(**changes)
        self.h.options()
        return self.lua.globals().RWA.Editor.Get("Buff reminder")

    def clean(self, text):
        return re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", text)

    def selectors(self):
        return sorted([w for w in self.h.widgets("Button")
                       if w.width == 134 and w.anchor and w.anchor[1] == "TOPLEFT"
                       and w.anchor[4] in (16, 192)],
                      key=lambda w: (w.anchor[5], w.anchor[4]))

    def button_at(self, x, y):
        choices = [w for w in self.h.widgets("Button") if w.anchor
                   and w.anchor[1] == "TOPLEFT" and w.anchor[4] == x and w.anchor[5] == y]
        self.assertEqual(len(choices), 1, f"button at {x}, {y}")
        return choices[0]

    def click(self, widget, key="LBUTTON"):
        self.h.script(widget.name, "OnClick", key=key)

    def select(self, index):
        self.click(self.selectors()[index])

    def minus(self, index):
        button = self.selectors()[index]
        return self.button_at(button.anchor[4] + 138, button.anchor[5])

    def add_button(self):
        choices = [w for w in self.h.widgets("Button", text="+")
                   if w.anchor and w.anchor[1] == "TOPLEFT" and w.anchor[4] == 354]
        self.assertEqual(len(choices), 1)
        return choices[0]

    def add(self, kind):
        self.click(self.add_button())
        suffix = {"text": "Text", "icon": "Icon", "aurabar": "Bar", "texture": "Graphic"}[kind]
        self.h.script("RWA_DisplayAdd" + suffix, "OnClick", key="LBUTTON")

    def choose(self, label):
        choices = [w for w in self.h.widgets("Button")
                   if (self.clean(w.text) == label or self.clean(w.text).startswith(label + "  -"))
                   and w.width >= 150]
        self.assertEqual(len(choices), 1, f"dropdown choice {label}")
        self.click(choices[0])

    def field(self, label, offset=0):
        labels = [w for w in self.h.widgets("FontString") if w.text == label]
        self.assertEqual(len(labels), 1, f"field label {label}")
        anchor = labels[0].anchor
        return self.h.field_at(anchor[4] + 100 + offset, anchor[5] - 2)

    def legacy_rules(self):
        self.h.click("< Back to rules")
        return self.lua.globals().RWA.UnifiedEditor

    def add_rule(self):
        self.h.click("+ Legacy rule")

    def unified_choice(self, label):
        choices = [w for w in self.h.widgets("Button")
                   if w.parent == "RWA_UnifiedMenu" and self.clean(w.text) == label]
        self.assertEqual(len(choices), 1, f"unified menu choice {label}")
        self.click(choices[0])

    def action(self, label):
        self.click(self.lua.globals().RWA.UnifiedEditor.legacyActionPick)
        self.unified_choice(label)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_selectors_are_not_inline_forms_and_add_menu_has_four_native_choices(self):
        draft = self.options()
        selector = self.selectors()[0]
        main_label = [w for w in self.h.widgets("FontString") if w.text == "Main display"]
        self.assertEqual(len(main_label), 1)
        self.assertLess(main_label[0].anchor[5], selector.anchor[5])
        self.assertFalse(any(w.anchor and w.anchor[5] == selector.anchor[5]
                             for w in self.h.widgets("EditBox")))
        self.assertEqual(len([w for w in self.h.widgets("FontString")
                             if w.text == "click - to remove, + to add new display mode"]), 1)
        self.click(self.add_button())
        self.assertIsNone(draft.elements)
        menu = ET.parse(support.RWA / "DisplayMenu.xml").getroot()
        dimension = menu.find("ui:Frame/ui:Size/ui:AbsDimension", support.NS)
        self.assertLessEqual(int(dimension.get("x")), 160)
        self.assertLessEqual(int(dimension.get("y")), 120)
        choices = [w for w in self.h.widgets("Button") if w.parent == "RWA_DisplayAddMenu"]
        self.assertEqual(sorted(w.text for w in choices), ["Bar", "Graphic", "Icon", "Text"])
        for widget in choices:
            self.assertIn("OnClick", self.h.xml[widget.name])
        self.h.script("RWA_DisplayAddText", "OnClick")
        self.assertEqual(draft.elements[1].type, "text")
        self.assertIsNone(self.saved.elements)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_selected_type_forms_edit_only_that_display_and_survive_switching(self):
        draft = self.options([
            {"type": "text", "fontSize": 16, "text": "old extra", "side": "BOTTOM", "from": 0},
            {"type": "icon", "width": 20, "height": 20, "side": "LEFT", "from": 0},
        ], text="old main")
        self.select(1)
        self.h.type_text(self.field("Size / font"), "23")
        self.h.type_text(self.field("Text"), "extra timer %e")
        self.assertEqual(len(self.h.widgets("Button", text="Icon...")), 0)
        self.select(2)
        self.h.type_text(self.field("Size  W / H"), "35")
        self.h.type_text(self.field("Size  W / H", 88), "36")
        self.assertEqual(len(self.h.widgets("Button", text="Icon...")), 1)
        self.select(0)
        self.assertEqual(draft.text, "old main")
        self.assertEqual((draft.elements[1].fontSize, draft.elements[1].text), (23, "extra timer %e"))
        self.assertEqual((draft.elements[2].width, draft.elements[2].height), (35, 36))
        self.assertEqual(self.saved.elements[1].text, "old extra")
        self.h.click("Save")
        self.assertEqual(self.lua.globals().RWA.GetAura("Buff reminder").elements[1].text, "extra timer %e")

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_selected_type_row_and_side_support_all_core_types(self):
        draft = self.options([{"type": "icon", "side": "LEFT", "from": 0}])
        self.select(1)
        type_control = self.button_at(242, 252)
        self.assertEqual(type_control.text, "Icon")
        self.click(type_control)
        self.choose("Bar")
        self.assertEqual(draft.elements[1].type, "aurabar")
        self.assertEqual(self.saved.regionType, "icon")
        self.assertEqual(draft.regionType, "icon")
        self.h.click("Left")
        self.choose("Below")
        self.assertEqual(draft.elements[1].side, "BOTTOM")
        self.h.click("Bar")
        self.choose("Graphic")
        self.assertEqual(draft.elements[1].type, "texture")
        self.assertEqual(len(self.h.widgets("Button", text="Graphic...")), 1)
        self.assertEqual(len(self.h.widgets("Button", text="Icon...")), 0)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_extra_icon_picker_is_draft_only_and_preview_follows_selected_icon(self):
        draft = self.options([{"type": "icon", "from": 0}], animation={"start": "none", "main": "none", "finish": "none"})
        self.select(1)
        self.h.click("Icon...")
        self.h.script("RWA_IconPick1", "OnClick")
        path = "Interface/Icons/Fixture1"
        self.assertEqual(draft.elements[1].icon, path)
        self.assertIsNone(draft.icon)
        self.assertIsNone(self.saved.elements[1].icon)
        self.h.tick()
        self.assertTrue(any(w.kind == "Texture" and w.parent == "RWA_Preview_icon" and w.texture == path
                            for w in self.lua.globals().fixtureWidgets.values()))

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_selected_look_and_preview_keep_extra_colour_opacity_and_border(self):
        draft = self.options([{"type": "text", "text": "Child", "fontSize": 20,
                               "color": [0.1, 0.2, 0.8, 1], "alpha": 0.4}],
                             color=[1, 0, 0, 1], alpha=1,
                             animation={"start": "none", "main": "none", "finish": "none"})
        self.select(1)
        self.h.tick()
        self.assertTrue(any(w.kind == "FontString" and w.parent == "RWA_Preview_text"
                            and w.color and w.color[3] == 0.8
                            for w in self.lua.globals().fixtureWidgets.values()))
        self.assertAlmostEqual(self.lua.globals().RWA_Preview_text.alpha, 0.4)
        self.h.click("None")
        self.choose("Corners")
        self.assertEqual(draft.elements[1].borderStyle, "corners")
        opacity_labels = [w for w in self.h.widgets("FontString") if w.text == "Opacity %"]
        label = opacity_labels[0]
        self.h.type_text(self.h.field_at(label.anchor[4] + 72, label.anchor[5] - 2), "65")
        self.assertEqual(draft.elements[1].alpha, 0.65)
        self.assertEqual(draft.alpha, 1)
        self.assertEqual(draft.color[1], 1)
        self.assertIsNone(self.saved.elements[1].borderStyle)
        self.assertEqual(len([w for w in self.h.widgets("FontString") if w.text == "Draft preview"]), 1)
        self.assertEqual(len([w for w in self.h.widgets("FontString") if w.text == "Inactive drafts stay visible; Hide rules still apply"]), 1)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_primary_remove_promotes_and_last_display_cannot_be_removed(self):
        draft = self.options([{"type": "texture", "width": 90, "height": 80, "texture": "Circle_White"}])
        triggers = len(draft.triggers)
        self.click(self.minus(0))
        self.assertEqual((draft.regionType, draft.width, draft.height), ("texture", 90, 80))
        self.assertEqual(len(draft.triggers), triggers)
        self.assertIsNone(draft.elements)
        self.assertEqual(self.saved.regionType, "icon")
        self.click(self.minus(0))
        self.assertEqual(len(self.selectors()), 1)
        self.assertTrue(any("at least one display" in message for message in self.lua.globals().fixtureMessages.values()))

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_add_limit_and_menu_closes_on_leave(self):
        draft = self.options()
        for kind in ("aurabar", "texture", "icon"):
            self.add(kind)
        self.assertEqual(len(draft.elements), 3)
        self.click(self.add_button())
        self.assertFalse(self.lua.globals().RWA.DisplayMenu.open)
        self.click(self.minus(3))
        self.click(self.add_button())
        self.h.click("< Back to rules")
        self.assertFalse(self.lua.globals().RWA.DisplayMenu.open)
        self.assertIsNone(self.saved.elements)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_legacy_rules_add_edit_remove_and_revert_drafts(self):
        draft = self.options()
        editor = self.legacy_rules()
        for _ in range(3):
            self.add_rule()
        self.assertEqual(len(draft.conditions), 3)
        self.assertEqual(editor.legacyIndex, 3)
        self.h.type_text(editor.legacyValue.box, "5")
        self.assertEqual(draft.conditions[3].value, 5)
        self.action("Size")
        self.h.type_text(editor.legacyActionInput.box, "150")
        self.assertEqual(draft.conditions[3].set.grow, 1.5)
        self.h.click("Delete rule")
        self.assertEqual(len(draft.conditions), 2)
        self.assertEqual(len(self.saved.conditions), 0)
        self.h.click("Revert")
        self.assertEqual(len(self.lua.globals().RWA.Editor.Get("Buff reminder").conditions), 0)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_legacy_condition_source_and_overlay_edit_only_the_draft(self):
        saved = self.h.add_aura(elements=[{"type": "icon", "from": 2}])
        saved.triggers[2] = self.h.trigger(ids=[500935], showOn="active")
        self.h.options()
        self.saved = saved
        draft = self.lua.globals().RWA.Editor.Get("Buff reminder")
        editor = self.legacy_rules()
        self.add_rule()
        self.click(editor.legacySource)
        self.unified_choice("Source 2: Buff / debuff (player): #500935")
        self.assertEqual(draft.conditions[1].trigger, 2)
        self.action("Overlay icon")
        self.h.type_text(editor.legacyActionInput.box, "Interface/Icons/Fixture2")
        self.assertEqual(draft.conditions[1].set.overlayIcon, "Interface/Icons/Fixture2")
        self.assertIsNone(draft.icon)
        self.assertEqual(len(saved.conditions), 0)
        self.h.click("Save aura")
        committed = self.lua.globals().RWA.GetAura("Buff reminder")
        self.assertEqual(committed.conditions[1].trigger, 2)
        self.assertEqual(committed.conditions[1].set.overlayIcon, "Interface/Icons/Fixture2")

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_legacy_condition_actions_and_missing_or_low_time_behavior(self):
        self.h.buffs(10, present=True)
        self.saved = self.h.add_aura(trigger=self.h.trigger(showOn="active", remainingOp=None, remaining=None))
        self.h.options()
        draft = self.lua.globals().RWA.Editor.Get("Buff reminder")
        self.legacy_rules()
        self.add_rule()
        for label, action in (("Hide", "hide"), ("Show", "show"), ("Sound", "sound"),
                              ("Blink", "blink"), ("Colour", "color")):
            self.action(label)
            self.assertIsNotNone(draft.conditions[1].set[action])
            self.h.click("Remove action")
        self.action("Show")
        for present, left, active in ((True, 10, False), (True, 2.9, True), (False, None, True)):
            self.h.buffs(left, present=present)
            self.h.tick()
            self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].realActive, active)
        self.action("Hide")
        self.h.tick()
        self.assertFalse(self.lua.globals().RWA.loaded["Buff reminder"].realActive)
        self.h.click("Remove action")
        self.h.tick()
        self.assertTrue(self.lua.globals().RWA.loaded["Buff reminder"].realActive)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_selected_extra_preview_uses_its_own_animation_placement(self):
        self.options([{"type": "text", "text": "Bouncing child", "alpha": 0.6,
                       "animation": {"start": "none", "main": "bounce", "finish": "none"}}],
                     animation={"start": "none", "main": "none", "finish": "none"})
        self.select(1)
        self.h.tick()
        frame = self.lua.globals().RWA_Preview_text
        before = frame.anchor[5]
        self.h.tick(0.25)
        self.assertNotEqual(frame.anchor[5], before)
        self.assertAlmostEqual(frame.alpha, 0.6)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_content_fit_preserves_preferred_scale_and_all_inputs_are_xml_backed(self):
        self.lua.globals().UIParent.SetSize(self.lua.globals().UIParent, 1024, 768)
        self.lua.globals().RWA_DB.settings.uiScale = 1.4
        self.options()
        window = self.lua.globals().RWA_OptionsWindow
        self.assertEqual(window.width, 800)
        self.assertGreater(window.height, 580)
        self.assertLessEqual(window.height * window.scale, 736.001)
        self.assertEqual(self.lua.globals().RWA_DB.settings.uiScale, 1.4)
        for widget in self.h.widgets("EditBox"):
            self.assertTrue(widget.name.startswith("RWA_OptEdit"), widget.name)
            self.assertIn("OnTextChanged", self.h.xml[widget.name])
        self.assertLess(self.h.button("Save").anchor[5] + 24, window.height)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_typed_id_invalidates_cache_without_editor_refresh(self):
        self.h.buffs(10, present=True)
        saved = self.h.add_aura(trigger=self.h.trigger(showOn="active", remainingOp=None, remaining=None))
        self.h.options()
        self.lua.execute("""
            fixtureEditorRefreshes = 0;
            local refresh = RWA.RefreshEditor;
            RWA.RefreshEditor = function(...)
              fixtureEditorRefreshes = fixtureEditorRefreshes + 1;
              return refresh(...);
            end;
        """)
        self.h.type_text(self.h.field_for_label("Name or ID"), "500935")
        self.h.tick()
        self.assertEqual(self.lua.globals().fixtureEditorRefreshes, 0)
        self.assertEqual(saved.triggers[1].ids[1], 500934)
        self.assertFalse(self.lua.globals().RWA.loaded["Buff reminder"].realActive)


if __name__ == "__main__":
    unittest.main(verbosity=2)
