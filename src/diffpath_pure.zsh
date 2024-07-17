#!/usr/bin/env zsh

setopt extended_glob

# Function to get files in a given PATH
get_files() {
    local -a files
    local IFS=: dir
    for dir in ${(s.:.)1}; do
        if [[ -d ${dir} ]]; then
            files+=(${dir}/*(-*N.x:t) ${dir}/.*(-*N.x:t))
        fi
    done
    print -l ${(ou)files}
}

# Function to print differences like comm -3, skipping duplicates
print_diff() {
    local -a arr1 arr2
    local n1 n2 i j elem1 elem2
    arr1=("${(@P)1}")
    arr2=("${(@P)2}")
    n1=${#arr1}
    n2=${#arr2}
    i=1
    j=1

    while (( i <= n1 && j <= n2 )); do
        elem1="${arr1[i]}"
        elem2="${arr2[j]}"
        if [[ "${elem1}" < "${elem2}" ]]; then
            print ${elem1}
            ((i++))
        elif [[ "${elem1}" > "${elem2}" ]]; then
            print "\t${elem2}"
            ((j++))
        else
            ((i++))
            ((j++))
        fi
    done

    # Print remaining elements
    while (( i <= n1 )); do
        elem1="${arr1[i]}"
        print ${elem1}
        ((i++))
    done

    while (( j <= n2 )); do
        elem2="${arr2[j]}"
        print "\t${elem2}"
        ((j++))
    done
}

main() {
    local -a files1 files2
    if (( $# != 2 )); then
        print "Usage: $0 PATH1 PATH2"
        return 1
    fi

    files1=($(get_files $1))
    files2=($(get_files $2))
    print_diff files1 files2
}

main "$@"
