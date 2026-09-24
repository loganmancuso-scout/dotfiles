# Pi Agent Configuration

Personal pi agent with skills and workflows for knowledge base management, troubleshooting, documentation, and infrastructure operations.

---

## What This Is

This directory contains the configuration and skills for a personalized pi coding agent that provides:

- **Knowledge Base Management** — Record work, decisions, and findings systematically
- **Troubleshooting Methodology** — 7-step systematic debugging approach
- **Infrastructure Operations** — Safe command reference for kubectl, Helm, Docker, Tofu
- **Documentation Standards** — Consistent writing conventions across code and KB
- **Communication Modes** — Compressed output (caveman mode) for token efficiency

---

## Skills

The agent has 6 specialized skills, organized into a clear taxonomy:

### Executor Skills (WHEN + HOW)
These skills make decisions and execute workflows.

**`scribe`** — KB record-keeper and scratch workspace
- Writes findings to project knowledge base (sessions, decisions, investigations)
- Provides scratch workspace for planning and thinking out loud
- Integrates with docs skill (applies markdown standards)
- Integrates with schema skill (references KB structure)
- Load when: Recording work, documenting findings, using KB as workspace

**`ops`** — Infrastructure commands (safe reference)
- Kubernetes: kubectl, deployments, pods, logs, scaling
- Helm: install, upgrade, rollback, values management
- Docker: images, containers, compose, networking, cleanup
- OpenTofu/Terraform: plan, apply, destroy, state management
- Authentication: tflogin, kubeconfig setup patterns
- Timeout policies for all command types
- Load when: Executing infrastructure changes, running safe commands

### Reference Skills (HOW only)
These skills provide structure, methodology, or standards without executing.

**`schema`** — KB file structure reference (RECENTLY RENAMED from knowledge-base)
- What context.md should look like (sections, frontmatter, size targets)
- What session files should look like (sections, naming conventions)
- What decision records (ADRs) should look like (status, rationale, alternatives)
- What investigation files should look like (notes, hypotheses, handoff)
- File naming conventions and paths
- Frontmatter requirements and tag suggestions
- Load when: Understanding what a KB file should look like, structuring new files

**`debug`** — Systematic troubleshooting methodology
- 7-step evidence-based approach to finding root causes
- Step 1: Understand the system
- Step 2: Gather evidence (logs, configs, state)
- Step 3: Form hypothesis based on evidence
- Step 4: Test hypothesis with minimal probe
- Step 5: Make the fix
- Step 6: Validate the fix
- Step 7: Record findings in KB
- Integrates with ops (calls ops mid-way for commands)
- Integrates with scribe (records findings at end)
- Load when: Something is broken and you need to find why

**`docs`** — Writing standards (quality layer across ALL writing)
- Code comments: explain WHY, not WHAT; no emojis; sentence case
- JSDoc/docstrings: document contract, not implementation
- Markdown style: ATX headers, fenced code blocks, no trailing space
- README structure: Summary, Deployment, Notes, Tasks, Known Issues
- Changelog format: Keep a Changelog standards
- Emoji policy: only in markdown files, never in code
- Load when: Writing code, KB files, or documentation

### Modes (Optional Meta-Layers)

**`caveman`** — Ultra-compressed communication (75% token reduction)
- Drop articles (a, the), filler (basically, really), pleasantries (sure, certainly)
- Use fragments and short synonyms
- Keep technical terms exact
- Three intensity levels: lite, full (default), ultra
- Classical Chinese variants: wenyan-lite, wenyan-full, wenyan-ultra
- Auto-disables for security warnings and destructive operations
- Apply when: You want compressed output to save tokens

---

## Skill Taxonomy & Relationships

```
                    ┌─────────────┐
                    │   caveman   │ ← applies to ANY output
                    │(compression)│   (optional mode)
                    └─────────────┘
                          ▲
    ┌─────────────────────┼─────────────────────┐
    │                     │                     │
    ▼                     ▼                     ▼
┌─────────┐         ┌──────────┐         ┌──────────┐
│ schema  │◄────────│  scribe  │────────▶│  debug   │
│  (HOW)  │    ref  │(WHEN+HOW)│  invoke │  (HOW)   │
└─────────┘         │          │         └──────────┘
                    │          │               ▼
                    │          │         ┌──────────┐
                    │          │         │   ops    │
                    │          │         │(WHEN+HOW)│
                    │          │         └──────────┘
                    │          │               ▲
                    └──────────┼───────────────┘
                               ▼
                          ┌──────────┐
                          │   docs   │
                          │ (STYLE)  │
                          └──────────┘
```

### How to Load Skills

```
KB work (recording)       → Load scribe
Understand KB structure   → Load schema
Troubleshooting          → Load debug
Infrastructure commands  → Load ops
Writing code/docs        → Load docs
Compressed output        → Load caveman
```

### Workflow Examples

**KB Documentation (Planned Work)**
```
Load: scribe (documentation mode)
  ↓ (optionally reference)
Load: schema (if unsure of structure)
  ↓ (apply standards from)
docs (markdown conventions)
  → Session file with Goal, Work Done, Findings, Next Steps
```

