'use strict';
// The Bank page: everything every character holds, in one scrolling grid like the game's own bank, with a search,
// filters, stacking rules, favourites, the game's own tooltips and a panel saying who holds an item and where. The
// Favourites, Currencies, Stats and Characters pages read the same data. Only the rows and slots on screen are
// drawn, so thousands of characters stay quick.
const GBBank = (() => {
  // The game's own pages: 30 bag slots, 40 bank slots. Bank slots after 200 are the item shop's tab.
  const PER_PAGE = {bag: 30, bank: 40};
  const PLACE = {bag: 'Bag', bank: 'Bank', shop: 'Item shop tab', worn: 'Worn'};
  // What a character wears, by the slot names the game's character window uses
  const SLOT_LABELS = {Head: 'Head', Shoulder: 'Shoulders', Chest: 'Chest', Hands: 'Hands', Waist: 'Waist', Feet: 'Feet', Legs: 'Legs', Back: 'Back',
    MainHand: 'Main hand', SecondaryHand: 'Off hand', Ranged: 'Ranged weapon', Ammo: 'Ammunition', Necklace: 'Necklace', Earring0: 'Earring', Earring1: 'Earring',
    Ring0: 'Ring', Ring1: 'Ring', Talisman0: 'Talisman', Talisman1: 'Talisman', Talisman2: 'Talisman', Adornment: 'Adornment'};
  const WORN_TYPES = {MainHand: 'Weapons', SecondaryHand: 'Weapons', Ranged: 'Weapons', Ammo: 'Weapons', Necklace: 'Jewellery', Earring0: 'Jewellery',
    Earring1: 'Jewellery', Ring0: 'Jewellery', Ring1: 'Jewellery', Talisman0: 'Jewellery', Talisman1: 'Jewellery', Talisman2: 'Jewellery'};
  const slotLabel = where => SLOT_LABELS[where] || String(where || 'Worn');
  // A slot's tier mark shows from this tier up, until you pick another
  const TIER_FROM = 7;
  const SHOP_FROM = 200;
  const MAX_HOLDERS = 10;
  // Copies of a stack of gear its tooltip lists one by one
  const MAX_COPIES = 15;
  const TYPES = ['Armour', 'Weapons', 'Jewellery', 'Runes', 'Mana stones', 'Potions', 'Materials', 'Recipes', 'Mounts and pets', 'Other'];
  const EQUIPPABLE = new Set(['Weapons', 'Armour', 'Jewellery']);
  // Every type can stack, and anything with stats of its own stacks only with identical copies.
  const DEFAULT_RULES = {on: true, types: new Set(TYPES), stats: 'match', always: new Set()};
  const NO_STACK = {on: false, types: new Set(), stats: 'apart', always: new Set()};
  const QUALITY = ['Plain', 'Green', 'Blue', 'Purple', 'Orange', 'Gold'];
  // The HD mark in a slot's corner: durability above this
  const HIGH_DURABILITY = 101;
  // The colours of a slot's corner marks, until you pick your own. control.css starts from these too.
  const MARK_COLORS = {tier: '#ff6b5e', plus: '#ffd75e', hd: '#5fe07a', count: '#ffffff'};
  // How the game's tooltip names an item's tier in each client language: Tier 18, Grad 18 and so on
  const TIER_LINE = /^\s*(?:Tier|Grad|Grado|Nivel|Rang|Série|Stopień|Уровень|Aşama|Cấp|등급|階層|阶层|ระดับ|ミスティックレベル|طبقة)\s+(\d+)\s*$/;
  // Bought with real money and shared by an account, so adding them up across characters would count them twice.
  // The game's code says bonus and billdin. Its Item Shop says Rubies and Phirius Tokens, which players call Daily Tokens.
  const SHOP_NAMES = {account: 'Diamonds', bonus: 'Rubies', billdin: 'Daily Tokens'};
  // Diamonds and Rubies belong to an account. Daily Tokens come from each character's daily quests.
  const ACCOUNT_MONEY = new Set(['account', 'bonus']);
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
  // The shortest form, for a tile: at most four characters, and rounded down too
  function formatTiny(value) {
    const amount = Math.max(0, Math.floor(Number(value) || 0));
    if (amount >= 1e10) return `${Math.floor(amount / 1e9)}B`;
    if (amount >= 1e9) return `${Math.floor(amount / 1e8) / 10}B`;
    if (amount >= 1e7) return `${Math.floor(amount / 1e6)}M`;
    if (amount >= 1e6) return `${Math.floor(amount / 1e5) / 10}M`;
    if (amount >= 1e4) return `${Math.floor(amount / 1e3)}K`;
    if (amount >= 1e3) return `${Math.floor(amount / 100) / 10}K`;
    return String(amount);
  }
  const counted = (count, word) => `${formatNumber(count)} ${word}${count === 1 ? '' : 's'}`;
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
  // Mana and fusion stones, by the IDs whose links can hold stats. zBag and the game window use the same ones.
  function isStone(id) {
    const number = Number(id) || 0;
    return (number >= 202840 && number <= 202859) || (number >= 202880 && number <= 202885);
  }
  // An item's tier: a mana stone's is in its ID, with 202840 as tier 1, and gear's is on its tooltip. 0 when not known.
  function tierOf(item) {
    const number = Number(item.id) || 0;
    if (number >= 202840 && number <= 202859) return number - 202839;
    if (!item.gear) return 0;
    for (const line of item.tip || []) {
      const found = TIER_LINE.exec(String(line[1] || ''));
      if (found) return Number(found[1]);
    }
    return 0;
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
    // Plus jewels share the fusion stones' pictures, but aren't stones
    if (isStone(number) || (/mana stone|fusnion_stone/.test(path) && !/fusnion_stone\/(uv|fi)_/.test(path))) return 'Mana stones';
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
  // Characters, stacks and items in all, for the page's status line, with what they wear
  function totals(characters) {
    let stacks = 0, items = 0;
    for (const character of characters) {
      for (const place of ['bag', 'bank', 'equip']) {
        for (const item of character[place] || []) {
          stacks++;
          items += Number(item.count) || 1;
        }
      }
    }
    return {characters: characters.length, stacks, items};
  }
  // Bank 45 (page 2, slot 5), or Worn (Main hand)
  function locationLabel(place, slot, where) {
    if (place === 'worn') return `Worn (${slotLabel(where)})`;
    if (place === 'bank' && slot > SHOP_FROM) return `Bank ${slot} (item shop tab, slot ${slot - SHOP_FROM})`;
    const perPage = PER_PAGE[place];
    const page = Math.floor((slot - 1) / perPage) + 1;
    return `${PLACE[place]} ${slot} (page ${page}, slot ${slot - (page - 1) * perPage})`;
  }
  function itemKey(entry) {
    return String(entry.id || entry.name);
  }
  // A worn item has no link, so what a link would say comes from its tooltip, as the game's character window shows it:
  // the plus on the first line ("Staff + 12"), a stat's name beside the first line of its effects, and its durability.
  function wornGear(item) {
    const tip = Array.isArray(item.tip) ? item.tip : [];
    const plus = Number(/\+\s*(\d+)\s*$/.exec(String(tip[0]?.[1] || ''))?.[1]) || 0;
    const stats = tip.filter(line => line[3] && /^[+-]\s*\d/.test(String(line[1] || ''))).map(line => String(line[3]));
    return {dura: Number(item.dura) || 0, maxDura: Number(item.maxDura) || 0, plus, tier: 0, freeSlots: 0, stats, runes: [],
      color: /^[0-9a-f]{6}$/i.test(tip[0]?.[0] || '') ? tip[0][0] : '', worn: true};
  }
  // One row for each stack on each character, and for each thing it wears, with what a search and the filters need
  // worked out once. A worn item's ID comes from the same item in someone's bag or bank, when there is one.
  function entries(characters) {
    const list = [];
    const worn = [];
    const ids = new Map();
    for (const character of characters) {
      const level = Number(character.level) || 0;
      for (const place of ['bag', 'bank', 'equip']) {
        for (const item of character[place] || []) {
          const onBody = place === 'equip';
          const gear = onBody ? wornGear(item) : item.gear || null;
          const stats = gear?.stats || item.stats || [];
          const name = String(item.name || 'Unknown item');
          const color = /^[0-9a-f]{6}$/i.test(gear?.color || '') ? gear.color : /^[0-9a-f]{6}$/i.test(item.tip?.[0]?.[0] || '') ? item.tip[0][0] : '';
          const entry = {id: item.id, name, lower: name.toLowerCase(), icon: item.icon, count: Number(item.count) || 1, tier: tierOf(onBody ? {...item, gear} : item),
            type: onBody ? WORN_TYPES[item.where] || 'Armour' : typeOf(item.id, item.icon), bound: onBody || !!item.bound, gear, stats, stone: !!item.stats,
            tip: item.tip || null, color, quality: qualityOf(color), search: stats.concat(gear?.runes || []).join('\n').toLowerCase(), character: character.name,
            ch: character, level, place: onBody ? 'worn' : place, where: onBody ? String(item.where || '') : '',
            shop: place === 'bank' && Number(item.slot) > SHOP_FROM, slot: Number(item.slot) || 0};
          if (onBody) worn.push(entry);
          else if (/^\d+$/.test(String(item.id || '')) && !ids.has(entry.lower)) ids.set(entry.lower, String(item.id));
          list.push(entry);
        }
      }
    }
    for (const entry of worn) entry.id = ids.get(entry.lower) || `n:${entry.name}`;
    return list;
  }
  // The plus on a piece of gear, from its link or, for a worn one, its tooltip
  const plusOf = entry => Number(entry.gear?.plus) || 0;
  // The quick filters a search can hold, each one word: #+5> (a plus above 5), #+5< (below), #+5>= and #+5 or #+5= (exactly +5), the same with
  // #t for the tier, and #equipped=true or false (worn by a character, or not). A plus works without its # too. Only
  // gear has a plus, and only gear and mana stones a tier, so the rest never matches those.
  const QUICK = /^(?:#?\+(\d{1,2})|#t(\d{1,2}))(>=|=>|<=|=<|!=|>|<|=)?$/i;
  function quickFilters(text) {
    const tests = [];
    const words = [];
    const all = String(text || '');
    // Only a search with a quick filter in it is split at its commas: an item's name can have one
    if (!/(^|[\s,])(#?\+\d|#t\d|#equipped|#worn)/i.test(all)) return {tests, text: all};
    for (const word of all.split(/[\s,]+/)) {
      if (!word) continue;
      const found = QUICK.exec(word);
      if (found) {
        const limit = Number(found[1] ?? found[2]);
        const plus = found[1] !== undefined;
        const how = found[3] || '=';
        tests.push(entry => {
          if (plus ? !entry.gear : !(entry.tier > 0)) return false;
          return compare(plus ? plusOf(entry) : entry.tier, how, limit);
        });
        continue;
      }
      const worn = /^#(?:equipped|worn)(?:=(true|false|yes|no))?$/i.exec(word);
      if (worn) {
        const on = !worn[1] || /^(true|yes)$/i.test(worn[1]);
        tests.push(entry => (entry.place === 'worn') === on);
        continue;
      }
      words.push(word);
    }
    return {tests, text: words.join(' ')};
  }
  // The test each item passes to be shown. keep(character) says whether its holder is on the page at all.
  function matcher(filters) {
    // The quick filters first, then #clean and #dirty: mana and fusion stones without stats, or with stats, as in zBag.
    // The rest of the search still applies here, so #dirty wisdom finds stones with wisdom on them.
    const quick = quickFilters(filters.text);
    let stones = '';
    const text = quick.text.toLowerCase().replace(/(^|[\s,])#(clean|dirty)(?=[\s,]|$)/g, (all, space, word) => {
      stones = word;
      return ' ';
    }).trim();
    const anyStat = names => names.some(name => name.toLowerCase().includes(text));
    return entry => {
      for (const test of quick.tests) if (!test(entry)) return false;
      if (stones) {
        if (!isStone(entry.id)) return false;
        // A stone saved before stats were recorded could be either, so it only counts once it says it has some
        if (stones === 'dirty' ? !entry.stats.length : entry.stats.length || entry.ch?.stale) return false;
      }
      if (text) {
        if (filters.searchIn === 'items') { if (entry.stone || !anyStat(entry.stats)) return false; }
        else if (filters.searchIn === 'stones') { if (!entry.stone || !anyStat(entry.stats)) return false; }
        else if (!(entry.lower ?? entry.name.toLowerCase()).includes(text) && !(entry.search ?? '').includes(text) && !anyStat(entry.stats) && !anyStat(entry.gear?.runes || [])) return false;
      }
      if (filters.type && entry.type !== filters.type) return false;
      // '' is everywhere, 'stored' the bag and the bank without what's worn
      if (filters.place === 'shop' ? !entry.shop : filters.place === 'stored' ? entry.place === 'worn' : filters.place && entry.place !== filters.place) return false;
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
  // What tells two copies of an item apart: a piece of gear's plus, tier, stats and runes, or a stone's stats, in
  // whatever order the game listed them. Durability wears down and is repaired, so it never keeps copies apart: the
  // stack's tooltip lists each copy with its own.
  function statsSignature(entry) {
    const sorted = list => [...list].sort().join(';');
    if (entry.gear) return ['g', entry.gear.plus, entry.gear.tier, sorted(entry.gear.stats), sorted(entry.gear.runes)].join('/');
    return 's/' + sorted(entry.stats);
  }
  const duraOf = entry => `${Number(entry.gear?.dura) || 0}/${Number(entry.gear?.maxDura) || 0}`;
  // Which stack an item joins, or null when it stays on its own. An item you chose to always stack joins every copy of
  // itself. Otherwise its type has to be ticked, and anything with stats of its own stacks only as rules.stats says:
  // 'match' with identical copies, 'apart' with none, 'all' with every copy.
  function stackKey(entry, rules = DEFAULT_RULES) {
    const key = itemKey(entry);
    if (rules.always?.has(key)) return 'k:' + key;
    if (!rules.on || !rules.types.has(entry.type)) return null;
    if (rules.stats === 'all') return 'k:' + key;
    if (entry.gear || entry.stats.length) return rules.stats === 'match' ? 'k:' + key + '|' + statsSignature(entry) : null;
    // Saved before stats were recorded: nobody can say whether it's identical to anything
    if (EQUIPPABLE.has(entry.type) || (entry.ch?.stale && isStone(entry.id))) return null;
    return 'k:' + key;
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
        cell = {key: itemKey(entry), id: entry.id, name: entry.name, icon: entry.icon, type: entry.type, gear: entry.gear, stats: entry.stats, stone: entry.stone, tier: entry.tier || 0,
          tip: entry.tip, color: entry.color || '', quality: entry.quality || 0, bound: entry.bound, total: 0, places: [], mixed: false, duraMixed: false};
        found.set(key, cell);
        out.push(cell);
      } else {
        if (!cell.mixed && (entry.gear || entry.stats.length || cell.gear || cell.stats.length) && statsSignature(entry) !== statsSignature(cell.places[0])) cell.mixed = true;
        if (!cell.duraMixed && (entry.gear || cell.gear) && duraOf(entry) !== duraOf(cell.places[0])) cell.duraMixed = true;
      }
      cell.total += entry.count;
      cell.places.push(entry);
    }
    return out;
  }
  // What a slot's corners say about a cell, and the same in words for a screen reader. The tier shows from tierFrom up.
  function slotMarks(cell, tierFrom = TIER_FROM) {
    if (cell.mixed) return {tier: '', durability: '', plus: '', words: []};
    const tier = cell.tier > 0 && cell.tier >= tierFrom ? `T${cell.tier}` : '';
    const plus = cell.gear?.plus > 0 ? `+${cell.gear.plus}` : '';
    const durability = (cell.places?.length ? cell.places.every(entry => entry.gear?.dura > HIGH_DURABILITY) : cell.gear?.dura > HIGH_DURABILITY) ? 'HD' : '';
    return {tier, durability, plus, words: [tier && `tier ${cell.tier}`, plus, durability && 'high durability'].filter(Boolean)};
  }
  // By name, with a numeral at the end counted, so Wrath VIII comes before Wrath IX and Wrath X
  const ROMAN_END = /^(.*\S)\s+([IVXLC]+)$/;
  const ROMAN = {I: 1, V: 5, X: 10, L: 50, C: 100};
  function romanValue(text) {
    let total = 0, highest = 0;
    for (const letter of [...text].reverse()) {
      const value = ROMAN[letter];
      total += value < highest ? -value : value;
      highest = Math.max(highest, value);
    }
    return total;
  }
  function byName(a, b) {
    const x = ROMAN_END.exec(a.name), y = ROMAN_END.exec(b.name);
    if (x && y && x[1] === y[1]) return romanValue(x[2]) - romanValue(y[2]);
    return a.name.localeCompare(b.name);
  }
  const SORTS = {
    name: byName,
    count: (a, b) => b.total - a.total || byName(a, b),
    type: (a, b) => a.type.localeCompare(b.type) || byName(a, b),
    quality: (a, b) => b.quality - a.quality || byName(a, b),
    id: (a, b) => (Number(a.id) || 0) - (Number(b.id) || 0) || byName(a, b),
  };
  // Sorting by type: what can be worn first, as the character window goes (weapons, jewellery, armour, wings), then the
  // rest, each kind together and in the chosen order inside it, some kinds in parts of their own: runes by rank, the
  // item shop's plus jewels and backpack tickets, and the Dynamic, Mystical and Steadfast crafting materials. A good
  // guess from IDs, icons and names, like typeOf.
  const SORT_GROUPS = ['Weapons', 'Jewellery', 'Armour', 'Wings', 'Mana stones', 'Runes', 'Consumables', 'Item shop', 'Crafting materials', 'Materials',
    'Recipes', 'Mounts and pets', 'Other'];
  // The parts some kinds have, in their order. A part not listed comes last.
  const SORT_PARTS = {
    Runes: ['Rank 0', 'Rank 1', 'Rank 2', 'Rank 3', 'Rank 4', 'Rank 5', 'Rank 6', 'Unranked', 'Other runes'],
    'Item shop': ['Plus jewels', 'Backpack tickets', 'Other item shop items'],
    'Crafting materials': ['Dynamic', 'Mystical', 'Steadfast'],
  };
  // Each rune's rank, by its name without its numeral
  const RUNE_RANKS = new Map(Object.entries({
    'Rank 0': 'Defense Endurance Harm Magic Mind Quickness Resistance Shell Strike Vigor Vitality',
    'Rank 1': 'Atonement Charm Cruelty Dexterity Excite Guts Intellect Life Payback Rouse Safeguard Savage Spell Spirit Stamina Triumph Ward',
    'Rank 2': 'Anger Barrier Capability Comprehension Devil Ferocity Grasp Keenness Mayhem Resistor',
    'Rank 3': 'Dauntlessness Destruction Enchantment Fearless Fountain Madness Passion Potential',
    'Rank 4': 'Accuracy Agile Curse Enlightenment Might Raid Sorcery',
    'Rank 5': 'Advance Aggression Assassin Block Revolution Sage Shield Tyrant',
    'Rank 6': 'Enigma Experience Hatred Judge Loot Massacre Reconciliation',
    Unranked: 'Burst Fatal Miracle Wrath',
  }).flatMap(([rank, names]) => names.split(' ').map(name => [name.toLowerCase(), rank])));
  // shopIds: the items someone keeps in the item shop tab, which only takes what was bought there. Returns [group, part].
  function sortGroupOf(cell, shopIds = null) {
    const path = String(cell.icon || '').toLowerCase();
    const name = String(cell.name || '').toLowerCase();
    const worn = cell.places?.find(place => place.place === 'worn');
    if (worn?.where === 'Adornment' || /wing|adorn|back_ornament/.test(path)) return ['Wings', ''];
    if (cell.type === 'Runes') return ['Runes', RUNE_RANKS.get((ROMAN_END.exec(cell.name)?.[1] || cell.name).toLowerCase()) || 'Other runes'];
    if (/fusnion_stone\/(uv|fi)_|\bjewel\b/.test(path + ' ' + name)) return ['Item shop', 'Plus jewels'];
    if (/backpack ticket/.test(name)) return ['Item shop', 'Backpack tickets'];
    if (cell.type === 'Weapons' || cell.type === 'Jewellery' || cell.type === 'Armour' || cell.type === 'Mana stones') return [cell.type, ''];
    if (/power stone|mana stone/.test(path)) return ['Mana stones', ''];
    const family = /^(dynamic|mystical|steadfast)\b/.exec(name);
    if (family) return ['Crafting materials', family[1][0].toUpperCase() + family[1].slice(1)];
    if (shopIds?.has(String(cell.id)) || /shop_goods|shop key|firework|ticket/.test(path + ' ' + name)) return ['Item shop', 'Other item shop items'];
    if (cell.type === 'Potions' || /potion|food|cook|dish|scroll|elixir/.test(path)) return ['Consumables', ''];
    if (cell.type === 'Materials' || cell.type === 'Recipes' || cell.type === 'Mounts and pets') return [cell.type, ''];
    return ['Other', ''];
  }
  // The cells in type order, then in each kind's parts, each sorted as asked inside
  function sortByType(list, order, shopIds) {
    const rank = new Map(SORT_GROUPS.map((group, at) => [group, at]));
    const partRank = (group, part) => {
      const parts = SORT_PARTS[group];
      const at = parts ? parts.indexOf(part) : 0;
      return at < 0 ? parts.length : at;
    };
    for (const cell of list) [cell.group, cell.part] = sortGroupOf(cell, shopIds);
    return list.sort((a, b) => rank.get(a.group) - rank.get(b.group) || partRank(a.group, a.part) - partRank(b.group, b.part) || order(a, b));
  }
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
      const gear = gearLines(cell.gear);
      if (cell.duraMixed) gear[0] = `Durability ${duraRange(cell.places)}, each copy below`;
      for (const text of gear) lines.push({text, kind: 'plain'});
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
      if (!found.has(id)) found.set(id, {name: entry.character, key: entry.ch?.key || '', server: entry.ch?.shownServer || '', count: 0, at: {worn: [], bag: [], bank: [], shop: []}});
      const row = found.get(id);
      row.count += entry.count;
      row.at[entry.shop ? 'shop' : entry.place].push(entry);
    }
    return [...found.values()].sort((a, b) => b.count - a.count || a.name.localeCompare(b.name)).map(row => {
      const parts = [];
      for (const place of ['worn', 'bag', 'bank', 'shop']) {
        const list = row.at[place];
        if (!list.length) continue;
        const count = list.reduce((sum, entry) => sum + entry.count, 0);
        parts.push(list.length === 1 ? locationLabel(list[0].place, list[0].slot, list[0].where) + (count > 1 ? ` × ${formatNumber(count)}` : '')
          : place === 'worn' ? `Worn (${list.map(entry => slotLabel(entry.where)).join(', ')})` : `${PLACE[place]} × ${formatNumber(count)} in ${list.length} slots`);
      }
      return {name: row.name, key: row.key, server: row.server, count: row.count, parts};
    });
  }

  // Lowest to highest durability among a stack's copies, "80–120 / 120"
  function duraRange(places) {
    const now = places.map(entry => Number(entry.gear?.dura) || 0);
    const most = places.map(entry => Number(entry.gear?.maxDura) || 0);
    const span = values => {
      const low = Math.min(...values), high = Math.max(...values);
      return low === high ? formatNumber(low) : `${formatNumber(low)}–${formatNumber(high)}`;
    };
    return `${span(now)} / ${span(most)}`;
  }
  // Where a copy is, short: "Bag 10 (p1)", "Bank 205 (shop 5)", "Worn (Head)"
  function shortLocation(entry) {
    if (entry.place === 'worn') return `Worn (${slotLabel(entry.where)})`;
    if (entry.place === 'bank' && entry.slot > SHOP_FROM) return `Bank ${entry.slot} (shop ${entry.slot - SHOP_FROM})`;
    const perPage = PER_PAGE[entry.place];
    if (!perPage || !entry.slot) return `${PLACE[entry.place] || entry.place} ${entry.slot || ''}`.trim();
    return `${PLACE[entry.place]} ${entry.slot} (p${Math.floor((entry.slot - 1) / perPage) + 1})`;
  }
  // A stack of gear, one line for each copy: its durability, name, count, holder and slot, lowest durability first
  function instanceLines(cell) {
    if (!cell.gear || cell.mixed || (cell.places?.length || 0) < 2) return [];
    return [...cell.places].sort((a, b) => (Number(a.gear?.dura) || 0) - (Number(b.gear?.dura) || 0) || a.character.localeCompare(b.character) || a.slot - b.slot)
      .map(entry => ({dura: entry.gear ? `${formatNumber(Number(entry.gear.dura) || 0)}/${formatNumber(Number(entry.gear.maxDura) || 0)}` : '?', high: (Number(entry.gear?.dura) || 0) > HIGH_DURABILITY,
        name: entry.name, count: entry.count, character: entry.character, server: entry.ch?.shownServer || '', key: entry.ch?.key || '', where: shortLocation(entry)}));
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
        const shop = ACCOUNT_MONEY.has(money.key);
        if (!columns.has(money.key)) columns.set(money.key, {key: money.key, name: currencyName(money), total: 0, shop});
      }
      return {name: character.name, key: character.key, server: character.shownServer ?? character.server ?? '', stale: !!character.stale, blank: !!character.notSaved, character, amounts};
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
        saved: String(character.saved || ''), day: Number(character.dailyLogin?.day) || 0, taken: Number.isFinite(taken) ? taken : 0,
        blank: !!character.notSaved};
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
      const inside = column.noSort ? column.head || '' : (column.lead || '') + sortButton(column.key, column.name, column.text) + (column.also || []).map(other => sortButton(other.key, other.name, other.text, true)).join('');
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
    // Accounts in the order their keys nest them, the rest biggest first
    const list = [...groups.values()].sort((a, b) => Number(a.key === '' || a.key === '~none') - Number(b.key === '' || b.key === '~none')
      || (how === 'account' ? (a.key < b.key ? -1 : a.key > b.key ? 1 : 0) : b.rows.length - a.rows.length || a.title.localeCompare(b.title)));
    if (!root.collapsedSet) {
      root.collapsedSet = true;
      if (rows.length > 400) for (const group of list) root.collapsed.add(group.key);
    }
    return list;
  }
  // By account: the linked Gameforge account, its server, then the RoM account, the characters one login screen lists
  const loginScreen = row => row.character?.romAccount || row.character?.group || null;
  const groupKeyOf = (how, accountName) => row => {
    if (how === 'server') return String(row.server || '').toLowerCase();
    const linked = (accountName && accountName(row.name)) || '';
    const list = loginScreen(row);
    if (!linked && !list) return '~none';
    return `${linked ? 'gf:' + linked.toLowerCase() : 'group'}|${String(row.server || '\uffff').toLowerCase()}|${list ? list.names[0].toLowerCase() : '\uffff'}`;
  };
  const groupTitleOf = (how, accountName, romTitle, locked) => row => {
    if (how === 'server') return row.server || NO_SERVER;
    const linked = accountName && accountName(row.name);
    if (!loginScreen(row)) return linked || 'No account known yet';
    const rom = romOf(row.character, romTitle);
    if (linked) return `${linked} › ${rom}`;
    return loginScreen(row).steam ? rom : `${rom}, ${locked && locked() ? 'accounts locked' : 'not linked'}`;
  };
  // The Characters and Currencies searches' filters, each one word: #level>=100, #classes>3, #dailytokens>5k,
  // #charges>10k, #gold<1m, #class=mage and so on, with k, m and b for thousands, millions and billions. A word on its
  // own, such as #charges, means more than none. extra.mailbox(key): its mailbox, for #mail and #mailgold.
  const AMOUNT = /^(\d+(?:\.\d+)?)([kmb]?)$/i;
  const SCALE = {'': 1, k: 1e3, m: 1e6, b: 1e9};
  const ownMoney = key => character => Number((character.currencies || []).find(item => item.key === key)?.amount) || 0;
  const CHARACTER_FILTERS = {
    level: character => Number(character.level) || 0,
    classes: character => (character.classes || []).filter(item => Number(item.level) > 0).length,
    classlevels: character => (character.classes || []).reduce((sum, item) => sum + (Number(item.level) || 0), 0),
    gold: character => Number(character.gold) || 0,
    dailytokens: ownMoney('billdin'),
    charges: ownMoney('transmutor'),
    diamonds: ownMoney('account'),
    rubies: ownMoney('bonus'),
    stones: character => transferStones(character),
    bag: character => (character.bag || []).length,
    bank: character => (character.bank || []).length,
    bagfree: character => Math.max(0, (Number(character.bagSlots) || 0) - (character.bag || []).length),
    bankfree: character => Math.max(0, (Number(character.bankSlots) || 0) - (character.bank || []).length),
    worn: character => (Array.isArray(character.equip) ? character.equip.length : 0),
    mail: (character, extra) => extra?.mailbox?.(character.key)?.count || 0,
    mailgold: (character, extra) => extra?.mailbox?.(character.key)?.gold || 0,
  };
  const FILTER_NAMES = {lvl: 'level', classtotal: 'classes', class_total: 'classes', dailytoken: 'dailytokens', tokens: 'dailytokens', token: 'dailytokens',
    charge: 'charges', transmutor: 'charges', diamond: 'diamonds', ruby: 'rubies', transferstones: 'stones', stone: 'stones', transfer: 'stones', mails: 'mail'};
  // Yes or no, with no number
  const CHARACTER_FLAGS = {needslogin: character => !!character.stale, steam: character => !!character.steam,
    nobank: character => !bankKnown(character), linked: (character, extra, row) => !!row?.account,
    // A character transfer is planned, or it moved and waits for a login on its new server
    xfer: character => !!character.transfer && character.transfer.state !== 'done'};
  const lettersOf = text => String(text || '').toLowerCase().replace(/[^a-zÀ-￿]/g, '');
  function compare(have, how, limit) {
    return how === '>' ? have > limit : how === '<' ? have < limit : how === '>=' || how === '=>' ? have >= limit
      : how === '<=' || how === '=<' ? have <= limit : how === '!=' ? have !== limit : have === limit;
  }
  function characterFilters(text, extra) {
    const tests = [];
    const words = [];
    const all = String(text || '');
    // Only a search with a filter in it is split at its commas and spaces: a note can hold either
    if (!/(^|[\s,])#[a-z]/i.test(all)) return {tests, text: all.trim()};
    for (const word of all.split(/[\s,]+/)) {
      if (!word) continue;
      const found = /^#([a-z_]+)(?:(>=|=>|<=|=<|!=|>|<|=)(.*))?$/i.exec(word);
      if (!found) { words.push(word); continue; }
      const name = FILTER_NAMES[found[1].toLowerCase()] || found[1].toLowerCase();
      const [, , how, value = ''] = found;
      if (CHARACTER_FLAGS[name] && !how) {
        tests.push((character, row) => CHARACTER_FLAGS[name](character, extra, row));
        continue;
      }
      if (name === 'class' && (how === '=' || how === '!=') && value) {
        const wanted = value.toLowerCase();
        const has = character => [character.class, ...(character.classes || []).map(item => item.name)].some(item => String(item || '').toLowerCase().startsWith(wanted));
        tests.push(character => has(character) === (how === '='));
        continue;
      }
      // A number, or any currency by the start of its name: #honor>1000
      const field = CHARACTER_FILTERS[name] || (name.length >= 3 ? character => {
        const money = (character.currencies || []).find(item => lettersOf(currencyName(item)).startsWith(name));
        return Number(money?.amount) || 0;
      } : null);
      const amount = how ? AMOUNT.exec(value) : null;
      if (!field || (how && !amount)) { words.push(word); continue; }
      const limit = amount ? Number(amount[1]) * SCALE[amount[2].toLowerCase()] : 0;
      tests.push(character => compare(field(character, extra), how || '>', limit));
    }
    return {tests, text: words.join(' ')};
  }
  function searchRows(rows, text, extra = null) {
    const filters = characterFilters(text, extra);
    const wanted = filters.text.toLowerCase();
    if (!wanted && !filters.tests.length) return rows;
    return rows.filter(row => filters.tests.every(test => test(row.character || {}, row)) && (!wanted || row.name.toLowerCase().includes(wanted)
      || String(row.server || '').toLowerCase().includes(wanted) || String(row.account || '').toLowerCase().includes(wanted)
      || String(row.rom || '').toLowerCase().includes(wanted) || String(row.class || '').toLowerCase().includes(wanted)
      || String(row.character?.note || '').toLowerCase().includes(wanted)));
  }
  // Diamonds and Rubies belong to an account, and every character on it saved the same balance, so each account counts
  // once, as of the newest save on it. A character no login screen has listed could be on any account: it isn't counted,
  // and says so. Daily Tokens are each character's own. A character saved before currencies were recorded says nothing
  // either way.
  function accountCurrencies(characters) {
    const newest = new Map();
    const recorded = [];
    let loose = 0;
    for (const character of characters) {
      if (character.stale || character.notSaved) continue;
      recorded.push(character);
      const account = character.romAccount || character.group || null;
      if (!account) { loose++; continue; }
      const held = newest.get(account);
      if (!held || String(character.saved || '') > String(held.saved || '')) newest.set(account, character);
    }
    return Object.entries(SHOP_NAMES).map(([key, name]) => {
      const perAccount = ACCOUNT_MONEY.has(key);
      const holders = perAccount ? [...newest.values()] : recorded;
      let total = 0;
      for (const character of holders) total += Number((character.currencies || []).find(money => money.key === key)?.amount) || 0;
      return {key, name, total, perAccount, accounts: newest.size, characters: recorded.length, loose, recorded: holders.length > 0};
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
        money.perAccount ? (money.recorded ? `${formatNumber(money.accounts)} RoM accounts, as last saved` : 'No character on a known RoM account has saved this yet')
          : (money.recorded ? `${formatNumber(money.characters)} characters, as last saved` : 'No character has saved this yet')));
    }
    const loose = shop[0]?.loose || 0;
    parts.push(`<p class="currency-note">Diamonds and Rubies belong to an account, so each RoM account counts once. Daily Tokens are each character's own.${loose ? ` ${formatNumber(loose)} characters aren't on a known RoM account yet, so theirs aren't counted.` : ''}</p>`);
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
    const rows = searchRows(table.rows, options.search, options);
    const groups = tableGroups(root, rows, how, groupKeyOf(how, options.accountName), groupTitleOf(how, options.accountName, options.romTitle, options.locked));
    for (const group of groups) {
      group.totals = {};
      for (const column of table.columns) group.totals[column.key] = column.shop ? null : group.rows.reduce((sum, row) => sum + (row.amounts[column.key] || 0), 0);
      group.sub = counted(group.rows.length, 'character');
    }
    root.selectGroup = key => options.selectKeys && options.selectKeys((groups.find(group => group.key === key)?.rows || []).map(row => row.key));
    const amount = (row, column) => {
      if (row.blank) return '';
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
  // A cell nothing saved can fill: blank on a row only the character transfer page knows
  const unsaved = cell => row => (row.blank ? '' : cell(row));
  // The letter on a coloured square: the class at a glance, and its colour where the page knows it
  const classBadge = (name, color) => `<span class="class-avatar"${color ? ` style="--class-color:${escapeHtml(color)}"` : ''} aria-hidden="true">${escapeHtml(String(name || '?').slice(0, 1).toUpperCase())}</span>`;
  // How many a character can transfer: "at least" what's in the bag while its bank isn't recorded, never a false 0
  function stonesCell(row) {
    const known = row.bankSeen || row.bank > 0;
    if (known) return `<span class="stone-count${row.stones ? '' : ' is-none'}">${escapeHtml(formatNumber(row.stones))}</span>`;
    return row.stones ? `<span class="stone-count is-atleast" title="At least this many: the bank isn't recorded">${escapeHtml(formatNumber(row.stones))}+</span>`
      : '<span class="not-recorded" title="None in the bag, and the bank isn\'t recorded">—</span>';
  }
  // The plate a planned or moved transfer puts on the character's row: "Xfer › Kadmos › Nov 4, 08:12". Its own tooltip
  // counts down to the maintenance, and a click opens the transfer log at it.
  function transferPlate(plate) {
    if (!plate) return '';
    return `<button type="button" class="xfer-plate is-${escapeHtml(plate.kind)}" data-xfer="${escapeHtml(plate.id)}" data-xfer-open aria-label="${escapeHtml(plate.label)}">`
      + `<b>Xfer</b><span class="xfer-sep" aria-hidden="true">\u203a</span>${escapeHtml(plate.to)}<span class="xfer-sep" aria-hidden="true">\u203a</span><span class="xfer-when">${escapeHtml(plate.when)}</span></button>`;
  }
  // Accounts with one character get no heading of their own: their characters share one group, before the characters
  // with no account known, and each one's account is in its hover card.
  const SINGLES = '~single';
  function gatherSingles(groups, rows) {
    const singles = groups.filter(group => group.rows.length === 1 && group.key !== '~none');
    if (singles.length < 2) return groups;
    const rest = groups.filter(group => !singles.includes(group));
    // In the table's own order, not the accounts'
    const alone = new Set(singles.map(group => group.rows[0]));
    const together = {key: SINGLES, title: 'Single-character accounts', rows: rows.filter(row => alone.has(row))};
    const at = rest.findIndex(group => group.key === '~none' || group.key === '');
    rest.splice(at < 0 ? rest.length : at, 0, together);
    return rest;
  }
  function renderRoster(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'gold', descending: true};
    root.collapsed = root.collapsed || new Set();
    root.redraw = () => renderRoster(root, root.last.characters, root.last.options);
    root.last = {characters, options};
    root.openCharacter = options.openCharacter;
    const how = options.how || 'server';
    const rows = searchRows(rosterRows(characters, root.sorting.key, root.sorting.descending, options.accountName, options.romTitle), options.search, options);
    let groups = tableGroups(root, rows, how, groupKeyOf(how, options.accountName), groupTitleOf(how, options.accountName, options.romTitle, options.locked));
    if (how === 'account' && options.singlesTogether) groups = gatherSingles(groups, rows);
    // A heading that names the accounts says them for every line under it
    const showAccounts = how !== 'account';
    if (!showAccounts && (root.sorting.key === 'account' || root.sorting.key === 'rom')) {
      root.sorting = {key: 'gold', descending: true};
      root.redraw();
      return;
    }
    for (const group of groups) {
      const gold = group.rows.reduce((sum, row) => sum + row.gold, 0);
      const caps = group.rows.filter(row => row.gold >= FULL_CAP).length;
      const stale = group.rows.filter(row => row.stale).length;
      const stones = group.rows.reduce((sum, row) => sum + row.stones, 0);
      group.sub = `${counted(group.rows.length, 'character')} · ${formatNumber(gold)} gold` + (caps ? ` · ${counted(caps, 'full cap')}` : '')
        + (stones ? ` · ${counted(stones, 'transfer stone')}` : '') + (stale ? ` · ${formatNumber(stale)} ${stale === 1 ? 'needs' : 'need'} a login` : '');
    }
    root.selectGroup = key => options.selectKeys && options.selectKeys((groups.find(group => group.key === key)?.rows || []).map(row => row.key));
    root.selectAll = () => options.selectKeys && options.selectKeys(rows.map(row => row.key));
    const clock = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    const shortClock = new Intl.DateTimeFormat(undefined, {month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'});
    const slots = (used, max) => escapeHtml(max ? `${formatNumber(used)}/${formatNumber(max)}` : formatNumber(used));
    const allSelected = rows.length > 0 && !!options.isSelected && rows.every(row => options.isSelected(row.key));
    groupedTable(root, {
      columns: [
        {key: 'name', name: 'Character', text: true, lead: `<input type="checkbox" class="select-all head-check" aria-label="Select all shown"${allSelected ? ' checked' : ''}>`,
          cell: row => `<span class="char-cell"><input type="checkbox" class="char-check" aria-label="Select ${escapeHtml(row.name)}"${options.isSelected && options.isSelected(row.key) ? ' checked' : ''}>${classBadge(row.class, options.classColor && options.classColor(row.character))}<span class="char-name">${escapeHtml(row.name)}</span></span>`},
        {key: 'class', name: 'Class', text: true, cell: unsaved(row => (row.class ? escapeHtml(row.class) : '<span class="not-recorded">Not recorded</span>'))},
        {key: 'level', name: 'Level', number: true, cell: unsaved(row => (row.level ? escapeHtml(formatNumber(row.level)) : '<span class="not-recorded">—</span>'))},
        {key: 'server', name: 'Server', text: true, cell: serverCell},
        {key: 'stones', name: 'Transfer stones', number: true, cell: row => transferPlate(options.transfer ? options.transfer(row.character) : null) + (row.blank ? '' : stonesCell(row))},
        ...(showAccounts ? [{key: 'account', name: 'Gameforge', text: true, cell: row => (row.account ? escapeHtml(row.account) : row.blank ? '' : `<span class="not-recorded">${options.locked && options.locked() ? 'Locked' : 'Not linked'}</span>`)},
          {key: 'rom', name: 'RoM account', text: true, cell: row => (row.rom ? escapeHtml(row.rom) : row.blank ? '' : '<span class="not-recorded">Not known</span>')}] : []),
        {key: 'gold', name: 'Gold', number: true, cell: unsaved(row => `<span class="gold-cell">${escapeHtml(formatNumber(row.gold))}</span>`)},
        {key: 'bag', name: 'Bag', number: true, cell: unsaved(row => slots(row.bag, row.character?.bagSlots))},
        {key: 'bank', name: 'Bank', number: true, cell: unsaved(row => (row.bankSeen || row.bank > 0 ? slots(row.bank, row.character?.bankSlots) : '<span class="not-recorded" title="Bank not recorded: one login with this character records it">Not recorded</span>'))},
        {key: 'saved', name: 'Last saved', text: true, cell: unsaved(row => escapeHtml(row.saved || 'Not recorded'))},
        {key: 'day', name: 'Reward day', number: true, also: [{key: 'taken', name: 'Taken'}],
          cell: unsaved(row => (row.taken ? `<span title="${escapeHtml(clock.format(row.taken))}">Day ${escapeHtml(row.day || '?')} <span class="muted">· ${escapeHtml(shortClock.format(row.taken))}</span></span>` : '<span class="not-recorded">Not recorded</span>'))},
        {key: 'stale', name: 'Status', cell: row => (options.transfer && options.transfer(row.character)?.confirm
          ? `<span class="status-pill is-xfer" title="${escapeHtml(`It moved to ${row.character.transfer.to}: one login with it there confirms the transfer and saves it on its new server`)}">Log in to confirm transfer</span>`
          : row.blank ? '' : row.stale ? '<span class="status-pill" title="Saved by an older version: log in once on the current one">Needs login</span>' : '<span class="status-pill is-good" role="img" aria-label="Current" title="Current"></span>')},
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
  // The template a stat is shown on: a tier 6 mana stone, as the game lists one, in its own colours
  const TEMPLATE_STONE = '202845';
  const EFFECT_LINE = /^[+-]\s*\d/;
  const STAT_EXCLUSIONS = 'excludedStats';
  const savedColor = value => /^[0-9a-f]{6}$/i.test(value || '') ? String(value).toLowerCase() : '';
  // What each stat does, from the game's own saved tooltips: a stat's name stands beside the first of its effects, and
  // the rest follow on the lines below. The way most items show a stat wins, a mana stone's counting double.
  // Keep each effect's saved colour as well as its text; green/yellow stats must not become orange.
  // Gear above 100 durability (HD) shows its stats raised, up to +20% at 120, and the Stats page always shows a
  // stat's own value. Such a tooltip's numbers are divided back by its durability (current, else maximum) when that
  // gives the whole numbers stats have, and it counts for little, so an ordinary item's way of showing the stat wins.
  const EFFECT_NUMBER = /^([+-]\s*)(\d+(?:\.\d+)?)/;
  function boostOf(gear, lines) {
    const numbers = lines.map(([, text]) => Number(EFFECT_NUMBER.exec(text)?.[2])).filter(value => value > 0);
    for (const dura of [Number(gear?.dura) || 0, Number(gear?.maxDura) || 0]) {
      if (dura <= 100 || dura > 120 || !numbers.length) continue;
      const scale = dura / 100;
      if (numbers.every(value => Math.abs(value / scale - Math.round(value / scale)) < 0.051)) return scale;
    }
    return 1;
  }
  const unboosted = (text, scale) => scale === 1 ? text : text.replace(EFFECT_NUMBER, (all, sign, number) => sign + String(Math.round(Number(number) / scale)));
  function statEffects(list) {
    const seen = new Map();
    let header = null;
    const tally = (stat, lines, weight) => {
      if (!seen.has(stat)) seen.set(stat, new Map());
      const ways = seen.get(stat);
      const key = JSON.stringify(lines);
      ways.set(key, (ways.get(key) || 0) + weight);
    };
    for (const entry of list || []) {
      if (!Array.isArray(entry.tip)) continue;
      if (!header && String(entry.id) === TEMPLATE_STONE && entry.tip.length >= 2) header = entry.tip.slice(0, 2).map(line => String(line[1] || ''));
      if (!entry.stats?.length) continue;
      const names = new Set(entry.stats);
      const high = (Number(entry.gear?.dura) || 0) > 100 || (Number(entry.gear?.maxDura) || 0) > 100;
      let current = null, lines = [];
      const finish = () => {
        if (current && lines.length) {
          const scale = high ? boostOf(entry.gear, lines) : 1;
          tally(current, lines.map(([color, text]) => [color, unboosted(text, scale)]), high ? 0.01 : entry.stone ? 2 : 1);
        }
        current = null;
        lines = [];
      };
      for (const line of entry.tip) {
        const left = String(line[1] || ''), right = String(line[3] || '');
        if (right && names.has(right) && EFFECT_LINE.test(left)) {
          finish();
          current = right;
          lines = [[savedColor(line[0]), left]];
        } else if (current && !right && EFFECT_LINE.test(left)) lines.push([savedColor(line[0]), left]);
        else finish();
      }
      finish();
    }
    const effects = new Map(), colors = new Map();
    for (const [stat, ways] of seen) {
      const lines = JSON.parse([...ways.entries()].sort((a, b) => b[1] - a[1])[0][0]);
      effects.set(stat, lines.map(line => line[1]));
      colors.set(stat, lines.map(line => line[0]));
    }
    return {effects, colors, header: header || ['Mana Stone Tier 6', 'Cannot be sold']};
  }
  // The stat on a tier 6 mana stone, as lines for the page's game tooltip: [colour, left, colour, right]
  function templateTip(stat, known) {
    const lines = known.effects.get(stat);
    if (!lines) return null;
    const colors = known.colors?.get(stat) || [];
    const nameColor = colors.find(color => savedColor(color)) || '';
    return [['ffffff', known.header[0]], ['ffffff', known.header[1]],
      ...lines.map((text, at) => (at === 0 ? [colors[at] || '', text, nameColor, stat] : [colors[at] || '', text]))];
  }
  function statNameCell(stat, known) {
    const lines = templateTip(stat, known)?.slice(2) || [];
    const color = lines[0]?.[0] || '';
    const style = color ? ` style="color:#${color}"` : '';
    const effects = lines.map(line => `<span${line[0] ? ` style="color:#${line[0]}"` : ''}>${escapeHtml(line[1])}</span>`).join('<span aria-hidden="true"> · </span>');
    return `<span class="stat-entry" data-stat="${escapeHtml(stat)}" tabindex="0"><span class="stat-name"${style}>${escapeHtml(stat)}</span>${effects ? `<span class="stat-effects">${effects}</span>` : ''}</span>`;
  }
  function excludedStatNames(value) {
    return new Set((Array.isArray(value) ? value : []).filter(name => typeof name === 'string' && name.length > 0 && name.length <= 200 && !/[\x00-\x1f]/.test(name)).slice(0, 2000));
  }
  async function changeStatExclusions(root, names, message) {
    const status = root.querySelector('#stat-status');
    if (!root.exclusionsReady) { status.textContent = root.exclusionError || 'Excluded stats are still loading. Try again in a moment.'; return; }
    root.excludedStats = excludedStatNames(names);
    root.redraw();
    status.textContent = message;
    try {
      if (root.options.storage?.set) await root.options.storage.set({[STAT_EXCLUSIONS]: [...root.excludedStats]});
    } catch {
      status.textContent = `${message} This change could not be saved in Chrome and only applies to this open page.`;
    }
  }
  function renderStatExclusions(root) {
    const list = root.querySelector('#stat-excluded-list');
    const names = [...root.excludedStats].sort((a, b) => a.localeCompare(b));
    root.querySelector('#stat-excluded-title').textContent = `Excluded stats (${formatNumber(names.length)})`;
    root.querySelector('#stat-excluded-empty').hidden = names.length > 0;
    root.querySelector('#stat-restore-all').hidden = names.length === 0;
    list.replaceChildren();
    for (const name of names) {
      const row = document.createElement('li');
      const label = document.createElement('span');
      label.textContent = name;
      const color = root.known.colors.get(name)?.find(color => savedColor(color));
      if (color) label.style.color = `#${color}`;
      const restore = document.createElement('button');
      restore.type = 'button';
      restore.className = 'gb-button--sm';
      restore.textContent = 'Restore';
      restore.setAttribute('aria-label', `Restore ${name}`);
      restore.addEventListener('click', () => changeStatExclusions(root, names.filter(stat => stat !== name), `Restored ${name}.`));
      row.append(label, restore);
      list.append(row);
    }
  }
  // A stat's name, hovered: the stat as the game shows it on a tier 6 mana stone
  function showStatTip(tooltip, event, stat, known) {
    const make = (tag, className, text) => {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    };
    const lines = tipLines(templateTip(stat, known));
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
      nodes.push(game, make('span', 'bank-tip-hint', 'As it shows on a tier 6 mana stone, from the game’s own tooltips.'));
    } else {
      nodes.push(make('strong', '', stat), make('span', 'bank-tip-type', 'What it does isn’t known yet: it comes from the game’s tooltip of an item that has it, which one login with its holder on the current version saves.'));
    }
    tooltip.replaceChildren(...nodes);
    tooltip.hidden = false;
    tooltip.style.left = Math.max(4, Math.min(event.clientX + 14, window.innerWidth - tooltip.offsetWidth - 8)) + 'px';
    tooltip.style.top = Math.max(4, Math.min(event.clientY + 14, window.innerHeight - tooltip.offsetHeight - 8)) + 'px';
  }
  // options: {data: {entries}} from the Bank tab, so the stats count the same characters it shows; all: every entry,
  // whose tooltips say what each stat does; tooltip: the element hovering a stat shows it in;
  // classColor: the character tooltip's colour resolver; menu: the page's context menu; storage: local preferences.
  function renderStats(root, characters, options = {}) {
    root.sorting = root.sorting || {key: 'total', descending: true};
    root.collapsed = root.collapsed || new Set();
    if (!root.listening) {
      root.listening = true;
      root.excludedStats = new Set();
      root.exclusionsReady = !options.storage?.get;
      if (!root.exclusionsReady) {
        const loadExclusions = async () => {
          try {
            const stored = await options.storage.get(STAT_EXCLUSIONS);
            root.excludedStats = excludedStatNames(stored?.[STAT_EXCLUSIONS]);
            root.exclusionsReady = true;
            root.redraw();
          } catch {
            root.exclusionError = 'Could not read your excluded stats from Chrome. Reload this page to try again.';
            root.querySelector('#stat-status').textContent = root.exclusionError;
          }
        };
        loadExclusions();
      }
      for (const id of ['stat-search', 'stat-kind']) root.querySelector('#' + id).addEventListener('input', () => renderStats(root, root.characters, root.options));
      root.querySelector('#stat-restore-all').addEventListener('click', () => changeStatExclusions(root, [], 'Restored all excluded stats.'));
      const table = root.querySelector('table');
      const statMenu = event => {
        const cell = event.target?.closest?.('[data-stat]');
        if (!cell || !root.options?.menu) return;
        event.preventDefault();
        event.stopPropagation();
        if (root.options.tooltip) root.options.tooltip.hidden = true;
        const rect = cell.getBoundingClientRect();
        const position = {preventDefault: () => event.preventDefault(), clientX: Number.isFinite(event.clientX) ? event.clientX : rect.left,
          clientY: Number.isFinite(event.clientY) ? event.clientY : rect.bottom};
        root.options.menu(position, [{label: 'Exclude this stat from showing', run: () => changeStatExclusions(root,
          [...root.excludedStats, cell.dataset.stat], `Excluded ${cell.dataset.stat}. Restore it under Excluded stats.`)}], []);
      };
      table.addEventListener('contextmenu', statMenu);
      table.addEventListener('keydown', event => { if (event.key === 'ContextMenu' || (event.key === 'F10' && event.shiftKey)) statMenu(event); });
      let hovered = null;
      table.addEventListener('mouseover', event => {
        const cell = event.target?.closest?.('[data-stat]');
        const tooltip = root.options?.tooltip;
        if (!tooltip) return;
        if (!cell) { if (hovered) { hovered = null; tooltip.hidden = true; } return; }
        if (cell === hovered) return;
        hovered = cell;
        showStatTip(tooltip, event, cell.dataset.stat, root.known);
      });
      table.addEventListener('mousemove', event => {
        const tooltip = root.options?.tooltip;
        if (!hovered || !tooltip || tooltip.hidden) return;
        tooltip.style.left = Math.max(4, Math.min(event.clientX + 14, window.innerWidth - tooltip.offsetWidth - 8)) + 'px';
        tooltip.style.top = Math.max(4, Math.min(event.clientY + 14, window.innerHeight - tooltip.offsetHeight - 8)) + 'px';
      }, {passive: true});
      table.addEventListener('mouseleave', () => { hovered = null; if (root.options?.tooltip) root.options.tooltip.hidden = true; });
    }
    root.characters = characters;
    root.options = options;
    // Worked out again only when the data is new
    const tips = options.all || options.data?.entries || [];
    if (!root.known || root.knownFrom !== tips) {
      root.knownFrom = tips;
      root.known = statEffects(tips);
    }
    root.redraw = () => renderStats(root, root.characters, root.options);
    const rows = statTable(options.data || characters, root.querySelector('#stat-kind').value, root.querySelector('#stat-search').value.trim(), root.sorting.key, root.sorting.descending)
      .filter(row => !root.excludedStats.has(row.stat));
    const ownerCharacters = new Map();
    for (const character of [...characters, ...tips.map(entry => entry.ch).filter(Boolean)]) {
      if (character.key) ownerCharacters.set(character.key, character);
      ownerCharacters.set(character.name, character);
    }
    const ownerCell = owner => {
      const character = ownerCharacters.get(owner.key || owner.name);
      const color = character && options.classColor?.(character);
      const style = /^#[0-9a-f]{6}$/i.test(color || '') ? ` style="color:${color}"` : '';
      return `<span class="owner"${style} ${owner.key ? `data-char="${escapeHtml(owner.key)}"` : ''}>${escapeHtml(owner.name)} ${escapeHtml(formatNumber(owner.count))}</span>`;
    };
    const owners = row => row.owners.slice(0, 12).map(ownerCell).join(', ')
      + (row.owners.length > 12 ? ` <span class="hint">and ${formatNumber(row.owners.length - 12)} more</span>` : '');
    groupedTable(root, {
      columns: [...STAT_COLUMNS.map(column => ({...column, number: !column.text,
        cell: row => (column.text ? statNameCell(row.stat, root.known) : escapeHtml(formatNumber(row[column.key])))})),
        {key: 'breakdown', name: 'Who has them', text: true, cell: owners}],
      groups: [{key: '', title: null, sub: '', rows}],
      empty: root.excludedStats.size ? 'No matching stats are shown. Check the filters or restore stats under Excluded stats.'
        : 'No matching stats. Check the filters, or log in and out with Global Bank enabled to save them.',
    });
    renderStatExclusions(root);
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
    const state = {characters: [], raw: [], entries: [], made: null, total: -1, sort: 'name', byType: false, cells: [], names: new Map(), loadedAt: 0, layout: 'grid', active: -1};
    // The items someone keeps in the item shop tab, worked out once for each load
    let shopKnown = null;
    function shopIds() {
      if (!shopKnown || shopKnown.entries !== state.entries) shopKnown = {entries: state.entries, ids: new Set(state.entries.filter(entry => entry.shop).map(entry => String(entry.id)))};
      return shopKnown.ids;
    }
    const settings = {excluded: new Set(), whitelist: new Set(), excludeBound: false};
    const rules = {on: true, types: new Set(DEFAULT_RULES.types), stats: DEFAULT_RULES.stats, always: new Set(), favourites: new Map(), quality: true};
    const icons = new Map();
    const requested = new Set();
    const el = id => root.querySelector('#' + id);
    const tooltip = options.tooltip || el('bank-tooltip');
    const grid = el('bank-grid');
    const hasDom = typeof window !== 'undefined' && !!grid?.appendChild;
    const storage = typeof chrome !== 'undefined' && chrome.storage ? chrome.storage.local : null;
    let columns = 1, rows = 0, frame = 0, space = null, typingTimer = 0, gridDirty = false, gridFrame = 0, loading = null, panelCell = null;
    // The lowest tier a slot's corner shows, kept in this Chrome
    let tierFrom = TIER_FROM;
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
      const copies = instanceLines(cell);
      if (copies.length) {
        // Stacked gear: each copy on its own line, so a worn-down one is easy to find
        const table = make('div', 'bank-tip-copies');
        for (const copy of copies.slice(0, MAX_COPIES)) {
          table.append(make('span', 'bank-tip-dura' + (copy.high ? ' is-high' : ''), copy.dura), make('span', 'bank-tip-copy-name', copy.name),
            make('span', 'bank-tip-copy-count', `×${formatNumber(copy.count)}`), make('b', '', copy.character + (servers.size > 1 && copy.server && !copy.character.endsWith(`(${copy.server})`) ? ` ${copy.server}` : '')),
            make('span', 'bank-tip-copy-where', copy.where));
        }
        nodes.push(table);
        if (copies.length > MAX_COPIES) nodes.push(make('span', 'bank-tip-type', `and ${formatNumber(copies.length - MAX_COPIES)} more`));
      } else {
        for (const row of who.slice(0, MAX_HOLDERS)) {
          const line = make('span', 'bank-tip-row');
          line.append(make('b', '', row.name));
          if (servers.size > 1 && row.server && !row.name.endsWith(`(${row.server})`)) line.append(make('i', '', ` ${row.server}`));
          line.append(` ${row.parts.join(' · ')}`);
          nodes.push(line);
        }
        if (who.length > MAX_HOLDERS) nodes.push(make('span', 'bank-tip-type', `and ${formatNumber(who.length - MAX_HOLDERS)} more characters`));
      }
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
      slot.tierMark = make('span', 'bank-mark bank-mark-tier');
      slot.durabilityMark = make('span', 'bank-mark bank-mark-hd');
      slot.plusMark = make('span', 'bank-mark bank-mark-plus');
      slot.star = make('span', 'bank-star', '★');
      // Only the list shows these
      slot.nameText = make('span', 'bank-slot-text is-name');
      slot.whereText = make('span', 'bank-slot-text is-where');
      slot.quantityText = make('span', 'bank-slot-text is-quantity');
      slot.append(slot.letters, slot.picture, slot.count, slot.tierMark, slot.durabilityMark, slot.plusMark, slot.star, slot.nameText, slot.whereText, slot.quantityText);
      grid.append(slot);
      return slot;
    }
    // Tier upper left, HD upper right, plus lower left. A stack of different kinds has no one answer, so it shows none.
    function fillMarks(slot, cell) {
      const marks = slotMarks(cell, tierFrom);
      slot.tierMark.textContent = marks.tier;
      slot.durabilityMark.textContent = marks.durability;
      slot.plusMark.textContent = marks.plus;
    }
    function fill(slot, cell, index) {
      slot.dataset.index = String(index);
      const excluded = isHidden(cell.places[0], settings);
      const favourite = rules.favourites.has(cell.key);
      slot.className = 'bank-slot filled' + (excluded ? ' bank-excluded' : '') + (rules.quality && cell.quality ? ` q${cell.quality}` : '') + (favourite ? ' is-favourite' : '')
        + (index === state.active ? ' is-active' : '') + (sameCell(panelCell, cell) ? ' is-open' : '');
      slot.setAttribute('aria-label', [`${cell.name}, ${formatNumber(cell.total)}`, ...slotMarks(cell, tierFrom).words].join(', '));
      slot.setAttribute('aria-selected', String(index === state.active));
      slot.letters.textContent = cell.name.slice(0, 2);
      if (shape().rows) {
        const who = new Set(cell.places.map(place => place.ch?.key || place.character));
        slot.nameText.replaceChildren(cell.name, make('small', '', [state.byType && cell.group ? [cell.group, cell.part].filter(Boolean).join(': ') : cell.type, cell.quality ? QUALITY[cell.quality] : ''].filter(Boolean).join(' · ')));
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
      slot.count.textContent = cell.total > 1 ? (cell.total > 9999 ? `${Math.floor(cell.total / 1000)}k` : String(cell.total)) : '';
      fillMarks(slot, cell);
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
      const order = SORTS[state.sort] || SORTS.name;
      state.cells = state.byType ? sortByType(cells(list, currentRules()), order, shopIds()) : cells(list, currentRules()).sort(order);
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
      el('coverage-login-text').textContent = stale === 1 ? '1 character needs a login on the current version' : `${formatNumber(stale)} characters need a login on the current version`;
      el('coverage-bank-text').textContent = unseen === 1 ? '1 bank not recorded: log in once with that character' : `${formatNumber(unseen)} banks not recorded: log in once with each`;
      // Mail waiting to be collected, and the gold in it: as each mailbox was when last open, with the mail sent since
      const boxes = options.mailboxes ? options.mailboxes() : null;
      const mail = boxes && typeof GBMail !== 'undefined' ? GBMail.totals(boxes, shown) : null;
      el('coverage-mail').hidden = !mail?.mails;
      el('coverage-mail-gold').hidden = !mail?.gold;
      if (mail?.mails) {
        el('coverage-mail-text').textContent = `${counted(mail.mails, 'mail')} waiting in ${formatNumber(mail.characters)} ${mail.characters === 1 ? 'mailbox' : 'mailboxes'}`
          + (mail.expiring ? ` · ${formatNumber(mail.expiring)} ${mail.expiring === 1 ? 'expires' : 'expire'} within 48 hours` : '');
        el('coverage-mail').classList.toggle('is-urgent', mail.expiring > 0);
        el('coverage-mail-gold-text').textContent = `${mail.estimated ? 'About ' : ''}${formatCompact(mail.gold)} gold waiting in mailboxes`;
        el('coverage-mail-gold-text').title = `${formatNumber(mail.gold)} gold` + (mail.estimated ? `, counting ${counted(mail.estimated, 'mail')} sent since the mailbox was last open` : ', as each mailbox was when last open');
      }
      el('bank-coverage').hidden = !stale && !unseen && !mail?.mails;
      renderServerPick();
    }
    // The server to show, picked in two clicks: all of them, a region's, or one server. It sets the same view as the
    // region and the server ticks at the top, so every page follows it.
    function renderServerPick() {
      const label = el('bank-server-label');
      if (!label || !roster || typeof GBRoster === 'undefined') return;
      const view = roster.view;
      const servers = GBRoster.serverList(roster.characters(), {...view, region: 'all', serversOff: new Set()}).filter(server => server.count > 0);
      const inView = servers.filter(server => (view.region === 'all' || !server.region || server.region === view.region) && !view.serversOff.has(server.key));
      const regionName = id => GBRoster.REGIONS[id]?.name || 'Other servers';
      label.textContent = inView.length === servers.length ? 'All' : inView.length === 1 ? inView[0].name
        : !view.serversOff.size && view.region !== 'all' ? regionName(view.region) : `${formatNumber(inView.length)} servers`;
      const list = el('bank-server-list');
      if (!list || !el('bank-server-pick')?.open) return;
      const pressed = on => ` aria-pressed="${on}"`;
      const parts = [`<button type="button" class="server-pick-all" data-pick-region="all"${pressed(inView.length === servers.length)}>All servers <span class="hint">${formatNumber(servers.reduce((sum, server) => sum + server.count, 0))}</span></button>`];
      for (const id of [...Object.keys(GBRoster.REGIONS), '']) {
        const members = servers.filter(server => (server.region || '') === id);
        if (!members.length) continue;
        const whole = id && view.region === id && !view.serversOff.size;
        parts.push(id ? `<button type="button" class="server-pick-region" data-pick-region="${escapeHtml(id)}"${pressed(!!whole)}>${escapeHtml(regionName(id))}</button>`
          : `<span class="server-pick-region">${escapeHtml(regionName(id))}</span>`);
        for (const server of members) {
          const only = inView.length === 1 && inView[0].key === server.key;
          parts.push(`<button type="button" class="server-pick-server" data-pick-server="${escapeHtml(server.key)}" data-pick-in="${escapeHtml(server.region || 'all')}"${pressed(only)}>`
            + `${escapeHtml(server.name)} <span class="hint">${formatNumber(server.count)}</span></button>`);
        }
      }
      list.innerHTML = parts.join('');
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
          bankRules: {version: 2, types: [...rules.types], stats: rules.stats, always: [...rules.always], quality: rules.quality,
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
      if (summary) summary.textContent = el('bank-stack').checked === false ? 'Stacking: off' : `Stacking: ${rules.types.size === TYPES.length ? 'all types' : `${rules.types.size} of ${TYPES.length} types`}` + (rules.always.size ? `, ${rules.always.size} always` : '');
      root.querySelectorAll?.('[data-stack-type]')?.forEach(box => { box.checked = rules.types.has(box.dataset.stackType); });
      if (el('bank-stack-stats')) el('bank-stack-stats').value = rules.stats;
      const identical = el('bank-stack-identical');
      if (identical) {
        identical.checked = rules.stats !== 'apart';
        identical.disabled = el('bank-stack').checked === false;
      }
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
      slot.tierMark = make('span', 'bank-mark bank-mark-tier');
      slot.durabilityMark = make('span', 'bank-mark bank-mark-hd');
      slot.plusMark = make('span', 'bank-mark bank-mark-plus');
      slot.append(slot.tierMark, slot.durabilityMark, slot.plusMark);
      fillMarks(slot, cell);
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
      const copies = instanceLines(cell);
      if (copies.length) {
        nodes.push(make('div', 'detail-title', 'Each copy'));
        const table = make('div', 'bank-tip-copies');
        for (const copy of copies.slice(0, 200)) {
          table.append(make('span', 'bank-tip-dura' + (copy.high ? ' is-high' : ''), copy.dura), make('span', 'bank-tip-copy-name', copy.name),
            make('span', 'bank-tip-copy-count', `×${formatNumber(copy.count)}`), make('b', '', copy.character), make('span', 'bank-tip-copy-where', copy.where));
        }
        nodes.push(table);
        if (copies.length > 200) nodes.push(make('span', 'hint', `and ${formatNumber(copies.length - 200)} more`));
      }
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
        let json = '', total = 0, again = false, first = null;
        for (;;) {
          const response = await send({type: 'bank-data', offset: json.length});
          const part = response.json || '';
          if (first === null) first = part;
          if (json && response.total && total && response.total !== total) { again = true; break; }
          total = response.total || total;
          json += part;
          // The stamp only has minutes, so two saves in one minute look alike: the first part itself has to match.
          if (ifChanged && json.length === part.length && total && total === state.total && part === state.firstPart) return null;
          if (!part || !total || json.length >= total) break;
        }
        if (!again) {
          try {
            return {data: json ? JSON.parse(json) : {characters: []}, total: total || json.length, first};
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
      state.firstPart = fetched.first;
      apply(Array.isArray(data.characters) ? data.characters : [], data.made || null);
      return true;
    }
    // Who is who, then everything drawn from it. Also run again on the same characters when a server set by hand
    // changes where some of them are.
    function apply(list, made) {
      // Everything as loaded, for running this again; then what the page shows of it (character transfers move some)
      state.raw = list;
      if (options.adjust) list = options.adjust(list) || list;
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
    // The order, and whether each type keeps together, kept in this Chrome
    const keepSort = () => { if (storage) storage.set({bankSort: {by: state.sort, type: state.byType}}).catch(() => {}); };
    el('bank-sort').addEventListener('change', event => { state.sort = event.target.value; keepSort(); renderGrid(true); });
    el('bank-sort-type')?.addEventListener('change', event => { state.byType = event.target.checked; keepSort(); renderGrid(true); });
    el('bank-update').addEventListener('click', update);
    el('bank-exclude-bound').addEventListener('change', event => { settings.excludeBound = event.target.checked; settingsChanged(); });
    el('bank-exclusion-add').addEventListener('click', () => addFromBox(settings.excluded, settings.whitelist));
    el('bank-whitelist-add').addEventListener('click', () => addFromBox(settings.whitelist, settings.excluded));
    el('bank-stack-stats')?.addEventListener('change', event => { rules.stats = event.target.value; settingsChanged(); });
    el('bank-stack-identical')?.addEventListener('change', event => { rules.stats = event.target.checked ? 'match' : 'apart'; settingsChanged(); });
    // The corner marks' colours, kept in this Chrome
    let markColors = {...MARK_COLORS};
    const markInputs = () => [...(root.querySelectorAll?.('[data-mark-color]') || [])];
    function showMarkColors() {
      for (const input of markInputs()) input.value = markColors[input.dataset.markColor];
      if (hasDom) for (const [name, color] of Object.entries(markColors)) document.documentElement.style.setProperty(`--mark-${name}`, color);
      const reset = el('bank-marks-reset');
      if (reset) reset.hidden = Object.keys(MARK_COLORS).every(name => markColors[name] === MARK_COLORS[name]);
    }
    for (const input of markInputs()) {
      input.addEventListener('input', () => {
        markColors[input.dataset.markColor] = input.value.toLowerCase();
        showMarkColors();
      });
      input.addEventListener('change', () => { if (storage) storage.set({bankMarkColors: markColors}).catch(() => {}); });
    }
    el('bank-marks-reset')?.addEventListener('click', () => {
      markColors = {...MARK_COLORS};
      showMarkColors();
      if (storage) storage.remove('bankMarkColors').catch(() => {});
    });
    el('bank-quality-borders')?.addEventListener('change', event => { rules.quality = event.target.checked; settingsChanged(); });
    root.querySelectorAll?.('[data-stack-type]')?.forEach(box => box.addEventListener('change', () => {
      if (box.checked) rules.types.add(box.dataset.stackType);
      else rules.types.delete(box.dataset.stackType);
      settingsChanged();
    }));
    el('bank-reset-filters').addEventListener('click', resetFilters);
    el('coverage-login-review').addEventListener('click', () => options.review?.('login'));
    el('coverage-bank-review').addEventListener('click', () => options.review?.('bank'));
    el('coverage-mail-review')?.addEventListener('click', () => options.review?.('mail'));
    el('coverage-mail-gold-review')?.addEventListener('click', () => options.review?.('mail'));
    el('bank-server-pick')?.addEventListener('toggle', renderServerPick);
    el('bank-server-list')?.addEventListener('click', event => {
      const button = event.target?.closest?.('[data-pick-region], [data-pick-server]');
      if (!button || !roster?.setView) return;
      if (button.dataset.pickServer !== undefined) roster.setView(button.dataset.pickIn, [button.dataset.pickServer]);
      else roster.setView(button.dataset.pickRegion);
      el('bank-server-pick').open = false;
    });
    // The lowest tier a corner shows
    el('bank-tier-from')?.addEventListener('change', event => {
      tierFrom = Number(event.target.value) || TIER_FROM;
      repaint();
      if (panelCell) drawPanel();
      if (storage) storage.set({bankTierFrom: tierFrom}).catch(() => {});
    });
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
      storage.get(['bankExclusions', 'bankRules', 'bankLayout', 'bankMarkColors', 'bankTierFrom', 'bankSort']).then(({bankExclusions: saved, bankRules: kept, bankLayout, bankMarkColors, bankTierFrom, bankSort}) => {
        setLayout(bankLayout || 'grid', false);
        if (bankSort && SORTS[bankSort.by]) {
          state.sort = bankSort.by;
          state.byType = bankSort.type === true;
          if (el('bank-sort')) el('bank-sort').value = state.sort;
          if (el('bank-sort-type')) el('bank-sort-type').checked = state.byType;
        }
        if (Number.isInteger(bankTierFrom) && bankTierFrom >= 1 && bankTierFrom <= 30) {
          tierFrom = bankTierFrom;
          if (el('bank-tier-from')) el('bank-tier-from').value = String(tierFrom);
        }
        if (bankMarkColors) {
          for (const name of Object.keys(MARK_COLORS)) if (/^#[0-9a-f]{6}$/i.test(bankMarkColors[name] || '')) markColors[name] = bankMarkColors[name];
          showMarkColors();
        }
        if (saved) {
          settings.excluded = new Set(saved.excluded || []);
          settings.whitelist = new Set(saved.whitelist || []);
          settings.excludeBound = !!saved.excludeBound;
        }
        if (kept) {
          // Saved before identical items stacked by default, these were the old defaults, so they start over once
          if (kept.version >= 2) {
            if (Array.isArray(kept.types)) rules.types = new Set(kept.types.filter(type => TYPES.includes(type)));
            if (['apart', 'match', 'all'].includes(kept.stats)) rules.stats = kept.stats;
          }
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
      reload, update, renderGrid, renderFavourites, closePanel, resetFilters,
      tierFrom: () => tierFrom,
      // A search on the Bank page, from elsewhere: an item's name, shown at once
      find(text) {
        el('bank-search').value = String(text || '');
        el('bank-search-in').value = '';
        renderGrid(true);
      },
      // The same characters prepared again: a server set by hand moves them
      reprepare() { if (state.raw.length) apply(state.raw, state.made); },
      // The Bank tab was opened: draw what changed while it was hidden
      show() { if (gridDirty) renderGrid(); else if (hasDom) { layout(); repaint(); } },
      entries: () => state.entries,
      characters: () => state.characters,
      // As loaded, before the page moved any of them
      raw: () => state.raw,
      shownEntries() {
        const test = matcher({keep: keep(false)});
        return state.entries.filter(test);
      },
      loadedAt: () => state.loadedAt,
    };
  }
  return {create, tellApart, typeOf, qualityOf, QUALITY, TYPES, locationLabel, entries, applyFilters, matcher, cells, stackKey, statsSignature, instanceLines, duraRange, DEFAULT_RULES,
    quickFilters, wornGear, plusOf, slotLabel, SLOT_LABELS, TIER_FROM, statEffects, templateTip, SORT_GROUPS, sortGroupOf, sortByType, SORTS,
    formatDuration, totals, isHidden, toggleHidden, stackable, gearLines, tipLines, itemLines, holders, currencyTable, currencyName, renderCurrencies, accountCurrencies,
    rosterRows, renderRoster, transferPlate, statTable, renderStats, searchRows, characterFilters, favouriteRows, groupedTable, escapeHtml, formatNumber, formatCompact, formatTiny, counted, tierOf, slotMarks, isStone, MARK_COLORS, transferStones, transferStonesText, bankKnown};
})();
