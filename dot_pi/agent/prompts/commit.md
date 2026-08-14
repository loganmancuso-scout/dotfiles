---
description: Review staged changes, generate a conventional commit message, and commit to git
---

Review the current git changes and create a commit.

1. Run `git status --short` to see which files are staged and unstaged
2. Run `git diff --cached` to read the staged diff
3. Run `git diff` to read the unstaged diff
4. Summarize what changed and why — be specific, not generic
5. Write a commit message following Conventional Commits:
   - Format: `<type>(<scope>): <subject>` — subject ≤ 50 chars
   - Types: feat, fix, refactor, chore, docs, style, test, ci
   - Add a body paragraph if the change is non-trivial (wrap at 72 chars)
6. Show the proposed message and ask for confirmation before committing
7. On confirmation: stage any unstaged changes with `git add -A`, then `git commit -m "<message>"`
8. Show `git log --oneline -1` to confirm the commit landed
