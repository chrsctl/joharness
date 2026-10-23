---
workstream: simplify-queue-docs
status: in-progress
branch: manage/simplify-queue-docs
pr: none
plan: simplify-queue-docs
issue: none
session: https://claude.ai/code/session_01D1BiuFo9v9TinYbs32J8NQ
agent: sonnet
updated: 2026-10-23
next: Run verify, verifier review, retire files, open PR, merge.
---

## Goal

Make the queue docs match the code and say each rule once (plan simplify-queue-docs).

## Decisions
- A1: confirmed — session-start prints no queue (`HANDOVER_SCOPE=branch`, joharness.sh:8273).
- A2: confirmed — joharness.sh:3901 "reads no GitHub".
- A3: confirmed — reading-budget.sh bounds handover/README.md upper only; now 15k bytes.
- A4: confirmed — research/README.md keeps "outside this checkout".
- Built by hand, no workers: five prose files, one reader needed for consistency.
- Line count 1045 (bound 1050), `ci: pass`.

## Review
