---
workstream: no-unbounded-waits
status: in-progress
branch: claude/drain-67lt1l
pr: none
plan: no-unbounded-waits
issue: none
session: https://claude.ai/code/session_015XtCMDkJC9wPu9htijCRbw
agent: sonnet
updated: 2026-09-05
next: Write .agents/harness/pretool-bash-guard.sh and its selftest topic.
---

## Goal

Requester, 2026-09-05: "maybe infinite loops should not exist". Two commands
in one session could not finish and both were caught after the fact — one by
a human reading the background-tasks panel at 1h 17m, one by the stop guard
at 18m. Add the stage that refuses the command before it runs.

## Decisions

- Took `no-unbounded-waits` over the queue's first item `orchestrated-run`.
  That plan's own "BEFORE YOU START" hands three calls to the human (the cap
  and three other knobs in `joharness.conf`, creating the heartbeat Routine,
  stocking the queue) and records that no heartbeat exists and the queue is
  not stocked. Money and product direction = ask, do not decide
  (`.agents/harness/AGENTS.md`, Decide alone). So it is not actionable this
  session; this one is. Both sit in wave 1 with disjoint `scope:`.
- Plan tier is `sonnet`; this session runs `opus`. Escalation, allowed.

## Rejected

-

## Review

## Blockers

None.

## Where to look

- `docs/plans/no-unbounded-waits.md` — scope, acceptance, traps.
- `.agents/harness/pretool-feedback.sh` — the existing PreToolUse hook: the
  one-line payload flattening, the anchored key read, the fail-open doctrine.
