'use strict';
// The Bank tab: every character's bag and bank, laid out as the game lays them out.
const GBBank = (() => {
  // The game's own layout: 30 bag slots a page, 6 across; 40 bank slots a page, 5 across.
  const LAYOUT = {
    bag: {label: 'Bag', perPage: 30, across: 6},
    bank: {label: 'Bank', perPage: 40, across: 5},
  };

  function formatGold(value) {
    return Number(value || 0).toLocaleString('en-US');
  }
  function holds(character, text) {
    return ['bag', 'bank'].some(place => (character[place] || []).some(item => String(item.name || '').toLowerCase().includes(text)));
  }
  // Characters a search shows: its text in a name or note, or an item they hold.
  function matches(character, text) {
    if (!text) return true;
    return String(character.name || '').toLowerCase().includes(text)
      || String(character.note || '').toLowerCase().includes(text)
      || holds(character, text);
  }
  function totalOf(character, text) {
    let total = 0;
    for (const place of ['bag', 'bank']) {
      for (const item of character[place] || []) {
        if (String(item.name || '').toLowerCase().includes(text)) total += Number(item.count) || 1;
      }
    }
    return total;
  }
  function pageCount(character, place) {
    const layout = LAYOUT[place];
    const slots = Number(place === 'bag' ? character.bagSlots : character.bankSlots) || 0;
    const used = Math.max(0, ...(character[place] || []).map(item => Number(item.slot) || 0));
    return Math.max(1, Math.ceil(Math.max(slots, used) / layout.perPage));
  }
  // The slots of one page: [{slot, item or undefined}], in the game's order.
  function pageSlots(character, place, page) {
    const layout = LAYOUT[place];
    const first = (page - 1) * layout.perPage + 1;
    const bySlot = new Map((character[place] || []).map(item => [Number(item.slot), item]));
    return Array.from({length: layout.perPage}, (_, i) => ({slot: first + i, item: bySlot.get(first + i)}));
  }

  function create(root, send, status) {
    const state = {characters: [], name: null, place: 'bag', page: 1, search: ''};
    const icons = new Map();
    const el = id => root.querySelector('#' + id);
    const tooltip = el('bank-tooltip');

    function make(tag, className, text) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== undefined) node.textContent = text;
      return node;
    }
    function current() {
      return state.characters.find(character => character.name === state.name) || null;
    }
    function renderList() {
      const list = el('bank-characters');
      list.replaceChildren();
      const text = state.search;
      const shown = state.characters.filter(character => matches(character, text));
      for (const character of shown) {
        const button = make('button', 'bank-character' + (character.name === state.name ? ' selected' : ''));
        button.type = 'button';
        button.append(make('span', 'bank-name', character.name));
        const held = text && holds(character, text) ? `${formatGold(totalOf(character, text))} found · ` : '';
        button.append(make('span', 'bank-detail', `${held}${character.class || 'Level'} ${character.level || '?'} · ${formatGold(character.gold)} gold`));
        if (character.note) button.append(make('span', 'bank-note', character.note));
        button.addEventListener('click', () => {
          state.name = character.name;
          state.page = 1;
          render();
        });
        list.append(button);
      }
      if (!shown.length) list.append(make('p', 'hint', state.characters.length ? 'Nobody matches that search.' : 'No characters saved yet.'));
      const total = state.characters.reduce((sum, character) => sum + (Number(character.gold) || 0), 0);
      el('bank-total').textContent = `${state.characters.length} characters · ${formatGold(total)} gold`;
    }
    function showTooltip(event, item) {
      tooltip.replaceChildren(make('strong', '', item.name || 'Unknown item'));
      if ((Number(item.count) || 1) > 1) tooltip.append(make('span', '', `Count: ${formatGold(item.count)}`));
      tooltip.hidden = false;
      moveTooltip(event);
    }
    function moveTooltip(event) {
      tooltip.style.left = Math.min(event.clientX + 14, window.innerWidth - 280) + 'px';
      tooltip.style.top = event.clientY + 14 + 'px';
    }
    function renderWindow() {
      const character = current();
      const title = el('bank-window-title');
      const grid = el('bank-grid');
      const pages = el('bank-pages');
      grid.replaceChildren();
      pages.replaceChildren();
      tooltip.hidden = true;
      root.querySelectorAll('[data-place]').forEach(button => button.classList.toggle('selected', button.dataset.place === state.place));
      if (!character) {
        title.textContent = 'Choose a character';
        el('bank-saved').textContent = '';
        return;
      }
      title.textContent = character.name;
      el('bank-saved').textContent = character.saved ? `Saved ${character.saved}` : '';
      const layout = LAYOUT[state.place];
      grid.style.gridTemplateColumns = `repeat(${layout.across}, var(--slot))`;
      if (state.place === 'bank' && !character.bankSeen) {
        grid.append(make('p', 'bank-empty', 'Not seen yet. Open the bank once on this character.'));
        return;
      }
      const count = pageCount(character, state.place);
      state.page = Math.min(state.page, count);
      for (let page = 1; page <= count; page++) {
        const button = make('button', 'bank-page' + (page === state.page ? ' selected' : ''), String(page));
        button.type = 'button';
        button.addEventListener('click', () => { state.page = page; renderWindow(); });
        pages.append(button);
      }
      const needed = [];
      for (const {item} of pageSlots(character, state.place, state.page)) {
        const slot = make('div', 'bank-slot');
        if (item) {
          slot.classList.add('filled');
          if (state.search && !String(item.name || '').toLowerCase().includes(state.search)) slot.classList.add('dim');
          slot.append(make('span', 'bank-letters', String(item.name || '?').slice(0, 2)));
          const picture = make('img');
          picture.alt = '';
          picture.dataset.icon = item.icon || '';
          if (icons.has(item.icon)) picture.src = icons.get(item.icon);
          else if (item.icon) needed.push(item.icon);
          slot.append(picture);
          if ((Number(item.count) || 1) > 1) slot.append(make('span', 'bank-count', String(item.count)));
          slot.addEventListener('mouseenter', event => showTooltip(event, item));
          slot.addEventListener('mousemove', moveTooltip);
          slot.addEventListener('mouseleave', () => { tooltip.hidden = true; });
        }
        grid.append(slot);
      }
      if (needed.length) {
        GBIcons.load(needed, send, (name, url) => {
          icons.set(name, url);
          grid.querySelectorAll('img').forEach(picture => { if (picture.dataset.icon === name) picture.src = url; });
        }).catch(error => { status(`Icons couldn't be read: ${error.message || error}`); });
      }
    }
    function render() {
      renderList();
      renderWindow();
    }
    async function reload() {
      const response = await send({type: 'bank-data'});
      const data = response.json ? JSON.parse(response.json) : {characters: []};
      state.characters = Array.isArray(data.characters) ? data.characters : [];
      if (!current()) state.name = state.characters.length ? state.characters[0].name : null;
      el('bank-made').textContent = data.made ? `Data from ${data.made}` : 'No saved data yet: press Update now after logging out of a character.';
      render();
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

    root.querySelectorAll('[data-place]').forEach(button => {
      button.addEventListener('click', () => {
        state.place = button.dataset.place;
        state.page = 1;
        renderWindow();
      });
    });
    el('bank-search').addEventListener('input', event => {
      state.search = event.target.value.trim().toLowerCase();
      render();
    });
    el('bank-update').addEventListener('click', update);
    return {reload, update};
  }
  return {create, matches, pageCount, pageSlots, totalOf};
})();
