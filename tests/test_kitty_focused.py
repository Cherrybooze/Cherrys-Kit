"""Focused KittyCombo execution and draft regressions using its Lua 5.1 loader."""
import test_kitty_startup
import unittest
import xml.etree.ElementTree as ET

class KittyFocusedTests(unittest.TestCase):
    def setUp(self):
        self.lua = test_kitty_startup.KittyStartupTests().runtime()

    def test_prediction_cooldowns_and_cast_throttle(self):
        self.lua.execute('''
          now=10; Kitty.getTime=function() return now end
          Kitty.isTurnedOff=function() return false end
          UnitCastingTime=function() return 3 end
          Kitty.CooldownManager.cooldownTable.Tracked={skilltype='CastingSpell', cooldown=2}
          Kitty.cooldownManager=Kitty.CooldownManager()
          Kitty.cooldownManager.skillTable.Tracked={timestamp=9,cooldown=2}
          Kitty.SkillManager.fetchSkill=function(name)
            if name=='Tracked' then return {isAvailable=true,isSuitSkill=false,remaining=0,texture='icon'} end
          end
          Kitty.slotManager={}; Kitty.macroManager={}
          Kitty.SettingManager.setting={command={{info={name='Test',class='any',target='all'}, {commandType='skill',commandName='Tracked'}}}}
          manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          assert(manager:check(Kitty.SettingManager.setting.command[1]) == nil)
          prediction=Kitty.Predict.next('Test',1)
          assert(prediction[1].name=='Tracked')
          assert(Kitty.cooldownManager.skillTable.Tracked ~= nil)
          assert(manager:check(Kitty.SettingManager.setting.command[1]) == nil)
          assert(manager:canCast({{name='Tracked',threshold=5}}))
          assert(manager:canCast({{name='Tracked',threshold=0,value=false}}))
          assert(not manager:canCast({{name='Tracked',threshold=5,value=false}}))
          Kitty.cooldownManager.skillTable.Tracked=nil
          Kitty.SkillManager.manaList.Tracked=100; Kitty.ClassManager.getMana=function() return 0 end
          assert(not manager:canCast({{name='Tracked',threshold=0,value=false}}))
          Kitty.SkillManager.manaList.Tracked=nil
          Kitty.cooldownManager.skillTable.Tracked={timestamp=9,cooldown=2}
          now=20
          local old=Kitty.Predict.compute
          Kitty.Predict.compute=function() return {{name='changed'}} end
          assert(Kitty.Predict.next('Test',1)[1].name=='changed')
          assert(Kitty.cooldownManager.skillTable.Tracked ~= nil)
          Kitty.Predict.compute=old
          Kitty.cooldownManager.skillTable.Macro={timestamp=0,cooldown=1}
          Kitty.macroManager.canExecute=function() return true end
          Kitty.SettingManager.setting.command[1]={{commandType='macro',commandName='Macro'},info={name='Test'}}
          assert(Kitty.Predict.compute('Test',1)[1].name=='Macro')
          assert(Kitty.cooldownManager.skillTable.Macro ~= nil)
        ''')

    def test_prediction_matches_execution_in_proc_cycle(self):
        self.lua.execute('''
          Kitty.sendMessage=function() end
          Kitty.SkillManager.fetchSkill=function(name)
            return {isAvailable=true,isSuitSkill=false,remaining=0,texture=name}
          end
          Kitty.slotManager={}; Kitty.macroManager={}; Kitty.cooldownManager=Kitty.CooldownManager()
          Kitty.SettingManager.setting={command={
            {info={name='A',class='any',target='all'}, {commandType='proc',commandName='B'}, {commandType='skill',commandName='Skill-A'}},
            {info={name='B',class='any',target='all'}, {commandType='proc',commandName='A'}, {commandType='skill',commandName='Skill-B'}}}}
          local manager=Kitty.ComboManager(Kitty.slotManager,Kitty.cooldownManager,Kitty.macroManager)
          local typ,name=manager:check(Kitty.Predict.findKitty('A'))
          assert(typ=='skill' and name=='Skill-B')
          assert(Kitty.Predict.compute('A',1)[1].name==name)
        ''')

    def test_share_and_editor_population(self):
        self.lua.execute('''
          list={info={name='Import',class='D',target='boss'},
            {commandType='macro',commandName='Test',icon='macro-icon', {conditionType='newerUnknown'}}}
          code=Kitty.Share.exportCommandList(list)
          assert(string.sub(code,1,5)=='CKC3!')
          local invalid, reason=Kitty.Share.importCommandList(code)
          assert(invalid==nil and string.find(reason,'newerUnknown',1,true))
          list[1][1]={conditionType='modeOn',{name='aoe',threshold=0}}
          local codes={Kitty.Share.exportCommandListV1(list), Kitty.Share.exportCommandListV2(list), Kitty.Share.exportCommandList(list)}
          for _, supported in ipairs(codes) do
            local imported=assert(Kitty.Share.importCommandList(supported))
            assert(imported[1].icon=='macro-icon' and imported[1][1].conditionType=='modeOn')
          end
          local result=assert(Kitty.Share.importCommandList(codes[3]))
          Kitty.CommandConfigFrame.allowUpdateData=true
          visible={name='old',class='OLD_CLASS',target='OLD_TARGET'}
          Kitty.settingToComponent=function(info)
            visible.name=info.name; Kitty.CommandConfigFrame.updateData()
            visible.class=info.class; visible.target=info.target
          end
          Kitty.CommandConfigFrame.onRedraw=function() end
          Kitty.CommandConfigFrame.refreshExport=function() end
          Kitty.CommandConfigFrame.refreshMacro=function() end
          KittyCommandConfigFrame={Show=function() end}
          KittyCommandConfigFrame_ImportEditBox={GetText=function() return code2 end, SetText=function() end}
          Kitty.sendMessage=function() end
          Kitty.CommandConfigFrame.open({result},1,function() end)
          local draft=Kitty.CommandConfigFrame.targetCommandList
          assert(draft.info.name==visible.name and draft.info.class==visible.class and draft.info.target==visible.target)
          list.info.class='M'; list.info.target='all'; code2=Kitty.Share.exportCommandList(list)
          Kitty.CommandConfigFrame.importCode()
          draft=Kitty.CommandConfigFrame.targetCommandList
          assert(draft.info.name==visible.name and draft.info.class==visible.class and draft.info.target==visible.target)
          assert(draft.info.class=='M' and draft.info.target=='all')
          assert(Kitty.CommandConfigFrame.allowUpdateData==true)
          Kitty.CommandConfigFrame.allowUpdateData=false
          Kitty.settingToComponent=function() error('widget failed') end
          assert(not pcall(Kitty.CommandConfigFrame.populateInfo,result.info))
          assert(Kitty.CommandConfigFrame.allowUpdateData==false)
          local names={{info={name='Cat'}},{info={name='Cat_copy'}}}
          assert(Kitty.CommandConfigFrame.copyName('Cat_copy',names)=='Cat_copy_001')
        ''')

    def test_priority_procs_and_conditions(self):
        self.lua.execute('''
          Kitty.SettingManager.setting={command={{info={name='Damage'}},{info={name='Heal'}}}}
          local ordered=Kitty.ComboManager.selectCommandListByName({'Heal','Damage'})
          assert(ordered[1].info.name=='Heal' and ordered[2].info.name=='Damage')
          Kitty.sendMessage=function() warnings=(warnings or 0)+1 end; Kitty.getTime=function() return 5 end
          local a={info={name='A'},{commandType='proc',commandName='B'},{commandType='break',commandName='fallback'}}
          local b={info={name='B'},{commandType='proc',commandName='A'}}
          local m=setmetatable({findProc=function(self,n) return n=='A' and {a} or {b} end}, {__index=Kitty.ComboManager})
          local typ,name=m:check(a); assert(typ=='break' and name=='fallback' and warnings==1)
          UnitDebuff=function(unit,i) if i==1 then return 'A',nil,nil,11 end end
          UnitDebuffLeftTime=function() return 4 end
          assert(not m:targetEffectCounter({{effectType='name',name='A',threshold=1},{effectType='name',name='B',threshold=1}}))
          assert(not m:targetEffectCounter({{effectType='name',name='A',threshold=2},{effectType='name',name='A',threshold=2}}))
          m.skillManager={canCast=function(_,name,t) return t==5 end, isOnCooldown=function() return false end}
          assert(m:canCast({{name='skill',threshold=5}}))
          assert(not m:canCast({{name='missing',threshold=5,value=false}}))
        ''')

    def test_build_dropdown_uses_callback_owner(self):
        path = test_kitty_startup.KITTY / 'gui' / 'KittyCommandConditionFrame.xml'
        root = ET.parse(path).getroot()
        ns = {'ui': 'http://www.runewaker.com/'}
        frame = root.find(".//ui:Frame[@name='$parentBuildDropDownMenu']/ui:Scripts/ui:OnLoad", ns)
        self.assertIsNotNone(frame)
        self.lua.execute("""
          Kitty.protectFunction=function(fn) return fn end
          Kitty.BuildManager.getGroupedList=function() return {A={'D'}} end
          Kitty.DropDown=function(owner) return {setListData=function(_,callback) menuCallback=callback end} end
          Kitty.CommandConditionFrame.updateData=function(row) updated=row end
          row={}; owner={GetParent=function() return row end}; this=owner
        """)
        self.lua.execute(frame.text)
        self.lua.execute("this={GetParent=function() error('menu entry used as owner') end}; menuCallback(owner,{})")
        self.assertTrue(self.lua.eval('updated==row'))

    def test_slots_macros_and_draft_modes(self):
        self.lua.execute('''
          assert(not Kitty.Macro.isKittyBody('/run Kitty.attack("other"); print("target")','target'))
          assert(Kitty.Macro.isKittyBody('/run Kitty.attack("other", "target")','target'))
          assert(not Kitty.Macro.isKittyBody('/run Kitty.attack(getName(), "target")','target'))
          names={[1]='Potion',[2]='Potion'}
          GetActionInfo=function(i) if names[i] then return 'icon' end end
          Kitty.SlotManager.getActionName=function(_,i) return names[i] end
          GetActionCooldown=function() return 10,2 end
          local slots=Kitty.SlotManager(); assert(slots:getIndex('Potion')==2)
          names[2]=nil; slots:onUpdate(2)
          assert(slots:getIndex('Potion')==1 and slots:canUse('Potion',5))
          assert(not slots:isOnCooldown('missing',0) and slots:isOnCooldown('Potion',1))
          Kitty.SettingManager.setting={command={},mode={names={},hidden={}}}
          Kitty.CommandConfigFrame.targetCommandList={{ {conditionType='modeOn', {name='draftmode'}} }}
          local found=false
          for _,n in ipairs(Kitty.ModeUI.names()) do if n=='draftmode' then found=true end end
          assert(found)
          for _,n in ipairs(Kitty.ModeUI.setting().names) do assert(n~='draftmode') end
          Kitty.CommandListFrame.allCommandList={Kitty.CommandConfigFrame.targetCommandList}
          Kitty.CommandConfigFrame.targetCommandList=nil
          found=false; for _,n in ipairs(Kitty.ModeUI.names()) do if n=='draftmode' then found=true end end
          assert(found and #Kitty.ModeUI.setting().names==0)
          Kitty.ModeUI.refresh=function() end
          Kitty.CommandListFrame.save()
          found=false; for _,n in ipairs(Kitty.ModeUI.setting().names) do if n=='draftmode' then found=true end end
          assert(found)
          Kitty.clearGameTooltip=function() end
          local tooltip={SetExtraActionItem=function() end,Hide=function() end,GetName=function() return 'TestTip' end}
          TestTipTextLeft1={GetText=function() return nil end}
          assert(Kitty.ExtraActionManager.getExtraActionName(tooltip,1)==nil)
        ''')

if __name__ == '__main__': unittest.main()
