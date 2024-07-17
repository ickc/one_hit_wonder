from __future__ import annotations

import os
import sys


def get_executables(path: str) -> set[str]:
    return {
        entry.name
        for directory in path.split(":")
        if os.path.isdir(directory)
        for entry in os.scandir(directory)
        if entry.is_symlink()
        or (
            entry.is_file()
            and (os.stat(entry.path, follow_symlinks=False).st_mode & 0o111)
        )
    }


def diffpath(
    path1: str,
    path2: str,
) -> None:
    executables1 = get_executables(path1)
    executables2 = get_executables(path2)
    for command in sorted(executables1 ^ executables2):
        if command in executables1:
            print(command)
        else:
            print(f"\t{command}")


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} PATH1 PATH2", file=sys.stderr)
        sys.exit(1)
    diffpath(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()
