#!/bin/bash
# scripts/check-templates.sh — guard the templates against the two failure modes
# that silently broke the Starship powerline on 2026-09-03.
#
#   1. VALIDITY. templates/starship.toml.tmpl wrote three `format` values as TOML
#      basic strings containing `\(`, which is not a valid escape. The whole
#      config failed to parse, and Starship responded by falling back to its
#      stock prompt rather than erroring — so the only symptom was "my prompt
#      looks generic". Rendering a template and asking its real parser about the
#      result turns that into a commit-time failure.
#
#   2. PARITY. templates/starship.toml.tmpl and starship/starship.toml are
#      hand-maintained copies of each other, so they drift. Rendering the
#      template with the mocha palette must reproduce starship/starship.toml
#      byte for byte, otherwise an install produces a prompt that differs from
#      the one checked in.
#
# Parity is asserted for the starship pair ONLY. The ghostty, aerospace and
# vscode templates deliberately differ from their repo copies in their comments:
# the template prose is genericised because the values around it are
# placeholders (`__AEROSPACE_MODIFIER__` renders as "alt", while the repo copy
# documents the "⌥ Option" default). Byte-identity is the wrong invariant there,
# so those pairs get the validity check only.
#
# Checks needing a tool that is missing are reported and skipped, not failed —
# a hook that blocks commits over an absent optional dependency gets bypassed,
# and a routinely bypassed hook is worse than no hook. The parity check needs
# nothing beyond the repo and always runs.
#
# Run manually with: ./scripts/check-templates.sh

# shellcheck disable=SC1091
# Modular libraries are located in lib/ and sourced at runtime.
# shellcheck disable=SC2034
# CONFIG_* variables are consumed by render_template as globals, not locally.

set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/config.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

FAIL_N=0
SKIP_N=0

_fail() {
    FAIL_N=$((FAIL_N + 1))
    printf "  %sFAIL%s  %s\n" "$C_RED" "$C_RESET" "$1"
    [ -n "${2:-}" ] && printf "        %s%s%s\n" "$C_DIM" "$2" "$C_RESET"
    return 0
}

_ok() { printf "  %sok%s    %s\n" "$C_GREEN" "$C_RESET" "$1"; }

_skip() {
    SKIP_N=$((SKIP_N + 1))
    printf "  %sskip%s  %s %s(%s)%s\n" "$C_YELLOW" "$C_RESET" "$1" "$C_DIM" "$2" "$C_RESET"
}

# Render a template with the default configuration into $WORK_DIR
_render() {
    local tmpl="$1" out="$2" palette="${3:-catppuccin_mocha}"
    (
        init_default_config
        CONFIG_THEME_PALETTE="$palette"
        render_template "$REPO_DIR/templates/$tmpl" "$out"
    ) >/dev/null 2>&1
}

printf "%s🧪 template checks%s\n" "$C_HEAD" "$C_RESET"

# --- 1. Starship parity: mocha render must equal the checked-in config --------
_render "starship.toml.tmpl" "$WORK_DIR/starship.toml" "catppuccin_mocha"
if diff -q "$WORK_DIR/starship.toml" "$REPO_DIR/starship/starship.toml" >/dev/null 2>&1; then
    _ok "starship template renders to starship/starship.toml byte-identically"
else
    _fail "starship template has drifted from starship/starship.toml" \
        "rendered template (<) vs checked-in config (>), first 20 lines:"
    diff "$WORK_DIR/starship.toml" "$REPO_DIR/starship/starship.toml" |
        head -20 | sed 's/^/        /'
fi

# --- 2. Starship validity, every palette the customizer offers ---------------
# `starship explain` exits 0 even on a broken config — it just prints the parse
# error and renders the default prompt — so match on the message, not the code.
if command -v starship >/dev/null 2>&1; then
    for palette in catppuccin_mocha catppuccin_macchiato catppuccin_frappe catppuccin_latte; do
        _render "starship.toml.tmpl" "$WORK_DIR/s_$palette.toml" "$palette"
        err="$(STARSHIP_CONFIG="$WORK_DIR/s_$palette.toml" starship explain 2>&1 |
            grep -m1 'Unable to parse the config file' || true)"
        if [ -n "$err" ]; then
            _fail "starship template is invalid under $palette" "$err"
        else
            _ok "starship template parses under $palette"
        fi
    done
else
    _skip "starship template validity" "starship not installed"
fi

# --- 3. AeroSpace validity ----------------------------------------------------
if command -v python3 >/dev/null 2>&1 && python3 -c "import tomllib" 2>/dev/null; then
    _render "aerospace.toml.tmpl" "$WORK_DIR/aerospace.toml"
    if err="$(python3 -c "import tomllib,sys; tomllib.load(open(sys.argv[1],'rb'))" \
        "$WORK_DIR/aerospace.toml" 2>&1)"; then
        _ok "aerospace template renders valid TOML"
    else
        _fail "aerospace template renders invalid TOML" "$(echo "$err" | tail -1)"
    fi
else
    _skip "aerospace template validity" "python3 with tomllib not available"
fi

printf "\n"
if [ "$FAIL_N" -gt 0 ]; then
    printf "  %s%d check(s) failed%s\n" "$C_RED" "$FAIL_N" "$C_RESET"
    printf "  %sBypass for one commit with LEFTHOOK=0 git commit ...%s\n" "$C_DIM" "$C_RESET"
    exit 1
fi

if [ "$SKIP_N" -gt 0 ]; then
    printf "  %sall checks passed (%d skipped)%s\n" "$C_GREEN" "$SKIP_N" "$C_RESET"
else
    printf "  %sall checks passed%s\n" "$C_GREEN" "$C_RESET"
fi
