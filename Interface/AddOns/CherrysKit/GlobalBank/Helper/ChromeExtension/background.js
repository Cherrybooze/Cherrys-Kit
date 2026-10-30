'use strict';
const HOST = 'com.cherryskit.globalbank';
// Any message makes the local host write Windows' time for the game's addons. Once per Chrome
// start is enough: the game carries that time on until Windows restarts.
const stampClock = () => chrome.runtime.sendNativeMessage(HOST, {type:'clock'}, () => void chrome.runtime.lastError);
// The page's toggle: run the helper, hidden, whenever Chrome is open.
const startHelperIfWanted = async () => {
  const {autoHelper} = await chrome.storage.local.get('autoHelper');
  if (autoHelper) chrome.runtime.sendNativeMessage(HOST, {type:'helper-auto-start'}, () => void chrome.runtime.lastError);
};
const chromeStarted = () => { stampClock(); startHelperIfWanted().catch(() => {}); };
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
  if ((control && message?.type === 'helper-info') || ((control || popup) && (message?.type === 'helper-auto-start' || message?.type === 'helper-auto-stop'))) {
    chrome.runtime.sendNativeMessage(HOST, {type:message.type}, response => {
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
  if (control && message?.type === 'bank-command') {
    const command = message.command;
    if (typeof command !== 'string' || !command.trim() || command.length > 256) return;
    chrome.runtime.sendNativeMessage(HOST, {type:'bank-command', command}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
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
