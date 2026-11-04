"""The helper's terminal, tested for real: Windows PowerShell 5.1, a real console with no window, real native
messaging frames and the mailbox between them. Every script is a private copy with its own mutex, and the
characters are made up, so a helper running on this PC is neither seen nor touched."""
from pathlib import Path
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import time
import unittest
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
SHELL = shutil.which('powershell')

if sys.platform == 'win32':
    from gb_console_driver import HelperConsole, CREATE_NO_WINDOW


def snapshot(name, gold=1000, items='', server=''):
    return f'GB1~{name}~Warrior~60~{gold}~60~100~1~x`C~Warrior~60`C~Mage~100{items}' + (f'`S~{server}' if server else '')


@unittest.skipUnless(SHELL and sys.platform == 'win32', 'Windows PowerShell required')
class TerminalFixture(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='gbterm-'))
        self.addCleanup(shutil.rmtree, self.root, True)
        self.helper = self.root / 'Interface/AddOns/CherrysKit/GlobalBank/Helper'
        self.helper.mkdir(parents=True)
        self.saves = self.root / 'saves'
        self.saves.mkdir()
        mutex = 'GBTerminalTest' + uuid.uuid4().hex
        # The local host runs the helper with its default folders, so the copies must have this one in place of the player's.
        real_saves = 'Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Runes of Magic"'
        for path in HELPER.glob('*.ps1'):
            text = path.read_text(encoding='utf-8-sig').replace('CherrysKitGlobalBankHelper', mutex)
            if path.name == 'GlobalBank-Update.ps1':
                self.assertIn(real_saves, text)
                text = text.replace(real_saves, "'" + str(self.saves).replace("'", "''") + "'")
            if path.name == 'GlobalBank-Console.ps1':
                # A test must not overwrite the clipboard of whoever is using this PC.
                self.assertIn('Set-Clipboard -Value', text)
                text = text.replace('Set-Clipboard -Value', "Set-Content -LiteralPath '" + str(self.root / 'clipboard.txt') + "' -Value")
            (self.helper / path.name).write_text(text, encoding='utf-8-sig')
        self.data = self.root / 'Interface/GlobalBankHelper'
        self.write_save('Sampleone', items='`B~1~3~5~Mana Stone~icon`K~1~4~5~Mana Stone~icon')
        self.write_save('Sampletwo', gold=2500, items='`B~1~7~9~Mana Potion~icon')
        self.write_save('Sämple')
        self.update = self.helper / 'GlobalBank-Update.ps1'
        self.console = None

    def write_save(self, name, **fields):
        folder = self.saves / name
        folder.mkdir(exist_ok=True)
        text = f'GlobalBank_Char = "{snapshot(name, **fields)}"\n'
        (folder / 'SaveVariables.lua').write_bytes(text.encode('utf-8'))

    def start_helper(self, *extra):
        self.console = HelperConsole([SHELL, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(self.update), '-Watch', '-SaveFolder', str(self.saves), *extra])
        self.addCleanup(self.console.close)
        self.console.wait_text('Global Bank is ready')
        self.wait_for_prompt()
        return self.console

    def wait_for_prompt(self):
        self.console.wait_for(lambda text: any(line.startswith('gb >') for line in text.splitlines()), what='the prompt')

    def run_line(self, line, expect):
        self.console.type(line)
        self.console.key('enter')
        return self.console.wait_text(expect)

    def caret_offset(self):
        data, row, text = self.console.prompt_row()
        return data['cursor'][0] - 5, data['cursor'][1] == row, text

    def host(self, *messages):
        """One native host process, like an open port: frames in, frames out, then close."""
        payload = b''
        for message in messages:
            body = json.dumps(message).encode()
            payload += struct.pack('<I', len(body)) + body
        result = subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(self.helper / 'GlobalBank-NativeHost.ps1')],
                                input=payload, capture_output=True, timeout=120, creationflags=CREATE_NO_WINDOW)
        self.assertEqual(result.returncode, 0, result.stderr.decode(errors='replace'))
        out = result.stdout
        answers = []
        at = 0
        while at < len(out):
            length = struct.unpack('<I', out[at:at + 4])[0]
            self.assertLess(length, 1048576)
            answers.append(json.loads(out[at + 4:at + 4 + length].decode('utf-8')))
            at += 4 + length
        self.assertEqual(at, len(out), 'Something other than a frame reached stdout')
        self.assertEqual(len(answers), len(messages))
        return answers

    def command(self, text, request_id=None):
        return self.host({'type': 'terminal-command', 'requestId': request_id or uuid.uuid4().hex[:16], 'command': text})[0]

    def texts(self, answer):
        return json.dumps(answer['records'], ensure_ascii=False)

    def wait_for_exit(self, timeout=20):
        self.console.process.wait(timeout=timeout)
        return self.console.process.returncode


