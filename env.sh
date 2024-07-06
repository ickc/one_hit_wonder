#!/usr/bin/env bash

# Check if 'nix' command is available
# TODO: port to non-nix system when needed
if ! command -v nix &> /dev/null; then
    echo "nix command not found. Please install Nix to proceed."
    exit 1
fi

# Check number of arguments
if [[ $# != 1 ]]; then
    echo "Usage: $0 <outfile>"
    exit 1
fi

outfile="$1"
export outfile
: > "${outfile}"

# Define function to get command path and write to outfile
get_command_path() {
    local var_name=$1
    local env_dir=$2
    local command_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\$(command -v ${command_name})\" >> ../../${outfile}"
}
get_env_var() {
    local var_name=$1
    local env_dir=$2
    local original_var_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\${${original_var_name}}\" >> ../../${outfile}"
}

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

# OS specific settings
case "$(uname -s)" in
    Darwin)
        echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        echo 'CLANGXX_SYSTEM=/usr/bin/clang++' >> "${outfile}"
        ;;
    *) ;;
esac
