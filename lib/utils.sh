#!/usr/bin/env bash
#
# wts utility functions
# Sourced by all wts commands
#

# ─────────────────────────────────────────────────────────────
# Colors (respects NO_COLOR: https://no-color.org/)
# ─────────────────────────────────────────────────────────────

if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
  WTS_RED=$'\033[0;31m'
  WTS_GREEN=$'\033[0;32m'
  WTS_YELLOW=$'\033[0;33m'
  WTS_BLUE=$'\033[0;34m'
  WTS_MAGENTA=$'\033[0;35m'
  WTS_CYAN=$'\033[0;36m'
  WTS_DIM=$'\033[2m'
  WTS_BOLD=$'\033[1m'
  WTS_RESET=$'\033[0m'
else
  WTS_RED=""
  WTS_GREEN=""
  WTS_YELLOW=""
  WTS_BLUE=""
  WTS_MAGENTA=""
  WTS_CYAN=""
  WTS_DIM=""
  WTS_BOLD=""
  WTS_RESET=""
fi

# ─────────────────────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────────────────────

wts_info() {
  echo "${WTS_BLUE}::${WTS_RESET} $*"
}

wts_success() {
  echo "${WTS_GREEN}::${WTS_RESET} $*"
}

wts_warn() {
  echo "${WTS_YELLOW}::${WTS_RESET} $*" >&2
}

wts_error() {
  echo "${WTS_RED}:: error:${WTS_RESET} $*" >&2
}

wts_debug() {
  if [ "${WTS_DEBUG:-0}" = "1" ]; then
    echo "${WTS_DIM}[debug] $*${WTS_RESET}" >&2
  fi
}

# ─────────────────────────────────────────────────────────────
# Dependency checks
# ─────────────────────────────────────────────────────────────

wts_require() {
  local cmd="$1"
  local msg="${2:-$cmd is required but not found. Please install it.}"
  if ! command -v "$cmd" &>/dev/null; then
    wts_error "$msg"
    exit 1
  fi
}

wts_check_deps() {
  wts_require tmux "tmux is required. Install with: brew install tmux"
  wts_require fzf "fzf is required. Install with: brew install fzf"
  wts_require git "git is required. Install with: brew install git"
}

# ─────────────────────────────────────────────────────────────
# Worktree helpers
# ─────────────────────────────────────────────────────────────

# Get the worktree root directory (parent of bare repo and worktrees)
# Looks for a bare repo directory in the current or specified directory
wts_find_worktree_root() {
  local dir="${1:-$(pwd)}"

  # Check if we're in a directory that contains worktrees
  # Look for a bare repo (a directory containing HEAD file and refs/)
  for d in "$dir"/*/; do
    [ -d "$d" ] || continue
    if [ -f "${d}HEAD" ] && [ -d "${d}refs" ]; then
      echo "$dir"
      return 0
    fi
  done

  # Check if we're inside a worktree - walk up to find the root
  local check_dir="$dir"
  while [ "$check_dir" != "/" ]; do
    if [ -f "$check_dir/.git" ]; then
      # This is a worktree (linked worktree has .git as a file, not dir)
      local parent
      parent="$(dirname "$check_dir")"
      # Verify parent has a bare repo
      for d in "$parent"/*/; do
        [ -d "$d" ] || continue
        if [ -f "${d}HEAD" ] && [ -d "${d}refs" ]; then
          echo "$parent"
          return 0
        fi
      done
    fi
    check_dir="$(dirname "$check_dir")"
  done

  return 1
}

# List all worktree directories (excluding the bare repo)
# Output format: <path>\t<branch>\t<status>
wts_list_worktrees() {
  local root="${1:-$(pwd)}"

  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    local name
    name="$(basename "$dir")"

    # Skip bare repo
    if [ -f "${dir}HEAD" ] && [ -d "${dir}refs" ]; then
      continue
    fi

    # Skip non-worktree directories
    if [ ! -f "${dir}.git" ] && [ ! -d "${dir}.git" ]; then
      continue
    fi

    # Get branch name
    local branch
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"

    # Check if tmux session exists
    local session_name
    session_name="$(wts_session_name "$name")"
    local status="inactive"
    if tmux has-session -t "=$session_name" 2>/dev/null; then
      status="active"
    fi

    printf '%s\t%s\t%s\t%s\n' "$dir" "$name" "$branch" "$status"
  done
}

