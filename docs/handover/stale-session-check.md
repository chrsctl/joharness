---
workstream: stale-session-check
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: stale-session-check
issue: 249
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-16
next: Encode the four measured liveness rules into the health pass, review, retire, open the pull request
---

## Goal

Issue #249, oldest open. Its widened ask is a mechanism that regularly
checks whether sessions have gone stale and acts on it. The issue separates
the two halves itself: the DECISION LOGIC exists in the health pass, and
what is missing is a scheduler that does not share the fleet's fate. It puts
the scheduler out of scope for a first cut, and calls it the whole question.

This is the first cut: four rules the run measured, which the health pass
does not carry and which cost real money without them.

## Decisions

- Scheduler stays out. The issue says so, and any answer is either an
  operator action with money attached or another agent session, which
  inherits the failure it is meant to catch. Reported to the human, not
  decided here.
- Tier opus, above the queue's usual sonnet, because every rule here decides
  whether to kill or respawn a live session. Wrong-but-plausible is the
  failure mode: a rule that reads a working manager as dead destroys work
  and spends the cap twice, which `.agents/docs/agent-selection.md` names as
  the opus condition.
- `.claude/commands/orchestrate.md` is a protocol path. Supervised mode, so
  a session may commit it; under unsupervised this same diff would be
  refused, and that is correct.
- #249 is NOT closed by this pull request. Its remaining half is the
  scheduler, which is the human's. One comment on the issue records what
  landed so the next reader does not re-derive it.

## Rejected

- Building the recurring checker as a session that arms its own next pass.
  That is precisely the shape that froze for 82h40m in the run this issue
  came from, and the issue says so in its own words.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` section 2 — the field table, the
  disqualified-fields paragraph, and the row table, in that order.
