#!/usr/bin/env bats
# =============================================================================
#  Structural & Convention Tests
#  Validates that the script's architecture rules are satisfied at all times.
#  No HOME isolation needed — these tests operate on the source file as text.
# =============================================================================

SCRIPT="${BATS_TEST_DIRNAME}/../git-identity-manager.sh"

# --- Syntax ---------------------------------------------------------------

@test "git-identity-manager.sh passes bash -n syntax check" {
    run bash -n "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install.sh passes bash -n syntax check" {
    run bash -n "${BATS_TEST_DIRNAME}/../install.sh"
    [ "$status" -eq 0 ]
}

@test "release.sh passes bash -n syntax check" {
    run bash -n "${BATS_TEST_DIRNAME}/../release.sh"
    [ "$status" -eq 0 ]
}

# --- Version variable -----------------------------------------------------

@test "VERSION variable is present and follows semver X.Y.Z" {
    run grep -E '^VERSION="[0-9]+\.[0-9]+\.[0-9]+"' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "comment header Version: matches VERSION variable" {
    header=$(grep -E '^#  Version:' "$SCRIPT" | awk '{print $3}')
    var=$(grep -E '^VERSION=' "$SCRIPT" | cut -d'"' -f2)
    [ "$header" = "$var" ]
}

@test "UPDATE_URL points to git-identity-manager.sh" {
    run grep -q 'git-identity-manager.sh' "$SCRIPT"
    [ "$status" -eq 0 ]
}

# --- SSH safety rule ------------------------------------------------------

@test "at least one IdentitiesOnly yes is present in the script" {
    count=$(grep -c 'IdentitiesOnly yes' "$SCRIPT" || true)
    [ "$count" -ge 1 ]
}

# --- Dual registration (CLI + TUI) ----------------------------------------

@test "setup is registered in the CLI case parser" {
    run grep -qE "setup\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "import is registered in the CLI case parser" {
    run grep -qE "import\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "switch is registered in the CLI case parser" {
    run grep -qE "switch\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "view is registered in the CLI case parser" {
    run grep -qE "view\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "doctor is registered in the CLI case parser" {
    run grep -qE "doctor\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "update is registered in the CLI case parser" {
    run grep -qE "update\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "settings is registered in the CLI case parser" {
    run grep -qE "settings\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "manage_settings function is defined" {
    run grep -q "^manage_settings()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "load_settings function is defined" {
    run grep -q "^load_settings()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "save_setting function is defined" {
    run grep -q "^save_setting()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "settings option 10 is registered in TUI menu loop" {
    run grep -qE "10\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "version_gt function is defined" {
    run grep -q "^version_gt()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "backup is registered in the CLI case parser" {
    run grep -qE "backup\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "restore is registered in the CLI case parser" {
    run grep -qE "restore\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "backup_profiles function is defined" {
    run grep -q "^backup_profiles()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "restore_profiles function is defined" {
    run grep -q "^restore_profiles()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "backup_restore function is defined" {
    run grep -q "^backup_restore()" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "option 11 is registered in TUI menu loop" {
    run grep -qE "11\)" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "CONFIG_FILE variable is defined" {
    run grep -q "^CONFIG_FILE=" "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "main TUI menu loop exists (while true)" {
    run grep -q 'while true' "$SCRIPT"
    [ "$status" -eq 0 ]
}

# --- Profile purity rule --------------------------------------------------

@test "finalize_profile writes only git config commands to profile" {
    # The heredoc in finalize_profile must not contain any raw secrets or keys
    run grep -n 'echo.*password\|echo.*private_key\|echo.*SECRET' "$SCRIPT"
    [ "$status" -ne 0 ]   # must find nothing
}

# --- CHANGELOG rule -------------------------------------------------------

@test "CHANGELOG.md exists in the repository root" {
    [ -f "${BATS_TEST_DIRNAME}/../CHANGELOG.md" ]
}
