---
workstream: goal-reached-outranks-a-recorded-plan
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: goal-reached-outranks-a-recorded-plan
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Move the goal check ahead of the free-plan branch in cmd_drain, then say the same in the queue hook
---

## Goal

A plan recorded with no goal open must not restart the fleet, or recording
becomes a way to manufacture a goal. Nothing implements that half of the
bullet: `cmd_drain` returns on the first free plan and the goal check sits
after that early return, so a recorded note is handed out and is the only
thing keeping an unattended fleet alive.

Plan tier is sonnet; this session is opus, which the protocol allows as an
escalation.

## Decisions

- **The goal is checked before the queue, and counted once.** In `cmd_drain`
  the check moves above the free-plan branch and its result is reused by the
  block below, which used to call `drain_goals` a second time. Two calls are
  two answers to one question and a reader trusts the second.
- **One printer for the stop.** `drain_goal_reached` is called from one place
  now, but the wording is load-bearing — a session acts on WHICH stop fired —
  and the message grew a paragraph that only makes sense when the queue is
  not empty. A function keeps the two facts in one place.
- **The hook gets the same check, at both of its terminal paths.** `drain`
  reads the hook, so a hook that still ordered a fleet would make the two
  readers disagree about one tree.
- **Recorded plans stay LISTED, in both modes.** What stops is the ORDERING:
  the fan-out order and the tail that points a session at the top free plan.
  A stop that hid the note would report an empty queue over a queue that is
  not, which is the same defect from the other side.
- **The hook's no-plans edge arm is narrowed, not deleted.** Probed
  2026-09-02: with no plans, a requirement is always unserved, so `unplanned`
  is non-empty and that branch takes it; with no requirement the new check
  stops first. The arm is unreachable today and is still the correct answer
  for the state it names, so it stays with the probe recorded beside it.
- **The fixtures that broke were asserting the pre-bound rule.** Sixteen
  cases carried no requirement at all and expected the generate-work edge.
  That is exactly the state PR 170 corrected `drain`'s cases out of when the
  goal bound landed; the hook was never brought under it. Re-aimed: the
  no-plans-no-goal state now asserts the stop, and the edge assertions moved
  to the path where a goal is open and nothing is free.

## Rejected

- **Hiding or de-ranking the recorded plan.** Recording is always allowed and
  the note is for a human. Taking it out of the listing to keep the fleet
  from seeing it trades one silent failure for another.
- **Fixing `drain` alone.** It reads the queue hook's output; leaving the
  hook ordering a fan-out while `drain` says stop is the two-readers drift
  this command's own comment forbids.
- **Deleting the unreachable edge arm.** It is right for the state it names,
  and a later change to where the goal check sits would want it back.

## Review

Pending.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — the early return on `next`.
- `joharness.sh:drain_goals` — counts open requirements, non-zero on an
  unreadable ref.
- `.agents/harness/queue-context.sh` — the second reader, which must agree.
