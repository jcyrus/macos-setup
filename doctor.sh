#!/bin/bash
# doctor.sh — read-only manifest-aware health check for this setup.
#
# Reports how far the current machine has drifted from what install.sh would
# produce. Makes no changes whatsoever: no installs, no writes, no symlinks.
#
# Exit status: 0 if nothing failed, 1 if any check failed.

# shellcheck disable=SC2088
# SC2088: this file passes "~/..." strings as display labels, not paths to resolve.
# shellcheck disable=SC2143
# SC2143: BSD grep behavior requires checking command substitution output.
# shellcheck disable=SC1091
# Modular libraries are located in lib/ and sourced at runtime.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source configuration & helpers
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/config.sh"

init_default_config

# Load user configuration if present
if [ -f "$CONFIG_FILE" ]; then
    load_preset "$CONFIG_FILE"
fi

if [ -t 1 ]; then
    C_OK=$'\033[32m'
    C_WARN=$'\033[33m'
    C_FAIL=$'\033[31m'
    C_HEAD=$'\033[1;36m'
    C_DIM=$'\033[2m'
    C_OFF=$'\033[0m'
else
    C_OK=""
    C_WARN=""
    C_FAIL=""
    C_HEAD=""
    C_DIM=""
    C_OFF=""
fi

PASS_N=0
WARN_N=0
FAIL_N=0

section() { printf "\n%s── %s%s\n" "$C_HEAD" "$1" "$C_OFF"; }
ok() {
    PASS_N=$((PASS_N + 1))
    printf "  %sok%s    %-26s %s\n" "$C_OK" "$C_OFF" "$1" "$2"
}
warn() {
    WARN_N=$((WARN_N + 1))
    printf "  %swarn%s  %-26s %s\n" "$C_WARN" "$C_OFF" "$1" "$2"
}
fail() {
    FAIL_N=$((FAIL_N + 1))
    printf "  %sFAIL%s  %-26s %s\n" "$C_FAIL" "$C_OFF" "$1" "$2"
}
skip() {
    PASS_N=$((PASS_N + 1))
    printf "  %sok%s    %-26s %s%s%s\n" "$C_OK" "$C_OFF" "$1" "$C_DIM" "$2" "$C_OFF"
}
hint() { printf "        %s%s%s\n" "$C_DIM" "$1" "$C_OFF"; }

check_link_or_file() {
    local label="$1" target="$2" expected="$3"
    if [ -L "$target" ]; then
        local dest
        dest="$(readlink "$target")"
        if [ ! -e "$target" ]; then
            fail "$label" "dangling symlink -> $dest"
            hint "the tool is running with no config; re-run install.sh"
        elif [ "$dest" = "$expected" ]; then
            ok "$label" "-> $dest"
        else
            ok "$label" "-> $dest"
        fi
    elif [ -f "$target" ]; then
        ok "$label" "present (customized config)"
    elif [ -d "$target" ]; then
        ok "$label" "present"
    else
        fail "$label" "missing"
    fi
}

printf "%s🩺 macos-setup doctor%s  %s(read-only)%s\n" "$C_HEAD" "$C_OFF" "$C_DIM" "$C_OFF"
printf "%srepo: %s%s\n" "$C_DIM" "$REPO_DIR" "$C_OFF"
if [ -f "$CONFIG_FILE" ]; then
    printf "%sactive profile: %s (%s)%s\n" "$C_DIM" "$CONFIG_PRESET_NAME" "$CONFIG_FILE" "$C_OFF"
fi

# --- Homebrew ---------------------------------------------------------------
section "Homebrew"
if command -v brew &>/dev/null; then
    ok "brew" "$(brew --version | head -n 1)"

    active_brewfile="$REPO_DIR/Brewfile"
    if [ -f "${CONFIG_DIR}/Brewfile.generated" ]; then
        active_brewfile="${CONFIG_DIR}/Brewfile.generated"
    fi

    missing="$(brew bundle check --verbose --file="$active_brewfile" 2>&1 |
        sed -n 's/^→ \(.*\) needs to be installed or updated\./\1/p')"
    if [ -z "$missing" ]; then
        ok "Brewfile" "all active entries satisfied"
    else
        n="$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
        warn "Brewfile" "$n entr(y/ies) missing from active manifest"
        printf '%s\n' "$missing" | while read -r m; do hint "$m"; done
    fi
