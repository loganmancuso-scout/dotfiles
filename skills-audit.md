# Pi Skills Audit

**Date:** 2026-09-10
**Scope:** All skills under `dot_pi/agent/skills/`, plus `dot_pi/agent/AGENTS.md`
(global instructions, loaded every session) and `dot_pi/agent/agents/*.md`
(subagent definitions), since staleness in those files has the same
blast radius as staleness in a skill. Compared against this project's own
knowledge base (`~/Documents/Notes/knowledge-base/projects/dotfiles/`) and
git history for ground truth on anything that changed recently.

## Summary

| File | Issues found | Changes made | Confidence |
|---|---|---|---|
| `dot_pi/agent/AGENTS.md` | Commands list missing `/closeout`; Skills list missing 3 of 9 skills (`analyze-sessions`, `pdf-reader`, `youtube-transcript`) | Added both | High |
| `skills/debug/SKILL.md` | `invoke @scribe` uses OpenCode's subagent-mention syntax — Pi has no `agents/scribe.md`, only the `scribe` skill | Changed to `load the scribe skill (/skill:scribe)` | High |
| `skills/ops/SKILL.md.tmpl` | Personal-profile `tflogin`/`kconf` examples used `dev-core`/`core` — renamed to `dev`/`prd` in commit `67e2f25` (2026-09-08), two days before this audit; the shared "which environment" prompt hint was stale for **both** profiles (neither uses `dev-core, core` anymore) | Updated personal-branch examples to `dev`/`prd`; profile-gated the environment-hint example instead of a single shared (and now-wrong-for-both) string | High — confirmed directly against the git diff that made the rename, not inference |
| `skills/analyze-sessions/SKILL.md` | None found | None | High |
| `skills/caveman/SKILL.md` | None found | None | High |
| `skills/docs/SKILL.md` | None found (the `@param`/`@returns`/`@throws` matches from the repo-wide grep are JSDoc tag examples, not agent-mention syntax — correct as-is) | None | High |
| `skills/pdf-reader/SKILL.md` | None found | None | High |
| `skills/schema/SKILL.md` | None found — already correctly says "load `/skill:scribe`" | None | High |
| `skills/scribe/SKILL.md` | None found | None | High |
| `skills/youtube-transcript/SKILL.md` | None found | None | High |
| `dot_pi/agent/agents/{researcher,scout,worker}.md` | None found | None | Medium — not deeply cross-checked against KB, just scanned for OpenCode refs and obviously stale infra naming |

## Detail

### `dot_pi/agent/AGENTS.md` — Commands and Skills lists out of date

This file is loaded on **every** session (per its own "Session Start
Procedure"), so drift here is the highest-blast-radius kind. Two gaps found
by directly diffing the documented lists against what's actually on disk:

- `## Commands` listed `/commit`, `/init-project`, `/summarize-issue` but not
  `/closeout`, even though `dot_pi/agent/prompts/closeout.md` exists and is
  referenced elsewhere (e.g. the `debug` skill's Step 7).
- `## Skills` listed 6 of the 9 skills present in `dot_pi/agent/skills/` —
  missing `analyze-sessions`, `pdf-reader`, `youtube-transcript`.

Both lists now match what's actually installed.

### `skills/debug/SKILL.md` — stale OpenCode subagent syntax

Step 7 ("Record Findings") said `invoke @scribe with a summary of...`. `@name`
subagent-mention syntax is an OpenCode convention (OpenCode had a dedicated
`agents/scribe.md` subagent, `mode: subagent`, invoked via `@scribe`). Pi
never had that subagent — scribe has always been a **skill** here, loaded
via `/skill:scribe`, consistent with how `schema/SKILL.md` already phrases
the same cross-reference correctly ("load `/skill:scribe`"). This was
already inconsistent with Pi's actual model before the OpenCode removal
work in this same migration — it just hadn't been caught yet. Fixed to
match `schema`'s phrasing.

### `skills/ops/SKILL.md.tmpl` — environment naming rename not propagated

`tflogin`/`tfunseal` (personal profile, `dot_config/aliases.tmpl`) were
refactored in commit `67e2f25` to accept `dev`/`prd` instead of `dev-core`/
`core`, matching a parallel rename of the underlying 1Password items
(`prd-openbao`, `rustfs prd-automation-accesskey`, etc.). That commit only
touched `aliases.tmpl` — the `ops` skill's personal-profile examples still
showed the old `dev-core`/`core` values, which would now fail outright
(`tflogin` validates its argument against an allowlist and errors on
anything else). Updated the three affected examples. Also caught that the
shared (non-profile-gated) "which environment are we targeting?" example
hint used the same stale `dev-core, core` naming — and would have been
wrong for the **work** profile too, which actually uses `core`/`app-prd`/
`app-uat` (verified against real files in `~/.kube` on the work machine).
Split that hint into a profile-gated pair matching each profile's real
naming.

## Not flagged as issues (verified correct, worth noting why)

- `skills/docs/SKILL.md`'s changelog example says "Scribe is now a subagent
  instead of a primary agent" — this is a generic illustrative changelog
  entry demonstrating Keep-a-Changelog format, not a claim about this
  repo's actual scribe implementation. Left as-is.
- `skills/ops/SKILL.md.tmpl` work-profile `kconf core.yaml` / `app-prd.yaml`
  / `app-uat.yaml` examples were verified against the real `~/.kube/`
  directory contents on the work machine — accurate, no change needed.
- No skill referenced Azure, and the only cloud/infra skill (`ops`) covers
  kubectl/Helm/Docker/OpenTofu generically without embedding
  provider-specific assumptions beyond the two profiles' own known-good
  aliases — nothing AWS- or Azure-specific to audit there.

## Recommendations (not applied — judgment calls, not clear-cut fixes)

- Consider adding a lightweight CI-less check (e.g. a `chezmoi execute-template`
  + `grep` sweep, similar to what was run manually during this audit) that
  fails a pre-commit/pre-push hook if `dot_pi/agent/AGENTS.md`'s Commands/
  Skills lists don't match the actual files on disk. This class of drift
  (a real file added, the summary list not updated) has now happened at
  least twice (this audit, and previously per `context.md`'s note about
  materialized skill files drifting from repo source).
- `dot_pi/agent/agents/{researcher,scout,worker}.md` weren't audited against
  the KB as deeply as the skills — they're sourced from an external repo
  (`amosblomqvist/pi-interactive-subagents` per `README.md`) and mostly
  inherit their behavior from upstream. If they're modified locally again,
  worth a dedicated pass.
- No formal versioning/changelog exists for the skills themselves — a skill
  that silently drifts out of sync with a related shell function (as `ops`
  did with `tflogin`) has no automated tripwire. Worth deciding whether
  that's worth the overhead for a personal dotfiles repo, or whether manual
  audits like this one are sufficient cadence.
