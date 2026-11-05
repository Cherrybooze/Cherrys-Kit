'use strict';
// Mail: what each mailbox held when its character last had it open, and the mail your characters sent since, which
// is on its way to the others. The game only shows a mailbox while it's open, so a mailbox's gold is known as of then,
// and the mail sent after that is added as an estimate. Times are seconds since 1970, as the game's os.time() gives.
const GBMail = (() => {
  // How long a mail waits before the game returns it. A mailbox says exactly; for mail sent since, this is a guess.
  const MAIL_DAYS = 30;
  const SOON = 48 * 3600;
  // The most sent mail the page keeps, newest first: the game keeps as many for each character
  const SENT_MAX = 2400;
  // Mail saved before Global Bank 1.6.14 has no send number: one after another to the same name, this close
  // together when both times are known, counts as one send
  const OLD_SEND_GAP = 120;
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
  // A sent mail's items: [{name, id, count, icon, plus, tier, stats, runes}]. Global Bank 1.6.14 saves each item's
  // details (name*id*count*icon*plus*tier*stats*runes, "^" between items); older mail has only "Name x3, Other".
  function sentItems(item) {
    const details = String(item.details || '');
    if (details) {
      return details.split('^').filter(Boolean).map(text => {
        const [name = '', id = '', count = '1', icon = '', plus = '0', tier = '0', stats = '', runes = ''] = text.split('*');
        return {name, id: id.startsWith('n:') ? '' : id, count: Math.max(1, Number(count) || 1), icon, plus: Number(plus) || 0, tier: Number(tier) || 0,
          stats: stats ? stats.split(';').filter(Boolean) : [], runes: runes ? runes.split(';').filter(Boolean) : []};
      });
    }
    return String(item.items || '').split(', ').filter(Boolean).map(text => {
      const match = /^(.*) x(\d+)$/.exec(text);
      return {name: match ? match[1] : text, id: '', count: match ? Number(match[2]) : 1, icon: '', plus: 0, tier: 0, stats: [], runes: []};
    });
  }

  // The newest sent mail of everyone shown, at most SENT_MAX: {at, from, fromKey, to, toKey, subject, gold, diamonds, cod,
  // items: the names as text, list: sentItems, send: the send it was part of, '' when not saved, order: its place in
  // the sender's list, oldest 0}
  function sentLog(characters, limit = SENT_MAX) {
    const known = new Set(characters.map(character => character.key));
    const list = [];
    for (const sender of characters) {
      const sent = Array.isArray(sender.mail?.sent) ? sender.mail.sent : [];
      sent.forEach((item, order) => {
        const toKey = keyOf(item.to, serverOf(sender));
        list.push({at: Number(item.at) || 0, from: String(sender.name || ''), fromKey: sender.key || '', to: String(item.to || ''), toKey: known.has(toKey) ? toKey : '',
          subject: String(item.subject || ''), gold: Number(item.gold) || 0, diamonds: Number(item.diamonds) || 0, cod: Number(item.cod) || 0, items: String(item.items || ''),
          list: sentItems(item), send: Number(item.send) > 0 ? Number(item.send) : '', order});
      });
    }
    // Mail of unknown time keeps its order within each sender, newest first, after everything with a time
    return list.sort((a, b) => b.at - a.at || a.from.localeCompare(b.from) || b.order - a.order).slice(0, limit);
  }

  // A subject without the "(2/5)" the mail window adds to a long letter's parts
  const subjectStem = subject => String(subject || '').replace(/\s*\(\d+\/\d+\)\s*$/, '');
  // What tells two copies of an item apart in a send's summary
  const itemKey = item => [item.id || lower(item.name), item.plus, item.tier, item.stats.join(';'), item.runes.join(';')].join('|');

  // The sent mail as sends: the mails that went together, one after another. Newest first:
  // {at, from, fromKey, mails (newest first), to: [{name, key}], subject, gold, diamonds, cod, items (summed), count}
  function sentSends(log) {
    const bySender = new Map();
    for (const mail of log) {
      if (!bySender.has(mail.fromKey + '|' + mail.from)) bySender.set(mail.fromKey + '|' + mail.from, []);
      bySender.get(mail.fromKey + '|' + mail.from).push(mail);
    }
    const sends = [];
    for (const mails of bySender.values()) {
      mails.sort((a, b) => a.order - b.order);
      let current = null;
      for (const mail of mails) {
        const last = current?.mails.at(-1);
        const together = last && (mail.send || last.send
          ? mail.send === last.send
          : lower(mail.to) === lower(last.to) && (!mail.at || !last.at ? !mail.at && !last.at : Math.abs(mail.at - last.at) <= OLD_SEND_GAP));
        if (!together) {
          current = {mails: []};
          sends.push(current);
        }
        current.mails.push(mail);
      }
    }
    for (const send of sends) {
      const mails = send.mails;
      const newest = mails.at(-1);
      send.at = Math.max(...mails.map(mail => mail.at));
      send.first = Math.min(...mails.map(mail => mail.at || Infinity));
      send.from = newest.from;
      send.fromKey = newest.fromKey;
      send.order = newest.order;
      send.count = mails.length;
      const to = new Map();
      for (const mail of mails) if (!to.has(lower(mail.to))) to.set(lower(mail.to), {name: mail.to, key: mail.toKey});
      send.to = [...to.values()];
      const stems = new Set(mails.map(mail => subjectStem(mail.subject)));
      send.subject = stems.size === 1 ? [...stems][0] : '';
      send.gold = send.diamonds = send.cod = 0;
      const items = new Map();
      for (const mail of mails) {
        send.gold += mail.gold;
        send.diamonds += mail.diamonds;
        send.cod += mail.cod;
        for (const item of mail.list) {
          const key = itemKey(item);
          if (items.has(key)) items.get(key).count += item.count;
          else items.set(key, {...item});
        }
      }
      send.items = [...items.values()];
      send.mails = mails.slice().reverse();
    }
    return sends.sort((a, b) => b.at - a.at || a.from.localeCompare(b.from) || b.order - a.order);
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

  // An item's picture as the Bank page draws one, its icon filled in once loaded; its count and plus in the corners
  function itemSlot(item, icon) {
    return `<span class="bank-slot filled mail-item" data-mail-item="${escapeHtml(JSON.stringify(item))}">`
      + (icon ? `<img data-icon="${escapeHtml(icon)}" alt="">` : `<span class="bank-letters">${escapeHtml(item.name.slice(0, 2))}</span>`)
      + (item.tier > 0 ? `<span class="bank-mark bank-mark-tier">T${item.tier}</span>` : '')
      + (item.plus > 0 ? `<span class="bank-mark bank-mark-plus">+${item.plus}</span>` : '')
      + (item.count > 1 ? `<span class="bank-count">${item.count > 9999 ? `${Math.floor(item.count / 1000)}k` : item.count}</span>` : '') + '</span>';
  }
  // Icons for items saved without one, by name, from what the characters hold now
  function iconsByName(characters) {
    const icons = new Map();
    for (const character of characters) {
      for (const item of [].concat(character.bag || [], character.bank || [])) {
        const name = lower(item.name);
        if (name && item.icon && !icons.has(name)) icons.set(name, String(item.icon));
      }
    }
    return icons;
  }

  // The Mail page: its cards, the mail waiting, soonest gone first, and the mail sent, newest first.
  // options: {search, sentSearch: the Sent list's own search, compact: the Sent list as sends, open: the sends shown
  // opened (a Set of their keys), gold(amount): its short form, clock: an Intl.DateTimeFormat}. Returns the icons
  // the Sent list wants.
  function render(root, characters, options = {}) {
    const now = Date.now() / 1000;
    const boxes = mailboxes(characters, now);
    const sum = totals(boxes, characters);
    const sent = sentLog(characters);
    const gold = options.gold || number;
    const clock = options.clock || new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'});
    const when = seconds => (seconds ? clock.format(seconds * 1000) : 'not known');
    const hours = options.hours || new Intl.DateTimeFormat(undefined, {timeStyle: 'short'});
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
    const own = lower(String(options.sentSearch || '').trim());
    const mailMatches = item => {
      const texts = [item.from, item.to, item.subject, item.items, ...item.list.flatMap(entry => [entry.name, ...entry.stats, ...entry.runes])];
      return matches(...texts) && (!own || texts.some(text => lower(text).includes(own)));
    };
    const charName = (name, key) => (key ? `<span class="char-name" data-char="${escapeHtml(key)}">${escapeHtml(name)}</span>` : escapeHtml(name));
    const money = item => [item.diamonds ? `${number(item.diamonds)} diamonds` : '', item.cod ? `C.O.D. ${number(item.cod)}` : ''].filter(Boolean).join(' · ');
    const names = iconsByName(characters);
    const icons = new Set();
    const iconOf = item => {
      const icon = item.icon || names.get(lower(item.name)) || '';
      if (icon) icons.add(icon);
      return icon;
    };
    const itemsCell = list => (list.length ? `<span class="mail-items">${list.slice(0, 24).map(item => itemSlot(item, iconOf(item))).join('')}`
      + `${list.length > 24 ? `<span class="hint">+${number(list.length - 24)}</span>` : ''}</span>` : '');
    const table = root.querySelector('#mail-sent');
    table.classList.toggle('is-compact', !!options.compact);
    let sentBody, shownCount;
    if (options.compact) {
      table.querySelector('thead').innerHTML = '<tr><th>When</th><th>From</th><th>To</th><th>Subject</th><th class="num">Gold</th><th>Items</th></tr>';
      const open = options.open || new Set();
      const sends = sentSends(sent).filter(send => send.mails.some(mailMatches));
      shownCount = sends.length;
      sentBody = sends.slice(0, 1000).map(send => {
        const key = `${send.fromKey}|${send.order}`;
        const opened = open.has(key) && send.count > 1;
        const spread = send.at && send.first !== Infinity && send.at - send.first >= 60;
        const whenText = spread ? `${when(send.first)} – ${hours.format(send.at * 1000)}` : when(send.at);
        const to = send.to.length === 1 ? charName(send.to[0].name, send.to[0].key)
          : `<span title="${escapeHtml(send.to.map(item => item.name).join(', '))}">${number(send.to.length)} characters</span>`;
        const subject = send.count > 1
          ? `<button type="button" class="link-button mail-send-toggle" data-send="${escapeHtml(key)}" aria-expanded="${opened}">${opened ? '▾' : '▸'} ${number(send.count)} mails</button>${send.subject ? ` ${escapeHtml(send.subject)}` : ''}`
          : escapeHtml(send.mails[0].subject);
        const head = `<tr class="mail-send${opened ? ' is-open' : ''}"><td>${escapeHtml(whenText)}</td>`
          + `<td>${charName(send.from, send.fromKey)}</td><td>${to}</td><td>${subject}</td>`
          + `<td class="num">${send.gold ? `<span class="gold-cell">${escapeHtml(number(send.gold))}</span>` : ''}</td>`
          + `<td>${itemsCell(send.items)}${money(send) ? `<span class="hint mail-money">${escapeHtml(money(send))}</span>` : ''}</td></tr>`;
        if (!opened) return head;
        return head + send.mails.map(mail => `<tr class="mail-send-part"><td class="hint">${escapeHtml(when(mail.at))}</td><td></td><td>${charName(mail.to, mail.toKey)}</td>`
          + `<td>${escapeHtml(mail.subject)}</td><td class="num">${mail.gold ? `<span class="gold-cell">${escapeHtml(number(mail.gold))}</span>` : ''}</td>`
          + `<td>${itemsCell(mail.list)}${money(mail) ? `<span class="hint mail-money">${escapeHtml(money(mail))}</span>` : ''}</td></tr>`).join('');
      });
    } else {
      table.querySelector('thead').innerHTML = '<tr><th>When</th><th>From</th><th>To</th><th>Subject</th><th class="num">Gold</th><th>Items</th></tr>';
      const shown = sent.filter(mailMatches);
      shownCount = shown.length;
      sentBody = shown.map(item => `<tr><td>${escapeHtml(when(item.at))}</td><td>${charName(item.from, item.fromKey)}</td><td>${charName(item.to, item.toKey)}</td>`
        + `<td>${escapeHtml(item.subject)}</td><td class="num">${item.gold ? `<span class="gold-cell">${escapeHtml(number(item.gold))}</span>` : ''}</td>`
        + `<td>${escapeHtml([item.items, money(item)].filter(Boolean).join(' · '))}</td></tr>`);
    }
    if (!sentBody.length) {
      sentBody.push(`<tr><td colspan="6" class="hint">${sent.length ? 'No sent mail matches the search.' : 'No sent mail recorded yet: mail sent with Global Bank 1.6.2 or newer shows here.'}</td></tr>`);
    }
    table.querySelector('tbody').innerHTML = sentBody.join('');
    root.querySelector('#mail-waiting-count').textContent = rows.length ? number(rows.length) : '';
    const unit = options.compact ? (shownCount === 1 ? 'send' : 'sends') : (shownCount === 1 ? 'mail' : 'mails');
    root.querySelector('#mail-sent-count').textContent = sent.length ? (shownCount === sent.length && !options.compact ? number(sent.length) : `${number(shownCount)} ${unit}`) : '';
    return [...icons];
  }

  // A sent item's hover card: its name, count, tier and plus, stats and runes, as the Bank page's tooltip shows them
  function itemTip(item) {
    const lines = [`<strong>${escapeHtml(item.name)}${item.count > 1 ? ` ×${number(item.count)}` : ''}</strong>`];
    const levels = [item.plus > 0 ? `+${item.plus}` : '', item.tier > 0 ? `Tier +${item.tier}` : ''].filter(Boolean);
    if (levels.length) lines.push(`<span class="bank-tip-type">${escapeHtml(levels.join(' · '))}</span>`);
    if (item.stats.length) lines.push(`<span>Stats: ${escapeHtml(item.stats.join(', '))}</span>`);
    if (item.runes.length) lines.push(`<span>Runes: ${escapeHtml(item.runes.join(', '))}</span>`);
    if (!item.stats.length && !item.runes.length && !item.icon) lines.push('<span class="bank-tip-hint">Sent before Global Bank 1.6.14, which saves its picture and stats.</span>');
    if (/^\d+$/.test(String(item.id || ''))) lines.push(`<span class="bank-tip-hint">Item ${escapeHtml(item.id)}</span>`);
    return lines.join('');
  }

  return {MAIL_DAYS, SOON, SENT_MAX, mailboxes, totals, sentLog, sentItems, sentSends, timeLeft, summary, render, itemTip, holds};
})();
