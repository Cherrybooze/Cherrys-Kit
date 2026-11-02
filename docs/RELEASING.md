# Building and publishing releases

All source stays on `main`. A release tag records one snapshot of the full collection; individual addon ZIPs are assets of that same release.

## Build

Use Python 3.10 or later and no extra packages:

```sh
python tools/build_release.py
```

Outputs go to `dist/<kit version>/`, which is ignored by Git. Each version gets its own folder so old and new release files cannot be mixed:

- `CherrysKit-Full-<kit version>.zip`: the complete installed tree.
- `CherrysKit-Hub-<kit version>.zip`: shared root files, KitLoad, Media and hub reference docs.
- One `CherrysKit-<folder>-<addon version>.zip` per addon, LoadTimes included.
- `CherrysKit-GlobalBankDailyRewards-<extension version>.zip`: optional Chrome extension and local bridge, installed separately on top of Global Bank.
- `LogNextChar-<version>.zip`: a separate package under `CherrysKit/`, and not in the full kit, with the login screen inside it. The hub's manifest loads it when it's there.
- `release-manifest.json`: package versions, dependency notes, file inventories and hashes.
- `release-versions.json`: the same packages without their file lists, for the guided setup to read each time it opens.
- `SHA256SUMS.txt`: hashes of every ZIP and of those two files.
- `RELEASE_NOTES.md`: notes ready for the GitHub release.

The builder uses fixed ZIP timestamps and a sorted file order. With the same source and Python/zlib version, ZIP contents and checksums are reproducible. It checks ZIP integrity, compares every archived file with the source, verifies the full kit equals the union of the hub and individual addons, checks the shared manifest, and checks local Markdown links.

Private character data is never a release input. The builder rejects `GlobalBankHelper`, saved helper backups, `Backups`, `TerminalBridge` and `offloaded_addons`, plus copied mail, tooltip, account-vault, macro, terminal and character-save files, including temporary/backup suffixes. It also rejects source input links and Windows junctions. Every ZIP route, including the Chrome Web Store archive, checks its inventory before writing; tracked private files anywhere in the repository stop the build so GitHub's source archive stays clean too. Keep the local data shared by your own Steam/Gameforge clients outside source/addon folders you distribute.

The hub's manifest lists the optional addons in a fixed order. Its first two entries are `KitLoad/start.lua`, which gives the load marks a do-nothing default, and `LoadTimes/Load.lua`, which reads `LoadTimes/Switch.txt` and only then loads LoadTimes' timing code; the builder checks that order. Without LoadTimes, or with it switched off, the marks stay do-nothing and the probe frames in `LoadTimes/CherrysLoadTimes.xml` and `LoadTimesLast.xml` stop on their first frame. Since kit 0.11.87 the hub does not bundle LoadTimes.

The hub alone and hub-plus-addon selections deliberately lack the unselected addons listed in the shared manifest. The package check distinguishes those optional paths from missing shared files; it cannot prove the client's behaviour with absent optional paths. The full kit has no missing manifest files. Test partial installations in game before claiming they have been tested.

## ZIP installation layout

Every install ZIP, including the optional extension ZIP, starts with `CherrysKit/`. Extract it into `<game>/Interface/AddOns/` and merge folders. The Full and Hub ZIPs also carry `!setup_cherryskit.bat` and `!setup_cherryskit.ps1` at the ZIP root, next to `CherrysKit/`. Either one starts the guided setup (`CherrysKit/Setup/Setup-CherrysKit.ps1`), which is also how players update:

```text
<game>/Interface/AddOns/
  CherrysKit/
    CherrysKit.toc
    README.md
    KittyCombo/
      README.md
    ...
```

The ZIPs omit the repository's `Interface/AddOns/` prefix. The source repository keeps that prefix to show where files belong. Users wanting everything should choose the **Full** asset; users choosing addons need the **Hub** asset too. These are kit modules, not separate legacy top-level addon installations.

Each addon includes its own README, local reference notes and the original combined licence file. Cross-addon integrations still need the corresponding addons.

## Publish a version

1. Bump the runtime version of every changed addon and the hub when changed, then the kit version and `release-packages.json`. The kit version must match `CherrysKit.toc`; keep the affected README version labels current. Carry unchanged addon packages forward byte for byte under their existing versions.
2. Update the release summary and runtime-validation notes in the package metadata, affected README limits, and the [CurseForge descriptions](curseforge/README.md) where the behaviour changed.
3. Run the builder and Lua regression suite, then use the relevant [in-game checks](TESTING.md). In release notes, distinguish offline checks from in-game checks.
4. Commit and push to `main`. Let the packaging check pass.
5. Tag that commit, for example `v0.11.77`, and push the tag.
6. Build again from the clean tagged checkout so `release-manifest.json` records the right source commit.
7. Create a GitHub release for the tag with the generated notes. Upload all seventeen install ZIPs (the full kit, the hub, twelve addon ZIPs, LogNextChar, zMail and the optional extension ZIP), `release-versions.json`, `release-manifest.json` and `SHA256SUMS.txt`. The Chrome Web Store archive is a separate upload. Mark it **Latest** when players should get it: the guided setup only offers the release marked Latest.
8. Compare uploaded asset sizes and SHA-256 digests with the local files before publishing.
9. Update the direct full-kit ZIP links at the top of the project README and the repository's About website. Keep the full-kit asset labelled as the installer, and start the release notes with its direct download. Test a downloaded asset by extracting it directly into an empty `Interface/AddOns/` folder: `CherrysKit/CherrysKit.toc` must appear there, with no repository or version wrapper, and the Full and Hub ZIPs must put `!setup_cherryskit.bat` at the root.

