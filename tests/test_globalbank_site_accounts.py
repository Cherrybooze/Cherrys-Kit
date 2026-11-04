"""The Runes of Magic site's account fields: the RoM username and Gameforge e-mail address its transfer and account pages
show, linked to the characters the same login lists, and used as those characters' account names on the Global Bank page."""
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
const context = vm.createContext({console, Intl, Date, crypto: globalThis.crypto, setTimeout, clearTimeout});
for (const [file, name] of [['transfers.js', 'GBTransfers'], ['accounts.js', 'GBAccounts'], ['roster.js', 'GBRoster']]) {
  vm.runInContext(fs.readFileSync(path.join(folder, file), 'utf8') + `;this.${name} = ${name};`, context);
}
const GBT = context.GBTransfers, GBA = context.GBAccounts, GBR = context.GBRoster;
const MIN = 60e3;
"""


@unittest.skipUnless(NODE, 'Node required')
class SiteAccountTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', PRELUDE + source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_the_fields_are_read_with_their_labels_in_any_layout(self):
        self.run_js(r"""
const account = texts => plain(GBT.parseAccount(texts));
// "Username: name" in one piece, or the label and the value apart, with decoration between
assert.deepEqual(account(['MY ACCOUNT', 'Username: rom_main1', 'Email: Player@Example.com']), {user: 'rom_main1', email: 'player@example.com'});
assert.deepEqual(account(['Username', ':', 'rom_main1', 'Email:', 'player@example.com']), {user: 'rom_main1', email: 'player@example.com'});
// The site's other languages
assert.deepEqual(account(['Benutzername:', 'rom_main1', 'E-Mail-Adresse:', 'player@example.com']), {user: 'rom_main1', email: 'player@example.com'});
assert.deepEqual(account(['Nom d’utilisateur : rom_main1']), {user: 'rom_main1', email: ''});
// An empty value never takes the next label as the name, and a sentence is no name
assert.deepEqual(account(['Username:', 'Email:', 'player@example.com']), {user: '', email: 'player@example.com'});
assert.equal(GBT.parseAccount(['Usernames must be 4 to 16 letters long', 'Username', 'must not be empty']), null);
// An unlabelled address counts only when it is the only one on the page
assert.equal(GBT.parseAccount(['Contact', 'support@example.com', 'someone@example.com']), null);
// Text boxes by their labels, never a password
assert.deepEqual(plain(GBT.parseAccount([], [{label: 'Username', value: 'rom_main1'}, {label: 'E-mail', value: 'player@example.com'}])), {user: 'rom_main1', email: 'player@example.com'});
// The whole page: the account page lists the login's characters too
const read = plain(GBT.parsePage({selects: [], texts: ['Username:', 'rom_main1', 'Email:', 'player@example.com', 'Characters', 'Anna (Gaia (PvE))', 'Bert (Kadmos (PvE))']}));
assert.deepEqual(read.account, {user: 'rom_main1', email: 'player@example.com'});
assert.deepEqual(read.listed, [{name: 'Anna', server: 'Gaia'}, {name: 'Bert', server: 'Kadmos'}]);
assert.deepEqual(read.planned, []);
// The background checks it again
assert.deepEqual(plain(GBT.cleanRead({planned: [], offered: [], listed: [{name: 'Anna', server: 'Gaia (PvE)'}], account: {user: '<b>', email: 'Player@Example.com'}})),
  {planned: [], offered: [], listed: [{name: 'Anna', server: 'Gaia'}], form: false, account: {user: '', email: 'player@example.com'}});
