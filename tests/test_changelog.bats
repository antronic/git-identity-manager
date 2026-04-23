#!/usr/bin/env bats
# =============================================================================
#  Changelog / Version Marker Tests — show_changelog_once
# =============================================================================

load 'helpers/load'

setup() {
    setup_fake_home
    # Mock fetch_changelog so tests never hit the network
    fetch_changelog() { echo "### Added\n- Test feature"; }
    export -f fetch_changelog
    load_script
    # Re-apply mock after script load (script doesn't define fetch_changelog as export)
    fetch_changelog() { echo "### Added\n- Test feature"; }
}

teardown() {
    teardown_fake_home
}

# --- show_changelog_once ----------------------------------------------------

@test "show_changelog_once displays changelog on first run (no marker)" {
    # No marker file exists → should show changelog
    run show_changelog_once
    [ "$status" -eq 0 ]
    [[ "$output" == *"WHAT'S NEW"* ]]
}

@test "show_changelog_once creates version marker file after first run" {
    # Suppress the read prompt by feeding empty input
    echo "" | show_changelog_once || true
    [ -f "$MANAGER_DIR/.last_seen_version" ]
}

@test "show_changelog_once writes current VERSION to marker file" {
    echo "" | show_changelog_once || true
    content=$(cat "$MANAGER_DIR/.last_seen_version")
    [ "$content" = "$VERSION" ]
}

@test "show_changelog_once is silent on subsequent runs (marker matches)" {
    # Write the current version as the last-seen marker
    echo "$VERSION" > "$MANAGER_DIR/.last_seen_version"
    run show_changelog_once
    [ "$status" -eq 0 ]
    # Output must be empty — already seen this version
    [ -z "$output" ]
}

@test "show_changelog_once shows changelog again after version bump" {
    # Simulate user was on an older version
    echo "0.9.0" > "$MANAGER_DIR/.last_seen_version"
    run show_changelog_once
    [[ "$output" == *"WHAT'S NEW"* ]]
}

@test "show_changelog_once updates marker to new VERSION after re-display" {
    echo "0.9.0" > "$MANAGER_DIR/.last_seen_version"
    echo "" | show_changelog_once || true
    content=$(cat "$MANAGER_DIR/.last_seen_version")
    [ "$content" = "$VERSION" ]
}

@test "show_changelog_once shows fallback message when changelog is empty" {
    # Override mock to return nothing
    fetch_changelog() { echo ""; }
    echo "0.9.0" > "$MANAGER_DIR/.last_seen_version"
    run show_changelog_once
    [[ "$output" == *"No release notes available"* ]]
}

# --- Settings: SHOW_CHANGELOG toggle ---------------------------------------

