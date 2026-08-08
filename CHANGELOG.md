# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]

### Added

- Ghostty config using the built-in Catppuccin Mocha theme, with translucent background, blur, tuned padding, and Nerd Font settings.
- Starship prompt config with a Catppuccin Mocha powerline layout, Nerd Font icon overrides, and a two-line prompt with command duration above the prompt character.
- Catppuccin-based tmux theming with a top status bar and session, application, user, and time segments.
- Homebrew install entries for Ghostty and JetBrains Mono Nerd Font.
- `doctor.sh`, a read-only health check that reports how far the current machine has drifted from what `install.sh` produces. It makes no changes; it catches dangling config symlinks, missing shell initialisation, duplicated zoxide/fzf setup, unactivated toolchains, and unapplied VS Code settings.

### Changed

- The installer symlinks the Ghostty and Starship configs and clones the Catppuccin tmux plugin alongside TPM, pinned to the tag the config is written against.
- `tmux` uses `tmux-256color` rather than `screen-256color`, and advertises RGB for `xterm-ghostty`.
- The Oh My Zsh plugin list no longer includes `zoxide` or `fzf`; both are initialised directly instead, and `zsh-syntax-highlighting` is last as upstream requires.
- Updated the README with terminal setup details, prerequisites, and a one-line install command.

### Fixed

- `MANUAL_INSTALL.md` did not reproduce `install.sh`. It was missing the Ghostty cask entirely, the Ghostty/Starship config symlinks, the git-delta configuration, `font-jetbrains-mono-nerd-font`, the pinned Catppuccin tmux clone, the tealdeer cache priming, the Xcode CLT prerequisite, and any mention of VS Code setup or `update.sh`.
- Documentation told users to enable Neovim language extras via `:LazyExtras`, but they are already imported in `nvim/lua/config/lazy.lua`; enabling them again would double-declare them.
- `fnm install --lts` never set a default alias, so `node` was unavailable in new shells and the README's `node --version` check failed. Both scripts now run `fnm default lts-latest`.
- The fzf setup block in `install.sh` was guarded by a marker string it never wrote, so it was appended again on every run.
- `zoxide` and `fzf` were initialised twice: once via the Oh My Zsh plugins and again explicitly. They are now initialised only once, directly, and `zsh-syntax-highlighting` is last in the plugin list as upstream requires.
- `install.sh` and `update.sh` passed a relative `./Brewfile` to `brew bundle`, breaking when invoked from another directory.
- `install.sh` overwrote any pre-existing `plugins=(...)` line with `sed`, silently dropping user customisations. It now warns instead.
- `rustup-init` was re-run unconditionally, aborting the whole script under `set -e` when Rust was already installed.
- A single failing Brewfile entry aborted the run before any shell or dotfile setup; the bundle step now warns and continues.
- `install.sh` did not check for Xcode Command Line Tools despite the README claiming it did, and never primed the tealdeer cache.
- `xcode-select --install` returns non-zero when an install is already in progress, which aborted the script under `set -e` before the "finish the installer, then re-run" guidance was printed.
- A failed `tldr --update` aborted `install.sh` at the last step, reporting an otherwise-complete setup as a failure.
- `update.sh` called bare `rustup update`, which fails when `~/.cargo/bin` is not on PATH.
- **Rust was never actually installed.** `rustup-init` is an old name for the `rustup` formula and the `rustup-init` binary no longer exists, so the installer's Rust step could not work on a fresh machine. Homebrew's `rustup` also links only `rustup` itself, leaving `rustc` and `cargo` in an unlinked shim directory. The Brewfile now requests `rustup`, the installer runs `rustup default stable`, and the generated `.zshrc` puts `$(brew --prefix rustup)/bin` on PATH.
- The custom tap entries were declared as casks, but `ghostwire` and `spektr` are formulae, so `brew bundle` could never satisfy them. `ghostwire` has also been renamed upstream to `zerodrop`, where the old name survives only as a migration shim.
- `github.copilot` is no longer recommended: VS Code 1.132+ bundles Copilot, and installing the marketplace extension fails trying to downgrade the newer built-in `copilot-chat`.

### Removed

- Warp cask. Ghostty is the terminal this repo actually configures; Warp is now an optional, commented-out entry.
- `font-jetbrains-mono`, which is superseded by `font-jetbrains-mono-nerd-font`, and `font-fira-code`, which no config referenced (moved to optional).
- Duplicate `brew tap` calls in `install.sh`; taps are declared in the Brewfile and applied by `brew bundle`.
- The hand-written 16-colour palette in `ghostty/config`, replaced by Ghostty's built-in `theme = Catppuccin Mocha` (verified to resolve to identical colours).
