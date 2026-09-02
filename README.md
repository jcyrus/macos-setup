# 🍎 The Modern Mac Setup

An opinionated, "Day 1" setup script for macOS developers.

This repository automates the installation of a modern stack (Rust, Flutter, Web), CLI power tools, and essential GUI applications. It is designed to take a fresh Mac from zero to hero in under 15 minutes.

## 📦 The App Manifest

| Category          | App / Tool         | Description                                            |
| :---------------- | :----------------- | :----------------------------------------------------- |
| **🚀 Terminal**   | **Ghostty**        | GPU-accelerated terminal with Catppuccin config.       |
|                   | **Starship**       | Minimal, blazing fast shell prompt.                    |
|                   | **Zoxide**         | Smarter `cd` that remembers your most used paths.      |
|                   | **tmux**           | Terminal multiplexer with persistent sessions.         |
| **🪟 Window Mgr**  | **AeroSpace**      | i3-inspired tiling window manager (Zero SIP required). |
|                   | **JankyBorders**   | Catppuccin active window border highlighter (`borders`).|
| **🛠 Core CLI**   | **Eza**            | Modern replacement for `ls` with icons & git status.   |
|                   | **Bat**            | Modern replacement for `cat` with syntax highlighting. |
|                   | **Ripgrep**        | Ultra-fast text search tool (`rg`).                    |
|                   | **fd**             | Fast, user-friendly `find` replacement.                |
|                   | **fzf**            | Fuzzy finder for files, history, and commands.         |
|                   | **JQ**             | Command-line JSON processor.                           |
|                   | **GitHub CLI**     | Official GitHub tool (`gh`).                           |
|                   | **tealdeer**       | Fast `tldr` client with example-driven docs.           |
| **⚡ Modern CLI** | **git-delta**      | Syntax-highlighted side-by-side git diffs.             |
|                   | **dust**           | Intuitive disk usage viewer (`du` replacement).        |
|                   | **duf**            | Modern disk free utility (`df` replacement).           |
|                   | **procs**          | Modern process viewer (`ps` replacement).              |
|                   | **btop**           | Resource monitor for CPU/memory/network/processes.     |
|                   | **hyperfine**      | Reliable command-line benchmarking.                    |
|                   | **tokei**          | Fast code statistics by language.                      |
|                   | **yazi**           | Blazing-fast terminal file manager.                    |
| **🤖 AI / LLM**   | **Ollama**         | Run local LLMs on device.                              |
| **🧠 Editors**    | **VS Code**        | GUI editor with curated extensions and settings.       |
|                   | **Neovim**         | Terminal editor powered by LazyVim.                    |
| **🌿 Git TUIs**   | **Lazygit**        | Fast terminal UI for git workflows.                    |
|                   | **Lazydocker**     | Terminal UI for Docker/OrbStack workflows.             |
| **🦀 Rust**       | **Rustup**         | Official Rust toolchain manager.                       |
|                   | **Bacon**          | Background Rust code checker (TUI).                    |
|                   | **Cargo-Binstall** | Binary installer (skips compiling).                    |
| **🌐 Web**        | **FNM**            | Fast Node.js manager (Rust-based).                     |
|                   | **PNPM**           | Disk-efficient package manager.                        |
| **📱 Mobile**     | **FVM**            | Flutter Version Manager.                               |
|                   | **Scrcpy**         | Low-latency Android screen mirroring.                  |
|                   | **Cocoapods**      | Dependency manager for iOS projects.                   |
| **💻 GUI Core**   | **Raycast**        | Extensible launcher (Spotlight replacement).           |
|                   | **Brave**          | Privacy-focused browser.                               |
|                   | **Google Chrome**  | Google's web browser.                                  |
|                   | **OrbStack**       | Fast container manager for macOS.                      |
|                   | **TablePlus**      | Native database GUI.                                   |
|                   | **Shottr**         | Precision screenshot tool.                             |
|                   | **Bruno**          | Open-source API client.                                |
|                   | **AppCleaner**     | Cleanly uninstall macOS apps.                          |
|                   | **The Unarchiver** | Archive extraction utility.                            |
|                   | **Hidden Bar**     | Ultra-lightweight menu bar icon hider.                 |
|                   | **Stats**          | Open-source macOS system monitor in menu bar.          |
|                   | **UTM**            | Virtual machine host for macOS (Apple Silicon native). |
|                   | **SF Symbols**     | Official Apple iconography inspection tool.            |
| **🔒 Security**   | **Bitwarden**      | Open-source password manager.                          |
|                   | **Tailscale**      | Zero-config VPN mesh network.                          |
| **🎨 Creative**   | **Figma**          | Interface design tool.                                 |
|                   | **Darktable**      | Open-source photography workflow.                      |
|                   | **ImageMagick**    | CLI image manipulation tool.                           |
| **📓 Notes**      | **Obsidian**       | Local-first notes and knowledge base.                  |
| **🍿 Lifestyle**  | **Telegram**       | Messaging client.                                      |
|                   | **IINA**           | Modern media player.                                   |
|                   | **Stremio**        | Video streaming aggregator.                            |
|                   | **Spotify**        | Music streaming.                                       |
| **🔤 Fonts**      | **0xProto Nerd**   | Default coding font for the terminal and VS Code.      |
|                   | **JetBrains Mono Nerd** | Secondary Nerd Font.                              |
| **👻 Custom**     | **ZeroDrop**       | Secure, ephemeral TUI chat client (jcyrus tap).        |
|                   | **Spektr**         | TUI utility for cleaning dev artifacts (jcyrus tap).   |

