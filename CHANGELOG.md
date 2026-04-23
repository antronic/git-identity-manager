# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.9] - 2026-04-23

### Changed
- GitHub Actions release workflow (`release.yml`): the generated GitHub Release body now
  automatically includes the relevant section extracted from `CHANGELOG.md` using `awk`,
  so release notes on GitHub always reflect the file instead of showing a generic message.

## [1.2.8] - 2026-04-23

### Changed
- `check_for_updates`: version comparison is now numeric semver (`version_gt`) instead of
  a string `!=` check, so `1.2.10` is correctly detected as newer than `1.2.9`.
- `fetch_changelog`: release notes are now sourced directly from the raw `CHANGELOG.md` in
  the repository rather than from the GitHub Releases API JSON body, ensuring the notes
  shown on upgrade always match what is written in the file.
- `CHANGELOG_URL` updated from the GitHub Releases API endpoint to the raw CHANGELOG.md URL.

### Added
- `version_gt()`: new helper that splits `X.Y.Z` into three integers and compares them
  component-by-component using decimal arithmetic (`10#$x`) to handle leading-zero edge cases.
- 8 new BATS tests: 4 for `fetch_changelog` (correct section extraction, no bleed-through,
  latest-section fallback, Unreleased skip) and 5 for `version_gt` (patch/minor/equal/lower/
  double-digit), plus 1 structural test for `version_gt` presence. (108 tests total)

## [1.2.7] - 2026-04-23

### Added
- **Profile Backup/Restore** (`[10] Backup / Restore Profiles` in TUI, `backup [path]` and `restore <file>` CLI commands):
  - `backup_profiles`: bundles all profiles, SSH conf files, and referenced SSH private/public keys
    into a timestamped `git-identity-manager-backup-<YYYYMMDD_HHMMSS>.tar.gz` archive.
  - `restore_profiles`: extracts an archive, reinstates profiles, SSH conf, and keys (with correct
    `600` / `644` permissions), and re-adds shell aliases to `$SHELL_PROFILE` if missing.
  - GPG private keys are intentionally excluded (they live in the system keychain); the output
    reminds users to export them separately with `gpg --export-secret-keys`.
  - 12 new BATS tests: 6 in `test_profiles.bats` (backup creation, archive content, empty-vault,
    missing-archive error, restore files, restore aliases) and 6 in `test_structure.bats`
    (function definitions, CLI parser and TUI registration). (100 tests total)

### Changed
- Main TUI menu reordered: `[10] Backup / Restore Profiles`, `[11] Settings`, `[0] Exit`
  so that Settings and Exit are always the last two items.

## [1.2.6] - 2026-04-23

### Added
- Startup UX: a transient `[i] Checking for updates...` message is now printed
  while the version check runs, preventing the blank-screen pause on launch.
  The message is overwritten by the main menu `clear` so it never lingers.
- Settings → `[3] Update Check Frequency`: choose how often the auto-update check
  runs on startup. Cycles through `everytime` (default) → `daily` → `weekly` and
  back. Setting is persisted to `~/.git-manager/config.env` as
  `UPDATE_CHECK_FREQUENCY`. A `.last_update_check` timestamp file in
  `~/.git-manager/` tracks when the last check occurred.
- Former `[3] Check for Updates Now` renumbered to `[4]` to accommodate the new
  frequency option.
- 6 new BATS tests covering: startup message display, frequency default, persistence,
  skip-when-recent (daily & weekly), and run-when-overdue (daily). (88 tests total)

## [1.2.5] - 2026-04-23

### Added
- Settings → Check for Updates Now: when already on the latest version, now shows
  `[✓] You are on the latest version!` with the current version number instead of
  silently returning with no feedback.
- `check_for_updates` accepts an optional `--explicit` flag; startup calls it without
  the flag (stays silent when up to date), the Settings menu calls it with `--explicit`
  (shows the confirmation message).
- 3 new BATS tests covering the explicit/silent behaviour split (82 tests total).

## [1.2.4] - 2026-04-23

### Fixed
- `fetch_changelog`: release notes always showed "No release notes available" after upgrade
  because the GitHub API returns pretty-printed JSON (`"body": "..."` with a space after `:`),
  but the grep pattern was `"body":"` (no space) so it never matched.
  Replaced the fragile `grep -o '"body":"[^"]*"'` with a `grep | sed` pipeline that strips
  leading whitespace and the optional space after `:`, and also handles escaped quotes (`\"`)
  in the body text.
- Added a regression BATS test (`fetch_changelog parses body from pretty-printed JSON`) to
  prevent the same issue from reappearing (79 tests total).

## [1.2.3] - 2026-04-23

