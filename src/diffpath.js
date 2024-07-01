#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

// Function to check if a file is executable
function isExecutable(filePath) {
  const stats = fs.lstatSync(filePath);
  return (stats.isFile() || stats.isSymbolicLink()) && stats.mode & 0o111;
}

// Function to get all executable files in a directory
function getExecutableFiles(paths) {
  const executables = new Set();
  paths.split(":").forEach((dir) => {
    try {
      const files = fs.readdirSync(dir);
      files.forEach((file) => {
        const filePath = path.join(dir, file);
        try {
          if (isExecutable(filePath)) {
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
  const difference = [];
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
  if (process.argv.length !== 4) {
    const programName = path.basename(process.argv[1]);
    console.error(`Usage: ${programName} PATH1 PATH2`);
    process.exit(1);
  }
  const [, , path1, path2] = process.argv;

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
