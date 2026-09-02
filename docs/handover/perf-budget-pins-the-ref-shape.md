---
workstream: perf-budget-pins-the-ref-shape
status: done
branch: claude/current-state-review-oxfb7f
pr: none
plan: perf-budget-pins-the-ref-shape
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Nothing — merged behaviour
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
  (fixed as far as it goes, and the rest is recorded rather than hidden: a
  fork per open branch costs 5 and the row still reads ok. Fifteen open branches would
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


### Second verifier round

It found the first rebuild still broken in two ways that mattered, and both
reproduce. The compromise at the heart of them — leaving `feedback` and
`review` on the operator's checkout with a floor beneath them — is gone: every
row is measured against the shape, which now carries a pinned history of 22
merged edges.

- v1: **a signal turned the whole gate into a green tick over nothing.** The
  trap deleted the shape and let bash resume the loop, so every remaining row
  measured a project directory that no longer existed:
  `./joharness.sh perf & sleep 4; kill -INT $!` printed
  `queue-context 0 ... ok`, `handover-guard 0 ... ok`, and exited **0**.
  Neither the 127 guard nor the floor could see it. (fixed — the signal traps
  clean up and EXIT, 130 and 143; re-run, the interrupt now stops after two
  rows and exits 130. A floor under every gated row is the second half.)
- v2: **the floor redded legitimate repositories**, three ways, each
  reproduced: a `--depth 1` clone counted 9 and 6; a repo with fewer than four
  merged edges did the same, which is every consumer for its first four
  merges; and a base branch not named `main` took `review` to 6, because
  `perf_count` pins `HANDOVER_BASE_BRANCH=main` — right for the shape, wrong
  for a row measured against the operator's tree. (fixed by removing the
  cause: those rows are measured against the shape now, where the pin is true
  by construction)
- v3: **`review` still went OVER driven by the operator's tree** — 12
  workstream files on the branch took it to 232 against 230, and this repo's
  own AGENTS.md records 23 accreted in one consumer. The defect this plan
  exists to remove, still live in a row I had left unpinned. (fixed)
- v4: **on the base branch `review` measured an early exit** at 207 and
  printed ok — four times any floor worth setting, because its per-file loop
  never runs there. (fixed — the shape's work branch is one commit ahead, so
  the loop runs every time)
- v5: pinned rows had no floor at all; a pinned row counting 0 printed ok.
  (fixed — the floor is under every gated row, at 15, far below the smallest
  real count of 22 and far above what a broken run produces)
- v6: **`PERF_FLOOR` was an unprefixed environment input** that silently
  disabled the new gate — verbatim the class recorded as fixed under r6, moved
  rather than fixed. The verifier was right to challenge that disposition.
  (fixed — `JOHARNESS_PERF_FLOOR`, and it is the only knob, since `--live` is
  a flag)
- v7: **the shape build depended on the caller's git config.** A global
  `commit.gpgsign = true`, a `core.hooksPath` with a failing pre-commit, or an
  inherited `GIT_DIR` each made it unbuildable, on a developer laptop, for a
  reason nothing in the output named. (fixed — one commit helper with
  `-c commit.gpgsign=false --no-verify`, and the git location variables unset
  rather than shadowed: `local VAR=` on an exported variable keeps the export
  and hands the child an empty `GIT_DIR`)
- v8: "headroom is 14 on every row but the guard" was false — `review` is 20.
  (fixed — both exceptions are named)
- v9: "+26" reproduces as +25 when the fork sits after the `origin/main` skip.
  (fixed — both placements and the reason for the difference)
- v10: the origin-story numbers (422, 1179, 494) re-count as 406, 1163, 490.
  (fixed — re-counted, and the correction says it is one)
- v11: the banner's shape numbers were written, not counted. (fixed — refs,
  plans and edges are all counted from the built shape)
- v12: `perf nosuchrow` built and discarded a 4MB shape before saying it did
  not know the name. (fixed — the name is checked first)
- v13: two selftest needles proved less than their names — one matched the
  `--live` header rather than a row verdict, the other passed because nothing
  was printed at all. (fixed, and the second now says which path it covers
  and which it does not)
- v14: the plan's Acceptance asks for the regression to be proved by `mutate`
  and nothing recorded one. (fixed — two runs, below)

`./joharness.sh mutate`, on this branch, baseline green:

| line replaced | cases redded |
| --- | --- |
| `PERF_PROJECT="${PERF_SHAPE_DIR}/work"` -> `"$ROOT"` | 2 |
| the floor comparison -> `if false` | 4 |

**Cost, re-counted with nothing else running.** `perf` 8.0 / 8.4 / 8.8s
against a baseline of 3.4s — but the baseline was measuring a 107-ref
checkout, and on the old code in this container the whole subcommand took
23.6s and was RED. So `ci` here gets both faster and green. The shape build
alone is 1.4s. The suite is 127s before this change and about 165s after,
measured once each; roughly 15s of that is the new cases and the rest is
every existing perf case now building a shape.
