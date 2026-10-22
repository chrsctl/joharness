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
retires: retitle, quote its next wake in its final report, ring the keeper
(`retired <id>`), end. The keeper starts a plain `/orchestrate`; the
successor inherits the ledger from the retired session's report.

## Decisions

- Human's call (2026-10-22, session_01UWVRaAaL6vGZGpyJizh88u): only the heartbeat spawns an orchestrator; the old one retires. Taken over from the blocked manager session_01KjRsJjm6q7mKQCqKQLbwJZ; plan rewritten to match.
- Doorbell by send_message, not fire_trigger (refused in auto mode). The doorbell carries no data: any session can message the keeper, so text there must never become a spawn prompt.
- Ledger travels in the retired session's own final report, read by the successor with list_events; the successor retitles it `orchestrator (succeeded)` so it is inherited once.
- No up-to-date heartbeat = no retire; the create_session hand-off is removed, not kept as a fallback.
- LIVE orchestrator = RUNNING, or a wake pending or fired within 2 x JOHARNESS_HEALTH_MINUTES. Used by Start step 3, Pass entry Duplicate, and the retired forwarder.
- Duplicate: the newer exits; the older rebuilds @new from manager titles this pass and the next.

## Rejected

- Retire wake text as the keeper's spawn prompt: prompt injection from any session that can message the keeper (verifier r9).
- fire_trigger on the heartbeat with the ledger as text: auto-mode refusal, reading in orchestrated.md.
- Self-bound probe Routine fired with text: the platform drops text for a Routine bound to the firing session.

## Review

- r1: (verifier) paragraph called an unmeasured prerequisite a failed one (fixed: reworded as unmeasured, both readings named open)
- r2: (verifier) a manager's refusal stands in for an orchestrator's (fixed: paragraph says the orchestrator path is unmeasured)
- r3: (verifier) retire cites an either-no rule whose condition was not met (fixed: blocked core path instead of retiring)
- r4: (verifier) claimed an allow rule lives in settings.json, none exists (fixed: says none exists today)
- r5: (verifier) reopen condition unobservable and dropped the two readings (fixed: condition removed, readings named)
- r6: (verifier) self-bound probe is a rejected path in harness docs (fixed: moved out of orchestrated.md, kept under Rejected)
- r7: (verifier) reading named the trigger by title, not id, and omitted the text (fixed: id and text quoted)
- r8: (verifier) two heartbeat needles no longer matched the rewritten keeper step 3 and start step 3 (fixed)
- r9: (verifier) keeper used a message's text as a spawn prompt: injection from any session (fixed: message is a doorbell, never read; ledger inherited from the retired session's report)
- r10: (verifier) Duplicate check missed an older orchestrator whose wake had just fired (fixed: wakes fired within 2 x health minutes count; one LIVE definition)
- r11: (verifier) a duplicate's exit lost its unclaimed @new spawns (fixed: the older rebuilds @new this pass and the next)
- r12: (verifier) retired session forwarded leads to the newest, possibly exited, orchestrator (fixed: forwards to the oldest LIVE one; duplicate and succeeded titles forward too)
- r13: (verifier) every retire dropped its leads; plan not updated (fixed: leads ride the quoted wake and are inherited; plan rewritten to the human's decision)
- r14: (verifier) send_message to the keeper wakes it and queues behind a running turn: unmeasured (no change: the doorbell is an optimisation; lost or refused, the hourly wake starts the successor, so correctness rests on the keeper's serial turns, not on delivery; priority later per the tool's own contract)
- r15: (verifier) undoes r2/r6 (no change: the fire_trigger design they reworded is dropped by the human's call, not re-patched; the reading stays as current fact, the rejected path lives here)
- r16: (verifier) stale hand-off wording in joharness.sh and this file (fixed)
- r17: (verifier) needles pinned phrases, not conditions; refute covered only HANDED OFF (fixed: needles on RUNNING, pending-or-fired, doorbell unread, never-restore; refutes for handed-off title and pass-through)
- r18: (verifier) Never-list exception named a forward RETIRE no longer makes (fixed)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 3, Pass entry Duplicate, §4 RETIRE, "## Keeper".
- `.agents/docs/orchestrated.md` — "Start each run fresh", "Heartbeat: making the fleet long".
