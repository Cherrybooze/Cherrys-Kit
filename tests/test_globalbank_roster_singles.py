"""Characters page grouped by account: a RoM account with one character has no heading of its own. Its character sits
under its Gameforge account with the RoM account on its line, or, with the switch on, such characters share one heading."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NODE = shutil.which('node')

PAGE = r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
function node() {
  return {children: [], style: {}, innerHTML: '', listeners: {}, nodes: new Map(), dataset: {},
    addEventListener(type, fn) { (this.listeners[type] ||= []).push(fn); }, querySelectorAll() { return []; },
    querySelector(selector) { if (!this.nodes.has(selector)) this.nodes.set(selector, node()); return this.nodes.get(selector); }};
}
const context = vm.createContext({console, document: {createElement: node}});
vm.runInContext(fs.readFileSync(path.join(process.argv[1], 'bank.js'), 'utf8') + ';this.GBBank = GBBank;', context);
const bank = context.GBBank;
const account = (...names) => ({names});
const pair = account('Alpha', 'Beta'), one = account('Gamma'), two = account('Delta');
const characters = [
  {name: 'Alpha', key: 'a', server: 'Gaia', gold: 5, group: pair},
  {name: 'Beta', key: 'b', server: 'Gaia', gold: 1, group: pair},
  {name: 'Gamma', key: 'g', server: 'Gaia', gold: 3, group: one},
  {name: 'Delta', key: 'd', server: 'Gaia', gold: 9, group: two},
  {name: 'Nobody', key: 'n', server: 'Gaia', gold: 2},
];
const html = singlesTogether => {
  const root = node();
  bank.renderRoster(root, characters, {how: 'account', singlesTogether});
  return root.querySelector('table').querySelector('tbody').innerHTML;
};
const headings = text => [...text.matchAll(/data-group-toggle="([^"]*)"/g)].map(found => found[1]);
const order = text => [...text.matchAll(/class="char-name">([^<]*)</g)].map(found => found[1]);

// By account with nothing linked: one heading for the login screens no Gameforge account is linked to, one inside it
// for the RoM account with two characters, and one for the character no login screen has listed
const apart = html(false);
assert.equal(headings(apart).length, 3);
assert.equal(headings(apart).at(-1), '~none');
assert.ok(!apart.includes('Single-character accounts'));
// The two alone on their RoM accounts sit right under it, richest first, each with its RoM account on its own line
assert.deepEqual(order(apart), ['Delta', 'Gamma', 'Alpha', 'Beta', 'Nobody']);
assert.equal((apart.match(/class="rom-chip"/g) || []).length, 2);
assert.match(apart, /Delta<\/span><span class="rom-chip" title="RoM account">Delta&#39;s account</);

// The switch on: they share one heading instead, after the RoM accounts with headings, their RoM accounts only on hover
const together = html(true);
const keys = headings(together);
assert.equal(keys.length, 4);
assert.ok(keys.at(-2).endsWith('|~single'), 'the shared group sits before the characters with no account');
assert.equal(keys.at(-1), '~none');
assert.ok(together.includes('Single-character accounts'));
assert.ok(!together.includes('rom-chip'));
// Inside it the table's sort (gold, highest first) holds, not the accounts' order
const names = order(together);
assert.ok(names.indexOf('Delta') < names.indexOf('Gamma'));
assert.deepEqual(names.slice(0, 2), ['Alpha', 'Beta']);

// Grouped by server, or with one single account only, nothing is shared
const root = node();
bank.renderRoster(root, characters.slice(0, 3), {how: 'account', singlesTogether: true});
assert.ok(!root.querySelector('table').querySelector('tbody').innerHTML.includes('Single-character accounts'));
const byServer = node();
bank.renderRoster(byServer, characters, {how: 'server', singlesTogether: true});
assert.ok(!byServer.querySelector('table').querySelector('tbody').innerHTML.includes('Single-character accounts'));
'''


@unittest.skipUnless(NODE, 'Node.js is not installed')
class RosterSinglesTests(unittest.TestCase):
    def test_single_character_accounts_share_one_group(self):
        result = subprocess.run([NODE, '-e', PAGE, str(EXTENSION)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_page_has_the_switch_beside_the_login_button(self):
        html = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        self.assertLess(html.index('id="roster-singles"'), html.index('id="select-stale"'))
        self.assertIn('Show single-character accounts only on tooltip', html)


if __name__ == '__main__':
    unittest.main()
