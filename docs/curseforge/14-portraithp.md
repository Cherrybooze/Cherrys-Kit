# PortraitHP

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\PortraitHP`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub, and nothing it does needs another addon.
>
> **Original addon:** PortraitHP v2019.07.14 by Nonante@Nuada. If `Interface\AddOns\PortraitHP` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon.

**Your target's health in percent, right on its portrait.**

PortraitHP v2019.07.14 by Nonante@Nuada, fixed for Cherry's Kit.

## Features

- Shows the target's health percent on the target portrait, and nothing when you have no target.
- Fixed for today's client: the original's event handler never ran in RoM, and it cleared your target when the UI loaded. Both are fixed.
- No error on units without a maximum health. On/off is saved. Safe with Reload UI.

## Chat commands

- `/php`: turn it on or off
- `/php probe`: what it sees (send it with bug reports)

## Install

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\PortraitHP\`.
- **Delete the old `Interface\AddOns\PortraitHP` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.
- Turn it on or off in the Cherry's Kit window (`/ck`).

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/php probe` if you can.

## Credits and licence

- Based on **PortraitHP v2019.07.14 by Nonante@Nuada**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- Full licence texts: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
