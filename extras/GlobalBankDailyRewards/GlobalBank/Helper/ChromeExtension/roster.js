'use strict';
// Who is who, on every page. A character is its name and its server: names repeat between servers, so a name
// only carries "(Server)" where it does. The region decides which servers the page shows, the server ticks at the
// top narrow that down, and one selection, shared by every page, is what a click on a character changes. The Bank
// shows everyone until you give it a scope: Use in Bank copies the selection there, and its own character list
// ticks them directly, so selecting never narrows the Bank by itself. Nothing here leaves this PC: the choices are
// kept in this extension's own storage.
const GBRoster = (() => {
  const NO_SERVER = 'Unknown server';
  const FULL_CAP = 999999999;
  // The servers each region's game lists. Europe and North America are separate games: nobody moves between them.
  // A server missing here still shows, and Region settings can add it to a region.
  const REGIONS = {
    // The live servers as the official forum listed them in October 2026. Characters can't move between the two regions.
    eu: {name: 'Europe', servers: ['Aynara', 'Kadmos', 'Kerub', 'Gaia', 'Svidur']},
    na: {name: 'North America', servers: ['Ayvenas']},
  };
  const VIEW_STORE = 'gbView';
  const SELECTION_STORE = 'gbSelection';
  const SCOPE_STORE = 'gbScope';
  // The names you gave RoM accounts, by character. Only labels for this page: logins live with the Gameforge accounts.
  const NAMES_STORE = 'gbRomNames';
  // The newest snapshots name their server. One without was saved by an older Global Bank, before it kept servers,
  // currencies, stats and the game's own tooltips.
  const STALE_NOTE = 'Saved by an older Global Bank: log in once to record its server, currencies and item stats.';
  const UNSAVED_NOTE = 'A login screen lists it, but nothing is saved here yet: log in with it once.';

  const number = value => Number(value || 0).toLocaleString('en-US');
  const escapeHtml = text => String(text ?? '').replace(/[&<>"']/g, letter => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[letter]));
  // "Aynara (PvE)", as the shop writes it, and "Aynara", as the game does, are the same server.
  function cleanServer(text) {
    return String(text || '').replace(/\s*\(.*\)\s*$/, '').trim();
  }
  // Asked for every character and item shown, of a handful of servers: worked out once each
  const serverKeys = new Map();
  function serverKey(text) {
    const raw = String(text || '');
    let key = serverKeys.get(raw);
    if (key === undefined) {
      key = cleanServer(raw).toLowerCase();
      if (serverKeys.size < 500) serverKeys.set(raw, key);
    }
    return key;
  }
  function keyOf(name, server) {
    return `${serverKey(server)}|${String(name || '').toLowerCase()}`;
  }
  // A name kept by name, never one of an object's own built-in properties
  function pick(map, key) {
    return map && Object.prototype.hasOwnProperty.call(map, key) && typeof map[key] === 'string' ? map[key] : '';
  }
  function textMap(value) {
    const map = Object.create(null);
    if (value && typeof value === 'object') for (const [key, text] of Object.entries(value)) if (typeof text === 'string' && text.trim()) map[key] = text.trim();
    return map;
  }

  // Once per load: every character gets its own name (base), a label that is unique on the page (name), a server
  // (its own, the one its login screen showed it with, or one set by hand), a key made of the server and the name,
  // and what's worth knowing. groupsOf: GBAccounts.accountGroups, the login screens' lists, which also tell the server
  // of a character that never saved one. assigned: {name in lower case: server} set by hand on the Servers tab, for
  // characters nothing else places.
  function prepare(characters, groupsOf, assigned) {
    const count = new Map();
    for (const character of characters) {
      character.base = String(character.base ?? character.name ?? '');
      // Only a snapshot's own server says it was saved by a build that keeps servers, currencies and stats.
      const own = cleanServer(character.server);
      if (character.stale === undefined) character.stale = !own;
      character.server = own || cleanServer(character.dailyLogin?.server);
      const lower = character.base.toLowerCase();
      count.set(lower, (count.get(lower) || 0) + 1);
    }
    const servers = new Map();
    for (const character of characters) {
      const repeats = count.get(character.base.toLowerCase()) > 1;
      character.name = repeats && character.server ? `${character.base} (${character.server})` : character.base;
      if (repeats) {
        if (!servers.has(character.base.toLowerCase())) servers.set(character.base.toLowerCase(), []);
        servers.get(character.base.toLowerCase()).push(character.server || NO_SERVER);
      }
    }
    const groups = groupsOf ? groupsOf(characters) : null;
    for (const character of characters) {
      const group = groups?.of(character.name) || null;
      character.group = group && group.names.length > 1 ? group : null;
      // Its RoM account: the characters one login screen lists, known once a list names it
      character.romAccount = group && (group.names.length > 1 || group.steam || (Array.isArray(character.roster) && character.roster.length > 0)) ? group : null;
      const known = character.server || cleanServer(group?.server);
      const manual = known ? '' : cleanServer(pick(assigned, character.base.toLowerCase()));
      character.manualServer = !!manual;
      character.shownServer = known || manual;
      character.key = keyOf(character.base, character.shownServer);
      character.elsewhere = (servers.get(character.base.toLowerCase()) || []).filter(server => server !== (character.server || NO_SERVER));
      character.gold = Number(character.gold) || 0;
      character.level = Number(character.level) || 0;
    }
    return characters;
  }

  // Names a login screen lists that never saved anything here: they can be selected and linked, and hold no items.
  // members: each RoM account and its saved characters, from create().setCharacters.
  function listedOf(characters, members, assigned) {
    const labels = new Set(characters.map(character => String(character.name).toLowerCase()));
    const found = new Map();
    for (const group of members.keys()) {
      for (const label of group.names) {
        const name = String(label);
        if (labels.has(name.toLowerCase())) continue;
        const known = cleanServer(group.server);
        const manual = known ? '' : cleanServer(pick(assigned, name.toLowerCase()));
        const shownServer = known || manual;
        const key = keyOf(name, shownServer);
        if (found.has(key)) continue;
        found.set(key, {name, base: name, key, server: '', shownServer, manualServer: !!manual, notSaved: true, stale: false,
          romAccount: group, group: group.names.length > 1 ? group : null, gold: 0, level: 0, elsewhere: []});
      }
    }
    return found;
  }

  const listsServer = (list, key) => Array.isArray(list) && list.some(name => serverKey(name) === key);
  const isDropped = (dropped, key) => !!dropped && (dropped.has ? dropped.has(key) : Array.isArray(dropped) && dropped.includes(key));
  // Which region lists a server: 'eu', 'na', or '' for one no region lists. extra: {region: [servers]} added by hand,
  // which come first; dropped: the servers taken off the game's own lists.
  function regionOf(server, extra = {}, dropped = null) {
    const key = serverKey(server);
    if (!key) return '';
    for (const id of Object.keys(REGIONS)) if (listsServer(extra?.[id], key)) return id;
    if (isDropped(dropped, key)) return '';
    for (const [id, region] of Object.entries(REGIONS)) if (region.servers.some(name => name.toLowerCase() === key)) return id;
    return '';
  }
  // The servers each region lists now: the game's own, less the ones taken off, plus the ones added by hand
  function regionLists(view = {}) {
    const lists = {};
    for (const [id, region] of Object.entries(REGIONS)) {
      const seen = new Set();
      lists[id] = [];
      for (const name of [...region.servers, ...(Array.isArray(view.extra?.[id]) ? view.extra[id] : [])]) {
        const key = serverKey(name);
        if (!key || seen.has(key) || regionOf(name, view.extra, view.dropped) !== id) continue;
        seen.add(key);
        lists[id].push(cleanServer(name));
      }
    }
    return lists;
  }
  // The region of a server for a view, remembered until the view's lists change
  function regionIn(view, server) {
    const cache = view.regionCache;
    if (!cache) return regionOf(server, view.extra, view.dropped);
    let region = cache.get(server);
    if (region === undefined) cache.set(server, region = regionOf(server, view.extra, view.dropped));
    return region;
  }
  // A region shows its own servers, servers no region lists, and characters whose server isn't known yet.
  function inRegion(character, view) {
    if (!view.region || view.region === 'all') return true;
    const region = regionIn(view, character.shownServer);
    return !region || region === view.region;
  }
  // The page's view: the region, then the server ticks.
  function shows(character, view) {
    return inRegion(character, view) && !view.serversOff.has(serverKey(character.shownServer));
  }
  // The ticks to offer: the region's own servers, even with nobody saved there yet, and every other server its
  // characters are on, busiest first, with the unknown one last. Each says which region lists it.
  function serverList(characters, view) {
    const found = new Map();
    const add = name => {
      const key = serverKey(name);
      if (!found.has(key)) found.set(key, {key, name: cleanServer(name) || NO_SERVER, region: regionOf(name, view.extra, view.dropped), count: 0, gold: 0, stale: 0, on: !view.serversOff.has(key)});
      return found.get(key);
    };
    for (const character of characters) {
      if (!inRegion(character, view)) continue;
      const server = add(character.shownServer);
      server.count++;
      server.gold += character.gold;
      if (character.stale) server.stale++;
    }
    const regions = !view.region || view.region === 'all' ? Object.keys(REGIONS) : [view.region];
    const lists = regionLists(view);
    for (const id of regions) for (const name of lists[id] || []) add(name);
    return [...found.values()].sort((a, b) => Number(!a.key) - Number(!b.key) || Number(!a.count) - Number(!b.count) || b.count - a.count || a.name.localeCompare(b.name));
  }
  // Every server the page knows, for the Servers tab: on a region's list, taken off one, or with characters on it.
  // builtIn: the region the game lists it in; added: put on a list by hand.
  function serverTable(characters, view = {}) {
    const found = new Map();
    const add = name => {
      const key = serverKey(name);
      if (!key) return null;
      if (!found.has(key)) {
        found.set(key, {key, name: cleanServer(name), region: regionOf(name, view.extra, view.dropped), builtIn: regionOf(name),
          added: Object.keys(REGIONS).some(id => listsServer(view.extra?.[id], key)), count: 0, saved: 0, stale: 0, gold: 0});
      }
      return found.get(key);
    };
    for (const region of Object.values(REGIONS)) for (const name of region.servers) add(name);
    for (const id of Object.keys(REGIONS)) for (const name of Array.isArray(view.extra?.[id]) ? view.extra[id] : []) add(name);
    for (const character of characters) {
      const server = add(character.shownServer);
      if (!server) continue;
      server.count++;
      if (!character.notSaved) server.saved++;
      if (character.stale) server.stale++;
      server.gold += Number(character.gold) || 0;
    }
    return [...found.values()].sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
  }
  // Servers your characters are on that the game's own lists don't name
  function unlistedServers(characters, extra = {}) {
    const found = new Map();
    for (const character of characters) {
      const key = serverKey(character.shownServer);
      if (!key || found.has(key) || REGIONS.eu.servers.concat(REGIONS.na.servers).some(name => name.toLowerCase() === key)) continue;
      found.set(key, {key, name: character.shownServer, region: regionOf(character.shownServer, extra)});
    }
    return [...found.values()].sort((a, b) => a.name.localeCompare(b.name));
  }
  // With nothing chosen yet, the region your characters' servers are in, Europe when nobody says.
  function guessRegion(characters) {
    const votes = {eu: 0, na: 0};
    for (const character of characters) {
      const region = regionOf(character.shownServer);
      if (region) votes[region]++;
    }
    return votes.na > votes.eu ? 'na' : 'eu';
  }

  // Groups for the character tables: by server, by account, or one group of everyone.
  function groupBy(characters, how, accountName) {
    const groups = new Map();
    for (const character of characters) {
      let key = '', title = '';
      if (how === 'server') {
        key = serverKey(character.shownServer);
        title = character.shownServer || NO_SERVER;
      } else if (how === 'account') {
        const linked = accountName ? accountName(character.name) : '';
        if (linked) {
          key = 'gf:' + linked.toLowerCase();
          title = linked;
        } else if (character.group) {
          key = 'group:' + character.group.names[0].toLowerCase() + '|' + serverKey(character.shownServer);
          title = `${character.group.names[0]}'s account, not linked`;
        } else {
          key = '~none';
          title = 'No account known yet';
        }
      }
      if (!groups.has(key)) groups.set(key, {key, title, characters: [], gold: 0, fullCaps: 0, stale: 0, items: 0});
      const group = groups.get(key);
      group.characters.push(character);
      group.gold += character.gold;
      if (character.gold >= FULL_CAP) group.fullCaps++;
      if (character.stale) group.stale++;
      group.items += (character.bag || []).length + (character.bank || []).length;
    }
    const last = key => Number(key === '' || key === '~none');
    return [...groups.values()].sort((a, b) => last(a.key) - last(b.key) || b.characters.length - a.characters.length || a.title.localeCompare(b.title));
  }

  // "Gameforge / RoM account: Main / Alts", leaving out a half the page's checkmarks hide. extra.account(character):
  // its linked Gameforge account while the accounts are open; extra.locked(): whether they're locked;
  // extra.rom(character): its RoM account's name, '' while no login screen has listed it.
  function accountLine(character, extra) {
    const labels = [], names = [];
    if (!extra.hideGameforge) {
      labels.push('Gameforge');
      names.push((extra.account && extra.account(character)) || (extra.locked && extra.locked() ? 'locked' : 'not linked'));
    }
    if (!extra.hideRom) {
      labels.push('RoM');
      names.push((extra.rom && extra.rom(character)) || 'not known yet');
    }
    return labels.length ? {kind: 'row', text: `${labels.join(' / ')} account: ${names.join(' / ')}`} : null;
  }
  // The few lines a hover over a character shows: who, where, what it holds, and what to do about stale data.
  // extra: what accountLine needs, hideGameforge and hideRom, and currencyName(item).
  function describe(character, extra = {}) {
    const lines = [];
    const server = character.shownServer ? character.shownServer + (character.manualServer ? ' (set by hand)' : '') : NO_SERVER;
    const account = accountLine(character, extra);
    if (character.notSaved) {
      lines.push({kind: 'sub', text: server});
      if (account) lines.push(account);
      lines.push({kind: 'warn', text: UNSAVED_NOTE});
      return lines;
    }
    const classes = (character.classes || []).filter(item => item.name).map(item => `${item.name} ${item.level}`);
    lines.push({kind: 'sub', text: [classes.length ? classes.join(' · ') : [character.class, character.level || ''].filter(Boolean).join(' '), server].filter(Boolean).join(' · ')});
    lines.push({kind: 'gold', text: `${number(character.gold)} gold${character.gold >= FULL_CAP ? ' (a full cap)' : ''}`});
    if (account) lines.push(account);
    const bag = (character.bag || []).length, bank = (character.bank || []).length;
    const bagText = character.bagSlots ? `Bag ${number(bag)} of ${number(character.bagSlots)}` : `Bag ${number(bag)}`;
    const bankText = !character.bankSeen ? 'bank not recorded' : character.bankSlots ? `bank ${number(bank)} of ${number(character.bankSlots)}` : `bank ${number(bank)}`;
    lines.push({kind: 'row', text: `${bagText} · ${bankText}`});
    const stones = extra.stones ? extra.stones(character) : '';
    if (stones) lines.push({kind: 'row', text: stones});
    const money = (character.currencies || []).filter(item => Number(item.amount) > 0);
    if (money.length) {
      const named = money.slice(0, 3).map(item => `${extra.currencyName ? extra.currencyName(item) : item.name || item.key} ${number(item.amount)}`);
      lines.push({kind: 'row', text: named.join(' · ') + (money.length > 3 ? ` · and ${money.length - 3} more` : '')});
    }
    const taken = Date.parse(character.dailyLogin?.collectedAt || '');
    if (Number.isFinite(taken)) {
      const when = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'}).format(taken);
      lines.push({kind: 'row', text: `Daily reward: day ${character.dailyLogin.day || '?'}, taken ${when}`});
    }
    if (character.saved) lines.push({kind: 'hint', text: `Saved ${character.saved}`});
    if (character.stale) lines.push({kind: 'warn', text: STALE_NOTE});
    if (character.elsewhere?.length) lines.push({kind: 'hint', text: `The same name is also on ${character.elsewhere.join(', ')}`});
    if (character.note) lines.push({kind: 'note', text: `Note: ${character.note}`});
    return lines;
  }

  // The view and the selection, and who wants to know when they change. Kept in this browser only.
  // Changes it tells about: 'view' (region, ticks, the regions' lists), 'selection', 'scope' (who the Bank shows),
  // 'assigned' (a server set by hand: the page prepares its characters again), 'names' (a RoM account renamed),
  // 'order' and 'card'.
  function create(storage) {
    const view = {region: '', serversOff: new Set(), extra: {}, dropped: new Set(), assigned: Object.create(null),
      hideGameforge: false, hideRom: false, romFirst: false, regionCache: new Map()};
    const selection = new Set();
    const scope = new Set();
    const listeners = new Set();
    let romNames = Object.create(null);
    let characters = [];
    let byKey = new Map();
    let listed = new Map();
    let listedList = [];
    // Each RoM account and its characters, saved or only listed
    let members = new Map();
    const nameCache = new Map();
    let lastClicked = null;
    let lastScoped = null;
    let saveTimer = 0;
    const changed = what => { for (const listener of listeners) listener(what); };
    const keep = data => { if (storage) Promise.resolve(storage.set(data)).catch(() => {}); };
    const stored = () => ({region: view.region, serversOff: [...view.serversOff], extra: view.extra, dropped: [...view.dropped], assigned: {...view.assigned},
      hideGameforge: view.hideGameforge, hideRom: view.hideRom, romFirst: view.romFirst});
    function save() {
      if (!storage) return;
      clearTimeout(saveTimer);
      // A shift-click can pick thousands; one write is plenty.
      saveTimer = setTimeout(() => keep({[VIEW_STORE]: stored(), [SELECTION_STORE]: [...selection], [SCOPE_STORE]: [...scope]}), 200);
    }
    const listsChanged = () => {
      view.regionCache.clear();
      save();
      changed('view');
    };
    // A RoM account's name is kept for each of its characters, by server and name once the server is sure, so it
    // survives characters joining or leaving the login screen. A server set by hand may be wrong: those keep it by name.
    const nameKey = character => (character.manualServer || !character.shownServer ? keyOf(character.base ?? character.name, '') : character.key);
    function romNameOf(group) {
      if (!group) return '';
      if (nameCache.has(group)) return nameCache.get(group);
      let found = '';
      for (const character of members.get(group) || []) {
        found = pick(romNames, nameKey(character)) || pick(romNames, keyOf(character.base ?? character.name, ''));
        if (found) break;
      }
      nameCache.set(group, found);
      return found;
    }
    // Where a server goes: added to a region by hand, or taken off the game's own list for it.
    function place(name, region) {
      const key = serverKey(name);
      if (!key) return;
      for (const id of Object.keys(REGIONS)) view.extra[id] = (Array.isArray(view.extra[id]) ? view.extra[id] : []).filter(server => serverKey(server) !== key);
      const builtIn = regionOf(name);
      if (builtIn && builtIn !== region) view.dropped.add(key);
      else view.dropped.delete(key);
      if (REGIONS[region] && region !== builtIn) view.extra[region].push(cleanServer(name));
    }
    const api = {
      view, selection, scope,
      onChange(listener) { listeners.add(listener); return () => listeners.delete(listener); },
      async load() {
        if (!storage) return;
        const saved = await storage.get([VIEW_STORE, SELECTION_STORE, SCOPE_STORE, NAMES_STORE]).catch(() => ({}));
        const kept = saved[VIEW_STORE] || {};
        view.region = typeof kept.region === 'string' ? kept.region : '';
        view.serversOff = new Set(Array.isArray(kept.serversOff) ? kept.serversOff : []);
        view.extra = {};
        for (const id of Object.keys(REGIONS)) view.extra[id] = Array.isArray(kept.extra?.[id]) ? kept.extra[id].filter(name => typeof name === 'string' && cleanServer(name)) : [];
        view.dropped = new Set(Array.isArray(kept.dropped) ? kept.dropped.filter(key => typeof key === 'string') : []);
        view.assigned = textMap(kept.assigned);
        view.hideGameforge = !!kept.hideGameforge;
        view.hideRom = !!kept.hideRom;
        view.romFirst = !!kept.romFirst;
        view.regionCache.clear();
        romNames = textMap(saved[NAMES_STORE]);
        nameCache.clear();
        for (const key of Array.isArray(saved[SELECTION_STORE]) ? saved[SELECTION_STORE] : []) selection.add(key);
        for (const key of Array.isArray(saved[SCOPE_STORE]) ? saved[SCOPE_STORE] : []) scope.add(key);
      },
      setCharacters(list) {
        characters = list;
        byKey = new Map(list.map(character => [character.key, character]));
        members = new Map();
        for (const character of list) {
          if (!character.romAccount) continue;
          if (!members.has(character.romAccount)) members.set(character.romAccount, []);
          members.get(character.romAccount).push(character);
        }
        listed = listedOf(list, members, view.assigned);
        for (const [key, character] of [...listed]) {
          // A saved character's key wins
          if (byKey.has(key)) listed.delete(key);
          else members.get(character.romAccount).push(character);
        }
        listedList = [...listed.values()];
        nameCache.clear();
        if (!view.region) view.region = guessRegion(list);
      },
      characters: () => characters,
      // Saved characters, and names only a login screen listed
      byKey: key => byKey.get(key) || listed.get(key) || null,
      listed: () => listedList,
      shows: character => shows(character, view),
      inRegion: character => inRegion(character, view),
      // Characters the page shows, in the region and on ticked servers
      shown: () => characters.filter(character => shows(character, view)),
      servers: () => serverList(characters, view),
      lists: () => regionLists(view),
      serverTable: () => serverTable(characters.concat(listedList), view),
      // Whether the Bank shows only the characters in its scope. A scope wholly on servers not shown doesn't empty it.
      scoped: () => scope.size > 0 && characters.some(character => scope.has(character.key) && shows(character, view)),
      inScope: key => scope.has(key),
      // The characters in the scope that the page shows
      inScopeShown: () => characters.filter(character => scope.has(character.key) && shows(character, view)),
      setScope(keys) {
        scope.clear();
        for (const key of keys) scope.add(key);
        lastScoped = null;
        save();
        changed('scope');
      },
      clearScope: () => api.setScope([]),
      // Use in Bank: the selected characters that hold anything, which a name only a login screen listed doesn't
      useSelection: () => api.setScope(api.selected().map(character => character.key)),
      toggleScope(key) {
        if (scope.has(key)) scope.delete(key);
        else scope.add(key);
        lastScoped = key;
        save();
        changed('scope');
      },
      // Shift-click in the Bank's own list: everything between the last tick and this one
      scopeRange(keys, key) {
        const from = keys.indexOf(lastScoped), to = keys.indexOf(key);
        if (from < 0 || to < 0) return api.toggleScope(key);
        const on = !scope.has(key) || scope.has(lastScoped);
        for (let i = Math.min(from, to); i <= Math.max(from, to); i++) {
          if (on) scope.add(keys[i]);
          else scope.delete(keys[i]);
        }
        lastScoped = key;
        save();
        changed('scope');
      },
      setRegion(region) {
        view.region = region;
        save();
        changed('view');
      },
      setServer(key, on) {
        if (on) view.serversOff.delete(key);
        else view.serversOff.add(key);
        save();
        changed('view');
      },
      // The regions' lists, edited by hand: a server moved to a region, or to none ('')
      setServerRegion(name, region) {
        place(name, region);
        listsChanged();
      },
      // A server for a region's list, even with nobody saved there yet. Says what's wrong, or ''.
      addServer(name, region) {
        const server = cleanServer(name);
        if (!server) return 'Type the server\'s name first.';
        if (server.length > 40) return 'That name is too long for a server.';
        if (!REGIONS[region]) return 'Pick a region.';
        if (regionOf(server, view.extra, view.dropped) === region) return `${REGIONS[region].name} lists ${server} already.`;
        place(server, region);
        listsChanged();
        return '';
      },
      // Off every list: a server added by hand goes, one of the game's own moves to No region
      removeServer(name) {
        place(name, '');
        listsChanged();
      },
      resetRegions() {
        for (const id of Object.keys(REGIONS)) view.extra[id] = [];
        view.dropped.clear();
        listsChanged();
      },
      // Servers set by hand, by name, for characters whose server nothing else tells. '' forgets them.
      assigned: () => view.assigned,
      setServerOf(list, server) {
        const name = cleanServer(server).slice(0, 40);
        for (const character of list) {
          const key = String(character.base ?? character.name ?? '').toLowerCase();
          if (!key) continue;
          if (name) view.assigned[key] = name;
          else delete view.assigned[key];
        }
        save();
        changed('assigned');
      },
      // Run what prepares the characters again, keeping the selection on the same characters when their keys change
      rekey(run) {
        const saved = characters.filter(character => selection.has(character.key));
        const scoped = characters.filter(character => scope.has(character.key));
        const names = new Set(listedList.filter(character => selection.has(character.key)).map(character => character.name.toLowerCase()));
        for (const character of saved) selection.delete(character.key);
        for (const character of scoped) scope.delete(character.key);
        for (const character of listedList) if (names.has(character.name.toLowerCase())) selection.delete(character.key);
        run();
        for (const character of saved) selection.add(character.key);
        for (const character of scoped) scope.add(character.key);
        for (const character of listedList) if (names.has(character.name.toLowerCase())) selection.add(character.key);
        save();
        changed('selection');
        changed('scope');
      },
      // A character's RoM account: the login screen's group, its characters, and the name you gave it ('' for none)
      romAccount(character) {
        const group = character?.romAccount;
        return group ? {group, characters: members.get(group) || [character], name: romNameOf(group)} : null;
      },
      // The name you gave its RoM account, or ''
      romName: character => romNameOf(character?.romAccount),
      // The name to show: yours, or the first name on its login screen's list; '' while no list names it. Steam's says so.
      romTitle(character) {
        const group = character?.romAccount;
        if (!group) return '';
        if (group.steam) return romNameOf(group) ? `${romNameOf(group)} (Steam)` : 'Steam account';
        return romNameOf(group) || `${group.names[0]}'s account`;
      },
      setRomName(character, name) {
        const group = character?.romAccount;
        if (!group) return;
        const text = String(name || '').trim().slice(0, 60);
        for (const member of members.get(group) || []) {
          const key = nameKey(member);
          const loose = keyOf(member.base ?? member.name, '');
          if (text) romNames[key] = text;
          else delete romNames[key];
          // The name kept before its server was known
          if (key !== loose) delete romNames[loose];
        }
        nameCache.clear();
        keep({[NAMES_STORE]: {...romNames}});
        changed('names');
      },
      // The page's checkmarks for the hover card, and which comes first on the Gameforge accounts tab
      setCard(what, on) {
        if (what === 'gameforge') view.hideGameforge = !!on;
        else view.hideRom = !!on;
        save();
        changed('card');
      },
      setRomFirst(on) {
        view.romFirst = !!on;
        save();
        changed('order');
      },
      // The selected characters the page shows; a selection hidden by the region still counts when it comes back.
      selected: () => characters.filter(character => selection.has(character.key) && shows(character, view)),
      // The same, with the names only a login screen listed
      selectedAll: () => characters.concat(listedList).filter(character => selection.has(character.key) && shows(character, view)),
      // How many selected characters the page shows, and how many the region or the ticks hide
      counts() {
        let shown = 0, hidden = 0;
        for (const key of selection) {
          const character = byKey.get(key) || listed.get(key);
          if (!character) continue;
          if (shows(character, view)) shown++;
          else hidden++;
        }
        return {shown, hidden};
      },
      isSelected: key => selection.has(key),
      toggle(key, on = !selection.has(key)) {
        if (on) selection.add(key);
        else selection.delete(key);
        lastClicked = key;
        save();
        changed('selection');
      },
      // Shift-click: everything between the last click and this one, in the order a list shows them
      range(keys, key) {
        const from = keys.indexOf(lastClicked), to = keys.indexOf(key);
        if (from < 0 || to < 0) return api.toggle(key);
        const on = !selection.has(key) || selection.has(lastClicked);
        for (let i = Math.min(from, to); i <= Math.max(from, to); i++) {
          if (on) selection.add(keys[i]);
          else selection.delete(keys[i]);
        }
        lastClicked = key;
        save();
        changed('selection');
      },
      setSelection(keys) {
        selection.clear();
        for (const key of keys) selection.add(key);
        save();
        changed('selection');
      },
      clearSelection() {
        selection.clear();
        lastClicked = null;
        save();
        changed('selection');
      },
    };
    return api;
  }

  // The hover card for any element with data-char (click selects it) or data-char-tip (hover only), and the
  // clicks, for every tab at once: one set of listeners, however many characters there are.
  // options: what describe() needs, classColor(character), menu(event, rows, owners, after) for the right-click
  // menu, and rows(character): the menu's own rows for that character.
  function attach(roster, tooltip, options = {}) {
    const make = (tag, className, text) => {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    };
    let shownKey = null;
    function place(event) {
      tooltip.style.left = Math.max(4, Math.min(event.clientX + 16, window.innerWidth - tooltip.offsetWidth - 8)) + 'px';
      tooltip.style.top = Math.max(4, Math.min(event.clientY + 16, window.innerHeight - tooltip.offsetHeight - 8)) + 'px';
    }
    function show(event, key, clickable = true) {
      const character = roster.byKey(key);
      if (!character) return;
      shownKey = key;
      const title = make('strong', 'char-tip-name', character.name);
      const color = options.classColor ? options.classColor(character) : null;
      if (color) title.style.color = color;
      const nodes = [title];
      for (const line of describe(character, {...options, hideGameforge: roster.view.hideGameforge, hideRom: roster.view.hideRom})) nodes.push(make('span', `char-tip-${line.kind}`, line.text));
      const selected = roster.isSelected(key);
      nodes.push(make('span', 'char-tip-hint', (selected ? 'Selected. ' : '') + (clickable ? 'Click to select, Shift-click for a range. ' : '') + 'Right-click to copy its login or rename its accounts.'));
      tooltip.replaceChildren(...nodes);
      tooltip.hidden = false;
      place(event);
    }
    const keyAt = target => target?.closest?.('[data-char], [data-char-tip]');
    document.addEventListener('mouseover', event => {
      const node = keyAt(event.target);
      const key = node ? node.dataset.char || node.dataset.charTip : null;
      if (!key) {
        if (shownKey) { tooltip.hidden = true; shownKey = null; }
        return;
      }
      if (key !== shownKey) show(event, key, !!node.dataset.char);
    });
    document.addEventListener('mousemove', event => { if (shownKey && !tooltip.hidden) place(event); }, {passive: true});
    document.addEventListener('scroll', () => { tooltip.hidden = true; shownKey = null; }, {passive: true, capture: true});
    document.addEventListener('click', event => {
      const node = event.target?.closest?.('[data-char]');
      if (!node || event.button !== 0 || event.target.closest('a, input:not(.char-check), select, textarea, button:not([data-char])')) return;
      const key = node.dataset.char;
      if (event.shiftKey) {
        const scope = node.closest('[data-select-scope]') || document;
        roster.range([...scope.querySelectorAll('[data-char]')].map(item => item.dataset.char), key);
        // Ticking a range shouldn't also select the page's text
        window.getSelection?.()?.removeAllRanges?.();
      } else roster.toggle(key);
      if (shownKey === key) show(event, key);
    });
    document.addEventListener('contextmenu', event => {
      const node = keyAt(event.target);
      if (!node || !options.menu) return;
      const character = roster.byKey(node.dataset.char || node.dataset.charTip);
      if (!character) return;
      tooltip.hidden = true;
      shownKey = null;
      options.menu(event, [], [character], options.rows ? options.rows(character) : []);
    });
  }

  return {NO_SERVER, FULL_CAP, REGIONS, STALE_NOTE, UNSAVED_NOTE, number, escapeHtml, cleanServer, serverKey, keyOf, prepare, regionOf, regionLists, inRegion, shows,
    serverList, serverTable, unlistedServers, guessRegion, groupBy, describe, accountLine, create, attach};
})();
