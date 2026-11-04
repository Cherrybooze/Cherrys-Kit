'use strict';
const helper = document.getElementById('helper');
const helperCard = document.getElementById('helper-card');
const helperBadge = document.getElementById('helper-badge');
const helperHint = document.getElementById('helper-hint');
const start = document.getElementById('start');
const stop = document.getElementById('stop');
const status = document.getElementById('status');
const reset = document.getElementById('reset');
const resetTime = document.getElementById('reset-time');
const autoHelper = document.getElementById('auto-helper');
const showTerminal = document.getElementById('show-terminal');
const getKit = document.getElementById('get-kit');
let starting = false;
let refreshTimer;
// The bridge says which version it is; older helper files lack what this extension asks for.
const BRIDGE_VERSION = 6;
const OLD_BRIDGE = 'Your Global Bank helper files are older than this extension. Update Cherry\u2019s Kit, then run Install Chrome extension.bat again.';

// The version Chrome is running now, so you can see that Reload took.
const versionLabel = document.getElementById('version');
if (versionLabel) versionLabel.textContent = 'Version ' + chrome.runtime.getManifest().version;

function setHelperVisual(state, badge, hint) {
  if (helperCard?.dataset) helperCard.dataset.state = state;
  if (helperBadge) helperBadge.textContent = badge;
  if (helperHint) {
    helperHint.textContent = hint || '';
    helperHint.hidden = !hint;
  }
}

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
function helperHintText(response) {
  if (!response.running) return starting ? '' : 'Start the helper below, or tick automatic mode so it runs with Chrome.';
  if (response.auto) {
    return (showTerminal?.checked ? 'Automatic mode (terminal window shown).' : 'Automatic mode (running in the background).')
      + ' Stop helper stops it and turns off automatic mode.';
  }
  return 'Running in its own window. Stop helper stops it.';
}

