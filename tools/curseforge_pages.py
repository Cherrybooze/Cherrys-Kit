#!/usr/bin/env python3
"""Puts each package's requirements at the very front of its CurseForge description.

The requirements, links between addons and original addons live in release-packages.json. This rewrites the
first lines of every numbered page in docs/curseforge, the same lines in descriptions.md and each addon's README,
the project table in docs/curseforge/README.md, docs/ADDON_MAP.md, and the hub's KitOrigins.lua.

    python tools/curseforge_pages.py            rewrite them
    python tools/curseforge_pages.py --check    only report what is out of date
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PAGES = ROOT / "docs" / "curseforge"
HUB = "Cherry's Kit"
TABLE_START = "<!-- project table: tools/curseforge_pages.py writes this -->"
TABLE_END = "<!-- end of project table -->"
README_START = "<!-- requirements: tools/curseforge_pages.py writes this -->"
README_END = "<!-- end of requirements -->"
ADDONS = ROOT / "Interface" / "AddOns"
KIT = ADDONS / "CherrysKit"
ORIGINS_FILE = KIT / "KitOrigins.lua"
MAP_FILE = ROOT / "docs" / "ADDON_MAP.md"


def metadata() -> dict:
    return json.loads((ROOT / "release-packages.json").read_text(encoding="utf-8"))


def packages(data: dict | None = None) -> list[dict]:
    """The hub, then every addon, then the packages with folders of their own."""
    data = data or metadata()
    hub = {"id": "hub", "title": HUB, "description_file": data["hub_description_file"], "kind": "hub",
           "zip": "CherrysKit-Hub-<kit version>.zip"}
    addons = [{**addon, "id": addon["folder"], "kind": "addon",
               "zip": f"CherrysKit-{addon['folder']}-<version>.zip"} for addon in data["addons"]]
    standalone = [{**package, "id": package["folder"], "kind": "standalone",
                   "zip": f"{package['folder']}-<version>.zip"} for package in data["standalone_packages"]]
    return [hub, *addons, *standalone]


def titles(all_packages: list[dict]) -> dict[str, str]:
    return {package["id"]: package["title"] for package in all_packages}


def required(package: dict, names: dict[str, str]) -> list[str]:
    if package["kind"] == "hub":
        return []
    hub = HUB
    if package.get("minimum_hub_version"):
        hub += f" (hub {package['minimum_hub_version']} or later)"
    return [hub, *(names[other] for other in package.get("requires", []))]


def join_names(items: list[str]) -> str:
    if len(items) < 2:
        return "".join(items)
    return ", ".join(items[:-1]) + " and " + items[-1]


def front_block(package: dict, names: dict[str, str]) -> str:
    """The lines a description starts with, right under its title."""
    if package["kind"] == "hub":
        return "> **Requires:** nothing. This is the base package: every other Cherry's Kit addon needs it."
    needs = required(package, names)
    it = "them" if len(needs) > 1 else "it"
    line = f"> **Requires:** {join_names(needs)}. The CurseForge app installs {it} for you; if you install by hand, install {it} first."
    if package["kind"] == "addon":
        line += " This addon can't load without the hub."
    lines = [line, ">", f"> **Where it goes:** `{install_path(package)}`. The hub loads it from there, and it won't load from anywhere else.", ">"]
    if package.get("works_with"):
        lines.append("> **On its own:** it runs with just the hub. Only the parts listed here need another addon, and without that addon they're simply missing:")
        lines += [f"> - **{names[item['package']]}:** {item['for']}" for item in package["works_with"]]
    else:
        lines.append("> **On its own:** it runs with just the hub, and nothing it does needs another addon.")
    lines += [">", f"> {origin_text(package['origin'])}"]
    for text in package.get("also", []):
        lines += [">", f"> **Other addons:** {text}"]
    if package.get("after_install"):
        lines += [">", f"> **After installing:** {package['after_install']}"]
    return "\n".join(lines)


def install_folder(package: dict) -> str:
    return package.get("install_folder", package["folder"])


def install_path(package: dict) -> str:
    return "Interface\\AddOns\\CherrysKit\\" + install_folder(package)


def origin_text(origin: dict) -> str:
    """What happens when the addon this came from, or an older copy of this one, is installed too."""
    where = f"`Interface\\AddOns\\{origin['folder']}`"
    off = "this version stays off, and the hub says so in chat and in its window. Delete that folder and Reload UI to use this one."
    if origin["kind"] == "older":
        text = f"**Older copy:** this addon has no original to give way to, but if {where} from an earlier release is still there, it takes precedence: {off}"
    else:
        text = f"**Original addon:** {origin['name']} by {origin['by']}. If {where} is still there, it takes precedence: {off}"
    if origin.get("note"):
        text += " " + origin["note"]
    return text


def lua_text(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def origins_lua(all_packages: list[dict]) -> str:
    rows = ["-- Written by tools/curseforge_pages.py from release-packages.json: the addon each kit addon came from,",
            "-- where it would be, and how to spot it. See CherrysKit.lua, \"Original addons\".",
            "CherrysKit_Origins = {"]
    for package in all_packages:
        origin = package.get("origin")
        if not origin:
            continue
        parts = [f"title = {lua_text(package['title'])}", f"kind = {lua_text(origin['kind'])}"]
        if origin.get("name"):
            parts.append(f"name = {lua_text(origin['name'])}")
        parts.append(f"folder = {lua_text(origin['folder'])}")
        parts.append("files = { " + ", ".join(lua_text(item) for item in origin["files"]) + " }")
        if origin.get("fingerprint"):
            parts.append(f"fingerprint = {lua_text(origin['fingerprint'])}")
        parts.append(f"kit_file = {lua_text(package['kit_file'])}")
        rows.append(f"  {package.get('hub_key', package['folder'])} = {{ {', '.join(parts)} }},")
    rows.append("}")
    return "\n".join(rows) + "\n"


def addon_map(all_packages: list[dict], names: dict[str, str]) -> str:
    rows = ["# Addon map", "",
            "Written by `tools/curseforge_pages.py` from `release-packages.json`. Run it after changing that file.", "",
            "Every addon needs the hub and lives under `Interface\\AddOns\\CherrysKit`, because the hub's manifest is what loads it. "
            "Each one runs with only the hub: what's listed under **Works with** is missing until you add that addon, and nothing else is. "
            "`tests/test_addons_alone.py` runs each one that way on a simulated client, and `tests/test_addon_map.py` fails if an addon reaches for another one that isn't listed here.", "",
            "If an addon's original, or an older separate copy, is in its own folder in `Interface\\AddOns`, that one takes precedence: "
            "the kit's version stays off and the hub says so, one line for each, in chat and in its window. Both still load, because the game can't skip a file in a manifest.", "",
            "| Addon | Installed at | Works with | Takes precedence if present |", "| --- | --- | --- | --- |"]
    for package in all_packages:
        if package["kind"] == "hub":
            continue
        partners = ", ".join(names[item["package"]] for item in package.get("works_with", [])) or "nothing"
        origin = package["origin"]
        who = f"{origin['name']} by {origin['by']}" if origin["kind"] == "original" else "an older copy"
        rows.append(f"| {package['title']} | `CherrysKit\\{install_folder(package)}` | {partners} | `AddOns\\{origin['folder']}`, {who} |")
    rows += ["", "## What each link does", ""]
    for package in all_packages:
        if package["kind"] == "hub":
            continue
        rows.append(f"### {package['title']}")
        rows.append("")
        if package.get("works_with"):
            rows += [f"- **{names[item['package']]}:** {item['for']}" for item in package["works_with"]]
        else:
            rows.append("- No links to other addons.")
        rows += [f"- **Other addons:** {text}" for text in package.get("also", [])]
        if package["origin"].get("note"):
            rows.append(f"- **Note:** {package['origin']['note']}")
        rows.append("")
    return "\n".join(rows).rstrip() + "\n"


def with_readme_block(text: str, block: str) -> str:
    """The README with block in front of its first section, replacing the block already there."""
    wrapped = f"{README_START}\n\n{block}\n\n{README_END}\n\n"
    if README_START in text:
        start, end = text.index(README_START), text.index(README_END) + len(README_END)
        return text[:start] + wrapped.rstrip("\n") + text[end:]
    match = re.search(r"(?m)^## ", text)
    at = match.start() if match else len(text)
    return text[:at] + wrapped + text[at:]


def readme_of(package: dict) -> Path:
    if package["kind"] == "addon":
        return KIT / package["folder"] / "README.md"
    return ADDONS / install_folder(package) / "README.md"


def read_keeping(path: Path) -> str:
    return path.read_bytes().decode("utf-8").replace("\r\n", "\n")


def with_block(page: str, block: str) -> str:
    """The page with block as the first thing after its title, replacing the block already there."""
    match = re.match(r"\s*(# [^\n]+\n)\s*((?:>[^\n]*\n)*)\s*", page)
    if not match:
        raise ValueError("A description must start with its title: " + page[:60])
    return f"{match.group(1)}\n{block}\n\n{page[match.end():]}"


def project_table(all_packages: list[dict], names: dict[str, str]) -> str:
    rows = ["| Project | Description | ZIP to upload | Required relations | Optional relations |", "| --- | --- | --- | --- | --- |"]
    for package in all_packages:
        needs = [HUB, *(names[other] for other in package.get("requires", []))] if package["kind"] != "hub" else []
        optional = [names[item["package"]] for item in package.get("works_with", [])]
        rows.append(f"| {package['title']} | [{package['description_file']}]({package['description_file']}) | `{package['zip']}` "
                    f"| {', '.join(needs) or 'none'} | {', '.join(optional) or 'none'} |")
    return "\n".join(rows)


def updated_files() -> dict[Path, str]:
    all_packages = packages()
    names = titles(all_packages)
    files = {}
    combined = (PAGES / "descriptions.md").read_text(encoding="utf-8")
    for package in all_packages:
        path = PAGES / package["description_file"]
        block = front_block(package, names)
        files[path] = with_block(path.read_text(encoding="utf-8"), block)
        marker = f"<!-- {package['description_file']} -->"
        if marker not in combined:
            raise ValueError(f"{marker} is missing from descriptions.md")
        before, rest = combined.split(marker, 1)
        following = re.search(r"\n---\n", rest)
        end = following.start() if following else len(rest)
        combined = f"{before}{marker}\n\n{with_block(rest[:end], block).rstrip()}\n{rest[end:]}"
    files[PAGES / "descriptions.md"] = combined
    readme = (PAGES / "README.md").read_text(encoding="utf-8")
    start, end = readme.index(TABLE_START) + len(TABLE_START), readme.index(TABLE_END)
    files[PAGES / "README.md"] = f"{readme[:start]}\n{project_table(all_packages, names)}\n{readme[end:]}"
    for package in all_packages:
        if package["kind"] != "hub":
            files[readme_of(package)] = with_readme_block(read_keeping(readme_of(package)), front_block(package, names))
    files[ORIGINS_FILE] = origins_lua(all_packages)
    files[MAP_FILE] = addon_map(all_packages, names)
    return files


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = [path for path, text in updated_files().items() if not path.exists() or read_keeping(path) != text]
    if args.check:
        for path in stale:
            print(f"Out of date: {path.relative_to(ROOT)}")
        sys.exit(1 if stale else 0)
    for path, text in updated_files().items():
        crlf = path.exists() and b"\r\n" in path.read_bytes()
        path.write_text(text, encoding="utf-8", newline="\r\n" if crlf else "\n")
    print(f"Rewrote {len(stale)} files.")


if __name__ == "__main__":
    main()
