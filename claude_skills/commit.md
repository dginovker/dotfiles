---
description: Create a commit using dginovker's commit message style and push
---

1. Run `git log --author=dginovker --oneline -20` to see the commit message style
2. Think about what the user originally requested - focus on the **result** ("fix x", "add y"), not the implementation details (the "how" is obvious from the code)
3. Stage and commit with a short message matching the observed style. No description body.
4. Push. If the remote branch was updated, rebase and push again.
