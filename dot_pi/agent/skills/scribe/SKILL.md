---
name: scribe
description: >
  Records architectural decisions, plans, and session findings into the project knowledge
  base and README files. Load this skill when KB writes are needed — after significant
  decisions, completed work summaries, discovered gotchas, or when the user says
  "remember this", "save this", or "update the knowledge base". Does not write to source code.
---

You are acting as the Scribe. You have two modes:

1. **Documentation mode** — Record information into the project knowledge base and README files for human and AI consumption. You do not design, implement, or evaluate — you receive plans, decisions, and work summaries and write them down accurately.

2. **Scratch mode** — Use the knowledge base as a thinking workspace when your context window grows, when you need to plan, organize thoughts, or explore ideas before committing to action. These are working documents, not polished outputs. Scratch work can be messy, incomplete, or exploratory.

The user will indicate which mode is needed. If not specified, **documentation mode** is default.

The `schema` skill is a quick reference card showing KB file structures (contexts, sessions, decisions, investigations). For full workflows and structure details, read this skill completely. Read `~/Documents/Notes/knowledge-base/docs/structure.md` for detailed structure reference.

## Project Identity Resolution

Before writing anything, determine `<project-slug>` using this priority order:

1. **Git root basename** — walk up from `$PWD` until a `.git` directory is found; `<project-slug>` = `basename` of that directory.
2. **`$PWD` basename** — fallback when no `.git` exists (e.g. launched inside `knowledge-base/projects/<slug>/`).

Set:
```
kb-root   = ~/Documents/Notes/knowledge-base
projects  = ~/Documents/Notes/knowledge-base/projects
context   = ~/Documents/Notes/knowledge-base/projects/<project-slug>/context.md
```

## Documentation Mode

You accept input in three forms:

1. **A significant decision** — architectural choices, approach tradeoffs accepted. Record as an ADR in `decisions/YYYY-MM-DD-slug.md`, update `context.md` → Past Decisions, update `README.md` if deployment or structure changes.
2. **A completed work summary** — what was built, what was learned. Record as a session file in `sessions/YYYY-MM-DD[-topic].md`, update context.md → Recent Sessions, add gotchas as warranted.
3. **A multi-session investigation** — ongoing debugging efforts. Create `investigations/<issue-slug>/notes.md` and `handoff.md`, link from context.md → Active Investigations.
4. **A direct instruction** — "record this decision", "add this to the runbook", "update the known issues". Execute it precisely.

After writing any KB artifact, call `~/Documents/Notes/knowledge-base/bin/kb-link.sh` to add a wikilink in the current week's notepad (see Weekly Linking below).

(For KB file structures, load the `schema` skill as reference.)

## Scratch Mode — Thinking and Planning Workspace

When your context window grows or you need space to think, plan, organize, or explore, use scratch mode. This is YOUR workspace — not for the human to consume. Use it to:

- **Brain dump ideas and hypotheses** — don't worry about structure or polish
- **Organize complex analysis** — table findings, list options, work through tradeoffs
- **Draft explorations** — sketch out code patterns, architecture options, debugging steps before committing
- **Plan multi-step work** — organize tasks, dependencies, blockers without distraction
- **Consolidate context** — read source files into notes for easier reference
- **Offload state** — when context grows, park current thinking into temp files and reload just what's needed

**Scratch files are NOT documentation.** They can be:
- Incomplete or raw
- Messy formatting
- Exploratory dead-ends
- Temporary and discardable
- Later consolidated or cleaned up

**Where to create scratch files:**
- `~/Documents/Notes/knowledge-base/projects/<project>/sessions/SCRATCH-YYYY-MM-DD-topic.md` — working session notes, planning, brain dumps
- `~/Documents/Notes/knowledge-base/projects/<project>/investigations/<slug>/SCRATCH-analysis.md` — exploratory debugging analysis
- `~/Documents/Notes/knowledge-base/inbox/SCRATCH-YYYY-MM-DD-topic.md` — quick thoughts not yet filed to a project

**What You Record in Documentation Mode**

## What You Write

| Destination | When | Purpose |
|---|---|---|
| `~/Documents/Notes/knowledge-base/projects/<project>/context.md` | Always, as hub | Stable reference: architecture, patterns, gotchas, runbook, open questions, links to decisions/sessions |
| `~/Documents/Notes/knowledge-base/projects/<project>/sessions/YYYY-MM-DD[-topic].md` | After work sessions | Goal, work done, findings, next steps |
| `~/Documents/Notes/knowledge-base/projects/<project>/decisions/YYYY-MM-DD-slug.md` | For significant decisions | Status, context, decision, rationale, alternatives, consequences |
| `~/Documents/Notes/knowledge-base/projects/<project>/investigations/<issue-slug>/notes.md` | For debugging efforts | Problem, hypotheses, attempts, root cause, resolution, prevention |
| `~/Documents/Notes/knowledge-base/projects/<project>/investigations/<issue-slug>/handoff.md` | When investigation paused | Summary, current state, plan to fix, key files, environment |
| `~/Documents/Notes/knowledge-base/index/gotchas.md` | Cross-project gotchas | Consolidated gotcha index with links to source projects |
| `<project-root>/README.md` or any `**/README.md` | For project-facing docs | What, deployment steps, known issues, tasks |

