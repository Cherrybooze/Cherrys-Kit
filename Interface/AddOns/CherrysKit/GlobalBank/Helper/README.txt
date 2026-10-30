Global Bank helper

Global Bank shows every character's bags, bank and gold. Each character saves its own snapshot
when it logs out; this helper collects them so every character can see the others.

1. Double-click "Start Global Bank helper.bat".
2. Keep its window open while you play. Close it to stop.

If Advanced AuctionHouse Broad search stays grey while the helper is open, update the helper,
close its window and start it again. Wait about 30 seconds for the game to detect it.

The window says whenever a character is added or updated, and how many characters it tracks.
Notes you write in game (right-click a character, Add note) reach your other characters through it.
You can also type commands in it (the / and the word get are optional):
    get goldtotal        gold of all characters together
    get gold <name>      one character's gold
    list gold            all characters, richest first (also: list level, items, name, note)
    search <text>        which characters hold an item, and how many (bag and bank); notes too
    show <name>          one character's classes, note, daily reward, bag and bank
    add note <name> <text>  set a note (also: note <name> <text>)
    note <name>             clear the note
    daily                level 100+ daily reward status
    search warrior > 60  characters with warrior level 60 or higher
    erase <name>         remove a character from the helper and stop tracking it
    ban list             see excluded characters
    unban <name>         allow the helper to track that character again

The helper stores its exclusion list in Interface\GlobalBankHelper\ExcludedCharacters.json,
next to the private character database. Never share that folder. The list is not part of the addon.
Erasing does not delete the game character or its save file. After unbanning, update the helper to
read that character's saved data again. Class levels appear after logging in with the updated addon.
Daily status is based on the local reward confirmation and the reset at 00:00 in Germany, converted
to your time zone. Unknown means
there is no unambiguous confirmation; it does not prove whether a reward was collected.
    status               character count, uptime and heartbeat setting
    heartbeat on|off     enable/disable the text heartbeat (also: heartbeat 1|0)
    help                 all commands

The colored startup guide groups character commands and helper controls. With the heartbeat on,
one compact "alive" line is added about every 30 seconds; scroll history is kept and any partially
typed command is restored. Use heartbeat off for a quiet idle prompt. The setting is binary and
lasts for this helper session; to start quietly use GlobalBank-Update.ps1 -Watch -Heartbeat 0
(the default is -Heartbeat 1). File liveness for the addon continues with either setting, including
during long auction-cache imports. The heartbeat never clears or redraws the whole terminal.
Auction imports and their cleanup retries run in one background worker, so commands remain
available while a large import is processing. A named lock prevents simultaneous cache writers;
the queue contains character file paths only. Closing the helper also stops its worker.

Unexpected exits and individual failed maintenance jobs are recorded in the local diagnostic file
Interface\GlobalBankHelper\GlobalBankHelper-errors.log, with exception type, a redacted short message,
script stack and invocation file/line. Payloads, URLs and credential values are excluded. A failed
maintenance job does not stop the other jobs or watcher. A fatal startup/watch error stops the
helper with a visible message; correct its cause and start the helper again.

What it does: it reads Documents\Runes of Magic\<Name>\SaveVariables.lua (written by the game when
a character logs out) and writes the Global Bank lines from them to Interface\GlobalBankHelper,
which it creates next to Interface\AddOns. It needs no admin rights and does not use the internet. Character snapshots are read;
only acknowledged AAH outbox assignments are removed with the guards described below.

For your own tools: Interface\GlobalBankHelper\GlobalBank.json holds every character's bags, bank
and gold, and is rewritten after every change. GlobalBank-Data.ps1 has the reading and search
functions, and GlobalBank-Update.ps1 -Command "search mana" runs one command and exits.

Sharing: the CherrysKit folder is safe to share; it never contains your characters. Don't share
Interface\GlobalBankHelper: it shows what all your characters own.

Chrome daily reward extension (Windows)
1. From the installed Helper folder, run "Install Chrome extension.bat".
2. It opens Chrome's extensions page and a small setup window. Turn on Developer mode and click
   Load unpacked; the setup window fills in the folder and closes when the extension connects.
