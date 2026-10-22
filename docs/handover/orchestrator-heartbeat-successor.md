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
next: ci + verify green, verifier r3, PR, merge
---

## Goal

Only the keeper starts orchestrators, and it retires the old one in the
same turn. Past the pass limit the orchestrator's wake carries
`retire=yes`; the keeper retitles it `orchestrator (retired)` and starts
the successor with that wake as prompt.

## Decisions

- Human's call (2026-10-22, session_01UWVRaAaL6vGZGpyJizh88u): only the heartbeat spawns an orchestrator; the old one retires. Taken over from the blocked manager session_01KjRsJjm6q7mKQCqKQLbwJZ; plan rewritten to match.
- SWAP in the keeper, one serial turn: retitle old, then create the successor. The old one keeps running passes until swapped, so no gap; retitled first, so no second fleet.
- Successor prompt = the retired session's own pending wake (pass=1, flag and leads removed): trusts nothing that session would not have run.
- Doorbell via send_message, text never read; fire_trigger is refused in auto mode.
- No up-to-date heartbeat = no swap; the orchestrator keeps arming in one session.
- LIVE = RUNNING or PENDING, or a pending wake. Pass entry Retired check first; Duplicate check exits the newer, the older rebuilds @new.

## Rejected

- Orchestrator starts its own successor (create_session hand-off): races the keeper's hourly wake.
- Doorbell text as spawn prompt (r9), ledger inherited from the retired session's report (r19, r21, r23): both trust text a non-orchestrator can write.
- fire_trigger on the heartbeat with the ledger as text: auto-mode refusal, reading in this file's history.
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
- r19: (verifier) a session retitled `orchestrator (retired)` by anyone could write the inherited ledger (fixed: no inheritance; the successor's prompt is the retired session's own pending wake)
- r20: (verifier) a PENDING successor read as not LIVE, so the keeper or a second start could double it (fixed: LIVE counts PENDING in Start step 3 and the keeper)
- r21: (verifier) a ledger could be inherited twice or from a stale retired session (fixed: no inheritance)
- r22: (verifier) the fired-within window made the keeper and Start disagree on LIVE, an hour with no orchestrator (fixed: window removed; the old orchestrator runs until swapped, so no gap)
- r23: (verifier) the doorbell went out before the report the successor read (fixed: no report to read; the keeper swaps from the stored wake)
- r24: (verifier) orchestrated.md said the ledger goes to the keeper (fixed: rewritten for SWAP)
- r25: (verifier) leads to a retired session in the gap were dropped (fixed: no gap; the retired session forwards to the LIVE one, which exists from the swap on)
- r26: (verifier) needles matched twice or not the clause (fixed: needles rewritten per clause, line-order check on retitle before spawn)
- r27: (verifier) keeper's last-started id lives in context (no change: one extra short session if compaction drops it; Start step 3 then exits the newer)
- r28: (verifier) a forged doorbell starts an orchestrator when none is LIVE (no change: the hourly wake would start the same one; it changes timing, never the prompt)
- r29: (verifier) incident narrative and gx chain in the doc (fixed: incident moved to git log; mechanism only)
- r30: r19-r23 came from fixes to r9-r10, churn (no change: the research step was the redesign to SWAP, which removes inheritance, the doorbell payload and the LIVE window instead of patching them)
- r31: (verifier) successor's first turn undefined; Start would empty the inherited ledger (fixed: successor runs Start, first-start ledger is the prompt's `ledger:` line)
- r32: (verifier) Retired halted any orchestrator whose title set_session_title could not set (fixed: stops only on exactly the retired or duplicate title)
- r33: (verifier) Pass entry ordered superseded first and Retired first at once (fixed: Retired bullet first, one order sentence, refute on the old one)
- r34: (verifier) two pending wakes after an out-of-band arm (fixed: SWAP takes the highest pass=; a retired session's human-ordered spawn reads its title first)
- r35: (verifier) a foreign trigger bound to the orchestrator could put any lines into the spawn prompt (fixed: wake shape check, only /orchestrate pass, harness=, ledger:, lead lines)
- r36: (verifier) refused create_session after retitle can leave none for an hour (fixed: guard 5 minutes read off date -u, failure pushes, doc states the gap)
- r37: (verifier) rejected path sentence in the doc (fixed: removed)
- r38: (verifier) serial keeper turns stated as fact, unmeasured (no change: one session runs one turn at a time; worded as that mechanism)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 3, Pass entry (Retired, Duplicate), §4 RETIRE, "## Keeper" SWAP.
- `.agents/docs/orchestrated.md` — "Start each run fresh", "Heartbeat: making the fleet long".
