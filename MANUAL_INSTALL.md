# 🛠 Manual Installation Guide

If you prefer not to run `install.sh`, use this guide to install and configure the same setup manually.

## 1. Prerequisites

Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add Homebrew to your shell on Apple Silicon:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## 2. Add Required Taps

```bash
brew tap leoafarias/fvm
brew tap jcyrus/homebrew-tap
```

## 3. Install Tooling

### 🚀 Terminal

```bash
brew install starship zoxide tmux
```

### 🛠 Core CLI

```bash
brew install git gh eza bat ripgrep fd fzf jq tealdeer mas
```

### ⚡ Modern CLI

```bash
brew install git-delta dust duf procs btop hyperfine tokei yazi tree-sitter
```

### 🤖 AI / LLM

```bash
brew install ollama
```

### 🧠 Editors + Git TUIs

```bash
brew install neovim lazygit lazydocker
```

### 🦀 Rust + 🌐 Web + 📱 Mobile

```bash
brew install rustup-init bacon cargo-binstall
brew install fnm pnpm leoafarias/fvm/fvm cocoapods scrcpy
```

### 💻 GUI Apps

```bash
brew install --cask warp visual-studio-code brave-browser google-chrome raycast orbstack
brew install --cask tableplus shottr bruno obsidian appcleaner the-unarchiver
```

### 🔤 Fonts

```bash
brew install --cask font-fira-code font-jetbrains-mono font-0xproto-nerd-font
```

### 🔒 Security

```bash
brew install --cask bitwarden tailscale
```

### 🎨 Creative + 🍿 Lifestyle + 👻 Custom

```bash
brew install --cask figma darktable telegram spotify iina stremio whisky
brew install imagemagick
brew install --cask ghostwire spektr
```

## 4. Shell and Language Setup

### Rust

```bash
rustup-init -y --no-modify-path
```

### Node (FNM)

```bash
eval "$(fnm env --use-on-cd)"
fnm install --lts
```

### Flutter (FVM)

```bash
fvm install stable
fvm global stable
```

### Oh My Zsh + Plugins

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

Add this to `~/.zshrc`:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git zoxide brew zsh-autosuggestions zsh-syntax-highlighting fzf)
source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fnm env --use-on-cd)"

if [ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]; then
   source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
fi
if [ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ]; then
   source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
fi

alias ls="eza --icons"
alias ll="eza -l --icons"
alias cat="bat"
alias f="fvm flutter"
alias lg="lazygit"
alias help="tldr"

export PATH="$HOME/.cargo/bin:$PATH"
```

Apply changes:

```bash
source ~/.zshrc
```

## 5. Neovim (LazyVim)

From the repo root (`macos-setup`), symlink the included Neovim config:

```bash
mkdir -p ~/.config
ln -sfn "$(pwd)/nvim" ~/.config/nvim
```

Run Neovim once to bootstrap plugins:

```bash
nvim
```

Then enable extras via `:LazyExtras`:

- `lang.rust`
- `lang.dart`
- `lang.tailwind`
- `lang.typescript`
- `lang.toml`
- `lang.git`

## 6. tmux + TPM

Symlink the included tmux config and install TPM:

```bash
ln -sfn "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Open tmux and press `prefix + I` to install plugins.

## 7. Quick Verification (Optional)

Use the canonical verification commands in [README.md](README.md#step-5-quick-verification-optional) to validate this manual setup.

Quick smoke test:

```bash
git --version && nvim --version | head -n 1 && tmux -V && ollama --version
```

## 8. Optional Extras

```bash
brew install --cask iterm2 discord slack zoom postman vlc
```
