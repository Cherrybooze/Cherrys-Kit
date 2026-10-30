# LogNextChar

**Next** and **Prev** buttons in game, plus `/lnc`, log you out and straight into the neighbouring character on the account.

**Requires Cherry's Kit and Cherry's Loginxml.** Cherry's Loginxml picks the character on the login screen; without it you are only logged out. In the hub, LogNextChar gets a row (`/ck`): **Settings** opens the options below, and **Turn off** switches it off.

## Install

Extract the zip into `Interface\AddOns`. You should end up with `Interface\AddOns\LogNextChar\LogNextChar.toc`.

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

Works with Cherry's Loginxml, whose original project is Rom Autologin by Pyrrhus. Integration fixes by Cherry. MIT licence, see `LICENSE.txt`.
