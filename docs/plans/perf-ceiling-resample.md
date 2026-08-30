---
plan: perf-ceiling-resample
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:joharness.sh
---

## Goal

#138 raised the `feedback` and `review` ceilings to 300 as a stopgap, because
265 sat inside the measurement's own noise band and flapped. #141 then cut
per-edge cost from ~10.8 commands to ~8.8. The comment beside the number says
what has to happen before it comes down:

> Lower it only after several merges have been sampled the way the six above
> were, and record them here when you do.

Several merges have since landed (#141 through #144). Sample the band and lower
the ceiling to something that can detect a regression again.

## Scope

- `joharness.sh:perf_rows` — re-measure and lower `JOHARNESS_PERF_BUDGET_FEEDBACK`
  and `JOHARNESS_PERF_BUDGET_REVIEW`, recording the samples in the comment that
  already carries the earlier six.

## Out of scope

- Lowering on one sample. That is the mistake #138 fixed and #141 declined to
  repeat; a ceiling must sit above the band, not inside it.
- Changing what `feedback` measures to make the number smaller. Shrinking
  `PERF_EDGES` or `FB_LIMIT` changes the score's meaning to pass a budget —
  the metric-gaming failure `.agents/docs/agent-selection.md` names.
- Any other row in the table. The other five are stable.

## Acceptance

- At least five `origin/main` commits sampled, each in a detached worktree, with
  the command and the counts recorded in `perf_rows` beside the existing six.
- The new ceiling sits ABOVE the observed maximum plus the branch overhead a
  working branch adds for its own workstream files (~+5, measured 2026-08-30).
  State both numbers.
- `./joharness.sh perf` — both rows green at the new ceilings.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `joharness.sh:perf_rows` — the ceilings and the measurement comment.
- `joharness.sh:PERF_EDGES` — the knob that pins the walk; vary it in the file,
  because `perf_count` overrides the environment variable.

## Traps

- `JOHARNESS_FEEDBACK_EDGES` set from outside returns a flat line and reads as
  confirmation. It is the override. Vary `PERF_EDGES` in the file.
- Measured number carries the command that produced it, same sentence.
