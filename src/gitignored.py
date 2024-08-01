"""
A script to list git-ignored files in a given directory.

This script provides functionality to list and print git-ignored files
in a specified directory, handling various scenarios such as nested
git repositories and subdirectories of git repositories.
"""

from __future__ import annotations

import argparse
import logging
import os
import subprocess
import sys
from itertools import chain
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from typing import Iterable, Literal

try:
    from coloredlogs import ColoredFormatter as Formatter
except ImportError:
    from logging import Formatter

# Set up logging
logger = logging.getLogger("gitignored")
handler = logging.StreamHandler()
handler.setFormatter(Formatter("%(name)s %(levelname)s: %(message)s"))
logger.addHandler(handler)
logger.setLevel(logging.DEBUG)
logger.propagate = False


def git_status_ignored(
    directory: Path,
    *,
    version: Literal[1, 2] = 1,
    expand_directory: bool = False,
) -> Iterable[str]:
    """
    Get all git-ignored files under the given directory.

    Args:
        directory (Path): The directory to search for git-ignored files. This must be the root of a git repository.
        version (Literal[1, 2]): The version of git status porcelain format to use (1 or 2).
        expand_directory (bool): Whether to list files in git-ignored directories.

    Returns:
        Iterable[str]: A generator of relative paths to git-ignored files.
    """
    ignored_prefix = "!! " if version == 1 else "! "
    n = 4 - version

    command = [
        "git",
        "status",
        ".",
        "--ignored",
        "--ignore-submodules=all",
        "--no-renames",
        f"--porcelain={version}",
        "-z",
    ]
    if expand_directory:
        command.append("--untracked-files=all")
    try:
        logger.debug("Running command: %s", subprocess.list2cmdline(command))
        result = subprocess.run(
            command,
            cwd=directory,
            capture_output=True,
            text=True,
            check=True,
        )
        stdout = result.stdout
    except subprocess.CalledProcessError as e:
        logger.info("%s: %s", directory, e.stderr)
        return []
    return (line[n:] for line in stdout.split("\0") if line.startswith(ignored_prefix))


def _find_git_root(directory: Path) -> Path | None:
    """
    Find the root directory of the git repository.

    Args:
        directory (Path): The absolute path to start searching from.

    Returns:
        Path | None: The root directory of the git repository, or None if not found.
    """
    while not (directory / ".git").exists():
        logger.debug("Recursing from directory: %s", directory)
        parent = directory.parent
        # either / or .
        if parent == directory:
            return None
        directory = parent
    return directory


def _find_relative_to_git_root(directory: Path) -> Path | None:
    """
    Express directory relative to the root git repository.

    Args:
        directory (Path): The directory to start searching from.

    Returns:
        Path | None: The directory relative to the root git repository, or None if not found.
    """
    directory = directory.resolve()
    res = Path("")
    while not (directory / ".git").exists():
        logger.debug("Recursing from directory: %s", directory)
        parent = directory.parent
        # either / or .
        if parent == directory:
            return None
        res = directory.name / res
        directory = parent
    return res


def git_subdir_get_ignored_files(
    directory: Path,
    *,
    version: Literal[1, 2] = 1,
    expand_directory: bool = False,
) -> Iterable[Path]:
    """
    Get all git-ignored files under the given directory, which is a subdirectory of a git repository.

    Args:
        directory (Path): The directory to search for git-ignored files.
        version (Literal[1, 2]): The version of git status porcelain format to use (1 or 2).
        expand_directory (bool): Whether to list files in git-ignored directories.

    Returns:
        Iterable[Path]: A generator of paths to git-ignored files.
    """
    if directory.is_absolute():
        git_root = _find_git_root(directory)
        if git_root is None:
            return []
        paths = git_status_ignored(
            directory,
            version=version,
            expand_directory=expand_directory,
        )
        res = (git_root / path for path in paths)
    else:
        relative_to_git_root = f"{_find_relative_to_git_root(directory)}/"
        if relative_to_git_root is None:
            return []
        paths = git_status_ignored(
            directory,
            version=version,
            expand_directory=expand_directory,
        )
        # because git status . is used, path must starts with the relative_to_git_root
        res = (directory / path.removeprefix(relative_to_git_root) for path in paths)
    return res


