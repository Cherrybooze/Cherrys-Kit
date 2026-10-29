# Cherry's Addon LoadTimes

**Find out which addons make your loading screen slow.**

A small report of how long each addon took while the loading screen was up, and how much memory it added.

## Updated in 1.2.1

Both probe frames stop after the loading screen is gone, so a tiny hidden frame no longer keeps processing every frame.

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

- **Requires Cherry's Kit** (installed automatically by CurseForge). This addon goes in `Interface\AddOns\CherrysKit\LoadTimes\` and loads first in the kit.
- **Delete the old `Interface\AddOns\!CherrysLoadTimes` folder** if you have it from an older kit.

## Bug reports

Write to **cherry** on the Runes of Magic Discord. Add the output of `/ckload probe` if you can.

## Credits and licence

- Written by Cherry for Cherry's Kit, under the **GNU GPL v2**.
- Full licence text: `Interface\AddOns\CherrysKit\LICENSE.txt` (installed with Cherry's Kit). Free, never to be sold.
