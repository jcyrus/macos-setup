# 🍎 The Modern Mac Setup

An opinionated, "Day 1" setup script for macOS developers.

This repository automates the installation of a modern stack (Rust, Flutter, Web), CLI power tools, and essential GUI applications. It is designed to take a fresh Mac from zero to hero in under 15 minutes.

## 📦 The App Manifest

| Category        | App / Tool         | Description                                            |
| :-------------- | :----------------- | :----------------------------------------------------- |
| **🚀 Terminal** | **Warp**           | AI-Powered modern terminal with "blocks" UI.           |
|                 | **Starship**       | Minimal, blazing fast shell prompt.                    |
|                 | **Zoxide**         | Smarter `cd` that remembers your most used paths.      |
| **🛠 Core CLI** | **Eza**            | Modern replacement for `ls` with icons & git status.   |
|                 | **Bat**            | Modern replacement for `cat` with syntax highlighting. |
|                 | **Ripgrep**        | Ultra-fast text search tool (`rg`).                    |
|                 | **JQ**             | Command-line JSON processor.                           |
|                 | **GitHub CLI**     | Official GitHub tool (`gh`).                           |
| **🦀 Rust**     | **Rustup**         | Official Rust toolchain installer.                     |
|                 | **Bacon**          | Background Rust code checker (TUI).                    |
|                 | **Cargo-Binstall** | Binary installer (skips compiling).                    |
| **🌐 Web**      | **FNM**            | Fast Node Manager (Rust-based).                        |
|                 | **PNPM**           | Disk-efficient package manager.                        |
| **📱 Mobile**   | **FVM**            | Flutter Version Manager.                               |
|                 | **Scrcpy**         | Low-latency Android screen mirroring.                  |
|                 | **Cocoapods**      | Dependency manager for iOS projects.                   |
| **💻 GUI Core** | **VS Code**        | The standard code editor.                              |
|                 | **Raycast**        | Extensible launcher (Spotlight replacement).           |
|                 | **Brave**          | Privacy-focused browser.                               |
|                 | **Google Chrome**  | Google's web browser.                                  |
|                 | **OrbStack**       | Fast, lightweight Docker & Linux container manager.    |
|                 | **TablePlus**      | Native database GUI.                                   |

| | **Shottr** | Precision screenshot tool. |
| **🔒 Security** | **Bitwarden** | Open-source password manager. |
| | **Tailscale** | Zero-config VPN mesh network. |
| **🎨 Creative** | **Figma** | Interface design tool. |
| | **Darktable** | Open-source photography workflow (Lightroom alt). |
| | **ImageMagick** | CLI image manipulation tool. |
| **🍿 Lifestyle** | **IINA** | Modern media player (Swift-based). |
| | **Whisky** | Run Windows games on Mac (GPTK wrapper). |
| | **Stremio** | Video streaming aggregator. |
| | **Spotify** | Music streaming. |
| **👻 Custom** | **GhostWire** | (From jcyrus tap) |
| | **Spektr** | (From jcyrus tap) |

## ⚠️ Prerequisites

- A fresh installation of macOS.
- Xcode Command Line Tools (The script will prompt you to install them if missing).

## 🛠 Usage

### Step 1: Clone

Open your terminal and clone this repo:

```bash
git clone https://github.com/jcyrus/macos-setup.git
cd modern-mac-setup
chmod +x install.sh

```

### Step 2: Install

Run the installer. This sets up Homebrew, installs all apps, and configures Zsh/Starship.

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
5. **VS Code:** Apply the settings and install recommended extensions (see below).

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

## 📦 Customization

Edit the `Brewfile` to add or remove apps before running the installer. Comment out lines with `#` to skip them.

## 🤝 Contributing

Found a bug or want to add a new tool? Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
