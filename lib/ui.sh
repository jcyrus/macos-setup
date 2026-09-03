#!/bin/bash
# lib/ui.sh — Interactive Terminal User Interface (TUI) wizard.

# shellcheck disable=SC2034
# Global configuration variables are mutated for downstream consumption.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_UI_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_UI_LOADED=1

# Helper: Read single keypress (including arrow escape sequences)
read_key() {
    local key=""
    local rest=""
    # Disable echo and set character-at-a-time input
    stty -echo -icanon min 1 time 0 2>/dev/null || true
    key="$(dd bs=1 count=1 2>/dev/null)"

    if [ "$key" = $'\x1b' ]; then
        # Read subsequent characters with short timeout
        stty min 0 time 1 2>/dev/null || true
        rest="$(dd bs=1 count=2 2>/dev/null)"
        key="$key$rest"
    fi
    # Restore normal terminal mode
    stty echo icanon 2>/dev/null || true

    case "$key" in
        $'\x1b[A' | $'\x1bOA') echo "UP" ;;
        $'\x1b[B' | $'\x1bOB') echo "DOWN" ;;
        $'\x1b[C' | $'\x1bOC') echo "RIGHT" ;;
        $'\x1b[D' | $'\x1bOD') echo "LEFT" ;;
        $'\x1b[5~') echo "PAGEUP" ;;
        $'\x1b[6~') echo "PAGEDOWN" ;;
        $'\x1b') echo "ESC" ;;
        "" | $'\n' | $'\r') echo "ENTER" ;;
        " ") echo "SPACE" ;;
        $'\t') echo "TAB" ;;
        "a" | "A") echo "A" ;;
        "n" | "N") echo "N" ;;
        "c" | "C") echo "C" ;;
        "q" | "Q") echo "Q" ;;
        *) echo "$key" ;;
    esac
}

# Render top header banner
render_header() {
    clear_screen
    printf "%s" "$C_MAUVE"
    echo "  ╔══════════════════════════════════════════════════════════════════════╗"
    echo "  ║                   🍎 THE MODERN MAC SETUP WIZARD                     ║"
    echo "  ║              Modular Developer Stack & Config Customizer             ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════╝"
    printf "%s\n" "$C_RESET"
}

