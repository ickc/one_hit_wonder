# This script does not implement the -d flag, which would verify that the paths exist.
# This also does not handle the case that the directory is not the root of a git repository.

usage="Usage: ${0} [-e] [-d] [directory]
List all git-ignored files under the given directory.
    -e  List files in a git-ignored directory.
    -d  Verify paths exist, print to stderr if not. (Not implemented.)
"

directory="."
expand_directory=""
debug=false

while getopts "ed" opt; do
    case ${opt} in
        e)
            expand_directory="--untracked-files=all"
            ;;
        d)
            # Note: Path verification is not implemented.
            # shellcheck disable=SC2034
            debug=true
            ;;
        *)
            echo "${usage}"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -gt 0 ]]; then
    directory=${1}
fi

# shellcheck disable=SC2312
find "${directory}" -name .git -exec bash -c '
	for git do
		dir="${git::-4}"
		{
            cd "${dir}"
            git status . --ignored --ignore-submodules=all --no-renames --porcelain=1 -z '"${expand_directory}"' | awk -v dir="${dir}" -v RS="\0" -v ORS="\0" "/^!! / {print dir substr(\$0,4)}"
        }
	done' _ {} + | sort -z | tr '\0' '\n'
