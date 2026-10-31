# Addon map

Written by `tools/curseforge_pages.py` from `release-packages.json`. Run it after changing that file.

Every addon needs the hub and lives under `Interface\AddOns\CherrysKit`, because the hub's manifest is what loads it. Each one runs with only the hub: what's listed under **Works with** is missing until you add that addon, and nothing else is. `tests/test_addons_alone.py` runs each one that way on a simulated client, and `tests/test_addon_map.py` fails if an addon reaches for another one that isn't listed here.

If an addon's original, or an older separate copy, is in its own folder in `Interface\AddOns`, that one takes precedence: the kit's version stays off and the hub says so, one line for each, in chat and in its window. Both still load, because the game can't skip a file in a manifest.

| Addon | Installed at | Works with | Takes precedence if present |
| --- | --- | --- | --- |
| Cherry's KittyCombo | `CherrysKit\KittyCombo` | rom weakauras, Cherry's Chat, Cherry's Grid, Cherry's Bar | `AddOns\KittyCombo`, KittyCombo 0.973 by Miranda |
| rom weakauras | `CherrysKit\RomWeakAuras` | Cherry's KittyCombo, pbInfo, Extended Macro Icons, Cherry's Quests | `AddOns\RomWeakAuras`, an older copy |
| Cherry's Chat | `CherrysKit\CherrysChat` | pbInfo, Ultimate Mail Mod, Cherry's KittyCombo | `AddOns\CherrysChat`, an older copy |
| zBag | `CherrysKit\zBag` | Global Bank, Advanced AuctionHouse | `AddOns\zBag`, zBag 5.07 by adisadicul |
| Global Bank | `CherrysKit\GlobalBank` | zBag, Advanced AuctionHouse, ZShop, Cherry's Bar, Cherry's Loginxml | `AddOns\GlobalBank`, an older copy |
| Extended Macro Icons | `CherrysKit\ExtendedMacroIcons` | rom weakauras | `AddOns\ExtendedMacroIcons`, ExtendedMacroIcons 2.15 by Amurilon |
| TooltipIds | `CherrysKit\TooltipIds` | pbInfo | `AddOns\TooltipIds`, TooltipIds 1.0b3 by Rock5 |
| Ultimate Mail Mod | `CherrysKit\UltimateMailMod` | Cherry's Chat, LogNextChar | `AddOns\UltimateMailMod`, Ultimate Mail Mod by Shardea of Siochain, later Maxeem of Muinin, mvoigt, Jagodragon and Raihir |
| Advanced AuctionHouse | `CherrysKit\AdvancedAuctionHouse` | Global Bank, zBag | `AddOns\AdvancedAuctionHouse`, Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves |
| Cherry's Addon LoadTimes | `CherrysKit\LoadTimes` | nothing | `AddOns\!CherrysLoadTimes`, an older copy |
| ZShop | `CherrysKit\ZShop` | Global Bank | `AddOns\ZShop`, ZShop by Pyrr |
| pbInfo | `CherrysKit\pbInfo` | TooltipIds, Cherry's Chat, rom weakauras, Cherry's Quests | `AddOns\pbInfo`, pbInfo v0.60 by p.b. a.k.a. novayuna, later odie2 |
| PortraitHP | `CherrysKit\PortraitHP` | nothing | `AddOns\PortraitHP`, PortraitHP v2019.07.14 by Nonante@Nuada |
| Cherry's Grid | `CherrysKit\CherrysGrid` | Cherry's KittyCombo | `AddOns\GridCliqueIt`, GridCliqueIt by Skaryon, Jacobian and odie2 |
| Cherry's Quests | `CherrysKit\CherrysQuests` | rom weakauras, pbInfo | `AddOns\CherrysQuests`, an older copy |
| Cherry's Bar | `CherrysKit\CherrysBar` | Cherry's KittyCombo, Global Bank | `AddOns\XBar`, XBar III by matif and Bussdee |
| Cherry's Loginxml | `CherrysKit\CherrysLoginxmlHook` | LogNextChar, Global Bank | `AddOns\CherrysLoginxml`, an older copy |
| LogNextChar | `CherrysKit\LogNextChar` | Cherry's Loginxml, Ultimate Mail Mod | `AddOns\LogNextChar`, an older copy |

