#!/bin/bash

# ==============================================================================
#  GIT IDENTITY MANAGER
#  Version: 1.2.0
#  Repository: https://github.com/antronic/git-identity-manager
#  Features: Setup, Import, Switch, View, Modify, Delete, Keys, Doctor, CLI
# ==============================================================================

VERSION="1.2.0"
UPDATE_URL="https://raw.githubusercontent.com/antronic/git-identity-manager/main/git-identity-manager.sh"
CHANGELOG_URL="https://api.github.com/repos/antronic/git-identity-manager/releases/latest"

MANAGER_DIR="$HOME/.git-manager"
PROFILES_DIR="$MANAGER_DIR/profiles"
CONFIG_FILE="$MANAGER_DIR/config.env"
mkdir -p "$PROFILES_DIR"

# Detect Shell Profile for aliases
SHELL_PROFILE="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_PROFILE="$HOME/.zshrc"

# --- SSH ARCHITECTURE SETUP ---
SSH_DIR="$HOME/.ssh"
SSH_CONF_DIR="$SSH_DIR/git-manager.d"
mkdir -p "$SSH_CONF_DIR"
touch "$SSH_DIR/config"

if ! grep -q "^Include ~/.ssh/git-manager.d/\*" "$SSH_DIR/config"; then
    echo -e "Include ~/.ssh/git-manager.d/*\n$(cat "$SSH_DIR/config")" > "$SSH_DIR/config"
fi

