---
description: Create a commit using dginovker's commit message style and push
---

1. Run `git log --author=dginovker --oneline -20` to see the commit message style
2. Think about what the user originally requested - focus on the **result** ("fix x", "add y"), not the implementation details (the "how" is obvious from the code)
3. Stage and commit with a short message matching the observed style. No description body.
4. **Branch targeting (Ziva repos only):** If in a Ziva repo (path contains `/ziva/`):
   - By default, push to `staging` (NOT main/prod)
   - Only push to `main` if the user explicitly says "push to prod" or "push to main"
   - **Before pushing to staging**, check that staging has all commits from main:
     - Run `git fetch origin main staging`
     - Run `git log origin/staging..origin/main --oneline` to find commits on main not on staging
     - If there are any, warn the user and ask if they want to sync main→staging first
   - For non-Ziva repos, push to the current branch as normal
5. Push to the target branch. If the remote branch was updated, rebase and push again.
