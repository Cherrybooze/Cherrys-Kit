"""KittyCombo "Attack speed (hits/s)" condition, Lua 5.1.

    python -m unittest discover -s tests -p test_kitty_attack_speed.py -v

A row with the condition fires when the rom weakauras "Hits per second" aura
(or, without it, RWA.Recent.Rate("white", 3)) is at the rate or higher. How
often it may fire is the "Imaginary cooldown (s)" condition's job.
"""

import unittest

import test_kitty_startup


SETUP = '''
  Kitty.sendMessage = function(text) table.insert(chat, text) end
  chat = {}
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
  auraRate, recentRate = nil, nil
  auraCalls = {}
  RWA = {
    IsAuraActive = function() return true end,
    GetAuraValue = function(id, field) table.insert(auraCalls, id .. ':' .. field); return auraRate end,
    Recent = {Rate = function(measure, window) return recentRate end},
  }
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
  function speed(rate)
    return {conditionType = 'attackSpeed', value = rate}
  end
'''


class KittyAttackSpeedTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute(SETUP)

    def test_fires_at_or_over_the_rate_from_the_aura(self):
        self.lua.execute('''
          list = {info = {name = 'K'}, row('Fan of Knives', speed('4')), row('Other')}
          auraRate = 3.6
          local t, n = press(list); assert(n == 'Other', tostring(n))
          assert(auraCalls[1] == 'Hits per second:perSecond', tostring(auraCalls[1]))
          auraRate = 4.2
          t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          auraRate = 4
          t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          -- Blank = 4, "4,5" = 4.5
          list = {info = {name = 'K'}, row('Fan of Knives', speed('')), row('Other')}
          t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          list = {info = {name = 'K'}, row('Fan of Knives', speed('4,5')), row('Other')}
          t, n = press(list); assert(n == 'Other', tostring(n))
        ''')

    def test_falls_back_to_recent_rate_and_skips_without_weakauras(self):
        self.lua.execute('''
          list = {info = {name = 'K'}, row('Fan of Knives', speed('4.5')), row('Other')}
          auraRate, recentRate = nil, 4.6
          local t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          recentRate = 4.4
          t, n = press(list); assert(n == 'Other', tostring(n))
          RWA = nil
          t, n = press(list); assert(n == 'Other', tostring(n))
          t, n = press(list)
          assert(#chat == 1 and string.find(chat[1], 'rom weakauras'), tostring(chat[1]))
        ''')

    def test_help_text_menu_and_share_code(self):
        self.lua.execute('''
          local help = Kitty.ComboManager.attackSpeedHelp(nil, '4')
          assert(string.find(help, '4'), help)
          assert(Kitty.ComboManager.conditionLabel('attackSpeed') == 'Attack speed (hits/s)')
          local level1, level2 = Kitty.ComboManager.getConditionMenu()
          local found = false
          for _, list in ipairs(level2) do
            if type(list) == 'table' then
              for _, entry in ipairs(list) do
                if entry.value == 'attackSpeed' then found = true end
              end
              assert(#list <= 32)
            end
          end
          assert(found)
          local fields = table.concat(Kitty.ComboManager.WEAKAURA_FIELDS, ',')
          assert(string.find(fields, 'perSecond'))
          local list = {info = {name = 'WWd', class = 'WWd', target = 'all'},
            {commandType = 'skill', commandName = 'Fan of Knives', icon = '', enable = true,
              {conditionType = 'attackSpeed', value = '4'}}}
          local code = Kitty.Share.exportCommandList(list)
          local imported = assert(Kitty.Share.importCommandList(code))
          local c = imported[1][1]
          assert(c.conditionType == 'attackSpeed' and c.value == '4')
        ''')

    def test_weakaura_state_per_second_field(self):
        self.lua.execute('''
          RWA_DB = {auras = {['Hits per second'] = {}}}
          list = {info = {name = 'K'}, row('Fan of Knives',
            {conditionType = 'weakaura', name = 'Hits per second', field = 'perSecond', min = 4}), row('Other')}
          auraRate = 4.1
          local t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          auraRate = 3
          t, n = press(list); assert(n == 'Other', tostring(n))
        ''')

    def test_with_imaginary_cooldown_fires_every_n_seconds_only_when_fast(self):
        self.lua.execute('''
          Kitty.ImaginaryCooldown.state = setmetatable({}, {__mode = 'k'})
          list = {info = {name = 'K'},
            row('Fan of Knives', speed('4'), {conditionType = 'imaginaryCooldown', value = '5'}),
            row('Other')}
          auraRate = 3.5
          local t, n = press(list); assert(n == 'Other', tostring(n))
          auraRate = 4.3
          t, n = press(list); assert(n == 'Fan of Knives', tostring(n))
          local fans = 1
          for i = 1, 100 do
            now = now + 0.2
            t, n = press(list)
            if n == 'Fan of Knives' then fans = fans + 1 end
          end
          -- 20 s more at 4.3 hits/s: one every 5 s
          assert(fans == 5, fans)
          -- Slower again: none, even with its wait over
          auraRate = 3; now = now + 10
          t, n = press(list); assert(n == 'Other', tostring(n))
        ''')

    def test_prediction_matches(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          auraRate = 5
          Kitty.SettingManager.setting = {command = {{info = {name = 'P', class = 'any', target = 'all'},
            row('Fan of Knives', speed('4')), row('Other')}}}
          Kitty.Predict.cache = {}
          local prediction = Kitty.Predict.next('P', 2)
          assert(prediction[1].name == 'Fan of Knives' and prediction[2].name == 'Other')
          assert(#sent == 0)
        ''')


if __name__ == "__main__":
    unittest.main()
