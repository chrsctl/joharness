---
plan: unsupervised-edge-generates-work
urgency: normal
agent: opus
effort: high
needs: unsupervised-stop-condition, unsupervised-finding-dedupe
requirement: unsupervised-mode
scope: docs/product
---

## Goal

Measure the one `Satisfied when` bullet nothing has tested:

> An unsupervised session that finds the queue empty writes new plan files
> and opens a pull request for them, rather than stopping to ask.

The RULE exists — `.agents/harness/AGENTS.md` step 2 carries the exception,
gated on the mode. What no run has shown is a session actually doing it. The
fan-out live run of 2026-08-30 is annotated in the requirement as not
showing this: both sessions were bounded to one named plan each and stopped
when that work ran out, and the repo mode was never flipped.

## BEFORE YOU START — two things that are not yours to decide

1. **Flipping `joharness.conf` to unsupervised is repo-wide.** Every session
   in this repo reads that file, including any running concurrently. A
   session cannot flip it for a measurement on its own judgment. Get the
   human's word, and say in the pull request when it was given.
2. **This bullet is contested text.** `origin/claude/unsupervised-goal`
   holds unmerged work replacing "an empty queue is a trigger for work, not
   a stopping point" with a goal bound — unsupervised live only while a
   requirement is open. That branch is unmerged and this wording is live, so
   this plan is written against the live text. If the amendment lands first,
   re-read this Goal before running anything: the behaviour it measures is
   the behaviour the amendment narrows.

## Scope

- One session, unsupervised, against a genuinely empty queue. Not simulated:
  the bullet is about what a session does, so a fixture cannot answer it.
- Record what it generated, whether the plans it wrote pass `graph lint`,
  and whether they were work or filler. A session that writes four plans
  nobody would take has satisfied the bullet's letter and failed its point.
- Annotate the requirement bullet with the result, the same way the fan-out
  run's partial result is annotated — including what the run did NOT show.

## Out of scope

- Endurance. That is `unsupervised-endurance`, and running both at once
  makes neither answerable.
- Merging what the session generates without reading it. Step 7 conditions
  are unchanged by the mode; the mode removes the human, never the gate.
- Adding a cap on how much work it may generate. Explicitly declined by the
  requester 2026-08-24 — "no cap on work per run" — and a decomposing
  session must not add it back on its own judgment. Propose it if the run
  argues for one.

## Acceptance

- The requirement's bullet carries a measured result with the date, the
  session, and what was NOT shown.
- Every plan the session generated is named, with a verdict: took it, or why
  not.
- `./joharness.sh ci` — pass, and `joharness.conf` is back to supervised
  unless the human said otherwise.

## Where to look

- `docs/product/unsupervised-mode.md` — the bullet, and the fan-out
  annotation for the shape a result should take.
- `.agents/harness/AGENTS.md` step 2 — the exception, and its boundary.
- `joharness.sh:cmd_drain` — the unsupervised branch a session hits at the
  edge.

## Traps

- The queue must be genuinely empty, INCLUDING unplanned requirements. PR
  157 fixed `drain` reporting DRAINED over one; a run started against a
  queue that only looked empty measures nothing.
- Leaving the repo unsupervised after the run is a live change to how every
  later session behaves.
