#!/usr/bin/env bash
# session-fzf.sh - Interactive session switcher using fzf in a popup
# Fuzzy find and switch between existing tmux sessions

# Get all sessions except the current one
current_session=$(tmux display-message -p '#S')

# List all sessions, exclude current, and use fzf to select
selected=$(tmux list-sessions -F '#{session_name}' | \
  grep -v "^${current_session}\$" | \
  fzf --reverse \
      --height=50% \
      --border=rounded \
      --border-label=" Switch Tmux Session " \
      --prompt="Session: " \
      --preview 'tmux list-windows -t {} -F "#{window_index}: #{window_name} (#{window_panes} panes)"' \
      --preview-window=right:50%:wrap)

# Switch to selected session if one was chosen
if [[ -n $selected ]]; then
  tmux switch-client -t "$selected"
fi
