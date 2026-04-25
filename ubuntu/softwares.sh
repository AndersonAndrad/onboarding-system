#!/bin/bash

set -e

echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing git..."
sudo apt install -y git

echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Done. Restart your terminal or run: source ~/.bashrc"
