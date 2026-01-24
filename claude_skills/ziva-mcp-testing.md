---
name: ziva-mcp-testing
description: Test changes to the Ziva Godot plugin by interacting with a running Godot instance via the MCP server
---

# Ziva Testing Skill

Use this skill when you need to test changes to the Ziva Godot plugin by interacting with a running Godot instance.

## Overview

The Ziva plugin exposes a WebSocket-based test API during development that allows Claude Code to:
- Execute Godot tools directly
- Check plugin readiness and status
- Query webview state and bridge connectivity
- Take screenshots and verify changes

## Architecture

```
Claude Code ──WebSocket──▶ Vite Dev Server ──▶ React App (plugin-app) ──Bridge──▶ Godot Plugin (C++)
               (port 5173)    (WebSocket)           (in webview)        (IPC)
```

**Key Components:**
- **Vite Dev Server**: Runs on port 5173, provides WebSocket endpoint `/__test_api_ws`
- **plugin-app**: React app running in webview, implements test API handlers
- **Bridge**: IPC communication between webview and C++ plugin (see `apps/plugin-app/src/lib/bridge/schemas.ts`)
- **Tool Manager**: C++ tool registry with 34 tools (see `gdext/src/tools/ToolManagerZiva.cpp`)

## Starting the Plugin

```bash
cd /home/w/Projects/ziva/gdext
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

## Test API Connection

Connect via WebSocket to the Vite dev server:

```javascript
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:5173/__test_api_ws');

ws.on('open', () => {
  ws.send(JSON.stringify({
    id: 'test-1',
    path: '/ready',
    method: 'GET'
  }));
});

ws.on('message', (data) => {
  const response = JSON.parse(data.toString());
  console.log(response.result);
});
```

### Request Format

**CRITICAL: Body must be a JSON STRING, not an object.**

```javascript
// CORRECT - body is JSON.stringify'd
ws.send(JSON.stringify({
  id: '1',
  path: '/send-message',
  method: 'POST',
  body: JSON.stringify({ message: "Hello world" })  // <-- JSON.stringify the body!
}));

// WRONG - body as object causes "[object Object]" parse error
ws.send(JSON.stringify({
  id: '1',
  path: '/send-message',
  method: 'POST',
  body: { message: "Hello world" }  // <-- This will FAIL!
}));
```

**Why:** The test API server receives the outer JSON, then parses `body` as JSON again internally via `JSON.parse(body)`. If you pass an object, it becomes `"[object Object]"` which is not valid JSON.

**Reference Implementation:** See `apps/plugin-app/test-api-validation.cjs` for a complete working example.

## Available Endpoints

**IMPORTANT:** Always discover endpoints dynamically by calling `GET /` first. Do not assume endpoints exist - the API evolves and hardcoded lists get stale.

```javascript
// FIRST: Discover all available endpoints
ws.send(JSON.stringify({ id: 'discover', path: '/', method: 'GET' }));

