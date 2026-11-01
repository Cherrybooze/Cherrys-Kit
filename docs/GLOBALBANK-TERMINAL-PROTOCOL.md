# Global Bank terminal protocol

One command language with two views: the helper's own console window and the extension page's Terminal view. PowerShell is the only place commands are understood. The page and the console both draw the same records.

## Who does what

| Part | File |
| --- | --- |
| Command catalogue, parser, dispatcher, records, plain-text layout | `Helper/GlobalBank-Commands.ps1` |
| Mailbox, activity feed, helper state, what the local host answers | `Helper/GlobalBank-Bridge.ps1` |
| Console window: drawing records, line editor | `Helper/GlobalBank-Console.ps1` |
| Native messaging frames and the persistent port's loop | `Helper/GlobalBank-NativeHost.ps1` |
| Page-to-host route, port lifetime | `ChromeExtension/background.js` |
| Terminal view: drawing records, input, follow | `ChromeExtension/terminal.js` (page) |

Commands reach the watcher through a mailbox in `Interface\GlobalBankHelper\TerminalBridge`. The watcher handles them on its own loop, between save scans, so a note or exclusion from the page can't leave a stale model. With no helper running, data commands run once in a separate process and say so. Session commands (`heartbeat`, `exit`) report that no helper is running.

## Messages from the page

All go through `chrome.runtime.sendMessage`. Only `control.html` may send them. background.js keeps one native port open while they arrive and closes it after 30 seconds without any.

### `{type:'terminal-command', requestId, command}`

`command` is literal text of at most 256 characters. `requestId` matches `^[A-Za-z0-9-]{8,64}$`. Never resend a request by yourself: the same `requestId` returns the first answer rather than running twice, but only for the last 32 requests.

### `{type:'terminal-confirm', requestId, token, answer}`

While a confirm is pending, everything typed goes here, and buttons send `yes` or `no`. The reply has the normal shape: outcome `ok` when it ran or was cancelled, `confirm` with a new confirm record if the text wasn't an answer, `error` when the token expired (after 2 minutes). Confirms aren't kept anywhere, so a page reload drops them.

### Reply to both

```
{ok, requestId, commandId, outcome, source, records, helper, changed, maybeApplied?, omitted?}
```

| Field | Meaning |
| --- | --- |
| `ok` | true only for outcome `ok` or `confirm`. Draw `records` either way. |
| `outcome` | `ok`, `error`, `confirm`, `timeout`, `no-helper`, or `bridge` (the native host itself failed, `error` holds the text) |
| `source` | `live` (the running helper) or `offline` (saved data; `records[0]` already says so) |
| `changed` | saved data changed: run the coalesced `bank.reload({ifChanged:true})` |
| `maybeApplied` | with `timeout`: the command may still have run. Say so and don't resend. |
| `omitted` | rows left out to stay under the size limit; a note in the records says so |
| `helper.stopping` | the helper acknowledged `exit` and is stopping |

### Records

Text only. Tones: `ok`, `info`, `warn`, `error`, `gold`, `muted`.

- `{kind:'message', tone, text, small?}`
- `{kind:'table', title?, caption?, columns:[{label, numeric?, gold?, wrap?}], rows, total?:{label, value}, notes?:[text], omitted?}`. A row is an array of cells or `{heading:'text'}`, spanning all columns. A cell is a formatted string or `{text, tone}`.
- `{kind:'status', title?, pairs:[{label, value, tone?}], notes?:[text]}`
- `{kind:'help', groups:[{name, rows:[{usage, text}]}], notes:[text]}`
- `{kind:'error', code, text, usage?}`. Codes: `usage`, `unknown-command`, `not-found`, `ambiguous`, `no-helper`, `invalid`, `confirm-expired`, `failed`.
- `{kind:'confirm', token, text, yes, no, prompt}`. `yes` and `no` are button labels. Show `prompt` as sent.
- `{kind:'control', action:'clear'|'copy'|'follow', value?:'on'|'off', messages?}`. `messages` holds the wording for the result: `{done, failed}` for copy, `{on, off}` for follow. Draw the one that applies as a message with tone `ok` (`failed` with tone `warn`). `clear` has no message.

