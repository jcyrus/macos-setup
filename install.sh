#!/bin/bash
# install.sh — Modular Day 1 setup installer and interactive TUI wizard for macOS.
# shellcheck disable=SC1091

set -e # Fail immediately on unexpected critical error

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source modular libraries
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/config.sh"
source "$REPO_DIR/lib/brew.sh"
source "$REPO_DIR/lib/dotfiles.sh"
source "$REPO_DIR/lib/toolchains.sh"
source "$REPO_DIR/lib/macos.sh"
source "$REPO_DIR/lib/ui.sh"

# Global CLI flags
UNATTENDED=false
DRY_RUN=false
CHOSEN_PRESET=""
CUSTOM_CONFIG=""
CHOSEN_BROWSERS=""
BROWSERS_OVERRIDDEN=false

print_usage() {
    cat <<EOF
🍎 The Modern Mac Setup Installer

Usage:
  ./install.sh [options]

Options:
  -y, --unattended         Run non-interactively with default or specified preset.
  -p, --preset <name>      Choose a profile (full, minimalist, web, rust, mobile).
  -c, --config <file>      Use an existing configuration TOML file.
  -b, --browsers <list>    Browser casks to install, space or comma separated.
                           Defaults to "zen". Pass "none" to install no browser.
                           Choices: zen, brave-browser, google-chrome, firefox,
                           arc, vivaldi, microsoft-edge, orion, librewolf, floorp.
  -d, --dry-run            Simulate installation and generate config/Brewfile without changes.
  -h, --help               Show this help message.

Examples:
  ./install.sh                           # Interactive TUI Setup Wizard
  ./install.sh --unattended              # Fast automated full installation (AI Agent mode)
  ./install.sh -p web -y                 # Unattended Web developer setup
  ./install.sh -b "zen firefox" -y       # Unattended, install Zen and Firefox only
  ./install.sh --browsers none -y        # Unattended, keep Safari as the only browser
  ./install.sh --config ~/.config/macos-setup/config.toml
EOF
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y | --unattended | --non-interactive)
            UNATTENDED=true
            shift
            ;;
        -p | --preset)
            CHOSEN_PRESET="$2"
            shift 2
            ;;
        --preset=*)
            CHOSEN_PRESET="${1#*=}"
            shift
            ;;
        -c | --config)
            CUSTOM_CONFIG="$2"
            shift 2
            ;;
        --config=*)
            CUSTOM_CONFIG="${1#*=}"
            shift
            ;;
        -b | --browsers)
            CHOSEN_BROWSERS="$2"
            BROWSERS_OVERRIDDEN=true
            shift 2
            ;;
        --browsers=*)
            CHOSEN_BROWSERS="${1#*=}"
            BROWSERS_OVERRIDDEN=true
            shift
            ;;
        -d | --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h | --help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Apply a --browsers override on top of whatever the preset or config asked for.
# Accepts a comma or space separated list; "none" installs no browser at all.
apply_browser_override() {
    [ "$BROWSERS_OVERRIDDEN" = true ] || return 0

    local normalized
    normalized="$(echo "$CHOSEN_BROWSERS" | tr ',' ' ' | xargs)"

    if [ -z "$normalized" ] || [ "$normalized" = "none" ]; then
        CONFIG_BROWSERS=""
        CAT_BROWSERS=0
    else
        CONFIG_BROWSERS="$normalized"
        CAT_BROWSERS=1
    fi
}

# Initialize default configuration
init_default_config
check_system_environment

# If custom config file provided, load it
if [ -n "$CUSTOM_CONFIG" ]; then
    if [ -f "$CUSTOM_CONFIG" ]; then
        log_info "Loading configuration from: $CUSTOM_CONFIG"
        load_preset "$CUSTOM_CONFIG"
    else
        log_error "Config file not found: $CUSTOM_CONFIG"
        exit 1
    fi
