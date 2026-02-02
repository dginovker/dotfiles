---
name: ziva-mcp-testing
description: Test changes to the Ziva Godot plugin by interacting with a running Godot instance via the HTTP test API
---

# Ziva Testing Skill

Use this skill when you need to test changes to the Ziva Godot plugin by interacting with a running Godot instance.

## Overview

The Ziva plugin exposes an HTTP-based test API during development that allows Claude Code to:
- Execute Godot tools directly
- Check plugin readiness and status
- Query webview state and bridge connectivity
- Take screenshots and verify changes

## Architecture

```
Test Script ──HTTP──▶ Vite Dev Server ──polling──▶ React App (plugin-app) ──Bridge──▶ Godot Plugin (C++)
              (port 5173)   (HTTP endpoints)         (in webview)            (IPC)
```

**Key Components:**
- **Vite Dev Server**: Runs on port 5173, provides HTTP endpoints at `/__test_api/*`
- **plugin-app**: React app running in webview, polls for requests and submits responses
- **Bridge**: IPC communication between webview and C++ plugin (see `apps/plugin-app/src/lib/bridge/schemas.ts`)
- **Tool Manager**: C++ tool registry with 34 tools (see `gdext/src/tools/ToolManagerZiva.cpp`)

## Starting the Plugin

```bash
cd /home/w/Projects/ziva
./run.sh
```

This script:
1. Kills conflicting processes on ports 3000, 5173, 9222
2. Builds the plugin (`./dev.sh`)
3. Starts web server (port 3000) and plugin-app (port 5173) in background
4. Opens Godot editor with the plugin loaded

## Log Files

Logs are written to `/tmp/ziva-logs/`:

| Component | Log File | Command |
|-----------|----------|---------|
| Godot editor | `/tmp/ziva-logs/godot.log` | `tail -f /tmp/ziva-logs/godot.log` |
| Web server (Next.js) | `/tmp/ziva-logs/web.log` | `tail -f /tmp/ziva-logs/web.log` |
| Plugin app (Vite) | `/tmp/ziva-logs/plugin-app.log` | `tail -f /tmp/ziva-logs/plugin-app.log` |

View all logs: `tail -f /tmp/ziva-logs/*.log`

## Test API Connection (HTTP)

The test API uses HTTP polling instead of WebSocket for reliability with CEF webviews.

### How It Works

1. **Submit request**: POST to `/__test_api/request` with your request payload
2. **Browser polls**: The browser polls `/__test_api/request` every 100ms for pending requests
3. **Browser processes**: When found, browser executes the request handler
4. **Browser responds**: Browser POSTs result to `/__test_api/response`
5. **Get response**: Poll `/__test_api/response/{id}` until response is available

### Example: Simple Request

```javascript
// Helper function to call the test API
async function callTestApi(path, method = 'GET', body = null) {
  const id = 'req-' + Date.now();

  // 1. Submit request
  await fetch('http://localhost:5173/__test_api/request', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, path, method, body: body ? JSON.stringify(body) : undefined })
  });

  // 2. Poll for response
  for (let i = 0; i < 50; i++) {
    await new Promise(r => setTimeout(r, 100));
    const res = await fetch(`http://localhost:5173/__test_api/response/${id}`);
    const data = await res.json();
    if (!data.pending) {
      return data.result;
    }
  }
  throw new Error('Timeout waiting for response');
}

// Usage
const ready = await callTestApi('/ready');
console.log('Ready:', ready);
```

### Request Format

**CRITICAL: Body must be a JSON STRING, not an object.**

```javascript
// CORRECT - body is JSON.stringify'd
const request = {
  id: '1',
  path: '/send-message',
  method: 'POST',
  body: JSON.stringify({ message: "Hello world" })  // <-- JSON.stringify the body!
};

