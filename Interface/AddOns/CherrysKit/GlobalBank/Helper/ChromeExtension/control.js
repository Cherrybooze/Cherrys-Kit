'use strict';
(() => {
  const byId = id => document.getElementById(id);
  const status = byId('helper-status');
  const start = byId('start-helper');
  let starting = false;
  async function send(message) {
    const response = await chrome.runtime.sendMessage(message);
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    return response;
  }
  async function checkHelper() {
    try {
      const response = await send({type:'helper-status'});
      status.textContent = response.running ? 'Helper is running.' : 'Helper is not running.';
      start.disabled = !!response.running || starting;
      return !!response.running;
    } catch (error) {
      status.textContent = 'Cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error);
      start.disabled = true;
      return false;
    }
  }
  byId('check-helper').addEventListener('click', checkHelper);
  start.addEventListener('click', async event => {
    if (!event.isTrusted || starting) return;
    starting = true;
    start.disabled = true;
    status.textContent = 'Starting the helper…';
    let running = false;
    try {
      await send({type:'helper-start'});
      for (let i = 0; i < 10 && !running; i++) {
        if (i) await new Promise(resolve => setTimeout(resolve, 500));
        running = await checkHelper();
      }
      if (!running) status.textContent = 'The helper did not report ready. Check its window, then try again.';
    } catch (error) {
      status.textContent = 'Could not start the helper: ' + String(error.message || error);
    } finally {
      starting = false;
      start.disabled = running;
    }
  });
  async function run(form, output, message) {
    const button = form.querySelector('button[type="submit"]');
    button.disabled = true;
    output.textContent = 'Reading local data…';
    try {
      const response = await send(message);
      output.textContent = typeof response.output === 'string' ? response.output : 'No results.';
    } catch (error) {
      output.textContent = 'Could not read local data: ' + String(error.message || error);
    } finally { button.disabled = false; }
  }
  byId('bank-form').addEventListener('submit', event => {
    event.preventDefault();
    const command = byId('bank-command').value.trim();
    if (command) run(event.currentTarget, byId('bank-output'), {type:'bank-query',command});
  });
  const stats = {
    str:'Strength', dex:'Dexterity', sta:'Stamina', int:'Intelligence', wis:'Wisdom',
    patt:'Physical attack', matt:'Magical attack', pdam:'Physical damage', mdam:'Magical damage',
    pdef:'Physical defense', mdef:'Magical defense', hp:'Health', mp:'Mana',
    pcrit:'Physical critical', mcrit:'Magical critical', pacc:'Physical accuracy',
    macc:'Magical accuracy', pdod:'Dodge', parry:'Parry', heal:'Healing'
  };
  const statSelect = byId('auction-stat');
  Object.entries(stats).forEach(([value, label]) => {
    const option = document.createElement('option');
    option.value = value; option.textContent = label; statSelect.appendChild(option);
  });
  const output = byId('auction-output');
  const table = byId('auction-table');
  const rows = byId('auction-rows');
  const prev = byId('auction-prev');
  const next = byId('auction-next');
  let query = null, total = 0, pageSize = 50, loading = false;
  const display = value => value === null || value === undefined || value === '' ? '—' : String(value);
  function readQuery() {
    return {type:'auction-query', search:byId('auction-search').value.trim(), realm:byId('auction-realm').value.trim(),
      pageOptions:{sort:byId('auction-sort').value, order:byId('auction-order').value,
        stat:statSelect.value, minimum:byId('auction-min').value, maximum:byId('auction-max').value, offset:0}};
  }
  async function showPage() {
    if (loading || !query) return;
    loading = true; prev.disabled = next.disabled = true;
    output.textContent = 'Reading local auction cache…';
    try {
      const response = await send(query);
      const page = response.page;
      if (!page || !Array.isArray(page.rows)) throw new Error('Unexpected auction cache response. Restart the helper and try again.');
      total = Number(page.total) || 0; pageSize = Number(page.pageSize) || 50;
      rows.replaceChildren();
      for (const item of page.rows) {
        const tr = document.createElement('tr');
        const name = display(item.name) + (item.itemid ? ' (ID ' + item.itemid + ')' : '') + (item.count > 1 ? ' ×' + item.count : '');
        const details = [item.statNames, item.stats].filter(Boolean).join(' — ');
        const date = item.end ? new Date(item.end) : null;
        const end = date && !Number.isNaN(date.getTime()) ? date.toLocaleString() : '—';
        const price = item.price === null || item.price === undefined ? '—' : Number(item.price).toLocaleString() + (item.currency ? ' ' + item.currency : '');
        for (const value of [name, item.realm, item.level, item.tier, item.dura, details, end, item.seller, price]) {
          const td = document.createElement('td'); td.textContent = display(value); tr.appendChild(td);
        }
        rows.appendChild(tr);
      }
      table.hidden = !page.rows.length;
      output.textContent = total ? 'Showing ' + (page.offset + 1) + '–' + (page.offset + page.rows.length) + ' of ' + total + ' cached auctions.' : 'No matching cached auctions. Search in game to collect auction data.';
      prev.disabled = page.offset <= 0;
      next.disabled = page.offset + page.rows.length >= total;
    } catch (error) {
      table.hidden = true; rows.replaceChildren();
      output.textContent = 'Could not read auction data: ' + String(error.message || error);
    } finally { loading = false; }
  }
  byId('auction-form').addEventListener('submit', event => {
    event.preventDefault(); if (loading) return;
    query = readQuery(); showPage();
  });
  byId('auction-all').addEventListener('click', () => {
    if (loading) return;
    for (const id of ['auction-search','auction-realm','auction-stat','auction-min','auction-max']) byId(id).value = '';
    if (byId('auction-sort').value === 'stat') byId('auction-sort').value = 'name';
    query = readQuery(); showPage();
  });
  prev.addEventListener('click', () => { if (query && !loading) { query.pageOptions.offset = Math.max(0, query.pageOptions.offset - pageSize); showPage(); } });
  next.addEventListener('click', () => { if (query && !loading && query.pageOptions.offset + pageSize < total) { query.pageOptions.offset += pageSize; showPage(); } });
  checkHelper();
})();
