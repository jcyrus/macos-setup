#!/bin/bash
# macos.sh — opinionated macOS system preferences for this setup.
#
# Every setting here is a user-level `defaults write`. Nothing needs sudo, and
# nothing touches security posture (Gatekeeper, quarantine, FileVault and
# friends are deliberately left alone).
#
# Usage:
#   ./macos.sh              apply the settings (backs up first)
#   ./macos.sh --dry-run    print what would change, write nothing
#   ./macos.sh --restore D  restore the domains from backup directory D
#
# Customisation follows the same convention as the Brewfile: comment out any
# line you do not want.

set -e

BACKUP_ROOT="$HOME/.macos-setup-backups"
SCREENSHOT_DIR="$HOME/Screenshots"

DRY_RUN=false
RESTORE_DIR=""

case "${1:-}" in
    --dry-run) DRY_RUN=true ;;
    --restore)
        RESTORE_DIR="${2:-}"
        if [ -z "$RESTORE_DIR" ]; then
            echo "❌ --restore needs a backup directory."
            echo "   Available:"
            find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null |
                sort | sed 's/^/     /' || echo "     (none)"
            exit 1
        fi
        ;;
    "") ;;
    *)
        echo "❌ Unknown option: $1"
        echo "   Usage: ./macos.sh [--dry-run | --restore <backup-dir>]"
        exit 1
        ;;
esac

# Every domain this script writes to. Backup and restore both walk this list,
# so adding a setting in a new domain only needs the domain added here.
DOMAINS=(
    "NSGlobalDomain"
    "com.apple.finder"
    "com.apple.dock"
    "com.apple.screencapture"
    "com.apple.desktopservices"
    "cc.ffitch.shottr"
)

# --- Restore mode -----------------------------------------------------------
if [ -n "$RESTORE_DIR" ]; then
    # Accept either a bare timestamp or a full path.
    if [ ! -d "$RESTORE_DIR" ] && [ -d "$BACKUP_ROOT/$RESTORE_DIR" ]; then
        RESTORE_DIR="$BACKUP_ROOT/$RESTORE_DIR"
    fi
    if [ ! -d "$RESTORE_DIR" ]; then
        echo "❌ No such backup directory: $RESTORE_DIR"
        exit 1
    fi

    echo "⏪ Restoring macOS defaults from $RESTORE_DIR"
    for domain in "${DOMAINS[@]}"; do
        plist="$RESTORE_DIR/$domain.plist"
        if [ -f "$plist" ]; then
            defaults import "$domain" "$plist"
            echo "   restored $domain"
        else
            echo "   ⚠️  no backup for $domain, skipping"
        fi
    done
    echo "🔄 Restarting Finder, Dock and SystemUIServer..."
    killall Finder Dock SystemUIServer 2>/dev/null || true
    echo "✅ Restore complete. Log out and back in for everything to settle."
    exit 0
fi

# --- Backup -----------------------------------------------------------------
if [ "$DRY_RUN" = false ]; then
    BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "💾 Backing up current values to $BACKUP_DIR"
    for domain in "${DOMAINS[@]}"; do
        # An unset domain exports as an empty plist, which is exactly right:
        # importing it later returns the domain to untouched system defaults.
        defaults export "$domain" "$BACKUP_DIR/$domain.plist" 2>/dev/null || true
    done
    echo "   undo with: ./macos.sh --restore $BACKUP_DIR"
else
    echo "🔍 Dry run — nothing will be written."
fi

# d <domain> <key> <type> <value> [note]
d() {
    local domain="$1" key="$2" type="$3" value="$4" note="${5:-}"
    if [ "$DRY_RUN" = true ]; then
        printf "   %-46s %s %s\n" "$key" "$value" "${note:+# $note}"
    else
        defaults write "$domain" "$key" "$type" "$value"
        printf "   %-46s %s %s\n" "$key" "$value" "${note:+# $note}"
    fi
}

section() { printf "\n\033[1;36m── %s\033[0m\n" "$1"; }

printf "\n\033[1;36m🍎 Applying macOS defaults\033[0m\n"

# --- Keyboard ---------------------------------------------------------------
# These are the settings this repo cares about most. LazyVim, tmux's vi mode
# and the vim pane bindings all depend on held keys repeating rather than
# opening the accent picker.
section "Keyboard & input"
d NSGlobalDomain ApplePressAndHoldEnabled -bool false "hold key repeats, no accent popup"
d NSGlobalDomain KeyRepeat -int 2 "fast repeat rate"
d NSGlobalDomain InitialKeyRepeat -int 15 "short delay before repeat"
d NSGlobalDomain AppleKeyboardUIMode -int 3 "tab moves through every control"

# Text substitutions that corrupt code and commit messages.
d NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false "no smart quotes"
d NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false "no smart dashes"
d NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false "no auto period"
d NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false "no auto capitalise"
d NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false "no autocorrect"

