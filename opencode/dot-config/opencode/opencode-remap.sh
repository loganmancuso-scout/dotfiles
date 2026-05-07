#!/usr/bin/env bash
# opencode-remap — Remap project paths in the OpenCode SQLite database
#
# Usage:
#   opencode-remap <OLD_PATH> <NEW_PATH>   # remap a path prefix
#   opencode-remap --list-stale            # show projects whose directories no longer exist
#
# Examples:
#   opencode-remap ~/SourceControl/temp ~/Documents/Notes
#   opencode-remap ~/SourceControl/old-name ~/SourceControl/new-name

set -euo pipefail

DB="${OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

die() { echo -e "${RED}error:${RESET} $*" >&2; exit 1; }
info() { echo -e "${CYAN}info:${RESET} $*"; }
warn() { echo -e "${YELLOW}warn:${RESET} $*"; }
ok() { echo -e "${GREEN}ok:${RESET} $*"; }

# Ensure sqlite3 is available
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is not installed or not in PATH"

# Ensure DB exists
[[ -f "$DB" ]] || die "OpenCode database not found at: $DB\n       Set OPENCODE_DB env var to override."

# ── list-paths mode ────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--list-paths" ]]; then
  echo -e "\n${BOLD}All project paths with sessions:${RESET}\n"
  count=0
  while IFS='|' read -r worktree session_count; do
    [[ "$worktree" == "/" ]] && continue
    if [[ -d "$worktree" ]]; then
      status="${GREEN}✓${RESET}"
    else
      status="${RED}✗${RESET}"
    fi
    printf "  %b  %-6s sessions   %s\n" "$status" "$session_count" "$worktree"
    count=$((count + 1))
  done < <(sqlite3 "$DB" "
    SELECT p.worktree, COUNT(s.id)
    FROM project p
    LEFT JOIN session s ON s.project_id = p.id
    WHERE p.id != 'global'
    GROUP BY p.id
    ORDER BY p.worktree;
  ")
  echo ""
  info "$count project(s) total. ${GREEN}✓${RESET} = exists  ${RED}✗${RESET} = missing"
  echo ""
  exit 0
fi

# ── list-stale mode ────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--list-stale" ]]; then
  echo -e "\n${BOLD}Stale project paths (directory no longer exists):${RESET}\n"
  stale=0
  while IFS='|' read -r worktree session_count; do
    [[ "$worktree" == "/" ]] && continue
    if [[ ! -d "$worktree" ]]; then
      printf "  %-6s sessions   %s\n" "$session_count" "$worktree"
      stale=$((stale + 1))
    fi
  done < <(sqlite3 "$DB" "
    SELECT p.worktree, COUNT(s.id)
    FROM project p
    LEFT JOIN session s ON s.project_id = p.id
    WHERE p.id != 'global'
    GROUP BY p.id
    ORDER BY p.worktree;
  ")
  if [[ $stale -eq 0 ]]; then
    ok "No stale projects found — all directories exist."
  else
    echo ""
    warn "$stale stale project(s) found."
    echo -e "  Run ${BOLD}opencode-remap <OLD_PATH> <NEW_PATH>${RESET} to remap them."
  fi
  echo ""
  exit 0
fi

# ── remap mode ─────────────────────────────────────────────────────────────────
[[ $# -eq 2 ]] || {
  echo "Usage: opencode-remap <OLD_PATH> <NEW_PATH>"
  echo "       opencode-remap --list-paths"
  echo "       opencode-remap --list-stale"
  exit 1
}

OLD_PATH="${1%/}"   # strip trailing slash
NEW_PATH="${2%/}"

# Expand ~ and resolve to absolute paths
OLD_PATH="$(eval echo "$OLD_PATH")"
NEW_PATH="$(eval echo "$NEW_PATH")"

[[ -n "$OLD_PATH" ]] || die "OLD_PATH cannot be empty"
[[ -n "$NEW_PATH" ]] || die "NEW_PATH cannot be empty"
[[ "$OLD_PATH" != "$NEW_PATH" ]] || die "OLD_PATH and NEW_PATH are the same"

# Warn if new path doesn't exist yet
if [[ ! -d "$NEW_PATH" ]]; then
  warn "NEW_PATH does not exist on disk: $NEW_PATH"
  warn "Remapping will still proceed, but OpenCode may not find the directory."
  echo ""
fi

echo -e "\n${BOLD}Dry run — rows that will be updated:${RESET}\n"

# Dry run: show affected rows
DRY=$(sqlite3 "$DB" "
  SELECT 'project', worktree FROM project
    WHERE worktree = '$OLD_PATH' OR worktree LIKE '$OLD_PATH/%'
  UNION ALL
  SELECT 'session', directory FROM session
    WHERE directory = '$OLD_PATH' OR directory LIKE '$OLD_PATH/%'
  UNION ALL
  SELECT 'workspace', directory FROM workspace
    WHERE directory = '$OLD_PATH' OR directory LIKE '$OLD_PATH/%';
")

if [[ -z "$DRY" ]]; then
  warn "No rows found matching path: $OLD_PATH"
  echo "       Nothing to remap. Run ${BOLD}opencode-remap --list-stale${RESET} to see all projects."
  exit 0
fi

while IFS='|' read -r table path; do
  printf "  [%-10s]  %s\n" "$table" "$path"
done <<< "$DRY"

echo ""
echo -e "  ${BOLD}$OLD_PATH${RESET}"
echo -e "    => ${GREEN}$NEW_PATH${RESET}"
echo ""

# Confirm
read -r -p "Apply changes? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted. No changes made."; exit 0; }

# Backup DB first
BACKUP="${DB}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$DB" "$BACKUP"
info "Database backed up to: $BACKUP"

# Apply UPDATEs
sqlite3 "$DB" "
BEGIN;

UPDATE project
SET worktree = '$NEW_PATH' || SUBSTR(worktree, LENGTH('$OLD_PATH') + 1)
WHERE worktree = '$OLD_PATH' OR worktree LIKE '$OLD_PATH/%';

UPDATE session
SET directory = '$NEW_PATH' || SUBSTR(directory, LENGTH('$OLD_PATH') + 1)
WHERE directory = '$OLD_PATH' OR directory LIKE '$OLD_PATH/%';

UPDATE workspace
SET directory = '$NEW_PATH' || SUBSTR(directory, LENGTH('$OLD_PATH') + 1)
WHERE directory = '$OLD_PATH' OR directory LIKE '$OLD_PATH/%';

COMMIT;
"

echo ""
ok "Remap complete."

# Show updated rows
echo -e "\n${BOLD}Updated rows:${RESET}\n"
sqlite3 "$DB" "
  SELECT 'project', worktree FROM project
    WHERE worktree = '$NEW_PATH' OR worktree LIKE '$NEW_PATH/%'
  UNION ALL
  SELECT 'session', directory FROM session
    WHERE directory = '$NEW_PATH' OR directory LIKE '$NEW_PATH/%'
  UNION ALL
  SELECT 'workspace', directory FROM workspace
    WHERE directory = '$NEW_PATH' OR directory LIKE '$NEW_PATH/%';
" | while IFS='|' read -r table path; do
  printf "  [%-10s]  %s\n" "$table" "$path"
done
echo ""
