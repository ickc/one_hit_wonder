function get_executables(path::String)::Set{String}
    return Set(
        basename(file)::String
        for dir::String in split(path, ':') if isdir(dir)
        for file::String in readdir(dir; join=true)
        if (islink(file) || isfile(file)) && (lstat(file).mode & 0o111 != 0)
    )
end

function diffpath(path1::String, path2::String)::Nothing
    executables1::Set{String} = get_executables(path1)
    executables2::Set{String} = get_executables(path2)
    for command::String in sort(collect(symdiff(executables1, executables2)))
        if command in executables1
            println(command)
        else
            println('\t' * command)
        end
    end
end

function main()::Nothing
    if length(ARGS) != 2
        println("Usage: $(PROGRAM_FILE) PATH1 PATH2")
        exit(1)
    end
    diffpath(ARGS[1], ARGS[2])
end

main()