## What each link does

### Cherry's KittyCombo

- **rom weakauras:** use your auras as combo conditions
- **Cherry's Chat:** shares its copy-box size
- **Cherry's Grid:** Cherry's Grid can run a kitty when you click a frame
- **Cherry's Bar:** Cherry's Bar shows the Kitty mode
- **Other addons:** AddonManager lists it when you have that addon.

### rom weakauras

- **Cherry's KittyCombo:** track its next skills and modes
- **pbInfo:** mob information for triggers
- **Extended Macro Icons:** its icon picker uses the icon categories
- **Cherry's Quests:** Cherry's Quests can use its fonts
- **Note:** It's a rewrite of WeakAuras for World of Warcraft, so there's no original for this game.

### Cherry's Chat

- **pbInfo:** class colours from its player list
- **Ultimate Mail Mod:** Ctrl+click a name in chat to fill the mail's To
- **Cherry's KittyCombo:** KittyCombo shares its copy-box size

### zBag

- **Global Bank:** a Global Bank button on the one-bag window
- **Advanced AuctionHouse:** clicks in the bag work in the auction window
- **Other addons:** AddonManager lists it when you have that addon. BagSearch 1.21, BagSort 1.05b, PocketMaid and Sol are built in, so delete any separate `BagSearch` or `BagSort` folder. The quick-sell filter is based on Lootomatic, which is a separate addon and can stay.

### Global Bank

- **zBag:** a button on the one-bag window
- **Advanced AuctionHouse:** its searches fill the helper's auction cache
- **ZShop:** its Chrome extension or helper tells ZShop the time, for the daily reminder
- **Cherry's Bar:** its Chrome extension gives Cherry's Bar's Clock the real time
- **Cherry's Loginxml:** the character screen shows each character's gold and last save, the server screen shows the helper's status, and its list of your account's characters boxes them together on the page and fills in their servers

### Extended Macro Icons

- **rom weakauras:** rom weakauras' icon picker uses its categories

### TooltipIds

- **pbInfo:** ID numbers in its tooltips too
- **Other addons:** AddonManager lists it when you have that addon.

### Ultimate Mail Mod

- **Cherry's Chat:** Ctrl+click a name in chat to fill the mail's To
- **LogNextChar:** LogNextChar closes its window before switching characters
- **Other addons:** AddonManager lists it when you have that addon. Its libraries, LibStub and Sol, come with it.

### Advanced AuctionHouse

- **Global Bank:** its helper keeps a searchable auction cache
- **zBag:** clicks in the bag work in the auction window
- **Other addons:** AddonManager lists it when you have that addon.
- **Note:** Its saved searches, price history and settings carry over to this version.

### Cherry's Addon LoadTimes

- No links to other addons.
- **Other addons:** It times every addon the game loads, kit or not, and needs none of them.

### ZShop

- **Global Bank:** its Chrome extension or helper tells ZShop the time, for the daily reminder

### pbInfo

- **TooltipIds:** ID numbers in its tooltips
- **Cherry's Chat:** class colours from its player list
- **rom weakauras:** mob information for triggers
- **Cherry's Quests:** takes over from its quest tracker
- **Other addons:** AddonManager lists it when you have that addon.

### PortraitHP

- No links to other addons.
- **Other addons:** AddonManager lists it when you have that addon.

### Cherry's Grid

- **Cherry's KittyCombo:** run a kitty when you click a frame
- **Note:** Cherry's Grid is new code that follows its design, and the two would draw the same raid frames.

### Cherry's Quests

- **rom weakauras:** more fonts to choose from
- **pbInfo:** keeps its quest tracker out of the way

### Cherry's Bar

- **Cherry's KittyCombo:** the Kitty mode display
- **Global Bank:** its Chrome extension gives the Clock the real time
- **Other addons:** Its Performance display times the update loops of other addons it finds, kit or not, including Lootomatic. It only reads their names, so none of them are needed.

### Cherry's Loginxml

- **LogNextChar:** Next and Prev character buttons in game
- **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
- **Note:** Install login screen.bat removes that folder for you. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer replaces whatever is there and keeps your saved logins.

### LogNextChar

- **Cherry's Loginxml:** picks the next or previous character on the login screen; without it Next and Prev only log you out, and you pick the character yourself
- **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
