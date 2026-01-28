---
description: Find potential Ziva customers - small/medium businesses using Godot
---

# Find Godot Leads

Search for potential Ziva customers: small-to-medium businesses actively using Godot.

## Orchestrator Discipline Rules

**CRITICAL: Each orchestrator MUST follow these rules:**

1. **No early exit.** Do not return "partial results" or say "we've collected enough." Run ALL sub-agents to completion.
2. **No time-based quitting.** "This is taking a long time" is not a reason to stop. Complete the mission.
3. **Explicit completion.** Each sub-agent must report DONE or FAILED. Orchestrator waits for all.
4. **Rate limit handling.** If rate limited, WAIT and retry. Do not skip the source.
5. **Failure logging.** If a sub-agent fails, log WHY and continue with others. Do not abort.

Orchestrators must end with:
```
ORCHESTRATOR COMPLETE
- Sub-agents dispatched: N
- Sub-agents succeeded: X
- Sub-agents failed: Y (with reasons)
- Total leads collected: Z
```

---

## Phase 1: GitHub Orchestrator

Spawn sub-agents SEQUENTIALLY (to avoid GitHub rate limits):

**1.1 - Organizations with game/studio keywords:**
> "Search GitHub for organizations with 'game', 'studio', 'interactive', or 'entertainment' in name AND repos with godot topic. Extract: org name, URL, website, public email, member count if visible, repo count. Return JSON array."

**1.2 - Prolific Godot users:**
> "Search GitHub for users with 3+ repositories containing project.godot files. Extract: username, URL, website, email, total godot repos, most recent commit date. Return JSON array."

**1.3 - Popular Godot projects:**
> "Search GitHub for repositories with godot topic AND 50+ stars. Extract: owner (user/org), repo URL, star count, last commit date, contributors count. Return JSON array."

**1.4 - Godot addon/plugin developers:**
> "Search GitHub for repositories tagged 'godot-addon' or 'godot-plugin' or in godot-asset-library. These are serious developers. Extract: owner, repo URL, addon name, download count if available. Return JSON array."

**1.5 - Recently active Godot devs:**
> "Search GitHub for repositories with godot topic AND pushed:>2024-06-01 (last 6 months). Focus on owners with multiple such repos. Extract: owner, URL, last activity date, repo count. Return JSON array."

Wait 2 seconds between sub-agents. If rate limited, wait 60 seconds and retry.

---

## Phase 2: Itch.io Orchestrator

Spawn sub-agents SEQUENTIALLY (itch.io has no official API):

**2.1 - Top sellers with Godot tag:**
> "Browse itch.io games tagged 'godot', sorted by 'Top sellers'. For top 100 results, extract: creator name, creator URL, game name, price (paid = good signal). Return JSON array."

**2.2 - Prolific creators:**
> "Search itch.io for creators who have published 3+ games tagged 'godot'. Extract: creator name, URL, game count, any visible contact info, website link. Return JSON array."

**2.3 - Paid game developers:**
> "Search itch.io for PAID games (not free) tagged 'godot'. Extract: creator name, URL, game name, price point. Paid games = revenue mindset. Return JSON array."

**2.4 - Recent releases:**
> "Search itch.io for games tagged 'godot' released in last 12 months. Extract: creator name, URL, release date, game name. Return JSON array."

**2.5 - Press kit hunters:**
> "For each creator found above, check their game pages for presskit links. Press kits often contain direct contact emails. Extract: creator name, presskit URL, email if found. Return JSON array."

Wait 1.5 seconds between page fetches.

---

## Phase 3: Steam Orchestrator

Spawn sub-agents SEQUENTIALLY:

**3.1 - Recent Godot releases:**
> "Search Steam/SteamDB for games made with Godot released 2024-2025. Extract: developer name, publisher name, Steam URL, release date. Return JSON array."

**3.2 - Games with traction:**
> "Search for Godot games on Steam with 50+ reviews (indicates meaningful sales). Extract: developer, Steam URL, review count, review score. Return JSON array."

**3.3 - Multi-title developers:**
> "Find developers/publishers on Steam with 2+ Godot titles. Multiple releases = serious operation. Extract: developer name, title count, Steam URLs. Return JSON array."

**3.4 - Revenue estimates:**
> "For games found above, check SteamSpy or SteamDB for estimated owners/revenue. Extract: game name, developer, estimated owners, estimated revenue range. Return JSON array."

