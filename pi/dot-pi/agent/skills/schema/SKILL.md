---
name: schema
description: >
  Knowledge base schema reference. Quick-lookup guide for KB file structures, templates,
  and frontmatter. Shows HOW KB files should look. For WHEN to write and complete workflows,
  load /skill:scribe. This skill is structure reference only — not a workflow executor.
---

**Quick schema reference for KB file structures. For workflows and decision logic, load `/skill:scribe`.**

Two-layer system:
- `<project-root>/README.md` — human-facing deployment guide
- `~/Documents/Notes/projects/<project-name>/context.md` — AI-facing institutional memory
- `~/Documents/Notes/projects/<project-name>/decisions/` — Architecture Decision Records
- `~/Documents/Notes/projects/<project-name>/sessions/` — Work session logs
- `~/Documents/Notes/projects/<project-name>/investigations/` — Multi-session debugging

---

## File Paths

| File | Path | Template |
|---|---|---|
| Context | `~/Documents/Notes/projects/<project-name>/context.md` | `context.template.md` |
| README | `<project-root>/README.md` | `readme.template.md` |
| Decision | `~/Documents/Notes/projects/<project-name>/decisions/YYYY-MM-DD-<slug>.md` | `adr.template.md` |
| Session | `~/Documents/Notes/projects/<project-name>/sessions/YYYY-MM-DD[-topic].md` | `session.template.md` |
| Investigation | `~/Documents/Notes/projects/<project-name>/investigations/<slug>/notes.md` | `investigation.template.md` |

---

## context.md Schema

| Section | Content |
|---|---|
| `## Architecture` | Components, dependencies, data flow |
| `## Key Patterns & Conventions` | Non-obvious patterns, naming, config, structure |
| `## Gotchas & Sharp Edges` | Failure modes, surprises, sharp edges |
| `## Past Decisions` | Index: `- YYYY-MM-DD — [Title](decisions/file.md)` |
| `## Maintenance Runbook` | Deploy, rollback, debug, update commands |
| `## Open Questions` | Unresolved issues checklist |
| `## Recent Sessions` | Links to last 5-10 session files |
| `## Active Investigations` | Links to ongoing investigations |

**Frontmatter:**
```yaml
---
project: <name>
last-updated: YYYY-MM-DD
tags: [tech, tags]
---
```

**Size target:** <200 lines

---

## sessions/YYYY-MM-DD[-topic].md Schema

| Section | Content |
|---|---|
| `## Goal` | What you set out to accomplish |
| `## Work Done` | Bullet list of actual work |
| `## Findings` | Gotchas discovered (persist key ones to context.md) |
| `## Next Steps` | Remaining work, blockers |

**Frontmatter:**
```yaml
---
project: <name>
date: YYYY-MM-DD
tags: [tech, tags]
---
```

**Naming:** Single session: `2026-05-28.md` | Multiple per day: `2026-05-28-topic.md`

---

## decisions/YYYY-MM-DD-slug.md Schema (ADR)

| Section | Content |
|---|---|
| `## Status` | `proposed`, `accepted`, or `superseded` |
| `## Context` | What prompted the decision |
| `## Decision` | What was decided |
| `## Rationale` | Why this option chosen |
| `## Alternatives Considered` | Other options, why rejected |
| `## Consequences` | Expected impacts |

**Create ADR when:** Non-obvious, meaningful tradeoffs, hard to reverse, expensive to change.

**Don't create ADR for:** Trivial config tweaks, formatting, minor bumps.

**Naming:** `2026-04-26-mongodb-prebackuppod.md` (date-short-slug)

---

## investigations/<slug>/notes.md Schema

| Section | Content |
|---|---|
| `## Problem` | Symptoms, error messages |
| `## Hypotheses` | Checklist of theories |
| `## What Was Tried` | Table: attempts → outcomes |
| `## Root Cause` | When found |
| `## Resolution` | When fixed |
| `## Prevention` | How to avoid recurrence |

**Also create:** `investigations/<slug>/handoff.md` for resuming investigation.

**handoff.md sections:** Problem Summary, Current State, Plan to Fix, Key Files, Environment.

---

## README.md Schema

| Section | Content |
|---|---|
| Summary | One paragraph: what, who uses it, where |
| Deployment Instructions | Pre / Deploy / Post with exact commands |
| Notes | Freeform operator notes |
| Tasks | Open checklist items |
| Known Issues | Active bugs, limitations |

---

## Update Triggers

### context.md updates
- Gotcha discovered → `## Gotchas & Sharp Edges`
- Significant decision → ADR + `## Past Decisions`
- Work completed → `## Recent Sessions` link
- Architecture change → `## Architecture`
- Pattern identified → `## Key Patterns & Conventions`
- Question unresolved → `## Open Questions`
- Operation documented → `## Maintenance Runbook`

### README.md updates
- Deployment steps change → `## Deployment Instructions`
- Issue resolved → remove from `### Known Issues`
- Issue discovered → add to `### Known Issues`
- Task completed → check off `### Tasks`

---

## Path Resolution

```
project-name = basename of directory containing .git
context-path = ~/Documents/Notes/projects/<project-name>/context.md
decisions-dir = ~/Documents/Notes/projects/<project-name>/decisions/
sessions-dir = ~/Documents/Notes/projects/<project-name>/sessions/
invest-dir = ~/Documents/Notes/projects/<project-name>/investigations/
```
