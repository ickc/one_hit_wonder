#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX_PATH 4096
#define INITIAL_CAPACITY 2048

// Function to check if a path is a regular file and executable
static inline int is_executable(const char* path)
{
    struct stat st;
    return (stat(path, &st) == 0) && S_ISREG(st.st_mode) && (st.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH));
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
        return;
    }
    *count = 0;

    char* saveptr;
    for (char* dir = strtok_r(path_copy, ":", &saveptr); dir != NULL; dir = strtok_r(NULL, ":", &saveptr)) {
        DIR* d = opendir(dir);
        if (!d) {
            fprintf(stderr, "Warning: Could not open directory %s\n", dir);
            continue;
        }

        struct dirent* entry;
        while ((entry = readdir(d)) != NULL) {
            char full_path[MAX_PATH];
            snprintf(full_path, MAX_PATH, "%s/%s", dir, entry->d_name);
            if (is_executable(full_path)) {
                // check if we need to resize the array
                if (*count >= capacity) {
                    capacity *= 2;
                    // fprintf(stderr, "Warning: Capacity exceeded. Resizing array to %zu\n", capacity);
                    *executables = realloc(*executables, capacity * sizeof(char*));
                    if (!*executables) {
                        fprintf(stderr, "Error: Memory allocation failed.\n");
                        free(path_copy);
                        closedir(d);
                        return;
                    }
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
void print_executable_diff(char** executables1, const size_t count1, char** executables2, const size_t count2)
{
    size_t i = 0, j = 0;
    while (i < count1 && j < count2) {
        int cmp = strcmp(executables1[i], executables2[j]);
        if (cmp < 0) {
            printf("%s\n", executables1[i]);
            i++;
            // skip duplicates
            while (i < count1 && strcmp(executables1[i], executables1[i - 1]) == 0) {
                i++;
            }
        } else if (cmp > 0) {
            printf("\t%s\n", executables2[j]);
            j++;
            // skip duplicates
            while (j < count2 && strcmp(executables2[j], executables2[j - 1]) == 0) {
                j++;
            }
        } else {
            i++;
            // skip duplicates
            while (i < count1 && strcmp(executables1[i], executables1[i - 1]) == 0) {
                i++;
            }
            j++;
            // skip duplicates
            while (j < count2 && strcmp(executables2[j], executables2[j - 1]) == 0) {
                j++;
            }
        }
    }

    while (i < count1) {
        printf("%s\n", executables1[i]);
        i++;
        // skip duplicates
        while (i < count1 && strcmp(executables1[i], executables1[i - 1]) == 0) {
            i++;
        }
    }

    while (j < count2) {
        printf("\t%s\n", executables2[j]);
        j++;
        // skip duplicates
        while (j < count2 && strcmp(executables2[j], executables2[j - 1]) == 0) {
            j++;
        }
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

    print_executable_diff(executables1, count1, executables2, count2);

    cleanup(executables1, count1);
    cleanup(executables2, count2);

    return 0;
}
