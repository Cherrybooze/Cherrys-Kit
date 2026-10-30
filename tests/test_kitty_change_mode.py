"""Change-mode commands, editable owned guards, native editor callbacks and read-only prediction."""
import unittest
import xml.etree.ElementTree as ET

import test_kitty_startup


class ChangeModeTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()
        self.lua.execute('''
          Kitty.sendMessage=function() end
          Kitty.debugPrint=function() end
          Kitty.isTurnedOff=function() return false end
          Kitty.getTime=function() return 100 end
          Kitty.Modes={heal=true}
          Kitty.SettingManager.setting={mode={names={},current="heal"},basic={},command={}}
          Kitty.SkillManager.fetchSkill=function(name)
            return {isAvailable=true,isSuitSkill=false,remaining=0,texture="skill-icon"}
          end
          Kitty.slotManager={}; Kitty.macroManager={}; Kitty.cooldownManager=Kitty.CooldownManager()
          function modeTestWidget(name,text)
            local w={name=name,text=text or "",visible=true,checked=true}
            function w:GetName() return self.name end
            function w:GetID() return self.id or 1 end
            function w:GetText() return self.text end
            function w:SetText(text) self.text=text end
            function w:SetFile(file) self.file=file end
            function w:SetChecked(v) self.checked=v end
            function w:IsChecked() return self.checked end
            function w:Show() self.visible=true end
            function w:Hide() self.visible=false end
            function w:IsVisible() return self.visible end
            _G[name]=w; return w
          end
          getglobal=function(name) return _G[name] end
          UIDropDownMenu_GetText=function(w) return w.text end
          UIDropDownMenu_SetText=function(w,text) w.text=text end
        ''')

    def test_dispatch_switches_once_then_continues_without_casting_a_skill(self):
        self.lua.execute('''
          local change={}
          assert(Kitty.ModeUI.configureCommand(change,"Boss"))
          local commands={change,{commandType="skill",commandName="Ready",{conditionType="modeOn",{name="boss"}}}}
          local manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          local kind,name=manager:check(commands)
          assert(kind=="changemode" and name=="boss")
          manager.skillManager.cast=function() error("mode dispatch cast a skill") end
          manager:cast(kind,name)
          assert(Kitty.Modes.boss==true and Kitty.Modes.heal==false)
          assert(Kitty.ModeUI.setting().current=="boss")
          assert(Kitty.cooldownManager.skillTable.boss==nil)
          kind,name=manager:check(commands)
          assert(kind=="skill" and name=="Ready")
        ''')

    def test_generated_guard_is_editable_retargeted_once_and_keeps_manual_conditions(self):
        self.lua.execute('''
          local command={{conditionType="modeOn",{name="aoe",value=true}}}
          Kitty.ModeUI.configureCommand(command,"boss")
          assert(#command==2 and command[2][1].value==false and command[2][1].name=="boss")
          command[2][1].value=true
          Kitty.ModeUI.configureCommand(command,"heal")
          Kitty.ModeUI.configureCommand(command,"heal")
          assert(#command==2 and command[1][1].name=="aoe")
          assert(command[2][1].name=="heal" and command[2][1].value==true)
          assert(command.icon==Kitty.ModeUI.iconPath("heal"))
          Kitty.ModeUI.clearCommandGuard(command)
          assert(#command==1 and command[1][1].name=="aoe")
        ''')

    def test_missing_mode_names_skip_cleanly_and_disabled_rows_stay_disabled(self):
        self.lua.execute('''
          local manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          for _,name in ipairs({"","  ",false,17}) do
            local typ,chosen=manager:check({{commandType="changemode",commandName=name},
              {commandType="skill",commandName="Ready"}})
            assert(typ=="skill" and chosen=="Ready")
          end
          local change={}; Kitty.ModeUI.configureCommand(change,"boss"); change.enable=false
          assert(manager:check({change})==nil)
          assert(Kitty.Modes.heal==true and not Kitty.Modes.boss)
        ''')

    def test_prediction_simulates_mode_changes_without_touching_live_modes_or_settings(self):
        self.lua.execute('''
          local change={}; Kitty.ModeUI.configureCommand(change,"boss")
          local list={info={name="Switch",class="any",target="all"},change,
            {commandType="skill",commandName="BossSkill",{conditionType="modeOn",{name="boss"}}},
            {commandType="skill",commandName="OtherSkill",{conditionType="modeOn",{name="heal"}}}}
          Kitty.SettingManager.setting.command={list}
          local prediction=Kitty.Predict.compute("Switch",3)
          assert(prediction[1].type=="changemode" and prediction[1].name=="boss")
          assert(prediction[1].icon==Kitty.ModeUI.iconPath("boss"))
          assert(prediction[2].name=="BossSkill" and prediction[3]==nil)
          assert(Kitty.Modes.heal==true and Kitty.Modes.boss==nil)
          assert(Kitty.ModeUI.setting().current=="heal" and #Kitty.ModeUI.setting().names==0)
          assert(Kitty.cooldownManager.skillTable.BossSkill==nil)
          assert(Kitty.Predict.LOOKAHEAD==1.1 and Kitty.SkillManager.EXECUTION_TOLERANCE==0.2)
        ''')

    def test_all_share_formats_keep_mode_icon_guard_and_guard_editor_split_merge(self):
        self.lua.execute('''
          local command={}; Kitty.ModeUI.configureCommand(command,"boss")
          command.icon="foreign-install-mode-icon"
          local list={info={name="Modes",class="any",target="all"},command}
          for _,code in ipairs({Kitty.Share.exportCommandListV1(list),Kitty.Share.exportCommandListV2(list),Kitty.Share.exportCommandList(list)}) do
            local imported=assert(Kitty.Share.importCommandList(code))
            assert(imported[1].commandType=="changemode" and imported[1].icon==Kitty.ModeUI.iconPath("boss"))
            local split=Kitty.CommandConditionFrame.separate(imported[1])
            assert(split[1].modeActionGuard==true and split[1].value==false)
            split[1].value=nil
            local merged=Kitty.CommandConditionFrame.merge(split)
            Kitty.ModeUI.configureCommand(merged,"heal")
            assert(#merged==1 and merged[1][1].name=="heal" and merged[1][1].value==nil)
          end
        ''')

    def editor(self):
        self.lua.execute('''
          local F=Kitty.CommandConfigFrame
          original={info={name="Modes",class="any",target="all"},{commandType="skill",commandName="Ready",icon="original"}}
          Kitty.SettingManager.setting.command={original}
          F.targetCommandList=Kitty.copyTable(original); F.allowUpdateData=true
          row=modeTestWidget("ModeRow")
          for _,suffix in ipairs({"CheckButton","ActionButtonIcon","DropDownMenu","CommandNameEditBox","CommandDropDownMenu","ModeButton","ConditionButton"}) do
            modeTestWidget("ModeRow"..suffix)
          end
          ModeRowDropDownMenu.text="changemode"; ModeRowCommandNameEditBox.text="Ready"
          modeTestWidget("KittyCommandConfigFrame_CommandListNameEditBox","Modes")
          modeTestWidget("KittyCommandConfigFrame_BuildDropDownMenu","any")
          modeTestWidget("KittyCommandConfigFrame_TargetDropDownMenu","all")
          KittyCommandConfigFrame=modeTestWidget("KittyCommandConfigFrame")
          scrollValue=1
          KittyCommandConfigFrame_ScrollBar={GetValue=function() return scrollValue end}
          F.onShowList=function() F.showDetail(row,F.targetCommandList[1],1,1) end
          Kitty.ModeUI.openPicker=function(anchor,callback,current,includeNone)
            pickerCallback,pickerAnchor,pickerCurrent=callback,anchor,current
            assert(includeNone==false); return true
          end
        ''')

    def test_type_selection_opens_mode_icons_and_changes_only_the_editor_draft(self):
        self.editor()
        self.lua.execute('''
          local F=Kitty.CommandConfigFrame
          F.onTypeChanged(row)
          assert(type(pickerCallback)=="function")
          assert(F.targetCommandList[1].commandType=="changemode" and F.targetCommandList[1].commandName=="")
          assert(ModeRowModeButton.visible and not ModeRowCommandNameEditBox.visible and not ModeRowCommandDropDownMenu.visible)
          pickerCallback("boss")
          local command=F.targetCommandList[1]
          assert(command.commandName=="boss" and command[1][1].value==false)
          assert(ModeRowActionButtonIcon.file==Kitty.ModeUI.iconPath("boss"))
          assert(original[1].commandType=="skill" and original[1].commandName=="Ready")
          assert(Kitty.Modes.heal==true and Kitty.Modes.boss==nil)
          F.openModePicker(row)
          scrollValue=2
          pickerCallback("heal")
          assert(command.commandName=="boss","recycled row accepted a stale picker callback")
          scrollValue=1; F.close(); pickerCallback("heal")
          assert(command.commandName=="boss")
        ''')

    def test_native_type_menu_exposes_changemode_as_a_top_level_action_and_keeps_owner(self):
        root = ET.parse(test_kitty_startup.KITTY / "gui/KittyCommandConfigFrame.xml").getroot()
        node = root.find(".//ui:Frame[@name='$parentDropDownMenu']/ui:Scripts/ui:OnLoad", test_kitty_startup.NS)
        self.lua.execute('''
          owner={GetParent=function() return "correct-row" end}; this=owner
          Kitty.protectFunction=function(fn) return fn end
          Kitty.DropDown=function() return {setListData=function(_,fn,l1,l2) menuCallback,menuChoices=fn,l1 end} end
          Kitty.CommandConfigFrame.onTypeChanged=function(row) updated=row end
        ''')
        self.lua.execute(node.text)
        self.lua.execute('''
          local found=false
          for _,choice in ipairs(menuChoices) do
            if choice=="changemode" or type(choice)=="table" and choice.value=="changemode" then found=true end
          end
          assert(found,"Change kitty mode is absent from the main action menu")
          this={GetParent=function() error("menu entry used as owner") end}
          menuCallback(owner,{},"changemode","changemode")
          assert(updated=="correct-row")
        ''')

    def test_two_unconditional_mode_rows_cannot_flip_the_mode_on_every_press(self):
        self.lua.execute('''
          clock=100; Kitty.getTime=function() return clock end
          Kitty.Modes={}; Kitty.ModeUI.setting().current=nil; Kitty.ModeUI.switchedAt=nil
          local aoe,single={},{}
          Kitty.ModeUI.configureCommand(aoe,"aoe"); Kitty.ModeUI.configureCommand(single,"single")
          local commands={aoe,single,{commandType="skill",commandName="Ready"}}
          local manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          manager.skillManager.cast=function() end
          fired={}
          for press=1,8 do
            local kind,name=manager:check(commands)
            manager:cast(kind,name)
            fired[press]=kind=="changemode" and name or kind
            clock=clock+0.3
          end
        ''')
        fired = list(self.lua.globals().fired.values())
        # Presses come every 0.3 s: a switch holds the other mode row for 1 s.
        self.assertEqual(fired, ["aoe", "skill", "skill", "skill", "single", "skill", "skill", "skill"])

    def test_mode_row_without_its_guard_does_not_use_presses_once_its_mode_is_on(self):
        self.lua.execute('''
          clock=100; Kitty.getTime=function() return clock end
          local change={}; Kitty.ModeUI.configureCommand(change,"boss"); Kitty.ModeUI.clearCommandGuard(change)
          assert(#change==0)
          local commands={change,{commandType="skill",commandName="Ready"}}
          local manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          local kind,name=manager:check(commands); manager:cast(kind,name)
          assert(kind=="changemode" and Kitty.Modes.boss==true and Kitty.Modes.heal==false)
          clock=clock+5
          kind,name=manager:check(commands)
          assert(kind=="skill" and name=="Ready","a switch to the only mode on used up a press")
          Kitty.Modes.heal=true
          kind,name=manager:check(commands)
          assert(kind=="changemode","another mode is on, so the switch still has work to do")
          clock=clock+5; Kitty.ModeUI.set("heal",true)
          assert(manager:check(commands)=="changemode","a manual switch does not hold kitty rows")
        ''')

    def test_prediction_mirrors_the_switch_hold(self):
        self.lua.execute('''
          clock=100; Kitty.getTime=function() return clock end
          Kitty.Modes={}; Kitty.ModeUI.setting().current=nil; Kitty.ModeUI.switchedAt=nil
          local aoe,single={},{}
          Kitty.ModeUI.configureCommand(aoe,"aoe"); Kitty.ModeUI.configureCommand(single,"single")
          local list={info={name="Flip",class="any",target="all"},aoe,single,
            {commandType="skill",commandName="Ready"},{commandType="skill",commandName="Other"}}
          Kitty.SettingManager.setting.command={list}
          local prediction=Kitty.Predict.compute("Flip",3)
          assert(prediction[1].type=="changemode" and prediction[1].name=="aoe")
          assert(prediction[2].name=="Ready" and prediction[3].name=="Other","prediction flipped the mode back")
          assert(next(Kitty.Modes)==nil)
          Kitty.ModeUI.kittySwitch("aoe")
          prediction=Kitty.Predict.compute("Flip",1)
          assert(prediction[1].name=="Ready","prediction ignored a live switch hold")
          clock=clock+1
          prediction=Kitty.Predict.compute("Flip",1)
          assert(prediction[1].type=="changemode" and prediction[1].name=="single")
        ''')

    def test_save_warns_about_mode_rows_that_take_turns(self):
        self.lua.execute('''
          sent={}; Kitty.sendMessage=function(text) table.insert(sent,text) end
          local function row(name,extra)
            local command={}; Kitty.ModeUI.configureCommand(command,name)
            if extra then table.insert(command,1,extra) end
            return command
          end
          local enemies={conditionType="playerHealth",{threshold=50}}
          assert(Kitty.ModeUI.loopingModes({row("aoe"),row("single")})[2]=="single")
          assert(Kitty.ModeUI.loopingModes({row("aoe"),row("single",enemies)})==nil)
          assert(Kitty.ModeUI.loopingModes({row("aoe"),row("aoe")})==nil)
          local off=row("single"); off.enable=false
          assert(Kitty.ModeUI.loopingModes({row("aoe"),off})==nil)
          local F=Kitty.CommandConfigFrame
          Kitty.componentToSetting=function() end
          F.allCommandList={}; F.targetCommandListIndex=0
          F.targetCommandList={info={name="Flip"},row("aoe"),row("single")}
          F.save()
          assert(#sent==1 and string.find(sent[1],"aoe, single",1,true),tostring(sent[1]))
          F.targetCommandList={info={name="Fine"},row("aoe"),row("single",enemies)}
          F.save()
          assert(#sent==1)
        ''')

    def test_scrolling_the_editor_closes_its_mode_picker(self):
        self.lua.execute("showList=Kitty.CommandConfigFrame.onShowList")
        self.editor()
        self.lua.execute('''
          local F=Kitty.CommandConfigFrame
          for i=1,10 do modeTestWidget("KittyCommandConfigFrame_Button"..i) end
          local slider={value=1}
          function slider:GetValue() return self.value end
          function slider:SetMinMaxValues(a,b) self.min,self.max=a,b end
          function slider:GetMinMaxValues() return self.min,self.max end
          F.targetCommandList={info={name="Modes"}}
          closed=0
          Kitty.ModeUI.closeFlyout=function() closed=closed+1; Kitty.ModeUI.pickHandler=nil end
          Kitty.ModeUI.openPicker=function(anchor,callback) Kitty.ModeUI.pickHandler=callback; return true end
          F.targetCommandList[1]={commandType="changemode",commandName=""}
          F.openModePicker(row)
          F.targetCommandList[1]=nil
          showList(slider,1,10)
          assert(closed==0,"a redraw at the same scroll closed the picker")
          slider.value=2; showList(slider,2,10)
          assert(closed==1 and Kitty.ModeUI.pickHandler==nil)
          slider.value=1; showList(slider,1,10)
          assert(closed==1)
        ''')

    def test_ready_window_command_is_saved_checked_and_reset(self):
        self.lua.execute('''
          sent={}; Kitty.sendMessage=function(text) table.insert(sent,text) end
          local S=Kitty.SkillManager
          SlashCmdList["KittyCombo"](nil,"window 0.6")
          assert(S.EXECUTION_TOLERANCE==0.6 and Kitty.SettingManager.setting.basic.readyWindow==0.6)
          assert(string.find(sent[#sent],"0.6 s",1,true))
          S.EXECUTION_TOLERANCE=0.2
          assert(S.applyReadyWindow()==0.6 and S.EXECUTION_TOLERANCE==0.6)
          assert(S.readyWindowCommand("5")==false and S.EXECUTION_TOLERANCE==0.6)
          assert(S.readyWindowCommand("abc")==false and Kitty.SettingManager.setting.basic.readyWindow==0.6)
          S.readyWindowCommand("default")
          assert(S.EXECUTION_TOLERANCE==0.2 and Kitty.SettingManager.setting.basic.readyWindow==nil)
          Kitty.SettingManager.setting.basic.readyWindow="junk"
          assert(S.applyReadyWindow()==0.2)
          S.readyWindowCommand("")
          assert(string.find(sent[#sent],"0.2 s",1,true))
        ''')

    def test_condition_editor_keeps_guard_ownership_when_only_on_off_changes(self):
        self.lua.execute('''
          local C=Kitty.CommandConditionFrame
          C.targetConditionList={{conditionType="modeOn",name="boss",value=false,modeActionGuard=true}}
          row=modeTestWidget("ConditionRow")
          for _,suffix in ipairs({"DropDownMenu","EffectTypeDropDownMenu","ConditionDropDownMenu","ConditionValueEditBox",
            "ConditionThresholdEditBox","MinEditBox","MaxEditBox","BooleanDropDownMenu","ActionDropDownMenu",
            "BuildDropDownMenu","WeakAuraDropDownMenu","WeakAuraFieldDropDownMenu","WeakAuraMinEditBox","WeakAuraMaxEditBox","ModeDropDownMenu"}) do
            modeTestWidget("ConditionRow"..suffix)
          end
          ConditionRowDropDownMenu.text=Kitty.ComboManager.conditionLabel("modeOn")
          ConditionRowModeDropDownMenu.text="boss"; ConditionRowBooleanDropDownMenu.text="on"
          KittyCommandConditionFrame_ScrollBar={GetValue=function() return 1 end}
          C.updateData(row)
          assert(C.targetConditionList[1].modeActionGuard==true and C.targetConditionList[1].value==nil)
          ConditionRowModeDropDownMenu.text="manual"
          C.updateData(row)
          assert(C.targetConditionList[1].modeActionGuard==nil,"a manually renamed guard stayed auto-owned")
        ''')


if __name__ == "__main__":
    unittest.main()
