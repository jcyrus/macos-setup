# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]

### Removed

- Warp cask. Ghostty is the terminal this repo actually configures; Warp is now an optional, commented-out entry.
- `font-jetbrains-mono`, which is superseded by `font-jetbrains-mono-nerd-font`, and `font-fira-code`, which no config referenced (moved to optional).
- Duplicate `brew tap` calls in `install.sh`; taps are declared in the Brewfile and applied by `brew bundle`.

### Added

- Ghostty config with manual Catppuccin Mocha colors, translucent background, blur, tuned padding, and Nerd Font settings.
- Starship prompt config with a Catppuccin Mocha powerline layout, Nerd Font icon overrides, and a two-line prompt with command duration above the prompt character.
- Catppuccin-based tmux theming with a top status bar and session, application, user, and time segments.
- Homebrew install entries for Ghostty and JetBrains Mono Nerd Font.

### Changed

- Updated the installer to symlink Ghostty and Starship configs and clone the Catppuccin tmux plugin alongside TPM.
- Updated the README with terminal setup details, prerequisites, and a one-line install command.
