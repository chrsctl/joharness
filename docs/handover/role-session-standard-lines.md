---
workstream: role-session-standard-lines
status: review
branch: manage/role-session-standard-lines
pr: none
plan: role-session-standard-lines
issue: 427
session: https://claude.ai/code/session_01SDBgJ7DRAdFYNQseW1FpAF
agent: sonnet
updated: 2026-10-12
next: Retire files, open PR, merge
---

## Goal

Plan role-session-standard-lines: role lines for clerk/curator/scout, read-rule carve-out, ci wait rule.

## Decisions

- Role lines go to clerk and conduct only: curate.md:25 and scout.md:26,43 write workstream files, so they keep the standard lines. Plan assumed all three; code says otherwise.
- Conduct added to role lines (conduct.md:49 writes no workstream file).

## Review

- r1: curator/scout claim by workstream file, role lines wrong for them (verifier) (fixed)
- r2: anchors vs product-code limit conflict (verifier) (fixed)
- r3: curate --apply not covered by background rule (verifier) (fixed)
- r4: scout one-pass vs resume (verifier) (fixed by r1)
