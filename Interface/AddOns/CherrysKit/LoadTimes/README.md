# Cherry's Addon LoadTimes

Version **1.2.1** · Kit release **0.11.80** · [All addons / hub](../README.md)

**Find out which addons make your loading screen slow.**

A small report of how long each addon took while the loading screen was up, and how much memory it added.

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

- `/ckload` (also `/loadtimes`): show the report (type it after the loading screen)
- `/ckload probe`: what this client allows (send it with bug reports)

## Install

Requires the [Cherry's Kit hub](../README.md). Download ZIPs from [Releases](https://github.com/Cherrybooze/Cherrys-Kit/releases).

1. Install the full kit, or install the hub ZIP and this addon's ZIP.
2. Extract into your game's `Interface/AddOns/` folder, merging the `CherrysKit` folders. This addon must end up at `Interface/AddOns/CherrysKit/LoadTimes/`.
3. Remove any old separate copy from `Interface/AddOns/`, as described below.
4. Start the game or Reload UI. Open `/ck` to find this addon, then use `/ckload` for its own controls.

### Addon-specific notes

- **Delete the old `Interface\AddOns\!CherrysLoadTimes` folder** if you have it from an older kit.

LoadTimes is already included in the current hub ZIP: its hooks are needed by the shared loader. The separate LoadTimes ZIP updates those same files; it is not needed on top of the matching hub or full kit.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/ckload probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: [LICENSE.txt](LICENSE.txt) (the complete kit notices, also installed with the hub). Free, never to be sold.

## Support and contributions

This is a personal hobby project. Support and PR reviews are best effort, with no promised response time or release schedule. Feel free to modify it for your own setup. If you fix something that was broken, a focused pull request is welcome; ideally DM **cherry** on the Runes of Magic Discord about it too. Include what changed and what you tested in game. See the [contribution guide](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/CONTRIBUTING.md).
