# wts - Worktree Sessions

Manage tmux sessions for git worktrees. Each worktree gets its own
tmux session with configurable panes for your development workflow.

## Dependencies

**Required:**

- [tmux](https://github.com/tmux/tmux) - terminal multiplexer
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder for interactive selection
- [git](https://git-scm.com/) - version control

**Optional (used by default pane commands):**

- [gh](https://cli.github.com/) - GitHub CLI, used for `gh dash` and `wts review`
- [neovim](https://neovim.io/) - editor (pane 2 default)
- [opencode](https://opencode.ai/) - AI assistant (pane 3 default)
- [Octo.nvim](https://github.com/pwntester/octo.nvim) - neovim plugin for PR review

```bash
brew install tmux fzf git gh neovim
```

## Installation

```bash
git clone https://github.com/michael-duren/worktree-sessions.git ~/worktree-sessions
cd ~/worktree-sessions
./install.sh
```

This symlinks `wts` into `~/.local/bin`. Pass a different prefix to change
the install location:

```bash
./install.sh /usr/local    # installs to /usr/local/bin/wts
```

Make sure the bin directory is in your `PATH`:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

### Shell completions

The installer automatically links completions for both bash and zsh.
For zsh, you may need to ensure the completions directory is in your `fpath`:

```bash
# Add to ~/.zshrc before compinit
fpath=(~/.local/share/zsh/site-functions $fpath)
```

## Expected directory structure

`wts` expects you to organize your repos using **git worktrees** with a
**bare clone** as the anchor. The layout looks like this:

```
myproject/                # <-- this is the "worktree root"
  bare/                   # bare git clone (contains HEAD, refs/, etc.)
  main/                   # worktree checked out to main
  feature-auth/           # worktree for a feature branch
  bugfix-login/           # worktree for a bugfix
  pr-123/                 # auto-created by `wts review 123`
```

### Setting up a repo this way

```bash
mkdir myproject && cd myproject
git clone --bare git@github.com:org/repo.git bare
git -C bare worktree add ../main main
git -C bare worktree add ../feature-auth feature-auth
```

Each subdirectory (except `bare/`) is a full working copy on its own branch.

## Where to run `wts`

You must run `wts` from one of two places:

1. **The worktree root directory** (the parent that contains `bare/` and all
   worktree directories). This is the most common case.

2. **Inside any worktree directory.** `wts` will walk up the directory tree
   to find the root automatically.

```bash
cd ~/Code/myproject       # worktree root -- works
cd ~/Code/myproject/main  # inside a worktree -- also works
wts                       # opens the interactive picker either way
```

It will **not** work from an unrelated directory -- it needs to find a bare
repo sibling to know where your worktrees are.

## Usage

```
wts [command] [options]
```

Running `wts` with no arguments opens the interactive worktree picker
(equivalent to `wts open`).

### Commands

| Command              | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| `wts`                | Interactive fzf picker, opens a 3-pane session in the selected worktree |
| `wts open <name>`    | Open a session directly by worktree directory name                      |
| `wts list`           | Show all worktrees with branch name and session status                  |
| `wts review <pr#>`   | Fetch a PR, create a worktree for it, open a review session             |
| `wts close [name]`   | Interactive picker to kill a session (or pass the name directly)        |
| `wts close --all`    | Kill all active worktree sessions                                       |
| `wts config`         | Print current configuration values                                      |
| `wts help [command]` | Show help (optionally for a specific command)                           |

### Examples

```bash
# Pick a worktree interactively and open a session
wts

# Open a session directly in the "main" worktree
wts open main

# List worktrees and see which have active sessions
wts list

# Review PR #42 -- creates pr-42/ worktree, fetches the branch, opens session
wts review 42

# Close a specific session
wts close main

# Close all sessions
wts close --all
```

## Configuration

Config lives at `~/.config/wts/config` (respects `$XDG_CONFIG_HOME`).
A default config is created on first run. It's a plain bash file with
variable assignments.

Run `wts config` to see current values.

### Config options

```bash
# Session name prefix (sessions are named <prefix>:<worktree>)
WTS_SESSION_PREFIX="wt"

# Commands for each pane
WTS_PANE1_CMD="gh dash"       # Pane 1: GitHub dashboard
WTS_PANE2_CMD="nvim"          # Pane 2: Editor
WTS_PANE3_CMD="opencode"      # Pane 3: AI assistant

# Layout: three-columns | main-vertical | main-horizontal
WTS_LAYOUT="three-columns"

# PR review settings
WTS_PR_WORKTREE_PREFIX="pr-"  # Prefix for auto-created PR worktrees
WTS_PR_REVIEW_CMD="nvim +Octo" # Editor command used in review sessions
```

### Layouts

**`three-columns`** (default) -- three equal-width columns:

```
┌──────────┬──────────┬──────────┐
│ gh dash  │  nvim    │ opencode │
│          │          │          │
│          │          │          │
└──────────┴──────────┴──────────┘
```

**`main-vertical`** -- large editor left, stacked sidebar right:

```
┌─────────────────┬──────────┐
│                 │ gh dash  │
│     nvim        ├──────────┤
│                 │ opencode │
└─────────────────┴──────────┘
```

**`main-horizontal`** -- large editor top, split bar bottom:

```
┌────────────────────────────┐
│           nvim             │
├──────────────┬─────────────┤
│   gh dash    │  opencode   │
└──────────────┴─────────────┘
```

## tmux integration

Add keybindings to your `~/.config/tmux/tmux.conf` for quick access:

```tmux
# Open worktree picker in a popup (prefix + w)
bind w display-popup -E -w 60% -h 60% "wts"

# List worktrees in a popup (prefix + W)
bind W display-popup -E -w 60% -h 40% "wts list"
```

## Debugging

Set `WTS_DEBUG=1` to enable debug output:

```bash
WTS_DEBUG=1 wts list
```

Colors can be disabled with `NO_COLOR=1` (follows the [no-color.org](https://no-color.org/) convention).

## Project structure

```
worktree-sessions/
  bin/wts               # Main entry point / dispatcher
  libexec/              # Subcommands (one file per command)
    wts-open
    wts-list
    wts-review
    wts-close
    wts-config
    wts-help
  lib/                  # Shared libraries sourced by all commands
    utils.sh            # Colors, logging, worktree/session helpers
    config.sh           # Config loading and defaults
  completions/          # Shell completions
    wts.bash
    _wts                # zsh completion
  install.sh
  VERSION
```

Follows the [rbenv](https://github.com/rbenv/rbenv) pattern: the dispatcher
in `bin/wts` resolves and `exec`s subcommand scripts from `libexec/`. Adding
a new subcommand is as simple as dropping a `wts-<name>` script into `libexec/`.
