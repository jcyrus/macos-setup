# 🍎 The Modern Mac Setup

An opinionated, "Day 1" setup script for macOS developers. 

This repository automates the installation of a modern stack (Rust, Flutter, Web), CLI power tools, and essential GUI applications. It is designed to take a fresh Mac from zero to hero in under 15 minutes.

## 🚀 The Stack
* **Terminal:** Warp + Starship + Zoxide
* **Shell:** Zsh + Oh My Zsh (Plugin Manager)
* **Core CLI:** Bat, Eza, Ripgrep, JQ, GitHub CLI
* **Languages:** Rust (Rustup), Node (FNM), Flutter (FVM)
* **Browsing:** Brave (Privacy & Speed)
* **Security:** Bitwarden + Mullvad VPN
* **Creativity:** Figma, Darktable, VS Code

## ⚠️ Prerequisites
* A fresh installation of macOS.
* Xcode Command Line Tools (The script will prompt you to install them if missing).

## 🛠 Usage

### Step 1: Clone (or Download)
Open your terminal and clone this repo (or download the ZIP):
```bash
git clone https://github.com/jcyrus/macos-setup.git
cd macos-setup
chmod +x install.sh

```

### Step 2: The Install

This script installs Homebrew, bundles all applications, and generates a fresh shell configuration.

```bash
./install.sh

```

### Step 3: Post-Install Manual Steps

1. **Warp:** Open Warp and sign in.
2. **App Store:** Open the Mac App Store and sign in to auto-install any `mas` apps.
3. **Raycast:** Open Raycast (`Alt+Space` recommended) and set up extensions.
4. **Brave:** Set as default browser.

## 📦 Customization

Edit the `Brewfile` to add or remove apps before running the installer. Comment out lines with `#` to skip them.