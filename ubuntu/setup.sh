#!/bin/bash

set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting full setup..."

bash "$SCRIPTS_DIR/softwares.sh"
bash "$SCRIPTS_DIR/git.sh"
bash "$SCRIPTS_DIR/ssh-github.sh"
bash "$SCRIPTS_DIR/zsh.sh"
bash "$SCRIPTS_DIR/commit.sh"

echo "Setup complete."
