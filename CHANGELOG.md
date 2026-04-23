# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/antronic/git-identity-manager/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/antronic/git-identity-manager/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/antronic/git-identity-manager/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/antronic/git-identity-manager/releases/tag/v1.0.0
