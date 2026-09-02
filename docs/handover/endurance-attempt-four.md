---
workstream: endurance-attempt-four
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: unsupervised-endurance
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Review the annotation diff at opus depth, record findings, retire this file and the plan, then open and merge the pull request
---

## Goal

Attempt four at the requirement bullet "Started once, the fleet keeps going
for hours with no human turn" was run from this session on 2026-09-02. This
workstream carries the two things the plan's Acceptance still wanted after the
run ended: the requirement bullet annotated with the result AND with what the
run did not show, and `joharness.conf` back to `supervised`.

## Decisions

- **The run went ahead without a heartbeat, and the report says one
  generation.** The plan's gate 2 is "whether a heartbeat exists for this
  run", and its own answer for the no-heartbeat case is explicit: "report the
  result as one generation and say so — do not quietly re-run the same
  experiment and call the number endurance." The annotation does exactly
  that, and names the missing heartbeat as what ended the run.
- **The annotation records a fifth wall rather than folding it into the
  four.** Session A spent its first fourteen minutes judging the `authority`
  verdict self-referential because a Claude session authored the commit that
  set the mode. That is a distinct failure from the four in the plan's table
  and it is not answered by any mechanism in the repo, so it is written as
  open rather than as a caveat on an existing row.
- **The plan is retired by this pull request.** Its Acceptance is met — every
  bullet including the revert — even though the requirement bullet it
  advances stays unsatisfied. A done plan left on `main` is a plan the next
  fleet claims, and this one costs a paid run to claim.

## Rejected

- **Annotating the bullet as satisfied, or partly satisfied.** 60 minutes is
  the same quantity the three runs before it measured; the plan's own Trap
  says 57 minutes is not hours. Three earlier annotations on this requirement
  omitted the not-shown half and each had to be corrected later.
- **Calling either session's ending a legitimate stop.** A said "attempt four
  complete" and B said "queue clear, no pending work". An empty queue is this
  mode's trigger, not its stop, so both are findings under the plan's Scope.
- **Waiting on the `unsupervised-endurance` claim held by
  `claude/gastown-review-owjgzg`.** That session is IDLE and disconnected
  (`list_sessions`, 2026-09-02), blocked on two operator items — a heartbeat
  Routine and a cap value — and its branch is unmerged, so nothing it holds
  reaches `main`. Its blockers are answered by the run rather than by an
  operator: the run went ahead without a heartbeat and reported one
  generation, which is what the plan says to do in that case.

## Review

## Blockers

None.

## Where to look

- `docs/product/unsupervised-mode.md` — the `Satisfied when` bullet the
  annotation lands under, beside the three earlier attempts' annotations.
- `docs/plans/unsupervised-endurance.md` — the plan, retired by this pull
  request; its `BEFORE YOU START` gates and its four-wall table are what the
  annotation answers.
- `joharness.conf` — the mode, and the comment block recording why it was
  flipped and when it came back.
- `origin/claude/gastown-review-owjgzg:docs/handover/unsupervised-endurance.md`
  — the other claim on this plan, and the connector-trap evidence (its r1)
  that the annotation cites as the reason no heartbeat exists.
