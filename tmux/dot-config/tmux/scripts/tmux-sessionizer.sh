#!/usr/bin/env bash
# tmux-sessionizer - Fuzzy find project directories and create/switch to tmux sessions
# Inspired by ThePrimeagen's tmux-sessionizer
# Usage: tmux-sessionizer.sh [directory]

if [[ $# -eq 1 ]]; then
  selected=$1
else
  # Fuzzy find directories to search
  # Customize these directories to match your project locations
  selected=$(find ~/SourceControl ~/Documents ~/Desktop ~ -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf --reverse --height=50% --border=rounded --border-label=" Select Project Directory " --prompt="Project: ")
fi

# Exit if no directory is selected
if [[ -z $selected ]]; then
  exit 0
fi

# Create session name from directory basename, replacing dots with underscores
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# If not in tmux and tmux is not running, create new session
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

# Create new session if it doesn't exist
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

# Switch to the session
if [[ -n $TMUX ]]; then
  # If inside tmux, switch client
  tmux switch-client -t "$selected_name"
else
  # If outside tmux, attach to session
  tmux attach-session -t "$selected_name"
fi
