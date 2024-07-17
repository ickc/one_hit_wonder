using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;

class DiffPath
{
    static void Main(string[] args)
    {
        if (args.Length != 2)
        {
            string executableName = Environment.GetCommandLineArgs()[0];
            string cwd = Directory.GetCurrentDirectory();
            string relativePath = Path.GetRelativePath(cwd, executableName);

            Console.Error.WriteLine($"Usage: {relativePath} PATH1 PATH2");
            return;
        }

        string path1 = args[0];
        string path2 = args[1];

        var executables1 = GetExecutables(path1);
        var executables2 = GetExecutables(path2);

        var uniqueExecutables = new SortedSet<string>(executables1.Except(executables2).Union(executables2.Except(executables1)), StringComparer.Ordinal);

        foreach (var exec in uniqueExecutables)
        {
            if (executables1.Contains(exec))
            {
                Console.WriteLine(exec);
            }
            else
            {
                Console.WriteLine("\t" + exec);
            }
        }
    }

    static SortedSet<string> GetExecutables(string pathVariable)
    {
        var executables = new SortedSet<string>(StringComparer.Ordinal);

        foreach (var path in pathVariable.Split(':'))
        {
            if (Directory.Exists(path))
            {
                try
                {
                    var files = Directory.EnumerateFileSystemEntries(path);
                    foreach (var file in files)
                    {
                        if (IsExecutable(file))
                        {
                            executables.Add(Path.GetFileName(file));
                        }
                    }
                }
                catch (UnauthorizedAccessException) { }
                catch (DirectoryNotFoundException) { }
            }
        }

        return executables;
    }

    public static bool IsExecutable(string filePath)
    {
        var fileInfo = new FileInfo(filePath);
        if (fileInfo.Attributes.HasFlag(FileAttributes.Directory))
        {
            return false;
        }
        var unixFilePermissions = fileInfo.UnixFileMode;
        const UnixFileMode AnyExecute = (UnixFileMode)0x49; // 0x40 (UserExecute) | 0x08 (GroupExecute) | 0x01 (OthersExecute)

        return (unixFilePermissions & AnyExecute) != 0;
    }
}
