# Cherry's Loginxml

> **Requires:** Cherry's Kit (hub 0.4.25 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysLoginxmlHook`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **LogNextChar:** Next and Prev character buttons in game
> - **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\CherrysLoginxml` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one. Install login screen.bat removes that folder for you. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer replaces whatever is there and keeps your saved logins.
>
> **After installing:** close the game and double-click `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there.

**A better login screen: gets past a stuck "obtaining server list", remembers your logins and works from the keyboard.**

A replacement for the game's login screen. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

## Features

- **Gets past a stuck "obtaining server list"**, including for Steam and Gameforge launcher logins, which retry on their own.
- **Saved logins**, with account or character lists and notes for NoCheckVersion accounts.
- **Fills in the secondary password.**
- **Cleaner server and character select**, usable from the keyboard: Up and Down to choose, Enter to go, Esc to go back.
- **Settings as toggle buttons on the server screen.** A click applies at once, and the game saves it when you log out or quit.
- **Log straight in**: when an account has only one character, or the first character in the list. Hold Ctrl to stop at character select anyway.
- **Joins your preferred channel.**
- Works with **LogNextChar** for Next and Prev buttons in game.

## Install

1. Remove any other login addon first. Only one can replace the login screen.
2. Install this addon, or extract the zip into `Interface\AddOns`.
3. Close the game and double-click `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there. It leaves nothing running.
4. Start the game. The login screen shows `(Cherry's Loginxml)` and its version next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings, and the addon tells you in chat if you forget.

## Your accounts and passwords

Saved logins are kept in plain files on your own PC, in `Interface\loginxml`. **They hold passwords: never share them, and never send them with a bug report.**

## Bug reports

Write to **cherry** on the Runes of Magic Discord.

## Credits and licence

- Original project: **Rom Autologin by Pyrrhus**, MIT licence. Integration fixes by **Cherry**.
- Full licence text: `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\LICENSE.txt`.
