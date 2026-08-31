---
workstream: goal-lifecycle
status: review
branch: claude/goal-lifecycle
pr: none
plan: docs/plans/unsupervised-goal-lifecycle.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Under the goal bound (PR 169) unsupervised is live only while a requirement
is open. `drain` deferred to the source sweep regardless, so with every goal
satisfied the fleet would keep generating work against nothing — the failure
the bound exists to prevent.

## Decisions

- **The goal is checked FIRST**, before the sweep: it is the cheaper stop and
  the more final one, and running a minute of `ci` to decide something a
  `ls-tree` answers is the wrong order.
- **Its own message, never the sweep's.** A dry sweep means the sources are
  exhausted; a reached goal means the work is finished. A session acts on
  which fired, and a human reading the report decides whether to set a new
  goal. The plan named this as a Trap and it is asserted both ways.
- **`drain_goals` returns 1 when the ref is unreadable**, and that defers to
  the sweep rather than winding down. ABSENT IS NOT ZERO — the same rule the
  queue part of the stop condition learned, and the unmarked detector learned
  from the other side.
- **Same definition of a requirement as the queue hook** — tracked `.md`
  under `docs/product/` minus TEMPLATE, README and VISION, read from the REF.
  A repo keeping a requirement TEMPLATE around would otherwise never reach
  its goal, and the bound would be unreachable rather than bounding.

## Rejected

- **Adding the goal as a fifth part of `sources`' stop condition**, which
  this plan's own Scope proposed. It is wrong: the goal-reached stop and the
  dry-sweep stop are ALTERNATIVES, not conjuncts, and making the goal a
  conjunct would have meant a dry sweep could not stop a fleet while a goal
  was open — the opposite of the requirement, which says both stop it. It
  would also have conflated two questions in a command whose banner says it
  counts sources. Recorded because the plan says otherwise and a later reader
  will notice.

## Review

Round 1, opus, self, with `mutate`.

- r1: **the plan's Scope was wrong** and research caught it before code. See
  Rejected. (fixed — implemented in `drain` alone)
- r2: the two existing unsupervised cases FAILED, correctly. They asserted
  "an empty queue is a trigger" with no requirement in the fixture at all,
  which was the pre-bound rule; under the bound that state is the
  goal-reached stop. (fixed — the fixture now has a goal for the trigger case
  and the no-goal state is its own case)
- r3: giving the fixture a requirement made the queue NON-empty, because an
  unplanned requirement is queue work and outranks plans (PR 157). So the
  unsupervised branch was never reached and three cases failed on a `next:`
  line. The state these cases need is a goal that is already PLANNED with its
  plan claimed. (fixed — requirement, plan serving it, and a claiming branch)
- r4: **the fixture trap twice, by two different routes.** Deleting the last
  plan removed `docs/plans/`; switching back from the claim branch removed
  `docs/handover/`, because git drops a directory when its last tracked file
  goes. Every later `cat >` then failed silently and two unrelated cases
  broke. `write_ws` documents this for writes; it bit here through a DELETE
  and through a BRANCH SWITCH. (fixed — `mkdir -p` at both points, with the
  reason)
- r5: my first goal-reached message split "NOT a dry sweep" across two
  printf lines, so the assertion for it could never match. A wrapped message
  and a needle written from the source read identically until one is run.
  (fixed — reflowed so the phrase is on one line)
- r6: verifier round owed and NOT run — standing instruction, twenty-fourth
  consecutive edge. (wontfix on this branch — this session cannot spawn
  subagents; issue #168 asks for the instruction to be lifted or confirmed)

## Verification

- `mutate joharness.sh 4392` (never stop on a reached goal) → reds **5**
- `mutate joharness.sh 4391` (unreadable ref read as zero goals) → reds **2**
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1113 passed, 0 failed**
  (up 7)
- Supervised `drain` output unchanged — the goal check lives inside the
  unsupervised branch, which is a `Satisfied when` bullet of its own.

## Blockers

None.
