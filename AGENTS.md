# 🤖 AI Agent Operating Instructions for `macos-setup`

This file provides autonomous execution rules, troubleshooting playbooks, and verification protocols for AI Coding Agents (such as Cursor, Antigravity, Claude Code, Windsurf, Copilot, etc.) operating in this repository.

---

## 🎯 Primary Objective

When asked by a user to "run the setup", "install everything", "monitor the setup and fix issues", or "verify the installation", you must autonomously:
1. Execute `./install.sh --unattended` (or specify `--preset=<name> -y`) and monitor the output stream.
2. Automatically fix non-interactive errors (Brewfile retries, PATH activation, missing symlinks).
3. Run `./doctor.sh` to perform a manifest-aware health check.
4. Auto-remediate any warnings/failures reported by `doctor.sh`.
5. Repeat verification until `./doctor.sh` exits cleanly with `0 failures`.
6. Provide a concise report of actions taken and remaining human GUI steps.

---

## 📋 Standard Operating Procedure (SOP)

### Step 1: Pre-flight Checks
Before running scripts, verify the host environment:
1. **OS Check**: Confirm operating system is macOS (`uname -s` outputs `Darwin`).
2. **Xcode Command Line Tools**: Run `xcode-select -p &>/dev/null`. If non-zero, note that `./install.sh` will initiate `xcode-select --install` which triggers a macOS system GUI popup.
3. **Working Directory**: Ensure you are in the repository root directory (`macos-setup`).

### Step 2: Installation Execution & Real-Time Monitoring
Run the unattended installer in the terminal and monitor stdout/stderr in real-time:

```bash
./install.sh --unattended
# or with a specific profile:
# ./install.sh --preset=minimalist --unattended
```

#### Auto-Remediation Playbook

| Issue / Failure | Root Cause | Automated Remediation Action |
| :--- | :--- | :--- |
| **Xcode CLT Prompt (`xcode-select: note: install requested...`)** | `xcode-select --install` launched an Apple GUI installer popup requiring user click. | Pause execution and inform user: *"Xcode Command Line Tools installation dialog opened. Please complete the installer dialog on your screen, then let me know to resume."* |
| **`brew: command not found` after install** | Homebrew binary path not evaluated in subshell on Apple Silicon (`/opt/homebrew/bin`). | Execute `eval "$(/opt/homebrew/bin/brew shellenv)"` in shell session before proceeding. |
| **`brew bundle` Partial Failure (`Some Brewfile entries failed...`)** | Network timeout, formula/cask conflict, broken download URL, or missing tap. | 1. Run `brew update`.<br>2. Parse failed entries from `install.sh` log.<br>3. Retry individual failures: `brew install <formula>` or `brew install --cask <cask>`.<br>4. Re-run `brew bundle --file=~/.config/macos-setup/Brewfile.generated`. |
| **Rust / Cargo binaries missing in current session** | `rustup` installed via Homebrew puts shims in `~/.cargo/bin` and `/opt/homebrew/opt/rustup/bin`. | Add paths to current shell session:<br>`export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"` |
| **Node / `fnm` unavailable** | `fnm` environment not evaluated in subshell. | Run `eval "$(fnm env)" && fnm install --lts && fnm default lts-latest`. |
| **Docker CLI missing with OrbStack** | `/Applications/OrbStack.app` installed but `docker` binary symlink missing. | Run `ln -sfn /Applications/OrbStack.app/Contents/MacOS/xbin/docker /opt/homebrew/bin/docker`. |
| **`tldr` cache update failed** | Network error updating tealdeer cache. | Non-fatal. Run `tldr --update` manually if network is available. |

---

### Step 3: Health Verification & Repair (`./doctor.sh`)
After `./install.sh` finishes (or when verifying setup state), run the read-only health check:

```bash
./doctor.sh
```

Inspect the output line-by-line for `warn` and `FAIL` indicators. `doctor.sh` reads `~/.config/macos-setup/config.toml` and evaluates only the components configured for this machine.

#### Doctor Issue Auto-Fix Rules

1. **Dangling Symlinks / Missing Configs (`FAIL: dangling symlink -> ...` or `missing`)**:
   - Cause: Target directory/file missing or moved.
   - Fix: Re-create symlinks pointing to repository source files or re-render templates via `./install.sh --unattended`.

2. **Missing Shell Init (`FAIL: <tool> init absent from .zshrc`)**:
   - Cause: Tool initialization line missing from `~/.zshrc`.
   - Fix: Append missing tool block (`eval "$(starship init zsh)"`, `eval "$(zoxide init zsh)"`, `eval "$(fnm env --use-on-cd)"`, `eval "$(fzf --zsh)"`) to `~/.zshrc`.

3. **Missing Oh My Zsh Plugins (`FAIL: <plugin> missing`)**:
   - Cause: Zsh autosuggestions or syntax highlighting repository not cloned.
   - Fix: Clone missing plugin into `$HOME/.oh-my-zsh/custom/plugins/<plugin>`.

4. **VS Code Settings Unapplied (`warn: settings.json real file, differs...` or `missing`)**:
   - Fix: Re-render template to `$HOME/Library/Application Support/Code/User/settings.json`.

5. **JankyBorders Service Stopped (`warn: borders service not started`)**:
   - Fix: Run `brew services start borders`.

After applying fixes, **re-run `./doctor.sh`** until exit status is `0` with `0 failures`.

---

### Step 4: Final Hand-Off Report
Present a summary to the user:
- **Status**: Setup completed & verified via `./doctor.sh`.
- **Active Profile**: Report the installed preset/profile.
- **Auto-Fixed Issues**: List any errors encountered and resolved during installation or doctor check.
- **Manual GUI Steps Remaining** (Prompt user to perform these non-scriptable actions):
  1. **Ghostty**: Open app to inspect Catppuccin theme & coding font.
  2. **tmux**: Open terminal, start `tmux`, press `prefix + I` (`Ctrl+a` then `Shift+i`) to install TPM plugins.
  3. **Raycast**: Open Raycast (`Option+Space` or `Cmd+Space`) and grant initial macOS permissions.
  4. **AeroSpace**: Open System Settings → Privacy & Security → Accessibility and ensure AeroSpace is enabled (if enabled in profile).
  5. **Ollama**: Run `ollama pull llama3.2` to download initial LLM model (if AI tools enabled).
  6. **Neovim**: Run `nvim` once to let LazyVim bootstrap plugins & LSPs.
