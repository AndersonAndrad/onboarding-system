#!/bin/bash

set -e

if [ "$(uname -s)" != "Darwin" ]; then
  echo "❌ This script must be run on macOS."
  exit 1
fi

echo "🍺 Installing Homebrew and development tools..."

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Complete the installation window, then run this script again."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

BREW_SHELLENV='eval "$('"$(brew --prefix)"'/bin/brew shellenv)"'
touch "$HOME/.zprofile"
if ! grep -qF 'brew shellenv' "$HOME/.zprofile"; then
  printf '\n# Homebrew\n%s\n' "$BREW_SHELLENV" >> "$HOME/.zprofile"
fi

brew update
brew install git

echo "⬢ Installing nvm..."
export PROFILE="$HOME/.zshrc"
touch "$PROFILE"

if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  echo "ℹ️ nvm is already installed"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "✅ Base software installed for $(uname -m)"
