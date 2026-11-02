# Addon map

Written by `tools/curseforge_pages.py` from `release-packages.json`. Run it after changing that file.

Every addon needs the hub and lives under `Interface\AddOns\CherrysKit`, because the hub's manifest is what loads it. Each one runs with only the hub: what's listed under **Works with** is missing until you add that addon, and nothing else is. `tests/test_addons_alone.py` runs each one that way on a simulated client, and `tests/test_addon_map.py` fails if an addon reaches for another one that isn't listed here.

If an addon's original, or an older separate copy, is in its own folder in `Interface\AddOns`, that one takes precedence: the kit's version stays off and the hub says so, one line for each, in chat and in its window. Both still load, because the game can't skip a file in a manifest. `!setup_cherryskit.bat` offers to move such folders to `Interface\offloaded_addons`, but only when the kit's own copy is installed. The Global Bank page's Addons page marks them too, with a **Switch with** button that installs the kit's addon if needed and then offloads the old folder.

## Why everything lives under CherrysKit

One folder, loaded and controlled by the hub, keeps the kit simple to develop and lets the hub's switches cover every addon in it. It also keeps the kit out of the way of anyone who'd rather run their own version of an addon. Compatibility with addons managed separately can't be guaranteed, so when one is there, the kit's version stays off instead of clashing with it.

## The addons

| Addon | Installed at | Works with | Takes precedence if present |
| --- | --- | --- | --- |
| Cherry's KittyCombo | `CherrysKit\KittyCombo` | rom weakauras, Cherry's Chat, Cherry's Grid, Cherry's Bar | `AddOns\KittyCombo`, KittyCombo 0.973 by Miranda |
| rom weakauras | `CherrysKit\RomWeakAuras` | Cherry's KittyCombo, Cherry's Info | `AddOns\RomWeakAuras`, an older copy |
| Cherry's Chat | `CherrysKit\CherrysChat` | Cherry's Info, Ultimate Mail Mod, Cherry's KittyCombo | `AddOns\CherrysChat`, an older copy |
| zBag | `CherrysKit\zBag` | Global Bank, Advanced AuctionHouse | `AddOns\zBag`, zBag 5.07 by adisadicul |
| Global Bank | `CherrysKit\GlobalBank` | zBag, Advanced AuctionHouse, ZShop, Cherry's Bar, LogNextChar, Cherry's Info | `AddOns\GlobalBank`, an older copy |
| Ultimate Mail Mod | `CherrysKit\UltimateMailMod` | Cherry's Chat, LogNextChar | `AddOns\UltimateMailMod`, Ultimate Mail Mod by Shardea of Siochain, later Maxeem of Muinin, mvoigt, Jagodragon and Raihir |
| Advanced AuctionHouse | `CherrysKit\AdvancedAuctionHouse` | Global Bank, zBag | `AddOns\AdvancedAuctionHouse`, Advanced AuctionHouse 6.0.2 by Mavoc, TellTod, Noguai and Graves |
| Cherry's Addon LoadTimes | `CherrysKit\LoadTimes` | nothing | `AddOns\!CherrysLoadTimes`, an older copy |
| ZShop | `CherrysKit\ZShop` | Global Bank | `AddOns\ZShop`, ZShop by Pyrr |
| Cherry's Info | `CherrysKit\CherrysInfo` | rom weakauras, Cherry's Chat, Global Bank | `AddOns\pbInfo`, pbInfo v0.60 by p.b. a.k.a. novayuna, later odie2; `AddOns\PortraitHP`, PortraitHP v2019.07.14 by Nonante@Nuada; `AddOns\TooltipIds`, TooltipIds 1.0b3 by Rock5; `AddOns\ExtendedMacroIcons`, ExtendedMacroIcons 2.15 by Amurilon; `AddOns\CherrysQuests`, an older copy |
| Cherry's Grid | `CherrysKit\CherrysGrid` | Cherry's KittyCombo | `AddOns\GridCliqueIt`, GridCliqueIt by Skaryon, Jacobian and odie2 |
| Cherry's Bar | `CherrysKit\CherrysBar` | Cherry's KittyCombo, Global Bank | `AddOns\XBar`, XBar III by matif and Bussdee |
| LogNextChar | `CherrysKit\LogNextChar` | Global Bank, Ultimate Mail Mod | `AddOns\LogNextChar`, an older copy; `AddOns\CherrysLoginxml`, an older copy |

