---
description: Incrementally reduce cpp warnings - find and remove a couple C++ warnings with comprehensive E2E verification
---

# Reduce Warnings

You are performing an incremental cleanup of warnings in the gdext/ codebase. Your goal: remove at least one warning while PROVING nothing breaks through comprehensive testing.

## Success Criteria

1. Warning count is reduced
2. ALL tests in your test plan PASS via `/ziva-mcp-testing`

## Phase 1: Build and capture warnings to a file

The warnings appear during the cmake build step. To capture them:

```bash
cd /home/w/Projects/ziva/gdext
rm -rf build  # Force full rebuild
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=./../godot-project/addons -B build -S . 2>&1 | tee /tmp/cmake-configure.log
cmake --build build -- -j10 2>&1 | tee /tmp/cmake-build.log
```

**CRITICAL**: The warnings are in `/tmp/cmake-build.log`. After the build completes, read that file to find warnings:

```bash
grep -n "warning:" /tmp/cmake-build.log
```

This will show you all compiler warnings with line numbers in the log file.

## Phase 2: Analyze the warnings

Read `/tmp/cmake-build.log` using the Read tool to see the full context of each warning. Filter out third-party warnings (from `thirdparty/` directory) as those are not our code to fix.

## Phase 3: Select Target and Create Test Plan

Review the warnings and the codebase. Select a couple warnings to fix based on:
1. **Safety**: Least likely to break something
2. **Impact**: Meaningful warning reduction
3. **Ease**: Clear path to fixing the warning 

### CRITICAL: Before changing ANYTHING, create a comprehensive test plan

Even if code appears simple, you must understand:
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
- Launch Godot with the plugin via ./run.sh
- Connect via the test API WebSocket
- Execute tool calls and verify responses
- Check UI state via bridge methods
- Take screenshots as evidence

## Phase 4: Execute Cleanup

Make the change. Be surgical - adjust only what's necessary.

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

### Results
- Warning A removed
- Warning B removed (5 instances)

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

- Avoid adding code - only remove or simplify
- **Testing is PARAMOUNT** - a passing build means nothing without E2E verification

