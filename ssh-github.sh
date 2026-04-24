#!/bin/bash

set -e

EMAIL="anderson_andrade_@outlook.com"
SSH_DIR="$HOME/.ssh"
KEY_NAME="id_ed25519_github"

echo "🔐 Setting up SSH for GitHub..."

# Create .ssh folder if not exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate key if it doesn't exist
if [ -f "$SSH_DIR/$KEY_NAME" ]; then
  echo "⚠️ SSH key already exists: $SSH_DIR/$KEY_NAME"
else
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_DIR/$KEY_NAME" -N ""
  echo "✅ SSH key generated"
fi

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add "$SSH_DIR/$KEY_NAME"

# Create SSH config (idempotent)
SSH_CONFIG="$SSH_DIR/config"

if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
  cat <<EOF >> "$SSH_CONFIG"

Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_DIR/$KEY_NAME
  IdentitiesOnly yes
EOF

  echo "✅ SSH config updated"
else
  echo "ℹ️ SSH config already contains github.com"
fi

chmod 600 "$SSH_CONFIG"

# Show public key
echo ""
echo "📋 Copy this public key to GitHub:"
echo "-----------------------------------"
cat "$SSH_DIR/$KEY_NAME.pub"
echo "-----------------------------------"

echo ""
echo "👉 Go to: https://github.com/settings/keys"
echo "👉 Click: New SSH Key"
echo "👉 Paste the key above"

echo ""
echo "🧪 After adding, test with:"
echo "ssh -T git@github.com"