"""RWA5 share codes: deflate with a frozen codebook, as KittyCombo's CKC3 codes."""
from pathlib import Path
import unittest
import zlib

import test_rwa as support

ROOT = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/RomWeakAuras'


class ShareCodebookTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        for name in ('KittyTracker.lua', 'Recent.lua', 'LastCast.lua', 'Threat.lua', 'CastBars.lua', 'Options.lua', 'Share.lua'):
            self.h.load(name)
        self.lua.execute('RWA.path = %r' % (ROOT.as_posix() + '/'))
        self.lua.execute('''
          laterCalls = {}
          RWA.After = function(seconds, fn) laterCalls[#laterCalls + 1] = {seconds = seconds, fn = fn} end
          function fromTemplate(templateId)
            for _, entry in ipairs(RWA.Templates.Catalog()) do
              if entry.id == templateId then
                local copy = RWA.CopyTable(entry.definition)
                copy.id = entry.title; copy.desc = entry.description
                return assert(RWA.AddAura(copy))
              end
            end
          end
        ''')

    def test_codebook_file_is_frozen(self):
        hexed = self.lua.eval('(string.gsub(dofile(RWA.path .. "data/ShareCodebook.lua"), ".", '
                              'function(c) return string.format("%02x", string.byte(c)) end))')
        data = bytes.fromhex(hexed)
        self.assertEqual(len(data), 26170)
        self.assertEqual(zlib.adler32(data), 563433626)
        self.assertEqual(self.lua.eval('RWA.Share.CODEBOOK_LENGTH'), len(data))
        self.assertEqual(self.lua.eval('RWA.Share.CODEBOOK_ADLER'), zlib.adler32(data))

    def test_template_aura_code_is_short_and_round_trips(self):
        self.lua.execute('''
          local id = fromTemplate("default:Player health")
          original = RWA.GetAura(id)
          code = assert(RWA.Share.Export({id}))
          legacy = assert(RWA.Share.Export({id}, true))
          ids = assert(RWA.Share.Import(code)); copy = RWA.GetAura(ids[1])
          local a = RWA.CopyTable(original); a.id = copy.id
          same = RWA.Share.Pack(a, true) == RWA.Share.Pack(copy, true)
        ''')
        g = self.lua.globals()
        self.assertTrue(g.code.startswith('RWA5!'))
        self.assertTrue(g.legacy.startswith('RWA4!'))
        self.assertLess(len(g.code), 60)
        self.assertGreater(len(g.legacy), 500)
        self.assertEqual(g.ids[1], 'Player health 2')
        self.assertTrue(g.same)

    def test_changed_aura_and_own_buff_names_still_fit_a_chat_line(self):
        self.lua.execute('''
          local id = fromTemplate("player:HELPFUL:false")
          local aura = RWA.GetAura(id)
          aura.sources[1].names = {"Holy Light Protection", "Grace of Life"}
          aura.x = 123; aura.y = -45
          code = assert(RWA.Share.Export({id}))
          link = RWA.Share.MakeLink(code, id)
          ids = assert(RWA.Share.Import(code)); copy = RWA.GetAura(ids[1])
        ''')
        g = self.lua.globals()
        self.assertLess(len(g.code), 100)
        self.assertIsNotNone(g.link)
        self.assertEqual(list(g.copy.sources[1].names.values()), ['Holy Light Protection', 'Grace of Life'])
        self.assertEqual(g.copy.x, 123)

    def test_export_all_mixed_auras_round_trips(self):
        self.lua.execute('''
          for _, t in ipairs({"default:Target health", "default:Threat meter", "resource:upper", "custom"}) do fromTemplate(t) end
          local before = #RWA_DB.order
          code, count = RWA.Share.Export()
          ids = assert(RWA.Share.Import(code))
          added = #RWA_DB.order - before
        ''')
        g = self.lua.globals()
        self.assertTrue(g.code.startswith('RWA5!'))
        self.assertEqual(g.count, 4)
        self.assertEqual(g.added, 4)

    def test_code_pasted_with_words_around_it(self):
        self.lua.execute('''
          local id = fromTemplate("default:Threat meter")
          code = assert(RWA.Share.Export({id}))
          ids = assert(RWA.Share.Import("cherry: my threat aura -> " .. code .. " <- have fun!"))
          ids2 = assert(RWA.Share.Import("look\\n" .. string.sub(code, 1, 10) .. "\\n" .. string.sub(code, 11)))
        ''')
        g = self.lua.globals()
        self.assertEqual(g.ids[1], 'Threat meter 2')
        self.assertEqual(g.ids2[1], 'Threat meter 3')

    def test_damaged_and_future_codes_are_refused(self):
        self.lua.execute('''
          local id = fromTemplate("default:Target health")
          local code = assert(RWA.Share.Export({id}))
          local body = string.sub(code, 6, -6)
          local swapped = string.sub(body, 1, 3) .. (string.sub(body, 4, 4) == "a" and "b" or "a") .. string.sub(body, 5)
          before = #RWA_DB.order
          ids, damaged = RWA.Share.Import("RWA5!" .. swapped .. string.sub(code, -5))
          ids2, future = RWA.Share.Import("RWA6!abcde!1234")
          after = #RWA_DB.order
        ''')
        g = self.lua.globals()
        self.assertIsNone(g.ids)
        self.assertIsNotNone(g.damaged)
        self.assertIn('newer version', g.future)
        self.assertEqual(g.before, g.after)

    def test_missing_codebook_falls_back_and_explains(self):
        self.lua.execute('''
          local id = fromTemplate("default:Target health")
          good = assert(RWA.Share.Export({id}))
          RWA.Share.codebook = nil
          RWA.path = "missing/"
          fallback = assert(RWA.Share.Export({id}))
          ids, problem = RWA.Share.Import(good)
          ids2 = assert(RWA.Share.Import(fallback))
        ''')
        g = self.lua.globals()
        self.assertTrue(g.fallback.startswith('RWA4!'))
        self.assertIsNone(g.ids)
        self.assertIn('ShareCodebook.lua', g.problem)
        self.assertEqual(g.ids2[1], 'Target health 2')

    def test_codebook_memory_is_released_after_last_use(self):
        self.lua.execute('''
          local id = fromTemplate("default:Target health")
          assert(RWA.Share.Export({id}))
          assert(RWA.Share.Export({id}))
          held = RWA.Share.codebook ~= nil
          for i = 1, #laterCalls - 1 do laterCalls[i].fn() end
          stillHeld = RWA.Share.codebook ~= nil
          laterCalls[#laterCalls].fn()
          released = RWA.Share.codebook == nil
          keep = laterCalls[#laterCalls].seconds
          again = string.sub(assert(RWA.Share.Export({id})), 1, 5)
        ''')
        g = self.lua.globals()
        self.assertTrue(g.held)
        self.assertTrue(g.stillHeld)
        self.assertTrue(g.released)
        self.assertEqual(g.keep, 30)
        self.assertEqual(g.again, 'RWA5!')

    def test_sorted_pack_does_not_depend_on_insertion_order(self):
        self.lua.execute('''
          local a, b = {}, {}
          for _, k in ipairs({"x", "y", "id", "names", "width"}) do a[k] = k end
          for _, k in ipairs({"width", "names", "id", "y", "x"}) do b[k] = k end
          a[7], b[7] = 1, 1
          same = RWA.Share.Pack(a, true) == RWA.Share.Pack(b, true)
        ''')
        self.assertTrue(self.lua.globals().same)


if __name__ == '__main__':
    unittest.main()
