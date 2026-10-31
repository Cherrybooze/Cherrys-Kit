# PortraitHP

Version **2019.07.14-ck2** · Kit release **0.11.78** · [All addons / hub](../README.md)

**Your target's health in percent, right on its portrait.**

PortraitHP v2019.07.14 by Nonante@Nuada, fixed for Cherry's Kit.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit. The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\PortraitHP`. The hub loads it from there, and it won't load from anywhere else.
>
> **On its own:** it runs with just the hub, and nothing it does needs another addon.
>
> **Original addon:** PortraitHP v2019.07.14 by Nonante@Nuada. If `Interface\AddOns\PortraitHP` is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.
>
> **Other addons:** AddonManager lists it when you have that addon.

<!-- end of requirements -->

## Features

- Shows the target's health percent on the target portrait, and nothing when you have no target.
- Fixed for today's client: the original's event handler never ran in RoM, and it cleared your target when the UI loaded. Both are fixed.
- No error on units without a maximum health. On/off is saved. Safe with Reload UI.
- The portrait text, font and placement are declared in XML and reused after Reload UI; target events wait until initialization is complete.

## Chat commands

- `/php`: turn it on or off
- `/php probe`: what it sees (send it with bug reports)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/PortraitHP/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/php` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\PortraitHP` folder** if you have one. While it is there, Cherry's Kit keeps this version turned off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/php probe` if you can. It includes initialization state and the last event error. If a native client call supplies no error text, PortraitHP reports the event and operation in chat; include that line too. A missing `PortraitHP_Text` message means the addon XML needs reinstalling before Reload UI.

## Credits and licence

- Based on **PortraitHP v2019.07.14 by Nonante@Nuada**. The original has no licence statement, so its copyright stays with its author and those parts are not covered by the GPL. Cherry's changes are offered under the **GNU GPL v2**.
- Full licence texts: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
