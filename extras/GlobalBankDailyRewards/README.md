# Global Bank Daily Rewards for Chrome

This optional Windows extension collects an available Daily Loyalty Bonus when you open the Gameforge Runes of Magic daily shop page. After the page confirms collection, its local bridge records the reward for a matching level 100 character in the Global Bank helper data. Install Cherry's Kit and Global Bank first.

## Install on Windows

**You need:** Google Chrome and Cherry's Kit with Global Bank installed. You do **not** need Python for the addons, the Global Bank helper, or this extension.

1. Install the [full Cherry's Kit](../../README.md#download-and-install) into your game's `Interface/AddOns/` folder. Check that `Interface/AddOns/CherrysKit/CherrysKit.toc` exists.
2. Download the [separate Global Bank Daily Rewards installer ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v0.11.107/CherrysKit-GlobalBankDailyRewards-1.0.14.zip). Extract it into the **same** `Interface/AddOns/` folder and merge `CherrysKit/`. GitHub's automatic source ZIP is a repository snapshot, not this installer.
3. Open `Interface/AddOns/CherrysKit/GlobalBank/Helper/` in File Explorer and double-click **Install Chrome extension.bat**. It registers the local bridge and brings up Chrome's extensions page, with a small setup window on top.
4. In Chrome, turn on **Developer mode** at the top right, then click **Load unpacked** at the top left. Those two clicks are all Chrome needs: the setup window fills in the folder and closes when the extension connects.
5. If the folder window does not fill itself in, the setup window copies the path for you: press **Ctrl+V** in the folder window, then **Enter**. If the extensions page did not open, type `chrome://extensions/` into Chrome's address bar.
6. Confirm **Global Bank Daily Rewards** appears in Chrome and is enabled. For this page later, double-click **Open Chrome extensions.bat** in the Helper folder.
7. Double-click **Start Global Bank helper.bat** in the same folder. Keep its window open and log in to your characters so the helper can build their snapshots. A single unambiguous matching level 100 character is required to save the local record.
8. In game, open the daily loyalty page through ZShop using Chrome. The extension tries to collect an available reward and records it locally after Gameforge confirms it. Click the extension icon for status. The page can offer to start the helper if it is stopped.

If you are upgrading an already loaded extension, extract the new ZIP over the old files, run the installer again, then click the reload icon on the extension card at `chrome://extensions/`.

The extension is not on the Chrome Web Store. The installer registers a native messaging bridge for the current Windows user; the game and helper remain separate. To install from source instead, copy this folder's `GlobalBank/Helper/` contents into the installed `CherrysKit/GlobalBank/Helper/`, then run the installer there.

## Search your characters and auction cache

The local bank and auction tools are included in version **1.0.3 and later**. The current download includes the searchable auction cache and its sorting controls.

1. Click the **Global Bank Daily Rewards** extension icon in Chrome, then **Open local bank and auction tools**.
2. Check whether the helper is running. If needed, click **Start helper** and leave its window open.
3. Under **Characters, bags and bank**, try `list`, `list gold`, `search mana`, or `show Name`. Type `help` for more commands.
4. Under **Auction cache search**, enter an item name or ID and optionally a realm. The results show saved observations, which may be out of date. If the cache is empty, search in the game and let the helper collect the data.

The **Bank** tab shows everything every character holds in one grid, with the game's own icons, a search and filters; hover an item to see who has it and in which slot. **Update now** reads your save files. The **Terminal** tab runs the helper's commands, including ones that change local data, such as `note` and `erase`. Nothing on this page can buy items. It does not need Python, your game password or the helper window. To collect auction data and update automatically each time you log out, turn on **Start the Global Bank helper automatically when Chrome is open** at the top of the page: it runs hidden, stops when Chrome closes, and turning it off closes it.

## Privacy and scope

Automatic page processing runs only on the Gameforge daily shop page; no content script runs on other websites. The local tools page opens inside the extension and reads your helper data only when you request a search. On the Gameforge daily shop page, the extension reads the displayed character name, server, and reward state. Temporary extension status lives in Chrome session storage. The local bridge stores confirmed names, servers, reward days and timestamps in `Interface/GlobalBankHelper/DailyRewards.json`; it does not send them to the developer or another third party. Collecting communicates with Gameforge. No password or saved login link is needed. The nearby `GlobalBank.json` contains character inventory data and should remain private.

The extension and bridge need Windows, Chrome, and the Global Bank helper. If the character is absent or ambiguous in the helper data, collection can still occur on Gameforge but the bridge refuses to record it. Check the extension status and refresh the character snapshot. In-game and browser behavior should be verified with your own client; this is an independent community project.

### Browse the auction cache

In the local tools page, choose **Show whole cache** to browse saved auctions, or search by item name, ID, or named stat. Choose a stat and optional minimum and maximum values to filter the added stats, and use **Sort by** and **Order** to arrange the results. Use **Previous** and **Next** to move through the cache.

The table includes the seller, buyout, tier, maximum durability, added stats and an estimated end time. End times use the game’s rounded remaining time; prices and availability may have changed since the auction was seen. Older entries can lack item details. Search in game with the updated auction addon and let the helper import the new observations to fill them in. Restart the helper after updating its files.
