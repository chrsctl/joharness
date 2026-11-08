---
workstream: keeper-stillborn-spawn
status: in-progress
branch: claude/keeper-stillborn-spawn
pr: none
plan: keeper-stillborn-spawn
issue: none
session: https://claude.ai/code/session_01J1YMK4CB57ke54pkRNnbob
agent: sonnet
updated: 2026-11-08
next: Read ci result (scratchpad ci.out), run verify, open PR, finish
---

## Goal

Fix the chrsctl/gx keeper defect (2026-11-08): a compacted keeper spawned a
successor with no checkout and refused to restart it for 5 h.

## Decisions

- Context bound = the platform's auto-compaction, made lossless by re-reading
  keeper.md whole every wake, plus a narrower `list_triggers`. Rotation
  rejected: every create_session child is one lineage level deeper (cap 8).

## Rejected

- Keeper rotation via its own create_session or the orchestrator's REPLACE:
  +1 or +2 depth per rotation strands the fleet after a few rotations.

## Review

- r1: selftest pin on step 3's args-then-report sentence broke when the Source check moved between them; pin split in two (fixed)
- r2: (verifier) the did-not-start push read the title after step 2's failed-spawn retitle, so the incident case lost its push; now "when step 2 read it, before any retitle" (fixed)
- r3: (verifier) "once for that id" ambiguous across wakes; now once per id, never again on a later wake (fixed)
- r4: (verifier) step 2's failed-spawn rule had no subject; now "any session this step reads" (fixed)
- r5: (verifier) SWAP's report did not match `started orchestrator <id>`; SWAP's report now counts (fixed)
- r6: (verifier) the last-started id lives in context and a compaction can drop it, skipping the push (wontfix: step 3 still starts one on NOT LIVE, so only the push degrades; no durable store reachable from the keeper's tools)
- r7: (verifier) list_triggers filters drop no candidate: every candidate is enabled with run_once_at set (no change)
## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:Not LIVE` — step 3.
