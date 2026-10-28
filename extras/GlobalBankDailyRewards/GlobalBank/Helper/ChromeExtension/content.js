'use strict';
(() => {
  if (!/^[a-z0-9-]+-shop-runesofmagic\.gameforge\.com$/i.test(location.hostname) || !/^\/dailies\/display\/5\/?$/.test(location.pathname)) return;
  let busy = false;
  let observer, timer;
  const active = () => !!chrome.runtime?.id;
  function stop() {
    if (observer) observer.disconnect();
    if (timer) clearInterval(timer);
    observer = timer = null;
  }
  const visible = el => !!el && el.getClientRects().length > 0 && getComputedStyle(el).visibility === 'visible' && getComputedStyle(el).display !== 'none';
  function identity() {
    const welcome = document.querySelector('.welcome');
    const name = welcome?.querySelector('a.text-link')?.textContent?.trim();
    const spans = welcome ? [...welcome.querySelectorAll(':scope > span')] : [];
    const server = spans.find(s => !s.querySelector('a'))?.textContent?.trim();
    return name && server ? {name,server} : null;
  }
  async function check() {
    if (!active()) { stop(); return; }
    if (busy) return;
    busy = true;
    try {
      const who = identity();
      if (!who) return;
      const pendingKey = 'pendingReward:' + encodeURIComponent(who.server.toLocaleLowerCase()) + ':' + encodeURIComponent(who.name.toLocaleLowerCase());
      const state = await chrome.storage.session.get(pendingKey);
      let pending = state[pendingKey];
      if (pending && pending.name === who.name && pending.server === who.server) {
        const chest = document.getElementById(pending.chestId);
        if (chest && (chest.dataset.status === 'redeemed' || chest.classList.contains('redeemed'))) {
          const result = await chrome.runtime.sendMessage({type:'reward-confirmed',name:who.name,server:who.server,day:pending.day});
          if (result?.ok) await chrome.storage.session.remove(pendingKey);
          return;
        }
        if (Date.now() - pending.started < 30000) return;
      }
      const chest = document.querySelector('li.chest.current[data-status="nowAvailable"]');
      const info = document.getElementById('chestinfo');
      if (!chest) {
        // The shop marks the collected chest redeemed and the next one
        // timeAvailable; its countdown is independent of page language.
        const next = document.querySelector('li.chest.current[data-status="timeAvailable"]');
        const redeemed = document.querySelector('li.chest.current[data-status="redeemed"]');
        const timer = document.getElementById('chestInfoTimer');
        const time = timer?.textContent?.replace(/\s+/g, ' ').trim();
        if (next && info?.dataset.for === next.id && visible(timer) && time) {
          const status = (redeemed ? 'Daily reward already collected. ' : '') + 'Next free reward in ' + time + '.';
          const previous = await chrome.storage.session.get('lastStatus');
          if (previous.lastStatus !== status) await chrome.storage.session.set({lastStatus:status});
        }
        return;
      }
      const button = document.getElementById('chestInfoButtonPrice');
      const day = Number(chest?.dataset.number);
      if (!chest || !chest.id || info?.dataset.for !== chest.id || !visible(button) || button.disabled || button.getAttribute('aria-disabled') === 'true' || !Number.isInteger(day) || day < 1 || day > 28) return;
      pending = {...who,chestId:chest.id,day,started:Date.now()};
      await chrome.storage.session.set({[pendingKey]:pending,lastStatus:'Collecting the available reward for ' + who.name + '…'});
      button.click();
    } catch (error) {
      if (!active()) { stop(); return; }
      try { await chrome.storage.session.set({lastStatus:'Daily reward extension: ' + String(error.message || error)}); }
      catch (_) { if (!active()) stop(); }
    } finally { busy = false; }
  }
  async function checkHelper() {
    try {
      const status = await chrome.runtime.sendMessage({type:'helper-status'});
      if (status?.running || document.getElementById('globalbank-helper-prompt')) return;
      const box = document.createElement('div');
      box.id = 'globalbank-helper-prompt';
      Object.assign(box.style, {position:'fixed',zIndex:'2147483647',bottom:'16px',right:'16px',padding:'12px',background:'#202a37',color:'#fff',border:'1px solid #d1b268',borderRadius:'6px',font:'13px sans-serif',maxWidth:'280px'});
      const label = document.createElement('span');
      label.textContent = status?.ok ? 'Global Bank helper is not running. Start it to keep character data up to date. ' : 'Global Bank bridge unavailable. Run Install Chrome extension.bat from the installed addon folder. ';
      const button = document.createElement('button');
      button.textContent = 'Start helper';
      button.hidden = !status?.ok;
      button.addEventListener('click', async (event) => {
        if (!event.isTrusted) return;
        button.disabled = true;
        const result = await chrome.runtime.sendMessage({type:'helper-start'});
        if (result?.ok) box.remove();
        else { label.textContent = 'Could not start the helper: ' + (result?.error || 'unknown error'); button.disabled = false; }
      });
      const close = document.createElement('button');
      close.textContent = '×'; close.title = 'Dismiss'; close.style.marginLeft = '8px'; close.addEventListener('click', () => box.remove());
      box.append(label, button, close); document.body.append(box);
    } catch (_) { /* The popup explains a missing bridge. */ }
  }
  // Popup commands are relayed only through a matching daily page.
  chrome.runtime.onMessage.addListener((message, sender, reply) => {
    if (sender.id !== chrome.runtime.id || (message?.type !== 'popup-helper-status' && message?.type !== 'popup-helper-start')) return;
    chrome.runtime.sendMessage({type: message.type === 'popup-helper-start' ? 'helper-start' : 'helper-status'}).then(reply, error => reply({ok:false,error:String(error)}));
    return true;
  });
  async function start() {
    const ready = await chrome.runtime.sendMessage({type:'session-ready'});
    if (!ready?.ok) return;
    checkHelper();
    observer = new MutationObserver(check);
    observer.observe(document.documentElement,{subtree:true,childList:true,attributes:true,attributeFilter:['class','data-status','data-for','style','disabled','aria-disabled']});
    timer = setInterval(check, 2000);
    check();
  }
  start().catch(() => {});
})();
