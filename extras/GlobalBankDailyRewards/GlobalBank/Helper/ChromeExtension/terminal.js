'use strict';
// The Terminal page: the same commands, wording and results as the helper's own window. PowerShell understands the
// commands and says everything there is to say (docs/GLOBALBANK-TERMINAL-PROTOCOL.md). This only draws its records as
// text, keeps your draft and caret while results and updates arrive, and follows the output. The only words of its own
// are for things only a browser has: its buttons, and the bridge itself not answering.
const GBTerminal = (() => {
  const MAX_BLOCKS = 300;
  const MAX_LINES_IN_A_BLOCK = 200;
  const MAX_HISTORY = 200;
  const POLL_MS = 2000;
  const POLL_FAILED_MS = 10000;
  // On the page's other tabs the feed is still read, a little slower, so new saves reach every tab without a click
  const WATCH_MS = 3000;
  const FEED_SIZE = 50;

  const make = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  };
  const number = value => Number(value || 0).toLocaleString('en-US');
  const clock = iso => {
    const date = new Date(iso);
    if (!Number.isFinite(date.getTime())) return '--:--';
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  };
  const cellText = cell => (cell !== null && typeof cell === 'object' ? String(cell.text ?? '') : String(cell ?? ''));

  // A record as plain lines, for Copy output, and for pages that only want to say what happened
  function recordLines(record) {
    const lines = [];
    if (record.title) lines.push(record.title);
    if (record.kind === 'message') lines.push(record.text);
    else if (record.kind === 'error') lines.push(record.text, ...(record.usage ? [`Usage: ${record.usage}`] : []));
    else if (record.kind === 'table') {
      lines.push((record.columns || []).map(column => column.label).join('\t'));
      for (const row of record.rows || []) lines.push(row?.heading !== undefined ? row.heading : row.map(cellText).join('\t'));
      if (record.total) lines.push(`${record.total.label}: ${record.total.value}`);
    } else if (record.kind === 'status') {
      for (const pair of record.pairs || []) lines.push(`${pair.label}: ${pair.value}`);
    } else if (record.kind === 'help') {
      for (const group of record.groups || []) {
        lines.push(group.name);
        for (const row of group.rows || []) lines.push(`${row.usage} — ${row.text}`);
      }
    } else if (record.kind === 'confirm') lines.push(record.text, record.prompt);
    lines.push(...(record.notes || []));
    return lines.filter(line => line !== undefined && line !== null);
  }
  const recordsText = records => (records || []).flatMap(recordLines).join('\n');

  // Every message answers, whatever happens: a reply saying the bridge failed is drawn like any other
  async function ask(message) {
    try {
      const reply = await chrome.runtime.sendMessage(message);
      if (reply) return reply.ok || reply.outcome ? reply : {...reply, outcome: 'bridge', records: reply.records || []};
      return {ok: false, outcome: 'bridge', error: 'The extension gave no answer. Update Cherry’s Kit, then reload the extension.', records: []};
    } catch (error) {
      return {ok: false, outcome: 'bridge', error: String(error.message || error), records: []};
    }
  }
  let requests = 0;
  const newRequestId = () => `page-${Date.now().toString(36)}-${(++requests).toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

  // options: {onChanged(): saved data changed, onHelper(): the helper started, stopped or began stopping,
  // savedTotals(): {characters, gold} from the Bank's data, for when no helper knows them, toast(text), startHelper()}
  function create(options = {}) {
    const byId = id => document.getElementById(id);
    const output = byId('term-output');
    const input = byId('term-input');
    const list = byId('term-completions');
    const idlePlaceholder = input.placeholder;
    const blocks = [];
    const history = [];
    let historyAt = 0, draft = '';
    let busy = false, pending = null, helper = null, bridgeDown = false;
    let follow = true, manualPause = false, unread = 0;
    let shown = false, watching = false, opened = false, polling = false, timer = 0, session = null, seq = 0;
    let catalogue = null, catalogueAsked = null;
    let suggestions = [], cycleAt = -1, listDismissed = false;
    let eventBlock = null;

    // ---- The output
    function afterAdding() {
      if (follow) {
        output.scrollTop = output.scrollHeight;
        unread = 0;
      } else unread++;
      showFollow();
    }
    function addBlock(block) {
      output.append(block.node);
      blocks.push(block);
      // Long output stays bounded: the oldest goes first
      while (blocks.length > MAX_BLOCKS) blocks.shift().node.remove();
    }
    function showFollow() {
      byId('term-follow-text').textContent = follow ? 'Pause follow' : 'Resume follow';
      byId('term-follow').setAttribute('aria-pressed', String(!follow));
      byId('term-unread').textContent = unread ? ` · ${number(unread)} new` : '';
    }
    function setFollow(on) {
      follow = on;
      manualPause = !on;
      if (on) {
        output.scrollTop = output.scrollHeight;
        unread = 0;
      }
      showFollow();
    }
    output.addEventListener('scroll', () => {
      const atEnd = output.scrollHeight - output.scrollTop - output.clientHeight < 30;
      if (!atEnd) follow = false;
      else if (!manualPause) {
        follow = true;
        unread = 0;
      }
      showFollow();
    }, {passive: true});

    function drawTable(record) {
      const box = make('div', 'gbt-table-scroll');
      const table = make('table', 'gbt-table');
      if (record.caption) table.append(make('caption', 'gb-sr-only', record.caption));
      const columns = record.columns || [];
      const headRow = make('tr');
      for (const column of columns) {
        const heading = make('th', column.numeric ? 'gbt-numeric' : '', column.label);
        heading.scope = 'col';
        headRow.append(heading);
      }
      const head = make('thead');
      head.append(headRow);
      const body = make('tbody');
      for (const row of record.rows || []) {
        const line = make('tr');
        if (row && !Array.isArray(row) && row.heading !== undefined) {
          const cell = make('td', 'gbt-heading', row.heading);
          cell.colSpan = Math.max(1, columns.length);
          line.append(cell);
        } else {
          (row || []).forEach((value, index) => {
            const column = columns[index] || {};
            const tone = value !== null && typeof value === 'object' && value.tone ? `gbt-tone-${value.tone}` : '';
            line.append(make('td', [column.numeric ? 'gbt-numeric' : '', column.gold ? 'gbt-table-gold' : '', column.wrap ? 'gbt-wrap' : '', tone].filter(Boolean).join(' '), cellText(value)));
          });
        }
        body.append(line);
      }
      table.append(head, body);
      box.append(table);
      return box;
    }
    function answerConfirm(answer, typed) {
      if (!pending || busy) return;
      const token = pending.token;
      run(typed, requestId => ({type: 'terminal-confirm', requestId, token, answer}));
    }
    function closePending() {
      if (!pending) return;
      pending.node.querySelectorAll('button').forEach(button => { button.disabled = true; });
      pending = null;
    }
    function drawConfirm(record) {
      const box = make('div', 'gbt-confirm');
      box.append(make('p', '', record.text));
      if (record.prompt) box.append(make('p', 'gbt-prompt-line', record.prompt));
      const actions = make('div', 'gbt-confirm-actions');
      for (const [answer, label, kind] of [['yes', record.yes, 'is-yes'], ['no', record.no, '']]) {
        const button = make('button', kind, label);
        button.type = 'button';
        button.addEventListener('click', () => answerConfirm(answer, label));
        actions.append(button);
      }
      box.append(actions);
      pending = {token: record.token, node: box, record};
      return box;
    }
    // What a presentation command says comes with it, because only this side knows how it went
    async function runControl(record, result) {
      if (record.action === 'clear') {
        clearView();
        return;
      }
      if (record.action === 'follow') {
        if (record.value) setFollow(record.value === 'on');
        const text = follow ? record.messages?.on : record.messages?.off;
        if (text) result.append(make('p', 'gbt-tone-ok', text));
        return;
      }
      if (record.action === 'copy') {
        const done = await copyOutput();
        const text = done ? record.messages?.done : record.messages?.failed;
        if (text) result.append(make('p', done ? 'gbt-tone-ok' : 'gbt-tone-warn', text));
        afterAdding();
      }
    }
    function drawRecord(record, result, words) {
      if (record.title) {
        result.append(make('p', 'gbt-title', record.title));
      }
      if (record.kind === 'message') {
        result.append(make('p', [`gbt-tone-${record.tone || 'info'}`, record.small ? 'gbt-small' : ''].filter(Boolean).join(' '), record.text));
      } else if (record.kind === 'error') {
        result.append(make('p', 'gbt-tone-error', record.text));
        if (record.usage) result.append(make('p', 'gbt-tone-muted gbt-small', `Usage: ${record.usage}`));
      } else if (record.kind === 'table') {
        result.append(drawTable(record));
        if (record.total) {
          const total = make('div', 'gbt-total-row');
          total.append(make('span', '', record.total.label), make('strong', '', record.total.value));
          result.append(total);
        }
      } else if (record.kind === 'status') {
        const pairs = make('dl', 'gbt-key-value');
        for (const pair of record.pairs || []) pairs.append(make('dt', '', pair.label), make('dd', pair.tone ? `gbt-tone-${pair.tone}` : '', pair.value));
        result.append(pairs);
      } else if (record.kind === 'help') {
        for (const group of record.groups || []) {
          const part = make('div', 'gbt-help-group');
          part.append(make('strong', '', group.name));
          for (const row of group.rows || []) {
            const line = make('div', 'gbt-help-row');
            line.append(make('code', '', row.usage), make('span', '', row.text));
            part.append(line);
          }
          result.append(part);
        }
      } else if (record.kind === 'confirm') {
        result.append(drawConfirm(record));
      } else if (record.kind === 'control') {
        runControl(record, result);
      } else if (record.text) {
        result.append(make('p', 'gbt-tone-info', record.text));
      }
      for (const note of record.notes || []) result.append(make('p', 'gbt-notice-line', note));
      if (record.kind !== 'control') words.push(...recordLines(record));
    }
    // Lines that arrive with nothing typed: the banner, what a broken bridge says
    function addLines(records) {
      eventBlock = null;
      const node = make('section', 'gbt-entry');
      const block = {node, words: []};
      for (const record of records) drawRecord(record, node, block.words);
      addBlock(block);
      afterAdding();
    }
    function bridgeMessage(reply) {
      if (reply.outcome === 'bridge') return {kind: 'error', code: 'failed', text: `Can't reach the local helper's bridge: ${reply.error || 'no answer'}. Run Install Chrome extension.bat in the installed GlobalBank Helper folder.`};
      if (reply.outcome === 'timeout' && !(reply.records || []).length) return {kind: 'message', tone: 'warn', text: reply.maybeApplied ? 'The helper didn’t answer in time. The command may still have run, so it wasn’t sent again.' : 'The helper didn’t answer in time.'};
      return null;
    }
    function drawEvents(events) {
      for (const event of events) {
        // What this page itself just did is already on the page. The helper's own window shows it.
        if (event.origin === 'browser') continue;
        // Updates in a row read as one block, under what you last ran
        if (!eventBlock || eventBlock.lines >= MAX_LINES_IN_A_BLOCK) {
          eventBlock = {node: make('section', 'gbt-entry'), words: [], lines: 0};
          addBlock(eventBlock);
        }
        const line = make('div', 'gbt-log-line');
        const time = make('time', '', clock(event.time));
        time.dateTime = String(event.time || '');
        line.append(time, make('span', `gbt-event-text${event.tone ? ` gbt-tone-${event.tone}` : ''}`, event.text));
        eventBlock.node.append(line);
        eventBlock.lines++;
        eventBlock.words.push(`${clock(event.time)} ${event.text}`);
      }
      if (events.length) afterAdding();
    }

    // ---- The header
    const STATE_WORDS = {loading: 'Running · loading saved characters…', watching: 'Running · watching', stopped: 'Stopped · saved data only', unknown: 'Running · state unknown'};
    function setPromptState() {
      const state = byId('term-state');
      const name = busy ? 'busy' : pending ? 'confirm' : helper && helper.state === 'stopped' ? 'stopped' : 'ready';
      state.dataset.state = name;
      state.textContent = {busy: 'WORKING…', confirm: 'CONFIRM', stopped: 'SAVED DATA', ready: 'READY'}[name];
      byId('term-run').disabled = busy;
      input.placeholder = pending?.record.prompt || idlePlaceholder;
      if (busy) byId('term-run').setAttribute('aria-busy', 'true');
      else byId('term-run').removeAttribute('aria-busy');
    }
    function showHelper(state) {
      if (state && (state.running !== helper?.running || state.stopping !== helper?.stopping) && helper) options.onHelper?.();
      if (state) helper = state;
      const box = byId('term-helper');
      const name = bridgeDown ? 'unknown' : helper?.stopping ? 'loading' : helper?.state || 'unknown';
      box.dataset.state = name;
      let words = STATE_WORDS[name] || STATE_WORDS.unknown;
      if (bridgeDown) words = 'Bridge not answering';
      else if (helper?.stopping) words = 'Stopping…';
      else if (helper?.running && helper.bridged === false) words = 'Running an older version: restart it';
      else if (name === 'watching' && helper?.uptimeSeconds !== undefined && helper?.uptimeSeconds !== null && typeof GBBank !== 'undefined') words += ` · ${GBBank.formatDuration(helper.uptimeSeconds)}`;
      byId('term-helper-text').textContent = words;
      // While loading, and when stopped, the helper doesn't know these. Not knowing isn't zero.
      const saved = options.savedTotals ? options.savedTotals() : null;
      const characters = helper?.characters ?? (name === 'loading' ? null : saved?.characters ?? null);
      const gold = helper?.gold ?? (name === 'loading' ? null : saved?.gold ?? null);
      byId('term-characters').textContent = characters === null ? '—' : number(characters);
      const goldNode = byId('term-gold');
      goldNode.textContent = gold === null ? '—' : typeof GBBank !== 'undefined' ? GBBank.formatCompact(gold) : number(gold);
      goldNode.title = gold === null ? '' : `${number(gold)} gold`;
      byId('term-snapshot').textContent = helper?.snapshot ? `Saved snapshot ${new Date(helper.snapshot).toLocaleString(undefined, {dateStyle: 'medium', timeStyle: 'short'})}` : 'No saved snapshot yet';
      byId('term-scan').textContent = helper?.lastScan ? `Last scan ${clock(helper.lastScan)}` : '';
      const stopped = !bridgeDown && helper?.state === 'stopped' && !helper.stopping;
      byId('term-stopped').hidden = !stopped;
      if (stopped) byId('term-stopped-text').textContent = 'The helper isn’t running. Commands read your saved data until you start it.';
      setPromptState();
    }

    // ---- Commands
    async function run(echo, message) {
      if (busy) return null;
      closeList();
      busy = true;
      setPromptState();
      eventBlock = null;
      const node = make('section', 'gbt-entry');
      const prompt = make('div', 'gbt-command-echo');
      prompt.append(make('span', 'gbt-cmd-prefix', 'gb >'), make('span', '', echo));
      const result = make('div', 'gbt-result');
      node.append(prompt, result);
      const block = {node, words: [`gb > ${echo}`]};
      addBlock(block);
      afterAdding();
      const reply = await ask(message(newRequestId()));
      busy = false;
      bridgeDown = reply.outcome === 'bridge';
      closePending();
      const extra = bridgeMessage(reply);
      for (const record of [...(extra ? [extra] : []), ...(reply.records || [])]) drawRecord(record, result, block.words);
      if (reply.helper) showHelper(reply.helper);
      else showHelper();
      afterAdding();
      if (reply.changed) {
        catalogueAsked = null;
        options.onChanged?.();
      }
      updateList();
      return reply;
    }
    function remember(text) {
      if (history[history.length - 1] !== text) history.push(text);
      if (history.length > MAX_HISTORY) history.shift();
      historyAt = history.length;
      draft = '';
    }
    byId('term-form').addEventListener('submit', event => {
      event.preventDefault();
      // A draft typed while a command runs stays as it is until that one is done
      if (busy) return;
      const text = input.value.trim();
      if (!text) return;
      input.value = '';
      if (pending) {
        answerConfirm(text, text);
        return;
      }
      remember(text);
      run(text, requestId => ({type: 'terminal-command', requestId, command: text}));
    });

    // ---- Completion: prefix matches on what the catalogue lists, the same catalogue the helper's window uses
    function closeList() {
      list.hidden = true;
      input.setAttribute('aria-expanded', 'false');
      input.removeAttribute('aria-activedescendant');
      suggestions = [];
      cycleAt = -1;
    }
    function suggest() {
      if (!catalogue || pending || !input.value.trim()) return [];
      let prefix = '', rest = input.value;
      for (const start of catalogue.prefixes || []) {
        if (rest.toLowerCase().startsWith(start.toLowerCase())) {
          prefix += rest.slice(0, start.length);
          rest = rest.slice(start.length);
        }
      }
      const lower = rest.toLowerCase();
      const found = [];
      for (const command of catalogue.commands || []) {
        if (!command.arg) continue;
        const stems = [command.complete, ...(command.aliases || []).map(alias => `${alias} `)].filter(stem => stem.endsWith(' '));
        const stem = stems.find(item => lower.startsWith(item.toLowerCase()));
        if (!stem) continue;
        const typed = lower.slice(stem.length);
        const names = (command.arg === 'excluded' ? catalogue.excluded : catalogue.characters) || [];
        for (const name of names) {
          if (name.toLowerCase().startsWith(typed) && name.toLowerCase() !== typed) found.push({value: prefix + rest.slice(0, stem.length) + name, label: stem + name, text: ''});
        }
        break;
      }
      for (const command of catalogue.commands || []) {
        for (const value of [command.complete, ...(command.more || [])]) {
          if (typeof value === 'string' && value.toLowerCase().startsWith(lower) && value.toLowerCase() !== lower) found.push({value: prefix + value, label: value.trim(), text: command.text || ''});
        }
      }
      return found;
    }
    function drawList() {
      list.replaceChildren(...suggestions.map((item, index) => {
        const choice = make('button', 'gbt-completion');
        choice.type = 'button';
        choice.id = `term-completion-${index}`;
        choice.setAttribute('role', 'option');
        choice.setAttribute('aria-selected', String(index === cycleAt));
        choice.tabIndex = -1;
        choice.append(make('span', '', item.label), make('small', '', item.text));
        choice.addEventListener('mousedown', event => event.preventDefault());
        choice.addEventListener('click', () => {
          input.value = item.value;
          input.focus({preventScroll: true});
          input.setSelectionRange(input.value.length, input.value.length);
          listDismissed = false;
          updateList();
        });
        return choice;
      }));
      list.hidden = !suggestions.length;
      input.setAttribute('aria-expanded', String(!!suggestions.length));
      if (cycleAt >= 0) {
        input.setAttribute('aria-activedescendant', `term-completion-${cycleAt}`);
        list.children[cycleAt]?.scrollIntoView({block: 'nearest'});
      } else input.removeAttribute('aria-activedescendant');
    }
    function updateList() {
      cycleAt = -1;
      suggestions = listDismissed ? [] : suggest();
      drawList();
    }
    input.addEventListener('input', () => {
      historyAt = history.length;
      draft = input.value;
      listDismissed = false;
      updateList();
    });
    input.addEventListener('blur', () => { list.hidden = true; input.setAttribute('aria-expanded', 'false'); });
    input.addEventListener('focus', () => { if (suggestions.length) { list.hidden = false; input.setAttribute('aria-expanded', 'true'); } });
    input.addEventListener('keydown', event => {
      if (event.isComposing) return;
      if (event.key === 'Tab') {
        const atEnd = input.selectionStart === input.value.length && input.selectionEnd === input.value.length;
        if (!atEnd || !suggestions.length) return;
        event.preventDefault();
        const count = suggestions.length;
        // One match fills in and offers what can come next. Several fill in the first and stay open for Tab to go on.
        if (count === 1) {
          input.value = suggestions[0].value;
          input.setSelectionRange(input.value.length, input.value.length);
          updateList();
          return;
        }
        cycleAt = cycleAt < 0 ? (event.shiftKey ? count - 1 : 0) : (cycleAt + (event.shiftKey ? -1 : 1) + count) % count;
        input.value = suggestions[cycleAt].value;
        input.setSelectionRange(input.value.length, input.value.length);
        drawList();
      } else if (event.key === 'ArrowUp') {
        if (!history.length) return;
        event.preventDefault();
        if (historyAt === history.length) draft = input.value;
        historyAt = Math.max(0, historyAt - 1);
        input.value = history[historyAt];
        input.setSelectionRange(input.value.length, input.value.length);
        closeList();
      } else if (event.key === 'ArrowDown') {
        if (historyAt === history.length) return;
        event.preventDefault();
        historyAt = Math.min(history.length, historyAt + 1);
        input.value = historyAt === history.length ? draft : history[historyAt];
        input.setSelectionRange(input.value.length, input.value.length);
        closeList();
      } else if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        if (suggestions.length) {
          listDismissed = true;
          closeList();
        } else {
          input.value = '';
          draft = '';
          historyAt = history.length;
        }
      }
    });

    // ---- The toolbar. The same things clear, copy and follow do when typed.
    async function copyOutput() {
      const text = blocks.flatMap(block => block.words).join('\n');
      try {
        await navigator.clipboard.writeText(text);
        return true;
      } catch {
        // A typed copy comes back from the helper too late for the clipboard call: the older way still works then
        const box = make('textarea');
        box.value = text;
        box.style.position = 'fixed';
        box.style.opacity = '0';
        document.body.append(box);
        box.select();
        const done = document.execCommand('copy');
        box.remove();
        input.focus({preventScroll: true});
        return done;
      }
    }
    function clearView() {
      const waiting = pending;
      for (const block of blocks.splice(0)) block.node.remove();
      eventBlock = null;
      unread = 0;
      follow = true;
      manualPause = false;
      showFollow();
      // A question still waiting stays where it can be answered
      if (waiting) {
        const node = make('section', 'gbt-entry');
        node.append(waiting.node);
        addBlock({node, words: recordLines(waiting.record)});
      }
    }
    byId('term-follow').addEventListener('click', () => setFollow(!follow));
    byId('term-clear').addEventListener('click', clearView);
    byId('term-copy').addEventListener('click', async () => {
      const done = await copyOutput();
      options.toast?.(done ? 'Copied the output.' : 'Could not reach the clipboard. Select the text and copy it instead.');
    });
    byId('term-start').addEventListener('click', () => options.startHelper?.());

    // ---- Keeping up with the helper
    function getCatalogue(force) {
      if (force || !catalogueAsked) {
        catalogueAsked = ask({type: 'terminal-catalogue'}).then(reply => {
          if (reply.ok) catalogue = reply;
          return reply;
        });
      }
      return catalogueAsked;
    }
    async function poll() {
      clearTimeout(timer);
      if (!(shown || watching) || document.hidden || polling) return;
      polling = true;
      let again = POLL_MS;
      const reply = await ask({type: 'terminal-feed', session, after: seq, max: FEED_SIZE});
      polling = false;
      if (!(shown || watching)) return;
      if (reply.ok) {
        bridgeDown = false;
        if (reply.session !== session) seq = 0;
        session = reply.session;
        seq = reply.seq ?? seq;
        if (reply.gap) {
          const lost = Number(reply.gap.to) - Number(reply.gap.from) + 1;
          drawEvents([{time: new Date().toISOString(), tone: 'warn', text: `${number(Math.max(lost, 1))} older updates were discarded.`}]);
        }
        drawEvents(reply.events || []);
        if ((reply.events || []).some(event => event.dataChanged)) {
          catalogueAsked = null;
          options.onChanged?.();
        }
        if (reply.more) again = 0;
      } else {
        again = POLL_FAILED_MS;
        if (!bridgeDown) {
          bridgeDown = true;
          const message = bridgeMessage(reply) || {kind: 'error', code: 'failed', text: reply.error || 'No answer from the local helper.'};
          addLines([message]);
        }
      }
      showHelper(reply.helper);
      if (!catalogueAsked) getCatalogue();
      if ((shown || watching) && !document.hidden) timer = setTimeout(poll, shown ? again : Math.max(again, WATCH_MS));
    }
    async function open() {
      if (opened) return;
      opened = true;
      const reply = await getCatalogue();
      if (reply.ok && Array.isArray(reply.banner) && reply.banner.length) addLines(reply.banner);
    }
    document.addEventListener('visibilitychange', () => { if ((shown || watching) && !document.hidden) poll(); });
    showFollow();
    setPromptState();

    return {
      // The page was opened or left: the extra polling only runs while you're looking at it
      visible(on) {
        shown = on;
        if (!on) {
          clearTimeout(timer);
          if (watching && !document.hidden) timer = setTimeout(poll, WATCH_MS);
          return;
        }
        open().finally(poll);
        input.focus({preventScroll: true});
        if (follow) output.scrollTop = output.scrollHeight;
      },
      // The rest of the page wants to hear about new saves while it is open, on any tab
      watch(on) {
        watching = !!on;
        if (watching && !shown) poll();
        else if (!watching && !shown) clearTimeout(timer);
      },
      // For the rest of the page: one command, its answer, and nothing drawn here
      command: command => ask({type: 'terminal-command', requestId: newRequestId(), command}),
      confirm: (token, answer) => ask({type: 'terminal-confirm', requestId: newRequestId(), token, answer}),
      catalogue: getCatalogue,
    };
  }
  return {create, recordLines, recordsText};
})();
