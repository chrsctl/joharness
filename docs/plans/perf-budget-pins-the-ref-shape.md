---
plan: perf-budget-pins-the-ref-shape
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

`./joharness.sh ci` is RED in every session container of this repo, on a
clean `main`, and has been for as long as the container has carried the
repo's branches. Four perf rows count a fork per remote-tracking ref, and the
budgets were calibrated against a GitHub checkout, which fetches one branch.

Measured 2026-09-02, same code, three shapes:

| shape | refs | graph | session-start | queue-context | drain |
| --- | --- | --- | --- | --- | --- |
| this container | 107 | **422** | **1179** | **494** | **1179** |
| single-branch clone | 1 | 19 | 62 | 39 | 65 |
| budget | | 260 | 700 | 350 | 700 |

The slope is linear and clean — `git clone --single-branch` of this repo,
then `git update-ref` to add merged refs, `./joharness.sh perf graph`:

| refs | graph | session-start |
| --- | --- | --- |
| 1 | 19 | 62 |
| 6 | 24 | 72 |
| 21 | 39 | 102 |
| 51 | 69 | 162 |

`graph` is `18 + 1/ref`; `session-start` is `60 + 2/ref`. In the live repo
the slope is steeper — 3.8/ref for `graph` — because an unmerged branch
carrying a workstream file costs more than a merged one.

**So the number describes the operator's branch list, not the code.** A gate
that is red for everyone is a gate sessions learn to route around, and this
one has already been explained away twice in merged review records as
"container-local" without anybody measuring why.

## The fix this file argues for, and the precedent it follows

`joharness.sh:PERF_EDGES` already does exactly this for history:

> Caps pinned during measurement, so the number describes the CODE and not
> how much history this repo has accumulated since.

History was pinned. The ref shape was not. Pin it the same way: measure every
row against a **pinned repository shape** rather than against whatever the
operator's checkout happens to hold.

A `--single-branch` clone of the repo takes 281ms here, keeps the real
history (so `feedback` and `review` keep counting what they count today —
204/207 against 204/212 live) and reduces the ref list to one. On top of it
the measurement adds a FIXED set of refs, including unmerged branches
carrying workstream files, so the loops that cost the most still run.

## Scope

- `perf` builds the pinned shape once per invocation and measures every row
  against it, with the entrypoint still taken from THIS tree so the number
  describes this code.
- The fixed shape includes at least one unmerged branch carrying a workstream
  file. The claims loop in `queue-context.sh` and the ownership walk in
  `handover-context.sh` are the dearest paths, and a shape without one leaves
  them unmeasured.
- Budgets recalibrated against that shape, each with the counted number and
  the command that produced it recorded beside it.
- The live repo's own count stays REPORTED, so nothing is lost — it is just
  not what gates.

## Out of scope

- Making the entrypoints cheaper. The fork per ref may well be worth
  removing, but that is a different plan and this one must not smuggle it in:
  a change that both moves the measurement and changes the thing measured
  cannot be checked.
- Raising a budget to match a count. The row's own comment forbids it and it
  would not work anyway — no fixed number is right for every operator.
- Deleting branches to make the number small. That is a human action and it
  fixes one checkout, not the gate.

## Acceptance

- The same tree measured in a 1-ref clone and in a 107-ref container produces
  the same counts, within noise. Reproduce both.
- `./joharness.sh ci` is green in a session container of this repo.
- A regression in kind is still caught: put a per-item fork back inside a ref
  loop and the row goes OVER. Proved by `mutate`, not by argument.
- A shape that cannot be built is reported, not silently replaced by the live
  repo. A green tick over nothing is the failure this whole subcommand exists
  to notice.
- The cost of building the shape is measured and recorded.

## Where to look

- `joharness.sh:perf_count` — the shim, the pinned `PERF_EDGES`, and the
  127 case that already refuses to call an absent entrypoint a zero.
- `joharness.sh:perf_rows` — the budget literals and the reasoning block
  above them, including why `handover-guard` pins its mode.
- `joharness.sh:perf_report` — the table, and the `only` filter the selftest
  uses to measure one row at a time.
- `.agents/harness/queue-context.sh` — the claims loop, one `git merge-base`
  and one `git ls-tree` per unmerged ref.
- `.agents/harness/selftest/perf.sh` — the topic, which measures one row per
  case on purpose because measuring every row costs ~5s.

## Traps

- **A fallback that measures the live repo silently is worse than a failure.**
  If the shape cannot be built, say so and exit non-zero.
- **A shape with no unmerged branch measures the cheap path only.** The
  budget would then pass a regression in the loop that actually costs.
- **`--local` is ignored for a shallow source repo**, and this container's
  checkout is shallow. The clone still works; do not add a `--local` that
  quietly does nothing and call it an optimisation.
- **The selftest measures one row per case.** Building the shape per row
  multiplies its cost; build once and reuse within an invocation.
