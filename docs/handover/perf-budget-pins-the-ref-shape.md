---
workstream: perf-budget-pins-the-ref-shape
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: perf-budget-pins-the-ref-shape
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Verify the rebuilt version in a clean clone, then finish
---

## Goal

ci is red in every session container of this repo because four perf rows
count a fork per remote-tracking ref and the budgets were calibrated against
a one-branch CI checkout. The plan carries the measurements.

## Decisions

- **A pinned shape, not a bigger number.** The row's own comment forbids
  raising a budget to match a count, and no fixed number is right for every
  checkout anyway. `PERF_EDGES` already made this decision for history; the
  ref shape was the half nobody pinned.
- **A bare origin plus a work clone.** The shape has to survive being
  measured: `handover-context.sh` opens with `git fetch --prune origin`, so
  refs that do not exist in the origin are pruned away mid-table. Refs that
  live in the origin survive, and the shape can then be built once for the
  whole run instead of once per row.
- **The shape carries THIS working tree's harness.** The child resolves its
  own `HARNESS_ROOT` from the project directory it is pointed at, so without
  the copy half the rows measured the shape's last commit and half measured
  the live files.
- **The queue content is pinned too**, three plans and a question. Refs were
  the loud half; a growing queue would walk the same count up for the same
  reason.
- **Budgets recalibrated with 14 of headroom**, sized from the regression
  they must catch rather than from taste: a per-ref fork adds one per ref and
  the shape carries 26.
- **`perf --live` keeps the live number reachable** without paying for it on
  every run. The plan said the live count stays reported; a second full pass
  costs another 7s per `ci`, so it is a flag instead. Deviation from the
  plan's Scope, decided here and recorded rather than smuggled.

## Rejected

- **Falling back to the live tree when the shape cannot be built.** It would
  silently restore the defect — an unpinned count under a pinned budget is
  the red every container was already seeing. It refuses and exits non-zero.
- **A fresh shape per row.** Correct but slower (13s against 7s), and it only
  looked necessary because the first shape was not fetch-stable. Fixing the
  cause made the copy unnecessary.
- **Making the entrypoints cheaper.** The fork per ref may well be worth
  removing; the plan's Out of scope says a change that both moves the
  measurement and changes the thing measured cannot be checked.

## Review

Depth is opus-adversarial, plus a verifier that did not write the diff. Its
first round found the implementation broken in its core and I rebuilt it
rather than patching around it; the numbers below are all from the rebuilt
version.

**What the first design got wrong.** It CLONED this checkout to make the
shape. That carried the source's HEAD as `origin/main`, so every entrypoint
that resolves the base ref still read the operator's queue — the count moved
+12 per plan file against 14 of headroom, which is the defect this plan
exists to remove, one dimension over. It also inherited the source's
shallowness, its detached HEAD under CI, and a refs list that only converged
after some row happened to fetch. The shape is now BUILT FROM NOTHING: an
empty bare origin, a work clone, this tree's harness copied in, and a queue
written by hand.

- r1 (verifier): **the queue was never pinned**, and both the code comment
  and my own r3 said it was. Reproduced: 20 plan files added to a clone took
  `graph` to 158/112 and `queue-context` to 354/128. (fixed — the shape's
  `origin/main` is now a commit the shape itself wrote, carrying three plans,
  a question and a requirement. Re-measured: 41 refs and 12 extra plans move
  the pinned rows by 0.)
- r2 (verifier): **the shape mutated mid-table**, so my claim that single-row
  runs matched the table was false. The merged refs were written into the
  bare origin after the work clone existed, so they only reached it when
  `session-start` fetched: rows before saw 7 refs, rows after saw 27, and
  `queue-context` read 94 alone against 114 in the table. (fixed — every ref
  is pushed from the work clone before any row runs, so both sides are in
  step by construction. Verified: single-row and in-table now agree.)
- r3 (verifier): **`graph` no longer caught the regression its budget is
  for** — it saw 7 refs, so a per-ref fork cost 7 against 34 of headroom.
  (partly fixed, and the rest is recorded rather than hidden: a fork per
  open branch costs 5 and the row still reads ok. Fifteen open branches would
  catch it at 17s a run against 7s. The limit is now stated in `perf_rows`,
  with the measured 104 -> 109, instead of being left for the next reader to
  find.)
- r4 (verifier): **`--live` parsing was a lie.** `main` dispatched
  `cmd_perf "${1:-}"`, one argument, so `perf graph --live` measured the
  shape and `perf --live graph` measured all seven rows live. (fixed — the
  dispatch passes `"$@"`, and a case asserts both orders)
- r5 (verifier): **`--live` gated.** It exited 1 with four rows OVER, so the
  documented debugging flag handed a session a red for its own container's
  branch list. (fixed — `--live` reports and never gates, with a case)
- r6 (verifier): **`PERF_LIVE` was an unprefixed environment input**, so an
  exported value silently switched the gate to the unpinned tree. (fixed — a
  local threaded from the flag, never read from the environment)
- r7 (verifier): **`HANDOVER_BASE_BRANCH` still moved every number**, and
  `HANDOVER_BASE_BRANCH=develop` took `review` to `6 ... ok` — a green tick
  over an entrypoint that exited early. `JOHARNESS_MODE` moved session-start
  by 8 of its 14. (fixed — both pinned in `perf_count`, where a row that
  wants a mode still overrides through its own `env` prefix)
- r8 (verifier): the recorded numbers did not reproduce — `graph 98` had been
  taken against a post-fetch shape the row never sees, and "headroom is 14 on
  every row" was false (graph 34, review 16). (fixed — every number in the
  comment is from the rebuilt version, counted twice, and the one row whose
  headroom is not 14 says so)
- r9 (verifier): "with HEAD left on `main` the handover-guard row counted 3"
  did not reproduce; it is 19 on main and 22 on the work branch. (fixed — the
  claim is gone. The work-branch checkout is kept for the reason that does
  hold: a session's checkout is never the base branch.)
- r10 (verifier): the push refspec `+refs/heads/perf-open-*:refs/heads/*`
  substitutes the captured glob, so the origin's branches were named `0`
  through `4`. Harmless to a count, and exactly what a later filter keyed on
  the name reads as absent. (fixed — explicit names on both sides)
- r11 (verifier): **no trap**, so an interrupted `ci` left megabytes of shape
  in the temp directory. (fixed — `trap ... EXIT INT TERM`, cleared on the
  normal path)
- r12 (verifier): the header stated a shape the rows did not have, and on a
  0-ref source said the checkout "would count higher". (fixed — the header
  states what the shape is and what this checkout carries, without the
  comparison)
- r13 (verifier): **the build cost was never recorded**, which the plan's
  Acceptance requires. (fixed — measured on this branch, 2026-09-02: `perf`
  7.6s against the baseline's figure below, and the suite 164s. The shape is
  built once per invocation, so the suite pays it once per `perf` call its
  own cases make.)
- r14 (verifier): the commit was unpushed, so the work was invisible to other
  sessions. (fixed — pushed)
- r15: **the live rows could still measure an early exit.** Left measuring
  this checkout because `PERF_EDGES` already pins them, they printed `6 ...
  ok` in a tree with nothing to review. Building them a synthetic history
  closed it and cost 5s a run; a floor closes it for nothing. (fixed — under
  the floor a row is TOO LOW and red, and the case pins it)
- r16: two of my own, both caught by `ci` rather than by reading. SC2016
  backticks inside a single-quoted `printf` — fourth instance in this repo's
  records — and SC1007 for `VAR= \` in the pinned-environment block.
  (fixed)

