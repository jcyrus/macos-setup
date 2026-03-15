#!/bin/bash
# install.sh

set -e # Fail immediately if any command fails

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

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
brew tap jcyrus/homebrew-tap

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

touch "$HOME/.zshrc"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

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
plugins=(git zoxide brew zsh-autosuggestions zsh-syntax-highlighting fzf)
source \$ZSH/oh-my-zsh.sh
EOT
elif grep -q "^plugins=(" "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=(.*/plugins=(git zoxide brew zsh-autosuggestions zsh-syntax-highlighting fzf)/' "$HOME/.zshrc"
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
alias help="tldr"

export PATH="\$HOME/.cargo/bin:\$PATH"
EOT
fi

if ! grep -q "fzf --zsh" "$HOME/.zshrc"; then
    cat <<'EOT' >> ~/.zshrc

# --- fzf (MacOS Setup) ---
if [ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]; then
  source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
fi
if [ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ]; then
  source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
fi
EOT
fi

echo "⚙️ Configuring Git defaults..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"

echo "🧠 Setting up Neovim config..."
mkdir -p "$HOME/.config"

needs_nvim_migration=false

if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
    needs_nvim_migration=true
fi

ln -sfn "$REPO_DIR/nvim" "$HOME/.config/nvim"

if [ "$needs_nvim_migration" = true ]; then
    for nvim_state_dir in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        if [ -d "$nvim_state_dir" ]; then
            mv "$nvim_state_dir" "$nvim_state_dir.backup.$(date +%s)"
        fi
    done
fi

echo "🪟 Setting up tmux..."
ln -sfn "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.tmux/plugins"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

CATPPUCCIN_TMUX_REPO="https://github.com/catppuccin/tmux.git"
CATPPUCCIN_TMUX_VERSION="v2.1.3"
CATPPUCCIN_TMUX_DIR="$HOME/.tmux/plugins/tmux"

backup_and_install_catppuccin_tmux() {
    if [ -e "$CATPPUCCIN_TMUX_DIR" ]; then
        mv "$CATPPUCCIN_TMUX_DIR" "$CATPPUCCIN_TMUX_DIR.backup.$(date +%s)"
    fi
    git clone -b "$CATPPUCCIN_TMUX_VERSION" "$CATPPUCCIN_TMUX_REPO" "$CATPPUCCIN_TMUX_DIR"
}

if [ -d "$CATPPUCCIN_TMUX_DIR/.git" ]; then
    origin_url="$(git -C "$CATPPUCCIN_TMUX_DIR" remote get-url origin 2>/dev/null || true)"
    if [ "$origin_url" = "$CATPPUCCIN_TMUX_REPO" ] || [ "$origin_url" = "git@github.com:catppuccin/tmux.git" ]; then
        if ! git -C "$CATPPUCCIN_TMUX_DIR" diff --quiet || ! git -C "$CATPPUCCIN_TMUX_DIR" diff --cached --quiet; then
            backup_and_install_catppuccin_tmux
        else
            git -C "$CATPPUCCIN_TMUX_DIR" fetch --tags --quiet
            git -C "$CATPPUCCIN_TMUX_DIR" checkout --quiet -f "$CATPPUCCIN_TMUX_VERSION"
        fi
    else
        backup_and_install_catppuccin_tmux
    fi
elif [ ! -e "$CATPPUCCIN_TMUX_DIR" ]; then
    git clone -b "$CATPPUCCIN_TMUX_VERSION" "$CATPPUCCIN_TMUX_REPO" "$CATPPUCCIN_TMUX_DIR"
else
    backup_and_install_catppuccin_tmux
fi

echo "👻 Setting up Ghostty..."
needs_ghostty_migration=false

if [ -e "$HOME/.config/ghostty" ] && [ ! -L "$HOME/.config/ghostty" ]; then
    mv "$HOME/.config/ghostty" "$HOME/.config/ghostty.backup.$(date +%s)"
    needs_ghostty_migration=true
fi

ln -sfn "$REPO_DIR/ghostty" "$HOME/.config/ghostty"

if [ "$needs_ghostty_migration" = true ]; then
    echo "📝 Existing Ghostty config backed up."
fi

echo "✨ Setting up Starship config..."
if [ -e "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
    mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.backup.$(date +%s)"
fi

ln -sfn "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

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

echo "✅ Done! Restart your terminal, then open nvim once to bootstrap LazyVim."