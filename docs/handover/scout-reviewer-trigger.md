---
workstream: scout-reviewer-trigger
status: in-progress
branch: manage/scout-reviewer-trigger
pr: none
plan: scout-reviewer-trigger
issue: 461
session: https://claude.ai/code/session_01QcZK5M6AWvqSjY9917d4q1
agent: opus
updated: 2026-10-13
next: ci, verify, then verifier at opus
---

## Goal

A scout pass runs only on the reviewer's order (`/scout`, `+human`) or a
`scout` issue waiting on the scout; clock, backlog trigger, ceiling and the
HOURS/BACKLOG/AUTOMERGE knobs go (#461 item 1, #460).

## Decisions

- Dispatch's scout row is state only: `off` (no reviewer / no command),
  `UNREADABLE`, `IN FLIGHT`, `held` (stale view, or `JOHARNESS_MAX_MANAGERS=0`
  pause), or `none in flight`. The orchestrator spawns on that last row plus
  the human's order or the issue trigger (orchestrate.md); dispatch never
  names a spawn it cannot see the reason for.
- `cmd_scout` still prints the `reviewer  :` line when off: clerk.md's scout
  gate reads it.
- Removed `scout_refs`, the `throughput` line and the evidence pointer block
  too: `scout_refs` had no caller once `scout_retired_ts` went; throughput
  only sized N; the pointers repeat scout.md §2 word for word.
- `cycle_landed_sha` lost its scout branch: no caller asks for kind scout.
- §4 "exactly ONE reply": a §5 revising/revised bracket counts as the one
  reply; a proposal not yours or nothing asked gets `scout: noted`.
- `## Never` dropped four bullets each restating a section's own rule
  (citation: §6/§7 verifier; outside reads: §3; file name: §1 walk; other
  repository: §6 `issue_write` on this repository).
- Scout block line count: `awk '/^# --- The scout cycle/,/^# --- The clerk
  cycle/' joharness.sh | wc -l` = 153, 2026-10-13 (347 on main before). The
  plan's "under 130" is not met: `scout_walk` (54 lines, kept by the plan)
  plus the reviewer line the clerk needs. Flagged in the pull request body.

## Rejected

- Trimming `scout_walk` to reach 130: its two greps and base-blob skip each
  carry a recorded regression case; a rewrite for a line count risks a
  hidden scout in flight.

## Review

- r1: trigger walk, reviewer asks a question on an unapproved proposal: their counting comment is newer than the newest `scout:` comment, (i) holds → spawn, as the plan expects (no change)
- r2: trigger walk, reviewer comments `approved` (or labels it): the issue passes THE SCOUT GATE, excluded → no spawn, as expected (no change)
- r3: trigger walk, planned issue with a new comment: listed under `planned` by `clerk`, excluded → no spawn, as expected (no change)
- r4: trigger walk, new research request with no comments: no `scout:` prefix and no `scout:` comment, (ii) holds → spawn, as expected (no change)
- r5: trigger walk, the scout answered last: its footed `scout:` comment is newest and not counting, neither (i) nor (ii) → no spawn, as expected (no change)
- r6: shellcheck SC2120: `cycle_age_h` kept a `kind` argument no caller passes once the scout clock went (fixed: parameter dropped from the three cycle readers)
- r7: a scout spawned this pass and not yet pushed left the row `none in flight`, so the next health pass could spawn a second on the same waiting issue — PR447 r1's hole reopened (fixed: `JOHARNESS_PENDING_SPAWNS` holds the row; scout.sh case)

## Blockers

None.

## Where to look

- `joharness.sh` `# --- The scout cycle` to `# --- The clerk cycle`.
