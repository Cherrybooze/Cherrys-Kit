const helper = document.getElementById('helper');
const start = document.getElementById('start');
let tabId;
async function send(type) {
  return chrome.tabs.sendMessage(tabId, {type:'popup-' + type});
}
async function refresh() {
  try {
    const r = await send('helper-status');
    helper.textContent = !r?.ok ? 'Local bridge unavailable: ' + (r?.error || 'unknown error') : r.running ? 'Helper is running.' : 'Helper is not running.';
    start.hidden = !r?.ok || r.running;
  } catch (_) {
    helper.textContent = 'Open the Runes of Magic daily loyalty page to use the extension.';
    start.hidden = true;
  }
}
start.addEventListener('click', async () => {
  start.disabled = true;
  try {
    const r = await send('helper-start');
    helper.textContent = r?.ok ? 'Starting the helper window…' : 'Could not start helper: ' + (r?.error || 'unknown error');
    if (r?.ok) setTimeout(refresh, 2500);
  } catch (_) { helper.textContent = 'Open the Runes of Magic daily loyalty page to use the extension.'; }
  start.disabled = false;
});
(async () => {
  const [tab] = await chrome.tabs.query({active:true,currentWindow:true});
  if (!tab?.id) { helper.textContent = 'Open the Runes of Magic daily loyalty page to use the extension.'; return; }
  tabId = tab.id;
  try {
    const response = await send('helper-status');
    if (!response) throw new Error('Not a supported daily page');
    const {lastStatus} = await chrome.storage.session.get('lastStatus');
    if (lastStatus) document.getElementById('status').textContent = lastStatus;
    helper.textContent = !response.ok ? 'Local bridge unavailable: ' + (response.error || 'unknown error') : response.running ? 'Helper is running.' : 'Helper is not running.';
    start.hidden = !response.ok || response.running;
  } catch (_) { helper.textContent = 'Open the Runes of Magic daily loyalty page to use the extension.'; }
})();
