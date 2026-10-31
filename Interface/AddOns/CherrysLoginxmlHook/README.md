# Cherry's Loginxml

A replacement login screen for Runes of Magic. Original project: Rom Autologin by Pyrrhus. Integration fixes by Cherry.

**Requires:** Cherry's Kit, the hub. **Optional:** LogNextChar, which adds Next and Prev buttons in game and needs this login screen to pick the character.

- Gets past a stuck "obtaining server list", including for Steam and Gameforge launcher logins, which retry on their own.
- Saved logins and account or character lists with notes for NoCheckVersion accounts.
- Fills in the secondary password.
- Cleaner server and character select, usable from the keyboard.
- Settings as toggle buttons on the server screen.
- Joins your preferred channel.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit (hub 0.4.25 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\CherrysLoginxmlHook`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **LogNextChar:** Next and Prev character buttons in game
> - **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\CherrysLoginxml` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one. Install login screen.bat removes that folder for you. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer replaces whatever is there and keeps your saved logins.
>
> **After installing:** close the game and double-click `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, so this copies it there.

<!-- end of requirements -->

## Install

1. Remove any other login addon first. Only one can replace the login screen.
2. Extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\CherrysLoginxml.toc`.
3. Close the game and double-click `Interface\AddOns\CherrysKit\CherrysLoginxmlHook\Install login screen.bat`. The game only reads a login screen from `Interface\loginxml`, and a package can only fill `Interface\AddOns`, so this copies it across. It also lets your settings toggles come back after a restart. It leaves nothing running.
4. Start the game. The login screen shows `(Cherry's Loginxml 1.2.2)` next to the client version in the top right corner.

Run the same file again after updating. It never touches your own accounts, passwords or settings. If you forget, the addon tells you in chat.

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

Original project: Rom Autologin by Pyrrhus, MIT licence. Integration fixes by Cherry. See [LICENSE.txt](LICENSE.txt).
