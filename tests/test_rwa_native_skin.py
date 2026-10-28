"""Native button readback and paint-layer regressions reported from the client."""
import unittest
import test_rwa as support


class NativeSkinTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.rwa = self.lua.globals().RWA

    def open_editor(self):
        self.h.load('Options.lua')
        self.lua.execute('''
          RWA.AddAura(RWA.Rules.MakeFlowExample({id="Native",enabled=true}))
          RWA.ToggleOptions(); RWA.ShowEditor("Native")
        ''')
        return self.rwa.UnifiedEditor

    def test_bare_native_buttons_cannot_erase_custom_labels_on_restyle(self):
        self.lua.execute('''
          local methods=getmetatable(RWA_UnifiedRoot).__index
          local get,set=methods.GetText,methods.SetText
          function methods:GetText() if self.kind=="Button" then return "" end; return get(self) end
          function methods:SetText(value) if self.kind=="Button" then return end; return set(self,value) end
        ''')
        editor = self.open_editor()
        for _ in range(3):
            editor.Refresh()
            self.assertTrue(self.rwa.W.skins[editor.sections.general.title].label.text.startswith('General'))
            self.assertEqual(self.rwa.W.skins[editor.save].label.text, 'Save aura')
            self.assertIn('Missing buff', self.rwa.W.skins[editor.ruleRows[1].first].label.text)
        editor.RowClick(2, 'first')
        self.assertIn('Buff / debuff', self.rwa.W.skins[editor.menu.buttons[1]].label.text)
        self.assertEqual(editor.name.box.text, 'Native')
        editor.CloseMenu()
        self.rwa.ShowTemplates()
        self.assertEqual(self.rwa.W.skins[self.lua.globals().RWA_TemplateUse].label.text, 'Choose a template')

    def test_panels_paint_on_parent_layers_and_cannot_cover_edit_boxes(self):
        editor = self.open_editor()
        self.h.script(editor.sections.general.collapse.name, 'OnClick', key='LBUTTON')
        for sec in editor.sections.values():
            panel = sec.panel
            skin = self.rwa.W.skins[panel]
            self.assertEqual(panel.kind, 'Texture')
            self.assertEqual(panel.parent, editor.root.name)
            self.assertEqual(skin.fill.parent, editor.root.name)
            self.assertEqual(panel.layer, 1)
        row = editor.ruleRows[1]
        self.assertEqual(row.card.kind, 'Texture')
        self.assertEqual(row.card.layer, 2)
        self.assertTrue(editor.name.box.IsVisible(editor.name.box))
        skin = self.rwa.W.skins[row.card]
        self.rwa.W.SetPoint(row.card, 'TOPLEFT', editor.root, 'TOPLEFT', 25, 205)
        self.assertEqual((skin.edge.x, skin.edge.y), (25, 205))
        self.rwa.W.SetSize(row.card, 500, 30)
        self.assertEqual((skin.fill.width, skin.fill.height), (500, 30))
        self.assertEqual((skin.edges[4].x, skin.edges[4].width), (524, 1))
        self.rwa.W.SetShown(row.card, False)
        self.assertFalse(skin.fill.visible)
        self.assertFalse(skin.edge.visible)
        self.rwa.W.SetShown(row.card, True)
        self.assertTrue(skin.fill.visible)

    def test_edit_boxes_keep_native_readback_when_button_labels_are_cached(self):
        editor = self.open_editor()
        self.h.type_text(editor.name.box, 'Renamed')
        self.assertEqual(self.rwa.W.GetText(editor.name.box), 'Renamed')
        self.rwa.W.Skin(editor.save, 'selected')
        self.rwa.W.Skin(editor.save, 'save')
        self.assertEqual(self.rwa.W.GetText(editor.save), 'Save aura')
        self.assertEqual(self.rwa.W.skins[editor.save].label.text, 'Save aura')

    def test_list_uses_full_width_and_scales_all_controls_with_window(self):
        self.h.load('Options.lua')
        self.lua.execute('''
          for i=1,11 do RWA.AddAura(RWA.Rules.MakeFlowExample({id="List "..i})) end
          RWA.ToggleOptions()
        ''')
        buttons = self.h.widgets('Button')
        down = [b for b in buttons if self.rwa.W.GetText(b) == 'v']
        self.assertEqual(len(down), 11)
        self.assertEqual(down[0].anchor[4] + down[0].width, 1038)
        self.assertEqual(max(b.anchor[5] for b in down), 557)
        for b in buttons:
            if b.name.startswith('RWA_OptBtn'):
                self.assertIsNotNone(self.rwa.W.skins[b])
        before = len(list(self.lua.globals().fixtureWidgets.keys()))
        self.rwa.SetWindowScale(1.2)
        self.assertAlmostEqual(self.lua.globals().RWA_OptionsWindow.scale, 1.2)
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())), before)

    def test_tooltips_color_each_cached_check_and_keep_unobserved_values_neutral(self):
        self.lua.execute('''
          data=RWA.Rules.MakeFlowExample({id="Colours",enabled=true})
          snapshot={s1={available=true,present=false},s2={available=true,percent=75,active=true}}
          result=RWA.Rules.Evaluate(data,snapshot,true)
          RWA.Rules.Observe=function() error("tooltip scanned") end
          RWA.PlaySound=function() error("tooltip played a sound") end
          colored=RWA.Rules.TooltipLines(data,result,snapshot)
          neutral=RWA.Rules.TooltipLines(data,nil)
        ''')
        colored = '\n'.join(self.lua.globals().colored.values())
        self.assertIn('|cff43d5d0[500934]|r', colored)
        self.assertIn('|cff50e69a[missing]|r', colored)
        self.assertIn('|cffff6b76[below]|r', colored)
        self.assertIn('|cffff6b76[20%]|r', colored)
        self.assertIn('|cff50e69a[true]|r', colored)
        neutral = '\n'.join(self.lua.globals().neutral.values())
        self.assertNotIn('|cffff6b76', neutral)
        self.assertNotIn('|cff50e69a', neutral)
        self.assertIn('|cff43d5d0[missing]|r', neutral)
        plain = self.rwa.Rules.RuleSentence(self.lua.globals().data, self.lua.globals().data.rules[1])
        self.assertNotIn('|c', plain)
        self.assertNotIn('[', plain)

    def test_tooltip_all_or_any_does_not_color_every_check_from_rule_result(self):
        self.lua.execute('''
          local d=RWA.Rules.MakeFlowExample({id="Any",enabled=true})
          d.rules[2].when.mode="any"
          local obs={s1={available=true,present=false},s2={available=true,percent=75,active=true}}
          local result=RWA.Rules.Evaluate(d,obs,true)
          assert(result.matches[d.rules[2].id])
          anyLines=RWA.Rules.TooltipLines(d,result,obs,d.rules[2])
        ''')
        lines = '\n'.join(self.lua.globals().anyLines.values())
        self.assertIn('|cff50e69a[true]|r', lines)
        self.assertIn('|cffff6b76[20%]|r', lines)


if __name__ == '__main__':
    unittest.main()
