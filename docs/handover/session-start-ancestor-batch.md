---
workstream: session-start-ancestor-batch
status: in-progress
branch: claude/review-optimize-1g74te
pr: none
plan: session-start-ancestor-batch
issue: none
session: https://claude.ai/code/session_01SqqhwxWTrXDj4t8bo2K9cU
agent: opus
updated: 2026-09-11
next: Replace the per-ref --is-ancestor in both hooks with one for-each-ref --merged, then re-pin the perf budgets from counted numbers
---

## Goal

Human asked to "review, optimize". The review found the harness's
most-paid-for loop: both session-start hooks spawn one
`git merge-base --is-ancestor <ref> origin/main` per remote ref, only to
skip refs already merged. 271 of session start's 463 git processes on this
checkout. `git for-each-ref --merged` answers it for every ref in one
process. Plan: `docs/plans/session-start-ancestor-batch.md`.

## Decisions

- **Batch the boolean, not the SHA.** Only the merged/not-merged test is
  batchable. The second `merge-base` per ref returns a SHA its caller needs
  (`owned_at`, churn base) — left alone, and it now runs for the ~11
  unmerged refs instead of all 136, which is the same saving by another
  route.
- **Not a memo cache.** Measured first: 297 merge-base calls, 290 distinct.
  A cache would have saved 7 calls and added a cache. Rejected on the
  number, before writing it.
- **Not the 417KB parse.** `joharness.sh` is 8216 lines and the obvious
  suspect; measured at ~10ms to parse, ~20ms for a trivial invocation.
  Rejected on the number.

## Rejected

- **Splitting joharness.sh to cut startup cost.** 20 invocations of
  `bash -n joharness.sh` take 0.201s total — 10ms each. Parse is not the
  bottleneck and a split would have been a large diff buying nothing.
- **Trimming the selftest to make `ci` faster.** `ci` is 4m37s, of which
  the selftest is 4m17s and ~31k git subprocesses. Real, but the fix there
  is fixture reuse across topics, which changes what the tests prove. The
  session-start loop is a strictly better first cut: it is paid by every
  session rather than by every pull request, and its output is a verifiable
  invariant.

## Review

(pending — step 5)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh` — `while IFS= read -r ref` loop,
  full `refname` spelling.
- `.agents/harness/queue-context.sh:claims` — same test, `refname:short`
  spelling. The two spellings are the trap.
- `joharness.sh:cmd_perf` — `JOHARNESS_PERF_BUDGET_*` defaults to re-pin.
