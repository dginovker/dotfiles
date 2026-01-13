---
description: Quick validation - verify Ziva is working
---

You are validating the Ziva plugin after a code change or build.

## Available Testing Primitives

You have access to a test API at `http://localhost:5173/__test_api_ws` (WebSocket-based).

To query it, you can use Node.js with the `ws` package or similar WebSocket client tools.

### Discovery

First, discover what endpoints are available:

```javascript
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:5173/__test_api_ws');

ws.on('open', () => {
  ws.send(JSON.stringify({
    id: '1',
    path: '/',
    method: 'GET'
  }));
});

ws.on('message', (data) => {
  console.log(JSON.parse(data.toString()));
  ws.close();
});
```

### Common Endpoints

Based on the test API design, these endpoints should be available:
- `GET /` - List all endpoints (discovery)
- `GET /ready` - Check if plugin is ready
- `GET /health` - Detailed health check
- `GET /state` - Get webview state
- `POST /call-tool` - Execute a Godot tool
- `POST /screenshot` - Capture editor screenshot

## Critical: End-to-End Testing Required

**LOGS ALONE ARE NOT PROOF** - Components showing "initialized" doesn't mean the feature works end-to-end.

### Automated Test Flow (Use Chrome DevTools Protocol)

For validating agent features, you MUST test the complete flow:

1. **Process Health Check**
   ```bash
   # Godot running
   ps aux | grep godot | grep project.godot

   # Dev server (5173)
   curl -s http://localhost:5173 | head -5

   # Ziva server (3000) if needed
   curl -s http://localhost:3000/health
   ```

2. **Webview Connection Test**
   ```javascript
   // Connect via Chrome DevTools Protocol
   const CDP = require('chrome-remote-interface');
   const targets = await CDP.List({ port: 9222 });
   const webview = targets.find(t => t.title.includes("Ziva"));
   // Verify webview exists and is responsive
   ```

3. **Bridge Communication Test**
   ```javascript
   // Call simple bridge method
   const result = await Runtime.evaluate({
     expression: 'window.c2g_getInitPayload({})'
   });
   // Verify response contains expected data
   ```

4. **End-to-End Message Test** (CRITICAL)
   ```javascript
   // Inject test message
   const textarea = document.querySelector('textarea');
   textarea.value = "test message";
   button.click();

   // Monitor for agent response
   // Check: [Agent prepareCall] logs
   // Check: Database for message parts
   // Check: UI updates with response
   ```

5. **Screenshot Evidence**
   - Take screenshot showing UI state
   - Verify expected UI elements present
   - Confirm no error messages visible

### What NOT to Do

❌ **Don't rely on logs alone** - "Context gathering initialized" ≠ "context reaches agent"
❌ **Don't test components in isolation** - Each component might work but the chain is broken
❌ **Don't skip the E2E test** - Always send a real message and verify response
❌ **Don't ignore silent failures** - No errors + no results = BUG

### What TO Do

✅ **Test the complete user flow** - Message send → Agent response → UI update
✅ **Verify data flow** - Check database/state shows expected changes
✅ **Use screenshots liberally** - Visual proof of working UI
✅ **Check for chain breaks** - If feature fails, find exactly where the chain breaks

## Important

- **Adapt to what you discover** - Don't follow rigid steps
- **Investigate failures** - If something fails, find out why before reporting
- **Always include evidence** - Screenshot + relevant logs for any claims
- **Be concise** - This is a quick check, not a comprehensive audit

## Output Format

Provide a brief report:

**Status**: ✓ Healthy / ✗ Issues found / ⚠️ Warnings

**What I checked**:
- [Bullet points of what you tested]

**Findings**:
- [What you discovered - errors, warnings, or all clear]

**Evidence**:
- [Screenshot if captured, log snippets if errors found]

**Recommendation**: Safe to continue / Needs fixing / Unclear

## Example: Testing Auto-Context Feature

```javascript
#!/usr/bin/env node
const CDP = require('chrome-remote-interface');

async function testAutoContext() {
  // 1. Connect to webview
  const targets = await CDP.List({ port: 9222 });
  const webview = targets.find(t => t.title.includes("Ziva"));
  const client = await CDP({ target: webview });
  const { Runtime, Console } = client;

  await Runtime.enable();
  await Console.enable();

  // 2. Monitor console for key logs
  const logs = [];
  Console.messageAdded(p => logs.push(p.message.text));

  // 3. Send test message
  await Runtime.evaluate({
    expression: `
      const textarea = document.querySelector('textarea');
      const button = document.querySelector('button[type="submit"]');
      textarea.value = "what is TEST_VALUE?";
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
      button.click();
    `
  });

  // 4. Wait and check for success markers
  await new Promise(r => setTimeout(r, 10000));

  // 5. Verify success criteria
  const hasAgentPrep = logs.some(l => l.includes('[Agent prepareCall]'));
  const hasOpenFiles = logs.some(l => l.includes('Has <open_files>: true'));
  const hasResponse = logs.some(l => l.includes('42'));
  const hasTools = logs.some(l => l.includes('tool-'));

  console.log('✓/✗ Agent called:', hasAgentPrep);
  console.log('✓/✗ Context injected:', hasOpenFiles);
  console.log('✓/✗ Correct response:', hasResponse);
  console.log('✓/✗ No tools used:', !hasTools);

  return hasAgentPrep && hasOpenFiles && hasResponse && !hasTools;
}
```

**Key Point**: This tests the COMPLETE flow, not just that logs appear.

## Example Usage

After building the plugin:
```bash
./gdext/dev.sh
claude /validate
```

After making changes:
```bash
# make code changes
./gdext/dev.sh
claude /validate
```
