"""Stats-page colours, owner identity and local exclusion controls, using fixture data only."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NODE = shutil.which('node')

PAGE = r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
function node(tag = 'div') {
  return {tag, children: [], style: {}, hidden: false, value: '', textContent: '', innerHTML: '', listeners: {}, nodes: new Map(),
    append(...children) { this.children.push(...children); }, replaceChildren(...children) { this.children = children; },
    setAttribute(name, value) { this[name] = value; },
    addEventListener(type, fn) { (this.listeners[type] ||= []).push(fn); },
    async fire(type, event = {}) { for (const fn of this.listeners[type] || []) await fn(event); },
    querySelector(selector) { if (!this.nodes.has(selector)) this.nodes.set(selector, node()); return this.nodes.get(selector); }};
}
const document = {createElement: node};
const context = vm.createContext({console, document, window: {innerWidth: 1200, innerHeight: 800}});
for (const [file, name] of [['bank.js', 'GBBank'], ['accounts.js', 'GBAccounts']])
  vm.runInContext(fs.readFileSync(path.join(process.argv[1], file), 'utf8') + `;this.${name} = ${name};`, context);
const bank = context.GBBank, accounts = context.GBAccounts;
const green = 'Stamina I', yellow = 'Ability of the Dreamer';
const tip = [['ffffff', 'Mana Stone Tier 6'], ['ffffff', 'Cannot be sold'],
  ['00ff00', '+3 Stamina', 'ffffff', green], ['ffff00', '+42 Stamina', 'ffffff', yellow], ['ffff00', '+84 Maximum HP']];
const characters = [
  {name: 'FixtureMage', key: 'mage-east', classToken: 'MAGE', bag: [{id: '202845', count: 2, stats: [green, yellow], tip}]},
  {name: 'FixtureScout', key: 'scout-west', classToken: 'RANGER', bag: [{id: '202845', count: 1, stats: [green], tip}]},
];
const entries = bank.entries(characters);
let saved = {}, writes = [], menus = [];
const storage = {async get() { return saved; }, async set(value) { writes.push(value); saved = JSON.parse(JSON.stringify(value)); }};
const options = {data: {entries}, all: entries, storage, classColor: accounts.classColor, menu(event, rows, owners) { menus.push({event, rows, owners}); }};
const rootOf = () => { const root = node(); root.querySelector('#stat-kind').value = 'stones'; return root; };
const rows = root => root.querySelector('table').querySelector('tbody').innerHTML;
const flush = async () => { for (let i = 0; i < 8; i++) await new Promise(resolve => setImmediate(resolve)); };
const target = stat => ({dataset: {stat}, closest() { return this; }, getBoundingClientRect() { return {left: 40, bottom: 80}; }});
const event = stat => ({target: target(stat), clientX: 20, clientY: 30, preventDefault() {}, stopPropagation() {}});
'''


@unittest.skipUnless(NODE, 'Node required')
class StatsPageTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', PAGE + source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_saved_game_colours_and_inline_effects_match_the_name(self):
        self.run_js(r'''
(async () => {
  const root = rootOf();
  bank.renderStats(root, characters, options);
  await flush();
  const html = rows(root);
  assert.match(html, /class="stat-name" style="color:#00ff00">Stamina I/);
  assert.match(html, /class="stat-name" style="color:#ffff00">Ability of the Dreamer/);
  const stamina = html.match(/<td[^>]*>(<span class="stat-entry" data-stat="Stamina I"[^]*?)<\/td>/)[1];
  assert.match(stamina, /class="stat-effects"><span style="color:#00ff00">\+3 Stamina/);
  assert.match(html, /style="color:#ffff00">\+42 Stamina/);
  assert.match(html, /style="color:#ffff00">\+84 Maximum HP/);
  const known = bank.statEffects(entries);
  assert.deepEqual(JSON.parse(JSON.stringify(bank.templateTip(green, known))).at(-1), ['00ff00', '+3 Stamina', '00ff00', green]);
  assert.equal(bank.templateTip('Unknown stat', known), null);
})().catch(error => { console.error(error); process.exit(1); });
''')

    def test_who_has_them_uses_the_same_class_resolver_as_the_tooltip(self):
        self.run_js(r'''
const root = rootOf();
bank.renderStats(root, characters, options);
assert.match(rows(root), new RegExp(`style="color:${accounts.classColor(characters[0])}" data-char="mage-east">FixtureMage 2`));
assert.match(rows(root), new RegExp(`style="color:${accounts.classColor(characters[1])}" data-char="scout-west">FixtureScout 1`));
''')

    def test_exclude_persists_after_reopening_and_restore_brings_it_back(self):
        self.run_js(r'''
(async () => {
  const root = rootOf();
  bank.renderStats(root, characters, options);
  await flush();
  await root.querySelector('table').fire('contextmenu', event(green));
  assert.equal(menus[0].rows[0].label, 'Exclude this stat from showing');
  await menus[0].rows[0].run();
  assert.doesNotMatch(rows(root), /data-stat="Stamina I"/);
  assert.match(rows(root), /data-stat="Ability of the Dreamer"/);
  assert.equal(root.querySelector('#stat-excluded-title').textContent, 'Excluded stats (1)');
  assert.deepEqual(saved, {excludedStats: [green]});
  const reopened = rootOf();
  bank.renderStats(reopened, characters, options);
  await flush();
  assert.doesNotMatch(rows(reopened), /data-stat="Stamina I"/);
  const excluded = reopened.querySelector('#stat-excluded-list').children[0];
  assert.equal(excluded.children[0].textContent, green);
  assert.equal(excluded.children[0].style.color, '#00ff00');
  await excluded.children[1].fire('click');
  assert.match(rows(reopened), /data-stat="Stamina I"/);
  assert.deepEqual(saved, {excludedStats: []});
  assert.equal(reopened.querySelector('#stat-excluded-title').textContent, 'Excluded stats (0)');
})().catch(error => { console.error(error); process.exit(1); });
''')

    def test_keyboard_menu_restore_all_and_filters_keep_the_exclusions(self):
        self.run_js(r'''
(async () => {
  const root = rootOf();
  bank.renderStats(root, characters, options);
  await flush();
  await root.querySelector('table').fire('keydown', {...event(green), clientX: undefined, clientY: undefined, key: 'F10', shiftKey: true});
  assert.equal(menus[0].event.clientX, 40);
  await menus[0].rows[0].run();
  await root.querySelector('table').fire('contextmenu', event(yellow));
  await menus[1].rows[0].run();
  assert.match(rows(root), /restore stats under Excluded stats/);
  root.querySelector('#stat-search').value = 'Stamina';
  await root.querySelector('#stat-search').fire('input');
  assert.doesNotMatch(rows(root), /data-stat="Stamina I"/);
  await root.querySelector('#stat-restore-all').fire('click');
  assert.match(rows(root), /data-stat="Stamina I"/);
  assert.deepEqual(saved, {excludedStats: []});
})().catch(error => { console.error(error); process.exit(1); });
''')

    def test_invalid_saved_values_and_missing_colours_do_not_become_html(self):
        self.run_js(r'''
(async () => {
  saved = {excludedStats: ['Hidden stat', null, {}, '\u0000bad', 42]};
  const root = rootOf();
  const odd = '<img src=x onerror=bad>';
  const unknown = bank.entries([{name: '<b>Fixture</b>', bag: [{id: '202845', stats: [odd], tip: [['red" onclick="bad', '+1 Value', '', odd]]}]}]);
  bank.renderStats(root, [], {...options, data: {entries: unknown}, all: unknown});
  await flush();
  assert.equal(root.excludedStats.size, 1);
  assert.match(rows(root), /&lt;img/);
  assert.doesNotMatch(rows(root), /<img|<b>|onclick=/);
})().catch(error => { console.error(error); process.exit(1); });
''')

    def test_storage_errors_are_reported_without_silently_losing_preferences(self):
        self.run_js(r'''
(async () => {
  const root = rootOf();
  bank.renderStats(root, characters, {...options, storage: {async get() { throw new Error('unavailable'); }}});
  await flush();
  await root.querySelector('table').fire('contextmenu', event(green));
  await menus[0].rows[0].run();
  assert.match(root.querySelector('#stat-status').textContent, /Could not read your excluded stats/);
  assert.match(rows(root), /data-stat="Stamina I"/);
})().catch(error => { console.error(error); process.exit(1); });
''')
