#!/bin/bash
# install.sh

set -e # Fail immediately if any command fails

echo "🚀 Starting Day 1 Installation..."

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "🍺 Homebrew found. Updating..."
    brew update
fi

# 2. Pre-Tap Essential Repositories
echo "🔗 Tapping repositories..."
brew tap leoafarias/fvm

# 3. Bundle Apps
echo "📦 Installing apps from Brewfile..."
brew bundle --file=./Brewfile

# 4. Configure Shell
echo "🐚 Setting up Zsh..."
# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

cat <<EOT > ~/.zshrc
# --- Path & Brew ---
eval "\$(/opt/homebrew/bin/brew shellenv)"

# --- Oh My Zsh ---
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="" 
plugins=(git zoxide brew docker)
source \$ZSH/oh-my-zsh.sh

# --- Tools Init ---
eval "\$(starship init zsh)"
eval "\$(zoxide init zsh)"
eval "\$(fnm env --use-on-cd)"

# --- Aliases ---
alias ls="eza --icons"
alias ll="eza -l --icons"
alias cat="bat"
alias f="fvm flutter" 
alias lg="lazygit"

# --- Path Additions ---
export PATH="\$HOME/.cargo/bin:\$PATH"
EOT

# 5. Language Setup
echo "🦀 Setting up Rust..."
# We check if rustup-init installed correctly
if command -v rustup-init &> /dev/null; then
    rustup-init -y --no-modify-path
else
    echo "❌ Error: rustup-init not found. Brew installation failed."
    exit 1
fi

echo "📱 Setting up Node (LTS)..."
eval "$(fnm env)"
fnm install --lts

echo "✅ Done! Restart Warp."