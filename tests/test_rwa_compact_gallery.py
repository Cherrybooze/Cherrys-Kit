"""Compact, one-page template gallery and family-navigation regressions."""
import unittest
import test_rwa as support


class CompactGalleryTests(unittest.TestCase):
    def setUp(self):
        self.h=support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua=self.h.lua
        self.lua.execute('RWA_DB.settings.resourceDefaultsVersion=2')
        if self.lua.globals().RWA.Resources is None:
            self.h.load('Resources.lua')
        if self.lua.globals().RWA.MEDIA is None or self.lua.globals().RWA.MEDIA.resources is None:
            self.h.load('MediaList.lua')
        if self.lua.globals().RWA.Regions.types.soulpoints is None:
            self.h.load('ResourceDisplays.lua')
        for name in ('KittyTracker.lua','Recent.lua','LastCast.lua','Threat.lua','CastBars.lua','Options.lua'):
            self.h.load(name)
        self.rwa=self.lua.globals().RWA
        self.rwa.ToggleOptions()
        self.rwa.ShowTemplates()
        self.gallery=self.rwa.Templates

    def visible_cards(self):
        return [card for card in self.gallery.cards.values() if card.button.IsVisible(card.button)]

    def click_card(self,entry_id):
        card=next(c for c in self.visible_cards() if c.entry.id==entry_id)
        self.h.script(card.button.name,'OnClick',key='LBUTTON')

    def test_all_defaults_fit_one_root_page_as_twenty_one_cards(self):
        self.assertEqual(len(self.gallery.Catalog()),27)
        cards=self.visible_cards()
        self.assertEqual(len(cards),21)
        ids={c.entry.id for c in cards}
        self.assertIn('family:buff',ids)
        self.assertIn('family:debuff',ids)
        self.assertIn('buff-count',ids)
        self.assertIn('kitty-hook',ids)
        self.assertIn('custom',ids)
        for resource in ('upper','lower','psi'):
            self.assertIn('resource:'+resource,ids)
        self.assertIn('default:Threat meter',ids)
        self.assertIn('default:My cast',ids)
        self.assertNotIn('player:HELPFUL:false',ids)
        self.assertFalse(self.lua.globals().RWA_TemplatePrevious.visible)
        self.assertEqual(self.rwa.W.GetText(self.lua.globals().RWA_TemplateNext),'X')
        for card in cards:
            self.assertGreaterEqual(card.button.x,18)
            self.assertLessEqual(card.button.x+card.button.width,714)
            self.assertLessEqual(card.button.y+card.button.height,624)
        initial=[c.entry.id for c in cards]
        self.gallery.Wheel(1)
        self.assertEqual([c.entry.id for c in self.visible_cards()],initial)

    def test_family_subcards_pair_present_and_missing_for_me_and_target(self):
        for family in ('family:buff','family:debuff'):
            self.click_card(family)
            cards=sorted(self.visible_cards(),key=lambda c:c.button.name)
            self.assertEqual(len(cards),4)
            self.assertIsNone(self.gallery.selected)
            for left,right in (cards[:2],cards[2:]):
                self.assertEqual(left.entry.unit,right.entry.unit)
                self.assertFalse(left.entry.missing)
                self.assertTrue(right.entry.missing)
                self.assertEqual(left.button.y,right.button.y)
                self.assertLess(left.button.x,right.button.x)
            self.assertEqual(cards[0].entry.unit,'player')
            self.assertEqual(cards[2].entry.unit,'target')
            self.h.script('RWA_TemplateBack','OnClick',key='LBUTTON')
            self.assertIsNone(self.gallery.family)
            self.assertEqual(len(self.visible_cards()),21)
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)

    def test_search_finds_specific_variant_in_any_word_order(self):
        self.h.type_text(self.gallery.search,'target missing debuff')
        cards=self.visible_cards()
        self.assertEqual(len(cards),1)
        self.assertEqual(cards[0].entry.id,'target:HARMFUL:true')
        self.click_card(cards[0].entry.id)
        self.assertEqual(self.gallery.selected.id,'target:HARMFUL:true')
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)
        self.h.type_text(self.gallery.search,'health')
        self.assertIsNone(self.gallery.selected)
        self.assertIn('default:Player health',[c.entry.id for c in self.visible_cards()])

    def test_broad_search_keeps_every_match_reachable_on_one_page(self):
        for query in ('a','p','t','m','buff','debuff','cast',''):
            self.h.type_text(self.gallery.search,query)
            self.assertLessEqual(len(self.gallery.filtered),24)
            self.assertEqual(len(self.visible_cards()),len(self.gallery.filtered))
        self.assertEqual(len(self.visible_cards()),21)

    def test_using_a_variant_creates_an_unsaved_independent_draft(self):
        self.click_card('family:buff')
        self.click_card('player:HELPFUL:true')
        self.h.script('RWA_TemplateUse','OnClick',key='LBUTTON')
        editor=self.rwa.UnifiedEditor
        draft=self.rwa.Editor.Get(editor.id)
        self.assertEqual(draft.sources[1].unit,'player')
        self.assertEqual(draft.rules[1].when.checks[1].field,'missing')
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)
        draft.sources[1].ids[1]=500934
        original=next(e for e in self.gallery.Catalog().values() if e.id=='player:HELPFUL:true')
        self.assertEqual(len(original.definition.sources[1].ids),0)

    def test_custom_opens_unconfigured_when_then_scaffolding(self):
        self.click_card('custom')
        editor=self.rwa.UnifiedEditor
        draft=self.rwa.Editor.Get(editor.id)
        self.assertEqual(len(draft.rules),1)
        self.assertEqual(len(draft.rules[1].when.checks),1)
        self.assertIsNone(draft.rules[1].when.checks[1].field)
        self.assertIsNone(draft.rules[1].when.checks[1].sourceId)
        self.assertEqual(len(draft.rules[1].actions),0)
        self.assertEqual(len(draft.sources),0)
        self.assertIsNone(draft.regionType)
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)
        custom=next(e for e in self.gallery.Catalog().values() if e.id=='custom')
        self.assertEqual(len(custom.definition.rules),0)

    def test_kitty_hook_preset_is_slot_two_and_three_skill_timeline(self):
        entry=next(e for e in self.gallery.Catalog().values() if e.id=='kitty-hook')
        d=entry.definition
        self.assertEqual(d.schemaVersion,3)
        self.assertEqual(d.sources[1].type,'kitty')
        self.assertEqual(d.sources[1].hotbarSlot,2)
        self.assertTrue(d.sources[1].anyCharacter)
        checks=list(d.rules[1].when.checks.values())
        self.assertEqual([(c.field,c.value) for c in checks],[('active',None),('hotbarSlot',2)])
        output=d.rules[1].actions[1].output
        self.assertEqual(output.regionType,'kittytracker')
        self.assertEqual(output.kittyLayout,'timeline')

    def test_gallery_preview_and_family_navigation_never_scan_or_execute_actions(self):
        self.lua.execute('''
          RWA.Rules.Observe=function() error("gallery scanned game state") end
          RWA.Triggers.CompileCustom=function() error("gallery compiled custom code") end
          RWA.PlaySound=function() error("gallery played a sound") end
        ''')
        for entry in self.gallery.Catalog().values():
            self.gallery.Select(entry)
            self.gallery.Update(100)
        self.click_card('family:debuff')
        self.h.script('RWA_TemplateBack','OnClick',key='LBUTTON')
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)

    def test_close_x_returns_to_aura_list_without_creating_anything(self):
        self.click_card('family:buff')
        self.h.script('RWA_TemplateNext','OnClick',key='LBUTTON')
        self.assertFalse(self.gallery.open)
        self.assertFalse(self.gallery.root.IsVisible(self.gallery.root))
        self.assertEqual(len(list(self.lua.globals().RWA_DB.auras.keys())),0)

    def test_repeated_open_search_and_family_navigation_reuse_controls(self):
        self.lua.execute('''
          function compactCycle()
            RWA.ShowTemplates()
            RWA.Templates.OpenFamily(RWA.Templates.RootCatalog()[1])
            RWA.Templates.Select(RWA.Templates.family.variants[1])
            RWA.Templates.Update(fixtureNow)
            RWA.Templates.ShowRoot()
            RWA.W.SetText(RWA.Templates.search,"target missing debuff")
            RWA.W.SetText(RWA.Templates.search,"")
            RWA.ShowList()
          end
          compactCycle()
        ''')
        before=len(list(self.lua.globals().fixtureWidgets.keys()))
        self.lua.execute('for i=1,20 do compactCycle() end')
        self.assertEqual(len(list(self.lua.globals().fixtureWidgets.keys())),before)

    def test_resource_templates_use_factory_defaults_and_create_independent_drafts(self):
        self.lua.execute('''
          local factory=RWA.Resources.Defaults()
          local mana
          for _,d in ipairs(factory) do if d.sources[1].resource=="upper" then mana=d end end
          assert(mana)
          local saved=RWA.CopyTable(mana)
          saved.rules[1].actions[1].output.barStyle="glass"
          RWA_DB.auras[saved.id]=saved
          RWA.Templates.catalog=nil;RWA.Templates.rootCatalog=nil
          local entry
          for _,e in ipairs(RWA.Templates.Catalog()) do if e.id=="resource:upper" then entry=e end end
          assert(entry and entry.definition.rules[1].actions[1].output.barStyle=="metal")
          local id=RWA.Templates.Create(entry.id)
          local draft=RWA.Editor.Get(id)
          draft.rules[1].actions[1].output.barStyle="minimal"
          assert(saved.rules[1].actions[1].output.barStyle=="glass")
          assert(entry.definition.rules[1].actions[1].output.barStyle=="metal")
          assert(draft.sources[1].type=="resource" and draft.sources[1].resource=="upper")
          assert(not RWA_DB.auras[id])
        ''')

    def test_resource_samples_are_detached_partial_states_and_psi_art_is_untinted(self):
        self.lua.execute('''
          UnitManaType=function() error("gallery read live resource type") end
          UnitSkillType=UnitManaType;UnitMana=UnitManaType;UnitSkill=UnitManaType
          UnitMaxMana=UnitManaType;UnitMaxSkill=UnitManaType;GetSoulPoint=UnitManaType
          for _,entry in ipairs(RWA.Templates.Catalog()) do
            if entry.resource then
              RWA.Templates.Select(entry)
              RWA.Templates.Update(fixtureNow)
              local source=entry.definition.sources[1]
              local state=RWA.Templates.states[source.id]
              assert(state.available and state.active and RWA.Resources.Matches(entry.resource,state))
              assert(state.value>0 and state.value<state.total)
              assert(not state.showMax)
              if entry.resource=="psi" then assert(state.total==RWA.Resources.PSI_MAX) end
            end
          end
        ''')
        self.gallery.Refresh()
        psi=next(c for c in self.visible_cards() if c.entry.id=='resource:psi')
        self.assertIn('Resources/soul-diamond',psi.image.texture)
        self.assertEqual(list(psi.image.color.values())[:3],[1,1,1])
        self.assertEqual(psi.image.width,psi.image.height)
        self.h.type_text(self.gallery.search,'resource')
        self.assertEqual({c.entry.resource for c in self.visible_cards()},{'upper','lower','psi'})


if __name__=='__main__':
    unittest.main()

