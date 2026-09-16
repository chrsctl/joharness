---
requirement: orchestrated-mode
priority: normal
---

## Goal

Requester, 2026-09-05, transcribed by the attended session that received
the ask. A session writes no requirement of its own; this file carries the
human's words, and when the session asked whether to correct, keep or
delete it the requester answered by delegating the decision to the
session ("Research and answer the 3 questions", same day). It stands as
the goal, on that delegation. The ask: add a new unsupervised
(beta) fully orchestrated mode. An orchestrator on a low-tier model, with
maximum parallelism, pulls from the queue as the controller and spawns one
manager per item in a new session; it checks health regularly and, when a
loop is stuck, can kill it — but first has the progress summarised into the
handover for the next one. Managers (project manager, researcher, whatever
the item needs) run on a higher tier set by the plan, work one plan or
research file that can be decomposed, spawn lower-tier models for the
decomposed pieces, and are in charge of that item until the plan retires.
Ultimate goal: empty the task queue efficiently under a maximum
concurrency.

## Satisfied when

- `JOHARNESS_MODE=orchestrated` exists, reads as unattended in every bound
  unsupervised has, and a session can tell its role from session-start
  output plus its own prompt alone.
- `./joharness.sh dispatch` answers the orchestrator's question in one
  read: the cap, managers in flight with push age, the spawn order, and one
  verdict — with a plan overlapping work in flight held back.
- A stuck manager is found from two signals, nudged, killed only after its
  handover is on the branch, and a successor resumes that branch.
- Started once with a stocked queue, an orchestrated run merges every free
  plan the queue held at start with no human turn, under the cap, and the
  run's numbers are counted, not written: wall-clock, managers spawned,
  kills, respawns, reconciles, pull requests merged, cost.

  **Not satisfied. Two runs counted, and the second is not over.**
  Run 1, 2026-09-06, consumer `chrsctl/gx`, cap 4: 5h37m, 10 managers, 0
  kills, 2 respawns, 8 merged, at least 437 USD. Row and workings in
  [`.agents/docs/orchestrated.md`](../../.agents/docs/orchestrated.md), Runs;
  what it did and did not move against the peer fleet in
  [`.agents/docs/product/README.md`](../../.agents/docs/product/README.md).
  Three clauses of this bullet it does not meet:

  - **No human turn.** It ended ON one, 17:42Z, which this requirement's own
    plan makes the end of the measurement.
  - **Every free plan the queue held at start.** 8 merged; 30 still waiting
    behind one branch in flight at the end.
  - **Counted, not written.** `reconciles` is counted nowhere — no column in
    the Runs table, no figure in the workings.

  `under the cap` it did meet, and says nothing about: from roughly 13:00Z
  the fleet was overlap-bound rather than slot-bound, 2 to 3 slots idle while
  every free plan collided with a claimed one on a registry path, so the cap
  of 4 was never the binding constraint.

  What run 1 did NOT show, owed by a later run: no heartbeat, so nothing
  about a fleet outliving one orchestrator; no kill and no nudge fired, so
  the third bullet's paths stay unmeasured; one consumer, one queue shape,
  whose overlap density does most of the work in the throughput number.

  Run 3, started in `chrsctl/gx` on 2026-09-11, is counted to its freeze in
  the same Runs table: 42h20m, 59 managers, 41 merged, at least 5252.42 USD,
  then 82h40m frozen because the orchestrator's self-armed pass chain was the
  only thing driving the fleet. It misses this bullet on every clause run 1
  missed and adds one: it has not ended, so nothing says what stopped it. The
  two defects run 1 exposed were filed as plans and both merged the same day
  (`e1ec240`, `8e637aa`): the second and third bullets' machinery repaired,
  not this bullet satisfied.

## Constraints

- Every bound in `.agents/docs/unsupervised.md` holds unchanged: protocol
  text off limits unattended, step 7 conditions for every merge, no
  requirement written by a session, nothing invented at the edge.
- The numbers — cap, stall window, health cadence, respawn limit — are the
  human's. A session proposes a change with evidence and never sets one on
  its own judgment.
- No state store, no status field: every view derives from git and the
  control plane at read time.
- Two spawn levels only: orchestrator to manager session, manager to
  worker subagent.
