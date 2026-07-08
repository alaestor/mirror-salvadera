# Global Agent Guidelines

## Grep

The harness' grep tool sucks. Use the terminal.

## Terminal Tool Usage

The `terminal` tool has a strict constraint: the `cd` parameter **must** be one of the project root directories. You cannot use it to navigate directly into subdirectories.

### Navigating Subdirectories
To execute a command in a subdirectory, use the `cd` command within the `command` string.

**Pattern:**
`terminal{ cd: "root_dir", command: "cd subdirectory && actual-command" }`

### Examples

- **Run a test in a subfolder:**
  `terminal{ cd: "/home/user/Projects/alaestor-codeberg/salvadera", command: "cd alce && nix run .#test" }`

- **List files in a specific directory:**
  `terminal{ cd: "/home/user/Projects/alaestor-codeberg/salvadera", command: "cd alce/src && ls" }`

- **Run a build command in a package directory:**
  `terminal{ cd: "/home/user/Projects/alaestor-codeberg/salvadera", command: "cd alce/pkgs && ls" }`

### Summary Table
| Goal | Approach |
| :--- | :--- |
| Run in root | `cd: "root_dir", command: "ls"` |
| Run in subfolder | `cd: "root_dir", command: "cd subfolder && ls"` |
| Read a file | Use `read_file{path: "root_dir/path/to/file"}` |
| Search code | Use `grep{regex: "...", include_pattern: "root_dir/**/*"}` |
