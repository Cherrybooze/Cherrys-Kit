# Repository instructions

- The working source is under Interface/AddOns/CherrysKit. Preserve the install paths, saved variables, credits and existing licence notices.
- Every new release must bump the runtime version of each changed addon, including the hub when changed, and the overall kit version. Keep release-packages.json and the relevant READMEs in sync.
- Carry unchanged addon packages forward with their existing versions and identical contents. Do not overwrite published files with changed contents under an old version.
- Publish a fresh release tag for changed runtime code. Keep the first README download graphic and all direct installer links pointed at the new full-kit asset.
- Run the Lua 5.1 regression tests and release-package checks relevant to the changes. Report simulated-client validation separately from in-game validation.
