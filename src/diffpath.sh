#!/bin/bash

# Function to get files in a given PATH
get_files() {
    local path="$1"
    IFS=':' read -r -a dirs <<< "${path}"
    for dir in "${dirs[@]}"; do
        if [[ -d ${dir} ]]; then
            cd "${dir}"
            find . -maxdepth 1 \( -type f -o -type l \) -perm /a+x -print
            cd -
            # ls -a "${dir}"
        fi
    done | sed 's|^\./||' | sort -u
}
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 PATH1 PATH2"
    exit 1
fi
comm -3 <(get_files "${1}") <(get_files "${2}")
