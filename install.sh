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

# --- 5. Configure Shell ---
echo "🐚 Configuring Zsh..."

# Check if .zshrc exists and back it up
if [ -f "$HOME/.zshrc" ]; then
    echo "📝 Backing up existing .zshrc to .zshrc.backup..."
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

# Function to append if not exists
append_if_missing() {
    grep -qF "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"
}

# Ensure Homebrew is in path (idempotent)
if ! grep -q "shellenv" "$HOME/.zshrc"; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
fi

# Oh My Zsh Setup (Only if not present)
if ! grep -q "oh-my-zsh.sh" "$HOME/.zshrc"; then
    cat <<EOT >> ~/.zshrc

# --- Oh My Zsh (MacOS Setup) ---
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zoxide brew)
source \$ZSH/oh-my-zsh.sh
EOT
fi

# Tools & Aliases (Use a marker to avoid dupes)
if ! grep -q "# --- MacOS Setup Tools ---" "$HOME/.zshrc"; then
    cat <<EOT >> ~/.zshrc

# --- MacOS Setup Tools ---
eval "\$(starship init zsh)"
eval "\$(zoxide init zsh)"
eval "\$(fnm env --use-on-cd)"

alias ls="eza --icons"
alias ll="eza -l --icons"
alias cat="bat"
alias f="fvm flutter"
alias lg="lazygit"

export PATH="\$HOME/.cargo/bin:\$PATH"
EOT
fi

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