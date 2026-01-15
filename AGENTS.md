# Instructions for Agents

This repository is a complex, polyglot experiment involving many languages and a specific build system. Please read this document carefully before making changes.

## Context

The goal of this project is to experiment with creating "One Hit Wonder" scripts—single-file executables—across various programming languages. We compare them based on build process, startup time, and binary size.

## Build System

- **`Makefile` is King**: All build logic is centralized in the `Makefile`. Do not introduce other build tools or scripts unless absolutely necessary and approved.
- **`devbox` & `pixi`**: Dependencies are managed via `devbox.json` (Nix) and `pixi.toml` (Conda). Ensure you have these tools available or use the provided environment.
- **Targets**:
    - `make compile`: Builds everything.
    - `make test`: Runs correctness tests.
    - `make format`: Formats code using language-specific formatters.

## coding Conventions

1. **Single File Output**:
    - The end result of a build must be a single executable file in `bin/`.
    - For compiled languages (C, Go, Rust), this is standard.
    - For interpreted languages (Python, Lua, Bash), use the existing patterns in the `Makefile` to create a self-contained script (often using a shebang hack).

2. **Standard Library Preference**:
    - Avoid external dependencies. Rely on the language's standard library as much as possible to keep the single-file distribution simple.
    - If a dependency is unavoidable, it must be managed via `devbox` or `pixi` and available in the build environment.

3. **Shebang Hacks**:
    - Be aware of the shebang hacks used in `Makefile`. For example, Lua and Python scripts are often prefixed with a specific shebang line during the build process to point to the correct interpreter version managed by devbox/pixi.

4. **Formatting**:
    - Run `make format` before submitting changes. Each language has a configured formatter (e.g., `clang-format`, `black`, `gofmt`).

## Workflow

1. **Explore First**:
    - Check `src/` to see existing implementations of `diffpath` and `gitignored`.
    - Read the `Makefile` to understand how a specific language is built.

2. **Implement**:
    - Add your source file to `src/`.
    - Update `Makefile` if you are adding a new language or a new variation of an existing language build.

3. **Verify**:
    - Run `make compile` to ensure it builds.
    - Run `make test` to verify correctness.
    - Run `make format` to clean up code.
