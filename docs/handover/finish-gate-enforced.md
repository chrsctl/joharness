---
workstream: finish-gate-enforced
status: in-progress
branch: claude/finish-gate-enforced
pr: none
plan: finish-gate-enforced
session: https://claude.ai/code/session_019c3kktaEvDBAnDv1K2i65p
agent: sonnet
updated: 2026-08-25
next: Factor the adds computation out of cmd_finish and call it from cmd_ci at the edge only.
---

## Goal

`./joharness.sh finish` is a correct gate `cmd_ci` never calls, so step 7
keeps not happening — `docs/handover/joharness-minify-optimize.md` has been
on `main` since 2026-08-24 through 22 merges. Plan:
`docs/plans/finish-gate-enforced.md`.

## Decisions

- **Share `cmd_finish`'s computation, never a second copy.** The gate and
  the command must agree; two implementations of "would this merge add a
  workstream file" is the drift this repo names everywhere else.
- **Edge only, via the existing `review_at_edge`.** The plan says to reuse
  the condition `JOHARNESS_REVIEW=on` already has rather than invent a
  second notion of "the edge".
- **Own files only.** Inherited stale files are reported, never red.
  A gate that fails for another session's omission is one sessions learn
  to route around — the same failure that produced this defect.
- **Always on, not behind a flag.** `JOHARNESS_REVIEW` is off by default
  because whether a review is deep enough is a judgment. Whether a branch
  still carries its own finished workstream file is not a judgment, and
  the defect being fixed is precisely that the check was optional.

## Rejected

- **Failing on inherited files too.** It would red every branch until
  somebody cleans main, which punishes the wrong session and teaches the
  gate is noise.
- **Gating the plan file's deletion.** `cmd_finish` already refuses to,
  and says why: whether a plan is done is a judgment, and a gate that
  guesses at one is a gate the next session learns to ignore.

## Review

(none yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_finish` — the gate, already correct.
- `joharness.sh:cmd_ci` — the `review_on` block, the shape to copy.
- `joharness.sh:review_at_edge` — the edge test to reuse.
