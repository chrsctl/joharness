---
workstream: simplify-consumer-docs
status: in-progress
branch: manage-simplify-consumer-docs
pr: none
plan: simplify-consumer-docs
issue: none
session: https://claude.ai/code/session_01EwfzjxJgaYY86URWxDTVXQ
agent: sonnet
updated: 2026-10-23
next: Wait for ci and verify green, record review, retire plan+workstream files, PR, finish
---

## Goal

Simplify consumer-repos.md, feedback.md, caveman.md, glossary.md per the plan.

## Decisions

- Docs edited to 900 lines total (plan limit). feedback sections renumbered 1-8; §1 and §4 kept (cited elsewhere).

## Review

- r1: (verifier) dropped `JOHARNESS_SYNC_ROOT` selftest-hook rule (fixed: bullet restored in consumer-repos.md)
- r2: (verifier) `analysis` caveats (MAY BE LIFTED, NO CONFIG MOVEMENT) stated nowhere after the cut (fixed: two-line caveat kept in feedback.md section 6)
- r3: (verifier) ci/verify unread by the verifier (no change: run by manager, ci: pass, verify 6 passed 0 failed; rerun after fixes)
- r4: (verifier) `upstream` paragraph sat under the stuck-edge section (fixed: moved to section 5)

## Blockers

None.

## Where to look

- `docs/plans/simplify-consumer-docs.md` — the plan.
