# Global Bank for RoM, for Chrome

This optional Windows extension opens Global Bank in a Chrome tab: search items across characters, inspect equipment, mail, currencies and gold, browse saved auctions, manage macros and addon-settings backups, and update or offload addons. Install Cherry's Kit and Global Bank first. The [main README](../../README.md#optional-chrome-extension) explains how the addon, Windows helper and Chrome extension fit together.

It also records your Daily Loyalty Bonus after the Gameforge daily shop page confirms collection for a matching level 100 character. Automatic collection is an optional popup setting, off by default. Item depot pages can also supply your depot data.

The helper now follows Chrome: the extension's button shows whether it is running and for how long, and can stop it or show its terminal window. The helper ends on its own when Chrome or the extension goes away.

## Stats page in 1.3.3

Stat names and their effects appear on the same row in the colours saved from the game. **Who has them** uses each holder's class colour, matching its tooltip. Right-click a stat and choose **Exclude this stat from showing**; **Excluded stats** on the same page restores individual stats or all of them. Exclusions stay on this PC in Chrome's local storage and only filter this page.

Your Steam and Gameforge clients can use the same private local database. Never include `Interface\GlobalBankHelper`, character saves, account files or backups when distributing the kit.

## Install on Windows

**Updating?** Chrome keeps loading the extension from the addon folder, so once the new files are there, click the extension's button and then **Reload extension**, or its Reload arrow on `chrome://extensions`. You don't load it again, and it keeps its settings.

**You need:** Google Chrome and Cherry's Kit with Global Bank installed. You do **not** need Python for the addons, the Global Bank helper, or this extension.

