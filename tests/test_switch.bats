#!/usr/bin/env bats
# =============================================================================
#  Switch Identity Tests — switch_identity
# =============================================================================

load 'helpers/load'

setup() {
    setup_fake_home
    load_script
    # Redirect global git config to a temp file so tests never touch the real one
    export GIT_CONFIG_GLOBAL="${BATS_TMPDIR}/gitconfig_global_${BATS_TEST_NUMBER}"
    touch "$GIT_CONFIG_GLOBAL"
}

teardown() {
    unset GIT_CONFIG_GLOBAL
    teardown_fake_home
}

# --- Missing profile --------------------------------------------------------

@test "switch_identity prints error for non-existent profile" {
    CLI_MODE=true
    run switch_identity "nonexistent" "local"
    [[ "$output" == *"does not exist"* ]]
}

@test "switch_identity exits cleanly for non-existent profile" {
    CLI_MODE=true
    run switch_identity "nonexistent" "local"
    # Should not crash (exit 1 from die) — function returns gracefully
    [ "$status" -eq 0 ]
}

# --- Global scope -----------------------------------------------------------

@test "switch_identity global applies user.name to global git config" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    switch_identity "work" "global"
    val=$(git config --global --get user.name)
    [ "$val" = "Alice Work" ]
}

@test "switch_identity global applies user.email to global git config" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    switch_identity "work" "global"
    val=$(git config --global --get user.email)
    [ "$val" = "alice@work.com" ]
}

@test "switch_identity global prints success message" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    run switch_identity "work" "global"
    [[ "$output" == *"GLOBAL"* ]]
}

@test "switch_identity accepts scope 'global' string" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    run switch_identity "work" "global"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[+]"* ]]
}

@test "switch_identity accepts scope '2' for global" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    run switch_identity "work" "2"
    [ "$status" -eq 0 ]
    [[ "$output" == *"GLOBAL"* ]]
}

# --- Local scope ------------------------------------------------------------

@test "switch_identity local prints error outside a git repo" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    CLI_MODE=true
    # Run from a directory that is NOT a git repo
    run bash -c "
        cd '${BATS_TMPDIR}'
        HOME='$HOME'
        GIT_CONFIG_GLOBAL='$GIT_CONFIG_GLOBAL'
        source '$SCRIPT'
        CLI_MODE=true
        switch_identity 'work' 'local'
    "
    [[ "$output" == *"not currently inside a Git"* ]]
}

@test "switch_identity local applies name inside a git repo" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    repo=$(make_fake_git_repo)
    CLI_MODE=true
    # Run from inside the temp git repo
    (
        cd "$repo"
        CLI_MODE=true
        switch_identity "work" "local"
        val=$(git config --local --get user.name)
        [ "$val" = "Alice Work" ]
    )
}

@test "switch_identity local applies email inside a git repo" {
    make_fake_profile "work" "Alice Work" "alice@work.com"
    repo=$(make_fake_git_repo)
    (
        cd "$repo"
        CLI_MODE=true
        switch_identity "work" "local"
        val=$(git config --local --get user.email)
        [ "$val" = "alice@work.com" ]
    )
}
