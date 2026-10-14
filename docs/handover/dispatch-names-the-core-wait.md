---
workstream: dispatch-names-the-core-wait
status: in-progress
branch: mgr-dispatch-names-the-core-wait
pr: none
plan: dispatch-names-the-core-wait
issue: none
session: https://claude.ai/code/session_01546ufvgD2uVHm37uhD2UHd
agent: sonnet
updated: 2026-10-14
next: retire, PR, merge
---

## Goal

Plan `dispatch-names-the-core-wait`: dispatch prints a wait line under DRAINED when CORE ONLY plans wait.

## Review
- r1: mutation, new printf replaced by `:` in a scratch run of the selftest: `FAIL the wait line counts it, dates it and names the stem`; restored: `2817 passed, 0 failed` (selftest.sh, 2026-10-14) (fixed)
- r2: (verifier) one unreadable add date among several still printed a day count, understating "oldest" (fixed: any unreadable date prints `?`)
- r3: (verifier) shallow clone or missing origin/main reads the graft/branch commit, age wrong not `?` (wontfix: same limit as every other dispatch git read, which already prints the shallow-clone floor warning)
- r4: (verifier) selftest covers only the final DRAINED branch, no multi-plan or `?` case (wontfix: the plan asks for exactly one case plus a refutation; the other branches share one flag read by one condition)
- r5: (verifier) orphan line break in orchestrated.md (no change: renders as prose)