# ==============================================================================
# SCREEN 1: PRESET SELECTION
# ==============================================================================
select_preset_screen() {
    local options=(
        "Complete Experience"
        "Minimalist / CLI Focus"
        "Full-Stack Web"
        "Systems & Rust"
        "Mobile & Flutter"
        "Custom Checklist"
    )
    local descriptions=(
        "Full stack setup: Rust, Web, Flutter, AeroSpace, Neovim, and all GUI apps."
        "Lightweight terminal: Ghostty, Neovim, Tmux, Starship, Rust, and modern CLI tools."
        "Web engineering: Node.js (FNM), pnpm, VS Code, Zen, Chrome, OrbStack, TablePlus, Bruno."
        "Systems programming: Rustup, Bacon, Cargo tools, Neovim, Lazygit, and Yazi."
        "Cross-platform mobile: Flutter (FVM), Cocoapods, Scrcpy, VS Code, and OrbStack."
        "Granular package-by-package & category selection matrix."
    )
    local preset_keys=(
        "full"
        "minimalist"
        "web"
        "rust"
        "mobile"
        "custom"
    )

    local current=0
    local total=${#options[@]}
    cursor_hide
    trap 'cursor_show; stty echo icanon 2>/dev/null; exit 0' INT TERM

    while true; do
        render_header
        printf "%s📌 Step 1/5: Choose an Installation Profile%s\n\n" "$C_HEAD" "$C_RESET"

        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current" ]; then
                printf "   %s❯%s %s● %-26s%s %s← [Selected]%s\n" "$C_MAUVE" "$C_RESET" "$C_BOLD$C_WHITE" "${options[$i]}" "$C_RESET" "$C_TEAL" "$C_RESET"
            else
                printf "     %s○ %-26s%s\n" "$C_DIM" "${options[$i]}" "$C_RESET"
            fi
        done

        printf "\n%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s📋 Summary:%s %s\n" "$C_BOLD" "$C_RESET" "${descriptions[$current]}"
        printf "%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s[↑/↓] Navigate   [Enter] Confirm Profile   [q] Quit%s\n" "$C_DIM" "$C_RESET"

        local action
        action="$(read_key)"
        case "$action" in
            UP)
                current=$(((current - 1 + total) % total))
                ;;
            DOWN)
                current=$(((current + 1) % total))
                ;;
            ENTER)
                cursor_show
                local selected_key="${preset_keys[$current]}"
                if [ "$selected_key" = "custom" ]; then
                    CONFIG_PRESET="custom"
                    CONFIG_PRESET_NAME="Custom Selection"
                else
                    CONFIG_PRESET="$selected_key"
                    load_preset "$REPO_DIR/presets/${selected_key}.toml"
                fi
                return 0
                ;;
            Q | ESC)
                cursor_show
                clear_screen
                log_info "Setup cancelled by user."
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# SCREEN 2A: CATEGORY MATRIX (MULTI-SELECT)
# ==============================================================================
category_matrix_screen() {
    local cat_names=(
        "Window Management (AeroSpace, JankyBorders)"
        "Terminal & Multiplexer (Ghostty, Starship, Zoxide, Tmux)"
        "Core CLI Utilities (git, gh, eza, bat, ripgrep, fd, fzf, jq, tealdeer)"
        "Modern CLI Power Tools (delta, dust, duf, procs, btop, tokei, yazi)"
        "Shell Quality & Linters (shellcheck, shfmt, lefthook)"
        "AI & Local LLM (Ollama)"
        "Editors & IDEs (Neovim / LazyVim, VS Code)"
        "Git TUIs (Lazygit, Lazydocker)"
        "Rust Toolchain (Rustup, Bacon, Cargo Binstall)"
        "Web Toolchain (Node / FNM, pnpm)"
        "Mobile Toolchain (Flutter / FVM, Cocoapods, Scrcpy)"
        "Browsers (picked individually on the next screen)"
        "GUI Productivity Apps (Raycast, OrbStack, TablePlus, Bruno, Obsidian, etc.)"
        "Nerd Fonts (0xProto, JetBrains Mono)"
        "Security Tools (Bitwarden, Tailscale)"
        "Creative & Media (Figma, ImageMagick, Telegram, Spotify, IINA)"
        "Custom Tap Tools (ZeroDrop, Spektr)"
    )
    local cat_vars=(
        "CAT_WINDOW_MANAGEMENT"
        "CAT_TERMINAL"
        "CAT_CORE_CLI"
        "CAT_MODERN_CLI"
        "CAT_SHELL_QUALITY"
        "CAT_AI"
        "CAT_EDITORS"
        "CAT_GIT_TUIS"
        "CAT_RUST"
        "CAT_WEB"
        "CAT_MOBILE"
        "CAT_BROWSERS"
        "CAT_GUI_CORE"
        "CAT_FONTS"
        "CAT_SECURITY"
        "CAT_CREATIVE"
        "CAT_CUSTOM_TAP"
    )

    local current=0
    local total=${#cat_names[@]}
    cursor_hide

    while true; do
        render_header
        printf "%s📦 Step 2/5: Customize Package Categories%s\n\n" "$C_HEAD" "$C_RESET"

        for i in "${!cat_names[@]}"; do
            local var_name="${cat_vars[$i]}"
            local val="${!var_name}"
            local check=" "
            local color="$C_DIM"

            if [ "$val" -eq 1 ]; then
                check="✓"
                color="$C_GREEN"
            fi

            if [ "$i" -eq "$current" ]; then
                printf " %s❯%s [%s%s%s] %s%s%s\n" "$C_MAUVE" "$C_RESET" "$color" "$check" "$C_RESET" "$C_BOLD$C_WHITE" "${cat_names[$i]}" "$C_RESET"
            else
                printf "   [%s%s%s] %s%s%s\n" "$color" "$check" "$C_RESET" "$C_DIM" "${cat_names[$i]}" "$C_RESET"
            fi
        done

        printf "\n%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s[↑/↓] Move   [Space] Toggle   [a] Select All   [n] Select None   [Enter] Individual Apps%s\n" "$C_DIM" "$C_RESET"

        local action
        action="$(read_key)"
        case "$action" in
            UP)
                current=$(((current - 1 + total) % total))
                ;;
            DOWN)
                current=$(((current + 1) % total))
                ;;
            SPACE)
                local var_name="${cat_vars[$current]}"
                if [ "${!var_name}" -eq 1 ]; then
                    eval "$var_name=0"
                else
                    eval "$var_name=1"
                fi
                ;;
            A)
                for var_name in "${cat_vars[@]}"; do eval "$var_name=1"; done
                ;;
            N)
                for var_name in "${cat_vars[@]}"; do eval "$var_name=0"; done
                ;;
            ENTER)
                cursor_show
                return 0
                ;;
            Q | ESC)
                cursor_show
                clear_screen
                log_info "Setup cancelled by user."
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# SCREEN 2B: INDIVIDUAL PACKAGES CHECKLIST (GRANULAR)
# ==============================================================================
individual_packages_screen() {
    # Format: "type|category_var|pkg_name|display_label"
    local raw_pkgs=(
        "cask|CAT_GUI_CORE|raycast|Raycast Launcher"
        "cask|CAT_GUI_CORE|orbstack|OrbStack Containers"
        "cask|CAT_GUI_CORE|tableplus|TablePlus Database GUI"
        "cask|CAT_GUI_CORE|shottr|Shottr Precision Screenshots"
        "cask|CAT_GUI_CORE|bruno|Bruno Open-Source API Client"
        "cask|CAT_GUI_CORE|obsidian|Obsidian Notes & Brain"
        "cask|CAT_GUI_CORE|appcleaner|AppCleaner Uninstaller"
        "cask|CAT_GUI_CORE|the-unarchiver|The Unarchiver Utility"
        "cask|CAT_GUI_CORE|hiddenbar|Hidden Bar Menu Icon Hider"
        "cask|CAT_GUI_CORE|stats|Stats System Monitor"
        "cask|CAT_GUI_CORE|utm|UTM Virtual Machines"
        "cask|CAT_GUI_CORE|sf-symbols|SF Symbols Apple Icons"
        "cask|CAT_SECURITY|bitwarden|Bitwarden Password Manager"
        "cask|CAT_SECURITY|tailscale-app|Tailscale Mesh VPN"
        "cask|CAT_CREATIVE|figma|Figma Interface Design"
        "brew|CAT_CREATIVE|imagemagick|ImageMagick CLI"
        "cask|CAT_CREATIVE|telegram|Telegram Messenger"
        "cask|CAT_CREATIVE|spotify|Spotify Music"
        "cask|CAT_CREATIVE|iina|IINA Media Player"
        "cask|CAT_CREATIVE|stremio|Stremio Video Streaming"
        "cask|CAT_WINDOW_MANAGEMENT|aerospace|AeroSpace Tiling Window Mgr"
        "brew|CAT_WINDOW_MANAGEMENT|borders|JankyBorders Window Highlighter"
        "cask|CAT_TERMINAL|ghostty|Ghostty GPU Terminal"
        "brew|CAT_TERMINAL|starship|Starship Prompt"
        "brew|CAT_TERMINAL|zoxide|Zoxide Fast cd"
        "brew|CAT_TERMINAL|tmux|tmux Terminal Multiplexer"
        "brew|CAT_EDITORS|neovim|Neovim (LazyVim Stack)"
        "cask|CAT_EDITORS|visual-studio-code|VS Code Editor"
        "brew|CAT_AI|ollama|Ollama Local LLM"
        "brew|CAT_RUST|rustup|Rustup Toolchain Manager"
        "brew|CAT_RUST|bacon|Bacon Rust Background Checker"
        "brew|CAT_RUST|cargo-binstall|Cargo Binstall Fast Installer"
        "brew|CAT_WEB|fnm|Fast Node Manager (FNM)"
        "brew|CAT_WEB|pnpm|pnpm Package Manager"
        "brew|CAT_MOBILE|leoafarias/fvm/fvm|Flutter Version Manager (FVM)"
        "brew|CAT_MOBILE|cocoapods|Cocoapods iOS Manager"
        "brew|CAT_MOBILE|scrcpy|Scrcpy Android Mirroring"
        "cask|CAT_FONTS|font-0xproto-nerd-font|0xProto Nerd Font"
        "cask|CAT_FONTS|font-jetbrains-mono-nerd-font|JetBrains Mono Nerd Font"
        "brew|CAT_CUSTOM_TAP|jcyrus/tap/zerodrop|ZeroDrop TUI Chat"
        "brew|CAT_CUSTOM_TAP|jcyrus/tap/spektr|Spektr Artifact Cleaner"
    )

    local current=0
    local offset=0
    local page_size=14
    local total=${#raw_pkgs[@]}
    cursor_hide

    # Helper: Check if specific package is currently enabled
    _is_pkg_active() {
        local type="$1" cat_var="$2" pkg="$3"
        if [ "${!cat_var}" -eq 0 ]; then
            return 1
        fi
        if [ "$type" = "cask" ]; then
            _is_in_list "$pkg" "$SKIPPED_CASKS" && return 1
        else
            _is_in_list "$pkg" "$SKIPPED_FORMULAE" && return 1
        fi
        return 0
    }

    # Helper: Toggle package inclusion/exclusion
    _toggle_pkg() {
        local type="$1" cat_var="$2" pkg="$3"
        # If parent category is disabled, enable category first
        if [ "${!cat_var}" -eq 0 ]; then
            eval "$cat_var=1"
        fi

        if [ "$type" = "cask" ]; then
            if _is_in_list "$pkg" "$SKIPPED_CASKS"; then
                # Remove from skip list
                SKIPPED_CASKS="$(echo "$SKIPPED_CASKS" | tr ' ' '\n' | grep -vFx "$pkg" | tr '\n' ' ')"
            else
                # Add to skip list
                SKIPPED_CASKS="$SKIPPED_CASKS $pkg"
            fi
        else
            if _is_in_list "$pkg" "$SKIPPED_FORMULAE"; then
                SKIPPED_FORMULAE="$(echo "$SKIPPED_FORMULAE" | tr ' ' '\n' | grep -vFx "$pkg" | tr '\n' ' ')"
            else
                SKIPPED_FORMULAE="$SKIPPED_FORMULAE $pkg"
            fi
        fi
    }

    while true; do
        render_header
        printf "%s📋 Step 2/5: Granular App & CLI Checklist%s\n\n" "$C_HEAD" "$C_RESET"

        # Adjust scroll offset
        if [ "$current" -lt "$offset" ]; then
            offset="$current"
        elif [ "$current" -ge "$((offset + page_size))" ]; then
            offset="$((current - page_size + 1))"
        fi

        # Top scroll indicator
        if [ "$offset" -gt 0 ]; then
            printf "   %s▲  (%d items above)...%s\n" "$C_DIM" "$offset" "$C_RESET"
        else
            printf "\n"
        fi

        local end_idx=$((offset + page_size))
        [ "$end_idx" -gt "$total" ] && end_idx="$total"

        for ((i = offset; i < end_idx; i++)); do
            IFS='|' read -r p_type p_cat p_name p_label <<<"${raw_pkgs[$i]}"
            local check=" "
            local color="$C_DIM"

            if _is_pkg_active "$p_type" "$p_cat" "$p_name"; then
                check="✓"
                color="$C_GREEN"
            fi

            if [ "$i" -eq "$current" ]; then
                printf " %s❯%s [%s%s%s] %s%-34s%s %s(%s)%s\n" "$C_MAUVE" "$C_RESET" "$color" "$check" "$C_RESET" "$C_BOLD$C_WHITE" "$p_label" "$C_RESET" "$C_TEAL" "$p_name" "$C_RESET"
            else
                printf "   [%s%s%s] %s%-34s%s %s(%s)%s\n" "$color" "$check" "$C_RESET" "$C_DIM" "$p_label" "$C_RESET" "$C_GRAY" "$p_name" "$C_RESET"
            fi
        done

        # Bottom scroll indicator
        local remaining=$((total - end_idx))
        if [ "$remaining" -gt 0 ]; then
            printf "   %s▼  (%d more items below)...%s\n" "$C_DIM" "$remaining" "$C_RESET"
        else
            printf "\n"
        fi

        printf "%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s[↑/↓] Move   [Space] Toggle App   [Enter] Continue to Config Customizer%s\n" "$C_DIM" "$C_RESET"

        local action
        action="$(read_key)"
        case "$action" in
            UP)
                current=$(((current - 1 + total) % total))
                ;;
            DOWN)
                current=$(((current + 1) % total))
                ;;
            PAGEUP)
                current=$((current - page_size))
                [ "$current" -lt 0 ] && current=0
                ;;
            PAGEDOWN)
                current=$((current + page_size))
                [ "$current" -ge "$total" ] && current=$((total - 1))
                ;;
            SPACE)
                IFS='|' read -r p_type p_cat p_name p_label <<<"${raw_pkgs[$current]}"
                _toggle_pkg "$p_type" "$p_cat" "$p_name"
                ;;
            ENTER)
                cursor_show
                return 0
                ;;
            Q | ESC)
                cursor_show
                clear_screen
                log_info "Setup cancelled by user."
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# SCREEN 2C: BROWSER PICKER
# ==============================================================================
# Shown on every interactive run, preset or not. Zen is the opinionated default,
# but browsers are personal, so nothing here is forced. This only decides what
# gets installed — the macOS default browser is never touched.
browser_selection_screen() {
    # Format: "cask_token|display_label|one-line description"
    local raw_browsers=(
        "zen|Zen Browser|Firefox-based, vertical tabs, split view, workspaces"
        "brave-browser|Brave|Chromium with built-in ad and tracker blocking"
        "google-chrome|Google Chrome|Chromium baseline for DevTools and testing"
        "firefox|Mozilla Firefox|Gecko engine, for cross-engine testing"
        "arc|Arc|Chromium with spaces and a sidebar-first layout"
        "vivaldi|Vivaldi|Chromium, heavily customizable, built-in tiling"
        "microsoft-edge|Microsoft Edge|Chromium with Edge-specific DevTools"
        "orion|Orion|WebKit engine, runs Chrome and Firefox extensions"
        "librewolf|LibreWolf|Hardened Firefox fork with telemetry stripped"
        "floorp|Floorp|Firefox fork with vertical tabs and workspaces"
    )

    local current=0
    local total=${#raw_browsers[@]}
    cursor_hide

    # Helper: append or remove a browser from the install list, order preserved
    _toggle_browser() {
        local token="$1"
        if _is_in_list "$token" "$CONFIG_BROWSERS"; then
            CONFIG_BROWSERS="$(echo "$CONFIG_BROWSERS" | tr ' ' '\n' | grep -vFx "$token" | tr '\n' ' ' | xargs)"
        else
            CONFIG_BROWSERS="$(echo "$CONFIG_BROWSERS $token" | xargs)"
        fi
    }

    while true; do
        render_header
        printf "%s🌐 Step 3/5: Choose Your Browsers%s\n\n" "$C_HEAD" "$C_RESET"

        for i in "${!raw_browsers[@]}"; do
            IFS='|' read -r b_token b_label b_desc <<<"${raw_browsers[$i]}"
            local check=" "
            local color="$C_DIM"

            if _is_in_list "$b_token" "$CONFIG_BROWSERS"; then
                check="✓"
                color="$C_GREEN"
            fi

            if [ "$i" -eq "$current" ]; then
                printf " %s❯%s [%s%s%s] %s%-18s%s %s%s%s\n" "$C_MAUVE" "$C_RESET" "$color" "$check" "$C_RESET" "$C_BOLD$C_WHITE" "$b_label" "$C_RESET" "$C_TEAL" "$b_desc" "$C_RESET"
            else
                printf "   [%s%s%s] %s%-18s%s %s%s%s\n" "$color" "$check" "$C_RESET" "$C_DIM" "$b_label" "$C_RESET" "$C_GRAY" "$b_desc" "$C_RESET"
            fi
        done

        printf "\n%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        if [ -n "$CONFIG_BROWSERS" ]; then
            printf "%s📋 Installing:%s %s\n" "$C_BOLD" "$C_RESET" "$CONFIG_BROWSERS"
        else
            printf "%s📋 Installing:%s %snothing — Safari stays your only browser%s\n" "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
        fi
        printf "%sYour macOS default browser is left untouched — set it yourself later.%s\n" "$C_DIM" "$C_RESET"
        printf "%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s[↑/↓] Move   [Space] Toggle   [n] Select None   [Enter] Continue%s\n" "$C_DIM" "$C_RESET"

        local action
        action="$(read_key)"
        case "$action" in
            UP)
                current=$(((current - 1 + total) % total))
                ;;
            DOWN)
                current=$(((current + 1) % total))
                ;;
            SPACE)
                IFS='|' read -r b_token b_label b_desc <<<"${raw_browsers[$current]}"
                _toggle_browser "$b_token"
                ;;
            N)
                CONFIG_BROWSERS=""
                ;;
            ENTER)
                cursor_show
                # An empty list disables the category so no stray header is emitted
                if [ -n "$CONFIG_BROWSERS" ]; then
                    CAT_BROWSERS=1
                else
                    CAT_BROWSERS=0
                fi
                return 0
                ;;
            Q | ESC)
                cursor_show
                clear_screen
                log_info "Setup cancelled by user."
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# SCREEN 3: MACHINE & CONFIGURATION CUSTOMIZER
# ==============================================================================
config_customizer_screen() {
    local fields=(
        "Git User Name"
        "Git Email Address"
        "Git Delta Diff Style"
        "Theme Palette"
        "Terminal Font"
        "Ghostty Background Opacity"
        "AeroSpace Modifier Key"
        "AeroSpace Window Gaps"
        "Apply macOS System Defaults"
    )

    local current=0
    local total=${#fields[@]}
    cursor_hide

    while true; do
        render_header
        printf "%s🎨 Step 4/5: Personalize Configuration & Aesthetics%s\n\n" "$C_HEAD" "$C_RESET"

        # Field 0: Git Name
        local f0="[ ${CONFIG_GIT_NAME:-"(not set)"} ]"
        # Field 1: Git Email
        local f1="[ ${CONFIG_GIT_EMAIL:-"(not set)"} ]"
        # Field 2: Delta
        local f2_text="Inline"
        [ "$CONFIG_GIT_DELTA_SIDE_BY_SIDE" = true ] && f2_text="Side-by-Side"
        local f2="[ $f2_text ]"
        # Field 3: Palette
        local f3="[ ${CONFIG_THEME_PALETTE} ]"
        # Field 4: Font
        local f4="[ ${CONFIG_THEME_FONT} ]"
        # Field 5: Opacity
        local f5="[ ${CONFIG_GHOSTTY_OPACITY} ]"
        # Field 6: AeroSpace Modifier
        local f6="[ ${CONFIG_AEROSPACE_MODIFIER} (Option) ]"
        # Field 7: AeroSpace Gaps
        local f7="[ ${CONFIG_AEROSPACE_GAPS}px ]"
        # Field 8: macOS Defaults
        local f8_text="No (Skip)"
        [ "$CONFIG_MACOS_DEFAULTS_ENABLED" = true ] && f8_text="Yes (Fast Dock & Keys)"
        local f8="[ $f8_text ]"

        local values=("$f0" "$f1" "$f2" "$f3" "$f4" "$f5" "$f6" "$f7" "$f8")

        for i in "${!fields[@]}"; do
            if [ "$i" -eq "$current" ]; then
                printf " %s❯%s %-32s %s%s%s\n" "$C_MAUVE" "$C_RESET" "${fields[$i]}:" "$C_BOLD$C_TEAL" "${values[$i]}" "$C_RESET"
            else
                printf "   %-32s %s%s%s\n" "${fields[$i]}:" "$C_DIM" "${values[$i]}" "$C_RESET"
            fi
        done

        printf "\n%s────────────────────────────────────────────────────────────────────────%s\n" "$C_GRAY" "$C_RESET"
        printf "%s[↑/↓] Navigate   [Space/Enter] Toggle Option / Edit   [c] Continue to Install%s\n" "$C_DIM" "$C_RESET"

        local action
        action="$(read_key)"
        case "$action" in
            UP)
                current=$(((current - 1 + total) % total))
                ;;
            DOWN)
                current=$(((current + 1) % total))
                ;;
            SPACE | ENTER)
                case "$current" in
                    0) # Git Name
                        cursor_show
                        printf "\n%sEnter your Git User Name:%s " "$C_BOLD" "$C_RESET"
                        read -r input_name
                        [ -n "$input_name" ] && CONFIG_GIT_NAME="$input_name"
                        cursor_hide
                        ;;
                    1) # Git Email
                        cursor_show
                        printf "\n%sEnter your Git Email Address:%s " "$C_BOLD" "$C_RESET"
                        read -r input_email
                        [ -n "$input_email" ] && CONFIG_GIT_EMAIL="$input_email"
                        cursor_hide
                        ;;
                    2) # Delta Diff
                        if [ "$CONFIG_GIT_DELTA_SIDE_BY_SIDE" = true ]; then
                            CONFIG_GIT_DELTA_SIDE_BY_SIDE=false
                        else
                            CONFIG_GIT_DELTA_SIDE_BY_SIDE=true
                        fi
                        ;;
                    3) # Palette cycle
                        case "$CONFIG_THEME_PALETTE" in
                            catppuccin_mocha) CONFIG_THEME_PALETTE="catppuccin_macchiato" ;;
                            catppuccin_macchiato) CONFIG_THEME_PALETTE="catppuccin_frappe" ;;
                            catppuccin_frappe) CONFIG_THEME_PALETTE="catppuccin_latte" ;;
                            *) CONFIG_THEME_PALETTE="catppuccin_mocha" ;;
                        esac
                        ;;
                    4) # Font cycle
                        if [ "$CONFIG_THEME_FONT" = "0xProto Nerd Font Mono" ]; then
                            CONFIG_THEME_FONT="JetBrains Mono Nerd Font"
                        else
                            CONFIG_THEME_FONT="0xProto Nerd Font Mono"
                        fi
                        ;;
                    5) # Opacity cycle
                        case "$CONFIG_GHOSTTY_OPACITY" in
                            "0.88") CONFIG_GHOSTTY_OPACITY="0.95" ;;
                            "0.95") CONFIG_GHOSTTY_OPACITY="1.00" ;;
                            *) CONFIG_GHOSTTY_OPACITY="0.88" ;;
                        esac
                        ;;
                    6) # Modifier cycle
                        case "$CONFIG_AEROSPACE_MODIFIER" in
                            "alt") CONFIG_AEROSPACE_MODIFIER="cmd" ;;
                            "cmd") CONFIG_AEROSPACE_MODIFIER="ctrl" ;;
                            *) CONFIG_AEROSPACE_MODIFIER="alt" ;;
                        esac
                        ;;
                    7) # Gaps cycle
                        case "$CONFIG_AEROSPACE_GAPS" in
                            8) CONFIG_AEROSPACE_GAPS=4 ;;
                            4) CONFIG_AEROSPACE_GAPS=12 ;;
                            12) CONFIG_AEROSPACE_GAPS=0 ;;
                            *) CONFIG_AEROSPACE_GAPS=8 ;;
                        esac
                        ;;
                    8) # macOS defaults toggle
                        if [ "$CONFIG_MACOS_DEFAULTS_ENABLED" = true ]; then
                            CONFIG_MACOS_DEFAULTS_ENABLED=false
                        else
                            CONFIG_MACOS_DEFAULTS_ENABLED=true
                        fi
                        ;;
                esac
                ;;
            C)
                cursor_show
                return 0
                ;;
            Q | ESC)
                cursor_show
                clear_screen
                log_info "Setup cancelled by user."
                exit 0
                ;;
        esac
    done
}

