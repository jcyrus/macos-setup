# 🍎 The Modern Mac Setup

An opinionated, "Day 1" setup script for macOS developers. 

This repository automates the installation of a modern stack (Rust, Flutter, Web), CLI power tools, and essential GUI applications. It is designed to take a fresh Mac from zero to hero in under 15 minutes.

## 📦 The App Manifest

| Category | App / Tool | Description |
| :--- | :--- | :--- |
| **🚀 Terminal** | **Warp** | AI-Powered modern terminal with "blocks" UI. |
| | **Starship** | Minimal, blazing fast shell prompt. |
| | **Zoxide** | Smarter `cd` that remembers your most used paths. |
| **🛠 Core CLI** | **Eza** | Modern replacement for `ls` with icons & git status. |
| | **Bat** | Modern replacement for `cat` with syntax highlighting. |
| | **Ripgrep** | Ultra-fast text search tool (`rg`). |
| | **JQ** | Command-line JSON processor. |
| | **GitHub CLI** | Official GitHub tool (`gh`). |
| **🦀 Rust** | **Rustup** | Official Rust toolchain installer. |
| | **Bacon** | Background Rust code checker (TUI). |
| | **Cargo-Binstall** | Binary installer (skips compiling). |
| **🌐 Web** | **FNM** | Fast Node Manager (Rust-based). |
| | **PNPM** | Disk-efficient package manager. |
| **📱 Mobile** | **FVM** | Flutter Version Manager. |
| | **Scrcpy** | Low-latency Android screen mirroring. |
| | **Cocoapods** | Dependency manager for iOS projects. |
| **💻 GUI Core** | **VS Code** | The standard code editor. |
| | **Raycast** | Extensible launcher (Spotlight replacement). |
| | **Brave** | Privacy-focused browser. |
| | **Google Chrome** | Google's web browser. |
| | **Docker** | Containerization platform. |
| | **TablePlus** | Native database GUI. |
| | **Rectangle** | Window snapping manager. |
| | **Shottr** | Precision screenshot tool. |
| **🔒 Security** | **Bitwarden** | Open-source password manager. |
| | **Mullvad** | Privacy-focused VPN (No email required). |
| **🎨 Creative** | **Figma** | Interface design tool. |
| | **Darktable** | Open-source photography workflow (Lightroom alt). |
| | **ImageMagick** | CLI image manipulation tool. |
| **🍿 Lifestyle** | **IINA** | Modern media player (Swift-based). |
| | **Whisky** | Run Windows games on Mac (GPTK wrapper). |
| | **Stremio** | Video streaming aggregator. |
| | **Spotify** | Music streaming. |

## ⚠️ Prerequisites
* A fresh installation of macOS.
* Xcode Command Line Tools (The script will prompt you to install them if missing).

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

### Step 3: Post-Install Steps

1. **Warp:** Open Warp and sign in.
2. **App Store:** Open the Mac App Store and sign in to auto-install `mas` apps.
3. **Raycast:** Open Raycast (`Alt+Space`) and install extensions.
4. **Flutter:** Run `fvm install stable` to get the latest SDK.

## 📦 Customization

Edit the `Brewfile` to add or remove apps before running the installer. Comment out lines with `#` to skip them.