1. Install the [full kit, or the hub plus Global Bank](../../README.md#download-and-install), into your game's `Interface/AddOns/` folder. Check that `Interface/AddOns/CherrysKit/CherrysKit.toc` exists.
2. For a separate extension release, download the [Global Bank for RoM installer ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.116/CherrysKit-GlobalBankDailyRewards-1.3.3.zip). Extract it into the **same** `Interface/AddOns/` and merge `CherrysKit/`. Keep the installed files in their final location. GitHub's automatic source ZIP is a repository snapshot, not this installer.
3. Say yes to the Chrome installer in `!setup_cherryskit.bat`, or open `Interface/AddOns/CherrysKit/GlobalBank/Helper/` and double-click **Install Chrome extension.bat** as your normal Windows user. It registers that user's local bridge and opens Chrome's extensions page, with a small setup window on top. Chrome still needs the next steps.
4. If the extensions page did not open, type **`chrome://extensions/`** into Chrome's address bar. Turn on **Developer mode** at the top right, then click **Load unpacked** at the top left.
5. The setup window tries to fill in and select the folder for you. If it cannot, select **`<game>\Interface\AddOns\CherrysKit\GlobalBank\Helper\ChromeExtension`** manually: this is the folder directly containing **`manifest.json`**. If the setup window says it copied the path, use **Ctrl+V**, then **Enter**, in the folder picker. Do not select the ZIP or the parent Helper folder.
6. Confirm **Global Bank for RoM** appears and is enabled. The small setup window reports a connection and closes. In Chrome's puzzle-piece **Extensions** menu, pin **Global Bank for RoM** if you want its toolbar button always visible. **Open Chrome extensions.bat** in the Helper folder opens the extensions page again later.
7. Click the extension's button, then **Open Global Bank**. Use **Start helper**, or tick **Run automatically while Chrome is open** in the popup, to keep collecting saved character data. The full page's **Connection** panel has the same controls. You can also run **Start Global Bank helper.bat** manually. Log characters in and **out** with Global Bank enabled: logout writes their snapshots, which the helper can then collect. **Update now** on the Bank page reads saved data; it does not update addon software.
8. For daily rewards, open the daily loyalty page through ZShop in Chrome and collect an available reward. A single unambiguous matching level 100 character is required to save its local confirmation. The popup's **Collect automatically on the daily page** can click it for you; it's off by default, and automated use may be against Gameforge's terms of service, so use it at your own risk.

With Steam and Gameforge configured together, use the **Gameforge** copy of the extension folder so Chrome and its local bridge point to the same install. Keep that folder where it is; after moving the game, rerun the installer from the new location and select the new extension folder in Chrome.

These instructions use Chrome's **Load unpacked** installation route. The installer registers a native messaging bridge for the current Windows user; the game and helper remain separate. To install from source instead, copy this folder's `GlobalBank/Helper/` contents into the installed `CherrysKit/GlobalBank/Helper/`, then run the installer there. Chrome's [official instructions](https://developer.chrome.com/docs/extensions/get-started/tutorial/hello-world#load-unpacked) explain loading, pinning and reloading a local extension.

## Update the extension and helper

1. Close the game. Run `!setup_cherryskit.bat` or use **Addons** on the Global Bank page to update Global Bank/helper files. For a separate extension ZIP, extract it over the same installed `Interface/AddOns/` folder too.
2. Click the extension's toolbar button, then **Reload extension**, or click its circular Reload arrow at `chrome://extensions/`. Enable Developer mode if the arrow is hidden. Ordinary updates use the existing extension entry; **Load unpacked** is for a first installation or changed folder.
3. Reopen the popup and Global Bank page. Reload any already open Gameforge daily shop/depot pages too. Check the connection/helper status; use **Start helper** if necessary.
4. Run **Install Chrome extension.bat** again if you moved the game, the bridge was not registered, or the popup reports missing/older helper files. A normal update in the same registered folder only needs Reload after replacing the files.

The [main README's update walkthrough](../../README.md#updating-the-extension) covers both update routes. Reloading the extension tells Chrome to read updated files; **Update now** on the Bank page refreshes character data instead.

## Update, offload and restore addons

Open **Global Bank for RoM → Open Global Bank → Addons**. This manages the game folder associated with the local bridge; it is separate from Chrome's extension-management page. The **Cherry's Kit**, **Other addons** and **Offloaded** lists show the current folders. **Read the folder again** rescans them without installing anything.

- **Check for updates** compares kit packages with this repository's Latest release. With the game closed, **Update from GitHub**, **Update all (N)** or **Download and install** confirms the selected downloads, then opens a separate progress window. It verifies checksums, keeps previous files in `Interface\offloaded_addons`, and shows the result on the page. Global Bank's running helper is paused for its own update and resumed afterwards. Reload the extension after its files change. Updating LogNextChar also needs its login-screen installer afterwards.
- **Offload** moves the selected folder out of the game's addon search path and keeps it under `Interface\offloaded_addons`; saved settings remain in the game saves. **Restore** returns a folder parked by the page to its recorded location. It refuses to overwrite a folder already there. Start the game or Reload UI after either action.
- **Delete** asks first, then sends an ordinary folder to the Recycle Bin. **Remove link** removes only the link. Use Offload when you want the page to keep the addon ready to bring back. The hub and Global Bank cannot remove themselves through this page.
- **Switch with ...** installs a replacement if needed, then offloads the old addon. The **Mail** panel switches Ultimate Mail Mod/zMail; selecting Ultimate Mail Mod parks zMail because it has no in-game off switch. Reload UI applies the mailbox choice.

Older backups moved by setup or created before an update may have no **Restore** button: use File Explorer to return them to their original locations. Kit addons belong inside `Interface\AddOns\CherrysKit`, other addons beside it. A separately managed addon can be listed without being updateable from this repository. If these newer controls are missing, check the release notes and update the Global Bank and extension files; published ZIPs can lag behind this branch.

See the [main README](../../README.md#manage-addons-from-chrome) for the full action table, replacement examples and recovery steps.

## Search your characters and auction cache

The local bank and auction tools are included in version **1.0.3 and later**. The current download includes the searchable auction cache and its sorting controls.

1. Click the **Global Bank for RoM** extension icon in Chrome, then **Open Global Bank**.
2. The top of the page says whether the helper is running. If needed, open **Connection** and click **Start helper**.
3. On **Terminal**, try `list`, `list gold`, `search mana`, or `show Name`. Type `help` for more commands.
4. On **Auctions**, enter an item name or ID and optionally a realm. The results show saved observations, which may be out of date. If the cache is empty, search in the game and let the helper collect the data.

The **Bank** page shows everything every character holds in one grid, with the game's own icons, a search and filters; hover an item to see who has it and in which slot, or click it for a panel. **Update now** reads your save files. The **Terminal** page runs the helper's commands in the running helper, including ones that change local data, such as `note` and `erase`. Nothing on this page can buy items. It does not need Python, your game password or the helper window. To collect auction data and update automatically each time you log out, open **Connection** and turn on **Run automatically**: the helper runs hidden, stops when Chrome closes, and turning it off closes it.

## Privacy and scope

Automatic page processing runs only on the Gameforge daily shop and item depot pages. The local tools page opens inside the extension and reads your saved helper data for the views you open. On the daily shop page, the extension reads the displayed character name, server and reward state. Temporary extension status lives in Chrome session storage. The local bridge stores confirmed names, servers, reward days and timestamps in `Interface/GlobalBankHelper/DailyRewards.json`; it does not send them to the developer or another third party. Collecting communicates with Gameforge. The Addons page contacts this repository on GitHub when you check for updates or request downloads. No game password or saved login link is needed for bank viewing. The nearby `GlobalBank.json` contains character inventory data and should remain private. See the [privacy policy](../../docs/privacy.md) for the full scope.

The extension and bridge need Windows, Chrome, and the Global Bank helper. If the character is absent or ambiguous in the helper data, collection can still occur on Gameforge but the bridge refuses to record it. Check the extension status and refresh the character snapshot. In-game and browser behavior should be verified with your own client; this is an independent community project.

### Browse the auction cache

In the local tools page, choose **Show whole cache** to browse saved auctions, or search by item name, ID, or named stat. Choose a stat and optional minimum and maximum values to filter the added stats, and use **Sort by** and **Order** to arrange the results. Use **Previous** and **Next** to move through the cache.

The table includes the seller, buyout, tier, maximum durability, added stats and an estimated end time. End times use the game’s rounded remaining time; prices and availability may have changed since the auction was seen. Older entries can lack item details. Search in game with the updated auction addon and let the helper import the new observations to fill them in. Restart the helper after updating its files.
