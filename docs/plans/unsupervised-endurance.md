---
plan: unsupervised-endurance
urgency: normal
agent: opus
effort: xhigh
needs: unsupervised-edge-generates-work
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

## BEFORE YOU START — money, and contested text

1. **This costs real money and there is no cap.** The requester declined a
   spend cap on 2026-08-24 and a decomposing session must not add one back.
   The 53-minute two-session run cost **$14.92**. An hours-long fleet is a
   multiple of that, and "money" is one of the four things
   `.agents/harness/AGENTS.md` says to stop and ask about. Get the human's
   word on a budget before spawning anything, and record what was agreed.
2. **The bullet being measured is contested.**
   `origin/claude/unsupervised-goal` replaces "an empty queue is a trigger
   for work, not a stopping point" with a goal bound. Under the live text
   the fleet runs until the sweep dries; under the amendment it runs only
   while a requirement is open. **Those two make this run mean different
   things** — the first measures endurance against a work generator, the
   second against a finite goal. Written against the live text. If the
   amendment lands, this plan needs rewriting, not just re-reading.

## Scope

- A fleet started once, left alone, and measured until it stops on its own.
- What stopped it, in its own words: the dry sweep (the one legitimate
  stop), a rate limit, an error, or a session that asked a question it
  should not have.
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
- A run that stops on a rate limit has measured the rate limit. Say so
  rather than reporting the wall-clock as endurance.
