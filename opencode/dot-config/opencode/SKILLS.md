# Pi Skills Reference

This document explains the 6 skills available in pi, how they work together, and when to load each one.

**TL;DR:** Load `scribe` for KB work, `debug` for troubleshooting, `ops` for infrastructure commands, `docs` for writing standards, `schema` for KB structure reference, `caveman` for compressed output.

---

## Skills at a Glance

| Skill | Type | Purpose | Load When |
|-------|------|---------|-----------|
| **scribe** | Executor | Record work in KB, use KB as scratch workspace | You need to write findings to KB or think out loud |
| **schema** | Reference | KB file structures (context, sessions, decisions, investigations) | You need to understand what a KB file should look like |
| **debug** | Methodology | Systematic 7-step troubleshooting approach | Something is broken and you need to find why |
| **ops** | Reference | Infrastructure commands (kubectl, helm, docker, tofu) | You need to execute infrastructure changes safely |
| **docs** | Standards | Writing conventions (code comments, markdown, READMEs) | You're writing code, KB files, or documentation |
| **caveman** | Mode | Ultra-compressed communication (~75% token reduction) | You want terse output to save tokens |

---

## Skill Categories

### Executor Skills (WHEN + HOW)
These skills handle both decision logic and execution:
- **scribe** — When should I write this? How do I structure it? How do I promote scratch work?
- **ops** — When should I execute this command? How do I safely apply it?

### Reference Skills (HOW only)
These skills provide structure or methodology without executing:
- **schema** — How should this KB file look?
- **debug** — How do I systematically troubleshoot?
- **docs** — How should this be formatted?

### Modes (applies to output)
- **caveman** — How compressed should my output be?

---

## Skill Dependency Map

