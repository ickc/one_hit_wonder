# Function to get files in a given PATH
get_files() {
    local path="$1"
    IFS=':' read -r -a dirs <<< "${path}"
    FUNC_RETVAL=() # Initialize global variable directly
    for dir in "${dirs[@]}"; do
        if [[ -d ${dir} ]]; then
            for file in "${dir}"/* "${dir}"/.*; do
                if [[ (-f ${file} || -L ${file}) && -x ${file} ]]; then
                    FUNC_RETVAL+=("${file##*/}") # Use parameter expansion to get the basename
                fi
            done
        fi
    done
}

# Function to sort an array using merge sort (iteratively)
sort_array() {
    local array=("$@")
    local n=${#array[@]}

    for ((size = 1; size < n; size *= 2)); do
        for ((left_start = 0; left_start < n - 1; left_start += 2 * size)); do
            local mid=$((left_start + size - 1))
            local right_end=$((left_start + 2 * size - 1))
            if ((right_end >= n)); then
                right_end=$((n - 1))
            fi

            local left=("${array[@]:left_start:size}")
            local right=("${array[@]:mid+1:right_end-mid}")

            local i=0 j=0 k=${left_start}
            while ((i < ${#left[@]} && j < ${#right[@]})); do
                if [[ ${left[i]} < ${right[j]} ]]; then
                    array[k++]="${left[i++]}"
                else
                    array[k++]="${right[j++]}"
                fi
            done

            while ((i < ${#left[@]})); do
                array[k++]="${left[i++]}"
            done

            while ((j < ${#right[@]})); do
                array[k++]="${right[j++]}"
            done
        done
    done

    FUNC_RETVAL=("${array[@]}") # Assign result to a global variable
}

# Function to print differences like comm -3, skipping duplicates
print_diff() {
    local arr1=("${!1}")
    local arr2=("${!2}")
    local n1=${#arr1[@]}
    local n2=${#arr2[@]}
    local i=0 j=0

    while [[ ${i} -lt ${n1} && ${j} -lt ${n2} ]]; do
        local elem1="${arr1[${i}]}"
        local elem2="${arr2[${j}]}"

        if [[ ${elem1} < ${elem2} ]]; then
            echo "${elem1}"
            ((i++))
            while [[ ${i} -lt ${n1} && ${arr1[${i}]} == "${elem1}" ]]; do
                ((i++))
            done
        elif [[ ${elem1} > ${elem2} ]]; then
            echo -e "\t${elem2}"
            ((j++))
            while [[ ${j} -lt ${n2} && ${arr2[${j}]} == "${elem2}" ]]; do
                ((j++))
            done
        else
            ((i++))
            while [[ ${i} -lt ${n1} && ${arr1[${i}]} == "${elem1}" ]]; do
                ((i++))
            done
            ((j++))
            while [[ ${j} -lt ${n2} && ${arr2[${j}]} == "${elem2}" ]]; do
                ((j++))
            done
        fi
    done

    # Print remaining elements
    while [[ ${i} -lt ${n1} ]]; do
        local elem1="${arr1[${i}]}"
        echo "${elem1}"
        ((i++))
        while [[ ${i} -lt ${n1} && ${arr1[${i}]} == "${elem1}" ]]; do
            ((i++))
        done
    done

    while [[ ${j} -lt ${n2} ]]; do
        local elem2="${arr2[${j}]}"
        echo -e "\t${elem2}"
        ((j++))
        while [[ ${j} -lt ${n2} && ${arr2[${j}]} == "${elem2}" ]]; do
            ((j++))
        done
    done
}

main() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 PATH1 PATH2"
        exit 1
    fi

    # Get files from both paths and store them in global variable
    get_files "${1}"
    files1=("${FUNC_RETVAL[@]}")

    get_files "${2}"
    files2=("${FUNC_RETVAL[@]}")

    # Sort arrays using the sort_array function
    sort_array "${files1[@]}"
    # shellcheck disable=SC2034
    sorted_files1=("${FUNC_RETVAL[@]}")

    sort_array "${files2[@]}"
    # shellcheck disable=SC2034
    sorted_files2=("${FUNC_RETVAL[@]}")

    # Print the differences, skipping duplicates
    print_diff sorted_files1[@] sorted_files2[@]
}

main "$@"
