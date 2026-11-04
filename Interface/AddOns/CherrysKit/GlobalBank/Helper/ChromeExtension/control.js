'use strict';
(() => {
  const CASCADE_SCREENS = [[1920, 1080], [2560, 1440], [3440, 1440], [3840, 2160]];
  // A size that suits a screen: the same share of its height as 1134 x 818 on a 1440p screen, same shape.
  const cascadeSuggest = height => { const h = Math.round(height * 818 / 1440); return {width: Math.round(h * 1134 / 818), height: h}; };
  // Fills the Display and Size lists: the displays Windows reports, or plain numbers when they can't be listed.
  // Shows which screen's size Resolution holds: the one picked if it still matches, else the first that does,
  // else "Pick a screen" (Resolution typed by hand).
  function showCascadeSize(sizeSelect, width, height) {
    const key = `${width}x${height}`, options = [...sizeSelect.options];
    if (options[sizeSelect.selectedIndex]?.value === key) return;
    const index = options.findIndex(item => item.value === key);
    sizeSelect.selectedIndex = index > 0 ? index : 0;
  }
  function fillCascadeLists(monitorSelect, sizeSelect, monitors, chosen, width, height) {
    const option = (value, text) => { const item = document.createElement('option'); item.value = value; item.textContent = text; return item; };
    const listed = Array.isArray(monitors) && monitors.length ? monitors : null;
    monitorSelect.replaceChildren(option('0', 'Where the oldest game window is'));
    for (const monitor of listed || [1, 2, 3, 4].map(id => ({id}))) {
      monitorSelect.append(option(String(monitor.id), listed ? `Display ${monitor.id}: ${monitor.width} x ${monitor.height}${monitor.primary ? ' (main)' : ''}` : `Display ${monitor.id}`));
    }
    if (chosen && ![...monitorSelect.options].some(item => item.value === String(chosen))) monitorSelect.append(option(String(chosen), `Display ${chosen} (not found)`));
    monitorSelect.value = String(chosen || 0);
    const picked = sizeSelect.options[sizeSelect.selectedIndex]?.textContent;
    sizeSelect.replaceChildren(option('', 'Pick a screen'));
    const screens = (listed || []).map(monitor => [monitor.width, monitor.height, `Display ${monitor.id}`]).concat(CASCADE_SCREENS.map(([w, h]) => [w, h, '']));
    const seen = new Set();
    for (const [w, h, name] of screens) {
      const size = cascadeSuggest(h), key = `${size.width}x${size.height}`;
      if (!name && seen.has(key)) continue;
      seen.add(key);
      sizeSelect.append(option(key, `${name ? name + ', ' : ''}${w} x ${h} screen: ${size.width} x ${size.height}`));
    }
    const again = [...sizeSelect.options].findIndex(item => item.textContent === picked);
    if (again > 0) sizeSelect.selectedIndex = again;
    showCascadeSize(sizeSelect, width, height);
  }
  const byId = id => document.getElementById(id);
  const status = byId('helper-status');
  const start = byId('start-helper');
  const stopButton = byId('stop-helper');
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
      start.hidden = !!response.running;
      stopButton.hidden = !response.running;
      return !!response.running;
    } catch (error) {
      status.textContent = 'Cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error);
      start.disabled = true;
      stopButton.hidden = true;
      return false;
    }
  }
  byId('check-helper').addEventListener('click', checkHelper);
  async function startHelper() {
    if (starting) return;
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
      refreshStatus();
    }
  }
  start.addEventListener('click', event => { if (event.isTrusted) startHelper(); });
  // The same as the popup's Stop: it stops the helper and turns off automatic start.
  stopButton.addEventListener('click', async event => {
    if (!event.isTrusted) return;
    stopButton.disabled = true;
    status.textContent = 'Stopping the helper\u2026';
    try {
      autoHelper.checked = false;
      await chrome.storage.local.set({autoHelper: false});
      await send({type:'helper-stop'});
    } catch (error) {
      status.textContent = 'Could not stop the helper: ' + String(error.message || error);
    } finally {
      stopButton.disabled = false;
      await checkHelper();
      refreshStatus();
    }
  });
  // Pages. Only the open one is drawn; one whose data changed while hidden is drawn when you open it.
  let currentTab = 'bank';
  let terminal = null;
  // The Servers page shows the regions' lists even before any data comes in
  const dirty = new Set(['servers']);
  const views = {};
  // These keep track of their own changes, and are cheap to ask
  const selfTracking = new Set(['bank', 'favourites', 'accounts', 'heatmap', 'macros', 'settings']);
  function showTab(name) {
    currentTab = name;
    document.querySelectorAll('[data-tab]').forEach(tab => {
      if (tab.dataset.tab === name) tab.setAttribute('aria-current', 'page');
      else tab.removeAttribute('aria-current');
    });
    document.querySelectorAll('.tab-panel').forEach(panel => { panel.hidden = panel.id !== 'tab-' + name; });
    byId('bank-tooltip').hidden = true;
    byId('char-tooltip').hidden = true;
    byId('main').scrollTop = 0;
    history.replaceState(null, '', '#' + name);
    document.title = `${document.querySelector(`[data-tab="${name}"] .nav-text`)?.textContent || 'Bank'} · Global Bank`;
    drawOpenTab();
    if (terminal) terminal.visible(name === 'terminal');
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

  // The Gameforge accounts' lock: at the top of the page, and in the Connection panel with its password box
  let accountState = 'none';
  function showAccountState(state) {
    // Locked and not linked read differently, so the tables that name accounts are drawn again
    if (state !== accountState) changed(['characters', 'currencies', 'servers']);
    accountState = state;
    const words = {none: 'No accounts saved', 'needs-key': 'Accounts need their key', locked: 'Accounts locked', open: 'Accounts open'};
    byId('status-accounts-text').textContent = words[state];
    byId('gf-forgot').hidden = state === 'none';
    byId('status-accounts-icon').innerHTML = window.GB_ICONS?.[state === 'open' ? 'unlock' : 'lock'] || '';
    byId('connection-accounts').textContent = {none: 'No Gameforge accounts are saved on this PC. You can add them on the Gameforge accounts page.',
      'needs-key': 'An encrypted accounts file is here, but this Chrome doesn\u2019t have its key. Enter it on the Gameforge accounts page.',
      locked: 'Enter your password to open your Gameforge accounts. Your items, gold and characters don\u2019t need it.',
      open: 'Your Gameforge accounts are open until you lock them or close this page.'}[state];
  }
  // Who is who on every page: the region, the server ticks, and one selection a click on any character changes
  const number = value => Number(value || 0).toLocaleString('en-US');
  const escapeHtml = GBRoster.escapeHtml;
  const roster = GBRoster.create(chrome.storage.local);
  const accounts = GBAccounts.create(send, {
    lockChanged: state => showAccountState(state),
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
    mailbox: key => mailboxes().get(key),
  });
  // A group's Select button selects all of it, or, when all of it is selected already, none of it
  function selectKeys(keys) {
    const group = new Set(keys);
    const all = keys.length > 0 && keys.every(key => roster.isSelected(key));
    roster.setSelection(all ? [...roster.selection].filter(key => !group.has(key)) : [...roster.selection, ...keys]);
  }
  // A selection only changes colours: the open tab's characters are marked, and the rest when they're opened.
  function markSelected() {
    const page = byId('tab-' + currentTab);
    page?.querySelectorAll('[data-char]').forEach(node => node.classList.toggle('is-selected', roster.isSelected(node.dataset.char)));
    const boxes = [...(page?.querySelectorAll('.char-check') || [])];
    for (const box of boxes) box.checked = roster.isSelected(box.closest('[data-char]')?.dataset.char);
    page?.querySelectorAll('.select-all').forEach(box => { box.checked = boxes.length > 0 && boxes.every(item => item.checked); });
  }
  const REGION_NAMES = {eu: 'Europe', na: 'North America', '': 'Other servers', unknown: 'Not known yet'};
  // A short note that goes away by itself
  let toastTimer = 0;
  function toast(text) {
    const node = byId('toast');
    clearTimeout(toastTimer);
    node.textContent = text;
    node.hidden = false;
    toastTimer = setTimeout(() => { node.hidden = true; }, 5000);
  }
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
    const on = servers.filter(server => server.on).length;
    byId('servers-summary').textContent = on === servers.length ? 'All servers' : `${number(on)} of ${number(servers.length)} servers`;
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
    byId('selection-bar').hidden = !roster.selection.size;
    byId('selection-count').textContent = !(shown + hidden) ? 'No characters selected'
      : `${number(shown + hidden)} selected` + (hidden ? ` (${number(hidden)} on servers not shown)` : '');
    byId('selection-copy').disabled = !shown;
    byId('selection-clear').disabled = !roster.selection.size;
    // Names only a login screen listed can be selected, but hold nothing the Bank could show
    byId('selection-use').disabled = !roster.selected().length;
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
    byId('servers-menu').open = false;
    showTab('servers');
  });
  byId('card-hide-gameforge').addEventListener('change', event => roster.setCard('gameforge', event.target.checked));
  byId('card-hide-rom').addEventListener('change', event => roster.setCard('rom', event.target.checked));
  byId('gf-first').addEventListener('change', event => roster.setRomFirst(event.target.value === 'rom'));
  byId('selection-use').addEventListener('click', () => {
    roster.useSelection();
    showTab('bank');
    const count = roster.inScopeShown().length;
    toast(count === 1 ? 'The Bank now shows this character\u2019s items.' : `The Bank now shows these ${number(count)} characters\u2019 items.`);
  });
  byId('selection-clear').addEventListener('click', () => roster.clearSelection());
  byId('select-stale').addEventListener('click', () => roster.setSelection(roster.shown().filter(character => character.stale).map(character => character.key)));
  byId('selection-copy').addEventListener('click', () => copyNames(roster.selectedAll(), ', ', byId('selection-note')));

  // The Bank tab
  const bankStatus = text => { byId('bank-status').textContent = text; };
  // What the top of the page says about the saved data, and the counts beside the page names
  let savedMade = null;
  function renderSavedData() {
    const shown = roster.shown();
    byId('nav-count-characters').textContent = shown.length ? number(shown.length) : '';
    byId('nav-count-bank').textContent = shown.length ? number(GBBank.totals(shown).stacks) : '';
    const all = roster.characters();
    const totals = GBBank.totals(all);
    const node = byId('status-data');
    node.textContent = !savedMade ? 'No data saved yet' : `Saved data · ${savedMade}`;
    node.parentElement.title = `${number(totals.characters)} characters · ${number(totals.items)} items in ${number(totals.stacks)} stacks. Saved data doesn't need the helper running.`
      + (usingFolders ? ' Read from your chosen folders.' : '');
  }
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
  // Every mailbox now, worked out again for new data, and once a minute, since mail runs out with time
  let mailCache = null;
  function mailboxes() {
    const loaded = bank ? bank.loadedAt() : 0;
    if (!mailCache || mailCache.loaded !== loaded || Date.now() - mailCache.at > 60000) {
      mailCache = {loaded, at: Date.now(), boxes: GBMail.mailboxes(roster.characters())};
    }
    return mailCache.boxes;
  }
  // The line a character's hover card and details give its mailbox, or null when nothing waits
  function mailLine(character) {
    const box = mailboxes().get(character.key);
    const text = GBMail.summary(box, Date.now() / 1000, GBBank.formatCompact);
    return text ? {text: `Mailbox: ${text}`, soon: box.expiring > 0} : null;
  }
  function renderMailCount() {
    const sum = GBMail.totals(mailboxes(), roster.shown());
    const node = byId('nav-count-mail');
    node.textContent = sum.mails ? number(sum.mails) : '';
    node.classList.toggle('is-urgent', sum.expiring > 0);
    node.title = sum.expiring ? `${number(sum.expiring)} expire within 48 hours` : '';
  }
  // Character transfers: what the Runes of Magic site's transfer page listed, the plates and the log, and the
  // characters a transfer moved to their new server. The background keeps the records; this page draws them.
  const transfers = GBTransfers.create({
    storage: chrome.storage.local,
    send,
    changed: what => {
      // One that moved a character, or changed what it is, prepares the characters again, the selection kept on them
      if (what === 'records' && bank) roster.rekey(() => bank.reprepare());
      renderTransferCount();
      changed(['characters']);
    },
    who: record => transferWho(record),
    openLog: id => openTransferLog(id),
    tooltip: byId('xfer-tooltip'),
  });
  let bank = null;
  bank = GBBank.create(byId('tab-bank'), bankSend, bankStatus, (totals, made, characters) => {
    accounts.setCharacters(characters);
    renderViewBar();
    renderSelectionBar();
    savedMade = made;
    renderSavedData();
    renderMailCount();
    renderTransferCount();
    changed(['favourites', 'currencies', 'stats', 'heatmap', 'characters', 'accounts', 'servers', 'mail']);
    // What the new saves say about transfers: one gone from its old server, or logged in on its new one
    transfers.check(bank.raw());
  }, accounts.openMenu, {
    roster,
    favouritesRoot: byId('tab-favourites'),
    openTab: showTab,
    visible: () => currentTab === 'bank',
    tooltip: byId('bank-tooltip'),
    favouritesChanged: count => { byId('nav-count-favourites').textContent = count ? number(count) : ''; },
    review: kind => (kind === 'mail' ? showTab('mail') : setRosterFilter(kind, true)),
    mailboxes,
    // A character a transfer moved shows on its new server, and its old server's copy goes once it logged in there
    adjust: list => transfers.overlay(list),
  });
  // Macros and addon settings come from the save folders, whose names are the characters' names.
  // A folder the page has no character for always shows, like a character whose server isn't known.
  const named = name => roster.characters().concat(roster.listed()).filter(character => character.name === name);
  const backups = GBBackups.create(send, {
    shows: (name, onlySelected) => {
      const found = named(name);
      if (onlySelected) return found.some(character => roster.isSelected(character.key));
      return !found.length || found.some(character => roster.shows(character));
    },
    selectedNames: () => [...new Set(roster.selectedAll().map(character => character.name))],
  });
  views.macros = () => { backups.showMacros(); };
  views.settings = () => { backups.showSettings(); };
  const addonsPage = GBAddons.create(send, {toast: text => toast(text)});
  views.addons = () => { addonsPage.show(); };
  selfTracking.add('addons');
  // Characters and Currencies: a search, and groups by server or account
  const tables = {characters: ['roster', 'roster-view'], currencies: ['currency', 'currency-view']};
  const tableOptions = prefix => ({
    how: byId(prefix + '-group').value,
    singlesTogether: prefix === 'roster' && byId('roster-singles').checked,
    search: byId(prefix + '-search').value,
    isSelected: key => roster.isSelected(key),
    accountName: name => accounts.accountName(name),
    romTitle: character => roster.romTitle(character),
    classColor: GBAccounts.classColor,
    locked: () => accounts.locked(),
    openCharacter,
    summary: prefix === 'currency' ? byId('currency-summary') : null,
    selectKeys,
    mailbox: key => mailboxes().get(key),
    transfer: character => transfers.plate(character),
  });
  // Which characters the Characters page lists. Needs login and Bank not recorded mean different things and can
  // overlap. Excluded characters aren't in the saved data at all: the helper keeps that list.
  let rosterFilter = 'all';
  const needsLogin = character => !!character.stale;
  const bankMissing = character => !GBBank.bankKnown(character);
  function rosterShown() {
    const list = roster.shown();
    return rosterFilter === 'login' ? list.filter(needsLogin) : rosterFilter === 'bank' ? list.filter(bankMissing) : list;
  }
  function renderRosterCounts() {
    const list = roster.shown();
    byId('roster-count-all').textContent = number(list.length);
    byId('roster-count-login').textContent = number(list.filter(needsLogin).length);
    byId('roster-count-bank').textContent = number(list.filter(bankMissing).length);
  }
  function setRosterFilter(kind, open) {
    rosterFilter = kind;
    document.querySelectorAll('[data-roster-filter]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.rosterFilter === kind)));
    byId('roster-view').hidden = kind === 'excluded' || kind === 'transfers';
    byId('excluded-view').hidden = kind !== 'excluded';
    byId('transfers-view').hidden = kind !== 'transfers';
    if (open) showTab('characters');
    changed(['characters']);
  }
  document.querySelectorAll('[data-roster-filter]').forEach(button => button.addEventListener('click', () => setRosterFilter(button.dataset.rosterFilter)));
  // The helper's own exclusions, changed through its own commands, so this page and its terminal can't disagree
  async function drawExcluded() {
    const note = byId('excluded-status');
    const reply = await terminal.catalogue(true);
    const list = byId('excluded-list');
    if (!reply.ok) {
      note.textContent = 'The list comes from the local helper, which isn\u2019t answering. ' + (reply.error || '');
      list.replaceChildren();
      byId('roster-count-excluded').textContent = '';
      return;
    }
    const names = reply.excluded || [];
    byId('roster-count-excluded').textContent = number(names.length);
    note.textContent = names.length ? '' : 'Nobody is excluded.';
    list.replaceChildren(...names.map(name => {
      const row = document.createElement('li');
      const label = document.createElement('b');
      label.textContent = name;
      const again = document.createElement('button');
      again.type = 'button';
      again.className = 'gb-button--sm';
      again.textContent = 'Track again';
      again.addEventListener('click', async () => {
        again.disabled = true;
        const answer = await terminal.command(`unban ${name}`);
        note.textContent = GBTerminal.recordsText(answer.records) || answer.error || '';
        if (answer.changed) bank.reload({ifChanged: true}).catch(() => {});
        await drawExcluded();
      });
      row.append(label, again);
      return row;
    }));
  }
  // The transfer log, under Characters: what each one is now, the weekly maintenance it waits for, and Forget
  const dayClock = new Intl.DateTimeFormat(undefined, {weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'});
  function renderTransferCount() {
    const count = transfers.counts();
    const node = byId('roster-count-transfers');
    node.textContent = count.total ? number(count.active) : '';
    node.classList.toggle('is-attention', count.due + count.moved > 0);
  }
  function renderMaintenance() {
    const plan = transfers.maintenance();
    const day = byId('xfer-day'), time = byId('xfer-time');
    if (document.activeElement !== day) day.value = String(plan.day);
    if (document.activeElement !== time) time.value = `${String(plan.hour).padStart(2, '0')}:${String(plan.minute).padStart(2, '0')}`;
    byId('xfer-next').textContent = `Next: ${dayClock.format(transfers.next())} your time`;
  }
  function drawTransfers() {
    renderTransferCount();
    renderMaintenance();
    const shown = transfers.renderLog(byId('transfers-rows'), {search: byId('roster-search').value});
    const total = transfers.counts().total;
    byId('transfers-log').hidden = !shown;
    byId('transfers-status').textContent = !total ? 'No character transfers yet. Open the transfer page on the Runes of Magic site, and Global Bank records the ones it lists as planned.'
      : !shown ? 'No transfer matches the search.' : '';
  }
  // From a plate: the log, at that transfer
  function openTransferLog(id) {
    setRosterFilter('transfers', true);
    const row = byId('xfer-' + id);
    if (!row) return;
    row.scrollIntoView({block: 'center'});
    row.classList.add('is-focus');
    setTimeout(() => byId('xfer-' + id)?.classList.remove('is-focus'), 2400);
  }
  // A transfer's character, wherever it shows now, and its accounts as this page knows them: its RoM account from its
  // own login screen, or its old one's; its Gameforge account from it or any character the same transfer page
  // offered; and, while it waits for the maintenance, what its mailbox still holds
  function transferWho(record) {
    const servers = record.state === 'moved' || record.state === 'done' ? [record.to, record.from] : [record.from, record.to];
    const own = servers.map(server => roster.byKey(GBRoster.keyOf(record.name, server))).filter(Boolean);
    const mates = (record.account || []).map(key => roster.byKey(key)).filter(Boolean);
    const oldMates = mates.filter(character => GBRoster.serverKey(character.shownServer) === GBRoster.serverKey(record.from));
    const oldRom = oldMates.map(character => roster.romTitle(character)).find(Boolean);
    const box = record.state === 'planned' && own[0] ? mailboxes().get(own[0].key) : null;
    return {
      rom: roster.view.hideRom ? '' : own.map(character => roster.romTitle(character)).find(Boolean) || (oldRom ? `${oldRom} on ${record.from}` : ''),
      gameforge: roster.view.hideGameforge || accounts.locked() ? '' : [...own, ...mates].map(character => accounts.accountNameOf(character)).find(Boolean) || '',
      mail: box ? GBMail.summary(box, Date.now() / 1000, GBBank.formatCompact) : '',
    };
  }
  function saveMaintenance() {
    const [hour, minute] = byId('xfer-time').value.split(':').map(Number);
    if (!Number.isInteger(hour) || !Number.isInteger(minute)) return;
    transfers.setMaintenance({day: Number(byId('xfer-day').value), hour, minute}).catch(error => toast('Could not keep the maintenance time: ' + String(error.message || error)));
  }
  byId('xfer-day').addEventListener('change', saveMaintenance);
  byId('xfer-time').addEventListener('change', saveMaintenance);
  byId('transfers-rows').addEventListener('click', async event => {
    const button = event.target.closest('[data-xfer-forget]');
    const record = button && transfers.record(button.dataset.xferForget);
    if (!record) return;
    const waiting = record.state === 'planned' || record.state === 'moved';
    const yes = await ask({title: 'Forget this transfer', noField: true, save: 'Forget',
      hint: `${record.name}, ${record.from} to ${record.to}, leaves the log` + (waiting ? ', and its plate goes. If the transfer page still lists it, it comes back the next time you open that page.' : '.')});
    if (yes === null) return;
    try {
      await transfers.forget(record.id);
    } catch (error) {
      toast('Could not forget it: ' + String(error.message || error));
    }
  });
  // The log's countdowns, while it shows
  setInterval(() => {
    if (currentTab === 'characters' && rosterFilter === 'transfers' && !document.hidden && transfers.tickLog(byId('transfers-rows'))) drawTransfers();
  }, 30000);
  // A character's note, kept by the helper and shown when you hover the character, here and in the game's window. It
  // goes through the helper's own note command, which checks it again.
  const noteProblem = text => (/[\x00-\x1f"~`|\\]/.test(text) ? 'A note can’t hold quotes, backslashes, |, ~ or backticks.'
    : new TextEncoder().encode(text).length > 80 ? 'Keep it to 80 letters or fewer, fewer with accents.' : '');
  async function editNote(character) {
    const text = await ask({
      title: character.note ? 'Edit note' : 'Add note',
      hint: `A note for ${character.name}. It shows when you hover the character, here and in the game’s Global Bank window, and the Characters search finds it.`,
      label: 'Note', value: character.note || '', placeholder: 'bank alt, mats, daily tokens…', clear: character.note ? 'Remove the note' : '',
      check: noteProblem,
    });
    if (text === null || text === (character.note || '')) return;
    const reply = await terminal.command(`note ${character.name} ${text}`.trim());
    toast(GBTerminal.recordsText(reply.records) || reply.error || '');
    if (reply.changed) await bank.reload({ifChanged: true}).catch(() => {});
  }
  // Right-click, Stop tracking: the helper names exactly who that covers, and asks.
  async function stopTracking(character) {
    const reply = await terminal.command(`erase ${character.base || character.name}`);
    const question = (reply.records || []).find(record => record.kind === 'confirm');
    if (!question) {
      toast(GBTerminal.recordsText(reply.records) || reply.error || 'The helper didn\u2019t answer.');
      return;
    }
    const yes = await ask({title: 'Stop tracking', hint: question.text, noField: true, save: question.yes, cancel: question.no});
    const answer = await terminal.confirm(question.token, yes === null ? 'no' : 'yes');
    toast(GBTerminal.recordsText(answer.records) || answer.error || '');
    if (answer.changed) {
      roster.selection.delete(character.key);
      roster.scope.delete(character.key);
      await bank.reload({ifChanged: true}).catch(() => {});
    }
    if (rosterFilter === 'excluded') drawExcluded();
    else terminal.catalogue(true).then(fresh => { if (fresh.ok) byId('roster-count-excluded').textContent = number((fresh.excluded || []).length); });
  }
  // What a character wears, laid out like the game's character window: rings, earrings and the necklace on top, a column
  // either side of the figure, talismans beside it and the ammunition under it. Each slot shows the game's own tooltip.
  const PROFILE_LEFT = ['Head', 'Chest', 'Waist', 'Legs', 'MainHand', 'Ranged'];
  const PROFILE_RIGHT = ['Shoulder', 'Hands', 'Feet', 'Back', 'SecondaryHand', 'Adornment'];
  const PROFILE_TOP = ['Ring0', 'Ring1', 'Earring0', 'Earring1', 'Necklace'];
  const PROFILE_TALISMANS = ['Talisman0', 'Talisman1', 'Talisman2'];
  const PROFILE_SHORT = {Head: 'Head', Chest: 'Chest', Waist: 'Waist', Legs: 'Legs', MainHand: 'Main', Ranged: 'Range', Shoulder: 'Shldr', Hands: 'Hands',
    Feet: 'Feet', Back: 'Back', SecondaryHand: 'Off', Adornment: 'Orn', Ring0: 'Ring', Ring1: 'Ring', Earring0: 'Ear', Earring1: 'Ear', Necklace: 'Neck',
    Talisman0: 'Tal', Talisman1: 'Tal', Talisman2: 'Tal', Ammo: 'Ammo'};
  function characterProfile(character, make, tip) {
    const worn = new Map((Array.isArray(character.equip) ? character.equip : []).map(item => [String(item.where), item]));
    const section = make('section', 'character-profile');
    section.setAttribute('aria-label', 'Character profile');
    const head = make('div', 'profile-head');
    head.append(make('h3', '', 'Character profile'));
    section.append(head);
    const classes = (character.classes || []).filter(item => item.name).map(item => `${item.name} ${item.level}`);
    section.append(make('div', 'profile-classes', classes.length ? classes.join(' / ') : [character.class, character.level ? `Level ${number(character.level)}` : ''].filter(Boolean).join(' · ') || 'Class not recorded'));
    const icons = [];
    const marksOf = item => {
      const gear = GBBank.wornGear(item);
      return GBBank.slotMarks({tier: GBBank.tierOf({...item, gear}), gear}, bank.tierFrom());
    };
    const slot = where => {
      const item = worn.get(where);
      const node = make('button', 'bank-slot profile-slot' + (item ? ' filled' : ' is-empty'));
      node.type = 'button';
      node.dataset.where = where;
      const label = GBBank.slotLabel(where);
      if (!item) {
        node.append(make('span', 'profile-slot-name', PROFILE_SHORT[where] || label));
        node.setAttribute('aria-label', `${label}: empty`);
        node.disabled = !Array.isArray(character.equip);
        node.title = Array.isArray(character.equip) ? `${label}: nothing worn` : label;
        return node;
      }
      if (item.quality > 0) node.classList.add(`q${Math.min(5, item.quality)}`);
      node.append(make('span', 'bank-letters', String(item.name || '?').slice(0, 2)));
      const picture = make('img');
      picture.alt = '';
      picture.dataset.icon = item.icon || '';
      if (item.icon) icons.push(item.icon);
      node.append(picture);
      const marks = marksOf(item);
      node.append(make('span', 'bank-mark bank-mark-tier', marks.tier), make('span', 'bank-mark bank-mark-hd', marks.durability), make('span', 'bank-mark bank-mark-plus', marks.plus));
      if (item.count > 1) node.append(make('span', 'bank-count', String(item.count)));
      node.setAttribute('aria-label', [`${label}: ${item.name}`, ...marks.words].join(', '));
      node.addEventListener('mouseenter', event => tip.show(event, item, label));
      node.addEventListener('mousemove', event => tip.move(event));
      node.addEventListener('mouseleave', () => tip.hide());
      node.addEventListener('focus', () => tip.show(null, item, label, node));
      node.addEventListener('blur', () => tip.hide());
      node.addEventListener('click', () => {
        byId('character-panel').close();
        roster.setScope([character.key]);
        bank.find(item.name);
        showTab('bank');
      });
      return node;
    };
    const doll = make('div', 'profile-doll');
    const top = make('div', 'profile-top');
    top.append(...PROFILE_TOP.map(slot));
    const left = make('div', 'profile-column');
    left.append(...PROFILE_LEFT.map(slot));
    const right = make('div', 'profile-column');
    right.append(...PROFILE_RIGHT.map(slot));
    const middle = make('div', 'profile-middle');
    const figure = make('div', 'profile-figure');
    const color = GBAccounts.classColor(character);
    if (color) figure.style.setProperty('--class-color', color);
    figure.append(make('span', 'profile-initial', String(character.class || '?').slice(0, 1).toUpperCase()), make('span', 'profile-name', character.base || character.name));
    const talismans = make('div', 'profile-talismans');
    talismans.append(...PROFILE_TALISMANS.map(slot));
    const ammo = make('div', 'profile-ammo');
    ammo.append(slot('Ammo'));
    middle.append(talismans, figure, ammo);
    doll.append(top, left, middle, right);
    section.append(doll);
    // A line about it all: how much is worn, the highest plus, the tiers and how many are HD
    if (!Array.isArray(character.equip)) {
      section.append(make('p', 'hint', character.notSaved ? 'Nothing saved for this character yet.' : 'What it wears isn’t recorded yet: log in once with it on Global Bank 1.6.2 or newer.'));
    } else {
      const gear = [...worn.values()].map(item => {
        const shaped = GBBank.wornGear(item);
        return {plus: shaped.plus, tier: GBBank.tierOf({...item, gear: shaped}), hd: shaped.dura > 101};
      });
      const tiers = gear.map(item => item.tier).filter(Boolean);
      const parts = [`${number(worn.size)} ${worn.size === 1 ? 'slot' : 'slots'} worn`];
      const plus = Math.max(0, ...gear.map(item => item.plus));
      if (plus) parts.push(`up to +${plus}`);
      if (tiers.length) parts.push(Math.min(...tiers) === Math.max(...tiers) ? `T${tiers[0]}` : `T${Math.min(...tiers)} to T${Math.max(...tiers)}`);
      const hd = gear.filter(item => item.hd).length;
      if (hd) parts.push(`${number(hd)} HD`);
      section.append(make('p', 'profile-summary', parts.join(' · ')));
      section.append(make('p', 'hint', 'Hover a slot for the game’s own tooltip, as last saved. Click one to find it on the Bank page.'));
    }
    if (icons.length && typeof GBIcons !== 'undefined') {
      GBIcons.load(icons, bankSend, (name, url) => {
        for (const picture of section.querySelectorAll('img[data-icon]')) if (picture.dataset.icon === name) picture.src = url;
      }).catch(() => {});
    }
    return section;
  }
  // The game's tooltip for a worn item, inside the details drawer: the page's own tooltip sits below an open dialog
  function profileTip(make) {
    const node = make('div', 'bank-tooltip profile-tip');
    node.hidden = true;
    const place = (x, y) => {
      node.style.left = Math.max(4, Math.min(x + 14, window.innerWidth - node.offsetWidth - 8)) + 'px';
      node.style.top = Math.max(4, Math.min(y + 14, window.innerHeight - node.offsetHeight - 8)) + 'px';
    };
    return {
      node,
      show(event, item, label, anchor = null) {
        const lines = GBBank.tipLines(item.tip);
        const nodes = [];
        if (lines.length) {
          const game = make('div', 'game-tip');
          for (const line of lines) {
            const row = make('div', 'game-tip-line');
            const left = make('span', 'game-tip-left', line.left);
            if (line.leftColor) left.style.color = line.leftColor;
            row.append(left);
            if (line.right) {
              const right = make('span', 'game-tip-right', line.right);
              if (line.rightColor) right.style.color = line.rightColor;
              row.append(right);
            }
            game.append(row);
          }
          nodes.push(game);
        } else {
          nodes.push(make('strong', '', item.name));
          if (item.maxDura) nodes.push(make('span', 'bank-tip-plain', `Durability ${number(item.dura)} / ${number(item.maxDura)}`));
        }
        nodes.push(make('span', 'bank-tip-hint', `${label} · click to find it on the Bank page`));
        node.replaceChildren(...nodes);
        node.hidden = false;
        if (event) place(event.clientX, event.clientY);
        else if (anchor) {
          const box = anchor.getBoundingClientRect();
          place(box.right, box.top);
        }
      },
      move(event) { if (!node.hidden) place(event.clientX, event.clientY); },
      hide() { node.hidden = true; },
    };
  }
  // One character's details, from the arrow on its row or its right-click menu
  function openCharacter(key) {
    const character = roster.byKey(key);
    if (!character) return;
    const make = (tag, className, text) => {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    };
    const avatar = make('span', 'class-avatar', String(character.class || '?').slice(0, 1).toUpperCase());
    const color = GBAccounts.classColor(character);
    if (color) avatar.style.setProperty('--class-color', color);
    const title = make('h2', '', character.name);
    title.id = 'character-panel-title';
    const words = make('div');
    words.append(title, make('div', 'hint', [character.class, character.level ? `Level ${number(character.level)}` : '', character.shownServer || GBRoster.NO_SERVER].filter(Boolean).join(' · ')));
    const hero = make('div', 'character-hero');
    hero.append(avatar, words);
    const metrics = make('div', 'detail-metrics');
    const stones = GBBank.transferStones(character);
    const known = GBBank.bankKnown(character);
    for (const [value, label] of [[character.notSaved ? 'Not recorded' : number(character.gold), Number(character.gold) >= GBRoster.FULL_CAP ? 'Gold · a full cap' : 'Gold'],
      [known || stones ? `${number(stones)}${known ? '' : '+'}` : 'Not recorded', known ? 'Transfer stones' : 'Transfer stones · bank not recorded']]) {
      const metric = make('div', 'detail-metric', value);
      metric.append(make('span', '', label));
      metrics.append(metric);
    }
    const details = make('dl', 'detail-list');
    const add = (label, value) => details.append(make('dt', '', label), make('dd', '', value));
    const bag = (character.bag || []).length, held = (character.bank || []).length;
    add('Bag', character.notSaved ? 'Not recorded' : character.bagSlots ? `${number(bag)} of ${number(character.bagSlots)} slots used` : `${number(bag)} slots used`);
    add('Bank', !known ? 'Bank not recorded: log in once with it' : character.bankSlots ? `${number(held)} of ${number(character.bankSlots)} slots used` : `${number(held)} slots used`);
    add('Last saved', character.saved || 'Not recorded');
    add('Login status', character.fromTransfer ? 'Known from the character transfer page only: log in with it once'
      : character.notSaved ? 'Nothing saved yet: log in once' : character.stale ? 'Needs a login on the current version' : 'Current');
    if (!roster.view.hideGameforge) add('Gameforge account', accounts.accountNameOf(character) || (accounts.locked() ? 'Locked' : 'Not linked'));
    if (!roster.view.hideRom) add('RoM account', roster.romTitle(character) || 'Not known yet');
    const taken = Date.parse(character.dailyLogin?.collectedAt || '');
    const clock = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    add('Last daily reward', Number.isFinite(taken) ? `Day ${character.dailyLogin.day || '?'}, ${clock.format(taken)}` : 'Not recorded');
    // Its mailbox as last open, with what was sent to it since; and what it sent
    if (!character.notSaved) {
      const box = mailboxes().get(character.key);
      const waiting = GBMail.summary(box, Date.now() / 1000, GBBank.formatCompact);
      add('Mailbox', waiting || (box?.recorded ? 'Nothing waiting' : character.mail ? 'Not open yet on this version: nothing known' : 'Not recorded: open its mailbox once on Global Bank 1.6.2 or newer'));
      if (box?.read) add('Mailbox last open', clock.format(box.read * 1000));
      const sent = Array.isArray(character.mail?.sent) ? character.mail.sent : [];
      if (sent.length) add('Mail sent', `${number(sent.length)} kept, the last ${clock.format((Number(sent.at(-1).at) || 0) * 1000)}`);
    }
    const transfer = transfers.cardLine(character);
    if (transfer) add('Transfer', transfer.text);
    if (character.note) add('Note', character.note);
    const actions = make('div', 'detail-actions');
    const button = (label, primary, run) => {
      const node = make('button', primary ? 'gb-button--primary' : '', label);
      node.type = 'button';
      node.addEventListener('click', run);
      actions.append(node);
    };
    if (!character.notSaved) {
      button('Show this character\u2019s items', true, () => {
        byId('character-panel').close();
        roster.setScope([character.key]);
        showTab('bank');
      });
    }
    button(roster.isSelected(key) ? 'Unselect' : 'Select', false, () => {
      roster.toggle(key);
      byId('character-panel').close();
    });
    if (!character.notSaved) {
      button(character.note ? 'Edit note…' : 'Add note…', false, () => {
        byId('character-panel').close();
        editNote(character);
      });
      button('Stop tracking…', false, () => {
        byId('character-panel').close();
        stopTracking(character);
      });
    }
    const panel = byId('character-panel');
    const side = make('div', 'character-details');
    side.append(hero, metrics, details, actions);
    const body = byId('character-panel-body');
    body.className = 'character-panel-body';
    const tip = profileTip(make);
    body.replaceChildren(characterProfile(character, make, tip), side, tip.node);
    panel.classList.add('has-profile');
    panel.showModal();
  }
  Object.assign(views, {
    bank: () => bank.show(),
    favourites: () => bank.renderFavourites(),
    currencies: () => GBBank.renderCurrencies(byId('currency-view'), roster.shown(), tableOptions('currency')),
    characters: () => {
      renderRosterCounts();
      if (rosterFilter === 'excluded') drawExcluded();
      else if (rosterFilter === 'transfers') drawTransfers();
      else GBBank.renderRoster(byId('roster-view'), rosterShown(), tableOptions('roster'));
    },
    stats: () => GBBank.renderStats(byId('tab-stats'), roster.shown(), {data: {entries: bank.shownEntries()}, all: bank.entries(), tooltip: byId('bank-tooltip'),
      classColor: GBAccounts.classColor, menu: accounts.openMenu, storage: chrome.storage.local}),
    heatmap: () => accounts.refresh('heatmap'),
    accounts: () => accounts.refresh('accounts'),
    servers: () => renderServers(),
    mail: () => {
      renderMailCount();
      GBMail.render(byId('tab-mail'), roster.shown(), {search: byId('mail-search').value, gold: GBBank.formatCompact});
    },
  });
  let mailTyping = 0;
  byId('mail-search').addEventListener('input', () => {
    clearTimeout(mailTyping);
    mailTyping = setTimeout(() => changed(['mail']), 150);
  });
  // The logo: back to the Bank as it first opens, with no characters selected, no scope and no filters. The region
  // stays, and every one of its servers shows again.
  byId('brand-home').addEventListener('click', event => {
    event.preventDefault();
    roster.clearSelection();
    roster.clearScope();
    if (roster.view.serversOff.size) roster.setView(roster.view.region);
    bank.resetFilters();
    bank.closePanel();
    showTab('bank');
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
      if (prefix === 'roster') showSinglesSwitch();
      changed([tab]);
    });
  }
  // Characters page, grouped by account: accounts with one character can go without a heading, kept in this Chrome
  const showSinglesSwitch = () => { byId('roster-singles-wrap').hidden = byId('roster-group').value !== 'account'; };
  showSinglesSwitch();
  chrome.storage.local.get('rosterSingles').then(({rosterSingles}) => {
    byId('roster-singles').checked = rosterSingles === true;
    if (rosterSingles === true) changed(['characters']);
  }).catch(() => {});
  byId('roster-singles').addEventListener('change', event => {
    chrome.storage.local.set({rosterSingles: event.target.checked}).catch(() => {});
    changed(['characters']);
  });
  roster.onChange(what => {
    if (what === 'card') return;
    renderSelectionBar();
    if (what === 'scope') return;
    if (what === 'view') {
      renderViewBar();
      renderSavedData();
      renderMailCount();
      accounts.redraw();
      changed(['favourites', 'currencies', 'stats', 'characters', 'servers', 'mail']);
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
    stones: GBBank.transferStonesText,
    transfer: character => transfers.cardLine(character),
    mail: mailLine,
    menu: accounts.openMenu,
    rows: character => characterRows(character),
    // The note first, then what goes for all the characters selected with it
    bulk: character => [...(character.notSaved ? [] : [{label: character.note ? 'Edit note…' : 'Add note…', run: () => editNote(character)}]), ...bulkRows(character)],
  });

  // A small form for one value: a new name, or a server from a list. Resolves to the text, to '' for its Clear
  // button, or to null when cancelled. With noField it's a question, and resolves to '' for yes.
  const dialog = byId('edit-dialog');
  let answer = null, checker = null;
  function ask({title, hint = '', label = '', value = '', choices = null, clear = '', check = null, placeholder = '', noField = false, save = 'Save', cancel = 'Cancel'}) {
    if (answer) answer(null);
    byId('edit-title').textContent = title;
    byId('edit-hint').textContent = hint;
    byId('edit-label').textContent = label;
    byId('edit-label').hidden = noField;
    byId('edit-error').textContent = '';
    byId('edit-save').textContent = save;
    byId('edit-cancel').textContent = cancel;
    const input = byId('edit-value'), choice = byId('edit-choice');
    input.hidden = !!choices || noField;
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
    else if (noField) byId('edit-cancel').focus();
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
    const text = byId('edit-value').hidden && byId('edit-choice').hidden ? '' : (byId('edit-choice').hidden ? byId('edit-value').value : byId('edit-choice').value).trim();
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

  // Names copied for pasting elsewhere: "A, B, C", or one a line
  async function copyNames(list, separator, note = null) {
    const names = [...new Set(list.map(character => character.name))];
    const how = separator === '\n' ? 'one a line' : 'comma separated';
    try {
      await navigator.clipboard.writeText(names.join(separator));
      (note ? text => { note.textContent = text; } : toast)(`Copied ${number(names.length)} ${names.length === 1 ? 'name' : 'names'}, ${how}.`);
    } catch (error) {
      (note ? text => { note.textContent = text; } : toast)('Could not copy: ' + String(error.message || error));
    }
  }
  // Right-click on one of several selected characters, above its logins: the same for all of them
  function bulkRows(character) {
    const picked = roster.selectedAll();
    if (!roster.isSelected(character.key) || picked.length < 2) return [];
    const count = number(picked.length);
    const saved = picked.filter(member => !member.notSaved);
    const rows = [];
    if (saved.length) {
      rows.push({label: `View these ${number(saved.length)} characters’ bank`, run: () => {
        roster.setScope(saved.map(member => member.key));
        showTab('bank');
        toast(`The Bank now shows these ${number(saved.length)} characters’ items.`);
      }});
    }
    rows.push({label: `Copy the ${count} names, comma separated`, run: () => copyNames(picked, ', ')});
    rows.push({label: `Copy the ${count} names, one a line`, run: () => copyNames(picked, '\n')});
    const accountKeys = new Set();
    for (const member of picked) for (const other of roster.romAccount(member)?.characters || []) if (other.key) accountKeys.add(other.key);
    const more = [...accountKeys].filter(key => !roster.isSelected(key));
    if (more.length) rows.push({label: `Select the rest of their RoM accounts (${number(more.length)} more)`, run: () => roster.setSelection([...roster.selection, ...more])});
    rows.push({label: `Link the ${count} to a Gameforge account…`, run: () => showTab('accounts')});
    rows.push({label: `Unselect all ${count}`, run: () => roster.clearSelection()});
    return rows;
  }
  // Right-click on a character, below its logins: its RoM account, its Gameforge account, and its server
  function characterRows(character) {
    const rows = [{label: 'Details…', run: () => openCharacter(character.key)}];
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
    if (!character.notSaved) rows.push({label: 'Stop tracking…', run: () => stopTracking(character)});
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
    transfers.stored(changes);
  });
  // The status line and the toggle
  const statusHelper = byId('status-helper');
  const autoHelper = byId('auto-helper');
  // Helper state, for the top of the page. It says nothing about the saved data, which is readable either way.
  function showHelperState(state, text, more = '') {
    statusHelper.textContent = text;
    byId('status-helper-chip').dataset.state = state;
    byId('status-helper-chip').title = more || 'Helper settings';
    byId('connection-dot').dataset.state = state;
    byId('connection-dot').title = text;
  }
  async function refreshStatus() {
    try {
      const info = await send({type:'helper-info'});
      if (info.stopping) {
        showHelperState('busy', 'Helper stopping…');
      } else if (!info.running) {
        showHelperState('stopped', 'Helper stopped', 'The helper is stopped. Your saved data is still readable.');
      } else {
        const ran = info.since ? ` · ${GBBank.formatDuration((Date.now() - Date.parse(info.since)) / 1000)}` : '';
        const how = info.auto ? (info.hidden === false ? 'Started automatically, with its window.' : 'Started automatically, in the background.') : 'Running in its own window.';
        showHelperState('running', `Helper running${ran}`, how);
      }
      // Older helper files don't say their version.
      if ((Number(info.bridge) || 0) < 6) showHelperState('error', 'Helper files out of date', 'Its files are older than this extension: update Cherry\u2019s Kit, then run Install Chrome extension.bat again.');
    } catch (error) {
      if (await GBFolders.usable('saves').catch(() => null)) showHelperState('stopped', 'Reading your folders', 'The helper isn\u2019t installed on this PC. The Bank page is reading your chosen folders.');
      else showHelperState('error', 'Helper not set up', 'Cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder, or choose your folders under Connection.');
    }
  }
  const showTerminal = byId('show-terminal');
  chrome.storage.local.get('autoHelper').then(({autoHelper: on}) => { autoHelper.checked = !!on; });
  chrome.storage.local.get('showTerminal').then(({showTerminal: on}) => { showTerminal.checked = !!on; });
  autoHelper.addEventListener('change', async () => {
    const on = autoHelper.checked;
    autoHelper.disabled = true;
    showHelperState('busy', on ? 'Helper starting…' : 'Helper stopping…');
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
      checkHelper();
    }
  });
  showTerminal.addEventListener('change', async () => {
    const on = showTerminal.checked;
    showTerminal.disabled = true;
    try {
      await chrome.storage.local.set({showTerminal: on});
      // A running automatic helper keeps the look it started with, so it restarts with the new one. A stopped helper
      // just starts with it next time, and one you started yourself is left alone.
      const info = await send({type:'helper-info'});
      if (info.running && info.auto) {
        showHelperState('busy', on ? 'Showing the helper\u2019s window…' : 'Hiding the helper\u2019s window…');
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
  // Game windows: the local host cascades them when the button is pressed, with the choice stored here.
  const cascadeCorner = byId('cascade-corner'), cascadeFit = byId('cascade-fit');
  const cascadeMonitor = byId('cascade-monitor'), cascadeSize = byId('cascade-size'), cascadeTop = byId('cascade-top');
  const cascadeStatus = byId('cascade-status');
  const cascadeWidth = byId('cascade-width'), cascadeHeight = byId('cascade-height'), cascadeStepX = byId('cascade-step-x'), cascadeStepY = byId('cascade-step-y');
  // Exact pixels, or 0 for automatic.
  const pixels = (input, most) => { const n = Math.floor(Number(input.value)); return input.value !== '' && n > 0 && n <= most ? n : 0; };
  const cascadeChoice = () => ({monitor: Math.max(0, Math.floor(Number(cascadeMonitor.value)) || 0), onTop: cascadeTop.checked, corner: cascadeCorner.value === 'top-left' ? 'top-left' : 'bottom-left', fit: cascadeFit.checked,
    width: pixels(cascadeWidth, 16000), height: pixels(cascadeHeight, 16000), stepX: pixels(cascadeStepX, 1000), stepY: pixels(cascadeStepY, 1000)});
  const showCascade = value => {
    cascadeCorner.value = value?.corner === 'top-left' ? 'top-left' : 'bottom-left';
    cascadeFit.checked = value?.fit !== false;
    cascadeTop.checked = value?.onTop === true;
    const monitor = Number.isInteger(value?.monitor) && value.monitor > 0 ? String(value.monitor) : '0';
    if ([...cascadeMonitor.options].some(item => item.value === monitor)) cascadeMonitor.value = monitor;
    cascadeMonitorChosen = Number(monitor);
    for (const [input, key] of [[cascadeWidth, 'width'], [cascadeHeight, 'height'], [cascadeStepX, 'stepX'], [cascadeStepY, 'stepY']]) {
      if (document.activeElement !== input) input.value = value?.[key] > 0 ? String(value[key]) : '';
    }
    showCascadeSize(cascadeSize, cascadeWidth.value, cascadeHeight.value);
  };
  let cascadeMonitorChosen = 0, cascadeMonitors = null;
  const fillCascade = () => fillCascadeLists(cascadeMonitor, cascadeSize, cascadeMonitors, cascadeMonitorChosen, cascadeWidth.value, cascadeHeight.value);
  chrome.storage.local.get('windowCascade').then(({windowCascade}) => { showCascade(windowCascade); fillCascade(); }).catch(() => {});
  // The displays come from the local host; without it the lists offer plain numbers and common screens.
  send({type:'windows-monitors'}).then(response => { cascadeMonitors = response.monitors; fillCascade(); }).catch(() => fillCascade());
  cascadeSize.addEventListener('change', () => {
    const [width, height] = cascadeSize.value.split('x').map(Number);
    if (!width || !height) return;
    cascadeWidth.value = String(width);
    cascadeHeight.value = String(height);
    chrome.storage.local.set({windowCascade: cascadeChoice()}).catch(() => {});
  });
  chrome.storage.onChanged.addListener((changes, area) => { if (area === 'local' && changes.windowCascade) showCascade(changes.windowCascade.newValue); });
  // Resolution typed by hand: the Size list goes back to "Pick a screen".
  for (const input of [cascadeWidth, cascadeHeight]) input.addEventListener('input', () => showCascadeSize(cascadeSize, cascadeWidth.value, cascadeHeight.value));
  for (const input of [cascadeMonitor, cascadeTop, cascadeCorner, cascadeFit, cascadeWidth, cascadeHeight, cascadeStepX, cascadeStepY]) {
    input.addEventListener('change', () => chrome.storage.local.set({windowCascade: cascadeChoice()}).catch(() => {}));
  }
  byId('cascade-now').addEventListener('click', async () => {
    const button = byId('cascade-now');
    button.disabled = true;
    cascadeStatus.textContent = 'Cascading\u2026 The first time, allow the Windows prompt.';
    try {
      const choice = cascadeChoice();
      await chrome.storage.local.set({windowCascade: choice});
      const result = await send({type:'windows-cascade', cascade: choice});
      const full = result.fullScreen ? ` ${result.fullScreen} in full-screen mode ${result.fullScreen === 1 ? 'was' : 'were'} left as ${result.fullScreen === 1 ? 'it is' : 'they are'}.` : '';
      const refused = result.refused ? ` Windows refused to move ${result.refused}: ${result.refused === 1 ? 'it runs' : 'they run'} as administrator. Press the button again and allow the Windows prompt.` : '';
      const missing = result.monitorMissing ? ` Display ${result.monitorMissing} isn\u2019t connected, so the oldest window\u2019s display was used.` : '';
      cascadeStatus.textContent = !result.found ? 'No Runes of Magic window is open.'
        : `Cascaded ${result.moved} game window${result.moved === 1 ? '' : 's'}.${full}${refused}${missing}`;
    } catch (error) {
      cascadeStatus.textContent = 'Could not cascade: ' + String(error.message || error);
    } finally {
      button.disabled = false;
    }
  });
  // The folders
  const foldersStatus = byId('folders-status');
  const allow = byId('folders-allow');
  const tryReload = () => bank.reload().then(() => bankStatus(''), error => {
    byId('folders').open = true;
    byId('status-data').textContent = 'No saved data read';
    // Nothing on the page works until one of those is done, so that's the first thing it shows
    openConnection();
    bankStatus('Cannot read your saved data. Choose your folders under Connection, or run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error));
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
      bankStatus('Chrome needs your OK to read your folders again: press Allow access again under Connection.');
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
  // The saved region, ticks, selection and transfers first, so the first drawing already uses them
  Promise.all([roster.load().catch(() => {}), transfers.load().catch(() => {})]).finally(() => {
    renderSettings();
    renderViewBar();
    renderSelectionBar();
    renderTransferCount();
    tryReload();
  });
  // Coming back to this tab looks for new data, at most once a minute, and only reads it all when it changed.
  let lastLook = Date.now();
  document.addEventListener('visibilitychange', () => {
    if (document.hidden || Date.now() - lastLook < 60000) return;
    lastLook = Date.now();
    bank.reload({ifChanged: true}).catch(error => bankStatus('Could not read new data: ' + String(error.message || error)));
  });

  // The Terminal page: the helper's own commands and live updates, in its own words
  let terminalReload = 0;
  terminal = GBTerminal.create({
    // Many updates in a row read the data once
    onChanged() {
      clearTimeout(terminalReload);
      terminalReload = setTimeout(() => bank.reload({ifChanged: true}).catch(error => bankStatus('Could not read new data: ' + String(error.message || error))), 1500);
    },
    savedTotals() {
      const all = roster.characters();
      return all.length ? {characters: all.length, gold: all.reduce((sum, character) => sum + (Number(character.gold) || 0), 0)} : null;
    },
    onHelper: () => refreshStatus(),
    toast,
    startHelper,
  });
  // New saves reach the Stats page and every other tab, not only while the Terminal shows
  terminal.watch(true);
  terminal.catalogue().then(reply => { if (reply.ok) byId('roster-count-excluded').textContent = number((reply.excluded || []).length); });
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

  // The panels at the side, and what opens them
  function openConnection(focus) {
    checkHelper();
    const panel = byId('connection-panel');
    if (!panel.open) panel.showModal();
    if (focus) byId(focus).focus();
  }
  byId('open-connection').addEventListener('click', () => openConnection());
  byId('status-helper-chip').addEventListener('click', () => openConnection());
  byId('open-page-settings').addEventListener('click', () => byId('page-settings').showModal());
  byId('gf-open-unlock').addEventListener('click', () => openConnection('gf-unlock-password'));
  document.querySelectorAll('[data-close-dialog]').forEach(button => button.addEventListener('click', () => button.closest('dialog').close()));
  document.querySelectorAll('.drawer').forEach(drawer => drawer.addEventListener('click', event => { if (event.target === drawer) drawer.close(); }));
  byId('status-accounts').addEventListener('click', () => {
    if (accountState === 'locked') openConnection('gf-unlock-password');
    else showTab('accounts');
  });
  // A menu closes when you click anywhere else, or press Escape
  document.addEventListener('click', event => {
    for (const menu of document.querySelectorAll('.bank-menu[open], .server-pick[open]')) if (!menu.contains(event.target)) menu.open = false;
  });
  // / goes to the open page's search. Escape closes what's open.
  const SEARCHES = {bank: 'bank-search', currencies: 'currency-search', stats: 'stat-search', characters: 'roster-search', accounts: 'gf-filter', servers: 'server-search',
    macros: 'macro-search', depot: 'depot-search', auctions: 'auction-search', terminal: 'term-input', mail: 'mail-search'};
  document.addEventListener('keydown', event => {
    if (document.querySelector('dialog[open]')) return;
    if (event.key === 'Escape') {
      const menu = document.querySelector('.bank-menu[open], .server-pick[open]');
      if (menu) {
        menu.open = false;
        menu.querySelector('summary')?.focus();
      } else if (currentTab === 'bank' && !byId('item-panel').hidden) bank.closePanel();
      return;
    }
    if (event.key !== '/' || event.ctrlKey || event.altKey || event.metaKey || event.target.closest?.('input, textarea, select, [contenteditable]')) return;
    const search = SEARCHES[currentTab] && byId(SEARCHES[currentTab]);
    if (search && !search.closest('[hidden]')) {
      event.preventDefault();
      search.focus();
      search.select?.();
    }
  });
  byId('page-version').textContent = 'Version ' + chrome.runtime.getManifest().version;
  // The page you were on comes back after a reload
  const firstPage = location.hash.slice(1);
  showTab(document.querySelector(`[data-tab="${CSS.escape(firstPage)}"]`) ? firstPage : 'bank');
  window.addEventListener('hashchange', () => {
    const page = location.hash.slice(1);
    if (page !== currentTab && document.querySelector(`[data-tab="${CSS.escape(page)}"]`)) showTab(page);
  });
})();
