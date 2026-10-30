# Global Bank Daily Rewards — Chrome Web Store draft

This is a working draft, not a published listing or final privacy policy.

## Listing description

Global Bank Daily Rewards helps Runes of Magic players collect an available Daily Loyalty Bonus on the Gameforge shop page. Once Gameforge confirms the collection, the extension can record the character, server, reward day and collection time in the local Global Bank helper data for a matching level 100 character.

The extension can show whether the Global Bank helper is running and offers a button to start it. The helper and its native messaging bridge must be installed separately with Cherry's Kit. The extension is an independent community tool and is not presented as an official Gameforge product.

## Data handling draft

On the Daily Loyalty Bonus page, the extension reads the displayed character name, server and reward state. It keeps the pending collection and last status in memory for the browser session. It clears temporary data left in Chrome local storage by earlier versions when the daily page is next opened. When the page confirms a collection, it sends the character name, server and reward day to the locally installed Global Bank bridge. The bridge checks local character data and saves a collection timestamp in the local GlobalBankHelper folder. It also checks whether the helper is running and can start it when requested. The extension does not intentionally send this data to the developer; collecting a reward interacts with Gameforge's page and service. The extension does not need the player's password.

The extension’s session data is cleared when the browser closes or the extension is disabled, reloaded or updated; the separately installed local helper data can be removed from the game's Interface\GlobalBankHelper folder. That folder may also contain other Global Bank data, so users should preserve anything they wish to keep.

The local bridge also writes Windows' time to `CherrysClockStamp.lua` in that same folder whenever Chrome starts or the extension contacts it, so the game's addons can show the real time. That file stays on the player's PC.

## Before submission

- Register and configure the owner's Chrome Web Store developer account, including required verification.
- Add an in-extension, affirmative consent flow and disclosure before reading or recording user data; verify against current Google policy.
- Publish an accurate privacy policy at a publicly accessible URL and provide it in the dashboard.
- Add the required extension icon and capture a current, suitably sized screenshot of the actual extension experience.
- Upload a draft, then verify its store-assigned extension ID. Update and test the native host allowlist and installation instructions for the actual store ID; do not assume it matches the unpacked development ID.
- Complete permission and data-use declarations and submit for Google's review. Verify the Gameforge page and native bridge end to end using the store-installed extension.
