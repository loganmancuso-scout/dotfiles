---
name: schema
description: >
  Knowledge base schema reference. Quick-lookup guide for KB file paths, naming
  conventions, and update triggers. Shows WHERE things live and WHEN to update them.
  For full file schemas and detailed structure, load /skill:scribe or read the templates
  in ~/Documents/Notes/templates/. This skill is a path reference, not a workflow executor.
---

**Quick path reference for the KB system. For file schemas and workflows, load `/skill:scribe`.**

Two-layer system:
- `<project-root>/README.md` — human-facing deployment guide
- `~/Documents/Notes/knowledge-base/projects/<project-slug>/context.md` — AI-facing institutional memory
- `~/Documents/Notes/knowledge-base/projects/<project-slug>/decisions/` — Architecture Decision Records
- `~/Documents/Notes/knowledge-base/projects/<project-slug>/sessions/` — Work session logs
- `~/Documents/Notes/knowledge-base/projects/<project-slug>/investigations/` — Multi-session debugging

---

## Project Identity Resolution

Determine `<project-slug>` in this priority order:

1. `basename` of the nearest `.git` root (walk up from `$PWD`)
2. `basename` of `$PWD` (fallback for no-git sessions launched inside `knowledge-base/projects/<slug>/`)

---

## File Paths

| File | Path |
|---|---|
| Context | `~/Documents/Notes/knowledge-base/projects/<project-slug>/context.md` |
| README | `<project-root>/README.md` |
| Decision | `~/Documents/Notes/knowledge-base/projects/<project-slug>/decisions/YYYY-MM-DD-<slug>.md` |
| Session | `~/Documents/Notes/knowledge-base/projects/<project-slug>/sessions/YYYY-MM-DD[-topic].md` |
| Investigation | `~/Documents/Notes/knowledge-base/projects/<project-slug>/investigations/<slug>/notes.md` |
| Scratch | `~/Documents/Notes/knowledge-base/projects/<project-slug>/sessions/SCRATCH-YYYY-MM-DD-topic.md` |
| Inbox scratch | `~/Documents/Notes/knowledge-base/inbox/SCRATCH-YYYY-MM-DD-topic.md` |
| Cross-project gotchas | `~/Documents/Notes/knowledge-base/index/gotchas.md` |
| KB structure reference | `~/Documents/Notes/knowledge-base/docs/structure.md` |

Templates live in `~/Documents/Notes/templates/` — always read the template before creating a new file.

---

## Scratch Workspace

Use the KB as a scratch workspace when you need to think, plan, or offload context. Scratch files are temporary — they are not polished documentation.

**When to create scratch files:**
- Planning a complex multi-step task before presenting it to the user
- Parking intermediate analysis when your context window grows
- Exploring options or hypotheses before committing to an approach

**Where:** `sessions/SCRATCH-YYYY-MM-DD-topic.md` — prefix with `SCRATCH-` to signal temporary

**After scratch work is done:** extract key findings to proper session, decision, or context files, then delete the scratch file.

---

## Update Triggers

| Trigger | Action |
|---|---|
| Gotcha discovered | Add to `context.md` → `## Gotchas & Sharp Edges` |
| Significant decision | Create ADR in `decisions/`, index in `context.md` → `## Past Decisions` |
| Work completed | Create session in `sessions/`, link in `context.md` → `## Recent Sessions` |
| Architecture change | Update `context.md` → `## Architecture` |
| Pattern identified | Update `context.md` → `## Key Patterns & Conventions` |
| Question unresolved | Add to `context.md` → `## Open Questions` |
| Operation documented | Update `context.md` → `## Maintenance Runbook` |
| Deployment steps change | Update `README.md` → `## Deployment Instructions` |
| Known issue found/resolved | Update `README.md` → `### Known Issues` |
| Any KB artifact written | Call `kb-link.sh` to add wikilink to current `notepad/Week-NN.md` |

---

## Path Resolution

```
project-slug  = basename(nearest .git)  OR  basename($PWD)
kb-root       = ~/Documents/Notes/knowledge-base
projects-dir  = ~/Documents/Notes/knowledge-base/projects
context-path  = ~/Documents/Notes/knowledge-base/projects/<project-slug>/context.md
decisions-dir = ~/Documents/Notes/knowledge-base/projects/<project-slug>/decisions/
sessions-dir  = ~/Documents/Notes/knowledge-base/projects/<project-slug>/sessions/
invest-dir    = ~/Documents/Notes/knowledge-base/projects/<project-slug>/investigations/
```
