[![Download the full kit install ZIP. Extract into Interface/AddOns.](docs/images/download-full-kit.svg)](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.80/CherrysKit-Full-0.11.80.zip)

# Cherry's Kit

> Development snapshot: kit 0.11.80 is not published yet. Visit Releases for the current public build.

## [Download the full kit — install ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.80/CherrysKit-Full-0.11.80.zip)

**Extract this ZIP straight into your game's `Interface/AddOns/` folder.** It creates `Interface/AddOns/CherrysKit/CherrysKit.toc`. Start the game or Reload UI, then type `/ck`.

> **Installing the addon? Use the download above.** GitHub's green **Code → Download ZIP** button and **Source code (zip)** links download the repository, with an extra `Cherrys-Kit-main` or version folder. Those downloads are for working on the source.

**Runes of Magic addons that work together, with one small control hub.**

Current kit release: **0.11.80** · [Release notes and all downloads](https://github.com/Cherrybooze/Cherrys-Kit/releases/tag/v0.11.80)

Cherry's Kit combines original addons, rewrites and fixes to older favourites into a single collection. Pick the full kit, or install the hub and the addons you want. The hub opens their settings, turns them on or off after Reload UI, and gives them one place on your minimap.

## What’s new in 0.11.80

- KittyCombo fires skills only when they are nearly ready (0.2 s instead of 0.6 s), and its action rows skip presses when the slot is gone or unusable, or when an item stack is empty.
- Reported issues are fixed across the kit: auction bid/sell clicks after scrolling and the stat filters, rom weakauras copies and class checks, chat selection painting, bank refreshes and sorting, buff tooltip chat spam, the daily reward mark, and more.
- Everything else carries over from 0.11.79.

Some features still need confirmation in the game client; see the release notes and individual addon guides for details.

## Why this project exists

Runes of Magic has plenty of useful addons, but many were made years ago and have different interfaces, overlapping features or rough edges on the current client. This project brings the addons I use into one place, fixes problems I run into, and connects them where it helps: raid-frame clicks can run a KittyCombo rotation, and rom weakauras can display what that rotation will do next.

It is a personal hobby project, shared so other players can use it, learn from it and improve it. It is not a promise to maintain every old addon or support every client and server setup.

## Download and install

**[Download the full-kit install ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.80/CherrysKit-Full-0.11.80.zip)** · [Hub and individual addon downloads](https://github.com/Cherrybooze/Cherrys-Kit/releases/latest)

- **Full kit:** the install ZIP above includes the hub and every addon.
- **Choose your addons:** download the Hub ZIP and whichever addon ZIPs you want from the release assets.

Extract the selected ZIPs into your game's **`Interface/AddOns/`** folder. They all contain a top-level `CherrysKit/` folder: merge those folders, keeping `CherrysKit.toc` directly inside `CherrysKit/`. Start the game or Reload UI, then type **`/ck`** (or **`/rwa`**).

The resulting layout should be:

```text
Interface/
  AddOns/
    CherrysKit/
      CherrysKit.toc
      CherrysKit.lua
      KittyCombo/
      RomWeakAuras/
      ...
```

If you already downloaded `Cherrys-Kit-main.zip`, use the install ZIP linked above instead. If Windows offers an extraction folder named after the ZIP, change that destination to your existing `Interface/AddOns/` folder.

Remove old separate copies of the same addons from `Interface/AddOns/` first; the hub keeps its copy idle if another copy is detected. Your saved settings live outside the addon folders. The [hub README](Interface/AddOns/CherrysKit/README.md) explains this in more detail.

The current hub includes **Addon LoadTimes**, because the shared loader uses its hooks. The separate LoadTimes ZIP updates those same files. The other individual addon ZIPs require the hub.

## What's included

| Addon | What it does | Command | Version |
| --- | --- | --- | --- |
| [Cherry's Kit hub](Interface/AddOns/CherrysKit/README.md) | Shared settings launcher, on/off switches and minimap button. | `/ck`,`/rwa` | 0.4.15 |
| [Cherry's KittyCombo](Interface/AddOns/CherrysKit/KittyCombo/README.md) | One-key priority combos and shared rotation codes. | `/kc` | 1.7.10 |
| [rom weakauras](Interface/AddOns/CherrysKit/RomWeakAuras/README.md) | Custom buff, debuff, cooldown, cast and status displays. | `/wa` | 0.9.23 |
| [Cherry's Chat](Interface/AddOns/CherrysKit/CherrysChat/README.md) | Selectable chat, copying, emoji and chat display settings. | `/cchat` | 0.10.8 |
| [zBag](Interface/AddOns/CherrysKit/zBag/README.md) | Bags, searching, sorting, quick sell and an All bags view. | `/zb` | 5.07-ck12 |
| [Global Bank](Interface/AddOns/CherrysKit/GlobalBank/README.md) | A searchable view of your characters' bags, banks and gold. | `/gb` | 1.4.6 |
| [Extended Macro Icons](Interface/AddOns/CherrysKit/ExtendedMacroIcons/README.md) | A larger, categorised macro icon picker. | `/emi` | 3.0.4 |
| [TooltipIds](Interface/AddOns/CherrysKit/TooltipIds/README.md) | ID numbers for items, buffs, skills and other game data. | `/ti` | 1.0b3-ck3 |
| [Ultimate Mail Mod](Interface/AddOns/CherrysKit/UltimateMailMod/README.md) | Mail management and mass sending. | `/umm` | 7.0.1-ck5 |
| [Advanced AuctionHouse](Interface/AddOns/CherrysKit/AdvancedAuctionHouse/README.md) | Auction searching, stat filters, history and a resizable window. | `/aah` | 6.2.3 |
| [Cherry's Addon LoadTimes](Interface/AddOns/CherrysKit/LoadTimes/README.md) | Loading times and memory use for the kit and other addons. | `/ckload` | 1.2.1 |
| [ZShop](Interface/AddOns/CherrysKit/ZShop/README.md) | Item-shop access and a daily loyalty reward shortcut. | `/zshop` | 1.2.0-ck3 |
| [pbInfo](Interface/AddOns/CherrysKit/pbInfo/README.md) | Richer tooltips, quest tracking, chat filters and cast-bar options. | `/pbinfo` | 0.60-ck3 |
| [PortraitHP](Interface/AddOns/CherrysKit/PortraitHP/README.md) | Your target's health percentage on its portrait. | `/php` | 2019.07.14-ck2 |
| [Cherry's Grid](Interface/AddOns/CherrysKit/CherrysGrid/README.md) | Party and raid frames, with KittyCombo actions on click. | `/grid` | 1.1.2 |

Some integrations need both addons: for example, running a kitty from Grid needs KittyCombo. Each addon's README lists its requirements and current limits. Features still being tested are labelled there.

## Optional Chrome extension

[Download Global Bank Daily Rewards for Chrome 1.0.8](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.80/CherrysKit-GlobalBankDailyRewards-1.0.8.zip) — an optional, separate Windows package for Chrome. It collects available rewards on the Gameforge daily shop page, records confirmed collections locally, and provides local character and auction-cache search. It requires Global Bank and its helper.

Extract the extension ZIP into `Interface/AddOns/`, run **Install Chrome extension.bat** from `CherrysKit/GlobalBank/Helper/`, and follow the [step-by-step setup guide](extras/GlobalBankDailyRewards/README.md). Chrome requires a one-time **Load unpacked** step. Automatic page processing is limited to the Gameforge daily shop page; the extension does not send your local data to the developer.

## Support and pull requests

Support and PR reviews are **best effort**. This is a small personal project; there is no promised response time, release schedule, or guarantee that every request will be taken on.

**Feel free to tweak it for your own setup.** If you think you fixed something that was broken, open a pull request. Keep it focused, explain what was wrong and what changed, and include what you tested in game. **Ideally DM me, cherry, on the Runes of Magic Discord about it too**, I may not notice a GitHub notification quickly.

Bug reports are welcome as well: say which addon and kit version you use, what you expected, what happened, and how to reproduce it. Add relevant probe output or screenshots when useful; the addon README gives the exact command. See [CONTRIBUTING.md](CONTRIBUTING.md) for a short guide.

## Inside this repository

- [`Interface/AddOns/CherrysKit/`](Interface/AddOns/CherrysKit/) holds the installed addon tree, with a README in the hub and every addon folder.
- [`docs/curseforge/`](docs/curseforge/README.md) contains the copy-and-paste CurseForge descriptions and publishing notes.
- [`docs/RELEASING.md`](docs/RELEASING.md) explains packaging, installation layouts and publishing a version.
- [`release-packages.json`](release-packages.json) records the package names and versions.
- [`tools/build_release.py`](tools/build_release.py) creates the ZIPs, validates their contents and writes SHA-256 checksums.

All addon source lives on **`main`**. Use short-lived branches for changes and tags for releases. Generated ZIPs live in Releases rather than Git history.

## Development and checks

Python 3.10 or later is enough; there are no Python package dependencies:

```sh
python tools/build_release.py
```

This creates seventeen ZIPs in `dist/<kit version>/` (the full kit, hub, fourteen addons and the optional Chrome extension), plus a release manifest, checksums and release notes. The same check runs on pushes and pull requests. It verifies the packaged source, file references, archive structure and local documentation links.

The original 0.11.77 import preserved the supplied runtime code. Earlier READMEs referring to old tests or generators are kept as reference notes, but those development tools were not included in the handoff. Current tests simulate client APIs; native drawing, input, sound and event timing still need in-game checks.

The current fixes also have Lua 5.1 regression coverage: install `tests/requirements.txt`, then run `python -m unittest discover -s tests -p 'test_*.py' -v`. The [in-game check list](docs/TESTING.md) describes the remaining native-client checks.

## Credits and licences

This collection includes work by several addon authors and bundles several different licences. Keep the individual credits, notices and media licences with anything you redistribute. [LICENSE.txt](LICENSE.txt) preserves the original combined notice file; the package READMEs explain the relevant origins, and each addon ZIP includes a copy.

The original [0.11.77 bundle README](docs/reference/CherrysKit_README-0.11.77.txt) is retained for reference.
