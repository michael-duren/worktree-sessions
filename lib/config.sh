#!/usr/bin/env bash
#
# wts configuration
# Handles loading and merging config from ~/.config/wts/config
#

# ─────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────

WTS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wts"
WTS_CONFIG_FILE="$WTS_CONFIG_DIR/config"

# Default pane commands
WTS_DEFAULT_PANE1_CMD="nvim"
WTS_DEFAULT_PANE2_CMD="opencode"

# Default layout: two-columns | main-vertical
WTS_DEFAULT_LAYOUT="two-columns"

# Session name prefix
WTS_SESSION_PREFIX="${WTS_SESSION_PREFIX:-wt}"

# PR review settings
WTS_PR_WORKTREE_PREFIX="${WTS_PR_WORKTREE_PREFIX:-pr-}"
WTS_PR_REVIEW_CMD="${WTS_PR_REVIEW_CMD:-nvim}"

# ─────────────────────────────────────────────────────────────
# Config loading
# ─────────────────────────────────────────────────────────────

wts_load_config() {
  # Create config dir if it doesn't exist
  if [ ! -d "$WTS_CONFIG_DIR" ]; then
    mkdir -p "$WTS_CONFIG_DIR"
  fi

  # Create default config if it doesn't exist
  if [ ! -f "$WTS_CONFIG_FILE" ]; then
    wts_create_default_config
  fi

  # Source the config file (it's just bash variable assignments)
  # shellcheck source=/dev/null
  source "$WTS_CONFIG_FILE"
}

wts_create_default_config() {
  cat > "$WTS_CONFIG_FILE" << 'EOF'
# ─────────────────────────────────────────────────────────────
# wts - Worktree Sessions Configuration
# ─────────────────────────────────────────────────────────────

# Session name prefix (sessions will be named: <prefix>/<worktree>)
# WTS_SESSION_PREFIX="wt"

# ─────────────────────────────────────────────────────────────
# Pane Commands
# ─────────────────────────────────────────────────────────────
# Commands to run in each pane when opening a worktree session.
# Two panes are arranged according to WTS_LAYOUT.

# Pane 1: Editor (left/main)
# WTS_PANE1_CMD="nvim"

# Pane 2: AI assistant (right)
# WTS_PANE2_CMD="opencode"

# ─────────────────────────────────────────────────────────────
# Layout
# ─────────────────────────────────────────────────────────────
# Available layouts:
#   two-columns    - [pane1 | pane2] equal width columns
#   main-vertical  - [pane1 (65%) | pane2 (35%)]

# WTS_LAYOUT="two-columns"

# ─────────────────────────────────────────────────────────────
# PR Review
# ─────────────────────────────────────────────────────────────
# Prefix for auto-created PR review worktrees
# WTS_PR_WORKTREE_PREFIX="pr-"

# Editor command for reviewing PRs (replaces pane1 command)
# Open nvim, then use :Octo pr <number> to review
# WTS_PR_REVIEW_CMD="nvim"
EOF

  wts_debug "Created default config at $WTS_CONFIG_FILE"
}

# Print current config values
wts_show_config() {
  echo "${WTS_BOLD}Current configuration:${WTS_RESET}"
  echo ""
  echo "  Config file:       $WTS_CONFIG_FILE"
  echo ""
  echo "  Session prefix:    ${WTS_SESSION_PREFIX:-wt}"
  echo "  Layout:            ${WTS_LAYOUT:-$WTS_DEFAULT_LAYOUT}"
  echo ""
  echo "  Pane 1 command:    ${WTS_PANE1_CMD:-$WTS_DEFAULT_PANE1_CMD}"
  echo "  Pane 2 command:    ${WTS_PANE2_CMD:-$WTS_DEFAULT_PANE2_CMD}"
  echo ""
  echo "  PR worktree prefix: ${WTS_PR_WORKTREE_PREFIX:-pr-}"
  echo "  PR review command:  ${WTS_PR_REVIEW_CMD:-nvim}"
}
