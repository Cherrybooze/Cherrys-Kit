"""KittyCombo "Press early" rows (pressEarly condition), Lua 5.1.

    python -m unittest discover -s tests -p test_kitty_press_early.py -v

The timing model at the end follows the client and server source
(cherrybooze/oneforall): the server lowers whole-second cooldown counters on
each character's one-second tick and refuses a cast while the global cooldown
or the skill's own counter is above 0; the client starts its 0.1 s countdown
when the cast report arrives, and stops sending casts until 0.99 s after the
last send once more than four went out without a finished spell.
"""

import heapq
import itertools
import random
import unittest

import test_kitty_startup


SETUP = '''
  Kitty.sendMessage = function() end
  Kitty.debugPrint = function() end
  now = 100
  Kitty.getTime = function() return now end
  GetTime = function() return now end
  cooldowns = {}
  Kitty.SkillManager.fetchSkill = function(name)
    return {isAvailable = true, isSuitSkill = false, remaining = cooldowns[name] or 0, texture = 'icon'}
  end
  sent = {}
  CastSpellByName = function(name) table.insert(sent, name) end
  Kitty.slotManager = {}; Kitty.macroManager = {}; Kitty.cooldownManager = Kitty.CooldownManager()
  Kitty.ComboManager.pressEarlyState = {}
  function press(list)
    local manager = Kitty.ComboManager(Kitty.slotManager, Kitty.cooldownManager, Kitty.macroManager)
    local commandType, commandName = manager:check(list)
    manager:cast(commandType, commandName)
    return commandType, commandName
  end
  function row(name, ...)
    local command = {commandType = 'skill', commandName = name}
    for _, condition in ipairs({...}) do table.insert(command, condition) end
    return command
  end
'''


class KittyPressEarlyTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute(SETUP)

    def test_row_fires_early_waits_for_its_skill_and_paces_its_sends(self):
        self.lua.execute('''
          list = {info = {name = 'CC'},
            row('Charged Chop', {conditionType = 'pressEarly', value = '0.75'}),
            row('Other')}
          -- Outside the window the next row fires, as before
          cooldowns['Charged Chop'] = 0.9
          local t, n = press(list); assert(t == 'skill' and n == 'Other', tostring(n))
          -- Inside it the skill goes out early...
          cooldowns['Charged Chop'] = 0.7
          t, n = press(list); assert(t == 'skill' and n == 'Charged Chop')
          -- ...and a press too soon after that sends nothing, not the lower row
          now = now + 0.05; cooldowns['Charged Chop'] = 0.65
          t, n = press(list); assert(t == 'hold' and n == 'Charged Chop', tostring(t))
          -- 0.75 / 4 = 0.1875 s apart, at most 4 early sends per cooldown
          local early = 1
          for i = 1, 6 do
            now = now + 0.19; cooldowns['Charged Chop'] = math.max(0.7 - 0.19 * i, 0.01)
            t, n = press(list)
            if t == 'skill' then early = early + 1 else assert(t == 'hold') end
          end
          assert(early == 4, early)
          -- Shown ready: it goes out again (the gap still applies)
          cooldowns['Charged Chop'] = 0
          t, n = press(list); assert(t == 'skill' and n == 'Charged Chop')
          t, n = press(list); assert(t == 'hold')
          now = now + 0.2
          t, n = press(list); assert(t == 'skill' and n == 'Charged Chop')
          -- It went off: its cooldown is back up, the lower row gets the press,
          -- and the next window counts its early sends from 0 again
          now = now + 0.2; cooldowns['Charged Chop'] = 1.0
          t, n = press(list); assert(n == 'Other')
          for i = 1, 4 do
            now = now + 0.2; cooldowns['Charged Chop'] = 0.8 - 0.19 * i
            t, n = press(list); assert(t == 'skill' and n == 'Charged Chop', i)
          end
          local casts = 0
          for _, name in ipairs(sent) do if name == 'Charged Chop' then casts = casts + 1 end end
          assert(casts == 10, casts)
          assert(sent[1] == 'Other')
        ''')

    def test_value_window_and_other_rows_unchanged(self):
        self.lua.execute('''
          local seconds = Kitty.ComboManager.pressEarlySeconds
          assert(seconds('') == 0.75 and seconds(nil) == 0.75 and seconds('soon') == 0.75)
          assert(seconds('0,5') == 0.5 and seconds('0.3') == 0.3 and seconds(0.4) == 0.4)
          assert(seconds('5') == 2 and seconds('-1') == 0)
          assert(Kitty.ComboManager.pressEarlyWindow(row('A')) == nil)
          assert(Kitty.ComboManager.pressEarlyWindow(row('A', {conditionType = 'pressEarly', value = '0.4'})) == 0.4)
          -- The row's window replaces the 0.2 s dispatch window for that row only
          local calls = {}
          local manager = Kitty.ComboManager({}, Kitty.CooldownManager(), {})
          manager.skillManager = {canCast = function(self, name, threshold)
            calls[name] = threshold; return false end}
          manager:check({row('Early', {conditionType = 'pressEarly', value = ''}), row('Plain')})
          assert(calls.Early == 0.75 and calls.Plain == 0.2)
          -- The condition itself never blocks a row, and reads in plain words
          assert(Kitty.ComboManager.pressEarly(nil, '0.75') == true)
          assert(string.find(Kitty.ComboManager.pressEarlyHelp(nil, ''), '0.75', 1, true))
          assert(Kitty.ComboManager.getFormatType('pressEarly') == Kitty.ComboManager.TYPE_STRING)
          assert(Kitty.ComboManager.conditionLabel('pressEarly') == 'Press early (s)')
          local level1, level2 = Kitty.ComboManager.getConditionMenu()
          local found = false
          for index, group in ipairs(level1) do
            if group.value == 'skill / gear' then
              for _, entry in ipairs(level2[index]) do
                if entry.value == 'pressEarly' then found = true end
              end
            end
          end
          assert(found)
          assert(Kitty.MenuHelp.conditions.pressEarly)
        ''')

    def test_other_conditions_still_decide_and_procs_pass_the_wait_up(self):
        self.lua.execute('''
          Kitty.Modes = {}
          cooldowns['Charged Chop'] = 0.5
          local guarded = {info = {name = 'G'},
            row('Charged Chop', {conditionType = 'pressEarly', value = '0.75'},
              {conditionType = 'modeOn', {name = 'single', threshold = 0}}),
            row('Other')}
          local t, n = press(guarded); assert(n == 'Other')
          Kitty.Modes.single = true
          t, n = press(guarded); assert(n == 'Charged Chop')
          now = now + 0.05
          t, n = press(guarded); assert(t == 'hold')
          -- Inside a proc the wait stops the outer kitty too
          Kitty.SettingManager.setting = {command = {
            {info = {name = 'Inner', class = 'proc', target = 'all'},
              row('Charged Chop', {conditionType = 'pressEarly', value = '0.75'})}}}
          local outer = {info = {name = 'Outer'},
            {commandType = 'proc', commandName = 'Inner'}, row('Other')}
          now = now + 0.05
          t, n = press(outer); assert(t == 'hold', tostring(t))
        ''')

    def test_prediction_shows_the_skill_and_leaves_the_count_alone(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          cooldowns['Charged Chop'] = 0.5
          Kitty.SettingManager.setting = {command = {{info = {name = 'P', class = 'any', target = 'all'},
            row('Charged Chop', {conditionType = 'pressEarly', value = '0.75'}), row('Other')}}}
          for i = 1, 3 do
            Kitty.Predict.cache = {}
            local prediction = Kitty.Predict.next('P', 2)
            assert(prediction[1].name == 'Charged Chop' and prediction[2].name == 'Other')
          end
          assert(next(Kitty.ComboManager.pressEarlyState) == nil)
          assert(#sent == 0)
        ''')

    def test_attack_macro_sends_nothing_while_waiting(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          UnitCastingTime = function() return nil end
          Kitty.BuildManager.getClass = function() return 'Warrior', 'Warden', 'WARRIOR', 'WARDEN' end
          Kitty.SettingManager.setting = {basic = {}, command = {
            {info = {name = 'Chop', class = 'any', target = 'all'},
              row('Charged Chop', {conditionType = 'pressEarly', value = '0.75'})},
            {info = {name = 'Rest', class = 'any', target = 'all'}, row('Other')}}}
          cooldowns['Charged Chop'] = 0.6
          Kitty.attack('Chop', 'Rest')
          now = now + 0.05
          Kitty.attack('Chop', 'Rest')
          assert(#sent == 1 and sent[1] == 'Charged Chop', table.concat(sent, ','))
          cooldowns['Charged Chop'] = 1.0
          now = now + 0.05
          Kitty.attack('Chop', 'Rest')
          assert(#sent == 2 and sent[2] == 'Other')
        ''')

    def test_share_code_keeps_the_condition(self):
        self.lua.execute('''
          local list = {info = {name = 'WWd_001', class = 'WWd', target = 'all'},
            {commandType = 'skill', commandName = 'Charged Chop', icon = '', enable = true,
              {conditionType = 'pressEarly', value = '0.75'}}}
          local code = Kitty.Share.exportCommandList(list)
          local imported = assert(Kitty.Share.importCommandList(code))
          assert(imported[1][1].conditionType == 'pressEarly' and imported[1][1].value == '0.75')
        ''')


class PressEarlyTimingModel(unittest.TestCase):
    """Drive the real engine against the client/server timing model.

    One Charged Chop row (1 s cooldown, 1 s global cooldown) above a filler
    skill. Ping and press rate vary; the press-early row must reach one cast
    per server second and never trip the client's send block.
    """

    @staticmethod
    def run_model(rows, press, ping, seed, duration=30.0):
        lua = test_kitty_startup.KittyStartupTests().runtime()
        lua.execute(SETUP)
        lua.execute('list = {info = {name = "Model"}, ' + rows + ', row("Filler")}')
        g = lua.globals()
        rng = random.Random(seed)
        server_phase = rng.random()
        client_phase = rng.random() * 0.1
        cooldown = {"Charged Chop": (1, 1), "Filler": (6, 1)}
        server = {"gcd": 0, "Charged Chop": 0, "Filler": 0}
        client = {"gcd": 0, "Charged Chop": 0, "Filler": 0}
        events, order = [], itertools.count()

        def add(when, kind, name=None):
            heapq.heappush(events, (when, next(order), kind, name))

        state = {"unfinished": 0, "last_send": -10.0, "blocked": 0}
        casts = {"Charged Chop": 0, "Filler": 0}
        t = 0.0
        while t < duration:
            add(t, "press")
            t += press * rng.uniform(0.85, 1.15)
        for i in range(int(duration) + 3):
            add(server_phase + i, "server tick")
        for i in range(int(duration * 10) + 30):
            add(client_phase + i * 0.1, "client tick")
        while events:
            now, _, kind, name = heapq.heappop(events)
            if now > duration:
                break
            if kind == "server tick":
                for key in server:
                    server[key] = max(0, server[key] - 1)
            elif kind == "client tick":
                for key in client:
                    client[key] = max(0, client[key] - 1)
            elif kind == "press":
                g.now = 100 + now
                for skill in casts:
                    g.cooldowns[skill] = max(client["gcd"], client[skill]) * 0.1
                before = len(g.sent)
                lua.eval("press(list)")
                for index in range(before + 1, len(g.sent) + 1):
                    if state["unfinished"] > 4 and state["last_send"] + 0.99 > now:
                        state["blocked"] += 1
                        continue
                    state["unfinished"] += 1
                    state["last_send"] = now
                    add(now + ping / 2 + rng.uniform(0, 0.01), "arrive", g.sent[index])
            elif kind == "arrive":
                if server["gcd"] == 0 and server[name] == 0:
                    own, gcd = cooldown[name]
                    server[name] = own
                    server["gcd"] = gcd
                    casts[name] += 1
                    add(now + ping / 2, "cast report", name)
            elif kind == "cast report":
                own, gcd = cooldown[name]
                client[name] = own * 10
                client["gcd"] = gcd * 10
                state["unfinished"] = 0
        return casts["Charged Chop"], state["blocked"]

    def test_press_early_reaches_one_chop_per_second_without_blocks(self):
        early = 'row("Charged Chop", {conditionType = "pressEarly", value = "0.75"})'
        # "Skill is ready: Charged Chop 0" waits until the icon shows ready
        strict = 'row("Charged Chop", {conditionType = "canCast", {name = "Charged Chop", threshold = 0}})'
        for press in (0.05, 0.1, 0.2, 0.3):
            for ping in (0.1, 0.25):
                with self.subTest(press=press, ping=ping):
                    chops, blocked = zip(*(self.run_model(early, press, ping, seed) for seed in range(4)))
                    self.assertGreaterEqual(min(chops), 29)
                    self.assertEqual(sum(blocked), 0)
                    waited = [self.run_model(strict, press, ping, seed)[0] for seed in range(4)]
                    self.assertLess(max(waited), min(chops) - 1)

    def test_a_plain_row_pressed_fast_trips_the_send_block(self):
        # Without pacing, fast presses at a high ping send more than five
        # requests before the first answer, and the client blocks the rest.
        plain = 'row("Charged Chop")'
        early = 'row("Charged Chop", {conditionType = "pressEarly", value = "0.75"})'
        self.assertGreater(sum(self.run_model(plain, 0.05, 0.25, seed)[1] for seed in range(4)), 0)
        self.assertEqual(sum(self.run_model(early, 0.05, 0.25, seed)[1] for seed in range(4)), 0)


if __name__ == "__main__":
    unittest.main()
