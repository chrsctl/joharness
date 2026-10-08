---
workstream: scheduler-outside-the-fleet
status: in-progress
branch: claude/scheduler-outside-the-fleet
pr: none
plan: scheduler-outside-the-fleet
issue: 249
session: https://claude.ai/code/session_01HxJCqyzWBxPevmBbn2r1oj
agent: opus
updated: 2026-10-08
next: Run the Method's four candidate probes, record each with its command, then graduate into .agents/docs/unsupervised.md
---

## Goal

Settle `docs/research/scheduler-outside-the-fleet.md`: what can run the
fleet's staleness check on a cadence without being a thing that goes stale
with the fleet? The decision procedure already exists in
`.claude/commands/orchestrate.md`; what does not exist is anything that
makes it RUN when the orchestrator itself has stopped. Graduates to
`.agents/docs/unsupervised.md`.

## Decisions

- (pending)

## Rejected

- (pending)

## Review

(pending — findings land here before their fix, in the same commit)

## Blockers

None.

## Where to look

- `docs/research/scheduler-outside-the-fleet.md` — the question, its Method
  listing the four candidates to probe.
- `.agents/docs/unsupervised.md` — graduation target; already carries the
  fleet-outlives-its-sessions problem and the heartbeat.
- `.claude/commands/orchestrate.md` — the health table that needs a runner.
