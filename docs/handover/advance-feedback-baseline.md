---
workstream: advance-feedback-baseline
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: advance-feedback-baseline
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-03
next: Verify the four findings cannot be dispositioned in place, move FB_SINCE, then review and retire
---

## Goal

`./joharness.sh sources` reports the sweep NOT dry on four unmarked findings
that predate the gate which stops new ones reaching that state (PR #181,
merged `847f64e3`). They live in workstream files deleted from every tree, so
they cannot be marked where they were written. Move `joharness.sh:FB_SINCE`
past that gate, and say in the comment which four the bump absorbs.

## Decisions

- **Re-measured on today's `main` before starting, not taken from the plan.**
  `./joharness.sh sources` (2026-09-03) reads 4 unmarked at the default
  baseline and 0 with `JOHARNESS_FEEDBACK_SINCE=847f64e3`. The plan's own
  evidence line was counted 2026-09-02, before PR 195, 196, 197 and 199
  merged; the check that matters is that those merges' own records — 17
  findings on 195, 11 on 199 — are AFTER the new baseline and still counted,
  so this bump cannot hide anything recent.
- **Tier escalated sonnet to opus.** The plan asks `sonnet`; escalation is
  allowed, downgrade is not. Moving this literal moves the stop condition of
  unsupervised mode, and the plan's own first Trap is that a baseline a
  session moves to make its own backlog disappear is the thing PR 161's
  design note warns against.

## Rejected

## Review

## Blockers

None.

## Where to look

- `docs/plans/advance-feedback-baseline.md` — the plan, its Traps, and the
  four findings it names.
- `joharness.sh:FB_SINCE` — the literal, and the comment that has to say what
  the bump absorbs.
