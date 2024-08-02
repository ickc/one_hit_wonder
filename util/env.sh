#!/usr/bin/env bash

# shellcheck disable=SC2312

set -e

# valid values for METHOD are devbox
METHOD="${METHOD:-devbox}"
# valid values for PYTHON_METHOD are devbox, pixi
PYTHON_METHOD="${PYTHON_METHOD:-pixi}"

# shellcheck disable=SC2046
DIR="$(cd "$(dirname $(dirname "${BASH_SOURCE[0]}"))" && pwd)"

# Check number of arguments
if [[ $# != 1 ]]; then
    echo "Usage: $0 <outfile>"
    exit 1
fi
outfile="$1"

case "${METHOD}" in
    devbox)
        if ! command -v devbox &> /dev/null; then
            echo "devbox command not found. Please install Nix and devbox to proceed."
            exit 1
        fi
        ;;
    *)
        echo "Invalid method: ${METHOD}"
        exit 1
        ;;
esac
case "${PYTHON_METHOD}" in
    devbox)
        if ! command -v devbox &> /dev/null; then
            echo "devbox command not found. Please install Nix and devbox to proceed."
            exit 1
        fi
        ;;
    pixi)
        if ! command -v pixi &> /dev/null; then
            echo "pixi command not found. Please install pixi to proceed."
            exit 1
        fi
        ;;
    *)
        echo "Invalid python method: ${PYTHON_METHOD}"
        exit 1
        ;;
esac

get_devbox_command_path() {
    local var_name=$1
    local env_dir=$2
    local command_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\$(type -P ${command_name})\" >> ../../${outfile}"
}

get_devbox_env_var() {
    local var_name=$1
    local env_dir=$2
    local original_var_name=$3
    devbox run --config "${env_dir}" "echo ${var_name}=\"\${${original_var_name}}\" >> ../../${outfile}"
}

get_pixi_command_path() {
    local var_name=$1
    local env_name=$2
    local command_name=$3
    echo "${var_name}=${DIR}/.pixi/envs/${env_name}/bin/${command_name}" >> "${outfile}"
}

get_devbox() {
    get_devbox_command_path CLANG_FORMAT envs/clang clang-format
    get_devbox_command_path GCC envs/gcc gcc
    get_devbox_command_path GXX envs/gcc g++
    get_devbox_command_path CLANG envs/clang clang
    get_devbox_command_path CLANGXX envs/clang clang++
    get_devbox_command_path GOFMT envs/go gofmt
    get_devbox_command_path GO envs/go go
    get_devbox_command_path STYLISH_HASKELL envs/ghc stylish-haskell
    get_devbox_command_path GHC envs/ghc ghc
    get_devbox_command_path STYLUA envs/lua stylua
    get_devbox_command_path LUA envs/lua lua
    get_devbox_env_var LUA_LUA_CPATH envs/lua LUA_CPATH
    get_devbox_command_path LUAJIT envs/luajit luajit
    get_devbox_env_var LUAJIT_LUA_CPATH envs/luajit LUA_CPATH
    get_devbox_command_path PYPY envs/pypy pypy3
    get_devbox_command_path RUSTFMT envs/rust rustfmt
    get_devbox_command_path RUSTC envs/rust rustc
    get_devbox_command_path SHFMT envs/bash shfmt
    get_devbox_command_path BASH envs/bash bash
    get_devbox_command_path ZSH envs/zsh zsh
    get_devbox_command_path NODE envs/typescript node
    get_devbox_command_path NPM envs/typescript npm
    get_devbox_command_path PRETTIER envs/typescript prettier
    get_devbox_command_path TSC envs/typescript tsc
    get_devbox_command_path PERL envs/perl perl
    get_devbox_command_path PERLTIDY envs/perl perltidy
    get_devbox_command_path DOTNET envs/dotnet dotnet
    get_devbox_command_path JULIA envs/julia julia

    get_devbox_command_path JAVA envs/java java
    get_devbox_command_path JAVAC envs/java javac
    get_devbox_command_path JAR envs/java jar
    get_devbox_command_path GOOGLE_JAVA_FORMAT envs/java google-java-format

    get_devbox_command_path HYPERFINE envs/system hyperfine
    get_devbox_command_path DIFFT envs/system difft
    get_devbox_command_path GNUTIME envs/system time
}

