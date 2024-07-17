# shellcheck disable=SC2312
# Function to get executable files in a given PATH
get_executables() {
    local dir
    local IFS=':'
    for dir in $1; do
        {
            cd "${dir}" 2> /dev/null &&
                find . -maxdepth 1 \( -type l -o -type f \) -perm /a+x -print
        }
    done | sed 's|^\./||' | sort -u
}
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 PATH1 PATH2"
    exit 1
fi
comm -3 <(get_executables "$1") <(get_executables "$2")
