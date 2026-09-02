#!/bin/bash
# update.sh — Config-aware updater for macos-setup packages, dotfiles, and toolchains.
# shellcheck disable=SC1091

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source config helpers
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/config.sh"
source "$REPO_DIR/lib/brew.sh"

init_default_config
if [ -f "$CONFIG_FILE" ]; then
    load_preset "$CONFIG_FILE"
fi

log_step "Starting system and packages update..."

# 1. Update Homebrew itself
log_info "Updating Homebrew metadata..."
brew update

# 2. Upgrade installed packages
log_info "Upgrading installed formulae and casks..."
brew upgrade

# 3. Dynamic or Master Brewfile bundle
active_brewfile="$REPO_DIR/Brewfile"
if [ -f "$CONFIG_FILE" ]; then
    active_brewfile="${CONFIG_DIR}/Brewfile.generated"
    generate_brewfile "$active_brewfile"
fi

log_info "Synchronizing active manifest ($active_brewfile)..."
brew bundle --file="$active_brewfile" || true

# 4. Cleanup old versions
log_info "Cleaning up old package versions..."
brew cleanup

# 5. Language toolchains
if [ "$CAT_RUST" -eq 1 ]; then
    log_info "Updating Rust toolchain..."
    ensure_path_environment
    if command -v rustup &>/dev/null; then
        rustup update
    fi
fi

if [ "$CAT_WEB" -eq 1 ] && command -v fnm &>/dev/null; then
    log_info "Refreshing Node LTS (fnm)..."
    eval "$(fnm env --use-on-cd)"
    fnm install --lts
    fnm default lts-latest
fi

# 6. Neovim plugins
if [ "$CAT_EDITORS" -eq 1 ] && command -v nvim &>/dev/null; then
    log_info "Syncing Neovim plugins (LazyVim)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

# 7. tmux plugins
if [ "$CAT_TERMINAL" -eq 1 ] && [ -x "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
    log_info "Updating tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all || true
fi

# 8. Caches
if command -v tldr &>/dev/null; then
    log_dim "Updating tealdeer / tldr cache..."
    tldr --update || true
fi

log_success "System update complete!"
