#!/bin/bash
# Author: Logan Mancuso | LastEdit: 2024-05-16

# Redirect all output to log file
exec > >(tee "stow-dotfiles.log") 2>&1

# Function for stowing files using GNU Stow
function stow_dotfiles() {
  echo "stowing dotfiles..."
  stow -vv --dotfiles --adopt --target=$HOME aliases
  stow -vv --dotfiles --adopt --target=$HOME bash
  stow -vv --dotfiles --adopt --target=$HOME continue
  stow -vv --dotfiles --adopt --target=$HOME git
  stow -vv --dotfiles --adopt --target=$HOME nvim
  stow -vv --dotfiles --adopt --target=$HOME ssh
  stow -vv --dotfiles --adopt --target=$HOME starship
  stow -vv --dotfiles --adopt --target=$HOME vscode
  stow -vv --dotfiles --adopt --target=$HOME zoxide
  stow -vv --dotfiles --adopt --target=$HOME zsh
  stow -vv --dotfiles --adopt --target=$HOME systemd
  systemctl --user daemon-reload
  # systemctl --user enable nextcloud.service
  # systemctl --user start nextcloud.service
}

# Function for unstowing files
function unstow_dotfiles() {
  echo "Unstowing dotfiles..."
  stow -D -vv --dotfiles --target=$HOME aliases
  stow -D -vv --dotfiles --target=$HOME bash
  stow -D -vv --dotfiles --target=$HOME continue
  stow -D -vv --dotfiles --target=$HOME git
  stow -D -vv --dotfiles --target=$HOME nvim
  stow -D -vv --dotfiles --target=$HOME ssh
  stow -D -vv --dotfiles --target=$HOME starship
  stow -D -vv --dotfiles --target=$HOME vscode
  stow -D -vv --dotfiles --target=$HOME zoxide
  stow -D -vv --dotfiles --target=$HOME zsh
  systemctl --user daemon-reload
  # systemctl --user stop nextcloud.service
  # systemctl --user disable nextcloud.service
  stow -D -vv --dotfiles --target=$HOME systemd
}

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

  # Parse options
  while true; do
    case "$1" in
      --stow)
        stow_dotfiles
        shift
        ;;
      --unstow)
        unstow_dotfiles
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
