---
plan: session-start-ancestor-batch
urgency: normal
agent: sonnet
effort: high
needs: none
scope: .agents/harness/handover-context.sh, .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest/perf.sh
---

## Goal

Session start costs 463 git processes on this checkout and 271 of them —
59% — are one `git merge-base --is-ancestor <ref> origin/main` per remote
ref, asked only to skip refs already merged. `git for-each-ref --merged`
answers the same question for every ref in ONE process. Both hooks run
before the first prompt of every session, every mode, every tier, so the
per-ref spawn is the most-paid-for loop in the harness.

Counted 2026-09-11 on this checkout (136 refs, 125 of them merged), with a
PATH shim logging every git invocation:

    session-start   463 git calls, 297 merge-base
    drain           469 git calls, 297 merge-base
    handover-context.sh   266 calls, 136 of them --is-ancestor
    queue-context.sh      197 calls, 135 of them --is-ancestor

## Scope

- `.agents/harness/handover-context.sh` — the `--is-ancestor` at the top of
  the ref loop. Build the merged set once before the loop; test membership.
- `.agents/harness/queue-context.sh` — the same call in the `claims` loop.
- `joharness.sh` — re-pin the perf budgets the change moves
  (`JOHARNESS_PERF_BUDGET_*` defaults). Counted numbers only, re-measured
  after the change, never estimated.
- `.agents/harness/selftest/perf.sh` — only if a pinned number lives there.

## Out of scope

- Every OTHER `merge-base` call. The second call per ref returns a SHA the
  caller needs (`owned_at`, churn base); only the boolean is batchable, and
  it now runs for the ~11 unmerged refs instead of all 136.
- Memoizing merge-base. Measured: 297 calls, 290 distinct. A cache saves 7.
- Reducing `log`/`show`/`ls-tree` counts, the next three after merge-base.
  Separate question, separate plan.
- Any change to what either hook PRINTS. This is a spawn-count change; the
  output is a byte-for-byte invariant and the acceptance below pins it.

## Acceptance

1. Output unchanged, both hooks, before vs after:

       .agents/harness/handover-context.sh > /tmp/hc.after
       .agents/harness/queue-context.sh    > /tmp/qc.after
       diff /tmp/hc.before /tmp/hc.after && diff /tmp/qc.before /tmp/qc.after

2. `--is-ancestor` is gone from both ref loops — one `for-each-ref --merged`
   each, and the per-ref count drops to the unmerged refs only.

3. `./joharness.sh ci` — `ci: pass`, and the perf table's counted numbers
   for `session-start`, `drain` and `queue-context` are LOWER than before
   and under their re-pinned budgets.

4. `./joharness.sh verify` — 0 failed.

5. The missing-base-ref fallback keeps current behaviour: with no
   `origin/<base>`, `--is-ancestor` exits 128 and skips nothing, so the
   batched set must be EMPTY and skip nothing. A selftest case pins it.

## Where to look

- `.agents/harness/handover-context.sh` — the `while IFS= read -r ref` loop;
  the comment block above it already spells the two-pass design this fits.
- `.agents/harness/queue-context.sh:claims` — same call, `refname:short`
  spelling, so the merged set there needs the short spelling too.
- `joharness.sh:cmd_perf` — the budget row list, `JOHARNESS_PERF_BUDGET_*`.

## Traps

- Ref spelling differs between the two hooks: `handover-context.sh` reads
  full `refname`, `queue-context.sh` reads `refname:short`. A set built in
  one spelling and tested in the other matches NOTHING and silently stops
  skipping merged branches — the listing then fills with finished work.
- Membership test must be exact-line, not substring. `origin/claude/foo`
  is a substring of `origin/claude/foo-2`; `grep -qxF` or a newline-delimited
  case, never `grep -q`.
- Trust counted numbers, never written numbers. The numbers in this Goal are
  this checkout's on 2026-09-11; re-count, do not copy.
