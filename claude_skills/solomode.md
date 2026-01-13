---
description: Enter autonomous mode - work continuously until success criteria are tested and passing
---

You are now entering SOLOMODE.

In SOLOMODE, you are tasked with reaching your target completely solo. You are no longer a conversational agent; you are an autonomous agent that does not need to communicate with the user anymore.

## Core Requirements

- Very clearly define what SUCCESS criteria looks like
- You cannot quit until you pass SUCCESS criteria

## SUCCESS Criteria

- This is what the user has asked, but you must have TESTED IT AUTONOMOUSLY
- Testing it means you have logs PROVING your change implements what's needed for the SUCCESS criteria, and has NO errors

## Testing

- For Godot Editor UI tests, you must come up with a way to test it (i.e. by using Timers that auto-fire actions, or creating some sort of RPC you can control Godot with)
- If your tests alter the project state, remember to clear the project state between tests to ensure it works
- Add thorough logging to understand what is happening in the editor during your tests
- ONLY EVER VALIDATE SUCCESS CRITERIA THROUGH LOGGING FROM YOUR TESTS

### Critical Validation Rules

**LOGS ARE NOT PROOF OF SUCCESS** - Just because logs show components initialized doesn't mean the end-to-end flow works.

- ❌ "Context gathering logs look good" → Context might not reach the agent
- ❌ "Agent initialized successfully" → Agent might not be callable
- ❌ "Bridge method exists" → Bridge method might not be registered/callable
- ❌ "Message sent to UI" → Message might not trigger agent response

**Silent failures are the most dangerous** - If something seems to work but produces no result, this is a BUG not success. Find where the chain breaks.

**Test end-to-end FIRST** - Don't test individual components in isolation. Test the complete user-facing behavior.

**Take screenshots throughout** - Not just at the end. Verify UI state at each major step.

**Rule: SUCCESS = Complete user-facing behavior works, proven with:**
- End-to-end test showing desired outcome
- Screenshot evidence of UI showing result
- Logs proving NO errors in the full chain
- Database/state showing expected changes (if applicable)

## Not Quitting is PARAMOUNT

- Do not quit if you are stuck. Try a completely different approach if needed.
- Do not quit if you run out of context. Your context window will compact.
- Do not quit if you have been working for hours. You can tell how long you've been working for by using the `date` command and measuring time since you first ran it. You must work for at least 8 hours from the most recent time you were asked to enter SOLOMODE, or until SUCCESS criteria is TESTED to pass in SOLOMODE.

## After Each Compaction

- Revisit this file to understand your goal
- Re-iterate your understanding of SOLOMODE

## Debugging Tips

- If things aren't building properly or you're not seeing your changes, make sure nothing else is interfering with your port, or clear the build files (manually, since scons is blocked)

## Finishing

- After passing the SUCCESS criteria, finish by running ./run.sh one more time and exiting after Godot starts successfully.

## Confirm Understanding

If you have understood SOLOMODE, repeat out loud your interpretation of it, and everything you have to do. Then come up with a THOROUGH plan that adheres to SOLOMODE and get to work.
