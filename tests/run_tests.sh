#!/bin/bash
# =============================================================================
#  Git Identity Manager — Test Runner
#  Usage: bash tests/run_tests.sh [--install-bats]
#
#  Options:
#    --install-bats   Attempt to install bats-core automatically if missing.
#                     Uses brew on macOS, apt-get on Linux.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Colours ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN} [i]${RESET} $*"; }
success() { echo -e "${GREEN} [+]${RESET} $*"; }
warn()    { echo -e "${YELLOW} [!]${RESET} $*"; }
die()     { echo -e "${RED} [!]${RESET} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Ensure BATS is available
# ---------------------------------------------------------------------------
ensure_bats() {
    if command -v bats &>/dev/null; then
        info "bats $(bats --version | awk '{print $NF}') found at $(command -v bats)"
        return 0
    fi

    if [[ "${1:-}" != "--install-bats" ]]; then
        echo ""
        echo -e "${YELLOW}  bats-core is not installed.${RESET}"
        echo "  Install it first, then re-run:"
        echo ""
        echo "    macOS   : brew install bats-core"
        echo "    Ubuntu  : sudo apt-get install -y bats"
        echo "    Manual  : https://bats-core.readthedocs.io/en/stable/installation.html"
        echo ""
        echo "  Or pass --install-bats to auto-install:"
        echo "    bash tests/run_tests.sh --install-bats"
        echo ""
        die "bats-core not found."
    fi

    info "Attempting automatic bats-core installation..."
    if [[ "$(uname)" == "Darwin" ]]; then
        command -v brew &>/dev/null || die "brew not found — install bats-core manually."
        brew install bats-core
    elif [[ "$(uname)" == "Linux" ]]; then
        sudo apt-get install -y bats 2>/dev/null || \
            die "apt-get failed — install bats-core manually."
    else
        die "Unsupported OS. Install bats-core manually."
    fi

    command -v bats &>/dev/null || die "bats installation failed."
    success "bats-core installed."
}

# ---------------------------------------------------------------------------
# Run all test suites
# ---------------------------------------------------------------------------
run_all_tests() {
    local failed=0

    echo ""
    echo -e "${BOLD}==================================================================${RESET}"
    echo -e "${BOLD}   Git Identity Manager — Test Suite${RESET}"
    echo -e "${BOLD}==================================================================${RESET}"
    echo ""

    local test_files=(
        "$SCRIPT_DIR/test_structure.bats"
        "$SCRIPT_DIR/test_release.bats"
        "$SCRIPT_DIR/test_profiles.bats"
        "$SCRIPT_DIR/test_switch.bats"
        "$SCRIPT_DIR/test_changelog.bats"
    )

    for tf in "${test_files[@]}"; do
        if [[ ! -f "$tf" ]]; then
            warn "Test file not found, skipping: $tf"
            continue
        fi

        echo -e "${CYAN}--- $(basename "$tf") ---${RESET}"
        if bats --tap "$tf"; then
            success "$(basename "$tf") passed"
        else
            warn "$(basename "$tf") FAILED"
            failed=1
        fi
        echo ""
    done

    echo -e "${BOLD}==================================================================${RESET}"
    if [[ "$failed" -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}  All tests passed.${RESET}"
        echo -e "${BOLD}==================================================================${RESET}"
        echo ""
        return 0
    else
        echo -e "${RED}${BOLD}  Some tests FAILED. Fix errors before releasing.${RESET}"
        echo -e "${BOLD}==================================================================${RESET}"
        echo ""
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
cd "$ROOT_DIR"
ensure_bats "${1:-}"
run_all_tests