# ==============================================================================
# SCREEN 4: SUMMARY & CONFIRMATION
# ==============================================================================
summary_confirmation_screen() {
    local active_cats=0
    for cat_var in CAT_WINDOW_MANAGEMENT CAT_TERMINAL CAT_CORE_CLI CAT_MODERN_CLI CAT_SHELL_QUALITY CAT_AI CAT_EDITORS CAT_GIT_TUIS CAT_RUST CAT_WEB CAT_MOBILE CAT_BROWSERS CAT_GUI_CORE CAT_FONTS CAT_SECURITY CAT_CREATIVE CAT_CUSTOM_TAP; do
        [ "${!cat_var}" -eq 1 ] && active_cats=$((active_cats + 1))
    done

    local browser_summary="none"
    if [ "$CAT_BROWSERS" -eq 1 ] && [ -n "$CONFIG_BROWSERS" ]; then
        browser_summary="$CONFIG_BROWSERS"
    fi

    render_header
    printf "%s🚀 Step 5/5: Setup Ready to Install%s\n\n" "$C_HEAD" "$C_RESET"
    printf "  • Profile:            %s%s%s\n" "$C_BOLD" "$CONFIG_PRESET_NAME" "$C_RESET"
    printf "  • Active Categories:  %s%d of 17 categories enabled%s\n" "$C_GREEN" "$active_cats" "$C_RESET"
    printf "  • Browsers:           %s%s%s\n" "$C_BOLD" "$browser_summary" "$C_RESET"
    printf "  • Theme Palette:      %s%s%s\n" "$C_BOLD" "$CONFIG_THEME_PALETTE" "$C_RESET"
    printf "  • Coding Font:        %s%s%s\n" "$C_BOLD" "$CONFIG_THEME_FONT" "$C_RESET"
    printf "  • macOS Defaults:     %s%s%s\n" "$C_BOLD" "$([ "$CONFIG_MACOS_DEFAULTS_ENABLED" = true ] && echo "Enabled" || echo "Disabled")" "$C_RESET"
    printf "  • Config Save Path:   %s%s%s\n\n" "$C_DIM" "$CONFIG_FILE" "$C_RESET"

    printf "%sPress [Enter] to start installation, or [q] to cancel.%s\n" "$C_HEAD" "$C_RESET"

    local action
    action="$(read_key)"
    if [ "$action" = "ENTER" ]; then
        clear_screen
        return 0
    else
        clear_screen
        log_info "Installation aborted."
        exit 0
    fi
}
