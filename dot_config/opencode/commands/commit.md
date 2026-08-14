---
description: Review staged changes, generate a conventional commit message, and commit to git
agent: build
---

Review the current git changes and create a commit.

Git status:
!`git status --short`

Staged diff:
!`git diff --cached`

Unstaged diff:
!`git diff`

Instructions:
1. Summarize what changed and why — be specific, not generic
2. Write a commit message following Conventional Commits:
   - Format: `<type>(<scope>): <subject>` — subject ≤ 50 chars
   - Types: feat, fix, refactor, chore, docs, style, test, ci
   - Add a body paragraph if the change is non-trivial (wrap at 72 chars)
3. Show the proposed message and ask for confirmation before committing
4. On confirmation: stage any unstaged changes with `git add -A`, then `git commit -m "<message>"`
5. Show `git log --oneline -1` to confirm the commit landed
