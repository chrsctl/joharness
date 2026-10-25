---
plan: queue-block-repair
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 626
scope: shared:joharness.sh, shared:.agents/harness/queue-context.sh, shared:.claude/commands/retro.md, shared:.agents/docs/graph.md, shared:.agents/docs/plans/README.md, shared:.agents/docs/plans/TEMPLATE.md, shared:.agents/harness/selftest/retro.sh, shared:.agents/harness/selftest/ci-graph-lint.sh, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

Issue #626, from consumer chrsctl/gx. Three plans gated on a requirement
that had no plan (`docs/product/projects-layer.md`). A plan's `needs:`
names plans only (`needs: <requirement>` is lint `DEAD`), so each gate was
written in prose. Dispatch cannot read prose and spawned two managers into
a certain block; the third was in `wave 1`. Retro, the role that traces a
failure to its missing check, would have sampled the blocked sessions only
on its 168h clock, and it has no route to repair the queue. The requester
asked that the protocol catch this and fix itself, with retro in that
position.

## Scope

- `.agents/harness/queue-context.sh`: a plan's `needs:` naming an open
  requirement stem (`docs/product/<stem>.md` on the base) blocks the plan
  while that file exists. Label: `blocked by: <stem> (open requirement)`.
- `joharness.sh` lint (`needs` loop): accept a stem that is, or was, a
  requirement. Warn (not red) when the named requirement has an open plan
  serving it, saying to name that plan instead; the requirement edge is for
  a requirement nobody has planned yet.
- `joharness.sh` `retro_due`: a retro is DUE regardless of the clock when
  a candidate session (blocked, not in the ledger) has a `next:` naming an
  open plan or requirement stem on the base other than its own `plan:`.
  Such a block is the queue's to resolve, not a human's. `cmd_retro` names
  the session and the stem. `JOHARNESS_RETRO_HOURS=0` still turns it off.
- `.claude/commands/retro.md`: a `repair: <stem>` route, before
  `mechanism`. When the block is a dependency the queue could hold but
  does not, the reviewer adds the `needs:` edge to the gated open plans,
  editing only their `needs:` line, and that is the one change to an
  existing plan it may make. If the needed item has no plan, the
  requirement stem is the edge (dispatch offers the requirement for
  planning). It still files the mechanism plan when a check should have
  stopped the gate being written in prose.
- `.agents/docs/graph.md` edge table, `.agents/docs/plans/README.md`
  (Dependencies) and `TEMPLATE.md`'s `needs:` comment: the new edge.
- Selftests: `ci-graph-lint.sh` (accept, warn), `dispatch.sh` or the
  queue-context suite (blocked by an open requirement; unblocked once it
  is deleted), `retro.sh` (due off-clock on a queue block; not on a block
  naming no open stem; not when HOURS=0).

## Assumptions

- A1: `queue-context.sh` already lists requirement files as `$reqs`
  before the plan rows are built. Evidence: `queue-context.sh:67`.
  Confidence: high.
- A2: dispatch reads blockers from queue-context's label (`, blocked by:`),
  so a new blocker kind reaches dispatch with no change there. Evidence:
  `joharness.sh` near `case "$dlabel" in *', blocked by:'*`. Confidence:
  medium; measured by the dispatch selftest.

## Out of scope

- Releasing a claim parked as `blocked` once an edge holds its plan.
  Today `halt` is a human's order. Making it automatic changes who may
  write another session's branch: a follow-up named on #626.
- Partly-served requirements (a plan naming `requirement:` for one clause
  silences `unplanned`): a follow-up named on #626.

## Acceptance

- `./joharness.sh ci`: `ci: pass`. Red is any other final line.
- `./joharness.sh verify`: `0 failed`, the new assertions counted among
  the passes. Red is a non-zero failed count.
- Each new assertion fails with its mechanism reverted (checked once by
  hand, said in the PR).

## Where to look

- `.agents/harness/queue-context.sh`: the `blockers` loop in `rows_raw`;
  `qc_need_stems`.
- `joharness.sh`: `lint_existed`, the `needs` loop near the `no such plan,
  never existed` message; `retro_candidates`, `retro_due`, `cmd_retro`.
- `.agents/harness/selftest/retro.sh`: the `rt_ws` fixture (its `next:`
  is `x`).

## Traps

- A `next:` line is a session's text: match only stems that exist as open
  files on the base, never act on its words.
- Never let the off switch (`JOHARNESS_RETRO_HOURS=0`) be bypassed by the
  new trigger.
- An unreadable read is not an empty one: fail closed, as `retro_due` does.
