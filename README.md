# 🍎 The Modern Mac Setup

An opinionated, "Day 1" setup script for macOS developers.

This repository automates the installation of a modern stack (Rust, Flutter, Web), CLI power tools, and essential GUI applications. It is designed to take a fresh Mac from zero to hero in under 15 minutes.

## 📦 The App Manifest

| Category          | App / Tool         | Description                                            |
| :---------------- | :----------------- | :----------------------------------------------------- |
| **🚀 Terminal**   | **Warp**           | AI-powered modern terminal with blocks UI.             |
|                   | **Ghostty**        | GPU-accelerated terminal with Catppuccin config.       |
|                   | **Starship**       | Minimal, blazing fast shell prompt.                    |
|                   | **Zoxide**         | Smarter `cd` that remembers your most used paths.      |
|                   | **tmux**           | Terminal multiplexer with persistent sessions.         |
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
| **🦀 Rust**       | **Rustup**         | Official Rust toolchain installer.                     |
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
| **🔒 Security**   | **Bitwarden**      | Open-source password manager.                          |
|                   | **Tailscale**      | Zero-config VPN mesh network.                          |
| **🎨 Creative**   | **Figma**          | Interface design tool.                                 |
|                   | **Darktable**      | Open-source photography workflow.                      |
|                   | **ImageMagick**    | CLI image manipulation tool.                           |
| **📓 Notes**      | **Obsidian**       | Local-first notes and knowledge base.                  |
| **🍿 Lifestyle**  | **Telegram**       | Messaging client.                                      |
|                   | **IINA**           | Modern media player.                                   |
|                   | **Whisky**         | Run Windows games on Mac (GPTK wrapper).               |
|                   | **Stremio**        | Video streaming aggregator.                            |
|                   | **Spotify**        | Music streaming.                                       |
| **🔤 Fonts**      | **0xProto Nerd**   | Recommended coding font for terminal/editor icons.     |
|                   | **Fira Code**      | Monospaced programming font.                           |
|                   | **JetBrains Mono** | Monospaced programming font.                           |
| **👻 Custom**     | **GhostWire**      | (From jcyrus tap)                                      |
|                   | **Spektr**         | (From jcyrus tap)                                      |

## ⚠️ Prerequisites

- A fresh installation of macOS.
- Xcode Command Line Tools (The script will prompt you to install them if missing).

## 🛠 Usage

### Step 1: Clone

Open your terminal and clone this repo:

```bash
git clone https://github.com/jcyrus/macos-setup.git
cd macos-setup
chmod +x install.sh

```

### Step 2: Install

Run the installer. This sets up Homebrew, installs all apps, and configures Zsh, Neovim, and tmux.

```bash
./install.sh
```

### Step 3: Updates

To keep your apps and tools up to date, or to install new apps added to `Brewfile`:

```bash
./update.sh
```

### Step 4: Post-Install Steps

1. **Warp:** Open Warp and sign in.
2. **App Store:** Open the Mac App Store and sign in to auto-install `mas` apps.
3. **Raycast:** Open Raycast (`Alt+Space`) and install extensions.
4. **Flutter:** Run `fvm install stable` to get the latest SDK.
5. **Ollama:** Pull your first model: `ollama pull llama3.2`.
6. **Neovim:** Run `nvim` once to bootstrap LazyVim and install plugins/LSP tools.
7. **Ghostty:** Open Ghostty after install to verify the bundled Catppuccin Mocha config and font rendering.
8. **tmux:** Start `tmux`, then press `prefix + I` (capital i) to install TPM plugins, including Catppuccin.
9. **VS Code:** Apply the settings and install recommended extensions (see below).

### Step 5: Quick Verification (Optional)

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
code --install-extension github.copilot
code --install-extension usernamehw.errorlens
code --install-extension christian-kohler.path-intellisense
code --install-extension mikestead.dotenv
```

> **Note:** The settings use `0xProto Nerd Font Mono`. Install it via: `brew install --cask font-0xproto-nerd-font`

## 🧠 Neovim Setup (LazyVim)

This repo ships a ready-to-use LazyVim config in `nvim/` and symlinks it to `~/.config/nvim` during `./install.sh`.

### Enabled language extras

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

### One-line install

```bash
git clone https://github.com/jcyrus/macos-setup.git && cd macos-setup && chmod +x install.sh && ./install.sh
```

### Notes

- LazyVim bootstraps on first run of `nvim`.
- Mason installs language servers/debug tools automatically.
- Use `:LazyExtras` to toggle additional modules.

## 📦 Customization

Edit `Brewfile` to add or remove tools before running the installer. Comment out lines with `#` to skip optional apps.

## 🤝 Contributing

Found a bug or want to add a new tool? Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
