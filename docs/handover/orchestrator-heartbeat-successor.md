---
workstream: orchestrator-heartbeat-successor
status: review
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01UWVRaAaL6vGZGpyJizh88u
agent: opus
updated: 2026-10-22
next: ci + verify green, verifier, PR, merge
---

## Goal

Only the keeper starts orchestrators. At the pass limit the orchestrator
retires (retitle, send the keeper its next wake with the ledger, end); the
keeper starts the successor with that wake as prompt. Lineage stays at
keeper + 1; no duplicate fleets.

## Decisions

- Human's call (2026-10-22, session_01UWVRaAaL6vGZGpyJizh88u): only the heartbeat spawns an orchestrator and the old one retires. Taken over from the blocked manager session_01KjRsJjm6q7mKQCqKQLbwJZ.
- Retire wake by send_message to the keeper, not fire_trigger: fire_trigger is refused in auto mode; send_message is the nudge transport already allowed. Undelivered = next hourly wake starts one, ledger lost, never doubled.
- No heartbeat up to date = no retire, keep arming in the same session (the create_session hand-off is removed, not a fallback).
- Keeper also counts its last-started orchestrator LIVE while RUNNING (one get_session; list_sessions hourly stays too costly).
- Pass entry duplicate check: an older LIVE orchestrator: session with a pending wake = this one retitles `orchestrator (duplicate)` and exits. Start step 3 counts a pending wake as LIVE, not only RUNNING.
- Leads at retire are reported, not forwarded: no successor exists yet; a spawn prompt never carries a lead.

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

None. The fire_trigger prerequisite no longer gates the build: the retire wake uses send_message.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 5, §4 HAND-OFF, "## Keeper".
