#!/bin/bash
# lib/config.sh — Configuration manager, preset loader, and template compiler.

# shellcheck disable=SC2034
# Global configuration variables are referenced across modules.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_CONFIG_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_CONFIG_LOADED=1

CONFIG_DIR="${HOME}/.config/macos-setup"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

# Initialize global configuration variables with defaults
init_default_config() {
    CONFIG_PRESET="full"
    CONFIG_PRESET_NAME="Complete Experience"
    CONFIG_PRESET_DESC="Full stack developer environment with AeroSpace, Ghostty, Neovim, Rust, Web, Flutter, and curated GUI tools."

    # Git
    CONFIG_GIT_NAME="$(git config --global user.name 2>/dev/null || echo "")"
    CONFIG_GIT_EMAIL="$(git config --global user.email 2>/dev/null || echo "")"
    CONFIG_GIT_DELTA_SIDE_BY_SIDE=true

    # Theme & Aesthetics
    CONFIG_THEME_PALETTE="catppuccin_mocha"
    CONFIG_THEME_FONT="0xProto Nerd Font Mono"
    CONFIG_THEME_FONT_SIZE=12

    # Ghostty
    CONFIG_GHOSTTY_THEME="Catppuccin Mocha"
    CONFIG_GHOSTTY_CURSOR_COLOR="#cba6f7"
    CONFIG_GHOSTTY_OPACITY="0.88"
    CONFIG_GHOSTTY_BLUR="20"
    CONFIG_GHOSTTY_TITLEBAR="hidden"

    # Window Management (AeroSpace + Borders)
    CONFIG_AEROSPACE_ENABLED=true
    CONFIG_AEROSPACE_MODIFIER="alt"
    CONFIG_AEROSPACE_GAPS=8
    CONFIG_BORDERS_COLOR="0xffcba6f7"
    CONFIG_BORDERS_WIDTH="4.0"
    CONFIG_BORDERS_RADIUS="10.0"

    # macOS System Defaults
    CONFIG_MACOS_DEFAULTS_ENABLED=true
    CONFIG_MACOS_DOCK_AUTOHIDE=true
    CONFIG_MACOS_DOCK_FAST=true
    CONFIG_MACOS_SCREENSHOTS_DIR="$HOME/Screenshots"
    CONFIG_MACOS_FAST_KEY_REPEAT=true

    # Browsers (space-delimited cask tokens; Zen is the opinionated main browser).
    # This only decides what gets installed — the macOS default browser is left
    # alone, since choosing it is the user's call (or their link router's).
    CONFIG_BROWSERS="zen"

    # Categories (1 = enabled, 0 = disabled)
    CAT_WINDOW_MANAGEMENT=1
    CAT_TERMINAL=1
    CAT_CORE_CLI=1
    CAT_MODERN_CLI=1
    CAT_SHELL_QUALITY=1
    CAT_AI=1
    CAT_EDITORS=1
    CAT_GIT_TUIS=1
    CAT_RUST=1
    CAT_WEB=1
    CAT_MOBILE=1
    CAT_BROWSERS=1
    CAT_GUI_CORE=1
    CAT_FONTS=1
    CAT_SECURITY=1
    CAT_CREATIVE=1
    CAT_CUSTOM_TAP=1

    # Specific package exclusions (space-delimited lists)
    SKIPPED_FORMULAE=""
    SKIPPED_CASKS=""
}

# Helper to read a value from a simple TOML / key-value string
_get_toml_val() {
    local file="$1" key="$2"
    # Matches `key = "value"` or `key = value`
    grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" 2>/dev/null |
        head -n 1 |
        sed -E "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//; s/[\"']//g; s/[[:space:]]*#.*$//" |
        tr -d '\r'
}

