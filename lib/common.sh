#!/bin/bash
# lib/common.sh — Core terminal, logging, and system environment utilities.

# shellcheck disable=SC2034
# Colors and formatting constants are exported for inclusion across scripts.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_COMMON_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_COMMON_LOADED=1

# ANSI Color Palette (Catppuccin Mocha inspired)
if [ -t 1 ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_UNDERLINE=$'\033[4m'

    # Text colors
    C_RED=$'\033[38;2;243;139;168m'      # #f38ba8
    C_GREEN=$'\033[38;2;166;227;161m'    # #a6e3a1
    C_YELLOW=$'\033[38;2;249;226;175m'   # #f9e2af
    C_BLUE=$'\033[38;2;137;180;250m'     # #89b4fa
    C_MAUVE=$'\033[38;2;203;166;247m'    # #cba6f7
    C_PINK=$'\033[38;2;245;194;231m'     # #f5c2e7
    C_TEAL=$'\033[38;2;148;226;213m'     # #94e2d5
    C_PEACH=$'\033[38;2;250;179;135m'    # #fab387
    C_LAVENDER=$'\033[38;2;180;190;254m' # #b4befe
    C_WHITE=$'\033[38;2;205;214;244m'    # #cdd6f4
    C_GRAY=$'\033[38;2;108;112;134m'     # #6c7086

    # Status aliases
    C_OK="$C_GREEN"
    C_WARN="$C_YELLOW"
    C_FAIL="$C_RED"
    C_HEAD="$C_MAUVE$C_BOLD"
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_UNDERLINE=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_BLUE=""
    C_MAUVE=""
    C_PINK=""
    C_TEAL=""
    C_PEACH=""
    C_LAVENDER=""
    C_WHITE=""
    C_GRAY=""
    C_OK=""
    C_WARN=""
    C_FAIL=""
    C_HEAD=""
fi

# Cursor and screen controls
cursor_hide() { printf "\033[?25l"; }
cursor_show() { printf "\033[?25h"; }
clear_screen() { printf "\033[2J\033[H"; }
cursor_up() { printf "\033[%dA" "${1:-1}"; }
clear_to_end() { printf "\033[J"; }

# Logging functions
log_info() {
    printf "%sℹ️  %s%s\n" "$C_BLUE" "$1" "$C_RESET"
}

log_step() {
    printf "\n%s🚀 %s%s\n" "$C_HEAD" "$1" "$C_RESET"
}

log_success() {
    printf "%s✅ %s%s\n" "$C_GREEN" "$1" "$C_RESET"
}

log_warn() {
    printf "%s⚠️  %s%s\n" "$C_YELLOW" "$1" "$C_RESET"
}

log_error() {
    printf "%s❌ %s%s\n" "$C_RED" "$1" "$C_RESET"
}

log_dim() {
    printf "   %s%s%s\n" "$C_DIM" "$1" "$C_RESET"
}

# Preflight system verification
check_system_environment() {
    if [ "$(uname -s)" != "Darwin" ]; then
        log_error "This setup script is strictly designed for macOS (Darwin)."
        exit 1
    fi
}

# Ensure standard tool paths are populated in current session
ensure_path_environment() {
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    elif [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi

    if command -v brew &>/dev/null && [ -d "$(brew --prefix rustup 2>/dev/null)/bin" ]; then
        local rustup_prefix
        rustup_prefix="$(brew --prefix rustup 2>/dev/null)"
        export PATH="$rustup_prefix/bin:$PATH"
    fi

    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
}
