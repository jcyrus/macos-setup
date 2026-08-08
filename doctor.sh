#!/bin/bash
# doctor.sh — read-only health check for this setup.
#
# Reports how far the current machine has drifted from what install.sh would
# produce. Makes no changes whatsoever: no installs, no writes, no symlinks.
#
# Exit status: 0 if nothing failed, 1 if any check failed.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -t 1 ]; then
    C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_FAIL=$'\033[31m'
    C_HEAD=$'\033[1;36m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
    C_OK=""; C_WARN=""; C_FAIL=""; C_HEAD=""; C_DIM=""; C_OFF=""
fi

PASS_N=0
WARN_N=0
FAIL_N=0

section() { printf "\n%s── %s%s\n" "$C_HEAD" "$1" "$C_OFF"; }
ok()   { PASS_N=$((PASS_N + 1)); printf "  %sok%s    %-26s %s\n" "$C_OK" "$C_OFF" "$1" "$2"; }
warn() { WARN_N=$((WARN_N + 1)); printf "  %swarn%s  %-26s %s\n" "$C_WARN" "$C_OFF" "$1" "$2"; }
fail() { FAIL_N=$((FAIL_N + 1)); printf "  %sFAIL%s  %-26s %s\n" "$C_FAIL" "$C_OFF" "$1" "$2"; }
hint() { printf "        %s%s%s\n" "$C_DIM" "$1" "$C_OFF"; }

# A config is only healthy if it is a symlink AND resolves inside this repo.
# A dangling symlink is the failure mode that matters most: the tool starts
# fine and silently runs with no configuration at all.
check_link() {
    local label="$1" target="$2" expected="$3"
    if [ -L "$target" ]; then
        local dest
        dest="$(readlink "$target")"
        if [ ! -e "$target" ]; then
            fail "$label" "dangling symlink -> $dest"
            hint "the tool is running with no config; re-run install.sh from the repo root"
        elif [ "$dest" = "$expected" ]; then
            ok "$label" "-> $dest"
        else
            warn "$label" "-> $dest (expected $expected)"
        fi
    elif [ -e "$target" ]; then
        if diff -q "$expected" "$target" >/dev/null 2>&1; then
            warn "$label" "real file, content matches repo (will not track changes)"
        else
            warn "$label" "real file, differs from repo"
        fi
    else
        fail "$label" "missing"
    fi
}

printf "%s🩺 macos-setup doctor%s  %s(read-only)%s\n" "$C_HEAD" "$C_OFF" "$C_DIM" "$C_OFF"
printf "%srepo: %s%s\n" "$C_DIM" "$REPO_DIR" "$C_OFF"

# --- Homebrew ---------------------------------------------------------------
section "Homebrew"
if command -v brew &> /dev/null; then
    ok "brew" "$(brew --version | head -n 1)"
    missing="$(brew bundle check --verbose --file="$REPO_DIR/Brewfile" 2>/dev/null \
        | sed -n 's/^→ \(.*\) needs to be installed or updated\./\1/p')"
    if [ -z "$missing" ]; then
        ok "Brewfile" "all entries satisfied"
    else
        n="$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
        warn "Brewfile" "$n entr(y/ies) missing"
        printf '%s\n' "$missing" | while read -r m; do hint "$m"; done
    fi
else
    fail "brew" "not installed"
fi

# --- Config symlinks --------------------------------------------------------
section "Config symlinks"
check_link "~/.config/nvim"          "$HOME/.config/nvim"          "$REPO_DIR/nvim"
check_link "~/.config/ghostty"       "$HOME/.config/ghostty"       "$REPO_DIR/ghostty"
check_link "~/.config/starship.toml" "$HOME/.config/starship.toml" "$REPO_DIR/starship/starship.toml"
check_link "~/.tmux.conf"            "$HOME/.tmux.conf"            "$REPO_DIR/tmux/.tmux.conf"

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
        if grep -q "$init" "$HOME/.zshrc"; then
            ok "${init% *} init" "wired up"
        else
            fail "${init% *} init" "absent from .zshrc"
            [ "$init" = "fnm env" ] && hint "without this, node is unavailable in new shells"
        fi
    done

    # Oh My Zsh ships its own zoxide and fzf plugins. Loading those *and*
    # calling the initialisers directly runs each setup twice.
    plugin_line="$(grep -m1 '^plugins=(' "$HOME/.zshrc")"
    for dup in zoxide fzf; do
        case " $plugin_line " in
            *" $dup"*|*"($dup"*)
                if [ "$dup" = "zoxide" ] && grep -q "zoxide init" "$HOME/.zshrc"; then
                    warn "duplicate zoxide init" "OMZ plugin + explicit eval"
                    hint "drop 'zoxide' from plugins=(...); the eval is enough"
                elif [ "$dup" = "fzf" ] && grep -qE "fzf --zsh|key-bindings\.zsh" "$HOME/.zshrc"; then
                    warn "duplicate fzf init" "OMZ plugin + explicit sourcing"
                    hint "drop 'fzf' from plugins=(...); the eval is enough"
                fi
                ;;
        esac
    done

    case "$plugin_line" in
        *"zsh-syntax-highlighting)"*) ok "syntax-highlighting" "last in plugin list" ;;
        *zsh-syntax-highlighting*)    warn "syntax-highlighting" "not last in plugin list" ;;
    esac