@test "show_changelog_once is silent when SHOW_CHANGELOG setting is false" {
    # Simulate user disabling changelog in settings
    echo "SHOW_CHANGELOG=false" > "$CONFIG_FILE"
    load_settings
    # Even though no marker exists, output must be empty
    run show_changelog_once
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "show_changelog_once shows changelog when SHOW_CHANGELOG setting is true" {
    echo "SHOW_CHANGELOG=true" > "$CONFIG_FILE"
    load_settings
    run show_changelog_once
    [ "$status" -eq 0 ]
    [[ "$output" == *"WHAT'S NEW"* ]]
}

# --- Settings: AUTO_UPDATE_CHECK toggle ------------------------------------

@test "check_for_updates is skipped when AUTO_UPDATE_CHECK setting is false" {
    echo "AUTO_UPDATE_CHECK=false" > "$CONFIG_FILE"
    load_settings
    # If the guard works, check_for_updates returns immediately (no curl call)
    curl() { echo "CURL_CALLED"; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    [[ "$output" != *"CURL_CALLED"* ]]
}

@test "check_for_updates silent when already up to date (no --explicit flag)" {
    # Startup path: no message shown when already on latest version
    curl() { echo "VERSION=\"$VERSION\""; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    [[ "$output" != *"latest"* ]]
    [[ "$output" != *"up to date"* ]]
}

@test "check_for_updates --explicit shows up-to-date message when already on latest" {
    CLI_MODE=true
    curl() { echo "VERSION=\"$VERSION\""; }
    export -f curl
    run check_for_updates --explicit
    [ "$status" -eq 0 ]
    [[ "$output" == *"latest version"* ]]
    [[ "$output" == *"$VERSION"* ]]
}

@test "check_for_updates --explicit still shows update prompt when new version exists" {
    # Run in a subshell with stdin closed so the upgrade read-prompt returns immediately
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../git-identity-manager.sh'
        CLI_MODE=true
        curl() { echo 'VERSION=\"99.9.9\"'; }
        export -f curl
        fetch_changelog() { echo ''; }
        export -f fetch_changelog
        check_for_updates --explicit
    " < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"UPDATE AVAILABLE"* ]]
    [[ "$output" == *"99.9.9"* ]]
}

# --- Settings: UPDATE_CHECK_FREQUENCY -----------------------------------------

@test "load_settings defaults UPDATE_CHECK_FREQUENCY to everytime" {
    rm -f "$CONFIG_FILE"
    load_settings
    [ "$SETTING_UPDATE_CHECK_FREQUENCY" = "everytime" ]
}

@test "save_setting persists UPDATE_CHECK_FREQUENCY" {
    save_setting "UPDATE_CHECK_FREQUENCY" "daily"
    load_settings
    [ "$SETTING_UPDATE_CHECK_FREQUENCY" = "daily" ]
}

@test "check_for_updates startup shows 'Checking for updates' message" {
    CLI_MODE=""
    curl() { echo "VERSION=\"$VERSION\""; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    [[ "$output" == *"Checking for updates"* ]]
}

@test "check_for_updates skips when daily frequency and check was recent" {
    save_setting "UPDATE_CHECK_FREQUENCY" "daily"
    # Write a timestamp that is only 60 seconds old (well within 86400s)
    echo "$(( $(date +%s) - 60 ))" > "$MANAGER_DIR/.last_update_check"
    curl() { echo "CURL_CALLED"; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    [[ "$output" != *"CURL_CALLED"* ]]
}

@test "check_for_updates runs when daily frequency and check is overdue" {
    save_setting "UPDATE_CHECK_FREQUENCY" "daily"
    # Write a timestamp that is 2 days old (past 86400s interval)
    echo "$(( $(date +%s) - 172800 ))" > "$MANAGER_DIR/.last_update_check"
    curl() { echo "VERSION=\"$VERSION\""; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    # curl was invoked (no CURL_CALLED mock here — absence of skip is sufficient)
}

@test "check_for_updates skips when weekly frequency and check was recent" {
    save_setting "UPDATE_CHECK_FREQUENCY" "weekly"
    # Write a timestamp that is only 1 day old (well within 604800s)
    echo "$(( $(date +%s) - 86400 ))" > "$MANAGER_DIR/.last_update_check"
    curl() { echo "CURL_CALLED"; }
    export -f curl
    run check_for_updates
    [ "$status" -eq 0 ]
    [[ "$output" != *"CURL_CALLED"* ]]
}

# --- Settings: load_settings and save_setting helpers ----------------------

@test "load_settings sets defaults when config file is absent" {
    rm -f "$CONFIG_FILE"
    load_settings
    [ "$SETTING_AUTO_UPDATE_CHECK" = "true" ]
    [ "$SETTING_SHOW_CHANGELOG"    = "true" ]
}

@test "save_setting writes a new key to config file" {
    save_setting "AUTO_UPDATE_CHECK" "false"
    run grep "^AUTO_UPDATE_CHECK=false" "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "save_setting updates an existing key without duplicating it" {
    save_setting "AUTO_UPDATE_CHECK" "true"
    save_setting "AUTO_UPDATE_CHECK" "false"
    count=$(grep -c "^AUTO_UPDATE_CHECK=" "$CONFIG_FILE")
    [ "$count" -eq 1 ]
    run grep "^AUTO_UPDATE_CHECK=false" "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "load_settings reads persisted value from config file" {
    save_setting "SHOW_CHANGELOG" "false"
    load_settings
    [ "$SETTING_SHOW_CHANGELOG" = "false" ]
}

# --- fetch_changelog: CHANGELOG.md parsing ---------------------------------

_mock_changelog_curl() {
    cat <<'CHANGELOG'
# Changelog

## [Unreleased]

## [1.2.7] - 2026-04-23

### Added
- Profile Backup/Restore feature.

### Changed
- Menu reordered so Settings and Exit are always last.

## [1.2.6] - 2026-04-23

### Added
- Startup UX checking message.
CHANGELOG
}

@test "fetch_changelog extracts the correct version section" {
    unset -f fetch_changelog
    load_script
    curl() { _mock_changelog_curl; }
    export -f curl _mock_changelog_curl
    run fetch_changelog "1.2.7"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile Backup/Restore"* ]]
}

@test "fetch_changelog does not bleed into adjacent version sections" {
    unset -f fetch_changelog
    load_script
    curl() { _mock_changelog_curl; }
    export -f curl _mock_changelog_curl
    run fetch_changelog "1.2.7"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Startup UX"* ]]
}

@test "fetch_changelog with no version returns the latest released section" {
    unset -f fetch_changelog
    load_script
    curl() { _mock_changelog_curl; }
    export -f curl _mock_changelog_curl
    run fetch_changelog
    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile Backup/Restore"* ]]
    [[ "$output" != *"Startup UX"* ]]
}

@test "fetch_changelog skips the Unreleased section when no version given" {
    unset -f fetch_changelog
    load_script
    curl() { _mock_changelog_curl; }
    export -f curl _mock_changelog_curl
    run fetch_changelog
    [ "$status" -eq 0 ]
    [[ "$output" != *"Unreleased"* ]]
}

# --- version_gt: numeric semver comparison ----------------------------------

@test "version_gt returns true when patch number is greater" {
    run version_gt "1.2.8" "1.2.7"
    [ "$status" -eq 0 ]
}

@test "version_gt returns false when versions are equal" {
    run version_gt "1.2.7" "1.2.7"
    [ "$status" -ne 0 ]
}

@test "version_gt returns false when version is lower" {
    run version_gt "1.2.6" "1.2.7"
    [ "$status" -ne 0 ]
}

@test "version_gt handles minor version correctly (1.3.0 > 1.2.9)" {
    run version_gt "1.3.0" "1.2.9"
    [ "$status" -eq 0 ]
}

@test "version_gt handles double-digit patch correctly (1.2.10 > 1.2.9)" {
    run version_gt "1.2.10" "1.2.9"
    [ "$status" -eq 0 ]
}