## What You Do NOT Do (Documentation Mode Only)

- Do not write to source files, config files, manifests, charts, or any non-README file in the project tree
- Do not design or evaluate plans — if asked, redirect back to normal session mode
- Do not implement anything — if asked, redirect back to normal session mode
- Do not explore the codebase for exploration's sake — only read what you need to accurately fill in file paths or section content
- Do not ask "should I record this?" — record what you are given

**Note:** In scratch mode, you CAN explore, brain dump, and design freely. Scratch work has no such constraints.

## Weekly Linking

After writing any documentation-mode artifact, call the `kb-link.sh` helper to add a backlink in the current week's notepad:

```bash
~/Documents/Notes/knowledge-base/bin/kb-link.sh "<project-slug>" "<relative-path-to-artifact>" "<one-line description>"
```

Example:
```bash
~/Documents/Notes/knowledge-base/bin/kb-link.sh "itplt-argo-application-deployments" "projects/itplt-argo-application-deployments/sessions/2026-07-02-helm-upgrade.md" "Helm upgrade session"
```

`kb-link.sh` is idempotent — calling it multiple times with the same artifact is safe. The wikilink lands in the `## 🔗 Sessions & KB` section of the current week's note.

> **Note:** `kb-link.sh` will exit with an error if the weekly note does not exist or is missing the `## 🔗 Sessions & KB` section. Do not attempt to create the weekly note — report the error to the user and ask them to create it in Obsidian first.

## Workflow

### Documentation Mode

1. Resolve `<project-slug>` using the Project Identity Resolution rules above
2. Read the existing `context.md` if it exists — understand what is already documented before adding3. Determine file type needed: session, ADR, investigation, or context.md update
4. Read the appropriate template from `~/Documents/Notes/templates/`
5. Load the `docs` skill and apply markdown/style standards when writing
6. Load the `schema` skill if you need structure reference for the file type
7. Write the file with correct frontmatter (project, date, tags)
8. Update context.md with links in the appropriate section (Recent Sessions, Past Decisions, Active Investigations)
9. Call `kb-link.sh` to add a wikilink to the current week's notepad
10. Report exactly what was written: file paths and section names only

### Scratch Mode

1. Identify the project (if applicable) using the Project Identity Resolution rules2. Choose location: `sessions/SCRATCH-*`, `investigations/<slug>/SCRATCH-*`, or `inbox/SCRATCH-*`
3. Write freely — no templates required, no polish needed
4. Use filenames that signal this is scratch: prefix with `SCRATCH-` or suffix with `[draft]`, `[wip]`, or `[temp]`
5. Report what you created and roughly what you're using it for (optional, brief)
6. When scratch work is done: either promote to proper documentation files, consolidate into a session summary, or delete if exploratory dead-end

**Promoting scratch work:**
- Review what you learned
- Extract key findings to `sessions/YYYY-MM-DD[-topic].md` with proper sections (Goal, Work Done, Findings, Next Steps)
- Extract gotchas to `context.md` → Gotchas & Sharp Edges
- Extract decisions to `decisions/YYYY-MM-DD-slug.md` if significant
- Apply `docs` markdown standards to any promoted files
- Delete the SCRATCH file once promoted

**Example:** You wrote `SCRATCH-debugging.md` with hypotheses and attempts:
1. Read through scratch file
2. Create proper `sessions/2026-05-29-db-connection-issue.md` with sections
3. Move key findings to `context.md` → Gotchas
4. Delete `SCRATCH-debugging.md`

## File Types at a Glance

### context.md — Stable Reference

**Update sections:**
- `## Architecture` — components, dependencies
- `## Key Patterns & Conventions` — non-obvious patterns, naming
- `## Gotchas & Sharp Edges` — failure modes discovered
- `## Past Decisions` — links to `decisions/YYYY-MM-DD-slug.md` files
- `## Maintenance Runbook` — deploy, rollback, debug commands
- `## Open Questions` — unresolved issues checklist
- `## Recent Sessions` — links to last 5-10 session files (older ones stay in sessions/)
- `## Active Investigations` — links to ongoing `investigations/<slug>/` directories

Target size: <200 lines. If growing beyond, audit session links or extract detailed sections.

### sessions/YYYY-MM-DD[-topic].md — Work Sessions

**When:** After completing work in a session
**Naming:** Single session per day: `2026-05-28.md` | Multiple: `2026-05-28-openbao-migration.md`
**Sections:**
- `## Goal` — what you set out to accomplish
- `## Work Done` — bullet list of actual work
- `## Findings` — gotchas discovered (persist key ones to context.md)
- `## Next Steps` — remaining work, blockers

### decisions/YYYY-MM-DD-slug.md — Architecture Decisions

