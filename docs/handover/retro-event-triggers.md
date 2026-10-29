---
workstream: retro-event-triggers
status: in-progress
branch: claude/retro-event-triggers-k7m2
pr: none
plan: retro-event-triggers
issue: none
session: https://claude.ai/code/session_01J1YMK5Sd1Dd2vzKcKvG8Gj
agent: opus
updated: 2026-10-29
next: ci on this head, then retire commit and PR, finish
---

## Goal

Start retro passes when the evidence calls for them, not only by the
168h clock: stalled/respawns blocks, an untraced CONCERN, or a full sample
make a mode due early once `JOHARNESS_RETRO_FLOOR_HOURS` (default 24) have
passed since its ledger landed.

## Decisions

- A1: confirmed — `retro_due`'s `age < hours` branch already returns due on `retro_queue_block`.
- A2: confirmed — `retro_queue_block` reads the branch head's file via `refs/remotes/origin/<b>:<path>`.
- A3: confirmed, writer corrected — the orchestrator writes `stalled:`/`respawns:` (orchestrate-reference.md), `block_reason_ok` accepts them; plan fixed.
- A4: confirmed — `retro` printed not due + 3-row sample, `retro --audit` not due + 3-row sample on origin/main 043dcd6e.
- A5: confirmed — `role_start_stop` keys on `^retro DUE:` / `^cadence   : DUE`, dispatch on state `due`; no other change needed.
- A6: confirmed — both modes date age from `retro_landed_ts`, which the floor reuses.
- The event reader walks `retro_candidates` only, so a session the ledger logs never re-fires (no thrash); a stalled/respawns hit sets `RETRO_QB` so it leads the sample.
- Full sample = count of `retro_sample "$sample"` / `conduct_sample "$sample"` (`N = 0` stops at one).
- `./joharness.sh verify` 2026-10-29 first run on this branch: 4 passed, 2 failed (docker networking, compose); paired run on origin/main b6a0dae4: 6 passed, 0 failed; branch re-run with the daemon warm: 6 passed, 0 failed. Read as a cold-daemon first run, not this diff (no `.agents/env/` change).
- New due cases, extracted and run against origin/main's joharness.sh 2026-10-29: 11 FAIL; on this branch 23 passed, 0 failed. Mutation: the `retro_event_block` `?` arm turned to `continue` = the UNREADABLE case fails.
- sha1 missing with no evidence = not due (nothing to draw); with evidence = unreadable.

## Rejected

- None yet.

## Review

- r1: (plan-checker) `retro_sample 0` prints at most one line, the full-sample count can never fire as written (fixed: plan counts `retro_sample "$JOHARNESS_RETRO_SAMPLE"`)
- r2: (plan-checker) a `stalled:` fixture naming an open stem hits the old queue-block path (fixed: fixture names no open stem)
- r3: (plan-checker) trigger 1's reach and order undefined; every-branch reading thrashes (fixed: candidates only, queue-block first, hit leads the sample)
- r4: (plan-checker) A3 names the manager as writer; the orchestrator writes them (fixed)
- r5: (plan-checker) conf-keys Trap wrong for a dispatch-scope knob (fixed: trap reworded)
- r6: (plan-checker) SHIPS uncheckable when not due (fixed: headers print the floor, in Scope)
- r7: (plan-checker) Acceptance names no command; dispatch line depends on clerk/audit (fixed: selftest named, rtd conditions stated)
- r8: (plan-checker) no-ledger case and conduct unreadable unstated (fixed)
- r9: (plan-checker) human-only list contradicts the code's set (fixed: out of scope reworded to event reasons only)
- r10: (plan-checker) spawn prompt carried the repo path beyond the plan path (no change: a cwd hint, no content about the plan)
- r11: (verifier) the logged-park case ran with FLOOR=0 at 0h, so it could not fail (fixed: a ledger logging the session landed 30h ago, default floor; fails when retro_candidates ignores the ledger)
- r12: (verifier) the leads-the-sample case had one candidate, so it could not fail (fixed: a second candidate whose sha1 sorts first, order asserted; fails without RETRO_QB)
- r13: (verifier) plan Acceptance said the fixtures run under `verify`; they run under `ci` (fixed)
- r14: (verifier) trace past the floor without sha1 read quiet not-due while audit read unreadable (fixed: both unreadable, checked once past the floor)
- r15: (verifier) orchestrated.md HOURS rows still read as the only due point (fixed: rows name the clock as the ceiling and the floor knob)
- r16: (verifier) past the floor an unreadable audit ledger makes trace UNREADABLE, where the clock path reads it in lower case (wontfix: plan Scope says any failed read is unreadable, never due; under the clock it is still not read)
- r17: (verifier) `.claude/commands/retro.md` named only the queue-block early due (fixed: one sentence names the floor triggers)

## Blockers

None.

## Where to look

- `joharness.sh:retro_due` / `joharness.sh:conduct_due` — the due logic.
- `.agents/harness/selftest/retro.sh` — fixtures.
