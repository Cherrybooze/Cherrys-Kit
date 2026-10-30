# CurseForge descriptions

These descriptions started as an initial hand-off text and are maintained with the addon guides. The [original 0.11.77 text](https://github.com/Cherrybooze/Cherrys-Kit/tree/v0.11.77/docs/curseforge) remains in the first release. Use the matching numbered file when filling in a CurseForge project description.

[All descriptions and publishing notes](descriptions.md) · [Release and packaging guide](../RELEASING.md)

## Before publishing

- Set Cherry's Kit as a Required dependency on each addon project before claiming it is installed automatically.
- The hub no longer includes LoadTimes (since kit 0.11.87). LoadTimes is an ordinary addon project that requires hub 0.4.22 or later and comes switched off.
- Preserve the existing credits and licence notices, including the ZShop note in the handoff.
- Keep the existing notes about features still being tested. GitHub packaging checks do not prove behaviour in the game.

## Release plan

Every package is its own CurseForge project. Every ZIP goes straight into `Interface/AddOns/`, and each one starts with a single folder: `CherrysKit/`, `CherrysLoginxml/` or `LogNextChar/`.

<!-- project table: tools/curseforge_pages.py writes this -->
| Project | Description | ZIP to upload | Required relations | Optional relations |
| --- | --- | --- | --- | --- |
| Cherry's Kit | [01-cherrys-kit.md](01-cherrys-kit.md) | `CherrysKit-Hub-<kit version>.zip` | none | none |
| Cherry's KittyCombo | [02-cherrys-kittycombo.md](02-cherrys-kittycombo.md) | `CherrysKit-KittyCombo-<version>.zip` | Cherry's Kit | rom weakauras, Cherry's Chat |
| rom weakauras | [03-rom-weakauras.md](03-rom-weakauras.md) | `CherrysKit-RomWeakAuras-<version>.zip` | Cherry's Kit | Cherry's KittyCombo, pbInfo |
| Cherry's Chat | [04-cherrys-chat.md](04-cherrys-chat.md) | `CherrysKit-CherrysChat-<version>.zip` | Cherry's Kit | pbInfo, Ultimate Mail Mod |
| zBag | [05-zbag.md](05-zbag.md) | `CherrysKit-zBag-<version>.zip` | Cherry's Kit | Global Bank, Advanced AuctionHouse |
| Global Bank | [06-global-bank.md](06-global-bank.md) | `CherrysKit-GlobalBank-<version>.zip` | Cherry's Kit | zBag, Advanced AuctionHouse |
| Extended Macro Icons | [07-extended-macro-icons.md](07-extended-macro-icons.md) | `CherrysKit-ExtendedMacroIcons-<version>.zip` | Cherry's Kit | none |
| TooltipIds | [08-tooltipids.md](08-tooltipids.md) | `CherrysKit-TooltipIds-<version>.zip` | Cherry's Kit | pbInfo |
| Ultimate Mail Mod | [09-ultimate-mail-mod.md](09-ultimate-mail-mod.md) | `CherrysKit-UltimateMailMod-<version>.zip` | Cherry's Kit | Cherry's Chat |
| Advanced AuctionHouse | [10-advanced-auctionhouse.md](10-advanced-auctionhouse.md) | `CherrysKit-AdvancedAuctionHouse-<version>.zip` | Cherry's Kit | Global Bank, zBag |
| Cherry's Addon LoadTimes | [11-cherrys-addon-loadtimes.md](11-cherrys-addon-loadtimes.md) | `CherrysKit-LoadTimes-<version>.zip` | Cherry's Kit | none |
| ZShop | [12-zshop.md](12-zshop.md) | `CherrysKit-ZShop-<version>.zip` | Cherry's Kit | Global Bank |
| pbInfo | [13-pbinfo.md](13-pbinfo.md) | `CherrysKit-pbInfo-<version>.zip` | Cherry's Kit | TooltipIds, Cherry's Chat, rom weakauras, Cherry's Quests |
| PortraitHP | [14-portraithp.md](14-portraithp.md) | `CherrysKit-PortraitHP-<version>.zip` | Cherry's Kit | none |
| Cherry's Grid | [15-cherrys-grid.md](15-cherrys-grid.md) | `CherrysKit-CherrysGrid-<version>.zip` | Cherry's Kit | Cherry's KittyCombo |
| Cherry's Quests | [16-cherrys-quests.md](16-cherrys-quests.md) | `CherrysKit-CherrysQuests-<version>.zip` | Cherry's Kit | rom weakauras, pbInfo |
| Cherry's Bar | [17-cherrys-bar.md](17-cherrys-bar.md) | `CherrysKit-CherrysBar-<version>.zip` | Cherry's Kit | Cherry's KittyCombo, Global Bank |
| Cherry's Loginxml | [18-cherrys-loginxml.md](18-cherrys-loginxml.md) | `CherrysLoginxml-<version>.zip` | Cherry's Kit | LogNextChar |
| LogNextChar | [19-lognextchar.md](19-lognextchar.md) | `LogNextChar-<version>.zip` | Cherry's Kit, Cherry's Loginxml | none |
<!-- end of project table -->

The requirements come from `release-packages.json`. After changing them, run `python tools/curseforge_pages.py`: it rewrites the lines at the front of every description, in the numbered pages and in `descriptions.md`, and this table. A test fails when they are out of date.

### How a missing hub gets installed

A ZIP can't install anything by itself. The hub arrives through CurseForge's **Required Dependency** relation, which has to be set on each project, so "the CurseForge app installs it for you" only holds once that is done. People downloading by hand are told by the first line of every description, and the release notes say to install the hub first.

The full kit stays on GitHub rather than becoming a project: it would overlap every other project's files. Link it from the Cherry's Kit page. The Daily Rewards extension isn't a project either, because the Global Bank ZIP already contains it.

### Each addon on its own

`tests/test_addons_alone.py` installs the hub alone, and the hub with one addon at a time, from the real package contents on a simulated client. It fails on any error the full kit doesn't have. What each addon does with another addon is listed above as optional, and all of those uses check that the other addon is there first.

- **Manifest lines for addons that aren't installed:** the client skips a missing XML file silently. A missing Lua file is reported as a script error, which would light the minimap's bug button on every login, so `KitLoad/start.lua` stops those reports and lets every other error through.
- **Global Bank's button on zBag's window** hides itself when zBag isn't installed.
- **Cherry's Loginxml** needs one step more, because the game only reads a login screen from `Interface/loginxml` and a package can only fill `Interface/AddOns`. Its ZIP carries the login screen in `CherrysLoginxml/LoginScreen/`, and `Install login screen.bat` copies it across. The login screen's `.toc` travels as `loginxml.toc.txt`, because the client loads every `.toc` it finds under `Interface/AddOns`, at any depth. The addon says so in chat while the login screen is missing or a different version.

### First publish

1. Create the **Cherry's Kit** project from the hub ZIP. It has to exist before anything can name it as a requirement.
2. Create **Cherry's Loginxml**, then the kit addons, then **LogNextChar**, which requires Cherry's Loginxml.
3. On each project's upload, set the required and optional relations from the table.
4. Paste each description from its numbered page, then replace the names in its first lines with links to the projects.
5. Install one addon through the app into a clean game folder, and check that the hub arrives with it. Do this before relying on it in the descriptions.

### Every release

1. Run `python tools/build_release.py`, and upload only the ZIPs whose version changed, plus the hub when it did. An addon's `minimum_hub_version` says which hub it needs.
2. Set the relations again on each upload if CurseForge doesn't carry them over from the last file.
3. Update the description when the behaviour or the requirements changed.

### Not confirmed yet

- Runes of Magic project pages on CurseForge show "Install via App" and a "Required Dependency" relation type, and their install notes say to unzip into `Interface\AddOns`. Whether the app really follows that relation for this game hasn't been tried. Step 5 above answers it.
- No single-addon install has run in the real client yet. The checks in [TESTING.md](../TESTING.md) cover it.

## Descriptions

- [Cherry's Kit](01-cherrys-kit.md)
- [Cherry's KittyCombo](02-cherrys-kittycombo.md)
- [rom weakauras](03-rom-weakauras.md)
- [Cherry's Chat](04-cherrys-chat.md)
- [zBag](05-zbag.md)
- [Global Bank](06-global-bank.md)
- [Extended Macro Icons](07-extended-macro-icons.md)
- [TooltipIds](08-tooltipids.md)
- [Ultimate Mail Mod](09-ultimate-mail-mod.md)
- [Advanced AuctionHouse](10-advanced-auctionhouse.md)
- [Cherry's Addon LoadTimes](11-cherrys-addon-loadtimes.md)
- [ZShop](12-zshop.md)
- [pbInfo](13-pbinfo.md)
- [PortraitHP](14-portraithp.md)
- [Cherry's Grid](15-cherrys-grid.md)
- [Cherry's Quests](16-cherrys-quests.md)
- [Cherry's Bar](17-cherrys-bar.md)
- [Cherry's Loginxml](18-cherrys-loginxml.md)
- [LogNextChar](19-lognextchar.md)
