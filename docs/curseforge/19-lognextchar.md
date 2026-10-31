# LogNextChar

> **Requires:** Cherry's Kit (hub 0.4.25 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LogNextChar`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Cherry's Loginxml:** picks the next or previous character on the login screen; without it Next and Prev only log you out, and you pick the character yourself
> - **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\LogNextChar` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

**Next and Prev buttons in game: log out and straight into the neighbouring character on your account.**

Made for alts. One click, and you are on the next character without touching the login screen.

## Features

- **Next and Prev buttons** just below the minimap, Next on top and Prev under it, the same way round as the character list. They follow the minimap at any UI scale or resolution.
- **Hover to see who is next.** The tooltip names the character each button will pick.
- **Greyed out when there is nobody to switch to**, on accounts with one character.
- **Move them if you like**: unlock them in the settings window, then right-drag or Shift+drag.
- **A row in the Cherry's Kit hub** (`/ck`), whose Settings button opens the settings window.

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

## Install

Install this addon, or extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\CherrysKit\LogNextChar\LogNextChar.lua`.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/lnc probe` if you can.

## Credits and licence

- By **Cherry**, MIT licence.
- Full licence text: `Interface\AddOns\CherrysKit\LogNextChar\LICENSE.txt`.
