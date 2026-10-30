'use strict';
// Reads the shop's item depot page while the player has it open, and hands the items to the extension's page.
// It never fetches anything, and never keeps the page's address, which holds a private token.
(() => {
  if (!/^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(location.hostname) || !/^\/depotitems\//.test(location.pathname)) return;
  const MAX_ITEMS = 2000;
  const MAX_OUTLINE = 500;
  const signature = node => node.tagName + '.' + [...node.classList].sort().join('.');

  // The address of a picture, https only, without anything after a ?.
  function pictureOf(node) {
    const image = node.querySelector('img');
    if (!image?.src) return '';
    try {
      const url = new URL(image.src);
      return url.protocol === 'https:' ? url.origin + url.pathname : '';
    } catch { return ''; }
  }
  function textLines(node) {
    const lines = [];
    const walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      const text = walker.currentNode.textContent.trim();
      if (text) lines.push(text);
    }
    return lines;
  }
  // Items are the biggest set of same-looking neighbours that each hold a picture and some text.
  function findRows(root) {
    let best = [];
    for (const parent of root.querySelectorAll('*')) {
      const groups = new Map();
      for (const child of parent.children) {
        if (!child.querySelector('img') || !textLines(child).length) continue;
        const key = signature(child);
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push(child);
      }
      for (const group of groups.values()) if (group.length > best.length) best = group;
    }
    return best;
  }
  function readRow(row) {
    const lines = textLines(row);
    const image = row.querySelector('img');
    const named = lines.find(line => !/^[x×]?\s*\d+\s*[x×]?$/i.test(line) && !/^\d/.test(line));
    const counted = lines.map(line => line.match(/^[x×]?\s*(\d+)\s*[x×]?$/i) || line.match(/[x×]\s*(\d+)\b/i)).find(Boolean);
    const name = (image?.alt || image?.title || named || lines[0] || '').trim();
    return {name: name.slice(0, 120), count: counted ? Number(counted[1]) : 1, picture: pictureOf(row)};
  }
  function readItems() {
    return findRows(document.body).slice(0, MAX_ITEMS).map(readRow).filter(item => item.name);
  }
  // The page's shape, for working out a page this doesn't read yet: tags and class names only, so no names, items or links.
  function outline() {
    const lines = [];
    const walk = (node, depth) => {
      if (lines.length >= MAX_OUTLINE || ['SCRIPT', 'STYLE', 'SVG', 'NOSCRIPT'].includes(node.tagName)) return;
      lines.push(' '.repeat(depth) + signature(node).toLowerCase());
      for (const child of node.children) walk(child, depth + 1);
    };
    walk(document.body, 0);
    return lines.join('\n');
  }
  function serverName() {
    const spans = [...(document.querySelector('.welcome')?.querySelectorAll(':scope > span') || [])];
    return spans.find(span => !span.querySelector('a'))?.textContent?.trim().slice(0, 120) || '';
  }
  let timer, last = '';
  function report() {
    const items = readItems();
    const text = JSON.stringify(items);
    if (text === last) return;
    last = text;
    try {
      chrome.runtime.sendMessage({type: 'depot-items', server: serverName(), items, outline: outline()}).catch(() => {});
    } catch { /* the extension was reloaded */ }
  }
  report();
  new MutationObserver(() => {
    clearTimeout(timer);
    timer = setTimeout(report, 500);
  }).observe(document.body, {childList: true, subtree: true});
})();
