"""Unified rule/editor integration and lightweight update-loop regressions."""
import unittest

import test_rwa as support


class UnifiedEditorTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua

    def open_editor(self, aura_id):
        self.h.load("Options.lua")
        self.lua.globals().RWA.ToggleOptions()
        self.lua.globals().RWA.ShowEditor(aura_id)
        self.h.tick()
        return self.lua.globals().RWA.UnifiedEditor

    def choice(self, label):
        choices = [w for w in self.h.widgets("Button", text=label) if w.parent == "RWA_UnifiedMenu"]
        self.assertEqual(len(choices), 1, label)
        self.h.script(choices[0].name, "OnClick", key="LBUTTON")

    def test_wheel_targets_rules_or_open_menu_only(self):
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Wheel",enabled=true}))')
        editor=self.open_editor('Wheel')
        self.lua.execute('for i=1,4 do RWA.Rules.Duplicate(RWA.Editor.Get("Wheel"),"r1") end')
        editor.Refresh()
        self.h.script(editor.name.box.name,"OnMouseWheel",delta=-1)
        self.assertEqual(editor.ruleTop,0)
        self.h.script(editor.ruleRows[2].first.name,"OnMouseWheel",delta=-1)
        self.assertEqual(editor.ruleTop,1)
        editor.RowClick(1,"first")
        self.assertTrue(editor.menu.open)
        # Use a long, real editor menu to exercise paging via the XML callback.
        self.lua.execute('for i=1,55 do RWA.UnifiedEditor.menu.values[i]={label=tostring(i),value=i} end')
        self.h.script(editor.menu.buttons[1].name,"OnMouseWheel",delta=-1)
        self.assertTrue(editor.menu.open)
        self.assertEqual(editor.menu.page,1)
        self.assertEqual(editor.ruleTop,1)
        editor.CloseMenu()
        editor.Scroll(-1)
        self.h.script("RWA_FlowRulesSurface", "OnMouseWheel", delta=-1)
        self.assertEqual(editor.ruleTop,1)

    def test_reset_normalizes_examples_before_reloading(self):
        self.lua.execute('RWA.SlashCommand("reset confirm")')
        auras=self.lua.globals().RWA_DB.auras
        self.assertGreater(len(list(auras.keys())),0)
        for name,aura in auras.items():
            self.assertEqual(aura.schemaVersion,3,name)
            if aura.enabled:
                self.assertIsNotNone(self.lua.globals().RWA.loaded[name],name)

    def test_list_preview_handles_action_outputs_and_sound_only_auras(self):
        self.lua.execute('''
          local d=RWA.Rules.InitializeActions({id="Sound only",enabled=true,regionType="icon"})
          d.rules[1].when.checks[1].field="always"
          RWA.Rules.AddAction(d,d.rules[1],{type="sound",clip="AirHorn",mode="once"})
          RWA.AddAura(d)
          local t=RWA.Rules.InitializeActions({id="Action text",enabled=true,regionType="icon"})
          t.rules[1].when.checks[1].field="always"
          RWA.Rules.AddAction(t,t.rules[1],{type="show",output={regionType="text",text="hello"}})
          RWA.AddAura(t)
          local long=RWA.Rules.InitializeActions({id="Long text",enabled=true,regionType="icon"})
          long.rules[1].when.checks[1].field="always"
          RWA.Rules.AddAction(long,long.rules[1],{type="show",output={regionType="text",text="Long text sample"}})
          RWA.AddAura(long)
        ''')
        self.h.load("Options.lua")
        self.lua.globals().RWA.ToggleOptions()
        self.assertIsNone(self.lua.globals().RWA.loaded['Sound only'].region)
        self.assertTrue(self.h.widgets("FontString", text="hello"))
        self.assertTrue(self.h.widgets("FontString", text="Aa"))

    def test_saved_rate_and_casting_checks_are_evaluated(self):
        self.lua.execute("""
          local d=RWA.Rules.InitializeActions({id="Checks",enabled=true})
          local source=RWA.Rules.AddSource(d,{type="status",check="health",unit="player"})
          local check=d.rules[1].when.checks[1]
          check.sourceId=source; check.op=">="; check.value=3.8
          check.field="perSecond"; rate=RWA.Rules.Match(d.rules[1],{[source]={available=true,perSecond=3.8}})
          check.field="casting"; check.value=1
          casting=RWA.Rules.Match(d.rules[1],{[source]={available=true,casting=1}})
        """)
        self.assertTrue(self.lua.globals().rate)
        self.assertTrue(self.lua.globals().casting)

    def test_all_builtin_examples_use_the_new_rule_model(self):
        for name in ("ClassIcons.lua", "KittyTracker.lua", "Recent.lua", "LastCast.lua", "Threat.lua", "CastBars.lua"):
            self.h.load(name)
        self.lua.execute('''
          RWA_DB=nil; RWA.LoadAura=function() end; RWA.InitDB()
          RWA.Recent.AddExample(); RWA.LastCast.AddExample()
          RWA.Threat.AddExample(); RWA.CastBars.AddExamples()
          RWA.Fire("RWA_READY")
        ''')
        auras = self.lua.globals().RWA_DB.auras
        self.assertEqual(len(list(auras.keys())), 17)
        self.assertIsNotNone(auras["High durability repair"])
        for name in ("Upper bar", "Lower bar", "PSI"):
            self.assertIsNotNone(auras["Resource: " + name])
        for name, aura in auras.items():
            with self.subTest(aura=name):
                self.assertEqual(aura.schemaVersion, 3)
                self.assertIsNone(aura.triggers)
                self.assertIsNone(aura.conditions)
                self.assertTrue(aura.sources[1])
                self.assertTrue(aura.rules[1])
                self.assertEqual(aura.primarySourceId, aura.sources[1].id)

    def test_converted_aura_runs_only_the_action_model(self):
        self.h.add_aura()
        self.open_editor("Buff reminder")
        self.assertEqual(self.lua.globals().RWA.Editor.Get("Buff reminder").schemaVersion, 3)
        self.lua.execute("""
          legacyEvaluations=0
          RWA.Conditions.EvaluateTrigger=function(...) legacyEvaluations=legacyEvaluations+1 end
        """)
        self.h.tick()
        self.assertEqual(self.lua.globals().legacyEvaluations, 0)
        self.assertEqual(self.lua.globals().RWA.loaded["Buff reminder"].data.schemaVersion, 3)

    def test_one_shared_scan_per_poll_without_copying_definitions(self):
        self.lua.execute('''
          for i=1,12 do
            local d=RWA.Rules.Initialize({id="Sample "..i,enabled=true,regionType="icon"})
            d.sources[1].ids={500934}
            for j=2,8 do
              local r=RWA.Rules.Add(d)
              r.set={color={1,0,0,1}}
              RWA.Rules.AddCheck(d,r,{sourceId=d.primarySourceId,field="present"})
            end
            RWA.AddAura(d)
          end
          scans,copies,polls=0,0,0
          local buff=UnitBuff; UnitBuff=function(...) scans=scans+1; return buff(...) end
          local copy=RWA.CopyTable; RWA.CopyTable=function(...) copies=copies+1; return copy(...) end
          local tick=RWA.Triggers.Tick; RWA.Triggers.Tick=function(...) polls=polls+1; return tick(...) end
        ''')
        for _ in range(3):
            self.h.tick()
        self.assertEqual(self.lua.globals().polls, 3)
        self.assertEqual(self.lua.globals().scans, 3)
        self.assertEqual(self.lua.globals().copies, 0)

    def test_preview_reuses_prepared_layout_until_the_draft_changes(self):
        self.lua.execute('RWA.AddAura(RWA.Rules.MakeFlowExample({id="Flow",enabled=true}))')
        editor = self.open_editor("Flow")
        self.lua.execute("""
          previewCopies=0
          local original=RWA.CopyTable
          RWA.CopyTable=function(value)
            local d=RWA.Editor.Get("Flow")
            if value==d or value==d.rules[1].actions[1].output then previewCopies=previewCopies+1 end
            return original(value)
          end
        """)
        for _ in range(5): self.h.tick()
        self.assertEqual(self.lua.globals().previewCopies,0)
        self.lua.globals().RWA.Editor.Get("Flow").rules[1].actions[1].output.width=83
        editor.previewDirty=True
        self.h.tick()
        self.assertGreater(self.lua.globals().previewCopies,0)
        self.lua.globals().previewCopies=0
        for _ in range(5): self.h.tick()
        self.assertEqual(self.lua.globals().previewCopies,0)

    def test_typing_updates_draft_without_reloading_aura(self):
        aura_id = self.lua.globals().RWA.NewAura("icon")
        editor = self.open_editor(aura_id)
        self.lua.execute('''
          reloads=0
          local load=RWA.LoadAura
          RWA.LoadAura=function(...) reloads=reloads+1; return load(...) end
        ''')
        self.h.type_text(editor.desc.box, "Description typed one character at a time")
        self.assertEqual(self.lua.globals().reloads, 0)
        self.assertEqual(self.lua.globals().RWA.Editor.Get(aura_id).desc,
                         "Description typed one character at a time")
        editor.Flush()
        self.assertLessEqual(self.lua.globals().reloads, 1)

    def test_closed_editor_does_not_do_preview_work_and_controls_are_reused(self):
        aura_id = self.lua.globals().RWA.NewAura("icon")
        self.h.load("Options.lua")
        self.lua.execute('''
          previews=0
          local original=RWA.UpdatePreview
          RWA.UpdatePreview=function(...) previews=previews+1; return original(...) end
        ''')
        self.h.tick()
        self.assertEqual(self.lua.globals().previews, 0)
        self.lua.globals().RWA.ToggleOptions()
        self.lua.globals().RWA.ShowEditor(aura_id)
        self.h.tick()
        self.assertGreater(self.lua.globals().previews, 0)
        self.lua.execute('collectgarbage("collect")')
        widget_count = self.lua.eval('(function() local n=0; for _ in pairs(fixtureWidgets) do n=n+1 end; return n end)')
        count = widget_count()
        before = self.lua.eval('collectgarbage("count")')
        for _ in range(10):
            self.lua.globals().RWA.ToggleOptions()
            self.lua.globals().RWA.ToggleOptions()
            self.lua.globals().RWA.ShowEditor(aura_id)
            self.h.tick()
        self.lua.execute('collectgarbage("collect")')
        self.assertEqual(widget_count(), count)
        self.assertLess(self.lua.eval('collectgarbage("count")') - before, 16)


if __name__ == "__main__":
    unittest.main(verbosity=2)
