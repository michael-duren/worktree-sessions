#!/usr/bin/env bash
#
# Bash completion for wts
#

_wts_completions() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="open list review close config help"

  case "$prev" in
    wts)
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
      return 0
      ;;
    help)
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
      return 0
      ;;
    close)
      if [ "$cur" = "-" ]; then
        COMPREPLY=( $(compgen -W "--all" -- "$cur") )
        return 0
      fi
      # Complete with active session names
      local sessions
      sessions="$(tmux list-sessions -F '#S' 2>/dev/null | grep '^wt:' | sed 's/^wt://' || true)"
      COMPREPLY=( $(compgen -W "$sessions" -- "$cur") )
      return 0
      ;;
    open)
      # Complete with worktree directory names
      local worktrees
      worktrees="$(ls -d */ 2>/dev/null | while read -r d; do
        d="${d%/}"
        if [ -f "${d}/.git" ] || [ -d "${d}/.git" ]; then
          echo "$d"
        fi
      done || true)"
      COMPREPLY=( $(compgen -W "$worktrees" -- "$cur") )
      return 0
      ;;
  esac
}

complete -F _wts_completions wts
