# Global Bank for RoM: privacy policy

Applies to the Chrome extension **Global Bank for RoM** and its local helper, part of [Cherry's Kit](https://github.com/Cherrybooze/Cherrys-Kit) for Runes of Magic. Last updated 4 November 2026.

It is an independent community tool, not made by or affiliated with Gameforge.

## The short version

Everything the extension reads or saves stays on your own PC. There is no developer server, no account with us, no analytics and no advertising. Nothing is sold, shared or sent to the developer or anyone else. The only websites it works on are Gameforge's own Runes of Magic item shop and the Runes of Magic site's character transfer and account pages, in the tab you opened. When you press **Check for updates** or an install button on the Addons page, the local helper downloads Cherry's Kit's release files from GitHub, like any download, and sends nothing about you.

## What it reads

- **The shop's daily loyalty page** (`https://<server>-shop-runesofmagic.gameforge.com/dailies/display/5`): the character name and server shown on the page, and the state of the reward chests. If you tick **Collect the daily reward automatically** in the popup (off by default), it also clicks the available reward for you.
- **The shop's item depot page**, while you have it open: the item names, counts and picture addresses listed there. It never keeps the page's address, which holds a private sign-in token.
- **Your game's save files**, through the local helper or through folders you choose on the page: each character's macros and addon settings (shown on the page, and copied to the helper folder as backups), and its bags, bank, gold, currencies, what it wears, what its mailbox held when last open, the mail it sent (recipient, subject, gold and items, the newest 360) and the list of characters on an account, which Global Bank writes into `Documents\Runes of Magic`.
- **The Runes of Magic site's character transfer page** (`https://<language>.runesofmagic.gameforge.com/charactertransfer`), while you have it open: the transfers it lists as planned (character, its server and the server it goes to) and the characters its form offers, each with its server. It looks through the page's text to find them, and never clicks, fills in or sends anything there.
- **The login's RoM username and Gameforge e-mail address**, on that transfer page and on the site's account page (`https://<language>.runesofmagic.gameforge.com/user/administration`), while you have them open, together with the characters those pages list. They name those characters' RoM and Gameforge accounts on the Global Bank page. No password, no link, nothing else from those pages.
- **The helper's auction cache**: auction results Advanced AuctionHouse saved while you searched in game.

## What it keeps, and where

- **Chrome's storage for this extension**, on your PC: your settings, the Stats page's excluded-stat list, the depot list, short-lived status text, and the character transfer log: each transfer's character, servers, when it was registered and what became of it, the characters the same transfer page offered with it, and the weekly maintenance time you set; and, for each character the site's pages listed, the RoM username and Gameforge e-mail address shown with it. These are not encrypted. What a transfer page tab showed last, and the username and e-mail address the site showed last, are kept only until Chrome closes. These use local storage, not Chrome Sync. Only the extension's own pages can read local storage; scripts on web pages cannot.
- **Gameforge accounts page (optional)**: if you use it, the account names, passwords, secondary passwords and notes you type are encrypted with AES-GCM before they are saved. The key comes from a password you choose, which is never stored, mixed with a random key kept in Chrome's storage for this extension (PBKDF2 with SHA-256, 600,000 rounds). The encrypted file is saved in Chrome and as `Interface\GlobalBankHelper\GameforgeAccounts.json` on your PC. Without your password it cannot be opened, and it is never sent anywhere.
- **The helper folder** `Interface\GlobalBankHelper` in your game folder: the combined character data (`GlobalBank.json`, `GlobalBankDatabase.lua`), the game's tooltips and your characters' mail (`GlobalBankTips.txt`, `GlobalBankMail.txt`), confirmed daily rewards (`DailyRewards.json`: character, server, day and time), the auction cache, the current time for the game's addons (`CherrysClockStamp.lua`) and the helper's logs.

Steam and Gameforge clients on the same PC can use the same local helper folder. This shares data between your own clients only. The folder, character saves, encrypted accounts, backups and terminal records are private: they are excluded from Git and release packages, including temporary copies and saved older helper folders. Distributing Cherry's Kit does not distribute those files. Keep `GlobalBankHelper` outside the addon/source folders when copying or sharing the kit.

## Permissions

- **storage**: settings and the encrypted accounts copy, as above.
- **alarms**: a signal once a minute to the local helper, so it knows Chrome is still open.
- **nativeMessaging**: talks to the Global Bank helper, a PowerShell script on your own PC, which reads the save files and writes the helper folder. It is installed separately by `Install Chrome extension.bat` and runs only on your computer.
- **Changing your addons**: only when you press a button on the Addons page. Updates keep the old version in `Interface\offloaded_addons`, and Delete asks first and uses the Recycle Bin.
- **Changing your save files**: only when you press a button on the Macros or Addon settings page. The helper keeps a copy of the file it replaces first.
- **Macro library**: every macro your characters have, and your groups, stay in the helper folder (`MacroLibrary.json`, and `GlobalBankMacros.lua` for the game's macro window). The helper reads the list of the game's macro icons from the game's `interface.fdb`.
- **Gameforge pages**: the extension's scripts run only on the shop's daily loyalty and item depot pages and on the Runes of Magic site's character transfer and account pages, and check the exact address before doing anything.

## Your choices

- Turn automatic collecting on or off in the popup at any time.
- **Forget** on the Characters page's Transfers list removes a transfer from the log.
- **Forget the site's account details**, in a character's right-click menu, removes the RoM username and e-mail address kept for the characters on its account.
- The Gameforge accounts page is optional. **Forgot your password? Delete these accounts and start again** on that page removes both encrypted copies and the random key.
- To remove everything: remove the extension from Chrome (this clears its storage), and delete the `Interface\GlobalBankHelper` folder.

## Contact

Questions or problems: open an issue at <https://github.com/Cherrybooze/Cherrys-Kit/issues>, or message **cherry** on Discord.
