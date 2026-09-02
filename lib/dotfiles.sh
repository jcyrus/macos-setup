#!/bin/bash
# lib/dotfiles.sh — Dotfile deployment, template rendering, and shell configuration.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_DOTFILES_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_DOTFILES_LOADED=1

setup_shell_config() {
    log_step "Configuring Zsh shell environment..."

    # Install Oh My Zsh if missing
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.backup" ]; then
        log_info "Backing up existing .zshrc to .zshrc.backup..."
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    fi
    touch "$HOME/.zshrc"

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
        log_dim "Cloning zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
        log_dim "Cloning zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
    fi

    # Ensure Homebrew is in path (idempotent)
    if ! grep -q "shellenv" "$HOME/.zshrc"; then
        # shellcheck disable=SC2016
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zshrc"
    fi

    # Oh My Zsh Setup
    local omz_plugins="plugins=(git brew zsh-autosuggestions zsh-syntax-highlighting)"
    if ! grep -q "oh-my-zsh.sh" "$HOME/.zshrc"; then
        cat <<EOT >>"$HOME/.zshrc"

# --- Oh My Zsh (MacOS Setup) ---
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""
$omz_plugins
source \$ZSH/oh-my-zsh.sh
EOT
    elif ! grep -qF "$omz_plugins" "$HOME/.zshrc"; then
        log_warn "Your .zshrc already sets Oh My Zsh plugins. Leaving it untouched."
        log_dim "Ensure it includes: git brew zsh-autosuggestions zsh-syntax-highlighting"
    fi

    # Tools & Aliases
    if ! grep -q "# --- MacOS Setup Tools ---" "$HOME/.zshrc"; then
        cat <<'EOT' >>"$HOME/.zshrc"

# --- MacOS Setup Tools ---
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fnm env --use-on-cd)"
eval "$(fzf --zsh)"

alias ls="eza --icons=auto"
alias ll="eza -l --icons=auto"
alias cat="bat --paging=never --plain"
alias f="fvm flutter"
alias lg="lazygit"
alias help="tldr"

# Rustup / Cargo shims
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
EOT
    fi
}

setup_git_defaults() {
    log_step "Configuring Git defaults..."

    if [ -n "$CONFIG_GIT_NAME" ]; then
        git config --global user.name "$CONFIG_GIT_NAME"
    fi
    if [ -n "$CONFIG_GIT_EMAIL" ]; then
        git config --global user.email "$CONFIG_GIT_EMAIL"
    fi

    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.dark true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side "$CONFIG_GIT_DELTA_SIDE_BY_SIDE"
    git config --global merge.conflictstyle zdiff3

    # Install git hooks (lefthook) if inside git clone
    if command -v lefthook &>/dev/null && [ -d "$REPO_DIR/.git" ]; then
        log_dim "Installing repository git hooks (lefthook)..."
        (cd "$REPO_DIR" && lefthook install >/dev/null) || true
    fi
}

setup_neovim_config() {
    if [ "$CAT_EDITORS" -eq 0 ]; then
        return 0
    fi
    log_step "Setting up Neovim (LazyVim)..."
    mkdir -p "$HOME/.config"

    local needs_migration=false
    if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
        needs_migration=true
    fi

    ln -sfn "$REPO_DIR/nvim" "$HOME/.config/nvim"

    if [ "$needs_migration" = true ]; then
        for nvim_state in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
            if [ -d "$nvim_state" ]; then
                mv "$nvim_state" "$nvim_state.backup.$(date +%s)"
            fi
        done
    fi
}

setup_tmux_config() {
    if [ "$CAT_TERMINAL" -eq 0 ]; then
        return 0
    fi
    log_step "Setting up tmux & Catppuccin theme..."
    ln -sfn "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    mkdir -p "$HOME/.tmux/plugins"

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    local cat_repo="https://github.com/catppuccin/tmux.git"
    local cat_version="v2.1.3"
    local cat_dir="$HOME/.tmux/plugins/tmux"

    if [ -d "$cat_dir/.git" ]; then
        git -C "$cat_dir" fetch --tags --quiet 2>/dev/null || true
        git -C "$cat_dir" checkout --quiet -f "$cat_version" 2>/dev/null || true
    elif [ ! -e "$cat_dir" ]; then
        git clone -b "$cat_version" "$cat_repo" "$cat_dir" 2>/dev/null || true
    fi
}

setup_ghostty_config() {
    if [ "$CAT_TERMINAL" -eq 0 ]; then
        return 0
    fi
    log_step "Configuring Ghostty..."
    mkdir -p "$HOME/.config/ghostty"

    if [ -e "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
        cp "$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.backup.$(date +%s)"
    fi

    render_template "$REPO_DIR/templates/ghostty.config.tmpl" "$HOME/.config/ghostty/config"
}

setup_starship_config() {
    if [ "$CAT_TERMINAL" -eq 0 ]; then
        return 0
    fi
    log_step "Configuring Starship prompt..."
    mkdir -p "$HOME/.config"

    if [ -e "$HOME/.config/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
        cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.backup.$(date +%s)"
    fi

    render_template "$REPO_DIR/templates/starship.toml.tmpl" "$HOME/.config/starship.toml"
}

setup_aerospace_config() {
    if [ "$CAT_WINDOW_MANAGEMENT" -eq 0 ] || [ "$CONFIG_AEROSPACE_ENABLED" = false ]; then
        return 0
    fi
    log_step "Configuring AeroSpace tiling window manager..."
    mkdir -p "$HOME/.config/aerospace"

    if [ -e "$HOME/.config/aerospace/aerospace.toml" ]; then
        cp "$HOME/.config/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml.backup.$(date +%s)"
    fi

    if [ -L "$HOME/.aerospace.toml" ]; then
        rm -f "$HOME/.aerospace.toml"
    elif [ -f "$HOME/.aerospace.toml" ]; then
        mv "$HOME/.aerospace.toml" "$HOME/.aerospace.toml.backup.$(date +%s)"
    fi

    render_template "$REPO_DIR/templates/aerospace.toml.tmpl" "$HOME/.config/aerospace/aerospace.toml"
}

setup_vscode_config() {
    if [ "$CAT_EDITORS" -eq 0 ]; then
        return 0
    fi
    local vscode_dir="$HOME/Library/Application Support/Code/User"
    if [ -d "$vscode_dir" ] || [ -d "/Applications/Visual Studio Code.app" ]; then
        log_step "Configuring VS Code settings & extensions..."
        mkdir -p "$vscode_dir"
        render_template "$REPO_DIR/templates/vscode.settings.json.tmpl" "$vscode_dir/settings.json"

        if command -v code &>/dev/null && [ -f "$REPO_DIR/vscode/extensions.json" ]; then
            log_dim "Installing recommended VS Code extensions..."
            local extensions
            extensions="$(sed -n 's/.*"\([a-zA-Z0-9._-]*\.[a-zA-Z0-9._-]*\)".*/\1/p' "$REPO_DIR/vscode/extensions.json")"
            for ext in $extensions; do
                code --install-extension "$ext" --force &>/dev/null || true
            done
        fi
    fi
}
