'use strict';
// The Bank tab on a PC without the local host: reads the save files and icons straight from folders the
// player picks, the same way GlobalBank-Data.ps1 does. It only reads. Nothing leaves this PC.
const GBFolders = (() => {
  const DATABASE = 'gbFolders';
  const STORE = 'kept';
  const HEADS_AT_ONCE = 256;
  const HEAD_BYTES = 320;

  // The save files are read byte for byte. Names the game wrote as UTF-8 are decoded when they are shown.
  function bytesToRaw(bytes) {
    const parts = [];
    for (let at = 0; at < bytes.length; at += 32768) parts.push(String.fromCharCode.apply(null, bytes.subarray(at, at + 32768)));
    return parts.join('');
  }
  function readable(raw) {
    if (!raw) return '';
    const bytes = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
    try { return new TextDecoder('utf-8', {fatal: true}).decode(bytes); } catch { return raw; }
  }
  function number(text) {
    const value = Number(text);
    return Number.isSafeInteger(value) ? value : 0;
  }
  // What a line such as  GlobalBank_Char = "..."  holds, still escaped as the file has it
  function savedString(text, name) {
    const start = name + ' = "';
    let at = text.startsWith(start) ? 0 : text.indexOf('\n' + start);
    if (at < 0) return null;
    at += (text[at] === '\n' ? 1 : 0) + start.length;
    for (let end = at; end < text.length; end++) {
      if (text[end] === '\\') end++;
      else if (text[end] === '\r' || text[end] === '\n') return null;
      else if (text[end] === '"') return text.slice(at, end);
    }
    return null;
  }
    // GB1~name~class~level~gold~bagSlots~bankSlots~bankSeen~time, then C~class~level, M~key~amount~name and
  // B/K~slot~count~id~name~icon[~1 if bound][~gear details] records,
  // records, all joined by backticks, into the character GlobalBank.json would hold.
  function snapshot(text, saved) {
    if (!text || !text.startsWith('GB1~')) return null;
    const records = text.split('`');
    const head = records[0].split('~');
    if (!head[1]) return null;
    const character = {name: readable(head[1]), class: readable(head[2]), classes: [], currencies: [], level: number(head[3]), gold: number(head[4]),
      bagSlots: number(head[5]), bankSlots: number(head[6]), bankSeen: head[7] === '1', saved, note: '', bag: [], bank: []};
    for (const record of records.slice(1)) {
      const field = record.split('~');
      if (field[0] === 'C' && field[1] && number(field[2]) > 0) {
        character.classes.push({name: readable(field[1]), level: number(field[2])});
      } else if (field[0] === 'M' && field[1] && number(field[2]) > 0) {
        character.currencies.push({key: field[1], amount: number(field[2]), name: readable(field[3])});
      } else if ((field[0] === 'B' || field[0] === 'K') && field.length >= 4) {
        (field[0] === 'B' ? character.bag : character.bank).push({slot: number(field[1]), count: Math.max(1, number(field[2])), id: field[3],
          name: readable(field[4]), icon: field[5] || '', ...(field[6] === '1' ? {bound: true} : {}),
          ...(field.length >= 15 ? {gear: {dura: number(field[7]), maxDura: number(field[8]), plus: number(field[9]), tier: number(field[10]), freeSlots: number(field[11]),
            stats: field[12] ? field[12].split(';').map(readable) : [], runes: field[13] ? field[13].split(';').map(readable) : [], color: field[14]}} : {})});
      }
    }
    return character;
  }
  function localTime(milliseconds) {
    const date = new Date(milliseconds);
    const two = value => String(value).padStart(2, '0');
    return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())} ${two(date.getHours())}:${two(date.getMinutes())}`;
  }
  // Each save as {folder, text, time}. The same rules as the helper: notes with the highest version win, then the
  // newest file, and a snapshot someone removed in game stays out unless the character has saved a newer one since.
  function charactersFrom(saves, excluded = new Set()) {
    const notes = new Map();
    const removed = new Map();
    const found = [];
    for (const save of saves) {
      if (excluded.has(save.folder)) continue;
      const saved = localTime(save.time);
      const character = snapshot(savedString(save.text, 'GlobalBank_Char'), saved);
      if (character && !excluded.has(character.name)) found.push({folder: save.folder, saved, character});
      for (const record of (savedString(save.text, 'GlobalBank_Notes') || '').split('`')) {
        const [name, version, note] = record.split('~');
        if (!name || !/^\d+$/.test(version || '')) continue;
        const have = notes.get(readable(name));
        if (!have || Number(version) > have.version || (Number(version) === have.version && save.time > have.time)) {
          notes.set(readable(name), {version: Number(version), time: save.time, text: readable(note)});
        }
      }
      for (const record of (savedString(save.text, 'GlobalBank_Removed') || '').split('`')) {
        const [name, date] = record.split('~');
        if (name && date && (!removed.has(name) || date > removed.get(name))) removed.set(name, date);
      }
    }
    return found.filter(entry => !(removed.has(entry.folder) && entry.saved <= removed.get(entry.folder))).map(entry => {
      entry.character.note = notes.get(entry.character.name)?.text || '';
      return entry.character;
    }).sort((a, b) => a.name.localeCompare(b.name));
  }

  function iconKey(name) {
    const key = String(name).replaceAll('/', '\\').replace(/^\\+/, '').toLowerCase();
    return /^interface\\icons\\[a-z0-9_\-\\. ]+$/.test(key) && !key.includes('..') ? `${key}.dds` : null;
  }
  // interface.fdb: magic, entry count, then 16 bytes for each entry ending in where it starts. Its index has no
  // names, so every entry's head is read once to find the item icons.
  async function iconIndex(file) {
    const start = new DataView(await file.slice(0, 8).arrayBuffer());
    const count = start.getUint32(4, true);
    const table = new DataView(await file.slice(8, 8 + count * 16).arrayBuffer());
    const index = {};
    const readHead = async at => {
      const head = new DataView(await file.slice(at, at + HEAD_BYTES).arrayBuffer());
      if (head.byteLength < 32) return;
      const length = head.getInt32(28, true);
      if (length <= 0 || 32 + length > head.byteLength) return;
      const name = bytesToRaw(new Uint8Array(head.buffer, 32, length)).replace(/\0+$/, '').toLowerCase();
      if (name.startsWith('interface\\icons\\')) index[name] = [at + 32 + length, head.getInt32(16, true), head.getInt32(8, true)];
    };
    for (let i = 0; i < count; i += HEADS_AT_ONCE) {
      const waiting = [];
      for (let j = i; j < Math.min(count, i + HEADS_AT_ONCE); j++) waiting.push(readHead(table.getUint32(j * 16 + 12, true)));
      await Promise.all(waiting);
    }
    return index;
  }
  // One icon as icons.js decodes it: the picture's 16-byte head, then its largest picture. Packing method 3 is zlib
  // and 0 is none; anything else returns null and the page shows initials.
  async function readIcon(file, [at, packed, method]) {
    if ((method !== 3 && method !== 0) || packed > 2097152) return null;
    const head = new Uint8Array(await file.slice(at, at + 16).arrayBuffer());
    if (head.length < 16) return null;
    const view = new DataView(head.buffer);
    const format = view.getUint32(0, true), width = view.getUint32(4, true), height = view.getUint32(8, true);
    if (width > 1024 || height > 1024) return null;
    const across = Math.ceil(width / 4), down = Math.ceil(height / 4);
    const wanted = {4: width * height * 4, 6: across * down * 8, 8: across * down * 16}[format];
    if (!wanted) return null;
    const plain = new Uint8Array(16 + wanted);
    plain.set(head);
    const body = file.slice(at + 16, at + 16 + packed);
    let stream = body.stream();
    if (method === 3) stream = stream.pipeThrough(new DecompressionStream('deflate'));
    const reader = stream.getReader();
    let filled = 16;
    while (filled < plain.length) {
      const {done, value} = await reader.read();
      if (done) break;
      plain.set(value.subarray(0, plain.length - filled), filled);
      filled += value.length;
    }
    reader.cancel().catch(() => {});
    return filled < plain.length ? null : plain;
  }

  // Where the picked folders are kept. Chrome can keep a folder only in IndexedDB.
  function openDatabase() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DATABASE, 1);
      request.onupgradeneeded = () => request.result.createObjectStore(STORE);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
  async function keep(key, value) {
    const database = await openDatabase();
    await new Promise((resolve, reject) => {
      const write = database.transaction(STORE, 'readwrite');
      write.objectStore(STORE).put(value, key);
      write.oncomplete = resolve;
      write.onerror = () => reject(write.error);
    });
    database.close();
  }
  async function kept(key) {
    const database = await openDatabase();
    const value = await new Promise((resolve, reject) => {
      const read = database.transaction(STORE).objectStore(STORE).get(key);
      read.onsuccess = () => resolve(read.result);
      read.onerror = () => reject(read.error);
    });
    database.close();
    return value;
  }

  async function looksLikeSaves(folder) {
    for await (const [, entry] of folder.entries()) {
      if (entry.kind !== 'directory') continue;
      try { await entry.getFileHandle('SaveVariables.lua'); return true; } catch { /* the next one */ }
    }
    return false;
  }
  async function iconFile(game) {
    return (await (await game.getDirectoryHandle('fdb')).getFileHandle('interface.fdb')).getFile();
  }
  async function looksLikeGame(folder) {
    try { await iconFile(folder); return true; } catch { return false; }
  }
  const PICKS = {
    saves: {id: 'gbsaves', startIn: 'documents', check: looksLikeSaves, wrong: "That isn't it: it has no character folders with a SaveVariables.lua. Look for Documents\\Runes of Magic."},
    game: {id: 'gbgame', check: looksLikeGame, wrong: "That isn't it: it has no fdb\\interface.fdb. Pick the folder Runes of Magic is installed in."},
  };
  // Returns the folder's name, or null if the player closed the window. Needs a click on the page.
  async function choose(kind) {
    const pick = PICKS[kind];
    let folder;
    try {
      folder = await showDirectoryPicker({id: pick.id, mode: 'read', ...(pick.startIn ? {startIn: pick.startIn} : {})});
    } catch (error) {
      if (error.name === 'AbortError') return null;
      throw error;
    }
    if (!await pick.check(folder)) throw new Error(pick.wrong);
    await keep(kind, folder);
    return folder.name;
  }
  // For each kind: {name, access}, where access is 'granted', or 'prompt' when Chrome needs a click to allow it again.
  async function state() {
    const result = {};
    for (const kind of Object.keys(PICKS)) {
      const folder = await kept(kind);
      result[kind] = folder ? {name: folder.name, access: await folder.queryPermission({mode: 'read'})} : null;
    }
    return result;
  }
  // Needs a click on the page.
  async function allowAgain() {
    for (const kind of Object.keys(PICKS)) {
      const folder = await kept(kind);
      if (folder) await folder.requestPermission({mode: 'read'});
    }
  }
  async function usable(kind) {
    const folder = await kept(kind);
    return folder && await folder.queryPermission({mode: 'read'}) === 'granted' ? folder : null;
  }
  async function readExcluded(game) {
    if (!game) return new Set();
    try {
      const helper = await (await game.getDirectoryHandle('interface')).getDirectoryHandle('GlobalBankHelper');
      const file = await (await helper.getFileHandle('ExcludedCharacters.json')).getFile();
      const names = JSON.parse(await file.text()).names;
      return new Set(Array.isArray(names) ? names : []);
    } catch { return new Set(); }
  }
  // A file the game is writing right now can't be read; it counts as busy and the next read picks it up.
  async function readCharacters() {
    const folder = await usable('saves');
    const saves = [];
    let busy = 0;
    for await (const [name, entry] of folder.entries()) {
      if (entry.kind !== 'directory') continue;
      let handle;
      try { handle = await entry.getFileHandle('SaveVariables.lua'); } catch { continue; }
      try {
        const file = await handle.getFile();
        saves.push({folder: name, text: bytesToRaw(new Uint8Array(await file.arrayBuffer())), time: file.lastModified});
      } catch { busy++; }
    }
    return {characters: charactersFrom(saves, await readExcluded(await usable('game'))), busy};
  }
  let icons = null;
  async function readIcons(names) {
    const game = await usable('game');
    if (!game) return {};
    const file = await iconFile(game);
    const stamp = `${file.size}:${file.lastModified}`;
    if (!icons || icons.stamp !== stamp) {
      const saved = await kept('iconIndex');
      icons = saved?.stamp === stamp ? saved : {stamp, index: await iconIndex(file)};
      if (icons !== saved) await keep('iconIndex', icons).catch(() => {});
    }
    const found = {};
    for (const name of names) {
      const entry = icons.index[iconKey(name)];
      if (!entry) continue;
      const picture = await readIcon(file, entry).catch(() => null);
      if (picture) found[name] = picture;
    }
    return found;
  }
  // Takes the same requests the local host does, for the Bank tab's needs.
  async function answer(message) {
    if (message.type === 'bank-icons') return {ok: true, icons: await readIcons(message.names)};
    const {characters, busy} = await readCharacters();
    if (message.type === 'bank-data') return {ok: true, json: JSON.stringify({made: localTime(Date.now()), characters})};
    return {ok: true, output: `Read ${characters.length} characters from your save files.${busy ? ` ${busy} were busy, so try again in a moment.` : ''}`};
  }
  return {choose, state, allowAgain, usable, answer, bytesToRaw, savedString, snapshot, charactersFrom, iconKey, iconIndex, readIcon};
})();
