'use strict';
// Reads the Runes of Magic site's character transfer page and its account page (/user/administration) while the
// player has them open: the transfers listed as planned, the characters the form offers or the page lists, and the
// login's RoM username and Gameforge e-mail address, so the Global Bank page can name those characters' accounts.
// GBTransfers.parsePage (transfers.js, loaded before this) makes sense of it, and the extension keeps it in its own
// storage on this PC. It passes on nothing else: no password, no link. It never clicks, fills in or fetches anything.
(() => {
  if (!/^[a-z0-9-]+\.runesofmagic\.gameforge\.com$/i.test(location.hostname)) return;
  const kind = /^\/charactertransfer(\/|$)/i.test(location.pathname) ? 'transfer' : /^\/user\/administration(\/|$)/i.test(location.pathname) ? 'account' : '';
  if (!kind) return;
  const SKIP = 'select, option, script, style, noscript, template, textarea';
  const MAX_TEXTS = 4000;
  let stopped = false, timer = 0, firstTimer = 0, last = '', notice = null;
  const active = () => {
    if (stopped) return false;
    try { return !!chrome.runtime?.id; } catch { return false; }
  };
  function stop() {
    stopped = true;
    clearTimeout(timer);
    clearTimeout(firstTimer);
    observer.disconnect();
  }
  // The options of each list on the page, and its other text in order
  function snapshot() {
    const selects = [...document.querySelectorAll('select')].slice(0, 20).map(list => [...list.options].slice(0, 400).map(option => option.textContent || ''));
    const texts = [];
    if (document.body) {
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
      while (walker.nextNode() && texts.length < MAX_TEXTS) {
        const node = walker.currentNode;
        const text = node.textContent.replace(/\s+/g, ' ').trim();
        if (!text || node.parentElement?.closest(SKIP) || node.parentElement?.closest('#globalbank-transfer-notice')) continue;
        texts.push(text.slice(0, 200));
      }
    }
    // Text boxes that show the account, by their label; never a password box
    const fields = [];
    for (const box of [...document.querySelectorAll('input')].slice(0, 60)) {
      const type = String(box.type || 'text').toLowerCase();
      if ((type !== 'text' && type !== 'email') || !box.value || fields.length >= 20) continue;
      const label = (box.id && document.querySelector(`label[for="${CSS.escape(box.id)}"]`)?.textContent) || box.closest?.('label')?.textContent
        || box.getAttribute?.('aria-label') || box.placeholder || box.name || '';
      fields.push({label: String(label).slice(0, 60), value: String(box.value).slice(0, 200)});
    }
    return {selects, texts, fields};
  }
  // A short note in the page's corner when Global Bank took a transfer up, or saw one end
  function tell(lines) {
    if (!lines.length || !document.body) return;
    notice?.remove();
    notice = document.createElement('div');
    notice.id = 'globalbank-transfer-notice';
    notice.setAttribute('role', 'status');
    Object.assign(notice.style, {position: 'fixed', zIndex: '2147483647', bottom: '16px', right: '16px', maxWidth: '340px', padding: '10px 30px 10px 12px',
      background: '#202a37', color: '#fff', border: '1px solid #d1b268', borderRadius: '6px', font: '13px/1.4 sans-serif', boxShadow: '0 6px 20px #0008'});
    const title = document.createElement('b');
    title.textContent = 'Global Bank';
    title.style.display = 'block';
    title.style.color = '#edc779';
    notice.append(title);
    for (const line of lines) {
      const row = document.createElement('div');
      row.textContent = line;
      notice.append(row);
    }
    const close = document.createElement('button');
    close.type = 'button';
    close.textContent = '×';
    close.title = 'Dismiss';
    Object.assign(close.style, {position: 'absolute', top: '4px', right: '6px', border: '0', background: 'none', color: '#fff', font: '16px sans-serif', cursor: 'pointer'});
    close.addEventListener('click', () => { notice?.remove(); notice = null; });
    notice.append(close);
    document.body.append(notice);
    const shown = notice;
    setTimeout(() => { if (notice === shown) { shown.remove(); notice = null; } }, 12000);
  }
  const when = ms => new Intl.DateTimeFormat(undefined, {weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'}).format(ms);
  async function report() {
    if (!active()) { stop(); return; }
    const read = GBTransfers.parsePage(snapshot());
    const text = JSON.stringify(read);
    // A page that says nothing about transfers or the account yet, or the same as last time, isn't worth a message
    if (text === last || (!read.form && !read.planned.length && !read.account && !read.listed.length && !last)) return;
    const first = !last;
    last = text;
    try {
      const answer = await chrome.runtime.sendMessage({type: 'transfer-page', kind, ...read});
      if (!active() || !answer?.ok) return;
      const lines = [...(answer.added || []).map(item => `Recorded ${item.name}'s transfer to ${item.to}. The game moves it in the maintenance on ${when(item.due)} (your time).`),
        ...(answer.ended || []).map(item => (item.state === 'cancelled' ? `${item.name}'s transfer to ${item.to} is cancelled: its plate is gone from the Characters page.`
          : item.state === 'moved' ? `${item.name} has moved to ${item.to}: log in with it there to confirm.` : `${item.name} is still on ${item.from}.`))];
      const linked = answer.linked;
      if (linked) lines.push(`Linked ${linked.count === 1 ? 'a character' : `${linked.count} characters`} to ${[linked.user ? `RoM account ${linked.user}` : '', linked.email ? `Gameforge account ${linked.email}` : ''].filter(Boolean).join(' and ')}.`);
      if (answer.remembered) lines.push(`Remembered ${[answer.remembered.user, answer.remembered.email].filter(Boolean).join(' and ')}: open the transfer page with this login to link its characters.`);
      // The first time, also what it understood, so a page it can't read shows at once
      const count = read.planned.length;
      if (first && !lines.length && kind === 'transfer') lines.push(count ? `Keeping track of ${count === 1 ? 'the planned transfer' : `the ${count} planned transfers`} on this page.` : 'No transfer is planned on this page yet.');
      tell(lines);
    } catch (error) {
      if (/extension context invalidated/i.test(String(error?.message || error))) stop();
    }
  }
  // The page may still be filling in its lists: read it a moment after it loaded, then a moment after changes, at most
  // that often however busy the page is
  const observer = new MutationObserver(() => {
    if (!active()) { stop(); return; }
    if (!timer) timer = setTimeout(() => { timer = 0; report(); }, 700);
  });
  observer.observe(document.documentElement, {subtree: true, childList: true, characterData: true});
  firstTimer = setTimeout(report, 1200);
})();
