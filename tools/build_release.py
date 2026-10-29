#!/usr/bin/env python3
"""Build and verify Cherry's Kit release assets with Python's standard library."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
from urllib.parse import unquote, urlsplit
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Interface" / "AddOns" / "CherrysKit"
ZIP_TIME = (1980, 1, 1, 0, 0, 0)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_output(*args: str) -> str | None:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def validate_markdown() -> int:
    count = 0
    for path in sorted(ROOT.rglob("*.md")):
        if ".git" in path.parts or "dist" in path.relative_to(ROOT).parts:
            continue
        text = path.read_text(encoding="utf-8-sig")
        fence = chr(96) * 3
        text = re.sub("(?ms)^" + fence + ".*?^" + fence + r"[^\n]*$", "", text)
        for target in re.findall(r"!?\[[^\]]*\]\(([^)\n]+)\)", text):
            target = target.strip().strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or target.startswith(("#", "//")):
                continue
            local_path = unquote(parsed.path)
            if not local_path:
                continue
            destination = (path.parent / local_path).resolve()
            require(destination.is_relative_to(ROOT), f"Link leaves repository: {path}: {target}")
            require(destination.exists(), f"Broken local link: {path}: {target}")
        count += 1
    return count


def write_zip(path: Path, files: dict[str, bytes]) -> dict:
    expected = {f"CherrysKit/{name}": data for name, data in sorted(files.items())}
    with ZipFile(path, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in expected.items():
            require(
                not PurePosixPath(name).is_absolute() and ".." not in PurePosixPath(name).parts,
                f"Unsafe archive path: {name}",
            )
            entry = ZipInfo(name, ZIP_TIME)
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            entry.compress_type = ZIP_DEFLATED
            archive.writestr(entry, data, compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(path) as archive:
        require(archive.testzip() is None, f"ZIP integrity check failed: {path.name}")
        require(archive.namelist() == list(expected), f"Archive inventory mismatch: {path.name}")
        for name, data in expected.items():
            require(archive.read(name) == data, f"Archived bytes differ: {path.name}: {name}")
    result = {
        "filename": path.name,
        "bytes": path.stat().st_size,
        "sha256": sha256(path.read_bytes()),
        "file_count": len(expected),
        "files": {name: sha256(data) for name, data in expected.items()},
    }
    print(f"{path.name}: {len(expected)} files, {result['bytes']:,} bytes")
    return result


PRIVATE_DATA_NAMES = frozenset(name.casefold() for name in (
    "SaveVariables.lua", "GlobalBankDatabase.lua", "GlobalBank.json", "ExcludedCharacters.json",
    "DailyRewards.json", "CharacterLinks.json", "GlobalBankHelperBeat.lua",
    "GlobalBankHelper.log", "GlobalBankHelper-errors.log", "AAHBroadCache.json", "AAHBroadCache.lua",
))


def is_private_release_path(path: Path) -> bool:
    name = path.name.casefold()
    return (any(part.casefold() == "globalbankhelper" for part in path.parts)
            or any(name == private or name.startswith(private + ".") for private in PRIVATE_DATA_NAMES))


def build(output: Path) -> None:
    require(not output.is_relative_to(KIT), "Build output must be outside the installed addon tree.")
    metadata = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))
    version = metadata["kit_version"]
    addons = metadata["addons"]
    folders = {addon["folder"] for addon in addons}
    require(len(folders) == len(addons), "Duplicate addon folder in release-packages.json.")
    for name in [version, *folders, *(addon["version"] for addon in addons)]:
        require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name) is not None, f"Unsafe package name: {name}")

    sources = {}
    for path in sorted(KIT.rglob("*")):
        require(not path.is_symlink(), f"Symlinks are not release inputs: {path}")
        if path.is_file():
            require(not is_private_release_path(path.relative_to(KIT)), f"Private game data must not be packaged: {path}")
            sources[path.relative_to(KIT).as_posix()] = path.read_bytes()
    require(sources, "No addon files found.")
    require(
        {path.name for path in KIT.iterdir() if path.is_dir()} == folders | {"KitLoad", "Media", "docs"},
        "Addon directory list differs from release-packages.json.",
    )
    toc = sources["CherrysKit.toc"].decode("utf-8-sig")
    require(
        re.search(rf"(?m)^## Version:\s*{re.escape(version)}\s*$", toc) is not None,
        "Kit version differs between CherrysKit.toc and release-packages.json.",
    )
    references = [
        line.strip().replace("\\", "/")
        for line in toc.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    require(all(ref in sources for ref in references), "The full kit has missing manifest files.")
    require(sources["LICENSE.txt"] == (ROOT / "LICENSE.txt").read_bytes(), "Root licence copy differs.")
    for addon in addons:
        prefix = addon["folder"] + "/"
        require(prefix + "README.md" in sources, f"Missing README for {addon['folder']}.")
        require(
            sources.get(prefix + "LICENSE.txt") == sources["LICENSE.txt"],
            f"Missing or changed combined notices for {addon['folder']}.",
        )
    markdown_count = validate_markdown()

    # Current loader marks and trailing XML call LoadTimes unconditionally.
    # Keep that dependency in the hub without changing the imported runtime.
    hub = {name: data for name, data in sources.items() if name.split("/")[0] not in folders - {"LoadTimes"}}
    modules = {
        addon["folder"]: {
            name: data for name, data in sources.items()
            if name.startswith(addon["folder"] + "/")
        }
        for addon in addons
    }
    combined = dict(hub)
    for folder, files in modules.items():
        overlaps = combined.keys() & files.keys()
        require(
            all(name.startswith("LoadTimes/") and combined[name] == files[name] for name in overlaps),
            f"Unexpected overlap between packages: {folder}",
        )
        combined.update(files)
        selection = hub | files
        missing = [ref for ref in references if ref not in selection]
        require(
            all(ref.split("/")[0] in folders - {"LoadTimes", folder} for ref in missing),
            f"Missing shared files in hub + {folder}.",
        )
    require(combined == sources, "Hub and addon packages do not reconstruct the complete kit.")
    require(all(ref.split("/")[0] in folders - {"LoadTimes"} for ref in references if ref not in hub),
            "Hub is missing required shared files.")

    output.mkdir(parents=True, exist_ok=True)
    packages = []
    for kind, title, package_version, files, bundled in [
        ("Full", "Full kit", version, sources, sorted(folders)),
        ("Hub", "Control hub", version, hub, ["LoadTimes"]),
        *((addon["folder"], addon["title"], addon["version"], modules[addon["folder"]], [addon["folder"]])
          for addon in addons),
    ]:
        result = write_zip(output / f"CherrysKit-{kind}-{package_version}.zip", files)
        result.update({
            "package": kind, "title": title, "version": package_version,
            "requires_hub": kind not in {"Full", "Hub"},
            "bundled_addons": bundled,
        })
        addon = next((item for item in addons if item["folder"] == kind), None)
        if addon and addon.get("minimum_hub_version"):
            result["minimum_hub_version"] = addon["minimum_hub_version"]
        packages.append(result)
    require(len(packages) == 16, "Expected a full kit, a hub, and fourteen addon ZIPs.")
    # The optional browser extension is separate: including it in Global Bank
    # would change the bytes of that unchanged addon's published archive.
    extension_root = ROOT / "extras" / "GlobalBankDailyRewards"
    extension_manifest = json.loads((extension_root / "GlobalBank/Helper/ChromeExtension/manifest.json").read_text(encoding="utf-8"))
    extension_version = extension_manifest["version"]
    require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", extension_version) is not None, "Unsafe extension version.")
    extension_files = {}
    for path in sorted((extension_root / "GlobalBank").rglob("*")):
        require(not path.is_symlink(), f"Symlinks are not release inputs: {path}")
        if path.is_file():
            relative = path.relative_to(extension_root)
            require(not is_private_release_path(relative), f"Private game data must not be packaged: {path}")
            extension_files[relative.as_posix()] = path.read_bytes()
    require(extension_files, "Missing Global Bank browser extension files.")
    extension = write_zip(output / f"CherrysKit-GlobalBankDailyRewards-{extension_version}.zip", extension_files)
    extension.update({"package": "GlobalBankDailyRewards", "title": "Global Bank Daily Rewards (Chrome)",
                      "version": extension_version, "requires_hub": True,
                      "requires_addon": "GlobalBank", "bundled_addons": []})
    packages.append(extension)
    revision = git_output("rev-parse", "HEAD")
    status = git_output("status", "--porcelain")
    manifest = {
        "kit_version": version,
        "hub_version": metadata["hub_version"],
        "source_commit": revision,
        "source_dirty": bool(status),
        "extract_into": "<Runes of Magic>/Interface/AddOns/",
        "archive_root": "CherrysKit/",
        "hub_bundles_loadtimes": True,
        "manifest_entries_checked": len(references),
        "markdown_files_checked": markdown_count,
        "runtime_validation": metadata["runtime_validation"],
        "optional_install_note": (
            "The shared manifest lists all addon files. Hub-only and partial installs "
            "omit unselected module paths; client behaviour for these selections needs "
            "in-game verification. The full kit contains every manifest file."
        ),
        "packages": packages,
    }
    manifest_path = output / "release-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    sums = [f"{package['sha256']}  {package['filename']}" for package in packages]
    sums.append(f"{sha256(manifest_path.read_bytes())}  {manifest_path.name}")
    (output / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="ascii", newline="\n")

    release_url = f"https://github.com/Cherrybooze/Cherrys-Kit/releases/download/v{version}"
    tick = chr(96)
    rwa = next((item for item in addons if item["folder"] == "RomWeakAuras"), {})
    hub_note = (
        f"**Updating RWA separately? Update the hub too.** RWA {rwa.get('version')} "
        f"needs hub {rwa['minimum_hub_version']} or later to load its modules. "
        "The Full ZIP already includes both."
        if rwa.get("minimum_hub_version") else ""
    )
    notes = [
        f"# Cherry's Kit {version}", "",
        f"## [Download the full kit — install ZIP]({release_url}/CherrysKit-Full-{version}.zip)", "",
        f"**Extract this ZIP straight into your game's {tick}Interface/AddOns/{tick} folder.** "
        f"It creates {tick}CherrysKit/CherrysKit.toc{tick}; start the game or Reload UI and type {tick}/ck{tick}.", "",
        "> **Use the install ZIP above.** GitHub's green **Code → Download ZIP** button and "
        "**Source code (zip)** links download the repository with an extra wrapper folder.", "",
        metadata["release_summary"], "",
        "## Install", "",
        f"Choose **Full** for the addons, or **Hub** plus the addon ZIPs you want. "
        f"Extract into {tick}Interface/AddOns/{tick}, merging the {tick}CherrysKit/{tick} folders. "
        f"Remove old separate copies, start the game or Reload UI, and type {tick}/ck{tick}.", "",
        "The hub includes Addon LoadTimes because the shared loader needs its hooks. "
        "The separate LoadTimes ZIP updates those same files. Other individual ZIPs require the hub.", "",
        hub_note, "",
        "The optional Chrome extension is a separate ZIP; see its included installation instructions.", "",
        "## Downloads", "",
        "| Package | Version | ZIP |", "| --- | --- | --- |",
    ]
    for package in packages:
        filename = package["filename"]
        notes.append(f"| {package['title']} | {package['version']} | [{filename}]({release_url}/{filename}) |")
    notes += [
        "", "## Checks and current limits", "",
        f"- ZIP integrity and every archived file verified against source; "
        f"hub + addons reconstruct the full kit.",
        f"- All {len(references)} full-kit manifest references and local documentation links checked.",
        "- Per-file and per-asset SHA-256 hashes are supplied in the release manifest and SHA256SUMS.txt.",
        "- These are offline packaging checks. No new in-game validation is claimed. "
        "The shared manifest still names absent modules in partial installations; "
        "hub-only and hub-plus-addon installs need verification in the actual client.",
        f"- Runtime validation: {metadata['runtime_validation']}",
        "- Existing feature-testing notes remain in each addon's README.",
        "", "## Support and contributions", "",
        "This is a personal hobby project with best-effort support and PR reviews. "
        "Feel free to tweak it; if you fix something broken, open a focused PR and "
        "ideally DM cherry on the Runes of Magic Discord too.",
        "", f"Source commit: {tick}{revision or 'unavailable'}{tick}. "
        f"See the [project README](https://github.com/Cherrybooze/Cherrys-Kit#readme) for all addon guides and credits.",
    ]
    (output / "RELEASE_NOTES.md").write_text("\n".join(notes) + "\n", encoding="utf-8", newline="\n")
    print(f"Verified {len(packages)} ZIPs, {len(references)} manifest entries, and {markdown_count} Markdown files.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    version = json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))["kit_version"]
    build((args.output or ROOT / "dist" / version).resolve())


if __name__ == "__main__":
    main()
