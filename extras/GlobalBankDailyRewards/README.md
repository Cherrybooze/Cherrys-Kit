# Global Bank Daily Rewards for Chrome

This optional Windows extension collects an available Daily Loyalty Bonus when you open the Gameforge Runes of Magic daily shop page. After the page confirms collection, its local bridge records the reward for a matching level 100 character in the Global Bank helper data. Install Cherry's Kit and Global Bank first.

## Install

1. Download `CherrysKit-GlobalBankDailyRewards-1.0.1.zip` from the release assets when this version is published. Extract it into the game's `Interface/AddOns/` folder and merge `CherrysKit/`.
2. Run `Interface/AddOns/CherrysKit/GlobalBank/Helper/Install Chrome extension.bat`. The window shows each step and stays open.
3. In Chrome, enable Developer mode, select **Load unpacked**, and paste the path copied by the installer into the folder picker with **Alt+D**, then **Ctrl+V** and **Enter**. Click **Select Folder**, even if the file list looks empty. Chrome requires this one-time step for an unpacked extension.
4. Run the Global Bank helper and log in to your characters so it can create their snapshots. Open the daily page in Chrome via ZShop. A matching level 100 character is required for the local record. The daily page can offer to start the helper if it is stopped.

The extension is not published on the Chrome Web Store. The GitHub source ZIP is a repository snapshot, not this installer. To install from source instead, copy the contents of this folder's `GlobalBank/Helper/` into the installed `CherrysKit/GlobalBank/Helper/`, then run the batch file there.

## Privacy and scope

Automatic page processing runs only on the Gameforge daily shop page; no content script runs on other websites. On that page the extension reads the displayed character name, server, and reward state. Temporary extension status lives in Chrome session storage. The local bridge stores confirmed names, servers, reward days and timestamps in `Interface/GlobalBankHelper/DailyRewards.json`; it does not send them to the developer or another third party. Collecting communicates with Gameforge. No password or saved login link is needed. The nearby `GlobalBank.json` contains character inventory data and should remain private.

The extension and bridge need Windows, Chrome, and the Global Bank helper. If the character is absent or ambiguous in the helper data, collection can still occur on Gameforge but the bridge refuses to record it. Check the extension status and refresh the character snapshot. In-game and browser behavior should be verified with your own client; this is an independent community project.
