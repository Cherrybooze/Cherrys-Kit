'use strict';
// Character transfers: what the site's transfer page lists, and the records the Global Bank page draws from. A service
// worker always has importScripts; a test running this file elsewhere may not, and has no transfers then.
if (typeof importScripts === 'function') importScripts('transfers.js');
const HOST = 'com.cherryskit.globalbank';
// Only this extension's own pages can read what it stores locally, not its scripts running on web pages.
chrome.storage?.local?.setAccessLevel?.({accessLevel: 'TRUSTED_CONTEXTS'})?.catch?.(() => {});
// Any message makes the local host write Windows' time for the game's addons and refresh the
// heartbeat the helper watches: while this extension is alive, the helper keeps running.
const BACKUP_REQUESTS = new Set(['backup-overview', 'backup-macros', 'backup-settings', 'backup-value', 'backup-restore-settings', 'backup-restore-macros', 'backup-macro-set',
  'macro-save', 'macro-groups', 'macro-delete', 'macro-group-list', 'macro-icons', 'macro-icon-list']);
const ADDON_REQUESTS = new Set(['addons-list', 'addons-check', 'addons-install', 'addons-offload', 'addons-restore', 'addons-delete', 'addons-mailbox', 'addons-loginscreen']);
// The clock also tells the helper's folder the automatic-start choice, which only this extension knows,
// so the helper's exit message can say what happens next.
// With the choice on, the same once-a-minute message also starts a helper that isn't running.
let autoHelperChoice, showTerminalChoice = false;
// Only these values reach the local host.
const cascadePixels = (value, most) => Number.isInteger(value) && value >= 0 && value <= most ? value : 0;
const cleanCascade = value => ({corner: value?.corner === 'top-left' ? 'top-left' : 'bottom-left', fit: value?.fit !== false,
  width: cascadePixels(value?.width, 16000), height: cascadePixels(value?.height, 16000),
  stepX: cascadePixels(value?.stepX, 1000), stepY: cascadePixels(value?.stepY, 1000),
  monitor: cascadePixels(value?.monitor, 32), onTop: value?.onTop === true});
chrome.storage?.local?.get?.(['autoHelper', 'showTerminal'])?.then?.(({autoHelper, showTerminal}) => {
  autoHelperChoice = !!autoHelper;
  showTerminalChoice = !!showTerminal;
})?.catch?.(() => {});
const stampClock = () => chrome.runtime.sendNativeMessage(HOST, autoHelperChoice === undefined ? {type:'clock'}
  : {type:'clock', autoHelper: autoHelperChoice, showWindow: showTerminalChoice}, () => void chrome.runtime.lastError);
// Once a minute is cheap and keeps the helper's 15-second check honest.
const ensureHeartbeat = () => chrome.alarms?.create?.('globalbank-heartbeat', {periodInMinutes: 1});
chrome.alarms?.onAlarm?.addListener(alarm => { if (alarm.name === 'globalbank-heartbeat') stampClock(); });
// The page's toggle: run the helper whenever Chrome is open, in a window if the player asked for one.
const startHelperIfWanted = async () => {
  const {autoHelper, showTerminal} = await chrome.storage.local.get(['autoHelper', 'showTerminal']);
  if (autoHelper) chrome.runtime.sendNativeMessage(HOST, {type:'helper-auto-start', showWindow: !!showTerminal}, () => void chrome.runtime.lastError);
};
// The daily page can't read local storage, so it gets the auto-collect choice through session storage.
const shareAutoCollect = () => chrome.storage.local.get('autoCollect')
  .then(({autoCollect}) => chrome.storage.session.set({autoCollect: autoCollect === true})).catch(() => {});
