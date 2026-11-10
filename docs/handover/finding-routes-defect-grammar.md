---
workstream: finding-routes-defect-grammar
status: in-progress
branch: manager/finding-routes-defect-grammar
pr: none
plan: finding-routes-defect-grammar
issue: none
session: https://claude.ai/code/session_01J1YMK6RVKJCUgZxwubwoSr
agent: sonnet
updated: 2026-11-10
next: Read scratchpad all2.out (selftest, ci, verify); if green retire ws+plan files, PR, merge.
---

## Goal

Make `ci` stage `finding routes` red a first reproduced defect cited only `PR body`.

## Decisions

- A1: confirmed — fr_routed read only verdict text; fb_findings feeds `## Review` only.
- A2: confirmed — lint_finding_routes uses fb_findings.
- Built directly (small, one file set); no workers.

## Review
- r1: negation window reached across "but", letting "not reproduced but defect confirmed" through (verifier) (fixed in joharness.sh:fr_defect_claim, clause words break the window; fixture r6)
- r2: claim keywords too narrow: reproducible, bug missed (verifier) (fixed: defect|bug|reproduc… counted, manager-reference.md updated; fixture r7)
- r3: "defect-free" read as a defect (verifier) (fixed: stripped; fixture r8)
- r4: weak fixtures (verifier) (fixed: r6-r8 added)
