#!/usr/bin/env bats
# =============================================================================
#  Profile Tests — get_profiles, finalize_profile
# =============================================================================

load 'helpers/load'

setup() {
    setup_fake_home
    load_script
}

teardown() {
    teardown_fake_home
}

# --- get_profiles -----------------------------------------------------------

@test "get_profiles returns empty array when vault is empty" {
    get_profiles
    [ "${#profiles[@]}" -eq 0 ]
}

@test "get_profiles lists a single profile" {
    make_fake_profile "work" "Alice" "alice@work.com"
    get_profiles
    [ "${#profiles[@]}" -eq 1 ]
    [ "${profiles[0]}" = "work" ]
}

@test "get_profiles lists multiple profiles" {
    make_fake_profile "work"     "Alice" "alice@work.com"
    make_fake_profile "personal" "Alice" "alice@personal.com"
    get_profiles
    [ "${#profiles[@]}" -eq 2 ]
}

# --- finalize_profile -------------------------------------------------------

@test "finalize_profile creates profile file in PROFILES_DIR" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    [ -f "$PROFILES_DIR/testid" ]
}

@test "finalize_profile profile contains user.name" {
    finalize_profile "testid" "Bob Smith" "bob@test.com" "" "" "GENERATE"
    run grep 'user.name' "$PROFILES_DIR/testid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Bob Smith"* ]]
}

@test "finalize_profile profile contains user.email" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    run grep 'user.email' "$PROFILES_DIR/testid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"bob@test.com"* ]]
}

@test "finalize_profile without GPG writes gpgsign false" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    run grep 'commit.gpgsign' "$PROFILES_DIR/testid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"false"* ]]
}

@test "finalize_profile with GPG writes signingkey and gpgsign true" {
    finalize_profile "testid" "Bob" "bob@test.com" "ABCD1234" "" "GENERATE"
    run grep 'signingkey' "$PROFILES_DIR/testid"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ABCD1234"* ]]
    run grep 'gpgsign' "$PROFILES_DIR/testid"
    [[ "$output" == *"true"* ]]
}

@test "finalize_profile adds as-<nick> alias to shell profile" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    run grep 'alias as-testid=' "$SHELL_PROFILE"
    [ "$status" -eq 0 ]
}

@test "finalize_profile adds as-<nick>-global alias to shell profile" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    run grep 'alias as-testid-global=' "$SHELL_PROFILE"
    [ "$status" -eq 0 ]
}

@test "finalize_profile does not duplicate aliases on second call" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    count=$(grep -c 'alias as-testid=' "$SHELL_PROFILE")
    [ "$count" -eq 1 ]
}

@test "finalize_profile profile file contains only git config commands" {
    finalize_profile "testid" "Bob" "bob@test.com" "" "" "GENERATE"
    # Every non-empty line must start with 'git config'
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == git\ config* ]] || { echo "Unexpected line: $line"; return 1; }
    done < "$PROFILES_DIR/testid"
}

# --- view_profiles GPG status (regression: --unset line must not read as Active) ---

@test "view_profiles shows GPG as None for profile without GPG key" {
    finalize_profile "nogpg" "Carol" "carol@test.com" "" "" "GENERATE"
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../git-identity-manager.sh'
        P_GPG=\$(grep '^git config user.signingkey' '$PROFILES_DIR/nogpg' | awk '{print \$4}' || true)
        echo \"GPG=[\$P_GPG]\"
    "
    [[ "$output" == *"GPG=[]"* ]]
}

@test "view_profiles shows GPG as Active for profile with a GPG key" {
    finalize_profile "withgpg" "Dave" "dave@test.com" "ABCD1234EFGH5678" "" "GENERATE"
    run bash -c "
        source '${BATS_TEST_DIRNAME}/../git-identity-manager.sh'
        P_GPG=\$(grep '^git config user.signingkey' '$PROFILES_DIR/withgpg' | awk '{print \$4}' || true)
        echo \"GPG=[\$P_GPG]\"
    "
    [[ "$output" == *"GPG=[ABCD1234EFGH5678]"* ]]
}
