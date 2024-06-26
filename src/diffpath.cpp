#include <filesystem>
#include <iostream>
#include <set>
#include <string>
#include <vector>

namespace fs = std::filesystem;

const inline bool is_executable(const fs::path& p)
{
    std::error_code ec;
    fs::file_status status = fs::status(p, ec);
    return !ec && fs::is_regular_file(status) && ((status.permissions() & (fs::perms::owner_exec | fs::perms::group_exec | fs::perms::others_exec)) != fs::perms::none);
}

const inline std::vector<std::string> split_path(const std::string& path)
{
    std::vector<std::string> paths;
    size_t start = 0, end = 0;
    while ((end = path.find(':', start)) != std::string::npos) {
        paths.push_back(path.substr(start, end - start));
        start = end + 1;
    }
    paths.push_back(path.substr(start));
    return paths;
}

std::set<std::string> get_executables(const std::string& PATH)
{
    std::set<std::string> executables;
    for (const auto& path : split_path(PATH)) {
        try {
            for (const auto& entry : fs::directory_iterator(path)) {
                if (is_executable(entry.path())) {
                    executables.insert(entry.path().filename().string());
                }
            }
        } catch (const fs::filesystem_error& e) {
            std::cerr << "Error accessing path " << path << ": " << e.what() << std::endl;
        }
    }
    return executables;
}

void diffpath(const std::string& PATH1, const std::string& PATH2)
{
    std::set<std::string> executables1 = get_executables(PATH1);
    std::set<std::string> executables2 = get_executables(PATH2);

    // Using set_symmetric_difference to get all unique executables in sorted order
    std::vector<std::string> all_unique;
    std::set_symmetric_difference(
        executables1.begin(), executables1.end(),
        executables2.begin(), executables2.end(),
        std::back_inserter(all_unique));

    for (const auto& exec : all_unique) {
        if (executables1.contains(exec)) {
            std::cout << exec << std::endl;
        } else {
            std::cout << "\t" << exec << std::endl;
        }
    }
}

int main(int argc, char* argv[])
{
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " PATH1 PATH2" << std::endl;
        return 1;
    }

    std::string PATH1 = argv[1];
    std::string PATH2 = argv[2];

    diffpath(PATH1, PATH2);

    return 0;
}
