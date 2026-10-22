---
workstream: orchestrator-heartbeat-successor
status: blocked
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01KjRsJjm6q7mKQCqKQLbwJZ
agent: opus
updated: 2026-10-22
next: core path: auto-mode classifier refused fire_trigger on the keeper; allow it in .claude/settings.json, or take the prerequisite reading from an orchestrator by hand?
---

## Goal

Fleet lives indefinitely and stays cheap: when an up-to-date heartbeat
exists, the orchestrator's §4 hand-off fires the keeper with the ledger as
payload instead of create_session, so lineage depth stays at keeper + 1.

## Decisions

- Prerequisite unmeasured, not failed: the manager's fire_trigger on the keeper heartbeat was refused by the auto-mode classifier (Interfere With Workloads), which answers neither plan question. The plan's either-no exit is not met, so no retire; nothing builds without the reading.
- Block reason core path: the remedy a session can name is a fire_trigger allow rule in .claude/settings.json (core path), or a human taking the reading from an orchestrator. Reading recorded in orchestrated.md, Heartbeat.
- No retry of the keeper fire: a refused call is that tool absent for the target (orchestrate.md, Tools).

## Rejected

- Self-bound probe Routine fired with text: the platform drops text for a Routine bound to the firing session, so it cannot stand in for the keeper reading.

## Review

- r1: (verifier) paragraph called an unmeasured prerequisite a failed one (fixed: reworded as unmeasured, both readings named open)
- r2: (verifier) a manager's refusal stands in for an orchestrator's (fixed: paragraph says the orchestrator path is unmeasured)
- r3: (verifier) retire cites an either-no rule whose condition was not met (fixed: blocked core path instead of retiring)
- r4: (verifier) claimed an allow rule lives in settings.json, none exists (fixed: says none exists today)
- r5: (verifier) reopen condition unobservable and dropped the two readings (fixed: condition removed, readings named)
- r6: (verifier) self-bound probe is a rejected path in harness docs (fixed: moved out of orchestrated.md, kept under Rejected)
- r7: (verifier) reading named the trigger by title, not id, and omitted the text (fixed: id and text quoted)

## Blockers

Prerequisite reading refused by the auto-mode classifier from a manager session. Unblock: a human allows fire_trigger (core path .claude/settings.json) or fires the keeper with a text payload from an orchestrator and records both readings; then resume this branch from the plan's Scope.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 5, §4 HAND-OFF, "## Keeper".
