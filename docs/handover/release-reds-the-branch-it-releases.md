---
workstream: release-reds-the-branch-it-releases
status: in-progress
branch: claude/release-reds-the-branch-it-releases
pr: none
plan: release-reds-the-branch-it-releases
issue: none
session: https://claude.ai/code/session_01F26SmuC5nB62uKrzGEMG72
agent: sonnet
updated: 2026-10-10
next: Await ci + verifier; record acceptance 5; retire files; PR; merge.
---

## Goal

Plan release-reds-the-branch-it-releases: janitor release note must say the `abandoned` red on `ci` clears on reconcile with base.

## Decisions

## Rejected

## Review

- r1: (verifier) awk extraction end anchor unchecked; a reworded next bullet would swallow the doc and mask a damaged clause (fixed: assert clause ends at "is real, not spurious." and excludes the next bullet).
- r2: (verifier) `jred` only matched "not one of", not the full `not one of:` form (fixed: grep `${k} '${v}' not one of:` from joharness.sh).
- r3: (verifier) bare `ci` anchor pins nothing; `abandoned` not refuted on the bad note (fixed: anchor `./joharness.sh ci`, refute `abandoned` on bad note).
- r4: (verifier) case remains partly tautological, the fixture note is built from the doc's own text (wontfix: acceptance 3 allows saying so; independent check is the lint_enum wording grep and the bad-note refutations).
- r6: Acceptance 5 (checked 2026-10-10): `git worktree add origin/claude/guard-docs-only-branch; ./joharness.sh ci` -> `DEAD docs/handover/guard-docs-only-branch.md: status 'abandoned' not one of: in-progress blocked review done` / `ci: FAIL`. Red still real. Selftest 2429 passed, 0 failed (`bash .agents/harness/selftest.sh`); `./joharness.sh ci` -> ci: pass. (fixed/no change)
- r5: This plan changes nothing for the branches that red today; it reaches only future sweeps' notes. Acceptance 6 unmet: no consumer reachable here.

## Blockers

None.

## Where to look

- `.claude/commands/janitor.md` §3