**3.5 - Developer website extraction:**
> "For each developer found, visit their Steam page and extract: official website, social links, support email if listed. Return JSON array."

---

## Phase 4: Job/Hiring Orchestrator

Spawn sub-agents in PARALLEL (different sites, no shared rate limit):

**4.1 - Indeed:**
> "Search Indeed for 'Godot developer' or 'Godot engineer' job postings. Extract: company name, job URL, company website, location, posting date. Return JSON array."

**4.2 - LinkedIn Jobs:**
> "Search LinkedIn Jobs for 'Godot' postings. Extract: company name, job URL, company size if shown, location. Return JSON array."

**4.3 - Remote boards:**
> "Search We Work Remotely, RemoteOK, and Working Nomads for 'Godot' or 'game developer Godot'. Extract: company name, job URL, company website. Return JSON array."

**4.4 - Gamedev-specific boards:**
> "Search GameDevJobs, Games Jobs Direct, and Hitmarker for Godot-related postings. Extract: company name, job URL, company website. Return JSON array."

**4.5 - Career page scraper:**
> "For companies found in other phases that have websites, check /careers, /jobs, /join-us pages. Any open positions = active hiring = budget. Extract: company name, careers URL, open position count. Return JSON array."

Hiring = strongest buying signal. Prioritize these leads.

---

## Phase 5: Business Signals Orchestrator

Spawn sub-agents to ENRICH existing leads with viability signals:

**5.1 - ProductHunt cross-reference:**
> "Search ProductHunt for any leads found in previous phases. Also search for 'Godot' launches. ProductHunt presence = marketing mindset. Extract: company name, PH URL, launch date, upvotes. Return JSON array."

**5.2 - Crunchbase/funding lookup:**
> "For leads with company websites, search Crunchbase for funding info. Extract: company name, funding stage, total raised, last funding date, investor count. Return JSON array."

**5.3 - LinkedIn company data:**
> "For leads found, search LinkedIn for company pages. Extract: company name, employee count range, founded date, specialties. Return JSON array."

**5.4 - Social activity check:**
> "For leads with Twitter/X handles, check last post date. Active = posted in last 30 days. Extract: company name, twitter handle, last post date, follower count. Return JSON array."

**5.5 - Business registration lookup:**
> "For leads claiming business status, search OpenCorporates or state registries for LLC/Inc/GmbH registration. Extract: company name, registration status, registration date, jurisdiction. Return JSON array."

---

## Phase 6: Merge and Deduplicate

After ALL orchestrators complete:

1. Collect all leads from all orchestrators
2. Normalize names (lowercase, strip Inc/LLC/Studio/Games suffixes)
3. Merge by normalized name, combining all data fields
4. Calculate composite score (see scoring below)

---

## Phase 7: Email Discovery

For leads WITHOUT email, spawn batched agents (10 leads per agent):

**Email Discovery Agent:**
> "For each lead:
> 1. Website: fetch /contact, /about, /press, /presskit, /team pages - find mailto: links
> 2. GitHub: check profile for public email
> 3. Itch.io: check creator profile for email
> 4. Twitter bio: check for email in bio
> 5. Press kits: parse presskit pages for contact email
> Return: [{name, email, source}] for leads where email found"

---

## Phase 8: Verification Agent

Validate ALL leads (spawn batched, 20 leads per agent):

**Verification Agent:**
> "For each lead:
> 1. **Exists:** Website/profile loads and is game-related
> 2. **Uses Godot:** Evidence in repos/game tags/blog
> 3. **Is business:** Multiple projects, team page, hiring, or paid products
> 4. **Is active:** Activity in last 12 months
> 5. **Email valid:** Use AbstractAPI/ZeroBounce free tier to check deliverability
>
> Return: {name, exists, uses_godot, is_business, is_active, email_valid, notes}"

---

## Phase 9: Scoring and Output

### Lead Scoring Formula

| Signal | Points |
|--------|--------|
| Validated email | +30 |
| Currently hiring | +25 |
| Paid products on Steam/Itch | +20 |
| Funding received | +20 |
| Team size 2-50 | +15 |
| Active in last 6 months | +15 |
| Multiple Godot projects | +10 |
| ProductHunt presence | +10 |
| Business registered | +10 |
| Active social media | +5 |
| 100+ GitHub stars | +5 |

**Tiers:**
- **Hot (80+):** Hiring, funded, or strong revenue signals
- **Warm (50-79):** Active business with contact info
- **Cold (25-49):** Legitimate but weak signals
- **Skip (<25):** Likely hobbyist

