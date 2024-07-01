#!/usr/bin/env lua

-- diffpath.lua
local lfs = require("lfs")

-- Function to split a PATH string into a table of directories
local function split_path(path)
    local dirs = {}
    for dir in string.gmatch(path, "([^:]+)") do
        table.insert(dirs, dir)
    end
    return dirs
end

-- Function to check if a file is executable and is either a regular file or a symlink
local function is_executable(file)
    local attrs = lfs.symlinkattributes(file)
    if attrs and (attrs.mode == "file" or attrs.mode == "link") then
        local perm = attrs.permissions
        if perm:sub(3, 3) == "x" or perm:sub(6, 6) == "x" or perm:sub(9, 9) == "x" then
            return true
        end
    end
    return false
end

-- Function to collect all executable filenames in a directory
local function get_executables(path)
    local execs = {}
    for _, dir in ipairs(split_path(path)) do
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." then
                local filepath = dir .. "/" .. file
                if is_executable(filepath) then
                    execs[file] = true
                end
            end
        end
    end
    return execs
end

-- Function to diff two tables of executables
local function symmetric_difference(exec1, exec2)
    local unique_files = {}
    for file in pairs(exec1) do
        if not exec2[file] then
            table.insert(unique_files, file)
        end
    end
    for file in pairs(exec2) do
        if not exec1[file] then
            table.insert(unique_files, file)
        end
    end

    table.sort(unique_files)

    return unique_files
end

-- Main function
local function main()
    if #arg < 2 then
        print("Usage: " .. arg[0] .. " PATH1 PATH2")
        os.exit(1)
    end

    local path1 = arg[1]
    local path2 = arg[2]

    local execs1 = get_executables(path1)
    local execs2 = get_executables(path2)

    local unique_files = symmetric_difference(execs1, execs2)

    for _, file in ipairs(unique_files) do
        if execs1[file] then
            print(file)
        else
            print("\t" .. file)
        end
    end
end

main()
