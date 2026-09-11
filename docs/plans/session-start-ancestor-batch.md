---
plan: session-start-ancestor-batch
urgency: normal
agent: sonnet
effort: high
needs: none
scope: .agents/harness/handover-context.sh, .agents/harness/queue-context.sh, joharness.sh, .agents/harness/selftest.sh, .agents/harness/selftest/handover-context-merged-filter.sh
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
- `.agents/harness/selftest.sh` and a new topic under
  `.agents/harness/selftest/` — the cases pinning the rewrite.

## Out of scope

- Every OTHER `merge-base` call. The second call per ref returns a SHA the
  caller needs (`owned_at`, churn base); only the boolean is batchable. That
  second call ALREADY ran for the unmerged refs only — the `--is-ancestor`
  it follows has always come first and `continue`d — so this change neither
  adds to it nor saves anything on it. The whole saving is the boolean.
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

6. IN A CONSUMER, after the sync that carries this. All three files ship
   (`ci`'s ship-scope stage says so), and a consumer carries no selftest —
   the cases above are canonical-only, so the bar there is the budget and
   the output:

       ./joharness.sh perf          # session-start, queue-context,
                                    # queue-orchestrated and drain each
                                    # `ok` against the re-pinned budgets

   The four re-pinned rows are `shape` rows, measured against the shape
   `perf_shape` builds rather than the consumer's own tree, so their counts
   do not move with a consumer's ref count and the tightened budgets are
   safe to ship. That is the claim this check tests: a consumer whose rows
   read `ok` confirms it; one that reds has found a budget cut too close,
   and the fix is the counted number there, not a revert here.

   And the hook output, which is the invariant the whole change rests on:

       .agents/harness/handover-context.sh   # lists the same branches
       .agents/harness/queue-context.sh      # claims the same plans
                                             # as before the sync

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
