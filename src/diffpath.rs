use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::Path;

fn is_executable(file_path: &Path) -> bool {
    if let Ok(metadata) = fs::metadata(file_path) {
        if metadata.is_file() {
            let permissions = metadata.permissions();
            return permissions.mode() & 0o111 != 0;
        }
    }
    false
}

fn list_executables(paths: &str) -> BTreeSet<String> {
    let mut executables = BTreeSet::new();
    for path in paths.split(':') {
        if let Ok(entries) = fs::read_dir(path) {
            for entry in entries.filter_map(Result::ok) {
                let file_path = entry.path();
                if is_executable(&file_path) {
                    if let Some(file_name) = file_path.file_name() {
                        if let Some(file_name_str) = file_name.to_str() {
                            executables.insert(file_name_str.to_string());
                        }
                    }
                }
            }
        }
    }
    executables
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: {} PATH1 PATH2", args[0]);
        std::process::exit(1);
    }

    let path1 = &args[1];
    let path2 = &args[2];

    let executables1 = list_executables(path1);
    let executables2 = list_executables(path2);

    let symmetric_difference: BTreeSet<_> = executables1
        .symmetric_difference(&executables2)
        .cloned()
        .collect();

    for exe in symmetric_difference {
        if executables2.contains(&exe) {
            println!("\t{}", exe);
        } else {
            println!("{}", exe);
        }
    }
}
