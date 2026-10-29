'use strict';
(() => {
  const byId = id => document.getElementById(id);
  const status = byId('helper-status');
  const start = byId('start-helper');
  let starting = false;
  async function send(message) {
    const response = await chrome.runtime.sendMessage(message);
    if (!response?.ok) throw new Error(response?.error || 'No response from the local bridge.');
    return response;
  }
  async function checkHelper() {
    try {
      const response = await send({type:'helper-status'});
      status.textContent = response.running ? 'Helper is running.' : 'Helper is not running.';
      start.disabled = !!response.running || starting;
      return !!response.running;
    } catch (error) {
      status.textContent = 'Cannot reach the local bridge. Run Install Chrome extension.bat in the installed GlobalBank Helper folder. ' + String(error.message || error);
      start.disabled = true;
      return false;
    }
  }
  byId('check-helper').addEventListener('click', checkHelper);
  start.addEventListener('click', async event => {
    if (!event.isTrusted || starting) return;
    starting = true;
    start.disabled = true;
    status.textContent = 'Starting the helper…';
    let running = false;
    try {
      await send({type:'helper-start'});
      for (let i = 0; i < 10 && !running; i++) {
        if (i) await new Promise(resolve => setTimeout(resolve, 500));
        running = await checkHelper();
      }
      if (!running) status.textContent = 'The helper did not report ready. Check its window, then try again.';
    } catch (error) {
      status.textContent = 'Could not start the helper: ' + String(error.message || error);
    } finally {
      starting = false;
      start.disabled = running;
    }
  });
  async function run(form, output, message) {
    const button = form.querySelector('button[type="submit"]');
    button.disabled = true;
    output.textContent = 'Reading local data…';
    try {
      const response = await send(message);
      output.textContent = typeof response.output === 'string' ? response.output : 'No results.';
    } catch (error) {
      output.textContent = 'Could not read local data: ' + String(error.message || error);
    } finally { button.disabled = false; }
  }
  byId('bank-form').addEventListener('submit', event => {
    event.preventDefault();
    const command = byId('bank-command').value.trim();
    if (command) run(event.currentTarget, byId('bank-output'), {type:'bank-query',command});
  });
  byId('auction-form').addEventListener('submit', event => {
    event.preventDefault();
    const search = byId('auction-search').value.trim();
    const realm = byId('auction-realm').value.trim();
    if (search) run(event.currentTarget, byId('auction-output'), {type:'auction-query',search,realm});
  });
  checkHelper();
})();
