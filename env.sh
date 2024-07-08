#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Check number of arguments
if [[ $# != 1 ]]; then
    echo "Usage: $0 <outfile>"
    exit 1
fi
outfile="$1"

if command -v devbox &> /dev/null; then
    METHOD=devbox
else
    echo "devbox command not found. Please install Nix and devbox to proceed."
    exit 1
fi

: > "${outfile}"

get_command_path() {
    local var_name=$1
    local env_dir=$2
    local command_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\$(type -P ${command_name})\" >> ../../${outfile}"
}

get_env_var() {
    local var_name=$1
    local env_dir=$2
    local original_var_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\${${original_var_name}}\" >> ../../${outfile}"
}

# get mandatory commands ###############################################

case "${METHOD}" in
    devbox)
        # Get command paths and write to outfile
        get_command_path CLANG_FORMAT envs/clang clang-format
        get_command_path GCC envs/gcc gcc
        get_command_path GXX envs/gcc g++
        get_command_path CLANG envs/clang clang
        get_command_path CLANGXX envs/clang clang++
        get_command_path GOFMT envs/go gofmt
        get_command_path GO envs/go go
        get_command_path STYLISH_HASKELL envs/ghc stylish-haskell
        get_command_path GHC envs/ghc ghc
        get_command_path STYLUA envs/lua stylua
        get_command_path LUA envs/lua lua
        get_env_var LUA_LUA_CPATH envs/lua LUA_CPATH
        get_command_path LUAJIT envs/luajit luajit
        get_env_var LUAJIT_LUA_CPATH envs/luajit LUA_CPATH
        get_command_path AUTOFLAKE envs/python autoflake
        get_command_path BLACK envs/python black
        get_command_path ISORT envs/python isort
        get_command_path PYTHON envs/python python
        get_command_path RUSTFMT envs/rust rustfmt
        get_command_path RUSTC envs/rust rustc
        get_command_path SHFMT envs/bash shfmt
        get_command_path BASH envs/bash bash
        get_command_path NODE envs/typescript node
        get_command_path NPM envs/typescript npm
        get_command_path PRETTIER envs/typescript prettier
        get_command_path TSC envs/typescript tsc

        get_command_path HYPERFINE envs/system hyperfine
        get_command_path DIFFT envs/system difft
        get_command_path GNUTIME envs/system time
        ;;
    *) ;;
esac

# Optional, OS specific commands #######################################

case "$(uname -s)" in
    Darwin)
        echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        echo 'CLANGXX_SYSTEM=/usr/bin/clang++' >> "${outfile}"

        case "$(uname -m)" in
            arm64)
                cpu_info=$(sysctl -n machdep.cpu.brand_string)
                case "${cpu_info}" in
                    "Apple M1"*)
                        GCC_MARCH="armv8.5-a"
                        ;;
                    "Apple M2"* | "Apple M3"*)
                        GCC_MARCH="armv8.6-a"
                        ;;
                    # Apple M4 or above
                    *)
                        GCC_MARCH="armv9-a"
                        ;;
                esac
                ;;
            *)
                GCC_MARCH=native
                ;;
        esac

        case "$(sw_vers -productVersion)" in
            13.*)
                CLANGXX_SYSTEM_STD=c++17
                ;;
            *)
                CLANGXX_SYSTEM_STD=c++20
                ;;
        esac

        echo "CLANGXX_SYSTEM_STD=${CLANGXX_SYSTEM_STD}" >> "${outfile}"
        ;;
    *)
        GCC_MARCH=native
        ;;
esac
echo "GCC_MARCH=${GCC_MARCH}" >> "${outfile}"
