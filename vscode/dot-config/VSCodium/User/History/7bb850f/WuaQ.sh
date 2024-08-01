#!/bin/bash
##############################################################################
#
# Author: Logan Mancuso
# Created: 07.31.2024
#
##############################################################################

# Redirect all output to log file
exec > >(tee -a "init-debian.log") 2>&1


function main() {
  print_ascii_time "Starting main"
  
  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"
  stow -vv --dotfiles --target=$HOME --adopt bash
  stow -vv --dotfiles --target=$HOME --adopt git
  stow -vv --dotfiles --target=$HOME --adopt nvim
  stow -vv --dotfiles --target=$HOME --adopt ssh 
  
  # stow -D -vv --dotfiles --target=$HOME bash

  print_ascii_time "Completed main"
}

main "$@"