3. Open a level 100+ character's daily page through ZShop. The available reward is clicked.
   It is recorded only after the page marks that chest redeemed. When the shop shows a redeemed
   current chest and the next reward countdown, the popup reports the collection and wait time.
   Seeing an already-redeemed chest does not create a new collection timestamp. The popup reports
   success or errors; if the helper is closed, its prompt and popup can start the helper window.
   Rerun the installer after moving the addon. Chrome and the user must approve installation.

Local bank and auction tools in Chrome
1. Click the Global Bank Daily Rewards extension icon, then click "Open local bank and auction tools".
2. Bank tab: every character's bag and bank as in game. Update now reads your save files.
3. Terminal tab: the helper's commands, including note and erase, without its window.
4. Auctions tab: search the auction cache. Prices are saved observations and may have changed.
You only need the helper window for collecting auction data and for automatic updates each time you
log out. Nothing on the page can buy items. Keep Interface\GlobalBankHelper private.

The bank results come from your saved character snapshots. Auction results are the last prices
seen by the helper, so an item may have sold or its price may have changed. Search in the game's
auction house and allow the helper to collect its data if the cache is empty. The page only reads
your local files when you ask; it cannot buy items. Keep Interface\GlobalBankHelper private.

Privacy: automatic page processing runs on the Gameforge Runes of Magic daily loyalty page only;
the extension does not read or change unrelated websites. Pending collection details and status are kept in
Chrome's memory for the browser session, not stored long term by the extension. Confirmed
character name, server, reward day and collection time are saved on this computer by the
Global Bank helper in Interface\GlobalBankHelper for your own use. The extension does not
send that information to Cherry or any analytics service. The normal Collect action still
communicates with Gameforge as part of using its shop. Earlier extension versions may have
stored temporary details in Chrome local storage; these are cleared when the daily page is
next opened after updating the extension.

Data for external tools (all files are in Interface\GlobalBankHelper):
- GlobalBank.json: character snapshots with optional dailyLogin {collectedAt,server,day}
  and accountId, or null when unavailable/ambiguous. collectedAt is UTC in ISO 8601.
- DailyRewards.json: schemaVersion 1 and records [{name,server,day,collectedAt}].
  Written atomically by the extension bridge, then reflected in GlobalBank.json by the helper.
- CharacterLinks.json: editable schemaVersion 1, accounts and characters arrays. Example:
  {"schemaVersion":1,"accounts":[{"id":"account-1","label":"Main account"}],
   "characters":[{"name":"Example","accountId":"account-1"}]}
  These are local labels, not credentials. Unique name links are exported as accountId.
  The helper refreshes GlobalBank.json when either sidecar changes. If it was closed, start
  the helper or use its export command. Do not put passwords, login tokens, or authenticated
  shop URLs in these files. Game snapshots contain no server, so name matches cannot verify
  the server; same-name multiple-server records are not joined into the character export.


AAH broad quote cache (helper 1.4.5)
The helper also consumes the temporary AAH_BroadOutbox from individual character SaveVariables.lua
files. It never reads/writes AH data in the shared root SaveVariables.lua. AAHBroadCache.json and
AAHBroadCache.lua in Interface\GlobalBankHelper hold realm-separated quote snapshots and acknowledgements.
Only after both cache files are committed does it remove acknowledged AAH_BroadOutbox assignments
from the character file. Other bytes and the original save timestamp are preserved. A recoverable
SaveVariables.lua.AAH-helper.<id>.bak is made first; only these helper-owned backups expire after2days.
Busy, unsettled, changed or read-only files are not forced and are retried later. Malformed exports
remain for diagnosis. The game writes its outbox on its normal character-save cycle; the helper
cannot read unsaved game memory. Restart the helper after updating it, then Reload UI in the game.

After installing updated extension files, open its popup and click Reload extension, then reopen
the popup or local tools page. If your existing popup has no reload button, open chrome://extensions
and click Reload on Global Bank Daily Rewards once. Chrome keeps the old version loaded until then.