## What each link does

### Cherry's KittyCombo

- **rom weakauras:** use your auras as combo conditions
- **Cherry's Chat:** its code boxes use Cherry's Chat's copy-box size
- **Cherry's Grid:** click a party or raid frame to run a kitty
- **Cherry's Bar:** the Kitty mode shows on Cherry's Bar instead of its own plate
- **Other addons:** AddonManager lists it when you have that addon.

### rom weakauras

- **Cherry's KittyCombo:** triggers for KittyCombo's next skills and modes
- **Cherry's Info:** mob information for triggers and the macro icon categories in its icon picker, and its quest tracker can use rom weakauras' fonts
- **Note:** It's a rewrite of WeakAuras for World of Warcraft, so there's no original for this game.

### Cherry's Chat

- **Cherry's Info:** class colours for names, from Cherry's Info's player list
- **Ultimate Mail Mod:** Ctrl+click a name in chat to fill the mail's To
- **Cherry's KittyCombo:** KittyCombo's code boxes use the same copy-box size

### zBag

- **Global Bank:** a Global Bank button on the one-bag window
- **Advanced AuctionHouse:** clicks in the bag work in the auction window
- **Other addons:** AddonManager lists it when you have that addon. BagSearch 1.21, BagSort 1.05b, PocketMaid and Sol are built in, so delete any separate `BagSearch` or `BagSort` folder. The quick-sell filter is based on Lootomatic, which is a separate addon and can stay.

### Global Bank

- **zBag:** a Global Bank button on zBag's one-bag window
- **Advanced AuctionHouse:** its searches fill the helper's auction cache
- **ZShop:** ZShop's daily reminder gets the real time from the Chrome extension or helper
- **Cherry's Bar:** Cherry's Bar's Clock gets the real time from the Chrome extension
- **LogNextChar:** the character screen shows each character's gold and last save, the server screen shows the helper's status, and its list of your account's characters boxes them together on the page and fills in their servers
- **Cherry's Info:** the macro window's Import button brings in macros from the page's library, and the page shows its extra macro icons

### Ultimate Mail Mod

- **Cherry's Chat:** Ctrl+click a name in chat to fill the mail's To
- **LogNextChar:** LogNextChar closes the mail window before switching characters
- **Other addons:** AddonManager lists it when you have that addon. Its libraries, LibStub and Sol, come with it.

### Advanced AuctionHouse

- **Global Bank:** Global Bank's helper keeps a searchable cache of your auction searches
- **zBag:** clicks in the bag work in the auction window
- **Other addons:** AddonManager lists it when you have that addon.
- **Note:** Its saved searches, price history and settings carry over to this version.

### Cherry's Addon LoadTimes

- No links to other addons.
- **Other addons:** It times every addon the game loads, kit or not, and needs none of them.

### ZShop

- **Global Bank:** the daily reminder uses the real time, from Global Bank's Chrome extension or helper

### Cherry's Info

- **rom weakauras:** rom weakauras' fonts for the quest tracker; its triggers and icon picker can use the mob information and macro icon categories from here
- **Cherry's Chat:** class colours in chat from its player list
- **Global Bank:** the macro window's Import button lists its macro library

### Cherry's Grid

- **Cherry's KittyCombo:** run a kitty when you click a frame
- **Note:** Cherry's Grid is new code that follows its design, and the two would draw the same raid frames.

### Cherry's Bar

- **Cherry's KittyCombo:** the Kitty mode display
- **Global Bank:** the Clock shows the real time, from Global Bank's Chrome extension
- **Other addons:** Its Performance display times the update loops of other addons it finds, kit or not, including Lootomatic. It only reads their names, so none of them are needed.

### LogNextChar

- **Global Bank:** shows each character's gold and last save on the character screen and the helper's status on the server screen, and gives it your account's character list, which boxes them together on its page and fills in their servers
- **Ultimate Mail Mod:** closes its window before switching characters, as it does the game's mail window
- **Note:** Install login screen.bat, or the guided setup, moves those folders to `Interface\offloaded_addons` for you, along with `CherrysKit\CherrysLoginxmlHook` from before Cherry's Loginxml became part of this addon. The login screen itself is Rom Autologin by Pyrrhus with fixes, and has to live in `Interface\loginxml`, the only place the game reads one: the same installer updates what is there, copies the old folder to `Interface\offloaded_addons` first, and keeps your saved logins.
