---
name: release-test
description: Comprehensive QA testing skill for Ziva plugin release validation. Spawns category agents to test all features.
---

# Ziva Release Test

You are the orchestrator for a comprehensive Ziva release test.

## What is Ziva?

Ziva is an AI assistant plugin for the Godot game engine. It runs as a dock panel inside the Godot editor, allowing developers to chat with an AI that can:
- Read and understand their Godot project (scenes, scripts, resources)
- Execute tools to modify the project (add nodes, edit files, create scenes)
- Provide context-aware help for game development

The plugin consists of:
- A C++ GDExtension that integrates with Godot
- A React webview UI (plugin-app) for the chat interface
- A backend server for AI inference

## QA Persona

All testing follows this mindset:

> "You are a thorough QA engineer. Finding a bug is not the end—document it, then KEEP TESTING. One failure does not stop the test suite. Your job is to find ALL issues, not just the first one."

## Before You Start

1. **Explore the repo** - Read the README.md and understand the codebase 

2. **Understand the test API** that has lots of information about in the `/ziva-mcp-testing` Skill

3. **Kill existing processes** before starting fresh (be specific - don't kill all Godot/Node instances, only ones matching the Ziva project).

4. **Start the environment** using the repo's documented approach (look for run.sh or similar in the READMEs).

## Test Execution

Spawn Task subagents **linearly** (one at a time) for each test category below.

Each category agent should:
1. Invoke `/ziva-mcp-testing` to understand the test API
2. Run all tests in its category
3. Return structured results (see Results Format below)

## Test Categories

### Category 1: Startup & Initialization
- Server responds to health check
- Godot launches without errors
- Plugin initializes (Ziva panel visible)
- Bridge connects (webview to C++)
- Test API becomes ready

### Category 2: Authentication
- Check initial login state
- Verify logout flow clears state
- API key persistence works
- Invalid API key shows error

### Category 3: Chat & Messaging
- Send a simple message and receive response
- Verify streaming works (partial responses appear)
- Message history persists
- Create new chat clears messages
- Long conversation handling (10+ messages)
- Thinking step after tool call: Ask agent to call a tool, verify text response appears after the tool result (not just tool card)

### Category 4: Tool Calling
- Query tool: Call `get_scene_tree`, verify response structure is valid
- Action tool: Call `add_node` to create a test node, verify it exists via `get_scene_tree`, call `delete_node` to remove it, verify it's gone
- Project settings tool: Call `update_project_setting` with setting_name="application/config/name" and value="ReleaseTest", verify via `get_project_info`, then restore original value

### Category 5: Settings & Preferences
- Open settings dialog
- Toggle settings and verify state changes
- Model selection works
- Settings persist after closing/reopening
- **UI Mode setting**: Toggle "Use main screen tab (like 2D/3D)" setting:
  - When enabled: Ziva panel should appear as a main screen tab alongside 2D/3D/Script
  - When disabled: Ziva panel should appear in the side dock next to Scene/Import tabs
  - Verify panel is functional (can send messages) and visually correct (screenshot) in both positions

### Category 6: Rate Limiting
- Rate limit status displays correctly
- Progress bars show usage
- Tier badge shows current plan
- Countdown timer works when rate limited

### Category 7: Payment UI
- Set yourself to be getting rate limited on the Free plan
- Upgrade button is clickable
- Plan comparison displays correctly
- Stripe embed loads
- Back navigation works
- **Stripe checkout flow**: Use `/simulate-checkout-success` to trigger success UI (Stripe iframe cannot be automated via test API)
- Verify "Subscription Activated!" message appears
- Verify dialog closes after clicking Continue

### Category 8: UI Validation
- Chat input accepts text and submits
- Sidebar toggles visibility
- Model selector dropdown works
- Message rendering (markdown, code blocks)
- Theme applies consistently

### Category 9: Context Injection
- Open scripts appear in context
- Open scenes appear in context
- AGENTS.md content available
- Context toggles affect injection

### Category 10: Error Handling
- Invalid tool call returns error gracefully
- Network error handling
- Bridge disconnect shows message
- Server restart recovery

### Category 11: Edge Cases
- Very long message (1000+ chars)
- Special characters in message
- Rapid message sending
- Large file in project
- Empty project handling
- Scrolling in chat: Scroll up/down in a long chat conversation, verify scrollbar is responsive and doesn't freeze

## Failure Handling Protocol

When a test fails:

1. **Retry immediately** - check for transient failures
2. **Try alternate approach** - different timing, different verification method
3. **Categorize the failure**:
   - **Transient**: Timing issue, passed on retry
   - **Environment**: Setup problem, port conflict, missing dependency
   - **Bug**: Actual defect that needs fixing
4. **Collect diagnostics**: Check logs in `/tmp/ziva-logs/`, query state via test API
5. **Document and continue** - do NOT stop the suite on failure

## Testability Feedback Mechanism

When a test struggles to verify something effectively:

1. Mark the result as `"status": "TESTABILITY_ISSUE"`
2. Document what couldn't be verified and why
3. Spawn a Task subagent to investigate the Ziva codebase and suggest 1-2 concrete improvements
4. Include suggestions in the final report

Examples of testability issues:
- Cannot observe internal state
- No API access to verify UI-only behavior
- Timing issues making verification flaky
- State resets before verification possible

## Results Format

Each category agent returns:
```json
{
  "category": "Category Name",
  "tests": [
    {
      "name": "test name",
      "status": "passed" | "failed" | "TESTABILITY_ISSUE",
      "details": "what happened",
      "reproductionSteps": ["step 1", "step 2"]
    }
  ],
  "testabilityIssues": [
    {"scenario": "...", "problem": "...", "suggestions": ["..."]}
  ],
  "summary": {"total": 0, "passed": 0, "failed": 0, "testabilityIssues": 0}
}
```

## Final Report

After all categories complete, write results to `/tmp/ziva-release-test-results.md`:

```markdown
# Ziva Release Test Results
**Date:** [timestamp]
**Duration:** [total time]

## Summary
- Total: X tests
- Passed: Y
- Failed: Z
- Testability Issues: W

## Failed Tests
[For each: name, category, details, reproduction steps, failure type]

## Testability Issues
[For each: scenario, problem, suggestions]

## All Results
[Category-by-category breakdown table]
```

## Cleanup

After all tests:
1. Kill only the processes you started
2. Reset project state if modified (`git checkout godot-project/`)
