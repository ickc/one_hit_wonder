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
            Console.WriteLine("Usage: diffpath PATH1 PATH2");
            return;
        }

        string path1 = args[0];
        string path2 = args[1];

        var executables1 = GetExecutables(path1);
        var executables2 = GetExecutables(path2);

        var uniqueExecutables = executables1.Except(executables2).Union(executables2.Except(executables1)).OrderBy(e => e);

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

    static HashSet<string> GetExecutables(string pathVariable)
    {
        var executables = new HashSet<string>();

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

    // dotnet is not good at handling posix specific stuff
    // using Mono.Posix.NETStandard still doesn't work and makes it hard to build a single binary
    // using lstat is another nightmare
    // I'm sure given enough effort, any of these methods can be made to work
    // but I'm not going to spend more time on this
    [DllImport("libc", SetLastError = true)]
    private static extern int access(string pathname, int mode);

    private const int X_OK = 0x01; // Execute permission

    public static bool IsExecutable(string filePath)
    {
        if (!File.Exists(filePath))
        {
            return false;
        }

        // Check execute permission using access system call
        if (access(filePath, X_OK) == 0)
        {
            return true;
        }

        return false;
    }
}
