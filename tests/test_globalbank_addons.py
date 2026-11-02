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
        # Installs run from a copy in GlobalBankHelper, never from the Global Bank folder an update replaces,
        # in an elevated window; a declined permission prompt leaves a failed result and a clear error.
        start = re.search(r'function Start-AddonsInstall.*?\n\}', source, re.S).group(0)
        self.assertIn("Join-Path $paths.data ('addons-run-'", start)
        self.assertIn('-Verb RunAs', start)
        self.assertIn('-WorkingDirectory $paths.interface', start)
        declined = start[start.index('} catch {'):]
        self.assertIn("state = 'failed'", declined)
        self.assertIn('administrator permission and it was not given', declined)
        self.assertIn('throw $text', declined)
        window = re.search(r'function Invoke-AddonsInstallWindow.*?\n\}', source, re.S).group(0)
        self.assertIn('Set-Location -LiteralPath $paths.interface', window)
        # An elevated window leaves the helper restart to the page, which runs as the player.
        self.assertIn('$status.restartHelper = @($helperModes)', window)
        read = re.search(r'function Read-AddonsStatus.*?\n\}', source, re.S).group(0)
        self.assertIn('Start-AddonsHelper $paths $modes -Quiet', read)

    def test_page_file_changes_run_as_administrator(self):
        source = ADDONS.read_text(encoding='utf-8')
        self.assertIn("$script:AddonsElevatedTypes = @('addons-offload', 'addons-restore', 'addons-delete', 'addons-mailbox')", source)
        message = re.search(r'function Invoke-AddonsMessage.*?\n\}', source, re.S).group(0)
        # The bridge Chrome starts runs as the player: these go to an administrator window; that window does them -Here.
        self.assertLess(message.index('Invoke-AddonsElevated $paths $message'), message.index('switch ('))
        elevated = re.search(r'function Invoke-AddonsElevated.*?\n\}', source, re.S).group(0)
        self.assertIn("Join-Path $paths.data ('addons-run-'", elevated)
        self.assertIn('-Verb RunAs', elevated)
        self.assertIn('-Wait -PassThru', elevated)
        self.assertIn('it was not given, so nothing changed', elevated)
        self.assertIn('Remove-Item -LiteralPath $work -Recurse', elevated)
        action = re.search(r'function Invoke-AddonsAction.*?\n\}', source, re.S).group(0)
        self.assertIn('$script:AddonsElevatedTypes -notcontains', action)
        self.assertIn('Invoke-AddonsMessage $message $addons -Here', action)
        login = re.search(r'function Start-AddonsLoginScreen.*?\n\}', source, re.S).group(0)
        self.assertIn('-Verb RunAs', login)
        self.assertIn("-Documents '{1}'", login)
        # Never elevated: the native host Chrome starts, and the helper it talks to.
        host = (HELPER / 'GlobalBank-NativeHost.ps1').read_text(encoding='utf-8')
        self.assertNotIn('RunAs', host)
        self.assertNotIn('RunAs', (HELPER / 'Install Chrome extension.ps1').read_text(encoding='utf-8'))

    def test_setup_and_login_screen_ask_for_administrator_rights(self):
        setup = SETUP.read_text(encoding='utf-8')
        self.assertIn('$askAdmin = $onWindows -and -not $NonInteractive -and -not $Elevated -and -not $UpdatedFrom -and -not $OtherInstall -and -not (Test-Admin)', setup)
        self.assertIn('if ($needRights -or $askAdmin) {', setup)
        self.assertIn('-Elevated -UserDocuments "{3}"', setup)
        self.assertIn('& $loginInstaller -Documents $UserDocuments', setup)
        root = ROOT / 'Interface/AddOns/LogNextChar'
        install = (root / 'setup' / 'Install.ps1').read_text(encoding='utf-8')
        self.assertIn('[switch]$Elevate', install)
        self.assertIn("-Verb RunAs -Wait", install)
        self.assertIn('exit 3', install)
        bat = (root / 'Install login screen.bat').read_text(encoding='utf-8')
        self.assertIn('Install.ps1" -Elevate %*', bat)
        self.assertIn('if errorlevel 3 exit /b 0', bat)

    def test_action_cells_stay_table_cells_and_update_all_sits_on_the_table(self):
        css = (EXTENSION / 'control.css').read_text(encoding='utf-8')
        rule = re.search(r'td\.addons-actions, th\.addons-actions \{([^}]*)\}', css).group(1)
        # display: flex on a <td> takes it out of the row, so its border no longer lines up with the rest.
        self.assertNotIn('display', rule)
        self.assertNotRegex(css, r'(^|\n)\.addons-actions \{[^}]*display')
        html = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        self.assertIn('<th class="addons-actions"><button id="addons-update-all-table" type="button" class="gb-button--primary gb-button--sm" hidden>', html)
        page = (EXTENSION / 'addons.js').read_text(encoding='utf-8')
        self.assertIn("for (const id of ['addons-update-all', 'addons-update-all-table'])", page)

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
        self.assertIn("if (($offload -or $mailbox) -and $skipped -gt 0) {", window)

    def test_mailbox_file_keeps_its_comments_and_crlf(self):
        source = ADDONS.read_text(encoding='utf-8')
        write = re.search(r'function Write-AddonsMailbox.*?\n\}', source, re.S).group(0)
        self.assertIn("-match '^Mailbox\\s*='", write)
        self.assertIn('-join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)', write)
        # Leaving zMail moves its folder out, since it has no switch of its own.
        switch = re.search(r'function Set-AddonsMailbox.*?\n\}', source, re.S).group(0)
        self.assertIn("Invoke-AddonsOffload $paths 'addons' 'zmail'", switch)
        self.assertLess(switch.index('Write-AddonsMailbox'), switch.index('Invoke-AddonsOffload'))

    def test_own_arguments_survive_loading_the_setup(self):
        # Dot-sourcing the setup binds its parameters here; the window's arguments are copied aside first.
        source = ADDONS.read_text(encoding='utf-8')
        kept = source.index("$script:AddonsArgs = @{ Install = $Install; AddonsFolder = $AddonsFolder; Offload = $Offload; Mailbox = $Mailbox; Action = $Action }")
        self.assertLess(kept, source.index('. $script:AddonsSetupPath -LoadOnly'))
        tail = source[source.index('. $script:AddonsSetupPath -LoadOnly'):]
        for name in ('$Install', '$AddonsFolder', '$Offload', '$Mailbox', '$Action'):
            self.assertNotRegex(tail, re.escape(name) + r'(?![A-Za-z])', name)
        setup = re.search(r'param\((.*?)\n\)', SETUP.read_text(encoding='utf-8'), re.S).group(1)
        own = set(re.findall(r'\$([A-Za-z]+)', re.search(r'^param\((.*?)\)$', source, re.M).group(1)))
        clash = own & set(re.findall(r'\]\$([A-Za-z]+)', setup))
        self.assertEqual(clash, set(), 'setup parameters that would overwrite this file\'s own')

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
// Replaced and not installed: not a row, but named once below the table
same(replacedRows.find(row => row.key === 'pbInfo'), undefined);
same(updatable(replacedRows).length, 0);
const retiredCheck = {packages: [{package: 'pbInfo', folder: 'pbInfo', title: 'pbInfo', state: 'superseded', by: "Cherry's Info"},
  {package: 'TooltipIds', folder: 'TooltipIds', title: 'TooltipIds', state: 'superseded', by: "Cherry's Info"},
  {package: 'CherrysLoginxml', folder: 'CherrysLoginxmlHook', title: "Cherry's Loginxml", state: 'superseded', by: 'LogNextChar'},
  {package: 'zBag', folder: 'zBag', title: 'zBag', state: 'current'}]};
