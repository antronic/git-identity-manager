# 🔮 Git Identity Manager

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
- [🤝 Maintainer](#-maintainer)
- [📄 License](#-license)

## ✨ Features
- [x] **Interactive TUI:** Easy-to-use terminal menu for managing accounts.
- [x] **CLI Support:** Switch profiles instantly via terminal commands.
- [x] **SSH Key Generation:** Automatically generates and links `ed25519` SSH keys.
- [x] **GPG Signatures:** Automates passphraseless or secure GPG key creation for signed commits.
- [x] **Anti-Bleed Architecture:** Uses isolated `Include` files and `IdentitiesOnly yes` to prevent the SSH Agent from using the wrong keys.
- [x] **System Doctor:** Built-in health check to repair file permissions, missing configs, and broken aliases.
- [x] **Import Existing Keys:** Securely link your existing SSH/GPG keys to a new profile.
- [x] **Auto-Updater:** Self-upgrades to the latest version directly from GitHub.
- [ ] *(Next)* **Profile Backup/Restore:** Export profiles to a secure `.tar.gz` archive.
- [ ] *(Next)* **Repo Auto-Detection:** Automatically detect which identity belongs to a folder upon `cd`.

## ⚠️ Known Issues
* **GPG Pinentry on Headless Servers:** If generating a GPG key *with* a passphrase on a headless Linux server, you may need to install/configure `pinentry-tty` if the system prompt fails to appear.
* **macOS Keychain:** Older macOS versions might require a manual restart of the SSH agent to accept new `UseKeychain` parameters.

## 🚀 Installation

Run this one-line command to install `git-manager` to your `~/.local/bin`:

```bash
curl -sL https://raw.githubusercontent.com/antronic/git-identity-manager/main/install.sh | bash
```
*(Note: Ensure `~/.local/bin` is in your system's `$PATH` or use the full path to the script)*

## 📖 Usage

### 🖥️ Interactive TUI

Launch the interactive menu by running `git-manager` with no arguments:

```bash
git-manager
```

```
 ==================================================================
              G I T   I D E N T I T Y   M A N A G E R
                         Version: 1.1.0
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
     [ 0 ] Exit

 ==================================================================
 -> Select an option [0-9]:
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
git-manager setup                  # Interactive setup (generate new keys)
git-manager import                 # Interactive import (link existing keys)
git-manager switch <profile>       # Apply profile to current local repo
git-manager global <profile>       # Apply profile globally
git-manager view                   # List all configured profiles
git-manager doctor                 # Run health check and auto-fix
git-manager update                 # Force check for updates
git-manager --help                 # Show help message
```

#### Quick-switch aliases
After setup, shell aliases are automatically injected into your `.zshrc` / `.bashrc`:

```bash
as-work                 # Apply 'work' profile to current local repo
as-work-global          # Apply 'work' profile globally
```

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
               │  git-manager setup              │
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
 │  git@github.com-work:         │   │  git-manager switch work    (CLI) │
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
Unlike native Git `includeIf` (which restricts you to specific folder paths) or NPM wrappers (which require heavy Node.js dependencies), `git-manager` uses pure Bash to:
1. Isolate SSH hosts using `.ssh/git-manager.d/*.conf` files.
2. Force `IdentitiesOnly yes` so GitHub doesn't misidentify you.
3. Inject fast switching aliases into your `.bashrc` / `.zshrc`.

## 🤝 Maintainer
Created and maintained by [antronic](https://github.com/antronic). Contributions, bug reports, and feature requests are highly encouraged—feel free to open an issue or submit a pull request!

## 📄 License
This project is licensed under the [MIT License](LICENSE).