Keep the clickable download graphic as the first item in the project README. When releasing a new kit version, update its filename/version text and the image's link to the full-kit ZIP; the graphic lives in [images/download-full-kit.svg](images/download-full-kit.svg).

GitHub's green **Code → Download ZIP** button and **Source code** release links always produce repository snapshots. They are separate from the install ZIPs. Keep the direct installer link prominent so players do not need to find the correct asset in a list.

A draft release is useful while uploading and checking assets. Do not replace an already published release's files silently; make a new version for changed source.

## Keeping addons updateable

The guided setup reads `release-versions.json` from the release marked Latest, compares each package's version with the `Version **x**` line in the installed addon's README, and offers whatever differs. It downloads only those ZIPs, checks each against the release's SHA-256, moves each old folder to `Interface\offloaded_addons\CherrysKit <old kit version> (before update <date>)`, and extracts the new one. Then the new copy of the setup carries on, with the Dependencies step, moving folders the new manifest no longer names, and the login screen and the helper restart. A full-kit install also gets addons new in that release. One that chose addons gets a line naming them.

For that to keep working:

1. **One folder per addon**, at `Interface/AddOns/CherrysKit/<Folder>`, listed in `release-packages.json` and loaded through `CherrysKit.toc`. No `.toc` of its own: the game loads every `.toc` it finds under `AddOns`.
2. **A version line near the top of its README**, `Version **x** · ...`, in the first 12 lines and equal to its version in `release-packages.json`. That line is what the setup compares. A test fails when they differ.
3. **A new version for every changed addon.** Change the files and keep the number, and players never get the change. The hub follows the same rule, and every release gets a new `kit_version`, in `CherrysKit.toc` too.
4. **No player data in addon folders.** An update moves the old folder away. Settings go in saved variables. A file players edit by hand, like `Commands.lua`, must be on the setup's `$script:KeepOnUpdate` list.
5. **Say what a rename or merge replaces.** Take the old folder's lines out of `CherrysKit.toc`, so the setup moves it out, and list the old folders under `origin.others` in `release-packages.json`, so the new addon comes in for whoever had the old one.
6. **ZIPs hold only `CherrysKit/...`**, plus the two launchers at the root of the Full and Hub ZIPs. An addon kept beside the kit, like zMail, fills only its own folder, named by its `install_folder`, and says its version on the first line of `CherrysKit-version.txt`. The builder checks this, and the setup refuses anything else.
7. **A release is tagged `v<kit version>`, carries every ZIP, `release-versions.json`, `release-manifest.json` and `SHA256SUMS.txt`, and is marked Latest.** The setup only offers the release marked Latest, so a prerelease reaches testers by its link and not through the tool. Never replace a published ZIP's files.
8. **Try the update before publishing:** build, then run `Setup-CherrysKit.ps1 -ReleaseFolder dist\<kit version>` in a copy of a game folder. Add `-ReinstallAll` to reinstall packages whose version didn't change.
9. **Say what an addon can use.** The setup's Dependencies step offers the `works_with` addons in `release-packages.json` to anyone who has the addon naming them. A Windows program an addon needs goes in the setup's `Get-Dependencies`.

`tests/test_setup_helper.py` checks these against throwaway game folders, with a build folder standing in for GitHub.

## LogNextChar

LogNextChar lives in `Interface/AddOns/LogNextChar` (its in-game half and installer) and `Interface/loginxml` (the login screen, which the build puts in its zip as `LoginScreen/`). The login screen's original project is by Pyrrhus, MIT licence unchanged (`LICENSE-Loginxml.txt`), integration fixes by Cherry. It isn't part of the full kit.

`Interface/loginxml/data` holds blank templates only; never put real accounts or passwords in this repository. The builder stops on a personal file or a filled-in template.

To release it, bump its version (`version` in `frames/login.lua`, `me.version` in `LogNextChar.lua`) and `release-packages.json`, and add the changes to the top of `Interface/loginxml/CHANGELOG`.

## CurseForge

The [release plan](curseforge/README.md#release-plan) lists every project, its ZIP and its relations, and how a missing hub gets installed.

Each addon project should declare the hub as a **Required** dependency before its description says CurseForge installs it automatically. Preserve the common `CherrysKit/` layout and check the install result with the actual client; do not infer client support from the ZIP validator.

The [numbered description files](curseforge/README.md) preserve the initial handoff text. They include existing credit/licence notes and features not yet confirmed in game. The GitHub source upload does not configure or publish CurseForge projects.
