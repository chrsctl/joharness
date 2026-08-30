---
plan: perf-window-fixed-cost
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh
---

## Goal

`feedback` and `review` score a sliding window of merged edges (`FB_LIMIT`, 50
by default). The window is fixed in SIZE and not in COST: each merge slides it,
and what slides in costs a different number of commands from what slid out. The
total therefore moves with repo content while the code stands still.

Measured on six consecutive `origin/main` commits, 2026-08-30, each in a
detached worktree:

```bash
for c in $(git log --merges --format=%h origin/main -6 | tac); do
  git worktree add -q --detach "$W" "$c"
  (cd "$W" && JOHARNESS_PERF=always ./joharness.sh perf review)
done
```

`#133` 253/250, `#134` 271/268, `#135` 271/268, `#136` 250/247, `#137` 271/268
(review/feedback). `joharness.sh` and `.agents/harness/` are byte-identical
between `#136` and `#137` — `git diff --name-only b52a800 3e45c5a` lists three
markdown files — and the count moves 21.

The ceiling was 265, inside both bands, so it flapped: GitHub run 336 green,
run 338 red, same code. That was raised to 300 as a stopgap in the commit that
recorded these numbers. This plan removes the need for the stopgap by making
the window fixed in cost, so the ceiling can come back down to something that
detects a regression instead of tracking content.

## Scope

- `joharness.sh:fb_collect` and the loop under it — find the per-edge work
  whose cost varies with the edge, and bound it. The `git merge-base` per edge
  and `fb_workstream` per edge are the first two to measure, not the first two
  to rewrite: measure which one carries the variance before changing either.
- `joharness.sh:perf_rows` — once cost is fixed, re-measure and lower the two
  ceilings to the observed value plus branch overhead. Record the counted
  number and the command in the same commit, per the rule that already governs
  this table.
- `.agents/harness/selftest/` — a case that the count does not move when only
  markdown changes. That is the property being bought, and without a test it
  regresses the next time an edge gets more expensive.

## Out of scope

- Shrinking `FB_LIMIT` to make the number smaller. That changes what the score
  MEANS to make a budget pass, which is the metric-gaming failure
  `.agents/docs/agent-selection.md` now names.
- Caching results across runs. `fb_cache_load` exists; this plan is about the
  cost of a cold run, which is what `perf` measures.
- Touching any other row in the table. The other five are stable.

## Acceptance

- Same command, two commits whose diff is markdown-only, identical counts for
  `feedback` and `review`. This is the whole plan in one check, and it is the
  one the current code fails.
- `./joharness.sh perf` — both rows green at their re-measured ceilings.
- `./joharness.sh ci` — `ci: pass`.
- The new ceilings appear in `perf_rows` with the counted number recorded
  beside them.

## Where to look

- `joharness.sh:fb_collect` — where the window is applied (`FB_LIMIT`).
- `joharness.sh:fb_edges`, `fb_workstream` — the per-edge readers.
- `joharness.sh:perf_rows` — the table and the comment carrying this
  measurement.
- `joharness.sh:perf_count` — how a command is counted, so the fix is measured
  the way the gate measures it.

## Traps

- Do not lower a ceiling by making the measurement mean less.
- Measured number carries the command that produced it, same sentence.
- Never skip, disable or quarantine a test to get green; never kick CI.
