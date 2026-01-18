---
description: Come up with a project requirements plan for Claude to turn into requriements and execute.
---

The user will ask you to brainstorm an idea with them. The final result should be a .md project document that can have an implementation plan built for.

You should:
1. Examine the current folders in depth to get a good understanding of 1/ what you're building and, 2/ how it can be tested
2. Come up with 2-3 different ways of implementing the user request, each with a specific on how it can be autonomously tested
3. Ask any clarified questions if needed

At the end, you should produce a succinct .md plan file for how the implementation should work, and recommend the user runs the `/create_plan` command.

Notes:
* YAGNI: Do not add ANYTHING to the plan that is not strictly required for the user request.
* Do not include a summary. It's a waste of tokens.
* If you have presented multiple options to the user and the user has picked one, do not include the other options as part of the plan.
* Tell the user the location of the .md file, so the user can review it