## ⚠️ Prerequisites

- A fresh installation of macOS.
- Xcode Command Line Tools (The script will prompt you to install them if missing).

## 🛠 Usage

### One-line install

```bash
git clone https://github.com/jcyrus/macos-setup.git && cd macos-setup && chmod +x install.sh && ./install.sh
```

Running `./install.sh` in an interactive terminal launches the **Interactive TUI Setup Wizard**.

---

### 🎛️ Interactive TUI Wizard & Presets

The interactive installer guides you through choosing preset profiles, customizing packages, and tailoring configurations:

1. **⚡ Preset Profiles**:
   - **`Complete Experience`**: Installs everything (Rust, Web, Flutter, AeroSpace, Neovim, and all GUI apps).
   - **`Minimalist / CLI Focus`**: Lightweight terminal stack with Ghostty, Neovim, Tmux, Starship, Rust, and modern CLI tools.
   - **`Full-Stack Web`**: Node.js (FNM), pnpm, VS Code, Chrome, Brave, TablePlus, Bruno, OrbStack.
   - **`Systems & Rust`**: Rustup, Bacon, Cargo tools, Neovim (LazyVim), Lazygit, Yazi.
   - **`Mobile & Flutter`**: Flutter (FVM), Cocoapods, Scrcpy, VS Code, OrbStack.
   - **`Custom Checklist`**: Granular package-by-package and category selection matrix.
2. **🎨 Machine & Config Customizer**:
   - Custom Git user name, email, and Delta diff layout.
   - Theme selection (Catppuccin Mocha, Macchiato, Frappe, Latte).
   - Coding font selection (0xProto Nerd Font, JetBrains Mono Nerd Font).
   - Ghostty background opacity and blur.
   - AeroSpace modifier key (`alt`/`cmd`/`ctrl`) and gap dimensions.
   - Toggle macOS system defaults and fast keyboard repeat rates.
3. **💾 Saved State**:
   - Saves your choices to `~/.config/macos-setup/config.toml` so future runs and `./update.sh` stay consistent.

---

### 🤖 Non-Interactive & AI Agent Execution

For CI pipelines, unattended automation, or AI agents:

```bash
# Run full installation unattended
./install.sh --unattended

# Run a specific profile headlessly
./install.sh --preset=minimalist -y
./install.sh --preset=web -y

# Simulate changes without installing (Dry Run)
./install.sh --dry-run

# Use a pre-existing config file
./install.sh --config ~/.config/macos-setup/config.toml -y
```

