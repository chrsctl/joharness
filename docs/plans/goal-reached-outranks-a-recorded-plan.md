---
plan: goal-reached-outranks-a-recorded-plan
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
advances: recorded with no goal open names neither, because there is nothing to name
scope: joharness.sh, .agents/harness/queue-context.sh, .agents/harness/selftest
---

## Goal

The requirement says a plan recorded with no goal open

> does NOT restart the fleet. Otherwise recording would be a way to
> manufacture a goal, which is the circularity the bound closes.

Nothing implements that. `cmd_drain` returns on the FIRST free plan, and the
goal check sits after that early return, so it is reached only when the queue
is already empty. A recorded note is a free plan.

Reproduced 2026-09-02 on a scratch clone — no files under `docs/product/`,
one plan carrying `requirement: none`:

```
$ JOHARNESS_MODE=unsupervised ./joharness.sh drain
== drain (mode: unsupervised)

NOT DRAINED
  next: docs/plans/recorded-note.md [normal, agent: sonnet, effort: low, ...]
```

Delete that one plan from the same tree and it prints `GOAL REACHED`. So the
recorded note is the only thing keeping the fleet alive, which is the exact
circularity the bullet forbids. Found by the verifier round on the
decomposition that filed this plan; `grep -rn "restart the fleet"` returns
the requirement's own line and nothing else.

## Why this is not the goal-lifecycle work already done

PR 170 made the goal a stop: with the queue empty and no requirement open,
`drain` says GOAL REACHED instead of deferring to the sweep. That is the
right behaviour for an EMPTY queue and it is tested. This is the other
order — queue not empty, goal gone — and it was never asked.

## Scope

- `cmd_drain` checks the goal BEFORE handing out a free plan when the mode is
  unsupervised: no open requirement means GOAL REACHED, whatever the queue
  holds.
- The queue hook says the same at the same moment, since a session re-reads
  one or the other and the two must not disagree.
- Recorded plans stay LISTED. They are a note for a human and deleting or
  hiding them is the failure this must not trade for.

## Out of scope

- Supervised behaviour. A supervised session with no open requirement takes
  the next plan exactly as it does today, and the requirement's own
  byte-identity line covers this.
- Blocking a session that has been told to work a specific plan. This
  changes what the QUEUE OFFERS an unattended fleet, not what a directed
  session may do.
- Deleting the requirement file, or judging whether its bullets read true.
  That is the terminus and it is a different bullet.
- Distinguishing a plan that was RECORDED from one that was GENERATED. No
  static check can: the difference is the session's state, not the file's
  content, and `lint_plan_advances` already carries that reasoning.

## Acceptance

- Unsupervised, no requirement open, one free plan: `drain` says
  GOAL REACHED and hands out nothing.
- The same tree under supervised is unchanged, byte for byte.
- Unsupervised with a requirement open: the free plan is handed out as it is
  today.
- The recorded plan is still listed in the queue hook's table in both modes.
- Cases for each, and `./joharness.sh mutate` reds them.

## Where to look

- `joharness.sh:cmd_drain` — the early return on `next`, and the goal check
  below it that never sees a non-empty queue.
- `joharness.sh:drain_goals` — counts open requirements from the ref, and
  returns non-zero rather than zero when the ref cannot be read.
- `.agents/harness/queue-context.sh:qc_edge_unsupervised` — what the hook
  says at the edge today.
- `.agents/harness/selftest/drain.sh` — the GOAL REACHED cases PR 170 wrote,
  which are the shape these follow.

## Traps

- **Absent is not zero.** `drain_goals` returns non-zero when the base ref
  cannot be read, and that must keep deferring rather than winding a fleet
  down over a question nobody answered. Do not turn an unreadable ref into
  "no goal".
- **A recorded plan is not a defect.** Recording is always allowed, in any
  mode, goal or no goal. This changes what the fleet is OFFERED, and nothing
  about what a session may write.
- **The two readers must agree.** `drain` reads the queue hook's output; a
  second answer computed here is the drift the command's own comment forbids.