# Load a preset profile from a TOML file
load_preset() {
    local preset_file="$1"
    if [ ! -f "$preset_file" ]; then
        log_error "Preset file not found: $preset_file"
        return 1
    fi

    local p_name p_desc
    p_name="$(_get_toml_val "$preset_file" "name")"
    p_desc="$(_get_toml_val "$preset_file" "description")"
    [ -n "$p_name" ] && CONFIG_PRESET_NAME="$p_name"
    [ -n "$p_desc" ] && CONFIG_PRESET_DESC="$p_desc"

    # Git
    local val
    val="$(_get_toml_val "$preset_file" "delta_side_by_side")"
    [ -n "$val" ] && CONFIG_GIT_DELTA_SIDE_BY_SIDE="$val"

    # Theme
    val="$(_get_toml_val "$preset_file" "palette")"
    [ -n "$val" ] && CONFIG_THEME_PALETTE="$val"
    val="$(_get_toml_val "$preset_file" "font")"
    [ -n "$val" ] && CONFIG_THEME_FONT="$val"
    val="$(_get_toml_val "$preset_file" "ghostty_opacity")"
    [ -n "$val" ] && CONFIG_GHOSTTY_OPACITY="$val"
    val="$(_get_toml_val "$preset_file" "ghostty_blur")"
    [ -n "$val" ] && CONFIG_GHOSTTY_BLUR="$val"
    val="$(_get_toml_val "$preset_file" "ghostty_titlebar")"
    [ -n "$val" ] && CONFIG_GHOSTTY_TITLEBAR="$val"

    # Window Manager
    val="$(_get_toml_val "$preset_file" "enabled")"
    [ -n "$val" ] && CONFIG_AEROSPACE_ENABLED="$val"
    val="$(_get_toml_val "$preset_file" "modifier")"
    [ -n "$val" ] && CONFIG_AEROSPACE_MODIFIER="$val"
    val="$(_get_toml_val "$preset_file" "gaps")"
    [ -n "$val" ] && CONFIG_AEROSPACE_GAPS="$val"
    val="$(_get_toml_val "$preset_file" "border_color")"
    [ -n "$val" ] && CONFIG_BORDERS_COLOR="$val"
    val="$(_get_toml_val "$preset_file" "border_width")"
    [ -n "$val" ] && CONFIG_BORDERS_WIDTH="$val"
    val="$(_get_toml_val "$preset_file" "border_radius")"
    [ -n "$val" ] && CONFIG_BORDERS_RADIUS="$val"

    # Browsers — `install` lives under [config.browsers] and holds cask tokens.
    # An explicitly empty list is honoured; a missing key keeps the default.
    if grep -qE '^[[:space:]]*install[[:space:]]*=' "$preset_file"; then
        CONFIG_BROWSERS="$(grep -E '^[[:space:]]*install[[:space:]]*=' "$preset_file" |
            head -n 1 |
            sed -E 's/^[[:space:]]*install[[:space:]]*=[[:space:]]*\[//; s/\]//; s/"//g; s/,/ /g' |
            xargs)"
    fi

    # Categories
    for cat in window_management terminal core_cli modern_cli shell_quality ai editors git_tuis rust web mobile browsers gui_core fonts security creative custom_tap; do
        val="$(_get_toml_val "$preset_file" "$cat")"
        cat_upper="$(echo "$cat" | tr '[:lower:]' '[:upper:]')"
        if [ "$val" = "true" ]; then
            eval "CAT_${cat_upper}=1"
        elif [ "$val" = "false" ]; then
            eval "CAT_${cat_upper}=0"
        fi
    done

    # Sync window manager category with aerospace_enabled
    if [ "$CAT_WINDOW_MANAGEMENT" -eq 0 ]; then
        CONFIG_AEROSPACE_ENABLED=false
    fi

    # Skipped items
    local skip_casks skip_formulae
    skip_casks="$(grep -E '^[[:space:]]*casks[[:space:]]*=' "$preset_file" | sed -E 's/^[[:space:]]*casks[[:space:]]*=[[:space:]]*\[//; s/\]//; s/"//g; s/,/ /g')"
    skip_formulae="$(grep -E '^[[:space:]]*formulae[[:space:]]*=' "$preset_file" | sed -E 's/^[[:space:]]*formulae[[:space:]]*=[[:space:]]*\[//; s/\]//; s/"//g; s/,/ /g')"
    SKIPPED_CASKS="$skip_casks"
    SKIPPED_FORMULAE="$skip_formulae"

    return 0
}

