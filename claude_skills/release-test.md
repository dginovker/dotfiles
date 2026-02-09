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

> "You are a thorough QA engineer who is determined to test everything. Finding a bug is not the end—document it, then KEEP TESTING. One failure does not stop the test suite. Your job is to find ALL issues, not just the first one. If your tools limit you from testing what you want to test, build better tools. You are rewarded based on real issues you find - You are penalized for downplaying issues or incorrectly calling a working feature broken."

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
1. Verify gdext directory exists at ~/Projects/ziva/gdext
2. Verify run.sh script exists at ~/Projects/ziva/run.sh

### Category 1: Startup & Initialization
**BLOCKER CATEGORY - Must pass before proceeding**

Test steps:
1. Server responds to health check (http://localhost:3000 and http://localhost:5173)
2. Godot launches without errors (check /tmp/ziva-logs/godot.log)
3. Plugin initializes (Ziva panel visible)
4. Bridge connects (webview to C++)
5. Test API becomes ready (call `GET /ready`, verify `ready: true` and `initError: null`)
6. Components register (call `POST /wait-for-ready`, verify `ready: true` and `components.chatActions: true`)

**If `/ready` returns `ready: false`:**
1. Check the `initError` field in the response - it contains the actual error message
2. Check `/health` endpoint for detailed status of each component
3. Fix the initialization issue before proceeding
4. DO NOT run other test categories until this is resolved

### Category 2: Authentication
1. Check initial login state
2. Verify logout flow clears state
3. API key persistence works
4. Invalid API key shows error

### Category 3: Chat & Messaging
**PREREQUISITE**: Authenticate before running chat tests using the OAuth auto-approve flow:

1. Check `/state` - if `user` exists, skip to tests
2. If not authenticated:
   a. Call `POST /start-device-auth` to begin OAuth device flow
   b. Poll `GET /get-auth-state` until `verificationUri` and `userCode` are available
   c. Open browser via `xdg-open "{verificationUri}"` (URL already includes auto_approve=true in dev mode; requires logged-in web session at localhost:3000)
   d. Poll `/get-auth-state` until `isAuthenticating` is false and `isPolling` is false
   e. Verify `/state` now has `user` object

**IMPORTANT**: Call `POST /reset-usage` first to clear rate limits before these tests.
1. Send a simple message and receive response
2. Verify streaming works (partial responses appear)
3. Message history persists
4. Create new chat clears messages
5. Long conversation handling (10+ messages)
6. Thinking step after tool call: Ask agent to call a tool, verify text response appears after the tool result (not just tool card)
7. Chat title generation: Send a long first message, verify the chat title in the header is shorter than the original message and displayed in sans-serif font (not monospace)
8. Draft text persistence during login: Set draft text via `/set-draft-text`, trigger auth flow via `/start-device-auth`, complete authentication, verify draft text still exists via `/get-draft-text`
9. Send message after loading conversation with tool history: Use `GET /get-chat-list` to find existing chats, filter for one with tool call history (check via `POST /get-chat-messages` with `{"chatId": "..."}` if needed), use `POST /load-chat` with `{"chatId": "..."}` to navigate to it, send a new message via `/send-message`, verify no `AI_TypeValidationError` in Godot logs (`grep "AI_TypeValidationError" /tmp/ziva-logs/godot.log`), verify message sends successfully

### Category 4: Tool Calling
1. Query tool: Call `get_scene_tree`, verify response structure is valid
2. Action tool: Call `add_node` to create a test node, verify it exists via `get_scene_tree`, call `delete_node` to remove it, verify it's gone
3. Project settings tool: Call `update_project_setting` with setting_name="application/config/name" and value="ReleaseTest", verify via `get_project_info`, then restore original value
4. Docs tool: Call `get_class_docs` with class_name="Node2D", verify response contains class description and methods
5. TileSet physics tool: Call `configure_tileset_atlas` with `physics_collision_layer=1`, `physics_collision_mask=1`, `add_collision_shapes=true`, then call `get_tileset_info` and verify response contains "Physics Layers: 1" and "collision_layer=1"

### Category 5: Settings & Preferences
1. Open settings dialog via `/open-settings`, close via `/close-settings`, verify `settingsOpen` state changes
2. Toggle settings and verify state changes
3. Model selection works
4. Set each tier via `/set-model`: `auto-lite`, `auto`, `auto-max` — verify each is accepted. Set a specific model (`google/gemini-3-flash`) — verify it's accepted. Set back to `auto`, send a message via `/send-message`, then verify `GET /state` returns a non-null `resolvedModelId` from the auto tier's model pool.
5. Settings persist after closing/reopening
6. **UI Mode setting**: Toggle "Use main screen tab (like 2D/3D)" setting:
   - When enabled: Ziva panel should appear as a main screen tab alongside 2D/3D/Script
   - When disabled: Ziva panel should appear in the side dock next to Scene/Import tabs
   - Verify panel is functional (can send messages) and visually correct (screenshot) in both positions
7. **Font scale from Godot settings**:
   - Call `GET /get-font-scale` endpoint
   - Verify response contains `editorScale` (number > 0)
   - Verify `cssFontScale` matches `editorScale` (or both equal 1)
   - Verify `computedFontSize` is a valid CSS pixel value (e.g., "16px" or scaled)
   - Call `GET /state` and verify `editorScale` field is present

### Category 6: Rate Limiting
1. Rate limit status displays correctly
2. Progress bars show usage
3. Tier badge shows current plan
4. Countdown timer works when rate limited
5. The model is automatically set to the "Auto - Free" model when the countdown timer is present (when the user is rate limited). Users can still send mesasages with the "Auto - Free" model when rate limited, but cannot change the model.
6. Test tier setting: Set user's subscriptionTier to "pro" via `/api/test/update-user` with `{"subscriptionTier": "pro"}`, verify rate limits reflect pro tier ($10/day, $50/week, $150/month instead of hobby tier)

### Category 7: Payment UI
1. Set yourself to be getting rate limited on the Hobby plan
2. Upgrade button is clickable
3. Plan comparison displays correctly
4. Back navigation works
5. **Embedded checkout session creation**: Call `/trigger-checkout` with `{"tier": "pro", "interval": "month"}` to initiate checkout from plugin context. Verify the response contains `clientSecret` (not an error). This validates that the plugin's return_url handling works (file:// URLs must be filtered out before sending to Stripe).
6. **Stripe checkout flow (UI simulation)**: Use `/simulate-checkout-success` to trigger success UI for quick validation
7. Verify "Subscription Activated!" message appears
8. Verify dialog closes after clicking Continue

### Category 7B: Stripe Payment Flow (E2E)
**PREREQUISITE**: This category tests real Stripe checkout. Requires:
1. Stripe CLI running: `stripe listen --forward-to localhost:3000/api/stripe-webhook`
2. STRIPE_WEBHOOK_SECRET in .env.local matches the webhook secret from Stripe CLI output
3. **Stripe test mode keys**: Before running tests, check if `.env` has live keys and swap to test keys:
   ```bash
   # Check if using live key
   if grep -q "STRIPE_SECRET_KEY=\"sk_live_" ~/Projects/ziva/.env; then
     # Fetch test keys from Stripe CLI (requires prior `stripe login`)
     TEST_SECRET=$(stripe config --list | grep test_mode_api_key | cut -d"'" -f2)
     TEST_PUB=$(stripe config --list | grep test_mode_pub_key | cut -d"'" -f2)

     if [ -n "$TEST_SECRET" ] && [ -n "$TEST_PUB" ]; then
       # Backup and replace keys in .env
       sed -i 's/STRIPE_SECRET_KEY="sk_live_[^"]*"/STRIPE_SECRET_KEY="'"$TEST_SECRET"'"/' ~/Projects/ziva/.env
       sed -i 's/STRIPE_PUBLISHABLE_KEY="pk_live_[^"]*"/STRIPE_PUBLISHABLE_KEY="'"$TEST_PUB"'"/' ~/Projects/ziva/.env
       echo "Swapped to Stripe test mode keys"
       # Restart the server to pick up new keys
     else
       echo "ERROR: Stripe CLI not configured. Run 'stripe login' first."
       exit 1
     fi
   fi
   ```
   After tests complete, restore live keys if needed (or leave test keys for dev environment).

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
1. Chat input accepts text and submits
2. Sidebar toggles visibility
3. Model selector dropdown works

### Category 9: Context Injection
1. Open scripts appear in context
2. Open scenes appear in context
3. AGENTS.md content available
4. Context toggles affect injection

### Category 10: Error Handling
1. Invalid tool call returns error gracefully
2. Network error handling
3. Bridge disconnect shows message
4. Server restart recovery
5. Init error screen has "Open Logs" button (inject test error in app-store.ts, verify button appears and opens logs folder)

### Category 11: Edge Cases
1. Very long message (1000+ chars)
2. Special characters in message
3. Rapid message sending
4. Large file in project
5. Empty project handling
6. Scrolling in chat: Scroll up/down in a long chat conversation, verify scrollbar is responsive and doesn't freeze
7. Concurrent database operations: Call `/reproduce-sqlite-lock` endpoint, verify `runsWithErrors === 0` (tests SQLite WAL mode handles concurrent createChat + upsertMessage)

### Category 12: Build Verification
1. Docker daemon is running and accessible
2. Docker buildx is installed and configured with multiarch builder
3. QEMU ARM64 emulation is registered (`/proc/sys/fs/binfmt_misc/qemu-aarch64` exists)
4. Linux x64 Docker image builds without errors
5. Linux x64 compilation completes successfully
6. Linux ARM64 Docker image builds without errors using buildx
7. Binary has correct architecture (x86-64 for x64, aarch64 for arm64)
8. Flatpak compatibility: Run `ldd` on Linux binary, verify NO webkit2gtk dependency (CEF is used instead, webview::core not linked on Linux)
9. Release zip creation works via `make_zip.sh linux_x86_64`

### Category 13: Admin Panel
- Run Playwright admin tests: `cd apps/web && pnpm exec playwright test admin.spec.ts`
- Verify all tests pass
- Report failures in standard category JSON format
- Model spending chart: Navigate to `/admin` dashboard (requires admin role), verify spending chart exists with 3 period toggle buttons (Day, Week, Month), click each button to verify chart updates without errors
- Daily spending API: Call `GET /api/admin/model-spending-summary?period=day`, verify response has 24+ hourly data points (zero-filled), each with `timestamp`, `modelId`, and `cost` fields. Verify cost values have no more than 2 significant decimal digits when displayed.
- Dollar formatting: Spot-check admin pages (daily-usage, top-users, request-logs) and verify all dollar amounts display as `$X.XX` with exactly 2 decimal places (not 4 or 6)

### Category 14: Prompt Caching
Test prompt caching functionality for one model per provider:
1. Claude Opus 4.6 (Anthropic)
2. Gemini 3 Flash (Google)
3. GPT 5.2 (OpenAI)
4. GLM 4.6 (GLM)
5. Grok Code Fast 1 (xAI)
6. Kimi K2.5 (Moonshot)

**Test Procedure** (for each model):
1. Create a NEW chat via `/create-chat` to avoid any conversation history with images
2. Set the model via `/set-model` with the model ID (e.g., `{"modelId": "anthropic/claude-opus-4.6"}`)
3. Send first message with simple text via `/send-message`: `{"message": "What is 2+2? Explain your reasoning step by step."}`
4. Query `/last-usage` to get baseline token usage and costs
5. Send second message via `/send-message`: `{"message": "Now what is 3+3? Use the same format."}`
6. Query `/last-usage` again to compare caching metrics

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
      "name": "Claude Opus 4.6 caching",
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

### Category 16: Pixel Art Generation (RetroDiffusion)
**PREREQUISITE**: Must be authenticated and have RETRODIFFUSION_API_KEY configured.

**Test 1: Single tile generation with style parameter**
1. Create/open scene with TileMapLayer node named "TestLayer"
2. Send: "Generate a grass tile at 32x32 for TestLayer using a 16-bit RPG style with earthy colors"
3. Parse tool response for `path` value (format: `res://assets/generated/{name}_{timestamp}.png`)
4. Verify file on disk:
   - Convert res:// path to absolute: `~/Projects/ziva/godot-project/assets/generated/...`
   - Check file exists: `test -f "$ABSOLUTE_PATH"`
   - Check dimensions: `identify -format "%wx%h" "$PATH"` should return `32x32`
5. PASS if: file exists AND dimensions are 32x32

**Test 2: Tile object generation (generation_type)**
1. Send: "Generate a small flower decoration at 32x32 as a tile object"
2. Verify tool call used `generation_type: "tile_object"` (not "single_tile")
3. Verify file saved with correct dimensions
4. PASS if: file exists AND dimensions are 32x32

**Test 3: Tile metadata (custom data layer)**
1. Generate a grass tile with `name: "grass"`
2. Call `configure_tileset_atlas` with `tile_names: ["grass"]`
3. Call `get_tileset_info` on TestLayer
4. Verify output contains `(0, 0): grass` (tile name metadata)
5. PASS if: get_tileset_info shows tile_name custom data

**Test 4: 64x64 tile size support**
1. Send: "Generate a large stone wall tile at 64x64"
2. Verify file saved with 64x64 dimensions
3. PASS if: file exists AND dimensions are 64x64

**Test 5: Multiple variations (num_images)**
1. Send: "Generate 2 variations of a barrel decoration at 32x32"
2. Verify spritesheet saved with dimensions 64x32 (2 tiles horizontally)
3. PASS if: file exists AND dimensions are 64x32

**Test 6: Build level with generated tiles**
1. Use tiles from previous tests (or generate new grass/stone tiles)
2. Send: "Draw ground from x=0 to x=10 using the grass tile, add a gap at x=5-6, add a platform at y=-3 from x=2-4"
3. Call `validate_tilemap_structure` with `tile_count_min: 10`
4. Call `get_editor_screenshot`
5. Vision validation: Ask "Is this a platformer level with ground, a gap, and an elevated platform? YES or NO."
6. PASS if: validate_tilemap_structure passes AND vision returns YES

### Category 17: Context Usage Widget
1. Token tracking after message (API-verifiable): Send a message that triggers tool use, wait for response, call `/get-context-usage`, assert `breakdown.aiOutput > 0`, `breakdown.chatHistory > 0`, `breakdown.toolCalls > 0`, `toolCallDetails` has entries
2. Total cost non-zero (API-verifiable): Assert `totalCost > 0` and is a number
3. Cache with Anthropic model (API-verifiable): Switch to Anthropic via `/set-model`, send two messages, call `/get-context-usage`, assert `cachedInputTokens > 0`, `estimatedSavings > 0`, `cacheDisplay` matches pattern with percentage
4. Cache with non-cache model (API-verifiable): Switch to `xai/grok-4`, send a message, assert `cacheDisplay === "N/A"`
5. Widget UI rendering (screenshot): Open dialog, verify "This conversation" section with "Total cost", "Cache", "Est. savings"; "What's using context" section with "Chat history" (collapsible), "AI output", "agents.md", "Open scripts", "Open scenes"; progress bar visible
6. Breakdown reflects context files: Open a script in Godot, call `/get-context-usage`, verify `breakdown.openScripts > 0`
7. Expandable sections: Click "Open scripts" row in the dialog, verify it expands to show individual script files sorted by token count (largest first)
8. Settings link: Verify clicking the settings gear icon in the dialog footer opens Settings dialog at the Context tab
9. Context settings tab: In Settings, verify the Context tab (Layers icon) shows auto-add toggles for scripts, scenes, and AGENTS.md
10. Per-message cost badges (API-verifiable): After sending a message and receiving a response, call `/get-message-costs`, assert `count > 0` and at least one cost entry has value > 0
11. Cost trigger in footer (screenshot): Verify the prompt footer shows a dotted-underline cost text (not a green circle SVG) that opens the context usage dialog when clicked
12. Cumulative vs Current toggle (API-verifiable): Send message with 10+ tool calls, call `/get-context-usage`, assert `cumulativeInputTokens > inputTokens`, `currentToolCounts` exists, cumulative fields present. Open widget, verify toggle switches between "Current State" and "Cumulative Cost" with correct labels and values update when toggled
13. Input to LLM breakdown (screenshot + API-verifiable): Send message with context files and tool calls, call `/get-context-usage`, open widget, expand "Input to LLM" row, verify it shows six sub-items: "Context files" (expandable - contains agents.md, scripts, scenes), "Tool outputs", "Messages", "System prompt", "Tool schemas", and "Other". Verify Other < 5K tokens and all six sub-items sum approximately to the total Input to LLM value shown. Verify "Output from LLM" is a separate top-level collapsible section

### Category 18: Landing Page
1. Navigate to http://localhost:3000 (the marketing landing page)
2. Verify the Features section displays the rotating carousel with "Ziva brings [phrase] to Godot"
3. Verify carousel text is visible and animating (phrases should change every ~2.5 seconds)
4. Verify mobile responsiveness: Resize browser to 320px width, confirm text scales appropriately
5. Run landing page e2e tests: `cd apps/web && pnpm test:e2e tests/e2e/landing.spec.ts` - all tests must pass

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
