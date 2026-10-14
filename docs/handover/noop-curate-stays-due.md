---
workstream: noop-curate-stays-due
status: in-progress
branch: manage-noop-curate
pr: none
plan: noop-curate-stays-due
issue: none
session: https://claude.ai/code/session_013aNMACdT4a1yDoQneRNHN3
agent: sonnet
updated: 2026-10-14
next: Wait for ci green on this head, retire commit (delete workstream file; plan curate-noop-record stays), open PR, merge via finish
---

## Goal

Settle whether a no-finding curator pass leaves `curate : DUE`, and graduate the answer.

## Decisions

- YES, from code: the clock (`cycle_landed_sha`) reads only a merged deletion of `docs/handover/curate-*.md`; a `role curate` STOP makes none. Graduated clerk-style record into curate.md; dispatch half filed as plan `curate-noop-record`.

## Rejected

## Review

- r1: curate.md carried a plan pointer, an unverifiable gx number and an over-long line (verifier) (fixed)
- r2: plan Trap cited AGENTS.md Part 2 for the merged-only rule; source is clerk_noop (verifier) (fixed)
- r3: plan named no stale bound for future stamps; now JOHARNESS_CURATE_HOURS (verifier) (fixed)
- r4: no selftest covers dispatch_curate_due, so the one case needs a new fixture (verifier) (no change: plan says fixture is the builder's)

## Blockers

None.

## Where to look

- `joharness.sh` clerk_noop (~3506) vs the curate clock
- `.claude/commands/curate.md` §0
