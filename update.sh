#!/bin/bash
# update.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 Starting Update Process..."

# 1. Update Homebrew itself
echo "🍺 Updating Homebrew..."
brew update

# 2. Upgrade installed packages
echo "⬆️  Upgrading packages..."
brew upgrade

# 3. Install new apps from Brewfile (and clean up old ones if you want to be strict, but we won't strictly cleanup to be flexible)
echo "📦 Installing/Updating apps from Brewfile..."
brew bundle --file="$REPO_DIR/Brewfile"

# 4. Cleanup
echo "🧹 Cleaning up..."
brew cleanup

echo "🦀 Updating Rust toolchain..."
# install.sh runs rustup-init with --no-modify-path, so rustup may only exist
# under ~/.cargo/bin and not be on PATH in a non-interactive shell.
export PATH="$HOME/.cargo/bin:$PATH"
if command -v rustup &> /dev/null; then
	rustup update
else
	echo "⚠️  rustup not found. Skipping Rust update."
fi

echo "📱 Refreshing Node LTS (fnm)..."
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default lts-latest

echo "🧠 Syncing Neovim plugins (LazyVim)..."
if command -v nvim &> /dev/null; then
	nvim --headless "+Lazy! sync" +qa
fi

echo "📚 Updating tldr cache..."
if command -v tldr &> /dev/null; then
	tldr --update
fi

echo "✅ Update Complete!"
