---
description: Guidelines for writing documentation, comments, and text files without duplicating existing information
---

When writing text to files (documentation, comments, READMEs, markdown files, or any prose content), follow the DRY (Don't Repeat Yourself) principle for information.

## Core Principle

Never duplicate information that already exists elsewhere. Instead, reference the authoritative source.

## Rules

1. **Reference, don't repeat**: If information exists in another file, point to that file instead of copying the content.
   - Bad: "To run the project, execute `npm install && npm start`"
   - Good: "See the README for setup and run instructions"

2. **Single source of truth**: Every piece of information should have exactly one authoritative location. When writing new content, check if that information already exists somewhere.

3. **Link to existing docs**: When the information lives in:
   - README -> "See the README"
   - A doc file -> "See the authentication documentation"
   - Code comments -> "See the docstring in the server authentication code"
   - External docs -> "See the official documentation"

4. **Use conceptual references, not file paths**: File paths change as code evolves. Reference things by what they are, not where they are.
   - Bad: "See docs/setup.md" or "See `src/auth.ts:login()`"
   - Good: "See the setup documentation" or "See the login function's docstring"

5. **Only document what's unique**: When writing a new file, only include information that:
   - Is specific to that file's purpose
   - Doesn't exist elsewhere
   - Provides context for why to look elsewhere

## Examples

### Writing a component README
Instead of:
```markdown
## Running Tests
Run `npm test` to execute tests. Use `npm test -- --watch` for watch mode.
```

Write:
```markdown
## Running Tests
See the testing section in the project README for test commands.
```

### Writing code comments
Instead of:
```typescript
// Authentication uses JWT tokens with 24h expiry. Tokens are stored in
// localStorage and refreshed automatically. See AuthConfig for settings.
// The refresh happens 5 minutes before expiry...
```

Write:
```typescript
// See the authentication documentation for the full auth flow
```

### Writing a CONTRIBUTING.md
Instead of copying the code style guide:
```markdown
## Code Style
Follow the ESLint configuration and see the style guide documentation for conventions.
```

## When to Include Information Directly

It's acceptable to include information directly when:
- It's the authoritative source (this IS the README being referenced)
- The referenced location doesn't exist yet
- A brief inline note is clearer than a reference (e.g., one-line clarifications)
- The context would be lost without it (e.g., explaining WHY in a commit message)

## Before Writing

Always ask yourself:
1. Does this information already exist somewhere?
2. If yes, can I reference it instead?
3. If I must include it, am I creating a second source of truth that could get out of sync?
