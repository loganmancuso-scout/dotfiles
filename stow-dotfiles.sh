#!/bin/bash
# Author: Logan Mancuso | LastEdit: 2025-09-07

# Main function to handle options
function main() {
  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"

  # Use getopt for long option parsing
  OPTIONS=$(getopt -o "" --long stow,unstow -- "$@")

  # Check if getopt succeeded
  if [[ $? -ne 0 ]]; then
    echo "Failed to parse options."
    exit 1
  fi

  # Reorder options and arguments
  eval set -- "$OPTIONS"

  declare -a dotfiles=("aliases" "bash" "continue" "ghostty" "git" "nvim" "ssh" "starship" "vscode" "zed" "zellij" "zoxide" "zsh")

  # Parse options
  while true; do
    case "$1" in
    --stow)
      echo "stowing dotfiles..."
      for dot in "${dotfiles[@]}"; do
        stow -v --dotfiles --adopt --target="$HOME" "$dot"
      done
      # leaving thses comments here to remind me how to recycle services if i add a job to the systemd folder
      # systemctl --user daemon-reload
      # systemctl --user enable nextcloud.service
      # systemctl --user start nextcloud.service
      shift
      ;;
    --unstow)
      echo "Unstowing dotfiles..."
      for dot in "${dotfiles[@]}"; do
        stow -D -v "$dot"
      done
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
    esac
  done
}

# Call main function with arguments
main "$@"
