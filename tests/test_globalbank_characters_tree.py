"""The Characters page by account: each Gameforge account once with its RoM accounts under it, the Gameforge account's
name copied with a click, characters linked by the e-mail address the site showed, and characters a transfer renamed."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NODE = shutil.which('node')

PRELUDE = r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const folder = process.argv[1];
const plain = value => JSON.parse(JSON.stringify(value));
function node() {
  return {children: [], style: {}, innerHTML: '', listeners: {}, nodes: new Map(), dataset: {},
    addEventListener(type, fn) { (this.listeners[type] ||= []).push(fn); }, querySelectorAll() { return []; }, prepend() {},
    querySelector(selector) { if (!this.nodes.has(selector)) this.nodes.set(selector, node()); return this.nodes.get(selector); }};
}
const context = vm.createContext({console, Intl, Date, crypto: globalThis.crypto, setTimeout, clearTimeout, document: {createElement: node}});
for (const [file, name] of [['bank.js', 'GBBank'], ['transfers.js', 'GBTransfers'], ['accounts.js', 'GBAccounts']]) {
  vm.runInContext(fs.readFileSync(path.join(folder, file), 'utf8') + `;this.${name} = ${name};`, context);
}
const bank = context.GBBank, GBT = context.GBTransfers, GBA = context.GBAccounts;
const pad = n => String(n).padStart(2, '0');
const saved = ms => { const d = new Date(ms); return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`; };
const H = 3600e3, D = 24 * H;
"""


