---
workstream: drain-loop
status: in-progress
branch: claude/drain-loop
pr: none
plan: drain-loop
issue: none
session: https://claude.ai/code/session_01Vaf3LtqeZuPLpVyeSRpngQ
agent: opus
updated: 2026-10-07
next: Record verifier findings under ## Review, fix, then retire commit + PR + merge (step 7)
---

## Goal

Human: "Add an infinity loop to drain … like the normal loop just with
parallelity 1." `/drain` loops item after item until DRAINED, one at a time,
inline — the orchestrator's loop at cap 1 without spawning.

## Decisions

- In-session loop, chosen by the human over the heartbeat Routine and `/loop`.
- Inline, not spawning: parallelity 1 means this session does each item;
  orchestrated mode at `JOHARNESS_MAX_MANAGERS=1` already covers the spawning
  shape.
- Re-read the Loop and drain.md between items: rules decay over a long
  context, task state survives (handover README, Compaction).
- Stop on an item that cannot reach merge rather than skip it: finishing
  outranks starting, so `drain` would name it again as edge work.

## Rejected

- Heartbeat Routine — spend is the human's; not what was asked.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/drain.md` — the command.
