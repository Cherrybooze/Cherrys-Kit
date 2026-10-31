# Cherry's Addon LoadTimes

Version **1.3.0** · Kit release **0.11.87** · [All addons / hub](../README.md)

**Find out which addons make your loading screen slow.**

A small report of how long each addon took while the loading screen was up, and how much memory it added. It is a troubleshooting tool, so it comes switched off and then uses no memory at all.

<!-- requirements: tools/curseforge_pages.py writes this -->

> **Requires:** Cherry's Kit (hub 0.4.22 or later). The CurseForge app installs it for you; if you install by hand, install it first. This addon can't load without the hub.
>
> **Where it goes:** `Interface\AddOns\CherrysKit\LoadTimes`. The hub loads it from there, and it won't load from anywhere else, which keeps it apart from any version you manage yourself.
>
> **On its own:** it runs with just the hub, and nothing it does needs another addon.
>
> **Older copy:** this addon has no original to give way to, but if `Interface\AddOns\!CherrysLoadTimes` from an earlier release is still there, it takes precedence: this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one.
>
> **Other addons:** It times every addon the game loads, kit or not, and needs none of them.

<!-- end of requirements -->

## Turning it on and off

Addons cannot change their own files, so the switch is a small text file you edit yourself:

1. Open `Interface\AddOns\CherrysKit\LoadTimes\Switch.txt` in Notepad.
2. Change `LoadTimes = false` to `LoadTimes = true` and save the file.
3. Restart the game (times measured after a Reload UI are not comparable), wait for the loading screen to finish and type `/ckload`.
4. Set it back to `false` when you are done.

While it is off, nothing of it loads except the switch check, and `/ckload` tells you how to turn it on.

## Updated in 1.3.0

Now a troubleshooting addon that stays off until `Switch.txt` turns it on, as described above. Switched off, the kit only reads that small file and keeps nothing of LoadTimes in memory. The hub no longer bundles it: it is its own optional download, and it needs hub 0.4.22 or later.

## Updated in 1.2.1

Both probe frames stop after the loading screen is gone, so a tiny hidden frame no longer keeps processing every frame for the rest of the session.

## Features

- **Per-addon times for Cherry's Kit addons**: exact load time and memory for every kit addon you have installed.
- **Other addons**: the time spent outside the kit as one total, plus the 10 slowest spots during loading, each named by the first thing the addon created after the wait (usually its name).
- Total loading time up to the end of the loading screen, and the time spent in the game's "variables loaded" step.
- Notices when you used Reload UI, since times after a reload are not comparable.
- Does nothing after loading; it only reports when you ask.

**Why not a time for every addon?** The Runes of Magic client names every addon file "?", so there is no way to tell which non-kit addon a piece of loading belongs to. The slow spots list is the best the game allows.

## Chat commands

- `/ckload` (also `/loadtimes`): show the report (type it after the loading screen). While it is switched off, it says how to turn it on.
- `/ckload probe`: what this client allows (send it with bug reports)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/LoadTimes/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Turn it on in `LoadTimes\Switch.txt` when you want to measure (see above), then start the game. Open `/ck` to find this addon, then use `/ckload` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\!CherrysLoadTimes` folder** if you have it from an older kit.

Since kit 0.11.87 the hub no longer includes LoadTimes: install its own ZIP (or the full kit) when you need it. The full kit installs it switched off.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/ckload probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
