# OpenCode → Pi Migration Summary

**Date:** 2026-09-10
**Branch:** `chore/opencode-to-pi-migration` → `chore/opencode-removal`

This repo previously ran two parallel AI coding agent configs — `opencode`
(`dot_config/opencode/`) and `pi` (`dot_pi/`) — with `pi` originally scoped
as "mirrors opencode for Raspberry Pi" per `dot_config/opencode/README.md`'s
history. Pi has since become the primary agent; `opencode` has been removed
entirely. This document maps every piece of removed OpenCode functionality
to its Pi equivalent.

## Behavior mapping

| Old OpenCode behavior | New Pi behavior |
|---|---|
| `opc` alias → `opencode` | `p` alias → `pi` |
| `opc-session` — standalone fzf script querying OpenCode's SQLite DB (`~/.local/share/opencode/opencode.db`) to resume a session from any directory | `pi -r` / `pi --resume` — Pi's own built-in picker. Tab toggles current-directory-only vs. all-sessions scope; automatically switches to the session's original working directory. No wrapper script needed — Pi's session storage model (one JSONL file per session under `~/.pi/agent/sessions/<escaped-cwd>/`) has no DB-path-remapping problem to work around in the first place |
| `opc-remap` — remapped `project`/`session`/`workspace` paths in the OpenCode SQLite DB after a project directory moved | **No replacement** — Pi has no equivalent problem. Each session file embeds its own `cwd` in its header; there's no separate `project`/`workspace` table to go stale, so there's nothing to remap |
| `opc-rename` — backfilled default-named sessions via a one-off Copilot API call | **No replacement needed** — superseded by `npm:pi-sessions`' built-in Auto Title extension (re-evaluates the title every 4 turns, respects manual `/name`, has its own model fallback chain). Retired Pi's own older custom `extensions/session-title.ts` (single-shot, first-turn-only) in favor of this at the same time |
| OpenCode `agent.title` config (`opencode.json` → `github-copilot/gpt-4o-mini`) for auto-titling | `pi-sessions`' `sessions.autoTitle` setting in `settings.json.tmpl` (currently `amazon-bedrock/us.amazon.nova-pro-v1:0`, thinking off) |
| `opc-login` — set `GITHUB_TOKEN` from 1Password for OpenCode's own auth needs | Renamed to `gh-login` (same body) — this was never actually OpenCode-specific, just named after it |
| `opc-document` — end-of-day KB article generator wrapper around `kb-eod.sh` | Renamed to `kb-document` (same body) — also never actually OpenCode-specific |
| `@scribe` subagent (`dot_config/opencode/agents/scribe.md`, `mode: subagent`) | Pi's `scribe` **skill** (`dot_pi/agent/skills/scribe/SKILL.md`), loaded via `/skill:scribe` or auto-loaded per the global `AGENTS.md` protocol. Different mechanism (skill vs. dedicated subagent persona), same responsibility. This was already the case before this migration — Pi never had an `agents/scribe.md` subagent, only the skill |
| `commands/{closeout,commit,init-project,summarize-issue}.md` | `dot_pi/agent/prompts/{closeout,commit,init-project,summarize-issue}.md` — already 1:1, no changes needed |
| `skills/{caveman,debug,docs,ops,schema,scribe}` | `dot_pi/agent/skills/` — already had all six plus `analyze-sessions`, `pdf-reader`, `youtube-transcript` (superset), no changes needed |
| `plugins/notification.js` | `dot_pi/agent/extensions/notification.ts` — already existed, no changes needed |
| `~/.config/opencode/bin` on `$PATH` | Removed. `~/.pi/agent/bin` was already on `$PATH`; the personal profile's dead `~/.opencode/bin` PATH entry (pointing at a package that was never installed there) was also cleaned up in the same pass |
| Known upstream OpenCode bug: `permission.edit` path patterns not evaluated (see historical GitHub issues #13872, #16331, #5395 on `anomalyco/opencode`) | Moot — Pi doesn't use OpenCode's permission-pattern system at all. Removed from this repo's `README.md` Known Issues since it no longer applies to anything in this repo |

## Files removed

- `dot_config/opencode/` (entire package): `bin/executable_opc-{remap,rename,session}`, `agents/scribe.md`, `commands/*.md`, `plugins/notification.js`, `skills/{caveman,debug,docs,ops,schema,scribe}/`, `opencode.json.tmpl`, `executable_opencode-remap.sh`, `README.md`, `SKILLS.md`, `AGENTS.md`
- `dot_pi/agent/extensions/session-title.ts` (removed in the prior commit, superseded by `pi-sessions`)

## Files changed

- `.chezmoiignore` — dropped `.config/opencode/**` android-exclusion line and updated the surrounding comment
- `dot_config/aliases.tmpl` — removed both `# OPENCODE` sections (work and personal profile branches); renamed the two genuinely-generic helper functions (`opc-login` → `gh-login`, `opc-document` → `kb-document`) rather than deleting them, since their bodies had nothing to do with OpenCode specifically
- `dot_config/tmux/tmux.conf.tmpl` — updated a comment referencing "pi/opencode TUIs" to just "pi TUIs"
- `README.md` — renamed "OpenCode / Pi agent config" section to "Pi agent config" and rewrote it pi-only (added coverage of `pi-sessions`, `enabledModels` favorites, and the global `pi -r` resume workflow); removed OpenCode from the OS-gating table and the Android/Termux extras list; removed the stale OpenCode permission-bug entry and the stale "pending tenant admin consent" WorkIQ note (WorkIQ has been enabled and confirmed working since commit `50bcc87`, well before this migration) from Known Issues

## Not migrated (no OpenCode equivalent needed)

Nothing. Every piece of OpenCode-specific functionality either already had
a Pi-native equivalent, was superseded by installing `npm:pi-sessions`, or
turned out to solve a problem (SQLite path remapping) that doesn't exist in
Pi's per-file session storage model.

## Follow-ups (manual, outside chezmoi's scope)

- **`~/.config/opencode` is now orphaned** — chezmoi no longer manages it
  (source deleted), but chezmoi doesn't auto-delete destination directories
  whose source disappears, so it's left in place untouched. Safe to
  `rm -rf ~/.config/opencode` manually once you've confirmed you don't need
  anything in it (it holds opencode's own runtime state, not anything
  chezmoi-tracked).
- If the `opencode` CLI/app itself is still installed (e.g. via `npm i -g
  opencode` or Homebrew), uninstalling it is also a manual step — outside
  this repo's scope.
- The dotfiles KB `context.md` for this project describes `op-remap`/`op-rename`
  as inline shell **functions** in `aliases` — that was inaccurate even before
  this migration; the real implementation was always standalone `bin/opc-*`
  scripts. Corrected as part of the KB update for this session (see
  `~/Documents/Notes/knowledge-base/projects/dotfiles/context.md`).
- Verify no other machine/branch still depends on `~/.local/share/opencode/opencode.db`
  before treating this migration as fully closed — that database itself is
  untouched by this migration (it lives outside the dotfiles repo) and can be
  deleted manually once you're confident nothing needs it.
