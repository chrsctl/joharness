---
workstream: heartbeat-self-registers
status: in-progress
branch: claude/heartbeat-self-registers
pr: none
plan: heartbeat-self-registers
issue: none
session: https://claude.ai/code/session_01XeXyvPqHBEa67tQe5q8JrV
agent: opus
updated: 2026-10-16
next: Run ci and verify, then the verifier at opus, then PR
---

## Goal

Requester: the heartbeat registers itself when `/orchestrate` runs and none
exists. Keeper design chosen by the requester in this session.

## Decisions

- Bound to a keeper session, not fresh-session: a session-made
  fresh-session Routine fires with `sources: []` and no session or GitHub
  tools (transcript of `session_011K3RWr1Ypfqu4z8XiW5CyX`, 2026-10-16).
- Keeper liveness = a pending `/orchestrate pass` wake bound to an
  `orchestrator: <owner/repo>` session. A RUNNING orchestrator mid-pass has
  no pending wake; the spawned one's step 3 exits on it, one short session.
  `list_sessions` rejected for the keeper: ~78K characters per call, hourly,
  into one persistent context.
- A paused heartbeat (`enabled` false, empty `ended_reason`) is the human's
  veto: never re-enabled, never replaced.

- The successor plan's IDLE-with-`updated_at` step 3 rule dropped: the
  keeper reads pending wakes, so an orchestrator between passes is seen.

## Rejected

- Session-made fresh-session heartbeat: measured unable to orchestrate.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` "## 0. Start" step 5, "## Keeper".
