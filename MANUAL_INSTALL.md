# 🛠 Manual Installation Guide

If you prefer not to run the automated `install.sh` script, you can install everything manually using the commands below.

## 1. Prerequisites

First, you need to install **Homebrew**, the package manager for macOS. Open your terminal and run:

```bash
/bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))"

```

Once installed, add it to your PATH (if you are on an M1/M2/M3 Mac):

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"

```

## 2. Add Essential Repositories (Taps)

Some tools require custom repositories.

```bash
brew tap leoafarias/fvm   # For Flutter Version Management
brew tap jcyrus/homebrew-tap # Custom Apps

```

## 3. The Installation Blocks

Copy and run the blocks for the tools you want.

### 🚀 Core CLI Tools (Essentials)

_Modern replacements for standard unix tools._

```bash
brew install git gh zoxide eza bat ripgrep jq starship mas

```

### 🦀 Rust Stack

_The complete Rust toolchain._

```bash
brew install rustup-init bacon cargo-binstall

```

### 🌐 Web & Mobile Stack

_Node.js (FNM), Flutter (FVM), and Mobile utils._

```bash
brew install fnm pnpm cocoapods scrcpy
brew install leoafarias/fvm/fvm

```

### 💻 GUI Applications (The Core)

_The essential "Day 1" apps._

```bash
brew install --cask warp visual-studio-code brave-browser google-chrome raycast orbstack
brew install --cask tableplus shottr appcleaner the-unarchiver
brew install --cask font-fira-code font-jetbrains-mono

```

### 🔒 Security & Privacy

```bash
brew install --cask bitwarden tailscale

```

### 🎨 Creative & Lifestyle (Optional)

```bash
brew install --cask figma darktable telegram spotify iina stremio whisky
brew install --cask ghostwire spektr
brew install imagemagick

```

---

## 4. Configuration (Crucial)

Installing the tools is only half the battle. You need to hook them up to your shell to make them work.

### Step A: Setup Rust

Run the initializer to set up the toolchain.

```bash
rustup-init -y

```

### Step B: Setup Node.js (FNM)

Initialize FNM and install the latest Node version.

```bash
# Add this to your shell config later, but for now run:
eval "$(fnm env --use-on-cd)"
fnm install --lts

```

### Step C: Setup Flutter (FVM)

Install the stable version of Flutter.

```bash
fvm install stable
fvm global stable

```

### Step D: Configure Zsh & Starship

To get the fancy prompt and smart commands, you need to edit your shell config.

1. **Install Oh My Zsh (Optional but recommended):**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. **Edit your `.zshrc`:**
   Open `~/.zshrc` and add these lines to the bottom:

```bash
# --- Homebrew Path ---
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- Tool Initializations ---
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fnm env --use-on-cd)"

# --- Aliases ---
alias ls="eza --icons"
alias cat="bat"
alias f="fvm flutter"

# --- Path Additions ---
export PATH="$HOME/.cargo/bin:$PATH"

```

3. **Apply Changes:**

```bash
source ~/.zshrc

```