# --- HELPER: GET PROFILES ---
get_profiles() {
    profiles=()
    if [ -d "$PROFILES_DIR" ]; then
        for f in "$PROFILES_DIR"/*; do
            [ -e "$f" ] && profiles+=("$(basename "$f")") || true
        done
    fi
}

# --- HELPER: LOAD SETTINGS FROM CONFIG FILE ---
load_settings() {
    # Defaults
    SETTING_AUTO_UPDATE_CHECK="true"
    SETTING_SHOW_CHANGELOG="true"

    if [[ -f "$CONFIG_FILE" ]]; then
        local key val
        while IFS='=' read -r key val; do
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            case "$key" in
                AUTO_UPDATE_CHECK) SETTING_AUTO_UPDATE_CHECK="$val" ;;
                SHOW_CHANGELOG)    SETTING_SHOW_CHANGELOG="$val" ;;
            esac
        done < "$CONFIG_FILE"
    fi
}

# --- HELPER: PERSIST A SETTING TO CONFIG FILE ---
save_setting() {
    local key="$1" value="$2"
    touch "$CONFIG_FILE"
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i.bak "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
        rm -f "${CONFIG_FILE}.bak"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
    # Reload so in-memory vars reflect the change
    load_settings
}

# --- HELPER: FETCH CHANGELOG FROM GITHUB RELEASES ---
fetch_changelog() {
    local target_version="${1:-}"
    if ! command -v curl &> /dev/null; then return; fi

    local release_json
    if [[ -n "$target_version" ]]; then
        release_json=$(curl -sL --max-time 5 \
            "https://api.github.com/repos/antronic/git-identity-manager/releases/tags/v${target_version}" \
            2>/dev/null)
    else
        release_json=$(curl -sL --max-time 5 "$CHANGELOG_URL" 2>/dev/null)
    fi

    # Extract body field — works without jq by parsing the JSON manually
    echo "$release_json" | grep -o '"body":"[^"]*"' | sed 's/"body":"//;s/"$//' | sed 's/\\r\\n/\n/g;s/\\n/\n/g'
}

# --- HELPER: SHOW CHANGELOG ONCE AFTER AN UPGRADE ---
show_changelog_once() {
    [[ "${SETTING_SHOW_CHANGELOG:-true}" == "false" ]] && return 0
    local marker_file="$MANAGER_DIR/.last_seen_version"
    local last_seen=""
    [[ -f "$marker_file" ]] && last_seen=$(cat "$marker_file")

    if [[ "$last_seen" != "$VERSION" ]]; then
        echo "=================================================================="
        echo " [*] WHAT'S NEW IN v$VERSION"
        echo "=================================================================="
        local changelog
        changelog=$(fetch_changelog "$VERSION")
        if [[ -n "$changelog" ]]; then
            echo "$changelog"
        else
            echo " No release notes available for this version."
        fi
        echo "=================================================================="
        echo "$VERSION" > "$marker_file"
        [[ -z "$CLI_MODE" ]] && read -p " Press Enter to continue..." || true
    fi
}

# --- AUTO UPDATE CHECKER ---
# shellcheck disable=SC2120  # $@ forwarded to exec for restart; callers never pass args intentionally
check_for_updates() {
    [[ "${SETTING_AUTO_UPDATE_CHECK:-true}" == "false" ]] && return 0
    if ! command -v curl &> /dev/null; then return; fi

    REMOTE_VERSION=$(curl -sL --max-time 2 "$UPDATE_URL" | grep -E '^VERSION=' | head -n 1 | cut -d'"' -f2)

    if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo "=================================================================="
        echo " [*] UPDATE AVAILABLE! "
        echo "     Current Version : $VERSION"
        echo "     New Version     : $REMOTE_VERSION"
        echo "=================================================================="
        echo ""
        echo " [*] Fetching release notes for v$REMOTE_VERSION..."
        local changelog
        changelog=$(fetch_changelog "$REMOTE_VERSION")
        if [[ -n "$changelog" ]]; then
            echo "------------------------------------------------------------------"
            echo "$changelog"
            echo "------------------------------------------------------------------"
        fi
        echo ""
        read -p " [?] Would you like to auto-upgrade now? (Y/n): " DO_UPGRADE
        DO_UPGRADE=${DO_UPGRADE:-Y}
        if [[ "$DO_UPGRADE" =~ ^[Yy]$ ]]; then
            echo " [*] Downloading update..."
            if curl -sL "$UPDATE_URL" -o "$0.tmp"; then
                mv "$0.tmp" "$0"
                chmod +x "$0"
                echo " [+] Upgrade complete! Restarting..."
                sleep 1
                # shellcheck disable=SC2120
                exec "$0" "$@"
            else
                echo " [!] Update failed. Check your internet connection."
                rm -f "$0.tmp"
                sleep 2
            fi
        fi
    fi
}

# --- FUNCTION: SETUP (GENERATE NEW KEYS) ---
setup_identity() {
    clear
    echo "=================================================================="
    echo " [ SETUP ]  GENERATE A NEW IDENTITY"
    echo "=================================================================="
    echo ""

    read -p " [?] Enter a nickname (e.g., work, dev): " NICKNAME
    if [ -f "$PROFILES_DIR/$NICKNAME" ]; then
        echo " [!] Identity '$NICKNAME' already exists."
        read -p " Press Enter to return..." && return
    fi

    echo ""
    read -p " [?] Enter full name for Git  : " GIT_NAME
    read -p " [?] Enter email for Git      : " GIT_EMAIL
    echo ""

    # Generate SSH
    echo "------------------------------------------------------------------"
    read -p " [?] Generate a new SSH key for this account? (Y/n): " DO_SSH
    DO_SSH=${DO_SSH:-Y}

    SSH_PATH="$HOME/.ssh/id_ed25519_$NICKNAME"
    if [[ "$DO_SSH" =~ ^[Yy]$ ]]; then
        echo " [*] Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_PATH" -N "" >/dev/null 2>&1

        read -p " [?] Add key to SSH Agent automatically? (Y/n): " ADD_AGENT
        ADD_AGENT=${ADD_AGENT:-Y}

        cat <<EOT > "$SSH_CONF_DIR/$NICKNAME.conf"
# Manager Identity: $NICKNAME
Host github.com-$NICKNAME
    HostName github.com
    User git
    IdentityFile $SSH_PATH
    IdentitiesOnly yes
EOT
        if [[ "$ADD_AGENT" =~ ^[Yy]$ ]]; then
            echo "    AddKeysToAgent yes" >> "$SSH_CONF_DIR/$NICKNAME.conf"
            [[ "$(uname)" == "Darwin" ]] && echo "    UseKeychain yes" >> "$SSH_CONF_DIR/$NICKNAME.conf"
        fi
        echo " [+] SSH configured at: ~/.ssh/git-manager.d/$NICKNAME.conf"
    fi
    echo ""

    # Generate GPG
    echo "------------------------------------------------------------------"
    read -p " [?] Generate a new GPG key for signing commits? (Y/n): " DO_GPG
    DO_GPG=${DO_GPG:-Y}

    GPG_ID=""
    if [[ "$DO_GPG" =~ ^[Yy]$ ]]; then
        read -p " [?] Secure GPG key with a passphrase? (Y/n - Default: Y): " GPG_PASS
        GPG_PASS=${GPG_PASS:-Y}

        echo " [*] Generating GPG key..."
        gpg_batch=$(mktemp)
        cat <<EOT > "$gpg_batch"
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: sign
Name-Real: $GIT_NAME
Name-Email: $GIT_EMAIL
Expire-Date: 0
EOT
        [[ ! "$GPG_PASS" =~ ^[Yy]$ ]] && echo "%no-protection" >> "$gpg_batch"
        echo "%commit" >> "$gpg_batch"

        gpg --batch --generate-key "$gpg_batch" 2>/dev/null
        rm "$gpg_batch"

        GPG_ID=$(gpg --list-secret-keys --keyid-format LONG "$GIT_EMAIL" | grep 'sec' | tail -1 | awk '{print $2}' | cut -d'/' -f2)
        [[ -n "$GPG_ID" ]] && echo " [+] GPG key generated: $GPG_ID" || echo " [!] GPG generation failed."
    fi

    finalize_profile "$NICKNAME" "$GIT_NAME" "$GIT_EMAIL" "$GPG_ID" "$SSH_PATH" "GENERATE"
}

# --- FUNCTION: IMPORT (LINK EXISTING KEYS) ---
import_identity() {
    clear
    echo "=================================================================="
    echo " [ IMPORT ]  LINK EXISTING KEYS TO A NEW PROFILE"
    echo "=================================================================="
    echo ""

    read -p " [?] Enter a nickname (e.g., work, dev): " NICKNAME
    if [ -f "$PROFILES_DIR/$NICKNAME" ]; then
        echo " [!] Identity '$NICKNAME' already exists."
        read -p " Press Enter to return..." && return
    fi

    echo ""
    read -p " [?] Enter full name for Git  : " GIT_NAME
    read -p " [?] Enter email for Git      : " GIT_EMAIL
    echo ""

    # Import SSH
    echo "------------------------------------------------------------------"
    read -p " [?] Import an existing SSH key? (Y/n): " DO_SSH
    DO_SSH=${DO_SSH:-Y}
    SSH_PATH=""

    if [[ "$DO_SSH" =~ ^[Yy]$ ]]; then
        read -p " [?] Absolute path to private SSH key (e.g., ~/.ssh/id_rsa): " RAW_PATH
        SSH_PATH="${RAW_PATH/#\~/$HOME}"

        if [ -f "$SSH_PATH" ]; then
            cat <<EOT > "$SSH_CONF_DIR/$NICKNAME.conf"
# Manager Identity: $NICKNAME
Host github.com-$NICKNAME
    HostName github.com
    User git
    IdentityFile $SSH_PATH
    IdentitiesOnly yes
EOT
            echo " [+] Linked existing SSH key."
        else
            echo " [!] Key not found at $SSH_PATH. Skipping SSH import."
            SSH_PATH=""
        fi
    fi
    echo ""

    # Import GPG
    echo "------------------------------------------------------------------"
    read -p " [?] Import an existing GPG key? (Y/n): " DO_GPG
    DO_GPG=${DO_GPG:-Y}
    GPG_ID=""

    if [[ "$DO_GPG" =~ ^[Yy]$ ]]; then
        echo " [*] Available GPG Keys:"
        gpg --list-secret-keys --keyid-format LONG | grep 'sec' | awk '{print $2}'
        echo ""
        read -p " [?] Enter the GPG Key ID to bind: " IMPORT_GPG_ID
        if [[ -n "$IMPORT_GPG_ID" ]]; then
            GPG_ID="$IMPORT_GPG_ID"
            echo " [+] GPG key $GPG_ID linked."
        fi
    fi

    finalize_profile "$NICKNAME" "$GIT_NAME" "$GIT_EMAIL" "$GPG_ID" "$SSH_PATH" "IMPORT"
}

# --- HELPER: FINALIZE PROFILE ---
finalize_profile() {
    local NICKNAME=$1 GIT_NAME=$2 GIT_EMAIL=$3 GPG_ID=$4 SSH_PATH=$5 MODE=$6

    PROFILE_FILE="$PROFILES_DIR/$NICKNAME"
    cat <<EOT > "$PROFILE_FILE"
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
EOT

    if [[ -n "$GPG_ID" ]]; then
        echo "git config user.signingkey $GPG_ID" >> "$PROFILE_FILE"
        echo "git config commit.gpgsign true" >> "$PROFILE_FILE"
    else
        echo "git config --unset user.signingkey 2>/dev/null || true" >> "$PROFILE_FILE"
        echo "git config commit.gpgsign false" >> "$PROFILE_FILE"
    fi

    SWITCH_CMD="as-$NICKNAME"
    GLOBAL_SWITCH_CMD="as-$NICKNAME-global"

    if ! grep -q "alias $SWITCH_CMD=" "$SHELL_PROFILE"; then
        echo "alias $SWITCH_CMD='source \"$PROFILE_FILE\" && echo \" [+] Switched to identity: $NICKNAME (Local)\"'" >> "$SHELL_PROFILE"
        echo "alias $GLOBAL_SWITCH_CMD='sed \"s/git config/git config --global/g\" \"$PROFILE_FILE\" | bash && echo \" [+] Switched to identity: $NICKNAME (Global)\"'" >> "$SHELL_PROFILE"
    fi

    if [ -z "$CLI_MODE" ]; then
        clear
        echo "=================================================================="
        echo " [ OK ]  IDENTITY SUCCESSFULLY CREATED: $NICKNAME "
        echo "=================================================================="
        echo ""
        echo " To switch instantly from your terminal in the future, restart it"
        echo " and use one of the following commands:"
        echo " -> Local Repo   :  $SWITCH_CMD"
        echo " -> Global System:  $GLOBAL_SWITCH_CMD"
        echo ""

        if [ -n "$SSH_PATH" ] && [ "$MODE" = "GENERATE" ]; then
            echo " 🗝️  SSH PUBLIC KEY (Add to your Git Provider):"
            cat "${SSH_PATH}.pub" 2>/dev/null || echo " [!] Public key not found."
            echo ""
        fi

        if [[ -n "$GPG_ID" ]] && [ "$MODE" = "GENERATE" ]; then
            echo " 🛡️  GPG PUBLIC KEY (Add to your Git Provider):"
            gpg --armor --export "$GPG_ID"
            echo ""
        fi
        read -p " Press Enter to return to the menu..."
    fi
}

# --- FUNCTION: SWITCH ACCOUNT ---
switch_identity() {
    local TARGET_PROFILE=$1
    local SCOPE=$2

    if [ -z "$TARGET_PROFILE" ]; then
        clear
        echo "=================================================================="
        echo " [ SWITCH ]  APPLY AN IDENTITY"
        echo "=================================================================="
        echo ""
        get_profiles
        if [ ${#profiles[@]} -eq 0 ]; then
            echo " [i] No identities found."
            read -p " Press Enter to return..." && return
        fi

        PS3=" [?] Select an identity to apply: "
        select TARGET_PROFILE in "${profiles[@]}" "Cancel"; do
            [[ "$TARGET_PROFILE" == "Cancel" ]] && return
            [[ -n "$TARGET_PROFILE" ]] && break
            echo " [!] Invalid selection."
        done

        echo ""
        echo " [?] Scope:"
        echo "     1) Local Repository (Current Directory)"
        echo "     2) Global System (All Repositories)"
        read -p " -> Select scope [1-2]: " SCOPE
    fi

    PROFILE_FILE="$PROFILES_DIR/$TARGET_PROFILE"
    if [ ! -f "$PROFILE_FILE" ]; then
        echo " [!] Identity '$TARGET_PROFILE' does not exist."
        [[ -z "$CLI_MODE" ]] && read -p " Press Enter..." || true
        return
    fi

    if [[ "$SCOPE" == "2" || "$SCOPE" == "global" ]]; then
        sed 's/git config/git config --global/g' "$PROFILE_FILE" | bash
        echo " [+] Successfully applied '$TARGET_PROFILE' to GLOBAL config."
    else
        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo " [!] Error: You are not currently inside a Git repository."
        else
            # shellcheck source=/dev/null
            source "$PROFILE_FILE"
            echo " [+] Successfully applied '$TARGET_PROFILE' to LOCAL repository."
        fi
    fi
    [[ -z "$CLI_MODE" ]] && read -p " Press Enter..." || true
}

# --- FUNCTION: VIEW PROFILES ---
view_profiles() {
    clear
    echo "=================================================================="
    echo " [ VIEW ]  IDENTITY VAULT"
    echo "=================================================================="
    echo ""

    get_profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo " [i] The vault is empty. No identities found."
        [[ -z "$CLI_MODE" ]] && read -p " Press Enter..." || true
        return
    fi

    echo "--------------------------------------------------------------------------------"
    printf " %-15s | %-20s | %-22s | %-12s \n" "NICKNAME" "NAME" "EMAIL" "GPG SIGNING"
    echo "--------------------------------------------------------------------------------"

    for opt in "${profiles[@]}"; do
        PROFILE_FILE="$PROFILES_DIR/$opt"
        P_NAME=$(grep "user.name" "$PROFILE_FILE" | cut -d'"' -f2 || echo "Unknown")
        P_EMAIL=$(grep "user.email" "$PROFILE_FILE" | cut -d'"' -f2 || echo "Unknown")
        P_GPG=$(grep "^git config user.signingkey" "$PROFILE_FILE" | awk '{print $4}' || true)

        if [[ -n "$P_GPG" ]]; then
            GPG_STATUS="[+] Active"
        else
            GPG_STATUS="[-] None"
        fi
        printf " %-15s | %-20s | %-22s | %-12s \n" "$opt" "${P_NAME:0:20}" "${P_EMAIL:0:22}" "$GPG_STATUS"
    done
    echo "--------------------------------------------------------------------------------"
    echo ""
    [[ -z "$CLI_MODE" ]] && read -p " Press Enter..." || true
}

# --- FUNCTION: MODIFY ACCOUNT ---
modify_identity() {
    clear
    echo "=================================================================="
    echo " [ MODIFY ]  UPDATE AN IDENTITY"
    echo "=================================================================="
    echo ""

    get_profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo " [i] No identities found to modify."
        read -p " Press Enter to return..." && return
    fi

    PS3=" [?] Select an identity to modify: "
    select opt in "${profiles[@]}" "Cancel"; do
        echo ""
        if [[ "$opt" == "Cancel" ]]; then
            echo " [*] Canceled."
            break
        elif [[ -n "$opt" ]]; then
            PROFILE_FILE="$PROFILES_DIR/$opt"

            CURRENT_NAME=$(grep "user.name" "$PROFILE_FILE" | cut -d'"' -f2)
            CURRENT_EMAIL=$(grep "user.email" "$PROFILE_FILE" | cut -d'"' -f2)
            GPG_LINE=$(grep "^git config user.signingkey" "$PROFILE_FILE" || true)
            GPG_SIGN_LINE=$(grep "commit.gpgsign" "$PROFILE_FILE" || true)

            echo " [i] Leave blank and press Enter to keep current values."
            echo "------------------------------------------------------------------"
            read -p " [?] New Git Name  [$CURRENT_NAME]: " NEW_NAME
            NEW_NAME=${NEW_NAME:-$CURRENT_NAME}

            read -p " [?] New Git Email [$CURRENT_EMAIL]: " NEW_EMAIL
            NEW_EMAIL=${NEW_EMAIL:-$CURRENT_EMAIL}
            echo "------------------------------------------------------------------"

            cat <<EOT > "$PROFILE_FILE"
git config user.name "$NEW_NAME"
git config user.email "$NEW_EMAIL"
EOT
            if [[ -n "$GPG_LINE" ]]; then
                echo "$GPG_LINE" >> "$PROFILE_FILE"
                echo "$GPG_SIGN_LINE" >> "$PROFILE_FILE"
            fi
            echo ""
            echo " [+] Identity '$opt' has been updated."
            break
        else
            echo " [!] Invalid selection."
        fi
    done
    read -p " Press Enter to return..."
}

# --- FUNCTION: DELETE ACCOUNT ---
delete_identity() {
    clear
    echo "=================================================================="
    echo " [ DELETE ]  REMOVE AN IDENTITY"
    echo "=================================================================="
    echo ""

    get_profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo " [i] No identities found to remove."
        read -p " Press Enter to return..." && return
    fi

    PS3=" [?] Select an identity to remove: "
    select opt in "${profiles[@]}" "Cancel"; do
        echo ""
        if [[ "$opt" == "Cancel" ]]; then
            echo " [*] Canceled."
            break
        elif [[ -n "$opt" ]]; then
            read -p " [!] Are you sure you want to delete profile '$opt'? (y/N): " CONFIRM
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                rm "$PROFILES_DIR/$opt" 2>/dev/null
                rm "$SSH_CONF_DIR/$opt.conf" 2>/dev/null

                grep -v "alias as-$opt=" "$SHELL_PROFILE" | grep -v "alias as-$opt-global=" > "${SHELL_PROFILE}.tmp"
                mv "${SHELL_PROFILE}.tmp" "$SHELL_PROFILE"

                echo ""
                echo " [+] Profile '$opt' and its SSH configuration have been deleted."
                echo " [i] Note: Your physical SSH and GPG keys remain intact on disk for safety."
            else
                echo ""
                echo " [*] Deletion aborted."
            fi
            break
        else
            echo " [!] Invalid selection."
        fi
    done
    read -p " Press Enter to return..."
}

# --- FUNCTION: PRINT PUBLIC KEYS ---
print_keys() {
    clear
    echo "=================================================================="
    echo " [ KEYS ]  REVEAL PUBLIC KEYS"
    echo "=================================================================="
    echo ""

    get_profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo " [i] No identities found."
        read -p " Press Enter to return..." && return
    fi

    PS3=" [?] Select an identity: "
    select opt in "${profiles[@]}" "Cancel"; do
        echo ""
        if [[ "$opt" == "Cancel" ]]; then
            break
        elif [[ -n "$opt" ]]; then
            CONF_FILE="$SSH_CONF_DIR/$opt.conf"
            if [ -f "$CONF_FILE" ]; then
                SSH_PATH=$(grep "IdentityFile" "$CONF_FILE" | awk '{print $2}')
                SSH_PUB_KEY="${SSH_PATH}.pub"
                if [ -f "$SSH_PUB_KEY" ]; then
                    echo "------------------------------------------------------------------"
                    echo " 🗝️  SSH PUBLIC KEY ($SSH_PUB_KEY):"
                    echo "------------------------------------------------------------------"
                    cat "$SSH_PUB_KEY"
                    echo ""
                else
                    echo " [i] SSH public key not found at $SSH_PUB_KEY"
                fi
            else
                echo " [i] No SSH configuration found for '$opt'."
            fi

            PROFILE_FILE="$PROFILES_DIR/$opt"
            GPG_ID=$(grep "^git config user.signingkey" "$PROFILE_FILE" | awk '{print $4}' || true)
            if [[ -n "$GPG_ID" ]]; then
                echo "------------------------------------------------------------------"
                echo " 🛡️  GPG PUBLIC KEY ($GPG_ID):"
                echo "------------------------------------------------------------------"
                gpg --armor --export "$GPG_ID"
                echo ""
            else
                echo " [i] No GPG key is bound to this identity."
            fi
            break
        else
            echo " [!] Invalid selection."
        fi
    done
    read -p " Press Enter to return..."
}

# --- FUNCTION: RUN DOCTOR ---
run_doctor() {
    clear
    echo "=================================================================="
    echo " [ DOCTOR ]  SYSTEM HEALTH CHECK & AUTO-FIX"
    echo "=================================================================="
    echo ""
    echo " [*] Scanning system health..."
    echo ""

    if [ -d "$HOME/.ssh" ]; then
        SSH_PERMS=$(stat -c %a "$HOME/.ssh" 2>/dev/null || stat -f %Lp "$HOME/.ssh" 2>/dev/null || echo "unknown")
        if [ "$SSH_PERMS" != "unknown" ] && [ "$SSH_PERMS" != "700" ]; then
            chmod 700 "$HOME/.ssh"
            echo " [+] Fixed ~/.ssh directory permissions (Set to 700)."
        fi
    fi

    if [ -f "$HOME/.ssh/config" ]; then
        CONF_PERMS=$(stat -c %a "$HOME/.ssh/config" 2>/dev/null || stat -f %Lp "$HOME/.ssh/config" 2>/dev/null || echo "unknown")
        if [ "$CONF_PERMS" != "unknown" ] && [ "$CONF_PERMS" != "600" ]; then
            chmod 600 "$HOME/.ssh/config"
            echo " [+] Fixed ~/.ssh/config file permissions (Set to 600)."
        fi
    fi

    if ! grep -q "^Include ~/.ssh/git-manager.d/\*" "$SSH_DIR/config" 2>/dev/null; then
        echo -e "Include ~/.ssh/git-manager.d/*\n$(cat "$SSH_DIR/config" 2>/dev/null)" > "$SSH_DIR/config"
        echo " [+] Fixed missing Include directive in primary SSH config."
    fi

    get_profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo " [i] No identities found. Vault is empty."
    else
        for opt in "${profiles[@]}"; do
            PROFILE_FILE="$PROFILES_DIR/$opt"
            SWITCH_CMD="as-$opt"
            GLOBAL_SWITCH_CMD="as-$opt-global"
            if ! grep -q "alias $SWITCH_CMD=" "$SHELL_PROFILE" 2>/dev/null; then
                echo "alias $SWITCH_CMD='source \"$PROFILE_FILE\" && echo \" [+] Switched to identity: $opt (Local)\"'" >> "$SHELL_PROFILE"
                echo " [+] Restored missing local alias 'as-$opt' in $SHELL_PROFILE."
            fi
            if ! grep -q "alias $GLOBAL_SWITCH_CMD=" "$SHELL_PROFILE" 2>/dev/null; then
                echo "alias $GLOBAL_SWITCH_CMD='sed \"s/git config/git config --global/g\" \"$PROFILE_FILE\" | bash && echo \" [+] Switched to identity: $opt (Global)\"'" >> "$SHELL_PROFILE"
                echo " [+] Restored missing global alias 'as-$opt-global' in $SHELL_PROFILE."
            fi

            CONF_FILE="$SSH_CONF_DIR/$opt.conf"
            if [ -f "$CONF_FILE" ]; then
                SSH_PATH=$(grep "IdentityFile" "$CONF_FILE" | awk '{print $2}')
                if [ ! -f "$SSH_PATH" ]; then
                    echo " [!] WARNING: Private SSH key missing for '$opt' at ($SSH_PATH)."
                fi
            fi

            GPG_ID=$(grep "^git config user.signingkey" "$PROFILE_FILE" | awk '{print $4}' || true)
            if [[ -n "$GPG_ID" ]]; then
                if ! gpg --list-secret-keys "$GPG_ID" >/dev/null 2>&1; then
                    echo " [!] WARNING: GPG Key '$GPG_ID' for '$opt' is not in local keychain."
                fi
            fi
        done
    fi

    echo ""
    echo " [ OK ] Health check complete! Fixable issues have been resolved."
    echo ""
    [[ -z "$CLI_MODE" ]] && read -p " Press Enter to return..." || true
}

# --- FUNCTION: QUICK GUIDE ---
quick_guide() {
    clear
    echo "=================================================================="
    echo " [ GUIDE ]  HOW TO USE GIT IDENTITY MANAGER"
    echo "=================================================================="
    echo ""
    echo " 1. HOW TO CLONE A REPOSITORY"
    echo " ----------------------------------------------------------------"
    echo " When you clone a repo, tell Git which SSH key to use by adding"
    echo " your identity nickname to the clone URL."
    echo ""
    echo " Standard Clone URL:  git clone git@github.com:Org/Repo.git"
    echo " Modified Clone URL:  git clone git@github.com-NICKNAME:Org/Repo.git"
    echo ""
    echo " Example for 'work':  git clone git@github.com-work:Org/Repo.git"
    echo ""
    echo ""
    echo " 2. HOW TO APPLY YOUR IDENTITY (NAME, EMAIL, GPG)"
    echo " ----------------------------------------------------------------"
    echo " After cloning, move into your project folder and apply your"
    echo " identity using the terminal aliases generated during setup:"
    echo ""
    echo " LOCALLY (only for the current folder):"
    echo " -> Type:  as-NICKNAME  (e.g., as-work, as-personal)"
    echo ""
    echo " GLOBALLY (default for all future repos):"
    echo " -> Type:  as-NICKNAME-global  (e.g., as-work-global)"
    echo ""
    echo ""
    echo " 3. QUICK-SWITCH ALIASES — TEMPLATE & SAMPLES"
    echo " ----------------------------------------------------------------"
    echo " Two aliases are auto-injected into your ~/.zshrc or ~/.bashrc"
    echo " every time you create or import a profile."
    echo ""
    echo " ALIAS FORMAT:"
    echo "   as-NICKNAME          → apply to current repo  (local .git/config)"
    echo "   as-NICKNAME-global   → apply system-wide      (global ~/.gitconfig)"
    echo ""
    echo " SAMPLE ALIASES WRITTEN TO YOUR SHELL RC FILE:"
    echo "   alias as-work='source \"~/.git-manager/profiles/work\" ...'"
    echo "   alias as-work-global='sed ... | bash ...'"
    echo "   alias as-personal='source \"~/.git-manager/profiles/personal\" ...'"
    echo "   alias as-personal-global='sed ... | bash ...'"
    echo ""
    echo " SAMPLE DAILY WORKFLOW:"
    echo "   \$ git clone git@github.com-work:MyOrg/project.git"
    echo "   \$ cd project"
    echo "   \$ as-work"
    echo "    [+] Switched to identity: work (Local)"
    echo "   \$ git config user.name    # -> Alice Work"
    echo "   \$ git config user.email   # -> alice@work.com"
    echo ""
    echo "   # Or set a global default for all repos:"
    echo "   \$ as-personal-global"
    echo "    [+] Switched to identity: personal (Global)"
    echo ""
    echo " TIP: Restart your terminal once after first setup so the"
    echo "      aliases become available in every new shell session."
    echo "=================================================================="
    echo ""
    read -p " Press Enter to return to the menu..."
}

# --- FUNCTION: MANAGE SETTINGS ---
manage_settings() {
    while true; do
        clear
        echo "=================================================================="
        echo " [ SETTINGS ]  CONFIGURE GIT IDENTITY MANAGER"
        echo "=================================================================="
        echo ""
        echo "  Toggle an option to enable or disable it."
        echo ""

        local upd_status chg_status
        [[ "$SETTING_AUTO_UPDATE_CHECK" == "true" ]] && upd_status="ENABLED " || upd_status="DISABLED"
        [[ "$SETTING_SHOW_CHANGELOG"    == "true" ]] && chg_status="ENABLED " || chg_status="DISABLED"

        printf "  [1] Auto Update Check on Startup : [%s]\n" "$upd_status"
        printf "  [2] Show Changelog After Upgrade  : [%s]\n" "$chg_status"
        echo ""
        echo "  [3] Check for Updates Now"
        echo "  [0] Back to Main Menu"
        echo ""
        echo "=================================================================="
        [[ -z "$CLI_MODE" ]] && read -p " -> Select an option [0-3]: " setting_choice || return 0

        case $setting_choice in
            1)
                if [[ "$SETTING_AUTO_UPDATE_CHECK" == "true" ]]; then
                    save_setting "AUTO_UPDATE_CHECK" "false"
                    echo " [+] Auto update check DISABLED."
                else
                    save_setting "AUTO_UPDATE_CHECK" "true"
                    echo " [+] Auto update check ENABLED."
                fi
                sleep 1
                ;;
            2)
                if [[ "$SETTING_SHOW_CHANGELOG" == "true" ]]; then
                    save_setting "SHOW_CHANGELOG" "false"
                    echo " [+] Changelog display DISABLED."
                else
                    save_setting "SHOW_CHANGELOG" "true"
                    echo " [+] Changelog display ENABLED."
                fi
                sleep 1
                ;;
            3)
                # Temporarily bypass the setting guard so a manual trigger always works
                local _saved="$SETTING_AUTO_UPDATE_CHECK"
                SETTING_AUTO_UPDATE_CHECK="true"
                check_for_updates
                SETTING_AUTO_UPDATE_CHECK="$_saved"
                ;;
            0) break ;;
            *) echo "" ; echo " [!] Invalid option." ; sleep 1 ;;
        esac
    done
}

# --- COMMAND LINE ARGUMENT PARSER & HELP MENU ---
print_help() {
    echo "Git Identity Manager (v$VERSION)"
    echo "Usage: git-identity-manager [command] [options]"
    echo ""
    echo "Commands:"
    echo "  setup                 Launch interactive setup (Generate new keys)"
    echo "  import                Launch interactive import (Link existing keys)"
    echo "  switch <profile>      Switch local repository to <profile>"
    echo "  global <profile>      Switch global git config to <profile>"
    echo "  view                  View all configured profiles"
    echo "  doctor                Run system health check and auto-fix"
    echo "  update                Force check for script updates"
    echo "  settings              Open settings menu"
    echo "  --help, -h            Display this help message"
    echo ""
    echo "Example:"
    echo "  git-identity-manager switch work"
    echo "  git-identity-manager global personal"
}

# ==============================================================================
# ENTRY POINT — only runs when executed directly, never when sourced (e.g. tests)
# ==============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CLI_MODE=true
    case "$1" in
        --help|-h|help) print_help; exit 0 ;;
        setup) setup_identity; exit 0 ;;
        import) import_identity; exit 0 ;;
        switch) switch_identity "$2" "local"; exit 0 ;;
        global) switch_identity "$2" "global"; exit 0 ;;
        view) view_profiles; exit 0 ;;
        doctor) run_doctor; exit 0 ;;
        update) check_for_updates; exit 0 ;;
        settings) load_settings; manage_settings; exit 0 ;;
        "") CLI_MODE="" ;; # No args, launch GUI
        *) echo "Unknown command: $1"; print_help; exit 1 ;;
    esac

    # --- MAIN MENU LOOP ---
    load_settings         # Load persisted user preferences
    check_for_updates     # Check on startup; prompts if update available (with changelog)
    show_changelog_once   # Show changelog once after a fresh upgrade

    while true; do
        clear
        echo "=================================================================="
        echo "               G I T   I D E N T I T Y   M A N A G E R            "
        echo "                        Version: $VERSION                         "
        echo "=================================================================="
        echo ""
        echo "    [ 1 ] Setup New Account (Generate Keys)"
        echo "    [ 2 ] Import Existing Account (Link Keys)"
        echo "    [ 3 ] Switch Account (Local / Global)"
        echo "    [ 4 ] View All Profiles"
        echo "    [ 5 ] Modify a Profile"
        echo "    [ 6 ] Delete a Profile"
        echo "    [ 7 ] View Public Keys (SSH/GPG)"
        echo "    [ 8 ] Run Doctor (Validate & Auto-Fix)"
        echo "    [ 9 ] Quick Guide & How-To"
        echo "    [10 ] Settings"
        echo "    [ 0 ] Exit"
        echo ""
        echo "=================================================================="
        read -p " -> Select an option [0-9/10]: " choice

        case $choice in
            1)  setup_identity ;;
            2)  import_identity ;;
            3)  switch_identity ;;
            4)  view_profiles ;;
            5)  modify_identity ;;
            6)  delete_identity ;;
            7)  print_keys ;;
            8)  run_doctor ;;
            9)  quick_guide ;;
            10) manage_settings ;;
            0)  echo "" ; echo " Exiting system. Goodbye." ; echo "" ; exit 0 ;;
            *)  echo "" ; echo " [!] Invalid option." ; sleep 1 ;;
        esac
    done
fi
