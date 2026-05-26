#!/bin/bash

set -e

PERSONAL_EMAIL="anderson_andrade_@outlook.com"
STONE_EMAIL="a.asilva@stone.com.br"

SSH_DIR="$HOME/.ssh"

PERSONAL_KEY_NAME="id_ed25519_github"
STONE_KEY_NAME="id_ed25519_github_stone"

PERSONAL_HOST="github.com"
STONE_HOST="github-stone"

echo "🔐 Setting up multiple GitHub SSH keys..."

# Create .ssh folder if not exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

generate_key() {
  local EMAIL=$1
  local KEY_NAME=$2

  if [ -f "$SSH_DIR/$KEY_NAME" ]; then
    echo "⚠️ SSH key already exists: $SSH_DIR/$KEY_NAME"
  else
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_DIR/$KEY_NAME" -N ""
    echo "✅ SSH key generated: $KEY_NAME"
  fi
}

# Generate personal key
generate_key "$PERSONAL_EMAIL" "$PERSONAL_KEY_NAME"

# Generate stone key
generate_key "$STONE_EMAIL" "$STONE_KEY_NAME"

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add "$SSH_DIR/$PERSONAL_KEY_NAME"
ssh-add "$SSH_DIR/$STONE_KEY_NAME"

SSH_CONFIG="$SSH_DIR/config"

# Backup old config
touch "$SSH_CONFIG"

# Remove old duplicated configs
sed -i '/Host github.com/,+4d' "$SSH_CONFIG"
sed -i '/Host github-stone/,+4d' "$SSH_CONFIG"

# Create SSH config
cat <<EOF >> "$SSH_CONFIG"

Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_DIR/$PERSONAL_KEY_NAME
  IdentitiesOnly yes

Host github-stone
  HostName github.com
  User git
  IdentityFile $SSH_DIR/$STONE_KEY_NAME
  IdentitiesOnly yes
EOF

chmod 600 "$SSH_CONFIG"

echo ""
echo "✅ SSH config updated"

echo ""
echo "📋 PERSONAL PUBLIC KEY"
echo "-----------------------------------"
cat "$SSH_DIR/$PERSONAL_KEY_NAME.pub"
echo "-----------------------------------"

echo ""
echo "📋 STONE PUBLIC KEY"
echo "-----------------------------------"
cat "$SSH_DIR/$STONE_KEY_NAME.pub"
echo "-----------------------------------"

echo ""
echo "👉 Add both keys to the correct GitHub accounts:"
echo "https://github.com/settings/keys"

echo ""
echo "🧪 Test personal account:"
echo "ssh -T git@github.com"

echo ""
echo "🧪 Test stone account:"
echo "ssh -T git@github-stone"

echo ""
echo "📦 Example clone personal:"
echo "git clone git@github.com:username/repository.git"

echo ""
echo "📦 Example clone stone:"
echo "git clone git@github-stone:StonePayments/repository.git"