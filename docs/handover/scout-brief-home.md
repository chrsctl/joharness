---
workstream: scout-brief-home
status: in-progress
branch: manage-scout-brief-home
pr: none
plan: scout-brief-home
issue: none
session: https://claude.ai/code/session_013gq19LfjnahCsnHBR9XXVz
agent: sonnet
updated: 2026-10-12
next: Edit the three VISION lists, add selftest cases and README section, run ci and verify
---

## Goal

Give `docs/product/SCOUT.md` a home that is never scheduled (plan scout-brief-home).

## Review
- r1: (verifier) SCOUT.md under docs/plans also skipped by queue_files (no change — same as VISION)
- r2: (verifier) x.md expect matched a bare substring (fixed — pins the row bracket)
- r3: (verifier) README line wrap, brief behaviour owned by scout-proposes-on-issues (no change)
- r4: first `verify` run 3 failed under concurrent selftests, rerun 6 passed 0 failed
