"""Real Lua 5.1 regressions for RWA triggers, drafts and XML editor controls.

Run with Lupa installed: python -m unittest discover -s tests -p test_rwa.py -v
The fixture replaces only game widgets/APIs; production modules and XML handlers run.
"""

from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
RWA = ROOT / "Interface" / "AddOns" / "CherrysKit" / "RomWeakAuras"
NS = {"ui": "http://www.runewaker.com/"}
BUFF_ICON = "Interface/Icons/fixture_buff_500934"


class RWATests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((Path(__file__).with_name("rwa_fixtures.lua")).read_text(encoding="utf-8"))
        self.xml = {}
        for name in ("Frames.xml", "OptionsWidgets.xml", "UnifiedWidgets.xml", "DisplayMenu.xml", "IconPicker.xml", "HotbarPicker.xml"):
            self.load_xml(name)
        for name in ("Init.lua", "MediaList.lua", "Widgets.lua", "Events.lua", "Database.lua",
                     "Editor.lua", "ClassIcons.lua", "Triggers.lua", "Regions.lua", "Conditions.lua", "Rules.lua", "Resources.lua", "ResourceDisplays.lua", "Engine.lua",
                     "DisplayEditor.lua", "DisplayMenu.lua", "IconPicker.lua", "HotbarPicker.lua", "Templates.lua", "SentenceLayout.lua", "UnifiedEditor.lua"):
            self.load(name)
        self.lua.execute("""
            -- Existing profile with built-in resources deliberately removed;
            -- resource lifecycle tests separately cover initial installation.
            RWA_DB = {auras = {}, order = {}, settings = {resourceDefaultsVersion=2,starterFlowDefaultsVersion=1}};
            RWA.MergeDefaults(RWA_DB.settings, RWA.SETTING_DEFAULTS);
            local report = RWA.Error;
            RWA.Error = function(message)
                table.insert(fixtureErrors, tostring(message));
                report(message);
            end;
            RWA.Share = {Export = function() return "RWA-fixture", 1; end};
            RWA.Fire("RWA_READY");
        """)

    def tearDown(self):
        self.assertEqual(list(self.lua.globals().fixtureErrors.values()), [])

    def load(self, name):
        self.lua.execute((RWA / name).read_text(encoding="utf-8-sig"), name=name)

    def load_xml(self, filename):
        tree = ET.parse(RWA / filename)
        widget_tags = {"Frame", "Button", "EditBox", "Texture", "FontString"}

        def visit(node, parent="UIParent"):
            kind = node.tag.split("}")[-1]
            name = node.get("name")
            if name and kind in widget_tags:
                name = name.replace("$parent", parent)
                parent_name = node.get("parent", parent).replace("$parent", parent)
                widget = self.lua.globals().FixtureWidget(kind, name, parent_name)
                widget.visible = node.get("hidden") != "true"
                widget.text = node.get("text", "")
                widget.strata = node.get("frameStrata")
                if node.get("frameLevel"):
                    widget.frameLevel = int(node.get("frameLevel"))
                dimensions = node.find("ui:Size/ui:AbsDimension", NS)
                if dimensions is not None:
                    widget.width = float(dimensions.get("x", 48))
                    widget.height = float(dimensions.get("y", 48))
                scripts = node.find("ui:Scripts", NS)
                if scripts is not None:
                    handlers = {script.tag.split("}")[-1]: script.text or ""
                                for script in scripts}
                    self.xml[name] = handlers
                    self.lua.globals().fixtureXmlScripts[name] = self.lua.table_from(handlers)
                parent = name
            for child in node:
                visit(child, parent)

        visit(tree.getroot())

    def table(self, value):
        return self.lua.table_from(value, recursive=True)

    def trigger(self, **changes):
        value = {"type": "aura", "unit": "player", "filter": "HELPFUL",
                 "ids": [500934], "names": [], "showOn": "missingOrExpiring",
                 "remainingOp": "<", "remaining": 3}
        value.update(changes)
        return self.table(value)

    def buffs(self, left=None, *, present=False, buff_id=500934, unit="player"):
        data = [] if not present else [{"id": buff_id, "left": left, "name": "Fixture buff",
                                      "icon": BUFF_ICON, "stacks": 2}]
        self.lua.globals().fixtureBuffs[unit] = self.table(data)
        self.lua.globals().RWA.Triggers.InvalidateAuras()

    def evaluate(self, trigger):
        return self.lua.globals().RWA.Triggers.Evaluate(trigger, self.lua.globals().fixtureNow,
                                                       self.lua.table())

    def add_aura(self, name="Buff reminder", *, trigger=None, **changes):
        self.lua.globals().testAura = self.table({"id": name, **changes})
        self.lua.globals().testTrigger = trigger or self.trigger()
        self.lua.execute('testAura.triggers = {mode = "all", testTrigger}; RWA.AddAura(testAura);')
        return self.lua.globals().RWA_DB.auras[name]

    def tick(self, advance=0.11):
        self.lua.globals().fixtureNow += advance
        self.script("RWA_CoreFrame", "OnUpdate")

    def script(self, widget, event, **globals_):
        for name, value in globals_.items():
            self.lua.globals()[name] = value
        self.lua.globals().FixtureDispatch(widget, event)

    def options(self, name="Buff reminder"):
        self.load("Options.lua")
        self.lua.globals().RWA.ToggleOptions()
        self.open_legacy_editor(name)

    def open_legacy_editor(self, name):
        self.lua.globals().RWA.ShowEditor(name)
        self.click("Detailed legacy sources and appearance...")
        self.tick()

    def widgets(self, kind, *, text=None):
        result = [w for w in self.lua.globals().fixtureWidgets.values()
                  if w.kind == kind and w.IsVisible(w)]
        if text is not None:
            result = [w for w in result if w.text == text]
        return sorted(result, key=lambda w: w.name)

    def button(self, text):
        choices = self.widgets("Button", text=text)
        self.assertEqual(len(choices), 1, f"expected one visible button {text!r}")
        return choices[0]

    def click(self, text):
        self.script(self.button(text).name, "OnClick", key="LBUTTON")

    def click_prefix(self, prefix):
        choices = [w for w in self.widgets("Button")
                   if re.sub(r"\|c[0-9a-fA-F]{8}|\|r", "", w.text).startswith(prefix)]
        self.assertEqual(len(choices), 1, f"expected one visible button starting with {prefix!r}")
        self.script(choices[0].name, "OnClick", key="LBUTTON")

    def field_at(self, x, y):
        choices = [w for w in self.widgets("EditBox")
                   if w.anchor and w.anchor[4] == x and w.anchor[5] == y]
        self.assertEqual(len(choices), 1, f"expected one edit box at {x}, {y}")
        return choices[0]

    def type_text(self, widget, text):
        self.assertIn("OnTextChanged", self.xml[widget.name])
        widget.SetText(widget, "")
        for i in range(1, len(text) + 1):
            widget.SetText(widget, text[:i])

    def field_for_label(self, label):
        choices = self.widgets("FontString", text=label)
        self.assertEqual(len(choices), 1, f"expected one visible label {label!r}")
        anchor = choices[0].anchor
        return self.field_at(anchor[4] + 100, anchor[5] - 2)

    def test_missing_or_under_three_seconds_uses_strict_id_and_boundary(self):
        trigger = self.trigger()
        for present, left, expected in ((False, None, True), (True, 10, False),
                                        (True, 3, False), (True, 2.999, True),
                                        (True, None, False), (True, 0, False)):
            with self.subTest(present=present, left=left):
                self.buffs(left, present=present)
                self.assertEqual(self.evaluate(trigger).show, expected)
        self.buffs(10, present=True, buff_id=500935)
        state = self.evaluate(trigger)
        self.assertTrue(state.show)  # Same localized name, wrong ID: 500934 is still missing.
        self.assertEqual(state.matchCount, 0)
        self.lua.globals().fixtureUnits.target = False
        self.assertFalse(self.evaluate(self.trigger(unit="target")).show)

    def test_buff_missing_option_roundtrips_canonical_schema(self):
        trigger = self.trigger(showOn="active", stacksOp=">", stacks=2)
        triggers = self.lua.globals().RWA.Triggers
        triggers.SetOptionType(trigger, "buffmissing")
        self.assertEqual((trigger.type, trigger.filter, trigger.showOn), ("aura", "HELPFUL", "missing"))
        self.assertIsNone(trigger.stacksOp)
        self.assertIsNone(trigger.stacks)
        self.assertEqual(triggers.GetOptionType(trigger), "buffmissing")
        triggers.SetOptionType(trigger, "aura")
        self.assertEqual((trigger.type, trigger.showOn), ("aura", "active"))
        triggers.SetOptionType(trigger, "status")
        self.assertEqual(triggers.GetOptionType(trigger), "status")

    def test_observed_buff_icon_survives_disappearance_and_trigger_reload(self):
        trigger = self.trigger()
        self.buffs(10, present=True)
        self.assertEqual(self.evaluate(trigger).icon, BUFF_ICON)
        cache = self.lua.globals().RWA_DB.buffInfo["500934"]
        self.assertEqual((cache.name, cache.icon), ("Fixture buff", BUFF_ICON))
        self.buffs()
        self.assertEqual(self.evaluate(trigger).icon, BUFF_ICON)
        self.load("Triggers.lua")  # Only the persisted cache survives a fresh module load.
        missing = self.evaluate(self.trigger())
        self.assertEqual((missing.name, missing.icon), ("Fixture buff", BUFF_ICON))

    def test_editor_drafts_deeply_isolate_revert_commit_and_rename(self):
        self.add_aura(elements=[{"type": "icon", "from": 1}], load={"class": "Mage"})
        self.lua.execute("""
            local saved = RWA.GetAura("Buff reminder")
            local draft = RWA.Editor.Get("Buff reminder")
            draft.sources[1].ids[1] = 500935
            draft.rules[1].name = "Edited"
            draft.load.class = "Rogue"
            assert(saved.sources[1].ids[1] == 500934 and saved.load.class == "Mage")
            draft = RWA.Editor.Revert("Buff reminder")
            assert(draft.sources[1].ids[1] == 500934 and draft.load.class == "Mage")
            draft.sources[1].ids[1] = 7
            RWA.Editor.names["Buff reminder"] = "Renamed reminder"
            committedId = RWA.Editor.Commit("Buff reminder")
            draft.sources[1].ids[1] = 99
        """)
        self.assertEqual(self.lua.globals().committedId, "Renamed reminder")
        self.assertIsNone(self.lua.globals().RWA_DB.auras["Buff reminder"])
        committed = self.lua.globals().RWA_DB.auras["Renamed reminder"]
        self.assertEqual(committed.sources[1].ids[1], 7)
        self.assertEqual(list(self.lua.globals().RWA_DB.order.values()), ["Renamed reminder"])

    def test_engine_uses_drafts_only_while_editing(self):
        self.add_aura()
        self.lua.execute('''
          local d=RWA.Editor.Get("Buff reminder")
          local p=RWA.Rules.PrepareActions(d)
          p.outputs[p.order[1]].definition.width=99
          RWA.LoadAura("Buff reminder")
        ''')
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].outputs[1].data.width, 48)
        self.lua.globals().RWA.SetEditMode(True)
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].outputs[1].data.width, 99)
        self.lua.globals().RWA.SetEditMode(False)
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].outputs[1].data.width, 48)
        self.assertEqual(self.lua.eval('(function() local p=RWA.Rules.PrepareActions(RWA.Editor.Get("Buff reminder")); return p.outputs[p.order[1]].definition.width end)()'), 99)

    def test_disabled_and_inactive_editor_preview_keeps_observed_icon(self):
        for enabled in (True, False):
            for region_type in ("icon", "aurabar"):
                with self.subTest(enabled=enabled, region_type=region_type):
                    name = f"Preview {enabled} {region_type}"
                    trigger = self.trigger(showOn="active")
                    self.buffs(10, present=True)
                    self.evaluate(trigger)
                    self.buffs()
                    self.add_aura(name, trigger=trigger, enabled=enabled, regionType=region_type, showIcon=True)
                    self.lua.globals().RWA.SetEditMode(True)
                    self.tick()
                    aura = self.lua.globals().RWA.loaded[name]
                    self.assertTrue(aura.region.shown)
                    self.assertFalse(aura.realActive)
                    self.assertEqual(aura.region.state.icon, BUFF_ICON)
                    self.assertEqual(aura.region.icon.texture, BUFF_ICON)

    def test_icon_picker_xml_wheel_selection_and_automatic_are_draft_only(self):
        saved = self.add_aura()
        self.lua.execute("""
            pickerChanges = 0;
            pickerContext = {get = function() return RWA.Editor.Get("Buff reminder"); end,
                changed = function() pickerChanges = pickerChanges + 1; end};
            RWA.IconPicker.Open(pickerContext);
        """)
        picker = self.lua.globals().RWA.IconPicker
        self.assertEqual((picker.columns, picker.rows, len(picker.cells)), (6, 5, 30))
        self.assertEqual(picker.cells[1].path, "Interface/Icons/Fixture1")
        self.script("RWA_IconPick1", "OnMouseWheel", delta=-1)
        self.assertEqual(picker.row, 1)
        self.assertEqual(picker.cells[1].path, "Interface/Icons/Fixture7")
        self.script("RWA_IconPick1", "OnClick")
        self.assertEqual(self.lua.globals().RWA.Editor.Get("Buff reminder").icon,
                         "Interface/Icons/Fixture7")
        self.assertIsNone(saved.icon)
        self.lua.globals().RWA.IconPicker.Open(self.lua.globals().pickerContext)
        self.script("RWA_IconPickAuto", "OnClick")
        self.assertIsNone(self.lua.globals().RWA.Editor.Get("Buff reminder").icon)
        self.assertEqual(self.lua.globals().pickerChanges, 2)
        self.assertFalse(picker.open)

    def test_icon_picker_optional_emi_categories_and_scroll_clamping(self):
        self.lua.execute("""
            CherrysEMI = {active = true,
                categories = {{name = "All", code = false}, {name = "Spells", code = "s"}},
                Count = function() return 2; end,
                IconNumber = function(category, n) return category * 100 + n; end,
                ExtendedTexture = function(n) return "Interface/Icons/EMI" .. n; end};
            pickerData = {};
            RWA.IconPicker.Open({get = function() return pickerData; end, changed = function() end});
        """)
        picker = self.lua.globals().RWA.IconPicker
        self.assertEqual(len(picker.categories), 2)
        self.script("RWA_IconPickCategory", "OnClick", key="LBUTTON")
        self.assertEqual(picker.cells[1].path, "Interface/Icons/EMI201")
        self.script("RWA_IconPick1", "OnMouseWheel", delta=-100)
        self.assertEqual(picker.row, 0)
        self.assertIsNone(picker.cells[3].path)
        self.assertFalse(picker.cells[3].button.visible)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_options_keystrokes_survive_load_and_trigger_switches_until_save(self):
        saved = self.add_aura()
        saved.triggers[2] = self.trigger(ids=[500935], showOn="active")
        self.options()
        self.type_text(self.field_for_label("Name or ID"), "500936")
        draft = self.lua.globals().RWA.Editor.Get("Buff reminder")
        self.assertEqual(draft.triggers[1].ids[1], 500936)
        self.assertEqual(saved.triggers[1].ids[1], 500934)
        self.click("Any time")  # Load/combat control: no Enter or focus-loss event.
        self.click_prefix("Only in combat")
        self.assertTrue(draft.load.combat)
        self.assertIsNone(saved.load.combat)
        self.click_prefix("1:")
        self.click_prefix("2:")
        self.assertEqual(self.field_for_label("Name or ID").text, "500935")
        self.type_text(self.field_for_label("Name or ID"), "500937")
        self.click_prefix("2:")
        self.click_prefix("1:")
        self.assertEqual(self.field_for_label("Name or ID").text, "500936")
        self.assertEqual(draft.triggers[2].ids[1], 500937)
        self.assertEqual(saved.triggers[2].ids[1], 500935)
        self.click("Save")
        committed = self.lua.globals().RWA.GetAura("Buff reminder")
        self.assertEqual((committed.triggers[1].ids[1], committed.triggers[2].ids[1]),
                         (500936, 500937))
        self.assertTrue(committed.load.combat)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_options_name_and_description_stay_in_drafts_until_save_or_revert(self):
        saved = self.add_aura(desc="Saved description")
        self.add_aura("Other aura")
        self.options()
        self.type_text(self.field_for_label("Name"), "Renamed in editor")
        self.type_text(self.field_for_label("Description"), "Draft description")
        self.lua.globals().RWA.ShowEditor("Other aura")
        self.open_legacy_editor("Buff reminder")
        self.assertEqual(self.field_for_label("Name").text, "Renamed in editor")
        self.assertEqual(self.field_for_label("Description").text, "Draft description")
        self.assertEqual(saved.desc, "Saved description")
        self.assertIsNone(self.lua.globals().RWA_DB.auras["Renamed in editor"])
        self.click("Revert")
        self.assertEqual(self.field_for_label("Name").text, "Buff reminder")
        self.assertEqual(self.field_for_label("Description").text, "Saved description")
        self.type_text(self.field_for_label("Name"), "Renamed in editor")
        self.click("Save")
        self.assertIsNone(self.lua.globals().RWA_DB.auras["Buff reminder"])
        self.assertEqual(self.lua.globals().RWA_DB.auras["Renamed in editor"].id,
                         "Renamed in editor")

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_options_icon_picker_updates_screen_and_editor_preview_before_save(self):
        saved = self.add_aura(enabled=False, trigger=self.trigger(showOn="active"),
                              previewIcon=BUFF_ICON)
        self.options()
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].region.icon.texture,
                         BUFF_ICON)
        self.assertTrue(any(w.kind == "Texture" and w.parent == "RWA_Preview_icon"
                            and w.texture == BUFF_ICON
                            for w in self.lua.globals().fixtureWidgets.values()))
        icon_button = self.button("Icon...")
        self.script(icon_button.name, "OnClick", key="LBUTTON")
        self.script(icon_button.name, "OnMouseWheel", delta=-1)
        self.assertEqual(self.lua.globals().RWA.IconPicker.row, 1)
        self.script("RWA_IconPick6", "OnClick")
        chosen = "Interface/Icons/Fixture12"
        self.assertEqual(self.lua.globals().RWA.Editor.Get("Buff reminder").icon, chosen)
        self.assertIsNone(saved.icon)
        self.tick()
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].region.icon.texture,
                         chosen)
        self.assertTrue(any(w.kind == "Texture" and w.parent == "RWA_Preview_icon"
                            and w.texture == chosen
                            for w in self.lua.globals().fixtureWidgets.values()))
        self.click("Save")
        self.assertEqual(self.lua.globals().RWA.GetAura("Buff reminder").icon, chosen)
        self.click("Icon...")
        self.script("RWA_IconPickAuto", "OnClick")
        self.assertIsNone(self.lua.globals().RWA.Editor.Get("Buff reminder").icon)
        self.assertEqual(self.lua.globals().RWA.GetAura("Buff reminder").icon, chosen)
        self.click("Revert")
        self.assertEqual(self.lua.globals().RWA.Editor.Get("Buff reminder").icon, chosen)

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_options_buff_missing_choice_saves_canonical_trigger(self):
        saved = self.add_aura()
        self.options()
        self.click("Buff / debuff")
        self.click_prefix("Buff missing")
        draft = self.lua.globals().RWA.Editor.Get("Buff reminder")
        self.assertEqual(draft.triggers[1].type, "aura")
        self.assertEqual(draft.triggers[1].filter, "HELPFUL")
        self.assertEqual(draft.triggers[1].showOn, "missing")
        self.assertEqual(saved.triggers[1].showOn, "missingOrExpiring")
        self.click("Save")
        committed = self.lua.globals().RWA.GetAura("Buff reminder").triggers[1]
        self.assertEqual((committed.type, committed.filter, committed.showOn),
                         ("aura", "HELPFUL", "missing"))

    @unittest.skip("Retired legacy editor; action-flow coverage is in test_rwa_flow_editor.py")
    def test_typing_a_new_buff_id_invalidates_the_live_draft_lookup(self):
        self.buffs(10, present=True)
        saved = self.add_aura(trigger=self.trigger(showOn="active", remainingOp=None, remaining=None))
        self.options()
        self.assertTrue(self.lua.globals().RWA.loaded["Buff reminder"].realActive)
        self.type_text(self.field_for_label("Name or ID"), "500935")
        self.tick()
        self.assertEqual(saved.triggers[1].ids[1], 500934)
        self.assertFalse(self.lua.globals().RWA.loaded["Buff reminder"].realActive,
                         "the live draft still matches the old ID after OnTextChanged")

    def test_icon_tooltip_xml_uses_named_button_when_this_is_missing(self):
        self.lua.execute("""
            RWA.IconPicker.Open({get = function() return {}; end, changed = function() end});
            GameTooltip = {
                SetOwner = function(self, owner)
                    assert(owner == RWA_IconPick1);
                    self.owner = owner;
                end,
                SetText = function(self, text) self.text = text; end,
                Show = function(self) self.shown = true; end,
            };
            this = nil;
        """)
        self.lua.execute(self.xml["RWA_IconPick1"]["OnEnter"])
        tooltip = self.lua.globals().GameTooltip
        self.assertTrue(tooltip.shown)
        self.assertEqual(tooltip.owner.name, "RWA_IconPick1")
        self.assertEqual(tooltip.text, "Interface/Icons/Fixture1")


if __name__ == "__main__":
    unittest.main()
