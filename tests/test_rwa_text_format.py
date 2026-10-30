"""Display text formatting keeps the old gsub output while skipping per-frame closures."""
import unittest

import test_rwa as support


# The pre-0.9.27 formatter, kept as the reference. It uses the real token
# function from Regions.lua, so only the template splitting is compared.
REFERENCE = r'''
  local i = 1
  while true do
    local name, value = debug.getupvalue(RWA.Regions.FormatText, i)
    if not name then break end
    if name == "placeholder" then referencePlaceholder = value end
    i = i + 1
  end
  assert(type(referencePlaceholder) == "function", "FormatText no longer uses placeholder()")
  function referenceFormat(template, state, now)
    if template=="%v / %t" and state.healthText then return state.healthText end
    if not template or template == "" then return "" end
    return (string.gsub(template, "%%(%a+)", function(word)
      local value = referencePlaceholder(word, state, now)
      if value then return value end
      local first = string.sub(word, 1, 1)
      value = referencePlaceholder(first, state, now)
      if value then return value .. string.sub(word, 2) end
      return "%" .. word
    end))
  end
'''

TEMPLATES = [
    "", "plain text", "%n", "%p", "%ps", "%t", "%s", "%v", "%pct", "%pct%", "%u", "%e",
    "%n - %p / %t", "50%", "100%%", "%", "%%n", "%xyz", "%nx", "%p%s%t", " %v / %t ",
    "%v / %t", "a%", "%1", "%n%", "x%py%", "%Ps", "%e: %n", "%pct%% done", "%name",
]


class TextFormatTests(unittest.TestCase):
    def setUp(self):
        self.h = support.RWATests()
        self.h.setUp()
        self.addCleanup(self.h.tearDown)
        self.lua = self.h.lua
        self.lua.execute(REFERENCE)
        self.states = [
            "{}",
            '{name="Rage",value=40,total=100,percent=40,unit="player",stacks=3,progressType="static"}',
            '{name="Buff",progressType="timed",duration=12,expirationTime=fixtureNow+4.4,stacks=1}',
            '{name=17,value=5,startTime=fixtureNow-75}',
            '{healthText="~3000 / 4000 (75%)",value=75,total=100}',
        ]

    def test_every_template_matches_the_previous_formatter(self):
        for state in self.states:
            for template in TEMPLATES:
                with self.subTest(state=state, template=template):
                    self.lua.globals().testTemplate = template
                    expected, actual = self.lua.eval(
                        "(function() local s=" + state + " return referenceFormat(testTemplate,s,fixtureNow),"
                        " RWA.Regions.FormatText(testTemplate,s,fixtureNow) end)()")
                    self.assertEqual(actual, expected)
        for value in ("false", "nil"):
            self.assertEqual(self.lua.eval("RWA.Regions.FormatText(" + value + ",{},0)"), "")
        self.assertEqual(self.lua.eval("RWA.Regions.FormatText(42,{},0)"), "42")

    def test_steady_text_allocates_far_less_than_the_previous_formatter(self):
        used = self.lua.eval('''(function()
          local s={name="Rage",value=40,total=100,percent=40,unit="player",progressType="static"}
          local function measure(fn)
            collectgarbage("collect"); collectgarbage("stop")
            local before=collectgarbage("count")
            for i=1,2000 do fn("%n %v / %t (%pct%)",s,0) end
            local after=collectgarbage("count"); collectgarbage("restart")
            return after-before
          end
          return {old=measure(referenceFormat), new=measure(RWA.Regions.FormatText)}
        end)()''')
        self.assertLess(used.new, 8)
        self.assertLess(used.new * 10, used.old)


    def test_past_second_codes_format_without_new_garbage(self):
        self.h.load("Recent.lua")
        self.lua.execute("""
          past={fightCount=12,fightTime=8,fightRate=1.5,perSecond=2.25,value=3,total=4}
          other={name="Rage",value=40,total=100}
          F=RWA.Regions.FormatText
        """)
        g = self.lua.globals()
        self.assertEqual(self.lua.eval('F("%rate hits/s",past,fixtureNow)'), "2.25 hits/s")
        self.assertEqual(self.lua.eval('F("%fight hits in %ft = %avg/s",past,fixtureNow)'), "12 hits in 8.0s = 1.50/s")
        self.assertEqual(self.lua.eval('F("%rate hits/s",other,fixtureNow)'), "%rate hits/s")
        self.assertEqual(self.lua.eval('F("%v of %t",past,fixtureNow)'), "3 of 4")
        self.lua.execute("""
          for i=1,50 do F("%fight hits in %ft = %avg/s",past,fixtureNow) end
          collectgarbage("collect"); collectgarbage("stop")
          local before=collectgarbage("count")
          for i=1,500 do F("%fight hits in %ft = %avg/s",past,fixtureNow); F("%rate hits/s",past,fixtureNow) end
          garbageKB=collectgarbage("count")-before
          collectgarbage("restart")
        """)
        self.assertLess(g.garbageKB, 1, "formatting the same text again made new tables or functions")


if __name__ == "__main__":
    unittest.main()
