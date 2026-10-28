"""Condition visibility/actions through real RWA Lua modules and the XML engine tick."""

import unittest

import test_rwa as harness


class ConditionTests(unittest.TestCase):
    # Reuse only the game/XML fixture helpers, without inheriting its test cases.
    setUp = harness.RWATests.setUp
    tearDown = harness.RWATests.tearDown
    load = harness.RWATests.load
    load_xml = harness.RWATests.load_xml
    table = harness.RWATests.table
    trigger = harness.RWATests.trigger
    buffs = harness.RWATests.buffs
    evaluate = harness.RWATests.evaluate
    add_aura = harness.RWATests.add_aura
    tick = harness.RWATests.tick
    script = harness.RWATests.script

    def condition(self, action="color", **changes):
        cond = self.lua.globals().RWA.Conditions.New(action)
        for key, value in changes.items():
            cond[key] = self.table(value) if isinstance(value, (dict, list)) else value
        return cond

    def reminder(self, name="Reminder", *, conditions=None, trigger=None, **changes):
        return self.add_aura(name, trigger=trigger or self.trigger(showOn="active"),
                             conditions=conditions or [self.condition()],
                             animation={"start": "none", "main": "none", "finish": "none"},
                             **changes)

    def aura(self, name="Reminder"):
        return self.lua.globals().RWA.loaded[name]

    def reconvert(self, name="Reminder"):
        self.lua.globals().testName = name
        self.lua.execute('''
          local legacy=RWA.GetAura(testName).previousDefinition
          RWA_DB.auras[testName]=RWA.ApplyAuraDefaults(assert(RWA.Rules.ConvertLegacy(legacy)))
          RWA.LoadAura(testName)
        ''')

    def capture_sounds(self):
        self.lua.execute("soundPaths = {}; PlaySoundByPath = function(path) table.insert(soundPaths, path); end;")

    def sounds(self):
        return list(self.lua.globals().soundPaths.values())

    def test_remaining_conditions_use_missing_or_strict_time_for_either_show_mode(self):
        for show_on in ("active", "missing"):
            name = "Rule " + show_on
            saved = self.reminder(name, trigger=self.trigger(showOn=show_on))
            for present, left, expected in ((False, None, True), (True, 10, False),
                                            (True, 3, False), (True, 2.999, True),
                                            (True, None, False), (True, 0, False)):
                with self.subTest(show_on=show_on, present=present, left=left):
                    self.buffs(left, present=present)
                    self.tick()
                    self.assertEqual(self.aura(name).realActive, expected)
                    self.assertEqual(self.aura(name).region.shown, expected)
            self.assertEqual(saved.previousDefinition.triggers[1].showOn, show_on)
            self.assertEqual(saved.previousDefinition.triggers[1].remaining, 3)

    def test_absent_target_and_stack_rejected_buff_are_not_missing(self):
        self.lua.globals().fixtureUnits.target = False
        self.reminder(trigger=self.trigger(unit="target", showOn="missing"))
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.lua.globals().fixtureUnits.target = True
        self.buffs(2, present=True, unit="target")
        data = self.lua.globals().RWA.GetAura("Reminder")
        data.previousDefinition.triggers[1].stacksOp, data.previousDefinition.triggers[1].stacks = ">", 5
        self.reconvert()
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.buffs(unit="target")
        self.tick()
        self.assertTrue(self.aura().realActive)

    def test_remaining_rows_are_independent_and_hide_wins(self):
        red = self.condition()
        grow = self.condition("grow", op=">=", value=8)
        grow.set.grow = 1.5
        data = self.reminder(conditions=[red, grow])
        self.buffs(10, present=True)
        self.tick()
        self.assertTrue(self.aura().realActive)
        self.assertEqual(self.aura().region.frame.scale, 1.5)
        self.assertEqual(self.aura().region.color[1], data.previousDefinition.color[1] if data.previousDefinition.color else 1)
        self.buffs(5, present=True)
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.buffs(2, present=True)
        self.tick()
        self.assertTrue(self.aura().realActive)
        self.assertEqual(self.aura().region.frame.scale, 1)
        self.assertEqual(self.aura().region.color[1], red.set.color[1])
        self.buffs()
        self.tick()
        self.assertTrue(self.aura().realActive)
        self.assertEqual(self.aura().region.frame.scale, 1.5)
        data.previousDefinition.conditions[3] = self.condition("hide")
        self.reconvert()
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.assertFalse(self.aura().region.shown)

    def test_visual_actions_restore_and_do_not_leak_through_region_pool(self):
        cond = self.condition(set={"color": [1, 0, 0, 1], "alpha": 0.6,
                                   "grow": 1.4, "blink": True, "overlayIcon": "exclamation-mark"})
        saved = self.reminder(conditions=[cond], alpha=0.8, color=[0, 1, 0, 1])
        self.buffs(2, present=True)
        self.tick(0)
        region = self.aura().region
        self.assertEqual(region.frame.scale, 1.4)
        self.assertEqual(region.color[1], 1)
        self.assertAlmostEqual(region.alpha, 0.6)
        self.assertTrue(region.conditionOverlay.visible)
        self.assertEqual(region.conditionOverlay.texture,
                         self.lua.globals().RWA.W.TexturePath("exclamation-mark"))
        self.tick(0.26)
        self.assertAlmostEqual(region.alpha, 0.15)
        self.buffs(10, present=True)
        self.tick()
        self.assertEqual(region.frame.scale, 1)
        self.assertEqual((region.color[1], region.color[2]), (0, 1))
        self.assertAlmostEqual(region.alpha, 0.8)
        self.assertFalse(region.conditionOverlay.visible)
        self.assertIsNone(region.conditionOverlay.texture)
        visual = self.lua.globals().RWA.Rules.PrepareActions(saved)
        definition = visual.outputs[visual.order[1]].definition
        self.assertEqual(definition.color[2], 1)
        self.assertEqual(definition.alpha, 0.8)
        self.lua.globals().RWA.UnloadAura("Reminder")
        self.add_aura("Pool reuse", trigger=self.table({"type": "custom", "code": "return true"}))
        self.tick()
        reused = self.aura("Pool reuse").region
        self.assertEqual(reused.frame.name, region.frame.name)
        self.assertEqual(reused.frame.scale, 1)
        self.assertFalse(reused.conditionOverlay.visible)

    def test_sound_fires_once_per_matching_edge_and_uses_existing_path_helper(self):
        self.capture_sounds()
        self.reminder(conditions=[self.condition("sound")])
        self.buffs(10, present=True)
        self.tick()
        self.assertEqual(self.sounds(), [])
        self.buffs(2, present=True)
        self.tick()
        self.assertEqual(self.sounds(), [self.lua.globals().RWA.SoundPath("AirHorn")])
        self.tick()
        self.buffs()
        self.tick()
        self.assertEqual(len(self.sounds()), 1)
        self.buffs(10, present=True)
        self.tick()
        self.buffs(2, present=True)
        self.tick()
        self.assertEqual(len(self.sounds()), 2)

    def test_sound_and_visibility_respect_other_triggers_load_and_disabled(self):
        self.capture_sounds()
        self.lua.execute("fixtureCombat = false; GetPlayerCombatState = function() return fixtureCombat; end;")
        self.reminder(conditions=[self.condition("sound")], load={"combat": True})
        self.buffs(2, present=True)
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.assertEqual(self.sounds(), [])
        self.lua.globals().fixtureCombat = True
        self.tick()
        self.assertTrue(self.aura().realActive)
        self.assertEqual(len(self.sounds()), 1)
        self.lua.execute('RWA.GetAura("Reminder").previousDefinition.triggers[2] = {type = "custom", code = "return false"}')
        self.reconvert()
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.assertEqual(len(self.sounds()), 1)
        self.reminder("Disabled", enabled=False, conditions=[self.condition("sound")])
        self.assertIsNone(self.aura("Disabled"))
        self.lua.globals().RWA.SetEditMode(True)
        self.tick()
        self.assertFalse(self.aura("Disabled").realActive)
        self.assertEqual(len(self.sounds()), 1)

    def test_editor_preview_never_plays_condition_or_aura_sound(self):
        self.capture_sounds()
        self.reminder(conditions=[self.condition("sound")], sound="AirHorn")
        self.buffs(2, present=True)
        self.lua.globals().RWA.SetEditMode(True)
        self.tick()
        self.tick()
        self.assertTrue(self.aura().region.shown)
        self.assertEqual(self.sounds(), [])

    def test_shared_visual_helper_applies_and_restores_the_separate_editor_region(self):
        self.reminder(conditions=[self.condition("grow")])
        self.buffs(2, present=True)
        self.tick()
        self.lua.execute('previewRegion = RWA.Regions.Acquire(RWA.CopyTable(RWA.loaded.Reminder.outputs[1].data));')
        region = self.lua.globals().previewRegion
        helper = self.lua.globals().RWA.ApplyConditionVisuals
        helper(region, self.aura().outputs[1].conditionEffects, self.lua.globals().fixtureNow)
        self.assertEqual(region.frame.scale, 1.25)
        self.buffs(10, present=True)
        self.tick()
        helper(region, self.aura().outputs[1].conditionEffects, self.lua.globals().fixtureNow)
        self.assertEqual(region.frame.scale, 1)

    def test_disabling_an_already_loaded_aura_does_not_bypass_the_gate(self):
        saved = self.reminder()
        self.buffs(2, present=True)
        self.tick()
        self.assertTrue(self.aura().realActive)
        saved.enabled = False
        self.tick()
        self.assertFalse(self.aura().realActive)
        self.assertFalse(self.aura().region.shown)

    def test_test_and_unlocked_preview_never_play_condition_or_aura_sound(self):
        self.capture_sounds()
        self.reminder(conditions=[self.condition("sound")], sound="AirHorn")
        self.buffs(2, present=True)
        self.lua.globals().RWA.TestAuras("Reminder")
        self.tick()
        self.assertEqual(self.sounds(), [])
        self.lua.globals().RWA.SetUnlocked(True)
        self.buffs(10, present=True)
        self.tick()
        self.buffs(2, present=True)
        self.tick()
        self.assertEqual(self.sounds(), [])

    def test_old_color_and_opacity_rules_still_restore_on_status_triggers(self):
        cond = self.table({"trigger": 1, "var": "percent", "op": "<", "value": 30,
                           "set": {"color": [1, 0, 0, 1], "alpha": 0.5}})
        self.reminder(trigger=self.table({"type": "status", "check": "health", "unit": "player"}),
                      conditions=[cond], color=[0, 1, 0, 1])
        self.tick()
        self.assertTrue(self.aura().realActive)
        self.assertEqual(self.aura().region.color[2], 1)
        self.lua.execute("UnitHealth = function() return 25; end;")
        self.tick()
        self.assertEqual(self.aura().region.color[1], 1)
        self.assertEqual(self.aura().region.alpha, 0.5)
        self.lua.execute("UnitHealth = function() return 75; end;")
        self.tick()
        self.assertEqual(self.aura().region.color[2], 1)
        self.assertEqual(self.aura().region.alpha, 1)

    def test_show_targets_only_its_trigger_and_explicit_hide_overrides_preview(self):
        show = self.condition("show", var="percent", op=">", value=50)
        data = self.reminder(trigger=self.table({"type": "status", "check": "health", "unit": "player",
                                                "op": "<", "value": 10}), conditions=[show])
        data.previousDefinition.triggers[2] = self.table({"type": "custom", "code": "return false"})
        self.reconvert()
        self.tick()
        self.assertFalse(self.aura().realActive)
        data = self.lua.globals().RWA.GetAura("Reminder")
        data.previousDefinition.triggers[2].code = "return true"
        self.reconvert()
        self.tick()
        self.assertTrue(self.aura().realActive)
        data = self.lua.globals().RWA.GetAura("Reminder")
        data.previousDefinition.conditions[2] = self.condition("hide", var="percent", op=">", value=50)
        self.reconvert()
        self.lua.globals().RWA.SetEditMode(True)
        self.tick()
        self.assertFalse(self.aura().realActive)
        # Move mode deliberately exposes output frames so they can be placed.
        self.assertTrue(self.aura().region.shown)

    def test_condition_action_helpers_choose_defaults_and_preserve_extensions(self):
        actions = self.lua.globals().RWA.Conditions
        for action in ("color", "hide", "show", "sound", "grow", "blink", "overlayIcon"):
            with self.subTest(action=action):
                rule = actions.New(action)
                self.assertEqual(actions.GetAction(rule), action)
                self.assertEqual((rule.trigger, rule.var, rule.op, rule.value), (1, "remaining", "<", 3))
        cond = self.condition()
        cond.set.extension = "preserved"
        actions.SetAction(cond, "grow")
        self.assertEqual(cond.set.grow, 1.25)
        self.assertIsNone(cond.set.color)
        self.assertEqual(cond.set.extension, "preserved")


if __name__ == "__main__":
    unittest.main()
