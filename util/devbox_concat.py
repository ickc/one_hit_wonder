#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# Compile the regular expression for removing comments


def remove_comments(
    text: str,
    regex=re.compile(r"^\s*//.*$", re.MULTILINE),
) -> str:
    """Remove comments from JSON content."""
    return regex.sub("", text)


def merge_data(data: list) -> dict:
    result = {}
    for item in data:
        for key, value in item.items():
            if key in result:
                if isinstance(result[key], list):
                    result[key] += value
                else:
                    assert result[key] == value
            else:
                result[key] = value
    result = {
        k: sorted(set(v)) if isinstance(v, list) else v
        for k, v in sorted(result.items())
    }
    return result


def concat(paths: list[Path]) -> None:
    data: list = []
    for path in paths:
        with path.open("r", encoding="utf-8") as file:
            data.append(json.loads(remove_comments(file.read())))
    result = merge_data(data)
    print(json.dumps(result, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge devbox JSON files")
    parser.add_argument(
        "files", metavar="FILE", type=Path, nargs="+", help="JSON files to merge"
    )

    args = parser.parse_args()
    concat(args.files)


if __name__ == "__main__":
    main()
