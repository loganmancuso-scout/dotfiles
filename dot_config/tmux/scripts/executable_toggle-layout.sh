#!/usr/bin/env bash
# toggle-layout.sh - Toggle the current window's pane layout between
# even-horizontal (side-by-side) and even-vertical (stacked).
#
# Tracks state in a window-scoped custom option (@layout_toggle) since tmux
# has no built-in "flip between these two layouts" command — only
# next-layout, which cycles through all 5 presets.

current=$(tmux show-options -wqv @layout_toggle)

if [[ "$current" == "vertical" ]]; then
  tmux select-layout -t "$(tmux display-message -p '#{window_id}')" even-horizontal
  tmux set-option -w @layout_toggle horizontal
else
  tmux select-layout -t "$(tmux display-message -p '#{window_id}')" even-vertical
  tmux set-option -w @layout_toggle vertical
fi
