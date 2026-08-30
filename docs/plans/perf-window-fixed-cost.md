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

`feedback` and `review` cost about **11 commands per merged edge**, and
`PERF_EDGES=20` pins how many edges the measurement walks. So the number does
not drift with repo size — it tracks the CONTENT of whichever 20 edges are
newest, and two edges' worth of change moves it ~20.

Measured on `main` at `fbae21d`, 2026-08-30:

```bash
for n in 5 10 20 30; do
  sed -i "s/^PERF_EDGES=.*/PERF_EDGES=$n/" joharness.sh
  JOHARNESS_PERF=always ./joharness.sh perf feedback
done
#  5 -> 94    10 -> 164    20 -> 276    30 -> 380    0 (unbounded) -> 1624
```

Per edge, that is roughly: a `git merge-base`, a name-only walk over
`docs/handover`, an awk and a sort, then a `git log -1` and a `git show` per
candidate workstream file — 0, 1 or 2 candidates, measured 7/42/2 across 51
edges — plus a findings awk and a `git log -1` for the label.

This is what made the ceiling flap: at ~11 commands an edge, the observed band
was 247-276 against a ceiling of 265, so #138 lifted it to 300 as a stopgap.
Cutting per-edge cost is what lets it come back down to something that detects
a regression instead of tracking content.

**Correction, and why this plan reads differently now.** Its first version said
the drift came from `FB_LIMIT`'s 50-edge window sliding with every merge. That
was wrong twice: the measured path never sees `FB_LIMIT` (`perf_count`
overrides `JOHARNESS_FEEDBACK_EDGES` with `PERF_EDGES`), and the window is
pinned rather than sliding. Sweeping `JOHARNESS_FEEDBACK_EDGES` from outside
returns a flat line, which reads as confirmation and is actually the override.
Vary `PERF_EDGES` in the file, as above.

## Scope

- `joharness.sh:fb_collect` and the loop under it — cut forks per edge. Two
  candidates are already identified and they are NOT equal:
  - `fb_label` runs `git log -1 --format=%s` per edge, while `fb_edges`
    already runs a `git log` that could carry `%s` in its format. One fork per
    edge, no behaviour change. Take this one.
  - folding `sort -u` into the awk in `fb_workstream` also saves a fork per
    edge, but selection among two candidate files is by SORTED order today and
    2 of 51 edges carry two candidates. Order-of-appearance would silently
    change which document is scored. Only do this with the sort preserved.
- `joharness.sh:perf_rows` — once cost is fixed, re-measure and lower the two
  ceilings to the observed value plus branch overhead. Record the counted
  number and the command in the same commit, per the rule that already governs
  this table.
- `.agents/harness/selftest/` — a case that the count does not move when only
  markdown changes. That is the property being bought, and without a test it
  regresses the next time an edge gets more expensive.

## Out of scope

- Shrinking `FB_LIMIT` or `PERF_EDGES` to make the number smaller. That
  changes what the score MEANS to make a budget pass, which is the
  metric-gaming failure `.agents/docs/agent-selection.md` now names.
- Any change to WHICH workstream document an edge is scored on. Cost is the
  target; selection is not.
- Caching results across runs. `fb_cache_load` exists; this plan is about the
  cost of a cold run, which is what `perf` measures.
- Touching any other row in the table. The other five are stable.

## Acceptance

- Per-edge cost measurably lower: re-run the `PERF_EDGES` sweep above and show
  the slope between 10 and 30 edges has dropped from ~11 commands per edge.
  The sweep is the check, because it isolates per-edge cost from the fixed
  base.
- `feedback` prints the same coverage, recurrence and hotspot lines before and
  after on the same commit. Cost changed, score did not — diff the two
  outputs, do not eyeball them.
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
