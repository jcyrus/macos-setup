#!/bin/bash
# install.sh - Installs Brewfile and configures the environment

set -e # Fail immediately if a command fails

echo "🚀 Starting Day 1 Installation..."

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "🍺 Homebrew already installed. Updating..."
    brew update
fi

# 2. Bundle Apps
echo "📦 Installing apps from Brewfile..."
brew bundle --file=./Brewfile || true # Continue even if one app fails

# 3. Configure Zsh + Starship
echo "🐚 Generating .zshrc..."
# Install Oh My Zsh (for plugin management)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Overwrite .zshrc with Modern Settings
cat <<EOT > ~/.zshrc
# --- Path & Brew ---
eval "\$(/opt/homebrew/bin/brew shellenv)"

# --- Oh My Zsh ---
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="" # Disabled for Starship
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

# 4. Language Setup
echo "🦀 Setting up Rust..."
rustup-init -y --no-modify-path

echo "📱 Setting up Node (LTS)..."
# FNM env needs to be eval'd in this script scope to work
eval "$(fnm env)"
fnm install --lts

echo "✅ Done! Restart your terminal (Warp) to see your new setup."