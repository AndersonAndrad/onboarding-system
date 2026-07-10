#!/bin/bash

set -e

PERSONAL_EMAIL="anderson_andrade_@outlook.com"
STONE_EMAIL="a.asilva@stone.com.br"
SSH_DIR="$HOME/.ssh"
PERSONAL_KEY_NAME="id_ed25519_github"
STONE_KEY_NAME="id_ed25519_github_stone"

echo "🔐 Setting up multiple GitHub SSH keys with macOS Keychain..."

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

generate_key() {
  local email="$1"
  local key_name="$2"
  if [ -f "$SSH_DIR/$key_name" ]; then
    echo "⚠️ SSH key already exists: $SSH_DIR/$key_name"
  else
    ssh-keygen -t ed25519 -C "$email" -f "$SSH_DIR/$key_name" -N ""
    echo "✅ SSH key generated: $key_name"
  fi
}

generate_key "$PERSONAL_EMAIL" "$PERSONAL_KEY_NAME"
generate_key "$STONE_EMAIL" "$STONE_KEY_NAME"

ssh-add --apple-use-keychain "$SSH_DIR/$PERSONAL_KEY_NAME"
ssh-add --apple-use-keychain "$SSH_DIR/$STONE_KEY_NAME"

SSH_CONFIG="$SSH_DIR/config"
touch "$SSH_CONFIG"
cp "$SSH_CONFIG" "$SSH_CONFIG.backup"

# Remove only blocks managed by this script, leaving other SSH hosts untouched.
sed -i '' '/# BEGIN onboarding-system GitHub/,/# END onboarding-system GitHub/d' "$SSH_CONFIG"

cat >> "$SSH_CONFIG" <<EOF

# BEGIN onboarding-system GitHub
Host github.com
  HostName github.com
  User git
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_DIR/$PERSONAL_KEY_NAME
  IdentitiesOnly yes

Host github-stone
  HostName github.com
  User git
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_DIR/$STONE_KEY_NAME
  IdentitiesOnly yes
# END onboarding-system GitHub
EOF

chmod 600 "$SSH_CONFIG"

echo "✅ SSH config updated (backup: $SSH_CONFIG.backup)"
echo ""
echo "📋 PERSONAL PUBLIC KEY"
cat "$SSH_DIR/$PERSONAL_KEY_NAME.pub"
echo ""
echo "📋 STONE PUBLIC KEY"
cat "$SSH_DIR/$STONE_KEY_NAME.pub"
echo ""
echo "👉 Add both keys at: https://github.com/settings/keys"
echo "🧪 Personal: ssh -T git@github.com"
echo "🧪 Stone:    ssh -T git@github-stone"
