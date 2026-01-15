# One Hit Wonder

## Overview

This repository is an experimental playground for creating self-contained, single-file executables ("One Hit Wonders") across a wide variety of programming languages. The goal is to compare how different languages, compilers, and interpreters handle building standalone utilities, with a focus on startup time, binary size, and ease of distribution.

## Key Concepts

- **Single Binary**: The output for each program in each language should ideally be a single file that can be executed directly.
- **Shebang Hacks**: For interpreted languages (Python, Lua, etc.), the build system often uses "shebang hacks" to concatenate the interpreter invocation and the source code into a single executable script.
- **Standard Library**: To keep the "binaries" self-contained, there is a strong preference for using the standard library (`stdlib`) over external dependencies.
- **Polyglot**: implementations exist for C, C++, C#, Go, Haskell, Java, Julia, Lua, Objective-C, Perl, Python (CPython, PyPy, Cython, Nuitka), Rust, Bash, Zsh, and TypeScript.

## Programs

The repository currently implements the following utilities:

- **`diffpath`**: A tool to compare two `PATH`-like environment strings (colon-separated directories) and list the executable files that differ between them. See `src/diffpath.md` for the specification.
- **`gitignored`**: A tool to list files that are ignored by git.

## Build System

The build system is orchestrated by a `Makefile` and uses `devbox` (Nix) and `pixi` (Conda/Mamba) to manage the massive array of compilers and interpreters required.

### Prerequisites

- [Devbox](https://www.jetify.com/devbox)
- [Pixi](https://prefix.dev/)

### Usage

- **Build everything**:
  ```bash
  make compile
  ```
  This will compile/generate all binaries into the `bin/` directory.

- **Run benchmarks**:
  ```bash
  make bench
  ```
  This uses `hyperfine` to benchmark the generated binaries. Results are stored in `out/`.

- **Run tests**:
  ```bash
  make test
  ```
  This verifies the correctness of the generated programs against a reference implementation.

- **Clean up**:
  ```bash
  make clean
  ```

- **Format code**:
  ```bash
  make format
  ```

- **Check compiler versions**:
  ```bash
  make compiler_version
  ```

## Directory Structure

- `src/`: Source code for all programs in all languages.
- `bin/`: Generated executables (git-ignored).
- `envs/`: Environment definitions for devbox.
- `util/`: Utility scripts for the build process.
- `out/`: Benchmark results and logs (git-ignored).
