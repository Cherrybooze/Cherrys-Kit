'use strict';
// The Gold heatmap and Gameforge accounts tabs, and the right-click menu for copying logins.
// Accounts, passwords and links only exist in the clear in this page's memory while unlocked. What's kept is
// encrypted: GameforgeAccounts.json beside the helper's other files, and a copy in Chrome. Opening it takes both
// a random key, which stays in Chrome's storage for this extension's own pages, and the player's password, which
// is never kept. Only the encrypted file ever reaches the local host. Characters are only linked by hand.
const GBAccounts = (() => {
  const KEY_STORE = 'gfKey';
  const FILE_STORE = 'gfSealed';
  const ITERATIONS = 600000;
  const PART = 300000;
  const FULL_CAP = 999999999;
  const HALF_CAP = 500000000;
  const RED = [198, 40, 40], ORANGE = [245, 124, 0], GREEN = [0, 230, 64];
  const NO_SERVER = 'Server unknown';
  const NO_ACCOUNT = 'No account';
  const MASK = '***';
  const MENU_OWNERS = 6;

  const toHex = bytes => Array.from(bytes, value => value.toString(16).padStart(2, '0')).join('');
  const fromHex = text => Uint8Array.from(text.match(/../g), pair => parseInt(pair, 16));
  const toBase64 = bytes => btoa(Array.from(bytes, value => String.fromCharCode(value)).join(''));
  const fromBase64 = text => Uint8Array.from(atob(text), letter => letter.charCodeAt(0));
  function newKey() {
    return toHex(crypto.getRandomValues(new Uint8Array(32)));
  }
  function cleanKey(text) {
    const key = String(text).replace(/\s+/g, '').toLowerCase();
    return /^[0-9a-f]{64}$/.test(key) ? key : null;
  }
  // The file's key comes from the password, with the random key and the file's own salt as PBKDF2's salt, so
  // the password alone, or the key and the file without the password, open nothing. It can't be exported.
  async function deriveKey(password, key, salt, iterations) {
    const material = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']);
    const random = fromHex(key);
    const mixed = new Uint8Array(random.length + salt.length);
    mixed.set(random);
    mixed.set(salt, random.length);
    return crypto.subtle.deriveKey({name: 'PBKDF2', hash: 'SHA-256', salt: mixed, iterations}, material, {name: 'AES-GCM', length: 256}, false, ['encrypt', 'decrypt']);
  }
  async function seal(data, fileKey, salt, iterations) {
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const sealed = await crypto.subtle.encrypt({name: 'AES-GCM', iv}, fileKey, new TextEncoder().encode(JSON.stringify(data)));
    return {schema: 1, kdf: 'PBKDF2-SHA256', iterations, salt: toBase64(salt), iv: toBase64(iv), data: toBase64(new Uint8Array(sealed)), saved: Date.now()};
  }
  // Fails with a wrong password or key, or a changed file.
  async function unseal(file, fileKey) {
    const plain = await crypto.subtle.decrypt({name: 'AES-GCM', iv: fromBase64(file.iv)}, fileKey, fromBase64(file.data));
    return JSON.parse(new TextDecoder().decode(plain));
  }
  function validFile(file) {
    return !!file && file.schema === 1 && Number.isInteger(file.iterations) && file.iterations > 0
      && typeof file.salt === 'string' && typeof file.iv === 'string' && typeof file.data === 'string';
  }
  // Red at no gold, orange at exactly half a cap, bright green at a full cap, and a gradient between
  function heatColor(gold) {
    const amount = Math.max(0, Math.min(FULL_CAP, Number(gold) || 0));
    const [from, to, part] = amount <= HALF_CAP ? [RED, ORANGE, amount / HALF_CAP] : [ORANGE, GREEN, (amount - HALF_CAP) / (FULL_CAP - HALF_CAP)];
    const rgb = from.map((value, i) => Math.round(value + (to[i] - value) * part));
    const light = rgb[0] * 0.299 + rgb[1] * 0.587 + rgb[2] * 0.114 > 110;
    return {rgb, css: `rgb(${rgb.join(',')})`, text: light ? '#101820' : '#ffffff'};
  }
  // "Aynara (PvE)", as the shop writes it, and "Aynara", as the game does, are the same server.
  function serverOf(character) {
    const name = String(character.server || character.dailyLogin?.server || '').replace(/\s*\(.*\)\s*$/, '').trim();
    return name || NO_SERVER;
  }
  const linkKey = name => String(name).toLowerCase();
  function emptyState() {
    return {accounts: [], links: {}};
  }
  function accountOf(state, name) {
    const id = state.links[linkKey(name)];
    return id ? state.accounts.find(account => account.id === id) || null : null;
  }
  // Links, or with no ID unlinks, and says how many changed.
  function setLinks(state, names, id) {
    let changed = 0;
    for (const name of names) {
      const key = linkKey(name);
      if (!key.trim() || (state.links[key] || null) === (id || null)) continue;
      if (id) state.links[key] = id;
      else delete state.links[key];
      changed++;
    }
    return changed;
  }
  function removeAccount(state, id) {
    state.accounts = state.accounts.filter(account => account.id !== id);
    for (const key of Object.keys(state.links)) if (state.links[key] === id) delete state.links[key];
  }
  // Pasted names, one a line or split by commas, against the characters there are.
  function matchNames(text, characters) {
    const known = new Map(characters.map(character => [linkKey(character.name), character.name]));
    const found = new Set(), missing = [];
    for (const raw of String(text).split(/[\r\n,;]+/)) {
      const name = raw.trim();
      if (!name) continue;
      if (known.has(linkKey(name))) found.add(known.get(linkKey(name)));
      else missing.push(name);
    }
    return {found: [...found], missing};
  }
  // A column for each server: its full caps pooled together, then the rest by account, richest first.
  function heatColumns(characters, state, noAccount = NO_ACCOUNT) {
    const servers = new Map();
    for (const character of characters) {
      const server = serverOf(character);
      if (!servers.has(server)) servers.set(server, {server, total: 0, fullCaps: [], groups: new Map()});
      const column = servers.get(server);
      const gold = Number(character.gold) || 0;
      const account = accountOf(state, character.name)?.name || noAccount;
      const cell = {name: String(character.name), gold, account, server};
      column.total += gold;
      if (gold >= FULL_CAP) column.fullCaps.push(cell);
      else {
        if (!column.groups.has(account)) column.groups.set(account, []);
        column.groups.get(account).push(cell);
      }
    }
    const byGold = (a, b) => b.gold - a.gold || a.name.localeCompare(b.name);
    const last = (a, b, unwanted) => Number(a === unwanted) - Number(b === unwanted) || a.localeCompare(b);
    return [...servers.values()].sort((a, b) => last(a.server, b.server, NO_SERVER)).map(column => ({
      server: column.server, total: column.total, fullCaps: column.fullCaps.sort(byGold),
      groups: [...column.groups.entries()].sort((a, b) => last(a[0], b[0], noAccount)).map(([account, list]) => ({account, characters: list.sort(byGold)})),
    }));
  }
  const number = value => Number(value || 0).toLocaleString('en-US');

  function create(send) {
    const byId = id => document.getElementById(id);
    let state = emptyState();
    // Only while unlocked. The password itself is never held on to.
    let fileKey = null, fileSalt = null, fileIterations = ITERATIONS;
    let key = null, sealedFile = null;
    let saving = Promise.resolve();
    let characters = [];
    let reveal = false;
    const ticked = new Set();
    let lastTicked = null;
    const make = (tag, className, text) => {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    };
    const button = (label, run) => {
      const node = make('button', '', label);
      node.type = 'button';
      node.addEventListener('click', run);
      return node;
    };
    // Encrypted first, then to Chrome and to the file beside the helper's. Without the local host, Chrome's copy
    // and the backup button are what there is.
    function save() {
      if (!fileKey) return saving;
      const snapshot = structuredClone(state);
      saving = saving.then(async () => {
        sealedFile = await seal(snapshot, fileKey, fileSalt, fileIterations);
        await chrome.storage.local.set({[FILE_STORE]: sealedFile});
        await send({type: 'gf-save', text: JSON.stringify(sealedFile)}).catch(() => {
          byId('gf-status').textContent = 'Saved in Chrome. The helper\'s folder couldn\'t be reached, so use the backup button to move these to another PC.';
        });
      }).catch(error => { byId('gf-status').textContent = `Could not save: ${error.message || error}`; });
      return saving;
    }
    async function readFile() {
      let text = '';
      for (;;) {
        const response = await send({type: 'gf-load', offset: text.length});
        text += response.json || '';
        if (!response.json || text.length >= response.total) break;
      }
      const file = text ? JSON.parse(text) : null;
      return validFile(file) ? file : null;
    }
    function renderLock() {
      const locked = !fileKey && !!sealedFile && !!key;
      byId('gf-unlock').hidden = !locked;
      byId('gf-setup').hidden = !!sealedFile;
      byId('gf-need-key').hidden = !sealedFile || !!key;
      byId('gf-locked-note').hidden = !locked;
      byId('gf-open').hidden = !fileKey;
    }
    function lock() {
      fileKey = null;
      fileSalt = null;
      state = emptyState();
      reveal = false;
      byId('gf-reveal').checked = false;
      ticked.clear();
      closeMenu();
      renderLock();
      renderAll();
    }
    async function copy(text) {
      await navigator.clipboard.writeText(text);
    }

    // The right-click menu stays open after copying, so the account name and then the password are two clicks.
    function closeMenu() {
      byId('gf-menu').hidden = true;
    }
    function copyRow(label, text) {
      const row = button(label, async () => {
        await copy(text).catch(() => {});
        row.textContent = `${label}: copied`;
      });
      row.disabled = !text;
      return row;
    }
    function ownerRows(menu, name, heading) {
      const account = accountOf(state, name);
      if (heading) menu.append(make('strong', '', name));
      menu.append(copyRow('Copy character name', name), copyRow('Copy Gameforge account name', account?.name || ''),
        copyRow('Copy password', account?.password || ''), copyRow('Copy secondary password', account?.secondary || ''));
      if (!account) menu.append(make('span', 'hint', fileKey ? 'Not linked to a Gameforge account yet.' : 'Unlock your Gameforge accounts to copy logins.'));
    }
    function openMenu(event, extra, names) {
      event.preventDefault();
      const menu = byId('gf-menu');
      menu.replaceChildren();
      for (const row of extra) menu.append(button(row.label, () => { closeMenu(); row.run(); }));
      const owners = [...new Set(names)];
      for (const name of owners.slice(0, MENU_OWNERS)) ownerRows(menu, name, owners.length > 1 || extra.length > 0);
      if (owners.length > MENU_OWNERS) menu.append(make('span', 'hint', `and ${owners.length - MENU_OWNERS} more`));
      menu.hidden = false;
      menu.style.left = Math.max(4, Math.min(event.clientX, window.innerWidth - menu.offsetWidth - 8)) + 'px';
      menu.style.top = Math.max(4, Math.min(event.clientY, window.innerHeight - menu.offsetHeight - 8)) + 'px';
    }

    function renderHeat() {
      const tip = byId('heat-tooltip');
      const cellFor = cell => {
        const color = heatColor(cell.gold);
        const node = make('div', 'heat-cell', cell.name);
        node.style.background = color.css;
        node.style.color = color.text;
        node.addEventListener('mouseenter', () => {
          tip.replaceChildren(make('strong', '', cell.name), make('span', '', `${number(cell.gold)} gold`), make('span', 'hint', `${cell.account} · ${cell.server}`));
          tip.hidden = false;
        });
        node.addEventListener('mousemove', event => {
          tip.style.left = Math.min(event.clientX + 14, window.innerWidth - 260) + 'px';
          tip.style.top = Math.min(event.clientY + 14, window.innerHeight - tip.offsetHeight - 8) + 'px';
        });
        node.addEventListener('mouseleave', () => { tip.hidden = true; });
        node.addEventListener('contextmenu', event => { tip.hidden = true; openMenu(event, [], [cell.name]); });
        return node;
      };
      const block = (title, cells) => {
        const box = make('div', 'heat-group');
        box.append(make('h3', '', title));
        const list = make('div', 'heat-cells');
        list.append(...cells.map(cellFor));
        box.append(list);
        return box;
      };
      const columns = heatColumns(characters, state, !fileKey && sealedFile ? 'Accounts locked' : NO_ACCOUNT);
      byId('heat-view').replaceChildren(...columns.map(column => {
        const node = make('section', 'heat-column');
        node.append(make('h2', '', column.server));
        node.append(make('p', 'hint', `${number(column.total)} gold · ${column.fullCaps.length} full caps`));
        if (column.fullCaps.length) node.append(block(`Full caps (${column.fullCaps.length})`, column.fullCaps));
        for (const group of column.groups) node.append(block(group.account, group.characters));
        return node;
      }));
      if (!columns.length) byId('heat-view').append(make('p', 'hint', 'No characters saved yet.'));
    }

    function renderAccounts() {
      const body = byId('gf-account-rows');
      const counts = {};
      for (const id of Object.values(state.links)) counts[id] = (counts[id] || 0) + 1;
      body.replaceChildren(...state.accounts.map(account => {
        const row = make('tr');
        const secret = value => (!value ? '—' : reveal ? value : MASK);
        row.append(make('td', '', account.name), make('td', 'gf-password', secret(account.password)), make('td', 'gf-password', secret(account.secondary)),
          make('td', 'gf-notes', account.notes || ''), make('td', '', number(counts[account.id] || 0)));
        const actions = make('td', 'gf-actions');
        const copied = (node, label) => { node.textContent = `${label}: copied`; setTimeout(() => { node.textContent = label; }, 1500); };
        const copyAccount = button('Copy account', () => copy(account.name).then(() => copied(copyAccount, 'Copy account')));
        const copyPassword = button('Copy password', () => copy(account.password).then(() => copied(copyPassword, 'Copy password')));
        copyPassword.disabled = !account.password;
        const copySecondary = button('Copy secondary', () => copy(account.secondary).then(() => copied(copySecondary, 'Copy secondary')));
        copySecondary.disabled = !account.secondary;
        const edit = button('Edit', () => {
          const field = (type, value, label) => {
            const box = make('input');
            box.type = type;
            box.value = value || '';
            box.autocomplete = type === 'password' ? 'new-password' : 'off';
            box.placeholder = label;
            box.setAttribute('aria-label', label);
            return box;
          };
          const secretType = reveal ? 'text' : 'password';
          const password = field(secretType, account.password, 'Password');
          const secondary = field(secretType, account.secondary, 'Secondary password');
          const notes = field('text', account.notes, 'Notes');
          const set = button('Save', () => {
            account.password = password.value;
            account.secondary = secondary.value;
            account.notes = notes.value;
            save();
            renderAccounts();
          });
          actions.replaceChildren(password, secondary, notes, set, button('Cancel', renderAccounts));
          password.focus();
        });
        const remove = button('Delete', () => {
          if (!window.confirm(`Delete the Gameforge account ${account.name} and unlink its characters?`)) return;
          removeAccount(state, account.id);
          save();
          renderAll();
        });
        actions.append(copyAccount, copyPassword, copySecondary, edit, remove);
        row.append(actions);
        return row;
      }));
      const select = byId('gf-link-account');
      const chosen = select.value;
      select.replaceChildren(...state.accounts.map(account => {
        const option = make('option', '', account.name);
        option.value = account.id;
        return option;
      }));
      if (state.accounts.some(account => account.id === chosen)) select.value = chosen;
    }

    function shownCharacters() {
      const text = byId('gf-filter').value.trim().toLowerCase();
      const unlinked = byId('gf-unlinked').checked;
      return characters.filter(character => (!text || String(character.name).toLowerCase().includes(text)) && (!unlinked || !accountOf(state, character.name)));
    }
    function renderLinks() {
      const shown = shownCharacters();
      byId('gf-characters').replaceChildren(...shown.map((character, index) => {
        const row = make('label', 'gf-character');
        const box = make('input');
        box.type = 'checkbox';
        box.checked = ticked.has(character.name);
        // Shift-click ticks everything between this one and the last one clicked
        box.addEventListener('click', event => {
          const on = box.checked;
          const from = event.shiftKey && lastTicked !== null ? Math.min(lastTicked, index) : index;
          const to = event.shiftKey && lastTicked !== null ? Math.max(lastTicked, index) : index;
          for (let i = from; i <= to; i++) {
            if (on) ticked.add(shown[i].name);
            else ticked.delete(shown[i].name);
          }
          lastTicked = index;
          if (from !== to) renderLinks();
          else showTicked();
        });
        row.append(box, make('span', 'bank-name', character.name), make('span', 'bank-detail', `${serverOf(character)} · ${accountOf(state, character.name)?.name || NO_ACCOUNT}`));
        return row;
      }));
      showTicked();
    }
    function showTicked() {
      byId('gf-link-count').textContent = `${number(ticked.size)} ticked of ${number(shownCharacters().length)} shown`;
    }
    function link(names, id) {
      const changed = setLinks(state, names, id);
      save();
      byId('gf-status').textContent = `${number(changed)} characters ${id ? 'linked' : 'unlinked'}.`;
      renderAll();
    }
    function renderAll() {
      renderAccounts();
      renderLinks();
      renderHeat();
    }

    byId('gf-create').addEventListener('submit', async event => {
      event.preventDefault();
      const first = byId('gf-create-password'), second = byId('gf-create-again');
      const note = byId('gf-setup-status');
      if (first.value.length < 8) { note.textContent = 'Use at least 8 characters.'; return; }
      if (first.value !== second.value) { note.textContent = 'Those two passwords are different.'; return; }
      key = newKey();
      fileSalt = crypto.getRandomValues(new Uint8Array(16));
      fileIterations = ITERATIONS;
      fileKey = await deriveKey(first.value, key, fileSalt, fileIterations);
      first.value = second.value = '';
      note.textContent = '';
      await chrome.storage.local.set({[KEY_STORE]: key});
      state = emptyState();
      await save();
      renderLock();
      renderAll();
    });
    async function open(password) {
      const salt = fromBase64(sealedFile.salt);
      const trying = await deriveKey(password, key, salt, sealedFile.iterations);
      state = await unseal(sealedFile, trying);
      fileKey = trying;
      fileSalt = salt;
      fileIterations = sealedFile.iterations;
    }
    byId('gf-unlock').addEventListener('submit', async event => {
      event.preventDefault();
      const box = byId('gf-unlock-password');
      const note = byId('gf-unlock-status');
      note.textContent = 'Unlocking...';
      try {
        await open(box.value);
        note.textContent = '';
        box.value = '';
        renderLock();
        renderAll();
      } catch {
        note.textContent = 'That password doesn\'t open them.';
      }
    });
    byId('gf-lock').addEventListener('click', lock);
    byId('gf-key-form').addEventListener('submit', async event => {
      event.preventDefault();
      const given = cleanKey(byId('gf-key-input').value);
      if (!given) { byId('gf-key-status').textContent = 'That isn\'t an encryption key: it should be 64 letters and numbers.'; return; }
      key = given;
      byId('gf-key-input').value = '';
      byId('gf-key-status').textContent = '';
      await chrome.storage.local.set({[KEY_STORE]: key});
      renderLock();
      renderHeat();
    });
    byId('gf-copy-key').addEventListener('click', async () => {
      if (!fileKey) return;
      await copy(key);
      byId('gf-move-status').textContent = 'Encryption key copied. Keep it somewhere safe, and away from the helper\'s folder.';
    });
    byId('gf-backup').addEventListener('click', () => {
      const link = make('a');
      link.href = URL.createObjectURL(new Blob([JSON.stringify(sealedFile)], {type: 'application/json'}));
      link.download = 'GameforgeAccounts.json';
      link.click();
      URL.revokeObjectURL(link.href);
    });
    for (const id of ['gf-restore-new', 'gf-restore-key']) {
      byId(id).addEventListener('change', async event => {
        const status = byId(id === 'gf-restore-new' ? 'gf-setup-status' : 'gf-key-status');
        try {
          const file = JSON.parse(await event.target.files[0].text());
          if (!validFile(file)) throw new Error('not one of ours');
          sealedFile = file;
          await chrome.storage.local.set({[FILE_STORE]: file});
          await send({type: 'gf-save', text: JSON.stringify(file)}).catch(() => {});
          status.textContent = '';
          renderLock();
          renderHeat();
        } catch {
          status.textContent = 'That isn\'t a Gameforge accounts file.';
        }
        event.target.value = '';
      });
    }
    byId('gf-change').addEventListener('submit', async event => {
      event.preventDefault();
      const box = byId('gf-change-password');
      if (box.value.length < 8) { byId('gf-move-status').textContent = 'Use at least 8 characters.'; return; }
      fileSalt = crypto.getRandomValues(new Uint8Array(16));
      fileIterations = ITERATIONS;
      fileKey = await deriveKey(box.value, key, fileSalt, fileIterations);
      box.value = '';
      await save();
      byId('gf-move-status').textContent = 'Password changed.';
    });
    byId('gf-forgot').addEventListener('click', async () => {
      if (!window.confirm('There\'s no way to recover a forgotten password. Delete every Gameforge account saved here and start again? Your items, gold and characters are not affected.')) return;
      await chrome.storage.local.remove([KEY_STORE, FILE_STORE]);
      await send({type: 'gf-delete'}).catch(() => {});
      key = null;
      sealedFile = null;
      lock();
    });
    byId('gf-add').addEventListener('submit', event => {
      event.preventDefault();
      const name = byId('gf-new-name').value.trim();
      if (!name) return;
      if (state.accounts.some(account => account.name.toLowerCase() === name.toLowerCase())) {
        byId('gf-status').textContent = `${name} is already on the list.`;
        return;
      }
      state.accounts.push({id: crypto.randomUUID(), name, password: byId('gf-new-password').value, secondary: byId('gf-new-secondary').value, notes: byId('gf-new-notes').value.trim()});
      for (const id of ['gf-new-name', 'gf-new-password', 'gf-new-secondary', 'gf-new-notes']) byId(id).value = '';
      save();
      renderAccounts();
      byId('gf-link-account').value = state.accounts[state.accounts.length - 1].id;
      byId('gf-new-name').focus();
    });
    // Off every time the page opens, and never saved
    byId('gf-reveal').checked = false;
    byId('gf-reveal').addEventListener('change', event => {
      reveal = event.target.checked;
      byId('gf-new-password').type = byId('gf-new-secondary').type = reveal ? 'text' : 'password';
      renderAccounts();
    });
    byId('gf-filter').addEventListener('input', () => { lastTicked = null; renderLinks(); });
    byId('gf-unlinked').addEventListener('change', () => { lastTicked = null; renderLinks(); });
    byId('gf-tick-shown').addEventListener('click', () => {
      for (const character of shownCharacters()) ticked.add(character.name);
      renderLinks();
    });
    byId('gf-tick-none').addEventListener('click', () => { ticked.clear(); renderLinks(); });
    byId('gf-link').addEventListener('click', () => {
      if (!byId('gf-link-account').value) { byId('gf-status').textContent = 'Add a Gameforge account first.'; return; }
      link([...ticked], byId('gf-link-account').value);
      ticked.clear();
      renderLinks();
    });
    byId('gf-unlink').addEventListener('click', () => { link([...ticked], null); ticked.clear(); renderLinks(); });
    byId('gf-link-pasted').addEventListener('click', () => {
      if (!byId('gf-link-account').value) { byId('gf-status').textContent = 'Add a Gameforge account first.'; return; }
      const {found, missing} = matchNames(byId('gf-paste').value, characters);
      link(found, byId('gf-link-account').value);
      byId('gf-paste').value = missing.join('\n');
      if (missing.length) byId('gf-status').textContent += ` ${number(missing.length)} names aren't saved characters, so they're left in the box.`;
    });
    document.addEventListener('click', event => { if (!event.target.closest?.('#gf-menu')) closeMenu(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') closeMenu(); });

    // Whichever copy was saved last, and a copy left in the helper's folder is what a new PC starts from.
    (async () => {
      const stored = await chrome.storage.local.get([KEY_STORE, FILE_STORE]);
      key = stored[KEY_STORE] || null;
      const local = validFile(stored[FILE_STORE]) ? stored[FILE_STORE] : null;
      const inFolder = await readFile().catch(() => null);
      sealedFile = !inFolder || (local && local.saved >= inFolder.saved) ? local : inFolder;
      if (sealedFile && sealedFile !== local) await chrome.storage.local.set({[FILE_STORE]: sealedFile});
      if (sealedFile && !inFolder) await send({type: 'gf-save', text: JSON.stringify(sealedFile)}).catch(() => {});
    })().catch(() => {}).finally(() => {
      renderLock();
      renderAll();
    });
    return {
      setCharacters(list) { characters = list; renderAll(); },
      openMenu,
    };
  }
  return {create, heatColor, serverOf, accountOf, setLinks, removeAccount, matchNames, heatColumns, emptyState,
    newKey, cleanKey, deriveKey, seal, unseal, validFile};
})();
