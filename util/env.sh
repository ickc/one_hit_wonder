#!/usr/bin/env bash

set -e

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
        get_command_path PYPY envs/pypy pypy3
        get_command_path RUSTFMT envs/rust rustfmt
        get_command_path RUSTC envs/rust rustc
        get_command_path SHFMT envs/bash shfmt
        get_command_path BASH envs/bash bash
        get_command_path NODE envs/typescript node
        get_command_path NPM envs/typescript npm
        get_command_path PRETTIER envs/typescript prettier
        get_command_path TSC envs/typescript tsc
        get_command_path PERL envs/perl perl
        get_command_path PERLTIDY envs/perl perltidy
        get_command_path DOTNET envs/dotnet dotnet

        get_command_path HYPERFINE envs/system hyperfine
        get_command_path DIFFT envs/system difft
        get_command_path GNUTIME envs/system time

        get_command_path CYTHONIZE envs/cython cythonize
        get_command_path CYTHON_PYTHON envs/cython python

        get_command_path NUITKA_PYTHON envs/nuitka python
        get_env_var NUITKA_PYTHONPATH envs/nuitka PYTHONPATH
        ;;
    *) ;;
esac

# Optional, OS specific commands #######################################

case "$(uname -s)" in
    Darwin)
        echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        echo 'PYTHON_SYSTEM=/usr/bin/python3' >> "${outfile}"
        echo 'BASH_SYSTEM=/bin/bash' >> "${outfile}"
        echo 'PERL_SYSTEM=/usr/bin/perl' >> "${outfile}"

        # Get the macOS version number
        macos_version=$(sw_vers -productVersion | awk -F '.' '{print $1}')

        if [[ ${macos_version} -ge 14 ]]; then
            echo 'CLANGXX_SYSTEM=/usr/bin/clang++' >> "${outfile}"
        fi

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
        ;;
    *)
        [[ -e /usr/bin/clang ]] && echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        [[ -e /usr/bin/python3 ]] && echo 'PYTHON_SYSTEM=/usr/bin/python3' >> "${outfile}"
        [[ -e /bin/bash ]] && echo 'BASH_SYSTEM=/bin/bash' >> "${outfile}"
        [[ -e /usr/bin/perl ]] && echo 'PERL_SYSTEM=/usr/bin/perl' >> "${outfile}"

        GCC_MARCH=native
        ;;
esac
echo "GCC_MARCH=${GCC_MARCH}" >> "${outfile}"
