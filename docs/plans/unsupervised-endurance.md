---
plan: unsupervised-endurance
urgency: normal
agent: opus
effort: xhigh
needs: unsupervised-goal-lifecycle, unsupervised-plan-provenance
requirement: unsupervised-mode
scope: docs/product
---

## Goal

Measure the word the requirement's Goal is built on, and that no run has
reached:

> Started once, the fleet keeps going for hours with no human turn.

The fan-out live run of 2026-08-30 is already annotated in the requirement
as not showing this: **53 minutes**, ended because bounded work ran out, not
because anything was exhausted. 53 minutes is not hours, and a fleet that
stops when its handed work runs out has not been asked the question.

## BEFORE YOU START — rewritten 2026-08-31, and the budget question changed

The goal bound landed (PR 169, issue #166). This plan was written against the
live text at the time — "an empty queue is a trigger for work, not a stopping
point" — and its own note said that if the amendment landed it would need
**rewriting, not just re-reading**. This is that rewrite.

**What changed.** The bullet is now:

> Started once, the fleet keeps going for hours with no human turn, **for as
> long as a goal is open**.

So endurance is no longer a fleet running against an open-ended work
generator. It runs toward a requirement and winds down when the last bullet
reads true. That is a different measurement, and a better one: the thing
being tested is whether the fleet sustains itself *while there is a goal*,
not whether it can be kept alive indefinitely.

**And the budget question dissolves with it.** The old blocker was that the
requester declined a spend cap and a session must not invent one — leaving no
number anybody could name. Under the bound the run is **bounded by the goal,
not by a clock**: it costs what the remaining plans against the requirement
cost, and it stops when they are done. A cap is still the human's to add if
they want one, but the run no longer needs an arbitrary figure to be safe,
which is what issue #165 was blocked on.

**Still not a session's call**: spawning sessions spends real money. The
figure is now derivable rather than arbitrary, and that is what to put to the
human — an estimate from the remaining queue, not a number pulled from air.

## Scope

- A fleet started once, left alone, and measured until it stops on its own.
- What stopped it, in its own words. There are now TWO legitimate stops and
  they must not be confused: the **goal reached** (no open requirement) and
  the **dry sweep**. Anything else — a rate limit, an error, a session asking
  a question it should not have — is a finding.
- Wall-clock, session count, pull requests merged, reconciles, and cost.
  The fan-out record is the format to match.
- Annotate the requirement bullet, including what the run did not show.

## Out of scope

- Fixing whatever the run exposes. Findings become plans; this one measures.
- Halting on a red `main`. Explicitly declined 2026-08-24 — do not add it
  because a run looked scary. Propose it with what the run showed.
- Banning sessions from spawning sessions. Also declined, same date.

## Acceptance

- A recorded run with wall-clock, what stopped it, and cost, all counted.
- The requirement's bullet annotated with the result and with what it did
  not show.
- Any finding the run produced is a filed plan or a stated non-finding.

## Where to look

- `docs/product/unsupervised-mode.md` — the bullet and the existing
  annotation, which is the template.
- `.agents/docs/unsupervised.md` — the fleet outliving its sessions, which
  is the heartbeat's job rather than `/drain`'s.
- `joharness.sh:cmd_sources` — the stop this run is waiting for, and the
  reason `unsupervised-stop-condition` comes first.

## Traps

- Do not count a fleet that kept going because a human answered something.
  "No human turn" is the measurement.
- A fleet that stops in ten minutes because the goal was nearly reached has
  not failed the bullet. Report the goal's size beside the wall-clock, or the
  number reads as endurance when it is really queue depth.
- A run that stops on a rate limit has measured the rate limit. Say so
  rather than reporting the wall-clock as endurance.
