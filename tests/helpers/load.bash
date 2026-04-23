# =============================================================================
#  Git Identity Manager — Shared BATS Test Helpers
# =============================================================================

PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
SCRIPT="$PROJECT_ROOT/git-identity-manager.sh"

# ---------------------------------------------------------------------------
# setup_fake_home
#   Call inside BATS setup(). Redirects HOME to a temp dir so every file
#   operation in the script runs in isolation without touching the real system.
# ---------------------------------------------------------------------------
setup_fake_home() {
    export _ORIG_HOME="$HOME"
    export HOME="${BATS_TMPDIR}/home_${BATS_TEST_NUMBER}"
    mkdir -p \
        "$HOME/.ssh/git-manager.d" \
        "$HOME/.git-manager/profiles"
    touch "$HOME/.ssh/config" "$HOME/.bashrc"
    export SHELL="/bin/bash"
}

# ---------------------------------------------------------------------------
# teardown_fake_home
#   Call inside BATS teardown(). Restores HOME and removes the temp tree.
# ---------------------------------------------------------------------------
teardown_fake_home() {
    export HOME="$_ORIG_HOME"
    rm -rf "${BATS_TMPDIR}/home_${BATS_TEST_NUMBER}"
}

# ---------------------------------------------------------------------------
# load_script
#   Sources the main script into the current shell after fake HOME is ready.
#   The top-level initialisation (mkdir, Include bootstrap) runs against
#   the fake HOME, keeping the real system untouched.
# ---------------------------------------------------------------------------
load_script() {
    # CLI_MODE=true suppresses all interactive read prompts in TUI functions
    export CLI_MODE=true
    # shellcheck source=/dev/null
    source "$SCRIPT"
}

# ---------------------------------------------------------------------------
# make_fake_git_repo <dir>
#   Initialises a bare-minimum git repo so tests that need to be "inside a
#   work tree" (e.g. switch_identity local) have one.
# ---------------------------------------------------------------------------
make_fake_git_repo() {
    local dir="${1:-${BATS_TMPDIR}/repo_${BATS_TEST_NUMBER}}"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.email "test@test.com"
    git -C "$dir" config user.name "Test"
    echo "$dir"
}

# ---------------------------------------------------------------------------
# make_fake_profile <nickname> <name> <email>
#   Creates a minimal profile file directly in PROFILES_DIR (bypasses the
#   interactive finalize_profile flow).
# ---------------------------------------------------------------------------
make_fake_profile() {
    local nick="$1" name="$2" email="$3"
    local f="$HOME/.git-manager/profiles/$nick"
    {
        echo "git config user.name \"$name\""
        echo "git config user.email \"$email\""
        echo "git config commit.gpgsign false"
    } > "$f"
    echo "$f"
}
