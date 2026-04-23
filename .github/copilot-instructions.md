# Git Identity Manager — Copilot Instructions

## Project Overview
A **zero-dependency, pure Bash** TUI/CLI tool (v1.1.0) for managing multiple Git identities on one machine.
Handles SSH key generation (`ed25519`), GPG signing key setup, and `git config` switching.

- **Entry point**: `git-identity-manager.sh` — single-file architecture; do NOT split into multiple files
- **Installer**: `install.sh` — downloads `git-identity-manager.sh` to `~/.local/bin/git-identity-manager`
- **Language**: Bash only — no npm, pip, gem, cargo, or any external runtime

## Runtime File Paths
| Path | Purpose |
|------|---------|
| `~/.git-manager/profiles/<nickname>` | Profile file — pure `git config` shell commands |
| `~/.ssh/git-manager.d/<nickname>.conf` | Isolated SSH `Host` block per identity |
| `~/.ssh/id_ed25519_<nickname>` | Generated SSH private key |
| `~/.ssh/id_ed25519_<nickname>.pub` | Generated SSH public key |
| `~/.ssh/config` | Never write directly — only an `Include` bootstrap at the top |
| `~/.bashrc` / `~/.zshrc` | Shell aliases: `as-<nick>` (local) and `as-<nick>-global` |

## Key Script Variables
```bash
VERSION="1.1.0"
MANAGER_DIR="$HOME/.git-manager"
PROFILES_DIR="$MANAGER_DIR/profiles"
SSH_CONF_DIR="$HOME/.ssh/git-manager.d"
SHELL_PROFILE   # Auto-detected: ~/.bashrc or ~/.zshrc
CLI_MODE        # "true" in CLI path; empty string means TUI/interactive mode
profiles=()     # Array populated by get_profiles()
```

## Function Inventory
| Function | Role |
|----------|------|
| `get_profiles()` | Populates `profiles[]` from `PROFILES_DIR` |
| `setup_identity()` | Generates SSH ed25519 + GPG keys for a new profile |
| `import_identity()` | Links existing SSH/GPG keys to a new profile |
| `finalize_profile()` | Writes profile file, SSH conf, and shell aliases |
| `switch_identity($profile, $scope)` | Sources/applies a profile locally or globally |
| `view_profiles()` | Tabular listing of all profiles |
| `modify_identity()` | Updates name/email of an existing profile |
| `delete_identity()` | Removes a profile and its associated files |
| `print_keys()` | Displays SSH/GPG public keys for a profile |
| `run_doctor()` | Auto-fixes SSH permissions, configs, and broken aliases |
| `check_for_updates()` | Silently checks and applies updates from GitHub |
| `print_help()` | Prints CLI usage/help text |
| `quick_guide()` | In-TUI how-to guide |

## CLI Commands
```
git-identity-manager setup               # Generate new keys and create profile
git-identity-manager import              # Link existing SSH/GPG keys
git-identity-manager switch <profile>    # Apply profile to current repo (local scope)
git-identity-manager global <profile>    # Apply profile globally
git-identity-manager view                # List all profiles in a table
git-identity-manager doctor              # Health check + auto-fix
git-identity-manager update              # Force update check
git-identity-manager --help              # Show CLI help
```

## Code Conventions
1. **Single-file rule** — all code stays in `git-identity-manager.sh`. Never create helper scripts.
2. **Dual registration** — every new function MUST be added to both:
   - The CLI `case "$1" in` argument parser (bottom of `git-identity-manager.sh`)
   - The TUI `while true; do` main menu loop (bottom of `git-identity-manager.sh`)
3. **Interactive function pattern**:
   ```bash
   my_feature() {
       clear
       echo "==================================================="
       echo " [ FEATURE ]  DESCRIPTION"
       echo "==================================================="
       # ... logic ...
       [[ -z "$CLI_MODE" ]] && read -p " Press Enter to return to the menu..."
   }
   ```
4. **Message prefix convention**:
   - ` [?] ` — User prompt / question
   - ` [i] ` — Informational message
   - ` [+] ` — Success
   - ` [!] ` — Error or warning
   - ` [*] ` — Status / in-progress
5. **SSH safety** — every generated SSH conf block MUST include `IdentitiesOnly yes`
6. **Profile purity** — profile files contain ONLY `git config` commands (name, email, signingkey)
7. **Version bump & CHANGELOG** — whenever `VERSION` is incremented in `git-identity-manager.sh`, you MUST also update `CHANGELOG.md`:
   - Add a new `## [X.Y.Z] - YYYY-MM-DD` section at the top (below the header)
   - Group changes under `### Added`, `### Fixed`, `### Changed`, or `### Removed`
   - Create `CHANGELOG.md` using [Keep a Changelog](https://keepachangelog.com) format if it does not exist yet

## Hard Constraints
- Never add any package manager dependency (npm, pip, gem, cargo, etc.)
- Never split `git-identity-manager.sh` into multiple files
- Never write directly to `~/.ssh/config` (the `Include` line is bootstrapped at script startup only)
- Never store SSH private key content or passwords in profile files or any tracked file
- Never use Python, Node.js, Ruby, or any language other than Bash
- Always include `IdentitiesOnly yes` in every SSH conf block written to `~/.ssh/git-manager.d/`
