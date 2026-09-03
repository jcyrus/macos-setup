# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]

### Added

- **Zen Browser, and a browser picker in the installer.** Browsers are now their own package category (`CAT_BROWSERS` / `[config.browsers]`) instead of being hard-coded inside GUI Core, with `zen` as the pre-selected main browser. A new TUI screen (Step 3/5) runs on every interactive install — whatever profile was chosen — offering Zen, Brave, Chrome, Firefox, Arc, Vivaldi, Edge, Orion, LibreWolf and Floorp, plus `[n]` for none. Unattended runs get the same control through `--browsers "zen firefox"` / `--browsers none`. The selection round-trips through `~/.config/macos-setup/config.toml` and is verified by `doctor.sh`. Installing a browser never changes the macOS default browser — that stays the user's call.
- **AeroSpace tiling window manager and JankyBorders focus indicator**: Added `nikitabobko/tap` and `FelixKratz/formulae` to Brewfile, complete with `aerospace/aerospace.toml` configuration, Catppuccin Mocha Mauve border integration, Vim-inspired `⌥ Option` navigation, instant virtual workspaces (zero SIP disabling required), and utility floating window rules. Updated `install.sh`, `doctor.sh`, `README.md`, `MANUAL_INSTALL.md`, and `AGENTS.md`.
- `scripts/check-templates.sh`, wired into `lefthook.yml` as a `pre-commit` gate. It renders each template with the default configuration and asserts two things: that the output parses (Starship answers an unparseable config by falling back to its stock prompt rather than erroring, so a bad escape is otherwise invisible until it reaches a machine), and that the Starship template rendered under the mocha palette reproduces `starship/starship.toml` byte for byte. Parity is asserted for the Starship pair only — the ghostty, aerospace and vscode templates deliberately differ from their repo copies in their comments, because the prose around a placeholder has to be generic. Checks whose tool is missing are reported and skipped rather than failed, since a hook that blocks on an absent optional dependency just gets bypassed.
- Shell linting for the repo's own scripts: `shellcheck`, `shfmt` and `lefthook` in the Brewfile, a `lefthook.yml` pre-commit hook, and an `.editorconfig` that is the single source of truth for shell formatting. `shellcheck` blocks a commit when it finds anything; `shfmt` reformats and restages instead. `install.sh` runs `lefthook install` when executed from a git clone.
- `.editorconfig` also covers JSON/YAML/TOML/Lua/Markdown, closing a gap where `vscode/extensions.json` recommended the EditorConfig extension but the repo shipped no config for it to read.
- `macos.sh`, an opinionated macOS system preferences script covering keyboard repeat, text substitution, Finder, screenshots, Dock/Spaces and dialog defaults. It supports `--dry-run` to preview changes and `--restore` to undo them, exporting every domain it touches to `~/.macos-setup-backups/<timestamp>/` before writing. All settings are user-level `defaults write` calls: nothing requires `sudo`, and nothing weakens Gatekeeper, quarantine or FileVault.
- Shottr's scriptable preferences (`fileNameTemplate`, `captureCursor`) are set by `macos.sh`, guarded so they are only written once Shottr has been launched and has a preferences domain to merge into. Its save folder is documented as unscriptable: the app is sandboxed with only `files.user-selected.read-write`, so write permission comes from a security-scoped bookmark created when the folder is chosen in Shottr's own panel.

### Changed

- `tailscale` cask renamed upstream to `tailscale-app`; the Brewfile and manual install instructions now use the new token.
- `install.sh` and `update.sh` now explicitly `brew tap jcyrus/tap` and `brew tap leoafarias/fvm` before `brew bundle`, so a tap failure is reported separately from a bundle failure instead of being folded into it.

### Removed

- `darktable` cask. Homebrew disabled it on 2026-09-01 because it fails the macOS Gatekeeper check, so `brew bundle` errors out on it rather than skipping it. Removed from the Brewfile, `lib/brew.sh`, the TUI checklist, the preset skip lists, and the docs.
- `whisky` cask. It's deprecated upstream (unmaintained) and no longer installable via `brew bundle`.