same(context.GBAddons.retired(retiredCheck), "pbInfo, TooltipIds (now Cherry's Info); Cherry's Loginxml (now LogNextChar)");
same(kitRows({hasKit: true, kit: [], offloaded: []}, retiredCheck).map(row => row.key), ['Hub', 'zBag']);
// A leftover folder of a replaced addon is still a row, with Switch
const leftover = kitRows({hasKit: true, kit: [{folder: 'pbInfo', title: 'pbInfo', version: '0.60'}], offloaded: [], replaced: {pbInfo: {owner: 'CherrysInfo', title: "Cherry's Info"}}}, null);
same(leftover.find(row => row.key === 'pbInfo').state, 'superseded');
const login = context.GBAddons.loginState;
same(login(null), null);
assert.match(login({state: 'missing', installer: true}).text, /running the game doesn’t put it there/);
same(login({state: 'missing', installer: true}).action, 'Install login screen');
assert.match(login({state: 'missing', installer: false}).text, /install LogNextChar first/);
same(login({state: 'missing', installer: false}).action, '');
same(login({state: 'update', installer: true, version: '1.3.2', lncVersion: '1.3.3'}).action, 'Update login screen');
same(login({state: 'current', installer: true, version: '1.3.3'}).action, '');
same(login({state: 'other', installer: true}).action, 'Replace with LogNextChar’s login screen');
same(kitRows({hasKit: false, kit: [], offloaded: []}, null), []);
''')

    def test_mail_switch(self):
        self.run_js(r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const same = (actual, expected) => assert.equal(JSON.stringify(actual), JSON.stringify(expected));
function node(tag) {
  return {tag, children: [], hidden: false, disabled: false, textContent: '', className: '', listeners: {},
    append(...kids) { this.children.push(...kids); }, replaceChildren(...kids) { this.children = kids; },
    addEventListener(type, callback) { this.listeners[type] = callback; }};
}
const ids = {};
const document = {createElement: node, getElementById: id => (ids[id] ||= node('div'))};
const sent = [];
const base = {ok: true, hasKit: true, kitVersion: '0.11.116', hubVersion: '0.4.31', kit: [{folder: 'UltimateMailMod', title: 'Ultimate Mail Mod', version: '7.0.1-ck12'}],
  others: [{folder: 'zmail', title: 'zMail', version: ''}], offloaded: [], job: null};
const answers = {'addons-list': {...base, mailbox: {known: true, setting: 'auto', umm: true, zmail: false, running: 'UMM'}},
  'addons-check': {ok: true, latestKit: '0.11.116', packages: [{package: 'zMail', folder: 'zmail', title: 'zMail', latest: '1.4-ck1', state: 'missing', bytes: 3072, external: true, alternativeTo: 'UltimateMailMod'}]}};
const send = async message => { sent.push(message); return answers[message.type] || {ok: true}; };
const context = {document, console, window: {confirm: () => true}, setTimeout: () => 0, clearTimeout() {}, Date};
vm.runInNewContext(fs.readFileSync(path.join(process.argv[1], 'addons.js'), 'utf8') + ';this.GBAddons = GBAddons;', context);
const {mailState, kitRows} = context.GBAddons;
same(mailState(null), null);
same(mailState({known: false, zmail: false}), null);
same(mailState({known: true, setting: 'auto', zmail: true, umm: true, running: 'zMail'}).offers, ['UMM']);
// zMail is on the Mail panel, not in the kit's table
same(kitRows(answers['addons-list'], answers['addons-check']).map(row => row.key), ['Hub', 'UltimateMailMod']);
const flush = async () => { for (let i = 0; i < 20; i++) await new Promise(resolve => setImmediate(resolve)); };
const buttons = item => typeof item === 'string' ? [] : [...(item.tag === 'button' ? [item] : []), ...(item.children || []).flatMap(buttons)];
(async () => {
  const page = context.GBAddons.create(send);
  page.show();
  await flush();
  assert.equal(ids['addons-mailbox'].hidden, false);
  assert.match(ids['addons-mail-text'].textContent, /Ultimate Mail Mod, chosen automatically/);
  // With the Mail panel showing zmail, the other addons list leaves it out
  assert.equal(ids['addons-other-rows'].children.length, 1);
  assert.doesNotMatch(JSON.stringify(ids['addons-other-rows'].children[0].children.map(c => c.textContent)), /zMail/);
  // zMail isn't here: the switch installs it and picks it
  buttons(ids['addons-mail-actions']).find(b => b.textContent === 'Switch to zMail').listeners.click({isTrusted: true});
  await flush();
  same(sent.filter(m => !['addons-list', 'addons-check'].includes(m.type)).at(-1), {type: 'addons-install', packages: ['zMail'], mailbox: 'zMail'});
  // zMail running: back to Ultimate Mail Mod is a setting change, and the bridge moves zmail out
  answers['addons-list'] = {...base, mailbox: {known: true, setting: 'zMail', umm: true, zmail: true, zmailVersion: '1.4-ck1', running: 'zMail'}};
  await ids['addons-refresh'].listeners.click({isTrusted: true});
  await flush();
  assert.match(ids['addons-mail-text'].textContent, /zMail 1\.4-ck1 is in/);
  buttons(ids['addons-mail-actions']).find(b => b.textContent === 'Switch to Ultimate Mail Mod').listeners.click({isTrusted: true});
  await flush();
  same(sent.filter(m => m.type === 'addons-mailbox').at(-1), {type: 'addons-mailbox', use: 'UMM'});
  // Without Ultimate Mail Mod, it installs first and offloads zmail after
  answers['addons-list'] = {...base, kit: [], mailbox: {known: true, setting: 'zMail', umm: false, zmail: true, running: 'zMail'}};
  answers['addons-check'].packages.push({package: 'UltimateMailMod', folder: 'UltimateMailMod', title: 'Ultimate Mail Mod', latest: '7.0.1-ck12', state: 'missing', bytes: 1024});
  await ids['addons-refresh'].listeners.click({isTrusted: true});
  await flush();
  buttons(ids['addons-mail-actions']).find(b => b.textContent === 'Switch to Ultimate Mail Mod').listeners.click({isTrusted: true});
  await flush();
  same(sent.at(-1), {type: 'addons-install', packages: ['UltimateMailMod'], mailbox: 'UMM', offload: [{where: 'addons', name: 'zmail'}]});
})().catch(error => { console.error(error); process.exitCode = 1; });
""")

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
ask({type: 'addons-loginscreen', name: 'x'});
same(sent.pop(), {type: 'addons-loginscreen'});
ask({type: 'addons-mailbox', use: 'zMail', extra: 1});
same(sent.pop(), {type: 'addons-mailbox', use: 'zMail'});
assert.notEqual(ask({type: 'addons-mailbox', use: 'auto'}).kept, true);
ask({type: 'addons-install', packages: ['zMail'], mailbox: 'zMail'});
same(sent.pop(), {type: 'addons-install', packages: ['zMail'], mailbox: 'zMail'});
assert.notEqual(ask({type: 'addons-install', packages: ['zMail'], mailbox: 'x'}).kept, true);
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

    def test_mailbox_switch_round_trip(self):
        kit = self.addons / 'CherrysKit'
        (kit / 'UltimateMailMod').mkdir()
        (kit / 'Mailbox.txt').write_bytes(b'-- Which mailbox addon\r\n--\r\n\r\nMailbox = "auto"\r\n')
        (self.addons / 'zmail').mkdir()
        (self.addons / 'zmail' / 'CherrysKit-version.txt').write_bytes(b'1.4-ck1\r\n')
        out = self.run_ps("(Get-AddonsMailbox $paths).running; [void](Set-AddonsMailbox $paths 'UMM'); (Get-AddonsMailbox $paths).running")
        self.assertEqual(out.splitlines()[-2:], ['zMail', 'UMM'])
        self.assertEqual((kit / 'Mailbox.txt').read_bytes(), b'-- Which mailbox addon\r\n--\r\n\r\nMailbox = "UMM"\r\n')
        self.assertFalse((self.addons / 'zmail').exists())

    def test_hub_comparison_uses_hub_version_instead_of_the_kit_zip_version(self):
        output = self.run_ps("""
$rows = @()
foreach ($case in @(@{ kit = '0.11.115'; hub = '0.4.30' }, @{ kit = '0.11.116'; hub = '0.4.31' }, @{ kit = '0.11.114'; hub = '0.4.29' })) {
    $release = @{ kit_version = $case.kit; hub_version = $case.hub; packages = @(@{ package = 'Hub'; version = $case.kit; title = 'Hub'; bytes = 1 }) }
    $check = Get-AddonsCheck $paths $release
    $row = $check.packages[0]
    $rows += @{ installed = $row.installed; latest = $row.latest; state = $row.state }
}
ConvertTo-Json -InputObject $rows -Compress
""")
        self.assertEqual(json.loads(output), [
            {'installed': '0.4.30', 'latest': '0.4.30', 'state': 'current'},
            {'installed': '0.4.30', 'latest': '0.4.31', 'state': 'update'},
            {'installed': '0.4.30', 'latest': '0.4.29', 'state': 'newer'},
        ])

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