```
                    ┌─────────────┐
                    │   caveman   │ ← optional: compress output
                    └─────────────┘
                          ▲
    ┌─────────────────────┼─────────────────────┐
    │                     │                     │
    ▼                     ▼                     ▼
┌─────────┐         ┌──────────┐         ┌──────────┐
│ schema  │◄────────│  scribe  │────────▶│  debug   │
│ (HOW)   │  (read) │(WHEN+HOW)│(invoke) │(HOW)     │
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

---

## Common Workflows

### Workflow: Record Completed Work in KB

```
1. Load: scribe (documentation mode)
2. Write: session file (Goal, Work Done, Findings, Next Steps)
3. Apply: docs standards (from scribe's integration)
4. Optional: Load schema to check structure
Result: KB session file created with proper formatting
```

---

### Workflow: Debug Production Issue

```
1. Load: debug (follow 7-step methodology)
   - Steps 1-3: Understand, gather evidence, hypothesize
   - Step 4: Test hypothesis (may load ops mid-way)
   - Step 5-6: Fix and validate
   - Step 7: Record findings

2. When testing: Load ops (execute commands)
3. When recording: Load scribe (document findings)
   - Apply: docs standards (markdown)
   - Load: schema (if creating investigation notes)

Result: Production fixed + KB updated with gotchas/findings
```

---

### Workflow: Refactor Code + Update KB

```
1. Load: docs (apply code comment standards)
2. Write/refactor code with comments explaining WHY
3. Load: scribe (documentation mode)
4. Write: ADR decision record explaining the refactor
   - Load: schema (ADR structure reference)
   - Apply: docs (markdown standards)
5. Update: README if deployment changed

Result: Code updated + KB decision recorded + docs standards applied
```

---

### Workflow: Use KB as Scratch Workspace

```
1. Load: scribe (scratch mode)
2. Write: SCRATCH-topic.md freely (no structure needed)
3. Organize: hypotheses, analysis, exploration
4. When promoting to final:
   - Load: schema (understand target structure)
   - Load: docs (markdown standards)
   - Create: proper session/decision/investigation file
   - Delete: SCRATCH file

Result: Working thoughts converted to polished KB entry
```

---

## When NOT to Load Skills

| Anti-Pattern | Why | What to Do Instead |
|---|---|---|
| Load schema when just writing | scribe already handles structure | Load scribe; it references schema internally |
| Load debug when you know the fix | Wastes time on methodology | Jump to ops if fix is obvious |
| Load docs for casual conversation | Over-formalizes prose | Use docs only for code/KB/README |
| Load ops to investigate | ops is for executing, not probing | Use debug for investigation; ops for fix |
| Compress security warnings with caveman | Clarity is critical | Always use full language for destructive ops |

---

## Skill Loading Strategies

### Strategy 1: Single Skill (Common Cases)

Use one skill for straightforward tasks:

```
- KB writing → Load scribe
- Infrastructure commands → Load ops
- Troubleshooting → Load debug
- Writing code/docs → Load docs
- Token efficiency → Load caveman
```

### Strategy 2: Skill Pair (Most Common)

Combine skills for natural workflows:

```
- debug + ops         = troubleshoot and fix
- scribe + schema     = write and reference structure
- scribe + docs       = write with style standards
- debug + scribe      = troubleshoot and record
```

### Strategy 3: Skill Chain (Complex Workflows)

Load skills in sequence as workflow requires:

```
debug → ops → scribe → schema + docs
(investigate, fix, record findings, structure with standards)
```

---

## Each Skill Explained

### scribe — KB Record-Keeper + Scratch Workspace

**Purpose:** Write findings to KB or use KB as thinking space

**Two modes:**
1. **Documentation mode** — Executor. Writes polished KB files.
   - Decides WHEN to write what (session, decision, investigation?)
   - Executes HOW to write it (structure, frontmatter, sections)
   - Integrates with docs (markdown standards)
   - Integrates with schema (file structures)

2. **Scratch mode** — Workspace. Fast, unpolished, flexible.
   - Brain dump, plan, explore without structure
   - Promote to proper KB files when ready
   - Delete when done

**Load when:** You need to record work, document findings, or use KB as workspace

**Integrates with:** docs (markdown standards), schema (file structures)

---

### schema — KB Structure Reference

**Purpose:** Quick-lookup guide for KB file structures

**Covers:**
- What a context.md should look like
- What a session file should look like
- What a decision (ADR) should look like
- What an investigation should look like
- Frontmatter requirements
- File paths and naming conventions

**Is NOT:** A workflow executor. Just structure reference.

**Load when:** You need to understand what a KB file should look like

**Used by:** scribe (when writing KB files)

---

### debug — Systematic Troubleshooting Methodology

**Purpose:** 7-step evidence-based approach to finding root causes

**Steps:**
1. Understand the system
2. Gather evidence (logs, configs, state)
3. Form hypothesis
4. Test hypothesis
5. Make fix
6. Validate
7. Record findings

**Is:** A methodology. Not an executor. May invoke ops mid-way.

**Load when:** Something is broken and you need to find why

**Integrates with:** ops (for commands), scribe (for recording)

---

### ops — Infrastructure Commands

**Purpose:** Safe, correct reference for kubectl, helm, docker, tofu

**Covers:**
- Kubernetes (deployments, pods, logs, etc.)
- Helm (install, upgrade, rollback, etc.)
- Docker (images, containers, compose, etc.)
- OpenTofu/Terraform (plan, apply, state, etc.)
- Auth patterns (tflogin, kubeconfig setup)
- Timeout policies

**Is:** Command reference. Not a methodology.

**Load when:** You need to execute infrastructure commands

**Integrates with:** debug (commands to test hypotheses or fix), scribe (record changes)

---

### docs — Writing Standards

**Purpose:** Consistency across all documentation

**Covers:**
- Code comments (no emojis, explain WHY not WHAT)
- JSDoc/docstrings (contracts, not implementations)
- Markdown style (ATX headers, fenced code, no trailing space)
- README structure (summary, deployment, notes, tasks, known issues)
- Changelog format (Keep a Changelog)
- Emoji policy (only in markdown, not in code)

**Is:** Standards reference. Horizontal layer — applies to all writing.

**Load when:** You're writing code, KB files, or documentation

**Integrates with:** scribe (KB files follow docs markdown standards), any code work

---

### caveman — Compressed Communication Mode

**Purpose:** 75% token reduction while keeping technical accuracy

**Modes:**
- lite — drop filler/hedging, keep full sentences
- full — drop articles, fragments OK, short synonyms
- ultra — abbreviations (DB/req/fn), strip conjunctions, arrows
- wenyan-lite/full/ultra — classical Chinese variants

**Auto-clarity:** Automatically switches to normal language for security warnings and destructive operations, then resumes caveman after.

**Is:** Communication mode. Applies to output only.

**Load when:** You want ultra-compressed output to save tokens

---

## Real-World Example: Production Incident

### Scenario
Your app crashes. You need to debug, fix it, and record what happened.

### Workflow

**Session 1 — Investigation & Fix**
```
User: "Production app crashed. Debug it."

1. Load: debug
   - Step 1: Understand the app architecture
   - Step 2: Gather logs, check config, resource usage
   - Step 3: Form hypothesis (OOM? Dependency crashed? Config change?)
   - Step 4: Test hypothesis
     - Load: ops (run kubectl logs, describe pod, etc.)
   - Step 5: Fix identified (update deployment config)
     - Load: ops (kubectl apply, helm upgrade, etc.)
   - Step 6: Validate (app is running, serving requests)
   - Step 7: Record findings
     - Load: scribe (documentation mode)
     - Load: schema (investigation structure if multi-session)
     - Load: docs (markdown standards)
     - Write: session log with root cause, fix, prevention
```

**Result:** Production fixed. KB updated with findings.

---

## Decision Tree: Which Skill to Load?

```
START: What am I doing?

├─ "I need to write something to KB"
│  └─ Load: scribe (then optionally schema, docs)
│
├─ "Something is broken"
│  └─ Load: debug (then ops as needed, then scribe for recording)
│
├─ "I need to run infrastructure commands"
│  └─ Load: ops
│
├─ "I'm writing code or documentation"
│  └─ Load: docs
│
├─ "I need to understand KB structure"
│  └─ Load: schema
│
├─ "I want compressed output"
│  └─ Load: caveman
│
└─ "Multiple of the above"
   └─ Load skills in dependency order (see map above)
```

---

## Skill Composition Rules

### Rule 1: Executor Skills Load Reference Skills as Needed
- scribe loads schema when you need structure reference
- debug loads ops when you need to test/fix
- debug loads scribe when you need to record findings

### Rule 2: Quality Layers Apply Everywhere
- docs applies to all writing (code, KB, README, changelogs)
- caveman applies to any output (optional mode)

### Rule 3: Don't Load Redundantly
- Load scribe for KB work, not schema directly
- Load debug for troubleshooting, not ops directly
- Load docs for all writing, not selectively

### Rule 4: Skills Enhance, Not Replace
- caveman + docs = compressed but standard-compliant
- debug + ops = systematic troubleshooting with safe commands
- scribe + schema + docs = polished KB files with structure and style

---

## Summary Table

| Question | Skill to Load |
|---|---|
| How do I write to the KB? | **scribe** |
| What should a KB file look like? | **schema** |
| How do I troubleshoot? | **debug** |
| What's the right command to run? | **ops** |
| How should I format this? | **docs** |
| Can I get terser output? | **caveman** |

---

## Next Steps

- **For KB work:** Load `/skill:scribe`
- **For troubleshooting:** Load `/skill:debug`
- **For infrastructure:** Load `/skill:ops`
- **For any writing:** Load `/skill:docs`
- **To understand KB structure:** Load `/skill:schema`
- **For compressed output:** Load `/skill:caveman`

Questions? Each skill has detailed documentation. Load it and read through.
