# distutils: language=c++
from libc.stdio cimport printf
from libc.string cimport strtok
from libcpp.algorithm cimport set_symmetric_difference
from libcpp.set cimport set as cppset
from libcpp.string cimport string
from libcpp.vector cimport vector

import sys

from cpython.unicode cimport PyUnicode_AsUTF8


cdef extern from "dirent.h":
    ctypedef struct DIR:
        pass
    cdef struct dirent:
        char* d_name
    DIR* opendir(const char* name)
    dirent* readdir(DIR* dirp)
    int closedir(DIR* dirp)
    int dirfd(DIR *dirp)

from posix.fcntl cimport AT_SYMLINK_NOFOLLOW
from posix.stat cimport (S_ISLNK, S_ISREG, S_IXGRP, S_IXOTH, S_IXUSR, fstatat,
                         struct_stat)


cdef cppset[string] get_executables(string path):
    """
    Retrieve a set of executable file names from the given path.

    Args:
        path (string): A colon-separated list of directory paths.

    Returns:
        cppset[string]: A set of executable file names found in the given directories.
    """
    cdef cppset[string] executables
    cdef DIR* dir
    cdef dirent* entry
    cdef struct_stat st
    cdef int dir_fd
    cdef char* token

    token = strtok(path.data(), ":")
    while token != NULL:
        dir = opendir(token)
        if dir != NULL:
            dir_fd = dirfd(dir)
            while (entry := readdir(dir)) != NULL:
                if (fstatat(dir_fd, entry.d_name, &st, AT_SYMLINK_NOFOLLOW) == 0) and (
                    S_ISLNK(st.st_mode) or (S_ISREG(st.st_mode) and (st.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH)))):
                    executables.insert(string(entry.d_name))
            closedir(dir)
        token = strtok(NULL, ":")
    return executables

cdef void diffpath(const string& PATH1, const string& PATH2):
    """
    Compare executable files in two paths and print the differences.

    Args:
        PATH1 (string): The first path to compare.
        PATH2 (string): The second path to compare.

    Prints:
        Executable files unique to PATH1 without indentation.
        Executable files unique to PATH2 with a tab indentation.
    """
    cdef cppset[string] executables1 = get_executables(PATH1)
    cdef cppset[string] executables2 = get_executables(PATH2)

    cdef size_t total_size = executables1.size() + executables2.size()
    cdef vector[string] all_unique
    all_unique.resize(total_size)

    cdef vector[string].iterator it_end = set_symmetric_difference(
        executables1.begin(), executables1.end(),
        executables2.begin(), executables2.end(),
        all_unique.begin()
    )

    all_unique.resize(it_end - all_unique.begin())

    cdef string exec_str
    for exec_str in all_unique:
        if executables1.contains(exec_str):
            printf("%s\n", exec_str.c_str())
        else:
            printf("\t%s\n", exec_str.c_str())

def main():
    """
    Main function to handle command-line arguments and call diffpath.

    Usage:
        python script_name.py PATH1 PATH2

    Exits with status code 1 if incorrect number of arguments are provided.
    """
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} PATH1 PATH2")
        sys.exit(1)
    
    cdef string path1 = PyUnicode_AsUTF8(sys.argv[1])
    cdef string path2 = PyUnicode_AsUTF8(sys.argv[2])
    diffpath(path1, path2)

if __name__ == "__main__":
    main()
