---
workstream: clerk-closes-settled
status: done
branch: clerk-closes-settled
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_019oJ7ty7CMVnYEyHFAKuFrf
agent: sonnet
updated: 2026-10-25
next: Merge the pull request once checks are green
---

## Goal

Owner, from consumer chrsctl/gx: "Can we fix the autoclosing in
joharness?" The clerk's DOES NOT HOLD left every verified-fixed issue open
for a human ("a human closes it"), and DUPLICATE closed nothing. In gx,
five issues verified fixed on main sat open until the owner asked a
session to close them by hand.

## Decisions

- DOES NOT HOLD closes: `completed` when a named base-branch commit fixed
  it, `not_planned` when the claim never held. DUPLICATE closes as
  `duplicate`. A scout issue is never closed (unchanged).
- Undo stays with the human: reopen and comment, which is newer than the
  verdict, so the next pass reads it.

## Review
- r1: (verifier) orchestrated.md's clerk row said "never closes or opens an issue" (fixed)
- r2: (verifier) a bare reopen or footed comment leaves the verdict newest and is skipped (fixed: said so)
- r3: (verifier) DUPLICATE of a plan with `issue: none` had no `duplicate_of` (fixed: `not_planned`, naming the plan)
- r4: (verifier) closing a `blocking:` defect would hide its parked manager (fixed: never closed)
- r5: (verifier) NARROWER's "does not hold" parts could read as closing (fixed: NARROWER never closes)
- r6: (verifier) pins did not cover the scout exemption or the completed/not_planned split (fixed: pinned)
- r7: (verifier) a long wrapped line in clerk.md (fixed: rewrapped)
- r8: (verifier) empty Review, file shipped as done (fixed: this list; the file is deleted in the last commit)
