#!/bin/sh
set -eou pipefail

DOTFILES_REPO="${DOTFILES_REPO:-username/dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# Install mise if needed
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Use mise-managed `gh` for GitHub authentication
if ! mise exec gh@latest -- gh auth status --hostname github.com >/dev/null 2>&1; then
    mise exec gh@latest -- gh auth login --hostname github.com --git-protocol https --web
else
    echo "User was already authenticated on GitHub."
fi
mise exec gh@latest -- gh auth setup-git --hostname github.com

# Git is still required for the actual repository checkout
if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. On macOS run: \`xcode-select --install\`." >&2
  exit 1
fi

cd "$HOME"

if [ ! -d "$HOME/.git" ]; then
  git init -b "$DOTFILES_BRANCH"
  git remote add origin "https://github.com/$DOTFILES_REPO.git"
else
  git remote set-url origin "https://github.com/$DOTFILES_REPO.git"
fi

git fetch origin
git checkout -f -B "$DOTFILES_BRANCH" "origin/$DOTFILES_BRANCH"
git branch --set-upstream-to="origin/$DOTFILES_BRANCH" "$DOTFILES_BRANCH"

mise bootstrap --yes

echo "System environment bootstrap is complete!"
