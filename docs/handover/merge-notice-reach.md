---
workstream: merge-notice-reach
status: in-progress
branch: claude/merge-notice-reach-79e466
pr: none
plan: docs/plans/merge-notice-reach.md
issue: #230
session: https://claude.ai/code/session_01G751FjhA159aSUbvtRUqDW
agent: opus
updated: 2026-09-06
next: Make the two text edits, then ci, then the verifier pass
---

## Goal

Issue #230, filed from consumer `chrsctl/gx` by the manager that hit it. A
manager finished its item, tried to send `"merged replay-age"` to its
orchestrator, and was refused twice. The human who read the report asked for
the fix here rather than in the consumer, which is also where the harness says
it goes: `.claude/commands/` syncs from this repo, so the consumer's copy is
not editable on its own.

## Decisions

- Same-session plan: written on this branch, retired by this pull request. The
  ask arrived direct from a human and the queue rule is that nothing builds
  unplanned; a small ask is still a small plan.
- Address by the name `ListAgents` gives the caller in its opening line, not by
  session title. The title was refused too, but for want of a route — that
  measurement says nothing about whether a title is an address, and writing
  protocol text on an unmeasured inference is what this issue is about.
- The gate stays `ToolSearch`, with the limit stated rather than replaced. A
  reachability gate the orchestrator could actually evaluate before the spawn
  does not exist: peer visibility is a property of the container the MANAGER
  will run in, which has not been created yet. Saying "holding the tool is not
  holding a route" costs one sentence and is true; inventing a probe would be a
  second thing to keep correct.

## Rejected

- Editing the consumer's copy in `chrsctl/gx`. It is under
  `./joharness.sh protocol-paths` there, its mode is orchestrated, and
  `AGENTS.md` says a harness fix lands here first — a consumer-only edit goes
  AHEAD on every future sync.
- Dropping the merge line entirely. It costs nothing when it fails and the
  early wake is real where sessions do see each other; the failure is that
  nobody could tell why it failed.
- Claiming cloud-to-cloud messaging never works. What was measured is one
  container listing no peers. `ListAgents` documents a route that exists when
  Remote Control is connected, and a "never" here would be the same unmeasured
  confidence the issue reports.

## Review

- r1: pending.

## Blockers

None.

## Where to look

- `docs/plans/merge-notice-reach.md` — scope, acceptance, traps.
- `.claude/commands/orchestrate.md`, `create_session` bullet and the NUDGE row.
- `.claude/commands/manage.md`, section 4 Finish.
