---
workstream: keeper-on-haiku
status: in-progress
branch: plan-keeper-haiku
pr: none
plan: keeper-on-haiku
issue: none
session: https://claude.ai/code/session_01Rvx2DxJa2xfSAnyJssP2CZ
agent: haiku
updated: 2026-10-23
next: Open the pull request, finish, merge
---

## Goal

Repo owner decided in chat (2026-10-23): the keeper role runs on haiku, not
sonnet. Plan `docs/plans/keeper-on-haiku.md`.

## Decisions

- Plan and build in one session, on owner's "Implement".
- The running keeper keeps its model until the next REGISTER or replace;
  no archive from this branch.

## Review
- r1: (verifier) ci red: orchestrated selftest pins the old REGISTER sentence; plan forbade selftests (fixed: pin follows the new text, plan scope names it)
- r2: (verifier) SHIPS plan's Acceptance named no consumer-side check (fixed: names the shipped selftest pin)
- r3: (verifier) REGISTER wording carried attribution "the human's tier decision" (fixed: dropped)
- r4: (verifier) plan Goal omitted the keeper's SWAP path (fixed: Goal names it, accepted by the owner)
- r5: /code-review default pass on the final diff found nothing (no change)