// WRONG - body as object causes "[object Object]" parse error
const request = {
  id: '1',
  path: '/send-message',
  method: 'POST',
  body: { message: "Hello world" }  // <-- This will FAIL!
};
```

## Available Endpoints

**IMPORTANT:** Always discover endpoints dynamically by calling `GET /` first. Do not assume endpoints exist - the API evolves and hardcoded lists get stale.

```javascript
const endpoints = await callTestApi('/');
console.log(endpoints);
// {
//   endpoints: [
//     { path: '/ready', description: 'Check if plugin is ready' },
//     { path: '/call-tool', description: 'Execute a Godot tool', method: 'POST' },
//     { path: '/send-message', description: 'Send a test message', method: 'POST' },
//     ... (more endpoints)
//   ]
// }
```

### Response Format

All tool calls return:
```typescript
{
  success: boolean,
  type: "text" | "image" | "json",
  data: any,
  mimeType?: string
}
```

## Available Ziva Tools

View `gdext/src/tools/ToolManagerZiva.cpp` for a list of tools Ziva can call

## Testing Workflow

Tip: Before running chat/messaging tests, call `POST /reset-usage` to clear rate limit usage for the current user. This prevents tests from being blocked by daily limits.

### 0. Available endpoints

See `apps/plugin-app/src/lib/test-api.ts` for the endpoints you can leverage for testing. Note that you can and SHOULD modify or add new endpoints to help with testing.

### Setting User Tier for Testing

When testing rate limit behavior, you can change the authenticated user's subscription tier using the `/api/test/update-user` endpoint:

```bash
curl -X POST http://localhost:3000/api/test/update-user \
  -H "Content-Type: application/json" \
  -d '{"subscriptionTier": "pro"}'
```

**Valid tier values:**
- `hobby`: $1/day, $5/week, $15/month
- `basic`: $4/day, $20/week, $60/month
- `pro`: $10/day, $50/week, $150/month
- `test`: $0.02/day, $0.10/week, $0.30/month (for automated testing)

The tier change takes effect immediately for the authenticated user. Use this to test rate limit UI, countdown timers, tier badges, and upgrade flows.

### 1. Check Plugin Readiness

```javascript
const ready = await callTestApi('/ready');
// { ready: true, checks: ['app: ok', 'bridge: ok'], initError: null }
```

### 2. Taking Screenshots

```javascript
const screenshot = await callTestApi('/screenshot', 'POST');
// { result: { success: true, type: 'image', data: '<base64 PNG>' } }

// Save to file
const buffer = Buffer.from(screenshot.result.data, 'base64');
require('fs').writeFileSync('/tmp/screenshot.png', buffer);
```

### 3. Execute a Tool

```javascript
const result = await callTestApi('/call-tool', 'POST', {
  toolName: 'get_scene_tree',
  toolArgs: {}
});
```

### 4. Verify Changes

```javascript
// Get errors/logs
const errors = await callTestApi('/call-tool', 'POST', {
  toolName: 'get_godot_errors',
  toolArgs: { num_lines: 50 }
});

// Clear logs before test
await callTestApi('/call-tool', 'POST', {
  toolName: 'clear_output_logs',
  toolArgs: {}
});
```

## Cleanup Between Tests

Always clean state between test iterations:

```bash
# Kill processes you started (be specific, don't kill all instances)
pkill -f "godot.*godot-project"

# Reset project state
cd /home/w/Projects/ziva
git checkout godot-project/
```

## Troubleshooting

### Plugin Not Ready
- Check that `./run.sh` completed successfully
- Verify Vite dev server is running on port 5173: `curl http://localhost:5173`
- Check logs in `/tmp/ziva-logs/`
- Check Godot console for errors

### HTTP Test API Not Responding
- Verify browser is polling: check for `[TestAPI] Polling started` in Godot logs
- Check port 5173 is available: `fuser 5173/tcp`
- Verify in development mode (test API only works in dev)

### Tool Execution Fails
- Check tool exists in ToolManagerZiva.cpp
- Verify parameter names are camelCase: `toolName`, `toolArgs` (not snake_case)
- Check bridge schemas in `apps/plugin-app/src/lib/bridge/schemas.ts`

### Changes Not Appearing
- Verify correct binary is loaded (check timestamps)
- Rebuild with `cd gdext && ./dev.sh`
- Check for C++ compile errors

## Important Notes

- Test API is only available in development mode (not production builds)
- Never commit to git unless explicitly asked
- All bridge method definitions: `apps/plugin-app/src/lib/bridge/schemas.ts`
- All tool implementations: `gdext/src/tools/` (actions/ and queries/ subdirectories)
