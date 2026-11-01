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
  // Tabs. Only the open one is drawn; one whose data changed while hidden is drawn when you open it.
  let currentTab = 'bank';
  // The Servers tab shows the regions' lists even before any data comes in
  const dirty = new Set(['servers']);
  const views = {};
  // These keep track of their own changes, and are cheap to ask
  const selfTracking = new Set(['bank', 'favourites', 'accounts', 'heatmap']);
  function showTab(name) {
    currentTab = name;
    document.querySelectorAll('[data-tab]').forEach(tab => tab.setAttribute('aria-selected', String(tab.dataset.tab === name)));
    document.querySelectorAll('.tab-panel').forEach(panel => { panel.hidden = panel.id !== 'tab-' + name; });
    byId('bank-tooltip').hidden = true;
    byId('char-tooltip').hidden = true;
    drawOpenTab();
  }
  function drawOpenTab() {
    if ((dirty.has(currentTab) || selfTracking.has(currentTab)) && views[currentTab]) {
      dirty.delete(currentTab);
      views[currentTab]();
    }
    markSelected();
  }
  function changed(names) {
    for (const name of names) dirty.add(name);
    drawOpenTab();
  }
  document.querySelectorAll('[data-tab]').forEach(tab => tab.addEventListener('click', () => showTab(tab.dataset.tab)));

  // Who is who on every tab: the region, the server ticks, and one selection a click on any character changes
  const number = value => Number(value || 0).toLocaleString('en-US');
  const escapeHtml = GBRoster.escapeHtml;
  const roster = GBRoster.create(chrome.storage.local);
  const accounts = GBAccounts.create(send, {
    shows: character => roster.shows(character),
    visible: tab => currentTab === tab,
    isSelected: key => roster.isSelected(key),
    selectKeys: keys => selectKeys(keys),
    addKeys: keys => roster.setSelection([...roster.selection, ...keys]),
    clearSelection: () => roster.clearSelection(),
    listed: () => roster.listed(),
    romTitle: character => roster.romTitle(character),
    romName: character => roster.romName(character),
    romFirst: () => roster.view.romFirst,
    linksChanged: () => changed(['currencies', 'characters', 'servers']),
  });
  // A group's Select button selects all of it, or, when all of it is selected already, none of it
  function selectKeys(keys) {
    const group = new Set(keys);
    const all = keys.length > 0 && keys.every(key => roster.isSelected(key));
    roster.setSelection(all ? [...roster.selection].filter(key => !group.has(key)) : [...roster.selection, ...keys]);
  }
  // A selection only changes colours: the open tab's characters are marked, and the rest when they're opened.
  function markSelected() {
    byId('tab-' + currentTab)?.querySelectorAll('[data-char]').forEach(node => node.classList.toggle('is-selected', roster.isSelected(node.dataset.char)));
  }
  const REGION_NAMES = {eu: 'Europe', na: 'North America', '': 'Other servers', unknown: 'Not known yet'};
  function renderViewBar() {
    const region = roster.view.region || 'eu';
    byId('view-region').value = region;
    const all = region === 'all';
    const order = {eu: 0, na: 1, '': 2};
    let servers = roster.servers();
    if (all) servers = servers.slice().sort((a, b) => Number(!a.key) - Number(!b.key) || order[a.region] - order[b.region]);
    const parts = [];
    let heading = null;
    for (const server of servers) {
      const region = server.key ? server.region : 'unknown';
      if (all && region !== heading) {
        heading = region;
        parts.push(`<span class="region-name">${escapeHtml(REGION_NAMES[region] || REGION_NAMES[''])}</span>`);
      }
      const title = server.count ? `${number(server.count)} characters · ${number(server.gold)} gold` + (server.stale ? ` · ${number(server.stale)} need a login on the current version` : '')
        : 'Nobody saved on this server yet';
      parts.push(`<label class="server-check${server.count ? '' : ' is-empty'}${server.on ? '' : ' is-off'}" title="${escapeHtml(title)}"><input type="checkbox" data-server="${escapeHtml(server.key)}"${server.on ? ' checked' : ''}> ${escapeHtml(server.name)} <span class="hint">${number(server.count)}</span></label>`);
    }
    byId('view-servers').innerHTML = parts.join('');
    const lists = roster.lists();
    byId('region-known').innerHTML = Object.entries(GBRoster.REGIONS).map(([id, item]) => `<p><b>${escapeHtml(item.name)}</b>: ${escapeHtml(lists[id].join(', ') || 'no servers')}</p>`).join('');
    const unlisted = roster.serverTable().filter(server => !server.region && server.count).map(server => server.name);
    byId('region-unlisted').textContent = !unlisted.length ? 'Every server your characters are on is in a region.'
      : `No region lists ${unlisted.join(', ')}, so ${unlisted.length === 1 ? 'it shows' : 'they show'} in every region.`;
  }
  // The page's own settings, once they're read
  function renderSettings() {
    byId('card-hide-gameforge').checked = !!roster.view.hideGameforge;
    byId('card-hide-rom').checked = !!roster.view.hideRom;
    byId('gf-first').value = roster.view.romFirst ? 'rom' : 'name';
  }
  function renderSelectionBar() {
    const {shown, hidden} = roster.counts();
    byId('selection-count').textContent = !(shown + hidden) ? 'No characters selected'
      : `${number(shown + hidden)} selected` + (hidden ? ` (${number(hidden)} on servers not shown)` : '');
    byId('selection-copy').disabled = !shown;
    byId('selection-clear').disabled = !roster.selection.size;
    byId('selection-only').checked = roster.view.onlySelected !== false;
    const stale = roster.shown().filter(character => character.stale).length;
    const button = byId('select-stale');
    button.hidden = !stale;
    button.textContent = stale === 1 ? 'Select the one that needs a login' : `Select the ${number(stale)} that need a login`;
    button.title = 'Saved by an older version: each needs one login and logout on the current version for its server, currencies and item stats.';
  }
  byId('view-region').addEventListener('change', event => roster.setRegion(event.target.value));
  byId('view-servers').addEventListener('change', event => {
    const box = event.target.closest('[data-server]');
    if (box) roster.setServer(box.dataset.server, box.checked);
  });
  byId('region-edit').addEventListener('click', () => {
    byId('region-settings').open = false;
    showTab('servers');
  });
  byId('card-hide-gameforge').addEventListener('change', event => roster.setCard('gameforge', event.target.checked));
  byId('card-hide-rom').addEventListener('change', event => roster.setCard('rom', event.target.checked));
  byId('gf-first').addEventListener('change', event => roster.setRomFirst(event.target.value === 'rom'));
  byId('selection-only').addEventListener('change', event => roster.setOnlySelected(event.target.checked));
  byId('selection-clear').addEventListener('click', () => roster.clearSelection());
  byId('select-stale').addEventListener('click', () => roster.setSelection(roster.shown().filter(character => character.stale).map(character => character.key)));
  byId('selection-copy').addEventListener('click', async () => {
    const names = roster.selectedAll().map(character => character.name);
    try {
      await navigator.clipboard.writeText(names.join('\n'));
      byId('selection-note').textContent = `Copied ${number(names.length)} names, one a line.`;
    } catch (error) {
      byId('selection-note').textContent = 'Could not copy: ' + String(error.message || error);
    }
  });

  // The Bank tab
  const bankStatus = text => { byId('bank-status').textContent = text; };
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
    accounts.setCharacters(characters);
    renderViewBar();
    renderSelectionBar();
    changed(['favourites', 'currencies', 'stats', 'heatmap', 'characters', 'accounts', 'servers']);
    byId('status-data').textContent = `${number(totals.characters)} characters · ${number(totals.items)} items in ${number(totals.stacks)} stacks`
      + (made ? ` · data from ${made}` : ' · no data saved yet');
  }, accounts.openMenu, {
    roster,
    onlySelected: () => roster.onlySelected(),
    favouritesRoot: byId('tab-favourites'),
    openTab: showTab,
    visible: () => currentTab === 'bank',
    tooltip: byId('bank-tooltip'),
  });
  // Characters and Currencies: a search, and groups by server or account
  const tables = {characters: ['roster', 'roster-view'], currencies: ['currency', 'currency-view']};
  const tableOptions = prefix => ({
    how: byId(prefix + '-group').value,
    search: byId(prefix + '-search').value,
    isSelected: key => roster.isSelected(key),
    accountName: name => accounts.accountName(name),
    romTitle: character => roster.romTitle(character),
    selectKeys,
  });
  Object.assign(views, {
    bank: () => bank.show(),
    favourites: () => bank.renderFavourites(),
    currencies: () => GBBank.renderCurrencies(byId('currency-view'), roster.shown(), tableOptions('currency')),
    characters: () => GBBank.renderRoster(byId('roster-view'), roster.shown(), tableOptions('roster')),
    stats: () => GBBank.renderStats(byId('tab-stats'), roster.shown(), {data: {entries: bank.shownEntries()}}),
    heatmap: () => accounts.refresh('heatmap'),
    accounts: () => accounts.refresh('accounts'),
    servers: () => renderServers(),
  });
  for (const [tab, [prefix, view]] of Object.entries(tables)) {
    let typing = 0;
    byId(prefix + '-search').addEventListener('input', () => {
      clearTimeout(typing);
      typing = setTimeout(() => changed([tab]), 150);
    });
    byId(prefix + '-group').addEventListener('change', () => {
      // New groups start closed again when there are many rows
      byId(view).collapsed = new Set();
      byId(view).collapsedSet = false;
      changed([tab]);
    });
  }
  roster.onChange(what => {
    if (what === 'card') return;
    renderSelectionBar();
    if (what === 'view') {
      renderViewBar();
      accounts.redraw();
      changed(['favourites', 'currencies', 'stats', 'characters', 'servers']);
    } else if (what === 'assigned') {
      // A server set by hand moves characters, and so their keys: prepared again, the selection kept on them
      roster.rekey(() => bank.reprepare());
    } else if (what === 'names') {
      accounts.redraw();
      changed(['currencies', 'characters', 'servers']);
    } else if (what === 'order') {
      accounts.redraw();
    } else {
      markSelected();
      accounts.showSelected();
      if (currentTab === 'servers') renderServerPick();
    }
  });
  GBRoster.attach(roster, byId('char-tooltip'), {
    classColor: GBAccounts.classColor,
    account: character => accounts.accountNameOf(character),
    locked: () => accounts.locked(),
    rom: character => roster.romTitle(character),
    currencyName: GBBank.currencyName,
    menu: accounts.openMenu,
    rows: character => characterRows(character),
  });

  // A small form for one value: a new name, or a server from a list. Resolves to the text, to '' for its Clear
  // button, or to null when cancelled.
  const dialog = byId('edit-dialog');
  let answer = null, checker = null;
  function ask({title, hint = '', label, value = '', choices = null, clear = '', check = null, placeholder = ''}) {
    if (answer) answer(null);
    byId('edit-title').textContent = title;
    byId('edit-hint').textContent = hint;
    byId('edit-label').textContent = label;
    byId('edit-error').textContent = '';
    const input = byId('edit-value'), choice = byId('edit-choice');
    input.hidden = !!choices;
    choice.hidden = !choices;
    byId('edit-label').htmlFor = choices ? 'edit-choice' : 'edit-value';
    input.value = choices ? '' : value;
    input.placeholder = placeholder;
    choice.replaceChildren(...(choices || []).map(name => {
      const option = document.createElement('option');
      option.value = option.textContent = name;
      return option;
    }));
    if (choices) choice.value = choices.includes(value) ? value : choices[0] || '';
    byId('edit-clear').hidden = !clear;
    byId('edit-clear').textContent = clear;
    checker = check;
    dialog.showModal();
    if (choices) choice.focus();
    else input.select();
    return new Promise(resolve => {
      answer = result => {
        answer = checker = null;
        if (dialog.open) dialog.close();
        resolve(result);
      };
    });
  }
  byId('edit-form').addEventListener('submit', event => {
    event.preventDefault();
    if (!answer) return;
    const text = (byId('edit-choice').hidden ? byId('edit-value').value : byId('edit-choice').value).trim();
    const problem = checker ? checker(text) : '';
    if (problem) {
      byId('edit-error').textContent = problem;
      return;
    }
    answer(text);
  });
  byId('edit-cancel').addEventListener('click', () => { if (answer) answer(null); });
  byId('edit-clear').addEventListener('click', () => { if (answer) answer(''); });
  // Escape, or anything else that closes it
  dialog.addEventListener('close', () => { if (answer) answer(null); });

  // Right-click on a character, below its logins: its RoM account, its Gameforge account, and its server
  function characterRows(character) {
    const rows = [];
    const rom = roster.romAccount(character);
    if (rom) {
      const keys = rom.characters.map(member => member.key).filter(Boolean);
      if (keys.length > 1) rows.push({label: `Select its RoM account's ${number(keys.length)} characters`, run: () => roster.setSelection([...roster.selection, ...keys])});
      rows.push({label: 'Rename RoM account…', run: () => renameRom(character)});
    }
    const linked = accounts.linkedAccount(character);
    if (linked) rows.push({label: 'Rename Gameforge account…', run: () => renameGameforge(linked)});
    if (!character.shownServer || character.manualServer) {
      // Characters one login screen lists are on one server
      const list = rom ? rom.characters.filter(member => !member.shownServer || member.manualServer) : [character];
      rows.push({label: character.manualServer ? 'Change the server you set…' : 'Set server…', run: () => setServerFor(list)});
    }
    return rows;
  }
  async function renameRom(character) {
    const rom = roster.romAccount(character);
    if (!rom) return;
    const names = rom.group.names;
    const list = names.length > 6 ? `${names.slice(0, 6).join(', ')} and ${number(names.length - 6)} more` : names.join(', ');
    const text = await ask({
      title: 'Rename RoM account',
      hint: `The characters one login screen lists: ${list}. The name is only a label for this page. It's kept in this browser without encryption, so never type a password here.`,
      label: 'RoM account name', value: rom.name, placeholder: `${names[0]}'s account`,
      clear: rom.name ? 'Use the default name' : '',
      check: text => (text.length > 60 ? 'Keep it to 60 letters or fewer.' : ''),
    });
    if (text !== null) roster.setRomName(character, text);
  }
  async function renameGameforge(linked) {
    const text = await ask({
      title: 'Rename Gameforge account',
      hint: 'Copy Gameforge account name copies this name, so keep it the one you log in with. Its passwords and linked characters stay as they are.',
      label: 'Gameforge account name', value: linked.name, check: text => accounts.nameProblem(linked.id, text),
    });
    if (text === null || text === linked.name) return;
    if (!accounts.rename(linked.id, text)) changed(['currencies', 'characters', 'servers']);
  }
  // A server for characters nothing else places, until they log in once on the current version and save theirs
  async function setServerFor(list) {
    if (!list.length) return;
    const lists = roster.lists();
    const choices = [...new Set([...lists.eu, ...lists.na, ...roster.serverTable().filter(server => !server.region && server.count).map(server => server.name)])];
    const manual = list.find(character => character.manualServer);
    const one = list.length === 1;
    const text = await ask({
      title: 'Set server',
      hint: `${one ? list[0].name : `These ${number(list.length)} characters`} ${one ? 'is' : 'are'} shown on this server until ${one ? 'it logs' : 'they log'} in once on the current version, which saves the real one. A server missing here can be added at the top of the Servers tab.`,
      label: 'Server', choices, value: manual?.shownServer || '', clear: manual ? 'Forget the server I set' : '',
      check: text => (text ? '' : 'Pick a server.'),
    });
    if (text !== null) roster.setServerOf(list, text);
  }

  // The Servers tab: what each region lists, and every character by server and RoM account
  const REGION_IDS = ['eu', 'na', ''];
  const regionName = id => (id ? GBRoster.REGIONS[id].name : 'No region');
  const unplaced = character => !character.shownServer || character.manualServer;
  const closedServers = new Set();
  let serversFolded = false;
  let serverBoxes = [];
  function renderServers() {
    const table = roster.serverTable();
    byId('server-regions').innerHTML = REGION_IDS.map(id => {
      const rows = table.filter(server => server.region === id && (id || server.count || server.builtIn)).map(server => {
        const where = server.builtIn && server.builtIn !== server.region ? ` · the game lists it in ${regionName(server.builtIn)}` : server.added ? ' · added by hand' : '';
        const choices = REGION_IDS.map(other => `<option value="${other}"${other === server.region ? ' selected' : ''}>${escapeHtml(regionName(other))}</option>`).join('');
        const remove = server.added && !server.count ? `<button type="button" data-drop="${escapeHtml(server.name)}">Remove</button>` : '';
        return `<div class="server-row"><span><b>${escapeHtml(server.name)}</b> <span class="hint">${server.count ? `${number(server.count)} characters` : 'nobody saved yet'}${escapeHtml(where)}</span></span>`
          + `<span class="server-row-tools"><select data-move="${escapeHtml(server.name)}" aria-label="Region of ${escapeHtml(server.name)}">${choices}</select>${remove}</span></div>`;
      }).join('');
      return `<div class="server-region"><h3>${escapeHtml(id ? regionName(id) : 'No region: shown in every region')}</h3>${rows || '<p class="hint">None.</p>'}</div>`;
    }).join('');
    renderServerCharacters();
  }
  function renderServerCharacters() {
    const text = byId('server-search').value.trim().toLowerCase();
    const unknownOnly = byId('server-unknown').checked;
    const everyone = roster.shown().concat(roster.listed().filter(character => roster.shows(character)));
    const wanted = everyone.filter(character => (!unknownOnly || unplaced(character))
      && (!text || character.name.toLowerCase().includes(text) || roster.romTitle(character).toLowerCase().includes(text)));
    if (!serversFolded && everyone.length) {
      serversFolded = true;
      // Thousands of characters start with every server closed
      if (everyone.length > 600) for (const character of everyone) closedServers.add(GBRoster.serverKey(character.shownServer));
    }
    const servers = new Map();
    for (const character of wanted) {
      const key = GBRoster.serverKey(character.shownServer);
      if (!servers.has(key)) servers.set(key, {key, name: character.shownServer || GBRoster.NO_SERVER, groups: new Map(), count: 0});
      const server = servers.get(key);
      server.count++;
      const group = character.romAccount || null;
      if (!server.groups.has(group)) server.groups.set(group, []);
      server.groups.get(group).push(character);
    }
    serverBoxes = [];
    const parts = [];
    for (const server of [...servers.values()].sort((a, b) => Number(!a.key) - Number(!b.key) || b.count - a.count || a.name.localeCompare(b.name))) {
      const open = !!text || unknownOnly || !closedServers.has(server.key);
      const region = server.key ? regionName(GBRoster.regionOf(server.name, roster.view.extra, roster.view.dropped)) : 'shown in every region';
      parts.push(`<details class="server-box" data-server-box="${escapeHtml(server.key)}"${open ? ' open' : ''}><summary><b>${escapeHtml(server.name)}</b> <span class="hint">${escapeHtml(region)} · ${number(server.count)} characters</span></summary><div class="server-accounts">`);
      const groups = [...server.groups.entries()].map(([group, members]) => ({group, members, title: group ? roster.romTitle(members[0]) : ''}))
        .sort((a, b) => Number(!a.group) - Number(!b.group) || a.title.localeCompare(b.title));
      for (const {group, members, title} of groups) {
        const index = serverBoxes.push(members) - 1;
        const tools = (group && members.some(unplaced) ? `<button type="button" class="group-select" data-box-server="${index}">Set server…</button>` : '')
          + (group ? `<button type="button" class="group-select" data-box-rename="${index}">Rename…</button>` : '')
          + `<button type="button" class="group-select" data-box-select="${index}">Select</button>`;
        parts.push(`<div class="server-account${group ? '' : ' is-loose'}"><div class="server-account-head"><span><b>${escapeHtml(group ? title : 'No login screen has listed these yet')}</b> <span class="hint">${number(members.length)}</span></span><span class="server-account-tools">${tools}</span></div><div class="server-chars">`);
        for (const character of members.sort((a, b) => a.name.localeCompare(b.name))) {
          const color = GBAccounts.classColor(character);
          parts.push(`<span class="server-char${character.notSaved ? ' is-unsaved' : ''}${roster.isSelected(character.key) ? ' is-selected' : ''}" data-char="${escapeHtml(character.key)}"${color ? ` style="color:${color}"` : ''}>${escapeHtml(character.name)}${character.manualServer ? '<i> set by hand</i>' : ''}</span>`);
        }
        parts.push('</div></div>');
      }
      parts.push('</div></details>');
    }
    byId('server-view').innerHTML = parts.join('') || `<p class="hint">${everyone.length ? 'No character matches.' : 'No characters saved yet.'}</p>`;
    renderServerPick();
  }
  function renderServerPick() {
    const count = roster.selectedAll().filter(unplaced).length;
    const button = byId('server-set-selected');
    button.disabled = !count;
    button.textContent = count ? `Set the server of the ${number(count)} selected whose server isn't known…` : 'Set the server of selected characters whose server isn\'t known…';
  }
  byId('server-regions').addEventListener('change', event => {
    const box = event.target.closest('[data-move]');
    if (box) roster.setServerRegion(box.dataset.move, box.value);
  });
  byId('server-regions').addEventListener('click', event => {
    const box = event.target.closest('[data-drop]');
    if (box) roster.removeServer(box.dataset.drop);
  });
  byId('server-add').addEventListener('submit', event => {
    event.preventDefault();
    const name = GBRoster.cleanServer(byId('server-add-name').value);
    const problem = roster.addServer(name, byId('server-add-region').value);
    byId('server-note').textContent = problem || `${name} is on the list now.`;
    if (!problem) byId('server-add-name').value = '';
  });
  byId('server-reset').addEventListener('click', () => {
    if (!window.confirm('Put every server back in the region the game lists it in, and forget the servers you added?')) return;
    roster.resetRegions();
    byId('server-note').textContent = 'The game\'s own lists are back.';
  });
  let serverTyping = 0;
  byId('server-search').addEventListener('input', () => {
    clearTimeout(serverTyping);
    serverTyping = setTimeout(() => changed(['servers']), 150);
  });
  byId('server-unknown').addEventListener('change', () => changed(['servers']));
  byId('server-set-selected').addEventListener('click', () => setServerFor(roster.selectedAll().filter(unplaced)));
  byId('server-view').addEventListener('click', event => {
    const target = event.target.closest('[data-box-select], [data-box-server], [data-box-rename]');
    if (!target) return;
    const members = serverBoxes[Number(target.dataset.boxSelect ?? target.dataset.boxServer ?? target.dataset.boxRename)] || [];
    if (target.dataset.boxSelect !== undefined) selectKeys(members.map(character => character.key));
    else if (target.dataset.boxServer !== undefined) setServerFor(members.filter(unplaced));
    else if (members.length) renameRom(members[0]);
  });
  // A server closed stays closed when the list is drawn again
  byId('server-view').addEventListener('toggle', event => {
    const box = event.target.closest?.('[data-server-box]');
    if (!box) return;
    if (box.open) closedServers.delete(box.dataset.serverBox);
    else closedServers.add(box.dataset.serverBox);
  }, true);
  // Two copies of this page would overwrite each other's account changes
  if (typeof BroadcastChannel === 'function') {
    const pages = new BroadcastChannel('global-bank-page');
    pages.onmessage = event => {
      if (event.data === 'here?') pages.postMessage('here');
      if (event.data === 'here' || event.data === 'here?') byId('page-twice').hidden = false;
      if (event.data === 'gone') byId('page-twice').hidden = true;
    };
    pages.postMessage('here?');
    window.addEventListener('pagehide', () => pages.postMessage('gone'));
  }
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
  // The saved region, ticks and selection first, so the first drawing already uses them
  roster.load().catch(() => {}).finally(() => {
    renderSettings();
    renderViewBar();
    renderSelectionBar();
    tryReload();
  });
  // Coming back to this tab looks for new data, at most once a minute, and only reads it all when it changed.
  let lastLook = Date.now();
  document.addEventListener('visibilitychange', () => {
    if (document.hidden || Date.now() - lastLook < 60000) return;
    lastLook = Date.now();
    bank.reload({ifChanged: true}).catch(error => bankStatus('Could not read new data: ' + String(error.message || error)));
  });

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
      bank.reload({ifChanged: true}).catch(error => printLine('Could not read the new data: ' + String(error.message || error)));
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
