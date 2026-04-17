# OpenCode Global Agent Instructions

These instructions apply to every opencode session, regardless of working directory or agent.

---

## Knowledge Base Protocol

You maintain a two-layer knowledge system for every project you work on.

### Layer 1 — Project README.md (human-facing)

Located in the project root. Written for humans. Keep it current as you work.

Covers:
- What the project is and what it does
- Deployment instructions (pre, deploy, post steps)
- Known issues and open tasks

Use the template structure from `~/Documents/Notes/templates/readme.template.md` if no README exists.

### Layer 2 — AI Context File (AI-facing)

Located at: `~/Documents/Notes/projects/<project-name>/context.md`

This is YOUR knowledge base — institutional memory written by you, for you. It is not for humans to consume directly. Read it at the start of every session in the current project.

Covers:
- Architecture and component relationships
- Key patterns and conventions in this codebase
- Gotchas, sharp edges, and non-obvious behaviors
- Past decisions and the reasoning behind them
- Maintenance runbook (how to safely make common changes)
- Open questions and unresolved issues
- Session history (brief dated entries of what was done)

---

## Session Start Procedure

1. Identify the current project from `$PWD`.
   - Walk up to find `.git`. The directory containing `.git` is the project root.
   - Derive `<project-name>` from the final directory component.

2. Check for `~/Documents/Notes/projects/<project-name>/context.md`.
   - If it exists: read it silently before doing any work. Do not summarize it back to the user unless asked.
   - If it does not exist: note that this project has no context file yet. Offer to run `/init-project` to bootstrap it, or create it automatically when you first learn something worth keeping.

3. Proceed with the user's request.

---

## Recording Decisions — Use @scribe

Do not write to the knowledge base or README files yourself. Instead, invoke the `@scribe` subagent to handle all knowledge base writes. Scribe has the correct permissions and follows the proper schema.

Invoke `@scribe` when:
- A significant architectural decision was made — scribe creates an ADR and updates `context.md`
- A meaningful unit of work is complete — scribe writes a session log entry
- A non-obvious behavior or gotcha was discovered — scribe adds it to `context.md`
- Deployment steps, known issues, or project summary have changed — scribe updates `README.md`
- The user says "remember this", "save this", or "update the knowledge base"
- The session is wrapping up and anything meaningful was learned

Do not invoke `@scribe` for: typo fixes, trivial formatting changes, exploratory work with no findings, or things already documented.

**How to invoke:** Pass scribe a clear, factual summary of what to record. Include: what was decided or discovered, why, and what changed. Scribe will determine the correct files and sections — you do not need to specify them.

---

## Project Name Derivation

Given `$PWD`, resolve the project name as follows:
- Walk up from `$PWD` until you find a `.git` directory or reach `$HOME`.
- The directory containing `.git` is the project root.
- `<project-name>` = the basename of that directory (e.g., `core-cluster` from `.../Infrastructure/core-cluster`).
- If no `.git` is found, use the basename of `$PWD`.

---

## Subagents

The following subagents are available. Invoke them with `@<name>` or via the task tool.

- `@scribe` — records decisions, session findings, and knowledge base updates. Invoke instead of writing to Notes or README yourself. See "Recording Decisions" above.

---

## Commands

The following slash commands are available in any session:

- `/commit` — review staged changes, generate a conventional commit message, and commit to git
- `/init-project` — bootstrap the knowledge base for the current project (creates `context.md` and `README.md`)
- `/summarize-issue` — summarize a GitHub issue

---

## Skills

Load the `knowledge-base` skill for detailed schema and update rules when working on project knowledge files.

The following skills are available:
- `knowledge-base` — project knowledge base protocol and file schemas
- `docs` — documentation writing standards: inline comments, JSDoc, READMEs, changelogs, emoji policy
- `ops` — command reference for kubectl, Helm, Docker, and OpenTofu operations
- `debug` — triage and diagnosis for infra and application failures; load ops to execute the fix
- `caveman` — ultra-compressed communication mode (~75% token reduction)
