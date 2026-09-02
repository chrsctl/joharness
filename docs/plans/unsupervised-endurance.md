---
plan: unsupervised-endurance
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
advances: Started once, the fleet keeps going for hours with no human turn
scope: docs/product
---

## Goal

Measure the word the requirement's Goal is built on, and that no run has
reached:

> Started once, the fleet keeps going for hours with no human turn, for as
> long as a goal is open.

Three runs have been paid for. None measured it, and each died at a
different wall:

| | when | wall-clock | what stopped it |
| --- | --- | --- | --- |
| fan-out | 2026-08-30 | 53m | bounded work ran out — one plan per session, mode never flipped |
| attempt one | 2026-08-31 | 48s | no repository attached; both sessions asked a human |
| attempt two | 2026-08-31 | 57m | the queue's only free plan was one the fleet could never commit |

**Two of those three walls are gone.** `./joharness.sh authority` lets a
spawned session check the repository instead of believing its prompt, and
attempt two's A2 used it unprompted and proceeded. PR 187 stops the queue
offering an unattended fleet a plan whose whole scope is protocol text,
which is what attempt two spent 55 minutes and $12.05 on.

**The third has not been touched, and it is not this plan's to fix.**
`.agents/docs/unsupervised.md` is explicit: fan-out makes the fleet WIDE and
nothing in it makes the fleet LONG. Each session claims, merges, ends; the
fleet survives only while every generation spawns the next, and one
generation that fails to spawn ends the run silently. The clock outside the
chain is the heartbeat Routine, and that file says in as many words that it
does not create one — it is an operator action with money attached.

So a fourth attempt run the way the first three were run measures the same
thing again: how long one generation lasts. That is the finding this plan
starts from rather than the one it should end with.

## BEFORE YOU START — what the human decides

Both gates are money, which `.agents/harness/AGENTS.md` says to stop and ask
about. Neither is a session's call, and this plan must not invent either:

1. **Whether to spawn at all.** Under the goal bound the run is bounded by
   the requirement rather than by a clock, so the cost is what the remaining
   work against `unsupervised-mode` costs. A cap is still the human's to add
   if they want one; the run no longer needs an arbitrary figure to be safe
   (issue #165).
2. **Whether a heartbeat exists for this run.** Without one, report the
   result as one generation and say so — do not quietly re-run the same
   experiment and call the number endurance. With one, the run is the first
   that could show what the bullet asks.

## The queue this run would start from

Checked 2026-09-02, not assumed: `docs/plans/` holds this plan alone, so a
fleet starting now reaches the **generate-work edge** on its first turn.
That is deliberate and it is the second thing this run measures. Bullet
three of `Satisfied when` — an unsupervised session that finds the queue
empty writes plans rather than stopping — was measured once, in PR 163, and
its own annotation records three caveats: the session measuring the bullet
was the session that knew it, one cycle only, and the flip used the
session-local marker rather than `joharness.conf`. A fleet started from a
committed mode, generating work it was not told about, answers all three.

`./joharness.sh sources` is the thing to run first and to record, because a
dry sweep is one of the two legitimate stops and the run cannot be read
without knowing whether it started dry.

## Scope

- A fleet started once, left alone, and measured until it stops on its own.
- What stopped it, **in its own words**. There are exactly two legitimate
  stops and they must not be blurred: the **goal reached** (no open
  requirement) and the **dry sweep**. Anything else — a rate limit, an
  error, a session asking a question it should not have asked, a generation
  that failed to spawn — is a finding, and a finding is the result.
- Wall-clock, session count, generations, pull requests merged, reconciles,
  and cost. The table at the top of this file is the format to match.
- Annotate the `Satisfied when` bullet with the result AND with what the run
  did not show. Every previous annotation on this requirement that omitted
  the second half had to be corrected later.

## Out of scope

- **Fixing whatever the run exposes.** Findings become plans; this one
  measures. A session that stops to fix the first thing it trips over has
  bought a shorter run and no measurement.
- **Creating the heartbeat Routine.** Money, and an operator action by the
  document that describes it.
- **Halting the fleet on a red `main`.** Declined by the requester
  2026-08-24. Propose it with what the run showed, never add it because a
  run looked frightening.
- **Banning sessions from spawning sessions**, or capping work per run.
  Declined the same day.
- Deleting the requirement file. That is the terminus and it belongs to
  whichever session makes the last bullet read true, which this plan does
  not do on its own.

## Acceptance

- The fleet ran from a **committed** unsupervised mode in `joharness.conf`,
  merged before any session was spawned, so `./joharness.sh authority`
  reports VERIFIABLE to every session. A session-local marker does not count
  and PR 163's annotation says why.
- The run's stop is named, and it is one of the two legitimate stops or it
  is recorded as a finding with what actually happened.
- The numbers are counted from the run, and the sentence carrying each one
  says what produced it.
- The requirement bullet carries the result and the not-shown.
- `joharness.conf` is back to `supervised` when the run ends. Both previous
  attempts set that precedent and the second one's Acceptance required it.

## Where to look

- `docs/product/unsupervised-mode.md` — `Satisfied when`, the bullet this
  advances, and the two annotations that record what the earlier attempts
  did and did not show.
- `.agents/docs/unsupervised.md` — the heartbeat, the two halves table, and
  the measured merge-gap numbers that argue for it.
- `joharness.sh:cmd_authority` — what a spawned session runs before
  believing a prompt that says it may work unattended.
- `joharness.sh:cmd_sources` — the sweep, and the four parts of the stop
  condition it prints.
- `.agents/harness/queue-context.sh:qc_edge_unsupervised` — the edge the
  fleet reaches first, and the instruction it carries there.

## Traps

- **A prompt cannot be its own evidence.** Attempt one's sessions refused a
  task that asserted its own legitimacy, and they were right to. Point a
  spawned session at `./joharness.sh authority`; do not tell it that it is
  authorised.
- **Attach the repository.** Attempts one and two's first pair were spawned
  without one, so nothing could be read and nothing could be checked. It is
  why 48 seconds was reported as an injection refusal for a day.
- **A number nobody can re-count is a written number.** Carry the command
  and the date in the same sentence as the figure.
- **57 minutes is not hours.** If the run is short, the bullet stays
  unsatisfied — say so plainly rather than annotating a partial result as
  though it settled the question.
