"""The Global Bank page's Addons page: its rows in Node, the extension's routing, and the bridge's file moves."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
EXTENSION = HELPER / 'ChromeExtension'
ADDONS = HELPER / 'GlobalBank-Addons.ps1'
SETUP = ROOT / 'Interface/AddOns/CherrysKit/Setup/Setup-CherrysKit.ps1'
NODE = shutil.which('node')
SHELL = shutil.which('powershell') or shutil.which('pwsh')


class AddonsSourceTests(unittest.TestCase):
    def test_setup_stops_after_its_functions_when_loaded(self):
        source = SETUP.read_text(encoding='utf-8')
        self.assertIn('[switch]$LoadOnly', source)
        stop = source.index('if ($LoadOnly) { return }')
        self.assertLess(stop, source.index("Write-Host \"Cherry's Kit - guided setup and update\""))
        # Every function the page uses is defined before the stop.
        for name in ('Get-LatestRelease', 'Get-PackageFolder', 'Read-InstalledVersion', 'Get-KitVersion', 'Compare-KitVersion',
                     'Install-Update', 'Get-HelperProcesses', 'Get-HelperMode', 'Get-GameProcesses', 'Add-SetupLog'):
            self.assertLess(source.index('function ' + name), stop, name)
        # Loading for the page never reaches GitHub by itself.
        self.assertIn('-not $ReleaseFolder -and -not $LoadOnly) {', source)

    def test_bridge_routes_addons_requests(self):
        host = (HELPER / 'GlobalBank-NativeHost.ps1').read_text(encoding='utf-8')
        self.assertIn("if (([string]$message.type) -like 'addons-*') {", host)
        self.assertIn(". (Join-Path $PSScriptRoot 'GlobalBank-Addons.ps1')", host)
        source = ADDONS.read_text(encoding='utf-8')
        for kind in ('list', 'check', 'install', 'offload', 'restore', 'delete'):
            self.assertIn(f"'addons-{kind}'", source)
            self.assertIn(f"'addons-{kind}'", (EXTENSION / 'background.js').read_text(encoding='utf-8'))

    def test_delete_goes_to_the_recycle_bin_and_never_follows_a_link(self):
        source = ADDONS.read_text(encoding='utf-8')
        delete = re.search(r'function Invoke-AddonsDelete.*?\n\}', source, re.S).group(0)
        self.assertIn('RecycleOption]::SendToRecycleBin', delete)
        self.assertLess(delete.index('Test-AddonsLink $path'), delete.index('DeleteDirectory'))
        self.assertIn('[IO.Directory]::Delete($path, $false)', delete)
        self.assertNotIn('Remove-Item -LiteralPath $path', delete)
        # Installs run from a temporary copy, never from the Global Bank folder an update replaces.
        start = re.search(r'function Start-AddonsInstall.*?\n\}', source, re.S).group(0)
        self.assertIn("GetTempPath()", start)
        self.assertIn('-WorkingDirectory $paths.interface', start)

    def test_merged_addons_show_as_replaced(self):
        # The same reading as Get-AddonsReplaced, on the kit's own KitOrigins.lua.
        source = ADDONS.read_text(encoding='utf-8')
        self.assertIn("if ($line -notmatch '^\\s*([A-Za-z0-9_]+) = \\{') { continue }", source)
        self.assertIn("$owner = if ($line -match 'kit_file = \"([^\"/]+)/') { $Matches[1] } else { $key }", source)
        self.assertIn("[regex]::Matches($line, 'folder = \"([^\"]+)\"')", source)
        replaced = {}
        for line in (ROOT / 'Interface/AddOns/CherrysKit/KitOrigins.lua').read_text(encoding='utf-8').splitlines():
            key = re.match(r'^\s*([A-Za-z0-9_]+) = \{', line)
            if key:
                kit_file = re.search(r'kit_file = "([^"/]+)/', line)
                owner = kit_file.group(1) if kit_file else key.group(1)
                for folder in re.findall(r'folder = "([^"]+)"', line):
                    replaced[folder] = owner
        for folder in ('pbInfo', 'PortraitHP', 'TooltipIds', 'ExtendedMacroIcons', 'CherrysQuests'):
            self.assertEqual(replaced.get(folder), 'CherrysInfo', folder)
        self.assertEqual(replaced.get('CherrysLoginxml'), 'LogNextChar')
        self.assertEqual(replaced.get('!CherrysLoadTimes'), 'LoadTimes')
        # A separate copy under the kit's own name is an older one: switching it keeps the kit's.
        self.assertEqual(replaced.get('zBag'), 'zBag')
        # Every owner is a kit folder the release can install.
        kit = ROOT / 'Interface/AddOns/CherrysKit'
        for owner in set(replaced.values()):
            # LogNextChar's source sits beside the kit and installs into CherrysKit/LogNextChar.
            self.assertTrue((kit / owner).is_dir() or (ROOT / 'Interface/AddOns' / owner).is_dir(), owner)
        # A switch only offloads once the new addon is in place, and never when it was skipped.
        window = re.search(r'function Invoke-AddonsInstallWindow.*?\n\}', source, re.S).group(0)
        self.assertLess(window.index('Install-Update $plan'), window.index('Invoke-AddonsOffload'))
        self.assertIn("if ($offload -and $skipped -gt 0) {", window)

    def test_page_is_listed_once_and_loads_its_script(self):
        page = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        self.assertEqual(page.count('data-tab="addons"'), 1)
        self.assertIn('<div id="tab-addons" class="tab-panel" hidden>', page)
        self.assertLess(page.index('src="addons.js"'), page.index('src="control.js"'))
        for name in re.findall(r"byId\('([a-z-]+)'\)", (EXTENSION / 'addons.js').read_text(encoding='utf-8')):
            self.assertIn(f'id="{name}"', page, name)


@unittest.skipUnless(NODE, 'Node required')
class AddonsPageTests(unittest.TestCase):
    def run_js(self, source):
        result = subprocess.run([NODE, '-e', source, str(EXTENSION)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_rows_join_installed_release_and_offloaded(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const context = {console};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'addons.js'), 'utf8') + ';this.GBAddons = GBAddons;', context);
const {kitRows, otherOffloaded, updatable} = context.GBAddons;
const same = (actual, expected) => assert.equal(JSON.stringify(actual), JSON.stringify(expected));
const list = {hasKit: true, kitVersion: '0.11.115', hubVersion: '0.4.30',
  kit: [{folder: 'zBag', title: 'zBag', version: '5.07-ck18'}, {folder: 'GlobalBank', title: 'Global Bank', version: '1.6.1', keep: 'Runs this page'},
        {folder: 'Retired', title: 'Retired', version: ''}],
  others: [{folder: 'Diyce', title: 'DIYCE', version: '2.0'}],
  offloaded: [{id: 'CherrysKit addons/KittyCombo', name: 'KittyCombo', from: 'kit', folder: 'KittyCombo', version: '1.7.18', title: "Cherry's KittyCombo"},
              {id: 'Diyce2', name: 'Diyce2', from: 'addons', folder: 'Diyce2'}, {id: 'zBag', name: 'zBag'}]};
let rows = kitRows(list, null);
same(rows.map(row => row.key), ['Hub', 'zBag', 'GlobalBank', 'Retired', 'KittyCombo']);
assert.equal(rows[0].state, 'unknown');
assert.equal(rows[4].state, 'offloaded');
assert.equal(rows[4].offloaded, 'CherrysKit addons/KittyCombo');
const check = {latestKit: '0.11.116', packages: [
  {package: 'Hub', latest: '0.4.31', state: 'update', bytes: 10},
  {package: 'zBag', folder: 'zBag', title: 'zBag', latest: '5.07-ck19', state: 'update', bytes: 2048},
  {package: 'GlobalBank', folder: 'GlobalBank', title: 'Global Bank', latest: '1.6.1', state: 'current'},
  {package: 'KittyCombo', folder: 'KittyCombo', title: "Cherry's KittyCombo", latest: '1.7.19', state: 'offloaded', offloaded: 'CherrysKit addons/KittyCombo'},
  {package: 'CherrysGrid', folder: 'CherrysGrid', title: "Cherry's Grid", latest: '1.1.6', state: 'missing', bytes: 4096}]};
rows = kitRows(list, check);
const by = Object.fromEntries(rows.map(row => [row.key, row]));
assert.equal(by.zBag.state, 'update');
assert.equal(by.zBag.latest, '5.07-ck19');
assert.equal(by.GlobalBank.state, 'current');
assert.equal(by.Retired.state, 'extra');
assert.equal(by.KittyCombo.state, 'offloaded');
assert.equal(by.KittyCombo.installed, '1.7.18');
assert.equal(by.CherrysGrid.state, 'missing');
assert.equal(rows.filter(row => row.key === 'KittyCombo').length, 1);
same(updatable(rows).map(row => row.package), ['Hub', 'zBag']);
same(otherOffloaded(list).map(entry => entry.id), ['Diyce2', 'zBag']);
const replacedRows = kitRows(list, {packages: [{package: 'pbInfo', folder: 'pbInfo', title: 'pbInfo', latest: '0.60-ck5', state: 'superseded', by: "Cherry's Info"}]});
const pb = replacedRows.find(row => row.key === 'pbInfo');
same(pb.state, 'superseded');
same(pb.by, "Cherry's Info");
same(updatable(replacedRows).length, 0);
same(kitRows({hasKit: false, kit: [], offloaded: []}, null), []);
''')

    def test_background_passes_only_well_formed_addons_requests(self):
        self.run_js(r'''
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const sent = [];
const same = (actual, expected) => assert.equal(JSON.stringify(actual), JSON.stringify(expected));
let listener;
const chrome = {runtime: {id: 'me', getURL: name => 'chrome-extension://me/' + name, lastError: null,
    onMessage: {addListener: callback => { listener = callback; }}, onInstalled: {addListener() {}}, onStartup: {addListener() {}},
    sendNativeMessage: (host, request, callback) => { sent.push(request); callback({ok: true}); }, connectNative: () => ({onMessage: {addListener() {}}, onDisconnect: {addListener() {}}, postMessage() {}})},
  storage: {local: {get: async () => ({}), set: async () => {}, setAccessLevel: async () => {}}, session: {set: async () => {}, setAccessLevel: async () => {}}, onChanged: {addListener() {}}},
  alarms: {create() {}, onAlarm: {addListener() {}}, clear: async () => {}}, action: {setBadgeText() {}}};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'background.js'), 'utf8'), {chrome, console, setTimeout, clearTimeout, URL});
const page = {id: 'me', url: 'chrome-extension://me/control.html'};
const ask = message => { let answer; const kept = listener(message, page, reply => { answer = reply; }); return {kept, answer}; };
assert.equal(ask({type: 'addons-list'}).kept, true);
same(sent.pop(), {type: 'addons-list'});
ask({type: 'addons-install', packages: ['zBag', 'Hub']});
same(sent.pop(), {type: 'addons-install', packages: ['zBag', 'Hub']});
for (const bad of [{type: 'addons-install', packages: ['..\\x']}, {type: 'addons-install', packages: []}, {type: 'addons-offload', where: 'offloaded', name: 'x'},
                   {type: 'addons-delete', where: 'C:', name: 'x'}, {type: 'addons-delete', where: 'kit'}]) {
  assert.notEqual(ask(bad).kept, true, JSON.stringify(bad));
}
assert.equal(sent.length, 0);
ask({type: 'addons-install', packages: ['CherrysInfo'], offload: [{where: 'addons', name: 'pbInfo', extra: 1}]});
same(sent.pop(), {type: 'addons-install', packages: ['CherrysInfo'], offload: [{where: 'addons', name: 'pbInfo'}]});
assert.notEqual(ask({type: 'addons-install', packages: ['CherrysInfo'], offload: [{where: 'offloaded', name: 'x'}]}).kept, true);
assert.notEqual(ask({type: 'addons-install', packages: ['CherrysInfo'], offload: 'pbInfo'}).kept, true);
ask({type: 'addons-delete', where: 'offloaded', name: 'CherrysKit addons/zBag', extra: 'dropped'});
same(sent.pop(), {type: 'addons-delete', name: 'CherrysKit addons/zBag', where: 'offloaded'});
ask({type: 'addons-restore', name: 'zBag', where: 'kit'});
same(sent.pop(), {type: 'addons-restore', name: 'zBag'});
// Web pages can't ask.
assert.notEqual(listener({type: 'addons-list'}, {id: 'me', url: 'https://example.com/', tab: {}}, () => {}), true);
''')


    def test_page_draws_and_its_buttons_ask_the_bridge(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
function node(tag) {
  return {tag, children: [], hidden: false, disabled: false, textContent: '', className: '', listeners: {},
    append(...kids) { this.children.push(...kids); }, replaceChildren(...kids) { this.children = kids; },
    addEventListener(type, callback) { this.listeners[type] = callback; }};
}
const ids = {};
const document = {createElement: node, getElementById: id => (ids[id] ||= node('div'))};
const sent = [];
let confirmAnswer = true;
const answers = {
  'addons-list': {ok: true, hasKit: true, kitVersion: '0.11.115', hubVersion: '0.4.30', gameRunning: false,
    kit: [{folder: 'zBag', title: 'zBag', version: '5.07-ck18'}], others: [{folder: 'Diyce', title: 'DIYCE', version: '2.0'}], offloaded: [], job: null},
  'addons-check': {ok: true, latestKit: '0.11.116', localKit: '0.11.115', ahead: false, packages: [
    {package: 'Hub', latest: '0.4.30', state: 'current', installed: '0.4.30'},
    {package: 'zBag', folder: 'zBag', title: 'zBag', latest: '5.07-ck19', state: 'update', bytes: 4096},
    {package: 'CherrysGrid', folder: 'CherrysGrid', title: "Cherry's Grid", latest: '1.1.6', state: 'missing', bytes: 2048}]},
};
const send = async message => { sent.push(message); return answers[message.type] || {ok: true}; };
const timers = [];
const context = {document, console, window: {confirm: () => confirmAnswer}, setTimeout: (fn) => { timers.push(fn); return timers.length; }, clearTimeout() {}, Date};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'addons.js'), 'utf8') + ';this.GBAddons = GBAddons;', context);
const flush = async () => { for (let i = 0; i < 20; i++) await new Promise(resolve => setImmediate(resolve)); };
const text = item => typeof item === 'string' ? item : (item.textContent || '') + (item.children || []).map(text).join(' ');
const buttons = item => typeof item === 'string' ? [] : [...(item.tag === 'button' ? [item] : []), ...(item.children || []).flatMap(buttons)];
(async () => {
  const page = context.GBAddons.create(send);
  page.show();
  await flush();
  assert.equal(sent[0].type, 'addons-list');
  assert.match(text(ids['addons-kit-rows']), /zBag/);
  assert.match(text(ids['addons-other-rows']), /DIYCE/);
  await ids['addons-check'].listeners.click({isTrusted: true});
  await flush();
  const rows = ids['addons-kit-rows'].children;
  assert.match(text(rows[1]), /Update available/);
  assert.match(text(rows[2]), /Not installed/);
  const install = buttons(rows[2]).find(b => b.textContent === 'Download and install');
  install.listeners.click({isTrusted: true});
  await flush();
  assert.equal(JSON.stringify(sent.at(-1)), JSON.stringify({type: 'addons-install', packages: ['CherrysGrid']}));
  const update = buttons(rows[1]).find(b => b.textContent === 'Update from GitHub');
  update.listeners.click({isTrusted: true});
  await flush();
  assert.equal(JSON.stringify(sent.at(-1)), JSON.stringify({type: 'addons-install', packages: ['zBag']}));
  confirmAnswer = false;
  const count = sent.length;
  buttons(ids['addons-kit-rows'].children[1]).find(b => b.textContent === 'Delete').listeners.click({isTrusted: true});
  await flush();
  assert.equal(sent.length, count, 'a declined delete sends nothing');
  confirmAnswer = true;
  buttons(ids['addons-other-rows'].children[0]).find(b => b.textContent === 'Offload').listeners.click({isTrusted: true});
  await flush();
  assert.equal(JSON.stringify(sent.find(m => m.type === 'addons-offload')), JSON.stringify({type: 'addons-offload', where: 'addons', name: 'Diyce'}));
  // Switch: a separate pbInfo with Cherry's Info installed only moves; with it missing, it installs first.
  answers['addons-list'] = {...answers['addons-list'], others: [{folder: 'pbInfo', title: 'pbInfo', version: '0.60'}],
    replaced: {pbInfo: {owner: 'CherrysInfo', title: "Cherry's Info"}}, kit: [{folder: 'zBag', title: 'zBag', version: '5.07-ck18'}, {folder: 'CherrysInfo', title: "Cherry's Info", version: '1.0.3'}]};
  await ids['addons-refresh'].listeners.click({isTrusted: true});
  await flush();
  assert.match(text(ids['addons-other-rows']), /Replaced by Cherry's Info/);
  buttons(ids['addons-other-rows'].children[0]).find(b => b.textContent === "Switch with Cherry's Info").listeners.click({isTrusted: true});
  await flush();
  assert.equal(JSON.stringify(sent.filter(m => m.type !== 'addons-list').at(-1)), JSON.stringify({type: 'addons-offload', where: 'addons', name: 'pbInfo'}));
  answers['addons-list'].kit = [{folder: 'zBag', title: 'zBag', version: '5.07-ck18'}];
  answers['addons-check'].packages.push({package: 'CherrysInfo', folder: 'CherrysInfo', title: "Cherry's Info", latest: '1.0.3', state: 'missing', bytes: 1024});
  await ids['addons-refresh'].listeners.click({isTrusted: true});
  await flush();
  buttons(ids['addons-other-rows'].children[0]).find(b => b.textContent === "Switch with Cherry's Info").listeners.click({isTrusted: true});
  await flush();
  assert.equal(JSON.stringify(sent.at(-1)), JSON.stringify({type: 'addons-install', packages: ['CherrysInfo'], offload: [{where: 'addons', name: 'pbInfo'}]}));
  answers['addons-list'] = {ok: false};
  const failing = context.GBAddons.create(async () => { throw new Error('Invalid reward record'); });
  failing.show();
  await flush();
  assert.match(ids['addons-status'].textContent, /older than this page/);
})().catch(error => { console.error(error); process.exitCode = 1; });
""")


