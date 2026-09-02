#!/bin/bash
# lib/toolchains.sh — Runtime toolchains, background services, and cache initialization.

# shellcheck disable=SC2143
# SC2143: BSD grep behavior requires checking command substitution output.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_TOOLCHAINS_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_TOOLCHAINS_LOADED=1

setup_rust_toolchain() {
    if [ "$CAT_RUST" -eq 0 ]; then
        return 0
    fi
    log_step "Setting up Rust toolchain..."
    if command -v brew &>/dev/null && [ -d "$(brew --prefix rustup 2>/dev/null)/bin" ]; then
        local rustup_prefix
        rustup_prefix="$(brew --prefix rustup 2>/dev/null)"
        export PATH="$rustup_prefix/bin:$PATH"
    fi

    if command -v rustup &>/dev/null; then
        # Check if any toolchain is installed
        if [ -z "$(rustup toolchain list 2>/dev/null | grep -v 'no installed toolchains')" ]; then
            log_dim "Installing stable Rust toolchain via rustup..."
            rustup default stable
        else
            log_dim "Rust toolchain already present."
        fi
    fi
}

setup_node_toolchain() {
    if [ "$CAT_WEB" -eq 0 ]; then
        return 0
    fi
    if command -v fnm &>/dev/null; then
        log_step "Setting up Node.js LTS via fnm..."
        eval "$(fnm env)"
        fnm install --lts
        fnm default lts-latest
    fi
}

setup_background_services() {
    if [ "$CAT_AI" -eq 1 ] && command -v ollama &>/dev/null; then
        log_step "Starting Ollama background service..."
        brew services start ollama 2>/dev/null || true
    fi

    if [ "$CAT_WINDOW_MANAGEMENT" -eq 1 ] && command -v borders &>/dev/null; then
        log_step "Starting JankyBorders window highlighter service..."
        brew services start borders 2>/dev/null || true
    fi
}

setup_caches_and_checks() {
    if command -v tldr &>/dev/null; then
        log_dim "Priming tealdeer / tldr cache..."
        tldr --update &>/dev/null || true
    fi

    if ! command -v docker &>/dev/null; then
        if [ -d "/Applications/OrbStack.app" ]; then
            log_info "OrbStack is installed. To enable docker CLI, link it via:"
            log_dim "ln -sfn /Applications/OrbStack.app/Contents/MacOS/xbin/docker /opt/homebrew/bin/docker"
        fi
    fi
}
