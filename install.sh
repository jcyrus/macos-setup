#!/bin/bash
# install.sh

set -e # Fail immediately if any command fails

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Starting Day 1 Installation..."

# 1. Xcode Command Line Tools (Homebrew and git both need these)
if ! xcode-select -p &>/dev/null; then
    echo "🧰 Installing Xcode Command Line Tools..."
    # Returns non-zero when an install is already in progress, which must not
    # abort the script under `set -e` before the guidance below is printed.
    xcode-select --install || true
    echo "⏳ Finish the Command Line Tools installer, then re-run this script."
    exit 1
fi

# 2. Install Homebrew
if ! command -v brew &>/dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "🍺 Homebrew found. Updating..."
    brew update
fi

# 3. Tap custom repositories (brew bundle would do this too, but tapping
# explicitly here surfaces any tap failure separately from bundle failures).
echo "🚰 Tapping jcyrus/tap and leoafarias/fvm..."
brew tap jcyrus/tap
brew tap leoafarias/fvm

# 4. Bundle Apps
# A single unavailable cask should not abort the rest of the setup, so this
# step is allowed to fail loudly instead of tripping `set -e`.
echo "📦 Installing apps from Brewfile..."
if ! brew bundle --file="$REPO_DIR/Brewfile"; then
    BUNDLE_FAILED=true
    echo "⚠️  Some Brewfile entries failed to install. Continuing with shell setup."
    echo "   Re-run 'brew bundle --file=$REPO_DIR/Brewfile' afterwards to retry."
fi

# 5. Configure Shell
echo "🐚 Configuring Zsh..."

# Install Oh My Zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

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
    # The single quotes are deliberate: this line must land in .zshrc verbatim
    # so brew resolves it at shell startup, not when this installer runs.
    # shellcheck disable=SC2016
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zshrc"
fi

# Oh My Zsh Setup (Only if not present)
# zoxide and fzf are deliberately NOT listed here: the tools block below
# initialises both directly, and loading the OMZ plugins too would bind their
# keys and shims twice. zsh-syntax-highlighting must stay last.
OMZ_PLUGINS="plugins=(git brew zsh-autosuggestions zsh-syntax-highlighting)"

if ! grep -q "oh-my-zsh.sh" "$HOME/.zshrc"; then
    cat <<EOT >>"$HOME/.zshrc"

# --- Oh My Zsh (MacOS Setup) ---
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""
$OMZ_PLUGINS
source \$ZSH/oh-my-zsh.sh
EOT
elif ! grep -qF "$OMZ_PLUGINS" "$HOME/.zshrc"; then
    # Never rewrite an existing plugins= line; it may hold customisations we
    # cannot safely merge. Tell the user what to add instead.
    echo "⚠️  Your .zshrc already sets Oh My Zsh plugins. Leaving it untouched."
    echo "   For this setup, make sure it includes: git brew zsh-autosuggestions zsh-syntax-highlighting"
    echo "   (keep zsh-syntax-highlighting last, and omit zoxide/fzf — they are initialised separately)"
fi

# Tools & Aliases (Use a marker to avoid dupes)
if ! grep -q "# --- MacOS Setup Tools ---" "$HOME/.zshrc"; then
    cat <<EOT >>"$HOME/.zshrc"

# --- MacOS Setup Tools ---
eval "\$(starship init zsh)"
eval "\$(zoxide init zsh)"
eval "\$(fnm env --use-on-cd)"
eval "\$(fzf --zsh)"

alias ls="eza --icons=auto"
alias ll="eza -l --icons=auto"
alias cat="bat --paging=never --plain"
alias f="fvm flutter"
alias lg="lazygit"
alias help="tldr"

# Homebrew's rustup formula links only \`rustup\` into bin; the rustc/cargo
# shims live here. \$HOME/.cargo/bin is where \`cargo install\` puts binaries.
export PATH="/opt/homebrew/opt/rustup/bin:\$PATH"
export PATH="\$HOME/.cargo/bin:\$PATH"
EOT
fi

# 6. Git defaults
echo "⚙️ Configuring Git defaults..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global merge.conflictstyle zdiff3

# Install this repo's own git hooks (shellcheck + shfmt on commit). Only
# meaningful from a git clone, so this is skipped for archive downloads.
if command -v lefthook &>/dev/null && [ -d "$REPO_DIR/.git" ]; then
    echo "🪝 Installing git hooks (lefthook)..."
    (cd "$REPO_DIR" && lefthook install >/dev/null) ||
        echo "⚠️  Could not install git hooks. Continuing."
fi

# 7. Dotfile symlinks
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
# Keep this tag in sync with the pin in tmux/.tmux.conf, otherwise `prefix + U`
# will drag the plugin off the version this config is written against.
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

# 8. Language Setup
echo "🦀 Setting up Rust..."
# Homebrew's rustup formula (formerly rustup-init) links only `rustup` into
# bin; rustc/cargo live in an unlinked shim directory that must be on PATH.
# There is no `rustup-init` binary any more, so the toolchain is installed
# with `rustup toolchain install` rather than by running an installer.
if command -v brew &>/dev/null && [ -d "$(brew --prefix rustup 2>/dev/null)/bin" ]; then
    rustup_prefix="$(brew --prefix rustup)"
    export PATH="$rustup_prefix/bin:$PATH"
fi

if ! command -v rustup &>/dev/null; then
    echo "❌ Error: rustup not found. Brew installation failed."
    exit 1
fi

# SC2143 suggests `! grep -q` here, but that is NOT equivalent on macOS: BSD
# grep exits 0 for `-qv` on empty input, so if rustup ever fails and prints
# nothing, the rewrite would report "already installed" and skip the install.
# The command-substitution form treats empty output as "no toolchain" and
# attempts the install, which is the safe direction. Verified on BSD grep.
# shellcheck disable=SC2143
if [ -z "$(rustup toolchain list 2>/dev/null | grep -v 'no installed toolchains')" ]; then
    rustup default stable
else
    echo "🦀 Rust toolchain already installed. Skipping."
fi

echo "📱 Setting up Node (LTS)..."
eval "$(fnm env)"
# `fnm install --lts` only installs; without a default alias, new shells still
# resolve to the system node (or none at all).
fnm install --lts
fnm default lts-latest

echo "🤖 Starting Ollama background service..."
if command -v ollama &>/dev/null; then
    brew services start ollama 2>/dev/null || true
fi

# 9. First-run caches
echo "📚 Priming tldr cache..."
if command -v tldr &>/dev/null; then
    # Optional and network-dependent; must not fail the whole install.
    tldr --update || echo "⚠️  Could not update the tldr cache. Continuing."
fi

if [ "${BUNDLE_FAILED:-false}" = true ]; then
    echo "⚠️  Reminder: some Brewfile entries failed earlier. See the log above."
fi

# 10. Docker / OrbStack CLI check
if ! command -v docker &>/dev/null; then
    if [ -d "/Applications/OrbStack.app" ]; then
        echo "⚠️  OrbStack is installed but 'docker' is not on PATH."
        echo "   Open OrbStack and enable CLI integration, or run:"
        echo "   ln -sfn /Applications/OrbStack.app/Contents/MacOS/xbin/docker /opt/homebrew/bin/docker"
    else
        echo "ℹ️  Docker CLI not found. Install OrbStack or Docker Desktop if needed."
    fi
fi

echo "✅ Done! Restart your terminal, then open nvim once to bootstrap LazyVim."
