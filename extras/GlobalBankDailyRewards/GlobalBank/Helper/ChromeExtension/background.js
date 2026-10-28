'use strict';
const HOST = 'com.cherryskit.globalbank';
const validPage = url => {
  try { const u = new URL(url); return u.protocol === 'https:' && /^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(u.hostname) && /^\/dailies\/display\/5\/?$/.test(u.pathname); }
  catch { return false; }
};
chrome.runtime.onMessage.addListener((message, sender, reply) => {
  if (sender.id !== chrome.runtime.id || (sender.tab && !validPage(sender.url || ''))) return;
  if (sender.tab && message?.type === 'session-ready') {
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
  if (sender.tab && (message?.type === 'helper-status' || message?.type === 'helper-start')) {
    chrome.runtime.sendNativeMessage(HOST, {type:message.type}, response => {
      const error = chrome.runtime.lastError?.message || response?.error || (response?.ok ? null : 'Local bridge returned no confirmation');
      reply(error ? {ok:false,error} : response);
    });
    return true;
  }
  if (!sender.tab || message?.type !== 'reward-confirmed') return;
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
