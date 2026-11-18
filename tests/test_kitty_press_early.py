"""KittyCombo "Press early" rows (pressEarly condition), Lua 5.1.

    python -m unittest discover -s tests -p test_kitty_press_early.py -v

The timing model at the end follows the client and server source
(cherrybooze/oneforall): the server lowers whole-second cooldown counters on
each character's one-second tick, sets them when a spell ends and refuses a
cast while the global cooldown or the skill's own counter is above 0; the
client starts its 0.1 s countdown when the cast report arrives, and stops
sending casts until 0.99 s after the last send once more than four went out
without a finished spell.
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


EARLY = 'row("Charged Chop", {conditionType = "pressEarly", value = "0.75"})'
# "Skill is ready: Charged Chop 0" waits until the icon shows ready
STRICT = 'row("Charged Chop", {conditionType = "canCast", {name = "Charged Chop", threshold = 0}})'


def ready_row(name):
    return 'row("%s", {conditionType = "canCast", {name = "%s", threshold = 0}})' % (name, name)


def early_row(name, seconds="0.75"):
    return 'row("%s", {conditionType = "pressEarly", value = "%s"})' % (name, seconds)


class PressEarlyTimingModel(unittest.TestCase):
    """Drive the real engine against the client/server timing model.

    Server (MagicProcess.cpp, RD_Setting.cxx, NetSrv_MagicChild.cpp): own and
    global cooldowns are whole seconds lowered on the character's 1 s beat and
    set when the spell ends; the spell runs on the next 0.2 s process step and
    ends 0.1 s later, and a request that arrives meanwhile is dropped without
    an answer. A skill with no global cooldown (TimeAllMagic 0) does not set it
    but still waits for it.
    """

    @staticmethod
    def run_model(rows, press, ping, seed, cooldown=None, duration=30.0, setup=""):
        cooldown = cooldown or {"Charged Chop": (1, 1), "Filler": (6, 1)}
        lua = test_kitty_startup.KittyStartupTests().runtime()
        lua.execute(SETUP)
        # Rage, mana and energy are assumed to be enough
        lua.execute('for _, key in ipairs({"manaList", "tensionList", "energyList", "focusList"}) do'
                    ' Kitty.SkillManager[key] = {} end')
        if setup:
            lua.execute(setup)
        lua.execute('list = {info = {name = "Model"}, ' + ", ".join(rows) + '}')
        g = lua.globals()
        rng = random.Random(seed)
        server = dict.fromkeys(cooldown, 0)
        client = dict.fromkeys(cooldown, 0)
        global_cd = {"server": 0, "client": 0}
        spell = {"name": None, "ending": False}
        events, order = [], itertools.count()

        def add(when, kind, name=None):
            heapq.heappush(events, (when, next(order), kind, name))

        state = {"unfinished": 0, "last_send": -10.0, "blocked": 0}
        casts = dict.fromkeys(cooldown, 0)
        t = 0.0
        while t < duration:
            add(t, "press")
            t += press * rng.uniform(0.85, 1.15)
        server_phase = rng.random()
        for i in range(int(duration) + 3):
            add(server_phase + i, "server beat")
        client_phase = rng.random() * 0.1
        for i in range(int(duration * 10) + 30):
            add(client_phase + i * 0.1, "client tick")
        add(rng.random() * 0.2, "spell step")
        while events:
            now, _, kind, name = heapq.heappop(events)
            if now > duration:
                break
            if kind == "server beat":
                for key in server:
                    server[key] = max(0, server[key] - 1)
                global_cd["server"] = max(0, global_cd["server"] - 1)
            elif kind == "client tick":
                for key in client:
                    client[key] = max(0, client[key] - 1)
                global_cd["client"] = max(0, global_cd["client"] - 1)
            elif kind == "press":
                g.now = 100 + now
                for skill in client:
                    g.cooldowns[skill] = max(global_cd["client"], client[skill]) * 0.1
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
                if spell["name"] is None and global_cd["server"] == 0 and server[name] == 0:
                    spell["name"], spell["ending"] = name, False
            elif kind == "spell step":
                step = 0.2
                if spell["name"] is not None:
                    step = 0.1
                    if spell["ending"]:
                        own, gcd = cooldown[spell["name"]]
                        server[spell["name"]] = own
                        if gcd:
                            global_cd["server"] = gcd
                        casts[spell["name"]] += 1
                        add(now + ping / 2, "cast report", spell["name"])
                        spell["name"] = None
                    else:
                        spell["ending"] = True
                add(now + step, "spell step")
            elif kind == "cast report":
                own, gcd = cooldown[name]
                client[name] = own * 10
                if gcd:
                    global_cd["client"] = gcd * 10
                state["unfinished"] = 0
        return casts, state["blocked"]

    def chops(self, rows, press, ping, seeds=4, cooldown=None):
        runs = [self.run_model(rows, press, ping, seed, cooldown) for seed in range(seeds)]
        return [casts["Charged Chop"] for casts, _ in runs], runs

    def test_press_early_reaches_one_chop_per_second_without_blocks(self):
        # Charged Chop with its own 1 s global cooldown above a filler skill
        for press in (0.05, 0.1, 0.2, 0.3):
            for ping in (0.1, 0.25):
                with self.subTest(press=press, ping=ping):
                    chops, runs = self.chops([EARLY, 'row("Filler")'], press, ping)
                    self.assertGreaterEqual(min(chops), 29)
                    self.assertEqual(sum(blocked for _, blocked in runs), 0)
                    waited, _ = self.chops([STRICT, 'row("Filler")'], press, ping)
                    self.assertLess(max(waited), min(chops) - 1)

    def test_skills_with_a_global_cooldown_still_fire_between_chops(self):
        # The shape of a Warrior/Warden kitty measured with a damage meter
        # (17 Charged Chops and 16 other skills in 30 s with "Skill is ready 0"):
        # Charged Chop sets no global cooldown, the skills below it do, so they
        # fit in right after each chop, but one landing between the server's
        # beat and the chop pushes that chop back a second.
        cooldown = {"Charged Chop": (1, 0), "Savage Whirlwind": (7, 1), "Probing Attack": (5, 1),
                    "Open Flank": (5, 1), "Thunder": (14, 1)}
        lower = [ready_row(name) for name in ("Savage Whirlwind", "Probing Attack", "Open Flank", "Thunder")]
        for press in (0.1, 0.2):
            for ping in (0.1, 0.25):
                with self.subTest(press=press, ping=ping):
                    waited, before = self.chops([STRICT] + lower, press, ping, 6, cooldown)
                    chops, after = self.chops([EARLY] + lower, press, ping, 6, cooldown)
                    others_before = sum(sum(casts.values()) for casts, _ in before) - sum(waited)
                    others_after = sum(sum(casts.values()) for casts, _ in after) - sum(chops)
                    self.assertLessEqual(sum(waited) / 6, 22)
                    self.assertGreaterEqual(sum(chops) / 6, sum(waited) / 6 + 4)
                    self.assertGreaterEqual(others_after / 6, others_before / 6 - 3)

    def test_rows_below_that_press_early_go_out_right_after_each_chop(self):
        # "Skill is ready 0" on the rows below makes them wait for their icons,
        # which lag the server by up to a second, so right after a chop they often
        # still show the global cooldown and miss their turn. With Press early on
        # them too, one of them goes out right after each chop instead, Charged
        # Chop keeps its count, and the paced sends stay clear of the send block.
        cooldown = {"Charged Chop": (1, 0), "Savage Whirlwind": (7, 1), "Probing Attack": (5, 1),
                    "Open Flank": (5, 1), "Thunder": (14, 1)}
        names = ("Savage Whirlwind", "Probing Attack", "Open Flank", "Thunder")
        waiting = [EARLY] + [ready_row(name) for name in names]
        pressing = [EARLY] + [early_row(name) for name in names]
        for press in (0.05, 0.15):
            for ping in (0.03, 0.1):
                with self.subTest(press=press, ping=ping):
                    chops_before, before = self.chops(waiting, press, ping, 6, cooldown)
                    chops_after, after = self.chops(pressing, press, ping, 6, cooldown)
                    others_before = sum(sum(casts.values()) for casts, _ in before) - sum(chops_before)
                    others_after = sum(sum(casts.values()) for casts, _ in after) - sum(chops_after)
                    self.assertGreaterEqual(sum(chops_after) / 6, 29)
                    self.assertGreaterEqual(sum(chops_after) / 6, sum(chops_before) / 6 - 0.5)
                    self.assertGreaterEqual(others_after / 6, others_before / 6 + 2)
                    self.assertEqual(sum(blocked for _, blocked in after), 0)

    def test_a_plain_row_pressed_fast_trips_the_send_block(self):
        # Without pacing, fast presses at a high ping send more than five
        # requests before the first answer, and the client blocks the rest.
        plain = [self.run_model(['row("Charged Chop")', 'row("Filler")'], 0.05, 0.25, seed)[1] for seed in range(4)]
        early = [self.run_model([EARLY, 'row("Filler")'], 0.05, 0.25, seed)[1] for seed in range(4)]
        self.assertGreater(sum(plain), 0)
        self.assertEqual(sum(early), 0)


if __name__ == "__main__":
    unittest.main()
