# Cherry's Loginxml

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Optional, when you have them:** LogNextChar (Next and Prev character buttons in game).
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
