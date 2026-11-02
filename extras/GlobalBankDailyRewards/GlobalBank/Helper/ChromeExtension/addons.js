'use strict';
// The Addons page: what is in Interface\AddOns, updates from the latest Cherry's Kit release on GitHub, and
// offload (a move to Interface\offloaded_addons that Restore undoes) and delete (to the Recycle Bin).
// The bridge does the work; installs and updates run in a window of their own with the guided setup's checks.
const GBAddons = (() => {
  const STATE_TEXT = {current: 'Up to date', update: 'Update available', missing: 'Not installed', offloaded: 'Offloaded',
    newer: 'Newer than the release', unknown: 'Not checked yet', extra: 'Not in the release', superseded: 'Replaced', curseforge: 'CurseForge copy'};
  const stateText = row => row.state === 'superseded' && row.by ? `Replaced by ${row.by}` : STATE_TEXT[row.state] || row.state;
  const OLD_BRIDGE = /Invalid reward record|Unknown addons request/;

  function el(tag, properties = {}, ...children) {
    const node = Object.assign(document.createElement(tag), properties);
    node.append(...children.filter(child => child !== null && child !== undefined && child !== false));
    return node;
  }
  const size = bytes => bytes >= 1048576 ? `${(bytes / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(bytes / 1024))} KB`;
  function when(stamp) {
    const time = new Date(stamp).getTime();
    return Number.isFinite(time) ? new Date(time).toLocaleString() : '';
  }

  // One row per kit addon: what is installed, what the release has, and what is offloaded, joined by folder.
  function kitRows(list, check) {
    const rows = [];
    const byFolder = new Map();
    const packages = check?.packages || [];
    const hub = packages.find(item => item.package === 'Hub');
    if (list?.hasKit) {
      rows.push({key: 'Hub', title: 'Cherry’s Kit hub', folder: '', installed: list.hubVersion || '', latest: hub?.latest || '',
        state: hub ? hub.state : 'unknown', package: 'Hub', bytes: hub?.bytes || 0, hub: true, note: list.kitVersion ? `Kit ${list.kitVersion}` : ''});
    }
    for (const addon of list?.kit || []) {
      const row = {key: addon.folder, title: addon.title || addon.folder, folder: addon.folder, installed: addon.version || '', latest: '',
        state: check ? 'extra' : 'unknown', keep: addon.keep || '', where: 'kit'};
      // A leftover folder of an addon that was merged into another one
      const by = replacedBy(list, addon.folder);
      if (by && by.owner !== addon.folder) Object.assign(row, {state: 'superseded', by: by.title, byPackage: by.owner});
      rows.push(row);
      byFolder.set(addon.folder, row);
    }
    const offloaded = new Map((list?.offloaded || []).filter(entry => entry.from === 'kit').map(entry => [entry.folder, entry]));
    for (const item of packages) {
      // The mail addons' own folder ones (zMail) have the Mail panel instead
      if (item.package === 'Hub' || item.external) continue;
      const row = byFolder.get(item.folder);
      if (row) {
        Object.assign(row, {latest: item.latest, state: row.state === 'superseded' ? 'superseded' : item.state, by: item.by || row.by || '',
          byPackage: item.byPackage || row.byPackage || '', package: item.package, bytes: item.bytes, title: item.title || row.title});
        continue;
      }
      const entry = offloaded.get(item.folder);
      // Replaced and not here: nothing to track, the page names it once below the table instead
      if (item.state === 'superseded' && !entry) continue;
      rows.push({key: item.folder, title: item.title, folder: item.folder, installed: entry?.version || '', latest: item.latest,
        state: entry && item.state !== 'superseded' ? 'offloaded' : item.state, by: item.by || '', byPackage: item.byPackage || '', package: item.package, bytes: item.bytes,
        offloaded: entry?.id || item.offloaded || ''});
      offloaded.delete(item.folder);
    }
    // Offloaded with no release to compare against yet
    for (const entry of offloaded.values()) {
      if (byFolder.has(entry.folder)) continue;
      rows.push({key: entry.folder, title: entry.title || entry.folder, folder: entry.folder, installed: entry.version || '', latest: '',
        state: 'offloaded', offloaded: entry.id});
    }
    return rows;
  }
  // What sits in offloaded_addons that isn't a kit addon Global Bank moved there: older copies the setup moved, other addons.
  const otherOffloaded = list => (list?.offloaded || []).filter(entry => entry.from !== 'kit');
  // What replaced a folder, from the kit's own origin list: {owner: kit folder, title}. Windows names ignore case.
  function replacedBy(list, folder) {
    const map = list?.replaced || {};
    const key = Object.keys(map).find(name => name.toLowerCase() === String(folder).toLowerCase());
    return key ? map[key] : null;
  }
  // Addons the release still lists that the kit has replaced and that aren't here, grouped by what replaced them.
  function retired(check) {
    const groups = new Map();
    for (const item of check?.packages || []) {
      if (item.state !== 'superseded' || item.external) continue;
      if (!groups.has(item.by)) groups.set(item.by, []);
      groups.get(item.by).push(item.title || item.folder);
    }
    return [...groups].map(([by, titles]) => `${titles.join(', ')} (now ${by})`).join('; ');
  }
  // What the login screen panel says and offers.
  function loginState(screen) {
    if (!screen) return null;
    const action = screen.installer ? (screen.state === 'missing' ? 'Install login screen' : screen.state === 'update' ? 'Update login screen'
      : screen.state === 'other' ? 'Replace with LogNextChar’s login screen' : '') : '';
    const text = {
      missing: `There’s no login screen in Interface\\loginxml. The game only reads one from there, and running the game doesn’t put it there: ${
        screen.installer ? 'LogNextChar’s installer copies it (the button below, the guided setup, or LogNextChar\\Install login screen.bat), with the game closed.'
          : 'it comes with LogNextChar, so install LogNextChar first, then its installer copies it.'}`,
      other: `Interface\\loginxml holds a login screen that isn’t LogNextChar’s${screen.version ? ` (${screen.version})` : ''}.${screen.installer ? ' Replacing it keeps a copy in Interface\\offloaded_addons and keeps your saved logins.' : ''}`,
      update: `LogNextChar’s login screen ${screen.version} is in Interface\\loginxml; LogNextChar here is ${screen.lncVersion}. Update it with the game closed; saved logins stay.`,
      current: `LogNextChar’s login screen ${screen.version || ''} is in Interface\\loginxml and matches LogNextChar.`.replace('  ', ' '),
    }[screen.state] || '';
    return {text, action, good: screen.state === 'current'};
  }
  const MAIL_NAMES = {UMM: 'Ultimate Mail Mod', zMail: 'zMail'};
  // Which mail addon runs and what the Mail panel offers. "auto" is zMail when it's installed, as the hub decides.
  function mailState(mailbox) {
    if (!mailbox || (!mailbox.known && !mailbox.zmail)) return null;
    const running = mailbox.running || '';
    return {running, setting: mailbox.setting || '', offers: ['zMail', 'UMM'].filter(use => use !== running), known: !!mailbox.known};
  }
  const updatable = rows => rows.filter(row => row.state === 'update' && row.package);

  function create(send, {toast = () => {}} = {}) {
    const byId = id => document.getElementById(id);
    let list = null;
    let check = null;
    let busy = false;
    let polling = 0;

    const say = text => { byId('addons-status').textContent = text || ''; };
    const problem = error => {
      const text = String(error?.message || error);
      say(OLD_BRIDGE.test(text) ? 'The helper files on this PC are older than this page. Update Cherry’s Kit with its guided setup, then run Install Chrome extension.bat again.' : text);
    };

    async function load() {
      list = await send({type: 'addons-list'});
      draw();
      return list;
    }
    async function checkNow() {
      if (busy) return;
      busy = true;
      byId('addons-check').disabled = true;
      say('Asking GitHub for the latest release…');
      try {
        check = await send({type: 'addons-check'});
        await load();
        const count = updatable(kitRows(list, check)).length;
        say(check.ahead ? `This kit (${check.localKit}) is newer than the latest release (${check.latestKit}).`
          : count ? `${count} ${count === 1 ? 'update' : 'updates'} in release ${check.latestKit}.` : `Everything is up to date with release ${check.latestKit}.`);
      } catch (error) { problem(error); }
      finally { busy = false; byId('addons-check').disabled = false; }
    }
    function confirmInstall(rows) {
      const bytes = rows.reduce((total, row) => total + (Number(row.bytes) || 0), 0);
      const names = rows.map(row => `${row.title} ${row.latest}`).join(', ');
      const globalBank = rows.some(row => row.folder === 'GlobalBank') ? ' The Global Bank helper stops while its files change and starts again after.' : '';
      return window.confirm(`Download and install ${names} (${size(bytes)}) from GitHub? The old versions move to Interface\\offloaded_addons. A window opens to show the progress.${globalBank}`);
    }
    async function install(rows) {
      if (!rows.length || !confirmInstall(rows)) return;
      try {
        await send({type: 'addons-install', packages: rows.map(row => row.package)});
        say('Installing in its own window…');
        watchJob();
      } catch (error) { problem(error); }
    }
    // Switch [old] with [new]: the new one installs first if it isn't here, and only then does the old one move
    // to offloaded_addons, where Restore brings it back.
    async function switchTo(row, where, name, owner, title) {
      if ((list?.kit || []).some(addon => addon.folder === owner)) {
        if (!window.confirm(`Switch ${name} with ${title}? ${title} is already installed, so ${name} just moves to Interface\\offloaded_addons. Restore brings it back.`)) return;
        try {
          await send({type: 'addons-offload', where, name});
          say(`Switched ${name} with ${title}.${list.gameRunning ? ' The game is running: Reload UI for this to take effect.' : ''}`);
          await load();
        } catch (error) { problem(error); }
        return;
      }
      if (!check) await checkNow();
      if (!check) return;
      const item = check.packages.find(entry => entry.package === owner && entry.state !== 'superseded');
      if (!item) {
        say(`${title} isn’t in the latest release on GitHub (${check.latestKit}) yet, so it can’t be installed from here. Install it from the full kit ZIP, then switch.`);
        return;
      }
      if (!window.confirm(`Switch ${name} with ${title}? This downloads ${title} ${item.latest} (${size(Number(item.bytes) || 0)}) from GitHub in its own window. Once it is installed, ${name} moves to Interface\\offloaded_addons, and Restore brings it back.`)) return;
      try {
        await send({type: 'addons-install', packages: [owner], offload: [{where, name}]});
        say(`Switching ${name} with ${title} in its own window…`);
        watchJob();
      } catch (error) { problem(error); }
    }
    // The mail switch. To zMail: install it if it isn't here, then choose it. To Ultimate Mail Mod: install it if
    // needed, choose it, and move the zmail folder out, since zMail has no off switch of its own. Reload UI applies it.
    async function switchMail(use) {
      const mailbox = list?.mailbox || {};
      const name = MAIL_NAMES[use];
      const here = use === 'zMail' ? mailbox.zmail : mailbox.umm;
      const leaving = use === 'UMM' && mailbox.zmail ? ' The zmail folder moves to Interface\\offloaded_addons, and Restore brings it back.' : '';
      if (here) {
        if (!window.confirm(`Use ${name} for mail?${leaving} Reload UI in game for it to take effect.`)) return;
        try {
          await send({type: 'addons-mailbox', use});
          say(`The kit now uses ${name} for mail. Reload UI in game (or start it) to switch.`);
          await load();
        } catch (error) { problem(error); }
        return;
      }
      if (!check) await checkNow();
      if (!check) return;
      const item = check.packages.find(entry => entry.package === (use === 'zMail' ? 'zMail' : 'UltimateMailMod'));
      if (!item) {
        say(`${name} isn’t in the latest release on GitHub (${check.latestKit}) yet, so it can’t be installed from here.`);
        return;
      }
      if (!window.confirm(`Switch to ${name}? This downloads ${name} ${item.latest} (${size(Number(item.bytes) || 0)}) from GitHub in its own window, then uses it for mail.${leaving}`)) return;
      try {
        const request = {type: 'addons-install', packages: [item.package], mailbox: use};
        if (leaving) request.offload = [{where: 'addons', name: 'zmail'}];
        await send(request);
        say(`Switching to ${name} in its own window…`);
        watchJob();
      } catch (error) { problem(error); }
    }
    function drawLogin() {
      const login = loginState(list.loginScreen);
      byId('addons-login').hidden = !login;
      if (!login) return;
      byId('addons-login-text').textContent = login.text;
      byId('addons-login-text').className = login.good ? '' : 'settings-warning';
      byId('addons-login-actions').replaceChildren(...(login.action ? [button(login.action, async () => {
        if (!window.confirm(`${login.action}? LogNextChar’s installer runs in its own window. Close the game first; your saved logins stay, and anything it replaces is copied to Interface\\offloaded_addons.`)) return;
        try {
          await send({type: 'addons-loginscreen'});
          say('The login screen installer is running in its own window. Press Read the folder again when it’s done.');
        } catch (error) { problem(error); }
      }, {className: 'gb-button--primary gb-button--sm'})] : []));
    }
    function drawMail() {
      const box = byId('addons-mailbox');
      const mail = mailState(list.mailbox);
      box.hidden = !mail;
      if (!mail) return;
      const running = mail.running ? MAIL_NAMES[mail.running] : 'neither (not installed)';
      const where = list.mailbox.zmail ? `zMail ${list.mailbox.zmailVersion || '(a CurseForge copy)'} is in Interface\\AddOns\\zmail.` : '';
      byId('addons-mail-text').textContent = `Mail runs with ${running}${mail.setting === 'auto' ? ', chosen automatically' : ''}. ${where}`.trim();
      // zMail's own updates, from the kit's copy of it; a CurseForge copy updates through CurseForge
      const zmail = (check?.packages || []).find(item => item.external && item.package === 'zMail' && item.state === 'update');
      byId('addons-mail-actions').replaceChildren(
        ...(zmail ? [button(`Update zMail to ${zmail.latest}`, () => install([{...zmail, title: 'zMail'}]), {className: 'gb-button--primary gb-button--sm'})] : []),
        ...(mail.known ? mail.offers.map(use =>
          button(`Switch to ${MAIL_NAMES[use]}`, () => switchMail(use), {className: 'gb-button--sm'})) : [
          el('span', {className: 'hint', textContent: 'Update the hub to switch between them here.'})]));
    }
    // The install window writes how it went; the page asks until it's done.
    function watchJob() {
      clearTimeout(polling);
      polling = setTimeout(async () => {
        try {
          await load();
          const job = list.job;
          const age = job ? Date.now() - new Date(job.startedAt).getTime() : Infinity;
          if (job && (job.state === 'running' || (job.state === 'starting' && age < 60000))) { watchJob(); return; }
          if (job?.state === 'done') { toast(job.text || 'Installed.'); check = null; await checkNow(); }
        } catch (error) { problem(error); }
      }, 2500);
    }
    async function act(type, row, where, name) {
      try {
        const answer = await send({type, where, name});
        const verb = type === 'addons-offload' ? 'Offloaded' : type === 'addons-restore' ? 'Restored' : answer.recycled ? 'Moved to the Recycle Bin:' : 'Deleted';
        const later = answer.gameRunning ? ' The game is running: Reload UI (or restart it) for this to take effect.' : '';
        say(`${verb} ${row.title}.${later}`);
        await load();
      } catch (error) { problem(error); }
    }
    function remove(row, where, name) {
      const place = where === 'offloaded' ? 'Interface\\offloaded_addons' : where === 'kit' ? 'Cherry’s Kit' : 'Interface\\AddOns';
      if (!window.confirm(`Delete ${row.title} (${name}) from ${place}? It goes to the Recycle Bin, and its saved settings stay. Offload keeps it here to bring back instead.`)) return;
      act('addons-delete', row, where, name);
    }

    const button = (text, onClick, extra = {}) => {
      const node = el('button', {type: 'button', textContent: text, className: 'gb-button--sm', ...extra});
      node.addEventListener('click', event => { if (event.isTrusted !== false) onClick(); });
      return node;
    };
    const versionCell = (text, title) => el('td', {className: 'num', textContent: text || '—', title: title || ''});
    function kitActions(row) {
      const cell = el('td', {className: 'addons-actions'});
      if (row.state === 'update' && row.package) cell.append(button('Update from GitHub', () => install([row]), {className: 'gb-button--primary gb-button--sm'}));
      if (row.state === 'superseded' && row.where === 'kit' && row.byPackage) {
        cell.append(button(`Switch with ${row.by}`, () => switchTo(row, 'kit', row.folder, row.byPackage, row.by), {className: 'gb-button--primary gb-button--sm'}));
      }
      if (row.state === 'missing' && row.package) cell.append(button('Download and install', () => install([row]), {className: 'gb-button--primary gb-button--sm'}));
      if (row.state === 'offloaded' && row.offloaded) {
        cell.append(button('Restore', () => act('addons-restore', row, 'offloaded', row.offloaded)));
        cell.append(button('Delete', () => remove(row, 'offloaded', row.offloaded), {className: 'gb-button--ghost gb-button--sm'}));
      }
      if (row.where === 'kit') {
        if (row.keep) cell.append(el('span', {className: 'hint', textContent: 'Runs this page', title: row.keep}));
        else {
          cell.append(button('Offload', () => act('addons-offload', row, 'kit', row.folder), {title: 'Moves it to Interface\\offloaded_addons; Restore brings it back'}));
          cell.append(button('Delete', () => remove(row, 'kit', row.folder), {className: 'gb-button--ghost gb-button--sm'}));
        }
      }
      return cell;
    }
    function draw() {
      if (!list) return;
      byId('addons-game').textContent = list.gameRunning ? 'The game is running. Updates wait until it’s closed; offloading and deleting take effect after Reload UI.' : '';
      byId('addons-setup').textContent = list.setupProblem || '';
      const job = list.job;
      byId('addons-job').textContent = !job ? '' : job.state === 'running' || job.state === 'starting' ? 'An install is running in its own window…'
        : `Last install (${when(job.finishedAt || job.startedAt)}): ${job.state === 'stopped' ? 'its window was closed before it finished.' : job.text || job.state}`;
      drawMail();
      drawLogin();
      byId('addons-retired').textContent = check && retired(check) ? `No longer separate addons: ${retired(check)}.` : '';
      const rows = kitRows(list, check);
      const updates = updatable(rows);
      const all = byId('addons-update-all');
      all.hidden = updates.length < 2;
      all.textContent = `Update all (${updates.length})`;
      all.onclick = () => install(updates);
      byId('addons-kit-rows').replaceChildren(...(rows.length ? rows.map(row => el('tr', {className: ['missing', 'offloaded', 'superseded'].includes(row.state) ? 'is-muted' : ''},
        el('td', {}, el('strong', {textContent: row.title}), row.folder && row.folder !== row.title ? el('div', {className: 'hint', textContent: row.folder}) : null,
          row.note ? el('div', {className: 'hint', textContent: row.note}) : null),
        versionCell(row.installed), versionCell(row.latest),
        el('td', {}, el('span', {className: `addons-state is-${row.state}`, textContent: stateText(row)})),
        kitActions(row))) : [el('tr', {}, el('td', {colSpan: 5, className: 'hint', textContent: 'Cherry’s Kit is not in this AddOns folder.'}))]));
      // zmail shows in the Mail panel
      const others = (list.others || []).filter(addon => !(list.mailbox?.known && addon.folder.toLowerCase() === 'zmail'));
      byId('addons-other-rows').replaceChildren(...(others.length ? others.map(addon => {
        const row = {title: addon.title || addon.folder};
        const by = replacedBy(list, addon.folder);
        return el('tr', {},
          el('td', {}, el('strong', {textContent: row.title}), addon.title && addon.title !== addon.folder ? el('div', {className: 'hint', textContent: addon.folder}) : null,
            by ? el('div', {className: 'addons-state is-update', textContent: `Replaced by ${by.title} in Cherry’s Kit`}) : null),
          versionCell(addon.version),
          el('td', {className: 'addons-actions'},
            by ? button(`Switch with ${by.title}`, () => switchTo(row, 'addons', addon.folder, by.owner, by.title), {className: 'gb-button--primary gb-button--sm'}) : null,
            button('Offload', () => act('addons-offload', row, 'addons', addon.folder), {title: 'Moves it to Interface\\offloaded_addons; Restore brings it back'}),
            button(addon.link ? 'Remove link' : 'Delete', () => remove(row, 'addons', addon.folder), {className: 'gb-button--ghost gb-button--sm'})));
      }) : [el('tr', {}, el('td', {colSpan: 3, className: 'hint', textContent: 'No other addons.'}))]));
      const shelved = otherOffloaded(list);
      byId('addons-offloaded-rows').replaceChildren(...(shelved.length ? shelved.map(entry => {
        const row = {title: entry.title || entry.folder || entry.name};
        return el('tr', {},
          el('td', {}, el('strong', {textContent: entry.name}), entry.folder && entry.folder !== entry.name ? el('div', {className: 'hint', textContent: `was ${entry.folder}`}) : null),
          versionCell(entry.version),
          el('td', {textContent: entry.from === 'addons' ? `Offloaded here ${when(entry.at)}` : `Moved here ${when(entry.at)}`}),
          el('td', {className: 'addons-actions'},
            entry.from === 'addons' ? button('Restore', () => act('addons-restore', row, 'offloaded', entry.id)) : null,
            button('Delete', () => remove(row, 'offloaded', entry.id), {className: 'gb-button--ghost gb-button--sm'})));
      }) : [el('tr', {}, el('td', {colSpan: 4, className: 'hint', textContent: 'Nothing offloaded.'}))]));
    }

    byId('addons-check').addEventListener('click', event => { if (event.isTrusted) checkNow(); });
    byId('addons-refresh').addEventListener('click', event => { if (event.isTrusted) load().then(() => say(''), problem); });
    let shown = false;
    return {
      show() {
        if (shown) return;
        shown = true;
        say('Reading Interface\\AddOns…');
        load().then(() => {
          say('');
          const job = list.job;
          if (job && (job.state === 'running' || job.state === 'starting')) watchJob();
        }, error => { shown = false; problem(error); });
      },
    };
  }
  return {create, kitRows, otherOffloaded, updatable, replacedBy, mailState, retired, loginState};
})();
