#!/usr/bin/env bats
# =============================================================================
#  Release Script Tests — bump_version
#  Sources only the bump_version function from release.sh (not the full
#  interactive flow) by isolating the function definition.
# =============================================================================

RELEASE_SCRIPT="${BATS_TEST_DIRNAME}/../release.sh"

setup() {
    # Extract and source only the bump_version function
    eval "$(grep -A12 '# --- Helper: semver bump ---' "$RELEASE_SCRIPT" | \
           sed -n '/^bump_version/,/^}/p')"
}

# --- Patch bump -------------------------------------------------------------

@test "bump_version patch increments patch number" {
    result=$(bump_version "1.2.3" patch)
    [ "$result" = "1.2.4" ]
}

@test "bump_version patch resets nothing in major or minor" {
    result=$(bump_version "2.5.9" patch)
    [ "$result" = "2.5.10" ]
}

@test "bump_version patch on zero patch" {
    result=$(bump_version "1.0.0" patch)
    [ "$result" = "1.0.1" ]
}

# --- Minor bump -------------------------------------------------------------

@test "bump_version minor increments minor number" {
    result=$(bump_version "1.2.3" minor)
    [ "$result" = "1.3.0" ]
}

@test "bump_version minor resets patch to 0" {
    result=$(bump_version "1.2.9" minor)
    [ "$result" = "1.3.0" ]
}

@test "bump_version minor does not change major" {
    result=$(bump_version "3.1.0" minor)
    [ "$result" = "3.2.0" ]
}

# --- Major bump -------------------------------------------------------------

@test "bump_version major increments major number" {
    result=$(bump_version "1.2.3" major)
    [ "$result" = "2.0.0" ]
}

@test "bump_version major resets minor and patch to 0" {
    result=$(bump_version "4.9.8" major)
    [ "$result" = "5.0.0" ]
}

@test "bump_version major from 0.x.y" {
    result=$(bump_version "0.9.9" major)
    [ "$result" = "1.0.0" ]
}

# --- Edge cases -------------------------------------------------------------

@test "bump_version handles double-digit minor" {
    result=$(bump_version "1.10.3" minor)
    [ "$result" = "1.11.0" ]
}

@test "bump_version handles double-digit patch" {
    result=$(bump_version "1.0.19" patch)
    [ "$result" = "1.0.20" ]
}