class NativeConsoleTests(TerminalFixture):
    def test_startup_shows_loading_first_then_the_real_count(self):
        console = self.start_helper()
        text = console.text()
        self.assertLess(text.index('Loading saved characters'), text.index('Global Bank is ready. 3 characters loaded'))
        self.assertNotIn('0 characters', text)
        self.assertNotIn('CHARACTERS & ITEMS', text, 'The full help waits for help.')
        self.assertIn('Try: goldtotal', text)
        # Colour reached the console as colour, whichever way this one supports it, and no escape codes show.
        self.assertNotIn('[38;', text)
        data = console.screen(back=200)
        row_of = lambda start: data['top'] + next(i for i, row in enumerate(data['rows']) if row.startswith(start))
        colour = lambda start: console.ask(kind='attributes', row=row_of(start))['attributes'][0] & 0xF
        self.assertNotEqual(colour('GLOBAL BANK'), colour('Keep this window'))
        self.run_line('help', 'CHARACTERS & ITEMS')

    def test_line_editing_keeps_the_caret_where_the_keys_put_it(self):
        console = self.start_helper()
        console.type('lst gold')
        for _ in range(8):
            console.key('left')
        console.key('right')
        console.type('i')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > list gold', what='the inserted letter')
        self.assertEqual(self.caret_offset()[0], 2)
        console.key('home')
        console.wait_for(lambda _: self.caret_offset()[0] == 0, what='Home')
        console.key('delete')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > ist gold', what='Delete')
        console.type('l')
        console.key('end')
        console.wait_for(lambda _: self.caret_offset()[0] == 9, what='End')
        console.key('backspace')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > list gol', what='Backspace')
        console.type('d')
        console.key('enter')
        console.wait_text('3 characters')

    def test_history_returns_to_the_unfinished_draft_and_escape_clears(self):
        console = self.start_helper()
        self.run_line('goldtotal', '4,500 gold on 3 characters.')
        self.run_line('status', 'Characters')
        console.type('half typ')
        console.key('up')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > status', what='last command')
        console.key('up')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > goldtotal', what='earlier command')
        console.key('down')
        console.key('down')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > half typ', what='the draft')
        console.key('escape')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb >', what='a cleared draft')

    def test_tab_completes_commands_and_names_and_escape_closes_the_list_first(self):
        console = self.start_helper()
        console.type('gol')
        console.key('tab')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > goldtotal', what='the first suggestion')
        self.assertIn('> goldtotal', console.text())
        console.key('tab')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > gold', what='the next suggestion')
        console.key('tab', shift=True)
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > goldtotal', what='Shift+Tab going back')
        console.key('escape')
        console.wait_for(lambda _: '> gold total' not in console.text(), what='the list closing')
        self.assertEqual(self.caret_offset()[2], 'gb > goldtotal')
        console.key('escape')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb >', what='the draft clearing')
        console.type('show Samplet')
        console.key('tab')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > show Sampletwo', what='a character name')
        console.key('enter')
        console.wait_text('Sampletwo (level 60 Warrior): 2,500 gold')

    def test_a_save_arriving_while_typing_leaves_the_draft_and_caret_alone(self):
        console = self.start_helper()
        console.type('search mana stone')
        for _ in range(6):
            console.key('left')
        console.wait_for(lambda _: self.caret_offset()[0] == 11, what='the caret moving')
        self.write_save('Sampletwo', gold=9000, items='`B~1~7~9~Mana Potion~icon')
        console.wait_text('Updated Sampletwo: gold 2,500 -> 9,000 (+6,500)')
        console.wait_for(lambda text: 'Tracking 3 characters' in text, what='the summary')
        # The screen is read from outside, so it can catch the prompt mid-redraw: it has to settle here.
        console.wait_for(lambda _: self.caret_offset() == (11, True, 'gb > search mana stone'), what='the draft and caret unchanged')
        console.type('X')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > search manaX stone', what='typing at the caret')

    def test_wrapped_input_redraws_and_survives_a_resize(self):
        console = self.start_helper()
        width = console.screen()['width']
        long = 'note Sampleone ' + 'word ' * ((width // 5) + 8)
        long = long[:width + 40]
        console.type(long)
        console.wait_for(lambda text: long[-8:].rstrip() in text, what='the wrapped draft')
        data, row, text = console.prompt_row()
        self.assertEqual(text, ('gb > ' + long)[:width].rstrip())
        self.assertEqual(data['cursor'][1], row + 1)
        before = data['rows'].count(text)
        self.assertEqual(before, 1)
        self.write_save('Sampletwo', gold=3000)
        console.wait_text('Updated Sampletwo')
        data, row, text = console.prompt_row()
        self.assertEqual(text, ('gb > ' + long)[:width].rstrip())
        self.assertEqual(data['cursor'][1], row + 1)
        console.key('escape')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb >', what='the wrapped draft clearing')
        tail = console.screen(back=2, below=4)['rows']
        self.assertFalse([line for line in tail if 'word word' in line], 'A wrapped row was left behind.')
        console.type('search mana')
        narrow = width - 30
        self.assertTrue(console.resize(narrow, console.screen()['height'])['ok'])
        console.wait_for(lambda _: console.screen()['width'] == narrow, what='the new width')
        console.wait_for(lambda _: self.caret_offset()[2] == 'gb > search mana', what='the prompt after resizing')
        self.assertEqual(self.caret_offset()[0], len('search mana'))

    def test_tables_wrap_to_the_window_and_keep_every_word(self):
        console = self.start_helper()
        self.run_line('note Sampleone one two three four five six seven eight nine ten eleven twelve', 'Note updated')
        width = console.screen()['width']
        console.resize(50, console.screen()['height'])
        console.wait_for(lambda _: console.screen()['width'] == 50, what='a narrow window')
        self.run_line('list note', '3 characters')
        text = console.text()
        for word in 'one two three four five six seven eight nine ten eleven twelve'.split():
            self.assertIn(word, text)
        self.assertTrue(width)

    def test_clear_copy_follow_and_heartbeat_are_presentation_only(self):
        console = self.start_helper()
        self.run_line('goldtotal', '4,500 gold')
        console.type('clear')
        console.key('enter')
        console.wait_for(lambda text: '4,500 gold' not in text, what='the view clearing')
        self.run_line('goldtotal', '4,500 gold')
        self.run_line('copy', 'Visible command output copied.')
        copied = (self.root / 'clipboard.txt').read_text()
        self.assertIn('4,500 gold', copied)
        self.assertNotIn('Loading saved characters', copied, 'clear also clears what copy takes')
        self.run_line('follow off', 'Follow is paused')
        self.write_save('Sampletwo', gold=3000)
        time.sleep(6)
        self.assertNotIn('Updated Sampletwo', console.text())
        self.assertRegex(console.ask(kind='title')['title'], r'follow paused, \d+ new')
        self.run_line('follow', 'Follow is paused')
        self.run_line('follow on', 'Follow is on')
        console.wait_text('Updated Sampletwo')
        self.run_line('heartbeat off', 'off (0)')
        self.assertEqual((self.data / 'TerminalHeartbeat.txt').read_text(), 'off')
        self.run_line('heartbeat maybe', 'Use heartbeat on|off')
        beat = self.data / 'GlobalBankHelperBeat.lua'
        self.assertTrue(beat.exists(), 'File liveness runs with the text heartbeat off.')

    def test_scrolling_up_holds_new_lines_and_says_how_many(self):
        console = self.start_helper()
        for count in range(1, 5):
            console.type('help')
            console.key('enter')
            console.wait_for(lambda text: text.count('Esc closes suggestions') == count and text.rstrip().endswith('gb >'), what=f'help {count}')
        data = console.screen()
        rows = data['windowBottom'] - data['windowTop'] + 1
        self.assertTrue(console.ask(kind='scroll', top=0, rows=rows, width=data['width'])['ok'])
        self.write_save('Sampletwo', gold=3000)
        console.wait_for(lambda _: ' new' in console.ask(kind='title')['title'], what='the count in the title')
        self.assertNotIn('Updated Sampletwo', console.text(back=300))
        self.assertEqual(console.screen()['windowTop'], 0, 'The window stays where the player scrolled to.')
        data = console.screen()
        self.assertTrue(console.ask(kind='scroll', top=max(0, data['cursor'][1] - rows + 1), rows=rows, width=data['width'])['ok'])
        console.wait_text('Updated Sampletwo')

    def test_the_heartbeat_keeps_to_one_line(self):
        console = self.start_helper()
        console.wait_for(lambda text: text.count('alive |') == 1, timeout=45, what='the first heartbeat')
        first = [line for line in console.text().splitlines() if 'alive |' in line]
        console.wait_for(lambda text: [line for line in text.splitlines() if 'alive |' in line] not in ([], first), timeout=45, what='the second heartbeat')
        self.assertEqual(console.text().count('alive |'), 1)

    def test_erase_asks_first_names_its_scope_and_can_be_undone(self):
        console = self.start_helper()
        self.run_line('erase Samp', 'Several characters start with Samp')
        console.type('erase Sampletwo')
        console.key('enter')
        console.wait_text('Type y to confirm or n to cancel.')
        self.assertIn('Game save files are not changed', console.text())
        self.run_line('maybe', 'Type y to confirm or n to cancel.')
        console.type('n')
        console.key('enter')
        console.wait_text('Nothing was changed')
        self.assertNotIn('Sampletwo', (self.data / 'ExcludedCharacters.json').read_text() if (self.data / 'ExcludedCharacters.json').exists() else '')
        console.type('erase Sampletwo')
        console.key('enter')
        time.sleep(0.5)
        console.type('y')
        console.key('enter')
        console.wait_text('Sampletwo is blocked from tracking')
        console.wait_text('Removed Sampletwo (erased here)')
        self.assertIn('Sampletwo', (self.data / 'ExcludedCharacters.json').read_text())
        self.run_line('unban Sampletwo', 'can be tracked again')

    def test_a_broken_request_does_not_stop_the_helper(self):
        console = self.start_helper()
        folder = self.data / 'TerminalBridge'
        (folder / 'request-broken-0001.json').write_text('{broken', encoding='utf-8')
        (folder / 'request-broken-0002.json').write_text(json.dumps({'schema': 1, 'deadline': 'soon', 'command': 'exit'}), encoding='utf-8')
        answer = self.command('status')
        self.assertTrue(answer['ok'], answer)
        self.assertIsNone(console.process.poll())

    def test_exit_stops_and_says_what_automatic_start_will_do(self):
        (self.data).mkdir(parents=True, exist_ok=True)
        (self.data / 'GlobalBankAutoStart.txt').write_text('on')
        console = self.start_helper()
        console.type('exit')
        console.key('enter')
        self.assertEqual(self.wait_for_exit(), 0)
        feed = json.loads((self.data / 'TerminalFeed.json').read_text(encoding='utf-8'))
        self.assertEqual(feed['state'], 'stopped')
        self.assertEqual(self.command('status')['helper']['state'], 'stopped')


class BridgeTests(TerminalFixture):
    def test_the_page_reaches_the_running_helper_not_a_new_process(self):
        self.start_helper()
        answer = self.command('status')
        self.assertTrue(answer['ok'], answer)
        self.assertEqual(answer['source'], 'live')
        self.assertTrue(answer['helper']['running'])
        self.assertEqual(answer['helper']['state'], 'watching')
        self.assertEqual(answer['helper']['characters'], 3)
        self.assertIsNotNone(answer['helper']['since'])
        self.assertIn('Running', self.texts(answer))

    def test_heartbeat_off_from_the_page_changes_the_live_text_and_not_the_liveness(self):
        console = self.start_helper()
        answer = self.command('heartbeat off')
        self.assertTrue(answer['ok'])
        self.assertFalse(answer['helper']['heartbeatText'])
        self.assertIn('off (0)', self.texts(answer))
        console.wait_text('From the browser: heartbeat off')
        feed = self.host({'type': 'terminal-feed', 'session': None, 'after': 0, 'max': 50})[0]
        self.assertEqual([event['origin'] for event in feed['events'] if 'From the browser' in event['text']], ['browser'])
        self.assertFalse([event for event in feed['events'] if 'From the browser' not in event['text'] and 'origin' in event])
        self.run_line('status', 'off (0)')
        beat = self.data / 'GlobalBankHelperBeat.lua'
        self.assertTrue(beat.exists())

    def test_exit_from_the_page_is_acknowledged_and_stops_that_helper(self):
        (self.data).mkdir(parents=True, exist_ok=True)
        (self.data / 'GlobalBankAutoStart.txt').write_text('on')
        self.start_helper()
        answer = self.command('stop')
        self.assertTrue(answer['ok'], answer)
        self.assertEqual(answer['commandId'], 'exit')
        self.assertTrue(answer['helper']['stopping'])
        self.assertIn('Stopping the helper', self.texts(answer))
        self.assertIn('starts again in the background within a minute while Chrome is open', self.texts(answer))
        self.assertEqual(self.wait_for_exit(), 0)
        self.assertEqual((self.data / 'GlobalBankAutoStart.txt').read_text(), 'on', 'exit leaves the Chrome preference alone')
        after = self.command('exit')
        self.assertEqual(after['outcome'], 'no-helper')
        self.assertFalse(after['ok'])

    def test_a_note_from_the_page_is_live_and_survives_the_next_save_scan(self):
        console = self.start_helper()
        answer = self.command('note Sampleone from the page')
        self.assertTrue(answer['ok'], answer)
        self.assertTrue(answer['changed'])
        self.run_line('show Sampleone', 'from the page')
        self.write_save('Sampletwo', gold=7777)
        console.wait_text('Updated Sampletwo')
        answer = self.command('show Sampleone')
        self.assertIn('from the page', self.texts(answer))
        self.assertIn('from the page', (self.data / 'GlobalBank.json').read_text(encoding='utf-8'))
        database = (self.data / 'GlobalBankDatabase.lua').read_text(encoding='latin-1')
        self.assertIn('from the page', database)

    def test_erase_from_the_page_confirms_through_the_same_helper(self):
        self.start_helper()
        answer = self.command('erase Sampletwo')
        self.assertEqual(answer['outcome'], 'confirm')
        self.assertTrue(answer['ok'])
        record = answer['records'][-1]
        self.assertEqual(record['kind'], 'confirm')
        self.assertEqual(record['yes'], 'Remove Sampletwo')
        self.assertFalse((self.data / 'ExcludedCharacters.json').exists())
        confirm = {'type': 'terminal-confirm', 'requestId': uuid.uuid4().hex[:16], 'token': record['token']}
        again = self.host({**confirm, 'answer': 'what'})[0]
        self.assertEqual(again['outcome'], 'confirm')
        cancel = self.host({**confirm, 'requestId': uuid.uuid4().hex[:16], 'answer': 'no'})[0]
        self.assertEqual(cancel['outcome'], 'ok')
        self.assertFalse((self.data / 'ExcludedCharacters.json').exists())
        done = self.host({**confirm, 'requestId': uuid.uuid4().hex[:16], 'answer': 'y'})[0]
        self.assertEqual(done['outcome'], 'ok', done)
        self.assertTrue(done['changed'])
        self.assertIn('blocked from tracking', self.texts(done))
        self.assertIn('Sampletwo', (self.data / 'ExcludedCharacters.json').read_text())
        time.sleep(0.5)
        self.assertIn('"excluded":["Sampletwo"]', (self.data / 'TerminalFeed.json').read_text(encoding='utf-8').replace(' ', ''))
        self.assertEqual(self.command('goldtotal')['helper']['characters'], 2)

    def test_the_same_request_twice_runs_once(self):
        self.start_helper()
        request_id = 'same-request-0001'
        first = self.command('note Sampleone once', request_id)
        database = self.data / 'GlobalBankDatabase.lua'
        version = database.read_text(encoding='latin-1').split('Sampleone~')[1].split('~')[0]
        second = self.command('note Sampleone once', request_id)
        self.assertEqual(first['records'], second['records'])
        self.assertEqual(database.read_text(encoding='latin-1').split('Sampleone~')[1].split('~')[0], version)

    def test_a_request_past_its_deadline_is_dropped_unrun(self):
        self.start_helper()
        folder = self.data / 'TerminalBridge'
        request = {'schema': 1, 'id': 'late-request-0001', 'kind': 'command', 'command': 'note Sampleone too late', 'origin': 'web', 'deadline': 1000}
        (folder / 'request-late-request-0001.json').write_text(json.dumps(request), encoding='utf-8')
        answer = self.command('goldtotal')
        self.assertTrue(answer['ok'])
        self.assertFalse((folder / 'request-late-request-0001.json').exists())
        self.assertFalse((folder / 'reply-late-request-0001.json').exists())
        self.assertNotIn('too late', (self.data / 'GlobalBankDatabase.lua').read_text(encoding='latin-1'))

    def test_a_silent_helper_times_out_and_says_a_change_may_have_applied(self):
        # A helper from a stale feed file: the mutex is held, nothing answers.
        console = self.start_helper()
        feed = self.data / 'TerminalFeed.json'
        self.assertTrue(feed.exists())
        bridge = (self.helper / 'GlobalBank-Bridge.ps1')
        text = bridge.read_text(encoding='utf-8-sig').replace('$script:GBBridgeWaitMs = 30000', '$script:GBBridgeWaitMs = 1')
        bridge.write_text(text, encoding='utf-8-sig')
        answer = self.command('note Sampleone maybe')
        self.assertEqual(answer['outcome'], 'timeout')
        self.assertTrue(answer['maybeApplied'])
        self.assertFalse(answer['ok'])
        self.assertTrue(console.process.poll() is None)

    def test_a_feed_reader_gets_cursors_gaps_and_new_sessions(self):
        console = self.start_helper()
        first = self.host({'type': 'terminal-feed', 'session': None, 'after': 0, 'max': 50})[0]
        self.assertTrue(first['ok'])
        self.assertIsNone(first['gap'])
        self.assertTrue(first['session'])
        kinds = [event['kind'] for event in first['events']]
        self.assertIn('loaded', kinds)
        self.write_save('Sampletwo', gold=1234)
        console.wait_text('Updated Sampletwo')
        time.sleep(0.5)
        later = self.host({'type': 'terminal-feed', 'session': first['session'], 'after': first['seq'], 'max': 50})[0]
        updated = [event for event in later['events'] if event['kind'] == 'updated' and event.get('character') == 'Sampletwo']
        self.assertTrue(updated)
        self.assertTrue(updated[0]['dataChanged'])
        self.assertIn('2,500 -> 1,234', updated[0]['text'])
        self.assertGreater(later['seq'], first['seq'])
        # Nothing new: no events, the same cursor
        idle = self.host({'type': 'terminal-feed', 'session': later['session'], 'after': later['seq'], 'max': 50})[0]
        self.assertEqual(idle['events'], [])
        self.assertEqual(idle['seq'], later['seq'])
        self.assertIsNone(idle['gap'])
        document = json.loads((self.data / 'TerminalFeed.json').read_text(encoding='utf-8'))
        document['events'] = [{'seq': 500, 'time': 'x', 'kind': 'notice', 'tone': 'info', 'text': 'kept'}]
        document['seq'] = 500
        (self.data / 'TerminalFeed.json').write_text(json.dumps(document), encoding='utf-8')
        behind = self.host({'type': 'terminal-feed', 'session': document['session'], 'after': 3, 'max': 50})[0]
        self.assertEqual(behind['gap'], {'from': 4, 'to': 499})
        self.assertEqual([event['seq'] for event in behind['events']], [500])

    def test_one_port_answers_in_order_without_starting_a_process_for_each(self):
        self.start_helper()
        messages = [{'type': 'terminal-catalogue'}, {'type': 'terminal-feed', 'session': None, 'after': 0, 'max': 5},
                    {'type': 'terminal-command', 'requestId': 'port-request-0001', 'command': 'gold Sampleone'},
                    {'type': 'terminal-command', 'requestId': 'port-request-0002', 'command': 'clear'},
                    {'type': 'terminal-confirm', 'requestId': 'port-request-0003', 'token': 'not a token', 'answer': 'y'}]
        catalogue, feed, gold, clear, confirm = self.host(*messages)
        self.assertEqual(catalogue['prefixes'], ['/', 'get '])
        self.assertIn('Sampletwo', catalogue['characters'])
        self.assertTrue(any(command['id'] == 'show' and command['arg'] == 'character' for command in catalogue['commands']))
        self.assertEqual(catalogue['banner'][0]['kind'], 'message')
        self.assertEqual(len(feed['events']) <= 5, True)
        self.assertEqual(gold['requestId'], 'port-request-0001')
        self.assertIn('1,000 gold', self.texts(gold))
        self.assertEqual(clear['records'], [{'kind': 'control', 'action': 'clear'}])
        self.assertEqual(confirm['outcome'], 'error')
        self.assertEqual(confirm['records'][0]['code'], 'confirm-expired')


class OfflineAndParityTests(TerminalFixture):
    def read_only_fixtures(self):
        return ['goldtotal', 'get totalgold', '/total', 'gold total', 'gold Sampleone', 'list gold', 'chars level', 'characters items Sample',
                'search mana', 'find mana stone', 'item potion', 'items nothing-here', 'search warrior >= 60', 'search warrior > 60', 'search mage < 101',
                'show Sampleone', 'char Sämple', 'character Sampletwo', 'view Samp', 'bank Sampleone', 'bag nobody', 'gold nobody', 'ban list', 'daily',
                'help', '?', 'commands', 'help show', 'help nothing', 'nonsense', 'ban', 'ban Sampleone', 'get', 'copy', 'copy now', 'follow', 'follow off', 'follow sideways', 'clear']

    def test_both_surfaces_answer_every_fixture_identically(self):
        self.host({'type': 'terminal-command', 'requestId': 'prepare-0001', 'command': 'update'})
        offline = {}
        for command in self.read_only_fixtures():
            answer = self.command(command)
            records = [record for record in answer['records'] if not (record['kind'] == 'message' and 'uses saved data' in record['text'])]
            offline[command] = (answer['commandId'], answer['outcome'], records)
        self.start_helper()
        for command in self.read_only_fixtures():
            answer = self.command(command)
            self.assertEqual((answer['commandId'], answer['outcome'], answer['records']), offline[command], command)
        # What the window itself runs: the same dispatcher, the same records, drawn as text
        self.run_line('search mana', 'Mana Stone: 7 on 1 character')
        self.run_line('gold nobody', 'No character called nobody')

    def test_aliases_and_prefixes_all_reach_the_same_command(self):
        self.command('update')
        for commands, expected in ((['help', '?', 'commands', 'get help', '/help', 'HELP'], 'help'),
                                   (['goldtotal', 'totalgold', 'total', 'gold', 'gold total', 'GET GOLD TOTAL'], 'goldtotal'),
                                   (['list', 'chars', 'characters'], 'list'), (['search x', 'find x', 'item x', 'items x'], 'search'),
                                   (['show Sampleone', 'char Sampleone', 'character Sampleone', 'view Sampleone', 'bank Sampleone', 'bag Sampleone'], 'show'),
                                   (['update', 'refresh'], 'update'), (['export', 'json'], 'export'), (['exit', 'quit', 'stop'], 'exit')):
            for command in commands:
                self.assertEqual(self.command(command)['commandId'], expected, command)

    def test_stopped_helper_labels_saved_data_and_refuses_session_commands(self):
        self.command('update')
        answer = self.command('goldtotal')
        self.assertTrue(answer['ok'])
        self.assertEqual(answer['source'], 'offline')
        self.assertIn('stopped', answer['records'][0]['text'])
        self.assertEqual(answer['helper']['state'], 'stopped')
        self.assertIsNone(answer['helper']['characters'], 'Not known is not zero')
        for command in ('heartbeat off', 'heartbeat', 'exit', 'quit'):
            refused = self.command(command)
            self.assertFalse(refused['ok'], command)
            self.assertEqual(refused['outcome'], 'no-helper')
            self.assertEqual(refused['records'][0]['code'], 'no-helper')

    def test_errors_are_semantic_and_input_is_never_evaluated(self):
        self.command('update')
        marker = self.root / 'ran.txt'
        for command, code in ((f'help; New-Item "{marker}"', 'unknown-command'), (f'$(New-Item {marker})', 'unknown-command'),
                              ('note', 'usage'), ('search', 'usage'), ('gold nobody', 'not-found'), ('show Samp', 'ambiguous'),
                              ('note Sampleone bad"quote', 'invalid'), ('note Sampleone ' + 'x' * 81, 'invalid'), ('x' * 257, 'invalid'), ('a\u0001b', 'invalid')):
            answer = self.command(command)
            self.assertFalse(answer['ok'], command)
            self.assertEqual(answer['outcome'], 'error', command)
            self.assertEqual(answer['records'][-1]['kind'], 'error', command)
            self.assertEqual(answer['records'][-1]['code'], code, command)
        self.assertFalse(marker.exists())

    def test_the_same_name_on_two_servers_must_be_told_apart(self):
        self.write_save('Samename', server='Aynara')
        text = (self.saves / 'Samename/SaveVariables.lua').read_bytes().decode()
        (self.saves / 'Samename/SaveVariables.lua').write_bytes((text + 'GlobalBank_Others = "' + snapshot('Samename', gold=222, server='Sonnenwind') + '"\n').encode())
        self.command('update')
        ambiguous = self.command('show Samename')
        self.assertEqual(ambiguous['records'][-1]['code'], 'ambiguous')
        self.assertIn('Samename (Aynara)', ambiguous['records'][-1]['text'])
        self.assertIn('Samename (Sonnenwind)', ambiguous['records'][-1]['text'])
        self.assertTrue(self.command('gold Samename (Sonnenwind)')['ok'])
        self.assertIn('222 gold', self.texts(self.command('gold Samename (Sonnenwind)')))
        note = self.command('note Samename (Sonnenwind) only this one')
        self.assertTrue(note['ok'], note)
        self.assertIn('only this one', self.texts(self.command('show Samename (Sonnenwind)')))
        self.assertNotIn('only this one', self.texts(self.command('show Samename (Aynara)')))
        erase = self.command('erase Samename')
        self.assertEqual(erase['outcome'], 'confirm')
        text = erase['records'][-1]['text']
        self.assertIn('Samename (Aynara), Samename (Sonnenwind)', text)
        self.assertIn('every server', text)

    def test_unicode_names_and_notes_keep_their_letters(self):
        self.command('update')
        answer = self.command('note Sämple für die Bank')
        self.assertTrue(answer['ok'], answer)
        show = self.command('show Sämple')
        self.assertIn('Sämple', self.texts(show))
        self.assertIn('für die Bank', self.texts(show))

    def test_a_long_answer_stays_inside_the_byte_limit_and_says_what_it_left_out(self):
        name = '\u6f22\u5b57' * 30
        items = ''.join(f'`B~{slot}~1~{slot}~{name} {slot:05d}~icon' for slot in range(1, 12000))
        self.write_save('Sampleone', items=items)
        self.command('update')
        answer = self.command('show Sampleone')
        encoded = json.dumps(answer, ensure_ascii=False).encode('utf-8')
        self.assertLess(len(encoded), 1048576)
        self.assertGreater(answer['omitted'], 0)
        self.assertIn('more rows were left out', self.texts(answer))

    def test_the_older_bank_command_route_keeps_its_output(self):
        answer = self.host({'type': 'bank-command', 'command': 'update'})[0]
        self.assertTrue(answer['ok'], answer)
        self.assertEqual(answer['output'].strip().split('\n')[-1], 'Tracking 3 characters, 4,500 gold in total.')
        self.assertEqual(answer['result']['commandId'], 'update')
        self.assertTrue(answer['result']['changed'])
        self.assertEqual(answer['bridge'], 4)

    def test_a_script_runs_erase_only_for_an_exact_name(self):
        def run(text):
            return subprocess.run([SHELL, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(self.update), '-SaveFolder', str(self.saves), '-Command', text],
                                  capture_output=True, text=True, timeout=60, creationflags=CREATE_NO_WINDOW)
        run('update')
        self.assertIn('Type the exact name', run('erase Sampleo').stdout)
        self.assertFalse((self.data / 'ExcludedCharacters.json').exists())
        self.assertIn('blocked from tracking', run('erase Sampleone').stdout)
        self.assertIn('Sampleone', (self.data / 'ExcludedCharacters.json').read_text())


if __name__ == '__main__':
    unittest.main()
