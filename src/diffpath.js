#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

// Function to get all executable files in a directory
function getExecutableFiles(paths) {
  const executables = new Set();
  paths.split(":").forEach((dir) => {
    try {
      const files = fs.readdirSync(dir);
      files.forEach((file) => {
        const filePath = path.join(dir, file);
        try {
          const stats = fs.statSync(filePath);
          if (stats.isFile() && stats.mode & 0o111) {
            // Check any execute permission
            executables.add(file);
          }
        } catch (err) {}
      });
    } catch (err) {}
  });
  return executables;
}

// Function to get the symmetric difference between two sets
function symmetricDifferenceList(set1, set2) {
  const difference = new Array();
  set1.forEach((value) => {
    if (!set2.has(value)) {
      difference.push(value);
    }
  });
  set2.forEach((value) => {
    if (!set1.has(value)) {
      difference.push(value);
    }
  });
  difference.sort();
  return difference;
}

// Main function to execute the diffpath logic
function main() {
  const [, , path1, path2] = process.argv;
  if (!path1 || !path2) {
    const programName = path.basename(process.argv[1]);
    console.error(`Usage: ${programName} PATH1 PATH2`);
    process.exit(1);
  }

  const execSet1 = getExecutableFiles(path1);
  const execSet2 = getExecutableFiles(path2);

  const sortedDiff = symmetricDifferenceList(execSet1, execSet2);

  sortedDiff.forEach((file) => {
    if (execSet1.has(file)) {
      console.log(file);
    } else {
      console.log(`\t${file}`);
    }
  });
}

main();
