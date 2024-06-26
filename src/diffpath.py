#!/usr/bin/env python

from __future__ import annotations

import os
import sys


def get_executables(path: str) -> set[str]:
    return {
        file
        for dir in path.split(":")
        if os.path.isdir(dir)
        for file in os.listdir(dir)
        if os.path.isfile(file_path := os.path.join(dir, file))
        and os.access(file_path, os.X_OK)
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


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} PATH1 PATH2")
        sys.exit(1)
    diffpath(sys.argv[1], sys.argv[2])
