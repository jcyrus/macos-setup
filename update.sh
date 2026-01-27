#!/bin/bash
# update.sh

set -e

echo "🔄 Starting Update Process..."

# 1. Update Homebrew itself
echo "🍺 Updating Homebrew..."
brew update

# 2. Upgrade installed packages
echo "⬆️  Upgrading packages..."
brew upgrade

# 3. Install new apps from Brewfile (and clean up old ones if you want to be strict, but we won't strictly cleanup to be flexible)
echo "📦 Installing/Updating apps from Brewfile..."
brew bundle --file=./Brewfile

# 4. Cleanup
echo "🧹 Cleaning up..."
brew cleanup

echo "✅ Update Complete!"