# Save current active configuration to ~/.config/macos-setup/config.toml
save_config() {
    local target="${1:-$CONFIG_FILE}"
    local target_dir
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    cat <<EOF >"$target"
# ==============================================================================
# macos-setup Active Machine Configuration
# Generated on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# ==============================================================================

version = "2.0.0"
preset = "${CONFIG_PRESET}"
preset_name = "${CONFIG_PRESET_NAME}"

[config.git]
name = "${CONFIG_GIT_NAME}"
email = "${CONFIG_GIT_EMAIL}"
delta_side_by_side = ${CONFIG_GIT_DELTA_SIDE_BY_SIDE}

[config.theme]
palette = "${CONFIG_THEME_PALETTE}"
font = "${CONFIG_THEME_FONT}"
font_size = ${CONFIG_THEME_FONT_SIZE}
ghostty_theme = "${CONFIG_GHOSTTY_THEME}"
ghostty_cursor_color = "${CONFIG_GHOSTTY_CURSOR_COLOR}"
ghostty_opacity = "${CONFIG_GHOSTTY_OPACITY}"
ghostty_blur = "${CONFIG_GHOSTTY_BLUR}"
ghostty_titlebar = "${CONFIG_GHOSTTY_TITLEBAR}"

[config.window_manager]
enabled = ${CONFIG_AEROSPACE_ENABLED}
modifier = "${CONFIG_AEROSPACE_MODIFIER}"
gaps = ${CONFIG_AEROSPACE_GAPS}
border_color = "${CONFIG_BORDERS_COLOR}"
border_width = "${CONFIG_BORDERS_WIDTH}"
border_radius = "${CONFIG_BORDERS_RADIUS}"

[config.macos_defaults]
enabled = ${CONFIG_MACOS_DEFAULTS_ENABLED}
dock_autohide = ${CONFIG_MACOS_DOCK_AUTOHIDE}
dock_fast = ${CONFIG_MACOS_DOCK_FAST}
screenshots_dir = "${CONFIG_MACOS_SCREENSHOTS_DIR}"
fast_keyboard_repeat = ${CONFIG_MACOS_FAST_KEY_REPEAT}

[config.browsers]
install = [$(for b in $CONFIG_BROWSERS; do printf '"%s", ' "$b"; done | sed 's/, $//')]

[categories]
window_management = $([ "$CAT_WINDOW_MANAGEMENT" -eq 1 ] && echo "true" || echo "false")
terminal = $([ "$CAT_TERMINAL" -eq 1 ] && echo "true" || echo "false")
core_cli = $([ "$CAT_CORE_CLI" -eq 1 ] && echo "true" || echo "false")
modern_cli = $([ "$CAT_MODERN_CLI" -eq 1 ] && echo "true" || echo "false")
shell_quality = $([ "$CAT_SHELL_QUALITY" -eq 1 ] && echo "true" || echo "false")
ai = $([ "$CAT_AI" -eq 1 ] && echo "true" || echo "false")
editors = $([ "$CAT_EDITORS" -eq 1 ] && echo "true" || echo "false")
git_tuis = $([ "$CAT_GIT_TUIS" -eq 1 ] && echo "true" || echo "false")
rust = $([ "$CAT_RUST" -eq 1 ] && echo "true" || echo "false")
web = $([ "$CAT_WEB" -eq 1 ] && echo "true" || echo "false")
mobile = $([ "$CAT_MOBILE" -eq 1 ] && echo "true" || echo "false")
browsers = $([ "$CAT_BROWSERS" -eq 1 ] && echo "true" || echo "false")
gui_core = $([ "$CAT_GUI_CORE" -eq 1 ] && echo "true" || echo "false")
fonts = $([ "$CAT_FONTS" -eq 1 ] && echo "true" || echo "false")
security = $([ "$CAT_SECURITY" -eq 1 ] && echo "true" || echo "false")
creative = $([ "$CAT_CREATIVE" -eq 1 ] && echo "true" || echo "false")
custom_tap = $([ "$CAT_CUSTOM_TAP" -eq 1 ] && echo "true" || echo "false")

[packages.skip]
formulae = [$(for f in $SKIPPED_FORMULAE; do printf '"%s", ' "$f"; done | sed 's/, $//')]
casks = [$(for c in $SKIPPED_CASKS; do printf '"%s", ' "$c"; done | sed 's/, $//')]
EOF
}

