'use strict';
// The Bank tab: everything every character holds, in one scrolling grid with a search and filters.
const GBBank = (() => {
  // The game's own pages: 30 bag slots, 40 bank slots.
  const PER_PAGE = {bag: 30, bank: 40};
  const PLACE = {bag: 'Bag', bank: 'Bank'};
  const MAX_TOOLTIP_ROWS = 12;
  const EQUIPPABLE = new Set(['Weapons', 'Armour', 'Jewellery']);
  // Bought with real money and shared by an account, so adding them up across characters would count them twice.
  const SHOP_NAMES = {account: 'Diamonds', bonus: 'Bonus', billdin: 'Billdin'};
  const FIXED_NAMES = {transmutor: 'Arcane Transmutor Charges'};
  // The order of the game's own currency window
  const CURRENCY_ORDER = ['transmutor', '11', '12', '10', '17', '21', '9', '13', '15', '16', '4', '8', '14', '18', '19', '22', '23', 'account', 'bonus', 'billdin'];

  function formatNumber(value) {
    return Number(value || 0).toLocaleString('en-US');
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
    if (/potion/.test(path)) return 'Potions';
    if (/mana stone|fusnion_stone|item_ore|item_mat|phantom\/material/.test(path)) return 'Materials';
    if (/mount|charger|pet_|egg/.test(path)) return 'Mounts and pets';
    return 'Other';
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
    const list = entries(characters);
    return {characters: characters.length, stacks: list.length, items: list.reduce((sum, entry) => sum + entry.count, 0)};
  }
  // Bank 45 (page 2, slot 5)
  function locationLabel(place, slot) {
    const perPage = PER_PAGE[place];
    const page = Math.floor((slot - 1) / perPage) + 1;
    return `${PLACE[place]} ${slot} (page ${page}, slot ${slot - (page - 1) * perPage})`;
  }
  // One row for each stack on each character
  function entries(characters) {
    const list = [];
    for (const character of characters) {
      for (const place of ['bag', 'bank']) {
        for (const item of character[place] || []) {
          list.push({id: item.id, name: String(item.name || 'Unknown item'), icon: item.icon, count: Number(item.count) || 1,
            type: typeOf(item.id, item.icon), bound: !!item.bound, gear: item.gear || null, stats: item.gear?.stats || item.stats || [], stone: !!item.stats, character: character.name, level: Number(character.level) || 0, place, slot: Number(item.slot) || 0});
        }
      }
    }
    return list;
  }
  function applyFilters(list, filters) {
    const text = (filters.text || '').toLowerCase();
    const has = names => names.some(name => name.toLowerCase().includes(text));
    const searched = entry => {
      if (filters.searchIn === 'items') return !entry.stone && has(entry.stats);
      if (filters.searchIn === 'stones') return entry.stone && has(entry.stats);
      return entry.name.toLowerCase().includes(text) || has(entry.stats) || has(entry.gear?.runes || []);
    };
    return list.filter(entry => (!text || searched(entry))
      && (!filters.type || entry.type === filters.type)
      && (!filters.place || entry.place === filters.place)
      && (!filters.hidden || !filters.hidden.has(entry.character))
      && (!filters.minLevel || entry.level >= filters.minLevel)
      && (!filters.maxLevel || entry.level <= filters.maxLevel));
  }
  // An item's own choice comes first: always keep, then excluded, then the rule for bound items.
  function itemKey(entry) {
    return String(entry.id || entry.name);
  }
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
  // The Currencies tab: a column for each currency anyone has, a total, and the characters in the order asked for.
  function currencyTable(characters, sort, descending) {
    const columns = new Map([['gold', {key: 'gold', name: 'Gold', total: 0, shop: false}]]);
    const rows = characters.map(character => {
      const amounts = {gold: Number(character.gold) || 0};
      for (const money of character.currencies || []) {
        amounts[money.key] = Number(money.amount) || 0;
        const shop = money.key in SHOP_NAMES;
        if (!columns.has(money.key)) columns.set(money.key, {key: money.key, name: SHOP_NAMES[money.key] || FIXED_NAMES[money.key] || money.name || `Currency ${money.key}`, total: 0, shop});
      }
      return {name: character.name, amounts};
    });
    for (const column of columns.values()) {
      column.total = column.shop ? null : rows.reduce((sum, row) => sum + (row.amounts[column.key] || 0), 0);
    }
    const direction = descending ? -1 : 1;
    rows.sort((a, b) => (sort === 'name' ? a.name.localeCompare(b.name) * direction
      : ((a.amounts[sort] || 0) - (b.amounts[sort] || 0)) * direction || a.name.localeCompare(b.name)));
    const list = [...columns.values()];
    const place = key => { const at = CURRENCY_ORDER.indexOf(key); return at < 0 ? CURRENCY_ORDER.length : at; };
    return {columns: [list[0], ...list.slice(1).sort((a, b) => place(a.key) - place(b.key) || a.name.localeCompare(b.name))], rows};
  }
  function tableCell(tag, text) {
    const node = document.createElement(tag);
    node.textContent = text;
    return node;
  }
  // A heading row whose buttons sort the table; text columns start A to Z and number columns highest first.
  function sortableHeadings(root, columns, redraw) {
    const sorting = root.sorting;
    const headers = document.createElement('tr');
    for (const column of columns) {
      const mark = sorting.key === column.key ? (sorting.descending ? ' ▼' : ' ▲') : '';
      const header = document.createElement('th');
      const button = tableCell('button', column.name + mark);
      button.type = 'button';
      button.addEventListener('click', () => {
        sorting.descending = sorting.key === column.key ? !sorting.descending : !column.text;
        sorting.key = column.key;
        redraw();
      });
      header.append(button);
      headers.append(header);
    }
    root.querySelector('thead').replaceChildren(headers);
  }
  function renderCurrencies(root, characters) {
    root.sorting = root.sorting || {key: 'gold', descending: true};
    const table = currencyTable(characters, root.sorting.key, root.sorting.descending);
    sortableHeadings(root, [{key: 'name', name: 'Character', text: true}, ...table.columns], () => renderCurrencies(root, characters));
    const total = document.createElement('tr');
    total.className = 'currency-total';
    total.append(tableCell('td', 'All characters'));
    for (const column of table.columns) total.append(tableCell('td', column.total === null ? 'per account' : formatNumber(column.total)));
    const rows = table.rows.map(row => {
      const line = document.createElement('tr');
      line.append(tableCell('td', row.name));
      for (const column of table.columns) line.append(tableCell('td', formatNumber(row.amounts[column.key] || 0)));
      return line;
    });
    root.querySelector('tbody').replaceChildren(total, ...rows);
  }
  // The Stats tab: each stat on items or on mana stones, how many there are, and who holds them.
  function statTable(characters, kind, text, sort, descending) {
    const wanted = String(text || '').toLowerCase();
    const found = new Map();
    for (const entry of entries(characters)) {
      if (kind === 'stones' ? !entry.stone : entry.stone) continue;
      for (const stat of entry.stats) {
        if (wanted && !stat.toLowerCase().includes(wanted)) continue;
        if (!found.has(stat)) found.set(stat, {stat, total: 0, owners: new Map()});
        const row = found.get(stat);
        row.total += entry.count;
        row.owners.set(entry.character, (row.owners.get(entry.character) || 0) + entry.count);
      }
    }
    const rows = [...found.values()].map(row => ({stat: row.stat, total: row.total, characters: row.owners.size,
      owners: [...row.owners.entries()].map(([name, count]) => ({name, count})).sort((a, b) => b.count - a.count || a.name.localeCompare(b.name))}));
    const direction = descending ? -1 : 1;
    const key = sort === 'breakdown' ? 'characters' : sort;
    return rows.sort((a, b) => (key === 'stat' ? a.stat.localeCompare(b.stat) : a[key] - b[key]) * direction || a.stat.localeCompare(b.stat));
  }
  const STAT_COLUMNS = [
    {key: 'stat', name: 'Stat', text: true},
    {key: 'total', name: 'How many'},
    {key: 'characters', name: 'Characters'},
  ];
  function renderStats(root, characters) {
    root.sorting = root.sorting || {key: 'total', descending: true};
    if (!root.listening) {
      root.listening = true;
      for (const id of ['stat-search', 'stat-kind']) root.querySelector('#' + id).addEventListener('input', () => renderStats(root, root.characters));
    }
    root.characters = characters;
    const table = root.querySelector('table');
    const rows = statTable(characters, root.querySelector('#stat-kind').value, root.querySelector('#stat-search').value.trim(), root.sorting.key, root.sorting.descending);
    const heads = {sorting: root.sorting, querySelector: selector => table.querySelector(selector)};
    sortableHeadings(heads, STAT_COLUMNS.concat({key: 'breakdown', name: 'Who has them', text: true}), () => renderStats(root, characters));
    table.querySelector('tbody').replaceChildren(...rows.map(row => {
      const line = document.createElement('tr');
      line.append(tableCell('td', row.stat), tableCell('td', formatNumber(row.total)), tableCell('td', formatNumber(row.characters)));
      const who = tableCell('td', row.owners.map(owner => `${owner.name} ${formatNumber(owner.count)}`).join(', '));
      who.className = 'stat-owners';
      line.append(who);
      return line;
    }));
    root.querySelector('#stat-total').textContent = `${formatNumber(rows.length)} different stats`;
  }
  // The Characters tab: one row for each, with the last daily reward taken.
  const ROSTER_COLUMNS = [
    {key: 'name', name: 'Character', text: true},
    {key: 'class', name: 'Class', text: true},
    {key: 'level', name: 'Level'},
    {key: 'gold', name: 'Gold'},
    {key: 'items', name: 'Items'},
    {key: 'saved', name: 'Last saved', text: true},
    {key: 'day', name: 'Reward day'},
    {key: 'taken', name: 'Reward taken'},
  ];
  function rosterRows(characters, sort, descending) {
    const rows = characters.map(character => {
      const taken = Date.parse(character.dailyLogin?.collectedAt || '');
      return {name: String(character.name || ''), class: String(character.class || ''), level: Number(character.level) || 0,
        gold: Number(character.gold) || 0, items: (character.bag || []).length + (character.bank || []).length,
        saved: String(character.saved || ''), day: Number(character.dailyLogin?.day) || 0, taken: Number.isFinite(taken) ? taken : 0};
    });
    const direction = descending ? -1 : 1;
    const text = ROSTER_COLUMNS.find(column => column.key === sort)?.text;
    return rows.sort((a, b) => (text ? a[sort].localeCompare(b[sort]) : a[sort] - b[sort]) * direction || a.name.localeCompare(b.name));
  }
  function renderRoster(root, characters) {
    root.sorting = root.sorting || {key: 'taken', descending: true};
    sortableHeadings(root, ROSTER_COLUMNS, () => renderRoster(root, characters));
    const clock = new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    root.querySelector('tbody').replaceChildren(...rosterRows(characters, root.sorting.key, root.sorting.descending).map(row => {
      const line = document.createElement('tr');
      for (const text of [row.name, row.class, formatNumber(row.level), formatNumber(row.gold), formatNumber(row.items), row.saved || '—',
        row.day || '—', row.taken ? clock.format(row.taken) : '—']) line.append(tableCell('td', text));
      return line;
    }));
  }
  // Gear is one of a kind, with its own durability and stats. Older saves have no details, so its type decides.
  function stackable(entry) {
    return !entry.gear && !EQUIPPABLE.has(entry.type) && !entry.stats.length;
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
  // One cell for each item, or for each stack when stacking is off, and everywhere it is
  function cells(list, stack) {
    const found = new Map();
    list.forEach((entry, index) => {
      const key = stack && stackable(entry) ? String(entry.id || entry.name) : index;
      if (!found.has(key)) found.set(key, {id: entry.id, name: entry.name, icon: entry.icon, type: entry.type, gear: entry.gear, stats: entry.stats, total: 0, places: []});
      const cell = found.get(key);
      cell.total += entry.count;
      cell.places.push(entry);
    });
    return [...found.values()];
  }
  const SORTS = {
    name: (a, b) => a.name.localeCompare(b.name),
    count: (a, b) => b.total - a.total || a.name.localeCompare(b.name),
    type: (a, b) => a.type.localeCompare(b.type) || a.name.localeCompare(b.name),
  };

  function create(root, send, status, onData, menu) {
    const state = {characters: [], hidden: new Set(), sort: 'name'};
    const settings = {excluded: new Set(), whitelist: new Set(), excludeBound: false};
    const icons = new Map();
    const el = id => root.querySelector('#' + id);
    const tooltip = el('bank-tooltip');

    function make(tag, className, text) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    }
    function moveTooltip(event) {
      tooltip.style.left = Math.min(event.clientX + 14, window.innerWidth - 340) + 'px';
      tooltip.style.top = Math.min(event.clientY + 14, window.innerHeight - tooltip.offsetHeight - 8) + 'px';
    }
    function showTooltip(event, cell) {
      const title = make('strong', '', cell.name);
      if (/^[0-9a-f]{6}$/i.test(cell.gear?.color || '')) title.style.color = `#${cell.gear.color}`;
      tooltip.replaceChildren(title, make('span', 'bank-tip-type', `${cell.type} · ${formatNumber(cell.total)} in all`));
      if (cell.gear) for (const line of gearLines(cell.gear)) tooltip.append(make('span', 'bank-tip-row', line));
      else if (cell.stats.length) tooltip.append(make('span', 'bank-tip-row', `Stats: ${cell.stats.join(', ')}`));
      const rows = [...cell.places].sort((a, b) => a.character.localeCompare(b.character) || a.place.localeCompare(b.place) || a.slot - b.slot);
      for (const entry of rows.slice(0, MAX_TOOLTIP_ROWS)) {
        const row = make('span', 'bank-tip-row');
        row.append(make('b', '', entry.character), ` ${locationLabel(entry.place, entry.slot)}`);
        if (entry.count > 1) row.append(` × ${formatNumber(entry.count)}`);
        tooltip.append(row);
      }
      if (rows.length > MAX_TOOLTIP_ROWS) tooltip.append(make('span', 'bank-tip-type', `and ${rows.length - MAX_TOOLTIP_ROWS} more`));
      tooltip.append(make('span', 'bank-tip-type', 'Right-click to exclude it or copy a login'));
      tooltip.hidden = false;
      moveTooltip(event);
    }
    function filters() {
      return {
        text: el('bank-search').value.trim(),
        searchIn: el('bank-search-in').value,
        type: el('bank-type').value,
        place: el('bank-place').value,
        hidden: state.hidden,
        minLevel: Number(el('bank-min-level').value) || 0,
        maxLevel: Number(el('bank-max-level').value) || 0,
      };
    }
    function renderGrid() {
      const grid = el('bank-grid');
      grid.replaceChildren();
      tooltip.hidden = true;
      const showHidden = el('bank-show-excluded').checked;
      const list = applyFilters(entries(state.characters), filters()).filter(entry => showHidden || !isHidden(entry, settings));
      const shown = cells(list, el('bank-stack').checked).sort(SORTS[state.sort]);
      const needed = [];
      for (const cell of shown) {
        const slot = make('div', isHidden(cell.places[0], settings) ? 'bank-slot filled bank-excluded' : 'bank-slot filled');
        slot.addEventListener('contextmenu', event => {
          tooltip.hidden = true;
          const hidden = isHidden(cell.places[0], settings);
          menu(event, [{label: hidden ? 'Bring this item back' : 'Exclude this item', run() {
            toggleHidden(cell.places[0], settings);
            settingsChanged();
          }}], cell.places.map(place => place.character));
        });
        slot.append(make('span', 'bank-letters', cell.name.slice(0, 2)));
        const picture = make('img');
        picture.alt = '';
        picture.dataset.icon = cell.icon || '';
        if (icons.has(cell.icon)) picture.src = icons.get(cell.icon);
        else if (cell.icon) needed.push(cell.icon);
        slot.append(picture);
        if (cell.total > 1) slot.append(make('span', 'bank-count', cell.total > 9999 ? `${Math.floor(cell.total / 1000)}k` : String(cell.total)));
        else if (cell.gear?.plus > 0) slot.append(make('span', 'bank-count', `+${cell.gear.plus}`));
        slot.addEventListener('mouseenter', event => showTooltip(event, cell));
        slot.addEventListener('mousemove', moveTooltip);
        slot.addEventListener('mouseleave', () => { tooltip.hidden = true; });
        grid.append(slot);
      }
      if (!shown.length) grid.append(make('p', 'bank-empty', state.characters.length ? 'Nothing matches these filters.' : 'No characters saved yet.'));
      const gold = state.characters.filter(character => !state.hidden.has(character.name)).reduce((sum, character) => sum + (Number(character.gold) || 0), 0);
      const unseen = state.characters.filter(character => !character.bankSeen).length;
      el('bank-total').textContent = `${formatNumber(shown.length)} shown · ${formatNumber(gold)} gold`
        + (unseen ? ` · ${unseen} characters' banks not seen yet: open the bank once on them` : '');
      if (needed.length) {
        GBIcons.load(needed, send, (name, url) => {
          icons.set(name, url);
          grid.querySelectorAll('img').forEach(picture => { if (picture.dataset.icon === name) picture.src = url; });
        }).catch(error => { status(`Icons couldn't be read: ${error.message || error}`); });
      }
    }
    // Kept in this browser only: it changes what this page shows, not what the game or the helper saves.
    function settingsChanged() {
      if (typeof chrome !== 'undefined' && chrome.storage) {
        chrome.storage.local.set({bankExclusions: {excluded: [...settings.excluded], whitelist: [...settings.whitelist], excludeBound: settings.excludeBound}}).catch(() => {});
      }
      renderExclusions();
      renderGrid();
    }
    function itemName(key) {
      for (const entry of entries(state.characters)) if (itemKey(entry) === key) return entry.name;
      return key.startsWith('n:') ? key.slice(2) : `Item ${key}`;
    }
    function renderExclusions() {
      el('bank-exclusions-summary').textContent = `Excluded items (${settings.excluded.size} excluded, ${settings.whitelist.size} always kept)`;
      el('bank-exclude-bound').checked = settings.excludeBound;
      for (const [id, set] of [['bank-excluded-list', settings.excluded], ['bank-whitelist', settings.whitelist]]) {
        const list = el(id);
        list.replaceChildren();
        for (const key of set) {
          const row = make('li', '', itemName(key) + ' ');
          const remove = make('button', '', 'Remove');
          remove.type = 'button';
          remove.addEventListener('click', () => { set.delete(key); settingsChanged(); });
          row.append(remove);
          list.append(row);
        }
      }
    }
    // An exact name or an ID, from what your characters hold; an ID also works for something nobody holds yet.
    function keyForText(text) {
      if (/^\d+$/.test(text)) return text;
      const lower = text.toLowerCase();
      const found = entries(state.characters).find(entry => entry.name.toLowerCase() === lower);
      return found ? itemKey(found) : null;
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
    function renderSummary() {
      const total = state.characters.length;
      const shown = total - state.characters.filter(character => state.hidden.has(character.name)).length;
      el('bank-character-summary').textContent = shown === total ? `All characters (${total})` : `${shown} of ${total} characters`;
    }
    function renderCharacters() {
      const list = el('bank-character-list');
      list.replaceChildren();
      for (const character of state.characters) {
        const label = make('label', 'bank-character');
        const box = make('input');
        box.type = 'checkbox';
        box.checked = !state.hidden.has(character.name);
        box.addEventListener('change', () => {
          if (box.checked) state.hidden.delete(character.name);
          else state.hidden.add(character.name);
          renderSummary();
          renderGrid();
        });
        const detail = `${character.class || 'Level'} ${character.level || '?'} · ${formatNumber(character.gold)} gold`;
        label.append(box, make('span', 'bank-name', character.name), make('span', 'bank-detail', character.note ? `${detail} · ${character.note}` : detail));
        list.append(label);
      }
      renderSummary();
    }
    function setAll(on) {
      state.hidden = new Set(on ? [] : state.characters.map(character => character.name));
      renderCharacters();
      renderGrid();
    }
    async function reload() {
      // A big file comes in parts, and the local host says how long the whole of it is.
      let json = '';
      for (;;) {
        const response = await send({type: 'bank-data', offset: json.length});
        json += response.json || '';
        if (!response.json || !response.total || json.length >= response.total) break;
      }
      const data = json ? JSON.parse(json) : {characters: []};
      state.characters = Array.isArray(data.characters) ? data.characters : [];
      el('bank-made').textContent = data.made ? `Data from ${data.made}` : 'No saved data yet: press Update now after logging out of a character.';
      renderCharacters();
      renderGrid();
      renderExclusions();
      if (onData) onData(totals(state.characters), data.made, state.characters);
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

    for (const id of ['bank-search', 'bank-min-level', 'bank-max-level']) el(id).addEventListener('input', renderGrid);
    for (const id of ['bank-type', 'bank-place', 'bank-stack', 'bank-search-in']) el(id).addEventListener('change', renderGrid);
    el('bank-sort').addEventListener('change', event => { state.sort = event.target.value; renderGrid(); });
    el('bank-all').addEventListener('click', () => setAll(true));
    el('bank-none').addEventListener('click', () => setAll(false));
    el('bank-update').addEventListener('click', update);
    el('bank-show-excluded').addEventListener('change', renderGrid);
    el('bank-exclude-bound').addEventListener('change', event => { settings.excludeBound = event.target.checked; settingsChanged(); });
    el('bank-exclusion-add').addEventListener('click', () => addFromBox(settings.excluded, settings.whitelist));
    el('bank-whitelist-add').addEventListener('click', () => addFromBox(settings.whitelist, settings.excluded));
    if (typeof chrome !== 'undefined' && chrome.storage) {
      chrome.storage.local.get('bankExclusions').then(({bankExclusions: saved}) => {
        if (!saved) return;
        settings.excluded = new Set(saved.excluded || []);
        settings.whitelist = new Set(saved.whitelist || []);
        settings.excludeBound = !!saved.excludeBound;
        renderExclusions();
        renderGrid();
      }).catch(() => {});
    }
    return {reload, update};
  }
  return {create, typeOf, locationLabel, entries, applyFilters, cells, formatDuration, totals, isHidden, toggleHidden, stackable, gearLines, currencyTable, renderCurrencies, rosterRows, renderRoster, statTable, renderStats};
})();
