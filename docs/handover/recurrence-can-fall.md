---
workstream: recurrence-can-fall
status: review
branch: claude/loop-research-plan-execute-o35t4g
pr: none
plan: recurrence-can-fall
session: https://claude.ai/code/session_01AE7grFXQWrQ3Qyr1n522Uf
agent: opus
updated: 2026-08-27
next: Retire this file and the plan, open PR, merge under step 7
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

Adversarial, opus depth, separate lenses (arithmetic, portability/hostile
input, doctrine-conformance).

- r1: hostile input — a non-numeric or negative `JOHARNESS_RECURRENCE_WINDOW`
  fell through awk's silent coercion to `w > 0` false, i.e. all-history: a
  typo restored the exact reading this plan exists to delete. Now junk and
  negatives coerce to the default 8; only a literal 0 buys all history.
  (fixed)
- r2: portability — the three counters came back tab-joined and were split
  with literal tab characters inside `${...%%	*}`. Invisible in review and
  one editor away from silently breaking. Replaced with space-separated awk
  output and `read -r`. (fixed)
- r3: arithmetic — verified the implementation against an independent Python
  model of the same definition over the real pair data: W=8 gives 9/28, W=12
  gives 18/38, W=0 gives 64/113. All three agree exactly. (no change needed)
- r4: doctrine — the plan forbids presenting a windowed number as a fall from
  the old cumulative one. `feedback.md` states both today's readings side by
  side and says in terms that they are two questions, not a trend. (no
  change needed)
- r5: scope — `.agents/docs/handover/README.md:313` still cites "36% of
  file-level fixes" with no window named, which is the misreading this change
  exists to prevent. It is outside this plan's declared scope, so not touched
  here. (wontfix — needs its own one-line change; named so the next session
  does not have to rediscover it)
- r6: equivalence — diffed old against new output with the recurrence block
  removed: byte-identical, across the full report, all 8 hot-spot per-path
  reports, and EDGES=2/8/16. Only the intended block moved. (no change
  needed)

## Blockers

None.

## Where to look

- `joharness.sh`, `repeat_pairs` awk — the claim under test.
- `.agents/docs/feedback.md:40,53,208` — the three statements that must end
  up agreeing with the implementation.