get_python_devbox() {
    get_devbox_command_path AUTOFLAKE envs/python autoflake
    get_devbox_command_path BLACK envs/python black
    get_devbox_command_path ISORT envs/python isort
    get_devbox_command_path PYTHON envs/python python

    get_devbox_command_path CYTHONIZE envs/cython cythonize
    get_devbox_command_path CYTHON_PYTHON envs/cython python

    if [[ "$(uname -s)" != Darwin || $(sw_vers -productVersion | awk -F '.' '{print $1}') -ge 14 ]]; then
        get_devbox_command_path NUITKA_PYTHON envs/nuitka python
        get_devbox_env_var NUITKA_PYTHONPATH envs/nuitka PYTHONPATH
    fi
}

get_python_pixi() {
    # not setting up pypy here, as
    # pypy from conda-forge is immature, e.g. as of writting
    # pypy3.10 is not available, and does not support osx-arm64

    get_pixi_command_path AUTOFLAKE python autoflake
    get_pixi_command_path BLACK python black
    get_pixi_command_path ISORT python isort
    get_pixi_command_path PYTHON python python

    get_pixi_command_path CYTHONIZE cython cythonize
    get_pixi_command_path CYTHON_PYTHON cython python

    get_pixi_command_path NUITKA_PYTHON nuitka python
}

# get mandatory commands ###############################################

echo "export JULIA_DEPOT_PATH=${DIR}/envs/julia/.julia" > "${outfile}"

case "${METHOD}" in
    devbox)
        get_devbox
        ;;
    *) ;;
esac
case "${PYTHON_METHOD}" in
    devbox)
        get_python_devbox
        ;;
    pixi)
        get_python_pixi
        ;;
    *) ;;
esac

# Optional, OS specific commands #######################################

case "$(uname -s)" in
    Darwin)
        echo 'BASH_SYSTEM=/bin/bash' >> "${outfile}"
        echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        echo 'PERL_SYSTEM=/usr/bin/perl' >> "${outfile}"
        echo 'PYTHON_SYSTEM=/usr/bin/python3' >> "${outfile}"
        echo 'ZSH_SYSTEM=/bin/zsh' >> "${outfile}"

        # CLANGXX_SYSTEM
        # Get the macOS version number
        macos_version=$(sw_vers -productVersion | awk -F '.' '{print $1}')
        if [[ ${macos_version} -ge 14 ]]; then
            echo 'CLANGXX_SYSTEM=/usr/bin/clang++' >> "${outfile}"
        fi

        # GCC_MARCH
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
        [[ -e /bin/bash ]] && echo 'BASH_SYSTEM=/bin/bash' >> "${outfile}"
        [[ -e /bin/zsh ]] && echo 'ZSH_SYSTEM=/bin/zsh' >> "${outfile}"
        [[ -e /usr/bin/clang ]] && echo 'CLANG_SYSTEM=/usr/bin/clang' >> "${outfile}"
        # failing on GitHub Actions with ubuntu-24.04, devbox
        # [[ -e /usr/bin/clang++ ]] && echo 'CLANGXX_SYSTEM=/usr/bin/clang++' >> "${outfile}"
        [[ -e /usr/bin/perl ]] && echo 'PERL_SYSTEM=/usr/bin/perl' >> "${outfile}"
        [[ -e /usr/bin/python3 ]] && echo 'PYTHON_SYSTEM=/usr/bin/python3' >> "${outfile}"

        GCC_MARCH=native
        ;;
esac
echo "GCC_MARCH=${GCC_MARCH}" >> "${outfile}"
