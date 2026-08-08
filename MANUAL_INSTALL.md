# 🛠 Manual Installation Guide

If you prefer not to run `install.sh`, use this guide to install and configure the same setup manually.

Every step below mirrors something `install.sh` does. Run them from the repo root (`macos-setup`) unless stated otherwise, since several steps symlink files out of this directory — keep the clone somewhere permanent.

## 1. Prerequisites

Install the Xcode Command Line Tools (Homebrew and `git` both need them):

```bash
xcode-select --install
```

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

> If you would rather install everything at once, `brew bundle --file=./Brewfile` covers sections 2 and 3 in one command, taps included.

## 3. Install Tooling

### 🚀 Terminal

```bash
brew install --cask ghostty
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
brew install --cask visual-studio-code brave-browser google-chrome raycast orbstack
brew install --cask tableplus shottr bruno obsidian appcleaner the-unarchiver
```

### 🔤 Fonts

```bash
brew install --cask font-0xproto-nerd-font font-jetbrains-mono-nerd-font
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

### Oh My Zsh + Plugins

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

Back up your existing config before editing it:

```bash
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.backup
```

Add this to `~/.zshrc`:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git brew zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(fnm env --use-on-cd)"
eval "$(fzf --zsh)"

alias ls="eza --icons"
alias ll="eza -l --icons"
alias cat="bat --paging=never --plain"
alias f="fvm flutter"
alias lg="lazygit"
alias help="tldr"

export PATH="$HOME/.cargo/bin:$PATH"
```

> **Do not add `zoxide` or `fzf` to the `plugins=(...)` list.** Oh My Zsh's versions of those plugins run the same initialisation the `eval` lines above do, and loading both double-binds their keys. `zsh-syntax-highlighting` must stay last in the list.

Apply changes:

```bash
source ~/.zshrc
```

### Rust

```bash
rustup-init -y --no-modify-path
```

### Node (FNM)

```bash
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default lts-latest
```

`fnm install` alone does not make the version active in new shells — `fnm default` is what sets it.

### Flutter (FVM)

```bash
fvm install stable
fvm global stable
```

### Git (delta)

Wire `git-delta` up as the pager, which is what makes the installed diff highlighting actually apply:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
```

### tealdeer

Populate the `tldr` cache before first use:

```bash
tldr --update
```

## 5. Config Symlinks

The installer symlinks four configs out of this repo. Do the same manually, backing up anything already there.

### Neovim (LazyVim)

```bash
mkdir -p ~/.config
[ -e ~/.config/nvim ] && [ ! -L ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup.$(date +%s)
ln -sfn "$(pwd)/nvim" ~/.config/nvim
```

If you moved an existing Neovim config aside, also move its state directories so old plugin data does not leak in:

```bash
for d in ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
  [ -d "$d" ] && mv "$d" "$d.backup.$(date +%s)"
done
```

Run Neovim once to bootstrap plugins:

```bash
nvim
```

The language extras (Rust, Dart, Tailwind, TypeScript, TOML, Git) are already declared in `nvim/lua/config/lazy.lua`, so there is nothing to enable via `:LazyExtras` — they install on first launch.

### Ghostty

```bash
[ -e ~/.config/ghostty ] && [ ! -L ~/.config/ghostty ] && mv ~/.config/ghostty ~/.config/ghostty.backup.$(date +%s)
ln -sfn "$(pwd)/ghostty" ~/.config/ghostty
```

### Starship

```bash
[ -e ~/.config/starship.toml ] && [ ! -L ~/.config/starship.toml ] && mv ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%s)
ln -sfn "$(pwd)/starship/starship.toml" ~/.config/starship.toml
```

Without this the prompt falls back to Starship's default — the `starship init` line alone does not pick up this repo's theme.

### tmux + TPM

```bash
ln -sfn "$(pwd)/tmux/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Open tmux and press `prefix + I` (capital i) to install plugins.

The config uses the Catppuccin v2 `@catppuccin_status_*` interface and pins the plugin to `v2.1.3`, so TPM clones that tag. To install it up front instead:

```bash
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.tmux/plugins/tmux
```

## 6. VS Code

Apply the bundled settings and extensions — see [README.md](README.md#-vs-code-setup) for the full list:

```bash
cp vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

## 7. Quick Verification (Optional)

Use the canonical verification commands in [README.md](README.md#step-6-quick-verification-optional) to validate this manual setup.

Quick smoke test:

```bash
git --version && nvim --version | head -n 1 && tmux -V && ollama --version && node --version
```

## 8. Keeping It Updated

`update.sh` upgrades Homebrew packages, re-applies the Brewfile, refreshes the Rust and Node toolchains, syncs Neovim plugins, and updates the `tldr` cache:

```bash
./update.sh
```

## 9. Optional Extras

```bash
brew install --cask iterm2 discord slack zoom postman vlc font-fira-code warp
```
