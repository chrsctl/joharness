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

- (to be filled as the work decides them)

## Rejected

- (to be filled)

## Review

Pending.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — the early return on `next`.
- `joharness.sh:drain_goals` — counts open requirements, non-zero on an
  unreadable ref.
- `.agents/harness/queue-context.sh` — the second reader, which must agree.
