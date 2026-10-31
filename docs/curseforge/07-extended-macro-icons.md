# Extended Macro Icons

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\ExtendedMacroIcons`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:
> - **rom weakauras:** rom weakauras' icon picker uses its categories
>
> **Original addon:** ExtendedMacroIcons 2.15 by Amurilon. If `Interface\AddOns\ExtendedMacroIcons` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.

**The game's macro window with about 10,500 more icons for your macros, in 58 categories.**

Based on ExtendedMacroIcons 2.15 by Amurilon, cleaned up for Cherry's Kit.

## Updated in 3.0.4

Macro icon lookups are cached between macro changes, and turning the addon off in the kit removes its hooks from the last session.

## Features

- **About 10,500 extra icons**: class skills, equipment, weapons, items, festival, furniture and more, in 58 categories.
- **Pick an icon**: edit a macro and click its icon. Switch category with the < > arrows or by clicking the category name (right-click or mouse wheel goes back). Hold Shift over an icon to see its file path.
- **Item** button puts the link of the item in your first backpack slot into the macro text; **Name** puts a player link.
- The picker opens scrolled to the macro's current icon, and scrolling stops at the last row.
- **Your existing macros keep their icons**: the icon numbers are the same as in 2.15.
- **No extra libraries**: Sol, LibStub and the old debug.lua are gone. (debug.lua replaced the global `print` and added `/print`, `/out`, `/eval` and `/e` for every addon; those commands are gone.) The awsmDropdown addon is no longer needed.
- Doesn't change the game's icon count, so other addons (like Cherry's KittyCombo's Create macro) see the real one.
- Icon lists load on first use, for a faster loading screen. Safe with Reload UI.

## Chat commands

- `/emi`: open or close the macro window (the game's own macro button and key open it too)
- `/emi probe`: what your client supports (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\ExtendedMacroIcons\`.
- **Delete the old `Interface\AddOns\ExtendedMacroIcons` folder** (version 2.15). While it is there, this version stays off.
- Turned off in `/ck`, macros with extra icons show the default icon until you turn it on again.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/emi probe` if you can.

## Credits and licence

- Based on **ExtendedMacroIcons 2.15, (C) 2018 Amurilon**. The original has no licence statement, so its copyright stays with Amurilon and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- The icon lists name pictures that belong to the Runes of Magic game client; none are shipped, except one button texture from the original addon.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
