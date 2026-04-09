#!/usr/bin/env bash
#
# wts installer
#
# Installs wts by:
#   1. Symlinking bin/wts to ~/.local/bin/wts (or /usr/local/bin/wts)
#   2. Creating default config at ~/.config/wts/config
#
# Usage:
#   ./install.sh              # install to ~/.local/bin (default)
#   ./install.sh /usr/local   # install to /usr/local/bin
#   curl ... | bash           # install from remote
#
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Resolve script location
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
if [ -t 1 ]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RESET=$'\033[0m'
else
  RED="" GREEN="" YELLOW="" BLUE="" BOLD="" DIM="" RESET=""
fi

info()    { echo "${BLUE}::${RESET} $*"; }
success() { echo "${GREEN}::${RESET} $*"; }
warn()    { echo "${YELLOW}::${RESET} $*" >&2; }
error()   { echo "${RED}:: error:${RESET} $*" >&2; }

# ─────────────────────────────────────────────────────────────
# Determine install prefix
# ─────────────────────────────────────────────────────────────

PREFIX="${1:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"

# ─────────────────────────────────────────────────────────────
# Check dependencies
# ─────────────────────────────────────────────────────────────

info "Checking dependencies..."

missing=()
for cmd in tmux fzf git; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  warn "Missing dependencies: ${missing[*]}"
  warn "Install with: brew install ${missing[*]}"
  echo ""
fi

# Optional deps
for cmd in gh nvim opencode; do
  if ! command -v "$cmd" &>/dev/null; then
    warn "Optional: $cmd not found (some features may not work)"
  fi
done

# ─────────────────────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────────────────────

info "Installing wts to $BIN_DIR..."

# Create bin directory
mkdir -p "$BIN_DIR"

# Create symlink
WTS_BIN="$BIN_DIR/wts"
if [ -L "$WTS_BIN" ] || [ -e "$WTS_BIN" ]; then
  warn "Removing existing $WTS_BIN"
  rm -f "$WTS_BIN"
fi

ln -s "$SCRIPT_DIR/bin/wts" "$WTS_BIN"
success "Symlinked $WTS_BIN -> $SCRIPT_DIR/bin/wts"

# ─────────────────────────────────────────────────────────────
# Shell completions
# ─────────────────────────────────────────────────────────────

COMPLETIONS_DIR="$PREFIX/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$PREFIX/share/zsh/site-functions"

if [ -f "$SCRIPT_DIR/completions/wts.bash" ]; then
  mkdir -p "$COMPLETIONS_DIR"
  ln -sf "$SCRIPT_DIR/completions/wts.bash" "$COMPLETIONS_DIR/wts"
  success "Installed bash completions"
fi

if [ -f "$SCRIPT_DIR/completions/_wts" ]; then
  mkdir -p "$ZSH_COMPLETIONS_DIR"
  ln -sf "$SCRIPT_DIR/completions/_wts" "$ZSH_COMPLETIONS_DIR/_wts"
  success "Installed zsh completions"
fi

# ─────────────────────────────────────────────────────────────
# PATH check
# ─────────────────────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  echo ""
  warn "$BIN_DIR is not in your PATH."
  echo ""
  echo "  Add this to your ~/.zshrc or ~/.bashrc:"
  echo ""
  echo "    ${BOLD}export PATH=\"$BIN_DIR:\$PATH\"${RESET}"
  echo ""
fi

# ─────────────────────────────────────────────────────────────
# tmux integration suggestion
# ─────────────────────────────────────────────────────────────

echo ""
info "Optional: Add tmux keybinding for quick access"
echo ""
echo "  Add to your ~/.config/tmux/tmux.conf:"
echo ""
echo "    ${DIM}# wts - Worktree Sessions${RESET}"
echo "    ${BOLD}bind w display-popup -E -w 60% -h 60% \"wts\"${RESET}"
echo "    ${BOLD}bind W display-popup -E -w 60% -h 40% \"wts list\"${RESET}"
echo ""

# ─────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────

echo ""
success "wts installed successfully!"
echo ""
echo "  Run ${BOLD}wts help${RESET} to get started."
echo "  Config will be created at ~/.config/wts/config on first run."
echo ""
