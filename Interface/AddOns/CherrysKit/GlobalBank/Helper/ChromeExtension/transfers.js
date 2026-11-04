'use strict';
// Character transfers. The Runes of Magic site's character transfer page (the Gameforge client's gear icon, then
// Transfer your character) lists the transfers an account has planned. The game carries one out in the next server
// maintenance, which this takes to be on Thursdays, and the characters' own saves show afterwards where they are.
// The background reads the site's page with this; the Global Bank page draws the plates, the log and the moved
// characters with it. Nothing here leaves this PC: the records stay in this extension's own storage.
const GBTransfers = (() => {
  const STORE = 'gbTransfers';
  const MAINTENANCE_STORE = 'gbMaintenance';
  // German time: Gameforge's European servers keep it
  const ZONE = 'Europe/Berlin';
  // Thursday at 09:00, until the page is told otherwise
  const MAINTENANCE = {day: 4, hour: 9, minute: 0};
  const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const MAX_RECORDS = 300;
  const MAX_EVENTS = 12;
  const MAX_ACCOUNT = 60;
  const MINUTE = 60000, HOUR = 60 * MINUTE, DAY = 24 * HOUR;
  // What a tab read this recently still tells about what that tab showed before
  const TAB_MEMORY = 30 * MINUTE;
  // A transfer taken for cancelled that the site lists again this soon never was, unless the site's form offered its
  // character again in between: then the player cancelled it and registered it once more
  const UNDO_CANCEL = 14 * DAY;
  // The servers the game lists, so that a server's name on the site's page can be told from a character's
  const SERVERS = ['Aynara', 'Kadmos', 'Kerub', 'Gaia', 'Svidur', 'Ayvenas'];
  const STATES = new Set(['planned', 'cancelled', 'moved', 'done', 'stayed']);

  const squash = text => String(text ?? '').replace(/\s+/g, ' ').trim();
  const lower = text => String(text ?? '').toLowerCase();
  // "Gaia (PvE)", as the site writes it, and "Gaia", as the game does, are the same server.
  const cleanServer = text => squash(text).replace(/\s*\(.*\)\s*$/, '').trim();
  const keyOf = (name, server) => `${lower(cleanServer(server))}|${lower(name)}`;
  const sameServer = (a, b) => lower(cleanServer(a)) === lower(cleanServer(b));
  const NAME = /^[^\s()<>"'`\\|~;,:#&]{2,32}$/u;
  const SERVER_NAME = /^[^()<>"'`\\|~;:#&]{2,40}$/u;
  const iso = ms => new Date(ms).toISOString();
  const timeOf = text => {
    const ms = Date.parse(text || '');
    return Number.isFinite(ms) ? ms : 0;
  };
  // "2026-11-04 08:12", the PC's own time when the game saved: the helper writes the save file's time like that
  function savedTime(character) {
    const found = /^(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d)/.exec(String(character?.saved || ''));
    return found ? new Date(+found[1], found[2] - 1, +found[3], +found[4], +found[5]).getTime() : 0;
  }

  // The clock. German wall-clock time for a moment, and the moment for a German wall-clock time.
  let zoneFormat = null;
  function zoneParts(ms) {
    zoneFormat = zoneFormat || new Intl.DateTimeFormat('en-US', {timeZone: ZONE, hourCycle: 'h23', year: 'numeric', month: 'numeric', day: 'numeric',
      hour: 'numeric', minute: 'numeric', second: 'numeric'});
    const parts = {};
    for (const part of zoneFormat.formatToParts(new Date(ms))) parts[part.type] = part.value;
    return {year: +parts.year, month: +parts.month, day: +parts.day, hour: +parts.hour % 24, minute: +parts.minute, second: +parts.second};
  }
  // Minutes German time is ahead of UTC at that moment
  function zoneOffset(ms) {
    const p = zoneParts(ms);
    return Math.round((Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - Math.floor(ms / 1000) * 1000) / MINUTE);
  }
  function zoned(year, month, day, hour, minute) {
    const wall = Date.UTC(year, month - 1, day, hour, minute);
    const first = wall - zoneOffset(wall) * MINUTE;
    return wall - zoneOffset(first) * MINUTE;
  }
  // The weekly maintenance as stored, or Thursday 09:00
  function maintenanceOf(value) {
    const whole = (number, low, high, fallback) => (Number.isInteger(number) && number >= low && number <= high ? number : fallback);
    return {day: whole(value?.day, 0, 6, MAINTENANCE.day), hour: whole(value?.hour, 0, 23, MAINTENANCE.hour), minute: whole(value?.minute, 0, 59, MAINTENANCE.minute)};
  }
  // The first maintenance to start after that moment
  function nextMaintenance(ms, maintenance) {
    const plan = maintenanceOf(maintenance);
    const today = zoneParts(ms);
    for (let add = 0; add <= 8; add++) {
      const date = new Date(Date.UTC(today.year, today.month - 1, today.day + add));
      if (date.getUTCDay() !== plan.day) continue;
      const at = zoned(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate(), plan.hour, plan.minute);
      if (at > ms) return at;
    }
    return ms + 7 * DAY;
  }
  // When a planned transfer is due: the first maintenance after the site last listed it, which moves on by a week each
  // time the site still lists it after one
  const dueOf = (record, maintenance) => nextMaintenance(Math.max(timeOf(record.at), timeOf(record.seen)), maintenance);

  // The site's page. A server's name and what follows it in brackets: "Kadmos (PvE)". null when it can't be one.
  function serverName(text) {
    const found = /^([^()]+?)\s*(?:\(\s*([^()]*?)\s*\))?$/.exec(squash(text));
    if (!found) return null;
    const name = found[1].trim();
    return SERVER_NAME.test(name) && name.split(' ').length <= 3 ? {name, tag: found[2] || ''} : null;
  }
  // A server the page names: one the game or the page's own server list has, or a single word with (PvE) or (PvP)
  // after it, as the site writes servers. '' when it isn't one: "to Kadmos (PvE)" in a sentence is no server.
  function serverLabel(text, known) {
    const found = serverName(text);
    if (!found) return '';
    if (known.has(lower(found.name))) return found.name;
    return /^\p{Lu}[\p{L}\p{N}'-]{1,24}$/u.test(found.name) && /^Pv[EP]$/i.test(found.tag) ? found.name : '';
  }
  // A character as it writes one: "Zuuzuuhehtne (Gaia (PvE))". null when it isn't one.
  function characterLabel(text, known) {
    const found = /^([^\s()]+)\s*\(\s*(.+?)\s*\)$/.exec(squash(text));
    if (!found || !NAME.test(found[1]) || !/^\p{L}/u.test(found[1])) return null;
    const server = serverLabel(found[2], known);
    return server ? {name: found[1], server} : null;
  }
  const decorative = text => !/[\p{L}\p{N}]/u.test(text);
  // A label the page split over a few pieces of text: the shortest run that reads as one
  function labelAt(texts, at, read, most) {
    for (let take = 1; take <= most && at + take <= texts.length; take++) {
      const found = read(texts.slice(at, at + take).join(' '));
      if (found) return {found, next: at + take};
    }
    return null;
  }
  // page: {selects: the options of each list on the page, texts: the page's text outside those lists, in order}.
  // planned: the transfers it lists, a character then the server it goes to; offered: the characters its form offers,
  // each on its server; form: whether that form was there.
  function parsePage(page) {
    const lists = (Array.isArray(page?.selects) ? page.selects : []).slice(0, 20).map(options => (Array.isArray(options) ? options : []).slice(0, 400).map(squash));
    const texts = (Array.isArray(page?.texts) ? page.texts : []).slice(0, 4000).map(squash).filter(Boolean);
    const known = new Set(SERVERS.map(lower));
    // The list of servers first: its names tell the characters' list apart
    const share = (options, test) => options.length > 0 && options.filter(test).length >= Math.ceil(options.length * 0.6);
    const serverList = lists.findIndex(options => share(options, text => serverLabel(text, known) && !characterLabel(text, known)));
    // Its servers are servers, even ones of more than a word, once they say PvE or PvP
    if (serverList >= 0) {
      for (const text of lists[serverList]) {
        const found = serverName(text);
        if (found && (serverLabel(text, known) || /^Pv[EP]$/i.test(found.tag))) known.add(lower(found.name));
      }
    }
    const characterList = lists.findIndex((options, index) => index !== serverList && share(options, text => characterLabel(text, known)));
    const offered = [];
    if (characterList >= 0) {
      for (const text of lists[characterList]) {
        const who = characterLabel(text, known);
        if (who) offered.push({name: who.name, server: who.server});
      }
    }
    const planned = [], seen = new Set();
    for (let at = 0; at < texts.length; at++) {
      const who = labelAt(texts, at, text => characterLabel(text, known), 4);
      if (!who) continue;
      let next = who.next;
      while (next < texts.length && next < who.next + 3 && decorative(texts[next])) next++;
      const target = labelAt(texts, next, text => serverLabel(text, known), 3);
      if (!target || sameServer(target.found, who.found.server)) continue;
      const key = `${keyOf(who.found.name, who.found.server)}>${lower(target.found)}`;
      if (!seen.has(key)) {
        seen.add(key);
        planned.push({name: who.found.name, from: who.found.server, to: target.found});
      }
      at = target.next - 1;
    }
    return {planned, offered, form: characterList >= 0 || serverList >= 0};
  }
  // A read from the site's page, as the background gets it, checked again; null when it isn't one
  function cleanRead(message) {
    if (!Array.isArray(message?.planned) || !Array.isArray(message?.offered) || message.planned.length > 40 || message.offered.length > 400) return null;
    const read = {planned: [], offered: [], form: message.form === true};
    for (const item of message.planned) {
      const name = String(item?.name ?? ''), from = cleanServer(item?.from), to = cleanServer(item?.to);
      if (NAME.test(name) && SERVER_NAME.test(from) && SERVER_NAME.test(to) && !sameServer(from, to)) read.planned.push({name, from, to});
    }
    for (const item of message.offered) {
      const name = String(item?.name ?? ''), server = cleanServer(item?.server);
      if (NAME.test(name) && SERVER_NAME.test(server)) read.offered.push({name, server});
    }
    return read;
  }

  // The records. Each: {id, name, from, to, state, at: registered, or first found planned; seen: last listed as planned;
  // here: seen being registered in this Chrome; ended: when it stopped being planned; offered: when the site's form
  // offered its character again after that; done: when it logged in on its new server; account: the characters the site
  // listed with it, server|name; events: [{at, what, text}]}.
  // States: planned, cancelled, moved (gone from its old server: a login on the new one confirms it), done, stayed (still
  // on its old server after the maintenance).
  function validRecord(record) {
    return !!record && typeof record.id === 'string' && /^[a-z0-9]{6,24}$/.test(record.id) && NAME.test(String(record.name)) && SERVER_NAME.test(String(record.from))
      && SERVER_NAME.test(String(record.to)) && STATES.has(record.state) && timeOf(record.at) > 0;
  }
  function load(stored) {
    const list = Array.isArray(stored?.list) ? stored.list.filter(validRecord).map(record => JSON.parse(JSON.stringify(record))) : [];
    for (const record of list) {
      record.events = Array.isArray(record.events) ? record.events.filter(item => item && typeof item.text === 'string' && timeOf(item.at)) : [];
      record.account = Array.isArray(record.account) ? record.account.filter(key => typeof key === 'string').slice(0, MAX_ACCOUNT) : [];
    }
    return {v: 1, list};
  }
  function newId() {
    const bytes = new Uint8Array(8);
    crypto.getRandomValues(bytes);
    return Array.from(bytes, value => (value % 36).toString(36)).join('') + Date.now().toString(36).slice(-4);
  }
  function note(record, at, what, text) {
    record.events.push({at: iso(at), what, text: String(text).slice(0, 200)});
    // The first, how it began, and the newest
    if (record.events.length > MAX_EVENTS) record.events.splice(1, record.events.length - MAX_EVENTS);
  }
  function end(record, state, at, text) {
    record.state = state;
    record.ended = iso(at);
    note(record, at, state, text);
  }
  const listed = (list, record) => list.some(item => keyOf(item.name, item.from) === keyOf(record.name, record.from) && sameServer(item.to, record.to));
  function trim(list) {
    // Planned and moved ones stay; the oldest finished ones go first
    while (list.length > MAX_RECORDS) {
      let oldest = -1;
      list.forEach((record, index) => {
        if (record.state === 'planned' || record.state === 'moved') return;
        if (oldest < 0 || timeOf(record.at) < timeOf(list[oldest].at)) oldest = index;
      });
      list.splice(oldest < 0 ? list.length - 1 : oldest, 1);
    }
  }
  // What one read of the site's page changes. now: when; previous: what the same tab showed last, within half an hour,
  // or null. Returns {state, changed, added, ended}: the new records, whether anything changed, and what to tell the
  // player on the site.
  function applyRead(stored, read, {now = Date.now(), previous = null, maintenance = null} = {}) {
    const state = load(stored);
    const before = JSON.stringify(state);
    const records = state.list;
    const added = [], ended = [];
    const account = [...read.planned.map(item => keyOf(item.name, item.from)), ...read.offered.map(item => keyOf(item.name, item.server))];
    const accountKeys = new Set(account);
    const earlier = previous && now - (Number(previous.at) || 0) < TAB_MEMORY && Array.isArray(previous.planned) ? previous.planned : null;
    for (const item of read.planned) {
      let record = records.find(other => other.state === 'planned' && keyOf(other.name, other.from) === keyOf(item.name, item.from));
      // Registered again, for another server: the first one was cancelled
      if (record && !sameServer(record.to, item.to)) {
        end(record, 'cancelled', now, `Registered again, for ${item.to}`);
        ended.push(record);
        record = null;
      }
      // Listed again soon after it seemed to end, with no chance to register it in between: it never ended
      const finished = records.find(other => (other.state === 'cancelled' || other.state === 'stayed') && keyOf(other.name, other.from) === keyOf(item.name, item.from)
        && sameServer(other.to, item.to));
      if (!record && finished && !timeOf(finished.offered) && now - timeOf(finished.ended) < UNDO_CANCEL && now - timeOf(finished.ended) >= 0) {
        record = finished;
        record.state = 'planned';
        delete record.ended;
        note(record, now, 'planned', 'Listed as planned on the transfer page again');
      }
      if (!record) {
        const here = !!earlier && !listed(earlier, item);
        record = {id: newId(), name: item.name, from: item.from, to: item.to, state: 'planned', at: iso(now), seen: iso(now), here, account: [], events: []};
        note(record, now, 'registered', `${here ? 'Registered' : 'Found planned'}${finished ? ' again' : ''} on the transfer page`);
        records.unshift(record);
        added.push(record);
      } else if (timeOf(record.seen) && dueOf(record, maintenance) <= now) {
        note(record, now, 'waiting', 'Still planned on the transfer page after the maintenance it was due in');
      }
      record.seen = iso(now);
      record.account = [...new Set([...record.account, ...account])].slice(0, MAX_ACCOUNT);
    }
    // Planned ones this page no longer lists, where it speaks for their account: it offers the character, the same tab
    // listed it just before, or the page lists others from the same account
    for (const record of records) {
      if (record.state !== 'planned' || listed(read.planned, record)) continue;
      const onFrom = read.offered.some(item => keyOf(item.name, item.server) === keyOf(record.name, record.from));
      const onTo = read.offered.some(item => keyOf(item.name, item.server) === keyOf(record.name, record.to));
      const sameTab = !!earlier && listed(earlier, record);
      const sameAccount = record.account.some(key => accountKeys.has(key));
      if (!onFrom && !onTo && !sameTab && !sameAccount) continue;
      const before = now < dueOf(record, maintenance);
      if (onTo) end(record, 'moved', now, `The transfer page lists it on ${record.to}`);
      else if (onFrom && !before) end(record, 'stayed', now, `Still on ${record.from} after the maintenance: the transfer page offers it again`);
      else if (before) end(record, 'cancelled', now, sameTab ? 'Cancelled on the transfer page' : 'No longer planned on the transfer page');
      else end(record, 'moved', now, 'No longer planned on the transfer page after the maintenance');
      ended.push(record);
    }
    // A cancelled or stayed one whose character the form offers again: listed as planned from now on, it is a new
    // registration, not this one coming back
    for (const record of records) {
      if ((record.state === 'cancelled' || record.state === 'stayed') && !record.offered
        && read.offered.some(item => keyOf(item.name, item.server) === keyOf(record.name, record.from))) record.offered = iso(now);
    }
    trim(records);
    return {state, changed: JSON.stringify(state) !== before, added, ended};
  }

  // A maintenance can start late or run long: a save this long after the start it was due in is surely after it
  const AFTER_MAINTENANCE = 3 * HOUR;
  // What the characters' saves show, as changes for the background to keep: [{id, state, at, text}].
  // characters: as the page loaded them, so each one's own server and login screen list.
  function evidence(records, characters, {now = Date.now(), maintenance = null} = {}) {
    const byName = new Map();
    const all = [];
    for (const character of characters || []) {
      const name = lower(character.base ?? character.name);
      const save = {
        name: String(character.base ?? character.name),
        server: cleanServer(character.origin ? character.origin.server : character.server),
        roster: (character.origin ? character.origin.roster : character.roster) || [],
        saved: savedTime(character),
      };
      if (!byName.has(name)) byName.set(name, []);
      byName.get(name).push(save);
      all.push(save);
    }
    const lists = (save, name) => save.roster.some(other => lower(other) === name);
    const changes = [];
    for (const record of records || []) {
      if (record.state === 'done') continue;
      const since = timeOf(record.at);
      const name = lower(record.name);
      const saves = byName.get(name) || [];
      // Saved on its new server since it was registered: it moved, and has logged in there
      const arrived = saves.find(save => sameServer(save.server, record.to) && save.saved > since && save.saved <= now + DAY);
      if (arrived) {
        changes.push({id: record.id, state: 'done', at: arrived.saved, text: `Logged in on ${record.to}: transfer confirmed`});
        continue;
      }
      if (record.state !== 'planned') continue;
      // On its new server's login screen: a character there logged in after it was registered, and its list has it.
      // Names are one to a server, so that is this one.
      const listedThere = all.find(save => sameServer(save.server, record.to) && save.saved > since && save.saved <= now + DAY && lists(save, name));
      if (listedThere) {
        changes.push({id: record.id, state: 'moved', at: listedThere.saved, text: `${record.to}'s login screen lists it: ${listedThere.name} logged in there`});
        continue;
      }
      // The login screen of its old server, from its account's characters there that logged in after it was registered
      const own = saves.find(save => sameServer(save.server, record.from));
      const mates = new Set([...(own ? own.roster : []).map(lower),
        ...record.account.filter(key => key.startsWith(`${lower(cleanServer(record.from))}|`)).map(key => key.slice(key.indexOf('|') + 1))]);
      mates.delete(name);
      const late = dueOf(record, maintenance) + AFTER_MAINTENANCE;
      let gone = null, there = null;
      for (const mate of mates) {
        for (const save of byName.get(mate) || []) {
          if (!sameServer(save.server, record.from) || !(save.saved > since) || !save.roster.length) continue;
          // That list no longer has it: gone
          if (!lists(save, name)) gone = gone || save;
          // Still there, well after the maintenance it was due in: it didn't move
          else if (save.saved > late && save.saved <= now + DAY) there = there || save;
        }
      }
      if (gone) {
        changes.push({id: record.id, state: 'moved', at: gone.saved, text: `${record.from}'s login screen no longer lists it: ${gone.name} logged in there`});
        continue;
      }
      // It logged in on its old server itself, well after that maintenance
      const stayed = own && own.saved > since && own.saved > late && own.saved <= now + DAY ? own : there;
      if (stayed) changes.push({id: record.id, state: 'stayed', at: stayed.saved, text: stayed === own ? `Logged in on ${record.from} after the maintenance it was due in: it didn't move`
        : `${record.from}'s login screen still lists it after the maintenance it was due in: ${stayed.name} logged in there`});
    }
    return changes;
  }
  // Changes from the Global Bank page, checked again: what its characters' saves showed, or a record forgotten
  function cleanChanges(list) {
    if (!Array.isArray(list) || !list.length || list.length > 100) return null;
    const changes = [];
    for (const change of list) {
      if (typeof change?.id !== 'string' || !/^[a-z0-9]{6,24}$/.test(change.id) || !['moved', 'stayed', 'done', 'forget'].includes(change.state)) return null;
      const at = Number(change.at);
      changes.push({id: change.id, state: change.state, at: Number.isFinite(at) && at > 0 ? at : Date.now(), text: String(change.text ?? '').slice(0, 200)});
    }
    return changes;
  }
  function applyChanges(stored, changes, now = Date.now()) {
    const state = load(stored);
    const before = JSON.stringify(state);
    for (const change of changes) {
      const index = state.list.findIndex(record => record.id === change.id);
      if (index < 0) continue;
      const record = state.list[index];
      const at = Math.min(change.at, now);
      if (change.state === 'forget') state.list.splice(index, 1);
      else if (change.state === 'moved' && record.state === 'planned') end(record, 'moved', at, change.text || 'Gone from its old server');
      else if (change.state === 'stayed' && record.state === 'planned') end(record, 'stayed', at, change.text || 'Still on its old server after the maintenance');
      else if (change.state === 'done' && record.state !== 'done') {
        if (record.state === 'planned') record.ended = iso(at);
        record.state = 'done';
        record.done = iso(at);
        note(record, at, 'done', change.text || 'Logged in on its new server');
      }
    }
    return {state, changed: JSON.stringify(state) !== before};
  }

  // The page's characters, moved as the records say. One gone from its old server shows on its new one, with what it
  // carried, until it logs in there; then the copy its old server's save file keeps goes. The old server's login screen
  // lists stop naming it, so it isn't boxed with its old account. A transferred character nothing has saved yet gets a
  // row of its own from what the transfer page said: its name, its server and the plate, the rest left blank. Run
  // before every prepare: each time it starts again from what the characters saved themselves.
  function overlay(list, records) {
    for (const character of list) {
      if (!character.origin) character.origin = {server: character.server ?? '', roster: Array.isArray(character.roster) ? character.roster : [], mail: character.mail};
      else {
        character.server = character.origin.server;
        character.roster = character.origin.roster;
        character.mail = character.origin.mail;
      }
      delete character.transfer;
      delete character.formerKey;
    }
    const byName = new Map();
    for (const character of list) {
      const name = lower(character.base ?? character.name);
      if (!byName.has(name)) byName.set(name, []);
      byName.get(name).push(character);
    }
    const hidden = new Set();
    // The server a character saved, or else the one its daily reward named; failing both, one by that name with no
    // server at all is taken for it
    const serverOf = character => cleanServer(character.origin.server) || cleanServer(character.dailyLogin?.server);
    const on = (mine, server) => mine.find(character => sameServer(serverOf(character), server))
      || (mine.filter(character => !serverOf(character)).length === 1 ? mine.find(character => !serverOf(character)) : undefined);
    // Rows for characters nothing saved, one for each name and server
    const blank = [], placed = new Set();
    const placeholder = (mine, record, server, shown) => {
      const key = keyOf(record.name, server);
      if (placed.has(key) || mine.some(character => sameServer(serverOf(character), server))) return;
      placed.add(key);
      blank.push({name: record.name, server, roster: [], notSaved: true, fromTransfer: true, stale: false, transfer: shown,
        origin: {server: '', roster: [], mail: undefined}, ...(shown.carried ? {formerKey: keyOf(record.name, record.from)} : {})});
    };
    // Newest first, so a character's newest transfer is the one it shows
    const touched = new Set();
    for (const record of records || []) {
      if (!['planned', 'moved', 'done'].includes(record.state)) continue;
      const name = lower(record.name);
      const mine = byName.get(name) || [];
      const since = timeOf(record.at);
      const old = on(mine, record.from);
      const arrived = mine.find(character => sameServer(serverOf(character), record.to) && savedTime(character) > since);
      const shown = {id: record.id, state: record.state, name: record.name, from: record.from, to: record.to};
      if (record.state === 'planned') {
        if (old && !touched.has(old)) {
          old.transfer = shown;
          touched.add(old);
        } else if (!old) placeholder(mine, record, record.from, shown);
        continue;
      }
      if (!old && !arrived && record.state === 'moved') placeholder(mine, record, record.to, {...shown, carried: true});
      const gone = timeOf(record.ended || record.done) || Date.now();
      if (old && !touched.has(old)) {
        if (arrived || record.state === 'done') {
          // Its old server's copy, unless a new character took the name there since
          if (savedTime(old) <= gone) hidden.add(old);
        } else {
          old.server = record.to;
          old.roster = [];
          old.mail = undefined;
          old.transfer = {...shown, carried: true};
          old.formerKey = keyOf(record.name, record.from);
        }
        touched.add(old);
      }
      if (arrived && !touched.has(arrived)) {
        arrived.transfer = {...shown, state: 'done'};
        arrived.formerKey = keyOf(record.name, record.from);
        touched.add(arrived);
      }
      // The old login screen's lists name it no more, unless a character by that name is there again
      if (!old || hidden.has(old) || old.transfer?.carried) {
        for (const character of list) {
          if (!sameServer(character.origin.server, record.from) || character === old) continue;
          const roster = character.roster || [];
          if (roster.some(other => lower(other) === name)) character.roster = roster.filter(other => lower(other) !== name);
        }
      }
    }
    const kept = hidden.size ? list.filter(character => !hidden.has(character)) : list;
    return blank.length ? kept.concat(blank) : kept;
  }

  // How the page shows them
  let clocks = null;
  function clock() {
    if (!clocks) {
      clocks = {
        long: new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'}),
        short: new Intl.DateTimeFormat(undefined, {month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'}),
        day: new Intl.DateTimeFormat(undefined, {weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'}),
        german: new Intl.DateTimeFormat(undefined, {timeZone: ZONE, weekday: 'short', hour: '2-digit', minute: '2-digit'}),
      };
    }
    return clocks;
  }
  // "1d 23h 47m 12s", down to the second
  function countdown(ms) {
    let left = Math.max(0, Math.floor(ms / 1000));
    const days = Math.floor(left / 86400);
    left -= days * 86400;
    const hours = Math.floor(left / 3600);
    left -= hours * 3600;
    const minutes = Math.floor(left / 60);
    const seconds = left - minutes * 60;
    if (days) return `${days}d ${hours}h ${minutes}m ${seconds}s`;
    if (hours) return `${hours}h ${minutes}m ${seconds}s`;
    return minutes ? `${minutes}m ${seconds}s` : `${seconds}s`;
  }
  // "1d 3h", "3h 12m", "12m": for a table, where seconds would only flicker
  function roughly(ms) {
    const minutes = Math.max(0, Math.ceil(ms / MINUTE));
    const days = Math.floor(minutes / 1440), hours = Math.floor((minutes % 1440) / 60), rest = minutes % 60;
    if (days) return `${days}d ${hours}h`;
    if (hours) return `${hours}h ${rest}m`;
    return rest ? `${rest}m` : 'a moment';
  }
  const make = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  };
  // What a record is now: planned, due (its maintenance has passed, nothing has said where it is yet), moved, done,
  // cancelled or stayed
  function phase(record, now, maintenance) {
    if (record.state !== 'planned') return record.state;
    return now >= dueOf(record, maintenance) ? 'due' : 'planned';
  }
  const PHASE_NAMES = {planned: 'Planned', due: 'Due: log in to check', moved: 'Moved: log in to confirm', done: 'Done', cancelled: 'Cancelled', stayed: 'Didn’t move'};
  // The plate on a character's row, or null: "Xfer › Kadmos › Nov 4, 08:12"
  function plateOf(character, records, now = Date.now(), maintenance = null) {
    const shown = character?.transfer;
    if (!shown || shown.state === 'done') return null;
    const record = (records || []).find(item => item.id === shown.id);
    if (!record) return null;
    const kind = phase(record, now, maintenance);
    const when = clock().short.format(timeOf(record.at));
    const label = kind === 'moved' ? `Moved from ${record.from} to ${record.to}, registered ${when}: log in with it on ${record.to} to confirm`
      : kind === 'due' ? `Transfer to ${record.to}, registered ${when}, was due in the last maintenance`
        : `Transfer to ${record.to}, registered ${when}`;
    return {id: record.id, kind, to: record.to, from: record.from, when, label, confirm: kind === 'moved'};
  }
  // The hover card's line about it, or null
  function cardLine(character, records, now = Date.now(), maintenance = null) {
    const shown = character?.transfer;
    if (!shown) return null;
    const record = (records || []).find(item => item.id === shown.id);
    if (!record) return null;
    const kind = phase(record, now, maintenance);
    const when = clock().short;
    if (kind === 'planned') return {kind: 'row', text: `Transfer to ${record.to} registered ${when.format(timeOf(record.at))}: due in the maintenance ${clock().day.format(dueOf(record, maintenance))}`};
    if (kind === 'due') return {kind: 'warn', text: `Transfer to ${record.to} was due in the maintenance ${clock().day.format(dueOf(record, maintenance))}: log in to check`};
    if (kind === 'moved') return {kind: 'warn', text: `Moved here from ${record.from}: log in with it on ${record.to} to confirm the transfer`};
    return {kind: 'hint', text: `Came from ${record.from} by transfer, ${when.format(timeOf(record.done || record.ended || record.at))}`};
  }
  // A record's tooltip, from the plate or the log: {title, lines: [{text, kind}], countdown: {label, at} or null}.
  // who: {rom, gameforge, mail}, its RoM and Gameforge account as the page knows them, and what its mailbox holds.
  function tipOf(record, now = Date.now(), maintenance = null, who = null) {
    const plan = maintenanceOf(maintenance);
    const kind = phase(record, now, maintenance);
    const lines = [{kind: 'sub', text: `${record.from} → ${record.to}`}];
    const accounts = [who?.rom ? `RoM account: ${who.rom}` : '', who?.gameforge ? `Gameforge: ${who.gameforge}` : ''].filter(Boolean);
    if (accounts.length) lines.push({kind: 'row', text: accounts.join(' · ')});
    lines.push({kind: `state is-${kind}`, text: PHASE_NAMES[kind]});
    for (const item of record.events) lines.push({kind: 'event', text: `${clock().long.format(timeOf(item.at))} · ${item.text}`});
    const due = dueOf(record, maintenance);
    let next = null;
    if (kind === 'planned') {
      // The transfer page's own warning: what's left in the mailbox or the Auction House is lost
      if (who?.mail) lines.push({kind: 'warn', text: `Mailbox: ${who.mail}. Take it all out before the maintenance: the transfer page warns that mail left there is lost.`});
      lines.push({kind: 'hint', text: 'The game moves it in that maintenance. Cancel it on the transfer page and its plate goes.'});
      next = {label: `${DAYS[plan.day]} maintenance in`, at: due, when: `${clock().day.format(due)} your time`};
    } else if (kind === 'due') {
      lines.push({kind: 'warn', text: `The maintenance ${clock().day.format(due)} should have moved it. Log in on ${record.from} with a character of its account, or with ${record.name} on ${record.to}, to check.`});
      const after = nextMaintenance(now, maintenance);
      next = {label: `If it didn't move: next ${DAYS[plan.day]} maintenance in`, at: after, when: `${clock().day.format(after)} your time`};
    } else if (kind === 'moved') {
      lines.push({kind: 'warn', text: `Log in with it on ${record.to} to confirm the transfer.`});
    }
    return {title: `Transfer: ${record.name}`, lines, countdown: next};
  }

  // The Global Bank page's side: the records, the maintenance setting, the tooltip with its countdown, and the log.
  // options: {storage: this extension's local storage, send(message): to the background, changed(what): 'records' when
  // a transfer moved characters or changed state, so the page prepares them again, 'times' when only what's drawn
  // changes; who(record): {rom, gameforge}; openLog(id): show the log at that record; tooltip: an element for it}
  function create(options = {}) {
    let state = {v: 1, list: []};
    let maintenance = {...MAINTENANCE};
    let shape = '';
    let sending = false;
    let dueTimer = 0;
    const storage = options.storage || null;
    // What moves characters or changes a plate: a change only to when the site last listed one draws the page again
    const shapeOf = () => JSON.stringify(state.list.map(record => [record.id, record.state, record.name, record.from, record.to, record.at, record.ended || '', record.done || '']));
    function settle(stored, plan) {
      state = load(stored);
      maintenance = maintenanceOf(plan);
      const next = shapeOf();
      const moved = next !== shape;
      shape = next;
      scheduleDue();
      return moved;
    }
    // A planned transfer turns due when its maintenance starts, with nothing new saved
    function scheduleDue() {
      clearTimeout(dueTimer);
      const now = Date.now();
      const next = Math.min(...state.list.filter(record => record.state === 'planned').map(record => dueOf(record, maintenance)).filter(at => at > now));
      if (Number.isFinite(next)) dueTimer = setTimeout(() => { if (options.changed) options.changed('times'); scheduleDue(); }, Math.min(next - now + 1000, 2 ** 31 - 1));
    }
    const api = {
      STORE, MAINTENANCE_STORE,
      async load() {
        if (!storage) return;
        const saved = await storage.get([STORE, MAINTENANCE_STORE]).catch(() => ({}));
        settle(saved[STORE], saved[MAINTENANCE_STORE]);
      },
      // A change in storage, from the background or another copy of the page
      stored(changes) {
        if (!changes[STORE] && !changes[MAINTENANCE_STORE]) return;
        const moved = settle(changes[STORE] ? changes[STORE].newValue : state, changes[MAINTENANCE_STORE] ? changes[MAINTENANCE_STORE].newValue : maintenance);
        if (options.changed) options.changed(moved ? 'records' : 'times');
      },
      records: () => state.list,
      maintenance: () => maintenance,
      overlay: list => overlay(list, state.list),
      plate: character => plateOf(character, state.list, Date.now(), maintenance),
      cardLine: character => cardLine(character, state.list, Date.now(), maintenance),
      // Planned, due and moved ones: the ones still waiting for something
      active: () => state.list.filter(record => record.state === 'planned' || record.state === 'moved'),
      record: id => state.list.find(record => record.id === id) || null,
      // What the newly loaded saves say, sent to the background to keep
      async check(characters) {
        const changes = evidence(state.list, characters, {now: Date.now(), maintenance});
        if (!changes.length || sending || !options.send) return 0;
        sending = true;
        try {
          await options.send({type: 'transfers-change', changes});
        } catch { /* told again on the next load */ } finally { sending = false; }
        return changes.length;
      },
      async forget(id) {
        if (options.send) await options.send({type: 'transfers-change', changes: [{id, state: 'forget', at: Date.now(), text: ''}]});
      },
      async setMaintenance(plan) {
        maintenance = maintenanceOf(plan);
        if (storage) await storage.set({[MAINTENANCE_STORE]: maintenance});
        scheduleDue();
        if (options.changed) options.changed('times');
      },
      tip: (record, now = Date.now()) => tipOf(record, now, maintenance, options.who ? options.who(record) : null),
      phase: (record, now = Date.now()) => phase(record, now, maintenance),
      due: record => dueOf(record, maintenance),
      next: (now = Date.now()) => nextMaintenance(now, maintenance),
      // How many are planned, due and moved, the ones waiting for something, and how many the log holds
      counts(now = Date.now()) {
        const count = {planned: 0, due: 0, moved: 0, active: 0, total: state.list.length};
        for (const record of state.list) {
          const kind = phase(record, now, maintenance);
          if (kind in count) count[kind]++;
        }
        count.active = count.planned + count.due + count.moved;
        return count;
      },
      // The log, in a table's body: the ones still waiting first, then the newest. search: words a record's name,
      // servers or state must hold (filters, #like this, are for the characters' table). Returns how many it shows.
      renderLog(body, {search = ''} = {}) {
        const now = Date.now();
        const words = lower(search).split(/[\s,]+/).filter(word => word && !word.startsWith('#'));
        const order = {planned: 0, due: 0, moved: 1};
        const rows = state.list.map(record => ({record, kind: phase(record, now, maintenance)}))
          .filter(({record, kind}) => words.every(word => lower(`${record.name} ${record.from} ${record.to} ${PHASE_NAMES[kind]}`).includes(word)))
          .sort((a, b) => (order[a.kind] ?? 2) - (order[b.kind] ?? 2) || timeOf(b.record.at) - timeOf(a.record.at));
        body.replaceChildren(...rows.map(({record, kind}) => {
          const row = make('tr', `xfer-row is-${kind}`);
          row.id = `xfer-${record.id}`;
          row.dataset.xfer = record.id;
          const who = make('td');
          who.append(make('b', 'xfer-name', record.name));
          const route = make('td', 'xfer-route');
          route.append(make('span', '', record.from), make('span', 'xfer-sep', ' › '), make('span', 'xfer-to', record.to));
          const at = timeOf(record.at);
          const registered = make('td', '', clock().short.format(at));
          registered.title = clock().long.format(at);
          const due = dueOf(record, maintenance);
          const when = make('td', '', clock().day.format(due));
          if (kind === 'planned') {
            const left = make('span', 'muted xfer-left', ` · in ${roughly(due - now)}`);
            left.dataset.xferLeft = String(due);
            when.append(left);
          }
          const chip = make('td');
          chip.append(make('span', `xfer-state is-${kind}`, PHASE_NAMES[kind]));
          const last = record.events[record.events.length - 1];
          const news = make('td', 'xfer-news', last ? last.text : '');
          if (last) news.title = clock().long.format(timeOf(last.at));
          const actions = make('td', 'xfer-actions');
          const forget = make('button', 'gb-button--ghost gb-button--sm', 'Forget');
          forget.type = 'button';
          forget.dataset.xferForget = record.id;
          forget.setAttribute('aria-label', `Forget ${record.name}'s transfer to ${record.to}`);
          actions.append(forget);
          row.append(who, route, registered, when, chip, news, actions);
          return row;
        }));
        return rows.length;
      },
      // The log's "in 1d 3h", kept current while it shows
      tickLog(body) {
        const now = Date.now();
        let passed = false;
        for (const node of body.querySelectorAll('[data-xfer-left]')) {
          const left = Number(node.dataset.xferLeft) - now;
          if (left <= 0) passed = true;
          else node.textContent = ` · in ${roughly(left)}`;
        }
        return passed;
      },
    };
    if (options.tooltip && typeof document !== 'undefined') attachTip(api, options);
    return api;
  }

  // One tooltip for every plate and log row: hovering or focusing [data-xfer] shows that record, with a countdown to
  // the maintenance that ticks while it is open. A click on a plate opens the log at that record.
  function attachTip(api, options) {
    const tooltip = options.tooltip;
    let shownId = null, ticker = 0, anchor = null;
    function place(x, y) {
      tooltip.style.left = Math.max(4, Math.min(x + 16, window.innerWidth - tooltip.offsetWidth - 8)) + 'px';
      tooltip.style.top = Math.max(4, Math.min(y + 16, window.innerHeight - tooltip.offsetHeight - 8)) + 'px';
    }
    function draw() {
      const record = api.record(shownId);
      if (!record) { hide(); return; }
      const tip = api.tip(record);
      const nodes = [make('strong', 'xfer-tip-title', tip.title)];
      for (const line of tip.lines) nodes.push(make('span', `xfer-tip-${line.kind}`, line.text));
      if (tip.countdown) {
        const box = make('span', 'xfer-tip-countdown');
        box.append(make('span', 'xfer-tip-countdown-label', tip.countdown.label), make('b', 'xfer-tip-countdown-time', countdown(tip.countdown.at - Date.now())),
          make('span', 'xfer-tip-countdown-when', tip.countdown.when));
        nodes.push(box);
      }
      if (anchor?.dataset.xferOpen !== undefined) nodes.push(make('span', 'xfer-tip-hint', 'Click for the transfer log'));
      tooltip.replaceChildren(...nodes);
    }
    function show(node, x, y) {
      const id = node.dataset.xfer;
      if (!api.record(id)) return;
      shownId = id;
      anchor = node;
      draw();
      tooltip.hidden = false;
      place(x, y);
      clearInterval(ticker);
      // Only the countdown changes: a second at a time while it shows
      ticker = setInterval(() => {
        const time = tooltip.querySelector('.xfer-tip-countdown-time');
        const record = api.record(shownId);
        const tip = record ? api.tip(record) : null;
        if (!tip || !time || !tip.countdown) { draw(); return; }
        time.textContent = countdown(tip.countdown.at - Date.now());
      }, 1000);
    }
    function hide() {
      clearInterval(ticker);
      tooltip.hidden = true;
      shownId = null;
      anchor = null;
    }
    document.addEventListener('mouseover', event => {
      const node = event.target?.closest?.('[data-xfer]');
      if (!node) { if (shownId) hide(); return; }
      if (node.dataset.xfer !== shownId || node !== anchor) show(node, event.clientX, event.clientY);
    });
    document.addEventListener('mousemove', event => { if (shownId && !tooltip.hidden) place(event.clientX, event.clientY); }, {passive: true});
    document.addEventListener('focusin', event => {
      const node = event.target?.closest?.('[data-xfer]');
      if (!node) return;
      const box = node.getBoundingClientRect();
      show(node, box.left, box.bottom);
    });
    document.addEventListener('focusout', event => { if (event.target?.closest?.('[data-xfer]')) hide(); });
    document.addEventListener('scroll', () => { if (shownId) hide(); }, {passive: true, capture: true});
    document.addEventListener('click', event => {
      const node = event.target?.closest?.('[data-xfer-open]');
      if (!node || !options.openLog) return;
      event.preventDefault();
      hide();
      options.openLog(node.dataset.xfer);
    });
  }

  return {STORE, MAINTENANCE_STORE, ZONE, MAINTENANCE, DAYS, SERVERS, TAB_MEMORY, PHASE_NAMES, cleanServer, keyOf, savedTime, zoneParts, zoneOffset, zoned,
    maintenanceOf, nextMaintenance, dueOf, serverLabel, characterLabel, parsePage, cleanRead, load, applyRead, evidence, cleanChanges, applyChanges,
    overlay, countdown, roughly, phase, plateOf, cardLine, tipOf, create};
})();
