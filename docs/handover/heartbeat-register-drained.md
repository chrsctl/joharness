---
workstream: heartbeat-register-drained
status: in-progress
branch: claude/heartbeat-register-drained
pr: none
plan: heartbeat-register-drained
issue: none
session: https://claude.ai/code/session_01D8rDGonCmGBgmUyRnLNe8F
agent: sonnet
updated: 2026-10-23
next: Verifier and edge review; record in ## Review; then ci, verify, PR, finish
---

## Goal

A DRAINED orchestrator that registers the heartbeat must not cause a second
orchestrator. REGISTER's keeper takes its post on the first turn. The first
hourly wake does the LIVE check.

## Decisions

- REGISTER's `create_session` prompt is `/keeper register`, and the Routine
  keeps `/keeper`. The marker is explicit, so the keeper never has to guess
  "first turn" from its own context.
- The register turn starts nothing, whatever the parent's state. The
  registering orchestrator has just read dispatch. If it dies without
  finishing, the next hourly wake recovers within the hour.

## Rejected

- create_session with no prompt: whether a Routine can wake a session that
  never ran is unverified on the platform.
- Keeper counts a retired parent as LIVE: a retired title is never LIVE
  (ref § 0. Start step 3), and on later wakes the parent stays retired
  forever.
- Skip REGISTER on a DRAINED run: then nothing restarts the fleet when new
  plans land.

## Review

- r1: (verifier) keeper.md LIVE clause still said "your first turn runs inside it", false since the register turn stops at step 1 (fixed: clause dropped, refute pin)
- r2: (verifier) orchestrated.md keeper-liveness paragraph said the keeper's first turn runs the check inside the parent's first start (fixed: an hourly wake lands there; the register turn checks nothing; refute pin)
- r3: (verifier) `keeper registered: parent <id>` had no spelling for an absent parent (fixed: `none` if absent)
- r4: (verifier) AGENTS.md, start.md, orchestrate.md, joharness.sh say "Prompt is /keeper"; `/keeper register` still routes there (the slash command is /keeper; keeper title guards) (no change)
- r5: keeper.md 5650 bytes over its 5647 reading-budget bound after the Register paragraph (fixed: r1's dropped clause, now 5633)
- r6: edge review: new pins fail on origin/main docs (selftest on a main worktree with only orchestrated.sh swapped: 5 FAIL, each a new pin) (no change)

## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:## Run`
- `.agents/docs/orchestrate-reference.md:## 0. Start` — step 5, REGISTER.
