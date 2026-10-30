#!/usr/bin/env python3
"""Puts each package's requirements at the very front of its CurseForge description.

The requirements live in release-packages.json. This rewrites the first lines of every numbered page in
docs/curseforge, the same lines in descriptions.md, and the project table in docs/curseforge/README.md.

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
    lines = [line, ">"]
    if package.get("works_with"):
        optional = [f"{names[item['package']]} ({item['for']})" for item in package["works_with"]]
        lines.append(f"> **Optional, when you have them:** {join_names(optional)}.")
    else:
        lines.append("> **Optional:** nothing else is needed.")
    if package.get("after_install"):
        lines += [">", f"> **After installing:** {package['after_install']}"]
    return "\n".join(lines)


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
    return files


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = [path for path, text in updated_files().items() if path.read_text(encoding="utf-8") != text]
    if args.check:
        for path in stale:
            print(f"Out of date: {path.relative_to(ROOT)}")
        sys.exit(1 if stale else 0)
    for path, text in updated_files().items():
        path.write_text(text, encoding="utf-8", newline="\n")
    print(f"Rewrote {len(stale)} files.")


if __name__ == "__main__":
    main()
