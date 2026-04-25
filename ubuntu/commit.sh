#!/bin/bash
set -e
trap 'echo "❌ Error at line $LINENO"; exit 1' ERR

# ─────────────────────────────────────────────────────────────────────────────
# COMMIT.SH — Global commit workflow: Commitizen + CommitLint + Husky
#
# After running this script:
#   commit              → interactive Commitizen prompt (validated by CommitLint)
#   commit -m "msg"     → regular git commit, no validation
#   commit --amend      → amend last commit
#
# Works in any project regardless of package manager (npm, yarn, pnpm, bun...)
# No per-project setup needed.
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "🚀 Configuring global commit workflow..."
echo "   Commitizen + CommitLint + Husky"
echo ""

# ── 1. Load nvm if available ──────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true

if command -v nvm >/dev/null 2>&1; then
  nvm use --lts >/dev/null 2>&1 || true
fi

# ── 2. Ensure Node.js and npm are available ───────────────────────────────────
if ! command -v node >/dev/null 2>&1; then
  echo "⚠️  Node.js not found. Installing via nvm..."

  if [ ! -d "$HOME/.nvm" ]; then
    echo "   Installing nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    \. "$NVM_DIR/nvm.sh"
  fi

  nvm install --lts
  nvm use --lts
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm not found even after nvm setup. Cannot continue."
  exit 1
fi

echo "✅ Node.js $(node --version) | npm $(npm --version)"

# ── 3. Install global npm packages ───────────────────────────────────────────
echo ""
echo "📦 Installing global packages..."
npm install -g \
  commitizen \
  cz-conventional-changelog \
  @commitlint/cli \
  @commitlint/config-conventional \
  2>&1 | grep -E "(added|updated|warn EM|ERR!)" || true

echo "✅ Packages installed"

# ── 4. Configure Commitizen ───────────────────────────────────────────────────
echo ""
echo "⚙️  Configuring Commitizen..."
cat > "$HOME/.czrc" << 'EOF'
{
  "path": "cz-conventional-changelog"
}
EOF
echo "✅ ~/.czrc configured"

# ── 5. Configure CommitLint ───────────────────────────────────────────────────
echo ""
echo "⚙️  Configuring CommitLint..."
mkdir -p "$HOME/.config/commitlint"
cat > "$HOME/.config/commitlint/commitlint.config.js" << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat',
      'fix',
      'docs',
      'style',
      'refactor',
      'test',
      'chore',
      'perf',
      'build',
      'ci',
      'revert',
    ]],
    'header-max-length': [0],
    'subject-empty': [0],
    'subject-case': [0],
    'scope-empty': [0],
  },
};
EOF
echo "✅ CommitLint config → ~/.config/commitlint/commitlint.config.js"

# ── 6. Configure Husky (global hooks) ────────────────────────────────────────
echo ""
echo "⚙️  Configuring Husky (global hooks at ~/.husky)..."
mkdir -p "$HOME/.husky"
git config --global core.hooksPath "$HOME/.husky"

cat > "$HOME/.husky/commit-msg" << 'HOOK'
#!/bin/bash

# Hooks run in a non-interactive shell — source nvm so commitlint is on PATH
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true

MSG_FILE="$1"
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)

# Only lint when the interactive `commit` command triggered this commit
if [ -f "$GIT_DIR/COMMITIZEN_IN_PROGRESS" ]; then
  if command -v commitlint >/dev/null 2>&1; then
    commitlint \
      --config "$HOME/.config/commitlint/commitlint.config.js" \
      --edit "$MSG_FILE"
    exit $?
  fi
fi

exit 0
HOOK

chmod +x "$HOME/.husky/commit-msg"
echo "✅ commit-msg hook created and enabled"

# ── 7. Create the `commit` command ───────────────────────────────────────────
echo ""
echo "⚙️  Creating 'commit' command..."
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/commit" << 'CMD'
#!/bin/bash

# Source nvm and activate the default node version so global bins (cz, commitlint) are on PATH
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Not a git repository"
  exit 1
fi

if [ $# -eq 0 ]; then
  # ── Interactive path: Commitizen → CommitLint validates ──
  GIT_DIR=$(git rev-parse --git-dir)
  touch "$GIT_DIR/COMMITIZEN_IN_PROGRESS"
  trap 'rm -f "$GIT_DIR/COMMITIZEN_IN_PROGRESS"' EXIT
  cz
else
  # ── Direct path: regular git commit (commit -m, --amend, etc.) ──
  git commit "$@"
fi
CMD

chmod +x "$HOME/.local/bin/commit"
echo "✅ 'commit' command → ~/.local/bin/commit"

# ── 8. Ensure ~/.local/bin is in PATH ────────────────────────────────────────
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$RC_FILE" ] && ! grep -qF '.local/bin' "$RC_FILE"; then
    printf '\n# Local user binaries\n%s\n' "$PATH_LINE" >> "$RC_FILE"
    echo "✅ PATH updated in $RC_FILE"
  fi
done

source ~/.zshrc 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅  Commit workflow configured successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  commit              → interactive Commitizen prompt"
echo "  commit -m 'msg'     → regular git commit (no validation)"
echo "  commit --amend      → amend last commit"
echo ""
echo "   to start using the 'commit' command."
echo ""
