---
workstream: defect-park-own-issue
status: in-progress
branch: claude/defect-park-own-issue
pr: none
plan: defect-park-own-issue
issue: none
session: https://claude.ai/code/session_01J1YMK62r3sAH91d8NqDL3c
agent: opus
updated: 2026-11-10
next: Retire commit, PR, finish, merge
---

## Goal

Harness defect from chrsctl/gx (2026-11-10): a manager parked `defect: #N`
on its own plan's issue; dispatch must flag it `INVALID BLOCK?`, and the
manager docs must say so. Plan: `docs/plans/defect-park-own-issue.md`.

## Decisions

- Same-session plan, on this branch.

## Review

- r1: a self-park joined blocked_claims, releasing its scope: an overlapping plan spawned beside a manager told to do the work (verifier) (fixed: scope held; case "a plan overlapping a self-park is held")
- r2: self-parks counted in "blocked: report to the human" (verifier) (fixed: own count line; case "self-parks are counted apart")
- r3: branch could edit its plan copy to `issue: none` and read PARKED again (verifier) (fixed: base and branch copy both read; case "editing its plan's issue: away")
- r4: `issue: 043` read PARKED; dead leading-zero strip (verifier) (fixed: own digit normalisation; case "issue: 043")
- r5: "retire as not reproduced" was an undefined procedure clashing with Acceptance (verifier) (fixed: § Defect step 0 routes to a `product:` block with the evidence)
- r6: gx numbers unmarked as a consumer reading (verifier) (fixed: "reported, not re-taken here")
- r7: flag read "never a park, parked 2h ago" (verifier) (fixed: "blocked")
- r8: spawn prompt carried a goal summary and focus list beyond subagents.md (verifier) (no change: process note, this review done)
- r9: edge review: own pass found nothing beyond r1-r8 (no change)

## Blockers

None.
