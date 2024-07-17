#!/usr/bin/env zsh

setopt extended_glob
setopt null_glob

# Function to get files in a given PATH
get_files() {
    local -a files
    local IFS=:
    for dir in ${(s.:.)1}; do
        if [[ -d ${dir} || -L ${dir} ]]; then
            local real_dir=${dir:A}  # Resolve symlink if it's a symlink
            local -a exec_files=(${real_dir}/*(-*N.x:t) ${real_dir}/.*(-*N.x:t))
            files+=(${exec_files})
        fi
    done
    print -l ${(u)files}
}

# Function to sort an array using merge sort (iteratively)
sort_array() {
    local -a array=("$@")
    local n=${#array}
    for ((size = 1; size < n; size *= 2)); do
        for ((left_start = 0; left_start < n - 1; left_start += 2 * size)); do
            local mid=$((left_start + size - 1))
            local right_end=$((left_start + 2 * size - 1))
            (( right_end >= n )) && right_end=$((n - 1))
            
            local -a left=("${(@)array[left_start+1,mid+1]}")
            local -a right=("${(@)array[mid+2,right_end+1]}")
            local i=1 j=1 k=$((left_start + 1))
            
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
    local -a arr1=("${(@P)1}")
    local -a arr2=("${(@P)2}")
    local n1=${#arr1} n2=${#arr2}
    local i=1 j=1
    
    while (( i <= n1 && j <= n2 )); do
        local elem1="${arr1[i]}" elem2="${arr2[j]}"
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
        local elem1="${arr1[i]}"
        print ${elem1}
        ((i++))
        while (( i <= n1 )) && [[ "${arr1[i]}" == "${elem1}" ]]; do ((i++)); done
    done
    
    while (( j <= n2 )); do
        local elem2="${arr2[j]}"
        print "\t${elem2}"
        ((j++))
        while (( j <= n2 )) && [[ "${arr2[j]}" == "${elem2}" ]]; do ((j++)); done
    done
}

main() {
    if (( $# != 2 )); then
        print "Usage: $0 PATH1 PATH2"
        return 1
    fi
    local -a files1=($(get_files $1))
    local -a files2=($(get_files $2))
    local -a sorted_files1=($(sort_array ${files1[@]}))
    local -a sorted_files2=($(sort_array ${files2[@]}))
    print_diff sorted_files1 sorted_files2
}

main "$@"
