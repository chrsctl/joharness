---
plan: unsupervised-endurance
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
advances: Started once, the fleet keeps going for hours with no human turn
scope: docs/product, joharness.conf
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
spawned session check the repository instead of believing its prompt: A2 was
told to run it, ran it, got VERIFIABLE and proceeded, and wrote that fact
into its workstream file unprompted. The mechanism worked; what was
unprompted was the recording, not the check. PR 187 stops the queue offering
an unattended fleet a plan whose whole scope is protocol text, which is what
attempt two spent 55 minutes and $12.05 on.

**The first row's wall has not been touched, and it is not this plan's to
fix.**
`.agents/docs/unsupervised.md` is explicit: fan-out makes the fleet WIDE and
nothing in it makes the fleet LONG. Each session claims, merges, ends; the
fleet survives only while every generation spawns the next, and one
generation that fails to spawn ends the run silently. The clock outside the
chain is the heartbeat Routine, and that file says in as many words that it
does not create one — it is an operator action with money attached.

So a fourth attempt run the way the first three were run measures the same
thing again: how long one generation lasts. That is the finding this plan
starts from rather than the one it should end with.

**And the stop it can reach is the sweep, not the goal.** Say this to the
human plainly, because the shape of the spend depends on it: the bullet this
run measures is itself one of the requirement's two open bullets, so "goal
reached" cannot fire while the run is in progress. Under the bound the fleet
runs while a goal is open, and this goal stays open by construction until the
run ends. The reachable stop is therefore a dry sweep — and the sweep is not
dry today.

## BEFORE YOU START — what the human decides

Both gates are money, which `.agents/harness/AGENTS.md` says to stop and ask
about. Neither is a session's call, and this plan must not invent either:

1. **Whether to spawn at all, and against what bound.** Issue #165 was
   answered with "the goal bounds it, so the cost is the remaining work
   against `unsupervised-mode`". That answer does not hold for THIS run, and
   the paragraph above says why: the goal cannot be reached while the run is
   what would reach it. What actually bounds the spend is the dry sweep, and
   a sweep goes dry only after the fleet has cleared every source it can
   count. Put that to the human, with `./joharness.sh sources` output beside
   it, rather than the goal-bound estimate. A cap is still the human's to
   add; it is a better idea for this run than it was for the last one.
2. **Whether a heartbeat exists for this run.** Without one, report the
   result as one generation and say so — do not quietly re-run the same
   experiment and call the number endurance. With one, the run is the first
   that could show what the bullet asks.

## The queue this run would start from, and the trap in it

**A fleet started today claims THIS PLAN first.** Checked rather than
assumed — `JOHARNESS_MODE=unsupervised ./joharness.sh drain` on a clone
standing where this branch's merge would put `main` answers
`next: docs/plans/unsupervised-endurance.md` (2026-09-02). One free plan is
not the generate-work edge; the edge is reached only when nothing is free.
So the first spawned session claims the plan that says spawning is the
human's call, reads `BEFORE YOU START`, and stops to ask — which this plan's
own Scope calls a finding. That is the fourth wall, and it is in this file.

**So the session driving the run claims this plan itself**, by pushing a
workstream file naming it, before any session is spawned. The queue then
shows it claimed, the fleet cannot take it, and what the fleet meets is the
queue behind it.

What is behind it decides what else the run measures. With nothing free, the
fleet reaches the **generate-work edge** on its first turn, and that is worth
having: bullet three of `Satisfied when` — an unsupervised session that finds
the queue empty writes plans rather than stopping — was measured once, in
PR 163, and its own annotation records three caveats: the session measuring
the bullet was the session that knew it, one cycle only, and the flip used
the session-local marker rather than `joharness.conf`. A fleet started from a
committed mode, generating work it was not told about, answers all three.

Run `./joharness.sh sources` first and record it. A dry sweep is one of the
two legitimate stops, and the run cannot be read without knowing whether it
started dry.

## Scope

- A fleet started once, left alone, and measured until it stops on its own.
- What stopped it, **in its own words**. There are exactly two legitimate
  stops and they must not be blurred: the **goal reached** (no open
  requirement) and the **dry sweep**. Anything else — a rate limit, an
  error, a session asking a question it should not have asked, a generation
  that failed to spawn — is a finding, and a finding is the result.
- Wall-clock, session count, generations, pull requests merged, reconciles,
  and cost. The fan-out annotation in the requirement is the format to match
  — the table at the top of this file records only what stopped each run.
- **The goal's size at T0, beside the wall-clock.** A fleet that stops in ten
  minutes because the goal was nearly reached has not failed the bullet, and
  a number without the queue depth beside it reads as endurance when it is
  really queue depth. This is the confound the requirement already records
  twice against attempt two.
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
  attempts did this and recorded doing it; neither was required to by an
  Acceptance, because attempt two ran on a direct human instruction with no
  plan file at all. It is a precedent, not an inherited rule, and it is
  written here so the next run has one.
- A fleet that kept going because a human answered something is not a fleet
  that kept going. Any human turn during the run ends the measurement at
  that point, and the number is reported up to it.

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
  why 48 seconds was reported as an injection refusal until the retry, the
  same day, corrected it.
- **A number nobody can re-count is a written number.** Carry the command
  and the date in the same sentence as the figure.
- **57 minutes is not hours.** If the run is short, the bullet stays
  unsatisfied — say so plainly rather than annotating a partial result as
  though it settled the question.
