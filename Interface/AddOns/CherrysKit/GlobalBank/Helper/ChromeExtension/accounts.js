'use strict';
// The Gold overview and Gameforge accounts pages, and the right-click menu for copying logins.
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
  // Red at no gold, orange at half a cap, bright green at a full cap, until you pick your own
  const HEAT_STORE = 'gbHeatColors';
  const HEAT_COLORS = ['#c62828', '#f57c00', '#00e640'];
  // How many letters of a name a tile shows: 0 is the whole name, and a tile is as wide as the longest one needs.
  // Below this many, a tile leaves out its gold too, and hovering still says it.
  const HEAT_LETTERS = 'gbHeatLetters';
  const HEAT_GOLD_FROM = 5;
  // The servers the Gold overview leaves out, and whether their names head their regions
  const HEAT_SERVERS = 'gbHeatServers';
  // Tiles on a line under an account: 8, 4, 2 or 1, so a full login screen's list is always a neat block, and as many
  // as fit this wide
  const HEAT_WIDEST_COLUMN = 200;
  const NO_SERVER = 'Unknown server';
  const NOT_LINKED = 'Not linked';
  const NO_ROM = 'Account not known';
  const MASK = '***';
  // Names one right-click menu lists (the rest are counted), and how long the pointer rests on another name
  // before its logins replace the open ones
  const MENU_OWNERS = 500;
  const SIDE_DELAY = 150;
  const collator = new Intl.Collator(undefined, {sensitivity: 'base', numeric: true});

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
  // A tile's colour for an amount of gold, with text that can be read on it
  function heatColor(gold, colors = HEAT_COLORS) {
    const amount = Math.max(0, Math.min(FULL_CAP, Number(gold) || 0));
    const kind = amount <= 0 ? 'none' : amount >= FULL_CAP ? 'full' : 'some';
    const [none, half, full] = colors.map(color => [1, 3, 5].map(at => parseInt(color.slice(at, at + 2), 16)));
    const [from, to, part] = amount <= HALF_CAP ? [none, half, amount / HALF_CAP] : [half, full, (amount - HALF_CAP) / (FULL_CAP - HALF_CAP)];
    const rgb = from.map((value, i) => Math.round(value + (to[i] - value) * part));
    const light = rgb[0] * 0.299 + rgb[1] * 0.587 + rgb[2] * 0.114 > 110;
    return {rgb, kind, css: `rgb(${rgb.join(',')})`, text: light ? '#101820' : '#ffffff'};
  }
  // What a tile says: a name that fits whole, otherwise the letters that tell it apart from the others on its account.
  // Bank alts often share a long start, so that's the letters after it, with the ones before to fill up.
  function heatName(name, letters, others = []) {
    const own = [...name];
    if (!(letters > 0) || own.length <= letters) return name;
    const lower = own.map(letter => letter.toLowerCase());
    let shared = 0;
    for (const other of others) {
      if (other === name) continue;
      const theirs = [...other].map(letter => letter.toLowerCase());
      let same = 0;
      while (same < own.length - 1 && same < theirs.length && lower[same] === theirs[same]) same++;
      shared = Math.max(shared, same);
    }
    const rest = own.slice(shared >= 3 ? shared : 0);
    const picked = (rest.length >= letters ? rest.slice(0, letters) : own.slice(-letters)).join('');
    return letters === 1 ? picked.toUpperCase() : picked;
  }
  const heatShowsGold = letters => !(letters > 0) || letters >= HEAT_GOLD_FROM;
  const validHeatColors = colors => Array.isArray(colors) && colors.length === 3 && colors.every(color => /^#[0-9a-f]{6}$/i.test(color));
  const linkKey = name => String(name).toLowerCase();
  // "Aynara (PvE)", as the shop writes it, and "Aynara", as the game does, are the same server.
  function ownServer(character) {
    return String(character.server || character.dailyLogin?.server || '').replace(/\s*\(.*\)\s*$/, '').trim();
  }
  // A character that hasn't saved its own can still be known from others on its account.
  function serverOf(character, known) {
    return ownServer(character) || known?.of(character.name)?.server || NO_SERVER;
  }
  // Characters one login screen listed together are on one account and one server. This only says who belongs
  // together: it never links anyone to a Gameforge account. Steam logs in to one account, so its characters are one
  // account on each server even before a login screen lists them.
  function accountGroups(characters) {
    const parent = new Map();
    const shown = new Map();
    const add = name => {
      const key = linkKey(name);
      if (!parent.has(key)) {
        parent.set(key, key);
        shown.set(key, String(name));
      }
      return key;
    };
    const find = key => {
      let at = key;
      while (parent.get(at) !== at) at = parent.get(at);
      return at;
    };
    const everyone = new Set(characters.map(character => linkKey(character.name)));
    const steamFirst = new Map();
    for (const character of characters) {
      const own = add(character.name);
      if (character.steam) {
        const server = ownServer(character).toLowerCase();
        if (steamFirst.has(server)) parent.set(find(own), find(steamFirst.get(server)));
        else steamFirst.set(server, own);
      }
      for (const other of character.roster || []) {
        // A list only names characters on its own server
        const scoped = `${other} (${ownServer(character)})`;
        parent.set(find(add(everyone.has(linkKey(scoped)) ? scoped : other)), find(own));
      }
    }
    const groups = new Map();
    for (const key of parent.keys()) {
      const root = find(key);
      if (!groups.has(root)) groups.set(root, {names: [], server: ''});
      groups.get(root).names.push(shown.get(key));
    }
    for (const character of characters) {
      const group = groups.get(find(linkKey(character.name)));
      group.server = group.server || ownServer(character);
      group.steam = group.steam || !!character.steam;
    }
    for (const group of groups.values()) group.names.sort((a, b) => a.localeCompare(b));
    return {
      of: name => (parent.has(linkKey(name)) ? groups.get(find(linkKey(name))) : null),
      groups: [...groups.values()].sort((a, b) => a.names[0].localeCompare(b.names[0])),
    };
  }
  // By last class: the token where a character has saved one, otherwise the English name
  const CLASS_COLORS = {WARRIOR: '#f24514', RANGER: '#9ed61f', THIEF: '#0dd1c2', MAGE: '#fa781a', AUGUR: '#5aa5ff', KNIGHT: '#e0e052',
    WARDEN: '#cc55cc', DRUID: '#3cc03c', PSYRON: '#8080ff', HARPSYN: '#a070ff', BARD: '#f280bf'};
  const CLASS_TOKENS = {warrior: 'WARRIOR', scout: 'RANGER', rogue: 'THIEF', mage: 'MAGE', priest: 'AUGUR', knight: 'KNIGHT',
    warden: 'WARDEN', druid: 'DRUID', warlock: 'HARPSYN', champion: 'PSYRON', bard: 'BARD'};
  function classColor(character) {
    return CLASS_COLORS[character.classToken || CLASS_TOKENS[String(character.class || '').toLowerCase()]] || null;
  }
  function emptyState() {
    return {accounts: [], links: {}};
  }
  function accountOf(state, name) {
    const id = state.links[linkKey(name)];
    return id ? state.accounts.find(account => account.id === id) || null : null;
  }
  // Links are kept by server and name once the server is known, so a name that turns up on a second server
  // doesn't take the link with it. A link kept the older way, by the name the page showed, still counts. A server
  // set by hand may be wrong, so those characters keep their links by name until they save their own.
  function linkKeysOf(character) {
    const keys = [];
    if (character.key && character.shownServer && !character.manualServer) keys.push(linkKey(character.key));
    keys.push(linkKey(character.name));
    return keys;
  }
  function accountFor(state, character) {
    for (const key of linkKeysOf(character)) {
      const id = state.links[key];
      if (id) return state.accounts.find(account => account.id === id) || null;
    }
    return null;
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
  // What's wrong with a Gameforge account's new name: empty, or another account's. '' when it's fine.
  function nameProblem(state, id, name) {
    const text = String(name || '').trim();
    if (!state.accounts.some(account => account.id === id)) return 'That account is gone.';
    if (!text) return 'Type a name first.';
    if (text.length > 120) return 'That name is too long.';
    if (state.accounts.some(account => account.id !== id && account.name.toLowerCase() === text.toLowerCase())) return `${text} is already on the list.`;
    return '';
  }
  // Renames it when the name is fine, and says what's wrong otherwise
  function renameAccount(state, id, name) {
    const problem = nameProblem(state, id, name);
    if (!problem) state.accounts.find(account => account.id === id).name = String(name).trim();
    return problem;
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
  const heatServerKey = name => String(name || '').replace(/\s*\(.*\)\s*$/, '').trim().toLowerCase();
  // The servers the Gold overview could show, with how many characters each has: {key, name, count}
  function heatServers(characters) {
    const known = accountGroups(characters);
    const found = new Map();
    for (const character of characters) {
      const name = character.shownServer || serverOf(character, known);
      const key = heatServerKey(name);
      if (!found.has(key)) found.set(key, {key, name, count: 0});
      found.get(key).count++;
    }
    return [...found.values()].sort((a, b) => Number(a.name === NO_SERVER) - Number(b.name === NO_SERVER) || b.count - a.count || a.name.localeCompare(b.name));
  }
  // A box for each Gameforge account, then one for the characters not linked to any. In a box its servers, and on a
  // server its RoM accounts, the characters one login screen lists, richest first, so that a full account shows as a
  // block of green. romTitle(character): the name to show for its RoM account. unlinked: the last box's name.
  // hidden: the servers, by key, the Gold overview leaves out
  function heatBoxes(characters, state, unlinked = NOT_LINKED, romTitle = null, hidden = null) {
    const boxes = new Map();
    const known = accountGroups(characters);
    for (const character of characters) {
      const serverName = character.shownServer || serverOf(character, known);
      if (hidden?.has(heatServerKey(serverName))) continue;
      const linked = accountFor(state, character)?.name || '';
      if (!boxes.has(linked)) boxes.set(linked, {account: linked || unlinked, linked: !!linked, total: 0, count: 0, fullCaps: 0, servers: new Map()});
      const box = boxes.get(linked);
      const gold = Number(character.gold) || 0;
      box.total += gold;
      box.count++;
      if (gold >= FULL_CAP) box.fullCaps++;
      if (!box.servers.has(serverName)) box.servers.set(serverName, {server: serverName, total: 0, roms: new Map()});
      const server = box.servers.get(serverName);
      server.total += gold;
      const group = known.of(character.name);
      const rom = (romTitle ? romTitle(character) : '') || (group.steam ? 'Steam account' : group.names.length > 1 ? `${group.names[0]}'s account` : NO_ROM);
      if (!server.roms.has(rom)) server.roms.set(rom, []);
      server.roms.get(rom).push({name: String(character.name), key: String(character.key || ''), gold});
    }
    const byGold = (a, b) => b.gold - a.gold || a.name.localeCompare(b.name);
    const last = (a, b, unwanted) => Number(a === unwanted) - Number(b === unwanted) || a.localeCompare(b);
    return [...boxes.values()].sort((a, b) => Number(b.linked) - Number(a.linked) || a.account.localeCompare(b.account)).map(box => ({
      account: box.account, linked: box.linked, total: box.total, count: box.count, fullCaps: box.fullCaps,
      servers: [...box.servers.values()].sort((a, b) => last(a.server, b.server, NO_SERVER)).map(server => ({
        server: server.server, total: server.total,
        roms: [...server.roms.entries()].sort((a, b) => last(a[0], b[0], NO_ROM)).map(([rom, list]) => ({rom, characters: list.sort(byGold)})),
      })),
    }));
  }
  const number = value => Number(value || 0).toLocaleString('en-US');
  const shortGold = value => (typeof GBBank !== 'undefined' ? GBBank.formatCompact(value) : number(value));
  const tinyGold = value => (typeof GBBank !== 'undefined' ? GBBank.formatTiny(value) : number(value));

  // options: {shows(character): on the page's region and servers, visible(tab): whether that tab is open,
  // isSelected(key), selectKeys(keys): all of them, or none when all are selected already, addKeys(keys),
  // clearSelection(): the page's one selection; listed(): names only a login screen listed, which can be linked
  // before they save anything; romTitle(character) and romName(character): its RoM account's name to show, and the
  // name you gave it; romFirst(): whether the RoM account comes before the character's name; linksChanged(): an
  // account renamed or characters linked, so tables grouped by account are drawn again; lockChanged(state):
  // 'none' (no accounts file), 'needs-key', 'locked' or 'open'}
  function create(send, options = {}) {
    const byId = id => document.getElementById(id);
    let state = emptyState();
    // Only while unlocked. The password itself is never held on to.
    let fileKey = null, fileSalt = null, fileIterations = ITERATIONS;
    let key = null, sealedFile = null;
    let saving = Promise.resolve();
    let characters = [];
    let byLabel = new Map();
    let reveal = false;
    let linksDirty = true, heatDirty = true;
    const shows = character => !options.shows || options.shows(character);
    const isSelected = key => !!key && !!options.isSelected && options.isSelected(key);
    const romOf = character => (options.romTitle ? options.romTitle(character) : '') || '';
    const visible = tab => !options.visible || options.visible(tab);
    const characterOf = name => byLabel.get(linkKey(name)) || null;
    const accountOfName = name => {
      const character = characterOf(name);
      return character ? accountFor(state, character) : accountOf(state, name);
    };
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
    // Each copy is written on its own, so a full Chrome storage doesn't also stop the helper's copy.
    function save() {
      if (!fileKey) return saving;
      const snapshot = structuredClone(state);
      saving = saving.then(async () => {
        sealedFile = await seal(snapshot, fileKey, fileSalt, fileIterations);
        const failed = [];
        await chrome.storage.local.set({[FILE_STORE]: sealedFile}).catch(error => { failed.push(`Chrome couldn't keep its copy (${error.message || error})`); });
        await send({type: 'gf-save', text: JSON.stringify(sealedFile)}).catch(error => {
          failed.push(`the helper's folder didn't take its copy (${error.message || error}), so use the backup button to move these to another PC`);
        });
        if (failed.length === 2) byId('gf-status').textContent = `Could not save: ${failed.join('; and ')}.`;
        else if (failed.length) byId('gf-status').textContent = `Saved, but ${failed[0]}.`;
      }).catch(error => { byId('gf-status').textContent = `Could not save: ${error.message || error}`; });
      return saving;
    }
    // Links kept by the name the page showed move to the character's server and name once that is known.
    function settleLinks() {
      if (!fileKey) return;
      let moved = 0;
      for (const character of characters) {
        const keys = linkKeysOf(character);
        if (keys.length < 2 || state.links[keys[0]] || !state.links[keys[1]]) continue;
        state.links[keys[0]] = state.links[keys[1]];
        delete state.links[keys[1]];
        moved++;
      }
      if (moved) save();
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
      if (options.lockChanged) options.lockChanged(fileKey ? 'open' : !sealedFile ? 'none' : key ? 'locked' : 'needs-key');
    }
    function lock() {
      fileKey = null;
      fileSalt = null;
      state = emptyState();
      reveal = false;
      byId('gf-reveal').checked = false;
      closeMenu();
      renderLock();
      renderAll();
    }
    async function copy(text) {
      await navigator.clipboard.writeText(text);
    }

    // The right-click menu stays open after copying, so the account name and then the password are two clicks.
    // For several characters it stacks their names, and each one's logins open in a side menu next to its name.
    let menuOwners = [], sideRow = null, sideTimer = 0;
    function closeSide() {
      clearTimeout(sideTimer);
      if (sideRow) sideRow.classList.remove('is-open');
      sideRow = null;
      const side = byId('gf-side-menu');
      side.hidden = true;
      side.replaceChildren();
    }
    function closeMenu() {
      byId('gf-menu').hidden = true;
      closeSide();
    }
    function copyRow(label, text) {
      const row = button(label, async () => {
        await copy(text).catch(() => {});
        row.textContent = `${label}: copied`;
      });
      row.disabled = !text;
      return row;
    }
    // owner: a character (saved, or only listed on a login screen) or the name the page shows it by
    function ownerRows(menu, owner, heading) {
      const name = typeof owner === 'string' ? owner : String(owner.name);
      const account = typeof owner === 'string' ? accountOfName(owner) : accountFor(state, owner);
      if (heading) menu.append(make('strong', '', name));
      menu.append(copyRow('Copy character name', String(name).replace(/ \([^()]*\)$/, '')), copyRow('Copy Gameforge account name', account?.name || ''),
        copyRow('Copy password', account?.password || ''), copyRow('Copy secondary password', account?.secondary || ''));
      if (!account) menu.append(make('span', 'hint', fileKey ? 'Not linked to a Gameforge account yet.' : 'Unlock your Gameforge accounts to copy logins.'));
    }
    const ownerName = owner => typeof owner === 'string' ? owner : String(owner.name);
    // Level with its name: to the right of the menu, or to the left when the window has no room there
    function openSide(row, focus = false) {
      clearTimeout(sideTimer);
      const owner = menuOwners[Number(row.dataset.owner)];
      if (owner === undefined) return;
      const side = byId('gf-side-menu');
      if (row !== sideRow) {
        closeSide();
        sideRow = row;
        row.classList.add('is-open');
        ownerRows(side, owner, true);
        side.hidden = false;
        const menuBox = byId('gf-menu').getBoundingClientRect(), rowBox = row.getBoundingClientRect();
        const width = side.offsetWidth, height = side.offsetHeight;
        side.style.left = (menuBox.right - 1 + width <= window.innerWidth - 8 ? menuBox.right - 1 : Math.max(4, menuBox.left - width + 1)) + 'px';
        side.style.top = Math.max(4, Math.min(rowBox.top - 9, window.innerHeight - height - 8)) + 'px';
      }
      if (focus) side.querySelector('button:not(:disabled)')?.focus();
    }
    function nameList(owners) {
      const list = make('div', 'gf-menu-names');
      owners.forEach((owner, index) => {
        const row = make('button', 'gf-menu-name');
        row.type = 'button';
        row.dataset.owner = String(index);
        row.append(make('span', '', ownerName(owner)), make('span', 'gf-menu-more', '›'));
        list.append(row);
      });
      return list;
    }
    // extra: rows above the logins, names: who to copy logins of, after: rows below them, each {label, run}
    function openMenu(event, extra, names, after = []) {
      event.preventDefault();
      closeSide();
      const menu = byId('gf-menu');
      menu.replaceChildren();
      for (const row of extra) menu.append(button(row.label, () => { closeMenu(); row.run(); }));
      const owners = [...new Set(names)];
      if (owners.length === 1) ownerRows(menu, owners[0], extra.length > 0);
      menuOwners = owners.length > 1 ? owners.sort((a, b) => collator.compare(ownerName(a), ownerName(b))).slice(0, MENU_OWNERS) : [];
      if (menuOwners.length) menu.append(nameList(menuOwners));
      if (owners.length > MENU_OWNERS) menu.append(make('span', 'hint', `and ${number(owners.length - MENU_OWNERS)} more`));
      if (after.length) menu.append(make('hr', 'gf-menu-line'));
      for (const row of after) menu.append(button(row.label, () => { closeMenu(); row.run(); }));
      menu.hidden = false;
      menu.style.left = Math.max(4, Math.min(event.clientX, window.innerWidth - menu.offsetWidth - 8)) + 'px';
      menu.style.top = Math.max(4, Math.min(event.clientY, window.innerHeight - menu.offsetHeight - 8)) + 'px';
    }

    // Your own colours for the Gold overview, kept in this Chrome
    let heatColors = HEAT_COLORS;
    let heatFrame = 0;
    const heatInputs = ['heat-color-none', 'heat-color-half', 'heat-color-full'].map(byId);
    let heatLetters = 0;
    function showHeatColors() {
      heatInputs.forEach((input, at) => {
        input.value = heatColors[at];
        byId('heat-legend').style.setProperty(`--${input.id}`, heatColors[at]);
      });
      byId('heat-colors-reset').hidden = heatColors.every((color, at) => color === HEAT_COLORS[at]);
    }
    for (const input of heatInputs) {
      // Tiles follow while you pick, once a frame, and the pick is kept when you're done
      input.addEventListener('input', () => {
        heatColors = heatInputs.map(each => each.value.toLowerCase());
        showHeatColors();
        cancelAnimationFrame(heatFrame);
        heatFrame = requestAnimationFrame(renderHeat);
      });
      input.addEventListener('change', () => { chrome.storage.local.set({[HEAT_STORE]: heatColors}).catch(() => {}); });
    }
    byId('heat-colors-reset').addEventListener('click', () => {
      heatColors = HEAT_COLORS;
      showHeatColors();
      renderHeat();
      chrome.storage.local.remove(HEAT_STORE).catch(() => {});
    });

    byId('heat-letters').addEventListener('change', event => {
      heatLetters = Number(event.target.value) || 0;
      renderHeat();
      chrome.storage.local.set({[HEAT_LETTERS]: heatLetters}).catch(() => {});
    });
    // Servers to leave off this map, and their names on top of their regions
    byId('heat-server-list')?.addEventListener('change', event => {
      const box = event.target.closest?.('[data-heat-server]');
      if (!box) return;
      if (box.checked) heatHidden.delete(box.dataset.heatServer);
      else heatHidden.add(box.dataset.heatServer);
      keepHeatServers();
      renderHeat();
    });
    byId('heat-server-names')?.addEventListener('change', event => {
      heatServerNames = event.target.checked;
      keepHeatServers();
      renderHeat();
    });
    byId('heat-servers-all')?.addEventListener('click', () => {
      heatHidden = new Set();
      keepHeatServers();
      renderHeat();
    });
    // The widest tile the names need. Tiles are measured, so a whole name is never cut. A mailbox mark takes a little more.
    let heatMeasure = null;
    function heatTileWidth(shown, mail) {
      heatMeasure = heatMeasure || document.createElement('canvas').getContext('2d');
      heatMeasure.font = `11px ${getComputedStyle(document.body).fontFamily}`;
      let widest = 0;
      for (const name of shown) widest = Math.max(widest, heatMeasure.measureText(name).width);
      return Math.ceil(widest) + 8 + (heatShowsGold(heatLetters) ? 30 : 0) + (mail ? 17 : 0);
    }
    // Which servers the map leaves out, and whether each one's region has its name on top. Kept in this Chrome.
    let heatHidden = new Set();
    let heatServerNames = true;
    const keepHeatServers = () => chrome.storage.local.set({[HEAT_SERVERS]: {hidden: [...heatHidden], names: heatServerNames}}).catch(() => {});
    function renderHeatServers(list) {
      const panel = byId('heat-server-list');
      const summary = byId('heat-servers-summary');
      if (!panel || !summary) return;
      const shown = list.filter(server => !heatHidden.has(server.key)).length;
      summary.textContent = shown === list.length ? (heatServerNames ? 'All servers' : 'All servers, no names') : `${number(shown)} of ${number(list.length)} servers`;
      panel.replaceChildren(...list.map(server => {
        const row = make('label', 'bank-check');
        const box = make('input');
        box.type = 'checkbox';
        box.checked = !heatHidden.has(server.key);
        box.dataset.heatServer = server.key;
        row.append(box, ` ${server.name} `, make('span', 'hint', number(server.count)));
        return row;
      }));
      byId('heat-server-names').checked = heatServerNames;
    }

    // Boxes share the width by how many lines they take, so they come out about the same height. How much width a box
    // asks for first decides which fit side by side, so this tries a few and keeps whichever leaves the least to scroll.
    let heatFit = null;
    function fitHeat() {
      const view = byId('heat-view');
      if (!heatFit || !view.offsetParent) return;
      const {column, boxes} = heatFit;
      const share = linesInColumn => {
        for (const {node, lines} of boxes) node.style.flex = `${lines} 1 ${Math.max(column + 16, Math.round(lines * column / linesInColumn))}px`;
      };
      let best = 21, lowest = Infinity;
      // Thousands of tiles take too long to lay out again and again
      for (const linesInColumn of heatFit.tiles > 1500 ? [] : [1000, 30, 25, 21, 16, 12]) {
        share(linesInColumn);
        if (view.offsetHeight < lowest) {
          lowest = view.offsetHeight;
          best = linesInColumn;
        }
      }
      share(best);
    }
    let heatResize = 0;
    window.addEventListener('resize', () => {
      clearTimeout(heatResize);
      heatResize = setTimeout(fitHeat, 200);
    });

    function renderHeat() {
      heatDirty = false;
      // Gold waiting in a mailbox shows as a mailbox after the name, with a ! when some of it goes within 48 hours
      const mailOf = cell => {
        const box = cell.key && options.mailbox ? options.mailbox(cell.key) : null;
        return box && (box.gold > 0 || box.expiring > 0) ? box : null;
      };
      // The page's hover card, click and right-click work from data-char, for every cell at once
      const cellFor = cell => {
        const color = heatColor(cell.gold, heatColors);
        const node = make('div', 'heat-cell');
        node.append(make('span', 'heat-name', cell.shown));
        const mail = mailOf(cell);
        if (mail) {
          const mark = make('span', 'heat-mail' + (mail.expiring ? ' is-soon' : ''));
          mark.innerHTML = window.GB_ICONS?.mail || '';
          if (mail.expiring) mark.append(make('i', '', '!'));
          node.append(mark);
        }
        if (heatShowsGold(heatLetters)) node.append(make('b', '', color.kind === 'full' ? 'MAX' : tinyGold(cell.gold)));
        node.style.background = color.css;
        node.style.color = color.text;
        node.setAttribute('aria-label', `${cell.name}, ${number(cell.gold)} gold` + (mail ? `, ${number(mail.gold)} gold in its mailbox${mail.expiring ? ', some of it expiring within 48 hours' : ''}` : ''));
        if (cell.key) node.dataset.char = cell.key;
        return node;
      };
      // Under its own server a name needs no "(Server)" after it
      const ownName = (cell, server) => (cell.name.endsWith(` (${server})`) ? cell.name.slice(0, -server.length - 3) : cell.name);
      // An account stays in one piece unless it's longer than a login screen's list
      const block = (title, cells) => {
        const box = make('div', 'heat-group' + (cells.length > 8 ? ' is-long' : ''));
        const head = make('h4', '', title);
        head.title = title;
        box.append(head, ...cells.map(cellFor));
        return box;
      };
      const inView = characters.filter(shows);
      renderHeatServers(heatServers(inView));
      const boxes = heatBoxes(inView, state, !fileKey && sealedFile ? 'Accounts locked' : NOT_LINKED, options.romTitle || null, heatHidden);
      const shown = [];
      let anyMail = false;
      for (const server of boxes.flatMap(box => box.servers)) {
        for (const rom of server.roms) {
          const names = rom.characters.map(cell => ownName(cell, server.server));
          rom.characters.forEach((cell, at) => {
            cell.shown = heatName(names[at], heatLetters, names);
            shown.push(cell.shown);
            anyMail = anyMail || !!mailOf(cell);
          });
        }
      }
      const tile = heatTileWidth(shown, anyMail);
      const perLine = [8, 4, 2].find(count => count * (tile + 1) - 1 <= HEAT_WIDEST_COLUMN) || 1;
      const column = perLine * (tile + 1) - 1;
      byId('heat-view').style.setProperty('--heat-per-line', perLine);
      byId('heat-view').classList.toggle('is-letters', !heatShowsGold(heatLetters));
      byId('heat-view').style.setProperty('--heat-tile', `${tile}px`);
      byId('heat-view').style.setProperty('--heat-column', `${column}px`);
      byId('heat-view').classList.toggle('is-narrow', column < 96);
      const allGold = boxes.reduce((sum, box) => sum + box.total, 0);
      const allCaps = boxes.reduce((sum, box) => sum + box.fullCaps, 0);
      const total = byId('heat-total');
      total.textContent = `${shortGold(allGold)} gold`;
      total.title = `${number(allGold)} gold`;
      total.append(make('span', 'soft-count', `${number(allCaps)} full ${allCaps === 1 ? 'cap' : 'caps'}`));
      const fit = [];
      byId('heat-view').classList.toggle('no-server-names', !heatServerNames);
      byId('heat-view').replaceChildren(...boxes.map(box => {
        const node = make('section', 'heat-column');
        fit.push({node, lines: box.servers.reduce((sum, server) => sum + (heatServerNames ? 1 : 0) + server.roms.reduce((rows, rom) => rows + 1 + Math.ceil(rom.characters.length / perLine), 0), 1)});
        node.style.flex = `${fit.at(-1).lines} 1 ${Math.max(column + 16, Math.round(fit.at(-1).lines * column / 21))}px`;
        const head = make('div', 'heat-column-head');
        head.append(make('h2', '', box.account), make('span', 'heat-column-sub', `${number(box.count)} ${box.count === 1 ? 'character' : 'characters'}`));
        const balance = make('span', 'heat-balance', shortGold(box.total));
        balance.title = `${number(box.total)} gold, ${number(box.fullCaps)} full ${box.fullCaps === 1 ? 'cap' : 'caps'}`;
        head.append(balance);
        node.append(head);
        // Each server is a region of its own, its name on top, so a name never turns up halfway down a column
        for (const server of box.servers) {
          const region = make('section', 'heat-region');
          region.setAttribute('aria-label', `${server.server}: ${number(server.total)} gold`);
          if (heatServerNames) {
            const title = make('h3', 'heat-server');
            title.title = `${server.server}: ${number(server.total)} gold`;
            title.append(make('span', '', server.server), make('span', '', shortGold(server.total)));
            region.append(title);
          }
          const flow = make('div', 'heat-flow');
          for (const rom of server.roms) flow.append(block(rom.rom, rom.characters));
          region.append(flow);
          node.append(region);
        }
        return node;
      }));
      heatFit = {column, boxes: fit, tiles: boxes.reduce((sum, box) => sum + box.count, 0)};
      fitHeat();
      if (!boxes.length) byId('heat-view').append(make('p', 'hint', !characters.length ? 'No characters saved yet.' : inView.length ? 'Every server is hidden on this map: tick one under Servers.' : 'No characters on the servers ticked at the top.'));
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
          // The name is what Copy Gameforge account name copies: the one you log in with
          const name = field('text', account.name, 'Account name');
          name.maxLength = 120;
          const password = field(secretType, account.password, 'Password');
          const secondary = field(secretType, account.secondary, 'Secondary password');
          const notes = field('text', account.notes, 'Notes');
          const set = button('Save', () => {
            const problem = renameAccount(state, account.id, name.value);
            if (problem) { byId('gf-status').textContent = problem; name.focus(); return; }
            account.password = password.value;
            account.secondary = secondary.value;
            account.notes = notes.value;
            save();
            renderAll();
            if (options.linksChanged) options.linksChanged();
          });
          actions.replaceChildren(name, password, secondary, notes, set, button('Cancel', renderAccounts));
          name.focus();
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

    // Everyone a login screen listed can be linked, whether or not they've saved anything here yet.
    const everyone = () => (options.listed ? characters.concat(options.listed()) : characters);
    function shownCharacters() {
      const text = byId('gf-filter').value.trim().toLowerCase();
      const unlinked = byId('gf-unlinked').checked;
      return everyone().filter(character => shows(character)
        && (!text || String(character.name).toLowerCase().includes(text) || romOf(character).toLowerCase().includes(text))
        && (!unlinked || !accountFor(state, character)));
    }
    // The selected characters this list can link: on the region and servers the page shows, whatever the filter
    const picked = () => everyone().filter(character => isSelected(character.key) && shows(character));
    let orphans = 0;
    let boxKeys = [];
    // One box for each Gameforge account on each server, then the characters not linked yet, by server. Each
    // character shows its name and its RoM account, in the order the page's switch asks for.
    function renderLinks() {
      linksDirty = false;
      const shown = shownCharacters();
      // Links that match nobody: a character renamed or deleted, or a name linked before it was on two servers
      const used = new Set();
      for (const character of everyone()) for (const key of linkKeysOf(character)) used.add(key);
      orphans = Object.keys(state.links).filter(key => !used.has(key)).length;
      const boxes = new Map();
      for (const character of shown) {
        const account = accountFor(state, character);
        const server = character.shownServer || '';
        const id = `${account ? account.id : ''}|${server.toLowerCase()}`;
        if (!boxes.has(id)) boxes.set(id, {account, server, members: []});
        boxes.get(id).members.push(character);
      }
      const romFirst = !!(options.romFirst && options.romFirst());
      const first = character => (romFirst ? romOf(character) : String(character.name));
      const second = character => (romFirst ? String(character.name) : romOf(character));
      // Characters no login screen listed yet go after the others when the RoM account comes first
      const byFirst = (a, b) => Number(!first(a)) - Number(!first(b)) || first(a).localeCompare(first(b)) || second(a).localeCompare(second(b));
      const sorted = [...boxes.values()].sort((a, b) => Number(!a.account) - Number(!b.account)
        || (a.account && b.account ? a.account.name.localeCompare(b.account.name) : 0)
        || Number(!a.server) - Number(!b.server) || a.server.localeCompare(b.server));
      boxKeys = [];
      const rowFor = character => {
        const row = make('div', 'gf-character' + (character.notSaved ? ' is-unsaved' : '') + (isSelected(character.key) ? ' is-selected' : ''));
        const name = make('span', 'gf-name', String(character.name));
        const color = classColor(character);
        if (color) name.style.color = color;
        const rom = make('span', 'gf-rom', romOf(character) || '—');
        const parts = romFirst ? [rom, name] : [name, rom];
        row.append(parts[0], make('span', 'gf-slash', ' / '), parts[1]);
        // The page's hover card; a click selects, Shift-click a range
        if (character.key) row.dataset.char = character.key;
        return row;
      };
      const nodes = sorted.map(box => {
        const keys = box.members.map(character => character.key).filter(Boolean);
        boxKeys.push(keys);
        const node = make('div', box.account ? 'gf-group' : 'gf-group gf-loose');
        const head = make('div', 'gf-group-head');
        const title = make('span', 'gf-group-title');
        title.append(make('b', '', box.account ? box.account.name : 'Not linked'), ` · ${box.server || NO_SERVER} · ${number(box.members.length)} characters`);
        const pick = button('Select', () => { if (options.selectKeys) options.selectKeys(keys); });
        pick.className = 'group-select';
        head.append(title, pick);
        const rows = make('div', 'gf-group-rows');
        rows.append(...box.members.sort(byFirst).map(rowFor));
        node.append(head, rows);
        return node;
      });
      if (!nodes.length) nodes.push(make('p', 'hint', everyone().length ? 'No character matches.' : 'No characters saved yet.'));
      byId('gf-characters').replaceChildren(...nodes);
      showSelected();
    }
    function showSelected() {
      const shown = shownCharacters();
      const chosen = shown.reduce((count, character) => count + Number(isSelected(character.key)), 0);
      byId('gf-link-count').textContent = `${number(chosen)} selected of ${number(shown.length)} shown`
        + (orphans ? ` · ${number(orphans)} links match no saved character (renamed, deleted, or the name is now on two servers): link those again` : '');
    }
    // By server and name where the server is known, and the older form taken away. list: characters, or the
    // names the page shows them by.
    function link(list, id) {
      let changed = 0;
      for (const item of list) {
        const character = typeof item === 'string' ? characterOf(item) || {name: item} : item;
        const keys = linkKeysOf(character);
        const before = accountFor(state, character)?.id || null;
        setLinks(state, keys, null);
        if (id) setLinks(state, [keys[0]], id);
        if (before !== (id || null)) changed++;
      }
      save();
      byId('gf-status').textContent = `${number(changed)} characters ${id ? 'linked' : 'unlinked'}.`;
      renderAll();
      if (changed && options.linksChanged) options.linksChanged();
      return changed;
    }
    // Only the open tab is drawn; the others when they're opened.
    function renderAll() {
      renderAccounts();
      linksDirty = heatDirty = true;
      if (visible('accounts')) renderLinks();
      if (visible('heatmap')) renderHeat();
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
      settleLinks();
    }
    byId('gf-unlock').addEventListener('submit', async event => {
      event.preventDefault();
      const box = byId('gf-unlock-password');
      const note = byId('gf-unlock-status');
      note.textContent = 'Unlocking…';
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
    byId('gf-filter').addEventListener('input', () => renderLinks());
    byId('gf-unlinked').addEventListener('change', () => renderLinks());
    byId('gf-select-shown').addEventListener('click', () => { if (options.addKeys) options.addKeys(shownCharacters().map(character => character.key).filter(Boolean)); });
    byId('gf-select-none').addEventListener('click', () => { if (options.clearSelection) options.clearSelection(); });
    // The page's selection, as on every tab. It's cleared after linking, so the next box starts from nothing.
    for (const [id, linking] of [['gf-link', true], ['gf-unlink', false]]) {
      byId(id).addEventListener('click', () => {
        const account = byId('gf-link-account').value;
        if (linking && !account) { byId('gf-status').textContent = 'Add a Gameforge account first.'; return; }
        const list = picked();
        if (!list.length) { byId('gf-status').textContent = 'Select characters first: click them, or a box\'s Select.'; return; }
        link(list, linking ? account : null);
        if (options.clearSelection) options.clearSelection();
      });
    }
    byId('gf-link-pasted').addEventListener('click', () => {
      if (!byId('gf-link-account').value) { byId('gf-status').textContent = 'Add a Gameforge account first.'; return; }
      const {found, missing} = matchNames(byId('gf-paste').value, characters);
      link(found, byId('gf-link-account').value);
      byId('gf-paste').value = missing.join('\n');
      if (missing.length) byId('gf-status').textContent += ` ${number(missing.length)} names aren't saved characters, so they're left in the box.`;
    });
    document.addEventListener('click', event => { if (!event.target.closest?.('#gf-menu, #gf-side-menu')) closeMenu(); });
    // A name's logins open on hover. On the way over to them the pointer may cross other names, so another name
    // takes over only once the pointer rests on it. A click, or Enter, opens them at once.
    const menuNode = byId('gf-menu');
    menuNode.addEventListener('mouseover', event => {
      const row = event.target.closest?.('.gf-menu-name') || null;
      clearTimeout(sideTimer);
      if (row === sideRow) return;
      if (row && !sideRow) openSide(row);
      else if (row) sideTimer = setTimeout(() => openSide(row), SIDE_DELAY);
      else if (sideRow && event.target.closest?.('button')) sideTimer = setTimeout(closeSide, SIDE_DELAY);
    });
    menuNode.addEventListener('click', event => {
      const row = event.target.closest?.('.gf-menu-name');
      if (row) openSide(row, event.detail === 0);
    });
    menuNode.addEventListener('scroll', closeSide, {capture: true, passive: true});
    byId('gf-side-menu').addEventListener('mouseover', () => clearTimeout(sideTimer));
    // Another tab of this page saved: take its changes rather than overwrite them with the next save here.
    chrome.storage.onChanged?.addListener((changes, area) => {
      const file = area === 'local' ? changes[FILE_STORE]?.newValue : null;
      if (!validFile(file) || (sealedFile && file.saved === sealedFile.saved && file.data === sealedFile.data)) return;
      sealedFile = file;
      if (!fileKey) { renderLock(); return; }
      unseal(file, fileKey).then(opened => { state = opened; renderAll(); }, () => lock());
    });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') closeMenu(); });

    // Whichever copy was saved last, and a copy left in the helper's folder is what a new PC starts from.
    (async () => {
      const stored = await chrome.storage.local.get([KEY_STORE, FILE_STORE, HEAT_STORE, HEAT_LETTERS, HEAT_SERVERS]);
      key = stored[KEY_STORE] || null;
      if (validHeatColors(stored[HEAT_STORE])) heatColors = stored[HEAT_STORE];
      const servers = stored[HEAT_SERVERS];
      if (servers && typeof servers === 'object') {
        heatHidden = new Set(Array.isArray(servers.hidden) ? servers.hidden.filter(item => typeof item === 'string') : []);
        heatServerNames = servers.names !== false;
      }
      const letters = Math.floor(Number(stored[HEAT_LETTERS]));
      const choice = [...byId('heat-letters').options].find(option => Number(option.value) === letters);
      if (choice) {
        heatLetters = letters;
        byId('heat-letters').value = choice.value;
      }
      const local = validFile(stored[FILE_STORE]) ? stored[FILE_STORE] : null;
      const inFolder = await readFile().catch(() => null);
      sealedFile = !inFolder || (local && local.saved >= inFolder.saved) ? local : inFolder;
      if (sealedFile && sealedFile !== local) await chrome.storage.local.set({[FILE_STORE]: sealedFile});
      if (sealedFile && !inFolder) await send({type: 'gf-save', text: JSON.stringify(sealedFile)}).catch(() => {});
    })().catch(() => {}).finally(() => {
      showHeatColors();
      renderLock();
      renderAll();
    });
    return {
      setCharacters(list) {
        characters = list;
        byLabel = new Map(list.map(character => [linkKey(character.name), character]));
        settleLinks();
        renderAll();
      },
      // A tab that was hidden when its data changed, drawn now that it's open
      refresh(tab) {
        if (tab === 'accounts' && linksDirty) renderLinks();
        if (tab === 'heatmap' && heatDirty) renderHeat();
      },
      // The linked Gameforge account's name, only while the accounts are open: by the name the page shows, or for
      // a character, saved or only listed on a login screen
      accountName: name => accountOfName(name)?.name || '',
      accountNameOf: character => accountFor(state, character)?.name || '',
      // Its Gameforge account's id and name, never its passwords
      linkedAccount(character) {
        const account = accountFor(state, character);
        return account ? {id: account.id, name: account.name} : null;
      },
      locked: () => !fileKey && !!sealedFile,
      nameProblem: (id, name) => nameProblem(state, id, name),
      // A new name for a Gameforge account, saved like any other change. Says what's wrong, or ''.
      rename(id, name) {
        const problem = renameAccount(state, id, name);
        if (!problem) {
          save();
          renderAll();
        }
        return problem;
      },
      // Everything drawn again: the region, the ticks or a RoM account's name changed
      redraw: renderAll,
      // The selection changed: the count under Link characters
      showSelected() { if (visible('accounts') && !linksDirty) showSelected(); },
      openMenu,
    };
  }
  return {create, heatColor, heatName, heatShowsGold, validHeatColors, serverOf, accountOf, accountFor, linkKeysOf, setLinks, nameProblem, renameAccount, removeAccount, matchNames, heatBoxes, emptyState,
    newKey, cleanKey, deriveKey, seal, unseal, validFile, accountGroups, classColor, heatServers, heatServerKey};
})();
