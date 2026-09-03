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
# Non-fatal for the same reason as in bootstrap_homebrew: a stale formula index
# still upgrades and bundles fine, and `set -e` on a bare call turns a network
# blip into an update that stops before touching anything.
log_info "Updating Homebrew metadata..."
if ! brew update; then
    log_warn "brew update failed. Continuing with the local formula index."
    log_dim "Usually a network problem; upgrades below may not see the newest versions."
fi

# 2. Upgrade installed packages
# One package failing to build should not skip the dotfiles and toolchain steps.
log_info "Upgrading installed formulae and casks..."
if ! brew upgrade; then
    log_warn "Some packages failed to upgrade. Continuing with the rest of the update."
    log_dim "Re-run 'brew upgrade' afterwards to see the failures on their own."
fi

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