### Output Format

Write to `.claude/leads/godot-leads-YYYY-MM-DD.md`:

```markdown
# Godot Lead Report - YYYY-MM-DD

## Orchestrator Summary
| Orchestrator | Sub-agents | Succeeded | Failed | Raw Leads |
|--------------|------------|-----------|--------|-----------|
| GitHub | 5 | 5 | 0 | 234 |
| Itch.io | 5 | 5 | 0 | 156 |
| Steam | 5 | 4 | 1 | 89 |
| Jobs | 5 | 5 | 0 | 45 |
| Business | 5 | 3 | 2 | - |
| **Total** | 25 | 22 | 3 | 524 |

After dedup: 312 unique leads
After verification: 245 verified leads
With validated email: 167 leads

## Hot Leads (Score 80+)

### [Company Name] - Score: 95
- **Website:** [URL]
- **Email:** [email] (validated)
- **Why hot:** Hiring 2 Godot devs, raised $500K seed, 3 Steam titles
- **Sources:** GitHub, Steam, LinkedIn Jobs, Crunchbase
- **Signals:**
  - Last activity: 2 days ago
  - Team size: 8-12
  - Hiring: Yes (2 positions)
  - Revenue: ~$50K-100K (Steam estimate)
  - Funding: $500K seed (2024)

---

[Repeat for each Hot lead]

## Warm Leads (Score 50-79)

[Same format, condensed]

## Cold Leads (Score 25-49)

[Table format - name, website, email, score, primary signal]

## Rejected Leads

| Name | Reason | Score |
|------|--------|-------|
| [name] | No activity since 2022 | 15 |
| [name] | Solo hobbyist, no business signals | 12 |
```

---

## Autonomous Testing

### Success Criteria

1. **Orchestrator completion:** ALL 5 orchestrators report COMPLETE (not partial)
2. **Sub-agent coverage:** At least 80% of sub-agents succeeded
3. **Volume sanity:** 100+ raw leads found (Godot community is large)
4. **Dedup effectiveness:** Unique leads < 70% of raw (expect overlap between sources)
5. **Verification pass rate:** 40-80% of leads pass verification
6. **Email hit rate:** 30%+ of verified leads have validated email
7. **Score distribution:** At least 10 Hot leads, 30 Warm leads
8. **Known entities:** GDQuest, Heartbeast, or Brackeys appears in results

### Verification Commands

```bash
# Check orchestrator completion
grep -c "ORCHESTRATOR COMPLETE" .claude/leads/godot-leads-*.md  # Should be 5

# Check lead counts
grep "After dedup:" .claude/leads/godot-leads-*.md
grep "With validated email:" .claude/leads/godot-leads-*.md

# Check Hot leads exist
grep -c "## Hot Leads" .claude/leads/godot-leads-*.md
grep -A2 "Score: [89][0-9]" .claude/leads/godot-leads-*.md | head -20

# Known entity check
grep -iE "gdquest|heartbeast|brackeys" .claude/leads/godot-leads-*.md
```

### Spot Check Protocol

After skill completes, verification agent picks 3 random Hot leads and:
1. Visits their website - confirms it loads and mentions games/Godot
2. Checks claimed email - sends test via validation API
3. Verifies one business signal (e.g., confirms they're hiring if claimed)

Report: "Spot check: 3/3 verified" or "Spot check: 2/3 verified - [Lead X] website 404"

---

## Rate Limiting Strategy

| Source | Limit | Strategy |
|--------|-------|----------|
| GitHub API | 60/hr unauth, 5000/hr auth | Sequential sub-agents, 2s delay, use token if available |
| Itch.io | No official API | 1.5s between fetches, respect robots.txt |
| Steam/SteamDB | Varies | 2s between fetches |
| LinkedIn | Aggressive limits | Use public pages only, 3s delay |
| Job boards | Varies | 1s delay, parallelize across different sites |
| Email validation | 100-250/mo free | Batch at end, prioritize Hot leads first |

If rate limited: wait the required time (up to 60s), then retry. Do NOT skip.

---

## Rules

- **No early exit** - Complete all orchestrators regardless of time
- Exclude obvious hobbyists (no website, single jam game, 0 stars)
- Exclude companies already using Ziva (check repos)
- Prioritize leads with validated emails
- Keep rejected leads for manual review
- Log all failures with reasons
