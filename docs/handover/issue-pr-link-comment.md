---
workstream: issue-pr-link-comment
status: in-progress
branch: manage/issue-pr-link-comment
pr: none
plan: issue-pr-link-comment
issue: none
session: https://claude.ai/code/session_01J81uGaaVshMcZfWQTpjPyT
agent: sonnet
updated: 2026-10-22
next: ci and verify, verifier review, retire, PR
---

## Goal

Manager and clerk comment the pull request link on every issue they name.

## Review

- r1: the four new needles are absent on origin/main (grep -c: Link the issue 0, post ONE comment on that issue 0, clerk: HOLDS — plan 0, AFTER the pull request opens 0), so the new expect cases are red without the command-file hunks (fixed)
- r2: (verifier) selftest cat of clerk.md fails in a consumer with the clerk off (fixed: guarded by [ -f ] and skipped when empty)
- r3: (verifier) HOLDS comment sentence could read as the HUMAN case (fixed: "A plan written:")
- r4: (verifier) deferral covered every verdict (fixed: only HOLDS and NARROWER defer)
- r5: (verifier) manage.md silent on a PR naming no issue (no change: zero named issues yields zero comments)
