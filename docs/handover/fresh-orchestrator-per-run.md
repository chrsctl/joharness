---
workstream: fresh-orchestrator-per-run
status: in-progress
branch: fresh-orchestrator-per-run
pr: none
plan: fresh-orchestrator-per-run
issue: 429
session: https://claude.ai/code/session_01D4X18QbBsbEzCUWJDi22Td
agent: sonnet
updated: 2026-10-12
next: Run ci and verify, review, retire plan and workstream, open PR
---

## Goal

Tell the human and the orchestrator that a fresh session per run is cheaper (plan fresh-orchestrator-per-run).

## Review

- r1: quote used hyphen not em dash (verifier) (fixed)
- r2: doc overstated when the line prints (verifier) (fixed)
- r3: order stated twice in Report section (verifier) (fixed)
- r4: ci/verify not confirmed by verifier; ci: pass run by author, verify 4 passed 2 failed on docker networking/compose, environmental, diff is .md-only (no change)

## Blockers

None.
