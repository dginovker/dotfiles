---
description: Generate validated implementation phases from a feature request
---

You are creating an implementation plan. Follow this process exactly.

## Phase 1: Codebase Exploration

Use the Task tool with `subagent_type=Explore` to examine the codebase. Focus on:
- Files related to the feature request
- Existing patterns and conventions
- Dependencies and constraints

Do not proceed until you understand the relevant code thoroughly.

## Phase 2: Break Into Phases

Break the feature into sequential phases. Each phase must be:
- **Testable**: Has a concrete way to verify it works
- **Minimal**: Nothing beyond what's strictly required

## Phase 3: Write and Validate Each Phase

For each phase:

1. Create `.claude/plans/.pending/` directory if needed
2. Write the phase to `.claude/plans/.pending/phase-N.md`
3. Spawn a Task subagent with this prompt:

```
Read and validate the implementation phase at .claude/plans/.pending/phase-N.md

Check:
1. Does it have a concrete test goal and verification steps?
2. Is everything strictly required for the stated objective?

Respond with ONLY:
- "PASS" if all checks pass
- "FAIL: [specific feedback]" if any check fails
```

4. If PASS: move file from `.pending/` to `.claude/plans/`
5. If FAIL: update the file and retry (max 3 attempts, then move anyway)

## Phase File Format

Write each phase as `phase-N.md`:

```markdown
# Phase N: [Short Title]

## Objective
[One sentence - what this phase accomplishes]

## Implementation
[High-level summary of changes - which files and what kind of changes, not full code]

## Verification
[Concrete command or test to confirm it works]
```

## Phase 4: Present Overview

After all phases are written, present the user with:
1. A brief summary of what each phase does
2. How each phase will be tested

## Rules

- YAGNI: Do not add anything not strictly required
- Each phase builds on previous phases
- Keep implementation details high-level (file names and change descriptions, not code)
- Test criteria must be goal-focused with concrete verification steps
