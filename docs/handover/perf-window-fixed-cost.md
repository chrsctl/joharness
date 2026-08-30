---
workstream: perf-window-fixed-cost
status: review
branch: claude/perf-window-fixed-cost
pr: none
plan: perf-window-fixed-cost
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Take the fb_label fork saving named in the corrected plan; it is one fork per edge with no behaviour change
---

## Goal

Claimed `perf-window-fixed-cost`. Research before code found that the plan's
own Goal — and the comment I merged in #138 — state a mechanism that is
FALSE. Correcting the record is the work; the optimisation the plan describes
is still wanted and still sonnet-sized, but it cannot be built on a wrong
premise.

## Decisions

- Measured before touching anything, as the plan instructs. That is what
  caught it: the plan says "measure which one carries the variance before
  changing either", and doing so falsified the plan's own framing.
- Correcting the merged comment outranks doing the optimisation. A comment
  asserting a mechanism the code does not have is what stops the next reader
  checking — this repo's own words, in `fb_cache_load`, about exactly this
  failure.

## Rejected

- Implementing the batching win in the same change. Two candidates looked
  clean (fold `sort -u` into the awk; take `%s` in `fb_edges`' existing
  format so `fb_label` stops forking per edge) and the first is not
  behaviour-preserving: selection among two candidate workstream files is by
  sorted order today, and 2 of 51 edges carry two candidates. A cost fix that
  silently changes which document is scored is the metric-gaming failure this
  repo just graduated a finding about.

## Review

opus, adversarial. The subject of the review is partly my own merged work.

- r1: #138 merged a comment asserting a mechanism I had not verified — that
  `FB_LIMIT`'s 50-edge window slides with every merge and so drifts the count.
  Both halves are false: `perf_count` overrides `JOHARNESS_FEEDBACK_EDGES` with
  `PERF_EDGES`, so the measured path never reads `FB_LIMIT`, and `PERF_EDGES`
  pins the walk rather than sliding it. The claim was inferred from `FB_LIMIT`
  existing, and it read plausibly enough to survive its own review. Corrected
  in `perf_rows` and in the plan. (fixed)
- r2: the same trap caught me twice in one session. Sweeping
  `JOHARNESS_FEEDBACK_EDGES` from outside returned an identical count at 1, 5,
  20 and 50 edges, and I read that flat line as "the edge walk costs nothing" —
  a second wrong conclusion from the same override. A knob that silently
  ignores you returns a flat line, and a flat line looks like evidence. The
  corrected comment names this explicitly so the next reader does not run the
  same sweep and believe it. (fixed)
- r3: what #138 actually established is unharmed — the ceiling sat inside the
  observed band (247-276 against 265) and therefore flapped, which is measured
  and reproducible from GitHub's own run history. Only the mechanism was
  misnamed. Checked before rewriting, so the correction does not quietly
  withdraw a finding that still holds. (no action)
- r4: rejected folding `sort -u` into the awk in `fb_workstream` even though it
  saves a fork per edge. Selection among candidates is by sorted order and 2 of
  51 edges carry two candidates, so order-of-appearance would change which
  document is scored. Recorded in the plan as a named trap rather than left for
  the next session to find attractive. (wontfix)
- r5: this branch does NOT retire the plan file. The plan is corrected, not
  done — the optimisation is still owed, and deleting it would read as
  finished. The workstream file retires; the plan goes back to the queue with
  a Goal that is now true. (no action)

## Blockers

None.

## Where to look

- `joharness.sh:PERF_EDGES` — the knob that actually pins the window during
  measurement.
- `joharness.sh:perf_count` — where it overrides JOHARNESS_FEEDBACK_EDGES,
  which is why an outside-in sweep of that variable reads as flat.
- `joharness.sh:fb_workstream` — the per-edge forks.
