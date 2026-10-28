"""Resource compositions, fixed frames and exact PSI/Max behavior."""
import unittest
import test_rwa as support

class ResourceDisplayTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests();self.h.setUp();self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua;self.rwa=self.lua.globals().RWA
        if not self.rwa.MEDIA or not self.rwa.MEDIA.resources:self.h.load('MediaList.lua')
        if not self.rwa.Resources:self.h.load('Resources.lua')
        if not self.rwa.ResourceDisplays:self.h.load('ResourceDisplays.lua')
        self.lua.execute('''
          function resourceRegion(kind,style)
            local d={id="Display",regionType=kind=="psi" and "soulpoints" or "aurabar",resource=kind,
              width=260,height=kind=="psi" and 96 or 34,fontSize=24,text="%v / %t",text2="",barStyle=style or "metal",psiStyle="diamonds",showMax=true,showIcon=false}
            RWA.ApplyAuraDefaults(d)
            return RWA.Regions.Acquire(d),d
          end
          function updateResource(r,kind,mode,value)
            local s=RWA.Resources.Preview(kind,mode)
            if value~=nil then s.value=value;s.percent=value/s.total*100;s.showMax=RWA.Resources.MaxEligible(s.resource,s.available,s.value,s.total,s.inCombat,s.combatKnown) end
            r:SetState(s);r:Show();r:Update(fixtureNow);return s
          end
        ''')

    def test_psi_has_exact_pips_and_zero_is_only_number_in_both_presentations(self):
        self.lua.execute('r,d=resourceRegion("psi")')
        r=self.lua.globals().r
        self.assertEqual(len(r.pips),6)
        anchor=None
        for count in (0,1,2,3,4,5,6,5,3,1,0):
            self.lua.globals().updateResource(r,'psi','partial',count)
            self.assertEqual(r.text.obj.text,str(count))
            self.assertEqual(sum(p.IsVisible(p) for p in r.pips.values()),count)
            self.assertFalse(r.resourceArt.max.IsVisible(r.resourceArt.max))
            current=tuple(r.text.obj.anchor.values())
            self.assertTrue(anchor is None or current==anchor)
            anchor=current
            if count==0:
                self.assertFalse(r.bg.IsVisible(r.bg))
                self.assertFalse(r.fill.IsVisible(r.fill))
                self.assertFalse(r.resourceArt.frame.IsVisible(r.resourceArt.frame))
                self.assertTrue(all(not x.IsVisible(x) for x in r.resourceArt.edges.values()))
        self.lua.execute('d.psiStyle="bar";r:Layout(d)')
        for count in (0,2,6,0):
            self.lua.globals().updateResource(r,'psi','partial',count)
            self.assertEqual(sum(p.IsVisible(p) for p in r.pips.values()),0)
            self.assertEqual(r.text.obj.text,str(count))
            self.assertEqual(r.resourceArt.frame.IsVisible(r.resourceArt.frame),count>0)
            self.assertFalse(r.resourceArt.max.IsVisible(r.resourceArt.max))
            if count==0:
                self.assertFalse(r.bg.IsVisible(r.bg))
                self.assertFalse(r.fill.IsVisible(r.fill))
                self.assertTrue(all(not x.IsVisible(x) for x in r.resourceArt.edges.values()))
        self.lua.globals().updateResource(r,'psi','unavailable')
        self.assertFalse(r.shown)

    def test_normalized_max_policy_and_energy_combat_changes_at_same_value(self):
        for kind in ('mana','rage','focus','energy','psi'):
            r,d=self.lua.globals().resourceRegion(kind,'metal')
            self.lua.globals().updateResource(r,kind,'full')
            self.assertFalse(r.resourceArt.max.IsVisible(r.resourceArt.max))
            self.lua.globals().updateResource(r,kind,'combat')
            self.assertEqual(r.resourceArt.max.IsVisible(r.resourceArt.max),kind!='mana')
            self.lua.globals().updateResource(r,kind,'partial')
            self.assertFalse(r.resourceArt.max.IsVisible(r.resourceArt.max))
            self.lua.globals().updateResource(r,kind,'full')
            d.showMax=False;r.Layout(r,d)
            self.lua.globals().updateResource(r,kind,'full')
            self.assertFalse(r.resourceArt.max.IsVisible(r.resourceArt.max))
            self.lua.globals().updateResource(r,kind,'unavailable')
            self.assertFalse(r.shown)
            r.Release(r)

    def test_fixed_metal_frame_and_padded_fill_align_without_uv_crop(self):
        r,_=self.lua.globals().resourceRegion('rage','metal')
        frame=r.resourceArt.frame
        geometry=(frame.width,frame.height,tuple(frame.anchor.values()))
        meta=self.rwa.MEDIA.resources.bevelFill
        for value in (0,25,50,100,10):
            self.lua.globals().updateResource(r,'rage','partial',value)
            self.assertEqual((frame.width,frame.height,tuple(frame.anchor.values())),geometry)
            expected=int(r.barW*value/100+.5)
            self.assertEqual(r.lastFill,expected)
            if value:
                self.assertAlmostEqual(r.fill.width*meta.content.w,expected)
                self.assertAlmostEqual(r.fill.height*meta.content.h,r.barH)
                self.assertAlmostEqual(r.fill.x+r.fill.width*meta.content.x,r.barX)
                self.assertAlmostEqual(r.fill.y+r.fill.height*meta.content.y,r.barY)
            self.assertIsNone(r.fill.texCoord)
        self.assertEqual(tuple(frame.color.values()),(1,1,1))
        self.assertEqual(tuple(r.resourceArt.max.color.values()),(1,1,1))

    def test_style_switches_and_updates_reuse_controls_and_preserve_approved_diamond_aspect(self):
        r,d=self.lua.globals().resourceRegion('psi','metal')
        self.lua.globals().updateResource(r,'psi','partial',3)
        pip=r.pips[1];meta=self.rwa.MEDIA.resources.diamond
        ratio=(pip.width*meta.content.w)/(pip.height*meta.content.h)
        expected=(meta.width*meta.content.w)/(meta.height*meta.content.h)
        self.assertAlmostEqual(ratio,expected)
        self.assertEqual(tuple(pip.color.values()),(1,1,1))
        before=len(list(self.lua.globals().fixtureWidgets.keys()))
        for style in ('glass','minimal','metal','glass','metal'):
            d.psiStyle='bar';d.barStyle=style;r.Layout(r,d)
            for value in (0,1,6,3,0):self.lua.globals().updateResource(r,'psi','partial',value)
            d.psiStyle='diamonds';r.Layout(r,d)
            self.lua.globals().updateResource(r,'psi','full')
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),before)
        self.lua.execute('''
          local W=RWA.W
          local original={text=W.SetText,shown=W.SetShown,size=W.SetSize,point=W.SetPoint,format=RWA.Regions.FormatText}
          local calls
          W.SetText=function(...) calls.text=calls.text+1;return original.text(...) end
          W.SetShown=function(...) calls.shown=calls.shown+1;return original.shown(...) end
          W.SetSize=function(...) calls.size=calls.size+1;return original.size(...) end
          W.SetPoint=function(...) calls.point=calls.point+1;return original.point(...) end
          RWA.Regions.FormatText=function(...) calls.format=calls.format+1;return original.format(...) end
          local function reset() calls={text=0,shown=0,size=0,point=0,format=0} end
          for _,case in ipairs({{"psi","diamonds","zero"},{"psi","bar","zero"},{"rage","bar","partial"},{"energy","bar","full"}}) do
            reset()
            local region,def=resourceRegion(case[1],"metal");def.psiStyle=case[2];region:Layout(def)
            local state=RWA.Resources.Preview(case[1],case[3]);region:SetState(state);region:Show();region:Update(fixtureNow)
            local expected=region.text.obj:GetText()
            reset()
            for i=1,40 do region:Update(fixtureNow+i*.1) end
            assert(calls.text==0 and calls.shown==0 and calls.size==0 and calls.point==0 and calls.format==0,
              case[1].." unchanged renderer did work")
            region:Hide();region:Show();region:Update(fixtureNow+5)
            assert(region.text.obj:GetText()==expected and region.text.obj:IsVisible(),"text did not restore")
            reset();region:Update(fixtureNow+5.1)
            assert(calls.text==0 and calls.shown==0 and calls.size==0 and calls.point==0 and calls.format==0,"restored renderer did repeat work")
            -- The same observation table changes in place, as placement samples do.
            if case[1]=="energy" then
              RWA.Resources.Preview("energy","combat",state);region:Update(fixtureNow+6)
              assert(region.resourceArt.max:IsVisible(),"combat change did not show Max")
              RWA.Resources.Preview("energy","full",state);region:Update(fixtureNow+6.1)
              assert(not region.resourceArt.max:IsVisible(),"leaving combat retained Max")
            else
              state.value=1;state.percent=100/state.total;state.showMax=false;region:Update(fixtureNow+6)
              assert(string.find(region.text.obj:GetText(),"1",1,true),"mutable state change was missed")
            end
            region:Release()
          end
          W.SetText,W.SetShown,W.SetSize,W.SetPoint=original.text,original.shown,original.size,original.point
          RWA.Regions.FormatText=original.format
        ''')

    def test_resource_bar_pool_does_not_leave_frame_or_max_on_an_ordinary_bar(self):
        r,_=self.lua.globals().resourceRegion('rage','metal')
        self.lua.globals().updateResource(r,'rage','full')
        art=r.resourceArt
        r.Release(r)
        self.lua.execute('ordinary={id="Ordinary",regionType="aurabar",width=200,height=24};RWA.ApplyAuraDefaults(ordinary);bar=RWA.Regions.Acquire(ordinary)')
        bar=self.lua.globals().bar
        self.assertTrue(self.lua.eval('bar==r') if self.lua.globals().r else bar.frame.name==r.frame.name)
        self.assertFalse(art.frame.visible)
        self.assertFalse(art.max.visible)
        self.assertTrue(all(not x.visible for x in art.edges.values()))
        self.assertEqual(bar.text.obj.justify,'LEFT')
        self.assertEqual(bar.text2.obj.justify,'RIGHT')

    def test_psi_bar_zero_never_keeps_generic_icon_or_secondary_text(self):
        self.lua.execute('''
          local d={id="PSI bar",regionType="aurabar",resource="psi",barStyle="metal",showIcon=true,
            icon="Interface/Icons/fixture",width=240,height=30,text="%v",text2="%n"}
          RWA.ApplyAuraDefaults(d);iconBar=RWA.Regions.Acquire(d)
        ''')
        r=self.lua.globals().iconBar
        self.lua.globals().updateResource(r,'psi','partial')
        self.assertFalse(r.icon.IsVisible(r.icon))
        self.lua.globals().updateResource(r,'psi','zero')
        self.assertEqual(r.text.obj.text,'0')
        self.assertEqual(r.text2.obj.text,'')
        for texture in (r.icon,r.fill,r.bg,r.resourceArt.frame,r.resourceArt.max):
            self.assertFalse(texture.IsVisible(texture))

    def test_resource_preview_modes_are_detached_and_keep_zero_and_unavailable_consistent(self):
        self.h.load('Options.lua')
        self.lua.execute('''
          local d
          for _,candidate in ipairs(RWA.Resources.Defaults()) do if candidate.sources[1].resource=="psi" then d=candidate;break end end
          d.id="Preview PSI";RWA.AddAura(d);RWA.ToggleOptions();RWA.ShowEditor(d.id)
          RWA.Rules.Observe=function() error("resource sample observed live state") end
          RWA.Triggers.CompileCustom=function() error("resource sample ran custom code") end
          RWA.PlaySound=function() error("resource sample played sound") end
        ''')
        e=self.rwa.UnifiedEditor
        for mode in ('zero','partial','full','unavailable','combat'):
            e.scenario='resource-'+mode;e.previewPoll=None;e.UpdatePreview(100)
            region=e.previewRegions[1]
            self.assertEqual(region.shown,mode!='unavailable')
            if mode=='zero':
                self.assertEqual(region.text.obj.text,'0')
                self.assertEqual(sum(p.IsVisible(p) for p in region.pips.values()),0)
            if mode=='unavailable':self.assertIn('unavailable',e.previewMatch.text.lower())
        self.assertEqual(self.lua.globals().RWA_DB.auras['Preview PSI'].rules[1].actions[1].output.psiStyle,'diamonds')
        self.assertIsNone(self.lua.globals().RWA_DB.auras['Preview PSI'].rules[1].actions[1].output._resourceScale)

    def test_field_resource_type_changes_keep_bound_output_identity_and_styles(self):
        self.h.load('Options.lua')
        self.lua.execute('''
          local d=RWA.Resources.Defaults()[1];d.id="Resource edit";RWA.AddAura(d);RWA.ToggleOptions();RWA.ShowEditor(d.id)
          RWA.UnifiedEditor.RowClick(2,"extra")
        ''')
        e=self.rwa.UnifiedEditor
        e.PanelClick('option1')
        choice=next(b for b in e.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='rage')
        self.h.script(choice.name,'OnClick',key='LBUTTON')
        d=self.rwa.Editor.Get('Resource edit')
        self.assertEqual(d.sources[1].resource,'rage')
        self.assertEqual(d.rules[1].actions[1].output.resource,'rage')
        self.assertEqual(d.rules[1].actions[1].output.id,'o1')
        self.assertEqual(d.rules[1].actions[1].output.barStyle,'metal')

    def test_full_editor_samples_fit_the_separate_max_ornament(self):
        self.h.load('Options.lua')
        self.rwa.ToggleOptions()
        for kind,style in (('rage',None),('psi','diamonds'),('psi','bar')):
            self.lua.globals().kind=kind;self.lua.globals().style=style
            self.lua.execute('''
              local d
              for _,candidate in ipairs(RWA.Resources.Defaults()) do if candidate.sources[1].resource==kind then d=candidate;break end end
              if not d then d=RWA.Resources.Defaults()[1];d.sources[1].resource=kind;d.rules[1].actions[1].output.resource=kind end
              d.id="Fit "..kind..tostring(style)
              if style then d.rules[1].actions[1].output.psiStyle=style end
              RWA.AddAura(d);RWA.ShowEditor(d.id)
              RWA.UnifiedEditor.scenario="resource-full";RWA.UnifiedEditor.previewPoll=nil;RWA.UnifiedEditor.UpdatePreview(fixtureNow)
            ''')
            editor=self.rwa.UnifiedEditor
            r=editor.previewById[editor.previewPrepared.order[1]]
            label=r.resourceArt.max;content=self.rwa.MEDIA.resources.maxLabel.content
            self.assertFalse(label.IsVisible(label))
            editor.scenario='resource-combat';editor.previewPoll=None;editor.UpdatePreview(self.lua.globals().fixtureNow)
            right=r.frame.x-r.data.width/2+label.x+label.width*(content.x+content.w)
            self.assertTrue(label.IsVisible(label))
            self.assertLessEqual(right,editor.sections.preview.x+editor.sections.preview.width-4)

    def test_resource_picker_updates_implicit_binding_and_preserves_unrelated_explicit_source(self):
        self.h.load('Options.lua')
        self.lua.execute('''
          local d=RWA.Resources.Defaults()[1];d.id="Implicit edit"
          d.rules[1].actions[1].sourceId=nil
          local other=RWA.Rules.AddSource(d,{type="resource",resource="energy"})
          otherDisplay=RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=other,
            output={regionType="aurabar",resource="energy",barStyle="minimal"}}).output.id
          RWA.AddAura(d);RWA.ToggleOptions();RWA.ShowEditor(d.id);RWA.UnifiedEditor.RowClick(2,"extra")
        ''')
        e=self.rwa.UnifiedEditor;e.PanelClick('option1')
        choice=next(b for b in e.menu.buttons.values() if b.flowChoice and b.flowChoice.value=='rage')
        self.h.script(choice.name,'OnClick',key='LBUTTON')
        d=self.rwa.Editor.Get('Implicit edit')
        self.assertEqual(d.rules[1].actions[1].output.resource,'rage')
        self.assertIsNone(d.rules[1].actions[1].sourceId)
        self.assertEqual(d.rules[1].actions[2].output.resource,'energy')
        self.assertEqual(d.rules[1].actions[2].output.barStyle,'minimal')

    def test_pyramid_builds_bottom_three_then_two_then_one_with_stable_bottom_count(self):
        r,d=self.lua.globals().resourceRegion('psi','metal')
        meta=self.rwa.MEDIA.resources.diamond.content
        def box(pip):
            return (pip.x+pip.width*meta.x,pip.y+pip.height*meta.y,pip.width*meta.w,pip.height*meta.h)
        geometry=[box(r.pips[i]) for i in range(1,7)]
        self.assertAlmostEqual(geometry[0][1],geometry[1][1])
        self.assertAlmostEqual(geometry[1][1],geometry[2][1])
        self.assertAlmostEqual(geometry[3][1],geometry[4][1])
        self.assertGreater(geometry[0][1],geometry[3][1])
        self.assertGreater(geometry[3][1],geometry[5][1])
        self.assertAlmostEqual(geometry[5][0],geometry[1][0])
        self.assertAlmostEqual(geometry[3][0],(geometry[0][0]+geometry[1][0])/2)
        bottom=geometry[0][1]+geometry[0][3]/2
        self.assertAlmostEqual(r.text.obj.y,bottom)
        maximum=r.resourceArt.max;bounds=self.rwa.MEDIA.resources.maxLabel.content
        self.assertAlmostEqual(maximum.y+maximum.height*(bounds.y+bounds.h/2),bottom)
        before=len(list(self.lua.globals().fixtureWidgets.keys()))
        for count in range(7):
            self.lua.globals().updateResource(r,'psi','partial',count)
            self.assertEqual(sum(p.IsVisible(p) for p in r.pips.values()),count)
            self.assertEqual([box(r.pips[i]) for i in range(1,7)],geometry)
            self.assertAlmostEqual(r.text.obj.y,bottom)
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),before)
        width,height,right=self.rwa.ResourceDisplays.Measure(d)
        self.assertEqual((width,height),(d.width,d.height))
        self.assertAlmostEqual(right,maximum.x+maximum.width*(bounds.x+bounds.w))
        self.assertLessEqual(maximum.y+maximum.height*(bounds.y+bounds.h),d.height+.001)
        d.psiLayout='row';r.Layout(r,d)
        row=[box(r.pips[i]) for i in range(1,7)]
        self.assertTrue(all(abs(p[1]-row[0][1])<.001 for p in row))

    def test_dynamic_resource_palette_updates_without_rebuilding_and_manual_override_wins(self):
        self.lua.execute('''
          primaryType,secondaryType=1,4
          UnitManaType=function() return primaryType end;UnitSkillType=function() return secondaryType end
          UnitMana=function() return 40 end;UnitMaxMana=function() return 100 end
          UnitSkill=function() return 70 end;UnitMaxSkill=function() return 100 end
          GetPlayerCombatState=function() return false end
          local d=RWA.Resources.Defaults()[1]
          local def=d.rules[1].actions[1].output
          assert(def.resource=="upper" and def.autoResourceColor)
          local region=RWA.Regions.Acquire(def)
          local prepared=RWA.Rules.PrepareActions(d)
          local function paint()
            RWA.Resources.Invalidate()
            local snapshot=RWA.Rules.Observe(d,fixtureNow,{})
            local result=RWA.Rules.Evaluate(d,snapshot,true,prepared)
            region:SetState(snapshot.s1);region:SetColor(result.outputs.o1.color);region:Show();region:Update(fixtureNow)
          end
          paint()
          paletteRegion,paletteDef,paletteData,palettePrepared,paintResource=region,def,d,prepared,paint
        ''')
        region=self.lua.globals().paletteRegion
        self.assertEqual(list(region.fill.color.values()),list(self.rwa.Resources.COLORS.mana.values())[:3])
        before=len(list(self.lua.globals().fixtureWidgets.keys()))
        self.lua.execute('primaryType=2;secondaryType=3;paintResource()')
        self.assertEqual(list(region.fill.color.values()),list(self.rwa.Resources.COLORS.rage.values())[:3])
        self.lua.execute('paletteDef.autoResourceColor=false;paletteDef.color={.3,.4,.8,1};paintResource()')
        self.assertEqual(list(region.fill.color.values()),[.3,.4,.8])
        self.lua.execute('primaryType=4;secondaryType=3;paintResource()')
        self.assertEqual(list(region.fill.color.values()),[.3,.4,.8])
        self.lua.execute('''
          paletteDef.autoResourceColor=true
          local rule=RWA.Rules.Add(paletteData)
          RWA.Rules.AddCheck(paletteData,rule,{field="always"})
          RWA.Rules.AddAction(paletteData,rule,{type="color",targetId="o1",value={1,0,0,1}})
          local snapshot=RWA.Rules.Observe(paletteData,fixtureNow,{})
          local result=RWA.Rules.Evaluate(paletteData,snapshot,true)
          paletteRegion:SetState(snapshot.s1);paletteRegion:SetColor(result.outputs.o1.color);paletteRegion:Update(fixtureNow)
          assert(result.outputs.o1.colorOverride)
        ''')
        self.assertEqual(list(region.fill.color.values()),[1,0,0])
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),before)

if __name__=='__main__':
    unittest.main()