assert.equal(GBT.cleanRead({planned: [], offered: [], listed: 'x'}), null);
""")

    def test_characters_the_login_lists_are_linked_to_its_account(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T20:00:00Z');
const read = (extra = {}) => ({planned: [], offered: [], listed: [], form: true, account: null, ...extra});
const main = {user: 'rom_main1', email: 'player@example.com'};
// The transfer page with the fields: its characters, offered and planned, get both
let result = GBT.applyAccount(null, read({planned: [{name: 'Anna', from: 'Gaia', to: 'Kadmos'}], offered: [{name: 'Bert', server: 'Gaia'}], account: main}), {now: t0});
assert.equal(result.changed, true);
assert.deepEqual(plain(result.linked), {...main, count: 2});
assert.deepEqual(Object.keys(result.state.chars).sort(), ['gaia|anna', 'gaia|bert']);
assert.equal(result.state.chars['gaia|anna'].user, 'rom_main1');
let state = result.state;
// Read again soon: nothing new to keep or tell
result = GBT.applyAccount(state, read({offered: [{name: 'Bert', server: 'Gaia'}], account: main}), {now: t0 + MIN, recent: result.recent});
assert.deepEqual([result.changed, result.linked], [false, null]);
// The account page alone, with no characters: remembered for the transfer page opened next with the same login
result = GBT.applyAccount(state, read({account: {user: 'rom_alt2', email: 'alt@example.com'}}), {now: t0 + 2 * MIN});
assert.deepEqual([result.changed, result.linked, result.recent.user], [false, null, 'rom_alt2']);
const recent = result.recent;
result = GBT.applyAccount(state, read({offered: [{name: 'Cleo', server: 'Kerub'}]}), {now: t0 + 5 * MIN, recent});
assert.deepEqual(plain(result.linked), {user: 'rom_alt2', email: 'alt@example.com', count: 1});
state = result.state;
// Remembered, but the page lists a character kept for another account: the site's login changed, so nothing is linked
result = GBT.applyAccount(state, read({offered: [{name: 'Bert', server: 'Gaia'}, {name: 'Dora', server: 'Gaia'}]}), {now: t0 + 6 * MIN, recent});
assert.deepEqual([result.changed, result.linked, result.conflict], [false, null, 1]);
// Too long ago: forgotten
result = GBT.applyAccount(state, read({offered: [{name: 'Dora', server: 'Gaia'}]}), {now: t0 + 2 * 3600e3, recent});
assert.deepEqual([result.changed, result.recent], [false, null]);
// Shown on the page, a new account wins over the one kept: the character moved to another login
result = GBT.applyAccount(state, read({offered: [{name: 'Bert', server: 'Gaia'}], account: {user: 'rom_alt2', email: ''}}), {now: t0 + 7 * MIN});
assert.deepEqual(plain(result.state.chars['gaia|bert']), {user: 'rom_alt2', email: '', at: new Date(t0 + 7 * MIN).toISOString()});
// One field shown, the other remembered from the same login
result = GBT.applyAccount(null, read({offered: [{name: 'Erin', server: 'Gaia'}], account: {user: 'rom_alt2', email: ''}}), {now: t0 + 8 * MIN, recent});
assert.deepEqual(plain(result.linked), {user: 'rom_alt2', email: 'alt@example.com', count: 1});
// What's kept is checked when loaded
assert.deepEqual(plain(GBT.loadAccounts({chars: {'gaia|anna': {user: 'ok_1', email: 'x', at: '2026-11-04T00:00:00Z'}, bad: {user: 'a', at: 'x'}}})).chars,
  {'gaia|anna': {user: 'ok_1', email: '', at: '2026-11-04T00:00:00Z'}});
""")

    def test_the_background_keeps_links_from_both_pages(self):
        self.run_js(r"""
(async () => {
  let listener;
  const local = {}, session = {};
  const area = store => ({get: async keys => Object.fromEntries([].concat(keys).filter(key => key in store).map(key => [key, plain(store[key])])),
    set: async data => Object.assign(store, plain(data)), remove: async keys => { for (const key of [].concat(keys)) delete store[key]; }, setAccessLevel: async () => {}});
  const chrome = {runtime: {id: 'test', getURL: file => 'chrome-extension://test/' + file, onMessage: {addListener: fn => { listener = fn; }},
    onStartup: {addListener() {}}, onInstalled: {addListener() {}}, sendNativeMessage: (host, message, reply) => reply({ok: true})},
    storage: {local: area(local), session: area(session), onChanged: {addListener() {}}}, alarms: {create() {}, onAlarm: {addListener() {}}}};
  const sandbox = {chrome, URL, console, setTimeout, clearTimeout, Date, Intl, crypto: globalThis.crypto,
    importScripts: file => vm.runInContext(fs.readFileSync(path.join(folder, file), 'utf8'), sandbox)};
  vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(folder, 'background.js'), 'utf8'), sandbox);
  const ask = (message, url) => new Promise(resolve => { if (listener(message, {id: 'test', tab: {id: 5}, url}, resolve) !== true) resolve('no answer'); });
  const admin = 'https://en.runesofmagic.gameforge.com/user/administration', transfer = 'https://en.runesofmagic.gameforge.com/charactertransfer';
  // The account page first: the login, remembered for a while, nothing linked yet
  let answer = await ask({type: 'transfer-page', planned: [], offered: [], listed: [], form: false, account: {user: 'rom_main1', email: 'player@example.com'}}, admin);
  assert.deepEqual(plain(answer), {ok: true, added: [], ended: [], linked: null, remembered: {user: 'rom_main1', email: 'player@example.com'}});
  assert.equal(session.siteLogin.user, 'rom_main1');
  assert.equal(local.gbSiteAccounts, undefined);
  // Then the transfer page without the fields: its characters join that login
  answer = await ask({type: 'transfer-page', planned: [], offered: [{name: 'Anna', server: 'Gaia'}], form: true}, transfer);
  assert.deepEqual(plain(answer.linked), {user: 'rom_main1', email: 'player@example.com', count: 1});
  assert.deepEqual(plain(local.gbSiteAccounts.chars['gaia|anna']).user, 'rom_main1');
  // Another site's page can't
  assert.equal(await ask({type: 'transfer-page', planned: [], offered: [], account: {user: 'x_1', email: ''}}, 'https://evil.example/user/administration'), 'no answer');
  process.exit(0);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_the_page_names_accounts_from_the_site(self):
        self.run_js(r"""
const characters = [
  {name: 'Ann', server: 'Gaia', gold: 5, roster: ['Ann', 'Bea']},
  {name: 'Bea', server: 'Gaia', gold: 7},
  {name: 'Cal', server: 'Gaia', gold: 1, roster: ['Cal', 'Dot']},
  {name: 'Dot', server: 'Gaia', gold: 2},
  {name: 'Eve', server: 'Kadmos', gold: 3},
];
const [ann, bea, cal, dot, eve] = characters;
const site = {chars: {'gaia|bea': {user: 'rom_main1', email: 'player@example.com', at: '2026-11-04T20:00:00Z'},
  'kadmos|eve': {user: 'rom_eve', email: 'eve@example.com', at: '2026-11-04T20:00:00Z'}}};
const store = {gbSiteAccounts: site};
const roster = GBR.create({get: async () => plain(store), set: async data => { Object.assign(store, plain(data)); }});
(async () => {
  await roster.load();
  GBR.prepare(characters, GBA.accountGroups, roster.assigned());
  roster.setCharacters(characters);
  // The site's username replaces "Ann's account" for every character on that login screen; a name you gave still wins
  assert.equal(roster.romTitle(ann), 'rom_main1');
  assert.equal(roster.romTitle(bea), 'rom_main1');
  assert.equal(roster.romTitle(cal), "Cal's account");
  // A character no login screen listed yet still gets it
  assert.equal(roster.romTitle(eve), 'rom_eve');
  assert.equal(roster.siteEmail(ann), 'player@example.com');
  assert.equal(roster.siteEmailByLabel('Eve'), 'eve@example.com');
  roster.setRomName(ann, 'Mains');
  assert.equal(roster.romTitle(bea), 'Mains');
  // Changed in storage: drawn again with the new names
  const told = [];
  roster.onChange(what => told.push(what));
  roster.setSiteAccounts({chars: {'gaia|dot': {user: 'rom_alts', email: '', at: '2026-11-04T20:00:00Z'}}});
  assert.deepEqual(told, ['names']);
  assert.equal(roster.romTitle(cal), 'rom_alts');
  assert.equal(roster.siteEmail(ann), '');
  // A transferred character keeps its account: by its old key, or by a name only one account has
  assert.deepEqual(plain(GBR.siteAccountOf({'gaia|zed': {user: 'u_1', email: ''}}, {key: 'kadmos|zed', formerKey: 'gaia|zed', name: 'Zed'})), {user: 'u_1', email: ''});
  assert.deepEqual(plain(GBR.siteAccountOf({'gaia|zed': {user: 'u_1', email: ''}}, {key: 'kadmos|zed', name: 'Zed'})), {user: 'u_1', email: ''});
  assert.equal(GBR.siteAccountOf({'gaia|zed': {user: 'u_1', email: ''}, 'kerub|zed': {user: 'u_2', email: ''}}, {key: 'kadmos|zed', name: 'Zed'}), null);
  // Gameforge: unlinked characters join the saved account named by their e-mail address; a link made by hand stays
  const state = {accounts: [{id: 'g1', name: 'Player@Example.com'}, {id: 'g2', name: 'Other'}], links: {'gaia|bea': 'g2'}};
  const emails = {Ann: 'player@example.com', Bea: 'player@example.com', Cal: 'nobody@example.com'};
  assert.equal(GBA.autoLink(state, [ann, bea, cal], character => emails[character.name] || ''), 1);
  assert.deepEqual(plain(state.links), {'gaia|bea': 'g2', 'gaia|ann': 'g1'});
  assert.equal(GBA.autoLink(state, [ann, bea, cal], character => emails[character.name] || ''), 0);
  // Forget: every character on that login screen, and only them
  assert.equal(await roster.forgetSiteAccount(ann), 1);
  assert.deepEqual(Object.keys(store.gbSiteAccounts.chars), ['kadmos|eve']);
  assert.equal(await roster.forgetSiteAccount(cal), 0);
  process.exit(0);
})().catch(error => { console.error(error); process.exit(1); });
""")


if __name__ == '__main__':
    unittest.main()
