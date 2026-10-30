# LogNextChar

> **Requires:** Cherry's Kit and Cherry's Loginxml. The CurseForge app installs them for you; if you install by hand, install them first.
>
> **Optional:** nothing else is needed.

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

Install this addon, or extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\LogNextChar\LogNextChar.toc`.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/lnc probe` if you can.

## Credits and licence

- Original project by **Pyrrhus**, MIT licence. Integration fixes by **Cherry**.
- Full licence text: `Interface\AddOns\LogNextChar\LICENSE.txt`.
