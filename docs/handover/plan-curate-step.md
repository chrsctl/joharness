---
workstream: plan-curate-step
status: review
branch: claude/plan-curate-step-k3m9
pr: none
plan: plan-curate-step
issue: none
session: https://claude.ai/code/session_01CCZ4fdZD5RpRj9muS4KcgD
agent: haiku
updated: 2026-10-22
next: ./joharness.sh finish, then PR and merge.
---

## Goal

A hand-written `/plan` can fail `./joharness.sh ci` on a mechanical scope
repair that `curate --apply` fixes by itself. Add the step `/plan` lacks,
mirroring `.claude/commands/clerk.md` §4.

## Decisions

- Single edit to `.claude/commands/plan.md`; no other file changes.

## Rejected

None yet.

## Blockers

None.

## Where to look

- `.claude/commands/plan.md:41` — step 4, the `ci` line the new step precedes.
- `.claude/commands/clerk.md:195` — the wording to mirror.

## Review

- r1: verifier (haiku) clean pass on the plan.md diff; ci pass, verify 6 passed 0 failed (no change)
