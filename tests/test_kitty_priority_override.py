"""KittyCombo priority override rows (row type "override"), Lua 5.1.

    python -m unittest discover -s tests -p test_kitty_priority_override.py -v

An override row is a skill or suit skill row saved with override = true. It is
checked before every other row of its kitty and fires on its imaginary
cooldown (blank or none = 1 s) instead of the cooldown the client shows. After
a fire it waits for the game to take the skill (its cooldown goes up on the
client): it sends it again up to four times in a second and the rows below
wait meanwhile. A turn the game did not take is followed by single sends until
the client shows the cooldown again. The timing model at the end drives the
real engine against the client/server model of test_kitty_press_early.
"""

import statistics
import unittest
import xml.etree.ElementTree as ET

import test_kitty_startup
from test_kitty_press_early import SETUP, EARLY, STRICT, PressEarlyTimingModel, ready_row


OVERRIDE_SETUP = '''
  for _, key in ipairs({"manaList", "tensionList", "energyList", "focusList", "soulPointList"}) do
    Kitty.SkillManager[key] = {}
  end
  Kitty.ImaginaryCooldown.state = setmetatable({}, {__mode = 'k'})
  Kitty.ComboManager.overrideState = setmetatable({}, {__mode = 'k'})
  casting = nil
  UnitCastingTime = function() return casting end
  function override(name, ...)
    local command = row(name, ...)
    command.override = true
    return command
  end
  function every(seconds) return {conditionType = 'imaginaryCooldown', value = seconds} end
  function count(name)
    local n = 0
    for _, s in ipairs(sent) do if s == name then n = n + 1 end end
    return n
  end
  function sends() return table.concat(sent, ',') end
'''


def override_row(name, seconds=None):
    """A Lua expression for an override row (for the timing model's rows)."""
    every = ', {conditionType = "imaginaryCooldown", value = "%s"}' % seconds if seconds else ''
    return '(function() local c = row("%s"%s); c.override = true; return c end)()' % (name, every)


class PriorityOverrideEngineTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute(SETUP)
        self.lua.execute(OVERRIDE_SETUP)

    def test_goes_before_the_rows_above_it_once_a_second_on_the_beat(self):
        self.lua.execute('''
          list = {info = {name = 'O'}, row('Top'), row('Second'), override('Chop', every('1'))}
          local t, n = press(list); assert(t == 'skill' and n == 'Chop', tostring(n))
          now = 100.3; t, n = press(list); assert(n == 'Top')
          now = 100.99; t, n = press(list); assert(n == 'Top')
          now = 101.0; t, n = press(list); assert(n == 'Chop')
          -- 0.2 s late keeps the beat: the next one is due 0.8 s later
          now = 102.2; t, n = press(list); assert(n == 'Chop')
          now = 102.99; t, n = press(list); assert(n == 'Top')
          now = 103.0; t, n = press(list); assert(n == 'Chop')
          assert(sends() == 'Chop,Top,Top,Chop,Chop,Top,Chop', sends())
          assert(Kitty.ComboManager.isOverride(list[3]) and not Kitty.ComboManager.isOverride(list[1]))
        ''')

    def test_no_condition_means_once_a_second_and_typed_periods_work(self):
        self.lua.execute('''
          local list = {info = {name = 'O'}, row('Top'), override('Chop')}
          local _, n = press(list); assert(n == 'Chop')
          now = 100.99; _, n = press(list); assert(n == 'Top')
          now = 101.0; _, n = press(list); assert(n == 'Chop')
          local slow = {info = {name = 'S'}, row('Top'), override('Big', every('2,5'))}
          now = 110; _, n = press(slow); assert(n == 'Big')
          now = 112.4; _, n = press(slow); assert(n == 'Top')
          now = 112.5; _, n = press(slow); assert(n == 'Big')
        ''')

    def test_the_icon_cooldown_is_not_checked_but_the_skill_must_be_there(self):
        self.lua.execute('''
          cooldowns['Chop'] = 0.8     -- the icon lags the game
          local plain = {info = {name = 'P'}, row('Chop'), row('Other')}
          local _, n = press(plain); assert(n == 'Other', 'a plain row waits for the icon')
          local list = {info = {name = 'O'}, row('Other'), override('Chop', every('1'))}
          _, n = press(list); assert(n == 'Chop')
          local base = Kitty.SkillManager.fetchSkill
          Kitty.SkillManager.fetchSkill = function(name)
            if name == 'Gone' then return nil end
            if name == 'Locked' then return {isAvailable = false, isSuitSkill = false, remaining = 0, texture = 'icon'} end
            return base(name)
          end
          local missing = {info = {name = 'M'}, override('Gone'), override('Locked'), override(''), row('Other')}
          _, n = press(missing); assert(n == 'Other')
          assert(Kitty.ImaginaryCooldown.state[missing[1]] == nil and Kitty.ImaginaryCooldown.state[missing[2]] == nil)
        ''')

    def test_range_and_ready_conditions_decide_and_a_failed_check_starts_no_wait(self):
        self.lua.execute('''
          inRange = false
          Kitty.slotManager.inRange = function(_, name) return inRange end
          cooldowns['Chop'] = 0.9
          local list = {info = {name = 'O'}, row('Other'),
            override('Chop', every('1'), {conditionType = 'inRange', value = 'Chop'},
              {conditionType = 'canCast', {name = 'Chop', threshold = 0.75}})}
          local _, n = press(list); assert(n == 'Other', 'out of range')
          inRange = true
          now = 100.1; _, n = press(list); assert(n == 'Other', 'the icon still shows more than 0.75 s')
          cooldowns['Chop'] = 0.7
          now = 100.2; _, n = press(list); assert(n == 'Chop', 'it fires as soon as they pass')
          -- Out of range while it waits for the game: the rows below go
          now = 100.3; inRange = false; cooldowns['Chop'] = 0.6
          _, n = press(list); assert(n == 'Other')
        ''')

    def test_sends_again_until_the_game_takes_it_and_the_rows_below_wait(self):
        self.lua.execute('''
          local list = {info = {name = 'O'}, row('Other'), override('Chop', every('1'))}
          cooldowns['Chop'] = 0.4
          local t, n = press(list); assert(n == 'Chop')
          now = 100.1; cooldowns['Chop'] = 0.3
          t, n = press(list); assert(t == 'hold' and n == 'Chop', tostring(t))
          now = 100.3; cooldowns['Chop'] = 0.1
          t, n = press(list); assert(t == 'skill' and n == 'Chop', 'a quarter second later: again')
          now = 100.45; cooldowns['Chop'] = 1.0       -- the game took it
          t, n = press(list); assert(n == 'Other')
          now = 100.99; cooldowns['Chop'] = 0.5
          t, n = press(list); assert(n == 'Other')
          now = 101.0
          t, n = press(list); assert(n == 'Chop', 'the marks stay where the first send put them')
          assert(sends() == 'Chop,Chop,Other,Other,Chop', sends())
        ''')

    def test_four_sends_at_most_then_single_sends_until_the_game_takes_it_again(self):
        self.lua.execute('''
          local list = {info = {name = 'O'}, row('Other'), override('Chop', every('1'))}
          cooldowns['Chop'] = 0.5     -- shown, but the game never takes it
          for i = 0, 16 do now = 100 + i * 0.06; press(list) end
          assert(count('Chop') == 4 and count('Other') == 0, sends())
          sent = {}
          now = 101.02; local t, n = press(list); assert(n == 'Chop')
          now = 101.08; t, n = press(list); assert(n == 'Other', 'a missed turn does not hold the next one')
          now = 101.5; cooldowns['Chop'] = 1.0
          t, n = press(list); assert(n == 'Other')
          now = 102.02; cooldowns['Chop'] = 0.3
          t, n = press(list); assert(n == 'Chop')
          now = 102.08; t, n = press(list); assert(t == 'hold', 'taken again, so it waits for the game again')
        ''')

    def test_a_skill_without_a_shown_cooldown_is_sent_once_and_a_cast_counts_as_taken(self):
        self.lua.execute('''
          local list = {info = {name = 'O'}, row('Other'), override('Shout', every('1'))}
          for i = 0, 15 do now = 100 + i * 0.06; press(list) end
          assert(count('Shout') == 1 and count('Other') == 15, sends())
          cooldowns['Bolt'] = 0.3
          local cast = {info = {name = 'C'}, row('Other'), override('Bolt', every('3'))}
          now = 110; local t, n = press(cast); assert(n == 'Bolt')
          now = 110.1; t, n = press(cast); assert(t == 'hold')
          casting = 'Bolt'
          now = 110.2; t, n = press(cast); assert(n == 'Other', 'a cast started: taken')
        ''')

    def test_override_rows_take_turns_in_list_order(self):
        self.lua.execute('''
          local list = {info = {name = 'O'}, row('Other'), override('A', every('1')), override('B', every('1'))}
          local _, n = press(list); assert(n == 'A')
          now = 100.1; _, n = press(list); assert(n == 'B')
          now = 100.2; _, n = press(list); assert(n == 'Other')
          now = 101.0; _, n = press(list); assert(n == 'A')
          now = 101.1; _, n = press(list); assert(n == 'B')
        ''')

    def test_disabled_rows_and_a_stale_flag_on_other_row_types(self):
        self.lua.execute('''
          Kitty.slotManager.canDispatch = function() return true end
          Kitty.slotManager.use = function(_, slot) table.insert(sent, 'slot ' .. slot) end
          local off = override('Chop', every('1')); off.enable = false
          local stale = {commandType = 'action', commandName = '7', override = true}
          assert(not Kitty.ComboManager.isOverride(stale))
          local list = {info = {name = 'O'}, row('Other'), stale, off}
          local t, n = press(list); assert(n == 'Other')
          list = {info = {name = 'O'}, stale, row('Other'), off}
          t, n = press(list); assert(t == 'action' and n == '7', 'a stale flag leaves an action row in its place')
          assert(Kitty.ImaginaryCooldown.state[off] == nil)
        ''')

    def test_procs_check_their_own_override_rows_first(self):
        self.lua.execute('''
          Kitty.SettingManager.setting = {command = {
            {info = {name = 'Inner', class = 'proc', target = 'all'}, row('Inner other'), override('Inner chop', every('1'))}}}
          local outer = {info = {name = 'Outer'}, {commandType = 'proc', commandName = 'Inner'},
            row('Outer other'), override('Outer chop', every('1'))}
          local _, n = press(outer); assert(n == 'Outer chop')
          now = 100.1; _, n = press(outer); assert(n == 'Inner chop')
          now = 100.2; _, n = press(outer); assert(n == 'Inner other')
        ''')

    def test_attack_macro_holds_the_next_kitty_too(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          Kitty.BuildManager.getClass = function() return 'Warrior', 'Warden', 'WARRIOR', 'WARDEN' end
          cooldowns['Chop'] = 0.4
          Kitty.SettingManager.setting = {basic = {}, command = {
            {info = {name = 'Chop', class = 'any', target = 'all'}, override('Chop', every('1'))},
            {info = {name = 'Rest', class = 'any', target = 'all'}, row('Other')}}}
          Kitty.attack('Chop', 'Rest')
          now = 100.1; Kitty.attack('Chop', 'Rest')
          now = 100.3; cooldowns['Chop'] = 1.0; Kitty.attack('Chop', 'Rest')
          assert(sends() == 'Chop,Other', sends())
        ''')

    def test_prediction_shows_it_when_due_or_waiting_and_changes_nothing(self):
        self.lua.execute('''
          Kitty.isTurnedOff = function() return false end
          Kitty.SettingManager.setting = {command = {{info = {name = 'P', class = 'any', target = 'all'},
            row('Top'), override('Chop', every('1'))}}}
          local list = Kitty.SettingManager.setting.command[1]
          cooldowns['Chop'] = 0.6
          for i = 1, 3 do
            Kitty.Predict.cache = {}
            local p = Kitty.Predict.next('P', 2)
            assert(p[1].name == 'Chop' and p[2].name == 'Top')
          end
          assert(next(Kitty.ImaginaryCooldown.state) == nil and next(Kitty.ComboManager.overrideState) == nil)
          press(list)
          local state = Kitty.ComboManager.overrideState[list[2]]
          local function snapshot() return state.sends .. ':' .. state.seen .. ':' .. tostring(state.waiting) end
          local before = snapshot()
          now = 100.1; Kitty.Predict.cache = {}
          assert(Kitty.Predict.next('P', 1)[1].name == 'Chop', 'still waiting for the game')
          cooldowns['Chop'] = 1.0; Kitty.Predict.cache = {}
          assert(Kitty.Predict.next('P', 1)[1].name == 'Top', 'taken: the next row')
          assert(snapshot() == before and #sent == 1)
        ''')

    def test_share_codes_keep_the_flag_and_the_icon(self):
        self.lua.execute('''
          local list = {info = {name = 'Share', class = 'any', target = 'all'},
            {commandType = 'skill', commandName = 'Chop', icon = 'foreign-icon', enable = true, override = true,
              {conditionType = 'imaginaryCooldown', value = '1'},
              {conditionType = 'canCast', {name = 'Chop', threshold = 0.75}}},
            {commandType = 'skill', commandName = 'Other', icon = '', enable = true}}
          local codes = {Kitty.Share.exportCommandListV1(list), Kitty.Share.exportCommandListV2(list), Kitty.Share.exportCommandList(list)}
          for index, code in ipairs(codes) do
            local imported = assert(Kitty.Share.importCommandList(code))
            assert(imported[1].override == true and Kitty.ComboManager.isOverride(imported[1]), index)
            assert(imported[2].override == nil)
            assert(imported[1][1].conditionType == 'imaginaryCooldown' and imported[1][2][1].threshold == 0.75)
            assert(imported[1].icon == (index == 1 and 'foreign-icon' or 'icon'), tostring(imported[1].icon))
          end
        ''')

    def test_the_kitty_listing_and_help_say_it_goes_first(self):
        self.lua.execute('''
          local command = {commandType = 'skill', commandName = 'Chop', override = true}
          assert(string.find(Kitty.ComboManager.formatCommandType('skill', command), '!', 1, true))
          assert(string.find(Kitty.ComboManager.formatCommandType('skill', {commandType = 'skill'}), 'K', 1, true))
          local help = Kitty.ComboManager.commandHelp(command)
          assert(string.find(help[1], 'Priority override', 1, true) and string.find(help[1], '[1]', 1, true), help[1])
          table.insert(command, {conditionType = 'imaginaryCooldown', value = '2'})
          help = Kitty.ComboManager.commandHelp(command)
          assert(string.find(help[1], 'Priority override', 1, true) and not string.find(help[1], 'once every', 1, true))
          assert(string.find(help[2], '2', 1, true))
          local plain = Kitty.ComboManager.commandHelp({commandType = 'skill', commandName = 'Chop'})
          assert(#plain == 0)
          local lines = Kitty.ComboManager.commandListHelp({info = {name = 'L'}, command})
          assert(string.find(lines[1], '!', 1, true) and string.find(lines[2][1], 'Priority override', 1, true))
          assert(string.find(Kitty.MenuHelp.commandTypes.override, 'before every other row', 1, true))
          assert(Kitty.MenuHelp.describe('KittyCommandConfigFrame_Button3DropDownMenu', 'override') == Kitty.MenuHelp.commandTypes.override)
          local lines = Kitty.ComboManager.imaginaryCooldownDescribe(nil, nil)
          assert(string.find(lines[3], 'override', 1, true))
        ''')


class PriorityOverrideEditorTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute('''
          Kitty.sendMessage = function() end
          Kitty.debugPrint = function() end
          Kitty.getTime = function() return 100 end
          Kitty.SettingManager.setting = {mode = {names = {}, current = nil}, basic = {}, command = {}}
          Kitty.SkillManager.fetchSkill = function(name)
            return {isAvailable = true, isSuitSkill = false, remaining = 0, texture = 'skill-icon'}
          end
          Kitty.SkillManager.update = function() end
          Kitty.slotManager = {}; Kitty.macroManager = {}; Kitty.cooldownManager = Kitty.CooldownManager()
          function widget(name, text)
            local w = {name = name, text = text or '', visible = true, checked = true}
            function w:GetName() return self.name end
            function w:GetID() return self.id or 1 end
            function w:GetText() return self.text end
            function w:SetText(text) self.text = text end
            function w:SetFile(file) self.file = file end
            function w:SetColor(r, g, b) self.color = {r, g, b} end
            function w:SetChecked(v) self.checked = v end
            function w:IsChecked() return self.checked end
            function w:Show() self.visible = true end
            function w:Hide() self.visible = false end
            function w:IsVisible() return self.visible end
            _G[name] = w; return w
          end
          getglobal = function(name) return _G[name] end
          UIDropDownMenu_GetText = function(w) return w.text end
          UIDropDownMenu_SetText = function(w, text) w.text = text end
          local F = Kitty.CommandConfigFrame
          original = {info = {name = 'Edit', class = 'any', target = 'all'},
            {commandType = 'skill', commandName = 'Charged Chop', icon = 'chop-icon'}}
          Kitty.SettingManager.setting.command = {original}
          F.targetCommandList = Kitty.copyTable(original); F.allowUpdateData = true
          row = widget('EditRow')
          for _, suffix in ipairs({'CheckButton', 'ActionButtonIcon', 'DropDownMenu', 'CommandNameEditBox',
              'CommandDropDownMenu', 'ModeButton', 'ConditionButton', 'Rank'}) do
            widget('EditRow' .. suffix)
          end
          EditRowCommandNameEditBox.text = 'Charged Chop'
          widget('KittyCommandConfigFrame_CommandListNameEditBox', 'Edit')
          widget('KittyCommandConfigFrame_BuildDropDownMenu', 'any')
          widget('KittyCommandConfigFrame_TargetDropDownMenu', 'all')
          KittyCommandConfigFrame = widget('KittyCommandConfigFrame')
          KittyCommandConfigFrame_ScrollBar = {GetValue = function() return 1 end}
          F.onShowList = function() F.showDetail(row, F.targetCommandList[1], 1, 1) end
          Kitty.ModeUI.openPicker = function() error('a skill row opened the mode icons') end
        ''')

    def test_picking_override_makes_a_skill_row_that_goes_first_with_its_one_second(self):
        self.lua.execute('''
          local F = Kitty.CommandConfigFrame
          EditRowDropDownMenu.text = 'override'
          F.onTypeChanged(row)
          local command = F.targetCommandList[1]
          assert(command.commandType == 'skill' and command.override == true and command.commandName == 'Charged Chop')
          assert(command.icon == 'chop-icon')
          assert(command[1].conditionType == 'imaginaryCooldown' and command[1].value == '1')
          assert(EditRowDropDownMenu.text == 'override' and F.typeText(command) == 'override')
          assert(EditRowRank.text == '!' and EditRowRank.color[1] == 1.0 and EditRowRank.color[2] == 0.82)
          assert(original[1].override == nil, 'only the editor draft changed')
          -- Picking it again adds no second cooldown; other edits keep the flag
          F.onTypeChanged(row)
          assert(#F.targetCommandList[1] == 1 and F.targetCommandList[1].override == true)
          EditRowCheckButton.checked = false
          F.updateData(row)
          assert(F.targetCommandList[1].override == true and F.targetCommandList[1].enable == false)
          -- Back to "skill": a plain skill row with its conditions
          EditRowDropDownMenu.text = 'skill'
          F.onTypeChanged(row)
          command = F.targetCommandList[1]
          assert(command.override == nil and command.commandType == 'skill' and #command == 1)
          assert(F.typeText(command) == 'skill' and EditRowRank.text == '1')
        ''')

    def test_a_suit_skill_stays_one_and_a_kept_cooldown_is_not_doubled(self):
        self.lua.execute('''
          local F = Kitty.CommandConfigFrame
          F.targetCommandList[1] = {commandType = 'suitskill', commandName = 'Set Strike', icon = 'set-icon',
            {conditionType = 'imaginaryCooldown', value = '3'}}
          EditRowDropDownMenu.text = 'override'; EditRowCommandNameEditBox.text = 'Set Strike'
          F.onTypeChanged(row)
          local command = F.targetCommandList[1]
          assert(command.commandType == 'suitskill' and command.override == true)
          assert(#command == 1 and command[1].value == '3')
          assert(Kitty.ComboManager.formatCommandType(command.commandType, command) == Kitty.colorGreen('!'))
        ''')

    def test_dropping_a_skill_keeps_the_override_and_a_macro_clears_it(self):
        self.lua.execute('''
          local F = Kitty.CommandConfigFrame
          EditRowDropDownMenu.text = 'override'
          F.onTypeChanged(row)
          icon = widget('EditRowActionButton')
          icon.GetParent = function() return row end
          drop = {kind = Kitty.DragAndDropManager.SKILL, a = 2, b = 5}
          F.dragAndDropManager = {getInfo = function() return drop.kind, drop.a, drop.b end, clear = function() end}
          CursorItemType = function() return drop.kind end
          ItemClipboard_Clear = function() end
          GetSkillDetail = function() return 'Savage Whirlwind', nil, 'whirl-icon' end
          F.onDrop(icon)
          local command = F.targetCommandList[1]
          assert(command.commandName == 'Savage Whirlwind' and command.override == true and command.icon == 'whirl-icon')
          assert(EditRowDropDownMenu.text == 'override')
          drop.kind = Kitty.DragAndDropManager.MACRO
          GetMacroInfo = function() return 3, 'Buffs', '/cast Buff' end
          GetMacroIconInfo = function() return 'macro-icon' end
          F.onDrop(icon)
          command = F.targetCommandList[1]
          assert(command.commandType == 'macro' and command.override == nil)
          assert(EditRowDropDownMenu.text == 'macro' and EditRowRank.text == '1')
        ''')

    def test_range_and_ready_start_with_the_rows_skill_and_the_editor_keeps_the_flag(self):
        self.lua.execute('''
          local C = Kitty.CommandConditionFrame
          C.commandList = {info = {name = 'E'},
            {commandType = 'skill', commandName = 'Charged Chop', override = true},
            {commandType = 'skill', commandName = 'Plain'}}
          C.targetCommandIndex = 1
          local range = C.newCondition('inRange')
          assert(range.conditionType == 'inRange' and range.value == 'Charged Chop')
          local ready = C.newCondition('canCast')
          assert(ready.name == 'Charged Chop' and ready.threshold == C.OVERRIDE_READY_SECONDS and ready.threshold == 0.75)
          local other = C.newCondition('playerHealth')
          assert(other.conditionType == 'playerHealth' and other.value == nil and other.name == nil)
          C.targetCommandIndex = 2
          assert(C.newCondition('inRange').value == nil and C.newCondition('canCast').name == nil)
          C.commandList = nil
          assert(C.newCondition('canCast').name == nil)
          -- What the condition editor saves back keeps the row an override row
          local command = {commandType = 'skill', commandName = 'Charged Chop', override = true,
            {conditionType = 'imaginaryCooldown', value = '1'}}
          local split = C.separate(command)
          table.insert(split, ready)
          local merged = C.merge(split)
          assert(merged.override == true and merged.commandName == 'Charged Chop')
          assert(merged[2].conditionType == 'canCast' and merged[2][1].name == 'Charged Chop' and merged[2][1].threshold == 0.75)
        ''')

    def test_the_type_menu_lists_override_after_skill_with_help_on_hover(self):
        ns = test_kitty_startup.NS
        root = ET.parse(test_kitty_startup.KITTY / "gui/KittyCommandConfigFrame.xml").getroot()
        frame = root.find(".//ui:Frame[@name='$parentDropDownMenu']", ns)
        self.assertEqual(frame.get("enableMouse"), "true")
        scripts = frame.find("ui:Scripts", ns)
        self.lua.execute('''
          owner = {GetParent = function() return 'row' end}; this = owner
          Kitty.protectFunction = function(fn) return fn end
          Kitty.DropDown = function() return {setListData = function(_, fn, l1, l2) menuChoices, menuSub = l1, l2 end} end
        ''')
        self.lua.execute(scripts.find("ui:OnLoad", ns).text)
        self.lua.execute('''
          assert(menuChoices[1] == 'skill' and menuChoices[2] == 'override' and menuChoices[3] == 'suitskill')
          assert(menuChoices[10] == 'other' and menuSub[10][1] == 'break' and menuSub[10][2] == 'debug')
          for index, choice in ipairs(menuChoices) do
            assert(Kitty.MenuHelp.commandTypes[choice], choice)
          end
          shown = nil
          Kitty.showGameTooltip = function(_, lines) shown = lines end
          Kitty.hideGameTooltip = function() shown = 'hidden' end
          this = {text = 'override'}
        ''')
        self.lua.execute(scripts.find("ui:OnEnter", ns).text)
        self.lua.execute('''
          assert(shown[1] == 'override' and shown[2] == Kitty.MenuHelp.commandTypes.override)
        ''')
        self.lua.execute(scripts.find("ui:OnLeave", ns).text)
        self.assertEqual(self.lua.eval('shown'), 'hidden')
        # The condition menu builds each new condition through newCondition
        condition_xml = (test_kitty_startup.KITTY / "gui/KittyCommandConditionFrame.xml").read_text(encoding="utf-8")
        self.assertIn("Kitty.CommandConditionFrame.newCondition(Kitty.ComboManager.conditionFromLabel(button:GetText()))",
                      condition_xml)


class PriorityOverrideTimingModel(unittest.TestCase):
    """The real engine against the client/server timing model.

    Charged Chop as an override row, once a second. In the model the game
    refuses a send that comes before its one-second beat lowered the cooldown,
    while another skill's global cooldown runs or while a spell goes off, so a
    single send a second gets far fewer than 30. Resending until the game takes
    it wins most of them back. Press early, which reads the icon, still gets
    the most when other attacks with a global cooldown sit below it.
    """

    model = staticmethod(PressEarlyTimingModel.run_model)
    SINGLE = "Kitty.ComboManager.OVERRIDE_HOLD = 0"
    WARDEN = {"Charged Chop": (1, 0), "Savage Whirlwind": (7, 1), "Probing Attack": (5, 1),
              "Open Flank": (5, 1), "Thunder": (14, 1)}
    LOWER = ("Savage Whirlwind", "Probing Attack", "Open Flank", "Thunder")

    def chops(self, rows, press, ping, cooldown=None, setup="", seeds=4):
        runs = [self.model(rows, press, ping, seed, cooldown, setup=setup) for seed in range(seeds)]
        chops = [casts["Charged Chop"] for casts, _ in runs]
        others = [sum(casts.values()) - casts["Charged Chop"] for casts, _ in runs]
        return statistics.mean(chops), statistics.mean(others)

    def test_resending_gets_charged_chop_close_to_once_a_second(self):
        # Charged Chop with its own 1 s global cooldown above a filler skill
        rows = ['row("Filler")', override_row("Charged Chop", "1")]
        for press in (0.1, 0.2):
            for ping in (0.03, 0.25):
                with self.subTest(press=press, ping=ping):
                    resent, _ = self.chops(rows, press, ping)
                    single, _ = self.chops(rows, press, ping, setup=self.SINGLE)
                    strict, _ = self.chops([STRICT, 'row("Filler")'], press, ping)
                    self.assertGreaterEqual(resent, 27)
                    self.assertGreater(resent, single + 2)
                    self.assertGreater(resent, strict + 6)

    def test_with_attacks_below_it_beats_waiting_for_the_icon_but_not_press_early(self):
        lower = [ready_row(name) for name in self.LOWER]
        rows = lower + [override_row("Charged Chop", "1")]
        totals = {"resent": [], "single": [], "strict": [], "early": [], "others": []}
        for press in (0.1, 0.2):
            for ping in (0.03, 0.1):
                resent, others = self.chops(rows, press, ping, self.WARDEN)
                totals["resent"].append(resent)
                totals["others"].append(others)
                totals["single"].append(self.chops(rows, press, ping, self.WARDEN, self.SINGLE)[0])
                totals["strict"].append(self.chops([STRICT] + lower, press, ping, self.WARDEN)[0])
                totals["early"].append(self.chops([EARLY] + lower, press, ping, self.WARDEN)[0])
        mean = {key: statistics.mean(values) for key, values in totals.items()}
        self.assertGreater(mean["resent"], mean["single"] + 3, mean)
        self.assertGreater(mean["resent"], mean["strict"] + 2, mean)
        self.assertGreater(mean["early"], mean["resent"], mean)
        self.assertGreaterEqual(mean["others"], 12, mean)


if __name__ == "__main__":
    unittest.main()
