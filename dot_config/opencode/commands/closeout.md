---
description: Wrap up the current session — git status, KB write-up, README update, session title/ID
agent: build
---

Close out this session. Work through these steps in order and report results as you go.

Current branch:
!`git branch --show-current`

Working tree status:
!`git status --short`

Commits on this branch not on main:
!`git log --oneline main..HEAD 2>/dev/null`

Merged into main check:
!`git merge-base --is-ancestor HEAD main 2>/dev/null && echo merged || echo not-merged`

Upstream tracking status:
!`git status -sb | head -1`

## 1. Git status

Using the output above, report clearly:
- current branch name
- clean or dirty working tree
- merged into `main`: yes/no
- pushed to upstream: yes/no, and ahead/behind counts if diverged

If there are uncommitted changes, unpushed commits, or no PR open yet, stop and ask whether to run `/commit`, push, and open a PR before continuing — do not do this automatically.

## 2. Document in the knowledge base

Load the `scribe` skill. Using the work done this session:

- Record a session summary (goal, work done, findings, next steps) per scribe's Documentation Mode
- If a significant decision was made this session, write an ADR
- If any project `README.md` exists in this repo, update it with project-facing changes (deployment steps, known issues, tasks) — scribe does not touch source files, only README.md and KB files

## 3. Session identity

opencode auto-generates the session title from the `agent.title.prompt` in `opencode.json` — no extra step needed to create it. To report it:

```bash
opencode session list --format json | jq -r --arg d "$PWD" '[.[] | select(.directory==$d)] | sort_by(.updated) | last | "\(.id)  \(.title)"'
```

Report the session ID and title plainly so this session can be found again in the session list. If the title is missing or too generic, propose a better short 3-6 word title and note that it can be renamed manually from the session list.

## 4. Closing summary

Give a short (3-6 sentence) plain-language summary of what was accomplished this session, suitable as a final handoff note.