### `{type:'terminal-feed', session, after, max}`

```
{ok, session, seq, gap, more, events, helper}
```

`events` are `{seq, time, kind, tone, text, character?, dataChanged?}`, with `time` as ISO UTC and `kind` one of `updated`, `loaded`, `heartbeat`, `notice`. `gap` is null or `{from, to}` when records you hadn't read were discarded. Pass `session:null` on first load to get the latest `max` events (default 50, at most 200) and no gap. A different `session` means the helper restarted. `more:true` means the byte limit cut the reply short, so ask again with the new `seq`.

### `{type:'terminal-catalogue'}`

```
{ok, version, prefixes:['/', 'get '], commands:[{id, complete, more, usage, text, group, aliases, arg}], characters, excluded}
```

`complete` is what Tab fills in, `more` lists further completions such as `list gold`, and `arg` is `character`, `excluded` or null. `characters` and `excluded` come from the helper's last written list, so completion still works when it's stopped.

### Helper state, in every reply

```
{running, stopping, auto, hidden, since, uptimeSeconds, characters, gold, snapshot, lastScan, heartbeatText, watching, state, bridged}
```

`state` is `loading`, `watching`, `stopped` or `unknown`. `characters`, `gold` and `lastScan` are null while loading and when stopped, never 0. `bridged` is false when an older helper without the mailbox is running. Treat that as `unknown` and suggest restarting it.

## Examples

Real answers from a helper with made-up characters.

`heartbeat off with the helper stopped`:

```json
{"requestId": "page-0003-abcd", "records": [{"code": "no-helper", "text": "No helper is running, so there is no heartbeat to change. Start the helper first.", "kind": "error"}], "ok": false, "source": "offline", "helper": {"auto": false, "uptimeSeconds": null, "state": "stopped", "hidden": false, "since": null, "running": false, "lastScan": null, "bridged": false, "stopping": false, "snapshot": null, "watching": false, "characters": null, "gold": null, "heartbeatText": null}, "commandId": "heartbeat", "outcome": "no-helper", "changed": false}
```

`search mana`:

```json
{"requestId": "page-0001-abcd", "records": [{"caption": "Items and who holds them", "rows": [{"heading": "Mana Potion: 40 on 1 character"}, ["Sampleone", "40", "bag 40"], {"heading": "Mana Stone: 12 on 2 characters"}, ["Sampleone", "10", "bag 4, bank 6"], ["Sampletwo", "2", "bank 2"]], "columns": [{"wrap": true, "label": "CHARACTER"}, {"numeric": true, "label": "QTY"}, {"label": "WHERE"}], "kind": "table"}], "ok": true, "source": "live", "helper": {"auto": false, "uptimeSeconds": 3, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "commandId": "search", "outcome": "ok", "changed": false}
```

`erase Sampletwo`:

```json
{"requestId": "page-0002-abcd", "records": [{"text": "Stop tracking Sampletwo? This removes it from Global Bank and blocks the name Sampletwo until you type unban Sampletwo. Game save files are not changed.", "no": "Cancel", "prompt": "Type y to confirm or n to cancel.", "token": "eyJjIjoiQ2FuY2VsbGVkLiBOb3RoaW5nIHdhcyBjaGFuZ2VkLiIsImUiOjE3OTM1NjI2NzQsInQiOiJTdG9wIHRyYWNraW5nIFNhbXBsZXR3bz8gVGhpcyByZW1vdmVzIGl0IGZyb20gR2xvYmFsIEJhbmsgYW5kIGJsb2NrcyB0aGUgbmFtZSBTYW1wbGV0d28gdW50aWwgeW91IHR5cGUgdW5iYW4gU2FtcGxldHdvLiBHYW1lIHNhdmUgZmlsZXMgYXJlIG5vdCBjaGFuZ2VkLiIsImEiOiJlcmFzZSIsIm4iOiJTYW1wbGV0d28ifQ==", "kind": "confirm", "yes": "Remove Sampletwo"}], "ok": true, "source": "live", "helper": {"auto": false, "uptimeSeconds": 4, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "commandId": "erase", "outcome": "confirm", "changed": false}
```

