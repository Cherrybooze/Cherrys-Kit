'use strict';
// The Bank tab: everything every character holds, in one scrolling grid with a search and filters.
const GBBank = (() => {
  // The game's own pages: 30 bag slots, 40 bank slots.
  const PER_PAGE = {bag: 30, bank: 40};
  const PLACE = {bag: 'Bag', bank: 'Bank'};
  const MAX_TOOLTIP_ROWS = 12;
  // A save older than this may be out of date: the character could have been played on another PC since.
  const STALE_DAYS = 7;

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
  // Bank 45 (page 2, slot 5)
  function locationLabel(place, slot) {
    const perPage = PER_PAGE[place];
    const page = Math.floor((slot - 1) / perPage) + 1;
    return `${PLACE[place]} ${slot} (page ${page}, slot ${slot - (page - 1) * perPage})`;
  }
  // Whole days since a saved time such as 2026-10-30 18:17, or null if it can't be read
  function savedDaysAgo(saved, now) {
    const time = Date.parse(String(saved || '').replace(' ', 'T'));
    return Number.isNaN(time) ? null : Math.max(0, Math.floor((now - time) / 86400000));
  }
  function staleNote(saved, now) {
    const days = savedDaysAgo(saved, now);
    return days !== null && days >= STALE_DAYS ? `saved ${days} days ago, may be out of date` : '';
  }
  // One row for each stack on each character
  function entries(characters) {
    const list = [];
    for (const character of characters) {
      for (const place of ['bag', 'bank']) {
        for (const item of character[place] || []) {
          list.push({id: item.id, name: String(item.name || 'Unknown item'), icon: item.icon, count: Number(item.count) || 1,
            type: typeOf(item.id, item.icon), character: character.name, level: Number(character.level) || 0, saved: character.saved, place, slot: Number(item.slot) || 0});
        }
      }
    }
    return list;
  }
  function applyFilters(list, filters) {
    const text = (filters.text || '').toLowerCase();
    return list.filter(entry => (!text || entry.name.toLowerCase().includes(text))
      && (!filters.type || entry.type === filters.type)
      && (!filters.place || entry.place === filters.place)
      && (!filters.hidden || !filters.hidden.has(entry.character))
      && (!filters.minLevel || entry.level >= filters.minLevel)
      && (!filters.maxLevel || entry.level <= filters.maxLevel));
  }
  // One cell for each item, or for each stack when stacking is off, and everywhere it is
  function cells(list, stack) {
    const found = new Map();
    list.forEach((entry, index) => {
      const key = stack ? String(entry.id || entry.name) : index;
      if (!found.has(key)) found.set(key, {id: entry.id, name: entry.name, icon: entry.icon, type: entry.type, total: 0, places: []});
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

  function create(root, send, status) {
    const state = {characters: [], hidden: new Set(), sort: 'name'};
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
      tooltip.replaceChildren(make('strong', '', cell.name), make('span', 'bank-tip-type', `${cell.type} · ${formatNumber(cell.total)} in all`));
      const rows = [...cell.places].sort((a, b) => a.character.localeCompare(b.character) || a.place.localeCompare(b.place) || a.slot - b.slot);
      for (const entry of rows.slice(0, MAX_TOOLTIP_ROWS)) {
        const row = make('span', 'bank-tip-row');
        row.append(make('b', '', entry.character), ` ${locationLabel(entry.place, entry.slot)}`);
        if (entry.count > 1) row.append(` × ${formatNumber(entry.count)}`);
        const stale = staleNote(entry.saved, Date.now());
        if (stale) row.append(make('span', 'bank-stale', ` (${stale})`));
        tooltip.append(row);
      }
      if (rows.length > MAX_TOOLTIP_ROWS) tooltip.append(make('span', 'bank-tip-type', `and ${rows.length - MAX_TOOLTIP_ROWS} more`));
      tooltip.hidden = false;
      moveTooltip(event);
    }
    function filters() {
      return {
        text: el('bank-search').value.trim(),
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
      const list = applyFilters(entries(state.characters), filters());
      const shown = cells(list, el('bank-stack').checked).sort(SORTS[state.sort]);
      const needed = [];
      for (const cell of shown) {
        const slot = make('div', 'bank-slot filled');
        slot.append(make('span', 'bank-letters', cell.name.slice(0, 2)));
        const picture = make('img');
        picture.alt = '';
        picture.dataset.icon = cell.icon || '';
        if (icons.has(cell.icon)) picture.src = icons.get(cell.icon);
        else if (cell.icon) needed.push(cell.icon);
        slot.append(picture);
        if (cell.total > 1) slot.append(make('span', 'bank-count', cell.total > 9999 ? `${Math.floor(cell.total / 1000)}k` : String(cell.total)));
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
        const stale = staleNote(character.saved, Date.now());
        if (stale) label.append(make('span', 'bank-detail bank-stale', stale));
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
      const response = await send({type: 'bank-data'});
      const data = response.json ? JSON.parse(response.json) : {characters: []};
      state.characters = Array.isArray(data.characters) ? data.characters : [];
      el('bank-made').textContent = data.made ? `Data from ${data.made}` : 'No saved data yet: press Update now after logging out of a character.';
      renderCharacters();
      renderGrid();
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
    for (const id of ['bank-type', 'bank-place', 'bank-stack']) el(id).addEventListener('change', renderGrid);
    el('bank-sort').addEventListener('change', event => { state.sort = event.target.value; renderGrid(); });
    el('bank-all').addEventListener('click', () => setAll(true));
    el('bank-none').addEventListener('click', () => setAll(false));
    el('bank-update').addEventListener('click', update);
    return {reload, update};
  }
  return {create, typeOf, locationLabel, entries, applyFilters, cells, staleNote};
})();
