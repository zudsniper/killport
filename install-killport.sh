#!/usr/bin/env bash
# install-killport.sh — Auto-installer for killport.sh via curl | bash
# Installs killport.sh into ~/.killport and symlinks it as "killport" in /usr/local/bin

set -e

REPO_URL="https://github.com/zudsniper/killport.git"
INSTALL_DIR="$HOME/.killport"
BIN_NAME="killport"
SYSTEM_BIN_DIR="/usr/local/bin"
TARGET_LINK="$SYSTEM_BIN_DIR/$BIN_NAME"

echo "🚀 Installing killport…"

# 1. Clone or update the repo
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "🔄 Updating existing installation in $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "📥 Cloning into $INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 2. Ensure killport.sh exists
if [ ! -f "$INSTALL_DIR/killport.sh" ]; then
  echo "❌ Error: killport.sh not found in cloned repo" >&2
  exit 1
fi

# 3. Ensure system bin dir exists
if [ ! -d "$SYSTEM_BIN_DIR" ]; then
  echo "🔧 Creating $SYSTEM_BIN_DIR"
  sudo mkdir -p "$SYSTEM_BIN_DIR"
fi

# 4. Create or update symlink
echo "🔗 Linking $INSTALL_DIR/killport.sh → $TARGET_LINK"
sudo ln -sf "$INSTALL_DIR/killport.sh" "$TARGET_LINK"
sudo chmod +x "$INSTALL_DIR/killport.sh" "$TARGET_LINK"

echo "✅ Installed killport to $TARGET_LINK"
echo "👉 You can now run: killport <port1> [port2,…]"
