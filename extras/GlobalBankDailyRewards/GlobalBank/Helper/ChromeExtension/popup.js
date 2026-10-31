'use strict';
const helper = document.getElementById('helper');
const start = document.getElementById('start');
const stop = document.getElementById('stop');
const status = document.getElementById('status');
const reset = document.getElementById('reset');
const resetTime = document.getElementById('reset-time');
let starting = false;
let refreshTimer;

// The same shape as the page's duration text, for the running helper's uptime.
function formatDuration(seconds) {
  const minutes = Math.max(0, Math.floor(seconds / 60));
  if (minutes < 60) return minutes + ' min';
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return hours + ' h ' + (minutes % 60) + ' min';
  return Math.floor(hours / 24) + ' days ' + (hours % 24) + ' h';
}
function helperRunText(response) {
  const since = Date.parse(response.since || '');
  return Number.isFinite(since)
    ? 'Helper is running \u2014 for ' + formatDuration((Date.now() - since) / 1000) + '.'
    : 'Helper is running.';
}

function collectionTime(value) {
  // Only a real, timezone-qualified confirmation can establish a collection.
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/i.test(value)) return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
}
// The daily reward resets at 00:00 in Germany, which is a different hour elsewhere.
const germanClock = new Intl.DateTimeFormat('en-US', {timeZone:'Europe/Berlin', hourCycle:'h23', year:'numeric', month:'numeric', day:'numeric', hour:'numeric', minute:'numeric', second:'numeric'});
function germanOffset(date) {
  const part = {};
  for (const {type, value} of germanClock.formatToParts(date)) part[type] = Number(value);
  return Date.UTC(part.year, part.month - 1, part.day, part.hour, part.minute, part.second) - Math.floor(date.getTime() / 1000) * 1000;
}
// 00:00 in Germany today, or that many days later. The offset is taken again at that moment,
// as it can differ from today's on the days the clocks change.
function germanMidnight(now, days) {
  const german = new Date(now.getTime() + germanOffset(now));
  const midnight = Date.UTC(german.getUTCFullYear(), german.getUTCMonth(), german.getUTCDate() + days);
  return new Date(midnight - germanOffset(new Date(midnight - germanOffset(now))));
}
function latestReset(now) {
  return germanMidnight(now, 0);
}
function showResetTime(now) {
  const clock = new Intl.DateTimeFormat(undefined, {timeStyle:'short'}).format(germanMidnight(now, 1));
  resetTime.textContent = 'Daily reset: ' + clock + ' your time (00:00 in Germany).';
}
function showCollection(record) {
  const collected = collectionTime(record?.collectedAt);
  reset.hidden = true;
  if (!collected) {
    status.textContent = 'Last confirmed collection: unknown.';
    return;
  }
  const clock = new Intl.DateTimeFormat(undefined, {dateStyle:'medium', timeStyle:'short'}).format(collected);
  status.textContent = 'Last confirmed collection: ' + record.name + (record.server ? ' (' + record.server + ')' : '') + ' — ' + clock + ' (local time).';
  reset.hidden = !(latestReset(new Date()) > collected);
}
async function send(type) {
  return chrome.runtime.sendMessage({type});
}
async function refresh() {
  try {
    const response = await send('helper-status');
    if (!response?.ok) {
      helper.textContent = response?.errorKind === 'native-error' ? 'Local helper setup error: ' + response.error : 'Native Messaging unavailable. Run Install Chrome extension.bat from the installed addon folder. ' + (response?.error || 'No response from the local bridge.');
      start.hidden = true;
      return false;
    }
    showCollection(response.lastCollected);
    if (response.rewardError) status.textContent = 'Could not read the last confirmed collection: ' + response.rewardError;
    helper.textContent = response.running ? helperRunText(response) : starting ? 'Starting the helper…' : 'Helper is not running.';
    start.hidden = false;
    start.disabled = response.running || starting;
    start.textContent = response.running ? 'Helper is running' : starting ? 'Starting helper…' : 'Start Global Bank helper';
    stop.hidden = !response.running;
    return response.running;
  } catch (error) {
    helper.textContent = 'Native Messaging unavailable: ' + String(error.message || error);
    start.hidden = true;
    return false;
  }
}
start.addEventListener('click', async event => {
  if (!event.isTrusted || starting || start.disabled) return;
  starting = true;
  start.disabled = true;
  start.textContent = 'Starting helper…';
  clearTimeout(refreshTimer);
  try {
    const response = await send('helper-start');
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    // Launch is user initiated. Status checks never launch another process.
    for (let attempt = 0; attempt < 10; attempt++) {
      if (await refresh()) return;
      if (attempt < 9) await new Promise(resolve => setTimeout(resolve, 500));
    }
    helper.textContent = 'Helper has not reported ready yet. Check its window, then try again.';
  } catch (error) {
    helper.textContent = 'Could not start the helper: ' + String(error.message || error);
  } finally {
    starting = false;
    if (start.textContent !== 'Helper is running') {
      start.disabled = false;
      start.textContent = 'Start Global Bank helper';
    }
    refreshTimer = setTimeout(poll, 30000);
  }
});
async function poll() {
  showResetTime(new Date());
  await refresh();
  refreshTimer = setTimeout(poll, 30000);
}
// The same setting as the toggle on the extension's page.
const autoHelper = document.getElementById('auto-helper');
chrome.storage.local.get('autoHelper').then(({autoHelper: on}) => { autoHelper.checked = !!on; }).catch(() => {});
autoHelper.addEventListener('change', async () => {
  const on = autoHelper.checked;
  autoHelper.disabled = true;
  helper.textContent = on ? 'Starting the helper…' : 'Stopping the helper…';
  try {
    await chrome.storage.local.set({autoHelper: on});
    const response = await chrome.runtime.sendMessage({type: on ? 'helper-auto-start' : 'helper-auto-stop', showWindow: showTerminal.checked});
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    // A helper takes a moment to start
    if (on) await new Promise(resolve => setTimeout(resolve, 3000));
    await refresh();
  } catch (error) {
    helper.textContent = 'The helper could not be changed: ' + String(error.message || error);
  } finally {
    autoHelper.disabled = false;
  }
});
stop.addEventListener('click', async event => {
  if (!event.isTrusted || stop.disabled) return;
  stop.disabled = true;
  helper.textContent = 'Stopping the helper\u2026';
  try {
    const response = await send('helper-stop');
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    await refresh();
  } catch (error) {
    helper.textContent = 'Could not stop the helper: ' + String(error.message || error);
  } finally {
    stop.disabled = false;
  }
});
const showTerminal = document.getElementById('show-terminal');
chrome.storage.local.get('showTerminal').then(({showTerminal: on}) => { showTerminal.checked = !!on; }).catch(() => {});
showTerminal.addEventListener('change', async () => {
  const on = showTerminal.checked;
  showTerminal.disabled = true;
  helper.textContent = on ? 'Showing the helper\u2019s window\u2026' : 'Hiding the helper\u2019s window\u2026';
  try {
    await chrome.storage.local.set({showTerminal: on});
    // A running automatic helper keeps the look it started with; restart it with the new one.
    if (autoHelper.checked) {
      await chrome.runtime.sendMessage({type:'helper-auto-stop'});
      const response = await chrome.runtime.sendMessage({type:'helper-auto-start', showWindow: on});
      if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
    await refresh();
  } catch (error) {
    helper.textContent = 'The terminal setting could not be applied: ' + String(error.message || error);
  } finally {
    showTerminal.disabled = false;
  }
});
document.getElementById('open-tools').addEventListener('click', event => {
  if (!event.isTrusted) return;
  chrome.tabs.create({url:chrome.runtime.getURL('control.html')});
});
document.getElementById('reload-extension').addEventListener('click', event => {
  if (event.isTrusted) chrome.runtime.reload();
});
poll();
