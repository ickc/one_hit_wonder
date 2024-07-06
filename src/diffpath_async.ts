import { promises as fs } from "fs";
import path from "path";

// Function to check if a file is executable
async function isExecutable(filePath: string): Promise<boolean> {
  const stats = await fs.lstat(filePath);
  return (
    (stats.isFile() || stats.isSymbolicLink()) && (stats.mode & 0o111) !== 0
  );
}

// Function to get all executable files in a directory
async function getExecutableFiles(paths: string): Promise<Set<string>> {
  const executables = new Set<string>();
  await Promise.all(
    paths.split(":").map(async (dir) => {
      try {
        const files = await fs.readdir(dir);
        await Promise.all(
          files.map(async (file) => {
            const filePath = path.join(dir, file);
            try {
              if (await isExecutable(filePath)) {
                executables.add(file);
              }
            } catch (err) {
              // Ignore errors for individual files
            }
          }),
        );
      } catch (err) {
        // Ignore errors for directories that can't be read
      }
    }),
  );
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
async function main(): Promise<void> {
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