# --- Finder -----------------------------------------------------------------
section "Finder"
d NSGlobalDomain AppleShowAllExtensions -bool true "always show file extensions"
# AppleShowAllFiles is deliberately NOT set: Cmd-Shift-. toggles dotfiles on
# demand, which beats having them permanently clutter every Finder window.
d com.apple.finder ShowPathbar -bool true "show path bar"
d com.apple.finder ShowStatusBar -bool true "show status bar"
d com.apple.finder FXPreferredViewStyle -string "Nlsv" "list view by default"
d com.apple.finder FXDefaultSearchScope -string "SCcf" "search current folder first"
d com.apple.finder FXEnableExtensionChangeWarning -bool false "no extension-change nag"
d com.apple.finder _FXSortFoldersFirst -bool true "folders before files"

# Keep .DS_Store off network shares and USB sticks. Nothing is more annoying
# than a repo on a share picking these up.
d com.apple.desktopservices DSDontWriteNetworkStores -bool true "no .DS_Store on network shares"
d com.apple.desktopservices DSDontWriteUSBStores -bool true "no .DS_Store on USB volumes"

# --- Screenshots ------------------------------------------------------------
# Shottr handles most capture work, but these govern the built-in Cmd-Shift-3/4.
section "Screenshots"
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$SCREENSHOT_DIR"
fi
d com.apple.screencapture location -string "$SCREENSHOT_DIR" "out of the Desktop"
d com.apple.screencapture type -string "png" "png, not heic"
d com.apple.screencapture disable-shadow -bool true "no window drop shadow"
d com.apple.screencapture show-thumbnail -bool false "no floating thumbnail"

# --- Shottr -----------------------------------------------------------------
# Shottr's save folder CANNOT be set from here, and this is not a gap in the
# script. The app is sandboxed with only `files.user-selected.read-write`, so
# its write permission comes from a security-scoped bookmark macOS mints when
# you choose the folder in Shottr's own panel. A bare path written into
# `defaults` would carry no permission with it. Verify with:
#     codesign -d --entitlements - /Applications/Shottr.app
#
# saveFormat is deliberately left alone: PNG is already Shottr's default and
# the only value its docs list is JPEG.
section "Shottr"
if [ -d "/Applications/Shottr.app" ]; then
    if defaults read cc.ffitch.shottr &>/dev/null; then
        d cc.ffitch.shottr fileNameTemplate -string "Screenshot %Y-%m-%d at %H.%M.%S" "sortable filenames"
        d cc.ffitch.shottr captureCursor -string "exclude" "keep the cursor out of captures"
    else
        echo "   ⚠️  Shottr has never been launched, so it has no preferences yet."
        echo "      Launch it once, then re-run this script to apply its settings."
    fi
    echo "   ℹ️  Point Shottr at $SCREENSHOT_DIR by hand (Preferences > General)."
    echo "      Sandboxing means the folder must be picked in Shottr's own panel."
else
    echo "   Shottr not installed, skipping."
fi

# --- Dock & Spaces ----------------------------------------------------------
section "Dock & Spaces"
d com.apple.dock autohide -bool true "auto-hide the Dock"
d com.apple.dock autohide-delay -float 0 "no delay before showing"
d com.apple.dock autohide-time-modifier -float 0.15 "faster show/hide animation"
d com.apple.dock show-recents -bool false "no recent applications"
d com.apple.dock tilesize -int 48 "smaller icons"
d com.apple.dock minimize-to-application -bool true "minimise into the app icon"
# Keep Spaces in a fixed order. Required for any predictable window-management
# or tiling setup; macOS otherwise reshuffles them by recent use.
d com.apple.dock mru-spaces -bool false "do not reorder Spaces"

# --- Windows & dialogs ------------------------------------------------------
section "Windows & dialogs"
d NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true "expanded save panel"
d NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true "expanded save panel"
d NSGlobalDomain PMPrintingExpandedStateForPrint -bool true "expanded print panel"
d NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true "expanded print panel"
d NSGlobalDomain NSWindowResizeTime -float 0.001 "near-instant window resize"

# NSDocumentSaveNewDocumentsToCloud is deliberately NOT set. Most dotfiles
# repos force it to false to keep new documents local; here iCloud is wanted
# so files follow across devices. Leaving it unset keeps the macOS default,
# which is to save to iCloud. Do not "fix" this.

# --- Apply ------------------------------------------------------------------
if [ "$DRY_RUN" = true ]; then
    printf "\n🔍 Dry run complete. Re-run without --dry-run to apply.\n"
    exit 0
fi

printf "\n🔄 Restarting Finder, Dock and SystemUIServer to apply...\n"
killall Finder Dock SystemUIServer 2>/dev/null || true

printf "\n✅ Done.\n"
echo "   Some settings (key repeat, keyboard navigation) only take effect in"
echo "   apps launched from now on — log out and back in to apply everywhere."
echo "   Undo everything with: ./macos.sh --restore $BACKUP_DIR"
