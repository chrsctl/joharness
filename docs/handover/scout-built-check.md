---
workstream: scout-built-check
status: in-progress
branch: scout-built-check
pr: none
plan: scout-built-check
issue: 454
session: https://claude.ai/code/session_011g3Fs8tSUZzE1qNhQLAtUB
agent: sonnet
updated: 2026-10-13
next: ci result pending (monitor); then retire plan+workstream, merge origin/main, PR
---

## Goal

Implement docs/plans/scout-built-check.md.

## Decisions

## Review
- r1: (verifier) selftest asserts `--format=%s origin/<base>`, fragile to printf reflow (wontfix: the assertion fails without the list, proven by reverting it; `first-parent` alone would match the throughput line)
- r2: (verifier) §2 "named paths only" vs globs (no change: named directories)
- r3: (verifier) `git fetch --unshallow` is a fetch, not a read (no change: scout.md already fetches origin)
- r4: edge review: clean pass otherwise; revert of the cmd_scout list makes both new assertions FAIL (2026-10-13)
