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

# --- fetch_changelog JSON parsing ------------------------------------------

@test "fetch_changelog parses body from compact JSON (no space after colon)" {
    unset -f fetch_changelog
    load_script
    curl() {
        echo '{"tag_name":"v1.2.0","body":"### Added\n- New thing\n### Fixed\n- Bug fix"}'
    }
    export -f curl
    run fetch_changelog "1.2.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Added"* ]] || [[ "$output" == *"New thing"* ]]
}

@test "fetch_changelog parses body from pretty-printed JSON (space after colon)" {
    # Regression: GitHub API returns pretty-printed JSON with 'body': '...' (space after :)
    # The old grep pattern '"body":"' missed this entirely.
    unset -f fetch_changelog
    load_script
    curl() {
        printf '{\n  "tag_name": "v1.2.0",\n  "body": "### Added\\n- New thing\\n### Fixed\\n- Bug fix"\n}\n'
    }
    export -f curl
    run fetch_changelog "1.2.0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Added"* ]] || [[ "$output" == *"New thing"* ]]
}