# Compile / Render a template file by substituting placeholders
render_template() {
    local tmpl="$1" out="$2"
    if [ ! -f "$tmpl" ]; then
        log_error "Template file not found: $tmpl"
        return 1
    fi

    mkdir -p "$(dirname "$out")"

    # Older versions of this installer symlinked these paths back into the repo.
    # Redirecting onto a symlink writes through to its target, which silently
    # overwrites the repo's checked-in configs with rendered output. Drop the
    # link first so we always render a real file at $out.
    if [ -L "$out" ]; then
        log_warn "Replacing legacy symlink with a rendered file: $out"
        rm -f "$out"
    fi

    # Derive VS Code theme name based on palette
    local vscode_theme="Catppuccin Mocha"
    case "$CONFIG_THEME_PALETTE" in
        catppuccin_latte) vscode_theme="Catppuccin Latte" ;;
        catppuccin_frappe) vscode_theme="Catppuccin Frappe" ;;
        catppuccin_macchiato) vscode_theme="Catppuccin Macchiato" ;;
        *) vscode_theme="Catppuccin Mocha" ;;
    esac

    sed \
        -e "s|__GHOSTTY_FONT__|${CONFIG_THEME_FONT}|g" \
        -e "s|__GHOSTTY_FONT_SIZE__|${CONFIG_THEME_FONT_SIZE}|g" \
        -e "s|__GHOSTTY_THEME__|${CONFIG_GHOSTTY_THEME}|g" \
        -e "s|__GHOSTTY_CURSOR_COLOR__|${CONFIG_GHOSTTY_CURSOR_COLOR}|g" \
        -e "s|__GHOSTTY_OPACITY__|${CONFIG_GHOSTTY_OPACITY}|g" \
        -e "s|__GHOSTTY_BLUR__|${CONFIG_GHOSTTY_BLUR}|g" \
        -e "s|__GHOSTTY_TITLEBAR__|${CONFIG_GHOSTTY_TITLEBAR}|g" \
        -e "s|__AEROSPACE_MODIFIER__|${CONFIG_AEROSPACE_MODIFIER}|g" \
        -e "s|__AEROSPACE_GAP_INNER__|${CONFIG_AEROSPACE_GAPS}|g" \
        -e "s|__AEROSPACE_GAP_OUTER__|${CONFIG_AEROSPACE_GAPS}|g" \
        -e "s|__BORDERS_ACTIVE_COLOR__|${CONFIG_BORDERS_COLOR}|g" \
        -e "s|__BORDERS_WIDTH__|${CONFIG_BORDERS_WIDTH}|g" \
        -e "s|__BORDERS_RADIUS__|${CONFIG_BORDERS_RADIUS}|g" \
        -e "s|__STARSHIP_PALETTE__|${CONFIG_THEME_PALETTE}|g" \
        -e "s|__VSCODE_FONT__|${CONFIG_THEME_FONT}|g" \
        -e "s|__VSCODE_FONT_SIZE__|${CONFIG_THEME_FONT_SIZE}|g" \
        -e "s|__VSCODE_THEME__|${vscode_theme}|g" \
        -e "s|__DELTA_SIDE_BY_SIDE__|${CONFIG_GIT_DELTA_SIDE_BY_SIDE}|g" \
        "$tmpl" >"$out"
}
