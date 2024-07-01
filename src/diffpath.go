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
	return (mode.IsRegular() || mode&os.ModeSymlink != 0) && mode&0111 != 0
}

// Function to get executables from a PATH
func getExecutables(path string) []string {
	executables := []string{}
	for _, dir := range strings.Split(path, ":") {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue // Skip directories that cannot be read
		}
		for _, entry := range entries {
			if isExecutable(entry) {
				executables = append(executables, entry.Name())
			}
		}
	}
	sort.Strings(executables)
	return executables
}

// printDiff prints the differences in the required format
func printDiff(execs1, execs2 []string) {
	// note that execs1 and execs2 are sorted but not necessarily unique
	i, j := 0, 0
	for i < len(execs1) && j < len(execs2) {
		if execs1[i] < execs2[j] {
			fmt.Println(execs1[i])
			i++
			// skip duplicates
			for i < len(execs1) && execs1[i] == execs1[i-1] {
				i++
			}
		} else if execs1[i] > execs2[j] {
			fmt.Println("\t" + execs2[j])
			j++
			// skip duplicates
			for j < len(execs2) && execs2[j] == execs2[j-1] {
				j++
			}
		} else {
			i++
			// skip duplicates
			for i < len(execs1) && execs1[i] == execs1[i-1] {
				i++
			}
			j++
			for j < len(execs2) && execs2[j] == execs2[j-1] {
				j++
			}

		}
	}
	// print the rest of the elements
	for i < len(execs1) {
		fmt.Println(execs1[i])
		i++
		// skip duplicates
		for i < len(execs1) && execs1[i] == execs1[i-1] {
			i++
		}
	}
	for j < len(execs2) {
		fmt.Println("\t" + execs2[j])
		j++
		// skip duplicates
		for j < len(execs2) && execs2[j] == execs2[j-1] {
			j++
		}
	}
}

func main() {
	if len(os.Args) != 3 {
		fmt.Printf("Usage: %s PATH1 PATH2\n", os.Args[0])
		os.Exit(1)
	}
	// Get collections of executable filenames
	execs1 := getExecutables(os.Args[1])
	execs2 := getExecutables(os.Args[2])

	// Sort and print the differences
	printDiff(execs1, execs2)
}