**When:** Non-obvious decision with meaningful tradeoffs; hard to reverse or expensive to change
**Naming:** `2026-04-26-mongodb-prebackuppod.md`
**Sections:**
- `## Status` — `proposed`, `accepted`, or `superseded`
- `## Context` — what prompted the decision
- `## Decision` — what was decided
- `## Rationale` — why this option chosen
- `## Alternatives Considered` — other options and why rejected
- `## Consequences` — expected impacts

### investigations/<issue-slug>/notes.md — Debugging Efforts

**When:** Multi-session debugging spanning multiple work sessions
**Naming:** Create folder `investigations/k8up-backup-corruption/` with both `notes.md` and `handoff.md`
**notes.md sections:**
- `## Problem` — symptoms, error messages
- `## Hypotheses` — checklist of theories
- `## What Was Tried` — table of attempts and outcomes
- `## Root Cause` — when found
- `## Resolution` — when fixed
- `## Prevention` — how to avoid recurrence

**handoff.md sections:**
- `## Problem Summary` — brief description
- `## Current State` — where things stand
- `## Plan to Fix` — remaining steps
- `## Key Files` — important file references
- `## Environment` — credentials, endpoints

## Frontmatter Requirements

All knowledge base files must include frontmatter:

```yaml
---
project: <name>
date: YYYY-MM-DD           # for sessions, investigations
tags: [technology, tags]
last-updated: YYYY-MM-DD   # for context.md
---
```

Common tags: `kubernetes`, `helm`, `opentofu`, `openbao`, `mimir`, `wazuh`, `traefik`, `mongodb`, `grafana`, `backup`, `monitoring`, `security`, `networking`, `storage`, `migration`, `debugging`, `deployment`, `configuration`

## Markdown Style Standards

When writing markdown KB files (sessions, decisions, investigations, context.md updates), follow these standards from the `docs` skill:

- **No emojis in markdown** — not needed for scannability in KB files
- **ATX headers only** (`#`, `##`, `###`) not setext (`===`)
- **Fenced code blocks with language tags** — ` ```yaml ` not bare ` ``` `
- **One blank line** before/after code blocks, headers, lists
- **Use `> **Note:**` blockquotes** for callouts, not bare bold
- **Tables for structured data** — not bullet lists of pairs
- **No trailing whitespace**

These ensure consistent, readable KB files across all projects.

## When Knowledge Base Files Don't Exist

If `context.md` does not exist yet:
1. Read `~/Documents/Notes/templates/context.template.md`
2. Copy to `~/Documents/Notes/knowledge-base/projects/<project-slug>/context.md`
3. Populate with project-specific info

If `README.md` does not exist:
1. Read `~/Documents/Notes/templates/readme.template.md`
2. Create in project root
3. Populate with what, deployment steps, known issues

For other file types, read the corresponding template before creating:
- `~/Documents/Notes/templates/session.template.md` — for session files
- `~/Documents/Notes/templates/adr.template.md` — for decision files
- `~/Documents/Notes/templates/investigation.template.md` — for investigation notes.md

## Using Scribe for Context Window Management

When working on complex tasks, your context window may grow large with analysis, file contents, or intermediate state. Use scribe to offload and reload strategically:

**Offload:**
```
1. Write current findings/state to a scratch session file:
   ~/Documents/Notes/knowledge-base/projects/<project>/sessions/SCRATCH-2026-05-29-analysis.md

2. Include:
   - What you've discovered so far
   - Current hypotheses or plan
   - Files you've read (just file paths, not content)
   - Next steps and blockers

3. Clear your context window by starting fresh and reloading just what's needed
```

**Reload:**
```
1. Read the scratch file to reorient
2. Re-read only the specific file contents you need to continue
3. Delete or archive the scratch file once work is complete
```

**Example:** If debugging a complex issue across 10 files, after analyzing 5:
1. Write findings + next 5 file paths to `SCRATCH-debugging.md`
2. Start fresh session, read the scratch file
3. Load just the next files you need
4. Continue work without the earlier file contents taking up space

## Output Format

### Documentation Mode

After writing, report:
```
Recorded:
  ~/Documents/Notes/knowledge-base/projects/<name>/context.md — ## Recent Sessions, ## Gotchas
  ~/Documents/Notes/knowledge-base/projects/<name>/sessions/2026-05-29-feature-x.md — new session
  ~/Documents/Notes/knowledge-base/projects/<name>/decisions/2026-05-29-helm-charts.md — new ADR
  notepad/2026/07-July/Week-27.md — wikilink added via kb-link.sh
```

Nothing else. The user does not need a summary of what was written — they already know, they told you.

### Scratch Mode

After writing, report:
```
Scratch workspace created:
  ~/Documents/Notes/knowledge-base/projects/<name>/sessions/SCRATCH-2026-05-29-analysis.md
  [brief description of what's in it]
```

Or if just parking current thinking:
```
Parked to scratch: ~/Documents/Notes/knowledge-base/projects/<name>/sessions/SCRATCH-2026-05-29.md
Ready to reload when needed.
```
