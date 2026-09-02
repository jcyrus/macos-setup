# 📋 macos-setup TUI & Customizer Roadmap

This document tracks the tasks and milestones for transforming `macos-setup` into an interactive, modular TUI installer.

---

## 🎯 Tasks & Completion Status

### Phase 1: Architecture & Data Foundations
- [x] **1.1 Presets Engine**: Create baseline configuration profiles in `presets/` (`full.toml`, `minimalist.toml`, `web.toml`, `rust.toml`, `mobile.toml`).
- [x] **1.2 Template Engine**: Create dotfile templates in `templates/` with configurable parameters for themes, fonts, opacity, AeroSpace gaps, modifier keys, and git info.
- [x] **1.3 Package & Manifest Metadata**: Define structured package categories and dependencies for dynamic Brewfile generation.

### Phase 2: Modular Engine Libraries (`lib/`)
- [x] **2.1 `lib/common.sh`**: Core utilities, ANSI color palettes, logging helpers, terminal dimension detection, and system validation.
- [x] **2.2 `lib/config.sh`**: Configuration manager (read/write `~/.config/macos-setup/config.toml`, parse presets, compile templates).
- [x] **2.3 `lib/brew.sh`**: Dynamic Brewfile generator that filters taps, casks, and formulae based on active user selection.
- [x] **2.4 `lib/dotfiles.sh`**: Modular dotfile applicator that renders customized templates or symlinks based on user config.
- [x] **2.5 `lib/toolchains.sh`**: Modular toolchain installers (Rust, Node/FNM, Flutter/FVM, Ollama, JankyBorders).
- [x] **2.6 `lib/macos.sh`**: Modular macOS defaults applicator based on user preference flags.

### Phase 3: Interactive TUI Engine (`lib/ui.sh`)
- [x] **3.1 TUI Core Navigation**: ANSI terminal engine with keyboard controls (arrow keys `↑`/`↓`, `Space` toggle, `Tab` focus, `Enter` confirm, `q` quit).
- [x] **3.2 Screen: Preset Selector**: Quick-start profile picker with side preview cards.
- [x] **3.3 Screen: Category & Package Matrix**: Multi-select checklist allowing granular toggling of categories and specific apps.
- [x] **3.4 Screen: Machine Customizer Form**: Interactive inputs for Git identity, themes (Catppuccin Mocha/Latte/Nord/Tokyo Night), fonts (0xProto/JetBrains Mono), AeroSpace modifier keys & gaps, and macOS defaults.
- [x] **3.5 Screen: Summary & Confirmation**: Pre-installation summary with dry-run and save profile options.

### Phase 4: CLI & Installer Orchestration (`install.sh`)
- [x] **4.1 CLI Argument Parser**: Support `--unattended`, `-y`, `--preset=<name>`, `--config=<path>`, `--dry-run`, and `--help`.
- [x] **4.2 TTY Auto-Detection**: Automatically launch interactive TUI when running in a terminal, or fall back to unattended mode in non-interactive/agent environments.
- [x] **4.3 Modular Execution Pipeline**: Clean orchestration with step-by-step progress logging.

### Phase 5: Verification & Subsystems Update
- [x] **5.1 Manifest-Aware `doctor.sh`**: Update health checks to read `~/.config/macos-setup/config.toml` and evaluate only active components.
- [x] **5.2 Config-Aware `update.sh`**: Update packages according to user-selected profile.
- [x] **5.3 Documentation & Agents Guide**: Update `README.md` and `AGENTS.md` with new flags and TUI usage instructions.
- [x] **5.4 Lint & Test**: Verify with `shellcheck` and `shfmt`.
