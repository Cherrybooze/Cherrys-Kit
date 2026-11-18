"""KittyCombo imaginary cooldowns (imaginaryCooldown condition), Lua 5.1.

    python -m unittest discover -s tests -p test_kitty_imaginary_cooldown.py -v

A row with "Imaginary cooldown (s)" fires at most once every N seconds,
counted from when Kitty fired it. The marks stay N seconds apart while the
presses keep coming (a fire up to 0.25 s late keeps the old mark), so the
row averages exactly one fire per N seconds instead of N plus the wait for
the next press. Prediction reads the marks and never moves them.
"""

import random
import unittest

import test_kitty_startup
from test_kitty_press_early import SETUP


class ImaginaryCooldownApiTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute(SETUP)

    def test_seconds_from_typed_values(self):
        self.lua.execute('''
          local seconds = Kitty.ImaginaryCooldown.seconds
          assert(seconds('') == 1 and seconds(nil) == 1 and seconds('soon') == 1)
          assert(seconds('0,5') == 0.5 and seconds('2.5') == 2.5 and seconds(4) == 4)
          assert(seconds('0') == 0.1 and seconds('-3') == 0.1 and seconds('99999') == 3600)
        ''')

    def test_marks_keep_the_beat_and_restart_after_a_long_gap(self):
        self.lua.execute('''
          local IC = Kitty.ImaginaryCooldown
          local key = 'test:beat'
          assert(IC.ready(key, 1, 10) and IC.remaining(key, 1, 10) == 0)
          IC.fired(key, 1, 10)
          assert(not IC.ready(key, 1, 10.5) and math.abs(IC.remaining(key, 1, 10.4) - 0.6) < 1e-9)
          assert(IC.ready(key, 1, 11))
          -- 0.2 s late: the next mark stays at 12, not 12.2
          IC.fired(key, 1, 11.2)
          assert(not IC.ready(key, 1, 11.99) and IC.ready(key, 1, 12))
          -- 0.3 s late is more than the 0.25 s catch-up: count from the fire
          IC.fired(key, 1, 12.3)
          assert(not IC.ready(key, 1, 13.2) and IC.ready(key, 1, 13.3))
          -- A short period catches up at most half of itself
          local short = 'test:short'
          IC.fired(short, 0.3, 20)
          IC.fired(short, 0.3, 20.44)     -- 0.14 s late of 20.3: mark 20.3
          assert(IC.ready(short, 0.3, 20.6) and not IC.ready(short, 0.3, 20.59))
          IC.fired(short, 0.3, 20.76)     -- 0.16 s late of 20.6: more than 0.15
          assert(not IC.ready(short, 0.3, 21.05) and IC.ready(short, 0.3, 21.06))
          -- A fire before the mark (an addon calling it early) counts from then
          IC.fired(short, 0.3, 21.0)
          assert(not IC.ready(short, 0.3, 21.29) and IC.ready(short, 0.3, 21.3))
          -- A new period applies at once to the next check
          assert(IC.ready(short, 0.1, 21.1))
          IC.reset(short)
          assert(IC.ready(short, 5, 21.01) and IC.remaining(short, 5, 21.01) == 0)
          -- nil keys are ignored
          IC.fired(nil, 1, 30); IC.reset(nil)
        ''')

    def test_rows_are_weak_keys_and_strings_stay(self):
        self.lua.execute('''
          local IC = Kitty.ImaginaryCooldown
          IC.state = setmetatable({}, {__mode = 'k'})
          ;(function()
            local command = {commandType = 'skill', commandName = 'Gone'}
            IC.fired(command, 1, 1)
            assert(next(IC.state) == command)
          end)()
          IC.fired('rwa:Fan of Knives', 5, 1)
          collectgarbage('collect'); collectgarbage('collect')
          local keys = {}
          for key in pairs(IC.state) do table.insert(keys, key) end
          assert(#keys == 1 and keys[1] == 'rwa:Fan of Knives', #keys)
        ''')

    def test_condition_reads_in_plain_words_and_never_blocks_by_itself(self):
        self.lua.execute('''
          assert(Kitty.ComboManager.imaginaryCooldown(nil, '1') == true)
          local help = Kitty.ComboManager.imaginaryCooldownHelp(nil, '')
          assert(string.find(help, '1', 1, true) and string.find(help, 'imaginary cooldown', 1, true), help)
          assert(string.find(Kitty.ComboManager.imaginaryCooldownHelp(nil, '2,5'), '2.5', 1, true))
          local lines = Kitty.ComboManager.imaginaryCooldownDescribe(nil, nil)
          assert(#lines == 3)
          assert(Kitty.ComboManager.getFormatType('imaginaryCooldown') == Kitty.ComboManager.TYPE_STRING)
          assert(Kitty.ComboManager.conditionLabel('imaginaryCooldown') == 'Imaginary cooldown (s)')
          assert(Kitty.ComboManager.conditionFromLabel('Imaginary cooldown (s)') == 'imaginaryCooldown')
          assert(Kitty.MenuHelp.conditions.imaginaryCooldown)
          local level1, level2 = Kitty.ComboManager.getConditionMenu()
          local found = false
          for index, group in ipairs(level1) do
            if group.value == 'skill / gear' then
              for _, entry in ipairs(level2[index]) do
                if entry.value == 'imaginaryCooldown' then found = true end
              end
              assert(#level2[index] <= 32)
            end
          end
          assert(found)
          assert(Kitty.ComboManager.createFunctionList().imaginaryCooldown)
          assert(Kitty.ComboManager.imaginaryCooldownSeconds({}) == nil)
          assert(Kitty.ComboManager.imaginaryCooldownSeconds({{conditionType = 'imaginaryCooldown', value = ''}}) == 1)
        ''')

    def test_share_code_keeps_the_condition(self):
        self.lua.execute('''
          local list = {info = {name = 'Every', class = 'any', target = 'all'},
            {commandType = 'skill', commandName = 'Fan of Knives', icon = '', enable = true,
              {conditionType = 'imaginaryCooldown', value = '5'}}}
          for _, code in ipairs({Kitty.Share.exportCommandListV1(list), Kitty.Share.exportCommandListV2(list),
              Kitty.Share.exportCommandList(list)}) do
            local imported = assert(Kitty.Share.importCommandList(code))
            assert(imported[1][1].conditionType == 'imaginaryCooldown' and imported[1][1].value == '5')
          end
        ''')


class ImaginaryCooldownEngineTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute(SETUP)
        self.lua.execute('''
          Kitty.ImaginaryCooldown.state = setmetatable({}, {__mode = 'k'})
          function every(name, seconds, ...)
            return row(name, {conditionType = 'imaginaryCooldown', value = seconds}, ...)
          end
          function count(name)
            local n = 0
            for _, sent in ipairs(sent) do if sent == name then n = n + 1 end end
            return n
          end
        ''')

    def test_row_fires_once_per_period_and_lower_rows_get_the_presses_between(self):
        self.lua.execute('''
          list = {info = {name = 'E'}, every('Fan of Knives', '1'), row('Other')}
          local t, n = press(list); assert(n == 'Fan of Knives')
          now = now + 0.2
          t, n = press(list); assert(n == 'Other')
          now = now + 0.79
          t, n = press(list); assert(n == 'Other')
          now = now + 0.01
          t, n = press(list); assert(n == 'Fan of Knives')
        ''')

    def test_presses_every_fifth_of_a_second_give_exactly_one_per_second(self):
        # With jitter in the presses, the row still fires once a second
        # (30 in 30 s); "not cast in the last 1 s" drifts by each wait.
        g = self.lua.globals()
        rng = random.Random(7)
        self.lua.execute('''
          beat = {info = {name = 'Beat'}, every('Chop', '1'), row('Other')}
          drift = {info = {name = 'Drift'},
            row('Chop', {conditionType = 'castRecently', {name = 'Chop', threshold = 1, value = false}}),
            row('Other')}
        ''')
        times = []
        t = 0.0
        while t < 30.0:
            times.append(t)
            t += 0.2 * rng.uniform(0.6, 1.0)
        for name in ("beat", "drift"):
            self.lua.execute('sent = {}; Kitty.lastCast = {}')
            for t in times:
                g.now = 1000 + t
                self.lua.eval('press(%s)' % name)
            chops = self.lua.eval('count("Chop")')
            if name == "beat":
                self.assertEqual(chops, 30)
            else:
                self.assertLess(chops, 30)

    def test_the_game_cooldown_and_other_conditions_still_decide(self):
        self.lua.execute('''
          Kitty.Modes = {}
          list = {info = {name = 'E'},
            every('Fan of Knives', '2', {conditionType = 'modeOn', {name = 'aoe', threshold = 0}}),
            row('Other')}
          -- The mode is off: the row is passed over and its time keeps running
          local t, n = press(list); assert(n == 'Other')
          Kitty.Modes.aoe = true
          cooldowns['Fan of Knives'] = 3
          now = now + 0.1
          t, n = press(list); assert(n == 'Other')   -- the skill itself is on cooldown
          cooldowns['Fan of Knives'] = 0
          t, n = press(list); assert(n == 'Fan of Knives')
          now = now + 1.9
          t, n = press(list); assert(n == 'Other')
          now = now + 0.1
          t, n = press(list); assert(n == 'Fan of Knives')
          -- A disabled row never fires
          list[1].enable = false
          now = now + 5
          t, n = press(list); assert(n == 'Other')
        ''')

    def test_procs_and_press_early_waits(self):
        self.lua.execute('''
          Kitty.SettingManager.setting = {command = {
            {info = {name = 'Inner', class = 'proc', target = 'all'}, every('Inner skill', '3'), row('Inner other')}}}
          local procRow = {commandType = 'proc', commandName = 'Inner', {conditionType = 'imaginaryCooldown', value = '1'}}
          local outer = {info = {name = 'Outer'}, procRow, row('Outer other')}
          local t, n = press(outer); assert(n == 'Inner skill')
          now = now + 0.5
          t, n = press(outer); assert(n == 'Outer other')      -- the proc row waits its 1 s
          now = now + 0.5
          t, n = press(outer); assert(n == 'Inner other')      -- the inner row waits its 3 s
          now = now + 2
          t, n = press(outer); assert(n == 'Inner skill')
          -- A "hold" from a press-early row inside a proc is not a fire
          Kitty.SettingManager.setting.command[1] = {info = {name = 'Inner', class = 'proc', target = 'all'},
            row('Chop', {conditionType = 'pressEarly', value = '0.75'})}
          Kitty.ImaginaryCooldown.state = setmetatable({}, {__mode = 'k'})
          Kitty.ComboManager.pressEarlyState = {}
          cooldowns['Chop'] = 0.5
          t, n = press(outer); assert(t == 'skill' and n == 'Chop')
          assert(Kitty.ImaginaryCooldown.state[procRow] ~= nil)
          Kitty.ImaginaryCooldown.state[procRow] = nil
          now = now + 0.05
          t, n = press(outer); assert(t == 'hold', tostring(t))
          assert(Kitty.ImaginaryCooldown.state[procRow] == nil)
        ''')

    def test_prediction_reads_the_marks_and_leaves_them_alone(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          Kitty.SettingManager.setting = {command = {{info = {name = 'P', class = 'any', target = 'all'},
            every('Fan of Knives', '2'), row('Other')}}}
          local list = Kitty.SettingManager.setting.command[1]
          for i = 1, 3 do
            Kitty.Predict.cache = {}
            local prediction = Kitty.Predict.next('P', 2)
            assert(prediction[1].name == 'Fan of Knives' and prediction[2].name == 'Other')
          end
          assert(next(Kitty.ImaginaryCooldown.state) == nil)
          press(list)
          Kitty.Predict.cache = {}
          now = now + 0.5
          local prediction = Kitty.Predict.next('P', 1)
          assert(prediction[1].name == 'Other')
          assert(#sent == 1)
        ''')

    def test_attack_macro_with_two_kitties(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          UnitCastingTime = function() return nil end
          Kitty.BuildManager.getClass = function() return 'Rogue', 'Scout', 'ROGUE', 'SCOUT' end
          Kitty.SettingManager.setting = {basic = {}, command = {
            {info = {name = 'Knives', class = 'any', target = 'all'}, every('Fan of Knives', '4')},
            {info = {name = 'Rest', class = 'any', target = 'all'}, row('Other')}}}
          Kitty.attack('Knives', 'Rest')
          now = now + 1
          Kitty.attack('Knives', 'Rest')
          now = now + 3
          Kitty.attack('Knives', 'Rest')
          assert(table.concat(sent, ',') == 'Fan of Knives,Other,Fan of Knives', table.concat(sent, ','))
        ''')


if __name__ == "__main__":
    unittest.main()
