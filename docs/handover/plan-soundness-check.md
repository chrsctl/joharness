---
workstream: plan-soundness-check
status: in-progress
branch: plan-soundness-check
pr: none
plan: plan-soundness-check
issue: none
session: https://claude.ai/code/session_01AkrfEEAVogEU2VPrEVsggC
agent: sonnet
updated: 2026-10-23
next: Record verifier findings (verifier) in ## Review, then retire plan+workstream files, PR, finish
---

## Goal

Add plan-checker agent: opus/fable plans get one outside reader before the first worker.

## Decisions

- manage.md headroom 760 bytes (bound 10172, size 9412); detail goes to manage-reference.md if needed.

## Review

- r1: item 4 of Acceptance has no command/failure form (plan-checker) (wontfix: dry run is a spawn, recorded here; plan file retires at merge)
- r2: Acceptance items 1-3 state no failure form (plan-checker) (wontfix: a mismatch with the expected output is the failure)
- r3: headroom claim "under 800" vs measured 415 after the §2 step (plan-checker) (no change: wc -c manage.md 9757 vs bound 10172; true, plan retires)
- r4: plan-assumptions also edits manage.md, no needs: link (plan-checker) (wontfix: shared: marker in scope is the mechanism; second merger reconciles)
- r5: no sync manifest lists agents/verifier, so none needs plan-checker (plan-checker) (no change)
- r6: dry run found no instruction-like text in plan; anchors all resolve (plan-checker) (no change)

## Blockers

None.

## Where to look

- `.claude/agents/verifier.md` — shape to copy.
