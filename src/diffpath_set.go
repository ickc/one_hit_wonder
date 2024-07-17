package main

import (
	"fmt"
	"os"
	"sort"
	"strings"
)

// Function to check if a path is a regular file and executable
func isExecutable(entry os.DirEntry) bool {
	info, err := entry.Info()
	if err != nil {
		return false
	}
	mode := info.Mode()
	return (mode&os.ModeSymlink != 0) || (mode.IsRegular() && (mode&0111 != 0))
}

// Function to get executables from a PATH
func getExecutables(path string) map[string]struct{} {
	executables := make(map[string]struct{})
	for _, dir := range strings.Split(path, ":") {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue // Skip directories that cannot be read
		}
		for _, entry := range entries {
			if isExecutable(entry) {
				executables[entry.Name()] = struct{}{}
			}
		}
	}
	return executables
}

func symmetricDifference(set1, set2 map[string]struct{}) []string {
	diff := make([]string, 0)
	for command := range set1 {
		if _, found := set2[command]; !found {
			diff = append(diff, command)
		}
	}
	for command := range set2 {
		if _, found := set1[command]; !found {
			diff = append(diff, command)
		}
	}
	sort.Strings(diff)
	return diff
}

// printDiff prints the differences in the required format
func printDiff(executables1, executables2 map[string]struct{}) {
	diff := symmetricDifference(executables1, executables2)
	for _, command := range diff {
		if _, found := executables1[command]; found {
			fmt.Println(command)
		} else {
			fmt.Println("\t" + command)
		}
	}
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s PATH1 PATH2\n", os.Args[0])
		os.Exit(1)
	}
	// Get collections of executable filenames
	execs1 := getExecutables(os.Args[1])
	execs2 := getExecutables(os.Args[2])

	// Sort and print the differences
	printDiff(execs1, execs2)
}