@unittest.skipUnless(SHELL, 'PowerShell required')
class AddonsBridgeTests(unittest.TestCase):
    """Offload, restore and refusals against a throwaway Interface folder."""

    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root, True)
        self.addons = self.root / 'Interface' / 'AddOns'
        kit = self.addons / 'CherrysKit'
        (kit / 'zBag').mkdir(parents=True)
        (kit / 'zBag' / 'README.md').write_text('# zBag\n\nVersion **5.07-ck19**\n', encoding='utf-8')
        (kit / 'CherrysKit.toc').write_text('## Version: 0.11.115\n', encoding='utf-8')
        (kit / 'README.md').write_text('Version **0.4.30**\n', encoding='utf-8')
        (self.addons / 'Diyce').mkdir()
        (self.addons / 'Diyce' / 'Diyce.toc').write_text('## Title: DIYCE\n## Version: 2.0\n', encoding='utf-8')

    def run_ps(self, body):
        script = (f". '{str(ADDONS)}' -SetupScript '{str(SETUP)}'\n"
                  f"$paths = Get-AddonsPaths '{str(self.addons)}'\n" + body)
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-Command', script], capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    def test_offload_and_restore_round_trip(self):
        out = self.run_ps("""
[void](Invoke-AddonsOffload $paths 'kit' 'zBag')
[void](Invoke-AddonsOffload $paths 'addons' 'Diyce')
$list = Get-AddonsList $paths
ConvertTo-Json -Compress -Depth 5 -InputObject @{ kit = @($list.kit | ForEach-Object { $_.folder }); others = @($list.others | ForEach-Object { $_.folder }); off = @($list.offloaded | ForEach-Object { $_.id + '|' + $_.from + '|' + $_.version }) }
""")
        state = json.loads(out.splitlines()[-1])
        self.assertEqual(state['kit'], [])
        self.assertEqual(state['others'], [])
        self.assertIn('CherrysKit addons/zBag|kit|5.07-ck19', state['off'])
        self.assertIn('Diyce|addons|2.0', state['off'])
        self.run_ps("[void](Invoke-AddonsRestore $paths 'CherrysKit addons/zBag'); [void](Invoke-AddonsRestore $paths 'Diyce')")
        self.assertTrue((self.addons / 'CherrysKit' / 'zBag' / 'README.md').exists())
        self.assertFalse((self.addons / 'CherrysKit' / 'zBag' / 'offloaded-by-global-bank.json').exists())
        self.assertTrue((self.addons / 'Diyce' / 'Diyce.toc').exists())

    def test_refuses_paths_outside_its_folders_and_its_own_folders(self):
        (self.addons / 'CherrysKit' / 'GlobalBank').mkdir()
        out = self.run_ps("""
foreach ($case in @(@('kit', '..'), @('kit', 'GlobalBank'), @('kit', 'Setup'), @('addons', 'CherrysKit'), @('addons', '..\\AddOns'), @('offloaded', '../x'), @('offloaded', 'CherrysKit addons'), @('elsewhere', 'zBag'))) {
    try { [void](Resolve-AddonsTarget $paths $case[0] $case[1]); Write-Output ('ALLOWED ' + ($case -join ' ')) } catch { Write-Output 'refused' }
}
""")
        self.assertNotIn('ALLOWED', out)
        self.assertEqual(out.count('refused'), 8)


if __name__ == '__main__':
    unittest.main()
