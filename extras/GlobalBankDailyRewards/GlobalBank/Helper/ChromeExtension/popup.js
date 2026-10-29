'use strict';
const helper = document.getElementById('helper');
const start = document.getElementById('start');
const status = document.getElementById('status');
const reset = document.getElementById('reset');
let starting = false;
let refreshTimer;

function collectionTime(value) {
  // Only a real, timezone-qualified confirmation can establish a collection.
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d{2}:\d{2})$/i.test(value)) return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
}
function latestReset(now) {
  const boundary = new Date(now);
  boundary.setHours(1, 0, 0, 0);
  if (boundary > now) boundary.setDate(boundary.getDate() - 1);
  return boundary;
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
    helper.textContent = response.running ? 'Helper is running.' : starting ? 'Starting the helper…' : 'Helper is not running.';
    start.hidden = false;
    start.disabled = response.running || starting;
    start.textContent = response.running ? 'Helper is running' : starting ? 'Starting helper…' : 'Start Global Bank helper';
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
  await refresh();
  refreshTimer = setTimeout(poll, 30000);
}
document.getElementById('open-tools').addEventListener('click', event => {
  if (!event.isTrusted) return;
  chrome.tabs.create({url:chrome.runtime.getURL('control.html')});
});
document.getElementById('reload-extension').addEventListener('click', event => {
  if (event.isTrusted) chrome.runtime.reload();
});
poll();
