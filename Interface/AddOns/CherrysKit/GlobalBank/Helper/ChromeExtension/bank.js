'use strict';
// The Bank page: everything every character holds, in one scrolling grid like the game's own bank, with a search,
// filters, stacking rules, favourites, the game's own tooltips and a panel saying who holds an item and where. The
// Favourites, Currencies, Stats and Characters pages read the same data. Only the rows and slots on screen are
// drawn, so thousands of characters stay quick.
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
  // The grid's layouts. Slots sit at fixed places, so these and control.css's sizes have to agree.
  const LAYOUTS = {grid: {slot: 56, gap: 6}, compact: {slot: 44, gap: 3}, list: {slot: 42, gap: 0, rows: true}};
  const PAD = 10;
  const FULL_CAP = 999999999;
  // Server Transfer Stones, by ID in any language, and by name for any other item the game calls that.
  const TRANSFER_STONE = '244657';
  const NO_SERVER = 'Unknown server';

  function formatNumber(value) {
    return Number(value || 0).toLocaleString('en-US');
  }
  // 3.73B, 528.77M, 1.38M, rounded down so a full cap never reads as a billion. Exact numbers stay in tooltips and tables.
  function formatCompact(value) {
    const amount = Math.max(0, Number(value) || 0);
    if (amount >= 1e9) return `${(Math.floor(amount / 1e7) / 100).toFixed(2)}B`;
    if (amount >= 1e6) return `${(Math.floor(amount / 1e4) / 100).toFixed(2)}M`;
    if (amount >= 1e4) return `${(Math.floor(amount / 100) / 10).toFixed(1)}K`;
    return formatNumber(amount);
  }
  const escapeHtml = text => String(text ?? '').replace(/[&<>"']/g, letter => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[letter]));
  // A bank read once in game is known; before that its items are simply missing, which isn't the same as none.
  const bankKnown = character => !!character.bankSeen || (character.bank || []).length > 0;
  function transferStones(character) {
    let count = 0;
    for (const place of ['bag', 'bank']) {
      for (const item of character[place] || []) {
        if (String(item.id) === TRANSFER_STONE || /^server transfer stone/i.test(String(item.name || ''))) count += Number(item.count) || 1;
      }
    }
    return count;
  }
  // The line for a character's hover card, or '' when it would only say there are none
  function transferStonesText(character) {
    const count = transferStones(character);
    if (!count) return '';
    return bankKnown(character) ? `Transfer stones: ${formatNumber(count)}` : `Transfer stones: at least ${formatNumber(count)}, bank not recorded`;
  }
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
    {key: 'stones', name: 'Transfer stones'},
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
    {key: 'stale', name: 'Status'},
  ];
  // The RoM account to show: the name you gave it, or the first name on its login screen's list
  const romOf = (character, romTitle) => (romTitle ? romTitle(character) : '')
    || (character.romAccount?.steam ? 'Steam account' : '')
    || ((character.romAccount || character.group) ? `${(character.romAccount || character.group).names[0]}'s account` : '');
  function rosterRows(characters, sort, descending, accountName, romTitle) {
    const rows = characters.map(character => {
      const taken = Date.parse(character.dailyLogin?.collectedAt || '');
      const bag = (character.bag || []).length, bank = (character.bank || []).length;
      const linked = accountName ? accountName(character.name) : '';
      return {name: String(character.name || ''), key: character.key, character, server: String(character.shownServer ?? character.server ?? ''),
        account: linked, rom: romOf(character, romTitle), stones: transferStones(character),
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
    const sortButton = (key, name, text, minor) => {
      const mark = sorting.key === key ? (sorting.descending ? ' ▼' : ' ▲') : '';
      return `<button type="button" class="${minor ? 'sort-minor' : ''}${minor && mark ? ' is-sorted' : ''}" data-sort="${escapeHtml(key)}" data-text="${text ? 1 : ''}">${escapeHtml(name + mark)}</button>`;
    };
    const cellClass = column => [column.number ? 'num' : '', column.className || ''].filter(Boolean).join(' ');
    // Two values in one column each keep their own way of sorting: column.also lists the second one's
    const head = spec.columns.map(column => {
      const sorted = sorting.key === column.key ? ` aria-sort="${sorting.descending ? 'descending' : 'ascending'}"` : '';
      const inside = column.noSort ? column.head || '' : sortButton(column.key, column.name, column.text) + (column.also || []).map(other => sortButton(other.key, other.name, other.text, true)).join('');
      return `<th class="${cellClass(column)}"${sorted}>${inside}</th>`;
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
        parts.push(`<tr data-char="${escapeHtml(row.key || '')}" class="char-row${selected}${row.stale ? ' is-stale' : ''}">${spec.columns.map(column => `<td class="${cellClass(column)}">${column.cell(row)}</td>`).join('')}</tr>`);
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
        const open = event.target.closest('[data-open-char]');
        if (open && root.openCharacter) root.openCharacter(open.dataset.openChar);
        if (event.target.closest('.select-all') && root.selectAll) root.selectAll();
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
  const groupTitleOf = (how, accountName, romTitle) => row => how === 'server' ? row.server || NO_SERVER
    : (accountName && accountName(row.name)) ? accountName(row.name)
      : loginScreen(row) ? (loginScreen(row).steam ? romOf(row.character, romTitle) : `${romOf(row.character, romTitle)}, not linked`) : 'No account known yet';
  function searchRows(rows, text) {
    const wanted = String(text || '').trim().toLowerCase();
    if (!wanted) return rows;
    return rows.filter(row => row.name.toLowerCase().includes(wanted) || String(row.server || '').toLowerCase().includes(wanted)
      || String(row.account || '').toLowerCase().includes(wanted) || String(row.rom || '').toLowerCase().includes(wanted) || String(row.class || '').toLowerCase().includes(wanted)
      || String(row.character?.note || '').toLowerCase().includes(wanted));
  }
  // Diamonds, Bonus and Billdin belong to an account, and every character on it saved the same balance, so each
  // account counts once, as of the newest save on it. A character no login screen has listed could be on any account:
  // it isn't counted, and says so. A character saved before currencies were recorded says nothing either way.
  function accountCurrencies(characters) {
    const newest = new Map();
    let loose = 0;
    for (const character of characters) {
      if (character.stale || character.notSaved) continue;
      const account = character.romAccount || character.group || null;
      if (!account) { loose++; continue; }
      const held = newest.get(account);
      if (!held || String(character.saved || '') > String(held.saved || '')) newest.set(account, character);
    }
    return Object.entries(SHOP_NAMES).map(([key, name]) => {
      let total = 0;
      for (const character of newest.values()) total += Number((character.currencies || []).find(money => money.key === key)?.amount) || 0;
      return {key, name, total, accounts: newest.size, loose, recorded: newest.size > 0};
    });
  }
  // The cards above the table: the gold on the characters in view, and the account currencies
  function renderCurrencySummary(node, characters) {
    if (!node) return;
    const gold = characters.reduce((sum, character) => sum + (Number(character.gold) || 0), 0);
    const caps = characters.filter(character => Number(character.gold) >= FULL_CAP).length;
    const card = (label, icon, value, unknown, help, primary) => `<div class="currency-card${primary ? ' is-primary' : ''}"><div class="currency-label"><span class="ico" data-card-icon="${icon}"></span>${escapeHtml(label)}</div>`
      + `<div class="currency-value${unknown ? ' is-unknown' : ''}">${escapeHtml(value)}</div><div class="currency-help">${escapeHtml(help)}</div></div>`;
    const parts = [card('Total character gold', 'coin', formatNumber(gold), false,
      `${formatNumber(characters.length)} characters in view · ${formatNumber(caps)} at the ${formatNumber(FULL_CAP)} cap`, true)];
    const shop = accountCurrencies(characters);
    for (const money of shop) {
      parts.push(card(money.name, money.key === 'account' ? 'diamond' : 'wallet', money.recorded ? formatNumber(money.total) : 'Not recorded', !money.recorded,
        money.recorded ? `${formatNumber(money.accounts)} RoM accounts, as last saved` : 'No character on a known RoM account has saved this yet'));
    }
    const loose = shop[0]?.loose || 0;
    parts.push(`<p class="currency-note">Diamonds, Bonus and Billdin belong to an account, so each RoM account counts once.${loose ? ` ${formatNumber(loose)} characters aren't on a known RoM account yet, so theirs aren't counted.` : ''}</p>`);
    node.innerHTML = parts.join('');
    for (const icon of node.querySelectorAll('[data-card-icon]')) icon.innerHTML = window.GB_ICONS?.[icon.dataset.cardIcon] || '';
  }
  // options: {characters, how, search, isSelected, accountName, romTitle, selectKeys, summary: the cards' element}
  function renderCurrencies(root, characters, options = {}) {
    renderCurrencySummary(options.summary, characters);
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
      if (column.key !== 'gold' && row.stale && !(column.key in row.amounts)) return '<span class="not-recorded" title="Not recorded: log in once on the current version">—</span>';
      if (column.key === 'gold') return `<span class="gold-cell">${escapeHtml(formatNumber(row.amounts.gold))}</span>`;
      return escapeHtml(formatNumber(row.amounts[column.key] || 0));
    };
    groupedTable(root, {
      columns: [{key: 'name', name: 'Character', text: true, cell: row => `<span class="char-name">${escapeHtml(row.name)}</span>`}, {key: 'server', name: 'Server', text: true, cell: serverCell},
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
  const serverCell = row => (row.server ? `<span class="server-pill">${escapeHtml(row.server)}</span>` : `<span class="server-pill is-unknown">${escapeHtml(NO_SERVER)}</span>`);
  // The letter on a coloured square: the class at a glance, and its colour where the page knows it
  const classBadge = (name, color) => `<span class="class-avatar"${color ? ` style="--class-color:${escapeHtml(color)}"` : ''} aria-hidden="true">${escapeHtml(String(name || '?').slice(0, 1).toUpperCase())}</span>`;
  // How many a character can transfer: "at least" what's in the bag while its bank isn't recorded, never a false 0
  function stonesCell(row) {
    const known = row.bankSeen || row.bank > 0;
    if (known) return `<span class="stone-count${row.stones ? '' : ' is-none'}">${escapeHtml(formatNumber(row.stones))}</span>`;
    return row.stones ? `<span class="stone-count is-atleast" title="At least this many: the bank isn't recorded">${escapeHtml(formatNumber(row.stones))}+</span>`
      : '<span class="not-recorded" title="None in the bag, and the bank isn\'t recorded">—</span>';
  }
  function renderRoster(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'gold', descending: true};
    root.collapsed = root.collapsed || new Set();
    root.redraw = () => renderRoster(root, root.last.characters, root.last.options);
    root.last = {characters, options};
    root.openCharacter = options.openCharacter;
    const how = options.how || 'server';
    const rows = searchRows(rosterRows(characters, root.sorting.key, root.sorting.descending, options.accountName, options.romTitle), options.search);
    const groups = tableGroups(root, rows, how, groupKeyOf(how, options.accountName), groupTitleOf(how, options.accountName, options.romTitle));
    for (const group of groups) {
      const gold = group.rows.reduce((sum, row) => sum + row.gold, 0);
      const caps = group.rows.filter(row => row.gold >= FULL_CAP).length;
      const stale = group.rows.filter(row => row.stale).length;
      const stones = group.rows.reduce((sum, row) => sum + row.stones, 0);
      group.sub = `${formatNumber(group.rows.length)} characters · ${formatNumber(gold)} gold` + (caps ? ` · ${formatNumber(caps)} full caps` : '')
        + (stones ? ` · ${formatNumber(stones)} transfer stones` : '') + (stale ? ` · ${formatNumber(stale)} need a login` : '');
    }
    root.selectGroup = key => options.selectKeys && options.selectKeys((groups.find(group => group.key === key)?.rows || []).map(row => row.key));
    root.selectAll = () => options.selectKeys && options.selectKeys(rows.map(row => row.key));
    const clock = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    const slots = (label, used, max) => `${escapeHtml(max ? `${formatNumber(used)} / ${formatNumber(max)}` : formatNumber(used))} ${label}`;
    const allSelected = rows.length > 0 && !!options.isSelected && rows.every(row => options.isSelected(row.key));
    groupedTable(root, {
      columns: [
        {key: 'select', noSort: true, className: 'check-col', head: `<input type="checkbox" class="select-all" aria-label="Select all shown"${allSelected ? ' checked' : ''}>`,
          cell: row => `<input type="checkbox" class="char-check" aria-label="Select ${escapeHtml(row.name)}"${options.isSelected && options.isSelected(row.key) ? ' checked' : ''}>`},
        {key: 'name', name: 'Character', text: true, also: [{key: 'class', name: 'Class', text: true}, {key: 'level', name: 'Level'}],
          cell: row => `<span class="char-cell">${classBadge(row.class, options.classColor && options.classColor(row.character))}<span><span class="char-name">${escapeHtml(row.name)}</span><span class="sub">${escapeHtml([row.class, row.level ? `Lv. ${formatNumber(row.level)}` : ''].filter(Boolean).join(' · ') || 'Class not recorded')}</span></span></span>`},
        {key: 'server', name: 'Server', text: true, cell: serverCell},
        {key: 'stones', name: 'Transfer stones', number: true, cell: stonesCell},
        {key: 'account', name: 'Gameforge', text: true, also: [{key: 'rom', name: 'RoM', text: true}],
          cell: row => `<span class="stacked">${escapeHtml(row.account || (options.locked && options.locked() ? 'Locked' : 'Not linked'))}<small>${escapeHtml(row.rom || 'RoM account not known')}</small></span>`},
        {key: 'gold', name: 'Gold', number: true, cell: row => `<span class="gold-cell">${escapeHtml(formatNumber(row.gold))}</span>`},
        {key: 'bag', name: 'Bag', number: true, also: [{key: 'bank', name: 'Bank'}],
          cell: row => `<span class="stacked">${slots('in bag', row.bag, row.character?.bagSlots)}<small>${row.bankSeen || row.bank > 0 ? slots('in bank', row.bank, row.character?.bankSlots) : 'Bank not recorded'}</small></span>`},
        {key: 'saved', name: 'Last saved', text: true, cell: row => escapeHtml(row.saved || 'Not recorded')},
        {key: 'day', name: 'Reward day', number: true, also: [{key: 'taken', name: 'Taken'}],
          cell: row => (row.taken ? `<span class="stacked">Day ${escapeHtml(row.day || '?')}<small>${escapeHtml(clock.format(row.taken))}</small></span>` : '<span class="not-recorded">Not recorded</span>')},
        {key: 'stale', name: 'Status', cell: row => (row.stale ? '<span class="status-pill" title="Saved by an older version: log in once on the current one">Needs login</span>' : '<span class="status-pill is-good">Current</span>')},
        {key: 'open', noSort: true, className: 'open-col', cell: row => `<button type="button" class="row-open" data-open-char="${escapeHtml(row.key || '')}" aria-label="Details for ${escapeHtml(row.name)}" title="Details"><span class="ico" data-cell-icon="chevron-right"></span></button>`},
      ],
      groups, isSelected: options.isSelected, open: !!String(options.search || '').trim(), empty: characters.length ? 'No character matches.' : 'No characters saved yet.',
    });
    if (typeof window !== 'undefined') for (const icon of root.querySelectorAll('[data-cell-icon]')) icon.innerHTML = window.GB_ICONS?.[icon.dataset.cellIcon] || '';
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

  // options: {roster, favouritesRoot, openTab(name), visible(): whether the Bank page is open, tooltip: the item
  // tooltip's element, review(kind): open the Characters page on 'login' or 'bank', favouritesChanged(count)}
  function create(root, send, status, onData, menu, options = {}) {
    const roster = options.roster || null;
    const state = {characters: [], entries: [], made: null, total: -1, sort: 'name', cells: [], names: new Map(), loadedAt: 0, layout: 'grid', active: -1};
    const settings = {excluded: new Set(), whitelist: new Set(), excludeBound: false};
    const rules = {on: true, types: new Set(DEFAULT_RULES.types), stats: 'apart', always: new Set(), favourites: new Map(), quality: true};
    const icons = new Map();
    const requested = new Set();
    const el = id => root.querySelector('#' + id);
    const tooltip = options.tooltip || el('bank-tooltip');
    const grid = el('bank-grid');
    const hasDom = typeof window !== 'undefined' && !!grid?.appendChild;
    const storage = typeof chrome !== 'undefined' && chrome.storage ? chrome.storage.local : null;
    let columns = 1, rows = 0, frame = 0, space = null, typingTimer = 0, gridDirty = false, gridFrame = 0, loading = null, panelCell = null;
    const pool = [];
    const shape = () => LAYOUTS[state.layout];
    // The same item again after the grid was drawn anew: cells are made each time, the saved entries aren't
    const sameCell = (a, b) => !!a && !!b && a.places[0] === b.places[0];

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
      nodes.push(make('span', 'bank-tip-hint', 'Click for where it is. Right-click: favourite, always stack, exclude, select who holds it, or copy a login'));
      tooltip.replaceChildren(...nodes);
      tooltip.hidden = false;
      moveTooltip(event);
    }
    // Who the Bank shows: the region and server ticks, and its scope when it has one. The other pages only follow
    // the region and the ticks, and selecting a character never changes this until Use in Bank says so.
    function scoped() {
      return !!roster?.scoped && roster.scoped();
    }
    function keep(withScope = true) {
      if (!roster) return null;
      const only = withScope && scoped();
      return character => roster.shows(character) && (!only || roster.inScope(character.key));
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
      slot.id = `bank-slot-${pool.length}`;
      slot.setAttribute('role', 'option');
      slot.letters = make('span', 'bank-letters');
      slot.picture = make('img');
      slot.picture.alt = '';
      slot.count = make('span', 'bank-count');
      slot.star = make('span', 'bank-star', '★');
      // Only the list shows these
      slot.nameText = make('span', 'bank-slot-text is-name');
      slot.whereText = make('span', 'bank-slot-text is-where');
      slot.quantityText = make('span', 'bank-slot-text is-quantity');
      slot.append(slot.letters, slot.picture, slot.count, slot.star, slot.nameText, slot.whereText, slot.quantityText);
      grid.append(slot);
      return slot;
    }
    function fill(slot, cell, index) {
      slot.dataset.index = String(index);
      const excluded = isHidden(cell.places[0], settings);
      const favourite = rules.favourites.has(cell.key);
      slot.className = 'bank-slot filled' + (excluded ? ' bank-excluded' : '') + (rules.quality && cell.quality ? ` q${cell.quality}` : '') + (favourite ? ' is-favourite' : '')
        + (index === state.active ? ' is-active' : '') + (sameCell(panelCell, cell) ? ' is-open' : '');
      slot.setAttribute('aria-label', `${cell.name}, ${formatNumber(cell.total)}`);
      slot.setAttribute('aria-selected', String(index === state.active));
      slot.letters.textContent = cell.name.slice(0, 2);
      if (shape().rows) {
        const who = new Set(cell.places.map(place => place.ch?.key || place.character));
        slot.nameText.replaceChildren(cell.name, make('small', '', [cell.type, cell.quality ? QUALITY[cell.quality] : ''].filter(Boolean).join(' · ')));
        slot.nameText.style.color = cell.color ? `#${cell.color}` : '';
        slot.whereText.replaceChildren(who.size === 1 ? cell.places[0].character : `${formatNumber(who.size)} characters`,
          make('small', '', [...new Set(cell.places.map(place => PLACE[place.shop ? 'shop' : place.place]))].join(' + ')));
        slot.quantityText.textContent = formatNumber(cell.total);
      }
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
      const {slot, gap, rows: oneColumn} = shape();
      const width = Math.max(slot, grid.clientWidth - PAD * 2);
      columns = oneColumn ? 1 : Math.max(1, Math.floor((width + gap) / (slot + gap)));
      rows = Math.ceil(state.cells.length / columns);
      space.style.height = (rows ? rows * (slot + gap) - gap + PAD * 2 : 0) + 'px';
    }
    function paint() {
      frame = 0;
      if (!hasDom) return;
      const step = shape().slot + shape().gap;
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
      const activeSlot = state.active >= from && state.active < to ? pool[state.active - from] : null;
      if (activeSlot) grid.setAttribute('aria-activedescendant', activeSlot.id);
      else grid.removeAttribute('aria-activedescendant');
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
      if (state.active >= state.cells.length || fromTop) state.active = -1;
      if (hasDom) {
        layout();
        grid.scrollTop = fromTop ? 0 : Math.min(grid.scrollTop, Math.max(0, grid.scrollHeight - grid.clientHeight));
        paint();
        let empty = grid.querySelector('.bank-empty');
        if (!state.cells.length) {
          if (!empty) {
            empty = make('div', 'bank-empty');
            const picture = make('img');
            picture.src = 'brand/empty-state-vault.svg';
            picture.alt = '';
            empty.append(picture, make('p', 'hint'));
            grid.append(empty);
          }
          empty.querySelector('p').textContent = state.characters.length ? 'Nothing matches these filters.' : 'No characters saved yet: log out of a character in game, then press Update now.';
        } else if (empty) empty.remove();
      }
      // Before the first read there's nothing to count, which isn't the same as counting nothing
      if (!state.loadedAt) return;
      const shown = keepCharacters();
      const gold = shown.reduce((sum, character) => sum + (Number(character.gold) || 0), 0);
      const held = totals(shown);
      el('bank-sum-items').textContent = formatNumber(held.items);
      el('bank-sum-stacks').textContent = formatNumber(held.stacks);
      el('bank-sum-gold').textContent = formatCompact(gold);
      el('bank-sum-gold').title = `${formatNumber(gold)} gold`;
      el('bank-sum-characters').textContent = formatNumber(shown.length);
      el('bank-shown').textContent = formatNumber(state.cells.length);
      el('bank-total').textContent = `${formatNumber(state.cells.reduce((sum, cell) => sum + cell.total, 0))} items in these`;
      el('bank-reset-filters').hidden = !filtersActive();
      renderScope(shown.length);
      // Separate warnings, which can overlap. Both take a login in game, which Update now can't do.
      const stale = shown.filter(character => character.stale).length;
      const unseen = shown.filter(character => !bankKnown(character)).length;
      el('coverage-login').hidden = !stale;
      el('coverage-bank').hidden = !unseen;
      el('bank-coverage').hidden = !stale && !unseen;
      el('coverage-login-text').textContent = stale === 1 ? '1 character needs a login on the current version' : `${formatNumber(stale)} characters need a login on the current version`;
      el('coverage-bank-text').textContent = unseen === 1 ? '1 bank not recorded: log in once with that character' : `${formatNumber(unseen)} banks not recorded: log in once with each`;
    }
    // Every filter that narrows what's listed, apart from the characters, which have their own reset
    function filtersActive() {
      return !!(el('bank-search').value.trim() || el('bank-search-in').value || el('bank-type').value || el('bank-place').value || el('bank-min-level').value || el('bank-max-level').value
        || el('bank-binding')?.value || Number(el('bank-quality')?.value) || el('bank-only-stats')?.checked || el('bank-only-favourites')?.checked);
    }
    function resetFilters() {
      for (const id of ['bank-search', 'bank-search-in', 'bank-type', 'bank-place', 'bank-min-level', 'bank-max-level', 'bank-binding']) el(id).value = '';
      el('bank-quality').value = '0';
      el('bank-only-stats').checked = el('bank-only-favourites').checked = false;
      renderGrid(true);
    }
    // Who is in view, in words, with a way back to everyone
    function renderScope(count) {
      const box = el('bank-scope');
      if (!hasDom) return;
      if (!scoped()) {
        box.textContent = `All ${formatNumber(count)} characters in view`;
        return;
      }
      const reset = make('button');
      reset.type = 'button';
      reset.setAttribute('aria-label', 'Show all characters');
      reset.title = 'Show all characters';
      const cross = make('span', 'ico');
      cross.innerHTML = window.GB_ICONS?.close || '';
      reset.append(cross);
      reset.addEventListener('click', () => roster.clearScope());
      const chip = make('span', 'active-scope', count === 1 ? `Only ${keepCharacters()[0]?.name || '1 character'}` : `Only ${formatNumber(count)} characters`);
      chip.append(reset);
      box.replaceChildren(chip);
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
      if (options.favouritesChanged) options.favouritesChanged(rules.favourites.size);
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
      el('bank-exclusions-summary').textContent = settings.excluded.size || settings.whitelist.size ? `Excluded items (${settings.excluded.size} excluded, ${settings.whitelist.size} always kept)` : 'Excluded items';
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
    // What can be done with an item, from its right-click menu and its panel
    function itemActions(cell) {
      const hidden = isHidden(cell.places[0], settings);
      const favourite = rules.favourites.has(cell.key);
      const always = rules.always.has(cell.key);
      const holding = new Set(cell.places.map(place => place.ch?.key || place.character)).size;
      return [
        {label: favourite ? 'Remove from favourites' : 'Add to favourites', icon: 'star', run() {
          if (favourite) rules.favourites.delete(cell.key);
          else rules.favourites.set(cell.key, {name: cell.name, icon: cell.icon || ''});
          settingsChanged();
        }},
        {label: always ? 'Stop always stacking this item' : 'Always stack every copy of this item', icon: 'compact', run() {
          if (always) rules.always.delete(cell.key);
          else rules.always.add(cell.key);
          settingsChanged();
        }},
        {label: hidden ? 'Bring this item back' : 'Exclude this item', icon: hidden ? 'eye' : 'eye-off', run() {
          toggleHidden(cell.places[0], settings);
          settingsChanged();
        }},
        {label: 'Show only this item', icon: 'search', run() {
          el('bank-search').value = cell.name;
          el('bank-search-in').value = '';
          if (options.openTab) options.openTab('bank');
          renderGrid(true);
        }},
        ...(roster ? [{label: holding === 1 ? 'Select the character who holds it' : `Select the ${formatNumber(holding)} characters who hold it`, icon: 'users', run() {
          roster.setSelection([...roster.selection, ...cell.places.map(place => place.ch?.key).filter(Boolean)]);
        }}] : []),
      ];
    }
    function itemMenu(event, cell) {
      if (tooltip) tooltip.hidden = true;
      menu(event, itemActions(cell), cell.places.map(place => place.character));
    }
    function closePanel() {
      panelCell = null;
      el('item-panel').hidden = true;
      repaint();
    }
    function openPanel(cell) {
      panelCell = cell;
      if (tooltip) tooltip.hidden = true;
      drawPanel();
      repaint();
    }
    function drawPanel() {
      const panel = el('item-panel');
      if (!hasDom || !panel) return;
      if (!panelCell) { panel.hidden = true; return; }
      const cell = panelCell;
      const who = holders(cell.places);
      const servers = new Set(who.map(row => row.server));
      const slot = make('div', `bank-slot filled${rules.quality && cell.quality ? ` q${cell.quality}` : ''}`);
      slot.append(make('span', 'bank-letters', cell.name.slice(0, 2)));
      if (icons.has(cell.icon)) {
        const picture = make('img');
        picture.alt = '';
        picture.src = icons.get(cell.icon);
        slot.append(picture);
      }
      const name = make('h2', '', cell.name);
      if (cell.color) name.style.color = `#${cell.color}`;
      const heading = make('div');
      heading.append(name, make('div', 'item-panel-sub', [cell.quality ? QUALITY[cell.quality] : '', cell.type, cell.bound ? 'Bound' : ''].filter(Boolean).join(' · ')));
      const close = make('button', 'item-panel-close gb-button--icon gb-button--ghost');
      close.type = 'button';
      close.setAttribute('aria-label', 'Close the details');
      const cross = make('span', 'ico');
      cross.innerHTML = window.GB_ICONS?.close || '';
      close.append(cross);
      close.addEventListener('click', () => { closePanel(); grid.focus({preventScroll: true}); });
      const top = make('div', 'item-panel-top');
      top.append(slot, heading, close);
      const nodes = [top];
      const lines = cell.mixed ? [] : tipLines(cell.tip);
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
        const details = itemLines(cell).filter(line => line.kind !== 'type' || cell.mixed);
        if (details.length) {
          const box = make('div', 'game-tip');
          for (const line of details) box.append(make('div', `bank-tip-${line.kind}`, line.text));
          nodes.push(box);
        }
      }
      const metrics = make('div', 'detail-metrics');
      for (const [value, label] of [[formatNumber(cell.total), 'In all'], [formatNumber(who.length), who.length === 1 ? 'Character holds it' : 'Characters hold it']]) {
        const metric = make('div', 'detail-metric', value);
        metric.append(make('span', '', label));
        metrics.append(metric);
      }
      nodes.push(metrics, make('div', 'detail-title', 'Where to find it'));
      const owners = make('div', 'owner-list');
      for (const row of who.slice(0, 200)) {
        const card = make('div', 'owner-card' + (roster?.isSelected(row.key) ? ' is-selected' : ''));
        if (row.key) card.dataset.char = row.key;
        card.append(make('b', '', row.name), make('span', 'owner-qty', formatNumber(row.count)),
          make('span', 'owner-meta', [row.server && !row.name.endsWith(`(${row.server})`) ? row.server : row.server ? '' : NO_SERVER, row.parts.join(' · ')].filter(Boolean).join(' · ')));
        owners.append(card);
      }
      if (who.length > 200) owners.append(make('span', 'hint', `and ${formatNumber(who.length - 200)} more characters`));
      nodes.push(owners);
      if (/^\d+$/.test(String(cell.id || ''))) nodes.push(make('span', 'hint', `Item ${cell.id}${servers.size > 1 ? ` · on ${formatNumber(servers.size)} servers` : ''}`));
      const actions = make('div', 'detail-actions');
      const copy = make('button', 'gb-button--sm', 'Copy name');
      copy.type = 'button';
      copy.addEventListener('click', () => navigator.clipboard.writeText(cell.name).then(() => { copy.textContent = 'Copied'; }, () => { copy.textContent = 'Could not copy'; }));
      actions.append(copy);
      for (const action of itemActions(cell)) {
        const button = make('button', 'gb-button--sm', action.label);
        button.type = 'button';
        button.addEventListener('click', () => { action.run(); drawPanel(); });
        actions.append(button);
      }
      nodes.push(actions);
      panel.replaceChildren(...nodes);
      panel.hidden = false;
    }
    // The grid from the keyboard: arrow keys move among the slots, Enter opens the panel, the menu key its menu
    function setActive(index) {
      state.active = Math.max(0, Math.min(state.cells.length - 1, index));
      const step = shape().slot + shape().gap;
      const top = PAD + Math.floor(state.active / columns) * step;
      if (top - PAD < grid.scrollTop) grid.scrollTop = top - PAD;
      else if (top + shape().slot + PAD > grid.scrollTop + grid.clientHeight) grid.scrollTop = top + shape().slot + PAD - grid.clientHeight;
      paint();
    }
    function gridKey(event) {
      const count = state.cells.length;
      if (!count) return;
      const step = shape().slot + shape().gap;
      const page = Math.max(1, Math.floor(grid.clientHeight / step)) * columns;
      const at = state.active < 0 ? Math.floor(grid.scrollTop / step) * columns : state.active;
      const moves = {ArrowRight: at + 1, ArrowLeft: at - 1, ArrowDown: at + columns, ArrowUp: at - columns, PageDown: at + page, PageUp: at - page, Home: 0, End: count - 1};
      if (event.key in moves) {
        event.preventDefault();
        setActive(state.active < 0 ? at : moves[event.key]);
      } else if ((event.key === 'Enter' || event.key === ' ') && state.active >= 0) {
        event.preventDefault();
        openPanel(state.cells[state.active]);
      } else if (event.key === 'Escape' && panelCell) {
        event.preventDefault();
        closePanel();
      } else if ((event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10')) && state.active >= 0) {
        event.preventDefault();
        const box = pool.find(slot => !slot.hidden && slot.dataset.index === String(state.active))?.getBoundingClientRect();
        if (box) itemMenu({preventDefault() {}, clientX: box.left + box.width / 2, clientY: box.bottom}, state.cells[state.active]);
      }
    }
    // Large slots, small slots or a list. The first item in view stays in view.
    function setLayout(name, remember = true) {
      if (!LAYOUTS[name]) return;
      const before = shape().slot + shape().gap;
      const firstRow = hasDom ? Math.floor(grid.scrollTop / before) * columns : 0;
      state.layout = name;
      if (remember && storage) storage.set({bankLayout: name}).catch(() => {});
      if (!hasDom) return;
      grid.classList.toggle('is-compact', name === 'compact');
      grid.classList.toggle('is-list', name === 'list');
      for (const button of root.querySelectorAll('[data-bank-layout]')) button.setAttribute('aria-pressed', String(button.dataset.bankLayout === name));
      layout();
      grid.scrollTop = Math.floor(firstRow / columns) * (shape().slot + shape().gap);
      paint();
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
      if (!favouriteList.length) gridArea.append(make('p', 'bank-empty', 'No favourites yet. Right-click an item on the Bank page and choose Add to favourites.'));
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

    // The Bank's own list of characters: it ticks who the Bank shows, grouped by server, with a search for thousands.
    function renderPicker() {
      const list = el('bank-character-list');
      const details = el('bank-characters-menu');
      if (!list?.replaceChildren || !roster) return;
      if (details && !details.open) return;
      const wanted = (el('bank-character-find')?.value || '').trim().toLowerCase();
      const shown = state.characters.filter(character => roster.shows(character) && (!wanted || character.name.toLowerCase().includes(wanted)));
      const groups = new Map();
      for (const character of shown) {
        const server = character.shownServer || NO_SERVER;
        if (!groups.has(server)) groups.set(server, []);
        groups.get(server).push(character);
      }
      const parts = [];
      for (const [server, members] of [...groups.entries()].sort((a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0]))) {
        parts.push(`<div class="picker-server">${escapeHtml(server)} <span class="hint">${formatNumber(members.length)}</span></div>`);
        // The ticked ones first, so they're easy to find and untick
        for (const character of members.slice().sort((a, b) => Number(roster.inScope(b.key)) - Number(roster.inScope(a.key)) || a.name.localeCompare(b.name)).slice(0, 2000)) {
          parts.push(`<div class="bank-character${roster.inScope(character.key) ? ' is-selected' : ''}" role="checkbox" tabindex="0" aria-checked="${roster.inScope(character.key)}" data-scope-char="${escapeHtml(character.key)}" data-char-tip="${escapeHtml(character.key)}"><span class="tick" aria-hidden="true"></span><span class="bank-name">${escapeHtml(character.name)}</span><span class="bank-detail">${escapeHtml(`${character.class || 'Level'} ${character.level || '?'} · ${formatNumber(character.gold)} gold`)}</span></div>`);
        }
      }
      if (!parts.length) parts.push('<p class="hint">No character matches.</p>');
      list.innerHTML = parts.join('');
    }
    function renderSummary() {
      const summary = el('bank-character-summary');
      if (!summary || !roster) return;
      const shown = state.characters.filter(character => roster.shows(character)).length;
      const inScope = roster.scoped() ? roster.inScopeShown().length : 0;
      summary.textContent = inScope ? `${formatNumber(inScope)} of ${formatNumber(shown)} characters` : `All characters (${formatNumber(shown)})`;
      const use = el('bank-select-use');
      const selected = roster.selected().length;
      use.hidden = !selected;
      use.textContent = `Use my selection (${formatNumber(selected)})`;
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
      // The panel's item, in the new data, if it's still there
      if (panelCell) {
        panelCell = state.cells.find(cell => cell.key === panelCell.key) || null;
        drawPanel();
      }
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
      button.setAttribute?.('aria-busy', 'true');
      status('Reading your save files…');
      try {
        const response = await send({type: 'bank-command', command: 'update'});
        await reload();
        status((response.output || '').trim().split('\n').pop() || 'Updated.');
      } catch (error) {
        status(`Could not update: ${error.message || error}`);
      } finally {
        button.disabled = false;
        button.removeAttribute?.('aria-busy');
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
    el('bank-reset-filters').addEventListener('click', resetFilters);
    el('coverage-login-review').addEventListener('click', () => options.review?.('login'));
    el('coverage-bank-review').addEventListener('click', () => options.review?.('bank'));
    el('bank-select-clear')?.addEventListener('click', () => roster?.clearScope());
    el('bank-select-use')?.addEventListener('click', () => roster?.useSelection());
    el('bank-select-shown')?.addEventListener('click', () => {
      const wanted = (el('bank-character-find')?.value || '').trim().toLowerCase();
      roster?.setScope([...roster.scope, ...state.characters.filter(character => roster.shows(character) && (!wanted || character.name.toLowerCase().includes(wanted))).map(character => character.key)]);
    });
    // Ticks in the Bank's list change what the Bank shows at once: Shift-click takes a range
    const pickerKeys = () => [...el('bank-character-list').querySelectorAll('[data-scope-char]')].map(row => row.dataset.scopeChar);
    function tickCharacter(row, range) {
      if (range) roster?.scopeRange(pickerKeys(), row.dataset.scopeChar);
      else roster?.toggleScope(row.dataset.scopeChar);
    }
    el('bank-character-list')?.addEventListener('click', event => {
      const row = event.target?.closest?.('[data-scope-char]');
      if (!row) return;
      tickCharacter(row, event.shiftKey);
      if (event.shiftKey) window.getSelection?.()?.removeAllRanges?.();
    });
    el('bank-character-list')?.addEventListener('keydown', event => {
      const row = event.target?.closest?.('[data-scope-char]');
      if (!row || (event.key !== ' ' && event.key !== 'Enter')) return;
      event.preventDefault();
      tickCharacter(row, event.shiftKey);
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
      grid.addEventListener('click', event => {
        const cell = cellAt(event.target);
        if (!cell) return;
        state.active = Number(event.target.closest('.bank-slot').dataset.index);
        if (sameCell(panelCell, cell)) closePanel();
        else openPanel(cell);
      });
      grid.addEventListener('keydown', gridKey);
      for (const button of root.querySelectorAll('[data-bank-layout]')) button.addEventListener('click', () => setLayout(button.dataset.bankLayout));
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
        // Names, the hover card's checkmarks and the order on the Gameforge accounts page don't change this page
        if (what !== 'selection' && what !== 'view' && what !== 'scope') return;
        renderSummary();
        // Selecting characters is only marks: the Bank waits to be told, through Use in Bank
        if (what === 'selection') {
          if (panelCell) drawPanel();
          return;
        }
        if (what === 'scope') {
          el('bank-character-list')?.querySelectorAll?.('[data-scope-char]')?.forEach(row => {
            const ticked = roster.inScope(row.dataset.scopeChar);
            row.classList.toggle('is-selected', ticked);
            row.setAttribute('aria-checked', String(ticked));
          });
          scheduleGrid();
          return;
        }
        renderPicker();
        scheduleGrid();
        renderFavourites();
      });
    }
    if (storage) {
      storage.get(['bankExclusions', 'bankRules', 'bankLayout']).then(({bankExclusions: saved, bankRules: kept, bankLayout}) => {
        setLayout(bankLayout || 'grid', false);
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
        if (options.favouritesChanged) options.favouritesChanged(rules.favourites.size);
      }).catch(() => {});
    }
    return {
      reload, update, renderGrid, renderFavourites, closePanel,
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
    formatDuration, totals, isHidden, toggleHidden, stackable, gearLines, tipLines, itemLines, holders, currencyTable, currencyName, renderCurrencies, accountCurrencies,
    rosterRows, renderRoster, statTable, renderStats, favouriteRows, groupedTable, escapeHtml, formatNumber, formatCompact, transferStones, transferStonesText, bankKnown};
})();
