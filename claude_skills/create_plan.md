---
description: Generate validated implementation phases from a feature request
---

You are creating an implementation plan. Follow this process exactly.

## Phase 1: Codebase Exploration

Use the Task tool with `subagent_type=Explore` to ruthlessly examine the codebase. Focus on:
- Files related to the feature request
- Existing patterns and conventions
- Dependencies and constraints

Do not proceed until you understand the relevant code thoroughly.

## Phase 2: Present Approaches

Present 2-3 distinct implementation approaches using AskUserQuestion. For each approach:
- One sentence description
- Key trade-off (what you gain vs what it costs)

Do not add approaches that aren't meaningfully different.

## Phase 3: Break Into Phases

After user selects an approach, break it into sequential phases. Each phase must be:
- **Testable**: Has a concrete way to verify it works
- **Minimal**: Nothing beyond what's strictly required

## Phase 4: Write and Validate Each Phase

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
[Files to create/modify and specific changes]

## Test Criteria

### Goal
Validate that [specific behavior] works as expected.

### Verification
Create [test file/manual test] and run [commands] to confirm:
- [Observable outcome]
```

## Rules

- YAGNI: Do not add anything not strictly required
- Each phase builds on previous phases
- Test criteria must be goal-focused, not checkbox-focused
- Prefer concrete commands over vague manual checks
