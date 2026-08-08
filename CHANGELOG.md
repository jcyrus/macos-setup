# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]

### Fixed

- `fnm install --lts` never set a default alias, so `node` was unavailable in new shells and the README's `node --version` check failed. Both scripts now run `fnm default lts-latest`.
- The fzf setup block in `install.sh` was guarded by a marker string it never wrote, so it was appended again on every run.
- `zoxide` and `fzf` were initialised twice: once via the Oh My Zsh plugins and again explicitly. They are now initialised only once, directly, and `zsh-syntax-highlighting` is last in the plugin list as upstream requires.
- `install.sh` and `update.sh` passed a relative `./Brewfile` to `brew bundle`, breaking when invoked from another directory.
- `install.sh` overwrote any pre-existing `plugins=(...)` line with `sed`, silently dropping user customisations. It now warns instead.
- `rustup-init` was re-run unconditionally, aborting the whole script under `set -e` when Rust was already installed.
- A single failing Brewfile entry aborted the run before any shell or dotfile setup; the bundle step now warns and continues.
- `install.sh` did not check for Xcode Command Line Tools despite the README claiming it did, and never primed the tealdeer cache.

### Removed

- Warp cask. Ghostty is the terminal this repo actually configures; Warp is now an optional, commented-out entry.
- `font-jetbrains-mono`, which is superseded by `font-jetbrains-mono-nerd-font`, and `font-fira-code`, which no config referenced (moved to optional).
- Duplicate `brew tap` calls in `install.sh`; taps are declared in the Brewfile and applied by `brew bundle`.
- The hand-written 16-colour palette in `ghostty/config`, replaced by Ghostty's built-in `theme = Catppuccin Mocha` (verified to resolve to identical colours).

### Added

- Ghostty config with manual Catppuccin Mocha colors, translucent background, blur, tuned padding, and Nerd Font settings.
- Starship prompt config with a Catppuccin Mocha powerline layout, Nerd Font icon overrides, and a two-line prompt with command duration above the prompt character.
- Catppuccin-based tmux theming with a top status bar and session, application, user, and time segments.
- Homebrew install entries for Ghostty and JetBrains Mono Nerd Font.

### Changed

- Updated the installer to symlink Ghostty and Starship configs and clone the Catppuccin tmux plugin alongside TPM.
- Updated the README with terminal setup details, prerequisites, and a one-line install command.
