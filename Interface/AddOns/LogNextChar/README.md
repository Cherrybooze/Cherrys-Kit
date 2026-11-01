# LogNextChar

Version **1.3.2** · Kit release **0.11.115** · [All addons / hub](../CherrysKit/README.md)

**Next** and **Prev** buttons in game, plus `/lnc`, log you out and straight into the neighbouring character on the account. It brings its own login screen, which picks the character, and which is a better login screen in its own right.

Without the login screen installed, Next and Prev only log you out, and you pick the character yourself. In the hub, LogNextChar gets a row (`/ck`): **Settings** opens the options below, and **Turn off** switches it off.

<!-- requirements: tools/curseforge_pages.py writes this -->

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

<!-- end of requirements -->

## Updated in 1.3.2

The character screen shows each character's Arcane Transmutor charges under its gold, as `Charges: #`. A character saved before currencies were recorded shows no line until it logs in and out again.

## Updated in 1.3.1

The character screen finds a character's gold by server and name, so characters with the same name on different servers no longer show each other's gold. Gold saved before servers were recorded shows a `?` until that character logs in and out again.

## Updated in 1.3.0

Cherry's Loginxml is now part of this addon: one folder, one zip and one row in the hub. Run `Install login screen.bat` once after updating. It moves the old folders to `Interface\offloaded_addons`, and your saved logins and toggles stay.

## Updated in 1.2.2

It now lives under `Interface\AddOns\CherrysKit`, and runs without Cherry's Loginxml: Next and Prev then only log you out.

## Updated in 1.2.1

Next, Prev and the other switches now close the mailbox and Ultimate Mail Mod's window first, so the mailbox still opens on the next character.

## Install

1. Remove any other login addon first. Only one can replace the login screen.
2. Extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\CherrysKit\LogNextChar\LogNextChar.lua`. If you have an older `Interface\AddOns\LogNextChar` folder, delete it.
3. Close the game and double-click `Interface\AddOns\CherrysKit\LogNextChar\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, and a package can only fill `Interface\AddOns`, so this copies it across. If you already have a `loginxml`, a copy of it goes to `Interface\offloaded_addons` first, and only the files that differ change. It leaves nothing running.
4. Start the game. The login screen shows `(LogNextChar 1.3.2)` next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings. If you forget, the addon tells you in chat.

## The buttons

Next sits on top and Prev under it, the same way round as the character list, just below the minimap. They follow the minimap at any UI scale or resolution. Hover a button to see which character it will log in. Both grey out when the account has only one character on that server.

The buttons are locked until you unlock them: open **Settings** in the hub or type `/lnc settings`, choose **Unlock login next char buttons**, then right-drag (or Shift+drag) them. The same window can hide them or put them back in their default spot.

## Commands

| Command | |
| --- | --- |
| `/lnc` or `/lnc next` | Next character |
| `/lpc` or `/lnc prev` | Previous character |
| `/lnc current` | Log out and back in to the same character |
| `/lnc 3` | The character in slot 3, in the order the characters were created |
| `/lnc settings` | Open the settings |
| `/lnc show`, `/lnc hide` | Show or hide the buttons |
| `/lnc lock`, `/lnc unlock` | Stop or allow moving them |
| `/lnc reset` | Put them back in their default spot |
| `/lnc probe` | Show positions and state, for a bug report |

Clicking a character, or using the arrow keys, on the character select screen cancels a pending switch. If a switch can't finish within 15 seconds, it gives up and leaves the choice to you.

For macros, `ChangeChar(slot)` does the same as `/lnc <slot>`.

## The login screen

A replacement login screen for Runes of Magic. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

- Gets past a stuck "obtaining server list", including for Steam and Gameforge launcher logins, which retry on their own.
- Saved logins and account or character lists with notes for NoCheckVersion accounts.
- Fills in the secondary password.
- Cleaner server and character select, usable from the keyboard.
- Settings as toggle buttons on the server screen.
- Joins your preferred channel.

## Settings

The on/off settings are toggle buttons to the right of the server list on the server screen. A click applies at once, and the game saves it when you log out or quit. **Use config.lua** forgets the saved toggles and goes back to the file.

| Toggle | Setting | Shipped | What it does |
| --- | --- | --- | --- |
| Log in if only one character | `character_login_single` | on | Logs straight in when the server has only one character |
| Log in the first character | `character_login_first` | off | Logs in the first character in the list, once after each account login |
| Ctrl stops at character select | `character_nologin_ctrl` | on | Hold Ctrl while logging in to stop at character select anyway |
| One click logs in a character | `character_single_click` | off | Otherwise a double-click |
| Sort characters by level | `character_sort` | off | Otherwise in creation order |
| One click joins a server | `server_single_click` | off | Otherwise a double-click |
| Retry the server list | `server_list_retry` | on (10) | Launcher logins: seconds before asking for the server list again, 0 = only by hand |
| One click logs in an account | `account_single_click` | off | Otherwise a double-click |
| Show empty account lists | `account_force_show` | off | |
| Account page slider | `account_use_slider` | on | Slider to switch between pages of lists |
| Account page list | `account_use_list` | on | List to switch between pages of lists |
| Show the account name | `show_account_info` | on | In the top right corner |
| DEBUG button and log | `debug` | off | |

These have no toggle and are set in `config.lua`:

| Setting | Shipped | What it does |
| --- | --- | --- |
| `channel` | 1 | Channel selected on character select |
| `server_list_retry_max` | 3 | Automatic retries before it's left to the Retry button |
| `account_columns` | 5 | Columns of account lists per page |
| `account_page` | 1 | Page shown first |

## Your accounts, passwords and config.lua

The files in `Interface\loginxml\data` are blank templates. Copy the ones you need up one level, into `Interface\loginxml\`, and edit those copies:

| File | What it holds |
| --- | --- |
| `accounts.lua` | NoCheckVersion accounts, their passwords and the account or character lists on the login screen |
| `password.lua` | Secondary passwords, also used for Steam and Gameforge launcher logins |
| `config.lua` | The settings above |

Loginxml reads `Interface\loginxml\` before `data\`, and installing an update never touches your copies. **They hold passwords: never share them, and never send them with a bug report.** The list format is described in [Rom-Autologin-Readme.md](../../loginxml/docs/Rom-Autologin-Readme.md).

## Controls

| Where | Control |
| --- | --- |
| Account | Enter logs in, Tab switches fields, click or double-click an entry in a list |
| Server list | Up / Down to choose, Enter to join, Esc to go back |
| Character select | Up / Down to choose, Enter to log in, Esc back to the server list, drag to turn the character |
| Launcher login | The Retry button counts down and asks for the server list again by itself. Click it to retry at once. |

For addons and macros, `CHARACTER_SELECT.selectedIndex` holds the slot of the character you're playing, as on the default login screen.

## Credits and licence

Next and Prev buttons by Cherry, MIT licence, see `LICENSE.txt`. Login screen: original project Rom Autologin by Pyrrhus, MIT licence, integration fixes by Cherry, see `LICENSE-Loginxml.txt`.
