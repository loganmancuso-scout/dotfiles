#!/bin/bash
# Author: Logan Mancuso | LastEdit: 2025-09-07

set -euo pipefail

function usage() {
  cat <<EOF
Usage:
  $(basename "$0") --stow [--all] [folder1 folder2 ...]
  $(basename "$0") --unstow [--all] [folder1 folder2 ...]

Examples:
  $(basename "$0") --stow --all
  $(basename "$0") --stow git zsh nvim
  $(basename "$0") --unstow --all
  $(basename "$0") --unstow vscode starship
EOF
}

function discover_dotfile_dirs() {
  local base_dir="$1"
  mapfile -t ALL_DOTFILE_DIRS < <(find "$base_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
}

function validate_requested_dirs() {
  local -n requested_ref=$1
  local -n available_ref=$2
  local dir
  local found

  for dir in "${requested_ref[@]}"; do
    found=0
    for available in "${available_ref[@]}"; do
      if [[ "$dir" == "$available" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      echo "Error: '$dir' is not a top-level folder in this dotfiles repo."
      echo "Available folders: ${available_ref[*]}"
      exit 1
    fi
  done
}

function resolve_target_dirs() {
  local use_all="$1"
  shift
  local -a requested=("$@")

  if [[ "$use_all" == "true" || ${#requested[@]} -eq 0 ]]; then
    TARGET_DIRS=("${ALL_DOTFILE_DIRS[@]}")
  else
    validate_requested_dirs requested ALL_DOTFILE_DIRS
    TARGET_DIRS=("${requested[@]}")
  fi
}

# Main function to handle options
function main() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  cd "$script_dir"

  echo "System Information:"
  echo "hostname: $(cat /etc/hostname)"
  echo "cpu: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
  echo "memory: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
  echo "user: $(whoami)"
  echo "time: $(date)"

  # Use getopt for long option parsing
  OPTIONS=$(getopt -o "" --long stow,unstow,all,help -- "$@")

  # Check if getopt succeeded
  if [[ $? -ne 0 ]]; then
    echo "Failed to parse options."
    exit 1
  fi

  # Reorder options and arguments
  eval set -- "$OPTIONS"

  discover_dotfile_dirs "$script_dir"

  if [[ ${#ALL_DOTFILE_DIRS[@]} -eq 0 ]]; then
    echo "No top-level folders found in dotfiles directory."
    exit 1
  fi

  local action=""
  local use_all="false"
  local -a requested_dirs=()

  # Parse options
  while true; do
    case "$1" in
    --stow)
      if [[ -n "$action" && "$action" != "stow" ]]; then
        echo "Choose only one action: --stow or --unstow"
        exit 1
      fi
      action="stow"
      shift
      ;;
    --unstow)
      if [[ -n "$action" && "$action" != "unstow" ]]; then
        echo "Choose only one action: --stow or --unstow"
        exit 1
      fi
      action="unstow"
      shift
      ;;
    --all)
      use_all="true"
      shift
      ;;
    --help)
      usage
      exit 0
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

  requested_dirs=("$@")

  if [[ -z "$action" ]]; then
    echo "You must provide one action: --stow or --unstow"
    usage
    exit 1
  fi

  resolve_target_dirs "$use_all" "${requested_dirs[@]}"

  if [[ "$action" == "stow" ]]; then
    echo "Stowing folders: ${TARGET_DIRS[*]}"
    for dot in "${TARGET_DIRS[@]}"; do
      stow -v --dotfiles --adopt --target="$HOME" "$dot"
    done
    # leaving these comments here to remind me how to recycle services if i add a job to the systemd folder
    # systemctl --user daemon-reload
    # systemctl --user enable nextcloud.service
    # systemctl --user start nextcloud.service
  else
    echo "Unstowing folders: ${TARGET_DIRS[*]}"
    for dot in "${TARGET_DIRS[@]}"; do
      stow -D -v "$dot"
    done
  fi
}

# Call main function with arguments
main "$@"
