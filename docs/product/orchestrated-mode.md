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
