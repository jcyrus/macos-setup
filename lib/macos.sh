#!/bin/bash
# lib/macos.sh — Modular macOS system preferences applicator.

# Prevent multiple inclusions
if [ -n "${_MACOS_SETUP_MACOS_LOADED:-}" ]; then
    return 0
fi
_MACOS_SETUP_MACOS_LOADED=1

apply_macos_settings() {
    if [ "${CONFIG_MACOS_DEFAULTS_ENABLED:-true}" = false ]; then
        log_info "macOS system defaults disabled in configuration. Skipping."
        return 0
    fi

    log_step "Applying macOS developer system preferences..."

    local backup_root="$HOME/.macos-setup-backups"
    local backup_timestamp
    backup_timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_dir="$backup_root/$backup_timestamp"
    mkdir -p "$backup_dir"

    local domains=(
        "NSGlobalDomain"
        "com.apple.finder"
        "com.apple.dock"
        "com.apple.screencapture"
        "com.apple.desktopservices"
        "cc.ffitch.shottr"
    )

    log_dim "Backing up current preferences to $backup_dir..."
    for domain in "${domains[@]}"; do
        defaults export "$domain" "$backup_dir/$domain.plist" 2>/dev/null || true
    done

    # Keyboard & input
    if [ "${CONFIG_MACOS_FAST_KEY_REPEAT:-true}" = true ]; then
        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
        defaults write NSGlobalDomain KeyRepeat -int 2
        defaults write NSGlobalDomain InitialKeyRepeat -int 15
    fi
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Disable smart text substitutions
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Finder
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Screenshots
    local screenshot_dir="${CONFIG_MACOS_SCREENSHOTS_DIR:-$HOME/Screenshots}"
    mkdir -p "$screenshot_dir"
    defaults write com.apple.screencapture location -string "$screenshot_dir"
    defaults write com.apple.screencapture type -string "png"
    defaults write com.apple.screencapture disable-shadow -bool true
    defaults write com.apple.screencapture show-thumbnail -bool false

    # Dock
    if [ "${CONFIG_MACOS_DOCK_AUTOHIDE:-true}" = true ]; then
        defaults write com.apple.dock autohide -bool true
        if [ "${CONFIG_MACOS_DOCK_FAST:-true}" = true ]; then
            defaults write com.apple.dock autohide-delay -float 0
            defaults write com.apple.dock autohide-time-modifier -float 0.15
        fi
    fi
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock mru-spaces -bool false

    # Windows & Save Panels
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

    # Restart UI Services
    killall Finder Dock SystemUIServer 2>/dev/null || true
    log_success "macOS system preferences applied cleanly."
}
