'use strict';
// Mail: what each mailbox held when its character last had it open, and the mail your characters sent since, which
// is on its way to the others. The game only shows a mailbox while it's open, so a mailbox's gold is known as of then,
// and the mail sent after that is added as an estimate. Times are seconds since 1970, as the game's os.time() gives.
const GBMail = (() => {
  // How long a mail waits before the game returns it. A mailbox says exactly; for mail sent since, this is a guess.
  const MAIL_DAYS = 30;
  const SOON = 48 * 3600;
  // The most sent mail the page keeps, newest first: the game keeps as many for each character
  const SENT_MAX = 360;
  const escapeHtml = text => String(text ?? '').replace(/[&<>"']/g, letter => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[letter]));
  const number = value => Number(value || 0).toLocaleString('en-US');
  const lower = text => String(text || '').toLowerCase();
  const serverOf = character => String(character.shownServer ?? character.server ?? '');
  // The same key the rest of the page gives a character: its server and its own name
  const keyOf = (name, server) => (typeof GBRoster !== 'undefined' ? GBRoster.keyOf(name, server) : `${lower(server)}|${lower(name)}`);
  // Something to collect: gold, diamonds or items. A letter with nothing on it isn't waiting for anyone.
  const holds = mail => Number(mail.gold) > 0 || Number(mail.diamonds) > 0 || Number(mail.items) > 0 || !!String(mail.itemText || '').trim();

  // Every character's mailbox now: {character, read, recorded, waiting: [mail], gold, diamonds, count, expiring, soonest,
  // estimated}. Each waiting mail is {from, subject, gold, diamonds, cod, items, itemText, expires, sent: the time it was
  // sent when it comes from the sent mail, seen: whether a mailbox showed it}. now: seconds.
  function mailboxes(characters, now = Date.now() / 1000) {
    const byKey = new Map();
    for (const character of characters) {
      const mail = character.mail || null;
      const read = Number(mail?.read) || 0;
      const box = {character, read, recorded: Array.isArray(mail?.inbox), waiting: [], gold: 0, diamonds: 0, count: 0, expiring: 0, soonest: 0, estimated: 0, unread: 0};
      for (const item of Array.isArray(mail?.inbox) ? mail.inbox : []) {
        const expires = read ? read + (Number(item.minutes) || 0) * 60 : 0;
        if (item.unread) box.unread++;
        if (!holds(item) || (expires && expires <= now)) continue;
        box.waiting.push({from: String(item.from || ''), subject: String(item.subject || ''), gold: Number(item.cod) > 0 ? 0 : Number(item.gold) || 0,
          diamonds: Number(item.diamonds) || 0, cod: Number(item.cod) || 0, items: Number(item.items) || 0, itemText: '', expires, sent: 0, seen: true,
          returned: !!item.returned});
      }
      byKey.set(character.key || keyOf(character.base ?? character.name, serverOf(character)), box);
    }
    // Mail sent to one of your own characters after its mailbox was last open is in it now, until it's taken or sent back
    for (const sender of characters) {
      for (const item of Array.isArray(sender.mail?.sent) ? sender.mail.sent : []) {
        const box = byKey.get(keyOf(item.to, serverOf(sender)));
        const at = Number(item.at) || 0;
        if (!box || box.character === sender || (box.read && at && at <= box.read)) continue;
        const expires = at ? at + MAIL_DAYS * 86400 : 0;
        if ((expires && expires <= now) || !holds({...item, itemText: item.items, items: 0})) continue;
        box.waiting.push({from: String(sender.name || ''), fromKey: sender.key || '', subject: String(item.subject || ''), gold: Number(item.cod) > 0 ? 0 : Number(item.gold) || 0,
          diamonds: Number(item.diamonds) || 0, cod: Number(item.cod) || 0, items: 0, itemText: String(item.items || ''), expires, sent: at, seen: false, returned: false});
      }
    }
    for (const box of byKey.values()) {
      box.waiting.sort((a, b) => (a.expires || Infinity) - (b.expires || Infinity));
      box.count = box.waiting.length;
      for (const mail of box.waiting) {
        box.gold += mail.gold;
        box.diamonds += mail.diamonds;
        if (!mail.seen) box.estimated++;
        if (mail.expires && mail.expires - now <= SOON) box.expiring++;
      }
      box.soonest = box.waiting.find(mail => mail.expires)?.expires || 0;
    }
    return byKey;
  }
  // The page's totals for the characters shown
  function totals(boxes, characters) {
    const sum = {mails: 0, gold: 0, diamonds: 0, expiring: 0, characters: 0, estimated: 0, read: 0, withExpiring: 0};
    for (const character of characters) {
      const box = boxes.get(character.key);
      if (!box) continue;
      if (box.recorded) sum.read++;
      if (!box.count) continue;
      sum.characters++;
      sum.mails += box.count;
      sum.gold += box.gold;
      sum.diamonds += box.diamonds;
      sum.expiring += box.expiring;
      sum.estimated += box.estimated;
      if (box.expiring) sum.withExpiring++;
    }
    return sum;
  }
  // The newest sent mail of everyone shown, at most SENT_MAX: {at, from, fromKey, to, toKey, subject, gold, diamonds, cod, items}
  function sentLog(characters, limit = SENT_MAX) {
    const known = new Set(characters.map(character => character.key));
    const list = [];
    for (const sender of characters) {
      for (const item of Array.isArray(sender.mail?.sent) ? sender.mail.sent : []) {
        const toKey = keyOf(item.to, serverOf(sender));
        list.push({at: Number(item.at) || 0, from: String(sender.name || ''), fromKey: sender.key || '', to: String(item.to || ''), toKey: known.has(toKey) ? toKey : '',
          subject: String(item.subject || ''), gold: Number(item.gold) || 0, diamonds: Number(item.diamonds) || 0, cod: Number(item.cod) || 0, items: String(item.items || '')});
      }
    }
    return list.sort((a, b) => b.at - a.at || a.from.localeCompare(b.from)).slice(0, limit);
  }
  // 3 days, 14 h, 25 min, or gone
  function timeLeft(expires, now = Date.now() / 1000) {
    const seconds = expires - now;
    if (!expires) return 'not known';
    if (seconds <= 0) return 'gone';
    if (seconds >= 2 * 86400) return `${Math.floor(seconds / 86400)} days`;
    if (seconds >= 3600) return `${Math.floor(seconds / 3600)} h`;
    return `${Math.max(1, Math.floor(seconds / 60))} min`;
  }
  // The line for a character's hover card and its details, or '' when nothing waits
  function summary(box, now = Date.now() / 1000, gold = number) {
    if (!box?.count) return '';
    const parts = [`${number(box.count)} ${box.count === 1 ? 'mail' : 'mails'} waiting`];
    if (box.gold) parts.push(`${gold(box.gold)} gold`);
    if (box.diamonds) parts.push(`${number(box.diamonds)} diamonds`);
    if (box.soonest) parts.push(`${box.expiring ? 'one expires in' : 'the first expires in'} ${timeLeft(box.soonest, now)}`);
    return parts.join(' · ');
  }

  // The Mail page: its cards, the mail waiting, soonest gone first, and the mail sent, newest first.
  // options: {search, gold(amount): its short form, clock: an Intl.DateTimeFormat}
  function render(root, characters, options = {}) {
    const now = Date.now() / 1000;
    const boxes = mailboxes(characters, now);
    const sum = totals(boxes, characters);
    const sent = sentLog(characters);
    const gold = options.gold || number;
    const clock = options.clock || new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    const when = seconds => (seconds ? clock.format(seconds * 1000) : 'not known');
    const wanted = lower(String(options.search || '').trim());
    const matches = (...texts) => !wanted || texts.some(text => lower(text).includes(wanted));
    const card = (label, value, help, warn) => `<div class="currency-card${warn ? ' is-warn' : ''}"><div class="currency-label">${escapeHtml(label)}</div>`
      + `<div class="currency-value">${escapeHtml(value)}</div><div class="currency-help">${escapeHtml(help)}</div></div>`;
    root.querySelector('#mail-summary').innerHTML = [
      card('Mail waiting', number(sum.mails), `for ${number(sum.characters)} characters${sum.estimated ? ` · ${number(sum.estimated)} sent since their mailbox was open` : ''}`),
      card('Gold in mailboxes', gold(sum.gold), sum.estimated ? 'an estimate: it counts mail sent since each mailbox was open' : 'as each mailbox was when last open'),
      card('Expiring within 48 hours', number(sum.expiring), sum.expiring ? `on ${number(sum.withExpiring)} characters: take it before the game sends it back` : 'nothing soon', sum.expiring > 0),
      card('Sent mail kept', number(sent.length), `the newest ${number(SENT_MAX)} at most · ${number(sum.read)} mailboxes read`),
    ].join('');
    const rows = [];
    for (const character of characters) {
      const box = boxes.get(character.key);
      for (const mail of box?.waiting || []) {
        if (!matches(character.name, mail.from, mail.subject, mail.itemText)) continue;
        rows.push({character, mail});
      }
    }
    rows.sort((a, b) => (a.mail.expires || Infinity) - (b.mail.expires || Infinity) || a.character.name.localeCompare(b.character.name));
    const waitingBody = rows.slice(0, 2000).map(({character, mail}) => {
      const soon = mail.expires && mail.expires - now <= SOON;
      const what = [mail.items ? `${number(mail.items)} ${mail.items === 1 ? 'item' : 'items'}` : '', mail.itemText, mail.cod ? `C.O.D. ${number(mail.cod)}` : ''].filter(Boolean).join(' · ');
      const source = mail.seen ? (mail.returned ? 'returned to it' : 'in its mailbox') : `sent ${when(mail.sent)}, mailbox not open since`;
      return `<tr class="${soon ? 'is-soon' : ''}"><td><span class="char-name" data-char="${escapeHtml(character.key || '')}">${escapeHtml(character.name)}</span></td>`
        + `<td>${escapeHtml(mail.from)}</td><td>${escapeHtml(mail.subject)}</td><td class="num">${mail.gold ? `<span class="gold-cell">${escapeHtml(number(mail.gold))}</span>` : ''}</td>`
        + `<td>${escapeHtml(what)}</td><td class="num" title="${escapeHtml(mail.expires ? when(mail.expires) : '')}">${soon ? '<span class="mail-soon" aria-hidden="true">!</span> ' : ''}${escapeHtml(timeLeft(mail.expires, now))}</td>`
        + `<td class="hint">${escapeHtml(source)}</td></tr>`;
    });
    if (!waitingBody.length) waitingBody.push(`<tr><td colspan="7" class="hint">${sum.read || sent.length ? 'Nothing is waiting.' : 'No mailbox read yet: open a mailbox in game with Global Bank 1.6.2 or newer.'}</td></tr>`);
    root.querySelector('#mail-waiting tbody').innerHTML = waitingBody.join('');
    const sentBody = sent.filter(item => matches(item.from, item.to, item.subject, item.items)).map(item => {
      const to = item.toKey ? `<span class="char-name" data-char="${escapeHtml(item.toKey)}">${escapeHtml(item.to)}</span>` : escapeHtml(item.to);
      return `<tr><td>${escapeHtml(when(item.at))}</td><td><span class="char-name" data-char="${escapeHtml(item.fromKey)}">${escapeHtml(item.from)}</span></td><td>${to}</td>`
        + `<td>${escapeHtml(item.subject)}</td><td class="num">${item.gold ? `<span class="gold-cell">${escapeHtml(number(item.gold))}</span>` : ''}</td>`
        + `<td>${escapeHtml([item.items, item.diamonds ? `${number(item.diamonds)} diamonds` : '', item.cod ? `C.O.D. ${number(item.cod)}` : ''].filter(Boolean).join(' · '))}</td></tr>`;
    });
    if (!sentBody.length) sentBody.push('<tr><td colspan="6" class="hint">No sent mail recorded yet: mail sent with Global Bank 1.6.2 or newer shows here.</td></tr>');
    root.querySelector('#mail-sent tbody').innerHTML = sentBody.join('');
    root.querySelector('#mail-waiting-count').textContent = rows.length ? number(rows.length) : '';
    root.querySelector('#mail-sent-count').textContent = sent.length ? number(sent.length) : '';
  }

  return {MAIL_DAYS, SOON, SENT_MAX, mailboxes, totals, sentLog, timeLeft, summary, render, holds};
})();
