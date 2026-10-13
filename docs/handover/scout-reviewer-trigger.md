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
next: ci and verify on the merged head, then finish
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
  cycle/' joharness.sh | wc -l` = 157, 2026-10-13 (153 before the no-brief off branch) (347 on main before). The
  plan's "under 130" is not met: `scout_walk` (54 lines, kept by the plan)
  plus the reviewer line the clerk needs. Flagged in the pull request body.

## Rejected

- Trimming `scout_walk` to reach 130: its two greps and base-blob skip each
  carry a recorded regression case; a rewrite for a line count risks a
  hidden scout in flight.

## Review

- r1: trigger walk, reviewer asks a question on an unapproved proposal: their counting comment is newer than the newest `scout:` comment, (i) holds → spawn, as the plan expects (no change)
- r2: trigger walk, reviewer comments `approved`: after merging #475 the comment is the gate (THE SCOUT GATE 1-2), the issue is approved and excluded → no spawn, as expected; before that merge, a label-only gate made this spawn (no change: re-walked on the merged tree)
- r3: trigger walk, planned issue with a new comment: listed under `planned` by `clerk`, excluded → no spawn, as expected (no change)
- r4: trigger walk, new research request with no comments: no `scout:` prefix and no `scout:` comment, (ii) holds → spawn, as expected (no change)
- r5: trigger walk, the scout answered last: its footed `scout:` comment is newest and not counting, neither (i) nor (ii) → no spawn, as expected (no change)
- r6: shellcheck SC2120: `cycle_age_h` kept a `kind` argument no caller passes once the scout clock went (fixed: parameter dropped from the three cycle readers)
- r7: a scout spawned this pass and not yet pushed left the row `none in flight`, so the next health pass could spawn a second on the same waiting issue — PR447 r1's hole reopened (fixed: `JOHARNESS_PENDING_SPAWNS` holds the row; scout.sh case)
- r8: (verifier) F1 no brief on base: a waiting issue respawned a scout every run that only reported NO BRIEF and posted nothing (fixed: no brief = `off` in `scout_state`, so neither dispatch nor `/scout` runs one; scout.sh brief cases)
- r9: (verifier) F1 any failure before the one reply (comment write refused every pass) still re-fires once per orchestrator run (wontfix: the old clock and 24h re-arm were the bound and the plan removes both; bounded by one fable session per run, and the scout's report names the refusal for the human)
- r10: (verifier) F2 merge with origin/main conflicted and auto-merged a §5 line naming the deleted §0.6 ceiling; the reviewer line said label (fixed: merged, §5 line rewritten, `reviewer  :` says comment, scout.md greps 0 for ceiling)
- r11: (verifier) F3 r2's walk was wrong against the label gate on the unmerged tree (fixed: re-walked after the merge, r2 rewritten)
- r12: (verifier) F4 any commenter could quiet the trigger with an unfooted `scout: ok` (fixed: trigger and §4 use THE SCOUT GATE's scout comment, footed and by a write-access author)
- r13: (verifier) F5 `planned   : UNREADABLE` or a failed comments page read as not planned / not approved (fixed: a failed reading = that issue needs nothing this pass, in orchestrate.md and §4)
- r14: (verifier) F6 a revision left at `scout: revision` never re-fired the trigger (fixed: trigger (iii); §4 names §5's "First" as its one reply)
- r15: (verifier) F7 orchestrate.md paraphrased the counting comment more strictly than clerk.md §2 (fixed: cites §2 only)
- r16: (verifier) F8 stale text: help line "is due", clerk comment "holds the scout", orchestrated.md "scout prints held", selftest clock comments (fixed)
- r17: (verifier) F9 scout.sh refuted "waits for a human to merge", a string neither side ever printed (fixed: case removed)
- r18: (verifier) F10 "at most 3 proposals" carried no provenance (fixed: marked a written number, #461)

## Blockers

None.

## Where to look

- `joharness.sh` `# --- The scout cycle` to `# --- The clerk cycle`.
