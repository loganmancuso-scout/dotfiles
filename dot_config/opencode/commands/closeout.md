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

This step is read-only — do not commit, push, or merge anything here. If there are uncommitted changes, unpushed commits, or the branch isn't merged yet, note it and get explicit approval to proceed with the close-out — the actual commit/push/merge happens in step 3, after documentation, not now.

## 2. Document in the knowledge base

Load the `scribe` skill. Using the work done this session:

- Record a session summary (goal, work done, findings, next steps) per scribe's Documentation Mode
- If a significant decision was made this session, write an ADR
- If any project `README.md` exists in this repo, update it with project-facing changes (deployment steps, known issues, tasks) — scribe does not touch source files, only README.md and KB files
- If the current branch is not `main`, these README changes must land on this branch (commit them here) — not directly on `main` after merging

## 3. Merge to main

Only if step 1 found unmerged/unpushed work and the user approved proceeding:

- If the README update in step 2 produced changes, run `/commit` to commit them to the current branch
- Push the branch to its upstream if not already in sync
- Merge or open the PR to `main` — this is the last git-affecting action of the close-out, so it includes the documentation commit from step 2

If the branch was already clean, merged, and pushed in step 1, skip this step.

## 4. Session identity

opencode auto-generates the session title from the `agent.title.prompt` in `opencode.json` — no extra step needed to create it. To report it:

```bash
opencode session list --format json | jq -r --arg d "$PWD" '[.[] | select(.directory==$d)] | sort_by(.updated) | last | "\(.id)  \(.title)"'
```

Report the session ID and title plainly so this session can be found again in the session list. If the title is missing or too generic, propose a better short 3-6 word title and note that it can be renamed manually from the session list.

## 5. Closing summary

Give a short (3-6 sentence) plain-language summary of what was accomplished this session, suitable as a final handoff note.
