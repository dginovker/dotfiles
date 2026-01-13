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
cd /home/w/Projects/ziva/ziva-agent-plugin-godot-private/gdext
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

**Reference Implementation:** See `apps/plugin-app/test-api-validation.cjs` for a complete working example.

## Available Endpoints

All endpoints documented in `apps/plugin-app/src/lib/test-api.ts`:

| Path | Method | Description | Parameters |
|------|--------|-------------|------------|
| `/` | GET | List all endpoints | - |
| `/ready` | GET | Check if plugin is ready | - |
| `/health` | GET | Detailed health check | - |
| `/state` | GET | Get webview state | - |
| `/call-tool` | POST | Execute a Godot tool | `{toolName, toolArgs}` |
| `/screenshot` | POST | Take editor screenshot | - |

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

## Available Tools

**Complete list in:** `gdext/src/tools/ToolManagerZiva.cpp`

### Query Tools (15)
- `get_filesystem_tree` - Get project file structure
- `get_godot_errors` - Get errors/logs from Godot output
- `get_input_map` - Get input action mappings
- `get_open_scripts` - List open script editors
- `get_project_info` - Get project metadata
- `get_scene_file_content` - Read .tscn file contents
- `get_scene_tree` - Get current scene node hierarchy
- `get_tilemap_state` - Get tilemap tile data
- `get_tileset_info` - Get tileset configuration
- `grep` - Search in project files
- `project_path_to_uid` - Convert path to UID
- `search_files` - Find files by pattern
- `take_screenshot` - Capture editor window
- `uid_to_project_path` - Convert UID to path
- `view_script` - Read script file contents

### Action Tools (19)
- `add_node`, `delete_node`, `duplicate_node`, `move_node` - Node manipulation
- `add_resource`, `add_scene`, `add_to_group`, `remove_from_group` - Resource/group management
- `attach_script`, `create_script`, `edit_file` - Script operations
- `create_scene`, `open_scene` - Scene management
- `clear_output_logs` - Clear Godot output logs
- `configure_tileset_atlas` - Configure tileset atlas
- `erase_tile`, `erase_tiles`, `set_tile`, `set_tiles` - Tilemap editing
- `set_anchor_preset`, `set_anchor_values` - UI anchors
- `stop_running_scene` - Stop running game scene
- `update_property` - Modify node property
- `rm` - Remove file from project

## Testing Workflow

### 1. Check Plugin Readiness

```javascript
ws.send(JSON.stringify({ id: '1', path: '/ready', method: 'GET' }));
// Wait for response: { id: '1', result: { ready: true, checks: [...] } }
```

### 2. Execute a Tool

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

### 3. Verify Changes

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

**CRITICAL**: Always clean state between test iterations:

```bash
# Kill processes you started (be specific, don't kill all instances)
pkill -f "godot.*ziva-agent-plugin"

# Reset project state
cd /home/w/Projects/ziva/ziva-agent-plugin-godot-private
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

## Important Notes

- Test API is **only available in development mode** (not production builds)
- Never commit to git unless explicitly asked
- When killing processes, be specific - don't kill all Godot/Node instances
- All bridge method definitions: `apps/plugin-app/src/lib/bridge/schemas.ts`
- All tool implementations: `gdext/src/tools/` (actions/ and queries/ subdirectories)
