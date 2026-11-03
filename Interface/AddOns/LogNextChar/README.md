# LogNextChar

Version **1.4.0** · Kit release **0.11.117** · [All addons / hub](../CherrysKit/README.md)

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

## Updated in 1.4.0

The character screen numbers your characters from 1, and Next and Prev show the number they log into, big under their name in cyan: playing number 4, Next shows 5 and Prev shows 3. They take the numbers from the login screen's character list, so without the login screen, or with one character, the buttons only show their names.

**Edit character order**, a new toggle with the character settings, puts an up and a down arrow on each row of the character screen. Click one, or hold Shift and press Up or Down, to move a character, and the numbers follow. Next, Prev and `/lnc <number>` go by your order. It is kept for each server and saved with the toggles; untick the toggle when you're done and the order stays. Characters on another account on the same server keep their own places. With Modern look off, the numbers only show while you edit.

On the server screen, the settings now sit at the left edge with the server list beside them, tops level, and **Settings**, **Back** and **Exit Game** sit at the bottom left, under the settings. The top right corner says `Loginxml 1.4.0` under the client version when the game has no account name to show there: a Gameforge launcher login only gives it `TNTLogin`.

The login screen has a new look, in the style of rom weakauras and Cherry's Bar: flat dark panels with a thin border, cyan for what you have selected, and gold for the main button. Gold on the character screen is gold, beside a coin, with the charges and the last save under it. The character, channel and server lists are as long as what is in them, the server rows show the flag and how many characters you have there beside a helmet, and the settings panel groups its toggles under headings, with new check boxes. Buttons, edit boxes and the sliders on the character creation screen match.

**Modern look**, the first toggle in the settings panel on the server screen, switches back to the game's own look at once, and the game remembers it like the other toggles. `modern_ui = false` in `config.lua` does the same. Run `Install login screen.bat` again after updating.

## Updated in 1.3.4

`Install login screen.bat` asks Windows for administrator rights and installs the login screen in that window, so a game folder such as `C:\RunesOfMagic` can't refuse to replace its files. Say No and it carries on without them. It reads your own Documents folder even when the administrator is another Windows user.

## Updated in 1.3.3

Next and Prev land on the right character more reliably. The login screen waits until the game has sent the whole character list before it picks one, starts from the character you left by name, and holds the pick until the login starts, so the game selecting its last played character a moment later can't stop it. A logout you cancel, or that the game stops, also drops the queued switch, so a later logout by hand stays an ordinary one. Run `Install login screen.bat` again after updating.

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
4. Start the game. The login screen shows `(LogNextChar 1.4.0)` next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings. If you forget, the addon tells you in chat.

## The buttons

Next sits on top and Prev under it, the same way round as the character list, just below the minimap. They follow the minimap at any UI scale or resolution. Each shows the number of the character it will log in, as the character screen numbers them, big under its name, and hovering it names that character. Both grey out when the account has only one character on that server.

The buttons are locked until you unlock them: open **Settings** in the hub or type `/lnc settings`, choose **Unlock login next char buttons**, then right-drag (or Shift+drag) them. The same window can hide them or put them back in their default spot.

## Commands

| Command | |
| --- | --- |
| `/lnc` or `/lnc next` | Next character |
| `/lpc` or `/lnc prev` | Previous character |
| `/lnc current` | Log out and back in to the same character |
| `/lnc 3` | The character with number 3 on the character screen |
| `/lnc settings` | Open the settings |
| `/lnc show`, `/lnc hide` | Show or hide the buttons |
| `/lnc lock`, `/lnc unlock` | Stop or allow moving them |
| `/lnc reset` | Put them back in their default spot |
| `/lnc probe` | Show positions and state, for a bug report |

Clicking a character, or using the arrow keys, on the character select screen cancels a pending switch. If a switch can't finish within 15 seconds, it gives up and leaves the choice to you.

For macros, `ChangeChar(slot)` logs in the character in that slot, in the order the characters were created, whatever their numbers.

## The login screen

A replacement login screen for Runes of Magic. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

- Gets past a stuck "obtaining server list", including for Steam and Gameforge launcher logins, which retry on their own.
- Saved logins and account or character lists with notes for NoCheckVersion accounts.
- Fills in the secondary password.
- Cleaner server and character select, usable from the keyboard.
- Settings as toggle buttons on the server screen.
- Joins your preferred channel.

## Settings

The on/off settings are toggle buttons on the server screen, at its left edge (to the right of the server list with Modern look off). A click applies at once, and the game saves it when you log out or quit. **Use config.lua** forgets the saved toggles and goes back to the file.

| Toggle | Setting | Shipped | What it does |
| --- | --- | --- | --- |
| Log in if only one character | `character_login_single` | on | Logs straight in when the server has only one character |
| Log in the first character | `character_login_first` | off | Logs in the first character in the list, once after each account login |
| Ctrl stops at character select | `character_nologin_ctrl` | on | Hold Ctrl while logging in to stop at character select anyway |
| One click logs in a character | `character_single_click` | off | Otherwise a double-click |
| Sort characters by level | `character_sort` | off | Otherwise in number order |
| Edit character order | `character_order_edit` | off | Up and down arrows on the character screen that change the characters' numbers |
| One click joins a server | `server_single_click` | off | Otherwise a double-click |
| Retry the server list | `server_list_retry` | on (10) | Launcher logins: seconds before asking for the server list again, 0 = only by hand |
| One click logs in an account | `account_single_click` | off | Otherwise a double-click |
| Show empty account lists | `account_force_show` | off | |
| Account page slider | `account_use_slider` | on | Slider to switch between pages of lists |
| Account page list | `account_use_list` | on | List to switch between pages of lists |
| Show the account name | `show_account_info` | on | In the top right corner, or `Loginxml` and its version when the game has none (launcher logins) |
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
| Character select | Up / Down to choose, Enter to log in, Esc back to the server list, drag to turn the character. With **Edit character order** on, Shift+Up / Down moves the selected character |
| Launcher login | The Retry button counts down and asks for the server list again by itself. Click it to retry at once. |

For addons and macros, `CHARACTER_SELECT.selectedIndex` holds the slot of the character you're playing, as on the default login screen.

## Credits and licence

Next and Prev buttons by Cherry, MIT licence, see `LICENSE.txt`. Login screen: original project Rom Autologin by Pyrrhus, MIT licence, integration fixes by Cherry, see `LICENSE-Loginxml.txt`.
