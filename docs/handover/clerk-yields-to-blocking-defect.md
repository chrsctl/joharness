---
workstream: clerk-yields-to-blocking-defect
status: in-progress
branch: manage/clerk-yields-to-blocking-defect
pr: none
plan: clerk-yields-to-blocking-defect
issue: none
session: https://claude.ai/code/session_01J1YMK3HUXzoWdaRTTWngzF
agent: opus
updated: 2026-10-29
next: Rerun ci and verify (verify red on Docker Hub 429), then finish
---

## Goal

A park-called clerk must not wait on an in-flight clerk that cannot merge:
when the early clerk is due and the in-flight clerk pushed nothing since the
first park, dispatch prints the clerk DUE row anyway (at most two clerks).

## Decisions

- A1: confirmed — `cmd_dispatch` prints IN FLIGHT when `n_clerk > 0`, ahead of the `kstate = due` test (the plan-checker's wording fix: after unreadable/off).
- A2: confirmed as written — a consumer record, not re-taken; the plan says so.
- One state, not a dispatch special case: `clerk_yield` (called from `clerk_due`) rewrites the lone in-flight row to `yielded`, which `scout_branches` drops, so dispatch, `clerk`, the role prelude (`role_start_stop`) and `role_suppressed` all read it alike.
- Signal: tip committer date (`git log -1 %ct`) before now minus `CLERK_EARLY_AGE` (minutes since the oldest qualifying park). Only when exactly one clerk is in flight: at most two.
- Twin check: once the park-called clerk's plan names the issue the early due ends and the stuck clerk reads in flight again, so `clerk_twin_rows` reads the same park with `clerk_park_early any` (planned issues count) and drops the ONE other row whose tip predates it. No park, or two such rows: every row counts.
- Cadence due: `clerk_due` reads the park too when a clerk is in flight, so a cadence-spawned clerk that never lands yields alike. `CLERK_EARLY*` reset per `clerk_due` call.

## Rejected

## Review

- r1: (plan-checker) prelude `role_start_stop` would stop the new clerk on IN FLIGHT (fixed: `yielded` drops the row before the report prints)
- r2: (plan-checker) twin check is `role_twin_run` code; the new clerk sorts after the stuck one (fixed: `clerk_twin_rows`)
- r3: (plan-checker) park-called clerk not observable (fixed: no marker needed, it pushes after the park so never yields; twin rule is time-based)
- r4: (plan-checker) pushed-nothing signal undefined (fixed: committer date vs oldest park, lone in-flight row only)
- r5: (plan-checker) at-most-one texts in orchestrator-reference.md, orchestrated.md roles row, dispatch tail row (fixed: each names the yielded exception; scope widened)
- r6: (plan-checker) selftest file not in scope (fixed: dispatch-park.sh added to scope)
- r7: (plan-checker) overlap with dispatch-holds-shared-defect in cmd_dispatch (no change: different lines, git merges it)
- r8: (plan-checker) acceptance 1 not a command (no change: the cases sit in dispatch-park.sh; 7 fail with joharness.sh reverted, 181 pass with it)
- r9: (plan-checker) acceptance 2 consumer checkout not runnable here (no change: the fixture is a consumer-shaped checkout; dispatch prints `clerk     : DUE`)
- r10: (plan-checker) acceptance 3/4 give pass output only (no change: the counts are read)
- r11: (plan-checker) A1 wording partly wrong (fixed: recorded corrected in Decisions)
- r12: (plan-checker) quoted string spacing (no change: cosmetic in the plan)
- r13: (plan-checker) which DUE row (fixed: both status line and tail spawn row, `clerk_due=1` as usual)
- r14: (plan-checker) second clerk's pull request may hit the same red (wontfix: the plan then sits on a branch, read as planned; the goal is the early clerk coming, not its merge)
- r15: (plan-checker) gx timeline unverified (no change: plan marks it so)
- r16: (plan-checker) cadence-gap paragraph stale before the change (fixed: names clerk_park_early, drops the retired plan's pointer)
- r17: (verifier) verifier prompt carried focus and the workstream pointer beyond subagents.md's fields (no change: the review ran; noted for the next spawn)
- r18: (verifier) yield never fires while the cadence reads due (fixed: clerk_due reads the park when a clerk is in flight; selftest JOHARNESS_CLERK_HOURS=2 case)
- r19: (verifier) clerk_twin_rows relaxed the twin rule with no park at all (fixed: drops a row only against the same park read, planned or not)
- r20: (verifier) commit-clock skew could let three clerks run through the twin rule (fixed: the rule no longer reads this branch's own commit time; tip vs park, exactly one row)
- r21: (verifier) at-most-two guard untested, mutant n -ge 1 survived (fixed: two stale clerks case, read through `clerk`; mutant now fails 1)
- r22: (verifier) a live clerk with unpushed plans can be yielded (wontfix: the plan's heuristic; an hour silent past a park is the signal)
- r23: (verifier) hand-started audit no longer held by a yielded clerk (wontfix: dispatch still suppresses through role_spawned; a yielded clerk holds nothing by design)
- r24: (verifier) orchestrated.md dated incident story and history wording (fixed: status-quo wording, marked not re-taken)
- r25: shellcheck SC2015 on clerk_twin_rows skip line (fixed: if-then)

## Blockers

None.

## Where to look

- `joharness.sh:clerk_park_early` — the early due.
- `joharness.sh:cmd_dispatch` — where IN FLIGHT wins.
