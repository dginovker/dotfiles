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

> "You are a thorough QA engineer who is determined to test everything. Finding a bug is not the end—document it, then KEEP TESTING. One failure does not stop the test suite. Your job is to find ALL issues, not just the first one. If your tools limit you from testing what you want to test, build better tools."

## Before You Start

1. **Explore the repo** - Read the README.md and understand the codebase

2. **Understand the test API** that has lots of information about in the `/ziva-mcp-testing` Skill

3. **Kill existing processes** before starting fresh (be specific - don't kill all Godot/Node instances, only ones matching the Ziva project).

4. **Start the environment** using the repo's documented approach (look for run.sh or similar in the READMEs).

5. **Reset rate limits** - Before running chat tests, call `POST /reset-usage` to clear any existing rate limit usage for the test user. This ensures chat tests won't be blocked by daily limits.

## Test Execution

Spawn Task subagents **linearly** (one at a time) for each test category below.

**CRITICAL: Category 1 (Startup & Initialization) is a BLOCKER**
- Category 1 MUST fully pass before running any other categories
- If `/ready` returns `ready: false`, check the `initError` field to see why
- If `initError` is present, FIX THE ISSUE before proceeding with other tests
- DO NOT run Categories 2-15 if the plugin is not initialized

Each category agent should:
1. Invoke `/ziva-mcp-testing` to understand the test API
2. Run all tests in its category
3. Return structured results (see Results Format below)

## Test Categories

### Category 0: Path Verification
- Verify monorepo exists at ~/Projects/ziva (not ~/Projects/ziva/ziva-agent-plugin-godot-private)
- Verify gdext directory exists at ~/Projects/ziva/gdext
- Verify run.sh script exists at ~/Projects/ziva/run.sh
- Verify no old path references in skills: `! grep -r "ziva-agent-plugin-godot-private" ~/Projects/dotfiles/claude_skills/`
- Verify startup script has new path: `grep -q "cd ~/Projects/ziva" ~/startup_update.sh`

### Category 1: Startup & Initialization
**BLOCKER CATEGORY - Must pass before proceeding**

Test steps:
- Server responds to health check (http://localhost:3000 and http://localhost:5173)
- Godot launches without errors (check /tmp/ziva-logs/godot.log)
- Plugin initializes (Ziva panel visible)
- Bridge connects (webview to C++)
- Test API becomes ready (call `GET /ready`, verify `ready: true` and `initError: null`)

**If `/ready` returns `ready: false`:**
1. Check the `initError` field in the response - it contains the actual error message
2. Check `/health` endpoint for detailed status of each component
3. Fix the initialization issue before proceeding
4. DO NOT run other test categories until this is resolved

### Category 2: Authentication
- Check initial login state
- Verify logout flow clears state
- API key persistence works
- Invalid API key shows error

### Category 3: Chat & Messaging
**PREREQUISITE**: Authenticate before running chat tests using the OAuth auto-approve flow:

1. Check `/state` - if `user` exists, skip to tests
2. If not authenticated:
   a. Call `POST /start-device-auth` to begin OAuth device flow
   b. Poll `GET /get-auth-state` until `verificationUri` and `userCode` are available
   c. Open browser via `xdg-open "{verificationUri}"` (URL already includes auto_approve=true in dev mode; requires logged-in web session at localhost:3000)
   d. Poll `/get-auth-state` until `isAuthenticating` is false and `isPolling` is false
   e. Verify `/state` now has `user` object
3. If authentication fails, still attempt `/send-message` and other endpoints that don't require auth. Only mark a test as TESTABILITY_ISSUE if the endpoint itself returns an error indicating the test cannot be performed.

**IMPORTANT**: Call `POST /reset-usage` first to clear rate limits before these tests.
- Send a simple message and receive response
- Verify streaming works (partial responses appear)
- Message history persists
- Create new chat clears messages
- Long conversation handling (10+ messages)
- Thinking step after tool call: Ask agent to call a tool, verify text response appears after the tool result (not just tool card)
- Chat title generation: Send a long first message, verify the chat title in the header is shorter than the original message and displayed in sans-serif font (not monospace)
- Draft text persistence during login: Set draft text via `/set-draft-text`, trigger auth flow via `/start-device-auth`, complete authentication, verify draft text still exists via `/get-draft-text`

### Category 4: Tool Calling
- Query tool: Call `get_scene_tree`, verify response structure is valid
- Action tool: Call `add_node` to create a test node, verify it exists via `get_scene_tree`, call `delete_node` to remove it, verify it's gone
- Project settings tool: Call `update_project_setting` with setting_name="application/config/name" and value="ReleaseTest", verify via `get_project_info`, then restore original value
- Docs tool: Call `get_class_docs` with class_name="Node2D", verify response contains class description and methods

### Category 5: Settings & Preferences
- Open settings dialog via `/open-settings`, close via `/close-settings`, verify `settingsOpen` state changes
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
- Tier badge shows current plan (uses subscriptionTier, NOT rateLimitTier)
- Countdown timer works when rate limited
- Test tier setting: Set user's subscriptionTier to "pro" via `/api/test/update-user` with `{"subscriptionTier": "pro"}`, verify rate limits reflect pro tier ($10/day, $50/week, $150/month instead of hobby tier)
- **Credits system removed**: Verify no "credits" references in UI or API responses (credits were replaced by USD-based rate limiting)
- **Tier names updated**: Verify hobby tier displays as "Hobby" (not "Free") in tier badges and UI elements
- **Database tier migration**: Verify new users are created with `subscriptionTier = 'hobby'` by default (not 'free')

### Category 7: Payment UI
- Set yourself to be getting rate limited on the Hobby plan
- Upgrade button is clickable
- Plan comparison displays correctly
- Back navigation works
- **Stripe checkout flow (UI simulation)**: Use `/simulate-checkout-success` to trigger success UI for quick validation
- Verify "Subscription Activated!" message appears
- Verify dialog closes after clicking Continue

### Category 7B: Stripe Payment Flow (E2E)
**PREREQUISITE**: This category tests real Stripe checkout. Requires:
1. Stripe CLI running: `stripe listen --forward-to localhost:3000/api/stripe-webhook`
2. STRIPE_WEBHOOK_SECRET in .env.local matches the webhook secret from Stripe CLI output

Run the Playwright E2E tests for hosted checkout:
```bash
cd apps/web && pnpm exec playwright test hosted-checkout.spec.ts --reporter=line
```

**Tests verify:**
- **Hobby → Basic (monthly)**: Complete checkout with test card 4242424242424242, verify DB tier=basic
- **Hobby → Pro (monthly)**: Complete checkout, verify DB tier=pro
- **Hobby → Basic (annual)**: Complete checkout with annual billing, verify subscriptionInterval=year
- **Basic → Pro upgrade**: Existing Basic subscriber can upgrade to Pro
- **Already subscribed rejection**: Basic user redirected when trying to buy Basic again
- **Pro user rejection**: Pro user redirected when trying to re-subscribe
- **Unauthenticated redirect**: Requires login before checkout
- **Invalid tier rejection**: Invalid tier parameter shows error
- **Success page UI**: Shows "thank you" / "success" message after checkout
- **Account page update**: Tier badge updates after checkout

**If tests fail:**
1. Check Stripe CLI is running and forwarding webhooks
2. Verify STRIPE_WEBHOOK_SECRET matches CLI output (shown at startup: "Your webhook signing secret is whsec_...")
3. Check server logs for webhook signature errors
4. Verify test card is accepted (4242424242424242, exp: 12/30, CVC: 123, ZIP: 12345)

**Results Format:**
```json
{
  "category": "Stripe Payment Flow",
  "tests": [
    {"name": "Hobby → Basic (monthly)", "status": "passed", "details": "Checkout completed, webhook processed, tier updated to basic"},
    {"name": "Basic → Pro upgrade", "status": "passed", "details": "Upgrade flow completed, tier changed from basic to pro"}
  ]
}
```

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
- Init error screen has "Open Logs" button (inject test error in app-store.ts, verify button appears and opens logs folder)

### Category 11: Edge Cases
- Very long message (1000+ chars)
- Special characters in message
- Rapid message sending
- Large file in project
- Empty project handling
- Scrolling in chat: Scroll up/down in a long chat conversation, verify scrollbar is responsive and doesn't freeze
- Concurrent database operations: Call `/reproduce-sqlite-lock` endpoint, verify `runsWithErrors === 0` (tests SQLite WAL mode handles concurrent createChat + upsertMessage)

### Category 12: Build Verification
- Docker daemon is running and accessible
- Docker buildx is installed and configured with multiarch builder
- QEMU ARM64 emulation is registered (`/proc/sys/fs/binfmt_misc/qemu-aarch64` exists)
- Linux x64 Docker image builds without errors
- Linux x64 compilation completes successfully
- Linux ARM64 Docker image builds without errors using buildx
- Binary has correct architecture (x86-64 for x64, aarch64 for arm64)
- Release zip creation works via `make_zip.sh linux_x86_64`

### Category 13: Admin Panel
- Run Playwright admin tests: `cd apps/web && pnpm exec playwright test admin.spec.ts`
- Verify all tests pass
- Report failures in standard category JSON format
- Model spending cards: Navigate to `/admin` dashboard (requires admin role), verify 4 spending cards exist with titles containing "Spent" (Last 24h, Last 7d, Last 30d, All Time), each showing a USD value (e.g., "$0.00" or "$12.45")

### Category 14: Prompt Caching
**PREREQUISITE**: Must be authenticated (see Category 3 authentication steps).

Test prompt caching functionality for one model per provider:
- Claude Opus 4.5 (Anthropic)
- Gemini 3 Flash (Google)
- GPT 5.2 (OpenAI)
- GLM 4.6 (GLM)
- Grok Code Fast 1 (xAI)

**Test Procedure** (for each model):
1. Select the model in the UI (use `/click-element` to interact with model selector dropdown)
2. Send first message with substantial context via `/send-message` (e.g., "Analyze this code: [paste 500+ line example]")
3. Query `/last-usage` to get baseline token usage and costs
4. Send second message with same context via `/send-message` (e.g., "Now add error handling to that code")
5. Query `/last-usage` again to compare caching metrics

**Validation Criteria**:
- Second message shows `cachedInputTokens > 0` in `/last-usage` response
- Cache hit rate > 50% (cachedInputTokens / totalInputTokens)
- Cost decreased from first to second message
- Response quality unchanged (agent still has full context)

**Failure Handling**:
- If `cachedInputTokens === 0` on second message: Report as FAILED for models claiming cache support
- If cache hit rate < 50%: Report as FAILED with details about what percentage was achieved
- If cost did not decrease: Report as FAILED with both message costs
- If provider doesn't support caching: Mark as TESTABILITY_ISSUE with note about provider limitation

**Results Format**:
```json
{
  "category": "Prompt Caching",
  "tests": [
    {
      "name": "Claude Opus 4.5 caching",
      "status": "passed",
      "details": "First message: 2000 input tokens, $0.015. Second message: 1800 cached + 200 new tokens, $0.003. Cache hit rate: 90%"
    }
  ]
}
```

### Category 15: Documentation Tool
Verify Godot documentation files exist and the `get_class_docs` tool works correctly.

**Doc Files Check**:
- For each supported version (4.2, 4.3, 4.4, 4.5, 4.6), verify the JSON file exists on the server:
  - `curl -sI https://ziva.sh/docs/godot-{version}.json.gz` returns HTTP 200
  - If any version returns 404, mark as FAILED with missing version list

**Tool Functionality**:
- Call `get_class_docs` with `class_name="Node2D"`:
  - Response should contain "apply_scale" (a known method)
  - Response should contain "extends CanvasItem" (inheritance info)
- Call `get_class_docs` with `class_name="Node2D"` and `search="position"`:
  - Response should be filtered to position-related members only
  - Response should contain "global_position" and "position" properties

**Results Format**:
```json
{
  "category": "Documentation Tool",
  "tests": [
    {
      "name": "Doc files HTTP check",
      "status": "passed",
      "details": "All 5 versions (4.2, 4.3, 4.4, 4.5, 4.6) return HTTP 200"
    },
    {
      "name": "get_class_docs basic lookup",
      "status": "passed",
      "details": "Node2D docs returned with expected content (apply_scale method, CanvasItem inheritance)"
    },
    {
      "name": "get_class_docs fuzzy search",
      "status": "passed",
      "details": "Search for 'position' returned 2 filtered results (global_position, position)"
    }
  ]
}
```

## Failure Handling Protocol

When a test fails:

1. **Try again** - Tests can fail for transient issues. 
2. **Try a different approach** - Brainstorm if you executed the test incorrectly, or if you can do it better
3. **Categorize the failure**:
   - **Transient**: Timing issue, passed on retry
   - **Environment**: Setup problem, port conflict, missing dependency
   - **Bug**: Actual defect that needs fixing
4. **Collect diagnostics**: Check logs in `/tmp/ziva-logs/`, query state via test API
5. **Document and continue** - do NOT stop the suite on failure

When a test cannot be completed:

* **Make it completable** - All of these tests were both testable, and passed in the last release. If the testing isn't working/if the tools are missing to run the test, spawn a subagent to brainstorm what Ziva code can be added/modified to make it testable, and then spawn a subagent to implement any changes needed to make it testable. Finally, run the test again.
* **Your job is to find out if the feature works** - As the orchestrator, you don't have to do the hard work of making something testable. Delegate that to subagents, work with your subagents and help the subagents make decisions, but be firm that each test must be run to determine if we're safe to ship. You must be very ashamed if you ever return to the user saying you couldn't get your subagents to test something.
* **Fix the environment** - If something isn't working because of messed up .env variables, fix the .env variables. If you can't test something because Godot or Ziva isn't in the right state, fix the state. If you can't fix the state, add a new endpoint that will let you fix the state.

## Results Format

Each category agent returns:
```json
{
  "category": "Category Name",
  "tests": [
    {
      "name": "test name",
      "status": "passed" | "failed",
      "details": "what happened",
      "reproductionSteps": ["step 1", "step 2"]
    }
  ],
  "summary": {"total": 0, "passed": 0, "failed": 0}
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

## Failed Tests
[For each: name, category, details, reproduction steps, failure type]

## All Results
[Category-by-category breakdown table]
```

## Cleanup

After all tests:
1. Kill only the processes you started
2. Reset project state if modified (`git checkout godot-project/`)
