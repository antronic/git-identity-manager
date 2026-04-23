#!/bin/bash

# ==============================================================================
# Git Identity Manager - Installer
# ==============================================================================

REPO_URL="https://raw.githubusercontent.com/antronic/git-identity-manager/main/git-manager.sh"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_PATH="$INSTALL_DIR/git-manager"

echo " [*] Installing Git Identity Manager..."

# Ensure the local bin directory exists
mkdir -p "$INSTALL_DIR"

# Download the latest version of the script
if curl -sL "$REPO_URL" -o "$SCRIPT_PATH"; then
    chmod +x "$SCRIPT_PATH"
    echo " [+] Successfully downloaded to $SCRIPT_PATH"
else
    echo " [!] Download failed. Please check your internet connection."
    exit 1
fi

# Check if ~/.local/bin is in the user's PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo " [!] Warning: $INSTALL_DIR is not in your PATH."
    echo "     To use 'git-manager' from anywhere, add this to your ~/.bashrc or ~/.zshrc:"
    echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "     For now, you can run it using: $SCRIPT_PATH"
else
    echo " [ OK ] Installation complete! You can now type 'git-manager' in your terminal."
fi
