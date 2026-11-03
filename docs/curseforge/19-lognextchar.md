# LogNextChar

> **Requires:** Cherry's Kit (hub 0.4.27 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LogNextChar`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **Alone or in the full kit:** installed alone, with just the hub, everything on this page works except the parts below. Each needs the addon named, and is missing until you install that addon too, or the full kit:
> - **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
> - **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
>
> **Older copies:** this addon has no original to give way to, but if any of `Interface\AddOns\LogNextChar`, `Interface\AddOns\CherrysLoginxml` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Move that folder out of AddOns (`!setup_cherryskit.bat` offers to) and Reload UI to use this one. Install login screen.bat, or the guided setup, moves those folders to `Interface\offloaded_addons` for you, along with `CherrysKit\CherrysLoginxmlHook` from before Cherry's Loginxml became part of this addon. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer updates what is there, copies the old folder to `Interface\offloaded_addons` first, and keeps your saved logins.
>
> **After installing:** close the game and run `!setup_cherryskit.bat`, or double-click `Interface\AddOns\CherrysKit\LogNextChar\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there. Until then, Next and Prev only log you out.

**Next and Prev buttons in game that log you straight into the neighbouring character, with a better login screen included.**

Made for alts. One click, and you are on the next character without touching the login screen. The login screen is what picks the character, and it's also a replacement for the game's own. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

## Recent changes

- **1.4.0**: a modern login screen in the style of rom weakauras and Cherry's Bar, with gold beside a coin on the character screen, tidier character, server and settings panels, and new check boxes. **Modern look** in the settings panel switches back to the game's own look at once.
- **1.3.4**: `Install login screen.bat` asks Windows for administrator rights and installs in that window, so a protected game folder can't refuse it.
- **1.3.3**: Next and Prev no longer stay on the character screen. The login screen waits for the whole character list before it picks, and a logout you cancel drops the queued switch. Run `Install login screen.bat` again after updating.

## Features

- **Next and Prev buttons** just below the minimap, Next on top and Prev under it, the same way round as the character list. They follow the minimap at any UI scale or resolution.
- **Hover to see who is next.** The tooltip names the character each button will pick.
- **Greyed out when there is nobody to switch to**, on accounts with one character.
- **Safe switching**: the mailbox and Ultimate Mail Mod's window close first. On the character screen, clicking a character or using the arrow keys cancels a switch, and one that can't finish within 15 seconds leaves the choice to you.
- **Move them if you like**: unlock them in the settings window, then right-drag or Shift+drag.
- **A row in the Cherry's Kit hub** (`/ck`), whose Settings button opens the settings window.
- For macros, `ChangeChar(slot)` does the same as `/lnc <slot>`.

## Commands

- `/lnc` or `/lnc next`: the next character
- `/lpc` or `/lnc prev`: the previous character
- `/lnc current`: log out and back in to the same character
- `/lnc 3`: the character in slot 3, in the order the characters were created
- `/lnc settings`: the settings window
- `/lnc show`, `/lnc hide`: show or hide the buttons
- `/lnc lock`, `/lnc unlock`: stop or allow moving them
- `/lnc reset`: put them back in their default spot
- `/lnc probe`: positions and state, for a bug report

## The login screen

- **Gets past a stuck "obtaining server list"**, including for Steam and Gameforge launcher logins: the Retry button counts down and asks for the server list again by itself (click it to retry at once).
- **Saved logins**, with account or character lists and notes for NoCheckVersion accounts.
- **Fills in the secondary password.**
- **A modern look**, or the game's own: flat dark panels, gold beside a coin, lists that fit what is in them and grouped settings. **Modern look** in the settings panel switches between them at once.
- **Cleaner server and character select**, usable from the keyboard: Up and Down to choose, Enter to go, Esc to go back.
- **Settings as toggle buttons on the server screen.** A click applies at once, and the game saves it when you log out or quit. **Use config.lua** forgets the saved toggles and goes back to the file.
- **Log straight in**: when an account has only one character, or the first character in the list. Hold Ctrl to stop at character select anyway.
- **Joins your preferred channel.**
- **With Global Bank**: each character's gold and last save on the character screen, and the helper's status on the server screen. Logging in also gives Global Bank your account's character list, which boxes those characters together on its page and fills in their servers.

## Install

1. Remove any other login addon first. Only one can replace the login screen.
2. Install this addon, or extract the zip into `Interface\AddOns`.
3. Close the game and run `!setup_cherryskit.bat`, or double-click `Interface\AddOns\CherrysKit\LogNextChar\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there. If you already have a `loginxml`, a copy of it goes to `Interface\offloaded_addons` first, and only the files that differ change. That copy holds any saved passwords it had, so keep it private. It leaves nothing running.
4. Start the game. The login screen shows `(LogNextChar)` and its version next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings, and the addon tells you in chat if you forget.

## Your accounts and passwords

Saved logins are kept in plain files on your own PC, in `Interface\loginxml`. **They hold passwords: never share them, and never send them with a bug report.**

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/lnc probe` if you can.

## Credits and licence

- Next and Prev buttons by **Cherry**, MIT licence: `Interface\AddOns\CherrysKit\LogNextChar\LICENSE.txt`.
- Login screen: original project **Rom Autologin by Pyrrhus**, MIT licence, integration fixes by **Cherry**: `Interface\AddOns\CherrysKit\LogNextChar\LICENSE-Loginxml.txt`.
