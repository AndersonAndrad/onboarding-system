#!/bin/bash

set -e

echo "🐚 Installing Zsh and dependencies..."

sudo apt update
sudo apt install -y zsh git curl

# Install Oh My Zsh (non-interactive)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "⚡ Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "ℹ️ Oh My Zsh already installed"
fi

# Install Powerlevel10k theme
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "🎨 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
else
  echo "ℹ️ Powerlevel10k already installed"
fi

# Set theme in .zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Install useful plugins
PLUGINS_LINE='plugins=(git zsh-autosuggestions zsh-syntax-highlighting)'

# Clone plugins
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Replace plugins line
sed -i "s/^plugins=.*/$PLUGINS_LINE/" ~/.zshrc

# Set Zsh as default shell
echo "🔁 Setting Zsh as default shell..."
chsh -s $(which zsh)

echo "✅ Zsh setup complete!"
echo ""
echo "👉 Restart your WSL or run: exec zsh"
echo "👉 First run will open Powerlevel10k config wizard"