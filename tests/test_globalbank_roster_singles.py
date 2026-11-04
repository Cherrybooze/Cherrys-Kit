"""Characters page grouped by account: accounts with one character can share one group instead of a heading each."""
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

const apart = html(false);
assert.equal(headings(apart).length, 4);
assert.ok(!apart.includes('Single-character accounts'));

const together = html(true);
const keys = headings(together);
assert.deepEqual(keys.slice(-2), ['~single', '~none'], 'the shared group sits before the characters with no account');
assert.equal(keys.length, 3);
assert.ok(together.includes('Single-character accounts'));
// Inside it the table's sort (gold, highest first) holds, not the accounts' order
const names = order(together);
assert.ok(names.indexOf('Delta') < names.indexOf('Gamma'));
assert.deepEqual(names.slice(0, 2), ['Alpha', 'Beta']);

// Grouped by server, or with one single account only, nothing changes
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
