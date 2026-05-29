---
name: docs
description: >
  Documentation writing standards and conventions. Covers inline code comments,
  JSDoc/docstrings, API docs, READMEs, changelogs, and markdown files.
  Load this skill when writing or updating any documentation — in code or in markdown.
---

Apply these standards to all documentation written in this session.

---

## Emoji Policy

**In code files and inline comments: never use emojis.** This includes:
- Inline `//` and `/* */` comments
- JSDoc / docstrings / docblocks
- TODO / FIXME / NOTE comments
- Any text embedded in source files

**In markdown files (README.md, Notes, changelogs, guides): emojis are fine** — use them where they aid scannability and don't clutter.

**If you encounter emojis in existing code comments or source files, remove them** and replace with plain text labels:
- `📝 Note:` → `Note:`
- `⚠️ Warning:` → `Warning:`
- `✅` → remove or use `[x]`
- `❌` → remove or use `[ ]`
- `🔧` → remove entirely, let the section heading speak

---

## Inline Comments

Write comments that explain **why**, not **what**. The code shows what — comments explain intent, constraints, and non-obvious decisions.

```js
// Bad: restates the code
i++ // increment i

// Good: explains why
// Skip the first byte — it's a BOM marker and confuses the parser
i++
```

Rules:
- One space after `//`
- Sentence case, no trailing period on single-line comments
- Full sentences with punctuation for multi-line block comments
- Keep comments close to the code they describe
- Delete comments when the code changes — stale comments are worse than none

---

## JSDoc / Docstrings

Document the contract, not the implementation.

```js
/**
 * Resolves the absolute path to the project root by walking up from cwd
 * until a .git directory is found.
 *
 * @param {string} cwd - Starting directory for the search
 * @returns {string} Absolute path to the project root
 * @throws {Error} If no .git directory is found before reaching filesystem root
 */
function findProjectRoot(cwd) { ... }
```

Include:
- One-line summary (what the function does, not how)
- `@param` for every parameter — name, type, description
- `@returns` with type and description
- `@throws` for every error condition
- `@example` for non-obvious usage

Omit JSDoc for: private helpers under 5 lines, self-evident getters/setters, test helpers.

---

## README Files

Follow the template at `~/Documents/Notes/templates/readme.template.md`.

Structure:
1. **Summary** — one paragraph: what it is, who uses it, where it runs
2. **Deployment Instructions** — Pre / Deploy / Post steps with exact commands
3. **Notes** — freeform operator notes
4. **Tasks** — open checklist items
5. **Known Issues** — active bugs or limitations

Style:
- Lead with the most important information
- Use exact commands, not descriptions of commands
- Write for someone on-call at 2am who has never seen this project

---

## Changelogs

Follow [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [1.2.0] - 2026-04-17

### Added
- New `/commit` command for automated conventional commits

### Changed
- Scribe is now a subagent instead of a primary agent

### Fixed
- External directory permission prompts for Notes paths

### Removed
- `code-reviewer` subagent — superseded by `/review` command
```

Group under: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

---

## General Markdown Style

- ATX headers (`#`, `##`) not setext (`===`, `---`)
- Fenced code blocks with language tag: ` ```yaml ` not bare ` ``` `
- One blank line before and after code blocks, headers, and lists
- Use `**bold**` for UI elements, key terms on first use, warnings
- Use `*italic*` for emphasis, titles, and introduced terms
- Use `> **Note:**` blockquotes for callouts — not bare bold on its own line
- Tables for structured comparisons — not bullet lists of pairs
- No trailing whitespace

---

## What NOT to document

- Obvious code (`i++`, `return nil`) — no comment needed
- Temporary debug code — delete it, don't comment it out
- Entire files commented out — use git if you need history
- Copyright headers unless the project requires them
