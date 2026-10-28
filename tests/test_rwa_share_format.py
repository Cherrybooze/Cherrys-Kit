"""RWA share format compatibility; runs production Lua under Lua 5.1."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/RomWeakAuras'

class ShareFormatTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute('RWA = { On = function() end }; RWA_DB = {auras = {}, order = {}, settings = {}}')
        for name in ('Init.lua', 'Database.lua', 'Rules.lua', 'Share.lua'):
            self.lua.execute((ROOT / name).read_text(encoding='utf-8-sig'), name=name)
        self.lua.execute('RWA.LoadAura = function() end')

    def test_rwa3_import_converts_and_reexports_without_recovery_archive(self):
        self.lua.execute("""
          local legacy={id="Legacy",enabled=true,triggers={{type="aura",ids={500934}}},conditions={}}
          local v2=RWA.CopyTable(legacy); v2.id="Modern"; RWA.Rules.StartFresh(v2)
          local r=RWA.Rules.Add(v2); r.when.checks={{sourceId=v2.primarySourceId,field="present"}}
          r.set={visible=true,color={1,0,0,1},grow=1.25}
          local value={formatVersion=3,auras={legacy,v2}}
          local packed=RWA.Share.Pack(value)
          local old="RWA3!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids=assert(RWA.Share.Import(old)); original=RWA.GetAura(ids[2])
          code=assert(RWA.Share.Export()); assert(string.sub(code,1,5)=="RWA4!")
          local copies=assert(RWA.Share.Import(code)); copy=RWA.GetAura(copies[2])
        """)
        g=self.lua.globals()
        self.assertEqual(g.original.schemaVersion,3)
        self.assertEqual(g.original.previousDefinition.schemaVersion,2)
        self.assertEqual(g.copy.schemaVersion,3)
        self.assertIsNone(g.copy.previousDefinition)
        self.assertIsNone(g.copy.triggers)
        self.assertEqual(self.lua.eval('#RWA.Share.WORDS'),96)

    def test_unconvertible_legacy_import_is_atomic(self):
        self.lua.execute("""
          local good={id="Good",triggers={{type="aura",ids={1}}}}
          local bad={id="Bad",schemaVersion=2,primarySourceId="s1",sources={{id="s1",type="aura",ids={1}}},
            elements={{type="icon",sourceId="s1"}},rules={{id="r1",when={mode="all",checks={{field="always"}}},set={visible=true,blink=true}}}}
          local packed=RWA.Share.Pack({formatVersion=3,auras={good,bad}})
          local code="RWA3!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids,problem=RWA.Share.Import(code)
        """)
        self.assertIsNone(self.lua.globals().ids)
        self.assertIn('could not convert',self.lua.globals().problem)
        self.assertEqual(self.lua.eval('#RWA_DB.order'),0)

    def test_action_model_roundtrip_and_recovery_exclusion(self):
        self.lua.execute('''
          RWA.Regions = { types = { icon = {} } }
          local aura = RWA.Rules.MakeFlowExample({id="Flow", enabled=true})
          aura.previousDefinition = {secret="recovery"}
          RWA.AddAura(aura)
          code = assert(RWA.Share.Export()); assert(string.sub(code, 1, 5) == "RWA4!")
          local ids = assert(RWA.Share.Import(code)); copy = RWA.GetAura(ids[1])
        ''')
        copy = self.lua.globals().copy
        self.assertEqual(copy.schemaVersion, 3)
        self.assertEqual(copy.rules[2].when.checks[1].ruleId, copy.rules[1].id)
        self.assertEqual(copy.rules[2].actions[1].targetId, copy.rules[1].actions[1].output.id)
        self.assertIsNone(copy.previousDefinition)
        self.assertEqual(self.lua.globals().RWA.GetAura('Flow').previousDefinition.secret, 'recovery')

    def test_rwa1_and_rwa2_legacy_import(self):
        self.lua.execute('''
          local value={auras={{id="Old",triggers={{type="aura",ids={500934}}}}}}
          local old=RWA.Share.Serialize(value)
          code1="RWA1!"..RWA.Share.Base64Encode(old).."!"..RWA.Share.Checksum(old)
          local packed=RWA.Share.Pack(value)
          code2="RWA2!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids1=assert(RWA.Share.Import(code1)); ids2=assert(RWA.Share.Import(code2))
        ''')
        self.assertEqual(self.lua.globals().ids1[1], 'Old')
        self.assertEqual(self.lua.globals().ids2[1], 'Old 2')

    def test_malformed_check_rejects_all_auras(self):
        self.lua.execute('''
          local value={formatVersion=3,auras={
            {id="Good",triggers={{type="aura"}}},
            {id="Invalid",schemaVersion=2,primarySourceId="s1",sources={{id="s1",type="aura",ids={1}}},
              rules={{id="r1",when={mode="all",checks={false}},set={visible=true}}}}
          }}
          local packed=RWA.Share.Pack(value)
          local code="RWA3!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids,problem=RWA.Share.Import(code)
        ''')
        self.assertIsNone(self.lua.globals().ids)
        self.assertIn('invalid rule check', self.lua.globals().problem)
        self.assertEqual(self.lua.eval('#RWA_DB.order'), 0)

    def test_rwa4_duplicate_output_id_rejects_the_entire_import(self):
        self.lua.execute('''
          local value={formatVersion=4,auras={
            {id="Good",triggers={{type="aura"}}},
            {id="Bad",schemaVersion=3,sources={},rules={{id="r1",when={mode="all",checks={}},actions={
              {id="a1",type="show",output={id="o1",regionType="icon"}},
              {id="a2",type="show",output={id="o1",regionType="text"}}}}}}
          }}
          local packed=RWA.Share.Pack(value)
          local code="RWA4!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids,problem=RWA.Share.Import(code)
        ''')
        self.assertIsNone(self.lua.globals().ids)
        self.assertIn('invalid output IDs', self.lua.globals().problem)
        self.assertEqual(self.lua.eval('#RWA_DB.order'), 0)

    def test_unknown_schema_rejects_entire_import(self):
        self.lua.execute('''
          local value={formatVersion=3,auras={{id="Good",triggers={{type="aura"}}},{id="Future",schemaVersion=99}}}
          local packed=RWA.Share.Pack(value)
          local code="RWA3!"..RWA.Share.Base85Encode(RWA.Share.Compress(packed)).."!"..RWA.Share.ShortChecksum(packed)
          ids, problem=RWA.Share.Import(code)
        ''')
        self.assertIsNone(self.lua.globals().ids)
        self.assertIn('newer version', self.lua.globals().problem)
        self.assertEqual(self.lua.eval('#RWA_DB.order'), 0)

if __name__ == '__main__': unittest.main()
