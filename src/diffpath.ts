import fs from "fs";
import path from "path";

// Function to check if a file is executable
function isExecutable(filePath: string): boolean {
  const stats = fs.lstatSync(filePath);
  return (
    stats.isSymbolicLink() || (stats.isFile() && (stats.mode & 0o111) !== 0)
  );
}

// Function to get all executable files in a directory
function getExecutableFiles(paths: string): Set<string> {
  const executables = new Set<string>();
  paths.split(":").forEach((dir) => {
    try {
      const files = fs.readdirSync(dir);
      files.forEach((file) => {
        const filePath = path.join(dir, file);
        try {
          if (isExecutable(filePath)) {
            executables.add(file);
          }
        } catch (err) {
          // Ignore errors for individual files
        }
      });
    } catch (err) {
      // Ignore errors for directories that can't be read
    }
  });
  return executables;
}

// Function to get the symmetric difference between two sets
function symmetricDifferenceList(
  set1: Set<string>,
  set2: Set<string>,
): string[] {
  const difference: string[] = [];
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
function main(): void {
  if (process.argv.length !== 4) {
    const absolutePath = process.argv[1];
    const relativePath = path.relative(process.cwd(), absolutePath);
    console.error(`Usage: ${relativePath} PATH1 PATH2`);
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
