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
next: ci, verifier review, retire, PR
---

## Goal

Plan `dispatch-names-the-core-wait`: dispatch prints a wait line under DRAINED when CORE ONLY plans wait.

## Review
- r1: mutation, new printf replaced by `:` in a scratch run of the selftest: `FAIL the wait line counts it, dates it and names the stem`; restored: `2817 passed, 0 failed` (selftest.sh, 2026-10-14) (fixed)
