---
name: knowledge-base
description: >
  Project knowledge base protocol. Defines schemas, update rules, and procedures for
  maintaining the two-layer knowledge system: project README.md (human-facing) and
  ~/Documents/Notes/projects/<project-name>/context.md (AI-facing institutional memory).
  Load this skill when reading, writing, or updating either knowledge layer.
---

## Overview

Two files. Two audiences. Both stay current.

```
<project-root>/README.md
  → Human-facing. Deployment guide. Known issues. Project summary.

~/Documents/Notes/projects/<project-name>/context.md
  → AI-facing. Institutional memory. Patterns. Gotchas. Decisions. History.

~/Documents/Notes/projects/<project-name>/decisions/YYYY-MM-DD-<slug>.md
  → Per-decision ADR files. Full reasoning for significant architectural choices.
```

---

## Templates

All knowledge base files are created from templates. Always read the template before
creating a new file — do not reconstruct the schema from memory.

| File | Template |
|---|---|
| `context.md` | `~/Documents/Notes/templates/context.template.md` |
| `README.md` | `~/Documents/Notes/templates/readme.template.md` |
| `decisions/YYYY-MM-DD-<slug>.md` | `~/Documents/Notes/templates/adr.template.md` |

---

## Context File

Full path: `~/Documents/Notes/projects/<project-name>/context.md`

Copy from `~/Documents/Notes/templates/context.template.md` when creating.

### Sections

| Section | Purpose |
|---|---|
| `## Architecture` | What the project is, components, dependencies, data flow |
| `## Key Patterns & Conventions` | Non-obvious patterns: naming, config layering, secrets, structure |
| `## Gotchas & Sharp Edges` | Failure modes, surprises, things that caused problems |
| `## Past Decisions` | Index of ADRs — one line per decision, links to `decisions/` files |
| `## Maintenance Runbook` | How to deploy, roll back, update deps, rotate secrets, debug |
| `## Open Questions` | Unresolved issues and unknowns as a checklist |
| `## Session Log` | Dated entries of meaningful work done, most recent first |

### `## Past Decisions` format

This section is an index only. Full reasoning lives in ADR files.

```markdown
## Past Decisions
- 2026-04-17 — [Switch to Helm charts](decisions/2026-04-17-switch-to-helm-charts.md)
- 2026-03-01 — [Use external secrets operator](decisions/2026-03-01-external-secrets.md)
```

---

## README File

Full path: `<project-root>/README.md`

Copy from `~/Documents/Notes/templates/readme.template.md` when creating.

Sections: Summary, Deployment Instructions (Pre/Deploy/Post), Notes, Tasks, Known Issues.

---

## Architecture Decision Records (ADRs)

Full path: `~/Documents/Notes/projects/<project-name>/decisions/YYYY-MM-DD-<slug>.md`

Copy from `~/Documents/Notes/templates/adr.template.md` when creating.

### When to create an ADR

Create one when a decision:
- Is non-obvious or has meaningful tradeoffs
- Will be hard to reverse or expensive to change
- Involves choosing between real alternatives
- Future-you (or future-AI) would wonder "why did we do it this way?"

Do NOT create one for: trivial config tweaks, formatting choices, minor dependency bumps.

### Naming convention

```
YYYY-MM-DD-<short-slug>.md
```

Examples:
```
2026-04-17-switch-to-helm-charts.md
2026-03-01-use-external-secrets-operator.md
2026-01-15-migrate-postgres-to-cnpg.md
```

### ADR status values

| Status | Meaning |
|---|---|
| `proposed` | Under consideration, not yet enacted |
| `accepted` | Decision made and in effect |
| `superseded` | Replaced by a newer decision (link in `superseded-by`) |

### After creating an ADR

Add a one-line entry to `## Past Decisions` in `context.md`:
```
- YYYY-MM-DD — [Title](decisions/YYYY-MM-DD-slug.md)
```

---

## Update Rules

### What triggers a `context.md` update

| Trigger | Action |
|---|---|
| Non-obvious behavior or gotcha discovered | Add to `## Gotchas & Sharp Edges` |
| Significant decision made | Create ADR, add index entry to `## Past Decisions` |
| Feature, fix, or refactor completed | Add dated entry to `## Session Log` |
| User says "remember this" or "save this" | Add to appropriate section |
| Unresolved question identified | Add to `## Open Questions` |
| Architecture changes | Update `## Architecture` |
| New pattern established | Update `## Key Patterns & Conventions` |
| Common operation documented | Update `## Maintenance Runbook` |

### What triggers a `README.md` update

| Trigger | Action |
|---|---|
| Deployment steps change | Update `## Deployment Instructions` |
| Known issue resolved | Remove/check off from `### Known Issues` |
| New known issue discovered | Add to `### Known Issues` |
| Project purpose/scope changes | Update `## Summary` |
| Task completed | Check off in `### Tasks` |

### What does NOT trigger an update

- Typo fixes or formatting changes
- Exploratory work that produced no findings
- Changes already documented

---

## File Operations

### Reading the context file

At session start for a known project:
1. Read `~/Documents/Notes/projects/<project-name>/context.md`
2. Load its contents into working memory silently
3. Do not summarize back to user unless asked

### Writing/updating the context file

- Preserve all existing sections
- Append to `## Session Log`, never overwrite past entries
- Update `last-updated` in front matter to today's date
- Keep entries concise — this file is for AI consumption, not prose

### Creating a new context file

1. Read `~/Documents/Notes/templates/context.template.md`
2. Copy it to `~/Documents/Notes/projects/<project-name>/context.md`
3. Populate from codebase exploration — leave `<!-- to be documented -->` where unknown

### Creating a new ADR

1. Read `~/Documents/Notes/templates/adr.template.md`
2. Determine the slug: 3-5 words, lowercase, hyphenated
3. Copy template to `~/Documents/Notes/projects/<project-name>/decisions/YYYY-MM-DD-<slug>.md`
4. Fill all sections fully — rationale and alternatives considered are mandatory
5. Add index entry to `## Past Decisions` in `context.md`

### Path resolution

```
project-name  = basename of project root (directory containing .git)
context-path  = ~/Documents/Notes/projects/<project-name>/context.md
decisions-dir = ~/Documents/Notes/projects/<project-name>/decisions/
notes-root    = ~/Documents/Notes/projects/<project-name>/
```

Create directories as needed before writing.
