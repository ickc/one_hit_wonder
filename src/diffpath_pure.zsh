#!/usr/bin/env zsh

setopt extended_glob

# Function to get files in a given PATH
get_files() {
    local -a files
    local IFS=: dir
    for dir in ${(s.:.)1}; do
        if [[ -L ${dir} ]]; then
            dir=${dir:A}  # Resolve symlink if it's a symlink
        fi
        if [[ -d ${dir} ]]; then
            files+=(${dir}/*(-*N.x:t) ${dir}/.*(-*N.x:t))
        fi
    done
    print -l ${(u)files}
}

# Function to sort an array using merge sort (iteratively)
sort_array() {
    local -a array left right
    local n size left_start mid right_end i j k
    array=("$@")
    n=${#array}

    for ((size = 1; size < n; size *= 2)); do
        for ((left_start = 0; left_start < n - 1; left_start += 2 * size)); do
            mid=$((left_start + size - 1))
            right_end=$((left_start + 2 * size - 1))
            (( right_end >= n )) && right_end=$((n - 1))

            left=("${(@)array[left_start+1,mid+1]}")
            right=("${(@)array[mid+2,right_end+1]}")
            i=1 j=1 k=$((left_start + 1))

            while (( i <= $#left && j <= $#right )); do
                if [[ ${left[i]} < ${right[j]} ]]; then
                    array[k++]=${left[i++]}
                else
                    array[k++]=${right[j++]}
                fi
            done
            while (( i <= $#left )); do
                array[k++]=${left[i++]}
            done
            while (( j <= $#right )); do
                array[k++]=${right[j++]}
            done
        done
    done
    print -l "${array[@]}"
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
            while (( i <= n1 )) && [[ "${arr1[i]}" == "${elem1}" ]]; do ((i++)); done
        elif [[ "${elem1}" > "${elem2}" ]]; then
            print "\t${elem2}"
            ((j++))
            while (( j <= n2 )) && [[ "${arr2[j]}" == "${elem2}" ]]; do ((j++)); done
        else
            ((i++))
            while (( i <= n1 )) && [[ "${arr1[i]}" == "${elem1}" ]]; do ((i++)); done
            ((j++))
            while (( j <= n2 )) && [[ "${arr2[j]}" == "${elem2}" ]]; do ((j++)); done
        fi
    done

    # Print remaining elements
    while (( i <= n1 )); do
        elem1="${arr1[i]}"
        print ${elem1}
        ((i++))
        while (( i <= n1 )) && [[ "${arr1[i]}" == "${elem1}" ]]; do ((i++)); done
    done

    while (( j <= n2 )); do
        elem2="${arr2[j]}"
        print "\t${elem2}"
        ((j++))
        while (( j <= n2 )) && [[ "${arr2[j]}" == "${elem2}" ]]; do ((j++)); done
    done
}

main() {
    local -a files1 files2 sorted_files1 sorted_files2
    if (( $# != 2 )); then
        print "Usage: $0 PATH1 PATH2"
        return 1
    fi

    files1=($(get_files $1))
    files2=($(get_files $2))
    sorted_files1=($(sort_array ${files1[@]}))
    sorted_files2=($(sort_array ${files2[@]}))
    print_diff sorted_files1 sorted_files2
}

main "$@"
