#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

// Function to get all executable files in a directory
function getExecutableFiles(dir) {
  let executables = new Set();
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
      } catch (err) {
        // Handle errors related to file stat
      }
    });
  } catch (err) {
    // Handle errors related to directory reading
  }
  return executables;
}

// Function to get the difference between two sets of executables
function diffExecutables(set1, set2) {
  const onlyInSet1 = [...set1].filter((x) => !set2.has(x));
  const onlyInSet2 = [...set2].filter((x) => !set1.has(x));
  return { onlyInSet1, onlyInSet2 };
}

// Main function to execute the diffpath logic
function main() {
  const [, , PATH1, PATH2] = process.argv;
  if (!PATH1 || !PATH2) {
    console.error("Usage: diffpath PATH1 PATH2");
    process.exit(1);
  }

  const path1Dirs = PATH1.split(":");
  const path2Dirs = PATH2.split(":");

  let execSet1 = new Set();
  let execSet2 = new Set();

  path1Dirs.forEach((dir) => {
    const execFiles = getExecutableFiles(dir);
    execFiles.forEach((file) => execSet1.add(file));
  });

  path2Dirs.forEach((dir) => {
    const execFiles = getExecutableFiles(dir);
    execFiles.forEach((file) => execSet2.add(file));
  });

  const { onlyInSet1, onlyInSet2 } = diffExecutables(execSet1, execSet2);

  const combinedSorted = [...onlyInSet1, ...onlyInSet2].sort();

  combinedSorted.forEach((file) => {
    if (onlyInSet1.includes(file)) {
      console.log(file);
    } else {
      console.log(`\t${file}`);
    }
  });
}

main();
