"""KittyCombo dispatch, action eligibility and resource regressions (Lua 5.1).

    python -m unittest discover -s tests -p test_kitty_dispatch.py -v
"""

import unittest

import test_kitty_startup


class KittyDispatchTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()

    def test_execution_tolerance_and_priority_walk(self):
        # A skill outside the dispatch window falls through to a usable lower
        # priority command; the tolerance is passed explicitly at dispatch and
        # a cast in progress does not hide skills (no blanket casting guard).
        self.lua.execute('''
          Kitty.sendMessage = function() end
          local stub = {};
          local calls = {};
          stub.canCast = function(self, name, threshold)
            table.insert(calls, {name = name, threshold = threshold});
            return name == 'Ready';
          end
          local list = {{info = {name = 'T'}},
            {commandType = 'skill', commandName = 'Slow'},
            {commandType = 'skill', commandName = 'Ready'}};
          local manager = Kitty.ComboManager({}, Kitty.CooldownManager(), {});
          manager.skillManager = stub;
          UnitCastingTime = function() return 3 end;
          local commandType, commandName = manager:check(list);
          assert(commandType == 'skill' and commandName == 'Ready');
          assert(#calls == 2);
          assert(calls[1].name == 'Slow' and calls[1].threshold == 0.2);
          assert(calls[2].name == 'Ready' and calls[2].threshold == 0.2);
          assert(Kitty.SkillManager.EXECUTION_TOLERANCE == 0.2);
        ''')
        # Real cooldown reads: dispatch uses the tolerance, while the
        # user-threshold "canCast" condition and the 0.6 default keep meaning.
        self.lua.execute('''
          Kitty.sendMessage = function() end
          Kitty.SkillManager.fetchSkill = function(name)
            if name == 'Slow' then
              return {isAvailable = true, isSuitSkill = false, remaining = 0.5, texture = 'icon'};
            end
            return {isAvailable = true, isSuitSkill = false, remaining = 0, texture = 'icon'};
          end
          local manager = Kitty.ComboManager({}, Kitty.CooldownManager(), {});
          assert(manager:check({{commandType = 'skill', commandName = 'Slow'}}) == nil);
          assert(not manager:canCast({{name = 'Slow', threshold = 0}}));
          assert(manager:canCast({{name = 'Slow', threshold = 1}}));
          local ready = manager:check({{commandType = 'skill', commandName = 'Fast'}});
          assert(ready == 'skill');
        ''')

    def test_prediction_lookahead_and_read_only(self):
        # Execution uses the 0.2 window; prediction keeps its 1.1 lookahead and
        # never changes live cooldown state.
        self.lua.execute('''
          Kitty.sendMessage = function() end
          Kitty.isTurnedOff = function() return false end
          now = 20; Kitty.getTime = function() return now end
          Kitty.SkillManager.fetchSkill = function(name)
            return {isAvailable = true, isSuitSkill = false, remaining = 1.0, texture = 'icon'};
          end
          Kitty.SettingManager.setting = {command = {{info = {name = 'Pred', class = 'any', target = 'all'},
            {commandType = 'skill', commandName = 'SlowReady'}}}};
          Kitty.slotManager = {}; Kitty.macroManager = {}; Kitty.cooldownManager = Kitty.CooldownManager();
          local prediction = Kitty.Predict.next('Pred', 1);
          assert(prediction[1] and prediction[1].name == 'SlowReady');
          local manager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager);
          assert(manager:check(Kitty.SettingManager.setting.command[1]) == nil);
          local after = Kitty.Predict.next('Pred', 1);
          assert(after[1] and after[1].name == 'SlowReady');
          assert(Kitty.cooldownManager.skillTable.SlowReady == nil);
        ''')

    def test_action_dispatch_eligibility(self):
        self.lua.execute('''
          Kitty.sendMessage = function() end
          Kitty.debugPrint = function() end
          local slots = setmetatable({slotTable = {Potion = 7}},
            {__index = Kitty.SlotManager});
          GetActionCooldown = function() return 0, 0 end;
          GetActionUsable = function() return true end;
          GetActionInfo = function() return 'icon', '', 3, false, false end;
          assert(slots:canDispatch('Potion'));
          assert(not slots:canDispatch('Unknown'));
          GetActionInfo = function() end;
          assert(not slots:canDispatch('Potion'));
          GetActionInfo = function() return 'icon', '', 3, false, false end;
          GetActionUsable = function() return false end;
          assert(not slots:canDispatch('Potion'));
          assert(slots:canUse('Potion'));
          GetActionUsable = function() return true end;
          GetActionInfo = function() return 'icon', '', 0, false, false end;
          assert(not slots:canDispatch('Potion'));
          GetActionInfo = function() return 'icon', '', 0, false, true end;
          assert(slots:canDispatch('Potion'));
          GetActionInfo = function() return 'icon', '', 1, false, false end;
          GetActionUsable = nil;
          assert(slots:canDispatch('Potion'));
          GetActionUsable = function() return true end;
          GetActionCooldown = function() return 0, 0.5 end;
          assert(not slots:canDispatch('Potion'));
        ''')
        # Engine level: an unusable action does not win; a valid action does.
        self.lua.execute('''
          Kitty.sendMessage = function() end
          Kitty.debugPrint = function() end
          local slots = setmetatable({slotTable = {Potion = 7}},
            {__index = Kitty.SlotManager});
          GetActionCooldown = function() return 0, 0 end;
          GetActionInfo = function() return 'icon', '', 0, false, false end;
          GetActionUsable = function() return false end;
          local manager = Kitty.ComboManager(slots, Kitty.CooldownManager(), {});
          manager.skillManager = {canCast = function() return true end};
          local commandType, commandName = manager:check({
            {commandType = 'action', commandName = 'Potion'},
            {commandType = 'skill', commandName = 'Ready'}});
          assert(commandType == 'skill' and commandName == 'Ready');
          GetActionInfo = function() return 'icon', '', 3, false, false end;
          GetActionUsable = function() return true end;
          local actionType, actionName = manager:check({
            {commandType = 'action', commandName = 'Potion'},
            {commandType = 'skill', commandName = 'Ready'}});
          assert(actionType == 'action' and actionName == 'Potion');
        ''')

    def test_missing_and_zero_mana(self):
        self.lua.execute('''
          UnitName = function() return 'Tester' end;
          UnitManaType = function() return 0 end;
          UnitSkillType = function() return 0 end;
          assert(Kitty.ClassManager.getMana('player') == nil);
          assert(Kitty.ClassManager.hasManaByRate('player', 0, 20) == false);
          assert(Kitty.ClassManager.hasMana('player', 0, 100) == false);
          local condition = setmetatable({}, {__index = Kitty.ComboManager});
          assert(condition:playerMana(0, 20) == false);
          UnitManaType = function() return 1 end;
          UnitMana = function() return 0 end;
          UnitMaxMana = function() return 100 end;
          assert(Kitty.ClassManager.hasManaByRate('player', 0, 20) == true);
          assert(Kitty.ClassManager.hasMana('player', 0, 0) == true);
          assert(condition:playerMana(0, 20) == true);
          UnitMaxMana = function() return 0 end;
          assert(Kitty.ClassManager.hasManaByRate('player', 0, 20) == false);
          UnitManaType = function() return 0 end;
          UnitSkillType = function() return 1 end;
          UnitSkill = function() return 40 end;
          UnitMaxSkill = function() return 80 end;
          assert(Kitty.ClassManager.hasManaByRate('player', 40, 60) == true);
        ''')
        # A mana-cost skill with no mana resource fails cleanly, and still
        # works with real mana values.
        self.lua.execute('''
          Kitty.SkillManager.fetchSkill = function(name)
            return {isAvailable = true, isSuitSkill = false, remaining = 0, texture = 'icon'};
          end
          Kitty.SkillManager.manaList.Manapotion = 50;
          local manager = Kitty.ComboManager({}, Kitty.CooldownManager(), {});
          UnitManaType = function() return 0 end;
          UnitSkillType = function() return 0 end;
          assert(not manager.skillManager:canCast('Manapotion', 0.2));
          UnitManaType = function() return 1 end;
          UnitMana = function() return 500 end;
          UnitMaxMana = function() return 1000 end;
          assert(manager.skillManager:canCast('Manapotion', 0.2));
          Kitty.SkillManager.manaList.Manapotion = nil;
        ''')

    def test_in_range_single_read_and_warning_limit(self):
        self.lua.execute('''
          Kitty.sendMessage = function() end
          now = 100; Kitty.getTime = function() return now end
          local warnings = 0;
          SendWarningMsg = function() warnings = warnings + 1 end;
          local calls = 0;
          local probe = setmetatable({slotManager = {inRange = function() calls = calls + 1; return nil end}},
            {__index = Kitty.ComboManager});
          assert(probe:inRange('Probe') == false);
          assert(calls == 1);
          assert(warnings == 1);
          assert(probe:inRange('Probe') == false);
          assert(warnings == 1);
          now = 111;
          assert(probe:inRange('Probe') == false);
          assert(warnings == 2);
          local sequence = {true, false};
          local reads = 0;
          local range = setmetatable({slotManager = {inRange = function()
            reads = reads + 1; return sequence[reads];
          end}}, {__index = Kitty.ComboManager});
          assert(range:inRange('Probe') == true and reads == 1);
        ''')

    def test_attempt_suppression_unchanged(self):
        self.lua.execute('''
          kittyNow = 101; Kitty.getTime = function() return kittyNow end;
          GetTime = function() return kittyNow end;
          Kitty.lastCast = {Demo = 100};
          local manager = setmetatable({}, {__index = Kitty.ComboManager});
          assert(Kitty.ComboManager.castWithin('Demo', 5) == true);
          assert(Kitty.ComboManager.castWithin('Other', 5) == false);
          assert(manager:castRecently({{name = 'Demo', threshold = 5}}) == true);
          assert(manager:castRecently({{name = 'Demo', threshold = 5, value = false}}) == false);
          kittyNow = 107;
          assert(Kitty.ComboManager.castWithin('Demo', 5) == false);
        ''')

    def test_imported_range_condition_without_a_name_fails_without_error_or_probe(self):
        self.lua.execute('''
          local reads, warnings, errors = 0, 0, 0
          SendWarningMsg = function() warnings = warnings + 1 end
          Kitty.sendMessage = function() errors = errors + 1 end
          local manager = setmetatable({slotManager={inRange=function()
            reads = reads + 1
          end}}, {__index=Kitty.ComboManager})
          for _=1,30 do
            assert(manager:inRange(nil) == false)
            assert(manager:inRange("") == false)
            assert(manager:inRange("  ") == false)
            assert(manager:inRange(false) == false)
            assert(manager:checkCondition({{conditionType="inRange"}}) == false)
          end
          assert(reads == 0 and warnings == 0 and errors == 0)
        ''')

    def test_execution_window_can_still_be_toggled_for_an_ab_comparison(self):
        self.lua.execute('''
          Kitty.SkillManager.fetchSkill = function()
            return {isAvailable=true,isSuitSkill=false,remaining=0.5,texture="icon"}
          end
          local manager = Kitty.ComboManager({}, Kitty.CooldownManager(), {})
          local commands = {{commandType="skill",commandName="Compare"}}
          assert(manager:check(commands) == nil)
          Kitty.SkillManager.EXECUTION_TOLERANCE = 0.6
          assert(manager:check(commands) == "skill")
          Kitty.SkillManager.EXECUTION_TOLERANCE = 0.2
          assert(manager:check(commands) == nil)
        ''')


if __name__ == "__main__":
    unittest.main()