def git_dir_get_ignored_files(
    directory: Path,
    *,
    version: Literal[1, 2] = 1,
    expand_directory: bool = False,
) -> Iterable[Path]:
    """
    Get all git-ignored files under the given directory, which is a git repository.

    Args:
        directory (Path): The directory to search for git-ignored files.
        version (Literal[1, 2]): The version of git status porcelain format to use (1 or 2).
        expand_directory (bool): Whether to list files in git-ignored directories.

    Returns:
        Iterable[Path]: A generator of paths to git-ignored files.
    """
    paths = git_status_ignored(
        directory,
        version=version,
        expand_directory=expand_directory,
    )
    return (directory / path for path in paths)


def get_ignored_files(
    directory: Path,
    *,
    version: Literal[1, 2] = 1,
    expand_directory: bool = False,
) -> Iterable[Path]:
    """
    List all git-ignored files under the given directory.

    This function handles both directories containing git repositories
    and subdirectories of git repositories.

    Args:
        directory (Path): The directory to search for git-ignored files.
        version (Literal[1, 2]): The version of git status porcelain format to use.
        expand_directory (bool): Whether to list files in git-ignored directories.

    Returns:
        Iterable[Path]: A generator of paths to git-ignored files.
    """
    # TODO: py312+: glob(..., case_sensitive=True)
    res = (
        git_dir_get_ignored_files(
            git_dir.parent,
            version=version,
            expand_directory=expand_directory,
        )
        for git_dir in directory.glob("**/.git")
    )
    # If directory is not a git repo, it might be a subdirectory of a git repo.
    return (
        chain(*res)
        if (directory / ".git").exists()
        else chain(
            git_subdir_get_ignored_files(
                directory,
                version=version,
                expand_directory=expand_directory,
            ),
            *res,
        )
    )


def format_path(path: Path) -> str:
    """
    Format a path, appending a slash if it's a directory.

    Args:
        path (Path): The path to format.

    Returns:
        str: The formatted path.
    """
    res = str(path)
    if path.is_dir():
        res += os.path.sep
    return res


def print_ignored_files(
    directory: Path,
    *,
    version: Literal[1, 2] = 1,
    expand_directory: bool = False,
    debug: bool = False,
) -> None:
    """
    Print all git-ignored files under the given directory.

    Args:
        directory (Path): The directory to search for git-ignored files.
        version (Literal[1, 2]): The version of git status porcelain format to use.
        expand_directory (bool): Whether to list files in git-ignored directories.
        debug (bool): Whether to verify path existence and print to stderr if not found.
    """
    paths: list[str] = sorted(
        map(
            format_path,
            get_ignored_files(
                directory,
                version=version,
                expand_directory=expand_directory,
            ),
        )
    )
    if debug:
        for path_str in paths:
            # double conversion. We don't care about the performance when debugging.
            path = Path(path_str)
            # TODO: py312+: if path.exists(follow_symlinks=False):
            if path.is_symlink() or path.exists():
                print(path_str)
            else:
                print(path_str, file=sys.stderr)
    else:
        for path_str in paths:
            print(path_str)


def main() -> None:
    """
    Parse command-line arguments and execute the main script functionality.
    """
    parser = argparse.ArgumentParser(
        description="List all git-ignored files under the given directory."
    )
    parser.add_argument(
        "directory",
        type=Path,
        nargs="?",
        default=Path("."),
        help="The directory to list git-ignored files. Default is the current directory.",
    )
    parser.add_argument(
        "-v",
        "--version",
        type=int,
        default=1,
        choices=[1, 2],
        help="The version of the git status --porcelain format to use.",
    )
    parser.add_argument(
        "-e",
        "--expand-directory",
        action="store_true",
        help="List files in a git-ignored directory. If not specified, only the directory itself is listed.",
    )
    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        help="Verify paths exist, print to stderr if not.",
    )

    args = parser.parse_args()
    print_ignored_files(
        args.directory,
        version=args.version,
        expand_directory=args.expand_directory,
        debug=args.debug,
    )


if __name__ == "__main__":
    main()