else
    fail "brew" "not installed"
fi

# --- Config files -----------------------------------------------------------
section "Configurations"
if [ "$CAT_EDITORS" -eq 1 ]; then
    check_link_or_file "~/.config/nvim" "$HOME/.config/nvim" "$REPO_DIR/nvim"
else
    skip "~/.config/nvim" "(editors category disabled)"
fi

if [ "$CAT_TERMINAL" -eq 1 ]; then
    check_link_or_file "~/.config/ghostty" "$HOME/.config/ghostty/config" "$REPO_DIR/ghostty/config"
    check_link_or_file "~/.config/starship.toml" "$HOME/.config/starship.toml" "$REPO_DIR/starship/starship.toml"
    check_link_or_file "~/.tmux.conf" "$HOME/.tmux.conf" "$REPO_DIR/tmux/.tmux.conf"
else
    skip "~/.config/ghostty" "(terminal category disabled)"
    skip "~/.config/starship.toml" "(terminal category disabled)"
    skip "~/.tmux.conf" "(terminal category disabled)"
fi

if [ "$CAT_WINDOW_MANAGEMENT" -eq 1 ] && [ "$CONFIG_AEROSPACE_ENABLED" = true ]; then
    check_link_or_file "~/.config/aerospace" "$HOME/.config/aerospace/aerospace.toml" "$REPO_DIR/aerospace/aerospace.toml"
else
    skip "~/.config/aerospace" "(window management disabled)"
fi

# --- Shell ------------------------------------------------------------------
section "Shell"
if [ -d "$HOME/.oh-my-zsh" ]; then ok "oh-my-zsh" "present"; else fail "oh-my-zsh" "missing"; fi
for p in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$p" ]; then
        ok "$p" "present"
    else
        fail "$p" "missing"
    fi
done

if [ -f "$HOME/.zshrc" ]; then
    for init in "starship init" "zoxide init" "fnm env"; do
        if [ "$init" = "fnm env" ] && [ "$CAT_WEB" -eq 0 ]; then
            continue
        fi
        if grep -q "$init" "$HOME/.zshrc"; then
            ok "${init% *} init" "wired up"
        else
            fail "${init% *} init" "absent from .zshrc"
        fi
    done
else
    fail "~/.zshrc" "missing"
fi

# --- tmux -------------------------------------------------------------------
if [ "$CAT_TERMINAL" -eq 1 ]; then
    section "tmux"
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then ok "tpm" "present"; else fail "tpm" "missing"; fi
    if [ -d "$HOME/.tmux/plugins/tmux" ]; then ok "catppuccin/tmux" "present"; else fail "catppuccin/tmux" "missing"; fi
fi

# --- Toolchains -------------------------------------------------------------
section "Toolchains"
if [ "$CAT_WEB" -eq 1 ]; then
    if command -v node &>/dev/null; then
        ok "node" "$(node --version)"
    else
        fail "node" "not on PATH"
        hint "'fnm install --lts' installs but does not activate; 'fnm default lts-latest' does"
    fi
else
    skip "node" "(web category disabled)"
fi

if [ "$CAT_RUST" -eq 1 ]; then
    if command -v rustc &>/dev/null; then
        ok "rust" "$(rustc --version | awk '{print $2}')"
    elif command -v rustup &>/dev/null; then
        if [ -n "$(rustup toolchain list 2>/dev/null | grep -v 'no installed toolchains')" ]; then
            fail "rust" "toolchain installed but rustc is not on PATH"
        else
            fail "rust" "rustup present but no toolchain installed"
        fi
    else
        fail "rust" "not installed"
    fi
else
    skip "rust" "(rust category disabled)"
fi

if [ "$CAT_MOBILE" -eq 1 ]; then
    if command -v fvm &>/dev/null; then
        if fvm list 2>/dev/null | grep -q "No SDKs have been installed"; then
            warn "flutter (fvm)" "fvm present, no SDK installed"
            hint "run: fvm install stable && fvm global stable"
        else
            ok "flutter (fvm)" "SDK installed"
        fi
    else
        fail "fvm" "not installed"
    fi
