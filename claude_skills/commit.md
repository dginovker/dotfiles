---
description: Create a commit using the current git user's commit message style and push
---

1. Run `git config user.name` to get the current user, then `git log --author="<name>" --oneline -20` to see their commit message style
2. Think about what the user originally requested - focus on the **result** ("fix x", "add y"), not the implementation details (the "how" is obvious from the code)
3. Stage and commit with a short message matching the observed style. No description body.
4. **Branch targeting (Ziva repos only):** If in a Ziva repo (path contains `/ziva/`):
   - By default, push to `staging` (NOT main/prod)
   - Only push to `main` if the user explicitly says "push to prod" or "push to main"
   - **Workflow rules to keep branches aligned:**
     - All commits go to staging first, always
     - Never commit directly to main
     - Never cherry-pick between branches (creates duplicate commits with different SHAs)
     - "Push to main" means fast-forward main to staging's HEAD
   - **Before pushing to staging:**
     - Run `git fetch origin main staging`
     - Run `git log origin/staging..origin/main --oneline` to find commits on main not on staging
     - If there are any, merge or rebase them onto staging first
   - **When pushing to main:**
     - First push to staging (so staging has the commit)
     - Then fast-forward main: `git push origin staging:main`
     - This ensures main is always a subset of staging's history
5. Push to the target branch. If the remote branch was updated, rebase and push again.

Rules:
* NEVER force push
* Do not coauthor with claude code