const collectionCheck = document.getElementById('collection-check');
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
  if (collectionCheck) collectionCheck.hidden = !collected;
  if (!collected) {
    status.textContent = 'Unknown: none recorded here. That doesn\u2019t mean a reward was missed.';
    return;
  }
  const clock = new Intl.DateTimeFormat(undefined, {dateStyle:'medium', timeStyle:'short'}).format(collected);
  status.textContent = record.name + (record.server ? ' \u00b7 ' + record.server : '') + '\n' + clock + ' (local time)';
  reset.hidden = !(latestReset(new Date()) > collected);
}
// What the daily page last reported about a collection. One Gameforge confirmed that couldn't be saved here says so,
// because that's not the same as a collection that failed. Its countdowns are out of date by now, so they stay out.
function showRewardNote() {
  const note = document.getElementById('reward-note');
  if (!note || !chrome.storage?.session?.get) return;
  chrome.storage.session.get('lastStatus').then(({lastStatus}) => {
    const shown = /^(Collection confirmed|Daily reward extension:)/.test(lastStatus || '') ? lastStatus : '';
    note.textContent = shown;
    note.hidden = !shown;
    note.classList.toggle('is-warning', /local save failed|^Daily reward extension:/.test(shown));
  }).catch(() => {});
}
async function send(type) {
  return chrome.runtime.sendMessage({type});
}
async function refresh() {
  try {
    const response = await send('helper-status');
    if (!response?.ok) {
      const missing = response?.errorKind !== 'native-error';
      helper.textContent = missing ? 'Native Messaging unavailable: the Global Bank helper is not set up on this PC. ' + (response?.error || 'No response from the local bridge.') : 'Local helper setup error: ' + response.error;
      start.hidden = true;
      stop.hidden = true;
      setHelperVisual('error', 'Setup needed', missing ? 'This extension needs Cherry\u2019s Kit with Global Bank on Windows. Install it, then run Install Chrome extension.bat in Interface\\AddOns\\CherrysKit\\GlobalBank\\Helper (again after each kit update).' : '');
      if (getKit) getKit.hidden = !missing;
      return false;
    }
    showCollection(response.lastCollected);
    if (response.rewardError) status.textContent = 'Could not read the last confirmed collection: ' + response.rewardError;
    helper.textContent = response.running ? helperRunText(response) : starting ? 'Starting the helper…' : 'Helper is not running.';
    start.hidden = false;
    start.disabled = response.running || starting;
    start.textContent = response.running ? 'Helper is running' : starting ? 'Starting helper…' : 'Start helper';
    stop.hidden = !response.running;
    if (getKit) getKit.hidden = true;
    setHelperVisual(
      response.running ? 'running' : starting ? 'busy' : 'stopped',
      response.running ? 'Running' : starting ? 'Starting\u2026' : 'Stopped',
      (Number(response.bridge) || 0) < BRIDGE_VERSION ? OLD_BRIDGE : helperHintText(response)
    );
    return response.running;
  } catch (error) {
    helper.textContent = 'Native Messaging unavailable: ' + String(error.message || error);
    start.hidden = true;
    stop.hidden = true;
    setHelperVisual('error', 'Unavailable', '');
    return false;
  }
}
start.addEventListener('click', async event => {
  if (!event.isTrusted || starting || start.disabled) return;
  starting = true;
  start.disabled = true;
  start.textContent = 'Starting helper…';
  setHelperVisual('busy', 'Starting\u2026', 'Waiting for the local helper window to report ready\u2026');
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
    setHelperVisual('stopped', 'Not ready', '');
  } catch (error) {
    helper.textContent = 'Could not start the helper: ' + String(error.message || error);
    setHelperVisual('error', 'Error', '');
  } finally {
    starting = false;
    if (start.textContent !== 'Helper is running') {
      start.disabled = false;
      start.textContent = 'Start helper';
    }
    refreshTimer = setTimeout(poll, 30000);
  }
});
async function poll() {
  showResetTime(new Date());
  showRewardNote();
  await refresh();
  refreshTimer = setTimeout(poll, 30000);
}
// Off unless the player turns it on: the daily page then clicks the reward by itself.
const autoCollect = document.getElementById('auto-collect');
if (autoCollect) {
  chrome.storage.local.get('autoCollect').then(({autoCollect: on}) => { autoCollect.checked = on === true; }).catch(() => {});
  autoCollect.addEventListener('change', () => { chrome.storage.local.set({autoCollect: autoCollect.checked}).catch(() => {}); });
}
// The same setting as the toggle on the extension's page.
chrome.storage.local.get('autoHelper').then(({autoHelper: on}) => { autoHelper.checked = !!on; }).catch(() => {});
autoHelper.addEventListener('change', async () => {
  const on = autoHelper.checked;
  autoHelper.disabled = true;
  helper.textContent = on ? 'Starting the helper…' : 'Stopping the helper…';
  setHelperVisual('busy', on ? 'Starting\u2026' : 'Stopping\u2026', '');
  try {
    await chrome.storage.local.set({autoHelper: on});
    const response = await chrome.runtime.sendMessage({type: on ? 'helper-auto-start' : 'helper-auto-stop', showWindow: showTerminal.checked});
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    // A helper takes a moment to start
    if (on) await new Promise(resolve => setTimeout(resolve, 3000));
    await refresh();
  } catch (error) {
    helper.textContent = 'The helper could not be changed: ' + String(error.message || error);
    setHelperVisual('error', 'Error', '');
  } finally {
    autoHelper.disabled = false;
  }
});
stop.addEventListener('click', async event => {
  if (!event.isTrusted || stop.disabled) return;
  stop.disabled = true;
  helper.textContent = 'Stopping the helper\u2026';
  setHelperVisual('busy', 'Stopping\u2026', 'Stopping the helper and turning off automatic mode\u2026');
  try {
    autoHelper.checked = false;
    await chrome.storage.local.set({autoHelper: false});
    const response = await send('helper-stop');
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    await refresh();
  } catch (error) {
    helper.textContent = 'Could not stop the helper: ' + String(error.message || error);
    setHelperVisual('error', 'Error', '');
  } finally {
    stop.disabled = false;
  }
});
chrome.storage.local.get('showTerminal').then(({showTerminal: on}) => { showTerminal.checked = !!on; }).catch(() => {});
showTerminal.addEventListener('change', async () => {
  const on = showTerminal.checked;
  showTerminal.disabled = true;
  try {
    await chrome.storage.local.set({showTerminal: on});
    // A running automatic helper keeps the look it started with, so it restarts with the new one. A stopped helper
    // just starts with it next time, and one you started yourself is left alone.
    const state = await send('helper-status');
    if (state?.running && state.auto) {
      helper.textContent = on ? 'Showing the helper\u2019s window\u2026' : 'Hiding the helper\u2019s window\u2026';
      setHelperVisual('busy', on ? 'Showing window\u2026' : 'Hiding window\u2026', '');
      await chrome.runtime.sendMessage({type:'helper-auto-stop'});
      const response = await chrome.runtime.sendMessage({type:'helper-auto-start', showWindow: on});
      if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
    await refresh();
  } catch (error) {
    helper.textContent = 'The terminal setting could not be applied: ' + String(error.message || error);
    setHelperVisual('error', 'Error', '');
  } finally {
    showTerminal.disabled = false;
  }
});
// One Global Bank page at a time: two would overwrite each other's Gameforge account changes. Chrome 116 and
// later can say whether it's open already; older ones open another, and the page itself warns.
document.getElementById('open-tools').addEventListener('click', async event => {
  if (!event.isTrusted) return;
  const url = chrome.runtime.getURL('control.html');
  try {
    const open = chrome.runtime.getContexts ? await chrome.runtime.getContexts({contextTypes:['TAB'], documentUrls:[url]}) : [];
    const page = open.find(context => context.tabId >= 0);
    if (page) {
      await chrome.tabs.update(page.tabId, {active:true});
      if (page.windowId >= 0 && chrome.windows) await chrome.windows.update(page.windowId, {focused:true});
      return;
    }
  } catch { /* open a new one */ }
  chrome.tabs.create({url});
});
document.getElementById('reload-extension').addEventListener('click', event => {
  if (event.isTrusted) chrome.runtime.reload();
});
poll();

// Game windows: the same choice as the page's Connection panel. The local host does the cascading.
const CASCADE_SCREENS = [[1920, 1080], [2560, 1440], [3440, 1440], [3840, 2160]];
// A size that suits a screen: the same share of its height as 1134 x 818 on a 1440p screen, same shape.
const cascadeSuggest = height => { const h = Math.round(height * 818 / 1440); return {width: Math.round(h * 1134 / 818), height: h}; };
// Fills the Display and Size lists: the displays Windows reports, or plain numbers when they can't be listed.
// Shows which screen's size Resolution holds: the one picked if it still matches, else the first that does,
// else "Pick a screen" (Resolution typed by hand).
function showCascadeSize(sizeSelect, width, height) {
  const key = `${width}x${height}`, options = [...sizeSelect.options];
  if (options[sizeSelect.selectedIndex]?.value === key) return;
  const index = options.findIndex(item => item.value === key);
  sizeSelect.selectedIndex = index > 0 ? index : 0;
}
function fillCascadeLists(monitorSelect, sizeSelect, monitors, chosen, width, height) {
  const option = (value, text) => { const item = document.createElement('option'); item.value = value; item.textContent = text; return item; };
  const listed = Array.isArray(monitors) && monitors.length ? monitors : null;
  monitorSelect.replaceChildren(option('0', 'Where the oldest game window is'));
  for (const monitor of listed || [1, 2, 3, 4].map(id => ({id}))) {
    monitorSelect.append(option(String(monitor.id), listed ? `Display ${monitor.id}: ${monitor.width} x ${monitor.height}${monitor.primary ? ' (main)' : ''}` : `Display ${monitor.id}`));
  }
  if (chosen && ![...monitorSelect.options].some(item => item.value === String(chosen))) monitorSelect.append(option(String(chosen), `Display ${chosen} (not found)`));
  monitorSelect.value = String(chosen || 0);
  const picked = sizeSelect.options[sizeSelect.selectedIndex]?.textContent;
  sizeSelect.replaceChildren(option('', 'Pick a screen'));
  const screens = (listed || []).map(monitor => [monitor.width, monitor.height, `Display ${monitor.id}`]).concat(CASCADE_SCREENS.map(([w, h]) => [w, h, '']));
  const seen = new Set();
  for (const [w, h, name] of screens) {
    const size = cascadeSuggest(h), key = `${size.width}x${size.height}`;
    if (!name && seen.has(key)) continue;
    seen.add(key);
    sizeSelect.append(option(key, `${name ? name + ', ' : ''}${w} x ${h} screen: ${size.width} x ${size.height}`));
  }
  const again = [...sizeSelect.options].findIndex(item => item.textContent === picked);
  if (again > 0) sizeSelect.selectedIndex = again;
  showCascadeSize(sizeSelect, width, height);
}
const cascadeMonitor = document.getElementById('cascade-monitor');
const cascadeSize = document.getElementById('cascade-size');
const cascadeTop = document.getElementById('cascade-top');
let cascadeMonitors = null;
const cascadeNow = document.getElementById('cascade-now');
const cascadeStatus = document.getElementById('cascade-status');
const cascadeQuick = document.getElementById('cascade-quick');
const cascadeQuickStatus = document.getElementById('cascade-quick-status');
const cascadeUnderBank = document.getElementById('cascade-under-bank');
let cascadeStored = {};
const cascadeFields = [['cascade-width', 'width', 16000], ['cascade-height', 'height', 16000], ['cascade-step-x', 'stepX', 1000], ['cascade-step-y', 'stepY', 1000]]
  .map(([id, key, most]) => ({input: document.getElementById(id), key, most})).filter(field => field.input);
const showCascadeStored = () => {
  if (cascadeTop) cascadeTop.checked = cascadeStored.onTop === true;
  for (const {input, key} of cascadeFields) if (document.activeElement !== input) input.value = cascadeStored[key] > 0 ? String(cascadeStored[key]) : '';
  if (cascadeMonitor && cascadeSize) fillCascadeLists(cascadeMonitor, cascadeSize, cascadeMonitors, Number.isInteger(cascadeStored.monitor) ? cascadeStored.monitor : 0,
    cascadeStored.width || '', cascadeStored.height || '');
};
const saveCascade = async () => {
  cascadeStored = {corner: 'bottom-left', fit: true, ...cascadeStored};
  delete cascadeStored.on;
  if (cascadeMonitor) cascadeStored.monitor = Math.max(0, Math.floor(Number(cascadeMonitor.value)) || 0);
  if (cascadeTop) cascadeStored.onTop = cascadeTop.checked;
  for (const {input, key, most} of cascadeFields) {
    const n = Math.floor(Number(input.value));
    cascadeStored[key] = input.value !== '' && n > 0 && n <= most ? n : 0;
  }
  await chrome.storage.local.set({windowCascade: cascadeStored});
};
// The button can sit under Open Global Bank instead of in here.
const placeCascadeButton = under => {
  if (cascadeUnderBank) cascadeUnderBank.checked = under;
  if (cascadeQuick) cascadeQuick.hidden = !under;
  if (cascadeQuickStatus && !under) cascadeQuickStatus.hidden = true;
  if (cascadeNow) cascadeNow.hidden = under;
};
async function runCascade(button, line) {
  button.disabled = true;
  line.hidden = false;
  line.textContent = 'Cascading\u2026 The first time, allow the Windows prompt.';
  try {
    await saveCascade();
    const result = await chrome.runtime.sendMessage({type:'windows-cascade', cascade: cascadeStored});
    if (!result?.ok) throw new Error(result?.error || 'No response from the local bridge.');
    const missing = result.monitorMissing ? ` Display ${result.monitorMissing} isn\u2019t connected.` : '';
    const refused = result.refused ? ` Windows refused to move ${result.refused}: ${result.refused === 1 ? 'it runs' : 'they run'} as administrator. Press again and allow the Windows prompt.` : '';
    line.textContent = !result.found ? 'No Runes of Magic window is open.'
      : `Cascaded ${result.moved} game window${result.moved === 1 ? '' : 's'}.${refused}${missing}`;
  } catch (error) {
    line.textContent = 'Could not cascade: ' + String(error.message || error);
  } finally {
    button.disabled = false;
  }
}
if (cascadeNow && cascadeStatus) {
  chrome.storage.local.get(['windowCascade', 'cascadeUnderBank']).then(({windowCascade, cascadeUnderBank: under}) => {
    cascadeStored = windowCascade || {};
    showCascadeStored();
    placeCascadeButton(under === true);
  }).catch(() => {});
  for (const {input} of cascadeFields) input.addEventListener('change', saveCascade);
  // Resolution typed by hand: the Size list goes back to "Pick a screen".
  const resolution = cascadeFields.filter(({key}) => key === 'width' || key === 'height').map(({input}) => input);
  for (const input of resolution) input.addEventListener('input', () => cascadeSize && showCascadeSize(cascadeSize, resolution[0].value, resolution[1].value));
  cascadeMonitor?.addEventListener('change', saveCascade);
  cascadeTop?.addEventListener('change', saveCascade);
  cascadeSize?.addEventListener('change', () => {
    const [width, height] = cascadeSize.value.split('x').map(Number);
    if (!width || !height) return;
    for (const {input, key} of cascadeFields) if (key === 'width' || key === 'height') input.value = String(key === 'width' ? width : height);
    saveCascade();
  });
  chrome.runtime.sendMessage({type:'windows-monitors'}).then(response => {
    if (!response?.ok) return;
    cascadeMonitors = response.monitors;
    showCascadeStored();
  }).catch(() => {});
  cascadeNow.addEventListener('click', () => runCascade(cascadeNow, cascadeStatus));
  cascadeQuick?.addEventListener('click', () => runCascade(cascadeQuick, cascadeQuickStatus));
  cascadeUnderBank?.addEventListener('change', async () => {
    placeCascadeButton(cascadeUnderBank.checked);
    await chrome.storage.local.set({cascadeUnderBank: cascadeUnderBank.checked});
  });
}
