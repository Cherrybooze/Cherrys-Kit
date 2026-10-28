"""Database and builtin Kitty mode regressions using Lupa's Lua 5.1 runtime."""

from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


RWA_DIR = Path(__file__).resolve().parents[1] / "Interface" / "AddOns" / "CherrysKit" / "RomWeakAuras"


class ModeExampleTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.load("Init.lua")
        self.lua.execute(
            """
            RWA.On = function() end
            RWA.W, RWA.Regions = {}, {}
            function UnitBuff() error("Kitty modes must not scan game buffs") end
            function UnitDebuff() error("Kitty modes must not scan game debuffs") end
            """
        )
        self.load("Database.lua")
        self.load("Triggers.lua")
        self.load("Rules.lua")
        self.load("Engine.lua")
        self.lua.execute(
            """
            loadedIds = {}
            RWA.LoadAura = function(id) loadedIds[#loadedIds + 1] = id end
            RWA.InitDB()
            mode = RWA_DB.auras["KittyCombo mode"]
            """
        )

    def load(self, filename):
        source = RWA_DIR / filename
        self.lua.execute(source.read_text(encoding="utf-8-sig"), name=str(source))

    def legacy(self, extra=""):
        self.lua.execute(
            """
            -- Construct the historical saved shape for the legacy repair tests.
            local source = mode.sources[1]
            mode.triggers = { mode = "all", { type = "custom", code = source.code } }
            mode.conditions = {}
            mode.schemaVersion, mode.sources, mode.rules, mode.primarySourceId = nil, nil, nil, nil
            mode.elements[1].from = 1
            RWA_DB.settings.kittyModeSourceFixed = nil
            """ + extra
        )

    def evaluate(self):
        return self.lua.eval("RWA.Triggers.Evaluate((mode.sources or mode.triggers)[1], 100, {})")

    def test_builtin_custom_trigger_is_owned_by_main_and_icon_follows_it(self):
        self.assertEqual(self.lua.eval("mode.schemaVersion"), 2)
        self.assertEqual(self.lua.eval("#mode.sources"), 1)
        self.assertEqual(self.lua.eval("mode.sources[1].type"), "custom")
        self.assertEqual(self.lua.eval("mode.primarySourceId"), "s1")
        self.assertIsNone(self.lua.eval("mode.elements[1].sourceId"))
        self.assertEqual(self.lua.eval("mode.rules[1].when.checks[1].field"), "active")
        self.assertTrue(self.lua.eval("mode.load.combat"))
        self.assertFalse(self.lua.eval("mode.enabled"))

    def test_original_custom_code_reads_live_kitty_mode_and_icon(self):
        self.lua.execute(
            """
            activeMode = "aoe"
            Kitty = { ModeUI = {
                current = function() return activeMode end,
                iconPath = function(name)
                    return "gfx/modes/" .. (name == "" and "none" or name) .. ".tga"
                end,
            } }
            """
        )
        state = self.evaluate()
        self.assertTrue(state.show)
        self.assertEqual(state.name, "Mode: aoe")
        self.assertEqual(state.icon, "gfx/modes/aoe.tga")
        self.lua.execute('activeMode = "single"')
        state = self.evaluate()
        self.assertEqual(state.name, "Mode: single")
        self.assertEqual(state.icon, "gfx/modes/single.tga")
        self.lua.execute("activeMode = nil")
        state = self.evaluate()
        self.assertTrue(state.show)
        self.assertEqual(state.name, "Mode: none")
        self.assertEqual(state.icon, "gfx/modes/none.tga")

    def test_mode_hides_without_kitty_or_its_mode_api(self):
        self.assertFalse(self.evaluate().show)
        self.lua.execute("Kitty = {}")
        self.assertFalse(self.evaluate().show)
        self.lua.execute("Kitty.ModeUI = {}")
        self.assertFalse(self.evaluate().show)
        self.lua.execute('Kitty.ModeUI.current = function() return "boss" end')
        state = self.evaluate()
        self.assertTrue(state.show)
        self.assertEqual(state.name, "Mode: boss")
        self.assertIsNone(state.icon)

    def test_untouched_legacy_builtin_source_is_repaired_once(self):
        self.legacy("originalCode = mode.triggers[1].code")
        self.lua.execute("RWA.InitDB()")
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 0)
        self.assertEqual(self.lua.eval("#mode.triggers"), 1)
        self.assertTrue(self.lua.eval("mode.triggers[1].code == originalCode"))
        self.assertFalse(self.lua.eval("mode.enabled"))
        self.assertTrue(self.lua.eval("RWA_DB.settings.kittyModeSourceFixed"))
        self.lua.execute("RWA.InitDB()")
        self.assertEqual(self.lua.eval("#mode.triggers"), 1)

    def test_generated_blank_trigger_is_removed_without_resetting_custom_appearance(self):
        self.legacy(
            """
            table.insert(mode.triggers, {
                type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active",
            })
            mode.enabled, mode.x, mode.fontSize = true, 123, 26
            mode.elements[1].size, mode.elements[1].x = 50, -12
            originalTrigger, originalIcon = mode.triggers[1], mode.elements[1]
            originalCount = #RWA_DB.order
            RWA.InitDB()
            """
        )
        self.assertEqual(self.lua.eval("#mode.triggers"), 1)
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 0)
        self.assertTrue(self.lua.eval("mode.triggers[1] == originalTrigger"))
        self.assertTrue(self.lua.eval("mode.elements[1] == originalIcon"))
        self.assertTrue(self.lua.eval("mode.enabled"))
        self.assertEqual(self.lua.eval("mode.x"), 123)
        self.assertEqual(self.lua.eval("mode.fontSize"), 26)
        self.assertEqual(self.lua.eval("mode.elements[1].size"), 50)
        self.assertEqual(self.lua.eval("mode.elements[1].x"), -12)
        self.assertTrue(self.lua.eval("#RWA_DB.order == originalCount"))

    def test_named_buff_is_preserved_and_not_reinterpreted_as_mode(self):
        self.legacy(
            """
            table.insert(mode.triggers, {
                type = "aura", unit = "player", filter = "HELPFUL",
                names = { "Battle Blessing" }, showOn = "active",
            })
            RWA.InitDB()
            """
        )
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 1)
        self.assertEqual(self.lua.eval("#mode.triggers"), 2)
        self.assertEqual(self.lua.eval("mode.triggers[2].names[1]"), "Battle Blessing")

    def test_custom_code_and_meaningful_blank_trigger_options_are_preserved(self):
        cases = [
            'mode.triggers[1].code = "return true, { name = \'My mode\' }"',
            'mode.triggers[2].unit = "target"',
            'mode.triggers[2].filter = "HARMFUL"',
            'mode.triggers[2].showOn = "missing"',
            'mode.triggers[2].remainingOp = "<"; mode.triggers[2].remaining = 3',
            'mode.triggers[2].names = { "" }',
            'mode.triggers.mode = "any"',
            'mode.conditions = { { trigger = 2, var = "show", op = "==", value = 1 } }',
            'mode.elements[1].kittyPick = 2',
            'table.insert(mode.triggers, { type = "status", check = "combat" })',
        ]
        for setup in cases:
            with self.subTest(setup=setup):
                self.setUp()
                self.legacy(
                    """
                    table.insert(mode.triggers, {
                        type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active",
                    })
                    """ + setup
                )
                count = self.lua.eval("#mode.triggers")
                code = self.lua.eval("mode.triggers[1].code")
                self.lua.execute("RWA.InitDB()")
                self.assertEqual(self.lua.eval("mode.elements[1].from"), 1)
                self.assertEqual(self.lua.eval("#mode.triggers"), count)
                self.assertEqual(self.lua.eval("mode.triggers[1].code"), code)

    def test_conditions_using_the_retained_mode_trigger_are_preserved(self):
        self.legacy(
            """
            mode.conditions = { { trigger = 1, var = "show", op = "==", value = 1,
                set = { alpha = 0.5 } } }
            RWA.InitDB()
            """
        )
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 0)
        self.assertEqual(self.lua.eval("mode.conditions[1].trigger"), 1)
        self.assertEqual(self.lua.eval("mode.conditions[1].set.alpha"), 0.5)

    def test_migration_does_not_recreate_deleted_or_renamed_example(self):
        self.legacy(
            """
            RWA_DB.auras["My mode"] = mode
            RWA_DB.auras["KittyCombo mode"] = nil
            RWA.InitDB()
            """
        )
        self.assertIsNone(self.lua.eval('RWA_DB.auras["KittyCombo mode"]'))
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 1)

    def test_migration_never_removes_new_user_changes_after_first_run(self):
        self.legacy("RWA.InitDB()")
        self.lua.execute(
            """
            mode.elements[1].from = 1
            table.insert(mode.triggers, {
                type = "aura", unit = "player", filter = "HELPFUL", names = {}, showOn = "active",
            })
            RWA.InitDB()
            """
        )
        self.assertEqual(self.lua.eval("mode.elements[1].from"), 1)
        self.assertEqual(self.lua.eval("#mode.triggers"), 2)

    def test_new_auras_start_with_an_incomplete_check_and_selected_output(self):
        for region in ("icon", "text", "aurabar", "texture"):
            with self.subTest(region=region):
                aura_id = self.lua.globals().RWA.NewAura(region)
                data = self.lua.globals().RWA.GetAura(aura_id)
                self.assertTrue(data.enabled)
                self.assertEqual(data.schemaVersion, 3)
                check = data.rules[1].when.checks[1]
                self.assertIsNone(check.field)
                self.assertEqual(data.rules[1].actions[1].output.regionType, region)
        self.assertEqual(self.lua.eval("#loadedIds"), 4)

    def test_copy_of_disabled_example_starts_enabled_and_keeps_original_disabled(self):
        aura_id = self.lua.globals().RWA.DuplicateAura("Example: buff on me")
        data = self.lua.globals().RWA.GetAura(aura_id)
        self.assertTrue(data.enabled)
        self.assertFalse(self.lua.eval('RWA_DB.auras["Example: buff on me"].enabled'))
        self.assertIsNone(data.sources[1].names[1])
        self.assertEqual(data.rules[1].when.checks[1].field, "missing")
        self.assertEqual((data.x, data.y), (260, -40))
        self.assertEqual(self.lua.eval('RWA_DB.auras["Example: buff on me"].y'), -70)
        data.sources[1].names[1] = "My buff"
        self.assertIsNone(self.lua.eval('RWA_DB.auras["Example: buff on me"].sources[1].names[1]'))

    def test_existing_saved_and_builtin_disabled_flags_remain_disabled(self):
        self.lua.execute(
            """
            RWA_DB.auras["My saved aura"] = { enabled = false, triggers = {} }
            RWA.InitDB()
            """
        )
        self.assertFalse(self.lua.eval('RWA_DB.auras["My saved aura"].enabled'))
        self.assertFalse(self.lua.eval('RWA_DB.auras["Class icon"].enabled'))
        self.assertFalse(self.lua.eval('RWA_DB.auras["KittyCombo mode"].enabled'))
        self.assertFalse(self.lua.eval('RWA_DB.auras["Example: debuff on target"].enabled'))


if __name__ == "__main__":
    unittest.main()
