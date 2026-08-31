---
workstream: marker-gate-needs-no-done
status: in-progress
branch: claude/marker-gate-needs-no-done
pr: none
plan: marker-gate-needs-no-done
issue: none
session: https://claude.ai/code/session_01Samg4LcLJBw1jg4RfCtT8Z
agent: sonnet
updated: 2026-08-31
next: Add selftest cases (review.sh) proving the review-to-retire leak reds, run mutate against the fix, then ./joharness.sh ci and .agents/harness/selftest.sh
---

## Goal

`docs/plans/marker-gate-needs-no-done.md`: `lint_finding_markers` only reds
on `status: done`, and nothing requires a branch to ever say it — a branch
that goes `review` straight to the retire commit merges undispositioned
findings unchecked. PR 172's own r5 is the evidence.

## Decisions

- RED trigger is the retire commit itself, not `status: done`. New
  `fin_retired_own(ref)` (joharness.sh) reads the LOG (added-then-deleted
  within this branch's own commits under `docs/handover`), not the tree —
  `fin_adds_at` is tree-based and is blind at exactly the moment retirement
  happens, since the retire commit deletes the file from HEAD's tree.
- `fin_strength` gains a third value, `retired`, alongside `done`/`edge`.
  `fin_gate` (finish's own gate) is untouched by this: a retired file has
  no `adds`, so its `n == 0` branch already returns clean regardless of
  strength — only `lint_finding_markers` treats `retired` as a red trigger.
- `(recorded` stays OUT of `fb_marker`'s vocabulary. It names no outcome —
  every finding under `## Review` is already recorded by being there, and
  several historical uses are bare `(recorded)` with nothing after it: not
  fixed, not wontfix, not a reason. Accepting it as a fourth verdict would
  let a finding close itself by restating what section it's in — the exact
  silent drop step 5 forbids. Findings marked only `(recorded` keep
  counting as unmarked, same as before this branch, going forward and in
  the historical pile FB_SINCE already bounds. Reasoning lives beside
  `fb_marker` itself (joharness.sh) and in the comment above
  `lint_finding_markers`'s TWO STRENGTHS block.

## Rejected

- Making `status: done` mandatory. The plan's own Trap: that moves the
  problem to a field rather than removing the dependence on one — a hurried
  session would just as easily skip a mandatory field as an optional one,
  and the gate would still fire on the wrong signal (a field) instead of the
  fact (the file is gone).

## Review

(mid-build — filled before the fix commit, per protocol)

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_markers` — the gate; now reds on `done` OR
  `retired`.
- `joharness.sh:fin_strength` — third strength added.
- `joharness.sh:fin_retired_own` — new; log-based retirement detection.
- `joharness.sh:fb_marker` — vocabulary; `(recorded` decision recorded
  beside it.
- `.agents/harness/selftest/review.sh:613` — existing "THE RETIRE COMMIT"
  case only checked content was read, never that `ci` reds. Needs an exit-
  code assertion plus a new case for the `review` (never `done`) shape the
  plan names as the leak that matters.
