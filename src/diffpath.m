#import <Foundation/Foundation.h>
#import <dirent.h>
#import <sys/stat.h>
#import <unistd.h>

// Function to check if a file is executable without following symlinks
BOOL isExecutableAtPath(int dirfd, const char* fileName)
{
    struct stat st;
    if (fstatat(dirfd, fileName, &st, AT_SYMLINK_NOFOLLOW) == -1) {
        perror("fstatat");
        return NO;
    }
    // Check if the file is either regular or symlink and executable by user, group, or others
    return S_ISLNK(st.st_mode) || (S_ISREG(st.st_mode) && (st.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH)));
}

// Function to get all executable filenames in a directory without following symlinks
NSSet<NSString*>* getExecutablesInDirectory(NSString* directory)
{
    NSMutableSet<NSString*>* executables = [NSMutableSet set];
    int dirfd = open([directory fileSystemRepresentation], O_RDONLY | O_DIRECTORY);
    if (dirfd == -1) {
        perror("open");
        return executables;
    }

    DIR* dir = fdopendir(dirfd);
    if (dir) {
        struct dirent* entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_type == DT_REG || entry->d_type == DT_LNK) {
                if (isExecutableAtPath(dirfd, entry->d_name)) {
                    NSString* filename = [NSString stringWithUTF8String:entry->d_name];
                    [executables addObject:filename];
                }
            }
        }
        closedir(dir);
    } else {
        perror("fdopendir");
        close(dirfd);
    }
    close(dirfd);
    return executables;
}

// Function to collect executables from PATH
NSSet<NSString*>* collectExecutables(NSString* path)
{
    NSMutableSet<NSString*>* executables = [NSMutableSet set];
    NSArray<NSString*>* directories = [path componentsSeparatedByString:@":"];
    for (NSString* directory in directories) {
        [executables unionSet:getExecutablesInDirectory(directory)];
    }
    return executables;
}

// Main function to compare executables in two PATHs and output the difference
int main(int argc, const char* argv[])
{
    @autoreleasepool {
        if (argc != 3) {
            fprintf(stderr, "Usage: diffpath PATH1 PATH2\n");
            return 1;
        }

        NSString* path1 = [NSString stringWithUTF8String:argv[1]];
        NSString* path2 = [NSString stringWithUTF8String:argv[2]];

        NSSet<NSString*>* executables1 = collectExecutables(path1);
        NSSet<NSString*>* executables2 = collectExecutables(path2);

        NSMutableSet<NSString*>* uniqueToPath1 = [executables1 mutableCopy];
        [uniqueToPath1 minusSet:executables2];

        NSMutableSet<NSString*>* uniqueToPath2 = [executables2 mutableCopy];
        [uniqueToPath2 minusSet:executables1];

        NSMutableSet<NSString*>* symmetricDifference = [uniqueToPath1 mutableCopy];
        [symmetricDifference unionSet:uniqueToPath2];

        NSArray<NSString*>* diff = [[symmetricDifference allObjects] sortedArrayUsingSelector:@selector(compare:)];

        for (NSString* entry in diff) {
            if ([executables1 containsObject:entry]) {
                printf("%s\n", [entry UTF8String]);
            } else {
                printf("\t%s\n", [entry UTF8String]);
            }
        }
    }
    return 0;
}
