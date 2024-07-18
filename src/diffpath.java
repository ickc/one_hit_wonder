import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Set;
import java.util.TreeSet;

public class diffpath {
    public static void main(String[] args) {
        if (args.length != 2) {
            System.err.println("Usage: " + getProgramName() + " PATH1 PATH2");
            System.exit(1);
        }

        String PATH1 = args[0];
        String PATH2 = args[1];

        Set<String> executables1 = getExecutables(PATH1);
        Set<String> executables2 = getExecutables(PATH2);

        printDiff(executables1, executables2);
    }

    private static String getProgramName() {
        String command = System.getProperty("sun.java.command");
        // Check if the command starts with a quote
        if (command.startsWith("\"")) {
            // Find the ending quote and extract the substring within quotes
            int endQuoteIndex = command.indexOf("\"", 1);
            if (endQuoteIndex > 0) {
                return command.substring(1, endQuoteIndex);
            }
        }
        // If no quotes, return the first part split by space
        return command.split(" ")[0];
    }

    private static Set<String> getExecutables(String PATH) {
        Set<String> executables = new TreeSet<>();
        String[] directories = PATH.split(":");

        for (String directory : directories) {
            File dir = new File(directory);
            if (dir.isDirectory()) {
                File[] files = dir.listFiles();
                if (files != null) {
                    for (File file : files) {
                        if (isExecutable(file)) {
                            executables.add(file.getName());
                        }
                    }
                }
            }
        }
        return executables;
    }

    private static boolean isExecutable(File file) {
        Path path = file.toPath();
        if (Files.isDirectory(path)) {
            return false;
        }
        if (Files.isSymbolicLink(path)) {
            return true;
        }
        if (Files.isRegularFile(path)) {
            try {
                Set<PosixFilePermission> permissions = Files.getPosixFilePermissions(path);
                return (permissions.contains(PosixFilePermission.OWNER_EXECUTE)
                        || permissions.contains(PosixFilePermission.GROUP_EXECUTE)
                        || permissions.contains(PosixFilePermission.OTHERS_EXECUTE));
            } catch (IOException e) {
                return false;
            }
        }
        return false;
    }

    private static void printDiff(Set<String> executables1, Set<String> executables2) {
        Set<String> all = new TreeSet<>(executables1);
        all.addAll(executables2);
        for (String executable : all) {
            if (executables1.contains(executable)) {
                if (!executables2.contains(executable)) {
                    System.out.println(executable);
                }
            } else {
                System.out.println("\t" + executable);
            }
        }
    }
}
