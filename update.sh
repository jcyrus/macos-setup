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

# 3. Tap custom repositories (brew bundle would do this too, but tapping
# explicitly here surfaces any tap failure separately from bundle failures).
echo "🚰 Tapping jcyrus/tap and leoafarias/fvm..."
brew tap jcyrus/tap
brew tap leoafarias/fvm

# 4. Install new apps from Brewfile (and clean up old ones if you want to be strict, but we won't strictly cleanup to be flexible)
echo "📦 Installing/Updating apps from Brewfile..."
brew bundle --file="$REPO_DIR/Brewfile"

# 5. Cleanup
echo "🧹 Cleaning up..."
brew cleanup

echo "🦀 Updating Rust toolchain..."
# Homebrew's rustup formula links only `rustup` into its shim directory;
# rustc/cargo live there too. ~/.cargo/bin is where `cargo install` puts binaries.
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"
if command -v rustup &>/dev/null; then
    rustup update
else
    echo "⚠️  rustup not found. Skipping Rust update."
fi

echo "📱 Refreshing Node LTS (fnm)..."
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default lts-latest

echo "🧠 Syncing Neovim plugins (LazyVim)..."
if command -v nvim &>/dev/null; then
    nvim --headless "+Lazy! sync" +qa
fi

echo "📚 Updating tldr cache..."
if command -v tldr &>/dev/null; then
    tldr --update
fi
echo "🪟 Updating tmux plugins..."
if [ -x "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
else
    echo "⚠️  TPM not found. Skipping tmux plugin update."
fi

echo "✅ Update Complete!"
