---
workstream: agents-docs-move
status: review
branch: claude/agents-docs-move
pr: none
plan: agents-docs-move
session: https://claude.ai/code/session_0178f1MyS7qfR1ovDhqt4pH8
agent: sonnet
updated: 2026-08-23
next: Merge when GitHub checks green (step 7; ci 245/0 and verify 7/7 green on this head)
---

## Goal

Implement plan agents-docs-move: harness protocol docs to `.agents/docs/`,
sync tools to `.agents/scripts/`, so a child's `docs/` is 100% its own and
the sync ships nothing into `docs/` or `scripts/`.

## Decisions

- update.yml compat: existing consumers' seeded update.yml calls
  canonical's `scripts/sync-to-consumer.sh`, which this plan removes. No
  shim (plan out-of-scope). Seeded update.yml gains a two-path probe so
  new consumers survive future moves; existing consumers' weekly run goes
  red with file-not-found until a one-line edit — documented in
  consumer-repos Migration. Flagged: scope call made alone.
- Legacy warning grows a file tier next to the dir tier: old doc/script
  paths are single files inside dirs that still hold live consumer work,
  so remedy must name files, never `-r` a docs dir.

## Rejected

None yet.

## Review

`/code-review` (high) on full diff vs `main`, round 1:

- r1: my regex pass over `.agents/docs/**` rewrote the migration doc's
  own `git rm` example block to the NEW paths — an agent following it
  would delete the live harness and keep the stale copies. Block restored
  to the old paths the sync's warning actually names. (fixed)
- r2: same regex hit the update.yml note, making broken path = fixed
  path. Old spelling restored. (fixed)
- r3: `.agents/harness/AGENTS.md` line 5 still sent readers to `docs/`
  for why-explanations — in a consumer that is now the child's own work.
  Re-pointed to `.agents/docs/`. (fixed)
- r4: `joharness.conf` marker comment named three removed paths. (fixed)
- r5: plan acceptance wrote "count GREATER than 247"; counted is 245
  (main baseline 240, +5 new cases — all planned cases present).
  Doctrine: trust counted numbers, never written — the 247 was a written
  guess. Recorded here, not padded with filler tests. (wontfix)
- r6: fixture commit message still said "drop graph doc" after the test
  re-targeted CLAUDE.md. (fixed)

## Blockers

None.

## Where to look

- docs/plans/agents-docs-move.md — the plan; PR #37 diff — the pattern.
