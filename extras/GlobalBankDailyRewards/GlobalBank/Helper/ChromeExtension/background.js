'use strict';
const HOST = 'com.cherryskit.globalbank';
// Any message makes the local host write Windows' time for the game's addons. Once per Chrome
// start is enough: the game carries that time on until Windows restarts.
const stampClock = () => chrome.runtime.sendNativeMessage(HOST, {type:'clock'}, () => void chrome.runtime.lastError);
chrome.runtime.onStartup.addListener(stampClock);
chrome.runtime.onInstalled.addListener(stampClock);
const validPage = url => {
  try { const u = new URL(url); return u.protocol === 'https:' && /^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(u.hostname) && /^\/dailies\/display\/5\/?$/.test(u.pathname); }
  catch { return false; }
};
chrome.runtime.onMessage.addListener((message, sender, reply) => {
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
    chrome.runtime.sendNativeMessage(HOST, {type:'bank-data'}, response => {
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