### Changed
- README: update TUI screenshot to v1.2.2 (active profile status line, Settings option, new prompt)
- README: add Settings menu and active profile display to the Features list
- README: update test-suite table to reflect current 78 tests across all 5 suites

## [1.2.2] - 2026-04-23

### Fixed
- `check_for_updates`: typing `n` at the upgrade prompt still triggered the upgrade because the
  default value was `Y` — if `read` returned an empty string for any reason (e.g. a buffered
  `Enter` keypress in stdin), the script silently defaulted to `Y` and proceeded with the download.
  Default is now `N`; an explicit `y` or `Y` is required to upgrade.
  Prompt changed from `(Y/n)` to `(y/N)` to reflect the safe default.
  Added `-r` flag to `read` to prevent backslash interpretation.

## [1.2.1] - 2026-04-23

### Changed
- README: remove `color=lightgrey` override from license badge so it uses the default shield colour

## [1.2.0] - 2026-04-23

### Added
- **Settings menu** (`[10] Settings` in TUI, `git-identity-manager settings` CLI command)
  - Toggle auto-update check on startup (`AUTO_UPDATE_CHECK`)
  - Toggle changelog display after upgrade (`SHOW_CHANGELOG`)
  - Trigger a manual update check from within the menu
- `manage_settings()`: interactive sub-menu with live toggle state display
- `load_settings()`: reads `~/.git-manager/config.env` safely (no `source`, no code execution)
- `save_setting()`: persists a single key/value to `config.env`, updates in-memory state immediately
- `CONFIG_FILE` variable pointing to `~/.git-manager/config.env`
- Quick-switch alias template, multi-profile sample, and daily workflow in README
- Developer Guide section in README: prerequisites table, getting-started steps, test-running guide, shellcheck instructions, project structure tree, and contributing rules
- 13 new BATS tests covering `load_settings`, `save_setting`, settings-guarded `check_for_updates`, settings-guarded `show_changelog_once`, structural presence of all new symbols (70 tests total)

### Changed
- `check_for_updates()` respects the `AUTO_UPDATE_CHECK` setting (returns early when disabled)
- `show_changelog_once()` respects the `SHOW_CHANGELOG` setting (returns early when disabled)
- Main TUI menu prompt updated to `[0-9/10]` to accommodate the new Settings option

## [1.1.0] - 2024-01-01

### Added
- Renamed project from `git-manager` to `git-identity-manager` for clarity
- `check_for_updates()`: fetches and displays release notes before prompting to upgrade
- `show_changelog_once()`: displays "What's New" once per version on first run after upgrade
- `fetch_changelog()`: retrieves release body from GitHub Releases API without `jq`
- `release.sh`: interactive release automation script (preflight → version bump → validate → commit/tag/push)
- BATS test suite: `tests/` directory with unit and structural tests
- GitHub Actions `unit-tests` job in `ci.yml` (Ubuntu + macOS)
- Shields.io badges in README (release, downloads, stars, license, ShellCheck, CI)

### Changed
- All internal references, filenames, and CLI commands updated to `git-identity-manager`
- `release.sh` Validation phase now runs the full test suite before tagging

## [1.0.0] - 2023-12-01

### Added
- Initial release of Git Identity Manager
- TUI menu and CLI (`--cli`) mode
- Profile management: `setup`, `import`, `switch`, `view`, `modify`, `delete`
- SSH key generation and linking per identity
- GPG signing key binding per identity
- `doctor` command for environment diagnostics
- `keys` command to list/manage SSH keys
- Shell alias injection (`as-<nick>`, `as-<nick>-global`)
- Auto-update via `curl` from GitHub raw URL
- GitHub Actions: ShellCheck, CI (syntax check), Release, Stale, Welcome, Release Drafter
- Zero external dependencies (pure Bash)

[Unreleased]: https://github.com/antronic/git-identity-manager/compare/v1.2.9...HEAD
[1.2.9]: https://github.com/antronic/git-identity-manager/compare/v1.2.8...v1.2.9
[1.2.8]: https://github.com/antronic/git-identity-manager/compare/v1.2.7...v1.2.8
[1.2.7]: https://github.com/antronic/git-identity-manager/compare/v1.2.6...v1.2.7
[1.2.6]: https://github.com/antronic/git-identity-manager/compare/v1.2.5...v1.2.6
[1.2.5]: https://github.com/antronic/git-identity-manager/compare/v1.2.4...v1.2.5
[1.2.4]: https://github.com/antronic/git-identity-manager/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/antronic/git-identity-manager/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/antronic/git-identity-manager/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/antronic/git-identity-manager/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/antronic/git-identity-manager/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/antronic/git-identity-manager/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0
