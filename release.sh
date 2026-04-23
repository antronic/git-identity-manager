#!/bin/bash

# ==============================================================================
#  Git Identity Manager — Release Script
#  Usage: bash release.sh
#  Bumps VERSION, commits, tags, and pushes to trigger the GitHub Actions
#  release workflow (.github/workflows/release.yml).
# ==============================================================================

set -euo pipefail

SCRIPT="git-identity-manager.sh"
REMOTE="origin"
BRANCH="main"

# --- Colours ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN} [i]${RESET} $*"; }
success() { echo -e "${GREEN} [+]${RESET} $*"; }
warn()    { echo -e "${YELLOW} [!]${RESET} $*"; }
die()     { echo -e "${RED} [!] ERROR:${RESET} $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}==>${RESET} $*"; }

# --- Helper: semver bump ---
bump_version() {
    local version="$1" part="$2"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    case "$part" in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "${major}.$((minor + 1)).0" ;;
        patch) echo "${major}.${minor}.$((patch + 1))" ;;
    esac
}

# ==============================================================================
# PRE-FLIGHT CHECKS
# ==============================================================================
step "Pre-flight checks"

# Must be run from the repo root
[[ -f "$SCRIPT" ]] || die "Run this script from the repository root (cannot find $SCRIPT)."

# Git must be available
command -v git &>/dev/null || die "git is not installed."

# Must be on the target branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ "$CURRENT_BRANCH" == "$BRANCH" ]] || \
    die "You are on branch '$CURRENT_BRANCH'. Switch to '$BRANCH' before releasing."

# Working tree must be clean
if ! git diff --quiet || ! git diff --cached --quiet; then
    die "Working tree has uncommitted changes. Commit or stash them first."
fi

# Pull latest from remote
info "Pulling latest from $REMOTE/$BRANCH..."
git pull "$REMOTE" "$BRANCH" --ff-only || die "Fast-forward pull failed. Resolve divergence first."

success "All pre-flight checks passed."

# ==============================================================================
# DETERMINE NEW VERSION
# ==============================================================================
step "Version bump"

CURRENT_VERSION=$(grep -E '^VERSION=' "$SCRIPT" | cut -d'"' -f2)
info "Current version: ${BOLD}$CURRENT_VERSION${RESET}"

PATCH_VER=$(bump_version "$CURRENT_VERSION" patch)
MINOR_VER=$(bump_version "$CURRENT_VERSION" minor)
MAJOR_VER=$(bump_version "$CURRENT_VERSION" major)

echo ""
echo "  [1] Patch  →  $PATCH_VER   (bug fixes)"
echo "  [2] Minor  →  $MINOR_VER   (new features, backward-compatible)"
echo "  [3] Major  →  $MAJOR_VER   (breaking changes)"
echo "  [4] Custom"
echo ""
read -rp " [?] Select bump type (1-4): " BUMP_CHOICE

case "$BUMP_CHOICE" in
    1) NEW_VERSION="$PATCH_VER" ;;
    2) NEW_VERSION="$MINOR_VER" ;;
    3) NEW_VERSION="$MAJOR_VER" ;;
    4)
        read -rp " [?] Enter version (without 'v'): " NEW_VERSION
        [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid semver: $NEW_VERSION"
        ;;
    *) die "Invalid choice." ;;
esac

info "New version will be: ${BOLD}$NEW_VERSION${RESET}"
read -rp " [?] Confirm release v$NEW_VERSION? (Y/n): " CONFIRM
CONFIRM=${CONFIRM:-Y}
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { warn "Release cancelled."; exit 0; }

# ==============================================================================
# UPDATE VERSION IN SCRIPT
# ==============================================================================
step "Updating $SCRIPT"

sed -i.bak \
    -e "s/^VERSION=\"$CURRENT_VERSION\"/VERSION=\"$NEW_VERSION\"/" \
    -e "s/^#  Version: $CURRENT_VERSION/#  Version: $NEW_VERSION/" \
    "$SCRIPT"
rm -f "$SCRIPT.bak"

# Verify the change landed
UPDATED_VERSION=$(grep -E '^VERSION=' "$SCRIPT" | cut -d'"' -f2)
[[ "$UPDATED_VERSION" == "$NEW_VERSION" ]] || die "VERSION update in $SCRIPT failed."
success "VERSION updated to $NEW_VERSION in $SCRIPT."

# ==============================================================================
# VALIDATION
# ==============================================================================
step "Validation"

info "Bash syntax check..."
bash -n "$SCRIPT" || die "Bash syntax check failed."
success "Bash syntax OK."

if command -v shellcheck &>/dev/null; then
    info "ShellCheck..."
    shellcheck --severity=warning "$SCRIPT" || die "ShellCheck reported warnings. Fix before releasing."
    success "ShellCheck OK."
else
    warn "shellcheck not installed — skipping static analysis."
fi

info "Running test suite..."
bash tests/run_tests.sh || die "Tests failed. Fix all errors before releasing."
success "All tests passed."

# ==============================================================================
# COMMIT, TAG, PUSH
# ==============================================================================
step "Commit & tag"

git add "$SCRIPT"
git commit -m "chore: bump version to v$NEW_VERSION"
success "Committed version bump."

git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
success "Tag v$NEW_VERSION created."

step "Pushing to $REMOTE"
git push "$REMOTE" "$BRANCH"
git push "$REMOTE" "v$NEW_VERSION"
success "Pushed branch and tag to $REMOTE."

# ==============================================================================
# DONE
# ==============================================================================
echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "  Release v$NEW_VERSION triggered successfully!"
echo -e "==================================================================${RESET}"
echo ""
echo "  GitHub Actions will now:"
echo "    1. Verify VERSION in $SCRIPT matches the tag"
echo "    2. Create a GitHub Release with $SCRIPT and install.sh as assets"
echo "    3. Release Drafter will update the changelog draft"
echo ""
echo "  Watch the run:"
echo "  https://github.com/antronic/git-identity-manager/actions"
echo ""