else
    skip "flutter (fvm)" "(mobile category disabled)"
fi

# --- Git --------------------------------------------------------------------
section "Git"
if [ "$(git config --global core.pager)" = "delta" ]; then
    ok "delta pager" "configured"
else
    fail "delta pager" "core.pager is not delta"
fi

# --- Neovim -----------------------------------------------------------------
if [ "$CAT_EDITORS" -eq 1 ]; then
    section "Neovim"
    if [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ]; then
        ok "LazyVim" "bootstrapped"
    else
        warn "LazyVim" "not yet bootstrapped (open nvim once to initialize)"
    fi
fi

# --- VS Code ----------------------------------------------------------------
if [ "$CAT_EDITORS" -eq 1 ]; then
    section "VS Code"
    vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    if [ -f "$vscode_settings" ]; then
        ok "settings.json" "configured"
    else
        warn "settings.json" "missing"
    fi
fi

# --- Starship ---------------------------------------------------------------
if [ "$CAT_TERMINAL" -eq 1 ]; then
    section "Starship"
    if command -v starship &>/dev/null; then
        ok "starship" "$(starship --version | head -n 1)"
    else
        fail "starship" "not installed"
    fi
fi

# --- Ollama -----------------------------------------------------------------
if [ "$CAT_AI" -eq 1 ]; then
    section "Ollama"
    if command -v ollama &>/dev/null; then
        ok "ollama CLI" "$(ollama --version 2>/dev/null | head -n 1)"
        if curl -s http://localhost:11434/api/tags &>/dev/null; then
            ok "ollama service" "running on localhost:11434"
        else
            warn "ollama service" "not running"
        fi
    else
        warn "ollama" "not installed"
    fi
fi

# --- Window Management ------------------------------------------------------
if [ "$CAT_WINDOW_MANAGEMENT" -eq 1 ] && [ "$CONFIG_AEROSPACE_ENABLED" = true ]; then
    section "Window Management"
    if [ -d "/Applications/AeroSpace.app" ] || command -v aerospace &>/dev/null; then
        ok "AeroSpace" "installed"
    else
        fail "AeroSpace" "not installed"
    fi

    if command -v borders &>/dev/null; then
        ok "borders" "installed"
    else
        fail "borders" "not installed"
    fi
fi

# --- Browsers ---------------------------------------------------------------
if [ "$CAT_BROWSERS" -eq 1 ] && [ -n "${CONFIG_BROWSERS:-}" ]; then
    section "Browsers"
    for browser in $CONFIG_BROWSERS; do
        case "$browser" in
            zen) app="/Applications/Zen.app" ;;
            brave-browser) app="/Applications/Brave Browser.app" ;;
            google-chrome) app="/Applications/Google Chrome.app" ;;
            firefox) app="/Applications/Firefox.app" ;;
            arc) app="/Applications/Arc.app" ;;
            vivaldi) app="/Applications/Vivaldi.app" ;;
            microsoft-edge) app="/Applications/Microsoft Edge.app" ;;
            orion) app="/Applications/Orion.app" ;;
            librewolf) app="/Applications/LibreWolf.app" ;;
            floorp) app="/Applications/Floorp.app" ;;
            *) app="" ;;
        esac

        if [ -z "$app" ]; then
            warn "$browser" "unknown cask, cannot verify"
        elif [ -d "$app" ]; then
            ok "$browser" "installed"
        else
            fail "$browser" "not installed"
            hint "brew install --cask $browser"
        fi
    done
fi

# --- Summary ----------------------------------------------------------------
printf "\n%s── Summary%s\n" "$C_HEAD" "$C_OFF"
printf "  %s%d ok%s   %s%d warn%s   %s%d fail%s\n\n" \
    "$C_OK" "$PASS_N" "$C_OFF" "$C_WARN" "$WARN_N" "$C_OFF" "$C_FAIL" "$FAIL_N" "$C_OFF"

[ "$FAIL_N" -eq 0 ]
