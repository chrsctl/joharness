---
workstream: recurrence-can-fall
status: in-progress
branch: claude/loop-research-plan-execute-o35t4g
pr: none
plan: recurrence-can-fall
session: https://claude.ai/code/session_01AE7grFXQWrQ3Qyr1n522Uf
agent: opus
updated: 2026-08-27
next: Measure same-file finding gaps to set the lookback window, then implement answer 1
---

## Goal

`feedback.md` calls recurrence the score and `joharness.sh` prints "want
this falling", but the number cannot fall: repeats = N - D, N grows, D
saturates. Fix the instrument, not the reading. The plan requires choosing
one of two answers and shipping it.

## Decisions

- ANSWER 1 (window it), in its lookback form: a repeat counts only when the
  earlier finding on that path is within W edges. Not the plain walk-window
  form. Reason is the plan's own trap — advice and score must point the same
  way. Under a plain walk window a session that follows the printed hot-spot
  advice still raises the score forever; under a lookback, a file that is
  read, fixed properly and then left alone ages out and the score falls,
  while a file that keeps re-drawing findings stays high. That is the
  sentence the doc wants to be able to say.
- Rejected answer 2 (keep cumulative, stop scoring) — defensible and
  honest, but it costs the document its thesis and leaves "did the loop
  work" with no answer at all. Answer 1 keeps a falsifiable score; its cost
  is one named constant, for which the harness already has three precedents.
- Window constant is chosen from measured same-file gap distribution on this
  repo, not picked round. Recorded below once measured.

## Rejected

- Reporting my own independent finding as new: the repo already carries
  `METRIC UNDER REPAIR` at `.agents/docs/feedback.md:44` and this plan. The
  contribution is the reproduction across windows (21% at 8 edges, 43% at
  16, 56% at 50, same repo same moment), not the diagnosis.

## Review

- r1: pending

## Blockers

None.

## Where to look

- `joharness.sh`, `repeat_pairs` awk — the claim under test.
- `.agents/docs/feedback.md:40,53,208` — the three statements that must end
  up agreeing with the implementation.