chrome.storage?.onChanged?.addListener((changes, area) => {
  if (area !== 'local') return;
  if ('autoCollect' in changes) shareAutoCollect();
  if ('showTerminal' in changes) showTerminalChoice = !!changes.showTerminal.newValue;
  if ('autoHelper' in changes) { autoHelperChoice = !!changes.autoHelper.newValue; stampClock(); }
});
// The Terminal view talks over one open port, so its polling never starts a process. The host answers in
// order. The port closes itself when the view has gone quiet, and a request on a dead port is reported, never resent.
const TERMINAL_IDLE_MS = 30000;
let terminalPort = null, terminalIdle = null;
const terminalWaiting = [];
const closeTerminalPort = () => {
  clearTimeout(terminalIdle);
  const port = terminalPort;
  terminalPort = null;
  if (port) { try { port.disconnect(); } catch {} }
  for (const reply of terminalWaiting.splice(0)) reply({ok:false, outcome:'bridge', error:'The connection to the local helper closed before it answered.', records:[]});
};
const terminalSend = (request, reply) => {
  try {
    if (!terminalPort) {
      const port = chrome.runtime.connectNative(HOST);
      port.onMessage.addListener(response => { terminalWaiting.shift()?.(response); });
      port.onDisconnect.addListener(() => {
        const error = chrome.runtime.lastError?.message || 'The connection to the local helper closed before it answered.';
        if (terminalPort !== port) return;
        terminalPort = null;
        for (const waiting of terminalWaiting.splice(0)) waiting({ok:false, outcome:'bridge', error, records:[]});
      });
      terminalPort = port;
    }
    terminalWaiting.push(reply);
    terminalPort.postMessage(request);
    clearTimeout(terminalIdle);
    terminalIdle = setTimeout(() => { if (!terminalWaiting.length) closeTerminalPort(); }, TERMINAL_IDLE_MS);
  } catch (error) {
    terminalWaiting.pop();
    reply({ok:false, outcome:'bridge', error:String(error?.message || error), records:[]});
  }
};
const validRequestId = id => typeof id === 'string' && /^[A-Za-z0-9-]{8,64}$/.test(id);
const terminalRequest = message => {
  if (message.type === 'terminal-catalogue') return {type:message.type};
  if (message.type === 'terminal-feed') {
    const session = typeof message.session === 'string' && /^[a-f0-9]{1,64}$/.test(message.session) ? message.session : null;
    const after = Number.isSafeInteger(message.after) && message.after > 0 ? message.after : 0;
    const max = Number.isSafeInteger(message.max) && message.max > 0 ? Math.min(message.max, 200) : 50;
    return {type:message.type, session, after, max};
  }
  if (!validRequestId(message.requestId)) return null;
  if (message.type === 'terminal-command') {
    if (typeof message.command !== 'string' || !message.command.trim() || message.command.length > 256) return null;
    return {type:message.type, requestId:message.requestId, command:message.command};
  }
  if (message.type === 'terminal-confirm') {
    if (typeof message.token !== 'string' || !message.token || message.token.length > 8192 || typeof message.answer !== 'string' || message.answer.length > 256) return null;
    return {type:message.type, requestId:message.requestId, token:message.token, answer:message.answer};
  }
  return null;
};
const chromeStarted = () => { ensureHeartbeat(); stampClock(); startHelperIfWanted().catch(() => {}); };
ensureHeartbeat();
chrome.runtime.onStartup.addListener(chromeStarted);
chrome.runtime.onInstalled.addListener(chromeStarted);
const validPage = url => {
  try { const u = new URL(url); return u.protocol === 'https:' && /^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(u.hostname) && /^\/dailies\/display\/5\/?$/.test(u.pathname); }
  catch { return false; }
};
const validDepot = url => {
  try { const u = new URL(url); return u.protocol === 'https:' && /^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(u.hostname) && /^\/depotitems\//.test(u.pathname); }
  catch { return false; }
};
// The Runes of Magic site's character transfer page, or its account page, in any of its languages: 'transfer',
// 'account' or ''
const sitePageKind = url => {
  try {
    const u = new URL(url);
    if (u.protocol !== 'https:' || !/^[a-z0-9-]+\.runesofmagic\.gameforge\.com$/i.test(u.hostname)) return '';
    return /^\/charactertransfer(\/|$)/i.test(u.pathname) ? 'transfer' : /^\/user\/administration(\/|$)/i.test(u.pathname) ? 'account' : '';
  } catch { return ''; }
};
// One change to the transfer records at a time, whether from the site's page or the Global Bank page, so neither
// writes over the other
let transferQueue = Promise.resolve();
const transferTask = task => {
  const run = transferQueue.then(task);
  transferQueue = run.catch(() => {});
  return run;
};
// What each tab of the transfer page showed last, so a transfer that leaves the list there was cancelled in that tab.
// Session storage: gone when Chrome closes.
const TRANSFER_TABS = 'transferTabs';
// What the site's pages showed of the login last, {at, user, email}: a transfer page without those fields links its
// characters to it for a while. Session storage: gone when Chrome closes.
const SITE_LOGIN = 'siteLogin';
async function recordSiteAccount(read) {
  const [kept, session] = await Promise.all([chrome.storage.local.get(GBTransfers.ACCOUNT_STORE), chrome.storage.session.get(SITE_LOGIN)]);
  const result = GBTransfers.applyAccount(kept[GBTransfers.ACCOUNT_STORE], read, {now: Date.now(), recent: session[SITE_LOGIN] || null});
  if (result.recent) await chrome.storage.session.set({[SITE_LOGIN]: result.recent});
  else await chrome.storage.session.remove(SITE_LOGIN);
  if (result.changed) await chrome.storage.local.set({[GBTransfers.ACCOUNT_STORE]: result.state});
  return result;
}
async function recordTransferPage(tab, read, kind = 'transfer') {
  const site = await recordSiteAccount(read);
  const linked = site.linked ? {user: site.linked.user, email: site.linked.email, count: site.linked.count} : null;
  const remembered = !linked && read.account && !read.planned.length && !read.offered.length && !read.listed.length ? read.account : null;
  // The account page lists no transfers: it never ends one
  if (kind !== 'transfer') return {ok: true, added: [], ended: [], linked, remembered};
  const now = Date.now();
  const [kept, session] = await Promise.all([chrome.storage.local.get([GBTransfers.STORE, GBTransfers.MAINTENANCE_STORE]), chrome.storage.session.get(TRANSFER_TABS)]);
  const tabs = session[TRANSFER_TABS] && typeof session[TRANSFER_TABS] === 'object' ? session[TRANSFER_TABS] : {};
  const result = GBTransfers.applyRead(kept[GBTransfers.STORE], read, {now, previous: tabs[tab] || null, maintenance: kept[GBTransfers.MAINTENANCE_STORE]});
  tabs[tab] = {at: now, planned: read.planned};
  for (const [id, seen] of Object.entries(tabs)) if (!(now - (Number(seen?.at) || 0) < GBTransfers.TAB_MEMORY)) delete tabs[id];
  await chrome.storage.session.set({[TRANSFER_TABS]: tabs});
  if (result.changed) await chrome.storage.local.set({[GBTransfers.STORE]: result.state});
  const maintenance = kept[GBTransfers.MAINTENANCE_STORE];
  return {ok: true,
    added: result.added.map(record => ({name: record.name, to: record.to, due: GBTransfers.dueOf(record, maintenance)})),
    ended: result.ended.map(record => ({name: record.name, from: record.from, to: record.to, state: record.state})), linked};
}
async function changeTransfers(changes) {
  const kept = await chrome.storage.local.get(GBTransfers.STORE);
  const result = GBTransfers.applyChanges(kept[GBTransfers.STORE], changes);
  if (result.changed) await chrome.storage.local.set({[GBTransfers.STORE]: result.state});
  return {ok: true, changed: result.changed};
}
// What the depot page reported: its items and when, never its address.
const cleanDepot = message => {
  if (!Array.isArray(message.items) || message.items.length > 2000 || typeof message.outline !== 'string' || message.outline.length > 40000) return null;
  const items = [];
  for (const item of message.items) {
    if (typeof item?.name !== 'string' || !item.name || item.name.length > 120 || !Number.isSafeInteger(item.count) || item.count < 1 || typeof item.picture !== 'string' || item.picture.length > 500) return null;
    items.push({name: item.name, count: item.count, picture: item.picture.startsWith('https://') ? item.picture.split('?')[0] : ''});
  }
  return {items, outline: message.outline, server: typeof message.server === 'string' ? message.server.slice(0, 120) : '', read: new Date().toISOString()};
};
chrome.runtime.onMessage.addListener((message, sender, reply) => {
  if (sender.id === chrome.runtime.id && !!sender.tab && message?.type === 'depot-items' && validDepot(sender.url || '')) {
    const depot = cleanDepot(message);
    if (!depot) return;
    chrome.storage.local.set({depot}).then(() => reply({ok:true}), error => reply({ok:false,error:String(error)}));
    return true;
  }
  // The character transfer page and the account page: the transfers listed, the characters offered or listed, and the
  // login's username and e-mail address
  const siteKind = sender.id === chrome.runtime.id && !!sender.tab && message?.type === 'transfer-page' ? sitePageKind(sender.url || '') : '';
  if (siteKind) {
    const read = GBTransfers.cleanRead(message);
    if (!read) { reply({ok:false, error:'Not a transfer page read.'}); return; }
    transferTask(() => recordTransferPage(String(sender.tab.id), read, siteKind)).then(reply, error => reply({ok:false,error:String(error?.message || error)}));
    return true;
  }
  const control = sender.url === chrome.runtime.getURL('control.html');
  const popup = !sender.tab && sender.url === chrome.runtime.getURL('popup.html');
  const shop = !!sender.tab && validPage(sender.url || '');
  if (sender.id !== chrome.runtime.id || (!control && !popup && !shop)) return;
  if (shop && message?.type === 'session-ready') {
    (async () => {
      // Remove temporary records written by older extension versions once the
      // daily page is opened; new temporary data lives only in memory.
      const old = await chrome.storage.local.get(null);
      const keys = Object.keys(old).filter(key => key === 'lastStatus' || key.startsWith('pendingReward:'));
      if (keys.length) await chrome.storage.local.remove(keys);
      await chrome.storage.session.setAccessLevel({accessLevel:'TRUSTED_AND_UNTRUSTED_CONTEXTS'});
      await shareAutoCollect();
    })().then(() => reply({ok:true}), error => reply({ok:false,error:String(error)}));
    return true;
  }
  if ((shop || popup || control) && (message?.type === 'helper-status' || message?.type === 'helper-start')) {
    chrome.runtime.sendNativeMessage(HOST, {type:message.type}, response => {
      const bridgeError = chrome.runtime.lastError?.message;
      const error = bridgeError || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error,errorKind:bridgeError || !response ? 'bridge-unavailable' : 'native-error'} : response);
    });
    return true;
  }
  // What the Global Bank page's saves showed about a transfer, or one the player forgot
  if (control && message?.type === 'transfers-change') {
    const changes = GBTransfers.cleanChanges(message.changes);
    if (!changes) { reply({ok:false, error:'No transfer changes.'}); return; }
    transferTask(() => changeTransfers(changes)).then(reply, error => reply({ok:false,error:String(error?.message || error)}));
    return true;
  }
  // Only the local extension page may ask for these.
  if (control && message?.type === 'auction-query') {
    const request = {type:'auction-query', search:message.search, realm:message.realm, pageOptions:message.pageOptions};
    if (typeof request.search !== 'string' || (!request.search.trim() && !request.pageOptions) || request.search.length > 128 || typeof request.realm !== 'string' || request.realm.length > 120) return;
    chrome.runtime.sendNativeMessage(HOST, request, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (control && message?.type === 'bank-data') {
    const offset = Number.isSafeInteger(message.offset) && message.offset > 0 ? message.offset : 0;
    chrome.runtime.sendNativeMessage(HOST, {type:'bank-data', offset}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  // "Cascade game windows": the local host arranges the game windows open right now.
  if ((control || popup) && message?.type === 'windows-cascade') {
    chrome.runtime.sendNativeMessage(HOST, {type:'windows-cascade', cascade: cleanCascade(message.cascade)}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  // The displays, for the Display list beside the cascade options.
  if ((control || popup) && message?.type === 'windows-monitors') {
    chrome.runtime.sendNativeMessage(HOST, {type:'windows-monitors'}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if ((control && message?.type === 'helper-info') || ((control || popup) && (message?.type === 'helper-auto-start' || message?.type === 'helper-auto-stop' || message?.type === 'helper-stop'))) {
    const request = {type: message.type};
    if (message.type === 'helper-auto-start') request.showWindow = message.showWindow === true;
    chrome.runtime.sendNativeMessage(HOST, request, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  // The encrypted accounts file only, and only for the extension's own page. It holds no key and no password.
  if (control && (message?.type === 'gf-save' || message?.type === 'gf-load' || message?.type === 'gf-delete')) {
    const request = {type: message.type};
    if (message.type === 'gf-save') {
      if (typeof message.text !== 'string' || message.text.length > 16777216) return;
      request.text = message.text;
    }
    if (message.type === 'gf-load') request.offset = Number.isSafeInteger(message.offset) && message.offset > 0 ? message.offset : 0;
    chrome.runtime.sendNativeMessage(HOST, request, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (control && message?.type === 'bank-icons') {
    const names = message.names;
    if (!Array.isArray(names) || !names.length || names.length > 25 || names.some(name => typeof name !== 'string' || name.length > 200)) return;
    chrome.runtime.sendNativeMessage(HOST, {type:'bank-icons', names}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (control && BACKUP_REQUESTS.has(message?.type)) {
    const {type, offset, character, from, variable, slot, characters, firstFree, icon, name, text, follow, id, groups, apply, deleted, action, group, to, code} = message;
    chrome.runtime.sendNativeMessage(HOST, {type, offset, character, from, variable, slot, characters, firstFree, icon, name, text, follow, id, groups, apply, deleted, action, group, to, code}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  // The Addons page. The bridge checks every name again; these only keep odd values from reaching it.
  if (control && ADDON_REQUESTS.has(message?.type)) {
    const request = {type: message.type};
    if (message.type === 'addons-install') {
      const packages = message.packages;
      if (!Array.isArray(packages) || !packages.length || packages.length > 30 || packages.some(name => typeof name !== 'string' || !/^[A-Za-z0-9!_-]{1,64}$/.test(name))) return;
      request.packages = packages;
      // Switch: the folders the new addon replaces, offloaded once it is installed
      if (message.offload !== undefined) {
        const offload = message.offload;
        if (!Array.isArray(offload) || offload.length > 10 || offload.some(entry => !['kit', 'addons'].includes(entry?.where) || typeof entry.name !== 'string' || !entry.name || entry.name.length > 200)) return;
        request.offload = offload.map(({where, name}) => ({where, name}));
      }
      // The mail switch: which mailbox addon to use once the install is done
      if (message.mailbox !== undefined) {
        if (!['UMM', 'zMail'].includes(message.mailbox)) return;
        request.mailbox = message.mailbox;
      }
    }
    if (message.type === 'addons-mailbox') {
      if (!['UMM', 'zMail'].includes(message.use)) return;
      request.use = message.use;
    }
    if (['addons-offload', 'addons-restore', 'addons-delete'].includes(message.type)) {
      if (typeof message.name !== 'string' || !message.name || message.name.length > 200) return;
      request.name = message.name;
      if (message.type !== 'addons-restore') {
        if (!['kit', 'addons', 'offloaded'].includes(message.where) || (message.type === 'addons-offload' && message.where === 'offloaded')) return;
        request.where = message.where;
      }
    }
    chrome.runtime.sendNativeMessage(HOST, request, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (control && message?.type === 'bank-command') {
    const command = message.command;
    if (typeof command !== 'string' || !command.trim() || command.length > 256) return;
    chrome.runtime.sendNativeMessage(HOST, {type:'bank-command', command}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (control && typeof message?.type === 'string' && message.type.startsWith('terminal-')) {
    const request = terminalRequest(message);
    if (!request) return;
    terminalSend(request, reply);
    return true;
  }
  if (!shop || message?.type !== 'reward-confirmed') return;
  const {name, server, day} = message;
  if (typeof name !== 'string' || !name.trim() || name.length > 80 || typeof server !== 'string' || !server.trim() || server.length > 120 || !Number.isInteger(day) || day < 1 || day > 28) return;
  chrome.runtime.sendNativeMessage(HOST, {type:'record', name, server, day}, response => {
    const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
    const status = error ? 'Collection confirmed; local save failed: ' + error : 'Collection confirmed and saved for ' + name + '.';
    chrome.storage.session.set({lastStatus: status});
    chrome.action.setBadgeText({text:error ? '!' : 'OK'});
    reply(error ? {ok:false,error} : {ok:true});
  });
  return true;
});
