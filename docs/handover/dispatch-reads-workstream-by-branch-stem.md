---
workstream: dispatch-reads-workstream-by-branch-stem
status: in-progress
branch: claude/dispatch-reads-workstream-by-branch-stem
pr: none
plan: dispatch-reads-workstream-by-branch-stem
issue: none
session: https://claude.ai/code/session_01J1YMK4yQtUpiLdJJnbH8i1
agent: sonnet
updated: 2026-11-10
next: Run ci, verify, finish; open PR, merge
---

## Decisions

Question refuted: the lookup is not by branch stem. Reproduced: suffixed
remote branch read in full from main; blank only when checked out on that
branch (handover hook skips the current branch). Selftest + orchestrated.md
section graduate it; research file deleted.

## Review

- r1: edge review: selftest case pins both position and suffix (no change)
- r2: (verifier) clean pass; dangling research cite is a name only (no change)
