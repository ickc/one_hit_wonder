#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define INITIAL_CAPACITY 2048

// Function to check if a path is a regular file and executable
static inline int is_executable(const int dir_fd, const struct dirent* entry)
{
    struct stat st;
    return (fstatat(dir_fd, entry->d_name, &st, AT_SYMLINK_NOFOLLOW) == 0) && (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) && (st.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH));
}

// Function to compare strings for qsort
int compare_strings(const void* a, const void* b)
{
    return strcmp(*(const char**)a, *(const char**)b);
}

// Function to get executables from a PATH
// return a sorted but not necessarily unique list of executables
void get_executables(const char* path, char*** executables, size_t* count)
{
    char* path_copy = strdup(path);
    if (!path_copy) {
        fprintf(stderr, "Error: Memory allocation failed.\n");
        return;
    }

    size_t capacity = INITIAL_CAPACITY;
    *executables = malloc(capacity * sizeof(char*));
    if (!*executables) {
        fprintf(stderr, "Error: Memory allocation failed.\n");
        free(path_copy);
        return;
    }
    *count = 0;

    char* saveptr;
    DIR* d;
    struct dirent* entry;
    for (char* dir = strtok_r(path_copy, ":", &saveptr); dir != NULL; dir = strtok_r(NULL, ":", &saveptr)) {
        d = opendir(dir);
        if (!d) {
            // fprintf(stderr, "Warning: Could not open directory %s\n", dir);
            continue;
        }
        // Get file descriptor for the directory
        int dir_fd = dirfd(d);
        if (dir_fd == -1) {
            closedir(d);
            continue;
        }

        while ((entry = readdir(d)) != NULL) {
            if (is_executable(dir_fd, entry)) {
                // check if we need to resize the array
                if (*count >= capacity) {
                    capacity *= 2;
                    // fprintf(stderr, "Warning: Capacity exceeded. Resizing array to %zu\n", capacity);
                    char** new_executables = realloc(*executables, capacity * sizeof(char*));
                    if (!new_executables) {
                        fprintf(stderr, "Error: Memory allocation failed.\n");
                        free(path_copy);
                        closedir(d);
                        return;
                    }
                    *executables = new_executables;
                }
                (*executables)[*count] = strdup(entry->d_name);
                if (!(*executables)[*count]) {
                    fprintf(stderr, "Error: Memory allocation failed.\n");
                    free(path_copy);
                    closedir(d);
                    return;
                }
                (*count)++;
            }
        }
        closedir(d);
    }
    free(path_copy);
    qsort(*executables, *count, sizeof(char*), compare_strings);
}

// Function to print the executable diff
void print_diff(char** executables1, const size_t count1, char** executables2, const size_t count2)
{
    size_t i = 0, j = 0;
    int cmp;
    char *elem1, *elem2;
    while (i < count1 && j < count2) {
        elem1 = executables1[i];
        elem2 = executables2[j];
        cmp = strcmp(elem1, elem2);
        if (cmp < 0) {
            printf("%s\n", elem1);
            do {
                i++;
            } while (i < count1 && strcmp(executables1[i], elem1) == 0);
        } else if (cmp > 0) {
            printf("\t%s\n", elem2);
            do {
                j++;
            } while (j < count2 && strcmp(executables2[j], elem2) == 0);
        } else {
            do {
                i++;
            } while (i < count1 && strcmp(executables1[i], elem1) == 0);
            do {
                j++;
            } while (j < count2 && strcmp(executables2[j], elem2) == 0);
        }
    }

    while (i < count1) {
        elem1 = executables1[i];
        printf("%s\n", elem1);
        do {
            i++;
        } while (i < count1 && strcmp(executables1[i], elem1) == 0);
    }

    while (j < count2) {
        elem2 = executables2[j];
        printf("\t%s\n", elem2);
        do {
            j++;
        } while (j < count2 && strcmp(executables2[j], elem2) == 0);
    }
}

// Function to clean up allocated memory
void cleanup(char** executables, size_t count)
{
    for (size_t i = 0; i < count; i++) {
        free(executables[i]);
    }
    free(executables);
}

int main(int argc, char* argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Usage: %s PATH1 PATH2\n", argv[0]);
        return 1;
    }

    char** executables1 = NULL;
    char** executables2 = NULL;
    size_t count1, count2;

    get_executables(argv[1], &executables1, &count1);
    get_executables(argv[2], &executables2, &count2);

    print_diff(executables1, count1, executables2, count2);

    cleanup(executables1, count1);
    cleanup(executables2, count2);

    return 0;
}
