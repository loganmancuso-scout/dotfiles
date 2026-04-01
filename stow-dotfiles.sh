#!/bin/bash
# Author: Logan Mancuso | LastEdit: 2026-03-23

# ─────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directories at the repo root that are not stow packages
EXCLUDE=(".git")

function discover_packages() {
  dotfiles=()
  for dir in "$SCRIPT_DIR"/*/; do
    local name
    name="$(basename "$dir")"
    [[ " ${EXCLUDE[*]} " == *" $name "* ]] && continue
    dotfiles+=("$name")
  done
}

function print_summary() {
  local action="$1"
  shift
  local ok=("$@")

  echo ""
  echo "Discovered packages: ${dotfiles[*]}"
  echo ""
  echo "${action} results:"
  for pkg in "${dotfiles[@]}"; do
    if [[ " ${ok[*]} " == *" $pkg "* ]]; then
      printf "  [OK]   %s\n" "$pkg"
    else
      printf "  [FAIL] %s\n" "$pkg"
      failed+=("$pkg")
    fi
  done

  echo ""
  local total=${#dotfiles[@]}
  local ok_count=${#ok[@]}
  local fail_count=${#failed[@]}
  local action_lower=$(echo "$action" | tr '[:upper:]' '[:lower:]')
  echo "Done. $ok_count/${total} ${action_lower}, ${fail_count} failed."

  if [[ ${#failed[@]} -gt 0 ]]; then
    echo "Failed packages: ${failed[*]}"
    return 1
  fi
  return 0
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────
function main() {
  echo "System Information:"
  echo "  user: $(whoami)"
  echo "  time: $(date)"

  OPTIONS=$(getopt -o "" --long stow,unstow -- "$@")
  if [[ $? -ne 0 ]]; then
    echo "Failed to parse options."
    exit 1
  fi
  eval set -- "$OPTIONS"

  discover_packages

  while true; do
    case "$1" in
    --stow)
      echo ""
      echo "Stowing dotfiles..."
      local ok=()
      local failed=()
      for pkg in "${dotfiles[@]}"; do
        local err
        err=$(stow -v --dotfiles --adopt --target="$HOME" "$pkg" 2>&1)
        if [[ $? -eq 0 ]]; then
          ok+=("$pkg")
        else
          echo "  [FAIL] $pkg: $err"
        fi
      done
      # leaving these comments here to remind me how to recycle services if i add a job to the systemd folder
      # systemctl --user daemon-reload
      # systemctl --user enable nextcloud.service
      # systemctl --user start nextcloud.service
      print_summary "Stowed" "${ok[@]}"
      exit $?
      ;;
    --unstow)
      echo ""
      echo "Unstowing dotfiles..."
      local ok=()
      local failed=()
      for pkg in "${dotfiles[@]}"; do
        local err
        err=$(stow -D -vv "$pkg" 2>&1)
        if [[ $? -eq 0 ]]; then
          ok+=("$pkg")
        else
          echo "  [FAIL] $pkg: $err"
        fi
      done
      print_summary "Unstowed" "${ok[@]}"
      exit $?
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

  echo "Usage: $0 --stow | --unstow"
  exit 1
}

main "$@"
