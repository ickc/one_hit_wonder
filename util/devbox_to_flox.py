#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path

def parse_devbox_json(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8") as file:
        content = file.read()
        # Remove comments
        content = re.sub(r"^\s*//.*$", "", content, flags=re.MULTILINE)
        data = json.loads(content)
        return data.get("packages", [])

def convert_to_flox(packages: list[str]) -> str:
    lines = []
    lines.append("version = 1")
    lines.append("")
    lines.append("[install]")

    for pkg in packages:
        # Remove version suffix like @latest, @1.2.3
        # flox might support version pinning differently, but for now we map pkg to pkg
        # assuming the package name in devbox (nixpkgs) is the same in flox (nixpkgs)

        # Split by @, take the first part
        pkg_name = pkg.split("@")[0]

        # Handle some edge cases or just simple mapping
        # flox manifest syntax: name = { pkg-path = "name" }
        lines.append(f'{pkg_name.replace(".", "-")} = {{ pkg-path = "{pkg_name}" }}')

    return "\n".join(lines)

def main() -> None:
    parser = argparse.ArgumentParser(description="Convert devbox.json to flox manifest.toml")
    parser.add_argument(
        "file", metavar="FILE", type=Path, help="devbox.json file"
    )

    args = parser.parse_args()
    packages = parse_devbox_json(args.file)
    manifest = convert_to_flox(packages)
    print(manifest)

if __name__ == "__main__":
    main()
