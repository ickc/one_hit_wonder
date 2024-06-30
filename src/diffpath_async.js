#!/usr/bin/env node

const fs = require("fs").promises;
const path = require("path");

// Function to get all executable files in a directory
async function getExecutableFiles(paths) {
  const executables = new Set();
  const dirs = paths.split(":");

  await Promise.all(
    dirs.map(async (dir) => {
      try {
        const files = await fs.readdir(dir);
        await Promise.all(
          files.map(async (file) => {
            const filePath = path.join(dir, file);
            try {
              const stats = await fs.stat(filePath);
              if (stats.isFile() && stats.mode & 0o111) {
                executables.add(file);
              }
            } catch (err) {}
          }),
        );
      } catch (err) {}
    }),
  );
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
async function main() {
  if (process.argv.length !== 4) {
    const programName = path.basename(process.argv[1]);
    console.error(`Usage: ${programName} PATH1 PATH2`);
    process.exit(1);
  }
  const [, , path1, path2] = process.argv;

  const [execSet1, execSet2] = await Promise.all([
    getExecutableFiles(path1),
    getExecutableFiles(path2),
  ]);

  const sortedDiff = symmetricDifferenceList(execSet1, execSet2);

  sortedDiff.forEach((file) => {
    if (execSet1.has(file)) {
      console.log(file);
    } else {
      console.log(`\t${file}`);
    }
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
