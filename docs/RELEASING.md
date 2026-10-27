# Building and publishing releases

All source stays on `main`. A release tag records one snapshot of the full collection; individual addon ZIPs are assets of that same release.

## Build

Use Python 3.10 or later and no extra packages:

```sh
python tools/build_release.py
```

Outputs go to `dist/<kit version>/`, which is ignored by Git. Each version gets its own folder so old and new release files cannot be mixed:

- `CherrysKit-Full-<kit version>.zip`: the complete installed tree.
- `CherrysKit-Hub-<kit version>.zip`: shared root files, KitLoad, Media, hub reference docs, and LoadTimes.
- One `CherrysKit-<folder>-<addon version>.zip` per addon, including LoadTimes.
- `release-manifest.json`: package versions, dependency notes, file inventories and hashes.
- `SHA256SUMS.txt`: hashes of every ZIP and the release manifest.
- `RELEASE_NOTES.md`: notes ready for the GitHub release.

The builder uses fixed ZIP timestamps and a sorted file order. With the same source and Python/zlib version, ZIP contents and checksums are reproducible. It checks ZIP integrity, compares every archived file with the source, verifies the full kit equals the union of the hub and individual addons, checks the shared manifest, and checks local Markdown links.

The hub's manifest lists the optional addons in a fixed order. The hub includes LoadTimes because `KitLoad/*.lua` and `LoadTimesLast.xml` call its hooks. The individual LoadTimes ZIP is an update to files already shipped with the hub. Keep that duplicate dependency explicit until the loader is deliberately changed.

The hub alone and hub-plus-addon selections deliberately lack the unselected addons listed in the shared manifest. The package check distinguishes those optional paths from missing shared files; it cannot prove the client's behaviour with absent optional paths. The full kit has no missing manifest files. Test partial installations in game before claiming they have been tested.

## ZIP installation layout

Every install ZIP starts with `CherrysKit/`. Extract it into `<game>/Interface/AddOns/` and merge folders:

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
7. Create a GitHub release for the tag with the generated notes. Upload all sixteen ZIPs, `release-manifest.json` and `SHA256SUMS.txt`.
8. Compare uploaded asset sizes and SHA-256 digests with the local files before publishing.
9. Update the direct full-kit ZIP links at the top of the project README and the repository's About website. Keep the full-kit asset labelled as the installer, and start the release notes with its direct download. Test a downloaded asset by extracting it directly into an empty `Interface/AddOns/` folder: `CherrysKit/CherrysKit.toc` must appear there, with no repository or version wrapper.

Keep the clickable download graphic as the first item in the project README. When releasing a new kit version, update its filename/version text and the image's link to the full-kit ZIP; the graphic lives in [images/download-full-kit.svg](images/download-full-kit.svg).

GitHub's green **Code → Download ZIP** button and **Source code** release links always produce repository snapshots. They are separate from the install ZIPs. Keep the direct installer link prominent so players do not need to find the correct asset in a list.

A draft release is useful while uploading and checking assets. Do not replace an already published release's files silently; make a new version for changed source.

## CurseForge

Each addon project should declare the hub as a **Required** dependency before its description says CurseForge installs it automatically. Preserve the common `CherrysKit/` layout and check the install result with the actual client; do not infer client support from the ZIP validator.

The [numbered description files](curseforge/README.md) preserve the initial handoff text. They include existing credit/licence notes and features not yet confirmed in game. The GitHub source upload does not configure or publish CurseForge projects.
