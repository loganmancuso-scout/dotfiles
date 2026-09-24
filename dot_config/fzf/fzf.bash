# Author: Logan Mancuso | LastEdit: 2026-04-01
# ~/.fzf.bash
# FZF configuration for bash

# ─────────────────────────────────────────
# FZF OPTIONS
# ─────────────────────────────────────────
# Default command uses fd for faster searching and respects .gitignore
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Default options for appearance and behavior
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout reverse
  --border rounded
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --preview-window right:50%:wrap
  --bind 'ctrl-/:toggle-preview'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
"

# ─────────────────────────────────────────
# KEYBINDINGS
# ─────────────────────────────────────────
# Ctrl-T: paste selected files/directories
# Ctrl-R: paste selected command from history
# Alt-C: cd into selected directory
# Note: keybindings and completions are loaded via `source <(fzf --bash)` in .bashrc
