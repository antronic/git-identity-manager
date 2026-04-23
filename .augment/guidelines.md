# Git Identity Manager — Workspace Guidelines

## Project Summary
A **zero-dependency, pure Bash** TUI/CLI tool (v1.1.0) that manages multiple Git identities on a single machine. It generates and isolates SSH (`ed25519`) and GPG keys per identity, switches `git config` values locally or globally, and injects shell aliases for instant switching.

- **Language**: Bash only — absolutely no external runtimes or package managers
- **Architecture**: Single-file (`git-identity-manager.sh`) — do NOT split into multiple files
- **Installer**: `install.sh` downloads `git-identity-manager.sh` to `~/.local/bin/git-identity-manager`
- **Repository**: https://github.com/antronic/git-identity-manager

---

## File & Directory Map

### Source Files
```
git-identity-manager.sh      ← Entire application — single source of truth
install.sh          ← One-liner curl installer
ARCHITECTURE.md     ← Architecture reference and constraints
```

### Runtime Paths (on user's machine)
| Path | Purpose |
|------|---------|
| `~/.git-manager/profiles/<nickname>` | Profile — pure `git config` shell commands |
| `~/.ssh/git-manager.d/<nickname>.conf` | Isolated SSH `Host` block per identity |
| `~/.ssh/id_ed25519_<nickname>` | Generated SSH private key |
| `~/.ssh/id_ed25519_<nickname>.pub` | Generated SSH public key |
| `~/.ssh/config` | **Never write directly** — only `Include` bootstrap at the top |
| `~/.bashrc` / `~/.zshrc` | Shell aliases: `as-<nick>` and `as-<nick>-global` |

---

## Key Variables
```bash
VERSION="1.1.0"
MANAGER_DIR="$HOME/.git-manager"
PROFILES_DIR="$MANAGER_DIR/profiles"
SSH_CONF_DIR="$HOME/.ssh/git-manager.d"
SHELL_PROFILE          # Auto-detected: ~/.bashrc or ~/.zshrc
CLI_MODE               # "true" in CLI path; "" (empty) = TUI/interactive mode
profiles=()            # Populated by get_profiles()
```

---

## Complete Function Reference
| Function | Signature | Role |
|----------|-----------|------|
| `get_profiles` | `get_profiles()` | Populates global `profiles[]` from `PROFILES_DIR` |
| `setup_identity` | `setup_identity()` | Interactive: generates SSH ed25519 + GPG keys |
| `import_identity` | `import_identity()` | Interactive: links existing SSH/GPG keys |
| `finalize_profile` | `finalize_profile $nick $name $email $gpg $ssh $mode` | Writes profile file, SSH conf, aliases |
| `switch_identity` | `switch_identity $profile $scope` | Sources/applies profile locally or globally |
| `view_profiles` | `view_profiles()` | Tabular listing of all profiles |
| `modify_identity` | `modify_identity()` | Updates name/email of existing profile |
| `delete_identity` | `delete_identity()` | Removes profile, SSH conf, optionally keys |
| `print_keys` | `print_keys()` | Displays SSH/GPG public keys |
| `run_doctor` | `run_doctor()` | Auto-fixes permissions, configs, broken aliases |
| `check_for_updates` | `check_for_updates()` | Silently checks and applies GitHub updates |
| `print_help` | `print_help()` | Prints CLI help text |
| `quick_guide` | `quick_guide()` | In-TUI how-to guide |

---

## CLI Interface
```
git-identity-manager setup               # Generate keys + create profile
git-identity-manager import              # Link existing SSH/GPG keys
git-identity-manager switch <profile>    # Apply profile to current repo (local)
git-identity-manager global <profile>    # Apply profile globally
git-identity-manager view                # List all profiles in a table
git-identity-manager doctor              # Health check + auto-fix
git-identity-manager update              # Force update check
git-identity-manager --help              # Show CLI help
```

---

## Code Conventions

### 1. Single-File Architecture
All logic lives in `git-identity-manager.sh`. Never extract to helper scripts.

### 2. Dual Registration for New Features
Every new function must be registered in **both**:
```bash
# CLI parser (bottom of git-identity-manager.sh)
case "$1" in
    myfeature) my_feature "$2"; exit 0 ;;

# TUI menu loop (bottom of git-identity-manager.sh)
case $choice in
    N) my_feature ;;
```

### 3. Interactive Function Pattern
```bash
my_feature() {
    clear
    echo "==================================================="
    echo " [ FEATURE ]  DESCRIPTION"
    echo "==================================================="
    echo ""
    # ... logic ...
    [[ -z "$CLI_MODE" ]] && read -p " Press Enter to return to the menu..."
}
```

### 4. Message Prefix Convention
| Prefix | Meaning |
|--------|---------|
| ` [?] ` | User prompt / question |
| ` [i] ` | Informational |
| ` [+] ` | Success |
| ` [!] ` | Error or warning |
| ` [*] ` | Status / in-progress |

### 5. SSH Safety Rule
Every SSH conf block written to `~/.ssh/git-manager.d/` MUST contain:
```
IdentitiesOnly yes
```

### 6. Version Bump & CHANGELOG Rule
Whenever `VERSION` is incremented in `git-identity-manager.sh`, you **MUST** also update `CHANGELOG.md`:
- Add a new `## [X.Y.Z] - YYYY-MM-DD` section at the top of the changelog (below the header)
- Group entries under `### Added`, `### Fixed`, `### Changed`, or `### Removed` as appropriate
- If `CHANGELOG.md` does not exist yet, create it using [Keep a Changelog](https://keepachangelog.com) format

```markdown
## [1.2.0] - 2026-04-23
### Added
- Brief description of the new feature

### Fixed
- Brief description of the bug fix
```

### 7. Profile File Format
Profile files contain ONLY `git config` commands — no secrets, no private key material:
```bash
git config user.name "Your Name"
git config user.email "you@example.com"
git config user.signingkey ABCDEF1234567890  # optional
git config commit.gpgsign true               # optional
```

---

## Hard Constraints — Never Violate
- **No dependencies** — never add npm, pip, gem, cargo, or any package manager
- **No file splits** — `git-identity-manager.sh` stays as a single file
- **No direct `~/.ssh/config` writes** — the `Include` line is bootstrapped at startup only
- **No secrets in tracked files** — no SSH private keys or passwords
- **Bash only** — no Python, Node.js, Ruby, or any other language
