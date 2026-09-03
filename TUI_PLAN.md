# TUI Migration Plan — `macsetup`

> [!IMPORTANT]
> **Status as of 2026-09-03: partially superseded. Read this as a design record,
> not as a description of the code.**
>
> The *interaction model* below shipped, but in Bash rather than Rust — see
> `lib/ui.sh` (wizard), `presets/*.toml` (profiles) and
> `~/.config/macos-setup/config.toml` (the saved profile). What did **not** ship
> is the architecture underneath it: there is no Rust engine, no `manifest/`
> directory, and no generation step. The Brewfile, the README app table,
> `MANUAL_INSTALL.md` and `lib/brew.sh` are still maintained by hand, in
> parallel.
>
> That means §1's diagnosis — the same data typed three times, drifting — is
> still live, and it is not theoretical. On 2026-09-03 a drift between
> `starship/starship.toml` and `templates/starship.toml.tmpl` shipped a template
> that did not parse as TOML, so every `install.sh` run silently replaced the
> Starship powerline with the stock prompt. Phase 0 below ("prove `gen`
> regenerates the Brewfile byte-identically") is the part of this plan that
> would have caught it, and it remains unstarted.
>
> Phases 1–5 are unstarted. Nothing here is committed to; the Rust/ratatui
> direction in particular predates the Bash wizard and should be re-argued
> before anyone acts on it.

Turning this repo from an all-or-nothing bash installer into a selective,
Ninite-style TUI for macOS: pick your packages *and* the configs that go with
them, install only those, and keep a machine reproducible from a saved profile.

**Decisions locked in:** Rust + ratatui · selectable packages, configs, and
macOS defaults · presets · headless path preserved via a profile lockfile ·
`install.sh` remains the day-1 bootstrap.

---

## 1. The problem with the current shape

| Today | Why it blocks selective install |
| :--- | :--- |
| `Brewfile` is a flat list with comment headers | No machine-readable categories, descriptions, or dependencies |
| App descriptions live in the README table | Same data typed twice, drifts, unusable at runtime |
| `MANUAL_INSTALL.md` restates every step | Typed a third time |
| Configs are hardcoded in `install.sh` (§5–§8) | Cannot be attached to, or detached from, a package choice |
| `.zshrc` gets one big append-once heredoc | Deselecting a tool can never remove its alias |
| `doctor.sh` checks the full setup | Screams about tools you deliberately never installed |
| `update.sh` runs `brew bundle` on everything | Reinstalls what you opted out of |

The fix is one idea applied everywhere: **a declarative manifest becomes the
single source of truth**, and every artifact (Brewfile, README table, manual
docs, installer actions, doctor checks) is derived from it.

---

## 2. Target architecture

```
macos-setup/
├── install.sh                # ~40-line bootstrap: CLT → Homebrew → macsetup → exec
├── manifest/
│   ├── schema.toml           # schema version + category ordering
│   ├── terminal.toml         # package definitions, per category
│   ├── core-cli.toml
│   ├── …
│   ├── configs.toml          # config modules (symlinks, zsh fragments, clones)
│   └── macos.toml            # macOS defaults, grouped into toggles
├── profiles/
│   ├── minimal.toml  full.toml  web.toml  rust.toml  mobile.toml  design.toml
├── crates/macsetup/          # the Rust engine + TUI
├── nvim/ ghostty/ starship/ tmux/ vscode/   # unchanged — symlink targets
├── Brewfile                  # GENERATED (kept for `brew bundle` compatibility)
├── README.md                 # app table section GENERATED
└── MANUAL_INSTALL.md         # GENERATED
```

**Engine and content ship together in this repo.** The manifest schema and the
engine version must agree, and — critically — the symlinks point into the
checkout, so the clone has to persist anyway. The binary resolves its content
root in this order: `--repo` flag → `MACSETUP_REPO` env → the directory it was
invoked from, if it looks like the repo → `~/.local/share/macos-setup`
(auto-cloned as a last resort).

---

## 3. The manifest

### Packages — `manifest/terminal.toml`

```toml
category = "Terminal"
icon = "🚀"
order = 10

[[package]]
id       = "ghostty"
name     = "Ghostty"
kind     = "cask"                 # brew | cask | mas | tap
formula  = "ghostty"
desc     = "GPU-accelerated terminal with Catppuccin config."
tags     = ["recommended", "terminal"]
configs  = ["ghostty-dotfiles"]   # offered when this package is selected
requires = ["font-0xproto-nerd-font"]
```

Fields that earn their place:

- `requires` — hard edges. Selecting a package auto-selects its requirements
  and the TUI shows `+2 required` rather than silently installing extras.
- `suggests` — soft edges, surfaced as a hint, never auto-checked.
- `configs` — the config modules this package unlocks.
- `size_mb` (optional) — feeds the "~3.1 GB" footer estimate.

The dependency edges are not hypothetical. Real ones in this repo today:

```
eza,bat,fzf,zoxide,fnm  →  the .zshrc alias/init block
git-delta               →  the delta git config
fvm                     →  the `f` alias
ghostty config          →  font-0xproto-nerd-font, Catppuccin theme
vscode settings         →  font-0xproto-nerd-font
tmux config             →  tmux, tpm, catppuccin/tmux @ v2.1.3 (pinned)
nvim (LazyVim)          →  ripgrep, fd, tree-sitter, a Nerd Font
lazydocker              →  orbstack (soft)
```

### Config modules — `manifest/configs.toml`

Seven action kinds cover everything `install.sh` does today:

| Kind | Covers |
| :--- | :--- |
| `symlink` | nvim, ghostty, starship.toml, `.tmux.conf` (+ timestamped backup) |
| `zsh_fragment` | one named block inside the managed `.zshrc` region |
| `git_config` | the delta / diff / merge settings |
| `clone` | oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, tpm, catppuccin-tmux |
| `copy` | VS Code `settings.json` |
| `command` | `rustup default stable`, `fnm install --lts`, `brew services start ollama`, `tldr --update`, `lefthook install` |
| `defaults` | macOS `defaults write` (see §5) |

```toml
[[config]]
id      = "ghostty-dotfiles"
name    = "Ghostty config (Catppuccin Mocha + 0xProto)"
kind    = "symlink"
source  = "ghostty"
target  = "~/.config/ghostty"
backup  = true
default = true            # pre-checked when its package is selected
```

The nvim module keeps its special case as an explicit field
(`purge_state_dirs = ["~/.local/share/nvim", "~/.local/state/nvim", "~/.cache/nvim"]`),
so the migration behaviour that exists in `install.sh:158-164` survives the port.

---

## 4. The `.zshrc` rewrite — the hard part

This is the change that actually makes deselection work, and it deserves to be
treated as its own piece of work.

**Today:** append-once, guarded by `grep -q "# --- MacOS Setup Tools ---"`. Every
alias for every tool lands in one block. Deselect `bat` and you still get
`alias cat="bat …"` — a broken shell.

**Target:** a single managed region, regenerated in full on every run.

```zsh
# >>> macos-setup managed — do not edit, regenerated by `macsetup` >>>
eval "$(/opt/homebrew/bin/brew shellenv)"
…fragments, in dependency order, only for selected packages…
# <<< macos-setup managed <<<
```

Rules:

1. Everything outside the markers is never read, never touched.
2. The region is rebuilt from the selection each run → deselecting removes the
   fragment. This is what makes re-running on a configured machine safe.
3. Fragment order is explicit (`order` field): brew shellenv first, oh-my-zsh
   before anything binding keys, `zsh-syntax-highlighting` strictly last.
4. Before the first managed write, back up `.zshrc` to
   `~/.config/macos-setup/backups/<timestamp>/.zshrc`.
5. If a pre-existing `plugins=(…)` line is found outside the region, keep the
   current behaviour: warn, change nothing, print what to add.

The existing "don't load zoxide/fzf as OMZ plugins, they're initialised
directly" comment (`install.sh:81-83`) becomes a constraint the fragment
ordering enforces, and `doctor` gains a check for the double-init it prevents.

---

## 5. macOS defaults as toggles

`macos.sh`'s `d <domain> <key> <type> <value> <note>` calls port almost
mechanically into `manifest/macos.toml`, grouped into the sections that already
exist in the file:

```toml
[[group]]
id   = "keyboard"
name = "Keyboard & input"
desc = "Fast key repeat, no accent popup, no smart quotes."
note = "LazyVim, tmux vi-mode and vim pane bindings all depend on key repeat."

  [[group.setting]]
  domain = "NSGlobalDomain"
  key    = "ApplePressAndHoldEnabled"
  type   = "bool"
  value  = false
  note   = "hold key repeats, no accent popup"
```

Non-negotiable carry-overs:

- `defaults export` backup per domain before any write, and `--restore <dir>`.
- `--dry-run`.
- The Shottr sandboxing explanation and the deliberate
  `NSDocumentSaveNewDocumentsToCloud` omission survive as `note` fields —
  those comments are the most valuable content in `macos.sh` and must not be
  lost in the port.
- Groups whose app isn't installed (Shottr) are shown disabled with the reason.

---

## 6. The profile lockfile

`~/.config/macos-setup/profile.toml`, written on every successful run:

```toml
schema     = 1
generated  = "2026-08-17T10:04:00Z"
preset     = "custom"          # or the preset id it was derived from
packages   = ["ghostty", "starship", "zoxide", "tmux", …]
configs    = ["ghostty-dotfiles", "zsh-init-starship", "zsh-alias-eza", …]
macos      = ["keyboard", "finder", "screenshots"]
```

This one file makes everything else fall into place:

- `macsetup install --profile ~/.../profile.toml --yes` — headless replay on a
  new machine, and the path `AGENTS.md` automation uses.
- `macsetup doctor` checks **only what the profile claims**, which eliminates
  the false-failure class doctor would otherwise develop.
- `macsetup update` upgrades only selected packages and re-applies their config.
- `macsetup profile diff` — what's on this machine vs. what the profile says.
- Committable: drop it in `profiles/` and it becomes a shareable preset.

Presets in `profiles/` are the same format, hand-curated, used as pre-checked
starting points (`minimal`, `full`, `web`, `rust`, `mobile`, `design`).

---

## 7. CLI surface

```
macsetup                          # TUI (default; refuses to run on a non-TTY)
macsetup install [--profile P] [--preset web] [--yes] [--dry-run]
macsetup update  [--prune]
macsetup doctor  [--fix]
macsetup profile show | save | diff
macsetup gen                      # regenerate Brewfile, README table, MANUAL_INSTALL
macsetup search <query>
```

`--dry-run` prints the resolved plan — packages, configs, defaults, in order —
and writes nothing. It's the review mechanism for anything scripted.

---

## 8. TUI design

```
┌ macsetup ─────────────────────────────────────────────┐
│ [Packages] Configs  macOS  Review                     │
├────────────┬──────────────────────────────────────────┤
│ Terminal ▸ │ Terminal                          [4/4]  │
│ Core CLI   │ [x] ghostty    GPU-accelerated terminal  │
│ Modern CLI │ [x] starship   minimal shell prompt      │
│ Editors    │ [x] zoxide     smarter cd  · installed   │
│ Git TUIs   │ [ ] tmux       terminal multiplexer      │
│ Stacks     │                                          │
│ GUI Apps   │ ── ghostty ──────────────────────────────│
│ Fonts      │ cask · 120 MB · requires 0xProto Nerd    │
│ Security   │ configs: [x] Catppuccin + 0xProto config │
├────────────┴──────────────────────────────────────────┤
│ 42 selected · ~3.1 GB · space toggle · / filter · ? help│
└───────────────────────────────────────────────────────┘
```

- **Startup state reflects reality.** Run `brew list --formula -1` and
  `brew list --cask -1` once at launch, pre-check what's installed, and label it
  `· installed`. Unchecking means *leave alone*, never *uninstall* (see §11).
- **Keys:** `space` toggle · `a`/`A` all-in-category / none · `/` fuzzy filter
  (`nucleo-matcher`) · `p` preset picker · `tab` switch pane · `enter` review ·
  `q` quit.
- **Review screen** lists exactly what will happen, grouped by phase, before any
  action — the same output as `--dry-run`.
- **Install screen** streams per-item progress: a status list on top
  (`✓ ghostty  ⠋ neovim  · tmux (queued)`) and a scrolling log pane below.
  Failures are collected, non-fatal, and reprinted at the end — matching the
  current `BUNDLE_FAILED` behaviour.

**Execution model:** don't shell out to `brew bundle` — it gives no per-item
progress. Run `brew install [--cask] <formula>` per item in a worker thread,
stream stdout over an `mpsc` channel into the render loop.

**Crates:** `ratatui`, `crossterm`, `serde`/`toml`, `clap`, `nucleo-matcher`,
`anyhow`, `dirs`, `duct` or `std::process` for streaming.

---

## 9. Delivery phases

Each phase ends somewhere shippable. Nothing below requires the next phase to
be useful.

**Phase 0 — Manifest extraction, zero behaviour change.**
Write the manifest TOMLs by mining the Brewfile, the README table (descriptions
are already written — don't retype them), and `install.sh`. Build `gen` and
prove it regenerates the current `Brewfile` **byte-identically** (`git diff`
must be empty). This de-risks every later phase and is independently valuable:
it kills the three-way duplication today.

**Phase 1 — Rust engine, headless only.**
`clap` CLI, manifest parsing + validation, `macsetup gen`, and
`macsetup install --preset full --yes` reproducing today's `install.sh` exactly.
Acceptance: on a clean UTM VM (already in your Brewfile), the headless full run
followed by the existing `doctor.sh` passes with 0 failures.

**Phase 2 — Config engine.**
The seven action kinds, and the `.zshrc` managed-region rewrite (§4). Hardest
correctness work in the project; it's what makes partial selection real.
Acceptance: select → deselect → re-run leaves a clean `.zshrc` with no orphans.

**Phase 3 — The TUI.**
Layered on phases 1–2, which already expose the full model. Purely a
presentation layer; if it's ever broken, `--preset`/`--profile` still works.

**Phase 4 — macOS defaults + profile-aware doctor + update.**
Port `macos.sh` into `manifest/macos.toml` with backup/restore/dry-run intact.
Rewrite doctor to read the profile. Add `update --prune` behind a confirmation.

**Phase 5 — Distribution and docs.**
`cargo-dist` release pipeline → `jcyrus/tap/macsetup` formula. `install.sh`
shrinks to a bootstrap. Rewrite README, `MANUAL_INSTALL.md` (generated), and
`AGENTS.md` (the auto-remediation playbook needs new failure modes and the
`--profile` replay path). Tag `v2.0.0`.

---

## 10. Bootstrap on a fresh Mac

`install.sh` keeps its name and its one-line `curl`/clone invocation — muscle
memory and every existing README/AGENTS link stay valid. It shrinks to:

```bash
1. Xcode CLT check          (unchanged)
2. Homebrew install/update  (unchanged)
3. brew install jcyrus/tap/macsetup
   └─ fallback: cargo-dist shell installer pulling a prebuilt
      darwin tarball from GitHub Releases, if the tap is unreachable
4. exec macsetup --repo "$REPO_DIR" "$@"
```

**Never compile from source on day 1** — `rustup` is itself a package this repo
manages, so a source build is a circular dependency and a 10-minute detour.
Ship prebuilt bottles. Build both `aarch64` and `x86_64` targets even though
everything here hardcodes `/opt/homebrew`; the extra target is nearly free in
`cargo-dist`, and add an explicit Apple-Silicon guard with a clear message
rather than letting an Intel Mac fail deep inside a path assumption.

---

## 11. Risks and explicit non-goals

1. **Uninstall is not in scope for v2.0.** Ninite doesn't uninstall either.
   Unchecking means "don't install / leave alone". `brew uninstall --cask`
   leaves app data behind, and reversing a dotfile symlink means restoring a
   timestamped backup. Ship `--prune` in phase 4 behind an explicit flag and a
   typed confirmation, and say so in the README so nobody assumes otherwise.

2. **Doctor false positives are the top regression risk.** The moment install
   becomes partial, a profile-unaware doctor is worse than useless. Phase 4 is
   not optional — keep `doctor.sh` frozen as a shim until it lands.

3. **Manifest drift from upstream.** `ghostwire → zerodrop` already happened
   once. Add a weekly CI job validating every `formula` against
   `brew info --json=v2` and flagging renames/deprecations. Cheap, catches a
   real class of bug.

4. **Manifest validation as a test, not a hope.** Every `requires` resolves;
   every config `source` exists in the repo; every package id is unique; every
   preset references only real ids. Fails CI.

5. **Idempotency is the acceptance criterion, not a nice-to-have.** Every phase
   ships with a "run twice, second run is a no-op" test. The current append-once
   guards work only because the block is never edited; the managed region has to
   be genuinely reconstructable.

6. **Contributor barrier.** The repo stops being pure bash. Mitigate by keeping
   the manifest — the part people actually want to edit — plain TOML that needs
   no Rust knowledge, and document "add a package" as a one-file change in
   `CONTRIBUTING.md`.

7. **Land the working tree first.** `Brewfile`, `install.sh`, `doctor.sh`,
   `update.sh`, `README.md`, `CHANGELOG.md` are all modified, and `macos.sh`,
   `lefthook.yml`, `.editorconfig` are untracked. Commit or shelve those before
   Phase 0 — the extraction step needs a stable baseline to diff against.

---

## 12. Suggested first commits

1. `chore: commit pending macos.sh / lefthook / editorconfig work`
2. `feat(manifest): extract packages and descriptions into manifest/*.toml`
3. `feat(gen): regenerate Brewfile from manifest (byte-identical)`
4. `ci: validate manifest integrity and Brewfile freshness`
5. `feat(engine): scaffold crates/macsetup with clap CLI and manifest parsing`
