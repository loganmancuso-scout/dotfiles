---
description: Bootstrap the knowledge base files for the current project. Creates ~/Documents/Notes/projects/<project-name>/context.md and ensures a README.md exists in the project root.
---

You are bootstrapping the knowledge base for the current project. Follow these steps precisely.

## Step 1 — Identify the Project

1. Determine the project root by walking up from `$PWD` until you find a `.git` directory or reach `$HOME`. The directory containing `.git` is the project root.
2. Set `<project-name>` = basename of the project root directory.
3. Set `<project-root>` = absolute path to the project root.
4. Set `<context-path>` = `~/Documents/Notes/projects/<project-name>/context.md`.

Report to the user:
```
Project: <project-name>
Root:    <project-root>
Context: <context-path>
```

## Step 2 — Explore the Project

Before writing anything, explore the project root to understand what it is:
- Read `README.md` if it exists
- List top-level files and directories
- Read key config files (e.g., `package.json`, `Makefile`, `Chart.yaml`, `main.tf`, `Dockerfile`, `docker-compose.yml`, `pyproject.toml`) — whichever are present
- Identify: language/stack, deployment model, dependencies, entry points

This exploration informs both files you are about to create or update.

## Step 3 — Create or Update the Context File

Check if `<context-path>` exists.

### If it does NOT exist:

Create the directory `~/Documents/Notes/projects/<project-name>/` if needed.

Create `<context-path>` using this schema, populated with what you learned in Step 2:

```markdown
---
project: <project-name>
repo: <project-root>
last-updated: <today's date YYYY-MM-DD>
---

## Architecture

<populate from exploration — what it is, components, dependencies, data flow>

## Key Patterns & Conventions

<populate from exploration — naming conventions, config layering, structure decisions>

## Gotchas & Sharp Edges

<!-- to be documented as issues are encountered -->

## Past Decisions

<!-- to be documented as decisions are made -->

## Maintenance Runbook

<populate what is already known — known deployment commands, rollback steps, etc.>

## Open Questions

- [ ] <!-- Add unresolved questions here -->

## Session Log

### <today's date YYYY-MM-DD>
- Initialized knowledge base via /init-project. Explored project structure.
```

### If it already exists:

Read it, then update:
- `last-updated` in front matter to today
- `## Architecture` if your Step 2 exploration reveals anything not already captured
- Add a `## Session Log` entry for today: "Re-initialized / reviewed knowledge base."
- Do not overwrite or remove existing entries.

## Step 4 — Create or Update README.md

Check if `<project-root>/README.md` exists.

### If it does NOT exist:

Create it using the template structure from `~/Documents/Notes/templates/readme.template.md`, populated with what you learned in Step 2. Fill in all sections you have enough information to populate. Leave placeholder comments for sections you cannot yet fill.

### If it already exists:

Read it. If it is missing major sections from the template (Summary, Deployment Instructions, Notes/Tasks/Known Issues), add them. Do not remove or rewrite existing content — only augment.

## Step 5 — Report

Tell the user what was created or updated:

```
Done. Knowledge base initialized for <project-name>.

  Created:  ~/Documents/Notes/projects/<project-name>/context.md
  Updated:  <project-root>/README.md   (or "Already exists — reviewed only")

Run /init-project again at any time to re-sync.
```

If either file already existed and was substantively up to date, say so clearly rather than overstating the work done.
