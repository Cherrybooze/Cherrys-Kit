# Chrome Web Store listing — Global Bank for RoM

Last updated: 2026-11-02. Working metadata for extension **1.3.4**; this file does not publish a store listing.

## Store listing

- **Name:** Global Bank for RoM
- **Short description:** Browse your Runes of Magic characters' items, mail and gold locally, with stat searches and optional daily reward tracking.
- **Single purpose:** A local companion for reviewing and managing Runes of Magic character records.
- **Language:** English.
- **Category and visibility:** publisher to confirm at submission.

Browse saved bags, banks, equipped items, mail, currencies and gold across your characters. Search stats in their original game colours, see who holds them, and keep a local list of stats you want to hide. Use the local macro library, settings backups, auction cache and addon manager from the same page.

Install Cherry's Kit and Global Bank, run the bridge installer, then load the extension in Chrome. Open its button and choose Open Global Bank. The helper reads the game's saved character files; characters need to log out to refresh those files. Your own Steam and Gameforge clients can use the same local database.

Daily reward tracking and automatic collection are optional. Automatic collection is off by default. The extension records collection after the Gameforge page confirms it. Addon downloads run only when you request them.

## Graphics and assets

| Asset | File | Status |
| --- | --- | --- |
| Store icon | `extras/GlobalBankDailyRewards/GlobalBank/Helper/ChromeExtension/icon128.png` | Existing 128 × 128 PNG; check with each upload. |
| Smaller icons | `icon16.png`, `icon32.png`, `icon48.png` beside the store icon | Used by the manifest. |
| Screenshots | Publisher's listing assets | Refresh the Stats screenshot for inline coloured effects, class-coloured holders and Excluded stats. Use fixture characters only. |

## Permissions justification

| Permission or page access | Purpose |
| --- | --- |
| `storage` | Saves preferences, excluded stats, the depot list and the encrypted account-vault copy locally in this Chrome profile. |
| `alarms` | Keeps the local helper informed that Chrome is open when automatic helper operation is enabled. |
| `nativeMessaging` | Reads local helper data and performs the local operations the player requests, such as backups, macro management and addon installation. |
| Gameforge daily and depot content scripts | Read the displayed daily reward state or depot items on the pages the player opens. Runtime URL checks restrict processing to the Runes of Magic shop. |

The Stats changes add no permissions. The manifest and the [privacy policy](docs/privacy.md) describe the current scope.

## Privacy and data use

| Data | Storage and use | Off-device behavior |
| --- | --- | --- |
| Character names, inventory, equipment, gold, currencies, tooltips and mail | Game saves and the private local `Interface/GlobalBankHelper` folder, for the bank and related views. | No upload by the extension or helper. |
| Macros, notes, settings and backups | Private helper files and game saves; changed only by the relevant user-requested operations. | No upload. |
| Gameforge accounts and passwords, when entered | An encrypted vault in local Chrome storage and the helper folder. The unlocking password is not retained. | No upload. |
| Excluded stat names and display preferences | Local Chrome storage; exclusions only filter the Stats page. | No Chrome Sync or upload. |
| Daily reward and depot page data | Local records after the player opens the supported Gameforge page. | Collecting a reward uses Gameforge's existing page/service. The helper does not upload its character database. |
| Addon release files | Downloaded from this GitHub repository after a check/install request. | Requests do not contain character records, mail, macros or account-vault contents. |

Local sharing between a player's own game clients is intentional. Private helper folders, exports, backups and terminal records are excluded from Git and every release-package route. Release input links and junctions are rejected to prevent private files being pulled into a build.

Data is not sold, used for unrelated purposes, or used for credit decisions. See the privacy policy for retention, removal and contact details. Publisher must confirm the store's data-use form against this policy before submission.

## Distribution and publisher details

- **Publisher:** Cherry / Cherrybooze; publisher account details must be confirmed by the owner.
- **Contact email:** not provided in this repository; owner to supply for submission.
- **Support:** [repository issues](https://github.com/Cherrybooze/Cherrys-Kit/issues).
- **Homepage:** [Cherry's Kit](https://github.com/Cherrybooze/Cherrys-Kit).
- **Privacy policy:** [repository policy](https://github.com/Cherrybooze/Cherrys-Kit/blob/main/docs/privacy.md); confirm the listing's public policy URL before submission.
- **Upload:** use the generated `CherrysKit-GlobalBankDailyRewards-ChromeWebStore-1.3.4.zip`. The build removes the unpacked extension's `key`. Confirm the store-assigned ID in the native-host allowlist.

## Version history

| Version | Date | Changes | Status |
| --- | --- | --- | --- |
| 1.3.4 | 2026-11-02 | Correct hub-version comparison; clarify published releases versus reloading installed files. No permission/storage changes. | Draft |
| 1.3.3 | 2026-11-02 | Original stat colours, inline effects, class-coloured holders and local excluded-stat controls. Private-data packaging guards strengthened. | Draft |
| 1.3.2 | 2026-11-02 | Equipment/mail views and addon management; see the repository's release notes. | Prior build; publication status to confirm. |

## Review notes

The remaining native-client checks are in [TESTING.md](docs/TESTING.md). Current publishing notes are in the [store draft](docs/chrome-web-store-draft.md). No submission or store-review outcome is recorded here.
