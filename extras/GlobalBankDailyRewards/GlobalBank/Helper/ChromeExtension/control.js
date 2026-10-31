'use strict';
(() => {
  const byId = id => document.getElementById(id);
  const status = byId('helper-status');
  const start = byId('start-helper');
  let starting = false;
  async function send(message) {
    const response = await chrome.runtime.sendMessage(message);
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    return response;
  }
  async function checkHelper() {
    try {
      const response = await send({type:'helper-status'});
      status.textContent = response.running ? 'Helper is running.' : 'Helper is not running.';
      start.disabled = !!response.running || starting;
      return !!response.running;
    } catch (error) {
      status.textContent = 'Cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error);
      start.disabled = true;
      return false;
    }
  }
  byId('check-helper').addEventListener('click', checkHelper);
  start.addEventListener('click', async event => {
    if (!event.isTrusted || starting) return;
    starting = true;
    start.disabled = true;
    status.textContent = 'Starting the helper…';
    let running = false;
    try {
      await send({type:'helper-start'});
      for (let i = 0; i < 10 && !running; i++) {
        if (i) await new Promise(resolve => setTimeout(resolve, 500));
        running = await checkHelper();
      }
      if (!running) status.textContent = 'The helper did not report ready. Check its window, then try again.';
    } catch (error) {
      status.textContent = 'Could not start the helper: ' + String(error.message || error);
    } finally {
      starting = false;
      start.disabled = running;
    }
  });
  // Tabs
  function showTab(name) {
    document.querySelectorAll('[data-tab]').forEach(tab => tab.setAttribute('aria-selected', String(tab.dataset.tab === name)));
    document.querySelectorAll('.tab-panel').forEach(panel => { panel.hidden = panel.id !== 'tab-' + name; });
  }
  document.querySelectorAll('[data-tab]').forEach(tab => tab.addEventListener('click', () => showTab(tab.dataset.tab)));

  // The Bank tab
  const bankStatus = text => { byId('bank-status').textContent = text; };
  const accounts = GBAccounts.create(send);
  // The local host if there is one, otherwise the folders the player chose
  let usingFolders = false;
  async function bankSend(message) {
    try {
      const response = await send(message);
      usingFolders = false;
      return response;
    } catch (error) {
      if (!await GBFolders.usable('saves')) throw error;
      usingFolders = true;
      return GBFolders.answer(message);
    }
  }
  const bank = GBBank.create(byId('tab-bank'), bankSend, bankStatus, (totals, made, characters) => {
    GBBank.renderCurrencies(byId('currency-view'), characters);
    GBBank.renderRoster(byId('roster-view'), characters);
    GBBank.renderStats(byId('tab-stats'), characters);
    accounts.setCharacters(characters);
    const number = value => value.toLocaleString('en-US');
    byId('status-data').textContent = `${number(totals.characters)} characters · ${number(totals.items)} items in ${number(totals.stacks)} stacks`
      + (made ? ` · data from ${made}` : ' · no data saved yet');
  }, accounts.openMenu);
  // The Item Depot tab
  let depot = null;
  function renderDepot() {
    const text = byId('depot-search').value.trim().toLowerCase();
    const items = (depot?.items || []).filter(item => !text || item.name.toLowerCase().includes(text));
    byId('depot-grid').replaceChildren(...items.map(item => {
      const slot = document.createElement('div');
      slot.className = 'bank-slot filled';
      slot.title = item.count > 1 ? `${item.name} × ${item.count.toLocaleString('en-US')}` : item.name;
      const letters = document.createElement('span');
      letters.className = 'bank-letters';
      letters.textContent = item.name.slice(0, 2);
      slot.append(letters);
      if (item.picture) {
        const picture = document.createElement('img');
        picture.alt = '';
        picture.referrerPolicy = 'no-referrer';
        picture.src = item.picture;
        slot.append(picture);
      }
      if (item.count > 1) {
        const count = document.createElement('span');
        count.className = 'bank-count';
        count.textContent = item.count > 9999 ? `${Math.floor(item.count / 1000)}k` : String(item.count);
        slot.append(count);
      }
      return slot;
    }));
    byId('depot-status').textContent = depot
      ? `${depot.items.length.toLocaleString('en-US')} items${depot.server ? ` on ${depot.server}` : ''}, read ${new Date(depot.read).toLocaleString()}.`
      : 'Nothing read yet.';
  }
  byId('depot-search').addEventListener('input', renderDepot);
  byId('depot-copy').addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(depot?.outline || '');
      byId('depot-status').textContent = depot?.outline ? 'Copied the page layout: tag and class names only, with no names, items or links.' : 'Open your item depot page first.';
    } catch (error) {
      byId('depot-status').textContent = 'Could not copy: ' + String(error.message || error);
    }
  });
  chrome.storage.local.get('depot').then(result => { depot = result.depot || null; renderDepot(); }).catch(() => {});
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== 'local') return;
    if (changes.depot) { depot = changes.depot.newValue || null; renderDepot(); }
    if (changes.autoHelper) { autoHelper.checked = !!changes.autoHelper.newValue; refreshStatus(); }
    if (changes.showTerminal) { showTerminal.checked = !!changes.showTerminal.newValue; refreshStatus(); }
  });
  // The status line and the toggle
  const statusHelper = byId('status-helper');
  const autoHelper = byId('auto-helper');
  async function refreshStatus() {
    try {
      const info = await send({type:'helper-info'});
      if (!info.running) {
        statusHelper.textContent = 'Helper: not running.';
      } else {
        const ran = info.since ? ` for ${GBBank.formatDuration((Date.now() - Date.parse(info.since)) / 1000)}` : '';
        const how = info.auto ? (info.hidden === false ? 'started automatically with its window' : 'started automatically') : 'in its own window';
        statusHelper.textContent = `Helper: running${ran}, ${how}.`;
      }
    } catch (error) {
      statusHelper.textContent = await GBFolders.usable('saves').catch(() => null)
        ? 'Helper: not installed on this PC. The Bank tab is reading your chosen folders.'
        : 'Helper: cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder, or choose your folders below.';
    }
  }
  const showTerminal = byId('show-terminal');
  chrome.storage.local.get('autoHelper').then(({autoHelper: on}) => { autoHelper.checked = !!on; });
  chrome.storage.local.get('showTerminal').then(({showTerminal: on}) => { showTerminal.checked = !!on; });
  autoHelper.addEventListener('change', async () => {
    const on = autoHelper.checked;
    autoHelper.disabled = true;
    statusHelper.textContent = on ? 'Helper: starting.' : 'Helper: stopping.';
    try {
      await chrome.storage.local.set({autoHelper: on});
      await send({type: on ? 'helper-auto-start' : 'helper-auto-stop', showWindow: showTerminal.checked});
      // A helper takes a moment to start
      if (on) await new Promise(resolve => setTimeout(resolve, 3000));
    } catch (error) {
      bankStatus('The helper could not be changed: ' + String(error.message || error));
    } finally {
      autoHelper.disabled = false;
      refreshStatus();
    }
  });
  showTerminal.addEventListener('change', async () => {
    const on = showTerminal.checked;
    showTerminal.disabled = true;
    statusHelper.textContent = on ? 'Helper: showing its window.' : 'Helper: hiding its window.';
    try {
      await chrome.storage.local.set({showTerminal: on});
      // A running automatic helper keeps the look it started with; restart it with the new one.
      if (autoHelper.checked) {
        await send({type:'helper-auto-stop'});
        await send({type:'helper-auto-start', showWindow: on});
        await new Promise(resolve => setTimeout(resolve, 3000));
      }
    } catch (error) {
      bankStatus('The terminal setting could not be applied: ' + String(error.message || error));
    } finally {
      showTerminal.disabled = false;
      refreshStatus();
    }
  });
  refreshStatus();
  setInterval(refreshStatus, 30000);
  // The folders
  const foldersStatus = byId('folders-status');
  const allow = byId('folders-allow');
  const tryReload = () => bank.reload().then(() => bankStatus(''), error => {
    byId('folders').open = true;
    bankStatus('Cannot read your saved data. Choose your folders above, or run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error));
  });
  async function showFolders() {
    const state = await GBFolders.state();
    for (const kind of ['saves', 'game']) {
      if (state[kind]) byId(kind + '-status').textContent = `Using ${state[kind].name}.`;
    }
    const needsClick = Object.values(state).some(folder => folder && folder.access !== 'granted');
    allow.hidden = !needsClick;
    if (needsClick) {
      byId('folders').open = true;
      foldersStatus.textContent = 'Chrome needs your OK to read these folders again.';
    } else foldersStatus.textContent = '';
  }
  for (const kind of ['saves', 'game']) {
    byId('choose-' + kind).addEventListener('click', async () => {
      try {
        if (await GBFolders.choose(kind) === null) return;
      } catch (error) {
        foldersStatus.textContent = String(error.message || error);
        return;
      }
      await showFolders();
      await tryReload();
      refreshStatus();
    });
  }
  allow.addEventListener('click', async () => {
    await GBFolders.allowAgain().catch(error => { foldersStatus.textContent = String(error.message || error); });
    await showFolders();
    await tryReload();
    refreshStatus();
  });
  showFolders().catch(() => {});
  tryReload();
  document.addEventListener('visibilitychange', () => { if (!document.hidden) bank.reload().catch(() => {}); });

  // The Terminal tab: the helper's own commands, run one at a time without its window
  const terminal = byId('bank-output');
  const history = [];
  let historyAt = 0;
  function printLine(text) {
    terminal.textContent += text + '\n';
    terminal.scrollTop = terminal.scrollHeight;
  }
  byId('bank-form').addEventListener('submit', async event => {
    event.preventDefault();
    const box = byId('bank-command');
    const command = box.value.trim();
    if (!command) return;
    box.value = '';
    history.push(command);
    historyAt = history.length;
    printLine('> ' + command);
    if (/^\/?(exit|quit|stop)$/i.test(command)) { printLine('Nothing to stop: each command here runs on its own.'); return; }
    if (/^\/?heartbeat\b/i.test(command)) { printLine('The heartbeat only shows in the helper window.'); return; }
    const button = event.currentTarget.querySelector('button[type="submit"]');
    button.disabled = true;
    try {
      const response = await send({type:'bank-command',command});
      printLine(String(response.output || '').trimEnd() || 'Done.');
      bank.reload().catch(() => {});
    } catch (error) {
      printLine('Could not run that: ' + String(error.message || error));
    } finally { button.disabled = false; box.focus(); }
  });
  byId('bank-command').addEventListener('keydown', event => {
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return;
    event.preventDefault();
    historyAt = Math.max(0, Math.min(history.length, historyAt + (event.key === 'ArrowUp' ? -1 : 1)));
    event.currentTarget.value = history[historyAt] || '';
  });
  const stats = {
    str:'Strength', dex:'Dexterity', sta:'Stamina', int:'Intelligence', wis:'Wisdom',
    patt:'Physical attack', matt:'Magical attack', pdam:'Physical damage', mdam:'Magical damage',
    pdef:'Physical defense', mdef:'Magical defense', hp:'Health', mp:'Mana',
    pcrit:'Physical critical', mcrit:'Magical critical', pacc:'Physical accuracy',
    macc:'Magical accuracy', pdod:'Dodge', parry:'Parry', heal:'Healing'
  };
  const statSelect = byId('auction-stat');
  Object.entries(stats).forEach(([value, label]) => {
    const option = document.createElement('option');
    option.value = value; option.textContent = label; statSelect.appendChild(option);
  });
  const output = byId('auction-output');
  const table = byId('auction-table');
  const rows = byId('auction-rows');
  const prev = byId('auction-prev');
  const next = byId('auction-next');
  let query = null, total = 0, pageSize = 50, loading = false;
  const display = value => value === null || value === undefined || value === '' ? '—' : String(value);
  function readQuery() {
    return {type:'auction-query', search:byId('auction-search').value.trim(), realm:byId('auction-realm').value.trim(),
      pageOptions:{sort:byId('auction-sort').value, order:byId('auction-order').value,
        stat:statSelect.value, minimum:byId('auction-min').value, maximum:byId('auction-max').value, offset:0}};
  }
  async function showPage() {
    if (loading || !query) return;
    loading = true; prev.disabled = next.disabled = true;
    output.textContent = 'Reading local auction cache…';
    try {
      const response = await send(query);
      const page = response.page;
      if (!page || !Array.isArray(page.rows)) throw new Error('Unexpected auction cache response. Restart the helper and try again.');
      total = Number(page.total) || 0; pageSize = Number(page.pageSize) || 50;
      rows.replaceChildren();
      for (const item of page.rows) {
        const tr = document.createElement('tr');
        const name = display(item.name) + (item.itemid ? ' (ID ' + item.itemid + ')' : '') + (item.count > 1 ? ' ×' + item.count : '');
        const details = [item.statNames, item.stats].filter(Boolean).join(' — ');
        const date = item.end ? new Date(item.end) : null;
        const end = date && !Number.isNaN(date.getTime()) ? date.toLocaleString() : '—';
        const price = item.price === null || item.price === undefined ? '—' : Number(item.price).toLocaleString() + (item.currency ? ' ' + item.currency : '');
        for (const value of [name, item.realm, item.level, item.tier, item.dura, details, end, item.seller, price]) {
          const td = document.createElement('td'); td.textContent = display(value); tr.appendChild(td);
        }
        rows.appendChild(tr);
      }
      table.hidden = !page.rows.length;
      output.textContent = total ? 'Showing ' + (page.offset + 1) + '–' + (page.offset + page.rows.length) + ' of ' + total + ' cached auctions.' : 'No matching cached auctions. Search in game to collect auction data.';
      prev.disabled = page.offset <= 0;
      next.disabled = page.offset + page.rows.length >= total;
    } catch (error) {
      table.hidden = true; rows.replaceChildren();
      output.textContent = 'Could not read auction data: ' + String(error.message || error);
    } finally { loading = false; }
  }
  byId('auction-form').addEventListener('submit', event => {
    event.preventDefault(); if (loading) return;
    query = readQuery(); showPage();
  });
  byId('auction-all').addEventListener('click', () => {
    if (loading) return;
    for (const id of ['auction-search','auction-realm','auction-stat','auction-min','auction-max']) byId(id).value = '';
    if (byId('auction-sort').value === 'stat') byId('auction-sort').value = 'name';
    query = readQuery(); showPage();
  });
  prev.addEventListener('click', () => { if (query && !loading) { query.pageOptions.offset = Math.max(0, query.pageOptions.offset - pageSize); showPage(); } });
  next.addEventListener('click', () => { if (query && !loading && query.pageOptions.offset + pageSize < total) { query.pageOptions.offset += pageSize; showPage(); } });
  checkHelper();
})();