AI coding agents follow the automated playbooks in [AGENTS.md](AGENTS.md).

---

### Step 3: Updates

To keep your apps and tools up to date according to your active profile:

```bash
./update.sh
```

### Step 4: Health Check

To see how far a machine has drifted from your configured setup, run the manifest-aware doctor:

```bash
./doctor.sh
```

It validates only the components enabled in your profile, reporting dangling symlinks, missing shell initializations, unactivated toolchains, or unapplied VS Code settings. Exits non-zero if any required component failed.

### Step 5: Post-Install Steps

1. **Ghostty:** Open Ghostty to verify the bundled Catppuccin Mocha config and font rendering.
2. **tmux:** Start `tmux`, then press `prefix + I` (capital i) to install TPM plugins, including Catppuccin.
3. **Raycast:** Open Raycast (`Alt+Space`) and install extensions.
4. **Shottr:** Launch it once, then set its save folder to `~/Screenshots` in Preferences. This step cannot be scripted — see [macOS System Defaults](#-macos-system-defaults). Re-run `./macos.sh` afterwards to apply its filename and cursor settings.
5. **Flutter:** Run `fvm install stable && fvm global stable` to get the latest SDK.
6. **Ollama:** Pull your first model: `ollama pull llama3.2`.
7. **Neovim:** Run `nvim` once to bootstrap LazyVim and install plugins/LSP tools.
8. **VS Code:** Apply the settings and install recommended extensions (see below).
9. **App Store (optional):** `mas` is installed for scripting App Store installs, but this Brewfile ships no `mas` entries. Add your own with `mas "App Name", id: 1234567890` after signing in to the App Store.

### Step 6: Quick Verification (Optional)

Run these grouped checks to verify the setup quickly.

**Core CLI**

```bash
git --version && gh --version && rg --version && fzf --version
eza --version && bat --version && zoxide --version
```

**Rust / Web / Mobile**

```bash
rustc --version && cargo --version && bacon --version
node --version && pnpm --version
fvm --version && pod --version
```

**Neovim / tmux / Git TUIs**

```bash
nvim --version | head -n 1
tmux -V
lazygit --version && lazydocker --version
```

**AI / LLM**

```bash
ollama --version
ollama list
```

If `ollama list` is empty, pull a model:

```bash
ollama pull llama3.2
```

## 🍎 macOS System Defaults

`./macos.sh` applies opinionated system preferences — the settings that make a
Mac pleasant for keyboard-driven development. It is separate from `install.sh`
because system preferences are more personal than installed apps.

```bash
./macos.sh --dry-run    # preview every change, write nothing
./macos.sh              # apply (backs up first)
```

Everything is a user-level `defaults write`. Nothing needs `sudo`, and nothing
weakens security posture — Gatekeeper, quarantine and FileVault are left alone.

### What it changes

- **Keyboard:** disables press-and-hold so held keys repeat, sets a fast repeat
  rate and short initial delay, and enables full keyboard navigation. These
  matter most for Neovim and tmux's vi mode.
- **Text input:** disables smart quotes, smart dashes, auto-capitalisation,
  auto-period and autocorrect, all of which corrupt code and commit messages.
- **Finder:** shows file extensions, the path bar and the status bar; defaults
  to list view; scopes search to the current folder; sorts folders first; and
  stops `.DS_Store` files being written to network shares and USB volumes.
- **Screenshots:** sends the built-in `Cmd-Shift-3/4` captures to
  `~/Screenshots` as shadowless PNGs, with no floating thumbnail.
- **Dock & Spaces:** auto-hides the Dock with no reveal delay, hides recent
  apps, shrinks the tiles, and stops macOS reordering Spaces by recent use.
- **Windows & dialogs:** expands save and print panels by default and speeds up
  window resize animations.

### Undo

Every domain is exported to `~/.macos-setup-backups/<timestamp>/` before any
write. Domains that were untouched export as empty plists, so restoring returns
them to genuine system defaults rather than to some earlier customised state:

```bash
./macos.sh --restore ~/.macos-setup-backups/<timestamp>
```

### Deliberate omissions

- **Showing hidden files permanently** (`AppleShowAllFiles`) — `Cmd-Shift-.`
  toggles dotfiles on demand instead of cluttering every window.
- **Forcing local saves** (`NSDocumentSaveNewDocumentsToCloud`) — left unset so
  new documents keep going to iCloud and follow you across devices.
- **Disabling the quarantine prompt** (`LSQuarantine`) — common in dotfiles
  repos, but it weakens Gatekeeper.
- **Shottr's save folder** — genuinely cannot be scripted. Shottr is sandboxed
  with only `files.user-selected.read-write`, so its write permission comes
  from a security-scoped bookmark macOS creates when you pick the folder in its
  own panel. A path written to `defaults` carries no such permission. The
  script sets the Shottr keys that *are* scriptable and points you at the rest.

## 🎨 VS Code Setup

This repo includes opinionated VS Code settings for Rust, Flutter, and Web development.

### Apply Settings

Copy the settings to your VS Code config directory:

```bash
cp vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

### Install Recommended Extensions

Open the `vscode/extensions.json` in VS Code, or install them via CLI:

```bash
code --install-extension esbenp.prettier-vscode
code --install-extension rust-lang.rust-analyzer
code --install-extension tamasfe.even-better-toml
code --install-extension fill-labs.dependi
code --install-extension dart-code.dart-code
code --install-extension dart-code.flutter
code --install-extension bradlc.vscode-tailwindcss
code --install-extension dbaeumer.vscode-eslint
code --install-extension pkief.material-icon-theme
code --install-extension eamodio.gitlens
code --install-extension usernamehw.errorlens
code --install-extension christian-kohler.path-intellisense
code --install-extension mikestead.dotenv
```

> **Note:** The settings use `0xProto Nerd Font Mono`. Install it via: `brew install --cask font-0xproto-nerd-font`

## 🧠 Neovim Setup (LazyVim)

This repo ships a ready-to-use LazyVim config in `nvim/` and symlinks it to `~/.config/nvim` during `./install.sh`.

### Enabled language extras

These are declared directly in `nvim/lua/config/lazy.lua` and install on first launch — there is nothing to toggle via `:LazyExtras`:

- Rust
- Dart/Flutter
- Tailwind CSS
- TypeScript/JavaScript
- TOML
- Git

## 🖥 Terminal Setup

`./install.sh` wires up the terminal stack automatically by symlinking the repo configs into your home directory.

### Included configs

- **Ghostty:** The `ghostty/` directory is linked to `~/.config/ghostty`, so Ghostty uses `~/.config/ghostty/config` with `0xProto Nerd Font Mono`, Catppuccin Mocha colors, translucent background, hidden title bar, and tuned cursor/padding settings.
- **Starship:** `starship/starship.toml` is linked to `~/.config/starship.toml` and uses a Catppuccin Mocha powerline prompt with Nerd Font icons.
- **tmux:** `tmux/.tmux.conf` is linked to `~/.tmux.conf` and uses TPM plus `catppuccin/tmux` for a top status bar with session, app, user, and time segments.

### Prerequisites

- `0xProto Nerd Font Mono` for the shared terminal/editor font setup.
- `font-jetbrains-mono-nerd-font` is installed by default as a secondary Nerd Font.

### Notes

- LazyVim bootstraps on first run of `nvim`.
- Mason installs language servers/debug tools automatically.
- Use `:LazyExtras` to toggle modules beyond the ones already declared in `nvim/lua/config/lazy.lua`.

## 🪟 Window Management (AeroSpace + JankyBorders)

`./install.sh` configures **AeroSpace** (an i3-inspired tree tiling window manager) and **JankyBorders** (an active window border highlighter with Catppuccin Mocha Mauve accent).

Unlike `yabai`, AeroSpace requires **zero SIP tampering** and uses instant virtual workspaces without macOS animation delays.

### Keyboard Shortcuts (⌥ Option Modifier)

All window management shortcuts use the `⌥ Option` (Alt) key to avoid colliding with `⌘ Command` (macOS apps), `⌃ Ctrl+a` (tmux), or Neovim:

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`⌥ Opt + H` / `J` / `K` / `L`** | Focus Window | Vim-style directional focus (Left / Down / Up / Right). |
| **`⌥ Opt + ⇧ Shift + H` / `J` / `K` / `L`** | Swap / Move Window | Swap position of current window in that direction. |
| **`⌥ Opt + F`** | Maximize / Zoom Toggle | Toggle fullscreen zoom for the focused window. |
| **`⌥ Opt + /`** | Toggle Split Axis | Switch split between Horizontal (side-by-side) and Vertical. |
| **`⌥ Opt + E`** | Accordion Layout | Toggle accordion mode for nested tiles. |
| **`⌥ Opt + ⇧ Shift + Space`** | Float / Tile Toggle | Detach window to floating mode (or re-tile). |
| **`⌥ Opt + 1` .. `9`** | Switch Workspace | Jump to workspace 1 through 9 instantly (0ms delay). |
| **`⌥ Opt + ⇧ Shift + 1` .. `9`** | Move to Workspace | Send focused window to workspace and follow focus. |
| **`⌥ Opt + Tab`** | Toggle Workspace | Bounce back to previous active workspace. |
| **`⌥ Opt + ⇧ Shift + Tab`** | Move to Next Monitor | Move focused window to the next connected display. |
| **`⌥ Opt + R`** | Resize Mode | Enter resize mode (`H`/`J`/`K`/`L` to resize, `B` to balance, `Esc` to exit). |
| **`⌥ Opt + ⇧ Shift + ;`** | Service Mode | System actions (`Esc` to reload config, `R` to flatten tree). |

> **Note:** On first launch, macOS requires granting **Accessibility** permission to AeroSpace in **System Settings → Privacy & Security → Accessibility**. Utility popups (Raycast, Shottr, Bitwarden, Finder dialogs) are automatically set to floating mode.

## 📦 Customization

Edit `Brewfile` to add or remove tools before running the installer. Comment out lines with `#` to skip optional apps.

## 🧹 Shell Linting

The scripts in this repo are the product, so they are linted and formatted on
the way in rather than audited afterwards.

| Tool           | Role                                                        |
| :------------- | :---------------------------------------------------------- |
| **shellcheck** | Finds real bugs — unquoted expansions, `set -e` masking.     |
| **shfmt**      | Formats shell source. Style comes from `.editorconfig`.      |
| **lefthook**   | Runs both as a pre-commit hook.                              |

`install.sh` installs the hooks automatically when run from a git clone. To set
them up by hand:

```bash
lefthook install
```

On commit, `shellcheck` **blocks** if it finds anything (it cannot auto-fix),
while `shfmt` rewrites the file and restages it. To check everything manually:

```bash
shellcheck ./*.sh          # lint
shfmt -d ./*.sh            # show formatting diffs
shfmt -w ./*.sh            # apply formatting
```

Bypass the hook for a single commit with `LEFTHOOK=0 git commit ...`.

> **Note:** `.editorconfig` is the single source of truth for shell formatting.
> shfmt reads it directly and **ignores** `-i`/`-ci` flags while it exists, so
> change the style there rather than in `lefthook.yml`.

### Suppressed warnings

Two shellcheck warnings are disabled deliberately, both documented inline:

- **SC2088** in `doctor.sh` — the `"~/..."` strings are display labels, not
  paths. The real paths beside them use `$HOME`.
- **SC2143** in `install.sh` and `doctor.sh` — shellcheck suggests
  `! grep -q`, but that is **not** equivalent on macOS. BSD grep exits 0 for
  `-qv` on empty input, so the rewrite would misreport a failing `rustup` as
  "toolchain already installed" and skip the install.

## 🤝 Contributing

Found a bug or want to add a new tool? Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
