---
workstream: a-block-names-its-reason
status: in-progress
branch: claude/a-block-names-its-reason
pr: none
plan: a-block-names-its-reason
issue: 392
session: https://claude.ai/code/session_012tFTpAdvvW6ZRD7QA64SxK
agent: sonnet
updated: 2026-10-10
next: read ci result, rerun verify (docker networking case flaked once; main passes), retire files, PR
---

## Goal

Blocks name a reason prefix; dispatch flags unprefixed ones (issue #392).

## Review

- r1: no selftest exercised the analysis_one reader (verifier) (fixed: analysis.sh case)
- r2: refute cases vacuous; five reason words uncovered (verifier) (fixed: cases h-m, row-printed expect)
- r3: quoted next: text flagged as invalid (verifier) (fixed: block_reason_ok strips a leading quote)
- r4: INVALID BLOCK? row said nudge a non-running session (verifier) (fixed: reworded)
- r5: long lines in edited docs (verifier) (no change: ci does not object)

## Blockers

None.
