---
workstream: findings-with-the-fix
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: findings-with-the-fix
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Research the plan's anchors and its query claim against the code, then build the lint
---

## Goal

`docs/plans/findings-with-the-fix.md`. Loop step 5 requires a review finding
to be recorded BEFORE its fix and in the SAME commit; nothing checks either
half. Only the second half is checkable — git records what landed in a
commit, never the order it was typed — and the plan says so rather than
pretending otherwise. What survives is worth having: a finding line added by
a commit that touches nothing but the workstream file means the findings
were written up as a separate documentation pass, which is the shape the
rule exists to stop.

## Decisions

- Taken at opus, above the plan's `sonnet`. Escalation is allowed and
  downgrade is not; the plan's own Traps name the opus condition for this
  work — a gate that cannot separate its false positives from the violation
  is wrong-but-plausible.

## Rejected

- `docs/plans/orchestrated-run.md`, which the queue ranks first. Not
  actionable and not this session's to unblock. Two of its preconditions are
  the human's by the plan's own words, and the only remaining deliverable —
  the Runs row saying what stopped run 3 — needs run 3 to have stopped.
  Re-counted 2026-09-17T01:21Z, `list_sessions` filtered to this account:
  two manager sessions `SESSION_STATUS_RUNNING` with `updated_at` inside the
  last minute. The run is live, so the row cannot be written, and the
  heartbeat the plan needs still does not exist.
- The edge branch naming pull request #10. Re-read from GitHub this session
  rather than inherited: `state: closed`, `merged: false`, closed
  2026-08-21. The session-start hook reads git and says closed, open and
  merged-elsewhere are the same bytes there — checked, and it is closed, so
  it is not edge work to finish. Deleting the branch is the human's.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:fb_fix_map` — the plan says read this first: it already
  keys on the stable `r<N>` id across a commit range rather than on a
  bullet's current text.
- `joharness.sh:lint_finding_ids` — the bullet parser and the report-only
  doctrine.
- `joharness.sh:lint_finding_markers` — the same parse, the other strength.
