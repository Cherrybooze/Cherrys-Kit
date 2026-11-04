"""Character transfers on the Global Bank page: the site's transfer page, the Thursday maintenance and the saves."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper/ChromeExtension'
NODE = shutil.which('node')

# transfers.js in its own context, as GBT, with saves written in this PC's time like the helper writes them
PRELUDE = r"""
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const folder = process.argv[1];
const context = vm.createContext({console, Intl, Date, crypto: globalThis.crypto, setTimeout, clearTimeout});
vm.runInContext(fs.readFileSync(path.join(folder, 'transfers.js'), 'utf8') + ';this.GBT = GBTransfers;', context);
const GBT = context.GBT;
const plain = value => JSON.parse(JSON.stringify(value));
const pad = n => String(n).padStart(2, '0');
const saved = ms => { const d = new Date(ms); return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`; };
const H = 3600e3, D = 24 * H;
"""


@unittest.skipUnless(NODE, 'Node required')
class TransferTests(unittest.TestCase):
    def run_js(self, source, zone='Europe/Helsinki'):
        env = dict(os.environ, TZ=zone)
        result = subprocess.run([NODE, '-e', PRELUDE + source, str(EXTENSION)], capture_output=True, text=True, env=env, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_the_maintenance_is_thursday_morning_in_germany_from_any_time_zone(self):
        for zone in ('Europe/Helsinki', 'America/New_York', 'Asia/Tokyo', 'UTC'):
            self.run_js(r"""
const next = text => new Date(GBT.nextMaintenance(Date.parse(text))).toISOString();
// 09:00 German time: 08:00 UTC in winter, 07:00 UTC in summer
assert.equal(next('2026-11-04T06:12:00Z'), '2026-11-05T08:00:00.000Z');
assert.equal(next('2026-11-05T07:59:59Z'), '2026-11-05T08:00:00.000Z');
assert.equal(next('2026-11-05T08:00:00Z'), '2026-11-12T08:00:00.000Z');
assert.equal(next('2026-07-01T00:00:00Z'), '2026-07-02T07:00:00.000Z');
// The weeks the clocks change: the last Sunday of October and of March
assert.equal(next('2026-10-24T00:00:00Z'), '2026-10-29T08:00:00.000Z');
assert.equal(next('2026-03-27T00:00:00Z'), '2026-04-02T07:00:00.000Z');
// Another day and time, as set on the page; nonsense falls back to Thursday 09:00
const plan = {day: 3, hour: 10, minute: 30};
assert.equal(new Date(GBT.nextMaintenance(Date.parse('2026-11-04T09:00:00Z'), plan)).toISOString(), '2026-11-04T09:30:00.000Z');
assert.deepEqual(plain(GBT.maintenanceOf({day: 9, hour: '10', minute: -1})), {day: 4, hour: 9, minute: 0});
// A transfer is due in the first maintenance after the site last listed it
const record = {at: '2026-11-04T06:12:00Z', seen: '2026-11-06T10:00:00Z'};
assert.equal(new Date(GBT.dueOf(record)).toISOString(), '2026-11-12T08:00:00.000Z');
assert.equal(GBT.countdown(D + 23 * H + 47 * 60e3 + 12e3), '1d 23h 47m 12s');
assert.equal(GBT.countdown(5e3), '5s');
assert.equal(GBT.countdown(H), '1h 0m 0s');
assert.equal(GBT.roughly(D + H + 60e3), '1d 1h');
assert.equal(GBT.roughly(59e3), '1m');
""", zone)

    def test_the_transfer_page_gives_its_planned_transfers_and_offered_characters(self):
        self.run_js(r"""
// As the site shows it: the form's lists, then the planned transfer with its arrow
const page = {selects: [['Zuuzuuhehtne (Gaia (PvE))', 'Zuuzuuhrutu (Kadmos (PvE))'], ['Gaia (PvE)', 'Kadmos (PvE)', 'Aynara (PvE)', 'Kerub (PvP)', 'Svidur (PvE)']],
  texts: ['MY ACCOUNT', 'someone@example.com', 'TRANSFER YOUR CHARACTER NOW!', 'You must have a Server Transfer Stone in your inventory.', 'Select your character:',
    'Server selection:', 'Register Character Transfer', 'PLANNED CHARACTER TRANSFERS', 'The character transfer can be canceled before the server maintenance.',
    'Zuuzuuhehtne (Gaia (PvE))', '»', 'Kadmos (PvE)', 'Cancel Character Transfer', 'Yes', 'No']};
const read = plain(GBT.parsePage(page));
assert.deepEqual(read.planned, [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}]);
assert.deepEqual(read.offered, [{name: 'Zuuzuuhehtne', server: 'Gaia'}, {name: 'Zuuzuuhrutu', server: 'Kadmos'}]);
assert.equal(read.form, true);
assert.doesNotMatch(JSON.stringify(read), /someone|example|ACCOUNT/);
// Split over several pieces of text, other arrows, and servers the game doesn't list
const split = plain(GBT.parsePage({selects: [], texts: ['Zuuzuuhehtne', '(', 'Gaia (PvE)', ')', '', 'Kadmos', '(PvE)', 'Cancel', 'Anna (Kerub)', '→', 'Ayvenas', 'Bo (Zhyro (PvP))', 'Smaragd (PvE)']}));
assert.deepEqual(split.planned, [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}, {name: 'Anna', from: 'Kerub', to: 'Ayvenas'}, {name: 'Bo', from: 'Zhyro', to: 'Smaragd'}]);
assert.equal(split.form, false);
// A sentence naming a character and a server is no transfer, nor is a character "moving" to its own server
assert.deepEqual(plain(GBT.parsePage({selects: [], texts: ['Do you really want to transfer', 'Zuuzuuhehtne (Gaia (PvE))', 'to', 'Kadmos (PvE)', '?']})).planned, []);
assert.deepEqual(plain(GBT.parsePage({selects: [], texts: ['Zuuzuuhehtne (Gaia (PvE))', '»', 'Gaia (PvE)']})).planned, []);
// A server of more than a word counts once the page's own server list has it
const multi = plain(GBT.parsePage({selects: [['Anna (Muinin Classic (PvE))', 'Bert (Gaia (PvE))'], ['Gaia (PvE)', 'Muinin Classic (PvE)', 'Kadmos (PvE)']], texts: ['Anna (Muinin Classic (PvE))', '»', 'Kadmos (PvE)']}));
assert.deepEqual(multi.planned, [{name: 'Anna', from: 'Muinin Classic', to: 'Kadmos'}]);
// The background checks what the page sent again
assert.equal(GBT.cleanRead({planned: 'x', offered: []}), null);
assert.equal(GBT.cleanRead({planned: new Array(41).fill({name: 'Anna', from: 'Gaia', to: 'Kadmos'}), offered: []}), null);
const clean = plain(GBT.cleanRead({planned: [{name: 'Anna', from: 'Gaia (PvE)', to: 'Kadmos'}, {name: '<b>x</b>', from: 'Gaia', to: 'Kadmos'}, {name: 'Bert', from: 'Gaia', to: 'Gaia'}],
  offered: [{name: 'Anna', server: 'Gaia'}, {name: 'a b', server: 'Gaia'}], form: 'yes'}));
assert.deepEqual(clean, {planned: [{name: 'Anna', from: 'Gaia', to: 'Kadmos'}], offered: [{name: 'Anna', server: 'Gaia'}], form: false});
""")

    def test_registered_cancelled_and_listed_again_on_the_site(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T08:00:00Z');
const offered = [{name: 'Zuuzuuhehtne', server: 'Gaia'}, {name: 'Mate', server: 'Gaia'}];
// The page before registering, then after: the same tab saw it registered
let result = GBT.applyRead(null, {planned: [], offered, form: true}, {now: t0});
assert.equal(result.changed, false);
result = GBT.applyRead(result.state, {planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}], offered, form: true}, {now: t0 + 60e3, previous: {at: t0, planned: []}});
assert.equal(result.added.length, 1);
let record = result.state.list[0];
assert.deepEqual([record.state, record.here, record.from, record.to, record.at], ['planned', true, 'Gaia', 'Kadmos', new Date(t0 + 60e3).toISOString()]);
assert.deepEqual(plain(record.events.map(item => item.text)), ['Registered on the transfer page']);
assert.deepEqual(plain(record.account), ['gaia|zuuzuuhehtne', 'gaia|mate']);
const planned = result.state;
// Read again: nothing new, only when it was last listed
result = GBT.applyRead(planned, {planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}], offered, form: true}, {now: t0 + 120e3});
assert.deepEqual([result.added.length, result.ended.length, result.state.list[0].events.length], [0, 0, 1]);
// Another account's page says nothing about it
result = GBT.applyRead(planned, {planned: [], offered: [{name: 'Other', server: 'Kerub'}], form: true}, {now: t0 + 180e3});
assert.equal(result.state.list[0].state, 'planned');
// Cancelled in the tab that listed it, before the maintenance
result = GBT.applyRead(planned, {planned: [], offered, form: true}, {now: t0 + 180e3, previous: {at: t0 + 60e3, planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}]}});
assert.deepEqual(plain(result.ended.map(item => item.state)), ['cancelled']);
assert.equal(result.state.list[0].events.at(-1).text, 'Cancelled on the transfer page');
// The form offers it again: listed as planned from now on, it was registered once more
assert.equal(result.state.list[0].offered, new Date(t0 + 180e3).toISOString());
// Registered again in the same tab, without reloading: a new transfer with its own time, and the cancelled one stays
// in the log
const kadmos = [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}];
const again = GBT.applyRead(result.state, {planned: kadmos, offered: [], form: false}, {now: t0 + 240e3, previous: {at: t0 + 180e3, planned: []}});
assert.equal(again.added.length, 1);
assert.deepEqual(plain(again.state.list.map(item => [item.state, item.at])),
  [['planned', new Date(t0 + 240e3).toISOString()], ['cancelled', new Date(t0 + 60e3).toISOString()]]);
assert.deepEqual(plain(again.state.list[0].events.map(item => item.text)), ['Registered again on the transfer page']);
// ... and found planned again later in another tab, or after Chrome restarted: also a new one
const later = GBT.applyRead(result.state, {planned: kadmos, offered: [], form: false}, {now: t0 + D});
assert.deepEqual([later.added.length, later.state.list[0].events[0].text], [1, 'Found planned again on the transfer page']);
// A page that briefly showed no transfer and no form either, then the transfer again: the same one, never cancelled
const blip = GBT.applyRead(planned, {planned: [], offered: [], form: false}, {now: t0 + 180e3, previous: {at: t0 + 60e3, planned: kadmos}});
assert.deepEqual(plain(blip.ended.map(item => item.state)), ['cancelled']);
const back = GBT.applyRead(blip.state, {planned: kadmos, offered: [], form: false}, {now: t0 + 181e3, previous: {at: t0 + 180e3, planned: []}});
assert.deepEqual([back.added.length, back.state.list.length, back.state.list[0].state, back.state.list[0].ended], [0, 1, 'planned', undefined]);
assert.equal(back.state.list[0].events.at(-1).text, 'Listed as planned on the transfer page again');
assert.equal(back.state.list[0].at, new Date(t0 + 60e3).toISOString());
// Registered again for another server: the first one was cancelled
const other = GBT.applyRead(planned, {planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Aynara'}], offered, form: true}, {now: t0 + H});
assert.deepEqual(plain(other.state.list.map(item => [item.to, item.state])), [['Aynara', 'planned'], ['Kadmos', 'cancelled']]);
// After its maintenance, the page lists it on its new server: it moved
const moved = GBT.applyRead(planned, {planned: [], offered: [{name: 'Zuuzuuhehtne', server: 'Kadmos'}, {name: 'Mate', server: 'Gaia'}], form: true}, {now: Date.parse('2026-11-05T12:00:00Z')});
assert.equal(moved.state.list[0].state, 'moved');
// ... or offers it on its old one: it didn't
const stayed = GBT.applyRead(planned, {planned: [], offered, form: true}, {now: Date.parse('2026-11-05T12:00:00Z')});
assert.equal(stayed.state.list[0].state, 'stayed');
// Still listed after it: a note, and due a week later
const waiting = GBT.applyRead(planned, {planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}], offered, form: true}, {now: Date.parse('2026-11-05T12:00:00Z')});
assert.equal(waiting.state.list[0].events.at(-1).text, 'Still planned on the transfer page after the maintenance it was due in');
assert.equal(new Date(GBT.dueOf(waiting.state.list[0])).toISOString(), '2026-11-12T08:00:00.000Z');
// What the store keeps is checked again when it's read
assert.deepEqual(plain(GBT.load({list: [{id: 'bad'}, null, {...record, state: 'lost'}]})), {v: 1, list: []});
""")

    def test_saves_show_a_character_moved_confirmed_or_still_there(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T08:00:00Z'), after = Date.parse('2026-11-05T12:00:00Z');
let state = GBT.applyRead(null, {planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}], offered: [{name: 'Mate', server: 'Gaia'}], form: true}, {now: t0}).state;
const id = state.list[0].id;
const characters = () => [
  {name: 'Zuuzuuhehtne', server: 'Gaia', roster: ['Zuuzuuhehtne', 'Mate'], saved: saved(t0 - H)},
  {name: 'Mate', server: 'Gaia', roster: ['Zuuzuuhehtne', 'Mate'], saved: saved(t0 - 2 * H)},
];
// Nothing saved since: nothing to say
assert.deepEqual(plain(GBT.evidence(state.list, characters(), {now: after})), []);
// A login on the old server before the maintenance still lists it: nothing to say either
let list = characters();
list[1].saved = saved(t0 + H);
assert.deepEqual(plain(GBT.evidence(state.list, list, {now: after})), []);
// After the maintenance its login screen no longer lists it: moved
list[1].saved = saved(after); list[1].roster = ['Mate'];
let changes = plain(GBT.evidence(state.list, list, {now: after + 60e3}));
assert.deepEqual(changes.map(change => [change.id, change.state]), [[id, 'moved']]);
assert.match(changes[0].text, /Gaia's login screen no longer lists it: Mate logged in there/);
state = GBT.applyChanges(state, GBT.cleanChanges(changes), after + 60e3).state;
assert.equal(state.list[0].state, 'moved');
// It logs in on its new server: confirmed
list.push({name: 'Zuuzuuhehtne', server: 'Kadmos', roster: ['Zuuzuuhehtne'], saved: saved(after + 2 * H)});
changes = plain(GBT.evidence(state.list, list, {now: after + 3 * H}));
assert.deepEqual(changes.map(change => change.state), ['done']);
state = GBT.applyChanges(state, GBT.cleanChanges(changes), after + 3 * H).state;
assert.deepEqual([state.list[0].state, state.list[0].done], ['done', new Date(after + 2 * H).toISOString()]);
assert.deepEqual(plain(GBT.evidence(state.list, list, {now: after + 3 * H})), []);
// Another account character on its new server lists it: moved, before it logged in itself
let other = GBT.applyRead(null, {planned: [{name: 'Cleo', from: 'Kerub', to: 'Kadmos'}], offered: [], form: true}, {now: t0}).state;
assert.deepEqual(plain(GBT.evidence(other.list, [{name: 'Dora', server: 'Kadmos', roster: ['Dora', 'Cleo'], saved: saved(after)}], {now: after + 1})).map(change => change.state), ['moved']);
// Still listed by its old server's login screen well after the maintenance, or logged in there itself: it didn't move
const stay = [{name: 'Anna', server: 'Kerub', roster: ['Anna', 'Bert'], saved: saved(t0 - D)}, {name: 'Bert', server: 'Kerub', roster: ['Anna', 'Bert'], saved: saved(Date.parse('2026-11-05T09:30:00Z'))}];
other = GBT.applyRead(null, {planned: [{name: 'Anna', from: 'Kerub', to: 'Aynara'}], offered: [{name: 'Bert', server: 'Kerub'}], form: true}, {now: t0}).state;
assert.deepEqual(plain(GBT.evidence(other.list, stay, {now: after})), []);
stay[1].saved = saved(Date.parse('2026-11-05T14:00:00Z'));
assert.deepEqual(plain(GBT.evidence(other.list, stay, {now: after + 4 * H})).map(change => change.state), ['stayed']);
stay[1].saved = saved(t0 - D);
stay[0].saved = saved(Date.parse('2026-11-05T14:00:00Z'));
const own = plain(GBT.evidence(other.list, stay, {now: after + 4 * H}));
assert.deepEqual(own.map(change => change.state), ['stayed']);
assert.match(own[0].text, /Logged in on Kerub after the maintenance it was due in/);
// Only the page's own changes, and only these kinds
assert.equal(GBT.cleanChanges([{id: 'x', state: 'done'}]), null);
assert.equal(GBT.cleanChanges([{id: id, state: 'planned'}]), null);
assert.equal(GBT.cleanChanges([]), null);
// Forget takes one out
assert.equal(GBT.applyChanges(state, [{id, state: 'forget', at: after, text: ''}]).state.list.length, 0);
""")

    def test_moved_characters_show_on_their_new_server_until_they_log_in_there(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T08:00:00Z'), after = Date.parse('2026-11-05T12:00:00Z');
const base = () => [
  {name: 'Zuuzuuhehtne', server: 'Gaia', roster: ['Zuuzuuhehtne', 'Mate'], saved: saved(t0 - H), mail: {inbox: []}},
  {name: 'Mate', server: 'Gaia', roster: ['Mate'], saved: saved(after)},
  {name: 'Kim', server: 'Gaia', roster: ['Zuuzuuhehtne', 'Kim'], saved: saved(t0 - 3 * D)},
];
const record = {id: 'aaaaaaaa1111', name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos', state: 'planned', at: new Date(t0).toISOString(), seen: new Date(t0).toISOString(), account: [], events: []};
// Planned: it stays where it is, with its transfer
let list = base();
let shown = GBT.overlay(list, [record]);
assert.equal(shown.length, 3);
assert.deepEqual(plain(shown[0].transfer), {id: 'aaaaaaaa1111', state: 'planned', name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'});
// Moved: on its new server, with nothing of its old login screen or mailbox, and its old server's lists no longer name it
const moved = {...record, state: 'moved', ended: new Date(after).toISOString()};
shown = GBT.overlay(list, [moved]);
assert.deepEqual([shown[0].server, shown[0].roster.length, shown[0].mail, shown[0].transfer.carried, shown[0].formerKey], ['Kadmos', 0, undefined, true, 'gaia|zuuzuuhehtne']);
assert.deepEqual(plain(shown[2].roster), ['Kim']);
// Every run starts again from what was saved: back to planned puts it back
shown = GBT.overlay(list, [record]);
assert.deepEqual([shown[0].server, shown[0].roster.length, !!shown[0].mail], ['Gaia', 2, true]);
assert.deepEqual(plain(shown[2].roster), ['Zuuzuuhehtne', 'Kim']);
// Logged in on its new server: its old server's copy goes, and the new one says where it came from
list = base();
list.push({name: 'Zuuzuuhehtne', server: 'Kadmos', roster: ['Zuuzuuhehtne'], saved: saved(after + H)});
const done = {...moved, state: 'done', done: new Date(after + H).toISOString()};
shown = GBT.overlay(list, [done]);
assert.deepEqual(plain(shown.map(character => `${character.name}@${character.server}`)), ['Mate@Gaia', 'Kim@Gaia', 'Zuuzuuhehtne@Kadmos']);
assert.equal(shown[2].transfer.state, 'done');
assert.equal(GBT.plateOf(shown[2], [done], after + 2 * H), null);
assert.match(GBT.cardLine(shown[2], [done], after + 2 * H).text, /^Came from Gaia by transfer/);
// A new character that took the name on the old server since stays
list[0].saved = saved(after + 5 * H);
assert.equal(GBT.overlay(list, [done]).length, 4);
// Cancelled ones change nothing
list = base();
assert.equal(GBT.overlay(list, [{...record, state: 'cancelled'}])[0].transfer, undefined);
// A transferred character nothing saved yet: a row of its own from what the transfer page said, the rest left blank
const stranger = {...record, id: 'bbbbbbbb2222', name: 'Newbie'};
shown = GBT.overlay(base(), [stranger]);
assert.equal(shown.length, 4);
assert.deepEqual(plain([shown[3].name, shown[3].server, shown[3].notSaved, shown[3].fromTransfer, shown[3].stale, shown[3].transfer.state, shown[3].roster]),
  ['Newbie', 'Gaia', true, true, false, 'planned', []]);
assert.deepEqual(plain(['gold', 'level', 'class', 'bag', 'bank', 'saved'].map(key => shown[3][key] ?? null)), [null, null, null, null, null, null]);
// Moved: on its new server, waiting for its first login there
const strangerMoved = {...stranger, state: 'moved', ended: new Date(after).toISOString()};
shown = GBT.overlay(base(), [strangerMoved]);
assert.deepEqual([shown[3].server, shown[3].transfer.carried, shown[3].formerKey], ['Kadmos', true, 'gaia|newbie']);
assert.equal(GBT.plateOf(shown[3], [strangerMoved], after).confirm, true);
// One row for each name and server, from its newest transfer
shown = GBT.overlay(base(), [stranger, {...stranger, id: 'cccccccc3333', at: new Date(t0 - D).toISOString()}]);
assert.deepEqual(plain(shown.slice(3).map(character => character.transfer.id)), ['bbbbbbbb2222']);
// Once it saved on its new server, that save is its row
list = base();
list.push({name: 'Newbie', server: 'Kadmos', roster: ['Newbie'], saved: saved(after + H)});
shown = GBT.overlay(list, [{...strangerMoved, state: 'done', done: new Date(after + H).toISOString()}]);
assert.deepEqual(plain(shown.filter(character => character.name === 'Newbie').map(character => [character.server, !!character.notSaved])), [['Kadmos', false]]);
// Every run starts from the saves again: no blank row is left over in them
list = base();
GBT.overlay(list, [stranger]);
assert.equal(list.length, 3);
// A save from an older Global Bank names no server of its own: its daily reward's server places it
list = base();
list.push({name: 'Oldie', dailyLogin: {server: 'Gaia'}, saved: saved(t0 - D)});
shown = GBT.overlay(list, [{...record, id: 'dddddddd4444', name: 'Oldie'}]);
assert.deepEqual([shown.length, shown[3].transfer?.id], [4, 'dddddddd4444']);
""")

    def test_plate_hover_card_and_tooltip(self):
        self.run_js(r"""
const t0 = Date.parse('2026-11-04T08:00:00Z');
const record = {id: 'aaaaaaaa1111', name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos', state: 'planned', at: new Date(t0).toISOString(), seen: new Date(t0).toISOString(), account: [],
  events: [{at: new Date(t0).toISOString(), what: 'registered', text: 'Registered on the transfer page'}]};
const character = {transfer: {id: record.id, state: 'planned'}};
const plate = plain(GBT.plateOf(character, [record], t0 + H));
assert.deepEqual([plate.kind, plate.to, plate.confirm], ['planned', 'Kadmos', false]);
assert.ok(plate.when);
assert.match(GBT.cardLine(character, [record], t0 + H).text, /^Transfer to Kadmos registered .+: due in the maintenance .+/);
// The tooltip counts down to that Thursday's maintenance, says who, and warns of mail left in the mailbox
let tip = plain(GBT.tipOf(record, t0 + H, null, {rom: "Mate's account", gameforge: 'main', mail: '3 mails waiting'}));
assert.equal(tip.title, 'Transfer: Zuuzuuhehtne');
assert.equal(tip.countdown.label, 'Thursday maintenance in');
assert.equal(new Date(tip.countdown.at).toISOString(), '2026-11-05T08:00:00.000Z');
assert.ok(tip.lines.some(line => line.text === "RoM account: Mate's account · Gameforge: main"));
assert.ok(tip.lines.some(line => line.kind === 'warn' && /Mailbox: 3 mails waiting/.test(line.text)));
assert.ok(tip.lines.some(line => line.kind === 'event' && /Registered on the transfer page$/.test(line.text)));
// Past its maintenance with nothing new: due, and the countdown is to the next one
const later = Date.parse('2026-11-05T10:00:00Z');
assert.equal(GBT.plateOf(character, [record], later).kind, 'due');
tip = plain(GBT.tipOf(record, later));
assert.match(tip.countdown.label, /^If it didn't move: next Thursday maintenance in$/);
assert.equal(new Date(tip.countdown.at).toISOString(), '2026-11-12T08:00:00.000Z');
// Moved: the plate asks for the login that confirms it
const moved = {...record, state: 'moved', ended: new Date(later).toISOString()};
assert.equal(GBT.plateOf({transfer: {id: record.id, state: 'moved'}}, [moved], later).confirm, true);
assert.equal(GBT.tipOf(moved, later).countdown, null);
assert.equal(GBT.PHASE_NAMES[GBT.phase(moved, later)], 'Moved: log in to confirm');
""")

    def test_page_state_maintenance_setting_and_changes(self):
        self.run_js(r"""
(async () => {
  const stored = {};
  const storage = {get: async keys => Object.fromEntries([].concat(keys).filter(key => key in stored).map(key => [key, plain(stored[key])])), set: async data => Object.assign(stored, plain(data))};
  const changed = [], sent = [];
  const t0 = Date.now() - H;
  stored.gbTransfers = {v: 1, list: [{id: 'aaaaaaaa1111', name: 'Anna', from: 'Gaia', to: 'Kadmos', state: 'planned', at: new Date(t0).toISOString(), seen: new Date(t0).toISOString(), account: ['gaia|mate'], events: []}]};
  const page = GBT.create({storage, send: async message => { sent.push(message); return {ok: true}; }, changed: what => changed.push(what)});
  await page.load();
  assert.equal(page.records().length, 1);
  const count = page.counts();
  assert.deepEqual([count.planned + count.due, count.moved, count.active, count.total], [1, 0, 1, 1]);
  // A change that only says when it was last listed draws the page again; one that moves it prepares the characters
  const seen = plain(stored.gbTransfers); seen.list[0].seen = new Date().toISOString();
  page.stored({gbTransfers: {newValue: seen}});
  const moved = plain(stored.gbTransfers); moved.list[0].state = 'moved'; moved.list[0].ended = new Date().toISOString();
  page.stored({gbTransfers: {newValue: moved}});
  page.stored({other: {newValue: 1}});
  assert.deepEqual(changed, ['times', 'records']);
  // The maintenance day and time are kept
  await page.setMaintenance({day: 3, hour: 10, minute: 30});
  assert.deepEqual(plain(stored.gbMaintenance), {day: 3, hour: 10, minute: 30});
  // New saves that show something go to the background; Forget too
  page.stored({gbTransfers: {newValue: seen}});
  const characters = [{name: 'Anna', server: 'Kadmos', roster: ['Anna'], saved: saved(Date.now())}];
  assert.equal(await page.check(characters), 1);
  await page.forget('aaaaaaaa1111');
  assert.deepEqual(sent.map(message => [message.type, message.changes[0].state]), [['transfers-change', 'done'], ['transfers-change', 'forget']]);
  process.exit(0);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_background_takes_reads_only_from_the_transfer_page_and_changes_only_from_its_own_page(self):
        self.run_js(r"""
(async () => {
  let listener;
  const local = {}, session = {};
  const area = store => ({get: async keys => Object.fromEntries([].concat(keys).filter(key => key in store).map(key => [key, plain(store[key])])),
    set: async data => Object.assign(store, plain(data)), setAccessLevel: async () => {}});
  const chrome = {runtime: {id: 'test', getURL: file => 'chrome-extension://test/' + file, onMessage: {addListener: fn => { listener = fn; }},
    onStartup: {addListener() {}}, onInstalled: {addListener() {}}, sendNativeMessage: (host, message, reply) => reply({ok: true})},
    storage: {local: area(local), session: area(session), onChanged: {addListener() {}}}, alarms: {create() {}, onAlarm: {addListener() {}}}};
  const source = fs.readFileSync(path.join(folder, 'background.js'), 'utf8');
  const sandbox = {chrome, URL, console, setTimeout, clearTimeout, Date, Intl, crypto: globalThis.crypto,
    importScripts: file => vm.runInContext(fs.readFileSync(path.join(folder, file), 'utf8'), sandbox)};
  vm.createContext(sandbox);
  vm.runInContext(source, sandbox);
  const ask = (message, sender) => new Promise(resolve => { if (listener(message, sender, resolve) !== true) resolve('no answer'); });
  const read = {type: 'transfer-page', planned: [{name: 'Anna', from: 'Gaia', to: 'Kadmos'}], offered: [{name: 'Anna', server: 'Gaia'}], form: true};
  // Not from the transfer page, or not from a tab: ignored
  assert.equal(await ask(read, {id: 'test', tab: {id: 3}, url: 'https://en.runesofmagic.gameforge.com/user/administration'}), 'no answer');
  assert.equal(await ask(read, {id: 'test', tab: {id: 3}, url: 'https://evil.example/charactertransfer'}), 'no answer');
  assert.equal(await ask(read, {id: 'test', url: 'https://en.runesofmagic.gameforge.com/charactertransfer'}), 'no answer');
  assert.equal(local.gbTransfers, undefined);
  // From the transfer page in a tab: kept, with what to tell the player there
  const answer = await ask(read, {id: 'test', tab: {id: 3}, url: 'https://en.runesofmagic.gameforge.com/charactertransfer'});
  assert.equal(answer.ok, true);
  assert.deepEqual(plain(answer.added.map(item => [item.name, item.to])), [['Anna', 'Kadmos']]);
  assert.equal(local.gbTransfers.list[0].state, 'planned');
  assert.deepEqual(Object.keys(session.transferTabs), ['3']);
  assert.deepEqual(plain((await ask({...read, planned: 'x'}, {id: 'test', tab: {id: 3}, url: 'https://de.runesofmagic.gameforge.com/charactertransfer'}))), {ok: false, error: 'Not a transfer page read.'});
  // Changes come only from the Global Bank page
  const id = local.gbTransfers.list[0].id;
  const change = {type: 'transfers-change', changes: [{id, state: 'forget'}]};
  assert.equal(await ask(change, {id: 'test', tab: {id: 3}, url: 'https://en.runesofmagic.gameforge.com/charactertransfer'}), 'no answer');
  assert.equal(local.gbTransfers.list.length, 1);
  assert.equal((await ask(change, {id: 'test', url: 'chrome-extension://test/control.html'})).ok, true);
  assert.equal(local.gbTransfers.list.length, 0);
  process.exit(0);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_transfer_page_script_sends_only_what_it_understood(self):
        self.run_js(r"""
(async () => {
  const sent = [];
  let observer, notice = null;
  const text = value => ({textContent: value, parentElement: {closest: () => null}});
  const texts = ['MY ACCOUNT', 'someone@example.com', 'PLANNED CHARACTER TRANSFERS', 'Zuuzuuhehtne (Gaia (PvE))', '»', 'Kadmos (PvE)', 'Cancel Character Transfer'].map(text);
  const option = value => ({textContent: value});
  const selects = [{options: ['Zuuzuuhehtne (Gaia (PvE))', 'Mate (Gaia (PvE))'].map(option)}, {options: ['Gaia (PvE)', 'Kadmos (PvE)'].map(option)}];
  const element = () => ({style: {}, setAttribute() {}, append() {}, addEventListener() {}, remove() {}});
  const document = {documentElement: {}, body: {append: node => { notice = node; }}, querySelectorAll: selector => (selector === 'select' ? selects : []),
    createElement: element, createTreeWalker: () => { let at = -1; return {nextNode: () => ++at < texts.length, get currentNode() { return texts[at]; }}; }};
  const timers = [];
  const sandbox = {document, location: {hostname: 'en.runesofmagic.gameforge.com', pathname: '/charactertransfer'}, NodeFilter: {SHOW_TEXT: 4}, Intl, Date, console, crypto: globalThis.crypto,
    MutationObserver: class { constructor(fn) { observer = fn; } observe() {} disconnect() {} },
    setTimeout: fn => { timers.push(fn); return timers.length; }, clearTimeout() {},
    chrome: {runtime: {id: 'test', sendMessage: async message => { sent.push(plain(message)); return {ok: true, added: [], ended: []}; }}}};
  vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(folder, 'transfers.js'), 'utf8'), sandbox);
  vm.runInContext(fs.readFileSync(path.join(folder, 'transfer-page.js'), 'utf8'), sandbox);
  timers.shift()();
  for (let i = 0; i < 5; i++) await new Promise(resolve => setImmediate(resolve));
  assert.deepEqual(sent, [{type: 'transfer-page', planned: [{name: 'Zuuzuuhehtne', from: 'Gaia', to: 'Kadmos'}],
    offered: [{name: 'Zuuzuuhehtne', server: 'Gaia'}, {name: 'Mate', server: 'Gaia'}], form: true}]);
  assert.ok(notice, 'the first read says what it understood');
  // The same page again sends nothing
  observer(); timers.pop()();
  for (let i = 0; i < 5; i++) await new Promise(resolve => setImmediate(resolve));
  assert.equal(sent.length, 1);
  // Another site, or another page of it: the script does nothing
  for (const where of [{hostname: 'evil.example', pathname: '/charactertransfer'}, {hostname: 'en.runesofmagic.gameforge.com', pathname: '/user/administration'}]) {
    const other = {...sandbox, location: where, chrome: {runtime: {id: 'test', sendMessage: async () => { throw new Error('sent'); }}}, MutationObserver: class { observe() { throw new Error('watched'); } }};
    vm.createContext(other);
    vm.runInContext(fs.readFileSync(path.join(folder, 'transfers.js'), 'utf8'), other);
    vm.runInContext(fs.readFileSync(path.join(folder, 'transfer-page.js'), 'utf8'), other);
  }
  process.exit(0);
})().catch(error => { console.error(error); process.exit(1); });
""")

    def test_manifest_page_and_scripts_fit_together(self):
        manifest = json.loads((EXTENSION / 'manifest.json').read_text(encoding='utf-8'))
        scripts = [entry for entry in manifest['content_scripts'] if 'transfer-page.js' in entry['js']]
        self.assertEqual(len(scripts), 1)
        self.assertEqual(scripts[0]['matches'], ['https://*.runesofmagic.gameforge.com/charactertransfer*'])
        self.assertEqual(scripts[0]['js'], ['transfers.js', 'transfer-page.js'])
        self.assertEqual(sorted(manifest['permissions']), ['alarms', 'nativeMessaging', 'storage'])
        self.assertNotIn('host_permissions', manifest)
        self.assertIn("importScripts('transfers.js')", (EXTENSION / 'background.js').read_text(encoding='utf-8'))
        page = (EXTENSION / 'control.html').read_text(encoding='utf-8')
        order = re.findall(r'<script defer src="([^"]+)"', page)
        self.assertLess(order.index('transfers.js'), order.index('control.js'))
        for marker in ('data-roster-filter="transfers"', 'id="transfers-view"', 'id="xfer-tooltip"', 'id="xfer-day"', 'id="xfer-time"', '#xfer'):
            self.assertIn(marker, page)
        # The kit's copy and the separate extension's copy are the same files
        extra = ROOT / 'extras/GlobalBankDailyRewards/GlobalBank/Helper/ChromeExtension'
        for name in ('transfers.js', 'transfer-page.js', 'manifest.json', 'control.js', 'control.html', 'control.css', 'background.js', 'bank.js', 'roster.js', 'accounts.js'):
            self.assertEqual((extra / name).read_bytes(), (EXTENSION / name).read_bytes(), name)


if __name__ == '__main__':
    unittest.main()
