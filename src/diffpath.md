Write a [LANGUAGE] program that implements a command-line tool called `diffpath` with the following specifications:

# Specifications

1. **Usage**:
    - The program should be called with two arguments: `PATH1` and `PATH2`.
    - If the wrong number of arguments is provided, print a usage message to stderr as `Usage: $0 PATH1 PATH2` and exit with status 1.
    - `$0` should represent the program name as called from the command line, which might be a relative or absolute path.

2. **Path Handling**:
    - Split each `PATH` variable (colon-separated list of directories) into individual directories.

3. **Executable Discovery**:
    - For each directory, identify all executable files defined as either:
        - Symlinks.
        - Regular files with any execute permission (user, group, or others).

4. **Collection of Executable Filenames**:
    - Create a collection of executable filenames (not full paths) for each `PATH`.

5. **Output the Diff**:
    - Compare the two collections and output the difference in a format similar to `comm -3`:
        - Include items unique to either `PATH1` or `PATH2`.
        - Sort these items.
        - Print each item in this combined sorted order.
        - Prefix items from `PATH2` with a tab character.

# Pseudo Code

```py
def is_executable(path):
    return path.is_symlink or (path.is_regular_file and (path.is_user_executable or path.is_group_executable or path.is_others_executable))

def get_executables(PATH) -> collection_type1:
    res = []
    for directory in PATH.split(":"):
        for file in directory.contents:
            if is_executable(file):
                res.append(file.filename)
    return res

def comm_3(executables1, executables2):
    """Behaves like `comm -3 executables1 executables2`"""
    unique: collection_type2 = symmetric_difference(executables1, executables2)
    for i in sorted(unique):
        if i in executables1:
            print(f"{i}")
        else:
            print(f"\t{i}")

def diffpath(PATH1, PATH2):
    executables1 = get_executables(PATH1)
    executables2 = get_executables(PATH2)
    comm_3(executables1, executables2)

def main():
    if len(args) != 2:
        stderr(f"Usage: $0 PATH1 PATH2")
    diffpath(args[0], args[1])
```

# Collection Choice

- Choose the best type of collection (e.g., sets, lists) based on the requirements and the standard library of the [LANGUAGE].

# Additional Information

- **Formatters**: Recommend a code formatter and justify why it is the best choice for [LANGUAGE].
- **Compilers**: Recommend a compiler and justify why it is the best choice for [LANGUAGE].
- **Optimization Options**: Suggest optimization options to be used when compiling the program and explain their benefits.
- **Compilation Instructions**: Provide exact steps on how to prepare the code and compile it. Use a single source file and commands to compile that file, avoiding additional files such as manifests if possible.