### Fixed

- **The Starship powerline was destroyed by any run of `install.sh`.** `templates/starship.toml.tmpl` — the file actually rendered to `~/.config/starship.toml` — wrote three `format` values as TOML *basic* strings containing `\(` (`aws`, `gcloud`, `kubernetes`). `\(` is not a valid escape in a basic string, so the whole config failed to parse and Starship silently fell back to its stock prompt: no powerline, no Catppuccin, no Nerd Font glyphs. Those three are now *literal* (single-quoted) strings, matching how `starship/starship.toml` has always written them. The template renders and parses cleanly under all four palettes.
- The same template's `format` string calls `$custom` but defined no `[custom.*]` modules, so even once parsing was fixed the powerline had no closing cap and the last segment ended flat. `[custom.git_cap]` and `[custom.dir_cap]` — which draw the end cap in green inside a git repo and blue outside one — are now in the template as well as in `starship/starship.toml`.
- **`render_template` overwrote the repo's own checked-in configs.** It redirects with `sed … > "$out"`, and older versions of the installer symlinked `~/.config/starship.toml` back into the clone. Redirecting onto a symlink writes through to its target, so on any machine carrying that legacy layout an install rewrote `starship/starship.toml`, `ghostty/config` and `aerospace/aerospace.toml` in the working tree. `render_template` now produces a real file regardless of the legacy layout. The link can sit on the file (`~/.config/starship.toml`) *or* on its parent directory (`~/.config/ghostty` → `<repo>/ghostty`, `~/.config/aerospace` → `<repo>/aerospace`); the directory case does not make `[ -L "$out" ]` true, so handling only the file left ghostty and aerospace still being overwritten on every install. Both cases are now replaced with real paths, and a final guard resolves the destination with `pwd -P` and refuses to render at all if it lands inside the checkout.
- **A network blip aborted the entire install before it touched anything.** `bootstrap_homebrew` called `brew update` bare under `set -e`, so when a transient GitHub outage made every tap fetch time out on port 443, the run died at step 4 of 8 — no packages, no dotfiles, no toolchains. A stale formula index is still perfectly usable and `brew bundle` works fine against it, so this now warns and continues, matching how `install_brew_packages` already handles a partial bundle failure. `update.sh` got the same treatment for both `brew update` and `brew upgrade`, so one package failing to build no longer skips the dotfile and toolchain steps that follow. This matters most on a day-one setup, which is exactly the situation likely to be running on unreliable wifi.
- `bootstrap_homebrew` now verifies `brew` is actually on `PATH` after installing Homebrew, and stops with an explicit instruction to open a new terminal, rather than continuing into confusing downstream failures.
- The README app manifest still listed Whisky as an installed app after the cask was removed from the Brewfile.
- `install.sh` masked the return value of `brew --prefix rustup` by assigning it inside an `export` (SC2155).
- `doctor.sh` used `tr 'A-Z' 'a-z'` to case-fold VS Code extension IDs, which is not accent- or locale-safe; it now uses `[:upper:]`/`[:lower:]`.
- `update.sh` was tab-indented while every other script used four spaces. All shell sources are now formatted consistently by `shfmt`.
- `macos.sh` computed a `REPO_DIR` it never used — caught by `shellcheck` (SC2034) as soon as linting was introduced.
- **`ls` and `ll` were broken whenever given a path.** The generated aliases used `eza --icons`, but `--icons` takes an optional `WHEN` value, so eza consumed the following argument: `ls somedir` became `eza --icons somedir` and failed with `invalid value 'somedir' for '--icons [<WHEN>]'`. Bare `ls` worked, which is why it went unnoticed. Both aliases now pass `--icons=auto` explicitly.

## [1.0.0] - 2026-08-08

### Added

- Homebrew casks for Hidden Bar (`hiddenbar`), Stats (`stats`), UTM virtual machines (`utm`), SF Symbols (`sf-symbols`), and Tailscale mesh VPN (`tailscale`).
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