**Debugging & Fixing**
```
Load: debug (7-step methodology)
  ├─ Steps 1-3: Understand, gather evidence, hypothesize
  ├─ Step 4: Test (load ops mid-way for commands)
  ├─ Steps 5-6: Fix and validate
  └─ Step 7: Record findings
      ↓ (load)
      scribe (documentation mode)
        + schema (investigation structure, optional)
        + docs (markdown standards)
```

**Production Incident Response**
```
Load: debug → ops → scribe + docs + schema
(investigate → fix → record with standards + structure)
```

---

## File Structure

```
~/.pi/agent/
├── README.md              ← You are here
├── AGENTS.md              ← Global agent instructions
├── SKILLS.md              ← Complete skills reference & decision tree
├── models.json            ← LLM model configuration
├── settings.json          ← Pi settings
├── auth.json              ← Authentication tokens
│
├── skills/                ← Specialized skills
│   ├── caveman/           ← Compressed communication mode
│   ├── debug/             ← Troubleshooting methodology
│   ├── docs/              ← Writing standards
│   ├── ops/               ← Infrastructure commands
│   ├── schema/            ← KB file structures [RENAMED from knowledge-base]
│   └── scribe/            ← KB executor + scratch workspace [ENHANCED]
│
├── prompts/               ← Custom prompt templates
│
├── bin/                   ← Utility scripts
│
└── sessions/              ← Pi session history

~/Documents/Notes/knowledge-base/projects/<project-name>/
├── context.md             ← AI-facing institutional memory (stable reference)
├── decisions/             ← Architecture Decision Records (ADRs)
│   └── YYYY-MM-DD-slug.md
├── sessions/              ← Work session logs (dated)
│   └── YYYY-MM-DD[-topic].md
└── investigations/        ← Multi-session debugging efforts
    └── <issue-slug>/
        ├── notes.md       ← Problem, hypotheses, attempts, resolution
        └── handoff.md     ← Current state, next steps (for resuming)
```

---

## Recent Changes (2026-05-29)

### Skills System Refactored ✅

**Renamed:** `knowledge-base` skill → `schema` skill
- More accurate name: "schema" clearly indicates structure reference
- Old name was misleading; implied broad protocol when it's actually just structure
- Updated all references throughout the system

**Enhanced:** `scribe` skill
- Added dual-mode design: documentation mode + scratch mode
- Integrated with `docs` skill (KB files follow markdown standards)
- Enhanced promotion workflow (SCRATCH → proper KB file)
- Added concrete examples of scratch work lifecycle

**Refactored:** Schema skill (formerly knowledge-base)
- Converted from 198 lines → 156 lines (-27%)
- Removed verbose explanations (moved to scribe)
- Eliminated 67% of redundancy with scribe
- Now pure structure reference card
- Made purpose crystal clear upfront

**Documented:** Comprehensive skills reference
- Created `SKILLS.md` (126 lines, covers everything)
- Skill at-a-glance table
- Dependency graph
- 5 detailed workflow examples
- Anti-patterns (what NOT to do)
- Decision tree for choosing skills
- Skill composition patterns
- Real-world incident response walkthrough

**Updated:** Project instructions
- `AGENTS.md` reordered skills by usage
- Clearer one-line descriptions
- All references updated to use `schema`

### Taxonomy & Architecture ✅

**Skills categorized:**
- **Executors** (WHEN + HOW): scribe, ops
- **References** (HOW only): schema, debug, docs
- **Modes**: caveman (optional, applies to output)

**Layers:**
- Layer 0 (Meta): caveman (communication)
- Layer 1 (Quality): docs (applies to all writing)
- Layer 2 (Domain): scribe+schema (KB), debug+ops (troubleshooting)

### Key Improvements ✅

1. ✅ **Purpose Clarity** — `schema` name matches its function
2. ✅ **Relationship Clarity** — scribe (executor) vs schema (reference) obvious
3. ✅ **Redundancy Eliminated** — 67% less duplication between skills
4. ✅ **Anti-patterns Documented** — Clear guidance on what NOT to do
5. ✅ **Workflows Documented** — 5+ detailed patterns with examples
6. ✅ **Comprehensive Reference** — Single authoritative SKILLS.md
7. ✅ **Taxonomy Clarity** — Logical layers with clear categorization

---

## Quick Start

### Load a Skill

```bash
# Documentation mode (record work)
/skill:scribe

# Scratch mode (thinking/planning)
/skill:scribe scratch mode

# Troubleshooting
/skill:debug

# Infrastructure commands
/skill:ops

# Writing standards
/skill:docs

# KB structure reference
/skill:schema

# Compressed output
/skill:caveman
```

### Common Workflows

**Record completed work:**
```
1. /skill:scribe (documentation mode)
2. Write: session file with Goal, Work Done, Findings, Next Steps
3. Result: KB session created with proper structure and markdown
```

