---
description: Incrementally reduce code bloat - find and remove one piece of slop with comprehensive E2E verification
---

# Reduce Slop

You are performing an incremental cleanup of the codebase. Your goal: remove ONE piece of slop while PROVING nothing breaks through comprehensive testing.

## Success Criteria

1. LoC is STRICTLY LOWER than baseline
2. `./run.sh` builds without error
3. ALL tests in your test plan PASS via `/ziva-mcp-testing`

## Phase 1: Baseline

Record the starting line count (excluding godot-project/):

```bash
find gdext apps -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.ts" -o -name "*.tsx" \) | xargs wc -l | tail -1
```

Store this number. It MUST decrease.

## Phase 2: Deep Analysis

Spawn MULTIPLE Task agents with `subagent_type=Explore` in PARALLEL:

**Agent 1 - gdext/ structural analysis:**
> "Analyze gdext/src/ for structural inefficiencies: files that do very little, classes with only one method, abstractions with single implementations, wrapper functions that add no value. Return specific candidates with file paths and reasoning."

**Agent 2 - gdext/ dead code:**
> "Analyze gdext/src/ for code that may never run: functions with no callers, unreachable branches, features that appear deprecated but not removed. Use grep/LSP to verify call sites. Return specific candidates with evidence."

**Agent 3 - apps/ structural analysis:**
> "Analyze apps/ for structural inefficiencies: components used once, utility functions called from one place, over-abstracted patterns, duplicate logic across files. Return specific candidates with file paths and reasoning."

**Agent 4 - apps/ dead code:**
> "Analyze apps/ for unused exports, unreferenced components, dead feature flags, commented-out code blocks, or modules that nothing imports. Return specific candidates with evidence."

## Phase 3: Select Target and Create Test Plan

Review all agent findings. Select ONE target based on:
1. **Safety**: Least likely to break something
2. **Impact**: Meaningful LoC reduction
3. **Clarity**: Obviously slop, not "maybe useful"

### CRITICAL: Before deleting ANYTHING, create a comprehensive test plan

Even if code appears unused, you must understand:
1. **What does this code do?** - Read it thoroughly
2. **What feature area does it relate to?** - Even unused code tells you what to test
3. **What could break if we're wrong?** - Assume grep missed something

Create a TEST PLAN with 5-10 specific tests that exercise the feature area. For example, if deleting a rate-limit component:
- Test: Send a message and verify response appears
- Test: Trigger rate limiting and verify dialog appears
- Test: Verify upgrade flow works
- Test: Check settings dialog opens correctly
- Test: Verify chat history loads properly

**The test plan must be executable via `/ziva-mcp-testing`** - meaning tests that:
- Launch Godot with the plugin
- Connect via the test API WebSocket
- Execute tool calls and verify responses
- Check UI state via bridge methods
- Take screenshots as evidence

## Phase 4: Execute Cleanup

Make the change. Be surgical - remove only what's necessary.

## Phase 5: Comprehensive Verification (~20 minutes)

This is the most important phase. You MUST:

1. **Build**: Run `cd gdext && ./run.sh` and wait for Godot to fully load

2. **Connect**: Use `/ziva-mcp-testing` to connect to the running instance

3. **Execute ALL tests in your test plan**:
   - For each test, document:
     - What you're testing
     - The commands/actions taken
     - The expected result
     - The actual result
     - PASS/FAIL

4. **Take screenshots** as evidence at key points

5. **Check logs** for any new errors: `tail -100 /tmp/ziva-logs/*.log`

6. **Spend at least 20 minutes** actually using the feature area:
   - If you deleted chat-related code, test all chat flows
   - If you deleted settings-related code, test all settings
   - If you deleted tool-related code, test tool execution
   - Be thorough - click around, try edge cases

7. **Verify LoC decreased**:
   ```bash
   find gdext apps -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.ts" -o -name "*.tsx" \) | xargs wc -l | tail -1
   ```

## Phase 6: Report Results

Your final report MUST include:

### Test Plan Summary
| Test | Description | Result |
|------|-------------|--------|
| 1 | [what you tested] | PASS/FAIL |
| 2 | ... | ... |

### Evidence
- Screenshots taken
- Key log snippets
- Any warnings observed

### Metrics
- Baseline LoC: X
- Final LoC: Y
- Reduction: Z lines

### Verdict
- ALL tests passed: Safe to keep change
- ANY test failed: Run `git checkout -- gdext apps` to rollback

## Rollback Protocol

If ANY verification step fails:
1. Run `git checkout -- gdext apps`
2. Report "Cleanup failed verification - rolled back"
3. Document exactly what failed
4. Do NOT retry the same cleanup

## Test Infrastructure Issues

**CRITICAL: If the test API or any testing infrastructure is broken, you MUST fix it before proceeding.**

- "Test API doesn't work" is NOT an acceptable reason to skip verification
- If WebSocket connections timeout, diagnose WHY and fix it
- If tools fail to execute, find the root cause
- Broken test infrastructure is a bug that blocks ALL verification - treat it as priority #1
- Do not report "BLOCKED" - either fix the issue or rollback and report the infrastructure bug

## Rules

- NEVER clean godot-project/ - only gdext/ and apps/
- ONE cleanup per run - incremental improvement
- If unsure whether something is slop, skip it
- Prefer deleting over refactoring (simpler to verify)
- Do not add code - only remove or simplify
- **Testing is PARAMOUNT** - a passing build means nothing without E2E verification
- If all agents find nothing, report "No obvious slop found" and exit

## What Counts as Slop

✓ Files with <20 lines that could be inlined
✓ Functions called from exactly one place
✓ Abstractions with single implementations
✓ "Just in case" error handling that can't trigger
✓ Wrapper functions that just forward calls
✓ Duplicate logic (pick one, delete others)
✓ Commented-out code blocks
✓ Unused imports/includes
✓ Dead feature flags
✓ Over-engineered patterns for simple tasks

## What Is NOT Slop

✗ Small utility functions used in multiple places
✗ Abstractions that enable testing
✗ Error handling at system boundaries
✗ Code that looks unused but is called via reflection/dynamic dispatch
✗ Platform-specific implementations (even if only one platform currently)
