[![Download the full kit install ZIP. Extract into Interface/AddOns.](docs/images/download-full-kit.svg)](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.83/CherrysKit-Full-0.11.83.zip)

# Cherry's Kit

> Playtest build: kit **0.11.83**. Native-client checks are listed in [TESTING.md](docs/TESTING.md). The [latest stable build](https://github.com/Cherrybooze/Cherrys-Kit/releases/latest) is available separately.

## [Download the full kit — install ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.83/CherrysKit-Full-0.11.83.zip)

**Extract this ZIP straight into your game's `Interface/AddOns/` folder.** It creates `Interface/AddOns/CherrysKit/CherrysKit.toc`. Start the game or Reload UI, then type `/ck`.

> **Installing the addon? Use the download above.** GitHub's green **Code → Download ZIP** button and **Source code (zip)** links download the repository, with an extra `Cherrys-Kit-main` or version folder. Those downloads are for working on the source.

**Runes of Magic addons that work together, with one small control hub.**

Current playtest build: **0.11.83** · [Release notes and all downloads](https://github.com/Cherrybooze/Cherrys-Kit/releases/tag/v0.11.83)

Cherry's Kit combines original addons, rewrites and fixes to older favourites into a single collection. Pick the full kit, or install the hub and the addons you want. The hub opens their settings, turns them on or off after Reload UI, and gives them one place on your minimap.

## What’s new in 0.11.83

- UMM adds **drag-box selection** across all six bags. Ctrl/Shift-drag adds, Escape/right-click cancels, and the original click/group controls remain available. Bound items keep their red marks and are excluded from sending.
- A right-side **Recently sent** pane fills the mass-send recipient without clearing committed selections. It shares the same 20-name history across characters. The wider mail window fits the viewport; sending/C.O.D. locks recipient changes and queue sending locks all four tabs.
- Kitty's mode picker rejects delayed clicks after closing or native hiding, preserving the live mode when an editor pick is cancelled.
- zBag keeps stack-split dialogs open through unrelated updates and validates their original source at confirmation. Slot numbers default to 8 points (about 40% smaller), with a **Font size** control in /zb.
- RWA tracks native transport and other non-spell player cast/progress events. AAH uses a private item-parser tooltip instead of the game's skill-upgrade tooltip. The reported TP-upgrade black flash still needs an in-game retest.

## Earlier 0.11.82 development features included

- RWA adds a default-on **Make clickthrough** checkbox for every aura. Normal gameplay passes clicks through and hides its hover tooltip; editing and placement views keep their interaction.
- **Position** now includes whole-aura **Scale**, a percentage field and quick −/+ adjustments. Linked displays inherit it once, and scaling preserves the chosen anchor. Section headers use **Expand / Collapse**.
- Optional **Auto scale position and size with screen size** starts off for every aura. Unlocked previews have a top-left move/Shift-scale grip and per-aura **Reset position**; factory positions use the approved layout while existing saved placements are preserved.
- Target health shows HP and percentage on a readable line: available HP directly, `~` for learned NPC estimates, and `?` for unknown HP.
- UMM adds default-on **Mail shortcuts**: **Use last** beside To and two editable gold buttons below Send Gold. The third main tab, **History**, lists the 20 most recent distinct successful recipients. All values are shared across characters; Mass Send Items is the fourth tab.
- Kitty's mode button and readout share a screen-aware icon picker: it opens top-down near the left edge when space allows, adapts to other corners/UI scales, and pages extra modes.
- The new main action **changemode** selects a mode icon and adds an editable **Mode is off** guard. Execution switches on that press; prediction simulates subsequent mode conditions privately.
- [Overhead emoji pictures need a client-side bubble hook](docs/CHAT_BUBBLES.md) absent from the inspected client. This candidate does not implement overhead rendering.
- The 0.11.81 fixes, 0.2-second dispatch, 0.6-second A/B toggle and 1.1-second lookahead carry forward. Unchanged addon packages retain their versions and package-release labels. Successful-cast throughput gains remain unmeasured.

Some features still need confirmation in the game client; see the release notes and individual addon guides for details.

## Why this project exists

Runes of Magic has plenty of useful addons, but many were made years ago and have different interfaces, overlapping features or rough edges on the current client. This project brings the addons I use into one place, fixes problems I run into, and connects them where it helps: raid-frame clicks can run a KittyCombo rotation, and rom weakauras can display what that rotation will do next.

It is a personal hobby project, shared so other players can use it, learn from it and improve it. It is not a promise to maintain every old addon or support every client and server setup.

## Download and install

**[Download the full-kit install ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.83/CherrysKit-Full-0.11.83.zip)** · [Hub and individual addon downloads](https://github.com/Cherrybooze/Cherrys-Kit/releases/latest)

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
| [Cherry's Kit hub](Interface/AddOns/CherrysKit/README.md) | Shared settings launcher, on/off switches and minimap button. | `/ck`,`/rwa` | 0.4.18 |
| [Cherry's KittyCombo](Interface/AddOns/CherrysKit/KittyCombo/README.md) | One-key priority combos and shared rotation codes. | `/kc` | 1.7.13 |
| [rom weakauras](Interface/AddOns/CherrysKit/RomWeakAuras/README.md) | Custom buff, debuff, cooldown, cast and status displays. | `/wa` | 0.9.26 |
| [Cherry's Chat](Interface/AddOns/CherrysKit/CherrysChat/README.md) | Selectable chat, copying, emoji and chat display settings. | `/cchat` | 0.10.9 |
| [zBag](Interface/AddOns/CherrysKit/zBag/README.md) | Bags, searching, sorting, quick sell and an All bags view. | `/zb` | 5.07-ck14 |
| [Global Bank](Interface/AddOns/CherrysKit/GlobalBank/README.md) | A searchable view of your characters' bags, banks and gold. | `/gb` | 1.4.6 |
| [Extended Macro Icons](Interface/AddOns/CherrysKit/ExtendedMacroIcons/README.md) | A larger, categorised macro icon picker. | `/emi` | 3.0.4 |
| [TooltipIds](Interface/AddOns/CherrysKit/TooltipIds/README.md) | ID numbers for items, buffs, skills and other game data. | `/ti` | 1.0b3-ck3 |
| [Ultimate Mail Mod](Interface/AddOns/CherrysKit/UltimateMailMod/README.md) | Mail management, drag-box selection, shared recipients, gold presets and mass sending. | `/umm` | 7.0.1-ck7 |
| [Advanced AuctionHouse](Interface/AddOns/CherrysKit/AdvancedAuctionHouse/README.md) | Auction searching, stat filters, history and a resizable window. | `/aah` | 6.2.4 |
| [Cherry's Addon LoadTimes](Interface/AddOns/CherrysKit/LoadTimes/README.md) | Loading times and memory use for the kit and other addons. | `/ckload` | 1.2.1 |
| [ZShop](Interface/AddOns/CherrysKit/ZShop/README.md) | Item-shop access and a daily loyalty reward shortcut. | `/zshop` | 1.2.0-ck4 |
| [pbInfo](Interface/AddOns/CherrysKit/pbInfo/README.md) | Richer tooltips, quest tracking, chat filters and cast-bar options. | `/pbinfo` | 0.60-ck4 |
| [PortraitHP](Interface/AddOns/CherrysKit/PortraitHP/README.md) | Your target's health percentage on its portrait. | `/php` | 2019.07.14-ck2 |
| [Cherry's Grid](Interface/AddOns/CherrysKit/CherrysGrid/README.md) | Party and raid frames, with KittyCombo actions on click. | `/grid` | 1.1.3 |

Some integrations need both addons: for example, running a kitty from Grid needs KittyCombo. Each addon's README lists its requirements and current limits. Features still being tested are labelled there.

## Optional Chrome extension

[Download Global Bank Daily Rewards for Chrome 1.0.8](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.83/CherrysKit-GlobalBankDailyRewards-1.0.8.zip) — an optional, separate Windows package for Chrome. It collects available rewards on the Gameforge daily shop page, records confirmed collections locally, and provides local character and auction-cache search. It requires Global Bank and its helper.

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
