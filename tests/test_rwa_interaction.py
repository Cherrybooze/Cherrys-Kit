"""Native XML-backed clickthrough controls and world-region input lifecycle."""
import unittest

import test_rwa as support


class AuraInteractionTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA
        self.lua.execute('''
          GameTooltip={shown=false}
          function GameTooltip:SetOwner(owner) self.owner=owner end
          function GameTooltip:SetFrameStrata() end
          function GameTooltip:SetText(text) self.text=text end
          function GameTooltip:AddLine() end
          function GameTooltip:Show() self.shown=true end
          function GameTooltip:Hide() self.shown=false end
          function interactionAura(id,clickThrough)
            local d=RWA.Rules.InitializeActions({id=id,enabled=true,clickThrough=clickThrough})
            local source=RWA.Rules.AddSource(d,{type="status",check="health",unit="player"})
            d.rules[1].when.checks={{field="active",sourceId=source}}
            local first=RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="icon",text="%v"}})
            RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="text",text="root",offsetX=80}})
            RWA.Rules.AddAction(d,d.rules[1],{type="show",sourceId=source,
              output={regionType="text",text="child",parentOutputId=first.output.id,offsetY=30}})
            RWA.AddAura(d)
          end
          interactionAura("Input")
        ''')
        self.h.tick()

    def test_existing_and_new_auras_default_to_clickthrough_on_every_output(self):
        self.assertTrue(self.rwa.GetAura("Input").clickThrough)
        for output in self.rwa.loaded.Input.outputs.values():
            self.assertFalse(output.region.frame.mouse)
            self.h.script(output.region.frame.name, "OnEnter")
            self.assertFalse(self.lua.globals().GameTooltip.shown)

    def test_opt_out_preserves_hover_and_lock_does_not_add_drag_handlers(self):
        self.lua.execute('interactionAura("Interactive",false)')
        self.h.tick()
        self.rwa.SetUnlocked(True)
        self.rwa.SetUnlocked(False)
        aura = self.rwa.loaded.Interactive
        self.assertIsNone(aura.dragUpdate)
        for output in aura.outputs.values():
            self.assertTrue(output.region.frame.mouse)
            self.h.script(output.region.frame.name, "OnEnter")
            self.assertTrue(self.lua.globals().GameTooltip.shown)
            self.h.script(output.region.frame.name, "OnLeave")

    def test_unlock_lock_and_preview_close_restore_clickthrough_and_hide_tooltip(self):
        self.rwa.SetUnlocked(True)
        for output in self.rwa.loaded.Input.outputs.values():
            self.assertTrue(output.region.frame.mouse)
        self.h.script(self.rwa.loaded.Input.region.frame.name, "OnEnter")
        self.assertTrue(self.lua.globals().GameTooltip.shown)
        self.rwa.SetUnlocked(False)
        self.assertFalse(self.lua.globals().GameTooltip.shown)
        for output in self.rwa.loaded.Input.outputs.values():
            self.assertFalse(output.region.frame.mouse)
        self.lua.execute('windowOpen=true; RWA.IsOptionsOpen=function() return windowOpen end')
        self.rwa.SetOptionsPreview(True)
        self.rwa.SetEditMode(False)  # locking placement must keep editor hover available
        for output in self.rwa.loaded.Input.outputs.values():
            self.assertTrue(output.region.frame.mouse)
        self.lua.execute("windowOpen=false")
        self.h.tick()  # native X/Escape close fallback
        for output in self.rwa.loaded.Input.outputs.values():
            self.assertFalse(output.region.frame.mouse)

    def test_checkbox_uses_xml_keeps_draft_isolation_and_saves_false(self):
        self.h.load("Options.lua")
        self.rwa.ToggleOptions()
        self.rwa.ShowEditor("Input")
        editor = self.rwa.UnifiedEditor
        box = editor.clickThrough
        self.assertEqual(box.kind, "CheckButton")
        self.assertTrue(box.IsChecked(box))
        self.h.script(box.name, "OnClick", key="LBUTTON")
        self.assertFalse(self.rwa.Editor.Get("Input").clickThrough)
        self.assertTrue(self.rwa.GetAura("Input").clickThrough)
        self.h.script(editor.revert.name, "OnClick", key="LBUTTON")
        self.assertTrue(box.IsChecked(box))
        self.h.script(box.name, "OnClick", key="LBUTTON")
        self.h.script(editor.save.name, "OnClick", key="LBUTTON")
        self.rwa.ToggleOptions()
        self.assertFalse(self.rwa.GetAura("Input").clickThrough)
        self.rwa.ReloadAll()
        self.assertTrue(self.rwa.loaded.Input.region.frame.mouse)

    def test_shared_false_and_legacy_missing_values_keep_their_meaning(self):
        self.h.load("Share.lua")
        self.lua.execute('''
          local saved=RWA.GetAura("Input")
          saved.clickThrough=false
          local code=assert(RWA.Share.Export({"Input"}))
          local imported=assert(RWA.Share.Import(code))
          assert(RWA.GetAura(imported[1]).clickThrough==false)
          local legacy={id="Old",schemaVersion=2,primarySourceId="s1",sources={{id="s1",type="status",check="health"}},
            rules={{id="r1",when={mode="all",checks={{field="active",sourceId="s1"}}},set={visible=true}}}}
          local converted=assert(RWA.Rules.ConvertV2(legacy))
          RWA.ApplyAuraDefaults(converted)
          assert(converted.clickThrough==true)
          legacy.clickThrough=false
          converted=assert(RWA.Rules.ConvertV2(legacy))
          assert(converted.clickThrough==false)
        ''')


if __name__ == "__main__":
    unittest.main()