elif [ -n "$CHOSEN_PRESET" ]; then
    preset_file="$REPO_DIR/presets/${CHOSEN_PRESET}.toml"
    if [ -f "$preset_file" ]; then
        load_preset "$preset_file"
        CONFIG_PRESET="$CHOSEN_PRESET"
    else
        log_error "Preset not found: $CHOSEN_PRESET (available: full, minimalist, web, rust, mobile)"
        exit 1
    fi
fi

apply_browser_override

# Determine whether to run Interactive TUI or Unattended
IS_TTY=false
if [ -t 0 ] && [ -t 1 ]; then
    IS_TTY=true
fi

if [ "$UNATTENDED" = false ] && [ "$IS_TTY" = true ] && [ -z "$CHOSEN_PRESET" ] && [ -z "$CUSTOM_CONFIG" ]; then
    # Launch interactive TUI flow
    select_preset_screen

    # If user selected custom profile, open category matrix and individual checklist screens
    if [ "$CONFIG_PRESET" = "custom" ]; then
        category_matrix_screen
        individual_packages_screen
    fi

    # Browser picker — every profile gets one, since browsers are personal.
    # A preset reset CONFIG_BROWSERS, so re-apply an explicit --browsers first.
    apply_browser_override
    if [ "$BROWSERS_OVERRIDDEN" = false ] && [ "$CAT_BROWSERS" -eq 1 ]; then
        browser_selection_screen
    fi

    # Machine & config customizer screen
    config_customizer_screen

    # Summary confirmation screen
    summary_confirmation_screen
fi

# ==============================================================================
# INSTALLATION PIPELINE
# ==============================================================================
GENERATED_BREWFILE="${CONFIG_DIR}/Brewfile.generated"

log_step "Initializing installation pipeline for profile: $CONFIG_PRESET_NAME"

# 1. Save active configuration profile
if [ "$DRY_RUN" = false ]; then
    save_config "$CONFIG_FILE"
    log_success "Saved machine configuration to $CONFIG_FILE"
else
    log_info "[Dry-Run] Would save config to $CONFIG_FILE"
fi

# 2. Preflight: Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    log_step "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    log_warn "Finish the Command Line Tools installer on your screen, then re-run this script."
    exit 1
fi

# 3. Dynamic Brewfile Generation
log_step "Compiling custom Brewfile from selected manifest..."
generate_brewfile "$GENERATED_BREWFILE"
log_success "Manifest generated at $GENERATED_BREWFILE"

if [ "$DRY_RUN" = true ]; then
    log_info "[Dry-Run] Manifest content:"
    cat "$GENERATED_BREWFILE"
    log_info "[Dry-Run] Simulation complete. No changes made to system."
    exit 0
fi

# 4. Bootstrap Homebrew
bootstrap_homebrew
ensure_path_environment

# 5. Install Packages
install_brew_packages "$GENERATED_BREWFILE"
ensure_path_environment

# 6. Deploy Shell & Dotfiles
setup_shell_config
setup_git_defaults
setup_neovim_config
setup_tmux_config
setup_ghostty_config
setup_starship_config
setup_aerospace_config
setup_vscode_config

# 7. Language Toolchains & Services
setup_rust_toolchain
setup_node_toolchain
setup_background_services
setup_caches_and_checks

# 8. macOS System Defaults
apply_macos_settings

log_step "✨ Installation and customization complete!"
log_info "Restart your terminal to load the new Zsh environment."
if [ "$CAT_WINDOW_MANAGEMENT" -eq 1 ] && [ "$CONFIG_AEROSPACE_ENABLED" = true ]; then
    log_info "Grant AeroSpace Accessibility permissions in macOS System Settings."
fi
if [ "$CAT_EDITORS" -eq 1 ]; then
    log_info "Open 'nvim' once to let LazyVim bootstrap plugins & language servers."
fi
if [ "$CAT_BROWSERS" -eq 1 ] && [ -n "$CONFIG_BROWSERS" ]; then
    log_info "Installed browsers: $CONFIG_BROWSERS"
    log_dim "Your macOS default browser was left as-is — change it in System Settings › Desktop & Dock."
fi
