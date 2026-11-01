'use strict';
// The Bank tab: everything every character holds, in one scrolling grid like the game's own bank, with a search,
// filters, stacking rules, favourites and the game's own tooltips. The Favourites, Currencies, Stats and Characters
// tabs read the same data. Only the rows and slots on screen are drawn, so thousands of characters stay quick.
const GBBank = (() => {
  // The game's own pages: 30 bag slots, 40 bank slots. Bank slots after 200 are the item shop's tab.
  const PER_PAGE = {bag: 30, bank: 40};
  const PLACE = {bag: 'Bag', bank: 'Bank', shop: 'Item shop tab'};
  const SHOP_FROM = 200;
  const MAX_HOLDERS = 10;
  const TYPES = ['Armour', 'Weapons', 'Jewellery', 'Runes', 'Mana stones', 'Potions', 'Materials', 'Recipes', 'Mounts and pets', 'Other'];
  const EQUIPPABLE = new Set(['Weapons', 'Armour', 'Jewellery']);
  // Like the game: gear is one of a kind, and so is anything with stats of its own.
  const DEFAULT_RULES = {on: true, types: new Set(TYPES.filter(type => !EQUIPPABLE.has(type))), stats: 'apart', always: new Set()};
  const NO_STACK = {on: false, types: new Set(), stats: 'apart', always: new Set()};
  const QUALITY = ['Plain', 'Green', 'Blue', 'Purple', 'Orange', 'Gold'];
  // Bought with real money and shared by an account, so adding them up across characters would count them twice.
  const SHOP_NAMES = {account: 'Diamonds', bonus: 'Bonus', billdin: 'Billdin'};
  const FIXED_NAMES = {transmutor: 'Arcane Transmutor Charges'};
  // The order of the game's own currency window
  const CURRENCY_ORDER = ['transmutor', '11', '12', '10', '17', '21', '9', '13', '15', '16', '4', '8', '14', '18', '19', '22', '23', 'account', 'bonus', 'billdin'];
  const SLOT = 44, GAP = 2, PAD = 10;
  const FULL_CAP = 999999999;

  function formatNumber(value) {
    return Number(value || 0).toLocaleString('en-US');
  }
  const escapeHtml = text => String(text ?? '').replace(/[&<>"']/g, letter => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[letter]));
  // Saved data has no item type, so this goes by the game's ID ranges and icon names. A good guess, not a fact.
  function typeOf(id, icon) {
    const number = Number(id) || 0;
    const path = String(icon || '').toLowerCase();
    if (number >= 520000 && number < 530000) return 'Runes';
    if (number >= 550000 && number < 560000) return 'Recipes';
    if (/earring|eq_ear|eq_neck|eq_finger|ring_|jewelry\//.test(path) && number >= 220000 && number < 240000) return 'Jewellery';
    if (number >= 210000 && number < 220000) return 'Weapons';
    if (number >= 220000 && number < 240000) return 'Armour';
    if ((number >= 202840 && number <= 202859) || (number >= 202880 && number <= 202885) || /mana stone|fusnion_stone/.test(path)) return 'Mana stones';
    if (/potion/.test(path)) return 'Potions';
    if (/item_ore|item_mat|phantom\/material/.test(path)) return 'Materials';
    if (/mount|charger|pet_|egg/.test(path)) return 'Mounts and pets';
    return 'Other';
  }
  // The colour the game gives an item's name, as a quality: 0 plain, 1 green, 2 blue, 3 purple, 4 orange, 5 gold.
  function qualityOf(color) {
    if (!/^[0-9a-f]{6}$/i.test(color || '')) return 0;
    const [r, g, b] = [0, 2, 4].map(at => parseInt(color.slice(at, at + 2), 16) / 255);
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    if (max - min < 0.2) return 0;
    let hue = max === r ? (g - b) / (max - min) : max === g ? 2 + (b - r) / (max - min) : 4 + (r - g) / (max - min);
    hue = (hue * 60 + 360) % 360;
    if (hue >= 75 && hue < 165) return 1;
    if (hue >= 165 && hue < 255) return 2;
    if (hue >= 255 && hue < 335) return 3;
    if (hue >= 45 && hue < 75) return 5;
    return 4;
  }
  // How long something has run: 45 min, or 2 h 14 min, or 3 days 2 h
  function formatDuration(seconds) {
    const minutes = Math.max(0, Math.floor(seconds / 60));
    if (minutes < 60) return `${minutes} min`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} h ${minutes % 60} min`;
    return `${Math.floor(hours / 24)} days ${hours % 24} h`;
  }
  // Characters, stacks and items in all, for the page's status line
  function totals(characters) {
    let stacks = 0, items = 0;
    for (const character of characters) {
      for (const place of ['bag', 'bank']) {
        for (const item of character[place] || []) {
          stacks++;
          items += Number(item.count) || 1;
        }
      }
    }
    return {characters: characters.length, stacks, items};
  }
  // Bank 45 (page 2, slot 5)
  function locationLabel(place, slot) {
    if (place === 'bank' && slot > SHOP_FROM) return `Bank ${slot} (item shop tab, slot ${slot - SHOP_FROM})`;
    const perPage = PER_PAGE[place];
    const page = Math.floor((slot - 1) / perPage) + 1;
    return `${PLACE[place]} ${slot} (page ${page}, slot ${slot - (page - 1) * perPage})`;
  }
  function itemKey(entry) {
    return String(entry.id || entry.name);
  }
  // One row for each stack on each character, with what a search and the filters need worked out once.
  function entries(characters) {
    const list = [];
    for (const character of characters) {
      const level = Number(character.level) || 0;
      for (const place of ['bag', 'bank']) {
        for (const item of character[place] || []) {
          const gear = item.gear || null;
          const stats = gear?.stats || item.stats || [];
          const name = String(item.name || 'Unknown item');
          const color = /^[0-9a-f]{6}$/i.test(gear?.color || '') ? gear.color : /^[0-9a-f]{6}$/i.test(item.tip?.[0]?.[0] || '') ? item.tip[0][0] : '';
          list.push({id: item.id, name, lower: name.toLowerCase(), icon: item.icon, count: Number(item.count) || 1,
            type: typeOf(item.id, item.icon), bound: !!item.bound, gear, stats, stone: !!item.stats, tip: item.tip || null, color, quality: qualityOf(color),
            search: stats.concat(gear?.runes || []).join('\n').toLowerCase(), character: character.name, ch: character, level, place,
            shop: place === 'bank' && Number(item.slot) > SHOP_FROM, slot: Number(item.slot) || 0});
        }
      }
    }
    return list;
  }
  // The test each item passes to be shown. keep(character) says whether its holder is on the page at all.
  function matcher(filters) {
    const text = (filters.text || '').toLowerCase();
    const anyStat = names => names.some(name => name.toLowerCase().includes(text));
    return entry => {
      if (text) {
        if (filters.searchIn === 'items') { if (entry.stone || !anyStat(entry.stats)) return false; }
        else if (filters.searchIn === 'stones') { if (!entry.stone || !anyStat(entry.stats)) return false; }
        else if (!(entry.lower ?? entry.name.toLowerCase()).includes(text) && !(entry.search ?? '').includes(text) && !anyStat(entry.stats) && !anyStat(entry.gear?.runes || [])) return false;
      }
      if (filters.type && entry.type !== filters.type) return false;
      if (filters.place === 'shop' ? !entry.shop : filters.place && entry.place !== filters.place) return false;
      if (filters.hidden && filters.hidden.has(entry.character)) return false;
      if (filters.keep && entry.ch && !filters.keep(entry.ch)) return false;
      if (filters.minLevel && entry.level < filters.minLevel) return false;
      if (filters.maxLevel && entry.level > filters.maxLevel) return false;
      if (filters.binding === 'bound' && !entry.bound) return false;
      if (filters.binding === 'free' && entry.bound) return false;
      if (filters.minQuality && (entry.quality || 0) < filters.minQuality) return false;
      if (filters.statsOnly && !entry.stats.length) return false;
      if (filters.favourites && !filters.favourites.has(itemKey(entry))) return false;
      return true;
    };
  }
  function applyFilters(list, filters) {
    return list.filter(matcher(filters));
  }
  // Names repeat between servers. Everywhere on the page, a name that does carries its server.
  function tellApart(characters) {
    const count = new Map();
    for (const character of characters) {
      const key = String(character.name).toLowerCase();
      count.set(key, (count.get(key) || 0) + 1);
    }
    for (const character of characters) {
      if (count.get(String(character.name).toLowerCase()) > 1 && character.server) character.name = `${character.name} (${character.server})`;
    }
    return characters;
  }
  // An item's own choice comes first: always keep, then excluded, then the rule for bound items.
  function isHidden(entry, settings) {
    const key = itemKey(entry);
    if (settings.whitelist.has(key)) return false;
    if (settings.excluded.has(key)) return true;
    return !!settings.excludeBound && entry.bound && !EQUIPPABLE.has(entry.type);
  }
  // The right-click on an item: a shown one becomes excluded, and an excluded one comes back.
  function toggleHidden(entry, settings) {
    const key = itemKey(entry);
    if (isHidden(entry, settings)) {
      settings.excluded.delete(key);
      if (isHidden(entry, settings)) settings.whitelist.add(key);
    } else {
      settings.whitelist.delete(key);
      settings.excluded.add(key);
    }
  }
  // What tells two copies of an item apart: a piece of gear's plus, tier, stats and runes, or a stone's stats.
  function statsSignature(entry) {
    if (entry.gear) return ['g', entry.gear.plus, entry.gear.tier, entry.gear.stats.join(';'), entry.gear.runes.join(';')].join('/');
    return 's/' + entry.stats.join(';');
  }
  // Which stack an item joins, or null when it stays on its own. An item you chose to always stack joins every copy
  // of itself; otherwise its type has to be ticked, and anything with stats stacks only as the rules for stats say.
  function stackKey(entry, rules = DEFAULT_RULES) {
    const key = itemKey(entry);
    if (rules.always?.has(key)) return 'k:' + key;
    if (!rules.on || !rules.types.has(entry.type)) return null;
    if (!(entry.gear || entry.stats.length) || rules.stats === 'all') return 'k:' + key;
    if (rules.stats === 'match') return 'k:' + key + '|' + statsSignature(entry);
    return null;
  }
  function stackable(entry) {
    return stackKey(entry, DEFAULT_RULES) !== null;
  }
  // One cell for each item, or for each stack the rules allow, and everywhere it is.
  function cells(list, stack = true) {
    const rules = stack === true ? DEFAULT_RULES : stack ? stack : NO_STACK;
    const found = new Map();
    const out = [];
    for (let index = 0; index < list.length; index++) {
      const entry = list[index];
      const key = stackKey(entry, rules) ?? '#' + index;
      let cell = found.get(key);
      if (!cell) {
        cell = {key: itemKey(entry), id: entry.id, name: entry.name, icon: entry.icon, type: entry.type, gear: entry.gear, stats: entry.stats, stone: entry.stone,
          tip: entry.tip, color: entry.color || '', quality: entry.quality || 0, bound: entry.bound, total: 0, places: [], mixed: false};
        found.set(key, cell);
        out.push(cell);
      } else if (!cell.mixed && (entry.gear || entry.stats.length || cell.gear || cell.stats.length) && statsSignature(entry) !== statsSignature(cell.places[0])) cell.mixed = true;
      cell.total += entry.count;
      cell.places.push(entry);
    }
    return out;
  }
  const SORTS = {
    name: (a, b) => a.name.localeCompare(b.name),
    count: (a, b) => b.total - a.total || a.name.localeCompare(b.name),
    type: (a, b) => a.type.localeCompare(b.type) || a.name.localeCompare(b.name),
    quality: (a, b) => b.quality - a.quality || a.name.localeCompare(b.name),
    id: (a, b) => (Number(a.id) || 0) - (Number(b.id) || 0) || a.name.localeCompare(b.name),
  };
  // A piece of gear's details, one line each, for the tooltip
  function gearLines(gear) {
    const lines = [`Durability ${formatNumber(gear.dura)} / ${formatNumber(gear.maxDura)}`];
    const levels = [];
    if (gear.plus > 0) levels.push(`+${gear.plus}`);
    if (gear.tier > 0) levels.push(`Tier +${gear.tier}`);
    if (levels.length) lines.push(levels.join(' · '));
    if (gear.stats.length) lines.push(`Stats: ${gear.stats.join(', ')}`);
    if (gear.runes.length) lines.push(`Runes: ${gear.runes.join(', ')}`);
    if (gear.freeSlots > 0) lines.push(`Free rune slots: ${gear.freeSlots}`);
    return lines;
  }
  // The game's own tooltip as it was saved, a line at a time: [colour, text, colour, text]
  function tipLines(tip) {
    const color = value => (/^[0-9a-f]{6}$/i.test(value || '') ? `#${value}` : null);
    return (tip || []).map(line => ({left: String(line[1] || ''), leftColor: color(line[0]), right: String(line[3] || ''), rightColor: color(line[2])}));
  }
  // Without the game's own tooltip: the lines the game would show, from what was saved. Each is {text, kind}.
  function itemLines(cell) {
    const lines = [];
    if (cell.bound) lines.push({text: 'Bound', kind: 'plain'});
    lines.push({text: `${cell.type} · ${formatNumber(cell.total)} in all`, kind: 'type'});
    if (cell.mixed) {
      const kinds = new Map();
      for (const entry of cell.places) {
        const label = entry.gear ? [entry.gear.plus > 0 ? `+${entry.gear.plus}` : '', ...entry.gear.stats].filter(Boolean).join(', ') || 'no stats' : entry.stats.join(', ') || 'no stats';
        kinds.set(label, (kinds.get(label) || 0) + entry.count);
      }
      lines.push({text: `${formatNumber(kinds.size)} different kinds, stacked by your choice:`, kind: 'type'});
      for (const [label, count] of [...kinds.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8)) lines.push({text: `${formatNumber(count)} × ${label}`, kind: 'stat'});
      if (kinds.size > 8) lines.push({text: `and ${kinds.size - 8} more kinds`, kind: 'type'});
    } else if (cell.gear) {
      for (const text of gearLines(cell.gear)) lines.push({text, kind: 'plain'});
    } else if (cell.stats.length) {
      for (const text of cell.stats) lines.push({text, kind: 'stat'});
    }
    const stale = cell.places.find(entry => entry.ch?.stale && !entry.gear && !entry.stats.length && (EQUIPPABLE.has(entry.type) || entry.type === 'Mana stones'));
    if (stale) lines.push({text: `Stats unknown: ${stale.character} saved this with an older Global Bank. Log in with it once to read them.`, kind: 'warn'});
    return lines;
  }
  // Who holds a cell's items, one row each, most first: {name, server, parts: ['Bag 10 (page 1, slot 10)', 'Bank × 30']}
  function holders(places) {
    const found = new Map();
    for (const entry of places) {
      const id = entry.ch?.key || entry.character;
      if (!found.has(id)) found.set(id, {name: entry.character, key: entry.ch?.key || '', server: entry.ch?.shownServer || '', count: 0, at: {bag: [], bank: [], shop: []}});
      const row = found.get(id);
      row.count += entry.count;
      row.at[entry.shop ? 'shop' : entry.place].push(entry);
    }
    return [...found.values()].sort((a, b) => b.count - a.count || a.name.localeCompare(b.name)).map(row => {
      const parts = [];
      for (const place of ['bag', 'bank', 'shop']) {
        const list = row.at[place];
        if (!list.length) continue;
        const count = list.reduce((sum, entry) => sum + entry.count, 0);
        parts.push(list.length === 1 ? locationLabel(list[0].place, list[0].slot) + (count > 1 ? ` × ${formatNumber(count)}` : '')
          : `${PLACE[place]} × ${formatNumber(count)} in ${list.length} slots`);
      }
      return {name: row.name, key: row.key, server: row.server, count: row.count, parts};
    });
  }

  // The Currencies tab: a column for each currency anyone has, a total, and the characters in the order asked for.
  function currencyName(money) {
    return SHOP_NAMES[money.key] || FIXED_NAMES[money.key] || money.name || `Currency ${money.key}`;
  }
  function currencyTable(characters, sort, descending) {
    const columns = new Map([['gold', {key: 'gold', name: 'Gold', total: 0, shop: false}]]);
    const rows = characters.map(character => {
      const amounts = {gold: Number(character.gold) || 0};
      for (const money of character.currencies || []) {
        amounts[money.key] = Number(money.amount) || 0;
        const shop = money.key in SHOP_NAMES;
        if (!columns.has(money.key)) columns.set(money.key, {key: money.key, name: currencyName(money), total: 0, shop});
      }
      return {name: character.name, key: character.key, server: character.shownServer ?? character.server ?? '', stale: !!character.stale, character, amounts};
    });
    for (const column of columns.values()) {
      column.total = column.shop ? null : rows.reduce((sum, row) => sum + (row.amounts[column.key] || 0), 0);
    }
    const direction = descending ? -1 : 1;
    rows.sort((a, b) => (sort === 'name' ? a.name.localeCompare(b.name) * direction
      : sort === 'server' ? (a.server.localeCompare(b.server) * direction || a.name.localeCompare(b.name))
        : ((a.amounts[sort] || 0) - (b.amounts[sort] || 0)) * direction || a.name.localeCompare(b.name)));
    const list = [...columns.values()];
    const place = key => { const at = CURRENCY_ORDER.indexOf(key); return at < 0 ? CURRENCY_ORDER.length : at; };
    return {columns: [list[0], ...list.slice(1).sort((a, b) => place(a.key) - place(b.key) || a.name.localeCompare(b.name))], rows};
  }
  // The Stats tab: each stat on items or on mana stones, how many there are, and who holds them.
  function statTable(characters, kind, text, sort, descending) {
    const wanted = String(text || '').toLowerCase();
    const found = new Map();
    for (const entry of Array.isArray(characters?.entries) ? characters.entries : entries(characters)) {
      if (kind === 'stones' ? !entry.stone : entry.stone) continue;
      for (const stat of entry.stats) {
        if (wanted && !stat.toLowerCase().includes(wanted)) continue;
        if (!found.has(stat)) found.set(stat, {stat, total: 0, owners: new Map()});
        const row = found.get(stat);
        row.total += entry.count;
        const owner = row.owners.get(entry.character) || {name: entry.character, key: entry.ch?.key || '', count: 0};
        owner.count += entry.count;
        row.owners.set(entry.character, owner);
      }
    }
    const rows = [...found.values()].map(row => ({stat: row.stat, total: row.total, characters: row.owners.size,
      owners: [...row.owners.values()].map(({name, count, key}) => (key ? {name, count, key} : {name, count})).sort((a, b) => b.count - a.count || a.name.localeCompare(b.name))}));
    const direction = descending ? -1 : 1;
    const key = sort === 'breakdown' ? 'characters' : sort;
    return rows.sort((a, b) => (key === 'stat' ? a.stat.localeCompare(b.stat) : a[key] - b[key]) * direction || a.stat.localeCompare(b.stat));
  }
  // The Characters tab: one row for each, with the last daily reward taken.
  const ROSTER_COLUMNS = [
    {key: 'name', name: 'Character', text: true},
    {key: 'server', name: 'Server', text: true},
    {key: 'account', name: 'Gameforge account', text: true},
    {key: 'rom', name: 'RoM account', text: true},
    {key: 'class', name: 'Class', text: true},
    {key: 'level', name: 'Level'},
    {key: 'gold', name: 'Gold'},
    {key: 'bag', name: 'Bag'},
    {key: 'bank', name: 'Bank'},
    {key: 'saved', name: 'Last saved', text: true},
    {key: 'day', name: 'Reward day'},
    {key: 'taken', name: 'Reward taken'},
  ];
  // The RoM account to show: the name you gave it, or the first name on its login screen's list
  const romOf = (character, romTitle) => (romTitle ? romTitle(character) : '')
    || ((character.romAccount || character.group) ? `${(character.romAccount || character.group).names[0]}'s account` : '');
  function rosterRows(characters, sort, descending, accountName, romTitle) {
    const rows = characters.map(character => {
      const taken = Date.parse(character.dailyLogin?.collectedAt || '');
      const bag = (character.bag || []).length, bank = (character.bank || []).length;
      const linked = accountName ? accountName(character.name) : '';
      return {name: String(character.name || ''), key: character.key, character, server: String(character.shownServer ?? character.server ?? ''),
        account: linked, rom: romOf(character, romTitle),
        class: String(character.class || ''), level: Number(character.level) || 0,
        gold: Number(character.gold) || 0, items: bag + bank, bag, bank, bankSeen: !!character.bankSeen, stale: !!character.stale,
        saved: String(character.saved || ''), day: Number(character.dailyLogin?.day) || 0, taken: Number.isFinite(taken) ? taken : 0};
    });
    const direction = descending ? -1 : 1;
    const text = ROSTER_COLUMNS.find(column => column.key === sort)?.text;
    return rows.sort((a, b) => (text ? a[sort].localeCompare(b[sort]) : a[sort] - b[sort]) * direction || a.name.localeCompare(b.name));
  }

  // Grouped tables (Characters, Currencies): a heading row per group with its totals, click a heading to sort, and
  // rows a click selects. Drawn as one piece of HTML, so a few thousand rows take a moment, not seconds.
  function groupedTable(root, spec) {
    const table = root.querySelector('table');
    const sorting = root.sorting;
    const head = spec.columns.map(column => {
      const mark = sorting.key === column.key ? (sorting.descending ? ' ▼' : ' ▲') : '';
      return `<th class="${column.number ? 'num' : ''}"><button type="button" data-sort="${escapeHtml(column.key)}" data-text="${column.text ? 1 : ''}">${escapeHtml(column.name + mark)}</button></th>`;
    }).join('');
    table.querySelector('thead').innerHTML = `<tr>${head}</tr>`;
    const parts = [];
    const span = spec.columns.length;
    for (const group of spec.groups) {
      if (group.title !== null) {
        const closed = !spec.open && root.collapsed.has(group.key);
        const cellsHtml = spec.groupCells ? spec.groupCells(group) : null;
        if (cellsHtml) {
          parts.push(`<tr class="group-row" data-group="${escapeHtml(group.key)}"><td colspan="${spec.groupSpan || 1}"><button type="button" class="group-toggle" data-group-toggle="${escapeHtml(group.key)}">${closed ? '▸' : '▾'} ${escapeHtml(group.title)}</button> <span class="group-sub">${escapeHtml(group.sub)}</span> <button type="button" class="group-select" data-group-select="${escapeHtml(group.key)}">Select</button></td>${cellsHtml}</tr>`);
        } else {
          parts.push(`<tr class="group-row" data-group="${escapeHtml(group.key)}"><td colspan="${span}"><button type="button" class="group-toggle" data-group-toggle="${escapeHtml(group.key)}">${closed ? '▸' : '▾'} ${escapeHtml(group.title)}</button> <span class="group-sub">${escapeHtml(group.sub)}</span> <button type="button" class="group-select" data-group-select="${escapeHtml(group.key)}">Select</button></td></tr>`);
        }
        if (closed) continue;
      }
      for (const row of group.rows) {
        const selected = spec.isSelected && spec.isSelected(row.key) ? ' is-selected' : '';
        parts.push(`<tr data-char="${escapeHtml(row.key || '')}" class="char-row${selected}${row.stale ? ' is-stale' : ''}">${spec.columns.map(column => `<td class="${column.number ? 'num' : ''}">${column.cell(row)}</td>`).join('')}</tr>`);
      }
    }
    if (!parts.length) parts.push(`<tr><td colspan="${span}" class="hint">${escapeHtml(spec.empty || 'Nothing to show.')}</td></tr>`);
    table.querySelector('tbody').innerHTML = parts.join('');
    if (!root.wired) {
      root.wired = true;
      table.addEventListener('click', event => {
        const sortButton = event.target.closest('[data-sort]');
        if (sortButton) {
          const key = sortButton.dataset.sort;
          root.sorting.descending = root.sorting.key === key ? !root.sorting.descending : !sortButton.dataset.text;
          root.sorting.key = key;
          root.redraw();
          return;
        }
        const toggle = event.target.closest('[data-group-toggle]');
        if (toggle) {
          const key = toggle.dataset.groupToggle;
          if (root.collapsed.has(key)) root.collapsed.delete(key);
          else root.collapsed.add(key);
          root.redraw();
          return;
        }
        const pick = event.target.closest('[data-group-select]');
        if (pick && root.selectGroup) root.selectGroup(pick.dataset.groupSelect);
      });
    }
  }
  // Groups for a table, sorted rows inside each. A long list starts with its groups closed.
  function tableGroups(root, rows, how, groupOf, titleOf) {
    if (how === 'none') return [{key: '', title: null, sub: '', rows}];
    const groups = new Map();
    for (const row of rows) {
      const key = groupOf(row);
      if (!groups.has(key)) groups.set(key, {key, title: titleOf(row), rows: []});
      groups.get(key).rows.push(row);
    }
    const list = [...groups.values()].sort((a, b) => Number(a.key === '' || a.key === '~none') - Number(b.key === '' || b.key === '~none') || b.rows.length - a.rows.length || a.title.localeCompare(b.title));
    if (!root.collapsedSet) {
      root.collapsedSet = true;
      if (rows.length > 400) for (const group of list) root.collapsed.add(group.key);
    }
    return list;
  }
  // By account: the linked Gameforge account, otherwise the RoM account, the characters one login screen lists
  const loginScreen = row => row.character?.romAccount || row.character?.group || null;
  const groupKeyOf = (how, accountName) => row => how === 'server' ? String(row.server || '').toLowerCase()
    : (accountName && accountName(row.name)) ? 'gf:' + accountName(row.name).toLowerCase()
      : loginScreen(row) ? 'group:' + loginScreen(row).names[0].toLowerCase() + '|' + String(row.server || '').toLowerCase() : '~none';
  const groupTitleOf = (how, accountName, romTitle) => row => how === 'server' ? row.server || 'Server unknown'
    : (accountName && accountName(row.name)) ? accountName(row.name)
      : loginScreen(row) ? `${romOf(row.character, romTitle)}, not linked` : 'No account known yet';
  function searchRows(rows, text) {
    const wanted = String(text || '').trim().toLowerCase();
    if (!wanted) return rows;
    return rows.filter(row => row.name.toLowerCase().includes(wanted) || String(row.server || '').toLowerCase().includes(wanted)
      || String(row.account || '').toLowerCase().includes(wanted) || String(row.rom || '').toLowerCase().includes(wanted) || String(row.class || '').toLowerCase().includes(wanted)
      || String(row.character?.note || '').toLowerCase().includes(wanted));
  }
  // options: {characters, how, search, isSelected, accountName, romTitle, selectKeys}
  function renderCurrencies(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'gold', descending: true};
    root.collapsed = root.collapsed || new Set();
    root.redraw = () => renderCurrencies(root, root.last.characters, root.last.options);
    root.last = {characters, options};
    const how = options.how || 'server';
    const table = currencyTable(characters, root.sorting.key, root.sorting.descending);
    const rows = searchRows(table.rows, options.search);
    const groups = tableGroups(root, rows, how, groupKeyOf(how, options.accountName), groupTitleOf(how, options.accountName, options.romTitle));
    for (const group of groups) {
      group.totals = {};
      for (const column of table.columns) group.totals[column.key] = column.shop ? null : group.rows.reduce((sum, row) => sum + (row.amounts[column.key] || 0), 0);
      group.sub = `${formatNumber(group.rows.length)} characters`;
    }
    root.selectGroup = key => options.selectKeys && options.selectKeys((groups.find(group => group.key === key)?.rows || []).map(row => row.key));
    const amount = (row, column) => {
      if (column.key !== 'gold' && row.stale && !(column.key in row.amounts)) return '<span class="hint" title="Not recorded yet: log in once on the current build">—</span>';
      return escapeHtml(formatNumber(row.amounts[column.key] || 0));
    };
    groupedTable(root, {
      columns: [{key: 'name', name: 'Character', text: true, cell: row => escapeHtml(row.name)}, {key: 'server', name: 'Server', text: true, cell: row => escapeHtml(row.server || '—')},
        ...table.columns.map(column => ({key: column.key, name: column.name, number: true, cell: row => amount(row, column)}))],
      groups, groupSpan: 2, isSelected: options.isSelected, open: !!String(options.search || '').trim(), empty: characters.length ? 'No character matches.' : 'No characters saved yet.',
      groupCells: group => group.title === null ? null : table.columns.map(column => `<td class="num">${group.totals[column.key] === null ? 'per account' : escapeHtml(formatNumber(group.totals[column.key]))}</td>`).join(''),
    });
    const total = document.createElement('tr');
    total.className = 'currency-total';
    // The totals follow the search: all characters, or only the ones that match it.
    total.innerHTML = `<td colspan="2">${rows.length === table.rows.length ? 'All' : 'Matching'} ${escapeHtml(formatNumber(rows.length))} characters</td>${table.columns.map(column => `<td class="num">${column.shop ? 'per account' : escapeHtml(formatNumber(rows.reduce((sum, row) => sum + (row.amounts[column.key] || 0), 0)))}</td>`).join('')}`;
    root.querySelector('tbody').prepend(total);
  }
  function renderRoster(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'gold', descending: true};
    root.collapsed = root.collapsed || new Set();
    root.redraw = () => renderRoster(root, root.last.characters, root.last.options);
    root.last = {characters, options};
    const how = options.how || 'server';
    const rows = searchRows(rosterRows(characters, root.sorting.key, root.sorting.descending, options.accountName, options.romTitle), options.search);
    const groups = tableGroups(root, rows, how, groupKeyOf(how, options.accountName), groupTitleOf(how, options.accountName, options.romTitle));
    for (const group of groups) {
      const gold = group.rows.reduce((sum, row) => sum + row.gold, 0);
      const caps = group.rows.filter(row => row.gold >= FULL_CAP).length;
      const stale = group.rows.filter(row => row.stale).length;
      group.sub = `${formatNumber(group.rows.length)} characters · ${formatNumber(gold)} gold` + (caps ? ` · ${formatNumber(caps)} full caps` : '') + (stale ? ` · ${formatNumber(stale)} need a login` : '');
    }
    root.selectGroup = key => options.selectKeys && options.selectKeys((groups.find(group => group.key === key)?.rows || []).map(row => row.key));
    const clock = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    const slots = (used, max, seen = true) => !seen ? '<span class="hint">not seen</span>' : escapeHtml(max ? `${formatNumber(used)} / ${formatNumber(max)}` : formatNumber(used));
    groupedTable(root, {
      columns: [
        {key: 'name', name: 'Character', text: true, cell: row => `<span class="char-name">${escapeHtml(row.name)}</span>${row.stale ? ' <span class="stale-mark" title="Needs one login on the current build">●</span>' : ''}`},
        {key: 'server', name: 'Server', text: true, cell: row => escapeHtml(row.server || '—')},
        {key: 'account', name: 'Gameforge account', text: true, cell: row => escapeHtml(row.account || '—')},
        {key: 'rom', name: 'RoM account', text: true, cell: row => escapeHtml(row.rom || '—')},
        {key: 'class', name: 'Class', text: true, cell: row => escapeHtml(row.class)},
        {key: 'level', name: 'Level', number: true, cell: row => escapeHtml(formatNumber(row.level))},
        {key: 'gold', name: 'Gold', number: true, cell: row => escapeHtml(formatNumber(row.gold))},
        {key: 'bag', name: 'Bag', number: true, cell: row => slots(row.bag, row.character?.bagSlots)},
        {key: 'bank', name: 'Bank', number: true, cell: row => slots(row.bank, row.character?.bankSlots, row.bankSeen || row.bank > 0)},
        {key: 'saved', name: 'Last saved', text: true, cell: row => escapeHtml(row.saved || '—')},
        {key: 'day', name: 'Reward day', number: true, cell: row => escapeHtml(row.day || '—')},
        {key: 'taken', name: 'Reward taken', cell: row => escapeHtml(row.taken ? clock.format(row.taken) : '—')},
      ],
      groups, isSelected: options.isSelected, open: !!String(options.search || '').trim(), empty: characters.length ? 'No character matches.' : 'No characters saved yet.',
    });
  }
  const STAT_COLUMNS = [
    {key: 'stat', name: 'Stat', text: true},
    {key: 'total', name: 'How many'},
    {key: 'characters', name: 'Characters'},
  ];
  // options: {data: {entries}} from the Bank tab, so the stats count the same characters it shows
  function renderStats(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'total', descending: true};
    root.collapsed = root.collapsed || new Set();
    if (!root.listening) {
      root.listening = true;
      for (const id of ['stat-search', 'stat-kind']) root.querySelector('#' + id).addEventListener('input', () => renderStats(root, root.characters, root.options));
    }
    root.characters = characters;
    root.options = options;
    root.redraw = () => renderStats(root, root.characters, root.options);
    const rows = statTable(options.data || characters, root.querySelector('#stat-kind').value, root.querySelector('#stat-search').value.trim(), root.sorting.key, root.sorting.descending);
    const owners = row => row.owners.slice(0, 12).map(owner => `<span class="owner" ${owner.key ? `data-char="${escapeHtml(owner.key)}"` : ''}>${escapeHtml(owner.name)} ${escapeHtml(formatNumber(owner.count))}</span>`).join(', ')
      + (row.owners.length > 12 ? ` <span class="hint">and ${formatNumber(row.owners.length - 12)} more</span>` : '');
    groupedTable(root, {
      columns: [...STAT_COLUMNS.map(column => ({...column, number: !column.text, cell: row => escapeHtml(column.text ? row.stat : formatNumber(row[column.key]))})),
        {key: 'breakdown', name: 'Who has them', text: true, cell: owners}],
      groups: [{key: '', title: null, sub: '', rows}],
      empty: 'No stats saved yet. Stats appear once a character has logged in and out on the current build.',
    });
    root.querySelector('#stat-total').textContent = `${formatNumber(rows.length)} different stats`;
  }

  // The Favourites tab: every favourite, how many there are on each server, and who has them.
  function favouriteRows(list, favourites) {
    const rows = new Map();
    for (const [key, item] of favourites) rows.set(key, {key, name: item.name || `Item ${key}`, icon: item.icon || '', total: 0, servers: new Map(), holders: new Set(), places: []});
    for (const entry of list) {
      const row = rows.get(itemKey(entry));
      if (!row) continue;
      row.total += entry.count;
      const server = entry.ch?.shownServer || '';
      row.servers.set(server, (row.servers.get(server) || 0) + entry.count);
      row.holders.add(entry.ch?.key || entry.character);
      row.places.push(entry);
    }
    return [...rows.values()].sort((a, b) => a.name.localeCompare(b.name));
  }

  // options: {roster, onlySelected(): show only the selected characters' items, favouritesRoot, openTab(name),
  // visible(): whether the Bank tab is open, tooltip: the item tooltip's element}
  function create(root, send, status, onData, menu, options = {}) {
    const roster = options.roster || null;
    const state = {characters: [], entries: [], made: null, total: -1, sort: 'name', cells: [], names: new Map(), loadedAt: 0};
    const settings = {excluded: new Set(), whitelist: new Set(), excludeBound: false};
    const rules = {on: true, types: new Set(DEFAULT_RULES.types), stats: 'apart', always: new Set(), favourites: new Map(), quality: true};
    const icons = new Map();
    const requested = new Set();
    const el = id => root.querySelector('#' + id);
    const tooltip = options.tooltip || el('bank-tooltip');
    const grid = el('bank-grid');
    const hasDom = typeof window !== 'undefined' && !!grid?.appendChild;
    const storage = typeof chrome !== 'undefined' && chrome.storage ? chrome.storage.local : null;
    let columns = 1, rows = 0, frame = 0, space = null, typingTimer = 0, shownGold = 0, gridDirty = false, gridFrame = 0, wasSelecting = false, loading = null;
    const pool = [];

    function make(tag, className, text) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    }
    const schedule = callback => (typeof requestAnimationFrame === 'function' ? requestAnimationFrame(callback) : setTimeout(callback, 16));
    function moveTooltip(event) {
      tooltip.style.left = Math.max(4, Math.min(event.clientX + 14, window.innerWidth - tooltip.offsetWidth - 8)) + 'px';
      tooltip.style.top = Math.max(4, Math.min(event.clientY + 14, window.innerHeight - tooltip.offsetHeight - 8)) + 'px';
    }
    // Shown the way the game shows it when the game's own tooltip was saved, and rebuilt from the saved details otherwise.
    function showTooltip(event, cell) {
      const lines = cell.mixed ? [] : tipLines(cell.tip);
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
        nodes.push(game, make('span', 'bank-tip-type', `${cell.type} · ${formatNumber(cell.total)} in all`));
      } else {
        const title = make('strong', '', cell.name);
        if (cell.color) title.style.color = `#${cell.color}`;
        nodes.push(title);
        for (const line of itemLines(cell)) nodes.push(make('span', `bank-tip-${line.kind}`, line.text));
      }
      const who = holders(cell.places);
      const servers = new Set(who.map(row => row.server));
      for (const row of who.slice(0, MAX_HOLDERS)) {
        const line = make('span', 'bank-tip-row');
        line.append(make('b', '', row.name));
        if (servers.size > 1 && row.server && !row.name.endsWith(`(${row.server})`)) line.append(make('i', '', ` ${row.server}`));
        line.append(` ${row.parts.join(' · ')}`);
        nodes.push(line);
      }
      if (who.length > MAX_HOLDERS) nodes.push(make('span', 'bank-tip-type', `and ${formatNumber(who.length - MAX_HOLDERS)} more characters`));
      if (/^\d+$/.test(String(cell.id || ''))) nodes.push(make('span', 'bank-tip-hint', `Item ${cell.id}${cell.bound ? ' · bound' : ''}${servers.size > 1 ? ` · on ${formatNumber(servers.size)} servers` : ''}`));
      nodes.push(make('span', 'bank-tip-hint', 'Right-click: favourite, always stack, exclude, select who holds it, or copy a login'));
      tooltip.replaceChildren(...nodes);
      tooltip.hidden = false;
      moveTooltip(event);
    }
    // Who the Bank tab shows: the region and server ticks, and the selection when that's on. The other tabs
    // only follow the region and the ticks, so clicking names there selects them without changing the view.
    function selecting() {
      return !!roster && !!options.onlySelected && options.onlySelected();
    }
    function keep(withSelection = true) {
      if (!roster) return null;
      const only = withSelection && selecting();
      return character => roster.shows(character) && (!only || roster.isSelected(character.key));
    }
    function filters() {
      return {
        text: el('bank-search').value.trim(),
        searchIn: el('bank-search-in').value,
        type: el('bank-type').value,
        place: el('bank-place').value,
        keep: keep(),
        minLevel: Number(el('bank-min-level').value) || 0,
        maxLevel: Number(el('bank-max-level').value) || 0,
        binding: el('bank-binding')?.value || '',
        minQuality: Number(el('bank-quality')?.value) || 0,
        statsOnly: !!el('bank-only-stats')?.checked,
        favourites: el('bank-only-favourites')?.checked ? rules.favourites : null,
      };
    }
    function currentRules() {
      return {on: el('bank-stack').checked !== false, types: rules.types, stats: rules.stats, always: rules.always};
    }
    // The slots on screen, and a few rows either side, drawn into a pool of slots that is reused as you scroll.
    function makeSlot() {
      const slot = make('div', 'bank-slot filled');
      slot.letters = make('span', 'bank-letters');
      slot.picture = make('img');
      slot.picture.alt = '';
      slot.count = make('span', 'bank-count');
      slot.star = make('span', 'bank-star', '★');
      slot.append(slot.letters, slot.picture, slot.count, slot.star);
      grid.append(slot);
      return slot;
    }
    function fill(slot, cell, index) {
      slot.dataset.index = String(index);
      const excluded = isHidden(cell.places[0], settings);
      const favourite = rules.favourites.has(cell.key);
      slot.className = 'bank-slot filled' + (excluded ? ' bank-excluded' : '') + (rules.quality && cell.quality ? ` q${cell.quality}` : '') + (favourite ? ' is-favourite' : '');
      slot.letters.textContent = cell.name.slice(0, 2);
      if (slot.icon !== cell.icon) {
        slot.icon = cell.icon;
        if (icons.has(cell.icon)) slot.picture.src = icons.get(cell.icon);
        else slot.picture.removeAttribute('src');
      }
      slot.count.textContent = cell.total > 1 ? (cell.total > 9999 ? `${Math.floor(cell.total / 1000)}k` : String(cell.total)) : cell.gear?.plus > 0 ? `+${cell.gear.plus}` : '';
      slot.hidden = false;
    }
    function layout() {
      if (!hasDom) return;
      if (!space) {
        space = make('div', 'bank-grid-space');
        grid.append(space);
      }
      const width = Math.max(SLOT, grid.clientWidth - PAD * 2);
      columns = Math.max(1, Math.floor((width + GAP) / (SLOT + GAP)));
      rows = Math.ceil(state.cells.length / columns);
      space.style.height = (rows ? rows * (SLOT + GAP) - GAP + PAD * 2 : 0) + 'px';
    }
    function paint() {
      frame = 0;
      if (!hasDom) return;
      const step = SLOT + GAP;
      const top = grid.scrollTop, height = grid.clientHeight || 600;
      const first = Math.max(0, Math.floor((top - PAD) / step) - 2);
      const last = Math.min(rows - 1, Math.ceil((top + height - PAD) / step) + 2);
      const from = first * columns, to = Math.min(state.cells.length, (last + 1) * columns);
      const wanted = [];
      let used = 0;
      for (let index = from; index < to; index++) {
        const cell = state.cells[index];
        const slot = pool[used] || (pool[used] = makeSlot());
        fill(slot, cell, index);
        slot.style.transform = `translate(${PAD + (index % columns) * step}px, ${PAD + Math.floor(index / columns) * step}px)`;
        if (cell.icon && !icons.has(cell.icon) && !requested.has(cell.icon)) {
          requested.add(cell.icon);
          wanted.push(cell.icon);
        }
        used++;
      }
      for (let i = used; i < pool.length; i++) pool[i].hidden = true;
      if (wanted.length && typeof GBIcons !== 'undefined') {
        GBIcons.load(wanted, send, (name, url) => {
          icons.set(name, url);
          for (const slot of pool) if (slot.icon === name) slot.picture.src = url;
        }).catch(error => { status(`Icons couldn't be read: ${error.message || error}`); });
      }
    }
    const repaint = () => { if (!frame) frame = schedule(paint); };
    // A filter change starts at the top; a new selection or new data keeps your place.
    function renderGrid(fromTop) {
      if (options.visible && !options.visible()) {
        gridDirty = true;
        return;
      }
      gridDirty = false;
      if (tooltip) tooltip.hidden = true;
      const showHidden = el('bank-show-excluded').checked;
      const test = matcher(filters());
      const list = [];
      for (const entry of state.entries) if (test(entry) && (showHidden || !isHidden(entry, settings))) list.push(entry);
      state.cells = cells(list, currentRules()).sort(SORTS[state.sort] || SORTS.name);
      if (hasDom) {
        layout();
        grid.scrollTop = fromTop ? 0 : Math.min(grid.scrollTop, Math.max(0, grid.scrollHeight - grid.clientHeight));
        paint();
        let empty = grid.querySelector('.bank-empty');
        if (!state.cells.length) {
          if (!empty) { empty = make('p', 'bank-empty'); grid.append(empty); }
          empty.textContent = state.characters.length ? 'Nothing matches these filters.' : 'No characters saved yet.';
        } else if (empty) empty.remove();
      }
      const shown = keepCharacters();
      shownGold = shown.reduce((sum, character) => sum + character.gold, 0);
      const unseen = shown.filter(character => !character.bankSeen).length;
      const stale = shown.filter(character => character.stale).length;
      el('bank-total').textContent = `${formatNumber(state.cells.length)} shown · ${formatNumber(shown.length)} characters${selecting() ? ' (your selection)' : ''} · ${formatNumber(shownGold)} gold`
        + (unseen === 1 ? ' · 1 bank not seen yet: open the bank once on that character' : unseen ? ` · ${formatNumber(unseen)} banks not seen yet: open the bank once on them` : '')
        + (stale === 1 ? ' · 1 character needs a login on the current version for stats' : stale ? ` · ${formatNumber(stale)} need a login on the current version for stats` : '');
    }
    // Many clicks in a row draw once
    function scheduleGrid() {
      if (gridFrame) return;
      gridFrame = schedule(() => { gridFrame = 0; renderGrid(); });
    }
    function keepCharacters() {
      const test = keep();
      return test ? state.characters.filter(test) : state.characters;
    }
    // Typing waits for a pause; every other change shows at once.
    function typed() {
      clearTimeout(typingTimer);
      typingTimer = setTimeout(() => renderGrid(true), state.entries.length > 20000 ? 250 : 120);
    }
    // Kept in this browser only: it changes what this page shows, not what the game or the helper saves.
    function settingsChanged() {
      if (storage) {
        storage.set({bankExclusions: {excluded: [...settings.excluded], whitelist: [...settings.whitelist], excludeBound: settings.excludeBound},
          bankRules: {types: [...rules.types], stats: rules.stats, always: [...rules.always], quality: rules.quality,
            favourites: [...rules.favourites].map(([key, item]) => ({key, name: item.name, icon: item.icon}))}}).catch(() => {});
      }
      renderExclusions();
      renderStacking();
      renderGrid();
      renderFavourites();
    }
    function itemName(key) {
      return state.names.get(key) || rules.favourites.get(key)?.name || (key.startsWith('n:') ? key.slice(2) : `Item ${key}`);
    }
    function renderList(id, keys, remove) {
      const list = el(id);
      if (!list?.replaceChildren) return;
      list.replaceChildren(...[...keys].map(key => {
        const row = make('li', '', itemName(key) + ' ');
        const button = make('button', '', 'Remove');
        button.type = 'button';
        button.addEventListener('click', () => { remove(key); settingsChanged(); });
        row.append(button);
        return row;
      }));
    }
    function renderExclusions() {
      el('bank-exclusions-summary').textContent = `Excluded items (${settings.excluded.size} excluded, ${settings.whitelist.size} always kept)`;
      el('bank-exclude-bound').checked = settings.excludeBound;
      renderList('bank-excluded-list', settings.excluded, key => settings.excluded.delete(key));
      renderList('bank-whitelist', settings.whitelist, key => settings.whitelist.delete(key));
    }
    function renderStacking() {
      const summary = el('bank-stacking-summary');
      if (summary) summary.textContent = el('bank-stack').checked === false ? 'Stacking: off' : `Stacking: ${rules.types.size} of ${TYPES.length} types` + (rules.always.size ? `, ${rules.always.size} always` : '');
      root.querySelectorAll?.('[data-stack-type]')?.forEach(box => { box.checked = rules.types.has(box.dataset.stackType); });
      if (el('bank-stack-stats')) el('bank-stack-stats').value = rules.stats;
      if (el('bank-quality-borders')) el('bank-quality-borders').checked = rules.quality;
      renderList('bank-always-list', rules.always, key => rules.always.delete(key));
    }
    // An exact name or an ID, from what your characters hold; an ID also works for something nobody holds yet.
    function keyForText(text) {
      if (/^\d+$/.test(text)) return text;
      const lower = text.toLowerCase();
      for (const [key, name] of state.names) if (name.toLowerCase() === lower) return key;
      return null;
    }
    function addFromBox(into, other) {
      const box = el('bank-exclusion-item');
      const key = keyForText(box.value.trim());
      el('bank-exclusion-note').textContent = key ? '' : 'None of your characters has an item with exactly that name. Try its ID.';
      if (!key) return;
      other.delete(key);
      into.add(key);
      box.value = '';
      settingsChanged();
    }
    function itemMenu(event, cell) {
      if (tooltip) tooltip.hidden = true;
      const hidden = isHidden(cell.places[0], settings);
      const favourite = rules.favourites.has(cell.key);
      const always = rules.always.has(cell.key);
      menu(event, [
        {label: favourite ? 'Remove from favourites' : 'Add to favourites', run() {
          if (favourite) rules.favourites.delete(cell.key);
          else rules.favourites.set(cell.key, {name: cell.name, icon: cell.icon || ''});
          settingsChanged();
        }},
        {label: always ? 'Stop always stacking this item' : 'Always stack every copy of this item', run() {
          if (always) rules.always.delete(cell.key);
          else rules.always.add(cell.key);
          settingsChanged();
        }},
        {label: hidden ? 'Bring this item back' : 'Exclude this item', run() {
          toggleHidden(cell.places[0], settings);
          settingsChanged();
        }},
        {label: 'Show only this item', run() {
          el('bank-search').value = cell.name;
          el('bank-search-in').value = '';
          if (options.openTab) options.openTab('bank');
          renderGrid(true);
        }},
        ...(roster ? [{label: `Select the ${formatNumber(new Set(cell.places.map(place => place.ch?.key || place.character)).size)} characters who hold it`, run() {
          roster.setSelection([...roster.selection, ...cell.places.map(place => place.ch?.key).filter(Boolean)]);
        }}] : []),
      ], cell.places.map(place => place.character));
    }

    // The Favourites tab: favourites in a row of slots like the bank's, then a table of where they are.
    function renderFavourites() {
      const area = options.favouritesRoot;
      if (!area?.querySelector || area.hidden) return;
      const test = matcher({keep: keep(false)});
      const list = state.entries.filter(entry => rules.favourites.has(itemKey(entry)) && test(entry));
      const favouriteList = favouriteRows(list, rules.favourites);
      const servers = [...new Set(list.map(entry => entry.ch?.shownServer || ''))].sort((a, b) => Number(!a) - Number(!b) || a.localeCompare(b));
      const gridArea = area.querySelector('#favourite-grid');
      gridArea.replaceChildren(...favouriteList.map((row, index) => {
        const slot = make('div', 'bank-slot filled is-favourite');
        slot.dataset.favourite = String(index);
        slot.append(make('span', 'bank-letters', row.name.slice(0, 2)));
        const picture = make('img');
        picture.alt = '';
        if (icons.has(row.icon)) picture.src = icons.get(row.icon);
        slot.append(picture);
        if (row.total !== 1) slot.append(make('span', 'bank-count', row.total > 9999 ? `${Math.floor(row.total / 1000)}k` : String(row.total)));
        if (!row.total) slot.classList.add('bank-excluded');
        return slot;
      }));
      if (!favouriteList.length) gridArea.append(make('p', 'bank-empty', 'No favourites yet. Right-click an item on the Bank tab and choose Add to favourites.'));
      gridArea.cells = favouriteList.map(row => ({key: row.key, id: row.key, name: row.name, icon: row.icon, type: row.places[0]?.type || typeOf(row.key, row.icon),
        gear: null, stats: [], tip: row.places[0]?.tip || null, color: row.places[0]?.color || '', quality: row.places[0]?.quality || 0, bound: false, total: row.total, places: row.places, mixed: false}));
      const missing = favouriteList.filter(row => row.icon && !icons.has(row.icon)).map(row => row.icon);
      if (missing.length && typeof GBIcons !== 'undefined') {
        GBIcons.load(missing, send, (name, url) => {
          icons.set(name, url);
          gridArea.querySelectorAll('[data-favourite]').forEach(slot => { if (favouriteList[Number(slot.dataset.favourite)]?.icon === name) slot.querySelector('img').src = url; });
        }).catch(() => {});
      }
      const table = area.querySelector('table');
      table.querySelector('thead').innerHTML = `<tr><th>Item</th><th class="num">In all</th>${servers.map(server => `<th class="num">${escapeHtml(server || 'Server unknown')}</th>`).join('')}<th>Most held by</th></tr>`;
      table.querySelector('tbody').innerHTML = favouriteList.map(row => {
        const top = holders(row.places).slice(0, 5).map(holder => `<span class="owner"${holder.key ? ` data-char="${escapeHtml(holder.key)}"` : ''}>${escapeHtml(holder.name)} ${escapeHtml(formatNumber(holder.count))}</span>`).join(', ');
        return `<tr><td>${escapeHtml(row.name)}</td><td class="num">${escapeHtml(formatNumber(row.total))}</td>${servers.map(server => `<td class="num">${escapeHtml(formatNumber(row.servers.get(server) || 0))}</td>`).join('')}<td>${top || '<span class="hint">nobody shown holds one</span>'}</td></tr>`;
      }).join('');
    }

    // The Bank tab's own list of characters: it picks the page's selection, grouped by server, with a search for thousands.
    function renderPicker() {
      const list = el('bank-character-list');
      const details = el('bank-characters-menu');
      if (!list?.replaceChildren || !roster) return;
      if (details && !details.open) return;
      const wanted = (el('bank-character-find')?.value || '').trim().toLowerCase();
      const shown = state.characters.filter(character => roster.shows(character) && (!wanted || character.name.toLowerCase().includes(wanted)));
      const groups = new Map();
      for (const character of shown) {
        const server = character.shownServer || 'Server unknown';
        if (!groups.has(server)) groups.set(server, []);
        groups.get(server).push(character);
      }
      const parts = [];
      for (const [server, members] of [...groups.entries()].sort((a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0]))) {
        parts.push(`<div class="picker-server">${escapeHtml(server)} <span class="hint">${formatNumber(members.length)}</span></div>`);
        // The selected ones first, so they're easy to find and untick
        for (const character of members.slice().sort((a, b) => Number(roster.isSelected(b.key)) - Number(roster.isSelected(a.key)) || a.name.localeCompare(b.name)).slice(0, 2000)) {
          parts.push(`<div class="bank-character${roster.isSelected(character.key) ? ' is-selected' : ''}" data-char="${escapeHtml(character.key)}"><span class="tick" aria-hidden="true"></span><span class="bank-name">${escapeHtml(character.name)}</span><span class="bank-detail">${escapeHtml(`${character.class || 'Level'} ${character.level || '?'} · ${formatNumber(character.gold)} gold`)}</span></div>`);
        }
      }
      if (!parts.length) parts.push('<p class="hint">No character matches.</p>');
      list.innerHTML = parts.join('');
    }
    function renderSummary() {
      const summary = el('bank-character-summary');
      if (!summary || !roster) return;
      const shown = state.characters.filter(character => roster.shows(character)).length;
      const selected = roster.selected().length;
      summary.textContent = selected ? `${formatNumber(selected)} selected of ${formatNumber(shown)} characters` : `All characters (${formatNumber(shown)})`;
    }

    // A big file comes in parts, and the local host says how long the whole of it is. When it starts with the same
    // stamp and has the same length as last time, nothing changed and the rest isn't fetched. When its length
    // changes on the way, the helper rewrote it, and it's read again from the start.
    async function fetchData(ifChanged) {
      for (let attempt = 0; ; attempt++) {
        let json = '', total = 0, again = false;
        for (;;) {
          const response = await send({type: 'bank-data', offset: json.length});
          const part = response.json || '';
          if (json && response.total && total && response.total !== total) { again = true; break; }
          total = response.total || total;
          json += part;
          if (ifChanged && json.length === part.length && total && total === state.total) {
            const made = /^\s*\{"made":"([^"]*)"/.exec(json)?.[1];
            if (made && made === state.made) return null;
          }
          if (!part || !total || json.length >= total) break;
        }
        if (!again) {
          try {
            return {data: json ? JSON.parse(json) : {characters: []}, total: total || json.length};
          } catch (error) {
            if (attempt >= 2) throw new Error(`The saved data couldn't be read (${error.message}). Press Update now.`);
          }
        } else if (attempt >= 2) throw new Error('The helper kept rewriting the data while it was read. Try again in a moment.');
      }
    }
    // One load at a time: asking again while one runs waits for it, then loads once more if something asked.
    async function reload(how = {}) {
      if (loading) {
        loading.again = loading.again || {ifChanged: !!how.ifChanged};
        if (!how.ifChanged) loading.again.ifChanged = false;
        return loading.promise;
      }
      const run = {again: null};
      loading = run;
      run.promise = (async () => {
        try {
          return await load(how);
        } finally {
          loading = null;
          if (run.again) reload(run.again).catch(error => status(String(error.message || error)));
        }
      })();
      return run.promise;
    }
    async function load(how) {
      const fetched = await fetchData(!!how.ifChanged);
      if (!fetched) return false;
      const {data} = fetched;
      state.total = fetched.total;
      apply(Array.isArray(data.characters) ? data.characters : [], data.made || null);
      return true;
    }
    // Who is who, then everything drawn from it. Also run again on the same characters when a server set by hand
    // changes where some of them are.
    function apply(list, made) {
      if (typeof GBRoster !== 'undefined') GBRoster.prepare(list, typeof GBAccounts !== 'undefined' ? GBAccounts.accountGroups : null, roster?.assigned ? roster.assigned() : null);
      else tellApart(list);
      state.characters = list;
      state.made = made;
      state.loadedAt = Date.now();
      state.entries = entries(list);
      state.names = new Map();
      for (const entry of state.entries) if (!state.names.has(itemKey(entry))) state.names.set(itemKey(entry), entry.name);
      el('bank-made').textContent = made ? `Data from ${made}` : 'No saved data yet: press Update now after logging out of a character.';
      if (roster) roster.setCharacters(list);
      renderGrid();
      renderExclusions();
      renderStacking();
      renderSummary();
      renderPicker();
      renderFavourites();
      if (onData) onData(totals(state.characters), made, state.characters);
    }
    async function update() {
      const button = el('bank-update');
      button.disabled = true;
      status('Reading your save files…');
      try {
        const response = await send({type: 'bank-command', command: 'update'});
        await reload();
        status((response.output || '').trim().split('\n').pop() || 'Updated.');
      } catch (error) {
        status(`Could not update: ${error.message || error}`);
      } finally {
        button.disabled = false;
      }
    }

    el('bank-search').addEventListener('input', typed);
    for (const id of ['bank-min-level', 'bank-max-level']) el(id).addEventListener('input', typed);
    for (const id of ['bank-type', 'bank-place', 'bank-search-in', 'bank-binding', 'bank-quality', 'bank-only-stats', 'bank-only-favourites', 'bank-show-excluded']) {
      el(id)?.addEventListener('change', () => renderGrid(true));
    }
    el('bank-stack').addEventListener('change', () => { renderStacking(); renderGrid(); });
    el('bank-sort').addEventListener('change', event => { state.sort = event.target.value; renderGrid(true); });
    el('bank-update').addEventListener('click', update);
    el('bank-exclude-bound').addEventListener('change', event => { settings.excludeBound = event.target.checked; settingsChanged(); });
    el('bank-exclusion-add').addEventListener('click', () => addFromBox(settings.excluded, settings.whitelist));
    el('bank-whitelist-add').addEventListener('click', () => addFromBox(settings.whitelist, settings.excluded));
    el('bank-stack-stats')?.addEventListener('change', event => { rules.stats = event.target.value; settingsChanged(); });
    el('bank-quality-borders')?.addEventListener('change', event => { rules.quality = event.target.checked; settingsChanged(); });
    root.querySelectorAll?.('[data-stack-type]')?.forEach(box => box.addEventListener('change', () => {
      if (box.checked) rules.types.add(box.dataset.stackType);
      else rules.types.delete(box.dataset.stackType);
      settingsChanged();
    }));
    el('bank-select-clear')?.addEventListener('click', () => roster?.clearSelection());
    el('bank-select-shown')?.addEventListener('click', () => {
      const wanted = (el('bank-character-find')?.value || '').trim().toLowerCase();
      roster?.setSelection([...roster.selection, ...state.characters.filter(character => roster.shows(character) && (!wanted || character.name.toLowerCase().includes(wanted))).map(character => character.key)]);
    });
    el('bank-character-find')?.addEventListener('input', renderPicker);
    el('bank-characters-menu')?.addEventListener('toggle', renderPicker);
    if (hasDom) {
      grid.addEventListener('scroll', repaint, {passive: true});
      if (typeof ResizeObserver !== 'undefined') new ResizeObserver(() => { layout(); repaint(); }).observe(grid);
      const cellAt = target => {
        const slot = target?.closest?.('.bank-slot');
        return slot && slot.dataset.index !== undefined ? state.cells[Number(slot.dataset.index)] : null;
      };
      let hovered = null;
      grid.addEventListener('mouseover', event => {
        const cell = cellAt(event.target);
        if (cell === hovered) return;
        hovered = cell;
        if (cell) showTooltip(event, cell);
        else tooltip.hidden = true;
      });
      grid.addEventListener('mousemove', event => { if (hovered && !tooltip.hidden) moveTooltip(event); }, {passive: true});
      grid.addEventListener('mouseleave', () => { hovered = null; tooltip.hidden = true; });
      grid.addEventListener('scroll', () => { hovered = null; tooltip.hidden = true; }, {passive: true});
      grid.addEventListener('contextmenu', event => {
        const cell = cellAt(event.target);
        if (cell) itemMenu(event, cell);
      });
      const favouriteGrid = options.favouritesRoot?.querySelector('#favourite-grid');
      if (favouriteGrid) {
        const favouriteAt = target => {
          const slot = target?.closest?.('[data-favourite]');
          return slot ? favouriteGrid.cells?.[Number(slot.dataset.favourite)] : null;
        };
        favouriteGrid.addEventListener('mouseover', event => {
          const cell = favouriteAt(event.target);
          if (cell) showTooltip(event, cell);
          else tooltip.hidden = true;
        });
        favouriteGrid.addEventListener('mousemove', event => { if (!tooltip.hidden) moveTooltip(event); }, {passive: true});
        favouriteGrid.addEventListener('mouseleave', () => { tooltip.hidden = true; });
        favouriteGrid.addEventListener('contextmenu', event => {
          const cell = favouriteAt(event.target);
          if (cell) itemMenu(event, cell);
        });
        favouriteGrid.addEventListener('click', event => {
          const cell = favouriteAt(event.target);
          if (!cell) return;
          tooltip.hidden = true;
          el('bank-search').value = cell.name;
          el('bank-search-in').value = '';
          if (options.openTab) options.openTab('bank');
          renderGrid(true);
        });
      }
    }
    if (roster) {
      roster.onChange(what => {
        // Names, the hover card's checkmarks and the order on the Gameforge accounts tab don't change this tab
        if (what !== 'selection' && what !== 'view') return;
        renderSummary();
        if (what === 'selection') {
          const list = el('bank-character-list');
          list?.querySelectorAll?.('[data-char]')?.forEach(row => row.classList.toggle('is-selected', roster.isSelected(row.dataset.char)));
          // The grid only follows the selection while that's on, and once more when it stops
          const now = selecting();
          if (now || wasSelecting) scheduleGrid();
          wasSelecting = now;
          return;
        }
        renderPicker();
        scheduleGrid();
        renderFavourites();
      });
    }
    if (storage) {
      storage.get(['bankExclusions', 'bankRules']).then(({bankExclusions: saved, bankRules: kept}) => {
        if (saved) {
          settings.excluded = new Set(saved.excluded || []);
          settings.whitelist = new Set(saved.whitelist || []);
          settings.excludeBound = !!saved.excludeBound;
        }
        if (kept) {
          if (Array.isArray(kept.types)) rules.types = new Set(kept.types.filter(type => TYPES.includes(type)));
          if (['apart', 'match', 'all'].includes(kept.stats)) rules.stats = kept.stats;
          rules.always = new Set(Array.isArray(kept.always) ? kept.always : []);
          rules.quality = kept.quality !== false;
          rules.favourites = new Map((Array.isArray(kept.favourites) ? kept.favourites : []).filter(item => item?.key).map(item => [String(item.key), {name: String(item.name || ''), icon: String(item.icon || '')}]));
        }
        renderExclusions();
        renderStacking();
        renderGrid();
        renderFavourites();
      }).catch(() => {});
    }
    return {
      reload, update, renderGrid, renderFavourites,
      // The same characters prepared again: a server set by hand moves them
      reprepare() { if (state.characters.length) apply(state.characters, state.made); },
      // The Bank tab was opened: draw what changed while it was hidden
      show() { if (gridDirty) renderGrid(); else if (hasDom) { layout(); repaint(); } },
      entries: () => state.entries,
      characters: () => state.characters,
      shownEntries() {
        const test = matcher({keep: keep(false)});
        return state.entries.filter(test);
      },
      loadedAt: () => state.loadedAt,
    };
  }
  return {create, tellApart, typeOf, qualityOf, QUALITY, TYPES, locationLabel, entries, applyFilters, matcher, cells, stackKey, statsSignature, DEFAULT_RULES,
    formatDuration, totals, isHidden, toggleHidden, stackable, gearLines, tipLines, itemLines, holders, currencyTable, currencyName, renderCurrencies,
    rosterRows, renderRoster, statTable, renderStats, favouriteRows, groupedTable, escapeHtml, formatNumber};
})();
