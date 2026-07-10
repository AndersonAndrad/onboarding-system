#!/bin/bash
set -e
trap 'echo "❌ Error at line $LINENO"; exit 1' ERR

echo "🚀 Configuring global commit workflow..."

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true

if ! command -v node >/dev/null 2>&1; then
  echo "⬢ Installing the latest Node.js LTS via nvm..."
  nvm install --lts
  nvm alias default 'lts/*'
fi
nvm use --lts >/dev/null

npm install -g commitizen cz-conventional-changelog @commitlint/cli @commitlint/config-conventional

cat > "$HOME/.czrc" <<'EOF'
{
  "path": "cz-conventional-changelog"
}
EOF

mkdir -p "$HOME/.config/commitlint" "$HOME/.husky" "$HOME/.local/bin"
cat > "$HOME/.config/commitlint/commitlint.config.js" <<'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore', 'perf', 'build', 'ci', 'revert']],
    'header-max-length': [0],
    'subject-empty': [0],
    'subject-case': [0],
    'scope-empty': [0],
  },
};
EOF

git config --global core.hooksPath "$HOME/.husky"
cat > "$HOME/.husky/commit-msg" <<'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true
MSG_FILE="$1"
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [ -f "$GIT_DIR/COMMITIZEN_IN_PROGRESS" ] && command -v commitlint >/dev/null 2>&1; then
  commitlint --config "$HOME/.config/commitlint/commitlint.config.js" --edit "$MSG_FILE"
fi
EOF
chmod +x "$HOME/.husky/commit-msg"

cat > "$HOME/.local/bin/commit" <<'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Not a git repository"
  exit 1
fi
if [ $# -eq 0 ]; then
  GIT_DIR=$(git rev-parse --git-dir)
  touch "$GIT_DIR/COMMITIZEN_IN_PROGRESS"
  trap 'rm -f "$GIT_DIR/COMMITIZEN_IN_PROGRESS"' EXIT
  cz
else
  git commit "$@"
fi
EOF
chmod +x "$HOME/.local/bin/commit"

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
touch "$HOME/.zshrc"
if ! grep -qF '.local/bin' "$HOME/.zshrc"; then
  printf '\n# Local user binaries\n%s\n' "$PATH_LINE" >> "$HOME/.zshrc"
fi

echo "✅ Commit workflow configured. Run: commit"