`status`:

```json
{"requestId": "page-0004-abcd", "records": [{"notes": ["File liveness continues with either heartbeat setting. Type help for command groups."], "kind": "status", "pairs": [{"label": "Helper", "tone": "ok", "value": "Running 0 min, in its own window"}, {"value": "2", "label": "Characters"}, {"label": "Saved gold", "tone": "gold", "value": "1,500"}, {"value": "on (1)", "label": "Text heartbeat"}, {"value": "Written every 30 seconds with either heartbeat setting", "label": "Game file liveness"}, {"value": "C:\\Games\\Runes of Magic\\...", "label": "Watching"}, {"value": "Last heard from 0 seconds ago", "label": "Chrome extension"}]}], "ok": true, "source": "live", "helper": {"auto": false, "uptimeSeconds": 4, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "commandId": "status", "outcome": "ok", "changed": false}
```

`follow off`:

```json
{"requestId": "page-0005-abcd", "records": [{"messages": {"on": "Follow is on · showing the latest output.", "off": "Follow is paused · new output will not move your place."}, "value": "off", "action": "follow", "kind": "control"}], "ok": true, "source": "live", "helper": {"auto": false, "uptimeSeconds": 5, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "commandId": "follow", "outcome": "ok", "changed": false}
```

`terminal-feed, first look`:

```json
{"seq": 7, "ok": true, "more": false, "helper": {"auto": false, "uptimeSeconds": 5, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "events": [{"time": "2026-11-01T19:49:12Z", "tone": "muted", "kind": "notice", "text": "Watching C:\\Games\\Runes of Magic\\...", "seq": 5}, {"time": "2026-11-01T19:49:12Z", "tone": "gold", "kind": "loaded", "text": "Global Bank is ready. 2 characters loaded, 1,500 gold. Watching for saves.", "seq": 6}, {"time": "2026-11-01T19:49:14Z", "tone": "muted", "kind": "notice", "text": "From the browser: erase Sampletwo", "seq": 7}], "gap": null, "session": "ff2e94a6ef4d4b59acde56b464f99fe1"}
```

`terminal-catalogue (first three commands)`:

```json
{"version": 1, "prefixes": ["/", "get "], "banner": [{"tone": "muted", "small": true, "text": "Try: goldtotal | list gold | search mana stone | show <name> | help", "kind": "message"}], "ok": true, "commands": [{"arg": null, "complete": "goldtotal", "group": "CHARACTERS & ITEMS", "id": "goldtotal", "more": [null], "aliases": ["goldtotal", "totalgold", "total"], "usage": "goldtotal", "text": "Gold of all characters together"}, {"arg": "character", "complete": "gold ", "group": "CHARACTERS & ITEMS", "id": "gold", "more": ["gold total"], "aliases": ["gold"], "usage": "gold <name>", "text": "One character's gold"}, {"arg": null, "complete": "list", "group": "CHARACTERS & ITEMS", "id": "list", "more": ["list gold", "list level", "list items", "list name", "list note", "list saved"], "aliases": ["list", "chars", "characters"], "usage": "list [gold|level|items|name|note|saved] [text]", "text": "Sort characters; add text to filter names or notes"}], "excluded": [], "helper": {"auto": false, "uptimeSeconds": 6, "state": "watching", "hidden": false, "since": "2026-11-01T19:49:11Z", "running": true, "lastScan": "2026-11-01T19:49:12Z", "bridged": true, "stopping": false, "snapshot": "2026-11-01T19:49:12Z", "watching": true, "characters": 2, "gold": 1500, "heartbeatText": true}, "characters": ["Sampleone", "Sampletwo"]}
```

## Older callers

`{type:'bank-command', command}` still works and answers `{ok:true, output, result}`: `output` is the records as plain text and `result` is the envelope above. `ok` there only means the bridge answered.