@unittest.skipUnless(NODE, 'Node.js is not installed')
class CharactersTreeTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', PRELUDE + source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)

    def test_each_gameforge_account_once_with_its_rom_accounts_under_it(self):
        self.run_js(r"""
// Login screens: each a list of names, one server's
const list = (...names) => ({names});
const steam = (...names) => ({names, steam: true});
const u7a = list('B1'), u7b = list('B2'), main = list('C1', 'C2'), s1 = steam('S1'), s2 = steam('S2'), loose = list('L1', 'L2');
let gold = 100;
const row = (name, server, account, rom, group) => ({name, key: `${server.toLowerCase()}|${name.toLowerCase()}`, server, account, rom, gold: gold--, character: {romAccount: group}});
// In the table's order: richest first
const rows = [
  row('A1', 'Gaia', 'a@example.com', 'u10', list('A1')),
  row('A2', 'Gaia', 'a@example.com', 'u9', list('A2', 'A3')),
  row('A3', 'Gaia', 'a@example.com', 'u9', list('A2', 'A3')),
  row('A4', 'Aynara', 'a@example.com', 'u2', list('A4', 'A5')),
  row('A5', 'Aynara', 'a@example.com', 'u2', list('A4', 'A5')),
  row('A6', 'Aynara', 'a@example.com', 'u9', list('A6')),
  // One RoM username on two login screen lists of one server: one RoM account
  row('B1', 'Gaia', 'a@example.com', 'u7', u7a),
  row('B2', 'Gaia', 'a@example.com', 'u7', u7b),
  row('C1', 'Kadmos', 'b@example.com', 'main', main),
  row('C2', 'Kadmos', 'b@example.com', 'main', main),
  row('S1', 'Kerub', '', 'Steam account', s1),
  row('S2', 'Kerub', '', 'Steam account', s2),
  row('L1', 'Aynara', '', "L1's account", loose),
  row('L2', 'Aynara', '', "L1's account", loose),
  row('N1', '', '', '', null),
];
const tree = bank.accountTree(rows.map(item => ({...item})), {});
assert.deepEqual(plain(tree.map(top => top.key)), ['gf:a@example.com', 'gf:b@example.com', '~steam', '~nolink', '~none']);
const [first, second, steamTop, nolink, none] = tree;
// Its RoM accounts: the ones alone on theirs right under it, in the table's order, each with its RoM account on its line;
// then the ones with more, by server, then by name the way people count (u7 before u9 before u10)
assert.equal(first.romAccounts, 5);
assert.equal(first.children[0].title, null);
assert.deepEqual(plain(first.children[0].rows.map(item => [item.name, item.chip])), [['A1', 'u10'], ['A6', 'u9']]);
assert.deepEqual(plain(first.children.slice(1).map(child => [child.rom, child.server, child.rows.map(item => item.name).join()])),
  [['u2', 'Aynara', 'A4,A5'], ['u7', 'Gaia', 'B1,B2'], ['u9', 'Gaia', 'A2,A3']]);
assert.equal(first.gf, 'a@example.com');
// A Gameforge account with only one RoM account says both on one heading, its characters right under it
assert.deepEqual(plain([second.gf, second.rest, second.server, second.children]), ['b@example.com', ' › main', 'Kadmos', null]);
// Steam logins: each login screen its own, and "Steam account" isn't written on every line
assert.equal(steamTop.title, 'Steam logins');
assert.deepEqual(plain(steamTop.children.map(child => child.rows.map(item => [item.name, item.chip]))), [[['S1', ''], ['S2', '']]]);
assert.equal(nolink.title, "Not linked to a Gameforge account › L1's account");
assert.deepEqual(plain([none.title, none.children, none.rows.map(item => item.name)]), ['No account known yet', null, ['N1']]);
// Locked accounts say so
assert.equal(bank.accountTree(rows.slice(12, 14).map(item => ({...item})), {locked: () => true})[0].title, "Gameforge accounts locked › L1's account");
// Together: the characters alone on their RoM accounts share one heading, last under their Gameforge account
const together = bank.accountTree(rows.map(item => ({...item})), {singlesTogether: true})[0];
assert.deepEqual(plain(together.children.map(child => child.title)), ['u2', 'u7', 'u9', 'Single-character accounts']);
assert.ok(together.children.at(-1).rows.every(item => !item.chip));
""")

    def test_the_characters_table_draws_the_tree(self):
        self.run_js(r"""
const list = (...names) => ({names});
const pair = list('Ann', 'Bea'), lone = list('Cal'), twoOther = list('Dot', 'Eve');
const characters = [
  {name: 'Ann', key: 'gaia|ann', server: 'Gaia', gold: 5, group: pair, romAccount: pair},
  {name: 'Bea', key: 'gaia|bea', server: 'Gaia', gold: 1, group: pair, romAccount: pair},
  {name: 'Cal', key: 'gaia|cal', server: 'Gaia', gold: 3, romAccount: lone, roster: ['Cal']},
  // Only the transfer page knows it: no gold to count
  {name: 'Fay', key: 'kadmos|fay', server: 'Kadmos', notSaved: true, fromTransfer: true, formerName: 'Old'},
  {name: 'Dot', key: 'kadmos|dot', server: 'Kadmos', gold: 9, group: twoOther, romAccount: twoOther},
  {name: 'Eve', key: 'kadmos|eve', server: 'Kadmos', gold: 2, group: twoOther, romAccount: twoOther},
];
const gf = {ann: 'player@example.com', bea: 'player@example.com', cal: 'player@example.com', fay: 'player@example.com', dot: 'alt@example.com', eve: 'alt@example.com'};
const rom = {ann: 'rom_main', bea: 'rom_main', cal: 'rom_cal', dot: 'rom_alt', eve: 'rom_alt'};
const root = node();
bank.renderRoster(root, characters, {how: 'account', accountName: name => gf[name.toLowerCase()] || '', romTitle: character => rom[character.name.toLowerCase()] || ''});
const html = root.querySelector('table').querySelector('tbody').innerHTML;
// Each Gameforge account's name is a button that copies it, once
assert.equal((html.match(/data-gf-copy="player@example.com"/g) || []).length, 1);
assert.match(html, /<button type="button" class="gf-name" data-gf-copy="alt@example.com">alt@example.com<span class="ico gf-name-icon" data-cell-icon="copy"/);
// Its heading counts its RoM accounts; the unsaved one has no gold to count, and says so
assert.match(html, /2 RoM accounts · 4 characters · 9 gold · 1 not saved yet/);
// The one with a single RoM account: both on one heading
assert.match(html, /data-group-toggle="gf:alt@example.com" tabindex="-1"> › rom_alt<\/button><span class="group-server">Kadmos<\/span> <span class="group-sub">2 characters · 11 gold</);
// Alone on its RoM account: its name on its line; a RoM account with more has its own heading, its rows a step in
assert.match(html, /Cal<\/span><span class="rom-chip" title="RoM account">rom_cal</);
assert.match(html, /class="group-row is-sub" data-group="gf:player@example.com\|gaia\|rom_main"/);
assert.match(html, /data-char="gaia\|ann" class="char-row is-depth-2/);
// A character a transfer renamed shows its old name, and the unsaved row is marked so
assert.match(html, /Fay<\/span><span class="was-name" title="Renamed in a character transfer">was Old</);
assert.match(html, /class="char-row is-depth-1 is-blank"/);
// Its Select takes the whole Gameforge account
let picked = null;
bank.renderRoster(root, characters, {how: 'account', accountName: name => gf[name.toLowerCase()] || '', romTitle: character => rom[character.name.toLowerCase()] || '', selectKeys: keys => { picked = keys; }});
root.selectGroup('gf:player@example.com');
assert.deepEqual(plain(picked).sort(), ['gaia|ann', 'gaia|bea', 'gaia|cal', 'kadmos|fay']);
root.selectGroup('gf:player@example.com|gaia|rom_main');
assert.deepEqual(plain(picked), ['gaia|ann', 'gaia|bea']);
// By server the Gameforge column copies too, and the old name finds it
const byServer = node();
bank.renderRoster(byServer, characters, {how: 'server', accountName: name => gf[name.toLowerCase()] || '', search: 'old'});
const found = byServer.querySelector('table').querySelector('tbody').innerHTML;
assert.match(found, /data-gf-copy="player@example.com"/);
assert.deepEqual([...found.matchAll(/class="char-name">([^<]*)</g)].map(hit => hit[1]), ['Fay']);
// The Currencies table groups the same way
const money = node();
bank.renderCurrencies(money, characters, {how: 'account', accountName: name => gf[name.toLowerCase()] || '', romTitle: character => rom[character.name.toLowerCase()] || ''});
assert.match(money.querySelector('table').querySelector('tbody').innerHTML, /data-gf-copy="player@example.com"/);
""")

    def test_characters_join_the_gameforge_account_the_site_showed_them_with(self):
        self.run_js(r"""
const character = (name, server = 'Gaia') => ({name, key: `${server.toLowerCase()}|${name.toLowerCase()}`, shownServer: server});
const [ann, bea, cal, dot, eve] = ['Ann', 'Bea', 'Cal', 'Dot', 'Eve'].map(name => character(name));
const emails = {Ann: 'player@example.com', Bea: 'Player@Example.com', Cal: 'other@example.com', Dot: '', Eve: 'player@example.com'};
const site = item => emails[item.name] || '';
const state = {accounts: [{id: 'g1', name: 'Kept by hand'}], links: {}};
// Nothing on the list by those addresses: nothing to link to, and nothing added unless asked
assert.equal(GBA.autoLink(state, [ann, bea, cal, dot], site), 0);
assert.equal(state.accounts.length, 1);
// Added: one account for each address, with no password yet, and every character with it linked to it
assert.equal(GBA.autoLink(state, [ann, bea, cal, dot], site, true), 3);
assert.deepEqual(plain(state.accounts.map(account => [account.name, account.password ?? null, account.email ?? null])),
  [['Kept by hand', null, null], ['player@example.com', '', 'player@example.com'], ['other@example.com', '', 'other@example.com']]);
const player = state.accounts[1];
assert.equal(state.links['gaia|ann'], player.id);
assert.equal(state.links['gaia|bea'], player.id);
assert.equal(state.links['gaia|dot'], undefined);
// Renamed on the list: characters the site shows with its address later still join it, and no second one is added
player.name = 'My main account';
assert.equal(GBA.autoLink(state, [eve], site, true), 1);
assert.equal(state.links['gaia|eve'], player.id);
assert.equal(state.accounts.length, 3);
// Deleted: its characters are unlinked, and its address isn't added back on its own
GBA.removeAccount(state, state.accounts[2].id);
assert.deepEqual(plain(state.removed), ['other@example.com']);
assert.equal(GBA.autoLink(state, [cal], site, true), 0);
assert.equal(state.accounts.length, 2);
// Unlinked by hand: it stays unlinked
delete state.links['gaia|ann'];
state.noAuto = {'gaia|ann': true};
assert.equal(GBA.autoLink(state, [ann], site, true), 0);
// A link made by hand to another account stays
state.links['gaia|bea'] = 'g1';
assert.equal(GBA.autoLink(state, [bea], site, true), 0);
assert.equal(state.links['gaia|bea'], 'g1');
""")

    def test_a_transfer_that_renamed_the_character(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T08:00:00Z'), after = Date.parse('2026-11-05T12:00:00Z');
// Registered with its account's characters then: Mate on Gaia and Known on Kadmos
let state = GBT.applyRead(null, {planned: [{name: 'Oldname', from: 'Gaia', to: 'Kadmos'}], offered: [{name: 'Mate', server: 'Gaia'}, {name: 'Known', server: 'Kadmos'}], form: true}, {now: t0}).state;
const id = state.list[0].id;
state = GBT.applyChanges(state, GBT.cleanChanges([{id, state: 'moved', at: after, text: 'Gone'}]), after).state;
const save = (name, server, gold, at) => ({name, server, roster: [name], saved: saved(at), level: 100, class: 'Scout', gold});
const old = () => ({...save('Oldname', 'Gaia', 1234, t0 - H), roster: ['Oldname', 'Mate']});
const fresh = save('Newname', 'Kadmos', 1234, after + H);
// Without the site: the one character new on Kadmos with its class, level and gold to the coin. Known was on its
// account already, and Other has other gold.
let changes = plain(GBT.evidence(state.list, [old(), fresh, save('Known', 'Kadmos', 1234, after + H), save('Other', 'Kadmos', 99, after + H)], {now: after + 2 * H}));
assert.deepEqual(changes.map(change => [change.state, change.name || '']), [['renamed', 'Newname'], ['done', '']]);
assert.match(changes[0].text, /with its class, level and gold/);
assert.match(changes[1].text, /^Logged in on Kadmos as Newname: transfer confirmed/);
// Two that fit: neither is taken
const twin = save('Twin', 'Kadmos', 1234, after + H);
assert.deepEqual(plain(GBT.evidence(state.list, [old(), fresh, twin], {now: after + 2 * H})), []);
// The site showed the old name and one of them on the same RoM username: that one, whatever its gold
const site = {'gaia|oldname': {user: 'rom_1'}, 'kadmos|twin': {user: 'rom_1'}, 'kadmos|newname': {user: 'rom_2'}};
changes = plain(GBT.evidence(state.list, [old(), fresh, {...twin, gold: 5}], {now: after + 2 * H, siteOf: key => site[key] || null}));
assert.deepEqual(changes.map(change => [change.state, change.name || '']), [['renamed', 'Twin'], ['done', '']]);
assert.match(changes[0].text, /on the same RoM account \(rom_1\)/);
// Kept: renamed and confirmed
state = GBT.applyChanges(state, GBT.cleanChanges(changes), after + 2 * H).state;
assert.deepEqual([state.list[0].state, state.list[0].renamed], ['done', 'Twin']);
assert.equal(state.list[0].events.at(-2).what, 'renamed');
// Shown: its new name's save, with the old name beside it; its old server's copy goes
const oldCopy = old();
let shown = GBT.overlay([oldCopy, {...twin}], state.list);
assert.deepEqual(plain(shown.map(character => [character.name, character.server, character.formerName, character.formerKey, character.transfer.state])),
  [['Twin', 'Kadmos', 'Oldname', 'gaia|oldname', 'done']]);
assert.match(GBT.cardLine(shown[0], state.list, after + 3 * H).text, /^Came from Gaia by transfer, renamed from Oldname/);
assert.equal(GBT.tipOf(state.list[0], after + 3 * H).title, 'Transfer: Oldname → Twin');
// Not renamed after all: it waits for a login again, and that name isn't taken for it again
state = GBT.applyChanges(state, GBT.cleanChanges([{id, state: 'unrename', at: after + 3 * H}]), after + 3 * H).state;
assert.deepEqual(plain([state.list[0].state, state.list[0].renamed, state.list[0].done, state.list[0].notRenamed]), ['moved', null, null, ['twin']]);
assert.deepEqual(plain(GBT.evidence(state.list, [old(), {...twin, gold: 5}], {now: after + 4 * H, siteOf: key => site[key] || null})), []);
// Set by hand: until the new name logs in, the copy it carried shows under that name, with the old one beside it
assert.equal(GBT.cleanChanges([{id, state: 'renamed'}]), null);
assert.equal(GBT.cleanChanges([{id, state: 'renamed', name: 'two words'}]), null);
state = GBT.applyChanges(state, GBT.cleanChanges([{id, state: 'renamed', name: 'Handname', at: after + 4 * H}]), after + 4 * H).state;
assert.deepEqual(plain([state.list[0].renamed, state.list[0].notRenamed]), ['Handname', ['twin']]);
const carried = old();
shown = GBT.overlay([carried], state.list);
assert.deepEqual(plain([shown[0].name, shown[0].base, shown[0].server, shown[0].formerName, shown[0].formerKey, shown[0].transfer.renamed]),
  ['Handname', 'Handname', 'Kadmos', 'Oldname', 'gaia|oldname', 'Handname']);
assert.match(GBT.plateOf(shown[0], state.list, after + 4 * H).label, /to Kadmos as Handname/);
// The saves still say what they saved: the copy is Oldname's
assert.deepEqual(plain(GBT.evidence(state.list, [carried], {now: after + 5 * H})), []);
// Every run starts from the saves again
shown = GBT.overlay([carried], []);
assert.deepEqual(plain([shown[0].name, shown[0].server, shown[0].formerName]), ['Oldname', 'Gaia', null]);
// Nothing saved at all: a blank row under its new name
shown = GBT.overlay([], state.list);
assert.deepEqual(plain([shown[0].name, shown[0].server, shown[0].formerName, shown[0].notSaved]), ['Handname', 'Kadmos', 'Oldname', true]);
// Its own name again: the same as not renamed
state = GBT.applyChanges(state, GBT.cleanChanges([{id, state: 'renamed', name: 'oldname', at: after + 5 * H}]), after + 5 * H).state;
assert.equal(state.list[0].renamed, undefined);
// A stored name that isn't one is dropped on load
assert.equal(GBT.load({v: 1, list: [{...plain(state.list[0]), renamed: 'not a name!'}]}).list[0].renamed, undefined);
""")

    def test_page_wiring(self):
        control = (EXTENSION / 'control.js').read_text(encoding='utf-8')
        html = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        # The page copies a Gameforge account's name and shows its tooltip
        self.assertIn("closest?.('[data-gf-copy]')", control)
        self.assertIn('navigator.clipboard.writeText(name)', control)
        self.assertIn('id="gf-tooltip"', html)
        self.assertIn("'Password missing'", control)
        # A transfer's new name by hand, and taking it back
        self.assertIn("'Renamed in its transfer…'", control)
        self.assertIn('siteOf: key => roster.siteByKey(key)', control)


if __name__ == '__main__':
    unittest.main()
