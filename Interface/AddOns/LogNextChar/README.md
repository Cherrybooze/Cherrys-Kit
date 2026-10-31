# LogNextChar

**Next** and **Prev** buttons in game, plus `/lnc`, log you out and straight into the neighbouring character on the account.

Cherry's Loginxml picks the character on the login screen; without it you are only logged out, and you pick the character yourself. In the hub, LogNextChar gets a row (`/ck`): **Settings** opens the options below, and **Turn off** switches it off.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit (hub 0.4.25 or later). The CurseForge app installs it for you; if you install by hand, install it first.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LogNextChar`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **Cherry's Loginxml:** picks the next or previous character on the login screen; without it Next and Prev only log you out, and you pick the character yourself
> - **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\LogNextChar` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

<!-- end of requirements -->

## Updated in 1.2.2

It now lives under `Interface\AddOns\CherrysKit`, and runs without Cherry's Loginxml: Next and Prev then only log you out.

## Updated in 1.2.1

Next, Prev and the other switches now close the mailbox and Ultimate Mail Mod's window first, so the mailbox still opens on the next character.

## Install

Extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\CherrysKit\LogNextChar\LogNextChar.lua`. If you have an older `Interface\AddOns\LogNextChar` folder, delete it.

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

## Credits and licence

By Cherry. Cherry's Loginxml has its own credits. MIT licence, see `LICENSE.txt`.
