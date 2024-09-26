#!/bin/bash
##############################################################################
#
# Author: Logan Mancuso
# Created: 07.31.2024
#
##############################################################################

# Redirect all output to log file
exec > >(tee -a "stow-dotfiles.log") 2>&1

# Function for stowing files using GNU Stow
function stow() {
  echo "stowing dotfiles..."
  stow -vv --dotfiles --adopt --target=$HOME bash
  stow -vv --dotfiles --adopt --target=$HOME git
  stow -vv --dotfiles --adopt --target=$HOME nvim
  stow -vv --dotfiles --adopt --target=$HOME ssh
  stow -vv --dotfiles --adopt --target=$HOME starship
  stow -vv --dotfiles --adopt --target=$HOME vscode
  stow -vv --dotfiles --adopt --target=$HOME zoxide
  stow -vv --dotfiles --adopt --target=$HOME systemd
  systemctl --user daemon-reload
  systemctl --user enable nextcloud.service
  systemctl --user start nextcloud.service
}

# Function for unstowing files
function unstow() {
  echo "Unstowing dotfiles..."
  stow -D -vv --dotfiles --target=$HOME bash
  stow -D -vv --dotfiles --target=$HOME git
  stow -D -vv --dotfiles --target=$HOME nvim
  stow -D -vv --dotfiles --target=$HOME ssh
  stow -D -vv --dotfiles --target=$HOME starship
  stow -D -vv --dotfiles --target=$HOME vscode
  stow -D -vv --dotfiles --target=$HOME zoxide
  stow -D -vv --dotfiles --target=$HOME systemd
}

# Main function to handle arguments
function main() {
  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"

  # Parse options
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --stow)
        stow
        ;;
      --unstow)
        unstow
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done
}

# Call main function with arguments
main "$@"