# ─────────────────────────────────────────────────────────────
# Session helpers
# ─────────────────────────────────────────────────────────────

# Generate a tmux session name from a worktree name
# Tmux reserves '.' and ':' as delimiters -- avoid both
wts_session_name() {
  local name="$1"
  echo "${WTS_SESSION_PREFIX:-wt}/${name}" | tr '.:"' '_'
}

# Check if a tmux session exists
wts_session_exists() {
  local name="$1"
  tmux has-session -t "=$name" 2>/dev/null
}

# Create a tmux session with configured panes for a worktree
wts_create_session() {
  local worktree_path="$1"
  local session_name="$2"

  wts_debug "Creating session '$session_name' in '$worktree_path'"

  # Read pane commands from config
  local pane1_cmd="${WTS_PANE1_CMD:-$WTS_DEFAULT_PANE1_CMD}"
  local pane2_cmd="${WTS_PANE2_CMD:-$WTS_DEFAULT_PANE2_CMD}"
  local pane3_cmd="${WTS_PANE3_CMD:-$WTS_DEFAULT_PANE3_CMD}"

  # Read layout from config
  local layout="${WTS_LAYOUT:-$WTS_DEFAULT_LAYOUT}"

  # Create session with first pane (gh dash)
  tmux new-session -d -s "$session_name" -c "$worktree_path" -x "$(tput cols)" -y "$(tput lines)"

  case "$layout" in
    three-columns)
      # Layout: [gh dash | neovim | opencode]
      # Split horizontally to create pane 2
      tmux split-window -h -t "$session_name" -c "$worktree_path"
      # Split pane 2 horizontally to create pane 3
      tmux split-window -h -t "$session_name" -c "$worktree_path"
      # Even out the columns
      tmux select-layout -t "$session_name" even-horizontal
      ;;
    main-vertical)
      # Layout: [neovim (big) | gh dash / opencode (stacked)]
      tmux split-window -h -t "$session_name" -c "$worktree_path" -p 35
      tmux split-window -v -t "$session_name:1.2" -c "$worktree_path"
      ;;
    main-horizontal)
      # Layout: [neovim (top, big) / gh dash | opencode (bottom)]
      tmux split-window -v -t "$session_name" -c "$worktree_path" -p 35
      tmux split-window -h -t "$session_name:1.2" -c "$worktree_path"
      ;;
    *)
      # Default: three columns
      tmux split-window -h -t "$session_name" -c "$worktree_path"
      tmux split-window -h -t "$session_name" -c "$worktree_path"
      tmux select-layout -t "$session_name" even-horizontal
      ;;
  esac

  # Send commands to each pane
  tmux send-keys -t "$session_name:1.1" "$pane1_cmd" C-m
  tmux send-keys -t "$session_name:1.2" "$pane2_cmd" C-m
  tmux send-keys -t "$session_name:1.3" "$pane3_cmd" C-m

  # Focus the editor pane (pane 2 = neovim by default)
  tmux select-pane -t "$session_name:1.2"

  wts_debug "Session '$session_name' created with layout '$layout'"
}

# Attach or switch to a tmux session
wts_attach_session() {
  local session_name="$1"

  if [ -n "${TMUX:-}" ]; then
    # Already inside tmux - switch client
    tmux switch-client -t "=$session_name"
  else
    # Outside tmux - attach
    tmux attach-session -t "=$session_name"
  fi
}

# ─────────────────────────────────────────────────────────────
# Notification helpers
# ─────────────────────────────────────────────────────────────

wts_notify() {
  local title="$1"
  local message="$2"

  # macOS notification
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null || true
  fi

  # tmux display-message as fallback
  if [ -n "${TMUX:-}" ]; then
    tmux display-message "[$title] $message" 2>/dev/null || true
  fi
}