else
    fail "~/.zshrc" "missing"
fi

# --- tmux -------------------------------------------------------------------
section "tmux"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then ok "tpm" "present"; else fail "tpm" "missing"; fi

pinned="$(sed -n "s/.*@plugin 'catppuccin\/tmux#\([^']*\)'.*/\1/p" "$REPO_DIR/tmux/.tmux.conf")"
cat_dir="$HOME/.tmux/plugins/tmux"
if [ -d "$cat_dir/.git" ]; then
    have="$(git -C "$cat_dir" describe --tags 2>/dev/null || git -C "$cat_dir" rev-parse --short HEAD)"
    if [ -n "$pinned" ] && [ "$have" != "$pinned" ]; then
        warn "catppuccin/tmux" "at $have, config pins $pinned"
    else
        ok "catppuccin/tmux" "$have"
    fi
else
    fail "catppuccin/tmux" "missing"
fi

# --- Toolchains -------------------------------------------------------------
section "Toolchains"
if command -v node &> /dev/null; then
    ok "node" "$(node --version)"
else
    fail "node" "not on PATH"
    hint "'fnm install --lts' installs but does not activate; 'fnm default lts-latest' does"
fi

if command -v rustc &> /dev/null; then
    ok "rust" "$(rustc --version | awk '{print $2}')"
elif command -v rustup &> /dev/null; then
    fail "rust" "rustup present but no toolchain installed"
    hint "run: rustup default stable"
else
    fail "rust" "not installed"
fi

if command -v fvm &> /dev/null; then
    if fvm list 2>/dev/null | grep -q "No SDKs have been installed"; then
        warn "flutter (fvm)" "fvm present, no SDK installed"
        hint "run: fvm install stable && fvm global stable"
    else
        ok "flutter (fvm)" "SDK installed"
    fi
else
    fail "fvm" "not installed"
fi

# --- Git --------------------------------------------------------------------
section "Git"
if [ "$(git config --global core.pager)" = "delta" ]; then
    ok "delta pager" "configured"
else
    fail "delta pager" "core.pager is not delta"
    hint "git-delta is installed but never runs until core.pager is set"
fi
if [ -n "$(git config --global interactive.diffFilter)" ]; then
    ok "delta diffFilter" "configured"
else
    fail "delta diffFilter" "unset"
fi

# --- Neovim -----------------------------------------------------------------
section "Neovim"
if [ -d "$HOME/.local/share/nvim/lazy/LazyVim" ]; then
    ok "LazyVim" "bootstrapped"
else
    fail "LazyVim" "not bootstrapped"
    hint "open nvim once (after the config symlink is valid) to install plugins"
fi

# --- VS Code ----------------------------------------------------------------
section "VS Code"
vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
if [ -f "$vscode_settings" ]; then
    if diff -q "$REPO_DIR/vscode/settings.json" "$vscode_settings" >/dev/null 2>&1; then
        ok "settings.json" "matches repo"
    else
        warn "settings.json" "differs from repo"
    fi
else
    warn "settings.json" "missing"
fi

if command -v code &> /dev/null; then
    installed="$(code --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')"
    wanted="$(sed -n 's/.*"\([a-zA-Z0-9._-]*\.[a-zA-Z0-9._-]*\)".*/\1/p' "$REPO_DIR/vscode/extensions.json")"
    missing_ext=""
    for e in $wanted; do
        printf '%s\n' "$installed" | grep -qx "$(printf '%s' "$e" | tr 'A-Z' 'a-z')" || missing_ext="$missing_ext $e"
    done
    if [ -z "$missing_ext" ]; then
        ok "extensions" "all recommended installed"
    else
        n="$(printf '%s' "$missing_ext" | wc -w | tr -d ' ')"
        warn "extensions" "$n missing"
        for e in $missing_ext; do hint "$e"; done
    fi
else
    warn "code CLI" "not on PATH (skipping extension check)"
fi

# --- Summary ----------------------------------------------------------------
printf "\n%s── Summary%s\n" "$C_HEAD" "$C_OFF"
printf "  %s%d ok%s   %s%d warn%s   %s%d fail%s\n\n" \
    "$C_OK" "$PASS_N" "$C_OFF" "$C_WARN" "$WARN_N" "$C_OFF" "$C_FAIL" "$FAIL_N" "$C_OFF"

[ "$FAIL_N" -eq 0 ]