// Response:
// {
//   endpoints: [
//     { path: '/ready', description: 'Check if plugin is ready' },
//     { path: '/call-tool', description: 'Execute a Godot tool', method: 'POST' },
//     { path: '/send-message', description: 'Send a test message', method: 'POST' },
//     ... (more endpoints)
//   ]
// }
```

Use the discovery response to determine what endpoints are available before making assumptions.

### Response Format

All tool calls return:
```typescript
{
  id: string,  // matches request id
  result: {
    success: boolean,
    type: "text" | "image" | "json",
    data: any,
    mimeType?: string
  }
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
- `free`: $1/day, $5/week, $15/month
- `basic`: $4/day, $20/week, $60/month
- `pro`: $10/day, $50/week, $150/month
- `test`: $0.02/day, $0.10/week, $0.30/month (for automated testing)

The tier change takes effect immediately for the authenticated user. Use this to test rate limit UI, countdown timers, tier badges, and upgrade flows.

### Setting User Tier for Testing

When testing rate limit behavior, you can change the authenticated user's subscription tier using the `/api/test/update-user` endpoint:

```bash
curl -X POST http://localhost:3000/api/test/update-user \
  -H "Content-Type: application/json" \
  -d '{"subscriptionTier": "pro"}'
```

**Valid tier values:**
- `free`: $1/day, $5/week, $15/month
- `basic`: $4/day, $20/week, $60/month
- `pro`: $10/day, $50/week, $150/month
- `test`: $0.02/day, $0.10/week, $0.30/month (for automated testing)

The tier change takes effect immediately for the authenticated user. Use this to test rate limit UI, countdown timers, tier badges, and upgrade flows.

### 1. Check Plugin Readiness

```javascript
ws.send(JSON.stringify({ id: '1', path: '/ready', method: 'GET' }));
// Wait for response: { id: '1', result: { ready: true, checks: [...] } }
```

### 2. Taking Screenshots

Use the `/screenshot` endpoint to capture the entire Godot editor window.

```javascript
// Take a screenshot of the editor
ws.send(JSON.stringify({
  id: 'screenshot-1',
  path: '/screenshot',
  method: 'POST'
}));

// Response format:
// {
//   id: 'screenshot-1',
//   result: {
//     result: {
//       success: true,
//       type: 'image',
//       data: '<base64-encoded PNG data>'
//     }
//   }
// }

// Save the screenshot
ws.on('message', (data) => {
  const response = JSON.parse(data.toString());
  if (response.id === 'screenshot-1') {
    const imageData = response.result.result.data;  // Note the double .result
    const buffer = Buffer.from(imageData, 'base64');
    fs.writeFileSync('/tmp/screenshot.png', buffer);
  }
});
```

**Key Points:**
- The screenshot captures the ENTIRE Godot editor window as it currently appears
- Image data is returned as base64-encoded PNG in `response.result.result.data`
- No parameters needed - it always captures the full editor window
- The underlying tool is `get_editor_screenshot` (can also be called via `/call-tool`)
- For UI testing, manually interact with the editor first, then take a screenshot

**Example: Complete Screenshot Script**
```javascript
const WebSocket = require('ws');
const fs = require('fs');

const ws = new WebSocket('ws://localhost:5173/__test_api_ws');

ws.on('open', () => {
  console.log('Taking screenshot...');
  ws.send(JSON.stringify({
    id: 'screenshot',
    path: '/screenshot',
    method: 'POST'
  }));
});

ws.on('message', async (data) => {
  // Handle Blob data from browser WebSocket
  let text = data;
  if (data instanceof Buffer) {
    text = data.toString('utf8');
  }

  const response = JSON.parse(text);
  const output = response.result?.result;

  if (output?.type === 'image' && output.data) {
    const buffer = Buffer.from(output.data, 'base64');
    fs.writeFileSync('/tmp/godot-screenshot.png', buffer);
    console.log(`Screenshot saved: ${buffer.length} bytes`);
    ws.close();
  }
});
```

### 3. Execute a Tool

```javascript
ws.send(JSON.stringify({
  id: '2',
  path: '/call-tool',
  method: 'POST',
  body: JSON.stringify({
    toolName: 'get_scene_tree',
    toolArgs: {}
  })
}));
```

### 4. Verify Changes

```javascript
// Get errors/logs
ws.send(JSON.stringify({
  id: '3',
  path: '/call-tool',
  method: 'POST',
  body: JSON.stringify({
    toolName: 'get_godot_errors',
    toolArgs: { num_lines: 50 }
  })
}));

// Clear logs before test
ws.send(JSON.stringify({
  id: '4',
  path: '/call-tool',
  method: 'POST',
  body: JSON.stringify({
    toolName: 'clear_output_logs',
    toolArgs: {}
  })
}));
```

## Cleanup Between Tests

Always clean state between test iterations:

```bash
# Kill processes you started (be specific, don't kill all instances)
pkill -f "godot.*ziva-agent-plugin"

# Reset project state
cd /home/w/Projects/ziva
git checkout project/
```

## Troubleshooting

### Plugin Not Ready
- Check that `./run.sh` completed successfully
- Verify Vite dev server is running on port 5173: `curl http://localhost:5173`
- Check logs in `/tmp/ziva-logs/`
- Check Godot console for errors

### WebSocket Connection Fails
- Ensure plugin-app is running: `pnpm --filter @repo/plugin-app dev`
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

## Expanding Testing
- Add w

## Important Notes

- Test API is only available in development mode (not production builds)
- Never commit to git unless explicitly asked
- All bridge method definitions: `apps/plugin-app/src/lib/bridge/schemas.ts`
- All tool implementations: `gdext/src/tools/` (actions/ and queries/ subdirectories)