**Debug production issue:**
```
1. /skill:debug (follow 7-step methodology)
2. During testing: /skill:ops (run commands)
3. After fix: /skill:scribe (record findings)
4. Result: Issue fixed + KB updated with gotchas
```

**Use KB as scratch workspace:**
```
1. /skill:scribe (scratch mode)
2. Write: SCRATCH-topic.md freely (no structure)
3. When ready to promote:
   - /skill:schema (understand target structure)
   - /skill:docs (apply markdown standards)
   - Create: proper session/decision file
   - Delete: SCRATCH file
4. Result: Working thoughts → polished KB entry
```

**Understand KB structure:**
```
1. /skill:schema (reference card)
2. Read: what context.md/session/decision/investigation should look like
3. See: frontmatter requirements, file naming, sizing targets
```

---

## How to Use This Agent

### Session Start

1. **Load context:** Agent reads project `context.md` at session start
2. **Choose skill:** Load the skill matching your task
3. **Follow skill guidance:** Each skill contains complete instructions
4. **Record findings:** Use scribe to update KB when work is meaningful

### Recording Work

**After completing work, load scribe to record:**
- Significant decisions → ADR (architecture decision record)
- Completed tasks → Session entry
- Discoveries/gotchas → Update context.md
- Multi-session issues → Investigation notes + handoff

**Before writing KB files:**
- Load docs for markdown standards
- Optionally load schema to check structure
- Scribe handles integration with both

### Troubleshooting

**When something breaks:**
1. Load debug (follow 7-step methodology)
2. Load ops mid-way (when testing/fixing)
3. Load scribe at end (record findings)
4. KB auto-updated with gotchas and prevention steps

---

## Anti-Patterns (What NOT to Do)

❌ Load schema when just writing
→ Load scribe instead; it references schema internally

❌ Load debug when fix is obvious
→ Jump straight to ops if clear path to fix

❌ Load docs for casual conversation
→ Apply docs only to code and KB files

❌ Load ops to investigate
→ Use debug for investigation; ops for executing fixes

❌ Compress security warnings
→ Always use full language for destructive operations

❌ Load caveman for critical clarity
→ Security and clarity override compression mode

---

## Configuration Files

### models.json
Defines available LLM models and which to use by default.

### settings.json
Pi configuration settings and preferences.

### auth.json
Authentication tokens (secured, do not commit).

### prompts/
Custom prompt templates for specialized tasks.

---

## Integration with Project Knowledge Base

Each project has its own knowledge base:

```
~/Documents/Notes/knowledge-base/projects/<project-name>/
├── context.md           ← stable reference
├── decisions/           ← ADRs
├── sessions/            ← work logs (and SCRATCH files)
└── investigations/      ← multi-session debugging
```

**Agent reads:** `context.md` at session start
**Agent writes:** Via scribe skill (sessions, decisions, investigations, updates to context)
**Manual:** Project README.md (deployment instructions, known issues)

---

## Documentation

### In This Directory

- **AGENTS.md** — Global agent instructions (applies to every session)
- **SKILLS.md** — Complete skills reference with workflows and decision tree
- **This file (README.md)** — Agent overview and quick start

### In Knowledge Base

- **~/Documents/Notes/knowledge-base/docs/structure.md** — KB file schemas
- **~/Documents/Notes/templates/** — KB file templates
- **~/Documents/Notes/knowledge-base/projects/*/context.md** — Per-project institutional memory

---

## No Breaking Changes

✅ All improvements are backward compatible
✅ Just renamed one skill (`knowledge-base` → `schema`)
✅ Functionality unchanged
✅ Existing workflows continue to work

Migration: Replace `knowledge-base` with `schema` in skill loads.

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Skills available | 6 |
| Skills improved | 2 |
| Skills renamed | 1 (knowledge-base → schema) |
| Redundancy reduced | 67% |
| Workflows documented | 5+ |
| Anti-patterns defined | 6 |
| Breaking changes | 0 |
| Files updated | 3 |
| Files created | 1 |

---

## Last Updated

**2026-05-29** — Skills refactor complete. Taxonomy clarified, documentation expanded, naming improved.

**Key changes:**
- Renamed knowledge-base → schema
- Enhanced scribe with dual-mode design
- Created comprehensive SKILLS.md reference
- Clarified skill relationships and workflows
- Eliminated redundancy between skills

---

## Next Steps

1. ✅ Try new skill names: `/skill:schema` (instead of knowledge-base)
2. ✅ Read SKILLS.md for complete reference
3. ✅ Follow decision tree to choose which skills to load
4. ✅ Use workflow examples to understand skill composition

---

## Need Help?

Each skill contains detailed documentation:
- `/skill:scribe` — KB recording and scratch workspace
- `/skill:schema` — KB structure reference
- `/skill:debug` — Troubleshooting methodology
- `/skill:ops` — Infrastructure commands
- `/skill:docs` — Writing standards
- `/skill:caveman` — Compressed communication

Or read `SKILLS.md` for the complete reference guide.
