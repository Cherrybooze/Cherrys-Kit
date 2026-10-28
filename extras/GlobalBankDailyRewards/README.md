# Global Bank Daily Rewards for Chrome

This optional Windows extension collects an available Daily Loyalty Bonus when you open the Gameforge Runes of Magic daily shop page. After the page confirms collection, its local bridge records the reward for a matching level 100 character in the Global Bank helper data. Install Cherry's Kit and Global Bank first.

## Install on Windows

**You need:** Google Chrome and Cherry's Kit with Global Bank installed. You do **not** need Python for the addons, the Global Bank helper, or this extension.

1. Install the [full Cherry's Kit](../../README.md#download-and-install) into your game's `Interface/AddOns/` folder. Check that `Interface/AddOns/CherrysKit/CherrysKit.toc` exists.
2. Download the [separate Global Bank Daily Rewards installer ZIP](https://github.com/Cherrybooze/Cherrys-Kit/releases/download/globalbank-daily-rewards-v1.0.1/CherrysKit-GlobalBankDailyRewards-1.0.1.zip). Extract it into the **same** `Interface/AddOns/` folder and merge `CherrysKit/`. GitHub's automatic source ZIP is a repository snapshot, not this installer.
3. Open `Interface/AddOns/CherrysKit/GlobalBank/Helper/` in File Explorer and double-click **Install Chrome extension.bat**. Keep its window open: it registers the local bridge, prints the exact extension folder, attempts to copy that path, and opens Chrome's extensions page.
4. In Chrome, turn on **Developer mode** at the top right, then click **Load unpacked** at the top left.
5. In the folder picker, press **Alt+D** to focus its address bar, **Ctrl+V** to paste the path, then **Enter**. If the installer says copying failed, type the extension folder path it printed instead. Click **Select Folder**. The picker selects folders, so an empty-looking file list is normal; do not search for the extension in that list.
6. Confirm **Global Bank Daily Rewards** appears in Chrome and is enabled. The newer setup package also includes **Open Chrome extensions.bat** in the Helper folder to reopen the page. Alternatively, type `chrome://extensions/` into Chrome's address bar.
7. Double-click **Start Global Bank helper.bat** in the same folder. Keep its window open and log in to your characters so the helper can build their snapshots. A single unambiguous matching level 100 character is required to save the local record.
8. In game, open the daily loyalty page through ZShop using Chrome. The extension tries to collect an available reward and records it locally after Gameforge confirms it. Click the extension icon for status. The page can offer to start the helper if it is stopped.

The extension is not on the Chrome Web Store. The installer registers a native messaging bridge for the current Windows user; the game and helper remain separate. To install from source instead, copy this folder's `GlobalBank/Helper/` contents into the installed `CherrysKit/GlobalBank/Helper/`, then run the installer there.

## Privacy and scope

Automatic page processing runs only on the Gameforge daily shop page; no content script runs on other websites. On that page the extension reads the displayed character name, server, and reward state. Temporary extension status lives in Chrome session storage. The local bridge stores confirmed names, servers, reward days and timestamps in `Interface/GlobalBankHelper/DailyRewards.json`; it does not send them to the developer or another third party. Collecting communicates with Gameforge. No password or saved login link is needed. The nearby `GlobalBank.json` contains character inventory data and should remain private.

The extension and bridge need Windows, Chrome, and the Global Bank helper. If the character is absent or ambiguous in the helper data, collection can still occur on Gameforge but the bridge refuses to record it. Check the extension status and refresh the character snapshot. In-game and browser behavior should be verified with your own client; this is an independent community project.
