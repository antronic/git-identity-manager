# Git Identity Manager - Architecture Context

This project is a zero-dependency Bash script (`git-identity-manager.sh`) that manages multiple Git identities, SSH keys, and GPG signatures.

## Core Rules & File Paths
When modifying this script, you must adhere to the following file structures:

1. **Profile Storage (`~/.git-manager/profiles/`)**
   - Each identity saves a small file here containing pure `git config` commands (e.g., `user.name`, `user.email`, `user.signingkey`).

2. **Isolated SSH Architecture (`~/.ssh/git-manager.d/`)**
   - We NEVER modify the standard `~/.ssh/config` directly, except to ensure `Include ~/.ssh/git-manager.d/*` is at the very top.
   - Every identity gets its own isolated file (e.g., `~/.ssh/git-manager.d/work.conf`).
   - All SSH configs MUST include `IdentitiesOnly yes` to prevent SSH Agent bleed.

3. **Shell Aliases (`~/.bashrc` or `~/.zshrc`)**
   - The script creates two aliases per profile:
     - Local: `alias as-<nickname>='source ...'`
     - Global: `alias as-<nickname>-global='sed ... | bash'`

## Code Conventions
- It operates as both an interactive TUI (Terminal User Interface) and a CLI tool.
- All new features must be modularized into a function (e.g., `new_feature()`).
- New functions must be added to BOTH the CLI argument parser (`case "$1" in`) and the interactive `while true; do` main menu loop.
- Use `clear` at the start of interactive functions and `read -p " Press Enter..."` at the end.
