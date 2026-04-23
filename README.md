# 🔮 Git Identity Manager

[![GitHub Release](https://img.shields.io/github/v/release/antronic/git-identity-manager?style=flat-square&color=blue)](https://github.com/antronic/git-identity-manager/releases/latest)
[![GitHub Downloads (all releases)](https://img.shields.io/github/downloads/antronic/git-identity-manager/total?style=flat-square&label=downloads&color=brightgreen)](https://github.com/antronic/git-identity-manager/releases)
[![GitHub Stars](https://img.shields.io/github/stars/antronic/git-identity-manager?style=flat-square&color=yellow)](https://github.com/antronic/git-identity-manager/stargazers)
[![License: MIT](https://img.shields.io/github/license/antronic/git-identity-manager?style=flat-square)](LICENSE)
[![ShellCheck](https://img.shields.io/github/actions/workflow/status/antronic/git-identity-manager/shellcheck.yml?style=flat-square&label=shellcheck)](https://github.com/antronic/git-identity-manager/actions/workflows/shellcheck.yml)
[![CI](https://img.shields.io/github/actions/workflow/status/antronic/git-identity-manager/ci.yml?style=flat-square&label=ci)](https://github.com/antronic/git-identity-manager/actions/workflows/ci.yml)

A zero-dependency, pure Bash TUI/CLI tool to effortlessly manage multiple Git identities on a single machine. Instantly generate, isolate, and switch between your work, personal, and freelance Git profiles with full SSH and GPG support.

> [!NOTE]
> This project was **built by AI**. Bugs and rough edges are expected — contributions and bug reports are very welcome!

## 📋 Table of Contents
- [✨ Features](#-features)
- [⚠️ Known Issues](#️-known-issues)
- [🚀 Installation](#-installation)
- [📖 Usage](#-usage)
  - [🖥️ Interactive TUI](#️-interactive-tui)
  - [⚡ CLI Commands](#-cli-commands)
- [🗺️ Working Flow](#️-working-flow)
- [🧠 How it Works](#-how-it-works-under-the-hood)
- [🛠️ Developer Guide](#️-developer-guide)
  - [Prerequisites](#prerequisites)
  - [Getting Started](#getting-started)
  - [Running Tests](#running-tests)
  - [Static Analysis](#static-analysis)
  - [Project Structure](#project-structure)
  - [Contributing](#contributing)
- [🤝 Maintainer](#-maintainer)
- [📄 License](#-license)

## ✨ Features
- [x] **Interactive TUI:** Easy-to-use terminal menu for managing accounts. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **CLI Support:** Switch profiles instantly via terminal commands. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **SSH Key Generation:** Automatically generates and links `ed25519` SSH keys. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **GPG Signatures:** Automates passphraseless or secure GPG key creation for signed commits. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **Anti-Bleed Architecture:** Uses isolated `Include` files and `IdentitiesOnly yes` to prevent the SSH Agent from using the wrong keys. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **System Doctor:** Built-in health check to repair file permissions, missing configs, and broken aliases. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **Import Existing Keys:** Securely link your existing SSH/GPG keys to a new profile. — [`v1.0.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0)
- [x] **Auto-Updater:** Self-upgrades to the latest version directly from GitHub (explicit `y` confirmation required). — [`v1.1.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.1.0)
- [x] **Settings Menu:** Toggle auto-update checks, changelog display, and update-check frequency (`everytime` / `daily` / `weekly`); trigger manual update checks — all persisted to `~/.git-manager/config.env`. — [`v1.2.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.2.0)
- [x] **Active Profile Display:** Current local and global identities shown on the main menu and in the Switch screen. — [`v1.2.0`](https://github.com/antronic/git-identity-manager/releases/tag/v1.2.0)
- [x] **Profile Backup/Restore:** Export all profiles, SSH configs, and keys to a timestamped `.tar.gz` archive; restore on any machine with a single command. — [`v1.2.7`](https://github.com/antronic/git-identity-manager/releases/tag/v1.2.7)
- [ ] *(Next)* **Repo Auto-Detection:** Automatically detect which identity belongs to a folder upon `cd`.

## ⚠️ Known Issues
* **GPG Pinentry on Headless Servers:** If generating a GPG key *with* a passphrase on a headless Linux server, you may need to install/configure `pinentry-tty` if the system prompt fails to appear.
* **macOS Keychain:** Older macOS versions might require a manual restart of the SSH agent to accept new `UseKeychain` parameters.

## 🚀 Installation

Run this one-line command to install `git-identity-manager` to your `~/.local/bin`:

```bash
curl -sL https://raw.githubusercontent.com/antronic/git-identity-manager/main/install.sh | bash
```
*(Note: Ensure `~/.local/bin` is in your system's `$PATH` or use the full path to the script)*

## 📖 Usage

### 🖥️ Interactive TUI

Launch the interactive menu by running `git-identity-manager` with no arguments:

```bash
git-identity-manager
```

```
 ==================================================================
              G I T   I D E N T I T Y   M A N A G E R
                         Version: 1.2.8
 ==================================================================
  Active  →  local: work  |  global: personal
 ==================================================================

     [ 1 ] Setup New Account (Generate Keys)
     [ 2 ] Import Existing Account (Link Keys)
     [ 3 ] Switch Account (Local / Global)
     [ 4 ] View All Profiles
     [ 5 ] Modify a Profile
     [ 6 ] Delete a Profile
     [ 7 ] View Public Keys (SSH/GPG)
     [ 8 ] Run Doctor (Validate & Auto-Fix)
     [ 9 ] Quick Guide & How-To
     [10 ] Backup / Restore Profiles
     [11 ] Settings
     [ 0 ] Exit

 ==================================================================
 -> Select an option [0-9/10/11]:
```

#### Setting Up a New Profile (Option 1)
1. Select **[1] Setup New Account**
2. Enter a short nickname (e.g., `work`, `personal`)
3. Provide your Git name and email
4. Choose to generate an SSH key (`ed25519`) — recommended
5. Choose to generate a GPG signing key — optional
6. Copy the displayed public keys and add them to GitHub / GitLab

#### Switching Identity (Option 3)
1. Select **[3] Switch Account**
2. Pick the target profile from the list
3. Choose the scope:
   - **Local** — applies only to the current git repository
   - **Global** — applies to all repositories on the machine

---

### ⚡ CLI Commands

```bash
git-identity-manager setup                  # Interactive setup (generate new keys)
git-identity-manager import                 # Interactive import (link existing keys)
git-identity-manager switch <profile>       # Apply profile to current local repo
git-identity-manager global <profile>       # Apply profile globally
git-identity-manager view                   # List all configured profiles
git-identity-manager doctor                 # Run health check and auto-fix
git-identity-manager update                 # Force check for updates
git-identity-manager settings               # Open settings menu
git-identity-manager backup [path]          # Backup all profiles to .tar.gz (default: current dir)
git-identity-manager restore <file>         # Restore profiles from a .tar.gz backup archive
git-identity-manager --help                 # Show help message
```

#### ⚡ Quick-switch aliases

After each profile is created, **two aliases per profile** are automatically appended to your `.zshrc` / `.bashrc`:

```
as-<nickname>           → apply profile to current repo only  (local .git/config)
as-<nickname>-global    → apply profile system-wide           (global git config)
```

**Alias template** (what gets written to your shell RC file):

```bash
# Auto-generated by git-identity-manager — do not edit manually
alias as-work='source "$HOME/.git-manager/profiles/work" && echo " [+] Switched to identity: work (Local)"'
alias as-work-global='sed "s/git config/git config --global/g" "$HOME/.git-manager/profiles/work" | bash && echo " [+] Switched to identity: work (Global)"'
```

**Sample — three profiles side by side:**

```bash
# ~/.zshrc (auto-generated entries)
alias as-work='source "$HOME/.git-manager/profiles/work" ...'
alias as-work-global='sed ... "$HOME/.git-manager/profiles/work" | bash ...'

alias as-personal='source "$HOME/.git-manager/profiles/personal" ...'
alias as-personal-global='sed ... "$HOME/.git-manager/profiles/personal" | bash ...'

alias as-freelance='source "$HOME/.git-manager/profiles/freelance" ...'
alias as-freelance-global='sed ... "$HOME/.git-manager/profiles/freelance" | bash ...'
```

**Daily workflow:**

```bash
# 1. Clone the repo with the right SSH key
git clone git@github.com-work:MyOrg/project.git
cd project

# 2. Stamp the repo with your work identity (local only)
as-work
#  [+] Switched to identity: work (Local)

# 3. Verify
git config user.name    # Alice Work
git config user.email   # alice@work.com

# --- OR --- set a global default for all repos on this machine
as-personal-global
#  [+] Switched to identity: personal (Global)
```

> **Tip:** `as-<nick>` (local) takes effect immediately in the current shell — no need to re-source your RC file. `as-<nick>-global` writes to `~/.gitconfig` so it applies to every new repo.

#### Cloning with a profile's SSH identity
```bash
# Standard clone — may use the wrong key if multiple are loaded
git clone git@github.com:Org/Repo.git

# Clone scoped to a specific identity (uses the host alias from work.conf)
git clone git@github.com-work:Org/Repo.git
```

## 🗺️ Working Flow

```
  ╔══════════════════════════════════════════════════════════════════╗
  ║               PHASE 1 — Create a Profile                         ║
  ╚═══════════════════════════╤══════════════════════════════════════╝
                              │
               ┌──────────────▼──────────────────┐
               │  git-identity-manager setup     │
               │  (TUI option 1  or  CLI)        │
               │  • Enter nickname, name, email  │
               │  • Generate SSH ed25519 key     │
               │  • Generate GPG signing key     │
               └──────────────┬──────────────────┘
                              │  writes to
          ┌───────────────────┼──────────────────────┐
          │                   │                      │
 ┌────────▼──────────┐ ┌──────▼──────────────┐ ┌────▼──────────────────┐
 │ ~/.ssh/           │ │ ~/.git-manager/     │ │ ~/.zshrc / ~/.bashrc  │
 │ git-manager.d/    │ │ profiles/work       │ │                       │
 │   work.conf       │ │                     │ │ alias as-work='...'   │
 │                   │ │ git config          │ │ alias as-work-        │
 │ Host              │ │   user.name  "..."  │ │       global='...'    │
 │ github.com-work   │ │   user.email "..."  │ └───────────────────────┘
 │ IdentitiesOnly yes│ │   signingkey "..."  │
 └───────────────────┘ └─────────────────────┘
```

```
  ╔══════════════════════════════════════════════════════════════════╗
  ║               PHASE 2 — Daily Use                                ║
  ╚═══════════════════════════╤══════════════════════════════════════╝
                              │
         ┌────────────────────┴─────────────────────┐
         │                                          │
 ┌───────▼───────────────────────┐   ┌──────────────▼────────────────────┐
 │  Clone with SSH identity host  │   │  Apply identity to a repo        │
 │                               │   │                                   │
 │  git clone                    │   │  cd MyRepo                        │
 │  git@github.com-work:         │   │  git-identity-manager switch work (CLI) │
 │    Org/Repo.git               │   │  # or: as-work             (alias)│
 └───────────────────────────────┘   └──────────────┬────────────────────┘
                                                    │
                                     ┌──────────────▼────────────────────┐
                                     │  Applied to .git/config:          │
                                     │  user.name  = "Your Work Name"    │
                                     │  user.email = "you@work.com"      │
                                     │  signingkey = <GPG Key ID>        │
                                     └───────────────────────────────────┘
```

## 🧠 How it Works (Under the Hood)
Unlike native Git `includeIf` (which restricts you to specific folder paths) or NPM wrappers (which require heavy Node.js dependencies), `git-identity-manager` uses pure Bash to:
1. Isolate SSH hosts using `.ssh/git-manager.d/*.conf` files.
2. Force `IdentitiesOnly yes` so GitHub doesn't misidentify you.
3. Inject fast switching aliases into your `.bashrc` / `.zshrc`.

## 🛠️ Developer Guide

### Prerequisites

| Tool | Min version | Required | Notes |
|------|-------------|----------|-------|
| `bash` | 4.0 | ✅ | macOS ships with 3.x — install a newer one via `brew install bash` if tests fail |
| `git` | 2.x | ✅ | Any modern version |
| `bats-core` | 1.0 | ✅ | Required to run the test suite |
| `shellcheck` | 0.7 | Recommended | Used by the ShellCheck CI job; install locally to catch issues early |
| `ssh-keygen` | — | ✅ | Bundled with OpenSSH (present on all supported OSes) |
| `gpg` | 2.x | ✅ | GnuPG — required for GPG key generation |
| `curl` | — | ✅ | Used by the auto-updater and changelog fetcher |

**Install test tooling:**

```bash
# macOS
brew install bats-core shellcheck

# Ubuntu / Debian
sudo apt-get install -y bats shellcheck
```

---

### Getting Started

```bash
# 1. Fork the repo on GitHub, then clone your fork
git clone https://github.com/<your-username>/git-identity-manager.git
cd git-identity-manager

# 2. Verify the script is syntactically valid
bash -n git-identity-manager.sh && echo "Syntax OK"

# 3. Run the full test suite
bash tests/run_tests.sh
```

> The script is a **single self-contained file** (`git-identity-manager.sh`). There are no build steps, no package installs, and no generated artefacts — just read, edit, and test.

---

### Running Tests

The test suite uses [BATS (Bash Automated Testing System)](https://bats-core.readthedocs.io/).

```bash
# Run every test suite at once (recommended before any commit)
bash tests/run_tests.sh

# Auto-install bats-core if it is not yet present
bash tests/run_tests.sh --install-bats

# Run a single suite
bats tests/test_structure.bats
bats tests/test_profiles.bats
bats tests/test_switch.bats
bats tests/test_release.bats
bats tests/test_changelog.bats

# Run one specific test by name filter
bats --filter "finalize_profile" tests/test_profiles.bats
```

**Test suites at a glance:**

| Suite | Tests | What it covers |
|-------|------:|----------------|
| `test_structure.bats` | 29 | Syntax checks, VERSION format, SSH safety rules, CLI registration, Settings, Backup/Restore, `version_gt` symbols |
| `test_profiles.bats` | 20 | `get_profiles`, `finalize_profile`, alias injection, GPG status detection, `backup_profiles`, `restore_profiles` |
| `test_switch.bats` | 16 | `switch_identity` local & global, `get_active_profile`, `active_status_line` |
| `test_release.bats` | 11 | `bump_version` patch / minor / major logic |
| `test_changelog.bats` | 32 | `show_changelog_once`, `fetch_changelog` (CHANGELOG.md parsing), `version_gt`, Settings guards, update-check frequency |
| **Total** | **108** | |

> **Note:** Tests are fully isolated — each test gets its own `$HOME` in a temp directory and never touches your real `~/.git-manager`, `~/.ssh`, or shell RC files.

---

### Static Analysis

```bash
# Run ShellCheck locally (mirrors what the CI job checks)
shellcheck git-identity-manager.sh
shellcheck install.sh
shellcheck release.sh
```

The CI pipeline runs ShellCheck at **warning** severity on every push and pull request. Fix all warnings before opening a PR.

---

### Project Structure

```
git-identity-manager/
├── git-identity-manager.sh   # ← entire tool lives here (single-file architecture)
├── install.sh                # one-line curl installer
├── release.sh                # local release automation (bump, tag, push)
├── CHANGELOG.md              # Keep a Changelog format
├── tests/
│   ├── run_tests.sh          # test runner (wraps bats, handles install)
│   ├── helpers/
│   │   └── load.bash         # shared BATS helpers (fake HOME, profile fixtures)
│   ├── test_structure.bats
│   ├── test_profiles.bats
│   ├── test_switch.bats
│   ├── test_release.bats
│   └── test_changelog.bats
└── .github/
    └── workflows/
        ├── ci.yml            # syntax + unit tests on Ubuntu & macOS
        ├── shellcheck.yml    # static analysis on every .sh change
        ├── release.yml       # GitHub Release creation on version tags
        └── welcome.yml       # first-time contributor welcome message
```

---

### Contributing

1. **Fork** the repo and create a branch from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```
2. **Make your changes** in `git-identity-manager.sh` (single-file rule — no new `.sh` helpers).
3. **Run tests** — all 108 must pass:
   ```bash
   bash tests/run_tests.sh
   ```
4. **Update `CHANGELOG.md`** if you bump `VERSION` (see the Keep a Changelog format already in the file).
5. **Open a Pull Request** with a title that follows [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add profile backup/restore command
   fix: correct GPG key export on macOS
   docs: expand quick-switch alias examples
   ```

> CI will automatically check syntax, run all tests, and lint your PR title. A failing check blocks the merge.

---

## 🤝 Maintainer
Created and maintained by [antronic](https://github.com/antronic). Contributions, bug reports, and feature requests are highly encouraged—feel free to open an issue or submit a pull request!

## 📄 License
This project is licensed under the [MIT License](LICENSE).
